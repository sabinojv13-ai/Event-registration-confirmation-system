import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MinistryDashboard extends StatefulWidget {
  const MinistryDashboard({super.key});

  @override
  State<MinistryDashboard> createState() => _MinistryDashboardState();
}

class _MinistryDashboardState extends State<MinistryDashboard> {
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api';

  final List<String> ministries = [
    'Choir',
    'Lectors',
    'Commentators',
    'Altar Servers',
  ];

  String selectedRole = 'Choir';
  List<Map<String, dynamic>> activities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/activities'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! List) {
        throw Exception('The server returned an unexpected response.');
      }

      final loadedActivities = (decoded['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        activities = loadedActivities;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Could not load activities. Make sure the Laravel server '
            'is running at http://127.0.0.1:8000.\n\n$error';
      });
    }
  }

  List<Map<String, dynamic>> get filteredActivities {
    return activities.where((activity) {
      return activity['ministry_role'] == selectedRole;
    }).toList();
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String formatDate(dynamic value) {
    final date = parseDate(value);

    if (date == null) return 'Schedule unavailable';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, ${date.year} '
        'at $hour:$minute $period';
  }

  int availablePlaces(Map<String, dynamic> activity) {
    final capacity = int.tryParse('${activity['capacity']}') ?? 0;
    final confirmed =
        int.tryParse('${activity['confirmed_count']}') ?? 0;

    return (capacity - confirmed).clamp(0, capacity);
  }

  void showActivityDetails(Map<String, dynamic> activity) {
    final capacity = int.tryParse('${activity['capacity']}') ?? 0;
    final confirmed =
        int.tryParse('${activity['confirmed_count']}') ?? 0;
    final available = availablePlaces(activity);

    final isOpen =
        activity['status']?.toString().toLowerCase() == 'open';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            activity['title']?.toString() ?? 'Ministry Activity',
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity['description']?.toString() ??
                      'No description available.',
                ),
                const SizedBox(height: 20),
                _detailRow(
                  Icons.calendar_month,
                  formatDate(activity['starts_at']),
                ),
                _detailRow(
                  Icons.groups,
                  'Ministry: ${activity['ministry_role'] ?? 'Not specified'}',
                ),
                _detailRow(
                  Icons.people_outline,
                  '$confirmed / $capacity confirmed',
                ),
                _detailRow(
                  Icons.event_available,
                  '$available places available',
                ),
                _detailRow(
                  Icons.info_outline,
                  'Status: ${activity['status'] ?? 'Unknown'}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: isOpen
                  ? () {
                      Navigator.pop(dialogContext);
                      showRegistrationForm(activity);
                    }
                  : null,
              icon: const Icon(Icons.app_registration),
              label: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showRegistrationForm(
    Map<String, dynamic> activity,
  ) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    final activityRole = activity['ministry_role']?.toString();
    String registrationRole = ministries.contains(activityRole)
        ? activityRole!
        : selectedRole;

    bool isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContentContext, setDialogState) {
              return AlertDialog(
                title: Text(
                  'Register for ${activity['title'] ?? 'Activity'}',
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: registrationRole,
                          decoration: const InputDecoration(
                            labelText: 'Ministry Role',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.church_outlined),
                          ),
                          items: ministries.map((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: isSubmitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      registrationRole = value;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final email = emailController.text.trim();

                            final emailPattern = RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            );

                            if (name.isEmpty || email.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter your full name and email address.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (!emailPattern.hasMatch(email)) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a valid email address.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              final activityId = activity['id'];

                              final response = await http
                                  .post(
                                    Uri.parse(
                                      '$apiBaseUrl/activities/'
                                      '$activityId/registrations',
                                    ),
                                    headers: const {
                                      'Accept': 'application/json',
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'member_name': name,
                                      'member_email': email,
                                      'ministry_role': registrationRole,
                                    }),
                                  )
                                  .timeout(
                                    const Duration(seconds: 20),
                                  );

                              Map<String, dynamic> result = {};

                              try {
                                final decoded = jsonDecode(response.body);

                                if (decoded is Map) {
                                  result = Map<String, dynamic>.from(
                                    decoded,
                                  );
                                }
                              } catch (_) {
                                // Handle a non-JSON response below.
                              }

                              if (!mounted || !dialogContext.mounted) {
                                return;
                              }

                              if (response.statusCode == 201 &&
                                  result['success'] == true) {
                                dynamic registrationData = result['data'];

                                if (registrationData is Map &&
                                    registrationData['registration'] is Map) {
                                  registrationData =
                                      registrationData['registration'];
                                }

                                final registrationStatus =
                                    registrationData is Map
                                        ? registrationData['status']
                                            ?.toString()
                                        : null;

                                final message = registrationStatus == 'waitlisted'
                                    ? 'Registration received. You have been placed on the waiting list.'
                                    : registrationStatus == 'confirmed'
                                        ? 'Registration successful! Your place is confirmed.'
                                        : 'Registration submitted successfully.';

                                // Capture the dashboard messenger before closing the dialog.
                                final messenger = ScaffoldMessenger.of(context);

                                Navigator.pop(dialogContext);

                                if (!mounted) return;

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    duration: const Duration(seconds: 5),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );

                                await fetchActivities();
                              } else {
                                final errors = result['errors'];

                                String message =
                                    result['message']?.toString() ??
                                        'Registration failed. Please try again.';

                                if (errors is Map && errors.isNotEmpty) {
                                  final firstErrors = errors.values.first;

                                  if (firstErrors is List &&
                                      firstErrors.isNotEmpty) {
                                    message = firstErrors.first.toString();
                                  }
                                }

                                if (!dialogContext.mounted) return;

                                setDialogState(() {
                                  isSubmitting = false;
                                });

                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (!mounted || !dialogContext.mounted) {
                                return;
                              }

                              setDialogState(() {
                                isSubmitting = false;
                              });

                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not connect to the Laravel server. '
                                    'Make sure it is running and try again.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit Registration'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
    }
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF345B45),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget buildActivityCard(Map<String, dynamic> activity) {
    final title =
        activity['title']?.toString() ?? 'Ministry Activity';
    final description =
        activity['description']?.toString() ?? 'No description available.';
    final role =
        activity['ministry_role']?.toString() ?? 'Not specified';
    final status =
        activity['status']?.toString() ?? 'unknown';
    final capacity = int.tryParse('${activity['capacity']}') ?? 0;
    final confirmed =
        int.tryParse('${activity['confirmed_count']}') ?? 0;
    final available = availablePlaces(activity);

    final isOpen = status.toLowerCase() == 'open';
    final progress = capacity > 0
        ? (confirmed / capacity).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Card(
      elevation: 2,
      color: const Color(0xFFF0F5EE),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE2EDE4),
                  child: Icon(
                    Icons.calendar_month,
                    color: Color(0xFF345B45),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => showActivityDetails(activity),
                  child: Text(status.toUpperCase()),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _detailRow(
              Icons.calendar_month,
              formatDate(activity['starts_at']),
            ),
            _detailRow(
              Icons.groups,
              'Ministry: $role',
            ),
            _detailRow(
              Icons.people_outline,
              '$confirmed / $capacity confirmed',
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFDDE5DC),
                color: const Color(0xFF345B45),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$available places available',
              style: TextStyle(
                color: available == 0
                    ? Colors.grey.shade700
                    : const Color(0xFF345B45),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => showActivityDetails(activity),
                icon: const Icon(Icons.info_outline),
                label: const Text('View details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF345B45),
                  side: const BorderSide(
                    color: Color(0xFF7A8B7E),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            if (!isOpen)
              const Text(
                'This activity is not currently open.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liturgical Ministry'),
        actions: [
          IconButton(
            tooltip: 'Refresh activities',
            onPressed: isLoading ? null : fetchActivities,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Welcome to the Liturgical Ministry System',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF345B45),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'View parish activities and find opportunities to serve '
                'in your ministry.',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 28),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Select your ministry',
                  prefixIcon: Icon(Icons.church),
                  border: OutlineInputBorder(),
                ),
                items: ministries.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Upcoming Activities',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text('${filteredActivities.length} activities'),
                ],
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 42,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: fetchActivities,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredActivities.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No activities are available for this ministry.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                ...filteredActivities.map(buildActivityCard),
            ],
          ),
        ),
      ),
    );
  }
}