# Stepping the heat equation on a grid -- the check behind the card.  Standard
# library only.  Rod 1 m, ends held at 0 C, kappa = 1, start u = sin(pi x).
# Road one: step the FTCS rule in a loop.  Road two: the exact solution
# e^(-pi^2 t) sin(pi x), and the scheme's own mode factor 1 - 4 r sin^2(k pi dx / 2).
import math
PI = math.pi

def ftcs(dt, dx, steps, in_place=False, r=None):
    n = round(1 / dx)
    r = dt / (dx * dx) if r is None else r
    u = [math.sin(PI * j * dx) for j in range(n + 1)]
    for _ in range(steps):
        old = u if in_place else u[:]
        for j in range(1, n):
            u[j] = r * old[j - 1] + (1 - 2 * r) * old[j] + r * old[j + 1]
    return u

def exact(x, t):
    return math.exp(-PI * PI * t) * math.sin(PI * x)

def factor(r, k, dx):                         # growth of mode sin(k pi x) per step
    return 1 - 4 * r * math.sin(k * PI * dx / 2) ** 2

def max_err(dt, dx, steps):
    u = ftcs(dt, dx, steps)
    return max(abs(u[j] - exact(j * dx, steps * dt)) for j in range(len(u)))

f = lambda v: f"{v:.6f}"
print("grid dx = 0.1, 11 nodes; A: dt = 0.004, r = 0.4; B: dt = 0.006, r = 0.6; limit dt <=", f(0.1 * 0.1 / 2),
      "; dx = 0.05 with dt = 0.004 gives r =", f(0.004 / (0.05 * 0.05)))
print("weights (left, self, right): A", f(0.4), f(1 - 0.8), f(0.4), "| B", f(0.6), f(1 - 1.2), f(0.6))
gA, gB = factor(0.4, 1, 0.1), factor(0.6, 1, 0.1)
print("mode 1 per step: A scheme", f(gA), "exact", f(math.exp(-PI * PI * 0.004)))
print("one step at the middle from", f(math.sin(PI * 4 * 0.1)), f(1.0), f(math.sin(PI * 6 * 0.1)),
      ": A", f(ftcs(0.004, 0.1, 1)[5]), "B", f(ftcs(0.006, 0.1, 1)[5]))
mid = ftcs(0.004, 0.1, 25)[5]
print("A middle at t = 0.1: loop", f(mid), "closed form", f(gA ** 25), "exact", f(exact(0.5, 0.1)))
errs = [max(abs(ftcs(0.004, 0.1, s)[j] - exact(j * 0.1, s * 0.004)) for j in range(11)) for s in range(201)]
print("A largest error over 0 < t <= 0.8:", f(max(errs)), "at t =", f"{errs.index(max(errs)) * 0.004:.3f}")
conv = [max_err(0.004 / 4 ** i, 0.1 / 2 ** i, 25 * 4 ** i) for i in range(3)]
print("error at t = 0.1, r = 0.4, dx = 0.1, 0.05, 0.025:", ", ".join(f(e) for e in conv))
print("error ratios:", f"{conv[0] / conv[1]:.3f}", f"{conv[1] / conv[2]:.3f}")
g9 = factor(0.6, 9, 0.1)
print("B checkerboard mode 9 per step:", f(g9), "doubles every", f"{math.log(2) / math.log(-g9):.2f}", "steps;",
      "A mode 9:", f(factor(0.4, 9, 0.1)), "; pure zigzag 1 - 4r:", f(1 - 4 * 0.6))
first = next(s for s in range(1, 400) if max(map(abs, ftcs(0.006, 0.1, s))) > 1)
growth = (abs(ftcs(0.006, 0.1, 150)[5]) / abs(ftcs(0.006, 0.1, 140)[5])) ** 0.1
print("B first step with |u| > 1:", first, "t =", f"{first * 0.006:.3f}", "; growth per step, steps 140-150:", f(growth))
b, a = ftcs(0.006, 0.1, 130), ftcs(0.004, 0.1, 195)
print("figure, B at t = 0.78:", ", ".join(f"{v:.3f}" for v in b))
print("figure, A at t = 0.78:", ", ".join(f"{v:.4f}" for v in a))
print("figure, exact t = 0.78:", ", ".join(f"{exact(j * 0.1, 0.78):.4f}" for j in range(11)))
print("mistake, r = dt/dx: middle at t = 0.1", f(ftcs(0.004, 0.1, 25, r=0.04)[5]))
print("mistake, update in place: middle at t = 0.1", f(ftcs(0.004, 0.1, 25, in_place=True)[5]))
assert abs(mid - gA ** 25) < 1e-12                       # loop equals the scheme's closed form
assert max(errs) < 0.005                                 # r = 0.4 tracks the exact rod
assert 3.8 < conv[0] / conv[1] < 4.2                     # halve dx, error falls 4x
assert abs(growth + g9) < 1e-3                           # r = 0.6 grows at the predicted rate
print("ALL CHECKS PASS")
