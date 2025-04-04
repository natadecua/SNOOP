# Snoop: Linux Network Monitoring GUI

Snoop is a simple, script-based network monitoring tool with a web-based Graphical User Interface (GUI). It utilizes Bash scripting (`nmap`, `arp-scan`) for backend network scanning and Python Flask for the web frontend, allowing users to easily initiate scans and retrieve reports.

Based on the paper: *Snoop: A Linux script-based Network Monitoring with a web-based GUI System* by Cua, Castro, Sebastian, and Mayor.

## Features

*   **Active Network Scanning:**
    *   **Ping Scan (Host Discovery):** Uses `nmap -sn` to identify active hosts on the network.
    *   **ARP Scan:** Uses `arp-scan` to map IP addresses to MAC addresses for devices on the local network segment.
*   **Web-Based GUI:**
    *   Built with Flask (Python) and HTML/CSS/JS.
    *   Allows users to input the target network range (CIDR notation) and select the network interface.
    *   Provides buttons to start the scan and fetch the generated report.
    *   Displays status messages (scan completion, errors).
*   **Report Generation:** Compiles results from Ping Scan and ARP Scan into a single downloadable text file (`report.txt`).
*   **Logging:** Records key actions and errors to a log file (`network_tool.log`) for troubleshooting.
*   **Error Handling:** Basic validation for inputs and checks for scan command failures.

## Technology Stack

*   **Backend Scripting:** Bash
*   **Network Tools:** `nmap`, `arp-scan`
*   **Web Framework:** Flask (Python)
*   **Frontend:** HTML, CSS, JavaScript (embedded)
*   **Operating System:** Linux (designed and likely tested on distributions like Kali Linux)

## Prerequisites

*   **Linux Operating System:** Required for `nmap` and `arp-scan`.
*   **Python 3 and Pip:** To run the Flask application.
    ```bash
    sudo apt update
    sudo apt install python3 python3-pip -y
    ```
*   **Nmap:** Network scanning tool.
    ```bash
    sudo apt install nmap -y
    ```
*   **ARP-Scan:** ARP scanning tool.
    ```bash
    sudo apt install arp-scan -y
    ```

## Setup and Installation

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd snoop-network-monitor
    ```
2.  **(Recommended) Create and activate a virtual environment:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    # On Windows use `venv\Scripts\activate`
    ```
3.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Make the Bash script executable:**
    ```bash
    chmod +x network_tool.sh
    ```

## Usage

1.  **Run the Flask application:**
    ```bash
    python app.py
    ```
    *Note: The application runs the underlying bash script using `sudo`. It will likely prompt for your password in the terminal where you launched `app.py` the first time it needs to execute the scan.*

2.  **Access the Web UI:** Open your web browser and navigate to `http://127.0.0.1:5000`.

3.  **Perform a Scan:**
    *   Enter the **Network Range** in CIDR notation (e.g., `192.168.1.0/24`).
    *   Select the **Network Interface** from the dropdown (e.g., `eth0`, `wlan0`).
    *   Click **Start Scan**.
    *   Wait for the confirmation message ("Scan completed successfully!"). Check the terminal running `app.py` for progress or errors.

4.  **Retrieve Report:**
    *   Click the **Get Report** button.
    *   The `report.txt` file containing the scan results will be downloaded by your browser.

5.  **Check Logs:** The `network_tool.log` file in the project directory contains a history of operations and any errors encountered by the backend script.

## File Structure
snoop-network-monitor/
├── .gitignore # Specifies intentionally untracked files git should ignore
├── LICENSE # Project license file (e.g., MIT)
├── README.md # This file: project description and instructions
├── app.py # The main Flask application (web server)
├── network_tool.sh # The core Bash script performing scans
├── requirements.txt # Python dependencies for pip
└── templates/
└── index.html # HTML template for the web interface

## Authors

*   Nathanael Adrian T. Cua
*   Carlos Miguel M. Castro
*   James V. Sebastian
*   Gabrielle Adlei N. Mayor

*(Based on the research paper)*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.