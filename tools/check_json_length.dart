import "dart:io"; void main() async { final file = File("lib/golf_courses_sweden.json"); final content = await file.readAsString(); print(content.length); }
