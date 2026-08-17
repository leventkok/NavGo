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
class TranslationsRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$ru common = _Translations$common$ru._(_root);
	@override late final _Translations$shell$ru shell = _Translations$shell$ru._(_root);
	@override late final _Translations$onboarding$ru onboarding = _Translations$onboarding$ru._(_root);
	@override late final _Translations$plan$ru plan = _Translations$plan$ru._(_root);
	@override late final _Translations$location$ru location = _Translations$location$ru._(_root);
	@override late final _Translations$profile$ru profile = _Translations$profile$ru._(_root);
	@override late final _Translations$explore$ru explore = _Translations$explore$ru._(_root);
	@override late final _Translations$trips$ru trips = _Translations$trips$ru._(_root);
	@override late final _Translations$splash$ru splash = _Translations$splash$ru._(_root);
}

// Path: common
class _Translations$common$ru extends Translations$common$tr {
	_Translations$common$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get brand => 'NavGo';
	@override String get cancel => 'Отмена';
	@override String get continueAction => 'Продолжить';
	@override String get ok => 'OK';
	@override String get retry => 'Повторить';
	@override String get back => 'Назад';
	@override String get emDash => '—';
	@override String get defaultTravelerName => 'Путешественник';
	@override late final _Translations$common$tempo$ru tempo = _Translations$common$tempo$ru._(_root);
	@override late final _Translations$common$group$ru group = _Translations$common$group$ru._(_root);
	@override late final _Translations$common$transport$ru transport = _Translations$common$transport$ru._(_root);
	@override late final _Translations$common$interest$ru interest = _Translations$common$interest$ru._(_root);
}

// Path: shell
class _Translations$shell$ru extends Translations$shell$tr {
	_Translations$shell$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get tabPlan => 'План';
	@override String get tabTrips => 'Поездки';
	@override String get tabExplore => 'Обзор';
	@override String get tabProfile => 'Профиль';
}

// Path: onboarding
class _Translations$onboarding$ru extends Translations$onboarding$tr {
	_Translations$onboarding$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String stepProgress({required Object current, required Object total}) => '${current}/${total}';
	@override String get continueAction => 'Продолжить';
	@override String get enterApp => 'Войти в NavGo';
	@override String get resolvingLocation => 'Определяем местоположение…';
	@override String get cityRequiredSnack => 'Нужен город или район';
	@override late final _Translations$onboarding$welcome$ru welcome = _Translations$onboarding$welcome$ru._(_root);
	@override late final _Translations$onboarding$name$ru name = _Translations$onboarding$name$ru._(_root);
	@override late final _Translations$onboarding$tempo$ru tempo = _Translations$onboarding$tempo$ru._(_root);
	@override late final _Translations$onboarding$interests$ru interests = _Translations$onboarding$interests$ru._(_root);
	@override late final _Translations$onboarding$group$ru group = _Translations$onboarding$group$ru._(_root);
	@override late final _Translations$onboarding$transport$ru transport = _Translations$onboarding$transport$ru._(_root);
}

// Path: plan
class _Translations$plan$ru extends Translations$plan$tr {
	_Translations$plan$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get selectLocation => 'Выбрать местоположение';
	@override String get quickStart => 'Маршруты для вас';
	@override String get quickStartNeedLocation => 'Выберите местоположение, затем откройте маршрут.';
	@override String get quickStartBody => 'Выберите настроение, посмотрите остановки, затем соберите день.';
	@override String get defaultPlanTitle => 'План дня';
	@override String routeSummary({required Object km, required Object mins, required Object provider}) => '${km} км · ~${mins} мин · ${provider}';
	@override String get greetingMorning => 'Доброе утро';
	@override String get greetingAfternoon => 'Добрый день';
	@override String get greetingEvening => 'Добрый вечер';
	@override String greetingLine({required Object greeting}) => '${greeting},';
	@override String get heroBadge => 'Сегодня';
	@override String get heroTitle => 'Один день. Реальные места.';
	@override String get heroBody => 'Выберите готовый маршрут или соберите свой — остановки из реальных мест.';
	@override String get heroCta => 'Спланировать новый день';
	@override String get errorTitle => 'Не удалось создать план';
	@override String get tipBanner => 'Для прогулок лучше прохладные часы — днём тень и короткие паузы комфортнее.';
	@override String get openInGoogleMaps => 'Открыть в Google Maps';
	@override String get backToHome => 'На главную';
	@override String get statusSigningIn => 'Вход…';
	@override String get statusParsingIntent => 'Разбираем запрос с LLM…';
	@override String get statusSearchingPlaces => 'Ищем места…';
	@override String get statusSearchingPlacesTemplate => 'Ищем места по шаблону…';
	@override String get statusPickingStops => 'Выбираем остановки с LLM…';
	@override String get statusBuildingRoute => 'Строим маршрут…';
	@override String get statusReady => 'План готов';
	@override String get errorDestinationRequired => 'Нужен пункт назначения';
	@override String get errorTimeout => 'Время ожидания истекло. Проверьте соединение и попробуйте снова.';
	@override String get errorConnection => 'Не удалось подключиться к серверу. Убедитесь, что API работает.';
	@override String get errorAuth => 'Не удалось войти. Попробуйте ещё раз.';
	@override String get errorUnprocessable => 'Эти места не подходят для маршрута. Попробуйте другой тип.';
	@override String get errorServer => 'Ошибка сервера. Попробуйте чуть позже.';
	@override String get errorNotEnoughPlaces => 'В этом районе недостаточно мест. Попробуйте другой пункт назначения или тип маршрута.';
	@override String get errorGeneric => 'Не удалось создать план. Попробуйте ещё раз.';
	@override late final _Translations$plan$startSheet$ru startSheet = _Translations$plan$startSheet$ru._(_root);
	@override late final _Translations$plan$chat$ru chat = _Translations$plan$chat$ru._(_root);
	@override late final _Translations$plan$suggestion$ru suggestion = _Translations$plan$suggestion$ru._(_root);
	@override String get suggestionsLoading => 'Подбираем маршруты…';
	@override late final _Translations$plan$preview$ru preview = _Translations$plan$preview$ru._(_root);
	@override late final _Translations$plan$routelistFallback$ru routelistFallback = _Translations$plan$routelistFallback$ru._(_root);
}

