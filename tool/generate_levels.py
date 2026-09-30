#!/usr/bin/env python3
"""Deterministic level generator for MazeDrop.

Three layout algorithms, chosen per level:
  * serpentine  - single winding corridor (levels 1-2, teaches swiping)
  * maze        - perfect maze (recursive backtracker): one route to the
                  exit, natural dead ends to explore
  * braided     - perfect maze with some walls knocked out, creating loops
                  and genuinely alternative routes

Mechanics are layered on top per LEVEL_SPECS. Placement rules that keep
every level fair:
  * plain (always-on) traps never sit on the required route -- they punish
    exploring the wrong branch, they never force damage
  * timed traps / moving obstacles / moving walls sit ON the route: they
    are always passable with timing
  * every key is reachable before the door it opens (checked by a
    key-aware BFS solver, which also treats plain traps as walls)
  * a teleport's entry pad sits in a dead end, its exit pad on the route,
    before any door, so it can never skip a lock

Every level is seeded by its id, so re-running the script yields the same
files. If a spec cannot be satisfied within the retry budget the script
aborts loudly instead of writing a broken level.

Usage: python3 tool/generate_levels.py assets/levels
"""
import json
import math
import random
import sys
from collections import deque
from pathlib import Path

MIN_PAR_MOVES = 10
MAX_PAR_MOVES = 55
MAX_ATTEMPTS = 200

# layout: serpentine(w, lanes) | maze/braided(cells_w, cells_h)
LEVEL_SPECS = [
    dict(id=1, layout="serpentine", w=4, lanes=3),
    dict(id=2, layout="serpentine", w=5, lanes=3, coins=1),
    dict(id=3, layout="maze", cw=3, ch=3, coins=1),
    dict(id=4, layout="maze", cw=3, ch=4, coins=2),
    dict(id=5, layout="maze", cw=4, ch=4, coins=2),

    dict(id=6, layout="maze", cw=4, ch=4, coins=2, keys=1),
    dict(id=7, layout="maze", cw=4, ch=5, coins=2, keys=1),
    dict(id=8, layout="maze", cw=4, ch=5, coins=3, keys=1),
    dict(id=9, layout="maze", cw=5, ch=5, coins=3, keys=1),
    dict(id=10, layout="maze", cw=5, ch=6, coins=3, keys=1),

    dict(id=11, layout="maze", cw=4, ch=5, coins=2, plain_traps=2),
    dict(id=12, layout="maze", cw=4, ch=5, coins=2, plain_traps=2, moving_obstacles=1),
    dict(id=13, layout="maze", cw=5, ch=5, coins=2, plain_traps=3, moving_obstacles=1),
    dict(id=14, layout="maze", cw=5, ch=6, coins=2, plain_traps=2, moving_obstacles=2),
    dict(id=15, layout="maze", cw=5, ch=6, coins=3, plain_traps=2, moving_obstacles=2, keys=1),

    dict(id=16, layout="braided", cw=4, ch=5, braids=2, coins=2, teleport=True),
    dict(id=17, layout="braided", cw=5, ch=5, braids=2, coins=3, teleport=True),
    dict(id=18, layout="braided", cw=5, ch=6, braids=3, coins=3, teleport=True, plain_traps=2),
    dict(id=19, layout="braided", cw=5, ch=6, braids=3, coins=3, teleport=True, keys=1),
    dict(id=20, layout="braided", cw=5, ch=6, braids=3, coins=4, teleport=True, plain_traps=2, keys=1),

    dict(id=21, layout="maze", cw=5, ch=5, min_par=22, coins=2, timed_traps=2),
    dict(id=22, layout="maze", cw=5, ch=6, min_par=26, coins=2, timed_traps=2, moving_walls=1),
    dict(id=23, layout="braided", cw=5, ch=6, min_par=26, braids=2, coins=3, timed_traps=2, moving_walls=1, keys=2),
    dict(id=24, layout="braided", cw=5, ch=6, min_par=26, braids=2, coins=3, timed_traps=3, moving_walls=2, keys=2),
    dict(id=25, layout="braided", cw=5, ch=6, min_par=26, braids=3, coins=3, timed_traps=2, moving_walls=1, keys=2, moving_obstacles=1),

    dict(id=26, layout="braided", cw=5, ch=6, min_par=26, braids=3, coins=3, keys=2, plain_traps=2, moving_obstacles=1, teleport=True),
    dict(id=27, layout="braided", cw=5, ch=6, min_par=26, braids=3, coins=3, keys=2, timed_traps=2, moving_walls=1, teleport=True),
    dict(id=28, layout="braided", cw=5, ch=6, min_par=26, braids=3, coins=4, keys=2, plain_traps=2, moving_obstacles=2, timed_traps=1),
    dict(id=29, layout="braided", cw=5, ch=6, min_par=26, braids=4, coins=4, keys=3, timed_traps=2, moving_walls=2, teleport=True),
    dict(id=30, layout="braided", cw=5, ch=6, min_par=26, braids=4, coins=4, keys=3, plain_traps=2, timed_traps=2, moving_obstacles=2, moving_walls=1, teleport=True),
]

