# Compactness of [a, b] -- the check behind the card.  Standard library only.
# Part 1, Bolzano-Weierstrass: halve [-2, 2] and keep a half that still holds the list's
# far terms, then pick ever-later terms.  Part 2, Heine-Borel: walk right along [0, 1],
# each step jumping to the farthest right end of a cover set that holds the current point.
M = 10 ** 6                                         # far terms x_{M+1}, x_{M+2} witness "infinitely many"

def x(n):
    return (-1) ** n * (1 + 1 / n)

def holds_far_terms(lo, hi):
    return any(lo <= x(n) <= hi for n in (M + 1, M + 2))

lo, hi, n, kept, picks = -2.0, 2.0, 0, [], []
for stage in range(21):
    if stage > 0:                                   # halve; keep the left half if it still qualifies
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if holds_far_terms(lo, mid) else (mid, hi)
    n += 1
    while not lo <= x(n) <= hi:                     # first term later than the last pick
        n += 1
    kept.append((lo, hi))
    picks.append(n)
print("x_1 to x_6:", " ".join(f"{x(k):.6f}" for k in range(1, 7)))
print("kept halves:", " ".join(f"[{a:g}, {b:g}]" for a, b in kept[:7]))
print("picks n:", " ".join(str(k) for k in picks[:7]), " values:", " ".join(f"{x(k):.6f}" for k in picks[:7]))
print(f"stage 20: kept [{lo:.6f}, {hi:.6f}], width {hi - lo:.6f}, pick n = {n}, x_n = {x(n):.6f}")
road2 = all(n % 2 == 1 and abs(x(n) + 1 - (-1 / n)) < 1e-12 for n in picks)   # odd terms sit 1/n below -1
inside = all(abs(x(k) + 1) <= b - a for k, (a, b) in zip(picks[2:], kept[2:]))
print(f"every pick is an odd term, 1/n below -1: {'yes' if road2 else 'no'}; within its half's width of -1: {'yes' if inside else 'no'}")

cover = [(-0.1, 0.1)] + [(1 / k, 2.0) for k in range(1, 1001)]
point, used = 0.0, []
while point <= 1.0:                                 # the supremum walk: reach as far right as one set allows
    best = max((s for s in cover if s[0] < point < s[1]), key=lambda s: s[1])
    used.append(best)
    point = best[1]
print("walk on [0, 1]: from 0 via " + ", then ".join(f"({a:.6g}, {b:g})" for a, b in used) + f": {len(used)} sets")
print(f"0.1 is not where the walk stops: (1/11, 2) holds it with room {0.1 - 1 / 11:.6f} on its left")
grid = all(any(a < k / 100000 < b for a, b in used) for k in range(100001))
print(f"those {len(used)} sets hold all 100001 points k/100000 of [0, 1]: {'yes' if grid else 'no'}")
miss = [next(1 / m for m in range(1, N + 2) if not any(1 / k < 1 / m < 2 for k in range(1, N + 1))) for N in (10, 100, 1000)]
print("(0, 1], first N sets (1/n, 2) for N = 10, 100, 1000 miss", ", ".join(f"{v:g}" for v in miss) + "; x_n = 1/n heads for 0, outside")
far = [next(m for m in range(N + 2) if not any(-1 < m < k for k in range(1, N + 1))) for N in (10, 100, 1000)]
print("[0, infinity), first N sets (-1, n) miss", ", ".join(map(str, far)) + "; x_n = n: neighbours 1 apart, nothing settles")
print(f"mistake, the whole list: x_1000 = {x(1000):.6f}, x_1001 = {x(1001):.6f}, gap {x(1000) - x(1001):.6f}")
first = sum(1 for k in range(1, M + 1) if -2 <= x(k) <= -1.5)
print(f"mistake, keep a half holding any term: [-2, -1.5] holds {first} of the first {M} terms")
assert kept[3] == (-1.5, -1.0) and picks[:7] == [1, 3, 5, 7, 9, 11, 17]        # halving as the card says
assert road2 and inside and abs(x(n) + 1) <= hi - lo                            # picks settle on -1
assert len(used) == 2 and grid and used[1][0] < used[0][1]                      # two sets cover [0, 1]
assert miss == [0.1, 0.01, 0.001] and far == [10, 100, 1000] and first == 1  # failures
print("ALL CHECKS PASS")
