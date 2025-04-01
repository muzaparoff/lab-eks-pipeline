from flask import Flask
import requests
import os
import threading
import time

app = Flask(__name__)
VERSION = os.getenv('APP_VERSION', '1.0.0')
BACKEND_URL = os.getenv('BACKEND_URL', 'http://backend-service:5000')
cached_value = "Loading..."

def fetch_data():
    global cached_value
    while True:
        try:
            response = requests.get(f'{BACKEND_URL}/data')
            if response.status_code == 200:
                cached_value = response.json().get('value', '')
        except Exception as e:
            print(f"Error fetching data: {e}")
        time.sleep(10)  # Fetch every 10 seconds

@app.route('/')
def home():
    return f"{cached_value} (Version: {VERSION})"

if __name__ == '__main__':
    # Start background data fetching
    threading.Thread(target=fetch_data, daemon=True).start()
    app.run(host='0.0.0.0', port=5000)