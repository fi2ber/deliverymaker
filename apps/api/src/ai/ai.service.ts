import { Inject, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { TENANT_CONNECTION } from '../database/database.module';
import { Order } from '../sales/order.entity';

@Injectable()
export class AiService {
  constructor(
    @Inject(TENANT_CONNECTION) private dataSource: DataSource,
  ) { }

  private get orderRepo() { return this.dataSource.getRepository(Order); }

  /**
   * Analyzes purchase frequency for a specific client.
   */
  async getSmartReminders(clientId: string) {
    const result = await this.orderRepo.query(`
          WITH PurchaseHistory AS (
            SELECT 
              oi."productId" as p_id, 
              o."createdAt" as buy_date,
              LAG(o."createdAt") OVER (PARTITION BY oi."productId" ORDER BY o."createdAt") as prev_buy_date
            FROM orders o
            JOIN order_items oi ON oi."orderId" = o.id
            WHERE o."clientId" = $1 
              AND o."status" = 'DELIVERED'
              AND o."createdAt" > NOW() - INTERVAL '90 days'
          ),
          Stats AS (
            SELECT 
              p_id,
              MAX(buy_date) as last_buy,
              AVG(EXTRACT(EPOCH FROM (buy_date - prev_buy_date))/86400) as avg_days_diff,
              COUNT(*) as purchase_count
            FROM PurchaseHistory
            WHERE prev_buy_date IS NOT NULL
            GROUP BY p_id
          )
          SELECT 
            s.p_id as "productId",
            p.name as "productName",
            ROUND(s.avg_days_diff) as "frequencyDays",
            s.last_buy as "lastPurchaseDate"
          FROM Stats s
          JOIN products p ON p.id = s.p_id
          WHERE s.purchase_count >= 2
            AND (NOW() > s.last_buy + (s.avg_days_diff * INTERVAL '1 day'))
          ORDER BY s.purchase_count DESC
          LIMIT 5;
       `, [clientId]);

    return result;
  }

  async getActiveClients() {
    return this.orderRepo.query(`
          SELECT DISTINCT "clientId" as id 
          FROM orders 
          WHERE "createdAt" > NOW() - INTERVAL '30 days'
      `);
  }

  /**
   * Identifies clients at risk of churning.
   */
  async getChurnRiskClients() {
    return this.orderRepo.query(`
        WITH ClientStats AS (
            SELECT 
                "clientId",
                MAX("createdAt") as last_order_date,
                COUNT(*) as order_count,
                AVG(EXTRACT(EPOCH FROM ("createdAt" - LAG("createdAt") OVER (PARTITION BY "clientId" ORDER BY "createdAt"))) / 86400) as avg_interval_days
            FROM orders
            WHERE "status" = 'DELIVERED'
            GROUP BY "clientId"
        )
        SELECT 
            cs."clientId",
            u."fullName",
            u.phone,
            u."telegramChatId",
            ROUND(cs.avg_interval_days) as "avgDays",
            ROUND(EXTRACT(EPOCH FROM (NOW() - cs.last_order_date))/86400) as "daysSinceLastOrder"
        FROM ClientStats cs
        JOIN users u ON u.id = cs."clientId"
        WHERE cs.order_count >= 3
          AND cs.avg_interval_days IS NOT NULL
          AND NOW() > cs.last_order_date + (cs.avg_interval_days * 1.5 * INTERVAL '1 day')
          AND cs.last_order_date > NOW() - INTERVAL '60 days' -- Was active recently
        ORDER BY "daysSinceLastOrder" DESC;
      `);
  }

  /**
   * Analyzes driver performance.
   */
  async getDriverPerformance() {
    return this.orderRepo.query(`
        SELECT 
            u."fullName" as "driverName",
            COUNT(*) as "totalAssigned",
            SUM(CASE WHEN o.status = 'DELIVERED' THEN 1 ELSE 0 END) as "delivered",
            SUM(CASE WHEN o.status IN ('CANCELLED', 'RETURNED') THEN 1 ELSE 0 END) as "failed",
            ROUND(
                (SUM(CASE WHEN o.status = 'DELIVERED' THEN 1 ELSE 0 END)::numeric / COUNT(*)) * 100
            ) as "successRate"
        FROM orders o
        JOIN users u ON u.id = o."driverId"
        WHERE o."createdAt" > NOW() - INTERVAL '30 days'
        GROUP BY u.id, u."fullName"
        ORDER BY "successRate" DESC;
      `);
  }

  /**
   * Identifies Dead Stock (Expired or Not Moving).
   */
  async getDeadStock() {
    return this.orderRepo.query(`
        WITH LastSales AS (
            SELECT 
                "productId", 
                MAX("createdAt") as last_sold
            FROM order_items oi
            JOIN orders o ON o.id = oi."orderId"
            WHERE o.status = 'DELIVERED'
            GROUP BY "productId"
        )
        SELECT 
            p.name as "productName",
            b."batchCode",
            b.quantity as "currentStock",
            b."expirationDate",
            ls.last_sold as "lastSoldDate",
            CASE 
                WHEN b."expirationDate" < NOW() + INTERVAL '30 days' THEN 'EXPIRING_SOON'
                WHEN ls.last_sold < NOW() - INTERVAL '60 days' OR ls.last_sold IS NULL THEN 'LOW_TURNOVER'
                ELSE 'OK'
            END as "riskType"
        FROM warehouse_batches b
        JOIN products p ON p.id = b."productId"
        LEFT JOIN LastSales ls ON ls."productId" = p.id
        WHERE b.quantity > 0
          AND (
            b."expirationDate" < NOW() + INTERVAL '30 days' 
            OR ls.last_sold < NOW() - INTERVAL '60 days' 
            OR ls.last_sold IS NULL
          )
        ORDER BY b."expirationDate" ASC;
      `);
  }

  /**
   * Simple Demand Forecasting (Linear Growth).
   */
  async getDemandForecast() {
    // Compare last 7 days vs previous 7 days to get trend
    return this.orderRepo.query(`
        WITH WeeklySales AS (
            SELECT 
                "productId",
                SUM(CASE WHEN "createdAt" > NOW() - INTERVAL '7 days' THEN quantity ELSE 0 END) as sales_last_7d,
                SUM(CASE WHEN "createdAt" BETWEEN NOW() - INTERVAL '14 days' AND NOW() - INTERVAL '7 days' THEN quantity ELSE 0 END) as sales_prev_7d
            FROM order_items oi
            JOIN orders o ON o.id = oi."orderId"
            WHERE o.status = 'DELIVERED'
            GROUP BY "productId"
        )
        SELECT 
            p.name,
            ws.sales_last_7d,
            ws.sales_prev_7d,
            CASE 
                WHEN ws.sales_prev_7d > 0 THEN ROUND(((ws.sales_last_7d - ws.sales_prev_7d)::numeric / ws.sales_prev_7d) * 100)
                ELSE 100 -- New product growth
            END as "growthRatePercent",
            ROUND(ws.sales_last_7d * (
                1 + (
                    CASE 
                        WHEN ws.sales_prev_7d > 0 THEN (ws.sales_last_7d - ws.sales_prev_7d)::numeric / ws.sales_prev_7d
                        ELSE 1
                    END
                )
            )) as "forecastNext7d"
        FROM WeeklySales ws
        JOIN products p ON p.id = ws."productId"
        WHERE ws.sales_last_7d > 5 -- Filter low volume
        ORDER BY "growthRatePercent" DESC;
      `);
  }

  /**
   * Detects Anomalies (Fraud/Theft/Process Issues).
   * 1. Returns > 15% (Driver or Client issue).
   * 2. Discounts > 20% (Sales Rep issue - if we tracked discounts).
   * 3. Order Completion time < 1 min (Fake GPS?).
   */
  async getAnomalies() {
    return this.orderRepo.query(`
        SELECT 
            'DRIVER_RETURNS_HIGH' as "anomalyType",
            u."fullName" as "entityName",
            ROUND((SUM(CASE WHEN o.status IN ('RETURNED', 'CANCELLED') THEN 1 ELSE 0 END)::numeric / COUNT(*)) * 100) as "metricValue",
            'Return Rate > 15%' as "reason"
        FROM orders o
        JOIN users u ON u.id = o."driverId"
        WHERE o."createdAt" > NOW() - INTERVAL '30 days'
        GROUP BY u.id, u."fullName"
        HAVING (SUM(CASE WHEN o.status IN ('RETURNED', 'CANCELLED') THEN 1 ELSE 0 END)::numeric / COUNT(*)) > 0.15

        UNION ALL

        SELECT 
            'CLIENT_ORDER_FREQUENCY_ABNORMAL' as "anomalyType",
            u."fullName" as "entityName",
            COUNT(*) as "metricValue",
            'Ordered > 5 times in 24h' as "reason"
        FROM orders o
        JOIN users u ON u.id = o."clientId"
        WHERE o."createdAt" > NOW() - INTERVAL '24 hours'
        GROUP BY u.id, u."fullName"
        HAVING COUNT(*) > 5;
      `);
  }
}
