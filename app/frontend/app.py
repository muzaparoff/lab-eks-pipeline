from flask import Flask, render_template
import requests
import os

app = Flask(__name__)
VERSION = os.getenv('APP_VERSION', '1.0.0')
BACKEND_URL = os.getenv('BACKEND_URL', 'http://backend-service:5000')

@app.route('/')
def home():
    response = requests.get(f'{BACKEND_URL}/data')
    db_value = response.json().get('value', '')
    return f"Hello Lab-commit {VERSION} - DB Value: {db_value}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)