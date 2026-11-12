# Multi-stage production Dockerfile for DailySave Native Node.js Backend
# Enforces non-root execution, minimal attack surface, and Alpine base

# Stage 1: Build & Dependencies
FROM node:24-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Production Runtime
FROM node:24-alpine

ENV NODE_ENV=production
WORKDIR /usr/src/app

# Security: Create non-root system user and group
RUN addgroup -S dailysave && adduser -S dailysave -G dailysave

# Copy production node_modules from builder
COPY --from=builder --chown=dailysave:dailysave /usr/src/app/node_modules ./node_modules
COPY --chown=dailysave:dailysave package*.json ./
COPY --chown=dailysave:dailysave src ./src

# Switch to unprivileged user
USER dailysave

EXPOSE 4000

# Healthcheck targeting native /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/health || exit 1

CMD ["node", "src/server.js"]
