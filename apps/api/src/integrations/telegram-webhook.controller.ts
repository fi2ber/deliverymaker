import { Controller, Post, Body, Param, Headers, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TenantTelegramService } from './tenant-telegram.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { OrdersService } from '../sales/orders.service';
import { verifyTelegramInitData } from '../common/middlewares/tenancy.middleware';

// Types for Telegram Webhook
interface TelegramUser {
  id: number;
  first_name: string;
  last_name?: string;
  username?: string;
}

interface TelegramChat {
  id: number;
  type: string;
  title?: string;
}

interface TelegramMessage {
  message_id: number;
  from?: TelegramUser;
  chat: TelegramChat;
  date: number;
  text?: string;
  entities?: Array<{
    type: string;
    offset: number;
    length: number;
  }>;
  successful_payment?: {
    currency: string;
    total_amount: number;
    invoice_payload: string;
    telegram_payment_charge_id: string;
    provider_payment_charge_id: string;
  };
}

interface TelegramCallbackQuery {
  id: string;
  from: TelegramUser;
  message?: {
    message_id: number;
    chat: TelegramChat;
  };
  data: string;
}

interface TelegramUpdate {
  update_id: number;
  message?: TelegramMessage;
  callback_query?: TelegramCallbackQuery;
  pre_checkout_query?: {
    id: string;
    from: TelegramUser;
    currency: string;
    total_amount: number;
    invoice_payload: string;
  };
}

@ApiTags('Telegram Webhook')
@Controller('webhooks/telegram')
export class TelegramWebhookController {
  constructor(
    private readonly tenantTelegramService: TenantTelegramService,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly ordersService: OrdersService,
  ) {}

  @Post(':tenantId')
  @ApiOperation({ summary: 'Receive webhook from Telegram for specific tenant' })
  async handleWebhook(
    @Param('tenantId') tenantId: string,
    @Body() update: TelegramUpdate,
    @Headers('x-telegram-bot-api-secret-token') secretToken?: string,
  ) {
    // Verify webhook secret if configured
    // TODO: Add secret token verification

    try {
      // Handle different update types
      if (update.message) {
        await this.handleMessage(tenantId, update.message);
      }
      
      if (update.callback_query) {
        await this.handleCallbackQuery(tenantId, update.callback_query);
      }
      
      if (update.pre_checkout_query) {
        await this.handlePreCheckoutQuery(tenantId, update.pre_checkout_query);
      }

      return { ok: true };
    } catch (error) {
      console.error(`Webhook error for tenant ${tenantId}:`, error);
      return { ok: false, error: error.message };
    }
  }

  private async handleMessage(tenantId: string, message: TelegramMessage) {
    const chatId = message.chat.id;
    const text = message.text || '';
    const user = message.from;

    // Handle commands
    if (text.startsWith('/')) {
      await this.handleCommand(tenantId, chatId, text, user);
      return;
    }

    // Handle regular messages (optional - can be used for support)
    if (text) {
      await this.handleRegularMessage(tenantId, chatId, text, user);
    }

    // Handle successful payment
    if (message.successful_payment) {
      await this.handleSuccessfulPayment(tenantId, chatId, message.successful_payment);
    }
  }

  private async handleCommand(
    tenantId: string,
    chatId: number,
    text: string,
    user?: TelegramUser,
  ) {
    const [command, ...args] = text.split(' ');
    const username = user?.username || user?.first_name || 'Клиент';

    switch (command) {
      case '/start':
        await this.handleStartCommand(tenantId, chatId, username, args[0]);
        break;

      case '/orders':
      case '/myorders':
        await this.handleOrdersCommand(tenantId, chatId, user?.id.toString());
        break;

      case '/subscriptions':
      case '/mysubs':
        await this.handleSubscriptionsCommand(tenantId, chatId, user?.id.toString());
        break;

      case '/support':
        await this.handleSupportCommand(tenantId, chatId);
        break;

      case '/help':
        await this.handleHelpCommand(tenantId, chatId);
        break;

      case '/profile':
        await this.handleProfileCommand(tenantId, chatId, user?.id.toString());
        break;

      default:
        await this.tenantTelegramService.sendMessage(tenantId, {
          chatId,
          text: '❌ Неизвестная команда. Используйте /help для списка команд.',
        });
    }
  }

