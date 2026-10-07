# Greeks under jumps -- the check behind the card.  Standard library only; the normal CDF, random
# numbers, integrator and root finder are written here.  House market: Acme $100, strike $100, rate 5%,
# dividends 2%, one year, diffusion vol 20%; jumps 0.5 a year, log-size mean -0.10, log-size spread 0.15.
from math import exp, log, sqrt, pi, cos
R, Q, SIG, LAM, MU, DL, M64, SEED = 0.05, 0.02, 0.20, 0.5, -0.10, 0.15, (1 << 64) - 1, [20260924]
HP = (0.0352624965998911, 0.700383064443688, 6.37396220353165, 33.912866078383,
      112.079291497871, 221.213596169931, 220.206867912376)
HQ = (0.0883883476483184, 1.75566716318264, 16.064177579207, 86.7807322029461,
      296.564248779674, 637.333633378831, 793.826512519948, 440.413735824752)

def N(x):                                   # normal CDF: Hart's 1968 rational form
    a, b, d = abs(x), 0.0, 0.0
    if a < 7.07106781186547:
        for c in HP: b = b * a + c
        for c in HQ: d = d * a + c
        c = exp(-a * a / 2) * b / d
    else: c = exp(-a * a / 2) / (a + 1 / (a + 2 / (a + 3 / (a + 4 / (a + 0.65))))) / 2.506628274631
    return 1 - c if x > 0 else c
def phi(x): return exp(-x * x / 2) / sqrt(2 * pi)
def merton(S, K, tau, lam=LAM, mu=MU, dl=DL, sg=SIG, M=12):   # price, delta, gamma, vega
    k, w, out = exp(mu + dl * dl / 2) - 1, exp(-lam * tau), [0.0] * 4
    for n in range(M):                      # one Black-Scholes term per jump count n
        vt = sqrt(sg * sg * tau + n * dl * dl)              # sigma_n times root tau
        qn = Q + lam * k - n * (mu + dl * dl / 2) / tau      # compensator and recentring
        d1 = (log(S / K) + (R - qn) * tau) / vt + vt / 2
        a = w * exp(-qn * tau)
        out = [o + v for o, v in zip(out, (a * S * N(d1) - w * K * exp(-R * tau) * N(d1 - vt), a * N(d1),
                                           a * phi(d1) / (S * vt), a * S * phi(d1) * sg * tau / vt))]
        w *= lam * tau / (n + 1)
    return out
