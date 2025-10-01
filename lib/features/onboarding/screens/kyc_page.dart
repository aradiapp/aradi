import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/file_upload_service.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/core/models/seller_profile.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'dart:io';



class KYCPage extends ConsumerStatefulWidget {
  final String role;

  const KYCPage({super.key, required this.role});

  @override
  ConsumerState<KYCPage> createState() => _KYCPageState();
}

class _KYCPageState extends ConsumerState<KYCPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  
  // File uploads
  File? _passportFile;
  File? _emiratesIdFile;
  File? _tradeLicenseFile;
  File? _signatoryPassportFile;
  File? _logoFile;

  // Helper method to create consistent input decoration
  InputDecoration _createInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon),
      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  // Simple validation functions to replace FormBuilderValidators
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle system back button
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/role');
        }
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text('${_getRoleTitle()} Verification'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Ensure back button works properly
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back to role selection
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/role');
              }
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Complete Your Profile',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide the required information to verify your account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildFormFields(),
                    ),
                  ),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Complete Verification',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
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

  Widget _buildFormFields() {
    switch (widget.role) {
      case 'developer':
        return _buildDeveloperForm();
      case 'buyer':
        return _buildBuyerForm();
      case 'seller':
        return _buildSellerForm();
      default:
        return const Text('Invalid role');
    }
  }

  Widget _buildDeveloperForm() {
    return Column(
      children: [
        FormBuilderTextField(
          name: 'companyName',
          decoration: _createInputDecoration(
            labelText: 'Company Name *',
            hintText: 'Enter your company name',
            icon: Icons.business,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'companyEmail',
          decoration: _createInputDecoration(
            labelText: 'Company Email *',
            hintText: 'Enter your company email',
            icon: Icons.email,
          ),
          validator: _emailValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'companyPhone',
          decoration: _createInputDecoration(
            labelText: 'Company Phone *',
            hintText: 'Enter your company phone',
            icon: Icons.phone,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'tradeLicense',
          decoration: _createInputDecoration(
            labelText: 'Trade License Number *',
            hintText: 'Enter your trade license number',
            icon: Icons.verified_user,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'signatoryPassport',
          decoration: _createInputDecoration(
            labelText: 'Signatory Passport *',
            hintText: 'Enter passport number',
            icon: Icons.credit_card,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderDropdown<String>(
          name: 'businessModel',
          decoration: _createInputDecoration(
            labelText: 'Business Model *',
            hintText: 'Select your business model',
            icon: Icons.model_training,
          ),
          items: const [
            DropdownMenuItem(
              value: 'business',
              child: Text('Business Development'),
            ),
            DropdownMenuItem(
              value: 'venture',
              child: Text('Venture Development'),
            ),
            DropdownMenuItem(
              value: 'both',
              child: Text('Both'),
            ),
          ],
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'areasInterested',
          decoration: _createInputDecoration(
            labelText: 'Areas of Interest',
            hintText: 'e.g., Dubai Marina, Palm Jumeirah (comma separated)',
            icon: Icons.location_on,
          ),
        ),
        const SizedBox(height: 20),
        
        // File Upload Section
        _buildFileUploadSection(),
      ],
    );
  }

  Widget _buildBuyerForm() {
    return Column(
      children: [
        FormBuilderTextField(
          name: 'name',
          decoration: _createInputDecoration(
            labelText: 'Full Name *',
            hintText: 'Enter your full name',
            icon: Icons.person,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'passport',
          decoration: _createInputDecoration(
            labelText: 'Passport Number *',
            hintText: 'Enter your passport number',
            icon: Icons.credit_card,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'email',
          decoration: _createInputDecoration(
            labelText: 'Email *',
            hintText: 'Enter your email address',
            icon: Icons.email,
          ),
          validator: _emailValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'phone',
          decoration: _createInputDecoration(
            labelText: 'Phone *',
            hintText: 'Enter your phone number',
            icon: Icons.phone,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'areasInterested',
          decoration: _createInputDecoration(
            labelText: 'Areas of Interest',
            hintText: 'Enter areas you\'re interested in (comma separated)',
            icon: Icons.location_on,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FormBuilderTextField(
                name: 'gfaMin',
                decoration: _createInputDecoration(
                  labelText: 'Min GFA (sqm)',
                  hintText: 'Minimum',
                  icon: Icons.square_foot,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormBuilderTextField(
                name: 'gfaMax',
                decoration: _createInputDecoration(
                  labelText: 'Max GFA (sqm)',
                  hintText: 'Maximum',
                  icon: Icons.square_foot,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FormBuilderTextField(
                name: 'budgetMin',
                decoration: _createInputDecoration(
                  labelText: 'Min Budget (AED)',
                  hintText: 'Minimum',
                  icon: Icons.attach_money,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormBuilderTextField(
                name: 'budgetMax',
                decoration: _createInputDecoration(
                  labelText: 'Max Budget (AED)',
                  hintText: 'Maximum',
                  icon: Icons.attach_money,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildFileUploadSection(),
      ],
    );
  }

  Widget _buildSellerForm() {
    return Column(
      children: [
        FormBuilderTextField(
          name: 'name',
          decoration: _createInputDecoration(
            labelText: 'Full Name *',
            hintText: 'Enter your full name',
            icon: Icons.person,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'phone',
          decoration: _createInputDecoration(
            labelText: 'Phone *',
            hintText: 'Enter your phone number',
            icon: Icons.phone,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'email',
          decoration: _createInputDecoration(
            labelText: 'Email *',
            hintText: 'Enter your email address',
            icon: Icons.email,
          ),
          validator: _emailValidator,
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'tradeLicense',
          decoration: _createInputDecoration(
            labelText: 'Trade License (Optional)',
            hintText: 'Enter your trade license if applicable',
            icon: Icons.verified_user,
          ),
        ),
        const SizedBox(height: 20),
        FormBuilderTextField(
          name: 'passportOrEmiratesId',
          decoration: _createInputDecoration(
            labelText: 'Passport/Emirates ID *',
            hintText: 'Enter your passport or Emirates ID',
            icon: Icons.credit_card,
          ),
          validator: _requiredValidator,
        ),
        const SizedBox(height: 32),
        _buildFileUploadSection(),
      ],
    );
  }

  String _getRoleTitle() {
    switch (widget.role) {
      case 'developer':
        return 'Developer';
      case 'buyer':
        return 'Buyer';
      case 'seller':
        return 'Seller';
      default:
        return 'User';
    }
  }
  
  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Documents',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        if (widget.role == 'developer') ...[
          _buildFileUploadButton(
            label: 'Trade License',
            file: _tradeLicenseFile,
            onTap: () => _pickFile('tradeLicense'),
            required: true,
          ),
          const SizedBox(height: 12),
          _buildFileUploadButton(
            label: 'Signatory Passport',
            file: _signatoryPassportFile,
            onTap: () => _pickFile('signatoryPassport'),
            required: true,
          ),
          const SizedBox(height: 12),
          _buildFileUploadButton(
            label: 'Company Logo (Optional)',
            file: _logoFile,
            onTap: () => _pickFile('logo'),
            required: false,
          ),
        ] else if (widget.role == 'buyer') ...[
          _buildFileUploadButton(
            label: 'Passport',
            file: _passportFile,
            onTap: () => _pickFile('passport'),
            required: true,
          ),
        ] else if (widget.role == 'seller') ...[
          _buildFileUploadButton(
            label: 'Passport or Emirates ID',
            file: _passportFile,
            onTap: () => _pickFile('passport'),
            required: true,
          ),
          const SizedBox(height: 12),
          _buildFileUploadButton(
            label: 'Trade License (Optional)',
            file: _tradeLicenseFile,
            onTap: () => _pickFile('tradeLicense'),
            required: false,
          ),
          const SizedBox(height: 12),
          _buildFileUploadButton(
            label: 'Company Logo (Optional)',
            file: _logoFile,
            onTap: () => _pickFile('logo'),
            required: false,
          ),
        ],
      ],
    );
  }
  
  Widget _buildFileUploadButton({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required bool required,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: file != null ? AppTheme.primaryColor : AppTheme.textSecondary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: file != null ? AppTheme.primaryColor.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle : Icons.upload_file,
              color: file != null ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label + (required ? ' *' : ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: file != null ? AppTheme.primaryColor : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    file != null ? 'File selected' : 'Tap to select file',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickFile(String type) async {
    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      File? selectedFile;
      
      // Show options for passport/emirates ID
      if (type == 'passport' && widget.role == 'seller') {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Document Type'),
            content: const Text('Choose the type of document you want to upload'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'passport'),
                child: const Text('Passport'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'emiratesId'),
                child: const Text('Emirates ID'),
              ),
            ],
          ),
        );
        
        if (choice == 'emiratesId') {
          type = 'emiratesId';
        }
      }
      
      // Pick file based on type
      if (type == 'logo') {
        selectedFile = await fileUploadService.pickImageFromGallery();
      } else {
        // For documents, show gallery option
        selectedFile = await fileUploadService.pickImageFromGallery();
      }
      
      if (selectedFile != null) {
        print('=== FILE PICKER DEBUG ===');
        print('File selected: $selectedFile for type: $type');
        print('File exists: ${selectedFile.existsSync()}');
        print('File size: ${selectedFile.lengthSync()} bytes');
        setState(() {
          switch (type) {
            case 'passport':
              _passportFile = selectedFile;
              print('Set _passportFile to: $_passportFile');
              print('_passportFile exists after set: ${_passportFile?.existsSync()}');
              break;
            case 'emiratesId':
              _emiratesIdFile = selectedFile;
              print('Set _emiratesIdFile to: $_emiratesIdFile');
              print('_emiratesIdFile exists after set: ${_emiratesIdFile?.existsSync()}');
              break;
            case 'tradeLicense':
              _tradeLicenseFile = selectedFile;
              print('Set _tradeLicenseFile to: $_tradeLicenseFile');
              print('_tradeLicenseFile exists after set: ${_tradeLicenseFile?.existsSync()}');
              break;
            case 'signatoryPassport':
              _signatoryPassportFile = selectedFile;
              print('Set _signatoryPassportFile to: $_signatoryPassportFile');
              print('_signatoryPassportFile exists after set: ${_signatoryPassportFile?.existsSync()}');
              break;
            case 'logo':
              _logoFile = selectedFile;
              print('Set _logoFile to: $_logoFile');
              print('_logoFile exists after set: ${_logoFile?.existsSync()}');
              break;
          }
        });
        print('File upload completed for type: $type');
        print('========================');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      // Debug: Print file states
      print('=== KYC FORM SUBMISSION DEBUG ===');
      print('File validation debug:');
      print('_passportFile: $_passportFile');
      print('_passportFile exists: ${_passportFile?.existsSync()}');
      print('_tradeLicenseFile: $_tradeLicenseFile');
      print('_tradeLicenseFile exists: ${_tradeLicenseFile?.existsSync()}');
      print('_signatoryPassportFile: $_signatoryPassportFile');
      print('_signatoryPassportFile exists: ${_signatoryPassportFile?.existsSync()}');
      print('_emiratesIdFile: $_emiratesIdFile');
      print('_emiratesIdFile exists: ${_emiratesIdFile?.existsSync()}');
      print('User role: ${widget.role}');
      print('Form validation passed: ${_formKey.currentState?.saveAndValidate()}');
      print('================================');
      
      // Validate required documents based on role
      if (widget.role == 'buyer' && _passportFile == null) {
        print('ERROR: _passportFile is null for buyer');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passport document is required'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      
      if (widget.role == 'seller' && _passportFile == null) {
        print('ERROR: Passport or Emirates ID required for seller');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passport or Emirates ID document is required'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      
      if (widget.role == 'developer' && _tradeLicenseFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade license document is required for developers'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      
      if (widget.role == 'developer' && _signatoryPassportFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authorized signatory passport is required for developers'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        final authService = ref.read(authServiceProvider);
        final fileUploadService = ref.read(fileUploadServiceProvider);
        
        // Get current user
        final currentUser = await authService.getCurrentUser();
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }
        
        // Upload files if any
        print('=== FILE UPLOAD DEBUG ===');
        Map<String, String> uploadedFiles = {};
        if (_passportFile != null) {
          print('Uploading passport file...');
          uploadedFiles['passport'] = await fileUploadService.uploadFile(_passportFile!, 'kyc/passports');
          print('Passport uploaded: ${uploadedFiles['passport']}');
        }
        if (_emiratesIdFile != null) {
          print('Uploading Emirates ID file...');
          uploadedFiles['emiratesId'] = await fileUploadService.uploadFile(_emiratesIdFile!, 'kyc/emirates_ids');
          print('Emirates ID uploaded: ${uploadedFiles['emiratesId']}');
        }
        if (_tradeLicenseFile != null) {
          print('Uploading trade license file...');
          uploadedFiles['tradeLicense'] = await fileUploadService.uploadFile(_tradeLicenseFile!, 'kyc/trade_licenses');
          print('Trade license uploaded: ${uploadedFiles['tradeLicense']}');
        }
        if (_signatoryPassportFile != null) {
          print('Uploading signatory passport file...');
          uploadedFiles['signatoryPassport'] = await fileUploadService.uploadFile(_signatoryPassportFile!, 'kyc/signatory_passports');
          print('Signatory passport uploaded: ${uploadedFiles['signatoryPassport']}');
        }
        if (_logoFile != null) {
          print('Uploading logo file...');
          uploadedFiles['logo'] = await fileUploadService.uploadFile(_logoFile!, 'kyc/logos');
          print('Logo uploaded: ${uploadedFiles['logo']}');
        }
        print('All files uploaded successfully');
        print('========================');
        
        // Create role-specific profile
        print('=== PROFILE CREATION DEBUG ===');
        print('Creating profile for role: ${widget.role}');
        switch (widget.role) {
          case 'developer':
            print('Creating developer profile...');
            await _createDeveloperProfile(formData, uploadedFiles, currentUser.id);
            print('Developer profile created successfully');
            break;
          case 'buyer':
            print('Creating buyer profile...');
            await _createBuyerProfile(formData, uploadedFiles, currentUser.id);
            print('Buyer profile created successfully');
            break;
          case 'seller':
            print('Creating seller profile...');
            await _createSellerProfile(formData, uploadedFiles, currentUser.id);
            print('Seller profile created successfully');
            break;
        }
        print('=============================');
        
        // Update user role and profile completion status (but not KYC verified yet)
        final updatedUser = currentUser.copyWith(
          role: widget.role == 'developer' ? UserRole.developer : 
                widget.role == 'buyer' ? UserRole.buyer : UserRole.seller,
          isProfileComplete: true,
          isKycVerified: false, // Will be set to true by admin approval
          wasKycRejected: false, // Reset rejection flag on resubmission
        );
        await authService.updateUserProfile(updatedUser);
        
        // Show pending approval message and navigate to auth
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile submitted for admin approval. You will be notified once approved.'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 5),
            ),
          );
          context.go('/auth');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _createDeveloperProfile(Map<String, dynamic> formData, Map<String, String> uploadedFiles, String userId) async {
    final authService = ref.read(authServiceProvider);
    
    // Validate that we have the required uploaded files
    if (uploadedFiles['tradeLicense'] == null || uploadedFiles['tradeLicense']!.isEmpty) {
      throw Exception('Trade license file is required');
    }
    if (uploadedFiles['signatoryPassport'] == null || uploadedFiles['signatoryPassport']!.isEmpty) {
      throw Exception('Signatory passport file is required');
    }
    
    await authService.createDeveloperProfile(
      userId: userId,
      companyName: formData['companyName'],
      companyEmail: formData['companyEmail'],
      companyPhone: formData['companyPhone'],
      tradeLicense: uploadedFiles['tradeLicense']!, // Use uploaded file, not form data
      signatoryPassport: uploadedFiles['signatoryPassport']!, // Use uploaded file, not form data
      businessModel: BusinessModel.values.firstWhere(
        (e) => e.toString().split('.').last == formData['businessModel'],
        orElse: () => BusinessModel.business,
      ),
      areasInterested: (formData['areasInterested'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [],
      logoUrl: uploadedFiles['logo'], // This can be null if not provided
    );
  }
  
  Future<void> _createBuyerProfile(Map<String, dynamic> formData, Map<String, String> uploadedFiles, String userId) async {
    final authService = ref.read(authServiceProvider);
    
    // Parse areas of interest
    List<String> areasInterested = [];
    if (formData['areasInterested'] != null && formData['areasInterested'].toString().trim().isNotEmpty) {
      areasInterested = formData['areasInterested'].toString().split(',').map((e) => e.trim()).toList();
    }
    
    // Parse GFA range
    Map<String, double>? gfaRange;
    if (formData['gfaMin'] != null && formData['gfaMax'] != null) {
      final gfaMin = double.tryParse(formData['gfaMin'].toString());
      final gfaMax = double.tryParse(formData['gfaMax'].toString());
      if (gfaMin != null && gfaMax != null) {
        gfaRange = {'min': gfaMin, 'max': gfaMax};
      }
    }
    
    // Parse budget range
    Map<String, double>? budgetRange;
    if (formData['budgetMin'] != null && formData['budgetMax'] != null) {
      final budgetMin = double.tryParse(formData['budgetMin'].toString());
      final budgetMax = double.tryParse(formData['budgetMax'].toString());
      if (budgetMin != null && budgetMax != null) {
        budgetRange = {'min': budgetMin, 'max': budgetMax};
      }
    }
    
    // Validate that we have the required uploaded files
    if (uploadedFiles['passport'] == null || uploadedFiles['passport']!.isEmpty) {
      throw Exception('Passport file is required');
    }
    
    await authService.createBuyerProfile(
      userId: userId,
      name: formData['name'],
      passport: uploadedFiles['passport']!, // Use uploaded file, not form data
      email: formData['email'],
      phone: formData['phone'],
      areasInterested: areasInterested,
      gfaRange: gfaRange,
      budgetRange: budgetRange,
    );
  }
  
  Future<void> _createSellerProfile(Map<String, dynamic> formData, Map<String, String> uploadedFiles, String userId) async {
    final authService = ref.read(authServiceProvider);
    
    // Validate that we have the required uploaded files
    if (uploadedFiles['passport'] == null || uploadedFiles['passport']!.isEmpty) {
      throw Exception('Passport or Emirates ID file is required');
    }
    
    await authService.createSellerProfile(
      userId: userId,
      name: formData['name'],
      phone: formData['phone'],
      email: formData['email'],
      passportOrEmiratesId: uploadedFiles['passport']!, // Use uploaded file, not form data
      tradeLicense: uploadedFiles['tradeLicense'], // This can be null if not provided
      logoUrl: uploadedFiles['logo'], // This can be null if not provided
    );
  }
}
