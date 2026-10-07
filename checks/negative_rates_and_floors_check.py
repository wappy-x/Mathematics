# Negative rates and floors -- the check behind the card.  Standard library only.
# A $10m three-year loan pays max(rate, 0) each year on a curve sitting at -0.50%.
# Nothing imported knows the answer: N(x) from math.erf, Simpson's rule, bisection
# and the random numbers are written out below.
from math import log, sqrt, exp, erf, pi, cos

def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))       # bell-curve area left of x
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x

def simpson(f, a, b, n=4000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

def expect(payoff, level, kink):          # E[payoff(level(z))], z a bell-curve draw, split at the kink
    g = lambda z: payoff(level(z)) * phi(z)
    k = min(max(kink, -10.0), 10.0)
    return simpson(g, -10.0, k) + simpson(g, k, 10.0)

def bach(F, K, s, T, cp):                  # normal model, per unit of rate; cp = +1 cap, -1 floor
    w = s * sqrt(T)
    if w == 0.0: return max(cp * (F - K), 0.0)
    d = cp * (F - K) / w
    return cp * (F - K) * N(d) + w * phi(d)

def black(F, K, s, T, cp):                 # Black-76, per unit of rate; needs F > 0 and K > 0
    w = s * sqrt(T)
    d1 = (log(F / K) + 0.5 * w * w) / w    # log of a negative or zero ratio: no price
    return cp * (F * N(cp * d1) - K * N(cp * (d1 - w)))

def shifted(F, K, a, s, T, cp):            # Black on the slid pair F + a, K + a
    if K + a <= 0.0: return max(cp * (F - K), 0.0)   # strike at or below the wall: never reached
    return black(F + a, K + a, s, T, cp)

def match(a, F, sN, T):                    # shifted vol with the normal model's at-the-money price
    target, lo, hi = sN * sqrt(T) / sqrt(2.0 * pi), 1e-9, 50.0
    if target >= F + a: return None        # no lognormal vol pays that much: the shift is too small
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if shifted(F, F, a, mid, T, 1) < target: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

# ---- the loan: $10m, three yearly periods, curve flat at -0.50% a year, zero floor ----
M, tau, Fq, K, sN = 10_000_000.0, 1.0, -0.005, 0.0, 0.005
D = [(1.0 + Fq) ** (-t) for t in range(4)]                      # discount factors D(0)..D(3)
F = [(D[i] / D[i + 1] - 1.0) / tau for i in range(3)]            # forward for period i, read off the curve
T = [0.0, 1.0, 2.0]                                              # when each period's rate is fixed
print("period  fixes  paid    D(paid)      forward")
for i in range(3): print(f"{i + 1:>6} {T[i]:>6.0f} {i + 1:>5} {D[i + 1]:>10.6f} {F[i]:>12.6%}")
for Kb, why in ((K, "divides by a zero strike"), (0.0001, "log of a negative number")):
    try: print(f"black, F = -0.50%, K = {Kb:.2%}: {black(F[1], Kb, 0.30, 1.0, -1):.6f}")
    except (ValueError, ZeroDivisionError): print(f"black, F = -0.50%, K = {Kb:.2%}: no price ({why})")
print(f"{'black, F = +0.01%, K = 1e-8, floorlet $':<44}{0.0 + max(M * D[2] * black(1e-4, 1e-8, 0.30, 1.0, -1), 0.0):>14.2f}")

flo, flo_int, cap0, intr, leg = [], [], [], [], []
for i in range(3):
    w, pay = sN * sqrt(T[i]), M * tau * D[i + 1]
    flo.append(pay * bach(F[i], K, sN, T[i], -1))
    if w > 0:
        lvl = lambda z, i=i, w=w: F[i] + w * z
        flo_int.append(pay * expect(lambda L: max(K - L, 0.0), lvl, (K - F[i]) / w))
        cap0.append(pay * expect(lambda L: max(L - K, 0.0), lvl, (K - F[i]) / w))
    else:
        flo_int.append(pay * max(K - F[i], 0.0)); cap0.append(pay * max(F[i] - K, 0.0))
    intr.append(pay * max(K - F[i], 0.0)); leg.append(pay * F[i])
print("period    floorlet     by integral    intrinsic   0-strike caplet   P(below 0)")
for i in range(3):
    pb = N((K - F[i]) / (sN * sqrt(T[i]))) if T[i] > 0 else 1.0
    print(f"{i + 1:>6} {flo[i]:>11.2f} {flo_int[i]:>14.2f} {intr[i]:>12.2f} {cap0[i]:>12.2f} {pb:>12.2%}")
dd = lambda i: (K - F[i]) / (sN * sqrt(T[i]))                   # by hand: periods 2 and 3
print(f"{'by hand':<26}{'period 2':>12}{'period 3':>12}")
for name, g in (("wiggle w = sN sqrt(T), bp", lambda i: 1e4 * sN * sqrt(T[i])), ("d = (K - F) / w", dd),
                ("N(d)", lambda i: N(dd(i))), ("phi(d)", lambda i: phi(dd(i))),
                ("floorlet bp, undiscounted", lambda i: 1e4 * bach(F[i], K, sN, T[i], -1)),
                ("floorlet bp, times D", lambda i: 1e4 * D[i + 1] * bach(F[i], K, sN, T[i], -1))):
    print(f"{name:<26}" + "".join(f"{g(i):>12.6f}" for i in (1, 2)))
x = 0x2545F4914F6CDD1D
def unif():                                                      # xorshift64, our own uniform on (0, 1)
    global x
    x ^= (x << 13) & 0xFFFFFFFFFFFFFFFF; x ^= x >> 7; x ^= (x << 17) & 0xFFFFFFFFFFFFFFFF
    return ((x >> 11) + 0.5) / 9007199254740992.0
n, tot, tot2 = 200_000, 0.0, 0.0
for _ in range(n):                                               # pay max(fixing, 0) on every path
    z1, z2 = sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif()), sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
    v = sum(M * tau * D[i + 1] * max(F[i] + sN * sqrt(T[i]) * z, 0.0) for i, z in ((0, 0.0), (1, z1), (2, z2)))
    tot += v; tot2 += v * v
