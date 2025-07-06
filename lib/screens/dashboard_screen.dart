import 'package:flutter/material.dart';
import 'package:flutterapp/viewmodels/dashboard_view_model.dart';
import 'package:flutterapp/viewmodels/transaction_view_model.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _currentMonthStart;
  late DateTime _currentMonthEnd;

  @override
  void initState() {
    super.initState();
    _setPeriodToCurrentMonth();
  }


  void _setPeriodToCurrentMonth() {
    final now = DateTime.now();
    _currentMonthStart = DateTime(now.year, now.month, 1);
    _currentMonthEnd = DateTime(now.year, now.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, dashboardViewModel, child) {
        final transactionViewModel = Provider.of<TransactionViewModel>(context);
        if (transactionViewModel.transactions.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: const Center(child: Text("Add some transactions to see your dashboard!")),
          );
        }

        final monthlyTotals = dashboardViewModel.getTotalsForDateRange(_currentMonthStart, _currentMonthEnd);
        final totalIncome = monthlyTotals['income'] ?? 0.0;
        final totalExpenses = monthlyTotals['expenses'] ?? 0.0;
        final expensesByCategory = dashboardViewModel.getExpensesByCategory(_currentMonthStart, _currentMonthEnd);
        final monthlyTrends = dashboardViewModel.getMonthlyTrends(6);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary for ${DateFormat('MMMM yyyy').format(_currentMonthStart)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('Total Income', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('€${totalIncome.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('Total Expenses', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('€${totalExpenses.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Expenses by Category (${DateFormat('MMMM yyyy').format(_currentMonthStart)})',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (expensesByCategory.isEmpty)
                  const Center(child: Text("No expenses for this month to categorize."))
                else
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(expensesByCategory),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(enabled: true),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildPieChartLegend(expensesByCategory),
                const SizedBox(height: 32),
                Text(
                  'Monthly Trends (Last 6 Months)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildMonthlyTrendChartData(monthlyTrends),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
  List<PieChartSectionData> _buildPieChartSections(Map<String, double> data) {
    if (data.isEmpty) return [];

    final total = data.values.fold(0.0, (sum, amount) => sum + amount);
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
/*       Colors.brown,
      Colors.pink,
      Colors.cyan,
      Colors.indigo,  */
    ];

    int colorIndex = 0;
    return data.entries.map((entry) {
      final double percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: Text(
          entry.key,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        badgePositionPercentageOffset: 1.2, 
      );
    }).toList();
  }

  Widget _buildPieChartLegend(Map<String, double> data) {
    final List<Color> colors = [
      Colors.blue, Colors.green, Colors.red, Colors.purple,
      Colors.orange, Colors.teal, Colors.brown, Colors.pink,
      Colors.cyan, Colors.indigo,
    ];
    int colorIndex = 0;

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: data.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(entry.key, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
          ],
        );
      }).toList(),
    );
  }

  LineChartData _buildMonthlyTrendChartData(Map<String, Map<String, double>> monthlyTrends) {
    final List<String> monthLabels = monthlyTrends.keys.toList();
    double maxY = 0;

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];

    for (int i = 0; i < monthLabels.length; i++) {
      final monthKey = monthLabels[i];
      final data = monthlyTrends[monthKey]!;
      final income = data['income'] ?? 0.0;
      final expenses = data['expenses'] ?? 0.0;

      incomeSpots.add(FlSpot(i.toDouble(), income));
      expenseSpots.add(FlSpot(i.toDouble(), expenses));

      if (income > maxY) maxY = income;
      if (expenses > maxY) maxY = expenses;
    }

    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0 && (incomeSpots.isNotEmpty || expenseSpots.isNotEmpty)) {
      maxY = 100; 
    } else if (maxY == 0) {
      maxY = 1; 
    }


    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < monthLabels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(monthLabels[index], style: const TextStyle(fontSize: 10)),
                );
              }
              return const Text('');
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('€${value.toInt()}', style: const TextStyle(fontSize: 10)),
            interval: maxY / 4,
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: (monthLabels.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final textStyle = TextStyle(color: touchedSpot.bar.color, fontWeight: FontWeight.bold, fontSize: 12);
              return LineTooltipItem(
                '${touchedSpot.bar.color == Colors.green ? 'Income' : 'Expenses'}: €${touchedSpot.y.toStringAsFixed(2)}',
                textStyle,
              );
            }).toList();
          },
        ),
      ),
    );
  }
}