def simpson(f, a, b, n=64):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def u():                                    # splitmix64: a uniform number in (0, 1)
    SEED[0] = (SEED[0] + 0x9E3779B97F4A7C15) & M64
    z = ((SEED[0] ^ (SEED[0] >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
def g(): u1 = u(); return sqrt(-2 * log(u1)) * cos(2 * pi * u())    # Box-Muller normal
def hedge(path, lam, f):                    # seller's book at expiry, rebalanced f times
    step, h, (c, d) = (len(path) - 1) // f, 1 / f, merton(100, 100, 1, lam)[:2]
    bank, sh = c - d * 100, d
    for j in range(1, f + 1):
        S = path[j * step]; bank *= exp(R * h); sh *= exp(Q * h)   # dividends buy shares
        if j < f: dn = merton(S, 100, 1 - j * h, lam, M=6 if lam else 1)[1]; bank -= (dn - sh) * S; sh = dn
    return sh * S + bank - max(S - 100, 0)
def show(label, *v, f="{:>12.6f}"): print(f"{label:<36}" + "".join(f.format(x) for x in v))
def iv(price, K, lo=0.01, hi=1.0):          # implied vol by bisection
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if merton(100, K, 1, lam=0, sg=mid, M=1)[0] < price else (lo, mid)
    return (lo + hi) / 2
C, D, G, V = merton(100, 100, 1)
DB = (merton(100.01, 100, 1)[0] - merton(99.99, 100, 1)[0]) / 0.02            # bump S by a cent
GB = (merton(100.01, 100, 1)[0] - 2 * C + merton(99.99, 100, 1)[0]) / 0.0001
VB = (merton(100, 100, 1, sg=SIG + 1e-4)[0] - merton(100, 100, 1, sg=SIG - 1e-4)[0]) / 2e-4
show("price, delta, gamma, vega: series", C, D, G, V)
show("gaps: k, e^mu_J, P(0 gaps), P(1 gap)", exp(MU + DL * DL / 2) - 1, exp(MU), exp(-LAM), LAM * exp(-LAM))
show("  by bumping; vega as S^2 sigma T G", DB, GB, VB, 100 ** 2 * SIG * G)
show("Black-Scholes at 20%: same four", *merton(100, 100, 1, lam=0, M=1))
IV = iv(C, 100); show("Black-Scholes at implied vol", IV, *merton(100, 100, 1, lam=0, sg=IV, M=1)[1:])
def gap(J, z):                              # jump residual two ways: prices, curvature integral
    return merton(100 * J, 100, 1)[0] - C - z * D, z * z * simpson(lambda t: (1 - t) * merton(100 + t * z, 100, 1)[2], 0, 1)
GAPS = [gap(J, 100 * (J - 1)) for J in (0.8, 0.9, 1.1, 1.2)]
for J, v in zip((0.8, 0.9, 1.1, 1.2), GAPS): show(f"gap J={J}: by prices, by curvature", *v)
ER = simpson(lambda y: phi(y) * (merton(100 * exp(MU + DL * y), 100, 1)[0] - C
                                 - 100 * (exp(MU + DL * y) - 1) * D), -8, 8, 96)
TH = (merton(100, 100, 1 - 1e-4)[0] - merton(100, 100, 1 + 1e-4)[0]) / 2e-4
DRIFT = -TH - SIG ** 2 * 100 ** 2 * G / 2 - (R - Q) * 100 * D + R * C
show("jump rent: lambda E[R], book drift", LAM * ER, DRIFT)

P, NF, FREQS, k = 1000, 1024, (16, 64, 256, 1024), exp(MU + DL * DL / 2) - 1
drift = {l: (R - Q - l * k - SIG * SIG / 2) / NF for l in (0, LAM)}   # log-drift per step
book, count, ST = {(l, f): [] for l in (0, LAM) for f in FREQS}, [], []
for p in range(P):
    x, n, pr, cum = u(), 0, exp(-LAM), exp(-LAM)   # jump count: invert the Poisson law
    while x > cum: n += 1; pr *= LAM / n; cum += pr
    gaps = [0.0] * NF
    for _ in range(n):                      # each jump: a uniform time, a normal log-size
        i = int(u() * NF); gaps[i] += MU + DL * g()
    count.append(n); z = [g() for _ in range(NF)]
    for lam in (0, LAM):
        path = [100.0]
        for i in range(NF):
            path.append(path[-1] * exp(drift[lam] + SIG * z[i] / sqrt(NF) + (gaps[i] if lam else 0.0)))
        for f in FREQS: book[(lam, f)].append(hedge(path, lam, f))
        if lam: ST.append(path[-1])             # the jump world's price at expiry
def ms(v): m = sum(v) / len(v); return m, sqrt(sum((x - m) ** 2 for x in v) / (len(v) - 1))
print("seller's book at expiry, 1000 paths   BS mean   BS sd     MJ mean   MJ sd")
for f in FREQS: show(f"  rebalanced {f} times a year", *ms(book[(0, f)]), *ms(book[(LAM, f)]), f="{:>10.2f}")
for b, lab in ((0, "0 jumps"), (1, "1 jump"), (2, "2 or more")):
    sel = [x for x, n in zip(book[(LAM, 256)], count) if min(n, 2) == b]
    print(f"  daily MJ book, {lab:<9}: {len(sel):>4} paths, mean {sum(sel) / len(sel):6.2f}")
show("  10th worst daily book: BS, MJ", sorted(book[(0, 256)])[9], sorted(book[(LAM, 256)])[9], f="{:>10.2f}")
PAY = ms([exp(-R) * max(x - 100, 0) for x in ST]); show("MJ price by simulation; std error", PAY[0], PAY[1] / sqrt(P))

KS = (92.15, 100.0, 119.93)
def prices(p): return [merton(100, K, 1, *p)[0] for K in KS]
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def det(A): return A[0][0] if len(A) == 1 else sum((-1) ** j * A[0][j] * det([r[:j] + r[j + 1:] for r in A[1:]]) for j in range(len(A)))
def solve(A, b): return [det([r[:j] + [v] + r[j + 1:] for r, v in zip(A, b)]) / det(A) for j in range(len(b))]  # Cramer
def fit(p, free, target):                   # damped Gauss-Newton, columns by bump-and-revalue
    for _ in range(40):
        f, cols = [a - b for a, b in zip(prices(p), target)], []
        for j in free:
            up, dn = p[:], p[:]; up[j] += 1e-5; dn[j] -= 1e-5
            cols.append([(a - b) / 2e-5 for a, b in zip(prices(up), prices(dn))])
        dx, t = solve([[dot(a, b) for b in cols] for a in cols], [-dot(a, f) for a in cols]), 1.0
        while t > 1e-6:                     # halve the step until the misfit falls
            c = p[:]
            for j, d in zip(free, dx): c[j] += t * d
            m = [a - b for a, b in zip(prices(c), target)]
            if c[0] > 0 and c[2] > 0 and dot(m, m) <= dot(f, f): p = c; break
            t /= 2
    return p
QUOTE = prices((LAM, MU, DL)); show("quotes at 92.15, 100, 119.93", *QUOTE)
FITS = [fit(s, (0, 1, 2), QUOTE) for s in ([1.0, -0.05, 0.10], [0.25, -0.20, 0.25])]
for s, p in zip(("(1.00, -0.05, 0.10)", "(0.25, -0.20, 0.25)"), FITS): show(f"fit from {s}", *p)
CENT = fit([LAM, MU, DL], (0, 1, 2), [QUOTE[0], QUOTE[1] + 0.01, QUOTE[2]]); show("one cent added at the 100 strike", *CENT)
RIDGE = []
for lam in (0.25, 0.375, 0.5, 0.625, 0.75):
    RIDGE.append(fit([lam, MU, DL], (1, 2), QUOTE))
    show(f"rate {lam:.3f}: mean, spread, misses", *RIDGE[-1][1:], *[a - b for a, b in zip(prices(RIDGE[-1]), QUOTE)])
SMK = (60, 70, 80, 92.15, 100, 110, 119.93, 130, 140)
SM = [[100 * iv(merton(100, K, 1, *p)[0], K) for K in SMK] for p in ((LAM, MU, DL), RIDGE[-1])]
print("smile at strikes    " + "".join(f"{K:>7}" for K in SMK))
for lab, row in zip(("  house  0.50 a year", "  other  0.75 a year"), SM): print(lab + "".join(f"{v:>7.2f}" for v in row))

assert abs(DB - D) < 1e-7 and abs(GB - G) < 1e-6 and abs(VB - V) < 1e-5, "series Greeks vs bumps"
assert all(0 < a and abs(a - b) < 1e-6 for a, b in GAPS), "gap residual: prices vs curvature"
assert abs(LAM * ER - DRIFT) < 1e-5, "no-jump drift of the book equals the jump rent"
sd = {key: ms(v)[1] for key, v in book.items()}
assert 0.2 < sd[(0, 256)] / sd[(0, 16)] < 0.3, "Black-Scholes error falls like one over root N"
assert sd[(LAM, 1024)] / sd[(LAM, 256)] > 0.9 and sd[(LAM, 1024)] > 10 * sd[(0, 1024)], "jump error plateaus"
assert abs(ms(book[(LAM, 1024)])[0]) < 3 * sd[(LAM, 1024)] / sqrt(P), "hedged book averages zero"
assert abs(PAY[0] - C) < 3 * PAY[1] / sqrt(P), "series price vs average simulated payoff"
assert all(max(abs(a - b) for a, b in zip(p, (LAM, MU, DL))) < 1e-8 for p in FITS), "fit recovers inputs"
assert all(a[2] > b[2] for a, b in zip(RIDGE, RIDGE[1:])), "spread falls as rate rises along the ridge"
assert max(abs(a - b) for a, b in zip(SM[0][3:7], SM[1][3:7])) < 0.1 < abs(SM[0][0] - SM[1][0]), "wing tells"
print("ALL CHECKS PASS")
