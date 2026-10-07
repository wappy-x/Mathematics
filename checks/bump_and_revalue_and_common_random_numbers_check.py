# Bump and revalue -- the check behind the card.  Standard library only, and
# nothing imported that already holds an answer: the bell-curve area is a series
# written out here, the random numbers come from an arithmetic generator written
# out here, and the tree and the simulation never look at the closed-form delta
# they are scored against.  Four roads reach the same delta, 0.586851.
from math import cos, exp, floor, log, log10, pi, sin, sqrt
EPS = 2.0 ** -52                                  # machine epsilon, 2.220e-16
S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def n_area(x):                                    # bell-curve area to the left of x
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    term = total = x                              # x + x^3/3 + x^5/(3*5) + ...
    for k in range(1, 120):
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + phi(x) * total
def d_one(s): return (log(s / K) + (R - Q + 0.5 * SIG * SIG) * T) / (SIG * sqrt(T))
def call(s):                                      # the pricer that gets bumped
    return (s * exp(-Q * T) * n_area(d_one(s))
            - K * exp(-R * T) * n_area(d_one(s) - SIG * sqrt(T)))
V0, D1 = call(S), d_one(S)
DELTA = exp(-Q * T) * n_area(D1)                  # closed-form delta, the score
GAMMA = exp(-Q * T) * phi(D1) / (S * SIG * sqrt(T))
SPEED = -GAMMA / S * (D1 / (SIG * sqrt(T)) + 1.0)          # third derivative
def central(h): return (call(S + h) - call(S - h)) / (2.0 * h)
def bump2(h): return (call(S + h) - 2.0 * V0 + call(S - h)) / (h * h)
def sci(v):                                       # one text shape in both languages
    e = int(floor(log10(abs(v))))
    return f"{v / 10.0 ** e:.3f}e{e:+03d}"
def line(label, v, extra=""): print(f"{label:<40}{v:>14.6f}   {extra}".rstrip())

print("--- 1. the score to beat: closed forms on the Acme call ---")
line("call price  V(100)", V0, f"d1 = {D1:.4f}")
line("delta   e^-qT N(d1)", DELTA)
line("gamma   e^-qT phi(d1) / (S sigma sqrtT)", GAMMA)
line("speed   dGamma/dS", SPEED, sci(SPEED))
print(f"{'machine epsilon':<40}{sci(EPS):>14}")
print("--- 2. delta by central difference, eleven bump sizes ---")
print(f"{'h':>10} {'h/S':>10}   {'central delta':>16} {'abs error':>11} {'digits right':>13}")
sweep = []
for k in range(0, 11):
    h = 10.0 ** -k
    est = central(h)
    sweep.append((h, est, abs(est - DELTA), -log10(abs(est - DELTA) / DELTA)))
    print(f"{sci(h):>10} {sci(h / S):>10}   {est:>16.12f} "
          f"{sci(sweep[-1][2]):>11} {sweep[-1][3]:>13.2f}")
h_best, est_best, err_best, dig_best = min(sweep, key=lambda t: t[2])
print(f"best bump {sci(h_best)}, error {sci(err_best)}; rule of thumb eps^(1/3) S = "
      f"{sci(EPS ** (1.0 / 3.0) * S)}; predicted {sci((3.0 * EPS * V0 / abs(SPEED)) ** (1.0 / 3.0))}")
line("at h = 1e-15 the bumped prices collide", central(1e-15), "so delta comes out exactly zero")
print("--- 3. one-sided against two-sided, bump h = 1 dollar ---")
up, dn = call(S + 1.0), call(S - 1.0)
fwd, bwd, cen = up - V0, V0 - dn, central(1.0)
print(f"{'V(101), V(100), V(99)':<40}{up:>14.6f}{V0:>12.6f}{dn:>12.6f}")
line("forward   (V(101)-V(100))/h", fwd, "error " + sci(fwd - DELTA))
line("backward  (V(100)-V(99))/h", bwd, "error " + sci(bwd - DELTA))
line("central   (V(101)-V(99))/(2h)", cen, "error " + sci(cen - DELTA))
line("predicted one-sided bias  h Gamma/2", GAMMA / 2.0, "central " + sci(SPEED / 6.0))
bars = [1000.0 * ((call(S + h) - V0) / h - DELTA) for h in (10.0, 4.0, 2.0, 1.0)]
print("one-sided error x 1000, h = 10, 4, 2, 1:" + "".join(f"{b:>8.1f}" for b in bars))
print("--- 4. gamma by bump of bump ---")
print(f"{'h':>10}   {'gamma':>16} {'abs error':>11}")
grows = []
for h in (1.0, 0.1, 0.01, 1e-4, 1e-6):
    grows.append((h, bump2(h), abs(bump2(h) - GAMMA)))
    print(f"{sci(h):>10}   {grows[-1][1]:>16.12f} {sci(grows[-1][2]):>11}")
gh, g_best, gerr = min(grows, key=lambda t: t[2])
print(f"best bump {sci(gh)}, error {sci(gerr)}; rule of thumb eps^(1/4) S = {sci(EPS ** 0.25 * S)}")
def tree(steps):                                  # road three: no bump anywhere
    dt = T / steps
    u = exp(SIG * sqrt(dt)); d = 1.0 / u
    p = (exp((R - Q) * dt) - d) / (u - d); disc = exp(-R * dt)
    v = [max(S * u ** j * d ** (steps - j) - K, 0.0) for j in range(steps + 1)]
    for n in range(steps, 1, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(n)]
    return disc * (p * v[1] + (1.0 - p) * v[0]), (v[1] - v[0]) / (S * u - S * d)
