import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class YandexService {
    private readonly logger = new Logger(YandexService.name);
    private readonly apiKey: string;

    constructor(private configService: ConfigService) {
        this.apiKey = this.configService.get<string>('YANDEX_API_KEY') || 'mock_key';
    }

    /**
     * Optimizes route sequence using approximate logic or Yandex API (Mocked for now).
     * @param origin - { lat, lng }
     * @param stops - Array of { id, lat, lng }
     * @returns Array of stop IDs in optimal order
     */
    async optimizeRoute(
        origin: { lat: number, lng: number },
        stops: { id: string, lat: number, lng: number }[]
    ): Promise<string[]> {
        if (this.apiKey === 'mock_key') {
            this.logger.warn('Using MOCK Yandex optimization (No API Key provided)');
            // Simple mock: Sort by distance from origin (Nearest Neighbor greedy)
            // Real TSP solution would be much more complex or use Yandex Routing API
            const remaining = [...stops];
            const optimizedIds = [];
            let currentPos = origin;

            while (remaining.length > 0) {
                // Find nearest
                let nearestIdx = -1;
                let minDist = Infinity;

                for (let i = 0; i < remaining.length; i++) {
                    const dist = this.getDistance(currentPos, remaining[i]);
                    if (dist < minDist) {
                        minDist = dist;
                        nearestIdx = i;
                    }
                }

                const nearest = remaining.splice(nearestIdx, 1)[0];
                optimizedIds.push(nearest.id);
                currentPos = nearest;
            }

            return optimizedIds;
        }

        // TODO: Implement real Yandex.Route API call here
        // https://yandex.com/dev/routing/
        return stops.map(s => s.id);
    }

    private getDistance(p1: { lat: number, lng: number }, p2: { lat: number, lng: number }) {
        // Simple Euclidean distance (assuming small area)
        // For real geo distance use Haversine formula
        return Math.sqrt(Math.pow(p1.lat - p2.lat, 2) + Math.pow(p1.lng - p2.lng, 2));
    }
}
