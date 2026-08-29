// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GroupSettingsTable extends GroupSettings
    with TableInfo<$GroupSettingsTable, GroupSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
      'term', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shareValueMeta =
      const VerificationMeta('shareValue');
  @override
  late final GeneratedColumn<double> shareValue = GeneratedColumn<double>(
      'share_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5000));
  static const VerificationMeta _socialFundPerMtgMeta =
      const VerificationMeta('socialFundPerMtg');
  @override
  late final GeneratedColumn<double> socialFundPerMtg = GeneratedColumn<double>(
      'social_fund_per_mtg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1000));
  static const VerificationMeta _interestRatePctMeta =
      const VerificationMeta('interestRatePct');
  @override
  late final GeneratedColumn<double> interestRatePct = GeneratedColumn<double>(
      'interest_rate_pct', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _loanMultiplierMeta =
      const VerificationMeta('loanMultiplier');
  @override
  late final GeneratedColumn<int> loanMultiplier = GeneratedColumn<int>(
      'loan_multiplier', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _maxRepaymentMonthsMeta =
      const VerificationMeta('maxRepaymentMonths');
  @override
  late final GeneratedColumn<int> maxRepaymentMonths = GeneratedColumn<int>(
      'max_repayment_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _requiredGuarantorsMeta =
      const VerificationMeta('requiredGuarantors');
  @override
  late final GeneratedColumn<int> requiredGuarantors = GeneratedColumn<int>(
      'required_guarantors', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _minSharesMeta =
      const VerificationMeta('minShares');
  @override
  late final GeneratedColumn<int> minShares = GeneratedColumn<int>(
      'min_shares', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _maxSharesMeta =
      const VerificationMeta('maxShares');
  @override
  late final GeneratedColumn<int> maxShares = GeneratedColumn<int>(
      'max_shares', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _cycleMonthsMeta =
      const VerificationMeta('cycleMonths');
  @override
  late final GeneratedColumn<int> cycleMonths = GeneratedColumn<int>(
      'cycle_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(12));
  static const VerificationMeta _cycleMonthsElapsedMeta =
      const VerificationMeta('cycleMonthsElapsed');
  @override
  late final GeneratedColumn<int> cycleMonthsElapsed = GeneratedColumn<int>(
      'cycle_months_elapsed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(6));
  static const VerificationMeta _meetingsHeldMeta =
      const VerificationMeta('meetingsHeld');
  @override
  late final GeneratedColumn<int> meetingsHeld = GeneratedColumn<int>(
      'meetings_held', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _interestEarnedMeta =
      const VerificationMeta('interestEarned');
  @override
  late final GeneratedColumn<double> interestEarned = GeneratedColumn<double>(
      'interest_earned', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _meetingExpenseMeta =
      const VerificationMeta('meetingExpense');
  @override
  late final GeneratedColumn<double> meetingExpense = GeneratedColumn<double>(
      'meeting_expense', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _otherExpenseMeta =
      const VerificationMeta('otherExpense');
  @override
  late final GeneratedColumn<double> otherExpense = GeneratedColumn<double>(
      'other_expense', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _openingCashMeta =
      const VerificationMeta('openingCash');
  @override
  late final GeneratedColumn<double> openingCash = GeneratedColumn<double>(
      'opening_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _openingSocialFundMeta =
      const VerificationMeta('openingSocialFund');
  @override
  late final GeneratedColumn<double> openingSocialFund =
      GeneratedColumn<double>('opening_social_fund', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _loanDurationMonthsMeta =
      const VerificationMeta('loanDurationMonths');
  @override
  late final GeneratedColumn<int> loanDurationMonths = GeneratedColumn<int>(
      'loan_duration_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _quorumPercentMeta =
      const VerificationMeta('quorumPercent');
  @override
  late final GeneratedColumn<int> quorumPercent = GeneratedColumn<int>(
      'quorum_percent', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(50));
  static const VerificationMeta _meetingFrequencyMeta =
      const VerificationMeta('meetingFrequency');
  @override
  late final GeneratedColumn<String> meetingFrequency = GeneratedColumn<String>(
      'meeting_frequency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('weekly'));
  static const VerificationMeta _meetingStartTimeMeta =
      const VerificationMeta('meetingStartTime');
  @override
  late final GeneratedColumn<String> meetingStartTime = GeneratedColumn<String>(
      'meeting_start_time', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('10:00'));
  static const VerificationMeta _meetingLocationMeta =
      const VerificationMeta('meetingLocation');
  @override
  late final GeneratedColumn<String> meetingLocation = GeneratedColumn<String>(
      'meeting_location', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _fineTypesMeta =
      const VerificationMeta('fineTypes');
  @override
  late final GeneratedColumn<String> fineTypes = GeneratedColumn<String>(
      'fine_types', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(kDefaultFineTypesJson));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        term,
        shareValue,
        socialFundPerMtg,
        interestRatePct,
        loanMultiplier,
        maxRepaymentMonths,
        requiredGuarantors,
        minShares,
        maxShares,
        cycleMonths,
        cycleMonthsElapsed,
        meetingsHeld,
        interestEarned,
        meetingExpense,
        otherExpense,
        openingCash,
        openingSocialFund,
        loanDurationMonths,
        quorumPercent,
        meetingFrequency,
        meetingStartTime,
        meetingLocation,
        fineTypes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_settings';
  @override
  VerificationContext validateIntegrity(Insertable<GroupSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
          _termMeta, term.isAcceptableOrUnknown(data['term']!, _termMeta));
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('share_value')) {
      context.handle(
          _shareValueMeta,
          shareValue.isAcceptableOrUnknown(
              data['share_value']!, _shareValueMeta));
    }
    if (data.containsKey('social_fund_per_mtg')) {
      context.handle(
          _socialFundPerMtgMeta,
          socialFundPerMtg.isAcceptableOrUnknown(
              data['social_fund_per_mtg']!, _socialFundPerMtgMeta));
    }
    if (data.containsKey('interest_rate_pct')) {
      context.handle(
          _interestRatePctMeta,
          interestRatePct.isAcceptableOrUnknown(
              data['interest_rate_pct']!, _interestRatePctMeta));
    }
    if (data.containsKey('loan_multiplier')) {
      context.handle(
          _loanMultiplierMeta,
          loanMultiplier.isAcceptableOrUnknown(
              data['loan_multiplier']!, _loanMultiplierMeta));
    }
    if (data.containsKey('max_repayment_months')) {
      context.handle(
          _maxRepaymentMonthsMeta,
          maxRepaymentMonths.isAcceptableOrUnknown(
              data['max_repayment_months']!, _maxRepaymentMonthsMeta));
    }
    if (data.containsKey('required_guarantors')) {
      context.handle(
          _requiredGuarantorsMeta,
          requiredGuarantors.isAcceptableOrUnknown(
              data['required_guarantors']!, _requiredGuarantorsMeta));
    }
    if (data.containsKey('min_shares')) {
      context.handle(_minSharesMeta,
          minShares.isAcceptableOrUnknown(data['min_shares']!, _minSharesMeta));
    }
    if (data.containsKey('max_shares')) {
      context.handle(_maxSharesMeta,
          maxShares.isAcceptableOrUnknown(data['max_shares']!, _maxSharesMeta));
    }
    if (data.containsKey('cycle_months')) {
      context.handle(
          _cycleMonthsMeta,
          cycleMonths.isAcceptableOrUnknown(
              data['cycle_months']!, _cycleMonthsMeta));
    }
    if (data.containsKey('cycle_months_elapsed')) {
      context.handle(
          _cycleMonthsElapsedMeta,
          cycleMonthsElapsed.isAcceptableOrUnknown(
              data['cycle_months_elapsed']!, _cycleMonthsElapsedMeta));
    }
    if (data.containsKey('meetings_held')) {
      context.handle(
          _meetingsHeldMeta,
          meetingsHeld.isAcceptableOrUnknown(
              data['meetings_held']!, _meetingsHeldMeta));
    }
    if (data.containsKey('interest_earned')) {
      context.handle(
          _interestEarnedMeta,
          interestEarned.isAcceptableOrUnknown(
              data['interest_earned']!, _interestEarnedMeta));
    }
    if (data.containsKey('meeting_expense')) {
      context.handle(
          _meetingExpenseMeta,
          meetingExpense.isAcceptableOrUnknown(
              data['meeting_expense']!, _meetingExpenseMeta));
    }
    if (data.containsKey('other_expense')) {
      context.handle(
          _otherExpenseMeta,
          otherExpense.isAcceptableOrUnknown(
              data['other_expense']!, _otherExpenseMeta));
    }
    if (data.containsKey('opening_cash')) {
      context.handle(
          _openingCashMeta,
          openingCash.isAcceptableOrUnknown(
              data['opening_cash']!, _openingCashMeta));
    }
    if (data.containsKey('opening_social_fund')) {
      context.handle(
          _openingSocialFundMeta,
          openingSocialFund.isAcceptableOrUnknown(
              data['opening_social_fund']!, _openingSocialFundMeta));
    }
    if (data.containsKey('loan_duration_months')) {
      context.handle(
          _loanDurationMonthsMeta,
          loanDurationMonths.isAcceptableOrUnknown(
              data['loan_duration_months']!, _loanDurationMonthsMeta));
    }
    if (data.containsKey('quorum_percent')) {
      context.handle(
          _quorumPercentMeta,
          quorumPercent.isAcceptableOrUnknown(
              data['quorum_percent']!, _quorumPercentMeta));
    }
    if (data.containsKey('meeting_frequency')) {
      context.handle(
          _meetingFrequencyMeta,
          meetingFrequency.isAcceptableOrUnknown(
              data['meeting_frequency']!, _meetingFrequencyMeta));
    }
    if (data.containsKey('meeting_start_time')) {
      context.handle(
          _meetingStartTimeMeta,
          meetingStartTime.isAcceptableOrUnknown(
              data['meeting_start_time']!, _meetingStartTimeMeta));
    }
    if (data.containsKey('meeting_location')) {
      context.handle(
          _meetingLocationMeta,
          meetingLocation.isAcceptableOrUnknown(
              data['meeting_location']!, _meetingLocationMeta));
    }
    if (data.containsKey('fine_types')) {
      context.handle(_fineTypesMeta,
          fineTypes.isAcceptableOrUnknown(data['fine_types']!, _fineTypesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      term: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}term'])!,
      shareValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}share_value'])!,
      socialFundPerMtg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}social_fund_per_mtg'])!,
      interestRatePct: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}interest_rate_pct'])!,
      loanMultiplier: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}loan_multiplier'])!,
      maxRepaymentMonths: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_repayment_months'])!,
      requiredGuarantors: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}required_guarantors'])!,
      minShares: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_shares'])!,
      maxShares: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_shares'])!,
      cycleMonths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cycle_months'])!,
      cycleMonthsElapsed: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}cycle_months_elapsed'])!,
      meetingsHeld: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meetings_held'])!,
      interestEarned: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}interest_earned'])!,
      meetingExpense: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}meeting_expense'])!,
      otherExpense: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}other_expense'])!,
      openingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}opening_cash'])!,
      openingSocialFund: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}opening_social_fund'])!,
      loanDurationMonths: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}loan_duration_months'])!,
      quorumPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quorum_percent'])!,
      meetingFrequency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}meeting_frequency'])!,
      meetingStartTime: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}meeting_start_time'])!,
      meetingLocation: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}meeting_location'])!,
      fineTypes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fine_types'])!,
    );
  }

  @override
  $GroupSettingsTable createAlias(String alias) {
    return $GroupSettingsTable(attachedDatabase, alias);
  }
}

class GroupSetting extends DataClass implements Insertable<GroupSetting> {
  final int id;
  final String name;
  final String term;
  final double shareValue;
  final double socialFundPerMtg;
  final double interestRatePct;
  final int loanMultiplier;
  final int maxRepaymentMonths;
  final int requiredGuarantors;
  final int minShares;
  final int maxShares;
  final int cycleMonths;
  final int cycleMonthsElapsed;
  final int meetingsHeld;
  final double interestEarned;
  final double meetingExpense;
  final double otherExpense;
  final double openingCash;
  final double openingSocialFund;
  final int loanDurationMonths;
  final int quorumPercent;
  final String meetingFrequency;
  final String meetingStartTime;
  final String meetingLocation;
  final String fineTypes;
  const GroupSetting(
      {required this.id,
      required this.name,
      required this.term,
      required this.shareValue,
      required this.socialFundPerMtg,
      required this.interestRatePct,
      required this.loanMultiplier,
      required this.maxRepaymentMonths,
      required this.requiredGuarantors,
      required this.minShares,
      required this.maxShares,
      required this.cycleMonths,
      required this.cycleMonthsElapsed,
      required this.meetingsHeld,
      required this.interestEarned,
      required this.meetingExpense,
      required this.otherExpense,
      required this.openingCash,
      required this.openingSocialFund,
      required this.loanDurationMonths,
      required this.quorumPercent,
      required this.meetingFrequency,
      required this.meetingStartTime,
      required this.meetingLocation,
      required this.fineTypes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['term'] = Variable<String>(term);
    map['share_value'] = Variable<double>(shareValue);
    map['social_fund_per_mtg'] = Variable<double>(socialFundPerMtg);
    map['interest_rate_pct'] = Variable<double>(interestRatePct);
    map['loan_multiplier'] = Variable<int>(loanMultiplier);
    map['max_repayment_months'] = Variable<int>(maxRepaymentMonths);
    map['required_guarantors'] = Variable<int>(requiredGuarantors);
    map['min_shares'] = Variable<int>(minShares);
    map['max_shares'] = Variable<int>(maxShares);
    map['cycle_months'] = Variable<int>(cycleMonths);
    map['cycle_months_elapsed'] = Variable<int>(cycleMonthsElapsed);
    map['meetings_held'] = Variable<int>(meetingsHeld);
    map['interest_earned'] = Variable<double>(interestEarned);
    map['meeting_expense'] = Variable<double>(meetingExpense);
    map['other_expense'] = Variable<double>(otherExpense);
    map['opening_cash'] = Variable<double>(openingCash);
    map['opening_social_fund'] = Variable<double>(openingSocialFund);
    map['loan_duration_months'] = Variable<int>(loanDurationMonths);
    map['quorum_percent'] = Variable<int>(quorumPercent);
    map['meeting_frequency'] = Variable<String>(meetingFrequency);
    map['meeting_start_time'] = Variable<String>(meetingStartTime);
    map['meeting_location'] = Variable<String>(meetingLocation);
    map['fine_types'] = Variable<String>(fineTypes);
    return map;
  }

  GroupSettingsCompanion toCompanion(bool nullToAbsent) {
    return GroupSettingsCompanion(
      id: Value(id),
      name: Value(name),
      term: Value(term),
      shareValue: Value(shareValue),
      socialFundPerMtg: Value(socialFundPerMtg),
      interestRatePct: Value(interestRatePct),
      loanMultiplier: Value(loanMultiplier),
      maxRepaymentMonths: Value(maxRepaymentMonths),
      requiredGuarantors: Value(requiredGuarantors),
      minShares: Value(minShares),
      maxShares: Value(maxShares),
      cycleMonths: Value(cycleMonths),
      cycleMonthsElapsed: Value(cycleMonthsElapsed),
      meetingsHeld: Value(meetingsHeld),
      interestEarned: Value(interestEarned),
      meetingExpense: Value(meetingExpense),
      otherExpense: Value(otherExpense),
      openingCash: Value(openingCash),
      openingSocialFund: Value(openingSocialFund),
      loanDurationMonths: Value(loanDurationMonths),
      quorumPercent: Value(quorumPercent),
      meetingFrequency: Value(meetingFrequency),
      meetingStartTime: Value(meetingStartTime),
      meetingLocation: Value(meetingLocation),
      fineTypes: Value(fineTypes),
    );
  }

  factory GroupSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupSetting(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      term: serializer.fromJson<String>(json['term']),
      shareValue: serializer.fromJson<double>(json['shareValue']),
      socialFundPerMtg: serializer.fromJson<double>(json['socialFundPerMtg']),
      interestRatePct: serializer.fromJson<double>(json['interestRatePct']),
      loanMultiplier: serializer.fromJson<int>(json['loanMultiplier']),
      maxRepaymentMonths: serializer.fromJson<int>(json['maxRepaymentMonths']),
      requiredGuarantors: serializer.fromJson<int>(json['requiredGuarantors']),
      minShares: serializer.fromJson<int>(json['minShares']),
      maxShares: serializer.fromJson<int>(json['maxShares']),
      cycleMonths: serializer.fromJson<int>(json['cycleMonths']),
      cycleMonthsElapsed: serializer.fromJson<int>(json['cycleMonthsElapsed']),
      meetingsHeld: serializer.fromJson<int>(json['meetingsHeld']),
      interestEarned: serializer.fromJson<double>(json['interestEarned']),
      meetingExpense: serializer.fromJson<double>(json['meetingExpense']),
      otherExpense: serializer.fromJson<double>(json['otherExpense']),
      openingCash: serializer.fromJson<double>(json['openingCash']),
      openingSocialFund: serializer.fromJson<double>(json['openingSocialFund']),
      loanDurationMonths: serializer.fromJson<int>(json['loanDurationMonths']),
      quorumPercent: serializer.fromJson<int>(json['quorumPercent']),
      meetingFrequency: serializer.fromJson<String>(json['meetingFrequency']),
      meetingStartTime: serializer.fromJson<String>(json['meetingStartTime']),
      meetingLocation: serializer.fromJson<String>(json['meetingLocation']),
      fineTypes: serializer.fromJson<String>(json['fineTypes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'term': serializer.toJson<String>(term),
      'shareValue': serializer.toJson<double>(shareValue),
      'socialFundPerMtg': serializer.toJson<double>(socialFundPerMtg),
      'interestRatePct': serializer.toJson<double>(interestRatePct),
      'loanMultiplier': serializer.toJson<int>(loanMultiplier),
      'maxRepaymentMonths': serializer.toJson<int>(maxRepaymentMonths),
      'requiredGuarantors': serializer.toJson<int>(requiredGuarantors),
      'minShares': serializer.toJson<int>(minShares),
      'maxShares': serializer.toJson<int>(maxShares),
      'cycleMonths': serializer.toJson<int>(cycleMonths),
      'cycleMonthsElapsed': serializer.toJson<int>(cycleMonthsElapsed),
      'meetingsHeld': serializer.toJson<int>(meetingsHeld),
      'interestEarned': serializer.toJson<double>(interestEarned),
      'meetingExpense': serializer.toJson<double>(meetingExpense),
      'otherExpense': serializer.toJson<double>(otherExpense),
      'openingCash': serializer.toJson<double>(openingCash),
      'openingSocialFund': serializer.toJson<double>(openingSocialFund),
      'loanDurationMonths': serializer.toJson<int>(loanDurationMonths),
      'quorumPercent': serializer.toJson<int>(quorumPercent),
      'meetingFrequency': serializer.toJson<String>(meetingFrequency),
      'meetingStartTime': serializer.toJson<String>(meetingStartTime),
      'meetingLocation': serializer.toJson<String>(meetingLocation),
      'fineTypes': serializer.toJson<String>(fineTypes),
    };
  }

  GroupSetting copyWith(
          {int? id,
          String? name,
          String? term,
          double? shareValue,
          double? socialFundPerMtg,
          double? interestRatePct,
          int? loanMultiplier,
          int? maxRepaymentMonths,
          int? requiredGuarantors,
          int? minShares,
          int? maxShares,
          int? cycleMonths,
          int? cycleMonthsElapsed,
          int? meetingsHeld,
          double? interestEarned,
          double? meetingExpense,
          double? otherExpense,
          double? openingCash,
          double? openingSocialFund,
          int? loanDurationMonths,
          int? quorumPercent,
          String? meetingFrequency,
          String? meetingStartTime,
          String? meetingLocation,
          String? fineTypes}) =>
      GroupSetting(
        id: id ?? this.id,
        name: name ?? this.name,
        term: term ?? this.term,
        shareValue: shareValue ?? this.shareValue,
        socialFundPerMtg: socialFundPerMtg ?? this.socialFundPerMtg,
        interestRatePct: interestRatePct ?? this.interestRatePct,
        loanMultiplier: loanMultiplier ?? this.loanMultiplier,
        maxRepaymentMonths: maxRepaymentMonths ?? this.maxRepaymentMonths,
        requiredGuarantors: requiredGuarantors ?? this.requiredGuarantors,
        minShares: minShares ?? this.minShares,
        maxShares: maxShares ?? this.maxShares,
        cycleMonths: cycleMonths ?? this.cycleMonths,
        cycleMonthsElapsed: cycleMonthsElapsed ?? this.cycleMonthsElapsed,
        meetingsHeld: meetingsHeld ?? this.meetingsHeld,
        interestEarned: interestEarned ?? this.interestEarned,
        meetingExpense: meetingExpense ?? this.meetingExpense,
        otherExpense: otherExpense ?? this.otherExpense,
        openingCash: openingCash ?? this.openingCash,
        openingSocialFund: openingSocialFund ?? this.openingSocialFund,
        loanDurationMonths: loanDurationMonths ?? this.loanDurationMonths,
        quorumPercent: quorumPercent ?? this.quorumPercent,
        meetingFrequency: meetingFrequency ?? this.meetingFrequency,
        meetingStartTime: meetingStartTime ?? this.meetingStartTime,
        meetingLocation: meetingLocation ?? this.meetingLocation,
        fineTypes: fineTypes ?? this.fineTypes,
      );
  GroupSetting copyWithCompanion(GroupSettingsCompanion data) {
    return GroupSetting(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      term: data.term.present ? data.term.value : this.term,
      shareValue:
          data.shareValue.present ? data.shareValue.value : this.shareValue,
      socialFundPerMtg: data.socialFundPerMtg.present
          ? data.socialFundPerMtg.value
          : this.socialFundPerMtg,
      interestRatePct: data.interestRatePct.present
          ? data.interestRatePct.value
          : this.interestRatePct,
      loanMultiplier: data.loanMultiplier.present
          ? data.loanMultiplier.value
          : this.loanMultiplier,
      maxRepaymentMonths: data.maxRepaymentMonths.present
          ? data.maxRepaymentMonths.value
          : this.maxRepaymentMonths,
      requiredGuarantors: data.requiredGuarantors.present
          ? data.requiredGuarantors.value
          : this.requiredGuarantors,
      minShares: data.minShares.present ? data.minShares.value : this.minShares,
      maxShares: data.maxShares.present ? data.maxShares.value : this.maxShares,
      cycleMonths:
          data.cycleMonths.present ? data.cycleMonths.value : this.cycleMonths,
      cycleMonthsElapsed: data.cycleMonthsElapsed.present
          ? data.cycleMonthsElapsed.value
          : this.cycleMonthsElapsed,
      meetingsHeld: data.meetingsHeld.present
          ? data.meetingsHeld.value
          : this.meetingsHeld,
      interestEarned: data.interestEarned.present
          ? data.interestEarned.value
          : this.interestEarned,
      meetingExpense: data.meetingExpense.present
          ? data.meetingExpense.value
          : this.meetingExpense,
      otherExpense: data.otherExpense.present
          ? data.otherExpense.value
          : this.otherExpense,
      openingCash:
          data.openingCash.present ? data.openingCash.value : this.openingCash,
      openingSocialFund: data.openingSocialFund.present
          ? data.openingSocialFund.value
          : this.openingSocialFund,
      loanDurationMonths: data.loanDurationMonths.present
          ? data.loanDurationMonths.value
          : this.loanDurationMonths,
      quorumPercent: data.quorumPercent.present
          ? data.quorumPercent.value
          : this.quorumPercent,
      meetingFrequency: data.meetingFrequency.present
          ? data.meetingFrequency.value
          : this.meetingFrequency,
      meetingStartTime: data.meetingStartTime.present
          ? data.meetingStartTime.value
          : this.meetingStartTime,
      meetingLocation: data.meetingLocation.present
          ? data.meetingLocation.value
          : this.meetingLocation,
      fineTypes: data.fineTypes.present ? data.fineTypes.value : this.fineTypes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupSetting(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('term: $term, ')
          ..write('shareValue: $shareValue, ')
          ..write('socialFundPerMtg: $socialFundPerMtg, ')
          ..write('interestRatePct: $interestRatePct, ')
          ..write('loanMultiplier: $loanMultiplier, ')
          ..write('maxRepaymentMonths: $maxRepaymentMonths, ')
          ..write('requiredGuarantors: $requiredGuarantors, ')
          ..write('minShares: $minShares, ')
          ..write('maxShares: $maxShares, ')
          ..write('cycleMonths: $cycleMonths, ')
          ..write('cycleMonthsElapsed: $cycleMonthsElapsed, ')
          ..write('meetingsHeld: $meetingsHeld, ')
          ..write('interestEarned: $interestEarned, ')
          ..write('meetingExpense: $meetingExpense, ')
          ..write('otherExpense: $otherExpense, ')
          ..write('openingCash: $openingCash, ')
          ..write('openingSocialFund: $openingSocialFund, ')
          ..write('loanDurationMonths: $loanDurationMonths, ')
          ..write('quorumPercent: $quorumPercent, ')
          ..write('meetingFrequency: $meetingFrequency, ')
          ..write('meetingStartTime: $meetingStartTime, ')
          ..write('meetingLocation: $meetingLocation, ')
          ..write('fineTypes: $fineTypes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        term,
        shareValue,
        socialFundPerMtg,
        interestRatePct,
        loanMultiplier,
        maxRepaymentMonths,
        requiredGuarantors,
        minShares,
        maxShares,
        cycleMonths,
        cycleMonthsElapsed,
        meetingsHeld,
        interestEarned,
        meetingExpense,
        otherExpense,
        openingCash,
        openingSocialFund,
        loanDurationMonths,
        quorumPercent,
        meetingFrequency,
        meetingStartTime,
        meetingLocation,
        fineTypes
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupSetting &&
          other.id == this.id &&
          other.name == this.name &&
          other.term == this.term &&
          other.shareValue == this.shareValue &&
          other.socialFundPerMtg == this.socialFundPerMtg &&
          other.interestRatePct == this.interestRatePct &&
          other.loanMultiplier == this.loanMultiplier &&
          other.maxRepaymentMonths == this.maxRepaymentMonths &&
          other.requiredGuarantors == this.requiredGuarantors &&
          other.minShares == this.minShares &&
          other.maxShares == this.maxShares &&
          other.cycleMonths == this.cycleMonths &&
          other.cycleMonthsElapsed == this.cycleMonthsElapsed &&
          other.meetingsHeld == this.meetingsHeld &&
          other.interestEarned == this.interestEarned &&
          other.meetingExpense == this.meetingExpense &&
          other.otherExpense == this.otherExpense &&
          other.openingCash == this.openingCash &&
          other.openingSocialFund == this.openingSocialFund &&
          other.loanDurationMonths == this.loanDurationMonths &&
          other.quorumPercent == this.quorumPercent &&
          other.meetingFrequency == this.meetingFrequency &&
          other.meetingStartTime == this.meetingStartTime &&
          other.meetingLocation == this.meetingLocation &&
          other.fineTypes == this.fineTypes);
}

class GroupSettingsCompanion extends UpdateCompanion<GroupSetting> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> term;
  final Value<double> shareValue;
  final Value<double> socialFundPerMtg;
  final Value<double> interestRatePct;
  final Value<int> loanMultiplier;
  final Value<int> maxRepaymentMonths;
  final Value<int> requiredGuarantors;
  final Value<int> minShares;
  final Value<int> maxShares;
  final Value<int> cycleMonths;
  final Value<int> cycleMonthsElapsed;
  final Value<int> meetingsHeld;
  final Value<double> interestEarned;
  final Value<double> meetingExpense;
  final Value<double> otherExpense;
  final Value<double> openingCash;
  final Value<double> openingSocialFund;
  final Value<int> loanDurationMonths;
  final Value<int> quorumPercent;
  final Value<String> meetingFrequency;
  final Value<String> meetingStartTime;
  final Value<String> meetingLocation;
  final Value<String> fineTypes;
  const GroupSettingsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.term = const Value.absent(),
    this.shareValue = const Value.absent(),
    this.socialFundPerMtg = const Value.absent(),
    this.interestRatePct = const Value.absent(),
    this.loanMultiplier = const Value.absent(),
    this.maxRepaymentMonths = const Value.absent(),
    this.requiredGuarantors = const Value.absent(),
    this.minShares = const Value.absent(),
    this.maxShares = const Value.absent(),
    this.cycleMonths = const Value.absent(),
    this.cycleMonthsElapsed = const Value.absent(),
    this.meetingsHeld = const Value.absent(),
    this.interestEarned = const Value.absent(),
    this.meetingExpense = const Value.absent(),
    this.otherExpense = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.openingSocialFund = const Value.absent(),
    this.loanDurationMonths = const Value.absent(),
    this.quorumPercent = const Value.absent(),
    this.meetingFrequency = const Value.absent(),
    this.meetingStartTime = const Value.absent(),
    this.meetingLocation = const Value.absent(),
    this.fineTypes = const Value.absent(),
  });
  GroupSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String term,
    this.shareValue = const Value.absent(),
    this.socialFundPerMtg = const Value.absent(),
    this.interestRatePct = const Value.absent(),
    this.loanMultiplier = const Value.absent(),
    this.maxRepaymentMonths = const Value.absent(),
    this.requiredGuarantors = const Value.absent(),
    this.minShares = const Value.absent(),
    this.maxShares = const Value.absent(),
    this.cycleMonths = const Value.absent(),
    this.cycleMonthsElapsed = const Value.absent(),
    this.meetingsHeld = const Value.absent(),
    this.interestEarned = const Value.absent(),
    this.meetingExpense = const Value.absent(),
    this.otherExpense = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.openingSocialFund = const Value.absent(),
    this.loanDurationMonths = const Value.absent(),
    this.quorumPercent = const Value.absent(),
    this.meetingFrequency = const Value.absent(),
    this.meetingStartTime = const Value.absent(),
    this.meetingLocation = const Value.absent(),
    this.fineTypes = const Value.absent(),
  })  : name = Value(name),
        term = Value(term);
  static Insertable<GroupSetting> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? term,
    Expression<double>? shareValue,
    Expression<double>? socialFundPerMtg,
    Expression<double>? interestRatePct,
    Expression<int>? loanMultiplier,
    Expression<int>? maxRepaymentMonths,
    Expression<int>? requiredGuarantors,
    Expression<int>? minShares,
    Expression<int>? maxShares,
    Expression<int>? cycleMonths,
    Expression<int>? cycleMonthsElapsed,
    Expression<int>? meetingsHeld,
    Expression<double>? interestEarned,
    Expression<double>? meetingExpense,
    Expression<double>? otherExpense,
    Expression<double>? openingCash,
    Expression<double>? openingSocialFund,
    Expression<int>? loanDurationMonths,
    Expression<int>? quorumPercent,
    Expression<String>? meetingFrequency,
    Expression<String>? meetingStartTime,
    Expression<String>? meetingLocation,
    Expression<String>? fineTypes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (term != null) 'term': term,
      if (shareValue != null) 'share_value': shareValue,
      if (socialFundPerMtg != null) 'social_fund_per_mtg': socialFundPerMtg,
      if (interestRatePct != null) 'interest_rate_pct': interestRatePct,
      if (loanMultiplier != null) 'loan_multiplier': loanMultiplier,
      if (maxRepaymentMonths != null)
        'max_repayment_months': maxRepaymentMonths,
      if (requiredGuarantors != null) 'required_guarantors': requiredGuarantors,
      if (minShares != null) 'min_shares': minShares,
      if (maxShares != null) 'max_shares': maxShares,
      if (cycleMonths != null) 'cycle_months': cycleMonths,
      if (cycleMonthsElapsed != null)
        'cycle_months_elapsed': cycleMonthsElapsed,
      if (meetingsHeld != null) 'meetings_held': meetingsHeld,
      if (interestEarned != null) 'interest_earned': interestEarned,
      if (meetingExpense != null) 'meeting_expense': meetingExpense,
      if (otherExpense != null) 'other_expense': otherExpense,
      if (openingCash != null) 'opening_cash': openingCash,
      if (openingSocialFund != null) 'opening_social_fund': openingSocialFund,
      if (loanDurationMonths != null)
        'loan_duration_months': loanDurationMonths,
      if (quorumPercent != null) 'quorum_percent': quorumPercent,
      if (meetingFrequency != null) 'meeting_frequency': meetingFrequency,
      if (meetingStartTime != null) 'meeting_start_time': meetingStartTime,
      if (meetingLocation != null) 'meeting_location': meetingLocation,
      if (fineTypes != null) 'fine_types': fineTypes,
    });
  }

  GroupSettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? term,
      Value<double>? shareValue,
      Value<double>? socialFundPerMtg,
      Value<double>? interestRatePct,
      Value<int>? loanMultiplier,
      Value<int>? maxRepaymentMonths,
      Value<int>? requiredGuarantors,
      Value<int>? minShares,
      Value<int>? maxShares,
      Value<int>? cycleMonths,
      Value<int>? cycleMonthsElapsed,
      Value<int>? meetingsHeld,
      Value<double>? interestEarned,
      Value<double>? meetingExpense,
      Value<double>? otherExpense,
      Value<double>? openingCash,
      Value<double>? openingSocialFund,
      Value<int>? loanDurationMonths,
      Value<int>? quorumPercent,
      Value<String>? meetingFrequency,
      Value<String>? meetingStartTime,
      Value<String>? meetingLocation,
      Value<String>? fineTypes}) {
    return GroupSettingsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      term: term ?? this.term,
      shareValue: shareValue ?? this.shareValue,
      socialFundPerMtg: socialFundPerMtg ?? this.socialFundPerMtg,
      interestRatePct: interestRatePct ?? this.interestRatePct,
      loanMultiplier: loanMultiplier ?? this.loanMultiplier,
      maxRepaymentMonths: maxRepaymentMonths ?? this.maxRepaymentMonths,
      requiredGuarantors: requiredGuarantors ?? this.requiredGuarantors,
      minShares: minShares ?? this.minShares,
      maxShares: maxShares ?? this.maxShares,
      cycleMonths: cycleMonths ?? this.cycleMonths,
      cycleMonthsElapsed: cycleMonthsElapsed ?? this.cycleMonthsElapsed,
      meetingsHeld: meetingsHeld ?? this.meetingsHeld,
      interestEarned: interestEarned ?? this.interestEarned,
      meetingExpense: meetingExpense ?? this.meetingExpense,
      otherExpense: otherExpense ?? this.otherExpense,
      openingCash: openingCash ?? this.openingCash,
      openingSocialFund: openingSocialFund ?? this.openingSocialFund,
      loanDurationMonths: loanDurationMonths ?? this.loanDurationMonths,
      quorumPercent: quorumPercent ?? this.quorumPercent,
      meetingFrequency: meetingFrequency ?? this.meetingFrequency,
      meetingStartTime: meetingStartTime ?? this.meetingStartTime,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      fineTypes: fineTypes ?? this.fineTypes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (shareValue.present) {
      map['share_value'] = Variable<double>(shareValue.value);
    }
    if (socialFundPerMtg.present) {
      map['social_fund_per_mtg'] = Variable<double>(socialFundPerMtg.value);
    }
    if (interestRatePct.present) {
      map['interest_rate_pct'] = Variable<double>(interestRatePct.value);
    }
    if (loanMultiplier.present) {
      map['loan_multiplier'] = Variable<int>(loanMultiplier.value);
    }
    if (maxRepaymentMonths.present) {
      map['max_repayment_months'] = Variable<int>(maxRepaymentMonths.value);
    }
    if (requiredGuarantors.present) {
      map['required_guarantors'] = Variable<int>(requiredGuarantors.value);
    }
    if (minShares.present) {
      map['min_shares'] = Variable<int>(minShares.value);
    }
    if (maxShares.present) {
      map['max_shares'] = Variable<int>(maxShares.value);
    }
    if (cycleMonths.present) {
      map['cycle_months'] = Variable<int>(cycleMonths.value);
    }
    if (cycleMonthsElapsed.present) {
      map['cycle_months_elapsed'] = Variable<int>(cycleMonthsElapsed.value);
    }
    if (meetingsHeld.present) {
      map['meetings_held'] = Variable<int>(meetingsHeld.value);
    }
    if (interestEarned.present) {
      map['interest_earned'] = Variable<double>(interestEarned.value);
    }
    if (meetingExpense.present) {
      map['meeting_expense'] = Variable<double>(meetingExpense.value);
    }
    if (otherExpense.present) {
      map['other_expense'] = Variable<double>(otherExpense.value);
    }
    if (openingCash.present) {
      map['opening_cash'] = Variable<double>(openingCash.value);
    }
    if (openingSocialFund.present) {
      map['opening_social_fund'] = Variable<double>(openingSocialFund.value);
    }
    if (loanDurationMonths.present) {
      map['loan_duration_months'] = Variable<int>(loanDurationMonths.value);
    }
    if (quorumPercent.present) {
      map['quorum_percent'] = Variable<int>(quorumPercent.value);
    }
    if (meetingFrequency.present) {
      map['meeting_frequency'] = Variable<String>(meetingFrequency.value);
    }
    if (meetingStartTime.present) {
      map['meeting_start_time'] = Variable<String>(meetingStartTime.value);
    }
    if (meetingLocation.present) {
      map['meeting_location'] = Variable<String>(meetingLocation.value);
    }
    if (fineTypes.present) {
      map['fine_types'] = Variable<String>(fineTypes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupSettingsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('term: $term, ')
          ..write('shareValue: $shareValue, ')
          ..write('socialFundPerMtg: $socialFundPerMtg, ')
          ..write('interestRatePct: $interestRatePct, ')
          ..write('loanMultiplier: $loanMultiplier, ')
          ..write('maxRepaymentMonths: $maxRepaymentMonths, ')
          ..write('requiredGuarantors: $requiredGuarantors, ')
          ..write('minShares: $minShares, ')
          ..write('maxShares: $maxShares, ')
          ..write('cycleMonths: $cycleMonths, ')
          ..write('cycleMonthsElapsed: $cycleMonthsElapsed, ')
          ..write('meetingsHeld: $meetingsHeld, ')
          ..write('interestEarned: $interestEarned, ')
          ..write('meetingExpense: $meetingExpense, ')
          ..write('otherExpense: $otherExpense, ')
          ..write('openingCash: $openingCash, ')
          ..write('openingSocialFund: $openingSocialFund, ')
          ..write('loanDurationMonths: $loanDurationMonths, ')
          ..write('quorumPercent: $quorumPercent, ')
          ..write('meetingFrequency: $meetingFrequency, ')
          ..write('meetingStartTime: $meetingStartTime, ')
          ..write('meetingLocation: $meetingLocation, ')
          ..write('fineTypes: $fineTypes')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<int> shares = GeneratedColumn<int>(
      'shares', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _joinedOnMeta =
      const VerificationMeta('joinedOn');
  @override
  late final GeneratedColumn<DateTime> joinedOn = GeneratedColumn<DateTime>(
      'joined_on', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, shares, joinedOn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(Insertable<Member> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    }
    if (data.containsKey('joined_on')) {
      context.handle(_joinedOnMeta,
          joinedOn.isAcceptableOrUnknown(data['joined_on']!, _joinedOnMeta));
    } else if (isInserting) {
      context.missing(_joinedOnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shares'])!,
      joinedOn: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}joined_on'])!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final String id;
  final String name;
  final String phone;
  final int shares;
  final DateTime joinedOn;
  const Member(
      {required this.id,
      required this.name,
      required this.phone,
      required this.shares,
      required this.joinedOn});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['shares'] = Variable<int>(shares);
    map['joined_on'] = Variable<DateTime>(joinedOn);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      shares: Value(shares),
      joinedOn: Value(joinedOn),
    );
  }

  factory Member.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      shares: serializer.fromJson<int>(json['shares']),
      joinedOn: serializer.fromJson<DateTime>(json['joinedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'shares': serializer.toJson<int>(shares),
      'joinedOn': serializer.toJson<DateTime>(joinedOn),
    };
  }

  Member copyWith(
          {String? id,
          String? name,
          String? phone,
          int? shares,
          DateTime? joinedOn}) =>
      Member(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        shares: shares ?? this.shares,
        joinedOn: joinedOn ?? this.joinedOn,
      );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      shares: data.shares.present ? data.shares.value : this.shares,
      joinedOn: data.joinedOn.present ? data.joinedOn.value : this.joinedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('shares: $shares, ')
          ..write('joinedOn: $joinedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, shares, joinedOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.shares == this.shares &&
          other.joinedOn == this.joinedOn);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<int> shares;
  final Value<DateTime> joinedOn;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.shares = const Value.absent(),
    this.joinedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.shares = const Value.absent(),
    required DateTime joinedOn,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        joinedOn = Value(joinedOn);
  static Insertable<Member> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<int>? shares,
    Expression<DateTime>? joinedOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (shares != null) 'shares': shares,
      if (joinedOn != null) 'joined_on': joinedOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<int>? shares,
      Value<DateTime>? joinedOn,
      Value<int>? rowid}) {
    return MembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      shares: shares ?? this.shares,
      joinedOn: joinedOn ?? this.joinedOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (shares.present) {
      map['shares'] = Variable<int>(shares.value);
    }
    if (joinedOn.present) {
      map['joined_on'] = Variable<DateTime>(joinedOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('shares: $shares, ')
          ..write('joinedOn: $joinedOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsTable extends Savings with TableInfo<$SavingsTable, Saving> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('confirmed'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, memberId, amount, type, method, date, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings';
  @override
  VerificationContext validateIntegrity(Insertable<Saving> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Saving map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Saving(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $SavingsTable createAlias(String alias) {
    return $SavingsTable(attachedDatabase, alias);
  }
}

class Saving extends DataClass implements Insertable<Saving> {
  final String id;
  final String memberId;
  final double amount;
  final String type;
  final String method;
  final DateTime date;
  final String status;
  const Saving(
      {required this.id,
      required this.memberId,
      required this.amount,
      required this.type,
      required this.method,
      required this.date,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    map['method'] = Variable<String>(method);
    map['date'] = Variable<DateTime>(date);
    map['status'] = Variable<String>(status);
    return map;
  }

  SavingsCompanion toCompanion(bool nullToAbsent) {
    return SavingsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      amount: Value(amount),
      type: Value(type),
      method: Value(method),
      date: Value(date),
      status: Value(status),
    );
  }

  factory Saving.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Saving(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      method: serializer.fromJson<String>(json['method']),
      date: serializer.fromJson<DateTime>(json['date']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'method': serializer.toJson<String>(method),
      'date': serializer.toJson<DateTime>(date),
      'status': serializer.toJson<String>(status),
    };
  }

  Saving copyWith(
          {String? id,
          String? memberId,
          double? amount,
          String? type,
          String? method,
          DateTime? date,
          String? status}) =>
      Saving(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        method: method ?? this.method,
        date: date ?? this.date,
        status: status ?? this.status,
      );
  Saving copyWithCompanion(SavingsCompanion data) {
    return Saving(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      method: data.method.present ? data.method.value : this.method,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Saving(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('method: $method, ')
          ..write('date: $date, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, memberId, amount, type, method, date, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Saving &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.method == this.method &&
          other.date == this.date &&
          other.status == this.status);
}

class SavingsCompanion extends UpdateCompanion<Saving> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<double> amount;
  final Value<String> type;
  final Value<String> method;
  final Value<DateTime> date;
  final Value<String> status;
  final Value<int> rowid;
  const SavingsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.method = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsCompanion.insert({
    required String id,
    required String memberId,
    required double amount,
    required String type,
    required String method,
    required DateTime date,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memberId = Value(memberId),
        amount = Value(amount),
        type = Value(type),
        method = Value(method),
        date = Value(date);
  static Insertable<Saving> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<String>? method,
    Expression<DateTime>? date,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (method != null) 'method': method,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? memberId,
      Value<double>? amount,
      Value<String>? type,
      Value<String>? method,
      Value<DateTime>? date,
      Value<String>? status,
      Value<int>? rowid}) {
    return SavingsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      method: method ?? this.method,
      date: date ?? this.date,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('method: $method, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShareTxTable extends ShareTx with TableInfo<$ShareTxTable, ShareTxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShareTxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shareCountMeta =
      const VerificationMeta('shareCount');
  @override
  late final GeneratedColumn<int> shareCount = GeneratedColumn<int>(
      'share_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('confirmed'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, memberId, shareCount, amount, method, date, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'share_tx';
  @override
  VerificationContext validateIntegrity(Insertable<ShareTxData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('share_count')) {
      context.handle(
          _shareCountMeta,
          shareCount.isAcceptableOrUnknown(
              data['share_count']!, _shareCountMeta));
    } else if (isInserting) {
      context.missing(_shareCountMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShareTxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShareTxData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id'])!,
      shareCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}share_count'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $ShareTxTable createAlias(String alias) {
    return $ShareTxTable(attachedDatabase, alias);
  }
}

class ShareTxData extends DataClass implements Insertable<ShareTxData> {
  final String id;
  final String memberId;
  final int shareCount;
  final double amount;
  final String method;
  final DateTime date;
  final String status;
  const ShareTxData(
      {required this.id,
      required this.memberId,
      required this.shareCount,
      required this.amount,
      required this.method,
      required this.date,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['share_count'] = Variable<int>(shareCount);
    map['amount'] = Variable<double>(amount);
    map['method'] = Variable<String>(method);
    map['date'] = Variable<DateTime>(date);
    map['status'] = Variable<String>(status);
    return map;
  }

  ShareTxCompanion toCompanion(bool nullToAbsent) {
    return ShareTxCompanion(
      id: Value(id),
      memberId: Value(memberId),
      shareCount: Value(shareCount),
      amount: Value(amount),
      method: Value(method),
      date: Value(date),
      status: Value(status),
    );
  }

  factory ShareTxData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShareTxData(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      shareCount: serializer.fromJson<int>(json['shareCount']),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String>(json['method']),
      date: serializer.fromJson<DateTime>(json['date']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'shareCount': serializer.toJson<int>(shareCount),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String>(method),
      'date': serializer.toJson<DateTime>(date),
      'status': serializer.toJson<String>(status),
    };
  }

  ShareTxData copyWith(
          {String? id,
          String? memberId,
          int? shareCount,
          double? amount,
          String? method,
          DateTime? date,
          String? status}) =>
      ShareTxData(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        shareCount: shareCount ?? this.shareCount,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        date: date ?? this.date,
        status: status ?? this.status,
      );
  ShareTxData copyWithCompanion(ShareTxCompanion data) {
    return ShareTxData(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      shareCount:
          data.shareCount.present ? data.shareCount.value : this.shareCount,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShareTxData(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('shareCount: $shareCount, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('date: $date, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, memberId, shareCount, amount, method, date, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShareTxData &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.shareCount == this.shareCount &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.date == this.date &&
          other.status == this.status);
}

class ShareTxCompanion extends UpdateCompanion<ShareTxData> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<int> shareCount;
  final Value<double> amount;
  final Value<String> method;
  final Value<DateTime> date;
  final Value<String> status;
  final Value<int> rowid;
  const ShareTxCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.shareCount = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShareTxCompanion.insert({
    required String id,
    required String memberId,
    required int shareCount,
    required double amount,
    this.method = const Value.absent(),
    required DateTime date,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memberId = Value(memberId),
        shareCount = Value(shareCount),
        amount = Value(amount),
        date = Value(date);
  static Insertable<ShareTxData> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<int>? shareCount,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<DateTime>? date,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (shareCount != null) 'share_count': shareCount,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShareTxCompanion copyWith(
      {Value<String>? id,
      Value<String>? memberId,
      Value<int>? shareCount,
      Value<double>? amount,
      Value<String>? method,
      Value<DateTime>? date,
      Value<String>? status,
      Value<int>? rowid}) {
    return ShareTxCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      shareCount: shareCount ?? this.shareCount,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      date: date ?? this.date,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (shareCount.present) {
      map['share_count'] = Variable<int>(shareCount.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShareTxCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('shareCount: $shareCount, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, Loan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberNameMeta =
      const VerificationMeta('memberName');
  @override
  late final GeneratedColumn<String> memberName = GeneratedColumn<String>(
      'member_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _principalMeta =
      const VerificationMeta('principal');
  @override
  late final GeneratedColumn<double> principal = GeneratedColumn<double>(
      'principal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _interestRateMeta =
      const VerificationMeta('interestRate');
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
      'interest_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _durationMonthsMeta =
      const VerificationMeta('durationMonths');
  @override
  late final GeneratedColumn<int> durationMonths = GeneratedColumn<int>(
      'duration_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _purposeMeta =
      const VerificationMeta('purpose');
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
      'purpose', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _disbursedOnMeta =
      const VerificationMeta('disbursedOn');
  @override
  late final GeneratedColumn<DateTime> disbursedOn = GeneratedColumn<DateTime>(
      'disbursed_on', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        memberId,
        memberName,
        principal,
        interestRate,
        durationMonths,
        dueDate,
        status,
        purpose,
        disbursedOn
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(Insertable<Loan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('member_name')) {
      context.handle(
          _memberNameMeta,
          memberName.isAcceptableOrUnknown(
              data['member_name']!, _memberNameMeta));
    } else if (isInserting) {
      context.missing(_memberNameMeta);
    }
    if (data.containsKey('principal')) {
      context.handle(_principalMeta,
          principal.isAcceptableOrUnknown(data['principal']!, _principalMeta));
    } else if (isInserting) {
      context.missing(_principalMeta);
    }
    if (data.containsKey('interest_rate')) {
      context.handle(
          _interestRateMeta,
          interestRate.isAcceptableOrUnknown(
              data['interest_rate']!, _interestRateMeta));
    }
    if (data.containsKey('duration_months')) {
      context.handle(
          _durationMonthsMeta,
          durationMonths.isAcceptableOrUnknown(
              data['duration_months']!, _durationMonthsMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(_purposeMeta,
          purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta));
    }
    if (data.containsKey('disbursed_on')) {
      context.handle(
          _disbursedOnMeta,
          disbursedOn.isAcceptableOrUnknown(
              data['disbursed_on']!, _disbursedOnMeta));
    } else if (isInserting) {
      context.missing(_disbursedOnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id'])!,
      memberName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_name'])!,
      principal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}principal'])!,
      interestRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}interest_rate'])!,
      durationMonths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_months'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      purpose: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purpose'])!,
      disbursedOn: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}disbursed_on'])!,
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }
}

class Loan extends DataClass implements Insertable<Loan> {
  final String id;
  final String memberId;
  final String memberName;
  final double principal;
  final double interestRate;
  final int durationMonths;
  final DateTime dueDate;
  final String status;
  final String purpose;
  final DateTime disbursedOn;
  const Loan(
      {required this.id,
      required this.memberId,
      required this.memberName,
      required this.principal,
      required this.interestRate,
      required this.durationMonths,
      required this.dueDate,
      required this.status,
      required this.purpose,
      required this.disbursedOn});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['member_name'] = Variable<String>(memberName);
    map['principal'] = Variable<double>(principal);
    map['interest_rate'] = Variable<double>(interestRate);
    map['duration_months'] = Variable<int>(durationMonths);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['status'] = Variable<String>(status);
    map['purpose'] = Variable<String>(purpose);
    map['disbursed_on'] = Variable<DateTime>(disbursedOn);
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      memberId: Value(memberId),
      memberName: Value(memberName),
      principal: Value(principal),
      interestRate: Value(interestRate),
      durationMonths: Value(durationMonths),
      dueDate: Value(dueDate),
      status: Value(status),
      purpose: Value(purpose),
      disbursedOn: Value(disbursedOn),
    );
  }

  factory Loan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loan(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      memberName: serializer.fromJson<String>(json['memberName']),
      principal: serializer.fromJson<double>(json['principal']),
      interestRate: serializer.fromJson<double>(json['interestRate']),
      durationMonths: serializer.fromJson<int>(json['durationMonths']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      purpose: serializer.fromJson<String>(json['purpose']),
      disbursedOn: serializer.fromJson<DateTime>(json['disbursedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'memberName': serializer.toJson<String>(memberName),
      'principal': serializer.toJson<double>(principal),
      'interestRate': serializer.toJson<double>(interestRate),
      'durationMonths': serializer.toJson<int>(durationMonths),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'status': serializer.toJson<String>(status),
      'purpose': serializer.toJson<String>(purpose),
      'disbursedOn': serializer.toJson<DateTime>(disbursedOn),
    };
  }

  Loan copyWith(
          {String? id,
          String? memberId,
          String? memberName,
          double? principal,
          double? interestRate,
          int? durationMonths,
          DateTime? dueDate,
          String? status,
          String? purpose,
          DateTime? disbursedOn}) =>
      Loan(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        memberName: memberName ?? this.memberName,
        principal: principal ?? this.principal,
        interestRate: interestRate ?? this.interestRate,
        durationMonths: durationMonths ?? this.durationMonths,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        purpose: purpose ?? this.purpose,
        disbursedOn: disbursedOn ?? this.disbursedOn,
      );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      memberName:
          data.memberName.present ? data.memberName.value : this.memberName,
      principal: data.principal.present ? data.principal.value : this.principal,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
      durationMonths: data.durationMonths.present
          ? data.durationMonths.value
          : this.durationMonths,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      disbursedOn:
          data.disbursedOn.present ? data.disbursedOn.value : this.disbursedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('memberName: $memberName, ')
          ..write('principal: $principal, ')
          ..write('interestRate: $interestRate, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('purpose: $purpose, ')
          ..write('disbursedOn: $disbursedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, memberId, memberName, principal,
      interestRate, durationMonths, dueDate, status, purpose, disbursedOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.memberName == this.memberName &&
          other.principal == this.principal &&
          other.interestRate == this.interestRate &&
          other.durationMonths == this.durationMonths &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.purpose == this.purpose &&
          other.disbursedOn == this.disbursedOn);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> memberName;
  final Value<double> principal;
  final Value<double> interestRate;
  final Value<int> durationMonths;
  final Value<DateTime> dueDate;
  final Value<String> status;
  final Value<String> purpose;
  final Value<DateTime> disbursedOn;
  final Value<int> rowid;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.memberName = const Value.absent(),
    this.principal = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.durationMonths = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.purpose = const Value.absent(),
    this.disbursedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoansCompanion.insert({
    required String id,
    required String memberId,
    required String memberName,
    required double principal,
    this.interestRate = const Value.absent(),
    this.durationMonths = const Value.absent(),
    required DateTime dueDate,
    required String status,
    this.purpose = const Value.absent(),
    required DateTime disbursedOn,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memberId = Value(memberId),
        memberName = Value(memberName),
        principal = Value(principal),
        dueDate = Value(dueDate),
        status = Value(status),
        disbursedOn = Value(disbursedOn);
  static Insertable<Loan> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? memberName,
    Expression<double>? principal,
    Expression<double>? interestRate,
    Expression<int>? durationMonths,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<String>? purpose,
    Expression<DateTime>? disbursedOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (memberName != null) 'member_name': memberName,
      if (principal != null) 'principal': principal,
      if (interestRate != null) 'interest_rate': interestRate,
      if (durationMonths != null) 'duration_months': durationMonths,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (purpose != null) 'purpose': purpose,
      if (disbursedOn != null) 'disbursed_on': disbursedOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoansCompanion copyWith(
      {Value<String>? id,
      Value<String>? memberId,
      Value<String>? memberName,
      Value<double>? principal,
      Value<double>? interestRate,
      Value<int>? durationMonths,
      Value<DateTime>? dueDate,
      Value<String>? status,
      Value<String>? purpose,
      Value<DateTime>? disbursedOn,
      Value<int>? rowid}) {
    return LoansCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      durationMonths: durationMonths ?? this.durationMonths,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      disbursedOn: disbursedOn ?? this.disbursedOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (memberName.present) {
      map['member_name'] = Variable<String>(memberName.value);
    }
    if (principal.present) {
      map['principal'] = Variable<double>(principal.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (durationMonths.present) {
      map['duration_months'] = Variable<int>(durationMonths.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (disbursedOn.present) {
      map['disbursed_on'] = Variable<DateTime>(disbursedOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('memberName: $memberName, ')
          ..write('principal: $principal, ')
          ..write('interestRate: $interestRate, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('purpose: $purpose, ')
          ..write('disbursedOn: $disbursedOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RepaymentsTable extends Repayments
    with TableInfo<$RepaymentsTable, Repayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RepaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<String> loanId = GeneratedColumn<String>(
      'loan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, loanId, amount, method, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repayments';
  @override
  VerificationContext validateIntegrity(Insertable<Repayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('loan_id')) {
      context.handle(_loanIdMeta,
          loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta));
    } else if (isInserting) {
      context.missing(_loanIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Repayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Repayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      loanId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}loan_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $RepaymentsTable createAlias(String alias) {
    return $RepaymentsTable(attachedDatabase, alias);
  }
}

class Repayment extends DataClass implements Insertable<Repayment> {
  final String id;
  final String loanId;
  final double amount;
  final String method;
  final DateTime date;
  const Repayment(
      {required this.id,
      required this.loanId,
      required this.amount,
      required this.method,
      required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['loan_id'] = Variable<String>(loanId);
    map['amount'] = Variable<double>(amount);
    map['method'] = Variable<String>(method);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  RepaymentsCompanion toCompanion(bool nullToAbsent) {
    return RepaymentsCompanion(
      id: Value(id),
      loanId: Value(loanId),
      amount: Value(amount),
      method: Value(method),
      date: Value(date),
    );
  }

  factory Repayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Repayment(
      id: serializer.fromJson<String>(json['id']),
      loanId: serializer.fromJson<String>(json['loanId']),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String>(json['method']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'loanId': serializer.toJson<String>(loanId),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String>(method),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  Repayment copyWith(
          {String? id,
          String? loanId,
          double? amount,
          String? method,
          DateTime? date}) =>
      Repayment(
        id: id ?? this.id,
        loanId: loanId ?? this.loanId,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        date: date ?? this.date,
      );
  Repayment copyWithCompanion(RepaymentsCompanion data) {
    return Repayment(
      id: data.id.present ? data.id.value : this.id,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Repayment(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, loanId, amount, method, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Repayment &&
          other.id == this.id &&
          other.loanId == this.loanId &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.date == this.date);
}

class RepaymentsCompanion extends UpdateCompanion<Repayment> {
  final Value<String> id;
  final Value<String> loanId;
  final Value<double> amount;
  final Value<String> method;
  final Value<DateTime> date;
  final Value<int> rowid;
  const RepaymentsCompanion({
    this.id = const Value.absent(),
    this.loanId = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RepaymentsCompanion.insert({
    required String id,
    required String loanId,
    required double amount,
    this.method = const Value.absent(),
    required DateTime date,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        loanId = Value(loanId),
        amount = Value(amount),
        date = Value(date);
  static Insertable<Repayment> custom({
    Expression<String>? id,
    Expression<String>? loanId,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loanId != null) 'loan_id': loanId,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RepaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? loanId,
      Value<double>? amount,
      Value<String>? method,
      Value<DateTime>? date,
      Value<int>? rowid}) {
    return RepaymentsCompanion(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<String>(loanId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepaymentsCompanion(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinesTable extends Fines with TableInfo<$FinesTable, Fine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paidMeta = const VerificationMeta('paid');
  @override
  late final GeneratedColumn<bool> paid = GeneratedColumn<bool>(
      'paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("paid" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, memberId, reason, amount, paid, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fines';
  @override
  VerificationContext validateIntegrity(Insertable<Fine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('paid')) {
      context.handle(
          _paidMeta, paid.isAcceptableOrUnknown(data['paid']!, _paidMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      paid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}paid'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $FinesTable createAlias(String alias) {
    return $FinesTable(attachedDatabase, alias);
  }
}

class Fine extends DataClass implements Insertable<Fine> {
  final String id;
  final String memberId;
  final String reason;
  final double amount;
  final bool paid;
  final DateTime date;
  const Fine(
      {required this.id,
      required this.memberId,
      required this.reason,
      required this.amount,
      required this.paid,
      required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['reason'] = Variable<String>(reason);
    map['amount'] = Variable<double>(amount);
    map['paid'] = Variable<bool>(paid);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  FinesCompanion toCompanion(bool nullToAbsent) {
    return FinesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      reason: Value(reason),
      amount: Value(amount),
      paid: Value(paid),
      date: Value(date),
    );
  }

  factory Fine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fine(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      reason: serializer.fromJson<String>(json['reason']),
      amount: serializer.fromJson<double>(json['amount']),
      paid: serializer.fromJson<bool>(json['paid']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'reason': serializer.toJson<String>(reason),
      'amount': serializer.toJson<double>(amount),
      'paid': serializer.toJson<bool>(paid),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  Fine copyWith(
          {String? id,
          String? memberId,
          String? reason,
          double? amount,
          bool? paid,
          DateTime? date}) =>
      Fine(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        reason: reason ?? this.reason,
        amount: amount ?? this.amount,
        paid: paid ?? this.paid,
        date: date ?? this.date,
      );
  Fine copyWithCompanion(FinesCompanion data) {
    return Fine(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      reason: data.reason.present ? data.reason.value : this.reason,
      amount: data.amount.present ? data.amount.value : this.amount,
      paid: data.paid.present ? data.paid.value : this.paid,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fine(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('reason: $reason, ')
          ..write('amount: $amount, ')
          ..write('paid: $paid, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, memberId, reason, amount, paid, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fine &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.reason == this.reason &&
          other.amount == this.amount &&
          other.paid == this.paid &&
          other.date == this.date);
}

class FinesCompanion extends UpdateCompanion<Fine> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> reason;
  final Value<double> amount;
  final Value<bool> paid;
  final Value<DateTime> date;
  final Value<int> rowid;
  const FinesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.reason = const Value.absent(),
    this.amount = const Value.absent(),
    this.paid = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinesCompanion.insert({
    required String id,
    required String memberId,
    required String reason,
    required double amount,
    this.paid = const Value.absent(),
    required DateTime date,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memberId = Value(memberId),
        reason = Value(reason),
        amount = Value(amount),
        date = Value(date);
  static Insertable<Fine> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? reason,
    Expression<double>? amount,
    Expression<bool>? paid,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (reason != null) 'reason': reason,
      if (amount != null) 'amount': amount,
      if (paid != null) 'paid': paid,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? memberId,
      Value<String>? reason,
      Value<double>? amount,
      Value<bool>? paid,
      Value<DateTime>? date,
      Value<int>? rowid}) {
    return FinesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      reason: reason ?? this.reason,
      amount: amount ?? this.amount,
      paid: paid ?? this.paid,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paid.present) {
      map['paid'] = Variable<bool>(paid.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('reason: $reason, ')
          ..write('amount: $amount, ')
          ..write('paid: $paid, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeetingsTable extends Meetings with TableInfo<$MeetingsTable, Meeting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attendedMeta =
      const VerificationMeta('attended');
  @override
  late final GeneratedColumn<int> attended = GeneratedColumn<int>(
      'attended', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
      'total', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _agendaItemsMeta =
      const VerificationMeta('agendaItems');
  @override
  late final GeneratedColumn<int> agendaItems = GeneratedColumn<int>(
      'agenda_items', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _decisionsMeta =
      const VerificationMeta('decisions');
  @override
  late final GeneratedColumn<int> decisions = GeneratedColumn<int>(
      'decisions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _collectionsMeta =
      const VerificationMeta('collections');
  @override
  late final GeneratedColumn<double> collections = GeneratedColumn<double>(
      'collections', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _finesMeta = const VerificationMeta('fines');
  @override
  late final GeneratedColumn<double> fines = GeneratedColumn<double>(
      'fines', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        number,
        date,
        attended,
        total,
        agendaItems,
        decisions,
        collections,
        fines
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meetings';
  @override
  VerificationContext validateIntegrity(Insertable<Meeting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('attended')) {
      context.handle(_attendedMeta,
          attended.isAcceptableOrUnknown(data['attended']!, _attendedMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('agenda_items')) {
      context.handle(
          _agendaItemsMeta,
          agendaItems.isAcceptableOrUnknown(
              data['agenda_items']!, _agendaItemsMeta));
    }
    if (data.containsKey('decisions')) {
      context.handle(_decisionsMeta,
          decisions.isAcceptableOrUnknown(data['decisions']!, _decisionsMeta));
    }
    if (data.containsKey('collections')) {
      context.handle(
          _collectionsMeta,
          collections.isAcceptableOrUnknown(
              data['collections']!, _collectionsMeta));
    }
    if (data.containsKey('fines')) {
      context.handle(
          _finesMeta, fines.isAcceptableOrUnknown(data['fines']!, _finesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meeting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meeting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      attended: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attended'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total'])!,
      agendaItems: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}agenda_items'])!,
      decisions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}decisions'])!,
      collections: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}collections'])!,
      fines: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fines'])!,
    );
  }

  @override
  $MeetingsTable createAlias(String alias) {
    return $MeetingsTable(attachedDatabase, alias);
  }
}

class Meeting extends DataClass implements Insertable<Meeting> {
  final String id;
  final int number;
  final DateTime date;
  final int attended;
  final int total;
  final int agendaItems;
  final int decisions;
  final double collections;
  final double fines;
  const Meeting(
      {required this.id,
      required this.number,
      required this.date,
      required this.attended,
      required this.total,
      required this.agendaItems,
      required this.decisions,
      required this.collections,
      required this.fines});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['number'] = Variable<int>(number);
    map['date'] = Variable<DateTime>(date);
    map['attended'] = Variable<int>(attended);
    map['total'] = Variable<int>(total);
    map['agenda_items'] = Variable<int>(agendaItems);
    map['decisions'] = Variable<int>(decisions);
    map['collections'] = Variable<double>(collections);
    map['fines'] = Variable<double>(fines);
    return map;
  }

  MeetingsCompanion toCompanion(bool nullToAbsent) {
    return MeetingsCompanion(
      id: Value(id),
      number: Value(number),
      date: Value(date),
      attended: Value(attended),
      total: Value(total),
      agendaItems: Value(agendaItems),
      decisions: Value(decisions),
      collections: Value(collections),
      fines: Value(fines),
    );
  }

  factory Meeting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meeting(
      id: serializer.fromJson<String>(json['id']),
      number: serializer.fromJson<int>(json['number']),
      date: serializer.fromJson<DateTime>(json['date']),
      attended: serializer.fromJson<int>(json['attended']),
      total: serializer.fromJson<int>(json['total']),
      agendaItems: serializer.fromJson<int>(json['agendaItems']),
      decisions: serializer.fromJson<int>(json['decisions']),
      collections: serializer.fromJson<double>(json['collections']),
      fines: serializer.fromJson<double>(json['fines']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'number': serializer.toJson<int>(number),
      'date': serializer.toJson<DateTime>(date),
      'attended': serializer.toJson<int>(attended),
      'total': serializer.toJson<int>(total),
      'agendaItems': serializer.toJson<int>(agendaItems),
      'decisions': serializer.toJson<int>(decisions),
      'collections': serializer.toJson<double>(collections),
      'fines': serializer.toJson<double>(fines),
    };
  }

  Meeting copyWith(
          {String? id,
          int? number,
          DateTime? date,
          int? attended,
          int? total,
          int? agendaItems,
          int? decisions,
          double? collections,
          double? fines}) =>
      Meeting(
        id: id ?? this.id,
        number: number ?? this.number,
        date: date ?? this.date,
        attended: attended ?? this.attended,
        total: total ?? this.total,
        agendaItems: agendaItems ?? this.agendaItems,
        decisions: decisions ?? this.decisions,
        collections: collections ?? this.collections,
        fines: fines ?? this.fines,
      );
  Meeting copyWithCompanion(MeetingsCompanion data) {
    return Meeting(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      date: data.date.present ? data.date.value : this.date,
      attended: data.attended.present ? data.attended.value : this.attended,
      total: data.total.present ? data.total.value : this.total,
      agendaItems:
          data.agendaItems.present ? data.agendaItems.value : this.agendaItems,
      decisions: data.decisions.present ? data.decisions.value : this.decisions,
      collections:
          data.collections.present ? data.collections.value : this.collections,
      fines: data.fines.present ? data.fines.value : this.fines,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meeting(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('date: $date, ')
          ..write('attended: $attended, ')
          ..write('total: $total, ')
          ..write('agendaItems: $agendaItems, ')
          ..write('decisions: $decisions, ')
          ..write('collections: $collections, ')
          ..write('fines: $fines')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, number, date, attended, total,
      agendaItems, decisions, collections, fines);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meeting &&
          other.id == this.id &&
          other.number == this.number &&
          other.date == this.date &&
          other.attended == this.attended &&
          other.total == this.total &&
          other.agendaItems == this.agendaItems &&
          other.decisions == this.decisions &&
          other.collections == this.collections &&
          other.fines == this.fines);
}

class MeetingsCompanion extends UpdateCompanion<Meeting> {
  final Value<String> id;
  final Value<int> number;
  final Value<DateTime> date;
  final Value<int> attended;
  final Value<int> total;
  final Value<int> agendaItems;
  final Value<int> decisions;
  final Value<double> collections;
  final Value<double> fines;
  final Value<int> rowid;
  const MeetingsCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.date = const Value.absent(),
    this.attended = const Value.absent(),
    this.total = const Value.absent(),
    this.agendaItems = const Value.absent(),
    this.decisions = const Value.absent(),
    this.collections = const Value.absent(),
    this.fines = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingsCompanion.insert({
    required String id,
    required int number,
    required DateTime date,
    this.attended = const Value.absent(),
    this.total = const Value.absent(),
    this.agendaItems = const Value.absent(),
    this.decisions = const Value.absent(),
    this.collections = const Value.absent(),
    this.fines = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        number = Value(number),
        date = Value(date);
  static Insertable<Meeting> custom({
    Expression<String>? id,
    Expression<int>? number,
    Expression<DateTime>? date,
    Expression<int>? attended,
    Expression<int>? total,
    Expression<int>? agendaItems,
    Expression<int>? decisions,
    Expression<double>? collections,
    Expression<double>? fines,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (date != null) 'date': date,
      if (attended != null) 'attended': attended,
      if (total != null) 'total': total,
      if (agendaItems != null) 'agenda_items': agendaItems,
      if (decisions != null) 'decisions': decisions,
      if (collections != null) 'collections': collections,
      if (fines != null) 'fines': fines,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingsCompanion copyWith(
      {Value<String>? id,
      Value<int>? number,
      Value<DateTime>? date,
      Value<int>? attended,
      Value<int>? total,
      Value<int>? agendaItems,
      Value<int>? decisions,
      Value<double>? collections,
      Value<double>? fines,
      Value<int>? rowid}) {
    return MeetingsCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      attended: attended ?? this.attended,
      total: total ?? this.total,
      agendaItems: agendaItems ?? this.agendaItems,
      decisions: decisions ?? this.decisions,
      collections: collections ?? this.collections,
      fines: fines ?? this.fines,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (attended.present) {
      map['attended'] = Variable<int>(attended.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (agendaItems.present) {
      map['agenda_items'] = Variable<int>(agendaItems.value);
    }
    if (decisions.present) {
      map['decisions'] = Variable<int>(decisions.value);
    }
    if (collections.present) {
      map['collections'] = Variable<double>(collections.value);
    }
    if (fines.present) {
      map['fines'] = Variable<double>(fines.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingsCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('date: $date, ')
          ..write('attended: $attended, ')
          ..write('total: $total, ')
          ..write('agendaItems: $agendaItems, ')
          ..write('decisions: $decisions, ')
          ..write('collections: $collections, ')
          ..write('fines: $fines, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfficersTable extends Officers with TableInfo<$OfficersTable, Officer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfficersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberNameMeta =
      const VerificationMeta('memberName');
  @override
  late final GeneratedColumn<String> memberName = GeneratedColumn<String>(
      'member_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [id, memberName, role, phone];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'officers';
  @override
  VerificationContext validateIntegrity(Insertable<Officer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_name')) {
      context.handle(
          _memberNameMeta,
          memberName.isAcceptableOrUnknown(
              data['member_name']!, _memberNameMeta));
    } else if (isInserting) {
      context.missing(_memberNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Officer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Officer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memberName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
    );
  }

  @override
  $OfficersTable createAlias(String alias) {
    return $OfficersTable(attachedDatabase, alias);
  }
}

class Officer extends DataClass implements Insertable<Officer> {
  final String id;
  final String memberName;
  final String role;
  final String phone;
  const Officer(
      {required this.id,
      required this.memberName,
      required this.role,
      required this.phone});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_name'] = Variable<String>(memberName);
    map['role'] = Variable<String>(role);
    map['phone'] = Variable<String>(phone);
    return map;
  }

  OfficersCompanion toCompanion(bool nullToAbsent) {
    return OfficersCompanion(
      id: Value(id),
      memberName: Value(memberName),
      role: Value(role),
      phone: Value(phone),
    );
  }

  factory Officer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Officer(
      id: serializer.fromJson<String>(json['id']),
      memberName: serializer.fromJson<String>(json['memberName']),
      role: serializer.fromJson<String>(json['role']),
      phone: serializer.fromJson<String>(json['phone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberName': serializer.toJson<String>(memberName),
      'role': serializer.toJson<String>(role),
      'phone': serializer.toJson<String>(phone),
    };
  }

  Officer copyWith(
          {String? id, String? memberName, String? role, String? phone}) =>
      Officer(
        id: id ?? this.id,
        memberName: memberName ?? this.memberName,
        role: role ?? this.role,
        phone: phone ?? this.phone,
      );
  Officer copyWithCompanion(OfficersCompanion data) {
    return Officer(
      id: data.id.present ? data.id.value : this.id,
      memberName:
          data.memberName.present ? data.memberName.value : this.memberName,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Officer(')
          ..write('id: $id, ')
          ..write('memberName: $memberName, ')
          ..write('role: $role, ')
          ..write('phone: $phone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, memberName, role, phone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Officer &&
          other.id == this.id &&
          other.memberName == this.memberName &&
          other.role == this.role &&
          other.phone == this.phone);
}

class OfficersCompanion extends UpdateCompanion<Officer> {
  final Value<String> id;
  final Value<String> memberName;
  final Value<String> role;
  final Value<String> phone;
  final Value<int> rowid;
  const OfficersCompanion({
    this.id = const Value.absent(),
    this.memberName = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfficersCompanion.insert({
    required String id,
    required String memberName,
    required String role,
    this.phone = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memberName = Value(memberName),
        role = Value(role);
  static Insertable<Officer> custom({
    Expression<String>? id,
    Expression<String>? memberName,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberName != null) 'member_name': memberName,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfficersCompanion copyWith(
      {Value<String>? id,
      Value<String>? memberName,
      Value<String>? role,
      Value<String>? phone,
      Value<int>? rowid}) {
    return OfficersCompanion(
      id: id ?? this.id,
      memberName: memberName ?? this.memberName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberName.present) {
      map['member_name'] = Variable<String>(memberName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfficersCompanion(')
          ..write('id: $id, ')
          ..write('memberName: $memberName, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoanGuarantorsTable extends LoanGuarantors
    with TableInfo<$LoanGuarantorsTable, LoanGuarantor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoanGuarantorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<String> loanId = GeneratedColumn<String>(
      'loan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [loanId, memberId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loan_guarantors';
  @override
  VerificationContext validateIntegrity(Insertable<LoanGuarantor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('loan_id')) {
      context.handle(_loanIdMeta,
          loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta));
    } else if (isInserting) {
      context.missing(_loanIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {loanId, memberId};
  @override
  LoanGuarantor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanGuarantor(
      loanId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}loan_id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id'])!,
    );
  }

  @override
  $LoanGuarantorsTable createAlias(String alias) {
    return $LoanGuarantorsTable(attachedDatabase, alias);
  }
}

class LoanGuarantor extends DataClass implements Insertable<LoanGuarantor> {
  final String loanId;
  final String memberId;
  const LoanGuarantor({required this.loanId, required this.memberId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['loan_id'] = Variable<String>(loanId);
    map['member_id'] = Variable<String>(memberId);
    return map;
  }

  LoanGuarantorsCompanion toCompanion(bool nullToAbsent) {
    return LoanGuarantorsCompanion(
      loanId: Value(loanId),
      memberId: Value(memberId),
    );
  }

  factory LoanGuarantor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanGuarantor(
      loanId: serializer.fromJson<String>(json['loanId']),
      memberId: serializer.fromJson<String>(json['memberId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'loanId': serializer.toJson<String>(loanId),
      'memberId': serializer.toJson<String>(memberId),
    };
  }

  LoanGuarantor copyWith({String? loanId, String? memberId}) => LoanGuarantor(
        loanId: loanId ?? this.loanId,
        memberId: memberId ?? this.memberId,
      );
  LoanGuarantor copyWithCompanion(LoanGuarantorsCompanion data) {
    return LoanGuarantor(
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanGuarantor(')
          ..write('loanId: $loanId, ')
          ..write('memberId: $memberId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(loanId, memberId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanGuarantor &&
          other.loanId == this.loanId &&
          other.memberId == this.memberId);
}

class LoanGuarantorsCompanion extends UpdateCompanion<LoanGuarantor> {
  final Value<String> loanId;
  final Value<String> memberId;
  final Value<int> rowid;
  const LoanGuarantorsCompanion({
    this.loanId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoanGuarantorsCompanion.insert({
    required String loanId,
    required String memberId,
    this.rowid = const Value.absent(),
  })  : loanId = Value(loanId),
        memberId = Value(memberId);
  static Insertable<LoanGuarantor> custom({
    Expression<String>? loanId,
    Expression<String>? memberId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (loanId != null) 'loan_id': loanId,
      if (memberId != null) 'member_id': memberId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoanGuarantorsCompanion copyWith(
      {Value<String>? loanId, Value<String>? memberId, Value<int>? rowid}) {
    return LoanGuarantorsCompanion(
      loanId: loanId ?? this.loanId,
      memberId: memberId ?? this.memberId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (loanId.present) {
      map['loan_id'] = Variable<String>(loanId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoanGuarantorsCompanion(')
          ..write('loanId: $loanId, ')
          ..write('memberId: $memberId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GroupSettingsTable groupSettings = $GroupSettingsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $SavingsTable savings = $SavingsTable(this);
  late final $ShareTxTable shareTx = $ShareTxTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $RepaymentsTable repayments = $RepaymentsTable(this);
  late final $FinesTable fines = $FinesTable(this);
  late final $MeetingsTable meetings = $MeetingsTable(this);
  late final $OfficersTable officers = $OfficersTable(this);
  late final $LoanGuarantorsTable loanGuarantors = $LoanGuarantorsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        groupSettings,
        members,
        savings,
        shareTx,
        loans,
        repayments,
        fines,
        meetings,
        officers,
        loanGuarantors
      ];
}

typedef $$GroupSettingsTableCreateCompanionBuilder = GroupSettingsCompanion
    Function({
  Value<int> id,
  required String name,
  required String term,
  Value<double> shareValue,
  Value<double> socialFundPerMtg,
  Value<double> interestRatePct,
  Value<int> loanMultiplier,
  Value<int> maxRepaymentMonths,
  Value<int> requiredGuarantors,
  Value<int> minShares,
  Value<int> maxShares,
  Value<int> cycleMonths,
  Value<int> cycleMonthsElapsed,
  Value<int> meetingsHeld,
  Value<double> interestEarned,
  Value<double> meetingExpense,
  Value<double> otherExpense,
  Value<double> openingCash,
  Value<double> openingSocialFund,
  Value<int> loanDurationMonths,
  Value<int> quorumPercent,
  Value<String> meetingFrequency,
  Value<String> meetingStartTime,
  Value<String> meetingLocation,
  Value<String> fineTypes,
});
typedef $$GroupSettingsTableUpdateCompanionBuilder = GroupSettingsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> term,
  Value<double> shareValue,
  Value<double> socialFundPerMtg,
  Value<double> interestRatePct,
  Value<int> loanMultiplier,
  Value<int> maxRepaymentMonths,
  Value<int> requiredGuarantors,
  Value<int> minShares,
  Value<int> maxShares,
  Value<int> cycleMonths,
  Value<int> cycleMonthsElapsed,
  Value<int> meetingsHeld,
  Value<double> interestEarned,
  Value<double> meetingExpense,
  Value<double> otherExpense,
  Value<double> openingCash,
  Value<double> openingSocialFund,
  Value<int> loanDurationMonths,
  Value<int> quorumPercent,
  Value<String> meetingFrequency,
  Value<String> meetingStartTime,
  Value<String> meetingLocation,
  Value<String> fineTypes,
});

class $$GroupSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupSettingsTable> {
  $$GroupSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shareValue => $composableBuilder(
      column: $table.shareValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get socialFundPerMtg => $composableBuilder(
      column: $table.socialFundPerMtg,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get interestRatePct => $composableBuilder(
      column: $table.interestRatePct,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get loanMultiplier => $composableBuilder(
      column: $table.loanMultiplier,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxRepaymentMonths => $composableBuilder(
      column: $table.maxRepaymentMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requiredGuarantors => $composableBuilder(
      column: $table.requiredGuarantors,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minShares => $composableBuilder(
      column: $table.minShares, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxShares => $composableBuilder(
      column: $table.maxShares, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cycleMonths => $composableBuilder(
      column: $table.cycleMonths, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cycleMonthsElapsed => $composableBuilder(
      column: $table.cycleMonthsElapsed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get meetingsHeld => $composableBuilder(
      column: $table.meetingsHeld, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get interestEarned => $composableBuilder(
      column: $table.interestEarned,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get meetingExpense => $composableBuilder(
      column: $table.meetingExpense,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get otherExpense => $composableBuilder(
      column: $table.otherExpense, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get openingSocialFund => $composableBuilder(
      column: $table.openingSocialFund,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get loanDurationMonths => $composableBuilder(
      column: $table.loanDurationMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quorumPercent => $composableBuilder(
      column: $table.quorumPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meetingFrequency => $composableBuilder(
      column: $table.meetingFrequency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meetingStartTime => $composableBuilder(
      column: $table.meetingStartTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meetingLocation => $composableBuilder(
      column: $table.meetingLocation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fineTypes => $composableBuilder(
      column: $table.fineTypes, builder: (column) => ColumnFilters(column));
}

class $$GroupSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupSettingsTable> {
  $$GroupSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shareValue => $composableBuilder(
      column: $table.shareValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get socialFundPerMtg => $composableBuilder(
      column: $table.socialFundPerMtg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get interestRatePct => $composableBuilder(
      column: $table.interestRatePct,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get loanMultiplier => $composableBuilder(
      column: $table.loanMultiplier,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxRepaymentMonths => $composableBuilder(
      column: $table.maxRepaymentMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requiredGuarantors => $composableBuilder(
      column: $table.requiredGuarantors,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minShares => $composableBuilder(
      column: $table.minShares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxShares => $composableBuilder(
      column: $table.maxShares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cycleMonths => $composableBuilder(
      column: $table.cycleMonths, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cycleMonthsElapsed => $composableBuilder(
      column: $table.cycleMonthsElapsed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get meetingsHeld => $composableBuilder(
      column: $table.meetingsHeld,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get interestEarned => $composableBuilder(
      column: $table.interestEarned,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get meetingExpense => $composableBuilder(
      column: $table.meetingExpense,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get otherExpense => $composableBuilder(
      column: $table.otherExpense,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get openingSocialFund => $composableBuilder(
      column: $table.openingSocialFund,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get loanDurationMonths => $composableBuilder(
      column: $table.loanDurationMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quorumPercent => $composableBuilder(
      column: $table.quorumPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meetingFrequency => $composableBuilder(
      column: $table.meetingFrequency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meetingStartTime => $composableBuilder(
      column: $table.meetingStartTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meetingLocation => $composableBuilder(
      column: $table.meetingLocation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fineTypes => $composableBuilder(
      column: $table.fineTypes, builder: (column) => ColumnOrderings(column));
}

class $$GroupSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupSettingsTable> {
  $$GroupSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<double> get shareValue => $composableBuilder(
      column: $table.shareValue, builder: (column) => column);

  GeneratedColumn<double> get socialFundPerMtg => $composableBuilder(
      column: $table.socialFundPerMtg, builder: (column) => column);

  GeneratedColumn<double> get interestRatePct => $composableBuilder(
      column: $table.interestRatePct, builder: (column) => column);

  GeneratedColumn<int> get loanMultiplier => $composableBuilder(
      column: $table.loanMultiplier, builder: (column) => column);

  GeneratedColumn<int> get maxRepaymentMonths => $composableBuilder(
      column: $table.maxRepaymentMonths, builder: (column) => column);

  GeneratedColumn<int> get requiredGuarantors => $composableBuilder(
      column: $table.requiredGuarantors, builder: (column) => column);

  GeneratedColumn<int> get minShares =>
      $composableBuilder(column: $table.minShares, builder: (column) => column);

  GeneratedColumn<int> get maxShares =>
      $composableBuilder(column: $table.maxShares, builder: (column) => column);

  GeneratedColumn<int> get cycleMonths => $composableBuilder(
      column: $table.cycleMonths, builder: (column) => column);

  GeneratedColumn<int> get cycleMonthsElapsed => $composableBuilder(
      column: $table.cycleMonthsElapsed, builder: (column) => column);

  GeneratedColumn<int> get meetingsHeld => $composableBuilder(
      column: $table.meetingsHeld, builder: (column) => column);

  GeneratedColumn<double> get interestEarned => $composableBuilder(
      column: $table.interestEarned, builder: (column) => column);

  GeneratedColumn<double> get meetingExpense => $composableBuilder(
      column: $table.meetingExpense, builder: (column) => column);

  GeneratedColumn<double> get otherExpense => $composableBuilder(
      column: $table.otherExpense, builder: (column) => column);

  GeneratedColumn<double> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => column);

  GeneratedColumn<double> get openingSocialFund => $composableBuilder(
      column: $table.openingSocialFund, builder: (column) => column);

  GeneratedColumn<int> get loanDurationMonths => $composableBuilder(
      column: $table.loanDurationMonths, builder: (column) => column);

  GeneratedColumn<int> get quorumPercent => $composableBuilder(
      column: $table.quorumPercent, builder: (column) => column);

  GeneratedColumn<String> get meetingFrequency => $composableBuilder(
      column: $table.meetingFrequency, builder: (column) => column);

  GeneratedColumn<String> get meetingStartTime => $composableBuilder(
      column: $table.meetingStartTime, builder: (column) => column);

  GeneratedColumn<String> get meetingLocation => $composableBuilder(
      column: $table.meetingLocation, builder: (column) => column);

  GeneratedColumn<String> get fineTypes =>
      $composableBuilder(column: $table.fineTypes, builder: (column) => column);
}

class $$GroupSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupSettingsTable,
    GroupSetting,
    $$GroupSettingsTableFilterComposer,
    $$GroupSettingsTableOrderingComposer,
    $$GroupSettingsTableAnnotationComposer,
    $$GroupSettingsTableCreateCompanionBuilder,
    $$GroupSettingsTableUpdateCompanionBuilder,
    (
      GroupSetting,
      BaseReferences<_$AppDatabase, $GroupSettingsTable, GroupSetting>
    ),
    GroupSetting,
    PrefetchHooks Function()> {
  $$GroupSettingsTableTableManager(_$AppDatabase db, $GroupSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> term = const Value.absent(),
            Value<double> shareValue = const Value.absent(),
            Value<double> socialFundPerMtg = const Value.absent(),
            Value<double> interestRatePct = const Value.absent(),
            Value<int> loanMultiplier = const Value.absent(),
            Value<int> maxRepaymentMonths = const Value.absent(),
            Value<int> requiredGuarantors = const Value.absent(),
            Value<int> minShares = const Value.absent(),
            Value<int> maxShares = const Value.absent(),
            Value<int> cycleMonths = const Value.absent(),
            Value<int> cycleMonthsElapsed = const Value.absent(),
            Value<int> meetingsHeld = const Value.absent(),
            Value<double> interestEarned = const Value.absent(),
            Value<double> meetingExpense = const Value.absent(),
            Value<double> otherExpense = const Value.absent(),
            Value<double> openingCash = const Value.absent(),
            Value<double> openingSocialFund = const Value.absent(),
            Value<int> loanDurationMonths = const Value.absent(),
            Value<int> quorumPercent = const Value.absent(),
            Value<String> meetingFrequency = const Value.absent(),
            Value<String> meetingStartTime = const Value.absent(),
            Value<String> meetingLocation = const Value.absent(),
            Value<String> fineTypes = const Value.absent(),
          }) =>
              GroupSettingsCompanion(
            id: id,
            name: name,
            term: term,
            shareValue: shareValue,
            socialFundPerMtg: socialFundPerMtg,
            interestRatePct: interestRatePct,
            loanMultiplier: loanMultiplier,
            maxRepaymentMonths: maxRepaymentMonths,
            requiredGuarantors: requiredGuarantors,
            minShares: minShares,
            maxShares: maxShares,
            cycleMonths: cycleMonths,
            cycleMonthsElapsed: cycleMonthsElapsed,
            meetingsHeld: meetingsHeld,
            interestEarned: interestEarned,
            meetingExpense: meetingExpense,
            otherExpense: otherExpense,
            openingCash: openingCash,
            openingSocialFund: openingSocialFund,
            loanDurationMonths: loanDurationMonths,
            quorumPercent: quorumPercent,
            meetingFrequency: meetingFrequency,
            meetingStartTime: meetingStartTime,
            meetingLocation: meetingLocation,
            fineTypes: fineTypes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String term,
            Value<double> shareValue = const Value.absent(),
            Value<double> socialFundPerMtg = const Value.absent(),
            Value<double> interestRatePct = const Value.absent(),
            Value<int> loanMultiplier = const Value.absent(),
            Value<int> maxRepaymentMonths = const Value.absent(),
            Value<int> requiredGuarantors = const Value.absent(),
            Value<int> minShares = const Value.absent(),
            Value<int> maxShares = const Value.absent(),
            Value<int> cycleMonths = const Value.absent(),
            Value<int> cycleMonthsElapsed = const Value.absent(),
            Value<int> meetingsHeld = const Value.absent(),
            Value<double> interestEarned = const Value.absent(),
            Value<double> meetingExpense = const Value.absent(),
            Value<double> otherExpense = const Value.absent(),
            Value<double> openingCash = const Value.absent(),
            Value<double> openingSocialFund = const Value.absent(),
            Value<int> loanDurationMonths = const Value.absent(),
            Value<int> quorumPercent = const Value.absent(),
            Value<String> meetingFrequency = const Value.absent(),
            Value<String> meetingStartTime = const Value.absent(),
            Value<String> meetingLocation = const Value.absent(),
            Value<String> fineTypes = const Value.absent(),
          }) =>
              GroupSettingsCompanion.insert(
            id: id,
            name: name,
            term: term,
            shareValue: shareValue,
            socialFundPerMtg: socialFundPerMtg,
            interestRatePct: interestRatePct,
            loanMultiplier: loanMultiplier,
            maxRepaymentMonths: maxRepaymentMonths,
            requiredGuarantors: requiredGuarantors,
            minShares: minShares,
            maxShares: maxShares,
            cycleMonths: cycleMonths,
            cycleMonthsElapsed: cycleMonthsElapsed,
            meetingsHeld: meetingsHeld,
            interestEarned: interestEarned,
            meetingExpense: meetingExpense,
            otherExpense: otherExpense,
            openingCash: openingCash,
            openingSocialFund: openingSocialFund,
            loanDurationMonths: loanDurationMonths,
            quorumPercent: quorumPercent,
            meetingFrequency: meetingFrequency,
            meetingStartTime: meetingStartTime,
            meetingLocation: meetingLocation,
            fineTypes: fineTypes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupSettingsTable,
    GroupSetting,
    $$GroupSettingsTableFilterComposer,
    $$GroupSettingsTableOrderingComposer,
    $$GroupSettingsTableAnnotationComposer,
    $$GroupSettingsTableCreateCompanionBuilder,
    $$GroupSettingsTableUpdateCompanionBuilder,
    (
      GroupSetting,
      BaseReferences<_$AppDatabase, $GroupSettingsTable, GroupSetting>
    ),
    GroupSetting,
    PrefetchHooks Function()>;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String name,
  Value<String> phone,
  Value<int> shares,
  required DateTime joinedOn,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<int> shares,
  Value<DateTime> joinedOn,
  Value<int> rowid,
});

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get joinedOn => $composableBuilder(
      column: $table.joinedOn, builder: (column) => ColumnFilters(column));
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get joinedOn => $composableBuilder(
      column: $table.joinedOn, builder: (column) => ColumnOrderings(column));
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<int> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedOn =>
      $composableBuilder(column: $table.joinedOn, builder: (column) => column);
}

class $$MembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MembersTable,
    Member,
    $$MembersTableFilterComposer,
    $$MembersTableOrderingComposer,
    $$MembersTableAnnotationComposer,
    $$MembersTableCreateCompanionBuilder,
    $$MembersTableUpdateCompanionBuilder,
    (Member, BaseReferences<_$AppDatabase, $MembersTable, Member>),
    Member,
    PrefetchHooks Function()> {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<int> shares = const Value.absent(),
            Value<DateTime> joinedOn = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembersCompanion(
            id: id,
            name: name,
            phone: phone,
            shares: shares,
            joinedOn: joinedOn,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> phone = const Value.absent(),
            Value<int> shares = const Value.absent(),
            required DateTime joinedOn,
            Value<int> rowid = const Value.absent(),
          }) =>
              MembersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            shares: shares,
            joinedOn: joinedOn,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MembersTable,
    Member,
    $$MembersTableFilterComposer,
    $$MembersTableOrderingComposer,
    $$MembersTableAnnotationComposer,
    $$MembersTableCreateCompanionBuilder,
    $$MembersTableUpdateCompanionBuilder,
    (Member, BaseReferences<_$AppDatabase, $MembersTable, Member>),
    Member,
    PrefetchHooks Function()>;
typedef $$SavingsTableCreateCompanionBuilder = SavingsCompanion Function({
  required String id,
  required String memberId,
  required double amount,
  required String type,
  required String method,
  required DateTime date,
  Value<String> status,
  Value<int> rowid,
});
typedef $$SavingsTableUpdateCompanionBuilder = SavingsCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<double> amount,
  Value<String> type,
  Value<String> method,
  Value<DateTime> date,
  Value<String> status,
  Value<int> rowid,
});

class $$SavingsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsTable> {
  $$SavingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$SavingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsTable> {
  $$SavingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$SavingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsTable> {
  $$SavingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SavingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavingsTable,
    Saving,
    $$SavingsTableFilterComposer,
    $$SavingsTableOrderingComposer,
    $$SavingsTableAnnotationComposer,
    $$SavingsTableCreateCompanionBuilder,
    $$SavingsTableUpdateCompanionBuilder,
    (Saving, BaseReferences<_$AppDatabase, $SavingsTable, Saving>),
    Saving,
    PrefetchHooks Function()> {
  $$SavingsTableTableManager(_$AppDatabase db, $SavingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memberId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingsCompanion(
            id: id,
            memberId: memberId,
            amount: amount,
            type: type,
            method: method,
            date: date,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memberId,
            required double amount,
            required String type,
            required String method,
            required DateTime date,
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingsCompanion.insert(
            id: id,
            memberId: memberId,
            amount: amount,
            type: type,
            method: method,
            date: date,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavingsTable,
    Saving,
    $$SavingsTableFilterComposer,
    $$SavingsTableOrderingComposer,
    $$SavingsTableAnnotationComposer,
    $$SavingsTableCreateCompanionBuilder,
    $$SavingsTableUpdateCompanionBuilder,
    (Saving, BaseReferences<_$AppDatabase, $SavingsTable, Saving>),
    Saving,
    PrefetchHooks Function()>;
typedef $$ShareTxTableCreateCompanionBuilder = ShareTxCompanion Function({
  required String id,
  required String memberId,
  required int shareCount,
  required double amount,
  Value<String> method,
  required DateTime date,
  Value<String> status,
  Value<int> rowid,
});
typedef $$ShareTxTableUpdateCompanionBuilder = ShareTxCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<int> shareCount,
  Value<double> amount,
  Value<String> method,
  Value<DateTime> date,
  Value<String> status,
  Value<int> rowid,
});

class $$ShareTxTableFilterComposer
    extends Composer<_$AppDatabase, $ShareTxTable> {
  $$ShareTxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shareCount => $composableBuilder(
      column: $table.shareCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$ShareTxTableOrderingComposer
    extends Composer<_$AppDatabase, $ShareTxTable> {
  $$ShareTxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shareCount => $composableBuilder(
      column: $table.shareCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$ShareTxTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShareTxTable> {
  $$ShareTxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get shareCount => $composableBuilder(
      column: $table.shareCount, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ShareTxTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShareTxTable,
    ShareTxData,
    $$ShareTxTableFilterComposer,
    $$ShareTxTableOrderingComposer,
    $$ShareTxTableAnnotationComposer,
    $$ShareTxTableCreateCompanionBuilder,
    $$ShareTxTableUpdateCompanionBuilder,
    (ShareTxData, BaseReferences<_$AppDatabase, $ShareTxTable, ShareTxData>),
    ShareTxData,
    PrefetchHooks Function()> {
  $$ShareTxTableTableManager(_$AppDatabase db, $ShareTxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShareTxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShareTxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShareTxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memberId = const Value.absent(),
            Value<int> shareCount = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShareTxCompanion(
            id: id,
            memberId: memberId,
            shareCount: shareCount,
            amount: amount,
            method: method,
            date: date,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memberId,
            required int shareCount,
            required double amount,
            Value<String> method = const Value.absent(),
            required DateTime date,
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShareTxCompanion.insert(
            id: id,
            memberId: memberId,
            shareCount: shareCount,
            amount: amount,
            method: method,
            date: date,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShareTxTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShareTxTable,
    ShareTxData,
    $$ShareTxTableFilterComposer,
    $$ShareTxTableOrderingComposer,
    $$ShareTxTableAnnotationComposer,
    $$ShareTxTableCreateCompanionBuilder,
    $$ShareTxTableUpdateCompanionBuilder,
    (ShareTxData, BaseReferences<_$AppDatabase, $ShareTxTable, ShareTxData>),
    ShareTxData,
    PrefetchHooks Function()>;
typedef $$LoansTableCreateCompanionBuilder = LoansCompanion Function({
  required String id,
  required String memberId,
  required String memberName,
  required double principal,
  Value<double> interestRate,
  Value<int> durationMonths,
  required DateTime dueDate,
  required String status,
  Value<String> purpose,
  required DateTime disbursedOn,
  Value<int> rowid,
});
typedef $$LoansTableUpdateCompanionBuilder = LoansCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<String> memberName,
  Value<double> principal,
  Value<double> interestRate,
  Value<int> durationMonths,
  Value<DateTime> dueDate,
  Value<String> status,
  Value<String> purpose,
  Value<DateTime> disbursedOn,
  Value<int> rowid,
});

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberName => $composableBuilder(
      column: $table.memberName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get principal => $composableBuilder(
      column: $table.principal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get interestRate => $composableBuilder(
      column: $table.interestRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get disbursedOn => $composableBuilder(
      column: $table.disbursedOn, builder: (column) => ColumnFilters(column));
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberName => $composableBuilder(
      column: $table.memberName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get principal => $composableBuilder(
      column: $table.principal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get interestRate => $composableBuilder(
      column: $table.interestRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get disbursedOn => $composableBuilder(
      column: $table.disbursedOn, builder: (column) => ColumnOrderings(column));
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get memberName => $composableBuilder(
      column: $table.memberName, builder: (column) => column);

  GeneratedColumn<double> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => column);

  GeneratedColumn<double> get interestRate => $composableBuilder(
      column: $table.interestRate, builder: (column) => column);

  GeneratedColumn<int> get durationMonths => $composableBuilder(
      column: $table.durationMonths, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<DateTime> get disbursedOn => $composableBuilder(
      column: $table.disbursedOn, builder: (column) => column);
}

class $$LoansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LoansTable,
    Loan,
    $$LoansTableFilterComposer,
    $$LoansTableOrderingComposer,
    $$LoansTableAnnotationComposer,
    $$LoansTableCreateCompanionBuilder,
    $$LoansTableUpdateCompanionBuilder,
    (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
    Loan,
    PrefetchHooks Function()> {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memberId = const Value.absent(),
            Value<String> memberName = const Value.absent(),
            Value<double> principal = const Value.absent(),
            Value<double> interestRate = const Value.absent(),
            Value<int> durationMonths = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> purpose = const Value.absent(),
            Value<DateTime> disbursedOn = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoansCompanion(
            id: id,
            memberId: memberId,
            memberName: memberName,
            principal: principal,
            interestRate: interestRate,
            durationMonths: durationMonths,
            dueDate: dueDate,
            status: status,
            purpose: purpose,
            disbursedOn: disbursedOn,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memberId,
            required String memberName,
            required double principal,
            Value<double> interestRate = const Value.absent(),
            Value<int> durationMonths = const Value.absent(),
            required DateTime dueDate,
            required String status,
            Value<String> purpose = const Value.absent(),
            required DateTime disbursedOn,
            Value<int> rowid = const Value.absent(),
          }) =>
              LoansCompanion.insert(
            id: id,
            memberId: memberId,
            memberName: memberName,
            principal: principal,
            interestRate: interestRate,
            durationMonths: durationMonths,
            dueDate: dueDate,
            status: status,
            purpose: purpose,
            disbursedOn: disbursedOn,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LoansTable,
    Loan,
    $$LoansTableFilterComposer,
    $$LoansTableOrderingComposer,
    $$LoansTableAnnotationComposer,
    $$LoansTableCreateCompanionBuilder,
    $$LoansTableUpdateCompanionBuilder,
    (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
    Loan,
    PrefetchHooks Function()>;
typedef $$RepaymentsTableCreateCompanionBuilder = RepaymentsCompanion Function({
  required String id,
  required String loanId,
  required double amount,
  Value<String> method,
  required DateTime date,
  Value<int> rowid,
});
typedef $$RepaymentsTableUpdateCompanionBuilder = RepaymentsCompanion Function({
  Value<String> id,
  Value<String> loanId,
  Value<double> amount,
  Value<String> method,
  Value<DateTime> date,
  Value<int> rowid,
});

class $$RepaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $RepaymentsTable> {
  $$RepaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loanId => $composableBuilder(
      column: $table.loanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));
}

class $$RepaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RepaymentsTable> {
  $$RepaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loanId => $composableBuilder(
      column: $table.loanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));
}

class $$RepaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RepaymentsTable> {
  $$RepaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get loanId =>
      $composableBuilder(column: $table.loanId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$RepaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RepaymentsTable,
    Repayment,
    $$RepaymentsTableFilterComposer,
    $$RepaymentsTableOrderingComposer,
    $$RepaymentsTableAnnotationComposer,
    $$RepaymentsTableCreateCompanionBuilder,
    $$RepaymentsTableUpdateCompanionBuilder,
    (Repayment, BaseReferences<_$AppDatabase, $RepaymentsTable, Repayment>),
    Repayment,
    PrefetchHooks Function()> {
  $$RepaymentsTableTableManager(_$AppDatabase db, $RepaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RepaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RepaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RepaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> loanId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RepaymentsCompanion(
            id: id,
            loanId: loanId,
            amount: amount,
            method: method,
            date: date,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String loanId,
            required double amount,
            Value<String> method = const Value.absent(),
            required DateTime date,
            Value<int> rowid = const Value.absent(),
          }) =>
              RepaymentsCompanion.insert(
            id: id,
            loanId: loanId,
            amount: amount,
            method: method,
            date: date,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RepaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RepaymentsTable,
    Repayment,
    $$RepaymentsTableFilterComposer,
    $$RepaymentsTableOrderingComposer,
    $$RepaymentsTableAnnotationComposer,
    $$RepaymentsTableCreateCompanionBuilder,
    $$RepaymentsTableUpdateCompanionBuilder,
    (Repayment, BaseReferences<_$AppDatabase, $RepaymentsTable, Repayment>),
    Repayment,
    PrefetchHooks Function()>;
typedef $$FinesTableCreateCompanionBuilder = FinesCompanion Function({
  required String id,
  required String memberId,
  required String reason,
  required double amount,
  Value<bool> paid,
  required DateTime date,
  Value<int> rowid,
});
typedef $$FinesTableUpdateCompanionBuilder = FinesCompanion Function({
  Value<String> id,
  Value<String> memberId,
  Value<String> reason,
  Value<double> amount,
  Value<bool> paid,
  Value<DateTime> date,
  Value<int> rowid,
});

class $$FinesTableFilterComposer extends Composer<_$AppDatabase, $FinesTable> {
  $$FinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get paid => $composableBuilder(
      column: $table.paid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));
}

class $$FinesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinesTable> {
  $$FinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get paid => $composableBuilder(
      column: $table.paid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));
}

class $$FinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinesTable> {
  $$FinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get paid =>
      $composableBuilder(column: $table.paid, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$FinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinesTable,
    Fine,
    $$FinesTableFilterComposer,
    $$FinesTableOrderingComposer,
    $$FinesTableAnnotationComposer,
    $$FinesTableCreateCompanionBuilder,
    $$FinesTableUpdateCompanionBuilder,
    (Fine, BaseReferences<_$AppDatabase, $FinesTable, Fine>),
    Fine,
    PrefetchHooks Function()> {
  $$FinesTableTableManager(_$AppDatabase db, $FinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memberId = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<bool> paid = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FinesCompanion(
            id: id,
            memberId: memberId,
            reason: reason,
            amount: amount,
            paid: paid,
            date: date,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memberId,
            required String reason,
            required double amount,
            Value<bool> paid = const Value.absent(),
            required DateTime date,
            Value<int> rowid = const Value.absent(),
          }) =>
              FinesCompanion.insert(
            id: id,
            memberId: memberId,
            reason: reason,
            amount: amount,
            paid: paid,
            date: date,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FinesTable,
    Fine,
    $$FinesTableFilterComposer,
    $$FinesTableOrderingComposer,
    $$FinesTableAnnotationComposer,
    $$FinesTableCreateCompanionBuilder,
    $$FinesTableUpdateCompanionBuilder,
    (Fine, BaseReferences<_$AppDatabase, $FinesTable, Fine>),
    Fine,
    PrefetchHooks Function()>;
typedef $$MeetingsTableCreateCompanionBuilder = MeetingsCompanion Function({
  required String id,
  required int number,
  required DateTime date,
  Value<int> attended,
  Value<int> total,
  Value<int> agendaItems,
  Value<int> decisions,
  Value<double> collections,
  Value<double> fines,
  Value<int> rowid,
});
typedef $$MeetingsTableUpdateCompanionBuilder = MeetingsCompanion Function({
  Value<String> id,
  Value<int> number,
  Value<DateTime> date,
  Value<int> attended,
  Value<int> total,
  Value<int> agendaItems,
  Value<int> decisions,
  Value<double> collections,
  Value<double> fines,
  Value<int> rowid,
});

class $$MeetingsTableFilterComposer
    extends Composer<_$AppDatabase, $MeetingsTable> {
  $$MeetingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attended => $composableBuilder(
      column: $table.attended, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get agendaItems => $composableBuilder(
      column: $table.agendaItems, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get decisions => $composableBuilder(
      column: $table.decisions, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get collections => $composableBuilder(
      column: $table.collections, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fines => $composableBuilder(
      column: $table.fines, builder: (column) => ColumnFilters(column));
}

class $$MeetingsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeetingsTable> {
  $$MeetingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attended => $composableBuilder(
      column: $table.attended, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get agendaItems => $composableBuilder(
      column: $table.agendaItems, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get decisions => $composableBuilder(
      column: $table.decisions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get collections => $composableBuilder(
      column: $table.collections, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fines => $composableBuilder(
      column: $table.fines, builder: (column) => ColumnOrderings(column));
}

class $$MeetingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeetingsTable> {
  $$MeetingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get attended =>
      $composableBuilder(column: $table.attended, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get agendaItems => $composableBuilder(
      column: $table.agendaItems, builder: (column) => column);

  GeneratedColumn<int> get decisions =>
      $composableBuilder(column: $table.decisions, builder: (column) => column);

  GeneratedColumn<double> get collections => $composableBuilder(
      column: $table.collections, builder: (column) => column);

  GeneratedColumn<double> get fines =>
      $composableBuilder(column: $table.fines, builder: (column) => column);
}

class $$MeetingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeetingsTable,
    Meeting,
    $$MeetingsTableFilterComposer,
    $$MeetingsTableOrderingComposer,
    $$MeetingsTableAnnotationComposer,
    $$MeetingsTableCreateCompanionBuilder,
    $$MeetingsTableUpdateCompanionBuilder,
    (Meeting, BaseReferences<_$AppDatabase, $MeetingsTable, Meeting>),
    Meeting,
    PrefetchHooks Function()> {
  $$MeetingsTableTableManager(_$AppDatabase db, $MeetingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeetingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> number = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> attended = const Value.absent(),
            Value<int> total = const Value.absent(),
            Value<int> agendaItems = const Value.absent(),
            Value<int> decisions = const Value.absent(),
            Value<double> collections = const Value.absent(),
            Value<double> fines = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingsCompanion(
            id: id,
            number: number,
            date: date,
            attended: attended,
            total: total,
            agendaItems: agendaItems,
            decisions: decisions,
            collections: collections,
            fines: fines,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int number,
            required DateTime date,
            Value<int> attended = const Value.absent(),
            Value<int> total = const Value.absent(),
            Value<int> agendaItems = const Value.absent(),
            Value<int> decisions = const Value.absent(),
            Value<double> collections = const Value.absent(),
            Value<double> fines = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingsCompanion.insert(
            id: id,
            number: number,
            date: date,
            attended: attended,
            total: total,
            agendaItems: agendaItems,
            decisions: decisions,
            collections: collections,
            fines: fines,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MeetingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeetingsTable,
    Meeting,
    $$MeetingsTableFilterComposer,
    $$MeetingsTableOrderingComposer,
    $$MeetingsTableAnnotationComposer,
    $$MeetingsTableCreateCompanionBuilder,
    $$MeetingsTableUpdateCompanionBuilder,
    (Meeting, BaseReferences<_$AppDatabase, $MeetingsTable, Meeting>),
    Meeting,
    PrefetchHooks Function()>;
typedef $$OfficersTableCreateCompanionBuilder = OfficersCompanion Function({
  required String id,
  required String memberName,
  required String role,
  Value<String> phone,
  Value<int> rowid,
});
typedef $$OfficersTableUpdateCompanionBuilder = OfficersCompanion Function({
  Value<String> id,
  Value<String> memberName,
  Value<String> role,
  Value<String> phone,
  Value<int> rowid,
});

class $$OfficersTableFilterComposer
    extends Composer<_$AppDatabase, $OfficersTable> {
  $$OfficersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberName => $composableBuilder(
      column: $table.memberName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));
}

class $$OfficersTableOrderingComposer
    extends Composer<_$AppDatabase, $OfficersTable> {
  $$OfficersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberName => $composableBuilder(
      column: $table.memberName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));
}

class $$OfficersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfficersTable> {
  $$OfficersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memberName => $composableBuilder(
      column: $table.memberName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);
}

class $$OfficersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OfficersTable,
    Officer,
    $$OfficersTableFilterComposer,
    $$OfficersTableOrderingComposer,
    $$OfficersTableAnnotationComposer,
    $$OfficersTableCreateCompanionBuilder,
    $$OfficersTableUpdateCompanionBuilder,
    (Officer, BaseReferences<_$AppDatabase, $OfficersTable, Officer>),
    Officer,
    PrefetchHooks Function()> {
  $$OfficersTableTableManager(_$AppDatabase db, $OfficersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfficersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfficersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfficersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memberName = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OfficersCompanion(
            id: id,
            memberName: memberName,
            role: role,
            phone: phone,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memberName,
            required String role,
            Value<String> phone = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OfficersCompanion.insert(
            id: id,
            memberName: memberName,
            role: role,
            phone: phone,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfficersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OfficersTable,
    Officer,
    $$OfficersTableFilterComposer,
    $$OfficersTableOrderingComposer,
    $$OfficersTableAnnotationComposer,
    $$OfficersTableCreateCompanionBuilder,
    $$OfficersTableUpdateCompanionBuilder,
    (Officer, BaseReferences<_$AppDatabase, $OfficersTable, Officer>),
    Officer,
    PrefetchHooks Function()>;
typedef $$LoanGuarantorsTableCreateCompanionBuilder = LoanGuarantorsCompanion
    Function({
  required String loanId,
  required String memberId,
  Value<int> rowid,
});
typedef $$LoanGuarantorsTableUpdateCompanionBuilder = LoanGuarantorsCompanion
    Function({
  Value<String> loanId,
  Value<String> memberId,
  Value<int> rowid,
});

class $$LoanGuarantorsTableFilterComposer
    extends Composer<_$AppDatabase, $LoanGuarantorsTable> {
  $$LoanGuarantorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get loanId => $composableBuilder(
      column: $table.loanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));
}

class $$LoanGuarantorsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoanGuarantorsTable> {
  $$LoanGuarantorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get loanId => $composableBuilder(
      column: $table.loanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));
}

class $$LoanGuarantorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoanGuarantorsTable> {
  $$LoanGuarantorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get loanId =>
      $composableBuilder(column: $table.loanId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);
}

class $$LoanGuarantorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LoanGuarantorsTable,
    LoanGuarantor,
    $$LoanGuarantorsTableFilterComposer,
    $$LoanGuarantorsTableOrderingComposer,
    $$LoanGuarantorsTableAnnotationComposer,
    $$LoanGuarantorsTableCreateCompanionBuilder,
    $$LoanGuarantorsTableUpdateCompanionBuilder,
    (
      LoanGuarantor,
      BaseReferences<_$AppDatabase, $LoanGuarantorsTable, LoanGuarantor>
    ),
    LoanGuarantor,
    PrefetchHooks Function()> {
  $$LoanGuarantorsTableTableManager(
      _$AppDatabase db, $LoanGuarantorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoanGuarantorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoanGuarantorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoanGuarantorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> loanId = const Value.absent(),
            Value<String> memberId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoanGuarantorsCompanion(
            loanId: loanId,
            memberId: memberId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String loanId,
            required String memberId,
            Value<int> rowid = const Value.absent(),
          }) =>
              LoanGuarantorsCompanion.insert(
            loanId: loanId,
            memberId: memberId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoanGuarantorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LoanGuarantorsTable,
    LoanGuarantor,
    $$LoanGuarantorsTableFilterComposer,
    $$LoanGuarantorsTableOrderingComposer,
    $$LoanGuarantorsTableAnnotationComposer,
    $$LoanGuarantorsTableCreateCompanionBuilder,
    $$LoanGuarantorsTableUpdateCompanionBuilder,
    (
      LoanGuarantor,
      BaseReferences<_$AppDatabase, $LoanGuarantorsTable, LoanGuarantor>
    ),
    LoanGuarantor,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GroupSettingsTableTableManager get groupSettings =>
      $$GroupSettingsTableTableManager(_db, _db.groupSettings);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$SavingsTableTableManager get savings =>
      $$SavingsTableTableManager(_db, _db.savings);
  $$ShareTxTableTableManager get shareTx =>
      $$ShareTxTableTableManager(_db, _db.shareTx);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$RepaymentsTableTableManager get repayments =>
      $$RepaymentsTableTableManager(_db, _db.repayments);
  $$FinesTableTableManager get fines =>
      $$FinesTableTableManager(_db, _db.fines);
  $$MeetingsTableTableManager get meetings =>
      $$MeetingsTableTableManager(_db, _db.meetings);
  $$OfficersTableTableManager get officers =>
      $$OfficersTableTableManager(_db, _db.officers);
  $$LoanGuarantorsTableTableManager get loanGuarantors =>
      $$LoanGuarantorsTableTableManager(_db, _db.loanGuarantors);
}
