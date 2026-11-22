#!/usr/bin/env python3
"""Catppuccin Macchiato for DBeaver (no official Catppuccin port exists).
Run by `./install.sh ide`; safe to re-run. DBeaver must be CLOSED — it rewrites
these files on exit, which would undo the changes.

DBeaver (Eclipse) stores Preferences → Appearance → Colors and Fonts as
`colourId=R,G,B` lines in the workspace's org.eclipse.ui.workbench.prefs;
generic text-editor colours live in org.eclipse.ui.editors.prefs. This sets
only the keys below and leaves every other line alone. The colour IDs are the
99 <colorDefinition>s from DBeaver's plugin.xml files (DBeaver 26.x). Keeps
DBeaver's own dark theme (e4_dark) for the widgets.
"""
import subprocess
import sys
from pathlib import Path

# --- Catppuccin Macchiato -----------------------------------------------------
P = dict(
    rosewater=(244, 219, 214), flamingo=(240, 198, 198), pink=(245, 189, 230), mauve=(198, 160, 246),
    red=(237, 135, 150), maroon=(238, 153, 160), peach=(245, 169, 127), yellow=(238, 212, 159),
    green=(166, 218, 149), teal=(139, 213, 202), sky=(145, 215, 227), sapphire=(125, 196, 228),
    blue=(138, 173, 244), lavender=(183, 189, 248), text=(202, 211, 245), subtext1=(184, 192, 224),
    subtext0=(165, 173, 203), overlay2=(147, 154, 183), overlay1=(128, 135, 162), overlay0=(110, 115, 141),
    surface2=(91, 96, 120), surface1=(73, 77, 100), surface0=(54, 58, 79), base=(36, 39, 58),
    mantle=(30, 32, 48), crust=(24, 25, 38),
)


def tint(name, amount):
    """Palette colour blended over `base` — for backgrounds that must stay dark."""
    c, b = P[name], P["base"]
    return tuple(round(b[i] + (c[i] - b[i]) * amount) for i in range(3))


def c(name):
    return P[name]


