"""Rebuild index.html from src/template.html (fills in the inlined image data)."""
import json, pathlib
here = pathlib.Path(__file__).parent
t = (here / "src/template.html").read_text()
d = json.loads((here / "src/inline.json").read_text())
(here / "index.html").write_text(t.replace("__BASES__", " ".join(d["bases"])))
print("index.html rebuilt")
