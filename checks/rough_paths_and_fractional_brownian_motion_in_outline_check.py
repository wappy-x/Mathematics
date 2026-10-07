# Rougher than Brownian: fractional Brownian motion and what breaks in Ito calculus.
# Standard library only; nothing imported holds the answer.  Log-volatility X_t =
# nu * B^H_t, time t in days, nu = 0.3, H = 0.1, volatility 20% * exp(X_t).
# Roads: the formulas; exact sums over the covariance; seeded simulation by
# Davies-Harte (SplitMix64, seed 20260930, Box-Muller, own FFT), with standard errors.
from math import sqrt, log, cos, sin, pi, exp

M64, state, spare = (1 << 64) - 1, 20260930, None

def uniform():                          # SplitMix64 -> a number in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0**53

def normal():                           # Box-Muller, both values of each pair used
    global spare
    if spare is not None:
        z, spare = spare, None
        return z
    r, th = sqrt(-2.0 * log(uniform())), 2.0 * pi * uniform()
    spare = r * sin(th)
    return r * cos(th)

def total(xs):                          # plain left-to-right sum, as in the Rust
    s = 0.0
    for x in xs:
        s += x
    return s

def gam(k, H):                          # covariance of unit-step increments k steps apart
    k = abs(k)
    return 0.5 * ((k + 1) ** (2 * H) - 2 * k ** (2 * H) + abs(k - 1) ** (2 * H))

