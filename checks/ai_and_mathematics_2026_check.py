# Machines that prove -- the check behind the card.  Standard library only.
# A machine's output is a candidate, not a confirmation.  Six small audits a
# reader can rerun: each recomputes a number by a second, independent road.
import math

def fmt10(x):                           # what a 10-digit calculator shows
    s = str(x); p = str((int(s[:11]) + 5) // 10)
    return f"{p[0]}.{p[1:]}e{len(s) - 1}"
def fpow(a, n):                         # float power by repeated multiplication
    p = 1.0
    for _ in range(n): p *= a
    return p

# 1. The near miss: 1782^12 + 1841^12 against 1922^12, three roads.
L, R = 1782 ** 12 + 1841 ** 12, 1922 ** 12
gap = (fpow(1782.0, 12) + fpow(1841.0, 12) - fpow(1922.0, 12)) / fpow(1922.0, 12)
print("near miss, left  1782^12 + 1841^12 =", L)
print("near miss, right 1922^12           =", R)
print("left minus right                   =", L - R)
print("10-digit calculator shows", fmt10(L), "and", fmt10(R))
print(f"relative gap (floating point)      = {gap:.4e}")
print("last digits", L % 10, "and", R % 10, "; left is", "odd" if L % 2 else "even",
      ", right is", "odd" if R % 2 else "even")
PRIMES = [1000003, 1000033, 1000037]
res = [((pow(1782, 12, p) + pow(1841, 12, p)) % p, pow(1922, 12, p)) for p in PRIMES]
print("residues mod 1000003, 1000033, 1000037:", res)

# 2. Fermat, small cases: search c <= 100.  n = 2 is the control that must hit.
def search(n, top):
    pw = {c ** n: c for c in range(1, top + 1)}
    return [(a, b, pw[a ** n + b ** n]) for a in range(1, top)
            for b in range(a, top) if a ** n + b ** n in pw]
TOP = 100
euclid = 0                              # second road for n = 2: Euclid's formula
for m in range(2, 11):
    for j in range(1, m):
        if (m - j) % 2 == 1 and math.gcd(m, j) == 1:
            euclid += TOP // (m * m + j * j)
hits = {n: len(search(n, TOP)) for n in range(2, 11)}
print(f"solutions of a^n + b^n = c^n with c <= {TOP}, n = 2..10:", list(hits.values()))
print("Euclid's formula count for n = 2:", euclid)
near = min(((abs(a**3 + b**3 - c**3), a, b, c) for a in range(2, TOP) for b in range(a, TOP)
            for c in range(b + 1, 126) if a**3 + b**3 != c**3))
print(f"closest cube miss: {near[1]}^3 + {near[2]}^3 - {near[3]}^3 =",
      near[1]**3 + near[2]**3 - near[3]**3)

# 3. Zeta zeros: the proved lower bounds as percentages, and the 2026 constants.
x = 1 / math.sqrt(2)
s = c = 0.0; t = x; u = 1.0
for k in range(12):                     # sin and cos by their series, written out
    s += t; c += u
    t *= -x * x / ((2 * k + 2) * (2 * k + 3)); u *= -x * x / ((2 * k + 1) * (2 * k + 2))
cinv_series = 0.5 + x * c / s
cinv_tan = 0.5 + x / math.tan(x)
mt, mt_d = 2 - cinv_series, (3 - cinv_series) / 2
for name, v in [("1974 one third", 1 / 3), ("1989 two fifths", 2 / 5), ("2020 five twelfths", 5 / 12),
                ("2026 two thirds", 2 / 3), ("2026 with the MT window", mt)]:
    print(f"zeros on the line, at least {name:<24}{100 * v:8.3f}%  " + "#" * round(50 * v))
print(f"MT window constant: series {mt:.12f}, tangent {2 - cinv_tan:.12f}; distinct {mt_d:.5f}")

# 4. Unit distances in a k by k grid: the commonest distance, two roads.
grid = []
for k in range(2, 9):
    pts = [(i, j) for i in range(k) for j in range(k)]
    cnt = {}
    for p in range(len(pts)):
        for q in range(p + 1, len(pts)):
            d = (pts[p][0] - pts[q][0]) ** 2 + (pts[p][1] - pts[q][1]) ** 2
            cnt[d] = cnt.get(d, 0) + 1
    best = max(cnt.values()); d = min(e for e in cnt if cnt[e] == best)
    rep = sum((k - abs(dx)) * (k - abs(dy)) for dx in range(-k + 1, k)
              for dy in range(-k + 1, k) if dx * dx + dy * dy == d) // 2
    grid.append((k * k, d, best, rep))
    print(f"grid {k}x{k}: n = {k*k:2}, squared distance {d}, pairs = {best:3}, "
          f"by counting vectors {rep:3}, log pairs / log n = {math.log(best) / math.log(k*k):.3f}")
print("unit-distance exponent excess, quoted: 6.24e-38 in the checked write-up, 0.014 claimed in a sharper preprint")

# 5. Finite-time blow-up in one line: y' = y^2, y(0) = 1, exact y = 1/(1 - t).
y, h, step, blow = 1.0, 0.0001, 0, []
for stop in (5000, 9000, 9900, 9990):
    while step < stop:
        k1 = y * y; a = y + h / 2 * k1; k2 = a * a; a = y + h / 2 * k2; k3 = a * a
        a = y + h * k3; k4 = a * a
        y += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4); step += 1
    exact = 1 / (1 - stop * h)
    blow.append((y, exact))
    print(f"blow-up toy at t = {stop * h:.3f}: step by step {y:.6f}, exact 1/(1 - t) {exact:.6f}")

# 6. The audit list.  Fields: statement matched (S), artifact public (A),
#    independent check (C: pass, gap, false or none).  Status is computed, not typed.
def status(S, A, C, kind):
    if C == "false": return "refuted"
    if C == "gap": return "as before"
    if S and A and C == "pass": return kind
    return "claimed"
rows = [("near miss, n = 12", True, True, "pass" if L == R else "false", "proved"),
        ("Fermat formalisation", True, True, "pass", "proved"),
        ("zeta zeros, two thirds", True, True, "none", "proved"),
        ("unit-distance conjecture", True, True, "pass", "refuted"),
        ("Navier-Stokes blow-up", True, True, "none", "proved")]
audit = [status(S, A, C, kind) for _, S, A, C, kind in rows]
for (name, S, A, C, _), st in zip(rows, audit):
    print(f"audit: {name:<26} S={'yes' if S else 'no '} A={'yes' if A else 'no '} C={C:<5} -> {st}")

assert L != R and fmt10(L) == fmt10(R) and L % 2 != R % 2
assert all(r == ((L % p), (R % p)) for r, p in zip(res, PRIMES))
assert hits[2] == euclid == 52 and all(hits[n] == 0 for n in range(3, 11))
assert abs(cinv_series - cinv_tan) < 1e-12 and round(mt, 5) == 0.6725 and round(mt_d, 5) == 0.83625
assert grid[1][2] == 12 and all(g[2] == g[3] for g in grid)
assert all(abs(a / b - 1) < 1e-5 for a, b in blow)
assert audit == ["refuted", "proved", "claimed", "refuted", "claimed"]
print("ALL CHECKS PASS")