mc, se = tot / n, sqrt((tot2 / n - (tot / n) ** 2) / n)
rows = [("one basis point, one year, on the loan", M * tau * 1e-4), ("unfloored leg, sum D tau F M", sum(leg)), ("unfloored leg, M (D(0) - D(3))", M * (D[0] - D[3])),
        ("floor, normal formula", sum(flo)), ("floor, integral", sum(flo_int)), ("floor, intrinsic only", sum(intr)),
        ("floor, time value", sum(flo) - sum(intr)), ("floored leg = leg + floor", sum(leg) + sum(flo)),
        ("floored leg = zero-strike cap", sum(cap0)), ("floored leg, Monte Carlo", mc), ("  Monte Carlo std error", se)]
for name, v in rows: print(f"{name:<44}{v:>14.2f}")

print(f"smallest shift that can match, 1y and 2y: {-F[1] + sN * sqrt(1.0 / (2.0 * pi)):.4%} {-F[2] + sN * sqrt(2.0 / (2.0 * pi)):.4%}")
print("shift  vol 1y match  vol 2y match     floor $   floored leg $   by integral")
for a in (0.0075, 0.01, 0.02, 0.03, 0.10):
    s1, s2 = match(a, F[1], sN, 1.0), match(a, F[2], sN, 2.0)
    if s2 is None: print(f"{a:>5.2%} {s1:>12.2%}          none    no price: the 2y quote cannot be matched"); continue
    fl = [flo[0], M * tau * D[2] * shifted(F[1], K, a, s1, 1.0, -1), M * tau * D[3] * shifted(F[2], K, a, s2, 2.0, -1)]
    G2 = F[2] + a
    chk = M * tau * D[3] * expect(lambda L: max(K + a - L, 0.0), lambda z: G2 * exp(-0.5 * s2 * s2 * 2.0 + s2 * sqrt(2.0) * z),
                                  (log((K + a) / G2) + s2 * s2) / (s2 * sqrt(2.0)))
    print(f"{a:>5.2%} {s1:>12.2%} {s2:>13.2%} {sum(fl):>11.2f} {sum(leg) + sum(fl):>15.2f} {chk + fl[0] + fl[1] + sum(leg):>13.2f}")
    assert abs(chk - fl[2]) < 1e-4, "shifted formula vs integral, year-3 floorlet"
    if a == 0.02: s1_2 = s1
    if a == 0.10: fl10 = sum(fl)

ks = [-0.015, -0.0125, -0.01, -0.0075, -0.005, -0.0025, 0.0, 0.0025, 0.005]
s1a = match(0.01, F[1], sN, 1.0)
print("chart, strike bp       " + " ".join(f"{k * 1e4:>7.0f}" for k in ks))
print("chart, normal          " + " ".join(f"{1e4 * D[2] * bach(F[1], k, sN, 1.0, -1):>7.2f}" for k in ks))
print("chart, shift 2%        " + " ".join(f"{1e4 * D[2] * shifted(F[1], k, 0.02, s1_2, 1.0, -1):>7.2f}" for k in ks))
print("chart, shift 1%        " + " ".join(f"{1e4 * D[2] * shifted(F[1], k, 0.01, s1a, 1.0, -1):>7.2f}" for k in ks))

wrong = [("wrong: skip period 1, it has fixed", sum(flo) - flo[0]),
         ("wrong: discount at 1, not D > 1", sum(flo[i] / D[i + 1] for i in range(3))),
         ("wrong: 2% shift's vol used at 1% shift", flo[0] + sum(M * tau * D[i + 1] * shifted(F[i], K, 0.01, match(0.02, F[i], sN, T[i]), T[i], -1) for i in (1, 2))),
         ("try: normal vol 1.00%", sum(M * tau * D[i + 1] * bach(F[i], K, 0.01, T[i], -1) for i in range(3))),
         ("try: floor at -0.25%, floored leg", sum(leg) + sum(M * tau * D[i + 1] * bach(F[i], -0.0025, sN, T[i], -1) for i in range(3)))]
for name, v in wrong: print(f"{name:<44}{v:>14.2f}")

assert abs(sum(leg) - M * (D[0] - D[3])) < 1e-6, "leg period by period vs the telescoped curve"
assert abs(sum(flo) - sum(flo_int)) < 1e-4, "normal formula vs brute-force integral"
assert abs(sum(leg) + sum(flo) - sum(cap0)) < 1e-4, "leg + floor must equal the zero-strike cap, priced separately"
assert abs(mc - (sum(leg) + sum(flo))) < 4.0 * se, "Monte Carlo within four standard errors"
assert sum(flo) > sum(intr) and abs(fl10 - sum(flo)) < 0.01 * sum(flo), "floor above intrinsic; wide shift near normal"
print("ALL CHECKS PASS")
