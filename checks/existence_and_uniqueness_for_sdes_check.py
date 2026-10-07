# Existence and uniqueness for SDEs -- the check behind the card.  Only math is imported.
# CIR rate dr = kappa (theta - r) dt + sigma sqrt(r) dW, r0 = 0.01, kappa = 0.5 a year, theta = 0.04,
# sigma = 0.25, t in years.  Roads: the theorem's conditions; Picard in mean square for CIR and a
# Lipschitz cousin (noise 1.25 r), against Euler's loop; two repaired Euler schemes against each other,
# the exact mean and variance, and the moment equations; dX = X^3 dt + X^2 dW, solved exactly, its
# explosion chance by the reflection principle and by simulation.  Simulated numbers carry standard errors.
import math

R0, KAP, TH, SIG = 0.01, 0.5, 0.04, 0.25
SEED, PATHS, FINE = 20260930, 2000, 1024
MASK = (1 << 64) - 1

class SplitMix64:                         # the wing's generator, with Box-Muller normals
    def __init__(self, seed):
        self.s, self.spare = seed & MASK, None
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):
        if self.spare is not None:
            z, self.spare = self.spare, None
            return z
        u1, u2 = self.uniform(), self.uniform()
        r = math.sqrt(-2.0 * math.log(1.0 - u1))
        self.spare = r * math.sin(2.0 * math.pi * u2)
        return r * math.cos(2.0 * math.pi * u2)

def Phi(x, n=4000):                       # normal CDF: Simpson's rule on the bell curve from -10 to x
    h, s = (x + 10.0) / n, math.exp(-50.0) + math.exp(-0.5 * x * x)
    for k in range(1, n):
        s += (4.0 if k % 2 == 1 else 2.0) * math.exp(-0.5 * (-10.0 + k * h) * (-10.0 + k * h))
    return s * h / 3.0 / math.sqrt(2.0 * math.pi)

def mean_se(xs):
    m = sum(xs) / len(xs)
    v = sum((x - m) * (x - m) for x in xs) / (len(xs) - 1)
    return m, math.sqrt(v / len(xs)), v

def cir(x): return SIG * math.sqrt(max(x, 0.0))   # CIR noise size, read as 0 below zero
def cousin(x): return 1.25 * abs(x)              # Lipschitz cousin: the same size at 4 percent

print(f"rate: r0 {R0}, kappa {KAP}, theta {TH}, sigma {SIG}; seeds {SEED} and {SEED + 1}; t in years")
print(f"Feller test: 2 kappa theta {2 * KAP * TH:.4f} against sigma^2 {SIG * SIG:.4f}; ratio {2 * KAP * TH / SIG ** 2:.2f}")
print("Lipschitz ratio of the noise at 0, sigma sqrt(x)/x: " +
      ", ".join(f"x = {x}: {cir(float(x)) / float(x):.1f}" for x in ("0.01", "0.0001", "0.000001")))
hold = max(abs(math.sqrt(i / 1000) - math.sqrt(j / 1000)) / math.sqrt(abs(i - j) / 1000)
           for i in range(0, 41) for j in range(0, 41) if i != j)
grow = max(cir(i / 1000) / (SIG * (1 + i / 1000) / 2) for i in range(0, 1001))
print(f"Hoelder test, max |sqrt x - sqrt y| / sqrt|x - y| on 0 to 0.04: {hold:.4f};"
      f" growth test, max sigma sqrt x / (sigma (1 + x)/2) on 0 to 1: {grow:.4f}")
assert abs(hold - 1.0) < 1e-12 and grow <= 1.0 + 1e-12
xs = [0.002 * i for i in range(11)]
print("figure, rate (percent): " + ", ".join(f"{100 * x:.1f}" for x in xs))
print("figure, noise sigma sqrt(r) (pp): " + ", ".join(f"{100 * cir(x):.2f}" for x in xs))
print("figure, line 2.5 r (pp): " + ", ".join(f"{250 * x:.2f}" for x in xs))
g, N, IT = SplitMix64(SEED), 64, 12       # Picard iteration in mean square, 1000 paths of 64 steps
sq, to_euler = {f: [[] for _ in range(IT)] for f in (cir, cousin)}, []
for _ in range(1000):
    dw = [math.sqrt(1.0 / N) * g.normal() for _ in range(N)]
    for f in (cir, cousin):
        x = [R0] * (N + 1)
        for k in range(IT):
            y, s = [R0], R0
            for i in range(N):
                s += KAP * (TH - max(x[i], 0.0)) / N + f(x[i]) * dw[i]
                y.append(s)
            sq[f][k].append(max(abs(a - b) for a, b in zip(x, y)) ** 2)
            x = y
        if f is cousin:                   # Euler's forward loop: a different road to the fixed point
            e = [R0]
            for i in range(N):
                e.append(e[-1] + KAP * (TH - max(e[-1], 0.0)) / N + f(e[-1]) * dw[i])
            to_euler.append(max(abs(a - b) for a, b in zip(x, e)))
for k in range(IT):
    (mc, sc, _), (mp, sp, _) = mean_se(sq[cir][k]), mean_se(sq[cousin][k])
    print(f"Picard round {k + 1:2d}: E sup gap^2  CIR {mc:.2e} +- {sc:.1e}   cousin {mp:.2e} +- {sp:.1e}")
print("figure, round: " + ", ".join(str(k + 1) for k in range(IT)))
for name, f in (("CIR", cir), ("cousin", cousin)):
    print(f"figure, digits -log10 E sup gap^2, {name}: " + ", ".join(f"{-math.log10(mean_se(sq[f][k])[0]):.2f}" for k in range(IT)))
