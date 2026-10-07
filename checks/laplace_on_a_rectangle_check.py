# Laplace on a rectangle -- the check behind the card.  Standard library only.  A 1 m square
# plate, top edge at 100 C, the rest at 0 C: u = sum over odd n of (400/(n pi)) sin(n pi x)
# sinh(n pi y)/sinh(n pi).  Road one: that series.  Road two: a grid of neighbour means, no sines.
# Road three: four turned copies add to 100 C.  Second case: edges 100, 60, 20, 0 C (T, R, B, L).
import math; PI = math.pi
def sinh_ratio(n, y, s=-1):         # sinh(n pi y)/sinh(n pi) without overflow; s = +1 gives the cosh mistake
    return math.exp(n * PI * (y - 1)) * (1 + s * math.exp(-2 * n * PI * y)) / (1 + s * math.exp(-2 * n * PI))
cosh_ratio = lambda n, y: sinh_ratio(n, y, 1)
def top(x, y, terms=0, shape=sinh_ratio):   # one hot edge at 100 C; terms counts odd n
    terms = terms or (100000 if y >= 1 else int(40 / (PI * (1 - y))) + 2)
    return sum(400 / (n * PI) * math.sin(n * PI * x) * shape(n, y) for n in range(1, 2 * terms, 2))
def plate(x, y, t, r, b, l): return (t * top(x, y) + r * top(y, x) + b * top(x, 1 - y) + l * top(y, 1 - x)) / 100
def simpson(f, m=2000): return sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(i / m) for i in range(m + 1)) / (3 * m)
def grid(N, t, r, b, l):            # u[j][i] at x = i/N, y = j/N; each point relaxed to its neighbours' mean
    u = [[0.0] * (N + 1) for _ in range(N + 1)]
    for k in range(1, N):
        u[N][k], u[k][N], u[0][k], u[k][0] = t, r, b, l
    w, change = 2 / (1 + math.sin(PI / N)), 1.0     # over-relaxation only speeds the sweeps up
    while change > 1e-11:
        change = 0.0
        for j in range(1, N):
            for i in range(1, N):
                d = (u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4 - u[j][i]
                change, u[j][i] = max(change, abs(d)), u[j][i] + w * d
    return u
def isotherm(x, c, lo=0.0, hi=1.0): # the height y where the one-edge plate reads c C, by bisection
    for _ in range(50): lo, hi = (lo, (lo + hi) / 2) if top(x, (lo + hi) / 2) > c else ((lo + hi) / 2, hi)
    return lo
f4 = lambda v: " ".join(f"{x:.4f}" for x in v)
bf = [400 / (n * PI) for n in (1, 3, 5, 7)]
bs = [simpson(lambda x: 200 * math.sin(n * PI * x)) for n in (1, 3, 5, 7)]
terms = [400 / (n * PI) * math.sin(n * PI / 2) * sinh_ratio(n, 0.5) for n in (1, 3, 5, 7)]
centre, turned = top(0.5, 0.5), [top(0.3, 0.8), top(0.8, 0.3), top(0.3, 0.2), top(0.8, 0.7)]
Ns, exact = (20, 40, 80), top(0.5, 0.75)
grids = {N: grid(N, 100, 0, 0, 0) for N in Ns}

errs = [abs(grids[N][3 * N // 4][N // 2] - exact) for N in Ns]
case2, grid2 = plate(0.25, 0.75, 100, 60, 20, 0), grid(80, 100, 60, 20, 0)[60][20]
print("sine coefficients, n = 1 3 5 7: formula", f4(bf), " Simpson", f4(bs))
print("centre (0.5, 0.5), n = 1 3 5 7: sinh ratios", " ".join(f"{sinh_ratio(n, 0.5):.6f}" for n in (1, 3, 5, 7)), " terms", f4(terms), f" full series {centre:.4f} C")
print("hot edge (0.5, 1), first 1 2 3 odd modes:", " ".join(f"{top(0.5, 1, k):.2f}" for k in (1, 2, 3)), f" full {top(0.5, 1):.2f} C")
print("four turned copies at (0.3, 0.8), top right bottom left:", f4(turned), f" sum {sum(turned):.4f} C")
print("grid (0.5, 0.75), N = 20 40 80:", f4([grids[N][3 * N // 4][N // 2] for N in Ns]), f" series {exact:.4f} C")
print("grid error:", " ".join(f"{e:.5f}" for e in errs), " ratios", " ".join(f"{errs[i] / errs[i + 1]:.2f}" for i in range(2)))
print("grid centre, N = 20 40 80:", f4([grids[N][N // 2][N // 2] for N in Ns]))
print("figure, y (m):         ", " ".join(f"{j / 10:.1f}" for j in range(11)))
print("figure, series x = 0.5:", " ".join(f"{top(0.5, j / 10):.2f}" for j in range(11)))
print("figure, grid N = 20:   ", " ".join(f"{grids[20][2 * j][10]:.2f}" for j in range(11)))
for c in (25, 50, 75):
    print(f"figure, {c} C isotherm, svg:", " ".join(f"{60 + 20 * i},{220 - 200 * isotherm(i / 10, c):.1f}" for i in range(1, 10)))
print(f"second case, edges 100 60 20 0 C: centre {plate(0.5, 0.5, 100, 60, 20, 0):.4f} C; (0.25, 0.75) series {case2:.4f}, grid N = 80 {grid2:.4f}")
print(f"mistake, cosh for sinh: centre {top(0.5, 0.5, 50, cosh_ratio):.2f} C, bottom edge middle {top(0.5, 0, 50, cosh_ratio):.2f} C, not 0")
raw = [400 / (n * PI) * math.sin(n * PI / 2) * (math.exp(n * PI / 2) - math.exp(-n * PI / 2)) / 2 for n in (1, 3, 5)]
print("mistake, no division by sinh(n pi): centre partial sums", " ".join(f"{sum(raw[:k]):.1f}" for k in (1, 2, 3)))
print(f"mistake, quarter rule off-centre: 25 C claimed at (0.5, 0.75), series gives {exact:.2f} C")
assert max(abs(p - q) for p, q in zip(bf, bs)) < 1e-6                 # closed-form coefficients against an integral
assert abs(centre - 25) < 1e-9 and abs(grids[80][40][40] - 25) < 1e-6  # series and grid meet the symmetry count
assert abs(sum(turned) - 100) < 1e-9                                  # four turned copies make a 100 C plate
assert errs[-1] < 0.01 and all(3.5 < errs[i] / errs[i + 1] < 4.5 for i in range(2)) and abs(case2 - grid2) < 0.01
print("ALL CHECKS PASS")
