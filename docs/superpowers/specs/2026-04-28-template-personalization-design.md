---
name: Template Personalization — Design Spec
description: Refactor the existing 9-lab cloud computing project into a personalizable template so anyone who clones the repo can run the labs and produce a fully personalized lab report by editing one config file
type: design
date: 2026-04-28
owner: Mukesh Pant (Roll No. 29)
---

# Template Personalization — Design Spec

## 1. Goal

Convert the currently-personalized cloud-computing lab project into a
**reusable template**. After cloning the repo and running a single
personalization step, a third party can:

- Run any lab's `terraform apply` and have AWS resources tagged and named
  with their own identifier (e.g. `vpc-jane` instead of `vpc-mukesh`).
- Regenerate `report/<Their_Name>_Cloud_Computing_Lab_Report.docx` with
  their cover page, their figure captions, and procedure prose that
  references their resource names.

The repo must still produce **Mukesh's exact original output by default**,
so cloning + running with no personalization yields the same report and
resource names as the version Mukesh has already submitted.

## 2. Non-goals

- Multi-tenant runtime (different users running labs in parallel from the
  same repo).
- AWS account isolation features beyond what already exists (SSO, account
  switching, cross-account roles).
- Templating the prose tone or language (output is always English).
- Templating CIDR blocks, AMI selection, instance types — defaults work
  for any AWS account in any region.
- Replacing references to "Mukesh Pant" in `README.md` — that's authorship
  attribution, not a hardcoded variable.

## 3. Personalizable fields (the template surface)

A single root file `config.yaml` holds all personalizable values:

```yaml
student:
  suffix: mukesh                # lowercase identifier; used in all resource names
  display_name: Mukesh          # used in tags, HTML, prose ("Mukesh's EC2")
  full_name: Mukesh Pant        # used on cover page; drives report filename
  roll_number: "29"             # cover page; string to allow non-numeric rolls
  semester: "VIII"              # cover page
  program: B.E. Computer Engineering   # cover page

institution:
  university: Far Western University
  faculty: Faculty of Engineering
  school: School of Engineering

subject:
  name: Cloud Computing

professor:
  name: Er. Robinson Pujara
  title: Lecturer, School of Engineering, FWU

aws:
  region: ap-south-1
  region_label: Asia Pacific (Mumbai)
```

**Excluded from the config** (and why):
- `subscriber_email` (Lab 8 SNS) — personal, must remain a Terraform CLI
  argument so it never gets committed by accident.
- CIDR blocks, AMI IDs, instance types — defaults work everywhere.

## 4. Personalization entry points

Two equivalent ways to set values:

1. **Edit `config.yaml` directly** — single file, easy diff, version-control
   friendly.
2. **Run `python scripts/personalize.py`** — interactive wizard with current
   `config.yaml` values pre-filled as defaults. Also accepts CLI flags for
   scripted runs:

   ```
   python scripts/personalize.py \
     --suffix jane --display-name Jane \
     --full-name "Jane Doe" --roll 5 \
     --semester VII --professor "Dr. Alice Smith"
   ```

Both paths converge on the same end state: `config.yaml` is updated, plus
the wizard runs the propagation steps below so Terraform and CloudFormation
pick up the new values without further user action.

## 5. Propagation: how config reaches each subsystem

### 5.1 Terraform (Labs 1–8)

- Each lab's `variables.tf` declares the variables it uses
  (`suffix`, `display_name`, `full_name`, `region`, etc.) with sensible
  defaults so a `terraform apply` works even if no `tfvars` exist.
- `personalize.py` writes `terraform.tfvars.json` into each of the 9 lab
  folders. Terraform auto-loads any `*.auto.tfvars.json` in the working
  directory, so no extra CLI flags are needed.
- `*.tf` files reference `var.suffix` etc. instead of hardcoded literals.
- `provider.tf` reads `region` from a var; default tags use
  `var.display_name`.

### 5.2 Inline files (HTML, shell scripts)

Files that today contain Mukesh's name as plain text:

- `lab-02/user_data.sh`
- `lab-03/web/index.html`, `lab-03/web/error.html`
- `lab-05/user_data.sh`

Are renamed `*.tpl` and rendered with Terraform's built-in
`templatefile()` function:

```hcl
user_data = templatefile("${path.module}/user_data.sh.tpl", {
  display_name = var.display_name
  full_name    = var.full_name
  roll_number  = var.roll_number
})
```

