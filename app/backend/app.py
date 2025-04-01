from flask import Flask, jsonify
import os
import psycopg2
from init_db import DB_CONFIG

app = Flask(__name__)

@app.route('/data')
def get_data():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute('SELECT value FROM lab_data ORDER BY created_at DESC LIMIT 1')
        value = cur.fetchone()[0]
        cur.close()
        conn.close()
        return jsonify({'value': value})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)