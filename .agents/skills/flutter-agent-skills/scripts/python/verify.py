#!/usr/bin/env python3
"""verify.py — runs the local pre-push verification suite for a Flutter project.
verify.py — 运行 Flutter 项目推送前的本地校验流程。

Usage:  python scripts/python/verify.py [--no-publish]
用法：  python scripts/python/verify.py [--no-publish]
Runs:   flutter format --set-exit-if-changed, flutter analyze, flutter test, and
        (unless skipped) flutter pub publish --dry-run.
执行：  flutter format --set-exit-if-changed、flutter analyze、flutter test，
        以及（除非跳过）flutter pub publish --dry-run。
Exits non-zero if any step fails, so it can gate CI or a pre-push hook.
任一环节失败即以非零码退出，可用于 CI 或 pre-push 钩子拦截。
"""

import subprocess
import sys


def run(cmd, args):
    """Run [cmd] with [args]; return the process exit code.
    运行 cmd 并传入 args，返回进程退出码。"""
    print(f"\n> {cmd} {' '.join(args)}")
    result = subprocess.run(
        cmd, args if isinstance(args, list) else list(args),
        shell=(sys.platform == "win32"), check=False,
    )
    return result.returncode


def main(argv):
    """Run the local pre-push verification suite. 运行本地推送前校验流程。"""
    skip_publish = "--no-publish" in argv

    # 0. Formatting.
    # 0. 格式化。
    if run("flutter", ["format", "--set-exit-if-changed", "."]) != 0:
        sys.stderr.write("flutter format found unformatted files.\n")
        return 1

    # 1. Static analysis.
    # 1. 静态分析。
    if run("flutter", ["analyze"]) != 0:
        sys.stderr.write("flutter analyze failed.\n")
        return 1

    # 2. Tests.
    # 2. 运行测试。
    if run("flutter", ["test"]) != 0:
        sys.stderr.write("flutter test failed.\n")
        return 1

    # 3. Publish dry-run (skipped for apps / private packages).
    # 3. 发布预检（应用 / 私有包可加 --no-publish 跳过）。
    if not skip_publish:
        if run("flutter", ["pub", "publish", "--dry-run"]) != 0:
            sys.stderr.write("flutter pub publish --dry-run failed.\n")
            return 1

    print("\nAll checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
