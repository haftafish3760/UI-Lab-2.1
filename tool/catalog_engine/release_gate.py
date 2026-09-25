"""Deterministic evidence gate. Unknown, stale or missing evidence blocks release.

Policy is trusted review-controlled input, not supplied by a downloaded pack.
Evidence authentication belongs to the CI boundary; hashes bind evidence to an
artifact but do not authenticate whoever produced a report.
"""
import re


def evaluate(policy, reports, *, artifact_sha256, source_sha256):
    problems = []

    def reject(rule, subject, detail):
        problems.append({"rule": rule, "subject": subject, "detail": detail})

    if not isinstance(policy, dict) or type(policy.get("version")) is not int or policy["version"] != 1:
        return {"release_ready": False, "problems": [{"rule": "policy.invalid", "subject": "policy", "detail": "Unsupported policy"}], "checks": []}
    if policy.get("review_state") != "approved":
        reject("policy.unreviewed", "policy", "Release policy must have explicit completed review")
    if not isinstance(artifact_sha256, str) or not re.fullmatch(r"[0-9a-f]{64}", artifact_sha256):
        reject("binding.artifact", "artifact", "An exact SHA-256 artifact binding is required")
    if not isinstance(source_sha256, dict) or not source_sha256 or any(
            not isinstance(k, str) or not isinstance(v, str) or not re.fullmatch(r"[0-9a-f]{64}", v)
            for k, v in source_sha256.items()):
        reject("binding.sources", "sources", "An exact nonempty source fingerprint map is required")
    required = policy.get("checks")
    if not isinstance(required, list) or not required:
        reject("policy.empty", "policy", "No release checks declared")
        required = []
    expected = {}
    for check in required:
        if (not isinstance(check, dict) or set(check) != {"id", "requirement_ids", "tier", "subjects"} or
                not isinstance(check.get("id"), str) or not check["id"] or
                not isinstance(check.get("requirement_ids"), list) or not check["requirement_ids"] or
                any(not isinstance(x, str) or not x for x in check["requirement_ids"]) or
                not isinstance(check.get("tier"), str) or check["tier"] not in {"fast", "semantic", "release"} or
                not isinstance(check.get("subjects"), list) or not check["subjects"] or
                any(not isinstance(x, str) or not x for x in check["subjects"])):
            reject("policy.check_invalid", "policy", "Malformed check/requirement/subject declaration")
            continue
        if check["id"] in expected or len(set(check["subjects"])) != len(check["subjects"]):
            reject("policy.duplicate", check["id"], "Duplicate check or subject")
        expected[check["id"]] = check
    received = {}
    if not isinstance(reports, list):
        reject("evidence.invalid", "reports", "Expected report list")
        reports = []
    for report in reports:
        if not isinstance(report, dict) or set(report) != {"check_id", "status", "artifact_sha256", "source_sha256", "subjects", "findings"}:
            reject("evidence.invalid", "report", "Malformed evidence envelope")
            continue
        key = report["check_id"]
        if not isinstance(key, str) or key not in expected:
            reject("evidence.unknown_check", "report", "Unknown evidence check")
            continue
        if key in received:
            reject("evidence.duplicate", key, "Multiple reports cannot overwrite each other")
        received[key] = report
        if report["artifact_sha256"] != artifact_sha256 or report["source_sha256"] != source_sha256:
            reject("evidence.stale", key, "Evidence does not bind to this artifact and current source revisions")
        if report["status"] != "passed":
            reject("evidence.not_passed", key, str(report["status"]))
        subjects = report["subjects"]
        if (not isinstance(subjects, list) or any(not isinstance(s, str) for s in subjects) or
                sorted(subjects) != sorted(expected[key]["subjects"])):
            reject("evidence.coverage", key, "Examined subjects differ from required scope")
        findings = report["findings"]
        if not isinstance(findings, list):
            reject("evidence.findings_invalid", key, "Findings must be explicit")
        else:
            for finding in findings:
                # Reviews require explicit resolution upstream, not a boolean
                # override carried alongside an otherwise unresolved finding.
                if not isinstance(finding, dict) or finding.get("severity") != "warning":
                    reject("evidence.unresolved", key, "Error, review or unknown finding remains")
    checks = []
    for key, check in sorted(expected.items()):
        if key not in received:
            reject("evidence.missing", key, "Mandatory check has not run")
        checks.append({"id": key, "tier": check["tier"], "requirement_ids": check["requirement_ids"],
                       "passed": key in received and not any(p["subject"] == key for p in problems)})
    problems.sort(key=lambda x: (x["rule"], x["subject"], x["detail"]))
    return {"release_ready": bool(expected) and not problems, "problems": problems, "checks": checks}
