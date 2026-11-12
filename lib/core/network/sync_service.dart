import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'api_client.dart';

class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final String? errorMessage;

  SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.errorMessage,
  });
}

class SyncService {
  final ApiClient apiClient;
  final _uuid = const Uuid();

  SyncService({required this.apiClient});

  /// Pushes local entities to the remote PostgreSQL database.
  Future<int> pushChanges(AppDatabase db) async {
    final transactions = await db.select(db.transactionsTable).get();
    if (transactions.isEmpty) return 0;

    final mutations = <Map<String, dynamic>>[];

    for (final tx in transactions) {
      mutations.add({
        'clientMutationId': _uuid.v4(),
        'entityType': 'transaction',
        'entityId': tx.id,
        'operationType': 'insert',
        'clientTimestamp': tx.updatedAt.toIso8601String(),
        'payload': {
          'amountCents': tx.amountInCents,
          'type': tx.type,
          'currency': tx.currency,
          'category': tx.category,
          'description': tx.description,
          'date': tx.date.toIso8601String(),
          'paymentMethod': tx.paymentMethod,
          'account': tx.account,
          'notes': tx.notes,
          'receiptPath': tx.receiptPath,
        },
      });
    }

    final response = await apiClient.post('/sync/push', body: {
      'mutations': mutations,
    });

    final results = response['results'] as List<dynamic>? ?? [];
    return results.where((r) => r['status'] == 'applied').length;
  }

  /// Pulls delta changes from the server committed after the last sync timestamp.
  Future<int> pullChanges(AppDatabase db) async {
    // 1. Get last sync timestamp from user preferences
    final prefRow = await (db.select(db.userPreferencesTable)
          ..where((tbl) => tbl.key.equals('last_sync_timestamp')))
        .getSingleOrNull();

    final since = prefRow?.value;
    final queryParams = since != null ? {'since': since} : null;

    final response = await apiClient.get('/sync/pull', queryParams: queryParams);

    final changes = response['changes'] as Map<String, dynamic>? ?? {};
    final serverSyncTimestamp = response['serverSyncTimestamp'] as String?;

    int totalUpdated = 0;

    // 2. Sync transactions
    final serverTransactions = changes['transactions'] as List<dynamic>? ?? [];
    for (final t in serverTransactions) {
      final id = t['id'] as String;
      final isDeleted = t['deleted_at'] != null;

      if (isDeleted) {
        await (db.delete(db.transactionsTable)..where((tbl) => tbl.id.equals(id))).go();
      } else {
        await db.into(db.transactionsTable).insertOnConflictUpdate(
              TransactionsTableCompanion.insert(
                id: id,
                amountInCents: int.parse(t['amount_cents'].toString()),
                type: t['type'] as String,
                currency: Value(t['currency'] as String? ?? 'ETB'),
                category: t['category'] as String,
                description: t['description'] as String? ?? '',
                date: DateTime.parse(t['date'] as String),
                paymentMethod: Value(t['payment_method'] as String? ?? 'Cash'),
                account: Value(t['account'] as String? ?? 'Cash Wallet'),
                notes: Value(t['notes'] as String? ?? ''),
                receiptPath: Value(t['receipt_path'] as String?),
                createdAt: DateTime.parse(t['created_at'] as String),
                updatedAt: DateTime.parse(t['updated_at'] as String),
              ),
            );
      }
      totalUpdated++;
    }

    // 3. Save new sync timestamp locally
    if (serverSyncTimestamp != null) {
      await db.into(db.userPreferencesTable).insertOnConflictUpdate(
            UserPreferencesTableCompanion.insert(
              key: 'last_sync_timestamp',
              value: serverSyncTimestamp,
            ),
          );
    }

    return totalUpdated;
  }

  /// Executes full two-way synchronization: Push offline changes then pull cloud delta.
  Future<SyncResult> syncAll(AppDatabase db) async {
    try {
      final pushed = await pushChanges(db);
      final pulled = await pullChanges(db);
      return SyncResult(
        success: true,
        pushedCount: pushed,
        pulledCount: pulled,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}
