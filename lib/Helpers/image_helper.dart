// // ignore_for_file: use_build_context_synchronously

// import 'dart:io';
// import 'package:appoptionxi/DB_Services/database_write.dart';
// import 'package:appoptionxi/DB_Services/upload_service.dart';
// import 'package:appoptionxi/DataModels/dm_gallery.dart';
// import 'package:appoptionxi/Dialogs/custom_alert.dart';
// import 'package:appoptionxi/Helpers/constants.dart';
// import 'package:appoptionxi/Helpers/filesize_helper.dart';
// import 'package:appoptionxi/Helpers/global_snackbar_get.dart';
// import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';

// class ImageHelper {
//   Future<bool> pickSingleImage(TextEditingController imgController) async {
//     bool done = false;
//     // PickedFile? pickedFile = await ImagePicker()
//     //     .getImage(source: ImageSource.gallery, maxWidth: 1800, maxHeight: 1800);
//     // // .getImage(source: ImageSource.gallery, imageQuality: 100);
//     // //     .then((PickedFile? image) {
//     // //   image = null;
//     // // }
//     // // );

//     // if (pickedFile != null) {
//     //   File imageFile = File(pickedFile.path);
//     //   done = true;
//     //   imgController.text = imageFile.path;
//     // }

//     return done;
//   }

//   Future<String?> pickSingleImage_directly() async {
//     // PickedFile? pickedFile = await ImagePicker()
//     //     .getImage(source: ImageSource.gallery, maxWidth: 1800, maxHeight: 1800);
//     // if (pickedFile != null) {
//     //   File imageFile = File(pickedFile.path);
//     //   return imageFile.path;
//     // }
//     return null;
//   }

//   Future<bool> upload_singleImage(BuildContext context, String imagefilepath,
//       String filename, String forane, String cat) async {
//     // check if its firebase link
//     if (imagefilepath.contains(".jpg") ||
//         imagefilepath.contains(".jpeg") ||
//         imagefilepath.contains(".png")) {
//       print("PDF file to upload is: $imagefilepath");
//       int bytes = await File(imagefilepath).length();
//       String filesize = await FilesizeHelper().getFileSize(imagefilepath, 2);
//       print("File size is: $bytes");
//       if (bytes >= Constants.MAX_IMAGE_SIZE) {
//         GlobalSnackBarGet().showGetError("Error",
//             "${Constants.MAX_IMAGE_SIZE_MESSAGE}.\nCompressed image size is $filesize");

//         return false;
//       }
//     }

//     customalert().showLoaderDialog(context, "Uploading the image.");

//     if (imagefilepath.contains(".jpg") ||
//         imagefilepath.contains(".jpeg") ||
//         imagefilepath.contains(".png")) {
//       var result = await Upload_helper()
//           .uploadFile(File(imagefilepath), "gallery/$forane/$cat/", filename);

//       if (result.toString() != "null") {
//         GlobalSnackBarGet().showGetSuccess("Success", "Image Uploaded");
//         imagefilepath = result.toString();
//       } else {
//         GlobalSnackBarGet().showGetError("Error", "Image couldn't be uploaded");
//       }
//     }

//     // generate the pdf model
//     generateGallerymodel(imagefilepath, forane, cat);

//     // Loader remove
//     Navigator.pop(context);

//     // Pop the main page
//     // Navigator.pop(context);
//     return true;
//   }

//   void generateGallerymodel(String imagefilepath, String path, String section) {
//     dm_gallery gallery = dm_gallery();
//     gallery.imgurl = imagefilepath;

//     DatabaseWriteService().updateToGallery(path, gallery);
//   }
// }

// //   void pickMultipleImage() async {
// //     //  // Pick multiple images
// //     // final List<XFile>? images = await _picker.pickMultiImage();

// //     // PickedFile pickedFile = await ImagePicker().getImage(
// //     //     // source: ImageSource.gallery,
// //     //     maxWidth: 1800,
// //     //     maxHeight: 1800,
// //     // );
// //     // if (pickedFile != null) {
// //     //     File imageFile = File(pickedFile.path);
// //     // }

// //   }
// // }
