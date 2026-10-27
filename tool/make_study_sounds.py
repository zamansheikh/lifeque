"""Builds the study-timer sounds with ffmpeg.

usage: python3 make_study_sounds.py <out_dir> <rain_source.ogg>

Short cues are synthesised bell/wood tones. Background loops are cut with an
equal-power crossfade at the seam so they repeat without a click, and are
written as WAV because MP3/AAC encoder padding leaves a gap on every loop.
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

OUT = Path(sys.argv[1])
RAIN_SRC = sys.argv[2]
OUT.mkdir(parents=True, exist_ok=True)
TMP = Path(tempfile.mkdtemp())


def run(args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], check=True)


def bell(freq, t0, decay):
    """A soft bell partial set starting at t0, with a 5 ms attack."""
    tt = f"(t-{t0})"
    return (
        f"gte(t,{t0})*min(1,{tt}*200)*exp(-{tt}*{decay})*("
        f"sin(2*PI*{freq}*{tt})+0.35*sin(2*PI*{2 * freq}*{tt})"
        f"+0.12*sin(2*PI*{3.01 * freq}*{tt}))"
    )


def wood(freq, t0, decay):
    tt = f"(t-{t0})"
    return (
        f"gte(t,{t0})*min(1,{tt}*800)*("
        f"exp(-{tt}*{decay})*sin(2*PI*{freq}*{tt})"
        f"+0.5*exp(-{tt}*{decay * 1.6})*sin(2*PI*{freq * 1.48}*{tt}))"
    )


def tone(name, parts, dur, peak_db=-3.0, rate=44100):
    expr = "+".join(parts)
    raw = TMP / f"{name}_raw.wav"
    run(["-f", "lavfi", "-i", f"aevalsrc='{expr}':s={rate}:d={dur}",
         "-af", "afade=t=out:st=%.3f:d=0.05" % (dur - 0.05),
         "-ac", "1", str(raw)])
    peak = max_volume(raw)
    run(["-i", str(raw), "-af", f"volume={peak_db - peak:.2f}dB",
         "-ac", "1", "-c:a", "pcm_s16le", str(OUT / f"{name}.wav")])


def max_volume(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
                        "-af", "volumedetect", "-f", "null", "-"],
                       capture_output=True, text=True)
    return float(re.search(r"max_volume: (-?[0-9.]+)", r.stderr).group(1))


def loudness(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
                        "-af", "ebur128", "-f", "null", "-"],
                       capture_output=True, text=True)
    return float(re.findall(r"I:\s+(-?[0-9.]+) LUFS", r.stderr)[-1])


def seamless_loop(name, src_args, length, fade, target_lufs, rate=22050, pre_filter=""):
    """Cuts length+fade seconds and folds the tail over the head."""
    raw = TMP / f"{name}_src.wav"
    run([*src_args, "-t", str(length + fade), "-ac", "1", "-ar", str(rate),
         *(["-af", pre_filter] if pre_filter else []), str(raw)])
    T, F = length, fade
    graph = (
        f"[0:a]asplit=3[a][b][c];"
        f"[a]atrim=0:{F},asetpts=PTS-STARTPTS,afade=t=in:d={F}:curve=qsin[head];"
        f"[b]atrim={T}:{T + F},asetpts=PTS-STARTPTS,afade=t=out:d={F}:curve=qsin[tail];"
        f"[head][tail]amix=inputs=2:normalize=0[seam];"
        f"[c]atrim={F}:{T},asetpts=PTS-STARTPTS[body];"
        f"[seam][body]concat=n=2:v=0:a=1[out]"
    )
    looped = TMP / f"{name}_loop.wav"
    run(["-i", str(raw), "-filter_complex", graph, "-map", "[out]", str(looped)])
    gain = target_lufs - loudness(looped)
    run(["-i", str(looped), "-af", f"volume={gain:.2f}dB,alimiter=limit=0.9",
         "-ac", "1", "-ar", str(rate), "-c:a", "pcm_s16le", str(OUT / f"{name}.wav")])


C5, E5, G5, A5, C6, D6 = 523.25, 659.25, 783.99, 880.0, 1046.5, 1174.66

# Tap feedback: short, quiet, distinct in direction.
tone("study_start", [bell(C5, 0, 5), bell(G5, 0.12, 5)], 1.0, -6)
tone("study_resume", [bell(E5, 0, 5), bell(A5, 0.10, 5)], 0.9, -6)
tone("study_pause", [bell(G5, 0, 6), bell(C5, 0.12, 6)], 0.9, -8)
tone("study_skip", [bell(A5, 0, 12), bell(D6, 0.07, 12)], 0.5, -8)

# Phase ends (played by the alarm): calm going into a break, bright coming back.
tone("study_focus_done", [bell(G5, 0, 2.5), bell(E5, 0.25, 2.5), bell(C5, 0.5, 2.2)], 2.6, -2)
tone("study_break_over", [bell(C5, 0, 2.5), bell(E5, 0.18, 2.5), bell(G5, 0.36, 2.5),
                          bell(C6, 0.54, 2.2)], 2.6, -2)

# 3-2-1 countdown tick.
tone("study_count", [wood(1100, 0, 45)], 0.18, -9)

# Clock tick-tock: exactly two seconds so it loops in time.
tone("study_tick_loop", [wood(2300, 0, 110), wood(1700, 1.0, 110)], 2.0, -14)

# Background loops.
seamless_loop("study_bg_white",
              ["-f", "lavfi", "-i", "anoisesrc=color=white:amplitude=0.4:seed=7"],
              20, 2, -26, pre_filter="lowpass=f=6500,highpass=f=60")
seamless_loop("study_bg_brown",
              ["-f", "lavfi", "-i", "anoisesrc=color=brown:amplitude=0.6:seed=11"],
              20, 3, -24, pre_filter="highpass=f=30")
seamless_loop("study_bg_rain",
              ["-ss", "6", "-i", RAIN_SRC],
              24, 2, -24, pre_filter="highpass=f=80")

for f in sorted(OUT.glob("*.wav")):
    print(f"{f.name}\t{f.stat().st_size // 1024} KB")
