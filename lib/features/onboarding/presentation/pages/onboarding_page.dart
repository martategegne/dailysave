import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dailysave/core/accessibility/accessibility_utils.dart';
import 'package:dailysave/core/database/app_database.dart';
import '../../domain/entities/demo_data.dart';
import '../demo_data_generator.dart';

class OnboardingPage extends StatefulWidget {
  final AppDatabase database;

  const OnboardingPage({super.key, required this.database});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  String _selectedLanguage = 'en';
  String _selectedCalendar = 'ethiopian';
  String _initialAccountName = 'Telebirr';
  final TextEditingController _balanceController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({DemoDataProfile? demoProfile}) async {
    setState(() => _isLoading = true);

    try {
      if (demoProfile != null) {
        await DemoDataGenerator.seedFictionalProfile(widget.database, demoProfile);
      } else {
        // Save user preferences
        await widget.database.into(widget.database.userPreferencesTable).insertOnConflictUpdate(
          UserPreferencesTableCompanion.insert(
            key: 'language',
            value: _selectedLanguage,
          ),
        );
        await widget.database.into(widget.database.userPreferencesTable).insertOnConflictUpdate(
          UserPreferencesTableCompanion.insert(
            key: 'calendar_type',
            value: _selectedCalendar,
          ),
        );
        await widget.database.into(widget.database.userPreferencesTable).insertOnConflictUpdate(
          UserPreferencesTableCompanion.insert(
            key: 'onboarding_completed',
            value: 'true',
          ),
        );
      }

      if (mounted) {
        context.go('/');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to DailySave (የዕለት ቁጠባ)'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _completeOnboarding();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Row(
                      children: [
                        AccessibilityUtils.ensureMinTouchTarget(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16865B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(_currentStep == 3 ? 'Start Fresh' : 'Continue'),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          AccessibilityUtils.ensureMinTouchTarget(
                            child: OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  // Step 1: Language Selection
                  Step(
                    title: const Text('Language (ቋንቋ)'),
                    isActive: _currentStep >= 0,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose your preferred language for financial terms and navigation:',
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<String>(
                          title: const Text('English (US)'),
                          value: 'en',
                          groupValue: _selectedLanguage,
                          onChanged: (val) => setState(() => _selectedLanguage = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Amharic (አማርኛ)'),
                          value: 'am',
                          groupValue: _selectedLanguage,
                          onChanged: (val) => setState(() => _selectedLanguage = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Afaan Oromoo (Oromo)'),
                          value: 'om',
                          groupValue: _selectedLanguage,
                          onChanged: (val) => setState(() => _selectedLanguage = val!),
                        ),
                      ],
                    ),
                  ),

                  // Step 2: Currency & Calendar
                  Step(
                    title: const Text('Calendar & Currency'),
                    isActive: _currentStep >= 1,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select your primary calendar system. You can switch calendars anytime.',
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<String>(
                          title: const Text("Ethiopian Ge'ez Calendar (13 Months)"),
                          subtitle: const Text('Meskerem to Pagume with Ge’ez numerals (፩, ፪, ፫)'),
                          value: 'ethiopian',
                          groupValue: _selectedCalendar,
                          onChanged: (val) => setState(() => _selectedCalendar = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Gregorian Calendar (Western)'),
                          subtitle: const Text('January to December'),
                          value: 'gregorian',
                          groupValue: _selectedCalendar,
                          onChanged: (val) => setState(() => _selectedCalendar = val!),
                        ),
                        const SizedBox(height: 12),
                        const ListTile(
                          leading: Icon(Icons.monetization_on, color: Color(0xFF16865B)),
                          title: Text('Primary Currency'),
                          subtitle: Text('Ethiopian Birr (ETB) — 64-bit integer cents precision'),
                        ),
                      ],
                    ),
                  ),

                  // Step 3: Initial Account
                  Step(
                    title: const Text('Primary Wallet / Account'),
                    isActive: _currentStep >= 2,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Where do you keep your everyday spending money?',
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _initialAccountName,
                          decoration: const InputDecoration(
                            labelText: 'Account Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Telebirr', child: Text('Telebirr Mobile Wallet')),
                            DropdownMenuItem(value: 'CBE Bank', child: Text('Commercial Bank of Ethiopia (CBE)')),
                            DropdownMenuItem(value: 'Cash Wallet', child: Text('Physical Cash Wallet')),
                            DropdownMenuItem(value: 'Awash Bank', child: Text('Awash Bank')),
                          ],
                          onChanged: (val) => setState(() => _initialAccountName = val!),
                        ),
                      ],
                    ),
                  ),

                  // Step 4: Explore or Start Fresh
                  Step(
                    title: const Text('Ready to Start!'),
                    isActive: _currentStep >= 3,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Would you like to start with an empty ledger, or explore DailySave using safe fictional demo data?',
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          color: const Color(0xFFF1F5F9),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Explore with Fictional Demo Datasets:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                AccessibilityUtils.ensureMinTouchTarget(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.school, color: Color(0xFF16865B)),
                                    label: const Text('Student Profile (Campus Budget)'),
                                    onPressed: () => _completeOnboarding(
                                      demoProfile: DemoDatasets.studentProfile,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AccessibilityUtils.ensureMinTouchTarget(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.family_restroom, color: Color(0xFF16865B)),
                                    label: const Text('Family Household Profile'),
                                    onPressed: () => _completeOnboarding(
                                      demoProfile: DemoDatasets.familyProfile,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AccessibilityUtils.ensureMinTouchTarget(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.storefront, color: Color(0xFF16865B)),
                                    label: const Text('Small Merchant Profile (Merkato)'),
                                    onPressed: () => _completeOnboarding(
                                      demoProfile: DemoDatasets.merchantProfile,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
