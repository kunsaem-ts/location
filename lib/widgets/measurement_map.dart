import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/colors.dart';
import '../app/constants.dart';
import '../app/strings.dart';
import '../models/measurement.dart';
import '../services/maps_loader.dart';

/// 측정 결과를 마커 + 오차반경 원으로 표시하는 지도 (FR-04).
/// 색은 연결망에 따라 달라진다 (AppColors.forConnection).
class MeasurementMap extends StatefulWidget {
  const MeasurementMap({super.key, required this.current});

  final Measurement? current;

  @override
  State<MeasurementMap> createState() => _MeasurementMapState();
}

class _MeasurementMapState extends State<MeasurementMap> {
  static const _markerId = MarkerId('current');
  static const _circleId = CircleId('accuracy');

  GoogleMapController? _controller;
  BitmapDescriptor? _icon;
  Color? _iconColor;

  @override
  void initState() {
    super.initState();
    _refreshIcon();
  }

  @override
  void didUpdateWidget(MeasurementMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final m = widget.current;
    if (m != null && !identical(m, oldWidget.current)) {
      _refreshIcon();
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(m.latitude, m.longitude),
          AppConstants.defaultMapZoom,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 연결망 색이 바뀔 때만 마커 비트맵을 다시 그린다.
  Future<void> _refreshIcon() async {
    final m = widget.current;
    if (m == null) return;
    final color = AppColors.forConnection(m.connectionType);
    if (color == _iconColor) return;
    final icon = await _dotMarker(color);
    if (!mounted) return;
    setState(() {
      _icon = icon;
      _iconColor = color;
    });
  }

  /// 기본 핀은 회색을 만들 수 없어(hue 기반) 흰 테두리 점 마커를 직접 그린다.
  static Future<BitmapDescriptor> _dotMarker(Color color) async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, Paint()..color = Colors.white);
    canvas.drawCircle(center, size / 2 - 5, Paint()..color = color);
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: size / 2,
      height: size / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: MapsLoader.ensureLoaded(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Notice(
            text: '${AppStrings.mapLoadError}\n${snapshot.error}',
            isError: true,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _Notice(text: AppStrings.mapLoading, isError: false);
        }
        return _buildMap();
      },
    );
  }

  Widget _buildMap() {
    final m = widget.current;
    final target = m == null
        ? const LatLng(AppConstants.initialLatitude, AppConstants.initialLongitude)
        : LatLng(m.latitude, m.longitude);
    final color = m == null ? null : AppColors.forConnection(m.connectionType);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: AppConstants.defaultMapZoom,
      ),
      onMapCreated: (c) => _controller = c,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: {
        if (m != null && _icon != null)
          Marker(
            markerId: _markerId,
            position: target,
            icon: _icon!,
            anchor: const Offset(0.5, 0.5),
          ),
      },
      circles: {
        if (m != null && color != null)
          Circle(
            circleId: _circleId,
            center: target,
            radius: m.accuracyM,
            fillColor: color.withValues(alpha: 0.15),
            strokeColor: color,
            strokeWidth: 2,
          ),
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.isError});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: isError ? scheme.error : null),
      ),
    );
  }
}
