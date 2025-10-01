import 'package:flutter/material.dart';

class ProgressAlbumScreen extends StatefulWidget {
  const ProgressAlbumScreen({super.key});

  @override
  State<ProgressAlbumScreen> createState() => _ProgressAlbumScreenState();
}

class _ProgressAlbumScreenState extends State<ProgressAlbumScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0; // Track selected tab index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Progress Album",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () {
                // Handle add button press
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Add spacing between app bar and tabs
            const SizedBox(height: 16),

            // Tab bar with Recent and Old tabs
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF191919),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                        _tabController.animateTo(0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Recent',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                        _tabController.animateTo(1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Old',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab content with scrollable date cards
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Recent tab content
                  _buildRecentContent(),
                  // Old tab content
                  _buildOldContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build recent content with date cards in normal order
  Widget _buildRecentContent() {
    List<String> dates = [
      "26 September 2025",
      "25 September 2025",
      "24 September 2025",
      "23 September 2025",
      "22 September 2025",
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (int i = 0; i < dates.length; i++) ...[
            _buildDateCard(dates[i]),
            if (i < dates.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // Build old content with date cards in reverse order
  Widget _buildOldContent() {
    List<String> dates = [
      "26 September 2025",
      "25 September 2025",
      "24 September 2025",
      "23 September 2025",
      "22 September 2025",
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (int i = dates.length - 1; i >= 0; i--) ...[
            _buildDateCard(dates[i]),
            if (i > 0) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // Build a date card with date header and images
  Widget _buildDateCard(String date) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header and share button at the top
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date header at left
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Share button at right
                PopupMenuButton<String>(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Share",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  color: Colors.grey[800], // Grey background for popup menu
                  onSelected: (String result) {
                    // Handle menu item selection
                    if (result == 'share_community') {
                      // Handle "Share to Community" selection
                      _handleShareToCommunity(date);
                    } else if (result == 'send_to') {
                      // Handle "Send to" selection
                      _handleSendTo(date);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'share_community',
                          child: Text(
                            'Share to Community',
                            style: TextStyle(color: Colors.white), // White text
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'send_to',
                          child: Text(
                            'Send to',
                            style: TextStyle(color: Colors.white), // White text
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),

          // Images grid
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: _buildImagesGrid(),
          ),
        ],
      ),
    );
  }

  // Build images grid for a date card
  Widget _buildImagesGrid() {
    // Sample data - in a real app, this would come from your data source
    List<String> images = [
      'assets/album.jpg',
      'assets/lakano.png',
      'assets/logo.jpg',
      'assets/abs.png',
      'assets/mog.jpg',
      'assets/figurines.png',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImageZoom(images[index]),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(images[index], fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  // Show image zoom overlay
  void _showImageZoom(String image) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ImageZoomOverlay(image: image),
      ),
    );
  }

  // Handle sharing to community
  void _handleShareToCommunity(String image) {
    // TODO: Implement actual sharing to community functionality
    // For now, just show a snackbar to indicate the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing $image to community'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Handle sending image
  void _handleSendTo(String image) {
    // TODO: Implement actual send functionality
    // For now, just show a snackbar to indicate the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending $image'), duration: Duration(seconds: 2)),
    );
  }
}

// Image zoom overlay widget with modern design
class _ImageZoomOverlay extends StatelessWidget {
  final String image;

  const _ImageZoomOverlay({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Hero(
                    tag: 'zoomImage',
                    child: Image.asset(image, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            // Close button at top right
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
