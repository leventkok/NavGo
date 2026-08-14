///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$shell$en shell = _Translations$shell$en._(_root);
	@override late final _Translations$onboarding$en onboarding = _Translations$onboarding$en._(_root);
	@override late final _Translations$plan$en plan = _Translations$plan$en._(_root);
	@override late final _Translations$location$en location = _Translations$location$en._(_root);
	@override late final _Translations$profile$en profile = _Translations$profile$en._(_root);
	@override late final _Translations$explore$en explore = _Translations$explore$en._(_root);
	@override late final _Translations$trips$en trips = _Translations$trips$en._(_root);
	@override late final _Translations$splash$en splash = _Translations$splash$en._(_root);
}

// Path: common
class _Translations$common$en extends Translations$common$tr {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get brand => 'NavGo';
	@override String get cancel => 'Cancel';
	@override String get continueAction => 'Continue';
	@override String get ok => 'OK';
	@override String get retry => 'Try again';
	@override String get back => 'Back';
	@override String get emDash => '—';
	@override String get defaultTravelerName => 'Traveler';
	@override late final _Translations$common$tempo$en tempo = _Translations$common$tempo$en._(_root);
	@override late final _Translations$common$group$en group = _Translations$common$group$en._(_root);
	@override late final _Translations$common$transport$en transport = _Translations$common$transport$en._(_root);
	@override late final _Translations$common$interest$en interest = _Translations$common$interest$en._(_root);
}

// Path: shell
class _Translations$shell$en extends Translations$shell$tr {
	_Translations$shell$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tabPlan => 'Plan';
	@override String get tabTrips => 'Trips';
	@override String get tabExplore => 'Explore';
	@override String get tabProfile => 'Profile';
}

// Path: onboarding
class _Translations$onboarding$en extends Translations$onboarding$tr {
	_Translations$onboarding$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String stepProgress({required Object current, required Object total}) => '${current}/${total}';
	@override String get continueAction => 'Continue';
	@override String get enterApp => 'Enter NavGo';
	@override String get resolvingLocation => 'Getting location…';
	@override String get cityRequiredSnack => 'City or district is required';
	@override late final _Translations$onboarding$welcome$en welcome = _Translations$onboarding$welcome$en._(_root);
	@override late final _Translations$onboarding$name$en name = _Translations$onboarding$name$en._(_root);
	@override late final _Translations$onboarding$tempo$en tempo = _Translations$onboarding$tempo$en._(_root);
	@override late final _Translations$onboarding$interests$en interests = _Translations$onboarding$interests$en._(_root);
	@override late final _Translations$onboarding$group$en group = _Translations$onboarding$group$en._(_root);
	@override late final _Translations$onboarding$transport$en transport = _Translations$onboarding$transport$en._(_root);
}

