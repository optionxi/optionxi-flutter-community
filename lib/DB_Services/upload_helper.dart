// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:optionxi/DB_Services/upload_service.dart';
import 'package:optionxi/Dialogs/custom_alert.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/filesize_helper.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';

class UploadHelperIMGPDF {
  Future<bool> Uploadpdf(
      TextEditingController pdfController,
      BuildContext context,
      String mainpath,
      String subpath,
      String filename) async {
    bool isdone = false;

    // check if its firebase link
    if (pdfController.text.endsWith(".pdf")) {
      print("PDF file to upload is: ${pdfController.text}");
      int bytes = await File(pdfController.text).length();
      if (bytes >= Constants.MAX_PDF_SIZE) {
        GlobalSnackBarGet()
            .showGetError("Error", Constants.MAX_PDF_SIZE_MESSAGE);
        return false;
      }
    } else {
      GlobalSnackBarGet()
          .showGetError("Error", "Invalid File type for pdf $filename");
      return false;
    }

    customalert().showLoaderDialog(context, "Uploading the doc");

    if (pdfController.text.contains(".pdf")) {
      var result = await Upload_helper().uploadFile(
          // File(pdfController.text), "downloads/" + cat + "/", filename);
          File(pdfController.text),
          mainpath + subpath,
          filename);

      if (result.toString() != "null") {
        GlobalSnackBarGet().showGetSucess("Success", "PDF Uploaded");
        pdfController.text = result.toString();
        isdone = true;
        // Loader remove
        Navigator.pop(context);
      } else {
        GlobalSnackBarGet().showGetError("Error", "PDF couldnt be uploaded");
        // Loader remove
        Navigator.pop(context);
        return false;
      }
    }

    return isdone;
  }

  Future<bool> UploadJpg(
      TextEditingController imgController,
      BuildContext context,
      String mainpath,
      String subpath,
      String filename) async {
    bool isdone = false;

    // check if its firebase link
    print("Checking the path in ${imgController.text}");
    String imgextension = imgController.text.toString().split(".").last;

    // String imgextension = imgController.text
    //     .toString()
    //     .substring(imgController.text.toString().length - 3);
    print("Extension is $imgextension");
    if (imgextension == "jpg" ||
        imgextension == "jpeg" ||
        imgextension == "png") {
      print("Image file to upload is: ${imgController.text}");
      int bytes = await File(imgController.text).length();
      String filesize =
          await FilesizeHelper().getFileSize(imgController.text, 2);
      if (bytes >= Constants.MAX_IMAGE_SIZE) {
        GlobalSnackBarGet().showGetError("Error",
            "${Constants.MAX_IMAGE_SIZE_MESSAGE}.\nCompressed image size is $filesize");
        return false;
      }
    } else {
      GlobalSnackBarGet()
          .showGetError("Error", "Invalid File type for image $filename");
      return false;
    }

    customalert().showLoaderDialog(context, "Uploading the image");

    // Main function to upload
    var result = await Upload_helper()
        .uploadFile(File(imgController.text), "$mainpath/$subpath/", filename);

    if (result.toString() != "null") {
      GlobalSnackBarGet().showGetSucess("Success", "Image Uploaded");
      imgController.text = result.toString();
      isdone = true;

      // Loader remove
      Navigator.pop(context);
    } else {
      GlobalSnackBarGet().showGetError("Error", "Image couldnt be uploaded");

      // Loader remove
      Navigator.pop(context);

      return false;
    }
    return isdone;
  }
}
