import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import '../widgets/bottom_nav_bar.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isCameraReady = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  // Timer variables
  int _selectedTimerSeconds = 0;
  List<int> _timerOptions = [0, 3, 5, 10];
  Timer? _countdownTimer;
  int _countdownValue = 0;
  bool _isCountdownActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
    if (state == AppLifecycleState.paused) {
      _cameraController?.dispose();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showError('Camera permission is required to take photos.');
        return;
      }

      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No camera available on this device.');
        return;
      }

      final cameraIndex = _selectedCameraIndex < _cameras!.length ? _selectedCameraIndex : 0;
      final cameraDescription = _cameras![cameraIndex];

      await _cameraController?.dispose();

      _cameraController = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      print('Camera initialization error: $e');
      _showError('Failed to initialize camera: $e');
    }
  }

  void _selectTimer(int seconds) {
    setState(() {
      _selectedTimerSeconds = seconds;
    });
  }

  void _startCountdown() {
    if (_selectedTimerSeconds == 0) {
      _takePhoto();
      return;
    }

    setState(() {
      _isCountdownActive = true;
      _countdownValue = _selectedTimerSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownValue--;
      });

      if (_countdownValue == 0) {
        timer.cancel();
        setState(() {
          _isCountdownActive = false;
        });
        _takePhoto();
      }
    });
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera is not ready. Please try again.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final XFile image = await _cameraController!.takePicture();

      if (mounted) {
        final File imageFile = File(image.path);
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(imageFile: imageFile),
          ),
        );
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // Request appropriate storage permission based on Android version
      PermissionStatus status;

      // Check if running on Android 13+ (API 33+)
      if (await _isAndroid13OrHigher()) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        _showError('Storage permission is required to access gallery.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        final File imageFile = File(image.path);
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(imageFile: imageFile),
          ),
        );
      }
    } catch (e) {
      _showError('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      try {
        // Check if photos permission exists (Android 13+)
        final photosStatus = await Permission.photos.status;
        return photosStatus != PermissionStatus.denied;
      } catch (e) {
        // If photos permission doesn't exist, it's Android 12 or below
        return false;
      }
    }
    return false;
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length <= 1) {
      _showError('Only one camera available.');
      return;
    }

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      _isCameraReady = false;
    });

    _initializeCamera();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - Big Logo with "Camera" text on right and Back button
            Container(
              height: 60,
              color: Colors.black,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Back button on left
                  Positioned(
                    left: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Logo
                  Positioned(
                    left: 45,
                    top: -50,
                    child: Image.asset(
                      'assets/logo1.png',
                      height: 170,
                      width: 170,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.star,
                          color: Colors.pink,
                          size: 140,
                        );
                      },
                    ),
                  ),
                  // "Camera" text on the right
                  Positioned(
                    right: 15,
                    top: 20,
                    child: Text(
                      'Camera',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body Content - Camera fills entire space
            Expanded(
              child: Container(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera Preview
                    if (_isCameraReady && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.pink,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Initializing Camera...',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),

                    // Countdown Overlay
                    if (_isCountdownActive)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Circular progress indicator
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: _countdownValue / _selectedTimerSeconds,
                                  strokeWidth: 8,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              // Countdown number
                              Text(
                                '$_countdownValue',
                                style: GoogleFonts.inter(
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              // Cancel button
                              Positioned(
                                bottom: 20,
                                child: GestureDetector(
                                  onTap: () {
                                    _countdownTimer?.cancel();
                                    setState(() {
                                      _isCountdownActive = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.pink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Timer indicator on top of camera
                    if (_isCameraReady && !_isCountdownActive && _selectedTimerSeconds > 0)
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedTimerSeconds}s timer',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTimerSeconds = 0;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bottom controls - Professional camera UI
                    if (_isCameraReady && !_isCountdownActive)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Gallery Button
                              GestureDetector(
                                onTap: _pickFromGallery,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),

                              // Capture Button with Timer
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Timer options - horizontal bar
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _timerOptions.map((seconds) {
                                        final isSelected = _selectedTimerSeconds == seconds;
                                        return GestureDetector(
                                          onTap: () => _selectTimer(seconds),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.pink
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              seconds == 0 ? 'Off' : '${seconds}s',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white70,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Capture button
                                  GestureDetector(
                                    onTap: _isLoading ? null : _startCountdown,
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isLoading
                                              ? Colors.grey
                                              : Colors.white,
                                        ),
                                        child: _isLoading
                                            ? const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Switch Camera Button
                              if (_cameras != null && _cameras!.length > 1)
                                GestureDetector(
                                  onTap: _switchCamera,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.flip_camera_ios,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 44),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}