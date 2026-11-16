# Levy's inversion formula -- the check behind the card.
# Standard library only: math supplies sin, cos and pi, nothing more.  Every
# integral is Simpson's rule written out, and so is the sine integral Si.
from math import sin, cos, pi

def simpson(f, a, b, n):           # n even: weights 1, 4, 2, 4, ..., 4, 1
    h = (b - a) / n
    s = f(a) + f(b)
    for k in range(1, n):
        s += (4 if k % 2 else 2) * f(a + k * h)
    return s * h / 3

def sinc(v):
    return 1.0 if v == 0 else sin(v) / v

def Si(u):                         # sine integral: area under sin(v)/v, 0 to u
    return simpson(sinc, 0.0, u, 2 * int(20 * abs(u) + 50))

def Si_series(u):                  # second road: u - u^3/(3*3!) + u^5/(5*5!) - ...
    term, s = u, 0.0
    for k in range(40):
        s += term / (2 * k + 1)
        term *= -u * u / ((2 * k + 2) * (2 * k + 3))
    return s

def G(u):                          # area under Si from 0 to |u|
    u = abs(u)
    return u * Si(u) + cos(u) - 1

def phi_U(t):                      # rounding error, uniform on [-0.5, 0.5] g
    return (sinc(t / 2), 0.0)

def phi_die(t):                    # one fair die: (1/6)(e^{it} + ... + e^{6it})
    return (sum(cos(k * t) for k in range(1, 7)) / 6,
            sum(sin(k * t) for k in range(1, 7)) / 6)

def levy(phi, a, b, T, flip=1.0):  # road 1: (1/2pi) int_{-T}^{T} weight * phi dt
    def g(t):
        if t == 0:
            return b - a
        re, im = phi(t)
        wr = (sin(t * b) - sin(t * a)) / t
        wi = (cos(t * b) - cos(t * a)) / t
        return wr * re - wi * flip * im
    return simpson(g, 0.0, T, 2 * int(50 * T + 100)) / pi

def kernel(x, a, b, T):            # what the cut-off formula does to one value x
    return (Si(T * (x - a)) - Si(T * (x - b))) / pi

def fubini_U(a, b, T):             # road 2: average of the kernel over U, exact
    return (G(T * (0.5 - a)) - G(T * (-0.5 - a))
            - G(T * (0.5 - b)) + G(T * (-0.5 - b))) / (pi * T)

def fubini_die(a, b, T):           # road 2 for the die: six faces, 1/6 each
    return sum(kernel(k, a, b, T) for k in range(1, 7)) / 6

def dens(phi, x, T):               # (1/2pi) int_{-T}^{T} e^{-itx} phi(t) dt
    return simpson(lambda t: phi(t)[0] * cos(t * x) + phi(t)[1] * sin(t * x),
                   0.0, T, 2 * int(50 * T + 100)) / pi

def f6(v):
    return f"{v:.6f}"

print("fingerprint of U: phi_U(4) =", f6(phi_U(4)[0]), " first zero at 2 pi =", f6(2 * pi))
print("chart, t     ", " ".join(f"{t:5d}" for t in range(0, 41, 2)))
print("chart, phi_U ", " ".join(f"{phi_U(t)[0]:5.2f}" for t in range(0, 41, 2)))
print("Si(pi) by Simpson", f6(Si(pi)), "by series", f6(Si_series(pi)), " Si(200) =", f6(Si(200)), " pi/2 =", f6(pi / 2))
assert abs(Si(pi) - Si_series(pi)) < 1e-9          # two roads to Si
assert abs(Si(200) - pi / 2) < 2 / 200              # Si settles on pi/2

a, b = -0.25, 0.25                                  # the error under a quarter gram
exact = b - a                                       # uniform: chance = length
print(f"U, a = {a} g, b = {b} g, exact chance by length {f6(exact)}")
print("    T   integral over t   kernel averaged over U")
for T in (10, 40, 160):
    r1, r2 = levy(phi_U, a, b, T), fubini_U(a, b, T)
    print(f"{T:5d}   {f6(r1)}          {f6(r2)}")
    assert abs(r1 - r2) < 1e-8                      # Fubini: both orders agree
