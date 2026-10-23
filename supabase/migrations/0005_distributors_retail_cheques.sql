-- =====================================================================
--  توسعة مبنية على دفاتر العميل الفعلية
--
--  ثلاثة تغييرات جوهرية:
--  ١) لكل عيار معاملان لا واحد: معامل خروج البضاعة ومعامل دخول الذهب.
--     الفارق بينهما (٠٫٨٨٥ مقابل ٠٫٨٧٠ في عيار ٢١) هو هامش التاجر،
--     وهو مطبَّق في كل صف من دفتر الموزعين.
--  ٢) المعاملان قابلان للتجاوز لكل طرف على حدة — كل موزّع قد يتفق
--     على معامل خاص.
--  ٣) عملاء التجزئة والشيكات المؤجّلة، وهما دفتران غائبان تماماً.
-- =====================================================================

-- ---------------------------------------------------------------------
--  ١) عميل التجزئة نوع حساب جديد
-- ---------------------------------------------------------------------
alter type account_kind add value if not exists 'customer';

-- ---------------------------------------------------------------------
--  ٢) معاملا العيار
-- ---------------------------------------------------------------------
alter table karats add column if not exists out_factor_ppm int;
alter table karats add column if not exists in_factor_ppm  int;

-- نقل القيمة القديمة كأساس، ثم ضبط المعاملات من دفتر العميل
update karats set out_factor_ppm = factor_ppm, in_factor_ppm = factor_ppm
where out_factor_ppm is null;

update karats set out_factor_ppm = 1000000, in_factor_ppm = 1000000
where name like '%24%';
update karats set out_factor_ppm =  885000, in_factor_ppm =  870000
where name like '%21%';
update karats set out_factor_ppm =  790000, in_factor_ppm =  740000
where name like '%18%';

-- عيار ٩ (بضاعة ٣٧٥) موجود في دفتر الموزعين ومفقود عندنا
insert into karats (tenant_id, name, factor_ppm, out_factor_ppm, in_factor_ppm, sort_order)
select t.id, 'عيار 9', 375000, 375000, 375000, 3
from tenants t
where not exists (
  select 1 from karats k where k.tenant_id = t.id and k.name = 'عيار 9'
);

alter table karats alter column out_factor_ppm set not null;
alter table karats alter column in_factor_ppm  set not null;

alter table karats add constraint karats_out_factor_range
  check (out_factor_ppm between 1 and 1000000);
alter table karats add constraint karats_in_factor_range
  check (in_factor_ppm between 1 and 1000000);

-- factor_ppm القديم يبقى للتوافق مع القيود المحفوظة، ولا يُستعمل بعد الآن
comment on column karats.factor_ppm is
  'مهجور — استُبدل بـ out_factor_ppm و in_factor_ppm. يبقى لقراءة القيود القديمة.';

-- ---------------------------------------------------------------------
--  ٣) معاملات خاصة لكل طرف
--
--  الحقل الفارغ يعني: استعمل معامل العيار العام. هذا أفضل من نسخ
--  القيمة الافتراضية، لأن تعديل العام لاحقاً يسري على من لم يتفق
--  على استثناء.
-- ---------------------------------------------------------------------
create table if not exists account_karat_factors (
  id             uuid primary key default gen_random_uuid(),
  tenant_id      uuid not null references tenants(id) on delete cascade,
  account_id     uuid not null references accounts(id) on delete cascade,
  karat_id       uuid not null references karats(id)   on delete cascade,
  out_factor_ppm int check (out_factor_ppm between 1 and 1000000),
  in_factor_ppm  int check (in_factor_ppm  between 1 and 1000000),
  note           text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (account_id, karat_id),
  -- صف بلا أي تجاوز لا معنى له
  check (out_factor_ppm is not null or in_factor_ppm is not null)
);

create index if not exists akf_account_idx
  on account_karat_factors (account_id);

-- المعامل الساري لكل طرف وعيار: الخاص إن وُجد، وإلا العام.
create or replace view effective_karat_factors
with (security_invoker = true) as
select
  a.id       as account_id,
  a.name     as account_name,
  k.id       as karat_id,
  k.name     as karat_name,
  k.sort_order,
  k.tenant_id,
  coalesce(f.out_factor_ppm, k.out_factor_ppm) as out_factor_ppm,
  coalesce(f.in_factor_ppm,  k.in_factor_ppm)  as in_factor_ppm,
  (f.out_factor_ppm is not null)               as out_is_custom,
  (f.in_factor_ppm  is not null)               as in_is_custom
from accounts a
join karats k on k.tenant_id = a.tenant_id and k.is_active
left join account_karat_factors f
       on f.account_id = a.id and f.karat_id = k.id
where a.deleted_at is null and a.is_active;

-- ---------------------------------------------------------------------
--  ٤) الشيكات المؤجّلة
--
--  الشيك ليس دفعة: الدين لا ينقص حتى يُحصَّل. لذلك يُسجَّل هنا بحالته،
--  ولا يُنشئ قيداً إلا لحظة التحصيل — وقتها يُربط بالحركة الناتجة.
-- ---------------------------------------------------------------------
do $$ begin
  create type cheque_direction as enum ('incoming', 'outgoing');
