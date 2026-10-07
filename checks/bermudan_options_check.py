# Bermudan put -- the check behind the card.  Standard library only; nothing
# imported knows the answer.  House market: S = K = 100, r = 5%, q = 2%,
# sigma = 20%, one year.  Roads: a CRR tree with the exercise check gated to
# the listed dates; a log-price grid rolled back by quadrature; the closed form
# (one date) and a one-date-added integral (two dates); least-squares Monte Carlo.
from math import exp, log, sqrt, pi, cos, ceil
S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0

def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3
def N(x): return 0.5 + simpson(phi, 0.0, x, 200)          # normal CDF, built here
def bs_put(s, t):                                          # European put, closed form
    d1 = (log(s / K) + (r - q + 0.5 * sig * sig) * t) / (sig * sqrt(t))
    return K * exp(-r * t) * N(sig * sqrt(t) - d1) - s * exp(-q * t) * N(-d1)

def every(n, m): return [k * n // m for k in range(1, m + 1)]   # m evenly spaced dates as tree steps
def tree(n, listed, greedy=False):   # Road 1: CRR tree, exercise compared only on listed steps
    dt = T / n; u = exp(sig * sqrt(dt)); d = 1 / u
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt); listed = set(listed); edge = {}
    v = [max(K - S * u ** j * d ** (n - j), 0.0) for j in range(n + 1)]
    for i in range(n - 1, -1, -1):
        v = [disc * (p * v[j + 1] + (1 - p) * v[j]) for j in range(i + 1)]
        if i in listed:                                     # the gate
            ex = [K - S * u ** j * d ** (i - j) for j in range(i + 1)]
            edge[i] = max([S * u ** j * d ** (i - j) for j in range(i + 1) if ex[j] > v[j]], default=0.0)
            v = [(e if e > 0 else c) if greedy else max(c, e) for c, e in zip(v, ex)]
    return v[0], edge

def grid(m, h=0.002, M=800):   # Road 2: log-price grid, rolled back date to date by quadrature
    dt = T / m; s = sig * sqrt(dt); mu = (r - q - 0.5 * sig * sig) * dt
    x = [log(S) + (i - M) * h for i in range(2 * M + 1)]
    w = [h * exp(-r * dt) * phi((k * h - mu) / s) / s for k in range(-2 * M, 2 * M + 1)]
    c = ceil(9 * s / h)
    v = [max(K - exp(xi), 0.0) for xi in x]
    for k in range(m - 1, -1, -1):
        new = [0.0] * (2 * M + 1)
        for i in range(max(0, M - k * c), min(2 * M, M + k * c) + 1):
            lo, hi = max(0, i - c), min(2 * M, i + c)
            new[i] = sum(v[j] * w[j - i + 2 * M] * (0.5 if j in (0, 2 * M) else 1.0) for j in range(lo, hi + 1))
            if k > 0: new[i] = max(new[i], K - exp(x[i]))
        v = new
    return v[M]

def s_half(z): return S * exp((r - q - 0.5 * sig * sig) * 0.5 + sig * sqrt(0.5) * z)
def gain(z): return K - s_half(z) - bs_put(s_half(z), 0.5)   # exercise at 6 months minus holding to expiry
lo, hi = -6.0, 0.0                                             # Road 3: bisection for where the gain turns positive
for _ in range(60):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if gain(mid) > 0 else (lo, mid)
z_star = lo
insert = exp(-r * 0.5) * simpson(lambda z: gain(z) * phi(z), -8.0, z_star, 2000)

state = 0x9E3779B97F4A7C15                                     # Road 4: least-squares Monte Carlo, quarterly
def uniform():                                                 # xorshift64*, a random-number generator written here
    global state
    state ^= state >> 12; state ^= (state << 25) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) * 2.0 ** -53 + 2.0 ** -54
def paths(n, m=4):
    dt = T / m; out = []
    for _ in range(n):
        s, row = S, []
        for _ in range(m):
            z = sqrt(-2 * log(uniform())) * cos(2 * pi * uniform())
            s *= exp((r - q - 0.5 * sig * sig) * dt + sig * sqrt(dt) * z); row.append(s)
        out.append(row)
    return out
def fit(pts):                  # least squares of y on 1, x, x^2 via the 3x3 normal equations
    A = [[0.0] * 4 for _ in range(3)]
    for x, y in pts:
        f = (1.0, x, x * x)
        for a in range(3):
            for b in range(3): A[a][b] += f[a] * f[b]
            A[a][3] += f[a] * y
    for a in range(3):
        for b in range(a + 1, 3):
            t = A[b][a] / A[a][a]; A[b] = [A[b][c] - t * A[a][c] for c in range(4)]
    beta = [0.0] * 3
    for a in (2, 1, 0): beta[a] = (A[a][3] - sum(A[a][c] * beta[c] for c in range(a + 1, 3))) / A[a][a]
    return beta
