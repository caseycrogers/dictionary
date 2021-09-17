import 'dart:io';
import 'dart:typed_data';

import 'package:feedback/feedback.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rogers_dictionary/dictionary_app.dart';

import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/util/string_utils.dart';
import 'package:rogers_dictionary/util/text_utils.dart';
import 'package:rogers_dictionary/widgets/get_dictionary_feedback.dart';

class FeedbackButton extends StatelessWidget {
  const FeedbackButton({Key? key, this.onPressed}) : super(key: key);

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
        i18n.giveFeedback.get(context),
        style: kButtonTextStyle,
      ),
      onPressed: () => _showFeedback(context),
    );
  }

  void _showFeedback(BuildContext context) {
    // Close the menu before displaying feedback.
    onPressed?.call();
    // Log user feedback in analytics
    unawaited(DictionaryApp.analytics.logEvent(
      name: 'feedback_opened',
    ));
    final Locale locale = Localizations.localeOf(context);
    BetterFeedback.of(context).controller.show(
          (userFeedback) => _onFeedback(userFeedback, locale),
        );
  }

  Future<void> _onFeedback(UserFeedback userFeedback, Locale locale) async {
    final screenshotFilePath =
        await writeImageToStorage(userFeedback.screenshot);
    final DictionaryFeedback feedback =
        userFeedback.extra!['feedback'] as DictionaryFeedback;
    final String typeString = feedback.type.toString().enumString;

    // Log user feedback in analytics
    unawaited(DictionaryApp.analytics.logEvent(
      name: 'feedback_submitted',
      parameters: feedback.toMap(),
    ));

    await FlutterEmailSender.send(
      Email(
        subject: '[Rogers Dictionary - ${typeToString(locale, feedback.type)}]',
        recipients: [
          'caseycrogers+$typeString@berkeley.edu',
          'glenntrogers+$typeString@gmail.com',
        ],
        body: feedback.body,
        attachmentPaths: [screenshotFilePath],
        isHTML: false,
      ),
    );
  }
}

Future<String> writeImageToStorage(Uint8List feedbackScreenshot) async {
  final Directory output = await getTemporaryDirectory();
  final String screenshotFilePath = '${output.path}/feedback.png';
  final File screenshotFile = File(screenshotFilePath);
  await screenshotFile.writeAsBytes(feedbackScreenshot);
  return screenshotFilePath;
}
