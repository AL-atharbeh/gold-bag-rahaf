-- =====================================================================
--  ارتجاع الشيك أو إلغاؤه
--
--  الشيك المربوط بحركة (settled_tx_id) حُسب نقداً لحظة تسجيله. فإذا ارتجع
--  من البنك أو أُلغي، يجب أن يعود المبلغ على حساب الطرف — وإلا بقي رصيده
--  مسدداً بشيك لم يُصرف. لذلك تُعكس حركته في نفس المعاملة مع تغيير حالته.
--  الشيك غير المربوط (لم يُقيَّد بعد) تتغير حالته فقط.
-- =====================================================================

create or replace function void_cheque(
  p_cheque_id uuid,
  p_status    cheque_status,
  p_note      text default null
) returns text language plpgsql security definer set search_path = public as $$
declare
  v_cheque cheques%rowtype;
  v_rev    uuid;
  v_reason text;
begin
  perform assert_can_write('cheques.manage');

  if p_status not in ('bounced', 'cancelled') then
    raise exception 'حالة غير صالحة: %', p_status;
  end if;

  select * into v_cheque from cheques
  where id = p_cheque_id and tenant_id = current_tenant_id() for update;
  if not found then
    raise exception 'الشيك غير موجود';
  end if;
  if v_cheque.status <> 'pending' then
    raise exception 'الشيك ليس معلّقاً — حالته %', v_cheque.status;
  end if;

  if v_cheque.settled_tx_id is not null then
    v_reason := coalesce(
      p_note,
      case when p_status = 'bounced' then 'شيك مرتجع ' else 'إلغاء شيك ' end
        || coalesce(v_cheque.cheque_number, '')
    );
    v_rev := reverse_transaction(v_cheque.settled_tx_id, v_reason);
  end if;

  update cheques
  set status = p_status,
      settled_at = now(),
      note = coalesce(p_note, note)
  where id = p_cheque_id;

  return (select doc_number from transactions where id = v_rev);
end $$;

grant execute on function void_cheque(uuid, cheque_status, text) to authenticated;

-- =====================================================================
--  إلغاء حركة محفوظة (خطأ إدخال)
--
--  لا تُحذف الحركة أبداً: يُنشأ قيد عكسي يساويها ويعاكسها، فتعود الأرصدة
--  والمخزون كما كانت، وتبقى الحركتان ظاهرتين في الدفتر للتدقيق.
--  - السبب إلزامي.
--  - لا يُلغى قيد عكسي، ولا حركة ملغاة مسبقاً.
--  - الشيكات المعلّقة المربوطة بالحركة تُلغى معها.
--  - يُرفض الإلغاء إن جعل مخزون الشنطة سالباً (مثلاً: إلغاء وارد بضاعة
--    بيع جزء منها) — هنا يلزم مرتجع لا إلغاء.
-- =====================================================================

create or replace function cancel_transaction(p_tx_id uuid, p_reason text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_tx  transactions%rowtype;
  v_rev uuid;
  v_doc text;
  v_bad record;
begin
  perform assert_can_write('ledger.write');

  if coalesce(trim(p_reason), '') = '' then
    raise exception 'اكتب سبب الإلغاء';
  end if;

  select * into v_tx from transactions
  where id = p_tx_id and tenant_id = current_tenant_id() for update;
  if not found then
    raise exception 'الحركة غير موجودة';
  end if;
  if v_tx.type = 'reversal' then
    raise exception 'لا يمكن إلغاء قيد عكسي';
  end if;
  if v_tx.reversed_by_tx_id is not null then
    raise exception 'هذه الحركة ملغاة مسبقاً';
  end if;

  v_rev := reverse_transaction(p_tx_id, 'إلغاء ' || v_tx.doc_number || ' — ' || trim(p_reason));

  -- المخزون بعد الإلغاء لا يجوز أن يصبح سالباً
  select s.item_name, s.karat_name, s.quantity, s.net_mg into v_bad
  from account_item_stock s
  join accounts a on a.id = s.account_id and a.kind = 'inventory_location'
  where s.tenant_id = v_tx.tenant_id
    -- الكسر بلا صنف (item_id فارغ) — لذلك المقارنة بـ is not distinct from
    and exists (
      select 1 from postings p
      where p.tx_id = p_tx_id and p.ledger = 'gold'
        and p.account_id = s.account_id
        and p.item_id  is not distinct from s.item_id
        and p.karat_id is not distinct from s.karat_id)
    and (s.quantity < 0 or s.net_mg < 0)
  limit 1;
  if found then
    raise exception 'لا يمكن الإلغاء: % % لم يعد كله في الشنطة (بيع جزء منه). استخدم المرتجع بدل الإلغاء.',
      coalesce(v_bad.item_name, 'كسر'), coalesce(v_bad.karat_name, '');
  end if;

  update cheques set status = 'cancelled', settled_at = now(),
         note = coalesce(note || ' — ', '') || 'أُلغيت حركته'
  where settled_tx_id = p_tx_id and status = 'pending';

  select doc_number into v_doc from transactions where id = v_rev;
  return jsonb_build_object('tx_id', v_rev, 'doc_number', v_doc);
end $$;

grant execute on function cancel_transaction(uuid, text) to authenticated;