D = "org.jkiss.dbeaver."
WORKBENCH = {
    # --- SQL editor ---
    D + "sql.editor.color.text.background": c("base"),
    D + "sql.editor.color.text.foreground": c("text"),
    D + "sql.editor.color.disabled.background": c("mantle"),
    D + "sql.editor.color.keyword.foreground": c("mauve"),
    D + "sql.editor.color.datatype.foreground": c("yellow"),
    D + "sql.editor.color.function.foreground": c("blue"),
    D + "sql.editor.color.string.foreground": c("green"),
    D + "sql.editor.color.number.foreground": c("peach"),
    D + "sql.editor.color.comment.foreground": c("overlay2"),
    D + "sql.editor.color.delimiter.foreground": c("overlay2"),
    D + "sql.editor.color.command.foreground": c("pink"),
    D + "sql.editor.color.parameter.foreground": c("maroon"),
    D + "sql.editor.color.sqlVariable.foreground": c("maroon"),
    D + "sql.editor.color.table.foreground": c("yellow"),
    D + "sql.editor.color.table.alias.foreground": c("yellow"),
    D + "sql.editor.color.column.foreground": c("lavender"),
    D + "sql.editor.color.column.derived.foreground": c("lavender"),
    D + "sql.editor.color.schema.foreground": c("flamingo"),
    D + "sql.editor.color.composite.field.foreground": c("teal"),
    D + "sql.editor.color.semanticError.foreground": c("red"),
    D + "sql.editor.color.aiSuggestion.foreground": c("overlay1"),
    D + "sql.editor.color.aiSuggestion.background": c("surface0"),
    # --- result grid ---
    D + "sql.resultset.color.selection.background": c("surface1"),
    D + "sql.resultset.color.selection.foreground": c("text"),
    D + "sql.resultset.color.cell.odd.background": c("mantle"),
    D + "sql.resultset.color.preview.background": c("surface0"),
    D + "sql.resultset.color.cell.modified.background": tint("yellow", .25),
    D + "sql.resultset.color.cell.new.background": tint("green", .25),
    D + "sql.resultset.color.cell.deleted.background": tint("red", .25),
    D + "sql.resultset.color.cell.error.background": tint("red", .45),
    D + "sql.resultset.color.cell.readonly.background": c("surface0"),
    D + "sql.resultset.color.cell.matched.background": tint("peach", .35),
    D + "sql.resultset.color.lines.normal": c("surface0"),
    D + "sql.resultset.color.lines.selected": c("surface2"),
    D + "sql.resultset.color.header.background": c("mantle"),
    D + "sql.resultset.color.header.foreground": c("subtext1"),
    D + "sql.resultset.color.header.selected.background": c("surface1"),
    D + "sql.resultset.color.header.border": c("surface0"),
    D + "sql.resultset.color.null.foreground": c("overlay0"),
    D + "sql.resultset.color.binary.foreground": c("overlay1"),
    D + "sql.resultset.color.boolean.foreground": c("peach"),
    D + "sql.resultset.color.datetime.foreground": c("teal"),
    D + "sql.resultset.color.numeric.foreground": c("peach"),
    D + "sql.resultset.color.string.foreground": c("text"),
    # --- general ---
    D + "ui.general.accent": c("mauve"),
    D + "ui.general.color.warning.foreground": c("yellow"),
    D + "ui.general.color.error.foreground": c("red"),
    D + "color.readOnly.foreground": c("peach"),
    D + "txn.color.committed.background": tint("green", .3),
    D + "txn.color.reverted.background": tint("red", .3),
    D + "txn.color.transaction.background": tint("yellow", .3),
    D + "ui.sqlPresentation.aiChat.color.prompt.background": c("surface0"),
    D + "ui.sqlPresentation.aiChat.color.prompt.border": c("surface1"),
    # --- navigator ---
    D + "ui.navigator.node.foreground": c("subtext0"),
    D + "ui.navigator.node.transient.foreground": c("teal"),
    D + "ui.navigator.node.new.background": tint("green", .25),
    D + "ui.navigator.node.modified.background": tint("yellow", .25),
    D + "ui.navigator.node.statistics.background": c("surface0"),
    # --- ER diagrams ---
    D + "erd.diagram.background": c("base"),
    D + "erd.diagram.entity.regular.background": c("mantle"),
    D + "erd.diagram.entity.primary.background": tint("peach", .4),
    D + "erd.diagram.entity.association.background": c("surface0"),
    D + "erd.diagram.entity.name.foreground": c("text"),
    D + "erd.diagram.attributes.background": c("surface0"),
    D + "erd.diagram.attributes.foreground": c("subtext1"),
    D + "erd.diagram.search.highlighting": tint("yellow", .4),
    D + "erd.diagram.fk.highlighting": tint("green", .4),
    D + "erd.diagram.notes.foreground": c("text"),
    D + "erd.diagram.notes.background": c("surface1"),
    D + "erd.diagram.lines.foreground": c("blue"),
    # --- hex / XML editors ---
    D + "hex.editor.color.caret": c("surface1"),
    D + "hex.editor.color.text": c("text"),
    D + "xml.editor.color.tag": c("blue"),
    D + "xml.editor.color.text": c("text"),
    D + "xml.editor.color.comment": c("overlay2"),
    # --- editor tabs (Eclipse workbench) ---
    "org.eclipse.ui.workbench.ACTIVE_TAB_BG_START": c("base"),
    "org.eclipse.ui.workbench.ACTIVE_TAB_BG_END": c("base"),
    "org.eclipse.ui.workbench.ACTIVE_TAB_TEXT_COLOR": c("text"),
    "org.eclipse.ui.workbench.ACTIVE_NOFOCUS_TAB_BG_START": c("base"),
    "org.eclipse.ui.workbench.ACTIVE_NOFOCUS_TAB_BG_END": c("base"),
    "org.eclipse.ui.workbench.ACTIVE_NOFOCUS_TAB_TEXT_COLOR": c("subtext1"),
    "org.eclipse.ui.workbench.INACTIVE_TAB_BG_START": c("mantle"),
    "org.eclipse.ui.workbench.INACTIVE_TAB_BG_END": c("mantle"),
    "org.eclipse.ui.workbench.INACTIVE_TAB_TEXT_COLOR": c("overlay1"),
}
# chart series, ERD border/header colours
for i, n in enumerate(["mauve", "blue", "green", "peach", "red", "teal", "yellow", "pink", "sapphire", "lavender"], 1):
    WORKBENCH[f"{D}ui.data.chart.color.{i}"] = c(n)
