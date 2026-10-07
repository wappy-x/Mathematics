# Martingale representation -- the check behind the card.  Standard library only.
# A $100 digital on a share S_t = 100 + 20 W_t (t in years, no interest) is written as
# $50 plus a continuous trading strategy.  Roads: the closed form from Ito's lemma, the
# coin-toss tree of the discrete theorem, and a seeded simulation of the hedge itself.
from math import sqrt, exp, erf, pi, log, cos, sin

S0, K, SIG, T, PAY = 100.0, 100.0, 20.0, 1.0, 100.0
def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))          # bell-curve area left of x
def Np(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)        # bell-curve height at x
def value(t, s, k=K):                                       # fair value M_t of the digital
    return PAY * N((s - k) / (SIG * sqrt(T - t)))
def stake(t, s, k=K):                                       # shares to hold, H_t = phi_t / SIG
    sd = SIG * sqrt(T - t)
    return PAY * Np((s - k) / sd) / sd

# ---- road 1: the closed form, and Ito's lemma checked by finite differences ----
print(f"{'M_0, fair value at the start':<36}{value(0.0, S0):>12.6f}")
print(f"{'H_0, shares at the start':<36}{stake(0.0, S0):>12.6f}")
print(f"{'phi_0 = SIG * H_0, per unit of W':<36}{SIG * stake(0.0, S0):>12.6f}")
print(f"{'N\'(0), bell height at the centre':<36}{Np(0.0):>12.6f}")
print(f"{'cash at the start, M_0 - H_0 S_0':<36}{value(0.0, S0) - stake(0.0, S0) * S0:>12.6f}")
print(f"{'stake one trading day out, S = 100':<36}{stake(T - 1.0 / 252.0, S0):>12.6f}")
t1, s1, h, e = 0.5, 110.0, 1e-4, 0.01
print(f"{'t=0.5, S=110: x, distance in s.d.':<36}{(s1 - K) / (SIG * sqrt(T - t1)):>12.6f}")
print(f"{'t=0.5, S=110: N\'(x)':<36}{Np((s1 - K) / (SIG * sqrt(T - t1))):>12.6f}")
fd = (value(t1, s1 + e) - value(t1, s1 - e)) / (2 * e)
ut = (value(t1 + h, s1) - value(t1 - h, s1)) / (2 * h)
uss = (value(t1, s1 + e) - 2 * value(t1, s1) + value(t1, s1 - e)) / (e * e)
print(f"{'t=0.5, S=110: stake by formula':<36}{stake(t1, s1):>12.6f}")
print(f"{'t=0.5, S=110: slope of M by bumping':<36}{fd:>12.6f}")
print(f"{'t=0.5, S=110: dM/dt':<36}{ut:>12.4f}")
print(f"{'t=0.5, S=110: (1/2) SIG^2 d2M/dS2':<36}{0.5 * SIG * SIG * uss:>12.4f}")

# ---- road 2: the discrete theorem on a fair +-step tree, exact over every path ----
def above(n, start, k, dlt):          # chance an n-step fair walk of +-dlt from start ends above k
    lp, tot = -n * log(2.0), 0.0
    for j in range(n + 1):
        if start + dlt * (2 * j - n) > k: tot += exp(lp)
        if j < n: lp += log((n - j) / (j + 1))
    return tot
def tree(n, k):                       # value and stake (M+ - M-) / (S+ - S-) at the root
    dlt = SIG * sqrt(T / n)
    up, dn = PAY * above(n - 1, S0 + dlt, k, dlt), PAY * above(n - 1, S0 - dlt, k, dlt)
    return (up + dn) / 2.0, (up - dn) / (2.0 * dlt)
print("tree steps         M_0         H_0   H_0 error  error * n")
for n in (9, 99, 999, 9999, 99999):
    m0, h0 = tree(n, K)
    print(f"{n:>10}{m0:>12.6f}{h0:>12.6f}{h0 - stake(0.0, S0):>12.6f}{(h0 - stake(0.0, S0)) * n:>11.4f}")

# ---- road 3: simulate the share, run the strategy, compare with the payoff ----
MASK, state = (1 << 64) - 1, [20260930]
def u01():                                                  # SplitMix64, top 53 bits
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & MASK
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def normals(count):                                         # Box-Muller, two at a time
    out = []
    while len(out) < count:
        r, a = sqrt(-2.0 * log(1.0 - u01())), 2.0 * pi * u01()
        out += [r * cos(a), r * sin(a)]
    return out
