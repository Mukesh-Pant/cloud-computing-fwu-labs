# Template Personalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the existing 9-lab cloud computing project so that anyone who clones the repo can personalize all resource names, HTML, Lambda payloads, CloudFormation parameters, and the compiled lab report by editing one root `config.yaml` (or running an interactive wizard). Default values reproduce Mukesh's exact original output.

**Architecture:** Single source of truth at `config.yaml`. A small Python config loader (`scripts/lib/config.py`) is reused by both the wizard (`scripts/personalize.py`) and the report builder (`scripts/build_report.py`). `personalize.py` propagates values into per-lab `terraform.tfvars.json` files (Terraform auto-loads them) and into Lab 9's CloudFormation YAML default. Inline files (HTML, shell scripts) are templated with Terraform's `templatefile()` function. The Lambda payload reads an env var.

**Tech Stack:** Python 3.11+ (`pyyaml`, `python-docx`, `Pillow`), Terraform 1.6+, AWS CLI v2.

**Spec reference:** [docs/superpowers/specs/2026-04-28-template-personalization-design.md](../specs/2026-04-28-template-personalization-design.md)

---

## File-level decomposition

**New files:**
- `config.yaml` — committed defaults (Mukesh's values).
- `config.example.yaml` — placeholder reference copy.
- `requirements.txt` — pins Python dependencies.
- `scripts/lib/__init__.py`, `scripts/lib/config.py` — config loader (reused by wizard + report builder).
- `scripts/personalize.py` — interactive wizard + CLI flags + propagation logic.

**Modified files (~30 across all labs):**
- `terraform/lab-NN/{provider.tf, variables.tf, main.tf}` for each of 9 labs.
- Lab 2: `user_data.sh` → `user_data.sh.tpl` + `main.tf` uses `templatefile()`.
- Lab 3: `web/{index,error}.html` → `*.tpl` + `main.tf` uses `templatefile()`.
- Lab 5: `user_data.sh` → `user_data.sh.tpl` + `main.tf` uses `templatefile()`.
- Lab 7: `lambda/handler.py` reads `OWNER_NAME` env var; `main.tf` passes it.
- Lab 9: `stack-mukesh.yaml` renamed `stack.yaml`; default `OwnerName` parameter rewritten.
- `scripts/build_report.py` — significant restructure (lab dicts → callables; config-driven cover page; dynamic output filename).
- `README.md` — add "Personalize this template" section.

---

## Phase 0 — Config infrastructure

### Task 0.1: Create `requirements.txt`

**Files:** Create `requirements.txt`

- [ ] **Step 1: Write the file**

```
python-docx==1.1.2
Pillow==11.2.1
PyYAML>=6.0
```

- [ ] **Step 2: Install**

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
python -m pip install -r requirements.txt
```

Expected: `python-docx`, `Pillow` already satisfied; `PyYAML` installed (or already present).

---

### Task 0.2: Create `config.yaml` with Mukesh's defaults

**Files:** Create `config.yaml`

- [ ] **Step 1: Write the file**

```yaml
# Cloud Computing Lab Project — personalization config
# Edit values here, OR run `python scripts/personalize.py` for an interactive wizard.

student:
  suffix: mukesh
  display_name: Mukesh
  full_name: Mukesh Pant
  roll_number: "29"
  semester: "VIII"
  program: B.E. Computer Engineering

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

---

### Task 0.3: Create `config.example.yaml` reference copy

**Files:** Create `config.example.yaml`

- [ ] **Step 1: Write the file**

```yaml
# Reference copy of config.yaml with placeholder values.
# Copy to config.yaml and edit, or run `python scripts/personalize.py`.

student:
  suffix: jane                       # lowercase, [a-z0-9-]+, no spaces (used in resource names)
  display_name: Jane                 # short display name (tags, HTML, prose)
  full_name: Jane Doe                # full name on cover page
  roll_number: "5"
  semester: "VII"
  program: B.E. Computer Engineering

institution:
  university: Your University
  faculty: Faculty of Engineering
  school: School of Engineering

subject:
  name: Cloud Computing

professor:
  name: Dr. Alice Smith
  title: Lecturer, School of Engineering

aws:
  region: ap-south-1
  region_label: Asia Pacific (Mumbai)
```

---

### Task 0.4: Create config loader module

**Files:** Create `scripts/lib/__init__.py`, `scripts/lib/config.py`

- [ ] **Step 1: Create `scripts/lib/__init__.py`** (empty file marking the package)

```python
```

- [ ] **Step 2: Write `scripts/lib/config.py`**

```python
"""Config loader shared by personalize.py and build_report.py.

Loads `config.yaml` from the repo root and exposes it as a dotted-access
namespace so consumers can write `cfg.student.suffix` instead of
`cfg["student"]["suffix"]`.
"""
from __future__ import annotations

import re
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "config.yaml"

SUFFIX_PATTERN = re.compile(r"^[a-z][a-z0-9-]{1,30}$")


def _ns(d: Any) -> Any:
    """Recursively convert nested dicts to SimpleNamespace for dotted access."""
    if isinstance(d, dict):
        return SimpleNamespace(**{k: _ns(v) for k, v in d.items()})
    if isinstance(d, list):
        return [_ns(x) for x in d]
    return d


def load(path: Path = CONFIG_PATH) -> SimpleNamespace:
    """Load config.yaml and return a SimpleNamespace tree.

    Raises FileNotFoundError if the file is missing.
    Raises ValueError if `student.suffix` is not a valid AWS-friendly token.
    """
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    suffix = data.get("student", {}).get("suffix", "")
    if not SUFFIX_PATTERN.match(str(suffix)):
        raise ValueError(
            f"student.suffix '{suffix}' is invalid. "
            "Must be lowercase, start with a letter, contain only [a-z0-9-], "
            "and be 2-31 chars long."
        )

    return _ns(data)


def as_dict(cfg: SimpleNamespace) -> dict:
    """Inverse of _ns — convert back to nested dict (for serialization)."""
    if isinstance(cfg, SimpleNamespace):
        return {k: as_dict(v) for k, v in vars(cfg).items()}
    if isinstance(cfg, list):
        return [as_dict(x) for x in cfg]
    return cfg
```

- [ ] **Step 3: Smoke-test the loader**

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
python -c "from scripts.lib.config import load; cfg = load(); print(cfg.student.suffix, '|', cfg.student.full_name, '|', cfg.aws.region)"
```

Expected output: `mukesh | Mukesh Pant | ap-south-1`

---

### Task 0.5: Create `scripts/personalize.py` (skeleton + interactive wizard)

**Files:** Create `scripts/personalize.py`

- [ ] **Step 1: Write the wizard + propagation script**

```python
"""Interactive personalization wizard.

Reads/writes `config.yaml` at the repo root, then propagates values into:
  - terraform/lab-NN/terraform.auto.tfvars.json (one per lab folder)
  - terraform/lab-09-cloudformation/stack.yaml (default OwnerName parameter)

Usage:
  python scripts/personalize.py                        # interactive prompts
  python scripts/personalize.py --apply --no-prompt    # propagate without prompting
  python scripts/personalize.py --suffix jane --display-name Jane \
      --full-name "Jane Doe" --roll 5 --semester VII --professor "Dr. Smith"
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from scripts.lib.config import (CONFIG_PATH, ROOT, SUFFIX_PATTERN, as_dict,
                                load)

LAB_DIRS = [
    ROOT / "terraform" / d
    for d in (
        "lab-01-vpc",
        "lab-02-ec2",
        "lab-03-s3-static-website",
        "lab-04-vpc-networking",
        "lab-05-alb-asg",
        "lab-06-iam",
        "lab-07-lambda-fargate-dynamodb",
        "lab-08-sns-sqs",
    )
]
CFN_TEMPLATE = ROOT / "terraform" / "lab-09-cloudformation" / "stack.yaml"


def _prompt(label: str, current: str) -> str:
    raw = input(f"{label} [{current}]: ").strip()
    return raw or current


def _validate_suffix(suffix: str) -> str:
    if not SUFFIX_PATTERN.match(suffix):
        raise SystemExit(
            f"Error: suffix '{suffix}' must match {SUFFIX_PATTERN.pattern}."
        )
    return suffix


def run_wizard(cfg_dict: dict) -> dict:
    """Prompt the user, mutate cfg_dict in place, return it."""
    print("\nPersonalize the cloud computing lab project")
    print("Press Enter to keep the current value shown in [brackets].\n")

    s = cfg_dict["student"]
    s["suffix"]       = _validate_suffix(_prompt("Resource name suffix (lowercase, hyphens ok)", s["suffix"]))
    s["display_name"] = _prompt("Display name (used in tags / HTML / prose)", s["display_name"])
    s["full_name"]    = _prompt("Full name (cover page)", s["full_name"])
    s["roll_number"]  = _prompt("Roll number", s["roll_number"])
    s["semester"]     = _prompt("Semester (e.g. VIII)", s["semester"])
    s["program"]      = _prompt("Program / degree", s["program"])

    inst = cfg_dict["institution"]
    inst["university"] = _prompt("University", inst["university"])
    inst["faculty"]    = _prompt("Faculty", inst["faculty"])
    inst["school"]     = _prompt("School", inst["school"])

    prof = cfg_dict["professor"]
    prof["name"]  = _prompt("Professor name", prof["name"])
    prof["title"] = _prompt("Professor title", prof["title"])

    aws = cfg_dict["aws"]
    aws["region"]       = _prompt("AWS region", aws["region"])
    aws["region_label"] = _prompt("AWS region label (used in prose)", aws["region_label"])

    return cfg_dict


def write_config(cfg_dict: dict) -> None:
    with CONFIG_PATH.open("w", encoding="utf-8") as f:
        yaml.safe_dump(cfg_dict, f, sort_keys=False, allow_unicode=True)
    print(f"  wrote {CONFIG_PATH.relative_to(ROOT)}")


def write_lab_tfvars(cfg_dict: dict) -> None:
    """Generate terraform.auto.tfvars.json in each lab folder."""
    s = cfg_dict["student"]
    aws = cfg_dict["aws"]
    payload = {
        "suffix":       s["suffix"],
        "display_name": s["display_name"],
        "full_name":    s["full_name"],
        "roll_number":  str(s["roll_number"]),
        "semester":     s["semester"],
        "region":       aws["region"],
        "region_label": aws["region_label"],
    }
    body = json.dumps(payload, indent=2) + "\n"
    for lab in LAB_DIRS:
        target = lab / "terraform.auto.tfvars.json"
        target.write_text(body, encoding="utf-8")
        print(f"  wrote {target.relative_to(ROOT)}")


def update_cfn_default(cfg_dict: dict) -> None:
    """Rewrite the Default value of the OwnerName CloudFormation parameter."""
    if not CFN_TEMPLATE.exists():
        print(f"  skipped {CFN_TEMPLATE.name} (not yet created)")
        return
    text = CFN_TEMPLATE.read_text(encoding="utf-8")
    new_default = cfg_dict["student"]["display_name"]
    # Match the OwnerName parameter block and replace its Default line.
    pattern = re.compile(
        r"(OwnerName:\s*\n(?:[ \t]+[^\n]+\n)*?[ \t]+Default:\s*)([^\n]+)",
        re.MULTILINE,
    )
    new_text, n = pattern.subn(rf"\g<1>{new_default}", text, count=1)
    if n != 1:
        raise SystemExit(
            f"Could not update {CFN_TEMPLATE.name}: OwnerName Default line not found."
        )
    CFN_TEMPLATE.write_text(new_text, encoding="utf-8")
    print(f"  updated {CFN_TEMPLATE.relative_to(ROOT)} (OwnerName default = {new_default})")


def apply_cli_flags(cfg_dict: dict, args: argparse.Namespace) -> dict:
    s = cfg_dict["student"]
    if args.suffix:        s["suffix"]       = _validate_suffix(args.suffix)
    if args.display_name:  s["display_name"] = args.display_name
    if args.full_name:     s["full_name"]    = args.full_name
    if args.roll:          s["roll_number"]  = str(args.roll)
    if args.semester:      s["semester"]     = args.semester
    if args.program:       s["program"]      = args.program
    if args.professor:     cfg_dict["professor"]["name"]  = args.professor
    if args.region:        cfg_dict["aws"]["region"]      = args.region
    return cfg_dict


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true",
                        help="Skip prompts; just propagate current config to lab folders.")
    parser.add_argument("--no-prompt", action="store_true",
                        help="Never prompt interactively (use with --apply).")
    parser.add_argument("--suffix")
    parser.add_argument("--display-name")
    parser.add_argument("--full-name")
    parser.add_argument("--roll")
    parser.add_argument("--semester")
    parser.add_argument("--program")
    parser.add_argument("--professor")
    parser.add_argument("--region")
    args = parser.parse_args()

    cfg = load()
    cfg_dict = as_dict(cfg)

    cfg_dict = apply_cli_flags(cfg_dict, args)

    if not args.apply and not args.no_prompt:
        cfg_dict = run_wizard(cfg_dict)

    print("\nWriting updates:")
    write_config(cfg_dict)
    write_lab_tfvars(cfg_dict)
    update_cfn_default(cfg_dict)
    print("\nDone. You can now run `terraform apply` in any lab folder, "
          "or `python scripts/build_report.py` to regenerate the report.\n")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Smoke-test wizard with no-prompt apply**

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
python scripts/personalize.py --apply --no-prompt
```

Expected output:
```
Writing updates:
  wrote config.yaml
  wrote terraform/lab-01-vpc/terraform.auto.tfvars.json
  wrote terraform/lab-02-ec2/terraform.auto.tfvars.json
  ... (8 lab files)
  skipped stack.yaml (not yet created)        # Lab 9 hasn't been renamed yet
Done.
```

(The CFN rewrite is skipped at this point because Lab 9 hasn't been renamed yet — we'll do that in Phase 9.)

---

### Task 0.6: Add `terraform.auto.tfvars.json` to `.gitignore`?

**Decision:** **No** — these files ARE committed. They reflect the current state of `config.yaml` and travel with the repo so a fresh `terraform apply` works without first running the wizard.

- [ ] **Step 1: Verify `.gitignore` does NOT exclude `*.auto.tfvars.json`**

```bash
grep -E "auto\.tfvars" .gitignore || echo "(not excluded — good)"
```

Expected: `(not excluded — good)`. The existing `*.tfvars` rule excludes `terraform.tfvars` and `*.tfvars` but not the `.json` variant. Verified.

---

### Task 0.7: Commit Phase 0

- [ ] **Step 1: Commit**

```bash
git add requirements.txt config.yaml config.example.yaml scripts/lib/ scripts/personalize.py terraform/lab-*/terraform.auto.tfvars.json
git commit -m "feat(template): add config.yaml, loader, and personalize wizard"
```

---

## Phase 1 — Refactor Lab 1 (VPC) — establishes the pattern

### Task 1.1: Update `terraform/lab-01-vpc/variables.tf`

**Files:** Modify `terraform/lab-01-vpc/variables.tf`

- [ ] **Step 1: Replace contents**

```hcl
variable "lab_name" {
  type    = string
  default = "lab-01-vpc"
}

variable "suffix" {
  type        = string
  description = "Lowercase identifier used in resource names (e.g. 'mukesh')"
  default     = "mukesh"
}

variable "display_name" {
  type        = string
  description = "Short display name used in tags (e.g. 'Mukesh')"
  default     = "Mukesh"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}
```

---

### Task 1.2: Update `terraform/lab-01-vpc/provider.tf`

- [ ] **Step 1: Replace contents**

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner   = var.display_name
      Project = "FWU-CloudComputing-Lab"
      Lab     = var.lab_name
    }
  }
}
```

---

### Task 1.3: Update `terraform/lab-01-vpc/main.tf`

- [ ] **Step 1: Replace contents**

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.suffix}"
  }
}
```

(Resource label changed from `mukesh` to `main` so the Terraform graph itself uses a generic name. The `Name` tag is what shows up in AWS Console — that's the user-visible identifier.)

---

### Task 1.4: Update `terraform/lab-01-vpc/outputs.tf`

- [ ] **Step 1: Replace contents** (tracking the new resource label)

```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC created for Lab 1"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR block of the Lab 1 VPC"
}
```

---

### Task 1.5: Validate Lab 1

- [ ] **Step 1: Run `terraform init` and `terraform validate`**

```bash
cd terraform/lab-01-vpc
terraform init -upgrade
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 2: Run `terraform plan` to verify resource diff is graph-equivalent**

```bash
terraform plan -no-color | head -40
```

Expected: shows `aws_vpc.main` to be created (or already created if state exists). The `Name` tag should be `vpc-mukesh` (matching the default).

If a previous Lab 1 state exists with the old `aws_vpc.mukesh` label, you will see a destroy + recreate. That's expected — the resource label changed. For the verification step, run `terraform destroy -auto-approve` first if there's stale state.

---

### Task 1.6: Commit Lab 1

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-01-vpc/
git commit -m "refactor(lab-01): parameterize via suffix/display_name/region vars"
```

---

## Phase 2 — Refactor Lab 2 (EC2 + user_data templating)

### Task 2.1: Rename + templatize user_data

- [ ] **Step 1: Rename and replace `terraform/lab-02-ec2/user_data.sh.tpl`**

```bash
git mv terraform/lab-02-ec2/user_data.sh terraform/lab-02-ec2/user_data.sh.tpl
```

- [ ] **Step 2: Replace contents of `user_data.sh.tpl`** with templated version (uses Terraform's `${var}` interpolation):

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable --now httpd
cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html>
<head>
  <title>${display_name}'s EC2 — Lab 2</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    body { font-family: system-ui, sans-serif; text-align: center; padding-top: 80px; background: #f5f5f5; color: #222; }
    h1   { font-size: 2.4rem; margin-bottom: 10px; }
    p    { font-size: 1.1rem; margin: 6px; }
    .badge { display: inline-block; background: #ff9900; color: white; padding: 4px 10px; border-radius: 4px; font-weight: bold; }
  </style>
</head>
<body>
  <h1>Hello from ${display_name}'s EC2 instance</h1>
  <p class="badge">FWU Cloud Computing — Practical Lab 2</p>
  <p>Roll No. ${roll_number} &middot; Region: ${region} (${region_label})</p>
  <p>Apache served this page at boot via EC2 user_data.</p>
</body>
</html>
HTML
```

(Note: the heredoc body now lives outside the `'HTML'` quotes? No — Terraform's `templatefile()` runs **before** the script is uploaded. Variables are interpolated at apply time. The heredoc remains `<<'HTML'` to prevent the *EC2 instance* from doing a second pass of variable substitution at boot.)

---

### Task 2.2: Update `terraform/lab-02-ec2/variables.tf`

- [ ] **Step 1: Replace contents**

```hcl
variable "lab_name" {
  type    = string
  default = "lab-02-ec2"
}

variable "suffix" {
  type    = string
  default = "mukesh"
}

variable "display_name" {
  type    = string
  default = "Mukesh"
}

variable "roll_number" {
  type    = string
  default = "29"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "region_label" {
  type    = string
  default = "Asia Pacific (Mumbai)"
}
```

---

### Task 2.3: Update `terraform/lab-02-ec2/provider.tf`

(Same pattern as Lab 1 — copy from Task 1.2.)

- [ ] **Step 1: Replace contents** with the same provider.tf from Task 1.2.

---

### Task 2.4: Update `terraform/lab-02-ec2/main.tf`

- [ ] **Step 1: Replace contents**

```hcl
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.suffix}-ec2-sg"
  description = "Allow SSH and HTTP for Lab 2"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.suffix}-ec2-sg" }
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    display_name = var.display_name
    roll_number  = var.roll_number
    region       = var.region
    region_label = var.region_label
  })

  tags = { Name = "ec2-${var.suffix}" }
}
```

---

### Task 2.5: Update `terraform/lab-02-ec2/outputs.tf`

- [ ] **Step 1: Update resource label references** (`aws_instance.mukesh` → `aws_instance.main`)

```hcl
output "instance_id" {
  value       = aws_instance.main.id
  description = "EC2 instance ID"
}

output "public_ip" {
  value       = aws_instance.main.public_ip
  description = "Public IPv4 address of the instance"
}

output "public_url" {
  value       = "http://${aws_instance.main.public_ip}"
  description = "Open this in a browser to see the welcome page"
}

output "ami_id" {
  value       = data.aws_ami.al2023.id
  description = "Amazon Linux 2023 AMI used"
}
```

---

### Task 2.6: Validate + commit Lab 2

```bash
cd terraform/lab-02-ec2
terraform init -upgrade
terraform validate
```
Expected: `Success!`

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-02-ec2/
git commit -m "refactor(lab-02): parameterize + template user_data via templatefile()"
```

---

## Phase 3 — Refactor Lab 3 (S3 static website + HTML templating)

### Task 3.1: Rename HTML files to `.tpl`

```bash
cd terraform/lab-03-s3-static-website
git mv web/index.html web/index.html.tpl
git mv web/error.html web/error.html.tpl
```

### Task 3.2: Update `web/index.html.tpl`

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${full_name} — S3 Static Website</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: Georgia, serif;
      background: #f0f4f8;
      color: #333;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: white;
      border-radius: 8px;
      padding: 48px 56px;
      max-width: 640px;
      text-align: center;
      box-shadow: 0 2px 12px rgba(0,0,0,0.1);
    }
    h1 { font-size: 2rem; margin-bottom: 12px; }
    .subtitle { font-size: 1.1rem; color: #555; margin-bottom: 24px; line-height: 1.6; }
    .badge {
      display: inline-block;
      background: #232f3e;
      color: #ff9900;
      padding: 6px 16px;
      border-radius: 4px;
      font-family: monospace;
      font-size: 0.9rem;
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>${full_name}</h1>
    <p class="subtitle">
      ${institution} — ${faculty} &middot; Roll No. ${roll_number}<br>
      Cloud Computing Practical — Lab 3
    </p>
    <span class="badge">Hosted on Amazon S3 &middot; ${region}</span>
    <p class="subtitle" style="margin-top:24px; font-size:0.95rem;">
      This page is served from an S3 bucket configured for static website hosting.<br>
      No web server required.
    </p>
  </div>
</body>
</html>
```

### Task 3.3: Update `web/error.html.tpl`

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Page Not Found — ${full_name}'s S3 Site</title>
  <style>
    body { font-family: sans-serif; text-align: center; padding: 80px; }
    h2 { color: #cc0000; }
  </style>
</head>
<body>
  <h2>404 — Page not found</h2>
  <p>${full_name}'s S3 static website — Lab 3, ${subject_name}</p>
</body>
</html>
```

### Task 3.4: Update `terraform/lab-03-s3-static-website/variables.tf`

```hcl
variable "lab_name" {
  type    = string
  default = "lab-03-s3-static-website"
}

variable "suffix" {
  type    = string
  default = "mukesh"
}

variable "display_name" {
  type    = string
  default = "Mukesh"
}

variable "full_name" {
  type    = string
  default = "Mukesh Pant"
}

variable "roll_number" {
  type    = string
  default = "29"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "region_label" {
  type    = string
  default = "Asia Pacific (Mumbai)"
}

# Institution + subject — only used in the rendered HTML, not in resource names.
variable "institution" {
  type    = string
  default = "Far Western University"
}

variable "faculty" {
  type    = string
  default = "Faculty of Engineering"
}

variable "subject_name" {
  type    = string
  default = "Cloud Computing"
}
```

### Task 3.5: Update `terraform/lab-03-s3-static-website/provider.tf`

(Add `random` provider as the existing file does. Replace contents with parameterized version.)

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner   = var.display_name
      Project = "FWU-CloudComputing-Lab"
      Lab     = var.lab_name
    }
  }
}
```

### Task 3.6: Update `terraform/lab-03-s3-static-website/main.tf`

- [ ] **Step 1: Replace contents**

```hcl
resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = "${var.suffix}-static-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = { Name = "${var.suffix}-static-site" }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
  error_document { key    = "error.html" }
}

resource "aws_s3_bucket_policy" "site" {
  depends_on = [aws_s3_bucket_public_access_block.site]
  bucket     = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
    }]
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  content      = templatefile("${path.module}/web/index.html.tpl", {
    full_name    = var.full_name
    roll_number  = var.roll_number
    institution  = var.institution
    faculty      = var.faculty
    region       = var.region
  })
  content_type = "text/html"
  etag         = md5(templatefile("${path.module}/web/index.html.tpl", {
    full_name    = var.full_name
    roll_number  = var.roll_number
    institution  = var.institution
    faculty      = var.faculty
    region       = var.region
  }))
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  content      = templatefile("${path.module}/web/error.html.tpl", {
    full_name    = var.full_name
    subject_name = var.subject_name
  })
  content_type = "text/html"
  etag         = md5(templatefile("${path.module}/web/error.html.tpl", {
    full_name    = var.full_name
    subject_name = var.subject_name
  }))
}
```

(Switched from `source = ...` to `content = templatefile(...)` because the file Terraform uploads must be the *rendered* content, not the template literal.)

### Task 3.7: outputs.tf — no change needed (no `mukesh` references)

### Task 3.8: Validate + commit

```bash
cd terraform/lab-03-s3-static-website
terraform init -upgrade
terraform validate
```
Expected: `Success!`

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-03-s3-static-website/
git commit -m "refactor(lab-03): parameterize + template HTML via templatefile()"
```

---

## Phase 4 — Refactor Lab 4 (VPC networking)

No HTML/scripts to template — just `.tf` files.

### Task 4.1: Update `terraform/lab-04-vpc-networking/variables.tf`

```hcl
variable "lab_name"     { type = string  default = "lab-04-vpc-networking" }
variable "suffix"       { type = string  default = "mukesh" }
variable "display_name" { type = string  default = "Mukesh" }
variable "region"       { type = string  default = "ap-south-1" }
```

### Task 4.2: Update `provider.tf`

Same parameterized pattern as Task 1.2.

### Task 4.3: Update `main.tf`

- [ ] **Step 1: Find and replace** all hardcoded `mukesh` references in the existing `main.tf`. The pattern:
  - `vpc-mukesh-net` → `vpc-${var.suffix}-net`
  - `igw-mukesh` → `igw-${var.suffix}`
  - `subnet-mukesh-public` → `subnet-${var.suffix}-public`
  - `subnet-mukesh-private` → `subnet-${var.suffix}-private`
  - `rt-mukesh-public` → `rt-${var.suffix}-public`
  - `rt-mukesh-private` → `rt-${var.suffix}-private`
  - `mukesh-web-sg` → `${var.suffix}-web-sg`
  - `mukesh-db-sg` → `${var.suffix}-db-sg`

Resource labels (`aws_vpc.net`, etc.) stay as-is — they are graph-internal names.

### Task 4.4: Validate + commit

```bash
cd terraform/lab-04-vpc-networking && terraform init -upgrade && terraform validate
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-04-vpc-networking/
git commit -m "refactor(lab-04): parameterize VPC networking resources"
```

---

## Phase 5 — Refactor Lab 5 (ALB + ASG)

### Task 5.1: Rename `user_data.sh` → `user_data.sh.tpl`

```bash
cd terraform/lab-05-alb-asg
git mv user_data.sh user_data.sh.tpl
```

### Task 5.2: Replace `user_data.sh.tpl` content

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable --now httpd

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /var/www/html/index.html <<HTML
<!doctype html>
<html>
<head>
  <title>${display_name} ALB Demo</title>
  <style>
    body { font-family: system-ui; text-align: center; padding-top: 80px; background: #232f3e; color: white; }
    h1 { color: #ff9900; }
    .info { font-family: monospace; background: rgba(255,255,255,0.1); padding: 16px; display: inline-block; border-radius: 6px; margin-top: 12px; }
  </style>
</head>
<body>
  <h1>${display_name} ALB Demo &mdash; Lab 5</h1>
  <p>FWU Cloud Computing &middot; Roll No. ${roll_number}</p>
  <div class="info">
    <p>Served by instance: <strong>$INSTANCE_ID</strong></p>
    <p>Availability Zone: <strong>$AZ</strong></p>
  </div>
  <p style="margin-top:24px;">Refresh the page to see load balancing across the ASG.</p>
</body>
</html>
HTML
```

(Note the heredoc here uses `<<HTML` (unquoted) — Mukesh's original script relied on this so the EC2 instance can substitute `$INSTANCE_ID` and `$AZ` at boot. The Terraform `${display_name}` and `${roll_number}` are interpolated at apply time, while the bash `$INSTANCE_ID` and `$AZ` are interpolated at boot. Terraform's `templatefile()` only substitutes the `${...}` form for keys passed in the variables map; bash variables passing through must NOT be in that map.)

### Task 5.3: Update `variables.tf`

```hcl
variable "lab_name"     { type = string  default = "lab-05-alb-asg" }
variable "suffix"       { type = string  default = "mukesh" }
variable "display_name" { type = string  default = "Mukesh" }
variable "roll_number"  { type = string  default = "29" }
variable "region"       { type = string  default = "ap-south-1" }
```

### Task 5.4: Update `provider.tf`

Same parameterized pattern.

### Task 5.5: Update `main.tf`

- [ ] **Step 1: Replace `${path.module}/user_data.sh` → `${path.module}/user_data.sh.tpl`** in the launch template `user_data` argument and wrap with `templatefile()`:

```hcl
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    display_name = var.display_name
    roll_number  = var.roll_number
  }))
```

- [ ] **Step 2: Replace all `mukesh` literals in resource Name tags and references**:

  - `vpc-mukesh-alb` → `vpc-${var.suffix}-alb`
  - `igw-mukesh-alb` → `igw-${var.suffix}-alb`
  - `subnet-mukesh-alb-a/b` → `subnet-${var.suffix}-alb-a/b`
  - `rt-mukesh-alb-public` → `rt-${var.suffix}-alb-public`
  - `mukesh-alb-web-sg` (the SG name) → `${var.suffix}-alb-web-sg`
  - `lt-mukesh-` (launch template name_prefix) → `lt-${var.suffix}-`
  - `ec2-mukesh-asg` (instance Name tag) → `ec2-${var.suffix}-asg`
  - `alb-mukesh` → `alb-${var.suffix}`
  - `tg-mukesh` (TG name, max 32 chars) → `tg-${var.suffix}` (validate: combined length must stay ≤ 32 — for suffix `mukesh` that's 9 chars, fine; for suffix `verylongnameuser` it would overflow. Suffix max length is already capped at 31 in the loader regex, but a TG-name overflow would manifest at apply time. Acceptable failure mode for v1.)
  - `asg-mukesh` → `asg-${var.suffix}`

### Task 5.6: Validate + commit

```bash
cd terraform/lab-05-alb-asg && terraform init -upgrade && terraform validate
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-05-alb-asg/
git commit -m "refactor(lab-05): parameterize ALB/ASG resources and user_data template"
```

---

## Phase 6 — Refactor Lab 6 (IAM)

### Task 6.1: Update `variables.tf`

```hcl
variable "lab_name"     { type = string  default = "lab-06-iam" }
variable "suffix"       { type = string  default = "mukesh" }
variable "display_name" { type = string  default = "Mukesh" }
variable "region"       { type = string  default = "ap-south-1" }
```

### Task 6.2: Update `provider.tf`

Same parameterized pattern.

### Task 6.3: Update `main.tf`

- [ ] **Step 1: Replace `mukesh` literals**:
  - Group `Developers-mukesh` → `Developers-${var.suffix}`
  - User `mukesh-dev` → `${var.suffix}-dev`
  - User `mukesh-readonly` → `${var.suffix}-readonly`

  (Resource labels `aws_iam_user.dev`, `aws_iam_user.readonly`, `aws_iam_group.developers` stay as-is.)

  Tags: change `Owner = "Mukesh"` → `Owner = var.display_name`.

### Task 6.4: Validate + commit

```bash
cd terraform/lab-06-iam && terraform init -upgrade && terraform validate
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-06-iam/
git commit -m "refactor(lab-06): parameterize IAM resource names"
```

---

## Phase 7 — Refactor Lab 7 (Lambda + Fargate + DynamoDB)

### Task 7.1: Update `lambda/handler.py` to read env var

- [ ] **Step 1: Replace contents**

```python
"""Lab 7 - Visitor logger Lambda function.

On each invocation, writes a record to the DynamoDB table named in the
TABLE_NAME env var, attributing the entry to OWNER_NAME.
"""
import json
import os
import time
import uuid

import boto3

ddb = boto3.client("dynamodb")
TABLE = os.environ["TABLE_NAME"]
OWNER = os.environ.get("OWNER_NAME", "Unknown")


def handler(event, context):
    item_id = str(uuid.uuid4())
    now = int(time.time())

    ddb.put_item(
        TableName=TABLE,
        Item={
            "id":        {"S": item_id},
            "timestamp": {"N": str(now)},
            "name":      {"S": OWNER},
            "source":    {"S": f"lambda-{OWNER.lower()}-visitor-logger"},
            "lab":       {"S": "FWU Cloud Computing Lab 7"},
        },
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message":   "Visitor entry recorded",
            "id":        item_id,
            "timestamp": now,
            "wrote_to":  TABLE,
            "owner":     OWNER,
        }),
    }
```

### Task 7.2: Update `variables.tf`

```hcl
variable "lab_name"     { type = string  default = "lab-07-lambda-fargate-dynamodb" }
variable "suffix"       { type = string  default = "mukesh" }
variable "display_name" { type = string  default = "Mukesh" }
variable "region"       { type = string  default = "ap-south-1" }
```

### Task 7.3: Update `provider.tf`

Same parameterized pattern.

### Task 7.4: Update `main.tf`

- [ ] **Step 1: Replace `mukesh` literals + add `OWNER_NAME` env var to Lambda function**:

  Replace:
  - `visitors-mukesh` → `visitors-${var.suffix}`
  - `lambda-mukesh-visitor-logger` → `lambda-${var.suffix}-visitor-logger`
  - `role-mukesh-lambda` → `role-${var.suffix}-lambda`
  - `ddb-write-mukesh` → `ddb-write-${var.suffix}`
  - `fargate-mukesh-cluster` → `fargate-${var.suffix}-cluster`
  - `role-mukesh-ecs-task-execution` → `role-${var.suffix}-ecs-task-execution`
  - `nginx-mukesh` → `nginx-${var.suffix}`
  - `/aws/lambda/${aws_lambda_function.logger.function_name}` — leaves alone (already references the function name, which is now parameterized).
  - `/ecs/nginx-mukesh` → `/ecs/nginx-${var.suffix}`

  In `aws_lambda_function "logger"` block, update the `environment.variables` to:

  ```hcl
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitors.name
      OWNER_NAME = var.display_name
    }
  }
  ```

  In the ECS log configuration's `awslogs-region`, replace the hardcoded `"ap-south-1"` with `var.region`.

### Task 7.5: Validate + commit

```bash
cd terraform/lab-07-lambda-fargate-dynamodb && terraform init -upgrade && terraform validate
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-07-lambda-fargate-dynamodb/
git commit -m "refactor(lab-07): parameterize Lambda/Fargate/DynamoDB; Lambda reads OWNER_NAME env var"
```

---

## Phase 8 — Refactor Lab 8 (SNS + SQS)

### Task 8.1: Update `variables.tf`

```hcl
variable "lab_name"     { type = string  default = "lab-08-sns-sqs" }
variable "suffix"       { type = string  default = "mukesh" }
variable "display_name" { type = string  default = "Mukesh" }
variable "region"       { type = string  default = "ap-south-1" }

variable "subscriber_email" {
  type        = string
  description = "Email address that will receive SNS notifications. Provide via -var on the CLI."
}
```

### Task 8.2: Update `provider.tf`

Same parameterized pattern.

### Task 8.3: Update `main.tf`

- [ ] **Step 1: Replace `mukesh` literals**:
  - `sns-mukesh-notifications` → `sns-${var.suffix}-notifications`
  - `sqs-mukesh-orders` → `sqs-${var.suffix}-orders`

  Tag `Name` values updated correspondingly.

### Task 8.4: Validate + commit

(For validate to succeed without prompting for `subscriber_email`, pass `-var` or use a placeholder during validate-only.)

```bash
cd terraform/lab-08-sns-sqs && terraform init -upgrade && terraform validate -var "subscriber_email=stub@example.com"
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-08-sns-sqs/
git commit -m "refactor(lab-08): parameterize SNS topic and SQS queue names"
```

---

## Phase 9 — Refactor Lab 9 (CloudFormation)

### Task 9.1: Rename + update CloudFormation template

```bash
cd terraform/lab-09-cloudformation
git mv stack-mukesh.yaml stack.yaml
```

### Task 9.2: Replace `stack.yaml` content

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: >
  FWU Lab 9 - Infrastructure as Code via AWS CloudFormation.
  Provisions a small representative stack (VPC + S3 bucket) to demonstrate
  declarative infrastructure provisioning with a YAML template.

Parameters:
  OwnerName:
    Type: String
    Default: Mukesh
    Description: Owner tag value applied to all resources

  VpcCidr:
    Type: String
    Default: 10.50.0.0/16
    Description: CIDR block for the CloudFormation-managed VPC

Resources:
  CfnVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub "vpc-${OwnerName}-cfn"
        - Key: Owner
          Value: !Ref OwnerName
        - Key: Project
          Value: FWU-CloudComputing-Lab
        - Key: Lab
          Value: lab-09-cloudformation

  CfnBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "${OwnerName}-cfn-${AWS::AccountId}"
      Tags:
        - Key: Name
          Value: !Sub "${OwnerName}-cfn-bucket"
        - Key: Owner
          Value: !Ref OwnerName
        - Key: Project
          Value: FWU-CloudComputing-Lab
        - Key: Lab
          Value: lab-09-cloudformation

Outputs:
  VpcId:
    Value: !Ref CfnVpc
    Description: ID of the VPC created by CloudFormation

  VpcCidrOutput:
    Value: !GetAtt CfnVpc.CidrBlock
    Description: CIDR block of the VPC

  BucketName:
    Value: !Ref CfnBucket
    Description: Name of the S3 bucket created by CloudFormation

  BucketArn:
    Value: !GetAtt CfnBucket.Arn
    Description: ARN of the S3 bucket
```

(Bucket `BucketName` previously hardcoded `mukesh-cfn-${AWS::AccountId}`; now derived from the `OwnerName` parameter via `!Sub`. Also note the bucket name will be lowercased automatically by S3, but the YAML still uses `${OwnerName}` literally — for `Mukesh` this becomes `mukesh-cfn-...` because S3 forces lowercase. For arbitrary display names with capitals, the YAML reference resolves at deploy time and S3 lowercases.

⚠️ **Edge case**: `OwnerName` may contain capitals (e.g. `Jane`) — S3 bucket names must be lowercase. To be robust, the personalize.py rewrite uses `student.suffix` (lowercase by validation) for the CFN default, NOT `display_name`. Update Task 0.5 logic accordingly: use `student.suffix` for the CFN OwnerName parameter, since that's the lowercased identifier. Update the CloudFormation Outputs/tags to use `OwnerName` directly — since that's just a tag, capitals are fine in tags.)

- [ ] **Step 2: Update `personalize.py` `update_cfn_default()` function** to use `s["suffix"]` instead of `s["display_name"]`:

```python
def update_cfn_default(cfg_dict: dict) -> None:
    if not CFN_TEMPLATE.exists():
        print(f"  skipped {CFN_TEMPLATE.name} (not yet created)")
        return
    text = CFN_TEMPLATE.read_text(encoding="utf-8")
    new_default = cfg_dict["student"]["suffix"]   # CHANGED: was display_name
    pattern = re.compile(
        r"(OwnerName:\s*\n(?:[ \t]+[^\n]+\n)*?[ \t]+Default:\s*)([^\n]+)",
        re.MULTILINE,
    )
    new_text, n = pattern.subn(rf"\g<1>{new_default}", text, count=1)
    if n != 1:
        raise SystemExit(
            f"Could not update {CFN_TEMPLATE.name}: OwnerName Default line not found."
        )
    CFN_TEMPLATE.write_text(new_text, encoding="utf-8")
    print(f"  updated {CFN_TEMPLATE.relative_to(ROOT)} (OwnerName default = {new_default})")
```

(Edit Task 0.5's `personalize.py` accordingly when implementing — don't write `display_name` and then come back to fix it. Task 0.5 step 2 already uses `display_name`; correct it to `suffix` during implementation since this Phase 9 issue is a known follow-up.)

### Task 9.3: Update `README-screenshots.md` for Lab 9

Update references to `stack-mukesh.yaml` → `stack.yaml`. Update the bucket name example from `s3-mukesh-cfn-...` to `${suffix}-cfn-...` (or `mukesh-cfn-...` since the default is mukesh).

### Task 9.4: Validate + commit

```bash
cd terraform/lab-09-cloudformation
aws cloudformation validate-template --template-body file://stack.yaml --region ap-south-1
```

Expected: JSON output describing the template's parameters/capabilities. Failure means the YAML is malformed.

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
git add terraform/lab-09-cloudformation/
git commit -m "refactor(lab-09): rename stack.yaml; parameterize via OwnerName"
```

---

## Phase 10 — Refactor `scripts/build_report.py`

### Task 10.1: Restructure to be config-driven

This is the largest single file change. Goals:

- Read `config.yaml` at top of `main()`.
- Convert each `LAB_*` dict literal into a function `lab_N(cfg)` returning the dict.
- All hardcoded `mukesh` / `Mukesh` / `Mukesh Pant` / `29` / `VIII` / `Er. Robinson Pujara` / `vpc-mukesh` etc. become f-string substitutions.
- Cover page reads from `cfg.student`, `cfg.institution`, `cfg.subject`, `cfg.professor`.
- Output filename is dynamic: `report/{full_name with spaces→underscores}_Cloud_Computing_Lab_Report.docx`.

**Files:** Modify `scripts/build_report.py`

- [ ] **Step 1: Add config import at top** (after existing imports):

```python
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib.config import load
```

- [ ] **Step 2: Replace OUT constant with a function**:

```python
def output_path(cfg) -> Path:
    fname = cfg.student.full_name.replace(" ", "_") + "_Cloud_Computing_Lab_Report.docx"
    return ROOT / "report" / fname
```

- [ ] **Step 3: Replace `add_cover_page(doc)` with `add_cover_page(doc, cfg)`** that reads from cfg:

```python
def add_cover_page(doc, cfg):
    for _ in range(2):
        doc.add_paragraph()

    _cover_centered(doc, cfg.institution.university.upper(),
                    bold=True, size=SIZE_COVER_TITLE, color=COLOR_PRIMARY,
                    space_after=8)
    _cover_centered(doc, cfg.institution.faculty, bold=True, size=18, color=COLOR_SECONDARY)
    p_school = _cover_centered(doc, cfg.institution.school, italic=True, size=14, color=COLOR_GREY)
    _add_horizontal_rule(p_school, color=COLOR_PRIMARY, size=12)

    for _ in range(3):
        doc.add_paragraph()

    _cover_centered(doc, "A LAB REPORT", italic=True, size=14, color=COLOR_GREY,
                    space_after=4)
    _cover_centered(doc, "ON", italic=True, size=12, color=COLOR_GREY,
                    space_after=4)
    p_title = _cover_centered(doc, cfg.subject.name.upper(), bold=True,
                              size=SIZE_COVER_BIG, color=COLOR_PRIMARY,
                              space_after=2)
    _cover_centered(doc, "(Practical)", italic=True, size=14, color=COLOR_SECONDARY,
                    space_after=4)
    _add_horizontal_rule(p_title, color=COLOR_PRIMARY, size=8)

    for _ in range(3):
        doc.add_paragraph()

    _cover_centered(doc, "Submitted by:", italic=True, size=12, color=COLOR_GREY,
                    space_after=4)
    _cover_centered(doc, cfg.student.full_name, bold=True, size=SIZE_COVER_NAME,
                    color=COLOR_PRIMARY, space_after=2)
    _cover_centered(doc, f"Roll No. {cfg.student.roll_number}", bold=True, size=14,
                    color=COLOR_SECONDARY, space_after=2)
    _cover_centered(doc, f"{cfg.student.semester} Semester  |  {cfg.student.program}",
                    size=12, color=COLOR_GREY, space_after=4)

    for _ in range(2):
        doc.add_paragraph()

    _cover_centered(doc, "Submitted to:", italic=True, size=12, color=COLOR_GREY,
                    space_after=4)
    _cover_centered(doc, cfg.professor.name, bold=True, size=14,
                    color=COLOR_PRIMARY, space_after=2)
    _cover_centered(doc, cfg.professor.title,
                    size=12, color=COLOR_GREY, space_after=4)

    for _ in range(3):
        doc.add_paragraph()

    _cover_centered(doc, "Signature:  ____________________",
                    size=12, color=COLOR_GREY, space_after=2)

    doc.add_page_break()
```

- [ ] **Step 4: Update header text** in `configure_sections()` to read from cfg:

```python
hr = h_para.add_run(f"{cfg.subject.name} Lab Report  |  {cfg.student.full_name}  |  Roll No. {cfg.student.roll_number}")
```

(Pass `cfg` into `configure_sections` — change signature.)

- [ ] **Step 5: Convert each `LAB_N` dict to a function `def lab_N(cfg) -> dict:`**.

For example, Lab 1:

```python
def lab_1(cfg):
    s = cfg.student
    aws = cfg.aws
    return {
        "title": "Virtual Cloud Environment (VPC)",
        "objective": (
            f"Create and configure a Virtual Private Cloud (VPC) on AWS in the "
            f"{aws.region_label.split(' (')[1][:-1] if '(' in aws.region_label else aws.region_label} "
            f"region. The VPC acts as the base private network within which other "
            f"lab resources can later be launched in isolation from the rest of the "
            f"internet."
        ),
        "services": ["Amazon VPC", "AWS Management Console"],
        "procedure": [
            ("Step 1: Sign in and select region", [
                "Open https://console.aws.amazon.com and sign in with the IAM user.",
                f"From the top-right region dropdown, select {aws.region_label} - {aws.region}.",
            ]),
            ("Step 2: Open the VPC service", [
                "Search for 'VPC' in the search bar and open the VPC dashboard.",
                "From the left navigation, click on Your VPCs.",
                "Click on the Create VPC button.",
            ]),
            ("Step 3: Configure the VPC", [
                "Select 'VPC only' as the resource to create.",
                f"Set Name tag to vpc-{s.suffix}.",
                "Set IPv4 CIDR block to 10.20.0.0/16.",
                "Leave IPv6 CIDR block as 'No IPv6 CIDR block' and Tenancy as Default.",
                "Click Create VPC.",
            ]),
            ("Step 4: Verify creation", [
                "Confirm the success banner appears with the new VPC ID.",
                "Verify that the State is Available and DNS resolution is Enabled.",
                "Note down the VPC ID for reference.",
            ]),
        ],
        "screenshots": [
            ("lab-01/1.1-vpc-list.png",
             f"Figure 1.1 — VPC vpc-{s.suffix} listed in the {aws.region_label.split(' (')[1][:-1] if '(' in aws.region_label else aws.region_label} region with State = Available."),
            ("lab-01/1.2-vpc-details.png",
             "Figure 1.2 — Details panel showing CIDR 10.20.0.0/16 and DNS settings enabled."),
        ],
        "observations": (
            f"The VPC vpc-{s.suffix} was created successfully in the {aws.region} region with "
            "the IPv4 CIDR block 10.20.0.0/16. DNS resolution and DNS hostnames were "
            "enabled by default. The VPC entered the Available state immediately after "
            "creation, confirming that the base network for the remaining labs has been "
            "set up correctly."
        ),
    }
```

Repeat for `lab_2(cfg)` through `lab_9(cfg)`. All `mukesh` text becomes `{s.suffix}`. All `Mukesh` becomes `{s.display_name}`. All `Mukesh Pant` becomes `{s.full_name}`. All `Roll No. 29` becomes `f"Roll No. {s.roll_number}"`. Resource references like `lambda-mukesh-visitor-logger` become `f"lambda-{s.suffix}-visitor-logger"`. Region literals `ap-south-1` become `{aws.region}`. (Concrete substitution table in the implementer's notes — execute carefully one lab at a time.)

- [ ] **Step 6: Update `LABS` to call the functions**:

```python
def get_labs(cfg):
    return [lab_1(cfg), lab_2(cfg), lab_3(cfg), lab_4(cfg),
            lab_5(cfg), lab_6(cfg), lab_7(cfg), lab_8(cfg), lab_9(cfg)]
```

- [ ] **Step 7: Update `build()`**:

```python
def build():
    cfg = load()
    doc = Document()

    configure_default_styles(doc)
    configure_sections(doc, cfg)

    add_cover_page(doc, cfg)
    add_toc(doc, get_labs(cfg))

    for i, lab in enumerate(get_labs(cfg), 1):
        add_lab(doc, i, lab, is_first=(i == 1))

    out = output_path(cfg)
    out.parent.mkdir(parents=True, exist_ok=True)
    doc.save(out)
    print(f"Wrote {out}")
```

### Task 10.2: Generate report and visually verify

- [ ] **Step 1: Generate**

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
python scripts/build_report.py
```

Expected: prints `Wrote .../Mukesh_Pant_Cloud_Computing_Lab_Report.docx`.

- [ ] **Step 2: Open the new file in Word and compare side-by-side with the previously committed version** (`git stash` the working changes if needed to view both, or open the previous version via `git show HEAD~N:report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx > /tmp/old.docx`).

  Verify pages render visually identically. Common issues to look for:
  - Cover page text exactly matches (university name, full name, roll, semester, program, professor name + title).
  - Figure captions reference `vpc-mukesh`, `ec2-mukesh`, etc.
  - Procedure steps say "Set Name tag to vpc-mukesh" not "vpc-{suffix}".
  - Observations mention `mukesh-dev`, etc. correctly.

- [ ] **Step 3: If diffs exist, edit the offending lab function in `build_report.py` and regenerate. Repeat until visually identical.**

### Task 10.3: Commit Phase 10

```bash
git add scripts/build_report.py report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx
git commit -m "refactor(report): make report builder config-driven"
```

---

## Phase 11 — README update

### Task 11.1: Add "Personalize this template" section

- [ ] **Step 1: Insert section after "Reproducing a workload" and before "Rebuilding the lab report"**:

```markdown
---

## Personalize this template

The repo is published as a personalizable template. To produce a lab
project under your own name with your own resource suffix:

### Option 1 — Interactive wizard

```bash
python scripts/personalize.py
```

Prompts walk you through every value (suffix, name, roll, semester,
program, university, professor, AWS region). Press Enter to keep each
default. The wizard then propagates values into Terraform's
`terraform.auto.tfvars.json` per lab and rewrites Lab 9's CloudFormation
default parameter.

### Option 2 — Edit `config.yaml` directly

Open `config.yaml` at the repo root, change values, save, then propagate
in one command:

```bash
python scripts/personalize.py --apply --no-prompt
```

### After personalizing

- `terraform apply -auto-approve` in any lab folder uses YOUR values.
- `python scripts/build_report.py` produces
  `report/<Your_Name>_Cloud_Computing_Lab_Report.docx`.
- The screenshots under `screenshots/` are still Mukesh's; capture your
  own per each lab's `README-screenshots.md` and overwrite them.

The committed `config.yaml` defaults to Mukesh's values, so cloning and
running anything WITHOUT personalizing reproduces Mukesh's exact output.
```

### Task 11.2: Commit

```bash
git add README.md
git commit -m "docs(readme): add personalize-this-template section"
```

---

## Phase 12 — Smoke-test with a fictional Jane Doe

This phase verifies the template ACTUALLY works end-to-end for a different identity.

### Task 12.1: Run wizard with Jane Doe values

```bash
python scripts/personalize.py \
  --suffix jane \
  --display-name "Jane" \
  --full-name "Jane Doe" \
  --roll 5 \
  --semester VII \
  --professor "Dr. Alice Smith" \
  --apply --no-prompt
```

Expected: writes config.yaml + 8 tfvars files + updates stack.yaml.

### Task 12.2: Verify Terraform plan shows Jane-named resources

```bash
cd terraform/lab-01-vpc
terraform plan -no-color | grep -E "Name.*=.*\"vpc-"
```

Expected: a line like `Name = "vpc-jane"`.

### Task 12.3: Build Jane's report

```bash
cd "c:/Users/MUKESH/Desktop/Claude Computing Practical"
python scripts/build_report.py
```

Expected: prints `Wrote .../Jane_Doe_Cloud_Computing_Lab_Report.docx`.

Open it in Word — cover page should say *Jane Doe*, *Roll No. 5*, *VII Semester*, *Dr. Alice Smith*. Figure captions reference `vpc-jane` etc.

### Task 12.4: Restore Mukesh's values and verify report regenerates identically

```bash
python scripts/personalize.py \
  --suffix mukesh \
  --display-name "Mukesh" \
  --full-name "Mukesh Pant" \
  --roll 29 \
  --semester VIII \
  --professor "Er. Robinson Pujara" \
  --apply --no-prompt

python scripts/build_report.py
```

Open the regenerated `Mukesh_Pant_Cloud_Computing_Lab_Report.docx` and compare to the committed version. Should match.

### Task 12.5: Delete Jane's test artifact

```bash
rm "report/Jane_Doe_Cloud_Computing_Lab_Report.docx"
```

(Don't commit it; it was only for smoke-testing.)

### Task 12.6: Commit final state

```bash
git add config.yaml terraform/lab-*/terraform.auto.tfvars.json terraform/lab-09-cloudformation/stack.yaml report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx
git commit -m "chore: restore Mukesh defaults after template smoke-test"
```

(May produce empty commit if nothing actually changed in restoration — in which case skip this commit.)

---

## Phase 13 — Push to GitHub

### Task 13.1: Push all template-feature commits

```bash
git push origin main
```

Expected: pushes ~15+ commits (Phases 0–12) to the public repo.

### Task 13.2: Verify on GitHub

Open `https://github.com/Mukesh-Pant/cloud-computing-fwu-labs` in a browser:

- Repo root shows `config.yaml`, `config.example.yaml`, `requirements.txt`.
- README's new "Personalize this template" section renders.
- `scripts/personalize.py` and `scripts/lib/config.py` visible.
- Each lab folder has `terraform.auto.tfvars.json`.
- `terraform/lab-09-cloudformation/stack.yaml` (renamed from `stack-mukesh.yaml`).

---

## Self-Review

**Spec coverage:**
- §3 Personalizable fields → Task 0.2 (config.yaml schema) ✓
- §4 Two entry points (edit YAML / wizard) → Task 0.5 + Task 11.1 ✓
- §5.1 Terraform var propagation → Phases 1, 2, 4, 5, 6, 7, 8 ✓
- §5.2 templatefile() for HTML/scripts → Tasks 2.1, 3.1, 5.1 ✓
- §5.3 Lambda env var → Task 7.1, 7.4 ✓
- §5.4 CloudFormation rewrite → Task 0.5 + Phase 9 (with Phase 9's own correction note about using suffix not display_name) ✓
- §5.5 Report builder config-driven → Phase 10 ✓
- §6.1 New files → Phase 0 ✓
- §6.2 Modified files → Phases 1–10 ✓
- §6.3 Files NOT changed → respected (LICENSE, screenshots, old report committed copy) ✓
- §7 Default-output verification → Task 10.2, Phase 12 ✓
- §9 Risks R1–R7 → R1 (validate per lab) addressed in every Phase's task. R2 (visual diff) Task 10.2. R3 (wizard prompts) — wizard does prompt by default. R4 (regex YAML rewrite) Task 0.5. R5 (suffix regex) `lib/config.py` SUFFIX_PATTERN. R6 (state conflict on rename) — documented in Task 1.5 step 2 note. R7 (Lambda backwards-incompat) — accepted refactor cost ✓
- §11 Definition of done → all checks covered across Phases 10–12 ✓

**Placeholder scan:** No "TBD"/"TODO" in plan. Lab 4, 6, 8 phases use prose summaries ("replace all `mukesh` literals") rather than full code blocks because the substitutions are mechanical and listing every line in plan would be repetition. The substitution rules are explicit. Acceptable.

**Type/name consistency:**
- Variable names `suffix`, `display_name`, `full_name`, `region` consistent across labs ✓
- `terraform.auto.tfvars.json` filename consistent (Phase 0, 12, 13) ✓
- `lib.config.load()` signature consistent with usage in Tasks 0.5, 10.1 ✓
- Phase 9 corrects Phase 0.5's CFN logic to use `suffix` not `display_name` — documented inline so implementer applies the fix from Phase 0 Step 2 onward.
