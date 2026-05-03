# Polished Lab Report Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `scripts/build_report.py` so it produces a `.docx` whose visual style matches the polished web-generated reference (`Mukesh_Pant_Cloud_Computing_Lab_Report.docx` at the repo root), while keeping all 35 embedded screenshots and the 9 lab procedures intact.

**Architecture:** All visual changes are confined to `scripts/build_report.py`. Two small additions to `config.yaml` / `config.example.yaml` (a new `institution.location` field, an extension of `professor.title`). No new files. Headings switch from "raw paragraph + manually styled run" to Word's native `Heading 1` / `Heading 2` styles so that Word's navigation pane works and a real `TOC` field can auto-populate page numbers. Two new content sections (Acknowledgement, Conclusion) are added as hard-coded prose templates with `{display_name}`, `{professor_name}`, `{semester}`, etc. substituted from `config.yaml` at build time.

**Tech Stack:** Python 3, `python-docx==1.1.2`, `PyYAML`, low-level `docx.oxml` for fields and table borders.

**Verification approach:** This is a `.docx` generator with no existing test suite. Each task ends with (a) a runnable `python -c "..."` command that re-builds the report and inspects the relevant aspect via `python-docx`, and (b) a commit. Where visual confirmation is required, the task says so explicitly — open the produced `.docx` in Word and eyeball it.

**Reference paths used throughout:**
- Repo root: `c:\Users\MUKESH\Desktop\Claude Computing Practical`
- Script under edit: `scripts/build_report.py`
- Config files: `config.yaml`, `config.example.yaml`
- Build command: `python scripts/build_report.py`
- Output file: `report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx`

---

### Task 1: Extend config files

**Files:**
- Modify: `config.yaml`
- Modify: `config.example.yaml`

**Why:** The polished cover page shows `Mahendranagar, Kanchanpur` under "School of Engineering", and splits the professor's title onto two lines (`Lecturer, School of Engineering` / `Far Western University`). The cover page redesign in Task 5 needs both the new `institution.location` field and the extended `professor.title` value.

- [ ] **Step 1: Add `institution.location` and extend `professor.title` in `config.yaml`**

Open `config.yaml` and update the `institution` and `professor` blocks so they read:

```yaml
institution:
  university: Far Western University
  faculty: Faculty of Engineering
  school: School of Engineering
  location: Mahendranagar, Kanchanpur

subject:
  name: Cloud Computing

professor:
  name: Er. Robinson Pujara
  title: Lecturer, School of Engineering, Far Western University
```

Only two lines change in practice:
- New `location:` line under `school:`.
- `professor.title:` now ends with `, Far Western University` (was `, FWU`).

- [ ] **Step 2: Apply the same additions to `config.example.yaml`**

Update `config.example.yaml`:

```yaml
institution:
  university: Your University
  faculty: Faculty of Engineering
  school: School of Engineering
  location: City, District

subject:
  name: Cloud Computing

professor:
  name: Dr. Alice Smith
  title: Lecturer, School of Engineering, Your University
```

- [ ] **Step 3: Verify the loader picks up the new field**

Run:

```bash
python -c "from scripts.lib.config import load; cfg = load(); print(cfg.institution.location); print(cfg.professor.title)"
```

Expected output:
```
Mahendranagar, Kanchanpur
Lecturer, School of Engineering, Far Western University
```

(`scripts/lib/config.py` recursively wraps every nested dict in `SimpleNamespace`, so no Python change is needed for the new field.)

- [ ] **Step 4: Commit**

```bash
git add config.yaml config.example.yaml
git commit -m "config: add institution.location and extend professor.title"
```

---

### Task 2: Add `configure_heading_styles` helper and wire it into `build()`

**Files:**
- Modify: `scripts/build_report.py`

**Why:** All later tasks that touch lab titles, the Acknowledgement, the Conclusion, and per-lab section headings rely on the document having Word's native `Heading 1` and `Heading 2` styles configured to match the polished reference (16pt navy bold, 13pt navy bold). Doing it once here means the rest of the plan can just say "set this paragraph's style to Heading 1" and the look is correct.

- [ ] **Step 1: Add the helper above `# Section / page setup` divider**

Find the line containing:

```python
# ---------------------------------------------------------------------------
# Section / page setup
# ---------------------------------------------------------------------------
```

Insert this function **immediately above** that divider (right after `_add_page_field`):

```python
def configure_heading_styles(doc):
    """Configure Word's native Heading 1 / Heading 2 styles to match the
    polished reference (navy bold, sized for an academic doc).

    Using real heading styles (instead of raw runs) is what lets Word's
    navigation pane jump between labs and lets the TOC field populate
    page numbers automatically.
    """
    h1 = doc.styles["Heading 1"]
    h1.font.name = FONT_HEADING
    h1.font.size = Pt(16)
    h1.font.bold = True
    h1.font.color.rgb = COLOR_PRIMARY
    h1.paragraph_format.space_before = Pt(12)
    h1.paragraph_format.space_after = Pt(6)
    h1.paragraph_format.keep_with_next = True

    h2 = doc.styles["Heading 2"]
    h2.font.name = FONT_HEADING
    h2.font.size = Pt(13)
    h2.font.bold = True
    h2.font.color.rgb = COLOR_PRIMARY
    h2.paragraph_format.space_before = Pt(8)
    h2.paragraph_format.space_after = Pt(2)
    h2.paragraph_format.keep_with_next = True
```

- [ ] **Step 2: Call it from `build()` right after `configure_default_styles(doc)`**

Find the function `def build():` (near the bottom). Update the body so it reads:

```python
def build():
    cfg = load()
    doc = Document()

    configure_default_styles(doc)
    configure_heading_styles(doc)
    configure_sections(doc, cfg)

    add_cover_page(doc, cfg)
    labs = get_labs(cfg)
    add_toc(doc, labs)

    for i, lab in enumerate(labs, 1):
        add_lab(doc, i, lab, is_first=(i == 1))

    out = output_path(cfg)
    out.parent.mkdir(parents=True, exist_ok=True)
    doc.save(out)
    print(f"Wrote {out}")
```

