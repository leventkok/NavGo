///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsTr = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.tr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <tr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$common$tr common = Translations$common$tr.internal(_root);
	late final Translations$shell$tr shell = Translations$shell$tr.internal(_root);
	late final Translations$onboarding$tr onboarding = Translations$onboarding$tr.internal(_root);
	late final Translations$plan$tr plan = Translations$plan$tr.internal(_root);
	late final Translations$routeMap$tr routeMap = Translations$routeMap$tr.internal(_root);
	late final Translations$location$tr location = Translations$location$tr.internal(_root);
	late final Translations$profile$tr profile = Translations$profile$tr.internal(_root);
	late final Translations$explore$tr explore = Translations$explore$tr.internal(_root);
	late final Translations$trips$tr trips = Translations$trips$tr.internal(_root);
	late final Translations$splash$tr splash = Translations$splash$tr.internal(_root);
}

// Path: common
class Translations$common$tr {
	Translations$common$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'NavGo'
	String get brand => 'NavGo';

	/// tr: 'Vazgeç'
	String get cancel => 'Vazgeç';

	/// tr: 'Devam'
	String get continueAction => 'Devam';

	/// tr: 'Tamam'
	String get ok => 'Tamam';

	/// tr: 'Tekrar dene'
	String get retry => 'Tekrar dene';

	/// tr: 'Geri'
	String get back => 'Geri';

	/// tr: '—'
	String get emDash => '—';

	/// tr: 'Gezgin'
	String get defaultTravelerName => 'Gezgin';

	late final Translations$common$tempo$tr tempo = Translations$common$tempo$tr.internal(_root);
	late final Translations$common$group$tr group = Translations$common$group$tr.internal(_root);
	late final Translations$common$transport$tr transport = Translations$common$transport$tr.internal(_root);
	late final Translations$common$interest$tr interest = Translations$common$interest$tr.internal(_root);
}

// Path: shell
class Translations$shell$tr {
	Translations$shell$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Plan'
	String get tabPlan => 'Plan';

	/// tr: 'Trips'
	String get tabTrips => 'Trips';

	/// tr: 'Explore'
	String get tabExplore => 'Explore';

	/// tr: 'Profile'
	String get tabProfile => 'Profile';
}

// Path: onboarding
class Translations$onboarding$tr {
	Translations$onboarding$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: '{current}/{total}'
	String stepProgress({required Object current, required Object total}) => '${current}/${total}';

	/// tr: 'Devam'
	String get continueAction => 'Devam';

	/// tr: 'NavGo’ya gir'
	String get enterApp => 'NavGo’ya gir';

	/// tr: 'Konum alınıyor…'
	String get resolvingLocation => 'Konum alınıyor…';

	/// tr: 'Şehir veya ilçe gerekli'
	String get cityRequiredSnack => 'Şehir veya ilçe gerekli';

	late final Translations$onboarding$welcome$tr welcome = Translations$onboarding$welcome$tr.internal(_root);
	late final Translations$onboarding$name$tr name = Translations$onboarding$name$tr.internal(_root);
	late final Translations$onboarding$tempo$tr tempo = Translations$onboarding$tempo$tr.internal(_root);
	late final Translations$onboarding$interests$tr interests = Translations$onboarding$interests$tr.internal(_root);
	late final Translations$onboarding$group$tr group = Translations$onboarding$group$tr.internal(_root);
	late final Translations$onboarding$transport$tr transport = Translations$onboarding$transport$tr.internal(_root);
}

// Path: plan
class Translations$plan$tr {
	Translations$plan$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Konum seç'
	String get selectLocation => 'Konum seç';

	/// tr: 'Senin için rotalar'
	String get quickStart => 'Senin için rotalar';

	/// tr: 'Konumunu seç, ardından bir rota önerisi aç.'
	String get quickStartNeedLocation => 'Konumunu seç, ardından bir rota önerisi aç.';

	/// tr: 'Bir ruh hali seç, durakları önizle, sonra günü kur.'
	String get quickStartBody => 'Bir ruh hali seç, durakları önizle, sonra günü kur.';

	/// tr: 'Gün planı'
	String get defaultPlanTitle => 'Gün planı';

	/// tr: '{km} km · ~{mins} dk · {provider}'
	String routeSummary({required Object km, required Object mins, required Object provider}) => '${km} km · ~${mins} dk · ${provider}';

	/// tr: 'Günaydın'
	String get greetingMorning => 'Günaydın';

	/// tr: 'İyi günler'
	String get greetingAfternoon => 'İyi günler';

	/// tr: 'İyi akşamlar'
	String get greetingEvening => 'İyi akşamlar';

	/// tr: '{greeting},'
	String greetingLine({required Object greeting}) => '${greeting},';

	/// tr: 'Bugün'
	String get heroBadge => 'Bugün';

	/// tr: 'Bir gün. Gerçek yerler.'
	String get heroTitle => 'Bir gün. Gerçek yerler.';

	/// tr: 'Hazır bir rota seç veya kendi gününü oluştur — duraklar gerçek mekanlardan gelir.'
	String get heroBody => 'Hazır bir rota seç veya kendi gününü oluştur — duraklar gerçek mekanlardan gelir.';

	/// tr: 'Yeni gün planla'
	String get heroCta => 'Yeni gün planla';

	/// tr: 'Plan oluşturulamadı'
	String get errorTitle => 'Plan oluşturulamadı';

	/// tr: 'Yürüyüş için serin saatleri tercih et — öğleden sonra gölgeli sokaklar ve kısa molalar daha rahat.'
	String get tipBanner => 'Yürüyüş için serin saatleri tercih et — öğleden sonra gölgeli sokaklar ve kısa molalar daha rahat.';

	/// tr: 'Google Maps’te aç'
	String get openInGoogleMaps => 'Google Maps’te aç';

	/// tr: 'Ana sayfaya dön'
	String get backToHome => 'Ana sayfaya dön';

	/// tr: 'Oturum açılıyor…'
	String get statusSigningIn => 'Oturum açılıyor…';

	/// tr: 'LLM intent çıkarılıyor…'
	String get statusParsingIntent => 'LLM intent çıkarılıyor…';

	/// tr: 'Mekanlar aranıyor…'
	String get statusSearchingPlaces => 'Mekanlar aranıyor…';

	/// tr: 'Şablon ile mekanlar aranıyor…'
	String get statusSearchingPlacesTemplate => 'Şablon ile mekanlar aranıyor…';

	/// tr: 'LLM durak seçiyor…'
	String get statusPickingStops => 'LLM durak seçiyor…';