def take(b, s): return s < K and K - s > b[0] + b[1] * (s / K) + b[2] * (s / K) ** 2
dq = exp(-r * T / 4); train = paths(40000); cash = [max(K - row[3], 0.0) for row in train]; betas = {}
for k in (2, 1, 0):
    cash = [c * dq for c in cash]
    betas[k] = b = fit([(row[k] / K, c) for row, c in zip(train, cash) if row[k] < K])
    cash = [K - row[k] if take(b, row[k]) else c for row, c in zip(train, cash)]
pay, peek = [], []
for row in paths(100000):      # fresh paths: follow the fitted rule; and, for contrast, peek at the future
    got = exp(-r * T) * max(K - row[3], 0.0)
    for k in (0, 1, 2):
        if take(betas[k], row[k]): got = exp(-r * T * (k + 1) / 4) * (K - row[k]); break
    pay.append(got); peek.append(max(exp(-r * T * (k + 1) / 4) * max(K - row[k], 0.0) for k in range(4)))
lsm = sum(pay) / len(pay); se = sqrt((sum(v * v for v in pay) / len(pay) - lsm * lsm) / len(pay))

eu = bs_put(S, T)
(t1, _), (t2, e2), (t4, e4) = tree(2000, every(2000, 1)), tree(2000, every(2000, 2)), tree(2000, every(2000, 4))
(t12, _), (t52, _), (tam, _) = tree(2400, every(2400, 12)), tree(2080, every(2080, 52)), tree(2000, range(2001))
greedy, early, late = tree(2000, every(2000, 4), True)[0], tree(2000, [500, 2000])[0], tree(2000, [1500, 2000])[0]
g1, g2, g4, g12 = grid(1), grid(2), grid(4), grid(12)
u2 = exp(sig * sqrt(0.5)); d2 = 1 / u2; p2 = (exp((r - q) * 0.5) - d2) / (u2 - d2); dc = exp(-r * 0.5)
hold = dc * (1 - p2) * (K - S * d2 * d2)                        # the by-hand tree: two half-year steps
berm2, euro2 = dc * (1 - p2) * max(hold, K - S * d2), dc * (1 - p2) * hold
rows = [("European put, closed form", eu), ("1 date, tree 2000 steps", t1), ("1 date, grid", g1),
        ("2 dates, tree 2000 steps", t2), ("2 dates, grid", g2), ("2 dates, closed form + insertion", eu + insert),
        ("4 dates, tree 2000 steps", t4), ("4 dates, grid", g4), ("4 dates, LSM 40000 fit/100000 run", lsm),
        ("  its standard error", se), ("12 dates, tree 2400 steps", t12), ("12 dates, grid", g12),
        ("52 dates, tree 2080 steps", t52), ("every step, tree 2000 steps", tam),
        ("value of the 6-month date alone", insert), ("6-month critical price", s_half(z_star)),
        ("  tree, highest node exercised", e2[1000]),
        ("quarterly boundary, 3 months", e4[500]), ("quarterly boundary, 6 months", e4[1000]),
        ("quarterly boundary, 9 months", e4[1500]),
        ("wrong: check at every step", tam), ("wrong: exercise whenever in money", greedy),
        ("wrong: peek at the future (MC)", sum(peek) / len(peek)),
        ("timing: dates at 3 months + expiry", early), ("timing: dates at 9 months + expiry", late),
        ("hand: up factor u", u2), ("hand: down factor d", d2), ("hand: up chance p", p2), ("hand: half-year discount", dc),
        ("hand: low price at 6 months", S * d2), ("hand: low price at expiry", S * d2 * d2), ("hand: put pays there", K - S * d2 * d2),
        ("hand: hold at the low 6-month node", hold), ("hand: exercise there", K - S * d2),
        ("hand: Bermudan today", berm2), ("hand: European today", euro2)]
for label, v in rows: print(f"{label:<36}{v:>12.6f}")
ladder = [t1, t2, t4, t12, t52, tam]
print("chart, price by dates  " + " ".join(f"{v:.2f}" for v in ladder))
print("share of American premium, %  " + " ".join(f"{100 * (v - t1) / (tam - t1):.1f}" for v in ladder))

assert abs(g1 - eu) < 1e-4, "grid with one date must return the closed-form European"
assert abs(t1 - eu) < 2e-3, "tree with one date must return the European, to tree accuracy"
assert abs(g2 - (eu + insert)) < 1e-4, "two dates: grid vs closed form plus insertion integral"
assert abs(t4 - g4) < 2e-3, "tree vs grid, quarterly"
assert abs(t12 - g12) < 2e-3, "tree vs grid, monthly"
assert t1 < t2 < t4 < t12 < t52 < tam, "more dates can never be worth less"
assert abs(lsm - g4) < 3 * se, "least squares within three standard errors of the grid"
assert e2[1000] <= s_half(z_star) < e2[1000] * exp(2 * sig * sqrt(T / 2000)), "tree edge brackets the critical price"
assert abs(berm2 - tree(2, [1, 2])[0]) < 1e-12, "hand arithmetic vs the general tree, two steps"
assert greedy < t4 < sum(peek) / len(peek), "a bad rule is worth less, foresight more"
print("ALL CHECKS PASS")
