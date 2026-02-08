import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/pet/pet_bloc.dart';
import '../../blocs/report/report_bloc.dart';
import '../../models/app_user.dart';
import '../../models/pet.dart';
import '../../models/booking.dart';
import '../../widgets/primary_button.dart';
import 'clinic_dashboard_screen.dart';
import 'sitter_dashboard_screen.dart';

class ReportDashboardScreen extends StatelessWidget {
  const ReportDashboardScreen({super.key});

  static const routeName = '/reports';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();

    if (user.role == UserRole.vet) {
      return const ClinicDashboardScreen();
    } else if (user.role == UserRole.sitter) {
      return const SitterDashboardScreen();
    } else {
      return const _PetHealthReport();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetHealthReport extends StatefulWidget {
  const _PetHealthReport();

  @override
  State<_PetHealthReport> createState() => _PetHealthReportState();
}

class _PetHealthReportState extends State<_PetHealthReport> {
  String? _selectedPetId;

  void _generateReport() {
    final ownerId = context.read<AuthBloc>().state.user?.id;
    if (ownerId == null || _selectedPetId == null) return;
    context.read<ReportBloc>().add(
      ReportRequested(ownerId: ownerId, petId: _selectedPetId!),
    );
  }

  void _exportReport() {
    context.read<ReportBloc>().add(const ReportExportRequested());
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetBloc>().state.pets;
    _selectedPetId ??= pets.isNotEmpty ? pets.first.id : null;

    Future<String?> saveBytesToDownloads(
      Uint8List bytes,
      String filename,
    ) async {
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          final dir = dirs.first;
          final file = File('${dir.path}/$filename');
          await file.writeAsBytes(bytes);
          return file.path;
        }

        final docDir = await getApplicationDocumentsDirectory();
        final file = File('${docDir.path}/$filename');
        await file.writeAsBytes(bytes);
        return file.path;
      } catch (e) {
        return null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocListener<ReportBloc, ReportState>(
          listenWhen: (previous, current) =>
              previous.exportedBytes != current.exportedBytes ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) async {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
            if (state.exportedBytes != null && !state.isExporting) {
              final bytes = state.exportedBytes!;
              final choice = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Report ready'),
                  content: const Text(
                    'Would you like to share the report or save it to Downloads?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop('share'),
                      child: const Text('Share'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop('save'),
                      child: const Text('Save to Downloads'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );

              if (choice == 'share') {
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'pet-report.pdf',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share dialog opened.')),
                );
              } else if (choice == 'save') {
                try {
                  final docDir = await getApplicationDocumentsDirectory();
                  final localFile = File('${docDir.path}/pet-report.pdf');
                  await localFile.writeAsBytes(bytes);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report saved locally: ${localFile.path}'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Local save failed: ${e.toString()}'),
                    ),
                  );
                }

                try {
                  await FileSaver.instance.saveFile(
                    name: 'pet-report',
                    bytes: bytes,
                    ext: 'pdf',
                    mimeType: MimeType.pdf,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report saved (via FileSaver).'),
                    ),
                  );
                } catch (_) {
                  final savedPath = await saveBytesToDownloads(
                    bytes,
                    'pet-report.pdf',
                  );
                  if (savedPath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Report saved to: $savedPath')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Save failed.')),
                    );
                  }
                }
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedPetId,
                decoration: const InputDecoration(labelText: 'Pet'),
                items: pets
                    .map(
                      (pet) => DropdownMenuItem(
                        value: pet.id,
                        child: Text(pet.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedPetId = value),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Generate report',
                onPressed: _generateReport,
              ),
              const SizedBox(height: 16),

              // Report preview area — appears after generation
              BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  if (state.isLoading)
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  if (state.reportData == null)
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Select a pet to generate detailed health insights.',
                      ),
                    );
                  if (!state.reportData!.containsKey('pet'))
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Invalid report data.'),
                    );

                  final pet = state.reportData!['pet'] as Pet;
                  final bookings =
                      state.reportData!['bookings'] as List<Booking>;
                  final activities = state.reportData!['activities'] as List;

                  final cards = [
                    _StatCard(
                      title: 'Total Appointments',
                      value: bookings.length.toString(),
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Upcoming',
                      value: bookings
                          .where((b) => b.date.isAfter(DateTime.now()))
                          .length
                          .toString(),
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Activity Logs',
                      value: activities.length.toString(),
                      icon: Icons.list_alt,
                      color: Colors.green,
                    ),
                  ];

                  return Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pet: ${pet.name}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('Species: ${pet.species}'),
                          const SizedBox(height: 12),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 640;
                              final crossAxisCount = isWide ? 3 : 1;
                              final cardHeight = 120.0;
                              final childAspectRatio = isWide
                                  ? (constraints.maxWidth / crossAxisCount) /
                                        cardHeight
                                  : constraints.maxWidth / cardHeight;
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                children: cards,
                              );
                            },
                          ),

                          const SizedBox(height: 16),
                          Text(
                            'Recent Appointments',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...bookings
                              .take(5)
                              .map(
                                (b) => Card(
                                  child: ListTile(
                                    title: Text(
                                      b.petName.isNotEmpty
                                          ? b.petName
                                          : pet.name,
                                    ),
                                    subtitle: Text(
                                      '${b.date.toLocal()} • ${b.status.name}',
                                    ),
                                    trailing: Text(b.time ?? ''),
                                  ),
                                ),
                              ),

                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Export as PDF',
                            isLoading: state.isExporting,
                            onPressed: _exportReport,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
