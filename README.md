# fumospots_app
[![Flutter](https://img.shields.io/badge/Flutter-3.13.5-blue?style=flat-square&logo=flutter)](https://flutter.dev)&nbsp;
[![Maplibre](https://img.shields.io/badge/Maplibre-0.3.6-blue?style=flat-square&logo=maplibre)](https://maplibre.org)&nbsp;

This is a third-party app for [fumospots](https://fumo.touhouspots.com) website. ([repo](https://github.com/Eitrous/fumospots))


# Getting Started.
pull up your flutter 3.13.5 [install](https://docs.flutter.dev/install/quick) on any machine you want

open your dumbass terminal and goto the project root and:
```sh
flutter pub get
```
and run:
```sh
flutter run -d <platform-id>
```
possible candidates are `android`, `ios`, `windows`, `macos` and `linux` but no one cares about desktop platforms.

# Building.
Android:
```sh
flutter build apk
flutter build apk --split-per-abi
```
Ios:
```sh
flutter build ipa
```
etc.

refer to https://docs.flutter.dev/ for more details.
