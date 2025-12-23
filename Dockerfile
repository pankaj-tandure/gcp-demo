# --- Stage 1: Build the application ---
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app

# 1. Copy the Maven wrapper and pom.xml first
# This allows Docker to cache dependencies if the pom.xml hasn't changed
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# 2. Grant execution permissions to the wrapper
RUN chmod +x mvnw

# 3. Download dependencies (optional but recommended for caching)
RUN ./mvnw dependency:go-offline

# 4. Copy the source code
COPY src ./src

# 5. Build the application
RUN ./mvnw clean package -DskipTests

# --- Stage 2: Run the application in a minimal JRE image ---
FROM eclipse-temurin:17-jdk-jammy
WORKDIR /app

# 6. Create a non-root user using Debian syntax (since 'slim' is Debian-based)
# 'groupadd' and 'useradd' are the standard commands here
RUN groupadd -r spring && useradd -r -g spring spring

# Switch to the non-root user
USER spring

# 7. Copy the JAR file
# Since WORKDIR is /app, this places the file at /app/app.jar
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

# 8. Correct the path in ENTRYPOINT
# Use "app.jar" (relative to WORKDIR) or "/app/app.jar" (absolute)
ENTRYPOINT ["java", "-jar", "app.jar"]