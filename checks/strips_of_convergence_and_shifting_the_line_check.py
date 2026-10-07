# Where a transform lives -- the check behind the card.  Standard library only.
# The balance f(t) = e^(0.05t) for t >= 0, and the drawn-down balance h(t):
# e^(0.05t) before today (t < 0), e^(-0.20t) from today on.  Road 1: closed forms
# and residues.  Road 2: the defining integrals and the inverse line integrals, summed.
import math
c, d = 0.05, 0.20                                  # growth before today, draw-down after
def cexp(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
def show(z):                                       # 'a + bi', six decimals, no -0.000000
    a, b = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def simpson(g, lo, hi, n):                         # Simpson's rule, n even
    k = (hi - lo) / n
    return k / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * g(lo + j * k) for j in range(n + 1))
def F(s): return 1 / (s - c)                       # road 1: the balance's transform, Re s > 0.05
def H(s): return 1 / (c - s) + 1 / (s + d)         # road 1: h's transform, -0.20 < Re s < 0.05
def h(t): return math.exp(c * t) if t < 0 else math.exp(-d * t)
def bal(t): return math.exp(c * t)
def fwd(g, s, lo, hi, n=60000): return simpson(lambda t: g(t) * cexp(-s * t), lo, hi, n)   # road 2
def seg(p, q, t, n):                               # integral of H(s) e^(st) ds, straight from p to q
    return simpson(lambda u: H(p + u * (q - p)) * cexp((p + u * (q - p)) * t), 0, 1, n) * (q - p)
def line(sig, t, R=2000):                          # (1 / 2 pi i) x integral up the line Re s = sig
    a, b = complex(sig, -1), complex(sig, 1)
    tot = seg(complex(sig, -R), a, t, 200000) + seg(a, b, t, 4000) + seg(b, complex(sig, R), t, 200000)
    return tot / (2j * math.pi)
def loop(s1, s2, R, t):                            # anticlockwise round the rectangle s1 to s2, -R to R
    p = [complex(s1, -R), complex(s2, -R), complex(s2, R), complex(s1, R)]
    return sum(seg(p[k], p[(k + 1) % 4], t, 40000) for k in range(4))
one = fwd(bal, 0.1, 0, 600)
damped = fwd(lambda t: bal(t) * math.exp(-0.1 * t), 0.05j, 0, 600)
print(f"balance, s = 0.10: 1/(s - 0.05) {F(0.1):.6f}; summed to T = 600 {show(one)}")
print(f"balance damped by a = 0.10, Fourier at w = 0.05: F(a + iw) {show(F(0.1 + 0.05j))}; summed {show(damped)}")
for s in (0.10, 0.05, 0.03, 0.0):
    p = [fwd(bal, s, 0, T, 20000).real for T in (100, 200)]
    print(f"balance summed to T = 100, 200 at s = {s:.2f}: {p[0]:.6f}, {p[1]:.6f}")
p = [fwd(bal, 0.1, -T, 0, 20000).real for T in (100, 200)]
print(f"all-time balance, past half at s = 0.10, from -100, -200: {p[0]:.6f}, {p[1]:.6f}")
two = fwd(h, 0.1j, -700, 0) + fwd(h, 0.1j, 0, 200)
print(f"drawn-down h, s = 0.1i: H {show(H(0.1j))}; summed {show(two)}; H(0) {H(0):.6f}")
L = {}
for sig in (0.0, -0.10, 0.10, -0.25):
    L[sig] = [line(sig, t) for t in (5, -10)]
    print(f"inverse up Re s = {sig:.2f}: t = 5 {show(L[sig][0])}, t = -10 {show(L[sig][1])}")
print(f"h itself: {h(5):.6f}, {h(-10):.6f}; minus e^(0.05t): {h(5) - bal(5):.6f}, {h(-10) - bal(-10):.6f}; "
      f"minus e^(-0.20t): {h(5) - math.exp(-d * 5):.6f}, {h(-10) - math.exp(2):.6f}")
inside = [loop(-0.1, 0, R, 5) for R in (0.1, 10)]
print(f"rectangle Re s -0.10 to 0, t = 5: loop at R = 0.1 {show(inside[0])}, at R = 10 {show(inside[1])}")
tops = [abs(seg(complex(0, R), complex(-0.1, R), 5, 4000)) for R in (0.1, 1, 10)]
print(f"top side size at R = 0.1, 1, 10: {tops[0]:.6f}, {tops[1]:.6f}, {tops[2]:.6f}")
pole, res = loop(0, 0.1, 0.1, 5), -bal(5)          # residue of H(s) e^(st) at 0.05 is -e^(0.05t)
print(f"rectangle Re s 0 to 0.10 round the pole 0.05, t = 5: loop {show(pole)}; 2 pi i x residue {show(2j * math.pi * res)}")
pul = fwd(lambda t: 1.0, -1, 0, 1, 2000)
print(f"house pulse (1 - e^(-s))/s: s = -1 {math.e - 1:.6f}, summed {show(pul)}; s = i {show((1 - cexp(-1j)) / 1j)}")
x, y = (lambda sg: round(240 + 800 * sg)), (lambda im: round(120 - 800 * im))
print(f"figure, 800 units per unit, origin (240, 120): poles x = {x(-d)}, {x(c)}; lines x = {x(-0.1)}, {x(0)}, {x(0.1)}; rectangle y = {y(0.1)} to {y(-0.1)}")
assert abs(one - F(0.1)) < 1e-9 and abs(damped - F(0.1 + 0.05j)) < 1e-9 and abs(two - H(0.1j)) < 1e-9
assert all(abs(L[sig][k] - h(t)) < 1e-6 for sig in (0.0, -0.10) for k, t in enumerate((5, -10)))
assert all(abs(L[0.10][k] - h(t) + bal(t)) < 1e-6 and abs(L[-0.25][k] - h(t) + math.exp(-d * t)) < 1e-6 for k, t in enumerate((5, -10)))
assert abs(inside[1]) < 1e-9 and abs(pole - 2j * math.pi * res) < 1e-8 and tops[2] < tops[1] < tops[0]
print("ALL CHECKS PASS")
