# Conditional expectation on a sigma-algebra -- the check behind the card.
# Standard library only.  One year of monthly rainfall, each month equally
# likely.  G is the season sigma-algebra; E[X | G] is found by two roads that
# share no arithmetic: Radon-Nikodym densities of the positive and negative
# parts, and a brute search that never divides.  Then the coarse "wet season
# or not" sigma-algebra, a date read exactly, and the cases that fail.
from fractions import Fraction as Fr

MONTHS = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split()
RAIN = [30, 24, 45, 60, 75, 100, 95, 75, 55, 40, 25, 36]      # mm in each month
P = Fr(1, 12)                                                   # each month's probability
SEASONS = [("winter", [11, 0, 1]), ("spring", [2, 3, 4]),
           ("summer", [5, 6, 7]), ("autumn", [8, 9, 10])]
WET = [("dry", [8, 9, 10, 11, 0, 1]), ("wet", [2, 3, 4, 5, 6, 7])]

def generated(blocks):              # every union of the blocks: a finite sigma-algebra
    return [frozenset(i for j, (_, b) in enumerate(blocks) if mask >> j & 1 for i in b)
            for mask in range(2 ** len(blocks))]

def integral(f, A):                 # the integral of f over the event A, against P
    return sum((P * f[i] for i in A), Fr(0))

def atoms(events):                  # smallest events: intersect all events holding w
    out = []
    for w in range(12):
        a = frozenset(range(12))
        for e in events:
            if w in e:
                a &= e
        if a not in out:
            out.append(a)
    return out

def measurable(f, events):          # is every set {f <= c} one of the events?
    return "yes" if all(frozenset(i for i in range(12) if f[i] <= c) in events for c in set(f)) else "no"

def rn_forecast(x, events):         # road one: densities of nu+ and nu- against P on G
    pos, neg, one = [max(v, 0) for v in x], [max(-v, 0) for v in x], [1] * 12
    m, parts = [None] * 12, []
    for a in atoms(events):
        hp = integral(pos, a) / integral(one, a)        # d(nu+)/dP on the atom a
        hm = integral(neg, a) / integral(one, a)        # d(nu-)/dP on the atom a
        parts.append((hp, hm))
        for i in a:
            m[i] = hp - hm
    return m, parts

