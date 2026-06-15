import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/address/data/models/address_model.dart';
import 'package:mobile/src/features/address/presentation/state/address_cubit.dart';
import 'package:mobile/src/features/address/presentation/state/address_state.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/edit_address_modal.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';

class AddressesPage extends StatefulWidget {
  final bool selectMode;
  const AddressesPage({super.key, this.selectMode = false});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  late final AddressCubit _addressCubit;

  @override
  void initState() {
    super.initState();
    _addressCubit = getIt<AddressCubit>()..fetchAddresses();
  }

  @override
  void dispose() {
    _addressCubit.close();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? AppColors.accentPink : AppColors.brandBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddEditAddressModal({AddressModel? address}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditAddressPage(
          initialName: address?.fullName ?? '',
          initialPhone: address?.phone ?? '',
          initialProvince: address?.province,
          initialDistrict: address?.district,
          initialWard: address?.ward,
          initialDetail: address?.detail,
          initialSaveAsDefault: address?.isDefault ?? false,
          onSave:
              (name, phone, province, district, ward, detail, saveAsDefault) {
                if (address == null) {
                  _addressCubit.createAddress(
                    fullName: name,
                    phone: phone,
                    province: province,
                    district: district,
                    ward: ward,
                    detail: detail,
                    isDefault: saveAsDefault,
                  );
                } else {
                  _addressCubit.updateAddress(
                    id: address.id,
                    fullName: name,
                    phone: phone,
                    province: province,
                    district: district,
                    ward: ward,
                    detail: detail,
                    isDefault: saveAsDefault,
                  );
                }
              },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        BlocListener<AddressCubit, AddressState>(
          bloc: _addressCubit,
          listener: (context, state) {
            if (state is AddressActionSuccess) {
              _showSnackBar(state.message);
            } else if (state is AddressError) {
              if (_addressCubit.state is AddressLoaded) {
                _showSnackBar(state.message, isError: true);
              }
            }
          },
        ),
      ],
      child: BlocBuilder<AddressCubit, AddressState>(
        bloc: _addressCubit,
        builder: (context, state) {
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          final isLoaded =
              state is AddressLoaded || _addressCubit.state is AddressLoaded;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: cs.onSurface,
                  size: 22,
                ),
              ),
              title: Text(
                widget.selectMode ? "Chọn địa chỉ giao hàng" : "Địa chỉ đã lưu",
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            body: Stack(
              children: [
                if (state is AddressLoading && state is! AddressLoaded)
                  Center(child: CircularProgressIndicator(color: cs.primary))
                else if (isLoaded)
                  _buildAddressList(
                    (state is AddressLoaded)
                        ? state.addresses
                        : (_addressCubit.state as AddressLoaded).addresses,
                  )
                else if (state is AddressError)
                  ErrorIllustrationWidget(
                    message: state.message,
                    title: 'Không thể tải địa chỉ',
                    onRetry: () => _addressCubit.fetchAddresses(),
                  )
                else
                  Center(child: CircularProgressIndicator(color: cs.primary)),

                if (isLoaded) _buildAddButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressList(List<AddressModel> addresses) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textHigh = cs.onSurface;
    final textMid = cs.onSurfaceVariant;

    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.mapPin, size: 48, color: textMid),
            const SizedBox(height: 16),
            Text(
              "Bạn chưa có địa chỉ giao hàng nào",
              style: TextStyle(
                color: textHigh,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Bấm nút bên dưới để thêm mới",
              style: TextStyle(color: textMid, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: addresses.length,
      separatorBuilder: (context, index) =>
          Divider(color: cs.outlineVariant, thickness: 0.5, height: 32),
      itemBuilder: (context, index) {
        final address = addresses[index];
        return InkWell(
          onTap: widget.selectMode
              ? () => Navigator.pop(context, address)
              : () => _openAddEditAddressModal(address: address),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      address.fullName,
                      style: TextStyle(
                        color: textHigh,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      address.phone,
                      style: TextStyle(
                        color: textMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (address.isDefault) _buildDefaultBadge(cs),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  address.fullAddressText,
                  style: TextStyle(color: textMid, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!address.isDefault)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _addressCubit.setDefaultAddress(address.id);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Thiết lập mặc định",
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () =>
                          _openAddEditAddressModal(address: address),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Sửa",
                        style: TextStyle(
                          color: textMid,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => _showDeleteConfirmDialog(address.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Xóa",
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "Mặc định",
        style: TextStyle(
          color: cs.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        title: Text(
          "Xác nhận xóa",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa địa chỉ này?",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Hủy",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _addressCubit.deleteAddress(id);
            },
            child: const Text(
              "Xóa",
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 20 + bottomPadding,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => _openAddEditAddressModal(),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(32), // Fully rounded Pill Shape
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, color: cs.onPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "THÊM ĐỊA CHỈ MỚI",
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