	/// tr: 'Rota oluşturuluyor…'
	String get statusBuildingRoute => 'Rota oluşturuluyor…';

	/// tr: 'Plan hazır'
	String get statusReady => 'Plan hazır';

	/// tr: 'Destinasyon gerekli'
	String get errorDestinationRequired => 'Destinasyon gerekli';

	/// tr: 'İstek zaman aşımına uğradı. Bağlantını kontrol edip tekrar dene.'
	String get errorTimeout => 'İstek zaman aşımına uğradı. Bağlantını kontrol edip tekrar dene.';

	/// tr: 'Sunucuya bağlanılamadı. API'nin çalıştığından emin ol.'
	String get errorConnection => 'Sunucuya bağlanılamadı. API\'nin çalıştığından emin ol.';

	/// tr: 'Oturum açılamadı. Lütfen tekrar dene.'
	String get errorAuth => 'Oturum açılamadı. Lütfen tekrar dene.';

	/// tr: 'Seçilen mekanlar rota için uygun değil. Başka bir rota dene.'
	String get errorUnprocessable => 'Seçilen mekanlar rota için uygun değil. Başka bir rota dene.';

	/// tr: 'Sunucu hatası oluştu. Biraz sonra tekrar dene.'
	String get errorServer => 'Sunucu hatası oluştu. Biraz sonra tekrar dene.';

	/// tr: 'Bu bölgede yeterli mekan bulunamadı. Farklı bir destinasyon veya rota tipi dene.'
	String get errorNotEnoughPlaces => 'Bu bölgede yeterli mekan bulunamadı. Farklı bir destinasyon veya rota tipi dene.';

	/// tr: 'Plan oluşturulamadı. Lütfen tekrar dene.'
	String get errorGeneric => 'Plan oluşturulamadı. Lütfen tekrar dene.';

	late final Translations$plan$startSheet$tr startSheet = Translations$plan$startSheet$tr.internal(_root);
	late final Translations$plan$chat$tr chat = Translations$plan$chat$tr.internal(_root);
	late final Translations$plan$suggestion$tr suggestion = Translations$plan$suggestion$tr.internal(_root);

	/// tr: 'Rotalar hazırlanıyor…'
	String get suggestionsLoading => 'Rotalar hazırlanıyor…';

	late final Translations$plan$preview$tr preview = Translations$plan$preview$tr.internal(_root);
	late final Translations$plan$routelistFallback$tr routelistFallback = Translations$plan$routelistFallback$tr.internal(_root);
}

// Path: routeMap
class Translations$routeMap$tr {
	Translations$routeMap$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Rotayı başlat'
	String get openRoute => 'Rotayı başlat';

	/// tr: 'Bitir'
	String get endRoute => 'Bitir';

	/// tr: 'Buradasın'
	String get youAreHere => 'Buradasın';

	/// tr: 'Sıradaki durak'
	String get currentStop => 'Sıradaki durak';

	/// tr: 'Güncel hedef'
	String get currentDestination => 'Güncel hedef';

	/// tr: 'Tamamlandı'
	String get completed => 'Tamamlandı';

	/// tr: 'Devam ediyor'
	String get inProgress => 'Devam ediyor';

	/// tr: 'Başlamadı'
	String get notStarted => 'Başlamadı';

	/// tr: '{count} durak kaldı · {status}'
	String stopsRemaining({required Object count, required Object status}) => '${count} durak kaldı · ${status}';

	/// tr: '{name} durağına vardın'
	String arrived({required Object name}) => '${name} durağına vardın';

	/// tr: 'Konum alınamadı. Harita rotası başlatılamıyor.'
	String get locationError => 'Konum alınamadı. Harita rotası başlatılamıyor.';

	/// tr: 'Rota çizilemedi. Ulaşım modunu değiştirmeyi dene.'
	String get routeError => 'Rota çizilemedi. Ulaşım modunu değiştirmeyi dene.';

	/// tr: 'Toplu taşıma'
	String get transitHint => 'Toplu taşıma';

	/// tr: 'Bu güzergahta otobüs veya hat yok. Yürüyüş daha uygun.'
	String get transitEmpty => 'Bu güzergahta otobüs veya hat yok. Yürüyüş daha uygun.';

	/// tr: 'Yürü: {stop}'
	String transitWalkTo({required Object stop}) => 'Yürü: ${stop}';

	/// tr: '{line} · {from} → {to}'
	String transitRide({required Object line, required Object from, required Object to}) => '${line} · ${from} → ${to}';

	/// tr: 'İn, hedefe yürü'
	String get transitWalkDest => 'İn, hedefe yürü';

	/// tr: 'Biniş durağı'
	String get transitBoard => 'Biniş durağı';

	/// tr: 'Yürüyüş'
	String get modeWalk => 'Yürüyüş';

	/// tr: 'Toplu taşıma'
	String get modeTransit => 'Toplu taşıma';

	/// tr: 'Araba'
	String get modeDrive => 'Araba';

	/// tr: 'Bisiklet'
	String get modeBike => 'Bisiklet';
}

// Path: location
class Translations$location$tr {
	Translations$location$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Konum gerekli'
	String get requiredTitle => 'Konum gerekli';

	/// tr: 'Konum alınamadı'
	String get failedTitle => 'Konum alınamadı';

	/// tr: 'Şehir veya ilçe'
	String get manualTitle => 'Şehir veya ilçe';

	/// tr: 'Örn. Antalya, Muratpaşa'
	String get manualHint => 'Örn. Antalya, Muratpaşa';

	/// tr: 'Manuel gir'
	String get enterManually => 'Manuel gir';

	/// tr: 'Ayarlara git'
	String get openSettings => 'Ayarlara git';

	late final Translations$location$settingsRequired$tr settingsRequired = Translations$location$settingsRequired$tr.internal(_root);

	/// tr: 'Konum alınamadı. Tekrar deneyebilir veya şehri elle yazabilirsin.'
	String get retryMessage => 'Konum alınamadı. Tekrar deneyebilir veya şehri elle yazabilirsin.';

	late final Translations$location$manualEntry$tr manualEntry = Translations$location$manualEntry$tr.internal(_root);
}

// Path: profile
class Translations$profile$tr {
	Translations$profile$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Profile'
	String get title => 'Profile';

	/// tr: 'Konum yok'
	String get noLocation => 'Konum yok';

	/// tr: 'Konum'
	String get labelLocation => 'Konum';

	/// tr: 'Tempo'
	String get labelTempo => 'Tempo';

	/// tr: 'İlgi'
	String get labelInterests => 'İlgi';

