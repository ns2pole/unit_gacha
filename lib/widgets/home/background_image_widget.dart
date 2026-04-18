// lib/widgets/background_image_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// 背景画像を4枚周期的に表示するウィジェット
/// 画面サイズに合わせて、縦横それぞれ2枚ずつ（合計4枚）表示される
class BackgroundImageWidget extends StatelessWidget {
  final String imagePath;
  final double opacity;

  const BackgroundImageWidget({
    super.key,
    this.imagePath = 'assets/background/home.png',
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableSize = Size(constraints.maxWidth, constraints.maxHeight);
          return FutureBuilder<Size?>(
            future: _getImageSize(imagePath),
            builder: (context, snapshot) {
              return _buildBackgroundImage(availableSize, snapshot.data);
            },
          );
        },
      ),
    );
  }

  /// 画像のサイズを取得する
  Future<Size?> _getImageSize(String assetPath) async {
    try {
      final imageProvider = AssetImage(assetPath);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final completer = Completer<Size?>();
      
      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
        imageStream.removeListener(listener);
      }, onError: (exception, stackTrace) {
        completer.complete(null);
        imageStream.removeListener(listener);
      });
      
      imageStream.addListener(listener);
      return completer.future;
    } catch (e) {
      return null;
    }
  }

  /// 背景画像を構築する（画面サイズに合わせて4枚周期的に表示）
  Widget _buildBackgroundImage(Size availableSize, Size? imageSize) {
    // 利用可能な領域の幅と高さのそれぞれ1/2になるようにサイズを計算
    final tileWidth = availableSize.width / 2;
    final tileHeight = availableSize.height / 2;
    
    // 4枚の画像を配置（2x2グリッド）
    return SizedBox(
      width: availableSize.width,
      height: availableSize.height,
      child: Stack(
        children: [
          // 左上
          Positioned(
            left: 0,
            top: 0,
            width: tileWidth,
            height: tileHeight,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
          // 右上
          Positioned(
            left: tileWidth,
            top: 0,
            width: tileWidth,
            height: tileHeight,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
          // 左下
          Positioned(
            left: 0,
            top: tileHeight,
            width: tileWidth,
            height: tileHeight,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
          // 右下
          Positioned(
            left: tileWidth,
            top: tileHeight,
            width: tileWidth,
            height: tileHeight,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

