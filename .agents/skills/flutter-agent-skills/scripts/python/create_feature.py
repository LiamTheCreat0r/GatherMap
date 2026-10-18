#!/usr/bin/env python3
# create_feature.py — scaffolds a feature-first folder under lib/features.
# create_feature.py — 在 lib/features 下生成「功能优先」结构的目录骨架。
#
# Usage / 用法:
#   python scripts/python/create_feature.py <feature_name> [--pattern mvvm|mvp]
# Example / 示例:
#   python scripts/python/create_feature.py auth
#   python scripts/python/create_feature.py auth --pattern mvp
# Creates / 生成:
#   lib/features/auth/{data,domain,presentation}/ with per-layer barrels, plus a
#   presentation/view_model (default MVVM) or presentation/presenter (MVP) layer,
#   and a feature-level barrel (auth.dart) re-exporting everything.
#   lib/features/auth/{data,domain,presentation}/ 及各层 barrel；presentation 下
#   默认生成 view_model（MVVM），或用 --pattern mvp 生成 presenter；feature 级
#   barrel（auth.dart）统一导出。

import os
import re
import sys

USAGE = (
    "Usage: python scripts/python/create_feature.py "
    "<feature_name> [--pattern mvvm|mvp]"
)


def main():
    positional = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not positional:
        sys.stderr.write(USAGE + "\n")
        sys.exit(1)

    pattern = "mvvm"
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == "--pattern" and i + 1 < len(args):
            pattern = args[i + 1].lower()
        elif a.startswith("--pattern="):
            pattern = a.split("=", 1)[1].lower()
    if pattern not in ("mvvm", "mvp"):
        sys.stderr.write('Unknown pattern "%s". Use mvvm or mvp.\n' % pattern)
        sys.exit(1)

    name = positional[0].strip()
    if not re.match(r"^[a-z][a-z0-9_]*$", name):
        sys.stderr.write(
            "Feature name must be snake_case starting with a letter.\n"
        )
        sys.exit(1)

    base = os.path.join(os.getcwd(), "lib", "features", name)
    sep = os.sep

    def mkdir(rel):
        os.makedirs(os.path.join(base, *rel.split("/")), exist_ok=True)

    def barrel(rel, filename, comment):
        path = os.path.join(base, *rel.split("/"), filename)
        with open(path, "w", encoding="utf-8") as f:
            f.write("// %s\n" % comment)

    for layer in ("data", "domain", "presentation"):
        mkdir(layer)
        barrel(layer, "%s_%s.dart" % (name, layer), "%s %s layer" % (name, layer))

    sub = "view_model" if pattern == "mvvm" else "presenter"
    sub_file = (
        "%s_view_model.dart" % name
        if pattern == "mvvm"
        else "%s_presenter.dart" % name
    )
    mkdir("presentation/%s" % sub)
    barrel(
        "presentation/%s" % sub,
        sub_file,
        "%s %s %s"
        % (name, pattern, "ViewModel" if pattern == "mvvm" else "Presenter"),
    )

    with open(os.path.join(base, "%s.dart" % name), "w", encoding="utf-8") as f:
        f.write("export '%s/data/%s_data.dart';\n" % (name, name))
        f.write("export '%s/domain/%s_domain.dart';\n" % (name, name))
        f.write("export '%s/presentation/%s_presentation.dart';\n" % (name, name))
        f.write("export '%s/presentation/%s/%s';\n" % (name, sub, sub_file))

    print('Created feature "%s" at lib/features/%s (pattern: %s)'
          % (name, name, pattern))


if __name__ == "__main__":
    main()
