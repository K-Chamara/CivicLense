import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';

/// BudgetNavigator Widget - Hierarchical government budget breakdown with drill-down navigation
/// 
/// This widget implements a treemap-style budget visualization with:
/// - Hierarchical navigation (Categories → Subcategories → Items)
/// - Smooth animations and transitions
/// - Mobile-responsive design
/// - Real-time data from Firebase Firestore
/// - Color-coded spending indicators
class BudgetNavigator extends StatefulWidget {
  const BudgetNavigator({super.key});

  @override
  State<BudgetNavigator> createState() => _BudgetNavigatorState();
}

class _BudgetNavigatorState extends State<BudgetNavigator>
    with TickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  
  // Navigation state
  BudgetNavigationState _navigationState = BudgetNavigationState(categories: []);
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _budgetStatistics;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBudgetData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Load budget data from Firebase
  Future<void> _loadBudgetData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load budget categories and statistics
      final categories = await _budgetService.getBudgetCategories();
      final statistics = await _budgetService.getBudgetStatistics();

      setState(() {
        _navigationState = _navigationState.copyWith(categories: categories);
        _budgetStatistics = statistics;
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Navigate to subcategories of a budget category
  Future<void> _navigateToSubcategories(BudgetCategory category) async {
    try {
      setState(() => _isLoading = true);

      final subcategories = await _budgetService.getBudgetSubcategories(category.id);

      setState(() {
        _navigationState = _navigationState.copyWith(
          subcategories: subcategories,
          currentLevel: 1,
          parentId: category.id,
          parentName: category.name,
        );
        _isLoading = false;
      });

      // Haptic feedback for navigation
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Navigate to budget items of a subcategory
  Future<void> _navigateToItems(BudgetSubcategory subcategory) async {
    try {
      setState(() => _isLoading = true);

      final items = await _budgetService.getBudgetItems(
        _navigationState.parentId!,
        subcategory.id,
      );

      setState(() {
        _navigationState = _navigationState.copyWith(
          items: items,
          currentLevel: 2,
          parentName: subcategory.name,
        );
        _isLoading = false;
      });

      // Haptic feedback for navigation
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Navigate back to previous level
  void _navigateBack() {
    setState(() {
      if (_navigationState.currentLevel == 2) {
        // Go back to subcategories
        _navigationState = _navigationState.copyWith(
          items: [],
          currentLevel: 1,
          parentName: _navigationState.parentName,
        );
      } else if (_navigationState.currentLevel == 1) {
        // Go back to categories
        _navigationState = _navigationState.copyWith(
          subcategories: [],
          currentLevel: 0,
          parentId: null,
          parentName: null,
        );
      }
    });

    // Haptic feedback for navigation
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with navigation and statistics
            _buildHeader(),
            
            // Main content area
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildBudgetContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the header with navigation and statistics
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation breadcrumb
          _buildNavigationBreadcrumb(),
          
          const SizedBox(height: 16),
          
          // Statistics summary
          if (_budgetStatistics != null) _buildStatisticsSummary(),
        ],
      ),
    );
  }

  /// Build navigation breadcrumb
  Widget _buildNavigationBreadcrumb() {
    return Row(
      children: [
        // Back button (only show if not at root level)
        if (_navigationState.currentLevel > 0) ...[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E4A62),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _navigateBack,
              tooltip: 'Go Back',
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Breadcrumb text
        Expanded(
          child: Text(
            _getBreadcrumbText(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4A62),
            ),
          ),
        ),
        
        // Refresh button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBudgetData,
            tooltip: 'Refresh Data',
          ),
        ),
      ],
    );
  }

  /// Get breadcrumb text based on current navigation level
  String _getBreadcrumbText() {
    switch (_navigationState.currentLevel) {
      case 0:
        return 'Government Budget Overview';
      case 1:
        return '${_navigationState.parentName} - Subcategories';
      case 2:
        return '${_navigationState.parentName} - Budget Items';
      default:
        return 'Government Budget';
    }
  }

  /// Build statistics summary
  Widget _buildStatisticsSummary() {
    final stats = _budgetStatistics!;
    final totalAllocated = stats['totalAllocated'] as double;
    final totalSpent = stats['totalSpent'] as double;
    final spendingPercentage = stats['spendingPercentage'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E4A62), Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Total allocated amount
          Expanded(
            child: _buildStatItem(
              'Total Budget',
              BudgetFormatter.formatAmount(totalAllocated),
              Icons.account_balance_wallet,
            ),
          ),
          
          // Total spent amount
          Expanded(
            child: _buildStatItem(
              'Spent',
              BudgetFormatter.formatAmount(totalSpent),
              Icons.trending_up,
            ),
          ),
          
          // Spending percentage
          Expanded(
            child: _buildStatItem(
              'Spent %',
              BudgetFormatter.formatPercentage(spendingPercentage),
              Icons.pie_chart,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading budget data...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2E4A62),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFE74C3C),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading budget data',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E4A62),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBudgetData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build main budget content based on navigation level
  Widget _buildBudgetContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content based on current navigation level
              if (_navigationState.currentLevel == 0)
                _buildCategoriesView()
              else if (_navigationState.currentLevel == 1)
                _buildSubcategoriesView()
              else if (_navigationState.currentLevel == 2)
                _buildItemsView(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build categories view (root level)
  Widget _buildCategoriesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E4A62),
          ),
        ),
        const SizedBox(height: 16),
        
        // Budget categories list
        ..._navigationState.categories.map((category) => 
          _buildCategoryCard(category)
        ).toList(),
      ],
    );
  }

  /// Build subcategories view
  Widget _buildSubcategoriesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Subcategories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E4A62),
          ),
        ),
        const SizedBox(height: 16),
        
        // Subcategories list
        ..._navigationState.subcategories.map((subcategory) => 
          _buildSubcategoryCard(subcategory)
        ).toList(),
      ],
    );
  }

  /// Build items view
  Widget _buildItemsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E4A62),
          ),
        ),
        const SizedBox(height: 16),
        
        // Items list
        ..._navigationState.items.map((item) => 
          _buildItemCard(item)
        ).toList(),
      ],
    );
  }

  /// Build category card
  Widget _buildCategoryCard(BudgetCategory category) {
    final totalAllocated = _budgetStatistics?['totalAllocated'] as double? ?? 1;
    final percentage = (category.allocatedAmount / totalAllocated) * 100;
    final spendingColor = BudgetFormatter.getSpendingColor(category.spendingPercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToSubcategories(category),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Category details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E4A62),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Amount and percentage
                      Row(
                        children: [
                          Text(
                            BudgetFormatter.formatAmount(category.allocatedAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              BudgetFormatter.formatPercentage(percentage),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90E2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Spending progress bar
                      _buildSpendingProgressBar(category.spendingPercentage, spendingColor),
                    ],
                  ),
                ),
                
                // Navigation arrow
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF4A90E2),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build subcategory card
  Widget _buildSubcategoryCard(BudgetSubcategory subcategory) {
    final spendingColor = BudgetFormatter.getSpendingColor(subcategory.spendingPercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToItems(subcategory),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Subcategory icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(int.parse(subcategory.color.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Subcategory details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subcategory.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E4A62),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subcategory.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Amount
                      Text(
                        BudgetFormatter.formatAmount(subcategory.allocatedAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Spending progress bar
                      _buildSpendingProgressBar(subcategory.spendingPercentage, spendingColor),
                    ],
                  ),
                ),
                
                // Navigation arrow
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF4A90E2),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build item card
  Widget _buildItemCard(BudgetItem item) {
    final spendingColor = BudgetFormatter.getSpendingColor(item.spendingPercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(int.parse(item.color.replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.attach_money,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E4A62),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Amount
                  Text(
                    BudgetFormatter.formatAmount(item.allocatedAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Spending progress bar
                  _buildSpendingProgressBar(item.spendingPercentage, spendingColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build spending progress bar
  Widget _buildSpendingProgressBar(double percentage, String color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${BudgetFormatter.formatPercentage(percentage)}',
              style: TextStyle(
                fontSize: 12,
                color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Remaining: ${BudgetFormatter.formatPercentage(100 - percentage)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(int.parse(color.replaceFirst('#', '0xFF'))),
          ),
          minHeight: 6,
        ),
      ],
    );
  }
}