	/// tr: 'Grup'
	String get labelGroup => 'Grup';

	/// tr: 'Taşıt'
	String get labelTransport => 'Taşıt';

	/// tr: 'Dil'
	String get labelLanguage => 'Dil';

	/// tr: 'Onboarding’i sıfırla'
	String get resetOnboarding => 'Onboarding’i sıfırla';
}

// Path: explore
class Translations$explore$tr {
	Translations$explore$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Explore'
	String get title => 'Explore';

	/// tr: 'Herhangi bir şehir veya bölge için fikirler. Plan sekmesinde destinasyonunu seç.'
	String get subtitle => 'Herhangi bir şehir veya bölge için fikirler. Plan sekmesinde destinasyonunu seç.';

	late final Translations$explore$destinations$tr destinations = Translations$explore$destinations$tr.internal(_root);
}

// Path: trips
class Translations$trips$tr {
	Translations$trips$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Trips'
	String get title => 'Trips';

	/// tr: 'Kaydettiğin gün planları burada listelenir.'
	String get subtitle => 'Kaydettiğin gün planları burada listelenir.';

	/// tr: 'Henüz kayıtlı trip yok'
	String get emptyTitle => 'Henüz kayıtlı trip yok';

	/// tr: 'Plan sekmesinden bir gün oluştur, sonra burada görünecek.'
	String get emptyBody => 'Plan sekmesinden bir gün oluştur, sonra burada görünecek.';
}

// Path: splash
class Translations$splash$tr {
	Translations$splash$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Gerçek yerlerle gün planı'
	String get tagline => 'Gerçek yerlerle gün planı';

	/// tr: 'Devam'
	String get continueAction => 'Devam';
}

// Path: common.tempo
class Translations$common$tempo$tr {
	Translations$common$tempo$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Sakin'
	String get calm => 'Sakin';

	/// tr: 'Dengeli'
	String get balanced => 'Dengeli';

	/// tr: 'Dolu'
	String get packed => 'Dolu';
}

// Path: common.group
class Translations$common$group$tr {
	Translations$common$group$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Yalnız'
	String get solo => 'Yalnız';

	/// tr: 'Çift'
	String get couple => 'Çift';

	/// tr: 'Arkadaş'
	String get friends => 'Arkadaş';

	/// tr: 'Aile'
	String get family => 'Aile';
}

// Path: common.transport
class Translations$common$transport$tr {
	Translations$common$transport$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Yürüyüş'
	String get walk => 'Yürüyüş';

	/// tr: 'Toplu taşıma'
	String get transit => 'Toplu taşıma';

	/// tr: 'Araç'
	String get drive => 'Araç';

	/// tr: 'Bisiklet'
	String get bike => 'Bisiklet';
}

// Path: common.interest
class Translations$common$interest$tr {
	Translations$common$interest$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Tarih'
	String get history => 'Tarih';

	/// tr: 'Yemek'
	String get food => 'Yemek';

	/// tr: 'Doğa'
	String get nature => 'Doğa';

	/// tr: 'Sanat'
	String get art => 'Sanat';

	/// tr: 'Alışveriş'
	String get shopping => 'Alışveriş';
}

// Path: onboarding.welcome
class Translations$onboarding$welcome$tr {
	Translations$onboarding$welcome$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Günü gerçek yerlerle planla'
	String get title => 'Günü gerçek yerlerle planla';

	/// tr: 'NavGo, konumunu ve tercihlerini alır; gerçek yerlerden rota ve gün planı oluşturur.'
	String get body => 'NavGo, konumunu ve tercihlerini alır; gerçek yerlerden rota ve gün planı oluşturur.';
}

// Path: onboarding.name
class Translations$onboarding$name$tr {
	Translations$onboarding$name$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Seni nasıl çağıralım?'
	String get title => 'Seni nasıl çağıralım?';

	/// tr: 'Profilinde görünecek kısa bir isim yeter.'
	String get body => 'Profilinde görünecek kısa bir isim yeter.';

	/// tr: 'Adın'
	String get hint => 'Adın';

	/// tr: 'Sana nasıl sesleneceğimizi bilmemiz için isim gerekli'
	String get errorRequired => 'Sana nasıl sesleneceğimizi bilmemiz için isim gerekli';
}

// Path: onboarding.tempo
class Translations$onboarding$tempo$tr {
	Translations$onboarding$tempo$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Günün temposu'
	String get title => 'Günün temposu';

	/// tr: 'Kaç durak istediğin — mekan yoğunluğundan bağımsız tercihin.'
	String get body => 'Kaç durak istediğin — mekan yoğunluğundan bağımsız tercihin.';

	/// tr: 'Az durak · bol nefes'
	String get calmSubtitle => 'Az durak · bol nefes';

	/// tr: 'Günün tadını çıkar'
	String get balancedSubtitle => 'Günün tadını çıkar';

	/// tr: 'Mümkün olduğunca keşfet'
	String get packedSubtitle => 'Mümkün olduğunca keşfet';
}

// Path: onboarding.interests
class Translations$onboarding$interests$tr {
	Translations$onboarding$interests$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'İlgi alanların'
	String get title => 'İlgi alanların';

	/// tr: 'Birden fazla seçebilirsin. Mekan aramasını buna göre yönlendiririz.'
	String get body => 'Birden fazla seçebilirsin. Mekan aramasını buna göre yönlendiririz.';

	/// tr: 'Sana uygun mekanlar önerebilmemiz için en az bir ilgi alanı seç'
	String get errorMinOne => 'Sana uygun mekanlar önerebilmemiz için en az bir ilgi alanı seç';
}

// Path: onboarding.group
class Translations$onboarding$group$tr {
	Translations$onboarding$group$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Kimle geziyorsun?'
	String get title => 'Kimle geziyorsun?';

	/// tr: 'Tercihin rotanı ve durakları şekillendirir.'
	String get body => 'Tercihin rotanı ve durakları şekillendirir.';

	/// tr: 'Kendi temposunda keşif'
	String get soloSubtitle => 'Kendi temposunda keşif';

	/// tr: 'İki kişilik rotalar'
	String get coupleSubtitle => 'İki kişilik rotalar';

	/// tr: 'Paylaşılabilir duraklar'
	String get friendsSubtitle => 'Paylaşılabilir duraklar';

	/// tr: 'Aile dostu; bar/pub önerilmez'
	String get familySubtitle => 'Aile dostu; bar/pub önerilmez';
}

// Path: onboarding.transport
class Translations$onboarding$transport$tr {
	Translations$onboarding$transport$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Nasıl ilerleyelim?'
	String get title => 'Nasıl ilerleyelim?';

