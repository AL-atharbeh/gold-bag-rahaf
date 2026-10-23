-- =====================================================================
--  المنصّة: المنشآت، العضويات، الصلاحيات، الشنط، الاشتراكات، لوحة الإدارة
--
--  الفكرة الأساسية:
--  • الشخص (auth.users برقم هاتفه) منفصل عن المنشأة (tenants).
--  • الشخص قد يكون عضواً في أكثر من منشأة — موزّع تابع لمصنع وصاحب
--    حساب مستقل في آن واحد — ويبدّل بينها. profiles.tenant_id هي
--    المنشأة "النشطة" حالياً، فتبقى كل سياسات RLS القديمة صالحة.
--  • current_tenant_id() لا تُرجع منشأة إلا إن كانت مفعّلة والعضوية
--    سارية؛ فالمنشأة المعلّقة أو الموقوفة لا ترى شيئاً من بياناتها.
--  • انتهاء الاشتراك يجعل المنشأة للقراءة فقط، لا مقفلة.
--
--  يُنفَّذ بعد 0001…0007 (وبعد fix_and_seed إن كان قد نُفِّذ — هذا الملف
--  يعيد الحماية التي عطّلها).
-- =====================================================================

-- ---------------------------------------------------------------------
-- ١) الأنواع
-- ---------------------------------------------------------------------
do $$ begin
  create type org_type as enum ('distributor', 'factory', 'shop');
exception when duplicate_object then null; end $$;

do $$ begin
  create type org_status as enum ('pending', 'active', 'suspended', 'rejected');
exception when duplicate_object then null; end $$;

do $$ begin
  create type member_role as enum ('owner', 'manager', 'bag_holder', 'assistant');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- ٢) الباقات
--    السعر بالفلس. السعر الصفري يعني "لم يُحدَّد بعد" ويُعدَّل من اللوحة.
-- ---------------------------------------------------------------------
create table if not exists plans (
  id                   uuid primary key default gen_random_uuid(),
  code                 text not null unique,
  org_type             org_type not null,
  name_ar              text not null,
  name_en              text not null,
  price_fils           bigint not null default 0 check (price_fils >= 0),
  period_months        int    not null default 12 check (period_months > 0),
  max_users            int    not null default 2  check (max_users > 0),
  max_bags             int    not null default 1  check (max_bags >= 0),
  extra_bag_price_fils bigint not null default 0 check (extra_bag_price_fils >= 0),
  is_active            boolean not null default true,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

insert into plans (code, org_type, name_ar, name_en, max_users, max_bags) values
  ('distributor', 'distributor', 'موزّع مستقل',   'Independent distributor', 2, 2),
  ('factory',     'factory',     'مصنع / مشغل',  'Factory / workshop',      10, 5),
  ('shop',        'shop',        'محل ذهب',      'Gold shop',               3, 0)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------
-- ٣) المنشأة = tenants القائمة، بأعمدة جديدة
-- ---------------------------------------------------------------------
-- المنشآت الموجودة قبل هذا الملف موزّعون مفعَّلون؛ الجديدة تبدأ معلّقة.
alter table tenants add column if not exists org_type org_type not null default 'distributor';
alter table tenants add column if not exists status   org_status not null default 'active';
alter table tenants alter column status set default 'pending';

alter table tenants add column if not exists owner_name           text;
alter table tenants add column if not exists phone                text;
alter table tenants add column if not exists city                 text;
alter table tenants add column if not exists status_note          text;
alter table tenants add column if not exists plan_id              uuid references plans(id);
-- فارغ = بلا تاريخ انتهاء (المنشآت القديمة حتى يحدد المدير اشتراكها)
alter table tenants add column if not exists subscription_ends_at timestamptz;
alter table tenants add column if not exists activated_at         timestamptz;
alter table tenants add column if not exists created_by           uuid references auth.users(id);

alter table profiles add column if not exists phone  text;
alter table profiles add column if not exists locale text;

-- ---------------------------------------------------------------------
-- ٤) العضويات والدعوات
-- ---------------------------------------------------------------------
create table if not exists memberships (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references tenants(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         member_role not null,
  -- مفاتيح الصلاحيات (انظر has_perm). المالك يملكها كلها ضمناً.
  permissions  text[] not null default '{}',
  display_name text not null default '',
  is_active    boolean not null default true,
  created_by   uuid references auth.users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (tenant_id, user_id)
);

create index if not exists memberships_user_idx on memberships (user_id);

create table if not exists invitations (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references tenants(id) on delete cascade,
  -- أرقام فقط بصيغة 9627XXXXXXXX — نفس صيغة auth.users.phone
  phone        text not null,
  role         member_role not null,
  permissions  text[] not null default '{}',
  display_name text not null default '',
  status       text not null default 'pending'
               check (status in ('pending', 'accepted', 'cancelled')),
  created_by   uuid references auth.users(id),
  created_at   timestamptz not null default now(),
  accepted_by  uuid references auth.users(id),
  accepted_at  timestamptz
);

create unique index if not exists invitations_pending_uniq
  on invitations (tenant_id, phone) where status = 'pending';

-- ---------------------------------------------------------------------
-- ٥) الشنط — كل شنطة حساب مخزون، وقد يحملها عضو بعينه
-- ---------------------------------------------------------------------
create table if not exists bags (
  id             uuid primary key default gen_random_uuid(),
  tenant_id      uuid not null references tenants(id) on delete cascade,
  name           text not null,
  account_id     uuid not null references accounts(id) on delete restrict,
  holder_user_id uuid references auth.users(id) on delete set null,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (tenant_id, name),
  unique (account_id)
);

