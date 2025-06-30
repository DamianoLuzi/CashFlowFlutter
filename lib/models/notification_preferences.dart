class NotificationPreferences {
  final bool overBudgetAlerts;
  final bool spendingSummaries;

  NotificationPreferences({
    this.overBudgetAlerts = false,
    this.spendingSummaries = false, 
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> data) {
    return NotificationPreferences(
      overBudgetAlerts: data['overBudgetAlerts'] ?? false,
      spendingSummaries: data['spendingSummaries'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overBudgetAlerts': overBudgetAlerts,
      'spendingSummaries': spendingSummaries,
    };
  }
  NotificationPreferences copyWith({
    bool? overBudgetAlerts,
    bool? spendingSummary,
  }) {
    return NotificationPreferences(
      overBudgetAlerts: overBudgetAlerts ?? this.overBudgetAlerts,
      spendingSummaries: spendingSummary ?? spendingSummaries,
    );
  }
}
