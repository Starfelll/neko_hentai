import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/config/theme_config.dart';
import 'package:jhentai/src/utils/log.dart';

import '../service/storage_service.dart';

enum EHThemeMode {
  light,
  dark,
  system,
}

enum ListMode {
  listWithoutTags,
  listWithTags,
  waterfallFlowWithImageOnly,
  waterfallFlowWithImageAndInfo,
}

class StyleSetting {
  static RxBool enableTagZHTranslation = false.obs;
  static Rx<EHThemeMode> themeMode = EHThemeMode.light.obs;
  static Rx<ListMode> listMode = ListMode.listWithTags.obs;
  static RxBool enableTabletLayout =
      WidgetsBinding.instance!.window.physicalSize.width / WidgetsBinding.instance!.window.devicePixelRatio <= 600
          ? false.obs
          : true.obs;

  static void init() {
    Map<String, dynamic>? map = Get.find<StorageService>().read<Map<String, dynamic>>('styleSetting');
    if (map != null) {
      _initFromMap(map);
      Log.info('init StyleSetting success', false);
    }
  }

  static saveEnableTagZHTranslation(bool enableTagZHTranslation) {
    StyleSetting.enableTagZHTranslation.value = enableTagZHTranslation;
    _save();
  }

  static saveThemeMode(EHThemeMode themeMode) {
    StyleSetting.themeMode.value = themeMode;
    _save();
    Get.changeTheme(getCurrentThemeData());
  }

  static saveListMode(ListMode listMode) {
    StyleSetting.listMode.value = listMode;
    _save();
  }

  static saveEnableTabletLayout(bool enableTabletLayout) {
    StyleSetting.enableTabletLayout.value = enableTabletLayout;
    _save();
  }

  static ThemeData getCurrentThemeData() {
    return themeMode.value == EHThemeMode.dark
        ? ThemeConfig.dark
        : themeMode.value == EHThemeMode.light
            ? ThemeConfig.light
            : WidgetsBinding.instance!.window.platformBrightness == Brightness.dark
                ? ThemeConfig.dark
                : ThemeConfig.light;
  }

  static Future<void> _save() async {
    await Get.find<StorageService>().write('styleSetting', _toMap());
  }

  static Map<String, dynamic> _toMap() {
    return {
      'enableTagZHTranslation': enableTagZHTranslation.value,
      'themeMode': themeMode.value.index,
      'listMode': listMode.value.index,
      'enableTabletLayout': enableTabletLayout.value,
    };
  }

  static _initFromMap(Map<String, dynamic> map) {
    enableTagZHTranslation.value = map['enableTagZHTranslation'];
    themeMode.value = EHThemeMode.values[map['themeMode']];
    listMode.value = ListMode.values[map['listMode']];
    enableTabletLayout.value = map['enableTabletLayout'];
  }
}
