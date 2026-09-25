"""Evaluate current artifact against all currently declared mandatory gates.

Only structural evidence is currently produced here. Missing integrations remain
missing reports, not passes or invented evidence. No report authorizes publishing.
"""
import argparse
import hashlib
import json
from pathlib import Path

from .release_gate import evaluate
from .validate import validate

ROOT = Path(__file__).resolve().parent
POLICY = ROOT / "acceptance/release_policy.json"


def assess(path):
    policy = json.loads(POLICY.read_text(encoding="utf-8"))
    sources = {str(p.relative_to(ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest()
               for p in sorted(ROOT.rglob("*")) if p.suffix in {".py", ".json"}}
    artifact = validate(path)
    binding = {"artifact_sha256": artifact["artifact_sha256"], "source_sha256": sources}
    report = {"check_id": "structure", "status": "passed" if artifact["structural_pass"] else "failed",
              **binding, "subjects": ["pack"],
              "findings": [i for i in artifact["issues"] if i["severity"] == "error"]}
    verdict = evaluate(policy, [report], **binding)
    # Retain review findings, although they are not structural errors. They are
    # not silently discarded: the factual evidence gate is separately mandatory.
    return {"gate": verdict, "artifact_validation": artifact, "binding": binding}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = assess(args.artifact)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, indent=2, ensure_ascii=False)
        stream.write("\n")
    print(f"Release ready: {result['gate']['release_ready']}; blockers: {len(result['gate']['problems'])}")
    raise SystemExit(0 if result["gate"]["release_ready"] else 1)
