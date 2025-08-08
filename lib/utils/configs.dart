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

// ✅ UPDATED: Use the working format with fdcName and ISO date format
String fetchTransactionsUrl({
  required String stationName,
  required String pumpId,
  DateTime? fromDate,
  DateTime? toDate,
}) {
  String url = '$baseTatsUrl/v2/transactions?fdcName=$stationName';
  
  if (fromDate != null) {
    url += '&fromDate=${fromDate.toIso8601String()}';
  }
  
  if (toDate != null) {
    url += '&toDate=${toDate.toIso8601String()}';
  }
  
  return url;
}

// ✅ NEW: Alternative function for single pump transactions
String fetchPumpTransactionsUrl({
  required String stationName,
  required String pumpId,
  DateTime? fromDate,
  DateTime? toDate,
}) {
  String url = '$baseTatsUrl/v2/transactions?fdcName=$stationName&pumpAddress=$pumpId';
  
  if (fromDate != null) {
    url += '&fromDate=${fromDate.toIso8601String()}';
  }
  
  if (toDate != null) {
    url += '&toDate=${toDate.toIso8601String()}';
  }
  
  return url;
}