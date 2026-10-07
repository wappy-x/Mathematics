# Pi-systems and Dynkin's theorem -- the check behind the card.  Standard
# library only: fractions for exact arithmetic, math.sqrt for one square root.
# Tomorrow's noon temperature T, in degrees C, under two rival models:
#   A: T = 8 + 12*U1 + 12*U2, two independent uniform swings (U from 0 to 1);
#   B: one uniform U read backwards through the distribution function F.
# Roads: F through Dynkin moves; the density integrated exactly by Simpson;
# a SplitMix64 simulation of each model; closures listed on finite spaces.
from fractions import Fraction as Fr
from math import sqrt, gcd

def F(t):                                    # P(T <= t), exact
    s = (Fr(t) - 8) / 12
    if s <= 0: return Fr(0)
    if s <= 1: return s * s / 2
    if s <= 2: return 1 - (2 - s) ** 2 / 2
    return Fr(1)

def dens(t):                                 # the triangle under F, peak 1/12 at 20
    return max(Fr(0), (t - 8) / 144 if t <= 20 else (32 - t) / 144)

def simpson(g, a, b, n=20):                  # exact on pieces of degree <= 3
    a, b = Fr(a), Fr(b); h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

MASK = (1 << 64) - 1
def splitmix(seed):                          # SplitMix64, uniform in [0, 1)
    s = seed
    while True:
        s = (s + 0x9E3779B97F4A7C15) & MASK
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield ((z ^ (z >> 31)) >> 11) / 2 ** 53

def model_b(u):                              # F read backwards
    return 8 + 12 * sqrt(2 * u) if u < 0.5 else 32 - 12 * sqrt(2 * (1 - u))

def closure(gens, full, sigma):              # smallest lambda- or sigma-system
    S = set(gens) | {full}
    while True:
        new = {b & ~a for a in S for b in S if a & b == a}          # proper differences
        if sigma: new |= {a | b for a in S for b in S} | {full & ~a for a in S}
        if new <= S: return S
        S |= new

def f4(x): return f"{float(x):.4f}"
def fr(x): return f"{x.numerator}/{x.denominator} = {float(x):.6f}"

