# DocIntellect

A smart, containerized document classification system designed for legal and professional environments. DocIntellect automatically scans, extracts text, and categorizes documents from various sources using a trainable machine learning model.

## Recommended Setup: Virtual Machine

This application is designed to run in a dedicated Linux environment. The most reliable method is to use a VirtualBox VM.

### Tech Stack

- **Backend**: Python, Flask, Gunicorn
- **Document Parsing**: Apache Tika Server
- **Database**: SQLite
- **Containerization**: Docker, Docker Compose
- **Web Server**: Nginx

### VM Installation & Setup

1.  **Create a VM**: Set up a VirtualBox VM with **Ubuntu Server 22.04 LTS**.
    -   Minimum **4GB RAM** and **2 CPUs**.
    -   Ensure you install the **OpenSSH server** during setup.

2.  **Install Docker**: SSH into your new VM and follow the [official Docker installation guide for Ubuntu](https://docs.docker.com/engine/install/ubuntu/). This ensures a clean, native installation.

3.  **Clone the Repository**:
    ```bash
    git clone https://github.com/rezanuhebring/DocIntellect.git
    cd DocIntellect
    ```

4.  **Run the Setup Script**: This script will configure permissions, prepare necessary files, and launch the application.
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```
    *Note: The first time you run the script, it will add your user to the `docker` group and ask you to log out and log back in. This is a one-time setup step.*

5.  **Configure Volumes**: The setup script will open `docker-compose.yml` in a text editor. Add the paths to your document directories that exist *inside the VM*.

### Accessing the Application

1.  **Configure Port Forwarding**: In your VirtualBox VM settings (under Network > Advanced > Port Forwarding), create a rule to forward traffic from the Host Port `80` to the Guest Port `80`.

2.  **Access the Dashboard**: Open a web browser on your main (host) computer and navigate to:
    > **http://localhost**

### Managing the Application

All commands are run from within the project directory inside your VM's SSH session.

-   **View Logs**: `docker compose logs -f`
-   **Stop Application**: `docker compose down`
-   **Start Application**: `docker compose up -d`