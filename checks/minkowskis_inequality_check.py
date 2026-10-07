# Minkowski's inequality -- the check behind the card.  Standard library only.
# Turbine A's week of daily mean wind speeds (m/s) is the shelf's house example;
# turbine B stands 3 km away.  Each week is a function on 7 days.  Roads: the two
# sides computed directly; p = 2 again from whole-number sums and a square root
# written out here; the Hoelder split of the proof; 3000 random SplitMix64 pairs.
INF = float("inf")
A = [3, 5, 8, 2, 6, 4, 7]
B = [5, 2, 4, 6, 1, 3, 2]
S = [a + b for a, b in zip(A, B)]
COUNT, PROB = [1.0] * 7, [1.0 / 7] * 7

def norm(f, p, w=COUNT):                 # (sum of |f|^p times weight)^(1/p); max where p = inf
    if p == INF:
        return max(abs(x) for x, wt in zip(f, w) if wt > 0)
    return sum(abs(x) ** p * wt for x, wt in zip(f, w)) ** (1 / p)

def sqrt_newton(x):                      # square root by Newton's method, written out
    r = x if x > 1 else 1.0
    for _ in range(60):
        r = 0.5 * (r + x / r)
    return r

def splitmix(state):                     # SplitMix64: returns (new state, 64-bit output)
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, z ^ (z >> 31)

def pname(p):
    return "inf" if p == INF else f"{p:g}"

print(f"A = {A}, B = {B}, A + B = {S}  (m/s)")
print("counting measure: p, ||A+B||_p, ||A||_p + ||B||_p, slack, holds")
for p in (0.5, 1, 1.5, 2, 3, 4, INF):
    l, r = norm(S, p), norm(A, p) + norm(B, p)
    print(f"  p = {pname(p):>3}: {l:10.4f} {r:10.4f} {r - l:+9.4f}  {'yes' if l <= r + 1e-12 else 'NO'}")
nA, nB, nS = norm(A, 2), norm(B, 2), norm(S, 2)
print(f"p = 2 parts: ||A|| = {nA:.4f}, ||B|| = {nB:.4f}, ||A+B|| = {nS:.4f}")
sa, sb, dot = sum(a * a for a in A), sum(b * b for b in B), sum(a * b for a, b in zip(A, B))
ss = sa + 2 * dot + sb                   # ||A+B||^2 expanded: no square root taken of it
gap_sq = 2 * (sqrt_newton(sa * sb) - dot)            # (||A||+||B||)^2 - ||A+B||^2
slack2 = gap_sq / (sqrt_newton(sa) + sqrt_newton(sb) + sqrt_newton(ss))
print(f"p = 2 by whole numbers: sum A^2 = {sa}, sum B^2 = {sb}, sum A*B = {dot}, sum (A+B)^2 = {ss}")
print(f"  gap in squares 2(sqrt({sa}*{sb}) - {dot}) = {gap_sq:.4f}; slack = {slack2:.4f}")
print(f"uniform probability 1/7: RMS A = {norm(A, 2, PROB):.4f}, RMS B = {norm(B, 2, PROB):.4f}, "
      f"RMS A+B = {norm(S, 2, PROB):.4f}, sum = {norm(A, 2, PROB) + norm(B, 2, PROB):.4f}")
print(f"  fleet average (A+B)/2: RMS {norm(S, 2, PROB) / 2:.4f} <= mean of RMS {(norm(A, 2, PROB) + norm(B, 2, PROB)) / 2:.4f}")
print(f"  cube-mean p = 3: A {norm(A, 3, PROB):.4f}, B {norm(B, 3, PROB):.4f}, A+B {norm(S, 3, PROB):.4f}")
split = []
for p in (2, 3):                         # the proof's split, with Hoelder on each half
    iA = sum(a * s ** (p - 1) for a, s in zip(A, S))
    iB = sum(b * s ** (p - 1) for b, s in zip(B, S))
    hA, hB = norm(A, p) * norm(S, p) ** (p - 1), norm(B, p) * norm(S, p) ** (p - 1)
    print(f"Hoelder split p = {p}: sum (A+B)^{p} = {sum(s ** p for s in S)} = {iA} + {iB}; "
          f"bounds {hA:.2f} + {hB:.2f}")
    split.append(iA <= hA and iB <= hB)
