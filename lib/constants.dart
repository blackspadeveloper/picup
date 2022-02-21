import 'dart:io';

class Constants {

  static const String lock = "LOCK";
  static const String lockType = "LOCK_TYPE";

  static const String pin = "PIN";
  static const String finger = "FINGER";
  static const String face = "FACE";

  static const String pinPassword = "PIN_PASSWORD";


  static String get bannerAdUnitId {
    String sdkId = "";
    if (Platform.isIOS) {
      sdkId = 'ca-app-pub-3940256099942544/2934735716'; // 아직 설정 안함
    } else if (Platform.isAndroid) {
      sdkId = 'ca-app-pub-2263794927909840/2877815360'; // 설정함(SDK ID, AndroidManifest : AppID)
    }
    return sdkId;
  }

  static String get testAdUnitId {
    String sdkId = "";
    if (Platform.isAndroid) {
      sdkId = 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      sdkId = 'ca-app-pub-3940256099942544/2934735716';
    }
    return sdkId;
  }

  // command+control+space
  static const String usableContents =
      "■ 잠금설정 : 상단 오른쪽 설정 아이콘︎ 선택 > 잠금설정(ON/OFF) 설정 > 간편비밀번호 또는 지문 선택 후 설정\n"
      "■ 파일생성 : 상단 오른쪽 카메라 아이콘 선택 > 갤러리 또는 카메라 선택\n"
      "\t\t○ 갤러리 > 사진 선택 > 사진 편집(옵션사항) > 텍스트 확인영 > 파일 저장\n"
      "\t\t○ 카메라 > 사진 촬 > 사진 편집(옵션사항) > 텍스트 확인 > 파일 저장\n\n"
      "\t* 파일은 별도의 저장이 필요없으며(앱내 저장), 앱 삭제시에는 파일이 같이 삭제될 수 있으므로 별도 저장을 원하시면 파일 열기한 애플리케이션에서 원하시는 저장소에 저장하시기 바랍니다.\n "
  ;

  static const String copyRight = '© 2022. AcroX Co. all rights reserved.';

}