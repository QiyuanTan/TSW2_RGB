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
        self.assertEqual(catalog["status"], "validated-for-mvp-envelope")
        for action in catalog["actions"]:
            self.assertEqual(
                set(action),
                {"raw_identifier", "direction", "semantic_action"},
            )

    def test_controlled_fixture_explains_all_three_swaps(self):
        custom = self.load("observed-custom.json")

        self.assertIs(custom["authority_proven_for_tested_profile"], True)
        action_changes = {
            entry["identifier"]: (entry["old"]["key_name"], entry["new"]["key_name"])
            for entry in custom["custom_action_mappings"]
        }
        self.assertEqual(action_changes["KeyboardToggleDoorsLeft"], ("Y", "U"))
        self.assertEqual(action_changes["KeyboardToggleDoorsRight"], ("U", "Y"))

        reverser = custom["custom_vehicle"][0]
        self.assertEqual(reverser["identifier"], "Reverser")
        self.assertEqual(reverser["increase"][0]["key_name"], "S")
        self.assertEqual(reverser["decrease"][0]["key_name"], "W")
        self.assertIs(
            custom["retained_vehicle_mapping_observation"][0]["authoritative"],
            False,
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

    def test_unbound_action_delta_removes_without_adding(self):
        fixture = self.load("observed-unbound.json")
        left = fixture["custom_action_mappings"][1]

        self.assertEqual(left["identifier"], "KeyboardToggleDoorsLeft")
        self.assertEqual(left["old_key_name"], "Y")
        self.assertEqual(left["new_key_name"], "None")
        self.assertEqual(fixture["effective"]["KeyboardToggleDoorsLeft"], [])

    def test_ordered_deltas_allow_persistent_duplicate_keys(self):
        fixture = self.load("observed-duplicate-restart.json")
        mappings = fixture["custom_action_mappings_in_serialized_order"]

        self.assertEqual(len(mappings), 3)
        self.assertEqual(mappings[-1]["old_key_name"], "None")
        effective = fixture["effective_confirmed_in_ui_after_restart"]
        self.assertEqual(effective["KeyboardToggleDoorsLeft"], ["Y"])
        self.assertEqual(effective["KeyboardToggleDoorsRight"], ["Y"])
        self.assertEqual(effective["Reverser.increase"], ["S"])
        self.assertEqual(effective["Reverser.decrease"], ["W"])


if __name__ == "__main__":
    unittest.main()