for i, n in enumerate(["green", "red", "peach", "maroon", "sapphire", "flamingo", "rosewater"], 1):
    WORKBENCH[f"{D}ui.presentation.erd.borders.color.{i}"] = c(n)
    WORKBENCH[f"{D}ui.presentation.erd.headers.color.{i}"] = tint(n, .3)

# generic Eclipse text editors (used by DBeaver's non-SQL editors)
EDITORS = {
    "AbstractTextEditor.Color.Background.SystemDefault": "false",
    "AbstractTextEditor.Color.Background": c("base"),
    "AbstractTextEditor.Color.Foreground.SystemDefault": "false",
    "AbstractTextEditor.Color.Foreground": c("text"),
    "AbstractTextEditor.Color.SelectionBackground.SystemDefault": "false",
    "AbstractTextEditor.Color.SelectionBackground": c("surface1"),
    "AbstractTextEditor.Color.SelectionForeground.SystemDefault": "false",
    "AbstractTextEditor.Color.SelectionForeground": c("text"),
    "currentLineColor": c("surface0"),
    "lineNumberColor": c("overlay0"),
}

SETTINGS = Path.home() / ".local/share/DBeaverData/workspace6/.metadata/.plugins/org.eclipse.core.runtime/.settings"

# Window chrome (panels, tabs, toolbars, dialogs) isn't in Colors and Fonts:
# Eclipse's dark theme paints it from CSS. Its theme engine loads a *modified*
# copy of a theme stylesheet from <configuration>/org.eclipse.e4.ui.css.swt.theme/.
# We write DBeaver's current e4-dark_linux.css with its @imports inlined and
# every colour literal swapped for its Catppuccin counterpart — so each rule
# keeps its exact selector/specificity (hand-written overrides lose to rules
# like `.MPart Composite > * > *`) — then our small extra block.
CSS_BLOCK = Path(__file__).resolve().with_name("dbeaver-catppuccin.css")
THEMES_GLOB = "/usr/lib/dbeaver/plugins/org.eclipse.ui.themes_*/css/e4-dark_linux.css"
CONFIG_GLOB = str(Path.home() / ".eclipse/org.jkiss.dbeaver.product_*/configuration")

# Eclipse dark-theme literal → Catppuccin role (case-insensitive, 3-digit expanded)
CSS_MAP = {
    "48484c": "base",       # DARK_BACKGROUND: dialogs, combos, Composite > *
    "2f2f2f": "base", "292929": "base", "262626": "base", "252525": "base",
    "232323": "base", "313538": "base",
    "3b4042": "mantle", "383c3e": "mantle", "383d3f": "mantle", "383a3b": "mantle",
    "333333": "mantle", "3f4447": "mantle", "1e1f22": "mantle",   # inputs, table headers
    "161616": "surface0",   # hovered tab
    "41464a": "surface0", "444444": "surface0", "464649": "surface0", "4f5355": "surface0",
    "515658": "surface0", "505f70": "surface1",
    "316c9b": "mauve", "2b79d7": "mauve", "4176af": "mauve",
    "6fc5ee": "blue", "2b97d7": "blue", "9ac9d8": "sapphire", "abceda": "sapphire", "aebed0": "subtext1",
}
GREY_RAMP = [  # fallback for other greys, by brightness
    (0x1c, "crust"), (0x36, "base"), (0x42, "mantle"), (0x60, "surface0"), (0x80, "overlay0"),
    (0x90, "overlay1"), (0xa0, "overlay2"), (0xb0, "subtext0"), (0xd0, "subtext1"), (0x100, "text"),
]