	/// tr: 'Gün boyunca nasıl dolaşacağını seç — rotan buna göre kurulur.'
	String get body => 'Gün boyunca nasıl dolaşacağını seç — rotan buna göre kurulur.';

	/// tr: 'Yaya rota'
	String get walkSubtitle => 'Yaya rota';

	/// tr: 'Metro · otobüs · tramvay'
	String get transitSubtitle => 'Metro · otobüs · tramvay';

	/// tr: 'Araba ile bağlantı'
	String get driveSubtitle => 'Araba ile bağlantı';

	/// tr: 'Hafif tempo'
	String get bikeSubtitle => 'Hafif tempo';
}

// Path: plan.startSheet
class Translations$plan$startSheet$tr {
	Translations$plan$startSheet$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Nereye gidelim?'
	String get title => 'Nereye gidelim?';

	/// tr: 'Konumundan gelen alanı kullan veya başka bir destinasyon yaz.'
	String get body => 'Konumundan gelen alanı kullan veya başka bir destinasyon yaz.';

	/// tr: 'Destinasyon'
	String get destinationLabel => 'Destinasyon';

	/// tr: 'Örn. Kadıköy, İstanbul'
	String get destinationHint => 'Örn. Kadıköy, İstanbul';

	/// tr: 'Konumumu kullan'
	String get useMyLocation => 'Konumumu kullan';

	/// tr: 'Konum alınıyor…'
	String get resolvingLocation => 'Konum alınıyor…';

	/// tr: 'Sohbette aç'
	String get openInChat => 'Sohbette aç';

	/// tr: 'Önce şehir veya ilçe yaz'
	String get areaRequiredSnack => 'Önce şehir veya ilçe yaz';
}

// Path: plan.chat
class Translations$plan$chat$tr {
	Translations$plan$chat$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Konuşarak planla'
	String get title => 'Konuşarak planla';

	/// tr: 'Konum paylaşmadan anlat'
	String get emptyTitle => 'Konum paylaşmadan anlat';

	/// tr: 'Gitmek istediğin günü yaz — şehir, tempo, ne görmek istediğin. Konum izni gerekmez.'
	String get emptyBody => 'Gitmek istediğin günü yaz — şehir, tempo, ne görmek istediğin. Konum izni gerekmez.';

	/// tr: 'Bugün ne yapmak istiyorsun?'
	String get inputHint => 'Bugün ne yapmak istiyorsun?';

	/// tr: 'Bu rotayı nasıl değiştirelim?'
	String get replyHint => 'Bu rotayı nasıl değiştirelim?';

	/// tr: 'Cevap ver'
	String get reply => 'Cevap ver';

	/// tr: 'Diğer'
	String get more => 'Diğer';

	/// tr: 'Yanıtlanan rota'
	String get quoting => 'Yanıtlanan rota';

	/// tr: 'Önizlemek için dokun'
	String get tapToPreview => 'Önizlemek için dokun';

	/// tr: 'Rota önerilemedi. Tekrar dene.'
	String get error => 'Rota önerilemedi. Tekrar dene.';

	/// tr: 'Model isteği kabul etmedi (LLM anahtarı). Colab çıktısındaki anahtarı .env ile eşle.'
	String get errorAuth => 'Model isteği kabul etmedi (LLM anahtarı). Colab çıktısındaki anahtarı .env ile eşle.';

	/// tr: 'Tekrar dene'
	String get retry => 'Tekrar dene';

	/// tr: 'Konuşmak için dokun'
	String get holdToSpeak => 'Konuşmak için dokun';

	/// tr: 'Kayıt alınıyor… tekrar dokununca gönderilir'
	String get listening => 'Kayıt alınıyor… tekrar dokununca gönderilir';

	/// tr: 'Mikrofon veya konuşma tanıma kullanılamıyor.'
	String get voiceUnavailable => 'Mikrofon veya konuşma tanıma kullanılamıyor.';

	/// tr: 'Ses algılanmadı. Tekrar dokun.'
	String get voiceEmpty => 'Ses algılanmadı. Tekrar dokun.';

	/// tr: 'Tekrar dinle'
	String get replayVoice => 'Tekrar dinle';

	late final Translations$plan$chat$thinking$tr thinking = Translations$plan$chat$thinking$tr.internal(_root);
}

// Path: plan.suggestion
class Translations$plan$suggestion$tr {
	Translations$plan$suggestion$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$plan$suggestion$historicCenter$tr historicCenter = Translations$plan$suggestion$historicCenter$tr.internal(_root);
	late final Translations$plan$suggestion$waterfront$tr waterfront = Translations$plan$suggestion$waterfront$tr.internal(_root);
	late final Translations$plan$suggestion$coffeeRoute$tr coffeeRoute = Translations$plan$suggestion$coffeeRoute$tr.internal(_root);
	late final Translations$plan$suggestion$museumCulture$tr museumCulture = Translations$plan$suggestion$museumCulture$tr.internal(_root);
	late final Translations$plan$suggestion$parksLakes$tr parksLakes = Translations$plan$suggestion$parksLakes$tr.internal(_root);
}

// Path: plan.preview
class Translations$plan$preview$tr {
	Translations$plan$preview$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Bu rotayı kur'
	String get buildRoute => 'Bu rotayı kur';

	/// tr: 'Vazgeç'
	String get dismiss => 'Vazgeç';

	/// tr: 'Yine de planla'
	String get planAnyway => 'Yine de planla';

	/// tr: 'Duraklar yüklenemedi. Tekrar deneyebilir veya yine de planlayabilirsin.'
	String get failed => 'Duraklar yüklenemedi. Tekrar deneyebilir veya yine de planlayabilirsin.';

	/// tr: 'Bu ruh hali için yeterince mekan bulunamadı.'
	String get empty => 'Bu ruh hali için yeterince mekan bulunamadı.';
}

// Path: plan.routelistFallback
class Translations$plan$routelistFallback$tr {
	Translations$plan$routelistFallback$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$plan$routelistFallback$firstDay$tr firstDay = Translations$plan$routelistFallback$firstDay$tr.internal(_root);
	late final Translations$plan$routelistFallback$slow$tr slow = Translations$plan$routelistFallback$slow$tr.internal(_root);
	late final Translations$plan$routelistFallback$culture$tr culture = Translations$plan$routelistFallback$culture$tr.internal(_root);
	late final Translations$plan$routelistFallback$food$tr food = Translations$plan$routelistFallback$food$tr.internal(_root);
}

