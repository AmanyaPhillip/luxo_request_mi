import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _unitController;

  late String _selectedTitle;
  late String _selectedProject;
  late Language _selectedLanguage;
  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;

    _firstNameController = TextEditingController(text: userData?.firstName ?? '');
    _lastNameController = TextEditingController(text: userData?.lastName ?? '');
    _phoneController = TextEditingController(text: userData?.phone ?? '');
    _emailController = TextEditingController(text: userData?.email ?? '');
    _unitController = TextEditingController(text: userData?.unit ?? '');

    _selectedTitle = userData?.title ?? Constants.titles.first;
    _selectedProject = userData?.realEstateProject ?? Constants.realEstateProjects.first;
    _selectedLanguage = Constants.languages.firstWhere(
      (lang) => lang.name == (userData?.language ?? 'English'),
      orElse: () => Constants.languages.first,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userData = UserData(
      title: _selectedTitle,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      realEstateProject: _selectedProject,
      unit: _unitController.text.trim(),
      language: _selectedLanguage.name,
    );

    try {
      await Provider.of<UserProvider>(context, listen: false).updateUserData(userData);
      
      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settings: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _initializeControllers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _isLoading ? null : _cancelEditing,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ],
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.userData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              '${userProvider.userData!.firstName[0]}${userProvider.userData!.lastName[0]}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProvider.getFullName(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userProvider.userData!.realEstateProject,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Unit ${userProvider.userData!.unit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Personal Information Section
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Title
                          DropdownButtonFormField<String>(
                            value: _selectedTitle,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                            items: Constants.titles.map((title) {
                              return DropdownMenuItem(value: title, child: Text(title));
                            }).toList(),
                            onChanged: _isEditing ? (value) {
                              setState(() {
                                _selectedTitle = value!;
                              });
                            } : null,
                          ),
                          const SizedBox(height: 16),

                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Last Name
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Property Information Section
                  Text(
                    'Property Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Real Estate Project - Fixed dropdown with explicit icon
                          DropdownButtonFormField<String>(
                            value: _selectedProject,
                            decoration: const InputDecoration(
                              labelText: 'Real Estate Project',
                              prefixIcon: Icon(Icons.business),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: _isEditing 
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).disabledColor,
                            ),
                            isExpanded: true,
                            items: Constants.realEstateProjects.map((project) {
                              return DropdownMenuItem(
                                value: project,
                                child: Text(
                                  project,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _isEditing ? (value) {
                              setState(() {
                                _selectedProject = value!;
                              });
                            } : null,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a real estate project';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Unit
                          TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              prefixIcon: Icon(Icons.home),
                            ),
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your unit number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Preferences Section
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Language',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...Constants.languages.map(
                            (language) => RadioListTile<Language>(
                              title: Text(language.nativeName),
                              value: language,
                              groupValue: _selectedLanguage,
                              onChanged: _isEditing ? (value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                });
                              } : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Debug Actions (can be removed in production)
                  if (_isEditing) ...[
                    Card(
                      color: Colors.red.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Debug Actions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Reset App'),
                                      content: const Text(
                                        'This will clear all user data and return to setup screen. Are you sure?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await userProvider.clearUserData();
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                              // The app will automatically navigate to setup
                                            }
                                          },
                                          child: const Text(
                                            'Reset',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh, color: Colors.red),
                                label: const Text(
                                  'Reset App to Setup',
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}