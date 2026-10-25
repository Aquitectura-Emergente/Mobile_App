import 'package:flutter/foundation.dart';

import 'app_settings_store.dart';

/// Lightweight EN/ES i18n for the mobile app (mirrors the web's LanguageService).
///
/// Usage: `tr('set_title')`. The language toggle lives in Settings and is
/// persisted locally. Screens re-read strings on rebuild; the bottom nav uses
/// pushReplacement so every tab change re-renders with the current language.
class I18n {
  static final ValueNotifier<String> lang = ValueNotifier<String>('en');

  static void init() {
    lang.value = AppSettingsStore.language;
  }

  static void set(String value) {
    lang.value = value;
    AppSettingsStore.language = value;
  }

  static void toggle() => set(lang.value == 'en' ? 'es' : 'en');

  static String t(String key) {
    final table = lang.value == 'es' ? _es : _en;
    return table[key] ?? _en[key] ?? key;
  }
}

/// Shorthand used across screens.
String tr(String key) => I18n.t(key);

const Map<String, String> _en = {
  // Common
  'common_retry': 'Retry',
  'common_cancel': 'Cancel',
  'common_save': 'Save',
  'common_close': 'Close',
  'common_refresh': 'Refresh',
  'common_loading': 'Loading...',
  'common_confirm': 'Confirm',

  // Bottom nav
  'nav_home': 'Home',
  'nav_monitor': 'Monitor',
  'nav_vitals': 'Vitals',
  'nav_alerts': 'Alerts',
  'nav_settings': 'Settings',

  // Dashboard
  'dash_subtitle': 'Radiation exposure monitoring live',
  'dash_errLoad': 'Could not load your dashboard.',
  'dash_average': 'Average',
  'dash_avgCaption': 'average',
  'dash_peak': 'Peak',
  'dash_peakCaption': 'highest reading',
  'dash_online': 'Online sensors',
  'dash_reporting': 'reporting',
  'dash_alerts': 'Alerts',
  'dash_needReview': 'need review',
  'dash_activeZones': 'ACTIVE ZONES',
  'dash_noSensors':
      'No sensors registered yet. Contact your EMSafe administrator to have your devices assigned.',
  'dash_stable': 'Daily exposure remains stable',
  'dash_aboveSafe': 'reading(s) above the safe level',
  'dash_noSpikes': 'No critical spikes detected across your sensors.',
  'dash_openAlerts': 'Open the Alerts tab to review the affected sensors.',
  'dash_currentExposure': 'Current exposure',
  'dash_msgSafe':
      'Your facility is inside the recommended radiation threshold.',
  'dash_msgCaution':
      'Radiation is elevated in one or more zones. Keep monitoring.',
  'dash_msgDanger':
      'Radiation exceeded the safe threshold. Review your sensors.',
  'dash_noReadings': 'No readings',

  // Monitor
  'mon_title': 'Monitor',
  'mon_subtitle': 'Live sensor monitoring',
  'mon_errLoad': 'Could not load sensor data.',
  'mon_noSensors':
      'You have no sensors assigned yet. Once your administrator assigns a device to your account it will appear here.',
  'mon_yourSensors': 'YOUR SENSORS',
  'mon_latest': 'Latest',
  'mon_reading': 'reading',
  'mon_readings': 'Readings',
  'mon_records': 'records stored',
  'mon_type': 'Type',
  'mon_status': 'Status',
  'mon_powerControl': 'POWER CONTROL',
  'mon_signalTrend': 'SIGNAL TREND',
  'mon_recentReadings': 'RECENT READINGS',
  'mon_recentTitle': 'Recent readings',
  'mon_noChart': 'No readings to chart yet.',
  'mon_peakWindow': 'Peak in this window:',
  'mon_noReadingsYet': 'No readings recorded for this sensor yet.',
  'mon_powerOn': 'Power connected',
  'mon_powerOff': 'Power cut off',
  'mon_noRelayState': 'Device has not reported its relay state yet.',
  'mon_relayReports': 'Device reports relay',
  'mon_relayToggleHint': 'Toggle to open/close the current.',
  'mon_updated': 'Updated',
  'mon_noData': 'No data yet',
  'mon_online': 'ONLINE',

  // Vitals (health tips)
  'vit_title': 'Electromagnetic Health',
  'vit_subtitle': 'Learn to reduce your daily exposure and protect your wellbeing.',
  'vit_currentRisk': 'CURRENT RISK',
  'vit_riskLow': 'Low risk',
  'vit_riskLowTitle': 'Exposure under control',
  'vit_riskLowDesc':
      'Keep your preventive habits and review occasional alerts.',
  'vit_riskMod': 'Moderate risk',
  'vit_riskModTitle': 'Take precautions',
  'vit_riskModDesc':
      'There is frequent exposure in your environment. Small daily changes can reduce the risk.',
  'vit_riskHigh': 'High risk',
  'vit_riskHighTitle': 'Reduce exposure',
  'vit_riskHighDesc':
      'Move away from nearby sources and review your frequent zones.',
  'vit_summaryLow':
      'Your environment shows a low exposure level. These habits help you keep it that way.',
  'vit_summaryMod':
      'Your environment shows a moderate exposure level. Review these recommendations to lower the risk.',
  'vit_summaryHigh':
      'Your environment shows a high exposure level. Apply these recommendations as soon as possible.',
  'vit_levels': 'RISK LEVELS',
  'vit_lvLow': 'Low',
  'vit_lvMid': 'Medium',
  'vit_lvHigh': 'High',
  'vit_categories': 'COMMON EXPOSURE SOURCES',
  'vit_catSleep': 'Sleep and rest',
  'vit_catSleepDesc':
      'Sleeping with your phone very close can increase exposure for several hours in a row.',
  'vit_catDevices': 'Prolonged device use',
  'vit_catDevicesDesc':
      'Using equipment without breaks keeps exposure close to your body for longer.',
  'vit_catRouters': 'Routers and nearby sources',
  'vit_catRoutersDesc':
      'Staying next to routers or active equipment can raise your daily exposure.',
  'vit_catZones': 'Higher radiation zones',
  'vit_catZonesDesc':
      'Some frequent zones can accumulate higher readings than others during the day.',
  'vit_tips': 'RECOMMENDATIONS',
  'vit_impactHigh': 'High impact',
  'vit_impactMid': 'Medium impact',
  'vit_impactLow': 'Low impact',
  'vit_tip1': 'Keep your phone away while you sleep.',
  'vit_tip1Why': 'Removes several hours of close exposure during the night.',
  'vit_tip2': 'Avoid staying near the router for long periods.',
  'vit_tip2Why': 'Moving a few meters away reduces continuous exposure.',
  'vit_tip3': 'Reduce continuous device use when the level is high.',
  'vit_tip3Why': 'Breaks help limit your total exposure time.',
  'vit_tip4': 'Review exposure alerts in your frequent zones.',
  'vit_tip4Why': 'Spotting patterns enables better daily decisions.',
  'vit_tip5': 'Enable reminders or preventive breaks.',
  'vit_tip5Why': 'Small sustained habits help keep the risk low.',

  // Alerts
  'al_title': 'Alert History',
  'al_subtitle': 'Review exposure events and status changes',
  'al_errLoad': 'Could not load your alerts.',
  'al_empty': 'No alerts yet. Your sensors are within safe levels.',
  'al_events': 'EVENTS',
  'al_eventsLogged': 'event(s) logged',
  'al_highNeedReview': 'high priority alert(s) need review.',
  'al_noHigh': 'No high priority alerts right now.',
  'al_high': 'High',
  'al_medium': 'Medium',
  'al_total': 'Total',

  // Settings
  'set_title': 'Settings',
  'set_subtitle': 'System preferences and sensor controls',
  'set_errLoad': 'Could not load settings.',
  'set_preferences': 'PREFERENCES',
  'set_push': 'Push alerts',
  'set_pushSub': 'Notify when exposure reaches DANGER',
  'set_calib': 'Auto calibration',
  'set_calibSub': 'Refresh sensor baseline overnight',
  'set_cloud': 'Cloud sync',
  'set_cloudSub': 'Back up readings and room profiles',
  'set_language': 'Language',
  'set_langSub': 'English / Español',
  'set_sensors': 'SENSORS',
  'set_noSensors': 'No sensors assigned to your account yet.',
  'set_maintenance': 'MAINTENANCE',
  'set_account': 'ACCOUNT',
  'set_editProfile': 'Edit profile',
  'set_editProfileSub': 'Name, phone and location',
  'set_changePw': 'Change password',
  'set_changePwSub': 'Update your access credentials',
  'set_export': 'Export data history',
  'set_exportSub': 'Share your readings as CSV',
  'set_exportEmpty': 'There are no readings to export yet.',
  'set_deviceInfo': 'Device information',
  'set_deviceInfoSub': 'Serial numbers and install dates',
  'set_signOut': 'Sign out',
  'set_signOutSub': 'End this secure session',
  'set_deleteAccount': 'Delete account',
  'set_deleteAccountSub': 'Permanently remove your personal data',
  'set_online': 'Online',
  'set_syncOk': 'SYNC OK',
  'set_offline': 'OFFLINE',
  'set_monitored': 'monitored',
  'set_sensor': 'sensor',
  'set_sensors_lc': 'sensors',
  'set_myAccount': 'My account',
  'set_serial': 'Serial',
  'set_type': 'Type',
  'set_installed': 'Installed',
  'set_status': 'Status',

  // Edit profile
  'prof_title': 'Edit Profile',
  'prof_subtitle': 'Update your personal information',
  'prof_name': 'Full name',
  'prof_phone': 'Phone',
  'prof_location': 'Location',
  'prof_address': 'Address',
  'prof_saved': 'Profile updated',
  'prof_nameRequired': 'Name is required',

  // Change password
  'pw_title': 'Change Password',
  'pw_subtitle': 'Update your access credentials',
  'pw_current': 'Current password',
  'pw_new': 'New password',
  'pw_confirm': 'Confirm new password',
  'pw_mismatch': 'Passwords do not match',
  'pw_tooShort': 'Minimum 6 characters',
  'pw_saved': 'Password updated',

  // Chat (Astra)
  'chat_title': 'Astra AI Assistant',
  'chat_subtitle': 'Ask about your exposure and sensors',
  'chat_hint': 'Ask Astra something...',
  'chat_welcome':
      'Hi! I\'m Astra, your EMSafe assistant. Ask me about your current '
          'exposure, your sensors, or how to reduce electromagnetic risk.',
  'chat_error': 'Astra could not answer. Check your connection and try again.',

  // Dashboard quick actions
  'dash_qaReports': 'Reports',
  'dash_qaMap': 'Map',
  'dash_qaAstra': 'Astra',

  // Map
  'map_title': 'Radiation Map',
  'map_subtitle': 'Your site and sensors, color-coded by level',
  'map_errLoad': 'Could not load the map data.',
  'map_all': 'All',
  'map_safe': 'Safe',
  'map_caution': 'Caution',
  'map_danger': 'Danger',
  'map_noneForFilter': 'No sensors match this filter.',

  // Reports
  'rep_title': 'Radiation Reports',
  'rep_subtitle': 'Monthly and yearly exposure summaries',
  'rep_month': 'Monthly',
  'rep_year': 'Yearly',
  'rep_avg': 'Average',
  'rep_peak': 'Peak',
  'rep_readings': 'Readings',
  'rep_alerts': 'Alerts',
  'rep_trend': 'EXPOSURE TREND',
  'rep_detail': 'DETAIL',
  'rep_empty': 'No readings in this period yet.',
  'rep_errLoad': 'Could not load the report.',
  'rep_open': 'Reports',

  // Notifications
  'notif_dangerTitle': '⚠ Radiation DANGER detected',

  // Danger power-cut modal
  'danger_modalTitle': 'Dangerous radiation detected',
  'danger_modalBody':
      'Radiation reached a DANGER level on this sensor. Do you want to cut the power connected to it?',
  'danger_cutPower': 'Cut the power',
  'danger_keepOn': 'Keep it on',

  // Relative time
  'time_justNow': 'just now',
  'time_ago_fmt': '{n} {u} ago',

  // Delete account
  'del_title': 'Delete account',
  'del_warning':
      'This permanently deletes your account and personal data. Your sensors will be unlinked. This cannot be undone.',
  'del_confirmPw': 'Enter your password to confirm',
  'del_button': 'Delete my account',
  'del_done': 'Your account has been deleted.',
};

