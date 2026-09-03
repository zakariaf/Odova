// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VehiclesTable extends Vehicles
    with TableInfo<$VehiclesTable, VehicleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _makeMeta = const VerificationMeta('make');
  @override
  late final GeneratedColumn<String> make = GeneratedColumn<String>(
    'make',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plateMeta = const VerificationMeta('plate');
  @override
  late final GeneratedColumn<String> plate = GeneratedColumn<String>(
    'plate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vinMeta = const VerificationMeta('vin');
  @override
  late final GeneratedColumn<String> vin = GeneratedColumn<String>(
    'vin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vehicleTypeMeta = const VerificationMeta(
    'vehicleType',
  );
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
    'vehicle_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (vehicle_type IN (\'car\', \'van\', \'motorcycle\', \'truck\', \'other\'))',
  );
  static const VerificationMeta _isBusinessMeta = const VerificationMeta(
    'isBusiness',
  );
  @override
  late final GeneratedColumn<bool> isBusiness = GeneratedColumn<bool>(
    'is_business',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_business" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fuelKindDefaultMeta = const VerificationMeta(
    'fuelKindDefault',
  );
  @override
  late final GeneratedColumn<String> fuelKindDefault = GeneratedColumn<String>(
    'fuel_kind_default',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (fuel_kind_default IN (\'petrol\', \'diesel\', \'lpg\', \'cng\', \'electric\', \'hybrid\', \'other\'))',
  );
  static const VerificationMeta _tankCapacityMlMeta = const VerificationMeta(
    'tankCapacityMl',
  );
  @override
  late final GeneratedColumn<int> tankCapacityMl = GeneratedColumn<int>(
    'tank_capacity_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (tank_capacity_ml IS NULL OR tank_capacity_ml > 0)',
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseOdometerMMeta = const VerificationMeta(
    'purchaseOdometerM',
  );
  @override
  late final GeneratedColumn<int> purchaseOdometerM = GeneratedColumn<int>(
    'purchase_odometer_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceMinorMeta =
      const VerificationMeta('purchasePriceMinor');
  @override
  late final GeneratedColumn<int> purchasePriceMinor = GeneratedColumn<int>(
    'purchase_price_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceCurrencyMeta =
      const VerificationMeta('purchasePriceCurrency');
  @override
  late final GeneratedColumn<String>
  purchasePriceCurrency = GeneratedColumn<String>(
    'purchase_price_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (purchase_price_currency IS NULL OR length(purchase_price_currency) = 3)',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status IN (\'active\', \'archived\', \'sold\'))',
  );
  static const VerificationMeta _soldOnMeta = const VerificationMeta('soldOn');
  @override
  late final GeneratedColumn<String> soldOn = GeneratedColumn<String>(
    'sold_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soldPriceMinorMeta = const VerificationMeta(
    'soldPriceMinor',
  );
  @override
  late final GeneratedColumn<int> soldPriceMinor = GeneratedColumn<int>(
    'sold_price_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soldPriceCurrencyMeta = const VerificationMeta(
    'soldPriceCurrency',
  );
  @override
  late final GeneratedColumn<String>
  soldPriceCurrency = GeneratedColumn<String>(
    'sold_price_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (sold_price_currency IS NULL OR length(sold_price_currency) = 3)',
  );
  static const VerificationMeta _expectedAnnualMMeta = const VerificationMeta(
    'expectedAnnualM',
  );
  @override
  late final GeneratedColumn<int> expectedAnnualM = GeneratedColumn<int>(
    'expected_annual_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
    'colour',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notificationsMutedMeta =
      const VerificationMeta('notificationsMuted');
  @override
  late final GeneratedColumn<bool> notificationsMuted = GeneratedColumn<bool>(
    'notifications_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (currency IS NULL OR length(currency) = 3)',
  );
  static const VerificationMeta _distanceUnitMeta = const VerificationMeta(
    'distanceUnit',
  );
  @override
  late final GeneratedColumn<String> distanceUnit = GeneratedColumn<String>(
    'distance_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (distance_unit IN (\'km\', \'mi\'))',
  );
  static const VerificationMeta _volumeUnitMeta = const VerificationMeta(
    'volumeUnit',
  );
  @override
  late final GeneratedColumn<String> volumeUnit = GeneratedColumn<String>(
    'volume_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (volume_unit IN (\'l\', \'gal_us\', \'gal_uk\'))',
  );
  static const VerificationMeta _consumptionUnitMeta = const VerificationMeta(
    'consumptionUnit',
  );
  @override
  late final GeneratedColumn<String> consumptionUnit = GeneratedColumn<String>(
    'consumption_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (consumption_unit IN (\'l_100km\', \'km_l\', \'mpg_us\', \'mpg_uk\', \'kwh_100km\', \'mi_kwh\'))',
  );
  static const VerificationMeta _noticeDistanceMMeta = const VerificationMeta(
    'noticeDistanceM',
  );
  @override
  late final GeneratedColumn<int> noticeDistanceM = GeneratedColumn<int>(
    'notice_distance_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noticeDaysMeta = const VerificationMeta(
    'noticeDays',
  );
  @override
  late final GeneratedColumn<int> noticeDays = GeneratedColumn<int>(
    'notice_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    deletedAtUtcMs,
    name,
    make,
    model,
    year,
    plate,
    vin,
    vehicleType,
    isBusiness,
    fuelKindDefault,
    tankCapacityMl,
    purchaseDate,
    purchaseOdometerM,
    purchasePriceMinor,
    purchasePriceCurrency,
    status,
    soldOn,
    soldPriceMinor,
    soldPriceCurrency,
    expectedAnnualM,
    colour,
    notes,
    sortOrder,
    notificationsMuted,
    currency,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
    noticeDistanceM,
    noticeDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<VehicleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('make')) {
      context.handle(
        _makeMeta,
        make.isAcceptableOrUnknown(data['make']!, _makeMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('plate')) {
      context.handle(
        _plateMeta,
        plate.isAcceptableOrUnknown(data['plate']!, _plateMeta),
      );
    }
    if (data.containsKey('vin')) {
      context.handle(
        _vinMeta,
        vin.isAcceptableOrUnknown(data['vin']!, _vinMeta),
      );
    }
    if (data.containsKey('vehicle_type')) {
      context.handle(
        _vehicleTypeMeta,
        vehicleType.isAcceptableOrUnknown(
          data['vehicle_type']!,
          _vehicleTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vehicleTypeMeta);
    }
    if (data.containsKey('is_business')) {
      context.handle(
        _isBusinessMeta,
        isBusiness.isAcceptableOrUnknown(data['is_business']!, _isBusinessMeta),
      );
    }
    if (data.containsKey('fuel_kind_default')) {
      context.handle(
        _fuelKindDefaultMeta,
        fuelKindDefault.isAcceptableOrUnknown(
          data['fuel_kind_default']!,
          _fuelKindDefaultMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fuelKindDefaultMeta);
    }
    if (data.containsKey('tank_capacity_ml')) {
      context.handle(
        _tankCapacityMlMeta,
        tankCapacityMl.isAcceptableOrUnknown(
          data['tank_capacity_ml']!,
          _tankCapacityMlMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('purchase_odometer_m')) {
      context.handle(
        _purchaseOdometerMMeta,
        purchaseOdometerM.isAcceptableOrUnknown(
          data['purchase_odometer_m']!,
          _purchaseOdometerMMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price_minor')) {
      context.handle(
        _purchasePriceMinorMeta,
        purchasePriceMinor.isAcceptableOrUnknown(
          data['purchase_price_minor']!,
          _purchasePriceMinorMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price_currency')) {
      context.handle(
        _purchasePriceCurrencyMeta,
        purchasePriceCurrency.isAcceptableOrUnknown(
          data['purchase_price_currency']!,
          _purchasePriceCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sold_on')) {
      context.handle(
        _soldOnMeta,
        soldOn.isAcceptableOrUnknown(data['sold_on']!, _soldOnMeta),
      );
    }
    if (data.containsKey('sold_price_minor')) {
      context.handle(
        _soldPriceMinorMeta,
        soldPriceMinor.isAcceptableOrUnknown(
          data['sold_price_minor']!,
          _soldPriceMinorMeta,
        ),
      );
    }
    if (data.containsKey('sold_price_currency')) {
      context.handle(
        _soldPriceCurrencyMeta,
        soldPriceCurrency.isAcceptableOrUnknown(
          data['sold_price_currency']!,
          _soldPriceCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('expected_annual_m')) {
      context.handle(
        _expectedAnnualMMeta,
        expectedAnnualM.isAcceptableOrUnknown(
          data['expected_annual_m']!,
          _expectedAnnualMMeta,
        ),
      );
    }
    if (data.containsKey('colour')) {
      context.handle(
        _colourMeta,
        colour.isAcceptableOrUnknown(data['colour']!, _colourMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('notifications_muted')) {
      context.handle(
        _notificationsMutedMeta,
        notificationsMuted.isAcceptableOrUnknown(
          data['notifications_muted']!,
          _notificationsMutedMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('distance_unit')) {
      context.handle(
        _distanceUnitMeta,
        distanceUnit.isAcceptableOrUnknown(
          data['distance_unit']!,
          _distanceUnitMeta,
        ),
      );
    }
    if (data.containsKey('volume_unit')) {
      context.handle(
        _volumeUnitMeta,
        volumeUnit.isAcceptableOrUnknown(data['volume_unit']!, _volumeUnitMeta),
      );
    }
    if (data.containsKey('consumption_unit')) {
      context.handle(
        _consumptionUnitMeta,
        consumptionUnit.isAcceptableOrUnknown(
          data['consumption_unit']!,
          _consumptionUnitMeta,
        ),
      );
    }
    if (data.containsKey('notice_distance_m')) {
      context.handle(
        _noticeDistanceMMeta,
        noticeDistanceM.isAcceptableOrUnknown(
          data['notice_distance_m']!,
          _noticeDistanceMMeta,
        ),
      );
    }
    if (data.containsKey('notice_days')) {
      context.handle(
        _noticeDaysMeta,
        noticeDays.isAcceptableOrUnknown(data['notice_days']!, _noticeDaysMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VehicleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VehicleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      make: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}make'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      plate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plate'],
      ),
      vin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vin'],
      ),
      vehicleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_type'],
      )!,
      isBusiness: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_business'],
      )!,
      fuelKindDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_kind_default'],
      )!,
      tankCapacityMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tank_capacity_ml'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      ),
      purchaseOdometerM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_odometer_m'],
      ),
      purchasePriceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_price_minor'],
      ),
      purchasePriceCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_price_currency'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      soldOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sold_on'],
      ),
      soldPriceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sold_price_minor'],
      ),
      soldPriceCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sold_price_currency'],
      ),
      expectedAnnualM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_annual_m'],
      ),
      colour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colour'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      notificationsMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_muted'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      distanceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_unit'],
      ),
      volumeUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_unit'],
      ),
      consumptionUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consumption_unit'],
      ),
      noticeDistanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notice_distance_m'],
      ),
      noticeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notice_days'],
      ),
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class VehicleRow extends DataClass implements Insertable<VehicleRow> {
  /// `<prefix>_<ULID>`; see `RecordId`.
  final String id;

  /// When the row was first written. UTC epoch milliseconds.
  final int createdAtUtcMs;

  /// When it was last changed. UTC epoch milliseconds.
  ///
  /// Never less than [createdAtUtcMs] — but repaired on READ rather than
  /// blocked on write. See `repairAuditTimes`.
  final int updatedAtUtcMs;

  /// When it was soft-deleted, or null.
  ///
  /// Soft delete is what makes Undo possible for the length of a snackbar.
  /// After that the row is purged, so a settled database has this null on
  /// every row that exists.
  final int? deletedAtUtcMs;

  /// What the user calls it: "The Golf", "Van".
  final String name;

  /// Manufacturer.
  final String? make;

  /// Model.
  final String? model;

  /// Model year.
  final int? year;

  /// Registration plate. Stored verbatim — an Iranian plate legitimately
  /// contains Persian digits and a Persian letter, so it is transcribed and
  /// never shaped or folded.
  final String? plate;

  /// Vehicle identification number.
  final String? vin;

  /// Drives the icon and which catalogue items seed.
  final String vehicleType;

  /// Drives the business/personal cost split.
  final bool isBusiness;

  /// What it burns. Decides which of a fill-up's three quantity columns is
  /// the non-null one.
  final String fuelKindDefault;

  /// Tank size in millilitres. A sanity check on a fill-up, never used in
  /// maths — SPEC.md §3 says so explicitly, because a "full tank" that
  /// exceeds it is a typo worth querying and not a number worth trusting.
  final int? tankCapacityMl;

  /// When it was bought.
  final String? purchaseDate;

  /// The odometer at purchase, in metres.
  final int? purchaseOdometerM;

  /// What it cost, in minor units.
  final int? purchasePriceMinor;

  /// The currency [purchasePriceMinor] is in.
  final String? purchasePriceCurrency;

  /// Where it is in its life with the user.
  final String status;

  /// When it was sold.
  final String? soldOn;

  /// What it sold for, in minor units.
  final int? soldPriceMinor;

  /// The currency [soldPriceMinor] is in.
  final String? soldPriceCurrency;

  /// Expected annual distance in metres, asked once at onboarding.
  ///
  /// Feeds the rate fallback: a vehicle with two readings a year apart has no
  /// usable rate, and this is what the projection uses instead of inventing
  /// one.
  final int? expectedAnnualM;

  /// A swatch key. v1 has no vehicle photo.
  final String? colour;

  /// Free text.
  final String? notes;

  /// Where it sits in the garage list.
  final int sortOrder;

  /// Whether this vehicle's reminders are silenced.
  final bool notificationsMuted;

  /// Overrides `settings.currency_default`.
  /// `withLength` is a DART-side validator that emits nothing into the
  /// schema, so a two-letter code written by an import or a migration was
  /// accepted — and the exponent that turns 4599 into 45.99 comes from the
  /// code. The check has to be in SQL.
  final String? currency;

  /// Overrides `settings.distance_unit`.
  final String? distanceUnit;

  /// Overrides `settings.volume_unit`.
  final String? volumeUnit;

  /// Overrides `settings.consumption_unit`.
  final String? consumptionUnit;

  /// Overrides the computed distance notice window, in metres.
  final int? noticeDistanceM;

  /// Overrides the computed time notice window, in days.
  final int? noticeDays;
  const VehicleRow({
    required this.id,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.deletedAtUtcMs,
    required this.name,
    this.make,
    this.model,
    this.year,
    this.plate,
    this.vin,
    required this.vehicleType,
    required this.isBusiness,
    required this.fuelKindDefault,
    this.tankCapacityMl,
    this.purchaseDate,
    this.purchaseOdometerM,
    this.purchasePriceMinor,
    this.purchasePriceCurrency,
    required this.status,
    this.soldOn,
    this.soldPriceMinor,
    this.soldPriceCurrency,
    this.expectedAnnualM,
    this.colour,
    this.notes,
    required this.sortOrder,
    required this.notificationsMuted,
    this.currency,
    this.distanceUnit,
    this.volumeUnit,
    this.consumptionUnit,
    this.noticeDistanceM,
    this.noticeDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || make != null) {
      map['make'] = Variable<String>(make);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || plate != null) {
      map['plate'] = Variable<String>(plate);
    }
    if (!nullToAbsent || vin != null) {
      map['vin'] = Variable<String>(vin);
    }
    map['vehicle_type'] = Variable<String>(vehicleType);
    map['is_business'] = Variable<bool>(isBusiness);
    map['fuel_kind_default'] = Variable<String>(fuelKindDefault);
    if (!nullToAbsent || tankCapacityMl != null) {
      map['tank_capacity_ml'] = Variable<int>(tankCapacityMl);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<String>(purchaseDate);
    }
    if (!nullToAbsent || purchaseOdometerM != null) {
      map['purchase_odometer_m'] = Variable<int>(purchaseOdometerM);
    }
    if (!nullToAbsent || purchasePriceMinor != null) {
      map['purchase_price_minor'] = Variable<int>(purchasePriceMinor);
    }
    if (!nullToAbsent || purchasePriceCurrency != null) {
      map['purchase_price_currency'] = Variable<String>(purchasePriceCurrency);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || soldOn != null) {
      map['sold_on'] = Variable<String>(soldOn);
    }
    if (!nullToAbsent || soldPriceMinor != null) {
      map['sold_price_minor'] = Variable<int>(soldPriceMinor);
    }
    if (!nullToAbsent || soldPriceCurrency != null) {
      map['sold_price_currency'] = Variable<String>(soldPriceCurrency);
    }
    if (!nullToAbsent || expectedAnnualM != null) {
      map['expected_annual_m'] = Variable<int>(expectedAnnualM);
    }
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<String>(colour);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['notifications_muted'] = Variable<bool>(notificationsMuted);
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || distanceUnit != null) {
      map['distance_unit'] = Variable<String>(distanceUnit);
    }
    if (!nullToAbsent || volumeUnit != null) {
      map['volume_unit'] = Variable<String>(volumeUnit);
    }
    if (!nullToAbsent || consumptionUnit != null) {
      map['consumption_unit'] = Variable<String>(consumptionUnit);
    }
    if (!nullToAbsent || noticeDistanceM != null) {
      map['notice_distance_m'] = Variable<int>(noticeDistanceM);
    }
    if (!nullToAbsent || noticeDays != null) {
      map['notice_days'] = Variable<int>(noticeDays);
    }
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      name: Value(name),
      make: make == null && nullToAbsent ? const Value.absent() : Value(make),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      plate: plate == null && nullToAbsent
          ? const Value.absent()
          : Value(plate),
      vin: vin == null && nullToAbsent ? const Value.absent() : Value(vin),
      vehicleType: Value(vehicleType),
      isBusiness: Value(isBusiness),
      fuelKindDefault: Value(fuelKindDefault),
      tankCapacityMl: tankCapacityMl == null && nullToAbsent
          ? const Value.absent()
          : Value(tankCapacityMl),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      purchaseOdometerM: purchaseOdometerM == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseOdometerM),
      purchasePriceMinor: purchasePriceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePriceMinor),
      purchasePriceCurrency: purchasePriceCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePriceCurrency),
      status: Value(status),
      soldOn: soldOn == null && nullToAbsent
          ? const Value.absent()
          : Value(soldOn),
      soldPriceMinor: soldPriceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(soldPriceMinor),
      soldPriceCurrency: soldPriceCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(soldPriceCurrency),
      expectedAnnualM: expectedAnnualM == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedAnnualM),
      colour: colour == null && nullToAbsent
          ? const Value.absent()
          : Value(colour),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sortOrder: Value(sortOrder),
      notificationsMuted: Value(notificationsMuted),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      distanceUnit: distanceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceUnit),
      volumeUnit: volumeUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeUnit),
      consumptionUnit: consumptionUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(consumptionUnit),
      noticeDistanceM: noticeDistanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(noticeDistanceM),
      noticeDays: noticeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(noticeDays),
    );
  }

  factory VehicleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VehicleRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      name: serializer.fromJson<String>(json['name']),
      make: serializer.fromJson<String?>(json['make']),
      model: serializer.fromJson<String?>(json['model']),
      year: serializer.fromJson<int?>(json['year']),
      plate: serializer.fromJson<String?>(json['plate']),
      vin: serializer.fromJson<String?>(json['vin']),
      vehicleType: serializer.fromJson<String>(json['vehicleType']),
      isBusiness: serializer.fromJson<bool>(json['isBusiness']),
      fuelKindDefault: serializer.fromJson<String>(json['fuelKindDefault']),
      tankCapacityMl: serializer.fromJson<int?>(json['tankCapacityMl']),
      purchaseDate: serializer.fromJson<String?>(json['purchaseDate']),
      purchaseOdometerM: serializer.fromJson<int?>(json['purchaseOdometerM']),
      purchasePriceMinor: serializer.fromJson<int?>(json['purchasePriceMinor']),
      purchasePriceCurrency: serializer.fromJson<String?>(
        json['purchasePriceCurrency'],
      ),
      status: serializer.fromJson<String>(json['status']),
      soldOn: serializer.fromJson<String?>(json['soldOn']),
      soldPriceMinor: serializer.fromJson<int?>(json['soldPriceMinor']),
      soldPriceCurrency: serializer.fromJson<String?>(
        json['soldPriceCurrency'],
      ),
      expectedAnnualM: serializer.fromJson<int?>(json['expectedAnnualM']),
      colour: serializer.fromJson<String?>(json['colour']),
      notes: serializer.fromJson<String?>(json['notes']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      notificationsMuted: serializer.fromJson<bool>(json['notificationsMuted']),
      currency: serializer.fromJson<String?>(json['currency']),
      distanceUnit: serializer.fromJson<String?>(json['distanceUnit']),
      volumeUnit: serializer.fromJson<String?>(json['volumeUnit']),
      consumptionUnit: serializer.fromJson<String?>(json['consumptionUnit']),
      noticeDistanceM: serializer.fromJson<int?>(json['noticeDistanceM']),
      noticeDays: serializer.fromJson<int?>(json['noticeDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'name': serializer.toJson<String>(name),
      'make': serializer.toJson<String?>(make),
      'model': serializer.toJson<String?>(model),
      'year': serializer.toJson<int?>(year),
      'plate': serializer.toJson<String?>(plate),
      'vin': serializer.toJson<String?>(vin),
      'vehicleType': serializer.toJson<String>(vehicleType),
      'isBusiness': serializer.toJson<bool>(isBusiness),
      'fuelKindDefault': serializer.toJson<String>(fuelKindDefault),
      'tankCapacityMl': serializer.toJson<int?>(tankCapacityMl),
      'purchaseDate': serializer.toJson<String?>(purchaseDate),
      'purchaseOdometerM': serializer.toJson<int?>(purchaseOdometerM),
      'purchasePriceMinor': serializer.toJson<int?>(purchasePriceMinor),
      'purchasePriceCurrency': serializer.toJson<String?>(
        purchasePriceCurrency,
      ),
      'status': serializer.toJson<String>(status),
      'soldOn': serializer.toJson<String?>(soldOn),
      'soldPriceMinor': serializer.toJson<int?>(soldPriceMinor),
      'soldPriceCurrency': serializer.toJson<String?>(soldPriceCurrency),
      'expectedAnnualM': serializer.toJson<int?>(expectedAnnualM),
      'colour': serializer.toJson<String?>(colour),
      'notes': serializer.toJson<String?>(notes),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'notificationsMuted': serializer.toJson<bool>(notificationsMuted),
      'currency': serializer.toJson<String?>(currency),
      'distanceUnit': serializer.toJson<String?>(distanceUnit),
      'volumeUnit': serializer.toJson<String?>(volumeUnit),
      'consumptionUnit': serializer.toJson<String?>(consumptionUnit),
      'noticeDistanceM': serializer.toJson<int?>(noticeDistanceM),
      'noticeDays': serializer.toJson<int?>(noticeDays),
    };
  }

  VehicleRow copyWith({
    String? id,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    String? name,
    Value<String?> make = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> plate = const Value.absent(),
    Value<String?> vin = const Value.absent(),
    String? vehicleType,
    bool? isBusiness,
    String? fuelKindDefault,
    Value<int?> tankCapacityMl = const Value.absent(),
    Value<String?> purchaseDate = const Value.absent(),
    Value<int?> purchaseOdometerM = const Value.absent(),
    Value<int?> purchasePriceMinor = const Value.absent(),
    Value<String?> purchasePriceCurrency = const Value.absent(),
    String? status,
    Value<String?> soldOn = const Value.absent(),
    Value<int?> soldPriceMinor = const Value.absent(),
    Value<String?> soldPriceCurrency = const Value.absent(),
    Value<int?> expectedAnnualM = const Value.absent(),
    Value<String?> colour = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? sortOrder,
    bool? notificationsMuted,
    Value<String?> currency = const Value.absent(),
    Value<String?> distanceUnit = const Value.absent(),
    Value<String?> volumeUnit = const Value.absent(),
    Value<String?> consumptionUnit = const Value.absent(),
    Value<int?> noticeDistanceM = const Value.absent(),
    Value<int?> noticeDays = const Value.absent(),
  }) => VehicleRow(
    id: id ?? this.id,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    name: name ?? this.name,
    make: make.present ? make.value : this.make,
    model: model.present ? model.value : this.model,
    year: year.present ? year.value : this.year,
    plate: plate.present ? plate.value : this.plate,
    vin: vin.present ? vin.value : this.vin,
    vehicleType: vehicleType ?? this.vehicleType,
    isBusiness: isBusiness ?? this.isBusiness,
    fuelKindDefault: fuelKindDefault ?? this.fuelKindDefault,
    tankCapacityMl: tankCapacityMl.present
        ? tankCapacityMl.value
        : this.tankCapacityMl,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    purchaseOdometerM: purchaseOdometerM.present
        ? purchaseOdometerM.value
        : this.purchaseOdometerM,
    purchasePriceMinor: purchasePriceMinor.present
        ? purchasePriceMinor.value
        : this.purchasePriceMinor,
    purchasePriceCurrency: purchasePriceCurrency.present
        ? purchasePriceCurrency.value
        : this.purchasePriceCurrency,
    status: status ?? this.status,
    soldOn: soldOn.present ? soldOn.value : this.soldOn,
    soldPriceMinor: soldPriceMinor.present
        ? soldPriceMinor.value
        : this.soldPriceMinor,
    soldPriceCurrency: soldPriceCurrency.present
        ? soldPriceCurrency.value
        : this.soldPriceCurrency,
    expectedAnnualM: expectedAnnualM.present
        ? expectedAnnualM.value
        : this.expectedAnnualM,
    colour: colour.present ? colour.value : this.colour,
    notes: notes.present ? notes.value : this.notes,
    sortOrder: sortOrder ?? this.sortOrder,
    notificationsMuted: notificationsMuted ?? this.notificationsMuted,
    currency: currency.present ? currency.value : this.currency,
    distanceUnit: distanceUnit.present ? distanceUnit.value : this.distanceUnit,
    volumeUnit: volumeUnit.present ? volumeUnit.value : this.volumeUnit,
    consumptionUnit: consumptionUnit.present
        ? consumptionUnit.value
        : this.consumptionUnit,
    noticeDistanceM: noticeDistanceM.present
        ? noticeDistanceM.value
        : this.noticeDistanceM,
    noticeDays: noticeDays.present ? noticeDays.value : this.noticeDays,
  );
  VehicleRow copyWithCompanion(VehiclesCompanion data) {
    return VehicleRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      name: data.name.present ? data.name.value : this.name,
      make: data.make.present ? data.make.value : this.make,
      model: data.model.present ? data.model.value : this.model,
      year: data.year.present ? data.year.value : this.year,
      plate: data.plate.present ? data.plate.value : this.plate,
      vin: data.vin.present ? data.vin.value : this.vin,
      vehicleType: data.vehicleType.present
          ? data.vehicleType.value
          : this.vehicleType,
      isBusiness: data.isBusiness.present
          ? data.isBusiness.value
          : this.isBusiness,
      fuelKindDefault: data.fuelKindDefault.present
          ? data.fuelKindDefault.value
          : this.fuelKindDefault,
      tankCapacityMl: data.tankCapacityMl.present
          ? data.tankCapacityMl.value
          : this.tankCapacityMl,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      purchaseOdometerM: data.purchaseOdometerM.present
          ? data.purchaseOdometerM.value
          : this.purchaseOdometerM,
      purchasePriceMinor: data.purchasePriceMinor.present
          ? data.purchasePriceMinor.value
          : this.purchasePriceMinor,
      purchasePriceCurrency: data.purchasePriceCurrency.present
          ? data.purchasePriceCurrency.value
          : this.purchasePriceCurrency,
      status: data.status.present ? data.status.value : this.status,
      soldOn: data.soldOn.present ? data.soldOn.value : this.soldOn,
      soldPriceMinor: data.soldPriceMinor.present
          ? data.soldPriceMinor.value
          : this.soldPriceMinor,
      soldPriceCurrency: data.soldPriceCurrency.present
          ? data.soldPriceCurrency.value
          : this.soldPriceCurrency,
      expectedAnnualM: data.expectedAnnualM.present
          ? data.expectedAnnualM.value
          : this.expectedAnnualM,
      colour: data.colour.present ? data.colour.value : this.colour,
      notes: data.notes.present ? data.notes.value : this.notes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      notificationsMuted: data.notificationsMuted.present
          ? data.notificationsMuted.value
          : this.notificationsMuted,
      currency: data.currency.present ? data.currency.value : this.currency,
      distanceUnit: data.distanceUnit.present
          ? data.distanceUnit.value
          : this.distanceUnit,
      volumeUnit: data.volumeUnit.present
          ? data.volumeUnit.value
          : this.volumeUnit,
      consumptionUnit: data.consumptionUnit.present
          ? data.consumptionUnit.value
          : this.consumptionUnit,
      noticeDistanceM: data.noticeDistanceM.present
          ? data.noticeDistanceM.value
          : this.noticeDistanceM,
      noticeDays: data.noticeDays.present
          ? data.noticeDays.value
          : this.noticeDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VehicleRow(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('name: $name, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('plate: $plate, ')
          ..write('vin: $vin, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('isBusiness: $isBusiness, ')
          ..write('fuelKindDefault: $fuelKindDefault, ')
          ..write('tankCapacityMl: $tankCapacityMl, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchaseOdometerM: $purchaseOdometerM, ')
          ..write('purchasePriceMinor: $purchasePriceMinor, ')
          ..write('purchasePriceCurrency: $purchasePriceCurrency, ')
          ..write('status: $status, ')
          ..write('soldOn: $soldOn, ')
          ..write('soldPriceMinor: $soldPriceMinor, ')
          ..write('soldPriceCurrency: $soldPriceCurrency, ')
          ..write('expectedAnnualM: $expectedAnnualM, ')
          ..write('colour: $colour, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notificationsMuted: $notificationsMuted, ')
          ..write('currency: $currency, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('volumeUnit: $volumeUnit, ')
          ..write('consumptionUnit: $consumptionUnit, ')
          ..write('noticeDistanceM: $noticeDistanceM, ')
          ..write('noticeDays: $noticeDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    deletedAtUtcMs,
    name,
    make,
    model,
    year,
    plate,
    vin,
    vehicleType,
    isBusiness,
    fuelKindDefault,
    tankCapacityMl,
    purchaseDate,
    purchaseOdometerM,
    purchasePriceMinor,
    purchasePriceCurrency,
    status,
    soldOn,
    soldPriceMinor,
    soldPriceCurrency,
    expectedAnnualM,
    colour,
    notes,
    sortOrder,
    notificationsMuted,
    currency,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
    noticeDistanceM,
    noticeDays,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VehicleRow &&
          other.id == this.id &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.name == this.name &&
          other.make == this.make &&
          other.model == this.model &&
          other.year == this.year &&
          other.plate == this.plate &&
          other.vin == this.vin &&
          other.vehicleType == this.vehicleType &&
          other.isBusiness == this.isBusiness &&
          other.fuelKindDefault == this.fuelKindDefault &&
          other.tankCapacityMl == this.tankCapacityMl &&
          other.purchaseDate == this.purchaseDate &&
          other.purchaseOdometerM == this.purchaseOdometerM &&
          other.purchasePriceMinor == this.purchasePriceMinor &&
          other.purchasePriceCurrency == this.purchasePriceCurrency &&
          other.status == this.status &&
          other.soldOn == this.soldOn &&
          other.soldPriceMinor == this.soldPriceMinor &&
          other.soldPriceCurrency == this.soldPriceCurrency &&
          other.expectedAnnualM == this.expectedAnnualM &&
          other.colour == this.colour &&
          other.notes == this.notes &&
          other.sortOrder == this.sortOrder &&
          other.notificationsMuted == this.notificationsMuted &&
          other.currency == this.currency &&
          other.distanceUnit == this.distanceUnit &&
          other.volumeUnit == this.volumeUnit &&
          other.consumptionUnit == this.consumptionUnit &&
          other.noticeDistanceM == this.noticeDistanceM &&
          other.noticeDays == this.noticeDays);
}

class VehiclesCompanion extends UpdateCompanion<VehicleRow> {
  final Value<String> id;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int?> deletedAtUtcMs;
  final Value<String> name;
  final Value<String?> make;
  final Value<String?> model;
  final Value<int?> year;
  final Value<String?> plate;
  final Value<String?> vin;
  final Value<String> vehicleType;
  final Value<bool> isBusiness;
  final Value<String> fuelKindDefault;
  final Value<int?> tankCapacityMl;
  final Value<String?> purchaseDate;
  final Value<int?> purchaseOdometerM;
  final Value<int?> purchasePriceMinor;
  final Value<String?> purchasePriceCurrency;
  final Value<String> status;
  final Value<String?> soldOn;
  final Value<int?> soldPriceMinor;
  final Value<String?> soldPriceCurrency;
  final Value<int?> expectedAnnualM;
  final Value<String?> colour;
  final Value<String?> notes;
  final Value<int> sortOrder;
  final Value<bool> notificationsMuted;
  final Value<String?> currency;
  final Value<String?> distanceUnit;
  final Value<String?> volumeUnit;
  final Value<String?> consumptionUnit;
  final Value<int?> noticeDistanceM;
  final Value<int?> noticeDays;
  final Value<int> rowid;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.name = const Value.absent(),
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.plate = const Value.absent(),
    this.vin = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.isBusiness = const Value.absent(),
    this.fuelKindDefault = const Value.absent(),
    this.tankCapacityMl = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchaseOdometerM = const Value.absent(),
    this.purchasePriceMinor = const Value.absent(),
    this.purchasePriceCurrency = const Value.absent(),
    this.status = const Value.absent(),
    this.soldOn = const Value.absent(),
    this.soldPriceMinor = const Value.absent(),
    this.soldPriceCurrency = const Value.absent(),
    this.expectedAnnualM = const Value.absent(),
    this.colour = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.notificationsMuted = const Value.absent(),
    this.currency = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.volumeUnit = const Value.absent(),
    this.consumptionUnit = const Value.absent(),
    this.noticeDistanceM = const Value.absent(),
    this.noticeDays = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VehiclesCompanion.insert({
    required String id,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.deletedAtUtcMs = const Value.absent(),
    required String name,
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.plate = const Value.absent(),
    this.vin = const Value.absent(),
    required String vehicleType,
    this.isBusiness = const Value.absent(),
    required String fuelKindDefault,
    this.tankCapacityMl = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchaseOdometerM = const Value.absent(),
    this.purchasePriceMinor = const Value.absent(),
    this.purchasePriceCurrency = const Value.absent(),
    required String status,
    this.soldOn = const Value.absent(),
    this.soldPriceMinor = const Value.absent(),
    this.soldPriceCurrency = const Value.absent(),
    this.expectedAnnualM = const Value.absent(),
    this.colour = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.notificationsMuted = const Value.absent(),
    this.currency = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.volumeUnit = const Value.absent(),
    this.consumptionUnit = const Value.absent(),
    this.noticeDistanceM = const Value.absent(),
    this.noticeDays = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs),
       name = Value(name),
       vehicleType = Value(vehicleType),
       fuelKindDefault = Value(fuelKindDefault),
       status = Value(status);
  static Insertable<VehicleRow> custom({
    Expression<String>? id,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? deletedAtUtcMs,
    Expression<String>? name,
    Expression<String>? make,
    Expression<String>? model,
    Expression<int>? year,
    Expression<String>? plate,
    Expression<String>? vin,
    Expression<String>? vehicleType,
    Expression<bool>? isBusiness,
    Expression<String>? fuelKindDefault,
    Expression<int>? tankCapacityMl,
    Expression<String>? purchaseDate,
    Expression<int>? purchaseOdometerM,
    Expression<int>? purchasePriceMinor,
    Expression<String>? purchasePriceCurrency,
    Expression<String>? status,
    Expression<String>? soldOn,
    Expression<int>? soldPriceMinor,
    Expression<String>? soldPriceCurrency,
    Expression<int>? expectedAnnualM,
    Expression<String>? colour,
    Expression<String>? notes,
    Expression<int>? sortOrder,
    Expression<bool>? notificationsMuted,
    Expression<String>? currency,
    Expression<String>? distanceUnit,
    Expression<String>? volumeUnit,
    Expression<String>? consumptionUnit,
    Expression<int>? noticeDistanceM,
    Expression<int>? noticeDays,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (name != null) 'name': name,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (plate != null) 'plate': plate,
      if (vin != null) 'vin': vin,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (isBusiness != null) 'is_business': isBusiness,
      if (fuelKindDefault != null) 'fuel_kind_default': fuelKindDefault,
      if (tankCapacityMl != null) 'tank_capacity_ml': tankCapacityMl,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (purchaseOdometerM != null) 'purchase_odometer_m': purchaseOdometerM,
      if (purchasePriceMinor != null)
        'purchase_price_minor': purchasePriceMinor,
      if (purchasePriceCurrency != null)
        'purchase_price_currency': purchasePriceCurrency,
      if (status != null) 'status': status,
      if (soldOn != null) 'sold_on': soldOn,
      if (soldPriceMinor != null) 'sold_price_minor': soldPriceMinor,
      if (soldPriceCurrency != null) 'sold_price_currency': soldPriceCurrency,
      if (expectedAnnualM != null) 'expected_annual_m': expectedAnnualM,
      if (colour != null) 'colour': colour,
      if (notes != null) 'notes': notes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (notificationsMuted != null) 'notifications_muted': notificationsMuted,
      if (currency != null) 'currency': currency,
      if (distanceUnit != null) 'distance_unit': distanceUnit,
      if (volumeUnit != null) 'volume_unit': volumeUnit,
      if (consumptionUnit != null) 'consumption_unit': consumptionUnit,
      if (noticeDistanceM != null) 'notice_distance_m': noticeDistanceM,
      if (noticeDays != null) 'notice_days': noticeDays,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VehiclesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int?>? deletedAtUtcMs,
    Value<String>? name,
    Value<String?>? make,
    Value<String?>? model,
    Value<int?>? year,
    Value<String?>? plate,
    Value<String?>? vin,
    Value<String>? vehicleType,
    Value<bool>? isBusiness,
    Value<String>? fuelKindDefault,
    Value<int?>? tankCapacityMl,
    Value<String?>? purchaseDate,
    Value<int?>? purchaseOdometerM,
    Value<int?>? purchasePriceMinor,
    Value<String?>? purchasePriceCurrency,
    Value<String>? status,
    Value<String?>? soldOn,
    Value<int?>? soldPriceMinor,
    Value<String?>? soldPriceCurrency,
    Value<int?>? expectedAnnualM,
    Value<String?>? colour,
    Value<String?>? notes,
    Value<int>? sortOrder,
    Value<bool>? notificationsMuted,
    Value<String?>? currency,
    Value<String?>? distanceUnit,
    Value<String?>? volumeUnit,
    Value<String?>? consumptionUnit,
    Value<int?>? noticeDistanceM,
    Value<int?>? noticeDays,
    Value<int>? rowid,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plate: plate ?? this.plate,
      vin: vin ?? this.vin,
      vehicleType: vehicleType ?? this.vehicleType,
      isBusiness: isBusiness ?? this.isBusiness,
      fuelKindDefault: fuelKindDefault ?? this.fuelKindDefault,
      tankCapacityMl: tankCapacityMl ?? this.tankCapacityMl,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseOdometerM: purchaseOdometerM ?? this.purchaseOdometerM,
      purchasePriceMinor: purchasePriceMinor ?? this.purchasePriceMinor,
      purchasePriceCurrency:
          purchasePriceCurrency ?? this.purchasePriceCurrency,
      status: status ?? this.status,
      soldOn: soldOn ?? this.soldOn,
      soldPriceMinor: soldPriceMinor ?? this.soldPriceMinor,
      soldPriceCurrency: soldPriceCurrency ?? this.soldPriceCurrency,
      expectedAnnualM: expectedAnnualM ?? this.expectedAnnualM,
      colour: colour ?? this.colour,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      notificationsMuted: notificationsMuted ?? this.notificationsMuted,
      currency: currency ?? this.currency,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      consumptionUnit: consumptionUnit ?? this.consumptionUnit,
      noticeDistanceM: noticeDistanceM ?? this.noticeDistanceM,
      noticeDays: noticeDays ?? this.noticeDays,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (make.present) {
      map['make'] = Variable<String>(make.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (plate.present) {
      map['plate'] = Variable<String>(plate.value);
    }
    if (vin.present) {
      map['vin'] = Variable<String>(vin.value);
    }
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (isBusiness.present) {
      map['is_business'] = Variable<bool>(isBusiness.value);
    }
    if (fuelKindDefault.present) {
      map['fuel_kind_default'] = Variable<String>(fuelKindDefault.value);
    }
    if (tankCapacityMl.present) {
      map['tank_capacity_ml'] = Variable<int>(tankCapacityMl.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (purchaseOdometerM.present) {
      map['purchase_odometer_m'] = Variable<int>(purchaseOdometerM.value);
    }
    if (purchasePriceMinor.present) {
      map['purchase_price_minor'] = Variable<int>(purchasePriceMinor.value);
    }
    if (purchasePriceCurrency.present) {
      map['purchase_price_currency'] = Variable<String>(
        purchasePriceCurrency.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (soldOn.present) {
      map['sold_on'] = Variable<String>(soldOn.value);
    }
    if (soldPriceMinor.present) {
      map['sold_price_minor'] = Variable<int>(soldPriceMinor.value);
    }
    if (soldPriceCurrency.present) {
      map['sold_price_currency'] = Variable<String>(soldPriceCurrency.value);
    }
    if (expectedAnnualM.present) {
      map['expected_annual_m'] = Variable<int>(expectedAnnualM.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (notificationsMuted.present) {
      map['notifications_muted'] = Variable<bool>(notificationsMuted.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (distanceUnit.present) {
      map['distance_unit'] = Variable<String>(distanceUnit.value);
    }
    if (volumeUnit.present) {
      map['volume_unit'] = Variable<String>(volumeUnit.value);
    }
    if (consumptionUnit.present) {
      map['consumption_unit'] = Variable<String>(consumptionUnit.value);
    }
    if (noticeDistanceM.present) {
      map['notice_distance_m'] = Variable<int>(noticeDistanceM.value);
    }
    if (noticeDays.present) {
      map['notice_days'] = Variable<int>(noticeDays.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('name: $name, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('plate: $plate, ')
          ..write('vin: $vin, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('isBusiness: $isBusiness, ')
          ..write('fuelKindDefault: $fuelKindDefault, ')
          ..write('tankCapacityMl: $tankCapacityMl, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchaseOdometerM: $purchaseOdometerM, ')
          ..write('purchasePriceMinor: $purchasePriceMinor, ')
          ..write('purchasePriceCurrency: $purchasePriceCurrency, ')
          ..write('status: $status, ')
          ..write('soldOn: $soldOn, ')
          ..write('soldPriceMinor: $soldPriceMinor, ')
          ..write('soldPriceCurrency: $soldPriceCurrency, ')
          ..write('expectedAnnualM: $expectedAnnualM, ')
          ..write('colour: $colour, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notificationsMuted: $notificationsMuted, ')
          ..write('currency: $currency, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('volumeUnit: $volumeUnit, ')
          ..write('consumptionUnit: $consumptionUnit, ')
          ..write('noticeDistanceM: $noticeDistanceM, ')
          ..write('noticeDays: $noticeDays, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServiceItemsTable extends ServiceItems
    with TableInfo<$ServiceItemsTable, ServiceItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (kind IN (\'oil_and_filter\', \'air_filter\', \'cabin_filter\', \'fuel_filter\', \'spark_plugs\', \'timing_belt\', \'brake_pads_check\', \'brake_pads_front\', \'brake_pads_rear\', \'brake_fluid\', \'coolant\', \'transmission_fluid\', \'wheel_alignment\', \'tyre_rotate\', \'tyre_replace\', \'battery\', \'wipers\', \'inspection\', \'registration\', \'insurance_renewal\', \'ac_service\', \'chain_lube\', \'chain_and_sprockets\', \'valve_clearance\', \'fork_oil\', \'reduction_gearbox_oil\', \'battery_12v\', \'custom\'))',
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalDistanceMMeta = const VerificationMeta(
    'intervalDistanceM',
  );
  @override
  late final GeneratedColumn<int> intervalDistanceM = GeneratedColumn<int>(
    'interval_distance_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (interval_distance_m IS NULL OR interval_distance_m > 0)',
  );
  static const VerificationMeta _intervalDistanceUnitMeta =
      const VerificationMeta('intervalDistanceUnit');
  @override
  late final GeneratedColumn<String> intervalDistanceUnit =
      GeneratedColumn<String>(
        'interval_distance_unit',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints:
            'CHECK (interval_distance_unit IN (\'km\', \'mi\'))',
      );
  static const VerificationMeta _intervalMonthsMeta = const VerificationMeta(
    'intervalMonths',
  );
  @override
  late final GeneratedColumn<int> intervalMonths = GeneratedColumn<int>(
    'interval_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (interval_months IS NULL OR interval_months > 0)',
  );
  static const VerificationMeta _targetOdometerMMeta = const VerificationMeta(
    'targetOdometerM',
  );
  @override
  late final GeneratedColumn<int> targetOdometerM = GeneratedColumn<int>(
    'target_odometer_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baselineDateMeta = const VerificationMeta(
    'baselineDate',
  );
  @override
  late final GeneratedColumn<String> baselineDate = GeneratedColumn<String>(
    'baseline_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baselineOdometerMMeta = const VerificationMeta(
    'baselineOdometerM',
  );
  @override
  late final GeneratedColumn<int> baselineOdometerM = GeneratedColumn<int>(
    'baseline_odometer_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noticeDistanceMMeta = const VerificationMeta(
    'noticeDistanceM',
  );
  @override
  late final GeneratedColumn<int> noticeDistanceM = GeneratedColumn<int>(
    'notice_distance_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noticeDaysMeta = const VerificationMeta(
    'noticeDays',
  );
  @override
  late final GeneratedColumn<int> noticeDays = GeneratedColumn<int>(
    'notice_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTrackedMeta = const VerificationMeta(
    'isTracked',
  );
  @override
  late final GeneratedColumn<bool> isTracked = GeneratedColumn<bool>(
    'is_tracked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tracked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyMeta = const VerificationMeta('notify');
  @override
  late final GeneratedColumn<bool> notify = GeneratedColumn<bool>(
    'notify',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (priority IN (\'safety\', \'normal\', \'low\'))',
  );
  static const VerificationMeta _rolloverMeta = const VerificationMeta(
    'rollover',
  );
  @override
  late final GeneratedColumn<String> rollover = GeneratedColumn<String>(
    'rollover',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (rollover IN (\'from_actual\', \'from_due\'))',
  );
  static const VerificationMeta _repeatsMeta = const VerificationMeta(
    'repeats',
  );
  @override
  late final GeneratedColumn<bool> repeats = GeneratedColumn<bool>(
    'repeats',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("repeats" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<String> snoozedUntil = GeneratedColumn<String>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozeUntilOdometerMMeta =
      const VerificationMeta('snoozeUntilOdometerM');
  @override
  late final GeneratedColumn<int> snoozeUntilOdometerM = GeneratedColumn<int>(
    'snooze_until_odometer_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozeCountMeta = const VerificationMeta(
    'snoozeCount',
  );
  @override
  late final GeneratedColumn<int> snoozeCount = GeneratedColumn<int>(
    'snooze_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    deletedAtUtcMs,
    vehicleId,
    kind,
    label,
    intervalDistanceM,
    intervalDistanceUnit,
    intervalMonths,
    targetOdometerM,
    targetDate,
    baselineDate,
    baselineOdometerM,
    noticeDistanceM,
    noticeDays,
    isTracked,
    isActive,
    notify,
    priority,
    rollover,
    repeats,
    snoozedUntil,
    snoozeUntilOdometerM,
    snoozeCount,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('interval_distance_m')) {
      context.handle(
        _intervalDistanceMMeta,
        intervalDistanceM.isAcceptableOrUnknown(
          data['interval_distance_m']!,
          _intervalDistanceMMeta,
        ),
      );
    }
    if (data.containsKey('interval_distance_unit')) {
      context.handle(
        _intervalDistanceUnitMeta,
        intervalDistanceUnit.isAcceptableOrUnknown(
          data['interval_distance_unit']!,
          _intervalDistanceUnitMeta,
        ),
      );
    }
    if (data.containsKey('interval_months')) {
      context.handle(
        _intervalMonthsMeta,
        intervalMonths.isAcceptableOrUnknown(
          data['interval_months']!,
          _intervalMonthsMeta,
        ),
      );
    }
    if (data.containsKey('target_odometer_m')) {
      context.handle(
        _targetOdometerMMeta,
        targetOdometerM.isAcceptableOrUnknown(
          data['target_odometer_m']!,
          _targetOdometerMMeta,
        ),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('baseline_date')) {
      context.handle(
        _baselineDateMeta,
        baselineDate.isAcceptableOrUnknown(
          data['baseline_date']!,
          _baselineDateMeta,
        ),
      );
    }
    if (data.containsKey('baseline_odometer_m')) {
      context.handle(
        _baselineOdometerMMeta,
        baselineOdometerM.isAcceptableOrUnknown(
          data['baseline_odometer_m']!,
          _baselineOdometerMMeta,
        ),
      );
    }
    if (data.containsKey('notice_distance_m')) {
      context.handle(
        _noticeDistanceMMeta,
        noticeDistanceM.isAcceptableOrUnknown(
          data['notice_distance_m']!,
          _noticeDistanceMMeta,
        ),
      );
    }
    if (data.containsKey('notice_days')) {
      context.handle(
        _noticeDaysMeta,
        noticeDays.isAcceptableOrUnknown(data['notice_days']!, _noticeDaysMeta),
      );
    }
    if (data.containsKey('is_tracked')) {
      context.handle(
        _isTrackedMeta,
        isTracked.isAcceptableOrUnknown(data['is_tracked']!, _isTrackedMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('notify')) {
      context.handle(
        _notifyMeta,
        notify.isAcceptableOrUnknown(data['notify']!, _notifyMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('rollover')) {
      context.handle(
        _rolloverMeta,
        rollover.isAcceptableOrUnknown(data['rollover']!, _rolloverMeta),
      );
    } else if (isInserting) {
      context.missing(_rolloverMeta);
    }
    if (data.containsKey('repeats')) {
      context.handle(
        _repeatsMeta,
        repeats.isAcceptableOrUnknown(data['repeats']!, _repeatsMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('snooze_until_odometer_m')) {
      context.handle(
        _snoozeUntilOdometerMMeta,
        snoozeUntilOdometerM.isAcceptableOrUnknown(
          data['snooze_until_odometer_m']!,
          _snoozeUntilOdometerMMeta,
        ),
      );
    }
    if (data.containsKey('snooze_count')) {
      context.handle(
        _snoozeCountMeta,
        snoozeCount.isAcceptableOrUnknown(
          data['snooze_count']!,
          _snoozeCountMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServiceItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      intervalDistanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_distance_m'],
      ),
      intervalDistanceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interval_distance_unit'],
      ),
      intervalMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_months'],
      ),
      targetOdometerM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_odometer_m'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      ),
      baselineDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}baseline_date'],
      ),
      baselineOdometerM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}baseline_odometer_m'],
      ),
      noticeDistanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notice_distance_m'],
      ),
      noticeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notice_days'],
      ),
      isTracked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tracked'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      notify: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      rollover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rollover'],
      )!,
      repeats: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}repeats'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snoozed_until'],
      ),
      snoozeUntilOdometerM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_until_odometer_m'],
      ),
      snoozeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_count'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $ServiceItemsTable createAlias(String alias) {
    return $ServiceItemsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class ServiceItemRow extends DataClass implements Insertable<ServiceItemRow> {
  /// `<prefix>_<ULID>`; see `RecordId`.
  final String id;

  /// When the row was first written. UTC epoch milliseconds.
  final int createdAtUtcMs;

  /// When it was last changed. UTC epoch milliseconds.
  ///
  /// Never less than [createdAtUtcMs] — but repaired on READ rather than
  /// blocked on write. See `repairAuditTimes`.
  final int updatedAtUtcMs;

  /// When it was soft-deleted, or null.
  ///
  /// Soft delete is what makes Undo possible for the length of a snackbar.
  /// After that the row is purged, so a settled database has this null on
  /// every row that exists.
  final int? deletedAtUtcMs;

  /// The vehicle this belongs to.
  ///
  /// Vehicles never share service items, intervals, fuel history or costs
  /// (SPEC.md §3 Scope), so this is not nullable and the cascade is real.
  /// Written as a `customConstraint` rather than with drift's
  /// `.references()`. `.references()` compiled and emitted no `REFERENCES`
  /// clause at all — the column came out as a bare `TEXT NOT NULL` — so an
  /// item pointing at a vehicle that does not exist was accepted, and the
  /// cascade that Undo depends on did not exist. The test that inserts an
  /// orphan is what found it; nothing in Dart could have.
  final String vehicleId;

  /// Which catalogue item, or `custom`.
  final String kind;

  /// What to call it.
  ///
  /// Required when [kind] is `custom`, and an optional override otherwise —
  /// the `CHECK` below is what makes a nameless custom item impossible rather
  /// than merely discouraged.
  final String? label;

  /// Distance interval in metres. Null means not distance-based.
  final int? intervalDistanceM;

  /// The unit the interval was ENTERED in, kept for display fidelity.
  ///
  /// SPEC.md §3: provenance units never enter arithmetic. Storage is metres;
  /// this exists so "every 10,000 miles" reads back as miles rather than as
  /// 16,093 km.
  final String? intervalDistanceUnit;

  /// Time interval in months. Null means not time-based.
  final int? intervalMonths;

  /// A one-off target odometer, in metres. "Cambelt at 120,000 km."
  final int? targetOdometerM;

  /// A one-off target date. "Registration renewal."
  final String? targetDate;

  /// "Last done March 2024", set when the item is created.
  final String? baselineDate;

  /// The odometer at [baselineDate], in metres.
  final int? baselineOdometerM;

  /// Per-item distance notice window override, in metres. Null = computed.
  final int? noticeDistanceM;

  /// Per-item time notice window override, in days. Null = computed.
  final int? noticeDays;

  /// False = seeded from the catalogue but never adopted. Invisible to the
  /// engine, so a fresh vehicle does not open on a wall of amber.
  final bool isTracked;

  /// False = the user paused it. Never notifies, greys out, keeps its history.
  final bool isActive;

  /// Whether this item may raise a notification.
  final bool notify;

  /// How it sorts when several are due at once.
  final String priority;

  /// What the next due date is measured from when it completes late.
  final String rollover;

  /// False = completes once and retires.
  final bool repeats;

  /// Snoozed until this date.
  final String? snoozedUntil;

  /// Snoozed until this odometer, in metres.
  final int? snoozeUntilOdometerM;

  /// How many times it has been snoozed. Reset to 0 on completion or on an
  /// interval edit.
  final int snoozeCount;

  /// Free text.
  final String? notes;
  const ServiceItemRow({
    required this.id,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.deletedAtUtcMs,
    required this.vehicleId,
    required this.kind,
    this.label,
    this.intervalDistanceM,
    this.intervalDistanceUnit,
    this.intervalMonths,
    this.targetOdometerM,
    this.targetDate,
    this.baselineDate,
    this.baselineOdometerM,
    this.noticeDistanceM,
    this.noticeDays,
    required this.isTracked,
    required this.isActive,
    required this.notify,
    required this.priority,
    required this.rollover,
    required this.repeats,
    this.snoozedUntil,
    this.snoozeUntilOdometerM,
    required this.snoozeCount,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || intervalDistanceM != null) {
      map['interval_distance_m'] = Variable<int>(intervalDistanceM);
    }
    if (!nullToAbsent || intervalDistanceUnit != null) {
      map['interval_distance_unit'] = Variable<String>(intervalDistanceUnit);
    }
    if (!nullToAbsent || intervalMonths != null) {
      map['interval_months'] = Variable<int>(intervalMonths);
    }
    if (!nullToAbsent || targetOdometerM != null) {
      map['target_odometer_m'] = Variable<int>(targetOdometerM);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    if (!nullToAbsent || baselineDate != null) {
      map['baseline_date'] = Variable<String>(baselineDate);
    }
    if (!nullToAbsent || baselineOdometerM != null) {
      map['baseline_odometer_m'] = Variable<int>(baselineOdometerM);
    }
    if (!nullToAbsent || noticeDistanceM != null) {
      map['notice_distance_m'] = Variable<int>(noticeDistanceM);
    }
    if (!nullToAbsent || noticeDays != null) {
      map['notice_days'] = Variable<int>(noticeDays);
    }
    map['is_tracked'] = Variable<bool>(isTracked);
    map['is_active'] = Variable<bool>(isActive);
    map['notify'] = Variable<bool>(notify);
    map['priority'] = Variable<String>(priority);
    map['rollover'] = Variable<String>(rollover);
    map['repeats'] = Variable<bool>(repeats);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<String>(snoozedUntil);
    }
    if (!nullToAbsent || snoozeUntilOdometerM != null) {
      map['snooze_until_odometer_m'] = Variable<int>(snoozeUntilOdometerM);
    }
    map['snooze_count'] = Variable<int>(snoozeCount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ServiceItemsCompanion toCompanion(bool nullToAbsent) {
    return ServiceItemsCompanion(
      id: Value(id),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      vehicleId: Value(vehicleId),
      kind: Value(kind),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      intervalDistanceM: intervalDistanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDistanceM),
      intervalDistanceUnit: intervalDistanceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDistanceUnit),
      intervalMonths: intervalMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalMonths),
      targetOdometerM: targetOdometerM == null && nullToAbsent
          ? const Value.absent()
          : Value(targetOdometerM),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      baselineDate: baselineDate == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineDate),
      baselineOdometerM: baselineOdometerM == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineOdometerM),
      noticeDistanceM: noticeDistanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(noticeDistanceM),
      noticeDays: noticeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(noticeDays),
      isTracked: Value(isTracked),
      isActive: Value(isActive),
      notify: Value(notify),
      priority: Value(priority),
      rollover: Value(rollover),
      repeats: Value(repeats),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      snoozeUntilOdometerM: snoozeUntilOdometerM == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeUntilOdometerM),
      snoozeCount: Value(snoozeCount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory ServiceItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceItemRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String?>(json['label']),
      intervalDistanceM: serializer.fromJson<int?>(json['intervalDistanceM']),
      intervalDistanceUnit: serializer.fromJson<String?>(
        json['intervalDistanceUnit'],
      ),
      intervalMonths: serializer.fromJson<int?>(json['intervalMonths']),
      targetOdometerM: serializer.fromJson<int?>(json['targetOdometerM']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      baselineDate: serializer.fromJson<String?>(json['baselineDate']),
      baselineOdometerM: serializer.fromJson<int?>(json['baselineOdometerM']),
      noticeDistanceM: serializer.fromJson<int?>(json['noticeDistanceM']),
      noticeDays: serializer.fromJson<int?>(json['noticeDays']),
      isTracked: serializer.fromJson<bool>(json['isTracked']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      notify: serializer.fromJson<bool>(json['notify']),
      priority: serializer.fromJson<String>(json['priority']),
      rollover: serializer.fromJson<String>(json['rollover']),
      repeats: serializer.fromJson<bool>(json['repeats']),
      snoozedUntil: serializer.fromJson<String?>(json['snoozedUntil']),
      snoozeUntilOdometerM: serializer.fromJson<int?>(
        json['snoozeUntilOdometerM'],
      ),
      snoozeCount: serializer.fromJson<int>(json['snoozeCount']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String?>(label),
      'intervalDistanceM': serializer.toJson<int?>(intervalDistanceM),
      'intervalDistanceUnit': serializer.toJson<String?>(intervalDistanceUnit),
      'intervalMonths': serializer.toJson<int?>(intervalMonths),
      'targetOdometerM': serializer.toJson<int?>(targetOdometerM),
      'targetDate': serializer.toJson<String?>(targetDate),
      'baselineDate': serializer.toJson<String?>(baselineDate),
      'baselineOdometerM': serializer.toJson<int?>(baselineOdometerM),
      'noticeDistanceM': serializer.toJson<int?>(noticeDistanceM),
      'noticeDays': serializer.toJson<int?>(noticeDays),
      'isTracked': serializer.toJson<bool>(isTracked),
      'isActive': serializer.toJson<bool>(isActive),
      'notify': serializer.toJson<bool>(notify),
      'priority': serializer.toJson<String>(priority),
      'rollover': serializer.toJson<String>(rollover),
      'repeats': serializer.toJson<bool>(repeats),
      'snoozedUntil': serializer.toJson<String?>(snoozedUntil),
      'snoozeUntilOdometerM': serializer.toJson<int?>(snoozeUntilOdometerM),
      'snoozeCount': serializer.toJson<int>(snoozeCount),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  ServiceItemRow copyWith({
    String? id,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    String? vehicleId,
    String? kind,
    Value<String?> label = const Value.absent(),
    Value<int?> intervalDistanceM = const Value.absent(),
    Value<String?> intervalDistanceUnit = const Value.absent(),
    Value<int?> intervalMonths = const Value.absent(),
    Value<int?> targetOdometerM = const Value.absent(),
    Value<String?> targetDate = const Value.absent(),
    Value<String?> baselineDate = const Value.absent(),
    Value<int?> baselineOdometerM = const Value.absent(),
    Value<int?> noticeDistanceM = const Value.absent(),
    Value<int?> noticeDays = const Value.absent(),
    bool? isTracked,
    bool? isActive,
    bool? notify,
    String? priority,
    String? rollover,
    bool? repeats,
    Value<String?> snoozedUntil = const Value.absent(),
    Value<int?> snoozeUntilOdometerM = const Value.absent(),
    int? snoozeCount,
    Value<String?> notes = const Value.absent(),
  }) => ServiceItemRow(
    id: id ?? this.id,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    vehicleId: vehicleId ?? this.vehicleId,
    kind: kind ?? this.kind,
    label: label.present ? label.value : this.label,
    intervalDistanceM: intervalDistanceM.present
        ? intervalDistanceM.value
        : this.intervalDistanceM,
    intervalDistanceUnit: intervalDistanceUnit.present
        ? intervalDistanceUnit.value
        : this.intervalDistanceUnit,
    intervalMonths: intervalMonths.present
        ? intervalMonths.value
        : this.intervalMonths,
    targetOdometerM: targetOdometerM.present
        ? targetOdometerM.value
        : this.targetOdometerM,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    baselineDate: baselineDate.present ? baselineDate.value : this.baselineDate,
    baselineOdometerM: baselineOdometerM.present
        ? baselineOdometerM.value
        : this.baselineOdometerM,
    noticeDistanceM: noticeDistanceM.present
        ? noticeDistanceM.value
        : this.noticeDistanceM,
    noticeDays: noticeDays.present ? noticeDays.value : this.noticeDays,
    isTracked: isTracked ?? this.isTracked,
    isActive: isActive ?? this.isActive,
    notify: notify ?? this.notify,
    priority: priority ?? this.priority,
    rollover: rollover ?? this.rollover,
    repeats: repeats ?? this.repeats,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    snoozeUntilOdometerM: snoozeUntilOdometerM.present
        ? snoozeUntilOdometerM.value
        : this.snoozeUntilOdometerM,
    snoozeCount: snoozeCount ?? this.snoozeCount,
    notes: notes.present ? notes.value : this.notes,
  );
  ServiceItemRow copyWithCompanion(ServiceItemsCompanion data) {
    return ServiceItemRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      intervalDistanceM: data.intervalDistanceM.present
          ? data.intervalDistanceM.value
          : this.intervalDistanceM,
      intervalDistanceUnit: data.intervalDistanceUnit.present
          ? data.intervalDistanceUnit.value
          : this.intervalDistanceUnit,
      intervalMonths: data.intervalMonths.present
          ? data.intervalMonths.value
          : this.intervalMonths,
      targetOdometerM: data.targetOdometerM.present
          ? data.targetOdometerM.value
          : this.targetOdometerM,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      baselineDate: data.baselineDate.present
          ? data.baselineDate.value
          : this.baselineDate,
      baselineOdometerM: data.baselineOdometerM.present
          ? data.baselineOdometerM.value
          : this.baselineOdometerM,
      noticeDistanceM: data.noticeDistanceM.present
          ? data.noticeDistanceM.value
          : this.noticeDistanceM,
      noticeDays: data.noticeDays.present
          ? data.noticeDays.value
          : this.noticeDays,
      isTracked: data.isTracked.present ? data.isTracked.value : this.isTracked,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      notify: data.notify.present ? data.notify.value : this.notify,
      priority: data.priority.present ? data.priority.value : this.priority,
      rollover: data.rollover.present ? data.rollover.value : this.rollover,
      repeats: data.repeats.present ? data.repeats.value : this.repeats,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      snoozeUntilOdometerM: data.snoozeUntilOdometerM.present
          ? data.snoozeUntilOdometerM.value
          : this.snoozeUntilOdometerM,
      snoozeCount: data.snoozeCount.present
          ? data.snoozeCount.value
          : this.snoozeCount,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceItemRow(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('intervalDistanceM: $intervalDistanceM, ')
          ..write('intervalDistanceUnit: $intervalDistanceUnit, ')
          ..write('intervalMonths: $intervalMonths, ')
          ..write('targetOdometerM: $targetOdometerM, ')
          ..write('targetDate: $targetDate, ')
          ..write('baselineDate: $baselineDate, ')
          ..write('baselineOdometerM: $baselineOdometerM, ')
          ..write('noticeDistanceM: $noticeDistanceM, ')
          ..write('noticeDays: $noticeDays, ')
          ..write('isTracked: $isTracked, ')
          ..write('isActive: $isActive, ')
          ..write('notify: $notify, ')
          ..write('priority: $priority, ')
          ..write('rollover: $rollover, ')
          ..write('repeats: $repeats, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('snoozeUntilOdometerM: $snoozeUntilOdometerM, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    deletedAtUtcMs,
    vehicleId,
    kind,
    label,
    intervalDistanceM,
    intervalDistanceUnit,
    intervalMonths,
    targetOdometerM,
    targetDate,
    baselineDate,
    baselineOdometerM,
    noticeDistanceM,
    noticeDays,
    isTracked,
    isActive,
    notify,
    priority,
    rollover,
    repeats,
    snoozedUntil,
    snoozeUntilOdometerM,
    snoozeCount,
    notes,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceItemRow &&
          other.id == this.id &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.vehicleId == this.vehicleId &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.intervalDistanceM == this.intervalDistanceM &&
          other.intervalDistanceUnit == this.intervalDistanceUnit &&
          other.intervalMonths == this.intervalMonths &&
          other.targetOdometerM == this.targetOdometerM &&
          other.targetDate == this.targetDate &&
          other.baselineDate == this.baselineDate &&
          other.baselineOdometerM == this.baselineOdometerM &&
          other.noticeDistanceM == this.noticeDistanceM &&
          other.noticeDays == this.noticeDays &&
          other.isTracked == this.isTracked &&
          other.isActive == this.isActive &&
          other.notify == this.notify &&
          other.priority == this.priority &&
          other.rollover == this.rollover &&
          other.repeats == this.repeats &&
          other.snoozedUntil == this.snoozedUntil &&
          other.snoozeUntilOdometerM == this.snoozeUntilOdometerM &&
          other.snoozeCount == this.snoozeCount &&
          other.notes == this.notes);
}

class ServiceItemsCompanion extends UpdateCompanion<ServiceItemRow> {
  final Value<String> id;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int?> deletedAtUtcMs;
  final Value<String> vehicleId;
  final Value<String> kind;
  final Value<String?> label;
  final Value<int?> intervalDistanceM;
  final Value<String?> intervalDistanceUnit;
  final Value<int?> intervalMonths;
  final Value<int?> targetOdometerM;
  final Value<String?> targetDate;
  final Value<String?> baselineDate;
  final Value<int?> baselineOdometerM;
  final Value<int?> noticeDistanceM;
  final Value<int?> noticeDays;
  final Value<bool> isTracked;
  final Value<bool> isActive;
  final Value<bool> notify;
  final Value<String> priority;
  final Value<String> rollover;
  final Value<bool> repeats;
  final Value<String?> snoozedUntil;
  final Value<int?> snoozeUntilOdometerM;
  final Value<int> snoozeCount;
  final Value<String?> notes;
  final Value<int> rowid;
  const ServiceItemsCompanion({
    this.id = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.intervalDistanceM = const Value.absent(),
    this.intervalDistanceUnit = const Value.absent(),
    this.intervalMonths = const Value.absent(),
    this.targetOdometerM = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.baselineDate = const Value.absent(),
    this.baselineOdometerM = const Value.absent(),
    this.noticeDistanceM = const Value.absent(),
    this.noticeDays = const Value.absent(),
    this.isTracked = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notify = const Value.absent(),
    this.priority = const Value.absent(),
    this.rollover = const Value.absent(),
    this.repeats = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.snoozeUntilOdometerM = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServiceItemsCompanion.insert({
    required String id,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.deletedAtUtcMs = const Value.absent(),
    required String vehicleId,
    required String kind,
    this.label = const Value.absent(),
    this.intervalDistanceM = const Value.absent(),
    this.intervalDistanceUnit = const Value.absent(),
    this.intervalMonths = const Value.absent(),
    this.targetOdometerM = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.baselineDate = const Value.absent(),
    this.baselineOdometerM = const Value.absent(),
    this.noticeDistanceM = const Value.absent(),
    this.noticeDays = const Value.absent(),
    this.isTracked = const Value.absent(),
    this.isActive = const Value.absent(),
    this.notify = const Value.absent(),
    required String priority,
    required String rollover,
    this.repeats = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.snoozeUntilOdometerM = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs),
       vehicleId = Value(vehicleId),
       kind = Value(kind),
       priority = Value(priority),
       rollover = Value(rollover);
  static Insertable<ServiceItemRow> custom({
    Expression<String>? id,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? deletedAtUtcMs,
    Expression<String>? vehicleId,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<int>? intervalDistanceM,
    Expression<String>? intervalDistanceUnit,
    Expression<int>? intervalMonths,
    Expression<int>? targetOdometerM,
    Expression<String>? targetDate,
    Expression<String>? baselineDate,
    Expression<int>? baselineOdometerM,
    Expression<int>? noticeDistanceM,
    Expression<int>? noticeDays,
    Expression<bool>? isTracked,
    Expression<bool>? isActive,
    Expression<bool>? notify,
    Expression<String>? priority,
    Expression<String>? rollover,
    Expression<bool>? repeats,
    Expression<String>? snoozedUntil,
    Expression<int>? snoozeUntilOdometerM,
    Expression<int>? snoozeCount,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (intervalDistanceM != null) 'interval_distance_m': intervalDistanceM,
      if (intervalDistanceUnit != null)
        'interval_distance_unit': intervalDistanceUnit,
      if (intervalMonths != null) 'interval_months': intervalMonths,
      if (targetOdometerM != null) 'target_odometer_m': targetOdometerM,
      if (targetDate != null) 'target_date': targetDate,
      if (baselineDate != null) 'baseline_date': baselineDate,
      if (baselineOdometerM != null) 'baseline_odometer_m': baselineOdometerM,
      if (noticeDistanceM != null) 'notice_distance_m': noticeDistanceM,
      if (noticeDays != null) 'notice_days': noticeDays,
      if (isTracked != null) 'is_tracked': isTracked,
      if (isActive != null) 'is_active': isActive,
      if (notify != null) 'notify': notify,
      if (priority != null) 'priority': priority,
      if (rollover != null) 'rollover': rollover,
      if (repeats != null) 'repeats': repeats,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (snoozeUntilOdometerM != null)
        'snooze_until_odometer_m': snoozeUntilOdometerM,
      if (snoozeCount != null) 'snooze_count': snoozeCount,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServiceItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int?>? deletedAtUtcMs,
    Value<String>? vehicleId,
    Value<String>? kind,
    Value<String?>? label,
    Value<int?>? intervalDistanceM,
    Value<String?>? intervalDistanceUnit,
    Value<int?>? intervalMonths,
    Value<int?>? targetOdometerM,
    Value<String?>? targetDate,
    Value<String?>? baselineDate,
    Value<int?>? baselineOdometerM,
    Value<int?>? noticeDistanceM,
    Value<int?>? noticeDays,
    Value<bool>? isTracked,
    Value<bool>? isActive,
    Value<bool>? notify,
    Value<String>? priority,
    Value<String>? rollover,
    Value<bool>? repeats,
    Value<String?>? snoozedUntil,
    Value<int?>? snoozeUntilOdometerM,
    Value<int>? snoozeCount,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return ServiceItemsCompanion(
      id: id ?? this.id,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      vehicleId: vehicleId ?? this.vehicleId,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      intervalDistanceM: intervalDistanceM ?? this.intervalDistanceM,
      intervalDistanceUnit: intervalDistanceUnit ?? this.intervalDistanceUnit,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      targetOdometerM: targetOdometerM ?? this.targetOdometerM,
      targetDate: targetDate ?? this.targetDate,
      baselineDate: baselineDate ?? this.baselineDate,
      baselineOdometerM: baselineOdometerM ?? this.baselineOdometerM,
      noticeDistanceM: noticeDistanceM ?? this.noticeDistanceM,
      noticeDays: noticeDays ?? this.noticeDays,
      isTracked: isTracked ?? this.isTracked,
      isActive: isActive ?? this.isActive,
      notify: notify ?? this.notify,
      priority: priority ?? this.priority,
      rollover: rollover ?? this.rollover,
      repeats: repeats ?? this.repeats,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      snoozeUntilOdometerM: snoozeUntilOdometerM ?? this.snoozeUntilOdometerM,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (intervalDistanceM.present) {
      map['interval_distance_m'] = Variable<int>(intervalDistanceM.value);
    }
    if (intervalDistanceUnit.present) {
      map['interval_distance_unit'] = Variable<String>(
        intervalDistanceUnit.value,
      );
    }
    if (intervalMonths.present) {
      map['interval_months'] = Variable<int>(intervalMonths.value);
    }
    if (targetOdometerM.present) {
      map['target_odometer_m'] = Variable<int>(targetOdometerM.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (baselineDate.present) {
      map['baseline_date'] = Variable<String>(baselineDate.value);
    }
    if (baselineOdometerM.present) {
      map['baseline_odometer_m'] = Variable<int>(baselineOdometerM.value);
    }
    if (noticeDistanceM.present) {
      map['notice_distance_m'] = Variable<int>(noticeDistanceM.value);
    }
    if (noticeDays.present) {
      map['notice_days'] = Variable<int>(noticeDays.value);
    }
    if (isTracked.present) {
      map['is_tracked'] = Variable<bool>(isTracked.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (notify.present) {
      map['notify'] = Variable<bool>(notify.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (rollover.present) {
      map['rollover'] = Variable<String>(rollover.value);
    }
    if (repeats.present) {
      map['repeats'] = Variable<bool>(repeats.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<String>(snoozedUntil.value);
    }
    if (snoozeUntilOdometerM.present) {
      map['snooze_until_odometer_m'] = Variable<int>(
        snoozeUntilOdometerM.value,
      );
    }
    if (snoozeCount.present) {
      map['snooze_count'] = Variable<int>(snoozeCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('intervalDistanceM: $intervalDistanceM, ')
          ..write('intervalDistanceUnit: $intervalDistanceUnit, ')
          ..write('intervalMonths: $intervalMonths, ')
          ..write('targetOdometerM: $targetOdometerM, ')
          ..write('targetDate: $targetDate, ')
          ..write('baselineDate: $baselineDate, ')
          ..write('baselineOdometerM: $baselineOdometerM, ')
          ..write('noticeDistanceM: $noticeDistanceM, ')
          ..write('noticeDays: $noticeDays, ')
          ..write('isTracked: $isTracked, ')
          ..write('isActive: $isActive, ')
          ..write('notify: $notify, ')
          ..write('priority: $priority, ')
          ..write('rollover: $rollover, ')
          ..write('repeats: $repeats, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('snoozeUntilOdometerM: $snoozeUntilOdometerM, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (id = \'settings\')',
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (language IN (\'system\', \'en\', \'de\', \'fr\', \'fa\', \'ar\', \'ckb\'))',
  );
  static const VerificationMeta _calendarMeta = const VerificationMeta(
    'calendar',
  );
  @override
  late final GeneratedColumn<String> calendar = GeneratedColumn<String>(
    'calendar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (calendar IN (\'gregorian\', \'persian\'))',
  );
  static const VerificationMeta _numeralsMeta = const VerificationMeta(
    'numerals',
  );
  @override
  late final GeneratedColumn<String> numerals = GeneratedColumn<String>(
    'numerals',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (numerals IN (\'auto\', \'latin\', \'arabic_indic\', \'extended_arabic_indic\'))',
  );
  static const VerificationMeta _firstDayOfWeekMeta = const VerificationMeta(
    'firstDayOfWeek',
  );
  @override
  late final GeneratedColumn<int> firstDayOfWeek = GeneratedColumn<int>(
    'first_day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (first_day_of_week BETWEEN 1 AND 7)',
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (theme IN (\'system\', \'light\', \'dark\'))',
  );
  static const VerificationMeta _currencyDefaultMeta = const VerificationMeta(
    'currencyDefault',
  );
  @override
  late final GeneratedColumn<String> currencyDefault = GeneratedColumn<String>(
    'currency_default',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(currency_default) = 3)',
  );
  static const VerificationMeta _currencyDisplayMeta = const VerificationMeta(
    'currencyDisplay',
  );
  @override
  late final GeneratedColumn<String> currencyDisplay = GeneratedColumn<String>(
    'currency_display',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (currency_display IN (\'none\', \'toman\'))',
  );
  static const VerificationMeta _distanceUnitMeta = const VerificationMeta(
    'distanceUnit',
  );
  @override
  late final GeneratedColumn<String> distanceUnit = GeneratedColumn<String>(
    'distance_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (distance_unit IN (\'km\', \'mi\'))',
  );
  static const VerificationMeta _volumeUnitMeta = const VerificationMeta(
    'volumeUnit',
  );
  @override
  late final GeneratedColumn<String> volumeUnit = GeneratedColumn<String>(
    'volume_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (volume_unit IN (\'l\', \'gal_us\', \'gal_uk\'))',
  );
  static const VerificationMeta _consumptionUnitMeta = const VerificationMeta(
    'consumptionUnit',
  );
  @override
  late final GeneratedColumn<String> consumptionUnit = GeneratedColumn<String>(
    'consumption_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (consumption_unit IN (\'l_100km\', \'km_l\', \'mpg_us\', \'mpg_uk\', \'kwh_100km\', \'mi_kwh\'))',
  );
  static const VerificationMeta _noticeDistanceMMeta = const VerificationMeta(
    'noticeDistanceM',
  );
  @override
  late final GeneratedColumn<int> noticeDistanceM = GeneratedColumn<int>(
    'notice_distance_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noticeDaysMeta = const VerificationMeta(
    'noticeDays',
  );
  @override
  late final GeneratedColumn<int> noticeDays = GeneratedColumn<int>(
    'notice_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationTimeMinutesMeta =
      const VerificationMeta('notificationTimeMinutes');
  @override
  late final GeneratedColumn<int> notificationTimeMinutes =
      GeneratedColumn<int>(
        'notification_time_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (notification_time_minutes BETWEEN 0 AND 1439)',
      );
  static const VerificationMeta _quietHoursFromMinutesMeta =
      const VerificationMeta('quietHoursFromMinutes');
  @override
  late final GeneratedColumn<int> quietHoursFromMinutes = GeneratedColumn<int>(
    'quiet_hours_from_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (quiet_hours_from_minutes BETWEEN 0 AND 1439)',
  );
  static const VerificationMeta _quietHoursToMinutesMeta =
      const VerificationMeta('quietHoursToMinutes');
  @override
  late final GeneratedColumn<int> quietHoursToMinutes = GeneratedColumn<int>(
    'quiet_hours_to_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (quiet_hours_to_minutes BETWEEN 0 AND 1439)',
  );
  static const VerificationMeta _weekdaysOnlyMeta = const VerificationMeta(
    'weekdaysOnly',
  );
  @override
  late final GeneratedColumn<bool> weekdaysOnly = GeneratedColumn<bool>(
    'weekdays_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("weekdays_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notifyServiceMeta = const VerificationMeta(
    'notifyService',
  );
  @override
  late final GeneratedColumn<bool> notifyService = GeneratedColumn<bool>(
    'notify_service',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_service" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyOdometerMeta = const VerificationMeta(
    'notifyOdometer',
  );
  @override
  late final GeneratedColumn<bool> notifyOdometer = GeneratedColumn<bool>(
    'notify_odometer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_odometer" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyBackupMeta = const VerificationMeta(
    'notifyBackup',
  );
  @override
  late final GeneratedColumn<bool> notifyBackup = GeneratedColumn<bool>(
    'notify_backup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_backup" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _activeVehicleIdMeta = const VerificationMeta(
    'activeVehicleId',
  );
  @override
  late final GeneratedColumn<String> activeVehicleId = GeneratedColumn<String>(
    'active_vehicle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingDoneMeta = const VerificationMeta(
    'onboardingDone',
  );
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
    'onboarding_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastBackupAtUtcMsMeta = const VerificationMeta(
    'lastBackupAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> lastBackupAtUtcMs = GeneratedColumn<int>(
    'last_backup_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastBackupReminderAtUtcMsMeta =
      const VerificationMeta('lastBackupReminderAtUtcMs');
  @override
  late final GeneratedColumn<int> lastBackupReminderAtUtcMs =
      GeneratedColumn<int>(
        'last_backup_reminder_at_utc_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    deletedAtUtcMs,
    schemaVersion,
    language,
    calendar,
    numerals,
    firstDayOfWeek,
    theme,
    currencyDefault,
    currencyDisplay,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
    noticeDistanceM,
    noticeDays,
    notificationTimeMinutes,
    quietHoursFromMinutes,
    quietHoursToMinutes,
    weekdaysOnly,
    notifyService,
    notifyOdometer,
    notifyBackup,
    activeVehicleId,
    onboardingDone,
    lastBackupAtUtcMs,
    lastBackupReminderAtUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('calendar')) {
      context.handle(
        _calendarMeta,
        calendar.isAcceptableOrUnknown(data['calendar']!, _calendarMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarMeta);
    }
    if (data.containsKey('numerals')) {
      context.handle(
        _numeralsMeta,
        numerals.isAcceptableOrUnknown(data['numerals']!, _numeralsMeta),
      );
    } else if (isInserting) {
      context.missing(_numeralsMeta);
    }
    if (data.containsKey('first_day_of_week')) {
      context.handle(
        _firstDayOfWeekMeta,
        firstDayOfWeek.isAcceptableOrUnknown(
          data['first_day_of_week']!,
          _firstDayOfWeekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstDayOfWeekMeta);
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    if (data.containsKey('currency_default')) {
      context.handle(
        _currencyDefaultMeta,
        currencyDefault.isAcceptableOrUnknown(
          data['currency_default']!,
          _currencyDefaultMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyDefaultMeta);
    }
    if (data.containsKey('currency_display')) {
      context.handle(
        _currencyDisplayMeta,
        currencyDisplay.isAcceptableOrUnknown(
          data['currency_display']!,
          _currencyDisplayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyDisplayMeta);
    }
    if (data.containsKey('distance_unit')) {
      context.handle(
        _distanceUnitMeta,
        distanceUnit.isAcceptableOrUnknown(
          data['distance_unit']!,
          _distanceUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceUnitMeta);
    }
    if (data.containsKey('volume_unit')) {
      context.handle(
        _volumeUnitMeta,
        volumeUnit.isAcceptableOrUnknown(data['volume_unit']!, _volumeUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeUnitMeta);
    }
    if (data.containsKey('consumption_unit')) {
      context.handle(
        _consumptionUnitMeta,
        consumptionUnit.isAcceptableOrUnknown(
          data['consumption_unit']!,
          _consumptionUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consumptionUnitMeta);
    }
    if (data.containsKey('notice_distance_m')) {
      context.handle(
        _noticeDistanceMMeta,
        noticeDistanceM.isAcceptableOrUnknown(
          data['notice_distance_m']!,
          _noticeDistanceMMeta,
        ),
      );
    }
    if (data.containsKey('notice_days')) {
      context.handle(
        _noticeDaysMeta,
        noticeDays.isAcceptableOrUnknown(data['notice_days']!, _noticeDaysMeta),
      );
    }
    if (data.containsKey('notification_time_minutes')) {
      context.handle(
        _notificationTimeMinutesMeta,
        notificationTimeMinutes.isAcceptableOrUnknown(
          data['notification_time_minutes']!,
          _notificationTimeMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationTimeMinutesMeta);
    }
    if (data.containsKey('quiet_hours_from_minutes')) {
      context.handle(
        _quietHoursFromMinutesMeta,
        quietHoursFromMinutes.isAcceptableOrUnknown(
          data['quiet_hours_from_minutes']!,
          _quietHoursFromMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quietHoursFromMinutesMeta);
    }
    if (data.containsKey('quiet_hours_to_minutes')) {
      context.handle(
        _quietHoursToMinutesMeta,
        quietHoursToMinutes.isAcceptableOrUnknown(
          data['quiet_hours_to_minutes']!,
          _quietHoursToMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quietHoursToMinutesMeta);
    }
    if (data.containsKey('weekdays_only')) {
      context.handle(
        _weekdaysOnlyMeta,
        weekdaysOnly.isAcceptableOrUnknown(
          data['weekdays_only']!,
          _weekdaysOnlyMeta,
        ),
      );
    }
    if (data.containsKey('notify_service')) {
      context.handle(
        _notifyServiceMeta,
        notifyService.isAcceptableOrUnknown(
          data['notify_service']!,
          _notifyServiceMeta,
        ),
      );
    }
    if (data.containsKey('notify_odometer')) {
      context.handle(
        _notifyOdometerMeta,
        notifyOdometer.isAcceptableOrUnknown(
          data['notify_odometer']!,
          _notifyOdometerMeta,
        ),
      );
    }
    if (data.containsKey('notify_backup')) {
      context.handle(
        _notifyBackupMeta,
        notifyBackup.isAcceptableOrUnknown(
          data['notify_backup']!,
          _notifyBackupMeta,
        ),
      );
    }
    if (data.containsKey('active_vehicle_id')) {
      context.handle(
        _activeVehicleIdMeta,
        activeVehicleId.isAcceptableOrUnknown(
          data['active_vehicle_id']!,
          _activeVehicleIdMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
        _onboardingDoneMeta,
        onboardingDone.isAcceptableOrUnknown(
          data['onboarding_done']!,
          _onboardingDoneMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_at_utc_ms')) {
      context.handle(
        _lastBackupAtUtcMsMeta,
        lastBackupAtUtcMs.isAcceptableOrUnknown(
          data['last_backup_at_utc_ms']!,
          _lastBackupAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_reminder_at_utc_ms')) {
      context.handle(
        _lastBackupReminderAtUtcMsMeta,
        lastBackupReminderAtUtcMs.isAcceptableOrUnknown(
          data['last_backup_reminder_at_utc_ms']!,
          _lastBackupReminderAtUtcMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      calendar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar'],
      )!,
      numerals: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numerals'],
      )!,
      firstDayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_day_of_week'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      currencyDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_default'],
      )!,
      currencyDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_display'],
      )!,
      distanceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_unit'],
      )!,
      volumeUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_unit'],
      )!,
      consumptionUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consumption_unit'],
      )!,
      noticeDistanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notice_distance_m'],
      ),
      noticeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notice_days'],
      ),
      notificationTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_time_minutes'],
      )!,
      quietHoursFromMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_from_minutes'],
      )!,
      quietHoursToMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_to_minutes'],
      )!,
      weekdaysOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weekdays_only'],
      )!,
      notifyService: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_service'],
      )!,
      notifyOdometer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_odometer'],
      )!,
      notifyBackup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_backup'],
      )!,
      activeVehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_vehicle_id'],
      ),
      onboardingDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_done'],
      )!,
      lastBackupAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_backup_at_utc_ms'],
      ),
      lastBackupReminderAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_backup_reminder_at_utc_ms'],
      ),
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final String id;

  /// When the row was first written. UTC epoch milliseconds.
  final int createdAtUtcMs;

  /// When it was last changed. UTC epoch milliseconds.
  ///
  /// Never less than [createdAtUtcMs] — but repaired on READ rather than
  /// blocked on write. See `repairAuditTimes`.
  final int updatedAtUtcMs;

  /// When it was soft-deleted, or null.
  ///
  /// Soft delete is what makes Undo possible for the length of a snackbar.
  /// After that the row is purged, so a settled database has this null on
  /// every row that exists.
  final int? deletedAtUtcMs;

  /// The schema version, mirrored on write.
  ///
  /// **Drift's own `user_version` stays authoritative for the migration
  /// ladder.** This column mirrors it and is what the EXPORT reads — the
  /// backup file needs the number without opening the database. Treating the
  /// two as independent is how a restore ends up believing a version the
  /// tables do not have.
  final int schemaVersion;

  /// `system` follows the device.
  final String language;

  /// Gregorian or Jalali. Hijri is not offered in v1.
  final String calendar;

  /// Which digits are drawn. `auto` is the locale's CLDR default.
  final String numerals;

  /// 1 = Monday, 7 = Sunday, as `DateTime`'s weekday constants.
  final int firstDayOfWeek;

  /// Light, dark or the device's.
  final String theme;

  /// The ISO 4217 code new vehicles inherit.
  /// The length is checked in SQL, not with `withLength`, which is a
  /// DART-side validator that emits nothing into the schema — so an import or
  /// a migration could write `'EU'`, and the exponent that turns 4599 into
  /// 45.99 comes from this code.
  final String currencyDefault;

  /// `toman` divides a stored IRR amount by ten FOR DISPLAY. Storage stays
  /// IRR, because `IRT` is not an ISO 4217 code and a non-ISO code in a backup
  /// would fail the file's own validation.
  final String currencyDisplay;

  /// Kilometres or miles.
  final String distanceUnit;

  /// Litres or gallons.
  final String volumeUnit;

  /// How consumption reads.
  final String consumptionUnit;

  /// Global distance notice window override, in metres. Null = computed.
  final int? noticeDistanceM;

  /// Global time notice window override, in days. Null = computed.
  final int? noticeDays;

  /// When the daily due check fires, as minutes after local midnight.
  ///
  /// Minutes, not a `DateTime`: it is a LOCAL time of day and not an instant,
  /// so storing it as one would move it when the user crosses a zone. 09:00
  /// stays 09:00 in Tehran and in Toronto.
  final int notificationTimeMinutes;

  /// Quiet hours start, minutes after local midnight. Default 21:00.
  final int quietHoursFromMinutes;

  /// Quiet hours end, minutes after local midnight. Default 08:00.
  final int quietHoursToMinutes;

  /// Whether reminders only fire on weekdays.
  final bool weekdaysOnly;

  /// Whether service reminders fire.
  final bool notifyService;

  /// Whether the odometer nudge fires.
  final bool notifyOdometer;

  /// Whether the backup nudge fires.
  final bool notifyBackup;

  /// Which vehicle the app opens on.
  final String? activeVehicleId;

  /// Whether onboarding has been completed.
  final bool onboardingDone;

  /// When the last backup was written. UTC epoch milliseconds.
  final int? lastBackupAtUtcMs;

  /// When the app last nudged about a backup. UTC epoch milliseconds.
  final int? lastBackupReminderAtUtcMs;
  const SettingsRow({
    required this.id,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.deletedAtUtcMs,
    required this.schemaVersion,
    required this.language,
    required this.calendar,
    required this.numerals,
    required this.firstDayOfWeek,
    required this.theme,
    required this.currencyDefault,
    required this.currencyDisplay,
    required this.distanceUnit,
    required this.volumeUnit,
    required this.consumptionUnit,
    this.noticeDistanceM,
    this.noticeDays,
    required this.notificationTimeMinutes,
    required this.quietHoursFromMinutes,
    required this.quietHoursToMinutes,
    required this.weekdaysOnly,
    required this.notifyService,
    required this.notifyOdometer,
    required this.notifyBackup,
    this.activeVehicleId,
    required this.onboardingDone,
    this.lastBackupAtUtcMs,
    this.lastBackupReminderAtUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    map['language'] = Variable<String>(language);
    map['calendar'] = Variable<String>(calendar);
    map['numerals'] = Variable<String>(numerals);
    map['first_day_of_week'] = Variable<int>(firstDayOfWeek);
    map['theme'] = Variable<String>(theme);
    map['currency_default'] = Variable<String>(currencyDefault);
    map['currency_display'] = Variable<String>(currencyDisplay);
    map['distance_unit'] = Variable<String>(distanceUnit);
    map['volume_unit'] = Variable<String>(volumeUnit);
    map['consumption_unit'] = Variable<String>(consumptionUnit);
    if (!nullToAbsent || noticeDistanceM != null) {
      map['notice_distance_m'] = Variable<int>(noticeDistanceM);
    }
    if (!nullToAbsent || noticeDays != null) {
      map['notice_days'] = Variable<int>(noticeDays);
    }
    map['notification_time_minutes'] = Variable<int>(notificationTimeMinutes);
    map['quiet_hours_from_minutes'] = Variable<int>(quietHoursFromMinutes);
    map['quiet_hours_to_minutes'] = Variable<int>(quietHoursToMinutes);
    map['weekdays_only'] = Variable<bool>(weekdaysOnly);
    map['notify_service'] = Variable<bool>(notifyService);
    map['notify_odometer'] = Variable<bool>(notifyOdometer);
    map['notify_backup'] = Variable<bool>(notifyBackup);
    if (!nullToAbsent || activeVehicleId != null) {
      map['active_vehicle_id'] = Variable<String>(activeVehicleId);
    }
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    if (!nullToAbsent || lastBackupAtUtcMs != null) {
      map['last_backup_at_utc_ms'] = Variable<int>(lastBackupAtUtcMs);
    }
    if (!nullToAbsent || lastBackupReminderAtUtcMs != null) {
      map['last_backup_reminder_at_utc_ms'] = Variable<int>(
        lastBackupReminderAtUtcMs,
      );
    }
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      schemaVersion: Value(schemaVersion),
      language: Value(language),
      calendar: Value(calendar),
      numerals: Value(numerals),
      firstDayOfWeek: Value(firstDayOfWeek),
      theme: Value(theme),
      currencyDefault: Value(currencyDefault),
      currencyDisplay: Value(currencyDisplay),
      distanceUnit: Value(distanceUnit),
      volumeUnit: Value(volumeUnit),
      consumptionUnit: Value(consumptionUnit),
      noticeDistanceM: noticeDistanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(noticeDistanceM),
      noticeDays: noticeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(noticeDays),
      notificationTimeMinutes: Value(notificationTimeMinutes),
      quietHoursFromMinutes: Value(quietHoursFromMinutes),
      quietHoursToMinutes: Value(quietHoursToMinutes),
      weekdaysOnly: Value(weekdaysOnly),
      notifyService: Value(notifyService),
      notifyOdometer: Value(notifyOdometer),
      notifyBackup: Value(notifyBackup),
      activeVehicleId: activeVehicleId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeVehicleId),
      onboardingDone: Value(onboardingDone),
      lastBackupAtUtcMs: lastBackupAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAtUtcMs),
      lastBackupReminderAtUtcMs:
          lastBackupReminderAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupReminderAtUtcMs),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      language: serializer.fromJson<String>(json['language']),
      calendar: serializer.fromJson<String>(json['calendar']),
      numerals: serializer.fromJson<String>(json['numerals']),
      firstDayOfWeek: serializer.fromJson<int>(json['firstDayOfWeek']),
      theme: serializer.fromJson<String>(json['theme']),
      currencyDefault: serializer.fromJson<String>(json['currencyDefault']),
      currencyDisplay: serializer.fromJson<String>(json['currencyDisplay']),
      distanceUnit: serializer.fromJson<String>(json['distanceUnit']),
      volumeUnit: serializer.fromJson<String>(json['volumeUnit']),
      consumptionUnit: serializer.fromJson<String>(json['consumptionUnit']),
      noticeDistanceM: serializer.fromJson<int?>(json['noticeDistanceM']),
      noticeDays: serializer.fromJson<int?>(json['noticeDays']),
      notificationTimeMinutes: serializer.fromJson<int>(
        json['notificationTimeMinutes'],
      ),
      quietHoursFromMinutes: serializer.fromJson<int>(
        json['quietHoursFromMinutes'],
      ),
      quietHoursToMinutes: serializer.fromJson<int>(
        json['quietHoursToMinutes'],
      ),
      weekdaysOnly: serializer.fromJson<bool>(json['weekdaysOnly']),
      notifyService: serializer.fromJson<bool>(json['notifyService']),
      notifyOdometer: serializer.fromJson<bool>(json['notifyOdometer']),
      notifyBackup: serializer.fromJson<bool>(json['notifyBackup']),
      activeVehicleId: serializer.fromJson<String?>(json['activeVehicleId']),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      lastBackupAtUtcMs: serializer.fromJson<int?>(json['lastBackupAtUtcMs']),
      lastBackupReminderAtUtcMs: serializer.fromJson<int?>(
        json['lastBackupReminderAtUtcMs'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'language': serializer.toJson<String>(language),
      'calendar': serializer.toJson<String>(calendar),
      'numerals': serializer.toJson<String>(numerals),
      'firstDayOfWeek': serializer.toJson<int>(firstDayOfWeek),
      'theme': serializer.toJson<String>(theme),
      'currencyDefault': serializer.toJson<String>(currencyDefault),
      'currencyDisplay': serializer.toJson<String>(currencyDisplay),
      'distanceUnit': serializer.toJson<String>(distanceUnit),
      'volumeUnit': serializer.toJson<String>(volumeUnit),
      'consumptionUnit': serializer.toJson<String>(consumptionUnit),
      'noticeDistanceM': serializer.toJson<int?>(noticeDistanceM),
      'noticeDays': serializer.toJson<int?>(noticeDays),
      'notificationTimeMinutes': serializer.toJson<int>(
        notificationTimeMinutes,
      ),
      'quietHoursFromMinutes': serializer.toJson<int>(quietHoursFromMinutes),
      'quietHoursToMinutes': serializer.toJson<int>(quietHoursToMinutes),
      'weekdaysOnly': serializer.toJson<bool>(weekdaysOnly),
      'notifyService': serializer.toJson<bool>(notifyService),
      'notifyOdometer': serializer.toJson<bool>(notifyOdometer),
      'notifyBackup': serializer.toJson<bool>(notifyBackup),
      'activeVehicleId': serializer.toJson<String?>(activeVehicleId),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'lastBackupAtUtcMs': serializer.toJson<int?>(lastBackupAtUtcMs),
      'lastBackupReminderAtUtcMs': serializer.toJson<int?>(
        lastBackupReminderAtUtcMs,
      ),
    };
  }

  SettingsRow copyWith({
    String? id,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    int? schemaVersion,
    String? language,
    String? calendar,
    String? numerals,
    int? firstDayOfWeek,
    String? theme,
    String? currencyDefault,
    String? currencyDisplay,
    String? distanceUnit,
    String? volumeUnit,
    String? consumptionUnit,
    Value<int?> noticeDistanceM = const Value.absent(),
    Value<int?> noticeDays = const Value.absent(),
    int? notificationTimeMinutes,
    int? quietHoursFromMinutes,
    int? quietHoursToMinutes,
    bool? weekdaysOnly,
    bool? notifyService,
    bool? notifyOdometer,
    bool? notifyBackup,
    Value<String?> activeVehicleId = const Value.absent(),
    bool? onboardingDone,
    Value<int?> lastBackupAtUtcMs = const Value.absent(),
    Value<int?> lastBackupReminderAtUtcMs = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    language: language ?? this.language,
    calendar: calendar ?? this.calendar,
    numerals: numerals ?? this.numerals,
    firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    theme: theme ?? this.theme,
    currencyDefault: currencyDefault ?? this.currencyDefault,
    currencyDisplay: currencyDisplay ?? this.currencyDisplay,
    distanceUnit: distanceUnit ?? this.distanceUnit,
    volumeUnit: volumeUnit ?? this.volumeUnit,
    consumptionUnit: consumptionUnit ?? this.consumptionUnit,
    noticeDistanceM: noticeDistanceM.present
        ? noticeDistanceM.value
        : this.noticeDistanceM,
    noticeDays: noticeDays.present ? noticeDays.value : this.noticeDays,
    notificationTimeMinutes:
        notificationTimeMinutes ?? this.notificationTimeMinutes,
    quietHoursFromMinutes: quietHoursFromMinutes ?? this.quietHoursFromMinutes,
    quietHoursToMinutes: quietHoursToMinutes ?? this.quietHoursToMinutes,
    weekdaysOnly: weekdaysOnly ?? this.weekdaysOnly,
    notifyService: notifyService ?? this.notifyService,
    notifyOdometer: notifyOdometer ?? this.notifyOdometer,
    notifyBackup: notifyBackup ?? this.notifyBackup,
    activeVehicleId: activeVehicleId.present
        ? activeVehicleId.value
        : this.activeVehicleId,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    lastBackupAtUtcMs: lastBackupAtUtcMs.present
        ? lastBackupAtUtcMs.value
        : this.lastBackupAtUtcMs,
    lastBackupReminderAtUtcMs: lastBackupReminderAtUtcMs.present
        ? lastBackupReminderAtUtcMs.value
        : this.lastBackupReminderAtUtcMs,
  );
  SettingsRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      language: data.language.present ? data.language.value : this.language,
      calendar: data.calendar.present ? data.calendar.value : this.calendar,
      numerals: data.numerals.present ? data.numerals.value : this.numerals,
      firstDayOfWeek: data.firstDayOfWeek.present
          ? data.firstDayOfWeek.value
          : this.firstDayOfWeek,
      theme: data.theme.present ? data.theme.value : this.theme,
      currencyDefault: data.currencyDefault.present
          ? data.currencyDefault.value
          : this.currencyDefault,
      currencyDisplay: data.currencyDisplay.present
          ? data.currencyDisplay.value
          : this.currencyDisplay,
      distanceUnit: data.distanceUnit.present
          ? data.distanceUnit.value
          : this.distanceUnit,
      volumeUnit: data.volumeUnit.present
          ? data.volumeUnit.value
          : this.volumeUnit,
      consumptionUnit: data.consumptionUnit.present
          ? data.consumptionUnit.value
          : this.consumptionUnit,
      noticeDistanceM: data.noticeDistanceM.present
          ? data.noticeDistanceM.value
          : this.noticeDistanceM,
      noticeDays: data.noticeDays.present
          ? data.noticeDays.value
          : this.noticeDays,
      notificationTimeMinutes: data.notificationTimeMinutes.present
          ? data.notificationTimeMinutes.value
          : this.notificationTimeMinutes,
      quietHoursFromMinutes: data.quietHoursFromMinutes.present
          ? data.quietHoursFromMinutes.value
          : this.quietHoursFromMinutes,
      quietHoursToMinutes: data.quietHoursToMinutes.present
          ? data.quietHoursToMinutes.value
          : this.quietHoursToMinutes,
      weekdaysOnly: data.weekdaysOnly.present
          ? data.weekdaysOnly.value
          : this.weekdaysOnly,
      notifyService: data.notifyService.present
          ? data.notifyService.value
          : this.notifyService,
      notifyOdometer: data.notifyOdometer.present
          ? data.notifyOdometer.value
          : this.notifyOdometer,
      notifyBackup: data.notifyBackup.present
          ? data.notifyBackup.value
          : this.notifyBackup,
      activeVehicleId: data.activeVehicleId.present
          ? data.activeVehicleId.value
          : this.activeVehicleId,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
      lastBackupAtUtcMs: data.lastBackupAtUtcMs.present
          ? data.lastBackupAtUtcMs.value
          : this.lastBackupAtUtcMs,
      lastBackupReminderAtUtcMs: data.lastBackupReminderAtUtcMs.present
          ? data.lastBackupReminderAtUtcMs.value
          : this.lastBackupReminderAtUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('language: $language, ')
          ..write('calendar: $calendar, ')
          ..write('numerals: $numerals, ')
          ..write('firstDayOfWeek: $firstDayOfWeek, ')
          ..write('theme: $theme, ')
          ..write('currencyDefault: $currencyDefault, ')
          ..write('currencyDisplay: $currencyDisplay, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('volumeUnit: $volumeUnit, ')
          ..write('consumptionUnit: $consumptionUnit, ')
          ..write('noticeDistanceM: $noticeDistanceM, ')
          ..write('noticeDays: $noticeDays, ')
          ..write('notificationTimeMinutes: $notificationTimeMinutes, ')
          ..write('quietHoursFromMinutes: $quietHoursFromMinutes, ')
          ..write('quietHoursToMinutes: $quietHoursToMinutes, ')
          ..write('weekdaysOnly: $weekdaysOnly, ')
          ..write('notifyService: $notifyService, ')
          ..write('notifyOdometer: $notifyOdometer, ')
          ..write('notifyBackup: $notifyBackup, ')
          ..write('activeVehicleId: $activeVehicleId, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('lastBackupAtUtcMs: $lastBackupAtUtcMs, ')
          ..write('lastBackupReminderAtUtcMs: $lastBackupReminderAtUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    deletedAtUtcMs,
    schemaVersion,
    language,
    calendar,
    numerals,
    firstDayOfWeek,
    theme,
    currencyDefault,
    currencyDisplay,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
    noticeDistanceM,
    noticeDays,
    notificationTimeMinutes,
    quietHoursFromMinutes,
    quietHoursToMinutes,
    weekdaysOnly,
    notifyService,
    notifyOdometer,
    notifyBackup,
    activeVehicleId,
    onboardingDone,
    lastBackupAtUtcMs,
    lastBackupReminderAtUtcMs,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.schemaVersion == this.schemaVersion &&
          other.language == this.language &&
          other.calendar == this.calendar &&
          other.numerals == this.numerals &&
          other.firstDayOfWeek == this.firstDayOfWeek &&
          other.theme == this.theme &&
          other.currencyDefault == this.currencyDefault &&
          other.currencyDisplay == this.currencyDisplay &&
          other.distanceUnit == this.distanceUnit &&
          other.volumeUnit == this.volumeUnit &&
          other.consumptionUnit == this.consumptionUnit &&
          other.noticeDistanceM == this.noticeDistanceM &&
          other.noticeDays == this.noticeDays &&
          other.notificationTimeMinutes == this.notificationTimeMinutes &&
          other.quietHoursFromMinutes == this.quietHoursFromMinutes &&
          other.quietHoursToMinutes == this.quietHoursToMinutes &&
          other.weekdaysOnly == this.weekdaysOnly &&
          other.notifyService == this.notifyService &&
          other.notifyOdometer == this.notifyOdometer &&
          other.notifyBackup == this.notifyBackup &&
          other.activeVehicleId == this.activeVehicleId &&
          other.onboardingDone == this.onboardingDone &&
          other.lastBackupAtUtcMs == this.lastBackupAtUtcMs &&
          other.lastBackupReminderAtUtcMs == this.lastBackupReminderAtUtcMs);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<String> id;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int?> deletedAtUtcMs;
  final Value<int> schemaVersion;
  final Value<String> language;
  final Value<String> calendar;
  final Value<String> numerals;
  final Value<int> firstDayOfWeek;
  final Value<String> theme;
  final Value<String> currencyDefault;
  final Value<String> currencyDisplay;
  final Value<String> distanceUnit;
  final Value<String> volumeUnit;
  final Value<String> consumptionUnit;
  final Value<int?> noticeDistanceM;
  final Value<int?> noticeDays;
  final Value<int> notificationTimeMinutes;
  final Value<int> quietHoursFromMinutes;
  final Value<int> quietHoursToMinutes;
  final Value<bool> weekdaysOnly;
  final Value<bool> notifyService;
  final Value<bool> notifyOdometer;
  final Value<bool> notifyBackup;
  final Value<String?> activeVehicleId;
  final Value<bool> onboardingDone;
  final Value<int?> lastBackupAtUtcMs;
  final Value<int?> lastBackupReminderAtUtcMs;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.language = const Value.absent(),
    this.calendar = const Value.absent(),
    this.numerals = const Value.absent(),
    this.firstDayOfWeek = const Value.absent(),
    this.theme = const Value.absent(),
    this.currencyDefault = const Value.absent(),
    this.currencyDisplay = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.volumeUnit = const Value.absent(),
    this.consumptionUnit = const Value.absent(),
    this.noticeDistanceM = const Value.absent(),
    this.noticeDays = const Value.absent(),
    this.notificationTimeMinutes = const Value.absent(),
    this.quietHoursFromMinutes = const Value.absent(),
    this.quietHoursToMinutes = const Value.absent(),
    this.weekdaysOnly = const Value.absent(),
    this.notifyService = const Value.absent(),
    this.notifyOdometer = const Value.absent(),
    this.notifyBackup = const Value.absent(),
    this.activeVehicleId = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.lastBackupAtUtcMs = const Value.absent(),
    this.lastBackupReminderAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String id,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.deletedAtUtcMs = const Value.absent(),
    required int schemaVersion,
    required String language,
    required String calendar,
    required String numerals,
    required int firstDayOfWeek,
    required String theme,
    required String currencyDefault,
    required String currencyDisplay,
    required String distanceUnit,
    required String volumeUnit,
    required String consumptionUnit,
    this.noticeDistanceM = const Value.absent(),
    this.noticeDays = const Value.absent(),
    required int notificationTimeMinutes,
    required int quietHoursFromMinutes,
    required int quietHoursToMinutes,
    this.weekdaysOnly = const Value.absent(),
    this.notifyService = const Value.absent(),
    this.notifyOdometer = const Value.absent(),
    this.notifyBackup = const Value.absent(),
    this.activeVehicleId = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.lastBackupAtUtcMs = const Value.absent(),
    this.lastBackupReminderAtUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs),
       schemaVersion = Value(schemaVersion),
       language = Value(language),
       calendar = Value(calendar),
       numerals = Value(numerals),
       firstDayOfWeek = Value(firstDayOfWeek),
       theme = Value(theme),
       currencyDefault = Value(currencyDefault),
       currencyDisplay = Value(currencyDisplay),
       distanceUnit = Value(distanceUnit),
       volumeUnit = Value(volumeUnit),
       consumptionUnit = Value(consumptionUnit),
       notificationTimeMinutes = Value(notificationTimeMinutes),
       quietHoursFromMinutes = Value(quietHoursFromMinutes),
       quietHoursToMinutes = Value(quietHoursToMinutes);
  static Insertable<SettingsRow> custom({
    Expression<String>? id,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? deletedAtUtcMs,
    Expression<int>? schemaVersion,
    Expression<String>? language,
    Expression<String>? calendar,
    Expression<String>? numerals,
    Expression<int>? firstDayOfWeek,
    Expression<String>? theme,
    Expression<String>? currencyDefault,
    Expression<String>? currencyDisplay,
    Expression<String>? distanceUnit,
    Expression<String>? volumeUnit,
    Expression<String>? consumptionUnit,
    Expression<int>? noticeDistanceM,
    Expression<int>? noticeDays,
    Expression<int>? notificationTimeMinutes,
    Expression<int>? quietHoursFromMinutes,
    Expression<int>? quietHoursToMinutes,
    Expression<bool>? weekdaysOnly,
    Expression<bool>? notifyService,
    Expression<bool>? notifyOdometer,
    Expression<bool>? notifyBackup,
    Expression<String>? activeVehicleId,
    Expression<bool>? onboardingDone,
    Expression<int>? lastBackupAtUtcMs,
    Expression<int>? lastBackupReminderAtUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (language != null) 'language': language,
      if (calendar != null) 'calendar': calendar,
      if (numerals != null) 'numerals': numerals,
      if (firstDayOfWeek != null) 'first_day_of_week': firstDayOfWeek,
      if (theme != null) 'theme': theme,
      if (currencyDefault != null) 'currency_default': currencyDefault,
      if (currencyDisplay != null) 'currency_display': currencyDisplay,
      if (distanceUnit != null) 'distance_unit': distanceUnit,
      if (volumeUnit != null) 'volume_unit': volumeUnit,
      if (consumptionUnit != null) 'consumption_unit': consumptionUnit,
      if (noticeDistanceM != null) 'notice_distance_m': noticeDistanceM,
      if (noticeDays != null) 'notice_days': noticeDays,
      if (notificationTimeMinutes != null)
        'notification_time_minutes': notificationTimeMinutes,
      if (quietHoursFromMinutes != null)
        'quiet_hours_from_minutes': quietHoursFromMinutes,
      if (quietHoursToMinutes != null)
        'quiet_hours_to_minutes': quietHoursToMinutes,
      if (weekdaysOnly != null) 'weekdays_only': weekdaysOnly,
      if (notifyService != null) 'notify_service': notifyService,
      if (notifyOdometer != null) 'notify_odometer': notifyOdometer,
      if (notifyBackup != null) 'notify_backup': notifyBackup,
      if (activeVehicleId != null) 'active_vehicle_id': activeVehicleId,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (lastBackupAtUtcMs != null) 'last_backup_at_utc_ms': lastBackupAtUtcMs,
      if (lastBackupReminderAtUtcMs != null)
        'last_backup_reminder_at_utc_ms': lastBackupReminderAtUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int?>? deletedAtUtcMs,
    Value<int>? schemaVersion,
    Value<String>? language,
    Value<String>? calendar,
    Value<String>? numerals,
    Value<int>? firstDayOfWeek,
    Value<String>? theme,
    Value<String>? currencyDefault,
    Value<String>? currencyDisplay,
    Value<String>? distanceUnit,
    Value<String>? volumeUnit,
    Value<String>? consumptionUnit,
    Value<int?>? noticeDistanceM,
    Value<int?>? noticeDays,
    Value<int>? notificationTimeMinutes,
    Value<int>? quietHoursFromMinutes,
    Value<int>? quietHoursToMinutes,
    Value<bool>? weekdaysOnly,
    Value<bool>? notifyService,
    Value<bool>? notifyOdometer,
    Value<bool>? notifyBackup,
    Value<String?>? activeVehicleId,
    Value<bool>? onboardingDone,
    Value<int?>? lastBackupAtUtcMs,
    Value<int?>? lastBackupReminderAtUtcMs,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      language: language ?? this.language,
      calendar: calendar ?? this.calendar,
      numerals: numerals ?? this.numerals,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      theme: theme ?? this.theme,
      currencyDefault: currencyDefault ?? this.currencyDefault,
      currencyDisplay: currencyDisplay ?? this.currencyDisplay,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      consumptionUnit: consumptionUnit ?? this.consumptionUnit,
      noticeDistanceM: noticeDistanceM ?? this.noticeDistanceM,
      noticeDays: noticeDays ?? this.noticeDays,
      notificationTimeMinutes:
          notificationTimeMinutes ?? this.notificationTimeMinutes,
      quietHoursFromMinutes:
          quietHoursFromMinutes ?? this.quietHoursFromMinutes,
      quietHoursToMinutes: quietHoursToMinutes ?? this.quietHoursToMinutes,
      weekdaysOnly: weekdaysOnly ?? this.weekdaysOnly,
      notifyService: notifyService ?? this.notifyService,
      notifyOdometer: notifyOdometer ?? this.notifyOdometer,
      notifyBackup: notifyBackup ?? this.notifyBackup,
      activeVehicleId: activeVehicleId ?? this.activeVehicleId,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      lastBackupAtUtcMs: lastBackupAtUtcMs ?? this.lastBackupAtUtcMs,
      lastBackupReminderAtUtcMs:
          lastBackupReminderAtUtcMs ?? this.lastBackupReminderAtUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (calendar.present) {
      map['calendar'] = Variable<String>(calendar.value);
    }
    if (numerals.present) {
      map['numerals'] = Variable<String>(numerals.value);
    }
    if (firstDayOfWeek.present) {
      map['first_day_of_week'] = Variable<int>(firstDayOfWeek.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (currencyDefault.present) {
      map['currency_default'] = Variable<String>(currencyDefault.value);
    }
    if (currencyDisplay.present) {
      map['currency_display'] = Variable<String>(currencyDisplay.value);
    }
    if (distanceUnit.present) {
      map['distance_unit'] = Variable<String>(distanceUnit.value);
    }
    if (volumeUnit.present) {
      map['volume_unit'] = Variable<String>(volumeUnit.value);
    }
    if (consumptionUnit.present) {
      map['consumption_unit'] = Variable<String>(consumptionUnit.value);
    }
    if (noticeDistanceM.present) {
      map['notice_distance_m'] = Variable<int>(noticeDistanceM.value);
    }
    if (noticeDays.present) {
      map['notice_days'] = Variable<int>(noticeDays.value);
    }
    if (notificationTimeMinutes.present) {
      map['notification_time_minutes'] = Variable<int>(
        notificationTimeMinutes.value,
      );
    }
    if (quietHoursFromMinutes.present) {
      map['quiet_hours_from_minutes'] = Variable<int>(
        quietHoursFromMinutes.value,
      );
    }
    if (quietHoursToMinutes.present) {
      map['quiet_hours_to_minutes'] = Variable<int>(quietHoursToMinutes.value);
    }
    if (weekdaysOnly.present) {
      map['weekdays_only'] = Variable<bool>(weekdaysOnly.value);
    }
    if (notifyService.present) {
      map['notify_service'] = Variable<bool>(notifyService.value);
    }
    if (notifyOdometer.present) {
      map['notify_odometer'] = Variable<bool>(notifyOdometer.value);
    }
    if (notifyBackup.present) {
      map['notify_backup'] = Variable<bool>(notifyBackup.value);
    }
    if (activeVehicleId.present) {
      map['active_vehicle_id'] = Variable<String>(activeVehicleId.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (lastBackupAtUtcMs.present) {
      map['last_backup_at_utc_ms'] = Variable<int>(lastBackupAtUtcMs.value);
    }
    if (lastBackupReminderAtUtcMs.present) {
      map['last_backup_reminder_at_utc_ms'] = Variable<int>(
        lastBackupReminderAtUtcMs.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('language: $language, ')
          ..write('calendar: $calendar, ')
          ..write('numerals: $numerals, ')
          ..write('firstDayOfWeek: $firstDayOfWeek, ')
          ..write('theme: $theme, ')
          ..write('currencyDefault: $currencyDefault, ')
          ..write('currencyDisplay: $currencyDisplay, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('volumeUnit: $volumeUnit, ')
          ..write('consumptionUnit: $consumptionUnit, ')
          ..write('noticeDistanceM: $noticeDistanceM, ')
          ..write('noticeDays: $noticeDays, ')
          ..write('notificationTimeMinutes: $notificationTimeMinutes, ')
          ..write('quietHoursFromMinutes: $quietHoursFromMinutes, ')
          ..write('quietHoursToMinutes: $quietHoursToMinutes, ')
          ..write('weekdaysOnly: $weekdaysOnly, ')
          ..write('notifyService: $notifyService, ')
          ..write('notifyOdometer: $notifyOdometer, ')
          ..write('notifyBackup: $notifyBackup, ')
          ..write('activeVehicleId: $activeVehicleId, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('lastBackupAtUtcMs: $lastBackupAtUtcMs, ')
          ..write('lastBackupReminderAtUtcMs: $lastBackupReminderAtUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $ServiceItemsTable serviceItems = $ServiceItemsTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vehicles,
    serviceItems,
    settingsTable,
  ];
}

typedef $$VehiclesTableCreateCompanionBuilder =
    VehiclesCompanion Function({
      required String id,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      required String name,
      Value<String?> make,
      Value<String?> model,
      Value<int?> year,
      Value<String?> plate,
      Value<String?> vin,
      required String vehicleType,
      Value<bool> isBusiness,
      required String fuelKindDefault,
      Value<int?> tankCapacityMl,
      Value<String?> purchaseDate,
      Value<int?> purchaseOdometerM,
      Value<int?> purchasePriceMinor,
      Value<String?> purchasePriceCurrency,
      required String status,
      Value<String?> soldOn,
      Value<int?> soldPriceMinor,
      Value<String?> soldPriceCurrency,
      Value<int?> expectedAnnualM,
      Value<String?> colour,
      Value<String?> notes,
      Value<int> sortOrder,
      Value<bool> notificationsMuted,
      Value<String?> currency,
      Value<String?> distanceUnit,
      Value<String?> volumeUnit,
      Value<String?> consumptionUnit,
      Value<int?> noticeDistanceM,
      Value<int?> noticeDays,
      Value<int> rowid,
    });
typedef $$VehiclesTableUpdateCompanionBuilder =
    VehiclesCompanion Function({
      Value<String> id,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      Value<String> name,
      Value<String?> make,
      Value<String?> model,
      Value<int?> year,
      Value<String?> plate,
      Value<String?> vin,
      Value<String> vehicleType,
      Value<bool> isBusiness,
      Value<String> fuelKindDefault,
      Value<int?> tankCapacityMl,
      Value<String?> purchaseDate,
      Value<int?> purchaseOdometerM,
      Value<int?> purchasePriceMinor,
      Value<String?> purchasePriceCurrency,
      Value<String> status,
      Value<String?> soldOn,
      Value<int?> soldPriceMinor,
      Value<String?> soldPriceCurrency,
      Value<int?> expectedAnnualM,
      Value<String?> colour,
      Value<String?> notes,
      Value<int> sortOrder,
      Value<bool> notificationsMuted,
      Value<String?> currency,
      Value<String?> distanceUnit,
      Value<String?> volumeUnit,
      Value<String?> consumptionUnit,
      Value<int?> noticeDistanceM,
      Value<int?> noticeDays,
      Value<int> rowid,
    });

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plate => $composableBuilder(
    column: $table.plate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vin => $composableBuilder(
    column: $table.vin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBusiness => $composableBuilder(
    column: $table.isBusiness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelKindDefault => $composableBuilder(
    column: $table.fuelKindDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tankCapacityMl => $composableBuilder(
    column: $table.tankCapacityMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchaseOdometerM => $composableBuilder(
    column: $table.purchaseOdometerM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePriceMinor => $composableBuilder(
    column: $table.purchasePriceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchasePriceCurrency => $composableBuilder(
    column: $table.purchasePriceCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soldOn => $composableBuilder(
    column: $table.soldOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get soldPriceMinor => $composableBuilder(
    column: $table.soldPriceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soldPriceCurrency => $composableBuilder(
    column: $table.soldPriceCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedAnnualM => $composableBuilder(
    column: $table.expectedAnnualM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsMuted => $composableBuilder(
    column: $table.notificationsMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get volumeUnit => $composableBuilder(
    column: $table.volumeUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consumptionUnit => $composableBuilder(
    column: $table.consumptionUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plate => $composableBuilder(
    column: $table.plate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vin => $composableBuilder(
    column: $table.vin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBusiness => $composableBuilder(
    column: $table.isBusiness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelKindDefault => $composableBuilder(
    column: $table.fuelKindDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tankCapacityMl => $composableBuilder(
    column: $table.tankCapacityMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchaseOdometerM => $composableBuilder(
    column: $table.purchaseOdometerM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePriceMinor => $composableBuilder(
    column: $table.purchasePriceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchasePriceCurrency => $composableBuilder(
    column: $table.purchasePriceCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soldOn => $composableBuilder(
    column: $table.soldOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soldPriceMinor => $composableBuilder(
    column: $table.soldPriceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soldPriceCurrency => $composableBuilder(
    column: $table.soldPriceCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedAnnualM => $composableBuilder(
    column: $table.expectedAnnualM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsMuted => $composableBuilder(
    column: $table.notificationsMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volumeUnit => $composableBuilder(
    column: $table.volumeUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consumptionUnit => $composableBuilder(
    column: $table.consumptionUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get make =>
      $composableBuilder(column: $table.make, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get plate =>
      $composableBuilder(column: $table.plate, builder: (column) => column);

  GeneratedColumn<String> get vin =>
      $composableBuilder(column: $table.vin, builder: (column) => column);

  GeneratedColumn<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBusiness => $composableBuilder(
    column: $table.isBusiness,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fuelKindDefault => $composableBuilder(
    column: $table.fuelKindDefault,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tankCapacityMl => $composableBuilder(
    column: $table.tankCapacityMl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchaseOdometerM => $composableBuilder(
    column: $table.purchaseOdometerM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePriceMinor => $composableBuilder(
    column: $table.purchasePriceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchasePriceCurrency => $composableBuilder(
    column: $table.purchasePriceCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get soldOn =>
      $composableBuilder(column: $table.soldOn, builder: (column) => column);

  GeneratedColumn<int> get soldPriceMinor => $composableBuilder(
    column: $table.soldPriceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soldPriceCurrency => $composableBuilder(
    column: $table.soldPriceCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedAnnualM => $composableBuilder(
    column: $table.expectedAnnualM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get notificationsMuted => $composableBuilder(
    column: $table.notificationsMuted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get volumeUnit => $composableBuilder(
    column: $table.volumeUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consumptionUnit => $composableBuilder(
    column: $table.consumptionUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => column,
  );
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          VehicleRow,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (
            VehicleRow,
            BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow>,
          ),
          VehicleRow,
          PrefetchHooks Function()
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> make = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> plate = const Value.absent(),
                Value<String?> vin = const Value.absent(),
                Value<String> vehicleType = const Value.absent(),
                Value<bool> isBusiness = const Value.absent(),
                Value<String> fuelKindDefault = const Value.absent(),
                Value<int?> tankCapacityMl = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<int?> purchaseOdometerM = const Value.absent(),
                Value<int?> purchasePriceMinor = const Value.absent(),
                Value<String?> purchasePriceCurrency = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> soldOn = const Value.absent(),
                Value<int?> soldPriceMinor = const Value.absent(),
                Value<String?> soldPriceCurrency = const Value.absent(),
                Value<int?> expectedAnnualM = const Value.absent(),
                Value<String?> colour = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> notificationsMuted = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<String?> distanceUnit = const Value.absent(),
                Value<String?> volumeUnit = const Value.absent(),
                Value<String?> consumptionUnit = const Value.absent(),
                Value<int?> noticeDistanceM = const Value.absent(),
                Value<int?> noticeDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                name: name,
                make: make,
                model: model,
                year: year,
                plate: plate,
                vin: vin,
                vehicleType: vehicleType,
                isBusiness: isBusiness,
                fuelKindDefault: fuelKindDefault,
                tankCapacityMl: tankCapacityMl,
                purchaseDate: purchaseDate,
                purchaseOdometerM: purchaseOdometerM,
                purchasePriceMinor: purchasePriceMinor,
                purchasePriceCurrency: purchasePriceCurrency,
                status: status,
                soldOn: soldOn,
                soldPriceMinor: soldPriceMinor,
                soldPriceCurrency: soldPriceCurrency,
                expectedAnnualM: expectedAnnualM,
                colour: colour,
                notes: notes,
                sortOrder: sortOrder,
                notificationsMuted: notificationsMuted,
                currency: currency,
                distanceUnit: distanceUnit,
                volumeUnit: volumeUnit,
                consumptionUnit: consumptionUnit,
                noticeDistanceM: noticeDistanceM,
                noticeDays: noticeDays,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int?> deletedAtUtcMs = const Value.absent(),
                required String name,
                Value<String?> make = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> plate = const Value.absent(),
                Value<String?> vin = const Value.absent(),
                required String vehicleType,
                Value<bool> isBusiness = const Value.absent(),
                required String fuelKindDefault,
                Value<int?> tankCapacityMl = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<int?> purchaseOdometerM = const Value.absent(),
                Value<int?> purchasePriceMinor = const Value.absent(),
                Value<String?> purchasePriceCurrency = const Value.absent(),
                required String status,
                Value<String?> soldOn = const Value.absent(),
                Value<int?> soldPriceMinor = const Value.absent(),
                Value<String?> soldPriceCurrency = const Value.absent(),
                Value<int?> expectedAnnualM = const Value.absent(),
                Value<String?> colour = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> notificationsMuted = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<String?> distanceUnit = const Value.absent(),
                Value<String?> volumeUnit = const Value.absent(),
                Value<String?> consumptionUnit = const Value.absent(),
                Value<int?> noticeDistanceM = const Value.absent(),
                Value<int?> noticeDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                name: name,
                make: make,
                model: model,
                year: year,
                plate: plate,
                vin: vin,
                vehicleType: vehicleType,
                isBusiness: isBusiness,
                fuelKindDefault: fuelKindDefault,
                tankCapacityMl: tankCapacityMl,
                purchaseDate: purchaseDate,
                purchaseOdometerM: purchaseOdometerM,
                purchasePriceMinor: purchasePriceMinor,
                purchasePriceCurrency: purchasePriceCurrency,
                status: status,
                soldOn: soldOn,
                soldPriceMinor: soldPriceMinor,
                soldPriceCurrency: soldPriceCurrency,
                expectedAnnualM: expectedAnnualM,
                colour: colour,
                notes: notes,
                sortOrder: sortOrder,
                notificationsMuted: notificationsMuted,
                currency: currency,
                distanceUnit: distanceUnit,
                volumeUnit: volumeUnit,
                consumptionUnit: consumptionUnit,
                noticeDistanceM: noticeDistanceM,
                noticeDays: noticeDays,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      VehicleRow,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (VehicleRow, BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow>),
      VehicleRow,
      PrefetchHooks Function()
    >;
typedef $$ServiceItemsTableCreateCompanionBuilder =
    ServiceItemsCompanion Function({
      required String id,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      required String vehicleId,
      required String kind,
      Value<String?> label,
      Value<int?> intervalDistanceM,
      Value<String?> intervalDistanceUnit,
      Value<int?> intervalMonths,
      Value<int?> targetOdometerM,
      Value<String?> targetDate,
      Value<String?> baselineDate,
      Value<int?> baselineOdometerM,
      Value<int?> noticeDistanceM,
      Value<int?> noticeDays,
      Value<bool> isTracked,
      Value<bool> isActive,
      Value<bool> notify,
      required String priority,
      required String rollover,
      Value<bool> repeats,
      Value<String?> snoozedUntil,
      Value<int?> snoozeUntilOdometerM,
      Value<int> snoozeCount,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$ServiceItemsTableUpdateCompanionBuilder =
    ServiceItemsCompanion Function({
      Value<String> id,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      Value<String> vehicleId,
      Value<String> kind,
      Value<String?> label,
      Value<int?> intervalDistanceM,
      Value<String?> intervalDistanceUnit,
      Value<int?> intervalMonths,
      Value<int?> targetOdometerM,
      Value<String?> targetDate,
      Value<String?> baselineDate,
      Value<int?> baselineOdometerM,
      Value<int?> noticeDistanceM,
      Value<int?> noticeDays,
      Value<bool> isTracked,
      Value<bool> isActive,
      Value<bool> notify,
      Value<String> priority,
      Value<String> rollover,
      Value<bool> repeats,
      Value<String?> snoozedUntil,
      Value<int?> snoozeUntilOdometerM,
      Value<int> snoozeCount,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$ServiceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ServiceItemsTable> {
  $$ServiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDistanceM => $composableBuilder(
    column: $table.intervalDistanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intervalDistanceUnit => $composableBuilder(
    column: $table.intervalDistanceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetOdometerM => $composableBuilder(
    column: $table.targetOdometerM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baselineOdometerM => $composableBuilder(
    column: $table.baselineOdometerM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTracked => $composableBuilder(
    column: $table.isTracked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notify => $composableBuilder(
    column: $table.notify,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rollover => $composableBuilder(
    column: $table.rollover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get repeats => $composableBuilder(
    column: $table.repeats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeUntilOdometerM => $composableBuilder(
    column: $table.snoozeUntilOdometerM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServiceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ServiceItemsTable> {
  $$ServiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDistanceM => $composableBuilder(
    column: $table.intervalDistanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intervalDistanceUnit => $composableBuilder(
    column: $table.intervalDistanceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetOdometerM => $composableBuilder(
    column: $table.targetOdometerM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baselineOdometerM => $composableBuilder(
    column: $table.baselineOdometerM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTracked => $composableBuilder(
    column: $table.isTracked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notify => $composableBuilder(
    column: $table.notify,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rollover => $composableBuilder(
    column: $table.rollover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get repeats => $composableBuilder(
    column: $table.repeats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeUntilOdometerM => $composableBuilder(
    column: $table.snoozeUntilOdometerM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServiceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServiceItemsTable> {
  $$ServiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get intervalDistanceM => $composableBuilder(
    column: $table.intervalDistanceM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intervalDistanceUnit => $composableBuilder(
    column: $table.intervalDistanceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalMonths => $composableBuilder(
    column: $table.intervalMonths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetOdometerM => $composableBuilder(
    column: $table.targetOdometerM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baselineOdometerM => $composableBuilder(
    column: $table.baselineOdometerM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTracked =>
      $composableBuilder(column: $table.isTracked, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get notify =>
      $composableBuilder(column: $table.notify, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get rollover =>
      $composableBuilder(column: $table.rollover, builder: (column) => column);

  GeneratedColumn<bool> get repeats =>
      $composableBuilder(column: $table.repeats, builder: (column) => column);

  GeneratedColumn<String> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeUntilOdometerM => $composableBuilder(
    column: $table.snoozeUntilOdometerM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$ServiceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServiceItemsTable,
          ServiceItemRow,
          $$ServiceItemsTableFilterComposer,
          $$ServiceItemsTableOrderingComposer,
          $$ServiceItemsTableAnnotationComposer,
          $$ServiceItemsTableCreateCompanionBuilder,
          $$ServiceItemsTableUpdateCompanionBuilder,
          (
            ServiceItemRow,
            BaseReferences<_$AppDatabase, $ServiceItemsTable, ServiceItemRow>,
          ),
          ServiceItemRow,
          PrefetchHooks Function()
        > {
  $$ServiceItemsTableTableManager(_$AppDatabase db, $ServiceItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int?> intervalDistanceM = const Value.absent(),
                Value<String?> intervalDistanceUnit = const Value.absent(),
                Value<int?> intervalMonths = const Value.absent(),
                Value<int?> targetOdometerM = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
                Value<String?> baselineDate = const Value.absent(),
                Value<int?> baselineOdometerM = const Value.absent(),
                Value<int?> noticeDistanceM = const Value.absent(),
                Value<int?> noticeDays = const Value.absent(),
                Value<bool> isTracked = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> notify = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> rollover = const Value.absent(),
                Value<bool> repeats = const Value.absent(),
                Value<String?> snoozedUntil = const Value.absent(),
                Value<int?> snoozeUntilOdometerM = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceItemsCompanion(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                vehicleId: vehicleId,
                kind: kind,
                label: label,
                intervalDistanceM: intervalDistanceM,
                intervalDistanceUnit: intervalDistanceUnit,
                intervalMonths: intervalMonths,
                targetOdometerM: targetOdometerM,
                targetDate: targetDate,
                baselineDate: baselineDate,
                baselineOdometerM: baselineOdometerM,
                noticeDistanceM: noticeDistanceM,
                noticeDays: noticeDays,
                isTracked: isTracked,
                isActive: isActive,
                notify: notify,
                priority: priority,
                rollover: rollover,
                repeats: repeats,
                snoozedUntil: snoozedUntil,
                snoozeUntilOdometerM: snoozeUntilOdometerM,
                snoozeCount: snoozeCount,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int?> deletedAtUtcMs = const Value.absent(),
                required String vehicleId,
                required String kind,
                Value<String?> label = const Value.absent(),
                Value<int?> intervalDistanceM = const Value.absent(),
                Value<String?> intervalDistanceUnit = const Value.absent(),
                Value<int?> intervalMonths = const Value.absent(),
                Value<int?> targetOdometerM = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
                Value<String?> baselineDate = const Value.absent(),
                Value<int?> baselineOdometerM = const Value.absent(),
                Value<int?> noticeDistanceM = const Value.absent(),
                Value<int?> noticeDays = const Value.absent(),
                Value<bool> isTracked = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> notify = const Value.absent(),
                required String priority,
                required String rollover,
                Value<bool> repeats = const Value.absent(),
                Value<String?> snoozedUntil = const Value.absent(),
                Value<int?> snoozeUntilOdometerM = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceItemsCompanion.insert(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                vehicleId: vehicleId,
                kind: kind,
                label: label,
                intervalDistanceM: intervalDistanceM,
                intervalDistanceUnit: intervalDistanceUnit,
                intervalMonths: intervalMonths,
                targetOdometerM: targetOdometerM,
                targetDate: targetDate,
                baselineDate: baselineDate,
                baselineOdometerM: baselineOdometerM,
                noticeDistanceM: noticeDistanceM,
                noticeDays: noticeDays,
                isTracked: isTracked,
                isActive: isActive,
                notify: notify,
                priority: priority,
                rollover: rollover,
                repeats: repeats,
                snoozedUntil: snoozedUntil,
                snoozeUntilOdometerM: snoozeUntilOdometerM,
                snoozeCount: snoozeCount,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServiceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServiceItemsTable,
      ServiceItemRow,
      $$ServiceItemsTableFilterComposer,
      $$ServiceItemsTableOrderingComposer,
      $$ServiceItemsTableAnnotationComposer,
      $$ServiceItemsTableCreateCompanionBuilder,
      $$ServiceItemsTableUpdateCompanionBuilder,
      (
        ServiceItemRow,
        BaseReferences<_$AppDatabase, $ServiceItemsTable, ServiceItemRow>,
      ),
      ServiceItemRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String id,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      required int schemaVersion,
      required String language,
      required String calendar,
      required String numerals,
      required int firstDayOfWeek,
      required String theme,
      required String currencyDefault,
      required String currencyDisplay,
      required String distanceUnit,
      required String volumeUnit,
      required String consumptionUnit,
      Value<int?> noticeDistanceM,
      Value<int?> noticeDays,
      required int notificationTimeMinutes,
      required int quietHoursFromMinutes,
      required int quietHoursToMinutes,
      Value<bool> weekdaysOnly,
      Value<bool> notifyService,
      Value<bool> notifyOdometer,
      Value<bool> notifyBackup,
      Value<String?> activeVehicleId,
      Value<bool> onboardingDone,
      Value<int?> lastBackupAtUtcMs,
      Value<int?> lastBackupReminderAtUtcMs,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> id,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int?> deletedAtUtcMs,
      Value<int> schemaVersion,
      Value<String> language,
      Value<String> calendar,
      Value<String> numerals,
      Value<int> firstDayOfWeek,
      Value<String> theme,
      Value<String> currencyDefault,
      Value<String> currencyDisplay,
      Value<String> distanceUnit,
      Value<String> volumeUnit,
      Value<String> consumptionUnit,
      Value<int?> noticeDistanceM,
      Value<int?> noticeDays,
      Value<int> notificationTimeMinutes,
      Value<int> quietHoursFromMinutes,
      Value<int> quietHoursToMinutes,
      Value<bool> weekdaysOnly,
      Value<bool> notifyService,
      Value<bool> notifyOdometer,
      Value<bool> notifyBackup,
      Value<String?> activeVehicleId,
      Value<bool> onboardingDone,
      Value<int?> lastBackupAtUtcMs,
      Value<int?> lastBackupReminderAtUtcMs,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendar => $composableBuilder(
    column: $table.calendar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numerals => $composableBuilder(
    column: $table.numerals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstDayOfWeek => $composableBuilder(
    column: $table.firstDayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyDefault => $composableBuilder(
    column: $table.currencyDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyDisplay => $composableBuilder(
    column: $table.currencyDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get volumeUnit => $composableBuilder(
    column: $table.volumeUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consumptionUnit => $composableBuilder(
    column: $table.consumptionUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationTimeMinutes => $composableBuilder(
    column: $table.notificationTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursFromMinutes => $composableBuilder(
    column: $table.quietHoursFromMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursToMinutes => $composableBuilder(
    column: $table.quietHoursToMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weekdaysOnly => $composableBuilder(
    column: $table.weekdaysOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyService => $composableBuilder(
    column: $table.notifyService,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyOdometer => $composableBuilder(
    column: $table.notifyOdometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyBackup => $composableBuilder(
    column: $table.notifyBackup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeVehicleId => $composableBuilder(
    column: $table.activeVehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastBackupAtUtcMs => $composableBuilder(
    column: $table.lastBackupAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastBackupReminderAtUtcMs => $composableBuilder(
    column: $table.lastBackupReminderAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendar => $composableBuilder(
    column: $table.calendar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numerals => $composableBuilder(
    column: $table.numerals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstDayOfWeek => $composableBuilder(
    column: $table.firstDayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyDefault => $composableBuilder(
    column: $table.currencyDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyDisplay => $composableBuilder(
    column: $table.currencyDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volumeUnit => $composableBuilder(
    column: $table.volumeUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consumptionUnit => $composableBuilder(
    column: $table.consumptionUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationTimeMinutes => $composableBuilder(
    column: $table.notificationTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursFromMinutes => $composableBuilder(
    column: $table.quietHoursFromMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursToMinutes => $composableBuilder(
    column: $table.quietHoursToMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get weekdaysOnly => $composableBuilder(
    column: $table.weekdaysOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyService => $composableBuilder(
    column: $table.notifyService,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyOdometer => $composableBuilder(
    column: $table.notifyOdometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyBackup => $composableBuilder(
    column: $table.notifyBackup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeVehicleId => $composableBuilder(
    column: $table.activeVehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastBackupAtUtcMs => $composableBuilder(
    column: $table.lastBackupAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastBackupReminderAtUtcMs => $composableBuilder(
    column: $table.lastBackupReminderAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get calendar =>
      $composableBuilder(column: $table.calendar, builder: (column) => column);

  GeneratedColumn<String> get numerals =>
      $composableBuilder(column: $table.numerals, builder: (column) => column);

  GeneratedColumn<int> get firstDayOfWeek => $composableBuilder(
    column: $table.firstDayOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get currencyDefault => $composableBuilder(
    column: $table.currencyDefault,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyDisplay => $composableBuilder(
    column: $table.currencyDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get volumeUnit => $composableBuilder(
    column: $table.volumeUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consumptionUnit => $composableBuilder(
    column: $table.consumptionUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noticeDistanceM => $composableBuilder(
    column: $table.noticeDistanceM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noticeDays => $composableBuilder(
    column: $table.noticeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationTimeMinutes => $composableBuilder(
    column: $table.notificationTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursFromMinutes => $composableBuilder(
    column: $table.quietHoursFromMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursToMinutes => $composableBuilder(
    column: $table.quietHoursToMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get weekdaysOnly => $composableBuilder(
    column: $table.weekdaysOnly,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyService => $composableBuilder(
    column: $table.notifyService,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyOdometer => $composableBuilder(
    column: $table.notifyOdometer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyBackup => $composableBuilder(
    column: $table.notifyBackup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeVehicleId => $composableBuilder(
    column: $table.activeVehicleId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastBackupAtUtcMs => $composableBuilder(
    column: $table.lastBackupAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastBackupReminderAtUtcMs => $composableBuilder(
    column: $table.lastBackupReminderAtUtcMs,
    builder: (column) => column,
  );
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsRow,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> calendar = const Value.absent(),
                Value<String> numerals = const Value.absent(),
                Value<int> firstDayOfWeek = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> currencyDefault = const Value.absent(),
                Value<String> currencyDisplay = const Value.absent(),
                Value<String> distanceUnit = const Value.absent(),
                Value<String> volumeUnit = const Value.absent(),
                Value<String> consumptionUnit = const Value.absent(),
                Value<int?> noticeDistanceM = const Value.absent(),
                Value<int?> noticeDays = const Value.absent(),
                Value<int> notificationTimeMinutes = const Value.absent(),
                Value<int> quietHoursFromMinutes = const Value.absent(),
                Value<int> quietHoursToMinutes = const Value.absent(),
                Value<bool> weekdaysOnly = const Value.absent(),
                Value<bool> notifyService = const Value.absent(),
                Value<bool> notifyOdometer = const Value.absent(),
                Value<bool> notifyBackup = const Value.absent(),
                Value<String?> activeVehicleId = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<int?> lastBackupAtUtcMs = const Value.absent(),
                Value<int?> lastBackupReminderAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                schemaVersion: schemaVersion,
                language: language,
                calendar: calendar,
                numerals: numerals,
                firstDayOfWeek: firstDayOfWeek,
                theme: theme,
                currencyDefault: currencyDefault,
                currencyDisplay: currencyDisplay,
                distanceUnit: distanceUnit,
                volumeUnit: volumeUnit,
                consumptionUnit: consumptionUnit,
                noticeDistanceM: noticeDistanceM,
                noticeDays: noticeDays,
                notificationTimeMinutes: notificationTimeMinutes,
                quietHoursFromMinutes: quietHoursFromMinutes,
                quietHoursToMinutes: quietHoursToMinutes,
                weekdaysOnly: weekdaysOnly,
                notifyService: notifyService,
                notifyOdometer: notifyOdometer,
                notifyBackup: notifyBackup,
                activeVehicleId: activeVehicleId,
                onboardingDone: onboardingDone,
                lastBackupAtUtcMs: lastBackupAtUtcMs,
                lastBackupReminderAtUtcMs: lastBackupReminderAtUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int?> deletedAtUtcMs = const Value.absent(),
                required int schemaVersion,
                required String language,
                required String calendar,
                required String numerals,
                required int firstDayOfWeek,
                required String theme,
                required String currencyDefault,
                required String currencyDisplay,
                required String distanceUnit,
                required String volumeUnit,
                required String consumptionUnit,
                Value<int?> noticeDistanceM = const Value.absent(),
                Value<int?> noticeDays = const Value.absent(),
                required int notificationTimeMinutes,
                required int quietHoursFromMinutes,
                required int quietHoursToMinutes,
                Value<bool> weekdaysOnly = const Value.absent(),
                Value<bool> notifyService = const Value.absent(),
                Value<bool> notifyOdometer = const Value.absent(),
                Value<bool> notifyBackup = const Value.absent(),
                Value<String?> activeVehicleId = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<int?> lastBackupAtUtcMs = const Value.absent(),
                Value<int?> lastBackupReminderAtUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                deletedAtUtcMs: deletedAtUtcMs,
                schemaVersion: schemaVersion,
                language: language,
                calendar: calendar,
                numerals: numerals,
                firstDayOfWeek: firstDayOfWeek,
                theme: theme,
                currencyDefault: currencyDefault,
                currencyDisplay: currencyDisplay,
                distanceUnit: distanceUnit,
                volumeUnit: volumeUnit,
                consumptionUnit: consumptionUnit,
                noticeDistanceM: noticeDistanceM,
                noticeDays: noticeDays,
                notificationTimeMinutes: notificationTimeMinutes,
                quietHoursFromMinutes: quietHoursFromMinutes,
                quietHoursToMinutes: quietHoursToMinutes,
                weekdaysOnly: weekdaysOnly,
                notifyService: notifyService,
                notifyOdometer: notifyOdometer,
                notifyBackup: notifyBackup,
                activeVehicleId: activeVehicleId,
                onboardingDone: onboardingDone,
                lastBackupAtUtcMs: lastBackupAtUtcMs,
                lastBackupReminderAtUtcMs: lastBackupReminderAtUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsRow,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$ServiceItemsTableTableManager get serviceItems =>
      $$ServiceItemsTableTableManager(_db, _db.serviceItems);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
