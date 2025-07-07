# DocIntellect

A smart, containerized document classification system designed for legal and professional environments. DocIntellect automatically scans, extracts text, and categorizes documents from various sources using a trainable machine learning model.

![Dashboard Screenshot](path/to/your/screenshot.png) <!-- It's highly recommended to add a screenshot! -->

## Features

- **Multi-Format Content Extraction**: Leverages Apache Tika to parse `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, and `.wpd` files.
- **Machine Learning Classification**: Uses a Scikit-learn pipeline to automatically categorize documents based on their content.
- **Multi-Lingual Support**: Capable of processing and classifying documents in both English and Bahasa Indonesia.
- **Interactive Dashboard**: A modern web UI built with Flask and Bootstrap to:
    - Select and scan specific drives or directories.
    - View real-time statistics and classification results.
    - Visualize data with charts (via Chart.js).
- **Easy Deployment**: Fully containerized with Docker and Docker Compose for a one-command setup on Linux, macOS, or Windows (via WSL).
- **Data Export**: Download the entire document database, including extracted content and metadata, as a CSV file.

## Tech Stack

- **Backend**: Python 3.9, Flask, Gunicorn
- **ML/Data Processing**: Scikit-learn, Pandas, Langdetect
- **Document Parsing**: Apache Tika
- **Database**: SQLite
- **Frontend**: HTML, Bootstrap 5, jQuery, Chart.js
- **Web Server**: Nginx
- **Containerization**: Docker, Docker Compose

## Getting Started

### Prerequisites

- Docker
- Docker Compose
- WSL 2 (for Windows users)

### Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/docintellect.git
    cd docintellect
    ```

2.  **Create an initial ML model:**
    This project comes with a script to create a dummy model to get you started. For real-world use, you should replace the sample data in `create_dummy_model.py` with your own categorized examples.
    ```bash
    python3 create_dummy_model.py
    ```

3.  **Configure Scan Directories:**
    Open `docker-compose.yml` and edit the `volumes` section to mount the host directories you wish to scan.
    ```yaml
    # docker-compose.yml
    services:
      web:
        volumes:
          # ... other volumes
          - /mnt/d/MyLegalDocs:/scan-targets/drive_d:ro
          - /home/user/contracts:/scan-targets/contracts:ro
    ```

4.  **Build and run the containers:**
    ```bash
    docker-compose up --build
    ```

5.  **Access the Dashboard:**
    Open your web browser and navigate to `http://localhost`.

## Usage

1.  From the dashboard, select a target directory from the dropdown menu.
2.  Click the "Scan Selected Directory" button.
3.  The dashboard will update automatically as documents are processed and classified.
