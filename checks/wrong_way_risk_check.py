# Wrong-way risk -- the check behind the card.  Standard library only.
# A put on Northwind's own shares, bought from Northwind.  Default is tied to the
# share through a Gaussian copula; CVA is recomputed at each correlation.
# Nothing imported knows the answer: normal CDF by series, quantile by bisection,
# integrals by Simpson's rule, random numbers by splitmix64 and Box-Muller.
from math import exp, log, sqrt, pi, cos

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def N(x):                                                         # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total
def inv_N(p):                                                     # the z with N(z) = p, by bisection
    lo, hi = -9.0, 9.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if N(mid) < p: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3.0

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0         # the house market, on Northwind's shares
lam, R = 0.02, 0.40                                               # Northwind's hazard rate and recovery
L, p = 1.0 - R, 1.0 - exp(-lam * T)                               # loss share, one-year default chance
a = inv_N(p)                                                      # the default cutoff on the credit score
v = sig * sqrt(T)
d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / v
d2 = d1 - v
D = exp(-r * T)
put = K * D * N(-d2) - S * exp(-q * T) * N(-d1)
call = S * exp(-q * T) * N(d1) - K * D * N(d2)
def s_T(y): return S * exp((r - q - 0.5 * sig * sig) * T + v * y)  # year-end share price, share score y
def p_rho(y, rho):                                                # default chance once the share score is y
    if rho >= 1.0: return 1.0 if y <= a else 0.0
    return N((a - rho * y) / sqrt(1.0 - rho * rho))

# road 1: integrate payoff x bell-curve height x conditional default chance
def cva_int(rho, kind):
    if kind == "put":
        lo, hi, pay = -9.0, -d2, lambda y: K - s_T(y)
    else:
        lo, hi, pay = -d2, 9.0, lambda y: s_T(y) - K
    if rho >= 1.0: hi = min(hi, a)                                # default only below the cutoff
    if hi <= lo: return 0.0
    return L * D * simpson(lambda y: pay(y) * phi(y) * p_rho(y, rho), lo, hi, 4000)

# road 2: closed form with the two-score bell-curve area N2, built from Plackett's identity
def N2(h, k, rho):                                                # chance first score < h and second < k
    def dens(t):
        if 1.0 - t * t < 1e-14: return 0.0
        return exp(-(h * h - 2 * t * h * k + k * k) / (2 * (1 - t * t))) / (2 * pi * sqrt(1 - t * t))
    return N(h) * N(k) + (simpson(dens, 0.0, rho, 2000) if rho != 0.0 else 0.0)
def cva_closed(rho, kind):
    if kind == "put":
        return L * (K * D * N2(-d2, a, rho) - S * exp(-q * T) * N2(-d1, a - rho * v, rho))
    return L * (S * exp(-q * T) * N2(d1, a - rho * v, -rho) - K * D * N2(d2, a, -rho))