// Path: location.settingsRequired
class Translations$location$settingsRequired$tr {
	Translations$location$settingsRequired$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'NavGo çalışmak için cihazında konum servisi açık olmalı. Lütfen ayarlardan konumu aç.'
	String get serviceDisabled => 'NavGo çalışmak için cihazında konum servisi açık olmalı. Lütfen ayarlardan konumu aç.';

	/// tr: 'NavGo çalışmak için konum izni gerekli. Lütfen izin ver.'
	String get permissionDenied => 'NavGo çalışmak için konum izni gerekli. Lütfen izin ver.';

	/// tr: 'NavGo çalışmak için konum izni gerekli. Ayarlardan NavGo için konumu aç.'
	String get permissionDeniedForever => 'NavGo çalışmak için konum izni gerekli. Ayarlardan NavGo için konumu aç.';

	/// tr: 'NavGo çalışmak için konum izni gerekli. Ayarlardan konumu aç.'
	String get fallback => 'NavGo çalışmak için konum izni gerekli. Ayarlardan konumu aç.';
}

// Path: location.manualEntry
class Translations$location$manualEntry$tr {
	Translations$location$manualEntry$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Konum alınamadı. Şehir veya ilçe yazarak devam edebilirsin.'
	String get timeout => 'Konum alınamadı. Şehir veya ilçe yazarak devam edebilirsin.';

	/// tr: 'Konumun alındı ama adres çözülemedi (ağ sorunu olabilir). Şehir veya ilçe yazarak devam edebilirsin.'
	String get geocodeFailed => 'Konumun alındı ama adres çözülemedi (ağ sorunu olabilir). Şehir veya ilçe yazarak devam edebilirsin.';

	/// tr: 'Bağlantı sorunu nedeniyle konum çözülemedi. Şehir veya ilçe yazarak devam edebilirsin.'
	String get unknown => 'Bağlantı sorunu nedeniyle konum çözülemedi. Şehir veya ilçe yazarak devam edebilirsin.';

	/// tr: 'Konum izni olmadan da şehir veya ilçe yazarak devam edebilirsin.'
	String get noPermission => 'Konum izni olmadan da şehir veya ilçe yazarak devam edebilirsin.';

	/// tr: 'Konum çözülemedi. Şehir veya ilçe yazarak devam edebilirsin.'
	String get fallback => 'Konum çözülemedi. Şehir veya ilçe yazarak devam edebilirsin.';
}

// Path: explore.destinations
class Translations$explore$destinations$tr {
	Translations$explore$destinations$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$explore$destinations$istanbul$tr istanbul = Translations$explore$destinations$istanbul$tr.internal(_root);
	late final Translations$explore$destinations$cappadocia$tr cappadocia = Translations$explore$destinations$cappadocia$tr.internal(_root);
	late final Translations$explore$destinations$rome$tr rome = Translations$explore$destinations$rome$tr.internal(_root);
	late final Translations$explore$destinations$lisbon$tr lisbon = Translations$explore$destinations$lisbon$tr.internal(_root);
	late final Translations$explore$destinations$tokyo$tr tokyo = Translations$explore$destinations$tokyo$tr.internal(_root);
	late final Translations$explore$destinations$barcelona$tr barcelona = Translations$explore$destinations$barcelona$tr.internal(_root);
}

// Path: plan.chat.thinking
class Translations$plan$chat$thinking$tr {
	Translations$plan$chat$thinking$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Düşünüyor…'
	String get s1 => 'Düşünüyor…';

	/// tr: 'Ruh halini seçiyor…'
	String get s2 => 'Ruh halini seçiyor…';

	/// tr: 'Rotayı örüyor…'
	String get s3 => 'Rotayı örüyor…';

	/// tr: 'Durakları sadeleştiriyor…'
	String get s4 => 'Durakları sadeleştiriyor…';

	/// tr: 'Konuma göre ayarlıyor…'
	String get s5 => 'Konuma göre ayarlıyor…';
}

// Path: plan.suggestion.historicCenter
class Translations$plan$suggestion$historicCenter$tr {
	Translations$plan$suggestion$historicCenter$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Tarihi merkez'
	String get title => 'Tarihi merkez';

	/// tr: 'Eski sokaklar · meydan · kahve'
	String get subtitle => 'Eski sokaklar · meydan · kahve';
}

// Path: plan.suggestion.waterfront
class Translations$plan$suggestion$waterfront$tr {
	Translations$plan$suggestion$waterfront$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Sahil / liman'
	String get title => 'Sahil / liman';

	/// tr: 'Su kenarı · yürüyüş · manzara'
	String get subtitle => 'Su kenarı · yürüyüş · manzara';
}

// Path: plan.suggestion.coffeeRoute
class Translations$plan$suggestion$coffeeRoute$tr {
	Translations$plan$suggestion$coffeeRoute$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Kahve rotası'
	String get title => 'Kahve rotası';

	/// tr: 'Üç durak · sakin tempo'
	String get subtitle => 'Üç durak · sakin tempo';
}

// Path: plan.suggestion.museumCulture
class Translations$plan$suggestion$museumCulture$tr {
	Translations$plan$suggestion$museumCulture$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Müze & kültür'
	String get title => 'Müze & kültür';

	/// tr: 'Müze · galeri · anıt'
	String get subtitle => 'Müze · galeri · anıt';
}

// Path: plan.suggestion.parksLakes
class Translations$plan$suggestion$parksLakes$tr {
	Translations$plan$suggestion$parksLakes$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Park & göl'
	String get title => 'Park & göl';

	/// tr: 'Yeşil alan · yürüyüş · dinlenme'
	String get subtitle => 'Yeşil alan · yürüyüş · dinlenme';
}

// Path: plan.routelistFallback.firstDay
class Translations$plan$routelistFallback$firstDay$tr {
	Translations$plan$routelistFallback$firstDay$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Şehre yeni misin?'
	String get title => 'Şehre yeni misin?';

	/// tr: 'İkonik duraklarla hızlı bir tur'
	String get subtitle => 'İkonik duraklarla hızlı bir tur';
}

// Path: plan.routelistFallback.slow
class Translations$plan$routelistFallback$slow$tr {
	Translations$plan$routelistFallback$slow$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Ağırdan al'
	String get title => 'Ağırdan al';

	/// tr: 'Kahve, park ve kısa yürüyüş'
	String get subtitle => 'Kahve, park ve kısa yürüyüş';
}

// Path: plan.routelistFallback.culture
class Translations$plan$routelistFallback$culture$tr {
	Translations$plan$routelistFallback$culture$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Hikâyeyi dinle'
	String get title => 'Hikâyeyi dinle';