-- ---------------------------------------------------------------------
-- ٦) مديرو المنصّة وسجل الاشتراكات
-- ---------------------------------------------------------------------
create table if not exists platform_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists org_events (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null references tenants(id) on delete cascade,
  action     text not null,
  details    jsonb not null default '{}',
  actor      uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists org_events_tenant_idx on org_events (tenant_id, created_at desc);

-- منع تكرار الحركة عند إعادة الضغط بعد انقطاع الاتصال
alter table transactions add column if not exists client_ref uuid;
create unique index if not exists transactions_client_ref_uniq
  on transactions (tenant_id, client_ref) where client_ref is not null;

-- ---------------------------------------------------------------------
-- ٧) الدوال المساعدة
-- ---------------------------------------------------------------------

-- "0791234567" أو "+962 79 123 4567" أو "00962791234567" → "962791234567"
create or replace function normalize_phone(p text)
returns text language plpgsql immutable as $$
declare v text := regexp_replace(coalesce(p, ''), '\D', '', 'g');
begin
  if v like '00%' then v := substr(v, 3); end if;
  if length(v) = 10 and v like '0%' then v := '962' || substr(v, 2); end if;
  if length(v) = 9  and v like '7%' then v := '962' || v; end if;
  return v;
end $$;

create or replace function is_platform_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from platform_admins where user_id = auth.uid())
$$;

-- المنشأة النشطة — فقط إن كانت مفعّلة والعضوية سارية.
create or replace function current_tenant_id()
returns uuid language sql stable security definer set search_path = public as $$
  select p.tenant_id
  from profiles p
  join memberships m on m.tenant_id = p.tenant_id and m.user_id = p.id and m.is_active
  join tenants t     on t.id = p.tenant_id and t.status = 'active'
  where p.id = auth.uid() and p.is_active
$$;

create or replace function current_role_in_tenant()
returns member_role language sql stable security definer set search_path = public as $$
  select m.role from memberships m
  where m.tenant_id = current_tenant_id() and m.user_id = auth.uid() and m.is_active
$$;

create or replace function is_tenant_owner()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(current_role_in_tenant() = 'owner', false)
$$;

--  مفاتيح الصلاحيات:
--   ledger.write    تسجيل الحركات في الدفاتر
--   finance.view    رؤية الأرصدة والتقارير المالية
--   bags.view_all   رؤية كل الشنط
--   bags.issue      تسليم بضاعة للشنط
--   bags.confirm    تأكيد الاستلام والمرتجعات
--   stock.count     طلب الجرد واعتماده
--   cheques.manage  إدارة الشيكات
--  إدارة الفريق والشنط للمالك وحده، ولا تُمنح.
create or replace function has_perm(p_perm text)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((
    select m.role = 'owner' or p_perm = any (m.permissions)
    from memberships m
    where m.tenant_id = current_tenant_id() and m.user_id = auth.uid() and m.is_active
  ), false)
$$;

-- الكتابة مسموحة ما دام الاشتراك سارياً.
create or replace function current_tenant_writable()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((
    select t.subscription_ends_at is null or t.subscription_ends_at > now()
    from tenants t where t.id = current_tenant_id()
  ), false)
$$;

create or replace function assert_can_write(p_perm text default 'ledger.write')
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if current_tenant_id() is null then
    raise exception 'الحساب غير مفعّل' using errcode = '42501';
  end if;
  if not current_tenant_writable() then
    raise exception 'انتهى الاشتراك — الحساب للقراءة فقط' using errcode = '42501';
  end if;
  if not has_perm(p_perm) then
    raise exception 'لا تملك صلاحية لهذه العملية' using errcode = '42501';
  end if;
end $$;

-- الصلاحيات الافتراضية لكل دور عند الدعوة
create or replace function default_permissions(p_role member_role)
returns text[] language sql immutable as $$
  select case p_role
    when 'owner'      then '{}'::text[]
    when 'manager'    then array['ledger.write','finance.view','bags.view_all',
                                 'bags.issue','bags.confirm','stock.count','cheques.manage']
    when 'bag_holder' then array['ledger.write']
    when 'assistant'  then array['ledger.write']
  end
$$;

