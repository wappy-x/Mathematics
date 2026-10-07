# Merton's no-early-exercise theorem -- the check behind the card.  Standard library
# only, and nothing imported that already knows the answer: the bell-curve area is
# thin slices under the curve (Simpson), every average is Simpson written out, the
# trees are loops, the exercise boundary comes from bisection.  Acme: S = K = 100,
# r = 5%, sigma = 20%, one year, no dividend yield; then one cash dividend D at
# six months, escrowed; then the put.
from math import log, sqrt, exp, pi
S, K, R, SIG, T, T1, STEPS = 100.0, 100.0, 0.05, 0.20, 1.0, 0.5, 2000

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def simpson(f, a, b, n):                                   # add up thin slices under f
    h = (b - a) / n
    tot = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return tot * h / 3.0
def ncdf(x):                                               # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 400)
def bs_call(s, k, t):                                      # road 1: the formula, no yield
    if t <= 0.0: return max(s - k, 0.0)
    d1 = (log(s / k) + (R + 0.5 * SIG * SIG) * t) / (SIG * sqrt(t))
    return s * ncdf(d1) - k * exp(-R * t) * ncdf(d1 - SIG * sqrt(t))
def grow(s, t, z): return s * exp((R - 0.5 * SIG * SIG) * t + SIG * sqrt(t) * z)
def by_integral(payoff, s, t):                             # road 2: average the payoff
    return exp(-R * t) * simpson(lambda z: payoff(grow(s, t, z)) * phi(z), -10.0, 10.0, 4000)

def tree(D, sign=1.0, american=True, steps=STEPS, s=S):         # road 3: CRR tree on the escrowed share
    dt = T / steps
    u = exp(SIG * sqrt(dt)); p = (exp(R * dt) - 1.0 / u) / (u - 1.0 / u); disc = exp(-R * dt)
    s0, m = s - D * exp(-R * T1), round(T1 / dt)           # step m is the moment just before ex-date
    v = [max(sign * (s0 * u ** (2 * j - steps) - K), 0.0) for j in range(steps + 1)]
    count, when, lowest = 0, set(), None
    for n in range(steps - 1, -1, -1):
        cash = D * exp(-R * (T1 - n * dt)) if n <= m else 0.0   # dividend still inside the share
        for j in range(n + 1):
            keep = disc * (p * v[j + 1] + (1.0 - p) * v[j])
            share = s0 * u ** (2 * j - n) + cash
            if american and sign * (share - K) > keep + 1e-12:
                keep = sign * (share - K); count += 1; when.add(n)
                if n == m and (lowest is None or share < lowest): lowest = share
            v[j] = keep
    return v[0], count, sorted(when), lowest

def threshold(): return K * (1.0 - exp(-R * (T - T1)))    # interest saved by waiting after ex-date
def boundary(D):                                           # cum-dividend price where exercise = holding
    if D <= threshold(): return None
    lo, hi = K - D, 10.0 * K                               # escrowed price at ex-date, bisection
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if mid + D - K > bs_call(mid, K, T - T1): hi = mid
        else: lo = mid
    return 0.5 * (lo + hi) + D
def exact_american(D, s=S):                                # road 4: decide once, at the ex-date
    s0, b = s - D * exp(-R * T1), boundary(D)
    f = lambda z: max(grow(s0, T1, z) + D - K, bs_call(grow(s0, T1, z), K, T - T1)) * phi(z)
    if b is None: return exp(-R * T1) * simpson(f, -10.0, 10.0, 2000)
    zb = (log((b - D) / s0) - (R - 0.5 * SIG * SIG) * T1) / (SIG * sqrt(T1))
    return exp(-R * T1) * (simpson(f, -10.0, zb, 1000) + simpson(f, zb, 10.0, 1000))
def black(D, s=S):                                         # the better of two Europeans
    s0 = s - D * exp(-R * T1)
    return max(bs_call(s0, K, T), bs_call(s0, K - D, T1)), bs_call(s0, K, T), bs_call(s0, K - D, T1)

