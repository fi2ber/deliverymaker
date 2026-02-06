import {
    WebSocketGateway,
    WebSocketServer,
    SubscribeMessage,
    OnGatewayConnection,
    OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UseGuards } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

interface AuthenticatedSocket extends Socket {
    userId?: string;
    tenantId?: string;
}

@WebSocketGateway({
    cors: {
        origin: '*',
    },
    namespace: '/notifications',
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer()
    server: Server;

    private readonly logger = new Logger(NotificationsGateway.name);
    private userSockets: Map<string, string[]> = new Map(); // userId -> socketIds[]

    constructor(private readonly jwtService: JwtService) { }

    async handleConnection(client: AuthenticatedSocket) {
        try {
            // Extract token from query or auth header
            const token = this.extractToken(client);
            if (!token) {
                this.logger.warn('Connection attempt without token');
                client.disconnect();
                return;
            }

            // Verify token
            const payload = this.jwtService.verify(token);
            client.userId = payload.sub;
            client.tenantId = payload.tenantId;

            // Register socket for user
            const userSockets = this.userSockets.get(payload.sub) || [];
            userSockets.push(client.id);
            this.userSockets.set(payload.sub, userSockets);

            this.logger.log(`Client connected: ${client.id}, user: ${payload.sub}`);

            // Join tenant room for broadcast messages
            client.join(`tenant:${payload.tenantId}`);

        } catch (error) {
            this.logger.error('Connection error:', error);
            client.disconnect();
        }
    }

    handleDisconnect(client: AuthenticatedSocket) {
        if (client.userId) {
            const userSockets = this.userSockets.get(client.userId) || [];
            const updated = userSockets.filter(id => id !== client.id);
            if (updated.length === 0) {
                this.userSockets.delete(client.userId);
            } else {
                this.userSockets.set(client.userId, updated);
            }
        }
        this.logger.log(`Client disconnected: ${client.id}`);
    }

    @SubscribeMessage('mark_read')
    handleMarkRead(client: AuthenticatedSocket, notificationId: string) {
        // TODO: Call notification service to mark as read
        this.logger.log(`Mark notification ${notificationId} as read for user ${client.userId}`);
        return { success: true };
    }

    @SubscribeMessage('subscribe_topic')
    handleSubscribeTopic(client: AuthenticatedSocket, topic: string) {
        client.join(`topic:${topic}`);
        this.logger.log(`User ${client.userId} subscribed to topic: ${topic}`);
        return { success: true, topic };
    }

    /**
     * Send real-time notification to specific user
     */
    sendToUser(userId: string, notification: any) {
        const socketIds = this.userSockets.get(userId);
        if (socketIds && socketIds.length > 0) {
            socketIds.forEach(socketId => {
                this.server.to(socketId).emit('notification', notification);
            });
        }
    }

    /**
     * Send notification to all users in tenant
     */
    sendToTenant(tenantId: string, notification: any) {
        this.server.to(`tenant:${tenantId}`).emit('notification', notification);
    }

    /**
     * Send notification to topic subscribers
     */
    sendToTopic(topic: string, notification: any) {
        this.server.to(`topic:${topic}`).emit('notification', notification);
    }

    /**
     * Broadcast to all connected clients
     */
    broadcast(notification: any) {
        this.server.emit('notification', notification);
    }

    private extractToken(client: AuthenticatedSocket): string | null {
        // Try from handshake auth
        const authToken = client.handshake.auth?.token;
        if (authToken) return authToken;

        // Try from query params
        const queryToken = client.handshake.query?.token as string;
        if (queryToken) return queryToken;

        // Try from headers
        const headerToken = client.handshake.headers.authorization;
        if (headerToken?.startsWith('Bearer ')) {
            return headerToken.substring(7);
        }

        return null;
    }

    // ============ Helper Methods ============

    isUserOnline(userId: string): boolean {
        const sockets = this.userSockets.get(userId);
        return sockets !== undefined && sockets.length > 0;
    }

    getOnlineUsersCount(): number {
        return this.userSockets.size;
    }
}