// Path: plan
class _Translations$plan$en extends Translations$plan$tr {
	_Translations$plan$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get selectLocation => 'Select location';
	@override String get quickStart => 'Quick start';
	@override String get quickStartNeedLocation => 'Pick a location, then choose a route type.';
	@override String quickStartWithArea({required Object area}) => 'Pick a route type for ${area} — real places based on your interests.';
	@override String get defaultPlanTitle => 'Day plan';
	@override String routeSummary({required Object km, required Object mins, required Object provider}) => '${km} km · ~${mins} min · ${provider}';
	@override String get greetingMorning => 'Good morning';
	@override String get greetingAfternoon => 'Good afternoon';
	@override String get greetingEvening => 'Good evening';
	@override String greetingLine({required Object greeting}) => '${greeting},';
	@override String get heroBadge => 'Today';
	@override String get heroTitle => 'One day. Real places.';
	@override String get heroBody => 'Pick a ready route or build your own — stops come from real venues.';
	@override String get heroCta => 'Plan a new day';
	@override String get errorTitle => 'Couldn’t create the plan';
	@override String get tipBanner => 'Prefer cooler hours for walking — shade and short breaks help in the afternoon.';
	@override String get openInGoogleMaps => 'Open in Google Maps';
	@override String get backToHome => 'Back to home';
	@override String get statusSigningIn => 'Signing in…';
	@override String get statusParsingIntent => 'Parsing intent with LLM…';
	@override String get statusSearchingPlaces => 'Searching places…';
	@override String get statusSearchingPlacesTemplate => 'Searching places with template…';
	@override String get statusPickingStops => 'Picking stops with LLM…';
	@override String get statusBuildingRoute => 'Building route…';
	@override String get statusReady => 'Plan ready';
	@override String get errorDestinationRequired => 'Destination is required';
	@override String get errorTimeout => 'The request timed out. Check your connection and try again.';
	@override String get errorConnection => 'Couldn’t reach the server. Make sure the API is running.';
	@override String get errorAuth => 'Couldn’t sign in. Please try again.';
	@override String get errorUnprocessable => 'Those places don’t work for a route. Try another route type.';
	@override String get errorServer => 'A server error occurred. Try again shortly.';
	@override String get errorNotEnoughPlaces => 'Not enough places found in this area. Try another destination or route type.';
	@override String get errorGeneric => 'Couldn’t create the plan. Please try again.';
	@override late final _Translations$plan$startSheet$en startSheet = _Translations$plan$startSheet$en._(_root);
	@override late final _Translations$plan$suggestion$en suggestion = _Translations$plan$suggestion$en._(_root);
}

// Path: location
class _Translations$location$en extends Translations$location$tr {
	_Translations$location$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get requiredTitle => 'Location required';
	@override String get failedTitle => 'Couldn’t get location';
	@override String get manualTitle => 'City or district';
	@override String get manualHint => 'e.g. Antalya, Muratpaşa';
	@override String get enterManually => 'Enter manually';
	@override String get openSettings => 'Open settings';
	@override late final _Translations$location$settingsRequired$en settingsRequired = _Translations$location$settingsRequired$en._(_root);
	@override String get retryMessage => 'Couldn’t get location. You can try again or type the city.';
	@override late final _Translations$location$manualEntry$en manualEntry = _Translations$location$manualEntry$en._(_root);
}

// Path: profile
class _Translations$profile$en extends Translations$profile$tr {
	_Translations$profile$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Profile';
	@override String get noLocation => 'No location';
	@override String get labelLocation => 'Location';
	@override String get labelTempo => 'Tempo';
	@override String get labelInterests => 'Interests';
	@override String get labelGroup => 'Group';
	@override String get labelTransport => 'Transport';
	@override String get labelLanguage => 'Language';
	@override String get resetOnboarding => 'Reset onboarding';
}

// Path: explore
class _Translations$explore$en extends Translations$explore$tr {
	_Translations$explore$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Explore';
	@override String get subtitle => 'Ideas for any city or region. Pick your destination on the Plan tab.';
	@override late final _Translations$explore$destinations$en destinations = _Translations$explore$destinations$en._(_root);
}

// Path: trips
class _Translations$trips$en extends Translations$trips$tr {
	_Translations$trips$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trips';
	@override String get subtitle => 'Your saved day plans will show up here.';
	@override String get emptyTitle => 'No saved trips yet';
	@override String get emptyBody => 'Create a day on the Plan tab — it will appear here.';
}

// Path: splash
class _Translations$splash$en extends Translations$splash$tr {
	_Translations$splash$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Grounded day plans';
	@override String get continueAction => 'Continue';
}

// Path: common.tempo
class _Translations$common$tempo$en extends Translations$common$tempo$tr {
	_Translations$common$tempo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get calm => 'Calm';
	@override String get balanced => 'Balanced';
	@override String get packed => 'Packed';
}

// Path: common.group
class _Translations$common$group$en extends Translations$common$group$tr {
	_Translations$common$group$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get solo => 'Solo';
	@override String get couple => 'Couple';
	@override String get friends => 'Friends';
	@override String get family => 'Family';
}

