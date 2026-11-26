"""Make the iPhone/iPad copy of the web app.

The App Store must not get hidden or switched-off features (App Review 2.5.19), so every
block marked  /* @web-only:start NAME */ ... /* @web-only:end NAME */  in index.html is
replaced by a small stub that keeps the rest of the app working. Website-only parts:
Facebook sign-in, Garden Club payments and the family pass (Stripe), the placeholder video,
and the switched-off Garden Loop game.
"""
import pathlib, re, sys

STUBS = {
    "accounts": 'var AUTH = null; function signedIn() { return false; } function signInWithFacebook() {} '
                'function authFromUrl() { return null; } function cloudSignInFinish() { return Promise.resolve(null); } '
                'function cloudPushSoon() {} function cloudPush() { return Promise.resolve(); } '
                'function accountCard() { return ""; } function wireAccountCard() {}',
    "club": 'var CLUB = { on: false, currency: "", trialDays: 0, plans: [], extraSpot: { price: 0, per: "", max: 0, link: "" }, manage: "" }; '
            'function clubFromUrl() { return null; } function renderClub() { go("settings"); } function deviceId() { return ""; } '
            'function passLink() { return ""; } function passCodeFromUrl() { return ""; } function finishAddSpots() {} '
            'function endGuestPass() {} function openPassClaim() {}',
    "video": 'function playVideo(reward, done) { done(); }',
    "loop1": 'let L = null; function stopLoop() {} function openLoopIntro() {}',
    "loop2": 'function renderLoop() { go("home"); }',
}

def strip(html):
    def sub(m):
        name = m.group(1)
        if name not in STUBS:
            sys.exit(f"No iPhone stub for web-only block '{name}'")
        return f"/* {name}: website only */ {STUBS[name]}\n"
    out, n = re.subn(r"/\* @web-only:start (\w+) \*/\n.*?/\* @web-only:end \1 \*/\n", sub, html, flags=re.S)
    if "@web-only" in out:
        sys.exit("Unmatched @web-only marker")
    return out, n

if __name__ == "__main__":
    root = pathlib.Path(__file__).resolve().parent.parent
    html, n = strip((root / "index.html").read_text())
    (root / "ios/Heather/Web/index.html").write_text(html)
    print(f"iPhone copy written: {n} website-only blocks replaced")
