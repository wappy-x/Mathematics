# Chooser options -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is a series written out, the root finder is
# bisection, the integral is Simpson's rule, the tree is a loop, the random numbers are splitmix64.
from math import log, sqrt, exp, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height
def N(x):                                                      # bell-curve area left of x (Marsaglia)
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    s, t, b, i = x, x, x * x, 3.0
    while s + t != s:
        t *= b / i; s += t; i += 2.0
    return 0.5 + s * phi(x)

def d12(S, K, r, q, sig, T):
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return d1, d1 - sig * sqrt(T)
def call(S, K, r, q, sig, T):
    d1, d2 = d12(S, K, r, q, sig, T); return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def put(S, K, r, q, sig, T):
    d1, d2 = d12(S, K, r, q, sig, T); return K * exp(-r * T) * N(-d2) - S * exp(-q * T) * N(-d1)

def chooser(S, K, r, q, sig, tau, T):                           # road 1: parity at the choice date
    if tau <= 0.0: return max(call(S, K, r, q, sig, T), put(S, K, r, q, sig, T))
    Kp = K * exp(-(r - q) * (T - tau))
    return call(S, K, r, q, sig, T) + exp(-q * (T - tau)) * put(S, Kp, r, q, sig, tau)

def bisect(f, a, b):                                            # a root of f between a and b
    fa = f(a)
    for _ in range(200):
        m = 0.5 * (a + b)
        if (f(m) > 0.0) == (fa > 0.0): a, fa = m, f(m)
        else: b = m
    return 0.5 * (a + b)

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3.0 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

S, K, r, q, sig, T, tau = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 0.5
Kc, Kq = 105.0, 95.0                                            # complex chooser: call at 105, put at 95
St = lambda z: S * exp((r - q - 0.5 * sig * sig) * tau + sig * sqrt(tau) * z)   # price at the choice date

def by_integral(Kcall, Kput):                                   # road 2: average max(C, P) at tau over the bell curve
    gap = lambda z: call(St(z), Kcall, r, q, sig, T - tau) - put(St(z), Kput, r, q, sig, T - tau)
    zs = bisect(gap, -8.0, 8.0)                                 # the kink: where the two legs are worth the same
    f = lambda z: max(call(St(z), Kcall, r, q, sig, T - tau), put(St(z), Kput, r, q, sig, T - tau)) * phi(z)
    return exp(-r * tau) * (simpson(f, -8.0, zs) + simpson(f, zs, 8.0)), St(zs)

def by_tree(steps=2000):                                        # road 3: coin-flip tree, choose at the middle step
    dt = T / steps; u = exp(sig * sqrt(dt)); d = 1.0 / u
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt); m = round(steps * tau / T)
    vc = [max(S * u ** j * d ** (steps - j) - K, 0.0) for j in range(steps + 1)]
    vp = [max(K - S * u ** j * d ** (steps - j), 0.0) for j in range(steps + 1)]
    for n in range(steps, m, -1):
        vc = [disc * (p * vc[j + 1] + (1 - p) * vc[j]) for j in range(n)]
        vp = [disc * (p * vp[j + 1] + (1 - p) * vp[j]) for j in range(n)]
    v = [max(a, b) for a, b in zip(vc, vp)]
    for n in range(m, 0, -1):
        v = [disc * (p * v[j + 1] + (1 - p) * v[j]) for j in range(n)]
    return v[0]

state = 20260924                                                # road 4: simulate through the choice date to expiry
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
paths, acc, n_call = 100000, [0.0, 0.0, 0.0, 0.0], 0
for _ in range(paths):
    rad, ang = sqrt(-2.0 * log(unif())), 2.0 * pi * unif()
    s1 = St(rad * cos(ang))
    sT = s1 * exp((r - q - 0.5 * sig * sig) * (T - tau) + sig * sqrt(T - tau) * rad * sin(ang))
    pick_call = call(s1, K, r, q, sig, T - tau) > put(s1, K, r, q, sig, T - tau)
    n_call += pick_call
    x = exp(-r * T) * (max(sT - K, 0.0) if pick_call else max(K - sT, 0.0))
    pick_c2 = call(s1, Kc, r, q, sig, T - tau) > put(s1, Kq, r, q, sig, T - tau)
    y = exp(-r * T) * (max(sT - Kc, 0.0) if pick_c2 else max(Kq - sT, 0.0))
    acc[0] += x; acc[1] += x * x; acc[2] += y; acc[3] += y * y
mc, mc_se = acc[0] / paths, sqrt((acc[1] / paths - (acc[0] / paths) ** 2) / paths)
mcx, mcx_se = acc[2] / paths, sqrt((acc[3] / paths - (acc[2] / paths) ** 2) / paths)

