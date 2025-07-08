# Dockerfile

# Use Python 3.9. This is the latest version fully supported by tika-python.
# This is the definitive fix for the 'No matching distribution' error.
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install Tika's dependency (Java) and build tools
RUN apt-get update && apt-get install -y --no-install-recommends default-jre build-essential && apt-get clean

# BEST PRACTICE: Upgrade pip inside the container first
RUN pip install --upgrade pip

# Copy the requirements file and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code
COPY . .

# Expose the port the app runs on
EXPOSE 5000