# Convergence, jumps and Gibbs -- the check behind the card.  Nothing is imported
# but math's sin and pi.  Square wave: -1 on (-pi, 0), +1 on (0, pi), period 2 pi.
# S(N, x) = (4/pi)(sin x + sin 3x/3 + ... + sin((2N-1)x)/(2N-1)), N odd harmonics.
from math import sin, pi

def S(N, x):                                  # road one: add the terms
    return 4 / pi * sum(sin((2 * k - 1) * x) / (2 * k - 1) for k in range(1, N + 1))

def simpson(g, a, b, n=4000):                 # our own integrator, n even
    h = (b - a) / n
    return h / 3 * sum(g(a + i * h) * (1 if i in (0, n) else 4 if i % 2 else 2) for i in range(n + 1))

def S_kernel(N, x):                           # road two: S' = (2/pi) sin(2Nt)/sin t, from S(0) = 0
    return 2 / pi * simpson(lambda t: 2 * N if t == 0 else sin(2 * N * t) / sin(t), 0, x)

def tri_err(N):                               # |x| minus its N-harmonic series, at x = 0 (its worst point)
    return abs(pi / 2 - 4 / pi * sum(1 / (2 * k - 1) ** 2 for k in range(1, N + 1)))

Ns = (10, 50, 250)
print("square wave: -1 on (-pi, 0), +1 on (0, pi); N = number of odd harmonics")
print("at the jump x = 0: " + ", ".join(f"S_{N} = {S(N, 0):.6f}" for N in Ns) + "; midpoint of -1 and 1 = 0")
print("at x = pi/2 by hand: " + ", ".join(f"S_{N} = {S(N, pi / 2):.4f}" for N in (1, 2, 3)))
print("at x = pi/2, error S_N - 1: " + ", ".join(f"N = {N}: {S(N, pi / 2) - 1:+.6f}" for N in Ns))
part = [sum((-1) ** (k - 1) / (2 * k - 1) for k in range(1, n + 1)) for n in (50, 51)]
pi_int = simpson(lambda t: 4 / (1 + t * t), 0, 1)
print(f"Leibniz: 4 x (1 - 1/3 + ... 50 terms) = {4 * part[0]:.6f}; 4 x mean of 50 and 51 terms = "
      f"{2 * (part[0] + part[1]):.6f}; pi as area under 4/(1+t^2) = {pi_int:.6f}")
peaks = {}
for N in Ns:
    x = pi / (2 * N)                          # first place S' is zero: sin(2Nx) = 0
    peaks[N] = (S(N, x), S_kernel(N, x))
    print(f"peak N = {N}: at x = pi/{2 * N} = {x:.5f}; by the terms {peaks[N][0]:.6f}; by the kernel {peaks[N][1]:.6f}")
si_int = simpson(lambda u: 1 if u == 0 else sin(u) / u, 0, pi)
si_ser, term = 0.0, pi                        # Si(pi) = sum (-1)^n pi^(2n+1) / ((2n+1)(2n+1)!)
for n in range(30):
    si_ser += term / (2 * n + 1)
    term *= -pi * pi / ((2 * n + 2) * (2 * n + 3))
lim = 2 / pi * si_ser
print(f"limit (2/pi) Si(pi): by Simpson {2 / pi * si_int:.6f}; by power series {lim:.6f}")
print(f"overshoot {lim - 1:.6f} above 1 = {100 * (lim - 1) / 2:.2f}% of the jump 2; read as % of the height 1: peak {1 + (lim - 1) / 2:.2f}, wrong")
print("square-wave overshoot, N = 10, 50, 250: " + ", ".join(f"{peaks[N][0] - 1:.4f}" for N in Ns))
print("triangle |x| worst error, N = 10, 50, 250: " + ", ".join(f"{tri_err(N):.6f}" for N in Ns)
      + "; times pi N: " + ", ".join(f"{tri_err(N) * pi * N:.4f}" for N in Ns))
xs = [i / 100 for i in range(21)]
print("figure, x: " + ", ".join(f"{x:.2f}" for x in xs))
print("figure, S_10: " + ", ".join(f"{S(10, x):.2f}" for x in xs))
print("figure, S_50: " + ", ".join(f"{S(50, x):.2f}" for x in xs))
print(f"mistake, value at the jump taken as f(0) = 1: series gives {S(50, 0):.2f}, off by 1")
assert all(abs(a - b) < 1e-9 for a, b in peaks.values())             # two roads to each peak
assert abs(si_int - si_ser) < 1e-9 and abs(peaks[250][0] - lim) < 1e-4  # peak -> (2/pi) Si(pi)
assert abs(2 * (part[0] + part[1]) - pi_int) < 5e-4 < abs(4 * part[0] - pi_int)  # Leibniz, and averaging helps
assert abs(tri_err(250) * pi * 250 - 1) < 0.01                     # no jump: error dies like 1/(pi N)
assert min(t for t, _ in peaks.values()) - 1 > 0.178               # a jump: the overshoot stays
print("ALL CHECKS PASS")
