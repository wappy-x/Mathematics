# Static barrier hedges -- the check behind the card.  Standard library only.
# House down-and-out call: S = K = 100, barrier B = 80, r = 5%, q = 2%, vol 20%, one year.
# Roads: (1) the closed form, call minus its mirror image; (2) a Derman-Ergener-Kani
# calendar strip of puts struck at 80, solved backwards so it is worth zero on the wall at
# each match date; (3) the mirror claim priced by Simpson's rule against the lognormal
# density, never using the closed form; (4) that claim built as a fan of plain puts.
from math import log, sqrt, exp, erf, pi

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def bs(S, K, r, q, s, t, cp):                   # cp = +1 call, -1 put; t = years left
    if t <= 0: return max(cp * (S - K), 0.0)
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * t) / (s * sqrt(t)); d2 = d1 - s * sqrt(t)
    return cp * (S * exp(-q * t) * N(cp * d1) - K * exp(-r * t) * N(cp * d2))

S0, K, B, s, T = 100.0, 100.0, 80.0, 0.20, 1.0
r, q = 0.05, 0.02
def expo(r, q): return 2 * (r - q) / (s * s) - 1   # the drift exponent a
def closed(S, r, q, t=T):                       # road 1: call minus mirror image
    return bs(S, K, r, q, s, t, 1) - (B / S) ** expo(r, q) * bs(B * B / S, K, r, q, s, t, 1)

def dek(n, r, q, strike=B):                     # road 2: the calendar strip
    Tj = [T * (j + 1) / n for j in range(n)]    # put j expires at Tj[j] ...
    tau = [T * j / n for j in range(n)]         # ... and is sized at the wall at tau[j]
    w, need = [0.0] * n, [0.0] * n             # need: wall value the put must cancel
    for j in range(n - 1, -1, -1):              # backwards: a triangular solve
        t = tau[j]
        v = bs(B, K, r, q, s, T - t, 1) + sum(w[k] * bs(B, strike, r, q, s, Tj[k] - t, -1)
                                               for k in range(j + 1, n))
        need[j], w[j] = v, -v / bs(B, strike, r, q, s, Tj[j] - t, -1)
    return w, Tj, tau, need
def strip(S, t, w, Tj, r, q, strike=B):        # the strip's value at price S, time t
    return bs(S, K, r, q, s, T - t, 1) + sum(wk * bs(S, strike, r, q, s, Tk - t, -1)
                                             for wk, Tk in zip(w, Tj) if Tk > t)

def g(x, r, q):                                 # the mirror claim's payoff at expiry
    return (B / x) ** expo(r, q) * max(B * B / x - K, 0.0)
def claim(S, t, r, q, m=4000):                  # road 3: Simpson against the density
    tau = T - t; mu = log(S) + (r - q - 0.5 * s * s) * tau; sd = s * sqrt(tau)
    lo, hi = mu - 10 * sd, log(B * B / K); h = (hi - lo) / m; tot = 0.0
    for i in range(m + 1):
        z = lo + i * h
        c = 1 if i in (0, m) else (4 if i % 2 else 2)
        tot += c * g(exp(z), r, q) * exp(-(z - mu) ** 2 / (2 * sd * sd)) / (sd * sqrt(2 * pi))
    return exp(-r * tau) * tot * h / 3

def fan(h, r, q):                               # road 4: puts at 64, 64-h, ..., h
    ks = [B * B / K - i * h for i in range(int(B * B / K / h))]
    sl = [(g(ks[i + 1], r, q) - g(ks[i], r, q)) / (ks[i + 1] - ks[i]) for i in range(len(ks) - 1)]
    return ks, [-sl[0]] + [sl[i - 1] - sl[i] for i in range(1, len(sl))]

z = lambda v: 0.0 if abs(v) < 1e-9 else v     # print rounding noise as a clean zero
out = lambda lab, v: print(f"{lab:<40}" + "".join(f"{z(x):>12.6f}" for x in v))
C0, V0 = bs(S0, K, r, q, s, T, 1), closed(S0, r, q)
out("call C(100), down-and-out closed form", [C0, V0])
out("a, mirror strike B^2/K, ratio K/B", [expo(r, q), B * B / K, K / B])
out("call alone: worth on the wall at t=0", [bs(B, K, r, q, s, T, 1)])
def naive(S, t, r=r, q=q):                      # the r = q hedge: call minus 1.25 puts at 64
    return bs(S, K, r, q, s, T - t, 1) - K / B * bs(S, B * B / K, r, q, s, T - t, -1)
out("1.25 puts at 64: price, wall at t=0", [naive(S0, 0.0), naive(B, 0.0)])
print("DEK strip, 4 dates, solved backwards from the last")
w4, T4, tau4, need4 = dek(4, r, q)
out("put at 80 on the wall, 0.25 .. 1 yr left", [bs(B, B, r, q, s, x, -1) for x in T4])
for j in range(3, -1, -1):
    out(f"match t={tau4[j]:.2f}: call, to cancel, weight", [bs(B, K, r, q, s, T - tau4[j], 1), need4[j], w4[j]])
