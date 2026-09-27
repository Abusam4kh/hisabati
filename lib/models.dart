class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String note;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'note': note,
        'created_at': createdAt,
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as int?,
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        note: (m['note'] ?? '') as String,
        createdAt: (m['created_at'] ?? '') as String,
      );
}

enum EntryType { credit, debit }

extension EntryTypeX on EntryType {
  String get dbValue => this == EntryType.credit ? 'credit' : 'debit';
  String get label => this == EntryType.credit ? 'له' : 'عليه';

  static EntryType fromDb(String value) =>
      value == 'credit' ? EntryType.credit : EntryType.debit;
}

class Entry {
  final int? id;
  final int customerId;
  final EntryType type;
  final double amount;
  final String currency;
  final String description;
  final String date;

  const Entry({
    this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'type': type.dbValue,
        'amount': amount,
        'currency': currency,
        'description': description,
        'date': date,
      };

  factory Entry.fromMap(Map<String, dynamic> m) => Entry(
        id: m['id'] as int?,
        customerId: m['customer_id'] as int,
        type: EntryTypeX.fromDb(m['type'] as String),
        amount: (m['amount'] as num).toDouble(),
        currency: (m['currency'] ?? 'YER') as String,
        description: (m['description'] ?? '') as String,
        date: (m['date'] ?? '') as String,
      );
}
