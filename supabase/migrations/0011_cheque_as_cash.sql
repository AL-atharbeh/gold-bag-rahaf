-- =====================================================================
--  الشيك يُعدّ نقداً لحظة تسجيله
--
--  الشيك المسلَّم للتاجر أو المستلم منه يُقيَّد كدفعة نقدية فوراً، ويُحفظ
--  في دفتر الشيكات مربوطاً بحركته (settled_tx_id) لمتابعة استحقاقه.
--  تحصيل شيك كهذا يغيّر حالته فقط — لا يقيّد المبلغ مرة ثانية.
--  الشيك القديم غير المربوط يبقى كما كان: تحصيله يُنشئ الدفعة.
-- =====================================================================

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

  -- محسوب نقداً مسبقاً: تُغلق متابعته فقط
  if v_cheque.settled_tx_id is not null then
    update cheques set status = 'cleared', settled_at = now() where id = p_cheque_id;
    return (select doc_number from transactions where id = v_cheque.settled_tx_id);
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

grant execute on function clear_cheque(uuid, uuid, timestamptz, text) to authenticated;
