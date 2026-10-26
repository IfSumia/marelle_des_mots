"""Merge lessons from the syllables / words_and_phrases / sentences / text format
into assets/data/lessons.json. Same lecture number = replaced.

Usage: python3 tool/import_lessons.py new_lessons.txt
Deck cards = syllables + words_and_phrases. sentences and text are stored for later.
"""
import json, re, sys

src = json.load(open(sys.argv[1], encoding="utf-8"))
path = "assets/data/lessons.json"
data = json.load(open(path, encoding="utf-8"))
by_num = {l["number"]: l for l in data["lessons"]}

for key, v in src.items():
    n = int(re.search(r"(\d+)", key).group(1))
    by_num[n] = {
        "id": f"lecture{n}",
        "number": n,
        "title": f"Lecture {n}",
        "words": v.get("syllables", []) + v.get("words_and_phrases", []),
        "sentences": v.get("sentences", []),
        "text": v.get("text", []),
    }

data["lessons"] = [by_num[k] for k in sorted(by_num)]
json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print([(l["number"], len(l["words"])) for l in data["lessons"]])
