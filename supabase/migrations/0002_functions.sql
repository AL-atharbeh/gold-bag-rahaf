-- =====================================================================
--  الدوال المحمية — كل كتابة في الدفتر تمر من هنا حصراً
--
--  لماذا في السيرفر وليس في التطبيق؟
--  في النظام المحلي لا أحد يصل للقاعدة إلا التطبيق. أما أونلاين فمن يملك
--  مفتاح التطبيق يستطيع مناداة الـ API مباشرة. لذلك قاعدة "مجموع القيد
--  = صفر" يجب أن تُفرض هنا، لا في واجهة Flutter.
-- =====================================================================

-- منشأة المستخدم الحالي. security definer لتفادي التكرار اللانهائي
-- في سياسات RLS على جدول profiles نفسه.
create or replace function current_tenant_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select tenant_id from profiles where id = auth.uid() and is_active
$$;

-- رقم المستند التالي. التوقيت بتوقيت عمّان حتى لا تنقلب السنة
-- على حركات آخر ليلة في السنة.
create or replace function next_doc_number(p_tenant uuid, p_when timestamptz)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_year int := extract(year from (p_when at time zone 'Asia/Amman'))::int;
  v_no   bigint;
begin
  insert into doc_counters (tenant_id, year, last_no)
  values (p_tenant, v_year, 1)
  on conflict (tenant_id, year)
    do update set last_no = doc_counters.last_no + 1
  returning last_no into v_no;

  return v_year || '-' || lpad(v_no::text, 5, '0');
end $$;

