import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/setting/style_setting.dart';

import '../consts/color_consts.dart';
import '../consts/locale_consts.dart';
import '../model/gallery.dart';
import '../model/gallery_image.dart';
import 'eh_gallery_list_card_.dart';
import 'eh_image.dart';

class EHGalleryWaterFlowCard extends StatelessWidget {
  final Gallery gallery;
  final TapCardCallback handleTapCard;
  final bool keepAlive;

  const EHGalleryWaterFlowCard({
    Key? key,
    required this.gallery,
    required this.handleTapCard,
    this.keepAlive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      keepAlive: keepAlive,
      child: GestureDetector(
        onTap: () => handleTapCard(gallery),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: Get.theme.brightness == Brightness.light ? Colors.grey.shade300 : Colors.grey.shade700,
            child: Obx(() {
              return Column(
                children: [
                  _buildCover(gallery.cover),
                  if (StyleSetting.listMode.value == ListMode.waterfallFlowWithImageAndInfo) _buildInfo(gallery),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(GalleryImage image) {
    return LayoutBuilder(
      builder: (context, constraints) {
        FittedSizes fittedSizes = applyBoxFit(
          BoxFit.contain,
          Size(image.width, image.height),
          Size(constraints.maxWidth, constraints.maxHeight),
        );

        return EHImage(
          containerHeight: fittedSizes.destination.height,
          containerWidth: fittedSizes.destination.width,
          galleryImage: image,
          adaptive: true,
          fit: BoxFit.contain,
        );
      },
    );
  }

  Widget _buildInfo(Gallery gallery) {
    return Container(
      height: 15,
      color: ColorConsts.galleryCategoryColor[gallery.category]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            gallery.category,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ).marginOnly(left: 4),
          const Expanded(child: SizedBox()),
          if (gallery.language != null)
            Text(
              LocaleConsts.language2Code[gallery.language] ?? '',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ).marginOnly(right: 4),
          if (gallery.pageCount != null)
            const Icon(
              Icons.panorama,
              size: 10,
              color: Colors.white70,
            ).marginOnly(right: 2),
          if (gallery.pageCount != null)
            Text(
              gallery.pageCount.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ).marginOnly(right: 2),
        ],
      ),
    );
  }
}
