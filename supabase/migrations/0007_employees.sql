-- =====================================================================
--  الموظفون — نمط ورقة "عبد" في دفتر الإكسل
--
--  الموظف حساب نقدي كأي طرف آخر: راتبه الشهري رقم ثابت على الحساب،
--  وسحوباته حركات نقد عادية تخرج من الصندوق. الرصيد الناتج هو
--  ما سُحب فعلياً خلال الشهر، ويُقارَن بالراتب في الشاشة لا في القاعدة —
--  لأن الشهر قد يُغلق متأخراً والراتب قد يتغيّر.
-- =====================================================================

alter type account_kind add value if not exists 'employee';

alter table accounts
  add column if not exists monthly_salary_fils integer not null default 0;

alter table accounts
  drop constraint if exists accounts_monthly_salary_nonneg;

alter table accounts
  add constraint accounts_monthly_salary_nonneg
  check (monthly_salary_fils >= 0);

comment on column accounts.monthly_salary_fils is
  'الراتب الشهري بالفلس — للموظفين فقط، صفر لبقية الأنواع';
