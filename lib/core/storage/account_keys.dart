/// Every saved value belongs to one account (phone number), so several accounts can
/// live on the same phone and none of them ever touches another one's data.
String acctKey(String? phone, String base) => 'u_${phone ?? 'guest'}_$base';
