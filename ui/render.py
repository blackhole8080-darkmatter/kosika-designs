"""Draw a Kosika Designs screen description as a page, with no model.

    python ui/render.py ui/samples/study-phone.json            # writes ui/out/study-phone.html
    python ui/render.py ui/samples/*.json --shots               # and a PNG of each (needs Playwright)

The kosika repo sits next to this one, unless KOSIKA_HOME says otherwise.
KOSIKA names the engine to run (default: kosika-native on PATH, else kosika).
"""
import ast, glob, json, os, shutil, subprocess, sys

here = os.path.dirname(os.path.abspath(__file__))
home = os.environ.get("KOSIKA_HOME") or os.path.join(here, "..", "..", "kosika")
module = os.path.join(home, "kosika", "std", "designs_ui.kos")
engine = os.environ.get("KOSIKA") or shutil.which("kosika-native") or "kosika"


def render(path):
    run = subprocess.run([engine, "run", module, "--workflow", "ui_render", "--input", path],
                         capture_output=True, text=True, encoding="utf-8")
    record = run.stdout.split("\nTrace:")[0].strip()
    if not record.startswith("{"):
        raise SystemExit(f"{path}: {record or run.stderr}")
    return ast.literal_eval(record)


def shoot(html_path, png_path, target):
    from playwright.sync_api import sync_playwright
    width = {"phone": 1360, "agent": 1340, "artifact": 1000}.get(target, 1280)
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": width, "height": 900}, device_scale_factor=2)
        page.goto("file://" + os.path.abspath(html_path))
        page.wait_for_timeout(400)
        page.screenshot(path=png_path, full_page=True)
        browser.close()


def main(args):
    shots = "--shots" in args
    files = [f for a in args if a != "--shots" for f in glob.glob(a)]
    out = os.path.join(here, "out")
    os.makedirs(out, exist_ok=True)
    for f in files:
        result = render(f)
        name = os.path.splitext(os.path.basename(f))[0]
        html = os.path.join(out, name + ".html")
        with open(html, "w", encoding="utf-8") as h:
            h.write(result["page"])
        print(f"{name}: {result['target']}, {len(result['fixed'])} fixed -> {html}")
        for line in result["fixed"]:
            print("   fixed:", line)
        if shots:
            shoot(html, os.path.join(out, name + ".png"), result["target"])


if __name__ == "__main__":
    main(sys.argv[1:])
