# Changing the measure -- the check behind the card.  Imports: math and
# fractions, neither of which knows the answer.  Ten tosses of a coin that lands
# heads 0.6 of the time (P), reweighted path by path into a fair coin (Q).
# Roads: the fair-coin formula, exact enumeration of all 1,024 paths in
# fractions, and a seeded simulation of the loaded coin carrying its weights.
import math
from fractions import Fraction as F

N, P_H, Q_H = 10, F(3, 5), F(1, 2)
UP, DOWN = Q_H / P_H, (1 - Q_H) / (1 - P_H)             # 5/6 on heads, 5/4 on tails

def prob(path, h):                                      # chance of a 0/1 path, heads chance h
    out = F(1)
    for x in path:
        out *= h if x else 1 - h
    return out

def dens(path):                                         # the density process after len(path) tosses
    k = sum(path)
    return UP ** k * DOWN ** (len(path) - k)

def paths(n): return [[(i >> j) & 1 for j in range(n)] for i in range(2 ** n)]

def wins(path): return 2 * sum(path) - len(path)        # $1 on heads each toss: heads minus tails

def big(path): return 1 if sum(path) >= 7 else 0       # the event: at least 7 heads

def cond(prefix, f):                                    # E^P[f(whole path) | the first tosses]
    return sum(prob(s, P_H) * f(prefix + s) for s in paths(N - len(prefix)))

def sz(w): return wins(w) * dens(w)                     # winnings times weight

ALL = paths(N)
q_mean = N * (2 * Q_H - 1)                              # road 1: the fair coin, read directly
q_big = F(sum(math.comb(N, k) for k in range(7, N + 1)), 2 ** N)
e_z = sum(prob(w, P_H) * dens(w) for w in ALL)          # road 2: every path, weighted by Z
e_sz = sum(prob(w, P_H) * sz(w) for w in ALL)
e_bz = sum(prob(w, P_H) * dens(w) * big(w) for w in ALL)
p_mean = sum(prob(w, P_H) * wins(w) for w in ALL)
p_big = sum(prob(w, P_H) * big(w) for w in ALL)
flip = sum(prob(w, P_H) / dens(w) for w in ALL)         # mistake: the ratio upside down
pres = [pre for n in range(N + 1) for pre in paths(n)]
mart = all(cond(pre, dens) == dens(pre) for pre in pres)
smart = all(cond(pre, sz) == sz(pre) for pre in pres)
hhhh, path1 = [1, 1, 1, 1], [0, 1, 1, 1, 1, 0, 1, 1, 1, 0]
raw = cond(hhhh, sz)
bayes, drift = raw / dens(hhhh), cond(hhhh, wins) - wins(hhhh)

MASK, state = (1 << 64) - 1, 20260930                   # road 3: SplitMix64, seed 20260930
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

M, sums, first = 200000, [0.0] * 8, []                  # sums: Z, Z^2, SZ, (SZ)^2, Z;7+, its square, S, S^2
for i in range(M):
    z, s, h, trace = 1.0, 0, 0, [(0, '-', 1.0, 1.0)]
    for n in range(1, N + 1):
        head = unif() < 0.6
        f = 5 / 6 if head else 5 / 4
        z, s, h = z * f, s + (1 if head else -1), h + head
        trace.append((n, 'H' if head else 'T', f, z))
    if i == 0:
        first = trace
    b = 1.0 if h >= 7 else 0.0
    for j, v in enumerate((z, z * z, s * z, (s * z) * (s * z), z * b, z * z * b, s, s * s)):
        sums[j] += v
def est(j):                                             # mean and standard error
    m = sums[j] / M
    return m, math.sqrt((sums[j + 1] / M - m * m) / (M - 1))
(sim_z, se_z), (sim_sz, se_sz), (sim_bz, se_bz), (sim_s, se_s) = est(0), est(2), est(4), est(6)

MU, T_END, X_END, bridge = 0.2, 10, 2, []               # toss every h, step sqrt(h), heads (1+MU sqrt h)/2
for k in range(6):
    h, n = 4.0 ** -k, 10 * 4 ** k
    heads, a = (n + X_END * 2 ** k) // 2, MU * math.sqrt(h)
    zd = math.exp(-heads * math.log(1 + a) - (n - heads) * math.log(1 - a))
    bridge.append((h, n, zd, math.exp(-MU * X_END + 0.5 * MU * MU * T_END)))

lf, far = [0.0], []                                     # log factorials; P and Q of {Z_n <= 0.01}
for j in range(1, 501):
    lf.append(lf[-1] + math.log(j))
for n in range(0, 501, 50):
    pz = qz = 0.0
    for k in range(n + 1):
        if k * math.log(5 / 6) + (n - k) * math.log(5 / 4) <= math.log(0.01):
            c = lf[n] - lf[k] - lf[n - k]
            pz += math.exp(c + k * math.log(0.6) + (n - k) * math.log(0.4))
            qz += math.exp(c + n * math.log(0.5))
    far.append((n, pz, qz))

def row(label, vals):
    print(f"{label:<17}" + " ".join(vals))
