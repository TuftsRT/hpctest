"""
Offline self-tests for bin/hpctest (no Slurm or module system needed).

    python3 -m unittest discover -s selftest -v
"""

import importlib.machinery
import importlib.util
import os
import shutil
import sys
import tempfile
import textwrap
import types
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
_path = os.path.join(os.path.dirname(HERE), "bin", "hpctest")
_loader = importlib.machinery.SourceFileLoader("hpctest", _path)
h = importlib.util.module_from_spec(importlib.util.spec_from_loader("hpctest", _loader))
_loader.exec_module(h)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(textwrap.dedent(text).lstrip("\n"))


class Sandbox(unittest.TestCase):
    """A throwaway tests/, profiles/ and sites/ tree with a stub module command."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="hpctest-self-")
        self.saved = (h.TESTS_DIR, h.PROFILES_DIR, h.SITES_DIR)
        h.TESTS_DIR = os.path.join(self.tmp, "tests")
        h.PROFILES_DIR = os.path.join(self.tmp, "profiles")
        h.SITES_DIR = os.path.join(self.tmp, "sites")
        write(os.path.join(self.tmp, "modinit.sh"), """
            module() {
              case "$1" in
                load|is-loaded) [ "$2" != broken ] ;;
                *) return 0 ;;
              esac
            }
            """)
        write(os.path.join(h.SITES_DIR, "lab", "site.conf"), """
            [site]
            workdir = %s/runs
            [modules]
            init = %s/modinit.sh
            purge = true
            [slurm]
            max_exclusive_nodes = 2
            [aliases]
            gcc = gcc/12
            nothing =
            [params]
            greeting = site
            undeclared = x
            [params:hello]
            who = site-hello
            [disabled]
            off = no license
            """ % (self.tmp, self.tmp))
        self.site = h.Site("lab")
        # Jobs must use the stub, not a module function inherited from this shell
        # or defined by BASH_ENV (Lmod sites often point it at their init script).
        self.env = {k: os.environ.pop(k) for k in list(os.environ)
                    if k.startswith(("BASH_FUNC_module", "BASH_FUNC_ml")) or k == "BASH_ENV"}

    def tearDown(self):
        os.environ.update(self.env)
        h.TESTS_DIR, h.PROFILES_DIR, h.SITES_DIR = self.saved
        shutil.rmtree(self.tmp, ignore_errors=True)

    def add_test(self, name, test_sh, expected="", build=None):
        d = os.path.join(h.TESTS_DIR, name)
        write(os.path.join(d, "test.sh"), test_sh)
        write(os.path.join(d, "expected.out"), expected)
        if build:
            write(os.path.join(d, "build.sh"), build)


class TestPatterns(unittest.TestCase):

    def match(self, expected, lines):
        return h.match_lines(h.compile_expected(expected), lines)

    def test_literal_and_wildcard(self):
        self.assertTrue(self.match(["host ${*} ok"], ["host n01 ok"])[0])
        self.assertFalse(self.match(["a(b)"], ["ab"])[0])          # regex chars are literal

    def test_capture_numbers(self):
        ok, caps, _ = self.match(["Copy ${copy}", "t=${t}s"], ["Copy 1.5e+05", "t=-3s"])
        self.assertTrue(ok)
        self.assertEqual(caps, {"copy": "1.5e+05", "t": "-3"})

    def test_optional_lines(self):
        exp = ["a", "${?}warning${*}", "b"]
        self.assertTrue(self.match(exp, ["a", "b"])[0])
        self.assertTrue(self.match(exp, ["a", "warning: x", "b"])[0])
        self.assertFalse(self.match(exp, ["a", "other", "b"])[0])

    def test_mismatch_position(self):
        ok, _, where = self.match(["a", "b", "c"], ["a", "b", "x"])
        self.assertFalse(ok)
        self.assertEqual(where, (2, 2))

    def test_trailing_blank_lines_ignored(self):
        self.assertTrue(self.match(["a", ""], h.clean_output(["a", "", "  "]))[0])


class TestHelpers(unittest.TestCase):

    def test_to_minutes(self):
        self.assertEqual([h.to_minutes(x) for x in ("30", "1:30", "2:00:00", "1-2", "")],
                         [30, 2, 120, 1560, None])

    def test_summarize_need(self):
        def job(status):
            return dict(id="t", test="t", status=status, need=2, runs=3, detail=status)
        self.assertEqual(h.summarize([job("PASS"), job("FAIL"), job("PASS")])[0]["status"],
                         "PASS")
        self.assertEqual(h.summarize([job("FAIL"), job("FAIL"), job("PASS")])[0]["status"],
                         "FAIL")
        self.assertEqual(h.summarize([job("PASS"), job("PENDING"), job("FAIL")])[0]["status"],
                         "PENDING")


class TestSite(Sandbox):

    def test_params_precedence(self):
        self.add_test("hello", """
            #@ param greeting = default
            #@ param who = world
            #@ param style = plain
            echo hi
            """)
        t = h.discover(self.site)["hello"]
        p = h.resolve_params(t, self.site, {"style": "profile"}, {"who": "cli"})
        self.assertEqual(p, {"greeting": "site", "who": "cli", "style": "profile"})
        self.assertNotIn("undeclared", p)

    def test_aliases(self):
        self.assertEqual(self.site.resolve_modules(["gcc", "nothing", "fftw"]),
                         ["gcc/12", "fftw"])

    def test_profile_parsing(self):
        write(os.path.join(h.PROFILES_DIR, "base.list"), "a\n")
        write(os.path.join(h.PROFILES_DIR, "p.list"), """
            # comment
            @base
            b x3 need=2 serial as=b:fast mode=fast   # trailing comment
            c -- --constraint=foo --exclude=n1
            """)
        es = h.parse_profile(self.site, "p")
        self.assertEqual([e.id for e in es], ["a", "b:fast", "c"])
        self.assertEqual((es[1].runs, es[1].need, es[1].serial, es[1].params),
                         (3, 2, True, {"mode": "fast"}))
        self.assertEqual(es[2].sbatch, ["--constraint=foo", "--exclude=n1"])

    def test_exclusive_cap(self):
        self.add_test("big", "#@ nodes: 4\n#@ exclusive: yes\n")
        notes = []
        args = h.sbatch_args(h.discover(self.site)["big"], self.site, notes)
        self.assertNotIn("--exclusive", args)
        self.assertTrue(notes)

    def test_update_conf_keeps_comments(self):
        path = os.path.join(self.tmp, "baselines.conf")
        write(path, """
            # header
            [io]
            # noisy file system
            read = 100 -70 300 1   # MB/s

            [other]
            x = 1 -1 1 1
            """)
        h.update_conf(path, {"io": {"read": "120 -70 300 1", "write": "50 -25 50 1"},
                             "new@zen4": {"y": "2 -25 50 1"}}, ["# unused"])
        with open(path) as fh:
            text = fh.read()
        self.assertIn("# noisy file system", text)
        self.assertIn("read = 120 -70 300 1   # MB/s", text)
        self.assertLess(text.index("write = 50"), text.index("[other]"))
        self.assertIn("[new@zen4]\ny = 2 -25 50 1", text)
        cp = h.new_config()
        cp.read(path)
        self.assertEqual(cp.get("other", "x"), "1 -1 1 1")


class TestSubmit(unittest.TestCase):

    def test_allocation_env_not_inherited(self):
        seen = {}

        def fake_run(cmd, **kw):
            seen.update(kw.get("env") or os.environ)
            return types.SimpleNamespace(returncode=0, stdout="42\n", stderr="")

        saved, h.run_cmd = h.run_cmd, fake_run
        old = dict(os.environ)
        os.environ.update(SLURM_MEM_PER_NODE="12288", SLURM_CONF="/etc/slurm/slurm.conf",
                          SBATCH_ACCOUNT="lab")
        try:
            job = dict(id="t", dir="/tmp/t")
            h.submit(job, "/tmp/t/job.sh", [], False)
        finally:
            h.run_cmd = saved
            os.environ.clear()
            os.environ.update(old)
        self.assertEqual(job["jobid"], "42")
        self.assertNotIn("SLURM_MEM_PER_NODE", seen)
        self.assertEqual(seen.get("SLURM_CONF"), "/etc/slurm/slurm.conf")
        self.assertEqual(seen.get("SBATCH_ACCOUNT"), "lab")


class TestBaselines(Sandbox):

    def test_perf_and_pass(self):
        write(os.path.join(h.SITES_DIR, "lab", "baselines.conf"), """
            [bench@zen4]
            bw = 100 -10 10 1
            """)
        job = dict(id="bench", test="bench", arch="zen4", values={"bw": 95.0})
        self.assertEqual(h.compare_baselines(job, self.site, [])[0], "PASS")
        job["values"]["bw"] = 50.0
        status, detail, _ = h.compare_baselines(job, self.site, [])
        self.assertEqual(status, "PERF")
        self.assertIn("-50.0%", detail)
        job["arch"] = "zen3"
        self.assertIn("no baseline", h.compare_baselines(job, self.site, [])[1])


class TestLocalRun(Sandbox):
    """End to end: hpctest run --local with the stub module command."""

    def run_local(self, *tests):
        args = types.SimpleNamespace(
            tests=list(tests), profile=None, all=False, set=None, jobs=2, quiet=True,
            repeat=None, need=None, workdir=None, timeout=1, cancel_on_timeout=False,
            nodes=False, syslog=False, local=True, no_wait=False, keep=True, sbatch=[],
            site="lab")
        saved = sys.stdout
        sys.stdout = open(os.devnull, "w")
        try:
            rc = h.cmd_run(args)
        finally:
            sys.stdout.close()
            sys.stdout = saved
        rows = {r["id"]: r for r in h.summarize(h.load_manifest(args.rundir)["jobs"])}
        return rc, rows

    def test_statuses(self):
        self.add_test("ok", "#@ modules: gcc\n#@ param n = 3\necho value $n\n",
                      "value ${v}\n")
        self.add_test("wrong", "echo nope\n", "yes\n")
        self.add_test("rc", "echo hi; exit 3\n", "hi\n")
        self.add_test("mod", "#@ modules: broken\necho hi\n", "hi\n")
        self.add_test("build", "./prog\n", "", build="false\n")
        self.add_test("off", "echo hi\n", "hi\n")
        self.add_test("multi", "#@ nodes: 2\necho hi\n", "hi\n")
        rc, rows = self.run_local("ok", "wrong", "rc", "mod", "build", "off", "multi")
        got = {k: r["status"] for k, r in rows.items()}
        self.assertEqual(got, {"ok": "PASS", "wrong": "FAIL", "rc": "FAIL", "mod": "MODULE",
                               "build": "BUILD", "off": "SKIP", "multi": "SKIP"})
        self.assertEqual(rc, 1)
        self.assertEqual(rows["ok"]["jobs"][0]["values"], {"v": 3.0})
        self.assertIn("exit code 3", rows["rc"]["detail"])

    def test_stderr_checked(self):
        self.add_test("noisy", "echo hi; echo oops >&2\n", "hi\n")
        self.add_test("quiet", "#@ stderr: ignore\necho hi; echo oops >&2\n", "hi\n")
        _, rows = self.run_local("noisy", "quiet")
        self.assertEqual(rows["noisy"]["status"], "FAIL")
        self.assertEqual(rows["quiet"]["status"], "PASS")


if __name__ == "__main__":
    unittest.main()
