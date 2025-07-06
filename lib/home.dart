import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'container.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userId; // Add userId parameter

  const HomeScreen({
    super.key,
    required this.onLogout,
    required this.userId, // Receive userId
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _containerIdController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> _getUserContainers() async {
    final doc = await _firestore.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['containers'] ?? []);
    }
    return [];
  }

  Future<void> _saveContainer(String containerId) async {
    final containers = await _getUserContainers();
    containers.add(containerId);

    await _firestore.collection('users').doc(widget.userId).update({
      'containers': FieldValue.arrayUnion([containerId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteContainer(String containerId) async {
    await _firestore.collection('users').doc(widget.userId).update({
      'containers': FieldValue.arrayRemove([containerId]),
    });
  }

  // New method to show the confirmation dialog before deleting
  Future<void> _confirmAndDeleteContainer(String containerId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this container "$containerId"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteContainer(containerId);
                if (mounted) {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  setState(() {}); // Refresh the UI to reflect the deletion
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red color for delete action
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showAddContainerDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _showAddContainerDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Container'),
          content: TextField(
            controller: _containerIdController,
            decoration: const InputDecoration(
              hintText: 'Enter Container ID',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _containerIdController.clear();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () async {
                if (_containerIdController.text.isNotEmpty) {
                  await _saveContainer(_containerIdController.text);
                  _containerIdController.clear();
                  if (mounted) {
                    Navigator.of(context).pop();
                    setState(() {}); // Refresh UI
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _containerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GrainGuard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50), // Green app bar
        elevation: 4.0, // Add a subtle shadow
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notification icon tap
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Containers',
              style: TextStyle(
                fontSize: 26, // Slightly larger
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333), // Darker grey
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    _firestore.collection('users').doc(widget.userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading containers'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final containers = List<String>.from(
                    (snapshot.data?.data() as Map<String, dynamic>?)?['containers'] ??
                        [],
                  );

                  if (containers.isEmpty) {
                    return const Center(child: Text('No containers added yet'));
                  }

                  return ListView.builder(
                    itemCount: containers.length,
                    itemBuilder: (context, index) {
                      final containerId = containers[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                containerId,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmAndDeleteContainer(containerId), // Call new confirmation method
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ContainerScreen(containerName: containerId),
                                ),
                              );
                            },
                            child: Container(
                              height: 140, // Slightly smaller height
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3), // More prominent shadow
                                    spreadRadius: 3,
                                    blurRadius: 7,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/jarcup.png',
                                      width: 90, // Slightly larger image
                                      height: 90,
                                      fit: BoxFit.contain, // Ensure image scales correctly
                                      colorBlendMode: BlendMode.srcATop, // Apply blend mode
                                      color: const Color(0xFF4CAF50).withOpacity(0.7), // Green tint
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey); // Larger error icon
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Center(
              child: Container(
                width: double.infinity, // Make the button full width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), // More rounded, pill shape
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.9),
                      const Color(0xFF8BC34A).withOpacity(0.9)
                    ], // Subtle green gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _showAddContainerDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // Transparent to show gradient
                    foregroundColor: Colors.white,
                    elevation: 0, // No shadow for the button itself
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Increased padding
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 28), // Larger icon
                  label: const Text(
                    'Add More Containers',
                    style: TextStyle(
                      fontSize: 18, // Larger text
                      fontWeight: FontWeight.w600, // Slightly bolder
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28), // Slightly larger icon
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, size: 28), // Slightly larger icon
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 28), // Slightly larger icon
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8, // More prominent shadow
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold selected label
      ),
    );
  }
}