FINE, PATHS, MS, CHART = 1280, 4000, (5, 20, 80, 320, 1280), 7
dt = T / FINE
pay, iso, err, un = [0.0, 0.0], [0.0, 0.0], {m: [0.0, 0.0] for m in MS}, [0.0, 0.0]
dbl, chart = {80: [0, 0.0], 1280: [0, 0.0]}, [[], [], []]
for p in range(PATHS):
    zw, zb = normals(FINE), normals(FINE)
    S, B = [S0], [0.0]
    for i in range(FINE):
        S.append(S[-1] + SIG * sqrt(dt) * zw[i]); B.append(B[-1] + sqrt(dt) * zb[i])
    V = PAY if S[-1] > K else 0.0
    pay[0] += V; pay[1] += V * V
    for m in MS:
        st, acc, q = FINE // m, PAY / 2.0, 0.0
        for k in range(m):
            if p == CHART and m == FINE and k % 64 == 0:
                chart[0].append(S[k]); chart[1].append(value(k * dt, S[k])); chart[2].append(acc)
            hk = stake(k * T / m, S[k * st])
            acc += hk * (S[(k + 1) * st] - S[k * st]); q += (SIG * hk) ** 2 * (T / m)
        err[m][0] += acc - V; err[m][1] += (acc - V) ** 2
    iso[0] += q; iso[1] += q * q
    if p == CHART:
        chart[0].append(S[-1]); chart[1].append(V); chart[2].append(acc)
    V2, acc2 = (PAY if (S[-1] - S0) / SIG + B[-1] > 0 else 0.0), PAY / 2.0
    for k in range(FINE):                 # a second, unseen noise B moves the payoff
        sd2 = sqrt(2.0 * (T - k * dt))
        acc2 += PAY * Np(((S[k] - S0) / SIG + B[k]) / sd2) / (sd2 * SIG) * (S[k + 1] - S[k])
    un[0] += (acc2 - V2) ** 2; un[1] += (acc2 - V2) ** 4
    for m in dbl:                         # doubling: start at $0, hold 2.5/(T-t) shares until $50
        st, g = FINE // m, 0.0
        for k in range(m):
            if g < PAY / 2.0: g += 2.5 / (T - k * T / m) * (S[(k + 1) * st] - S[k * st])
        if g >= PAY / 2.0: dbl[m][0] += 1
        else: dbl[m][1] += g
def mse(s, n): return s[0] / n, sqrt(max(s[1] / n - (s[0] / n) ** 2, 0.0) / n)
pm, pse = mse(pay, PATHS)
print(f"{'simulated mean payoff, 4000 paths':<36}{pm:>12.4f} +- {pse:.4f}")
print("rebalances   mean error  +- s.e.    RMS error")
rms = {}
for m in MS:
    em, ese = mse(err[m], PATHS); rms[m] = sqrt(err[m][1] / PATHS)
    print(f"{m:>10}{em:>13.4f}{ese:>9.4f}{rms[m]:>12.2f}")
print(f"{'RMS ratio per 4x rebalances':<36}" + " ".join(f"{rms[MS[i + 1]] / rms[MS[i]]:.3f}" for i in range(4)))
grid = sum(PAY * PAY / (2 * pi * sqrt(T * T - (k * dt) ** 2)) * dt for k in range(FINE))
im, ise = mse(iso, PATHS)
print(f"{'sum of phi^2 dt, simulated':<36}{im:>12.4f} +- {ise:.4f}")
print(f"{'sum of phi^2 dt, exact on the grid':<36}{grid:>12.4f}")
print(f"{'limit 100^2/(2 pi) * pi/2 = Var(V)':<36}{PAY * PAY / 4:>12.4f}")
print(f"{'simulated Var(V)':<36}{pay[1] / PATHS - pm * pm:>12.4f}")
print(f"{'unseen noise: RMS error, 1280 trades':<36}{sqrt(un[0] / PATHS):>12.4f}")
print(f"{'unseen noise: sqrt(2500 / 2)':<36}{sqrt(PAY * PAY / 8):>12.4f}")
for m, (hit, miss) in dbl.items():
    print(f"{'doubling, ' + str(m) + ' trades: share at $50':<36}{hit / PATHS:>12.4f}")
    print(f"{'doubling, ' + str(m) + ' trades: mean of misses':<36}{miss / (PATHS - hit):>12.2f}")
print("chart, t        " + " ".join(f"{k * 0.05:.2f}" for k in range(21)))
for lab, row in zip(("chart, share", "chart, M_t", "chart, account"), chart):
    print(f"{lab:<16}" + " ".join(f"{v:.2f}" for v in row))

assert abs(tree(99999, K)[1] - stake(0.0, S0)) < 1e-3, "tree stake vs Ito formula"
assert abs(fd - stake(t1, s1)) < 1e-5, "stake = slope of the fair value"
assert abs(ut + 0.5 * SIG * SIG * uss) < 1e-3, "drift term of Ito's lemma cancels"
assert abs(pm - 50.0) < 4 * pse, "simulated payoff mean vs $50"
assert abs(mse(err[1280], PATHS)[0]) < 4 * mse(err[1280], PATHS)[1], "hedge is fair"
assert max(rms[m] * m ** 0.25 for m in MS) < 1.2 * min(rms[m] * m ** 0.25 for m in MS), "miss falls like n^(-1/4)"
assert abs(im - grid) < 4 * ise, "isometry on the grid"
assert abs(mse(un, PATHS)[0] - PAY * PAY / 8) < 4 * mse(un, PATHS)[1], "unseen noise leaves half the variance"
assert dbl[1280][0] > dbl[80][0] > 0.8 * PATHS, "doubling reaches $50 on more paths as trading refines"
print("ALL CHECKS PASS")
