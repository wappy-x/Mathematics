# The circle's fundamental group -- the check behind the card.  Standard library
# only.  Metres.  A lamp post at (0, 0); a dog on a lead starts and ends at (2, 0).
# A loop is a list of pieces; a piece turns a*s + c*sin(2 pi k s) turns round the
# post as s runs 0 to 1, at distance 2 + r*sin(2 pi 5 s), run backwards if rev.
# Three roads to the number of turns: lift the loop by adding small turns (atan2);
# read 8 compass sectors by atan2, then walk and cancel steps in integers only;
# and the contour integral of dz/z, divided by 2 pi i, from the winding-number card.
import math
TAU, N = 2 * math.pi, 2000                  # N samples per piece

def clean(x): return 0.0 if abs(x) < 5e-7 else x
def piece_at(p, s):
    a, c, k, r, rev = p
    s = 1 - s if rev else s
    turns, dist = a * s + c * math.sin(TAU * k * s), 2 + r * math.sin(TAU * 5 * s)
    return (dist * math.cos(TAU * turns), dist * math.sin(TAU * turns))
def points(loop, n=N):                      # run the pieces one after the other
    pts = [piece_at(loop[0], 0.0)]
    for p in loop:
        pts += [piece_at(p, j / n) for j in range(1, n + 1)]
    return pts
def lift(pts):                              # road 1: add up each small step's turn
    out, big = [0.0], 0.0
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        step = math.atan2(x1 * y2 - y1 * x2, x1 * x2 + y1 * y2) / TAU
        out.append(out[-1] + step)
        big = max(big, abs(step))
    return out, big
def compass(pts):                           # road 2: sectors 0..7, east in the middle of 0
    secs = [math.floor(8 * math.atan2(y, x) / TAU + 0.5) % 8 for x, y in pts]
    word, rays = [], []
    for k1, k2 in zip(secs, secs[1:]):
        d = (k2 - k1 + 4) % 8 - 4
        assert abs(d) <= 1                  # samples close enough: one sector at a time
        if d: word.append(d)
        if {k1, k2} == {7, 0}: rays.append(d)   # crossing the ray 1/16 turn south of east
    stack = []
    for d in word:                          # cancel a step and its undo
        if stack and stack[-1] == -d: stack.pop()
        else: stack.append(d)
    return word, stack, rays
def contour(pts):                           # road 3: trapezoid sum of dz/z, over 2 pi i
    s = sum((1 / complex(*u) + 1 / complex(*v)) / 2 * (complex(*v) - complex(*u)) for u, v in zip(pts, pts[1:]))
    return s / (TAU * 1j)
def circle(h): return [(math.cos(TAU * x), math.sin(TAU * x)) for x in h]

ALPHA, BETA = (2, 0.15, 3, 0.5, False), (3, 0.1, 2, 0.4, False)
def back(p): return p[:4] + (not p[4],)
loops = [("alpha, 2 turns", [ALPHA], 2), ("beta, 3 turns", [BETA], 3),
         ("alpha then beta", [ALPHA, BETA], 5), ("beta then alpha", [BETA, ALPHA], 5),
         ("beta reversed", [back(BETA)], -3), ("beta then alpha reversed", [BETA, back(ALPHA)], 1),
         ("beta then beta reversed", [BETA, back(BETA)], 0)]
print("post at (0, 0) m; the dog starts and ends at (2, 0) m")
for name, loop, hand in loops:
    pts = points(loop)
    L, big = lift(pts)
    word, red, rays = compass(pts)
    w = contour(pts)
    print(f"{name}: lift ends at {clean(L[-1]):.6f}; compass steps {len(word)}, net {sum(word)} = "
          f"{sum(word) // 8} x 8; after cancelling {len(red)} steps; integral {clean(w.real):.3f}")
    assert round(L[-1]) == hand and abs(L[-1] - hand) < 1e-9 and big < 0.25        # road 1 = hand count
    assert sum(word) == 8 * hand and len(red) == 8 * abs(hand) and len(set(red)) <= 1  # road 2: pure laps
    assert abs(w.real - hand) < 1e-3                                                # road 3 agrees
    if name == "alpha then beta":
        print(f"biggest single step of the lift: {big:.6f} turn (it must stay under 1/2)")
        print("chart, lift of alpha then beta at s = 0, 0.1, ..., 1:",
              ", ".join(f"{clean(L[2 * N * i // 10]):.3f}" for i in range(11)))
    if name == "alpha, 2 turns":
        designed = [2 * s + 0.15 * math.sin(TAU * 3 * s) for s in (j / N for j in range(N + 1))]
        gap = max(abs(u - v) for u, v in zip(L, designed))
        print(f"lift against the designed angle at {N + 1} samples: largest gap under 1e-9: {'yes' if gap < 1e-9 else 'no'}")
        assert gap < 1e-9                                                           # the lift is the angle
        stages = [lift(circle([(1 - u / 10) * x + u / 10 * 2 * j / N for j, x in enumerate(L)]))[0][-1]
                  for u in range(11)]
        print("slide alpha to the plain loop s -> 2s turns, 11 stages, each re-lifted:",
              " ".join(f"{round(e)}" for e in stages))
        assert all(abs(e - 2) < 1e-9 for e in stages)                               # the count never moves
    if name == "beta then beta reversed":
        ends = [lift(circle([(1 - u / 10) * x for x in L]))[0][-1] for u in range(11)]
        print("shrink it to the start, 11 stages, each re-lifted:", " ".join(f"{round(clean(e))}" for e in ends))
        assert all(abs(e) < 1e-9 for e in ends)
ok = 0
for m in range(-3, 4):
    for n in range(-3, 4):
        e = lift(points([(m, 0, 0, 0, False), (n, 0, 0, 0, False)]))[0][-1]
        ok += abs(e - (m + n)) < 1e-9
print(f"plain loops m then n, m and n from -3 to 3: count is m + n in {ok} of 49 cases")
assert ok == 49
five = points([(5, 0, 0, 0, False)])
print(f"mistake 1, 5 turns read by the final angle only: {clean(math.atan2(five[-1][1], five[-1][0]) / TAU):.6f} turns, not 5")
coarse = lift(points([(5, 0, 0, 0, False)], 8))[0][-1]
print(f"mistake 2, 5 turns sampled at 8 points: each step 5/8 turn reads as -3/8; total {coarse:.6f}, not 5")
rays = compass(points([BETA, back(ALPHA)]))[2]
print(f"mistake 3, beta then alpha reversed, ray crossings counted without sign: {len(rays)}, not {sum(rays)}")
part = lift(points([ALPHA])[: 7 * N // 8 + 1])[0][-1]
print(f"mistake 4, alpha stopped at s = 0.875, not closed: lift ends at {part:.6f}, no whole number")
assert abs(coarse + 3) < 1e-9 and sum(rays) == 1 and len(rays) == 5 and abs(part - round(part)) > 0.1
print("ALL CHECKS PASS")
