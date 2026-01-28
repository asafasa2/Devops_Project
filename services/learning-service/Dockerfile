FROM node:18-alpine AS base

WORKDIR /app

# Copy package files
COPY package*.json ./

# Development stage
FROM base AS development
RUN npm install
COPY src/ ./src/
EXPOSE 4001
CMD ["npm", "run", "dev"]

# Production stage
FROM base AS production
RUN npm install --only=production
COPY src/ ./src/

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S learningservice -u 1001

# Change ownership of the app directory
RUN chown -R learningservice:nodejs /app
USER learningservice

EXPOSE 4001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD ["npm", "start"]