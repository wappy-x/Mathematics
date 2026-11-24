# Galton-Watson branching -- the check behind the card.  Standard library only.
# Each person has 0, 1 or 2 children with chances 1/4, 1/4, 1/2; Z_n people in
# generation n, Z_0 = 1.  f(s) = 1/4 + s/4 + s^2/2.  Roads: the factorised fixed-
# point equation, the iteration q_n = f(q_{n-1}), the exact law of Z_n by
# convolution, and a seeded SplitMix64 simulation of 10,000 families.
from fractions import Fraction as F
from math import sqrt
LAW = (F(1, 4), F(1, 4), F(1, 2))
m = sum(k * p for k, p in enumerate(LAW))
var = sum(k * k * p for k, p in enumerate(LAW)) - m * m
def f(p, s): return p[0] + p[1] * s + p[2] * s * s
def q_iter(p, n, s=0.0):                 # road 2: P(Z_n = 0) = f(f(...f(0)))
    for _ in range(n): s = f(p, s)
    return s
def q_closed(p):                         # road 1: p2 s^2 + (p1-1) s + p0 = (s-1)(p2 s - p0)
    return min(F(1), p[0] / p[2]) if p[2] else F(1)
q = q_closed(LAW)
assert 2 * q * q - 3 * q + 1 == 0 and f(LAW, q) == q and f(LAW, F(1)) == 1
print(f"offspring law P(0), P(1), P(2) = 1/4 1/4 1/2; mean m = {m} = {float(m)}; variance sigma^2 = {var} = {float(var)}")
print(f"fixed points of f(s) = s: 2s^2 - 3s + 1 = (2s - 1)(s - 1) = 0, roots 1/2 and 1; smallest q = p0/p2 = {q}")
h = [q_iter(LAW, n, F(0)) for n in range(4)]
print(f"by hand: P(Z_1=0) = {h[1]}, P(Z_2=0) = f(1/4) = {h[2]} = {float(h[2]):.5f}, P(Z_3=0) = f(11/32) = {h[3]} = {float(h[3]):.5f}")
dist = {1: F(1)}                         # road 3: the whole law of Z_n
for n in range(1, 6):
    new = {}
    for k, pk in dist.items():           # k parents: children law is LAW convolved k times
        kids = {0: F(1)}
        for _ in range(k):
            nk = {}
            for a, pa in kids.items():
                for c, pc in enumerate(LAW): nk[a + c] = nk.get(a + c, 0) + pa * pc
            kids = nk
        for j, pj in kids.items(): new[j] = new.get(j, 0) + pk * pj
    dist = new
    ez = sum(k * p for k, p in dist.items()); vz = sum(k * k * p for k, p in dist.items()) - ez * ez
    eh = sum(p * F(1, 2) ** k for k, p in dist.items())
    assert dist[0] == q_iter(LAW, n, F(0)) and ez == m ** n and eh == q
    assert vz == var * m ** (n - 1) * (m ** n - 1) / (m - 1)
    print(f"exact law, n={n}: P(Z=0) {float(dist[0]):.6f} = iteration; E[Z] {float(ez):.6f} = m^n; Var(Z) {float(vz):.6f} = formula; E[W] = {ez / m ** n}; E[(1/2)^Z] = {eh}")
qs = [q_iter((0.25, 0.25, 0.5), n) for n in range(201)]
print("q_n = P(dead by generation n), n = 0..10: " + " ".join(f"{x:.4f}" for x in qs[:11]))
ratio = (qs[41] - 0.5) / (qs[40] - 0.5)
assert abs(qs[200] - 0.5) < 1e-12 and abs(ratio - 0.75) < 1e-6
print(f"q_200 = {qs[200]:.12f}; gap ratio (q_41 - q)/(q_40 - q) = {ratio:.4f} = f'(1/2) = 1/4 + 1/2 = 0.75")
print(f"three founders: all three lines die with chance q^3 = {q ** 3}")
for tl in ((F(1, 8), F(3, 8), F(1, 2)), (F(1, 2), F(1, 4), F(1, 4))):   # edit the first law to try another
    tq, ti = q_closed(tl), q_iter(tuple(map(float, tl)), 400)
    assert abs(ti - float(tq)) < 1e-12, "shortcut vs iteration (a law with mean exactly 1 converges too slowly)"
    print(f"try: law {' '.join(map(str, tl))} (mean {float(sum(k * x for k, x in enumerate(tl)))}): q = min(1, p0/p2) = {tq}, iteration {ti:.4f}")
