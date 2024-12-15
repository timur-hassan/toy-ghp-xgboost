#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Step 1: Initialize a new GitHub repository if not already initialized
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit"
fi

# Step 2: Create directory structure for the workflow
echo "Creating directory structure..."
mkdir -p .github/workflows
mkdir -p scripts
mkdir -p reports
mkdir -p docs

# Step 3: Create .nojekyll file
touch docs/.nojekyll

# Step 4: Create the Python script
cat > scripts/xgboost_example.py << 'EOF'
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier
from sklearn.metrics import classification_report
import os

os.makedirs('reports', exist_ok=True)

X, y = np.random.rand(1000, 10), np.random.randint(0, 2, 1000)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)
model = XGBClassifier(eval_metric='logloss')
model.fit(X_train, y_train)
y_pred = model.predict(X_test)
report = classification_report(y_test, y_pred)

with open("reports/model_report.txt", "w") as f:
    f.write(report)
EOF

# Step 5: Create the workflow file
cat > .github/workflows/xgboost_workflow.yml << 'EOF'
name: XGBoost Workflow

on:
  push:
    branches:
      - main

jobs:
  run-xgboost:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: 3.8
      - run: |
          pip install numpy pandas scikit-learn xgboost
          python scripts/xgboost_example.py
      - uses: actions/upload-artifact@v3
        with:
          name: model-report
          path: reports/model_report.txt

  deploy:
    needs: run-xgboost
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/download-artifact@v3
        with:
          name: model-report
          path: reports
      - name: Create site
        run: |
          mkdir -p public
          touch public/.nojekyll
          echo "<html><body><pre>" > public/index.html
          cat reports/model_report.txt >> public/index.html
          echo "</pre></body></html>" >> public/index.html
      - name: Deploy
        uses: actions/upload-pages-artifact@v2
        with:
          path: public
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
        with:
          artifact_name: github-pages
EOF
# Step 6: Commit changes
git add .
git commit -m "Setup complete with .nojekyll"

echo "Done! Now push to GitHub and ensure GitHub Pages is enabled."