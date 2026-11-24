# Cramer's theorem and large deviations -- the check behind the card.
# Standard library only (math). Fair coin, share of heads at least 0.6.
# Roads: the rate by formula and by a numerical maximum (Legendre transform);
# the exact tail by log-factorials and by a step-down recursion; the exact
# tail again through the tilting identity; and a tilted simulation.
import math

P, A, N = 0.5, 0.6, 1000

def lam(t, p=P):                        # log-moment function of one flip
    return math.log(1 - p + p * math.exp(t))
def lam_die(t):                         # log-moment function of one die roll
    return math.log(sum(math.exp(t * k) for k in range(1, 7)) / 6)
def kl2(c, p):                          # D((c, 1 - c) || (p, 1 - p))
    return c * math.log(c / p) + (1 - c) * math.log((1 - c) / (1 - p))

def legendre(a, f):                     # sup over t of (t a - f(t)), golden section
    lo, hi, g = -30.0, 30.0, (math.sqrt(5) - 1) / 2
    for _ in range(200):
        x1, x2 = hi - g * (hi - lo), lo + g * (hi - lo)
        lo, hi = (x1, hi) if x1 * a - f(x1) < x2 * a - f(x2) else (lo, x2)
    t = (lo + hi) / 2
    return t, t * a - f(t)

LF = [0.0]                              # LF[k] = ln k!
for i in range(1, 100001): LF.append(LF[-1] + math.log(i))

def log_pmf(n, k, p): return LF[n] - LF[k] - LF[n - k] + k * math.log(p) + (n - k) * math.log(1 - p)

def log_tail(n, k0, p=P):               # road 1: ln P(S >= k0), summed in log space
    lt = [log_pmf(n, k, p) for k in range(k0, n + 1)]; m = max(lt)
    return m + math.log(sum(math.exp(x - m) for x in lt))

def tail_recursion(n, k0):              # road 2: start at P(S = n) = 2^-n, step down
    term = 0.5 ** n; total = term
    for k in range(n, k0, -1):
        term *= k / (n - k + 1); total += term
    return total

def log_normal_tail(z):                 # ln P(G >= z) for large z, Laplace's continued fraction
    cf = z
    for k in range(80, 0, -1): cf = z + k / cf
    return -z * z / 2 - math.log(math.sqrt(2 * math.pi)) - math.log(cf)

