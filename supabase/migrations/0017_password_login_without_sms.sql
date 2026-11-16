-- =====================================================================
--  الدخول بالرقم وكلمة المرور دون مزوّد رسائل (Twilio)
--
--  Supabase يرفض أي دخول بالهاتف ما لم يُفعَّل مزوّد SMS، مع أن نسخة
--  الشنطة لا ترسل رسائل أبداً. فلكل حساب بريد داخلي ثابت يُشتق من رقمه:
--      962791234567  →  962791234567@phone.goldbashar.app
--  المستخدم يكتب رقمه وكلمة مروره كما هو، والتطبيق يدخل بهذا البريد.
--  لا يُرسل إليه شيء: التسجيل الذاتي مغلق، والحسابات تُنشأ من هنا مؤكَّدة.
-- =====================================================================

create or replace function edition_login_email(p_phone text) returns text
language sql immutable as $$
  select edition_phone(p_phone) || '@phone.goldbashar.app'
$$;

-- ١) إضافة حساب: كما في 0013، ومعه البريد الداخلي وهويته
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
  v_email  text := edition_login_email(p_phone);
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
      email, email_confirmed_at,
      encrypted_password, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
      v_phone, now(), v_email, now(),
      crypt(p_password, gen_salt('bf')),
      '{"provider":"email","providers":["email","phone"]}'::jsonb,
      jsonb_build_object('full_name', p_name),
      now(), now(), '', '', '', ''
    );
  else
    -- رقم موجود: تُضبط كلمة مروره وبريده ويُرفع عنه أي إيقاف
    update auth.users
    set encrypted_password = crypt(p_password, gen_salt('bf')),
        phone_confirmed_at = coalesce(phone_confirmed_at, now()),
        email = coalesce(email, v_email),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        banned_until = null, updated_at = now()
    where id = v_uid;
  end if;

  perform _edition_identities(v_uid);

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

-- هويتا الحساب (هاتف وبريد) — تُضاف الناقصة فقط
create or replace function _edition_identities(p_uid uuid) returns void
language plpgsql security definer set search_path = public, auth as $$
declare v_phone text; v_email text;
begin
  select phone, email into v_phone, v_email from auth.users where id = p_uid;
  if v_phone is not null and not exists (
    select 1 from auth.identities where user_id = p_uid and provider = 'phone') then
    insert into auth.identities (id, user_id, provider_id, provider, identity_data,
                                 last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), p_uid, p_uid::text, 'phone',
            jsonb_build_object('sub', p_uid::text, 'phone', v_phone, 'phone_verified', true),
            now(), now(), now());
  end if;
  if v_email is not null and not exists (
    select 1 from auth.identities where user_id = p_uid and provider = 'email') then
    insert into auth.identities (id, user_id, provider_id, provider, identity_data,
                                 last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), p_uid, p_uid::text, 'email',
            jsonb_build_object('sub', p_uid::text, 'email', v_email,
                               'email_verified', true, 'phone_verified', false),
            now(), now(), now());
  end if;
end $$;

-- ٢) الحسابات الموجودة: بريد داخلي لكل رقم بلا بريد
update auth.users
   set email = phone || '@phone.goldbashar.app',
       email_confirmed_at = coalesce(email_confirmed_at, now()),
       updated_at = now()
 where phone is not null and phone <> '' and email is null;

do $$
declare r record;
begin
  for r in select id from auth.users where email like '%@phone.goldbashar.app' loop
    perform _edition_identities(r.id);
  end loop;
end $$;

-- لا يستدعيها التطبيق أبداً — SQL Editor فقط
revoke all on function edition_add_user(text, text, text, member_role, uuid) from public, anon, authenticated;
revoke all on function _edition_identities(uuid) from public, anon, authenticated;

-- للتأكد: كل حساب له بريد داخلي
select phone, email, email_confirmed_at is not null as confirmed
from auth.users order by created_at;
