# Momentum, Nesterov and Adam racing down f(x) = (x1^2 + 100 x2^2)/2 from (10, 1).
# Minimum: f >= 0 everywhere and f(0, 0) = 0, so x* = (0, 0) and the distance to it is the error.
import math
MU, L, X0, TOL = 1.0, 100.0, (10.0, 1.0), 1e-4
BOWL = ((MU, 0.0), (0.0, L))

def grad(A, x):
    return (A[0][0] * x[0] + A[0][1] * x[1], A[1][0] * x[0] + A[1][1] * x[1])

def momentum(A, a, b, n, nesterov=False, x0=X0):
    # y = x_k + b (x_k - x_{k-1}); heavy ball steps from y with the slope at x_k, Nesterov with the slope at y
    xp = x = x0
    path = [x]
    for _ in range(n):
        y = (x[0] + b * (x[0] - xp[0]), x[1] + b * (x[1] - xp[1]))
        g = grad(A, y if nesterov else x)
        xp, x = x, (y[0] - a * g[0], y[1] - a * g[1])
        path.append(x)
    return path

def adam(A, step, n, b1=0.9, b2=0.999, rng=None, x0=X0):
    x, m, v, p1, p2 = list(x0), [0.0, 0.0], [0.0, 0.0], 1.0, 1.0
    path = [tuple(x)]
    for k in range(1, n + 1):
        g = grad(A, x)
        p1, p2 = p1 * b1, p2 * b2
        for i in (0, 1):
            gi = g[i] + (math.sqrt(3.0) * (2.0 * rng() - 1.0) if rng else 0.0)  # noise of standard deviation 1
            m[i] = b1 * m[i] + (1 - b1) * gi
            v[i] = b2 * v[i] + (1 - b2) * gi * gi
            x[i] -= step(k) * (m[i] / (1 - p1)) / (math.sqrt(v[i] / (1 - p2)) + 1e-8)
        path.append(tuple(x))
    return path

dist = lambda p: math.hypot(p[0], p[1])
steps = lambda path: next((k for k, p in enumerate(path) if dist(p) <= TOL), None)

def splitmix(seed):
    s = [seed]
    def nxt():
        s[0] = (s[0] + 0x9E3779B97F4A7C15) % 2**64
        z = s[0]
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
        return ((z ^ (z >> 31)) >> 11) / 2.0**53
    return nxt

def double_root(e0, e1, rho, k):
    # a two-term recurrence whose two roots coincide at rho: e_k = (e0 + (e1/rho - e0) k) rho^k
    return 0.0 if rho == 0.0 else (e0 + (e1 / rho - e0) * k) * rho ** k

kap, sk = L / MU, math.sqrt(L / MU)
a_gd = 2 / (MU + L)
a_hb, b_hb = 4 / (math.sqrt(L) + math.sqrt(MU)) ** 2, ((sk - 1) / (sk + 1)) ** 2
a_ns, b_ns = 1 / L, (sk - 1) / (sk + 1)
N = 800
gd, hb = momentum(BOWL, a_gd, 0.0, N), momentum(BOWL, a_hb, b_hb, N)
ns, ad = momentum(BOWL, a_ns, b_ns, N, True), adam(BOWL, lambda k: 0.3, N)

def closed(kind, k):
    out = []
    for lam, e0 in zip((MU, L), X0):
        if kind == "gd":
            out.append(e0 * (1 - a_gd * lam) ** k)
            continue
        s = (a_hb if kind == "hb" else a_ns) * lam
        tr = 1 + b_hb - s if kind == "hb" else (1 + b_ns) * (1 - s)
        out.append(double_root(e0, (1 - s) * e0, tr / 2, k))
    return tuple(out)