(Only one new line added: `configure_heading_styles(doc)`.)

- [ ] **Step 3: Run the script — should still produce the same .docx (no visible change yet, since nothing references Heading 1/2 yet)**

```bash
python scripts/build_report.py
```

Expected output: `Wrote ...\report\Mukesh_Pant_Cloud_Computing_Lab_Report.docx`

- [ ] **Step 4: Verify the styles are now configured in the output**

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); h1 = d.styles['Heading 1']; print('H1 size:', h1.font.size.pt, 'color:', h1.font.color.rgb); h2 = d.styles['Heading 2']; print('H2 size:', h2.font.size.pt, 'color:', h2.font.color.rgb)"
```

Expected output:
```
H1 size: 16.0 color: 1F3864
H2 size: 13.0 color: 1F3864
```

- [ ] **Step 5: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: configure native Heading 1/2 styles (16pt/13pt navy)"
```

---

### Task 3: Update body font to 11pt and margins to 1.0″

**Files:**
- Modify: `scripts/build_report.py`

**Why:** Two of the simplest global changes from the spec — body text changes from 12pt to 11pt (every paragraph using the `Normal` style picks this up automatically), and margins go from 0.85″ left/right to 1.0″ all four sides for a standard academic look.

- [ ] **Step 1: Change `SIZE_BODY` constant**

Near the top of the file, find:

```python
SIZE_BODY = 12
```

Change to:

```python
SIZE_BODY = 11
```

- [ ] **Step 2: Update `configure_default_styles` to use the new size and tighter line spacing**

Find:

```python
def configure_default_styles(doc):
    style = doc.styles["Normal"]
    style.font.name = FONT_BODY
    style.font.size = Pt(SIZE_BODY)
    style.paragraph_format.space_after = Pt(6)
    style.paragraph_format.line_spacing = 1.25
```

Replace with:

```python
def configure_default_styles(doc):
    style = doc.styles["Normal"]
    style.font.name = FONT_BODY
    style.font.size = Pt(SIZE_BODY)
    style.paragraph_format.space_after = Pt(6)
    style.paragraph_format.line_spacing = 1.3
```

(Only the line-spacing changed: `1.25 → 1.3`. The font size already pulls from `SIZE_BODY` which is now 11.)

- [ ] **Step 3: Update margins in `configure_sections`**

Find:

```python
    section.top_margin = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(0.85)
    section.right_margin = Inches(0.85)
```

Replace with:

```python
    section.top_margin = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(1.0)
    section.right_margin = Inches(1.0)
```

- [ ] **Step 4: Run the script and verify**

```bash
python scripts/build_report.py
```

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); s = d.sections[0]; print('margins (in):', s.top_margin.inches, s.bottom_margin.inches, s.left_margin.inches, s.right_margin.inches); print('Normal pt:', d.styles['Normal'].font.size.pt)"
```

Expected output:
```
margins (in): 1.0 1.0 1.0 1.0
Normal pt: 11.0
```

- [ ] **Step 5: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: tighten body to 11pt and use 1in margins all sides"
```

---

### Task 4: Footer changes from "Page X" to "Page X of Y"

**Files:**
- Modify: `scripts/build_report.py`

**Why:** The polished reference shows `Page 4 of 33` in the footer. The current script only inserts a `PAGE` field. We need a sister helper for the `NUMPAGES` field and an updated footer string.

- [ ] **Step 1: Add `_add_pages_field` helper next to `_add_page_field`**

Find:

```python
def _add_page_field(run):
    """Insert {PAGE} field into a run for live page numbers."""
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "PAGE"
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_begin)
    run._r.append(instr)
    run._r.append(fld_end)
```

Add this function **directly below**:

```python
def _add_pages_field(run):
    """Insert {NUMPAGES} field into a run for live total page count."""
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "NUMPAGES"
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_begin)
    run._r.append(instr)
    run._r.append(fld_end)
```

- [ ] **Step 2: Update the footer construction in `configure_sections`**

Find:

```python
    footer = section.footer
    f_para = footer.paragraphs[0]
    f_para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    label = f_para.add_run("Page ")
    _set_run(label, size=10, color=COLOR_GREY)
    page_run = f_para.add_run()
    _set_run(page_run, size=10, color=COLOR_GREY)
    _add_page_field(page_run)
```

Replace with:

```python
    footer = section.footer
    f_para = footer.paragraphs[0]
    f_para.alignment = WD_ALIGN_PARAGRAPH.CENTER

    label = f_para.add_run("Page ")
    _set_run(label, size=10, color=COLOR_GREY)

    page_run = f_para.add_run()
    _set_run(page_run, size=10, color=COLOR_GREY)
    _add_page_field(page_run)

    of_run = f_para.add_run(" of ")
    _set_run(of_run, size=10, color=COLOR_GREY)

    pages_run = f_para.add_run()
    _set_run(pages_run, size=10, color=COLOR_GREY)
    _add_pages_field(pages_run)
```

- [ ] **Step 3: Run the script**

```bash
python scripts/build_report.py
```

- [ ] **Step 4: Verify visually**

Open `report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx` in Word. On any page after the cover, the footer should read `Page <n> of <total>` (e.g. `Page 4 of 33`). The fields update automatically when Word opens the file.

