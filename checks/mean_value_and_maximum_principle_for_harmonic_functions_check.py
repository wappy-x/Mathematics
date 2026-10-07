# Mean value and maximum principle -- the check behind the card.  Standard
# library only.  The soap film u = x^2 - y^2 on the wire frame |z| = 1, whose
# frame height is cos(2 theta).  Road one: closed forms.  Road two: averages
# round circles, Cauchy's loop sum, and a grid film grown by neighbour averaging.
import math

def u(x, y): return x * x - y * y
def pushed(x, y): return u(x, y) + 1.5 * (1 - x * x - y * y)   # same frame, pushed from below
def lnmod(x, y): return 0.5 * math.log(x * x + y * y)           # ln|z|, harmonic except at 0
def pt(r, k, n): return r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n)
def lap(g, h=0.1): return (g(h, 0) + g(-h, 0) + g(0, h) + g(0, -h) - 4 * g(0, 0)) / h ** 2   # net bending at 0
def fx(v): return f"{0.0 if abs(v) < 5e-7 else v:.6f}"          # six decimals, no -0.000000

def avg(g, cx, cy, r, n=64):               # plain average of g at n equal steps round a circle
    return sum(g(cx + p[0], cy + p[1]) for p in (pt(r, k, n) for k in range(n))) / n

def cauchy(a, n=64):                       # (1/2 pi i) x loop sum of z^2/(z - a) dz round |z| = 1
    s = 0
    for k in range(n):
        z = complex(*pt(1, k, n))
        s += z * z / (z - a) * 1j * z * (2 * math.pi / n)
    return s / (2j * math.pi)

def ring(r, n=360):                        # highest and lowest film height on the circle |z| = r
    hs = [u(*pt(r, k, n)) for k in range(n)]
    return max(hs), min(hs)

def relax(start, N=10, sweeps=3000):       # grid film, step 1/N: each inside node -> its 4 neighbours' average
    inside = [(i, j) for i in range(-N, N + 1) for j in range(-N, N + 1) if i * i + j * j < N * N]
    g = {(i, j): u(i / N, j / N) for i in range(-N - 1, N + 2) for j in range(-N - 1, N + 2)}
    g.update({p: start for p in inside})
    for _ in range(sweeps):
        for i, j in inside:
            g[i, j] = (g[i + 1, j] + g[i - 1, j] + g[i, j + 1] + g[i, j - 1]) / 4
    frame = [g[q] for i, j in inside for q in ((i+1, j), (i-1, j), (i, j+1), (i, j-1)) if q not in set(inside)]
    return g, inside, frame

a = complex(0.3, 0.4)
print("figure, 1 unit = the 10 cm frame radius, heights in mm; 80 units per 1: centre (180, 120), frame radius 80, a = 0.3 + 0.4i at (204, 88), circle round a radius 32")
print(f"round 0, radii 0.25, 0.5, 1: averages {', '.join(fx(avg(u, 0, 0, r)) for r in (0.25, 0.5, 1))}; u(0) = {fx(u(0, 0))}")
print(f"a = 0.3 + 0.4i: u(a) = {fx(u(0.3, 0.4))}; average on radius 0.4 = {fx(avg(u, 0.3, 0.4, 0.4))}")
c = cauchy(a)
print(f"Cauchy loop sum of z^2/(z - a), 64 points = {fx(c.real)} + {fx(c.imag)}i; a^2 = {fx((a*a).real)} + {fx((a*a).imag)}i")
for r in (0, 0.25, 0.5, 0.75, 1):
    hi, lo = ring(r)
    print(f"circle r = {r}: highest {fx(hi)}, lowest {fx(lo)}; r^2 = {fx(r * r)}")
g0, inside, frame = relax(0.0)
g5 = relax(5.0)[0]
print(f"grid film, step 0.1: centre {fx(g0[0, 0])}, at 0.5 {fx(g0[5, 0])}, highest inside node {fx(max(g0[p] for p in inside))}, frame nodes {fx(min(frame))} to {fx(max(frame))}")
gap = max(abs(g0[p] - g5[p]) for p in inside)
print(f"grid films from starts 0 and 5: largest gap {fx(gap)}")
print(f"Laplacian at 0 by differences: film {fx(lap(u))}, pushed sheet {fx(lap(pushed))}")
print(f"mistake 1, sheet pushed from below: centre {fx(pushed(0, 0))}, frame highest {fx(ring(1)[0])}, rim average {fx(avg(pushed, 0, 0, 1))}")
print(f"mistake 2, half-plane x > 0, films 0 and x, both 0 on the edge x = 0: at z = 1 they give {fx(0)} and {fx(1)}")
print(f"mistake 3, ln|z| round 0.5, radius 1, the hole at 0 inside: average {fx(avg(lnmod, 0.5, 0, 1))}, not ln 0.5 = {fx(math.log(0.5))}")
assert all(abs(avg(u, x, y, r) - u(x, y)) < 1e-12 for x, y, r in ((0, 0, 1), (0.3, 0.4, 0.4), (0.5, 0, 0.3)))
assert abs(c - a * a) < 1e-12                                    # Cauchy road: F(a) = a^2
assert all(abs(ring(r)[0] - r * r) < 1e-12 and abs(ring(r)[1] + r * r) < 1e-12 for r in (0.25, 0.5, 0.75, 1))
assert gap < 1e-9 and all(abs(g0[i, j] - u(i / 10, j / 10)) < 1e-9 for i, j in inside)   # one film only
print("ALL CHECKS PASS")