// Path: location
class _Translations$location$ru extends Translations$location$tr {
	_Translations$location$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get requiredTitle => 'Нужно местоположение';
	@override String get failedTitle => 'Не удалось определить местоположение';
	@override String get manualTitle => 'Город или район';
	@override String get manualHint => 'Напр. Анталья, Муратпаша';
	@override String get enterManually => 'Ввести вручную';
	@override String get openSettings => 'Открыть настройки';
	@override late final _Translations$location$settingsRequired$ru settingsRequired = _Translations$location$settingsRequired$ru._(_root);
	@override String get retryMessage => 'Не удалось определить местоположение. Можно повторить или ввести город.';
	@override late final _Translations$location$manualEntry$ru manualEntry = _Translations$location$manualEntry$ru._(_root);
}

// Path: profile
class _Translations$profile$ru extends Translations$profile$tr {
	_Translations$profile$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Профиль';
	@override String get noLocation => 'Нет местоположения';
	@override String get labelLocation => 'Местоположение';
	@override String get labelTempo => 'Темп';
	@override String get labelInterests => 'Интересы';
	@override String get labelGroup => 'Группа';
	@override String get labelTransport => 'Транспорт';
	@override String get labelLanguage => 'Язык';
	@override String get resetOnboarding => 'Сбросить онбординг';
}

// Path: explore
class _Translations$explore$ru extends Translations$explore$tr {
	_Translations$explore$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Обзор';
	@override String get subtitle => 'Идеи для любого города или региона. Пункт назначения выберите во вкладке «План».';
	@override late final _Translations$explore$destinations$ru destinations = _Translations$explore$destinations$ru._(_root);
}

// Path: trips
class _Translations$trips$ru extends Translations$trips$tr {
	_Translations$trips$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Поездки';
	@override String get subtitle => 'Сохранённые планы дня появятся здесь.';
	@override String get emptyTitle => 'Пока нет сохранённых поездок';
	@override String get emptyBody => 'Создайте день во вкладке «План» — он появится здесь.';
}

// Path: splash
class _Translations$splash$ru extends Translations$splash$tr {
	_Translations$splash$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Планы дня по реальным местам';
	@override String get continueAction => 'Продолжить';
}

// Path: common.tempo
class _Translations$common$tempo$ru extends Translations$common$tempo$tr {
	_Translations$common$tempo$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get calm => 'Спокойный';
	@override String get balanced => 'Сбалансированный';
	@override String get packed => 'Насыщенный';
}

// Path: common.group
class _Translations$common$group$ru extends Translations$common$group$tr {
	_Translations$common$group$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get solo => 'Один';
	@override String get couple => 'Пара';
	@override String get friends => 'Друзья';
	@override String get family => 'Семья';
}

// Path: common.transport
class _Translations$common$transport$ru extends Translations$common$transport$tr {
	_Translations$common$transport$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get walk => 'Пешком';
	@override String get transit => 'Общественный транспорт';
	@override String get drive => 'На машине';
	@override String get bike => 'Велосипед';
}

// Path: common.interest
class _Translations$common$interest$ru extends Translations$common$interest$tr {
	_Translations$common$interest$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get history => 'История';
	@override String get food => 'Еда';
	@override String get nature => 'Природа';
	@override String get art => 'Искусство';
	@override String get shopping => 'Шопинг';
}

