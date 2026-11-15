# Banach algebras and the Gelfand transform -- the check behind the card.  Nothing
# is imported.  The algebra is C[0, 24]: continuous price curves over one day,
# sized by their largest absolute value.  The curve is p(t) = 30 + (t - 12)^2 / 2
# in pounds per MWh (illustrative).  Every computation is a grid of N points.
def p(t): return 30 + (t - 12) ** 2 / 2
def grid(n): return [24 * k / (n - 1) for k in range(n)]
def sup(f): return max(abs(v) for v in f)
print("chart, p at 0,2,..,24 h: " + " ".join(f"{p(t):g}" for t in range(0, 25, 2)))
print("spectrum of p, exact: [30, 102]")
for n in (25, 241, 2401):                       # road 2: the grid's values
    vals = sorted(set(round(p(t), 9) for t in grid(n)))
    gap = max(b - a for a, b in zip(vals, vals[1:]))
    print(f"grid N={n:>5}: min {vals[0]:.4f}, max {vals[-1]:.4f}, "
          f"{len(vals)} values, largest gap {gap:.5f}")
    assert vals[0] == 30 and vals[-1] == 102 and gap < 12 * 24 / (n - 1)
def neumann(lam, n=2401):                       # road 3: invert p - lam by algebra
    g = [p(t) - lam for t in grid(n)]
    best = min((sup([1 - c * v for v in g]), c) for c in (1 / sup(g), -1 / sup(g)))
    q, c = best
    if q >= 1: return q, None, 0
    inv, term, k = [c] * n, [c] * n, 0          # c * sum of (1 - c g)^k
    while sup(term) > 1e-14 and k < 5000:
        term = [a * (1 - c * v) for a, v in zip(term, g)]
        inv = [a + b for a, b in zip(inv, term)]; k += 1
    assert sup([a * v - 1 for a, v in zip(inv, g)]) < 1e-12   # g times inverse is 1
    return q, inv, k
for lam, dist in ((20, 10), (110, 8)):
    q, inv, k = neumann(lam)
    print(f"lambda={lam}: |1 - c g| = {q:.6f} < 1, {k} terms, "
          f"|inverse| = {sup(inv):.6f}, 1/{dist} = {1 / dist:.6f}")
    assert abs(sup(inv) - 1 / dist) < 1e-9
q, inv, k = neumann(80)
def root(f, a, b):                              # bisection, written out
    for _ in range(60):
        m = (a + b) / 2
        a, b = (m, b) if f(a) * f(m) > 0 else (a, m)
    return (a + b) / 2
r1, r2 = root(lambda t: p(t) - 80, 0, 12), root(lambda t: p(t) - 80, 12, 24)
print(f"lambda=80: best |1 - c g| = {q:.6f}, no series; p = 80 at t = {r1:.6f} and {r2:.6f}")
assert inv is None and abs(r1 - 2) < 1e-9 and abs(r2 - 22) < 1e-9
s = 2 ** 0.5
print(f"lambda=31: true crossings t = {12 - s:.6f} and {12 + s:.6f}; min |p - 31| on the grid:")
mins = [min(abs(p(t) - 31) for t in grid(n)) for n in (25, 241, 2401, 24001)]
print("  N = 25, 241, 2401, 24001: " + ", ".join(f"{m:.6f}" for m in mins))
print("  so the grid's inverse has size " + ", ".join(f"{1 / m:.1f}" for m in mins))
assert mins[0] == 0.5 and mins[-1] < 1e-3 and abs(root(lambda t: p(t) - 31, 0, 12) - (12 - s)) < 1e-9
# The rehearsal: C^4, prices at 0, 6, 12 and 18 h, multiplied place by place.
x4 = [p(t) for t in (0, 6, 12, 18)]
w_set = (-1, -0.5, 0, 0.5, 1, 2)
cands = [(a, b, c, d) for a in w_set for b in w_set for c in w_set for d in w_set]
def is_char(w):                                 # chi(1) = 1, chi(e_i e_j) = chi(e_i) chi(e_j)
    return sum(w) == 1 and all((w[i] if i == j else 0) == w[i] * w[j]
                               for i in range(4) for j in range(4))
chars = sorted((w for w in cands if is_char(w)), reverse=True)
cv = [sum(a * b for a, b in zip(w, x4)) for w in chars]
print(f"C^4 rehearsal: {len(cands)} candidate weightings, {len(chars)} characters, "
      f"values on the price list {', '.join(f'{v:g}' for v in cv)}")
