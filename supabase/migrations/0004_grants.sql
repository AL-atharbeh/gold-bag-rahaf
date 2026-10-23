-- ---------------------------------------------------------------------
--  الصلاحيات — منح صريح لا يعتمد على إعدادات Supabase الافتراضية
--
--  السياسات (RLS) تحدّد *أي صفوف* يراها المستخدم.
--  المنح (GRANT) تحدّد *أي جداول* يصلها أصلاً. الاثنان مطلوبان معاً.
-- ---------------------------------------------------------------------

grant usage on schema public to authenticated;

-- القراءة مسموحة على كل شيء؛ السياسات تحصرها في منشأة المستخدم.
grant select on all tables in schema public to authenticated;

-- البيانات المرجعية يعدّلها المستخدم مباشرة.
grant insert, update, delete on accounts, karats, items, gold_prices
  to authenticated;

grant update on profiles to authenticated;

-- السجل المحاسبي لا يُكتب مباشرة أبداً — فقط عبر الدوال (security definer).
-- هذا ما يجعل "لا حذف ولا تعديل" قاعدة تفرضها قاعدة البيانات لا التطبيق.
revoke insert, update, delete on transactions from authenticated;
revoke insert, update, delete on postings     from authenticated;
revoke insert, update, delete on audit_log    from authenticated;
revoke insert, update, delete on doc_counters from authenticated;
revoke update, delete          on tenants     from authenticated;
revoke insert, delete          on profiles    from authenticated;

-- غير المسجّل لا يصل إلى شيء.
revoke all on all tables in schema public from anon;

-- TRUNCATE يمسح الجدول كاملاً، ولا تقيّده سياسات RLS ولا تلتقطه
-- المشغّلات على مستوى الصف. بدون سحبه تبقى قاعدة "لا حذف" قابلة للالتفاف.
-- TRIGGER يسمح بتركيب مشغّلات جديدة على الجداول — طريق لتجاوز الحمايات.
-- كلاهما جاء من منح Supabase الافتراضي، ولا يحتاجهما التطبيق.
revoke truncate, trigger, references on all tables in schema public
  from authenticated;

-- العرضان للقراءة فقط (غير قابلين للكتابة أصلاً، لكن النية تُكتب صراحة).
revoke insert, update, delete on account_balances, account_statement
  from authenticated;
