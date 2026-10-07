# Structural model sensitivities -- the check behind the card.  Standard library
# only; nothing imported knows the answer.  N(x) is Simpson's rule on the bell
# curve's height.  Three roads: the card's Greek formulas; bumping the closed-form
# prices; and pricing every claim by integrating its payoff over the asset value
# at maturity, with the default point found by bisection (no d1, no d2).
from math import exp, log, sqrt, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def N(x):                                                   # bell-curve area left of x
    if abs(x) > 12.0: return 1.0 if x > 0 else 0.0
    return 0.5 + simpson(phi, 0.0, x)

def claims(V, D, s, r, T):                                  # road 1: closed forms
    vt = s * sqrt(T)
    d1 = (log(V / D) + (r + 0.5 * s * s) * T) / vt
    d2 = d1 - vt
    E = V * N(d1) - D * exp(-r * T) * N(d2)
    B = V - E
    return [E, B, D * exp(-r * T) - B, N(-d2), (-log(B / D) / T - r) * 1e4, d1, d2]

STEP = [1.0, 0.01, 1.0, 1.0, 0.01]                          # $1m, 1 vol point, $1m, 1 year, 1 rate point

def greeks(V, D, s, r, T):                                  # the card's table, per step
    E, B, P, Q, sp, d1, d2 = claims(V, D, s, r, T)
    DF, rt, y = exp(-r * T), sqrt(T), -log(B / D) / T
    eg = [N(d1), V * phi(d1) * rt, -DF * N(d2),
          V * phi(d1) * s / (2 * rt) + r * D * DF * N(d2), T * D * DF * N(d2)]
    bg = [1.0 - eg[0], -eg[1], -eg[2], -eg[3], -eg[4]]
    pg = [eg[0] - 1.0, eg[1], DF + eg[2], eg[3] - r * D * DF, eg[4] - T * D * DF]
    f = phi(d2)
    qg = [-f / (V * s * rt), f * d1 / s, f / (D * s * rt),
          f * (log(V / D) - (r - 0.5 * s * s) * T) / (2 * s * T * rt), -f * rt / s]
    sg = [-bg[0] / (T * B), -bg[1] / (T * B), -(bg[2] / B - 1.0 / D) / T,
          -bg[3] / (T * B) - y / T, -bg[4] / (T * B) - 1.0]
    sg = [g * 1e4 for g in sg]
    return [[g * h for g, h in zip(row, STEP)] for row in (eg, bg, pg, qg, sg)]

def bumped(V, D, s, r, T):                                  # road 2: bump and revalue
    x, out = [V, D, s, r, T], [[0.0] * 5 for _ in range(5)]
    for col, i in enumerate((0, 2, 1, 4, 3)):               # V, sigma, D, T, r
        h = 1e-4 * x[i]
        up, dn = x[:], x[:]
        up[i] += h; dn[i] -= h
        cu, cd = claims(*up), claims(*dn)
        for k in range(5):
            out[k][col] = (cu[k] - cd[k]) / (2 * h) * STEP[col]
    return out

def by_integral(V, D, s, r, T, drift=None):                 # road 3: average the payoffs
    m = (r if drift is None else drift) - 0.5 * s * s
    VT = lambda z: V * exp(m * T + s * sqrt(T) * z)
    lo, hi = -12.0, 12.0                                    # bisection for V_T = D
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if VT(mid) < D: lo = mid
        else: hi = mid
    zs, DF = 0.5 * (lo + hi), exp(-r * T)
    E = DF * simpson(lambda z: (VT(z) - D) * phi(z), zs, 12.0)
    B = DF * (simpson(lambda z: VT(z) * phi(z), -12.0, zs) + D * simpson(phi, zs, 12.0))
    return E, B, simpson(phi, -12.0, zs)

V, D, s, r, T = 100.0, 80.0, 0.20, 0.05, 1.0
E, B, P, Q, sp, d1, d2 = claims(V, D, s, r, T)
Ei, Bi, Qi = by_integral(V, D, s, r, T)
spi = (-log(Bi / D) / T - r) * 1e4
print("base: V 100, D 80, sigma 0.20, r 0.05, T 1; money in $m")
print(f"{'d1, d2':<28}{d1:12.6f}{d2:12.6f}")
print(f"{'N(d1), N(d2)':<28}{N(d1):12.6f}{N(d2):12.6f}")
print(f"{'phi(d1), phi(d2)':<28}{phi(d1):12.6f}{phi(d2):12.6f}")
print(f"{'e^-rT, leverage D e^-rT / V':<28}{exp(-r * T):12.6f}{D * exp(-r * T) / V:12.6f}")
print(f"{'dE/dT parts: vol, rate':<28}{V * phi(d1) * s / 2:12.6f}{r * D * exp(-r * T) * N(d2):12.6f}")
print(f"{'claim':<28}{'formula':>12}{'integral':>12}")
for lab, a, b in (("equity E", E, Ei), ("debt B", B, Bi), ("put P", P, D * exp(-r * T) - Bi),
                  ("default prob Q", Q, Qi), ("spread s (bp)", sp, spi)):
    print(f"{lab:<28}{a:12.6f}{b:12.6f}")
