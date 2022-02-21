class MutableFileData {
  bool isChecked = false;
  String fileName = "";
  String extensionName = "";
  DateTime lastModified;

  MutableFileData({
    required this.isChecked,
    required this.fileName,
    required this.extensionName,
    required this.lastModified,
  });

}