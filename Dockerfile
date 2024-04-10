# Stage 1: Build stage
FROM maven:3.9.0-eclipse-temurin-17 as build
WORKDIR /app
COPY . .
RUN mvn clean install

# Stage 2: Runtime stage
FROM openjdk:11-jdk-slim
WORKDIR /app
RUN jlink --no-header-files --no-man-pages --compress=2 --strip-debug --add-modules java.base,java.logging,java.sql,java.naming,java.management,java.instrument,java.desktop,java.security.jgss --output /usr/lib/jvm/spring-boot-runtime
COPY --from=build /app/target/demoapp.jar /app/
COPY --from=build /app/lib/ /app/lib/
ENV JAVA_HOME /usr/lib/jvm/spring-boot-runtime
ENTRYPOINT ["java", "-cp", ".:/app/lib/*", "com.example.DemoApp"]
EXPOSE 8080