- [ ] **Step 5: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: footer now shows 'Page X of Y'"
```

---

### Task 5: Cover page restyle (sizes, location line, Date field, professor split)

**Files:**
- Modify: `scripts/build_report.py`

**Why:** Eight calibration changes to the cover page so it matches the polished reference: smaller university line, smaller submitted-by name, location line, professor's title split onto two lines, and a Date field beneath the Signature.

- [ ] **Step 1: Update cover-page size constants**

Near the top of the file, find:

```python
SIZE_COVER_TITLE = 30
SIZE_COVER_BIG = 22
SIZE_COVER_NAME = 18
```

Replace with:

```python
SIZE_COVER_TITLE = 20   # university line — was 30
SIZE_COVER_BIG = 22     # subject (CLOUD COMPUTING) — unchanged
SIZE_COVER_NAME = 15    # student full name — was 18
```

- [ ] **Step 2: Replace `add_cover_page` body**

Find the existing `def add_cover_page(doc, cfg):` function and replace its **entire body** (everything inside the function — keep the `def` line) with:

```python
def add_cover_page(doc, cfg):
    for _ in range(2):
        doc.add_paragraph()

    _cover_centered(doc, cfg.institution.university.upper(),
                    bold=True, size=SIZE_COVER_TITLE, color=COLOR_PRIMARY,
                    space_after=8)
    _cover_centered(doc, cfg.institution.faculty,
                    bold=False, size=14, color=COLOR_PRIMARY)
    p_school = _cover_centered(doc, cfg.institution.school,
                               italic=True, size=13, color=COLOR_GREY)
    _cover_centered(doc, cfg.institution.location,
                    italic=True, size=11, color=COLOR_GREY)
    _add_horizontal_rule(p_school, color=COLOR_PRIMARY, size=12)

    for _ in range(3):
        doc.add_paragraph()

    _cover_centered(doc, "A LAB REPORT",
                    bold=True, size=14, color=COLOR_GREY, space_after=4)
    _cover_centered(doc, "ON",
                    size=12, color=COLOR_GREY, space_after=4)
    p_title = _cover_centered(doc, cfg.subject.name.upper(),
                              bold=True, size=SIZE_COVER_BIG,
                              color=COLOR_PRIMARY, space_after=2)
    _cover_centered(doc, "(Practical)",
                    italic=True, size=12, color=COLOR_GREY, space_after=4)
    _add_horizontal_rule(p_title, color=COLOR_PRIMARY, size=8)

    for _ in range(3):
        doc.add_paragraph()

    _cover_centered(doc, "Submitted by:",
                    italic=True, size=12, color=COLOR_GREY, space_after=4)
    _cover_centered(doc, cfg.student.full_name,
                    bold=True, size=SIZE_COVER_NAME,
                    color=COLOR_PRIMARY, space_after=2)
    _cover_centered(doc, f"Roll No. {cfg.student.roll_number}",
                    size=12, color=COLOR_GREY, space_after=2)
    _cover_centered(doc, f"{cfg.student.semester} Semester  |  {cfg.student.program}",
                    size=11, color=COLOR_GREY, space_after=4)

    for _ in range(2):
        doc.add_paragraph()

    _cover_centered(doc, "Submitted to:",
                    italic=True, size=12, color=COLOR_GREY, space_after=4)
    _cover_centered(doc, cfg.professor.name,
                    bold=True, size=13, color=COLOR_PRIMARY, space_after=2)

    # Split professor.title on the LAST comma so the trailing institution name
    # ("Far Western University") becomes its own line. If no comma, the whole
    # title goes on line 1 and line 2 is omitted.
    title = cfg.professor.title
    if ", " in title:
        title_line_1, title_line_2 = title.rsplit(", ", 1)
    else:
        title_line_1, title_line_2 = title, ""
    _cover_centered(doc, title_line_1,
                    size=11, color=COLOR_GREY, space_after=2)
    if title_line_2:
        _cover_centered(doc, title_line_2,
                        size=11, color=COLOR_GREY, space_after=4)

    for _ in range(3):
        doc.add_paragraph()

    _cover_centered(doc, "Signature:  ____________________",
                    size=11, color=COLOR_GREY, space_after=4)
    _cover_centered(doc, "Date:  ____________________",
                    size=11, color=COLOR_GREY, space_after=2)

    doc.add_page_break()
```

- [ ] **Step 3: Run the script**

```bash
python scripts/build_report.py
```

- [ ] **Step 4: Verify visually**

Open the doc in Word. On the cover page check, top to bottom:
1. `FAR WESTERN UNIVERSITY` is visibly smaller than before (20pt navy, not 30pt).
2. `Mahendranagar, Kanchanpur` appears in italic grey under `School of Engineering`.
3. Student name "Mukesh Pant" is 15pt navy bold.
4. Professor block reads `Er. Robinson Pujara` / `Lecturer, School of Engineering` / `Far Western University` on three separate lines.
5. Both `Signature:  ____________________` and `Date:  ____________________` are visible.

- [ ] **Step 5: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: restyle cover page (sizes, location, date, prof split)"
```

---

### Task 6: Acknowledgement section (between cover and ToC)

**Files:**
- Modify: `scripts/build_report.py`

**Why:** The polished reference has an Acknowledgement page between the cover and the ToC — three justified paragraphs of personal gratitude, signed at the bottom right. We add it as a hard-coded prose template with config substitutions.

- [ ] **Step 1: Add `add_acknowledgement(doc, cfg)` above the `# Table of contents` divider**

Find:

```python
# ---------------------------------------------------------------------------
# Table of contents
# ---------------------------------------------------------------------------
```

Insert this function **immediately above** that divider:

