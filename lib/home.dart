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
        title: const Text('GrainGuard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(widget.userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading containers'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final containers = List<String>.from(
                    (snapshot.data?.data() as Map<String, dynamic>?)?['containers'] ?? []
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
                                onPressed: () async {
                                  await _deleteContainer(containerId);
                                },
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
                              height: 150,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/jarcup.png',
                                      width: 80,
                                      height: 80,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported, size: 50);
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
              child: ElevatedButton.icon(
                onPressed: _showAddContainerDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                  foregroundColor: const Color(0xFF4CAF50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 24),
                label: const Text(
                  'Add more containers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}