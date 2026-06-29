import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/di/injection.dart';

class PaymentCard {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String bankName;

  PaymentCard({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.bankName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardNumber': cardNumber,
    'cardHolder': cardHolder,
    'expiryDate': expiryDate,
    'bankName': bankName,
  };

  factory PaymentCard.fromJson(Map<String, dynamic> json) => PaymentCard(
    id: json['id'] as String,
    cardNumber: json['cardNumber'] as String,
    cardHolder: json['cardHolder'] as String,
    expiryDate: json['expiryDate'] as String,
    bankName: json['bankName'] as String,
  );
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  static const String _storageKey = 'saved_payment_cards';
  List<PaymentCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final prefs = getIt<SharedPreferences>();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        setState(() {
          _cards = decoded
              .map((item) => PaymentCard.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('[PaymentMethods] Error loading cards: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCards(List<PaymentCard> cards) async {
    try {
      final prefs = getIt<SharedPreferences>();
      final jsonStr = jsonEncode(cards.map((c) => c.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
      setState(() {
        _cards = cards;
      });
    } catch (e) {
      debugPrint('[PaymentMethods] Error saving cards: $e');
    }
  }

  void _showAddCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetCtx) {
        return _AddCardForm(
          existingCards: _cards,
          onSave: (newCard) async {
            final updated = List<PaymentCard>.from(_cards)..add(newCard);
            await _saveCards(updated);
          },
        );
      },
    );
  }

  void _confirmDeleteCard(PaymentCard card) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Xóa thẻ',
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thẻ ${card.bankName} kết thúc bằng ${card.cardNumber.substring(card.cardNumber.length - 4)} không?',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final updated = _cards.where((c) => c.id != card.id).toList();
              await _saveCards(updated);
            },
            child: Text(
              'Xóa',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String number) {
    if (number.length < 4) return number;
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('  ');
      }
      buffer.write(number[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'PHƯƠNG THỨC THANH TOÁN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: cs.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: cs.primary,
                strokeWidth: 2,
              ),
            )
          : _cards.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return _buildCreditCard(card);
              },
            ),
      bottomNavigationBar: _cards.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: _showAddCardSheet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('THÊM THẺ THANH TOÁN'),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onSurface.withValues(alpha: 0.03),
              ),
              child: Icon(
                LucideIcons.creditCard,
                size: 40,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có phương thức thanh toán',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lưu thẻ ATM nội địa hoặc thẻ tín dụng để thực hiện thanh toán nhanh hơn khi đặt hàng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddCardSheet,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Thêm thẻ mới'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardChip(ColorScheme cs) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Horizontal division lines
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(height: 1, color: cs.onSurface.withValues(alpha: 0.15)),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(height: 1, color: cs.onSurface.withValues(alpha: 0.15)),
          ),
          // Vertical division lines
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: cs.onSurface.withValues(alpha: 0.15)),
          ),
          Positioned(
            left: 28,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: cs.onSurface.withValues(alpha: 0.15)),
          ),
          // Inner goldish/silver design loop
          Center(
            child: Container(
              width: 14,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(PaymentCard card) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14141F) : const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 0.8),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.bankName.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  Text(
                    'ATM NỘI ĐỊA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                    onPressed: () => _confirmDeleteCard(card),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCardChip(cs),
              const SizedBox(width: 12),
              Transform.rotate(
                angle: 90 * 3.14159 / 180,
                child: Icon(
                  Icons.wifi,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            _formatCardNumber(card.cardNumber),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              letterSpacing: 1.2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHỦ THẺ',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.cardHolder.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'HẠN DÙNG',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.expiryDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCardForm extends StatefulWidget {
  final ValueChanged<PaymentCard> onSave;
  final List<PaymentCard> existingCards;

  const _AddCardForm({
    required this.onSave,
    required this.existingCards,
  });

  @override
  State<_AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<_AddCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _bankController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _fillDemoData() {
    setState(() {
      _numberController.text = '9704198526191432198';
      _holderController.text = 'NGUYEN VAN A';
      _expiryController.text = '07/15';
      _bankController.text = 'NCB';
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cardNumberOnly = _numberController.text.trim().replaceAll(' ', '');
      
      final isDuplicate = widget.existingCards.any(
        (c) => c.cardNumber == cardNumberOnly,
      );
      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thẻ này đã tồn tại trong danh sách!'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final card = PaymentCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardNumber: cardNumberOnly,
        cardHolder: _holderController.text.trim().toUpperCase(),
        expiryDate: _expiryController.text.trim(),
        bankName: _bankController.text.trim(),
      );
      widget.onSave(card);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: bottomPadding + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'THÊM THẺ MỚI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _fillDemoData,
                    icon: const Icon(LucideIcons.bolt, size: 14),
                    label: const Text('Điền nhanh NCB Demo'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.secondary,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _bankController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tên Ngân hàng',
                  hintText: 'Ví dụ: NCB, VCB, Techcombank',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên ngân hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Số thẻ ATM / Tín dụng',
                  hintText: 'Nhập dãy số trên mặt thẻ',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số thẻ';
                  }
                  if (val.trim().length < 12) {
                    return 'Số thẻ không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _holderController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Tên chủ thẻ',
                        hintText: 'NGUYEN VAN A',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nhập tên';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hạn dùng',
                        hintText: '07/15',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nhập hạn';
                        }
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(val)) {
                          return 'Định dạng MM/YY';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  child: const Text('LƯU THẺ THANH TOÁN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