def ceil_share(n, num, den): return -(-num * n // den)

def row(label, v): print(f"{label:<58} {v}")
# The rate, two roads
I = kl2(A, P)
t_num, I_num = legendre(A, lam)
theta = math.log(A * (1 - P) / (P * (1 - A)))
row("I(0.6) = 0.6 ln 1.2 + 0.4 ln 0.8", f"{I:.6f}")
row("I(0.6) by maximising 0.6 t - ln M(t): best t", f"{t_num:.6f}")
row("I(0.6) by maximising 0.6 t - ln M(t): value", f"{I_num:.6f}")
row("tilt theta = ln 1.5; tilted coin's chance of heads", f"{theta:.6f} {P * math.exp(theta) / (1 - P + P * math.exp(theta)):.4f}")
row("quadratic guess (a - mu)^2 / (2 sigma^2)", f"{(A - P) ** 2 / (2 * P * (1 - P)):.6f}")
for t in (0.2, 1.0):
    row(f"Chernoff exponent at a guessed dial t = {t}", f"{t * A - lam(t):.6f}")
row("Chernoff bound at t = 0.2, n = 1000", f"{math.exp(-N * (0.2 * A - lam(0.2))):.3e}")
print("chart, Lambda(t)    " + " ".join(f"{lam(i / 10):.3f}" for i in range(11)))
print("chart, 0.6 t        " + " ".join(f"{0.6 * i / 10:.3f}" for i in range(11)))
print("chart, gap          " + " ".join(f"{0.6 * i / 10 - lam(i / 10):.4f}" for i in range(11)))
# The exact chance at n = 1000, two roads, against the bound
k0 = ceil_share(N, 6, 10)
lt = log_tail(N, k0); exact = math.exp(lt); rec = tail_recursion(N, k0); bound = math.exp(-N * I)
row("n = 1000: exact P(S >= 600), log-factorials", f"{exact:.4e}")
row("n = 1000: exact P(S >= 600), step-down recursion", f"{rec:.4e}")
row("n = 1000: (1/n) ln P", f"{lt / N:.4f}")
row("n = 1000: bound e^(-nI)", f"{bound:.3e}")
row("n = 1000: bound / exact", f"{bound / exact:.1f}")
# The tilting identity and the lower bound's window
pref = sum(math.exp(log_pmf(N, k, A) - theta * (k - k0)) for k in range(k0, N + 1))
row("prefactor E_Q[e^(-theta (S - 600)); S >= 600]", f"{pref:.4f}")
row("e^(-nI) x prefactor", f"{bound * pref:.4e}")
sq = math.sqrt(A * (1 - A))
br = 1 / ((1 - math.exp(-theta)) * sq * math.sqrt(2 * math.pi * N))
row("Bahadur-Rao prefactor 1/((1 - e^-theta) sigma_Q sqrt(2 pi n))", f"{br:.4f}")
qw = sum(math.exp(log_pmf(N, k, A)) for k in range(k0, ceil_share(N, 62, 100) + 1))
low = math.exp(-N * (I + theta * 0.02)) * qw
row("window: Q(600 <= S <= 620)", f"{qw:.4f}")
row("window: lower bound e^(-n(I + 0.02 theta)) Q(window)", f"{low:.3e}")
row("window: limit of (1/n) ln, -(I + 0.02 theta)", f"{-(I + theta * 0.02):.6f}")
# The approach to -I as n grows
ns = [50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000]
rates = [log_tail(n, ceil_share(n, 6, 10)) / n for n in ns]
print("chart, n            " + " ".join(f"{n}" for n in ns))
print("chart, (1/n) ln P   " + " ".join(f"{r:.4f}" for r in rates))
print("chart, -I           " + " ".join(f"{-I:.4f}" for _ in ns))
# The bell curve far out: share 0.8 at n = 1000
z8 = 300 / math.sqrt(N * 0.25); I8, lt8, ln8 = kl2(0.8, P), log_tail(N, 800), log_normal_tail(z8)
row("share 0.8: I(0.8) against quadratic 0.18", f"{I8:.6f}")
row("share 0.8: exact P(S >= 800)", f"{math.exp(lt8):.3e}")
row("share 0.8: bell-curve tail at z = 18.97", f"{math.exp(ln8):.3e}")
row("share 0.6: bell-curve tail at z = 6.32", f"{math.exp(log_normal_tail(100 / math.sqrt(N * 0.25))):.3e}")
# Sanov, two letters: the type (0.6, 0.4) at n = 1000
tp = math.exp(log_pmf(N, k0, P))
row("Sanov: D((0.6, 0.4) || (0.5, 0.5))", f"{kl2(A, P):.6f}")
row("Sanov: P(type = (0.6, 0.4)), with its two bounds", f"{tp:.3e} in [{bound / (N + 1) ** 2:.3e}, {bound:.3e}]")
# The house die: average at least 4.4
lo, hi = 0.0, 5.0
for _ in range(200):
    mid = (lo + hi) / 2
    w = [math.exp(mid * k) for k in range(1, 7)]
    lo, hi = (mid, hi) if sum(k * x for k, x in zip(range(1, 7), w)) / sum(w) < 4.4 else (lo, mid)
q = [x / sum(w) for x in w]
Id = sum(x * math.log(6 * x) for x in q)
td, Id_num = legendre(4.4, lam_die)
row("die: tilt theta to mean 4.4; D(tilt || fair)", f"{lo:.6f} {Id:.6f}")
row("die: I(4.4) by maximising 4.4 t - ln M(t)", f"{Id_num:.6f}")
# A tilted simulation against a plain one, splitmix64, same seed in Rust
s = 20261123
def nxt():
    global s
    s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return (z ^ (z >> 31)) >> 11
R = 4000
cut_q, cut_p = int(A * 2 ** 53), int(P * 2 ** 53)
ws, hits = [], 0
for _ in range(R):
    S = sum(1 for _ in range(N) if nxt() < cut_q)
    ws.append(math.exp(S * math.log(P / A) + (N - S) * math.log((1 - P) / (1 - A))) if S >= k0 else 0.0)
    if sum(1 for _ in range(N) if nxt() < cut_p) >= k0: hits += 1
est = sum(ws) / R; se = math.sqrt(sum((x - est) ** 2 for x in ws) / (R - 1) / R)
row("simulation, 4000 runs: plain coin, runs with S >= 600", f"{hits}")
row("simulation, 4000 runs: tilted coin, estimate and std error", f"{est:.4e} {se:.1e}")

assert abs(I - I_num) < 1e-9 and abs(t_num - theta) < 1e-6, "Legendre maximum vs closed form"
assert abs(rec - exact) < 1e-9 * exact, "two exact roads"
assert exact <= bound and all(r <= -I for r in rates), "Chernoff bound never exceeded"
assert abs(bound * pref - exact) < 1e-9 * exact, "tilting identity"
assert low <= exact and abs(br - pref) < 0.05 * pref, "lower bound and prefactor"
assert abs(rates[-1] + I) < 1e-4 and rates == sorted(rates), "(1/n) ln P rises to -I"
assert bound / (N + 1) ** 2 <= tp <= bound, "Sanov type bounds"
assert abs(Id - Id_num) < 1e-9 and abs(Id - 0.143213) < 1e-6, "die: two roads to I(4.4)"
assert abs(est - exact) < 4 * se and hits == 0, "tilted simulation"
c8 = math.exp(ln8 + z8 * z8 / 2) * math.sqrt(2 * math.pi)    # tail / phi, between two Mills series bounds
assert 1 / z8 - z8 ** -3 < c8 < 1 / z8 - z8 ** -3 + 3 * z8 ** -5 and ln8 > lt8 + 10, "bell curve: Mills bounds; overstates"
print("ALL CHECKS PASS")
