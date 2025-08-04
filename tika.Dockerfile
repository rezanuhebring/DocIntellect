# tika.Dockerfile
# This Dockerfile sets up the Apache Tika server.

# Use an official OpenJDK runtime as a parent image.
# Eclipse Temurin is the successor to AdoptOpenJDK and is recommended.
FROM eclipse-temurin:17-jre-jammy

# Set Tika version as a build argument and environment variable
ARG TIKA_VERSION=2.9.1
ENV TIKA_VERSION=${TIKA_VERSION}
ENV TIKA_SERVER_JAR=tika-server-standard-${TIKA_VERSION}.jar

# Set up a non-root user for security
RUN groupadd --system --gid 1000 tika && \
    useradd --system --uid 1000 --gid tika tika

# Install necessary tools, download Tika, and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    mkdir -p /opt/tika && \
    curl -L "https://archive.apache.org/dist/tika/${TIKA_VERSION}/${TIKA_SERVER_JAR}" -o /opt/tika/tika-server.jar && \
    chown -R tika:tika /opt/tika && \
    apt-get purge -y curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch to the non-root user
USER tika
WORKDIR /opt/tika

# Expose the Tika server port
EXPOSE 9998

# Set the entrypoint to run the Tika Server, binding to all interfaces.
CMD ["java", "-jar", "tika-server.jar", "--host=0.0.0.0"]
