class NotificationPreferences {
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