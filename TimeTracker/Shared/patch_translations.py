import json

path = '/Users/alexi/Desktop/time-tracker/TimeTracker/Shared/Localizable.xcstrings'

with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

missing_en = {
    "%lldг": "%lldh",
    "%lldг залишилось": "%lldh remaining",
    "OK": "OK",
    "UAH": "UAH",
    "USD": "USD",
    "Активного таймера немає": "No active timer",
    "Архівувати": "Archive",
    "Бюджет": "Budget",
    "Годин": "Hours",
    "Готово": "Done",
    "ДЕННА ЦІЛЬ": "DAILY GOAL",
    "Денна ціль": "Daily goal",
    "День": "Day",
    "Запускає таймер для останнього обраного проекту у FreelanceKit": "Starts the timer for the last selected project in FreelanceKit",
    "Запустити": "Start",
    "Зберегти зміни": "Save changes",
    "Звіт (%@)": "Report (%@)",
    "Зупинити": "Stop",
    "Зупиняє активний таймер у FreelanceKit": "Stops the active timer in FreelanceKit",
    "Кінець": "End",
    "Ліміт вичерпано": "Limit reached",
    "Натисни для відкриття": "Tap to open",
    "Немає записів": "No entries",
    "Перемкнути таймер": "Toggle timer",
    "Період": "Period",
    "Помилка": "Error",
    "Початок": "Start",
    "Розархівувати": "Unarchive",
    "Спочатку створи проект у FreelanceKit": "First create a project in FreelanceKit",
    "Стан": "Status",
    "Старт таймер": "Start Timer",
    "Створити проект": "Create project",
    "Стоп таймер": "Stop Timer",
    "Таймер FreelanceKit": "FreelanceKit Timer",
    "Таймер запущено для «%@»": "Timer started for «%@»",
    "Таймер зупинено. Відпрацьовано %@ для «%@»": "Timer stopped. Worked %@ for «%@»",
    "Тікає": "Running",
    "ЦІЛЬ ДОСЯГНУТА 🎉": "GOAL REACHED 🎉",
    "Ціль досягнута! 🎉": "Goal reached! 🎉",
    "Чим займаєшся?": "What are you working on?",
    "Швидкий запуск та зупинка таймера.": "Quick start and stop of the timer."
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

