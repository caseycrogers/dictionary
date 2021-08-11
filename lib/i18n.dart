import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'i18n_base.dart';

export 'i18n_base.dart';

extension MaterialMessage on Message {
  String get(BuildContext context) {
    return getForLocale(Localizations.localeOf(context));
  }

  String getForLocale(Locale locale) {
    return getFor(locale.languageCode == 'es');
  }
}
