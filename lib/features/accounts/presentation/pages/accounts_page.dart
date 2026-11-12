import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/money_parser.dart';

class AccountsPage extends StatefulWidget {
  final AppDatabase db;

  const AccountsPage({super.key, required this.db});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Currencies (ሂሳቦች)'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Account'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency Exchange Rate Card
            Card(
              elevation: 0,
              color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Foreign Exchange Reference',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BASE: ETB (ብር)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'All accounts and authoritative books are settled in Ethiopian Birr (ETB). Exchange rates track historical purchasing power with effective dates.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<List<ExchangeRatesTableData>>(
                      stream: widget.db.select(widget.db.exchangeRatesTable).watch(),
                      builder: (context, snapshot) {
                        final rates = snapshot.data ?? [];
                        if (rates.isEmpty) {
                          return const Text('No foreign exchange rates defined.');
                        }
                        return Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: rates.map((r) {
                            return Chip(
                              avatar: const Icon(Icons.currency_exchange, size: 16),
                              label: Text(
                                '1 ${r.fromCurrency} = ${r.rate.toStringAsFixed(2)} ${r.toCurrency}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Your Payment Accounts & Wallets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<AccountsTableData>>(
              stream: widget.db.select(widget.db.accountsTable).watch(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final accounts = snapshot.data ?? [];

                if (accounts.isEmpty) {
                  return const Center(child: Text('No accounts registered yet.'));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    IconData icon;
                    switch (acc.accountType) {
                      case 'cash':
                        icon = Icons.payments_outlined;
                        break;
                      case 'mobile_money':
                        icon = Icons.phone_android_outlined;
                        break;
                      case 'bank':
                        icon = Icons.account_balance_outlined;
                        break;
                      case 'savings':
                        icon = Icons.savings_outlined;
                        break;
                      default:
                        icon = Icons.account_balance_wallet_outlined;
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                          child: Icon(icon, color: AppColors.primaryGreen),
                        ),
                        title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${acc.accountType.toUpperCase()} &bull; ${acc.currency}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: Text(
                          '${(acc.initialBalanceCents / 100).toStringAsFixed(2)} ${acc.currency}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0.00');
    String type = 'cash';
    String currency = 'ETB';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Account / Wallet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name *',
                        hintText: 'e.g. Awash Bank, Commercial Bank, Cash',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Account Type'),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash Wallet')),
                        DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money (Telebirr, etc.)')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                        DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
                        DropdownMenuItem(value: 'custom', child: Text('Custom Account')),
                      ],
                      onChanged: (val) => setDialogState(() => type = val ?? type),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Initial Balance (ETB)',
                        hintText: '0.00',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final cents = parseEtbToMinorUnits(balanceController.text.trim()) ?? 0;

                    await widget.db.into(widget.db.accountsTable).insert(
                          AccountsTableCompanion.insert(
                            id: const Uuid().v4(),
                            name: nameController.text.trim(),
                            accountType: type,
                            initialBalanceCents: drift.Value(cents),
                            currency: drift.Value(currency),
                            isArchived: const drift.Value(false),
                          ),
                        );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
