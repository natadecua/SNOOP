from flask import Flask, request, send_file, jsonify
import subprocess
import os

app = Flask(__name__)

@app.route('/')
def index():
    return open('templates/index.html').read()

@app.route('/run-scan', methods=['POST'])
def run_scan():
    network = request.form.get('network')
    interface = request.form.get('interface')

    # Validate inputs
    if not network or not interface:
        return "Network and interface are required", 400

    # Run the bash script with sudo
    try:
        result = subprocess.run(
            ['sudo', './network_tool.sh', '-n', network, '-i', interface],
            capture_output=True,
            text=True,
            check=True
        )
        return "Scan completed successfully! Check the logs for details."
    except subprocess.CalledProcessError as e:
        return f"Error: {e.stderr}", 500

@app.route('/get-report', methods=['GET'])
def get_report():
    if os.path.exists('report.txt'):
        return send_file('report.txt', as_attachment=True)
    else:
        return "No report available", 404

@app.route('/interfaces', methods=['GET'])
def get_interfaces():
    try:
        result = subprocess.run(['ip', 'link', 'show'], capture_output=True, text=True, check=True)
        interfaces = [line.split(':')[1].strip() for line in result.stdout.splitlines() if ':' in line]
        return jsonify(interfaces)
    except subprocess.CalledProcessError as e:
        return f"Error: {e.stderr}", 500

if __name__ == '__main__':
    app.run(debug=True)
