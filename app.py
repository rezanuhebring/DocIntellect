# /home/user/document_classifier/app.py

import os
import sqlite3
import pickle
import threading
from datetime import datetime
import pandas as pd
from io import StringIO

from flask import Flask, jsonify, render_template, request, g, Response
from tika import parser
from langdetect import detect, LangDetectException

# --- APP CONFIGURATION ---
DATABASE = 'database.db'
MODEL_PATH = 'model.pkl'
# Define the parent directory inside the container where all drives are mounted
SCAN_TARGETS_BASE = '/scan-targets'

app = Flask(__name__)

# --- DATABASE HELPERS ---
def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

# --- ML MODEL LOADING ---
try:
    with open(MODEL_PATH, 'rb') as f:
        model = pickle.load(f)
    print("--- Machine Learning Model loaded successfully. ---")
except FileNotFoundError:
    print(f"--- FATAL ERROR: Model file not found at {MODEL_PATH}. Please run create_dummy_model.py first. ---")
    model = None


# --- BACKGROUND PROCESSING ---
def process_documents_thread(target_directory):
    """The main worker function that scans a given directory in a background thread."""
    print(f"--- Background scan started for directory: {target_directory} ---")
    processed_count = 0
    with app.app_context(): # Need app context to access DB
        db = get_db()
        cursor = db.cursor()

        for root, _, files in os.walk(target_directory):
            for filename in files:
                if not filename.lower().endswith(('.pdf', '.doc', '.docx', '.xls', '.xlsx', '.wpd')):
                    continue

                file_path = os.path.join(root, filename)
                try:
                    mod_time_stamp = os.path.getmtime(file_path)
                    mod_time = datetime.fromtimestamp(mod_time_stamp)

                    # Check if file is already processed and up-to-date
                    cursor.execute("SELECT modified_date FROM documents WHERE filename = ?", (file_path,))
                    result = cursor.fetchone()
                    if result and datetime.fromisoformat(result['modified_date']) >= mod_time:
                        continue # Skip if already processed and not modified

                    print(f"Processing: {file_path}")
                    # 1. Extract content with Tika
                    parsed = parser.from_file(file_path)
                    content = parsed.get('content', '')
                    metadata = parsed.get('metadata', {})
                    if not content:
                        print(f"Warning: No content extracted from {filename}")
                        continue
                    
                    content = content.strip()

                    # 2. Detect Language
                    try:
                        lang = detect(content[:500]) # Use first 500 chars for speed
                    except LangDetectException:
                        lang = 'unknown'

                    # 3. Classify with ML Model
                    predicted_category = model.predict([content])[0]
                    confidence_scores = model.predict_proba([content])[0]
                    confidence = max(confidence_scores)

                    # 4. Store in Database (UPSERT logic)
                    doc_data = {
                        "filename": file_path,
                        "created_date": metadata.get('Creation-Date'),
                        "modified_date": mod_time.isoformat(),
                        "created_by": metadata.get('Author') or metadata.get('creator'),
                        "content": content,
                        "language": lang,
                        "predicted_category": predicted_category,
                        "confidence_score": float(confidence),
                        "status": "Processed"
                    }
                    
                    cursor.execute("""
                        INSERT INTO documents (filename, created_date, modified_date, created_by, content, language, predicted_category, confidence_score, status)
                        VALUES (:filename, :created_date, :modified_date, :created_by, :content, :language, :predicted_category, :confidence_score, :status)
                        ON CONFLICT(filename) DO UPDATE SET
                            modified_date=excluded.modified_date,
                            content=excluded.content,
                            language=excluded.language,
                            predicted_category=excluded.predicted_category,
                            confidence_score=excluded.confidence_score,
                            status=excluded.status;
                    """, doc_data)
                    db.commit()
                    processed_count += 1

                except Exception as e:
                    print(f"!!! ERROR processing {file_path}: {e}")
                    cursor.execute("""
                        INSERT INTO documents (filename, status) VALUES (?, 'Failed')
                        ON CONFLICT(filename) DO UPDATE SET status='Failed';
                    """, (file_path,))
                    db.commit()

    print(f"--- Background scan finished. Processed {processed_count} new/updated files. ---")