# ---- road 1: the event from half-line values only, by Dynkin moves ----
F15, F20, F30 = F(15), F(20), F(30)
band = F20 - F15                             # (15, 20] = (-inf, 20] minus (-inf, 15]
above = 1 - F30                              # (30, inf) = everything minus (-inf, 30]
p_dynkin = 1 - ((1 - band) - above)          # E = everything minus ((not band) minus above)
print(f"F(15) = {fr(F15)}; F(20) = {fr(F20)}; F(30) = {fr(F30)}")
print("density f at 15, 20, 30: " + ", ".join(f"{d.numerator}/{d.denominator}" for d in map(dens, (Fr(15), Fr(20), Fr(30)))))
print(f"band (15, 20]: {fr(band)}; above 30: {fr(above)}")
print(f"P(E) by Dynkin moves on F alone: {fr(p_dynkin)}")
# ---- road 2: the density integrated, never touching F ----
p_dens = simpson(dens, 15, 20) + simpson(dens, 30, 32)
print(f"P(E) by integrating the density: {fr(p_dens)}")
# ---- roads 3 and 4: simulate both models ----
N, TS = 200000, list(range(8, 33, 2))
ga, gb = splitmix(2026), splitmix(29)
cnt = {"A": [0] * len(TS), "B": [0] * len(TS)}
hitE, heat, heat2 = {"A": 0, "B": 0}, {"A": 0.0, "B": 0.0}, {"A": 0.0, "B": 0.0}
ceil15 = 0
for _ in range(N):
    ta = 8 + 12 * next(ga) + 12 * next(ga)
    tb = model_b(next(gb))
    ceil15 += -int(-ta // 1) <= 15           # model C: A's reading rounded up
    for m, t in (("A", ta), ("B", tb)):
        hitE[m] += (15 < t <= 20) or t > 30
        g = max(18 - t, 0.0); heat[m] += g; heat2[m] += g * g
        for i, x in enumerate(TS): cnt[m][i] += t <= x
se = sqrt(float(p_dens) * (1 - float(p_dens)) / N)
for m in "AB":
    print(f"P(E), model {m} simulated, {N} draws: {hitE[m] / N:.4f}")
print(f"standard error of one simulated P(E): {se:.4f}")
print("chart, t:", ", ".join(str(x) for x in TS))
print("chart, F exact:", ", ".join(f"{float(F(x)):.2f}" for x in TS))
for m in "AB":
    print(f"chart, model {m}:", ", ".join(f"{c / N:.2f}" for c in cnt[m]))
# ---- the function version: heating degrees max(18 - T, 0) ----
h_exact = simpson(lambda t: (18 - t) * dens(t), 8, 18)
print(f"E[max(18 - T, 0)] exact: {fr(h_exact)}")
hse = {}
for m in "AB":
    mean = heat[m] / N; hse[m] = sqrt((heat2[m] / N - mean * mean) / N)
    print(f"E[max(18 - T, 0)], model {m} simulated: {mean:.4f} (se {hse[m]:.4f})")
# ---- finite spaces, every set listed ----
full6, H = 0b111111, [0b1, 0b11, 0b111, 0b1111, 0b11111]      # six 5-degree bands
d6, s6 = closure(H + [0], full6, False), closure(H + [0], full6, True)
print(f"six bands, half-lines at 10..30: lambda closure {len(d6)} sets, sigma closure {len(s6)} sets")
C = [0b0011, 0b0110]                         # cold-or-mild, mild-or-warm
mu, nu = [Fr(1, 4)] * 4, [Fr(0), Fr(1, 2), Fr(0), Fr(1, 2)]
meas = lambda w, A: sum(w[i] for i in range(4) if A >> i & 1)
good = {A for A in range(16) if meas(mu, A) == meas(nu, A)}
dC, sC = closure(C, 15, False), closure(C, 15, True)
print(f"four bands, not a pi-system: lambda closure {len(dC)} sets, sigma closure {len(sC)} sets")
print(f"sets where the two four-band models agree: {len(good)} of 16; 'mild' gets {float(meas(mu, 2)):.2f} and {float(meas(nu, 2)):.2f}")
print(f"add the overlap 'mild' and the lambda closure has {len(closure(C + [0b0010], 15, False))} sets")
# ---- what breaks ----
q = {n: sum(1 for d in range(1, n + 1) for k in range(1, d + 1) if gcd(k, d) == 1) for n in (10, 100, 1000)}
print("rationals in (0, 1] with denominator <= 10, 100, 1000: " + ", ".join(str(q[n]) for n in q)
      + "; doubled: " + ", ".join(str(2 * q[n]) for n in q) + "; at the point 1/2: 1 against 2")
print(f"model C (A rounded up), whole degrees only: at 15 both {f4(F15)}; at 15.5 C {f4(F15)}"
      f" (simulated {ceil15 / N:.4f}), A {f4(F(Fr(31, 2)))}")
print("figure, x = 30 + 12.5(t - 8), y = 200 - 1920 f(t):",
      "; ".join(f"t={x} ({float(30 + Fr(25, 2) * (x - 8)):.2f}, {float(200 - 1920 * dens(Fr(x))):.2f})"
                for x in (8, 15, 20, 30, 32)))
assert p_dynkin == p_dens == Fr(11, 32)                       # F alone against the density
assert all(abs(hitE[m] / N - float(p_dens)) < 4 * se for m in "AB")
assert d6 == s6 and len(s6) == 64                              # pi-system: lambda closure is everything
assert good == dC and len(dC) == 6 and len(sC) == 16           # not pi: agreement stops short
assert h_exact == Fr(125, 108) and all(abs(heat[m] / N - 125 / 108) < 4 * hse[m] for m in "AB")
se15 = sqrt(float(F15) * (1 - float(F15)) / N)                  # model C: agrees at 15, not at 15.5
assert abs(ceil15 / N - float(F15)) < 4 * se15 and F(Fr(31, 2)) - F15 > 8 * se15
print("ALL CHECKS PASS")
