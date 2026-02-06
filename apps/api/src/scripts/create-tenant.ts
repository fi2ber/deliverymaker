import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/user.entity';
// Import all entities specifically or use glob if running with ts-node
import { Warehouse } from '../warehouse/warehouse.entity';
// We can use a glob pattern if ts-node handles it, or import all. 
// For robustness in this script, let's rely on the glob pattern matching the source structure.

async function bootstrap() {
    const args = process.argv.slice(2);
    if (args.length < 4) {
        console.error('Usage: npm run tenant:create <schema_name> <company_name> <admin_email> <admin_password>');
        process.exit(1);
    }

    const [schema, companyName, email, password] = args;
    console.log(`🚀 Starting provisioning for tenant: ${companyName} (Schema: ${schema})`);

    const dataSource = new DataSource({
        type: 'postgres',
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT || '5432'),
        username: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'postgres',
        database: process.env.DB_NAME || 'delivery_maker',
        // Valid for standard NestJS structure
        entities: [__dirname + '/../**/*.entity{.ts,.js}'],
        synchronize: false, // We will sync manually after schema switch
    });

    try {
        await dataSource.initialize();
    } catch (err: any) {
        if (err.code === '3D000') {
            console.log('⚠️  Database "delivery_maker" not found. Creating...');
            const adminSource = new DataSource({
                type: 'postgres',
                host: process.env.DB_HOST || 'localhost',
                port: parseInt(process.env.DB_PORT || '5432'),
                username: process.env.DB_USER || 'postgres',
                password: process.env.DB_PASSWORD || 'postgres',
                database: 'postgres', // Connect to default DB
            });
            await adminSource.initialize();
            await adminSource.query('CREATE DATABASE "delivery_maker"');
            await adminSource.destroy();
            console.log('✅ Database created. Retrying connection...');
            await dataSource.initialize();
        } else {
            throw err;
        }
    }

    try {
        console.log('✅ Connected to Database');

        const queryRunner = dataSource.createQueryRunner();

        // 1. Create Schema
        console.log(`Cleaning up schema "${schema}"...`);
        await queryRunner.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`);
        console.log(`Creating schema "${schema}"...`);
        await queryRunner.query(`CREATE SCHEMA IF NOT EXISTS "${schema}"`);

        // 2. Switch to Schema & Sync
        // We need a NEW connection specifically for this schema to run synchronize logic easily,
        // OR we can just use the queryRunner to create tables if we had migrations.
        // Since we rely on synchronize: true in dev/MVP, we'll re-connect.
        await dataSource.destroy();

        const tenantDataSource = new DataSource({
            type: 'postgres',
            host: process.env.DB_HOST || 'localhost',
            port: parseInt(process.env.DB_PORT || '5432'),
            username: process.env.DB_USER || 'postgres',
            password: process.env.DB_PASSWORD || 'postgres',
            database: process.env.DB_NAME || 'delivery_maker',
            schema: schema,
            entities: [__dirname + '/../**/*.entity{.ts,.js}'],
            synchronize: true, // This creates the tables in the new schema
        });

        await tenantDataSource.initialize();
        console.log('✅ Schema Synchronized (Tables Created)');

        // 3. Create Admin User
        const userRepo = tenantDataSource.getRepository(User);

        // Check if exists
        const existing = await userRepo.findOneBy({ email });
        if (existing) {
            console.warn('⚠️  User already exists. Skipping creation.');
        } else {
            const salt = await bcrypt.genSalt();
            const passwordHash = await bcrypt.hash(password, salt);

            const admin = userRepo.create({
                email,
                passwordHash,
                fullName: companyName + ' Admin',
                role: UserRole.OWNER,
                tenantId: schema,
            });

            await userRepo.save(admin);
            console.log(`✅ Owner created: ${email}`);
        }

        // 4. Create Main Warehouse (Boilerplate)
        const warehouseRepo = tenantDataSource.getRepository(Warehouse);
        const mainWarehouse = await warehouseRepo.findOneBy({ type: 'MAIN' });
        if (!mainWarehouse) {
            await warehouseRepo.save({
                name: 'Main Warehouse',
                type: 'MAIN',
                isActive: true,
                address: 'Main HQ'
            });
            console.log('✅ Main Warehouse created');
        }

        console.log(`\n🎉 Tenant "${companyName}" provisioned successfully!`);
        console.log(`Login Schema/Subdomain: ${schema}`);

        await tenantDataSource.destroy();
        process.exit(0);

    } catch (error) {
        console.error('❌ Provisioning Failed:', error);
        process.exit(1);
    }
}

bootstrap();
