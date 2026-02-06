# Base Image
FROM node:20-alpine AS builder

WORKDIR /app

# Enable corepack for pnpm/yarn if needed, but we use npm
# Copy Root Configs
COPY package.json package-lock.json turbo.json ./

# Copy App Configs
COPY apps/api/package.json ./apps/api/package.json
# If there were shared packages: COPY packages ./packages

# Install Dependencies
RUN npm install

# Copy Source Code
COPY apps/api ./apps/api

# Build
RUN npm run build -w apps/api

# Production Runner
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

# Copy built assets and modules
# Note: For strict optimization we should prune devDependencies but for MVP we keep simple
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/apps/api/package.json ./apps/api/package.json
COPY --from=builder /app/apps/api/dist ./apps/api/dist

# Expose Port
EXPOSE 3000

# Start
CMD ["node", "apps/api/dist/main"]
