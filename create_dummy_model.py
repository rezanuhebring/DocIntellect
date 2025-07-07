# /home/user/document_classifier/create_dummy_model.py

import pickle
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline

print("Creating a dummy classification model...")

# In a real project, you would load hundreds of categorized documents here.
# For this prototype, we'll use simple sample data.
dummy_data = [
    ("This agreement is for the lease of the property.", "Contract Law"),
    ("The patent for the invention was filed yesterday.", "Intellectual Property"),
    ("We are filing a lawsuit for breach of contract.", "Litigation"),
    ("The company bylaws need to be amended.", "Corporate Law"),
    ("Perjanjian sewa menyewa ini harus ditandatangani.", "Contract Law"), # Bahasa example
    ("Gugatan class action telah didaftarkan di pengadilan.", "Litigation") # Bahasa example
]

# Unpack the data into texts and labels
texts, labels = zip(*dummy_data)

# Create a machine learning pipeline
# 1. TfidfVectorizer: Converts text into numerical features.
# 2. LogisticRegression: A simple and effective classification algorithm.
model = Pipeline([
    ('vectorizer', TfidfVectorizer(ngram_range=(1, 2))),
    ('classifier', LogisticRegression())
])

# Train the model on our dummy data
model.fit(texts, labels)

# Save the trained model to a file
with open('model.pkl', 'wb') as f:
    pickle.dump(model, f)

print("Model 'model.pkl' created successfully.")
print("This model is trained to recognize categories: 'Contract Law', 'Intellectual Property', 'Litigation', 'Corporate Law'.")