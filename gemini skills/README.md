# Gemini Skills

This directory is a converted copy of the original `skills/` tree, updated from Claude-specific wording to Gemini-friendly naming.

## What was done
- Copied all original skills from `skills/` into `gemini skills/`
- Replaced `Claude`/`claude` references with `Gemini`/`gemini` in text-based files
- Renamed files and directories that contained `claude` in their path
- Generated a simple `manifest.json` for each skill based on the YAML frontmatter from `SKILL.md`
- Created `skill-registry.json` at the root listing all skills and their manifest files

## What is included
- `skill-registry.json` — registry of all skills with names, descriptions, and relative paths
- `*/manifest.json` — per-skill manifest metadata
- `SKILL.md` files retained in each skill directory

## Next step
To make this tree conform to a specific Gemini skill or plugin runtime, provide the target Gemini manifest schema.

Once the schema is available, the generated `manifest.json` files can be transformed into the required Gemini plugin format automatically.
