// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchAccountPage extends StatefulWidget {
  const SearchAccountPage({super.key});

  @override
  State<SearchAccountPage> createState() => _SearchAccountPageState();
}

class _SearchAccountPageState extends State<SearchAccountPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isLoading = false;
  bool _isInitialLoading = true;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allUsers = [];
  String _selectedUserType = "All"; // Default to All
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
    _subscription = FirebaseFirestore.instance
        .collection('user_contact')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          // Update your state here when new data comes in
          _loadAllUsers(); // Or a more efficient update method
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  // Load all users when the page initializes
  Future<void> _loadAllUsers() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
    });

    try {
      // Get all users
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      print('Fetched ${querySnapshot.docs.length} users');

      // Convert to list of maps with id included
      final users = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Store user ID in multiple formats to ensure we can match later
        return {
          'id': doc.id,
          'uid': doc.id, // Alternative form
          'userId': doc.id, // Another alternative
          ...data,
        };
      }).toList();

      // Get contact info for all users
      final contactInfoMap = await _fetchContactInfo(users);

      // Now also try to directly get the user_contact collection by doc ID
      final additionalContacts = await _fetchAdditionalContacts();

      // Merge contact info with user data
      final usersWithContact = users.map((user) {
        // Try to find contact info by userId field first
        String? userId = user['userId'] as String?;

        // If no contact found, try finding by document ID
        Map<String, dynamic>? contactInfo =
            userId != null ? contactInfoMap[userId] : null;

        // If still no contact, try with the document ID
        if (contactInfo == null) {
          final docId = user['id'] as String?;
          if (docId != null) {
            contactInfo = additionalContacts[docId];
          }
        }

        return {
          ...user,
          'contactNumber': contactInfo?['contactNumber'] ?? 'Not available',
          'contactName': contactInfo?['contactName'] ?? 'Not available',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _allUsers = usersWithContact;
        _searchResults = usersWithContact;
        _isInitialLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');

      if (!mounted) return;

      setState(() {
        _allUsers = [];
        _searchResults = [];
        _isInitialLoading = false;
      });
    }
  }

  // Additional method to fetch contacts by document ID
  Future<Map<String, Map<String, dynamic>>> _fetchAdditionalContacts() async {
    final Map<String, Map<String, dynamic>> contactsMap = {};

    try {
      // See if any contacts are stored with the same ID as the user document
      final QuerySnapshot contactsSnapshot =
          await FirebaseFirestore.instance.collection('user_contact').get();

      for (final doc in contactsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Store contact by document ID (in case user_contact documents match user IDs)
        contactsMap[doc.id] = {
          'contactNumber': data['contactNumber'] ??
              data['contactnumber'] ??
              data['contact_number'] ??
              data['contact'] ??
              'Unknown',
          'contactName': data['contactName'] ??
              data['contactname'] ??
              data['contact_name'] ??
              data['name'] ??
              'Unknown',
        };
      }
    } catch (e) {
      print('Error fetching additional contact information: $e');
    }

    return contactsMap;
  }

  // Fetch contact information for multiple users efficiently
  Future<Map<String, Map<String, dynamic>>> _fetchContactInfo(
      List<Map<String, dynamic>> users) async {
    final Map<String, Map<String, dynamic>> contactsMap = {};

    try {
      // Get all contacts at once
      final QuerySnapshot contactsSnapshot =
          await FirebaseFirestore.instance.collection('user_contact').get();

      print('Fetched ${contactsSnapshot.docs.length} contacts from Firestore');

      // Process and organize by userId
      for (final doc in contactsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Print the entire document for debugging
        print('Contact data: ${data.toString()}');

        // Check different possible field names for userId
        final String? userId = data['userId'] as String? ??
            data['uid'] as String? ??
            data['user_id'] as String?;

        if (userId != null) {
          // Get contact info, check different possible field names
          final contactNumber = data['contactNumber'] as String? ??
              data['contactnumber'] as String? ??
              data['contact_number'] as String? ??
              data['contact'] as String?;

          final contactName = data['contactName'] as String? ??
              data['contactname'] as String? ??
              data['contact_name'] as String? ??
              data['name'] as String?;

          contactsMap[userId] = {
            'contactNumber': contactNumber ?? 'Unknown',
            'contactName': contactName ?? 'Unknown',
          };

          print('Mapped contact for userId: $userId');
        } else {
          print('No userId found in contact document: ${doc.id}');
        }
      }

      print('Processed ${contactsMap.length} contacts with valid userIds');
    } catch (e) {
      print('Error fetching contact information: $e');
    }

    return contactsMap;
  }

  Future<void> _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final searchLower = _searchQuery.toLowerCase().trim();

      // Filter the already loaded users
      final results = _allUsers.where((user) {
        if (searchLower.isEmpty) return true; // Show all when no search

        // Filter by user type first
        if (_selectedUserType != "All" &&
            user['userType'] != _selectedUserType) {
          return false;
        }

        // Then by search query
        final String name = (user['fullName'] ?? '').toString().toLowerCase();
        final String email = (user['email'] ?? '').toString().toLowerCase();
        final String idNumber =
            (user['idNumber'] ?? '').toString().toLowerCase();
        final String contactNumber =
            (user['contactNumber'] ?? '').toString().toLowerCase();

        return name.contains(searchLower) ||
            email.contains(searchLower) ||
            idNumber.contains(searchLower) ||
            contactNumber.contains(searchLower);
      }).toList();

      if (!mounted) return;

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error performing search: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.manage_search_rounded,
                        color: Colors.blue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Search Accounts',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    return constraints.maxWidth < 600
                        ? Column(
                            children: [
                              _buildStatCard(
                                'Total Users',
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.hasData
                                          ? '${snapshot.data?.docs.length ?? 0}'
                                          : 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    );
                                  },
                                ),
                                Icons.people,
                                const Color(0xFF4285F4),
                              ),
                              const SizedBox(height: 16),
                              _buildStatCard(
                                'Students',
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('userType', isEqualTo: 'Student')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.hasData
                                          ? '${snapshot.data?.docs.length ?? 0}'
                                          : 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    );
                                  },
                                ),
                                Icons.school,
                                const Color(0xFFFF9800),
                              ),
                              const SizedBox(height: 16),
                              _buildStatCard(
                                'Faculty & Staff',
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('userType',
                                          isEqualTo: 'Faculty & Staff')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.hasData
                                          ? '${snapshot.data?.docs.length ?? 0}'
                                          : 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    );
                                  },
                                ),
                                Icons.work,
                                const Color(0xFF0F9D58),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Users',
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.hasData
                                            ? '${snapshot.data?.docs.length ?? 0}'
                                            : 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      );
                                    },
                                  ),
                                  Icons.people,
                                  const Color(0xFF4285F4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Students',
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .where('userType', isEqualTo: 'Student')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.hasData
                                            ? '${snapshot.data?.docs.length ?? 0}'
                                            : 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      );
                                    },
                                  ),
                                  Icons.school,
                                  const Color(0xFFFF9800),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Faculty & Staff',
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .where('userType',
                                            isEqualTo: 'Faculty & Staff')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.hasData
                                            ? '${snapshot.data?.docs.length ?? 0}'
                                            : 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      );
                                    },
                                  ),
                                  Icons.work,
                                  const Color(0xFF0F9D58),
                                ),
                              ),
                            ],
                          );
                  },
                ),

                const SizedBox(height: 24),

                // Find User Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: Colors.blue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Find User',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(builder: (context, constraints) {
                          return constraints.maxWidth < 700
                              ? Column(
                                  children: [
                                    TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search by name, email, ID or contact...',
                                        hintStyle: TextStyle(
                                            color: Colors.grey.shade500),
                                        prefixIcon: Icon(Icons.search,
                                            color: Colors.blue.shade400),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade400,
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.blue.shade50
                                            .withOpacity(0.3),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
                                      onSubmitted: (_) => _performSearch(),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: _selectedUserType,
                                      decoration: InputDecoration(
                                        labelText: 'User Type',
                                        labelStyle: TextStyle(
                                            color: Colors.blue.shade700),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade400,
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.blue.shade50
                                            .withOpacity(0.3),
                                        prefixIcon: Icon(
                                            Icons.people_alt_outlined,
                                            color: Colors.blue.shade400),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 0),
                                      ),
                                      dropdownColor: Colors.white,
                                      style: TextStyle(
                                          color: Colors.blueGrey.shade800,
                                          fontSize: 16),
                                      items: [
                                        'All',
                                        'Student',
                                        'Faculty & Staff'
                                      ].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        setState(() {
                                          _selectedUserType = newValue!;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isLoading ? null : _performSearch,
                                        icon: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.search),
                                        label: const Text('Search'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 20,
                                          ),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Search by name, email, ID or contact...',
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500),
                                          prefixIcon: Icon(Icons.search,
                                              color: Colors.blue.shade400),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.blue.shade200),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.blue.shade200),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.blue.shade400,
                                                width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.blue.shade50
                                              .withOpacity(0.3),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                        onSubmitted: (_) => _performSearch(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedUserType,
                                        decoration: InputDecoration(
                                          labelText: 'User Type',
                                          labelStyle: TextStyle(
                                              color: Colors.blue.shade700),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.blue.shade200),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.blue.shade200),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.blue.shade400,
                                                width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.blue.shade50
                                              .withOpacity(0.3),
                                          prefixIcon: Icon(
                                              Icons.people_alt_outlined,
                                              color: Colors.blue.shade400),
                                        ),
                                        dropdownColor: Colors.white,
                                        style: TextStyle(
                                            color: Colors.blueGrey.shade800,
                                            fontSize: 16),
                                        items: [
                                          'All',
                                          'Student',
                                          'Faculty & Staff'
                                        ].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          setState(() {
                                            _selectedUserType = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed:
                                          _isLoading ? null : _performSearch,
                                      icon: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.search),
                                      label: const Text('Search'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Search Results Card
                Container(
                  height: 500, // Made taller
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.list_alt,
                                    size: 24, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Text(
                                  'Users Directory',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Text(
                                '${_searchResults.length} users',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildSearchResultsView(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsView() {
    if (_isInitialLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Loading users...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                _searchQuery.isEmpty
                    ? Icons.person_search_outlined
                    : Icons.search_off,
                size: 64,
                color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No users found in the system'
                  : 'No results found matching "$_searchQuery"${_selectedUserType != "All" ? " for $_selectedUserType" : ""}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool useCards = constraints.maxWidth < 600;
        return ListView.separated(
          itemCount: _searchResults.length,
          separatorBuilder: (context, index) => useCards
              ? const SizedBox.shrink()
              : const Divider(height: 1, thickness: 1),
          itemBuilder: (context, index) {
            final user = _searchResults[index];
            return useCards
                ? _buildCompactUserCard(user)
                : _buildWideUserRow(user);
          },
        );
      },
    );
  }

  Widget _buildCompactUserCard(Map<String, dynamic> user) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    user['userType'] == 'Student' ? Icons.school : Icons.work,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user['fullName'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildUserTypeChip(user['userType'] ?? 'Unknown'),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('ID: ${user['idNumber'] ?? 'N/A'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Email: ${user['email'] ?? 'N/A'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Contact: ${user['contactNumber'] ?? 'N/A'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
                onPressed: () {
                  _showUserDetails(user);
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideUserRow(Map<String, dynamic> user) {
    return InkWell(
      onTap: () => _showUserDetails(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(Icons.badge, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(user['idNumber'] ?? 'N/A'),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(user['fullName'] ?? 'N/A'),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(user['contactNumber'] ?? 'N/A'),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildUserTypeChip(user['userType'] ?? 'Unknown'),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, Widget valueWidget, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          valueWidget,
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeChip(String userType) {
    Color chipColor;
    IconData icon;

    switch (userType) {
      case 'Student':
        chipColor = const Color(0xFFFF9800);
        icon = Icons.school;
        break;
      case 'Faculty & Staff':
        chipColor = const Color(0xFF0F9D58);
        icon = Icons.work;
        break;
      default:
        chipColor = Colors.grey;
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            userType,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper function to get user profile image URL
  Future<String?> _getUserProfileImage(String? userId) async {
    if (userId == null || userId.isEmpty) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          return userData['profileImage'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user profile image: $e');
      return null;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                user['userType'] == 'Student' ? Icons.school : Icons.work,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              const Text('User Details'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Center(
                    child: FutureBuilder<String?>(
                      future: _getUserProfileImage(user['id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          );
                        }

                        final imageUrl = snapshot.data;

                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(imageUrl),
                                backgroundColor: Colors.grey.shade200,
                                onBackgroundImageError: (_, __) {
                                  // Handle image loading error silently
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user['fullName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        }

                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            user['userType'] == 'Student'
                                ? Icons.school
                                : Icons.work,
                            size: 50,
                            color: Colors.blue.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                      Icons.badge, 'ID Number', user['idNumber'] ?? 'N/A'),
                  _buildDetailRow(
                      Icons.person, 'Name', user['fullName'] ?? 'N/A'),
                  _buildDetailRow(Icons.email, 'Email', user['email'] ?? 'N/A'),
                  _buildDetailRow(Icons.people_alt_outlined, 'User Type',
                      user['userType'] ?? 'N/A'),
                  _buildDetailRow(Icons.phone, 'Phone', user['phone'] ?? 'N/A'),
                  const Divider(height: 24),

                  // Emergency contact section
                  Row(
                    children: [
                      Icon(Icons.contact_emergency,
                          size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.person_outline, 'Contact Name',
                      user['contactName'] ?? 'N/A'),
                  _buildDetailRow(Icons.phone_enabled, 'Contact Number',
                      user['contactNumber'] ?? 'N/A'),

                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.verified_user,
                          size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Account Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(user['status'] ?? 'Active'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        chipColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'inactive':
        chipColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
