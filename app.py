# app.py
import os, sqlite3, pickle, threading, json, requests
from datetime import datetime
import pandas as pd
from io import StringIO
from flask import Flask, jsonify, render_template, request, g, Response
from langdetect import detect, LangDetectException

DATABASE = 'database.db'
MODEL_PATH = 'model.pkl'
SCAN_TARGETS_BASE = '/scan-targets'
# Get the Tika server URL from the environment variable
TIKA_SERVER_URL = os.environ.get('TIKA_SERVER_URL', 'http://localhost:9998/tika')

app = Flask(__name__)

# --- Database and Model setup (no changes) ---
def get_db():
    db = getattr(g, '_database', None)
    if db is None: db = g._database = sqlite3.connect(DATABASE); db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None: db.close()

try: model = pickle.load(open(MODEL_PATH, 'rb')); print("--- ML Model loaded. ---")
except FileNotFoundError: print(f"--- FATAL: Model not found at {MODEL_PATH}.---"); model = None

# --- NEW Tika Parsing Function ---
def parse_with_tika_server(file_path):
    """Sends a file to the Tika server and gets the text content."""
    headers = { "Accept": "text/plain" }
    with open(file_path, 'rb') as f:
        response = requests.put(TIKA_SERVER_URL, data=f, headers=headers)
    response.raise_for_status()  # Raise an exception for bad status codes
    return response.text

# --- Background Processing (MODIFIED) ---
def process_documents_thread(target_directory):
    print(f"--- Background scan started for: {target_directory} ---")
    with app.app_context():
        db = get_db(); cursor = db.cursor()
        for root, _, files in os.walk(target_directory):
            for filename in files:
                if not filename.lower().endswith(('.pdf', '.doc', '.docx', '.xls', '.xlsx', '.wpd')): continue
                file_path = os.path.join(root, filename)
                try:
                    mod_time = datetime.fromtimestamp(os.path.getmtime(file_path))
                    cursor.execute("SELECT modified_date FROM documents WHERE filename = ?", (file_path,))
                    result = cursor.fetchone()
                    if result and datetime.fromisoformat(result['modified_date']) >= mod_time: continue
                    
                    print(f"Processing: {file_path}")
                    # 1. Extract content using the new server method
                    content = parse_with_tika_server(file_path).strip()
                    if not content: continue
                    
                    # 2. Detect Language
                    try: lang = detect(content[:500])
                    except LangDetectException: lang = 'unknown'

                    # 3. Classify with ML Model
                    pred_cat = model.predict([content])[0]; confidence = max(model.predict_proba([content])[0])
                    
                    # 4. Store in DB
                    doc_data = {"filename": file_path, "modified_date": mod_time.isoformat(), "content": content, "language": lang, "predicted_category": pred_cat, "confidence_score": float(confidence), "status": "Processed"}
                    cursor.execute("INSERT INTO documents (filename, modified_date, content, language, predicted_category, confidence_score, status) VALUES (:filename, :modified_date, :content, :language, :predicted_category, :confidence_score, :status) ON CONFLICT(filename) DO UPDATE SET modified_date=excluded.modified_date, content=excluded.content, language=excluded.language, predicted_category=excluded.predicted_category, confidence_score=excluded.confidence_score, status=excluded.status;", doc_data)
                    db.commit()
                except Exception as e:
                    print(f"!!! ERROR processing {file_path}: {e}")
                    cursor.execute("INSERT INTO documents (filename, status) VALUES (?, 'Failed') ON CONFLICT(filename) DO UPDATE SET status='Failed';", (file_path,)); db.commit()
    print(f"--- Scan finished. ---")

# The rest of the app.py file (routes, db setup) remains the same as before.
# ... (All routes like @app.route('/'), @app.route('/api/scan'), etc. are unchanged)
@app.route('/')
def index(): return render_template('index.html')

@app.route('/api/scan', methods=['POST'])
def start_scan():
    if not model: return jsonify({"error": "Model not loaded"}), 500
    data = request.get_json(); scan_path = data.get('path')
    if not scan_path: return jsonify({"error": "Missing 'path' in request."}), 400
    if not os.path.abspath(scan_path).startswith(SCAN_TARGETS_BASE): return jsonify({"error": "Disallowed path."}), 403
    if not os.path.isdir(scan_path): return jsonify({"error": f"Path '{scan_path}' not found."}), 404
    thread = threading.Thread(target=process_documents_thread, args=(scan_path,)); thread.daemon = True; thread.start()
    return jsonify({"message": f"Scan started for '{scan_path}'."})

@app.route('/api/documents')
def get_documents():
    cursor = get_db().cursor(); cursor.execute("SELECT filename, predicted_category, confidence_score, language, modified_date FROM documents WHERE status = 'Processed' ORDER BY modified_date DESC")
    return jsonify([dict(row) for row in cursor.fetchall()])

@app.route('/api/stats')
def get_stats():
    cursor = get_db().cursor(); cursor.execute("SELECT COUNT(id) FROM documents WHERE status = 'Processed'"); total = cursor.fetchone()[0]
    cursor.execute("SELECT predicted_category, COUNT(id) FROM documents WHERE status = 'Processed' GROUP BY predicted_category")
    by_category = {row['predicted_category']: row['COUNT(id)'] for row in cursor.fetchall()}
    return jsonify({"total_documents": total, "by_category": by_category})

@app.route('/download_csv')
def download_csv():
    df = pd.read_sql_query("SELECT * FROM documents", get_db()); csv_buffer = StringIO(); df.to_csv(csv_buffer, index=False)
    return Response(csv_buffer.getvalue(), mimetype="text/csv", headers={"Content-disposition": "attachment; filename=document_export.csv"})

def setup_database(app):
    with app.app_context():
        db = get_db(); db.execute("CREATE TABLE IF NOT EXISTS documents (id INTEGER PRIMARY KEY, filename TEXT UNIQUE NOT NULL, created_date TEXT, modified_date TEXT, created_by TEXT, content TEXT, language TEXT, predicted_category TEXT, confidence_score REAL, status TEXT);"); db.commit()

if __name__ == '__main__': setup_database(app); app.run(host='0.0.0.0', port=5000)
else: setup_database(app)