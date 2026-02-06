import { 
    Controller, 
    Get, 
    Post, 
    Put, 
    Delete,
    Body, 
    Param, 
    Query,
    UseGuards,
    Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service';
import { CreateSubscriptionDto, CreateComboProductDto } from './dto/create-subscription.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';

@ApiTags('Subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
    constructor(private readonly subscriptionsService: SubscriptionsService) {}

    // ============ COMBO PRODUCTS ============

    @Get('combos')
    @ApiOperation({ summary: 'Get all active combo products' })
    async findAllCombos() {
        return this.subscriptionsService.findAllCombos();
    }

    @Get('combos/tma')
    @ApiOperation({ summary: 'Get combos available in Telegram Mini App' })
    async findCombosForTMA() {
        return this.subscriptionsService.findCombosForTMA();
    }

    @Get('combos/:id')
    @ApiOperation({ summary: 'Get combo product by ID' })
    @ApiParam({ name: 'id', description: 'Combo product ID' })
    async findComboById(@Param('id') id: string) {
        return this.subscriptionsService.findComboById(id);
    }

    @Post('combos')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.DIRECTOR)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Create new combo product (Admin only)' })
    async createCombo(@Body() dto: CreateComboProductDto) {
        return this.subscriptionsService.createCombo(dto);
    }

    // ============ SUBSCRIPTIONS ============

    @Post()
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Create new subscription' })
    async createSubscription(
        @Request() req,
        @Body() dto: CreateSubscriptionDto,
    ) {
        const clientId = req.user.sub;
        return this.subscriptionsService.createSubscription(clientId, dto);
    }

    @Get('my')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Get my subscriptions' })
    async findMySubscriptions(@Request() req) {
        const clientId = req.user.sub;
        return this.subscriptionsService.findSubscriptionsByClient(clientId);
    }

    @Get('my/active')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Get my active subscriptions' })
    async findMyActiveSubscriptions(@Request() req) {
        const clientId = req.user.sub;
        return this.subscriptionsService.findActiveSubscriptions(clientId);
    }

    @Get(':id')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Get subscription by ID' })
    async findSubscriptionById(@Param('id') id: string) {
        return this.subscriptionsService.findSubscriptionById(id);
    }

    @Post(':id/activate')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Activate subscription after payment' })
    async activateSubscription(
        @Param('id') id: string,
        @Body('paymentChargeId') paymentChargeId: string,
    ) {
        return this.subscriptionsService.activateSubscription(id, paymentChargeId);
    }

    @Put(':id/pause')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Pause subscription' })
    async pauseSubscription(@Param('id') id: string) {
        return this.subscriptionsService.pauseSubscription(id);
    }

    @Put(':id/resume')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Resume subscription' })
    async resumeSubscription(@Param('id') id: string) {
        return this.subscriptionsService.resumeSubscription(id);
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Cancel subscription' })
    async cancelSubscription(@Param('id') id: string) {
        return this.subscriptionsService.cancelSubscription(id);
    }

    // ============ ADMIN ENDPOINTS ============

    @Get(':id/deliver')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.DIRECTOR, UserRole.WAREHOUSE)
    @ApiBearerAuth('JWT-auth')
    @ApiOperation({ summary: 'Process delivery for subscription (Admin/Driver)' })
    async processDelivery(@Param('id') id: string) {
        return this.subscriptionsService.processDelivery(id);
    }
}