def fft(a):                             # radix-2 Fourier transform, written out
    n = len(a)
    if n == 1:
        return a[:]
    ev, od = fft(a[0::2]), fft(a[1::2])
    out = [0j] * n
    for k in range(n // 2):
        t = complex(cos(2 * pi * k / n), -sin(2 * pi * k / n)) * od[k]
        out[k], out[k + n // 2] = ev[k] + t, ev[k] - t
    return out

def eigen(n, H):                        # circulant embedding of the covariance
    c = [gam(k, H) for k in range(n + 1)] + [gam(k, H) for k in range(n - 1, 0, -1)]
    return [z.real for z in fft([complex(x, 0.0) for x in c])]

def fgn(n, lam):                        # Davies-Harte: n increments with covariance gam
    m = 2 * n
    w = [0j] * m
    w[0] = complex(sqrt(lam[0] / m) * normal(), 0.0)
    w[n] = complex(sqrt(lam[n] / m) * normal(), 0.0)
    for j in range(1, n):
        s = sqrt(lam[j] / (2 * m))
        a = s * normal()
        w[j] = complex(a, s * normal())
        w[m - j] = w[j].conjugate()
    return [z.real for z in fft(w)[:n]]

def mean_se(xs):
    m = total(xs) / len(xs)
    return m, sqrt(total([(x - m) * (x - m) for x in xs]) / (len(xs) - 1) / len(xs))

H, NU, T, N = 0.1, 0.3, 64.0, 1024     # 64 days on a grid of 1/16 day
h = T / N
print("log-vol X_t = 0.3 B^H_t, t in days, H = 0.1; SplitMix64 seed 20260930")
print("increment correlation rho(n), n = 1 2 4 16:")
for hh in (0.1, 0.5, 0.7):
    print(f"  H = {hh}: " + " ".join(f"{gam(n, hh):+.4f}" for n in (1, 2, 4, 16)))
print(f"H = 1.2 would need rho(1) = {gam(1, 1.2):.4f}, above 1: impossible")
print(f"share of the next step forecast by the last one, rho(1)^2: {gam(1, H) ** 2:.4f}")
print("sd of X over 1, 32, 1024 days, rough: " + " ".join(f"{NU * d ** H:.4f}" for d in (1, 32, 1024))
      + "; Brownian, same daily size: " + " ".join(f"{NU * d ** 0.5:.4f}" for d in (1, 32, 1024)))
print(f"hand: 2^0.2 {2 ** 0.2:.4f}, 64^0.2 {64 ** 0.2:.4f}, 16^0.8 {16 ** 0.8:.4f}; vol from 20% after one sd:"
      f" 1 day up {20 * exp(NU):.2f} down {20 * exp(-NU):.2f}, 1024 days up {20 * exp(2 * NU):.2f}")
dbl = total([gam(i - j, H) for i in range(64) for j in range(64)])
print(f"exact: double sum of rho over 64 steps {dbl:.10f}, formula 64^(2H) {64 ** (2 * H):.10f}")
lam = eigen(N, H)
print(f"exact: smallest circulant eigenvalue {min(lam):.6f} (must be >= 0)")
assert abs(dbl - 64 ** (2 * H)) < 1e-9, "covariance sums do not rebuild the variance law"
assert min(lam) > 0, "embedding not valid"

M = 1000                                # paths
lag1, lag2, xt2, qv, lft, rgt, hest = [], [], [], {1: [], 4: [], 16: []}, [], [], []
for p in range(M):
    g = fgn(N, lam)
    lag1.append(total([g[i] * g[i + 1] for i in range(N - 1)]) / (N - 1))
    lag2.append(total([g[i] * g[i + 2] for i in range(N - 2)]) / (N - 2))
    x = [0.0]
    for v in g:
        x.append(x[-1] + NU * h ** H * v)
    dx = [x[i + 1] - x[i] for i in range(N)]
    xt2.append(x[N] ** 2)
    for f in (1, 4, 16):                # f fine steps per sampling step
        qv[f].append(total([(x[i + f] - x[i]) ** 2 for i in range(0, N, f)]))
    lft.append(total([x[i] * dx[i] for i in range(N)]))
    rgt.append(total([x[i + 1] * dx[i] for i in range(N)]))
    lx, ly = [], []
    for e in range(5):                  # lags 1/16 day up to 1 day
        k = 2 ** e
        lx.append(log(k * h))
        ly.append(log(total([(x[i + k] - x[i]) ** 2 for i in range(N - k)]) / (N - k)))
    mx, my = total(lx) / 5, total(ly) / 5
    hest.append(total([(a - mx) * (b - my) for a, b in zip(lx, ly)])
                / total([(a - mx) ** 2 for a in lx]) / 2)
    if p == 0:
        path_r = [20 * exp(x[32 * i]) for i in range(33)]

print(f"-- simulation, {M} paths, 64 days, grid 1/16 day --")
rows = [("rho(1)", lag1, gam(1, H)), ("rho(2)", lag2, gam(2, H)), ("E X_64^2", xt2, NU * NU * T ** (2 * H))]
for f, lab in ((16, "1 day"), (4, "1/4 day"), (1, "1/16 day")):
    rows.append((f"sum dX^2, step {lab}", qv[f], NU * NU * T * (f * h) ** (2 * H - 1)))
rows += [("left-point sum", lft, 0.5 * NU * NU * (T ** (2 * H) - T * h ** (2 * H - 1))),
         ("right-point sum", rgt, 0.5 * NU * NU * (T ** (2 * H) + T * h ** (2 * H - 1))),
         ("H fitted per path", hest, H)]
for lab, xs, fm in rows:
    m, se = mean_se(xs)
    print(f"{lab:<22} sim {m:9.4f} +- {se:7.4f}   formula {fm:9.4f}")
    assert abs(m - fm) < 4 * se + (0.005 if lab[0] == "H" else 0.0), lab   # the fit's log bias
print("sum dX^2 by step, Brownian with the same daily size: "
      + " ".join(f"{NU * NU * T:.4f}" for _ in range(3)))

# ---- Brownian with the same 64-day spread, for the picture: nu_B = 0.3 * 64^0.1 / 8 ----
nub = NU * T ** H / sqrt(T)
lam_b = eigen(N, 0.5)
gb = fgn(N, lam_b)
xb = [0.0]
for v in gb:
    xb.append(xb[-1] + nub * sqrt(h) * v)
print(f"Brownian nu matched over 64 days: {nub:.4f} per root day; daily sd ratio {NU / nub:.4f}")
print("chart, day          " + " ".join(f"{2 * i}" for i in range(33)))
print("chart, rough vol %  " + " ".join(f"{v:.2f}" for v in path_r))
print("chart, Brownian %   " + " ".join(f"{20 * exp(xb[32 * i]):.2f}" for i in range(33)))
print("chart, sum dX^2 sim " + " ".join(f"{mean_se(qv[f])[0]:.2f}" for f in (16, 4, 1)))
print("chart, formula      " + " ".join(f"{NU * NU * T * (f * h) ** (2 * H - 1):.2f}" for f in (16, 4, 1)))
print("ALL CHECKS PASS")
