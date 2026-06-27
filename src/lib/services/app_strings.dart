class AppStrings {
  final String appName;
  final String appTagline;
  final String openMap;
  final String startActivity;
  final String stopActivity;
  final String browsePoi;
  final String time;
  final String distance;
  final String avgSpeed;
  final String listen;
  final String stopListening;
  final String close;
  final String simulationLabel;
  final String mapTitleSuffix;
  final String settings;
  final String language;
  final String routeSettings;
  final String poiRetrigger;
  final String poiRetriggerDesc;
  final String voiceSettings;
  final String voiceSpeed;
  final String exitApp;
  final String exitAppConfirm;
  final String cancel;
  final String resume;
  final String pause;
  final String doubleTapToReset;
  final String trackingReset;

  const AppStrings({
    required this.appName,
    required this.appTagline,
    required this.openMap,
    required this.startActivity,
    required this.stopActivity,
    required this.browsePoi,
    required this.time,
    required this.distance,
    required this.avgSpeed,
    required this.listen,
    required this.stopListening,
    required this.close,
    required this.simulationLabel,
    required this.mapTitleSuffix,
    required this.settings,
    required this.language,
    required this.routeSettings,
    required this.poiRetrigger,
    required this.poiRetriggerDesc,
    required this.voiceSettings,
    required this.voiceSpeed,
    required this.exitApp,
    required this.exitAppConfirm,
    required this.cancel,
    required this.resume,
    required this.pause,
    required this.doubleTapToReset,
    required this.trackingReset,
  });

  static AppStrings of(String languageCode) {
    return _strings[languageCode] ?? _strings['it']!;
  }

  static final Map<String, AppStrings> _strings = {
    'it': const AppStrings(
      appName: 'Ronda Stories',
      appTagline: 'Storie lungo il percorso',
      openMap: 'Apri mappa',
      startActivity: 'Inizia percorso',
      stopActivity: 'Termina percorso',
      browsePoi: 'Esplora',
      time: 'Tempo',
      distance: 'Distanza',
      avgSpeed: 'Vel. media',
      listen: 'Ascolta',
      stopListening: 'Interrompi',
      close: 'Chiudi',
      simulationLabel: 'Simulazione movimento',
      mapTitleSuffix: ' — Mappa',
      settings: 'Impostazioni',
      language: 'Lingua',
      routeSettings: 'Percorso',
      poiRetrigger: 'Rileggi punti già visitati',
      poiRetriggerDesc: 'Mostra di nuovo il testo se ripassi vicino a un punto già visitato',
      voiceSettings: 'Voce',
      voiceSpeed: 'Velocità lettura',
      exitApp: 'Esci',
      exitAppConfirm: 'Vuoi uscire dall\'app?',
      cancel: 'Annulla',
      resume: 'Riprendi',
      pause: 'Pausa',
      doubleTapToReset: 'Riprendi · doppio tap per azzerare',
      trackingReset: 'Percorso azzerato',
    ),
    'en': const AppStrings(
      appName: 'Ronda Stories',
      appTagline: 'Stories along the way',
      openMap: 'Open map',
      startActivity: 'Start route',
      stopActivity: 'End route',
      browsePoi: 'Explore',
      time: 'Time',
      distance: 'Distance',
      avgSpeed: 'Avg. speed',
      listen: 'Listen',
      stopListening: 'Stop',
      close: 'Close',
      simulationLabel: 'Movement simulation',
      mapTitleSuffix: ' — Map',
      settings: 'Settings',
      language: 'Language',
      routeSettings: 'Route',
      poiRetrigger: 'Re-read visited points',
      poiRetriggerDesc: 'Show content again if you pass near a point you already visited',
      voiceSettings: 'Voice',
      voiceSpeed: 'Reading speed',
      exitApp: 'Exit',
      exitAppConfirm: 'Do you want to exit the app?',
      cancel: 'Cancel',
      resume: 'Resume',
      pause: 'Pause',
      doubleTapToReset: 'Resume · double tap to reset',
      trackingReset: 'Route reset',
    ),
    'zh': const AppStrings(
      appName: 'Ronda Stories',
      appTagline: '路途中的故事',
      openMap: '打开地图',
      startActivity: '开始路线',
      stopActivity: '结束路线',
      browsePoi: '探索',
      time: '时间',
      distance: '距离',
      avgSpeed: '平均速度',
      listen: '收听',
      stopListening: '停止',
      close: '关闭',
      simulationLabel: '移动模拟',
      mapTitleSuffix: ' — 地图',
      settings: '设置',
      language: '语言',
      routeSettings: '路线',
      poiRetrigger: '重新读取已访问的点',
      poiRetriggerDesc: '如果您再次经过已访问的地点，将再次显示内容',
      voiceSettings: '语音',
      voiceSpeed: '朗读速度',
      exitApp: '退出',
      exitAppConfirm: '您要退出应用程序吗？',
      cancel: '取消',
      resume: '继续',
      pause: '暂停',
      doubleTapToReset: '继续 · 双击重置',
      trackingReset: '路线已重置',
    ),
  };
}
