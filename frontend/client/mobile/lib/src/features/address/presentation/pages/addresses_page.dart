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
          onSave: (name, phone, province, district, ward, detail, saveAsDefault) {
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
    return BlocProvider.value(
      value: _addressCubit,
      child: BlocConsumer<AddressCubit, AddressState>(
        listener: (context, state) {
          if (state is AddressActionSuccess) {
            _showSnackBar(state.message);
          } else if (state is AddressError) {
            _showSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
              title: Text(
                widget.selectMode ? "Chọn địa chỉ giao hàng" : "Địa chỉ đã lưu",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            body: Stack(
              children: [
                if (state is AddressLoading && state is! AddressLoaded)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.champagne,
                    ),
                  )
                else if (state is AddressLoaded ||
                    _addressCubit.state is AddressLoaded)
                  _buildAddressList(
                    (state is AddressLoaded)
                        ? state.addresses
                        : (_addressCubit.state as AddressLoaded).addresses,
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.champagne,
                    ),
                  ),

                _buildAddButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressList(List<AddressModel> addresses) {
    if (addresses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.mapPin, size: 48, color: AppColors.textDim),
            SizedBox(height: 16),
            Text(
              "Bạn chưa có địa chỉ giao hàng nào",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Bấm nút bên dưới để thêm mới",
              style: TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: address.isDefault
                  ? AppColors.champagne
                  : AppColors.borderCardStrong,
              width: address.isDefault ? 1.0 : 0.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.selectMode
                ? () => Navigator.pop(context, address)
                : () => _openAddEditAddressModal(address: address),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.fullName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        address.phone,
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.champagne.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.champagne.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            "Mặc định",
                            style: TextStyle(
                              color: AppColors.champagne,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    address.fullAddressText,
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const Divider(color: AppColors.borderCardStrong, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!address.isDefault)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _addressCubit.setDefaultAddress(address.id);
                          },
                          child: const Text(
                            "Thiết lập mặc định",
                            style: TextStyle(
                              color: AppColors.brandBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () =>
                            _openAddEditAddressModal(address: address),
                        icon: const Icon(
                          LucideIcons.pencil,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                        label: const Text(
                          "Sửa",
                          style: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!address.isDefault)
                        TextButton.icon(
                          onPressed: () {
                            _showDeleteConfirmDialog(address.id);
                          },
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 14,
                            color: AppColors.error,
                          ),
                          label: const Text(
                            "Xóa",
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderCardStrong, width: 0.5),
        ),
        title: const Text(
          "Xác nhận xóa",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Bạn có chắc chắn muốn xóa địa chỉ này?",
          style: TextStyle(color: AppColors.slate400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.slate400),
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
    return Positioned(
      bottom: 20 + bottomPadding,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => _openAddEditAddressModal(),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.champagne,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.champagne.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, color: Colors.black, size: 20),
                SizedBox(width: 8),
                Text(
                  "THÊM ĐỊA CHỈ MỚI",
                  style: TextStyle(
                    color: Colors.black,
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
