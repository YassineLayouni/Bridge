import 'package:bridge/Globals/Dialogs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart' as GetX;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'dart:convert';

class UploadAudioController extends GetX.GetxController {
  PlatformFile? audio;
  WebSocketChannel? channel;
  GetX.RxString language = "en".obs;
  GetX.RxBool translating = false.obs;
  GetX.RxList<Map<String, dynamic>> result = <Map<String, dynamic>>[].obs;

  void reset() {
    channel = null;
    language.value = "en";
    translating.value = false;
    result.value = [];
  }

  void translate() async {
    if (audio != null) {
      Dialogs.uploadingDialog();
      reset();
      try {
        channel = WebSocketChannel.connect(
          Uri.parse('ws://192.168.1.19:8764'),
        );
        File audioFile = File(audio!.path!);
        final fileStream = audioFile.openRead();
        await for (var chunk in fileStream) {
          channel?.sink.add(chunk);
        }
        channel?.sink.add("_DONE_");
        // Listen for result back
        translating.value = true;
        channel?.stream.listen((message) {
          if (message is String) {
            if (message == "_UPLOAD_COMPLETE_") {
              GetX.Get.back();
            } else if (message == "_DONE_") {
              channel?.sink.close();
            } else {
              result.value.add(jsonDecode(message) as Map<String, dynamic>);
            }
          }
        }, onDone: () {
          translating.value = false;
        });
      } catch (e) {
        print('Error sending audio: $e');
        if(channel != null) {
          channel?.sink.close();
        }
        GetX.Get.back();
        translating.value = false;
      }
    }
  }
}
