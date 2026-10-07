# Planar graphs and Euler's formula -- the check behind the card.  Nothing is imported.
# The board is a cube drawn flat: outer pads 1 2 3 4, inner pads 5 6 7 8, four spokes.
# Every face is traced from the drawing itself -- the cyclic order of tracks round each
# pad -- and only then met with E - V + 2.  Then the same count on the map's dual graph.
BOARD = {1: [2, 5, 4], 2: [3, 6, 1], 3: [4, 7, 2], 4: [3, 1, 8],
         5: [6, 8, 1], 6: [7, 5, 2], 7: [3, 8, 6], 8: [7, 4, 5]}
WHEEL = {0: [2, 3, 4, 1], 1: [2, 0, 4], 2: [3, 0, 1], 3: [4, 0, 2], 4: [0, 3, 1]}
SEA = {1, 2, 3, 4}                      # which face is unbounded is part of the drawing

def trace(rot):                         # one walk round a face is one face
    out, used = [], set()
    for start in sorted((u, v) for u in rot for v in rot[u]):
        if start in used: continue
        (u, v), face = start, []
        while (u, v) != start or not face:
            used.add((u, v)); face.append(u); u, v = v, rot[v][rot[v].index(u) - 1]
        out.append(face)
    return sorted(out)

def size(rot): return len(rot), sum(len(rot[u]) for u in rot) // 2
def parts(rot):                         # separate pieces: pass the smallest pad name along
    home = {u: u for u in rot}
    for _ in rot: home = {u: min([home[u]] + [home[v] for v in rot[u]]) for u in rot}
    return len(set(home.values()))
def cut(rot, u, v): return {a: [b for b in rot[a] if {a, b} != {u, v}] for a in rot}

V, E = size(BOARD); faces = trace(BOARD)
print(f"the board drawn flat: pads V = {V}, tracks E = {E}, pieces = {parts(BOARD)}")
print(f"road 1, faces traced from the drawing: F = {len(faces)}, sides walked {sum(len(f) for f in faces)} = 2 x {E}\n  {faces}")
print(f"road 2, faces from E - V + 2: F = {E - V + 2}; the roads agree: {'yes' if len(faces) == E - V + 2 else 'no'}")
print(f"V - E + F = {V} - {E} + {len(faces)} = {V - E + len(faces)}")
rot, peeled, fs, chis = BOARD, [], [], []
while True:
    spare = [(u, v) for u in sorted(rot) for v in sorted(rot[u]) if u < v and parts(cut(rot, u, v)) == 1]
    if not spare: break
    (a, b), rot = spare[0], cut(rot, *spare[0])
    peeled.append(f"{a}-{b}"); pv, pe = size(rot); fs.append(len(trace(rot))); chis.append(pv - pe + fs[-1])
tv, te = size(rot)
print(f"peel one cycle track at a time, {len(peeled)} of them: {', '.join(peeled)}")
print(f"  F after each peel: {fs};  V - E + F after each: {chis}")
print(f"what is left is a tree: V = {tv}, E = {te}, F = {len(trace(rot))}, and E = V - 1: {'yes' if te == tv - 1 else 'no'}")
sides = [(tuple(sorted((f[j], f[(j + 1) % len(f)]))), i) for i, f in enumerate(faces) for j in range(len(f))]
border = {e: [i for e2, i in sides if e2 == e] for e, _ in sides}; sea = [i for i, f in enumerate(faces) if set(f) == SEA][0]
reg_e = sum(1 for b in border.values() if sea not in b)
reg_deg = sorted(sum(1 for b in border.values() if i in b and sea not in b) for i in range(len(faces)) if i != sea)
wv, we = size(WHEEL); wf = trace(WHEEL); wheel_deg = sorted(len(WHEEL[u]) for u in WHEEL)
print(f"the dual, one vertex per face: V = {len(faces)}, E = {len(border)}, F from E - V + 2 = {len(border) - len(faces) + 2}, the board's pad count {V}")
print(f"drop the sea vertex: {len(faces) - 1} regions, E = {reg_e}, degrees {reg_deg}")
print(f"the 5-region map graph on its own: V = {wv}, E = {we}, F = {len(wf)}, V - E + F = {wv - we + len(wf)}, degrees {wheel_deg}\n  {wf}")
TWO = dict(BOARD); TWO.update({u + 8: [w + 8 for w in BOARD[u]] for u in BOARD})
two_f = len(trace(TWO)) - 1             # side by side, the two outer faces are one region
for k, (lab, bad) in enumerate((("the outside face forgotten", len(faces) - 1), ("the four corridors read as one ring", 3))):
    print(f"mistake {k + 1}, {lab}: {V} - {E} + {bad} = {V - E + bad}, not 2")
print(f"mistake 3, two boards as one drawing: {2 * V} - {2 * E} + {two_f} = {2 * V - 2 * E + two_f}, and 1 + pieces = {1 + parts(TWO)}")
assert len(faces) == E - V + 2 and sum(len(f) for f in faces) == 2 * E
assert all(c == 2 for c in chis) and fs == [5, 4, 3, 2, 1] and te == tv - 1
assert len(border) == E and len(faces) - 1 == wv and reg_e == we and reg_deg == wheel_deg
assert len(wf) == we - wv + 2 and 2 * V - 2 * E + two_f == 1 + parts(TWO)
print("ALL CHECKS PASS")
