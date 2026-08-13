"""cloudflared quick / named tunnel helpers for Colab serve."""

from __future__ import annotations

import os
import platform
import re
import stat
import subprocess
import time
import urllib.request
from pathlib import Path

URL_RE = re.compile(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com")


def download_cloudflared(dest_dir: str | Path = "/tmp") -> Path:
    dest = Path(dest_dir)
    dest.mkdir(parents=True, exist_ok=True)
    binary = dest / "cloudflared"
    if binary.exists() and binary.stat().st_size > 0:
        return binary

    machine = platform.machine().lower()
    if machine in ("x86_64", "amd64"):
        arch = "amd64"
    elif machine in ("aarch64", "arm64"):
        arch = "arm64"
    else:
        raise RuntimeError(f"unsupported arch for cloudflared: {machine}")

    url = (
        "https://github.com/cloudflare/cloudflared/releases/latest/download/"
        f"cloudflared-linux-{arch}"
    )
    print("downloading cloudflared:", url)
    urllib.request.urlretrieve(url, binary)
    binary.chmod(binary.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return binary


def wait_for_health(base_url: str, *, timeout_s: float = 60.0) -> bool:
    import urllib.error
    import urllib.request as ureq

    deadline = time.time() + timeout_s
    health = base_url.rstrip("/") + "/health"
    while time.time() < deadline:
        try:
            with ureq.urlopen(health, timeout=3) as resp:
                if resp.status == 200:
                    return True
        except (urllib.error.URLError, TimeoutError, OSError):
            time.sleep(1)
    return False


def start_tunnel(
    local_url: str,
    *,
    binary: Path,
    token: str | None = None,
) -> tuple[subprocess.Popen[str], str | None]:
    """Start cloudflared. Returns (proc, public_https_url)."""
    env = os.environ.copy()
    if token:
        # Named tunnel (stable hostname) when CLOUDFLARE_TUNNEL_TOKEN is set.
        cmd = [str(binary), "tunnel", "--no-autoupdate", "run", "--token", token]
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=env,
        )
        public = (os.environ.get("LLM_PUBLIC_URL") or "").strip() or None
        if public:
            # Wait until named tunnel is up enough for local health already passed.
            time.sleep(3)
            return proc, public.rstrip("/")
        # Named tunnel without LLM_PUBLIC_URL: cannot auto-discover hostname.
        time.sleep(3)
        return proc, None

    cmd = [
        str(binary),
        "tunnel",
        "--no-autoupdate",
        "--url",
        local_url,
    ]
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=env,
    )
    public_url: str | None = None
    deadline = time.time() + 90
    assert proc.stdout is not None
    while time.time() < deadline:
        line = proc.stdout.readline()
        if not line:
            if proc.poll() is not None:
                break
            time.sleep(0.2)
            continue
        print(line.rstrip())
        m = URL_RE.search(line)
        if m:
            public_url = m.group(0)
            break
    return proc, public_url


def write_env_snippet(public_url: str, api_key: str) -> str:
    base = public_url.rstrip("/") + "/v1"
    return (
        f"LLM_BASE_URL={base}\n"
        f"LLM_MODEL=navgo-gemma\n"
        f"LLM_API_KEY={api_key}\n"
        f"SERVER_WRITE_TIMEOUT_SECONDS=300\n"
    )
