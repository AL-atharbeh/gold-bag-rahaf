/// أسماء الشهور وصيغ التاريخ العربية المستعملة في الشاشات.
///
/// أسماء بلاد الشام لا الأسماء اللاتينية — لأن التاجر يقرأ "أيلول"
/// لا "سبتمبر"، والدفتر الورقي الذي نستبدله مكتوب بها.
library;

const List<String> arabicMonths = [
  'كانون الثاني',
  'شباط',
  'آذار',
  'نيسان',
  'أيار',
  'حزيران',
  'تموز',
  'آب',
  'أيلول',
  'تشرين الأول',
  'تشرين الثاني',
  'كانون الأول',
];

String monthName(int month) => arabicMonths[(month - 1).clamp(0, 11)];

/// "أيلول 2026"
String monthLabel(DateTime d) => '${monthName(d.month)} ${d.year}';

/// "2026/09/04"
String shortDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// "4 أيلول"
String dayAndMonth(DateTime d) => '${d.day} ${monthName(d.month)}';

/// أول لحظة في شهر التاريخ المعطى.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

/// أول لحظة في الشهر التالي — الحد الأعلى المفتوح لنطاق الشهر.
DateTime monthEnd(DateTime d) => DateTime(d.year, d.month + 1);

/// هل يقع التاريخ داخل شهر [anchor]؟
bool inSameMonth(DateTime d, DateTime anchor) =>
    d.year == anchor.year && d.month == anchor.month;

/// الشهر السابق أو التالي، مع ضبط انقلاب السنة.
DateTime shiftMonth(DateTime d, int delta) => DateTime(d.year, d.month + delta);