// Path: common.transport
class _Translations$common$transport$en extends Translations$common$transport$tr {
	_Translations$common$transport$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get walk => 'Walk';
	@override String get transit => 'Transit';
	@override String get drive => 'Drive';
	@override String get bike => 'Bike';
}

// Path: common.interest
class _Translations$common$interest$en extends Translations$common$interest$tr {
	_Translations$common$interest$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get history => 'History';
	@override String get food => 'Food';
	@override String get nature => 'Nature';
	@override String get art => 'Art';
	@override String get shopping => 'Shopping';
}

// Path: onboarding.welcome
class _Translations$onboarding$welcome$en extends Translations$onboarding$welcome$tr {
	_Translations$onboarding$welcome$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plan the day with real places';
	@override String get body => 'NavGo uses your location and preferences to build a day plan from real venues.';
}

// Path: onboarding.name
class _Translations$onboarding$name$en extends Translations$onboarding$name$tr {
	_Translations$onboarding$name$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'What should we call you?';
	@override String get body => 'A short name for your profile is enough.';
	@override String get hint => 'Your name';
	@override String get errorRequired => 'We need a name so we know how to address you';
}

// Path: onboarding.tempo
class _Translations$onboarding$tempo$en extends Translations$onboarding$tempo$tr {
	_Translations$onboarding$tempo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Day tempo';
	@override String get body => 'How many stops you want — independent of venue density.';
	@override String get calmSubtitle => 'Fewer stops · more breathing room';
	@override String get balancedSubtitle => 'Enjoy the day at ease';
	@override String get packedSubtitle => 'Explore as much as you can';
}

// Path: onboarding.interests
class _Translations$onboarding$interests$en extends Translations$onboarding$interests$tr {
	_Translations$onboarding$interests$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Your interests';
	@override String get body => 'Pick one or more. We’ll bias place search accordingly.';
	@override String get errorMinOne => 'Select at least one interest so we can suggest fitting places';
}

// Path: onboarding.group
class _Translations$onboarding$group$en extends Translations$onboarding$group$tr {
	_Translations$onboarding$group$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Who are you with?';
	@override String get body => 'Your choice shapes the route and stops.';
	@override String get soloSubtitle => 'Explore at your own pace';
	@override String get coupleSubtitle => 'Routes for two';
	@override String get friendsSubtitle => 'Shareable stops';
	@override String get familySubtitle => 'Family-friendly; no bar/pub picks';
}

// Path: onboarding.transport
class _Translations$onboarding$transport$en extends Translations$onboarding$transport$tr {
	_Translations$onboarding$transport$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How will you get around?';
	@override String get body => 'Choose how you’ll move through the day — the route follows.';
	@override String get walkSubtitle => 'On foot';
	@override String get transitSubtitle => 'Metro · bus · tram';
	@override String get driveSubtitle => 'By car';
	@override String get bikeSubtitle => 'Easy pace';
}

// Path: plan.startSheet
class _Translations$plan$startSheet$en extends Translations$plan$startSheet$tr {
	_Translations$plan$startSheet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Where to?';
	@override String get body => 'Use the area from your location or type another destination.';
	@override String get destinationLabel => 'Destination';
	@override String get destinationHint => 'e.g. Kadıköy, Istanbul';
	@override String get useMyLocation => 'Use my location';
	@override String get resolvingLocation => 'Getting location…';
	@override String get areaRequiredSnack => 'Enter a city or district first';
}

// Path: plan.suggestion
class _Translations$plan$suggestion$en extends Translations$plan$suggestion$tr {
	_Translations$plan$suggestion$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$plan$suggestion$historicCenter$en historicCenter = _Translations$plan$suggestion$historicCenter$en._(_root);
	@override late final _Translations$plan$suggestion$waterfront$en waterfront = _Translations$plan$suggestion$waterfront$en._(_root);
	@override late final _Translations$plan$suggestion$coffeeRoute$en coffeeRoute = _Translations$plan$suggestion$coffeeRoute$en._(_root);
	@override late final _Translations$plan$suggestion$museumCulture$en museumCulture = _Translations$plan$suggestion$museumCulture$en._(_root);
}