  private async handleStartCommand(
    tenantId: string,
    chatId: number,
    username: string,
    startParam?: string,
  ) {
    // Get bot settings for welcome message
    const bot = await this.tenantTelegramService.getBot(tenantId);
    const welcomeMessage = bot?.settings?.welcomeMessage || 
      `👋 Привет, ${username}!\n\n` +
      `Добро пожаловать в наш магазин! Здесь вы можете:\n` +
      `• 🛒 Заказать товары\n` +
      `• 💎 Оформить подписку на комбо\n` +
      `• 📋 Смотреть историю заказов\n\n` +
      `Нажмите кнопку ниже, чтобы открыть магазин:`;

    const webAppUrl = bot?.settings?.webAppUrl || 
      `https://tma.deliverymaker.uz?tenant=${tenantId}`;

    await this.tenantTelegramService.sendMessage(tenantId, {
      chatId,
      text: welcomeMessage,
      parseMode: 'HTML',
      replyMarkup: {
        inline_keyboard: [
          [
            {
              text: '🛒 Открыть магазин',
              web_app: { url: webAppUrl },
            },
          ],
          [
            { text: '📋 Мои заказы', callback_data: 'show_orders' },
            { text: '💎 Подписки', callback_data: 'show_subscriptions' },
          ],
        ],
      },
    });
  }

  private async handleOrdersCommand(
    tenantId: string,
    chatId: number,
    telegramUserId?: string,
  ) {
    if (!telegramUserId) {
      await this.tenantTelegramService.sendMessage(tenantId, {
        chatId,
        text: '❌ Не удалось определить ваш профиль.',
      });
      return;
    }

    // Get orders for this user
    // Note: We need to map telegram user ID to internal user ID
    const orders = []; // TODO: Implement getOrdersByTelegramId

    if (orders.length === 0) {
      await this.tenantTelegramService.sendMessage(tenantId, {
        chatId,
        text: '📋 У вас пока нет заказов.\n\nНажмите кнопку ниже, чтобы сделать первый заказ:',
        replyMarkup: {
          inline_keyboard: [
            [
              {
                text: '🛒 Перейти в магазин',
                web_app: { url: `https://tma.deliverymaker.uz?tenant=${tenantId}` },
              },
            ],
          ],
        },
      });
      return;
    }

    // Show recent orders
    let message = '📋 <b>Ваши последние заказы:</b>\n\n';
    // TODO: Format orders list

    await this.tenantTelegramService.sendMessage(tenantId, {
      chatId,
      text: message,
      parseMode: 'HTML',
    });
  }

  private async handleSubscriptionsCommand(
    tenantId: string,
    chatId: number,
    telegramUserId?: string,
  ) {
    if (!telegramUserId) {
      await this.tenantTelegramService.sendMessage(tenantId, {
        chatId,
        text: '❌ Не удалось определить ваш профиль.',
      });
      return;
    }

    // Get active subscriptions
    const subscriptions = []; // TODO: Implement getSubscriptionsByTelegramId

    if (subscriptions.length === 0) {
      await this.tenantTelegramService.sendMessage(tenantId, {
        chatId,
        text: '💎 У вас нет активных подписок.\n\nОформите подписку на комбо и экономьте до 20%!',
        replyMarkup: {
          inline_keyboard: [
            [
              {
                text: '💎 Выбрать комбо',
                web_app: { url: `https://tma.deliverymaker.uz?tenant=${tenantId}&tab=subscriptions` },
              },
            ],
          ],
        },
      });
      return;
    }

    let message = '💎 <b>Ваши подписки:</b>\n\n';
    // TODO: Format subscriptions list

    await this.tenantTelegramService.sendMessage(tenantId, {
      chatId,
      text: message,
      parseMode: 'HTML',
    });
  }

  private async handleSupportCommand(tenantId: string, chatId: number) {
    const bot = await this.tenantTelegramService.getBot(tenantId);
    const supportUsername = bot?.settings?.supportUsername;

    if (supportUsername) {
      await this.tenantTelegramService.sendMessage(tenantId, {
        chatId,
        text: `📞 Свяжитесь с нашей поддержкой:\n@${supportUsername}`,
      });
    } else {
      await this.tenantTelegramService.sendMessage(tenantId, {
        chatId,
        text: '📞 Напишите ваш вопрос здесь, и мы ответим в ближайшее время.',
      });
    }
  }

  private async handleHelpCommand(tenantId: string, chatId: number) {
    const helpText = `
📚 <b>Доступные команды:</b>

/start - Главное меню
/orders - Мои заказы
/subscriptions - Мои подписки
/profile - Мой профиль
/support - Поддержка
/help - Эта справка

💡 <b>Советы:</b>
• Нажмите "🛒 Открыть магазин" для просмотра товаров
• Оформите подписку на комбо и экономьте до 20%
• Получайте уведомления о статусе заказа
    `.trim();

    await this.tenantTelegramService.sendMessage(tenantId, {
      chatId,
      text: helpText,
      parseMode: 'HTML',
    });
  }

