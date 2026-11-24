# Heather

Gentle daily brain games for my grandma Heather: Daily Word, Quick Peek, Flower Match, Memory Lane and more, with a garden that grows as she plays.

- `index.html` is the whole app (built from `src/template.html` with `python3 build.py`).
- `words.json` is the word list for the word games.
- Game progress is saved in the browser. The **family circle** (invite links, shared Memory Lane questions) runs on Supabase through locked-down database functions; the publishable key in the app is safe to ship.

Hosted on Vercel; every push to `main` goes live.
