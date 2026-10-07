# Congruent triangles -- the check behind the card.  Nothing is imported.
# A double gate, metres.  Left brace triangle: corner hole A, rail hole B,
# stile hole C.  The right leaf D, E, F is built by ASA and by RHS, then
# compared with the left leaf flipped over.  SSA and AAA are shown failing.
A, B, C = (0.0, 0.0), (1.5, 0.0), (0.0, 0.8)
D, E = (3.2, 0.0), (1.7, 0.0)          # right corner hole and rail hole

def dist(p, q):                        # the distance formula on the grid
    return ((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2) ** 0.5

def bisect(f, lo, hi):                 # a root of f between lo and hi, by halving
    for _ in range(200):
        mid = (lo + hi) / 2
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return (lo + hi) / 2

brace = dist(B, C)
dot = (B[0] - A[0]) * (C[0] - A[0]) + (B[1] - A[1]) * (C[1] - A[1])   # 0 means a square corner
print(f"left leaf: rail {dist(A, B):.3f} stile {dist(A, C):.3f} brace {brace:.3f}, corner dot product {dot:.3f}")
print(f"SAS right leaf, 1.500 and 0.800 at a square corner: brace {dist(E, (D[0], 0.8)):.3f}")
u = (-(C[0] - B[0]), C[1] - B[1])      # ASA: bevel gauge copies the brace line, mirrored
t = (D[0] - E[0]) / u[0]               # run along it until it meets the right stile
F = (E[0] + t * u[0], E[1] + t * u[1])
print(f"ASA right leaf, bevel copy at rail hole: stile hole {F[1]:.3f} up, brace {dist(E, F):.3f}")
flip = [(3.2 - x, y) for (x, y) in (A, B, C)]   # rigid motion: turn the left leaf over
miss = max(dist(p, q) for p, q in zip(flip, (D, E, F)))
print(f"flipped left leaf vs ASA-built right leaf: largest hole miss {miss:.3f}")
print(f"SSS spacings right leaf: {dist(D, E):.3f} {dist(D, F):.3f} {dist(E, F):.3f}")
h = bisect(lambda y: dist(E, (D[0], y)) - brace, 0.0, brace)
print(f"RHS search up the stile for a {brace:.3f} brace: {h:.3f}")
assert miss < 1e-12                    # ASA construction lands on the flipped holes
assert abs(dist(E, F) - brace) < 1e-12 # the transferred brace length
assert abs(h - dist(A, C)) < 1e-9      # RHS search returns the left stile spacing
# SSA: angle at B, rail BA = 1.5, stile hole 0.8 from A; brace length s unknown.
w = ((C[0] - B[0]) / brace, (C[1] - B[1]) / brace)
p = (B[0] - A[0]) * w[0] + (B[1] - A[1]) * w[1]
q = dist(A, B) ** 2 - 0.8 ** 2         # s^2 + 2 p s + q = 0
roots = sorted([-p - (p * p - q) ** 0.5, -p + (p * p - q) ** 0.5])
print(f"SSA quadratic: braces {roots[1]:.3f} and {roots[0]:.3f}")
print(f"SSA gap from corner hole to brace line: {(dist(A, B) ** 2 - p * p) ** 0.5:.3f}")
g = lambda s: dist(A, (B[0] + s * w[0], B[1] + s * w[1])) - 0.8
scan = [bisect(g, k / 100, (k + 1) / 100) for k in range(300) if (g(k / 100) > 0) != (g((k + 1) / 100) > 0)]
print(f"SSA brute-force scan: braces {scan[1]:.3f} and {scan[0]:.3f}")
assert all(abs(a - b) < 1e-9 for a, b in zip(roots, scan))
Cs = (B[0] + scan[0] * w[0], B[1] + scan[0] * w[1])
print(f"SSA second stile hole: ({Cs[0]:.3f}, {Cs[1]:.3f}), {dist(A, Cs):.3f} from corner")
small = [0.8 * dist(A, B), 0.8 * dist(A, C)]   # AAA: same angles, 0.8 size
sb = dist((small[0], 0.0), (0.0, small[1]))
print(f"AAA copy at 0.8 size: rail {small[0]:.3f} stile {small[1]:.3f} brace {sb:.3f}")
print(f"brace slope {small[1] / small[0]:.3f} vs {C[1] / B[0]:.3f}, brace short by {brace - sb:.3f}")
print(f"rail and stile swapped: rail hole misses by {dist(A, B) - dist(A, C):.3f}")
fig = lambda P: f"{20 + 100 * P[0]:.0f},{200 - 100 * P[1]:.0f}"
print("figure, 100 units per m: " + " ".join(n + " " + fig(P) for n, P in zip("ABCDEF", (A, B, C, D, E, F))))
fig2 = lambda P: f"{60 + 150 * P[0]:.1f},{200 - 150 * P[1]:.1f}"
print("figure2, 150 units per m: " + " ".join(n + " " + fig2(P) for n, P in (("A", A), ("B", B), ("C", C), ("C*", Cs))))
print("ALL CHECKS PASS")
