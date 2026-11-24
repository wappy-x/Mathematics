# Monotone operators and splitting -- the check behind the card.  Standard library only.
# Roads: the Moreau envelope of |x| by its prox, by the Huber formula and by a grid search;
# Douglas-Rachford against the closed-form answer and its KKT multipliers;
# Chambolle-Pock against a duality gap and an enumeration of every jump pattern.
import math, itertools
F = lambda v: "%.6f" % (0.0 if abs(v) < 5e-7 else v)
L = lambda vs: "(" + ", ".join(F(v) for v in vs) + ")"
nm = lambda v: math.sqrt(sum(a * a for a in v))
sub = lambda a, b: [p - q for p, q in zip(a, b)]
print("monotone operators and splitting")
# 1. the prox of |x| is soft thresholding; its Moreau envelope is the Huber function
prox = lambda x: math.copysign(max(abs(x) - 1, 0), x)
env = lambda x: abs(prox(x)) + 0.5 * (x - prox(x)) ** 2
huber = lambda x: x * x / 2 if abs(x) <= 1 else abs(x) - 0.5
grid = [i / 1000 for i in range(-5000, 5001)]
xs = [i / 2 for i in range(-6, 7)]
for x in xs:
    g = min(abs(t) + 0.5 * (x - t) ** 2 for t in grid)
    assert abs(env(x) - huber(x)) < 1e-12 and abs(env(x) - g) < 1e-6
print("chart_abs, " + ", ".join(F(abs(x)) for x in xs))
print("chart_env, " + ", ".join(F(env(x)) for x in xs))
for x in [3.0, 0.4]:
    cd = (env(x + 1e-5) - env(x - 1e-5)) / 2e-5
    clip = max(-1.0, min(1.0, x))
    assert abs(cd - (x - prox(x))) < 1e-6 and abs(prox(x) + clip - x) < 1e-15
    print("x = %s: prox %s, envelope %s, gradient x - prox %s, central difference %s, clip %s"
          % (F(x), F(prox(x)), F(env(x)), F(x - prox(x)), F(cd), F(clip)))
pts = [i / 10 for i in range(-40, 41)]
slack = min((a - b) * (prox(a) - prox(b)) - (prox(a) - prox(b)) ** 2 for a in pts for b in pts)
assert slack >= 0
print("firm nonexpansiveness, worst slack over 6561 pairs:", F(slack))
pp, fw = [3.0], [0.4]
for k in range(3): pp.append(prox(pp[-1])); fw.append(fw[-1] - math.copysign(1, fw[-1]))
assert pp[-1] == 0 and abs(fw[-1] + 0.6) < 1e-12
print("proximal point from 3:", L(pp), "| subgradient step 1 from 0.4:", L(fw))
# 2. Douglas-Rachford: simplex (budget, long only) and a ball round the model weights
def p_simplex(v):
    s, c = sorted(v, reverse=True), 0.0
    for i, a in enumerate(s):
        c += a; t = (c - 1) / (i + 1)
        if i == len(s) - 1 or s[i + 1] <= t: break
    return [max(a - t, 0.0) for a in v]
u, h = [0.5, 0.6, -0.1], [0.6, 0.4, 0.0]
def p_ball(v, r):
    d = sub(v, u); n = nm(d)
    return v[:] if n <= r else [b + r * x / n for b, x in zip(u, d)]
p_f = lambda v: p_simplex([(a + b) / 2 for a, b in zip(v, h)])
def dr(r, steps, zstar=None):
    z, hist = h[:], []
    for k in range(steps):
        x = p_f(z); y = p_ball(sub([2 * a for a in x], z), r); zn = [a + b - c for a, b, c in zip(z, y, x)]
        hist.append((x, y, zn))
        if zstar is not None:  # firm nonexpansiveness: Fejer decrease, residual bound
            assert nm(sub(zn, zstar)) ** 2 <= nm(sub(z, zstar)) ** 2 - nm(sub(zn, z)) ** 2 + 1e-15
            assert nm(sub(zn, z)) <= nm(sub(h, zstar)) / math.sqrt(k + 1) + 1e-15
        if nm(sub(zn, z)) < 1e-12: return k + 1, zn, hist
        z = zn
    return steps, z, hist
