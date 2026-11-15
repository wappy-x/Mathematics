# Evolution as an equation -- the check behind the card.  Standard library only.
# Three 100 L stirred tanks in a row, clean water through at c = 10 L/min,
# 5 kg of salt spilled into tank 1: u' = A u with A = k(S - I), k = 0.1 per min.
# Roads: the nilpotent closed form, the power series of tA, RK4 time steps and a
# salt balance.  Then N tanks along the same 300 L: the operator tends to -c d/dx.
import math
C, M0, T = 10.0, 5.0, 15.0                     # L/min, kg spilled, minutes

def closed3(t, k=0.1):                         # e^{-kt}(I + ktS + (kt)^2 S^2/2) u0
    a, e = k * t, math.exp(-k * t)
    return [M0 * e, M0 * e * a, M0 * e * a * a / 2]

def rate(u, k):                                # (A u)_j = k(u_{j-1} - u_j), chain
    return [k * ((u[j - 1] if j else 0.0) - u[j]) for j in range(len(u))]

def series3(t, terms=60, k=0.1):               # sum of (tA)^m u0 / m!
    term, tot = [M0, 0.0, 0.0], [M0, 0.0, 0.0]
    for m in range(1, terms):
        term = [t * v / m for v in rate(term, k)]
        tot = [x + y for x, y in zip(tot, term)]
    return tot

def rk4(u, k, t_end, dt):                      # classical Runge-Kutta steps
    for _ in range(round(t_end / dt)):
        a = rate(u, k)
        b = rate([x + dt / 2 * y for x, y in zip(u, a)], k)
        c = rate([x + dt / 2 * y for x, y in zip(u, b)], k)
        d = rate([x + dt * y for x, y in zip(u, c)], k)
        u = [x + dt / 6 * (p + 2 * q + 2 * r + s) for x, p, q, r, s in zip(u, a, b, c, d)]
    return u

def chain(n, t, length):                       # N tanks of 300/N L, slug in first 100 L
    k, s, lam = n / 30.0, n // 3, n / 30.0 * t
    lf, cdf, run = 0.0, [], 0.0                # Poisson weights e^{-lam} lam^m / m!
    for m in range(length):
        if m: lf += math.log(m)
        run += math.exp(-lam + m * math.log(lam) - lf) if lam > 0 else float(m == 0)
        cdf.append(run)
    cd = lambda i: cdf[i] if i >= 0 else 0.0
    return [M0 / s * (cd(j) - cd(j - s)) for j in range(length)], cdf[-1]

def plug(n, t, length):                        # exact transport: slug at [ct, ct + 100]
    h, a = 300.0 / n, C * t
    return [0.05 * max(0.0, min((j + 1) * h, a + 100) - max(j * h, a)) for j in range(length)]

f3 = lambda v: " ".join(f"{x:.6f}" for x in v)
u, s, r = closed3(T), series3(T), rk4([M0, 0.0, 0.0], 0.1, T, 0.01)
g = lambda x: closed3(x)[2] * 0.1              # salt leaving tank 3, kg/min
w = sum((1 if i in (0, 600) else 4 if i % 2 else 2) * g(i * T / 600) for i in range(601)) * T / 1800
print("three tanks, t = 15 min, closed form (kg):", f3(u))
print(f"kt = {0.1 * T:.1f}, e^(-kt) = {math.exp(-0.1 * T):.6f}, weights 1, kt, (kt)^2/2 =", f3([1, 0.1 * T, (0.1 * T) ** 2 / 2]))
print("power series of tA, 60 terms (kg):        ", f3(s))
print("RK4, step 0.01 min (kg):                  ", f3(r))
print(f"in tanks {sum(u):.6f} kg + flushed (Simpson) {w:.6f} kg = {sum(u) + w:.6f} kg")
assert max(abs(x - y) for x, y in zip(u, s)) < 1e-12 and max(abs(x - y) for x, y in zip(u, r)) < 1e-9
assert abs(sum(u) + w - M0) < 1e-9
for i in range(3):
    print(f"chart tank {i + 1} (kg), t = 0..60 by 5:", " ".join(f"{closed3(5.0 * m)[i]:.2f}" for m in range(13)))
