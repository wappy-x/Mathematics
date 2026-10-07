# Absolutely continuous and singular measures -- the check behind the card.
# Standard library only.  Five dice on the faces 1 to 6, every one of the 64
# sets of faces tested against the definitions and, by a second road, against
# a comparison of which faces carry weight.  Then the epsilon-delta form on a
# countable space, a density on the line by two integrals, and Cantor stages.
from fractions import Fraction as Fr

DICE = {"P": [Fr(1, 6)] * 6,                            # fair
        "Q": [Fr(1, 10)] * 4 + [Fr(2, 10), Fr(4, 10)],  # loaded
        "R": [Fr(1, 5)] * 5 + [Fr(0)],                  # never shows 6
        "T": [Fr(0)] + [Fr(1, 5)] * 5,                  # never shows 1
        "D": [Fr(0)] * 5 + [Fr(1)]}                     # always shows 6

def size(w, A):                          # A is a bit pattern: bit k-1 = face k
    return sum(w[k] for k in range(6) if A >> k & 1)

def ac(nu, mu):                          # road one: every mu-null set is nu-null
    return all(size(nu, A) == 0 for A in range(64) if size(mu, A) == 0)

def sing(nu, mu):                        # road one: some S with mu(off S) = 0 = nu(S)
    return any(size(mu, 63 ^ S) == 0 and size(nu, S) == 0 for S in range(64))

def faces(w):                            # road two: the faces that carry weight
    return {k + 1 for k in range(6) if w[k] > 0}

def verdict(a, b):
    x, y = DICE[a], DICE[b]
    if sing(x, y): return "mutually singular"
    if ac(x, y) and ac(y, x): return "equivalent"
    if ac(x, y): return f"{a} << {b} only"
    if ac(y, x): return f"{b} << {a} only"
    return "neither"

print("face weights, faces 1 to 6; faces with weight; count of null sets out of 64")
for n, w in DICE.items():
    nulls = sum(1 for A in range(64) if size(w, A) == 0)
    print(f"{n}: {' '.join(f'{float(p):.4f}' for p in w)}; {sorted(faces(w))}; {nulls}")
agree, table = True, []
for i, a in enumerate(DICE):
    for b in list(DICE)[i + 1:]:
        x, y = DICE[a], DICE[b]
        agree &= ac(x, y) == (faces(x) <= faces(y)) and ac(y, x) == (faces(y) <= faces(x))
        agree &= sing(x, y) == (not faces(x) & faces(y))
        table.append(verdict(a, b))
        print(f"{a} and {b}: {table[-1]}")
print(f"definition over 64 sets agrees with the face comparison: {'yes' if agree else 'no'}")
f = [q / p for q, p in zip(DICE["Q"], DICE["P"])]
print(f"density of Q against P: {' '.join(f'{float(v):.2f}' for v in f)}")
print(f"Q(5 or 6) as the integral of f against P: {float((f[4] + f[5]) / 6):.4f}")
print(f"P(6) = {float(DICE['P'][5]):.4f}, R(6) = {float(DICE['R'][5]):.4f}, Q(6) = {float(DICE['Q'][5]):.4f}")
dens_ok = all(ac([g // 3 ** k % 3 * r for k, r in enumerate(DICE["R"])], DICE["R"])
              for g in range(729))
print(f"all 729 densities with values 0, 1, 2 give measures << R: {'yes' if dens_ok else 'no'}")

# epsilon-delta on the counting numbers: mu(n) = 1/2^n, nu(n) = 1/(n(n+1))
eps, delta = Fr(1, 10), Fr(1, 2 ** 10)
best = max(sum(Fr(1, n * (n + 1)) for n in range(1, 17) if A >> (n - 1) & 1)
           for A in range(1 << 16)
           if sum(Fr(1, 2 ** n) for n in range(1, 17) if A >> (n - 1) & 1) < delta)
best += Fr(1, 17)                        # nu of 17, 18, 19, ... together
print(f"searched {1 << 16} sets of the numbers 1 to 16; weight beyond 16: 1/17")
print(f"eps 0.1, delta 1/1024: sup of nu(A) over mu(A) < delta, by search {float(best):.4f}, "
      f"by telescoping 1/11 = {1 / 11:.4f}")
for n in (10, 20):
    print(f"infinite nu (counting): mu({n}) = 1/{2 ** n}, nu({n}) = 1")

def ex(x):                               # e^x by its series, written out here
    total, term = 0.0, 1.0
    for k in range(1, 40):
        total, term = total + term, term * x / k
    return total

def simpson(g, a, b, m=200):
    h = (b - a) / m
    return h / 3 * sum((1 if j in (0, m) else 4 if j % 2 else 2) * g(a + j * h)
                       for j in range(m + 1))

print("bus waits: d, E1[0,d] = 1 - e^-d, E2[0,d] closed form, E2 by Simpson, bound 2d")
gap, below, chart = 0.0, True, [[], [], []]
for d in (0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5):
    e1, e2 = 1 - ex(-d), 1 - ex(-2 * d)
    for row, v in zip(chart, (2 * d, e2, e1)):
        row += [f"{v:.2f}"] if d > 0.01 else []
    s2 = simpson(lambda x: 2 * ex(-2 * x), 0.0, d)
    gap, below = max(gap, abs(e2 - s2)), below and e1 <= d and e2 <= 2 * d
    print(f"{d:.2f}, {e1:.4f}, {e2:.4f}, {s2:.4f}, {2 * d:.2f}")

print("chart, d = 0.05 to 0.5; 2d, E2, E1 to two places: " + "; ".join(", ".join(r) for r in chart))
print("point mass at 6 on the line: lambda({6}) <= 2h, D({6}) = 1")
for h in (0.1, 0.001):
    print(f"h = {h}: interval length {2 * h}")
def overlap(a, b):                      # length of [a, b] inside [0, 1]
    return max(0.0, min(b, 1.0) - max(a, 0.0))
m6, m01 = 0.5 * 1 + 0.5 * overlap(6, 6), 0.5 * 0 + 0.5 * overlap(0, 1)
print(f"M = half D plus half length on [0, 1]: M({{6}}) = {m6:.1f}, length({{6}}) = {overlap(6, 6):.1f}, M([0, 1]) = {m01:.1f}")

print("Cantor stages: n, intervals, total length by list, (2/3)^n, kappa per interval")
stage, cantor_ok = [(Fr(0), Fr(1))], True
for n in range(1, 11):
    stage = [iv for a, b in stage for iv in ((a, a + (b - a) / 3), (b - (b - a) / 3, b))]
    total = sum(b - a for a, b in stage)
    cantor_ok &= total == Fr(2, 3) ** n
    if n in (1, 2, 5, 10):
        print(f"{n}, {len(stage)}, {float(total):.4f}, {(2 / 3) ** n:.4f}, 1/{2 ** n}")
print("figure, bars 100 px per unit on baselines y=70,140,210; x=110+40(k-1), width 24; "
      "P 16.67 px, Q 10,10,10,10,20,40 px, R 20 px and none at face 6")

assert agree                                               # two roads, 20 verdicts
assert table[:4] == ["equivalent", "R << P only", "T << P only", "D << P only"]
assert "mutually singular" in table and table.count("neither") == 1
assert f == [Fr(3, 5)] * 4 + [Fr(6, 5), Fr(12, 5)]        # density against the hand values
assert dens_ok and best == Fr(1, 11)                       # density; search against telescoping
assert best < eps                                          # delta 1/1024 meets eps 0.1
assert gap < 1e-9 and below and cantor_ok                  # two integrals; stages
