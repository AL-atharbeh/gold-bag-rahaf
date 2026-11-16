-- =====================================================================
--  نسخة تاجر الشنطة: مستخدم واحد، وتاريخ بداية راتب للموظف
--
--  ١) حد الحسابات لكل منشأة على حدة (القاعدة مشتركة مع المنصة):
--     منشأة الترخيص الدائم (0015) = حساب واحد، والبقية كما هي (3).
--  ٢) تاريخ بداية الراتب: منه تبدأ دورة الراتب الشهرية (من يومه إلى
--     مثله في الشهر التالي)، ومنه يُرحَّل الباقي من شهر لشهر.
--     فارغ = الشهر الميلادي من أوله لآخره، بلا ترحيل.
--
--  ⚠️ نفّذ 0015 قبل هذا الملف.
-- =====================================================================

-- ١) حد الحسابات لكل منشأة
alter table tenants add column if not exists max_members int
  check (max_members is null or max_members > 0);

create or replace function guard_member_limit()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_max int;
begin
  select coalesce(t.max_members, edition_max_members()) into v_max
  from tenants t where t.id = new.tenant_id;
  if new.is_active and (
    select count(*) from memberships
    where tenant_id = new.tenant_id and is_active and id <> new.id
  ) >= v_max then
    raise exception 'وصلت النسخة للحد الأقصى: % حسابات', v_max
      using errcode = '42501';
  end if;
  return new;
end $$;

update tenants set max_members = 1 where lifetime_license;

-- ٢) تاريخ بداية الراتب
alter table accounts add column if not exists salary_start_date date;

comment on column accounts.salary_start_date is
  'بداية راتب الموظف: يوم بداية الدورة الشهرية، ومنه يُرحَّل الباقي';

-- للتأكد: الحسابات الفعّالة في المنشأة — يجب أن يبقى واحد فقط.
-- إن ظهر أكثر من واحد، أوقف الزائد:  select edition_disable_user('07xxxxxxxx');
select u.phone, m.display_name, m.role, m.is_active
from memberships m
join auth.users u on u.id = m.user_id
join tenants t    on t.id = m.tenant_id
where t.lifetime_license and m.is_active
order by m.created_at;
