FROM eclipse-temurin:17-jdk AS builder

WORKDIR /app

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre

WORKDIR /app

# Install Docker CLI for Docker-in-Docker functionality
RUN apt-get update && apt-get install -y docker.io wget && rm -rf /var/lib/apt/lists/*

# Copy the built jar from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Create non-root user
RUN groupadd -g 1001 spring && \
    useradd -r -u 1001 -g spring labservice

# Change ownership of the app directory
RUN chown -R labservice:spring /app
USER labservice

EXPOSE 4003

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4003/labs/health || exit 1

CMD ["java", "-jar", "app.jar"]