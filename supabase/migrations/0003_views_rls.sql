-- =====================================================================
--  العروض والصلاحيات
-- =====================================================================

-- ---------------------------------------------------------------------
-- ١) الأرصدة — محسوبة من القيود دائماً، لا يوجد حقل رصيد قابل للتعديل
-- ---------------------------------------------------------------------
create view account_balances
with (security_invoker = true) as
select
  a.id        as account_id,
  a.tenant_id,
  a.name,
  a.kind,
  a.system_key,
  a.consignment_account_id,
  coalesce(sum(p.amount) filter (where p.ledger = 'gold'), 0)::bigint as gold_mg,
  coalesce(sum(p.amount) filter (where p.ledger = 'cash'), 0)::bigint as cash_fils
from accounts a
left join postings p on p.account_id = a.id
where a.deleted_at is null and a.is_active
group by a.id;

-- ---------------------------------------------------------------------
-- ٢) كشف الحساب — كل سطر قيد مع معلومات حركته
-- ---------------------------------------------------------------------
create view account_statement
with (security_invoker = true) as
select
  p.id                 as posting_id,
  p.tenant_id,
  p.account_id,
  p.ledger,
  p.amount,
  p.gross_weight_mg,
  p.karat_ppm,
  k.name               as karat_name,
  p.making_per_gram_fils,
  p.note               as line_note,
  t.id                 as tx_id,
  t.type               as tx_type,
  t.doc_number,
  t.occurred_at,
  t.price_per_gram_fils,
  t.note               as tx_note,
  t.reversed_by_tx_id is not null as is_reversed,
  t.counterparty_id,
  c.name               as counterparty_name
from postings p
join transactions t on t.id = p.tx_id
left join karats k   on k.id = p.karat_id
left join accounts c on c.id = t.counterparty_id;

-- ---------------------------------------------------------------------
-- ٣) إنشاء المستخدم: كل حساب دخول جديد يحصل على ملف تعريف تلقائياً
-- ---------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------------------------------------------------------------------
-- ٤) تهيئة المنشأة — تُنادى مرة واحدة من أول مستخدم
--    تنشئ العيارات وحسابات النظام وتربط المستخدم بالمنشأة.
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

    insert into karats (tenant_id, name, factor_ppm, sort_order) values
      (v_tenant, 'عيار 24', 1000000, 0),
      (v_tenant, 'عيار 21',  885000, 1),
      (v_tenant, 'عيار 18',  740000, 2);

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

-- ---------------------------------------------------------------------
-- ٥) تفعيل الحماية على مستوى الصف
-- ---------------------------------------------------------------------
alter table tenants      enable row level security;
alter table profiles     enable row level security;
alter table karats       enable row level security;
alter table accounts     enable row level security;
alter table items        enable row level security;
alter table gold_prices  enable row level security;
alter table transactions enable row level security;
alter table postings     enable row level security;
alter table audit_log    enable row level security;
alter table doc_counters enable row level security;

create policy tenants_read on tenants for select to authenticated
  using (id = current_tenant_id());

create policy profiles_read_self on profiles for select to authenticated
  using (id = auth.uid() or tenant_id = current_tenant_id());

create policy profiles_update_self on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- بيانات المنشأة: قراءة وكتابة داخل نفس المنشأة
create policy karats_all on karats for all to authenticated
  using (tenant_id = current_tenant_id())
  with check (tenant_id = current_tenant_id());

create policy accounts_all on accounts for all to authenticated
  using (tenant_id = current_tenant_id())
  with check (tenant_id = current_tenant_id());

create policy items_all on items for all to authenticated
  using (tenant_id = current_tenant_id())
  with check (tenant_id = current_tenant_id());

create policy gold_prices_all on gold_prices for all to authenticated
  using (tenant_id = current_tenant_id())
  with check (tenant_id = current_tenant_id());

-- الدفتر: قراءة فقط. الكتابة حصراً عبر post_transaction.
create policy transactions_read on transactions for select to authenticated
  using (tenant_id = current_tenant_id());

create policy postings_read on postings for select to authenticated
  using (tenant_id = current_tenant_id());

create policy audit_read on audit_log for select to authenticated
  using (tenant_id = current_tenant_id());

create policy doc_counters_read on doc_counters for select to authenticated
  using (tenant_id = current_tenant_id());

-- ---------------------------------------------------------------------
-- ٦) الصلاحيات — سد الباب أمام الكتابة المباشرة على الدفتر
--
--    بدون هذا القسم يستطيع أي شخص يملك مفتاح التطبيق أن يرسل
--    INSERT مباشراً على postings ويُدخل قيداً مختلاً.
-- ---------------------------------------------------------------------
revoke insert, update, delete on transactions from authenticated, anon;
revoke insert, update, delete on postings     from authenticated, anon;
revoke insert, update, delete on audit_log    from authenticated, anon;
revoke insert, update, delete on doc_counters from authenticated, anon;
revoke update, delete          on tenants     from authenticated, anon;
revoke insert, delete          on profiles    from authenticated, anon;

-- المستخدم غير المسجّل لا يرى شيئاً
revoke all on all tables in schema public from anon;

-- الدوال الداخلية ليست واجهة عامة
revoke all on function next_doc_number(uuid, timestamptz) from public, anon, authenticated;
revoke all on function forbid_mutation()                  from public, anon, authenticated;
revoke all on function transactions_guard()               from public, anon, authenticated;
revoke all on function handle_new_user()                  from public, anon, authenticated;

-- الواجهة المسموحة للتطبيق
grant execute on function current_tenant_id()   to authenticated;
grant execute on function bootstrap_tenant(text) to authenticated;
grant execute on function create_showroom(text, text, text) to authenticated;
grant execute on function post_transaction(tx_type, timestamptz, jsonb, uuid, bigint, text, uuid)
  to authenticated;
grant execute on function reverse_transaction(uuid, text) to authenticated;

grant select on account_balances, account_statement to authenticated;
