# Girsanov's theorem -- the check behind the card.  Only math is imported.
# A $100 share drifts at mu = 0.08 a year with sigma = 0.20; the pricing desk wants
# drift r = 0.05.  Weight each path by Z_T = exp(-theta W_T - theta^2 T / 2) with
# theta = (mu - r) / sigma, and Wt = W + theta t should be a Brownian motion.
# Roads: closed forms; exact integrals over the bell curve (Simpson's rule);
# 4000 seeded paths (SplitMix64, Box-Muller) with a constant and a bounded drift.
import math

S0, MU, R, SIG, T = 100.0, 0.08, 0.05, 0.20, 1.0
TH = (MU - R) / SIG
SEED, PATHS, FINE, GRIDS = 20260930, 4000, 1024, (16, 64, 256, 1024)
MASK = (1 << 64) - 1

class SplitMix64:                                  # the wing's generator, written out
    def __init__(self, seed): self.s = seed
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                              # Box-Muller, cosine half
        u1, u2 = self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)

def phi(x): return math.exp(-0.5 * x * x) / math.sqrt(2.0 * math.pi)

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4.0 if i % 2 == 1 else 2.0) * f(a + i * h)
    return s * h / 3.0

def ncdf(x): return min(1.0, max(0.0, 0.5 + simpson(phi, 0.0, max(-9.0, min(9.0, x)), 2000)))
def ep(g, hi=12.0): return simpson(lambda w: g(w) * phi(w), -12.0, hi, 4000)   # E^P over W_T, T = 1
def z(w, th=TH): return math.exp(-th * w - 0.5 * th * th * T)
def st(w): return S0 * math.exp((MU - 0.5 * SIG * SIG) * T + SIG * w)
def ms(a): m = a[0] / PATHS; return m, math.sqrt(max(a[1] / PATHS - m * m, 0.0) / PATHS)

print(f"share: S0 {S0:.0f} dollars, mu {MU:.2f}, r {R:.2f}, sigma {SIG:.2f} a year, T {T:.0f} year")
print(f"theta = (mu - r) / sigma {TH:.6f}   correction theta^2 T / 2 {0.5 * TH * TH * T:.6f}")
print("chart, W_T      " + " ".join(f"{w:7.0f}" for w in range(-3, 4)))
print("weight, 4 places " + " ".join(f"{z(w):7.4f}" for w in range(-3, 4)))
print("chart, weight   " + " ".join(f"{z(w):7.2f}" for w in range(-3, 4)))
print(f"road 1, E^P[S_T] = S0 e^(mu T) {S0 * math.exp(MU * T):.4f}   E^Q[S_T] = S0 e^(r T) {S0 * math.exp(R * T):.4f}")
print(f"log drift under P, mu - sigma^2/2 {MU - 0.5 * SIG * SIG:.6f}   under Q, mu - sigma^2/2 - sigma theta {MU - 0.5 * SIG * SIG - SIG * TH:.6f}")
ez, eqw = ep(z), ep(lambda w: z(w) * w)
eqwt, eqwt2 = ep(lambda w: z(w) * (w + TH * T)), ep(lambda w: z(w) * (w + TH * T) * (w + TH * T))
eqs, eps = ep(lambda w: z(w) * st(w)), ep(st)
print(f"road 2, E^P[Z_T] {ez:.6f}   E^Q[W_T] {eqw:+.6f}   E^Q[Wt_T] {eqwt:+.6f}   E^Q[Wt_T^2] {eqwt2:.6f}")
print(f"road 2, E^P[S_T] {eps:.4f}   E^Q[S_T] {eqs:.4f}   E^Q[e^(-rT) S_T] {math.exp(-R * T) * eqs:.4f}")
cdf = [(x, ep(z, x - TH * T), ncdf(x)) for x in (-1.0, 0.0, 1.0)]
print("road 2, Q(Wt_T <= x) against N(x): " + "   ".join(f"x {x:+.0f}: {q:.6f} {n:.6f}" for x, q, n in cdf))

