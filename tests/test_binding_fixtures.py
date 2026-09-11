import json
import pathlib
import unittest


FIXTURES = pathlib.Path(__file__).parent / "fixtures" / "bindings"


class BindingResearchFixtureTests(unittest.TestCase):
    def load(self, name):
        with (FIXTURES / name).open(encoding="utf-8") as stream:
            return json.load(stream)

    def test_captures_are_explicitly_non_authoritative_and_comparable(self):
        backup = self.load("observed-backup.json")
        current = self.load("observed-current.json")

        self.assertEqual(backup["fixture_schema"], 1)
        self.assertEqual(current["fixture_schema"], 1)
        self.assertIs(backup["authority_proven"], False)
        self.assertIs(current["authority_proven"], False)
        self.assertEqual(backup["records"], current["records"])
        self.assertEqual(len(current["records"]), 3)

    def test_action_catalog_has_no_physical_bindings(self):
        catalog = self.load("action-catalog.json")

        self.assertEqual(catalog["catalog_schema"], 1)
        self.assertIn("pending", catalog["status"])
        for action in catalog["actions"]:
            self.assertEqual(
                set(action),
                {"raw_identifier", "direction", "semantic_action"},
            )

    def test_every_observed_required_direction_is_catalogued(self):
        current = self.load("observed-current.json")
        catalog = self.load("action-catalog.json")["actions"]
        catalogued = {
            (entry["raw_identifier"], entry["direction"]) for entry in catalog
        }

        observed = {
            (record["identifier"], direction)
            for record in current["records"]
            for direction in ("increase", "decrease")
            if record[direction]
        }
        self.assertTrue(observed <= catalogued)


if __name__ == "__main__":
    unittest.main()
