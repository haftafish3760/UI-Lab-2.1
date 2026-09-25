import copy
from pathlib import Path
import tempfile
import unittest

from tool.catalog_engine.generate import build
from tool.catalog_engine.manifest import describe, verify

ROOT = Path(__file__).resolve().parents[1]


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.artifact = self.root / "pack.sqlite"
        build(ROOT / "definitions/families.json", ROOT / "fixtures/candidates.json", self.artifact)
        self.manifest = describe(self.artifact)

    def test_valid_integrity_is_not_publisher_authentication(self):
        result = verify(self.root, self.manifest)
        self.assertTrue(result["integrity_verified"])
        self.assertFalse(result["publisher_authenticated"])
        self.assertFalse(result["release_ready"])

    def test_corrupted_and_truncated_bytes_fail_before_trust(self):
        data = self.artifact.read_bytes()
        self.artifact.write_bytes(data[:-1])
        with self.assertRaisesRegex(ValueError, "length"):
            verify(self.root, self.manifest)
        modified = bytearray(data)
        modified[-1] ^= 1
        self.artifact.write_bytes(modified)
        with self.assertRaisesRegex(ValueError, "hash"):
            verify(self.root, self.manifest)

    def test_path_escape_and_unknown_manifest_fields_rejected(self):
        for name in ["../pack.sqlite", "C:/pack.sqlite", "\\\\server\\pack.sqlite", "sub/pack.sqlite", "pack.sqlite:stream"]:
            manifest = copy.deepcopy(self.manifest)
            manifest["artifact"] = name
            with self.assertRaises(ValueError):
                verify(self.root, manifest)
        self.manifest["release_approved"] = True
        with self.assertRaises(ValueError):
            verify(self.root, self.manifest)

    def test_forged_counts_schema_and_publication_state_rejected(self):
        for key, value in [("counts", {"items": 999}), ("schema_version", 999),
                           ("publication_state", "approved"), ("sources", [])]:
            manifest = copy.deepcopy(self.manifest)
            manifest[key] = value
            with self.assertRaises(ValueError):
                verify(self.root, manifest)

    def test_manifest_description_is_deterministic_and_read_only(self):
        before = self.artifact.read_bytes()
        self.assertEqual(self.manifest, describe(self.artifact))
        self.assertEqual(before, self.artifact.read_bytes())