for k in range(2):
    print("DR step %d: x %s, y %s, z %s" % ((k,) + tuple(L(v) for v in dr(0.15, 2)[2][k])))
n, zs, hist = dr(0.15, 5000)
dr(0.15, 5000, zs)
w = p_f(zs)
e = math.sqrt(0.06) / 4; exact = [0.45 + e, 0.55 - e, 0.0]
assert nm(sub(w, exact)) < 1e-9
# KKT: h - w = mu (w - u) + nu (1,1,1) - eta e3, with mu, eta >= 0
mu = ((h[0] - w[0]) - (h[1] - w[1])) / ((w[0] - u[0]) - (w[1] - u[1]))
nu = h[0] - w[0] - mu * (w[0] - u[0])
eta = mu * (w[2] - u[2]) + nu - (h[2] - w[2])
assert mu > 0 and eta > 0 and abs(nm(sub(w, u)) - 0.15) < 1e-9 and abs(sum(w) - 1) < 1e-12
print("DR converged in", n, "steps: w", L(w), "closed form", L(exact))
print("KKT multipliers: ball", F(mu), "budget", F(nu), "Japan >= 0", F(eta))
print("distance to model", F(nm(sub(w, u))), "tracking error %", F(20 * nm(sub(w, u))), "trade", F(w[0] - h[0]))
print("Fejer decrease and residual bound held at all", n, "steps")
q2 = lambda v: L([(v[1] - v[0]) / math.sqrt(2), (2 * v[2] - v[0] - v[1]) / math.sqrt(6)])
print("figure, plane coordinates: u", q2(u), "h", q2(h), "w", q2(w))
print("figure, z path:", " ".join(q2(hist[k][2]) for k in (0, 1, 2, 4, 8, 16, 32)))
print("what breaks: read off z: %s, sum %s" % (L(zs), F(sum(zs))))
n10, z10, hist10 = dr(0.10, 400)
drift = nm(sub(hist10[-1][2], hist10[-2][2]))
assert n10 == 400 and drift > 0.02 and nm(sub(hist10[-1][0], u)) > 0.12
print("what breaks: radius 0.10, z still moving %s per step after 400; x %s is %s from the model"
      % (F(drift), L(hist10[-1][0]), F(nm(sub(hist10[-1][0], u)))))
# 3. Chambolle-Pock: total-variation smoothing of eight days of trading spreads (bp)
y, lam, m = [2, 4, 3, 10, 12, 9, 11, 3], 3, 8
Dx = lambda x: [x[i + 1] - x[i] for i in range(m - 1)]
DT = lambda p: [(p[k - 1] if k > 0 else 0) - (p[k] if k < m - 1 else 0) for k in range(m)]
P = lambda x: 0.5 * sum((a - b) ** 2 for a, b in zip(x, y)) + lam * sum(abs(d) for d in Dx(x))
Q = lambda p: 0.5 * sum(a * a for a in y) - 0.5 * sum((a - b) ** 2 for a, b in zip(y, DT(p)))
def cp(tau, sig, steps):
    x, xb, p = [0.0] * m, [0.0] * m, [0.0] * (m - 1)
    for k in range(steps):
        p = [max(-lam, min(lam, a + sig * b)) for a, b in zip(p, Dx(xb))]
        xn = [(a - tau * b + tau * c) / (1 + tau) for a, b, c in zip(x, DT(p), y)]
        xb = [2 * a - b for a, b in zip(xn, x)]
        if max(abs(a - b) for a, b in zip(xn, x)) < 1e-12: return k + 1, xn, p
        x = xn
    return steps, x, p
v = [1.0] + [0.0] * (m - 1)
for _ in range(2000):
    v = DT(Dx(v)); s = nm(v); v = [a / s for a in v]
