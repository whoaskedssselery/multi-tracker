// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Multi-tracker';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabTrain => 'Train';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabAI => 'AI';

  @override
  String get navSettings => 'Настройки';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionUpdate => 'Обновить';

  @override
  String get actionEdit => 'Изменить';

  @override
  String get actionAdd => 'Добавить';

  @override
  String get actionCreate => 'Создать';

  @override
  String get actionDone => 'Готово';

  @override
  String get actionClose => 'Закрыть';

  @override
  String get actionBack => 'Назад';

  @override
  String get actionOpen => 'Открыть';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get actionExport => 'Экспорт';

  @override
  String get actionImport => 'Импорт';

  @override
  String get actionReset => 'Сбросить';

  @override
  String get actionConfirm => 'Подтвердить';

  @override
  String get labelToday => 'Сегодня';

  @override
  String get labelTomorrow => 'Завтра';

  @override
  String get labelThisWeek => 'Эта неделя';

  @override
  String get labelLater => 'Позже';

  @override
  String get labelNoDate => 'Без даты';

  @override
  String get labelDone => 'Выполнено';

  @override
  String get labelRest => 'Отдых';

  @override
  String get labelKg => 'кг';

  @override
  String get labelLbs => 'фунты';

  @override
  String get labelReps => 'повт';

  @override
  String get labelSet => 'Подход';

  @override
  String get labelSets => 'Подходы';

  @override
  String get priorityNone => 'нет';

  @override
  String get priorityLow => 'низкий';

  @override
  String get priorityMid => 'средний';

  @override
  String get priorityHigh => 'высокий';

  @override
  String homeGreeting(String name) {
    return 'Привет, $name';
  }

  @override
  String get homeGoals => 'Цели';

  @override
  String get homeWeight => 'Вес';

  @override
  String get homeHistory => 'История';

  @override
  String get homeStreaks => 'Стрики';

  @override
  String get homeTodayPlan => 'Сегодня по плану';

  @override
  String get homeTodayTasks => 'Задач на сегодня';

  @override
  String get homeRecordWeight => 'Записать вес';

  @override
  String homeActiveTasks(int count) {
    return '$count активных';
  }

  @override
  String get trainWeek => 'Неделя';

  @override
  String get trainProgram => 'Программа';

  @override
  String get trainStart => 'Начать тренировку';

  @override
  String trainExercises(int count) {
    return '$count упр.';
  }

  @override
  String get trainLastTime => 'Прошлый раз';

  @override
  String get trainNote => 'Заметка к тренировке';

  @override
  String get trainAskAI => 'Спросить ИИ';

  @override
  String get tasksTitle => 'Задачи';

  @override
  String get tasksNotes => 'Заметки';

  @override
  String get tasksNew => 'Новая задача';

  @override
  String get tasksNewNote => 'Новая заметка';

  @override
  String get tasksWhenLabel => 'Когда';

  @override
  String get tasksPriorityLabel => 'Приоритет';

  @override
  String get tasksTimeLabel => 'Время';

  @override
  String get tasksRepeatLabel => 'Повтор';

  @override
  String get tasksEmpty => 'Пусто.';

  @override
  String get tasksEmptyBody => 'Не работа, отдыхай.';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiInputHint => 'Спросить…';

  @override
  String get aiSend => 'Отправить';

  @override
  String get aiContextAll => 'Всё';

  @override
  String get aiContextTrain => 'Тренировки';

  @override
  String get aiContextWeight => 'Вес';

  @override
  String get aiContextTasks => 'Задачи';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsProfile => 'Профиль';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsAI => 'ИИ';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsData => 'Данные';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAccent => 'Акцент';

  @override
  String get settingsUnits => 'Единицы';

  @override
  String get settingsGeminiKey => 'Gemini API Key';

  @override
  String get settingsGeminiKeyHint => 'Вставь ключ из aistudio.google.com';

  @override
  String get settingsGeminiVerify => 'Проверить';

  @override
  String get settingsGeminiOk => 'Ключ работает';

  @override
  String get settingsNotifAll => 'Все уведомления';

  @override
  String get settingsNotifTasks => 'Задачи';

  @override
  String get settingsNotifWeight => 'Напомнить взвеситься';

  @override
  String get settingsExportJson => 'Экспорт JSON';

  @override
  String get settingsExportCsv => 'Экспорт CSV';

  @override
  String get settingsResetAll => 'Сбросить всё';

  @override
  String get settingsResetConfirm => 'Удалить все данные? Это необратимо.';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsPlatform => 'Платформа';
}