-- العيارات وحسابات النظام لمنشأة جديدة. آمنة للتكرار.
create or replace function seed_tenant(p_tenant uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_shanta uuid; v_type org_type;
begin
  insert into karats (tenant_id, name, factor_ppm, out_factor_ppm, in_factor_ppm, sort_order) values
    (p_tenant, 'عيار 24', 1000000, 1000000, 1000000, 0),
    (p_tenant, 'عيار 21',  885000,  885000,  870000, 1),
    (p_tenant, 'عيار 18',  790000,  790000,  740000, 2),
    (p_tenant, 'عيار 9',   375000,  375000,  375000, 3)
  on conflict (tenant_id, name) do nothing;

  insert into accounts (tenant_id, name, kind, system_key, is_system) values
    (p_tenant, 'الشنطة',         'inventory_location', 'shanta',         true),
    (p_tenant, 'الخزنة',         'inventory_location', 'vault',          true),
    (p_tenant, 'الصندوق',        'cashbox',            'cashbox',        true),
    (p_tenant, 'إيراد المصنعية', 'income',             'making_income',  true),
    (p_tenant, 'أرباح وفروقات',  'income',             'trading_income', true),
    (p_tenant, 'رأس المال',      'owner',              'capital',        true)
  on conflict (tenant_id, system_key) do nothing;

  select org_type into v_type from tenants where id = p_tenant;
  if v_type in ('distributor', 'factory') then
    select id into v_shanta from accounts where tenant_id = p_tenant and system_key = 'shanta';
    insert into bags (tenant_id, name, account_id)
    values (p_tenant, 'الشنطة الرئيسية', v_shanta)
    on conflict do nothing;
  end if;
end $$;

-- ينشئ عضوية فوراً إن كان صاحب الرقم مسجّلاً، وإلا يترك دعوة
-- تُقبل تلقائياً عند أول دخول له.
create or replace function _invite(
  p_tenant uuid, p_phone text, p_role member_role,
  p_permissions text[], p_display_name text
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_phone text := normalize_phone(p_phone);
  v_user  uuid;
  v_id    uuid;
begin
  if length(v_phone) < 11 then
    raise exception 'رقم الهاتف غير صالح';
  end if;

  select id into v_user from auth.users where phone = v_phone limit 1;

  if v_user is not null then
    insert into memberships (tenant_id, user_id, role, permissions, display_name, created_by)
    values (p_tenant, v_user, p_role, coalesce(p_permissions, default_permissions(p_role)),
            coalesce(p_display_name, ''), auth.uid())
    on conflict (tenant_id, user_id) do update
      set role = excluded.role, permissions = excluded.permissions,
          display_name = excluded.display_name, is_active = true, updated_at = now()
    returning id into v_id;

    -- المنشأة الأولى للشخص تصبح نشطة تلقائياً
    update profiles set tenant_id = p_tenant, updated_at = now()
    where id = v_user and tenant_id is null;

    return jsonb_build_object('kind', 'member', 'id', v_id);
  end if;

  insert into invitations (tenant_id, phone, role, permissions, display_name, created_by)
  values (p_tenant, v_phone, p_role, coalesce(p_permissions, default_permissions(p_role)),
          coalesce(p_display_name, ''), auth.uid())
  on conflict (tenant_id, phone) where status = 'pending' do update
    set role = excluded.role, permissions = excluded.permissions,
        display_name = excluded.display_name
  returning id into v_id;

  return jsonb_build_object('kind', 'invitation', 'id', v_id);
end $$;

create or replace function _seat_count(p_tenant uuid)
returns int language sql stable security definer set search_path = public as $$
  select (select count(*) from memberships where tenant_id = p_tenant and is_active)::int
       + (select count(*) from invitations where tenant_id = p_tenant and status = 'pending')::int
$$;

create or replace function _log(p_tenant uuid, p_action text, p_details jsonb default '{}')
returns void language sql security definer set search_path = public as $$
  insert into org_events (tenant_id, action, details, actor)
  values (p_tenant, p_action, coalesce(p_details, '{}'), auth.uid())
$$;

-- ---------------------------------------------------------------------
-- ٨) إنشاء الملف الشخصي — مع رقم الهاتف
-- ---------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name, phone)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), new.phone)
  on conflict (id) do update set phone = excluded.phone;
  return new;
end $$;

-- ---------------------------------------------------------------------
-- ٩) واجهة التطبيق: الجلسة، التسجيل، التبديل
-- ---------------------------------------------------------------------

-- كل ما يحتاجه التطبيق بعد الدخول، في نداء واحد. يقبل الدعوات المعلّقة
-- لرقم المستخدم أولاً.
create or replace function load_my_context()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_phone text;
  v_inv   record;
  v_prof  profiles%rowtype;
begin
  if v_uid is null then
    raise exception 'يلزم تسجيل الدخول' using errcode = '42501';
  end if;

  select phone into v_phone from auth.users where id = v_uid;

  insert into profiles (id, phone) values (v_uid, v_phone)
  on conflict (id) do update set phone = excluded.phone;

  for v_inv in
    select * from invitations where phone = v_phone and status = 'pending'
  loop
    insert into memberships (tenant_id, user_id, role, permissions, display_name, created_by)
    values (v_inv.tenant_id, v_uid, v_inv.role, v_inv.permissions, v_inv.display_name, v_inv.created_by)
    on conflict (tenant_id, user_id) do update
      set role = excluded.role, permissions = excluded.permissions, is_active = true;
    update invitations set status = 'accepted', accepted_by = v_uid, accepted_at = now()
    where id = v_inv.id;
  end loop;

  select * into v_prof from profiles where id = v_uid;

  -- المنشأة النشطة لم تعد صالحة؟ اختر أول عضوية سارية.
  if v_prof.tenant_id is null or not exists (
    select 1 from memberships
    where user_id = v_uid and tenant_id = v_prof.tenant_id and is_active
  ) then
    update profiles set tenant_id = (
      select m.tenant_id from memberships m
      where m.user_id = v_uid and m.is_active
      order by m.created_at limit 1
    ) where id = v_uid
    returning * into v_prof;
  end if;

  return jsonb_build_object(
    'user_id',           v_uid,
    'phone',             v_phone,
    'full_name',         v_prof.full_name,
    'locale',            v_prof.locale,
    'is_platform_admin', is_platform_admin(),
    'active_tenant_id',  v_prof.tenant_id,
    'memberships', coalesce((
      select jsonb_agg(jsonb_build_object(
        'membership_id',        m.id,
        'tenant_id',            t.id,
        'org_name',             t.name,
        'org_type',             t.org_type,
        'status',               t.status,
        'status_note',          t.status_note,
        'role',                 m.role,
        'permissions',          m.permissions,
        'display_name',         m.display_name,
        'subscription_ends_at', t.subscription_ends_at,
        'plan_name_ar',         pl.name_ar,
        'plan_name_en',         pl.name_en,
        'max_users',            pl.max_users,
        'max_bags',             pl.max_bags
      ) order by m.created_at)
      from memberships m
      join tenants t on t.id = m.tenant_id
      left join plans pl on pl.id = t.plan_id
      where m.user_id = v_uid and m.is_active
    ), '[]'::jsonb)
  );