The template files use Terraform's `${variable}` interpolation syntax.

### 5.3 Lambda payload (Lab 7)

`handler.py` is reused as-is and reads a new environment variable
`OWNER_NAME` (alongside the existing `TABLE_NAME`). The Terraform
`aws_lambda_function` resource passes
`OWNER_NAME = var.display_name` in its environment variables block.

### 5.4 CloudFormation (Lab 9)

- File renamed `stack-mukesh.yaml` → `stack.yaml`.
- Stack name and bucket prefix are derived from the `OwnerName` parameter.
- `personalize.py` rewrites the YAML's default `OwnerName` parameter to
  match `student.display_name` so deploying with no `--parameter-overrides`
  still produces the user's resources.
- Deploy command in `README-screenshots.md` stays the same.

### 5.5 Report builder (`scripts/build_report.py`)

- Reads `config.yaml` at script startup via `yaml.safe_load`.
- The 9 `LAB_*` dictionaries become **functions** that take `cfg` and
  return a dict, so all references like `vpc-mukesh` in procedure prose
  and `Figure 1.1 — VPC vpc-mukesh listed in the Mumbai region`
  in figure captions resolve dynamically.
- Cover page reads name, roll, semester, professor, institution from `cfg`.
- **Output filename** derives from `full_name`:
  `report/{full_name with underscores}_Cloud_Computing_Lab_Report.docx`.
  So Mukesh's stays `Mukesh_Pant_..._Report.docx` and Jane's becomes
  `Jane_Doe_..._Report.docx` automatically.

## 6. File-level change inventory

### 6.1 New files
- `config.yaml` — committed with Mukesh's values as defaults.
- `config.example.yaml` — duplicate with placeholder values, useful as
  reference if a user accidentally corrupts `config.yaml`.
- `scripts/personalize.py` — wizard + CLI flags.
- `scripts/lib/config.py` — small loader module used by both
  `personalize.py` and `build_report.py`. Loads YAML, returns a typed
  object/namespace.
- `requirements.txt` — pins `python-docx`, `Pillow`, `pyyaml`.

### 6.2 Modified files (per category)

**Terraform** (9 labs × `provider.tf`, `variables.tf`, `main.tf`,
`outputs.tf`):
- `variables.tf`: declare `suffix`, `display_name`, `full_name`, `region`,
  `roll_number`, etc. as needed by that lab.
- `provider.tf`: `region = var.region`; default tags
  `Owner = var.display_name`.
- `main.tf`: replace `"vpc-mukesh"` → `"vpc-${var.suffix}"`,
  `"mukesh-ec2-sg"` → `"${var.suffix}-ec2-sg"`,
  `"Developers-mukesh"` → `"Developers-${var.suffix}"`, etc.
- `outputs.tf`: no functional changes; values flow through.

**Inline file renames + content updates**:
- `lab-02/user_data.sh` → `user_data.sh.tpl` (Terraform interpolation
  syntax for vars).
- `lab-03/web/index.html` → `web/index.html.tpl` (same).
- `lab-03/web/error.html` → `web/error.html.tpl`.
- `lab-05/user_data.sh` → `user_data.sh.tpl`.
- `lab-07/lambda/handler.py`: hardcoded `"Mukesh"` → `os.environ["OWNER_NAME"]`.
  `aws_lambda_function` gets `OWNER_NAME = var.display_name` env var.
- `lab-09/stack-mukesh.yaml` → `stack.yaml`. Default parameter
  `OwnerName` value will be rewritten by `personalize.py`.
- All 9 `README-screenshots.md` updated where they reference resource names
  with hardcoded suffixes (replace prose like
  *"the bucket should be named `mukesh-static-<random>`"* with
  *"the bucket should be named `${suffix}-static-<random>`"*).

**Report builder**:
- `scripts/build_report.py` — significant restructure: `LAB_*` dicts
  become callables; cover page reads from cfg; output filename is dynamic.

**README**:
- Add a new "Personalize this template" section before the "Reproducing a
  workload" section, with the two paths (edit YAML directly / run wizard).

### 6.3 Files NOT changed
- `LICENSE` — name in copyright stays.
- Existing committed screenshots — they remain Mukesh's screenshots; the
  template explains that a friend who runs labs is expected to capture
  their own.
