import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart'; // Import Fluent Icons
import 'package:url_launcher/url_launcher.dart';

import 'budget_screen.dart';
import 'goals_screen.dart';
import 'dashboard_screen.dart';

// Define the primary accent color globally for consistent modern theming
const Color primaryAccent = Color(0xFF4C5BF0); 

class FinancialEducScreen extends StatefulWidget {
  const FinancialEducScreen({super.key});

  @override
  State<FinancialEducScreen> createState() => _FinancialEducScreenState();
}

class _FinancialEducScreenState extends State<FinancialEducScreen> {
  bool _isOnline = true;
  int _selectedIndex = 3; // Education screen is index 3
  late Future<QuerySnapshot> _contentFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _contentFuture = _fetchEducationalContent();

    // Search listener
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<QuerySnapshot> _fetchEducationalContent() async {
    // NOTE: This requires FirebaseFirestore to be correctly initialized in the main app
    return await FirebaseFirestore.instance
        .collection('educational_content')
        .orderBy('timestamp', descending: true)
        .get();
  }

  // ========== Navigation Logic (Modernized) ==========
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const BudgetScreen();
        break;
      case 1:
        nextScreen = const GoalsScreen();
        break;
      case 2:
        nextScreen = const DashboardScreen();
        break;
      default:
        return; // Should not happen for index 3
    }

    // Use pushReplacement to update the main screen context efficiently
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  void _openLink(String url) async {
    if (url.isEmpty) return;
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open the link.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening link: $e")),
        );
      }
    }
  }
  
  // Modernized Nav Item builder
  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? activeIcon : icon, 
            color: selected ? primaryAccent : Colors.grey.shade600, 
            size: 26),
          Text(label,
              style: TextStyle(
                  color: selected ? primaryAccent : Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // Modernized Bottom Navigation Bar
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
              color: primaryAccent.withOpacity(0.1), 
              blurRadius: 15, 
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(FluentIcons.wallet_24_regular, FluentIcons.wallet_24_filled, "Budget", 0),
              _buildNavItem(FluentIcons.ribbon_24_regular, FluentIcons.ribbon_24_filled, "Goals", 1),
              _buildNavItem(FluentIcons.grid_dots_24_regular, FluentIcons.grid_dots_24_filled, "Dashboard", 2),
              _buildNavItem(FluentIcons.book_open_24_regular, FluentIcons.book_open_24_filled, "Education", 3),
            ],
          ),
        ),
      ),
    );
  }

  // Modernized Feature Banner
  Widget _buildFeaturedBanner(double Function(double) scale) {
    return Container(
      decoration: BoxDecoration(
        // Use consistent accent color gradient
        gradient: LinearGradient(
          colors: [primaryAccent, primaryAccent.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(scale(20)), // Increased radius
        boxShadow: [
          BoxShadow(
              color: primaryAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: scale(18),
        vertical: scale(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: scale(10), vertical: scale(4)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(scale(10)), // Softer radius
            ),
            child: Text("Featured Course", // Updated label
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: scale(12))),
          ),
          SizedBox(height: scale(12)),
          Text("Master Your Money",
              style: TextStyle(
                  fontSize: scale(22), // Slightly larger font
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: scale(6)),
          Text(
            "Complete our comprehensive course on personal finance basics and build your foundation.",
            style: TextStyle(color: Colors.white70, fontSize: scale(14)),
          ),
          SizedBox(height: scale(10)),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(FluentIcons.rocket_24_regular, color: Colors.white70, size: scale(30)),
          )
        ],
      ),
    );
  }

  // Modernized Article Card
  Widget _buildArticleCard({
    required String tag,
    required String title,
    required String read_time,
    required String link,
    required double Function(double) scale,
    required double fullWidth,
  }) {
    // Check if the content is filtered by the search query
    final contentMatches = title.toLowerCase().contains(_query) ||
        tag.toLowerCase().contains(_query);
    
    if (_query.isNotEmpty && !contentMatches) {
      return Container(); // Hide if no match and search is active
    }

    return InkWell(
      onTap: () => _openLink(link),
      borderRadius: BorderRadius.circular(scale(16)),
      child: Container(
        width: fullWidth,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scale(16)), // Softer radius
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1), // Subtler shadow
                blurRadius: 10, 
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: scale(18), vertical: scale(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tag,
                  style: TextStyle(
                      color: primaryAccent.withOpacity(0.8), // Use accent color
                      fontSize: scale(12),
                      fontWeight: FontWeight.w600)),
              SizedBox(height: scale(8)),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: scale(16))), // Bolder title
              SizedBox(height: scale(6)),
              Row(
                children: [
                  Icon(FluentIcons.clock_20_regular, size: scale(14), color: Colors.black54),
                  SizedBox(width: scale(4)),
                  Text(read_time,
                      style:
                          TextStyle(fontSize: scale(12), color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Scale function based on DashboardScreen logic
    double scale(double value) => value * (width / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Light background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _checkConnection();
            setState(() {
              _contentFuture = _fetchEducationalContent();
            });
          },
          // Use Stack for search overlay, keep the SingleChildScrollView inside
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: scale(16),
                  right: scale(16),
                  top: scale(16),
                  bottom: scale(100), // Add padding for the bottom nav bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER (Modernized)
                    Row(
                      children: [
                        Icon(FluentIcons.book_open_24_filled, // Filled icon for prominence
                            color: primaryAccent, size: scale(30)),
                        SizedBox(width: scale(8)),
                        Text(
                          "Finance Education Hub",
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: scale(20),
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: scale(6)),
                    Text(
                      "Boost your financial knowledge by exploring articles, guides, and featured courses.",
                      style: TextStyle(fontSize: scale(14), color: Colors.black54),
                    ),
                    SizedBox(height: scale(20)),

                    // SEARCH BAR (Modernized)
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search articles, videos & more",
                        prefixIcon: Icon(FluentIcons.search_24_regular, color: Colors.grey.shade500),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(FluentIcons.dismiss_24_regular, color: Colors.grey.shade500),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _query = "";
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: scale(0), horizontal: scale(16)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(scale(16)), // Large radius
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: scale(24)),

                    _buildFeaturedBanner(scale),
                    SizedBox(height: scale(30)),

                    // CONTENT LIST HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Latest Insights",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: scale(18),
                              color: Colors.black87),
                        ),
                        // 'View All' is often implicit on a scrolling content page
                        Text(
                          "",
                          style: TextStyle(
                              color: primaryAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: scale(14)),
                        ),
                      ],
                    ),
                    SizedBox(height: scale(14)),

                    // EDUCATIONAL CONTENT LIST
                    FutureBuilder<QuerySnapshot>(
                      future: _contentFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(scale(40)),
                              child: const CircularProgressIndicator(color: primaryAccent),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(scale(20)),
                            child: Center(
                                child: Text("No content available yet.", style: TextStyle(fontSize: scale(14), color: Colors.grey))),
                          );
                        }

                        final contents = snapshot.data!.docs;
                        
                        // Filter content directly (if search is active, use the searchResults logic in a cleaner way)
                        final filteredContents = _query.isEmpty
                            ? contents
                            : contents.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final title = (data['title'] ?? "").toString().toLowerCase();
                                final tag = (data['tag'] ?? "").toString().toLowerCase();
                                return title.contains(_query) || tag.contains(_query);
                              }).toList();
                        
                        if (filteredContents.isEmpty && _query.isNotEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(scale(20)),
                              child: Center(
                                  child: Text("No results found for '$_query'.", style: TextStyle(fontSize: scale(14), color: Colors.grey))),
                            );
                        }


                        return Column(
                          children: filteredContents.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final tag = data['tag'] ?? "#General";
                            final readTime = data['read_time'] ?? '3 min read';

                            return Padding(
                              padding: EdgeInsets.only(bottom: scale(16)),
                              child: _buildArticleCard(
                                tag: tag,
                                title: data['title'] ?? 'Untitled Content',
                                read_time: readTime,
                                link: data['link'] ?? '',
                                scale: scale,
                                fullWidth: width,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    SizedBox(height: scale(20)),

                    // OFFLINE BANNER (Modernized)
                    if (!_isOnline)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: scale(12), vertical: scale(12)),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50, // Lighter orange
                          borderRadius: BorderRadius.circular(scale(16)), // Softer radius
                          border: Border.all(color: Colors.orange.shade200)
                        ),
                        child: Row(
                          children: [
                            Icon(FluentIcons.wifi_off_24_regular,
                                color: Colors.orange.shade700, size: scale(20)),
                            SizedBox(width: scale(10)),
                            Expanded(
                              child: Text(
                                "You are offline. Content may not be fully up to date. Swipe down to refresh.",
                                style: TextStyle(fontSize: scale(13), color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: scale(10)), 
                  ],
                ),
              ),

              // The original search result overlay logic is merged into the list logic for simplicity 
              // and to avoid complex positioning conflicts, filtering the list directly.
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}