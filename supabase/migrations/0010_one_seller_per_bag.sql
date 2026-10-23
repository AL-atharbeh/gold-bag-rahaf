-- =====================================================================
--  الشنطة لبائع واحد: حاملها وحده يبيع منها ويُدخل إليها
--
--  • كل شنطة لها حامل واحد (holder_user_id). الشنطة الرئيسية يحملها
--    المالك تلقائياً عند التسجيل، والمالك يعيد تعيينها من "الشنط".
--  • أي قيد على حساب شنطة من غير حاملها يُرفض في قاعدة البيانات نفسها،
--    مهما كان مصدره.
--  • استثناء واحد: المالك يستطيع إلغاء (قيد عكسي) حركة خاطئة على أي
--    شنطة في منشأته.
-- =====================================================================

-- ١) الشنط القائمة بلا حامل → يحملها المالك
update bags b
   set holder_user_id = m.user_id, updated_at = now()
  from memberships m
 where m.tenant_id = b.tenant_id
   and m.role = 'owner'
   and m.is_active
   and b.holder_user_id is null;

-- ٢) المالك الجديد يحمل الشنطة الرئيسية تلقائياً
create or replace function owner_holds_main_bag()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role = 'owner' and new.is_active then
    update bags set holder_user_id = new.user_id, updated_at = now()
    where tenant_id = new.tenant_id and holder_user_id is null;
  end if;
  return new;
end $$;

drop trigger if exists memberships_owner_holds_bag on memberships;
create trigger memberships_owner_holds_bag
  after insert on memberships
  for each row execute function owner_holds_main_bag();

-- ٣) الحارس: لا قيد على شنطة إلا من حاملها
create or replace function guard_bag_holder()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_holder uuid;
  v_type   tx_type;
begin
  -- من SQL Editor أو مهام النظام (بلا مستخدم) لا فحص
  if auth.uid() is null then
    return new;
  end if;

  select holder_user_id into v_holder
  from bags where account_id = new.account_id and is_active;

  if v_holder is null or v_holder = auth.uid() then
    return new;
  end if;

  -- المالك يصحّح بالقيد العكسي فقط
  select type into v_type from transactions where id = new.tx_id;
  if v_type = 'reversal' and is_tenant_owner() then
    return new;
  end if;

  raise exception 'هذه الشنطة يبيع منها حاملها فقط' using errcode = '42501';
end $$;

drop trigger if exists postings_bag_holder on postings;
create trigger postings_bag_holder
  before insert on postings
  for each row execute function guard_bag_holder();

revoke all on function owner_holds_main_bag() from public, anon, authenticated;
revoke all on function guard_bag_holder()      from public, anon, authenticated;
