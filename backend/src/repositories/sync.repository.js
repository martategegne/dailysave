import { query, withTransaction } from '../config/database.js';

export const syncRepository = {
  /**
   * Applies a batch of client mutations inside a database transaction with idempotency and conflict resolution.
   */
  async processPushBatch(userId, mutations) {
    return withTransaction(async (client) => {
      const results = [];
      const serverTimestamp = new Date();

      for (const mut of mutations) {
        const {
          clientMutationId,
          entityType,
          entityId,
          operationType,
          clientTimestamp,
          payload,
        } = mut;

        // 1. Idempotency Check: if mutation was already processed, return previous status
        const existingOpRes = await client.query(
          `SELECT client_mutation_id, status FROM sync_operations WHERE user_id = $1 AND client_mutation_id = $2;`,
          [userId, clientMutationId]
        );

        if (existingOpRes.rows[0]) {
          results.push({
            clientMutationId,
            status: existingOpRes.rows[0].status,
            entityId,
            note: 'Already processed (idempotent duplicate)',
          });
          continue;
        }

        const cTime = new Date(clientTimestamp || Date.now());

        // 2. Process Entity
        let status = 'applied';
        let conflictDetails = null;

        try {
          if (entityType === 'transaction') {
            if (operationType === 'delete') {
              await client.query(
                `UPDATE transactions 
                 SET deleted_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP 
                 WHERE user_id = $1 AND id = $2;`,
                [userId, entityId]
              );
            } else {
              // Insert or Update transaction
              await client.query(
                `
                INSERT INTO transactions (
                  id, user_id, amount_cents, type, currency, category,
                  description, date, payment_method, account, notes,
                  receipt_path, sync_status, created_at, updated_at
                )
                VALUES (
                  $1, $2, $3, $4, $5, $6,
                  $7, $8, $9, $10, $11,
                  $12, 'synced', $13, CURRENT_TIMESTAMP
                )
                ON CONFLICT (id) DO UPDATE
                SET 
                  amount_cents = EXCLUDED.amount_cents,
                  type = EXCLUDED.type,
                  category = EXCLUDED.category,
                  description = EXCLUDED.description,
                  date = EXCLUDED.date,
                  payment_method = EXCLUDED.payment_method,
                  account = EXCLUDED.account,
                  notes = EXCLUDED.notes,
                  receipt_path = EXCLUDED.receipt_path,
                  sync_status = 'synced',
                  updated_at = CURRENT_TIMESTAMP
                WHERE transactions.user_id = $2 AND transactions.updated_at <= $14;
                `,
                [
                  entityId,
                  userId,
                  payload.amountCents || payload.amount_cents,
                  payload.type,
                  payload.currency || 'ETB',
                  payload.category,
                  payload.description || '',
                  new Date(payload.date || Date.now()),
                  payload.paymentMethod || payload.payment_method || 'Cash',
                  payload.account || 'Cash Wallet',
                  payload.notes || '',
                  payload.receiptPath || payload.receipt_path || null,
                  cTime,
                  cTime,
                ]
              );
            }
          } else if (entityType === 'budget') {
            if (operationType === 'delete') {
              await client.query(
                `DELETE FROM budgets WHERE user_id = $1 AND id = $2;`,
                [userId, entityId]
              );
            } else {
              await client.query(
                `
                INSERT INTO budgets (
                  id, user_id, name, amount_cents, period, category,
                  start_date, end_date, warning_threshold_percent,
                  danger_threshold_percent, critical_threshold_percent, updated_at
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, CURRENT_TIMESTAMP)
                ON CONFLICT (id) DO UPDATE
                SET 
                  name = EXCLUDED.name,
                  amount_cents = EXCLUDED.amount_cents,
                  period = EXCLUDED.period,
                  category = EXCLUDED.category,
                  start_date = EXCLUDED.start_date,
                  end_date = EXCLUDED.end_date,
                  warning_threshold_percent = EXCLUDED.warning_threshold_percent,
                  danger_threshold_percent = EXCLUDED.danger_threshold_percent,
                  critical_threshold_percent = EXCLUDED.critical_threshold_percent,
                  updated_at = CURRENT_TIMESTAMP
                WHERE budgets.user_id = $2 AND budgets.updated_at <= $12;
                `,
                [
                  entityId,
                  userId,
                  payload.name,
                  payload.amountCents || payload.amount_cents,
                  payload.period || 'monthly',
                  payload.category || null,
                  new Date(payload.startDate || payload.start_date),
                  payload.endDate || payload.end_date ? new Date(payload.endDate || payload.end_date) : null,
                  payload.warningThresholdPercent || 75,
                  payload.dangerThresholdPercent || 90,
                  payload.criticalThresholdPercent || 100,
                  cTime,
                ]
              );
            }
          } else if (entityType === 'goal') {
            if (operationType === 'delete') {
              await client.query(
                `DELETE FROM savings_goals WHERE user_id = $1 AND id = $2;`,
                [userId, entityId]
              );
            } else {
              await client.query(
                `
                INSERT INTO savings_goals (
                  id, user_id, name, target_amount_cents, current_amount_cents,
                  currency, deadline, description, is_completed, updated_at
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP)
                ON CONFLICT (id) DO UPDATE
                SET 
                  name = EXCLUDED.name,
                  target_amount_cents = EXCLUDED.target_amount_cents,
                  current_amount_cents = EXCLUDED.current_amount_cents,
                  currency = EXCLUDED.currency,
                  deadline = EXCLUDED.deadline,
                  description = EXCLUDED.description,
                  is_completed = EXCLUDED.is_completed,
                  updated_at = CURRENT_TIMESTAMP
                WHERE savings_goals.user_id = $2 AND savings_goals.updated_at <= $10;
                `,
                [
                  entityId,
                  userId,
                  payload.name,
                  payload.targetAmountCents || payload.target_amount_cents,
                  payload.currentAmountCents || payload.current_amount_cents || 0,
                  payload.currency || 'ETB',
                  new Date(payload.deadline),
                  payload.description || '',
                  Boolean(payload.isCompleted || payload.is_completed),
                  cTime,
                ]
              );
            }
          } else if (entityType === 'debt') {
            if (operationType === 'delete') {
              await client.query(
                `DELETE FROM debts WHERE user_id = $1 AND id = $2;`,
                [userId, entityId]
              );
            } else {
              await client.query(
                `
                INSERT INTO debts (
                  id, user_id, person_name, debt_type, initial_amount_cents,
                  remaining_amount_cents, currency, due_date, description,
                  is_settled, updated_at
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)
                ON CONFLICT (id) DO UPDATE
                SET
                  person_name = EXCLUDED.person_name,
                  debt_type = EXCLUDED.debt_type,
                  initial_amount_cents = EXCLUDED.initial_amount_cents,
                  remaining_amount_cents = EXCLUDED.remaining_amount_cents,
                  currency = EXCLUDED.currency,
                  due_date = EXCLUDED.due_date,
                  description = EXCLUDED.description,
                  is_settled = EXCLUDED.is_settled,
                  updated_at = CURRENT_TIMESTAMP
                WHERE debts.user_id = $2 AND debts.updated_at <= $11;
                `,
                [
                  entityId,
                  userId,
                  payload.personName || payload.person_name,
                  payload.debtType || payload.debt_type,
                  payload.initialAmountCents || payload.initial_amount_cents,
                  payload.remainingAmountCents || payload.remaining_amount_cents,
                  payload.currency || 'ETB',
                  payload.dueDate || payload.due_date ? new Date(payload.dueDate || payload.due_date) : null,
                  payload.description || '',
                  Boolean(payload.isSettled || payload.is_settled),
                  cTime,
                ]
              );
            }
          } else if (entityType === 'account') {
            if (operationType === 'delete') {
              await client.query(
                `DELETE FROM accounts WHERE user_id = $1 AND id = $2;`,
                [userId, entityId]
              );
            } else {
              await client.query(
                `
                INSERT INTO accounts (
                  id, user_id, name, account_type, currency, initial_balance_cents, updated_at
                )
                VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
                ON CONFLICT (id) DO UPDATE
                SET
                  name = EXCLUDED.name,
                  account_type = EXCLUDED.account_type,
                  currency = EXCLUDED.currency,
                  initial_balance_cents = EXCLUDED.initial_balance_cents,
                  updated_at = CURRENT_TIMESTAMP
                WHERE accounts.user_id = $2 AND accounts.updated_at <= $7;
                `,
                [
                  entityId,
                  userId,
                  payload.name,
                  payload.accountType || payload.account_type,
                  payload.currency || 'ETB',
                  payload.initialBalanceCents || payload.initial_balance_cents || 0,
                  cTime,
                ]
              );
            }
          }

          // 3. Record operation into sync_operations log table
          await client.query(
            `
            INSERT INTO sync_operations (
              user_id, client_mutation_id, entity_type, entity_id,
              operation_type, client_timestamp, server_timestamp, status, conflict_resolution_json
            )
            VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, $7, $8);
            `,
            [
              userId,
              clientMutationId,
              entityType,
              entityId,
              operationType,
              cTime,
              status,
              conflictDetails ? JSON.stringify(conflictDetails) : null,
            ]
          );

          results.push({
            clientMutationId,
            status,
            entityId,
          });
        } catch (err) {
          console.error(`Sync error on mutation ${clientMutationId}:`, err);
          results.push({
            clientMutationId,
            status: 'rejected',
            entityId,
            error: err.message,
          });
        }
      }

      return {
        results,
        serverSyncTimestamp: serverTimestamp.toISOString(),
      };
    });
  },

  /**
   * Retrieves all records modified or deleted since a given timestamp.
   */
  async pullChanges(userId, sinceTimestamp) {
    const sinceDate = sinceTimestamp ? new Date(sinceTimestamp) : new Date(0);
    const serverSyncTimestamp = new Date().toISOString();

    const [transactionsRes, budgetsRes, goalsRes, debtsRes, accountsRes] =
      await Promise.all([
        query(
          `SELECT * FROM transactions WHERE user_id = $1 AND updated_at > $2 ORDER BY updated_at ASC;`,
          [userId, sinceDate]
        ),
        query(
          `SELECT * FROM budgets WHERE user_id = $1 AND updated_at > $2 ORDER BY updated_at ASC;`,
          [userId, sinceDate]
        ),
        query(
          `SELECT * FROM savings_goals WHERE user_id = $1 AND updated_at > $2 ORDER BY updated_at ASC;`,
          [userId, sinceDate]
        ),
        query(
          `SELECT * FROM debts WHERE user_id = $1 AND updated_at > $2 ORDER BY updated_at ASC;`,
          [userId, sinceDate]
        ),
        query(
          `SELECT * FROM accounts WHERE user_id = $1 AND updated_at > $2 ORDER BY updated_at ASC;`,
          [userId, sinceDate]
        ),
      ]);

    return {
      serverSyncTimestamp,
      changes: {
        transactions: transactionsRes.rows,
        budgets: budgetsRes.rows,
        goals: goalsRes.rows,
        debts: debtsRes.rows,
        accounts: accountsRes.rows,
      },
    };
  },
};