assert len(chars) == 4 and chars == [tuple(int(i == k) for i in range(4)) for k in range(4)]
spec4 = sorted(set(lam for lam in range(0, 201) if any(v - lam == 0 for v in x4)))
print(f"C^4 spectrum of the list (lambda with a zero coordinate): {', '.join(map(str, spec4))}")
def simpson(f, n=2400):                         # the day's average, by Simpson's rule
    h = 24 / n
    s2 = f(0) + f(24) + sum((4 if k % 2 else 2) * f(k * h) for k in range(1, n))
    return s2 * h / 3 / 24
m1, m2 = simpson(p), simpson(lambda t: p(t) ** 2)
print(f"daily average: mean p = {m1:.4f}, mean p^2 = {m2:.4f}, (mean p)^2 = {m1 * m1:.4f}, "
      f"gap {m2 - m1 * m1:.4f}")
assert abs(m1 - 54) < 1e-9 and abs(m2 - 3376.8) < 1e-6
print(f"evaluation at 5 h: p(5) = {p(5):.1f}, inside [30, 102]")
g1 = min((p(t) - 80) ** 2 + (t - 12) ** 2 for t in grid(240001))
g2 = min(((p(t) - 80) ** 2 + (t - 2) ** 2, t) for t in grid(2401))
print(f"ideal of p-80 and t-12: min of the sum of squares {g1:.4f} > 0, so it holds 1")
print(f"ideal of p-80 and t-2: min of the sum of squares {g2[0]:.4f} at t = {g2[1]:.4f}")
assert abs(g1 - 99) < 1e-6 and g2[0] == 0 and g2[1] == 2
# A commuting algebra that is not functions: a I + b J, J swapping two hours.
def mul(x, y): return [[sum(x[i][k] * y[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
I2, J = [[1, 0], [0, 1]], [[0, 1], [1, 0]]
def ab(a, b): return [[a, b], [b, a]]
def chi(x, s): return x[0][0] + s * x[0][1]     # a candidate character: a I + b X -> a + s b
svals = [k / 100 for k in range(-300, 301)]     # keep s only if chi(J J) = chi(J)^2 on the product
jvals = [s for s in svals if abs(chi(mul(J, J), s) - chi(J, s) ** 2) < 1e-9]
print(f"J^2 = I: {str(mul(J, J) == I2).lower()}; characters send J to {jvals[0]:g} and {jvals[1]:g}")
hat = lambda a, b: (a + b, a - b)               # the Gelfand transform
B = (0.8, 0.2); bh = hat(*B); ih = (1 / bh[0], 1 / bh[1])
inv = ((ih[0] + ih[1]) / 2, (ih[0] - ih[1]) / 2)
res = mul(ab(*B), ab(*inv))
print(f"blur 0.8I+0.2J: transform ({bh[0]:.1f}, {bh[1]:.1f}); inverse "
      f"{inv[0]:.6f} I {inv[1]:+.6f} J; product {res[0][0]:.6f} {res[0][1]:.6f}")
assert abs(res[0][0] - 1) < 1e-12 and abs(res[0][1]) < 1e-12 and jvals == [-1, 1]
ah, M = hat(0.5, 0.5), ab(0.5, 0.5)
detM = M[0][0] * M[1][1] - M[0][1] * M[1][0]
print(f"average 0.5I+0.5J: transform ({ah[0]:.1f}, {ah[1]:.1f}), determinant {detM:.2f}")
def norm(x): return max(abs(r[0]) + abs(r[1]) for r in x)   # largest row sum
T, Z = [[1, 1], [0, 1]], [[0, 1], [0, 0]]
pw, out = I2, []
for n in range(1, 101):
    pw = mul(pw, T)
    if n in (1, 10, 100): out.append(f"{norm(pw) ** (1 / n):.6f}")
    assert norm(pw) == n + 1                    # |T^n| = n + 1, by the binomial rule
nvals = [s for s in svals if abs(chi(mul(Z, Z), s) - chi(Z, s) ** 2) < 1e-9]   # chi(Z Z) = chi(Z)^2
print(f"|Z| = {norm(Z)}, |Z^2| = {norm(mul(Z, Z))}, every character sends Z to {nvals[0]:g}")
print(f"|T^n|^(1/n) for T = I + Z, n = 1, 10, 100: {', '.join(out)}; spectral radius 1")
R = [[0, -1], [1, 0]]                           # rotation; det(R - lambda) from its entries
dets = min((R[0][0] - l) * (R[1][1] - l) - R[0][1] * R[1][0] for l in [k / 100 for k in range(-1000, 1001)])
print(f"rotation over the reals: min det(R - lambda) = {dets:.4f}, real spectrum empty")
assert norm(mul(Z, Z)) == 0 and nvals == [0] and ah[1] == 0 and detM == 0 and dets == 1
print("ALL CHECKS PASS")
