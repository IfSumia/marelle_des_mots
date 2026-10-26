"""Extract the word lists from the V1 HTML into assets/data/lessons.json.

Usage: python3 tool/extract_lists.py path/to/marelle-des-mots.html
Run again whenever you change the lists in the HTML (optional: you can also
just edit assets/data/lessons.json by hand).
"""
import json, re, sys

html = open(sys.argv[1], encoding="utf-8").read()

def grab(const_name):
    m = re.search(r"const\s+" + const_name + r"\s*=\s*\[(.*?)\];", html, re.S)
    if not m:
        raise SystemExit(f"{const_name} not found")
    return re.findall(r'"((?:[^"\\]|\\.)*)"', m.group(1))

lessons = []
for n in range(3, 20):
    try:
        words = grab(f"LECTURE_{n}")
    except SystemExit:
        continue
    lessons.append({"id": f"lecture{n}", "number": n, "title": f"Lecture {n}", "words": words})

out = {
    "toolWords": {"id": "default", "title": "Mots outils", "words": grab("DEFAULT_WORDS")},
    "lessons": lessons,
}
json.dump(out, open("assets/data/lessons.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("lessons:", [(l["number"], len(l["words"])) for l in lessons], "tool words:", len(out["toolWords"]["words"]))
