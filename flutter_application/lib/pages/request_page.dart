import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/file_list.dart';
import 'package:flutter_application/custom_widgets/file_uploader.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/chat_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/rent_service.dart';
import 'package:flutter_application/services/socket_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:image_picker/image_picker.dart';

class RequestPage extends StatefulWidget {
  final int requestId;

  const RequestPage({super.key, required this.requestId});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  // Main State
  Request? request;
  bool loading = true;
  int selectedStep = 1;

  // Data for UI (Derived from Request)
  RequestUser? displayUser; // The "other" person (Owner if I am Tenant, etc.)
  RentAmount? priceDetails; // Only fetched for Step 5

  // Step 2 Form State
  List<XFile> uploadedContract = [];
  int? gracePeriodDays;
  double? rentalPrice;
  double? depositPrice;
  late TextEditingController rentalController;
  late TextEditingController depositController;

  @override
  void initState() {
    super.initState();
    rentalController = TextEditingController();
    depositController = TextEditingController();
    _loadRequest();

    SocketService.onEvent('refresh_request', (data) {
      debugPrint("Received refresh event: $data");
      if (data['request_id'] == request?.id) {
        _loadRequest(); 
      }
    });
  }

  @override
  void dispose() {
    rentalController.dispose();
    depositController.dispose();
    super.dispose();
  }

  Future<void> _loadRequest() async {
    try {
      final fetchedRequest = await RentService.getRentRequest(widget.requestId);

      if (fetchedRequest != null) {
        // Determine "Other Party" to display
        final myId = AppUser().id;
        RequestUser? target;
        
        if (myId == fetchedRequest.tenantId) {
          target = fetchedRequest.owner; 
        } else {
          target = fetchedRequest.tenant; 
        }

        // Pre-fill 
        if (fetchedRequest.property != null) {
          if (rentalController.text.isEmpty) {
            rentalPrice = fetchedRequest.property!.price;
            rentalController.text = fetchedRequest.property!.price.toStringAsFixed(0);
          }
          if (depositController.text.isEmpty) {
            depositPrice = fetchedRequest.property!.deposit;
            depositController.text = fetchedRequest.property!.deposit.toStringAsFixed(0);
          }
        }

        // Update State
        setState(() {
          request = fetchedRequest;
          displayUser = target;
          selectedStep = fetchedRequest.currentStep;
          loading = false;
        });

        // Fetch Breakdown if at Payment Step
        if (fetchedRequest.currentStep == 5) {
          final fetchedPrice = await RentService.getRentAmounts(requestId: widget.requestId);
          setState(() => priceDetails = fetchedPrice);
        }

      } else {
        _handleError("Request not found");
      }
    } catch (e) {
      _handleError("Error loading request: $e");
    }
  }