- Existing committed `report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx`
  — kept as-is; refactor must regenerate an identical (or
  visually-identical) file when defaults are used.
- `docs/superpowers/specs/2026-04-27-cloud-lab-report-design.md` and the
  matching plan — historical record, do not modify.

## 7. Default-output verification

After the refactor:

1. With unchanged `config.yaml` (Mukesh's defaults), run
   `python scripts/personalize.py --apply --no-prompt` to regenerate
   `terraform.tfvars.json` files and rewrite the CFN template default,
   without prompting interactively.
2. Run `python scripts/build_report.py`.
3. Compare the new `.docx` against the previously committed one by
   opening both side-by-side in Word.

**Acceptance criterion**: every page (cover, TOC, all 9 labs) renders
visually identically — same text, same layout, same images, same
captions. Differences acceptable without action: file metadata
(creation timestamp), internal paragraph IDs, image XML hashes
(re-embedded picture XML may serialize slightly differently). Anything
visible to a reader is a defect to fix.

For Terraform side: `terraform plan` in any lab folder should produce
"No changes" if the corresponding stack were already up — i.e. the
generated tfvars produce the same resource graph as the previous
hardcoded values.

## 8. Workflow comparison (before / after)

**Before (today):**
```
clone → cd terraform/lab-01-vpc → terraform apply → screenshots → terraform destroy
```
Always produces Mukesh-named resources. Report belongs to Mukesh.

**After (template):**
```
clone
  → (option) python scripts/personalize.py    # writes config + tfvars
  → cd terraform/lab-01-vpc → terraform apply # uses your suffix
  → screenshots → terraform destroy
  → python scripts/build_report.py            # produces YOUR docx
```
Skipping the personalize step still works — it gives Mukesh's defaults.

## 9. Risks & mitigations

| ID | Risk | Mitigation |
|----|------|------------|
| R1 | Templating breaks resources mid-lab (typo in `${var.x}` causes apply-time error) | After refactor, run `terraform validate` in every lab folder; commit only after all 9 pass. Add `terraform validate` to the verification step in the implementation plan. |
| R2 | Regenerated `.docx` differs visually from committed one | Verification step (Section 7) catches this. If diff is real, fix the prose template until output matches. |
| R3 | `personalize.py` overwrites a user's hand-edited tfvars | Wizard prints the changes it will make and asks for confirmation before writing. |
| R4 | YAML rewrite for CloudFormation default param breaks YAML structure | Use a minimal regex-style line replacement targeting the single `Default: <name>` line under the `OwnerName` parameter — no full YAML round-trip needed, no extra dependency. Verified by running `aws cloudformation validate-template` after each rewrite. |
| R5 | A user's `display_name` contains characters invalid in AWS resource names (spaces, punctuation, capitals) | `personalize.py` validates `suffix` against the regex `^[a-z][a-z0-9-]{1,30}$` and refuses non-conforming values. `display_name` is allowed to be free-form because it only appears in tags/prose, not resource names. |
| R6 | Existing local `terraform.tfstate` files conflict with renamed resources | Document in the README that personalizing AFTER an apply requires running `terraform destroy` first, or expect Terraform to plan a "destroy + recreate" diff. |
| R7 | Lab 7 Lambda handler is committed without env var; existing deployments break on next apply | Change is backwards-incompatible. Acceptable — this is a refactor commit, not a hot patch. |

## 10. Out of scope (for this spec)

- Web UI for personalization.
- A `terraform destroy --all` script that destroys every lab's resources.
- Multi-language report generation.
- A CI workflow that lints `config.yaml` on every push.

## 11. Definition of done

- `config.yaml` exists at repo root with Mukesh's values.
- `scripts/personalize.py` runs without errors and propagates correctly.
- All 9 labs pass `terraform validate`.
- `python scripts/build_report.py` produces a `.docx` that visually
  matches the existing committed `Mukesh_Pant_..._Report.docx` when
  defaults are unchanged.
- README has a "Personalize this template" section.
- A second smoke test: change `config.yaml` to a fictional `Jane Doe`,
  run `personalize.py`, run `terraform plan` in (say) Lab 1 — it must
  show the resource will be named `vpc-jane`. Run
  `build_report.py` — it must write `Jane_Doe_..._Report.docx` with all
  references to "Mukesh" replaced by "Jane".
- All changes committed in a clear sequence (one commit per logical step
  per the writing-plans pattern).
