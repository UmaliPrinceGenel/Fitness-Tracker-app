import 'package:flutter/material.dart';

class PhotoEditingScreen extends StatefulWidget {
  final String? initialImagePath;
  final String? initialCaption;

  const PhotoEditingScreen({
    super.key,
    this.initialImagePath,
    this.initialCaption,
  });

  @override
  State<PhotoEditingScreen> createState() => _PhotoEditingScreenState();
}

class _PhotoEditingScreenState extends State<PhotoEditingScreen> {
  String? _selectedImage;
  String _caption = '';
  TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImagePath;
    _caption = widget.initialCaption ?? '';
    _captionController.text = _caption;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Create Post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _showDiscardDialog(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _selectedImage != null || _caption.isNotEmpty
                ? () {
                    // Return the image and caption to the previous screen
                    Navigator.pop(context, {
                      'image': _selectedImage,
                      'caption': _captionController.text.trim(),
                    });
                  }
                : null,
            child: const Text(
              "Post",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image selection area
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (_selectedImage != null)
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            color: Colors.grey[800],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.asset(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[800],
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                color: Colors.grey[600],
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No image selected",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _selectImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  "Select Image",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF191919),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEditButton(
                              icon: Icons.image,
                              label: "Gallery",
                              onTap: _selectImage,
                            ),
                            _buildEditButton(
                              icon: Icons.camera_alt,
                              label: "Camera",
                              onTap: () {
                                // Would implement camera functionality
                              },
                            ),
                            _buildEditButton(
                              icon: Icons.tune,
                              label: "Edit",
                              onTap: () {
                                // Would implement image editing
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Caption input
                Text(
                  "Caption",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: "Write a caption...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        _caption = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _selectImage() {
    // In a real app, this would open the image picker
    // For now, we'll just use a placeholder
    setState(() {
      _selectedImage = "assets/album.jpg"; // Using a placeholder image
    });
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191919),
          title: Text("Discard Post", style: TextStyle(color: Colors.white)),
          content: Text(
            "Are you sure you want to discard this post?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                "Continue Editing",
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text("Discard", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
