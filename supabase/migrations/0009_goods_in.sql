-- =====================================================================
--  وارد البضاعة من المشغل — الأصناف، عيار 14، ومخزون الشنطة بالعدد والوزن
--
--  • عيار 14: البضاعة بـ 14/24 (0.583333)، والكسر بـ 0.550.
--  • الأصناف: خاتم، حلق، سلسال، تعليقة، ذبلة — ويضيف الموزّع صنفه الخاص.
--  • نوع حركة جديد goods_in (وارد بضاعة) بدل "شراء": البضاعة تدخل
--    الشنطة ديناً ذهبياً للمشغل، ومصنوعيتها ديناً نقدياً له.
--  • المصنوعية تُقيَّد على الشنطة نفسها في دفتر النقد: رصيد الشنطة
--    النقدي = رأس المال المدفوع مصنوعيةً في البضاعة الموجودة فيها.
--  • الكمية في القيود صارت بإشارة (مدين +، دائن −) فيُجمع مخزون كل صنف.
-- =====================================================================

alter type tx_type add value if not exists 'goods_in';

-- ---------------------------------------------------------------------
-- ١) عيار 14
-- ---------------------------------------------------------------------
insert into karats (tenant_id, name, factor_ppm, out_factor_ppm, in_factor_ppm, sort_order)
select t.id, 'عيار 14', 583333, 583333, 550000, 3
from tenants t
on conflict (tenant_id, name) do nothing;

-- عيار 9 ينزل بعد 14 في الترتيب
update karats set sort_order = 4 where name = 'عيار 9';

-- ---------------------------------------------------------------------
-- ٢) الأصناف
-- ---------------------------------------------------------------------
alter table items add column if not exists sort_order int not null default 100;
alter table items add column if not exists is_custom boolean not null default true;

do $$ begin
  alter table items add constraint items_tenant_name_uniq unique (tenant_id, name);
exception when duplicate_object or duplicate_table then null; end $$;

create or replace function seed_items(p_tenant uuid)
returns void language sql security definer set search_path = public as $$
  insert into items (tenant_id, name, sort_order, is_custom) values
    (p_tenant, 'خاتم',   1, false),
    (p_tenant, 'حلق',    2, false),
    (p_tenant, 'سلسال',  3, false),
    (p_tenant, 'تعليقة', 4, false),
    (p_tenant, 'ذبلة',   5, false)
  on conflict (tenant_id, name) do nothing
$$;

select seed_items(id) from tenants;

-- ---------------------------------------------------------------------
-- ٣) تهيئة المنشآت الجديدة — نفس 0008 مع عيار 14 والأصناف
-- ---------------------------------------------------------------------
create or replace function seed_tenant(p_tenant uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_shanta uuid; v_type org_type;
begin
  insert into karats (tenant_id, name, factor_ppm, out_factor_ppm, in_factor_ppm, sort_order) values
    (p_tenant, 'عيار 24', 1000000, 1000000, 1000000, 0),
    (p_tenant, 'عيار 21',  885000,  885000,  870000, 1),
    (p_tenant, 'عيار 18',  790000,  790000,  740000, 2),
    (p_tenant, 'عيار 14',  583333,  583333,  550000, 3),
    (p_tenant, 'عيار 9',   375000,  375000,  375000, 4)
  on conflict (tenant_id, name) do nothing;

  insert into accounts (tenant_id, name, kind, system_key, is_system) values
    (p_tenant, 'الشنطة',         'inventory_location', 'shanta',         true),
    (p_tenant, 'الخزنة',         'inventory_location', 'vault',          true),
    (p_tenant, 'الصندوق',        'cashbox',            'cashbox',        true),
    (p_tenant, 'إيراد المصنعية', 'income',             'making_income',  true),
    (p_tenant, 'أرباح وفروقات',  'income',             'trading_income', true),
    (p_tenant, 'رأس المال',      'owner',              'capital',        true)
  on conflict (tenant_id, system_key) do nothing;

  perform seed_items(p_tenant);

  select org_type into v_type from tenants where id = p_tenant;
  if v_type in ('distributor', 'factory') then
    select id into v_shanta from accounts where tenant_id = p_tenant and system_key = 'shanta';
    insert into bags (tenant_id, name, account_id)
    values (p_tenant, 'الشنطة الرئيسية', v_shanta)
    on conflict do nothing;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- ٤) مخزون كل حساب: لكل صنف وعيار — العدد والقائم والصافي
-- ---------------------------------------------------------------------
create or replace view account_item_stock
with (security_invoker = true) as
select
  p.tenant_id,
  p.account_id,
  p.item_id,
  i.name                                       as item_name,
  p.karat_id,
  k.name                                       as karat_name,
  coalesce(k.sort_order, 99)                   as karat_sort,
  coalesce(i.sort_order, 999)                  as item_sort,
  coalesce(sum(p.quantity), 0)::int            as quantity,
  coalesce(sum(p.gross_weight_mg), 0)::bigint  as gross_mg,
  coalesce(sum(p.amount), 0)::bigint           as net_mg
from postings p
join transactions t on t.id = p.tx_id
left join items  i  on i.id = p.item_id
left join karats k  on k.id = p.karat_id
where p.ledger = 'gold'
group by p.tenant_id, p.account_id, p.item_id, i.name, p.karat_id, k.name,
         k.sort_order, i.sort_order;

grant select on account_item_stock to authenticated;