print(f"p = inf as a limit: ||A||_p at p = 8, 16, 64: "
      + ", ".join(f"{norm(A, p):.4f}" for p in (8, 16, 64)) + f"; max = {norm(A, INF)}")
c = -2.5
cA = [c * a for a in A]
print(f"scaling: ||(-2.5)A||_3 = {norm(cA, 3):.4f}, 2.5 * ||A||_3 = {abs(c) * norm(A, 3):.4f}")
off = [1.0] * 6 + [0.0]                  # day 7 given weight zero: sensor offline
Z = [0, 0, 0, 0, 0, 0, 9]
print(f"weight 0 on day 7: ||{Z}||_2 = {norm(Z, 2, off):.4f}, yet the function is not 0 on day 7")
twice, minus = [2 * a for a in A], [-2 * a for a in A]
print(f"B = 2A: ||A+2A||_2 = {norm([3 * a for a in A], 2):.4f}, ||A|| + ||2A|| = {nA + norm(twice, 2):.4f}")
print(f"B = -2A: ||A-2A||_2 = {norm([-a for a in A], 2):.4f}, ||A|| + ||-2A|| = {nA + norm(minus, 2):.4f}")
print(f"mistake, no root at p = 2: sum (A+B)^2 = {ss} > {sa} + {sb} = {sa + sb}")
print(f"mistake, p = 1/2: {norm(S, 0.5):.4f} > {norm(A, 0.5) + norm(B, 0.5):.4f}")
state, fails, worst = 20260929, {}, {}
ps = (0.5, 1, 1.5, 2, 3, INF)
for _ in range(3000):
    vec = []
    for _ in range(14):
        state, z = splitmix(state)
        vec.append((z >> 33) % 19 - 9)
    f, g = vec[:7], vec[7:]
    h = [x + y for x, y in zip(f, g)]
    for p in ps:
        l, r = norm(h, p), norm(f, p) + norm(g, p)
        if r > 0:
            worst[p] = max(worst.get(p, 0.0), l / r)
            fails[p] = fails.get(p, 0) + (l > r * (1 + 1e-12))
print("3000 random pairs, entries -9..9: p, failures, largest ||f+g|| / (||f|| + ||g||)")
for p in ps:
    print(f"  p = {pname(p):>3}: {fails[p]:4d}  {worst[p]:.6f}")
chart = (0.5, 0.75, 1, 1.5, 2, 3, 4, 8, 16)
print("chart, p:     " + " ".join(f"{p:g}" for p in chart))
print("chart, ratio: " + " ".join(f"{norm(S, p) / (norm(A, p) + norm(B, p)):.2f}" for p in chart))
print("figure, days 1-2 at 20 units per m/s from (40, 200): A tip (100, 100), sum tip (200, 60), "
      f"lengths {norm(A[:2], 2):.3f} + {norm(B[:2], 2):.3f} = {norm(A[:2], 2) + norm(B[:2], 2):.3f} "
      f"vs {norm(S[:2], 2):.3f}")
assert abs((nA + nB - nS) - slack2) < 1e-9           # p = 2 slack: roots of sums vs whole numbers
assert all(split)                                    # Hoelder bounds each half of the split
assert all(fails[p] == 0 for p in ps if p >= 1) and fails[0.5] > 0
assert abs(norm(cA, 3) - 2.5 * norm(A, 3)) < 1e-9       # scaling, list rescaled vs norm rescaled
assert abs(norm(A, 64) - norm(A, INF)) < 1e-3          # large p approaches the sup-norm
assert abs(norm([3 * a for a in A], 2) - (nA + norm(twice, 2))) < 1e-9   # t = 2: equality
assert norm([-a for a in A], 2) < nA + norm(minus, 2) - 1                # t = -2: strict
assert norm(Z, 2, off) == 0                            # size zero, function not zero
print("ALL CHECKS PASS")
