// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gold Distribution Manager';

  @override
  String get otherLanguage => 'العربية';

  @override
  String get language => 'Language';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get saved => 'Saved';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String genericError(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get offlineBanner =>
      'No internet connection — connect to record transactions';

  @override
  String get offlineAction => 'Can\'t save without an internet connection';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle =>
      'Enter your phone number and we\'ll text you a verification code';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => '07XXXXXXXX';

  @override
  String get invalidPhone => 'Enter a valid Jordanian mobile number';

  @override
  String get sendCode => 'Send code';

  @override
  String get enterCode => 'Enter the verification code';

  @override
  String codeSentTo(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get codeLabel => 'Code';

  @override
  String get invalidCode => 'The code is 6 digits';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get wrongCode => 'The code is wrong or has expired';

  @override
  String get signIn => 'Sign in';

  @override
  String get loginSubtitleDev => 'Enter your phone number to sign in';

  @override
  String get devModeBadge => 'Test mode — sign in without a code';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get changeNumber => 'Change number';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out from this device?';

  @override
  String get registerTitle => 'Create a new account';

  @override
  String get registerSubtitle =>
      'Choose your account type and fill in your details. The app team reviews and activates every request.';

  @override
  String get accountType => 'Account type';

  @override
  String get orgTypeDistributor => 'Bag trader / Distributor';

  @override
  String get orgTypeDistributorDesc =>
      'A gold distributor with one or more bags, dealing with shops and workshops';

  @override
  String get orgTypeFactory => 'Factory / Workshop';

  @override
  String get orgTypeFactoryDesc =>
      'A gold manufacturing workshop with several distribution bags and its own distributors';

  @override
  String get orgTypeShop => 'Gold shop';

  @override
  String get orgTypeShopDesc =>
      'A gold retail shop dealing with distributors, factories and customers';

  @override
  String get orgName => 'Business name';

  @override
  String get ownerName => 'Owner name';

  @override
  String get city => 'Governorate';

  @override
  String get submitRequest => 'Submit registration';

  @override
  String get chooseAccountType => 'Choose an account type first';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusActive => 'Active';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusPendingTitle => 'Your request is under review';

  @override
  String statusPendingBody(String org) {
    return 'We received the registration for “$org”. Our team will contact you to activate the account and choose a plan.';
  }

  @override
  String get statusRejectedTitle => 'Your request was not approved';

  @override
  String get statusSuspendedTitle => 'Account suspended';

  @override
  String statusSuspendedBody(String org) {
    return '“$org” has been suspended. Please contact the app team.';
  }

  @override
  String statusNote(String note) {
    return 'Note: $note';
  }

  @override
  String get checkAgain => 'Check again';

  @override
  String contactUs(String phone) {
    return 'Contact: $phone';
  }

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleBagHolder => 'Bag holder';

  @override
  String get roleAssistant => 'Assistant';

  @override
  String get roleManagerDesc =>
      'Issues, receives and approves stock counts as permitted';

  @override
  String get roleBagHolderDesc =>
      'Carries a bag and confirms what is issued to it';

  @override
  String get roleAssistantDesc => 'Records transactions only';

  @override
  String get permLedgerWrite => 'Record transactions';

  @override
  String get permFinanceView => 'View balances & financial reports';

  @override
  String get permBagsViewAll => 'View all bags';

  @override
  String get permBagsIssue => 'Issue goods to bags';

  @override
  String get permBagsConfirm => 'Confirm receipts & returns';

  @override
  String get permStockCount => 'Request & approve stock counts';

  @override
  String get permChequesManage => 'Manage cheques';

  @override
  String get tabBag => 'Bag';

  @override
  String get goodsIn => 'Goods in';

  @override
  String get goodsInTitle => 'Goods in from workshop';

  @override
  String get workshop => 'Workshop';

  @override
  String get newWorkshop => 'New workshop';

  @override
  String get workshopName => 'Workshop name';

  @override
  String get noWorkshops => 'No workshops yet — add your first one';

  @override
  String get item => 'Item';

  @override
  String get newItem => 'New item';

  @override
  String get itemName => 'Item name';

  @override
  String get count => 'Count';

  @override
  String get grossWeight => 'Gross weight';

  @override
  String get karat => 'Karat';

  @override
  String get makingPerGram => 'Making / gram';

  @override
  String get net24 => 'Net (24K)';

  @override
  String get making => 'Making';

  @override
  String get addLine => 'Add another item';

  @override
  String lineNumber(int n) {
    return 'Line $n';
  }

  @override
  String get summary => 'Summary';

  @override
  String get totalPieces => 'Pieces';

  @override
  String get totalGross => 'Total gross';

  @override
  String get totalNet => 'Total net 24K';

  @override
  String get totalMaking => 'Total making';

  @override
  String effectWorkshop(String gold, String cash) {
    return 'We will owe the workshop: $gold g net and $cash JOD making';
  }

  @override
  String get saveInvoice => 'Save invoice';

  @override
  String invoiceSaved(String doc) {
    return 'Invoice saved — No. $doc';
  }

  @override
  String get fillLines => 'Complete the item and weight on every line';

  @override
  String get noteOptional => 'Notes (optional)';

  @override
  String get date => 'Date';

  @override
  String get gramsUnit => 'g';

  @override
  String get dinarUnit => 'JOD';

  @override
  String get bagEmpty => 'The bag is empty';

  @override
  String get bagEmptyHint =>
      'Record goods in from a workshop and they will appear here by count and weight.';

  @override
  String get bagCapital => 'Capital (making)';

  @override
  String piecesCount(int n) {
    return '$n pcs';
  }

  @override
  String get unknownItem => 'Scrap';

  @override
  String get invalidWeight => 'Invalid weight';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get remove => 'Remove';

  @override
  String get tabShops => 'Shops';

  @override
  String get tabTraders => 'Traders';

  @override
  String get tabSettings => 'Settings';

  @override
  String get phDistributorHome =>
      'Your day at a glance: bag balance, what shops and traders owe you, and what you owe workshops.';

  @override
  String get bagStock => 'Stock';

  @override
  String get bagWorkshops => 'Workshops';

  @override
  String get newShop => 'New shop';

  @override
  String get newTrader => 'New trader';

  @override
  String get noShops => 'No shops yet';

  @override
  String get noShopsHint => 'Add the shops you sell goods to.';

  @override
  String get noTraders => 'No traders yet';

  @override
  String get noTradersHint =>
      'Add the traders you sell scrap to, buy scrap from, or fix prices with.';

  @override
  String get noWorkshopsHint => 'Add the workshops you take goods from.';

  @override
  String get otherLedgers => 'Other ledgers';

  @override
  String get shopSaleTitle => 'Sale to shop';

  @override
  String get shop => 'Shop';

  @override
  String get soldGoods => 'Goods sold';

  @override
  String get receivedScrap => 'Scrap received';

  @override
  String get receivedCash => 'Cash received';

  @override
  String get addScrap => 'Add scrap';

  @override
  String scrapLine(int n) {
    return 'Scrap $n';
  }

  @override
  String get cashAmount => 'Amount';

  @override
  String get accountEffect => 'Effect on the account';

  @override
  String get goldBalance => 'Gold balance';

  @override
  String get cashBalance => 'Cash balance';

  @override
  String get balanceBefore => 'Before';

  @override
  String get balanceAfter => 'After';

  @override
  String owedToUs(String v) {
    return 'Owes us $v';
  }

  @override
  String owedByUs(String v) {
    return 'We owe $v';
  }

  @override
  String get settledZero => 'Zero';

  @override
  String get emptyTx => 'Enter goods, scrap or an amount';

  @override
  String get saveTx => 'Save';

  @override
  String get sell => 'Sell';

  @override
  String get movements => 'Transactions';

  @override
  String get noMovements => 'No transactions yet';

  @override
  String get goldChange => 'Gold';

  @override
  String get cashChange => 'Cash';

  @override
  String bagNotEnough(String item, String karat, String have) {
    return '$item $karat: the bag holds only $have g';
  }

  @override
  String bagNotEnoughCount(String item, String karat, int have) {
    return '$item $karat: the bag holds only $have pcs';
  }

  @override
  String get saleExceedsBag => 'You cannot sell more than the bag holds:';

  @override
  String get onlyHolderSells => 'Only the bag holder can sell from this bag';

  @override
  String get product => 'Product';

  @override
  String get pickFromBag => 'Pick from the bag — tap a product to add it';

  @override
  String get txDetails => 'Transaction details';

  @override
  String get docNumber => 'Invoice No.';

  @override
  String get reversedTx => 'Reversed';

  @override
  String get receivedGoods => 'Goods received';

  @override
  String get deliveredScrap => 'Scrap delivered';

  @override
  String get paidCash => 'Cash paid';

  @override
  String get total => 'Total';

  @override
  String get traderOps => 'Trader transaction';

  @override
  String get opSellGold => 'Sell gold / scrap to trader';

  @override
  String get opSellGoldDesc =>
      'Usually by phone: we owe gold, they owe cash at the 24K price';

  @override
  String get opBuyGold => 'Buy gold / scrap from trader';

  @override
  String get opBuyGoldDesc => 'They owe gold, we owe cash at the 24K price';

  @override
  String get opFix => 'Fix price (تسكير)';

  @override
  String get opFixDesc =>
      'Convert the gold balance to cash at today\'s 24K price';

  @override
  String get opDeliverScrap => 'Deliver scrap to trader';

  @override
  String get opDeliverScrapDesc => 'Leaves the bag and reduces the gold we owe';

  @override
  String get opReceiveScrap => 'Receive scrap from trader';

  @override
  String get opReceiveScrapDesc =>
      'Enters the bag and reduces the gold they owe';

  @override
  String get opReceiveCash => 'Receive cash / cheque';

  @override
  String get opReceiveCashDesc =>
      'A cheque counts as cash and is logged in the cheques ledger';

  @override
  String get opPayCash => 'Pay cash / cheque';

  @override
  String get opPayCashDesc =>
      'A cheque counts as cash and is logged in the cheques ledger';

  @override
  String get opGoodsInvoice => 'Goods invoice + making';

  @override
  String get opGoodsInvoiceDesc =>
      'Goods received from the trader into the bag';

  @override
  String get netGrams24 => 'Weight (net 24K)';

  @override
  String get pricePerGram24 => '24K price per gram';

  @override
  String get totalValue => 'Value';

  @override
  String get fixDirection => 'Direction';

  @override
  String get fixWeOwe => 'We owe gold → we owe cash';

  @override
  String get fixTheyOwe => 'They owe gold → they owe cash';

  @override
  String get byCheque => 'By cheque';

  @override
  String get byChequeHint =>
      'Counts as cash now; its due date is tracked in the cheques ledger';

  @override
  String get chequeNumber => 'Cheque No.';

  @override
  String get bank => 'Bank';

  @override
  String get dueDate => 'Due date';

  @override
  String bagScrapNotEnough(String karat, String have) {
    return '$karat: the bag holds only $have g of scrap';
  }

  @override
  String get scrapExceedsBag =>
      'You cannot deliver more scrap than the bag holds:';

  @override
  String get supplier => 'Supplier (workshop / trader)';

  @override
  String get newKarat => 'New karat';

  @override
  String get karatNameLabel => 'Karat name (e.g. 22K or 9999 bars)';

  @override
  String get factorLabel => 'Factor';

  @override
  String get invalidFactor => 'Invalid factor — between 0.001 and 1.000';

  @override
  String get karatAdded => 'Karat added';

  @override
  String get partialPricing => 'Buy part of it for cash';

  @override
  String get partialPricingHint =>
      'Part of the scrap is priced as cash we owe at the 24K price; the rest goes to the gold balance';

  @override
  String get partGrams => 'Weight bought (net 24K)';

  @override
  String get partExceeds => 'The part bought exceeds the net scrap received';

  @override
  String get wholeBalance => 'Whole balance';

  @override
  String get goldLines => 'Gold / scrap';

  @override
  String get netTotal => 'Net (24K)';

  @override
  String get karatAndFactor => 'Karat & factor';

  @override
  String get otherFactor => 'Instant karat (this operation only)…';

  @override
  String get tabDistributors => 'Distributors';

  @override
  String get tabReceivables => 'Receivables';

  @override
  String get tabCompany => 'International Co.';

  @override
  String get tabEmployees => 'Employees';

  @override
  String get tabCheques => 'Cheques';

  @override
  String get tabMore => 'More';

  @override
  String get tabHome => 'Home';

  @override
  String get tabBags => 'Bags';

  @override
  String get tabMyBag => 'My bag';

  @override
  String get tabTransfers => 'Issue & receive';

  @override
  String get tabConfirmations => 'Confirmations';

  @override
  String get tabStockCount => 'Stock count';

  @override
  String get tabSuppliers => 'Suppliers';

  @override
  String get tabShowcase => 'Showcase';

  @override
  String get tabCustomers => 'Customers';

  @override
  String get nextPhaseTitle => 'Under construction — next phase';

  @override
  String get phFactoryHome =>
      'Factory summary: each bag\'s balance, transactions awaiting confirmation and the latest stock count.';

  @override
  String get phTransfers =>
      'Issue goods to bags and receive scrap and returns. Each transfer waits for the other side\'s confirmation before it hits the balances.';

  @override
  String get phConfirmations =>
      'What the factory issued to your bag, awaiting your confirmation or dispute.';

  @override
  String get phStockCount =>
      'A joint stock count between the manager and the bag holder, comparing what\'s physically there with the book balance.';

  @override
  String get phMyBag => 'Your bag\'s balance and its transactions with shops.';

  @override
  String get phSuppliers =>
      'Ledgers of the distributors and factories you deal with.';

  @override
  String get phShowcase => 'Gold on display and on consignment per supplier.';

  @override
  String get myAccount => 'My account';

  @override
  String get currentAccount => 'Current account';

  @override
  String get switchAccount => 'Switch account';

  @override
  String get team => 'Team';

  @override
  String get teamDesc => 'Add staff and set their permissions';

  @override
  String get bags => 'Bags';

  @override
  String get bagsDesc => 'Bags and their holders';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String get registerAnotherOrg => 'Register another account';

  @override
  String get registerAnotherOrgDesc =>
      'e.g. an independent account alongside your factory membership';

  @override
  String get endsOn => 'Ends on';

  @override
  String get noExpiry => 'No expiry date';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String seatsUsed(int used, int max) {
    return '$used of $max users';
  }

  @override
  String get inviteMember => 'Add member';

  @override
  String get pendingInvitations => 'Invitations awaiting first sign-in';

  @override
  String get invitationHint =>
      'Joins automatically on first sign-in with this number';

  @override
  String get cancelInvitation => 'Cancel invitation';

  @override
  String get memberName => 'Member name';

  @override
  String get role => 'Role';

  @override
  String get permissions => 'Permissions';

  @override
  String get memberActive => 'Membership active';

  @override
  String get inactive => 'Inactive';

  @override
  String get editMember => 'Edit member';

  @override
  String get memberAdded => 'Member added';

  @override
  String get invitationCreated =>
      'Invitation saved — they join on first sign-in';

  @override
  String get you => '(you)';

  @override
  String get ownerOnly => 'This page is for the owner only';

  @override
  String get ownerHasAll => 'The owner has every permission';

  @override
  String bagsUsed(int used, int max) {
    return '$used of $max bags';
  }

  @override
  String get newBag => 'New bag';

  @override
  String get bagName => 'Bag name';

  @override
  String get bagHolder => 'Bag holder';

  @override
  String get noHolder => 'No holder';

  @override
  String get bagActive => 'Bag active';

  @override
  String get editBag => 'Edit bag';

  @override
  String get noBags => 'No bags';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminOrgs => 'Organizations';

  @override
  String get statPending => 'Awaiting activation';

  @override
  String get statActive => 'Active';

  @override
  String get statExpiring => 'Expiring in 14 days';

  @override
  String get statSuspended => 'Suspended';

  @override
  String get statUsers => 'Users';

  @override
  String get pendingRequests => 'Requests awaiting review';

  @override
  String get noPending => 'No new requests';

  @override
  String get searchOrgs => 'Search by name or phone';

  @override
  String get all => 'All';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get activate => 'Activate';

  @override
  String get renew => 'Renew';

  @override
  String get suspend => 'Suspend';

  @override
  String get reject => 'Reject';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get months => 'Duration';

  @override
  String monthsCount(int count) {
    return '$count months';
  }

  @override
  String get note => 'Note';

  @override
  String get addMemberByPhone => 'Add member by phone';

  @override
  String get createdAt => 'Registered';

  @override
  String get owner => 'Owner';

  @override
  String get phone => 'Phone';

  @override
  String get activityLog => 'Activity log';

  @override
  String get nameAr => 'Arabic name';

  @override
  String get nameEn => 'English name';

  @override
  String get price => 'Price (JOD)';

  @override
  String get maxUsers => 'Max users';

  @override
  String get maxBags => 'Max bags';

  @override
  String get extraBagPrice => 'Extra bag price (JOD)';

  @override
  String perPeriod(String price, int months) {
    return '$price JOD / $months mo';
  }

  @override
  String get priceNotSet => 'Price not set';

  @override
  String get noResults => 'No results';

  @override
  String get accountStatement => 'Account statement';

  @override
  String get statementPeriod => 'Period';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String get last3Months => 'Last 3 months';

  @override
  String get thisYear => 'This year';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String get statementLanguage => 'Statement language';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get closingBalance => 'Closing balance';

  @override
  String get periodMovements => 'Period movements';

  @override
  String get previewPdf => 'Preview & share PDF';

  @override
  String get statementHint =>
      'The statement starts with the balance brought forward, then the period\'s movements. Notes are not included.';

  @override
  String get invalidRange => 'Start date is after end date';

  @override
  String get cancelTx => 'Cancel transaction';

  @override
  String get cancelTxBody =>
      'The transaction won\'t be deleted; a reversing entry restores balances and stock, and both stay visible in the ledger. Linked pending cheques are cancelled too.';

  @override
  String get cancelReason => 'Reason for cancelling';

  @override
  String get cancelConfirm => 'Confirm cancel';

  @override
  String txCancelledDoc(String doc) {
    return 'Transaction cancelled — reversal no. $doc';
  }

  @override
  String get txIsReversed =>
      'This transaction was cancelled by a reversing entry and no longer affects balances.';

  @override
  String get txIsReversal =>
      'This is a reversing entry that cancelled an earlier transaction.';

  @override
  String get needMigration12 => 'Run 0012_void_cheque.sql in Supabase first';

  @override
  String get partialReturn => 'Partial return';

  @override
  String get returnFromShopHint =>
      'Returned pieces go back to the bag; the shop\'s net gold and making charge are reduced at the invoice rates.';

  @override
  String get returnToWorkshopHint =>
      'Returned pieces leave the bag to the workshop; what we owe it in gold and making is reduced at the invoice rates.';

  @override
  String get returnAll => 'All';

  @override
  String get returnedCount => 'Returned pcs';

  @override
  String get returnedGross => 'Returned weight';

  @override
  String maxReturn(String count, String grams) {
    return 'Available to return: $count pcs · $grams g';
  }

  @override
  String get returnExceeds => 'More than available to return';

  @override
  String get nothingToReturn => 'Enter the weight of at least one line';

  @override
  String returnSaved(String doc) {
    return 'Return saved — no. $doc';
  }

  @override
  String get returnedGoods => 'Returned goods';

  @override
  String get saveReturn => 'Save return';

  @override
  String get invoiceLines => 'Invoice lines';

  @override
  String get bagEditionSubtitle =>
      'Bag trader edition — sign in with your phone and password';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get wrongPhoneOrPassword => 'Wrong phone number or password';

  @override
  String get forgotPasswordHint =>
      'Forgot your password or need a new account? Contact support';

  @override
  String get accountNotEnabled => 'This account is not enabled in this edition';

  @override
  String get accountNotEnabledHint =>
      'Accounts are added or enabled by support only. Contact us to enable yours.';

  @override
  String get letterheadTitle => 'Statement & invoice header';

  @override
  String get letterheadHint =>
      'Shown at the top of every statement, invoice and PDF report.';

  @override
  String get businessName => 'Business name';

  @override
  String get businessPhone => 'Business phone';

  @override
  String get businessCity => 'City / address';

  @override
  String get editionAccounts => 'Accounts';

  @override
  String accountsUsed(int count, int max) {
    return '$count of $max accounts in use';
  }

  @override
  String get accountsBySupport =>
      'Adding an account, changing a password or disabling an account is done by support. Tap an account to edit its permissions.';

  @override
  String get appSection => 'App';

  @override
  String get aboutEdition => 'About';

  @override
  String get editionVersion => 'Bag trader edition · 1.3.0';

  @override
  String get support => 'Support';

  @override
  String get edit => 'Edit';

  @override
  String get needMigration13 => 'Run 0013_bag_edition.sql in Supabase first';

  @override
  String get welcome => 'Welcome';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get noTradersYet => 'No traders yet — add one from the Traders tab';

  @override
  String get chooseTrader => 'Choose a trader';

  @override
  String get quickSellShop => 'Sell to shop';

  @override
  String get today => 'Today';

  @override
  String get noMovesToday => 'No movements today yet';

  @override
  String get todaySales => 'Today\'s sales (net)';

  @override
  String get makingProfit => 'Making profit';

  @override
  String get cashIn => 'Cash received';

  @override
  String get cashOut => 'Cash paid';

  @override
  String get movementsToday => 'Movements';

  @override
  String get scrapInBag => 'Scrap in bag';

  @override
  String get receivablesSummary => 'Balances';

  @override
  String get topDebtors => 'Largest gold balances';

  @override
  String get chequesOverdue => 'Overdue cheques';

  @override
  String get chequesThisWeek => 'Due this week';

  @override
  String get recentMovements => 'Recent movements';

  @override
  String get reports => 'Reports';

  @override
  String get accountStatements => 'Account statements';

  @override
  String get shopStatement => 'Shop statement';

  @override
  String get traderStatement => 'Trader statement';

  @override
  String get workshopStatement => 'Workshop statement';

  @override
  String get statementTileHint =>
      'Pick the account and period — starts with the opening balance';

  @override
  String get salesAndBag => 'Sales & bag';

  @override
  String get salesReport => 'Sales report';

  @override
  String get salesReportHint =>
      'Daily, weekly, monthly — by day, shop and item';

  @override
  String get bagStatement => 'Bag statement';

  @override
  String get bagStatementHint =>
      'Opening, in, out and closing per item, with all movements';

  @override
  String get bagInventoryNow => 'Bag inventory now';

  @override
  String get bagInventoryHint => 'What\'s in the bag now, item by item';

  @override
  String get shopsBalances => 'Shops balances';

  @override
  String get tradersBalances => 'Traders balances';

  @override
  String get chequesReportHint => 'Pending and closed — with a PDF report';

  @override
  String get noAccountsOfKind => 'No accounts of this kind yet';

  @override
  String get chooseAccount => 'Choose an account';

  @override
  String get thisWeek => 'This week';

  @override
  String get soldNet => 'Sold (net)';

  @override
  String get netSales => 'Net sales';

  @override
  String get makingCharges => 'Making charges';

  @override
  String get invoicesCount => 'Invoices';

  @override
  String get byShop => 'By shop';

  @override
  String get byDay => 'By day';

  @override
  String get noSalesInPeriod => 'No sales in this period';

  @override
  String get goodsInPeriod => 'In during period';

  @override
  String get goodsOutPeriod => 'Out during period';

  @override
  String get stockByItem => 'Stock by item';

  @override
  String get scrap => 'Scrap';

  @override
  String get openingShort => 'Open';

  @override
  String get inShort => 'In';

  @override
  String get outShort => 'Out';

  @override
  String get reportsHint => 'Statements, sales, bag statement, balances';

  @override
  String get shopOps => 'Shop movement';

  @override
  String get shopSellDesc => 'Goods from the bag, with scrap or cash received';

  @override
  String get shopFixDesc =>
      'Pays cash instead of the gold owed — at today\'s 24K gram price';

  @override
  String get movement => 'Movement';

  @override
  String get goodsInBag => 'Goods in bag';

  @override
  String get totalGoldNet => 'Total gold (net)';

  @override
  String get cashInBag => 'Cash in bag';

  @override
  String get chequesInHand => 'Cheques in hand';

  @override
  String get cashboxBalance => 'Cashbox balance';

  @override
  String get chequesInPending => 'Incoming cheques not cashed';

  @override
  String get chequesOutPending => 'Outgoing cheques not cashed';

  @override
  String get cashInBagHint => 'The actual cash you should be holding now.';

  @override
  String get expensesToday => 'Today\'s expenses';

  @override
  String get newExpense => 'Expense';

  @override
  String get closeDay => 'Close day';

  @override
  String get openDay => 'Open day';

  @override
  String get goodMorning => 'Good morning';

  @override
  String goodMorningName(String name) {
    return 'Good morning, $name';
  }

  @override
  String get openDayFor => 'Start of';

  @override
  String get cashYouCarry => 'Cash you carry';

  @override
  String get cashLeftYesterday => 'Left from last day';

  @override
  String cashAddedNote(String amount) {
    return 'You will add $amount JOD to the bag cash';
  }

  @override
  String cashTakenNote(String amount) {
    return 'You will take $amount JOD out of the bag cash';
  }

  @override
  String get reasonRequired => 'Reason (required)';

  @override
  String get startDay => 'Start day';

  @override
  String get confirmGoodsFirst => 'Confirm goods and scrap first';

  @override
  String get dayReport => 'Bag day report PDF';

  @override
  String get closeOldDayFirst =>
      'A previous day is still open. Close it first to start your new day.';

  @override
  String get daySummary => 'Day summary';

  @override
  String get chequesReceived => 'Cheques received';

  @override
  String get cashPaidParties => 'Cash paid to parties';

  @override
  String get afterExpenses => 'After expenses';

  @override
  String get bagCount => 'Bag count';

  @override
  String get confirmGoodsScrap =>
      'I confirm the goods and scrap in the bag match';

  @override
  String get countCash => 'Count cash';

  @override
  String get cashExpected => 'Expected cash per movements';

  @override
  String get cashCounted => 'Cash actually counted';

  @override
  String get matches => 'Matches';

  @override
  String cashShortage(String amount) {
    return 'Shortage $amount JOD';
  }

  @override
  String cashSurplus(String amount) {
    return 'Surplus $amount JOD';
  }

  @override
  String get dayClosed => 'Day closed ✓';

  @override
  String get continueLabel => 'Continue';

  @override
  String get expFuel => 'Fuel';

  @override
  String get expFood => 'Food';

  @override
  String get expTransport => 'Transport';

  @override
  String get expMaintenance => 'Maintenance';

  @override
  String get expPersonal => 'Personal withdrawal';

  @override
  String get expOther => 'Other';

  @override
  String get needMigration14 => 'Run 0014_bag_day.sql in Supabase first';

  @override
  String get expenseSaved => 'Expense saved';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expenseNoteRequired => 'Description (required)';

  @override
  String get expenseHint =>
      'The amount is deducted from the bag cash and shown in today\'s expenses and reports.';

  @override
  String get instantKarat => 'Instant karat';

  @override
  String get makingPerPiece => 'Making / piece';

  @override
  String get perGram => 'Per gram';

  @override
  String get perPiece => 'Per piece';

  @override
  String get makingDiscount => 'Making discount';

  @override
  String get noDiscount => 'No discount';

  @override
  String get dropFraction => 'Drop fraction';

  @override
  String get extraDiscount => 'Extra discount';

  @override
  String get finalMaking => 'Final making';

  @override
  String get recoveredGoods => 'Recovered goods';

  @override
  String get recoveredMaking => 'Recovered making';

  @override
  String get addRecovered => 'Add recovered';

  @override
  String get dailyCashTotal => 'Daily cash total';

  @override
  String get dailyCashHint => 'Opening cash + received';

  @override
  String get netCash => 'Net cash';

  @override
  String get fixClass => 'Fix type';

  @override
  String get fixClassGold => 'Gold';

  @override
  String get fixClassScrap => 'Scrap';

  @override
  String get fixCashNow => 'Cash now (optional)';

  @override
  String get fixCashHint => 'All, part or zero — the rest stays on account.';

  @override
  String get fixWithTrader => 'Fix with a trader or workshop (optional)';

  @override
  String get noTrader => 'No trader or workshop';

  @override
  String get traderGrams => 'Trader grams';

  @override
  String get traderFixHint => 'Empty = same grams and price as the shop.';

  @override
  String get opReceiveGold => 'Receive gold';

  @override
  String get opReceiveGoldDesc =>
      'Into the bag at any karat, factor 1.000 by default';

  @override
  String get opDeliverGold => 'Deliver gold';

  @override
  String get opDeliverGoldDesc =>
      'Out of the bag at any karat, factor 1.000 by default';

  @override
  String get opLira => 'Sell lira with fees';

  @override
  String get opLiraDesc => 'Gross weight, per-piece fees for us';

  @override
  String get opExchange => 'Gold exchange';

  @override
  String get opExchangeDesc => 'Receive and deliver with per-gram fees';

  @override
  String get liraFromBag => 'Leaves the bag';

  @override
  String get liraFromBagHint => 'Turn on if the lira is from bag stock.';

  @override
  String get liraFee => 'Fee / piece';

  @override
  String get liraCountNeeded => 'Enter the count to compute fees.';

  @override
  String get exchangeReceived => 'Gold received';

  @override
  String get exchangeDelivered => 'Gold delivered (optional)';

  @override
  String get exchangeDeliveredHint =>
      'Whatever is not delivered stays on balance.';

  @override
  String get exchangeFee => 'Exchange fee';

  @override
  String get exchangeFeePerGram => 'Fee / gram';

  @override
  String get feeForUs => 'For us';

  @override
  String get feeOnUs => 'On us';

  @override
  String get openingBalances => 'Opening balances';

  @override
  String get openingBalancesHint =>
      'Prior balances for parties, and bag contents';

  @override
  String get openingBag => 'Bag at start';

  @override
  String get openingBagHint => 'Goods, scrap and cash on hand';

  @override
  String get openingGold => 'Gold balance (net 24K)';

  @override
  String get openingCash => 'Cash balance';

  @override
  String get openingForUs => 'He owes us';

  @override
  String get openingForHim => 'We owe him';

  @override
  String openingSaved(String doc) {
    return 'Balance saved — $doc';
  }

  @override
  String get bagMovements => 'Movements';

  @override
  String get allMovements => 'All';

  @override
  String get movementsIn => 'Into the bag';

  @override
  String get movementsOut => 'Out of the bag';

  @override
  String get noBagMovements => 'No movements in this period';

  @override
  String lastMakingHint(String rate, String unit) {
    return 'Last making for this shop: $rate $unit — editable';
  }

  @override
  String recoveredLine(int n) {
    return 'Recovered $n';
  }

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get noExpenses => 'No expenses in this period';

  @override
  String get expensesTotal => 'Total expenses';

  @override
  String get expensesOnEmployees => 'Charged to employees';

  @override
  String get expenseOnEmployee => 'Charge to an employee (optional)';

  @override
  String get noEmployee => 'No employee';

  @override
  String get expenseEmployeeHint =>
      'Paid from the bag cash, deducted from the employee\'s salary, and shown in today\'s expenses.';

  @override
  String get fixInSale => 'Fix price with the sale (optional)';

  @override
  String get fixInSaleHint =>
      'Fix the shop\'s grams in the same invoice, optionally against a trader or workshop.';

  @override
  String get fixGrams => 'Grams to fix (net)';

  @override
  String get fixNeedsGramsPrice =>
      'Enter the fix grams and price, or switch the fix off.';

  @override
  String get fixSpread => 'Price difference';
}
