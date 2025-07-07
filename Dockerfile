# /home/user/document_classifier/Dockerfile

FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install Tika's dependencies (Java)
RUN apt-get update && apt-get install -y --no-install-recommends default-jre && apt-get clean

# Copy the requirements file and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on
EXPOSE 5000