# --- FLASK ROUTES (API ENDPOINTS) ---
@app.route('/')
def index():
    """Serves the main dashboard page."""
    return render_template('index.html')

@app.route('/api/scan_locations')
def get_scan_locations():
    """Lists the available top-level directories from the mounted scan targets."""
    if not os.path.exists(SCAN_TARGETS_BASE) or not os.path.isdir(SCAN_TARGETS_BASE):
        return jsonify([])
    
    locations = [os.path.join(SCAN_TARGETS_BASE, d) for d in os.listdir(SCAN_TARGETS_BASE) if os.path.isdir(os.path.join(SCAN_TARGETS_BASE, d))]
    return jsonify(sorted(locations))

@app.route('/api/scan', methods=['POST'])
def start_scan():
    """Triggers the background document scanning process for a specific path."""
    if not model:
        return jsonify({"error": "Model not loaded, cannot scan."}), 500
    
    data = request.get_json()
    if not data or 'path' not in data:
        return jsonify({"error": "Missing 'path' in request body."}), 400

    scan_path = data['path']

    # --- SECURITY CHECK ---
    # Ensure the requested path is a valid and safe subdirectory.
    if not os.path.abspath(scan_path).startswith(SCAN_TARGETS_BASE):
        return jsonify({"error": f"Disallowed path. Must be inside {SCAN_TARGETS_BASE}."}), 403
    
    if not os.path.isdir(scan_path):
        return jsonify({"error": f"Path '{scan_path}' does not exist or is not a directory in the container."}), 404

    thread = threading.Thread(target=process_documents_thread, args=(scan_path,))
    thread.daemon = True
    thread.start()
    
    return jsonify({"message": f"Scan started for '{scan_path}'. Dashboard will update automatically."})

@app.route('/api/documents')
def get_documents():
    """Returns a list of all processed documents."""
    cursor = get_db().cursor()
    cursor.execute("SELECT filename, predicted_category, confidence_score, language, modified_date FROM documents WHERE status = 'Processed' ORDER BY modified_date DESC")
    docs = [dict(row) for row in cursor.fetchall()]
    return jsonify(docs)

@app.route('/api/stats')
def get_stats():
    """Returns key statistics for the dashboard."""
    cursor = get_db().cursor()
    # Total documents
    cursor.execute("SELECT COUNT(id) FROM documents WHERE status = 'Processed'")
    total = cursor.fetchone()[0]
    # Documents by category
    cursor.execute("SELECT predicted_category, COUNT(id) FROM documents WHERE status = 'Processed' GROUP BY predicted_category")
    by_category = {row['predicted_category']: row['COUNT(id)'] for row in cursor.fetchall()}

    return jsonify({
        "total_documents": total,
        "by_category": by_category
    })

@app.route('/download_csv')
def download_csv():
    """Downloads the entire database as a CSV file."""
    db = get_db()
    df = pd.read_sql_query("SELECT * FROM documents", db)
    
    csv_buffer = StringIO()
    df.to_csv(csv_buffer, index=False)
    
    return Response(
        csv_buffer.getvalue(),
        mimetype="text/csv",
        headers={"Content-disposition": "attachment; filename=document_export.csv"}
    )

def setup_database(app):
    """Initializes the database and creates the table if it doesn't exist."""
    with app.app_context():
        db = get_db()
        db.execute("""
            CREATE TABLE IF NOT EXISTS documents (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                filename TEXT UNIQUE NOT NULL,
                created_date TEXT,
                modified_date TEXT,
                created_by TEXT,
                content TEXT,
                language TEXT,
                predicted_category TEXT,
                confidence_score REAL,
                status TEXT
            );
        """)
        db.commit()

# --- MAIN EXECUTION ---
if __name__ == '__main__':
    # This block runs when you execute `python app.py` directly
    setup_database(app)
    app.run(host='0.0.0.0', port=5000)
else:
    # This block runs when the app is started by Gunicorn (in production)
    setup_database(app)