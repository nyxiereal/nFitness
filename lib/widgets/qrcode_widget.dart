import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/efitness_service.dart';

class QrCodeWidget extends StatefulWidget {
  final int clubId;
  const QrCodeWidget({required this.clubId, super.key});

  @override
  State<QrCodeWidget> createState() => _QrCodeWidgetState();
}

class _QrCodeWidgetState extends State<QrCodeWidget> {
  final EfitnessService _service = EfitnessService();
  Map<String, dynamic>? _qrData;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchQr();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQr() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final data = await _service.generateQrCode(widget.clubId);
    if (data != null && data['expiresAt'] != null) {
      final expiresAt = DateTime.parse(data['expiresAt']);
      final now = DateTime.now().toUtc();
      _timeLeft = expiresAt.difference(now);
      _startTimer();
      setState(() {
        _qrData = data;
        _loading = false;
        _error = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_qrData == null) return;
      final expiresAt = DateTime.parse(_qrData!['expiresAt']);
      final now = DateTime.now().toUtc();
      final left = expiresAt.difference(now);
      if (left.isNegative) {
        _timer?.cancel();
        _fetchQr();
      } else {
        setState(() {
          _timeLeft = left;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entry QR Code',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const CircularProgressIndicator()
            else if (_error)
              Column(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Failed to generate QR code',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: _fetchQr,
                  ),
                ],
              )
            else ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: QrImageView(
                  data: _qrData!['token'] ?? '',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _timeLeft.inSeconds > 0
                    ? 'Valid for: ${_formatDuration(_timeLeft)}'
                    : 'Expired',
                style: TextStyle(
                  fontSize: 16,
                  color: _timeLeft.inSeconds > 10
                      ? colorScheme.primary
                      : colorScheme.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _infoText(
                    'Issued:',
                    _formatDate(_qrData!['issuedAt']),
                    colorScheme,
                  ),
                  const SizedBox(width: 18),
                  _infoText(
                    'Expires:',
                    _formatDate(_qrData!['expiresAt']),
                    colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary, width: 1.2),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _fetchQr,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoText(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 0) return '0s';
    if (d.inMinutes > 0) {
      return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')} min';
    }
    return '${d.inSeconds}s';
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm:ss').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
