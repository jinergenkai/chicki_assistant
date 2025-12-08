import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moon_design/moon_design.dart';
import 'package:path/path.dart' as p;

import 'package:chicki_buddy/services/model_manager_service.dart';

class DownloadModelScreen extends StatefulWidget {
  const DownloadModelScreen({super.key});

  @override
  State<DownloadModelScreen> createState() => _DownloadModelScreenState();
}

class _DownloadModelScreenState extends State<DownloadModelScreen> {
  final _modelManager = Get.find<ModelManagerService>();

  @override
  void initState() {
    super.initState();
    _modelManager.checkFilesStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Migration Tools", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Manage AI model assets migration.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              // Status Panel
              Obx(() => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_modelManager.currentOperation.value.isEmpty 
                        ? "Idle" 
                        : _modelManager.currentOperation.value
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: 8),
              Obx(() => _modelManager.currentOperation.value.isNotEmpty ? LinearProgressIndicator(
                value: _modelManager.downloadProgress.value,
              ) : const SizedBox.shrink()),

              const SizedBox(height: 24),
              const Text("Assets Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              
              Expanded(
                child: Obx(() {
                  final status = _modelManager.fileStatus;
                  if (status.isEmpty) return const Center(child: Text("No files tracked"));
                  
                  return ListView.separated(
                    itemCount: status.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final fileName = status.keys.elementAt(index);
                      final exists = status[fileName] ?? false;
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              exists ? Icons.check_circle : Icons.error_outline,
                              color: exists ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(exists ? "Available on disk" : "Missing / Use Asset default", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            )),
                            if (!exists)
                              MoonButton(
                                onTap: () => _modelManager.downloadFile(fileName),
                                label: const Text("Download"),
                                buttonSize: MoonButtonSize.xs,
                              )
                            else
                              Row(
                                children: [
                                  // Extract Button for Archive
                                  if (fileName.endsWith('.rar') || fileName.endsWith('.zip'))
                                    MoonButton(
                                      onTap: () => _modelManager.extractFile(fileName),
                                      label: const Text("Extract"),
                                      buttonSize: MoonButtonSize.xs,
                                      backgroundColor: Colors.orange.shade50,
                                      textColor: Colors.orange,
                                    ),
                                  
                                  // View Folder Button (if extracted)
                                  if (fileName.contains('vits-piper') && _modelManager.getExtractedFiles().isNotEmpty)
                                    IconButton(
                                      tooltip: "View Extracted Files",
                                      icon: const Icon(Icons.folder_open, color: Colors.blue),
                                      onPressed: () => _showExtractedFiles(context),
                                    ),

                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                    onPressed: () => _modelManager.deleteFile(fileName),
                                  ),
                                ],
                              )
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text("Note: RAR files must be extracted manually after download.", style: TextStyle(color: Colors.amber.shade800, fontSize: 13)),
              const SizedBox(height: 8),
              
              MoonFilledButton(
                label: const Text("Re-check Status"),
                onTap: () => _modelManager.checkFilesStatus(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExtractedFiles(BuildContext context) {
    final files = _modelManager.getExtractedFiles();
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.white,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Extracted Files", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: files.isEmpty 
               ? const Center(child: Text("Folder is empty"))
               : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, i) {
                     final f = files[i];
                     return ListTile(
                       leading: Icon(f is Directory ? Icons.folder : Icons.description, color: Colors.grey),
                       title: Text(p.basename(f.path)),
                       subtitle: Text(f.path.split('vits-piper-en_GB-jenny_dioco-medium').last),
                       dense: true,
                     );
                  },
               ),
            ),
          ],
        ),
      ),
    );
  }
}
