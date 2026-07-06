# Use OpenJDK 26 runtime image
FROM docker.io/library/eclipse-temurin:26-jre-alpine

# Set working directory
WORKDIR /app

# Copy the JAR file
COPY target/Hello.jar /app/Hello.jar

# Expose port 8080
EXPOSE 8090

# Run the application
ENTRYPOINT ["java", "-jar", "/app/Hello.jar"]