def brute(blocks, events):          # road two: search forecasts 0, 5, ..., 100 per block
    hits = []
    for code in range(21 ** len(blocks)):
        vals, m = [5 * (code // 21 ** j % 21) for j in range(len(blocks))], [0] * 12
        for v, (_, b) in zip(vals, blocks):
            for i in b:
                m[i] = v
        if all(sum(m[i] for i in A) == sum(RAIN[i] for i in A) for A in events):
            hits.append(vals)
    return hits

def f2(q):
    return f"{float(q):.2f}"

G = generated(SEASONS)
M, _ = rn_forecast(RAIN, G)
mean = integral(RAIN, range(12))
Z = [r - mean for r in RAIN]                                    # rainfall anomaly, mm
MZ, zparts = rn_forecast(Z, G)
found = brute(SEASONS, G)
print(f"months {len(RAIN)}, events in the season sigma-algebra {len(G)}, atoms {len(atoms(G))}")
print(f"yearly mean E[X] = {f2(mean)}")
tot = [sum(RAIN[i] for i in b) for _, b in SEASONS + WET]
spring = [Z[i] for i in SEASONS[1][1]]
print(f"totals, mm: winter {tot[0]}, spring {tot[1]}, summer {tot[2]}, autumn {tot[3]}, dry {tot[4]}, "
      f"wet {tot[5]}, year {sum(RAIN)}; P(winter) = {f2(integral([1] * 12, G[1]))}")
print(f"anomaly totals, mm: spring surplus {sum(max(v, 0) for v in spring)}, spring shortfall "
      f"{sum(max(-v, 0) for v in spring)}, year surplus {sum(max(v, 0) for v in Z)}; all sets of months {2 ** 12}")
print("road one, Radon-Nikodym on the atoms: " + ", ".join(
    f"{n} {f2(M[b[0]])}" for n, b in SEASONS))
print(f"anomaly Z = X - {f2(mean)}: nu+(Omega) = {f2(integral([max(v, 0) for v in Z], range(12)))}, "
      f"nu-(Omega) = {f2(integral([max(-v, 0) for v in Z], range(12)))}")
for (n, b), (hp, hm) in zip(SEASONS, zparts):
    print(f"  {n}: h+ = {f2(hp)}, h- = {f2(hm)}, h+ - h- = {f2(hp - hm)}, plus mean = {f2(hp - hm + mean)}")
print(f"road two, brute search over {21 ** 4} forecasts, no division: {len(found)} passes, {found}")
print(f"property 1, E[X | G] is G-measurable: {measurable(M, G)}")
ok = sum(integral(M, A) == integral(RAIN, A) for A in G)
print(f"property 2, integrals match on {ok} of {len(G)} events")
for name, A in (("winter", G[1]), ("wet half", G[6]), ("Omega", G[15])):
    print(f"  {name}: integral of X {f2(integral(RAIN, A))}, of E[X | G] {f2(integral(M, A))}")
low = [MONTHS[i] for i in range(12) if RAIN[i] <= 30]
print(f"candidate X itself: G-measurable {measurable(RAIN, G)}, since {{X <= 30}} = {' '.join(low)}")
flat = [mean] * 12
print(f"candidate constant {f2(mean)}: G-measurable {measurable(flat, G)}, integrals match "
      f"{sum(integral(flat, A) == integral(RAIN, A) for A in G)} of 16; winter "
      f"{f2(integral(flat, G[1]))} against {f2(integral(RAIN, G[1]))}")
G2 = generated(WET)
C, _ = rn_forecast(RAIN, G2)
T, _ = rn_forecast(M, G2)                                        # forecast the forecast
print(f"wet season or not: dry {f2(C[0])}, wet {f2(C[2])}; from the season forecast: "
      f"dry {f2(T[0])}, wet {f2(T[2])}; brute search {brute(WET, G2)}")
print("figure, rain " + " ".join(str(r) for r in RAIN))
print("figure, season forecast " + " ".join(f"{float(v):g}" for v in M))
print("figure, wet-or-not forecast " + " ".join(f"{float(v):g}" for v in C))

def r(u):                            # season forecast read off an exact date u in [0, 1)
    return [30, 60, 90, 40][min(int(u * 4), 3)]

def grid(a, b, nv=50):               # integral of X(u, v) = r(u) * 2v over [a, b) x [0, 1)
    nu, s = round((b - a) * 400), 0.0
    for i in range(nu):
        u = a + (b - a) * (i + 0.5) / nu
        for j in range(nv):
            s += r(u) * 2 * (j + 0.5) / nv
    return s * (b - a) / nu / nv

def exact(a, b):                     # integral of the candidate r(u) over [a, b)
    cuts = sorted({a, b} | {c for c in (0.25, 0.5, 0.75) if a < c < b})
    return sum(r((p + q) / 2) * (q - p) for p, q in zip(cuts, cuts[1:]))

rows = [(a, b, grid(a, b), exact(a, b)) for a, b in ((0.0, 0.1), (0.2, 0.3), (0.45, 0.8))]
for a, b, g, e in rows:
    print(f"date in [{a}, {b}): integral of X {g:.4f}, of r(U) {e:.4f}")
print("exact date U = 0.5: P(U = 0.5) = 0, so the partition rule asks for 0/0")
sums, acc, absacc = [], Fr(0), Fr(0)
for n in range(1, 7):                # X(n) = (-2)^n with probability 2^-n
    acc += Fr((-2) ** n, 2 ** n)
    absacc += Fr(2 ** n, 2 ** n)
    sums.append(int(acc))
print(f"no integrability: partial sums of E[X] {sums}; of E|X| up to {int(absacc)} and rising")

assert found == [[30, 60, 90, 40]] and [M[b[0]] for _, b in SEASONS] == found[0]
assert [MZ[b[0]] + mean for _, b in SEASONS] == found[0]            # signed road agrees
assert [C[0], C[2]] == [T[0], T[2]] == [35, 75] and brute(WET, G2) == [[35, 75]]
assert all(abs(g - e) < 1e-9 for _, _, g, e in rows)
assert measurable(M, G) == "yes" and measurable(RAIN, G) == "no" and integral(flat, G[1]) != integral(RAIN, G[1])
assert ok == len(G) and sum(integral(flat, A) == integral(RAIN, A) for A in G) == 2
print("ALL CHECKS PASS")