end $$;

-- تسجيل منشأة جديدة — تبقى معلّقة حتى يفعّلها المدير.
create or replace function register_organization(
  p_org_name   text,
  p_org_type   org_type,
  p_owner_name text,
  p_city       text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := auth.uid();
  v_phone  text;
  v_tenant uuid;
  v_plan   uuid;
begin
  if v_uid is null then
    raise exception 'يلزم تسجيل الدخول' using errcode = '42501';
  end if;
  if coalesce(trim(p_org_name), '') = '' or coalesce(trim(p_owner_name), '') = '' then
    raise exception 'الاسم التجاري واسم المالك مطلوبان';
  end if;

  -- طلب واحد معلّق في كل مرة يكفي
  if exists (
    select 1 from memberships m join tenants t on t.id = m.tenant_id
    where m.user_id = v_uid and m.role = 'owner' and t.status = 'pending'
  ) then
    raise exception 'لديك طلب تسجيل قيد المراجعة';
  end if;

  select phone into v_phone from auth.users where id = v_uid;
  select id into v_plan from plans where org_type = p_org_type and is_active
  order by created_at limit 1;

  insert into tenants (name, org_type, status, owner_name, phone, city, plan_id, created_by)
  values (trim(p_org_name), p_org_type, 'pending', trim(p_owner_name), v_phone,
          nullif(trim(coalesce(p_city, '')), ''), v_plan, v_uid)
  returning id into v_tenant;

  perform seed_tenant(v_tenant);

  insert into memberships (tenant_id, user_id, role, display_name, created_by)
  values (v_tenant, v_uid, 'owner', trim(p_owner_name), v_uid);

  update profiles
     set tenant_id = v_tenant,
         full_name = case when full_name = '' then trim(p_owner_name) else full_name end,
         updated_at = now()
   where id = v_uid;

  perform _log(v_tenant, 'registered', jsonb_build_object('org_type', p_org_type));
  return v_tenant;
end $$;

create or replace function switch_tenant(p_tenant uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from memberships
    where user_id = auth.uid() and tenant_id = p_tenant and is_active
  ) then
    raise exception 'لست عضواً في هذه المنشأة' using errcode = '42501';
  end if;
  update profiles set tenant_id = p_tenant, updated_at = now() where id = auth.uid();
end $$;

create or replace function set_my_locale(p_locale text)
returns void language sql security definer set search_path = public as $$
  update profiles set locale = p_locale, updated_at = now() where id = auth.uid()
$$;

-- ---------------------------------------------------------------------
-- ١٠) الفريق — للمالك وحده
-- ---------------------------------------------------------------------
create or replace function invite_member(
  p_phone        text,
  p_role         member_role,
  p_permissions  text[] default null,
  p_display_name text default ''
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_tenant uuid := current_tenant_id();
  v_max    int;
  v_res    jsonb;
begin
  if not is_tenant_owner() then
    raise exception 'إدارة الفريق للمالك فقط' using errcode = '42501';
  end if;
  if p_role = 'owner' then
    raise exception 'لا يمكن إضافة مالك ثانٍ';
  end if;
  if not current_tenant_writable() then
    raise exception 'انتهى الاشتراك — الحساب للقراءة فقط' using errcode = '42501';
  end if;

  select pl.max_users into v_max from tenants t join plans pl on pl.id = t.plan_id
  where t.id = v_tenant;
  if v_max is not null and _seat_count(v_tenant) >= v_max then
    raise exception 'وصلت إلى الحد الأقصى للمستخدمين في باقتك (%)', v_max;
  end if;

  v_res := _invite(v_tenant, p_phone, p_role, p_permissions, p_display_name);
  perform _log(v_tenant, 'member_invited',
               jsonb_build_object('phone', normalize_phone(p_phone), 'role', p_role));
  return v_res;
end $$;

create or replace function update_member(
  p_membership_id uuid,
  p_role          member_role,
  p_permissions   text[],
  p_display_name  text,
  p_is_active     boolean
) returns void language plpgsql security definer set search_path = public as $$
declare v_m memberships%rowtype;
begin
  if not is_tenant_owner() then
    raise exception 'إدارة الفريق للمالك فقط' using errcode = '42501';
  end if;

  select * into v_m from memberships
  where id = p_membership_id and tenant_id = current_tenant_id();
  if not found then
    raise exception 'العضو غير موجود';
  end if;
  if v_m.role = 'owner' then
    raise exception 'لا يمكن تعديل دور المالك أو إيقافه';
  end if;
  if p_role = 'owner' then
    raise exception 'لا يمكن إضافة مالك ثانٍ';
  end if;

  update memberships
     set role = p_role,
         permissions = coalesce(p_permissions, '{}'),
         display_name = coalesce(p_display_name, display_name),
         is_active = p_is_active,
         updated_at = now()
   where id = p_membership_id;

  -- العضو الموقوف لا يحمل شنطة
  if not p_is_active then
    update bags set holder_user_id = null, updated_at = now()
    where tenant_id = v_m.tenant_id and holder_user_id = v_m.user_id;
  end if;

  perform _log(v_m.tenant_id, 'member_updated',
               jsonb_build_object('membership_id', p_membership_id, 'role', p_role,
                                  'is_active', p_is_active));
end $$;

create or replace function cancel_invitation(p_invitation_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_tenant_owner() then
    raise exception 'إدارة الفريق للمالك فقط' using errcode = '42501';
  end if;
  update invitations set status = 'cancelled'
  where id = p_invitation_id and tenant_id = current_tenant_id() and status = 'pending';
end $$;

-- ---------------------------------------------------------------------
-- ١١) الشنط — للمالك وحده
-- ---------------------------------------------------------------------
create or replace function create_bag(p_name text, p_holder_user_id uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_tenant  uuid := current_tenant_id();
  v_max     int;
  v_count   int;
  v_account uuid;
  v_bag     uuid;
begin
  if not is_tenant_owner() then
    raise exception 'إدارة الشنط للمالك فقط' using errcode = '42501';
  end if;
  if not current_tenant_writable() then
    raise exception 'انتهى الاشتراك — الحساب للقراءة فقط' using errcode = '42501';
  end if;
  if coalesce(trim(p_name), '') = '' then
    raise exception 'اسم الشنطة مطلوب';
  end if;

  select pl.max_bags into v_max from tenants t join plans pl on pl.id = t.plan_id
  where t.id = v_tenant;
  select count(*) into v_count from bags where tenant_id = v_tenant and is_active;
  if v_max is not null and v_count >= v_max then
    raise exception 'وصلت إلى الحد الأقصى للشنط في باقتك (%)', v_max;
  end if;

  if p_holder_user_id is not null and not exists (
    select 1 from memberships
    where tenant_id = v_tenant and user_id = p_holder_user_id and is_active
  ) then
    raise exception 'حامل الشنطة ليس عضواً في المنشأة';
  end if;

  insert into accounts (tenant_id, name, kind, is_system, created_by)
  values (v_tenant, 'شنطة ' || trim(p_name), 'inventory_location', true, auth.uid())
  returning id into v_account;

  insert into bags (tenant_id, name, account_id, holder_user_id)
  values (v_tenant, trim(p_name), v_account, p_holder_user_id)
  returning id into v_bag;

  perform _log(v_tenant, 'bag_created', jsonb_build_object('bag_id', v_bag, 'name', p_name));
  return v_bag;
end $$;

create or replace function update_bag(
  p_bag_id uuid, p_name text, p_holder_user_id uuid, p_is_active boolean
) returns void language plpgsql security definer set search_path = public as $$
declare v_tenant uuid := current_tenant_id();
begin
  if not is_tenant_owner() then
    raise exception 'إدارة الشنط للمالك فقط' using errcode = '42501';
  end if;
  if p_holder_user_id is not null and not exists (
    select 1 from memberships
    where tenant_id = v_tenant and user_id = p_holder_user_id and is_active
  ) then
    raise exception 'حامل الشنطة ليس عضواً في المنشأة';
  end if;

  update bags
     set name = coalesce(nullif(trim(p_name), ''), name),
         holder_user_id = p_holder_user_id,
         is_active = p_is_active,
         updated_at = now()
   where id = p_bag_id and tenant_id = v_tenant;
  if not found then
    raise exception 'الشنطة غير موجودة';
  end if;
end $$;

-- الفريق مع أرقام الهواتف — للمالك ومن يرى كل الشنط
create or replace function list_team()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_tenant uuid := current_tenant_id();
begin
  if v_tenant is null then
    raise exception 'الحساب غير مفعّل' using errcode = '42501';
  end if;
  if not (is_tenant_owner() or has_perm('bags.view_all')) then
    raise exception 'لا تملك صلاحية لهذه العملية' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
        'membership_id', m.id, 'user_id', m.user_id, 'role', m.role,
        'permissions', m.permissions, 'display_name', m.display_name,
        'is_active', m.is_active, 'phone', p.phone)
        order by (m.role = 'owner') desc, m.created_at)
      from memberships m left join profiles p on p.id = m.user_id
      where m.tenant_id = v_tenant), '[]'::jsonb),
    'invitations', case when is_tenant_owner() then coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', i.id, 'phone', i.phone, 'role', i.role,
        'permissions', i.permissions, 'display_name', i.display_name,
        'created_at', i.created_at) order by i.created_at)
      from invitations i
      where i.tenant_id = v_tenant and i.status = 'pending'), '[]'::jsonb)
      else '[]'::jsonb end
  );