	/// tr: 'Müze, anıt ve eski sokaklar'
	String get subtitle => 'Müze, anıt ve eski sokaklar';
}

// Path: plan.routelistFallback.food
class Translations$plan$routelistFallback$food$tr {
	Translations$plan$routelistFallback$food$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Yerel tat'
	String get title => 'Yerel tat';

	/// tr: 'Esnaf, pazar ve sokak lezzeti'
	String get subtitle => 'Esnaf, pazar ve sokak lezzeti';
}

// Path: explore.destinations.istanbul
class Translations$explore$destinations$istanbul$tr {
	Translations$explore$destinations$istanbul$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'İstanbul'
	String get name => 'İstanbul';

	/// tr: 'Tarihi yarımada · Boğaz · kahve'
	String get blurb => 'Tarihi yarımada · Boğaz · kahve';
}

// Path: explore.destinations.cappadocia
class Translations$explore$destinations$cappadocia$tr {
	Translations$explore$destinations$cappadocia$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Kapadokya'
	String get name => 'Kapadokya';

	/// tr: 'Vadiler · gün doğumu · yürüyüş'
	String get blurb => 'Vadiler · gün doğumu · yürüyüş';
}

// Path: explore.destinations.rome
class Translations$explore$destinations$rome$tr {
	Translations$explore$destinations$rome$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Roma'
	String get name => 'Roma';

	/// tr: 'Forum · Trastevere · gelato'
	String get blurb => 'Forum · Trastevere · gelato';
}

// Path: explore.destinations.lisbon
class Translations$explore$destinations$lisbon$tr {
	Translations$explore$destinations$lisbon$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Lizbon'
	String get name => 'Lizbon';

	/// tr: 'Alfama · tramvay · miradouro'
	String get blurb => 'Alfama · tramvay · miradouro';
}

// Path: explore.destinations.tokyo
class Translations$explore$destinations$tokyo$tr {
	Translations$explore$destinations$tokyo$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Tokyo'
	String get name => 'Tokyo';

	/// tr: 'Mahalleler · tapınak · ramen'
	String get blurb => 'Mahalleler · tapınak · ramen';
}

// Path: explore.destinations.barcelona
class Translations$explore$destinations$barcelona$tr {
	Translations$explore$destinations$barcelona$tr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// tr: 'Barselona'
	String get name => 'Barselona';

	/// tr: 'Gotik mahalle · plaj · tapas'
	String get blurb => 'Gotik mahalle · plaj · tapas';
}

