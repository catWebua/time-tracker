import json

path = '/Users/alexi/Desktop/time-tracker/TimeTracker/Shared/Localizable.xcstrings'

with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

new_translations = {
    "notification_daily_body": {
        "uk": "Не забудь запустити таймер!",
        "en": "Don't forget to start the timer!"
    },
    "notification_long_running_title": {
        "uk": "Таймер ще тікає ⏱",
        "en": "Timer is still ticking ⏱"
    },
    "notification_long_running_body": {
        "uk": "Ти відслідковуєш час вже %d год. — може час зупинитись?",
        "en": "You've been tracking for %d h. — maybe time to stop?"
    },
    "week": {
        "uk": "Тиждень",
        "en": "Week"
    },
    "month": {
        "uk": "Місяць",
        "en": "Month"
    },
    "all": {
        "uk": "Весь",
        "en": "All"
    },
    "ДИНАМІКА РОБОТИ": {
        "uk": "ДИНАМІКА РОБОТИ",
        "en": "WORK DYNAMICS"
    },
    "РОЗПОДІЛ ПО ПРОЕКТАХ": {
        "uk": "РОЗПОДІЛ ПО ПРОЕКТАХ",
        "en": "PROJECT BREAKDOWN"
    },
    "Зроблено з 💜 для Фрілансерів": {
        "uk": "Зроблено з 💜 для Фрілансерів",
        "en": "Made with 💜 for Freelancers"
    }
}

for k, trans in new_translations.items():
    if k not in data["strings"]:
        data["strings"][k] = {"localizations": {}}
    
    s = data["strings"][k]
    if "localizations" not in s:
        s["localizations"] = {}
    
    for lang, val in trans.items():
        s["localizations"][lang] = {
            "stringUnit": {
                "state": "translated",
                "value": val
            }
        }

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