E = [math.exp(T * a) for a in (-0.1, 0.1, 0.0)]  # mistake: e of each entry of tA
print("mistake, entrywise e^(tA) (kg):", f3([M0 * x for x in E]))
print("N, norm of A_N (1/min), log10 e^(15 norm), salt in the 300 L (kg), L1 gap to plug flow (kg), gap*sqrt(N)")
gaps = []
for n in (3, 30, 300, 3000):
    m, mass = chain(n, T, 2 * n + 40)
    gap = sum(abs(x - y) for x, y in zip(m[:n], plug(n, T, n)))
    gaps.append(gap)
    print(f"{n:5d} {n / 15:9.3f} {T * n / 15 / math.log(10):10.3f} {sum(m[:n]):.6f} {gap:.6f} {gap * math.sqrt(n):.4f}")
    assert abs(mass - 1) < 1e-9                   # Poisson weights sum to 1: no salt made
print(f"central-limit prediction of gap*sqrt(N): 30/sqrt(pi) = {30 / math.sqrt(math.pi):.4f}")
assert gaps == sorted(gaps, reverse=True) and abs(gaps[-1] * math.sqrt(3000) / (30 / math.sqrt(math.pi)) - 1) < 0.02
m30 = rk4([M0 / 10] * 10 + [0.0] * 90, 1.0, T, 0.01)
assert max(abs(x - y) for x, y in zip(m30, chain(30, T, 100)[0])) < 1e-8
print("N = 30 by RK4 against the closed form: agree to 1e-8 kg")
xs = [12.5 + 25 * i for i in range(12)]
for n in (3, 300):
    m = chain(n, T, 2 * n + 40)[0]
    print(f"chart N = {n} (g/L):", " ".join(f"{1000 * m[int(x // (300 / n))] / (300 / n):.1f}" for x in xs))
print("chart plug (g/L):", " ".join(f"{50.0 if 150 < x < 250 else 0.0:.1f}" for x in xs))
# a smooth plume f(x) = 0.05/(1 + ((x-150)/50)^2) kg/L; its Taylor series at 150 L
co, ps = [1.0, 0.0], []                        # coefficients of 1/(1+z^2): g_n = -g_{n-2}
for i in range(2, 201):
    co.append(-co[i - 2])
for t in (4.0, 10.0):
    z, tot, ps = -C * t / 50, 0.0, []
    for i in range(201):
        tot += 0.05 * co[i] * z ** i
        if i % 2 == 0: ps.append(tot)
    true = 0.05 / (1 + z * z)                  # the shifted plume, f(150 - ct)
    print(f"plume at 150 L, t = {t:.0f} min: true {true:.6f} kg/L, partial sums", " ".join(f"{p:.6f}" for p in ps[:5]))
    print("   sum to power 200:", f"{ps[-1]:.6f}" if t < 5 else f"size 10^{math.log10(abs(ps[-1])):.1f}")
    assert (abs(ps[-1] - true) < 1e-12) if t < 5 else (abs(ps[-1]) > 1e50)
print(f"series reach: radius 50 L / c = {50 / C:.1f} min; at 10 min it diverges wherever |x - 150| < {math.sqrt(100 ** 2 - 50 ** 2):.1f} L")
def quot_gap(f, h, lo, hi, dx):                # L1 size of q_h - q_{h/2}, q_h = (u0(x-ch)-u0(x))/h
    n = round((hi - lo) / dx)
    return sum(abs((f(x - C * h) - f(x)) / h - (f(x - C * h / 2) - f(x)) / (h / 2))
               for x in (lo + (i + 0.5) * dx for i in range(n))) * dx
slug = lambda x: 0.05 if 0 <= x < 100 else 0.0
plume = lambda x: 0.05 / (1 + ((x - 150) / 50) ** 2)
pred = C * C / 4 * 0.05 / 50 * 3 * math.sqrt(3) / 2   # (c^2/4) times the size of f''
print(f"Taylor prediction for the plume gap: {pred:.6f} h kg/min; for the slug: 2 x 0.05 x c = {0.1 * C:.6f}")
for h in (1.0, 0.1, 0.01):
    a, b = quot_gap(slug, h, -1.0, 111.0, 0.001), quot_gap(plume, h, -19850.0, 20150.0, 0.02)
    print(f"rate test step = {h:.2f} min: slug gap {a:.6f} kg/min, plume gap {b:.6f} kg/min")
    assert abs(a - 0.1 * C) < 1e-6 and abs(b / h / pred - 1) < 0.01 * max(1, 10 * h)
print("ALL CHECKS PASS")
