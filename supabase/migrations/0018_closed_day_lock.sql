-- =====================================================================
--  اليوم المغلق مقفل: لا حركة بتاريخه بعد إغلاقه
--
--  إغلاق اليوم جرد: كاش معدود وبضاعة مؤكدة. حركة تُسجَّل بعده بنفس
--  التاريخ تجعل الجرد المحفوظ لا يطابق الواقع. فالحركة على يوم مغلق
--  تُرفض، ولتسجيل حركة نُسيت يُعاد فتح اليوم من الشنطة ثم يُغلق ثانية.
--
--  اليوم بتوقيت عمّان، كما يفتحه التطبيق.
-- =====================================================================

create or replace function guard_closed_bag_day()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (
    select 1 from bag_days
    where tenant_id = new.tenant_id
      and day = (new.occurred_at at time zone 'Asia/Amman')::date
      and closed_at is not null
  ) then
    raise exception 'هذا اليوم مغلق — أعد فتحه من الشنطة لتسجيل حركة بتاريخه'
      using errcode = '42501';
  end if;
  return new;
end $$;

drop trigger if exists transactions_closed_day on transactions;
create trigger transactions_closed_day
  before insert on transactions
  for each row execute function guard_closed_bag_day();

revoke all on function guard_closed_bag_day() from public, anon, authenticated;

-- إعادة فتح يوم مغلق (اليوم الحالي أو آخر يوم): يبقى جرده السابق في
-- السجل (closing_* تُمسح ويُحفظ وقت الإغلاق السابق في الملاحظة)، ويُغلق
-- من جديد بعد تسجيل الحركة الناقصة.
create or replace function reopen_bag_day(p_day date)
returns void language plpgsql security definer set search_path = public as $$
declare v_row bag_days%rowtype;
begin
  perform assert_can_write('ledger.write');
  select * into v_row from bag_days
  where tenant_id = current_tenant_id() and day = p_day for update;
  if not found then raise exception 'هذا اليوم غير مفتوح'; end if;
  if v_row.closed_at is null then raise exception 'هذا اليوم مفتوح أصلاً'; end if;
  if exists (select 1 from bag_days
             where tenant_id = v_row.tenant_id and day > p_day) then
    raise exception 'لا يُعاد فتح يوم بعده أيام أخرى';
  end if;
  update bag_days
     set closed_at = null,
         closed_by = null,
         goods_confirmed = false,
         closing_note = concat_ws(' — ', nullif(closing_note, ''),
                                  'أُعيد فتحه بعد إغلاق ' || to_char(closed_at at time zone 'Asia/Amman', 'HH24:MI'))
   where id = v_row.id;
end $$;

grant execute on function reopen_bag_day(date) to authenticated;