-- ---------------------------------------------------------------------
--  حفظ حركة كاملة: الرأس + السطور + التدقيق، في معاملة واحدة.
--  ترفض أي قيد غير متوازن.
-- ---------------------------------------------------------------------
create or replace function post_transaction(
  p_type                tx_type,
  p_occurred_at         timestamptz,
  p_postings            jsonb,
  p_counterparty_id     uuid    default null,
  p_price_per_gram_fils bigint  default null,
  p_note                text    default null,
  p_reverses_tx_id      uuid    default null
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant uuid := current_tenant_id();
  v_tx     uuid := gen_random_uuid();
  v_doc    text;
  v_count  int;
  v_bad    int;
  v_row    record;
begin
  if v_tenant is null then
    raise exception 'مستخدم غير مصرّح له';
  end if;

  if jsonb_typeof(p_postings) <> 'array' then
    raise exception 'سطور القيد يجب أن تكون مصفوفة';
  end if;

  select count(*) into v_count from jsonb_array_elements(p_postings);
  if v_count < 2 then
    raise exception 'القيد يحتاج سطرين على الأقل';
  end if;

  -- كل حساب مذكور في القيد يجب أن يكون ضمن نفس المنشأة وغير محذوف
  select count(*) into v_bad
  from jsonb_array_elements(p_postings) e
  left join accounts a
    on a.id = (e->>'account_id')::uuid
   and a.tenant_id = v_tenant
   and a.deleted_at is null
  where a.id is null;

  if v_bad > 0 then
    raise exception 'القيد يشير إلى حساب غير معروف';
  end if;

  -- الحارس الأساسي: مجموع كل دفتر داخل الحركة = صفر
  for v_row in
    select (e->>'ledger')::ledger_kind as ledger,
           sum((e->>'amount')::bigint) as total
    from jsonb_array_elements(p_postings) e
    group by 1
  loop
    if v_row.total <> 0 then
      raise exception 'قيد غير متوازن في دفتر %: الفرق %',
        v_row.ledger, v_row.total;
    end if;
  end loop;

  v_doc := next_doc_number(v_tenant, p_occurred_at);

  insert into transactions (
    id, tenant_id, type, occurred_at, doc_number, counterparty_id,
    price_per_gram_fils, note, created_by, reverses_tx_id
  ) values (
    v_tx, v_tenant, p_type, p_occurred_at, v_doc, p_counterparty_id,
    p_price_per_gram_fils, p_note, auth.uid(), p_reverses_tx_id
  );

  insert into postings (
    tenant_id, tx_id, seq, account_id, ledger, amount,
    karat_id, karat_ppm, gross_weight_mg, item_id, quantity,
    making_per_gram_fils, note
  )
  select
    v_tenant,
    v_tx,
    (t.ord - 1)::int,
    (t.e->>'account_id')::uuid,
    (t.e->>'ledger')::ledger_kind,
    (t.e->>'amount')::bigint,
    (t.e->>'karat_id')::uuid,
    (t.e->>'karat_ppm')::int,
    (t.e->>'gross_weight_mg')::bigint,
    (t.e->>'item_id')::uuid,
    (t.e->>'quantity')::int,
    (t.e->>'making_per_gram_fils')::bigint,
    t.e->>'note'
  from jsonb_array_elements(p_postings) with ordinality as t(e, ord);

  insert into audit_log (tenant_id, entity, entity_id, action, details, actor)
  values (
    v_tenant, 'transaction', v_tx,
    case when p_reverses_tx_id is null then 'create' else 'reverse' end,
    p_type::text || ' — ' || v_doc,
    auth.uid()
  );

  return v_tx;
end $$;

-- ---------------------------------------------------------------------
--  القيد العكسي — التصحيح الوحيد المسموح. التاريخ لا يُمحى.
-- ---------------------------------------------------------------------
create or replace function reverse_transaction(
  p_tx_id  uuid,
  p_reason text default null
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant   uuid := current_tenant_id();
  v_tx       transactions%rowtype;
  v_postings jsonb;
  v_new      uuid;
begin
  if v_tenant is null then
    raise exception 'مستخدم غير مصرّح له';
  end if;

  select * into v_tx
  from transactions
  where id = p_tx_id and tenant_id = v_tenant;

  if not found then
    raise exception 'الحركة غير موجودة';
  end if;

  if v_tx.reversed_by_tx_id is not null then
    raise exception 'هذه الحركة ملغاة مسبقاً';
  end if;

  select jsonb_agg(
           jsonb_build_object(
             'account_id',           p.account_id,
             'ledger',               p.ledger,
             'amount',               -p.amount,
             'karat_id',             p.karat_id,
             'karat_ppm',            p.karat_ppm,
             'gross_weight_mg',      -p.gross_weight_mg,
             'item_id',              p.item_id,
             'quantity',             -p.quantity,
             'making_per_gram_fils', p.making_per_gram_fils,
             'note',                 p.note
           ) order by p.seq
         )
  into v_postings
  from postings p
  where p.tx_id = p_tx_id;

  v_new := post_transaction(
    'reversal'::tx_type,
    now(),
    v_postings,
    v_tx.counterparty_id,
    v_tx.price_per_gram_fils,
    coalesce(p_reason, 'إلغاء ' || v_tx.doc_number),
    p_tx_id
  );

  update transactions set reversed_by_tx_id = v_new where id = p_tx_id;

  return v_new;
end $$;

-- ---------------------------------------------------------------------
--  إنشاء محل عرض مع حساب عهدته في خطوة واحدة.
--  فصل العهدة إلزامي: الذهب المعروض ما زال ملكنا وليس مديونية.
-- ---------------------------------------------------------------------
create or replace function create_showroom(
  p_name  text,
  p_phone text default null,
  p_note  text default null
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant  uuid := current_tenant_id();
  v_shop    uuid := gen_random_uuid();
  v_consign uuid := gen_random_uuid();
begin
  if v_tenant is null then
    raise exception 'مستخدم غير مصرّح له';
  end if;

  insert into accounts (id, tenant_id, name, kind, is_system, created_by)
  values (v_consign, v_tenant, 'عهدة ' || p_name,
          'inventory_location', true, auth.uid());

  insert into accounts (id, tenant_id, name, kind, phone, note,
                        consignment_account_id, created_by)
  values (v_shop, v_tenant, p_name, 'showroom', p_phone, p_note,
          v_consign, auth.uid());

  insert into audit_log (tenant_id, entity, entity_id, action, details, actor)
  values (v_tenant, 'account', v_shop, 'create',
          'محل عرض: ' || p_name, auth.uid());

  return v_shop;
end $$;
