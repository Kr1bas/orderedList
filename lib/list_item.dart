import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomListItem implements Comparable<CustomListItem> {
  CustomListItem(
      {required this.text, required this.number, required this.uuid});

  factory CustomListItem.fromStorage(String uuid, List<String> item) {
    return CustomListItem(
        text: item[0], number: int.parse(item[1]), uuid: uuid);
  }

  final String uuid;
  String text;
  int number;

  void asyncSaveToStorage() async {
    SharedPreferences.getInstance()
        .then((value) => value.setStringList(uuid, [text, "$number"]));
  }

  void asyncRemoveFromStorage() async {
    SharedPreferences.getInstance().then((value) => value.remove(uuid));
  }

  @override
  int compareTo(CustomListItem other) {
    return number > other.number ? 1 : (number < other.number ? -1 : 0);
  }

  @override
  String toString({DiagnosticLevel? minLevel}) {
    return ("{$uuid : [$text,$number]}");
  }

  void updateValues(String text, int number) {
    this.text = text;
    this.number = number;
  }
}
