import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/financial_transaction.dart';

class FinancialTransactionModel extends FinancialTransaction {
  const FinancialTransactionModel({
    required super.id,
    required super.amountInCents,
    required super.type,
    super.currency = 'ETB',
    required super.category,
    required super.description,
    required super.date,
    super.paymentMethod = 'Cash',
    super.account = 'Cash Wallet',
    super.notes = '',
    super.receiptPath,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FinancialTransactionModel.fromEntity(FinancialTransaction entity) {
    return FinancialTransactionModel(
      id: entity.id,
      amountInCents: entity.amountInCents,
      type: entity.type,
      currency: entity.currency,
      category: entity.category,
      description: entity.description,
      date: entity.date,
      paymentMethod: entity.paymentMethod,
      account: entity.account,
      notes: entity.notes,
      receiptPath: entity.receiptPath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory FinancialTransactionModel.fromDrift(TransactionsTableData data) {
    return FinancialTransactionModel(
      id: data.id,
      amountInCents: data.amountInCents,
      type: TransactionType.fromString(data.type),
      currency: data.currency,
      category: data.category,
      description: data.description,
      date: data.date,
      paymentMethod: data.paymentMethod,
      account: data.account,
      notes: data.notes,
      receiptPath: data.receiptPath,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  TransactionsTableCompanion toCompanion() {
    return TransactionsTableCompanion.insert(
      id: id,
      amountInCents: amountInCents,
      type: type.name,
      currency: Value(currency),
      category: category,
      description: description,
      date: date,
      paymentMethod: Value(paymentMethod),
      account: Value(account),
      notes: Value(notes),
      receiptPath: Value(receiptPath),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
