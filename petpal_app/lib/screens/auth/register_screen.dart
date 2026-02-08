import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../models/app_user.dart';
import '../../screens/home/home_screen.dart';
import '../../utils/app_validators.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../vets/vet_profile_setup_screen.dart';
import '../../screens/sitters/sitter_profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();

  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _manualStateController = TextEditingController();
  // _countryController removed, using selection state

  // State
  UserRole _role = UserRole.owner;
  String _selectedCountry = 'Malaysia';
  String? _selectedMalaysianState;
  String _selectedCountryCode = '+60';

  // Password Validation State
  bool _isPasswordLengthValid = false;
  bool _doPasswordsMatch = false;

  final List<String> _countries = [
    'Malaysia',
    'Singapore',
    'Indonesia',
    'Thailand',
    'Vietnam',
    'Philippines',
    'Brunei',
    'United Kingdom',
    'United States',
    'Australia',
    'Other',
  ];

  final List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];

  final List<String> _countryCodes = [
    '+60',
    '+65',
    '+62',
    '+66',
    '+84',
    '+63',
    '+673',
    '+44',
    '+1',
    '+61',
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordValidation);
    _confirmPasswordController.addListener(_updatePasswordValidation);
  }

  void _updatePasswordValidation() {
    setState(() {
      _isPasswordLengthValid = _passwordController.text.length >= 6;
      _doPasswordsMatch =
          _passwordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _manualStateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Final check on password
    if (!_isPasswordLengthValid || !_doPasswordsMatch) {
      DialogUtils.showErrorDialog(context, 'Please fix password errors.');
      return;
    }

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    final stateValue = _selectedCountry == 'Malaysia'
        ? _selectedMalaysianState ?? ''
        : _manualStateController.text.trim();

    final fullAddress =
        '${_address1Controller.text.trim()}, ${_address2Controller.text.trim()}, '
        '${_cityController.text.trim()}, $stateValue, '
        '${_postcodeController.text.trim()}, $_selectedCountry';

    final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        name: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
        phone: fullPhone,
        address: fullAddress,
        birthday: _dobController.text.trim(),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = picked.toIso8601String().split('T').first;

      // Auto-calculate age
      final now = DateTime.now();
      int age = now.year - picked.year;
      if (now.month < picked.month ||
          (now.month == picked.month && now.day < picked.day)) {
        age--;
      }
      _ageController.text = age.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            // Only trigger listener when error or auth status actually changes
            return previous.errorMessage != current.errorMessage ||
                previous.status != current.status;
          },
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              DialogUtils.showErrorDialog(context, state.errorMessage!);
            }
            if (state.status == AuthStatus.authenticated) {
              if (state.user?.role == UserRole.vet) {
                Navigator.pushReplacementNamed(
                  context,
                  VetProfileSetupScreen.routeName,
                );
              } else if (state.user?.role == UserRole.sitter) {
                Navigator.pushReplacementNamed(
                  context,
                  SitterProfileSetupScreen.routeName,
                );
              } else {
                Navigator.pushReplacementNamed(context, HomeScreen.routeName);
              }
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role Selection (Single option visible as per requirements, but keeping structure)
                  DropdownButtonFormField<UserRole>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: 'I am a...'),
                    onChanged: (role) =>
                        setState(() => _role = role ?? UserRole.owner),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.owner,
                        child: Text('Pet Owner'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.vet,
                        child: Text('Veterinarian'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.sitter,
                        child: Text('Pet Sitter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Personal Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          validator: (v) => AppValidators.required(
                            v,
                            fieldName: 'First Name',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          validator: (v) =>
                              AppValidators.required(v, fieldName: 'Last Name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  // Live validation indicators
                  Row(
                    children: [
                      Icon(
                        _isPasswordLengthValid
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _isPasswordLengthValid
                            ? Colors.green
                            : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'At least 6 characters',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _doPasswordsMatch
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _doPasswordsMatch ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Passwords match',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: AppTextField(
                          controller: _ageController,
                          label: 'Age',
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              AppValidators.required(v, fieldName: 'Age'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: AppTextField(
                              controller: _dobController,
                              label: 'Date of Birth',
                              validator: (v) =>
                                  AppValidators.required(v, fieldName: 'DOB'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCountryCode,
                          decoration: const InputDecoration(labelText: 'Code'),
                          items: _countryCodes
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCountryCode = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _phoneController,
                          label: 'Mobile Number',
                          keyboardType: TextInputType.phone,
                          validator: (v) => AppValidators.required(
                            v,
                            fieldName: 'Mobile Number',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Address',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _address1Controller,
                    label: 'Address Line 1',
                    validator: (v) =>
                        AppValidators.required(v, fieldName: 'Address Line 1'),
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _address2Controller,
                    label: 'Address Line 2 (Optional)',
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _cityController,
                          label: 'City',
                          validator: (v) =>
                              AppValidators.required(v, fieldName: 'City'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _postcodeController,
                          label: 'Postcode',
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          hideCounter: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length != 5) return 'Must be 5 digits';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedCountry,
                    decoration: const InputDecoration(labelText: 'Country'),
                    items: _countries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCountry = val!;
                        _selectedMalaysianState = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_selectedCountry == 'Malaysia')
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMalaysianState,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (v) => v == null ? 'Required' : null,
                      items: _malaysianStates
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedMalaysianState = val),
                    )
                  else
                    AppTextField(
                      controller: _manualStateController,
                      label: 'State/Province',
                      validator: (v) =>
                          AppValidators.required(v, fieldName: 'State'),
                    ),

                  const SizedBox(height: 32),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        label: 'Register',
                        isLoading: state.isLoading,
                        onPressed: _submit,
                      );
                    },
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
