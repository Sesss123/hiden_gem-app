import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('ru'),
    Locale('si'),
    Locale('ta')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems SL'**
  String get appTitle;

  /// No description provided for @goodMorningAdmin.
  ///
  /// In en, this message translates to:
  /// **'Good Morning, Admin'**
  String get goodMorningAdmin;

  /// No description provided for @oracleToday.
  ///
  /// In en, this message translates to:
  /// **'Here is what\'s happening with the Oracle today.'**
  String get oracleToday;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'TOTAL USERS'**
  String get totalUsers;

  /// No description provided for @plansToday.
  ///
  /// In en, this message translates to:
  /// **'PLANS TODAY'**
  String get plansToday;

  /// No description provided for @avgConfidence.
  ///
  /// In en, this message translates to:
  /// **'AVG CONFIDENCE'**
  String get avgConfidence;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'REVENUE (LKR)'**
  String get revenue;

  /// No description provided for @oraclesChoice.
  ///
  /// In en, this message translates to:
  /// **'Oracle\'s Choice'**
  String get oraclesChoice;

  /// No description provided for @recentPlans.
  ///
  /// In en, this message translates to:
  /// **'Recent Plans'**
  String get recentPlans;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Language'**
  String get selectLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueButton;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// No description provided for @style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get style;

  /// No description provided for @planB.
  ///
  /// In en, this message translates to:
  /// **'Plan B'**
  String get planB;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @discovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get discovery;

  /// No description provided for @nearYou.
  ///
  /// In en, this message translates to:
  /// **'Near You'**
  String get nearYou;

  /// No description provided for @aiReason.
  ///
  /// In en, this message translates to:
  /// **'Why this place?'**
  String get aiReason;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @openOnMap.
  ///
  /// In en, this message translates to:
  /// **'Open on Map'**
  String get openOnMap;

  /// No description provided for @planNewTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan New Trip'**
  String get planNewTrip;

  /// No description provided for @localGemsOffline.
  ///
  /// In en, this message translates to:
  /// **'Local Gems (Offline)'**
  String get localGemsOffline;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get supportCenter;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your saved trips and data will be lost.'**
  String get confirmDeleteMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @discoveryHeader.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoveryHeader;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for hidden gems...'**
  String get searchHint;

  /// No description provided for @picksForYou.
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems SL Picks for you'**
  String get picksForYou;

  /// No description provided for @exploreInAr.
  ///
  /// In en, this message translates to:
  /// **'Explore in AR'**
  String get exploreInAr;

  /// No description provided for @bestNatureNearby.
  ///
  /// In en, this message translates to:
  /// **'Best Nature nearby'**
  String get bestNatureNearby;

  /// No description provided for @topCultureSpots.
  ///
  /// In en, this message translates to:
  /// **'Top Culture spots'**
  String get topCultureSpots;

  /// No description provided for @villageStayTitle.
  ///
  /// In en, this message translates to:
  /// **'Village & Authentic Stays'**
  String get villageStayTitle;

  /// No description provided for @noMatchesNearby.
  ///
  /// In en, this message translates to:
  /// **'No matches nearby'**
  String get noMatchesNearby;

  /// No description provided for @tryIncreasingDistance.
  ///
  /// In en, this message translates to:
  /// **'Try increasing distance or removing filters.'**
  String get tryIncreasingDistance;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNature.
  ///
  /// In en, this message translates to:
  /// **'Nature 🌿'**
  String get filterNature;

  /// No description provided for @filterWaterfall.
  ///
  /// In en, this message translates to:
  /// **'Waterfall 🌊'**
  String get filterWaterfall;

  /// No description provided for @filterHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking 🥾'**
  String get filterHiking;

  /// No description provided for @filterCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture 🏛️'**
  String get filterCulture;

  /// No description provided for @filterCoastal.
  ///
  /// In en, this message translates to:
  /// **'Coastal 🌊'**
  String get filterCoastal;

  /// No description provided for @filterFamily.
  ///
  /// In en, this message translates to:
  /// **'Family 👨‍👩‍👧‍👦'**
  String get filterFamily;

  /// No description provided for @filterBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget 💸'**
  String get filterBudget;

  /// No description provided for @filterAr.
  ///
  /// In en, this message translates to:
  /// **'AR Places 🏛'**
  String get filterAr;

  /// No description provided for @categoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get categoryNature;

  /// No description provided for @categoryWaterfall.
  ///
  /// In en, this message translates to:
  /// **'Waterfall'**
  String get categoryWaterfall;

  /// No description provided for @categoryHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get categoryHiking;

  /// No description provided for @categoryCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get categoryCulture;

  /// No description provided for @categoryCoastal.
  ///
  /// In en, this message translates to:
  /// **'Coastal'**
  String get categoryCoastal;

  /// No description provided for @categoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get categoryFamily;

  /// No description provided for @categoryBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get categoryBudget;

  /// No description provided for @oracleVision.
  ///
  /// In en, this message translates to:
  /// **'ORACLE\\\'S VISION'**
  String get oracleVision;

  /// No description provided for @theKnowledge.
  ///
  /// In en, this message translates to:
  /// **'THE KNOWLEDGE'**
  String get theKnowledge;

  /// No description provided for @safetyProtocols.
  ///
  /// In en, this message translates to:
  /// **'SAFETY PROTOCOLS'**
  String get safetyProtocols;

  /// No description provided for @provisions.
  ///
  /// In en, this message translates to:
  /// **'PROVISIONS'**
  String get provisions;

  /// No description provided for @sustainableEthos.
  ///
  /// In en, this message translates to:
  /// **'SUSTAINABLE ETHOS'**
  String get sustainableEthos;

  /// No description provided for @culturalEtiquette.
  ///
  /// In en, this message translates to:
  /// **'CULTURAL ETIQUETTE'**
  String get culturalEtiquette;

  /// No description provided for @ecoResponsibleTravel.
  ///
  /// In en, this message translates to:
  /// **'ECO-RESPONSIBLE TRAVEL'**
  String get ecoResponsibleTravel;

  /// No description provided for @tapToTranslate.
  ///
  /// In en, this message translates to:
  /// **'TAP TO TRANSLATE'**
  String get tapToTranslate;

  /// No description provided for @moment.
  ///
  /// In en, this message translates to:
  /// **'MOMENT'**
  String get moment;

  /// No description provided for @offering.
  ///
  /// In en, this message translates to:
  /// **'OFFERING'**
  String get offering;

  /// No description provided for @reality.
  ///
  /// In en, this message translates to:
  /// **'REALITY'**
  String get reality;

  /// No description provided for @aerDimensionReady.
  ///
  /// In en, this message translates to:
  /// **'AER DIMENSION READY'**
  String get aerDimensionReady;

  /// No description provided for @invokeAr.
  ///
  /// In en, this message translates to:
  /// **'INVOKE AR'**
  String get invokeAr;

  /// No description provided for @addToDestiny.
  ///
  /// In en, this message translates to:
  /// **'ADD TO DESTINY'**
  String get addToDestiny;

  /// No description provided for @distanceLockTitle.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE LOCK'**
  String get distanceLockTitle;

  /// No description provided for @distanceLockMessage.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} KM away. Seekers can only access the AER dimension within 500M of the site.'**
  String distanceLockMessage(Object distance);

  /// No description provided for @arCoreNotDetected.
  ///
  /// In en, this message translates to:
  /// **'AR CORE NOT DETECTED'**
  String get arCoreNotDetected;

  /// No description provided for @arCoreMessage.
  ///
  /// In en, this message translates to:
  /// **'Traveler, the ancient visions require ARCore to manifest. Please ensure it is installed and updated on your device.'**
  String get arCoreMessage;

  /// No description provided for @road.
  ///
  /// In en, this message translates to:
  /// **'ROAD'**
  String get road;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'ACCESS'**
  String get access;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'PARKING'**
  String get parking;

  /// No description provided for @syncingResonance.
  ///
  /// In en, this message translates to:
  /// **'Syncing with ancient resonance...'**
  String get syncingResonance;

  /// No description provided for @resonanceLost.
  ///
  /// In en, this message translates to:
  /// **'Resonance Lost'**
  String get resonanceLost;

  /// No description provided for @gpsRequired.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify your location. Ensure GPS is active.'**
  String get gpsRequired;

  /// No description provided for @unlockTeleport.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK TELEPORT'**
  String get unlockTeleport;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get close;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @ancestralPortalOpen.
  ///
  /// In en, this message translates to:
  /// **'ANCESTRAL PORTAL OPEN'**
  String get ancestralPortalOpen;

  /// No description provided for @stepIntoHistory.
  ///
  /// In en, this message translates to:
  /// **'Step into history'**
  String get stepIntoHistory;

  /// No description provided for @viewEraIn360.
  ///
  /// In en, this message translates to:
  /// **'View {era} in 360°'**
  String viewEraIn360(Object era);

  /// No description provided for @arDemoLabel.
  ///
  /// In en, this message translates to:
  /// **'10-Second AR Demo'**
  String get arDemoLabel;

  /// No description provided for @fullHeritageAr.
  ///
  /// In en, this message translates to:
  /// **'Full Heritage AR'**
  String get fullHeritageAr;

  /// No description provided for @ancientHeritageSite.
  ///
  /// In en, this message translates to:
  /// **'Ancient Heritage Site'**
  String get ancientHeritageSite;

  /// No description provided for @arTipPlace.
  ///
  /// In en, this message translates to:
  /// **'Tap the surface to place the 3D reconstruction'**
  String get arTipPlace;

  /// No description provided for @arTipTime.
  ///
  /// In en, this message translates to:
  /// **'Swipe \"Then/Now\" to travel through time'**
  String get arTipTime;

  /// No description provided for @arTipAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio guide available in Sinhala & English'**
  String get arTipAudio;

  /// No description provided for @arTipGroup.
  ///
  /// In en, this message translates to:
  /// **'Host or join a group AR tour'**
  String get arTipGroup;

  /// No description provided for @openArPortal.
  ///
  /// In en, this message translates to:
  /// **'OPEN AR PORTAL'**
  String get openArPortal;

  /// No description provided for @enterDemo.
  ///
  /// In en, this message translates to:
  /// **'ENTER DEMO (10s)'**
  String get enterDemo;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Offline Ready'**
  String get offlineReady;

  /// No description provided for @assetsCached.
  ///
  /// In en, this message translates to:
  /// **'Heritage assets cached for offline use!'**
  String get assetsCached;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please check connection.'**
  String get downloadFailed;

  /// No description provided for @downloadForOffline.
  ///
  /// In en, this message translates to:
  /// **'Download for Offline'**
  String get downloadForOffline;

  /// No description provided for @initiateTravel.
  ///
  /// In en, this message translates to:
  /// **'INITIATE TRAVEL SEQUENCE'**
  String get initiateTravel;

  /// No description provided for @selectOracleLanguage.
  ///
  /// In en, this message translates to:
  /// **'SELECT YOUR ORACLE LANGUAGE'**
  String get selectOracleLanguage;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'SKIP FOR NOW'**
  String get skipForNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'en',
        'ja',
        'ko',
        'ru',
        'si',
        'ta'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ru':
      return AppLocalizationsRu();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
