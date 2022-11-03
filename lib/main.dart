import 'package:flutter/material.dart';

import 'layout/components/video_component.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: VideoComponent(
      mediaUrl:
          "https://static.videezy.com/system/resources/previews/000/043/350/original/Galaxy-dark-star-rotation-space.mp4",
      fullScreen: true,
      videoType: VideoType.network,
      looping: true,
      showButtonPlay: true,
      startVideo: true,
    ));
  }
}
