import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import 'package:rogers_dictionary/clients/entry_builders.dart';
import 'package:rogers_dictionary/dictionary_app.dart';
import 'package:rogers_dictionary/i18n.dart' as i18n;
import 'package:rogers_dictionary/pages/page_header.dart';
import 'package:rogers_dictionary/util/collection_utils.dart';
import 'package:rogers_dictionary/util/constants.dart';
import 'package:rogers_dictionary/util/string_utils.dart';
import 'package:rogers_dictionary/util/text_utils.dart';
import 'package:rogers_dictionary/widgets/loading_text.dart';

class AboutButton extends StatelessWidget {
  const AboutButton({Key? key, required this.onPressed}) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
        i18n.aboutThisApp.get(context),
        style: kButtonTextStyle,
      ),
      onPressed: () {
        DictionaryApp.analytics.logEvent(name: 'about_pressed');
        onPressed();
        showDialog<void>(
          context: context,
          builder: (overlayContext) => _AboutPage(() {
            Navigator.of(overlayContext).pop();
          }),
        );
      },
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage(this.onClose);

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2 * kPad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2 * kPad),
        child: Material(
          color: Theme.of(context).cardColor,
          child: PageHeader(
            header: headline1Text(context, 'About'),
            onClose: onClose,
            child: Column(
              children: [
                Container(
                  height: 240,
                  width: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(
                        join('assets', 'images', 'glenn.jpg'),
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Hi, welcome to my English/Spanish medical app, the digital '
                  'version of the 5th edition of my medical bilingual '
                  'dictionary to be published later this year (2021). The app '
                  'translates any medical word likely to come up in a '
                  'conversation between a health professional and a patient, '
                  'including slang, regionalisms, and more.\n',
                ),
                const Text(
                  'It also provides an extensive sample dialogue '
                  'section based on my 30-plus year history as an internist '
                  'with Spanish-speaking patients in outpatient, Med-Surg '
                  'ward, and ICU settings.\n',
                ),
                const Text('The app was developed by my son, Casey Rogers, '
                    'using skills he acquired at Google and GM Cruise.\n'),
                const Text('Enjoy the app! If you have any feedback, you can '
                    'let us know by pressing the "options" button at the top '
                    'right and tapping "give feedback."'),
                const Divider(),
                const _DebugInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugInfo extends StatelessWidget {
  const _DebugInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.black38, fontSize: 20),
      child: Column(
        children: <String, Future<String>>{
          '': Future.value(Theme.of(context).platform.toString().enumString),
          'app v': DictionaryApp.packageInfo.then((p) => p.version),
          'database v': DictionaryApp.db.version.then((v) => v.versionString),
        }
            .mapDown(
              (label, future) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  FutureBuilder<String>(
                    future: future,
                    builder: (_, snap) {
                      if (!snap.hasData) {
                        return const LoadingText();
                      }
                      return Text(snap.data!);
                    },
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
