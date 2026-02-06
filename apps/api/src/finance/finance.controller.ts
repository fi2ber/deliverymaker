import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { FinanceService } from './finance.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '../users/user.entity';

@ApiTags('Finance')
@ApiBearerAuth('JWT-auth')
@Controller('finance')
@UseGuards(JwtAuthGuard, RolesGuard)
export class FinanceController {
    constructor(private readonly financeService: FinanceService) { }

    @Get('balance/my')
    @Roles(UserRole.DRIVER, UserRole.SALES_REP)
    async getMyBalance(@CurrentUser() user: any) {
        return { balance: await this.financeService.getDriverBalance(user.id) };
    }

    @Post('handover')
    @Roles(UserRole.DRIVER, UserRole.SALES_REP)
    async requestHandover(@CurrentUser() user: any, @Body() body: { amount: number }) {
        return this.financeService.requestHandover(user.id, body.amount);
    }

    @Post('handover/:id/confirm')
    @Roles(UserRole.ACCOUNTANT, UserRole.SUPER_ADMIN, UserRole.OWNER)
    async confirmHandover(@Param('id') id: string, @CurrentUser() user: any) {
        return this.financeService.confirmHandover(id, user.id);
    }
}
