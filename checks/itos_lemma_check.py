# Ito's lemma -- the check behind the card.  Only math is imported.
# A $100 share follows dS = mu S dt + sigma S dW, mu = 0.10, sigma = 0.40 a year.
# Roads to the log drift mu - sigma^2/2 = 0.02: the formula; Euler's step rule
# averaged exactly by Simpson's rule (no Ito used); 4000 seeded paths, checked
# path by path; and W squared split exactly into an Ito sum plus its squares.
import math

S0, MU, SIG, T = 100.0, 0.10, 0.40, 1.0
SEED, PATHS, FINE, GRIDS = 20260930, 4000, 1024, (16, 64, 256, 1024)
MASK = (1 << 64) - 1

class SplitMix64:                         # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                     # Box-Muller, cosine half
        u1, u2 = self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)

def phi(z):                               # bell-curve height
    return math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi)

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def ncdf(x):                              # bell-curve area left of x
    return 0.5 + simpson(phi, 0.0, x, 2000)

def euler_log_drift(n):                   # n E[log(1 + mu dt + sigma sqrt(dt) Z)] / T
    dt = T / n
    f = lambda z: math.log(1.0 + MU * dt + SIG * math.sqrt(dt) * z) * phi(z)
    return n * simpson(f, -9.0, 9.0, 6000) / T

ito, naive, wrong_sign = MU - 0.5 * SIG * SIG, MU, MU + 0.5 * SIG * SIG
print(f"share: S0 {S0:.0f} dollars, mu {MU:.2f} and sigma {SIG:.2f} a year, T {T:.0f} year")
print(f"road 1, Ito's lemma: log drift mu - sigma^2/2   {ito:.6f}")
print(f"ordinary chain rule: log drift mu               {naive:.6f}")
print(f"median price after a year, S0 e^(0.02)          {S0 * math.exp(ito * T):.4f}")
print(f"mean price after a year, S0 e^(0.10)            {S0 * math.exp(MU * T):.4f}")
p_below = ncdf(-ito * T / (SIG * math.sqrt(T)))
print(f"chance below 100 after a year, N(-0.05)         {p_below:.6f}")

print("road 2, Euler's rule averaged exactly over the bell curve:")
errs = []
for n in GRIDS:
    d, mp = euler_log_drift(n), S0 * (1.0 + MU * T / n) ** n
    errs.append(d - ito)
    print(f"  steps {n:5d}   log drift {d:.6f}   error {d - ito:+.6f}   mean price {mp:.4f}")

g = SplitMix64(SEED)
acc = {n: [0.0] * 6 for n in GRIDS}   # log, log^2, |gap to Ito|, |gap to ordinary|, their squares
price, price2, below = 0.0, 0.0, 0
w2, w4, left, left2, right, right2 = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
first = []
for p in range(PATHS):
    dw = [g.normal() * math.sqrt(T / FINE) for _ in range(FINE)]
    wT = sum(dw)
    for n in GRIDS:
        m, dt, s = FINE // n, T / n, S0
        w, lsum, qv = 0.0, 0.0, 0.0
        for k in range(n):
            step = sum(dw[k * m:(k + 1) * m])
            s *= 1.0 + MU * dt + SIG * step
            lsum += w * step
            qv += step * step
            w += step
        lg = math.log(s / S0)
        a = acc[n]
        gi, go = abs(lg - ito * T - SIG * wT), abs(lg - naive * T - SIG * wT)
        a[0] += lg; a[1] += lg * lg; a[2] += gi; a[3] += go; a[4] += gi * gi; a[5] += go * go
        if p == 0:
            first.append((n, wT * wT, 2.0 * lsum, qv))
    price += s; price2 += s * s; below += 1 if s < S0 else 0
    w2 += wT * wT; w4 += wT ** 4; left += lsum; left2 += lsum * lsum
    right += lsum + qv; right2 += (lsum + qv) ** 2

print(f"road 3, {PATHS} seeded paths (seed {SEED}), one-year Euler runs on nested grids:")
for n in GRIDS:
    a = acc[n]
    mean = a[0] / PATHS
    se, gi, go = (math.sqrt((a[q] / PATHS - (a[k] / PATHS) ** 2) / PATHS) for k, q in ((0, 1), (2, 4), (3, 5)))
    print(f"  steps {n:5d}   mean log drift {mean:.4f} (se {se:.4f})   |gap to Ito| {a[2] / PATHS:.4f}"
          f" (se {gi:.5f})   |gap to ordinary| {a[3] / PATHS:.4f} (se {go:.5f})")