def row(label, v): print(f"{label:<40} {v:>12.6f}" if isinstance(v, float) else f"{label:<40} {v:>12}")
print("no dividend, house call")
c_f = bs_call(S, K, T); c_i = by_integral(lambda x: max(x - K, 0.0), S, T)
c_e, _, _, _ = tree(0.0, american=False); c_a, n0, _, _ = tree(0.0)
p_i = by_integral(lambda x: max(K - x, 0.0), S, T)
for lab, v in (("1 formula", c_f), ("2 Simpson average", c_i), ("3 tree, European", c_e),
               ("  tree, American", c_a), ("  nodes where exercise wins", n0), ("  nodes checked", STEPS * (STEPS + 1) // 2),
               ("floor S - K e^-rT", S - K * exp(-R * T)), ("at S=120: live call", bs_call(120.0, K, T)),
               ("  thrown away by exercising", bs_call(120.0, K, T) - 20.0)): row(lab, v)
print("one cash dividend at six months")
row("threshold K(1 - e^-r(T-t1))", threshold())
res = {}
for D in (2.0, 5.0):
    am, cnt, when, low = tree(D); bl, e1, e2 = black(D); ex = exact_american(D); res[D] = (am, cnt, when, low, bl, ex)
    for lab, v in ((f"D={D:.0f}: escrowed spot S*", S - D * exp(-R * T1)), ("  European to expiry", e1),
                   ("  European to ex-date, strike K-D", e2), ("  Black: the larger", bl),
                   ("  tree, American", am), ("  decide-at-ex-date integral", ex), ("  nodes where exercise wins", cnt)): row(lab, v)
    if when: row("  steps holding them", f"{when[0]}..{when[-1]}"); row("  lowest exercised share", low)
    if boundary(D): row("  boundary by bisection", boundary(D))
row("textbook Black leg, S not S*", bs_call(S, K, T1))
print("dividend   European      Black   American    premium")
for D in (0.0, 2.0, 3.0, 5.0, 8.0):
    bl, e1, _ = black(D); am = exact_american(D); print(f"{D:8.2f} {e1:10.4f} {bl:10.4f} {am:10.4f} {round(am - e1, 4) + 0.0:10.4f}")
bl120, e120, _ = black(5.0, 120.0); ex120 = exact_american(5.0, 120.0)
print(f"try S=120, D=5: European {e120:.4f}, Black {bl120:.4f}, American {ex120:.4f}")
print("the put, no dividend")
pa, pn, _, _ = tree(0.0, sign=-1.0); pa80, _, pw80, _ = tree(0.0, sign=-1.0, steps=400, s=80.0)
for lab, v in (("European put, Simpson average", p_i), ("  parity: C - P", c_f - p_i), ("American put, tree", pa), ("  early-exercise premium", pa - p_i),
               ("  nodes where exercise wins", pn), ("floor K e^-rT - S at S=80", K * exp(-R * T) - 80.0)): row(lab, v)
row("American put at S=80, 400 steps", pa80); row("  exercised at step 0", "yes" if 0 in pw80 else "no")
xs = [80.0, 90.0, 100.0, 110.0, 120.0, 130.0]
print("chart S       " + " ".join(f"{x:6.0f}" for x in xs))
print("chart live    " + " ".join(f"{bs_call(x, K, T):6.2f}" for x in xs))
print("chart floor   " + " ".join(f"{max(x - K * exp(-R * T), 0.0):6.2f}" for x in xs))
print("chart exercise" + " ".join(f"{max(x - K, 0.0):6.2f}" for x in xs))
ys = [95.0, 100.0, 105.0, 110.0, 115.0, 120.0, 125.0]
print("chart cum     " + " ".join(f"{y:6.0f}" for y in ys))
print("chart exer D5 " + " ".join(f"{max(y - K, 0.0):6.2f}" for y in ys))
print("chart hold D5 " + " ".join(f"{bs_call(y - 5.0, K, T - T1):6.2f}" for y in ys))

a2, a5 = res[2.0], res[5.0]
assert abs(c_i - c_f) < 1e-6 and abs(c_e - c_f) < 0.005,         "three roads to the no-dividend call"
assert n0 == 0 and abs(c_a - c_e) < 1e-12,                        "no node exercises; American equals European"
assert a2[1] == 0 and abs(a2[0] - a2[5]) < 0.005,                 "a 2.00 dividend is below the threshold"
assert a5[1] > 0 and a5[2] == [STEPS // 2] and abs(a5[0] - a5[5]) < 0.005, "5.00: exercise only just before ex-date"
assert abs(a5[3] - boundary(5.0)) < 0.5,                          "tree's lowest exercise node sits on the boundary"
assert a5[4] <= a5[5] and bl120 <= ex120,                         "Black is a lower bound"
assert pa > p_i + 0.4 and pn > 0 and abs(pa80 - 20.0) < 1e-9,     "the put carries a premium"
print("ALL CHECKS PASS")