// Path: location.settingsRequired
class _Translations$location$settingsRequired$en extends Translations$location$settingsRequired$tr {
	_Translations$location$settingsRequired$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get serviceDisabled => 'NavGo needs location services on. Please turn location on in Settings.';
	@override String get permissionDenied => 'NavGo needs location permission. Please allow it.';
	@override String get permissionDeniedForever => 'NavGo needs location permission. Enable it for NavGo in Settings.';
	@override String get fallback => 'NavGo needs location permission. Turn it on in Settings.';
}

// Path: location.manualEntry
class _Translations$location$manualEntry$en extends Translations$location$manualEntry$tr {
	_Translations$location$manualEntry$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get timeout => 'Couldn’t get location. You can continue by typing a city or district.';
	@override String get geocodeFailed => 'Got your coordinates but couldn’t resolve the address (network issue?). Type a city or district to continue.';
	@override String get unknown => 'Couldn’t resolve location due to a connection issue. Type a city or district to continue.';
	@override String get noPermission => 'You can still continue by typing a city or district without location permission.';
	@override String get fallback => 'Couldn’t resolve location. Type a city or district to continue.';
}

// Path: explore.destinations
class _Translations$explore$destinations$en extends Translations$explore$destinations$tr {
	_Translations$explore$destinations$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$destinations$istanbul$en istanbul = _Translations$explore$destinations$istanbul$en._(_root);
	@override late final _Translations$explore$destinations$cappadocia$en cappadocia = _Translations$explore$destinations$cappadocia$en._(_root);
	@override late final _Translations$explore$destinations$rome$en rome = _Translations$explore$destinations$rome$en._(_root);
	@override late final _Translations$explore$destinations$lisbon$en lisbon = _Translations$explore$destinations$lisbon$en._(_root);
	@override late final _Translations$explore$destinations$tokyo$en tokyo = _Translations$explore$destinations$tokyo$en._(_root);
	@override late final _Translations$explore$destinations$barcelona$en barcelona = _Translations$explore$destinations$barcelona$en._(_root);
}

// Path: plan.suggestion.historicCenter
class _Translations$plan$suggestion$historicCenter$en extends Translations$plan$suggestion$historicCenter$tr {
	_Translations$plan$suggestion$historicCenter$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Historic center';
	@override String get subtitle => 'Old streets · square · coffee';
}

// Path: plan.suggestion.waterfront
class _Translations$plan$suggestion$waterfront$en extends Translations$plan$suggestion$waterfront$tr {
	_Translations$plan$suggestion$waterfront$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Waterfront / harbor';
	@override String get subtitle => 'By the water · walk · views';
}

// Path: plan.suggestion.coffeeRoute
class _Translations$plan$suggestion$coffeeRoute$en extends Translations$plan$suggestion$coffeeRoute$tr {
	_Translations$plan$suggestion$coffeeRoute$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Coffee route';
	@override String get subtitle => 'Three stops · calm pace';
}

// Path: plan.suggestion.museumCulture
class _Translations$plan$suggestion$museumCulture$en extends Translations$plan$suggestion$museumCulture$tr {
	_Translations$plan$suggestion$museumCulture$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Museum & culture';
	@override String get subtitle => 'Museum · gallery · monument';
}

// Path: explore.destinations.istanbul
class _Translations$explore$destinations$istanbul$en extends Translations$explore$destinations$istanbul$tr {
	_Translations$explore$destinations$istanbul$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Istanbul';
	@override String get blurb => 'Historic peninsula · Bosphorus · coffee';
}

