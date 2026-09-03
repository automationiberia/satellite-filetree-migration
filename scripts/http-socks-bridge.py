#!/usr/bin/env python3
"""Minimal HTTP CONNECT proxy forwarding to a SOCKS5 upstream."""
from __future__ import annotations

import os
import select
import socket
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import socks

SOCKS_HOST = "127.0.0.1"
SOCKS_PORT = 51313
LISTEN_HOST = "127.0.0.1"
LISTEN_PORT = 18118

# Clients (curl health checks, Ansible connection pooling) often reset before
# sending a full HTTP request; treat that as normal, not an error.
_QUIET_CLIENT_ERRORS = (
    ConnectionResetError,
    BrokenPipeError,
    ConnectionAbortedError,
    socket.timeout,
)


def _socks_connect(host: str, port: int) -> socket.socket:
    sock = socks.socksocket()
    sock.set_proxy(socks.SOCKS5, SOCKS_HOST, SOCKS_PORT, rdns=True)
    sock.settimeout(60)
    sock.connect((host, port))
    return sock


def _relay(client: socket.socket, remote: socket.socket) -> None:
    sockets = [client, remote]
    try:
        while True:
            readable, _, exceptional = select.select(sockets, [], sockets, 60)
            if exceptional:
                break
            if not readable:
                break
            for source in readable:
                data = source.recv(65536)
                if not data:
                    return
                target = remote if source is client else client
                target.sendall(data)
    except _QUIET_CLIENT_ERRORS:
        return
    except OSError:
        return
    finally:
        for sock in (client, remote):
            try:
                sock.close()
            except OSError:
                pass


class HttpToSocksHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt: str, *args) -> None:
        if os.environ.get("HTTP_PROXY_VERBOSE", "").lower() not in ("1", "true", "yes"):
            return
        sys.stderr.write(f"[http-proxy] {self.address_string()} - {fmt % args}\n")

    def handle(self) -> None:
        try:
            super().handle()
        except _QUIET_CLIENT_ERRORS:
            return

    def handle_one_request(self) -> None:
        try:
            super().handle_one_request()
        except _QUIET_CLIENT_ERRORS:
            return

    def do_CONNECT(self) -> None:
        host, _, port_str = self.path.partition(":")
        port = int(port_str or "443")
        try:
            remote = _socks_connect(host, port)
        except OSError as exc:
            sys.stderr.write(f"[http-proxy] upstream connect failed for {host}:{port}: {exc}\n")
            self.send_error(502, f"Upstream connect failed: {exc}")
            return
        self.send_response(200, "Connection Established")
        self.end_headers()
        _relay(self.connection, remote)

    def do_GET(self) -> None:
        self.send_error(501, "Only CONNECT is supported")


class QuietThreadingHTTPServer(ThreadingHTTPServer):
    daemon_threads = True

    def handle_error(self, request, client_address) -> None:
        exc_type, _, _ = sys.exc_info()
        if exc_type is not None and issubclass(exc_type, _QUIET_CLIENT_ERRORS):
            return
        super().handle_error(request, client_address)


def main() -> None:
    server = QuietThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), HttpToSocksHandler)
    if os.environ.get("HTTP_PROXY_VERBOSE", "").lower() in ("1", "true", "yes"):
        sys.stderr.write(
            f"[http-proxy] listening on http://{LISTEN_HOST}:{LISTEN_PORT} -> socks5://{SOCKS_HOST}:{SOCKS_PORT}\n"
        )
    server.serve_forever()


if __name__ == "__main__":
    main()
