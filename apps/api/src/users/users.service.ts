import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './user.entity';

@Injectable()
export class UsersService {
    constructor(
        @InjectRepository(User)
        private usersRepository: Repository<User>,
    ) { }

    async findOneByEmail(email: string): Promise<User | null> {
        return this.usersRepository.findOne({ where: { email } });
    }

    async create(userData: Partial<User>): Promise<User> {
        const user = this.usersRepository.create(userData);
        return this.usersRepository.save(user);
    }

    async findAll(): Promise<User[]> {
        return this.usersRepository.find({
            select: ['id', 'email', 'fullName', 'phone', 'role', 'currentDebt', 'createdAt'],
            order: { fullName: 'ASC' }
        });
    }

    async findByRoles(roles: UserRole[]): Promise<User[]> {
        return this.usersRepository.find({
            where: roles.map(role => ({ role })),
            select: ['id', 'email', 'fullName', 'phone', 'role', 'currentDebt', 'createdAt'],
            order: { fullName: 'ASC' }
        });
    }

    async findOne(id: string): Promise<User | null> {
        return this.usersRepository.findOne({
            where: { id },
            select: ['id', 'email', 'fullName', 'phone', 'role', 'currentDebt', 'createdAt']
        });
    }
}
