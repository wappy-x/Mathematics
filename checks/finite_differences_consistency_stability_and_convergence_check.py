# Finite differences on a grid -- the check behind the card.  Standard library only.
# Steel bar 1 m long, ends held at 0 C, diffusivity alpha = 1.2e-5 m^2/s (illustrative),
# start u = 100 sin(pi x) C.  Road one: step the explicit scheme in a loop.  Road two:
# the exact solution 100 e^(-alpha pi^2 t) sin(pi x), and the scheme's own factor g per
# step for this one sine.  Road three: the Lax bound, error <= sum of dt * max |tau|.
from math import pi, sin, cos, exp, log2, log10

ALPHA, U0, T = 1.2e-5, 100.0, 3600.0                  # m^2/s, C, s
HS = [0.04, 0.02, 0.01, 0.005]                         # space steps, m

def sci(v, d=3):                                       # 1.234e-5, the same in Rust
    m, e = f"{v:.{d}e}".split("e")
    return f"{m}e{int(e)}"

def exact(x, t):
    return U0 * exp(-ALPHA * pi * pi * t) * sin(pi * x)

def run(h, r, steps, w=None):                          # explicit steps; w = weight used
    n, w = round(1 / h), r if w is None else w
    u = [U0 * sin(pi * j * h) for j in range(n + 1)]
    for _ in range(steps):
        u = [0.0] + [w * u[j - 1] + (1 - 2 * w) * u[j] + w * u[j + 1] for j in range(1, n)] + [0.0]
    return u

def tau(x, t, h, dt):                                  # exact solution put into the scheme
    d2 = (exact(x + h, t) - 2 * exact(x, t) + exact(x - h, t)) / (h * h)
    return (exact(x, t + dt) - exact(x, t)) / dt - ALPHA * d2

def error_and_bound(h, r, t_end):                      # true max error at t_end, Lax bound
    n, dt = round(1 / h), r * h * h / ALPHA
    steps = round(t_end / dt)
    u = run(h, r, steps)
    err = max(abs(u[j] - exact(j * h, steps * dt)) for j in range(n + 1))
    bound = sum(dt * max(abs(tau(j * h, m * dt, h, dt)) for j in range(1, n)) for m in range(steps))
    return err, bound, steps

def norm_inf(r, n):                                    # largest row sum of |weights| in A
    return max(sum(abs(w) for w in ([r] if i > 1 else []) + [1 - 2 * r] + ([r] if i < n - 1 else []))
               for i in range(1, n))

def orders(es):
    return ", ".join(f"{log2(es[i] / es[i + 1]):.2f}" for i in range(len(es) - 1))

h, dt = 0.02, 10.0
r = ALPHA * dt / h ** 2
print(f"bar 1 m, alpha = {sci(ALPHA, 1)} m^2/s, start 100 sin(pi x) C, T = {T:.0f} s")
print(f"grid h = {h} m, 51 nodes, dt = {dt:.0f} s, r = {r:.4f}, steps {round(T / dt)}; r <= 1/2 needs dt <= {h * h / (2 * ALPHA):.3f} s")
print(f"weights: {r:.4f}, {1 - 2 * r:.4f}, {r:.4f}")
u1 = run(h, r, 1)[25]
print(f"middle after one step: scheme {u1:.6f} C, exact {exact(0.5, dt):.6f} C")
uT = run(h, r, 360)[25]
g = 1 - 4 * r * sin(pi * h / 2) ** 2
print(f"middle at T: loop {uT:.6f} C, closed form 100 g^360 {U0 * g ** 360:.6f} C (g = {g:.8f}), exact {exact(0.5, T):.6f} C")
print(f"one-hour target: centre error below 0.01 C; centre error {abs(uT - exact(0.5, T)):.4f} C")
d2e = [abs((2 * U0 * cos(pi * hh) - 2 * U0) / hh ** 2 + U0 * pi * pi) for hh in HS]
print("second difference of 100 sin(pi x) at 0.5, error: " + ", ".join(f"{e:.6f}" for e in d2e) + "; orders " + orders(d2e))
print(f"  predicted h^2/12 * 100 pi^4 at h = 0.02: {h * h / 12 * U0 * pi ** 4:.6f}; exact value -100 pi^2 = {-U0 * pi * pi:.4f}")
for rr, name in ((0.3, "0.3"), (1 / 6, "1/6")):
    ts = [abs(tau(0.5, 0.0, hh, rr * hh * hh / ALPHA)) for hh in HS]
    lead = ALPHA * pi ** 4 * h * h * U0 * (rr / 2 - 1 / 12)
    print(f"tau at the middle, t = 0, r = {name}: " + ", ".join(sci(t) for t in ts) + " C/s; orders " + orders(ts))
    print(f"  leading term alpha pi^4 h^2 100 (r/2 - 1/12) at h = 0.02: {sci(lead)} C/s")
