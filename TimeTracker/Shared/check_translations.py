import json

path = '/Users/alexi/Desktop/time-tracker/TimeTracker/Shared/Localizable.xcstrings'

with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

missing = []
for k, v in data.get("strings", {}).items():
    if not v.get("localizations", {}).get("en"):
        missing.append(k)

print(f"Total strings: {len(data.get('strings', {}))}")
print(f"Missing English: {len(missing)}")
for m in sorted(missing):
    print(f" - {m}")
