#!/usr/bin/env python3
"""Deterministic level generator for MazeDrop.

Builds a single-corridor "boustrophedon" maze (guaranteed solvable: every
non-branch cell lies on one connected path from start to exit), then
layers mechanics on top of it per a fixed per-level spec table. Re-running
this script always produces the same output for the same LEVEL_SPECS
entry (seeded by level id) -- level design is controlled, not random.

Usage: python3 generate_levels.py <output_dir>
"""
import json
import math
import random
import sys
from pathlib import Path

LEVEL_SPECS = [
    # id, w, lanes, dead_ends, coins, keys, plain_traps, timed_traps, moving_obstacles, moving_walls, teleport
    dict(id=1, w=4, lanes=3, dead=0, coins=0),
    dict(id=2, w=4, lanes=3, dead=1, coins=1),
    dict(id=3, w=5, lanes=3, dead=1, coins=1),
    dict(id=4, w=5, lanes=4, dead=1, coins=2),
    dict(id=5, w=6, lanes=4, dead=2, coins=2),

    dict(id=6, w=5, lanes=4, dead=2, coins=2, keys=1),
    dict(id=7, w=6, lanes=4, dead=2, coins=2, keys=1),
    dict(id=8, w=6, lanes=5, dead=2, coins=3, keys=1),
    dict(id=9, w=7, lanes=5, dead=3, coins=3, keys=1),
    dict(id=10, w=7, lanes=5, dead=3, coins=3, keys=1),

    dict(id=11, w=6, lanes=4, dead=2, coins=2, plain_traps=2),
    dict(id=12, w=6, lanes=5, dead=2, coins=2, plain_traps=2, moving_obstacles=1),
    dict(id=13, w=7, lanes=5, dead=3, coins=2, plain_traps=3, moving_obstacles=1),
    dict(id=14, w=7, lanes=5, dead=3, coins=2, plain_traps=2, moving_obstacles=2),
    dict(id=15, w=7, lanes=5, dead=3, coins=3, plain_traps=2, moving_obstacles=2, keys=1),

    dict(id=16, w=6, lanes=4, dead=3, coins=2, teleport=True),
    dict(id=17, w=7, lanes=5, dead=3, coins=3, teleport=True),
    dict(id=18, w=7, lanes=5, dead=4, coins=3, teleport=True, plain_traps=2),
    dict(id=19, w=7, lanes=5, dead=4, coins=3, teleport=True, keys=1),
    dict(id=20, w=8, lanes=5, dead=4, coins=4, teleport=True, plain_traps=2, keys=1),

    dict(id=21, w=7, lanes=5, dead=3, coins=2, timed_traps=2),
    dict(id=22, w=7, lanes=5, dead=3, coins=2, timed_traps=2, moving_walls=1),
    dict(id=23, w=8, lanes=5, dead=4, coins=3, timed_traps=2, moving_walls=1, keys=2),
    dict(id=24, w=8, lanes=5, dead=4, coins=3, timed_traps=3, moving_walls=2, keys=2),
    dict(id=25, w=8, lanes=6, dead=4, coins=3, timed_traps=2, moving_walls=1, keys=2, moving_obstacles=1),

    dict(id=26, w=8, lanes=5, dead=4, coins=3, keys=2, plain_traps=2, moving_obstacles=1, teleport=True),
    dict(id=27, w=8, lanes=6, dead=5, coins=3, keys=2, timed_traps=2, moving_walls=1, teleport=True),
    dict(id=28, w=9, lanes=6, dead=5, coins=4, keys=2, plain_traps=2, moving_obstacles=2, timed_traps=1),
    dict(id=29, w=9, lanes=6, dead=5, coins=4, keys=3, timed_traps=2, moving_walls=2, teleport=True),
    dict(id=30, w=9, lanes=6, dead=6, coins=4, keys=3, plain_traps=2, timed_traps=2, moving_obstacles=2, moving_walls=1, teleport=True),
]


