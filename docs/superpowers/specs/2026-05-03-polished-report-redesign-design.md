# Polished Lab Report Redesign

**Status:** Approved (pending implementation)
**Author:** Mukesh Pant
**Date:** 2026-05-03

## Background

`scripts/build_report.py` already generates a complete, screenshot-rich .docx of all 9
cloud-computing labs. After running the script, the user uploaded the output to the
Claude web interface and asked it to "make it more professional". The web-generated
result (committed at the repo root as `Mukesh_Pant_Cloud_Computing_Lab_Report.docx`)
keeps the same content but with a calmer, more academic visual treatment. The script's
output (`report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx`) is the same content
without those refinements.

This spec is the diff between those two files: the small set of typography, layout,
and content changes the script needs to produce a doc that matches the polished
version while keeping all 35 embedded screenshots in place.

## Goal

Refactor `scripts/build_report.py` so that running `python scripts/build_report.py`
produces a .docx whose visual style matches the polished web-generated reference,
while keeping every screenshot and all per-lab content intact.

## Non-goals

- Rewriting any per-lab procedure text. The lab body text stays as-is.
- Changing where screenshots live, how many there are, or how they're named.
- Externalising body content into separate Markdown files. Procedure text stays in
  Python lab dictionaries; the new Acknowledgement and Conclusion text are also
  hard-coded as templates with `{display_name}`, `{professor}`, etc. substitutions
  from `config.yaml`.
- Adding a CLI for the script. It still runs the same way.

## Confirmed decisions (from the brainstorming dialogue)

1. **Keep all screenshots embedded in their current positions.** This is a
   typography retrofit, not a content surgery.
2. **Acknowledgement and Conclusion text are hard-coded in the script** as f-string
   templates that pull `{display_name}`, `{professor.name}`, `{semester}`, etc. from
   `config.yaml`. No new files for body content.
3. **Header is kept** in the existing pattern
   (`Cloud Computing Lab Report  |  Mukesh Pant  |  Roll No. 29`, italic 10pt grey,
   right-aligned, with thin rule beneath, suppressed on cover). The footer changes
   from `Page X` to `Page X of Y`.

## Section 1 — Page chrome and global typography

### Margins

- All four sides: **1.0″** (currently 0.85″ left/right). Standard academic.

### Header (`section.header`)

- Text: `{subject.name} Lab Report  |  {student.full_name}  |  Roll No. {student.roll_number}`
- Style: italic, 10pt, grey (`#595959`), right-aligned
- Thin horizontal rule (`#BFBFBF`, 4-half-points) beneath
- Suppressed on cover via `different_first_page_header_footer = True`

### Footer (`section.footer`)

- Format: **`Page <PAGE> of <NUMPAGES>`**
- Implementation: a centered paragraph with the literal text `Page `, a `PAGE`
  field, the literal ` of `, and a `NUMPAGES` field. Both fields use
  `OxmlElement("w:fldChar")` begin/end markers and a `w:instrText` of `PAGE` or
  `NUMPAGES` respectively
- Style: 10pt grey

### Body text

- Font: Calibri **11pt** (down from 12pt)
- Line spacing: 1.3
- Justified by default
- Configured on the `Normal` style in `configure_default_styles`

### Native Heading styles

The script today builds headings as plain paragraphs with manually styled runs.
**Switch to Word's built-in `Heading 1` and `Heading 2` styles** so that:

- Word's navigation pane works (one-click jump between labs)
- A real `TOC` field can auto-populate page numbers
- Document structure is exposed to PDF export bookmarks and screen readers

Style configuration (set on `doc.styles["Heading 1"]` and `doc.styles["Heading 2"]`):

| Style       | Use                                                  | Font   | Size | Weight | Colour                |
|-------------|------------------------------------------------------|--------|------|--------|-----------------------|
| Heading 1   | Lab title, "Acknowledgement", "Conclusion"           | Calibri| 16pt | Bold   | navy `#1F3864`        |
| Heading 2   | Objective / AWS Services Used / Step-by-Step / etc.  | Calibri| 13pt | Bold   | navy `#1F3864`        |

(These match the actual sizes measured in the polished reference doc:
Heading 1 = 16pt, Heading 2 = 13pt. The "18pt" figure mentioned during the
brainstorming dialogue was a verbal estimate; the spec uses the measured value.)

**Note:** the thin horizontal rule below Heading 1 is *only* drawn beneath
**lab titles**. It is NOT part of the Heading 1 style itself — it is added by
`_add_horizontal_rule(...)` inside `add_lab()` after the title paragraph.
The "ACKNOWLEDGEMENT" and "CONCLUSION" Heading 1 paragraphs do not get a rule.

### Step sub-headings (e.g. `Step 1: Sign in and select region`)

