import unittest, os, json, sys, tempfile, time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import projects as P

HOME = os.path.expanduser("~")


def mk(root, name, first_record, age=0):
    d = Path(root) / name; d.mkdir()
    f = d / "x.jsonl"; f.write_text(json.dumps(first_record) + "\n")
    t = time.time() - age; os.utime(d, (t, t)); os.utime(f, (t, t))


class Candidates(unittest.TestCase):
    def test_candidates_skip_missing_cwd_and_dead_paths(self):
        with tempfile.TemporaryDirectory() as root:
            mk(root, "-a", {"cwd": "/does/not/exist"}); mk(root, "-b", {}); mk(root, "-c", {"cwd": "/tmp"})
            c = P.candidates([], root, exists=lambda p: p in ("/tmp", HOME))
            self.assertEqual(c, ["/tmp", HOME])

    def test_worktree_collapses_to_repo_root(self):
        c = P.candidates([{"cwd": "/r/acm-frontend/.claude/worktrees/x"}], "/nonexistent", exists=lambda p: True)
        self.assertEqual(c[0], "/r/acm-frontend")

    def test_agents_first_then_dedup_and_cap(self):
        c = P.candidates([{"cwd": "/p1"}, {"cwd": "/p1"}, {"cwd": "/p2"}], "/nonexistent", limit=2, exists=lambda p: True)
        self.assertEqual(c, ["/p1", "/p2"])

    def test_recent_projects_ordered_by_mtime(self):
        with tempfile.TemporaryDirectory() as root:
            mk(root, "-old", {"cwd": "/old"}, age=3600); mk(root, "-new", {"cwd": "/new"}, age=10)
            c = P.candidates([], root, exists=lambda p: True)
            self.assertEqual(c[:2], ["/new", "/old"])

    def test_cwd_found_past_first_record(self):
        with tempfile.TemporaryDirectory() as root:
            d = Path(root) / "-p"; d.mkdir()
            (d / "x.jsonl").write_text(json.dumps({"type": "last-prompt"}) + "\n" + json.dumps({"type": "mode"}) + "\n"
                                       + json.dumps({"type": "attachment", "cwd": "/found"}) + "\n")
            self.assertEqual(P.candidates([], root, exists=lambda p: True)[0], "/found")


class Preselect(unittest.TestCase):
    C = ["/h/work/acm", "/h/DotFiles", "/h"]

    def test_keyword(self): self.assertEqual(P.preselect("fix the ACM login", self.C, None), 0)

    def test_alias(self): self.assertEqual(P.preselect("change my colorscheme in herdr", self.C, None), 1)

    def test_last_then_first(self):
        self.assertEqual(P.preselect("hello", self.C, "/h"), 2); self.assertEqual(P.preselect("hello", self.C, None), 0)


class Slug(unittest.TestCase):
    def test_slug(self):
        self.assertEqual(P.slug("Change my colorscheme to Kanagawa, please"), "change-my-colorscheme-to")
        self.assertEqual(P.slug("  "), "task")


if __name__ == "__main__":
    unittest.main()
