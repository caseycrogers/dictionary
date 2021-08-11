import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rogers_dictionary/main.dart';

class DictionaryBannerAd extends StatefulWidget {
  const DictionaryBannerAd({Key? key}) : super(key: key);

  @override
  _DictionaryBannerAdState createState() => _DictionaryBannerAdState();
}

class _DictionaryBannerAdState extends State<DictionaryBannerAd> {
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _realAdUnitId = 'ca-app-pub-4592603753721232/8369891839';

  static const List<String> _universalKeywords = [
    'medical',
    'spanish',
    'english',
    'pharmaceutical',
    'doctor',
  ];

  late final Future<BannerAd> _bannerAd = _getBannerAd();

  Future<BannerAd> _getBannerAd() async {
    final AdSize? adSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).orientation,
      MediaQuery.of(context).size.width.round(),
    );
    final BannerAd ad = BannerAd(
      adUnitId: _testAdUnitId,
      size: adSize ?? AdSize.banner,
      request: const AdRequest(
        keywords: [
          ..._universalKeywords
        ],
        nonPersonalizedAds: true,
      ),
      listener: BannerAdListener(
        onAdFailedToLoad: (Ad ad, loadAdError) {
          MyApp.analytics.logEvent(
            name: 'ad_load_error',
            parameters: {'ad': ad.toString(), 'error': loadAdError.toString()},
          );
          print(loadAdError);
        },
      ),
    );
    await ad.load();
    return ad;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BannerAd>(
      future: _bannerAd,
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return Container();
        }
        return Container(
          height: snap.data!.size.height.toDouble(),
          width: snap.data!.size.width.toDouble(),
          child: AdWidget(
            ad: snap.data!,
          ),
        );
      },
    );
  }
}