/// The flat map containing all translations for locale <tr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.brand' => 'NavGo',
			'common.cancel' => 'Vazgeç',
			'common.continueAction' => 'Devam',
			'common.ok' => 'Tamam',
			'common.retry' => 'Tekrar dene',
			'common.back' => 'Geri',
			'common.emDash' => '—',
			'common.defaultTravelerName' => 'Gezgin',
			'common.tempo.calm' => 'Sakin',
			'common.tempo.balanced' => 'Dengeli',
			'common.tempo.packed' => 'Dolu',
			'common.group.solo' => 'Yalnız',
			'common.group.couple' => 'Çift',
			'common.group.friends' => 'Arkadaş',
			'common.group.family' => 'Aile',
			'common.transport.walk' => 'Yürüyüş',
			'common.transport.transit' => 'Toplu taşıma',
			'common.transport.drive' => 'Araç',
			'common.transport.bike' => 'Bisiklet',
			'common.interest.history' => 'Tarih',
			'common.interest.food' => 'Yemek',
			'common.interest.nature' => 'Doğa',
			'common.interest.art' => 'Sanat',
			'common.interest.shopping' => 'Alışveriş',
			'shell.tabPlan' => 'Plan',
			'shell.tabTrips' => 'Trips',
			'shell.tabExplore' => 'Explore',
			'shell.tabProfile' => 'Profile',
			'onboarding.stepProgress' => ({required Object current, required Object total}) => '${current}/${total}',
			'onboarding.continueAction' => 'Devam',
			'onboarding.enterApp' => 'NavGo’ya gir',
			'onboarding.resolvingLocation' => 'Konum alınıyor…',
			'onboarding.cityRequiredSnack' => 'Şehir veya ilçe gerekli',
			'onboarding.welcome.title' => 'Günü gerçek yerlerle planla',
			'onboarding.welcome.body' => 'NavGo, konumunu ve tercihlerini alır; gerçek yerlerden rota ve gün planı oluşturur.',
			'onboarding.name.title' => 'Seni nasıl çağıralım?',
			'onboarding.name.body' => 'Profilinde görünecek kısa bir isim yeter.',
			'onboarding.name.hint' => 'Adın',
			'onboarding.name.errorRequired' => 'Sana nasıl sesleneceğimizi bilmemiz için isim gerekli',
			'onboarding.tempo.title' => 'Günün temposu',
			'onboarding.tempo.body' => 'Kaç durak istediğin — mekan yoğunluğundan bağımsız tercihin.',
			'onboarding.tempo.calmSubtitle' => 'Az durak · bol nefes',
			'onboarding.tempo.balancedSubtitle' => 'Günün tadını çıkar',
			'onboarding.tempo.packedSubtitle' => 'Mümkün olduğunca keşfet',
			'onboarding.interests.title' => 'İlgi alanların',
			'onboarding.interests.body' => 'Birden fazla seçebilirsin. Mekan aramasını buna göre yönlendiririz.',
			'onboarding.interests.errorMinOne' => 'Sana uygun mekanlar önerebilmemiz için en az bir ilgi alanı seç',
			'onboarding.group.title' => 'Kimle geziyorsun?',
			'onboarding.group.body' => 'Tercihin rotanı ve durakları şekillendirir.',
			'onboarding.group.soloSubtitle' => 'Kendi temposunda keşif',
			'onboarding.group.coupleSubtitle' => 'İki kişilik rotalar',
			'onboarding.group.friendsSubtitle' => 'Paylaşılabilir duraklar',
			'onboarding.group.familySubtitle' => 'Aile dostu; bar/pub önerilmez',
			'onboarding.transport.title' => 'Nasıl ilerleyelim?',
			'onboarding.transport.body' => 'Gün boyunca nasıl dolaşacağını seç — rotan buna göre kurulur.',
			'onboarding.transport.walkSubtitle' => 'Yaya rota',
			'onboarding.transport.transitSubtitle' => 'Metro · otobüs · tramvay',
			'onboarding.transport.driveSubtitle' => 'Araba ile bağlantı',
			'onboarding.transport.bikeSubtitle' => 'Hafif tempo',
			'plan.selectLocation' => 'Konum seç',
			'plan.quickStart' => 'Senin için rotalar',
			'plan.quickStartNeedLocation' => 'Konumunu seç, ardından bir rota önerisi aç.',
			'plan.quickStartBody' => 'Bir ruh hali seç, durakları önizle, sonra günü kur.',
			'plan.defaultPlanTitle' => 'Gün planı',
			'plan.routeSummary' => ({required Object km, required Object mins, required Object provider}) => '${km} km · ~${mins} dk · ${provider}',
			'plan.greetingMorning' => 'Günaydın',
			'plan.greetingAfternoon' => 'İyi günler',
			'plan.greetingEvening' => 'İyi akşamlar',
			'plan.greetingLine' => ({required Object greeting}) => '${greeting},',
			'plan.heroBadge' => 'Bugün',
			'plan.heroTitle' => 'Bir gün. Gerçek yerler.',
			'plan.heroBody' => 'Hazır bir rota seç veya kendi gününü oluştur — duraklar gerçek mekanlardan gelir.',
			'plan.heroCta' => 'Yeni gün planla',
			'plan.errorTitle' => 'Plan oluşturulamadı',
			'plan.tipBanner' => 'Yürüyüş için serin saatleri tercih et — öğleden sonra gölgeli sokaklar ve kısa molalar daha rahat.',
			'plan.openInGoogleMaps' => 'Google Maps’te aç',
			'plan.backToHome' => 'Ana sayfaya dön',
			'plan.statusSigningIn' => 'Oturum açılıyor…',
			'plan.statusParsingIntent' => 'LLM intent çıkarılıyor…',
			'plan.statusSearchingPlaces' => 'Mekanlar aranıyor…',
			'plan.statusSearchingPlacesTemplate' => 'Şablon ile mekanlar aranıyor…',
			'plan.statusPickingStops' => 'LLM durak seçiyor…',
			'plan.statusBuildingRoute' => 'Rota oluşturuluyor…',
			'plan.statusReady' => 'Plan hazır',
			'plan.errorDestinationRequired' => 'Destinasyon gerekli',
			'plan.errorTimeout' => 'İstek zaman aşımına uğradı. Bağlantını kontrol edip tekrar dene.',
			'plan.errorConnection' => 'Sunucuya bağlanılamadı. API\'nin çalıştığından emin ol.',
			'plan.errorAuth' => 'Oturum açılamadı. Lütfen tekrar dene.',
			'plan.errorUnprocessable' => 'Seçilen mekanlar rota için uygun değil. Başka bir rota dene.',
			'plan.errorServer' => 'Sunucu hatası oluştu. Biraz sonra tekrar dene.',
			'plan.errorNotEnoughPlaces' => 'Bu bölgede yeterli mekan bulunamadı. Farklı bir destinasyon veya rota tipi dene.',
			'plan.errorGeneric' => 'Plan oluşturulamadı. Lütfen tekrar dene.',
			'plan.startSheet.title' => 'Nereye gidelim?',
			'plan.startSheet.body' => 'Konumundan gelen alanı kullan veya başka bir destinasyon yaz.',
			'plan.startSheet.destinationLabel' => 'Destinasyon',
			'plan.startSheet.destinationHint' => 'Örn. Kadıköy, İstanbul',
			'plan.startSheet.useMyLocation' => 'Konumumu kullan',
			'plan.startSheet.resolvingLocation' => 'Konum alınıyor…',
			'plan.startSheet.openInChat' => 'Sohbette aç',
			'plan.startSheet.areaRequiredSnack' => 'Önce şehir veya ilçe yaz',
			'plan.chat.title' => 'Konuşarak planla',
			'plan.chat.emptyTitle' => 'Konum paylaşmadan anlat',
			'plan.chat.emptyBody' => 'Gitmek istediğin günü yaz — şehir, tempo, ne görmek istediğin. Konum izni gerekmez.',
			'plan.chat.inputHint' => 'Bugün ne yapmak istiyorsun?',
			'plan.chat.replyHint' => 'Bu rotayı nasıl değiştirelim?',
			'plan.chat.reply' => 'Cevap ver',
			'plan.chat.more' => 'Diğer',
			'plan.chat.quoting' => 'Yanıtlanan rota',
			'plan.chat.tapToPreview' => 'Önizlemek için dokun',
			'plan.chat.error' => 'Rota önerilemedi. Tekrar dene.',
			'plan.chat.errorAuth' => 'Model isteği kabul etmedi (LLM anahtarı). Colab çıktısındaki anahtarı .env ile eşle.',
			'plan.chat.retry' => 'Tekrar dene',
			'plan.chat.holdToSpeak' => 'Konuşmak için dokun',
			'plan.chat.listening' => 'Kayıt alınıyor… tekrar dokununca gönderilir',
			'plan.chat.voiceUnavailable' => 'Mikrofon veya konuşma tanıma kullanılamıyor.',
			'plan.chat.voiceEmpty' => 'Ses algılanmadı. Tekrar dokun.',
			'plan.chat.replayVoice' => 'Tekrar dinle',
			'plan.chat.thinking.s1' => 'Düşünüyor…',
			'plan.chat.thinking.s2' => 'Ruh halini seçiyor…',
			'plan.chat.thinking.s3' => 'Rotayı örüyor…',
			'plan.chat.thinking.s4' => 'Durakları sadeleştiriyor…',
			'plan.chat.thinking.s5' => 'Konuma göre ayarlıyor…',
			'plan.suggestion.historicCenter.title' => 'Tarihi merkez',
			'plan.suggestion.historicCenter.subtitle' => 'Eski sokaklar · meydan · kahve',
			'plan.suggestion.waterfront.title' => 'Sahil / liman',
			'plan.suggestion.waterfront.subtitle' => 'Su kenarı · yürüyüş · manzara',
			'plan.suggestion.coffeeRoute.title' => 'Kahve rotası',
			'plan.suggestion.coffeeRoute.subtitle' => 'Üç durak · sakin tempo',
			'plan.suggestion.museumCulture.title' => 'Müze & kültür',
			'plan.suggestion.museumCulture.subtitle' => 'Müze · galeri · anıt',
			'plan.suggestion.parksLakes.title' => 'Park & göl',
			'plan.suggestion.parksLakes.subtitle' => 'Yeşil alan · yürüyüş · dinlenme',
			'plan.suggestionsLoading' => 'Rotalar hazırlanıyor…',
			'plan.preview.buildRoute' => 'Bu rotayı kur',
			'plan.preview.dismiss' => 'Vazgeç',
			'plan.preview.planAnyway' => 'Yine de planla',
			'plan.preview.failed' => 'Duraklar yüklenemedi. Tekrar deneyebilir veya yine de planlayabilirsin.',
			'plan.preview.empty' => 'Bu ruh hali için yeterince mekan bulunamadı.',
			'plan.routelistFallback.firstDay.title' => 'Şehre yeni misin?',
			'plan.routelistFallback.firstDay.subtitle' => 'İkonik duraklarla hızlı bir tur',
			'plan.routelistFallback.slow.title' => 'Ağırdan al',
			'plan.routelistFallback.slow.subtitle' => 'Kahve, park ve kısa yürüyüş',
			'plan.routelistFallback.culture.title' => 'Hikâyeyi dinle',
			'plan.routelistFallback.culture.subtitle' => 'Müze, anıt ve eski sokaklar',
			'plan.routelistFallback.food.title' => 'Yerel tat',
			'plan.routelistFallback.food.subtitle' => 'Esnaf, pazar ve sokak lezzeti',
			'routeMap.openRoute' => 'Rotayı başlat',
			'routeMap.endRoute' => 'Bitir',
			'routeMap.youAreHere' => 'Buradasın',
			'routeMap.currentStop' => 'Sıradaki durak',
			'routeMap.currentDestination' => 'Güncel hedef',
			'routeMap.completed' => 'Tamamlandı',
			'routeMap.inProgress' => 'Devam ediyor',
			'routeMap.notStarted' => 'Başlamadı',
			'routeMap.stopsRemaining' => ({required Object count, required Object status}) => '${count} durak kaldı · ${status}',
			'routeMap.arrived' => ({required Object name}) => '${name} durağına vardın',
			'routeMap.locationError' => 'Konum alınamadı. Harita rotası başlatılamıyor.',
			'routeMap.routeError' => 'Rota çizilemedi. Ulaşım modunu değiştirmeyi dene.',
			'routeMap.transitHint' => 'Toplu taşıma',
			'routeMap.transitEmpty' => 'Bu güzergahta otobüs veya hat yok. Yürüyüş daha uygun.',
			'routeMap.transitWalkTo' => ({required Object stop}) => 'Yürü: ${stop}',
			'routeMap.transitRide' => ({required Object line, required Object from, required Object to}) => '${line} · ${from} → ${to}',
			'routeMap.transitWalkDest' => 'İn, hedefe yürü',
			'routeMap.transitBoard' => 'Biniş durağı',
			'routeMap.modeWalk' => 'Yürüyüş',
			'routeMap.modeTransit' => 'Toplu taşıma',
			'routeMap.modeDrive' => 'Araba',
			'routeMap.modeBike' => 'Bisiklet',
			'location.requiredTitle' => 'Konum gerekli',
			'location.failedTitle' => 'Konum alınamadı',
			'location.manualTitle' => 'Şehir veya ilçe',
			'location.manualHint' => 'Örn. Antalya, Muratpaşa',
			'location.enterManually' => 'Manuel gir',
			'location.openSettings' => 'Ayarlara git',
			'location.settingsRequired.serviceDisabled' => 'NavGo çalışmak için cihazında konum servisi açık olmalı. Lütfen ayarlardan konumu aç.',
			'location.settingsRequired.permissionDenied' => 'NavGo çalışmak için konum izni gerekli. Lütfen izin ver.',
			'location.settingsRequired.permissionDeniedForever' => 'NavGo çalışmak için konum izni gerekli. Ayarlardan NavGo için konumu aç.',
			'location.settingsRequired.fallback' => 'NavGo çalışmak için konum izni gerekli. Ayarlardan konumu aç.',
			'location.retryMessage' => 'Konum alınamadı. Tekrar deneyebilir veya şehri elle yazabilirsin.',
			'location.manualEntry.timeout' => 'Konum alınamadı. Şehir veya ilçe yazarak devam edebilirsin.',
			'location.manualEntry.geocodeFailed' => 'Konumun alındı ama adres çözülemedi (ağ sorunu olabilir). Şehir veya ilçe yazarak devam edebilirsin.',
			'location.manualEntry.unknown' => 'Bağlantı sorunu nedeniyle konum çözülemedi. Şehir veya ilçe yazarak devam edebilirsin.',
			'location.manualEntry.noPermission' => 'Konum izni olmadan da şehir veya ilçe yazarak devam edebilirsin.',
			'location.manualEntry.fallback' => 'Konum çözülemedi. Şehir veya ilçe yazarak devam edebilirsin.',
			'profile.title' => 'Profile',
			'profile.noLocation' => 'Konum yok',
			'profile.labelLocation' => 'Konum',
			'profile.labelTempo' => 'Tempo',
			'profile.labelInterests' => 'İlgi',
			'profile.labelGroup' => 'Grup',
			'profile.labelTransport' => 'Taşıt',
			'profile.labelLanguage' => 'Dil',
			'profile.resetOnboarding' => 'Onboarding’i sıfırla',
			'explore.title' => 'Explore',
			'explore.subtitle' => 'Herhangi bir şehir veya bölge için fikirler. Plan sekmesinde destinasyonunu seç.',
			'explore.destinations.istanbul.name' => 'İstanbul',
			'explore.destinations.istanbul.blurb' => 'Tarihi yarımada · Boğaz · kahve',
			'explore.destinations.cappadocia.name' => 'Kapadokya',
			'explore.destinations.cappadocia.blurb' => 'Vadiler · gün doğumu · yürüyüş',
			'explore.destinations.rome.name' => 'Roma',
			'explore.destinations.rome.blurb' => 'Forum · Trastevere · gelato',
			'explore.destinations.lisbon.name' => 'Lizbon',
			'explore.destinations.lisbon.blurb' => 'Alfama · tramvay · miradouro',
			'explore.destinations.tokyo.name' => 'Tokyo',
			'explore.destinations.tokyo.blurb' => 'Mahalleler · tapınak · ramen',
			'explore.destinations.barcelona.name' => 'Barselona',
			'explore.destinations.barcelona.blurb' => 'Gotik mahalle · plaj · tapas',
			'trips.title' => 'Trips',
			'trips.subtitle' => 'Kaydettiğin gün planları burada listelenir.',
			'trips.emptyTitle' => 'Henüz kayıtlı trip yok',
			'trips.emptyBody' => 'Plan sekmesinden bir gün oluştur, sonra burada görünecek.',
			'splash.tagline' => 'Gerçek yerlerle gün planı',
			'splash.continueAction' => 'Devam',
			_ => null,
		};
	}
}
