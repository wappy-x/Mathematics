# Separation of variables -- the check behind the card.  Standard library only.
# A 1 m rod, kappa = 1 (scaled time), started at 100 C with both ends held at 0 C:
# u = sum over odd n of (400/(n pi)) e^(-n^2 pi^2 t) sin(n pi x).  Road one: that
# mode sum, its coefficients also found by Simpson's rule.  Road two: a grid that
# steps u_t = u_xx directly and knows nothing of modes.  Second case: a 0-to-100 C
# ramp with insulated ends, a cosine series.
import math
PI = math.pi
def simpson(f, m=2000):                     # integral of f from 0 to 1, m even
    return sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(i / m) for i in range(m + 1)) / (3 * m)
def sine_sum(x, t, terms=10**4):            # cold ends, uniform 100 C start; terms counts odd n
    return sum(400 / (n * PI) * math.exp(-(n * PI) ** 2 * t) * math.sin(n * PI * x) for n in range(1, 2 * terms, 2))
def cos_sum(x, t, terms=400):               # insulated ends, ramp 100x start
    return 50 - sum(400 / (n * PI) ** 2 * math.exp(-(n * PI) ** 2 * t) * math.cos(n * PI * x) for n in range(1, 2 * terms, 2))
def grid(N, t_end, insulated=False):        # N cells, time step dx^2/4, new u = u + (left - 2u + right)/4
    u = [100 * i / N for i in range(N + 1)] if insulated else [0.0] + [100.0] * (N - 1) + [0.0]
    for _ in range(round(t_end * 4 * N * N)):
        e = [u[1]] + u + [u[-2]]            # insulated: mirror points make the end slope zero
        new = [e[i + 1] + (e[i] - 2 * e[i + 1] + e[i + 2]) / 4 for i in range(N + 1)]
        u = new if insulated else [0.0] + new[1:-1] + [0.0]
    return u
b_f = [400 / (n * PI) if n % 2 else 0.0 for n in range(1, 7)]
b_s = [simpson(lambda x: 200 * math.sin(n * PI * x)) for n in range(1, 7)]
a_f = [-400 / (n * PI) ** 2 if n % 2 else 0.0 for n in range(1, 5)]
a_s = [simpson(lambda x: 200 * x * math.cos(n * PI * x)) for n in range(1, 5)]
f3 = lambda v: f"{round(v, 3) + 0.0:.3f}"   # + 0.0 prints -0.000 as 0.000
mid = sine_sum(0.5, 0.05)
modes = [400 / (n * PI) * math.exp(-(n * PI) ** 2 * 0.05) * math.sin(n * PI / 2) for n in (1, 3, 5)]
Ns = (10, 20, 40, 80)
errs = [abs(grid(N, 0.05)[N // 2] - mid) for N in Ns]
end_s, end_g = cos_sum(0.0, 0.05), grid(80, 0.05, True)
print("sine coefficients b1..b6, formula:", " ".join(map(f3, b_f)))
print("sine coefficients b1..b6, Simpson:", " ".join(map(f3, b_s)))
print("middle at t = 0, first 1 2 3 10 100 odd modes:", " ".join(f"{sine_sum(0.5, 0, k):.2f}" for k in (1, 2, 3, 10, 100)))
print("decay factors e^(-n^2 pi^2 0.05), n = 1 3 5:", " ".join(f"{math.exp(-(n * PI) ** 2 * 0.05):.4f}" for n in (1, 3, 5)))
print(f"middle at t = 0.05: modes 1 3 5 give {modes[0]:.2f} {modes[1]:.2f} {modes[2]:.4f}; full sum {mid:.2f} C")
print("grid middle at t = 0.05, N = 10 20 40 80:", " ".join(f"{grid(N, 0.05)[N // 2]:.4f}" for N in Ns))
print("grid error:", " ".join(f"{e:.4f}" for e in errs), " ratios", " ".join(f"{errs[i] / errs[i + 1]:.2f}" for i in range(3)))
print(f"copper, kappa 1.11e-4 m^2/s: one time unit = {1 / 1.11e-4:.0f} s; t = 0.05 is {0.05 / 1.11e-4:.0f} s = {0.05 / 1.11e-4 / 60:.1f} min")
print("figure, x (m):    ", " ".join(f"{i / 10:.1f}" for i in range(11)))
for t in (0.01, 0.05, 0.2):
    print(f"figure, t = {t:.2f}:", " ".join(f"{sine_sum(i / 10, t, 200):.2f}" for i in range(11)))
print("cosine coefficients a1..a4, formula:", " ".join(map(f3, a_f)), " Simpson:", " ".join(map(f3, a_s)))
print(f"insulated ramp, end x = 0 at t = 0.05: series {end_s:.2f} C, grid {end_g[0]:.2f} C; grid mean {(sum(end_g) - (end_g[0] + end_g[-1]) / 2) / 80:.2f} C")
print(f"mistake, dropping the 2 in b_n: middle at t = 0.05 is {mid / 2:.2f} C, not {mid:.2f}")
wrong = sum(400 / (n * PI) * math.exp(-n * PI * PI * 0.05) * math.sin(n * PI / 2) for n in range(1, 2 * 10**4, 2))
print(f"mistake, e^(-n pi^2 t) for e^(-n^2 pi^2 t): middle {wrong:.2f} C, not {mid:.2f}")
cold_mean = sum(200 / (n * PI) * math.exp(-(n * PI) ** 2 * 0.5) * 2 / (n * PI) for n in range(1, 400, 2))
print(f"mistake, insulated ends treated as cold: ramp's mean at t = 0.5 is {cold_mean:.2f} C, not {simpson(lambda x: cos_sum(x, 0.5, 50), 200):.2f}")
assert max(abs(p - q) for p, q in zip(b_f + a_f, b_s + a_s)) < 1e-6    # closed form against numerical integral
assert errs[-1] < 0.02                                                 # grid, no modes, lands on the mode sum
assert all(3.5 < errs[i] / errs[i + 1] < 4.5 for i in range(3))        # and closes in at order two
assert abs(end_s - end_g[0]) < 0.02                                    # insulated case: cosines against the grid
print("ALL CHECKS PASS")
