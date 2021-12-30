import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

AnimationController? playC;
Animation<double>? play;

class BasicPlayerPage extends StatefulWidget {
  const BasicPlayerPage({Key? key}) : super(key: key);
  @override
  _BasicPlayerPageState createState() => _BasicPlayerPageState();
}

class _BasicPlayerPageState extends State<BasicPlayerPage> with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  Duration nowDuration = Duration.zero;

  screenSetting() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else if (MediaQuery.of(context).orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.restoreSystemUIOverlays();
    }
  }

  durationTrack() async {
    nowDuration = await _controller!.position ?? Duration.zero;
  }

  startAnimation() {
    if (playC!.isCompleted) playC!.reverse();
  }

  @override
  void initState() {
    super.initState();
    playC = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    play = Tween(begin: 0.0, end: 1.0).animate(playC!);
    _controller = VideoPlayerController.network('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
      ..initialize().then((e) {
        setState(() {});
      })
      ..addListener(() {
        if (!_controller!.value.isPlaying) {
          startAnimation();
        }
      });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.restoreSystemUIOverlays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () async {
            if (playC!.isCompleted) {
              playC!.reverse();
              _controller!.pause();
              await durationTrack();
              setState(() {});
            } else {
              playC!.forward();
              _controller!.play();
              await durationTrack();
              setState(() {});
            }
          },
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: _controller == null ? const CircularProgressIndicator() : VideoPlayer(_controller!),
              ),
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ValueListenableBuilder(
                    valueListenable: _controller!,
                    builder: (context, VideoPlayerValue value, child) {
                      durationTrack();
                      return Text(
                        value.position.toString().split('.')[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 60,
                top: 3,
                child: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: play!,
                  color: Colors.black54,
                ),
              ),
              Positioned(
                right: 5,
                top: 3,
                child: GestureDetector(
                  onTap: () {
                    screenSetting();
                  },
                  child: const Icon(Icons.fullscreen),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ValueListenableBuilder(
                  valueListenable: _controller!,
                  builder: (context, VideoPlayerValue value, child) {
                    return GestureDetector(
                      onHorizontalDragUpdate: (data) {
                        nowDuration = Duration(milliseconds: ((_controller!.value.duration.inMilliseconds / MediaQuery.of(context).size.width) * data.localPosition.dx).floor());
                        _controller!.seekTo(nowDuration);
                        setState(() {});
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.transparent,
                        padding: const EdgeInsets.only(top: 40),
                        child: Row(
                          children: [
                            Container(
                              height: 3,
                              width: nowDuration.inMilliseconds == 0 ? 0 : (MediaQuery.of(context).size.width / _controller!.value.duration.inMilliseconds) * nowDuration.inMilliseconds,
                              color: Colors.red.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
