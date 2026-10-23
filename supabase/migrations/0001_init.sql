-- =====================================================================
--  نظام إدارة توزيع الذهب — المخطط الأساسي
--  ينفَّذ مرة واحدة على مشروع Supabase جديد (SQL Editor → Run)
-- =====================================================================

-- ---------------------------------------------------------------------
-- ١) الأنواع
-- ---------------------------------------------------------------------

create type account_kind as enum (
  'showroom',            -- محل عرض
  'trader',              -- تاجر
  'factory',             -- مصنع
  'inventory_location',  -- موقع مخزون: الشنطة، الخزنة، عهدة محل
  'cashbox',             -- صندوق نقد
  'income',              -- إيرادات
  'expense',             -- مصاريف
  'owner'                -- رأس المال
);

-- دفتران منفصلان تماماً. لا يُجمعان أبداً في رصيد واحد.
create type ledger_kind as enum ('gold', 'cash');

create type tx_type as enum (
  'opening_balance', 'sale', 'purchase',
  'consignment_out', 'consignment_return', 'consignment_sold',
  'cash_payment', 'gold_payment', 'pricing',
  'transfer', 'adjustment', 'reversal'
);

-- الأدمن غير مطلوب حالياً، لكن العمود موجود من الآن:
-- إضافته لاحقاً على بيانات حقيقية أصعب بكثير من تركه اليوم.
create type user_role as enum ('admin', 'operator');

-- ---------------------------------------------------------------------
-- ٢) الجداول
-- ---------------------------------------------------------------------

create table tenants (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  base_currency text not null default 'JOD',
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ملف المستخدم، مربوط بحساب الدخول في auth.users
create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  tenant_id  uuid references tenants(id) on delete restrict,
  full_name  text not null default '',
  role       user_role not null default 'operator',
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- العيارات ومعاملات التحويل. المعامل مضروب بمليون ليبقى عدداً صحيحاً:
-- 0.885 → 885000 ، 0.740 → 740000 ، عيار 24 → 1000000
create table karats (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null references tenants(id) on delete cascade,
  name       text not null,
  factor_ppm integer not null check (factor_ppm > 0 and factor_ppm <= 1000000),
  sort_order integer not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, name)
);

create table accounts (
  id                     uuid primary key default gen_random_uuid(),
  tenant_id              uuid not null references tenants(id) on delete cascade,
  name                   text not null,
  kind                   account_kind not null,
  phone                  text,
  address                text,
  note                   text,
  -- حساب العهدة الخاص بمحل العرض: الذهب المعروض عنده وما زال ملكنا
  consignment_account_id uuid references accounts(id) on delete restrict,
  -- مفتاح ثابت لحسابات النظام (الشنطة، الصندوق…) للوصول إليها بالكود
  system_key             text,
  is_system              boolean not null default false,
  is_active              boolean not null default true,
  deleted_at             timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  created_by             uuid references auth.users(id),
  unique (tenant_id, system_key)
);

create index accounts_tenant_idx on accounts (tenant_id) where deleted_at is null;

