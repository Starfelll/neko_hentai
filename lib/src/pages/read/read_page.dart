import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/pages/read/read_page_logic.dart';
import 'package:jhentai/src/pages/read/widget/read_list_view_helper.dart';
import 'package:jhentai/src/widget/eh_image.dart';
import 'package:jhentai/src/widget/icon_text_button.dart';
import 'package:jhentai/src/widget/loading_state_indicator.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../service/download_service.dart';

class ReadPage extends StatelessWidget {
  final logic = Get.put(ReadPageLogic());
  final state = Get.find<ReadPageLogic>().state;
  final DownloadService downloadService = Get.find();

  ReadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ReadListViewHelper(
        child: _buildListView(context),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return ScrollablePositionedList.separated(
      minCacheExtent: state.type == 'local' ? 5000.0 : 500.0,
      initialScrollIndex: state.initialIndex,
      itemCount: state.pageCount,
      itemScrollController: state.itemScrollController,
      itemPositionsListener: state.itemPositionsListener,
      itemBuilder: (context, index) => Obx(() {
        /// step 1: parsing thumbnail if needed. check thumbnail info whether exists, if not, [parse] one page of thumbnails
        if (state.thumbnails.isEmpty || state.thumbnails[index].value == null) {
          if (state.imageHrefParsingState.value == LoadingState.idle) {
            logic.beginParsingImageHref(index);
          }
          if (state.type == 'online' || state.images[index].value == null) {
            return _buildParsingThumbnailsIndicator(context, index);
          }
        }

        /// step 2: parsing image url. [parse] one image's raw data
        if (state.images[index].value == null) {
          if (state.imageUrlParsingStates?[index].value == LoadingState.idle) {
            logic.beginParsingImageUrl(index);
          }

          /// just like a listener
          downloadService.gid2Images[state.gid]?[index].value;

          return _buildParsingImageIndicator(context, index);
        }

        FittedSizes fittedSizes = applyBoxFit(
          BoxFit.contain,
          Size(state.images[index].value!.width, state.images[index].value!.height),
          Size(context.width, double.infinity),
        );

        /// step 3 load image : use url to [load] image
        return KeepAliveWrapper(
          child: EHImage(
            enableLongPressToRefresh: state.type == 'online',
            containerHeight: fittedSizes.destination.height,
            containerWidth: fittedSizes.destination.width,
            galleryImage: state.images[index].value!,
            adaptive: true,
            fit: BoxFit.contain,
            loadingWidgetBuilder: (double progress) => _loadingWidgetBuilder(context, index, progress),
            failedWidgetBuilder: (ExtendedImageState state) => _failedWidgetBuilder(context, index, state),
            downloadingWidgetBuilder: () => _downloadingWidgetBuilder(context, index),
          ),
        );
      }),
      separatorBuilder: (BuildContext context, int index) {
        return const Divider(height: 6);
      },
    );
  }

  Widget _buildParsingThumbnailsIndicator(BuildContext context, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showReParseBottomSheet(context, () => logic.beginParsingImageHref(index)),
      child: SizedBox(
        height: context.height / 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingStateIndicator(
              userCupertinoIndicator: false,
              loadingState: state.imageHrefParsingState.value,
              idleWidget: const CircularProgressIndicator(),
              errorWidget: const Icon(Icons.warning, color: Colors.yellow),
            ),
            Text(
              state.imageHrefParsingState.value == LoadingState.error ? 'parsePageFailed'.tr : 'parsingPage'.tr,
              style: state.readPageTextStyle(),
            ).marginOnly(top: 8),
            Text(index.toString(), style: state.readPageTextStyle()).marginOnly(top: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildParsingImageIndicator(BuildContext context, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showReParseBottomSheet(context, () => logic.beginParsingImageUrl(index)),
      child: SizedBox(
        height: context.height / 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.type == 'online')
              LoadingStateIndicator(
                userCupertinoIndicator: false,
                loadingState: state.imageUrlParsingStates![index].value,
                idleWidget: const CircularProgressIndicator(),
                errorWidget: const Icon(Icons.warning, color: Colors.yellow),
              ),
            if (state.type == 'local') const CircularProgressIndicator(),
            Text(
              state.imageUrlParsingStates?[index].value == LoadingState.error ? 'parseURLFailed'.tr : 'parsingURL'.tr,
              style: state.readPageTextStyle(),
            ).marginOnly(top: 8),
            Text(index.toString(), style: state.readPageTextStyle()).marginOnly(top: 4),
          ],
        ),
      ),
    );
  }

  Widget _loadingWidgetBuilder(BuildContext context, int index, double progress) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(value: progress),
        Text('loading'.tr, style: state.readPageTextStyle()).marginOnly(top: 8),
        Text(index.toString(), style: state.readPageTextStyle()).marginOnly(top: 4),
      ],
    );
  }

  Widget _failedWidgetBuilder(BuildContext context, int index, ExtendedImageState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTextButton(
          iconData: Icons.error,
          text: Text('networkError'.tr, style: this.state.readPageTextStyle()),
          onPressed: state.reLoadImage,
        ),
        Text(index.toString(), style: this.state.readPageTextStyle()),
      ],
    );
  }

  Widget _downloadingWidgetBuilder(BuildContext context, int index) {
    return Obx(() {
      SpeedComputer speedComputer = downloadService.gid2SpeedComputer[state.gid]!;
      int downloadedBytes = speedComputer.imageDownloadedBytes[index].value;
      int totalBytes = speedComputer.imageTotalBytes[index].value;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: max(downloadedBytes / totalBytes, 0.01)),
          Text('downloading'.tr, style: state.readPageTextStyle()).marginOnly(top: 8),
          Text(index.toString(), style: state.readPageTextStyle()),
        ],
      );
    });
  }

  void _showReParseBottomSheet(BuildContext context, ErrorTapCallback callback) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text('reload'.tr),
            onPressed: () async {
              callback();
              Get.back();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('cancel'.tr),
          onPressed: Get.back,
        ),
      ),
    );
  }
}
