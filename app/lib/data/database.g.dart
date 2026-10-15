// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
    'issuer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    issuer,
    productName,
    source,
    last4,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('issuer')) {
      context.handle(
        _issuerMeta,
        issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta),
      );
    } else if (isInserting) {
      context.missing(_issuerMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      issuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final int id;
  final String issuer;
  final String productName;
  final String? source;
  final String? last4;
  final bool active;
  const CardRow({
    required this.id,
    required this.issuer,
    required this.productName,
    this.source,
    this.last4,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['issuer'] = Variable<String>(issuer);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      issuer: Value(issuer),
      productName: Value(productName),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      last4: last4 == null && nullToAbsent
          ? const Value.absent()
          : Value(last4),
      active: Value(active),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<int>(json['id']),
      issuer: serializer.fromJson<String>(json['issuer']),
      productName: serializer.fromJson<String>(json['productName']),
      source: serializer.fromJson<String?>(json['source']),
      last4: serializer.fromJson<String?>(json['last4']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'issuer': serializer.toJson<String>(issuer),
      'productName': serializer.toJson<String>(productName),
      'source': serializer.toJson<String?>(source),
      'last4': serializer.toJson<String?>(last4),
      'active': serializer.toJson<bool>(active),
    };
  }

  CardRow copyWith({
    int? id,
    String? issuer,
    String? productName,
    Value<String?> source = const Value.absent(),
    Value<String?> last4 = const Value.absent(),
    bool? active,
  }) => CardRow(
    id: id ?? this.id,
    issuer: issuer ?? this.issuer,
    productName: productName ?? this.productName,
    source: source.present ? source.value : this.source,
    last4: last4.present ? last4.value : this.last4,
    active: active ?? this.active,
  );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      source: data.source.present ? data.source.value : this.source,
      last4: data.last4.present ? data.last4.value : this.last4,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('issuer: $issuer, ')
          ..write('productName: $productName, ')
          ..write('source: $source, ')
          ..write('last4: $last4, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, issuer, productName, source, last4, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.issuer == this.issuer &&
          other.productName == this.productName &&
          other.source == this.source &&
          other.last4 == this.last4 &&
          other.active == this.active);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<int> id;
  final Value<String> issuer;
  final Value<String> productName;
  final Value<String?> source;
  final Value<String?> last4;
  final Value<bool> active;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.issuer = const Value.absent(),
    this.productName = const Value.absent(),
    this.source = const Value.absent(),
    this.last4 = const Value.absent(),
    this.active = const Value.absent(),
  });
  CardsCompanion.insert({
    this.id = const Value.absent(),
    required String issuer,
    required String productName,
    this.source = const Value.absent(),
    this.last4 = const Value.absent(),
    this.active = const Value.absent(),
  }) : issuer = Value(issuer),
       productName = Value(productName);
  static Insertable<CardRow> custom({
    Expression<int>? id,
    Expression<String>? issuer,
    Expression<String>? productName,
    Expression<String>? source,
    Expression<String>? last4,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (issuer != null) 'issuer': issuer,
      if (productName != null) 'product_name': productName,
      if (source != null) 'source': source,
      if (last4 != null) 'last4': last4,
      if (active != null) 'active': active,
    });
  }

  CardsCompanion copyWith({
    Value<int>? id,
    Value<String>? issuer,
    Value<String>? productName,
    Value<String?>? source,
    Value<String?>? last4,
    Value<bool>? active,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      productName: productName ?? this.productName,
      source: source ?? this.source,
      last4: last4 ?? this.last4,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('issuer: $issuer, ')
          ..write('productName: $productName, ')
          ..write('source: $source, ')
          ..write('last4: $last4, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sortOrder,
    isDefault,
    hidden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final int sortOrder;
  final bool isDefault;
  final bool hidden;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isDefault,
    required this.hidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_default'] = Variable<bool>(isDefault);
    map['hidden'] = Variable<bool>(hidden);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      isDefault: Value(isDefault),
      hidden: Value(hidden),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      hidden: serializer.fromJson<bool>(json['hidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isDefault': serializer.toJson<bool>(isDefault),
      'hidden': serializer.toJson<bool>(hidden),
    };
  }

  CategoryRow copyWith({
    int? id,
    String? name,
    int? sortOrder,
    bool? isDefault,
    bool? hidden,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    isDefault: isDefault ?? this.isDefault,
    hidden: hidden ?? this.hidden,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isDefault: $isDefault, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, isDefault, hidden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.isDefault == this.isDefault &&
          other.hidden == this.hidden);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> isDefault;
  final Value<bool> hidden;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.hidden = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.hidden = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? isDefault,
    Expression<bool>? hidden,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isDefault != null) 'is_default': isDefault,
      if (hidden != null) 'hidden': hidden,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? isDefault,
    Value<bool>? hidden,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      hidden: hidden ?? this.hidden,
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
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isDefault: $isDefault, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KRW'),
  );
  static const VerificationMeta _originalAmountMeta = const VerificationMeta(
    'originalAmount',
  );
  @override
  late final GeneratedColumn<String> originalAmount = GeneratedColumn<String>(
    'original_amount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantRawMeta = const VerificationMeta(
    'merchantRaw',
  );
  @override
  late final GeneratedColumn<String> merchantRaw = GeneratedColumn<String>(
    'merchant_raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantNormMeta = const VerificationMeta(
    'merchantNorm',
  );
  @override
  late final GeneratedColumn<String> merchantNorm = GeneratedColumn<String>(
    'merchant_norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installmentMonthsMeta = const VerificationMeta(
    'installmentMonths',
  );
  @override
  late final GeneratedColumn<int> installmentMonths = GeneratedColumn<int>(
    'installment_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isForeignMeta = const VerificationMeta(
    'isForeign',
  );
  @override
  late final GeneratedColumn<bool> isForeign = GeneratedColumn<bool>(
    'is_foreign',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_foreign" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _excludedFromSumsMeta = const VerificationMeta(
    'excludedFromSums',
  );
  @override
  late final GeneratedColumn<bool> excludedFromSums = GeneratedColumn<bool>(
    'excluded_from_sums',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("excluded_from_sums" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cancelOfIdMeta = const VerificationMeta(
    'cancelOfId',
  );
  @override
  late final GeneratedColumn<int> cancelOfId = GeneratedColumn<int>(
    'cancel_of_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _suggestedCategoryIdMeta =
      const VerificationMeta('suggestedCategoryId');
  @override
  late final GeneratedColumn<int> suggestedCategoryId = GeneratedColumn<int>(
    'suggested_category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _suggestSourceMeta = const VerificationMeta(
    'suggestSource',
  );
  @override
  late final GeneratedColumn<String> suggestSource = GeneratedColumn<String>(
    'suggest_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUnusualMeta = const VerificationMeta(
    'isUnusual',
  );
  @override
  late final GeneratedColumn<bool> isUnusual = GeneratedColumn<bool>(
    'is_unusual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unusual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedMeta = const VerificationMeta(
    'confirmed',
  );
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
    'confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta(
    'needsReview',
  );
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reviewReasonMeta = const VerificationMeta(
    'reviewReason',
  );
  @override
  late final GeneratedColumn<String> reviewReason = GeneratedColumn<String>(
    'review_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringItemIdMeta = const VerificationMeta(
    'recurringItemId',
  );
  @override
  late final GeneratedColumn<int> recurringItemId = GeneratedColumn<int>(
    'recurring_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourcePackageMeta = const VerificationMeta(
    'sourcePackage',
  );
  @override
  late final GeneratedColumn<String> sourcePackage = GeneratedColumn<String>(
    'source_package',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notifKeyMeta = const VerificationMeta(
    'notifKey',
  );
  @override
  late final GeneratedColumn<String> notifKey = GeneratedColumn<String>(
    'notif_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dedupeKeyMeta = const VerificationMeta(
    'dedupeKey',
  );
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
    'dedupe_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    kind,
    amount,
    currency,
    originalAmount,
    merchantRaw,
    merchantNorm,
    approvedAt,
    localDate,
    installmentMonths,
    isForeign,
    status,
    excludedFromSums,
    cancelOfId,
    categoryId,
    suggestedCategoryId,
    suggestSource,
    isUnusual,
    memo,
    confirmed,
    needsReview,
    reviewReason,
    recurringItemId,
    rawText,
    sourcePackage,
    notifKey,
    dedupeKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('original_amount')) {
      context.handle(
        _originalAmountMeta,
        originalAmount.isAcceptableOrUnknown(
          data['original_amount']!,
          _originalAmountMeta,
        ),
      );
    }
    if (data.containsKey('merchant_raw')) {
      context.handle(
        _merchantRawMeta,
        merchantRaw.isAcceptableOrUnknown(
          data['merchant_raw']!,
          _merchantRawMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantRawMeta);
    }
    if (data.containsKey('merchant_norm')) {
      context.handle(
        _merchantNormMeta,
        merchantNorm.isAcceptableOrUnknown(
          data['merchant_norm']!,
          _merchantNormMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantNormMeta);
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_approvedAtMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('installment_months')) {
      context.handle(
        _installmentMonthsMeta,
        installmentMonths.isAcceptableOrUnknown(
          data['installment_months']!,
          _installmentMonthsMeta,
        ),
      );
    }
    if (data.containsKey('is_foreign')) {
      context.handle(
        _isForeignMeta,
        isForeign.isAcceptableOrUnknown(data['is_foreign']!, _isForeignMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('excluded_from_sums')) {
      context.handle(
        _excludedFromSumsMeta,
        excludedFromSums.isAcceptableOrUnknown(
          data['excluded_from_sums']!,
          _excludedFromSumsMeta,
        ),
      );
    }
    if (data.containsKey('cancel_of_id')) {
      context.handle(
        _cancelOfIdMeta,
        cancelOfId.isAcceptableOrUnknown(
          data['cancel_of_id']!,
          _cancelOfIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('suggested_category_id')) {
      context.handle(
        _suggestedCategoryIdMeta,
        suggestedCategoryId.isAcceptableOrUnknown(
          data['suggested_category_id']!,
          _suggestedCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('suggest_source')) {
      context.handle(
        _suggestSourceMeta,
        suggestSource.isAcceptableOrUnknown(
          data['suggest_source']!,
          _suggestSourceMeta,
        ),
      );
    }
    if (data.containsKey('is_unusual')) {
      context.handle(
        _isUnusualMeta,
        isUnusual.isAcceptableOrUnknown(data['is_unusual']!, _isUnusualMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('confirmed')) {
      context.handle(
        _confirmedMeta,
        confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta),
      );
    }
    if (data.containsKey('needs_review')) {
      context.handle(
        _needsReviewMeta,
        needsReview.isAcceptableOrUnknown(
          data['needs_review']!,
          _needsReviewMeta,
        ),
      );
    }
    if (data.containsKey('review_reason')) {
      context.handle(
        _reviewReasonMeta,
        reviewReason.isAcceptableOrUnknown(
          data['review_reason']!,
          _reviewReasonMeta,
        ),
      );
    }
    if (data.containsKey('recurring_item_id')) {
      context.handle(
        _recurringItemIdMeta,
        recurringItemId.isAcceptableOrUnknown(
          data['recurring_item_id']!,
          _recurringItemIdMeta,
        ),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('source_package')) {
      context.handle(
        _sourcePackageMeta,
        sourcePackage.isAcceptableOrUnknown(
          data['source_package']!,
          _sourcePackageMeta,
        ),
      );
    }
    if (data.containsKey('notif_key')) {
      context.handle(
        _notifKeyMeta,
        notifKey.isAcceptableOrUnknown(data['notif_key']!, _notifKeyMeta),
      );
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(
        _dedupeKeyMeta,
        dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dedupeKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      originalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_amount'],
      ),
      merchantRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_raw'],
      )!,
      merchantNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_norm'],
      )!,
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      installmentMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_months'],
      )!,
      isForeign: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_foreign'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      excludedFromSums: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}excluded_from_sums'],
      )!,
      cancelOfId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancel_of_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      suggestedCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}suggested_category_id'],
      ),
      suggestSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggest_source'],
      ),
      isUnusual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unusual'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      confirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmed'],
      )!,
      needsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_review'],
      )!,
      reviewReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_reason'],
      ),
      recurringItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurring_item_id'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      sourcePackage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_package'],
      ),
      notifKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notif_key'],
      ),
      dedupeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedupe_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final int? cardId;
  final String kind;
  final int amount;
  final String currency;
  final String? originalAmount;
  final String merchantRaw;
  final String merchantNorm;
  final DateTime approvedAt;
  final String localDate;
  final int installmentMonths;
  final bool isForeign;
  final String status;
  final bool excludedFromSums;
  final int? cancelOfId;
  final int? categoryId;
  final int? suggestedCategoryId;
  final String? suggestSource;
  final bool isUnusual;
  final String? memo;
  final bool confirmed;
  final bool needsReview;
  final String? reviewReason;
  final int? recurringItemId;
  final String rawText;
  final String? sourcePackage;
  final String? notifKey;
  final String dedupeKey;
  final DateTime createdAt;
  const TransactionRow({
    required this.id,
    this.cardId,
    required this.kind,
    required this.amount,
    required this.currency,
    this.originalAmount,
    required this.merchantRaw,
    required this.merchantNorm,
    required this.approvedAt,
    required this.localDate,
    required this.installmentMonths,
    required this.isForeign,
    required this.status,
    required this.excludedFromSums,
    this.cancelOfId,
    this.categoryId,
    this.suggestedCategoryId,
    this.suggestSource,
    required this.isUnusual,
    this.memo,
    required this.confirmed,
    required this.needsReview,
    this.reviewReason,
    this.recurringItemId,
    required this.rawText,
    this.sourcePackage,
    this.notifKey,
    required this.dedupeKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<int>(cardId);
    }
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || originalAmount != null) {
      map['original_amount'] = Variable<String>(originalAmount);
    }
    map['merchant_raw'] = Variable<String>(merchantRaw);
    map['merchant_norm'] = Variable<String>(merchantNorm);
    map['approved_at'] = Variable<DateTime>(approvedAt);
    map['local_date'] = Variable<String>(localDate);
    map['installment_months'] = Variable<int>(installmentMonths);
    map['is_foreign'] = Variable<bool>(isForeign);
    map['status'] = Variable<String>(status);
    map['excluded_from_sums'] = Variable<bool>(excludedFromSums);
    if (!nullToAbsent || cancelOfId != null) {
      map['cancel_of_id'] = Variable<int>(cancelOfId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || suggestedCategoryId != null) {
      map['suggested_category_id'] = Variable<int>(suggestedCategoryId);
    }
    if (!nullToAbsent || suggestSource != null) {
      map['suggest_source'] = Variable<String>(suggestSource);
    }
    map['is_unusual'] = Variable<bool>(isUnusual);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['confirmed'] = Variable<bool>(confirmed);
    map['needs_review'] = Variable<bool>(needsReview);
    if (!nullToAbsent || reviewReason != null) {
      map['review_reason'] = Variable<String>(reviewReason);
    }
    if (!nullToAbsent || recurringItemId != null) {
      map['recurring_item_id'] = Variable<int>(recurringItemId);
    }
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || sourcePackage != null) {
      map['source_package'] = Variable<String>(sourcePackage);
    }
    if (!nullToAbsent || notifKey != null) {
      map['notif_key'] = Variable<String>(notifKey);
    }
    map['dedupe_key'] = Variable<String>(dedupeKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      kind: Value(kind),
      amount: Value(amount),
      currency: Value(currency),
      originalAmount: originalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(originalAmount),
      merchantRaw: Value(merchantRaw),
      merchantNorm: Value(merchantNorm),
      approvedAt: Value(approvedAt),
      localDate: Value(localDate),
      installmentMonths: Value(installmentMonths),
      isForeign: Value(isForeign),
      status: Value(status),
      excludedFromSums: Value(excludedFromSums),
      cancelOfId: cancelOfId == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelOfId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      suggestedCategoryId: suggestedCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedCategoryId),
      suggestSource: suggestSource == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestSource),
      isUnusual: Value(isUnusual),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      confirmed: Value(confirmed),
      needsReview: Value(needsReview),
      reviewReason: reviewReason == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewReason),
      recurringItemId: recurringItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringItemId),
      rawText: Value(rawText),
      sourcePackage: sourcePackage == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePackage),
      notifKey: notifKey == null && nullToAbsent
          ? const Value.absent()
          : Value(notifKey),
      dedupeKey: Value(dedupeKey),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int?>(json['cardId']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      originalAmount: serializer.fromJson<String?>(json['originalAmount']),
      merchantRaw: serializer.fromJson<String>(json['merchantRaw']),
      merchantNorm: serializer.fromJson<String>(json['merchantNorm']),
      approvedAt: serializer.fromJson<DateTime>(json['approvedAt']),
      localDate: serializer.fromJson<String>(json['localDate']),
      installmentMonths: serializer.fromJson<int>(json['installmentMonths']),
      isForeign: serializer.fromJson<bool>(json['isForeign']),
      status: serializer.fromJson<String>(json['status']),
      excludedFromSums: serializer.fromJson<bool>(json['excludedFromSums']),
      cancelOfId: serializer.fromJson<int?>(json['cancelOfId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      suggestedCategoryId: serializer.fromJson<int?>(
        json['suggestedCategoryId'],
      ),
      suggestSource: serializer.fromJson<String?>(json['suggestSource']),
      isUnusual: serializer.fromJson<bool>(json['isUnusual']),
      memo: serializer.fromJson<String?>(json['memo']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
      reviewReason: serializer.fromJson<String?>(json['reviewReason']),
      recurringItemId: serializer.fromJson<int?>(json['recurringItemId']),
      rawText: serializer.fromJson<String>(json['rawText']),
      sourcePackage: serializer.fromJson<String?>(json['sourcePackage']),
      notifKey: serializer.fromJson<String?>(json['notifKey']),
      dedupeKey: serializer.fromJson<String>(json['dedupeKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int?>(cardId),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'originalAmount': serializer.toJson<String?>(originalAmount),
      'merchantRaw': serializer.toJson<String>(merchantRaw),
      'merchantNorm': serializer.toJson<String>(merchantNorm),
      'approvedAt': serializer.toJson<DateTime>(approvedAt),
      'localDate': serializer.toJson<String>(localDate),
      'installmentMonths': serializer.toJson<int>(installmentMonths),
      'isForeign': serializer.toJson<bool>(isForeign),
      'status': serializer.toJson<String>(status),
      'excludedFromSums': serializer.toJson<bool>(excludedFromSums),
      'cancelOfId': serializer.toJson<int?>(cancelOfId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'suggestedCategoryId': serializer.toJson<int?>(suggestedCategoryId),
      'suggestSource': serializer.toJson<String?>(suggestSource),
      'isUnusual': serializer.toJson<bool>(isUnusual),
      'memo': serializer.toJson<String?>(memo),
      'confirmed': serializer.toJson<bool>(confirmed),
      'needsReview': serializer.toJson<bool>(needsReview),
      'reviewReason': serializer.toJson<String?>(reviewReason),
      'recurringItemId': serializer.toJson<int?>(recurringItemId),
      'rawText': serializer.toJson<String>(rawText),
      'sourcePackage': serializer.toJson<String?>(sourcePackage),
      'notifKey': serializer.toJson<String?>(notifKey),
      'dedupeKey': serializer.toJson<String>(dedupeKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionRow copyWith({
    int? id,
    Value<int?> cardId = const Value.absent(),
    String? kind,
    int? amount,
    String? currency,
    Value<String?> originalAmount = const Value.absent(),
    String? merchantRaw,
    String? merchantNorm,
    DateTime? approvedAt,
    String? localDate,
    int? installmentMonths,
    bool? isForeign,
    String? status,
    bool? excludedFromSums,
    Value<int?> cancelOfId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<int?> suggestedCategoryId = const Value.absent(),
    Value<String?> suggestSource = const Value.absent(),
    bool? isUnusual,
    Value<String?> memo = const Value.absent(),
    bool? confirmed,
    bool? needsReview,
    Value<String?> reviewReason = const Value.absent(),
    Value<int?> recurringItemId = const Value.absent(),
    String? rawText,
    Value<String?> sourcePackage = const Value.absent(),
    Value<String?> notifKey = const Value.absent(),
    String? dedupeKey,
    DateTime? createdAt,
  }) => TransactionRow(
    id: id ?? this.id,
    cardId: cardId.present ? cardId.value : this.cardId,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    originalAmount: originalAmount.present
        ? originalAmount.value
        : this.originalAmount,
    merchantRaw: merchantRaw ?? this.merchantRaw,
    merchantNorm: merchantNorm ?? this.merchantNorm,
    approvedAt: approvedAt ?? this.approvedAt,
    localDate: localDate ?? this.localDate,
    installmentMonths: installmentMonths ?? this.installmentMonths,
    isForeign: isForeign ?? this.isForeign,
    status: status ?? this.status,
    excludedFromSums: excludedFromSums ?? this.excludedFromSums,
    cancelOfId: cancelOfId.present ? cancelOfId.value : this.cancelOfId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    suggestedCategoryId: suggestedCategoryId.present
        ? suggestedCategoryId.value
        : this.suggestedCategoryId,
    suggestSource: suggestSource.present
        ? suggestSource.value
        : this.suggestSource,
    isUnusual: isUnusual ?? this.isUnusual,
    memo: memo.present ? memo.value : this.memo,
    confirmed: confirmed ?? this.confirmed,
    needsReview: needsReview ?? this.needsReview,
    reviewReason: reviewReason.present ? reviewReason.value : this.reviewReason,
    recurringItemId: recurringItemId.present
        ? recurringItemId.value
        : this.recurringItemId,
    rawText: rawText ?? this.rawText,
    sourcePackage: sourcePackage.present
        ? sourcePackage.value
        : this.sourcePackage,
    notifKey: notifKey.present ? notifKey.value : this.notifKey,
    dedupeKey: dedupeKey ?? this.dedupeKey,
    createdAt: createdAt ?? this.createdAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      originalAmount: data.originalAmount.present
          ? data.originalAmount.value
          : this.originalAmount,
      merchantRaw: data.merchantRaw.present
          ? data.merchantRaw.value
          : this.merchantRaw,
      merchantNorm: data.merchantNorm.present
          ? data.merchantNorm.value
          : this.merchantNorm,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      installmentMonths: data.installmentMonths.present
          ? data.installmentMonths.value
          : this.installmentMonths,
      isForeign: data.isForeign.present ? data.isForeign.value : this.isForeign,
      status: data.status.present ? data.status.value : this.status,
      excludedFromSums: data.excludedFromSums.present
          ? data.excludedFromSums.value
          : this.excludedFromSums,
      cancelOfId: data.cancelOfId.present
          ? data.cancelOfId.value
          : this.cancelOfId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      suggestedCategoryId: data.suggestedCategoryId.present
          ? data.suggestedCategoryId.value
          : this.suggestedCategoryId,
      suggestSource: data.suggestSource.present
          ? data.suggestSource.value
          : this.suggestSource,
      isUnusual: data.isUnusual.present ? data.isUnusual.value : this.isUnusual,
      memo: data.memo.present ? data.memo.value : this.memo,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
      needsReview: data.needsReview.present
          ? data.needsReview.value
          : this.needsReview,
      reviewReason: data.reviewReason.present
          ? data.reviewReason.value
          : this.reviewReason,
      recurringItemId: data.recurringItemId.present
          ? data.recurringItemId.value
          : this.recurringItemId,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      sourcePackage: data.sourcePackage.present
          ? data.sourcePackage.value
          : this.sourcePackage,
      notifKey: data.notifKey.present ? data.notifKey.value : this.notifKey,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('merchantRaw: $merchantRaw, ')
          ..write('merchantNorm: $merchantNorm, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('localDate: $localDate, ')
          ..write('installmentMonths: $installmentMonths, ')
          ..write('isForeign: $isForeign, ')
          ..write('status: $status, ')
          ..write('excludedFromSums: $excludedFromSums, ')
          ..write('cancelOfId: $cancelOfId, ')
          ..write('categoryId: $categoryId, ')
          ..write('suggestedCategoryId: $suggestedCategoryId, ')
          ..write('suggestSource: $suggestSource, ')
          ..write('isUnusual: $isUnusual, ')
          ..write('memo: $memo, ')
          ..write('confirmed: $confirmed, ')
          ..write('needsReview: $needsReview, ')
          ..write('reviewReason: $reviewReason, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('rawText: $rawText, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('notifKey: $notifKey, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    cardId,
    kind,
    amount,
    currency,
    originalAmount,
    merchantRaw,
    merchantNorm,
    approvedAt,
    localDate,
    installmentMonths,
    isForeign,
    status,
    excludedFromSums,
    cancelOfId,
    categoryId,
    suggestedCategoryId,
    suggestSource,
    isUnusual,
    memo,
    confirmed,
    needsReview,
    reviewReason,
    recurringItemId,
    rawText,
    sourcePackage,
    notifKey,
    dedupeKey,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.originalAmount == this.originalAmount &&
          other.merchantRaw == this.merchantRaw &&
          other.merchantNorm == this.merchantNorm &&
          other.approvedAt == this.approvedAt &&
          other.localDate == this.localDate &&
          other.installmentMonths == this.installmentMonths &&
          other.isForeign == this.isForeign &&
          other.status == this.status &&
          other.excludedFromSums == this.excludedFromSums &&
          other.cancelOfId == this.cancelOfId &&
          other.categoryId == this.categoryId &&
          other.suggestedCategoryId == this.suggestedCategoryId &&
          other.suggestSource == this.suggestSource &&
          other.isUnusual == this.isUnusual &&
          other.memo == this.memo &&
          other.confirmed == this.confirmed &&
          other.needsReview == this.needsReview &&
          other.reviewReason == this.reviewReason &&
          other.recurringItemId == this.recurringItemId &&
          other.rawText == this.rawText &&
          other.sourcePackage == this.sourcePackage &&
          other.notifKey == this.notifKey &&
          other.dedupeKey == this.dedupeKey &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<int?> cardId;
  final Value<String> kind;
  final Value<int> amount;
  final Value<String> currency;
  final Value<String?> originalAmount;
  final Value<String> merchantRaw;
  final Value<String> merchantNorm;
  final Value<DateTime> approvedAt;
  final Value<String> localDate;
  final Value<int> installmentMonths;
  final Value<bool> isForeign;
  final Value<String> status;
  final Value<bool> excludedFromSums;
  final Value<int?> cancelOfId;
  final Value<int?> categoryId;
  final Value<int?> suggestedCategoryId;
  final Value<String?> suggestSource;
  final Value<bool> isUnusual;
  final Value<String?> memo;
  final Value<bool> confirmed;
  final Value<bool> needsReview;
  final Value<String?> reviewReason;
  final Value<int?> recurringItemId;
  final Value<String> rawText;
  final Value<String?> sourcePackage;
  final Value<String?> notifKey;
  final Value<String> dedupeKey;
  final Value<DateTime> createdAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.merchantRaw = const Value.absent(),
    this.merchantNorm = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.localDate = const Value.absent(),
    this.installmentMonths = const Value.absent(),
    this.isForeign = const Value.absent(),
    this.status = const Value.absent(),
    this.excludedFromSums = const Value.absent(),
    this.cancelOfId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.suggestedCategoryId = const Value.absent(),
    this.suggestSource = const Value.absent(),
    this.isUnusual = const Value.absent(),
    this.memo = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.reviewReason = const Value.absent(),
    this.recurringItemId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    this.notifKey = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    required String kind,
    required int amount,
    this.currency = const Value.absent(),
    this.originalAmount = const Value.absent(),
    required String merchantRaw,
    required String merchantNorm,
    required DateTime approvedAt,
    required String localDate,
    this.installmentMonths = const Value.absent(),
    this.isForeign = const Value.absent(),
    this.status = const Value.absent(),
    this.excludedFromSums = const Value.absent(),
    this.cancelOfId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.suggestedCategoryId = const Value.absent(),
    this.suggestSource = const Value.absent(),
    this.isUnusual = const Value.absent(),
    this.memo = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.reviewReason = const Value.absent(),
    this.recurringItemId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    this.notifKey = const Value.absent(),
    required String dedupeKey,
    this.createdAt = const Value.absent(),
  }) : kind = Value(kind),
       amount = Value(amount),
       merchantRaw = Value(merchantRaw),
       merchantNorm = Value(merchantNorm),
       approvedAt = Value(approvedAt),
       localDate = Value(localDate),
       dedupeKey = Value(dedupeKey);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<String>? originalAmount,
    Expression<String>? merchantRaw,
    Expression<String>? merchantNorm,
    Expression<DateTime>? approvedAt,
    Expression<String>? localDate,
    Expression<int>? installmentMonths,
    Expression<bool>? isForeign,
    Expression<String>? status,
    Expression<bool>? excludedFromSums,
    Expression<int>? cancelOfId,
    Expression<int>? categoryId,
    Expression<int>? suggestedCategoryId,
    Expression<String>? suggestSource,
    Expression<bool>? isUnusual,
    Expression<String>? memo,
    Expression<bool>? confirmed,
    Expression<bool>? needsReview,
    Expression<String>? reviewReason,
    Expression<int>? recurringItemId,
    Expression<String>? rawText,
    Expression<String>? sourcePackage,
    Expression<String>? notifKey,
    Expression<String>? dedupeKey,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (originalAmount != null) 'original_amount': originalAmount,
      if (merchantRaw != null) 'merchant_raw': merchantRaw,
      if (merchantNorm != null) 'merchant_norm': merchantNorm,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (localDate != null) 'local_date': localDate,
      if (installmentMonths != null) 'installment_months': installmentMonths,
      if (isForeign != null) 'is_foreign': isForeign,
      if (status != null) 'status': status,
      if (excludedFromSums != null) 'excluded_from_sums': excludedFromSums,
      if (cancelOfId != null) 'cancel_of_id': cancelOfId,
      if (categoryId != null) 'category_id': categoryId,
      if (suggestedCategoryId != null)
        'suggested_category_id': suggestedCategoryId,
      if (suggestSource != null) 'suggest_source': suggestSource,
      if (isUnusual != null) 'is_unusual': isUnusual,
      if (memo != null) 'memo': memo,
      if (confirmed != null) 'confirmed': confirmed,
      if (needsReview != null) 'needs_review': needsReview,
      if (reviewReason != null) 'review_reason': reviewReason,
      if (recurringItemId != null) 'recurring_item_id': recurringItemId,
      if (rawText != null) 'raw_text': rawText,
      if (sourcePackage != null) 'source_package': sourcePackage,
      if (notifKey != null) 'notif_key': notifKey,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? cardId,
    Value<String>? kind,
    Value<int>? amount,
    Value<String>? currency,
    Value<String?>? originalAmount,
    Value<String>? merchantRaw,
    Value<String>? merchantNorm,
    Value<DateTime>? approvedAt,
    Value<String>? localDate,
    Value<int>? installmentMonths,
    Value<bool>? isForeign,
    Value<String>? status,
    Value<bool>? excludedFromSums,
    Value<int?>? cancelOfId,
    Value<int?>? categoryId,
    Value<int?>? suggestedCategoryId,
    Value<String?>? suggestSource,
    Value<bool>? isUnusual,
    Value<String?>? memo,
    Value<bool>? confirmed,
    Value<bool>? needsReview,
    Value<String?>? reviewReason,
    Value<int?>? recurringItemId,
    Value<String>? rawText,
    Value<String?>? sourcePackage,
    Value<String?>? notifKey,
    Value<String>? dedupeKey,
    Value<DateTime>? createdAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      originalAmount: originalAmount ?? this.originalAmount,
      merchantRaw: merchantRaw ?? this.merchantRaw,
      merchantNorm: merchantNorm ?? this.merchantNorm,
      approvedAt: approvedAt ?? this.approvedAt,
      localDate: localDate ?? this.localDate,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      isForeign: isForeign ?? this.isForeign,
      status: status ?? this.status,
      excludedFromSums: excludedFromSums ?? this.excludedFromSums,
      cancelOfId: cancelOfId ?? this.cancelOfId,
      categoryId: categoryId ?? this.categoryId,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      suggestSource: suggestSource ?? this.suggestSource,
      isUnusual: isUnusual ?? this.isUnusual,
      memo: memo ?? this.memo,
      confirmed: confirmed ?? this.confirmed,
      needsReview: needsReview ?? this.needsReview,
      reviewReason: reviewReason ?? this.reviewReason,
      recurringItemId: recurringItemId ?? this.recurringItemId,
      rawText: rawText ?? this.rawText,
      sourcePackage: sourcePackage ?? this.sourcePackage,
      notifKey: notifKey ?? this.notifKey,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (originalAmount.present) {
      map['original_amount'] = Variable<String>(originalAmount.value);
    }
    if (merchantRaw.present) {
      map['merchant_raw'] = Variable<String>(merchantRaw.value);
    }
    if (merchantNorm.present) {
      map['merchant_norm'] = Variable<String>(merchantNorm.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (installmentMonths.present) {
      map['installment_months'] = Variable<int>(installmentMonths.value);
    }
    if (isForeign.present) {
      map['is_foreign'] = Variable<bool>(isForeign.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (excludedFromSums.present) {
      map['excluded_from_sums'] = Variable<bool>(excludedFromSums.value);
    }
    if (cancelOfId.present) {
      map['cancel_of_id'] = Variable<int>(cancelOfId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (suggestedCategoryId.present) {
      map['suggested_category_id'] = Variable<int>(suggestedCategoryId.value);
    }
    if (suggestSource.present) {
      map['suggest_source'] = Variable<String>(suggestSource.value);
    }
    if (isUnusual.present) {
      map['is_unusual'] = Variable<bool>(isUnusual.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (reviewReason.present) {
      map['review_reason'] = Variable<String>(reviewReason.value);
    }
    if (recurringItemId.present) {
      map['recurring_item_id'] = Variable<int>(recurringItemId.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (sourcePackage.present) {
      map['source_package'] = Variable<String>(sourcePackage.value);
    }
    if (notifKey.present) {
      map['notif_key'] = Variable<String>(notifKey.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('merchantRaw: $merchantRaw, ')
          ..write('merchantNorm: $merchantNorm, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('localDate: $localDate, ')
          ..write('installmentMonths: $installmentMonths, ')
          ..write('isForeign: $isForeign, ')
          ..write('status: $status, ')
          ..write('excludedFromSums: $excludedFromSums, ')
          ..write('cancelOfId: $cancelOfId, ')
          ..write('categoryId: $categoryId, ')
          ..write('suggestedCategoryId: $suggestedCategoryId, ')
          ..write('suggestSource: $suggestSource, ')
          ..write('isUnusual: $isUnusual, ')
          ..write('memo: $memo, ')
          ..write('confirmed: $confirmed, ')
          ..write('needsReview: $needsReview, ')
          ..write('reviewReason: $reviewReason, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('rawText: $rawText, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('notifKey: $notifKey, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InstallmentSchedulesTable extends InstallmentSchedules
    with TableInfo<$InstallmentSchedulesTable, InstallmentScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voidedMeta = const VerificationMeta('voided');
  @override
  late final GeneratedColumn<bool> voided = GeneratedColumn<bool>(
    'voided',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("voided" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    seq,
    month,
    amount,
    voided,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installment_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('voided')) {
      context.handle(
        _voidedMeta,
        voided.isAcceptableOrUnknown(data['voided']!, _voidedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstallmentScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentScheduleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      voided: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}voided'],
      )!,
    );
  }

  @override
  $InstallmentSchedulesTable createAlias(String alias) {
    return $InstallmentSchedulesTable(attachedDatabase, alias);
  }
}

class InstallmentScheduleRow extends DataClass
    implements Insertable<InstallmentScheduleRow> {
  final int id;
  final int transactionId;
  final int seq;
  final String month;
  final int amount;
  final bool voided;
  const InstallmentScheduleRow({
    required this.id,
    required this.transactionId,
    required this.seq,
    required this.month,
    required this.amount,
    required this.voided,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<int>(transactionId);
    map['seq'] = Variable<int>(seq);
    map['month'] = Variable<String>(month);
    map['amount'] = Variable<int>(amount);
    map['voided'] = Variable<bool>(voided);
    return map;
  }

  InstallmentSchedulesCompanion toCompanion(bool nullToAbsent) {
    return InstallmentSchedulesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      seq: Value(seq),
      month: Value(month),
      amount: Value(amount),
      voided: Value(voided),
    );
  }

  factory InstallmentScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentScheduleRow(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      seq: serializer.fromJson<int>(json['seq']),
      month: serializer.fromJson<String>(json['month']),
      amount: serializer.fromJson<int>(json['amount']),
      voided: serializer.fromJson<bool>(json['voided']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<int>(transactionId),
      'seq': serializer.toJson<int>(seq),
      'month': serializer.toJson<String>(month),
      'amount': serializer.toJson<int>(amount),
      'voided': serializer.toJson<bool>(voided),
    };
  }

  InstallmentScheduleRow copyWith({
    int? id,
    int? transactionId,
    int? seq,
    String? month,
    int? amount,
    bool? voided,
  }) => InstallmentScheduleRow(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    seq: seq ?? this.seq,
    month: month ?? this.month,
    amount: amount ?? this.amount,
    voided: voided ?? this.voided,
  );
  InstallmentScheduleRow copyWithCompanion(InstallmentSchedulesCompanion data) {
    return InstallmentScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      month: data.month.present ? data.month.value : this.month,
      amount: data.amount.present ? data.amount.value : this.amount,
      voided: data.voided.present ? data.voided.value : this.voided,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentScheduleRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('seq: $seq, ')
          ..write('month: $month, ')
          ..write('amount: $amount, ')
          ..write('voided: $voided')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transactionId, seq, month, amount, voided);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentScheduleRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.seq == this.seq &&
          other.month == this.month &&
          other.amount == this.amount &&
          other.voided == this.voided);
}

class InstallmentSchedulesCompanion
    extends UpdateCompanion<InstallmentScheduleRow> {
  final Value<int> id;
  final Value<int> transactionId;
  final Value<int> seq;
  final Value<String> month;
  final Value<int> amount;
  final Value<bool> voided;
  const InstallmentSchedulesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.month = const Value.absent(),
    this.amount = const Value.absent(),
    this.voided = const Value.absent(),
  });
  InstallmentSchedulesCompanion.insert({
    this.id = const Value.absent(),
    required int transactionId,
    required int seq,
    required String month,
    required int amount,
    this.voided = const Value.absent(),
  }) : transactionId = Value(transactionId),
       seq = Value(seq),
       month = Value(month),
       amount = Value(amount);
  static Insertable<InstallmentScheduleRow> custom({
    Expression<int>? id,
    Expression<int>? transactionId,
    Expression<int>? seq,
    Expression<String>? month,
    Expression<int>? amount,
    Expression<bool>? voided,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (seq != null) 'seq': seq,
      if (month != null) 'month': month,
      if (amount != null) 'amount': amount,
      if (voided != null) 'voided': voided,
    });
  }

  InstallmentSchedulesCompanion copyWith({
    Value<int>? id,
    Value<int>? transactionId,
    Value<int>? seq,
    Value<String>? month,
    Value<int>? amount,
    Value<bool>? voided,
  }) {
    return InstallmentSchedulesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      seq: seq ?? this.seq,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      voided: voided ?? this.voided,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (voided.present) {
      map['voided'] = Variable<bool>(voided.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('seq: $seq, ')
          ..write('month: $month, ')
          ..write('amount: $amount, ')
          ..write('voided: $voided')
          ..write(')'))
        .toString();
  }
}

class $RecurringItemsTable extends RecurringItems
    with TableInfo<$RecurringItemsTable, RecurringItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchPatternMeta = const VerificationMeta(
    'matchPattern',
  );
  @override
  late final GeneratedColumn<String> matchPattern = GeneratedColumn<String>(
    'match_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountTolerancePctMeta =
      const VerificationMeta('amountTolerancePct');
  @override
  late final GeneratedColumn<int> amountTolerancePct = GeneratedColumn<int>(
    'amount_tolerance_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _isEnvelopeMeta = const VerificationMeta(
    'isEnvelope',
  );
  @override
  late final GeneratedColumn<bool> isEnvelope = GeneratedColumn<bool>(
    'is_envelope',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_envelope" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    isEstimate,
    dueDay,
    cardId,
    matchPattern,
    amountTolerancePct,
    isEnvelope,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDayMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('match_pattern')) {
      context.handle(
        _matchPatternMeta,
        matchPattern.isAcceptableOrUnknown(
          data['match_pattern']!,
          _matchPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matchPatternMeta);
    }
    if (data.containsKey('amount_tolerance_pct')) {
      context.handle(
        _amountTolerancePctMeta,
        amountTolerancePct.isAcceptableOrUnknown(
          data['amount_tolerance_pct']!,
          _amountTolerancePctMeta,
        ),
      );
    }
    if (data.containsKey('is_envelope')) {
      context.handle(
        _isEnvelopeMeta,
        isEnvelope.isAcceptableOrUnknown(data['is_envelope']!, _isEnvelopeMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      ),
      matchPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_pattern'],
      )!,
      amountTolerancePct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_tolerance_pct'],
      ),
      isEnvelope: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_envelope'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $RecurringItemsTable createAlias(String alias) {
    return $RecurringItemsTable(attachedDatabase, alias);
  }
}

class RecurringItemRow extends DataClass
    implements Insertable<RecurringItemRow> {
  final int id;
  final String name;
  final int amount;
  final bool isEstimate;
  final int dueDay;
  final int? cardId;
  final String matchPattern;
  final int? amountTolerancePct;
  final bool isEnvelope;
  final bool active;
  const RecurringItemRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.isEstimate,
    required this.dueDay,
    this.cardId,
    required this.matchPattern,
    this.amountTolerancePct,
    required this.isEnvelope,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<int>(amount);
    map['is_estimate'] = Variable<bool>(isEstimate);
    map['due_day'] = Variable<int>(dueDay);
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<int>(cardId);
    }
    map['match_pattern'] = Variable<String>(matchPattern);
    if (!nullToAbsent || amountTolerancePct != null) {
      map['amount_tolerance_pct'] = Variable<int>(amountTolerancePct);
    }
    map['is_envelope'] = Variable<bool>(isEnvelope);
    map['active'] = Variable<bool>(active);
    return map;
  }

  RecurringItemsCompanion toCompanion(bool nullToAbsent) {
    return RecurringItemsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      isEstimate: Value(isEstimate),
      dueDay: Value(dueDay),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      matchPattern: Value(matchPattern),
      amountTolerancePct: amountTolerancePct == null && nullToAbsent
          ? const Value.absent()
          : Value(amountTolerancePct),
      isEnvelope: Value(isEnvelope),
      active: Value(active),
    );
  }

  factory RecurringItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringItemRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<int>(json['amount']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      dueDay: serializer.fromJson<int>(json['dueDay']),
      cardId: serializer.fromJson<int?>(json['cardId']),
      matchPattern: serializer.fromJson<String>(json['matchPattern']),
      amountTolerancePct: serializer.fromJson<int?>(json['amountTolerancePct']),
      isEnvelope: serializer.fromJson<bool>(json['isEnvelope']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<int>(amount),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'dueDay': serializer.toJson<int>(dueDay),
      'cardId': serializer.toJson<int?>(cardId),
      'matchPattern': serializer.toJson<String>(matchPattern),
      'amountTolerancePct': serializer.toJson<int?>(amountTolerancePct),
      'isEnvelope': serializer.toJson<bool>(isEnvelope),
      'active': serializer.toJson<bool>(active),
    };
  }

  RecurringItemRow copyWith({
    int? id,
    String? name,
    int? amount,
    bool? isEstimate,
    int? dueDay,
    Value<int?> cardId = const Value.absent(),
    String? matchPattern,
    Value<int?> amountTolerancePct = const Value.absent(),
    bool? isEnvelope,
    bool? active,
  }) => RecurringItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    isEstimate: isEstimate ?? this.isEstimate,
    dueDay: dueDay ?? this.dueDay,
    cardId: cardId.present ? cardId.value : this.cardId,
    matchPattern: matchPattern ?? this.matchPattern,
    amountTolerancePct: amountTolerancePct.present
        ? amountTolerancePct.value
        : this.amountTolerancePct,
    isEnvelope: isEnvelope ?? this.isEnvelope,
    active: active ?? this.active,
  );
  RecurringItemRow copyWithCompanion(RecurringItemsCompanion data) {
    return RecurringItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      matchPattern: data.matchPattern.present
          ? data.matchPattern.value
          : this.matchPattern,
      amountTolerancePct: data.amountTolerancePct.present
          ? data.amountTolerancePct.value
          : this.amountTolerancePct,
      isEnvelope: data.isEnvelope.present
          ? data.isEnvelope.value
          : this.isEnvelope,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('dueDay: $dueDay, ')
          ..write('cardId: $cardId, ')
          ..write('matchPattern: $matchPattern, ')
          ..write('amountTolerancePct: $amountTolerancePct, ')
          ..write('isEnvelope: $isEnvelope, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    isEstimate,
    dueDay,
    cardId,
    matchPattern,
    amountTolerancePct,
    isEnvelope,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.isEstimate == this.isEstimate &&
          other.dueDay == this.dueDay &&
          other.cardId == this.cardId &&
          other.matchPattern == this.matchPattern &&
          other.amountTolerancePct == this.amountTolerancePct &&
          other.isEnvelope == this.isEnvelope &&
          other.active == this.active);
}

class RecurringItemsCompanion extends UpdateCompanion<RecurringItemRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amount;
  final Value<bool> isEstimate;
  final Value<int> dueDay;
  final Value<int?> cardId;
  final Value<String> matchPattern;
  final Value<int?> amountTolerancePct;
  final Value<bool> isEnvelope;
  final Value<bool> active;
  const RecurringItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.cardId = const Value.absent(),
    this.matchPattern = const Value.absent(),
    this.amountTolerancePct = const Value.absent(),
    this.isEnvelope = const Value.absent(),
    this.active = const Value.absent(),
  });
  RecurringItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int amount,
    this.isEstimate = const Value.absent(),
    required int dueDay,
    this.cardId = const Value.absent(),
    required String matchPattern,
    this.amountTolerancePct = const Value.absent(),
    this.isEnvelope = const Value.absent(),
    this.active = const Value.absent(),
  }) : name = Value(name),
       amount = Value(amount),
       dueDay = Value(dueDay),
       matchPattern = Value(matchPattern);
  static Insertable<RecurringItemRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amount,
    Expression<bool>? isEstimate,
    Expression<int>? dueDay,
    Expression<int>? cardId,
    Expression<String>? matchPattern,
    Expression<int>? amountTolerancePct,
    Expression<bool>? isEnvelope,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (dueDay != null) 'due_day': dueDay,
      if (cardId != null) 'card_id': cardId,
      if (matchPattern != null) 'match_pattern': matchPattern,
      if (amountTolerancePct != null)
        'amount_tolerance_pct': amountTolerancePct,
      if (isEnvelope != null) 'is_envelope': isEnvelope,
      if (active != null) 'active': active,
    });
  }

  RecurringItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? amount,
    Value<bool>? isEstimate,
    Value<int>? dueDay,
    Value<int?>? cardId,
    Value<String>? matchPattern,
    Value<int?>? amountTolerancePct,
    Value<bool>? isEnvelope,
    Value<bool>? active,
  }) {
    return RecurringItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isEstimate: isEstimate ?? this.isEstimate,
      dueDay: dueDay ?? this.dueDay,
      cardId: cardId ?? this.cardId,
      matchPattern: matchPattern ?? this.matchPattern,
      amountTolerancePct: amountTolerancePct ?? this.amountTolerancePct,
      isEnvelope: isEnvelope ?? this.isEnvelope,
      active: active ?? this.active,
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
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (matchPattern.present) {
      map['match_pattern'] = Variable<String>(matchPattern.value);
    }
    if (amountTolerancePct.present) {
      map['amount_tolerance_pct'] = Variable<int>(amountTolerancePct.value);
    }
    if (isEnvelope.present) {
      map['is_envelope'] = Variable<bool>(isEnvelope.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('dueDay: $dueDay, ')
          ..write('cardId: $cardId, ')
          ..write('matchPattern: $matchPattern, ')
          ..write('amountTolerancePct: $amountTolerancePct, ')
          ..write('isEnvelope: $isEnvelope, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $RecurringMatchesTable extends RecurringMatches
    with TableInfo<$RecurringMatchesTable, RecurringMatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringMatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recurringItemIdMeta = const VerificationMeta(
    'recurringItemId',
  );
  @override
  late final GeneratedColumn<int> recurringItemId = GeneratedColumn<int>(
    'recurring_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_items (id)',
    ),
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedOnMeta = const VerificationMeta(
    'decidedOn',
  );
  @override
  late final GeneratedColumn<String> decidedOn = GeneratedColumn<String>(
    'decided_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recurringItemId,
    month,
    transactionId,
    status,
    decidedOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringMatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recurring_item_id')) {
      context.handle(
        _recurringItemIdMeta,
        recurringItemId.isAcceptableOrUnknown(
          data['recurring_item_id']!,
          _recurringItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recurringItemIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
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
    if (data.containsKey('decided_on')) {
      context.handle(
        _decidedOnMeta,
        decidedOn.isAcceptableOrUnknown(data['decided_on']!, _decidedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_decidedOnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringMatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringMatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recurringItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurring_item_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      decidedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_on'],
      )!,
    );
  }

  @override
  $RecurringMatchesTable createAlias(String alias) {
    return $RecurringMatchesTable(attachedDatabase, alias);
  }
}

class RecurringMatchRow extends DataClass
    implements Insertable<RecurringMatchRow> {
  final int id;
  final int recurringItemId;
  final String month;
  final int? transactionId;
  final String status;
  final String decidedOn;
  const RecurringMatchRow({
    required this.id,
    required this.recurringItemId,
    required this.month,
    this.transactionId,
    required this.status,
    required this.decidedOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recurring_item_id'] = Variable<int>(recurringItemId);
    map['month'] = Variable<String>(month);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<int>(transactionId);
    }
    map['status'] = Variable<String>(status);
    map['decided_on'] = Variable<String>(decidedOn);
    return map;
  }

  RecurringMatchesCompanion toCompanion(bool nullToAbsent) {
    return RecurringMatchesCompanion(
      id: Value(id),
      recurringItemId: Value(recurringItemId),
      month: Value(month),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      status: Value(status),
      decidedOn: Value(decidedOn),
    );
  }

  factory RecurringMatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringMatchRow(
      id: serializer.fromJson<int>(json['id']),
      recurringItemId: serializer.fromJson<int>(json['recurringItemId']),
      month: serializer.fromJson<String>(json['month']),
      transactionId: serializer.fromJson<int?>(json['transactionId']),
      status: serializer.fromJson<String>(json['status']),
      decidedOn: serializer.fromJson<String>(json['decidedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recurringItemId': serializer.toJson<int>(recurringItemId),
      'month': serializer.toJson<String>(month),
      'transactionId': serializer.toJson<int?>(transactionId),
      'status': serializer.toJson<String>(status),
      'decidedOn': serializer.toJson<String>(decidedOn),
    };
  }

  RecurringMatchRow copyWith({
    int? id,
    int? recurringItemId,
    String? month,
    Value<int?> transactionId = const Value.absent(),
    String? status,
    String? decidedOn,
  }) => RecurringMatchRow(
    id: id ?? this.id,
    recurringItemId: recurringItemId ?? this.recurringItemId,
    month: month ?? this.month,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    status: status ?? this.status,
    decidedOn: decidedOn ?? this.decidedOn,
  );
  RecurringMatchRow copyWithCompanion(RecurringMatchesCompanion data) {
    return RecurringMatchRow(
      id: data.id.present ? data.id.value : this.id,
      recurringItemId: data.recurringItemId.present
          ? data.recurringItemId.value
          : this.recurringItemId,
      month: data.month.present ? data.month.value : this.month,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      status: data.status.present ? data.status.value : this.status,
      decidedOn: data.decidedOn.present ? data.decidedOn.value : this.decidedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringMatchRow(')
          ..write('id: $id, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('month: $month, ')
          ..write('transactionId: $transactionId, ')
          ..write('status: $status, ')
          ..write('decidedOn: $decidedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recurringItemId, month, transactionId, status, decidedOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringMatchRow &&
          other.id == this.id &&
          other.recurringItemId == this.recurringItemId &&
          other.month == this.month &&
          other.transactionId == this.transactionId &&
          other.status == this.status &&
          other.decidedOn == this.decidedOn);
}

class RecurringMatchesCompanion extends UpdateCompanion<RecurringMatchRow> {
  final Value<int> id;
  final Value<int> recurringItemId;
  final Value<String> month;
  final Value<int?> transactionId;
  final Value<String> status;
  final Value<String> decidedOn;
  const RecurringMatchesCompanion({
    this.id = const Value.absent(),
    this.recurringItemId = const Value.absent(),
    this.month = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.status = const Value.absent(),
    this.decidedOn = const Value.absent(),
  });
  RecurringMatchesCompanion.insert({
    this.id = const Value.absent(),
    required int recurringItemId,
    required String month,
    this.transactionId = const Value.absent(),
    required String status,
    required String decidedOn,
  }) : recurringItemId = Value(recurringItemId),
       month = Value(month),
       status = Value(status),
       decidedOn = Value(decidedOn);
  static Insertable<RecurringMatchRow> custom({
    Expression<int>? id,
    Expression<int>? recurringItemId,
    Expression<String>? month,
    Expression<int>? transactionId,
    Expression<String>? status,
    Expression<String>? decidedOn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recurringItemId != null) 'recurring_item_id': recurringItemId,
      if (month != null) 'month': month,
      if (transactionId != null) 'transaction_id': transactionId,
      if (status != null) 'status': status,
      if (decidedOn != null) 'decided_on': decidedOn,
    });
  }

  RecurringMatchesCompanion copyWith({
    Value<int>? id,
    Value<int>? recurringItemId,
    Value<String>? month,
    Value<int?>? transactionId,
    Value<String>? status,
    Value<String>? decidedOn,
  }) {
    return RecurringMatchesCompanion(
      id: id ?? this.id,
      recurringItemId: recurringItemId ?? this.recurringItemId,
      month: month ?? this.month,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      decidedOn: decidedOn ?? this.decidedOn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recurringItemId.present) {
      map['recurring_item_id'] = Variable<int>(recurringItemId.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (decidedOn.present) {
      map['decided_on'] = Variable<String>(decidedOn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringMatchesCompanion(')
          ..write('id: $id, ')
          ..write('recurringItemId: $recurringItemId, ')
          ..write('month: $month, ')
          ..write('transactionId: $transactionId, ')
          ..write('status: $status, ')
          ..write('decidedOn: $decidedOn')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, BudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [month, amount, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  BudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetRow(
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class BudgetRow extends DataClass implements Insertable<BudgetRow> {
  final String month;
  final int amount;
  final String source;
  const BudgetRow({
    required this.month,
    required this.amount,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<String>(month);
    map['amount'] = Variable<int>(amount);
    map['source'] = Variable<String>(source);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      month: Value(month),
      amount: Value(amount),
      source: Value(source),
    );
  }

  factory BudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetRow(
      month: serializer.fromJson<String>(json['month']),
      amount: serializer.fromJson<int>(json['amount']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<String>(month),
      'amount': serializer.toJson<int>(amount),
      'source': serializer.toJson<String>(source),
    };
  }

  BudgetRow copyWith({String? month, int? amount, String? source}) => BudgetRow(
    month: month ?? this.month,
    amount: amount ?? this.amount,
    source: source ?? this.source,
  );
  BudgetRow copyWithCompanion(BudgetsCompanion data) {
    return BudgetRow(
      month: data.month.present ? data.month.value : this.month,
      amount: data.amount.present ? data.amount.value : this.amount,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetRow(')
          ..write('month: $month, ')
          ..write('amount: $amount, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(month, amount, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetRow &&
          other.month == this.month &&
          other.amount == this.amount &&
          other.source == this.source);
}

class BudgetsCompanion extends UpdateCompanion<BudgetRow> {
  final Value<String> month;
  final Value<int> amount;
  final Value<String> source;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.month = const Value.absent(),
    this.amount = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String month,
    required int amount,
    required String source,
    this.rowid = const Value.absent(),
  }) : month = Value(month),
       amount = Value(amount),
       source = Value(source);
  static Insertable<BudgetRow> custom({
    Expression<String>? month,
    Expression<int>? amount,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (amount != null) 'amount': amount,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? month,
    Value<int>? amount,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      month: month ?? this.month,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('month: $month, ')
          ..write('amount: $amount, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetPlansTable extends BudgetPlans
    with TableInfo<$BudgetPlansTable, BudgetPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMonthMeta = const VerificationMeta(
    'startMonth',
  );
  @override
  late final GeneratedColumn<String> startMonth = GeneratedColumn<String>(
    'start_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAmountMeta = const VerificationMeta(
    'startAmount',
  );
  @override
  late final GeneratedColumn<int> startAmount = GeneratedColumn<int>(
    'start_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
    'target_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthsMeta = const VerificationMeta('months');
  @override
  late final GeneratedColumn<int> months = GeneratedColumn<int>(
    'months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    startMonth,
    startAmount,
    targetAmount,
    months,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('start_month')) {
      context.handle(
        _startMonthMeta,
        startMonth.isAcceptableOrUnknown(data['start_month']!, _startMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_startMonthMeta);
    }
    if (data.containsKey('start_amount')) {
      context.handle(
        _startAmountMeta,
        startAmount.isAcceptableOrUnknown(
          data['start_amount']!,
          _startAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAmountMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('months')) {
      context.handle(
        _monthsMeta,
        months.isAcceptableOrUnknown(data['months']!, _monthsMeta),
      );
    } else if (isInserting) {
      context.missing(_monthsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      startMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_month'],
      )!,
      startAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_amount'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount'],
      )!,
      months: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}months'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BudgetPlansTable createAlias(String alias) {
    return $BudgetPlansTable(attachedDatabase, alias);
  }
}

class BudgetPlanRow extends DataClass implements Insertable<BudgetPlanRow> {
  final int id;
  final String mode;
  final String startMonth;
  final int startAmount;
  final int targetAmount;
  final int months;
  final DateTime createdAt;
  const BudgetPlanRow({
    required this.id,
    required this.mode,
    required this.startMonth,
    required this.startAmount,
    required this.targetAmount,
    required this.months,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mode'] = Variable<String>(mode);
    map['start_month'] = Variable<String>(startMonth);
    map['start_amount'] = Variable<int>(startAmount);
    map['target_amount'] = Variable<int>(targetAmount);
    map['months'] = Variable<int>(months);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetPlansCompanion toCompanion(bool nullToAbsent) {
    return BudgetPlansCompanion(
      id: Value(id),
      mode: Value(mode),
      startMonth: Value(startMonth),
      startAmount: Value(startAmount),
      targetAmount: Value(targetAmount),
      months: Value(months),
      createdAt: Value(createdAt),
    );
  }

  factory BudgetPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetPlanRow(
      id: serializer.fromJson<int>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      startMonth: serializer.fromJson<String>(json['startMonth']),
      startAmount: serializer.fromJson<int>(json['startAmount']),
      targetAmount: serializer.fromJson<int>(json['targetAmount']),
      months: serializer.fromJson<int>(json['months']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mode': serializer.toJson<String>(mode),
      'startMonth': serializer.toJson<String>(startMonth),
      'startAmount': serializer.toJson<int>(startAmount),
      'targetAmount': serializer.toJson<int>(targetAmount),
      'months': serializer.toJson<int>(months),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BudgetPlanRow copyWith({
    int? id,
    String? mode,
    String? startMonth,
    int? startAmount,
    int? targetAmount,
    int? months,
    DateTime? createdAt,
  }) => BudgetPlanRow(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    startMonth: startMonth ?? this.startMonth,
    startAmount: startAmount ?? this.startAmount,
    targetAmount: targetAmount ?? this.targetAmount,
    months: months ?? this.months,
    createdAt: createdAt ?? this.createdAt,
  );
  BudgetPlanRow copyWithCompanion(BudgetPlansCompanion data) {
    return BudgetPlanRow(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      startMonth: data.startMonth.present
          ? data.startMonth.value
          : this.startMonth,
      startAmount: data.startAmount.present
          ? data.startAmount.value
          : this.startAmount,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      months: data.months.present ? data.months.value : this.months,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetPlanRow(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startMonth: $startMonth, ')
          ..write('startAmount: $startAmount, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('months: $months, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    startMonth,
    startAmount,
    targetAmount,
    months,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetPlanRow &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.startMonth == this.startMonth &&
          other.startAmount == this.startAmount &&
          other.targetAmount == this.targetAmount &&
          other.months == this.months &&
          other.createdAt == this.createdAt);
}

class BudgetPlansCompanion extends UpdateCompanion<BudgetPlanRow> {
  final Value<int> id;
  final Value<String> mode;
  final Value<String> startMonth;
  final Value<int> startAmount;
  final Value<int> targetAmount;
  final Value<int> months;
  final Value<DateTime> createdAt;
  const BudgetPlansCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.startAmount = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.months = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BudgetPlansCompanion.insert({
    this.id = const Value.absent(),
    required String mode,
    required String startMonth,
    required int startAmount,
    required int targetAmount,
    required int months,
    this.createdAt = const Value.absent(),
  }) : mode = Value(mode),
       startMonth = Value(startMonth),
       startAmount = Value(startAmount),
       targetAmount = Value(targetAmount),
       months = Value(months);
  static Insertable<BudgetPlanRow> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<String>? startMonth,
    Expression<int>? startAmount,
    Expression<int>? targetAmount,
    Expression<int>? months,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (startMonth != null) 'start_month': startMonth,
      if (startAmount != null) 'start_amount': startAmount,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (months != null) 'months': months,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BudgetPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? mode,
    Value<String>? startMonth,
    Value<int>? startAmount,
    Value<int>? targetAmount,
    Value<int>? months,
    Value<DateTime>? createdAt,
  }) {
    return BudgetPlansCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      startMonth: startMonth ?? this.startMonth,
      startAmount: startAmount ?? this.startAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      months: months ?? this.months,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<String>(startMonth.value);
    }
    if (startAmount.present) {
      map['start_amount'] = Variable<int>(startAmount.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    if (months.present) {
      map['months'] = Variable<int>(months.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetPlansCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startMonth: $startMonth, ')
          ..write('startAmount: $startAmount, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('months: $months, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MerchantRulesTable extends MerchantRules
    with TableInfo<$MerchantRulesTable, MerchantRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _merchantNormMeta = const VerificationMeta(
    'merchantNorm',
  );
  @override
  late final GeneratedColumn<String> merchantNorm = GeneratedColumn<String>(
    'merchant_norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [merchantNorm, categoryId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<MerchantRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('merchant_norm')) {
      context.handle(
        _merchantNormMeta,
        merchantNorm.isAcceptableOrUnknown(
          data['merchant_norm']!,
          _merchantNormMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantNormMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {merchantNorm};
  @override
  MerchantRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantRuleRow(
      merchantNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_norm'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MerchantRulesTable createAlias(String alias) {
    return $MerchantRulesTable(attachedDatabase, alias);
  }
}

class MerchantRuleRow extends DataClass implements Insertable<MerchantRuleRow> {
  final String merchantNorm;
  final int categoryId;
  final DateTime updatedAt;
  const MerchantRuleRow({
    required this.merchantNorm,
    required this.categoryId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['merchant_norm'] = Variable<String>(merchantNorm);
    map['category_id'] = Variable<int>(categoryId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MerchantRulesCompanion toCompanion(bool nullToAbsent) {
    return MerchantRulesCompanion(
      merchantNorm: Value(merchantNorm),
      categoryId: Value(categoryId),
      updatedAt: Value(updatedAt),
    );
  }

  factory MerchantRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantRuleRow(
      merchantNorm: serializer.fromJson<String>(json['merchantNorm']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'merchantNorm': serializer.toJson<String>(merchantNorm),
      'categoryId': serializer.toJson<int>(categoryId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MerchantRuleRow copyWith({
    String? merchantNorm,
    int? categoryId,
    DateTime? updatedAt,
  }) => MerchantRuleRow(
    merchantNorm: merchantNorm ?? this.merchantNorm,
    categoryId: categoryId ?? this.categoryId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MerchantRuleRow copyWithCompanion(MerchantRulesCompanion data) {
    return MerchantRuleRow(
      merchantNorm: data.merchantNorm.present
          ? data.merchantNorm.value
          : this.merchantNorm,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRuleRow(')
          ..write('merchantNorm: $merchantNorm, ')
          ..write('categoryId: $categoryId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(merchantNorm, categoryId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantRuleRow &&
          other.merchantNorm == this.merchantNorm &&
          other.categoryId == this.categoryId &&
          other.updatedAt == this.updatedAt);
}

class MerchantRulesCompanion extends UpdateCompanion<MerchantRuleRow> {
  final Value<String> merchantNorm;
  final Value<int> categoryId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MerchantRulesCompanion({
    this.merchantNorm = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MerchantRulesCompanion.insert({
    required String merchantNorm,
    required int categoryId,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : merchantNorm = Value(merchantNorm),
       categoryId = Value(categoryId);
  static Insertable<MerchantRuleRow> custom({
    Expression<String>? merchantNorm,
    Expression<int>? categoryId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (merchantNorm != null) 'merchant_norm': merchantNorm,
      if (categoryId != null) 'category_id': categoryId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MerchantRulesCompanion copyWith({
    Value<String>? merchantNorm,
    Value<int>? categoryId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MerchantRulesCompanion(
      merchantNorm: merchantNorm ?? this.merchantNorm,
      categoryId: categoryId ?? this.categoryId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (merchantNorm.present) {
      map['merchant_norm'] = Variable<String>(merchantNorm.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRulesCompanion(')
          ..write('merchantNorm: $merchantNorm, ')
          ..write('categoryId: $categoryId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationLogsTable extends NotificationLogs
    with TableInfo<$NotificationLogsTable, NotificationLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, type, sentAt, localDate, summary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
    );
  }

  @override
  $NotificationLogsTable createAlias(String alias) {
    return $NotificationLogsTable(attachedDatabase, alias);
  }
}

class NotificationLogRow extends DataClass
    implements Insertable<NotificationLogRow> {
  final int id;
  final String type;
  final DateTime sentAt;
  final String localDate;
  final String? summary;
  const NotificationLogRow({
    required this.id,
    required this.type,
    required this.sentAt,
    required this.localDate,
    this.summary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    return map;
  }

  NotificationLogsCompanion toCompanion(bool nullToAbsent) {
    return NotificationLogsCompanion(
      id: Value(id),
      type: Value(type),
      sentAt: Value(sentAt),
      localDate: Value(localDate),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
    );
  }

  factory NotificationLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLogRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      localDate: serializer.fromJson<String>(json['localDate']),
      summary: serializer.fromJson<String?>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'localDate': serializer.toJson<String>(localDate),
      'summary': serializer.toJson<String?>(summary),
    };
  }

  NotificationLogRow copyWith({
    int? id,
    String? type,
    DateTime? sentAt,
    String? localDate,
    Value<String?> summary = const Value.absent(),
  }) => NotificationLogRow(
    id: id ?? this.id,
    type: type ?? this.type,
    sentAt: sentAt ?? this.sentAt,
    localDate: localDate ?? this.localDate,
    summary: summary.present ? summary.value : this.summary,
  );
  NotificationLogRow copyWithCompanion(NotificationLogsCompanion data) {
    return NotificationLogRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('sentAt: $sentAt, ')
          ..write('localDate: $localDate, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, sentAt, localDate, summary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLogRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.sentAt == this.sentAt &&
          other.localDate == this.localDate &&
          other.summary == this.summary);
}

class NotificationLogsCompanion extends UpdateCompanion<NotificationLogRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<DateTime> sentAt;
  final Value<String> localDate;
  final Value<String?> summary;
  const NotificationLogsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.localDate = const Value.absent(),
    this.summary = const Value.absent(),
  });
  NotificationLogsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required DateTime sentAt,
    required String localDate,
    this.summary = const Value.absent(),
  }) : type = Value(type),
       sentAt = Value(sentAt),
       localDate = Value(localDate);
  static Insertable<NotificationLogRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<DateTime>? sentAt,
    Expression<String>? localDate,
    Expression<String>? summary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (sentAt != null) 'sent_at': sentAt,
      if (localDate != null) 'local_date': localDate,
      if (summary != null) 'summary': summary,
    });
  }

  NotificationLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<DateTime>? sentAt,
    Value<String>? localDate,
    Value<String?>? summary,
  }) {
    return NotificationLogsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      localDate: localDate ?? this.localDate,
      summary: summary ?? this.summary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('sentAt: $sentAt, ')
          ..write('localDate: $localDate, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }
}

class $MetricEventsTable extends MetricEvents
    with TableInfo<$MetricEventsTable, MetricEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, type, at, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metric_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetricEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MetricEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $MetricEventsTable createAlias(String alias) {
    return $MetricEventsTable(attachedDatabase, alias);
  }
}

class MetricEventRow extends DataClass implements Insertable<MetricEventRow> {
  final int id;
  final String type;
  final DateTime at;
  final String data;
  const MetricEventRow({
    required this.id,
    required this.type,
    required this.at,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['at'] = Variable<DateTime>(at);
    map['data'] = Variable<String>(data);
    return map;
  }

  MetricEventsCompanion toCompanion(bool nullToAbsent) {
    return MetricEventsCompanion(
      id: Value(id),
      type: Value(type),
      at: Value(at),
      data: Value(data),
    );
  }

  factory MetricEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricEventRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      at: serializer.fromJson<DateTime>(json['at']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'at': serializer.toJson<DateTime>(at),
      'data': serializer.toJson<String>(data),
    };
  }

  MetricEventRow copyWith({
    int? id,
    String? type,
    DateTime? at,
    String? data,
  }) => MetricEventRow(
    id: id ?? this.id,
    type: type ?? this.type,
    at: at ?? this.at,
    data: data ?? this.data,
  );
  MetricEventRow copyWithCompanion(MetricEventsCompanion data) {
    return MetricEventRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      at: data.at.present ? data.at.value : this.at,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricEventRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('at: $at, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, at, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricEventRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.at == this.at &&
          other.data == this.data);
}

class MetricEventsCompanion extends UpdateCompanion<MetricEventRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<DateTime> at;
  final Value<String> data;
  const MetricEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.at = const Value.absent(),
    this.data = const Value.absent(),
  });
  MetricEventsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required DateTime at,
    required String data,
  }) : type = Value(type),
       at = Value(at),
       data = Value(data);
  static Insertable<MetricEventRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<DateTime>? at,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (at != null) 'at': at,
      if (data != null) 'data': data,
    });
  }

  MetricEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<DateTime>? at,
    Value<String>? data,
  }) {
    return MetricEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      at: at ?? this.at,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('at: $at, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $PlannedExpensesTable extends PlannedExpenses
    with TableInfo<$PlannedExpensesTable, PlannedExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneOnMeta = const VerificationMeta('doneOn');
  @override
  late final GeneratedColumn<String> doneOn = GeneratedColumn<String>(
    'done_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USER'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    date,
    doneOn,
    transactionId,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('done_on')) {
      context.handle(
        _doneOnMeta,
        doneOn.isAcceptableOrUnknown(data['done_on']!, _doneOnMeta),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      doneOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}done_on'],
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlannedExpensesTable createAlias(String alias) {
    return $PlannedExpensesTable(attachedDatabase, alias);
  }
}

class PlannedExpenseRow extends DataClass
    implements Insertable<PlannedExpenseRow> {
  final int id;
  final String name;
  final int amount;
  final String date;
  final String? doneOn;
  final int? transactionId;
  final String source;
  final DateTime createdAt;
  const PlannedExpenseRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.doneOn,
    this.transactionId,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || doneOn != null) {
      map['done_on'] = Variable<String>(doneOn);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<int>(transactionId);
    }
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlannedExpensesCompanion toCompanion(bool nullToAbsent) {
    return PlannedExpensesCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      date: Value(date),
      doneOn: doneOn == null && nullToAbsent
          ? const Value.absent()
          : Value(doneOn),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory PlannedExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedExpenseRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      doneOn: serializer.fromJson<String?>(json['doneOn']),
      transactionId: serializer.fromJson<int?>(json['transactionId']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<String>(date),
      'doneOn': serializer.toJson<String?>(doneOn),
      'transactionId': serializer.toJson<int?>(transactionId),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlannedExpenseRow copyWith({
    int? id,
    String? name,
    int? amount,
    String? date,
    Value<String?> doneOn = const Value.absent(),
    Value<int?> transactionId = const Value.absent(),
    String? source,
    DateTime? createdAt,
  }) => PlannedExpenseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    doneOn: doneOn.present ? doneOn.value : this.doneOn,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  PlannedExpenseRow copyWithCompanion(PlannedExpensesCompanion data) {
    return PlannedExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      doneOn: data.doneOn.present ? data.doneOn.value : this.doneOn,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedExpenseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('doneOn: $doneOn, ')
          ..write('transactionId: $transactionId, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    date,
    doneOn,
    transactionId,
    source,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedExpenseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.doneOn == this.doneOn &&
          other.transactionId == this.transactionId &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class PlannedExpensesCompanion extends UpdateCompanion<PlannedExpenseRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amount;
  final Value<String> date;
  final Value<String?> doneOn;
  final Value<int?> transactionId;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const PlannedExpensesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.doneOn = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlannedExpensesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int amount,
    required String date,
    this.doneOn = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       amount = Value(amount),
       date = Value(date);
  static Insertable<PlannedExpenseRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amount,
    Expression<String>? date,
    Expression<String>? doneOn,
    Expression<int>? transactionId,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (doneOn != null) 'done_on': doneOn,
      if (transactionId != null) 'transaction_id': transactionId,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlannedExpensesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? amount,
    Value<String>? date,
    Value<String?>? doneOn,
    Value<int?>? transactionId,
    Value<String>? source,
    Value<DateTime>? createdAt,
  }) {
    return PlannedExpensesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      doneOn: doneOn ?? this.doneOn,
      transactionId: transactionId ?? this.transactionId,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
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
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (doneOn.present) {
      map['done_on'] = Variable<String>(doneOn.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedExpensesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('doneOn: $doneOn, ')
          ..write('transactionId: $transactionId, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $InstallmentSchedulesTable installmentSchedules =
      $InstallmentSchedulesTable(this);
  late final $RecurringItemsTable recurringItems = $RecurringItemsTable(this);
  late final $RecurringMatchesTable recurringMatches = $RecurringMatchesTable(
    this,
  );
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $BudgetPlansTable budgetPlans = $BudgetPlansTable(this);
  late final $MerchantRulesTable merchantRules = $MerchantRulesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $NotificationLogsTable notificationLogs = $NotificationLogsTable(
    this,
  );
  late final $MetricEventsTable metricEvents = $MetricEventsTable(this);
  late final $PlannedExpensesTable plannedExpenses = $PlannedExpensesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cards,
    categories,
    transactions,
    installmentSchedules,
    recurringItems,
    recurringMatches,
    budgets,
    budgetPlans,
    merchantRules,
    settings,
    notificationLogs,
    metricEvents,
    plannedExpenses,
  ];
}

typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  required String issuer,
  required String productName,
  Value<String?> source,
  Value<String?> last4,
  Value<bool> active,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  Value<String> issuer,
  Value<String> productName,
  Value<String?> source,
  Value<String?> last4,
  Value<bool> active,
});

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, CardRow> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'cards__id__transactions__card_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get issuer =>
      $composableBuilder(column: $table.issuer, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          CardRow,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardRow, $$CardsTableReferences),
          CardRow,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> issuer = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                issuer: issuer,
                productName: productName,
                source: source,
                last4: last4,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String issuer,
                required String productName,
                Value<String?> source = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                issuer: issuer,
                productName: productName,
                source: source,
                last4: last4,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CardsTable, CardRow>(table),
                  $$CardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      CardRow,
                      $CardsTable,
                      TransactionRow
                    >(
                      currentTable: table,
                      referencedTable: $$CardsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$CardsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cardId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      CardRow,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardRow, $$CardsTableReferences),
      CardRow,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<int> sortOrder,
  Value<bool> isDefault,
  Value<bool> hidden,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<bool> isDefault,
  Value<bool> hidden,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _confirmedTransactionsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactions,
        aliasName: 'categories__id__transactions__category_id',
      );

  $$TransactionsTableProcessedTableManager get confirmedTransactions {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _confirmedTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _suggestedTransactionsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactions,
        aliasName: 'categories__id__transactions__suggested_category_id',
      );

  $$TransactionsTableProcessedTableManager get suggestedTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.suggestedCategoryId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _suggestedTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MerchantRulesTable, List<MerchantRuleRow>>
  _merchantRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.merchantRules,
    aliasName: 'categories__id__merchant_rules__category_id',
  );

  $$MerchantRulesTableProcessedTableManager get merchantRulesRefs {
    final manager = $$MerchantRulesTableTableManager(
      $_db,
      $_db.merchantRules,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_merchantRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> confirmedTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> suggestedTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.suggestedCategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> merchantRulesRefs(
    Expression<bool> Function($$MerchantRulesTableFilterComposer f) f,
  ) {
    final $$MerchantRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.merchantRules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MerchantRulesTableFilterComposer(
            $db: $db,
            $table: $db.merchantRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  Expression<T> confirmedTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> suggestedTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.suggestedCategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> merchantRulesRefs<T extends Object>(
    Expression<T> Function($$MerchantRulesTableAnnotationComposer a) f,
  ) {
    final $$MerchantRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.merchantRules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MerchantRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.merchantRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool confirmedTransactions,
            bool suggestedTransactions,
            bool merchantRulesRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                isDefault: isDefault,
                hidden: hidden,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                isDefault: isDefault,
                hidden: hidden,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                confirmedTransactions = false,
                suggestedTransactions = false,
                merchantRulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (confirmedTransactions) db.transactions,
                    if (suggestedTransactions) db.transactions,
                    if (merchantRulesRefs) db.merchantRules,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (confirmedTransactions)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._confirmedTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).confirmedTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (suggestedTransactions)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._suggestedTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).suggestedTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.suggestedCategoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (merchantRulesRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          MerchantRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._merchantRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).merchantRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool confirmedTransactions,
        bool suggestedTransactions,
        bool merchantRulesRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int?> cardId,
      required String kind,
      required int amount,
      Value<String> currency,
      Value<String?> originalAmount,
      required String merchantRaw,
      required String merchantNorm,
      required DateTime approvedAt,
      required String localDate,
      Value<int> installmentMonths,
      Value<bool> isForeign,
      Value<String> status,
      Value<bool> excludedFromSums,
      Value<int?> cancelOfId,
      Value<int?> categoryId,
      Value<int?> suggestedCategoryId,
      Value<String?> suggestSource,
      Value<bool> isUnusual,
      Value<String?> memo,
      Value<bool> confirmed,
      Value<bool> needsReview,
      Value<String?> reviewReason,
      Value<int?> recurringItemId,
      Value<String> rawText,
      Value<String?> sourcePackage,
      Value<String?> notifKey,
      required String dedupeKey,
      Value<DateTime> createdAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int?> cardId,
      Value<String> kind,
      Value<int> amount,
      Value<String> currency,
      Value<String?> originalAmount,
      Value<String> merchantRaw,
      Value<String> merchantNorm,
      Value<DateTime> approvedAt,
      Value<String> localDate,
      Value<int> installmentMonths,
      Value<bool> isForeign,
      Value<String> status,
      Value<bool> excludedFromSums,
      Value<int?> cancelOfId,
      Value<int?> categoryId,
      Value<int?> suggestedCategoryId,
      Value<String?> suggestSource,
      Value<bool> isUnusual,
      Value<String?> memo,
      Value<bool> confirmed,
      Value<bool> needsReview,
      Value<String?> reviewReason,
      Value<int?> recurringItemId,
      Value<String> rawText,
      Value<String?> sourcePackage,
      Value<String?> notifKey,
      Value<String> dedupeKey,
      Value<DateTime> createdAt,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$AppDatabase db) =>
      db.cards.createAlias('transactions__card_id__cards__id');

  $$CardsTableProcessedTableManager? get cardId {
    final $_column = $_itemColumn<int>('card_id');
    if ($_column == null) return null;
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _suggestedCategoryIdTable(_$AppDatabase db) => db
      .categories
      .createAlias('transactions__suggested_category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get suggestedCategoryId {
    final $_column = $_itemColumn<int>('suggested_category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_suggestedCategoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $InstallmentSchedulesTable,
    List<InstallmentScheduleRow>
  >
  _installmentSchedulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.installmentSchedules,
        aliasName: 'transactions__id__installment_schedules__transaction_id',
      );

  $$InstallmentSchedulesTableProcessedTableManager
  get installmentSchedulesRefs {
    final manager = $$InstallmentSchedulesTableTableManager(
      $_db,
      $_db.installmentSchedules,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _installmentSchedulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantRaw => $composableBuilder(
    column: $table.merchantRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantNorm => $composableBuilder(
    column: $table.merchantNorm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentMonths => $composableBuilder(
    column: $table.installmentMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isForeign => $composableBuilder(
    column: $table.isForeign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludedFromSums => $composableBuilder(
    column: $table.excludedFromSums,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cancelOfId => $composableBuilder(
    column: $table.cancelOfId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestSource => $composableBuilder(
    column: $table.suggestSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnusual => $composableBuilder(
    column: $table.isUnusual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewReason => $composableBuilder(
    column: $table.reviewReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurringItemId => $composableBuilder(
    column: $table.recurringItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notifKey => $composableBuilder(
    column: $table.notifKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get suggestedCategoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.suggestedCategoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> installmentSchedulesRefs(
    Expression<bool> Function($$InstallmentSchedulesTableFilterComposer f) f,
  ) {
    final $$InstallmentSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installmentSchedules,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.installmentSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantRaw => $composableBuilder(
    column: $table.merchantRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantNorm => $composableBuilder(
    column: $table.merchantNorm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentMonths => $composableBuilder(
    column: $table.installmentMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isForeign => $composableBuilder(
    column: $table.isForeign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludedFromSums => $composableBuilder(
    column: $table.excludedFromSums,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cancelOfId => $composableBuilder(
    column: $table.cancelOfId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestSource => $composableBuilder(
    column: $table.suggestSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnusual => $composableBuilder(
    column: $table.isUnusual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewReason => $composableBuilder(
    column: $table.reviewReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurringItemId => $composableBuilder(
    column: $table.recurringItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notifKey => $composableBuilder(
    column: $table.notifKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get suggestedCategoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.suggestedCategoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantRaw => $composableBuilder(
    column: $table.merchantRaw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantNorm => $composableBuilder(
    column: $table.merchantNorm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<int> get installmentMonths => $composableBuilder(
    column: $table.installmentMonths,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isForeign =>
      $composableBuilder(column: $table.isForeign, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get excludedFromSums => $composableBuilder(
    column: $table.excludedFromSums,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cancelOfId => $composableBuilder(
    column: $table.cancelOfId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suggestSource => $composableBuilder(
    column: $table.suggestSource,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUnusual =>
      $composableBuilder(column: $table.isUnusual, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);

  GeneratedColumn<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewReason => $composableBuilder(
    column: $table.reviewReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurringItemId => $composableBuilder(
    column: $table.recurringItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notifKey =>
      $composableBuilder(column: $table.notifKey, builder: (column) => column);

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get suggestedCategoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.suggestedCategoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> installmentSchedulesRefs<T extends Object>(
    Expression<T> Function($$InstallmentSchedulesTableAnnotationComposer a) f,
  ) {
    final $$InstallmentSchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.installmentSchedules,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentSchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.installmentSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({
            bool cardId,
            bool categoryId,
            bool suggestedCategoryId,
            bool installmentSchedulesRefs,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> cardId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> originalAmount = const Value.absent(),
                Value<String> merchantRaw = const Value.absent(),
                Value<String> merchantNorm = const Value.absent(),
                Value<DateTime> approvedAt = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<int> installmentMonths = const Value.absent(),
                Value<bool> isForeign = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> excludedFromSums = const Value.absent(),
                Value<int?> cancelOfId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> suggestedCategoryId = const Value.absent(),
                Value<String?> suggestSource = const Value.absent(),
                Value<bool> isUnusual = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<String?> reviewReason = const Value.absent(),
                Value<int?> recurringItemId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> sourcePackage = const Value.absent(),
                Value<String?> notifKey = const Value.absent(),
                Value<String> dedupeKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                cardId: cardId,
                kind: kind,
                amount: amount,
                currency: currency,
                originalAmount: originalAmount,
                merchantRaw: merchantRaw,
                merchantNorm: merchantNorm,
                approvedAt: approvedAt,
                localDate: localDate,
                installmentMonths: installmentMonths,
                isForeign: isForeign,
                status: status,
                excludedFromSums: excludedFromSums,
                cancelOfId: cancelOfId,
                categoryId: categoryId,
                suggestedCategoryId: suggestedCategoryId,
                suggestSource: suggestSource,
                isUnusual: isUnusual,
                memo: memo,
                confirmed: confirmed,
                needsReview: needsReview,
                reviewReason: reviewReason,
                recurringItemId: recurringItemId,
                rawText: rawText,
                sourcePackage: sourcePackage,
                notifKey: notifKey,
                dedupeKey: dedupeKey,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> cardId = const Value.absent(),
                required String kind,
                required int amount,
                Value<String> currency = const Value.absent(),
                Value<String?> originalAmount = const Value.absent(),
                required String merchantRaw,
                required String merchantNorm,
                required DateTime approvedAt,
                required String localDate,
                Value<int> installmentMonths = const Value.absent(),
                Value<bool> isForeign = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> excludedFromSums = const Value.absent(),
                Value<int?> cancelOfId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> suggestedCategoryId = const Value.absent(),
                Value<String?> suggestSource = const Value.absent(),
                Value<bool> isUnusual = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<String?> reviewReason = const Value.absent(),
                Value<int?> recurringItemId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> sourcePackage = const Value.absent(),
                Value<String?> notifKey = const Value.absent(),
                required String dedupeKey,
                Value<DateTime> createdAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                cardId: cardId,
                kind: kind,
                amount: amount,
                currency: currency,
                originalAmount: originalAmount,
                merchantRaw: merchantRaw,
                merchantNorm: merchantNorm,
                approvedAt: approvedAt,
                localDate: localDate,
                installmentMonths: installmentMonths,
                isForeign: isForeign,
                status: status,
                excludedFromSums: excludedFromSums,
                cancelOfId: cancelOfId,
                categoryId: categoryId,
                suggestedCategoryId: suggestedCategoryId,
                suggestSource: suggestSource,
                isUnusual: isUnusual,
                memo: memo,
                confirmed: confirmed,
                needsReview: needsReview,
                reviewReason: reviewReason,
                recurringItemId: recurringItemId,
                rawText: rawText,
                sourcePackage: sourcePackage,
                notifKey: notifKey,
                dedupeKey: dedupeKey,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cardId = false,
                categoryId = false,
                suggestedCategoryId = false,
                installmentSchedulesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (installmentSchedulesRefs) db.installmentSchedules,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cardId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cardId,
                            referencedTable: $$TransactionsTableReferences
                                ._cardIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._cardIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TransactionsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (suggestedCategoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.suggestedCategoryId,
                            referencedTable: $$TransactionsTableReferences
                                ._suggestedCategoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._suggestedCategoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (installmentSchedulesRefs)
                        await $_getPrefetchedData<
                          TransactionRow,
                          $TransactionsTable,
                          InstallmentScheduleRow
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._installmentSchedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).installmentSchedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({
        bool cardId,
        bool categoryId,
        bool suggestedCategoryId,
        bool installmentSchedulesRefs,
      })
    >;
typedef $$InstallmentSchedulesTableCreateCompanionBuilder =
    InstallmentSchedulesCompanion Function({
      Value<int> id,
      required int transactionId,
      required int seq,
      required String month,
      required int amount,
      Value<bool> voided,
    });
typedef $$InstallmentSchedulesTableUpdateCompanionBuilder =
    InstallmentSchedulesCompanion Function({
      Value<int> id,
      Value<int> transactionId,
      Value<int> seq,
      Value<String> month,
      Value<int> amount,
      Value<bool> voided,
    });

final class $$InstallmentSchedulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstallmentSchedulesTable,
          InstallmentScheduleRow
        > {
  $$InstallmentSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) => db
      .transactions
      .createAlias('installment_schedules__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<int>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstallmentSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentSchedulesTable> {
  $$InstallmentSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentSchedulesTable> {
  $$InstallmentSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentSchedulesTable> {
  $$InstallmentSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get voided =>
      $composableBuilder(column: $table.voided, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentSchedulesTable,
          InstallmentScheduleRow,
          $$InstallmentSchedulesTableFilterComposer,
          $$InstallmentSchedulesTableOrderingComposer,
          $$InstallmentSchedulesTableAnnotationComposer,
          $$InstallmentSchedulesTableCreateCompanionBuilder,
          $$InstallmentSchedulesTableUpdateCompanionBuilder,
          (InstallmentScheduleRow, $$InstallmentSchedulesTableReferences),
          InstallmentScheduleRow,
          PrefetchHooks Function({bool transactionId})
        > {
  $$InstallmentSchedulesTableTableManager(
    _$AppDatabase db,
    $InstallmentSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallmentSchedulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstallmentSchedulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> transactionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<bool> voided = const Value.absent(),
              }) => InstallmentSchedulesCompanion(
                id: id,
                transactionId: transactionId,
                seq: seq,
                month: month,
                amount: amount,
                voided: voided,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int transactionId,
                required int seq,
                required String month,
                required int amount,
                Value<bool> voided = const Value.absent(),
              }) => InstallmentSchedulesCompanion.insert(
                id: id,
                transactionId: transactionId,
                seq: seq,
                month: month,
                amount: amount,
                voided: voided,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InstallmentSchedulesTable,
                    InstallmentScheduleRow
                  >(table),
                  $$InstallmentSchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$InstallmentSchedulesTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$InstallmentSchedulesTableReferences
                            ._transactionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstallmentSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentSchedulesTable,
      InstallmentScheduleRow,
      $$InstallmentSchedulesTableFilterComposer,
      $$InstallmentSchedulesTableOrderingComposer,
      $$InstallmentSchedulesTableAnnotationComposer,
      $$InstallmentSchedulesTableCreateCompanionBuilder,
      $$InstallmentSchedulesTableUpdateCompanionBuilder,
      (InstallmentScheduleRow, $$InstallmentSchedulesTableReferences),
      InstallmentScheduleRow,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$RecurringItemsTableCreateCompanionBuilder =
    RecurringItemsCompanion Function({
      Value<int> id,
      required String name,
      required int amount,
      Value<bool> isEstimate,
      required int dueDay,
      Value<int?> cardId,
      required String matchPattern,
      Value<int?> amountTolerancePct,
      Value<bool> isEnvelope,
      Value<bool> active,
    });
typedef $$RecurringItemsTableUpdateCompanionBuilder =
    RecurringItemsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> amount,
      Value<bool> isEstimate,
      Value<int> dueDay,
      Value<int?> cardId,
      Value<String> matchPattern,
      Value<int?> amountTolerancePct,
      Value<bool> isEnvelope,
      Value<bool> active,
    });

final class $$RecurringItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $RecurringItemsTable, RecurringItemRow> {
  $$RecurringItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$RecurringMatchesTable, List<RecurringMatchRow>>
  _recurringMatchesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recurringMatches,
    aliasName: 'recurring_items__id__recurring_matches__recurring_item_id',
  );

  $$RecurringMatchesTableProcessedTableManager get recurringMatchesRefs {
    final manager = $$RecurringMatchesTableTableManager(
      $_db,
      $_db.recurringMatches,
    ).filter((f) => f.recurringItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recurringMatchesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurringItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringItemsTable> {
  $$RecurringItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchPattern => $composableBuilder(
    column: $table.matchPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountTolerancePct => $composableBuilder(
    column: $table.amountTolerancePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnvelope => $composableBuilder(
    column: $table.isEnvelope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recurringMatchesRefs(
    Expression<bool> Function($$RecurringMatchesTableFilterComposer f) f,
  ) {
    final $$RecurringMatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringMatches,
      getReferencedColumn: (t) => t.recurringItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringMatchesTableFilterComposer(
            $db: $db,
            $table: $db.recurringMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringItemsTable> {
  $$RecurringItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchPattern => $composableBuilder(
    column: $table.matchPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountTolerancePct => $composableBuilder(
    column: $table.amountTolerancePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnvelope => $composableBuilder(
    column: $table.isEnvelope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringItemsTable> {
  $$RecurringItemsTableAnnotationComposer({
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

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get matchPattern => $composableBuilder(
    column: $table.matchPattern,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountTolerancePct => $composableBuilder(
    column: $table.amountTolerancePct,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnvelope => $composableBuilder(
    column: $table.isEnvelope,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> recurringMatchesRefs<T extends Object>(
    Expression<T> Function($$RecurringMatchesTableAnnotationComposer a) f,
  ) {
    final $$RecurringMatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringMatches,
      getReferencedColumn: (t) => t.recurringItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringMatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringItemsTable,
          RecurringItemRow,
          $$RecurringItemsTableFilterComposer,
          $$RecurringItemsTableOrderingComposer,
          $$RecurringItemsTableAnnotationComposer,
          $$RecurringItemsTableCreateCompanionBuilder,
          $$RecurringItemsTableUpdateCompanionBuilder,
          (RecurringItemRow, $$RecurringItemsTableReferences),
          RecurringItemRow,
          PrefetchHooks Function({bool recurringMatchesRefs})
        > {
  $$RecurringItemsTableTableManager(
    _$AppDatabase db,
    $RecurringItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<int> dueDay = const Value.absent(),
                Value<int?> cardId = const Value.absent(),
                Value<String> matchPattern = const Value.absent(),
                Value<int?> amountTolerancePct = const Value.absent(),
                Value<bool> isEnvelope = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => RecurringItemsCompanion(
                id: id,
                name: name,
                amount: amount,
                isEstimate: isEstimate,
                dueDay: dueDay,
                cardId: cardId,
                matchPattern: matchPattern,
                amountTolerancePct: amountTolerancePct,
                isEnvelope: isEnvelope,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int amount,
                Value<bool> isEstimate = const Value.absent(),
                required int dueDay,
                Value<int?> cardId = const Value.absent(),
                required String matchPattern,
                Value<int?> amountTolerancePct = const Value.absent(),
                Value<bool> isEnvelope = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => RecurringItemsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                isEstimate: isEstimate,
                dueDay: dueDay,
                cardId: cardId,
                matchPattern: matchPattern,
                amountTolerancePct: amountTolerancePct,
                isEnvelope: isEnvelope,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringItemsTable, RecurringItemRow>(table),
                  $$RecurringItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recurringMatchesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recurringMatchesRefs) db.recurringMatches,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recurringMatchesRefs)
                    await $_getPrefetchedData<
                      RecurringItemRow,
                      $RecurringItemsTable,
                      RecurringMatchRow
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringItemsTableReferences
                          ._recurringMatchesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).recurringMatchesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.recurringItemId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecurringItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringItemsTable,
      RecurringItemRow,
      $$RecurringItemsTableFilterComposer,
      $$RecurringItemsTableOrderingComposer,
      $$RecurringItemsTableAnnotationComposer,
      $$RecurringItemsTableCreateCompanionBuilder,
      $$RecurringItemsTableUpdateCompanionBuilder,
      (RecurringItemRow, $$RecurringItemsTableReferences),
      RecurringItemRow,
      PrefetchHooks Function({bool recurringMatchesRefs})
    >;
typedef $$RecurringMatchesTableCreateCompanionBuilder =
    RecurringMatchesCompanion Function({
      Value<int> id,
      required int recurringItemId,
      required String month,
      Value<int?> transactionId,
      required String status,
      required String decidedOn,
    });
typedef $$RecurringMatchesTableUpdateCompanionBuilder =
    RecurringMatchesCompanion Function({
      Value<int> id,
      Value<int> recurringItemId,
      Value<String> month,
      Value<int?> transactionId,
      Value<String> status,
      Value<String> decidedOn,
    });

final class $$RecurringMatchesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecurringMatchesTable,
          RecurringMatchRow
        > {
  $$RecurringMatchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecurringItemsTable _recurringItemIdTable(_$AppDatabase db) => db
      .recurringItems
      .createAlias('recurring_matches__recurring_item_id__recurring_items__id');

  $$RecurringItemsTableProcessedTableManager get recurringItemId {
    final $_column = $_itemColumn<int>('recurring_item_id')!;

    final manager = $$RecurringItemsTableTableManager(
      $_db,
      $_db.recurringItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurringMatchesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringMatchesTable> {
  $$RecurringMatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decidedOn => $composableBuilder(
    column: $table.decidedOn,
    builder: (column) => ColumnFilters(column),
  );

  $$RecurringItemsTableFilterComposer get recurringItemId {
    final $$RecurringItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringItemId,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableFilterComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringMatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringMatchesTable> {
  $$RecurringMatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decidedOn => $composableBuilder(
    column: $table.decidedOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecurringItemsTableOrderingComposer get recurringItemId {
    final $$RecurringItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringItemId,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableOrderingComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringMatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringMatchesTable> {
  $$RecurringMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get decidedOn =>
      $composableBuilder(column: $table.decidedOn, builder: (column) => column);

  $$RecurringItemsTableAnnotationComposer get recurringItemId {
    final $$RecurringItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringItemId,
      referencedTable: $db.recurringItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringMatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringMatchesTable,
          RecurringMatchRow,
          $$RecurringMatchesTableFilterComposer,
          $$RecurringMatchesTableOrderingComposer,
          $$RecurringMatchesTableAnnotationComposer,
          $$RecurringMatchesTableCreateCompanionBuilder,
          $$RecurringMatchesTableUpdateCompanionBuilder,
          (RecurringMatchRow, $$RecurringMatchesTableReferences),
          RecurringMatchRow,
          PrefetchHooks Function({bool recurringItemId})
        > {
  $$RecurringMatchesTableTableManager(
    _$AppDatabase db,
    $RecurringMatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringMatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringMatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recurringItemId = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<int?> transactionId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> decidedOn = const Value.absent(),
              }) => RecurringMatchesCompanion(
                id: id,
                recurringItemId: recurringItemId,
                month: month,
                transactionId: transactionId,
                status: status,
                decidedOn: decidedOn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recurringItemId,
                required String month,
                Value<int?> transactionId = const Value.absent(),
                required String status,
                required String decidedOn,
              }) => RecurringMatchesCompanion.insert(
                id: id,
                recurringItemId: recurringItemId,
                month: month,
                transactionId: transactionId,
                status: status,
                decidedOn: decidedOn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringMatchesTable, RecurringMatchRow>(table),
                  $$RecurringMatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recurringItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recurringItemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recurringItemId,
                        referencedTable: $$RecurringMatchesTableReferences
                            ._recurringItemIdTable(db),
                        referencedColumn: $$RecurringMatchesTableReferences
                            ._recurringItemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecurringMatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringMatchesTable,
      RecurringMatchRow,
      $$RecurringMatchesTableFilterComposer,
      $$RecurringMatchesTableOrderingComposer,
      $$RecurringMatchesTableAnnotationComposer,
      $$RecurringMatchesTableCreateCompanionBuilder,
      $$RecurringMatchesTableUpdateCompanionBuilder,
      (RecurringMatchRow, $$RecurringMatchesTableReferences),
      RecurringMatchRow,
      PrefetchHooks Function({bool recurringItemId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String month,
  required int amount,
  required String source,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> month,
  Value<int> amount,
  Value<String> source,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          BudgetRow,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (BudgetRow, BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>),
          BudgetRow,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> month = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                month: month,
                amount: amount,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String month,
                required int amount,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                month: month,
                amount: amount,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, BudgetRow>(table),
                  BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      BudgetRow,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (BudgetRow, BaseReferences<_$AppDatabase, $BudgetsTable, BudgetRow>),
      BudgetRow,
      PrefetchHooks Function()
    >;
typedef $$BudgetPlansTableCreateCompanionBuilder =
    BudgetPlansCompanion Function({
      Value<int> id,
      required String mode,
      required String startMonth,
      required int startAmount,
      required int targetAmount,
      required int months,
      Value<DateTime> createdAt,
    });
typedef $$BudgetPlansTableUpdateCompanionBuilder =
    BudgetPlansCompanion Function({
      Value<int> id,
      Value<String> mode,
      Value<String> startMonth,
      Value<int> startAmount,
      Value<int> targetAmount,
      Value<int> months,
      Value<DateTime> createdAt,
    });

class $$BudgetPlansTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetPlansTable> {
  $$BudgetPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAmount => $composableBuilder(
    column: $table.startAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get months => $composableBuilder(
    column: $table.months,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetPlansTable> {
  $$BudgetPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAmount => $composableBuilder(
    column: $table.startAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get months => $composableBuilder(
    column: $table.months,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetPlansTable> {
  $$BudgetPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startAmount => $composableBuilder(
    column: $table.startAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get months =>
      $composableBuilder(column: $table.months, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BudgetPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetPlansTable,
          BudgetPlanRow,
          $$BudgetPlansTableFilterComposer,
          $$BudgetPlansTableOrderingComposer,
          $$BudgetPlansTableAnnotationComposer,
          $$BudgetPlansTableCreateCompanionBuilder,
          $$BudgetPlansTableUpdateCompanionBuilder,
          (
            BudgetPlanRow,
            BaseReferences<_$AppDatabase, $BudgetPlansTable, BudgetPlanRow>,
          ),
          BudgetPlanRow,
          PrefetchHooks Function()
        > {
  $$BudgetPlansTableTableManager(_$AppDatabase db, $BudgetPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> startMonth = const Value.absent(),
                Value<int> startAmount = const Value.absent(),
                Value<int> targetAmount = const Value.absent(),
                Value<int> months = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BudgetPlansCompanion(
                id: id,
                mode: mode,
                startMonth: startMonth,
                startAmount: startAmount,
                targetAmount: targetAmount,
                months: months,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mode,
                required String startMonth,
                required int startAmount,
                required int targetAmount,
                required int months,
                Value<DateTime> createdAt = const Value.absent(),
              }) => BudgetPlansCompanion.insert(
                id: id,
                mode: mode,
                startMonth: startMonth,
                startAmount: startAmount,
                targetAmount: targetAmount,
                months: months,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetPlansTable, BudgetPlanRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BudgetPlansTable,
                    BudgetPlanRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetPlansTable,
      BudgetPlanRow,
      $$BudgetPlansTableFilterComposer,
      $$BudgetPlansTableOrderingComposer,
      $$BudgetPlansTableAnnotationComposer,
      $$BudgetPlansTableCreateCompanionBuilder,
      $$BudgetPlansTableUpdateCompanionBuilder,
      (
        BudgetPlanRow,
        BaseReferences<_$AppDatabase, $BudgetPlansTable, BudgetPlanRow>,
      ),
      BudgetPlanRow,
      PrefetchHooks Function()
    >;
typedef $$MerchantRulesTableCreateCompanionBuilder =
    MerchantRulesCompanion Function({
      required String merchantNorm,
      required int categoryId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MerchantRulesTableUpdateCompanionBuilder =
    MerchantRulesCompanion Function({
      Value<String> merchantNorm,
      Value<int> categoryId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MerchantRulesTableReferences
    extends
        BaseReferences<_$AppDatabase, $MerchantRulesTable, MerchantRuleRow> {
  $$MerchantRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('merchant_rules__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MerchantRulesTableFilterComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get merchantNorm => $composableBuilder(
    column: $table.merchantNorm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get merchantNorm => $composableBuilder(
    column: $table.merchantNorm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get merchantNorm => $composableBuilder(
    column: $table.merchantNorm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MerchantRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MerchantRulesTable,
          MerchantRuleRow,
          $$MerchantRulesTableFilterComposer,
          $$MerchantRulesTableOrderingComposer,
          $$MerchantRulesTableAnnotationComposer,
          $$MerchantRulesTableCreateCompanionBuilder,
          $$MerchantRulesTableUpdateCompanionBuilder,
          (MerchantRuleRow, $$MerchantRulesTableReferences),
          MerchantRuleRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$MerchantRulesTableTableManager(_$AppDatabase db, $MerchantRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MerchantRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MerchantRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> merchantNorm = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MerchantRulesCompanion(
                merchantNorm: merchantNorm,
                categoryId: categoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String merchantNorm,
                required int categoryId,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MerchantRulesCompanion.insert(
                merchantNorm: merchantNorm,
                categoryId: categoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MerchantRulesTable, MerchantRuleRow>(table),
                  $$MerchantRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$MerchantRulesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$MerchantRulesTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MerchantRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MerchantRulesTable,
      MerchantRuleRow,
      $$MerchantRulesTableFilterComposer,
      $$MerchantRulesTableOrderingComposer,
      $$MerchantRulesTableAnnotationComposer,
      $$MerchantRulesTableCreateCompanionBuilder,
      $$MerchantRulesTableUpdateCompanionBuilder,
      (MerchantRuleRow, $$MerchantRulesTableReferences),
      MerchantRuleRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationLogsTableCreateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      required String type,
      required DateTime sentAt,
      required String localDate,
      Value<String?> summary,
    });
typedef $$NotificationLogsTableUpdateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<DateTime> sentAt,
      Value<String> localDate,
      Value<String?> summary,
    });

class $$NotificationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$NotificationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationLogsTable,
          NotificationLogRow,
          $$NotificationLogsTableFilterComposer,
          $$NotificationLogsTableOrderingComposer,
          $$NotificationLogsTableAnnotationComposer,
          $$NotificationLogsTableCreateCompanionBuilder,
          $$NotificationLogsTableUpdateCompanionBuilder,
          (
            NotificationLogRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationLogsTable,
              NotificationLogRow
            >,
          ),
          NotificationLogRow,
          PrefetchHooks Function()
        > {
  $$NotificationLogsTableTableManager(
    _$AppDatabase db,
    $NotificationLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String?> summary = const Value.absent(),
              }) => NotificationLogsCompanion(
                id: id,
                type: type,
                sentAt: sentAt,
                localDate: localDate,
                summary: summary,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required DateTime sentAt,
                required String localDate,
                Value<String?> summary = const Value.absent(),
              }) => NotificationLogsCompanion.insert(
                id: id,
                type: type,
                sentAt: sentAt,
                localDate: localDate,
                summary: summary,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotificationLogsTable, NotificationLogRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationLogsTable,
                    NotificationLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationLogsTable,
      NotificationLogRow,
      $$NotificationLogsTableFilterComposer,
      $$NotificationLogsTableOrderingComposer,
      $$NotificationLogsTableAnnotationComposer,
      $$NotificationLogsTableCreateCompanionBuilder,
      $$NotificationLogsTableUpdateCompanionBuilder,
      (
        NotificationLogRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationLogsTable,
          NotificationLogRow
        >,
      ),
      NotificationLogRow,
      PrefetchHooks Function()
    >;
typedef $$MetricEventsTableCreateCompanionBuilder =
    MetricEventsCompanion Function({
      Value<int> id,
      required String type,
      required DateTime at,
      required String data,
    });
typedef $$MetricEventsTableUpdateCompanionBuilder =
    MetricEventsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<DateTime> at,
      Value<String> data,
    });

class $$MetricEventsTableFilterComposer
    extends Composer<_$AppDatabase, $MetricEventsTable> {
  $$MetricEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $MetricEventsTable> {
  $$MetricEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetricEventsTable> {
  $$MetricEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$MetricEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetricEventsTable,
          MetricEventRow,
          $$MetricEventsTableFilterComposer,
          $$MetricEventsTableOrderingComposer,
          $$MetricEventsTableAnnotationComposer,
          $$MetricEventsTableCreateCompanionBuilder,
          $$MetricEventsTableUpdateCompanionBuilder,
          (
            MetricEventRow,
            BaseReferences<_$AppDatabase, $MetricEventsTable, MetricEventRow>,
          ),
          MetricEventRow,
          PrefetchHooks Function()
        > {
  $$MetricEventsTableTableManager(_$AppDatabase db, $MetricEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> data = const Value.absent(),
          }) => MetricEventsCompanion(id: id, type: type, at: at, data: data),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required DateTime at,
                required String data,
              }) => MetricEventsCompanion.insert(
                id: id,
                type: type,
                at: at,
                data: data,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MetricEventsTable, MetricEventRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MetricEventsTable,
                    MetricEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetricEventsTable,
      MetricEventRow,
      $$MetricEventsTableFilterComposer,
      $$MetricEventsTableOrderingComposer,
      $$MetricEventsTableAnnotationComposer,
      $$MetricEventsTableCreateCompanionBuilder,
      $$MetricEventsTableUpdateCompanionBuilder,
      (
        MetricEventRow,
        BaseReferences<_$AppDatabase, $MetricEventsTable, MetricEventRow>,
      ),
      MetricEventRow,
      PrefetchHooks Function()
    >;
typedef $$PlannedExpensesTableCreateCompanionBuilder =
    PlannedExpensesCompanion Function({
      Value<int> id,
      required String name,
      required int amount,
      required String date,
      Value<String?> doneOn,
      Value<int?> transactionId,
      Value<String> source,
      Value<DateTime> createdAt,
    });
typedef $$PlannedExpensesTableUpdateCompanionBuilder =
    PlannedExpensesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> amount,
      Value<String> date,
      Value<String?> doneOn,
      Value<int?> transactionId,
      Value<String> source,
      Value<DateTime> createdAt,
    });

class $$PlannedExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedExpensesTable> {
  $$PlannedExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doneOn => $composableBuilder(
    column: $table.doneOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannedExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedExpensesTable> {
  $$PlannedExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneOn => $composableBuilder(
    column: $table.doneOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannedExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedExpensesTable> {
  $$PlannedExpensesTableAnnotationComposer({
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

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get doneOn =>
      $composableBuilder(column: $table.doneOn, builder: (column) => column);

  GeneratedColumn<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlannedExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedExpensesTable,
          PlannedExpenseRow,
          $$PlannedExpensesTableFilterComposer,
          $$PlannedExpensesTableOrderingComposer,
          $$PlannedExpensesTableAnnotationComposer,
          $$PlannedExpensesTableCreateCompanionBuilder,
          $$PlannedExpensesTableUpdateCompanionBuilder,
          (
            PlannedExpenseRow,
            BaseReferences<
              _$AppDatabase,
              $PlannedExpensesTable,
              PlannedExpenseRow
            >,
          ),
          PlannedExpenseRow,
          PrefetchHooks Function()
        > {
  $$PlannedExpensesTableTableManager(
    _$AppDatabase db,
    $PlannedExpensesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> doneOn = const Value.absent(),
                Value<int?> transactionId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlannedExpensesCompanion(
                id: id,
                name: name,
                amount: amount,
                date: date,
                doneOn: doneOn,
                transactionId: transactionId,
                source: source,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int amount,
                required String date,
                Value<String?> doneOn = const Value.absent(),
                Value<int?> transactionId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlannedExpensesCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                date: date,
                doneOn: doneOn,
                transactionId: transactionId,
                source: source,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlannedExpensesTable, PlannedExpenseRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlannedExpensesTable,
                    PlannedExpenseRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannedExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedExpensesTable,
      PlannedExpenseRow,
      $$PlannedExpensesTableFilterComposer,
      $$PlannedExpensesTableOrderingComposer,
      $$PlannedExpensesTableAnnotationComposer,
      $$PlannedExpensesTableCreateCompanionBuilder,
      $$PlannedExpensesTableUpdateCompanionBuilder,
      (
        PlannedExpenseRow,
        BaseReferences<_$AppDatabase, $PlannedExpensesTable, PlannedExpenseRow>,
      ),
      PlannedExpenseRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$InstallmentSchedulesTableTableManager get installmentSchedules =>
      $$InstallmentSchedulesTableTableManager(_db, _db.installmentSchedules);
  $$RecurringItemsTableTableManager get recurringItems =>
      $$RecurringItemsTableTableManager(_db, _db.recurringItems);
  $$RecurringMatchesTableTableManager get recurringMatches =>
      $$RecurringMatchesTableTableManager(_db, _db.recurringMatches);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$BudgetPlansTableTableManager get budgetPlans =>
      $$BudgetPlansTableTableManager(_db, _db.budgetPlans);
  $$MerchantRulesTableTableManager get merchantRules =>
      $$MerchantRulesTableTableManager(_db, _db.merchantRules);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$NotificationLogsTableTableManager get notificationLogs =>
      $$NotificationLogsTableTableManager(_db, _db.notificationLogs);
  $$MetricEventsTableTableManager get metricEvents =>
      $$MetricEventsTableTableManager(_db, _db.metricEvents);
  $$PlannedExpensesTableTableManager get plannedExpenses =>
      $$PlannedExpensesTableTableManager(_db, _db.plannedExpenses);
}
