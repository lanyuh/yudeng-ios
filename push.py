# -*- coding: utf-8 -*-
"""把屿灯 iOS 工程推到 GitHub，用它的 Mac 机器编出 ipa。

用法：
    set GH_TOKEN=ghp_xxx
    python push.py

只做四件事：建仓库、传文件、触发 Actions、下产物。
"""

import base64
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

工程 = pathlib.Path(r"D:\tools\yudeng-ios")
仓库名 = "yudeng-ios"
TOKEN = os.environ.get("GH_TOKEN", "").strip()


def api(方法, 路径, 数据=None, 原始=False):
    url = "https://api.github.com" + 路径
    body = json.dumps(数据).encode("utf-8") if 数据 is not None else None
    req = urllib.request.Request(url, data=body, method=方法)
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("User-Agent", "yudeng-push")
    if body is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            raw = r.read()
            if 原始:
                return raw
            return json.loads(raw.decode("utf-8")) if raw else None
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {e.code} {url}\n{body}")


def 要(路径):
    return api("GET", 路径)


def 建仓库(owner):
    try:
        r = 要(f"/repos/{owner}/{仓库名}")
        print("仓库已经在：", r["html_url"])
        return
    except SystemExit:
        pass
    except Exception:
        pass
    r = api("POST", "/user/repos", {
        "name": 仓库名,
        "private": True,
        "auto_init": True,
        "description": "屿灯 iOS —— 摩托队局域网对讲",
    })
    print("建好了：", r["html_url"])


def 传文件(owner, 相对路径):
    完整 = 工程 / 相对路径
    内容 = 完整.read_bytes()
    b64 = base64.b64encode(内容).decode("ascii")
    路径 = f"/repos/{owner}/{仓库名}/contents/{相对路径.replace(os.sep, '/')}"
    # 先看有没有，有就带上 sha 覆盖
    sha = None
    try:
        r = 要(路径 + "?ref=main")
        sha = r.get("sha")
    except SystemExit:
        sha = None
    except Exception:
        sha = None
    数据 = {"message": f"add {相对路径}", "content": b64, "branch": "main"}
    if sha:
        数据["sha"] = sha
    结果 = api("PUT", 路径, 数据)
    print("  传了", 相对路径, 结果["content"]["size"], "字节")


def main():
    if not TOKEN:
        print("没有 GH_TOKEN。先 set GH_TOKEN=... 再跑。")
        return 2

    我 = 要("/user")
    owner = 我["login"]
    print("账号：", owner)

    建仓库(owner)

    文件们 = []
    for p in 工程.rglob("*"):
        if not p.is_file():
            continue
        相对 = p.relative_to(工程)
        if 相对.parts[0] in ("build", "out", ".git"):
            continue
        文件们.append(相对)
    文件们.sort()
    print("一共", len(文件们), "个文件")

    for 相对 in 文件们:
        传文件(owner, str(相对))

    # 触发
    try:
        api("POST", f"/repos/{owner}/{仓库名}/actions/workflows/ios-build.yml/dispatches",
            {"ref": "main"})
        print("已触发编译")
    except SystemExit as e:
        print("触发失败：", e)
        return 3

    # 等
    上次 = None
    for i in range(120):
        time.sleep(15)
        runs = 要(f"/repos/{owner}/{仓库名}/actions/runs?per_page=1")
        列表 = runs.get("workflow_runs", [])
        if not 列表:
            print("等编译任务出现…", i)
            continue
        run = 列表[0]
        状态 = run["status"]
        结论 = run["conclusion"]
        if (状态, 结论) != 上次:
            print(f"  第 {i} 次看：{状态} {结论 or ''}")
            上次 = (状态, 结论)
        if 状态 == "completed":
            print("完了：", 结论, run["html_url"])
            if 结论 != "success":
                return 4
            下产物(owner, run["id"])
            return 0
    print("等太久了")
    return 5


def 下产物(owner, run_id):
    arts = 要(f"/repos/{owner}/{仓库名}/actions/runs/{run_id}/artifacts")
    列表 = arts.get("artifacts", [])
    if not 列表:
        print("没有产物")
        return
    出 = 工程 / "out"
    出.mkdir(exist_ok=True)
    for a in 列表:
        print("下：", a["name"], a["size_in_bytes"], "字节")
        原始 = api("GET", a["archive_download_url"].replace("https://api.github.com", ""), 原始=True)
        目标 = 出 / (a["name"] + ".zip")
        目标.write_bytes(原始)
        print("  存到", 目标)


if __name__ == "__main__":
    sys.exit(main())
