-- =====================================================================
--  يومية الشنطة: الكاش، والشيكات، والمصاريف، وفتح اليوم وإغلاقه
--
--  ١) حسابان جديدان لكل منشأة:
--     - "شيكات بالصندوق": الشيك يُخصم من كاش المحل كأنه نقد، لكنه يُحفظ
--       هنا لا في كاش الشنطة — فالكاش المعروض نقد فعلي فقط.
--     - "المصاريف": بنزين، أكل، مواصلات، صيانة، سحب شخصي، أخرى.
--  ٢) صرف الشيك: نقداً (يدخل كاش الشنطة) أو إيداعاً في البنك (يخرج للمالك).
--  ٣) فتح اليوم: تأكيد الكاش المحمول (الافتراضي ما بقي من الأمس)،
--     والفرق يُسجَّل إضافةً من المالك أو سحباً له.
--  ٤) إغلاق اليوم (إلزامي): عدّ الكاش وتأكيد البضاعة والكسر، والفرق
--     يُسجَّل عجزاً أو زيادة في "أرباح وفروقات".
-- =====================================================================

alter type tx_type add value if not exists 'expense';
alter type tx_type add value if not exists 'cash_adjust';
alter type tx_type add value if not exists 'cheque_clear';

-- ---------------------------------------------------------------------
-- ١) الحسابان الجديدان — للمنشآت الحالية وللجديدة
-- ---------------------------------------------------------------------
insert into accounts (tenant_id, name, kind, system_key, is_system)
select t.id, x.name, x.kind::account_kind, x.key, true
from tenants t
cross join (values
  ('شيكات بالصندوق', 'cashbox', 'cheques'),
  ('المصاريف',       'expense', 'expenses')
) as x(name, kind, key)
on conflict (tenant_id, system_key) do nothing;

create or replace function seed_tenant(p_tenant uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_shanta uuid; v_type org_type;
begin
  insert into karats (tenant_id, name, factor_ppm, out_factor_ppm, in_factor_ppm, sort_order) values
    (p_tenant, 'عيار 24', 1000000, 1000000, 1000000, 0),
    (p_tenant, 'عيار 21',  885000,  885000,  870000, 1),
    (p_tenant, 'عيار 18',  790000,  790000,  740000, 2),
    (p_tenant, 'عيار 14',  583333,  583333,  550000, 3),
    (p_tenant, 'عيار 9',   375000,  375000,  375000, 4)
  on conflict (tenant_id, name) do nothing;

  insert into accounts (tenant_id, name, kind, system_key, is_system) values
    (p_tenant, 'الشنطة',          'inventory_location', 'shanta',         true),
    (p_tenant, 'الخزنة',          'inventory_location', 'vault',          true),
    (p_tenant, 'الصندوق',         'cashbox',            'cashbox',        true),
    (p_tenant, 'شيكات بالصندوق',  'cashbox',            'cheques',        true),
    (p_tenant, 'المصاريف',        'expense',            'expenses',       true),
    (p_tenant, 'إيراد المصنعية',  'income',             'making_income',  true),
    (p_tenant, 'أرباح وفروقات',   'income',             'trading_income', true),
    (p_tenant, 'رأس المال',       'owner',              'capital',        true)
  on conflict (tenant_id, system_key) do nothing;

  perform seed_items(p_tenant);

  select org_type into v_type from tenants where id = p_tenant;
  if v_type in ('distributor', 'factory') then
    select id into v_shanta from accounts where tenant_id = p_tenant and system_key = 'shanta';
    insert into bags (tenant_id, name, account_id)
    values (p_tenant, 'الشنطة الرئيسية', v_shanta)
    on conflict do nothing;
  end if;
end $$;

create or replace function system_account(p_key text) returns uuid
language sql stable security definer set search_path = public as $$
  select id from accounts where tenant_id = current_tenant_id() and system_key = p_key
$$;

create or replace function cash_balance(p_account uuid) returns bigint
language sql stable security definer set search_path = public as $$
  select coalesce(sum(amount), 0)::bigint from postings
  where account_id = p_account and ledger = 'cash'
    and tenant_id = current_tenant_id()
$$;

-- ---------------------------------------------------------------------
-- ٢) صرف الشيك
--    الشيك المحفوظ في "شيكات بالصندوق": [p_to_cash] صحيح = صُرف نقداً
--    فيدخل كاش الشنطة، خطأ = أُودع في البنك فيخرج للمالك.
--    الشيكات القديمة المقيّدة على الصندوق مباشرة تُغلق حالتها فقط.
-- ---------------------------------------------------------------------
drop function if exists clear_cheque(uuid, uuid, timestamptz, text);

