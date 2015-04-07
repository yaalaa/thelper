# thelper
Helps to connect developers and translators.

In particular it help to cover to typical use-cases:
..*to provide translators with texts to translate
..*to incorporate texts came from those translators

Source codes and resources are likely complicated. 
Translators are usually too far from app sources.
So we are used to send texts in data sheets (CSV, Excel, ODS, etc.).

The tool now uses CSV to export and import texts.

## How to export not-translated texts for a partuclar language
`thelper.pl n --android <path_to_android_app_project> --lang es --out-csv <path_to_csv>`

..*path_to_android_app_project is path at which android app project resides
..*"es" langauge is just an example, of course.
..*path_to_csv is path to write exported CSV to

## How to import new translations for a particular langauge
`thelper.pl a --android <path_to_android_app_project> --lang es --in-csv <path_to_csv> --out-xml <path_to_xml>`

..*path_to_android_app_project is path at which android app project resides
..*"es" langauge is just an example, again.
..*path_to_csv is path to CSV file to read importing texts from
..*path_to_xml is path to write new string resource XML file to

## The tool is very simple and straght forward
Indeed, it is.
The tool doesn't cover whole variety of Android project string resources.
Instead it assumes the following:
..*texts are kept in strings.xml files, i.e. tool to look at the following files only
..*value folder language modificator is the only modificator, e.g. values-es-sw600dp is not the case

Freaky string resource case could be convered by using aliases.
Texts marked as non-translatable is skipped.
And `xliff:g` is ignored.

## How about iOS
Yup, Android app project was just an example.
The tool could work with iOS app project.
Just use `--ios` option instead of `--android`.

For iOS app project the tool works with `lang>.lproj/Localizable.strings` (`Localizable.stringsdict` will come I hope).
`en.lproj` is treated as the default translation.