  private async handleProfileCommand(
    tenantId: string,
    chatId: number,
    telegramUserId?: string,
  ) {
    // TODO: Get user profile from database
    const profile = {
      name: 'Клиент',
      ordersCount: 0,
      totalSpent: 0,
      debt: 0,
    };

    const message = `
👤 <b>Ваш профиль:</b>

📦 Заказов: ${profile.ordersCount}
💰 Потрачено: ${profile.totalSpent.toLocaleString()} sum
${profile.debt > 0 ? `⚠️ Текущий долг: ${profile.debt.toLocaleString()} sum` : '✅ Долгов нет'}

💡 Нажмите кнопку ниже, чтобы открыть полный профиль:
    `.trim();

    await this.tenantTelegramService.sendMessage(tenantId, {
      chatId,
      text: message,
      parseMode: 'HTML',
      replyMarkup: {
        inline_keyboard: [
          [
            {
              text: '👤 Открыть профиль',
              web_app: { url: `https://tma.deliverymaker.uz?tenant=${tenantId}&page=profile` },
            },
          ],
        ],
      },
    });
  }

  private async handleRegularMessage(
    tenantId: string,
    chatId: number,
    text: string,
    user?: TelegramUser,
  ) {
    // Forward to support or handle as needed
    // For now, just acknowledge
    await this.tenantTelegramService.sendMessage(tenantId, {
      chatId,
      text: '✉️ Сообщение получено. Мы ответим вам в ближайшее время.',
    });
  }

  private async handleCallbackQuery(
    tenantId: string,
    callbackQuery: TelegramCallbackQuery,
  ) {
    const chatId = callbackQuery.message?.chat.id;
    const data = callbackQuery.data;
    const user = callbackQuery.from;

    if (!chatId) return;

    // Answer the callback query to remove loading state
    await this.answerCallbackQuery(tenantId, callbackQuery.id);

    switch (data) {
      case 'show_orders':
        await this.handleOrdersCommand(tenantId, chatId, user.id.toString());
        break;

      case 'show_subscriptions':
        await this.handleSubscriptionsCommand(tenantId, chatId, user.id.toString());
        break;

      case 'open_shop':
        // This will be handled by web_app button, but just in case
        break;

      default:
        if (data.startsWith('order_')) {
          const orderId = data.replace('order_', '');
          // TODO: Show order details
        } else if (data.startsWith('cancel_order_')) {
          const orderId = data.replace('cancel_order_', '');
          // TODO: Cancel order
        }
    }
  }

  private async handlePreCheckoutQuery(
    tenantId: string,
    preCheckoutQuery: {
      id: string;
      from: TelegramUser;
      currency: string;
      total_amount: number;
      invoice_payload: string;
    },
  ) {
    // Always answer pre-checkout query positively
    // You can add validation here if needed
    await this.answerPreCheckoutQuery(tenantId, preCheckoutQuery.id, true);
  }

  private async handleSuccessfulPayment(
    tenantId: string,
    chatId: number,
    payment: {
      currency: string;
      total_amount: number;
      invoice_payload: string;
      telegram_payment_charge_id: string;
      provider_payment_charge_id: string;
    },
  ) {
    try {
      const payload = JSON.parse(payment.invoice_payload);
      
      if (payload.type === 'subscription') {
        // Activate subscription
        await this.subscriptionsService.activateSubscription(
          payload.subscriptionId,
          payment.telegram_payment_charge_id,
        );

        await this.tenantTelegramService.sendMessage(tenantId, {
          chatId,
          text: '✅ <b>Оплата успешна!</b>\n\nВаша подписка активирована. Мы отправим уведомление перед первой доставкой.',
          parseMode: 'HTML',
        });
      }
    } catch (error) {
      console.error('Error handling payment:', error);
      await this.tenantTelegramService.sendMessage(tenantId, {
        chatId,
        text: '⚠️ Оплата прошла, но возникла ошибка при активации. Пожалуйста, свяжитесь с поддержкой.',
      });
    }
  }

  private async answerCallbackQuery(tenantId: string, callbackQueryId: string) {
    try {
      const bot = await this.tenantTelegramService.getBot(tenantId);
      // TODO: Implement answerCallbackQuery in TenantTelegramService
    } catch (error) {
      console.error('Error answering callback query:', error);
    }
  }

  private async answerPreCheckoutQuery(
    tenantId: string,
    preCheckoutQueryId: string,
    ok: boolean,
    errorMessage?: string,
  ) {
    try {
      const bot = await this.tenantTelegramService.getBot(tenantId);
      // TODO: Implement answerPreCheckoutQuery in TenantTelegramService
    } catch (error) {
      console.error('Error answering pre-checkout query:', error);
    }
  }
}
