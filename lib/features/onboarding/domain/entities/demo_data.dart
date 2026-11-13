/// Fictional Demo Datasets for Safe User Exploration.
/// Conforms strictly to privacy guidelines: zero real financial records.
library;

class DemoDataProfile {
  final String title;
  final String description;
  final int initialBalanceCents;
  final List<DemoTransaction> transactions;

  const DemoDataProfile({
    required this.title,
    required this.description,
    required this.initialBalanceCents,
    required this.transactions,
  });
}

class DemoTransaction {
  final String description;
  final int amountCents;
  final String type; // 'income', 'expense'
  final String category;
  final String account;

  const DemoTransaction({
    required this.description,
    required this.amountCents,
    required this.type,
    required this.category,
    required this.account,
  });
}

class DemoDatasets {
  static const studentProfile = DemoDataProfile(
    title: 'University Student (Addis Ababa)',
    description: 'Monthly student stipend with dormitory, books, and cafeteria tracking.',
    initialBalanceCents: 350000, // 3,500.00 ETB
    transactions: [
      DemoTransaction(
        description: 'Monthly Family Allowance',
        amountCents: 300000,
        type: 'income',
        category: 'Allowance',
        account: 'Telebirr',
      ),
      DemoTransaction(
        description: 'Campus Cafeteria & Meals',
        amountCents: 45000,
        type: 'expense',
        category: 'Food',
        account: 'Cash Wallet',
      ),
      DemoTransaction(
        description: 'Semester Lecture Notes Photocopying',
        amountCents: 15000,
        type: 'expense',
        category: 'Education',
        account: 'Cash Wallet',
      ),
      DemoTransaction(
        description: 'Mobile Internet Data Package',
        amountCents: 20000,
        type: 'expense',
        category: 'Utilities',
        account: 'Telebirr',
      ),
    ],
  );

  static const familyProfile = DemoDataProfile(
    title: 'Family Household Budget',
    description: 'Monthly household groceries, utility vouchers, and tuition reserve.',
    initialBalanceCents: 2500000, // 25,000.00 ETB
    transactions: [
      DemoTransaction(
        description: 'Monthly Employment Salary',
        amountCents: 3500000,
        type: 'income',
        category: 'Salary',
        account: 'CBE Bank',
      ),
      DemoTransaction(
        description: 'Weekly Market Fresh Groceries',
        amountCents: 420000,
        type: 'expense',
        category: 'Groceries',
        account: 'Telebirr',
      ),
      DemoTransaction(
        description: 'Prepaid Electricity Voucher',
        amountCents: 80000,
        type: 'expense',
        category: 'Utilities',
        account: 'CBE Bank',
      ),
      DemoTransaction(
        description: 'School Term Bus Fee',
        amountCents: 150000,
        type: 'expense',
        category: 'Education',
        account: 'Cash Wallet',
      ),
    ],
  );

  static const merchantProfile = DemoDataProfile(
    title: 'Small Retail Merchant (Merkato)',
    description: 'Daily shop sales, supplier inventory purchase, and customer credit ledger.',
    initialBalanceCents: 5000000, // 50,000.00 ETB
    transactions: [
      DemoTransaction(
        description: 'Morning Retail Goods Sales',
        amountCents: 850000,
        type: 'income',
        category: 'Sales',
        account: 'Telebirr',
      ),
      DemoTransaction(
        description: 'Wholesale Inventory Restock',
        amountCents: 620000,
        type: 'expense',
        category: 'Inventory',
        account: 'CBE Bank',
      ),
      DemoTransaction(
        description: 'Shop Electricity & Maintenance',
        amountCents: 40000,
        type: 'expense',
        category: 'Utilities',
        account: 'Cash Wallet',
      ),
    ],
  );
}