def recolour(css):
    import re

    def swap(m):
        h = m.group(1).lower()
        if len(h) == 3:
            h = "".join(ch * 2 for ch in h)
        role = CSS_MAP.get(h)
        if role is None:
            r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
            if max(r, g, b) - min(r, g, b) > 60:          # a real colour: leave it
                return m.group(0)
            role = next(n for limit, n in GREY_RAMP if (r + g + b) / 3 < limit)
        return "#%02x%02x%02x" % P[role]
    # `#org-eclipse-…` ids never match: hex digits only, then a non-word char
    return re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})(?![\w-])", swap, css)


def inline_imports(path, depth=0):
    """Paste in @import url("platform:/plugin/org.eclipse.ui.themes/css/…") files."""
    import re
    text = path.read_text()
    root = next(p for p in path.parents if p.name == "css")

    def sub(m):
        f = root / m.group(1)
        return inline_imports(f, depth + 1) if f.exists() and depth < 5 else m.group(0)
    return re.sub(r'@import\s+url\("platform:/plugin/org\.eclipse\.ui\.themes/css/([^"]+)"\);', sub, text)


def install_chrome_css():
    import glob, os
    originals = sorted(glob.glob(THEMES_GLOB))
    configs = sorted(glob.glob(CONFIG_GLOB), key=os.path.getmtime)
    if not originals or not configs:
        print("!! DBeaver: dark theme CSS or configuration dir not found — chrome not themed")
        return False
    target = Path(configs[-1]) / "org.eclipse.e4.ui.css.swt.theme" / "e4-dark_linux.css"
    new = recolour(inline_imports(Path(originals[-1]))) + "\n" + CSS_BLOCK.read_text()
    if target.exists() and target.read_text() == new:
        return False
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(new)
    return True


def fmt(v):
    return v if isinstance(v, str) else ",".join(map(str, v))


def merge(path, values):
    lines = path.read_text().splitlines() if path.exists() else ["eclipse.preferences.version=1"]
    todo = {k: fmt(v) for k, v in values.items()}
    out = []
    for line in lines:
        key = line.split("=", 1)[0]
        if key in todo:
            out.append(f"{key}={todo.pop(key)}")
        else:
            out.append(line)
    out += [f"{k}={v}" for k, v in sorted(todo.items())]
    new = "\n".join(out) + "\n"
    changed = not path.exists() or path.read_text() != new
    if changed:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(new)
    return changed


def main(settings=SETTINGS):
    if subprocess.run(["pgrep", "-f", "/usr/lib/dbeaver/dbeaver"], capture_output=True).returncode == 0:
        print("!! DBeaver is running — close it and re-run ./install.sh ide "
              "(it rewrites its settings on exit)")
        return 0
    if not settings.parent.parent.exists():
        print("!! no DBeaver workspace yet — start DBeaver once, close it, then re-run")
        return 0
    a = merge(settings / "org.eclipse.ui.workbench.prefs", WORKBENCH)
    b = merge(settings / "org.eclipse.ui.editors.prefs", EDITORS)
    css = install_chrome_css()
    print(f"==> DBeaver: Catppuccin Macchiato {'set' if a or b or css else 'already set'} "
          f"({len(WORKBENCH)} colours + {len(EDITORS)} editor settings + window chrome CSS)")
    return 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]) if len(sys.argv) > 1 else SETTINGS))
