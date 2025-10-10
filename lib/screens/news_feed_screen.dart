import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/report.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> with TickerProviderStateMixin {
  final _news = NewsService();
  late AnimationController _fabAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<double> _fabAnimation;
  
  // Module palette
  static const Color _primary = Color(0xFF1565C0);
  static const Color _accent = Color(0xFF26A69A);
  static const Color _verified = Color(0xFF2E7D32);
  static const Color _breaking = Color(0xFFC62828);
  
  String _query = '';
  String _category = '';
  bool _breakingOnly = false;
  bool _verifiedOnly = false;
  String _sortMode = 'Recent';


  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Filter Articles',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Category section
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                
                // All Categories chip
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 18,
                          color: _category.isEmpty 
                            ? _primary 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        const Text('All Categories'),
                      ],
                    ),
                    selected: _category.isEmpty,
                    onSelected: (_) {
                      setState(() => _category = '');
                      setSheetState(() {});
                    },
                    selectedColor: _primary.withOpacity(0.15),
                    checkmarkColor: _primary,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    side: BorderSide(
                      color: _category.isEmpty 
                        ? _primary.withOpacity(0.5)
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Category chips
                _buildLeftAlignedCategoryRow(['Politics', 'Economy'], setSheetState),
                const SizedBox(height: 8),
                _buildLeftAlignedCategoryRow(['Health', 'Education'], setSheetState),
                const SizedBox(height: 8),
                _buildLeftAlignedCategoryRow(['Infrastructure'], setSheetState),
                const SizedBox(height: 8),
                _buildLeftAlignedCategoryRow(['Environment', 'Justice'], setSheetState),
                
                const SizedBox(height: 24),
                
                // Options section
                Text(
                  'Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: _breakingOnly 
                              ? _breaking 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          const Text('Breaking News'),
                        ],
                      ),
                      selected: _breakingOnly,
                      onSelected: (v) {
                        setState(() => _breakingOnly = v);
                        setSheetState(() {});
                      },
                      selectedColor: _breaking.withOpacity(0.15),
                      checkmarkColor: _breaking,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      side: BorderSide(
                        color: _breakingOnly 
                          ? _breaking.withOpacity(0.6)
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _verifiedOnly 
                              ? _verified 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          const Text('Verified Only'),
                        ],
                      ),
                      selected: _verifiedOnly,
                      onSelected: (v) {
                        setState(() => _verifiedOnly = v);
                        setSheetState(() {});
                      },
                      selectedColor: _verified.withOpacity(0.15),
                      checkmarkColor: _verified,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      side: BorderSide(
                        color: _verifiedOnly 
                          ? _verified.withOpacity(0.6)
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _category = '';
                            _breakingOnly = false;
                            _verifiedOnly = false;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Apply'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('News Feed'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            _fabAnimationController.reverse().then((_) {
              Navigator.pushNamed(context, '/publish');
              _fabAnimationController.forward();
            });
          },
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Write Article'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double horizontalPadding = constraints.maxWidth > 1000 ? (constraints.maxWidth - 900) / 2 : 0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12 + horizontalPadding, 12, 12 + horizontalPadding, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _query = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _showFilterBottomSheet();
                  },
                  icon: const Icon(Icons.filter_list_rounded),
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),
          // Filters moved to bottom sheet popup (no inline expansion)
          // Sort chips with animations
          Padding(
            padding: EdgeInsets.fromLTRB(12 + horizontalPadding, 8, 12 + horizontalPadding, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAnimatedSortChip('Recent', Icons.schedule_rounded, _primary),
                  const SizedBox(width: 8),
                  _buildAnimatedSortChip('Popular', Icons.trending_up_rounded, _accent),
                  const SizedBox(width: 8),
                  _buildAnimatedSortChip('Verified', Icons.verified_rounded, _verified),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async { await Future.delayed(const Duration(milliseconds: 350)); setState(() {}); },
              child: StreamBuilder<List<ReportArticle>>(
              stream: _news.streamArticles(
                searchQuery: _query,
                category: _category.isEmpty ? null : _category,
                breakingOnly: _breakingOnly ? true : null,
                verifiedOnly: _verifiedOnly ? true : null,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildShimmerLoading();
                }
                List<ReportArticle> items = List<ReportArticle>.from(snapshot.data!);
                // Apply client-side sort
                if (_sortMode == 'Popular') {
                  items.sort((a, b) => b.likeCount.compareTo(a.likeCount));
                } else if (_sortMode == 'Verified') {
                  items.sort((a, b) {
                    final av = a.isVerified ? 1 : 0;
                    final bv = b.isVerified ? 1 : 0;
                    if (av != bv) return bv.compareTo(av);
                    return 0; // keep stream order (recent)
                  });
                }
                if (items.isEmpty) {
                  return const Center(child: Text('No news found'));
                }
                return AnimatedList(
                  key: ValueKey('${_sortMode}_${items.length}'),
                  initialItemCount: items.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= items.length) {
                      return const SizedBox.shrink();
                    }
                    final a = items[index];
                    return SlideTransition(
                      position: animation.drive(
                        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeOut)),
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(16 + horizontalPadding, 8, 16 + horizontalPadding, 8),
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(context, '/article', arguments: a.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.title,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Theme.of(context).colorScheme.onSurface,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (a.bannerImageUrl != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: NetworkImage(a.bannerImageUrl!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Text(
                                      a.summary, 
                                      maxLines: 3, 
                                      overflow: TextOverflow.ellipsis, 
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (a.isBreakingNews) _chip('Breaking', _breaking),
                                        if (a.isVerified) _chip('Verified', _verified),
                                        if (a.category.isNotEmpty) _chip(a.category, _primary),
                                        ...a.hashtags.take(3).map((h) => _chip('#$h', _accent)).toList(),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 14,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                a.authorName,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.schedule,
                                                  size: 12,
                                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _formatDate(a.createdAt.toDate()),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(label),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'breaking':
        return Icons.bolt;
      case 'verified':
        return Icons.verified;
      case 'politics':
        return Icons.account_balance;
      case 'economy':
        return Icons.trending_up;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'infrastructure':
        return Icons.construction;
      case 'environment':
        return Icons.eco;
      case 'justice':
        return Icons.gavel;
      default:
        return Icons.tag;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'politics':
        return Colors.red;
      case 'economy':
        return Colors.orange;
      case 'health':
        return Colors.green;
      case 'education':
        return Colors.blue;
      case 'infrastructure':
        return Colors.purple;
      case 'environment':
        return Colors.teal;
      case 'justice':
        return Colors.indigo;
      default:
        return _primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildLeftAlignedCategoryRow(List<String> categories, StateSetter setSheetState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: categories.map((category) {
        Color chipColor = _getCategoryColor(category);
        IconData categoryIcon = _getCategoryIcon(category);
        bool isSelected = _category == category;
        
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                categoryIcon,
                size: 16,
                color: isSelected 
                  ? chipColor 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (_) {
            setState(() => _category = category);
            setSheetState(() {});
          },
          selectedColor: chipColor.withOpacity(0.15),
          checkmarkColor: chipColor,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          side: BorderSide(
            color: isSelected 
              ? chipColor.withOpacity(0.6)
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedSortChip(String label, IconData icon, Color color) {
    bool isSelected = _sortMode == label;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                ? color 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                  ? color 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _sortMode = label),
        selectedColor: color.withOpacity(0.15),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        side: BorderSide(
          color: isSelected 
            ? color.withOpacity(0.6)
            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title shimmer
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Summary shimmer
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              // Tags shimmer
              Row(
                children: [
                  Container(
                    height: 24,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 24,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