- These are NOT a Word heading style. They are plain paragraphs.
- Style: **black bold 12pt** (was navy bold 12pt — same size, just black not navy,
  and using the body font; matches the measured polished reference)
- `keep_with_next = True` so the heading doesn't dangle from its bullets

### Captions (figure captions)

- Style change: **bold + italic** 10pt grey (was italic only)
- Centered, with `keep_together = True` and `keep_with_next` carried forward from the image paragraph

## Section 2 — Cover, ToC, and the two new sections

### Cover page

Re-tune sizes and add two missing pieces. New `config.yaml` field required:

- `institution.location: "Mahendranagar, Kanchanpur"`

Cover layout (top to bottom, all centered):

| Element                                                | Style                                  |
|--------------------------------------------------------|----------------------------------------|
| `{institution.university.upper()}`                     | 20pt navy bold                         |
| `{institution.faculty}`                                | 14pt navy                              |
| `{institution.school}`                                 | 13pt italic grey                       |
| `{institution.location}` *(new)*                       | 11pt italic grey                       |
| (horizontal rule)                                      | navy, 12 half-points                   |
| `A LAB REPORT`                                         | 14pt bold                              |
| `ON`                                                   | 12pt                                   |
| `{subject.name.upper()}`                               | 22pt navy bold                         |
| `(Practical)`                                          | 12pt italic grey                       |
| `Submitted by:`                                        | 12pt italic grey                       |
| `{student.full_name}`                                  | 15pt navy bold (was 18pt)              |
| `Roll No. {student.roll_number}`                       | 12pt plain (was 14pt navy bold)        |
| `{student.semester} Semester  \|  {student.program}`   | 11pt grey                              |
| `Submitted to:`                                        | 12pt italic grey                       |
| `{professor.name}`                                     | 13pt navy bold                         |
| `{professor.title_line_1}` (e.g. `Lecturer, School of Engineering`) | 11pt grey         |
| `{professor.title_line_2}` (e.g. `Far Western University`) | 11pt grey                       |
| `Signature:  ____________________`                     | 11pt                                   |
| `Date:  ____________________` *(new)*                  | 11pt                                   |

**Implementation note — professor's title split.** The script will
`rsplit(", ", 1)` the `professor.title` string on the **last** comma + space,
producing two lines: everything before the last comma → line 1, everything
after → line 2.

The user must update `config.yaml` to make the result match the polished
reference:

- Change `professor.title` from `Lecturer, School of Engineering, FWU` to
  `Lecturer, School of Engineering, Far Western University`.

After that change the split yields `Lecturer, School of Engineering` (line 1)
and `Far Western University` (line 2), exactly as in the reference.

If `professor.title` contains no comma, the whole string goes on line 1 and
line 2 is omitted. No new config fields are introduced for this.

### Acknowledgement section (new, between cover and ToC)

- Page-break before
- Heading 1: `ACKNOWLEDGEMENT`, centered
- Three justified body paragraphs (text taken from the polished web version,
  with `{display_name}`, `{professor.name}`, `{semester}`, `{program}`,
  `{institution.faculty}`, `{institution.school}`, `{institution.university}`
  substituted from config)
- Three lines at the bottom right:
  - `{student.full_name}` — 12pt bold
  - `Roll No. {student.roll_number}` — 11pt
  - `{student.program}, {student.semester} Semester` — 11pt

### Table of Contents

- Above the TOC field, a centered **"TABLE OF CONTENTS"** standalone paragraph,
  18pt navy bold. This is NOT a Heading 1 (it should not list itself).
- Replace the script's hand-built ToC paragraphs with a real Word **TOC field**.
- Implementation: insert a `w:fldChar begin`, an instruction
  `TOC \o "1-1" \h \z \u` (only Heading 1 entries — labs, Acknowledgement,
  Conclusion), a `w:fldChar separate`, a placeholder paragraph saying
  `Right-click and select "Update Field" to populate.`, and a `w:fldChar end`.
- On first open in Word, the user clicks "Update field" once and the ToC
  populates with the dotted-leader entries `Lab 1.   Virtual Cloud Environment (VPC)   ····   4`.
- Word can be configured to update fields automatically on open via
  `settings.xml` `w:updateFields w:val="true"` — the script will set this so the
  user does not need to manually update.

### Conclusion section (new, after Lab 9)

- Page-break before
- Heading 1: `CONCLUSION`
- Five justified body paragraphs (text from the polished web version, with the
  same kind of config substitutions as Acknowledgement). Paragraph topics:
  1. Opening: across the nine labs the user worked through the building blocks
     of an AWS deployment.
  2. Networking foundation (Labs 1 + 4): VPC, subnets, IGW, route tables,
     security groups.
  3. Compute and traffic (Labs 2, 3, 5): EC2, S3 static hosting, ALB + ASG.
  4. Identity (Lab 6): IAM users, groups, managed policies; group-based vs
     direct attachment.
  5. Managed services + IaC (Labs 7, 8, 9) and a closing line about practical
     skills gained.

