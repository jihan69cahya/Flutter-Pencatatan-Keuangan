import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:iconsax/iconsax.dart';

class Toast {
  static void showWarningToast(context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      title: Text("Peringatan !!!"),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: Color(0xFFFFFFFF),
      icon: Icon(Iconsax.warning_2),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: highModeShadow,
      showProgressBar: true,
      dragToClose: true,
      pauseOnHover: false,
      applyBlurEffect: true,
    );
  }

  static void showSuccessToast(context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: Text("Berhasil"),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: Color(0xFFFFFFFF),
      icon: Icon(Iconsax.tick_circle),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: highModeShadow,
      showProgressBar: true,
      dragToClose: true,
      pauseOnHover: false,
      applyBlurEffect: true,
      primaryColor: Color(0xFF1976D2),
    );
  }

  static void showErrorToast(context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text("Gagal !!!"),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: Color(0xFFFFFFFF),
      icon: Icon(Iconsax.close_circle),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: highModeShadow,
      showProgressBar: true,
      dragToClose: true,
      pauseOnHover: false,
      applyBlurEffect: true,
    );
  }

  static void showInfoToast(context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: Text("Informasi ..."),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: Color(0xFFFFFFFF),
      icon: Icon(Iconsax.message),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: highModeShadow,
      showProgressBar: true,
      dragToClose: true,
      pauseOnHover: false,
      applyBlurEffect: true,
    );
  }
}
