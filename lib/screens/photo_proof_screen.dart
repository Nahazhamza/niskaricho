import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/prayer_model.dart';
import '../services/supabase_service.dart';
import '../services/zones.dart';
import '../theme/app_theme.dart';

/// BeReal-style proof: live camera only (no gallery), stamped with prayer +
/// server-corrected time, uploaded to an insert-only bucket.
///
/// The burned-in watermark is for humans. The tamper-proof timestamp is the
/// storage object's server `created_at`, which `attach_photo_proof` checks
/// against the session and stores as `photo_uploaded_at`.
class PhotoProofScreen extends StatefulWidget {
  const PhotoProofScreen({super.key, required this.log});
  final PrayerLog log;

  @override
  State<PhotoProofScreen> createState() => _PhotoProofScreenState();
}

class _PhotoProofScreenState extends State<PhotoProofScreen> {
  final _db = SupabaseService.instance;
  CameraController? _cam;
  Uint8List? _stamped;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final ctrl = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _cam = ctrl);
    } catch (e) {
      setState(() => _error = tr('Camera not available: {error}', {'error': e}));
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _snap() async {
    final cam = _cam;
    if (_busy || (cam == null && !_db.isDemo)) return;
    setState(() => _busy = true);
    try {
      // Demo without a camera (e.g. desktop browser): use a bundled sample photo.
      final raw = cam != null
          ? await (await cam.takePicture()).readAsBytes()
          : (await rootBundle.load('assets/demo/sample_proof.jpg')).buffer.asUint8List();
      final when = _db.toMyZone(_db.serverNow);
      final label =
          'NISKARICHO?  ${widget.log.prayer.english.toUpperCase()}'
          '  ${DateFormat('d MMM yyyy  HH:mm:ss').format(when)}  ${Zones.offsetLabel(_db.myTimezone, _db.serverNow)}';
      final stamped = await compute(_watermark, (raw, label));
      setState(() {
        _stamped = stamped;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final bytes = _stamped;
    if (bytes == null) return;
    setState(() => _busy = true);
    try {
      await _db.uploadPhotoProof(widget.log, bytes);
      if (mounted) Navigator.of(context).pop(true);
    } on ServerRuleException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(tr('📸 Photo proof')),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Skip')))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              tr('Take a photo of your prayer mat or prayer place. Your circle will see it today.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _stamped != null
                  ? Image.memory(_stamped!, fit: BoxFit.contain)
                  : cam != null && cam.value.isInitialized
                  ? CameraPreview(cam)
                  : Center(
                      child: _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _db.isDemo
                                    ? '$_error\n\n${tr('Demo: tap the button to use a sample photo.')}'
                                    : _error!,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const CircularProgressIndicator(),
                    ),
            ),
          ),
          if (_error != null && _stamped != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: AppColors.missed)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _stamped == null
                ? FloatingActionButton.large(
                    onPressed: _busy ? null : _snap,
                    backgroundColor: AppColors.gold,
                    child: _busy ? const CircularProgressIndicator() : const Icon(Icons.camera_alt, size: 36),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => setState(() => _stamped = null),
                          child: Text(tr('Retake')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _upload,
                          child: Text(_busy ? tr('Uploading…') : tr('Share with circle')),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Runs in a background isolate: resize, burn in the banner, encode JPEG.
Uint8List _watermark((Uint8List, String) args) {
  final (raw, label) = args;
  var image = img.decodeImage(raw)!;
  image = img.bakeOrientation(image);
  if (image.width > 1080) image = img.copyResize(image, width: 1080);

  final font = img.arial24;
  const pad = 18;
  final bannerH = font.lineHeight + pad * 2;
  img.fillRect(
    image,
    x1: 0,
    y1: image.height - bannerH,
    x2: image.width,
    y2: image.height,
    color: img.ColorRgba8(11, 31, 26, 200),
  );
  img.drawString(image, label, font: font, x: pad, y: image.height - bannerH + pad, color: img.ColorRgb8(212, 168, 75));
  img.drawString(
    image,
    'server-verified',
    font: img.arial14,
    x: pad,
    y: pad,
    color: img.ColorRgba8(245, 239, 224, 160),
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: 82));
}
