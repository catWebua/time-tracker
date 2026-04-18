import json

path = '/Users/alexi/Desktop/time-tracker/TimeTracker/Shared/Localizable.xcstrings'

with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

missing_en = {
    "АКТИВНО": "ACTIVE",
    "ЗУПИНЕНО": "STOPPED",
    "ТАЙМЕР ЗАПУЩЕНО": "TIMER RUNNING",
    "Дивись і керуй таймером прямо з Home Screen.": "View and manage the timer right from the Home Screen.",
    "FreelanceKit Таймер": "FreelanceKit Timer",
    "%@ / %lldг": "%1$@ / %2$lldh",
    "%@ з %lldг сьогодні": "%1$@ of %2$lldh today",
    "%lld НЕ ОПЛАЧЕНО": "%lld UNBILLED",
    "Архів (%lld)": "Archive (%lld)",
    "Через %lld год.": "In %lld h.",
    "РОБОЧА СЕСІЯ": "WORK SESSION",
    "залишилось %@": "%@ remaining",
    "Кільце Прогресу": "Ring of Progress",
    "Зроблено з 💜 для Фрілансерів": "Made with 💜 for Freelancers",
    "Таймер іде задовго": "Timer is running too long",
    "Новий запис": "New Entry",
    "Редагувати": "Edit",
    "Зберегти запис": "Save Entry",
    "Додати до історії": "Add to History",
    "Сповіщення заблоковані": "Notifications Disabled",
    "ЗАГАЛЬНЕ": "GENERAL",
    "Українська": "Ukrainian",
    "English": "English",
    "СПОВІЩЕННЯ": "NOTIFICATIONS",
    "Щоденне нагадування": "Daily Reminder",
    "Час нагадування": "Reminder Time",
    "ВІДЖЕТ": "WIDGET",
    "ПРО ЗАСТОСУНОК": "ABOUT THE APP",
    "Версія": "Version",
    "Сховище": "Storage",
    "Незабаром": "Coming Soon",
    "Довго натисни на Home Screen": "Long press on Home Screen",
    "Натисни «+» у кутку": "Tap «+» in the corner",
    "Знайди «FreelanceKit»": "Find «FreelanceKit»",
    "Вибери розмір та додай": "Select size and add",
    "залишилось %1$@": "%1$@ remaining",
    "Через %1$lld год.": "In %1$lld h."
}

for k, v in missing_en.items():
    if k not in data["strings"]:
        data["strings"][k] = {}
        
    s = data["strings"][k]
    
    if "localizations" not in s:
        s["localizations"] = {}
        
    # Set english translation
    s["localizations"]["en"] = {
        "stringUnit": {
            "state": "translated",
            "value": v
        }
    }

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Patched localization catalog!")