// Path: onboarding.welcome
class _Translations$onboarding$welcome$ru extends Translations$onboarding$welcome$tr {
	_Translations$onboarding$welcome$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Планируйте день по реальным местам';
	@override String get body => 'NavGo учитывает ваше местоположение и предпочтения и строит маршрут дня из реальных мест.';
}

// Path: onboarding.name
class _Translations$onboarding$name$ru extends Translations$onboarding$name$tr {
	_Translations$onboarding$name$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Как к вам обращаться?';
	@override String get body => 'Достаточно короткого имени для профиля.';
	@override String get hint => 'Ваше имя';
	@override String get errorRequired => 'Нужно имя, чтобы мы знали, как к вам обращаться';
}

// Path: onboarding.tempo
class _Translations$onboarding$tempo$ru extends Translations$onboarding$tempo$tr {
	_Translations$onboarding$tempo$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Темп дня';
	@override String get body => 'Сколько остановок вы хотите — независимо от плотности мест.';
	@override String get calmSubtitle => 'Меньше остановок · больше пауз';
	@override String get balancedSubtitle => 'Наслаждайтесь днём без спешки';
	@override String get packedSubtitle => 'Успеть как можно больше';
}

// Path: onboarding.interests
class _Translations$onboarding$interests$ru extends Translations$onboarding$interests$tr {
	_Translations$onboarding$interests$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ваши интересы';
	@override String get body => 'Можно выбрать несколько. Поиск мест подстроится под них.';
	@override String get errorMinOne => 'Выберите хотя бы один интерес, чтобы мы могли предложить подходящие места';
}

// Path: onboarding.group
class _Translations$onboarding$group$ru extends Translations$onboarding$group$tr {
	_Translations$onboarding$group$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'С кем вы путешествуете?';
	@override String get body => 'Выбор влияет на маршрут и остановки.';
	@override String get soloSubtitle => 'В своём темпе';
	@override String get coupleSubtitle => 'Маршруты для двоих';
	@override String get friendsSubtitle => 'Места, которыми легко поделиться';
	@override String get familySubtitle => 'Для семьи; бары и пабы не предлагаем';
}

// Path: onboarding.transport
class _Translations$onboarding$transport$ru extends Translations$onboarding$transport$tr {
	_Translations$onboarding$transport$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Как будете передвигаться?';
	@override String get body => 'Выберите способ перемещения на день — маршрут подстроится.';
	@override String get walkSubtitle => 'Пешком';
	@override String get transitSubtitle => 'Метро · автобус · трамвай';
	@override String get driveSubtitle => 'На машине';
	@override String get bikeSubtitle => 'Спокойный темп';
}

// Path: plan.startSheet
class _Translations$plan$startSheet$ru extends Translations$plan$startSheet$tr {
	_Translations$plan$startSheet$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Куда пойдём?';
	@override String get body => 'Используйте район из геолокации или введите другой пункт назначения.';
	@override String get destinationLabel => 'Пункт назначения';
	@override String get destinationHint => 'Напр. Кадыкёй, Стамбул';
	@override String get useMyLocation => 'Моё местоположение';
	@override String get resolvingLocation => 'Определяем местоположение…';
	@override String get openInChat => 'Открыть чат';
	@override String get areaRequiredSnack => 'Сначала введите город или район';
}

// Path: plan.chat
class _Translations$plan$chat$ru extends Translations$plan$chat$tr {
	_Translations$plan$chat$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Планировать в чате';
	@override String get emptyTitle => 'Опишите день без геолокации';
	@override String get emptyBody => 'Напишите город, темп и что хотите увидеть — доступ к локации не нужен.';
	@override String get inputHint => 'Что хотите делать сегодня?';
	@override String get replyHint => 'Как изменить этот маршрут?';
	@override String get reply => 'Ответить';
	@override String get more => 'Ещё';
	@override String get quoting => 'Ответ на маршрут';
	@override String get tapToPreview => 'Нажмите для предпросмотра';
	@override String get error => 'Не удалось предложить маршрут. Попробуйте ещё раз.';
	@override String get errorAuth => 'Модель отклонила запрос (ключ LLM). Сверьте ключ Colab с .env.';
	@override String get retry => 'Повторить';
	@override String get holdToSpeak => 'Нажмите, чтобы говорить';
	@override String get listening => 'Запись… нажмите ещё раз, чтобы отправить';
	@override String get voiceUnavailable => 'Микрофон или распознавание речи недоступны.';
	@override String get voiceEmpty => 'Речь не распознана. Нажмите ещё раз.';
	@override String get replayVoice => 'Слушать снова';
	@override late final _Translations$plan$chat$thinking$ru thinking = _Translations$plan$chat$thinking$ru._(_root);
}

