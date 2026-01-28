FROM openjdk:17-alpine

WORKDIR /app

# Install Docker CLI for Docker-in-Docker functionality
RUN apk add --no-cache docker-cli

# Copy Maven wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Make mvnw executable
RUN chmod +x ./mvnw

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests

# Create non-root user
RUN addgroup -g 1001 -S spring && \
    adduser -S labservice -u 1001 -G spring

# Change ownership of the app directory
RUN chown -R labservice:spring /app
USER labservice

EXPOSE 4003

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4003/labs/health || exit 1

CMD ["java", "-jar", "target/lab-service-1.0.0.jar"]