print("--- 5. a road with no bump at all: a 2000-step binomial tree ---")
t_price, t_delta = tree(2000)
line("tree price, 2000 steps", t_price, f"formula {V0:.6f}")
line("tree delta from the two step-1 nodes", t_delta, f"formula {DELTA:.6f}")
NP, MODULUS = 200000, 1 << 32
def draws(seed):                                  # own generator, then Box-Muller
    st, out = seed, []
    for _ in range(NP // 2):
        st = (1664525 * st + 1013904223) % MODULUS; u = (st + 0.5) / MODULUS
        st = (1664525 * st + 1013904223) % MODULUS; v = (st + 0.5) / MODULUS
        rad = sqrt(-2.0 * log(u)); ang = 2.0 * pi * v
        out.append(rad * cos(ang)); out.append(rad * sin(ang))
    return out
DISC, DRIFT, VOL = exp(-R * T), (R - Q - 0.5 * SIG * SIG) * T, SIG * sqrt(T)
def grow(seed): return [exp(DRIFT + VOL * z) for z in draws(seed)]
A, B, C = grow(20260919), grow(777), grow(4242)   # A is shared; B and C are fresh
def pay(x, a): return DISC * max(x * a - K, 0.0)  # one path's discounted payoff
def stats(xs):                                    # mean and standard error, added in order
    t = 0.0
    for x in xs: t += x
    m = t / NP
    t = 0.0
    for x in xs: t += (x - m) * (x - m)
    return m, sqrt(t / (NP - 1) / NP)
def shared(h): return stats([(pay(S + h, a) - pay(S - h, a)) / (2.0 * h) for a in A])
def fresh(h):
    u, su = stats([pay(S + h, b) for b in B])
    d, sd = stats([pay(S - h, c) for c in C])
    return (u - d) / (2.0 * h), sqrt(su * su + sd * sd) / (2.0 * h)
print("--- 6. a road through simulation: 200000 paths, shared and fresh draws ---")
mc_p, mc_se = stats([pay(S, a) for a in A])
line("simulated price", mc_p, f"+/- {mc_se:.6f}, shared-draw se ceiling {1.0 / sqrt(NP):.6f}")
print(f"{'h':>6} {'shared delta':>14} {'shared se':>11} "
      f"{'fresh delta':>13} {'fresh se':>11} {'se ratio':>10}")
mc = []
for h in (5.0, 1.0, 0.1, 0.01):
    (sdd, ss), (fd, fs) = shared(h), fresh(h)
    mc.append((h, sdd, ss, fd, fs))
    print(f"{h:>6.2f} {sdd:>14.6f} {ss:>11.6f} {fd:>13.6f} {fs:>11.6f} {fs / ss:>10.1f}")
pw, pw_se = stats([DISC * a if S * a > K else 0.0 for a in A])
line("pathwise delta, no bump at all", pw, f"+/- {pw_se:.6f}")
print("--- 7. what breaks ---")
line("divide by h, not 2h", up - dn, "twice the true delta")
line("one-sided bump at h = 1", fwd, "bias " + sci(fwd - DELTA))
line("bump half the spot, h = 50", central(50.0), "11 percent low")
line("delta-sized bump for gamma, h = 1e-06", bump2(1e-6), f"gamma is {GAMMA:.6f}")
assert abs(V0 - 9.227005508154) < 1e-9,               "the pricer reproduces the house call price"
assert abs(DELTA - 0.586851146135) < 1e-9,            "closed-form delta, the shelf's number"
assert abs(GAMMA - 0.018950578755) < 1e-9,            "closed-form gamma, the shelf's number"
assert abs((cen - DELTA) - SPEED / 6.0) < 0.02 * abs(SPEED / 6.0), "central bias is h^2 V'''/6"
assert abs((fwd - DELTA) - GAMMA / 2.0) < 0.02 * GAMMA / 2.0, "one-sided bias is half a bump of gamma"
assert abs(cen - DELTA) < abs(fwd - DELTA) / 100.0,   "two-sided beats one-sided a hundredfold"
assert abs(g_best - GAMMA) < 1e-8,                    "bumped gamma at its best bump matches the formula"
assert err_best < abs(central(10.0) - DELTA) / 1e4,   "left arm: a huge bump is far worse"
assert err_best < abs(central(1e-10) - DELTA) / 1e4,  "right arm: a tiny bump is far worse"
assert central(1e-15) == 0.0,                         "at h = 1e-15 the bumped prices are one number"
assert gh > 1e-3,                                     "gamma's best bump is far bigger than delta's"
assert abs(t_price - V0) < 0.01,                      "tree price within a cent of the formula"
assert abs(t_delta - DELTA) < 2e-4,                   "tree delta, read off nodes, matches the formula"
assert abs(mc[3][1] - DELTA) < 3.0 * mc[3][2],        "shared-draw delta within three standard errors"
assert mc[3][4] > 100.0 * mc[3][2],                   "fresh draws are 100x noisier at h = 0.01"
assert abs(pw - DELTA) < 3.0 * pw_se,                 "pathwise delta within three standard errors"
print("ALL CHECKS PASS")
