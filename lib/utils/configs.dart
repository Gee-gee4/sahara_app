const String stationNameKey = 'stationName';
const String stationIdKey = 'stationId';
const String urlKey = 'tatsUrl';
const String durationKey = 'duration';

const String consumerKey = 'com.cloudtats.dashboard';
const String consumerSecret = 'GHj3UhLip501CDCa';

// ✅ Start with working project's default, but allow override
String baseTatsUrl = 'http://etims.saharafcs.com:8889';

// ✅ Make these functions instead of static strings so they update when baseTatsUrl changes
String get authUrl => '$baseTatsUrl/auth/token';
String get signupUrl => '$baseTatsUrl/signup';
String get userInfoUrl => '$baseTatsUrl/userInfo';

String fetchPumpsUrl(String stationName) => 
    '$baseTatsUrl/stations/pumps/$stationName';
String postTransactionUrl() =>
    '$baseTatsUrl/v2/transactions';
String fetchTransactionsUrl({
  required String stationId,
  required String pumpId,
  bool isPosted = false,
  DateTime? fromDate,
  DateTime? toDate,
}) =>
    '$baseTatsUrl/v2/transactions?automationDeviceId=$stationId&pumpAddress=$pumpId&isPosted=$isPosted${fromDate == null ? "" : "&fromDate=$fromDate"}${toDate == null ? "" : "&toDate=$toDate"}';