// Path: plan.suggestion
class _Translations$plan$suggestion$ru extends Translations$plan$suggestion$tr {
	_Translations$plan$suggestion$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$plan$suggestion$historicCenter$ru historicCenter = _Translations$plan$suggestion$historicCenter$ru._(_root);
	@override late final _Translations$plan$suggestion$waterfront$ru waterfront = _Translations$plan$suggestion$waterfront$ru._(_root);
	@override late final _Translations$plan$suggestion$coffeeRoute$ru coffeeRoute = _Translations$plan$suggestion$coffeeRoute$ru._(_root);
	@override late final _Translations$plan$suggestion$museumCulture$ru museumCulture = _Translations$plan$suggestion$museumCulture$ru._(_root);
	@override late final _Translations$plan$suggestion$parksLakes$ru parksLakes = _Translations$plan$suggestion$parksLakes$ru._(_root);
}

// Path: plan.preview
class _Translations$plan$preview$ru extends Translations$plan$preview$tr {
	_Translations$plan$preview$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get buildRoute => 'Собрать маршрут';
	@override String get dismiss => 'Не сейчас';
	@override String get planAnyway => 'Всё равно спланировать';
	@override String get failed => 'Не удалось загрузить остановки. Повторите или спланируйте без предпросмотра.';
	@override String get empty => 'Для этого настроения недостаточно мест.';
}

// Path: plan.routelistFallback
class _Translations$plan$routelistFallback$ru extends Translations$plan$routelistFallback$tr {
	_Translations$plan$routelistFallback$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$plan$routelistFallback$firstDay$ru firstDay = _Translations$plan$routelistFallback$firstDay$ru._(_root);
	@override late final _Translations$plan$routelistFallback$slow$ru slow = _Translations$plan$routelistFallback$slow$ru._(_root);
	@override late final _Translations$plan$routelistFallback$culture$ru culture = _Translations$plan$routelistFallback$culture$ru._(_root);
	@override late final _Translations$plan$routelistFallback$food$ru food = _Translations$plan$routelistFallback$food$ru._(_root);
}

// Path: location.settingsRequired
class _Translations$location$settingsRequired$ru extends Translations$location$settingsRequired$tr {
	_Translations$location$settingsRequired$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get serviceDisabled => 'NavGo нужна служба геолокации. Включите её в настройках.';
	@override String get permissionDenied => 'NavGo нужно разрешение на геолокацию. Пожалуйста, разрешите.';
	@override String get permissionDeniedForever => 'NavGo нужно разрешение на геолокацию. Включите его для NavGo в настройках.';
	@override String get fallback => 'NavGo нужно разрешение на геолокацию. Включите его в настройках.';
}

// Path: location.manualEntry
class _Translations$location$manualEntry$ru extends Translations$location$manualEntry$tr {
	_Translations$location$manualEntry$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get timeout => 'Не удалось определить местоположение. Можно продолжить, введя город или район.';
	@override String get geocodeFailed => 'Координаты получены, но адрес не удалось распознать (возможна проблема с сетью). Введите город или район.';
	@override String get unknown => 'Из‑за проблемы с соединением местоположение не определено. Введите город или район.';
	@override String get noPermission => 'Без разрешения на геолокацию тоже можно продолжить, введя город или район.';
	@override String get fallback => 'Не удалось определить местоположение. Введите город или район.';
}

// Path: explore.destinations
class _Translations$explore$destinations$ru extends Translations$explore$destinations$tr {
	_Translations$explore$destinations$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$destinations$istanbul$ru istanbul = _Translations$explore$destinations$istanbul$ru._(_root);
	@override late final _Translations$explore$destinations$cappadocia$ru cappadocia = _Translations$explore$destinations$cappadocia$ru._(_root);
	@override late final _Translations$explore$destinations$rome$ru rome = _Translations$explore$destinations$rome$ru._(_root);
	@override late final _Translations$explore$destinations$lisbon$ru lisbon = _Translations$explore$destinations$lisbon$ru._(_root);
	@override late final _Translations$explore$destinations$tokyo$ru tokyo = _Translations$explore$destinations$tokyo$ru._(_root);
	@override late final _Translations$explore$destinations$barcelona$ru barcelona = _Translations$explore$destinations$barcelona$ru._(_root);
}

// Path: plan.chat.thinking
class _Translations$plan$chat$thinking$ru extends Translations$plan$chat$thinking$tr {
	_Translations$plan$chat$thinking$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get s1 => 'Думаю…';
	@override String get s2 => 'Выбираю настроение…';
	@override String get s3 => 'Собираю маршрут…';
	@override String get s4 => 'Упрощаю остановки…';
	@override String get s5 => 'Сверяю с городом…';
}