C, P, V = call(S, K, r, q, sig, T), put(S, K, r, q, sig, T), chooser(S, K, r, q, sig, tau, T)
Kp = K * exp(-(r - q) * (T - tau)); p1, p2 = d12(S, Kp, r, q, sig, tau); c1, _ = d12(S, K, r, q, sig, T)
Pleg, scale = put(S, Kp, r, q, sig, tau), exp(-q * (T - tau))
V_int, S_star = by_integral(K, K); V_tree = by_tree()
X_int, X_star = by_integral(Kc, Kq)
f = lambda **kw: chooser(**{**dict(S=S, K=K, r=r, q=q, sig=sig, tau=tau, T=T), **kw})
delta = (f(S=S + 0.01) - f(S=S - 0.01)) / 0.02; delta_an = exp(-q * T) * (N(c1) - N(-p1))
gamma = (f(S=S + 0.5) - 2 * V + f(S=S - 0.5)) / 0.25
vega = (f(sig=sig + 1e-4) - f(sig=sig - 1e-4)) / 2e-4 / 100
rho = (f(r=r + 1e-4) - f(r=r - 1e-4)) / 2e-4 / 100
theta = f(tau=tau - 1 / 365, T=T - 1 / 365) - V

rows = [("house call C(S,K,T)", C), ("house put P(S,K,T)", P),
        ("put leg strike K' = K e^-(r-q)(T-tau)", Kp), ("put leg d1", p1), ("put leg d2", p2),
        ("put leg N(-d1)", N(-p1)), ("put leg N(-d2)", N(-p2)),
        ("put leg cash half K' e^-r.tau N(-d2)", Kp * exp(-r * tau) * N(-p2)),
        ("put leg share half S e^-q.tau N(-d1)", S * exp(-q * tau) * N(-p1)),
        ("put leg P(S,K',tau)", Pleg), ("scale e^-q(T-tau)", scale), ("put leg scaled", scale * Pleg),
        ("1 chooser, parity formula", V), ("2 chooser, integral over S_tau", V_int),
        ("3 chooser, tree 2000 steps", V_tree), ("4 chooser, simulation 100000 paths", mc),
        ("  simulation standard error", mc_se), ("critical price, root finder", S_star),
        ("chance of choosing the call, simulation", n_call / paths), ("  N(d2) of the put leg", N(p2)),
        ("call plus put, both legs kept", C + P),
        ("greek delta by bump", delta), ("  e^-qT (N(d1 call) - N(-d1 put leg))", delta_an),
        ("greek gamma", gamma), ("greek vega per vol point", vega), ("greek rho per rate point", rho),
        ("greek theta, one day passes", theta),
        ("wrong: put leg struck at K", C + scale * put(S, K, r, q, sig, tau)),
        ("wrong: no e^-q(T-tau) scale", C + Pleg),
        ("wrong: no-dividend textbook strike K e^-r(T-tau)", C + put(S, K * exp(-r * (T - tau)), r, q, sig, tau)),
        ("wrong: choose today, max(C,P)", max(C, P)),
        ("complex: critical price, root finder", X_star), ("complex: chooser by integral", X_int),
        ("complex: chooser by simulation", mcx), ("  simulation standard error", mcx_se),
        ("complex: floor, better of C(105) and P(95)", max(call(S, Kc, r, q, sig, T), put(S, Kq, r, q, sig, T))),
        ("complex: ceiling, C(105) plus P(95)", call(S, Kc, r, q, sig, T) + put(S, Kq, r, q, sig, T)),
        ("try: sigma = 0.40", f(sig=0.40)), ("try: S = 120", f(S=120.0)),
        ("try: S = 120, call alone", call(120.0, K, r, q, sig, T))]
for name, v in rows:
    print(f"{name:<48} {v:>12.6f}")
taus, grid = [i / 10 for i in range(11)], [80.0 + 5.0 * i for i in range(9)]
print("chart, choice date " + " ".join(f"{t:6.1f}" for t in taus))
print("chart, chooser     " + " ".join(f"{f(tau=t):6.2f}" for t in taus))
print("chart, S at tau    " + " ".join(f"{s:6.0f}" for s in grid))
print("chart, call at tau " + " ".join(f"{call(s, K, r, q, sig, T - tau):6.2f}" for s in grid))
print("chart, put at tau  " + " ".join(f"{put(s, K, r, q, sig, T - tau):6.2f}" for s in grid))
print("chart, chooser     " + " ".join(f"{max(call(s, K, r, q, sig, T - tau), put(s, K, r, q, sig, T - tau)):6.2f}" for s in grid))

assert abs(V - 13.344280) < 5e-7, "parity formula vs the shelf's house number"
assert abs(V_int - V) < 1e-7, "integral of max(C, P) at the choice date vs the parity formula"
assert abs(V_tree - V) < 0.01, "tree within a cent"
assert abs(mc - V) < 3 * mc_se, "simulation within 3 standard errors"
assert abs(n_call / paths - N(p2)) < 3 * sqrt(N(p2) * (1 - N(p2)) / paths), "simulated choice rate vs N(d2)"
assert abs(S_star - Kp) < 1e-8, "root-found critical price equals the put leg's strike"
assert abs(X_int - mcx) < 3 * mcx_se, "complex chooser: integral vs simulation"
assert abs(delta - delta_an) < 1e-6, "bumped delta vs the two-leg delta"
print("ALL CHECKS PASS")