print(f"{'E + B by integral':<28}{Ei + Bi:12.6f}")
print(f"{'real-world Q, drift 0.08':<28}{by_integral(V, D, s, r, T, 0.08)[2]:12.6f}")

G, H = greeks(V, D, s, r, T), bumped(V, D, s, r, T)
print(f"{'per step':<16}{'$1m of V':>12}{'1 vol pt':>12}{'$1m of D':>12}{'1 year':>12}{'1 rate pt':>12}")
for k, lab in enumerate(("equity", "debt", "put", "prob Q", "spread bp")):
    for tag, M in (("form", G), ("bump", H)):
        print(f"{lab + ' ' + tag:<16}" + "".join(f"{v:12.6f}" for v in M[k]))
worst = max(abs(G[k][j] - H[k][j]) / max(1e-9, abs(G[k][j])) for k in range(5) for j in range(5))
print(f"{'formula vs bump, worst gap':<28}{'below 1e-5' if worst < 1e-5 else 'TOO BIG':>12}")

h = 1e-4                                                    # the tug-of-war, on road 3 only
vE = (by_integral(V, D, s + h, r, T)[0] - by_integral(V, D, s - h, r, T)[0]) / (2 * h)
vB = (by_integral(V, D, s + h, r, T)[1] - by_integral(V, D, s - h, r, T)[1]) / (2 * h)
print(f"{'integral vega E, B, |sum|':<28}{vE:12.6f}{vB:12.6f}{abs(vE + vB):12.6f}")
euler = V * G[0][0] + D * G[0][2]
print(f"{'V dE/dV + D dE/dD':<28}{euler:12.6f}")

print(f"{'scenario':<16}{'E':>10}{'B':>10}{'P':>10}{'Q %':>10}{'s bp':>10}")
scen = (("base", 100, 80, .2, .05, 1), ("sigma 0.40", 100, 80, .4, .05, 1), ("V 90", 90, 80, .2, .05, 1),
        ("D 88.89", 100, 800 / 9, .2, .05, 1), ("T 2", 100, 80, .2, .05, 2), ("r 0.06", 100, 80, .2, .06, 1))
gap = 0.0
for lab, *x in scen:
    c = claims(*x)
    gap = max(gap, abs(c[0] - by_integral(*x)[0]))
    print(f"{lab:<16}" + "".join(f"{v:10.2f}" for v in (c[0], c[1], c[2], 100 * c[3], c[4])))
print(f"{'scenarios, integral E gap':<28}{'below 1e-8' if gap < 1e-8 else 'TOO BIG':>12}")

sig = [0.10 + 0.05 * i for i in range(11)]
print("chart sigma " + " ".join(f"{v:7.2f}" for v in sig))
print("chart E     " + " ".join(f"{claims(V, D, v, r, T)[0]:7.2f}" for v in sig))
print("chart B     " + " ".join(f"{claims(V, D, v, r, T)[1]:7.2f}" for v in sig))
print("chart s bp  " + " ".join(f"{claims(V, D, v, r, T)[4]:7.2f}" for v in sig))
mats = [0.25, 0.5, 1, 2, 3, 5, 7, 10]
print("term T      " + " ".join(f"{t:7.2f}" for t in mats))
for lab, a in (("term V 100 ", 100.0), ("term V 90  ", 90.0)):
    print(lab + " " + " ".join(f"{claims(a, D, s, r, t)[4]:7.2f}" for t in mats))

c40 = claims(V, D, 0.40, r, T)
print(f"{'transfer, sigma 0.20 to 0.40':<28}{c40[0] - E:12.6f}{c40[1] - B:12.6f}")
print(f"{'wrong: linear E, sigma 0.40':<28}{E + G[0][1] * 20:12.6f}{c40[0]:12.6f}")
print(f"{'wrong: linear s, sigma 0.40':<28}{sp + G[4][1] * 20:12.6f}{c40[4]:12.6f}")
print(f"{'wrong: put delta as Q':<28}{-G[2][0]:12.6f}{Q:12.6f}")
print(f"{'wrong: longer is wider, V 90':<28}{claims(90, D, s, r, 1)[4]:12.6f}{claims(90, D, s, r, 2)[4]:12.6f}")

assert abs(E - Ei) < 1e-8, "equity: closed form vs payoff integral"
assert abs(B - Bi) < 1e-8, "debt: closed form vs payoff integral"
assert abs(Ei + Bi - V) < 1e-8, "equity plus debt, priced separately, is the firm"
assert worst < 1e-5, "every Greek formula vs bump-and-revalue"
assert abs(vE - G[0][1] * 100) < 1e-5, "equity vega: integral bump vs formula"
assert abs(vB + G[0][1] * 100) < 1e-5, "debt vega: integral bump vs minus the formula"
assert abs(euler - E) < 1e-6, "scaling: V dE/dV + D dE/dD must rebuild E"
assert abs(claims(90, 80, s, r, T)[4] - claims(100, 800 / 9, s, r, T)[4]) < 1e-9, "only leverage matters"
assert gap < 1e-8, "every scenario's equity, closed form vs integral"
assert abs(Q - Qi) < 1e-10, "default probability: N(-d2) vs the integral of the default region"
print("ALL CHECKS PASS")