create or replace function clear_cheque(
  p_cheque_id   uuid,
  p_cashbox_id  uuid,
  p_occurred_at timestamptz default now(),
  p_note        text default null,
  p_to_cash     boolean default true
) returns text language plpgsql security definer set search_path = public as $$
declare
  v_cheque  cheques%rowtype;
  v_sign    int;
  v_tx      uuid;
  v_cheques uuid := system_account('cheques');
  v_other   uuid;
  v_held    boolean;
begin
  perform assert_can_write('cheques.manage');

  select * into v_cheque from cheques
  where id = p_cheque_id and tenant_id = current_tenant_id() for update;
  if not found then
    raise exception 'الشيك غير موجود';
  end if;
  if v_cheque.status <> 'pending' then
    raise exception 'الشيك ليس معلّقاً — حالته %', v_cheque.status;
  end if;

  v_sign := case when v_cheque.direction = 'incoming' then 1 else -1 end;

  if v_cheque.settled_tx_id is not null then
    select exists (select 1 from postings
                   where tx_id = v_cheque.settled_tx_id and account_id = v_cheques)
      into v_held;
    if v_held then
      v_other := case when p_to_cash then p_cashbox_id else system_account('capital') end;
      v_tx := post_transaction(
        'cheque_clear'::tx_type, p_occurred_at,
        jsonb_build_array(
          jsonb_build_object('account_id', v_other, 'ledger', 'cash',
                             'amount', v_sign * v_cheque.amount_fils),
          jsonb_build_object('account_id', v_cheques, 'ledger', 'cash',
                             'amount', -v_sign * v_cheque.amount_fils)
        ),
        v_cheque.account_id, null,
        coalesce(p_note, case when p_to_cash then 'صرف شيك نقداً ' else 'إيداع شيك في البنك ' end
                         || coalesce(v_cheque.cheque_number, '')),
        null
      );
    end if;
    update cheques set status = 'cleared', settled_at = now() where id = p_cheque_id;
    return (select doc_number from transactions
            where id = coalesce(v_tx, v_cheque.settled_tx_id));
  end if;

  -- شيك قديم لم يُقيَّد بعد: تحصيله يُنشئ الدفعة
  v_tx := post_transaction(
    'cash_payment'::tx_type, p_occurred_at,
    jsonb_build_array(
      jsonb_build_object('account_id', p_cashbox_id, 'ledger', 'cash',
                         'amount', v_sign * v_cheque.amount_fils),
      jsonb_build_object('account_id', v_cheque.account_id, 'ledger', 'cash',
                         'amount', -v_sign * v_cheque.amount_fils)
    ),
    v_cheque.account_id, null,
    coalesce(p_note, 'تحصيل شيك ' || coalesce(v_cheque.cheque_number, '')),
    null
  );
  update cheques set status = 'cleared', settled_at = now(), settled_tx_id = v_tx
  where id = p_cheque_id;
  return (select doc_number from transactions where id = v_tx);
end $$;

grant execute on function clear_cheque(uuid, uuid, timestamptz, text, boolean) to authenticated;

-- ---------------------------------------------------------------------
-- ٣) يومية الشنطة
-- ---------------------------------------------------------------------
create table if not exists bag_days (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references tenants(id) on delete cascade,
  day                   date not null,
  opening_expected_fils bigint not null,
  opening_cash_fils     bigint not null,
  opening_note          text,
  opening_adjust_tx     uuid references transactions(id),
  opened_by             uuid references auth.users(id),
  opened_at             timestamptz not null default now(),
  closing_expected_fils bigint,
  closing_cash_fils     bigint,
  goods_confirmed       boolean not null default false,
  closing_note          text,
  closing_adjust_tx     uuid references transactions(id),
  closed_by             uuid references auth.users(id),
  closed_at             timestamptz,
  unique (tenant_id, day)
);

alter table bag_days enable row level security;
drop policy if exists bag_days_read on bag_days;
create policy bag_days_read on bag_days for select to authenticated
  using (tenant_id = current_tenant_id());
-- الكتابة عبر الدالتين أدناه فقط
revoke insert, update, delete on bag_days from authenticated, anon;
grant select on bag_days to authenticated;

