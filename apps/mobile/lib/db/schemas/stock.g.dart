// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStockCollection on Isar {
  IsarCollection<Stock> get stocks => this.collection();
}

const StockSchema = CollectionSchema(
  name: r'Stock',
  id: 6740185341894042082,
  properties: {
    r'batchCode': PropertySchema(
      id: 0,
      name: r'batchCode',
      type: IsarType.string,
    ),
    r'expirationDate': PropertySchema(
      id: 1,
      name: r'expirationDate',
      type: IsarType.dateTime,
    ),
    r'price': PropertySchema(
      id: 2,
      name: r'price',
      type: IsarType.double,
    ),
    r'productId': PropertySchema(
      id: 3,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 4,
      name: r'productName',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 5,
      name: r'quantity',
      type: IsarType.double,
    )
  },
  estimateSize: _stockEstimateSize,
  serialize: _stockSerialize,
  deserialize: _stockDeserialize,
  deserializeProp: _stockDeserializeProp,
  idName: r'id',
  indexes: {
    r'productId': IndexSchema(
      id: 5580769080710688203,
      name: r'productId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'productId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _stockGetId,
  getLinks: _stockGetLinks,
  attach: _stockAttach,
  version: '3.1.0+1',
);

int _stockEstimateSize(
  Stock object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.batchCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.productId.length * 3;
  bytesCount += 3 + object.productName.length * 3;
  return bytesCount;
}

void _stockSerialize(
  Stock object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.batchCode);
  writer.writeDateTime(offsets[1], object.expirationDate);
  writer.writeDouble(offsets[2], object.price);
  writer.writeString(offsets[3], object.productId);
  writer.writeString(offsets[4], object.productName);
  writer.writeDouble(offsets[5], object.quantity);
}

Stock _stockDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Stock();
  object.batchCode = reader.readStringOrNull(offsets[0]);
  object.expirationDate = reader.readDateTimeOrNull(offsets[1]);
  object.id = id;
  object.price = reader.readDouble(offsets[2]);
  object.productId = reader.readString(offsets[3]);
  object.productName = reader.readString(offsets[4]);
  object.quantity = reader.readDouble(offsets[5]);
  return object;
}

P _stockDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _stockGetId(Stock object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _stockGetLinks(Stock object) {
  return [];
}

void _stockAttach(IsarCollection<dynamic> col, Id id, Stock object) {
  object.id = id;
}

extension StockQueryWhereSort on QueryBuilder<Stock, Stock, QWhere> {
  QueryBuilder<Stock, Stock, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StockQueryWhere on QueryBuilder<Stock, Stock, QWhereClause> {
  QueryBuilder<Stock, Stock, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Stock, Stock, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Stock, Stock, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Stock, Stock, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterWhereClause> productIdEqualTo(
      String productId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'productId',
        value: [productId],
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterWhereClause> productIdNotEqualTo(
      String productId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [],
              upper: [productId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [productId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [productId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [],
              upper: [productId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension StockQueryFilter on QueryBuilder<Stock, Stock, QFilterCondition> {
  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'batchCode',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'batchCode',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'batchCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'batchCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'batchCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'batchCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'batchCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'batchCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'batchCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'batchCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> batchCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'batchCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> expirationDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expirationDate',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> expirationDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expirationDate',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> expirationDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expirationDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> expirationDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expirationDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> expirationDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expirationDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> expirationDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expirationDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> quantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> quantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> quantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Stock, Stock, QAfterFilterCondition> quantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension StockQueryObject on QueryBuilder<Stock, Stock, QFilterCondition> {}

extension StockQueryLinks on QueryBuilder<Stock, Stock, QFilterCondition> {}

extension StockQuerySortBy on QueryBuilder<Stock, Stock, QSortBy> {
  QueryBuilder<Stock, Stock, QAfterSortBy> sortByBatchCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchCode', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByBatchCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchCode', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByExpirationDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expirationDate', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByExpirationDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expirationDate', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }
}

extension StockQuerySortThenBy on QueryBuilder<Stock, Stock, QSortThenBy> {
  QueryBuilder<Stock, Stock, QAfterSortBy> thenByBatchCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchCode', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByBatchCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchCode', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByExpirationDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expirationDate', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByExpirationDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expirationDate', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<Stock, Stock, QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }
}

extension StockQueryWhereDistinct on QueryBuilder<Stock, Stock, QDistinct> {
  QueryBuilder<Stock, Stock, QDistinct> distinctByBatchCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Stock, Stock, QDistinct> distinctByExpirationDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expirationDate');
    });
  }

  QueryBuilder<Stock, Stock, QDistinct> distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<Stock, Stock, QDistinct> distinctByProductId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Stock, Stock, QDistinct> distinctByProductName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Stock, Stock, QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }
}

extension StockQueryProperty on QueryBuilder<Stock, Stock, QQueryProperty> {
  QueryBuilder<Stock, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Stock, String?, QQueryOperations> batchCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchCode');
    });
  }

  QueryBuilder<Stock, DateTime?, QQueryOperations> expirationDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expirationDate');
    });
  }

  QueryBuilder<Stock, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<Stock, String, QQueryOperations> productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<Stock, String, QQueryOperations> productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<Stock, double, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }
}