## Section 3 — Per-lab content layout

### Lab title

- `Lab {n}: {title}` — Heading 1
- Existing thin horizontal rule beneath (keep `_add_horizontal_rule` call)
- `page_break_before = True` for every lab except the first (already so)

### Per-lab section headings

All five become Heading 2 (13pt navy bold):

- `Objective`
- `AWS Services Used`
- `Step-by-Step Procedure`
- `Screenshots`
- `Observations and Results` *(rename from "Observations & Results")*

### AWS Services Used table — visual change

Replace the current navy-bullet table with a plain bordered grid:

- Same 2-column / `(n+1)//2` row layout
- Cell content: just the service name in 11pt black, left-aligned with cell padding
- **Drop the `•  ` navy prefix run**
- **Drop `autofit = False` and the explicit 3.2″ column width** so the table fills
  the body width naturally
- Add **light-grey 1pt borders** around every cell using `tcBorders` OxmlElement
  (top, left, bottom, right, all with `w:val="single"`, `w:sz="4"`, `w:color="BFBFBF"`)
- Cell vertical alignment stays centered

### Step-by-Step Procedure body

- Each step's sub-heading: plain black bold 11pt paragraph (covered in section 1)
- Bullet items beneath: Word `List Bullet` style, 11pt, justified
- No change to the per-step structure

### Screenshots

- Image: 5.6″ wide, centered (no change)
- Caption: bold + italic 10pt grey (style change covered in section 1)
- Keep `keep_with_next` on image paragraph and `keep_together` on caption so a
  figure and its caption don't split across pages

### Observations and Results

- Single justified 11pt body paragraph (size change covered in section 1)
- No layout change

## Implementation notes

### Files to change

- `scripts/build_report.py` — all visual changes; new helpers for Heading 1/2
  styles, TOC field, NUMPAGES field, Acknowledgement/Conclusion sections,
  bordered services table
- `config.yaml` — add `institution.location: "Mahendranagar, Kanchanpur"`
- `config.example.yaml` — same addition for new template users
- Possibly `scripts/lib/config.py` — add the `location` field to whatever
  dataclass/model it uses for `institution`

### Helper functions worth introducing

- `_style_heading(doc, name, *, size, color, bold=True)` — configure
  `doc.styles[name]` so Heading 1 and Heading 2 share a setup path
- `_add_toc_field(doc)` — emit the `TOC` field XML
- `_add_pages_field(run)` — emit the `NUMPAGES` field XML (sister to existing
  `_add_page_field`)
- `_set_cell_borders(cell, color="BFBFBF", size=4)` — add the four
  `w:tcBorders` children
- `_enable_update_fields_on_open(doc)` — set `w:updateFields w:val="true"` in
  `settings.xml`

### Function shape

`build()` will read more like:

```python
configure_default_styles(doc)
configure_heading_styles(doc)
configure_sections(doc, cfg)
add_cover_page(doc, cfg)
add_acknowledgement(doc, cfg)
add_toc(doc)
labs = get_labs(cfg)
for i, lab in enumerate(labs, 1):
    add_lab(doc, i, lab, is_first=(i == 1))
add_conclusion(doc, cfg)
enable_update_fields_on_open(doc)
doc.save(output_path(cfg))
```

## Acceptance criteria

A reviewer running `python scripts/build_report.py` on a fresh checkout (with
the updated `config.yaml`) and opening the resulting .docx in Word, then
hitting "Update field" once on the ToC, should see:

1. Cover page matches the polished reference: 20pt university line, location
   line under "School of Engineering", professor's title on two lines, Date
   field beneath Signature.
2. An Acknowledgement page appears between cover and ToC.
3. The ToC lists `Acknowledgement`, `Lab 1` … `Lab 9`, `Conclusion`, each with
   a real page number after a dot leader.
4. Word's navigation pane (Ctrl+F → "Headings") shows every lab and every
   Heading 2 section.
5. Every page after the cover shows the running header
   `Cloud Computing Lab Report  |  Mukesh Pant  |  Roll No. 29` and the footer
   `Page X of Y`.
6. Body text is 11pt, justified, line spacing 1.3.
7. The AWS Services Used table on each lab is a plain bordered grid (no navy
   bullets, light grey borders).
8. All 35 screenshots are embedded in the same lab-by-lab order they are now,
   each with a bold + italic caption beneath.
9. A Conclusion page appears after Lab 9.

## Out of scope (future work, not this spec)

- Auto-detecting screenshots in folders (currently they're listed explicitly).
- Generating a PDF directly (Word "Save as PDF" or LibreOffice headless export
  remains the user's responsibility).
- Multi-language / Nepali transliteration of cover text.