g, dt, CH = SplitMix64(SEED), T / FINE, FINE // 8
acc = {k: [0.0, 0.0] for k in ("z", "plain", "wtd", "wt", "wt2", "cov", "rv", "rvw", "z2", "plain2", "wtd2", "wt_2", "wt2_2", "ex_2")}
gap = {n: 0.0 for n in GRIDS}
chart = [[0.0, 0.0] for _ in range(9)]
for p in range(PATHS):
    w, ls, ls2, lz2, sh2, rv, wmid = 0.0, math.log(S0), math.log(S0), 0.0, 0.0, 0.0, 0.0
    ze, part = {n: 1.0 for n in GRIDS}, {n: 0.0 for n in GRIDS}
    for k in range(FINE + 1):
        if k % CH == 0:
            disc = math.exp(ls - R * k * dt)
            chart[k // CH][0] += disc; chart[k // CH][1] += disc * math.exp(-TH * w - 0.5 * TH * TH * k * dt)
        if k == FINE: break
        dw = math.sqrt(dt) * g.normal()
        step = (MU - 0.5 * SIG * SIG) * dt + SIG * dw
        ls += step; rv += step * step; w += dw
        th2 = 0.30 if ls2 >= math.log(110.0) else 0.15     # bounded drift: 11% above $110
        ls2 += (R + SIG * th2 - 0.5 * SIG * SIG) * dt + SIG * dw
        lz2 += -th2 * dw - 0.5 * th2 * th2 * dt; sh2 += th2 * dt
        for n in GRIDS:
            part[n] += dw
            if (k + 1) % (FINE // n) == 0: ze[n] *= 1.0 - TH * part[n]; part[n] = 0.0
        if k + 1 == FINE // 2: wmid = w + TH * 0.5 * T
    zt, wt = z(w), w + TH * T
    z2, wt2 = math.exp(lz2), w + sh2
    for key, v in (("z", zt), ("plain", math.exp(ls - R * T)), ("wtd", zt * math.exp(ls - R * T)),
                   ("wt", zt * wt), ("wt2", zt * wt * wt), ("cov", zt * wmid * (wt - wmid)),
                   ("rv", rv), ("rvw", zt * rv), ("z2", z2), ("plain2", math.exp(ls2 - R * T)),
                   ("wtd2", z2 * math.exp(ls2 - R * T)), ("wt_2", z2 * wt2), ("wt2_2", z2 * wt2 * wt2),
                   ("ex_2", z2 * math.exp(wt2 - 0.5 * T))):
        acc[key][0] += v; acc[key][1] += v * v
    for n in GRIDS: gap[n] += abs(ze[n] - zt)

names = (("mean weight Z_T", "z", "1"), ("plain mean of e^(-rT) S_T", "plain", f"{S0 * math.exp((MU - R) * T):.4f}"),
         ("weighted mean of e^(-rT) S_T", "wtd", "100"), ("weighted mean of Wt_T", "wt", "0"),
         ("weighted mean of Wt_T^2", "wt2", "1"), ("weighted mean of half-year steps product", "cov", "0"))
print(f"road 3, {PATHS} seeded paths (seed {SEED}), {FINE} steps a year, constant theta:")
for lab, key, tgt in names: print(f"  {lab:<42} {ms(acc[key])[0]:+.4f} (se {ms(acc[key])[1]:.4f})   target {tgt}")
print("density built step by step, Z <- Z (1 - theta dW), mean |gap| to the closed form:")
for n in GRIDS: print(f"  steps {n:5d}   mean gap {gap[n] / PATHS:.6f}")
print("bounded drift, 0.08 below $110 and 0.11 above, theta_t = 0.15 or 0.30:")
for lab, key, tgt in (("mean weight Z_T", "z2", "1"), ("plain mean of e^(-rT) S_T", "plain2", "none known"),
                      ("weighted mean of e^(-rT) S_T", "wtd2", "100"), ("weighted mean of Wt_T", "wt_2", "0"),
                      ("weighted mean of Wt_T^2", "wt2_2", "1"), ("weighted mean of e^(Wt_T - T/2)", "ex_2", "1")):
    print(f"  {lab:<42} {ms(acc[key])[0]:+.4f} (se {ms(acc[key])[1]:.4f})   target {tgt}")
print("what breaks:")
nocorr = ep(lambda w: math.exp(-TH * w))
print(f"  no -theta^2 T/2: total weight {nocorr:.6f} (e^(theta^2/2) {math.exp(0.5 * TH * TH):.6f}), share priced {nocorr * 100.0:.4f}")
flip = math.exp(-R * T) * ep(lambda w: z(w, -TH) * st(w))
print(f"  theta with the wrong sign: share priced {flip:.4f} (drift mu + sigma theta = {MU + SIG * TH:.2f})")
print(f"  realised variance of log S, plain {ms(acc['rv'])[0]:.6f}, weighted {ms(acc['rvw'])[0]:.6f}, sigma^2 T {SIG * SIG * T:.6f}")
horizon = []
for yrs in (1.0, 100.0, 1000.0, 10000.0):
    cut = (-math.log(0.01) - 0.5 * TH * TH * yrs) / (TH * math.sqrt(yrs))
    horizon.append((1.0 - ncdf(cut), 1.0 - ncdf(cut + TH * math.sqrt(yrs))))
    print(f"  horizon {yrs:7.0f} years: P(Z_T < 0.01) {horizon[-1][0]:.4f}   Q(Z_T < 0.01) {horizon[-1][1]:.4f}")
print("chart, years    " + " ".join(f"{k / 8:7.3f}" for k in range(9)))
print("chart, plain    " + " ".join(f"{c[0] / PATHS:7.2f}" for c in chart))
print("chart, weighted " + " ".join(f"{c[1] / PATHS:7.2f}" for c in chart))
print("chart, P exact  " + " ".join(f"{S0 * math.exp((MU - R) * k / 8):7.2f}" for k in range(9)))

m = {k: ms(v) for k, v in acc.items()}
assert abs(ez - 1.0) < 1e-9, "Simpson: the weights average 1"
assert abs(eqw + TH * T) < 1e-9, "Simpson: under Q, W_T is centred at -theta T"
assert abs(eqs - S0 * math.exp(R * T)) < 1e-6, "Simpson: under Q the share grows at r"
assert all(abs(q - n) < 1e-6 for _, q, n in cdf), "Simpson: Wt_T has the bell-curve law under Q"
assert abs(m["wtd"][0] - 100.0) < 4 * m["wtd"][1], "simulation: discounted share fair under Q"
assert m["plain"][0] - 100.0 > 6 * m["plain"][1], "simulation: and not fair under P"
assert abs(m["wt"][0]) < 4 * m["wt"][1], "simulation: Wt_T centred under Q"
assert abs(m["wt2"][0] - 1.0) < 4 * m["wt2"][1], "simulation: Wt_T has variance T under Q"
assert abs(m["cov"][0]) < 4 * m["cov"][1], "simulation: the two half-year Q-steps are uncorrelated"
assert abs(m["wtd2"][0] - 100.0) < 4 * m["wtd2"][1], "bounded drift: discounted share still fair under Q"
assert abs(m["wt_2"][0]) < 4 * m["wt_2"][1], "bounded drift: Wt_T centred under Q"
assert abs(m["wt2_2"][0] - 1.0) < 4 * m["wt2_2"][1], "bounded drift: Wt_T has variance T under Q"
assert abs(m["ex_2"][0] - 1.0) < 4 * m["ex_2"][1], "bounded drift: e^(Wt_T - T/2) averages 1 under Q"
assert gap[1024] < gap[16] / 4, "the step-by-step density closes on the closed form"
assert abs(nocorr - math.exp(0.5 * TH * TH)) < 1e-9, "without the correction the weights overshoot"
assert horizon[3][0] > 0.99, "over 10000 years P puts nearly all its mass where Z_T < 0.01"
assert horizon[3][1] < 0.01, "while Q puts almost none there"
print("ALL CHECKS PASS")