print(f"norm of the step, max row sum: r = 0.3: {norm_inf(0.3, 50):.4f}, r = 0.5: {norm_inf(0.5, 50):.4f}, r = 0.51: {norm_inf(0.51, 50):.4f}")
gz = 1 - 4 * 0.51 * sin(49 * pi * h / 2) ** 2
print(f"r = 0.51, h = 0.02: dt = {0.51 * h * h / ALPHA:.0f} s, weights 0.5100, {1 - 2 * 0.51:.4f}, 0.5100, zigzag factor g = {gz:.6f}; 1.04^200 = {1.04 ** 200:.1f}; |g|^200 = {abs(gz) ** 200:.1f}")
E3, B3 = [], []
for hh in HS:
    e, b, s = error_and_bound(hh, 0.3, T)
    E3.append(e); B3.append(b)
    print(f"r = 0.3, h = {hh}: {s} steps, true error {sci(e)} C, bound {sci(b)} C, bound / true {b / e:.3f}")
print("r = 0.3: error ratio per halving " + ", ".join(f"{E3[i] / E3[i + 1]:.3f}" for i in range(3)) + "; orders " + orders(E3))
work = [(round(1 / hh) - 1) * round(T / (0.3 * hh * hh / ALPHA)) for hh in HS]
print("work, node updates to 3600 s at r = 0.3: " + ", ".join(str(w) for w in work) + "; ratios " + ", ".join(f"{work[i + 1] / work[i]:.2f}" for i in range(3)))
E6 = [error_and_bound(hh, 1 / 6, T)[0] for hh in HS]
print("r = 1/6: true error " + ", ".join(sci(e) for e in E6) + " C; orders " + orders(E6))
E51 = []
for hh in HS:
    dd = 0.51 * hh * hh / ALPHA
    u = run(hh, 0.51, round(3400 / dd))
    E51.append(max(abs(u[j] - exact(j * hh, 3400.0)) for j in range(len(u))))
print("r = 0.51 at 3400 s, h = 0.04, 0.02, 0.01, 0.005: error " + ", ".join(sci(e) for e in E51) + " C")
print("chart x, log10 h: " + ", ".join(f"{log10(hh):.2f}" for hh in HS))
print("chart, log10 error r = 0.3: " + ", ".join(f"{log10(e):.2f}" for e in E3))
print("chart, log10 bound r = 0.3: " + ", ".join(f"{log10(b):.2f}" for b in B3))
print("chart, log10 error r = 1/6: " + ", ".join(f"{log10(e):.2f}" for e in E6))
sq = [run(hh, 0, 360, w=ALPHA * dt / hh)[round(0.5 / hh)] for hh in HS]
print("mistake, r = alpha dt / h with dt = 10 s: middle at T " + ", ".join(f"{v:.4f}" for v in sq) + f" C; true {exact(0.5, T):.4f} C; weight at h = 0.02: {ALPHA * dt / h:.4f}")
bad = max(map(abs, run(0.01, 1.2, 360)))
print(f"mistake, h = 0.01 with dt = 10 s (r = {ALPHA * 10 / 0.0001:.1f}): largest |u| at T {sci(bad)} C")
assert abs(uT - U0 * g ** 360) < 1e-9                  # loop equals the closed form g^n
assert abs(uT - exact(0.5, T)) < 0.01                  # r = 0.3 tracks the bar
assert all(1.98 < log2(E3[i] / E3[i + 1]) < 2.02 for i in range(3))   # order 2, as tau says
assert all(3.9 < log2(E6[i] / E6[i + 1]) < 4.1 for i in range(3))     # r = 1/6: order 4
assert all(1.0 < B3[i] / E3[i] < 2.0 for i in range(4))              # the Lax bound holds
assert E51[3] > 1e6 * E51[1]                           # consistent but unstable: no convergence
assert abs(sq[3] - exact(0.5, T)) > abs(sq[0] - exact(0.5, T))       # stable, inconsistent: wrong
assert bad > 1e100                                     # h halved, dt kept: r = 1.2 blows up
print("ALL CHECKS PASS")
