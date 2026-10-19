"""D1 — Deterministic UTF-8 BOM & frontmatter integrity check for DSH & AGH Skills.

Scans all `.dsh/skills/*/SKILL.md` and `.agh/skills/*/SKILL.md` files and verifies:
  1. File is non-empty and does NOT start with UTF-8 BOM (EF BB BF);
  2. File strictly starts with `---\n` or `---\r\n` so skill parsers never silently skip a skill.

Usage:
    python physics-agent/hooks/skill_bom_check.py [--skills-dir .dsh/skills] [--fix]
"""
import argparse
import glob
import os
import sys

BOM = b"\xef\xbb\xbf"


def check_skills(skills_dir=None, fix=False):
    if skills_dir:
        targets = [skills_dir]
    else:
        targets = [d for d in [".dsh/skills", ".agh/skills"] if os.path.isdir(d)]
        if not targets:
            targets = [".dsh/skills"]

    total_paths = 0
    overall_rc = 0

    for s_dir in targets:
        pattern = os.path.join(s_dir, "*", "SKILL.md")
        paths = sorted(glob.glob(pattern))
        if not paths:
            print(f"[WARN] No SKILL.md files found under {s_dir}")
            continue

        total_paths += len(paths)
        bad_bom = []
        bad_frontmatter = []
        fixed = []

        for p in paths:
            with open(p, "rb") as f:
                raw = f.read()
            if raw.startswith(BOM):
                if fix:
                    raw = raw[len(BOM):]
                    with open(p, "wb") as fw:
                        fw.write(raw)
                    fixed.append(p)
                else:
                    bad_bom.append(p)
                    continue
            if not (raw.startswith(b"---\n") or raw.startswith(b"---\r\n")):
                bad_frontmatter.append(p)

        if fixed:
            print(f"[FIXED] Stripped UTF-8 BOM from {len(fixed)} file(s) in {s_dir}: {', '.join(fixed)}")

        if bad_bom or bad_frontmatter:
            for p in bad_bom:
                print(f"[FAIL] UTF-8 BOM (EF BB BF) detected at start of: {p}")
            for p in bad_frontmatter:
                print(f"[FAIL] Missing strict '---' YAML frontmatter header at start of: {p}")
            overall_rc = 1
        else:
            print(f"[PASS] All {len(paths)} SKILL.md files under '{s_dir}' are BOM-free and have valid frontmatter headers.")

    if overall_rc != 0:
        print(
            "\nTo strip BOM automatically, run:\n"
            "  python physics-agent/hooks/skill_bom_check.py --fix"
        )
        return 1

    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Check .dsh/skills/*/SKILL.md and .agh/skills/*/SKILL.md for UTF-8 BOM and frontmatter header.")
    ap.add_argument("--skills-dir", default=None, help="Path to skills directory (defaults to auto-detecting .dsh/skills and .agh/skills).")
    ap.add_argument("--fix", action="store_true", help="Automatically strip UTF-8 BOM if found.")
    args = ap.parse_args(argv)
    return check_skills(args.skills_dir, fix=args.fix)


if __name__ == "__main__":
    sys.exit(main())
