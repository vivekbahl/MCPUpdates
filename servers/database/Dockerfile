FROM node:18-alpine

# Create non-root user
RUN addgroup -g 1000 mcpuser && \
    adduser -D -u 1000 -G mcpuser mcpuser

# Install dependencies
RUN apk add --no-cache tini postgresql-client

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY --chown=mcpuser:mcpuser . .

# Create necessary directories
RUN mkdir -p logs && \
    chown -R mcpuser:mcpuser /app

# Switch to non-root user
USER mcpuser

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "src/server.js"] 