cl = {kind: steps([closed(kind, k) for k in range(N + 1)]) for kind in ("gd", "hb", "ns")}
print(f"bowl (x1^2 + {L:.0f} x2^2)/2 from (10, 1); kappa {kap:.0f}; stop when distance to (0, 0) <= {TOL}")
print(f"plain     alpha {a_gd:.4f}               rate {(kap - 1) / (kap + 1):.5f}  steps {steps(gd)}, closed form {cl['gd']}")
print(f"heavy     alpha {a_hb:.4f} beta {b_hb:.4f}   rate {math.sqrt(b_hb):.5f}  steps {steps(hb)}, closed form {cl['hb']}")
print(f"nesterov  alpha {a_ns:.4f} beta {b_ns:.4f}   rate {1 - 1 / sk:.5f}  steps {steps(ns)}, closed form {cl['ns']}")
print(f"adam      alpha 0.3 beta1 0.9 beta2 0.999   steps {steps(ad)}; first step to ({ad[1][0]:.4f}, {ad[1][1]:.4f})")
print(f"heavy, step 20: loop ({hb[20][0]:.6f}, {hb[20][1]:.6f}), closed form ({closed('hb', 20)[0]:.6f}, {closed('hb', 20)[1]:.6f})")
cof = lambda e0, s, tr: f"({tr / 2:.4f}, {(1 - s) * e0 / (tr / 2) - e0:.4f})"  # (double root, coefficient of k)
print(f"double roots and k-coefficients: heavy x1 {cof(10, a_hb, 1 + b_hb - a_hb)}, x2 {cof(1, a_hb * L, 1 + b_hb - a_hb * L)}; nesterov x1 {cof(10, a_ns, (1 + b_ns) * (1 - a_ns))}")
print(f"heavy stability: alpha L = {a_hb * L:.4f} < 2(1 + beta) = {2 * (1 + b_hb):.4f}; plain needs alpha L < 2")
KS = (0, 1, 2, 5, 10, 25, 50, 100, 200)
print("race, distance at k " + " ".join(f"{k:>9}" for k in KS))
for name, p in (("plain", gd), ("heavy ball", hb), ("nesterov", ns), ("adam", ad)):
    print(f"  {name:<18}" + " ".join(f"{dist(p[k]):9.2e}" for k in KS))
for name, p in (("plain", gd), ("heavy ball", hb), ("nesterov", ns), ("adam", ad)):
    print(f"chart log10, {name:<10} " + " ".join(f"{math.log10(dist(p[k])):.2f}" for k in range(0, 201, 25)))
for name, p in (("plain", gd), ("heavy ball", hb), ("nesterov", ns), ("adam", ad)):
    print(f"figure, {name:<10} " + " ".join(f"{q[0]:.2f},{q[1]:.2f}" for q in p[:11]))

