# Standing waves on a string -- the check behind the card.  Standard library only.
# A 1 m string, c = 1 m/s, ends fixed, pulled 1 cm aside at the middle, let go.
# Roads: the sine series (amplitudes by Simpson's rule and by formula), d'Alembert's
# two travelling halves, a grid stepped in time.  Energy: by mode and from the shape.
from math import sin, cos, pi
L, C = 1.0, 1.0
clean = lambda v: round(v, 9) + 0.0       # prints -0.000000 as 0.000000

def pluck(x, a=0.5):                      # the triangle, 1 cm high at x = a
    return x / a if x <= a else (L - x) / (L - a)
def b_simpson(n, a=0.5, m=2000):          # b_n = (2/L) * integral of pluck * sine
    f = lambda x: pluck(x, a) * sin(n * pi * x / L)
    s = f(0) + f(L) + sum((4 if k % 2 else 2) * f(k * L / m) for k in range(1, m))
    return 2 / L * s * (L / m) / 3
def b(n):                                 # the closed form for the middle pluck
    return 8 / (n * n * pi * pi) * sin(n * pi / 2)
def series(x, t, N):
    return sum(b(n) * sin(n * pi * x / L) * cos(n * pi * C * t / L) for n in range(1, N + 1))
def dal(x, t):                            # half the pluck runs each way, reflected odd
    def ext(y):
        y %= 2 * L
        return pluck(y) if y <= L else -pluck(2 * L - y)
    return 0.5 * (ext(x - C * t) + ext(x + C * t))
def grid(m, t_end, r=0.5):                # leapfrog, m intervals, c*dt/dx = r
    u0 = [pluck(i / m) for i in range(m + 1)]
    u1 = [0.0] + [u0[i] + r*r/2 * (u0[i+1] - 2*u0[i] + u0[i-1]) for i in range(1, m)] + [0.0]
    for _ in range(round(t_end * C * m / r) - 1):
        u0, u1 = u1, [0.0] + [2*u1[i] - u0[i] + r*r * (u1[i+1] - 2*u1[i] + u1[i-1]) for i in range(1, m)] + [0.0]
    return max(abs(u1[i] - dal(i / m, t_end)) for i in range(m + 1))
def shape_energy(t, m=1000, h=1e-7):      # (1/2) integral of u_t^2, and of c^2 u_x^2
    xs = [(k + 0.5) / m for k in range(m)]
    kin = sum(((dal(x, t + h) - dal(x, t - h)) / (2 * h)) ** 2 for x in xs) / (2 * m)
    pot = sum(C * C * ((dal(x + h, t) - dal(x - h, t)) / (2 * h)) ** 2 for x in xs) / (2 * m)
    return kin, pot

mode_E = lambda n, k=1: L / 4 * (k * pi * C / L) ** 2 * b(n) ** 2      # k = n is right
print("string 1 m, c = 1 m/s, plucked 1 cm at the middle; harmonic 1 repeats every 2 s")
for n in range(1, 7):
    print(f"harmonic {n}: b by Simpson {clean(b_simpson(n)):+.6f} cm, by formula {clean(b(n)):+.6f} cm, "
          f"{n * C / (2 * L):.1f} Hz, energy share {100 * mode_E(n, n) / 2:.2f}%")
print(f"middle at t = 0.25 s: d'Alembert {dal(0.5, 0.25):.6f}, series to n = 21 {series(0.5, 0.25, 21):.6f}, to n = 201 {series(0.5, 0.25, 201):.6f}")
errs = [grid(m, 0.25) for m in (40, 80, 160)]
print(f"grid, c*dt/dx = 0.5, worst error at t = 0.25 s: 40 intervals {errs[0]:.4f}, 80 {errs[1]:.4f}, 160 {errs[2]:.4f} cm")
for t in (0, 0.25, 0.5):
    k, p = shape_energy(t)
    print(f"energy from the shape at t = {t} s: motion {k:.6f} + stretch {p:.6f} = {k + p:.6f}")
modes = [sum(mode_E(n, n) for n in range(1, N + 1)) for N in (201, 2001)]
print(f"energy summed over modes: to n = 201 {modes[0]:.6f}, to n = 2001 {modes[1]:.6f}")
print(f"figure, t = 0 peak (180.0, {190 - 130 * dal(0.5, 0):.1f}); t = 0.25 s shoulders ({40 + 280 * 0.25:.1f}, "
      f"{190 - 130 * dal(0.25, 0.25):.1f}) ({40 + 280 * 0.75:.1f}, {190 - 130 * dal(0.75, 0.25):.1f}); t = 0.5 s flat at {190 - 130 * dal(0.5, 0.5):.1f}")
w = lambda x, t: max(C * t - x, 0.0) ** 3                               # a wave arriving from x < 0
print(f"mistake, ends not held: u = (t - x)^3 for t > x starts at rest, middle at t = 1 s {w(0.5, 1):.6f} cm")
print(f"mistake, energy as sum of b_n^2 without n^2: {sum(mode_E(n) for n in range(1, 2002)):.6f}")
print(f"mistake, pluck at a quarter still hollow: b_2 by Simpson {b_simpson(2, 0.25):.6f} cm, not 0")
print(f"mistake, series cut after harmonic 1: middle at t = 0 {series(0.5, 0, 1):.6f} cm, not 1")
assert all(abs(b_simpson(n) - b(n)) < 1e-6 for n in range(1, 7))        # integral vs formula
assert abs(series(0.5, 0.25, 201) - dal(0.5, 0.25)) < 1e-4 and errs[2] < errs[0] / 2
assert abs(modes[1] - sum(shape_energy(0.25))) < 1e-3                     # modes vs shape
assert abs(b_simpson(2, 0.25) - 32 / (12 * pi * pi)) < 1e-6              # quarter pluck, b_2
print("ALL CHECKS PASS")
