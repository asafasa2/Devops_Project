FROM python:3.11-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache postgresql-dev gcc python3-dev musl-dev

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S python && \
    adduser -S userservice -u 1001 -G python

# Change ownership of the app directory
RUN chown -R userservice:python /app
USER userservice

EXPOSE 4002

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:4002/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:4002", "--workers", "4", "app:app"]