# Step-size schedules: the same Adam with noisy slopes, root-mean-square distance over 20 seeds
SCHED = (("constant 0.3", lambda k: 0.3), ("constant 0.03", lambda k: 0.03),
         ("halve every 200", lambda k: 0.3 * 0.5 ** ((k - 1) // 200)),
         ("cosine 0.3 to 0", lambda k: 0.15 * (1 + math.cos(math.pi * k / 1000))))
KN, rms = (100, 200, 400, 600, 800, 1000), {}
for name, sch in SCHED:
    sq = [0.0] * len(KN)
    for seed in range(20):
        p = adam(BOWL, sch, 1000, rng=splitmix(seed))
        for j, k in enumerate(KN):
            sq[j] += dist(p[k]) ** 2 / 20
    rms[name] = [math.sqrt(s) for s in sq]
    print(f"noisy adam, {name:<16}" + " ".join(f"{r:7.4f}" for r in rms[name]))

# What breaks, then the Try-changing experiments
STEEP = ((MU, 0.0), (0.0, 150.0))
br = [dist(momentum(STEEP, a, b, 100, nv)[-1]) for a, b, nv in ((a_gd, 0, 0), (a_hb, b_hb, 0), (a_ns, b_ns, 1))]
print(f"breaks: curvature 150, tuned for 100, distance after 100: plain {br[0]:.3e}, heavy {br[1]:.3e}, nesterov {br[2]:.3e}; adam steps {steps(adam(STEEP, lambda k: 0.3, N))}")
print(f"breaks: heavy ball's alpha with beta 0, curvature 100, distance after 50: {dist(momentum(BOWL, a_hb, 0.0, 50)[-1]):.3e}")
def reddi(ams, T=3000, C=3.0):
    # f_k(x) = C x when k leaves remainder 1 on division by 3, else -x; x kept in [-1, 1]
    x, v, vmax, loss = 0.0, 0.0, 0.0, 0.0
    for k in range(1, T + 1):
        g = C if k % 3 == 1 else -1.0
        loss += g * x / T
        v = 0.1 * v + 0.9 * g * g                   # beta1 = 0, beta2 = 1/(1 + C^2) = 0.1
        vmax = max(vmax, v)
        x = max(-1.0, min(1.0, x - 0.5 / math.sqrt(k) * g / math.sqrt(vmax if ams else v)))
    return x, loss
(xa, la), (xm, lm) = reddi(False), reddi(True)
print(f"breaks: Reddi example, 3000 rounds: adam ends at x = {xa:.4f}, average loss {la:.4f}; max-memory variant x = {xm:.4f}, {lm:.4f}; best x = -1, {-(3.0 - 2.0) / 3:.4f}")
ROT = ((50.5, -49.5), (-49.5, 50.5))          # the same bowl turned 45 degrees
r0 = ((X0[0] + X0[1]) / math.sqrt(2.0), (X0[0] - X0[1]) / math.sqrt(2.0))  # the start, turned too
rot = [steps(momentum(ROT, a_gd, 0.0, N, x0=r0)), steps(momentum(ROT, a_hb, b_hb, N, x0=r0)),
       steps(momentum(ROT, a_ns, b_ns, N, True, x0=r0)), steps(adam(ROT, lambda k: 0.3, 3000, x0=r0))]
print(f"try: bowl turned 45 degrees: plain {rot[0]}, heavy {rot[1]}, nesterov {rot[2]}, adam {rot[3]} steps")
tries = [steps(adam(BOWL, lambda k: 0.03, 3000)), steps(adam(((MU, 0.0), (0.0, 1e4)), lambda k: 0.3, N))]
a4, b4 = 4 / (100 + 1) ** 2, (99 / 101) ** 2
hb4 = momentum(((MU, 0.0), (0.0, 1e4)), a4, b4, 3000)
gd4 = next(k for k in range(10 ** 6) if math.hypot(10 * (9999 / 10001) ** k, (9999 / 10001) ** k) <= TOL)
print(f"try: adam alpha 0.03: {tries[0]} steps; curvature 10000: adam {tries[1]}, heavy ball retuned {steps(hb4)}, plain retuned (closed form) {gd4}")

assert (steps(gd), steps(hb), steps(ns)) == (cl["gd"], cl["hb"], cl["ns"]), "loop and closed form disagree"
assert max(abs(hb[20][i] - closed("hb", 20)[i]) for i in (0, 1)) < 1e-9, "heavy ball off its double root"
assert abs(ad[1][0] - 9.7) < 1e-6 and abs(ad[1][1] - 0.7) < 1e-6, "Adam's first step is alpha per variable"
assert steps(hb) < steps(ns) < steps(ad) < steps(gd), "the race order"
assert rot[0:3] == [steps(gd), steps(hb), steps(ns)] and rot[3] > steps(ad), "turning the bowl changes only Adam"
assert xa > 0.99 and xm < -0.99, "Reddi: Adam settles at the worst point, the max-memory variant near the best"
assert rms["halve every 200"][-1] < rms["constant 0.3"][-1] / 3, "a falling schedule beats the constant step"
print("ALL CHECKS PASS")
