
import 'package:flutter/material.dart';
import '../animals/create_post_screen.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _amountController = TextEditingController();

  int? _selectedAmount;
  bool _isCustomAmount = false;

  final List<int> _amounts = [500, 1000, 2000, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustomAmount = false;
      _amountController.clear();
    });
  }

  void _selectCustomAmount() {
    setState(() {
      _selectedAmount = null;
      _isCustomAmount = true;
    });
  }

  void _donate() {
    final amount = _isCustomAmount
        ? int.tryParse(_amountController.text.trim())
        : _selectedAmount;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid donation amount'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected donation: Rs. $amount'),
      ),
    );

    // Payment gateway integration will be added later.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawlyColors.softCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: PawlyColors.espressoBrown,
        ),
        title: const Text(
          'Make a Donation',
          style: TextStyle(
            color: PawlyColors.espressoBrown,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                size: 80,
                color: PawlyColors.burntOrange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Give Love. Save Lives.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: PawlyColors.espressoBrown,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your donation helps rescued animals '
                'receive food, shelter and medical care.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: PawlyColors.espressoBrown,
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Choose a donation amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PawlyColors.espressoBrown,
                ),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _amounts.map((amount) {
                  final selected = _selectedAmount == amount;

                  return SizedBox(
                    width: 145,
                    child: OutlinedButton(
                      onPressed: () => _selectAmount(amount),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? PawlyColors.burntOrange
                            : Colors.white,
                        foregroundColor: selected
                            ? Colors.white
                            : PawlyColors.espressoBrown,
                        side: const BorderSide(
                          color: PawlyColors.burntOrange,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                      ),
                      child: Text(
                        'Rs. $amount',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _selectCustomAmount,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _isCustomAmount
                      ? PawlyColors.burntOrange
                      : Colors.white,
                  foregroundColor: _isCustomAmount
                      ? Colors.white
                      : PawlyColors.espressoBrown,
                  side: const BorderSide(
                    color: PawlyColors.burntOrange,
                  ),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Enter Custom Amount'),
              ),

              if (_isCustomAmount) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Donation Amount (LKR)',
                    prefixText: 'Rs. ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _donate,
                icon: const Icon(Icons.favorite_rounded),
                label: const Text('Continue to Donate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PawlyColors.burntOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
