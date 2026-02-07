import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/ios_theme.dart';
import '../bloc/route_bloc.dart';

/// Bottom sheet for completing delivery
/// Photo + Signature + Notes
class DeliveryCompletionSheet extends StatefulWidget {
  final DeliveryStop stop;
  final Function(DeliveryProof) onComplete;

  const DeliveryCompletionSheet({
    super.key,
    required this.stop,
    required this.onComplete,
  });

  @override
  State<DeliveryCompletionSheet> createState() =>
      _DeliveryCompletionSheetState();
}

class _DeliveryCompletionSheetState extends State<DeliveryCompletionSheet> {
  File? _photo;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    IOSTheme.mediumImpact();
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _photo = File(image.path);
      });
    }
  }

  void _complete() {
    if (_photo == null) {
      _showError('Сделайте фото подтверждения доставки');
      return;
    }

    IOSTheme.success();
    
    final proof = DeliveryProof(
      photoPath: _photo!.path,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      timestamp: DateTime.now(),
    );

    widget.onComplete(proof);
    Navigator.pop(context);
  }

  void _showError(String message) {
    IOSTheme.error();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: IOSTheme.systemRed,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: IOSTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            IOSButton(
              text: 'Понятно',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IOSTheme.radius2Xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: IOSTheme.fill,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Подтверждение доставки',
                    style: IOSTheme.title2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.stop.customerName,
                    style: IOSTheme.bodyMedium.copyWith(
                      color: IOSTheme.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Photo section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Фото подтверждения',
                    style: IOSTheme.headline,
                  ),
                  const SizedBox(height: 12),
                  
                  if (_photo == null)
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: IOSTheme.bgTertiary,
                          borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
                          border: Border.all(
                            color: IOSTheme.separator,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: IOSTheme.systemBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 32,
                                color: IOSTheme.systemBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Сделать фото',
                              style: IOSTheme.bodyMedium.copyWith(
                                color: IOSTheme.systemBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Сфотографируйте место передачи заказа',
                              style: IOSTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
                          child: Image.file(
                            _photo!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _photo = null);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Переснять',
                                    style: IOSTheme.footnote.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Notes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Комментарий (опционально)',
                    style: IOSTheme.headline,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: IOSTheme.bgTertiary,
                      borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Например: передал охраннику, домофон не работал...',
                        hintStyle: IOSTheme.bodyMedium.copyWith(
                          color: IOSTheme.labelQuaternary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: IOSTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: IOSButton(
                  text: 'Подтвердить доставку',
                  isLoading: _isLoading,
                  onPressed: _complete,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