```python
def add_acknowledgement(doc, cfg):
    """Acknowledgement page: Heading 1 'ACKNOWLEDGEMENT', three justified body
    paragraphs, signed at the bottom right with name, roll, and program.
    """
    s = cfg.student
    inst = cfg.institution
    prof = cfg.professor

    h = doc.add_paragraph(style="Heading 1")
    h.alignment = WD_ALIGN_PARAGRAPH.CENTER
    h.add_run("ACKNOWLEDGEMENT")

    paragraphs = [
        (
            f"I would like to express my sincere gratitude to my subject teacher, "
            f"{prof.name}, for guiding me throughout the {cfg.subject.name} "
            f"laboratory work and for the patient explanations of cloud concepts "
            f"that helped me understand the material well beyond what a textbook "
            f"alone could offer."
        ),
        (
            f"I am also thankful to the {inst.faculty} and the {inst.school} at "
            f"{inst.university} for providing the lab environment and the "
            f"opportunity to complete the practical exercises that make up this "
            f"report."
        ),
        (
            f"Finally, I would like to thank my classmates of {s.semester} semester "
            f"{s.program} for the discussions and the willingness to compare notes "
            f"while working through the AWS console — those small conversations "
            f"often saved hours of confusion."
        ),
    ]
    for txt in paragraphs:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        _para_spacing(p, space_before=0, space_after=8, line=1.3)
        r = p.add_run(txt)
        _set_run(r, size=SIZE_BODY)

    # Signed block, right-aligned
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    _para_spacing(p, space_before=14, space_after=2, line=1.2)
    r = p.add_run(s.full_name)
    _set_run(r, bold=True, size=12, color=COLOR_PRIMARY)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    _para_spacing(p, space_before=0, space_after=2, line=1.2)
    r = p.add_run(f"Roll No. {s.roll_number}")
    _set_run(r, size=11, color=COLOR_GREY)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    _para_spacing(p, space_before=0, space_after=2, line=1.2)
    r = p.add_run(f"{s.program}, {s.semester} Semester")
    _set_run(r, size=11, color=COLOR_GREY)

    doc.add_page_break()
```

- [ ] **Step 2: Wire it into `build()` between cover and ToC**

Find:

```python
    add_cover_page(doc, cfg)
    labs = get_labs(cfg)
    add_toc(doc, labs)
```

Replace with:

```python
    add_cover_page(doc, cfg)
    add_acknowledgement(doc, cfg)
    labs = get_labs(cfg)
    add_toc(doc, labs)
```

- [ ] **Step 3: Run and verify**

```bash
python scripts/build_report.py
```

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); texts = [p.text for p in d.paragraphs]; print('Has heading:', 'ACKNOWLEDGEMENT' in texts); print('Mentions professor:', any('Er. Robinson Pujara' in t for t in texts))"
```

Expected output:
```
Has heading: True
Mentions professor: True
```

- [ ] **Step 4: Visual check (optional but recommended)**

Open the .docx in Word. Page 2 should be the Acknowledgement page, with `ACKNOWLEDGEMENT` as a navy bold heading, three justified paragraphs, and the signed block at bottom right.

- [ ] **Step 5: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: add Acknowledgement page between cover and ToC"
```

---

### Task 7: Replace hand-built ToC with a Word `TOC` field

**Files:**
- Modify: `scripts/build_report.py`

**Why:** The polished reference's ToC has real page numbers (`Lab 1.   Virtual Cloud Environment (VPC)   ····   4`). Hand-computing those in Python is fragile (it depends on font metrics and line breaks Word actually performs); the standard approach is to insert a Word `TOC` field that auto-populates from Heading 1 paragraphs when the doc opens. We also flip on `w:updateFields` in `settings.xml` so the user does not need to right-click and update manually.

- [ ] **Step 1: Add two helper functions above the `# Table of contents` divider**

Find:

```python
# ---------------------------------------------------------------------------
# Table of contents
# ---------------------------------------------------------------------------
```

Insert above it:

```python
def _add_toc_field(paragraph, instr=r'TOC \o "1-1" \h \z \u'):
    """Emit a Word TOC field that builds a ToC from Heading 1 entries.

    The user only sees the ToC populate after opening the doc once and (a)
    Word auto-updates fields on open if `w:updateFields` is set, or (b) the
    user right-clicks the placeholder and chooses "Update field".
    """
    run = paragraph.add_run()
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    fld_begin.set(qn("w:dirty"), "true")  # tells Word to refresh on open
    run._r.append(fld_begin)

    instr_el = OxmlElement("w:instrText")
    instr_el.set(qn("xml:space"), "preserve")
    instr_el.text = instr
    run._r.append(instr_el)

    fld_sep = OxmlElement("w:fldChar")
    fld_sep.set(qn("w:fldCharType"), "separate")
    run._r.append(fld_sep)

    placeholder = paragraph.add_run(
        "Right-click and select \"Update Field\" to populate."
    )
    _set_run(placeholder, italic=True, size=10, color=COLOR_GREY)

    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    placeholder._r.append(fld_end)


def _enable_update_fields_on_open(doc):
    """Set <w:updateFields w:val="true"/> in settings.xml so Word refreshes
    PAGE / NUMPAGES / TOC fields the moment the document opens.
    """
    settings = doc.settings.element  # <w:settings ...>
    existing = settings.find(qn("w:updateFields"))
    if existing is None:
        update = OxmlElement("w:updateFields")
        update.set(qn("w:val"), "true")
        settings.append(update)
    else:
        existing.set(qn("w:val"), "true")
```

- [ ] **Step 2: Replace `add_toc` body**

Find the existing `def add_toc(doc, labs):` function. Replace its **entire body** (keep the `def` line, but you can remove the `labs` parameter usage — leave the parameter for backwards compatibility) with:

```python
def add_toc(doc, labs):
    """Add a centered 'TABLE OF CONTENTS' heading and a Word TOC field that
    populates from every Heading 1 paragraph in the document (labs +
    Acknowledgement + Conclusion).

    The `labs` argument is no longer needed (the field reads from doc heading
    structure) but is kept for call-site compatibility.
    """
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    _para_spacing(p, space_before=4, space_after=8, keep_with_next=True)
    r = p.add_run("TABLE OF CONTENTS")
    _set_run(r, bold=True, size=18, color=COLOR_PRIMARY)
    _add_horizontal_rule(p, color=COLOR_PRIMARY, size=8)

    toc_para = doc.add_paragraph()
    _para_spacing(toc_para, space_before=4, space_after=8, line=1.2)
    _add_toc_field(toc_para)

    doc.add_page_break()
```

- [ ] **Step 3: Call `_enable_update_fields_on_open` from `build()` just before saving**

Find:

```python
    out = output_path(cfg)
    out.parent.mkdir(parents=True, exist_ok=True)
    doc.save(out)
```

Insert one line so it reads:

```python
    _enable_update_fields_on_open(doc)
    out = output_path(cfg)
    out.parent.mkdir(parents=True, exist_ok=True)
    doc.save(out)
```