def build_path(w, lanes):
    """Boustrophedon single-corridor maze. Returns (path, width, height)."""
    path = []
    for lane in range(lanes):
        cols = range(w) if lane % 2 == 0 else range(w - 1, -1, -1)
        row = 2 * lane
        for col in cols:
            path.append((col, row))
        if lane < lanes - 1:
            connector_col = (w - 1) if lane % 2 == 0 else 0
            path.append((connector_col, row + 1))
    height = 2 * lanes - 1
    return path, w, height


def add_dead_ends(path, w, h, count, rng):
    """Branch a handful of 1-cell dead ends off the main path. Returns the
    list of new (col, row) dead-end tips (good spots for optional coins)."""
    path_set = set(path)
    tips = []
    candidates = list(range(1, len(path) - 1))
    rng.shuffle(candidates)
    directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    for idx in candidates:
        if len(tips) >= count:
            break
        cx, cy = path[idx]
        dirs = directions[:]
        rng.shuffle(dirs)
        for dx, dy in dirs:
            nx, ny = cx + dx, cy + dy
            if not (0 <= nx < w and 0 <= ny < h):
                continue
            if (nx, ny) in path_set:
                continue
            path_set.add((nx, ny))
            tips.append((nx, ny))
            break
    return tips


def make_level(spec):
    rng = random.Random(1000 + spec["id"])
    path, w, h = build_path(spec["w"], spec["lanes"])
    dead_tips = add_dead_ends(path, w, h, spec.get("dead", 0), rng)

    path_set = set(path)
    walls = [
        {"x": x, "y": y}
        for x in range(w)
        for y in range(h)
        if (x, y) not in path_set and (x, y) not in dead_tips
    ]

    player = path[0]
    exit_pos = path[-1]
    reserved = {player, exit_pos}

    def pick_indices(n, lo_frac, hi_frac):
        indices = []
        span = list(range(max(1, int(len(path) * lo_frac)), min(len(path) - 1, int(len(path) * hi_frac))))
        rng.shuffle(span)
        for i in span:
            if path[i] in reserved:
                continue
            indices.append(i)
            reserved.add(path[i])
            if len(indices) == n:
                break
        return indices

    keys_out, doors_out = [], []
    n_keys = spec.get("keys", 0)
    if n_keys:
        door_indices = sorted(pick_indices(n_keys, 0.55, 0.97), reverse=False)
        for rank, d_idx in enumerate(door_indices):
            key_lo = 0.05 + rank * 0.12
            key_hi = min(0.9, (d_idx / len(path)) - 0.05)
            k_idx_list = pick_indices(1, key_lo, max(key_lo + 0.05, key_hi))
            if not k_idx_list:
                continue
            k_idx = k_idx_list[0]
            key_id = f"k{rank + 1}"
            keys_out.append({"x": path[k_idx][0], "y": path[k_idx][1], "id": key_id})
            doors_out.append({"x": path[d_idx][0], "y": path[d_idx][1], "id": key_id})

    plain_traps_out = []
    for _ in range(spec.get("plain_traps", 0)):
        idx_list = pick_indices(1, 0.2, 0.9)
        if idx_list:
            x, y = path[idx_list[0]]
            plain_traps_out.append({"x": x, "y": y})

    timed_traps_out = []
    for _ in range(spec.get("timed_traps", 0)):
        idx_list = pick_indices(1, 0.2, 0.9)
        if idx_list:
            x, y = path[idx_list[0]]
            timed_traps_out.append({"x": x, "y": y, "activeMs": 900, "inactiveMs": 900})

    moving_obstacles_out = []
    for _ in range(spec.get("moving_obstacles", 0)):
        idx_list = pick_indices(1, 0.2, 0.85)
        if idx_list:
            i = idx_list[0]
            j = min(i + 1, len(path) - 2)
            if path[j] in reserved:
                j = max(i - 1, 1)
            reserved.add(path[j])
            moving_obstacles_out.append(
                {"path": [{"x": path[i][0], "y": path[i][1]}, {"x": path[j][0], "y": path[j][1]}], "stepMs": 500}
            )

    moving_walls_out = []
    for _ in range(spec.get("moving_walls", 0)):
        idx_list = pick_indices(1, 0.2, 0.9)
        if idx_list:
            x, y = path[idx_list[0]]
            moving_walls_out.append({"x": x, "y": y, "openMs": 1400, "closedMs": 1400})

    teleports_out = []
    if spec.get("teleport"):
        lo = pick_indices(1, 0.15, 0.4)
        hi = pick_indices(1, 0.55, 0.85)
        if lo and hi:
            ax, ay = path[lo[0]]
            bx, by = path[hi[0]]
            teleports_out.append({"x": ax, "y": ay, "id": "t1"})
            teleports_out.append({"x": bx, "y": by, "id": "t1"})

    coins_out = []
    coin_spots = list(dead_tips)
    rng.shuffle(coin_spots)
    n_coins = spec.get("coins", 0)
    while len(coin_spots) < n_coins:
        idx_list = pick_indices(1, 0.1, 0.95)
        if not idx_list:
            break
        coin_spots.append(path[idx_list[0]])
    for (x, y) in coin_spots[:n_coins]:
        coins_out.append({"x": x, "y": y})

    par_moves = len(path) - 1
    par_time = max(15, math.ceil(par_moves * 0.7) + 5)

    return {
        "id": spec["id"],
        "width": w,
        "height": h,
        "player": {"x": player[0], "y": player[1]},
        "exit": {"x": exit_pos[0], "y": exit_pos[1]},
        "walls": walls,
        "traps": plain_traps_out + timed_traps_out,
        "keys": keys_out,
        "doors": doors_out,
        "teleports": teleports_out,
        "coins": coins_out,
        "movingObstacles": moving_obstacles_out,
        "movingWalls": moving_walls_out,
        "parMoves": par_moves,
        "parTimeSeconds": par_time,
    }


