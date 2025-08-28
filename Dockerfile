# Multi-stage Dockerfile for Meshtastic Web monorepo

# Stage 1: Build stage
FROM node:22-alpine AS builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Set working directory
WORKDIR /app

# Copy package files for dependency installation
COPY pnpm-workspace.yaml ./
COPY package.json pnpm-lock.yaml ./

# Copy all package.json files from packages
COPY packages/core/package.json packages/core/
COPY packages/transport-deno/package.json packages/transport-deno/
COPY packages/transport-http/package.json packages/transport-http/
COPY packages/transport-node/package.json packages/transport-node/
COPY packages/transport-node-serial/package.json packages/transport-node-serial/
COPY packages/transport-web-bluetooth/package.json packages/transport-web-bluetooth/
COPY packages/transport-web-serial/package.json packages/transport-web-serial/
COPY packages/web/package.json packages/web/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application source
COPY . .

# Build all packages
RUN pnpm run build:all

# Stage 2: Production stage for serving the web app
FROM nginx:1.27-alpine

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app from builder stage
COPY --from=builder /app/packages/web/dist /usr/share/nginx/html

# Copy nginx configuration if it exists
COPY --from=builder /app/packages/web/infra/default.conf /etc/nginx/conf.d/default.conf

# Expose port 8080
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]