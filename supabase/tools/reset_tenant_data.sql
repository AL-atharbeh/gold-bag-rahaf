-- =====================================================================
--  تفريغ بيانات منشأة واحدة لإعادة الإدخال — للتجربة فقط
--
--  ⚠️ نهائي ولا يمكن التراجع عنه.
--
--  يُحذف: كل الحركات والقيود، كل الأطراف (محلات، مشاغل، تجار، زبائن،
--         موظفون)، الأصناف الخاصة، الشيكات، المعاملات الخاصة، عدّاد
--         أرقام الفواتير، وسجل التدقيق للحركات.
--  يبقى:  المنشأة وتفعيلها واشتراكها، العضويات، حسابات النظام
--         (الشنطة، الصندوق…)، الشنط وحاملوها، العيارات، الأصناف الأساسية.
--
--  حدّد المنشأة برقم مالكها في السطر أدناه (بدون صفر وبدون +).
-- =====================================================================

do $$
declare
  v_owner_phone text := '962770466648';   -- ← رقم مالك المنشأة
  v_tenant      uuid;
  v_name        text;
begin
  select m.tenant_id, t.name into v_tenant, v_name
  from memberships m
  join auth.users u on u.id = m.user_id
  join tenants t    on t.id = m.tenant_id
  where u.phone = v_owner_phone and m.role = 'owner'
  limit 1;

  if v_tenant is null then
    raise exception 'لا توجد منشأة يملكها الرقم %', v_owner_phone;
  end if;

  -- الحركات محمية من الحذف — تُرفع الحماية مؤقتاً داخل هذه العملية فقط
  alter table postings     disable trigger postings_immutable;
  alter table transactions disable trigger transactions_immutable;
  alter table audit_log    disable trigger audit_log_immutable;

  delete from cheques               where tenant_id = v_tenant;
  -- يومية الشنطة (تشير إلى حركات التسوية) — إن وُجد الجدول
  if to_regclass('public.bag_days') is not null then
    execute 'delete from bag_days where tenant_id = $1' using v_tenant;
  end if;
  delete from postings              where tenant_id = v_tenant;
  delete from transactions          where tenant_id = v_tenant;
  delete from audit_log             where tenant_id = v_tenant and entity in ('transaction', 'account');
  delete from doc_counters          where tenant_id = v_tenant;
  delete from account_karat_factors where tenant_id = v_tenant;

  -- المحلات أولاً (تشير إلى حسابات عهدتها)، ثم بقية الأطراف وحسابات العهدة
  delete from accounts
   where tenant_id = v_tenant and kind = 'showroom';
  delete from accounts
   where tenant_id = v_tenant
     and system_key is null
     and id not in (select account_id from bags where tenant_id = v_tenant);

  delete from items where tenant_id = v_tenant and is_custom;

  alter table postings     enable trigger postings_immutable;
  alter table transactions enable trigger transactions_immutable;
  alter table audit_log    enable trigger audit_log_immutable;

  raise notice 'تم تفريغ بيانات المنشأة: %', v_name;
end $$;

-- للتأكد: يجب أن تكون كل الأعداد صفراً
select
  (select count(*) from transactions t join memberships m on m.tenant_id = t.tenant_id
     join auth.users u on u.id = m.user_id where u.phone = '962770466648' and m.role = 'owner') as transactions_left,
  (select count(*) from accounts a join memberships m on m.tenant_id = a.tenant_id
     join auth.users u on u.id = m.user_id
     where u.phone = '962770466648' and m.role = 'owner' and a.system_key is null
       and a.id not in (select account_id from bags)) as parties_left;
