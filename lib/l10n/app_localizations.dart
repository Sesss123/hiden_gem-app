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

  /// No description provided for @allNearbyPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Nearby Places'**
  String get allNearbyPlacesTitle;

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

  /// No description provided for @goodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get goodToKnow;

  /// No description provided for @bestAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Best at {time}'**
  String bestAtLabel(String time);

  /// No description provided for @arHeritageReady.
  ///
  /// In en, this message translates to:
  /// **'AR Heritage ready'**
  String get arHeritageReady;

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

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY POLICY & LEGAL'**
  String get privacyPolicyTitle;

  /// No description provided for @dataProtectionProtocol.
  ///
  /// In en, this message translates to:
  /// **'DATA PROTECTION PROTOCOL'**
  String get dataProtectionProtocol;

  /// No description provided for @lastUpdatedDate.
  ///
  /// In en, this message translates to:
  /// **'LAST UPDATED: JULY 5, 2026'**
  String get lastUpdatedDate;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'We value your privacy and data sovereignty. This document outlines how Hidden Gems Sri Lanka (Pvt) Ltd collects, protects, and governs your personal information under Sri Lankan law.'**
  String get privacyIntro;

  /// No description provided for @contactUsAboutData.
  ///
  /// In en, this message translates to:
  /// **'CONTACT US ABOUT YOUR DATA'**
  String get contactUsAboutData;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email client. Please email support@hiddengems.lk'**
  String get couldNotOpenEmail;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open a maps app on this device.'**
  String get couldNotOpenMaps;

  /// No description provided for @photosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosLabel;

  /// No description provided for @scheduleOngoingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ongoing — date to be announced'**
  String get scheduleOngoingLabel;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. DATA WE COLLECT'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Body.
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems Sri Lanka collects personal information voluntarily provided when using our services:\n\n• Account Information: Display name, email address, phone number, and profile picture (via Firebase Auth / Google Sign-In).\n• Precise & Live Location: We request location data to enable location-based Discovery, Local Gems, and live tracking features. When using Family Sharing, your real-time coordinates are processed to update authorized recipients.\n• Family Sharing Recipient Data: Recipient names, contact identifiers, and temporary share tokens generated during coordination sessions.\n• Guide Profile & Verification Data: Licensing status, identification credentials, languages spoken, and bio details submitted during guide enrollment.\n• In-App Messages & Bookings: Communications between tourists and guides, itinerary data, and session logs.\n• Device & Analytics Data: Crash diagnostics, performance metrics, and device metadata via Firebase Analytics and Crashlytics.\n• Payment Data: If applicable, financial transactions are processed exclusively by PCI-DSS compliant third-party payment gateways. Hidden Gems Sri Lanka never stores raw credit card numbers or banking data on our servers.'**
  String get privacySection1Body;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. FAMILY SHARING FEATURE SPECIFICALLY'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Body.
  ///
  /// In en, this message translates to:
  /// **'Our \'Family Sharing\' and coordination hub allows explorers to share live status, guide identity, meeting points, and emergency alerts with trusted personal contacts:\n\n• Opt-In & Revocable: Sharing is strictly opt-in and controlled entirely by the user. You may revoke access or delete active sharing links at any time in the app.\n• Time-Limited: Shared mission links automatically expire after your selected duration (e.g., 4, 12, or 24 hours). Once expired, location transmission ceases immediately.\n• Zero Content Monitoring: Hidden Gems Sri Lanka is not a party to and does not monitor or inspect the personal communications or shared status between you and your chosen recipients beyond what is technically necessary to operate the feature and deliver encrypted telemetry.'**
  String get privacySection2Body;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. LEGAL BASIS & SRI LANKA COMPLIANCE'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Body.
  ///
  /// In en, this message translates to:
  /// **'Our data practices strictly adhere to Sri Lankan regulatory frameworks and international best practices:\n\n• Governing Data Law: This policy is governed by the Personal Data Protection Act, No. 9 of 2022 (Sri Lanka). Hidden Gems Sri Lanka (Pvt) Ltd / TripMe.ai acts as the Data Controller and commits to the core statutory principles of data minimization, purpose limitation, lawful processing, and mandatory breach notification.\n• Tourism Act & SLTDA Regulations: In compliance with the Tourism Act, No. 38 of 2005 and Sri Lanka Tourism Development Authority (SLTDA) guidelines, guide verification credentials displayed in app profiles are self-reported or verified against SLTDA registries where available. The company provides this information for transparency but does not guarantee licensing status beyond what is displayed.\n• Cross-Border Data Transfers: For international tourists visiting Sri Lanka, using this application involves transferring data across borders to global cloud infrastructure (including Google Firebase and AWS servers). By utilizing the app, you explicitly consent to these international data transfers for the performance of the service.'**
  String get privacySection3Body;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. LIABILITY LIMITATION & DISCLAIMERS'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Body.
  ///
  /// In en, this message translates to:
  /// **'To the maximum extent permitted by applicable law, your use of the app is subject to the following limitations:\n\n• Connective Platform Role: Hidden Gems Sri Lanka operates as an informational and connective platform connecting tourists with independent local guides and services. We are not liable for the conduct, safety, licensing validity, or actions of any guide, driver, or third-party service connected through the app.\n• Emergency & Location Feature Limitations: Location-sharing, \'Family Sharing\', and emergency alert signals are provided on a best-effort technical basis. THEY ARE NOT A SUBSTITUTE FOR OFFICIAL EMERGENCY SERVICES. In an emergency, always contact Sri Lanka Police (119), Tourist Police (+94 11 242 1052), or Suwaseriya Ambulance (1990). The company assumes no liability for network delays, GPS inaccuracies, or notification delivery failures.\n• Independent Verification: Users remain solely responsible for verifying guide credentials, vehicle safety, and personal security independently prior to travel.\n• Statutory Liability Cap: Under Sri Lankan law, any liability of Hidden Gems Sri Lanka (Pvt) Ltd arising out of or related to your use of the platform is strictly limited to the total fees paid by you to the company for the specific service in dispute.'**
  String get privacySection4Body;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. USER RIGHTS & DATA CONTROL'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Body.
  ///
  /// In en, this message translates to:
  /// **'Under the Personal Data Protection Act No. 9 of 2022, you hold fundamental rights regarding your personal data:\n\n• Right of Access & Correction: You may review, download, or edit your account information and profile data directly within the app\'s Profile Screen.\n• Withdrawal of Consent: You may withdraw consent for location tracking or data processing at any time by disabling location permissions in device settings or revoking active Family Sharing links.\n• Right to Deletion (Right to be Forgotten): You can request permanent account deletion directly via Profile > Privacy > Account Deletion, or by emailing our data protection officer at support@hiddengems.lk.'**
  String get privacySection5Body;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. DATA RETENTION & PURGATION'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Body.
  ///
  /// In en, this message translates to:
  /// **'We retain personal data only for as long as necessary to fulfill the purposes outlined in this policy:\n\n• Family Sharing & Location Data: Temporary share links and associated live location history are automatically purged from active databases upon link expiration or manual revocation.\n• Account Data: Upon submitting an account deletion request, your profile, saved wishlists, and personal identifiers are permanently scrubbed from our production servers within 30 days, retaining only anonymized statistical data required for regulatory audit trails.'**
  String get privacySection6Body;

  /// No description provided for @privacySection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. CHILDREN\'S PRIVACY PROTECTION'**
  String get privacySection7Title;

  /// No description provided for @privacySection7Body.
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems Sri Lanka is designed for adult travelers and independent tourism professionals. The application is not directed at children under the age of 18. We do not knowingly solicit, collect, or process personal data from minors. If we discover that an underage user has provided personal data without verified parental consent, we will immediately purge such data from our infrastructure.'**
  String get privacySection7Body;

  /// No description provided for @privacySection8Title.
  ///
  /// In en, this message translates to:
  /// **'8. CHANGES TO THIS POLICY'**
  String get privacySection8Title;

  /// No description provided for @privacySection8Body.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy periodically to reflect technological advancements, new app features, or evolving Sri Lankan legal requirements. When material changes occur, we will notify users via prominent in-app banners and update the persistent \'Last Updated\' timestamp at the top of this document. Continued use of the platform constitutes acceptance of the revised terms.'**
  String get privacySection8Body;

  /// No description provided for @privacySection9Title.
  ///
  /// In en, this message translates to:
  /// **'9. CLOSING LEGAL DISCLAIMER'**
  String get privacySection9Title;

  /// No description provided for @privacySection9Body.
  ///
  /// In en, this message translates to:
  /// **'This policy is provided for general informational purposes and does not constitute formal legal advice. Hidden Gems Sri Lanka (Pvt) Ltd / TripMe.ai recommends that users and tourism stakeholders seek independent legal counsel in Sri Lanka to confirm full compliance with the Personal Data Protection Act No. 9 of 2022, the Tourism Act No. 38 of 2005, and any other applicable statutory regulations.'**
  String get privacySection9Body;

  /// No description provided for @privacyFooterCompany.
  ///
  /// In en, this message translates to:
  /// **'HIDDEN GEMS SRI LANKA (PVT) LTD'**
  String get privacyFooterCompany;

  /// No description provided for @privacyFooterAddress.
  ///
  /// In en, this message translates to:
  /// **'Registered Office: Colombo, Sri Lanka • support@hiddengems.lk'**
  String get privacyFooterAddress;

  /// No description provided for @termsAndPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & privacy'**
  String get termsAndPrivacyTitle;

  /// No description provided for @reviewBeforeContinuing.
  ///
  /// In en, this message translates to:
  /// **'Please review before continuing'**
  String get reviewBeforeContinuing;

  /// No description provided for @dataPrivacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get dataPrivacySectionTitle;

  /// No description provided for @dataPrivacySectionBody.
  ///
  /// In en, this message translates to:
  /// **'We keep your data secure. We securely store your profile and saved trips, and never sell your data to third parties.'**
  String get dataPrivacySectionBody;

  /// No description provided for @aiPlanningSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI trip planning'**
  String get aiPlanningSectionTitle;

  /// No description provided for @aiPlanningSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Our AI planner is a predictive tool. While we strive for accuracy, its suggestions may differ from real-time conditions, so please verify critical information independently.\n\nBy using the AI planner, you agree to:\n• Use results responsibly, not maliciously.\n• Never attempt to exploit or manipulate the AI.\n• Treat all suggestions as guidance, not guarantees.'**
  String get aiPlanningSectionBody;

  /// No description provided for @communityConductSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Community conduct'**
  String get communityConductSectionTitle;

  /// No description provided for @communityConductSectionBody.
  ///
  /// In en, this message translates to:
  /// **'You agree to use the app respectfully, helping keep the platform safe and reliable for other travelers.'**
  String get communityConductSectionBody;

  /// No description provided for @readFullPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read the full privacy policy'**
  String get readFullPrivacyPolicy;

  /// No description provided for @acceptTermsCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Service & Privacy Policy'**
  String get acceptTermsCheckbox;

  /// No description provided for @acceptAiPolicyCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand the AI planner\'s limitations'**
  String get acceptAiPolicyCheckbox;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'An update is required'**
  String get updateRequiredTitle;

  /// No description provided for @updateReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is ready'**
  String get updateReadyTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Please update the app to continue your journey.'**
  String get updateRequiredBody;

  /// No description provided for @updateReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Better maps, faster AI trips, and improved AR are waiting for you.'**
  String get updateReadyBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @couldNotOpenStore.
  ///
  /// In en, this message translates to:
  /// **'Failed to open store. Please update manually.'**
  String get couldNotOpenStore;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'SRI LANKA\'S PREMIER AI TRAVEL ORACLE'**
  String get brandTagline;

  /// No description provided for @oracleConnected.
  ///
  /// In en, this message translates to:
  /// **'ORACLE CONNECTED'**
  String get oracleConnected;

  /// No description provided for @initializingExperience.
  ///
  /// In en, this message translates to:
  /// **'INITIALIZING TRAVEL EXPERIENCE...'**
  String get initializingExperience;

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hidden Gems'**
  String get welcomeToApp;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sri Lanka\'s AI travel companion'**
  String get loginSubtitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start planning your Sri Lanka trip'**
  String get signupSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @identifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Identifier required'**
  String get identifierRequired;

  /// No description provided for @invalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid address'**
  String get invalidAddress;

  /// No description provided for @insufficientComplexity.
  ///
  /// In en, this message translates to:
  /// **'Insufficient complexity'**
  String get insufficientComplexity;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @googleLabel.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get googleLabel;

  /// No description provided for @appleLabel.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get appleLabel;

  /// No description provided for @zenithLockActive.
  ///
  /// In en, this message translates to:
  /// **'ZENITH LOCK ACTIVE'**
  String get zenithLockActive;

  /// No description provided for @lockoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Multiple failed attempts detected.\nNeural link restricted to prevent brute force.'**
  String get lockoutMessage;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'TIME REMAINING'**
  String get timeRemaining;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In was cancelled.'**
  String get googleSignInCancelled;

  /// No description provided for @authFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Authentication Failed: {reason}'**
  String authFailedPrefix(String reason);

  /// No description provided for @googleSignInFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Failed: {reason}'**
  String googleSignInFailedPrefix(String reason);

  /// No description provided for @appleSignInFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In Failed: {reason}'**
  String appleSignInFailedPrefix(String reason);

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your registered email address first.'**
  String get enterEmailFirst;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions sent to {email}.'**
  String passwordResetSent(String email);

  /// No description provided for @resetEmailFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email: {reason}'**
  String resetEmailFailedPrefix(String reason);

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'The email address is already in use by another account.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password provided is too weak.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network request failed. Please check your internet connection.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This operation is not allowed.'**
  String get authErrorNotAllowed;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An authentication error occurred.'**
  String get authErrorGeneric;

  /// No description provided for @noPlaceFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No place found matching \"{query}\"'**
  String noPlaceFoundMatching(String query);

  /// No description provided for @featuredLabel.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredLabel;

  /// No description provided for @exploreLabel.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreLabel;

  /// No description provided for @planTripAction.
  ///
  /// In en, this message translates to:
  /// **'Plan Trip'**
  String get planTripAction;

  /// No description provided for @findGuideAction.
  ///
  /// In en, this message translates to:
  /// **'Find Guide'**
  String get findGuideAction;

  /// No description provided for @foodAiAction.
  ///
  /// In en, this message translates to:
  /// **'Food AI'**
  String get foodAiAction;

  /// No description provided for @arPortalsAction.
  ///
  /// In en, this message translates to:
  /// **'AR Portals'**
  String get arPortalsAction;

  /// No description provided for @localGemsNearby.
  ///
  /// In en, this message translates to:
  /// **'Local Gems Nearby'**
  String get localGemsNearby;

  /// No description provided for @todayInSriLanka.
  ///
  /// In en, this message translates to:
  /// **'Today in Sri Lanka'**
  String get todayInSriLanka;

  /// No description provided for @discoverSriLanka.
  ///
  /// In en, this message translates to:
  /// **'Discover Sri Lanka'**
  String get discoverSriLanka;

  /// No description provided for @letOracleGuide.
  ///
  /// In en, this message translates to:
  /// **'Let the Oracle guide your path'**
  String get letOracleGuide;

  /// No description provided for @searchSecretLocations.
  ///
  /// In en, this message translates to:
  /// **'Search secret locations...'**
  String get searchSecretLocations;

  /// No description provided for @offlineModeLabel.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE MODE'**
  String get offlineModeLabel;

  /// No description provided for @ayubowanGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ayubowan, {name}!'**
  String ayubowanGreeting(String name);

  /// No description provided for @travelerFallback.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get travelerFallback;

  /// No description provided for @exploreByCategory.
  ///
  /// In en, this message translates to:
  /// **'Explore by Category'**
  String get exploreByCategory;

  /// No description provided for @categoryNatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get categoryNatureLabel;

  /// No description provided for @categoryBeachesLabel.
  ///
  /// In en, this message translates to:
  /// **'Beaches'**
  String get categoryBeachesLabel;

  /// No description provided for @categoryCultureLabel.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get categoryCultureLabel;

  /// No description provided for @categoryAdventureLabel.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get categoryAdventureLabel;

  /// No description provided for @exploreNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreNavLabel;

  /// No description provided for @eventsNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsNavLabel;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String daysLabel(int count);

  /// No description provided for @originRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select or enter a starting point.'**
  String get originRequiredError;

  /// No description provided for @destinationRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select or enter a destination.'**
  String get destinationRequiredError;

  /// No description provided for @unsupportedCityError.
  ///
  /// In en, this message translates to:
  /// **'\"{city}\" is not a supported Sri Lankan city. Please select from the dropdown.'**
  String unsupportedCityError(String city);

  /// No description provided for @originDestinationSameError.
  ///
  /// In en, this message translates to:
  /// **'Starting point and destination cannot be the same.'**
  String get originDestinationSameError;

  /// No description provided for @stepProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgressLabel(int current, int total);

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Where should we guide you?'**
  String get step1Title;

  /// No description provided for @step1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'The Essentials'**
  String get step1Subtitle;

  /// No description provided for @startingPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting Point'**
  String get startingPointLabel;

  /// No description provided for @startingPointHint.
  ///
  /// In en, this message translates to:
  /// **'Airport, Colombo...'**
  String get startingPointHint;

  /// No description provided for @destinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinationLabel;

  /// No description provided for @destinationHint.
  ///
  /// In en, this message translates to:
  /// **'Ella, Galle, Kandy...'**
  String get destinationHint;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Define the vibe of your journey.'**
  String get step2Title;

  /// No description provided for @step2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Budget & Style'**
  String get step2Subtitle;

  /// No description provided for @tripLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip length'**
  String get tripLengthLabel;

  /// No description provided for @tripLengthDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String tripLengthDaysValue(int days);

  /// No description provided for @travelStandardLabel.
  ///
  /// In en, this message translates to:
  /// **'Travel Standard'**
  String get travelStandardLabel;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'With whom do you travel?'**
  String get step3Title;

  /// No description provided for @step3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Companions & Pace'**
  String get step3Subtitle;

  /// No description provided for @companionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Companions'**
  String get companionsLabel;

  /// No description provided for @travelPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Travel Pace'**
  String get travelPaceLabel;

  /// No description provided for @step4Title.
  ///
  /// In en, this message translates to:
  /// **'What stirs your soul?'**
  String get step4Title;

  /// No description provided for @step4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Interests & Passions'**
  String get step4Subtitle;

  /// No description provided for @estimatedBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated budget'**
  String get estimatedBudgetLabel;

  /// No description provided for @lkrCurrencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'LKR '**
  String get lkrCurrencyPrefix;

  /// No description provided for @consultTheOracleButton.
  ///
  /// In en, this message translates to:
  /// **'Consult the Oracle'**
  String get consultTheOracleButton;

  /// No description provided for @aiTripsFeatureName.
  ///
  /// In en, this message translates to:
  /// **'AI Trips'**
  String get aiTripsFeatureName;

  /// No description provided for @bonusTripUnlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Bonus Trip Unlocked! Try submitting again.'**
  String get bonusTripUnlockedMessage;

  /// No description provided for @groupTypeSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get groupTypeSolo;

  /// No description provided for @groupTypeCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get groupTypeCouple;

  /// No description provided for @groupTypeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get groupTypeFamily;

  /// No description provided for @groupTypeFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get groupTypeFriends;

  /// No description provided for @paceRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get paceRelaxed;

  /// No description provided for @paceBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get paceBalanced;

  /// No description provided for @pacePacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get pacePacked;

  /// No description provided for @styleBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get styleBudget;

  /// No description provided for @styleComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get styleComfort;

  /// No description provided for @styleLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get styleLuxury;

  /// No description provided for @interestAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get interestAdventure;

  /// No description provided for @interestFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get interestFood;

  /// No description provided for @interestWildlife.
  ///
  /// In en, this message translates to:
  /// **'Wildlife'**
  String get interestWildlife;

  /// No description provided for @interestPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get interestPhotography;

  /// No description provided for @interestVillageExperiences.
  ///
  /// In en, this message translates to:
  /// **'Village Experiences'**
  String get interestVillageExperiences;

  /// No description provided for @oracleConnectionDisrupted.
  ///
  /// In en, this message translates to:
  /// **'Oracle connection disrupted: {error}'**
  String oracleConnectionDisrupted(String error);

  /// No description provided for @discoveryFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERY FILTERS'**
  String get discoveryFiltersTitle;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get resetButton;

  /// No description provided for @maximumRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'MAXIMUM RADIUS: {radius} KM'**
  String maximumRadiusKm(int radius);

  /// No description provided for @budgetLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'BUDGET LEVEL'**
  String get budgetLevelLabel;

  /// No description provided for @priceRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get priceRangeAll;

  /// No description provided for @priceRangeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get priceRangeFree;

  /// No description provided for @priceRangeEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get priceRangeEconomy;

  /// No description provided for @priceRangePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get priceRangePremium;

  /// No description provided for @heritageArSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'HERITAGE AR SEARCH'**
  String get heritageArSearchTitle;

  /// No description provided for @onlyShowArEnabledSpots.
  ///
  /// In en, this message translates to:
  /// **'ONLY SHOW AR ENABLED SPOTS'**
  String get onlyShowArEnabledSpots;

  /// No description provided for @revealDestinies.
  ///
  /// In en, this message translates to:
  /// **'REVEAL DESTINIES'**
  String get revealDestinies;

  /// No description provided for @hostedByName.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {hostName}'**
  String hostedByName(String hostName);

  /// No description provided for @priceInLkr.
  ///
  /// In en, this message translates to:
  /// **'LKR {price}'**
  String priceInLkr(String price);

  /// No description provided for @resetAllFilters.
  ///
  /// In en, this message translates to:
  /// **'RESET ALL FILTERS'**
  String get resetAllFilters;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @arBadge.
  ///
  /// In en, this message translates to:
  /// **'AR'**
  String get arBadge;

  /// No description provided for @heritageArBadge.
  ///
  /// In en, this message translates to:
  /// **'HERITAGE AR'**
  String get heritageArBadge;

  /// No description provided for @tripDurationStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'{days}-day {style} trip'**
  String tripDurationStyleLabel(int days, String style);

  /// No description provided for @budgetTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTabLabel;

  /// No description provided for @mapTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTabLabel;

  /// No description provided for @premiumFeatureSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{featureName} is a Premium feature.'**
  String premiumFeatureSnackbar(String featureName);

  /// No description provided for @savedPlansFeatureName.
  ///
  /// In en, this message translates to:
  /// **'Saved Plans'**
  String get savedPlansFeatureName;

  /// No description provided for @noPathFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No path found'**
  String get noPathFoundTitle;

  /// No description provided for @noPathFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The Oracle could not chart a path for this destination. Try refining your budget or style preferences.'**
  String get noPathFoundMessage;

  /// No description provided for @tripOverviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip overview'**
  String get tripOverviewLabel;

  /// No description provided for @expenseBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get expenseBreakdownTitle;

  /// No description provided for @openExpenseTrackerButton.
  ///
  /// In en, this message translates to:
  /// **'Open Expense Tracker'**
  String get openExpenseTrackerButton;

  /// No description provided for @estimatedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get estimatedTotalLabel;

  /// No description provided for @userBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'User budget: {amount}'**
  String userBudgetLabel(String amount);

  /// No description provided for @percentUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Used'**
  String percentUsedLabel(int percent);

  /// No description provided for @percentOfTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of total'**
  String percentOfTotalLabel(int percent);

  /// No description provided for @visualTourRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Tour Route'**
  String get visualTourRouteTitle;

  /// No description provided for @visualTourRouteDescription.
  ///
  /// In en, this message translates to:
  /// **'Plot your entire journey across the teardrop isle. View detailed route segments and travel times.'**
  String get visualTourRouteDescription;

  /// No description provided for @openRouteMapButton.
  ///
  /// In en, this message translates to:
  /// **'Open Route Map'**
  String get openRouteMapButton;

  /// No description provided for @oracleRainPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Oracle\'s Rain Plan'**
  String get oracleRainPlanTitle;

  /// No description provided for @oracleRainPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Caught in a sudden shower? Switch to this.'**
  String get oracleRainPlanSubtitle;

  /// No description provided for @oracleVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Oracle\'s Vault'**
  String get oracleVaultTitle;

  /// No description provided for @oracleVaultDescription.
  ///
  /// In en, this message translates to:
  /// **'The rainy-day alternative is locked for free travelers.\nWatch a short video to unlock it for this trip.'**
  String get oracleVaultDescription;

  /// No description provided for @unlockWithAdButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock with ad'**
  String get unlockWithAdButton;

  /// No description provided for @goPremiumAdFreeButton.
  ///
  /// In en, this message translates to:
  /// **'Go Premium for Ad-Free Experience'**
  String get goPremiumAdFreeButton;

  /// No description provided for @hiddenGemsLuxuryTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems luxury'**
  String get hiddenGemsLuxuryTitle;

  /// No description provided for @premiumCtaDescription.
  ///
  /// In en, this message translates to:
  /// **'Go beyond the ordinary. Unlock the Oracle\'s full wisdom.'**
  String get premiumCtaDescription;

  /// No description provided for @premiumFeatureVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get premiumFeatureVoice;

  /// No description provided for @premiumFeaturePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get premiumFeaturePdf;

  /// No description provided for @premiumFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get premiumFeatureNoAds;

  /// No description provided for @unleashOracleButton.
  ///
  /// In en, this message translates to:
  /// **'Unleash the Oracle'**
  String get unleashOracleButton;

  /// No description provided for @couldNotOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Could not open map.'**
  String get couldNotOpenMap;

  /// No description provided for @viewOnMapButton.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMapButton;

  /// No description provided for @verificationSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Sources'**
  String get verificationSourcesTitle;

  /// No description provided for @proTipsForSriLanka.
  ///
  /// In en, this message translates to:
  /// **'💡 Pro Tips for Sri Lanka'**
  String get proTipsForSriLanka;

  /// No description provided for @oracleLocalTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Oracle\'s Local Tip'**
  String get oracleLocalTipTitle;

  /// No description provided for @budgetCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get budgetCategoryTransport;

  /// No description provided for @budgetCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get budgetCategoryFood;

  /// No description provided for @budgetCategoryHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get budgetCategoryHotel;

  /// No description provided for @budgetCategoryAttractions.
  ///
  /// In en, this message translates to:
  /// **'Attractions'**
  String get budgetCategoryAttractions;

  /// No description provided for @budgetCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get budgetCategoryOther;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'PROFILE PHOTO'**
  String get profilePhoto;

  /// No description provided for @localizationError.
  ///
  /// In en, this message translates to:
  /// **'Localization error'**
  String get localizationError;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @settingsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSectionLabel;

  /// No description provided for @profileErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'PROFILE ERROR:\n{error}\n\n{stack}'**
  String profileErrorDetails(String error, String stack);

  /// No description provided for @premiumTraveler.
  ///
  /// In en, this message translates to:
  /// **'Premium Traveler'**
  String get premiumTraveler;

  /// No description provided for @oracleTraveler.
  ///
  /// In en, this message translates to:
  /// **'Oracle Traveler'**
  String get oracleTraveler;

  /// No description provided for @levelBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'{levelTitle} · Level {levelNumber}'**
  String levelBadgeLabel(String levelTitle, int levelNumber);

  /// No description provided for @statLabelTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get statLabelTrips;

  /// No description provided for @statLabelPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get statLabelPlaces;

  /// No description provided for @statLabelLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get statLabelLevel;

  /// No description provided for @oracleExplorer.
  ///
  /// In en, this message translates to:
  /// **'Oracle Explorer'**
  String get oracleExplorer;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @fullArAiAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Full AR & AI access granted'**
  String get fullArAiAccessGranted;

  /// No description provided for @unlockArAiFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock AR & AI features'**
  String get unlockArAiFeatures;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @journeyHub.
  ///
  /// In en, this message translates to:
  /// **'Journey hub'**
  String get journeyHub;

  /// No description provided for @aiBudgetConcierge.
  ///
  /// In en, this message translates to:
  /// **'AI Budget Concierge'**
  String get aiBudgetConcierge;

  /// No description provided for @smartExpenseAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Smart expense advisor'**
  String get smartExpenseAdvisor;

  /// No description provided for @heritagePassport.
  ///
  /// In en, this message translates to:
  /// **'Heritage Passport'**
  String get heritagePassport;

  /// No description provided for @verifiableVisitCollection.
  ///
  /// In en, this message translates to:
  /// **'Verifiable visit collection'**
  String get verifiableVisitCollection;

  /// No description provided for @ethicalTravelMeter.
  ///
  /// In en, this message translates to:
  /// **'Ethical Travel Meter'**
  String get ethicalTravelMeter;

  /// No description provided for @ethicalRankScore.
  ///
  /// In en, this message translates to:
  /// **'Rank: {rank} • Score: {score}'**
  String ethicalRankScore(String rank, int score);

  /// No description provided for @ethicalTravelMeterDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'ETHICAL TRAVEL METER'**
  String get ethicalTravelMeterDialogTitle;

  /// No description provided for @ethicalRankScorePoints.
  ///
  /// In en, this message translates to:
  /// **'Rank: {rank} • Score: {score} Pts'**
  String ethicalRankScorePoints(String rank, int score);

  /// No description provided for @ethicalScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Your ethical travel score measures your positive impact on local communities and heritage preservation across Sri Lanka.'**
  String get ethicalScoreDescription;

  /// No description provided for @howToEarnPointsHeading.
  ///
  /// In en, this message translates to:
  /// **'HOW TO EARN POINTS:'**
  String get howToEarnPointsHeading;

  /// No description provided for @earnPointsReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Place Reviews'**
  String get earnPointsReviewsTitle;

  /// No description provided for @earnPointsReviewsAmount.
  ///
  /// In en, this message translates to:
  /// **'+10 Pts'**
  String get earnPointsReviewsAmount;

  /// No description provided for @earnPointsReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support local guides and travelers'**
  String get earnPointsReviewsSubtitle;

  /// No description provided for @earnPointsFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample Local Food'**
  String get earnPointsFoodTitle;

  /// No description provided for @earnPointsFoodAmount.
  ///
  /// In en, this message translates to:
  /// **'+15 Pts'**
  String get earnPointsFoodAmount;

  /// No description provided for @earnPointsFoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Empower authentic local eateries'**
  String get earnPointsFoodSubtitle;

  /// No description provided for @earnPointsHeritageTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit Heritage Sites'**
  String get earnPointsHeritageTitle;

  /// No description provided for @earnPointsHeritageAmount.
  ///
  /// In en, this message translates to:
  /// **'+20 Pts'**
  String get earnPointsHeritageAmount;

  /// No description provided for @earnPointsHeritageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promote cultural preservation'**
  String get earnPointsHeritageSubtitle;

  /// No description provided for @rewardsPerksHeading.
  ///
  /// In en, this message translates to:
  /// **'REWARDS & PERKS YOU UNLOCK:'**
  String get rewardsPerksHeading;

  /// No description provided for @rewardEcoGuardianBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Eco Guardian Badge'**
  String get rewardEcoGuardianBadgeTitle;

  /// No description provided for @rewardEcoGuardianBadgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stand out on leaderboards & reviews'**
  String get rewardEcoGuardianBadgeSubtitle;

  /// No description provided for @rewardPartnerDiscountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner Discounts'**
  String get rewardPartnerDiscountsTitle;

  /// No description provided for @rewardPartnerDiscountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'5%-15% off at verified eco-stays & cafes'**
  String get rewardPartnerDiscountsSubtitle;

  /// No description provided for @rewardFreePremiumPerksTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Premium Perks'**
  String get rewardFreePremiumPerksTitle;

  /// No description provided for @rewardFreePremiumPerksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock AR guides & offline maps with points'**
  String get rewardFreePremiumPerksSubtitle;

  /// No description provided for @rewardRealWorldImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-World Impact'**
  String get rewardRealWorldImpactTitle;

  /// No description provided for @rewardRealWorldImpactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach 500 Pts & we plant a tree in SL for you!'**
  String get rewardRealWorldImpactSubtitle;

  /// No description provided for @gotItKeepExploring.
  ///
  /// In en, this message translates to:
  /// **'GOT IT, KEEP EXPLORING'**
  String get gotItKeepExploring;

  /// No description provided for @guideCommandHub.
  ///
  /// In en, this message translates to:
  /// **'GUIDE COMMAND HUB'**
  String get guideCommandHub;

  /// No description provided for @guideCommandHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access to your guide tools'**
  String get guideCommandHubSubtitle;

  /// No description provided for @activeStatusBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeStatusBadge;

  /// No description provided for @tourDashboard.
  ///
  /// In en, this message translates to:
  /// **'Tour Dashboard'**
  String get tourDashboard;

  /// No description provided for @tourDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active tour, QR, listing & safety'**
  String get tourDashboardSubtitle;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @earningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payouts & stats'**
  String get earningsSubtitle;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @clientsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'History & notes'**
  String get clientsSubtitle;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @tourRequests.
  ///
  /// In en, this message translates to:
  /// **'Tour requests'**
  String get tourRequests;

  /// No description provided for @unreadRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} new request} other{{count} new requests}}'**
  String unreadRequestsCount(int count);

  /// No description provided for @packages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packages;

  /// No description provided for @customTourPricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom tour pricing'**
  String get customTourPricingSubtitle;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @manageTeam.
  ///
  /// In en, this message translates to:
  /// **'Manage team'**
  String get manageTeam;

  /// No description provided for @manageTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Team, roles & branding'**
  String get manageTeamSubtitle;

  /// No description provided for @becomeAGuide.
  ///
  /// In en, this message translates to:
  /// **'Become a Guide'**
  String get becomeAGuide;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @familySharing.
  ///
  /// In en, this message translates to:
  /// **'Family Sharing'**
  String get familySharing;

  /// No description provided for @scanGuideQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Guide QR'**
  String get scanGuideQr;

  /// No description provided for @oracleLens.
  ///
  /// In en, this message translates to:
  /// **'Oracle Lens'**
  String get oracleLens;

  /// No description provided for @bilingualToggle.
  ///
  /// In en, this message translates to:
  /// **'Bilingual (EN/SI)'**
  String get bilingualToggle;

  /// No description provided for @emergencyProtocol.
  ///
  /// In en, this message translates to:
  /// **'Emergency Protocol'**
  String get emergencyProtocol;

  /// No description provided for @rateTheApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateTheApp;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteButtonLabel;

  /// No description provided for @genericErrorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericErrorWithDetails(String error);

  /// No description provided for @signOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get signOutDialogTitle;

  /// No description provided for @confirmSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOutMessage;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Join Hidden Gems SL! 🌍 https://hiddengems.lk'**
  String get shareAppMessage;

  /// No description provided for @shareAppSubject.
  ///
  /// In en, this message translates to:
  /// **'Join me on Hidden Gems SL!'**
  String get shareAppSubject;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please restart the app.'**
  String get somethingWentWrong;

  /// No description provided for @cameraPermissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Required'**
  String get cameraPermissionRequiredTitle;

  /// No description provided for @cameraPermissionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required for the AR experience. Please enable it in Settings.'**
  String get cameraPermissionRequiredMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @liveScanningComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Live scanning is coming soon.\n\nReal-time landmark and object recognition through your camera is on the way. We\'ll let you know the moment it\'s ready.'**
  String get liveScanningComingSoonMessage;

  /// No description provided for @landmarkScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Landmark scanner'**
  String get landmarkScannerTitle;

  /// No description provided for @identifyingLabel.
  ///
  /// In en, this message translates to:
  /// **'Identifying…'**
  String get identifyingLabel;

  /// No description provided for @analyzeLandmarkButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze landmark'**
  String get analyzeLandmarkButton;

  /// No description provided for @unlockLandmarkScanningTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock landmark scanning'**
  String get unlockLandmarkScanningTitle;

  /// No description provided for @unlockLandmarkScanningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any site to reveal its hidden history.'**
  String get unlockLandmarkScanningSubtitle;

  /// No description provided for @oracleVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Oracle verified'**
  String get oracleVerifiedLabel;

  /// No description provided for @mapLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load map data: {error}'**
  String mapLoadErrorMessage(String error);

  /// No description provided for @guideLiveMarkerLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR GUIDE (LIVE)'**
  String get guideLiveMarkerLabel;

  /// No description provided for @vehicleMarkerLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR VEHICLE'**
  String get vehicleMarkerLabel;

  /// No description provided for @meetingPointMarkerLabel.
  ///
  /// In en, this message translates to:
  /// **'MEETING POINT: {pointName}'**
  String meetingPointMarkerLabel(String pointName);

  /// No description provided for @sosEmergencySignalTitle.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY SIGNAL'**
  String get sosEmergencySignalTitle;

  /// No description provided for @sosGuideTriggeredMessage.
  ///
  /// In en, this message translates to:
  /// **'YOUR GUIDE HAS TRIGGERED AN SOS'**
  String get sosGuideTriggeredMessage;

  /// No description provided for @sosSafetyProtocolsTitle.
  ///
  /// In en, this message translates to:
  /// **'SAFETY PROTOCOLS'**
  String get sosSafetyProtocolsTitle;

  /// No description provided for @sosProtocolStayInLocation.
  ///
  /// In en, this message translates to:
  /// **'1. Stay in your current location.'**
  String get sosProtocolStayInLocation;

  /// No description provided for @sosProtocolOpenLiveMap.
  ///
  /// In en, this message translates to:
  /// **'2. Open your live map to track the guide.'**
  String get sosProtocolOpenLiveMap;

  /// No description provided for @sosProtocolWaitForHelp.
  ///
  /// In en, this message translates to:
  /// **'3. Wait for emergency services or guide signal.'**
  String get sosProtocolWaitForHelp;

  /// No description provided for @sosAcknowledgeButton.
  ///
  /// In en, this message translates to:
  /// **'ACKNOWLEDGE'**
  String get sosAcknowledgeButton;

  /// No description provided for @distanceAwayLabel.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String distanceAwayLabel(String distance);

  /// No description provided for @offlineRouteMapSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offline route map saved successfully!'**
  String get offlineRouteMapSavedSuccess;

  /// No description provided for @cannotSaveMapSaveTripFirst.
  ///
  /// In en, this message translates to:
  /// **'Cannot save map. Please save the trip plan first!'**
  String get cannotSaveMapSaveTripFirst;

  /// No description provided for @saveTripAction.
  ///
  /// In en, this message translates to:
  /// **'SAVE TRIP'**
  String get saveTripAction;

  /// No description provided for @failedToSaveMapError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save map: {error}'**
  String failedToSaveMapError(String error);

  /// No description provided for @mapMarkerDaySnippet.
  ///
  /// In en, this message translates to:
  /// **'Day {day} • {time}'**
  String mapMarkerDaySnippet(int day, String time);

  /// No description provided for @visualRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Route'**
  String get visualRouteTitle;

  /// No description provided for @journeyVisualizerTitle.
  ///
  /// In en, this message translates to:
  /// **'Journey Visualizer'**
  String get journeyVisualizerTitle;

  /// No description provided for @journeyVisualizerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{dayCount} Days across {destination}'**
  String journeyVisualizerSubtitle(int dayCount, String destination);

  /// No description provided for @saveOfflineMapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save Offline Map'**
  String get saveOfflineMapTooltip;

  /// No description provided for @focusButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get focusButtonLabel;

  /// No description provided for @planRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Plan removed from Oracle cache'**
  String get planRemovedSnackbar;

  /// No description provided for @viewInArLabel.
  ///
  /// In en, this message translates to:
  /// **'View in AR'**
  String get viewInArLabel;

  /// No description provided for @savedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved trips'**
  String get savedTripsTitle;

  /// No description provided for @clearSavedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear saved trips'**
  String get clearSavedTripsTitle;

  /// No description provided for @clearSavedTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove all saved trips from this device.'**
  String get clearSavedTripsMessage;

  /// No description provided for @eraseAllButton.
  ///
  /// In en, this message translates to:
  /// **'Erase all'**
  String get eraseAllButton;

  /// No description provided for @noSavedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved trips yet'**
  String get noSavedTripsTitle;

  /// No description provided for @noSavedTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip to see it saved here.'**
  String get noSavedTripsSubtitle;

  /// No description provided for @unknownDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDateLabel;

  /// No description provided for @noArSpotsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'No AR spots in this plan'**
  String get noArSpotsSnackbar;

  /// No description provided for @tripRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'{fromCity} → {destinationCity}'**
  String tripRouteLabel(String fromCity, String destinationCity);

  /// No description provided for @tripDaysChip.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day} other{{days} days}}'**
  String tripDaysChip(int days);

  /// No description provided for @tripBudgetChip.
  ///
  /// In en, this message translates to:
  /// **'Rs {amount}'**
  String tripBudgetChip(String amount);

  /// No description provided for @arBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'AR'**
  String get arBadgeLabel;

  /// No description provided for @savedTimeAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved {timeAgo}'**
  String savedTimeAgoLabel(String timeAgo);

  /// No description provided for @minutesAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgoShort(int minutes);

  /// No description provided for @hoursAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgoShort(int hours);

  /// No description provided for @daysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgoShort(int days);

  /// No description provided for @weeksAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String weeksAgoShort(int weeks);

  /// No description provided for @loadingConsultingBrain.
  ///
  /// In en, this message translates to:
  /// **'Consulting HiddenGems.lk Brain...'**
  String get loadingConsultingBrain;

  /// No description provided for @loadingTipTrainSchedules.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Sri Lanka train schedules...'**
  String get loadingTipTrainSchedules;

  /// No description provided for @loadingTipWeatherPatterns.
  ///
  /// In en, this message translates to:
  /// **'Checking seasonal weather patterns...'**
  String get loadingTipWeatherPatterns;

  /// No description provided for @loadingTipClusteringGems.
  ///
  /// In en, this message translates to:
  /// **'Clustering the best hidden gems nearby...'**
  String get loadingTipClusteringGems;

  /// No description provided for @loadingTipBudgetBuffer.
  ///
  /// In en, this message translates to:
  /// **'Calculating budget with 10% safety buffer...'**
  String get loadingTipBudgetBuffer;

  /// No description provided for @loadingTipCraftingPlan.
  ///
  /// In en, this message translates to:
  /// **'Crafting your personalised day plan...'**
  String get loadingTipCraftingPlan;

  /// No description provided for @loadingTipRainDayPlanB.
  ///
  /// In en, this message translates to:
  /// **'Adding rain-day alternatives (Plan B)...'**
  String get loadingTipRainDayPlanB;

  /// No description provided for @loadingTipFinalisingExperts.
  ///
  /// In en, this message translates to:
  /// **'Finalising tips from local experts...'**
  String get loadingTipFinalisingExperts;

  /// No description provided for @loadingOfflineRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE RECOVERY'**
  String get loadingOfflineRecoveryTitle;

  /// No description provided for @loadingManifestingTitle.
  ///
  /// In en, this message translates to:
  /// **'MANIFESTING'**
  String get loadingManifestingTitle;

  /// No description provided for @loadingOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Synthesizing Local Memories…'**
  String get loadingOfflineSubtitle;

  /// No description provided for @loadingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'THE CONNECTION FADED'**
  String get loadingErrorTitle;

  /// No description provided for @loadingRetryStatus.
  ///
  /// In en, this message translates to:
  /// **'Re-Consulting Oracle...'**
  String get loadingRetryStatus;

  /// No description provided for @loadingErrorRetryButton.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get loadingErrorRetryButton;

  /// No description provided for @loadingErrorRefineButton.
  ///
  /// In en, this message translates to:
  /// **'REFINE REQUEST'**
  String get loadingErrorRefineButton;

  /// No description provided for @fieldNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Field Notes'**
  String get fieldNotesTitle;

  /// No description provided for @heritageSiteLocked.
  ///
  /// In en, this message translates to:
  /// **'Heritage Site Locked'**
  String get heritageSiteLocked;

  /// No description provided for @lockOverlayDescription.
  ///
  /// In en, this message translates to:
  /// **'This Oracle Vision is reserved for Premium Explorers. Watch a short Ad to unlock this place for today.'**
  String get lockOverlayDescription;

  /// No description provided for @watchAdToUnlock.
  ///
  /// In en, this message translates to:
  /// **'WATCH AD TO UNLOCK'**
  String get watchAdToUnlock;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @etiquetteTipReusableBottle.
  ///
  /// In en, this message translates to:
  /// **'Carry a reusable water bottle'**
  String get etiquetteTipReusableBottle;

  /// No description provided for @etiquetteTipAvoidPlastic.
  ///
  /// In en, this message translates to:
  /// **'Avoid plastic single-use bags'**
  String get etiquetteTipAvoidPlastic;

  /// No description provided for @etiquetteTipRespectWildlife.
  ///
  /// In en, this message translates to:
  /// **'Respect local wildlife and plants'**
  String get etiquetteTipRespectWildlife;

  /// No description provided for @etiquetteTipRemoveShoes.
  ///
  /// In en, this message translates to:
  /// **'Remove shoes and hats before entering'**
  String get etiquetteTipRemoveShoes;

  /// No description provided for @etiquetteTipDressModestly.
  ///
  /// In en, this message translates to:
  /// **'Dress modestly (cover shoulders and knees)'**
  String get etiquetteTipDressModestly;

  /// No description provided for @etiquetteTipAskPhotoPermission.
  ///
  /// In en, this message translates to:
  /// **'Ask permission before taking photos of people'**
  String get etiquetteTipAskPhotoPermission;

  /// No description provided for @etiquetteTipNoBackToStatues.
  ///
  /// In en, this message translates to:
  /// **'Do not pose for photos with your back to statues'**
  String get etiquetteTipNoBackToStatues;

  /// No description provided for @etiquetteTipStayOnTrails.
  ///
  /// In en, this message translates to:
  /// **'Stay on marked trails to protect flora'**
  String get etiquetteTipStayOnTrails;

  /// No description provided for @etiquetteTipPackOutTrash.
  ///
  /// In en, this message translates to:
  /// **'Pack out all your trash (Leave no trace)'**
  String get etiquetteTipPackOutTrash;

  /// No description provided for @etiquetteTipNoFeedingAnimals.
  ///
  /// In en, this message translates to:
  /// **'Do not feed or disturb wild animals'**
  String get etiquetteTipNoFeedingAnimals;

  /// No description provided for @etiquetteTipNoSoapInPools.
  ///
  /// In en, this message translates to:
  /// **'Avoid using soap/shampoo in natural pools'**
  String get etiquetteTipNoSoapInPools;

  /// No description provided for @arTierHeritageShort.
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get arTierHeritageShort;

  /// No description provided for @arTierExploreShort.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get arTierExploreShort;

  /// No description provided for @arTierStoryShort.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get arTierStoryShort;

  /// No description provided for @notAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailableShort;

  /// No description provided for @arBadgeHeritage.
  ///
  /// In en, this message translates to:
  /// **'HERITAGE AR'**
  String get arBadgeHeritage;

  /// No description provided for @arBadgeExplore.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE AR'**
  String get arBadgeExplore;

  /// No description provided for @arBadgeStory.
  ///
  /// In en, this message translates to:
  /// **'STORY VIEW'**
  String get arBadgeStory;

  /// No description provided for @noRiskTagsFound.
  ///
  /// In en, this message translates to:
  /// **'No manifestations detected.'**
  String get noRiskTagsFound;

  /// No description provided for @noFacilitiesFound.
  ///
  /// In en, this message translates to:
  /// **'Minimal provisions found.'**
  String get noFacilitiesFound;

  /// No description provided for @fieldNoteMobileSignal.
  ///
  /// In en, this message translates to:
  /// **'Mobile Signal'**
  String get fieldNoteMobileSignal;

  /// No description provided for @fieldNoteRoadCondition.
  ///
  /// In en, this message translates to:
  /// **'Road Condition'**
  String get fieldNoteRoadCondition;

  /// No description provided for @fieldNoteActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get fieldNoteActivities;

  /// No description provided for @fieldNotePopularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get fieldNotePopularity;

  /// No description provided for @fieldNoteFamilyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Family Friendly'**
  String get fieldNoteFamilyFriendly;

  /// No description provided for @fieldNoteBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get fieldNoteBudget;

  /// No description provided for @fieldNoteToilets.
  ///
  /// In en, this message translates to:
  /// **'Toilets'**
  String get fieldNoteToilets;

  /// No description provided for @fieldNoteFoodNearby.
  ///
  /// In en, this message translates to:
  /// **'Food Nearby'**
  String get fieldNoteFoodNearby;

  /// No description provided for @fieldNoteWheelchairAccess.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Access'**
  String get fieldNoteWheelchairAccess;

  /// No description provided for @fieldNoteCamping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get fieldNoteCamping;

  /// No description provided for @fieldNoteSafetyLevel.
  ///
  /// In en, this message translates to:
  /// **'Safety Level'**
  String get fieldNoteSafetyLevel;

  /// No description provided for @fieldNoteWildlifeHazard.
  ///
  /// In en, this message translates to:
  /// **'Wildlife Hazard'**
  String get fieldNoteWildlifeHazard;

  /// No description provided for @fieldNoteGuideRequired.
  ///
  /// In en, this message translates to:
  /// **'Guide Required'**
  String get fieldNoteGuideRequired;

  /// No description provided for @fieldNoteRainSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Rain Sensitivity'**
  String get fieldNoteRainSensitivity;

  /// No description provided for @fieldNoteMonsoonNote.
  ///
  /// In en, this message translates to:
  /// **'Monsoon Note'**
  String get fieldNoteMonsoonNote;

  /// No description provided for @fieldNoteSurfing.
  ///
  /// In en, this message translates to:
  /// **'Surfing'**
  String get fieldNoteSurfing;

  /// No description provided for @fieldNoteHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get fieldNoteHeight;

  /// No description provided for @fieldNoteLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get fieldNoteLength;

  /// No description provided for @bookmarkAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'✨ Marked in your journey!'**
  String get bookmarkAddedSnackbar;

  /// No description provided for @bookmarkRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Removed from bookmarks.'**
  String get bookmarkRemovedSnackbar;

  /// No description provided for @itineraryAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'🗺️ {placeName} added to your destiny!'**
  String itineraryAddedSnackbar(String placeName);

  /// No description provided for @itineraryRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Removed from itinerary.'**
  String get itineraryRemovedSnackbar;

  /// No description provided for @featureNameHeritageSessions.
  ///
  /// In en, this message translates to:
  /// **'Heritage Sessions'**
  String get featureNameHeritageSessions;

  /// No description provided for @featureNameOracleQueries.
  ///
  /// In en, this message translates to:
  /// **'Oracle Queries'**
  String get featureNameOracleQueries;

  /// No description provided for @bonusSessionUnlockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Bonus Session Unlocked! Try launching again.'**
  String get bonusSessionUnlockedSnackbar;

  /// No description provided for @oracleRewardActiveSnackbar.
  ///
  /// In en, this message translates to:
  /// **'✨ Oracle reward active! AR session unlocked.'**
  String get oracleRewardActiveSnackbar;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @arBrandNameHeritage.
  ///
  /// In en, this message translates to:
  /// **'Heritage AR'**
  String get arBrandNameHeritage;

  /// No description provided for @arBrandNameExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore AR'**
  String get arBrandNameExplore;

  /// No description provided for @bonusDownloadUnlockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Bonus Download Unlocked! Try downloading again.'**
  String get bonusDownloadUnlockedSnackbar;

  /// No description provided for @featureNameOfflineDownloads.
  ///
  /// In en, this message translates to:
  /// **'Offline Downloads'**
  String get featureNameOfflineDownloads;

  /// No description provided for @myBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookingsTitle;

  /// No description provided for @myBookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get myBookingsEmptyTitle;

  /// No description provided for @myBookingsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requests you send to guides will show up here with their status.'**
  String get myBookingsEmptySubtitle;

  /// No description provided for @guideFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guideFallbackName;

  /// No description provided for @guestCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 guest} other{{count} guests}}'**
  String guestCountLabel(int count);

  /// No description provided for @paymentPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentPaidLabel;

  /// No description provided for @payGuideDirectlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay guide directly'**
  String get payGuideDirectlyLabel;

  /// No description provided for @bookingStatusPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get bookingStatusPendingLabel;

  /// No description provided for @bookingStatusAcceptedLabel.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get bookingStatusAcceptedLabel;

  /// No description provided for @bookingStatusSessionReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get bookingStatusSessionReadyLabel;

  /// No description provided for @bookingStatusDeclinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bookingStatusDeclinedLabel;

  /// No description provided for @bookingStatusExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bookingStatusExpiredLabel;

  /// No description provided for @bookingStatusCancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelledLabel;

  /// No description provided for @bookingStatusCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompletedLabel;

  /// No description provided for @bookingStatusDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingStatusDefaultLabel;

  /// No description provided for @requestBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Request booking'**
  String get requestBookingTitle;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @guestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guestsLabel;

  /// No description provided for @specialInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get specialInstructionsLabel;

  /// No description provided for @numberOfGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of guests'**
  String get numberOfGuestsLabel;

  /// No description provided for @notesFieldHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. We are traveling with seniors, need a low-walking route...'**
  String get notesFieldHint;

  /// No description provided for @sendRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequestButton;

  /// No description provided for @userNotAuthenticatedError.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticatedError;

  /// No description provided for @guideQuotaExceededError.
  ///
  /// In en, this message translates to:
  /// **'This guide has reached their maximum booking quota for the month. Please try again next month or select another guide.'**
  String get guideQuotaExceededError;

  /// No description provided for @noGuideListingError.
  ///
  /// In en, this message translates to:
  /// **'This guide hasn\'t set up their profile yet, so they can\'t accept bookings right now. Please try another guide.'**
  String get noGuideListingError;

  /// No description provided for @sendQuoteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your price'**
  String get sendQuoteDialogTitle;

  /// No description provided for @sendQuoteAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sendQuoteAmountLabel;

  /// No description provided for @sendQuoteConfirmButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept & send quote'**
  String get sendQuoteConfirmButtonLabel;

  /// No description provided for @payNowButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNowButtonLabel;

  /// No description provided for @paymentUnavailableError.
  ///
  /// In en, this message translates to:
  /// **'This booking can\'t be paid right now — it may already be paid, or the price may have changed. Pull to refresh and try again.'**
  String get paymentUnavailableError;

  /// No description provided for @receiptTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get receiptTitleLabel;

  /// No description provided for @receiptReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get receiptReferenceLabel;

  /// No description provided for @guideLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guideLabelShort;

  /// No description provided for @receiptPaidOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get receiptPaidOnLabel;

  /// No description provided for @receiptPaymentIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment ID'**
  String get receiptPaymentIdLabel;

  /// No description provided for @receiptTotalPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get receiptTotalPaidLabel;

  /// No description provided for @requestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSentTitle;

  /// No description provided for @requestSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Your booking request has been sent to the guide. You\'ll get a notification once they respond.'**
  String get requestSentMessage;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @noBookingsToSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'No accepted bookings to sync yet.'**
  String get noBookingsToSyncMessage;

  /// No description provided for @calendarEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour: {touristName} ({guestCount} guests)'**
  String calendarEventTitle(String touristName, int guestCount);

  /// No description provided for @defaultTouristName.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get defaultTouristName;

  /// No description provided for @calendarSyncSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Synced 1 booking to your calendar.} other{Synced {count} bookings to your calendar.}}'**
  String calendarSyncSuccessMessage(int count);

  /// No description provided for @calendarSyncFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync failed: {error}'**
  String calendarSyncFailedMessage(String error);

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view booking requests.'**
  String get loginRequiredMessage;

  /// No description provided for @bookingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsScreenTitle;

  /// No description provided for @syncToCalendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync to calendar'**
  String get syncToCalendarTooltip;

  /// No description provided for @inboxLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading inbox: {error}'**
  String inboxLoadErrorMessage(String error);

  /// No description provided for @filterReadyForTour.
  ///
  /// In en, this message translates to:
  /// **'Ready for tour'**
  String get filterReadyForTour;

  /// No description provided for @emptyBookingsMessage.
  ///
  /// In en, this message translates to:
  /// **'No {filter} booking requests.'**
  String emptyBookingsMessage(String filter);

  /// No description provided for @touristIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Tourist #{touristId}'**
  String touristIdLabel(String touristId);

  /// No description provided for @requestedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested {time}'**
  String requestedAtLabel(String time);

  /// No description provided for @priorityBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY'**
  String get priorityBadgeLabel;

  /// No description provided for @tourDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tour Date'**
  String get tourDateLabel;

  /// No description provided for @guestsCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 Person} other{{count} Person(s)}}'**
  String guestsCountValue(int count);

  /// No description provided for @quotedPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Quoted Price'**
  String get quotedPriceLabel;

  /// No description provided for @netPayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Net Payout'**
  String get netPayoutLabel;

  /// No description provided for @notAvailableAbbrev.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailableAbbrev;

  /// No description provided for @tourNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Tour notes / requirements'**
  String get tourNotesLabel;

  /// No description provided for @responseNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Your response note: {note}'**
  String responseNoteLabel(String note);

  /// No description provided for @declineButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButtonLabel;

  /// No description provided for @acceptButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButtonLabel;

  /// No description provided for @startTourSessionButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Start / launch tour session'**
  String get startTourSessionButtonLabel;

  /// No description provided for @bookingAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'🎉 Booking accepted & Tour Session created!'**
  String get bookingAcceptedMessage;

  /// No description provided for @acceptBookingErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error accepting booking: {error}'**
  String acceptBookingErrorMessage(String error);

  /// No description provided for @declineBookingDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Booking?'**
  String get declineBookingDialogTitle;

  /// No description provided for @declineReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for declining (optional):'**
  String get declineReasonPrompt;

  /// No description provided for @declineReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fully booked on this date / Vehicle maintenance'**
  String get declineReasonHint;

  /// No description provided for @declineConfirmButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'DECLINE'**
  String get declineConfirmButtonLabel;

  /// No description provided for @bookingDeclinedMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking declined.'**
  String get bookingDeclinedMessage;

  /// No description provided for @declineBookingErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error declining booking: {error}'**
  String declineBookingErrorMessage(String error);

  /// No description provided for @meetingPointPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'To be confirmed in chat'**
  String get meetingPointPendingLabel;

  /// No description provided for @bookingAcceptedResponseNote.
  ///
  /// In en, this message translates to:
  /// **'Booking Accepted! Session ready.'**
  String get bookingAcceptedResponseNote;

  /// No description provided for @bookingDeclinedDefaultNote.
  ///
  /// In en, this message translates to:
  /// **'Declined by guide.'**
  String get bookingDeclinedDefaultNote;

  /// No description provided for @statusLabelCancelledByTourist.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by tourist'**
  String get statusLabelCancelledByTourist;

  /// No description provided for @statusLabelCancelledByGuide.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by guide'**
  String get statusLabelCancelledByGuide;

  /// No description provided for @reviewSubmitSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Transmission Complete. Thank you for your feedback.'**
  String get reviewSubmitSuccessMessage;

  /// No description provided for @reviewSubmitErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Transmission Error: {error}'**
  String reviewSubmitErrorMessage(String error);

  /// No description provided for @overallExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'OVERALL EXPERIENCE'**
  String get overallExperienceLabel;

  /// No description provided for @missionFeedbackEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MISSION FEEDBACK'**
  String get missionFeedbackEyebrow;

  /// No description provided for @rateGuidePerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your guide\'s performance.'**
  String get rateGuidePerformanceTitle;

  /// No description provided for @trustScoreDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Your data is used to calculate the guide\'s Trust Score. Be objective and fair.'**
  String get trustScoreDisclaimer;

  /// No description provided for @ratingScaleAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'AVERAGE'**
  String get ratingScaleAverageLabel;

  /// No description provided for @ratingScaleExceptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'EXCEPTIONAL'**
  String get ratingScaleExceptionalLabel;

  /// No description provided for @knowledgeFactorLabel.
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE'**
  String get knowledgeFactorLabel;

  /// No description provided for @communicationFactorLabel.
  ///
  /// In en, this message translates to:
  /// **'COMMUNICATION'**
  String get communicationFactorLabel;

  /// No description provided for @punctualityFactorLabel.
  ///
  /// In en, this message translates to:
  /// **'PUNCTUALITY'**
  String get punctualityFactorLabel;

  /// No description provided for @safetyFactorLabel.
  ///
  /// In en, this message translates to:
  /// **'SAFETY'**
  String get safetyFactorLabel;

  /// No description provided for @fieldNotesLabelUppercase.
  ///
  /// In en, this message translates to:
  /// **'FIELD NOTES'**
  String get fieldNotesLabelUppercase;

  /// No description provided for @commentFieldHint.
  ///
  /// In en, this message translates to:
  /// **'What impressed you? Where could they improve?'**
  String get commentFieldHint;

  /// No description provided for @transmitFeedbackButton.
  ///
  /// In en, this message translates to:
  /// **'TRANSMIT FEEDBACK'**
  String get transmitFeedbackButton;

  /// No description provided for @familyShareLinkLimitReached.
  ///
  /// In en, this message translates to:
  /// **'⚠️ You\'ve reached the limit of {maxLinks} active share links. Remove one to create another.'**
  String familyShareLinkLimitReached(int maxLinks);

  /// No description provided for @familyShareRecipientNameRequired.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Please enter a recipient name.'**
  String get familyShareRecipientNameRequired;

  /// No description provided for @familyShareNoActiveSessionError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Start an active tour session first — there\'s nothing to share yet.'**
  String get familyShareNoActiveSessionError;

  /// No description provided for @familyShareLinkGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Mission link generated for \"{name}\"!'**
  String familyShareLinkGeneratedSuccess(String name);

  /// No description provided for @familyShareActiveLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Active links'**
  String get familyShareActiveLinksTitle;

  /// No description provided for @familyShareNewLinkButton.
  ///
  /// In en, this message translates to:
  /// **'+ New'**
  String get familyShareNewLinkButton;

  /// No description provided for @familyShareAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Family sharing'**
  String get familyShareAppBarTitle;

  /// No description provided for @familyShareHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let family track your trip status securely'**
  String get familyShareHeroSubtitle;

  /// No description provided for @familyShareNoActiveSessionNotice.
  ///
  /// In en, this message translates to:
  /// **'No active tour right now — start or join a tour to generate a live share link.'**
  String get familyShareNoActiveSessionNotice;

  /// No description provided for @familyShareEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'No active sharing links found'**
  String get familyShareEmptyStateMessage;

  /// No description provided for @familyShareExpiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get familyShareExpiredBadge;

  /// No description provided for @familyShareViewedCountBadge.
  ///
  /// In en, this message translates to:
  /// **'Viewed {count}x'**
  String familyShareViewedCountBadge(int count);

  /// No description provided for @familyShareLinkNoLongerValid.
  ///
  /// In en, this message translates to:
  /// **'No longer valid'**
  String get familyShareLinkNoLongerValid;

  /// No description provided for @familyShareLinkExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires {time}'**
  String familyShareLinkExpiresAt(String time);

  /// No description provided for @familyShareCopyLinkSnackbar.
  ///
  /// In en, this message translates to:
  /// **'📋 Invite code copied to clipboard!'**
  String get familyShareCopyLinkSnackbar;

  /// No description provided for @familyShareRemoveLinkDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Link?'**
  String get familyShareRemoveLinkDialogTitle;

  /// No description provided for @familyShareRemoveLinkDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will revoke \"{recipientName}\"\'s shared access.'**
  String familyShareRemoveLinkDialogBody(String recipientName);

  /// No description provided for @familyShareLinkRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Link for \"{recipientName}\" removed.'**
  String familyShareLinkRemovedSnackbar(String recipientName);

  /// No description provided for @familyShareRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get familyShareRemoveButton;

  /// No description provided for @familyShareCreateSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Create share link'**
  String get familyShareCreateSheetTitle;

  /// No description provided for @familyShareRecipientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient name'**
  String get familyShareRecipientNameLabel;

  /// No description provided for @familyShareRecipientNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Mom, Dad, Home office'**
  String get familyShareRecipientNameHint;

  /// No description provided for @familyShareExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get familyShareExpiryLabel;

  /// No description provided for @familyShareDuration4Hours.
  ///
  /// In en, this message translates to:
  /// **'4 hours'**
  String get familyShareDuration4Hours;

  /// No description provided for @familyShareDuration12Hours.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get familyShareDuration12Hours;

  /// No description provided for @familyShareDuration24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get familyShareDuration24Hours;

  /// No description provided for @familyShareToggleStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Share live status'**
  String get familyShareToggleStatusLabel;

  /// No description provided for @familyShareToggleIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Share guide identity'**
  String get familyShareToggleIdentityLabel;

  /// No description provided for @familyShareToggleMeetingPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Share meeting point'**
  String get familyShareToggleMeetingPointLabel;

  /// No description provided for @familyShareToggleEmergencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Share emergency alerts'**
  String get familyShareToggleEmergencyLabel;

  /// No description provided for @familyShareGenerateLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Generate link'**
  String get familyShareGenerateLinkButton;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryChauffeur.
  ///
  /// In en, this message translates to:
  /// **'Chauffeur'**
  String get categoryChauffeur;

  /// No description provided for @categorySiteGuide.
  ///
  /// In en, this message translates to:
  /// **'Site Guide'**
  String get categorySiteGuide;

  /// No description provided for @categoryAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get categoryAdventure;

  /// No description provided for @categoryWildlife.
  ///
  /// In en, this message translates to:
  /// **'Wildlife'**
  String get categoryWildlife;

  /// No description provided for @categoryHeritage.
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get categoryHeritage;

  /// No description provided for @categoryPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get categoryPhotography;

  /// No description provided for @marketplaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, language, or city...'**
  String get marketplaceSearchHint;

  /// No description provided for @verifiedGuidesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Verified guides'**
  String get verifiedGuidesEyebrow;

  /// No description provided for @findYourExpertTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your expert'**
  String get findYourExpertTitle;

  /// No description provided for @noVerifiedGuidesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No verified guides published yet.'**
  String get noVerifiedGuidesEmptyState;

  /// No description provided for @noGuidesFoundForQuery.
  ///
  /// In en, this message translates to:
  /// **'No guides found matching \'{query}\''**
  String noGuidesFoundForQuery(String query);

  /// No description provided for @signInToBrowseGuidesError.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse verified guides.'**
  String get signInToBrowseGuidesError;

  /// No description provided for @genericLoadGuidesError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading guides. Please try again.'**
  String get genericLoadGuidesError;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @reviewCountSuffix.
  ///
  /// In en, this message translates to:
  /// **' ({count})'**
  String reviewCountSuffix(int count);

  /// No description provided for @hourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'{currency} {rate}/hr'**
  String hourlyRateLabel(String currency, String rate);

  /// No description provided for @zenithPresenceSyncErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Zenith Presence Sync Error: {error}'**
  String zenithPresenceSyncErrorMessage(String error);

  /// No description provided for @couldNotGetLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Using default coordinates. ({error})'**
  String couldNotGetLocationMessage(String error);

  /// No description provided for @failedToUpdatePhaseMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update phase: {error}'**
  String failedToUpdatePhaseMessage(String error);

  /// No description provided for @setMeetingPointDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'SET MEETING POINT'**
  String get setMeetingPointDialogTitle;

  /// No description provided for @meetingPointHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., Temple Entrance, Bus Stand'**
  String get meetingPointHintText;

  /// No description provided for @cancelButtonUppercase.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelButtonUppercase;

  /// No description provided for @setHereButtonUppercase.
  ///
  /// In en, this message translates to:
  /// **'SET HERE'**
  String get setHereButtonUppercase;

  /// No description provided for @meetingPointUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Meeting point updated'**
  String get meetingPointUpdatedTitle;

  /// No description provided for @meetingPointUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'New meeting point: {name}'**
  String meetingPointUpdatedBody(String name);

  /// No description provided for @failedToSetMeetingPointMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to set meeting point: {error}'**
  String failedToSetMeetingPointMessage(String error);

  /// No description provided for @vehiclePositionMarkedMessage.
  ///
  /// In en, this message translates to:
  /// **'Vehicle position marked'**
  String get vehiclePositionMarkedMessage;

  /// No description provided for @failedToUpdateVehicleLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update vehicle location: {error}'**
  String failedToUpdateVehicleLocationMessage(String error);

  /// No description provided for @tourDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour dashboard'**
  String get tourDashboardTitle;

  /// No description provided for @bottomNavTour.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get bottomNavTour;

  /// No description provided for @bottomNavPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get bottomNavPlan;

  /// No description provided for @bottomNavReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get bottomNavReviews;

  /// No description provided for @bottomNavSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get bottomNavSafety;

  /// No description provided for @bottomNavListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get bottomNavListing;

  /// No description provided for @noActiveTourTitle.
  ///
  /// In en, this message translates to:
  /// **'No active tour'**
  String get noActiveTourTitle;

  /// No description provided for @noActiveTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new tour and generate a QR for your travelers to connect.'**
  String get noActiveTourSubtitle;

  /// No description provided for @addVehicleFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your vehicle in the \"My Listing\" tab first'**
  String get addVehicleFirstMessage;

  /// No description provided for @generateTourQrButton.
  ///
  /// In en, this message translates to:
  /// **'Generate tour QR'**
  String get generateTourQrButton;

  /// No description provided for @sessionDataUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Session data unavailable.'**
  String get sessionDataUnavailableMessage;

  /// No description provided for @upcomingTourSessionReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming tour session ready'**
  String get upcomingTourSessionReadyTitle;

  /// No description provided for @upcomingTourSessionReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Travelers and meeting point confirmed. Tap below when you and the travelers arrive at the meeting point to officially start the timer and tracking.'**
  String get upcomingTourSessionReadyMessage;

  /// No description provided for @startTourSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Start tour session'**
  String get startTourSessionButton;

  /// No description provided for @tourSessionStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'🚀 Tour Session Started!'**
  String get tourSessionStartedMessage;

  /// No description provided for @statLabelTravelers.
  ///
  /// In en, this message translates to:
  /// **'Travelers'**
  String get statLabelTravelers;

  /// No description provided for @statLabelRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get statLabelRating;

  /// No description provided for @statLabelServed.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get statLabelServed;

  /// No description provided for @updatePointButton.
  ///
  /// In en, this message translates to:
  /// **'Update point'**
  String get updatePointButton;

  /// No description provided for @setPointButton.
  ///
  /// In en, this message translates to:
  /// **'Set point'**
  String get setPointButton;

  /// No description provided for @markVehicleButton.
  ///
  /// In en, this message translates to:
  /// **'Mark vehicle'**
  String get markVehicleButton;

  /// No description provided for @joinStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Join status'**
  String get joinStatusLabel;

  /// No description provided for @openToScansLabel.
  ///
  /// In en, this message translates to:
  /// **'Open to scans'**
  String get openToScansLabel;

  /// No description provided for @lockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedLabel;

  /// No description provided for @joiningPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joining paused'**
  String get joiningPausedLabel;

  /// No description provided for @tapToRefreshJoinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to refresh join code'**
  String get tapToRefreshJoinCodeLabel;

  /// No description provided for @broadcastButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcastButtonLabel;

  /// No description provided for @sosAlertBroadcastedMessage.
  ///
  /// In en, this message translates to:
  /// **'SOS ALERT BROADCASTED!'**
  String get sosAlertBroadcastedMessage;

  /// No description provided for @connectedTravelersLabel.
  ///
  /// In en, this message translates to:
  /// **'Connected travelers'**
  String get connectedTravelersLabel;

  /// No description provided for @activeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeCountLabel(int count);

  /// No description provided for @waitingForScansLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for scans...'**
  String get waitingForScansLabel;

  /// No description provided for @phaseLabelAssembly.
  ///
  /// In en, this message translates to:
  /// **'ASSEMBLY'**
  String get phaseLabelAssembly;

  /// No description provided for @phaseLabelEnRoute.
  ///
  /// In en, this message translates to:
  /// **'EN ROUTE'**
  String get phaseLabelEnRoute;

  /// No description provided for @phaseLabelAtSite.
  ///
  /// In en, this message translates to:
  /// **'AT SITE'**
  String get phaseLabelAtSite;

  /// No description provided for @phaseLabelBreak.
  ///
  /// In en, this message translates to:
  /// **'BREAK'**
  String get phaseLabelBreak;

  /// No description provided for @phaseLabelReturning.
  ///
  /// In en, this message translates to:
  /// **'RETURNING'**
  String get phaseLabelReturning;

  /// No description provided for @stopTourSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Stop tour session'**
  String get stopTourSessionButton;

  /// No description provided for @selectVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get selectVehicleTitle;

  /// No description provided for @travelerTileLabel.
  ///
  /// In en, this message translates to:
  /// **'Traveler {shortId}'**
  String travelerTileLabel(String shortId);

  /// No description provided for @weatherHazardLoggedMessage.
  ///
  /// In en, this message translates to:
  /// **'✅ Weather hazard logged to Safety Console!'**
  String get weatherHazardLoggedMessage;

  /// No description provided for @errorLoggingIncidentMessage.
  ///
  /// In en, this message translates to:
  /// **'Error logging incident: {error}'**
  String errorLoggingIncidentMessage(String error);

  /// No description provided for @logIncidentButtonUppercase.
  ///
  /// In en, this message translates to:
  /// **'LOG INCIDENT'**
  String get logIncidentButtonUppercase;

  /// No description provided for @safetyConsoleButtonUppercase.
  ///
  /// In en, this message translates to:
  /// **'SAFETY CONSOLE'**
  String get safetyConsoleButtonUppercase;

  /// No description provided for @defaultMonsoonAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'🚨 EMERGENCY MONSOON ALERT'**
  String get defaultMonsoonAlertTitle;

  /// No description provided for @defaultMonsoonAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Severe weather warning in your tour district.'**
  String get defaultMonsoonAlertMessage;

  /// No description provided for @earningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// No description provided for @pleaseLogInViewEarningsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view earnings.'**
  String get pleaseLogInViewEarningsMessage;

  /// No description provided for @errorLoadingFinancialDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading financial data: {error}'**
  String errorLoadingFinancialDataMessage(String error);

  /// No description provided for @totalNetEarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total net earnings'**
  String get totalNetEarningsLabel;

  /// No description provided for @netPercentageLabel.
  ///
  /// In en, this message translates to:
  /// **'90% net'**
  String get netPercentageLabel;

  /// No description provided for @lkrAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'LKR {amount}'**
  String lkrAmountLabel(String amount);

  /// No description provided for @subStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get subStatPending;

  /// No description provided for @subStatPaidOut.
  ///
  /// In en, this message translates to:
  /// **'Paid out'**
  String get subStatPaidOut;

  /// No description provided for @subStatPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform fee'**
  String get subStatPlatformFee;

  /// No description provided for @requestPayoutButton.
  ///
  /// In en, this message translates to:
  /// **'Request payout'**
  String get requestPayoutButton;

  /// No description provided for @bankButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankButtonLabel;

  /// No description provided for @clientAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Client analytics'**
  String get clientAnalyticsTitle;

  /// No description provided for @analyticsStatCompletedTours.
  ///
  /// In en, this message translates to:
  /// **'Completed tours'**
  String get analyticsStatCompletedTours;

  /// No description provided for @analyticsStatUniqueClients.
  ///
  /// In en, this message translates to:
  /// **'Unique clients'**
  String get analyticsStatUniqueClients;

  /// No description provided for @analyticsStatRepeatRate.
  ///
  /// In en, this message translates to:
  /// **'Repeat rate'**
  String get analyticsStatRepeatRate;

  /// No description provided for @avgBookingValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg. booking value'**
  String get avgBookingValueLabel;

  /// No description provided for @clientAnalyticsLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat rate, unique clients & more — Pro tier'**
  String get clientAnalyticsLockedSubtitle;

  /// No description provided for @upgradeButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButtonLabel;

  /// No description provided for @filterChipAllBookings.
  ///
  /// In en, this message translates to:
  /// **'All Bookings'**
  String get filterChipAllBookings;

  /// No description provided for @filterChipPendingPayout.
  ///
  /// In en, this message translates to:
  /// **'⏳ Pending Payout'**
  String get filterChipPendingPayout;

  /// No description provided for @filterChipPaidOut.
  ///
  /// In en, this message translates to:
  /// **'✅ Paid Out'**
  String get filterChipPaidOut;

  /// No description provided for @filterChipDisputed.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Disputed'**
  String get filterChipDisputed;

  /// No description provided for @payoutStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payoutStatusPaid;

  /// No description provided for @payoutStatusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get payoutStatusDisputed;

  /// No description provided for @payoutStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get payoutStatusPending;

  /// No description provided for @tourBookingIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Tour booking #{id}'**
  String tourBookingIdLabel(String id);

  /// No description provided for @guestCountDateLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} guests · {date}'**
  String guestCountDateLabel(int count, String date);

  /// No description provided for @viaPayHereDateLabel.
  ///
  /// In en, this message translates to:
  /// **'via PayHere · {date}'**
  String viaPayHereDateLabel(String date);

  /// No description provided for @grossLkrLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross LKR {amount}'**
  String grossLkrLabel(String amount);

  /// No description provided for @noTransactionsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFoundTitle;

  /// No description provided for @noTransactionsFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you complete tour bookings, your net payouts\nwill appear here automatically.'**
  String get noTransactionsFoundSubtitle;

  /// No description provided for @noPendingFundsMessage.
  ///
  /// In en, this message translates to:
  /// **'No pending funds available for payout withdrawal.'**
  String get noPendingFundsMessage;

  /// No description provided for @requestPayoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Payout'**
  String get requestPayoutDialogTitle;

  /// No description provided for @requestPayoutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You are requesting a transfer of LKR {amount} to your registered Bank Account / Mobile Money wallet.\n\nTransfers are processed by the Oracle finance team within 24 business hours.'**
  String requestPayoutDialogMessage(String amount);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @confirmPayoutButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm payout'**
  String get confirmPayoutButton;

  /// No description provided for @payoutRequestSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Payout request submitted successfully!'**
  String get payoutRequestSubmittedMessage;

  /// No description provided for @payoutAccountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout Account Settings'**
  String get payoutAccountSettingsTitle;

  /// No description provided for @bankNameWalletProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Name / Wallet Provider'**
  String get bankNameWalletProviderLabel;

  /// No description provided for @accountPhoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Account / Phone Number'**
  String get accountPhoneNumberLabel;

  /// No description provided for @saveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// No description provided for @payoutAccountSettingsUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Payout account settings updated!'**
  String get payoutAccountSettingsUpdatedMessage;

  /// No description provided for @availabilityScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability & schedule'**
  String get availabilityScheduleTitle;

  /// No description provided for @whenYoureFreeToGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'When you\'re free to guide'**
  String get whenYoureFreeToGuideTitle;

  /// No description provided for @touristsOnlySeeOpenSlotsMessage.
  ///
  /// In en, this message translates to:
  /// **'Tourists only see slots you mark open.'**
  String get touristsOnlySeeOpenSlotsMessage;

  /// No description provided for @instantBookNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant book & notice'**
  String get instantBookNoticeTitle;

  /// No description provided for @instantBookLabel.
  ///
  /// In en, this message translates to:
  /// **'Instant book'**
  String get instantBookLabel;

  /// No description provided for @instantBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let tourists book you immediately, no manual approval'**
  String get instantBookSubtitle;

  /// No description provided for @advanceNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance notice'**
  String get advanceNoticeLabel;

  /// No description provided for @advanceNoticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum lead time before a tour starts'**
  String get advanceNoticeSubtitle;

  /// No description provided for @hoursShortLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} hrs'**
  String hoursShortLabel(String count);

  /// No description provided for @weeklyScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get weeklyScheduleTitle;

  /// No description provided for @weeklyScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Toggle the days you work and set your hours'**
  String get weeklyScheduleSubtitle;

  /// No description provided for @dayOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get dayOffLabel;

  /// No description provided for @blackoutDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Blackout dates'**
  String get blackoutDatesTitle;

  /// No description provided for @blackoutDatesCountSuffix.
  ///
  /// In en, this message translates to:
  /// **' ({count})'**
  String blackoutDatesCountSuffix(int count);

  /// No description provided for @addDateButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get addDateButtonLabel;

  /// No description provided for @noBlackoutDatesMessage.
  ///
  /// In en, this message translates to:
  /// **'No blackout dates yet — you\'re available according to your weekly schedule.'**
  String get noBlackoutDatesMessage;

  /// No description provided for @saveAvailabilityButton.
  ///
  /// In en, this message translates to:
  /// **'Save availability'**
  String get saveAvailabilityButton;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @clientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsTitle;

  /// No description provided for @pleaseLogInMessage.
  ///
  /// In en, this message translates to:
  /// **'Please log in.'**
  String get pleaseLogInMessage;

  /// No description provided for @noClientsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No clients yet'**
  String get noClientsYetTitle;

  /// No description provided for @noClientsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Once travelers book your tours, they\'ll appear here.'**
  String get noClientsYetSubtitle;

  /// No description provided for @travelerShortIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Traveler {shortId}'**
  String travelerShortIdLabel(String shortId);

  /// No description provided for @tourCountCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 tour} other{{count} tours}} completed · Last: {date}'**
  String tourCountCompletedLabel(int count, String date);

  /// No description provided for @clientStatTours.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get clientStatTours;

  /// No description provided for @clientStatTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get clientStatTotalSpent;

  /// No description provided for @clientStatLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get clientStatLastVisit;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @clientNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Preferences, allergies, memorable moments...'**
  String get clientNoteHint;

  /// No description provided for @saveNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNoteButton;

  /// No description provided for @noteSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSavedMessage;

  /// No description provided for @bookingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get bookingHistoryTitle;

  /// No description provided for @guestCountParenthesesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} guest(s)'**
  String guestCountParenthesesLabel(int count);

  /// No description provided for @becomeAGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a guide'**
  String get becomeAGuideTitle;

  /// No description provided for @fieldsMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Fields missing: Please fill all and upload documents.'**
  String get fieldsMissingMessage;

  /// No description provided for @uploadingDocumentsMessage.
  ///
  /// In en, this message translates to:
  /// **'Uploading documents...'**
  String get uploadingDocumentsMessage;

  /// No description provided for @documentsUploadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Guide documents could not be transmitted to the Oracle vault. Please verify your connection.'**
  String get documentsUploadFailureMessage;

  /// No description provided for @savingApplicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Saving application...'**
  String get savingApplicationMessage;

  /// No description provided for @synchronizingApplicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing application...'**
  String get synchronizingApplicationMessage;

  /// No description provided for @applicationSubmittedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Application submitted successfully!'**
  String get applicationSubmittedSuccessMessage;

  /// No description provided for @authRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please login again.'**
  String get authRequiredMessage;

  /// No description provided for @cameraAccessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera access denied or error: {error}'**
  String cameraAccessDeniedMessage(String error);

  /// No description provided for @takeASelfieTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie'**
  String get takeASelfieTitle;

  /// No description provided for @uploadDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocumentTitle;

  /// No description provided for @cameraOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraOptionLabel;

  /// No description provided for @galleryOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryOptionLabel;

  /// No description provided for @errorGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGenericMessage(String error);

  /// No description provided for @verifyingYourDetailsMessage.
  ///
  /// In en, this message translates to:
  /// **'Verifying your details...'**
  String get verifyingYourDetailsMessage;

  /// No description provided for @credentialsBeingVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your credentials are being securely verified.'**
  String get credentialsBeingVerifiedMessage;

  /// No description provided for @applicationSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get applicationSubmittedTitle;

  /// No description provided for @applicationSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Our team will review your documents and let you know once a decision is made.'**
  String get applicationSubmittedMessage;

  /// No description provided for @returnToProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Return to profile'**
  String get returnToProfileButton;

  /// No description provided for @applicationUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Application under review'**
  String get applicationUnderReviewTitle;

  /// No description provided for @applicationUnderReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Your guide application has been submitted and is currently being reviewed. You will be notified once a decision is made.'**
  String get applicationUnderReviewMessage;

  /// No description provided for @applicationRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application rejected'**
  String get applicationRejectedTitle;

  /// No description provided for @applicationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}\n\nYou can re-submit your application below once you fix the required items.'**
  String applicationRejectedMessage(String reason);

  /// No description provided for @defaultRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Documents incomplete or unclear.'**
  String get defaultRejectionReason;

  /// No description provided for @guidePollRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Please ensure your license documents and photos are clear and valid.'**
  String get guidePollRejectionReason;

  /// No description provided for @approvedGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'You are an approved guide'**
  String get approvedGuideTitle;

  /// No description provided for @approvedGuideMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your guide identity is active. You can access the Guide Dashboard from your profile.'**
  String get approvedGuideMessage;

  /// No description provided for @shareLocalKnowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your local knowledge'**
  String get shareLocalKnowledgeTitle;

  /// No description provided for @guideTravelersEarnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guide travelers and earn on your own schedule.'**
  String get guideTravelersEarnSubtitle;

  /// No description provided for @guideCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Guide category'**
  String get guideCategoryLabel;

  /// No description provided for @categoryNational.
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get categoryNational;

  /// No description provided for @categoryProvincial.
  ///
  /// In en, this message translates to:
  /// **'Provincial'**
  String get categoryProvincial;

  /// No description provided for @categorySite.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get categorySite;

  /// No description provided for @licenseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get licenseNumberLabel;

  /// No description provided for @licenseNumberHint.
  ///
  /// In en, this message translates to:
  /// **'SLTDA-XXXX-XXXX'**
  String get licenseNumberHint;

  /// No description provided for @shortBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Short bio'**
  String get shortBioLabel;

  /// No description provided for @shortBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your experience...'**
  String get shortBioHint;

  /// No description provided for @verificationDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification documents'**
  String get verificationDocumentsTitle;

  /// No description provided for @guideLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Guide license'**
  String get guideLicenseLabel;

  /// No description provided for @nicPassportLabel.
  ///
  /// In en, this message translates to:
  /// **'NIC / passport'**
  String get nicPassportLabel;

  /// No description provided for @selfieForIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Selfie for identity'**
  String get selfieForIdentityLabel;

  /// No description provided for @submitApplicationButton.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get submitApplicationButton;

  /// No description provided for @tourPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour packages'**
  String get tourPackagesTitle;

  /// No description provided for @noPackagesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No packages yet'**
  String get noPackagesYetTitle;

  /// No description provided for @noPackagesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer half-day, full-day, or multi-day tour packages with fixed pricing.'**
  String get noPackagesYetSubtitle;

  /// No description provided for @inactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveLabel;

  /// No description provided for @durationGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'{hours}h · up to {guests} guests'**
  String durationGuestsLabel(String hours, String guests);

  /// No description provided for @currencyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'{currency} {price}'**
  String currencyPriceLabel(String currency, String price);

  /// No description provided for @newPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'New package'**
  String get newPackageTitle;

  /// No description provided for @editPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit package'**
  String get editPackageTitle;

  /// No description provided for @failedToSavePackageMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save package: {error}'**
  String failedToSavePackageMessage(String error);

  /// No description provided for @packageTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Package title'**
  String get packageTitleLabel;

  /// No description provided for @packageTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Full-day Sigiriya & Dambulla'**
  String get packageTitleHint;

  /// No description provided for @requiredFieldMessage.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredFieldMessage;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @packageDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What does this package include?'**
  String get packageDescriptionHint;

  /// No description provided for @durationHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (hours)'**
  String get durationHoursLabel;

  /// No description provided for @maxGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Max guests'**
  String get maxGuestsLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @inclusionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Inclusions (comma separated)'**
  String get inclusionsLabel;

  /// No description provided for @inclusionsHint.
  ///
  /// In en, this message translates to:
  /// **'Lunch, entrance fees, water'**
  String get inclusionsHint;

  /// No description provided for @includesVehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Includes vehicle'**
  String get includesVehicleLabel;

  /// No description provided for @activeBookableLabel.
  ///
  /// In en, this message translates to:
  /// **'Active (bookable by tourists)'**
  String get activeBookableLabel;

  /// No description provided for @savePackageButton.
  ///
  /// In en, this message translates to:
  /// **'Save package'**
  String get savePackageButton;

  /// No description provided for @availabilityScheduleUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Availability & schedule updated'**
  String get availabilityScheduleUpdatedMessage;

  /// No description provided for @errorSavingAvailabilityMessage.
  ///
  /// In en, this message translates to:
  /// **'Error saving availability: {error}'**
  String errorSavingAvailabilityMessage(String error);

  /// No description provided for @broadcastSentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Broadcast sent successfully'**
  String get broadcastSentSuccessMessage;

  /// No description provided for @broadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcastTitle;

  /// No description provided for @activeBroadcastsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active broadcasts'**
  String get activeBroadcastsTitle;

  /// No description provided for @messageToTravelersLabel.
  ///
  /// In en, this message translates to:
  /// **'Message to travelers'**
  String get messageToTravelersLabel;

  /// No description provided for @messageToTravelersHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your message to travelers...'**
  String get messageToTravelersHint;

  /// No description provided for @sendToAllTravelersButton.
  ///
  /// In en, this message translates to:
  /// **'Send to all travelers'**
  String get sendToAllTravelersButton;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @noActiveBroadcastsMessage.
  ///
  /// In en, this message translates to:
  /// **'No active broadcasts'**
  String get noActiveBroadcastsMessage;

  /// No description provided for @acksCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} acks'**
  String acksCountLabel(int count);

  /// No description provided for @expireButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Expire'**
  String get expireButtonLabel;

  /// No description provided for @broadcastTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get broadcastTypeGeneral;

  /// No description provided for @broadcastTypeWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get broadcastTypeWeather;

  /// No description provided for @broadcastTypeMeetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get broadcastTypeMeetingPoint;

  /// No description provided for @broadcastTypeDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get broadcastTypeDelay;

  /// No description provided for @broadcastTypeDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get broadcastTypeDeparture;

  /// No description provided for @broadcastTypeVehicleChange.
  ///
  /// In en, this message translates to:
  /// **'Vehicle change'**
  String get broadcastTypeVehicleChange;

  /// No description provided for @broadcastTypeSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get broadcastTypeSafety;

  /// No description provided for @broadcastPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get broadcastPriorityLow;

  /// No description provided for @broadcastPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get broadcastPriorityNormal;

  /// No description provided for @broadcastPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get broadcastPriorityHigh;

  /// No description provided for @broadcastPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get broadcastPriorityCritical;

  /// No description provided for @writeReviewButton.
  ///
  /// In en, this message translates to:
  /// **'WRITE REVIEW'**
  String get writeReviewButton;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @failedToLoadReviewsMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reviews. Please try again.'**
  String get failedToLoadReviewsMessage;

  /// No description provided for @premiumAnalyticsLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM ANALYTICS LOCKED'**
  String get premiumAnalyticsLockedTitle;

  /// No description provided for @premiumAnalyticsLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to PRO or ELITE to unlock deep insights into your performance, trust score, and tourist feedback.'**
  String get premiumAnalyticsLockedMessage;

  /// No description provided for @upgradeNowButton.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE NOW'**
  String get upgradeNowButton;

  /// No description provided for @trustScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust score'**
  String get trustScoreLabel;

  /// No description provided for @tierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze tier'**
  String get tierBronze;

  /// No description provided for @tierDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond tier'**
  String get tierDiamond;

  /// No description provided for @tierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold tier'**
  String get tierGold;

  /// No description provided for @tierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver tier'**
  String get tierSilver;

  /// No description provided for @miniStatTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get miniStatTrips;

  /// No description provided for @miniStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get miniStatRating;

  /// No description provided for @miniStatIncidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get miniStatIncidents;

  /// No description provided for @verifiedTripBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified trip'**
  String get verifiedTripBadge;

  /// No description provided for @touristShortIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Tourist {shortId}'**
  String touristShortIdLabel(String shortId);

  /// No description provided for @noReviewsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYetTitle;

  /// No description provided for @noReviewsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified participants can leave feedback after session completion.'**
  String get noReviewsYetSubtitle;

  /// No description provided for @guideProfileNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Guide profile not found'**
  String get guideProfileNotFoundMessage;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// No description provided for @noBioProvidedMessage.
  ///
  /// In en, this message translates to:
  /// **'No bio provided.'**
  String get noBioProvidedMessage;

  /// No description provided for @vehicleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleSectionTitle;

  /// No description provided for @vehicleDetailsNotProvidedMessage.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details not provided'**
  String get vehicleDetailsNotProvidedMessage;

  /// No description provided for @vehicleProvidedByGuideMessage.
  ///
  /// In en, this message translates to:
  /// **'Provided by the guide for tours'**
  String get vehicleProvidedByGuideMessage;

  /// No description provided for @packagesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packagesSectionTitle;

  /// No description provided for @tapPackageToBookMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap a package to book it directly'**
  String get tapPackageToBookMessage;

  /// No description provided for @standardPackageLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard package'**
  String get standardPackageLabel;

  /// No description provided for @durationHoursShortLabel.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String durationHoursShortLabel(String hours);

  /// No description provided for @guestsCountShortLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} guests'**
  String guestsCountShortLabel(String count);

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @requestThisGuideButton.
  ///
  /// In en, this message translates to:
  /// **'Request this guide'**
  String get requestThisGuideButton;

  /// No description provided for @experienceStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceStatLabel;

  /// No description provided for @yearsExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String yearsExperienceLabel(String years);

  /// No description provided for @ratingStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingStatLabel;

  /// No description provided for @rankStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rankStatLabel;

  /// No description provided for @licensedGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'Licensed guide • {licenseNumber}'**
  String licensedGuideLabel(String licenseNumber);

  /// No description provided for @platformVerifiedInsuredLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform verified & insured'**
  String get platformVerifiedInsuredLabel;

  /// No description provided for @yourListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your listing'**
  String get yourListingTitle;

  /// No description provided for @basicInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get basicInformationTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kasun Perera'**
  String get displayNameHint;

  /// No description provided for @aboutMeBioLabel.
  ///
  /// In en, this message translates to:
  /// **'About Me (Bio)'**
  String get aboutMeBioLabel;

  /// No description provided for @aboutMeBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell tourists about your passion, experience, and favorite spots...'**
  String get aboutMeBioHint;

  /// No description provided for @categorySpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Category & specialties'**
  String get categorySpecialtiesTitle;

  /// No description provided for @primaryCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Category'**
  String get primaryCategoryLabel;

  /// No description provided for @languagesCommaLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages (comma separated)'**
  String get languagesCommaLabel;

  /// No description provided for @languagesCommaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. English, Sinhala, German'**
  String get languagesCommaHint;

  /// No description provided for @specializationsCommaLabel.
  ///
  /// In en, this message translates to:
  /// **'Specializations (comma separated)'**
  String get specializationsCommaLabel;

  /// No description provided for @specializationsCommaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Heritage, Wildlife, Photography'**
  String get specializationsCommaHint;

  /// No description provided for @serviceRegionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Regions (comma separated)'**
  String get serviceRegionsLabel;

  /// No description provided for @serviceRegionsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Central, Southern, Western'**
  String get serviceRegionsHint;

  /// No description provided for @pricingVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing & vehicle'**
  String get pricingVehicleTitle;

  /// No description provided for @hourlyRateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRateFieldLabel;

  /// No description provided for @hourlyRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 25'**
  String get hourlyRateHint;

  /// No description provided for @vehicleAvailableForToursLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle available for tours'**
  String get vehicleAvailableForToursLabel;

  /// No description provided for @provideTransportationLabel.
  ///
  /// In en, this message translates to:
  /// **'Do you provide transportation?'**
  String get provideTransportationLabel;

  /// No description provided for @vehicleTypeModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type & Model'**
  String get vehicleTypeModelLabel;

  /// No description provided for @vehicleTypeModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toyota Prius Hybrid / Luxury Van'**
  String get vehicleTypeModelHint;

  /// No description provided for @coverPhotosCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover photos ({count})'**
  String coverPhotosCountTitle(int count);

  /// No description provided for @availabilityCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability calendar'**
  String get availabilityCalendarTitle;

  /// No description provided for @visibilityBoostTitle.
  ///
  /// In en, this message translates to:
  /// **'Visibility boost'**
  String get visibilityBoostTitle;

  /// No description provided for @saveDraftButton.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraftButton;

  /// No description provided for @publishListingButton.
  ///
  /// In en, this message translates to:
  /// **'Publish listing'**
  String get publishListingButton;

  /// No description provided for @uploadingPhotoMessage.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhotoMessage;

  /// No description provided for @photoUploadedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully!'**
  String get photoUploadedSuccessMessage;

  /// No description provided for @failedToUploadPhotoMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo.'**
  String get failedToUploadPhotoMessage;

  /// No description provided for @uploadingVehiclePhotoMessage.
  ///
  /// In en, this message translates to:
  /// **'Uploading vehicle photo...'**
  String get uploadingVehiclePhotoMessage;

  /// No description provided for @vehiclePhotoUploadedMessage.
  ///
  /// In en, this message translates to:
  /// **'Vehicle photo uploaded!'**
  String get vehiclePhotoUploadedMessage;

  /// No description provided for @listingPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'🎉 Listing Published to Marketplace!'**
  String get listingPublishedMessage;

  /// No description provided for @draftSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'💾 Draft Saved Successfully'**
  String get draftSavedMessage;

  /// No description provided for @failedToSaveListingMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save listing: {error}'**
  String failedToSaveListingMessage(String error);

  /// No description provided for @addPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhotoLabel;

  /// No description provided for @verifiedLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified license'**
  String get verifiedLicenseLabel;

  /// No description provided for @addVehiclePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle photo'**
  String get addVehiclePhotoLabel;

  /// No description provided for @manageAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Availability'**
  String get manageAvailabilityTitle;

  /// No description provided for @manageAvailabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set blackout dates & recurring working hours'**
  String get manageAvailabilitySubtitle;

  /// No description provided for @featureThisListingLabel.
  ///
  /// In en, this message translates to:
  /// **'Feature this listing'**
  String get featureThisListingLabel;

  /// No description provided for @currentlyFeaturedMessage.
  ///
  /// In en, this message translates to:
  /// **'Currently featured in the marketplace'**
  String get currentlyFeaturedMessage;

  /// No description provided for @featureRequestedMessage.
  ///
  /// In en, this message translates to:
  /// **'Requested — an admin will review and enable this shortly'**
  String get featureRequestedMessage;

  /// No description provided for @featureRequestPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Request to be featured in the marketplace (subject to admin review)'**
  String get featureRequestPromptMessage;

  /// No description provided for @upgradeToProFeatureMessage.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to boost your visibility in the marketplace'**
  String get upgradeToProFeatureMessage;

  /// No description provided for @safetyConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety console'**
  String get safetyConsoleTitle;

  /// No description provided for @offlineErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline Error: {error}'**
  String offlineErrorMessage(String error);

  /// No description provided for @secureOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure operations'**
  String get secureOperationsTitle;

  /// No description provided for @allIncidentsLoggedMessage.
  ///
  /// In en, this message translates to:
  /// **'All incidents logged with audit trail'**
  String get allIncidentsLoggedMessage;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get filterResolved;

  /// No description provided for @filterMyReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get filterMyReports;

  /// No description provided for @priorityBadgeText.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY'**
  String get priorityBadgeText;

  /// No description provided for @updatesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} updates'**
  String updatesCountLabel(int count);

  /// No description provided for @noCriticalIncidentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No critical incidents'**
  String get noCriticalIncidentsTitle;

  /// No description provided for @sessionWithinSafetyParamsMessage.
  ///
  /// In en, this message translates to:
  /// **'Session operations are within safety parameters.'**
  String get sessionWithinSafetyParamsMessage;

  /// No description provided for @reportIncidentButton.
  ///
  /// In en, this message translates to:
  /// **'Report incident'**
  String get reportIncidentButton;

  /// No description provided for @fileAnIncidentTitle.
  ///
  /// In en, this message translates to:
  /// **'File an incident'**
  String get fileAnIncidentTitle;

  /// No description provided for @incidentAuditTrailMessage.
  ///
  /// In en, this message translates to:
  /// **'Provide accurate details, this is logged with an audit trail.'**
  String get incidentAuditTrailMessage;

  /// No description provided for @incidentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Incident title'**
  String get incidentTitleHint;

  /// No description provided for @descriptionOfEventHint.
  ///
  /// In en, this message translates to:
  /// **'Description of event'**
  String get descriptionOfEventHint;

  /// No description provided for @transmitReportButton.
  ///
  /// In en, this message translates to:
  /// **'Transmit report'**
  String get transmitReportButton;

  /// No description provided for @incidentReportFieldsRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both the title and description.'**
  String get incidentReportFieldsRequiredMessage;

  /// No description provided for @incidentReportSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Incident report submitted.'**
  String get incidentReportSubmittedMessage;

  /// No description provided for @incidentStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get incidentStatusOpen;

  /// No description provided for @incidentStatusInvestigating.
  ///
  /// In en, this message translates to:
  /// **'Investigating'**
  String get incidentStatusInvestigating;

  /// No description provided for @incidentStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get incidentStatusResolved;

  /// No description provided for @incidentStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get incidentStatusClosed;

  /// No description provided for @resolutionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolutionNoteLabel;

  /// No description provided for @resolvedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolved by {name}'**
  String resolvedByLabel(String name);

  /// No description provided for @manageTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage team'**
  String get manageTeamTitle;

  /// No description provided for @signInToManageTeamMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your team.'**
  String get signInToManageTeamMessage;

  /// No description provided for @guideAddedToTeamMessage.
  ///
  /// In en, this message translates to:
  /// **'Guide added to your team'**
  String get guideAddedToTeamMessage;

  /// No description provided for @failedToInviteGuideMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to invite guide: {error}'**
  String failedToInviteGuideMessage(String error);

  /// No description provided for @failedToRemoveGuideMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove guide: {error}'**
  String failedToRemoveGuideMessage(String error);

  /// No description provided for @failedToUploadLogoMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload logo: {error}'**
  String failedToUploadLogoMessage(String error);

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get tabTeam;

  /// No description provided for @tabBranding.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get tabBranding;

  /// No description provided for @eliteOperatorAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Elite operator account'**
  String get eliteOperatorAccountLabel;

  /// No description provided for @overviewStatTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get overviewStatTeamSize;

  /// No description provided for @overviewStatMissions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get overviewStatMissions;

  /// No description provided for @overviewStatAvgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg. rating'**
  String get overviewStatAvgRating;

  /// No description provided for @guideUserIdToInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Guide user ID to invite'**
  String get guideUserIdToInviteHint;

  /// No description provided for @teamMembersCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Team members ({count})'**
  String teamMembersCountTitle(int count);

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get roleMember;

  /// No description provided for @logoLabel.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logoLabel;

  /// No description provided for @brandColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand color'**
  String get brandColorLabel;

  /// No description provided for @brandColorAppliedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your brand color is applied across this team dashboard for your organization.'**
  String get brandColorAppliedMessage;

  /// No description provided for @incidentNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Not Found'**
  String get incidentNotFoundTitle;

  /// No description provided for @incidentNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Record was sanitized or moved.'**
  String get incidentNotFoundDescription;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @severityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityLabel;

  /// No description provided for @timelineLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineLabel;

  /// No description provided for @encryptedLogLabel.
  ///
  /// In en, this message translates to:
  /// **'Encrypted log'**
  String get encryptedLogLabel;

  /// No description provided for @noTimelineActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'No timeline active.'**
  String get noTimelineActiveMessage;

  /// No description provided for @minutesAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgoLabel(int minutes);

  /// No description provided for @verifiedAuditLogLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified audit log'**
  String get verifiedAuditLogLabel;

  /// No description provided for @forensicIntegrityLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This report is locked for forensic integrity. Only authorized admins can modify status.'**
  String get forensicIntegrityLockedMessage;

  /// No description provided for @addEvidenceButton.
  ///
  /// In en, this message translates to:
  /// **'Add evidence'**
  String get addEvidenceButton;

  /// No description provided for @escalateButton.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get escalateButton;

  /// No description provided for @timelineTypeSosTriggered.
  ///
  /// In en, this message translates to:
  /// **'Sos triggered'**
  String get timelineTypeSosTriggered;

  /// No description provided for @invalidQrCodeFormatMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code format'**
  String get invalidQrCodeFormatMessage;

  /// No description provided for @unrecognizedQrCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized QR code'**
  String get unrecognizedQrCodeMessage;

  /// No description provided for @sessionNotFoundClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'Session not found or closed'**
  String get sessionNotFoundClosedMessage;

  /// No description provided for @connectionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionErrorMessage;

  /// No description provided for @tourVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour verification'**
  String get tourVerificationTitle;

  /// No description provided for @localGuideFallback.
  ///
  /// In en, this message translates to:
  /// **'Local guide'**
  String get localGuideFallback;

  /// No description provided for @vehicleNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {vehicleNumber}'**
  String vehicleNumberLabel(String vehicleNumber);

  /// No description provided for @consentTrackingMessage.
  ///
  /// In en, this message translates to:
  /// **'I consent to live location tracking and safety monitoring for this tour session.'**
  String get consentTrackingMessage;

  /// No description provided for @connectSyncButton.
  ///
  /// In en, this message translates to:
  /// **'Connect & sync'**
  String get connectSyncButton;

  /// No description provided for @realitySyncedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reality synced'**
  String get realitySyncedTitle;

  /// No description provided for @safetyProtocolsActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Global safety protocols and live tracking active.'**
  String get safetyProtocolsActiveMessage;

  /// No description provided for @enterHubButton.
  ///
  /// In en, this message translates to:
  /// **'Enter hub'**
  String get enterHubButton;

  /// No description provided for @decryptingTokenMessage.
  ///
  /// In en, this message translates to:
  /// **'Decrypting token…'**
  String get decryptingTokenMessage;

  /// No description provided for @scanGuideTourCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan your guide\'s tour code'**
  String get scanGuideTourCodeMessage;

  /// No description provided for @emergencyTranslatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Translator'**
  String get emergencyTranslatorTitle;

  /// No description provided for @showScreenToBystanderMessage.
  ///
  /// In en, this message translates to:
  /// **'Show this screen to a bystander, police officer, or hospital staff — it\'s speaking Sinhala for you.'**
  String get showScreenToBystanderMessage;

  /// No description provided for @locationCoordinatesTapMapsLabel.
  ///
  /// In en, this message translates to:
  /// **'{lat}, {lng} — tap to open in Maps'**
  String locationCoordinatesTapMapsLabel(String lat, String lng);

  /// No description provided for @locationUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailableMessage;

  /// No description provided for @speakingEllipsisMessage.
  ///
  /// In en, this message translates to:
  /// **'Speaking…'**
  String get speakingEllipsisMessage;

  /// No description provided for @playAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgainButton;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyTitle;

  /// No description provided for @criticalContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Critical contacts'**
  String get criticalContactsTitle;

  /// No description provided for @medicalFacilitiesNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical facilities nearby'**
  String get medicalFacilitiesNearbyTitle;

  /// No description provided for @emergencyProtocolLabel.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY PROTOCOL'**
  String get emergencyProtocolLabel;

  /// No description provided for @sendingAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Sending alert…'**
  String get sendingAlertMessage;

  /// No description provided for @keepHoldingToConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep holding to confirm…'**
  String get keepHoldingToConfirmMessage;

  /// No description provided for @pressHoldTwoSecondsMessage.
  ///
  /// In en, this message translates to:
  /// **'Press and hold for 2 seconds to alert'**
  String get pressHoldTwoSecondsMessage;

  /// No description provided for @preventsAccidentalTriggersMessage.
  ///
  /// In en, this message translates to:
  /// **'Prevents accidental triggers'**
  String get preventsAccidentalTriggersMessage;

  /// No description provided for @sosLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// No description provided for @contactNamePolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get contactNamePolice;

  /// No description provided for @contactNameAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get contactNameAmbulance;

  /// No description provided for @contactNameTouristPolice.
  ///
  /// In en, this message translates to:
  /// **'Tourist Police'**
  String get contactNameTouristPolice;

  /// No description provided for @contactNameFireDept.
  ///
  /// In en, this message translates to:
  /// **'Fire Dept'**
  String get contactNameFireDept;

  /// No description provided for @privateGuardiansTitle.
  ///
  /// In en, this message translates to:
  /// **'Private guardians'**
  String get privateGuardiansTitle;

  /// No description provided for @noGuardiansAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'No guardians assigned. Signals will default to emergency services.'**
  String get noGuardiansAssignedMessage;

  /// No description provided for @nearestHospitalTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearest hospital, wherever you are'**
  String get nearestHospitalTitle;

  /// No description provided for @checkingLocationAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking location access…'**
  String get checkingLocationAccessMessage;

  /// No description provided for @locationAccessDeniedGeneralMessage.
  ///
  /// In en, this message translates to:
  /// **'Location access denied — will search generally instead.'**
  String get locationAccessDeniedGeneralMessage;

  /// No description provided for @hospitalMapsExplanationMessage.
  ///
  /// In en, this message translates to:
  /// **'Opens Google Maps using your live GPS — shows every government and private hospital nearby, no matter where you are in Sri Lanka.'**
  String get hospitalMapsExplanationMessage;

  /// No description provided for @findNearestHospitalButton.
  ///
  /// In en, this message translates to:
  /// **'Find nearest hospital on Maps'**
  String get findNearestHospitalButton;

  /// No description provided for @addGuardianTitle.
  ///
  /// In en, this message translates to:
  /// **'Add guardian'**
  String get addGuardianTitle;

  /// No description provided for @guardianPhoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Guardian phone number'**
  String get guardianPhoneNumberHint;

  /// No description provided for @addGuardianButton.
  ///
  /// In en, this message translates to:
  /// **'Add guardian'**
  String get addGuardianButton;

  /// No description provided for @sosAlertsPreparedLoggedMessage.
  ///
  /// In en, this message translates to:
  /// **'SOS Alerts Prepared & Logged in Secure Vault!'**
  String get sosAlertsPreparedLoggedMessage;

  /// No description provided for @sosCriticalAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL SOS ALERT'**
  String get sosCriticalAlertTitle;

  /// No description provided for @sosDistressSignalDescription.
  ///
  /// In en, this message translates to:
  /// **'Emergency distress signal triggered from Guardian System.'**
  String get sosDistressSignalDescription;

  /// No description provided for @locationPermissionsPermanentlyDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied.'**
  String get locationPermissionsPermanentlyDeniedMessage;

  /// No description provided for @emergencyTranslatorPremiumMessage.
  ///
  /// In en, this message translates to:
  /// **'Instantly explain your situation to Sri Lankan police or hospital staff in spoken Sinhala — a Premium safety feature.'**
  String get emergencyTranslatorPremiumMessage;

  /// No description provided for @notNowButton.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNowButton;

  /// No description provided for @viewPlansButton.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlansButton;

  /// No description provided for @monsoonHazardAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'MONSOON HAZARD ALERT'**
  String get monsoonHazardAlertTitle;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District: {district}'**
  String districtLabel(String district);

  /// No description provided for @districtGeneralFallback.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get districtGeneralFallback;

  /// No description provided for @severeMonsoonWeatherDetectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Severe monsoon weather detected.'**
  String get severeMonsoonWeatherDetectedMessage;

  /// No description provided for @acknowledgeButton.
  ///
  /// In en, this message translates to:
  /// **'ACKNOWLEDGE'**
  String get acknowledgeButton;

  /// No description provided for @offlineErrorGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline Error: {error}'**
  String offlineErrorGenericMessage(String error);

  /// No description provided for @sessionNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get sessionNotFoundMessage;

  /// No description provided for @yourTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Your tour'**
  String get yourTourTitle;

  /// No description provided for @tourActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour active'**
  String get tourActiveTitle;

  /// No description provided for @preparingTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing tour'**
  String get preparingTourTitle;

  /// No description provided for @everythingOnTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'Everything\'s on track'**
  String get everythingOnTrackMessage;

  /// No description provided for @statusColonValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusColonValueLabel(String status);

  /// No description provided for @phaseAssemblingGroup.
  ///
  /// In en, this message translates to:
  /// **'Assembling group'**
  String get phaseAssemblingGroup;

  /// No description provided for @phaseEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get phaseEnRoute;

  /// No description provided for @phaseAtDestination.
  ///
  /// In en, this message translates to:
  /// **'At destination'**
  String get phaseAtDestination;

  /// No description provided for @phaseFreeTimeBreak.
  ///
  /// In en, this message translates to:
  /// **'Free time / break'**
  String get phaseFreeTimeBreak;

  /// No description provided for @phaseReturningToBase.
  ///
  /// In en, this message translates to:
  /// **'Returning to base'**
  String get phaseReturningToBase;

  /// No description provided for @liveNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Live navigation'**
  String get liveNavigationTitle;

  /// No description provided for @findGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'Find guide'**
  String get findGuideLabel;

  /// No description provided for @liveTrackingLabel.
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get liveTrackingLabel;

  /// No description provided for @findVehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Find vehicle'**
  String get findVehicleLabel;

  /// No description provided for @parkedSpotLabel.
  ///
  /// In en, this message translates to:
  /// **'Parked spot'**
  String get parkedSpotLabel;

  /// No description provided for @meetingPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get meetingPointLabel;

  /// No description provided for @returnHereIfLostMessage.
  ///
  /// In en, this message translates to:
  /// **'Return here if lost or separated from group.'**
  String get returnHereIfLostMessage;

  /// No description provided for @navigateToPointButton.
  ///
  /// In en, this message translates to:
  /// **'Navigate to point'**
  String get navigateToPointButton;

  /// No description provided for @guideAnnouncementLabel.
  ///
  /// In en, this message translates to:
  /// **'Guide announcement'**
  String get guideAnnouncementLabel;

  /// No description provided for @justNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNowLabel;

  /// No description provided for @acknowledgedLabel.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledgedLabel;

  /// No description provided for @iAcknowledgeButton.
  ///
  /// In en, this message translates to:
  /// **'I acknowledge'**
  String get iAcknowledgeButton;

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreLabel;

  /// No description provided for @shareLiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Share live'**
  String get shareLiveLabel;

  /// No description provided for @familyAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Family access'**
  String get familyAccessLabel;

  /// No description provided for @rateTourLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate tour'**
  String get rateTourLabel;

  /// No description provided for @buildReputationLabel.
  ///
  /// In en, this message translates to:
  /// **'Build reputation'**
  String get buildReputationLabel;

  /// No description provided for @helpImLostButton.
  ///
  /// In en, this message translates to:
  /// **'Help, I\'m lost'**
  String get helpImLostButton;

  /// No description provided for @emergencySosButton.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySosButton;

  /// No description provided for @instantAlertAdminPoliceMessage.
  ///
  /// In en, this message translates to:
  /// **'Instant alert to admin, police, and hub.'**
  String get instantAlertAdminPoliceMessage;

  /// No description provided for @signalSentStayMessage.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL SENT! STAY WHERE YOU ARE.'**
  String get signalSentStayMessage;

  /// No description provided for @travelerLostBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'TRAVELER LOST'**
  String get travelerLostBroadcastTitle;

  /// No description provided for @travelerLostBroadcastBody.
  ///
  /// In en, this message translates to:
  /// **'A traveler has signaled they are lost! Location shared on map.'**
  String get travelerLostBroadcastBody;

  /// No description provided for @sosCooledDownMessage.
  ///
  /// In en, this message translates to:
  /// **'SOS cooled down. Wait {seconds} seconds.'**
  String sosCooledDownMessage(int seconds);

  /// No description provided for @sosBroadcastedAuthoritiesMessage.
  ///
  /// In en, this message translates to:
  /// **'SOS ALERT BROADCASTED TO ALL AUTHORITIES!'**
  String get sosBroadcastedAuthoritiesMessage;

  /// No description provided for @tourCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour Completed!'**
  String get tourCompletedTitle;

  /// No description provided for @tourCompletedRateMessage.
  ///
  /// In en, this message translates to:
  /// **'We hope you had an amazing experience! Would you like to rate your guide now? Your feedback helps guides maintain high standards.'**
  String get tourCompletedRateMessage;

  /// No description provided for @remindLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Remind later'**
  String get remindLaterButton;

  /// No description provided for @reminderSetMessage.
  ///
  /// In en, this message translates to:
  /// **'⏰ Reminder set! We\'ll send a notification tomorrow.'**
  String get reminderSetMessage;

  /// No description provided for @rateNowButton.
  ///
  /// In en, this message translates to:
  /// **'Rate now ⭐'**
  String get rateNowButton;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @topPicksForYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Top picks for you'**
  String get topPicksForYouTitle;

  /// No description provided for @categoryAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAllFilter;

  /// No description provided for @categoryBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get categoryBeach;

  /// No description provided for @categoryCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get categoryCultural;

  /// No description provided for @categoryReligious.
  ///
  /// In en, this message translates to:
  /// **'Religious'**
  String get categoryReligious;

  /// No description provided for @categorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get categorySports;

  /// No description provided for @categorySeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get categorySeasonal;

  /// No description provided for @categoryFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get categoryFestival;

  /// No description provided for @categoryParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get categoryParty;

  /// No description provided for @availableEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available events'**
  String get availableEventsTitle;

  /// No description provided for @temporalDataLabel.
  ///
  /// In en, this message translates to:
  /// **'TEMPORAL DATA'**
  String get temporalDataLabel;

  /// No description provided for @acquirePassButton.
  ///
  /// In en, this message translates to:
  /// **'ACQUIRE PASS'**
  String get acquirePassButton;

  /// No description provided for @unpinButton.
  ///
  /// In en, this message translates to:
  /// **'UNPIN'**
  String get unpinButton;

  /// No description provided for @pinToHudButton.
  ///
  /// In en, this message translates to:
  /// **'PIN TO HUD'**
  String get pinToHudButton;

  /// No description provided for @noEventsOnDayMessage.
  ///
  /// In en, this message translates to:
  /// **'No events on this day'**
  String get noEventsOnDayMessage;

  /// No description provided for @musicPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Music preferences'**
  String get musicPreferencesTitle;

  /// No description provided for @fineTuneOracleMessage.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune the temporal oracle with your stylistic preferences.'**
  String get fineTuneOracleMessage;

  /// No description provided for @syncPreferencesButton.
  ///
  /// In en, this message translates to:
  /// **'Sync preferences'**
  String get syncPreferencesButton;

  /// No description provided for @failedToShareTimelineMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to share timeline: {error}'**
  String failedToShareTimelineMessage(String error);

  /// No description provided for @hazardWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'🚨 HAZARD WARNING: {message}'**
  String hazardWarningMessage(String message);

  /// No description provided for @extremeWeatherAlertFallback.
  ///
  /// In en, this message translates to:
  /// **'Extreme weather alert!'**
  String get extremeWeatherAlertFallback;

  /// No description provided for @recommendedForYouLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYouLabel;

  /// No description provided for @eventLocationCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'{location} · {category}'**
  String eventLocationCategoryLabel(String location, String category);

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpenseTitle;

  /// No description provided for @resourceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Resource Description'**
  String get resourceDescriptionLabel;

  /// No description provided for @amountLkrLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (LKR)'**
  String get amountLkrLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @saveExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get saveExpenseButton;

  /// No description provided for @planLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan limit'**
  String get planLimitLabel;

  /// No description provided for @spentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spentLabel;

  /// No description provided for @expenseLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense ledger'**
  String get expenseLedgerTitle;

  /// No description provided for @entriesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String entriesCountLabel(int count);

  /// No description provided for @noEntriesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesYetMessage;

  /// No description provided for @addFirstEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Add first entry'**
  String get addFirstEntryButton;

  /// No description provided for @expenseCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get expenseCategoryFood;

  /// No description provided for @expenseCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseCategoryTransport;

  /// No description provided for @expenseCategoryTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get expenseCategoryTickets;

  /// No description provided for @expenseCategoryMisc.
  ///
  /// In en, this message translates to:
  /// **'Misc'**
  String get expenseCategoryMisc;

  /// No description provided for @budgetConciergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget concierge'**
  String get budgetConciergeTitle;

  /// No description provided for @analyzingSpendingPatternsMessage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your spending patterns...'**
  String get analyzingSpendingPatternsMessage;

  /// No description provided for @localAdviceMessage.
  ///
  /// In en, this message translates to:
  /// **'Your spending pace aligns well with island travel standards. We recommend utilizing PickMe or Uber for transparent transport fares, and sampling local eateries to maximize your value.'**
  String get localAdviceMessage;

  /// No description provided for @recentTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactionsTitle;

  /// No description provided for @totalSpentSoFarLabel.
  ///
  /// In en, this message translates to:
  /// **'Total spent so far'**
  String get totalSpentSoFarLabel;

  /// No description provided for @approxUsdLabel.
  ///
  /// In en, this message translates to:
  /// **'≈ US\$ {amount}'**
  String approxUsdLabel(String amount);

  /// No description provided for @oracleAdviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Oracle advice'**
  String get oracleAdviceLabel;

  /// No description provided for @logTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Log transaction'**
  String get logTransactionTitle;

  /// No description provided for @whatWasThePurposeHint.
  ///
  /// In en, this message translates to:
  /// **'What was the purpose?'**
  String get whatWasThePurposeHint;

  /// No description provided for @amountLkrHint.
  ///
  /// In en, this message translates to:
  /// **'Amount (LKR)'**
  String get amountLkrHint;

  /// No description provided for @expenseCategoryAttraction.
  ///
  /// In en, this message translates to:
  /// **'Attraction'**
  String get expenseCategoryAttraction;

  /// No description provided for @expenseCategoryLodging.
  ///
  /// In en, this message translates to:
  /// **'Lodging'**
  String get expenseCategoryLodging;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenseCategoryOther;

  /// No description provided for @billingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'BILLING HISTORY'**
  String get billingHistoryTitle;

  /// No description provided for @errorGenericColonMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGenericColonMessage(String error);

  /// No description provided for @noBillingHistoryFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No billing history found.'**
  String get noBillingHistoryFoundMessage;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'PLAN: {planId}'**
  String planLabel(String planId);

  /// No description provided for @startedLabel.
  ///
  /// In en, this message translates to:
  /// **'STARTED'**
  String get startedLabel;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES'**
  String get expiresLabel;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {subscriptionId}'**
  String idLabel(String subscriptionId);

  /// No description provided for @subscriptionStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get subscriptionStatusCancelled;

  /// No description provided for @subscriptionStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get subscriptionStatusExpired;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get subscriptionStatusActive;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDeniedMessage;

  /// No description provided for @subscribedToPlanMessage.
  ///
  /// In en, this message translates to:
  /// **'✅ Subscribed to \"{planId}\" plan!'**
  String subscribedToPlanMessage(String planId);

  /// No description provided for @subscriptionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscription failed: {error}'**
  String subscriptionFailedMessage(String error);

  /// No description provided for @purchasesRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'✅ Purchases restored successfully.'**
  String get purchasesRestoredMessage;

  /// No description provided for @restoreFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailedMessage(String error);

  /// No description provided for @serviceTiersTitle.
  ///
  /// In en, this message translates to:
  /// **'Service tiers'**
  String get serviceTiersTitle;

  /// No description provided for @freeTierTitle.
  ///
  /// In en, this message translates to:
  /// **'Free tier'**
  String get freeTierTitle;

  /// No description provided for @freeTierDescription.
  ///
  /// In en, this message translates to:
  /// **'Essential tour tools for verified guides.'**
  String get freeTierDescription;

  /// No description provided for @featureBasicOperations.
  ///
  /// In en, this message translates to:
  /// **'Basic Operations'**
  String get featureBasicOperations;

  /// No description provided for @featureVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Badge'**
  String get featureVerifiedBadge;

  /// No description provided for @featureStandardSos.
  ///
  /// In en, this message translates to:
  /// **'Standard SOS'**
  String get featureStandardSos;

  /// No description provided for @proCommanderTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro Commander'**
  String get proCommanderTitle;

  /// No description provided for @proCommanderDescription.
  ///
  /// In en, this message translates to:
  /// **'Elevate your visibility and tools.'**
  String get proCommanderDescription;

  /// No description provided for @featureFeaturedListings.
  ///
  /// In en, this message translates to:
  /// **'Featured Listings'**
  String get featureFeaturedListings;

  /// No description provided for @featureAdvancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get featureAdvancedAnalytics;

  /// No description provided for @featureClientAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Client Analytics'**
  String get featureClientAnalytics;

  /// No description provided for @featurePrioritySos.
  ///
  /// In en, this message translates to:
  /// **'Priority SOS'**
  String get featurePrioritySos;

  /// No description provided for @eliteAgencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Elite Agency'**
  String get eliteAgencyTitle;

  /// No description provided for @eliteAgencyDescription.
  ///
  /// In en, this message translates to:
  /// **'Full fleet and company management.'**
  String get eliteAgencyDescription;

  /// No description provided for @featureTeamManagement.
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get featureTeamManagement;

  /// No description provided for @featureOperatorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Operator Dashboard'**
  String get featureOperatorDashboard;

  /// No description provided for @featureWhiteLabelBranding.
  ///
  /// In en, this message translates to:
  /// **'White-label Branding'**
  String get featureWhiteLabelBranding;

  /// No description provided for @fleetPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet plans'**
  String get fleetPlansTitle;

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlanLabel;

  /// No description provided for @freeTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Free tier'**
  String get freeTierLabel;

  /// No description provided for @expiresColonDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresColonDateLabel(String date);

  /// No description provided for @upgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButton;

  /// No description provided for @manageButton.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageButton;

  /// No description provided for @mostPopularLabel.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get mostPopularLabel;

  /// No description provided for @perMonthSlashLabel.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonthSlashLabel;

  /// No description provided for @currentPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlanButton;

  /// No description provided for @selectThisPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Select this plan'**
  String get selectThisPlanButton;

  /// No description provided for @goPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremiumTitle;

  /// No description provided for @fullArUnlimitedAiTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'Full AR & unlimited AI trips'**
  String get fullArUnlimitedAiTripsMessage;

  /// No description provided for @heritageArModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Heritage AR Mode'**
  String get heritageArModeTitle;

  /// No description provided for @heritageArModeDescription.
  ///
  /// In en, this message translates to:
  /// **'See ancient ruins reconstructed in 1:1 scale with historical audio guides.'**
  String get heritageArModeDescription;

  /// No description provided for @oracleAiTripIntelligenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Oracle AI Trip Intelligence'**
  String get oracleAiTripIntelligenceTitle;

  /// No description provided for @oracleAiTripIntelligenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Unlimited hyper-personalized itineraries powered by the Oracle engine.'**
  String get oracleAiTripIntelligenceDescription;

  /// No description provided for @offlineDigitalTwinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Digital Twins'**
  String get offlineDigitalTwinsTitle;

  /// No description provided for @offlineDigitalTwinsDescription.
  ///
  /// In en, this message translates to:
  /// **'Download high-res maps and 100+ points of interest for low-signal areas.'**
  String get offlineDigitalTwinsDescription;

  /// No description provided for @exclusiveCuratorDealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Curator Deals'**
  String get exclusiveCuratorDealsTitle;

  /// No description provided for @exclusiveCuratorDealsDescription.
  ///
  /// In en, this message translates to:
  /// **'Access to member-only discounts at handpicked boutique stays.'**
  String get exclusiveCuratorDealsDescription;

  /// No description provided for @guardianEmergencyTranslatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Guardian Emergency Translator'**
  String get guardianEmergencyTranslatorTitle;

  /// No description provided for @guardianEmergencyTranslatorDescription.
  ///
  /// In en, this message translates to:
  /// **'Instantly explain your situation to Sri Lankan police or hospital staff in spoken Sinhala during an SOS.'**
  String get guardianEmergencyTranslatorDescription;

  /// No description provided for @premiumActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'{plan} active'**
  String premiumActiveLabel(String plan);

  /// No description provided for @premiumFallback.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumFallback;

  /// No description provided for @renewingOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Renewing on {date}'**
  String renewingOnLabel(String date);

  /// No description provided for @viaSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Via {source}'**
  String viaSourceLabel(String source);

  /// No description provided for @storeFallback.
  ///
  /// In en, this message translates to:
  /// **'store'**
  String get storeFallback;

  /// No description provided for @resetPremiumDevButton.
  ///
  /// In en, this message translates to:
  /// **'RESET PREMIUM (DEV ONLY)'**
  String get resetPremiumDevButton;

  /// No description provided for @premiumResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Premium reset. Pricing tiers are back.'**
  String get premiumResetMessage;

  /// No description provided for @smartTravelerTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Traveler'**
  String get smartTravelerTitle;

  /// No description provided for @billedMonthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get billedMonthlyLabel;

  /// No description provided for @featureAiItineraries20.
  ///
  /// In en, this message translates to:
  /// **'20 AI Itineraries/mo'**
  String get featureAiItineraries20;

  /// No description provided for @featureSelectedArPlaces.
  ///
  /// In en, this message translates to:
  /// **'Selected AR Places'**
  String get featureSelectedArPlaces;

  /// No description provided for @featureOfflineMapsBasic.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps (Basic)'**
  String get featureOfflineMapsBasic;

  /// No description provided for @heritagePremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Heritage Premium'**
  String get heritagePremiumTitle;

  /// No description provided for @billedYearlySaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Billed yearly · save ~17%'**
  String get billedYearlySaveLabel;

  /// No description provided for @featureUnlimitedAiItineraries.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Itineraries'**
  String get featureUnlimitedAiItineraries;

  /// No description provided for @featureFullHeritageArAccess.
  ///
  /// In en, this message translates to:
  /// **'Full Heritage AR Access'**
  String get featureFullHeritageArAccess;

  /// No description provided for @featureAllOfflineFeatures.
  ///
  /// In en, this message translates to:
  /// **'All Offline Features'**
  String get featureAllOfflineFeatures;

  /// No description provided for @ultraExplorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ultra Explorer'**
  String get ultraExplorerTitle;

  /// No description provided for @waitlistLabel.
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get waitlistLabel;

  /// No description provided for @nextGenExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Next-Gen Experience'**
  String get nextGenExperienceLabel;

  /// No description provided for @featureVrModeSupport.
  ///
  /// In en, this message translates to:
  /// **'VR Mode Support'**
  String get featureVrModeSupport;

  /// No description provided for @featureHistoricalTimelines.
  ///
  /// In en, this message translates to:
  /// **'Historical Timelines'**
  String get featureHistoricalTimelines;

  /// No description provided for @featurePersonalAiCurator.
  ///
  /// In en, this message translates to:
  /// **'Personal AI Curator'**
  String get featurePersonalAiCurator;

  /// No description provided for @ultraExplorerWaitlistMessage.
  ///
  /// In en, this message translates to:
  /// **'🚀 Ultra Explorer is on the waitlist! We\'ll notify you when it launches.'**
  String get ultraExplorerWaitlistMessage;

  /// No description provided for @restorePreviousPurchasesButton.
  ///
  /// In en, this message translates to:
  /// **'Restore previous purchases'**
  String get restorePreviousPurchasesButton;

  /// No description provided for @termsPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service  •  Privacy Policy'**
  String get termsPrivacyLabel;

  /// No description provided for @testBuyDevButton.
  ///
  /// In en, this message translates to:
  /// **'TEST BUY (DEV ONLY)'**
  String get testBuyDevButton;

  /// No description provided for @mockPurchaseSimulatedMessage.
  ///
  /// In en, this message translates to:
  /// **'🚀 Mock Purchase Simulated. Refreshing...'**
  String get mockPurchaseSimulatedMessage;

  /// No description provided for @monthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyLabel;

  /// No description provided for @yearlySaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Yearly · Save 17%'**
  String get yearlySaveLabel;

  /// No description provided for @lockedLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedLabelShort;

  /// No description provided for @perMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonthLabel;

  /// No description provided for @comingSoonButton.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonButton;

  /// No description provided for @upgradeNowLongButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade now'**
  String get upgradeNowLongButton;

  /// No description provided for @trialDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}} free trial'**
  String trialDaysLabel(int count);

  /// No description provided for @trialWeeksLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 week} other{{count} weeks}} free trial'**
  String trialWeeksLabel(int count);

  /// No description provided for @trialMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 month} other{{count} months}} free trial'**
  String trialMonthsLabel(int count);

  /// No description provided for @trialYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 year} other{{count} years}} free trial'**
  String trialYearsLabel(int count);

  /// No description provided for @trialPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} period free trial'**
  String trialPeriodLabel(int count);

  /// No description provided for @oracleLostFocusMessage.
  ///
  /// In en, this message translates to:
  /// **'Oracle lost focus: {error}'**
  String oracleLostFocusMessage(String error);

  /// No description provided for @savorLankaAiTitle.
  ///
  /// In en, this message translates to:
  /// **'SAVORLANKA AI'**
  String get savorLankaAiTitle;

  /// No description provided for @culinaryVisionEngineLabel.
  ///
  /// In en, this message translates to:
  /// **'CULINARY VISION ENGINE V2'**
  String get culinaryVisionEngineLabel;

  /// No description provided for @liveRealTimeScannerLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE REAL-TIME SCANNER'**
  String get liveRealTimeScannerLabel;

  /// No description provided for @nutritionReliabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION RELIABILITY: {reliability}'**
  String nutritionReliabilityLabel(String reliability);

  /// No description provided for @neuralReasoningLabel.
  ///
  /// In en, this message translates to:
  /// **'NEURAL REASONING'**
  String get neuralReasoningLabel;

  /// No description provided for @aiVisualMarkersFallback.
  ///
  /// In en, this message translates to:
  /// **'AI identified visual culinary markers consistent with {label}.'**
  String aiVisualMarkersFallback(String label);

  /// No description provided for @authenticityIntelligenceTitle.
  ///
  /// In en, this message translates to:
  /// **'AUTHENTICITY INTELLIGENCE'**
  String get authenticityIntelligenceTitle;

  /// No description provided for @ingredientCertaintyTitle.
  ///
  /// In en, this message translates to:
  /// **'INGREDIENT CERTAINTY'**
  String get ingredientCertaintyTitle;

  /// No description provided for @manualCulinaryOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'MANUAL CULINARY OVERRIDE'**
  String get manualCulinaryOverrideTitle;

  /// No description provided for @refineIngredientsHint.
  ///
  /// In en, this message translates to:
  /// **'Refine ingredients (comma separated)...'**
  String get refineIngredientsHint;

  /// No description provided for @cancelButtonUppercaseAlt.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelButtonUppercaseAlt;

  /// No description provided for @applyOverrideButton.
  ///
  /// In en, this message translates to:
  /// **'APPLY OVERRIDE'**
  String get applyOverrideButton;

  /// No description provided for @ingredientTierConfirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get ingredientTierConfirmed;

  /// No description provided for @ingredientTierLikely.
  ///
  /// In en, this message translates to:
  /// **'LIKELY'**
  String get ingredientTierLikely;

  /// No description provided for @ingredientTierOptional.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL / SIDES'**
  String get ingredientTierOptional;

  /// No description provided for @mealContextLabel.
  ///
  /// In en, this message translates to:
  /// **'MEAL CONTEXT: {context}'**
  String mealContextLabel(String context);

  /// No description provided for @supportingElementsLabel.
  ///
  /// In en, this message translates to:
  /// **'SUPPORTING ELEMENTS:'**
  String get supportingElementsLabel;

  /// No description provided for @influencesLabel.
  ///
  /// In en, this message translates to:
  /// **'INFLUENCES: {influences}'**
  String influencesLabel(String influences);

  /// No description provided for @visualFreshnessQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'VISUAL FRESHNESS & QUALITY'**
  String get visualFreshnessQualityLabel;

  /// No description provided for @qualityColonLabel.
  ///
  /// In en, this message translates to:
  /// **'QUALITY: {quality}'**
  String qualityColonLabel(String quality);

  /// No description provided for @textureColonLabel.
  ///
  /// In en, this message translates to:
  /// **'TEXTURE: {texture}'**
  String textureColonLabel(String texture);

  /// No description provided for @heritageNarrativeEngineTitle.
  ///
  /// In en, this message translates to:
  /// **'HERITAGE NARRATIVE ENGINE'**
  String get heritageNarrativeEngineTitle;

  /// No description provided for @verifiedLegacyTitle.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED LEGACY'**
  String get verifiedLegacyTitle;

  /// No description provided for @regionalTraditionTitle.
  ///
  /// In en, this message translates to:
  /// **'REGIONAL TRADITION'**
  String get regionalTraditionTitle;

  /// No description provided for @folkloreNarrativeTitle.
  ///
  /// In en, this message translates to:
  /// **'FOLKLORE NARRATIVE'**
  String get folkloreNarrativeTitle;

  /// No description provided for @culinaryGapPairingEngineTitle.
  ///
  /// In en, this message translates to:
  /// **'CULINARY GAP & PAIRING ENGINE'**
  String get culinaryGapPairingEngineTitle;

  /// No description provided for @missingCompanionsLabel.
  ///
  /// In en, this message translates to:
  /// **'MISSING COMPANIONS:'**
  String get missingCompanionsLabel;

  /// No description provided for @engineNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'ENGINE NOTES:'**
  String get engineNotesLabel;

  /// No description provided for @recipeRefactorEngineTitle.
  ///
  /// In en, this message translates to:
  /// **'RECIPE REFACTOR ENGINE'**
  String get recipeRefactorEngineTitle;

  /// No description provided for @refactoredStepsForYouLabel.
  ///
  /// In en, this message translates to:
  /// **'REFACTORED STEPS FOR YOU:'**
  String get refactoredStepsForYouLabel;

  /// No description provided for @prepMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'PREP'**
  String get prepMetricLabel;

  /// No description provided for @cookMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'COOK'**
  String get cookMetricLabel;

  /// No description provided for @levelMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL'**
  String get levelMetricLabel;

  /// No description provided for @calMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'CAL'**
  String get calMetricLabel;

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbsLabel;

  /// No description provided for @fatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fatLabel;

  /// No description provided for @fiberLabel.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get fiberLabel;

  /// No description provided for @healthRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'HEALTH RATING'**
  String get healthRatingLabel;

  /// No description provided for @healthRatingValueLabel.
  ///
  /// In en, this message translates to:
  /// **'{rating}/10'**
  String healthRatingValueLabel(int rating);

  /// No description provided for @sinhalaLabel.
  ///
  /// In en, this message translates to:
  /// **'SINHALA'**
  String get sinhalaLabel;

  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'ENGLISH'**
  String get englishLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get backLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get nextLabel;

  /// No description provided for @rescanLabel.
  ///
  /// In en, this message translates to:
  /// **'RESCAN'**
  String get rescanLabel;

  /// No description provided for @oracleInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'ORACLE INSIGHTS'**
  String get oracleInsightsTitle;

  /// No description provided for @globalSubstitutionsTitle.
  ///
  /// In en, this message translates to:
  /// **'GLOBAL SUBSTITUTIONS'**
  String get globalSubstitutionsTitle;

  /// No description provided for @aiEstimatedValuesDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-estimated values. Traditional variations may differ.'**
  String get aiEstimatedValuesDisclaimer;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get savedLabel;

  /// No description provided for @saveToCookbookLabel.
  ///
  /// In en, this message translates to:
  /// **'SAVE TO COOKBOOK'**
  String get saveToCookbookLabel;

  /// No description provided for @voiceGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'VOICE GUIDE'**
  String get voiceGuideLabel;

  /// No description provided for @savorLankaShareText.
  ///
  /// In en, this message translates to:
  /// **'Check out this {name} recipe I found on Hidden Gems SL.ai! It\'s an authentic Sri Lankan delicacy. \n\nOracle Score: {score}%'**
  String savorLankaShareText(String name, String score);

  /// No description provided for @savorLankaShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems SL.ai - Savor Lanka Recipe'**
  String get savorLankaShareSubject;

  /// No description provided for @phase3CrossMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'PHASE 3: CROSS-MATCH SUBSTITUTION'**
  String get phase3CrossMatchTitle;

  /// No description provided for @visuallySimilarAlternativesLabel.
  ///
  /// In en, this message translates to:
  /// **'VISUALLY SIMILAR ALTERNATIVES'**
  String get visuallySimilarAlternativesLabel;

  /// No description provided for @aiCrossMatchReasoningLabel.
  ///
  /// In en, this message translates to:
  /// **'AI CROSS-MATCH REASONING:'**
  String get aiCrossMatchReasoningLabel;

  /// No description provided for @phase6HygienePresentationTitle.
  ///
  /// In en, this message translates to:
  /// **'PHASE 6: HYGIENE & PRESENTATION'**
  String get phase6HygienePresentationTitle;

  /// No description provided for @presentationLabel.
  ///
  /// In en, this message translates to:
  /// **'PRESENTATION'**
  String get presentationLabel;

  /// No description provided for @integrityLabel.
  ///
  /// In en, this message translates to:
  /// **'INTEGRITY'**
  String get integrityLabel;

  /// No description provided for @popularLabel.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularLabel;

  /// No description provided for @curatorDealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Curator deals'**
  String get curatorDealsTitle;

  /// No description provided for @noDealsRightNowTitle.
  ///
  /// In en, this message translates to:
  /// **'No deals right now'**
  String get noDealsRightNowTitle;

  /// No description provided for @newPartnerDiscountsMessage.
  ///
  /// In en, this message translates to:
  /// **'New partner discounts are added regularly — check back soon.'**
  String get newPartnerDiscountsMessage;

  /// No description provided for @percentOffLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% OFF'**
  String percentOffLabel(int percent);

  /// No description provided for @validUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntilLabel(String date);

  /// No description provided for @claimDealButton.
  ///
  /// In en, this message translates to:
  /// **'Claim deal'**
  String get claimDealButton;

  /// No description provided for @passportTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passportTitle;

  /// No description provided for @verifiedVisitCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your verified visit collection'**
  String get verifiedVisitCollectionSubtitle;

  /// No description provided for @passportIsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport is empty'**
  String get passportIsEmptyTitle;

  /// No description provided for @exploreHistoricalGemsMessage.
  ///
  /// In en, this message translates to:
  /// **'Explore historical gems to\nclaim your unique digital stamps.'**
  String get exploreHistoricalGemsMessage;

  /// No description provided for @claimedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Claimed on {date}'**
  String claimedOnLabel(String date);

  /// No description provided for @verifiableHashLabel.
  ///
  /// In en, this message translates to:
  /// **'Verifiable hash'**
  String get verifiableHashLabel;

  /// No description provided for @shareCollectibleButton.
  ///
  /// In en, this message translates to:
  /// **'Share collectible'**
  String get shareCollectibleButton;

  /// No description provided for @stampRarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get stampRarityCommon;

  /// No description provided for @stampRarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get stampRarityRare;

  /// No description provided for @stampRarityMythic.
  ///
  /// In en, this message translates to:
  /// **'Mythic'**
  String get stampRarityMythic;

  /// No description provided for @audioGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio guide'**
  String get audioGuideLabel;

  /// No description provided for @audioGuideUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This audio guide isn\'t available right now. Tap to retry.'**
  String get audioGuideUnavailable;

  /// No description provided for @sinhalaShortLabel.
  ///
  /// In en, this message translates to:
  /// **'සිංහල'**
  String get sinhalaShortLabel;

  /// No description provided for @englishShortLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishShortLabel;

  /// No description provided for @joinGroupTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Group Tour'**
  String get joinGroupTourTitle;

  /// No description provided for @enterSixDigitCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code provided by your guide.'**
  String get enterSixDigitCodeMessage;

  /// No description provided for @cancelButtonUppercaseThird.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelButtonUppercaseThird;

  /// No description provided for @joinButtonUppercase.
  ///
  /// In en, this message translates to:
  /// **'JOIN'**
  String get joinButtonUppercase;

  /// No description provided for @tapFlatSurfaceMessage.
  ///
  /// In en, this message translates to:
  /// **'👆 Tap a flat surface to place the model'**
  String get tapFlatSurfaceMessage;

  /// No description provided for @groupTourStartedCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Tour Started! Code: {code}'**
  String groupTourStartedCodeLabel(String code);

  /// No description provided for @invalidSessionCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid Session Code'**
  String get invalidSessionCodeMessage;

  /// No description provided for @couldNotLoadAudioMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load audio narration.'**
  String get couldNotLoadAudioMessage;

  /// No description provided for @galleryPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Gallery permission denied'**
  String get galleryPermissionDeniedMessage;

  /// No description provided for @failedToCapturePhotoMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo: {error}'**
  String failedToCapturePhotoMessage(String error);

  /// No description provided for @codeColonLabel.
  ///
  /// In en, this message translates to:
  /// **'CODE: {code}'**
  String codeColonLabel(String code);

  /// No description provided for @thenLabel.
  ///
  /// In en, this message translates to:
  /// **'THEN'**
  String get thenLabel;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get nowLabel;

  /// No description provided for @resetLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetLabel;

  /// No description provided for @scalePlusLabel.
  ///
  /// In en, this message translates to:
  /// **'Scale+'**
  String get scalePlusLabel;

  /// No description provided for @scaleMinusLabel.
  ///
  /// In en, this message translates to:
  /// **'Scale-'**
  String get scaleMinusLabel;

  /// No description provided for @memoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memoryLabel;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @placeLabel.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeLabel;

  /// No description provided for @historicalInfoComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Historical information coming soon.'**
  String get historicalInfoComingSoonMessage;

  /// No description provided for @preparingHeritageAssetsMessage.
  ///
  /// In en, this message translates to:
  /// **'Preparing Heritage Assets...'**
  String get preparingHeritageAssetsMessage;

  /// No description provided for @progressSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'{progress}% • {size} MB'**
  String progressSizeLabel(int progress, String size);

  /// No description provided for @arModelPlacementFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'This model couldn\'t be placed — it may be missing or corrupted. Try again or pick another location.'**
  String get arModelPlacementFailedMessage;

  /// No description provided for @arSessionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'AR error: {message}'**
  String arSessionErrorMessage(String message);

  /// No description provided for @largeDownloadWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Large download'**
  String get largeDownloadWarningTitle;

  /// No description provided for @largeDownloadWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This 3D model is about {size} MB. Downloading it now will use your mobile data. Continue?'**
  String largeDownloadWarningMessage(String size);

  /// No description provided for @downloadAnywayButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Download anyway'**
  String get downloadAnywayButtonLabel;

  /// No description provided for @modelColonNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Model: {name}'**
  String modelColonNameLabel(String name);

  /// No description provided for @authorColonNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Author: {name}'**
  String authorColonNameLabel(String name);

  /// No description provided for @moveSlowlyToScanMessage.
  ///
  /// In en, this message translates to:
  /// **'Move your phone slowly\nto scan a flat surface'**
  String get moveSlowlyToScanMessage;

  /// No description provided for @tapPlaceToPlaceModelMessage.
  ///
  /// In en, this message translates to:
  /// **'👇 Tap \"Place\" then tap a flat surface'**
  String get tapPlaceToPlaceModelMessage;

  /// No description provided for @demoModeSecondsRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'DEMO MODE: {seconds} REMAINING'**
  String demoModeSecondsRemainingLabel(int seconds);

  /// No description provided for @premiumHeritageSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM HERITAGE SESSION'**
  String get premiumHeritageSessionLabel;

  /// No description provided for @artifactDiscoveredLabel.
  ///
  /// In en, this message translates to:
  /// **'ARTIFACT DISCOVERED!'**
  String get artifactDiscoveredLabel;

  /// No description provided for @ptsRarityLabel.
  ///
  /// In en, this message translates to:
  /// **'+{points} PTS • {rarity}'**
  String ptsRarityLabel(int points, String rarity);

  /// No description provided for @hiddenGemsSlWatermark.
  ///
  /// In en, this message translates to:
  /// **'HIDDEN GEMS SL'**
  String get hiddenGemsSlWatermark;

  /// No description provided for @heritageArWatermark.
  ///
  /// In en, this message translates to:
  /// **'HERITAGE AR'**
  String get heritageArWatermark;

  /// No description provided for @captureSuccessfulTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture Successful!'**
  String get captureSuccessfulTitle;

  /// No description provided for @shareDiscoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Share your historical discovery with the world'**
  String get shareDiscoveryMessage;

  /// No description provided for @instagramLabel.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagramLabel;

  /// No description provided for @tiktokLabel.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get tiktokLabel;

  /// No description provided for @savedLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabelShort;

  /// No description provided for @sharePlatformCaptionInstagram.
  ///
  /// In en, this message translates to:
  /// **'Exploring {placeName} in AR with #HiddenGemsSL'**
  String sharePlatformCaptionInstagram(String placeName);

  /// No description provided for @sharePlatformCaptionTiktok.
  ///
  /// In en, this message translates to:
  /// **'History comes alive! #HiddenGemsSL #HeritageAR'**
  String get sharePlatformCaptionTiktok;

  /// No description provided for @photoSavedGalleryMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo saved to your gallery!'**
  String get photoSavedGalleryMessage;

  /// No description provided for @backToArButton.
  ///
  /// In en, this message translates to:
  /// **'Back to AR'**
  String get backToArButton;

  /// No description provided for @distanceToTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'{distance}m to {placeName}'**
  String distanceToTargetLabel(String distance, String placeName);

  /// No description provided for @recommendedLabel.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get recommendedLabel;

  /// No description provided for @categoryRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'{category} • {rating} ★'**
  String categoryRatingLabel(String category, String rating);

  /// No description provided for @viewButtonUppercase.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get viewButtonUppercase;

  /// No description provided for @loginToLeaveMemoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Login to leave an AR memory!'**
  String get loginToLeaveMemoryMessage;

  /// No description provided for @leaveArMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave an AR Memory'**
  String get leaveArMemoryTitle;

  /// No description provided for @whatDoYouSeeHereHint.
  ///
  /// In en, this message translates to:
  /// **'What do you see here?'**
  String get whatDoYouSeeHereHint;

  /// No description provided for @cancelButton2.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton2;

  /// No description provided for @dropButton.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get dropButton;

  /// No description provided for @memoryDroppedMessage.
  ///
  /// In en, this message translates to:
  /// **'Memory dropped into the AR universe!'**
  String get memoryDroppedMessage;

  /// No description provided for @explorerFallback.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorerFallback;

  /// No description provided for @signalPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL: {percent}%'**
  String signalPercentLabel(int percent);

  /// No description provided for @searchingLabel.
  ///
  /// In en, this message translates to:
  /// **'SEARCHING...'**
  String get searchingLabel;

  /// No description provided for @cameraAccessNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access needed'**
  String get cameraAccessNeededTitle;

  /// No description provided for @arNotAvailableDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'AR isn\'t available on this device'**
  String get arNotAvailableDeviceTitle;

  /// No description provided for @arCouldntLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'AR couldn\'t load this time'**
  String get arCouldntLoadTitle;

  /// No description provided for @cameraAccessNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed for AR features. Here\'s a cinematic reconstruction instead.'**
  String get cameraAccessNeededMessage;

  /// No description provided for @arNotAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a cinematic 360° view of the same era instead.'**
  String get arNotAvailableMessage;

  /// No description provided for @arCouldntLoadMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the historical 3D model. Here\'s the cinematic fallback view instead.'**
  String get arCouldntLoadMessage;

  /// No description provided for @closeButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButtonLabel;

  /// No description provided for @watchAdToUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to unlock'**
  String get watchAdToUnlockButton;

  /// No description provided for @oracleRewardFallbackMessage.
  ///
  /// In en, this message translates to:
  /// **'✨ Oracle reward active! Fallback modes and premium content unlocked.'**
  String get oracleRewardFallbackMessage;

  /// No description provided for @arNotAvailableInfoBarMessage.
  ///
  /// In en, this message translates to:
  /// **'AR isn\'t available on this device · Showing 360° view'**
  String get arNotAvailableInfoBarMessage;

  /// No description provided for @cinematicPreviewUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Cinematic preview unavailable'**
  String get cinematicPreviewUnavailableMessage;

  /// No description provided for @interactive3dViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive 3D View'**
  String get interactive3dViewTitle;

  /// No description provided for @touchToRotateMonumentMessage.
  ///
  /// In en, this message translates to:
  /// **'Touch to rotate monument'**
  String get touchToRotateMonumentMessage;

  /// No description provided for @historicalStoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Historical story'**
  String get historicalStoryLabel;

  /// No description provided for @unveilingEraTitle.
  ///
  /// In en, this message translates to:
  /// **'Unveiling the {era}'**
  String unveilingEraTitle(String era);

  /// No description provided for @heritageStoryBody.
  ///
  /// In en, this message translates to:
  /// **'Sri Lanka\'s heritage runs deep into the fabric of time. This site, dating back to the {era}, was once the center of a thriving civilization that pioneered hydraulic engineering and spiritual architecture.\n\nThe stupa we see today was constructed using over 100 million sun-baked bricks, standing as a testament to the engineering marvels of ancient kings...'**
  String heritageStoryBody(String era);

  /// No description provided for @listenToNarrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Listen to narration'**
  String get listenToNarrationLabel;

  /// No description provided for @sinhalaEnglishAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Sinhala & English available'**
  String get sinhalaEnglishAvailableLabel;

  /// No description provided for @illustrationCaptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Illustration: Ancient Engineering (Concept Art)'**
  String get illustrationCaptionLabel;

  /// No description provided for @mode360Label.
  ///
  /// In en, this message translates to:
  /// **'360°'**
  String get mode360Label;

  /// No description provided for @mode3dLabel.
  ///
  /// In en, this message translates to:
  /// **'3D'**
  String get mode3dLabel;

  /// No description provided for @modeStoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get modeStoryLabel;

  /// No description provided for @unlockArHeritageModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock AR Heritage Mode'**
  String get unlockArHeritageModeTitle;

  /// No description provided for @arHeritageModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Experience Sri Lanka as it looked thousands of years ago.'**
  String get arHeritageModeSubtitle;

  /// No description provided for @featureAncient3dReconstruction.
  ///
  /// In en, this message translates to:
  /// **'Ancient 3D Reconstruction'**
  String get featureAncient3dReconstruction;

  /// No description provided for @featureAudioNarrationBilingual.
  ///
  /// In en, this message translates to:
  /// **'Audio Narration (සිංහල / English)'**
  String get featureAudioNarrationBilingual;

  /// No description provided for @featureArPhotoCapture.
  ///
  /// In en, this message translates to:
  /// **'AR Photo Capture & Social Share'**
  String get featureArPhotoCapture;

  /// No description provided for @pricingTrialLabel.
  ///
  /// In en, this message translates to:
  /// **'From Rs. 299/month  ·  7-day free trial'**
  String get pricingTrialLabel;

  /// No description provided for @upgradeToPremiumButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremiumButton;

  /// No description provided for @watch10SecPreviewButton.
  ///
  /// In en, this message translates to:
  /// **'Watch 10-sec Preview'**
  String get watch10SecPreviewButton;

  /// No description provided for @watchAdUnlockSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad to Unlock Session'**
  String get watchAdUnlockSessionButton;

  /// No description provided for @notNowButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNowButtonLabel;

  /// No description provided for @ancientArtifactsLabel.
  ///
  /// In en, this message translates to:
  /// **'ANCIENT ARTIFACTS'**
  String get ancientArtifactsLabel;

  /// No description provided for @adminGuideVerificationTile.
  ///
  /// In en, this message translates to:
  /// **'Guide Verifications'**
  String get adminGuideVerificationTile;

  /// No description provided for @adminVerificationConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Console'**
  String get adminVerificationConsoleTitle;

  /// No description provided for @pendingReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review submitted guide applications and documents.'**
  String get pendingReviewsSubtitle;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @filterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get filterApproved;

  /// No description provided for @filterRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get filterRejected;

  /// No description provided for @filterExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get filterExpiringSoon;

  /// No description provided for @filterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get filterExpired;

  /// No description provided for @noApplicationsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No {filter} applications.'**
  String noApplicationsFoundMessage(String filter);

  /// No description provided for @appliedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Applied {date}'**
  String appliedOnLabel(String date);

  /// No description provided for @licenseNumberDisplayLabel.
  ///
  /// In en, this message translates to:
  /// **'License No. {number}'**
  String licenseNumberDisplayLabel(String number);

  /// No description provided for @applicantDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applicant Details'**
  String get applicantDetailsTitle;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @licenseDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'License Document'**
  String get licenseDocumentLabel;

  /// No description provided for @nicDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'NIC Document'**
  String get nicDocumentLabel;

  /// No description provided for @selfiePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Selfie Photo'**
  String get selfiePhotoLabel;

  /// No description provided for @imageFailedToLoadMessage.
  ///
  /// In en, this message translates to:
  /// **'Image failed to load'**
  String get imageFailedToLoadMessage;

  /// No description provided for @noDocumentProvidedMessage.
  ///
  /// In en, this message translates to:
  /// **'No document provided'**
  String get noDocumentProvidedMessage;

  /// No description provided for @adminCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (required to reject)'**
  String get adminCommentHint;

  /// No description provided for @rejectionReasonRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please add a reason before rejecting.'**
  String get rejectionReasonRequiredMessage;

  /// No description provided for @approveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveButtonLabel;

  /// No description provided for @rejectButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectButtonLabel;

  /// No description provided for @applicationApprovedNoticeMessage.
  ///
  /// In en, this message translates to:
  /// **'Application approved.'**
  String get applicationApprovedNoticeMessage;

  /// No description provided for @applicationRejectedNoticeMessage.
  ///
  /// In en, this message translates to:
  /// **'Application rejected.'**
  String get applicationRejectedNoticeMessage;

  /// No description provided for @reviewActionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review: {error}'**
  String reviewActionFailedMessage(String error);

  /// No description provided for @licenseExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'License Expiry'**
  String get licenseExpiryLabel;

  /// No description provided for @notProvidedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvidedLabel;

  /// No description provided for @expiryStatusValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get expiryStatusValid;

  /// No description provided for @expiryStatusExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiryStatusExpiringSoon;

  /// No description provided for @expiryStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiryStatusExpired;

  /// No description provided for @selectExpiryDateButton.
  ///
  /// In en, this message translates to:
  /// **'Select License Expiry Date'**
  String get selectExpiryDateButton;

  /// No description provided for @languagesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages Spoken'**
  String get languagesSectionTitle;

  /// No description provided for @tourTypesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tours Offered'**
  String get tourTypesSectionTitle;

  /// No description provided for @tourTypeBoatSafari.
  ///
  /// In en, this message translates to:
  /// **'Boat Safari'**
  String get tourTypeBoatSafari;

  /// No description provided for @tourTypeWildlifeSafari.
  ///
  /// In en, this message translates to:
  /// **'Wildlife Safari'**
  String get tourTypeWildlifeSafari;

  /// No description provided for @tourTypeHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get tourTypeHiking;

  /// No description provided for @tourTypeDiving.
  ///
  /// In en, this message translates to:
  /// **'Diving'**
  String get tourTypeDiving;

  /// No description provided for @tourTypeCulturalTours.
  ///
  /// In en, this message translates to:
  /// **'Cultural Tours'**
  String get tourTypeCulturalTours;

  /// No description provided for @reportReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Review'**
  String get reportReviewTitle;

  /// No description provided for @reportReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this review?'**
  String get reportReviewSubtitle;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Thanks — this review has been reported for moderation.'**
  String get reportSubmittedMessage;

  /// No description provided for @reportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to report this review. Please try again.'**
  String get reportFailedMessage;

  /// No description provided for @filterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Guides'**
  String get filterSheetTitle;

  /// No description provided for @filterHasVehicle.
  ///
  /// In en, this message translates to:
  /// **'Has Vehicle'**
  String get filterHasVehicle;

  /// No description provided for @filterApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filterApplyButton;

  /// No description provided for @filterClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClearButton;

  /// No description provided for @filterRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get filterRegionLabel;

  /// No description provided for @filterLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get filterLanguageLabel;
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