// Path: explore.destinations.cappadocia
class _Translations$explore$destinations$cappadocia$en extends Translations$explore$destinations$cappadocia$tr {
	_Translations$explore$destinations$cappadocia$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Cappadocia';
	@override String get blurb => 'Valleys · sunrise · walks';
}

// Path: explore.destinations.rome
class _Translations$explore$destinations$rome$en extends Translations$explore$destinations$rome$tr {
	_Translations$explore$destinations$rome$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Rome';
	@override String get blurb => 'Forum · Trastevere · gelato';
}

// Path: explore.destinations.lisbon
class _Translations$explore$destinations$lisbon$en extends Translations$explore$destinations$lisbon$tr {
	_Translations$explore$destinations$lisbon$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Lisbon';
	@override String get blurb => 'Alfama · tram · miradouro';
}

// Path: explore.destinations.tokyo
class _Translations$explore$destinations$tokyo$en extends Translations$explore$destinations$tokyo$tr {
	_Translations$explore$destinations$tokyo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Tokyo';
	@override String get blurb => 'Neighborhoods · temples · ramen';
}

// Path: explore.destinations.barcelona
class _Translations$explore$destinations$barcelona$en extends Translations$explore$destinations$barcelona$tr {
	_Translations$explore$destinations$barcelona$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Barcelona';
	@override String get blurb => 'Gothic quarter · beach · tapas';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.brand' => 'NavGo',
			'common.cancel' => 'Cancel',
			'common.continueAction' => 'Continue',
			'common.ok' => 'OK',
			'common.retry' => 'Try again',
			'common.back' => 'Back',
			'common.emDash' => '—',
			'common.defaultTravelerName' => 'Traveler',
			'common.tempo.calm' => 'Calm',
			'common.tempo.balanced' => 'Balanced',
			'common.tempo.packed' => 'Packed',
			'common.group.solo' => 'Solo',
			'common.group.couple' => 'Couple',
			'common.group.friends' => 'Friends',
			'common.group.family' => 'Family',
			'common.transport.walk' => 'Walk',
			'common.transport.transit' => 'Transit',
			'common.transport.drive' => 'Drive',
			'common.transport.bike' => 'Bike',
			'common.interest.history' => 'History',
			'common.interest.food' => 'Food',
			'common.interest.nature' => 'Nature',
			'common.interest.art' => 'Art',
			'common.interest.shopping' => 'Shopping',
			'shell.tabPlan' => 'Plan',
			'shell.tabTrips' => 'Trips',
			'shell.tabExplore' => 'Explore',
			'shell.tabProfile' => 'Profile',
			'onboarding.stepProgress' => ({required Object current, required Object total}) => '${current}/${total}',
			'onboarding.continueAction' => 'Continue',
			'onboarding.enterApp' => 'Enter NavGo',
			'onboarding.resolvingLocation' => 'Getting location…',
			'onboarding.cityRequiredSnack' => 'City or district is required',
			'onboarding.welcome.title' => 'Plan the day with real places',
			'onboarding.welcome.body' => 'NavGo uses your location and preferences to build a day plan from real venues.',
			'onboarding.name.title' => 'What should we call you?',
			'onboarding.name.body' => 'A short name for your profile is enough.',
			'onboarding.name.hint' => 'Your name',
			'onboarding.name.errorRequired' => 'We need a name so we know how to address you',
			'onboarding.tempo.title' => 'Day tempo',
			'onboarding.tempo.body' => 'How many stops you want — independent of venue density.',
			'onboarding.tempo.calmSubtitle' => 'Fewer stops · more breathing room',
			'onboarding.tempo.balancedSubtitle' => 'Enjoy the day at ease',
			'onboarding.tempo.packedSubtitle' => 'Explore as much as you can',
			'onboarding.interests.title' => 'Your interests',
			'onboarding.interests.body' => 'Pick one or more. We’ll bias place search accordingly.',
			'onboarding.interests.errorMinOne' => 'Select at least one interest so we can suggest fitting places',
			'onboarding.group.title' => 'Who are you with?',
			'onboarding.group.body' => 'Your choice shapes the route and stops.',
			'onboarding.group.soloSubtitle' => 'Explore at your own pace',
			'onboarding.group.coupleSubtitle' => 'Routes for two',
			'onboarding.group.friendsSubtitle' => 'Shareable stops',
			'onboarding.group.familySubtitle' => 'Family-friendly; no bar/pub picks',
			'onboarding.transport.title' => 'How will you get around?',
			'onboarding.transport.body' => 'Choose how you’ll move through the day — the route follows.',
			'onboarding.transport.walkSubtitle' => 'On foot',
			'onboarding.transport.transitSubtitle' => 'Metro · bus · tram',
			'onboarding.transport.driveSubtitle' => 'By car',
			'onboarding.transport.bikeSubtitle' => 'Easy pace',
			'plan.selectLocation' => 'Select location',
			'plan.quickStart' => 'Quick start',
			'plan.quickStartNeedLocation' => 'Pick a location, then choose a route type.',
			'plan.quickStartWithArea' => ({required Object area}) => 'Pick a route type for ${area} — real places based on your interests.',
			'plan.defaultPlanTitle' => 'Day plan',
			'plan.routeSummary' => ({required Object km, required Object mins, required Object provider}) => '${km} km · ~${mins} min · ${provider}',
			'plan.greetingMorning' => 'Good morning',
			'plan.greetingAfternoon' => 'Good afternoon',
			'plan.greetingEvening' => 'Good evening',
			'plan.greetingLine' => ({required Object greeting}) => '${greeting},',
			'plan.heroBadge' => 'Today',
			'plan.heroTitle' => 'One day. Real places.',
			'plan.heroBody' => 'Pick a ready route or build your own — stops come from real venues.',
			'plan.heroCta' => 'Plan a new day',
			'plan.errorTitle' => 'Couldn’t create the plan',
			'plan.tipBanner' => 'Prefer cooler hours for walking — shade and short breaks help in the afternoon.',
			'plan.openInGoogleMaps' => 'Open in Google Maps',
			'plan.backToHome' => 'Back to home',
			'plan.statusSigningIn' => 'Signing in…',
			'plan.statusParsingIntent' => 'Parsing intent with LLM…',
			'plan.statusSearchingPlaces' => 'Searching places…',
			'plan.statusSearchingPlacesTemplate' => 'Searching places with template…',
			'plan.statusPickingStops' => 'Picking stops with LLM…',
			'plan.statusBuildingRoute' => 'Building route…',
			'plan.statusReady' => 'Plan ready',
			'plan.errorDestinationRequired' => 'Destination is required',
			'plan.errorTimeout' => 'The request timed out. Check your connection and try again.',
			'plan.errorConnection' => 'Couldn’t reach the server. Make sure the API is running.',
			'plan.errorAuth' => 'Couldn’t sign in. Please try again.',
			'plan.errorUnprocessable' => 'Those places don’t work for a route. Try another route type.',
			'plan.errorServer' => 'A server error occurred. Try again shortly.',
			'plan.errorNotEnoughPlaces' => 'Not enough places found in this area. Try another destination or route type.',
			'plan.errorGeneric' => 'Couldn’t create the plan. Please try again.',
			'plan.startSheet.title' => 'Where to?',
			'plan.startSheet.body' => 'Use the area from your location or type another destination.',
			'plan.startSheet.destinationLabel' => 'Destination',
			'plan.startSheet.destinationHint' => 'e.g. Kadıköy, Istanbul',
			'plan.startSheet.useMyLocation' => 'Use my location',
			'plan.startSheet.resolvingLocation' => 'Getting location…',
			'plan.startSheet.areaRequiredSnack' => 'Enter a city or district first',
			'plan.suggestion.historicCenter.title' => 'Historic center',
			'plan.suggestion.historicCenter.subtitle' => 'Old streets · square · coffee',
			'plan.suggestion.waterfront.title' => 'Waterfront / harbor',
			'plan.suggestion.waterfront.subtitle' => 'By the water · walk · views',
			'plan.suggestion.coffeeRoute.title' => 'Coffee route',
			'plan.suggestion.coffeeRoute.subtitle' => 'Three stops · calm pace',
			'plan.suggestion.museumCulture.title' => 'Museum & culture',
			'plan.suggestion.museumCulture.subtitle' => 'Museum · gallery · monument',
			'location.requiredTitle' => 'Location required',
			'location.failedTitle' => 'Couldn’t get location',
			'location.manualTitle' => 'City or district',
			'location.manualHint' => 'e.g. Antalya, Muratpaşa',
			'location.enterManually' => 'Enter manually',
			'location.openSettings' => 'Open settings',
			'location.settingsRequired.serviceDisabled' => 'NavGo needs location services on. Please turn location on in Settings.',
			'location.settingsRequired.permissionDenied' => 'NavGo needs location permission. Please allow it.',
			'location.settingsRequired.permissionDeniedForever' => 'NavGo needs location permission. Enable it for NavGo in Settings.',
			'location.settingsRequired.fallback' => 'NavGo needs location permission. Turn it on in Settings.',
			'location.retryMessage' => 'Couldn’t get location. You can try again or type the city.',
			'location.manualEntry.timeout' => 'Couldn’t get location. You can continue by typing a city or district.',
			'location.manualEntry.geocodeFailed' => 'Got your coordinates but couldn’t resolve the address (network issue?). Type a city or district to continue.',
			'location.manualEntry.unknown' => 'Couldn’t resolve location due to a connection issue. Type a city or district to continue.',
			'location.manualEntry.noPermission' => 'You can still continue by typing a city or district without location permission.',
			'location.manualEntry.fallback' => 'Couldn’t resolve location. Type a city or district to continue.',
			'profile.title' => 'Profile',
			'profile.noLocation' => 'No location',
			'profile.labelLocation' => 'Location',
			'profile.labelTempo' => 'Tempo',
			'profile.labelInterests' => 'Interests',
			'profile.labelGroup' => 'Group',
			'profile.labelTransport' => 'Transport',
			'profile.labelLanguage' => 'Language',
			'profile.resetOnboarding' => 'Reset onboarding',
			'explore.title' => 'Explore',
			'explore.subtitle' => 'Ideas for any city or region. Pick your destination on the Plan tab.',
			'explore.destinations.istanbul.name' => 'Istanbul',
			'explore.destinations.istanbul.blurb' => 'Historic peninsula · Bosphorus · coffee',
			'explore.destinations.cappadocia.name' => 'Cappadocia',
			'explore.destinations.cappadocia.blurb' => 'Valleys · sunrise · walks',
			'explore.destinations.rome.name' => 'Rome',
			'explore.destinations.rome.blurb' => 'Forum · Trastevere · gelato',
			'explore.destinations.lisbon.name' => 'Lisbon',
			'explore.destinations.lisbon.blurb' => 'Alfama · tram · miradouro',
			'explore.destinations.tokyo.name' => 'Tokyo',
			'explore.destinations.tokyo.blurb' => 'Neighborhoods · temples · ramen',
			'explore.destinations.barcelona.name' => 'Barcelona',
			'explore.destinations.barcelona.blurb' => 'Gothic quarter · beach · tapas',
			'trips.title' => 'Trips',
			'trips.subtitle' => 'Your saved day plans will show up here.',
			'trips.emptyTitle' => 'No saved trips yet',
			'trips.emptyBody' => 'Create a day on the Plan tab — it will appear here.',
			'splash.tagline' => 'Grounded day plans',
			'splash.continueAction' => 'Continue',
			_ => null,
		};
	}
}
