# Farey fractions and Ford circles -- the check behind the card.  Standard library only.  Order 5 is listed twice.
from math import gcd, sqrt
X = (sqrt(5) - 1) / 2                                # 0.618034, the golden ratio less 1
def farey(n): return sorted({(p, q) for q in range(1, n + 1) for p in range(q + 1) if gcd(p, q) == 1}, key=lambda f: f[0] / f[1])
def by_mediants(n):                                  # road two: 0/1 and 1/1, then mediants only
    fs = [(0, 1), (1, 1)]
    for k in range(2, n + 1): fs = [fs[0]] + [h for (a, b), (c, d) in zip(fs, fs[1:]) for h in ([(a + c, k)] if b + d == k else []) + [(c, d)]]
    return fs
def gap(f, g, s=2):                                  # centre distance and radius sum; radius 1/(s q^2)
    return sqrt((g[0] / g[1] - f[0] / f[1]) ** 2 + (1 / (s * g[1] ** 2) - 1 / (s * f[1] ** 2)) ** 2), 1 / (s * f[1] ** 2) + 1 / (s * g[1] ** 2)
def trap(n):                                         # neighbours around X, then the mediant picks a half
    (a, b), (c, d) = next((f, g) for f, g in zip(farey(n), farey(n)[1:]) if f[0] / f[1] < X < g[0] / g[1])
    p, q = (a, b) if X < (a + c) / (b + d) else (c, d)
    print(f"order {n}: {a}/{b} < {X:.6f} < {c}/{d}, mediant {a + c}/{b + d}, so {p}/{q} is {abs(X - p / q):.5f} off, under 1/({q} x {b + d}) = {1 / (q * (b + d)):.5f} < 1/{q * q} = {1 / q ** 2:.6f}")
    return p, q, abs(X - p / q) < 1 / (q * (b + d)) < 1 / q ** 2
F = farey(5)                                         # road one: every p/q with q <= 5, lowest terms, sorted
print(f"order 5, {len(F)} fractions: " + " ".join(f"{p}/{q}" for p, q in F) + f"; built from mediants: {'same' if by_mediants(5) == F else 'DIFFERENT'}")
print("b x c - a x d: " + " ".join(str(b * c - a * d) for (a, b), (c, d) in zip(F, F[1:])) + "; gaps 1/(b x d): " + " ".join(f"1/{b * d}" for (a, b), (c, d) in zip(F, F[1:])))
print(f"1/3 and 2/5: 2 x 3 - 1 x 5 = {2 * 3 - 1 * 5}, gap {2 / 5 - 1 / 3:.5f} = 1/15; mediant of 1/3 and 1/2: {1 + 1}/{3 + 2}; average {1 * 2 + 1 * 3}/{3 * 2 * 2}; sum {1 * 2 + 1 * 3}/{3 * 2}")
(dist, rsum), (bad, badsum) = gap((1, 3), (2, 5)), gap((1, 3), (2, 5), 1)
print(f"Ford circles at 1/3 and 2/5: radii {1 / 18:.5f} and {1 / 50:.5f}, centres {dist:.5f} apart, radii add to {rsum:.5f}; with radius 1/q^2 they overlap by {badsum - bad:.5f}")
print(f"figure, centre 1/3 ({1 / 3:.5f}, {1 / 18:.5f}), centre 2/5 ({2 / 5:.5f}, {1 / 50:.5f}), touch at ({13 / 34:.5f}, {1 / 34:.5f}) = (13/34, 1/34)")
hits = [trap(5), trap(8)]
near = [(p, q) for q in range(1, 14) for p in range(q + 1) if gcd(p, q) == 1 and abs(X - p / q) < 1 / q ** 2]
print("search, q up to 13, fractions within 1/q^2: " + " ".join(f"{p}/{q}" for p, q in near) + f"; 3/4 misses: {abs(X - 3 / 4):.5f} > 1/16 = {1 / 16:.5f}")
assert by_mediants(30) == farey(30) and all(b * c - a * d == 1 for n in range(1, 31) for (a, b), (c, d) in zip(farey(n), farey(n)[1:]))
assert all(abs(gap(f, g)[0] - gap(f, g)[1]) < 1e-12 for f, g in zip(farey(30), farey(30)[1:])) and gap((1, 4), (1, 2))[0] > gap((1, 4), (1, 2))[1] + 1e-9
assert all(ok and (p, q) in near for p, q, ok in hits) and near == [(0, 1), (1, 1), (1, 2), (2, 3), (3, 5), (5, 8), (8, 13)]
assert abs(1 / 3 + (2 / 5 - 1 / 3) / 18 / dist - 13 / 34) < 1e-12 and abs(1 / 18 - (1 / 18 - 1 / 50) / 18 / dist - 1 / 34) < 1e-12
print("ALL CHECKS PASS")
