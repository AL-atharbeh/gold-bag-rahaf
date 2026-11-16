-- =====================================================================
--  نسخة تاجر الشنطة: ترخيص دائم — بلا اشتراك شهري ولا تاريخ انتهاء
--
--  القاعدة مشتركة مع المنصة، فلا يُلغى الاشتراك لكل المنشآت: منشأة
--  تاجر الشنطة وحدها تُعلَّم "ترخيص دائم"، فتبقى قابلة للكتابة دائماً
--  حتى لو وُضع لها تاريخ انتهاء لاحقاً، وبلا حدود باقة للمستخدمين والشنط.
--
--  حدّد المنشأة برقم مالكها في السطر أدناه.
--  (حد الحسابات الثلاثة في 0013 لا يتغير هنا.)
-- =====================================================================

alter table tenants add column if not exists lifetime_license boolean not null default false;

-- الكتابة مسموحة: ترخيص دائم، أو اشتراك ساري
create or replace function current_tenant_writable()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((
    select t.lifetime_license
        or t.subscription_ends_at is null
        or t.subscription_ends_at > now()
    from tenants t where t.id = current_tenant_id()
  ), false)
$$;

do $$
declare
  v_owner_phone text := '0797040903';   -- ← رقم مالك منشأة تاجر الشنطة
  v_tenant      uuid;
  v_name        text;
begin
  select m.tenant_id, t.name into v_tenant, v_name
  from memberships m
  join auth.users u on u.id = m.user_id
  join tenants t    on t.id = m.tenant_id
  where u.phone = edition_phone(v_owner_phone) and m.role = 'owner'
  limit 1;

  if v_tenant is null then
    raise exception 'لا توجد منشأة يملكها الرقم %', v_owner_phone;
  end if;

  update tenants
     set lifetime_license     = true,
         subscription_ends_at = null,   -- لا تاريخ انتهاء
         plan_id              = null,   -- لا حدود باقة
         updated_at           = now()
   where id = v_tenant;

  raise notice 'ترخيص دائم للمنشأة: %', v_name;
end $$;

-- للتأكد
select t.name, t.status, t.lifetime_license, t.subscription_ends_at, t.plan_id
from tenants t
where t.lifetime_license;