for p in ((F(1, 4), F(1, 4), F(1, 2)), (F(3, 8), F(0), F(5, 8)), (F(0), F(3, 4), F(1, 4))):
    mp, qc, qi = sum(k * x for k, x in enumerate(p)), q_closed(p), q_iter(tuple(map(float, p)), 400)
    assert mp == m and abs(qi - qc) < 1e-12
    print(f"same mean {float(mp)}: law {' '.join(str(x) for x in p)}: q = p0/p2 = {float(qc):.4f}, iteration {qi:.4f}")
laws = {"subcritical 1/2 1/4 1/4 (m 0.75)": (0.5, 0.25, 0.25), "critical 1/4 1/2 1/4 (m 1)": (0.25, 0.5, 0.25),
        "supercritical 1/4 1/4 1/2 (m 1.25)": (0.25, 0.25, 0.5)}
for name, p in laws.items():
    print(f"chart, P(dead by n), n = 0..20, {name}: " + " ".join(f"{q_iter(p, n):.3f}" for n in range(21)))
CL = (0.25, 0.5, 0.25)                   # the critical law: mean mc = 1, variance vc
mc = sum(k * p for k, p in enumerate(CL))
vc = sum(k * k * p for k, p in enumerate(CL)) - mc * mc
crit = [(n, 1 - q_iter(CL, n)) for n in (10, 100, 1000)]
assert abs(crit[-1][0] * crit[-1][1] - 2 / vc) < 0.05 and all(a > b for (_, a), (_, b) in zip(crit, crit[1:]))
print(f"critical, P(alive at n) and n x P (Kolmogorov: tends to 2/variance = 2/{vc} = {2 / vc:.0f}): " + "  ".join(f"n={n} {a:.4f} {n * a:.3f}" for n, a in crit))
sub = [(n, 1 - q_iter((0.5, 0.25, 0.25), n)) for n in (10, 20)]
print("subcritical, P(alive at n) and P / 0.75^n: " + "  ".join(f"n={n} {a:.6f} {a / 0.75 ** n:.4f}" for n, a in sub))
vw = var / (m * (m - 1))
print(f"Var(W) = sigma^2/(m(m-1)) = {float(vw)}; E[W_n^2] rises to 1 + {float(vw)} = {float(1 + vw)}; P(W = 0) = q = {q}, so E[W | W > 0] = {1 / (1 - q)}")
state = 20261123
def u():                                 # SplitMix64, a uniform number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & (2**64 - 1)
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return ((z ^ (z >> 31)) >> 11) * 2.0**-53
N, G, mf = 10000, 20, 1.25
dead = sw = sw2 = sd = salive = 0.0
paths, kept = [], [0, 0]
for fam in range(N):                     # road 4: simulate generation by generation
    z, w = 1, [1.0]
    for g in range(G):
        z = sum(0 if r < 0.25 else 1 if r < 0.5 else 2 for r in (u() for _ in range(z)))
        w.append(z / mf ** (g + 1))
    dead += z == 0; sw += w[G]; sw2 += w[G] ** 2; sd += (w[G] - w[10]) ** 2; salive += w[G] if z else 0
    i = 0 if z else 1
    if kept[i] < (2 if z else 1): kept[i] += 1; paths.append((fam + 1, w))
def show(label, mean, msq, exact):      # msq: the mean of the squares
    se = sqrt((msq - mean * mean) / N)
    assert abs(mean - exact) < 4 * se, label
    print(f"simulated {label}: {mean:.4f} +- {se:.4f} (exact {exact:.4f})")
q20 = qs[G]
show("share dead by generation 20", dead / N, dead / N, q20)
show("mean W_20", sw / N, sw2 / N, 1.0)
vw20, vw10 = float(vw) * (1 - 1 / mf ** 20), float(vw) * (1 - 1 / mf ** 10)
print(f"simulated mean W_20^2: {sw2 / N:.4f} (exact 1 + Var(W_20) = {1 + vw20:.4f}); mean (W_20 - W_10)^2: {sd / N:.4f} (exact {vw20 - vw10:.4f})")
print(f"simulated mean W_20 among the {N - int(dead)} families alive: {salive / (N - dead):.4f} (exact 1/(1 - q_20) = {1 / (1 - q20):.4f})")
assert abs(sd / N - (vw20 - vw10)) < 0.15 and abs(salive / (N - dead) - 1 / (1 - q20)) < 0.1
for fam, w in sorted(paths):
    print(f"path, family {fam}, W_n for n = 0..20: " + " ".join(f"{x:.2f}" for x in w))
print(f"wrong: E[Z_20] = m^20 = {mf ** 20:.4f}, yet P(dead by 20) = {q20:.4f}; wrong: larger root 1 says sure death, true {float(q):.4f}")
print(f"wrong: critical E[Z_100] = mc^100 = {mc ** 100:.4f}, yet P(alive at 100) = {crit[1][1]:.4f}")
print("ALL CHECKS PASS")