exception when duplicate_object then null; end $$;

do $$ begin
  create type cheque_status as enum ('pending', 'cleared', 'bounced', 'cancelled');
exception when duplicate_object then null; end $$;

create table if not exists cheques (
  id             uuid primary key default gen_random_uuid(),
  tenant_id      uuid not null references tenants(id) on delete cascade,
  account_id     uuid not null references accounts(id),
  direction      cheque_direction not null,
  status         cheque_status not null default 'pending',
  amount_fils    bigint not null check (amount_fils > 0),
  due_date       date not null,
  cheque_number  text,
  bank_name      text,
  note           text,
  -- الحركة التي أنشأها التحصيل. فارغة ما دام الشيك معلّقاً.
  settled_tx_id  uuid references transactions(id),
  settled_at     timestamptz,
  created_at     timestamptz not null default now(),
  created_by     uuid references auth.users(id),
  -- شيك محصَّل أو مرتجع لا بد له من تاريخ تسوية
  check (status = 'pending' or settled_at is not null)
);

create index if not exists cheques_due_idx
  on cheques (tenant_id, status, due_date);
create index if not exists cheques_account_idx
  on cheques (account_id);

-- ---------------------------------------------------------------------
--  ٥) تحصيل شيك — يُنشئ الدفعة ويربطها بالشيك في عملية واحدة
-- ---------------------------------------------------------------------
create or replace function clear_cheque(
  p_cheque_id  uuid,
  p_cashbox_id uuid,
  p_occurred_at timestamptz default now(),
  p_note       text default null
) returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_cheque  cheques%rowtype;
  v_doc     text;
  v_sign    int;
begin
  select * into v_cheque from cheques where id = p_cheque_id for update;
  if not found then
    raise exception 'الشيك غير موجود';
  end if;
  if v_cheque.status <> 'pending' then
    raise exception 'الشيك ليس معلّقاً — حالته %', v_cheque.status;
  end if;

  -- وارد: يدخل الصندوق وينقص دين الطرف. صادر: العكس.
  v_sign := case when v_cheque.direction = 'incoming' then 1 else -1 end;

  v_doc := post_transaction(
    'cash_payment'::tx_type,
    p_occurred_at,
    jsonb_build_array(
      jsonb_build_object(
        'account_id', p_cashbox_id,
        'ledger', 'cash',
        'amount', v_sign * v_cheque.amount_fils),
      jsonb_build_object(
        'account_id', v_cheque.account_id,
        'ledger', 'cash',
        'amount', -v_sign * v_cheque.amount_fils)
    ),
    v_cheque.account_id,
    null,
    coalesce(p_note, 'تحصيل شيك ' || coalesce(v_cheque.cheque_number, '')),
    null
  );

  update cheques
     set status = 'cleared',
         settled_at = now(),
         settled_tx_id = (select id from transactions
                          where doc_number = v_doc and tenant_id = v_cheque.tenant_id)
   where id = p_cheque_id;

  return v_doc;
end $$;

-- ---------------------------------------------------------------------
--  ٦) بيع تجزئة بمبلغ متفق عليه
--
--  التاجر لا يحسب سعر الجرام للزبون: يتفق على مبلغ القطعة كاملاً.
--  فالبضاعة تخرج بوزنها، والدين يُقيَّد بالمبلغ المتفق لا بحساب الوزن.
-- ---------------------------------------------------------------------
create or replace function post_retail_sale(
  p_customer_id   uuid,
  p_inventory_id  uuid,
  p_income_id     uuid,
  p_total_fils    bigint,
  p_lines         jsonb,          -- [{karat_id, karat_ppm, gross_weight_mg, quantity}]
  p_paid_fils     bigint default 0,
  p_cashbox_id    uuid default null,
  p_occurred_at   timestamptz default now(),
  p_note          text default null
) returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_postings jsonb := '[]'::jsonb;
  v_line     jsonb;
  v_net      bigint;
  v_doc      text;