def verify_solvable(level):
    """BFS over (position, frozenset(collected keys)) treating doors as
    walls until their key is collected. Raises if the exit is unreachable."""
    from collections import deque

    walls = {(w["x"], w["y"]) for w in level["walls"]}
    doors = {(d["x"], d["y"]): d["id"] for d in level["doors"]}
    key_at = {(k["x"], k["y"]): k["id"] for k in level["keys"]}
    teleport_pairs = {}
    for t in level["teleports"]:
        teleport_pairs.setdefault(t["id"], []).append((t["x"], t["y"]))

    start = (level["player"]["x"], level["player"]["y"])
    exit_pos = (level["exit"]["x"], level["exit"]["y"])
    w, h = level["width"], level["height"]

    start_state = (start, frozenset())
    seen = {start_state}
    queue = deque([start_state])
    while queue:
        (pos, keys) = queue.popleft()
        if pos == exit_pos:
            return True
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = pos[0] + dx, pos[1] + dy
            if not (0 <= nx < w and 0 <= ny < h):
                continue
            if (nx, ny) in walls:
                continue
            if (nx, ny) in doors and doors[(nx, ny)] not in keys:
                continue
            new_keys = keys
            if (nx, ny) in key_at:
                new_keys = keys | {key_at[(nx, ny)]}
            new_pos = (nx, ny)
            for pair_id, pads in teleport_pairs.items():
                if new_pos in pads:
                    other = [p for p in pads if p != new_pos]
                    if other:
                        new_pos = other[0]
                    break
            state = (new_pos, new_keys)
            if state not in seen:
                seen.add(state)
                queue.append(state)
    return False


def main():
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/levels")
    out_dir.mkdir(parents=True, exist_ok=True)
    for spec in LEVEL_SPECS:
        level = make_level(spec)
        if not verify_solvable(level):
            raise SystemExit(f"Level {spec['id']} generated as UNSOLVABLE, aborting")
        path = out_dir / f"level_{spec['id']:02d}.json"
        path.write_text(json.dumps(level, indent=2) + "\n")
        print(f"wrote {path} (par {level['parMoves']} moves / {level['parTimeSeconds']}s)")


if __name__ == "__main__":
    main()