  void _handleError(String msg) {
    setState(() => loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _onStepSelected(int step) {
    if (request == null) return;
    // Allow viewing past steps or current step
    if (step <= request!.currentStep) {
      setState(() {
        selectedStep = step;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request", style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? const Center(child: Text("Request not found"))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 22),
                        
                        if (request!.status == 'pending') 
                          _buildProgressBar(),
                        
                        const SizedBox(height: 20),
                        
                        // Content Area
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: (0.1)),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: (request!.status == 'pending')
                              ? _buildStepContent()
                              : _buildStatusMessage(),
                        ),

                        const SizedBox(height: 26),
                        
                        if (request!.status == 'pending')
                          Center(
                            child: OutlinedButton(
                              onPressed: () async {
                               
                                
                                await RentService.terminateRentRequest(userId: AppUser().id!, requestId: widget.requestId);
                                _loadRequest();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text("Terminate Request"),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    final prop = request!.property;
    final user = displayUser;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage: (user?.profileUrl != null)
                    ? NetworkImage(ApiService.buildImageUrl(user!.profileUrl!))
                    : null,
                child: (user?.profileUrl == null)
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? "Unknown User",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request!.tenantId == AppUser().id ? "Owner" : "Tenant",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        propertyId: request!.propertyId, 
                        tenantId: request!.tenantId, 
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text("Chat", style: TextStyle(fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: AppTheme.primaryColor,
                  iconColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // --- Label ---
          Row(
            children: const [
              Icon(Icons.info_outline, size: 16, color: Colors.orangeAccent),
              SizedBox(width: 6),
              Text(
                "Request Info",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.orangeAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Property Row ---
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: (prop?.thumbnailUrl != null)
                        ? DecorationImage(
                            image: NetworkImage(ApiService.buildImageUrl(prop!.thumbnailUrl!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: prop?.thumbnailUrl == null 
                      ? const Icon(Icons.home, color: Colors.grey) 
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prop?.name ?? "Unknown Property",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prop?.fullLocation ?? "",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // --- Dates ---
          Column(
            children: [
              _buildIconText(Icons.calendar_today, "Start:", 
                  request!.startDate.toLocal().toString().split(' ')[0]),
              const SizedBox(height: 8),
              _buildIconText(Icons.timer, "Duration:", 
                  "${request!.endDate.difference(request!.startDate).inDays ~/ 30} months"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        int stepNumber = index + 1;
        bool isCompleted = stepNumber < selectedStep;
        bool isCurrent = stepNumber == selectedStep;
        
        return GestureDetector(
          onTap: () => _onStepSelected(stepNumber),
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isCompleted ? Colors.green : (isCurrent ? AppTheme.primaryColor : Colors.grey.shade300),
                child: Text(
                  "$stepNumber",
                  style: TextStyle(color: (isCompleted || isCurrent) ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text("Step $stepNumber", style: TextStyle(fontSize: 12, color: (isCompleted || isCurrent) ? Colors.black : Colors.grey)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusMessage() {
    bool isRejected = request!.status == 'rejected';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRejected ? Icons.cancel : Icons.check_circle,
            size: 48,
            color: isRejected ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            "Request ${request!.status.toUpperCase()}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (selectedStep) {
      case 1: return _step1();
      case 2: return _step2();
      case 3: return _step3();
      case 4: return _step4();
      case 5: return _step5();
      default: return const Center(child: Text("Unknown Step"));
    }
  }

  // ==================== STEPS LOGIC ====================

  // --- STEP 1: Review ---
  Widget _step1() {
    final step1Docs = request!.documents.where((doc) => doc.stepNumber == 1).toList();
    final bool isOwner = AppUser().id != request!.tenantId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader("Request Review", "Step 1"),
        _docSection("Financial Proof Documents", step1Docs),
        const SizedBox(height: 30),
        
        if (isOwner && request!.currentStep == 1)
          Row(
            children: [
              Expanded(child: _actionButton("Reject", Colors.red, false, () async {
                await RentService.rejectRentRequest(requestId: request!.id);
                _loadRequest();
              })),
              const SizedBox(width: 16),
              Expanded(child: _actionButton("Approve", Colors.green, true, () async {
                await RentService.acceptRentRequest(requestId: request!.id);
                _loadRequest();
              })),
            ],
          )
        else if (!isOwner && request!.currentStep == 1)
          _waitingText("Waiting for owner approval..."),
      ],
    );
  }

  // --- STEP 2: Contract Upload ---
  Widget _step2() {
    final bool isOwner = AppUser().id != request!.tenantId;
    final prop = request!.property;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader("Contract Upload", "Step 2"),
        
        if (request!.currentStep == 2 && isOwner) ...[
          const Text("Upload Property Contract", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          XFileUploadWidget(
            maxFiles: 1,
            onFilesChanged: (files) => setState(() => uploadedContract = files),
          ),
          
          const SizedBox(height: 20),
          _inputField("Grace Period (Days)", (val) => gracePeriodDays = int.tryParse(val)),
          const SizedBox(height: 16),
          
          _priceRow("Rental Price (RM)", rentalController, (val) => rentalPrice = double.tryParse(val), prop?.price),
          const SizedBox(height: 16),
          _priceRow("Deposit Price (RM)", depositController, (val) => depositPrice = double.tryParse(val), prop?.deposit),

          const SizedBox(height: 28),
          _actionButton("Submit Contract", Colors.green, true, () async {
             // Validation here...
             await RentService.uploadContract(
               userId: AppUser().id!,
               requestId: request!.id,
               contractFile: uploadedContract.first,
               gracePeriodDays: gracePeriodDays,
               rentalPrice: rentalPrice,
               depositPrice: depositPrice
             );
             _loadRequest();
          }),
        ] else if (request!.currentStep == 2 && !isOwner)
          _waitingText("Waiting for owner to upload contract..."),
        
        if (request!.currentStep > 2)
          const Center(child: Text("Contract Uploaded. Proceed to next step.")),
      ],
    );
  }

  // --- STEP 3: Signing ---
  Widget _step3() {
    final step2Docs = request!.documents.where((doc) => doc.stepNumber == 2).toList();
    final bool isTenant = AppUser().id == request!.tenantId;
    List<XFile> signedFile = [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader("Contract Signing", "Step 3"),
        _docSection("Uploaded Contract", step2Docs),
        const SizedBox(height: 30),

        if (request!.currentStep == 3 && isTenant) ...[
          const Text("Upload Signed Contract", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          XFileUploadWidget(maxFiles: 1, onFilesChanged: (f) => signedFile = f),
          const SizedBox(height: 20),
          _actionButton("Submit Signed Contract", Colors.green, true, () async {
             if (signedFile.isNotEmpty) {
               await RentService.uploadContract(
                 userId: AppUser().id!,
                 requestId: request!.id,
                 contractFile: signedFile.first
               );
               _loadRequest();
             }
          }),
        ] else if (request!.currentStep == 3 && !isTenant)
          _waitingText("Waiting for tenant to sign..."),
          
        if (request!.currentStep > 3)
           const Center(child: Text("Signed Contract Uploaded.")),
      ],
    );
  }

  // --- STEP 4: Approval ---
Widget _step4() {
    final signedDocs = request!.documents.where((doc) => doc.stepNumber == 3).toList();
    final bool isOwner = AppUser().id != request!.tenantId;

    // Ensure we have a valid default value (1-3) for the dropdown
    int currentGrace = (gracePeriodDays != null && gracePeriodDays! >= 1 && gracePeriodDays! <= 3) 
        ? gracePeriodDays! 
        : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader("Contract Approval", "Step 4"),
        _docSection("Signed Contract", signedDocs),
        const SizedBox(height: 30),

        if (request!.currentStep == 4 && isOwner) ...[
          // --- Grace Period Picker ---
          const Text(
            "Set Payment Grace Period", 
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: currentGrace,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: [1, 2, 3].map((days) => DropdownMenuItem(
              value: days,
              child: Text("$days Days"),
            )).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => gracePeriodDays = val);
              }
            },
          ),
          const SizedBox(height: 20),

          // --- Action Buttons ---
          Row(
            children: [
              Expanded(
                child: _actionButton("Reject", Colors.red, false, () async {
                  await RentService.handleContractApproval(
                    requestId: request!.id, 
                    isApproved: false
                  );
                  _loadRequest();
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionButton("Approve", Colors.green, true, () async {
                  await RentService.handleContractApproval(
                    requestId: request!.id, 
                    isApproved: true, 
                    gracePeriodDays: currentGrace 
                  ); 
                  _loadRequest();
                }),
              ),
            ],
          ),
        ] else if (request!.currentStep == 4 && !isOwner)
          _waitingText("Waiting for owner approval..."),
          
        if (request!.currentStep > 4)
           const Center(child: Text("Contract Approved.")),
      ],
    );
  }

  // --- STEP 5: Payment ---
  Widget _step5() {
    final bool isTenant = AppUser().id == request!.tenantId;
    
    // Only show if loaded
    if (priceDetails == null && request!.currentStep == 5) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader("Payment", "Step 5"),
        
        if (priceDetails != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _kvRow("First Month Rent", "RM ${priceDetails!.price}"),
                const SizedBox(height: 8),
                _kvRow("Deposit", "RM ${priceDetails!.deposit}"),
                const Divider(height: 24),
                _kvRow("Total Due", "RM ${priceDetails!.price + priceDetails!.deposit}", isBold: true),
                
                // --- NEW: Pay Before Date Message ---
                if (request!.firstPaymentDue != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: (0.05)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_alarm, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          "Pay before ${request!.firstPaymentDue!.toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.red
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (request!.currentStep == 5 && isTenant)
          _actionButton("Pay Now", Colors.green, true, () async {
             await RentService.payFirstPayment(requestId: request!.id);
             _loadRequest();
          })
        else if (request!.currentStep == 5 && !isTenant)
          _waitingText("Waiting for payment..."),
      ],
    );
  }
  Widget _stepHeader(String title, String subtitle) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _docSection(String title, List<RequestDocument> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        docs.isEmpty
            ? const Text("No documents.", style: TextStyle(fontStyle: FontStyle.italic))
            : FileList(files: docs, shrinkWrap: true, physics: const NeverScrollableScrollPhysics()),
      ],
    );
  }

  Widget _waitingText(String text) {
    return Center(child: Text(text, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)));
  }

  Widget _actionButton(String text, Color color, bool filled, VoidCallback onTap) {
    return filled
        ? ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(text, style: TextStyle(color: color)),
          );
  }

  Widget _priceRow(String label, TextEditingController ctrl, Function(String) onChanged, double? defaultVal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: onChanged,
              ),
            ),
            if (defaultVal != null) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ctrl.text = defaultVal.toStringAsFixed(0);
                  onChanged(defaultVal.toString());
                },
                child: const Text("Default"),
              ),
            ]
          ],
        ),
      ],
    );
  }
  
  Widget _inputField(String hint, Function(String) onChanged) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _kvRow(String key, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}