import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService userService = UserService();

  List<User> users = [];
  List<User> filteredUsers = [];

  bool isLoading = true;
  String? errorMessage;

  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final data = await userService.getUsers();

      setState(() {
        users = data;
        filteredUsers = data;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('ERROR loading users: $e');
      print(stackTrace);

      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }
  
  void searchUsers(String keyword) {
    final query = keyword.toLowerCase();

    setState(() {
      filteredUsers = users.where((user) {
        return user.username
            .toLowerCase()
            .contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.fullName ?? '')
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${filteredUsers.length} users',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: searchController,
            onChanged: searchUsers,
            decoration: InputDecoration(
              hintText: 'Search username, name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: buildContent(),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      );
    }

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy user'),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Active')),
              DataColumn(label: Text('Actions')),
            ],
            rows: filteredUsers.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user.id.toString())),

                  DataCell(
                    Text(user.username),
                  ),

                  DataCell(
                    Text(
                      user.fullName ??
                          '${user.firstName} ${user.lastName}',
                    ),
                  ),

                  DataCell(
                    Text(user.email),
                  ),

                  DataCell(
                    Text(user.roleName ?? 'N/A'),
                  ),

                  DataCell(
                    Text(user.status),
                  ),

                  DataCell(
                    Icon(
                      user.isActive
                          ? Icons.check_circle
                          : Icons.cancel,
                    ),
                  ),

                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            showUserDetail(user);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void showUserDetail(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user.username),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${user.id}'),
              Text('Name: ${user.fullName ?? ''}'),
              Text('Email: ${user.email}'),
              Text('Role: ${user.roleName ?? 'N/A'}'),
              Text('Status: ${user.status}'),
              Text(
                'Active: ${user.isActive ? 'Yes' : 'No'}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}