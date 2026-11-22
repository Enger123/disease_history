# Історія хвороб (Flutter + SQLite)

## Запуск
1. `flutter create . --org com.example --project-name med_history`  (створить android/ios; наші lib/ і pubspec.yaml залишаться)
2. `flutter pub get`
3. `dart run flutter_launcher_icons` та `dart run flutter_native_splash:create`  (іконка + нативний splash)
4. `flutter run`

## Структура
- lib/sections.dart — опис розділів (хвороби, візити, ліки); з нього генеруються таблиці, форми, списки, пошук
- lib/db.dart — SQLite (sqflite), файли копіюються в папку застосунку
- lib/auth.dart — реєстрація/вхід/видалення акаунта (SHA-256 + сіль), сесія в SharedPreferences
- lib/auth_screens.dart — екрани входу, реєстрації, видалення акаунта
- lib/home.dart — навігація, списки, глобальний пошук, профіль
- lib/edit.dart — створення/редагування запису + прикріплення файлів
