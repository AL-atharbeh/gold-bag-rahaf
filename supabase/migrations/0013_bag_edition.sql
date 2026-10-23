-- =====================================================================
--  نسخة تاجر الشنطة — دخول برقم الهاتف وكلمة مرور، بحد أقصى 3 حسابات
--
--  لا يوجد تسجيل من التطبيق. الحسابات ننشئها نحن من SQL Editor بالدوال
--  أدناه (مقفلة على التطبيق: لا يستطيع أي مستخدم استدعاءها).
--
--  ⚠️ بعد تنفيذ هذا الملف، من لوحة Supabase:
--     Authentication → Sign In / Providers → عطّل "Allow new users to sign up"
--     فلا يستطيع أحد إنشاء حساب حتى لو حاول من خارج التطبيق.
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------
-- ١) الحد الأقصى: 3 أعضاء فعّالين في المنشأة
-- ---------------------------------------------------------------------
create or replace function edition_max_members() returns int
language sql immutable as $$ select 3 $$;

create or replace function guard_member_limit()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.is_active and (
    select count(*) from memberships
    where tenant_id = new.tenant_id and is_active and id <> new.id
  ) >= edition_max_members() then
    raise exception 'وصلت النسخة للحد الأقصى: % حسابات', edition_max_members()
      using errcode = '42501';
  end if;
  return new;
end $$;

drop trigger if exists memberships_limit on memberships;
create trigger memberships_limit
  before insert or update of is_active on memberships
  for each row execute function guard_member_limit();

-- رقم أردني بأي صيغة → 9627XXXXXXXX (صيغة auth.users.phone)
create or replace function edition_phone(p text) returns text
language plpgsql immutable as $$
declare d text := regexp_replace(coalesce(p, ''), '\D', '', 'g');
begin
  if d like '00962%' then d := substr(d, 3); end if;
  if d like '07%' and length(d) = 10 then d := '962' || substr(d, 2); end if;
  if d like '7%' and length(d) = 9 then d := '962' || d; end if;
  if d !~ '^9627[789]\d{7}$' then
    raise exception 'رقم غير صالح: %', p;
  end if;
  return d;
end $$;

-- ---------------------------------------------------------------------
-- ٢) إضافة حساب: رقم + كلمة مرور + اسم + دور
--    المنشأة: الوحيدة الفعّالة إن لم تُحدَّد.
-- ---------------------------------------------------------------------
create or replace function edition_add_user(
  p_phone    text,
  p_password text,
  p_name     text,
  p_role     member_role default 'bag_holder',
  p_tenant   uuid default null
) returns uuid language plpgsql security definer
  set search_path = public, auth, extensions as $$
declare
  v_phone  text := edition_phone(p_phone);
  v_tenant uuid := p_tenant;
  v_uid    uuid;
begin
  if length(coalesce(p_password, '')) < 8 then
    raise exception 'كلمة المرور 8 أحرف على الأقل';
  end if;

  if v_tenant is null then
    select id into v_tenant from tenants where status = 'active';
    if (select count(*) from tenants where status = 'active') <> 1 then
      raise exception 'حدّد المنشأة (p_tenant): يوجد أكثر من منشأة أو لا يوجد';
    end if;
  end if;

  select id into v_uid from auth.users where phone = v_phone;

  if v_uid is null then
    v_uid := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, phone, phone_confirmed_at,
      encrypted_password, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
      v_phone, now(),
      crypt(p_password, gen_salt('bf')),
      '{"provider":"phone","providers":["phone"]}'::jsonb,
      jsonb_build_object('full_name', p_name),
      now(), now(), '', '', '', ''
    );
    insert into auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_uid, v_uid::text, 'phone',
      jsonb_build_object('sub', v_uid::text, 'phone', v_phone,
                         'phone_verified', true),
      now(), now(), now()
    );
  else
    -- رقم موجود: تُضبط كلمة مروره ويُرفع عنه أي إيقاف
    update auth.users
    set encrypted_password = crypt(p_password, gen_salt('bf')),
        phone_confirmed_at = coalesce(phone_confirmed_at, now()),
        banned_until = null, updated_at = now()
    where id = v_uid;
  end if;

  insert into profiles (id, phone, full_name, tenant_id)
  values (v_uid, v_phone, p_name, v_tenant)
  on conflict (id) do update
    set full_name = excluded.full_name, tenant_id = excluded.tenant_id;

  insert into memberships (tenant_id, user_id, role, permissions, display_name)
  values (v_tenant, v_uid, p_role, default_permissions(p_role), p_name)
  on conflict (tenant_id, user_id) do update
    set role = excluded.role, permissions = excluded.permissions,
        display_name = excluded.display_name, is_active = true;

  return v_uid;