end $$;

create or replace function list_bags()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_tenant uuid := current_tenant_id();
begin
  if v_tenant is null then
    raise exception 'الحساب غير مفعّل' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', b.id, 'name', b.name, 'account_id', b.account_id,
      'holder_user_id', b.holder_user_id, 'holder_name', m.display_name,
      'is_active', b.is_active) order by b.created_at)
    from bags b
    left join memberships m on m.tenant_id = b.tenant_id and m.user_id = b.holder_user_id
    where b.tenant_id = v_tenant
      and (b.holder_user_id = auth.uid() or has_perm('bags.view_all'))
  ), '[]'::jsonb);
end $$;

-- ---------------------------------------------------------------------
-- ١٢) الدفتر: الحفظ عبر post_entry — صلاحية + اشتراك + عدم تكرار
--
--  post_transaction تبقى الحارس الأخير (التوازن)، ونضيف إليها فحص
--  الكتابة فتشمل كل الدوال التي تناديها (الشيكات، التجزئة، العكس).
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
  perform assert_can_write('ledger.write');

  if jsonb_typeof(p_postings) <> 'array' then
    raise exception 'سطور القيد يجب أن تكون مصفوفة';
  end if;

  select count(*) into v_count from jsonb_array_elements(p_postings);
  if v_count < 2 then
    raise exception 'القيد يحتاج سطرين على الأقل';
  end if;

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
    v_tenant, v_tx, (t.ord - 1)::int,
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