print(f"loaded coin P: heads 0.6; fair coin Q: heads 0.5; {N} tosses, {len(ALL)} paths")
print(f"weights per toss: heads {UP} = {float(UP):.6f}, tails {DOWN} = {float(DOWN):.6f}; "
      f"log-weight per toss averages {0.6 * math.log(5 / 6) + 0.4 * math.log(5 / 4):.6f} under P")
row("heads count k", [f"{k:6d}" for k in range(N + 1)])
row("P-law of k", [f"{float(math.comb(N, k) * P_H ** k * (1 - P_H) ** (N - k)):.4f}" for k in range(N + 1)])
row("Q-law of k", [f"{float(math.comb(N, k) * Q_H ** N):.4f}" for k in range(N + 1)])
row("Z_10 at k heads", [f"{float(UP ** k * DOWN ** (N - k)):.4f}" for k in range(N + 1)])
print(f"path 1, THHHHTHHHT: P {float(prob(path1, P_H)):.8f}, Q {float(prob(path1, Q_H)):.8f}, "
      f"Z {float(dens(path1)):.6f}, P x Z {float(prob(path1, P_H) * dens(path1)):.8f}")
print(f"E^P[Z_10] by enumeration: {e_z}")
print(f"E^Q[S_10]: fair formula {q_mean}; E^P[S_10 Z_10] enumerated {e_sz}; unweighted E^P[S_10] {float(p_mean):.6f}")
print(f"Q(7+ heads): counted {q_big * 2 ** N}/{2 ** N} = {float(q_big):.6f}; E^P[Z_10; 7+] enumerated {float(e_bz):.6f}; P(7+) {float(p_big):.6f}")
print(f"E^P[Z_10 | first n tosses] = Z_n for all {len(pres)} prefixes: {'yes' if mart else 'no'}")
print(f"S_n Z_n a P-martingale on all {len(pres)} prefixes: {'yes' if smart else 'no'}")
print(f"after HHHH: Z_4 = {float(dens(hhhh)):.6f}; E^P[S_10 Z_10 | HHHH] over {2 ** (N - 4)} endings = {float(raw):.6f}; "
      f"divided by Z_4 = {float(bayes):.6f}")
print(f"after HHHH: E^P[S_10 | HHHH] - S_4 = {float(drift):.6f} (S is not a P-martingale)")
print(f"mistake, ratio upside down: weights average {float(flip):.6f}, formula (26/25)^10 = {float(F(26, 25) ** 10):.6f}")
for n, c, f, z in first:
    print(f"path 1, toss {n:2d}: {c}  factor {f:.4f}  Z_n {z:.4f}")
print(f"simulated, M = {M}, seed 20260930:")
print(f"  E^P[Z_10]        {sim_z:.4f} +- {se_z:.4f}  (exact 1)")
print(f"  E^P[S_10 Z_10]   {sim_sz:.4f} +- {se_sz:.4f}  (exact 0)")
print(f"  E^P[Z_10; 7+]    {sim_bz:.4f} +- {se_bz:.4f}  (exact {float(q_big):.6f})")
print(f"  unweighted S_10  {sim_s:.4f} +- {se_s:.4f}  (exact 2)")
for h, n, zd, zc in bridge:
    print(f"bridge h = {h:.6f}, {n:5d} tosses: Z discrete {zd:.6f}, limit {zc:.6f}, error {abs(zd - zc):.7f}")
row("n", [f"{n:6d}" for n, _, _ in far])
row("P(Z_n <= 0.01)", [f"{p:.4f}" for _, p, _ in far])
row("Q(Z_n <= 0.01)", [f"{q:.4f}" for _, _, q in far])
row("figure, Z_n", [f"{z:.2f}" for *_, z in first])
row("figure, E^P[Z_n]", [str(sum(prob(w, P_H) * dens(w) for w in paths(n))) for n in range(N + 1)])
row("figure, P(<=.01)", [f"{p:.2f}" for _, p, _ in far])
row("figure, Q(<=.01)", [f"{q:.2f}" for _, _, q in far])
assert e_z == 1 and min(dens(w) for w in ALL) > 0                       # a probability, equivalent
assert e_sz == q_mean and p_mean == N * (2 * P_H - 1)                  # weighted P average = Q formula
assert e_bz == q_big                                                    # weighted P chance = Q count
assert mart and smart                                                   # every prefix, exactly
assert bayes == 4 + (N - 4) * (2 * Q_H - 1) and drift == (N - 4) * (2 * P_H - 1)  # Bayes = fair forecast
assert flip == F(26, 25) ** N                                           # upside-down weights do not average 1
assert all(abs(m - x) < 4 * e for m, e, x in ((sim_z, se_z, 1), (sim_sz, se_sz, q_mean), (sim_bz, se_bz, q_big), (sim_s, se_s, p_mean)))
assert all(abs(b[2] - b[3]) < abs(a[2] - a[3]) / 3 for a, b in zip(bridge, bridge[1:]))  # error falls about 4x per step
assert all(q <= 0.01 * p + 1e-15 for _, p, q in far) and far[-1][1] > 0.5
print("ALL CHECKS PASS")
