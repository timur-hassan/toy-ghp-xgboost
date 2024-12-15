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

# Step 3: Create the Python script for XGBoost on synthetic data
cat > scripts/xgboost_example.py <<EOF
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier
from sklearn.metrics import classification_report

# Generate synthetic dataset
X, y = np.random.rand(1000, 10), np.random.randint(0, 2, 1000)

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# Train XGBoost classifier
model = XGBClassifier(use_label_encoder=False, eval_metric='logloss')
model.fit(X_train, y_train)

# Make predictions
y_pred = model.predict(X_test)

# Generate classification report
report = classification_report(y_test, y_pred)

# Save report
with open("reports/model_report.txt", "w") as f:
    f.write(report)

print("Model report generated at reports/model_report.txt")
EOF

# Step 4: Create the GitHub workflow YAML file
cat > .github/workflows/xgboost_workflow.yml <<EOF
name: XGBoost Workflow

on:
  push:
    branches:
      - main

jobs:
  run-xgboost:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: 3.8

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install numpy pandas scikit-learn xgboost

      - name: Run XGBoost script
        run: python scripts/xgboost_example.py

      - name: Upload report
        uses: actions/upload-artifact@v3
        with:
          name: model-report
          path: reports/model_report.txt

  publish-to-pages:
    needs: run-xgboost
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Upload report to GitHub Pages
        run: |
          mkdir -p public
          cp reports/model_report.txt public/
          echo "XGBoost Model Report" > public/index.html
          echo "<pre>" >> public/index.html
          cat reports/model_report.txt >> public/index.html
          echo "</pre>" >> public/index.html

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: \${{ secrets.GITHUB_TOKEN }}
          publish_dir: public
EOF

# Step 5: Commit the workflow and scripts
echo "Adding and committing files to the repository..."
git add .
git commit -m "Add XGBoost workflow and scripts"

echo "Done! Push your repository to GitHub and ensure GitHub Pages is enabled."