begin
  if p_total_fils <= 0 then
    raise exception 'مبلغ البيع يجب أن يكون أكبر من صفر';
  end if;
  if p_paid_fils < 0 or p_paid_fils > p_total_fils then
    raise exception 'المدفوع مقدماً لا يصح أن يتجاوز المبلغ';
  end if;
  if p_paid_fils > 0 and p_cashbox_id is null then
    raise exception 'الدفعة المقدمة تحتاج صندوقاً';
  end if;

  for v_line in select * from jsonb_array_elements(p_lines) loop
    v_net := ((v_line->>'gross_weight_mg')::bigint
              * (v_line->>'karat_ppm')::bigint + 500000) / 1000000;

    v_postings := v_postings
      || jsonb_build_object(
           'account_id', p_inventory_id, 'ledger', 'gold', 'amount', -v_net,
           'karat_id', v_line->>'karat_id',
           'karat_ppm', (v_line->>'karat_ppm')::int,
           'gross_weight_mg', -(v_line->>'gross_weight_mg')::bigint,
           'quantity', (v_line->>'quantity')::int)
      || jsonb_build_object(
           'account_id', p_income_id, 'ledger', 'gold', 'amount', v_net,
           'karat_id', v_line->>'karat_id',
           'karat_ppm', (v_line->>'karat_ppm')::int,
           'gross_weight_mg', (v_line->>'gross_weight_mg')::bigint,
           'quantity', (v_line->>'quantity')::int);
  end loop;

  -- الدين النقدي بالمبلغ المتفق
  v_postings := v_postings
    || jsonb_build_object('account_id', p_customer_id, 'ledger', 'cash',
                          'amount', p_total_fils)
    || jsonb_build_object('account_id', p_income_id, 'ledger', 'cash',
                          'amount', -p_total_fils);

  -- الدفعة المقدمة إن وُجدت، ضمن نفس الحركة
  if p_paid_fils > 0 then
    v_postings := v_postings
      || jsonb_build_object('account_id', p_cashbox_id, 'ledger', 'cash',
                            'amount', p_paid_fils)
      || jsonb_build_object('account_id', p_customer_id, 'ledger', 'cash',
                            'amount', -p_paid_fils);
  end if;

  v_doc := post_transaction('sale'::tx_type, p_occurred_at, v_postings,
                            p_customer_id, null, p_note, null);
  return v_doc;
end $$;

-- ---------------------------------------------------------------------
--  ٧) الحماية والصلاحيات للجداول الجديدة
-- ---------------------------------------------------------------------
alter table account_karat_factors enable row level security;
alter table cheques               enable row level security;

drop policy if exists akf_all on account_karat_factors;
create policy akf_all on account_karat_factors for all to authenticated
  using (tenant_id = current_tenant_id())
  with check (tenant_id = current_tenant_id());

drop policy if exists cheques_all on cheques;
create policy cheques_all on cheques for all to authenticated
  using (tenant_id = current_tenant_id())
  with check (tenant_id = current_tenant_id());

grant select, insert, update, delete on account_karat_factors to authenticated;
grant select, insert, update on cheques to authenticated;
grant select on effective_karat_factors to authenticated;

-- الشيك المحصَّل لا يُحذف: هو مرتبط بحركة محاسبية
revoke delete on cheques from authenticated;
revoke truncate, trigger, references
  on account_karat_factors, cheques from authenticated;
revoke all on account_karat_factors from anon;
revoke all on cheques               from anon;

grant execute on function clear_cheque(uuid, uuid, timestamptz, text)
  to authenticated;
grant execute on function post_retail_sale(
  uuid, uuid, uuid, bigint, jsonb, bigint, uuid, timestamptz, text)
  to authenticated;

-- ---------------------------------------------------------------------
--  ٨) تهيئة المنشآت الجديدة بالمعاملات المزدوجة
-- ---------------------------------------------------------------------
create or replace function bootstrap_tenant(p_name text default 'تاجر الذهب')
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_existing uuid;
  v_tenant   uuid;
begin
  if auth.uid() is null then
    raise exception 'يلزم تسجيل الدخول';
  end if;

  select tenant_id into v_existing from profiles where id = auth.uid();
  if v_existing is not null then
    return v_existing; -- مهيّأة مسبقاً؛ النداء آمن للتكرار
  end if;

  -- أول منشأة فقط تُنشأ بهذه الطريقة؛ من يأتي بعدها ينضم إليها.
  select id into v_tenant from tenants order by created_at limit 1;

  if v_tenant is null then
    insert into tenants (name) values (p_name) returning id into v_tenant;

    -- معاملان لكل عيار: الأول لخروج البضاعة، والثاني لدخول الذهب.
    -- الفارق بينهما هامش التاجر، مأخوذ من دفتره الفعلي.
    insert into karats (tenant_id, name, factor_ppm,
                        out_factor_ppm, in_factor_ppm, sort_order) values
      (v_tenant, 'عيار 24', 1000000, 1000000, 1000000, 0),
      (v_tenant, 'عيار 21',  885000,  885000,  870000, 1),
      (v_tenant, 'عيار 18',  790000,  790000,  740000, 2),
      (v_tenant, 'عيار 9',   375000,  375000,  375000, 3);

    insert into accounts (tenant_id, name, kind, system_key, is_system) values
      (v_tenant, 'الشنطة',          'inventory_location', 'shanta',         true),
      (v_tenant, 'الخزنة',          'inventory_location', 'vault',          true),
      (v_tenant, 'الصندوق',         'cashbox',            'cashbox',        true),
      (v_tenant, 'إيراد المصنعية',  'income',             'making_income',  true),
      (v_tenant, 'أرباح وفروقات',   'income',             'trading_income', true),
      (v_tenant, 'رأس المال',       'owner',              'capital',        true);
  end if;

  update profiles set tenant_id = v_tenant, updated_at = now()
  where id = auth.uid();

  return v_tenant;
end $$;

grant execute on function bootstrap_tenant(text) to authenticated;