norm2 = nm(DT(Dx(v)))
assert abs(norm2 - (2 + 2 * math.cos(math.pi / m))) < 1e-9
print("||D||^2 by power iteration", F(norm2), "closed form", F(2 + 2 * math.cos(math.pi / m)), "tau sigma ||D||^2", F(0.45 * 0.45 * norm2))
k, x, p = cp(0.45, 0.45, 100000)
gap = P(x) - Q(p)
assert 0 <= gap < 1e-6 and max(abs(a) for a in p) <= lam
print("CP converged in", k, "steps: x", L(x))
print("primal", F(P(x)), "dual", F(Q(p)), "gap", F(gap), "prices p", L(p))
found = []
for s in itertools.product([-1, 0, 1], repeat=m - 1):
    xs, a = [0.0] * m, 0
    while a < m:
        b = a
        while b < m - 1 and s[b] == 0: b += 1
        val = (sum(y[a:b + 1]) + lam * (s[b] if b < m - 1 else 0) - lam * (s[a - 1] if a > 0 else 0)) / (b - a + 1)
        xs[a:b + 1] = [val] * (b - a + 1); a = b + 1
    ok = all((d > 1e-12) if t == 1 else (d < -1e-12) if t == -1 else abs(d) < 1e-12 for d, t in zip(Dx(xs), s))
    run = 0.0
    for i in range(m - 1):
        run += xs[i] - y[i]
        ok = ok and (abs(run - lam * s[i]) < 1e-9 if s[i] else abs(run) <= lam + 1e-9)
    if ok: found.append(xs)
assert len(found) == 1 and max(abs(a - b) for a, b in zip(found[0], x)) < 1e-9
print("enumeration: 2187 jump patterns, 1 passes:", L(found[0]))
print("hand: |h - u| %s, scale %s, (z1 + h)/2 %s; TV fit %s, total jump %s" % (F(nm(sub(h, u))), F(0.15 / nm(sub(h, u))),
      L([(a + b) / 2 for a, b in zip(dr(0.15, 2)[2][0][2], h)]), F(0.5 * sum((a - b) ** 2 for a, b in zip(x, y))), F(sum(abs(d) for d in Dx(x)))))
a1, b1, a2, b2 = [1.0, 0, 2, 5, 3, 1, 0, 4], [0.5, -1, 2, 0, 1, -2, 0], [2.0, 1, 1, 3, 3, 3, 2, 0], [0.0, 1, -1, 2, -2, 0, 0.5]
op = lambda xx, pq: (sub(xx, sub(y, DT(pq))), [-d for d in Dx(xx)])
(g1, h1), (g2, h2) = op(a1, b1), op(a2, b2)
inner = sum(c * d for c, d in zip(sub(g1, g2), sub(a1, a2))) + sum(c * d for c, d in zip(sub(h1, h2), sub(b1, b2)))
assert abs(inner - nm(sub(a1, a2)) ** 2) < 1e-12
print("saddle operator: <Ma - Mb, a - b> =", F(inner), "= ||x_a - x_b||^2 =", F(nm(sub(a1, a2)) ** 2))
(k1, x1, p1), x9, x8 = cp(1.0, 1.0, 3000), cp(1.0, 1.0, 2999)[1], cp(1.0, 1.0, 2998)[1]
assert P(x1) - P(x) > 1 and P(x9) - P(x1) > 1 and abs(P(x8) - P(x1)) < 1e-9   # stuck in a two-step cycle
print("what breaks: tau = sigma = 1 (tau sigma ||D||^2 = %s): after %d steps %s above the minimum, after %d steps %s"
      % (F(norm2), k1, F(P(x1) - P(x)), k1 - 1, F(P(x9) - P(x))))
k6, x6, p6 = cp(0.6, 0.6, 100000); w20 = p_f(dr(0.20, 5000)[1])
print("try: CP at tau = sigma = 0.6 (tau sigma ||D||^2 = %s): %d steps, gap %s; DR at radius 0.20: w %s" % (F(0.36 * norm2), k6, F(P(x6) - Q(p6)), L(w20)))
print("ALL CHECKS PASS")