-- الواجهة الوحيدة التي يستعملها التطبيق للحفظ.
-- client_ref يُولَّد على الجهاز قبل الإرسال: إعادة الإرسال بعد انقطاع
-- الاتصال ترجع الحركة نفسها بدل تكرارها.
create or replace function post_entry(
  p_client_ref          uuid,
  p_type                tx_type,
  p_occurred_at         timestamptz,
  p_postings            jsonb,
  p_counterparty_id     uuid   default null,
  p_price_per_gram_fils bigint default null,
  p_note                text   default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_doc text;
begin
  if p_client_ref is not null then
    select id, doc_number into v_id, v_doc from transactions
    where tenant_id = current_tenant_id() and client_ref = p_client_ref;
    if found then
      return jsonb_build_object('tx_id', v_id, 'doc_number', v_doc, 'duplicate', true);
    end if;
  end if;

  v_id := post_transaction(p_type, p_occurred_at, p_postings, p_counterparty_id,
                           p_price_per_gram_fils, p_note, null);

  update transactions set client_ref = p_client_ref where id = v_id;
  select doc_number into v_doc from transactions where id = v_id;

  return jsonb_build_object('tx_id', v_id, 'doc_number', v_doc, 'duplicate', false);
end $$;

create or replace function reverse_entry(p_tx_id uuid, p_reason text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_doc text;
begin
  v_id := reverse_transaction(p_tx_id, p_reason);
  select doc_number into v_doc from transactions where id = v_id;
  return jsonb_build_object('tx_id', v_id, 'doc_number', v_doc);
end $$;

-- إصلاح: post_transaction ترجع معرّف الحركة لا رقمها، فكان الربط يفشل.
create or replace function clear_cheque(
  p_cheque_id   uuid,
  p_cashbox_id  uuid,
  p_occurred_at timestamptz default now(),
  p_note        text default null
) returns text language plpgsql security definer set search_path = public as $$
declare
  v_cheque cheques%rowtype;
  v_sign   int;
  v_tx     uuid;
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

-- إنشاء محل عرض: نفس السابق مع فحص الكتابة
create or replace function create_showroom(
  p_name  text,
  p_phone text default null,
  p_note  text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_tenant  uuid := current_tenant_id();
  v_shop    uuid := gen_random_uuid();
  v_consign uuid := gen_random_uuid();
begin
  perform assert_can_write('ledger.write');

  insert into accounts (id, tenant_id, name, kind, is_system, created_by)
  values (v_consign, v_tenant, 'عهدة ' || p_name, 'inventory_location', true, auth.uid());

  insert into accounts (id, tenant_id, name, kind, phone, note,
                        consignment_account_id, created_by)
  values (v_shop, v_tenant, p_name, 'showroom', p_phone, p_note, v_consign, auth.uid());

  insert into audit_log (tenant_id, entity, entity_id, action, details, actor)
  values (v_tenant, 'account', v_shop, 'create', 'محل عرض: ' || p_name, auth.uid());

  return v_shop;
end $$;

-- bootstrap_tenant القديمة كانت تضم أي مستخدم جديد لأول منشأة —
-- ثغرة بعد فتح التسجيل للعموم. تُستبدل بإرجاع المنشأة النشطة فقط.
create or replace function bootstrap_tenant(p_name text default null)
returns uuid language sql stable security definer set search_path = public as $$
  select current_tenant_id()
$$;

-- ---------------------------------------------------------------------
-- ١٣) لوحة الإدارة — لمديري المنصّة فقط
-- ---------------------------------------------------------------------
create or replace function _require_admin()
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then
    raise exception 'هذه العملية لمدير المنصّة فقط' using errcode = '42501';
  end if;
end $$;

create or replace function admin_overview()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform _require_admin();
  return jsonb_build_object(
    'pending',   (select count(*) from tenants where status = 'pending'),
    'active',    (select count(*) from tenants where status = 'active'),
    'suspended', (select count(*) from tenants where status = 'suspended'),
    'expiring',  (select count(*) from tenants where status = 'active'
                    and subscription_ends_at between now() and now() + interval '14 days'),
    'expired',   (select count(*) from tenants where status = 'active'
                    and subscription_ends_at < now()),
    'by_type', coalesce((
      select jsonb_object_agg(org_type::text, n) from (
        select org_type, count(*) n from tenants where status = 'active' group by org_type
      ) x), '{}'::jsonb),
    'users',     (select count(*) from memberships where is_active)
  );
end $$;

create or replace function admin_list_orgs(
  p_status org_status default null,
  p_type   org_type   default null,
  p_search text       default null
) returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform _require_admin();
  return coalesce((
    select jsonb_agg(row_to_json(x) order by x.created_at desc) from (
      select t.id, t.name, t.org_type, t.status, t.status_note, t.owner_name,
             t.phone, t.city, t.created_at, t.activated_at, t.subscription_ends_at,
             t.plan_id, pl.name_ar as plan_name_ar, pl.name_en as plan_name_en,
             (select count(*) from memberships m
               where m.tenant_id = t.id and m.is_active) as members,
             (select count(*) from bags b
               where b.tenant_id = t.id and b.is_active) as bags
      from tenants t
      left join plans pl on pl.id = t.plan_id
      where (p_status is null or t.status = p_status)
        and (p_type is null or t.org_type = p_type)
        and (p_search is null or p_search = ''
             or t.name ilike '%' || p_search || '%'
             or coalesce(t.owner_name, '') ilike '%' || p_search || '%'
             or coalesce(t.phone, '') like '%' || normalize_phone(p_search) || '%')
    ) x
  ), '[]'::jsonb);
end $$;

create or replace function admin_org_detail(p_tenant uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform _require_admin();
  return jsonb_build_object(
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
        'membership_id', m.id, 'user_id', m.user_id, 'role', m.role,
        'display_name', m.display_name, 'is_active', m.is_active,
        'phone', p.phone) order by m.created_at)
      from memberships m left join profiles p on p.id = m.user_id
      where m.tenant_id = p_tenant), '[]'::jsonb),
    'invitations', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', i.id, 'phone', i.phone, 'role', i.role, 'display_name', i.display_name,
        'created_at', i.created_at) order by i.created_at)
      from invitations i where i.tenant_id = p_tenant and i.status = 'pending'), '[]'::jsonb),
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
        'action', e.action, 'details', e.details, 'created_at', e.created_at)
        order by e.created_at desc)
      from (select * from org_events where tenant_id = p_tenant
            order by created_at desc limit 30) e), '[]'::jsonb)
  );
