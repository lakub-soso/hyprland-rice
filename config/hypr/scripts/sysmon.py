#!/usr/bin/env python3
"""waybar custom/sysmon — one pill: CPU · RAM · GPU usage with icons.

Hover: full stats (CPU model/freq/temp/load, RAM + swap + DIMM temp, GPU
usage/temp/VRAM, disk usage + NVMe temp, uptime). Click: Mission Center
(set in waybar's config). Turns yellow/red ("warning"/"critical" class)
when something runs hot or full.

Runs forever, printing one JSON line every INTERVAL seconds (CPU % needs two
/proc/stat samples, so a long-lived process is simpler than waybar polling).
"""
import json
import os
import shutil
import subprocess
import time

INTERVAL = 2
ICON = {"cpu": "\U000f0ee0", "ram": "\U000f035b", "gpu": "\U000f08ae",
        "temp": "\U000f050f", "disk": "\U000f02ca", "up": "\U000f0954"}
C = {"cpu": "#a6da95", "ram": "#eed49f", "gpu": "#7dc4e4",       # green / yellow / sapphire
     "head": "#c6a0f6", "dim": "#8087a2", "text": "#cad3f5"}     # mauve / overlay1 / text


def span(color, s, bold=False):
    return f'<span foreground="{color}"{" weight=\"bold\"" if bold else ""}>{s}</span>'


def read(path, default=""):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def hwmon_temps():
    """sensor name → list of °C (first temp input of each hwmon device)."""
    temps = {}
    base = "/sys/class/hwmon"
    for h in sorted(os.listdir(base)) if os.path.isdir(base) else []:
        raw = read(f"{base}/{h}/temp1_input")
        if raw.isdigit():
            temps.setdefault(read(f"{base}/{h}/name"), []).append(int(raw) / 1000)
    return temps


def cpu_times():
    fields = [int(x) for x in read("/proc/stat").splitlines()[0].split()[1:]]
    idle = fields[3] + fields[4]                      # idle + iowait
    return idle, sum(fields)


def meminfo():
    m = {}
    for line in read("/proc/meminfo").splitlines():
        k, v = line.split(":", 1)
        m[k] = int(v.split()[0]) * 1024               # kB → bytes
    return m


def cpu_model():
    for line in read("/proc/cpuinfo").splitlines():
        if line.startswith("model name"):
            name = line.split(":", 1)[1].strip()
            for junk in (" Processor", " 8-Core", " 6-Core", " 12-Core", " 16-Core"):
                name = name.replace(junk, "")
            return name
    return "CPU"


def cpu_freq_ghz():
    freqs = []
    base = "/sys/devices/system/cpu"
    for d in os.listdir(base):
        f = read(f"{base}/{d}/cpufreq/scaling_cur_freq")
        if d.startswith("cpu") and f.isdigit():
            freqs.append(int(f))
    return sum(freqs) / len(freqs) / 1e6 if freqs else 0


def gpu():
    """(name, util %, temp °C, used MiB, total MiB) or None."""
    if not shutil.which("nvidia-smi"):
        return None
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total",
             "--format=csv,noheader,nounits"], capture_output=True, text=True, timeout=3).stdout
        name, util, temp, used, total = [x.strip() for x in out.splitlines()[0].split(",")]
        return name.replace("NVIDIA GeForce ", ""), int(util), float(temp), int(used), int(total)
    except Exception:
        return None


def gib(b):
    return b / 1024 ** 3


def uptime():
    s = int(float(read("/proc/uptime", "0").split()[0]))
    d, s = divmod(s, 86400)
    h, s = divmod(s, 3600)
    return (f"{d}d " if d else "") + f"{h}h {s // 60}m"


def main():
    model = cpu_model()
    prev_idle, prev_total = cpu_times()
    time.sleep(0.5)
    while True:
        idle, total = cpu_times()
        dt = total - prev_total
        cpu = 100 * (1 - (idle - prev_idle) / dt) if dt else 0
        prev_idle, prev_total = idle, total

        m = meminfo()
        ram_used = m["MemTotal"] - m["MemAvailable"]
        ram = 100 * ram_used / m["MemTotal"]
        swap_used = m.get("SwapTotal", 0) - m.get("SwapFree", 0)
        temps = hwmon_temps()
        cpu_t = (temps.get("k10temp") or temps.get("coretemp") or [None])[0]
        nvme_t = (temps.get("nvme") or [None])[0]
        dimm = temps.get("spd5118") or []
        g = gpu()
        disk = shutil.disk_usage("/")
        load = " ".join(read("/proc/loadavg", "0 0 0").split()[:3])

        gpu_pct = g[1] if g else None
        # Nerd Font icons draw wider than their advance: two spaces after each,
        # three between groups
        text = (f'{span(C["cpu"], ICON["cpu"])}  {cpu:.0f}%   '
                f'{span(C["ram"], ICON["ram"])}  {ram:.0f}%'
                + (f'   {span(C["gpu"], ICON["gpu"])}  {gpu_pct}%' if g else ""))

        hot = [x for x in (cpu_t, g[2] if g else None) if x is not None]
        if (hot and max(hot) >= 90) or ram >= 92:
            cls = "critical"
        elif (hot and max(hot) >= 80) or ram >= 80 or cpu >= 90:
            cls = "warning"
        else:
            cls = "normal"

        def t(v):
            return f" · {v:.0f}°C" if v is not None else ""
        lines = [
            span(C["head"], f'{ICON["cpu"]}  {model}', bold=True),
            f'   usage {cpu:.0f}% · {cpu_freq_ghz():.2f} GHz{t(cpu_t)}',
            f'   load  {load}',
            "",
            span(C["head"], f'{ICON["ram"]}  Memory', bold=True),
            f'   RAM   {gib(ram_used):.1f} / {gib(m["MemTotal"]):.1f} GiB ({ram:.0f}%)'
            + (t(sum(dimm) / len(dimm)) if dimm else ""),
            f'   swap  {gib(swap_used):.1f} / {gib(m.get("SwapTotal", 0)):.1f} GiB',
        ]
        if g:
            lines += ["", span(C["head"], f'{ICON["gpu"]}  {g[0]}', bold=True),
                      f'   usage {g[1]}%{t(g[2])}',
                      f'   VRAM  {g[3] / 1024:.1f} / {g[4] / 1024:.1f} GiB']
        lines += ["", span(C["head"], f'{ICON["disk"]}  Disk', bold=True),
                  f'   /     {gib(disk.used):.0f} / {gib(disk.total):.0f} GiB '
                  f'({100 * disk.used / disk.total:.0f}%){t(nvme_t)}',
                  "", span(C["dim"], f'{ICON["up"]}  up {uptime()}  ·  click: Mission Center')]

        print(json.dumps({"text": text, "class": cls,
                          "tooltip": "<tt>" + "\n".join(lines) + "</tt>"}), flush=True)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except (BrokenPipeError, KeyboardInterrupt):   # waybar restarted / closed the pipe
        pass
