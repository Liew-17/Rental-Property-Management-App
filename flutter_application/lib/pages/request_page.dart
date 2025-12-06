import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/file_list.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/services/rent_service.dart';
import 'package:flutter_application/theme.dart';

class RequestPage extends StatefulWidget {
  final int requestId;

  const RequestPage({super.key, required this.requestId});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  Request? request;
  int selectedStep = 1;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final fetchedRequest = await RentService.getRentRequest(widget.requestId);
    if (fetchedRequest != null) {
      setState(() {
        request = fetchedRequest;
        selectedStep = fetchedRequest.currentStep; // start at current step
        loading = false;
      });
    } else {
      // Handle request not found
      setState(() {
        loading = false;
      });

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request not found")),
        );
      }
    }
  }

  void _onStepSelected(int step) {
    if (request == null) return;
    if (step <= 5/* change to request!.currentStep later*/) {
      setState(() { 
        selectedStep = step;
      });
    }
  }

  Widget _buildStepContent() {

    switch (selectedStep) {
      case 1:
        return _step1();
      case 2:
        return Center(child: Text("Step 2"));
      case 3:
        return Center(child: Text("Step 3"));
      case 4:
        return Center(child: Text("Step 4"));
      case 5:
        return Center(child: Text("Step 5"));
      default:
        return Center(child: Text("Unknown Step"));
    }
  }

  Widget _buildProgressBar() {
    if (request == null) return SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        int stepNumber = index + 1;
        bool isCompleted = stepNumber < selectedStep;
        bool isCurrent = stepNumber == selectedStep;
        bool isEnabled = stepNumber <= 5; //request!.currentStep;

        return GestureDetector(
          onTap: isEnabled ? () => _onStepSelected(stepNumber) : null,
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                child: Text(
                  "$stepNumber",
                  style: TextStyle(
                    color: isCompleted || isCurrent ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Step $stepNumber",
                style: TextStyle(
                  fontSize: 12,
                  color: isEnabled ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }


  Widget _step1(){
    if(request == null) {
      return Center(child: CircularProgressIndicator());
    }
      
    final step1Docs = request!.documents.where((doc) => doc.stepNumber == 1).toList();
    
    if (step1Docs.isEmpty) {
      return const Center(child: Text("No files for Step 1."));
    }

    return Column(
      children: [
        Text("Step 1 Files"),

        FileList(files: step1Docs,shrinkWrap: true,physics: NeverScrollableScrollPhysics())

      ],
    );
  }

  Widget _Step2(){
    return SizedBox(width: 10,height: 500,);
  }

  Widget _Step3(){
    return SizedBox(width: 10,height: 500,);
  }

  Widget _Step4(){
    return SizedBox(width: 10,height: 500,);
  }

  Widget _Step5(){
    return SizedBox(width: 10,height: 500,);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rent Request #${widget.requestId}", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          scrolledUnderElevation: 0,    
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : request == null
              ? Center(child: Text("Request not found"))
              : SingleChildScrollView(   // <- scroll is now outer
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        _buildProgressBar(),
                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: _buildStepContent(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }



}