end $$;

-- تفعيل أو تجديد: يضيف الأشهر إلى ما تبقّى من الاشتراك.
create or replace function admin_activate(p_tenant uuid, p_plan_id uuid, p_months int)
returns void language plpgsql security definer set search_path = public as $$
declare v_ends timestamptz;
begin
  perform _require_admin();
  if p_months is null or p_months <= 0 then
    raise exception 'عدد الأشهر يجب أن يكون أكبر من صفر';
  end if;

  select greatest(coalesce(subscription_ends_at, now()), now())
         + make_interval(months => p_months)
    into v_ends from tenants where id = p_tenant;
  if not found then
    raise exception 'المنشأة غير موجودة';
  end if;

  update tenants
     set status = 'active',
         status_note = null,
         plan_id = coalesce(p_plan_id, plan_id),
         subscription_ends_at = v_ends,
         activated_at = coalesce(activated_at, now()),
         updated_at = now()
   where id = p_tenant;

  perform seed_tenant(p_tenant);
  perform _log(p_tenant, 'activated',
               jsonb_build_object('plan_id', p_plan_id, 'months', p_months, 'ends_at', v_ends));
end $$;

create or replace function admin_set_status(p_tenant uuid, p_status org_status, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform _require_admin();
  update tenants set status = p_status, status_note = p_note, updated_at = now()
  where id = p_tenant;
  if not found then
    raise exception 'المنشأة غير موجودة';
  end if;
  perform _log(p_tenant, 'status_' || p_status::text, jsonb_build_object('note', p_note));
end $$;

-- لربط مالك بمنشأة قائمة (مثل المنشأة الأصلية قبل نظام الهاتف)
create or replace function admin_invite(
  p_tenant uuid, p_phone text, p_role member_role, p_display_name text default ''
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v jsonb;
begin
  perform _require_admin();
  v := _invite(p_tenant, p_phone, p_role, null, p_display_name);
  perform _log(p_tenant, 'admin_invited',
               jsonb_build_object('phone', normalize_phone(p_phone), 'role', p_role));
  return v;
end $$;

-- ---------------------------------------------------------------------
-- ١٤) ترحيل البيانات القائمة
-- ---------------------------------------------------------------------
-- كل ملف شخصي كان مربوطاً بمنشأة يصبح عضواً فيها
insert into memberships (tenant_id, user_id, role, display_name)
select p.tenant_id, p.id,
       case when p.role = 'admin' then 'owner'::member_role else 'manager'::member_role end,
       p.full_name
from profiles p
where p.tenant_id is not null
on conflict (tenant_id, user_id) do nothing;

update memberships set permissions = default_permissions('manager')
where role = 'manager' and permissions = '{}';

update tenants set plan_id = (select id from plans where code = 'distributor')
where plan_id is null and org_type = 'distributor';

-- الشنطة الرئيسية للمنشآت القائمة
insert into bags (tenant_id, name, account_id)
select a.tenant_id, 'الشنطة الرئيسية', a.id
from accounts a
where a.system_key = 'shanta'
on conflict do nothing;

-- ---------------------------------------------------------------------
-- ١٥) الحماية — إعادة ما عطّله fix_and_seed_supabase.sql
-- ---------------------------------------------------------------------
alter table tenants               enable row level security;
alter table profiles              enable row level security;
alter table karats                enable row level security;
alter table accounts              enable row level security;
alter table items                 enable row level security;
alter table gold_prices           enable row level security;
alter table transactions          enable row level security;
alter table postings              enable row level security;
alter table audit_log             enable row level security;
alter table doc_counters          enable row level security;
alter table account_karat_factors enable row level security;
alter table cheques               enable row level security;
alter table plans                 enable row level security;
alter table memberships           enable row level security;
alter table invitations           enable row level security;
alter table bags                  enable row level security;
alter table platform_admins       enable row level security;
alter table org_events            enable row level security;

