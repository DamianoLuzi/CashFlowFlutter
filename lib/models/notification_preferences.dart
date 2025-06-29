/* class NotificationPreferences {
  final bool overBudgetAlerts;
  // Add other preferences as needed

  NotificationPreferences({
    this.overBudgetAlerts = true, // Default to true
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> data) {
    return NotificationPreferences(
      overBudgetAlerts: data['overBudgetAlerts'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overBudgetAlerts': overBudgetAlerts,
    };
  }
}
 */

class NotificationPreferences {
  final bool overBudgetAlerts;
  final bool spendingSummary;

  NotificationPreferences({
    this.overBudgetAlerts = false,
    this.spendingSummary = false, 
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> data) {
    return NotificationPreferences(
      overBudgetAlerts: data['overBudgetAlerts'] ?? false,
      spendingSummary: data['spendingSummary'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overBudgetAlerts': overBudgetAlerts,
      'spendingSummary': spendingSummary,
    };
  }
  NotificationPreferences copyWith({
    bool? overBudgetAlerts,
    bool? spendingSummary,
  }) {
    return NotificationPreferences(
      overBudgetAlerts: overBudgetAlerts ?? this.overBudgetAlerts,
      spendingSummary: spendingSummary ?? this.spendingSummary,
    );
  }
}
