# Inverting a Laplace transform -- the check behind the card.  V(s) = 2/(s(s + 2))
# is the charging capacitor's voltage.  Road one: residues of V(s)e^(st), each by
# its own limit.  Road two: the Bromwich integral itself, summed up the line Re s = 1.
import math
POLES, C = [0, -2], 1.0

def cexp(z):                           # e^z from e^x, cos and sin
    return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))

def V(s): return 2 / (s * (s + 2))

def res(a, t):                         # (s - a)V(s)e^(st) = 2e^(st)/(s - b), b the other pole; s -> a
    b = [p for p in POLES if p != a][0]
    return 2 / (a - b) * math.exp(a * t)

def by_residues(t):                    # t > 0: close left, both poles; t < 0: close right, none
    return sum(res(a, t) for a in POLES) if t >= 0 else 0.0

def line(F, t, W, c=C, h=0.01):        # (1/(2 pi i)) x integral up Re s = c, from c - iW to c + iW;
    n = round(W / h)                   # F(conj s) = conj F(s), so twice the real part of the top half
    tot = sum((F(complex(c, k * h)) * cexp(complex(c, k * h) * t)).real * (0.5 if k in (0, n) else 1)
              for k in range(n + 1))
    return tot * h / math.pi + 0.0

def arc(t, R, n):                      # (1/(2 pi i)) x integral round the left half circle, radius R
    ws = [cexp(1j * (math.pi / 2 + k * math.pi / n)) for k in range(n + 1)]
    tot = sum(V(C + R * w) * cexp((C + R * w) * t) * R * w * (0.5 if k in (0, n) else 1) for k, w in enumerate(ws))
    return tot / (2 * n)

def forward(f, s, T=40.0, n=80000):    # Laplace transform of f at s, trapezoid on [0, T]
    return T / n * sum(f(k * T / n) * math.exp(-s * k * T / n) * (0.5 if k in (0, n) else 1) for k in range(n + 1))

print(f"residues of V(s)e^(st) at t = 0: at 0 {res(0, 0):.6f}, at -2 {res(-2, 0):.6f}")
d = 1 / 5 - 1 / 9                       # match A/s + B/(s + 2) to V at s = 1 and 3, by Cramer's rule
A, B = (V(1) / 5 - V(3) / 3) / d, (V(3) - V(1) / 3) / d
print(f"partial fractions, matched at s = 1 and s = 3: A = {A:.6f}, B = {B:.6f}")
print(f"v(1) by residues: {res(0, 1):.6f} + ({res(-2, 1):.6f}) = {by_residues(1):.6f}")
lines = [line(V, 1, W) for W in (10, 100, 1000)]
print("v(1) by the line integral, W = 10, 100, 1000: " + ", ".join(f"{x:.6f}" for x in lines))
arcs = [arc(1, R, 100 * R) for R in (10, 100, 1000)]
print("left arc's share at t = 1, R = 10, 100, 1000: " + ", ".join(f"{x.real:.6f}" for x in arcs))
ts = [0, 0.5, 1, 1.5, 2, 2.5, 3]
print("chart, v(t) at t = 0 to 3 by residues: " + ", ".join(f"{by_residues(t):.4f}" for t in ts))
print("chart, t = 0.5 to 3 by the line integral, W = 1000: " + ", ".join(f"{line(V, t, 1000):.4f}" for t in ts[1:]))
neg = line(V, -1, 1000)
print(f"t = -1: residues, closing right, {by_residues(-1):.6f}; line integral {abs(neg):.6f}")
fw = forward(by_residues, 1.0)
print(f"forward check, Laplace transform of 1 - e^(-2t) at s = 1: {fw:.6f}; V(1) = {V(1):.6f}")
left = line(V, 1, 1000, c=-1.0)
print(f"mistake, line at Re s = -1, between the poles: {left:.6f}, not {by_residues(1):.6f}")
print(f"mistake, e^(st) dropped: residues of V alone sum to {res(0, 0) + res(-2, 0):.6f}")
pl = line(lambda s: (1 - cexp(-s)) / s, 0.5, 1000)
print(f"break, pulse (1 - e^(-s))/s at t = 0.5: residue sum 0.000; line integral {pl:.3f}")
print("figure, 25 units per 1, 0 at (220, 125); -2 at (170, 125); Re s = 1 at x = 245, "
      "y from 25 to 225; left arc radius 100 (R = 4), leftmost x = 145")
assert abs(lines[2] - by_residues(1)) < 1e-5 and abs(neg) < 1e-4           # two roads agree
assert all(abs(lines[i] + arcs[i].real - by_residues(1)) < 1e-5 for i in range(3))  # line + arc = residues
assert abs(A - res(0, 0)) < 1e-12 and abs(B - res(-2, 0)) < 1e-12           # partial fractions = residues
assert abs(fw - V(1)) < 1e-6 and abs(pl - 1) < 1e-2                          # back to V; the pulse needs the line
print("ALL CHECKS PASS")