pv = [bs(S0, B, r, q, s, Tk, -1) for Tk in T4]
out("puts at 80, Acme at 100: 0.25 .. 1 yr", pv)
out("puts' cost, strip price, its error", [-sum(a * b for a, b in zip(w4, pv)), strip(S0, 0.0, w4, T4, r, q),
                                          strip(S0, 0.0, w4, T4, r, q) - V0])
print("dates   strip price   error (cents)")
errs = []
for n in (1, 2, 4, 12, 52, 252):
    wn, Tn, _, _ = dek(n, r, q); p = strip(S0, 0.0, wn, Tn, r, q); errs.append(p - V0)
    print(f"{n:>5}{p:>14.6f}{100 * (p - V0):>14.4f}")
ts = [i / 20 for i in range(20)]
print("chart, t        " + "".join(f"{t:>7.2f}" for t in ts))
print("chart, strip    " + "".join(f"{z(strip(B, t, w4, T4, r, q)):>7.3f}" for t in ts))
print("chart, 1.25 put " + "".join(f"{naive(B, t):>7.3f}" for t in ts))
fine = [i / 400 for i in range(400)]
w52, T52, _, _ = dek(52, r, q)
out("worst wall value: 4 dates, 52 dates", [min(strip(B, t, w4, T4, r, q) for t in fine),
                                            min(strip(B, t, w52, T52, r, q) for t in fine)])
print("mirror claim: payoff (B/x)^a (B^2/x - K)+ below 64")
M0 = claim(S0, 0.0, r, q)
C64 = bs(B * B / S0, K, r, q, s, T, 1)
out("(B/S)^a, C(64), product, Simpson claim", [(B / S0) ** 0.5, C64, (B / S0) ** 0.5 * C64, M0])
out("hedge price C - claim", [C0 - M0])
wall = [(bs(B, K, r, q, s, T - t, 1), claim(B, t, r, q)) for t in (0.0, 0.5, 0.9)]
out("wall at t=0, 0.5, 0.9: call - claim", [c - m for c, m in wall])
print("fan of puts below 64   puts   weight at 64   hedge price")
fans = {}
for h in (16.0, 8.0, 4.0, 2.0, 1.0):
    ks, wf = fan(h, r, q)
    fans[h] = C0 - sum(wk * bs(S0, k, r, q, s, T, -1) for wk, k in zip(wf, ks))
    print(f"spacing {h:>4.0f}{len(wf):>15}{wf[0]:>15.6f}{fans[h]:>14.6f}")
print("r = q = 2%: the symmetry hedge is exact")
ksq, wq = fan(4.0, 0.02, 0.02); wq52, Tq52, _, _ = dek(52, 0.02, 0.02)
out("closed form, 1.25 puts at 64", [closed(S0, 0.02, 0.02), naive(S0, 0.0, 0.02, 0.02)])
out("fan weight at 64, largest other weight", [wq[0], max(abs(x) for x in wq[1:])])
out("DEK strip, 52 dates", [strip(S0, 0.0, wq52, Tq52, 0.02, 0.02)])
print("what breaks")
w100, T100, _, _ = dek(4, r, q, strike=K)
out("4 puts struck at 100 instead of 80", [strip(S0, 0.0, w100, T100, r, q, strike=K)])
w12, T12, _, _ = dek(12, r, q)
out("try: 12 monthly dates, worst wall value", [strip(S0, 0.0, w12, T12, r, q),
                                                min(strip(B, t, w12, T12, r, q) for t in fine)])

assert abs(V0 - 9.133306) < 1e-6, "house down-and-out price"
assert abs(C0 - M0 - V0) < 1e-8, "Simpson mirror claim matches the closed form"
assert all(abs(c - m) < 1e-8 for c, m in wall), "call minus claim is zero on the wall"
assert all(abs(errs[i + 1]) < abs(errs[i]) for i in range(5)), "strip error shrinks with dates"
assert abs(errs[-1]) < 1e-4, "252-date strip within a hundredth of a cent"
assert abs(fans[1.0] - V0) < 2e-4 and abs(fans[16.0] - V0) > abs(fans[1.0] - V0), "fan converges"
assert abs(wq[0] - 1.25) < 1e-9 and max(abs(x) for x in wq[1:]) < 1e-9, "r = q fan is 1.25 puts"
assert abs(naive(S0, 0.0, 0.02, 0.02) - closed(S0, 0.02, 0.02)) < 1e-9, "r = q: 1.25 puts at 64 is exact"
assert all(abs(naive(B, t, 0.02, 0.02)) < 1e-9 for t in (0.0, 0.5, 0.9)), "r = q: zero on the wall"
assert abs(strip(S0, 0.0, wq52, Tq52, 0.02, 0.02) - closed(S0, 0.02, 0.02)) < 1e-3, "r = q strip"
assert abs(naive(B, 0.0)) > 0.1, "symmetry hedge fails on the wall when r != q"
print("ALL CHECKS PASS")
