import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Multi-tracker'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get tabHome;

  /// No description provided for @tabTrain.
  ///
  /// In ru, this message translates to:
  /// **'Train'**
  String get tabTrain;

  /// No description provided for @tabTasks.
  ///
  /// In ru, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tabAI.
  ///
  /// In ru, this message translates to:
  /// **'AI'**
  String get tabAI;

  /// No description provided for @navSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get navSettings;

  /// No description provided for @actionCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get actionDelete;

  /// No description provided for @actionUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get actionUpdate;

  /// No description provided for @actionEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get actionAdd;

  /// No description provided for @actionCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get actionCreate;

  /// No description provided for @actionDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get actionDone;

  /// No description provided for @actionClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get actionBack;

  /// No description provided for @actionOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get actionOpen;

  /// No description provided for @actionRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get actionRetry;

  /// No description provided for @actionExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт'**
  String get actionExport;

  /// No description provided for @actionImport.
  ///
  /// In ru, this message translates to:
  /// **'Импорт'**
  String get actionImport;

  /// No description provided for @actionReset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get actionReset;

  /// No description provided for @actionConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get actionConfirm;

  /// No description provided for @labelToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get labelToday;

  /// No description provided for @labelTomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Завтра'**
  String get labelTomorrow;

  /// No description provided for @labelThisWeek.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get labelThisWeek;

  /// No description provided for @labelLater.
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get labelLater;

  /// No description provided for @labelNoDate.
  ///
  /// In ru, this message translates to:
  /// **'Без даты'**
  String get labelNoDate;

  /// No description provided for @labelDone.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено'**
  String get labelDone;

  /// No description provided for @labelRest.
  ///
  /// In ru, this message translates to:
  /// **'Отдых'**
  String get labelRest;

  /// No description provided for @labelKg.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get labelKg;

  /// No description provided for @labelLbs.
  ///
  /// In ru, this message translates to:
  /// **'фунты'**
  String get labelLbs;

  /// No description provided for @labelReps.
  ///
  /// In ru, this message translates to:
  /// **'повт'**
  String get labelReps;

  /// No description provided for @labelSet.
  ///
  /// In ru, this message translates to:
  /// **'Подход'**
  String get labelSet;

  /// No description provided for @labelSets.
  ///
  /// In ru, this message translates to:
  /// **'Подходы'**
  String get labelSets;

  /// No description provided for @priorityNone.
  ///
  /// In ru, this message translates to:
  /// **'нет'**
  String get priorityNone;

  /// No description provided for @priorityLow.
  ///
  /// In ru, this message translates to:
  /// **'низкий'**
  String get priorityLow;

  /// No description provided for @priorityMid.
  ///
  /// In ru, this message translates to:
  /// **'средний'**
  String get priorityMid;

  /// No description provided for @priorityHigh.
  ///
  /// In ru, this message translates to:
  /// **'высокий'**
  String get priorityHigh;

  /// No description provided for @homeGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Привет, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGoals.
  ///
  /// In ru, this message translates to:
  /// **'Цели'**
  String get homeGoals;

  /// No description provided for @homeWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес'**
  String get homeWeight;

  /// No description provided for @homeHistory.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get homeHistory;

  /// No description provided for @homeStreaks.
  ///
  /// In ru, this message translates to:
  /// **'Стрики'**
  String get homeStreaks;

  /// No description provided for @homeTodayPlan.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня по плану'**
  String get homeTodayPlan;

  /// No description provided for @homeTodayTasks.
  ///
  /// In ru, this message translates to:
  /// **'Задач на сегодня'**
  String get homeTodayTasks;

  /// No description provided for @homeRecordWeight.
  ///
  /// In ru, this message translates to:
  /// **'Записать вес'**
  String get homeRecordWeight;

  /// No description provided for @homeActiveTasks.
  ///
  /// In ru, this message translates to:
  /// **'{count} активных'**
  String homeActiveTasks(int count);

  /// No description provided for @trainWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get trainWeek;

  /// No description provided for @trainProgram.
  ///
  /// In ru, this message translates to:
  /// **'Программа'**
  String get trainProgram;

  /// No description provided for @trainStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать тренировку'**
  String get trainStart;

  /// No description provided for @trainExercises.
  ///
  /// In ru, this message translates to:
  /// **'{count} упр.'**
  String trainExercises(int count);

  /// No description provided for @trainLastTime.
  ///
  /// In ru, this message translates to:
  /// **'Прошлый раз'**
  String get trainLastTime;

  /// No description provided for @trainNote.
  ///
  /// In ru, this message translates to:
  /// **'Заметка к тренировке'**
  String get trainNote;

  /// No description provided for @trainAskAI.
  ///
  /// In ru, this message translates to:
  /// **'Спросить ИИ'**
  String get trainAskAI;

  /// No description provided for @tasksTitle.
  ///
  /// In ru, this message translates to:
  /// **'Задачи'**
  String get tasksTitle;

  /// No description provided for @tasksNotes.
  ///
  /// In ru, this message translates to:
  /// **'Заметки'**
  String get tasksNotes;

  /// No description provided for @tasksNew.
  ///
  /// In ru, this message translates to:
  /// **'Новая задача'**
  String get tasksNew;

  /// No description provided for @tasksNewNote.
  ///
  /// In ru, this message translates to:
  /// **'Новая заметка'**
  String get tasksNewNote;

  /// No description provided for @tasksWhenLabel.
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get tasksWhenLabel;

  /// No description provided for @tasksPriorityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Приоритет'**
  String get tasksPriorityLabel;

  /// No description provided for @tasksTimeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get tasksTimeLabel;

  /// No description provided for @tasksRepeatLabel.
  ///
  /// In ru, this message translates to:
  /// **'Повтор'**
  String get tasksRepeatLabel;

  /// No description provided for @tasksEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пусто.'**
  String get tasksEmpty;

  /// No description provided for @tasksEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Не работа, отдыхай.'**
  String get tasksEmptyBody;

  /// No description provided for @aiTitle.
  ///
  /// In ru, this message translates to:
  /// **'AI'**
  String get aiTitle;

  /// No description provided for @aiInputHint.
  ///
  /// In ru, this message translates to:
  /// **'Спросить…'**
  String get aiInputHint;

  /// No description provided for @aiSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get aiSend;

  /// No description provided for @aiContextAll.
  ///
  /// In ru, this message translates to:
  /// **'Всё'**
  String get aiContextAll;

  /// No description provided for @aiContextTrain.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки'**
  String get aiContextTrain;

  /// No description provided for @aiContextWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес'**
  String get aiContextWeight;

  /// No description provided for @aiContextTasks.
  ///
  /// In ru, this message translates to:
  /// **'Задачи'**
  String get aiContextTasks;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get settingsProfile;

  /// No description provided for @settingsAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Внешний вид'**
  String get settingsAppearance;

  /// No description provided for @settingsAI.
  ///
  /// In ru, this message translates to:
  /// **'ИИ'**
  String get settingsAI;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsData.
  ///
  /// In ru, this message translates to:
  /// **'Данные'**
  String get settingsData;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAbout;

  /// No description provided for @settingsTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In ru, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsAccent.
  ///
  /// In ru, this message translates to:
  /// **'Акцент'**
  String get settingsAccent;

  /// No description provided for @settingsUnits.
  ///
  /// In ru, this message translates to:
  /// **'Единицы'**
  String get settingsUnits;

  /// No description provided for @settingsGeminiKey.
  ///
  /// In ru, this message translates to:
  /// **'Gemini API Key'**
  String get settingsGeminiKey;

  /// No description provided for @settingsGeminiKeyHint.
  ///
  /// In ru, this message translates to:
  /// **'Вставь ключ из aistudio.google.com'**
  String get settingsGeminiKeyHint;

  /// No description provided for @settingsGeminiVerify.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get settingsGeminiVerify;

  /// No description provided for @settingsGeminiOk.
  ///
  /// In ru, this message translates to:
  /// **'Ключ работает'**
  String get settingsGeminiOk;

  /// No description provided for @settingsNotifAll.
  ///
  /// In ru, this message translates to:
  /// **'Все уведомления'**
  String get settingsNotifAll;

  /// No description provided for @settingsNotifTasks.
  ///
  /// In ru, this message translates to:
  /// **'Задачи'**
  String get settingsNotifTasks;

  /// No description provided for @settingsNotifWeight.
  ///
  /// In ru, this message translates to:
  /// **'Напомнить взвеситься'**
  String get settingsNotifWeight;

  /// No description provided for @settingsExportJson.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт JSON'**
  String get settingsExportJson;

  /// No description provided for @settingsExportCsv.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт CSV'**
  String get settingsExportCsv;

  /// No description provided for @settingsResetAll.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить всё'**
  String get settingsResetAll;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить все данные? Это необратимо.'**
  String get settingsResetConfirm;

  /// No description provided for @settingsVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get settingsVersion;

  /// No description provided for @settingsPlatform.
  ///
  /// In ru, this message translates to:
  /// **'Платформа'**
  String get settingsPlatform;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