const Map<String, String> _es = {
  // Common
  'common_retry': 'Reintentar',
  'common_cancel': 'Cancelar',
  'common_save': 'Guardar',
  'common_close': 'Cerrar',
  'common_refresh': 'Actualizar',
  'common_loading': 'Cargando...',
  'common_confirm': 'Confirmar',

  // Bottom nav
  'nav_home': 'Inicio',
  'nav_monitor': 'Monitor',
  'nav_vitals': 'Salud',
  'nav_alerts': 'Alertas',
  'nav_settings': 'Ajustes',

  // Dashboard
  'dash_subtitle': 'Monitoreo de exposición en tiempo real',
  'dash_errLoad': 'No se pudo cargar tu dashboard.',
  'dash_average': 'Promedio',
  'dash_avgCaption': 'promedio',
  'dash_peak': 'Pico',
  'dash_peakCaption': 'lectura más alta',
  'dash_online': 'Sensores en línea',
  'dash_reporting': 'reportando',
  'dash_alerts': 'Alertas',
  'dash_needReview': 'por revisar',
  'dash_activeZones': 'ZONAS ACTIVAS',
  'dash_noSensors':
      'Aún no tienes sensores registrados. Contacta a tu administrador EMSafe para que asigne tus dispositivos.',
  'dash_stable': 'La exposición diaria se mantiene estable',
  'dash_aboveSafe': 'lectura(s) por encima del nivel seguro',
  'dash_noSpikes': 'No se detectaron picos críticos en tus sensores.',
  'dash_openAlerts': 'Abre la pestaña Alertas para revisar los sensores afectados.',
  'dash_currentExposure': 'Exposición actual',
  'dash_msgSafe':
      'Tu instalación está dentro del umbral de radiación recomendado.',
  'dash_msgCaution':
      'La radiación está elevada en una o más zonas. Sigue monitoreando.',
  'dash_msgDanger':
      'La radiación superó el umbral seguro. Revisa tus sensores.',
  'dash_noReadings': 'Sin lecturas',

  // Monitor
  'mon_title': 'Monitor',
  'mon_subtitle': 'Monitoreo del sensor en vivo',
  'mon_errLoad': 'No se pudieron cargar los datos del sensor.',
  'mon_noSensors':
      'Aún no tienes sensores asignados. Cuando tu administrador asigne un dispositivo a tu cuenta aparecerá aquí.',
  'mon_yourSensors': 'TUS SENSORES',
  'mon_latest': 'Última',
  'mon_reading': 'lectura',
  'mon_readings': 'Lecturas',
  'mon_records': 'registros guardados',
  'mon_type': 'Tipo',
  'mon_status': 'Estado',
  'mon_powerControl': 'CONTROL DE CORRIENTE',
  'mon_signalTrend': 'TENDENCIA DE SEÑAL',
  'mon_recentReadings': 'LECTURAS RECIENTES',
  'mon_recentTitle': 'Lecturas recientes',
  'mon_noChart': 'Aún no hay lecturas para graficar.',
  'mon_peakWindow': 'Pico en esta ventana:',
  'mon_noReadingsYet': 'Este sensor aún no registra lecturas.',
  'mon_powerOn': 'Corriente conectada',
  'mon_powerOff': 'Corriente cortada',
  'mon_noRelayState': 'El dispositivo aún no reporta el estado de su relé.',
  'mon_relayReports': 'El dispositivo reporta relé',
  'mon_relayToggleHint': 'Usa el switch para abrir/cerrar la corriente.',
  'mon_updated': 'Actualizado',
  'mon_noData': 'Sin datos aún',
  'mon_online': 'EN LÍNEA',

  // Vitals
  'vit_title': 'Salud Electromagnética',
  'vit_subtitle': 'Aprende a reducir tu exposición diaria y cuida tu bienestar.',
  'vit_currentRisk': 'RIESGO ACTUAL',
  'vit_riskLow': 'Riesgo bajo',
  'vit_riskLowTitle': 'Exposición controlada',
  'vit_riskLowDesc':
      'Mantener hábitos preventivos y revisar alertas ocasionales.',
  'vit_riskMod': 'Riesgo moderado',
  'vit_riskModTitle': 'Tomar precauciones',
  'vit_riskModDesc':
      'Hay exposición frecuente en tu entorno. Pequeños cambios diarios pueden reducir el riesgo.',
  'vit_riskHigh': 'Riesgo alto',
  'vit_riskHighTitle': 'Reducir exposición',
  'vit_riskHighDesc':
      'Alejarse de fuentes cercanas y revisar zonas frecuentes.',
  'vit_summaryLow':
      'Tu entorno presenta un nivel bajo de exposición. Estos hábitos te ayudan a mantenerlo así.',
  'vit_summaryMod':
      'Tu entorno presenta un nivel moderado de exposición. Revisa estas recomendaciones para disminuir el riesgo.',
  'vit_summaryHigh':
      'Tu entorno presenta un nivel alto de exposición. Aplica estas recomendaciones lo antes posible.',
  'vit_levels': 'NIVELES DE RIESGO',
  'vit_lvLow': 'Bajo',
  'vit_lvMid': 'Medio',
  'vit_lvHigh': 'Alto',
  'vit_categories': 'FUENTES COMUNES DE EXPOSICIÓN',
  'vit_catSleep': 'Sueño y descanso',
  'vit_catSleepDesc':
      'Dormir con el celular muy cerca puede aumentar la exposición durante varias horas seguidas.',
  'vit_catDevices': 'Uso prolongado de dispositivos',
  'vit_catDevicesDesc':
      'Usar equipos sin pausas mantiene la exposición cerca del cuerpo por más tiempo.',
  'vit_catRouters': 'Routers y fuentes cercanas',
  'vit_catRoutersDesc':
      'Permanecer junto a routers o equipos activos puede elevar la exposición diaria.',
  'vit_catZones': 'Zonas de mayor radiación',
  'vit_catZonesDesc':
      'Algunas zonas frecuentes pueden acumular lecturas más altas que otras durante el día.',
  'vit_tips': 'RECOMENDACIONES',
  'vit_impactHigh': 'Alto impacto',
  'vit_impactMid': 'Medio impacto',
  'vit_impactLow': 'Bajo impacto',
  'vit_tip1': 'Mantén el celular alejado mientras duermes.',
  'vit_tip1Why': 'Reduce varias horas de exposición cercana durante la noche.',
  'vit_tip2': 'Evita permanecer mucho tiempo cerca del router.',
  'vit_tip2Why': 'Alejarte unos metros disminuye la exposición continua.',
  'vit_tip3': 'Reduce el uso continuo de dispositivos cuando el nivel sea alto.',
  'vit_tip3Why': 'Las pausas ayudan a limitar el tiempo total de exposición.',
  'vit_tip4': 'Revisa las alertas de exposición en zonas frecuentes.',
  'vit_tip4Why': 'Identificar patrones permite tomar mejores decisiones diarias.',
  'vit_tip5': 'Activa recordatorios o pausas preventivas.',
  'vit_tip5Why': 'Pequeños hábitos sostenidos ayudan a mantener el riesgo bajo.',

  // Alerts
  'al_title': 'Historial de Alertas',
  'al_subtitle': 'Revisa eventos de exposición y cambios de estado',
  'al_errLoad': 'No se pudieron cargar tus alertas.',
  'al_empty': 'Sin alertas por ahora. Tus sensores están en niveles seguros.',
  'al_events': 'EVENTOS',
  'al_eventsLogged': 'evento(s) registrados',
  'al_highNeedReview': 'alerta(s) de alta prioridad por revisar.',
  'al_noHigh': 'No hay alertas de alta prioridad por ahora.',
  'al_high': 'Altas',
  'al_medium': 'Medias',
  'al_total': 'Total',

  // Settings
  'set_title': 'Ajustes',
  'set_subtitle': 'Preferencias del sistema y control de sensores',
  'set_errLoad': 'No se pudieron cargar los ajustes.',
  'set_preferences': 'PREFERENCIAS',
  'set_push': 'Alertas push',
  'set_pushSub': 'Notificar cuando la exposición llegue a PELIGRO',
  'set_calib': 'Calibración automática',
  'set_calibSub': 'Recalibra la base del sensor cada noche',
  'set_cloud': 'Sincronización en la nube',
  'set_cloudSub': 'Respalda lecturas y perfiles de ambientes',
  'set_language': 'Idioma',
  'set_langSub': 'English / Español',
  'set_sensors': 'SENSORES',
  'set_noSensors': 'Aún no tienes sensores asignados a tu cuenta.',
  'set_maintenance': 'MANTENIMIENTO',
  'set_account': 'CUENTA',
  'set_editProfile': 'Editar perfil',
  'set_editProfileSub': 'Nombre, teléfono y ubicación',
  'set_changePw': 'Cambiar contraseña',
  'set_changePwSub': 'Actualiza tus credenciales de acceso',
  'set_export': 'Exportar historial de datos',
  'set_exportSub': 'Comparte tus lecturas en CSV',
  'set_exportEmpty': 'Aún no hay lecturas para exportar.',
  'set_deviceInfo': 'Información de dispositivos',
  'set_deviceInfoSub': 'Números de serie y fechas de instalación',
  'set_signOut': 'Cerrar sesión',
  'set_signOutSub': 'Termina esta sesión segura',
  'set_deleteAccount': 'Eliminar cuenta',
  'set_deleteAccountSub': 'Borra permanentemente tus datos personales',
  'set_online': 'En línea',
  'set_syncOk': 'SINC OK',
  'set_offline': 'SIN CONEXIÓN',
  'set_monitored': 'monitoreado(s)',
  'set_sensor': 'sensor',
  'set_sensors_lc': 'sensores',
  'set_myAccount': 'Mi cuenta',
  'set_serial': 'Serie',
  'set_type': 'Tipo',
  'set_installed': 'Instalado',
  'set_status': 'Estado',

  // Edit profile
  'prof_title': 'Editar Perfil',
  'prof_subtitle': 'Actualiza tu información personal',
  'prof_name': 'Nombre completo',
  'prof_phone': 'Teléfono',
  'prof_location': 'Ubicación',
  'prof_address': 'Dirección',
  'prof_saved': 'Perfil actualizado',
  'prof_nameRequired': 'El nombre es obligatorio',

  // Change password
  'pw_title': 'Cambiar Contraseña',
  'pw_subtitle': 'Actualiza tus credenciales de acceso',
  'pw_current': 'Contraseña actual',
  'pw_new': 'Nueva contraseña',
  'pw_confirm': 'Confirmar nueva contraseña',
  'pw_mismatch': 'Las contraseñas no coinciden',
  'pw_tooShort': 'Mínimo 6 caracteres',
  'pw_saved': 'Contraseña actualizada',

  // Chat (Astra)
  'chat_title': 'Asistente Astra AI',
  'chat_subtitle': 'Pregunta sobre tu exposición y sensores',
  'chat_hint': 'Pregúntale algo a Astra...',
  'chat_welcome':
      '¡Hola! Soy Astra, tu asistente EMSafe. Pregúntame sobre tu exposición '
          'actual, tus sensores o cómo reducir el riesgo electromagnético.',
  'chat_error': 'Astra no pudo responder. Revisa tu conexión e intenta de nuevo.',

  // Dashboard quick actions
  'dash_qaReports': 'Reportes',
  'dash_qaMap': 'Mapa',
  'dash_qaAstra': 'Astra',

  // Map
  'map_title': 'Mapa de Radiación',
  'map_subtitle': 'Tu sede y sensores, coloreados por nivel',
  'map_errLoad': 'No se pudieron cargar los datos del mapa.',
  'map_all': 'Todos',
  'map_safe': 'Seguro',
  'map_caution': 'Precaución',
  'map_danger': 'Peligro',
  'map_noneForFilter': 'Ningún sensor coincide con este filtro.',

  // Reports
  'rep_title': 'Reportes de Radiación',
  'rep_subtitle': 'Resúmenes de exposición mensual y anual',
  'rep_month': 'Mensual',
  'rep_year': 'Anual',
  'rep_avg': 'Promedio',
  'rep_peak': 'Pico',
  'rep_readings': 'Lecturas',
  'rep_alerts': 'Alertas',
  'rep_trend': 'TENDENCIA DE EXPOSICIÓN',
  'rep_detail': 'DETALLE',
  'rep_empty': 'Aún no hay lecturas en este periodo.',
  'rep_errLoad': 'No se pudo cargar el reporte.',
  'rep_open': 'Reportes',

  // Notifications
  'notif_dangerTitle': '⚠ PELIGRO de radiación detectado',

  // Danger power-cut modal
  'danger_modalTitle': 'Radiación peligrosa detectada',
  'danger_modalBody':
      'La radiación alcanzó un nivel de PELIGRO en este sensor. ¿Deseas cortar la corriente conectada a él?',
  'danger_cutPower': 'Cortar la corriente',
  'danger_keepOn': 'Mantener encendido',

  // Relative time
  'time_justNow': 'ahora mismo',
  'time_ago_fmt': 'hace {n} {u}',

  // Delete account
  'del_title': 'Eliminar cuenta',
  'del_warning':
      'Esto elimina permanentemente tu cuenta y tus datos personales. Tus sensores quedarán sin vincular. No se puede deshacer.',
  'del_confirmPw': 'Ingresa tu contraseña para confirmar',
  'del_button': 'Eliminar mi cuenta',
  'del_done': 'Tu cuenta ha sido eliminada.',
};
