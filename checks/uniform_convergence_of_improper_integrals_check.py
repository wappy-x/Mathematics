# Uniform convergence of improper integrals -- the check behind the card.  Only
# exp, sin, atan, log and pi come from the standard library; every integral is the
# script's own Simpson sum.  Road one integrates directly; road two takes the
# derivative through the integral sign; road three is the closed form.
from math import exp, sin, atan, log, pi
def simpson(g, a, b, m=6000):                  # parabolas through equal steps
    w = (b - a) / m
    return w / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * g(a + i * w) for i in range(m + 1))
def area(n, t, a=0.0, b=60.0): return simpson(lambda x: x ** n * exp(-t * x), a, b)
def sinc(x): return 1.0 if x == 0 else sin(x) / x
def dirichlet(t): return simpson(lambda x: exp(-t * x) * sinc(x), 0, 60 / t, int(6000 / t))
def cap_tail(B): return exp(-B) * (B ** 3 + 3 * B ** 2 + 6 * B + 6)    # area of x^3 e^(-x) beyond B
a1, a2 = area(3, 1.0), area(3, 2.0)
print(f"x^3 e^(-tx) on [0, 60]: t=1 Simpson {a1:.6f}, 6/t^4 {6 / 1 ** 4:.6f}; t=2 Simpson {a2:.6f}, 6/t^4 {6 / 2 ** 4:.6f}")
caps = [area(n, 1.0) for n in (1, 2, 3)]
print("caps for t >= 1: area of x e^(-x), x^2 e^(-x), x^3 e^(-x):", " ".join(f"{c:.6f}" for c in caps))
h = 1e-4
dq = (area(2, 1.5 + h) - area(2, 1.5 - h)) / (2 * h)
print(f"slope of the x^2 integral at t=1.5 by difference quotient {dq:.6f}; minus the x^3 integral "
      f"{-area(3, 1.5):.6f}; -6/t^4 {-6 / 1.5 ** 4:.6f}")
tails = [area(3, 1 + k / 2, 20.0, 100.0) for k in range(9)]     # t = 1, 1.5, ..., 5
worst = max(tails)
print(f"tail beyond B=20, worst over t = 1, 1.5, ..., 5: {worst:.7f} at t={1 + tails.index(worst) / 2:.2f}; "
      f"cap's tail {cap_tail(20):.7f}")
Bs = range(0, 45, 5)
capped = [max(area(3, t, B, B + 80.0) for t in (1.0, 2.0, 4.0)) for B in Bs]
ts = [10.0 ** -k for k in range(7)]
def drip(t, B): return simpson(lambda x: t * exp(-t * x), B, B + 60 / t)   # tail of t e^(-tx)
uncapped = [max(drip(t, B) for t in ts) for B in Bs]
print("chart capped:  ", " ".join(f"{v:.2f}" for v in capped))
print("chart uncapped:", " ".join(f"{v:.2f}" for v in uncapped))
print("tail beyond B=100 of t e^(-tx) at t=0.1, 0.01, 0.001:", " ".join(f"{drip(t, 100.0):.6f}" for t in (0.1, 0.01, 0.001)))
print(f"integral of t e^(-tx) at t=0.001: {simpson(lambda x: 0.001 * exp(-0.001 * x), 0, 60000):.6f}; at t=0 the integrand is 0, integral 0")
d1, d01 = dirichlet(1.0), dirichlet(0.1)
print(f"I(t) = integral of e^(-tx) sin x / x: t=1 Simpson {d1:.6f}, pi/2 - arctan t {pi / 2 - atan(1):.6f}")
print(f"  t=0.1 Simpson {d01:.6f}, pi/2 - arctan t {pi / 2 - atan(0.1):.6f}")
dI = (dirichlet(1 + h) - dirichlet(1 - h)) / (2 * h)
print(f"I'(1) by difference quotient {dI:.6f}; integral of -e^(-x) sin x {simpson(lambda x: -exp(-x) * sin(x), 0, 60):.6f}; -1/(1+t^2) {-1 / 2:.6f}")
si = [simpson(sinc, 0, B, 100 * B) for B in (10, 100, 1000)]
print("t=0: integral of sin x / x up to B = 10, 100, 1000:", " ".join(f"{v:.6f}" for v in si))
print("  miss from pi/2:", " ".join(f"{abs(pi / 2 - v):.6f}" for v in si) + "; bound 2/B: 0.200000 0.020000 0.002000")
ab = [simpson(lambda x: abs(sinc(x)), 0, N * pi, 200 * N) for N in (10, 100, 1000)]
print("no cap at t=0: integral of |sin x|/x up to 10pi, 100pi, 1000pi:", " ".join(f"{v:.6f}" for v in ab))
print(f"mistakes: constant dropped, I(0) = -arctan 0 = 0, not {pi / 2:.6f}; "
      f"cap x^3 for t >= 0 has no area, and 6/t^4 at t=0.1 is {6 / 0.1 ** 4:.0f}")
gam = lambda s: simpson(lambda u: 2 * u ** (2 * s - 1) * exp(-u * u), 0, 10, 20000)  # x = u^2
dG = (gam(1 + h) - gam(1 - h)) / (2 * h)
lnin = simpson(lambda u: 4 * u * log(u) * exp(-u * u) if u > 0 else 0.0, 0, 10, 20000)
print(f"gamma'(1) by difference quotient {dG:.6f}; integral of ln x e^(-x) {lnin:.6f}; minus Euler's constant -0.577216")
cap0, cap1 = simpson(lambda u: -16 * u * log(u) if u > 0 else 0.0, 0, 1), simpson(lambda x: x * log(x) * exp(-x), 1, 60)  # x = u^4
print(f"caps on gamma's s-rate, s from 1/2 to 2: x^(-1/2)|ln x| on (0, 1], area {cap0:.6f}; x ln x e^(-x) beyond 1, area {cap1:.6f}")
assert abs(dG - lnin) < 1e-6 and abs(lnin + 0.5772156649) < 1e-6        # gamma: slope inside
assert abs(cap0 - 4) < 1e-6 and abs(cap1 - exp(-1) - simpson(lambda x: exp(-x) / x, 1, 60)) < 1e-6   # caps: by hand; by parts
assert abs(a1 - 6) < 1e-6 and abs(a2 - 6 / 16) < 1e-6                   # direct vs 6/t^4
assert abs(dq + area(3, 1.5)) < 1e-5 and abs(dq + 6 / 1.5 ** 4) < 1e-5  # derivative passes inside
assert tails.index(worst) == 0 and abs(worst - cap_tail(20)) < 1e-9     # the cap bounds every tail
assert abs(d1 - pi / 4) < 1e-6 and abs(d01 - (pi / 2 - atan(0.1))) < 1e-6 and abs(dI + 0.5) < 1e-5
assert all(abs(pi / 2 - v) <= 2 / B for v, B in zip(si, (10, 100, 1000)))  # the uniform tail bound
assert min(uncapped) > 0.99 and capped[-1] < 1e-9 and ab[2] - ab[1] > 1.4  # no cap: tails stay
print("ALL CHECKS PASS")
