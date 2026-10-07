# The heat kernel -- the check behind the card.  Standard library only.  Dye in
# a long tube, kappa = 0.01 cm^2/s.  Roads: the kernel formula; a halving walk
# stepped cell by cell; a grid stepped from a step start; Simpson integrals.
from math import exp, sqrt, pi, log
K = 0.01
def G(x, t, k=K): return exp(-x * x / (4 * k * t)) / sqrt(4 * pi * k * t)
def simpson(f, a, b, n=4000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def erf(z):                                     # Maclaurin series, fine for z <= 2
    s, term, n = 0.0, z, 0
    while abs(term) > 1e-17:
        s += term / (2 * n + 1); n += 1; term *= -z * z / n
    return 2 / sqrt(pi) * s
def step(u, r, n):                              # n explicit steps, u_i += r (u_(i-1) - 2 u_i + u_(i+1))
    for _ in range(n):
        u = [u[0]] + [u[i] + r * (u[i - 1] - 2 * u[i] + u[i + 1]) for i in range(1, len(u) - 1)] + [u[-1]]
    return u
h = 1e-3                                        # 1. the kernel obeys u_t = kappa u_xx at x = 1 cm, t = 100 s
gt = (G(1, 100 + h) - G(1, 100 - h)) / (2 * h)
gxx = K * (G(1 + h, 100) - 2 * G(1, 100) + G(1 - h, 100)) / h ** 2
print(f"at x = 1 cm, t = 100 s, in 1e-4 per s: u_t = {gt * 1e4:.6f}, kappa u_xx = {gxx * 1e4:.6f}")
print("dye under the bell, t = 100 and 400 s:", " ".join(f"{simpson(lambda x: G(x, t), -30, 30):.6f}" for t in (100, 400)))
dx = 0.1                                        # 2. halving walk: r = 1/2, one tick = dx^2/(2 kappa) = 0.5 s
walk, xs = [0.0] * 200 + [1.0] + [0.0] * 200, [(i - 200) * dx for i in range(401)]
wid = {}
for t in (100, 400):
    w = step(walk, 0.5, int(t / 0.5))
    wid[t] = sqrt(sum(m * x * x for m, x in zip(w, xs)))
    if t == 100: dens = w[210] / (2 * dx)
print("width sqrt(2 kappa t), t = 100 and 400 s:", " ".join(f"{sqrt(2 * K * t):.4f}" for t in (100, 400)), "cm")
print("width of the halving walk, same times:   ", " ".join(f"{wid[t]:.4f}" for t in (100, 400)), "cm")
print(f"dye per cm at x = 1 cm, t = 100 s: bell {G(1, 100):.4f}, walk {dens:.4f}; peaks at 100 and 400 s: {G(0, 100):.4f} {G(0, 400):.4f}")
for t in (100, 400):
    print(f"figure, bell t = {t} s, x = -6..6 cm:", ", ".join(f"{G(x, t):.3f}" for x in range(-6, 7)))
xq = (0, 1, 2)                                  # 3. step start: full strength 1 left of 0, clear water right
by_erf = [0.5 * (1 - erf(x / (2 * sqrt(K * 100)))) for x in xq]
by_conv = [simpson(lambda s: G(s, 100), x, x + 20) for x in xq]
print("step start, t = 100 s, x = 0, 1, 2 cm: by erf  ", " ".join(f"{v:.6f}" for v in by_erf))
print("                           by kernel integral   ", " ".join(f"{v:.6f}" for v in by_conv))
errs = []
for d in (0.2, 0.1):                            # grid of cells d cm wide, r = 1/4, so a time step of 25 d^2 s
    n = round(10 / d)
    u = step([1.0] * n + [0.5] + [0.0] * n, 0.25, round(100 / (25 * d * d)))
    errs.append(abs(u[n + round(1 / d)] - by_erf[1]))
print(f"grid error at x = 1 cm, cells 0.2 and 0.1 cm, in 1e-4: {errs[0] * 1e4:.2f} {errs[1] * 1e4:.2f}, ratio {errs[0] / errs[1]:.2f}")
print(f"step start at x = 10 cm, t = 100 s (by integral): {simpson(lambda s: G(s, 100), 10, 30):.3e}")
S, Kx, r, q, sg, T = 100, 100, 0.05, 0.02, 0.2, 1.0   # 4. wing 12: kernel in log price, kappa = sigma^2 / 2
m = log(S) + (r - q - sg * sg / 2) * T
call = exp(-r * T) * simpson(lambda y: (exp(y) - Kx) * G(y - m, T, sg * sg / 2), log(Kx), m + 12 * sg)
print(f"Black-Scholes call from the kernel: {call:.9f}")
print(f"mistake 1, width sqrt(kappa t) at 100 s: {sqrt(K * 100):.4f} cm")
print(f"mistake 2, width taken to grow with t: {2 * sqrt(2 * K * 100):.4f} cm at 200 s; true {sqrt(2 * K * 200):.4f} cm")
print(f"mistake 3, bell without 1/sqrt(4 pi kappa t): dye total {simpson(lambda x: exp(-x * x / 4), -30, 30):.4f} at 100 s")
assert abs(gt - gxx) < 1e-6 * abs(gt) and abs(gt - G(1, 100) * (1 / 400 - 1 / 200)) < 1e-9
assert all(abs(wid[t] - sqrt(2 * K * t)) < 1e-9 for t in wid) and abs(dens - G(1, 100)) < 0.01 * G(1, 100)
assert all(abs(a - b) < 1e-9 for a, b in zip(by_erf, by_conv)) and errs[1] < 1e-3 and 3.5 < errs[0] / errs[1] < 4.5
assert abs(call - 9.227005508154) < 1e-6
print(f"mistake 4, run backwards 100 s: a ripple 1 cm long grows by e^{K * (2 * pi) ** 2 * 100:.2f}")
print("ALL CHECKS PASS")
