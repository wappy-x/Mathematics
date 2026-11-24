# Malliavin calculus in outline -- the check behind the card.  Standard library only.
# A digital call pays $1 if a share, now $100, ends one year above $100 (volatility 20%,
# no interest).  Its delta from the Malliavin weight, E[1{S_T > K} W_T] / (S0 sigma T),
# against the exact phi(d2) / (S0 sigma); then the duality and Clark-Ocone by simulation.
from math import sqrt, exp, log, cos, pi

S0, K, SIG, T = 100.0, 100.0, 0.2, 1.0
MASK = (1 << 64) - 1
class Rng:                                        # SplitMix64, normals by Box-Muller
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    def normal(self):
        u1 = self.u()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * self.u())
def pdf(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height phi
def cdf(x):                                       # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    term, total, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1; term *= x * x / (2 * k + 1); total += term
    return 0.5 + pdf(x) * total
def d2(s, tau): return (log(s / K) - 0.5 * SIG * SIG * tau) / (SIG * sqrt(tau))
def value(s, tau): return cdf(d2(s, tau))         # digital's fair value, rate 0
def share(w, s0=S0): return s0 * exp(-0.5 * SIG * SIG * T + SIG * w)
def mse(xs):                                      # mean and its standard error
    n = len(xs); m = sum(xs) / n
    return m, sqrt(sum((x - m) ** 2 for x in xs) / (n - 1) / n)
def simpson(f, a, b, n=4000):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))

# Road 1: closed form.  Road 2: bump the exact price.  Road 3: quadrature of E[1{S_T>K} W_T].
z2 = d2(S0, T); delta = pdf(z2) / (S0 * SIG * sqrt(T))
bump = (value(S0 + 0.01, T) - value(S0 - 0.01, T)) / 0.02
wstar = (log(K / S0) + 0.5 * SIG * SIG * T) / SIG          # S_T > K exactly when W_T > wstar
quad = simpson(lambda w: w * pdf(w / sqrt(T)) / sqrt(T), wstar, 10.0)
print(f"d2 = (ln(S0/K) - sigma^2 T/2)/(sigma sqrt T)  {z2:.6f}")
print(f"phi(d2), bell-curve height                    {pdf(z2):.6f}")
print(f"digital value N(d2), dollars                  {value(S0, T):.6f}")
print(f"S_T > K exactly when W_T >                    {wstar:.6f}")
print(f"delta exact phi(d2)/(S0 sigma sqrt T)         {delta:.6f}")
print(f"delta by bumping the exact price 1 cent       {bump:.6f}")
print(f"E[1{{S_T>K}} W_T] by quadrature                 {quad:.6f}")
print(f"quadrature / (S0 sigma T)                     {quad / (S0 * SIG * T):.6f}")
assert abs(bump - delta) < 1e-7 and abs(quad - pdf(z2)) < 1e-9

# Road 4: Monte Carlo, 102,400 paths; W at half a year and at the year's end.
rng, N = Rng(20261123), 102400
wh = [sqrt(0.5 * T) * rng.normal() for _ in range(N)]
wt = [a + sqrt(0.5 * T) * rng.normal() for a in wh]
mall = [(share(w) > K) * w / (S0 * SIG * T) for w in wt]
half = [(share(w) > K) * a / (S0 * SIG * T) for a, w in zip(wh, wt)]
def bumped(h): return [((share(w, S0 + h) > K) - (share(w, S0 - h) > K)) / (2 * h) for w in wt]
b1, b001 = bumped(1.0), bumped(0.01)
m_val, s_val = mse([float(share(w) > K) for w in wt])      # the value itself, by a road that skips d2
print(f"MC digital value, mean of 1{{S_T>K}}            {m_val:.6f} +- {s_val:.6f}")
assert abs(m_val - value(S0, T)) < 4 * s_val
for name, xs in [("Malliavin weight", mall), ("bump h = $1, same draws", b1),
                 ("bump h = 1 cent, same draws", b001), ("weight W_{T/2} (wrong)", half)]:
    m, s = mse(xs); print(f"MC delta, {name:36s}{m:.6f} +- {s:.6f}")
m_mall, s_mall = mse(mall); m_b1, s_b1 = mse(b1); m_half, s_half = mse(half)
print(f"MC delta, pathwise (payoff slope is 0)        {0.0:.6f} +- {0.0:.6f}")
print(f"paths needed, bump $1 / Malliavin, same error {(s_b1 / s_mall) ** 2:.2f}")
assert abs(m_mall - delta) < 4 * s_mall and abs(m_half - delta / 2) < 4 * s_half
assert s_b1 > 2 * s_mall
for n in (400, 1600, 6400, 25600, 102400):
    print(f"chart, paths {n:6d}  Malliavin {sum(mall[:n]) / n:.6f}  bump $1 {sum(b1[:n]) / n:.6f}")

# The duality E[F W_T] = E[integral of D_t F dt], with F = W_T^3 and F = S_T.
c3l, s3l = mse([w ** 4 for w in wt]); c3r, s3r = mse([3 * w * w * T for w in wt])
csl, ssl = mse([share(w) * w for w in wt]); csr, ssr = mse([SIG * share(w) * T for w in wt])
print(f"F = W_T^3: E[F W_T] = {c3l:.4f} +- {s3l:.4f}   E[3 W_T^2 T] = {c3r:.4f} +- {s3r:.4f}   exact 3")
print(f"F = S_T:   E[F W_T] = {csl:.4f} +- {ssl:.4f}   E[sigma S_T T] = {csr:.4f} +- {ssr:.4f}  exact {S0 * SIG * T:.0f}")
assert abs(c3l - 3 * T * T) < 4 * s3l and abs(csl - S0 * SIG * T) < 4 * ssl

# Clark-Ocone.  W_T^2 = T + int 2 W_t dW_t; mean of W = int (T - s) dW_s; the digital's shares.
rng, P, n = Rng(7), 2000, 500
dt = T / n; miss2, avg = [], []
for _ in range(P):
    w = a = g = 0.0
    for _ in range(n):
        dw = sqrt(dt) * rng.normal(); a += w * dt; g += 2 * w * dw; w += dw
    miss2.append((w * w - (T + g)) ** 2); avg.append(a)
rms = sqrt(sum(miss2) / P); ma, _ = mse(avg)
va = sum((x - ma) ** 2 for x in avg) / (P - 1); vgrid = sum((T - j * dt) ** 2 * dt for j in range(1, n + 1))
print(f"W_T^2 hedge, 500 steps: RMS miss {rms:.6f}, exact sqrt(2/500) {sqrt(2 * T * T / n):.6f}")
print(f"mean of W: variance {va:.4f} +- {va * sqrt(2 / (P - 1)):.4f}, isometry on grid {vgrid:.4f}, limit 1/3")
assert abs(rms - sqrt(2 * T * T / n)) < 0.1 * sqrt(2 * T * T / n) and abs(va - vgrid) < 4 * va * sqrt(2 / (P - 1))
for t, s in [(0.0, 100.0), (0.5, 110.0), (0.5, 100.0), (1 - 1 / 252, 100.0)]:
    tau = T - t; co = pdf(d2(s, tau)) / sqrt(tau); h = co / (SIG * s)
    fd = (value(s + 0.01, tau) - value(s - 0.01, tau)) / 0.02
    print(f"t = {t:.4f}, S = {s:.0f}: E[D_t F | F_t] = {co:.6f}, shares {h:.6f}, bumped slope {fd:.6f}")
    assert abs(h - fd) < 1e-4 * h + 1e-9
print("ALL CHECKS PASS")
