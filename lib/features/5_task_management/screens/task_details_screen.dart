import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/5_task_management/providers/task_data_provider.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/models/task_model.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rescuetn/core/services/storage_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final Task? initialTask;
  const TaskDetailsScreen({super.key, this.initialTask});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }



  List<Color> _getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'active':
      case 'inprogress':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'completed':
        return [Colors.green.shade400, Colors.green.shade600];
      default:
        return [AppColors.textSecondary, AppColors.textSecondary];
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'high':
        return Colors.red.shade600;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'active':
      case 'inprogress':
        return Icons.work_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.hourglass_empty;
    }
  }

  void _showStatusUpdateDialog() {
    final task = ref.read(selectedTaskProvider).value;
    if (task == null) return;

    // Capture the outer context for navigation
    final outerContext = context;

    // Local state for the modal
    File? selectedImage;
    File? selectedAudio;
    bool isUploading = false;
    bool isRecording = false;
    TaskStatus? selectedStatus;
    final audioRecorder = AudioRecorder();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.accent.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.update_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "tasks.updateStatus".tr(context),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isUploading) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text("tasks.uploadProof".tr(context)),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Status Options based on current task status
                    
                    // For PENDING tasks: Show Accept Task and Start Working options
                    if (task.status == TaskStatus.pending) ...[
                      _buildEnhancedStatusOption(
                        TaskStatus.accepted,
                        [Colors.teal.shade400, Colors.teal.shade600],
                        Icons.thumb_up_rounded,
                        onTap: () {
                          Navigator.pop(context);
                          _updateStatus(TaskStatus.accepted);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildEnhancedStatusOption(
                        TaskStatus.inProgress,
                        [Colors.blue.shade400, Colors.blue.shade600],
                        Icons.work_rounded,
                        onTap: () {
                          Navigator.pop(context);
                          _updateStatus(TaskStatus.inProgress);
                        },
                      ),
                    ],

                    // For ACCEPTED tasks: Show Start Working and Mark Completed options
                    if (task.status == TaskStatus.accepted) ...[
                      _buildEnhancedStatusOption(
                        TaskStatus.inProgress,
                        [Colors.blue.shade400, Colors.blue.shade600],
                        Icons.work_rounded,
                        onTap: () {
                          Navigator.pop(context);
                          _updateStatus(TaskStatus.inProgress);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildEnhancedStatusOption(
                        TaskStatus.completed,
                        [Colors.green.shade400, Colors.green.shade600],
                        Icons.check_circle_rounded,
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet
                          outerContext.push('/task-complete/${task.id}', extra: task);
                        },
                      ),
                    ],

                    // For IN_PROGRESS tasks: Show Mark Completed option
                    if (task.status == TaskStatus.inProgress) ...[
                      _buildEnhancedStatusOption(
                        TaskStatus.completed,
                        [Colors.green.shade400, Colors.green.shade600],
                        Icons.check_circle_rounded,
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet
                          outerContext.push('/task-complete/${task.id}', extra: task);
                        },
                      ),
                    ],

                    // Completion Flow with Image Upload
                    if (selectedStatus == TaskStatus.completed) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "tasks.proofTitle".tr(context),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setModalState(() => selectedStatus = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "tasks.uploadInstruction".tr(context),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (selectedImage != null)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImage!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => selectedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              InkWell(
                                onTap: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    setModalState(() => selectedImage = File(image.path));
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        "tasks.selectPhoto".tr(context),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),
                            
                            // Audio Recording Section
                            Text(
                              "Audio Recording (Optional)",
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (selectedAudio != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.audiotrack, color: Colors.green.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Audio recorded",
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => setModalState(() => selectedAudio = null),
                                    ),
                                  ],
                                ),
                              )
                            else
                              InkWell(
                                onTap: () async {
                                  if (isRecording) {
                                    // Stop recording
                                    final path = await audioRecorder.stop();
                                    setModalState(() => isRecording = false);
                                    if (path != null) {
                                      setModalState(() => selectedAudio = File(path));
                                    }
                                  } else {
                                    // Start recording
                                    if (await audioRecorder.hasPermission()) {
                                      final dir = await getTemporaryDirectory();
                                      final path = '${dir.path}/task_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
                                      await audioRecorder.start(const RecordConfig(), path: path);
                                      setModalState(() => isRecording = true);
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: isRecording ? Colors.red.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isRecording ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isRecording ? Icons.stop : Icons.mic,
                                        color: isRecording ? Colors.red : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isRecording ? "Stop Recording" : "Record Audio",
                                        style: TextStyle(
                                          color: isRecording ? Colors.red : Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: selectedImage == null
                                  ? null
                                  : () async {
                                setModalState(() => isUploading = true);
                                try {
                                  final storageService = ref.read(storageServiceProvider);
                                  
                                  // Upload image
                                  final imageUrl = await storageService.uploadTaskCompletionImage(
                                    task.id,
                                    selectedImage!,
                                  );

                                  // Upload audio if present
                                  String? audioUrl;
                                  if (selectedAudio != null) {
                                    audioUrl = await storageService.uploadTaskCompletionAudio(
                                      task.id,
                                      selectedAudio!,
                                    );
                                  }

                                  // Dispose recorder
                                  await audioRecorder.dispose();

                                  if (context.mounted) {
                                    // Close modal first
                                    Navigator.pop(context);
                                    
                                    // Then update status
                                    await _updateStatus(
                                      TaskStatus.completed,
                                      completionImageUrl: imageUrl,
                                      completionAudioUrl: audioUrl,
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isUploading = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${"tasks.errorUpdating".tr(context)}: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                "tasks.submitCompletion".tr(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(TaskStatus status, {String? completionImageUrl, String? completionAudioUrl}) async {
    final currentTask = ref.read(selectedTaskProvider).value ?? widget.initialTask;
    if (currentTask != null) {
      try {
        await ref
            .read(databaseServiceProvider)
            .updateTaskStatus(currentTask.id, status, completionImageUrl: completionImageUrl, completionAudioUrl: completionAudioUrl);
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('${"tasks.statusUpdated".tr(context)} ${status.name}'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${"tasks.errorUpdating".tr(context)}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildEnhancedStatusOption(
      TaskStatus status,
      List<Color> gradient,
      IconData icon,
      {VoidCallback? onTap}
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient[0].withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "taskFilters.${status.name}".tr(context).toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: gradient[1],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: gradient[0].withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(selectedTaskProvider);
    final volunteerAsync = ref.watch(volunteerDetailsProvider);
    final textTheme = Theme.of(context).textTheme;

    // Use initialTask to show immediate content while loading or if error occurs (and we have initial data)
    final effectiveTaskState = (widget.initialTask != null && (taskAsync.isLoading || taskAsync.hasError || taskAsync.value == null))
        ? AsyncData(widget.initialTask)
        : taskAsync;

    return effectiveTaskState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) {
        final isPermissionError = err.toString().contains('permission-denied');
        return Scaffold(
          appBar: AppBar(title: Text("error".tr(context))),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPermissionError ? Icons.lock_person_rounded : Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPermissionError ? "tasks.accessDenied".tr(context) : "tasks.errorLoading".tr(context),
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPermissionError 
                        ? "tasks.permissionError".tr(context)
                        : '${"tasks.unexpectedError".tr(context)}: $err',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (widget.initialTask != null) 
                     ElevatedButton.icon(
                      onPressed: () {
                         // Force displaying initial task implies ignoring error for now, 
                         // but we are inside 'error' builder which returns a widget.
                         // This path effectively won't be reached because we construct 'effectiveTaskState' above.
                         // But if we decide not to wrap in AsyncData above to verify fresh data, this would be needed.
                         // Since we DO wrap above, this error widget only shows if BOTH provider fails and initialTask is null.
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text("tasks.retry".tr(context)),
                     ),
                  if (isPermissionError)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to profile or trigger logout
                        // Since we can't easily logout here without context loop, advise user
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text("tasks.goToProfile".tr(context))),
                        );
                        context.go('/profile');
                      },
                      icon: const Icon(Icons.logout),
                      label: Text("tasks.goToProfile".tr(context)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      data: (task) {
        // If we wrapped initialTask, 'task' here is actually AsyncData(initialTask).value which is Task?.
        // But invalid tasks might be null.
        if (task == null) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade700,
                    Colors.red.shade600,
                    Colors.red.shade500,
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.15, 0.3, 0.3],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                              onPressed: () {
                                context.go('/home');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "tasks.notFound".tr(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

    final statusGradient = _getStatusGradient(task.status.name);
    final severityColor = _getSeverityColor(task.severity.name);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusGradient[0],
              statusGradient[1],
              statusGradient[1].withValues(alpha: 0.8),
              AppColors.background,
            ],
            stops: const [0.0, 0.15, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Hero(
                      tag: 'back_button',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: () {
                              context.go('/home');
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "tasks.detailsTitle".tr(context),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "tasks.detailsSubtitle".tr(context),
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(task.status.name),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          // Enhanced Title Card
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    statusGradient[0].withValues(alpha: 0.15),
                                    statusGradient[1].withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: statusGradient[0].withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusGradient[0].withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient:
                                          LinearGradient(colors: statusGradient),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusGradient[0]
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _getStatusIcon(task.status.name),
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: textTheme.headlineSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: statusGradient),
                                                borderRadius:
                                                BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: statusGradient[0]
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                task.status.name.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Enhanced Section Header
                          _buildEnhancedSectionHeader(
                            icon: Icons.info_outline_rounded,
                            title: 'Task Information',
                            gradient: [Colors.indigo.shade400, Colors.indigo.shade600],
                          ),
                          const SizedBox(height: 20),

                          // Description Card
                          _buildEnhancedDetailCard(
                            title: 'Description',
                            content: task.description,
                            icon: Icons.description_rounded,
                            gradient: [Colors.blue.shade400, Colors.blue.shade600],
                          ),
                          const SizedBox(height: 16),

                          // Severity Card
                          _buildEnhancedDetailCard(
                            title: 'Severity Level',
                            content: task.severity.name[0].toUpperCase() +
                                task.severity.name.substring(1),
                            icon: Icons.warning_amber_rounded,
                            gradient: [severityColor, severityColor],
                            showBadge: true,
                            badgeColor: severityColor,
                          ),
                          const SizedBox(height: 16),

                          // --- NEW: Location Card ---
                          if (task.location != null && task.location!.isNotEmpty) ...[
                            _buildEnhancedDetailCard(
                              title: 'Location',
                              content: task.location!,
                              icon: Icons.location_on_rounded,
                              gradient: [Colors.red.shade400, Colors.red.shade600],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // --- NEW: Assignment Card ---
                          if (task.volunteerName != null || task.assignedBy != null || task.assignedTo != null) ...[
                             Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.teal.shade400,
                                              Colors.teal.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.teal.shade300
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Assignment Details',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Volunteer Details (Async from Provider)
                                  if (volunteerAsync.isLoading)
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                    )
                                  else if (volunteerAsync.hasValue && volunteerAsync.value != null) ...[
                                      _buildEnhancedInfoRow(
                                        Icons.badge_rounded,
                                        'Assigned To',
                                        (volunteerAsync.value!.fullName?.isNotEmpty ?? false) ? volunteerAsync.value!.fullName! : (task.volunteerName ?? 'Unknown'),
                                        Colors.teal.shade400,
                                      ),
                                      if (volunteerAsync.value!.phoneNumber.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                          Divider(
                                            color: AppColors.textSecondary.withValues(alpha: 0.1),
                                            height: 1,
                                          ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildEnhancedInfoRow(
                                                Icons.phone_rounded,
                                                'Contact',
                                                volunteerAsync.value!.phoneNumber,
                                                Colors.green.shade400,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.call, color: Colors.green),
                                              onPressed: () {
                                                // Functionality to launch dialer could be added here
                                                // launchUrl(Uri.parse('tel:${volunteerAsync.value!.phoneNumber}'));
                                              }, 
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ]
                                  ] else if (task.volunteerName != null) ...[
                                     // Fallback to task document data if provider fetches nothing
                                    _buildEnhancedInfoRow(
                                      Icons.badge_rounded,
                                      'Assigned To',
                                      task.volunteerName!,
                                      Colors.teal.shade400,
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  if (task.assignedByName != null) ...[
                                    Divider(
                                      color:
                                          AppColors.textSecondary.withValues(alpha: 0.1),
                                      height: 1,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEnhancedInfoRow(
                                      Icons.admin_panel_settings_rounded,
                                      'Assigned By',
                                      task.assignedByName!,
                                      Colors.purple.shade400,
                                    ),
                                  ],
                                ],
                              ),
                             ),
                             const SizedBox(height: 16),
                          ],

                          // Enhanced Timeline Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  AppColors.textPrimary.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple.shade400,
                                            Colors.purple.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.purple.shade300
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Task Timeline',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (task.assignedAt != null)
                                  _buildEnhancedInfoRow(
                                    Icons.calendar_today_rounded,
                                    'Assigned',
                                    _formatDate(task.assignedAt!),
                                    Colors.blue.shade400,
                                  ),
                                if (task.updatedAt != null) ...[
                                  const SizedBox(height: 12),
                                  Divider(
                                    color:
                                    AppColors.textSecondary.withValues(alpha: 0.1),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildEnhancedInfoRow(
                                    Icons.update_rounded,
                                    'Last Updated',
                                    _formatDate(task.updatedAt!),
                                    Colors.green.shade400,
                                  ),
                                ],
                                if (task.completedAt != null) ...[
                                  const SizedBox(height: 12),
                                  _buildEnhancedInfoRow(
                                    Icons.check_circle_rounded,
                                    'Completed',
                                    _formatDate(task.completedAt!),
                                    Colors.teal.shade400,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Enhanced Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: statusGradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusGradient[0].withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // For in-progress or accepted tasks, go directly to completion screen
                          if (task.status == TaskStatus.inProgress || 
                              task.status == TaskStatus.accepted) {
                            context.push('/task-complete/${task.id}', extra: task);
                          } else {
                            // For other statuses, show the status update dialog
                            _showStatusUpdateDialog();
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                (task.status == TaskStatus.inProgress || 
                                 task.status == TaskStatus.accepted)
                                    ? Icons.check_circle_rounded
                                    : Icons.update_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                (task.status == TaskStatus.inProgress || 
                                 task.status == TaskStatus.accepted)
                                    ? 'Mark Completed'
                                    : 'Update Status',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildEnhancedSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDetailCard({
    required String title,
    required String content,
    required IconData icon,
    required List<Color> gradient,
    bool showBadge = false,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (showBadge && badgeColor != null)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(
      IconData icon,
      String label,
      String value,
      Color iconColor,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, can use intl package if available
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}