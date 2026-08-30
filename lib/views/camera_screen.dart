import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import '../widgets/bottom_nav_bar.dart';
import 'preview_screen.dart';
import 'home_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isCameraReady = false;
  bool _isPermissionDenied = false;
  bool _isCheckingPermission = true;
  bool _isGalleryPermissionDenied = false;
  bool _showPermissionDialog = false;
  bool _hasCheckedGalleryPermission = false;
  bool _isGalleryPermissionGranted = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  bool _isReturningFromPreview = false;

  int _selectedTimerSeconds = 0;
  List<int> _timerOptions = [0, 3, 5, 10];
  Timer? _countdownTimer;
  int _countdownValue = 0;
  bool _isCountdownActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInitialize();
    _checkGalleryPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isReturningFromPreview && !_isCameraReady && !_isPermissionDenied) {
      _initializeCamera();
      _isReturningFromPreview = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _disposeCameraController();
    super.dispose();
  }

  void _disposeCameraController() {
    if (_cameraController != null) {
      try {
        _cameraController?.dispose();
      } catch (e) {
        print('Error disposing camera: $e');
      }
      _cameraController = null;
    }
    setState(() {
      _isCameraReady = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndInitialize();
    }
    if (state == AppLifecycleState.paused) {
      if (!_isReturningFromPreview) {
        _disposeCameraController();
      }
    }
  }


  // CHECK GALLERY PERMISSION ON INIT

  Future<void> _checkGalleryPermission() async {
    try {
      PermissionStatus status;
      if (await _isAndroid13OrHigher()) {
        status = await Permission.photos.status;
      } else {
        status = await Permission.storage.status;
      }

      setState(() {
        _hasCheckedGalleryPermission = true;
        _isGalleryPermissionGranted = status.isGranted;
        _isGalleryPermissionDenied = !status.isGranted;
      });

      print('Gallery permission status: $status');
    } catch (e) {
      print('Error checking gallery permission: $e');
      setState(() {
        _hasCheckedGalleryPermission = true;
        _isGalleryPermissionDenied = true;
        _isGalleryPermissionGranted = false;
      });
    }
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() {
      _isCheckingPermission = true;
    });

    try {
      final status = await Permission.camera.status;
      print('Camera permission status: $status');

      if (status.isGranted) {
        setState(() {
          _isPermissionDenied = false;
          _isCheckingPermission = false;
          _showPermissionDialog = false;
        });
        await _initializeCamera();
      } else if (status.isDenied) {
        setState(() {
          _isPermissionDenied = true;
          _isCheckingPermission = false;
          _showPermissionDialog = true;
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _isPermissionDenied = true;
          _isCheckingPermission = false;
          _showPermissionDialog = false;
        });
      } else {
        setState(() {
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
      print('Error checking permission: $e');
      setState(() {
        _isCheckingPermission = false;
        _isPermissionDenied = true;
        _showPermissionDialog = true;
      });
    }
  }


  // NATIVE-STYLE PERMISSION DIALOG OVERLAY

  Widget _buildPermissionDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"ShapeSnap" Would Like to Access the Camera',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This app uses the camera to scan your body shape and provide personalized style recommendations.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPermissionDialog = false;
                        _isPermissionDenied = true;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE6186A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Don't Allow",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE6186A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      PermissionStatus status = await Permission.camera.request();
                      print('Camera permission result: $status');

                      if (status.isGranted) {
                        setState(() {
                          _isPermissionDenied = false;
                          _showPermissionDialog = false;
                        });
                        await _initializeCamera();
                      } else {
                        setState(() {
                          _isPermissionDenied = true;
                          _showPermissionDialog = true;
                        });
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFE6186A),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  // GALLERY PERMISSION METHODS

  Future<void> _checkAndRequestGalleryPermission() async {
    try {
      if (_isGalleryPermissionGranted) {
        _openGallery();
        return;
      }

      PermissionStatus status;
      if (await _isAndroid13OrHigher()) {
        status = await Permission.photos.status;
      } else {
        status = await Permission.storage.status;
      }

      if (status.isGranted) {
        setState(() {
          _isGalleryPermissionGranted = true;
          _isGalleryPermissionDenied = false;
        });
        _openGallery();
        return;
      }

      _showGalleryPermissionDialog();
    } catch (e) {
      print('Gallery permission error: $e');
      _showError('Failed to check gallery permission: $e');
    }
  }

  void _showGalleryPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          '"ShapeSnap" Would Like to Access Your Gallery',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'This app uses your gallery to select existing photos for body shape analysis and style recommendations.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isGalleryPermissionDenied = true;
                    _isGalleryPermissionGranted = false;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE6186A),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Don't Allow",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE6186A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleAllowGallery();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFE6186A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAllowGallery() async {
    try {
      PermissionStatus status;
      if (await _isAndroid13OrHigher()) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        setState(() {
          _isGalleryPermissionGranted = true;
          _isGalleryPermissionDenied = false;
        });
        _openGallery();
      } else {
        setState(() {
          _isGalleryPermissionGranted = false;
          _isGalleryPermissionDenied = true;
        });
        final bool isPermanentlyDenied = await _isAndroid13OrHigher()
            ? await Permission.photos.isPermanentlyDenied
            : await Permission.storage.isPermanentlyDenied;

        if (isPermanentlyDenied) {
          _showGalleryPermissionDeniedDialog();
        }
      }
    } catch (e) {
      print('Gallery permission error: $e');
      _showError('Failed to request gallery permission: $e');
    }
  }

  void _showGalleryPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Gallery Permission Required',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A2A4F),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gallery access has been permanently denied. To select photos from your gallery, please enable storage permission in your device settings.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 How to enable:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A2A4F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1. Tap "Open Settings" below\n2. Find ShapeSnap in the app list\n3. Tap "Permissions"\n4. Select "Allow" for Photos/Storage',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6186A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Open Settings',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      try {
        final photosStatus = await Permission.photos.status;
        return photosStatus != PermissionStatus.denied ||
            photosStatus == PermissionStatus.granted ||
            photosStatus == PermissionStatus.limited;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<void> _initializeCamera() async {
    _disposeCameraController();

    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        setState(() {
          _isPermissionDenied = true;
          _isCheckingPermission = false;
          _showPermissionDialog = true;
        });
        return;
      }

      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No camera available on this device.');
        setState(() {
          _isCheckingPermission = false;
        });
        return;
      }

      final cameraIndex = _selectedCameraIndex < _cameras!.length ? _selectedCameraIndex : 0;
      final cameraDescription = _cameras![cameraIndex];

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
        _isPermissionDenied = false;
        _isCheckingPermission = false;
        _showPermissionDialog = false;
      });
    } catch (e) {
      print('Camera initialization error: $e');
      _showError('Failed to initialize camera: $e');
      setState(() {
        _isCameraReady = false;
        _isCheckingPermission = false;
      });
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
        _isReturningFromPreview = true;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(imageFile: imageFile),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCameraReady) {
            _initializeCamera();
          }
        });
      }
    } catch (e) {
      _showError('Error taking photo: $e');
      _isReturningFromPreview = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openGallery() async {
    try {
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
        _isReturningFromPreview = true;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(imageFile: imageFile),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCameraReady) {
            _initializeCamera();
          }
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
      _isReturningFromPreview = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isGalleryPermissionGranted) {
      _openGallery();
      return;
    }

    try {
      PermissionStatus status;
      if (await _isAndroid13OrHigher()) {
        status = await Permission.photos.status;
      } else {
        status = await Permission.storage.status;
      }

      if (status.isGranted) {
        setState(() {
          _isGalleryPermissionGranted = true;
          _isGalleryPermissionDenied = false;
        });
        _openGallery();
        return;
      } else if (status.isDenied) {
        _showGalleryPermissionDialog();
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _isGalleryPermissionDenied = true;
          _isGalleryPermissionGranted = false;
        });
        _showGalleryPermissionDeniedDialog();
      } else {
        _showGalleryPermissionDialog();
      }
    } catch (e) {
      print('Error checking gallery permission: $e');
      _showError('Failed to check gallery permission');
    }
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
    if (_isCheckingPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.pink,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing camera...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Changed to white
      body: SafeArea(
        child: Stack(
          children: [
            // Camera UI
            Column(
              children: [
                // HEADER - WHITE BACKGROUND WITH PINK TEXT
                Container(
                  height: 60,
                  color: Colors.white,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Back button
                      Positioned(
                        left: 10,
                        top: 10,
                        child: GestureDetector(
                          onTap: _goBack,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.pink,
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
                      // "Camera" text - PINK
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
                // Camera Preview - takes remaining space
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized)
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

                        if (_isCountdownActive)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
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
                                  Text(
                                    '$_countdownValue',
                                    style: GoogleFonts.inter(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
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
                      ],
                    ),
                  ),
                ),
                // BOTTOM CONTROLS - WHITE BACKGROUND
                Container(
                  color: Colors.white, // White background for bottom controls
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.photo_library,
                            color: Colors.pink,
                            size: 28,
                          ),
                        ),
                      ),
                      // Timer and Capture button
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Timer options
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.shade300,
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
                                            : Colors.grey.shade700,
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
                                  color: Colors.pink,
                                  width: 4,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isLoading
                                      ? Colors.grey.shade300
                                      : Colors.pink,
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
                                    : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Switch camera button
                      if (_cameras != null && _cameras!.length > 1)
                        GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.flip_camera_ios,
                              color: Colors.pink,
                              size: 28,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 44),
                    ],
                  ),
                ),
              ],
            ),
            if (_showPermissionDialog && !_isCameraReady)
              _buildPermissionDialog(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}