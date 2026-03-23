# CKA Simulator Service
FROM node:20-alpine

WORKDIR /app

# Install dependencies for container management
RUN apk add --no-cache docker-cli curl

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY src/ ./src/

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S ckasim -u 1001 -G nodejs

# Change ownership
RUN chown -R ckasim:nodejs /app
USER ckasim

EXPOSE 4005

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4005/health || exit 1

CMD ["node", "src/server.js"]