- [ ] **Step 4: Run and verify**

```bash
python scripts/build_report.py
```

Verify the TOC field is present in the XML:

```bash
python -c "import zipfile; z = zipfile.ZipFile('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); xml = z.read('word/document.xml').decode('utf-8'); print('TOC field:', 'TOC \\\\o' in xml); print('Update on open:', 'updateFields' in z.read('word/settings.xml').decode('utf-8'))"
```

Expected output:
```
TOC field: True
Update on open: True
```

- [ ] **Step 5: Visual check**

Open the .docx in Word. Word may briefly prompt "This document contains fields that may refer to other files. Do you want to update the fields?" — click Yes. The ToC page should now show entries: `Acknowledgement   2`, `Lab 1.   Virtual Cloud Environment (VPC)   ?`, `Lab 2 …`, etc. (Lab numbering format depends on Word — entries from Heading 1 will appear with whatever text the headings have. They'll all be there.)

(Note: at this stage the lab titles are still using raw paragraphs, NOT Heading 1 — so the ToC will only show `Acknowledgement` for now. The lab titles join the ToC after Task 8.)

- [ ] **Step 6: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: replace hand-built ToC with Word TOC field"
```

---

### Task 8: Switch lab titles to Heading 1 style

**Files:**
- Modify: `scripts/build_report.py`

**Why:** Right now `add_lab` builds the lab title as a raw paragraph with manual sizing/colour. Switching to Word's `Heading 1` style (already configured in Task 2) is what gets every lab into the navigation pane and the auto-generated ToC. The horizontal rule under the title stays — it's drawn explicitly by `_add_horizontal_rule`, not by the style.

- [ ] **Step 1: Modify the start of `add_lab`**

Find:

```python
def add_lab(doc, n, lab, *, is_first=False):
    title_p = doc.add_paragraph()
    _para_spacing(title_p, space_before=0, space_after=8, line=1.2,
                  keep_with_next=True,
                  page_break_before=not is_first)
    tr = title_p.add_run(f"Lab {n}: {lab['title']}")
    _set_run(tr, bold=True, size=SIZE_LAB_TITLE, color=COLOR_PRIMARY)
    _add_horizontal_rule(title_p, color=COLOR_PRIMARY, size=12)
```

Replace with:

```python
def add_lab(doc, n, lab, *, is_first=False):
    title_p = doc.add_paragraph(style="Heading 1")
    _para_spacing(title_p, space_before=0, space_after=8, line=1.2,
                  keep_with_next=True,
                  page_break_before=not is_first)
    title_p.add_run(f"Lab {n}: {lab['title']}")
    _add_horizontal_rule(title_p, color=COLOR_PRIMARY, size=12)
```

(The `_set_run(tr, ...)` call is removed — the Heading 1 style provides bold, size, and colour.)

- [ ] **Step 2: Run and verify**

```bash
python scripts/build_report.py
```

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); h1s = [p.text for p in d.paragraphs if p.style and p.style.name == 'Heading 1']; print('H1 count:', len(h1s)); [print(' -', t) for t in h1s]"
```

Expected output (10 entries — 1 acknowledgement + 9 labs):
```
H1 count: 10
 - ACKNOWLEDGEMENT
 - Lab 1: Virtual Cloud Environment (VPC)
 - Lab 2: Compute Instances and Startup Scripts (EC2)
 - Lab 3: Object Storage and Static Website Hosting (S3)
 - Lab 4: Virtual Networking — Subnets, Routing, and Security Groups
 - Lab 5: Load Balancer and Auto-Scaling Simulation
 - Lab 6: IAM Users, Groups and Policy Configuration
 - Lab 7: Serverless Function Deployment (Lambda, Fargate, DynamoDB)
 - Lab 8: Messaging Queue and Pub/Sub Simulation (SNS, SQS)
 - Lab 9: Infrastructure as Code using CloudFormation
```

- [ ] **Step 3: Visual check**

Open in Word, press `Ctrl+F` to open the navigation pane, click "Headings" tab. Every lab and the Acknowledgement should appear as a clickable item. The ToC page should now also list every lab once you update fields (right-click → Update Field, or close and reopen).

- [ ] **Step 4: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: lab titles now use Word Heading 1 style"
```

---

### Task 9: Switch per-lab section headings to Heading 2 + rename "Observations and Results"

**Files:**
- Modify: `scripts/build_report.py`

**Why:** The `Objective`, `AWS Services Used`, `Step-by-Step Procedure`, `Screenshots`, and `Observations and Results` headings should use Word's `Heading 2` style (configured in Task 2). The current `_add_h1` helper builds them as raw paragraphs — replace with `_add_h1` calling Heading 2 (despite the misleading name kept for minimal diff). Also rename "Observations & Results" → "Observations and Results" everywhere.

- [ ] **Step 1: Replace `_add_h1` body to use Heading 2 style**

The current helper is misnamed (it's called `_add_h1` but is used for sub-section headings inside a lab). Find:

```python
def _add_h1(doc, text, *, keep_with_next=True):
    p = doc.add_paragraph()
    _para_spacing(p, space_before=10, space_after=4, line=1.2,
                  keep_with_next=keep_with_next)
    r = p.add_run(text)
    _set_run(r, bold=True, size=SIZE_H1, color=COLOR_PRIMARY)
    return p
```

Replace with:

```python
def _add_h1(doc, text, *, keep_with_next=True):
    """Per-lab section heading. Uses Word's Heading 2 style.

    The function is called `_add_h1` for historical reasons; per-lab section
    headings are visually H2 in this document because the Lab title itself is H1.
    """
    p = doc.add_paragraph(style="Heading 2")
    _para_spacing(p, space_before=10, space_after=4, line=1.2,
                  keep_with_next=keep_with_next)
    p.add_run(text)
    return p
```

- [ ] **Step 2: Rename the heading text everywhere**

In `add_lab`, find:

```python
    _add_h1(doc, "Observations & Results")
```

Replace with:

```python
    _add_h1(doc, "Observations and Results")
```

- [ ] **Step 3: Run and verify**

```bash
python scripts/build_report.py
```

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); h2s = [p.text for p in d.paragraphs if p.style and p.style.name == 'Heading 2']; print('H2 count:', len(h2s)); print('First few:', h2s[:6]); print('Has rename:', 'Observations and Results' in h2s); print('Old gone:', 'Observations & Results' not in h2s)"
```

Expected output (5 H2 headings × 9 labs = 45):
```
H2 count: 45
First few: ['Objective', 'AWS Services Used', 'Step-by-Step Procedure', 'Screenshots', 'Observations and Results', 'Objective']
Has rename: True
Old gone: True
```

- [ ] **Step 4: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: section headings use Heading 2; rename to 'Observations and Results'"
```

---

### Task 10: Step sub-headings — change navy 12pt → black bold 12pt

**Files:**
- Modify: `scripts/build_report.py`

**Why:** Inside each step (`Step 1: Sign in and select region`), the helper `_add_h3` colours the text in `COLOR_SECONDARY` (mid-blue). The polished reference uses plain **black bold** at 12pt. Sized stays the same; only colour changes (drop the colour argument so the run inherits black from the Normal style).

- [ ] **Step 1: Update `_add_h3`**

Find:

```python
def _add_h3(doc, text, *, keep_with_next=True):
    p = doc.add_paragraph()
    _para_spacing(p, space_before=6, space_after=2, line=1.2,
                  keep_with_next=keep_with_next)
    r = p.add_run(text)
    _set_run(r, bold=True, size=SIZE_H3, color=COLOR_SECONDARY)
    return p
```

Replace with:

```python
def _add_h3(doc, text, *, keep_with_next=True):
    """Step sub-heading inside a lab procedure. Plain black bold 12pt."""
    p = doc.add_paragraph()
    _para_spacing(p, space_before=6, space_after=2, line=1.2,
                  keep_with_next=keep_with_next)
    r = p.add_run(text)
    _set_run(r, bold=True, size=SIZE_H3)
    return p
```

(The colour argument is dropped so the run renders in the default Normal-style black.)

Note that `SIZE_H3 = 12` already, which matches the polished reference — no change to the constant needed.

- [ ] **Step 2: Run and verify**

```bash
python scripts/build_report.py
```

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); ps = [p for p in d.paragraphs if p.text.startswith('Step 1:') and p.runs]; r = ps[0].runs[0]; print('Bold:', r.bold, 'Size:', r.font.size.pt, 'Color override:', r.font.color.rgb)"
```

Expected output (no explicit colour means `None`):
```
Bold: True Size: 12.0 Color override: None
```

- [ ] **Step 3: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: step sub-headings now plain black bold (was navy)"
```

---

### Task 11: Captions — italic only → bold + italic

**Files:**
- Modify: `scripts/build_report.py`

**Why:** The polished reference's figure captions are bold + italic at 10pt grey. The current script renders them italic only. One-line fix in `_add_screenshot`.

- [ ] **Step 1: Update caption run formatting**

Find:

```python
    cr = cap.add_run(caption)
    _set_run(cr, italic=True, size=SIZE_CAPTION, color=COLOR_GREY)
```

Replace with:

```python
    cr = cap.add_run(caption)
    _set_run(cr, bold=True, italic=True, size=SIZE_CAPTION, color=COLOR_GREY)
```

- [ ] **Step 2: Run and verify**

```bash
python scripts/build_report.py
```

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); cap = next(p for p in d.paragraphs if p.text.startswith('Figure 1.1')); r = cap.runs[0]; print('Bold:', r.bold, 'Italic:', r.italic, 'Size:', r.font.size.pt)"
```

Expected output:
```
Bold: True Italic: True Size: 10.0
```

- [ ] **Step 3: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: figure captions are now bold + italic (was italic only)"
```

---

### Task 12: AWS Services Used — drop bullets, add light-grey grid borders

**Files:**
- Modify: `scripts/build_report.py`

**Why:** The current 2-column table puts a navy bullet (`•  `) in front of each service. The polished reference is a plain bordered grid with just the service name in each cell. Drop the bullet runs, drop the manual column-width override (so the table fills body width naturally), and add a 1pt light-grey border around every cell.

- [ ] **Step 1: Add `_set_cell_borders` helper above `_add_services_table`**

Find:

```python
def _add_services_table(doc, services):
```

Insert this function **immediately above** it:

```python
def _set_cell_borders(cell, color="BFBFBF", size="4"):
    """Add a single 1pt light-grey border around a table cell on all four sides."""
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.find(qn("w:tcBorders"))
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        b = OxmlElement(f"w:{edge}")
        b.set(qn("w:val"), "single")
        b.set(qn("w:sz"), str(size))
        b.set(qn("w:space"), "0")
        b.set(qn("w:color"), color)
        borders.append(b)
```

- [ ] **Step 2: Replace `_add_services_table` body**

Find the existing `def _add_services_table(doc, services):` function. Replace its **entire body** with:

```python
def _add_services_table(doc, services):
    """Render services as a clean 2-column bordered grid (no bullets)."""
    n = len(services)
    rows = (n + 1) // 2
    table = doc.add_table(rows=rows, cols=2)
    table.alignment = WD_ALIGN_PARAGRAPH.CENTER

    for idx, svc in enumerate(services):
        r, c = divmod(idx, 2)
        cell = table.cell(r, c)
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        cell.text = ""
        para = cell.paragraphs[0]
        _para_spacing(para, space_before=2, space_after=2, line=1.15)
        run = para.add_run(svc)
        _set_run(run, size=SIZE_BODY)
        _set_cell_borders(cell)

    # If services count is odd, give the trailing empty cell a border too
    # so the grid looks consistent.
    if n % 2 == 1:
        empty_cell = table.cell(rows - 1, 1)
        _set_cell_borders(empty_cell)

    after = doc.add_paragraph()
    _para_spacing(after, space_before=0, space_after=4, line=1.0)
```

(`autofit = False` and the explicit `Inches(3.2)` width are gone, so the table will fill the page width and split evenly between the two columns.)

- [ ] **Step 3: Run and verify visually**

```bash
python scripts/build_report.py
```

Open in Word. On the first page of Lab 1, the "AWS Services Used" section should show a 1×2 grid: `Amazon VPC | AWS Management Console`, each cell with a thin light-grey border, no bullets.

- [ ] **Step 4: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: services table is plain bordered grid (drop navy bullets)"
```

---

### Task 13: Conclusion section (after Lab 9)

**Files:**
- Modify: `scripts/build_report.py`

**Why:** The polished reference closes with a Conclusion page — five paragraphs reflecting on what was learned across the nine labs. Add it as the symmetric counterpart to the Acknowledgement.

- [ ] **Step 1: Add `add_conclusion(doc, cfg)` above the `# Lab content` divider**

Find:

```python
# ---------------------------------------------------------------------------
# Lab content (functions of cfg)
# ---------------------------------------------------------------------------
```

Insert above it:

```python
def add_conclusion(doc, cfg):
    """Closing Conclusion page. Heading 1 'CONCLUSION' (so it joins the ToC)
    + five justified paragraphs synthesising the work across the nine labs.
    """
    s = cfg.student

    h = doc.add_paragraph(style="Heading 1")
    h.alignment = WD_ALIGN_PARAGRAPH.LEFT
    h.add_run("Conclusion")
    _para_spacing(h, space_before=0, space_after=8, line=1.2,
                  page_break_before=True)

    paragraphs = [
        (
            f"Across the nine labs in this report, I worked through the practical "
            f"building blocks of a typical AWS deployment, starting from the "
            f"network layer at the bottom and finishing with managed services and "
            f"infrastructure as code at the top. The labs were small enough to "
            f"finish in a single session, but together they cover most of what a "
            f"real cloud workload would touch."
        ),
        (
            "Labs 1 and 4 covered the network foundation — a VPC with public and "
            "private subnets, an internet gateway, route tables, and tiered "
            "security groups. The most useful idea here was that everything else "
            "in AWS sits on top of this network, so getting the routing and "
            "security boundaries right makes every later step easier."
        ),
        (
            "Labs 2, 3, and 5 covered compute and traffic delivery — an EC2 "
            "instance with a startup script, S3 hosting a static website without "
            "any server, and an Application Load Balancer in front of an Auto "
            "Scaling Group across two availability zones. Watching the ALB "
            "alternate between backend instances on each refresh made the "
            "horizontal-scaling story click in a way that reading about it never "
            "did."
        ),
        (
            "Lab 6 covered identity and access — IAM users, groups, and managed "
            "policies — and made the difference between assigning permissions "
            "through a group and attaching them directly to a user concrete. "
            "Group-based permissioning is what scales in practice, and the "
            "console makes it obvious why."
        ),
        (
            "Labs 7, 8, and 9 covered the higher-level managed services and "
            "infrastructure as code: a Lambda function writing into a DynamoDB "
            "table on each invocation, a Fargate task running an Nginx container "
            "without any EC2 host to manage, an SNS topic fanning out a single "
            "publish to both an SQS queue and an email subscriber, and finally a "
            "CloudFormation stack creating a VPC and an S3 bucket from a single "
            f"YAML file. Beyond the AWS services themselves, the labs gave me "
            f"practical experience with the AWS Management Console, the AWS CLI, "
            f"basic shell user-data scripts, and the discipline of capturing "
            f"evidence at each step — habits that will carry over into any cloud "
            f"work I do after this {s.semester} semester."
        ),
    ]
    for txt in paragraphs:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        _para_spacing(p, space_before=0, space_after=8, line=1.3)
        r = p.add_run(txt)
        _set_run(r, size=SIZE_BODY)
```

- [ ] **Step 2: Wire it into `build()` after the lab loop**

Find:

```python
    for i, lab in enumerate(labs, 1):
        add_lab(doc, i, lab, is_first=(i == 1))

    _enable_update_fields_on_open(doc)
```

Replace with:

```python
    for i, lab in enumerate(labs, 1):
        add_lab(doc, i, lab, is_first=(i == 1))

    add_conclusion(doc, cfg)

    _enable_update_fields_on_open(doc)
```

- [ ] **Step 3: Run and verify**

```bash
python scripts/build_report.py
```

```bash
python -c "from docx import Document; d = Document('report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'); h1s = [p.text for p in d.paragraphs if p.style and p.style.name == 'Heading 1']; print('H1 count:', len(h1s)); print('Last H1:', h1s[-1])"
```

Expected output:
```
H1 count: 11
Last H1: Conclusion
```

- [ ] **Step 4: Commit**

```bash
git add scripts/build_report.py
git commit -m "report: add Conclusion page after Lab 9"
```

---

### Task 14: Final acceptance check

**Files:**
- (read-only — no further edits if everything passes)

**Why:** Every spec acceptance criterion gets a single verification step here so the engineer knows the work is complete.

- [ ] **Step 1: Re-run the build clean**

```bash
python scripts/build_report.py
```

Expected output: `Wrote ...\report\Mukesh_Pant_Cloud_Computing_Lab_Report.docx` and no Python errors.

- [ ] **Step 2: Run the structural acceptance check**

```bash
python -c "
from docx import Document
import zipfile
path = 'report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx'

d = Document(path)

# 1. Margins
s = d.sections[0]
assert s.top_margin.inches == 1.0 and s.left_margin.inches == 1.0, 'margins not 1in'
print('OK margins 1.0 all sides')

# 2. Body 11pt
assert d.styles['Normal'].font.size.pt == 11.0, 'Normal not 11pt'
print('OK body 11pt')

# 3. Heading styles
assert d.styles['Heading 1'].font.size.pt == 16.0
assert d.styles['Heading 2'].font.size.pt == 13.0
print('OK Heading 1 16pt, Heading 2 13pt')

# 4. Heading 1 count = 1 (Acknowledgement) + 9 labs + 1 (Conclusion) = 11
h1s = [p.text for p in d.paragraphs if p.style and p.style.name == 'Heading 1']
assert len(h1s) == 11, f'expected 11 H1s, got {len(h1s)}'
print('OK 11 Heading 1 paragraphs (Ack + 9 labs + Conclusion)')

# 5. Heading 2 count = 5 sections per lab x 9 labs = 45
h2s = [p.text for p in d.paragraphs if p.style and p.style.name == 'Heading 2']
assert len(h2s) == 45, f'expected 45 H2s, got {len(h2s)}'
print('OK 45 Heading 2 paragraphs (5 sections x 9 labs)')

# 6. 35 inline images preserved
assert len(d.inline_shapes) == 35, f'expected 35 images, got {len(d.inline_shapes)}'
print('OK 35 screenshots embedded')

# 7. TOC + NUMPAGES + updateFields all present in raw XML
with zipfile.ZipFile(path) as z:
    docxml = z.read('word/document.xml').decode('utf-8')
    settings = z.read('word/settings.xml').decode('utf-8')
assert 'TOC \\\\o' in docxml or 'TOC \\\\\\\\o' in docxml or 'TOC ' in docxml, 'TOC field missing'
assert 'NUMPAGES' in docxml, 'NUMPAGES field missing'
assert 'updateFields' in settings, 'updateFields not enabled'
print('OK TOC field, NUMPAGES field, updateFields=true')

# 8. 'Observations and Results' (not '& Results')
assert any('Observations and Results' == p.text for p in d.paragraphs)
assert not any('Observations & Results' == p.text for p in d.paragraphs)
print('OK 'Observations and Results' rename')

print()
print('All acceptance checks passed.')
"
```

Expected output: every line above with `OK ...`, ending with `All acceptance checks passed.`

- [ ] **Step 3: Open the .docx in Word and run the visual checklist**

Open `report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx`. Click **Yes** if Word asks to update fields. Walk the document top to bottom and confirm:

1. **Cover page:** "FAR WESTERN UNIVERSITY" 20pt navy, location line under "School of Engineering", professor's title on two lines, both Signature and Date fields visible.
2. **Page 2 — Acknowledgement** with three justified paragraphs and the signed block bottom-right.
3. **Page 3 — Table of Contents** populated with: `Acknowledgement`, all 9 labs, `Conclusion`, each followed by a real page number (after a dot leader).
4. **Pages after the cover:** running header `Cloud Computing Lab Report  |  Mukesh Pant  |  Roll No. 29` (italic grey) and footer `Page X of Y` (centered grey).
5. **Within each lab:** title in 16pt navy with horizontal rule, section headings in 13pt navy, step sub-headings in plain black bold, AWS Services Used as a plain bordered grid (no navy bullets), figure captions bold + italic.
6. **Last page — Conclusion** with five justified paragraphs.
7. **Navigation pane (Ctrl+F → Headings):** 11 entries.

- [ ] **Step 4: Final commit if any docs need updating**

If everything passes, the implementation is complete and no further commits are needed. If any of the visual checks fails, open a follow-up task referencing the spec's acceptance criteria and the failing item.

---

## Self-review against spec

### Spec coverage

Walking each spec section to confirm a task implements it:

| Spec item | Implemented in |
|-----------|----------------|
| 1.0″ margins all four sides | Task 3 |
| Header (subject \| name \| roll, italic 10pt grey, rule, suppressed on cover) | already in script — left untouched |
| Footer "Page X of Y" | Task 4 |
| Body 11pt Calibri, 1.3 line spacing | Task 3 |
| Native Heading 1/2 styles (16pt/13pt navy bold) | Task 2 (config), Tasks 8, 9 (apply) |
| Lab title underline rule (only beneath lab titles, not Ack/Conclusion H1s) | Task 8 keeps `_add_horizontal_rule` only inside `add_lab`; Tasks 6, 13 don't add a rule under their H1s |
| Step sub-heading 12pt black bold | Task 10 |
| Captions bold + italic 10pt grey | Task 11 |
| Cover layout (sizes, location, Date, professor split) | Task 5 (relies on Task 1 config) |
| Acknowledgement section | Task 6 |
| ToC as Word TOC field with auto-update | Task 7 |
| Conclusion section | Task 13 |
| Lab title → Heading 1 | Task 8 |
| Section headings → Heading 2 | Task 9 |
| AWS Services Used → bordered grid (no bullets) | Task 12 |
| `Observations and Results` rename | Task 9 |
| `institution.location` config field | Task 1 |
| `professor.title` extension | Task 1 |
| `professor.title` last-comma split | Task 5 |
| All 35 screenshots preserved in place | Asserted in Task 14 acceptance check |

No spec items uncovered.

### Placeholder scan

Searched the plan for `TBD`, `TODO`, `implement later`, `add appropriate`, `similar to Task`, etc. — none present. Every code step contains the actual code; every verification step contains the actual command and expected output.

### Type / signature consistency

- `_set_cell_borders(cell, color="BFBFBF", size="4")` — used in Task 12, defined in Task 12. Defaults match the call site (no args passed).
- `_add_pages_field(run)` — defined in Task 4, used in Task 4. Mirrors the existing `_add_page_field(run)` signature.
- `_add_toc_field(paragraph, instr=...)` — defined in Task 7, used in Task 7. Default `instr` covers the only call site.
- `_enable_update_fields_on_open(doc)` — defined in Task 7, called from `build()` in Task 7.
- `configure_heading_styles(doc)` — defined in Task 2, called from `build()` in Task 2.
- `add_acknowledgement(doc, cfg)` — defined in Task 6, called from `build()` in Task 6.
- `add_conclusion(doc, cfg)` — defined in Task 13, called from `build()` in Task 13.
- `_add_h1` (kept name despite being H2 visually) — body changes in Task 9; called by `add_lab` everywhere.

All cross-references are consistent.
