import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/accessibility/accessibility_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_parser.dart';
import '../../domain/entities/financial_transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

/// Accessible and responsive form for recording or modifying transactions.
/// Supports both Income and Expense modes, categorized according to requirements.
class AddEditTransactionPage extends StatefulWidget {
  final FinancialTransaction? transactionToEdit;
  final TransactionType initialType;

  const AddEditTransactionPage({
    super.key,
    this.transactionToEdit,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _receiptController;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late String _selectedAccount;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  static const List<String> incomeCategories = [
    'Salary',
    'Freelancing',
    'Business',
    'Tutoring',
    'Allowance',
    'Gifts',
    'Investments',
    'Rental income',
    'Other',
  ];

  static const List<String> expenseCategories = [
    'Food',
    'Transportation',
    'Education',
    'Housing',
    'Electricity',
    'Water',
    'Healthcare',
    'Communication',
    'Internet',
    'Entertainment',
    'Clothing',
    'Shopping',
    'Family support',
    'Business',
    'Personal care',
    'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'Telebirr',
    'CBE Birr',
    'Bank Transfer',
    'Amole',
    'Other',
  ];

  static const List<String> accounts = [
    'Cash Wallet',
    'Telebirr',
    'Commercial Bank of Ethiopia (CBE)',
    'Emergency Savings Reserve',
    'Other Account',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;

    _selectedType = edit?.type ?? widget.initialType;

    final initialAmount = edit != null ? (edit.amountInCents / 100).toStringAsFixed(2) : '';
    _amountController = TextEditingController(text: initialAmount);
    _descriptionController = TextEditingController(text: edit?.description ?? '');
    _notesController = TextEditingController(text: edit?.notes ?? '');
    _receiptController = TextEditingController(text: edit?.receiptPath ?? '');

    final availableCategories = _selectedType == TransactionType.income
        ? incomeCategories
        : expenseCategories;

    _selectedCategory = (edit != null && availableCategories.contains(edit.category))
        ? edit.category
        : availableCategories.first;

    _selectedPaymentMethod = (edit != null && paymentMethods.contains(edit.paymentMethod))
        ? edit.paymentMethod
        : paymentMethods.first;

    _selectedAccount = (edit != null && accounts.contains(edit.account))
        ? edit.account
        : accounts.first;

    _selectedDate = edit?.date ?? DateTime.now();
    _selectedTime = edit != null
        ? TimeOfDay(hour: edit.date.hour, minute: edit.date.minute)
        : TimeOfDay.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories {
    return _selectedType == TransactionType.income
        ? incomeCategories
        : expenseCategories;
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      _selectedCategory = _currentCategories.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final cents = parseEtbToMinorUnits(_amountController.text.trim())!;
    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final now = DateTime.now();
    final isEditing = widget.transactionToEdit != null;

    final transaction = FinancialTransaction(
      id: isEditing ? widget.transactionToEdit!.id : const Uuid().v4(),
      amountInCents: cents,
      type: _selectedType,
      currency: 'ETB',
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      date: combinedDateTime,
      paymentMethod: _selectedPaymentMethod,
      account: _selectedAccount,
      notes: _notesController.text.trim(),
      receiptPath: _receiptController.text.trim().isNotEmpty
          ? _receiptController.text.trim()
          : null,
      createdAt: isEditing ? widget.transactionToEdit!.createdAt : now,
      updatedAt: now,
    );

    if (isEditing) {
      context.read<TransactionBloc>().add(TransactionUpdated(transaction));
    } else {
      context.read<TransactionBloc>().add(TransactionAdded(transaction));
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing ? 'Transaction updated successfully.' : 'Transaction recorded in database.',
        ),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    final title = isEditing
        ? 'Edit Transaction'
        : (_selectedType == TransactionType.income ? 'Record Income' : 'Record Expense');

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Switcher (Income vs Expense)
                  if (!isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Expense (ወጪ)')),
                            selected: _selectedType == TransactionType.expense,
                            selectedColor: AppColors.expenseWarning.withValues(alpha: 0.15),
                            onSelected: (selected) {
                              if (selected) _onTypeChanged(TransactionType.expense);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Income (ገቢ)')),
                            selected: _selectedType == TransactionType.income,
                            selectedColor: AppColors.success.withValues(alpha: 0.15),
                            onSelected: (selected) {
                              if (selected) _onTypeChanged(TransactionType.income);
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Amount in ETB
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (ETB / የብር መጠን) *',
                      hintText: 'e.g. 500.00',
                      prefixIcon: Icon(Icons.money),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Amount is required.';
                      }
                      final cents = parseEtbToMinorUnits(val);
                      if (cents == null || cents <= 0) {
                        return 'Enter a valid positive amount (max 2 decimals).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    key: ValueKey('cat_${_selectedType.name}_$_selectedCategory'),
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _currentCategories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'What was this transaction for?',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Description is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(_selectedTime.format(context)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payment_outlined),
                    ),
                    items: paymentMethods
                        .map((pm) => DropdownMenuItem(value: pm, child: Text(pm)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPaymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Account / Wallet
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'Account / Wallet',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: accounts
                        .map((acc) => DropdownMenuItem(value: acc, child: Text(acc)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAccount = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes (Optional)
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Additional details or memo',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Receipt
                  TextFormField(
                    controller: _receiptController,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Attachment Ref (Optional)',
                      hintText: 'Reference code or receipt filename',
                      prefixIcon: Icon(Icons.receipt_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Action Button
                  AccessibilityUtils.ensureMinTouchTarget(
                    child: FilledButton.icon(
                      onPressed: _saveTransaction,
                      icon: const Icon(Icons.check),
                      label: Text(isEditing ? 'Save Changes' : 'Record Transaction'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedType == TransactionType.income
                            ? AppColors.primaryGreen
                            : AppColors.darkNavy,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
