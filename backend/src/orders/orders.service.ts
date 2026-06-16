import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { ActivityLogService } from 'src/activity-log/activity-log.service';
import { InventoriesService } from 'src/inventories/inventories.service';
import { CreateOrderDto } from './dto/create-order.dto';
import {
  OrderStatus,
  InventoryTransactionType,
  Prisma,
  Role,
  PaymentStatus,
  PaymentMethod,
  TransactionStatus,
} from '@prisma/client';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { PromotionService } from 'src/promotion/promotion.service';
import { NotificationService } from 'src/notification/notification.service';
import { ReviewCancelDto } from './dto/review-cancel.dto';
import { Cron, CronExpression } from '@nestjs/schedule';
import { FlashSaleService } from 'src/flash-sale/flash-sale.service';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);
  constructor(
    private prisma: PrismaService,
    private activityLogService: ActivityLogService,
    private inventoriesService: InventoriesService,
    private promotionService: PromotionService,
    private notificationService: NotificationService,
    private flashSaleService: FlashSaleService,
  ) { }

  /**
   * tạo đơn hàng mới từ giỏ hàng hoặc mua trực tiếp
   * 
   * xác thực các biến thể sản phẩm có tồn tại và còn đủ số lượng tồn kho
   * áp dụng voucher và tính toán tổng tiền thanh toán (bao gồm VAT)
   * tạo bản ghi Order, OrderItem và thiết lập trạng thái theo dõi ban đầu
   * khấu trừ số lượng tồn kho và cập nhật trạng thái sử dụng của voucher tùy theo phương thức thanh toán
   * làm sạch giỏ hàng bằng cách loại bỏ các sản phẩm đã được thanh toán
   */
  async createOrder(userId: string, data: CreateOrderDto) {
    const { items, voucherId, ...shippingInfor } = data;
    const variantIds = items.map((i) => i.variantId);

    // mảng lưu trạng thái
    // lưu lại danh sách các sản phẩm fs mà user đã trừ kho trên redis thành công - mua fs thành công
    const decrementedFlashSales: { variantId: string; quantity: number }[] = [];

    try {
      return await this.prisma.$transaction(async (tx) => {
        // lấy thông tin giá bán và tồn kho tại thời điểm mua
        // ngăn chặn việc gian lận hoặc thay đổi giá từ phía client
        const variants = await tx.productVariant.findMany({
          where: { id: { in: variantIds } },
          include: {
            product: { select: { name: true } },
          },
        });

        if (variants.length !== items.length) {
          throw new NotFoundException(
            'Một số sản phẩm không tồn tại trong hệ thống',
          );
        }

        // tính tổng giá trị tạm tính và kiểm tra tồn kho để đảm bảo cửa hàng có đủ số lượng sản phẩm cung ứng
        let totalAmount = 0;
        const orderItemsData: any[] = [];

        // tìm sản phẩm và kiểm tra tồn kho
        for (const item of items) {
          const variant = variants.find((v) => v.id === item.variantId);
          if (!variant) {
            throw new NotFoundException(
              `Sản phẩm với ID ${item.variantId} không tồn tại`,
            );
          }

          // chặn xử lý tạo đơn hàng nếu số lượng mua vượt quá số lượng tồn kho khả dụng của sản phẩm
          if (variant.stock < item.quantity) {
            throw new BadRequestException(
              `Sản phẩm ${variant.name} chỉ còn ${variant.stock} sản phẩm`,
            );
          }

          // kiểm tra sản phẩm này có đang chạy flash sale không
          // nếu luồng order bị lỗi - hủy toàn bộ các hành động trừ kho flash sale
          const flashSale = await this.flashSaleService.validateAndGetFlashSale(
            item.variantId,
            item.quantity,
            tx,
          );
          // nếu sp này đang được fs và trừ kho thành công
          // lưu vào temp arr
          if (flashSale) {
            decrementedFlashSales.push({ variantId: item.variantId, quantity: item.quantity });
          }
          // quyết định giá mua thực tế và cộng dồn tiền vào đơn hàng
          // nếu có chương trình flash sale thì lấy giá được giảm
          // không thì lấy giá gốc của biến thể
          const priceAtPurchase = flashSale ? flashSale.flashPrice : Number(variant.price);
          totalAmount += priceAtPurchase * item.quantity; // tổng tiền đơn

          orderItemsData.push({
            productVariantId: item.variantId,
            quantity: item.quantity,
            priceAtPurchase: new Prisma.Decimal(priceAtPurchase), // snap lại giá lúc user mua, tránh làm sai lệch lịch sử đơn hàng khi hết đợt flash sale
            productName: variant.product.name,
            variantName: variant.name,
          });
        }

        // mô hình giá đã bao gồm VAT
        const subtotal = totalAmount; // tổng tiền đã bao gồm thuế
        // trích xuất 8% thuế từ bên trong (8% theo mức thuế cho các sản phẩm phần cứng công nghệ hiện tại ở VN)
        const vatAmount = (subtotal / 1.08) * 0.08;
        const baseAmount = subtotal - vatAmount; // giá gốc chưa thuế

        let voucherDiscount = 0;

        // xác thực và tính toán giá trị được giảm từ voucher (nếu có áp dụng)
        if (voucherId) {
          const voucher = await this.promotionService.validateVoucherForCheckout(
            userId,
            voucherId,
            subtotal,
            tx,
          );
          voucherDiscount = this.promotionService.calculateVoucherDiscount(
            voucher,
            subtotal,
          );
        }

        const finalTotal = Math.max(0, subtotal - voucherDiscount);

        // khởi tạo đơn hàng chính thức và thực hiện tracking đơn
        const order = await tx.order.create({
          data: {
            userId,
            totalAmount: new Prisma.Decimal(finalTotal),
            ...shippingInfor,
            voucherDiscount: new Prisma.Decimal(voucherDiscount),
            items: {
              create: orderItemsData,
            },
            tracking: {
              create: {
                statusLabel: 'Đặt hàng thành công',
                description:
                  'Đơn hàng đã được hệ thống tiếp nhận và đang chờ xử lý',
              },
            },
          },
        });

        const isCOD =
          shippingInfor.paymentMethod === PaymentMethod.COD ||
          !shippingInfor.paymentMethod;

        // với COD voucher được đánh dấu sử dụng ngay
        // với thanh toán online, chỉ liên kết voucher vào đơn hàng tạm thời và sẽ hoàn trả lại 
        // nếu khách hàng hủy thanh toán hoặc giao dịch thất bại giữa chừng
        if (isCOD) {
          if (voucherId) {
            await this.promotionService.markVoucherUsed(
              userId,
              voucherId,
              order.id,
              tx,
            );
          }
        } else {
          if (voucherId) {
            await tx.userVoucher.update({
              where: { userId_voucherId: { userId, voucherId } },
              data: { orderId: order.id },
            });
          }
        }

        // trừ tồn kho thông qua InventoriesService để tự động ghi lại lịch sử giao dịch kho bán hàng
        for (const item of items) {
          await this.inventoriesService.adjustStock({
            variantId: item.variantId,
            type: InventoryTransactionType.SALE,
            quantity: item.quantity,
            referenceId: order.id,
            reason: `Trừ kho cho đơn hàng #${order.id.slice(0, 8)}`,
            tx,
          });
        }

        // giải phóng các item đã được mua khỏi giỏ hàng của user
        await tx.cartItem.deleteMany({
          where: {
            cart: { userId },
            productVariantId: { in: variantIds },
          },
        });

        return order;
      });
    } catch (error) {
      // hoàn trả tồn kho redis cho các sản phẩm flash sale đã trừ kho
      for (const df of decrementedFlashSales) {
        try {
          await this.flashSaleService.incrbyRedisStock(df.variantId, df.quantity);
        } catch (redisError) {
          this.logger.error(`Failed to rollback Redis stock for variant ${df.variantId}:`, redisError);
        }
      }
      throw error;
    }
  }

  /**
   * lấy lịch sử đơn hàng của người dùng hiện tại
   * dữ liệu được đính kèm chi tiết từng sản phẩm và tracking
   */
  async getMyOrders(
    userId: string,
    query: { page?: number; limit?: number; status?: OrderStatus },
  ) {
    const { page = 1, limit = 10, status } = query;

    const skip = (page - 1) * limit;

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where: {
          userId,
          // lọc theo trạng thái được chọn từ các tab hiển thị trên UI
          ...(status && { status }),
        },
        include: {
          items: {
            include: {
              productVariant: {
                include: {
                  product: {
                    // chỉ lấy các thông tin thiết yếu hiển thị danh sách sản phẩm trên UI
                    select: {
                      name: true,
                      thumbnailUrl: true,
                    },
                  },
                },
              },
            },
          },
          tracking: {
            orderBy: { createdAt: 'desc' },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: Number(limit),
      }),
      this.prisma.order.count({ where: { userId, ...(status && { status }) } }),
    ]);

    return {
      data: orders,
      meta: {
        total,
        page,
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  /**
   * lấy danh sách tất cả đơn hàng toàn hệ thống (admin/staff)
   * hỗ trợ tìm kiếm động theo mã đơn hàng, tên người nhận, SĐT và lọc theo trạng thái
   */
  async getAllOrders(query: {
    page?: number;
    limit?: number;
    status?: OrderStatus;
    paymentStatus?: PaymentStatus;
    paymentMethod?: PaymentMethod;
    createdFrom?: string;
    createdTo?: string;
    minTotal?: number;
    maxTotal?: number;
    cancelRequestOnly?: boolean;
    search?: string;
    userId?: string;
  }) {
    const {
      page = 1,
      limit = 10,
      status,
      paymentStatus,
      paymentMethod,
      createdFrom,
      createdTo,
      minTotal,
      maxTotal,
      cancelRequestOnly,
      search,
      userId,
    } = query;

    const skip = (page - 1) * limit;

    // điều kiện lọc
    // lọc theo trạng thái đơn hàng, trạng thái thanh toán, phương thức thanh toán,
    // userid, khoảng thời gian tạo đơn, khoảng giá, các đơn yêu cầu hủy và theo keyword tìm kiếm
    const whereCondition: Prisma.OrderWhereInput = {
      ...(status && { status }),
      ...(paymentStatus && { paymentStatus }),
      ...(paymentMethod && { paymentMethod }),
      ...(userId && { userId }),
      ...((createdFrom || createdTo) && {
        createdAt: {
          ...(createdFrom && { gte: new Date(createdFrom) }),
          ...(createdTo && { lte: new Date(createdTo) }),
        },
      }),
      ...((minTotal !== undefined || maxTotal !== undefined) && {
        totalAmount: {
          ...(minTotal !== undefined && { gte: minTotal }),
          ...(maxTotal !== undefined && { lte: maxTotal }),
        },
      }),
      ...(cancelRequestOnly && {
        tracking: {
          some: { statusLabel: 'Yêu cầu hủy' },
        },
      }),
      ...(search && {
        OR: [
          { id: { contains: search } },
          { receiverName: { contains: search } },
          { receiverPhone: { contains: search } },
        ],
      }),
    };

    const [orders, total] = await Promise.all([
      this.prisma.order.findMany({
        where: whereCondition,
        include: {
          user: {
            // chỉ lấy các thông tin định danh tối thiểu của user đặt mua
            select: {
              email: true,
              profile: {
                select: { fullName: true },
              },
            },
          },
          // tổng số món hàng trong đơn
          _count: { select: { items: true } },
          tracking: {
            orderBy: { createdAt: 'desc' },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: Number(limit),
      }),

      this.prisma.order.count({ where: whereCondition }),
    ]);

    return {
      data: orders,
      meta: {
        total,
        page,
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  async getOrderDetail(userId: string, id: string, role?: Role) {
    const whereCondition: Prisma.OrderWhereInput = { id };
    if (role !== Role.ADMIN && role !== Role.STAFF) {
      whereCondition.userId = userId;
    }

    const order = await this.prisma.order.findFirst({
      where: whereCondition,
      include: {
        items: {
          include: {
            productVariant: {
              include: {
                product: {
                  select: {
                    name: true,
                    thumbnailUrl: true,
                  },
                },
              },
            },
          },
        },
        tracking: {
          orderBy: { createdAt: 'asc' },
        },
        transaction: true,
      },
    });

    if (!order) throw new NotFoundException('Không tìm thấy đơn hàng này');

    return order;
  }

  /**
   * cập nhật trạng thái đơn hàng và tự động đồng bộ hóa các tài nguyên liên quan
   * thực hiện hoàn trả/khấu trừ kho, hoàn voucher, cập nhật hóa đơn thanh toán
   * và gửi thông báo trạng thái đơn hàng tới client
   */
  async updateOrderStatus(orderId: string, data: UpdateOrderStatusDto) {
    const { status, description } = data;

    const result = await this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        include: { items: true },
      });
      if (!order) throw new NotFoundException('Không tìm thấy đơn hàng');

      // bỏ qua các bước xử lý phía dưới nếu trạng thái thực tế không có sự thay đổi
      if (order.status === status) {
        return { order, statusChanged: false };
      }

      // các trạng thái được định nghĩa là hoàn trả lại tài nguyên cho hệ thống
      const refundStatuses: OrderStatus[] = [
        OrderStatus.CANCELLED,
        OrderStatus.RETURNED,
        OrderStatus.FAILED,
      ];
      const isNewRefundStatus = refundStatuses.includes(status as OrderStatus);
      const isCurrentRefundStatus = refundStatuses.includes(
        order.status as OrderStatus,
      );

      // chuyển từ trạng thái hoạt động sang trạng thái hủy/trả hàng: cần hoàn trả kho và voucher
      if (isNewRefundStatus && !isCurrentRefundStatus) {
        await this.rollbackPromotion(orderId, order.userId, tx);

        for (const item of order.items) {
          const refundType =
            status === OrderStatus.CANCELLED || status === OrderStatus.FAILED
              ? InventoryTransactionType.ORDER_CANCEL
              : InventoryTransactionType.RETURN;
          await this.inventoriesService.adjustStock({
            variantId: item.productVariantId,
            type: refundType,
            quantity: item.quantity,
            referenceId: orderId,
            reason: `Hoàn kho từ đơn hàng #${orderId.slice(0, 8)} - ${status}`,
            tx,
          });
        }
      }
      // khôi phục đơn hàng từ trạng thái hủy về hoạt động: cần thực hiện trừ lại kho hàng
      else if (!isNewRefundStatus && isCurrentRefundStatus) {
        for (const item of order.items) {
          await this.inventoriesService.adjustStock({
            variantId: item.productVariantId,
            type: InventoryTransactionType.SALE,
            quantity: item.quantity,
            referenceId: orderId,
            reason: `Trừ lại kho khi khôi phục đơn hàng #${orderId.slice(0, 8)}`,
            tx,
          });
        }
      }

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: { status },
      });

      // nếu đơn hàng bị hủy bỏ/trả hàng và khách hàng đã thanh toán online, chuyển trạng thái thanh toán sang REFUNDED
      if (isNewRefundStatus) {
        if (order.paymentStatus === PaymentStatus.PAID) {
          await tx.order.update({
            where: { id: orderId },
            data: { paymentStatus: PaymentStatus.REFUNDED },
          });

          await tx.transaction.updateMany({
            where: { orderId: orderId },
            data: { status: TransactionStatus.FAILED },
          });
        }
      }
      // COD chỉ được xem là thanh toán thành công khi shipper báo đã giao hàng thành công (DELIVERED)
      else if (
        status === OrderStatus.DELIVERED &&
        order.paymentMethod === PaymentMethod.COD
      ) {
        await tx.order.update({
          where: { id: orderId },
          data: { paymentStatus: PaymentStatus.PAID },
        });

        await tx.transaction.upsert({
          where: { orderId: orderId },
          update: {
            status: TransactionStatus.SUCCESS,
            amount: order.totalAmount,
            provider: 'CASH',
            paymentMethod: order.paymentMethod,
            description: `Thanh toán COD cho đơn hàng #${orderId.slice(0, 8)}`,
            paymentDate: new Date(),
          },
          create: {
            orderId: orderId,
            status: TransactionStatus.SUCCESS,
            amount: order.totalAmount,
            provider: 'CASH',
            paymentMethod: order.paymentMethod,
            description: `Thanh toán COD cho đơn hàng #${orderId.slice(0, 8)}`,
            paymentDate: new Date(),
          },
        });
      }

      await tx.orderTracking.create({
        data: {
          orderId,
          statusLabel: this.mapStatusToLabel(status),
          description:
            description || `Đơn hàng đã được chuyển sang trạng thái ${status}`,
        },
      });

      return { order: updatedOrder, statusChanged: true };
    });

    if (result.statusChanged) {
      this.sendOrderStatusNotification(
        result.order.userId,
        result.order.id,
        status,
      );
    }

    return result.order;
  }

  private sendOrderStatusNotification(
    userId: string,
    orderId: string,
    status: OrderStatus,
  ) {
    const message = this.mapStatusToPushMessage(status);
    if (!message) return;

    void this.notificationService.sendToUser(userId, {
      notification: message,
      data: {
        type: 'order',
        orderId,
        route: `/orders/${orderId}`,
      },
    });
  }

  private mapStatusToPushMessage(
    status: OrderStatus,
  ): { title: string; body: string } | null {
    const messages: Partial<
      Record<OrderStatus, { title: string; body: string }>
    > = {
      [OrderStatus.CONFIRMED]: {
        title: 'Xác nhận đơn hàng',
        body: 'Đơn hàng của bạn đã được xác nhận.',
      },
      [OrderStatus.SHIPPING]: {
        title: 'Đơn hàng đang vận chuyển',
        body: 'Đơn hàng của bạn đang trên đường giao.',
      },
      [OrderStatus.DELIVERED]: {
        title: 'Đơn hàng đã giao',
        body: 'Đơn hàng của bạn đã giao thành công. Vui lòng xác nhận đã nhận hàng.',
      },
      [OrderStatus.COMPLETED]: {
        title: 'Đơn hàng hoàn tất',
        body: 'Đơn hàng của bạn đã hoàn tất. Cảm ơn bạn đã mua sắm tại GearHub!',
      },
      [OrderStatus.CANCELLED]: {
        title: 'Hủy đơn hàng',
        body: 'Đơn hàng của bạn đã bị hủy.',
      },
      [OrderStatus.FAILED]: {
        title: 'Giao hàng thất bại',
        body: 'Đơn hàng của bạn không thể tiếp tục giao.',
      },
    };

    return messages[status] ?? null;
  }

  private mapStatusToLabel(status: OrderStatus): string {
    const labels = {
      [OrderStatus.PENDING]: 'Chờ xác nhận',
      [OrderStatus.CONFIRMED]: 'Đã xác nhận',
      [OrderStatus.PROCESSING]: 'Đang đóng gói',
      [OrderStatus.SHIPPING]: 'Đang giao hàng',
      [OrderStatus.DELIVERED]: 'Giao hàng thành công',
      [OrderStatus.CANCELLED]: 'Đã hủy đơn',
      [OrderStatus.RETURNED]: 'Khách trả hàng',
      [OrderStatus.FAILED]: 'Giao hàng thất bại',
      [OrderStatus.COMPLETED]: 'Đã hoàn thành',
    };
    return labels[status] || status;
  }

  /**
   * xử lý yêu cầu hủy đơn hàng từ phía client
   * phân loại logic xử lý theo trạng thái hiện tại của đơn hàng:
   * - PENDING / CONFIRMED: Hủy đơn tự động, tự động hoàn trả kho và voucher
   * - PROCESSING: ghi nhận yêu cầu hủy vào tracking chờ admin duyệt
   * - các trạng thái khác: chặn thao tác và báo lỗi
   */
  async cancelOrder(userId: string, id: string, reason: string) {
    return await this.prisma.$transaction(async (tx) => {
      // xác thực quyền sở hữu đơn hàng của chính người dùng gửi yêu cầu để chặn việc can thiệp đơn hàng chéo
      const order = await tx.order.findFirst({
        where: {
          id,
          userId,
        },
        include: { items: true },
      });
      if (!order) throw new NotFoundException('Đơn hàng không tồn tại');

      const allowedStatusesForInstantCancel: OrderStatus[] = [OrderStatus.PENDING, OrderStatus.CONFIRMED];

      // đơn hàng chưa đóng gói / giao vận chuyển: cho phép hệ thống hủy tự động ngay lập tức
      if (allowedStatusesForInstantCancel.includes(order.status)) {
        // kiểm tra nếu là đơn hàng đã thanh toán bằng cổng thanh toán
        const isPaidGateway = order.paymentMethod === PaymentMethod.PAYMENT_GATEWAY && order.paymentStatus === PaymentStatus.PAID;

        if (isPaidGateway) {
          const latestTracking = await tx.orderTracking.findFirst({
            where: { orderId: id },
            orderBy: { createdAt: 'desc' },
          });

          // chặn việc gửi trùng nhiều yêu cầu hủy liên tiếp làm nhiễu dữ liệu xử lý
          if (latestTracking && latestTracking.statusLabel === 'Yêu cầu hủy') {
            throw new BadRequestException('Bạn đã gửi yêu cầu hủy cho đơn hàng này rồi, vui lòng chờ Admin duyệt.');
          }

          // log yêu cầu hủy
          await tx.orderTracking.create({
            data: {
              orderId: id,
              statusLabel: 'Yêu cầu hủy',
              description: reason,
            },
          });

          const updatedOrder = await tx.order.findUnique({
            where: { id },
            include: {
              items: true,
              tracking: { orderBy: { createdAt: 'desc' } },
            },
          });

          return updatedOrder;
        } else {
          await this.rollbackPromotion(id, userId, tx);

          // cộng lại số lượng tồn kho khả dụng cho các biến thể sản phẩm
          for (const item of order.items) {
            await this.inventoriesService.adjustStock({
              variantId: item.productVariantId,
              type: InventoryTransactionType.ORDER_CANCEL,
              quantity: item.quantity,
              referenceId: order.id,
              reason: `Hoàn kho - đơn hàng bị hủy bởi người mua`,
              tx,
            });
          }

          const updatedOrder = await tx.order.update({
            where: { id },
            data: { status: OrderStatus.CANCELLED },
          });

          // ghi lại lý do hủy cụ thể
          await tx.orderTracking.create({
            data: {
              orderId: id,
              statusLabel: 'Đã hủy đơn',
              description: `Hủy bởi người mua. Lý do: ${reason}`,
            },
          });

          return updatedOrder;
        }
      } else {
        throw new BadRequestException(
          'Đơn hàng đang ở trạng thái không thể hủy.',
        );
      }
    });
  }

  /**
   * phê duyệt hoặc từ chối yêu cầu hủy đơn hàng từ phía khách hàng
   * - đồng ý: chuyển đơn sang CANCELLED, kích hoạt luồng hoàn kho và hoàn voucher tự động
   * - từ chối: tạo tracking ghi nhận từ chối và gửi thông báo đẩy giải thích lý do cho khách hàng
   */
  async reviewCancelRequest(id: string, data: ReviewCancelDto) {
    const { approve, reason } = data;

    const order = await this.prisma.order.findUnique({
      where: { id },
    });

    if (!order) throw new NotFoundException('Đơn hàng không tồn tại');

    // yêu cầu hủy hợp lệ đối với đơn ở trạng thái PENDING hoặc CONFIRMED
    const allowedStatusesForCancelRequest: OrderStatus[] = [OrderStatus.PENDING, OrderStatus.CONFIRMED];
    if (!allowedStatusesForCancelRequest.includes(order.status)) {
      throw new BadRequestException('Đơn hàng không ở trạng thái chờ duyệt hủy');
    }

    const latestTracking = await this.prisma.orderTracking.findFirst({
      where: { orderId: id },
      orderBy: { createdAt: 'desc' },
    });

    // chỉ thực hiện xử lý nếu thực sự tồn tại yêu cầu hủy chưa được giải quyết gần nhất
    if (!latestTracking || latestTracking.statusLabel !== 'Yêu cầu hủy') {
      throw new BadRequestException('Đơn hàng không có yêu cầu hủy nào cần xử lý');
    }

    if (approve) {
      // nếu là đơn hàng online đã thanh toán, yêu cầu sử dụng tính năng hoàn tiền VNPay để duyệt hủy
      if (order.paymentMethod === PaymentMethod.PAYMENT_GATEWAY && order.paymentStatus === PaymentStatus.PAID) {
        throw new BadRequestException('Vui lòng sử dụng tính năng Hoàn tiền VNPay để hủy đơn hàng này');
      }

      const cancelReason = reason ? `Chấp nhận yêu cầu hủy. Lý do: ${reason}` : 'Chấp nhận yêu cầu hủy';

      // chấp nhận: gọi cập nhật trạng thái sang CANCELLED để tự động kích hoạt hoàn kho và hoàn voucher
      return this.updateOrderStatus(id, {
        status: OrderStatus.CANCELLED,
        description: cancelReason,
      });
    } else {
      const rejectReason = reason ? `Từ chối yêu cầu hủy. Lý do: ${reason}` : 'Từ chối yêu cầu hủy';

      // từ chối: tạo bản ghi nhật trình từ chối hủy để khách hàng có thể đọc được trên app
      await this.prisma.orderTracking.create({
        data: {
          orderId: id,
          statusLabel: 'Từ chối hủy đơn',
          description: rejectReason,
        },
      });

      // gửi thông báo đẩy về client
      void this.notificationService.sendToUser(order.userId, {
        notification: {
          title: 'Yêu cầu hủy đơn bị từ chối',
          body: `Yêu cầu hủy đơn #${order.id.slice(0, 8).toUpperCase()} đã bị cửa hàng từ chối.`,
        },
        data: {
          type: 'order',
          orderId: order.id,
          route: `/orders/${order.id}`,
        },
      });

      return this.prisma.order.findUnique({
        where: { id },
        include: {
          items: true,
          tracking: { orderBy: { createdAt: 'desc' } },
        },
      });
    }
  }

  // lấy top sản phẩm bán chạy nhất (theo biến thể)
  async getTopSellingProducts(limit = 5) {
    // lấy tổng biến thể xuất hiện trong toàn bộ đơn hàng - gom nhóm theo id
    const topVariants = await this.prisma.orderItem.groupBy({
      by: ['productVariantId'],
      _sum: { quantity: true },
    });

    const variantSales = await Promise.all(
      topVariants.map(async (item) => {
        const variant = await this.prisma.productVariant.findUnique({
          where: { id: item.productVariantId },
          select: {
            productId: true,
            imageUrl: true,
            product: {
              select: {
                id: true,
                name: true,
                thumbnailUrl: true,
              },
            },
          },
        });

        // trả về thông tin cha của biến thể và tổng bán
        return {
          productId: variant?.productId,
          productName: variant?.product?.name,
          imageUrl: variant?.imageUrl || variant?.product?.thumbnailUrl,
          totalSold: item._sum.quantity || 0,
        };
      }),
    );

    const productSales: Record<
      string,
      { name: string; imageUrl: string | null; totalSold: number }
    > = {};

    for (const item of variantSales) {
      if (!item.productId || !item.productName) continue;
      const prodId = item.productId;
      if (!productSales[prodId]) {
        productSales[prodId] = {
          name: item.productName,
          imageUrl: item.imageUrl || null,
          totalSold: 0,
        };
      }
      productSales[prodId].totalSold += item.totalSold;
    }

    return Object.values(productSales)
      .sort((a, b) => b.totalSold - a.totalSold)
      .slice(0, limit);
  }

  // thu thập số liệu thống kê tổng quan cho trang quản trị
  async getAdminStats() {
    const [revenue, orderCounts, refundedOrders, userCount, lowStockVariants, latestLogs] =
      await Promise.all([
        // chỉ tính các đơn hàng đã thanh toán thành công để phản ánh chính xác doanh thu thực tế, loại bỏ đơn ảo/hủy
        this.prisma.order.aggregate({
          _sum: { totalAmount: true },
          where: { paymentStatus: PaymentStatus.PAID },
        }),

        // phân nhóm theo trạng thái để thống kê số lượng đơn ở từng bước xử lý
        this.prisma.order.groupBy({
          by: ['status'],
          _count: { id: true },
        }),

        // tính các đơn hàng đã hoàn tiền
        this.prisma.order.count({
          where: { paymentStatus: PaymentStatus.REFUNDED },
        }),

        // chỉ đếm tài khoản khách hàng thực tế để đo lường quy mô và mức độ tăng trưởng tệp người dùng
        this.prisma.user.count({
          where: { role: Role.USER },
        }),

        // đếm các biến thể sản phẩm có số lượng tồn kho dưới 10 để đưa ra cảnh báo kịp thời cho admin nhập thêm hàng
        this.prisma.productVariant.count({
          where: { stock: { lt: 10 } },
        }),

        this.activityLogService.findAll({ page: 1, limit: 7 }),
      ]);

    const formattedOrders = orderCounts.reduce((acc, curr) => {
      acc[curr.status] = curr._count.id;
      return acc;
    }, {});

    // truy vấn dữ liệu xu hướng doanh thu và đơn hàng trong 7 ngày gần nhất để vẽ biểu đồ phân tích tăng trưởng ngắn hạn
    const trends = await this.getTrends(7);

    // tính toán tỷ lệ tăng trưởng của 7 ngày gần nhất và 7 ngày trước đó
    const now = new Date();

    // kì a
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(now.getDate() - 7);

    // kì b
    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(now.getDate() - 14);

    const [
      ordersCountA,
      ordersCountB,
      revenueA,
      revenueB,
      usersCountA,
      usersCountB,
    ] = await Promise.all([
      // số lượng đơn hàng
      this.prisma.order.count({
        where: { createdAt: { gte: sevenDaysAgo } }
      }),
      this.prisma.order.count({
        where: { createdAt: { gte: fourteenDaysAgo, lt: sevenDaysAgo } }
      }),
      // tổng doanh thu thực tế
      this.prisma.order.aggregate({
        _sum: { totalAmount: true },
        where: { paymentStatus: PaymentStatus.PAID, createdAt: { gte: sevenDaysAgo } }
      }),
      this.prisma.order.aggregate({
        _sum: { totalAmount: true },
        where: { paymentStatus: PaymentStatus.PAID, createdAt: { gte: fourteenDaysAgo, lt: sevenDaysAgo } }
      }),
      // lượng khách hàng đăng ký mới
      this.prisma.user.count({
        where: { role: Role.USER, createdAt: { gte: sevenDaysAgo } }
      }),
      this.prisma.user.count({
        where: { role: Role.USER, createdAt: { gte: fourteenDaysAgo, lt: sevenDaysAgo } }
      })
    ]);

    // tính tăng trưởng phần trăm
    const calculatePercentageChange = (current: number, previous: number): string => {
      if (previous === 0) {
        return current > 0 ? '+100%' : '0%';
      }
      const change = ((current - previous) / previous) * 100;
      const sign = change >= 0 ? '+' : '';
      return `${sign}${change.toFixed(1)}%`;
    };

    const ordersTrend = calculatePercentageChange(ordersCountA, ordersCountB);
    const revenueTrend = calculatePercentageChange(
      Number(revenueA._sum.totalAmount || 0),
      Number(revenueB._sum.totalAmount || 0)
    );
    // số lượng tài khoản mới
    const diffUsers = usersCountA - usersCountB;
    const usersTrend = diffUsers >= 0 ? `+${diffUsers}` : `${diffUsers}`;

    return {
      totalRevenue: revenue._sum.totalAmount || 0,
      ordersByStatus: formattedOrders,
      refundedOrders,
      totalUsers: userCount,
      lowStockAlert: lowStockVariants,
      revenueTrends: trends.revenue,
      orderTrends: trends.orders,
      latestLogs: latestLogs.data,
      ordersTrend,
      revenueTrend,
      usersTrend,
    };
  }

  // tính toán dữ liệu xu hướng doanh thu và lượng đơn hàng theo ngày
  private async getTrends(days: number) {
    const now = new Date();
    const startDate = new Date();
    startDate.setDate(now.getDate() - (days - 1));
    startDate.setHours(0, 0, 0, 0);

    // chỉ select các trường cần thiết để giảm tải lượng dữ liệu truyền tải từ db và tiết kiệm RAM
    const allOrders = await this.prisma.order.findMany({
      where: { createdAt: { gte: startDate } },
      select: {
        createdAt: true,
        totalAmount: true,
        paymentStatus: true,
      },
    });

    // khởi tạo map chứa đầy đủ các ngày trong khoảng thống kê
    //  để tránh việc bị thiếu hụt mốc thời gian trên biểu đồ của FE 
    // nếu ngày đó không phát sinh đơn hàng
    const statsMap = new Map<string, { orders: number; revenue: number }>();

    for (let i = 0; i < days; i++) {
      const d = new Date(startDate);
      d.setDate(d.getDate() + i);
      const dateStr = d.toLocaleDateString('vi-VN', {
        day: '2-digit',
        month: '2-digit',
      });
      statsMap.set(dateStr, { orders: 0, revenue: 0 });
    }

    // phân bổ dữ liệu các đơn hàng đã truy vấn vào từng ngày tương ứng trong map
    allOrders.forEach((order) => {
      const dateStr = order.createdAt.toLocaleDateString('vi-VN', {
        day: '2-digit',
        month: '2-digit',
      });
      if (statsMap.has(dateStr)) {
        const current = statsMap.get(dateStr)!;
        current.orders += 1;
        // chỉ cộng dồn doanh thu của các đơn đã thanh toán để tránh gây ảo báo cáo tài chính
        if (order.paymentStatus === PaymentStatus.PAID) {
          current.revenue += Number(order.totalAmount || 0);
        }
        statsMap.set(dateStr, current);
      }
    });

    const result = Array.from(statsMap.entries()).map(([date, data]) => ({
      date,
      orders: data.orders,
      revenue: data.revenue,
    }));

    return {
      orders: result.map((d) => ({ date: d.date, count: d.orders })),
      revenue: result.map((d) => ({ date: d.date, value: d.revenue })),
    };
  }

  /**
   * thực hiện mua lại đơn hàng cũ bằng cách chuyển toàn bộ sản phẩm hợp lệ vào giỏ hàng
   * 
   * xác thực quyền sở hữu đơn hàng của người dùng để tránh truy cập trái phép
   * kiểm tra trạng thái đơn hàng (chỉ cho phép đơn hàng đã giao thành công hoặc đã hủy)
   * tìm hoặc khởi tạo giỏ hàng hiện tại của user
   * duyệt qua từng sản phẩm trong đơn hàng cũ:
   *  - chỉ được mua lại nếu biến thể / sản phẩm đó còn kinh doanh
   *  - đối chiếu và kiểm tra stock hiện tại để tránh việc đặt quá số lượng cho phép
   *  - tính toán số lượng có thể thêm vào giỏ hàng sau khi đã trừ đi số lượng hiện có trong giỏ
   * thực hiện cập nhật danh mục sản phẩm vào giỏ hàng
   */
  async reorderToCart(userId: string, id: string, orderItemIds: string[]) {
    // thực hiện toàn bộ quy trình trong transaction để đảm bảo tính nhất quán dữ liệu tại thời điểm kiểm tra tồn kho
    return this.prisma.$transaction(async (tx) => {
      // truy vấn đơn hàng cũ kèm danh sách chi tiết các mặt hàng
      const oldOrder = await tx.order.findFirst({
        where: { id, userId },
        include: { items: true },
      });

      if (!oldOrder) {
        throw new NotFoundException('Không tìm thấy đơn hàng cũ');
      }

      // chỉ cho phép mua lại với các đơn hàng đã hoàn tất chu kỳ
      if (!['DELIVERED', 'COMPLETED', 'CANCELLED'].includes(oldOrder.status)) {
        throw new BadRequestException(
          'Chỉ có thể mua lại đơn hàng đã giao hoặc đã hủy',
        );
      }

      if (oldOrder.items.length === 0) {
        throw new BadRequestException('Đơn hàng cũ không có sản phẩm để mua lại');
      }

      // chỉ được mua lại khi có ít nhất một sản phẩm được chọn
      if (!orderItemIds.length) {
        throw new BadRequestException(
          'Vui lòng chọn ít nhất một sản phẩm để mua lại',
        );
      }

      const selectedItems = oldOrder.items.filter((item) =>
        orderItemIds.includes(item.id),
      );

      if (selectedItems.length === 0) {
        throw new BadRequestException(
          'Không có sản phẩm hợp lệ để mua lại',
        );
      }

      // tạo giỏ hàng cho user nếu chưa có
      const cart = await tx.cart.upsert({
        where: { userId },
        update: {},
        create: { userId },
        include: { items: true }
      });

      // list item thêm thành công - sp hợp lệ, còn hàng, đang hoạt động
      const addedItems: {
        orderItemId: string;
        variantId: string;
        productName: string;
        quantity: number;
      }[] = [];

      // list item bỏ qua - sp hết hàng, ngưng kinh doanh, tổng trong cart đã đạt tới max stock
      const skippedItems: {
        orderItemId: string;
        variantId: string;
        reason: string;
      }[] = [];

      // lần lượt xử lý từng sản phẩm được chọn mua lại
      for (const item of selectedItems) {
        // sản phẩm / biến thể phải đang hoạt động
        const variant = await tx.productVariant.findFirst({
          where: {
            id: item.productVariantId,
            isActive: true,
            product: { isActive: true },
          },
          select: {
            id: true,
            stock: true,
            product: {
              select: { name: true },
            },
          },
        });

        if (!variant) {
          skippedItems.push({
            orderItemId: item.id,
            variantId: item.productVariantId,
            reason: 'Sản phẩm không còn khả dụng',
          });
          continue;
        }

        if (variant.stock <= 0) {
          skippedItems.push({
            orderItemId: item.id,
            variantId: item.productVariantId,
            reason: 'Sản phẩm đã hết hàng',
          });
          continue;
        }

        // lấy số lượng của sản phẩm này hiện đang có trong giỏ hàng (nếu có)
        const existingCartItem = await tx.cartItem.findUnique({
          where: {
            cartId_productVariantId: {
              cartId: cart.id,
              productVariantId: variant.id,
            },
          },
          select: {
            quantity: true,
          },
        });

        const requestedQuantity = item.quantity;
        const currentCartQuantity = existingCartItem?.quantity ?? 0;
        // tính toán số lượng còn lại có thể thêm vào giỏ hàng mà không vượt quá giới hạn tồn kho
        const availableToAdd = Math.max(variant.stock - currentCartQuantity, 0);

        if (availableToAdd <= 0) {
          skippedItems.push({
            orderItemId: item.id,
            variantId: variant.id,
            reason: 'Số lượng trong giỏ hàng đã đạt tối đa tồn kho',
          });
          continue;
        }

        // quyết định số lượng thực tế sẽ thêm vào giỏ hàng
        const quantityToAdd = Math.min(requestedQuantity, availableToAdd);
        const finalQuantity = currentCartQuantity + quantityToAdd;

        // cập nhật số lượng mới vào giỏ hàng
        await tx.cartItem.upsert({
          where: {
            cartId_productVariantId: {
              cartId: cart.id,
              productVariantId: variant.id,
            },
          },
          update: {
            quantity: finalQuantity,
          },
          create: {
            cartId: cart.id,
            productVariantId: variant.id,
            quantity: quantityToAdd,
          },
        });

        addedItems.push({
          orderItemId: item.id,
          variantId: variant.id,
          productName: variant.product.name,
          quantity: quantityToAdd,
        });

        // nếu số lượng thêm vào nhỏ hơn số lượng yêu cầu do giới hạn tồn kho, ghi nhận cảnh báo
        if (quantityToAdd < requestedQuantity) {
          skippedItems.push({
            orderItemId: item.id,
            variantId: variant.id,
            reason: `Chỉ thêm được ${quantityToAdd}/${requestedQuantity} sản phẩm do giới hạn tồn kho`,
          });
        }
      }

      // nếu không có bất kỳ sản phẩm nào thêm vào giỏ hàng thành công
      if (addedItems.length === 0) {
        throw new BadRequestException({
          message: 'Không có sản phẩm nào còn khả dụng để mua lại',
          skippedItems,
        });
      }

      return {
        message: 'Đã thêm sản phẩm vào giỏ hàng',
        cartId: cart.id,
        addedCount: addedItems.length,
        addedItems,
        skippedItems,
      };
    });
  }

  private async rollbackPromotion(
    orderId: string,
    userId: string,
    tx: Prisma.TransactionClient,
  ) {
    // giải phóng voucher
    const userVoucher = await tx.userVoucher.findFirst({
      where: { orderId },
    });
    if (userVoucher) {
      if (userVoucher.usedAt) {
        // giảm số lượt sử dụng của voucher đi khi đã dùng thành công
        await tx.voucher.update({
          where: { id: userVoucher.voucherId },
          data: { usedCount: { decrement: 1 } },
        });
      }
      await tx.userVoucher.update({
        where: { id: userVoucher.id },
        data: { usedAt: null, orderId: null },
      });
    }

    // hoàn trả tồn kho flash sale
    const order = await tx.order.findUnique({
      where: { id: orderId },
      include: { items: true },
    });
    if (order) {
      for (const item of order.items) {
        await this.flashSaleService.rollbackFlashSaleStock(
          item.productVariantId,
          item.quantity,
          order.createdAt,
          tx,
        );
      }
    }
  }

  async confirmOrder(userId: string, id: string) {
    return this.prisma.$transaction(async (tx) => {
      // tìm đơn hàng theo quyền sở hữu, tránh xác nhận chéo
      const order = await tx.order.findFirst({
        where: { id, userId }
      });

      if (!order) {
        throw new NotFoundException('Không tìm thấy đơn hàng');
      }

      // chỉ cho phép xác nhận khi đơn hàng được giao thành công
      if (order.status !== OrderStatus.DELIVERED) {
        throw new BadRequestException('Chỉ dược xác nhận đã nhận hàng khi đơn hàng đã được giao thành công');
      }

      // cập nhận trạng thái đã nhận hàng
      await tx.order.update({
        where: { id },
        data: {
          status: OrderStatus.COMPLETED
        }
      });

      // tracking
      await tx.orderTracking.create({
        data: {
          orderId: order.id,
          statusLabel: 'Đã nhận hàng thành công',
          description: `Đơn hàng #${order.id.slice(0, 8)} đã được nhận`
        }
      });
    });
  }

  // cron job auto confirming order after 3 days
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleAutoConfirmOrders() {
    const daysLimit = 3; // số ngày tối đa chờ KH xác nhận -> sau n ngày sẽ tự xác nhận vào mỗi nửa đêm
    const thresoldDate = new Date();
    thresoldDate.setDate(thresoldDate.getDate() - daysLimit);

    // tìm tất cả các đơn hàng được giao thành công, chưa xác nhận quá n ngày
    const ordersToConfirm = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED,
        tracking: {
          some: {
            statusLabel: 'Giao hàng thành công',
            createdAt: { lte: thresoldDate }
          }
        }
      },
      select: {
        id: true,
        userId: true
      }
    });

    if (ordersToConfirm.length === 0) {
      return;
    }

    for (const od of ordersToConfirm) {
      try {
        await this.prisma.$transaction(async (tx) => {
          // thực hiện cập nhật trạng thái sang đã nhận
          await tx.order.updateMany({
            where: { id: od.id, status: OrderStatus.DELIVERED },
            data: {
              status: OrderStatus.COMPLETED
            }
          });

          // tracking
          await tx.orderTracking.create({
            data: {
              orderId: od.id,
              statusLabel: 'Hệ thống tự động xác nhận đã nhận hàng',
              description: `Đơn hàng #{${od.id.slice(0, 8)} đã được tự động xác nhận sau ${daysLimit} khi giao hàng thành công`,
            }
          });

          // push noti cho KH
          await this.sendOrderStatusNotification(od.userId, od.id, OrderStatus.COMPLETED);
        })
      } catch (er) {
        this.logger.error(
          `Auto confirm delivered order failed orderId=${er.id}`,
          er instanceof Error ? er.stack : String(er),
        );
      }
    }
  }

  // cron job thực hiện hủy các đơn hàng chưa thanh toán trong x phút
  // áp dụng cho cổng thanh toán
  @Cron(CronExpression.EVERY_10_MINUTES)
  async handleAutoCancelUnpaidOrders() {
    const timeLimitMinutes = 10;
    const thresholdTime = new Date(Date.now() - timeLimitMinutes * 60 * 1000);

    // list các đơn hàng cần hủy
    // đang chờ xác nhận
    // phương thức thanh toán: cổng tt
    // chưa được thanh toán thành công - pending
    // quá 10 phút kể từ lúc khởi tạo đơn hàng
    const ordersToCancel = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.PENDING,
        paymentMethod: PaymentMethod.PAYMENT_GATEWAY,
        paymentStatus: PaymentStatus.PENDING,
        createdAt: { lte: thresholdTime },
      },
      include: { items: true },
    });

    if (ordersToCancel.length === 0) return;

    for (const order of ordersToCancel) {
      try {
        await this.prisma.$transaction(async (tx) => {
          // update hàng loạt các đơn này về trạng thái hủy đơn & thanh toán thất bại
          await tx.order.updateMany({
            where: {
              id: order.id,
              status: OrderStatus.PENDING,
              paymentStatus: PaymentStatus.PENDING,
            },
            data: {
              status: OrderStatus.CANCELLED,
              paymentStatus: PaymentStatus.FAILED,
            },
          });

          // hoàn trả voucher nếu có áp dụng
          await this.rollbackPromotion(order.id, order.userId, tx);

          // hoàn kho cho từng item trong đơn
          for (const item of order.items) {
            await this.inventoriesService.adjustStock({
              variantId: item.productVariantId,
              type: InventoryTransactionType.ORDER_CANCEL,
              quantity: item.quantity,
              reason: `Tự động hoàn kho từ đơn hàng quá hạn thanh toán #${order.id.slice(0, 8)}`,
              referenceId: order.id,
              tx,
            });
          }

          // tracking
          await tx.orderTracking.create({
            data: {
              orderId: order.id,
              statusLabel: 'Tự động hủy đơn',
              description: `Đơn hàng tự động bị hủy do quá hạn thanh toán ${timeLimitMinutes} phút`,
            },
          });
        });

        // gửi push noti tới KH
        await this.sendOrderStatusNotification(
          order.userId,
          order.id,
          OrderStatus.CANCELLED,
        );
      } catch (er) {
        this.logger.error(
          `Auto cancel unpaid order failed orderId=${order.id}`,
          er instanceof Error ? er.stack : String(er),
        );
      }
    }
  }
}
