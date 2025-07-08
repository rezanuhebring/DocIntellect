# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install build tools (Java is no longer needed here)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && apt-get clean

RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 5000