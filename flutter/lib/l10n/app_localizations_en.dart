// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Multi-tracker';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTrain => 'Train';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabAI => 'AI';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionUpdate => 'Update';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionDone => 'Done';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionExport => 'Export';

  @override
  String get actionImport => 'Import';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get labelToday => 'Today';

  @override
  String get labelTomorrow => 'Tomorrow';

  @override
  String get labelThisWeek => 'This week';

  @override
  String get labelLater => 'Later';

  @override
  String get labelNoDate => 'No date';

  @override
  String get labelDone => 'Done';

  @override
  String get labelRest => 'Rest';

  @override
  String get labelKg => 'kg';

  @override
  String get labelLbs => 'lbs';

  @override
  String get labelReps => 'reps';

  @override
  String get labelSet => 'Set';

  @override
  String get labelSets => 'Sets';

  @override
  String get priorityNone => 'none';

  @override
  String get priorityLow => 'low';

  @override
  String get priorityMid => 'medium';

  @override
  String get priorityHigh => 'high';

  @override
  String homeGreeting(String name) {
    return 'Hey, $name';
  }

  @override
  String get homeGoals => 'Goals';

  @override
  String get homeWeight => 'Weight';

  @override
  String get homeHistory => 'History';

  @override
  String get homeStreaks => 'Streaks';

  @override
  String get homeTodayPlan => 'Today\'s plan';

  @override
  String get homeTodayTasks => 'Today\'s tasks';

  @override
  String get homeRecordWeight => 'Log weight';

  @override
  String homeActiveTasks(int count) {
    return '$count active';
  }

  @override
  String get trainWeek => 'Week';

  @override
  String get trainProgram => 'Program';

  @override
  String get trainStart => 'Start workout';

  @override
  String trainExercises(int count) {
    return '$count exercises';
  }

  @override
  String get trainLastTime => 'Last time';

  @override
  String get trainNote => 'Workout note';

  @override
  String get trainAskAI => 'Ask AI';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksNotes => 'Notes';

  @override
  String get tasksNew => 'New task';

  @override
  String get tasksNewNote => 'New note';

  @override
  String get tasksWhenLabel => 'When';

  @override
  String get tasksPriorityLabel => 'Priority';

  @override
  String get tasksTimeLabel => 'Time';

  @override
  String get tasksRepeatLabel => 'Repeat';

  @override
  String get tasksEmpty => 'All clear.';

  @override
  String get tasksEmptyBody => 'Nothing left to do.';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiInputHint => 'Ask anything…';

  @override
  String get aiSend => 'Send';

  @override
  String get aiContextAll => 'All';

  @override
  String get aiContextTrain => 'Training';

  @override
  String get aiContextWeight => 'Weight';

  @override
  String get aiContextTasks => 'Tasks';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAI => 'AI';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAccent => 'Accent colour';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsGroqKey => 'Groq API Key';

  @override
  String get settingsGroqKeyHint => 'Paste key from console.groq.com';

  @override
  String get settingsGroqVerify => 'Verify';

  @override
  String get settingsGroqOk => 'Key is working';

  @override
  String get settingsNotifAll => 'All notifications';

  @override
  String get settingsNotifTasks => 'Task reminders';

  @override
  String get settingsNotifWeight => 'Weight reminder';

  @override
  String get settingsExportJson => 'Export JSON';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get settingsResetAll => 'Reset everything';

  @override
  String get settingsResetConfirm => 'Delete all data? This cannot be undone.';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPlatform => 'Platform';
}