mlog = acc[1024][0] / PATHS
se_log = math.sqrt((acc[1024][1] / PATHS - mlog * mlog) / PATHS)
mprice = price / PATHS; se_price = math.sqrt((price2 / PATHS - mprice * mprice) / PATHS)
frac = below / PATHS; se_frac = math.sqrt(frac * (1.0 - frac) / PATHS)
print(f"  1024 steps: mean price {mprice:.2f} (se {se_price:.2f}), below 100 {frac:.4f} (se {se_frac:.4f})")

print("W squared on path 1: W_T^2 = 2 sum W dW + sum dW^2, exactly")
for n, wsq, two_left, qv in first:
    print(f"  steps {n:5d}   W_T^2 {wsq:.6f}   2 sum W dW {two_left:+.6f}   sum dW^2 {qv:.6f}"
          f"   sd of sum dW^2 {math.sqrt(2.0 / n):.4f}")
mw2, mleft, mright = w2 / PATHS, left / PATHS, right / PATHS
se_w2 = math.sqrt((w4 / PATHS - mw2 * mw2) / PATHS)
se_left = math.sqrt((left2 / PATHS - mleft * mleft) / PATHS)
se_right = math.sqrt((right2 / PATHS - mright * mright) / PATHS)
print(f"W squared over {PATHS} paths, 1024 steps: mean W_T^2 {mw2:.4f} (se {se_w2:.4f})")
print(f"  mean of sum W dW, left ends {mleft:+.4f} (se {se_left:.4f});  right ends {mright:+.4f} (se {se_right:.4f})")

print("what breaks:")
print(f"  ordinary rule on W^2: mean W_T^2 would be 2 x {mleft:+.4f}; it is {mw2:.4f}")
print(f"  ordinary rule on log S: median {S0 * math.exp(naive * T):.2f}, below 100"
      f" {ncdf(-naive * T / (SIG * math.sqrt(T))):.4f}")
print(f"  plus sign on sigma^2/2: log drift {wrong_sign:.4f}, median {S0 * math.exp(wrong_sign * T):.2f}")

print("chart, years " + " ".join(f"{t:7d}" for t in range(11)))
print("chart, mean   " + " ".join(f"{S0 * math.exp(MU * t):7.2f}" for t in range(11)))
print("chart, median " + " ".join(f"{S0 * math.exp(ito * t):7.2f}" for t in range(11)))

gaps = [math.log(x / 100.0) - (x - 100.0) / 100.0 for x in (60.0, 140.0)]
print(f"convexity: log gap below tangent at 60 {gaps[0]:+.4f}, at 140 {gaps[1]:+.4f},"
      f" average {(gaps[0] + gaps[1]) / 2:+.4f}; Ito's -sigma^2/2 {-0.5 * SIG * SIG:+.4f}")
pts = [(40 + 3 * (x - 50), 110 - 160 * math.log(x / 100.0)) for x in range(50, 151, 10)]
print("figure, curve " + " ".join(f"{px:.0f},{py:.1f}" for px, py in pts))
print(f"figure, tangent 40,{110 - 160 * -0.5:.1f} 340,{110 - 160 * 0.5:.1f};"
      f" at 60 tangent {110 - 160 * -0.4:.1f} curve {110 - 160 * math.log(0.6):.1f};"
      f" at 140 tangent {110 - 160 * 0.4:.1f} curve {110 - 160 * math.log(1.4):.1f}")

assert abs(errs[-1]) < 1e-4, "Euler's exact log drift must close on mu - sigma^2/2"
assert abs(errs[0]) > abs(errs[1]) > abs(errs[2]) > abs(errs[3]), "the step error must shrink"
assert abs(mlog - ito) < 4 * se_log, "simulated log drift within 4 se of Ito"
assert abs(mlog - naive) > 8 * se_log, "the ordinary chain rule is measurably wrong"
assert acc[1024][2] / PATHS < 0.01, "path by path, Euler closes on Ito's formula"
assert acc[1024][2] < acc[16][2] / 4, "the path-by-path gap shrinks with the step"
assert acc[1024][3] / PATHS > 0.07, "the ordinary formula stays 0.08 off on every grid"
assert abs(mw2 - T) < 4 * se_w2, "E[W_T^2] = T, the dt term of Ito on x^2"
assert abs(mleft) < 4 * se_left, "the Ito sum has mean zero"
assert abs(mright - T) < 4 * se_right, "the right-end sum has mean T, not zero"
assert abs(frac - p_below) < 4 * se_frac, "chance below 100 matches N(-0.05)"
print("ALL CHECKS PASS")
