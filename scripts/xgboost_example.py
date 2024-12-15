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
