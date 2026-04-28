"""Interactive personalization wizard.

Reads/writes `config.yaml` at the repo root, then propagates values into:
  - terraform/lab-NN/terraform.auto.tfvars.json (one per Terraform lab folder)
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
    """Generate terraform.auto.tfvars.json in each Terraform lab folder."""
    s = cfg_dict["student"]
    inst = cfg_dict["institution"]
    subj = cfg_dict["subject"]
    aws = cfg_dict["aws"]
    payload = {
        "suffix":       s["suffix"],
        "display_name": s["display_name"],
        "full_name":    s["full_name"],
        "roll_number":  str(s["roll_number"]),
        "semester":     s["semester"],
        "region":       aws["region"],
        "region_label": aws["region_label"],
        "institution":  inst["university"],
        "faculty":      inst["faculty"],
        "subject_name": subj["name"],
    }
    body = json.dumps(payload, indent=2) + "\n"
    for lab in LAB_DIRS:
        if not lab.exists():
            print(f"  skipped {lab.relative_to(ROOT)} (folder not present)")
            continue
        target = lab / "terraform.auto.tfvars.json"
        target.write_text(body, encoding="utf-8")
        print(f"  wrote {target.relative_to(ROOT)}")


def update_cfn_default(cfg_dict: dict) -> None:
    """Rewrite the Default value of the OwnerName CloudFormation parameter.

    Uses student.suffix (lowercase, S3-bucket-safe) rather than display_name
    because CFN's bucket name is derived from this value.
    """
    if not CFN_TEMPLATE.exists():
        print(f"  skipped {CFN_TEMPLATE.name} (not yet present)")
        return
    text = CFN_TEMPLATE.read_text(encoding="utf-8")
    new_default = cfg_dict["student"]["suffix"]
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
