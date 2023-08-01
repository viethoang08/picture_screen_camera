import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class PictureScreenCamera extends StatefulWidget {
  const PictureScreenCamera({
    super.key,
    this.lensDirection,
    this.shootingMinutes = 0,
    this.shootingSeconds = 0,
    this.changeCameraSeconds = 0,
    this.changeCameraMinutes = 0,
    required this.examId,
  });
  final int? lensDirection;
  final String examId;
  final int shootingMinutes;
  final int shootingSeconds;
  final int changeCameraSeconds;
  final int changeCameraMinutes;

  @override
  State<PictureScreenCamera> createState() => _CameraMonitorState();
}

class _CameraMonitorState extends State<PictureScreenCamera> {
  late CameraController controller;
  late List<CameraDescription> _cameras;
  ScreenshotController screenshotController = ScreenshotController();
  bool isLoading = true;
  Timer? timeChangeCamera;
  Timer? timeShotCamera;

  void startService() async {
    _cameras = await availableCameras();
    await _initCamera(_cameras[widget.lensDirection ?? 0]);
    startShotScreenCamera();
    startChangeCamera();
  }

  void startShotScreenCamera() {
    if (widget.shootingSeconds > 0 || widget.shootingMinutes > 0) {
      Timer.periodic(
        Duration(
          seconds: widget.shootingSeconds,
          minutes: widget.shootingMinutes,
        ),
            (timer) async {
          timeShotCamera = timer;
          pictureScreen();
        },
      );
    }
  }

  void startChangeCamera() {
    if (widget.changeCameraMinutes > 0 || widget.changeCameraSeconds > 0) {
      Timer.periodic(
        Duration(
          seconds: widget.changeCameraSeconds,
          minutes: widget.changeCameraMinutes,
        ),
            (timer) async {
          timeChangeCamera = timer;
          if (widget.lensDirection != 0 && widget.lensDirection != 1) {
            await switchCamera();
          }
        },
      );
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    try {
      controller = CameraController(description, ResolutionPreset.low);
      await controller.initialize();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi mở camera: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> switchCamera() async {
    final lensDirection = controller.description.lensDirection;
    CameraDescription newDescription;
    if (lensDirection == CameraLensDirection.front) {
      newDescription = _cameras.firstWhere(
            (description) => description.lensDirection == CameraLensDirection.back,
      );
    } else {
      newDescription = _cameras.firstWhere(
            (description) => description.lensDirection == CameraLensDirection.front,
      );
    }

    await _initCamera(newDescription);
  }

  void pictureScreen() {
    screenshotController.capture(delay: const Duration(seconds: 1)).then(
          (capturedImage) async {
        saveImage(capturedImage);
      },
    ).catchError((onError) {
      print(onError);
    });
  }

  Future<void> saveImage(Uint8List? capturedImage) async {
    if (capturedImage != null) {
      File imageFile = File(await ServicePictureScreenCamera()
          .createPathSaveImageByExamId(widget.examId));

      await imageFile.writeAsBytes(capturedImage);
    }
  }

  @override
  void initState() {
    super.initState();
    startService();
  }

  @override
  void dispose() {
    try {
      if (timeChangeCamera != null) {
        timeChangeCamera?.cancel();
      }
      if (timeShotCamera != null) {
        timeShotCamera?.cancel();
      }
      if (controller.value.isInitialized) {
        controller.dispose();
      }
    } catch (e) {
      print(e);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || !controller.value.isInitialized) {
      return Container();
    }
    return Screenshot(
      controller: screenshotController,
      child: CameraPreview(
        controller,
        child: Stack(
          children: [
            Positioned(
              top: 5,
              right: 5,
              child: Text(
                DateFormat('HH:mm:ss dd/MM/yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServicePictureScreenCamera {
  Future<String> createPathSaveImageByExamId(String examId) async {
    Directory? externalDir = Platform.isAndroid
        ? await getExternalStorageDirectory() //FOR ANDROID
        : await getApplicationDocumentsDirectory(); //FOR iOS
    String dateTime = DateFormat('HH_mm_ss_dd_MM_yyyy').format(DateTime.now());
    String myImagePath = "${externalDir?.path}/exam${examId}_$dateTime.jpg";
    return myImagePath;
  }

  Future<List<String>> getListPathImageByExamId(String examId) async {
    Directory? externalDir = Platform.isAndroid
        ? await getExternalStorageDirectory() //FOR ANDROID
        : await getApplicationDocumentsDirectory(); //FOR iOS
    List<FileSystemEntity> file = Directory("${externalDir?.path}")
        .listSync(recursive: true, followLinks: false);
    List<String> listImagePath = [];
    for (var i = 0; i < file.length; i++) {
      if (file[i].path.contains('exam$examId')) {
        listImagePath.add(file[i].path);
      }
    }
    return listImagePath;
  }
}
