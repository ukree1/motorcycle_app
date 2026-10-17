import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/motor_service.dart';
import '../models/motor.dart';
import 'login_screen.dart';
import 'add_motor_screen.dart';
import 'motor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();
  final MotorService motorService = MotorService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color violet = Color(0xFF8B5CF6);
  static const Color bg = Color(0xFF08080D);
  static const Color panel = Color(0xFF11111A);
  static const Color border = Color(0xFF272637);
  static const Color muted = Color(0xFF9694AA);

  static const Color green = Color(0xFF34D399);
  static const Color red = Color(0xFFF87171);
  static const Color amber = Color(0xFFFBBF24);
  static const Color blue = Color(0xFF60A5FA);

  int selectedIndex = 0;
  bool isDarkMode = true;
  bool loggingOut = false;

  late AnimationController _controller;
  late Stream<List<Motor>> _motorsStream;

  final List<_NavItem> navItems = const [
    _NavItem('Dashboard', Icons.dashboard_rounded),
    _NavItem('My Motors', Icons.two_wheeler_rounded),
    _NavItem('Maintenance', Icons.build_rounded),
    _NavItem('Reminders', Icons.notifications_active_rounded),
    _NavItem('Expenses', Icons.account_balance_wallet_rounded),
    _NavItem('Fuel Log', Icons.local_gas_station_rounded),
    _NavItem('Parts Inventory', Icons.inventory_2_rounded),
    _NavItem('Bike Tips', Icons.lightbulb_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _motorsStream = motorService.getMotors();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------- Theme helpers ----------
  Color get pageBg => isDarkMode ? bg : const Color(0xFFF5F3FA);
  Color get cardBg => isDarkMode ? panel : Colors.white;
  Color get borderColor => isDarkMode ? border : const Color(0xFFE7E2EF);
  Color get textColor => isDarkMode ? Colors.white : const Color(0xFF191522);
  Color get secondaryColor => isDarkMode ? muted : const Color(0xFF777384);

  // ---------- Actions ----------
  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Future<void> logout() async {
    if (loggingOut) return;

    setState(() => loggingOut = true);

    try {
      await authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to log out: $e'),
          backgroundColor: const Color(0xFF351B2A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loggingOut = false);
      }
    }
  }

  Future<void> confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Logout?', style: TextStyle(color: textColor)),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: violet,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await logout();
    }
  }

  void selectPage(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MotorListScreen()),
      );
      return;
    }

    setState(() => selectedIndex = index);
  }

  Future<void> addMotor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMotorScreen()),
    );
  }

  Future<void> openSettings() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cardBg,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      value: isDarkMode,
                      activeThumbColor: violet,
                      title: Text(
                        'Dark mode',
                        style: TextStyle(color: textColor),
                      ),
                      secondary: const Icon(
                        Icons.dark_mode_outlined,
                        color: violet,
                      ),
                      onChanged: (value) {
                        setState(() => isDarkMode = value);
                        setSheetState(() {});
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () => Navigator.pop(sheetContext, 'logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;

    if (result == 'logout') {
      await confirmLogout();
    }
  }

  // ---------- Calculations ----------
  double totalPaid(List<Motor> motors) =>
      motors.fold(0.0, (sum, m) => sum + m.paidAmount);

  double totalBalance(List<Motor> motors) =>
      motors.fold(0.0, (sum, m) => sum + m.balance);

  int fullyPaidCount(List<Motor> motors) =>
      motors.where((m) => m.balance <= 0).length;

  String money(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₱$whole.${parts[1]}';
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: pageBg,
          drawer: desktop
              ? null
              : Drawer(
                  backgroundColor: cardBg,
                  width: 285,
                  child: SafeArea(child: _buildSidebar()),
                ),
          appBar: AppBar(
            backgroundColor: pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: textColor),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  navItems[selectedIndex].title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Motorcycle care and installment tracking',
                  style: TextStyle(color: secondaryColor, fontSize: 11),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: openSettings,
                icon: Icon(Icons.settings_outlined, color: secondaryColor),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (desktop) SizedBox(width: 245, child: _buildSidebar()),
              Expanded(
                child: Stack(
                  children: [
                    if (isDarkMode)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (_, __) => CustomPaint(
                              painter: _ParticlePainter(_controller.value),
                            ),
                          ),
                        ),
                      ),
                    _buildSelectedPage(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 15, 27),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: violet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: violet,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MOTOR',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Text(
                        'TRACKER',
                        style: TextStyle(
                          color: violet,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: [
                Text(
                  'WORKSPACE',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (int i = 0; i < navItems.length; i++) _buildNavItem(i),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 15,
                  ),
                  child: Divider(color: borderColor),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 10),
                  child: Text(
                    'PREFERENCES',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                _sidebarAction(
                  Icons.settings_outlined,
                  'Settings',
                  () {
                    _closeDrawerIfOpen();
                    openSettings();
                  },
                ),
                _sidebarAction(
                  Icons.logout_rounded,
                  loggingOut ? 'Logging out...' : 'Logout',
                  loggingOut
                      ? () {}
                      : () {
                          _closeDrawerIfOpen();
                          confirmLogout();
                        },
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: violet.withValues(alpha: 0.35)),
              gradient: LinearGradient(
                colors: [violet.withValues(alpha: 0.16), cardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: violet,
                  size: 25,
                ),
                const SizedBox(height: 10),
                Text(
                  'Ride safely.',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Regular maintenance helps keep your motorcycle road-ready.',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = navItems[index];
    final selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? violet.withValues(alpha: 0.17) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // FIX: use the scaffold key instead of Scaffold.of(context),
            // which threw because State.context sits above the Scaffold.
            _closeDrawerIfOpen();
            selectPage(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? violet.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? violet : secondaryColor,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: selected ? violet : textColor,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: violet,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarAction(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color ?? secondaryColor, size: 20),
      title: Text(
        title,
        style: TextStyle(color: color ?? textColor, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSelectedPage() {
    if (selectedIndex != 0) {
      return _buildPlaceholderPage();
    }

    return StreamBuilder<List<Motor>>(
      stream: _motorsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final motors = snapshot.data!;
        final paid = totalPaid(motors);
        final balance = totalBalance(motors);
        final fullyPaid = fullyPaidCount(motors);
        final totalAmount = paid + balance;
        final progress =
            totalAmount > 0 ? (paid / totalAmount).clamp(0.0, 1.0) : 0.0;

        return RefreshIndicator(
          color: violet,
          backgroundColor: cardBg,
          onRefresh: () async {
            setState(() {
              _motorsStream = motorService.getMotors();
            });
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(22),
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 27),
              _sectionHeading('Overview', Icons.analytics_outlined),
              const SizedBox(height: 15),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 4
                      : constraints.maxWidth >= 470
                          ? 2
                          : 1;

                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: columns == 1 ? 2.2 : 1.25,
                    children: [
                      _statCard(
                        'Total Motors',
                        '${motors.length}',
                        Icons.two_wheeler_rounded,
                        violet,
                        'Registered motorcycles',
                      ),
                      _statCard(
                        'Total Paid',
                        money(paid),
                        Icons.account_balance_wallet_outlined,
                        green,
                        'Recorded payments',
                      ),
                      _statCard(
                        'Remaining',
                        money(balance),
                        Icons.payments_outlined,
                        red,
                        'Outstanding balance',
                      ),
                      _statCard(
                        'Fully Paid',
                        '$fullyPaid / ${motors.length}',
                        Icons.verified_outlined,
                        amber,
                        'Motors with no balance',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildPaymentProgress(progress, paid, totalAmount),
              if (motors.isEmpty) ...[
                const SizedBox(height: 16),
                _buildEmptyMotors(),
              ],
              const SizedBox(height: 28),
              _sectionHeading(
                'Maintenance Checklist',
                Icons.build_circle_outlined,
              ),
              const SizedBox(height: 14),
              _maintenanceTip(
                Icons.oil_barrel_outlined,
                'Engine oil',
                'Check oil level and follow the manufacturer service interval.',
                const Color(0xFFA78BFA),
              ),
              _maintenanceTip(
                Icons.tire_repair_outlined,
                'Tires and brakes',
                'Inspect tire pressure, tread, and brake response regularly.',
                blue,
              ),
              _maintenanceTip(
                Icons.battery_charging_full_rounded,
                'Battery and lights',
                'Check battery terminals, headlights, signals, and brake lights.',
                green,
              ),
              _maintenanceTip(
                Icons.settings_rounded,
                'Chain and drivetrain',
                'Inspect chain slack, lubrication, and unusual noises.',
                amber,
              ),
              const SizedBox(height: 24),
              _sectionHeading('Quick Actions', Icons.bolt_rounded),
              const SizedBox(height: 14),
              _actionButton(
                Icons.add_circle_outline_rounded,
                'Add New Motor',
                'Register a motorcycle',
                true,
                addMotor,
              ),
              const SizedBox(height: 11),
              _actionButton(
                Icons.view_list_rounded,
                'View Motor Records',
                'See your registered motorcycles',
                false,
                () => selectPage(1),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: violet.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: violet.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: violet,
                      size: 26,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Riding Tip',
                            style: TextStyle(
                              color: violet,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Never ignore unusual engine sounds, brake changes, or warning lights. Inspect your motorcycle before long rides.',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'MOTOR TRACKER • KEEP YOUR RIDE ROAD-READY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: violet.withValues(alpha: 0.4)),
        gradient: LinearGradient(
          colors: isDarkMode
              ? const [Color(0xFF281746), Color(0xFF11111A)]
              : const [Color(0xFFEDE5FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: violet.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'YOUR MOTORCYCLE WORKSPACE',
              style: TextStyle(
                color: violet,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            // FIX: was '\\n', which printed a literal backslash-n.
            'Keep Your Ride\nIn Top Condition.',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Manage your motorcycles, track installment balances, and build better maintenance habits.',
            style: TextStyle(color: secondaryColor, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: addMotor,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add Motor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgress(
    double progress,
    double paid,
    double totalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Installment Progress',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: green,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: green,
              backgroundColor: borderColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${money(paid)} paid of ${money(totalAmount)} total',
            style: TextStyle(color: secondaryColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMotors() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.two_wheeler_rounded, color: violet, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'No motorcycles yet. Tap "Add Motor" to register your first one.',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: violet, size: 21),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color accent,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(color: secondaryColor, fontSize: 11)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: secondaryColor, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _maintenanceTip(
    IconData icon,
    String title,
    String description,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String title,
    String subtitle,
    bool filled,
    VoidCallback onTap,
  ) {
    return Material(
      color: filled ? violet : cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: filled ? violet : borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: filled ? Colors.white : violet, size: 25),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: filled ? Colors.white : textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: filled ? Colors.white70 : secondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: filled ? Colors.white : violet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage() {
    final item = navItems[selectedIndex];

    const descriptions = <int, String>{
      2: 'Organize oil changes, tire inspections, brake checks, and other motorcycle services.',
      3: 'Keep track of upcoming oil changes, scheduled inspections, and service intervals.',
      4: 'Review maintenance costs, repair expenses, and motorcycle-related purchases.',
      5: 'Record fuel purchases and monitor your motorcycle fuel economy.',
      6: 'Keep an organized list of spare parts, tools, and motorcycle supplies.',
      7: 'Learn useful maintenance practices to help keep your motorcycle road-ready.',
    };

    final description = descriptions[selectedIndex] ??
        'Manage your motorcycle information in one place.';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(item.icon, color: violet, size: 32),
              ),
              const SizedBox(height: 22),
              Text(
                item.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: violet.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: violet.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.construction_rounded, color: violet),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This section is a UI placeholder for now. No maintenance records, expenses, fuel entries, or reminders are being saved here yet.',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (selectedIndex == 2) ...[
                _actionButton(
                  Icons.build_circle_outlined,
                  'Open Maintenance Checklist',
                  'View recommended maintenance checks',
                  true,
                  () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: cardBg,
                        title: Text(
                          'Maintenance Checklist',
                          style: TextStyle(color: textColor),
                        ),
                        content: Text(
                          'Check engine oil, tires, brakes, battery, lights, and chain condition. Follow your motorcycle manufacturer’s service schedule.',
                          style: TextStyle(color: secondaryColor, height: 1.6),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Close',
                              style: TextStyle(color: violet),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              _actionButton(
                Icons.two_wheeler_rounded,
                'View My Motors',
                'Open your registered motorcycle records',
                false,
                () => selectPage(1),
              ),
              const SizedBox(height: 12),
              _actionButton(
                Icons.add_circle_outline_rounded,
                'Add a Motor',
                'Register another motorcycle',
                true,
                addMotor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(color: violet, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your dashboard...',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching your motor records',
            style: TextStyle(color: secondaryColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: red, size: 54),
            const SizedBox(height: 18),
            Text(
              'Unable to load motor records',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Check your connection and try again. You can expand the technical details to inspect the error.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Technical details',
                style: TextStyle(color: secondaryColor),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    error,
                    style: TextStyle(color: secondaryColor, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _motorsStream = motorService.getMotors();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: violet,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;

  const _NavItem(this.title, this.icon);
}

class _ParticlePainter extends CustomPainter {
  final double animation;

  _ParticlePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Fresh seeded Random each paint so particle positions stay stable.
    final random = Random(42);
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.19);

    for (int i = 0; i < 55; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + animation * size.height) % size.height;

      canvas.drawCircle(Offset(x, y), 1.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}