-- القراءة داخل المنشأة النشطة، والكتابة بشرط الاشتراك والصلاحية
do $$
declare t text;
begin
  foreach t in array array['karats','accounts','items','gold_prices','account_karat_factors']
  loop
    execute format('drop policy if exists %1$s_all on %1$s', t);
    execute format('drop policy if exists %1$s_read on %1$s', t);
    execute format('drop policy if exists %1$s_write on %1$s', t);
    execute format(
      'create policy %1$s_read on %1$s for select to authenticated
         using (tenant_id = current_tenant_id())', t);
    execute format(
      'create policy %1$s_write on %1$s for all to authenticated
         using (tenant_id = current_tenant_id() and current_tenant_writable()
                and has_perm(''ledger.write''))
         with check (tenant_id = current_tenant_id() and current_tenant_writable()
                and has_perm(''ledger.write''))', t);
  end loop;
end $$;

-- akf كان اسم السياسة القديمة على account_karat_factors
drop policy if exists akf_all on account_karat_factors;

drop policy if exists cheques_all   on cheques;
drop policy if exists cheques_read  on cheques;
drop policy if exists cheques_write on cheques;
create policy cheques_read on cheques for select to authenticated
  using (tenant_id = current_tenant_id());
create policy cheques_write on cheques for all to authenticated
  using (tenant_id = current_tenant_id() and current_tenant_writable()
         and has_perm('cheques.manage'))
  with check (tenant_id = current_tenant_id() and current_tenant_writable()
         and has_perm('cheques.manage'));

drop policy if exists tenants_read on tenants;
create policy tenants_read on tenants for select to authenticated
  using (id = current_tenant_id() or is_platform_admin());

drop policy if exists profiles_read_self on profiles;
create policy profiles_read_self on profiles for select to authenticated
  using (id = auth.uid() or tenant_id = current_tenant_id() or is_platform_admin());

drop policy if exists plans_read on plans;
create policy plans_read on plans for select to authenticated using (true);
drop policy if exists plans_admin on plans;
create policy plans_admin on plans for all to authenticated
  using (is_platform_admin()) with check (is_platform_admin());

-- المالك يرى الفريق كاملاً، والعضو يرى نفسه
drop policy if exists memberships_read on memberships;
create policy memberships_read on memberships for select to authenticated
  using (user_id = auth.uid()
         or (tenant_id = current_tenant_id() and (is_tenant_owner() or has_perm('bags.view_all')))
         or is_platform_admin());

drop policy if exists invitations_read on invitations;
create policy invitations_read on invitations for select to authenticated
  using ((tenant_id = current_tenant_id() and is_tenant_owner()) or is_platform_admin());

-- حامل الشنطة يرى شنطته؛ المالك ومن له bags.view_all يرون الكل
drop policy if exists bags_read on bags;
create policy bags_read on bags for select to authenticated
  using (tenant_id = current_tenant_id()
         and (holder_user_id = auth.uid() or has_perm('bags.view_all')));

drop policy if exists platform_admins_read on platform_admins;
create policy platform_admins_read on platform_admins for select to authenticated
  using (user_id = auth.uid());

drop policy if exists org_events_read on org_events;
create policy org_events_read on org_events for select to authenticated
  using ((tenant_id = current_tenant_id() and is_tenant_owner()) or is_platform_admin());

-- المنح: نبدأ من الصفر ثم نفتح المطلوب فقط
revoke all on all tables    in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all routines  in schema public from anon, authenticated, public;

alter default privileges in schema public revoke all on tables    from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke all on routines  from anon, authenticated, public;

grant usage on schema public to authenticated;

grant select on all tables in schema public to authenticated;
grant insert, update, delete on accounts, karats, items, gold_prices, account_karat_factors
  to authenticated;
grant insert, update on cheques to authenticated;
grant insert, update, delete on plans to authenticated;   -- RLS: للمدير فقط
grant update (full_name, locale) on profiles to authenticated;

-- جدول app_users القديم (كلمات مرور نصية) — لا يصل إليه أحد من التطبيق
do $$ begin
  execute 'revoke all on app_users from anon, authenticated';
exception when undefined_table then null; end $$;

-- الدوال المتاحة للتطبيق
grant execute on function
  current_tenant_id(), is_platform_admin(), has_perm(text), is_tenant_owner(),
  current_tenant_writable(), normalize_phone(text),
  load_my_context(), register_organization(text, org_type, text, text),
  switch_tenant(uuid), set_my_locale(text),
  invite_member(text, member_role, text[], text),
  update_member(uuid, member_role, text[], text, boolean),
  cancel_invitation(uuid), list_team(), list_bags(),
  create_bag(text, uuid), update_bag(uuid, text, uuid, boolean),
  post_entry(uuid, tx_type, timestamptz, jsonb, uuid, bigint, text),
  reverse_entry(uuid, text),
  clear_cheque(uuid, uuid, timestamptz, text),
  create_showroom(text, text, text),
  bootstrap_tenant(text),
  admin_overview(), admin_list_orgs(org_status, org_type, text),
  admin_org_detail(uuid), admin_activate(uuid, uuid, int),
  admin_set_status(uuid, org_status, text),
  admin_invite(uuid, text, member_role, text)
to authenticated;

-- =====================================================================
--  بعد التنفيذ:
--
--  ١) قبل أول دخول — اربط المنشأة الأصلية برقم مالكها، فيدخلها مباشرة
--     بلا شاشة تسجيل (الرقم بصيغة 9627XXXXXXXX):
--
--    insert into invitations (tenant_id, phone, role, display_name)
--    select id, '9627XXXXXXXX', 'owner', 'بشار'
--    from tenants order by created_at limit 1;
--
--  ٢) بعد أول دخول من التطبيق — اجعل نفسك مدير المنصّة:
--
--    insert into platform_admins (user_id)
--    select id from auth.users where phone = '9627XXXXXXXX';
--
--  (admin_invite تعمل من لوحة الإدارة فقط، لا من SQL Editor)
-- =====================================================================
