import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';

enum VideoType { asset, network }

class VideoComponent extends StatefulWidget {
  final VideoController? controller;
  final String mediaUrl;
  final VideoType videoType;
  final VoidCallback? onEndVideo;
  final bool startVideo;
  final bool fullScreen;
  final bool looping;
  final double volume;
  final bool showButtonPlay;
  final bool centerVideo;
  final bool showOverlayGradient;
  final Color? backgroundColor;
  final ValueChanged<bool>? onUserChangedIsPlaying;
  final WidgetBuilder? loadingBuilder;

  const VideoComponent({
    Key? key,
    this.mediaUrl = '',
    this.videoType = VideoType.network,
    this.onEndVideo,
    this.startVideo = false,
    this.fullScreen = false,
    this.looping = true,
    this.showButtonPlay = true,
    this.volume = 1,
    this.controller,
    this.showOverlayGradient = true,
    this.backgroundColor,
    this.centerVideo = false,
    this.onUserChangedIsPlaying,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<VideoComponent> createState() => _VideoComponentState();
}

class _VideoComponentState extends State<VideoComponent> with SingleTickerProviderStateMixin {
  late final AnimationController _overlayAnimationController;
  late final VideoController _fallbackController = VideoController();
  Duration? _lastPosition;

  VideoController get _controller => widget.controller ?? _fallbackController;

  @override
  void initState() {
    super.initState();
    _overlayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.startVideo ? 0 : 1,
    );

    _controller._initialize(_createVideoOptions()).then((value) {
      setState(() {});
      final videoPlayerController = _controller._videoPlayerController;
      if (videoPlayerController != null && widget.onEndVideo != null) {
        videoPlayerController.addListener(() {
          final position = videoPlayerController.value.position;
          final duration = videoPlayerController.value.duration;
          if (position == duration && position != _lastPosition) {
            widget.onEndVideo!();
          }
          _lastPosition = position;
        });
      }
    });
  }

  VideoOptions _createVideoOptions() {
    return VideoOptions(
      mediaUrl: widget.mediaUrl,
      videoType: widget.videoType,
      fullScreen: widget.fullScreen,
      looping: widget.looping,
      startVideo: widget.startVideo,
      volume: widget.volume,
    );
  }

  @override
  void dispose() {
    _overlayAnimationController.dispose();
    if (widget.controller == null) {
      _fallbackController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_controller._isInitialized) {
      child = Container(alignment: Alignment.topCenter, child: buildVideo());
    } else {
      child = widget.loadingBuilder?.call(context) ??
          const Center(
              child: SpinKitRing(
            color: Colors.black,
            size: 50.0,
          ));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  Widget buildVideo() {
    return GestureDetector(
      onTap: playOrPauseVideo,
      child: Stack(
        fit: widget.fullScreen ? StackFit.expand : StackFit.loose,
        children: [
          if (widget.centerVideo)
            Center(child: buildVideoPlayer())
          else
            buildVideoPlayer(),
          if (widget.showOverlayGradient)
            Positioned.fill(
              child: buildOverlayGradient(),
            ),
          widget.showButtonPlay
              ? Center(child: Positioned(
                  bottom: 8,
                  left: 8,
                  child: buildPlayPauseIcon(),
                ))
              : const SizedBox(),
        ],
      ),
    );
  }

  void playOrPauseVideo() {
    if (_controller._isPlaying) {
      _controller.pause();
      widget.onUserChangedIsPlaying?.call(false);
      _overlayAnimationController.animateTo(1);
    } else {
      _controller.play();
      widget.onUserChangedIsPlaying?.call(true);
      _overlayAnimationController.animateTo(0);
    }
  }

  Widget buildOverlayGradient() {
    return FadeTransition(
      opacity: _overlayAnimationController,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(100, 0, 0, 0),
              Color.fromARGB(0, 0, 0, 0),
            ],
            begin: FractionalOffset.bottomCenter,
            end: FractionalOffset.topCenter,
            stops: [0.0, 1.0],
          ),
        ),
      ),
    );
  }

  Widget buildPlayPauseIcon() {
    return AnimatedIcon(
      progress: _overlayAnimationController,
      icon: AnimatedIcons.pause_play,
      color:  Colors.white,
    );
  }

  Widget buildVideoPlayer() => FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: _controller._size.height,
          width: _controller._size.width,
          child: VideoPlayer(_controller._videoPlayerController!),
        ),
      );
}

class VideoController {
  final bool _cacheVideo;
  VideoPlayerController? _videoPlayerController;

  VideoController({bool? cacheVideo}) : _cacheVideo = cacheVideo ?? false;

  void play() {
    _videoPlayerController?.play();
  }

  void pause() {
    _videoPlayerController?.pause();
  }

  void restart() {
    _videoPlayerController?.seekTo(Duration.zero);
  }

  void dispose() {
    _videoPlayerController?.dispose();
  }

  Future<void> _initialize(VideoOptions options) async {
    if (_isInitialized && _cacheVideo) {
      _videoPlayerController!.seekTo(Duration.zero);
    } else {
      _videoPlayerController?.dispose();
      await _initializeNewVideoPlayerController(options);
    }
    if (options.startVideo) {
      _videoPlayerController!.play();
    }
  }

  Future<void> _initializeNewVideoPlayerController(VideoOptions options) {
    if (options.videoType == VideoType.network) {
      _videoPlayerController = VideoPlayerController.network(options.mediaUrl);
    } else if (options.videoType == VideoType.asset) {
      _videoPlayerController = VideoPlayerController.asset(options.mediaUrl);
    }

    _videoPlayerController!.setLooping(options.looping);
    _videoPlayerController!.setVolume(options.volume);
    return _videoPlayerController!.initialize();
  }

  Size get _size => _videoPlayerController?.value.size ?? Size.zero;

  bool get _isPlaying => _videoPlayerController?.value.isPlaying ?? false;

  bool get _isInitialized =>
      _videoPlayerController?.value.isInitialized ?? false;
}

class VideoOptions {
  final String mediaUrl;
  final VideoType videoType;
  final bool startVideo;
  final bool fullScreen;
  final bool looping;
  final double volume;

  const VideoOptions({
    required this.mediaUrl,
    required this.videoType,
    this.startVideo = false,
    this.fullScreen = false,
    this.looping = true,
    this.volume = 0,
  });
}

abstract class VideoEvent {}

class PlayVideoEvent extends VideoEvent {}

class PauseVideoEvent extends VideoEvent {}