create table items (
  id               uuid primary key default gen_random_uuid(),
  tenant_id        uuid not null references tenants(id) on delete cascade,
  name             text not null,
  sku              text,
  default_karat_id uuid references karats(id) on delete set null,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- سعر الجرام (عيار 24) محفوظ تاريخياً حتى تبقى التقارير القديمة صحيحة
create table gold_prices (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references tenants(id) on delete cascade,
  effective_at        timestamptz not null default now(),
  price_per_gram_fils bigint not null check (price_per_gram_fils > 0),
  source              text,
  created_at          timestamptz not null default now(),
  created_by          uuid references auth.users(id)
);

create index gold_prices_tenant_time_idx
  on gold_prices (tenant_id, effective_at desc);

-- رأس الحركة. غير قابل للتعديل بعد الحفظ — التصحيح بقيد عكسي فقط.
create table transactions (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references tenants(id) on delete restrict,
  type                tx_type not null,
  occurred_at         timestamptz not null,
  doc_number          text not null,
  counterparty_id     uuid references accounts(id) on delete restrict,
  -- فارغ = ذهب غير مسعّر (تسعير مؤجل)
  price_per_gram_fils bigint check (price_per_gram_fils is null or price_per_gram_fils > 0),
  note                text,
  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  reversed_by_tx_id   uuid references transactions(id) on delete restrict,
  reverses_tx_id      uuid references transactions(id) on delete restrict,
  unique (tenant_id, doc_number)
);

create index transactions_tenant_time_idx
  on transactions (tenant_id, occurred_at desc);
create index transactions_counterparty_idx
  on transactions (counterparty_id, occurred_at desc);

-- سطور القيد المزدوج.
-- الإشارة: موجب = مدين، سالب = دائن.
--   حساب محل، دفتر ذهب، موجب  → المحل مدين لنا بالذهب
--   حساب مخزون، دفتر ذهب، موجب → الذهب موجود لدينا في ذلك الموقع
-- مجموع كل دفتر داخل الحركة الواحدة = صفر (تفرضه دالة post_transaction).
create table postings (
  id                   uuid primary key default gen_random_uuid(),
  tenant_id            uuid not null references tenants(id) on delete restrict,
  tx_id                uuid not null references transactions(id) on delete restrict,
  seq                  integer not null,
  account_id           uuid not null references accounts(id) on delete restrict,
  ledger               ledger_kind not null,
  -- ذهب: مليجرام صافي (عيار 24). نقد: فلس.
  amount               bigint not null,
  -- نسخة من معامل العيار وقت التنفيذ: تعديل جدول العيارات لاحقاً
  -- لا يغيّر أي حركة سابقة.
  karat_id             uuid references karats(id) on delete restrict,
  karat_ppm            integer,
  gross_weight_mg      bigint,
  item_id              uuid references items(id) on delete restrict,
  quantity             integer,
  making_per_gram_fils bigint,
  note                 text,
  created_at           timestamptz not null default now(),
  unique (tx_id, seq)
);

create index postings_account_idx on postings (account_id, ledger);
create index postings_tx_idx on postings (tx_id);

create table audit_log (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null references tenants(id) on delete cascade,
  entity     text not null,
  entity_id  uuid not null,
  action     text not null,
  details    text,
  actor      uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index audit_log_tenant_time_idx on audit_log (tenant_id, created_at desc);

-- عدّاد أرقام المستندات. على السيرفر، فلا تتصادم الأرقام بين الأجهزة إطلاقاً.
create table doc_counters (
  tenant_id uuid not null references tenants(id) on delete cascade,
  year      integer not null,
  last_no   bigint not null default 0,
  primary key (tenant_id, year)
);

-- ---------------------------------------------------------------------
-- ٣) عدم قابلية الحركات للتعديل
--    التصحيح الوحيد المسموح: قيد عكسي.
-- ---------------------------------------------------------------------

create or replace function forbid_mutation()
returns trigger language plpgsql as $$
begin
  raise exception 'الحركات المحفوظة لا تُعدَّل ولا تُحذف — استخدم القيد العكسي';
end $$;

create trigger postings_immutable
  before update or delete on postings
  for each row execute function forbid_mutation();

create trigger audit_log_immutable
  before update or delete on audit_log
  for each row execute function forbid_mutation();

-- الحركة يُسمح فيها بتغيير واحد فقط: تسجيل القيد العكسي الذي ألغاها.
create or replace function transactions_guard()
returns trigger language plpgsql as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'لا يجوز حذف حركة — استخدم القيد العكسي';
  end if;

  if new.id                  is distinct from old.id
  or new.tenant_id           is distinct from old.tenant_id
  or new.type                is distinct from old.type
  or new.occurred_at         is distinct from old.occurred_at
  or new.doc_number          is distinct from old.doc_number
  or new.counterparty_id     is distinct from old.counterparty_id
  or new.price_per_gram_fils is distinct from old.price_per_gram_fils
  or new.note                is distinct from old.note
  or new.created_by          is distinct from old.created_by
  or new.created_at          is distinct from old.created_at
  or new.reverses_tx_id      is distinct from old.reverses_tx_id
  then
    raise exception 'لا يجوز تعديل حركة محفوظة — استخدم القيد العكسي';
  end if;

  if old.reversed_by_tx_id is not null then
    raise exception 'هذه الحركة ملغاة مسبقاً';
  end if;

  return new;
end $$;

create trigger transactions_immutable
  before update or delete on transactions
  for each row execute function transactions_guard();
