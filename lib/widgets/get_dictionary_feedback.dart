import 'package:feedback/feedback.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/util/string_utils.dart';

class DictionaryFeedback {
  DictionaryFeedback(this.body, this.type);

  final String body;
  final DictionaryFeedbackType type;

  Map<String, String> toMap() {
    return {'body': body, 'type': type.toString().enumString};
  }
}

class _DictionaryFeedbackBuilder {
  String? body;
  DictionaryFeedbackType? type;

  DictionaryFeedback build() => DictionaryFeedback(
        body ?? '',
        type!,
      );
}

enum DictionaryFeedbackType {
  translation_error,
  bug_report,
  feature_request,
  other,
}

String typeToString(Locale locale, DictionaryFeedbackType type) {
  switch (type) {
    case DictionaryFeedbackType.bug_report:
      return i18n.bugReport.getForLocale(locale);
    case DictionaryFeedbackType.feature_request:
      return i18n.featureRequest.getForLocale(locale);
    case DictionaryFeedbackType.translation_error:
      return i18n.translationError.getForLocale(locale);
    case DictionaryFeedbackType.other:
      return i18n.other.getForLocale(locale);
  }
}

class GetDictionaryFeedback extends StatefulWidget {
  const GetDictionaryFeedback(this.onSubmit, {Key? key}) : super(key: key);

  final OnSubmit onSubmit;

  @override
  _GetDictionaryFeedbackState createState() => _GetDictionaryFeedbackState();
}

class _GetDictionaryFeedbackState extends State<GetDictionaryFeedback> {
  final _feedbackBuilder = _DictionaryFeedbackBuilder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    Text('${i18n.feedbackType.cap.get(context)}: '),
                    DropdownButton<DictionaryFeedbackType>(
                      value: _feedbackBuilder.type,
                      items: DictionaryFeedbackType.values
                          .map(
                            (type) => DropdownMenuItem<DictionaryFeedbackType>(
                              child: Text(
                                typeToString(
                                  Localizations.localeOf(context),
                                  type,
                                ),
                              ),
                              value: type,
                            ),
                          )
                          .toList(),
                      onChanged: (type) {
                        setState(() => _feedbackBuilder.type = type);
                      },
                    ),
                    const Text(' *'),
                  ],
                ),
                TextField(
                  minLines: 2,
                  maxLines: 10,
                  decoration: InputDecoration(
                    helperText: i18n.feedback.cap.get(context),
                  ),
                  onChanged: (value) => _feedbackBuilder.body = value,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _feedbackBuilder.type != null
                ? () => widget.onSubmit(
                      '',
                      extras: <String, DictionaryFeedback>{
                        'feedback': _feedbackBuilder.build()
                      },
                    )
                : null,
            child: Text(i18n.submit.cap.get(context)),
          ),
          Text(i18n.opensEmail.get(context)),
        ],
      ),
    );
  }
}