DIRS = ((1, 0), (-1, 0), (0, 1), (0, -1))


class Unsatisfiable(Exception):
    pass


# --------------------------------------------------------------------------
# Layouts
# --------------------------------------------------------------------------

def layout_serpentine(spec, rng):
    w, lanes = spec["w"], spec["lanes"]
    floor = []
    for lane in range(lanes):
        cols = range(w) if lane % 2 == 0 else range(w - 1, -1, -1)
        row = 2 * lane
        floor.extend((c, row) for c in cols)
        if lane < lanes - 1:
            floor.append(((w - 1) if lane % 2 == 0 else 0, row + 1))
    return set(floor), w, 2 * lanes - 1, floor[0], floor[-1]


def layout_maze(spec, rng, braids=0):
    cw, ch = spec["cw"], spec["ch"]
    w, h = 2 * cw + 1, 2 * ch + 1
    start = (1, 1)
    floor = {start}
    visited = {start}
    stack = [start]
    while stack:
        cx, cy = stack[-1]
        options = []
        for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
            nx, ny = cx + dx, cy + dy
            if 1 <= nx < w - 1 and 1 <= ny < h - 1 and (nx, ny) not in visited:
                options.append((nx, ny, dx, dy))
        if options:
            nx, ny, dx, dy = rng.choice(options)
            floor.add((cx + dx // 2, cy + dy // 2))
            floor.add((nx, ny))
            visited.add((nx, ny))
            stack.append((nx, ny))
        else:
            stack.pop()

    if braids:
        candidates = []
        for x in range(1, w - 1):
            for y in range(1, h - 1):
                if (x, y) in floor:
                    continue
                horiz = (x - 1, y) in floor and (x + 1, y) in floor
                vert = (x, y - 1) in floor and (x, y + 1) in floor
                if horiz != vert:  # a wall strictly between two floor cells
                    candidates.append((x, y))
        rng.shuffle(candidates)
        for cell in candidates[:braids]:
            floor.add(cell)

    exit_pos = (w - 2, h - 2)
    return floor, w, h, start, exit_pos


# --------------------------------------------------------------------------
# Graph helpers
# --------------------------------------------------------------------------

def neighbors(cell, floor):
    x, y = cell
    for dx, dy in DIRS:
        n = (x + dx, y + dy)
        if n in floor:
            yield n


def bfs_parents(start, floor, blocked=frozenset()):
    parents = {start: None}
    q = deque([start])
    while q:
        cur = q.popleft()
        for n in neighbors(cur, floor):
            if n in blocked or n in parents:
                continue
            parents[n] = cur
            q.append(n)
    return parents


def shortest_path(start, goal, floor, blocked=frozenset()):
    parents = bfs_parents(start, floor, blocked)
    if goal not in parents:
        return None
    path = [goal]
    while path[-1] != start:
        path.append(parents[path[-1]])
    path.reverse()
    return path


# --------------------------------------------------------------------------
# Solver: key-aware BFS, plain traps count as walls
# --------------------------------------------------------------------------

def verify_solvable(level):
    walls = {(w["x"], w["y"]) for w in level["walls"]}
    plain_traps = {(t["x"], t["y"]) for t in level["traps"] if not t.get("activeMs")}
    blocked = walls | plain_traps
    doors = {(d["x"], d["y"]): d["id"] for d in level["doors"]}
    key_at = {(k["x"], k["y"]): k["id"] for k in level["keys"]}
    pairs = {}
    for t in level["teleports"]:
        pairs.setdefault(t["id"], []).append((t["x"], t["y"]))

    start = (level["player"]["x"], level["player"]["y"])
    exit_pos = (level["exit"]["x"], level["exit"]["y"])
    w, h = level["width"], level["height"]

    init = (start, frozenset())
    seen = {init}
    q = deque([init])
    while q:
        pos, keys = q.popleft()
        if pos == exit_pos:
            return True
        for dx, dy in DIRS:
            nx, ny = pos[0] + dx, pos[1] + dy
            if not (0 <= nx < w and 0 <= ny < h) or (nx, ny) in blocked:
                continue
            if (nx, ny) in doors and doors[(nx, ny)] not in keys:
                continue
            new_keys = keys | {key_at[(nx, ny)]} if (nx, ny) in key_at else keys
            new_pos = (nx, ny)
            for pads in pairs.values():
                if new_pos in pads:
                    others = [p for p in pads if p != new_pos]
                    if others:
                        new_pos = others[0]
                    break
            state = (new_pos, new_keys)
            if state not in seen:
                seen.add(state)
                q.append(state)
    return False


# --------------------------------------------------------------------------
# Level assembly
# --------------------------------------------------------------------------

def build_level(spec, rng):
    layout = spec["layout"]
    if layout == "serpentine":
        floor, w, h, start, exit_pos = layout_serpentine(spec, rng)
    elif layout == "maze":
        floor, w, h, start, exit_pos = layout_maze(spec, rng)
    elif layout == "braided":
        floor, w, h, start, exit_pos = layout_maze(spec, rng, braids=spec.get("braids", 2))
    else:
        raise ValueError(f"unknown layout {layout}")

    route = shortest_path(start, exit_pos, floor)
    if route is None:
        raise Unsatisfiable("no route")
    par_moves = len(route) - 1
    min_par = spec.get("min_par", MIN_PAR_MOVES)
    if not (min_par <= par_moves <= MAX_PAR_MOVES):
        raise Unsatisfiable(f"par {par_moves} out of range")

    route_set = set(route)
    route_index = {cell: i for i, cell in enumerate(route)}
    used = {start, exit_pos}

    def dead_ends():
        return [c for c in floor if c not in used and sum(1 for _ in neighbors(c, floor)) == 1]

    def branch_cells():
        return [c for c in floor if c not in used and c not in route_set]

    def route_cells(lo, hi):
        a, b = int(len(route) * lo), int(len(route) * hi)
        return [route[i] for i in range(max(1, a), min(len(route) - 1, b)) if route[i] not in used]

    def take(cells):
        if not cells:
            raise Unsatisfiable("no placement cell")
        cell = rng.choice(cells)
        used.add(cell)
        return cell

    # --- keys & doors ---------------------------------------------------
    keys_out, doors_out = [], []
    n_keys = spec.get("keys", 0)
    if n_keys:
        door_cells = []
        band = route_cells(0.45, 0.95)
        rng.shuffle(band)
        for cell in sorted(band, key=lambda c: route_index[c]):
            if len(door_cells) == n_keys:
                break
            if all(abs(route_index[cell] - route_index[d]) >= 3 for d in door_cells):
                door_cells.append(cell)
        if len(door_cells) < n_keys:
            raise Unsatisfiable("not enough door spots")
        door_cells.sort(key=lambda c: route_index[c])
        for cell in door_cells:
            used.add(cell)
        for i, door in enumerate(door_cells):
            # Reachable from start with this door and every later door shut.
            still_shut = frozenset(door_cells[i:])
            reachable = set(bfs_parents(start, floor, still_shut))
            prefer = [c for c in dead_ends() if c in reachable]
            fallback = [c for c in branch_cells() if c in reachable] or \
                       [c for c in route[1:route_index[door]] if c not in used]
            key_cell = take(prefer or fallback)
            key_id = f"k{i + 1}"
            keys_out.append({"x": key_cell[0], "y": key_cell[1], "id": key_id})
            doors_out.append({"x": door[0], "y": door[1], "id": key_id})

    first_door_index = min((route_index[(d["x"], d["y"])] for d in doors_out), default=len(route))

    # --- teleport: dead end -> route, before any door ---------------------
    teleports_out = []
    if spec.get("teleport"):
        entry = take(dead_ends() or branch_cells())
        exits = [c for c in route_cells(0.3, 0.8) if route_index[c] < first_door_index]
        exit_pad = take(exits)
        teleports_out = [
            {"x": entry[0], "y": entry[1], "id": "t1"},
            {"x": exit_pad[0], "y": exit_pad[1], "id": "t1"},
        ]

    # --- hazards ------------------------------------------------------------
    traps_out = []
    for _ in range(spec.get("plain_traps", 0)):
        cell = take(branch_cells())
        traps_out.append({"x": cell[0], "y": cell[1]})
    for _ in range(spec.get("timed_traps", 0)):
        cell = take(route_cells(0.2, 0.9))
        traps_out.append({"x": cell[0], "y": cell[1], "activeMs": 900, "inactiveMs": 900})

    moving_obstacles_out = []
    for _ in range(spec.get("moving_obstacles", 0)):
        a = take(route_cells(0.2, 0.85))
        i = route_index[a]
        b = route[i + 1] if route[i + 1] not in used and i + 1 < len(route) - 1 else route[i - 1]
        if b in used:
            raise Unsatisfiable("obstacle partner used")
        used.add(b)
        moving_obstacles_out.append({
            "path": [{"x": a[0], "y": a[1]}, {"x": b[0], "y": b[1]}],
            "stepMs": 500,
        })

    moving_walls_out = []
    for _ in range(spec.get("moving_walls", 0)):
        cell = take(route_cells(0.2, 0.9))
        moving_walls_out.append({"x": cell[0], "y": cell[1], "openMs": 1400, "closedMs": 1400})

    # --- coins: reward exploring dead ends first ---------------------------
    coins_out = []
    for _ in range(spec.get("coins", 0)):
        pool = dead_ends() or branch_cells() or route_cells(0.1, 0.95)
        cell = take(pool)
        coins_out.append({"x": cell[0], "y": cell[1]})

    walls = [{"x": x, "y": y} for y in range(h) for x in range(w) if (x, y) not in floor]
    par_time = math.ceil(par_moves * 0.7) + 5
    time_limit = min(120, par_moves * 2 + 15)

    return {
        "id": spec["id"],
        "width": w,
        "height": h,
        "player": {"x": start[0], "y": start[1]},
        "exit": {"x": exit_pos[0], "y": exit_pos[1]},
        "walls": walls,
        "traps": traps_out,
        "keys": keys_out,
        "doors": doors_out,
        "teleports": teleports_out,
        "coins": coins_out,
        "movingObstacles": moving_obstacles_out,
        "movingWalls": moving_walls_out,
        "parMoves": par_moves,
        "parTimeSeconds": par_time,
        "timeLimitSeconds": time_limit,
    }


def make_level(spec):
    for attempt in range(MAX_ATTEMPTS):
        rng = random.Random(1000 * spec["id"] + attempt)
        try:
            level = build_level(spec, rng)
        except Unsatisfiable:
            continue
        if verify_solvable(level):
            return level
    raise SystemExit(f"Level {spec['id']}: no valid layout in {MAX_ATTEMPTS} attempts")


def main():
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/levels")
    out_dir.mkdir(parents=True, exist_ok=True)
    for spec in LEVEL_SPECS:
        level = make_level(spec)
        path = out_dir / f"level_{spec['id']:02d}.json"
        path.write_text(json.dumps(level, indent=2) + "\n")
        print(f"level {spec['id']:02d}: {level['width']}x{level['height']} "
              f"par {level['parMoves']} moves / {level['parTimeSeconds']}s, limit {level['timeLimitSeconds']}s")


if __name__ == "__main__":
    main()
