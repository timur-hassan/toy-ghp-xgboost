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

# Step 3: Create Jekyll config
cat > docs/_config.yml << EOF
title: XGBoost Model Report
baseurl: "/toy-ghp-xgboost"
url: "https://timur-hassan.github.io"
theme: jekyll-theme-minimal
EOF

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

  publish-to-pages:
    needs: run-xgboost
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v3
      - uses: actions/download-artifact@v3
        with:
          name: model-report
          path: reports
      - name: Create Pages
        run: |
          mkdir -p docs
          echo "<html><body><pre>" > docs/index.html
          cat reports/model_report.txt >> docs/index.html
          echo "</pre></body></html>" >> docs/index.html
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs
          force_orphan: true
EOF

# Step 6: Commit changes
git add .
git commit -m "Setup complete with Jekyll configuration"

echo "Done! Now push to GitHub and ensure GitHub Pages is enabled."