-- تسوية الكاش: يدخل أو يخرج من الصندوق مقابل حساب آخر.
create or replace function _cash_adjust(p_diff bigint, p_other uuid, p_note text)
returns uuid language plpgsql security definer set search_path = public as $$
begin
  if p_diff = 0 then return null; end if;
  return post_transaction(
    'cash_adjust'::tx_type, now(),
    jsonb_build_array(
      jsonb_build_object('account_id', system_account('cashbox'), 'ledger', 'cash', 'amount', p_diff),
      jsonb_build_object('account_id', p_other, 'ledger', 'cash', 'amount', -p_diff)
    ),
    null, null, p_note, null);
end $$;
revoke all on function _cash_adjust(bigint, uuid, text) from public, anon, authenticated;

-- فتح اليوم: الكاش المحمول. الفرق عن الدفتر = إضافة من المالك أو سحب له.
create or replace function open_bag_day(p_day date, p_cash_fils bigint, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_tenant   uuid := current_tenant_id();
  v_expected bigint;
  v_tx       uuid;
begin
  perform assert_can_write('ledger.write');
  if p_cash_fils < 0 then raise exception 'المبلغ لا يكون سالباً'; end if;
  if exists (select 1 from bag_days where tenant_id = v_tenant and closed_at is null) then
    raise exception 'يوجد يوم سابق لم يُغلق — أغلقه أولاً';
  end if;
  if exists (select 1 from bag_days where tenant_id = v_tenant and day = p_day) then
    raise exception 'هذا اليوم مفتوح سابقاً';
  end if;

  v_expected := cash_balance(system_account('cashbox'));
  if p_cash_fils <> v_expected and coalesce(trim(p_note), '') = '' then
    raise exception 'اكتب سبب تغيير الكاش عن رصيد الأمس';
  end if;
  v_tx := _cash_adjust(p_cash_fils - v_expected, system_account('capital'),
                       'فتح يوم ' || p_day || coalesce(' — ' || nullif(trim(p_note), ''), ''));

  insert into bag_days (tenant_id, day, opening_expected_fils, opening_cash_fils,
                        opening_note, opening_adjust_tx, opened_by)
  values (v_tenant, p_day, v_expected, p_cash_fils, nullif(trim(p_note), ''), v_tx, auth.uid());
  return jsonb_build_object('expected', v_expected, 'cash', p_cash_fils);
end $$;

-- إغلاق اليوم: الكاش المعدود، وتأكيد البضاعة والكسر. الفرق = عجز أو زيادة.
create or replace function close_bag_day(
  p_day date, p_cash_fils bigint, p_goods_confirmed boolean, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_tenant   uuid := current_tenant_id();
  v_row      bag_days%rowtype;
  v_expected bigint;
  v_tx       uuid;
begin
  perform assert_can_write('ledger.write');
  if p_cash_fils < 0 then raise exception 'المبلغ لا يكون سالباً'; end if;
  if not p_goods_confirmed then
    raise exception 'أكّد البضاعة والكسر قبل الإغلاق';
  end if;

  select * into v_row from bag_days
  where tenant_id = v_tenant and day = p_day for update;
  if not found then raise exception 'هذا اليوم غير مفتوح'; end if;
  if v_row.closed_at is not null then raise exception 'هذا اليوم مغلق سابقاً'; end if;

  v_expected := cash_balance(system_account('cashbox'));
  if p_cash_fils <> v_expected and coalesce(trim(p_note), '') = '' then
    raise exception 'يوجد فرق في الكاش — اكتب سببه';
  end if;
  v_tx := _cash_adjust(p_cash_fils - v_expected, system_account('trading_income'),
                       case when p_cash_fils < v_expected then 'عجز صندوق ' else 'زيادة صندوق ' end
                       || p_day || coalesce(' — ' || nullif(trim(p_note), ''), ''));

  update bag_days
  set closing_expected_fils = v_expected,
      closing_cash_fils = p_cash_fils,
      goods_confirmed = true,
      closing_note = nullif(trim(p_note), ''),
      closing_adjust_tx = v_tx,
      closed_by = auth.uid(),
      closed_at = now()
  where id = v_row.id;
  return jsonb_build_object('expected', v_expected, 'cash', p_cash_fils);
end $$;

grant execute on function open_bag_day(date, bigint, text) to authenticated;
grant execute on function close_bag_day(date, bigint, boolean, text) to authenticated;
grant execute on function cash_balance(uuid) to authenticated;
