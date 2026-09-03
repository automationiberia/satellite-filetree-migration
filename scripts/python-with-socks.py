#!/usr/bin/env python3
"""Python interpreter wrapper routing all sockets through SOCKS5."""
from __future__ import annotations

import runpy
import socket
import sys
from pathlib import Path

import socks

_PROXY_HOST = "localhost"
_PROXY_PORT = 51313

socks.set_default_proxy(socks.SOCKS5, _PROXY_HOST, _PROXY_PORT, rdns=True)
socket.socket = socks.socksocket


def _run_module_script(script: str) -> None:
    sys.argv = sys.argv[1:]
    runpy.run_path(script, run_name="__main__")


def _run_python() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "-c":
        code = sys.argv[2]
        sys.argv = sys.argv[3:]
        exec(compile(code, "-c", "exec"), {"__name__": "__main__"})
        return

    if len(sys.argv) > 1 and sys.argv[1] == "-m":
        module = sys.argv[2]
        sys.argv = sys.argv[3:]
        runpy.run_module(module, run_name="__main__", alter_sys=True)
        return

    if len(sys.argv) > 1 and Path(sys.argv[1]).suffix == ".py":
        _run_module_script(sys.argv[1])
        return

    real_python = Path(__file__).resolve().parent / "python3"
    sys.argv[0] = str(real_python)
    runpy.run_module("code", run_name="__main__", alter_sys=True)


if __name__ == "__main__":
    _run_python()