// Path: plan.suggestion.historicCenter
class _Translations$plan$suggestion$historicCenter$ru extends Translations$plan$suggestion$historicCenter$tr {
	_Translations$plan$suggestion$historicCenter$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Исторический центр';
	@override String get subtitle => 'Старые улицы · площадь · кофе';
}

// Path: plan.suggestion.waterfront
class _Translations$plan$suggestion$waterfront$ru extends Translations$plan$suggestion$waterfront$tr {
	_Translations$plan$suggestion$waterfront$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Набережная / порт';
	@override String get subtitle => 'У воды · прогулка · виды';
}

// Path: plan.suggestion.coffeeRoute
class _Translations$plan$suggestion$coffeeRoute$ru extends Translations$plan$suggestion$coffeeRoute$tr {
	_Translations$plan$suggestion$coffeeRoute$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Кофейный маршрут';
	@override String get subtitle => 'Три остановки · спокойный темп';
}

// Path: plan.suggestion.museumCulture
class _Translations$plan$suggestion$museumCulture$ru extends Translations$plan$suggestion$museumCulture$tr {
	_Translations$plan$suggestion$museumCulture$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Музеи и культура';
	@override String get subtitle => 'Музей · галерея · памятник';
}

// Path: plan.suggestion.parksLakes
class _Translations$plan$suggestion$parksLakes$ru extends Translations$plan$suggestion$parksLakes$tr {
	_Translations$plan$suggestion$parksLakes$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Парки и озёра';
	@override String get subtitle => 'Зелень · прогулка · отдых';
}

// Path: plan.routelistFallback.firstDay
class _Translations$plan$routelistFallback$firstDay$ru extends Translations$plan$routelistFallback$firstDay$tr {
	_Translations$plan$routelistFallback$firstDay$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Впервые в городе?';
	@override String get subtitle => 'Быстрый круг по знаковым местам';
}

// Path: plan.routelistFallback.slow
class _Translations$plan$routelistFallback$slow$ru extends Translations$plan$routelistFallback$slow$tr {
	_Translations$plan$routelistFallback$slow$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Без спешки';
	@override String get subtitle => 'Кофе, парк и короткая прогулка';
}

// Path: plan.routelistFallback.culture
class _Translations$plan$routelistFallback$culture$ru extends Translations$plan$routelistFallback$culture$tr {
	_Translations$plan$routelistFallback$culture$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Послушать историю';
	@override String get subtitle => 'Музеи, памятники, старые улицы';
}

// Path: plan.routelistFallback.food
class _Translations$plan$routelistFallback$food$ru extends Translations$plan$routelistFallback$food$tr {
	_Translations$plan$routelistFallback$food$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Вкусы города';
	@override String get subtitle => 'Рынок, локальная еда, уличные закуски';
}

// Path: explore.destinations.istanbul
class _Translations$explore$destinations$istanbul$ru extends Translations$explore$destinations$istanbul$tr {
	_Translations$explore$destinations$istanbul$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get name => 'Стамбул';
	@override String get blurb => 'Исторический полуостров · Босфор · кофе';
}

// Path: explore.destinations.cappadocia
class _Translations$explore$destinations$cappadocia$ru extends Translations$explore$destinations$cappadocia$tr {
	_Translations$explore$destinations$cappadocia$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get name => 'Каппадокия';
	@override String get blurb => 'Долины · рассвет · прогулки';
}

// Path: explore.destinations.rome
class _Translations$explore$destinations$rome$ru extends Translations$explore$destinations$rome$tr {
	_Translations$explore$destinations$rome$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get name => 'Рим';
	@override String get blurb => 'Форум · Трастевере · джелато';
}

// Path: explore.destinations.lisbon
class _Translations$explore$destinations$lisbon$ru extends Translations$explore$destinations$lisbon$tr {
	_Translations$explore$destinations$lisbon$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get name => 'Лиссабон';
	@override String get blurb => 'Алфама · трамвай · смотровые';
}

// Path: explore.destinations.tokyo
class _Translations$explore$destinations$tokyo$ru extends Translations$explore$destinations$tokyo$tr {
	_Translations$explore$destinations$tokyo$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get name => 'Токио';
	@override String get blurb => 'Районы · храмы · рамен';
}

