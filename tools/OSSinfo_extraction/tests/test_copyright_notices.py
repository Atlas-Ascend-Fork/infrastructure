# Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Verify detected notices survive extraction and Readme.opensource output."""

import tempfile
import unittest
from pathlib import Path

from ossinfo_extraction.parse_and_duplication import extract_and_duplicate_copyright
from ossinfo_extraction.readme_opensource import write_readme_opensource


class CopyrightNoticesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.output = self.root / "copyright.txt"

    def extract(self, files):
        return extract_and_duplicate_copyright({"files": files}, self.output)

    def test_detected_notices_reach_readme_without_keyword(self):
        for notice in (
            "copr. (c) Example Contributors",
            "Example Contributors (c) 2026",
        ):
            with self.subTest(notice=notice):
                records = self.extract(
                    [{"path": "src/example.c", "copyrights": [{"copyright": notice}]}]
                )
                readme = self.root / "Readme.opensource"
                write_readme_opensource(
                    readme, "Example", "1.0", records, [], self.root
                )
                self.assertEqual(records, [notice])
                self.assertEqual(self.output.read_text(encoding="utf-8"), notice + "\n")
                self.assertIn(notice, readme.read_text(encoding="utf-8"))
                self.assertNotIn(
                    "No copyright information found.",
                    readme.read_text(encoding="utf-8"),
                )

    def test_statement_fallback_is_trimmed_and_deduplicated(self):
        notice = "copr. (c) Example Contributors"
        records = self.extract(
            [
                {
                    "path": "NOTICE",
                    "copyrights": [
                        {"statement": "  " + notice + "  "},
                        {"copyright": notice},
                        {"copyright": "Copyright 2026 Other Contributors"},
                    ],
                },
                {"path": "src/example.c", "copyrights": [{"copyright": notice}]},
            ]
        )
        self.assertEqual(records, [notice, "Copyright 2026 Other Contributors"])
        self.assertEqual(
            self.output.read_text(encoding="utf-8"), "\n".join(records) + "\n"
        )

    def test_empty_records_and_ignored_document_suffix_are_excluded(self):
        records = self.extract(
            [
                {
                    "path": "src/example.c",
                    "copyrights": [
                        {"copyright": ""},
                        {"copyright": "  \n "},
                        {},
                    ],
                },
                {
                    "path": "guide.MD",
                    "copyrights": [{"copyright": "Copyright 2026 Documentation"}],
                },
            ]
        )
        self.assertEqual(records, [])
        self.assertEqual(self.output.read_text(encoding="utf-8"), "")

    def test_ordinary_copyright_notice_is_preserved(self):
        notice = "Copyright 2026 Example Contributors"
        records = self.extract(
            [{"path": "src/example.c", "copyrights": [{"copyright": notice}]}]
        )
        self.assertEqual(records, [notice])


if __name__ == "__main__":
    unittest.main()
