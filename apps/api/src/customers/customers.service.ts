import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Customer } from './entities/customer.entity';
import { CreateCustomerDto, UpdateCustomerDto } from './dto';

@Injectable()
export class CustomersService {
    constructor(
        @InjectRepository(Customer)
        private customerRepository: Repository<Customer>,
    ) {}

    async create(dto: CreateCustomerDto): Promise<Customer> {
        const customer = this.customerRepository.create(dto);
        return this.customerRepository.save(customer);
    }

    async findAll(tenantId?: string): Promise<Customer[]> {
        const where = tenantId ? { tenantId } : {};
        return this.customerRepository.find({
            where,
            order: { createdAt: 'DESC' },
        });
    }

    async findOne(id: string): Promise<Customer> {
        const customer = await this.customerRepository.findOne({
            where: { id },
        });
        if (!customer) {
            throw new NotFoundException(`Customer with ID ${id} not found`);
        }
        return customer;
    }

    async findByTelegramId(telegramId: string): Promise<Customer | null> {
        return this.customerRepository.findOne({
            where: { telegramId },
        });
    }

    async update(id: string, dto: UpdateCustomerDto): Promise<Customer> {
        const customer = await this.findOne(id);
        Object.assign(customer, dto);
        return this.customerRepository.save(customer);
    }

    async remove(id: string): Promise<void> {
        const customer = await this.findOne(id);
        await this.customerRepository.remove(customer);
    }
}