// Path: explore.destinations.barcelona
class _Translations$explore$destinations$barcelona$ru extends Translations$explore$destinations$barcelona$tr {
	_Translations$explore$destinations$barcelona$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get name => 'Барселона';
	@override String get blurb => 'Готический квартал · пляж · тапас';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.brand' => 'NavGo',
			'common.cancel' => 'Отмена',
			'common.continueAction' => 'Продолжить',
			'common.ok' => 'OK',
			'common.retry' => 'Повторить',
			'common.back' => 'Назад',
			'common.emDash' => '—',
			'common.defaultTravelerName' => 'Путешественник',
			'common.tempo.calm' => 'Спокойный',
			'common.tempo.balanced' => 'Сбалансированный',
			'common.tempo.packed' => 'Насыщенный',
			'common.group.solo' => 'Один',
			'common.group.couple' => 'Пара',
			'common.group.friends' => 'Друзья',
			'common.group.family' => 'Семья',
			'common.transport.walk' => 'Пешком',
			'common.transport.transit' => 'Общественный транспорт',
			'common.transport.drive' => 'На машине',
			'common.transport.bike' => 'Велосипед',
			'common.interest.history' => 'История',
			'common.interest.food' => 'Еда',
			'common.interest.nature' => 'Природа',
			'common.interest.art' => 'Искусство',
			'common.interest.shopping' => 'Шопинг',
			'shell.tabPlan' => 'План',
			'shell.tabTrips' => 'Поездки',
			'shell.tabExplore' => 'Обзор',
			'shell.tabProfile' => 'Профиль',
			'onboarding.stepProgress' => ({required Object current, required Object total}) => '${current}/${total}',
			'onboarding.continueAction' => 'Продолжить',
			'onboarding.enterApp' => 'Войти в NavGo',
			'onboarding.resolvingLocation' => 'Определяем местоположение…',
			'onboarding.cityRequiredSnack' => 'Нужен город или район',
			'onboarding.welcome.title' => 'Планируйте день по реальным местам',
			'onboarding.welcome.body' => 'NavGo учитывает ваше местоположение и предпочтения и строит маршрут дня из реальных мест.',
			'onboarding.name.title' => 'Как к вам обращаться?',
			'onboarding.name.body' => 'Достаточно короткого имени для профиля.',
			'onboarding.name.hint' => 'Ваше имя',
			'onboarding.name.errorRequired' => 'Нужно имя, чтобы мы знали, как к вам обращаться',
			'onboarding.tempo.title' => 'Темп дня',
			'onboarding.tempo.body' => 'Сколько остановок вы хотите — независимо от плотности мест.',
			'onboarding.tempo.calmSubtitle' => 'Меньше остановок · больше пауз',
			'onboarding.tempo.balancedSubtitle' => 'Наслаждайтесь днём без спешки',
			'onboarding.tempo.packedSubtitle' => 'Успеть как можно больше',
			'onboarding.interests.title' => 'Ваши интересы',
			'onboarding.interests.body' => 'Можно выбрать несколько. Поиск мест подстроится под них.',
			'onboarding.interests.errorMinOne' => 'Выберите хотя бы один интерес, чтобы мы могли предложить подходящие места',
			'onboarding.group.title' => 'С кем вы путешествуете?',
			'onboarding.group.body' => 'Выбор влияет на маршрут и остановки.',
			'onboarding.group.soloSubtitle' => 'В своём темпе',
			'onboarding.group.coupleSubtitle' => 'Маршруты для двоих',
			'onboarding.group.friendsSubtitle' => 'Места, которыми легко поделиться',
			'onboarding.group.familySubtitle' => 'Для семьи; бары и пабы не предлагаем',
			'onboarding.transport.title' => 'Как будете передвигаться?',
			'onboarding.transport.body' => 'Выберите способ перемещения на день — маршрут подстроится.',
			'onboarding.transport.walkSubtitle' => 'Пешком',
			'onboarding.transport.transitSubtitle' => 'Метро · автобус · трамвай',
			'onboarding.transport.driveSubtitle' => 'На машине',
			'onboarding.transport.bikeSubtitle' => 'Спокойный темп',
			'plan.selectLocation' => 'Выбрать местоположение',
			'plan.quickStart' => 'Маршруты для вас',
			'plan.quickStartNeedLocation' => 'Выберите местоположение, затем откройте маршрут.',
			'plan.quickStartBody' => 'Выберите настроение, посмотрите остановки, затем соберите день.',
			'plan.defaultPlanTitle' => 'План дня',
			'plan.routeSummary' => ({required Object km, required Object mins, required Object provider}) => '${km} км · ~${mins} мин · ${provider}',
			'plan.greetingMorning' => 'Доброе утро',
			'plan.greetingAfternoon' => 'Добрый день',
			'plan.greetingEvening' => 'Добрый вечер',
			'plan.greetingLine' => ({required Object greeting}) => '${greeting},',
			'plan.heroBadge' => 'Сегодня',
			'plan.heroTitle' => 'Один день. Реальные места.',
			'plan.heroBody' => 'Выберите готовый маршрут или соберите свой — остановки из реальных мест.',
			'plan.heroCta' => 'Спланировать новый день',
			'plan.errorTitle' => 'Не удалось создать план',
			'plan.tipBanner' => 'Для прогулок лучше прохладные часы — днём тень и короткие паузы комфортнее.',
			'plan.openInGoogleMaps' => 'Открыть в Google Maps',
			'plan.backToHome' => 'На главную',
			'plan.statusSigningIn' => 'Вход…',
			'plan.statusParsingIntent' => 'Разбираем запрос с LLM…',
			'plan.statusSearchingPlaces' => 'Ищем места…',
			'plan.statusSearchingPlacesTemplate' => 'Ищем места по шаблону…',
			'plan.statusPickingStops' => 'Выбираем остановки с LLM…',
			'plan.statusBuildingRoute' => 'Строим маршрут…',
			'plan.statusReady' => 'План готов',
			'plan.errorDestinationRequired' => 'Нужен пункт назначения',
			'plan.errorTimeout' => 'Время ожидания истекло. Проверьте соединение и попробуйте снова.',
			'plan.errorConnection' => 'Не удалось подключиться к серверу. Убедитесь, что API работает.',
			'plan.errorAuth' => 'Не удалось войти. Попробуйте ещё раз.',
			'plan.errorUnprocessable' => 'Эти места не подходят для маршрута. Попробуйте другой тип.',
			'plan.errorServer' => 'Ошибка сервера. Попробуйте чуть позже.',
			'plan.errorNotEnoughPlaces' => 'В этом районе недостаточно мест. Попробуйте другой пункт назначения или тип маршрута.',
			'plan.errorGeneric' => 'Не удалось создать план. Попробуйте ещё раз.',
			'plan.startSheet.title' => 'Куда пойдём?',
			'plan.startSheet.body' => 'Используйте район из геолокации или введите другой пункт назначения.',
			'plan.startSheet.destinationLabel' => 'Пункт назначения',
			'plan.startSheet.destinationHint' => 'Напр. Кадыкёй, Стамбул',
			'plan.startSheet.useMyLocation' => 'Моё местоположение',
			'plan.startSheet.resolvingLocation' => 'Определяем местоположение…',
			'plan.startSheet.openInChat' => 'Открыть чат',
			'plan.startSheet.areaRequiredSnack' => 'Сначала введите город или район',
			'plan.chat.title' => 'Планировать в чате',
			'plan.chat.emptyTitle' => 'Опишите день без геолокации',
			'plan.chat.emptyBody' => 'Напишите город, темп и что хотите увидеть — доступ к локации не нужен.',
			'plan.chat.inputHint' => 'Что хотите делать сегодня?',
			'plan.chat.replyHint' => 'Как изменить этот маршрут?',
			'plan.chat.reply' => 'Ответить',
			'plan.chat.more' => 'Ещё',
			'plan.chat.quoting' => 'Ответ на маршрут',
			'plan.chat.tapToPreview' => 'Нажмите для предпросмотра',
			'plan.chat.error' => 'Не удалось предложить маршрут. Попробуйте ещё раз.',
			'plan.chat.errorAuth' => 'Модель отклонила запрос (ключ LLM). Сверьте ключ Colab с .env.',
			'plan.chat.retry' => 'Повторить',
			'plan.chat.holdToSpeak' => 'Нажмите, чтобы говорить',
			'plan.chat.listening' => 'Запись… нажмите ещё раз, чтобы отправить',
			'plan.chat.voiceUnavailable' => 'Микрофон или распознавание речи недоступны.',
			'plan.chat.voiceEmpty' => 'Речь не распознана. Нажмите ещё раз.',
			'plan.chat.replayVoice' => 'Слушать снова',
			'plan.chat.thinking.s1' => 'Думаю…',
			'plan.chat.thinking.s2' => 'Выбираю настроение…',
			'plan.chat.thinking.s3' => 'Собираю маршрут…',
			'plan.chat.thinking.s4' => 'Упрощаю остановки…',
			'plan.chat.thinking.s5' => 'Сверяю с городом…',
			'plan.suggestion.historicCenter.title' => 'Исторический центр',
			'plan.suggestion.historicCenter.subtitle' => 'Старые улицы · площадь · кофе',
			'plan.suggestion.waterfront.title' => 'Набережная / порт',
			'plan.suggestion.waterfront.subtitle' => 'У воды · прогулка · виды',
			'plan.suggestion.coffeeRoute.title' => 'Кофейный маршрут',
			'plan.suggestion.coffeeRoute.subtitle' => 'Три остановки · спокойный темп',
			'plan.suggestion.museumCulture.title' => 'Музеи и культура',
			'plan.suggestion.museumCulture.subtitle' => 'Музей · галерея · памятник',
			'plan.suggestion.parksLakes.title' => 'Парки и озёра',
			'plan.suggestion.parksLakes.subtitle' => 'Зелень · прогулка · отдых',
			'plan.suggestionsLoading' => 'Подбираем маршруты…',
			'plan.preview.buildRoute' => 'Собрать маршрут',
			'plan.preview.dismiss' => 'Не сейчас',
			'plan.preview.planAnyway' => 'Всё равно спланировать',
			'plan.preview.failed' => 'Не удалось загрузить остановки. Повторите или спланируйте без предпросмотра.',
			'plan.preview.empty' => 'Для этого настроения недостаточно мест.',
			'plan.routelistFallback.firstDay.title' => 'Впервые в городе?',
			'plan.routelistFallback.firstDay.subtitle' => 'Быстрый круг по знаковым местам',
			'plan.routelistFallback.slow.title' => 'Без спешки',
			'plan.routelistFallback.slow.subtitle' => 'Кофе, парк и короткая прогулка',
			'plan.routelistFallback.culture.title' => 'Послушать историю',
			'plan.routelistFallback.culture.subtitle' => 'Музеи, памятники, старые улицы',
			'plan.routelistFallback.food.title' => 'Вкусы города',
			'plan.routelistFallback.food.subtitle' => 'Рынок, локальная еда, уличные закуски',
			'location.requiredTitle' => 'Нужно местоположение',
			'location.failedTitle' => 'Не удалось определить местоположение',
			'location.manualTitle' => 'Город или район',
			'location.manualHint' => 'Напр. Анталья, Муратпаша',
			'location.enterManually' => 'Ввести вручную',
			'location.openSettings' => 'Открыть настройки',
			'location.settingsRequired.serviceDisabled' => 'NavGo нужна служба геолокации. Включите её в настройках.',
			'location.settingsRequired.permissionDenied' => 'NavGo нужно разрешение на геолокацию. Пожалуйста, разрешите.',
			'location.settingsRequired.permissionDeniedForever' => 'NavGo нужно разрешение на геолокацию. Включите его для NavGo в настройках.',
			'location.settingsRequired.fallback' => 'NavGo нужно разрешение на геолокацию. Включите его в настройках.',
			'location.retryMessage' => 'Не удалось определить местоположение. Можно повторить или ввести город.',
			'location.manualEntry.timeout' => 'Не удалось определить местоположение. Можно продолжить, введя город или район.',
			'location.manualEntry.geocodeFailed' => 'Координаты получены, но адрес не удалось распознать (возможна проблема с сетью). Введите город или район.',
			'location.manualEntry.unknown' => 'Из‑за проблемы с соединением местоположение не определено. Введите город или район.',
			'location.manualEntry.noPermission' => 'Без разрешения на геолокацию тоже можно продолжить, введя город или район.',
			'location.manualEntry.fallback' => 'Не удалось определить местоположение. Введите город или район.',
			'profile.title' => 'Профиль',
			'profile.noLocation' => 'Нет местоположения',
			'profile.labelLocation' => 'Местоположение',
			'profile.labelTempo' => 'Темп',
			'profile.labelInterests' => 'Интересы',
			'profile.labelGroup' => 'Группа',
			'profile.labelTransport' => 'Транспорт',
			'profile.labelLanguage' => 'Язык',
			'profile.resetOnboarding' => 'Сбросить онбординг',
			'explore.title' => 'Обзор',
			'explore.subtitle' => 'Идеи для любого города или региона. Пункт назначения выберите во вкладке «План».',
			'explore.destinations.istanbul.name' => 'Стамбул',
			'explore.destinations.istanbul.blurb' => 'Исторический полуостров · Босфор · кофе',
			'explore.destinations.cappadocia.name' => 'Каппадокия',
			'explore.destinations.cappadocia.blurb' => 'Долины · рассвет · прогулки',
			'explore.destinations.rome.name' => 'Рим',
			'explore.destinations.rome.blurb' => 'Форум · Трастевере · джелато',
			'explore.destinations.lisbon.name' => 'Лиссабон',
			'explore.destinations.lisbon.blurb' => 'Алфама · трамвай · смотровые',
			'explore.destinations.tokyo.name' => 'Токио',
			'explore.destinations.tokyo.blurb' => 'Районы · храмы · рамен',
			'explore.destinations.barcelona.name' => 'Барселона',
			'explore.destinations.barcelona.blurb' => 'Готический квартал · пляж · тапас',
			'trips.title' => 'Поездки',
			'trips.subtitle' => 'Сохранённые планы дня появятся здесь.',
			'trips.emptyTitle' => 'Пока нет сохранённых поездок',
			'trips.emptyBody' => 'Создайте день во вкладке «План» — он появится здесь.',
			'splash.tagline' => 'Планы дня по реальным местам',
			'splash.continueAction' => 'Продолжить',
			_ => null,
		};
	}
}
