import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs de bloques de anuncios. Por defecto son los de PRUEBA de Google; para
/// publicar se pasan los reales con --dart-define=BANNER_ID=ca-app-pub-.../...
class AdIds {
  static const banner = String.fromEnvironment('BANNER_ID',
      defaultValue: 'ca-app-pub-3940256099942544/6300978111');
  static const interstitial = String.fromEnvironment('INTERSTITIAL_ID',
      defaultValue: 'ca-app-pub-3940256099942544/1033173712');
}

class AdService {
  AdService._();
  static final instance = AdService._();

  InterstitialAd? _interstitial;
  int _actions = 0;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Cuenta una accion del usuario y muestra un intersticial cada [every]
  /// acciones. Mantenerlo espaciado evita molestar y cumple las politicas.
  void maybeShowInterstitial({int every = 5}) {
    if (++_actions % every != 0) return;
    final ad = _interstitial;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    _interstitial = null;
    ad.show();
  }
}

/// Banner adaptable al ancho; se coloca en la parte inferior de la pantalla.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad != null) return;
    final width = MediaQuery.of(context).size.width.truncate();
    AdSize.getLargeAnchoredAdaptiveBannerAdSize(width).then((size) {
      if (size == null || !mounted) return;
      BannerAd(
        adUnitId: AdIds.banner,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => setState(() => _ad = ad as BannerAd),
          onAdFailedToLoad: (ad, _) => ad.dispose(),
        ),
      ).load();
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SafeArea(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