end $$;

-- ---------------------------------------------------------------------
-- ٣) تغيير كلمة المرور
-- ---------------------------------------------------------------------
create or replace function edition_set_password(p_phone text, p_password text)
returns void language plpgsql security definer
  set search_path = public, auth, extensions as $$
begin
  if length(coalesce(p_password, '')) < 8 then
    raise exception 'كلمة المرور 8 أحرف على الأقل';
  end if;
  update auth.users
  set encrypted_password = crypt(p_password, gen_salt('bf')), updated_at = now()
  where phone = edition_phone(p_phone);
  if not found then raise exception 'الرقم غير موجود'; end if;
end $$;

-- ---------------------------------------------------------------------
-- ٤) إيقاف حساب: لا يدخل بعدها، ويفرغ مكانه من الحسابات الثلاثة.
--    بياناته وحركاته تبقى كما هي.
-- ---------------------------------------------------------------------
create or replace function edition_disable_user(p_phone text)
returns void language plpgsql security definer
  set search_path = public, auth as $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users where phone = edition_phone(p_phone);
  if v_uid is null then raise exception 'الرقم غير موجود'; end if;
  update memberships set is_active = false, updated_at = now() where user_id = v_uid;
  update auth.users set banned_until = 'infinity', updated_at = now() where id = v_uid;
  delete from auth.sessions where user_id = v_uid;
end $$;

-- ---------------------------------------------------------------------
-- ٥) عرض الحسابات الحالية
-- ---------------------------------------------------------------------
create or replace function edition_users()
returns table (phone text, name text, role member_role, is_active boolean,
               last_sign_in timestamptz)
language sql security definer set search_path = public, auth as $$
  select u.phone, m.display_name, m.role, m.is_active and u.banned_until is null,
         u.last_sign_in_at
  from memberships m join auth.users u on u.id = m.user_id
  order by m.created_at
$$;

-- لا يستدعيها التطبيق أبداً — SQL Editor فقط
revoke all on function edition_add_user(text, text, text, member_role, uuid) from public, anon, authenticated;
revoke all on function edition_set_password(text, text)  from public, anon, authenticated;
revoke all on function edition_disable_user(text)        from public, anon, authenticated;
revoke all on function edition_users()                    from public, anon, authenticated;

-- ---------------------------------------------------------------------
--  أمثلة الاستعمال (من SQL Editor):
--
--  select edition_add_user('0790000001', 'Kalimat#Sirr1', 'أبو محمد', 'owner');
--  select edition_add_user('0790000002', 'Kalimat#Sirr2', 'المساعد',  'assistant');
--  select edition_set_password('0790000002', 'Jadida#2026');
--  select edition_disable_user('0790000002');
--  select * from edition_users();
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- ٦) بيانات المنشأة التي تظهر في ترويسة الكشوفات والفواتير
--    المالك وحده يعدّلها من شاشة الإعدادات.
-- ---------------------------------------------------------------------
create or replace function update_org_profile(
  p_name  text,
  p_phone text default null,
  p_city  text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_tenant_owner() then
    raise exception 'المالك وحده يعدّل بيانات المنشأة' using errcode = '42501';
  end if;
  if coalesce(trim(p_name), '') = '' then
    raise exception 'اسم المنشأة مطلوب';
  end if;
  update tenants
  set name = trim(p_name),
      phone = nullif(trim(coalesce(p_phone, '')), ''),
      city = nullif(trim(coalesce(p_city, '')), ''),
      updated_at = now()
  where id = current_tenant_id();
end $$;

grant execute on function update_org_profile(text, text, text) to authenticated;