assert abs(levy(phi_U, a, b, 160) - exact) < 1e-3   # the limit is the chance
print("hand: Si(10) =", f6(Si(10)), " Si(30) =", f6(Si(30)), " G(10) =", f6(G(10)),
      " G(30) =", f6(G(30)), " 2(G(30) - G(10))/(40 pi) =", f6(2 * (G(30) - G(10)) / (40 * pi)))
for u in (10, 30):                                  # G against its definition: area under Si
    assert abs(G(u) - simpson(Si, 0.0, u, 20 * u)) < 1e-6
print("kernel at T = 40: x = 0:", f6(kernel(0, a, b, 40)), " x = 0.25:", f6(kernel(0.25, a, b, 40)),
      " x = 0.4:", f6(kernel(0.4, a, b, 40)), " ceiling 2 Si(pi)/pi =", f6(2 * Si(pi) / pi))
assert max(abs(kernel(k / 100, a, b, 40)) for k in range(-100, 101)) <= 2 * Si(pi) / pi

pf = [1 / 6] * 6                                    # the die, counted
for (a, b) in ((2, 5), (2.5, 4.5)):
    inside = sum(p for k, p in zip(range(1, 7), pf) if a < k < b)
    ends = sum(p for k, p in zip(range(1, 7), pf) if k in (a, b))
    vals = [levy(phi_die, a, b, T) for T in (10, 40, 160, 640)]
    print(f"die, a = {a}, b = {b}: T = 10, 40, 160, 640:", " ".join(f6(v) for v in vals),
          f" counted: inside {f6(inside)}, half the ends {f6(ends / 2)}")
    for T, v in zip((10, 40, 160, 640), vals):      # Fubini at every cut-off
        assert abs(v - fubini_die(a, b, T)) < 1e-8
    assert abs(vals[-1] - (inside + ends / 2)) < 1e-3
print("die, a = 2, b = 5: chance with both ends", f6(4 / 6))

print("density of U by the cut-off integral (true: 1 inside, 0 outside)")
print("  peak: at x = 0.5 - pi/T;  abs area: (1/2pi) int_{-T}^{T} |phi_U(t)| dt")
print("    T     x = 0  x = 0.25  edge 0.5      peak  abs area")
for T in (10, 40, 160):
    row = [dens(phi_U, x, T) for x in (0, 0.25, 0.5, 0.5 - pi / T)]
    row.append(simpson(lambda t: abs(phi_U(t)[0]), 0, T, 20000) / pi)
    print(f"{T:5d}  " + "  ".join(f6(v) for v in row))
assert abs(dens(phi_U, 0.5, 160) - kernel(0.5, -0.5, 0.5, 160)) < 1e-8
print("peak limit 1/2 + Si(pi)/pi =", f6(0.5 + Si(pi) / pi))
xs = [k / 10 - 1 for k in range(21)]
print("chart, x      ", " ".join(f"{x:5.1f}" for x in xs))
print("chart, gate   ", " ".join(f"{(1.0 if abs(x) < 0.5 else 0.5 if abs(x) == 0.5 else 0.0):5.2f}" for x in xs))
for T in (10, 40):
    print(f"chart, T = {T:2d}", " ".join(f"{dens(phi_U, x, T):5.2f}" for x in xs))

sq = lambda t: (phi_U(t)[0] ** 2, 0.0)              # error of gross minus tare
print("U1 - U2, triangle on [-1, 1] g: true density 1 at 0, 0.5 at 0.5")
for T in (50, 200):
    d0, d5, tail = dens(sq, 0, T), dens(sq, 0.5, T), 4 / (pi * T)
    print(f"  T = {T:3d}: x = 0: {f6(d0)}  x = 0.5: {f6(d5)}  tail bound 4/(pi T) = {f6(tail)}")
    assert abs(d0 - 1) <= tail                      # inside the tail bound
    assert abs(d5 - 0.5) <= tail

print("mistake, no 1/(2 pi), U, T = 160:", f6(2 * pi * levy(phi_U, -0.25, 0.25, 160)))
fl = levy(phi_die, 2.5, 4.5, 160, flip=-1.0)
print("mistake, spin-back sign flipped, die, a = 2.5, b = 4.5, T = 160:", f6(fl))
assert abs(fl) < 1e-3                               # recovers -X: chance 0
print("ALL CHECKS PASS")