# road 3: simulate share and credit scores together
M64 = (1 << 64) - 1
seed = [2026]
def rand():                                                       # splitmix64 -> uniform strictly inside (0, 1)
    seed[0] = (seed[0] + 0x9E3779B97F4A7C15) & M64
    z = seed[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def mc(rho, n=1000000):
    sp = sc = sp2 = sc2 = 0.0
    for _ in range(n):
        u1, u2, u3 = rand(), rand(), rand()
        y = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
        e = sqrt(-2.0 * log(u3)) * cos(2.0 * pi * rand())
        if rho * y + sqrt(1.0 - rho * rho) * e <= a:              # Northwind defaults this year
            st = s_T(y)
            xp, xc = L * D * max(K - st, 0.0), L * D * max(st - K, 0.0)
            sp += xp; sp2 += xp * xp; sc += xc; sc2 += xc * xc
    mp, mcl = sp / n, sc / n
    return mp, sqrt((sp2 / n - mp * mp) / n), mcl, sqrt((sc2 / n - mcl * mcl) / n)

indep_put, indep_call = L * p * put, L * p * call
print(f"{'clean put, Black-Scholes':<34}{put:>12.6f}")
print(f"{'clean call, Black-Scholes':<34}{call:>12.6f}")
print(f"{'one-year default chance p':<34}{p:>12.6f}")
print(f"{'default cutoff a':<34}{a:>12.6f}")
print(f"{'d1, d2':<22}{d1:>12.6f}{d2:>12.6f}")
print(f"{'independent put CVA  L p P':<34}{indep_put:>12.6f}")
print(f"{'independent call CVA L p C':<34}{indep_call:>12.6f}")
print()
print("rho    put:integral    closed   x indep   call:integral   closed   x indep")
rhos = (-0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 0.9, 1.0)
res = {}
for rho in rhos:
    res[rho] = (cva_int(rho, "put"), cva_closed(rho, "put"), cva_int(rho, "call"), cva_closed(rho, "call"))
    pi_, pc_, ci_, cc_ = res[rho]
    print(f"{rho:>5.2f} {pi_:>13.6f} {pc_:>9.6f} {pi_ / indep_put:>8.2f} {ci_:>14.6f} {cc_:>9.6f} {ci_ / indep_call:>8.2f}")
put5, call5 = res[0.5][0], res[0.5][2]
mp, sep, mcl, sec = mc(0.5)
print()
print(f"{'MC rho 0.5 put, 1000000 paths':<34}{mp:>12.4f}  +/- {sep:.4f}")
print(f"{'MC rho 0.5 call, 1000000 paths':<34}{mcl:>12.4f}  +/- {sec:.4f}")
parity = L * (K * D * N(a) - S * exp(-q * T) * N(a - 0.5 * v))
print(f"{'K e^-rT, S e^-qT':<22}{K * D:>12.6f}{S * exp(-q * T):>12.6f}")
print(f"{'N2(-d2, a; .5), N2(-d1, a-.5v; .5)':<34}{N2(-d2, a, 0.5):>12.6f}{N2(-d1, a - 0.5 * v, 0.5):>12.6f}")
print(f"{'rho 0.5 put CVA - call CVA':<34}{put5 - call5:>12.6f}")
print(f"{'  L(K D N(a) - S e^-qT N(a-rho v))':<34}{parity:>12.6f}")
for x in (0.0, 0.5, 1.0):
    print(f"{'put exposure given default, rho':<30}{x:>4.1f}{res[x][0] / (L * p):>12.6f}")
print(f"{'rho 0.5 risky put  P - CVA':<34}{put - put5:>12.6f}")
print(f"{'independent risky put':<34}{put - indep_put:>12.6f}")
print(f"{'ceiling: put pays K at default':<34}{L * K * D * p:>12.6f}")
print(f"{'house check: L p x Acme call':<34}{indep_call:>12.6f}")
print()
print("wrong answers")
print(f"{'wrong: independent formula at 0.5':<34}{indep_put:>12.6f}")
print(f"{'wrong: 50% as a variance share':<34}{cva_int(sqrt(0.5), 'put'):>12.6f}")
print(f"{'wrong: sign of rho flipped':<34}{res[-0.5][0]:>12.6f}")
print(f"{'wrong: the ceiling read as a price':<34}{L * K * D * p:>12.6f}")
print()
print(f"chart: default chance % at rho 0.5 by year-end price; {100 * p:.2f} at rho 0")
for st in (60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0, 140.0):
    y = (log(st / S) - (r - q - 0.5 * sig * sig) * T) / v
    print(f"  price {st:>5.0f}   default chance {100 * p_rho(y, 0.5):>6.2f}   put pays {max(K - st, 0.0):>5.2f}")

assert all(abs(res[x][0] - res[x][1]) < 1e-7 for x in rhos), "put: integral road vs closed-form road"
assert all(abs(res[x][2] - res[x][3]) < 1e-7 for x in rhos), "call: integral road vs closed-form road"
assert abs(res[0.0][0] - L * p * put) < 1e-8, "independence: integral must collapse to L p P"
assert abs(mp - put5) < 4 * sep and abs(mcl - call5) < 4 * sec, "simulation within 4 standard errors"
assert all(abs(res[x][0] - res[x][2] - L * (K * D * N(a) - S * exp(-q * T) * N(a - x * v))) < 1e-7 for x in rhos), "CVA parity"
assert all(res[x][0] < res[y][0] and res[x][2] > res[y][2] for x, y in zip(rhos, rhos[1:])), "put up, call down"
assert res[1.0][0] < L * K * D * p, "no model beats the ceiling"
assert abs(put - 6.330080627550) < 1e-9 and abs(indep_call - 0.1096) < 5e-5 and abs(call - indep_call - 9.117) < 5e-4, "house put, CVA 0.1096, risky call 9.117"
print("ALL CHECKS PASS")
