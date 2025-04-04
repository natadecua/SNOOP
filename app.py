from flask import Flask, request, send_file, jsonify, render_template
import subprocess
import os

app = Flask(__name__)

# Define the report file name
REPORT_FILE = 'report.txt'
LOG_FILE = 'network_tool.log' # Match bash script
SCRIPT_FILE = './network_tool.sh'

@app.route('/')
def index():
    # Using render_template to serve the HTML file from the templates directory
    return render_template('index.html')

@app.route('/run-scan', methods=['POST'])
def run_scan():
    network = request.form.get('network')
    interface = request.form.get('interface')

    # Basic input validation
    if not network or not interface:
        return "Network range and interface are required", 400

    # Construct the command to run the bash script with sudo
    command = [
        'sudo', SCRIPT_FILE,
        '-n', network,
        '-i', interface
    ]

    try:
        # Run the bash script
        # Using capture_output=True to get stdout/stderr
        # Using text=True to get strings instead of bytes
        # Using check=True to raise CalledProcessError on non-zero exit codes
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True,
            timeout=120 # Add a timeout (e.g., 2 minutes) to prevent hanging
        )

        # Check script's stdout for success message (optional, relies on script output)
        # Or just rely on check=True which checks exit code 0
        # script_output = result.stdout

        # Check stderr for any errors logged by the script itself, even if exit code was 0
        if result.stderr:
             # Log stderr for debugging, but might not indicate failure if script handles errors internally
             print(f"Script stderr: {result.stderr}") # Print to Flask console

        # If check=True passes (exit code 0), assume success
        return "Scan completed successfully! Check the logs for details.", 200

    except subprocess.CalledProcessError as e:
        # Script returned a non-zero exit code
        error_message = f"Error running scan script: Exit Code {e.returncode}\n"
        error_message += f"Stderr: {e.stderr}\n"
        error_message += f"Stdout: {e.stdout}"
        print(error_message) # Log to Flask console
        # Try to read the log file for more context from the script
        log_content = ""
        if os.path.exists(LOG_FILE):
            try:
                with open(LOG_FILE, 'r') as f:
                    # Get last few lines of the log
                    log_lines = f.readlines()
                    log_content = "".join(log_lines[-10:]) # Last 10 lines
            except Exception as log_e:
                log_content = f"(Could not read log file: {log_e})"

        return f"Scan failed. Check logs.\nScript Error: {e.stderr}\nLog Tail:\n{log_content}", 500

    except subprocess.TimeoutExpired as e:
        print(f"Scan script timed out: {e}")
        return "Scan script timed out.", 500

    except FileNotFoundError:
        print(f"Error: Script file '{SCRIPT_FILE}' not found or sudo is not available.")
        return f"Error: Script file '{SCRIPT_FILE}' not found or sudo is not available.", 500

    except Exception as e:
        # Catch any other unexpected errors
        print(f"An unexpected error occurred: {e}")
        return f"An unexpected server error occurred: {e}", 500


@app.route('/get-report', methods=['GET'])
def get_report():
    if os.path.exists(REPORT_FILE):
        # Use send_file to allow the browser to download the report
        return send_file(REPORT_FILE, as_attachment=True)
    else:
        return "Report file not found.", 404

@app.route('/interfaces', methods=['GET'])
def get_interfaces():
    # Get network interfaces using the 'ip link show' command
    try:
        # Run the 'ip link show' command
        result = subprocess.run(['ip', '-o', 'link', 'show'],
                                capture_output=True, text=True, check=True)

        # Parse the output to get interface names
        interfaces = []
        lines = result.stdout.strip().splitlines()
        for line in lines:
            parts = line.split(': ')
            if len(parts) > 1:
                iface_name = parts[1].split('@')[0] # Get name, remove potential @ifX part
                # Basic filtering - avoid 'lo', docker, virtual interfaces if desired
                if iface_name != 'lo' and not iface_name.startswith(('docker', 'veth', 'br-')):
                     interfaces.append(iface_name)

        return jsonify(interfaces)

    except subprocess.CalledProcessError as e:
        print(f"Error getting interfaces: {e.stderr}")
        return f"Error fetching interfaces: {e.stderr}", 500
    except FileNotFoundError:
         print("Error: 'ip' command not found.")
         return "Error: could not execute 'ip' command.", 500
    except Exception as e:
        print(f"An unexpected error occurred while fetching interfaces: {e}")
        return f"An unexpected error occurred fetching interfaces: {e}", 500


if __name__ == '__main__':
    # Set debug=False for production
    # Host='0.0.0.0' makes it accessible on the network, 127.0.0.1 is local only
    app.run(debug=True, host='127.0.0.1', port=5000)