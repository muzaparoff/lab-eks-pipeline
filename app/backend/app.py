from flask import Flask, jsonify
import os
import psycopg2

app = Flask(__name__)

DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'database': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD')
}

def get_message():
    try:
        conn = psycopg2.connect(
            host=DB_CONFIG['host'],
            dbname=DB_CONFIG['database'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            connect_timeout=5
        )
        cur = conn.cursor()
        cur.execute("SELECT message FROM lab_table LIMIT 1;")
        row = cur.fetchone()
        cur.close()
        conn.close()
        return row[0] if row else "No message"
    except Exception as e:
        return f"Error: {str(e)}"

@app.route("/message", methods=["GET"])
def message():
    msg = get_message()
    return jsonify({"message": msg})

@app.route('/data')
def get_data():
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    cur.execute('SELECT value FROM lab_data LIMIT 1')
    value = cur.fetchone()[0]
    cur.close()
    conn.close()
    return jsonify({'value': value})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)