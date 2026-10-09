import os

itin_py_path = r"c:\Users\parra\OneDrive\Desktop\naviigo-web\NaviiGo-Website\backend\services\itinerary_model.py"
with open(itin_py_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("\\n    # 6. Browsing signals boost", "\n    # 6. Browsing signals boost")

with open(itin_py_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Fixed itinerary_model.py")