me, se_e, _ = mean_se(to_euler)
print(f"cousin after {IT} rounds: mean sup gap to Euler's loop {me:.2e} +- {se_e:.1e}")
assert mean_se(sq[cousin][IT - 1])[0] < 1e-8 and mean_se(sq[cir][IT - 1])[0] > 1e-6 and me < 1e-4
g = SplitMix64(SEED + 1)                  # 2000 years on 1024 steps: repaired Euler, plain Euler, explosion
NS, ends = (16, 64, 256, 1024), []
gap, neg, hit = ({n: [] for n in NS} for _ in range(3))
for _ in range(PATHS):
    dw = [math.sqrt(1.0 / FINE) * g.normal() for _ in range(FINE)]
    for n in NS:
        b, dt = FINE // n, 1.0 / n
        tr = rf = pl = R0
        w = wmax = went = 0.0
        for k in range(n):
            d = sum(dw[k * b:(k + 1) * b])
            tr = tr + KAP * (TH - max(tr, 0.0)) * dt + cir(tr) * d             # full truncation
            rf = abs(rf + KAP * (TH - rf) * dt + cir(rf) * d)                  # reflection
            pl = pl + KAP * (TH - pl) * dt + SIG * math.sqrt(pl) * d if pl >= 0 else pl   # plain: stuck below 0
            went = 1.0 if pl < 0 else went
            w += d
            wmax = max(wmax, w)
        gap[n].append(abs(max(tr, 0.0) - rf)); neg[n].append(went)
        hit[n].append(1.0 if wmax >= 1.0 else 0.0)
    ends.append(max(tr, 0.0))
for n in NS:
    (mg, sg, _), (a, sa, _) = mean_se(gap[n]), mean_se(neg[n])
    print(f"n = {n:4d} steps: |truncated - reflected| at 1 year {mg:.5f} +- {sg:.5f};"
          f" plain Euler needs sqrt of a negative: {a:.4f} +- {sa:.4f}")
ratio = mean_se(gap[16])[0] / mean_se(gap[1024])[0]
print(f"gap ratio n = 16 to n = 1024: {ratio:.1f}")
mean_f = TH + (R0 - TH) * math.exp(-KAP)
var_f = R0 * SIG ** 2 / KAP * (math.exp(-KAP) - math.exp(-2 * KAP)) + TH * SIG ** 2 / (2 * KAP) * (1 - math.exp(-KAP)) ** 2
mo, hs = [R0, R0 * R0], 1e-4                 # moment equations from Ito's lemma, Heun's method to t = 1
dm = lambda m: [KAP * (TH - m[0]), (2 * KAP * TH + SIG ** 2) * m[0] - 2 * KAP * m[1]]
for _ in range(10000):
    a = dm(mo); b = dm([mo[i] + hs * a[i] for i in range(2)]); mo = [mo[i] + hs * (a[i] + b[i]) / 2 for i in range(2)]
m, se, v = mean_se(ends)
m4 = sum((x - m) ** 4 for x in ends) / PATHS
sev = math.sqrt((m4 - v * v) / PATHS)
print(f"rate at 1 year: formula mean {mean_f:.6f} sd {math.sqrt(var_f):.6f};"
      f" simulated mean {m:.6f} +- {se:.6f}, variance {v:.3e} +- {sev:.1e} (formula {var_f:.3e})")
print(f"moment equations, step 1e-4: mean {mo[0]:.6f}, variance {mo[1] - mo[0] ** 2:.3e}")
assert abs(mo[0] - mean_f) < 1e-9 and abs(mo[1] - mo[0] ** 2 - var_f) < 1e-9 and ratio > 3.0 and mean_se(neg[1024])[0] > 0.2 and abs(m - mean_f) < 4 * se and abs(v - var_f) < 4 * sev
f, h = (lambda w: 1.0 / (1.0 - w)), 1e-4   # the exploding SDE: X = 1/(1 - W), X0 = 1
f1, f2 = (f(0.3 + h) - f(0.3 - h)) / (2 * h), (f(0.3 + h) - 2 * f(0.3) + f(0.3 - h)) / (h * h)
print(f"Ito's lemma at w = 0.3, X = {f(0.3):.6f}: drift f''/2 = {f2 / 2:.6f} (X^3 = {f(0.3) ** 3:.6f}),"
      f" noise f' = {f1:.6f} (X^2 = {f(0.3) ** 2:.6f})")
assert abs(f2 / 2 - f(0.3) ** 3) < 1e-3 and abs(f1 - f(0.3) ** 2) < 1e-6
p_ex = 2.0 * (1.0 - Phi(1.0))
print(f"explosion by t = 1: Phi(1) = {Phi(1.0):.4f}, reflection principle 2 (1 - Phi(1)) = {p_ex:.4f}; without the noise, x' = x^3 explodes at t = 0.5")
for n in NS:
    mh, sh, _ = mean_se(hit[n])
    print(f"explosion by t = 1, W watched on {n:4d} steps: {mh:.4f} +- {sh:.4f}")
print("figure, explosion percent at n = 16, 64, 256, 1024: " + ", ".join(f"{100 * mean_se(hit[n])[0]:.2f}" for n in NS) + f"; exact {100 * p_ex:.2f}")
assert abs(mean_se(hit[1024])[0] - p_ex) < 4 * mean_se(hit[1024])[1] and mean_se(hit[16])[0] < p_ex
z = (R0 + KAP * (TH - R0) / 12) / (SIG * math.sqrt(R0) * math.sqrt(1 / 12))
print(f"by hand: one monthly Euler step from 1 percent, mean {R0 + KAP * (TH - R0) / 12:.5f}, sd {SIG * math.sqrt(R0 / 12):.5f},"
      f" P(below 0) = Phi(-{z:.4f}) = {Phi(-z):.4f}")
print("ALL CHECKS PASS")
