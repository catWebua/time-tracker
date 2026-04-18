import json

path = '/Users/alexi/Desktop/time-tracker/TimeTracker/Shared/Localizable.xcstrings'

with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

missing_en = {
    "ВІДСЛІДКОВУВАННЯ": "TRACKING"
}

for k, v in missing_en.items():
    if k not in data["strings"]:
        data["strings"][k] = {}
        
    s = data["strings"][k]
    
    if "localizations" not in s:
        s["localizations"] = {}
        
    s["localizations"]["en"] = {
        "stringUnit": {
            "state": "translated",
            "value": v
        }
    }

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

