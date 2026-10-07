# Laplace's equation on a 1 m square plate: top edge 100 C, other three 0 C.
# Road one relaxes a grid until each point is the average of its neighbours;
# road two is the rectangle card's sine series; the centre's third road is symmetry.
from math import pi, sin, cos, exp
N, F = 40, 100.0                     # grid intervals per metre; heat source, C per m^2

def relax(n, top, src, start):       # sweep u = neighbour average + h^2 src / 4 until settled
    h, w = 1 / n, 2 / (1 + sin(pi / n))                  # w: over-relaxation factor
    u = [[start] * (n + 1) for _ in range(n + 1)]        # u[i][j] is u at x = i h, y = j h
    for i in range(n + 1):
        u[i][0], u[0][i], u[n][i], u[i][n] = 0.0, 0.0, 0.0, top
    while True:
        big = 0.0
        for i in range(1, n):
            for j in range(1, n):
                new = (u[i+1][j] + u[i-1][j] + u[i][j+1] + u[i][j-1] + h * h * src) / 4
                big = max(big, abs(new - u[i][j]))
                u[i][j] += w * (new - u[i][j])
        if big < 1e-12:
            return u

def plate(x, y):                     # sum over odd n of 400/(n pi) sin(n pi x) sinh(n pi y)/sinh(n pi)
    return sum(400 / (n * pi) * sin(n * pi * x) * (exp(n * pi * (y - 1)) - exp(-n * pi * (y + 1)))
               / (1 - exp(-2 * n * pi)) for n in range(1, 800, 2))

def heated(x, y):                    # edges 0 C, source F: a parabola minus a harmonic correction
    return F * (x * (1 - x) / 2 - sum(4 / (n * pi) ** 3 * sin(n * pi * x) * (exp(n * pi * (y - 1))
               + exp(-n * pi * y)) / (1 + exp(-n * pi)) for n in range(1, 200, 2)))
def ring(g, x, y, r, m=256):         # average of g round a circle of radius r, m points
    return sum(g(x + r * cos(2 * pi * k / m), y + r * sin(2 * pi * k / m)) for k in range(m)) / m

A, B = relax(N, 100.0, 0.0, 0.0), relax(N, 100.0, 0.0, 100.0)   # two different first guesses
inner = [A[i][j] for i in range(1, N) for j in range(1, N)]
line_s = [plate(0.5, k / 10) if k < 10 else 100.0 for k in range(11)]
line_g = [A[N // 2][4 * k] for k in range(11)]
p20, p40, pex = relax(20, 0.0, F, 0.0)[10][10], relax(40, 0.0, F, 0.0)[20][20], heated(0.5, 0.5)
m1, m2, m3 = ring(plate, 0.5, 0.5, 0.25), ring(plate, 0.5, 0.75, 0.2), ring(heated, 0.5, 0.5, 0.25)
f = lambda v: ", ".join(f"{t:.2f}" for t in v)
print(f"plate centre: symmetry 25, series {plate(0.5, 0.5):.6f}, grid h=1/40 {A[20][20]:.6f}")
print(f"one-point grids h=1/2: plate (100+0+0+0)/4 = {relax(2, 100.0, 0.0, 0.0)[1][1]:.2f}, "
      f"heated 0 + (1/4)(100)/4 = {relax(2, 0.0, F, 0.0)[1][1]:.2f}")
print(f"centre line x=0.5, y=0,0.1..1, series: {f(line_s)}")
print(f"centre line x=0.5, y=0,0.1..1, grid:   {f(line_g)}")
print(f"interior grid max {max(inner):.4f} at (0.5, 0.975), min {min(inner):.4f} at (0.025, 0.025); edges 0 and 100")
gap = max(abs(a - b) for ra, rb in zip(A, B) for a, b in zip(ra, rb))
print(f"uniqueness: first guesses 0 and 100 settle within 1e-9 of each other: {'yes' if gap < 1e-9 else 'no'}")
print(f"mean value at (0.5, 0.5), r=0.25: ring {m1:.6f}, point {plate(0.5, 0.5):.6f}")
print(f"mean value at (0.5, 0.75), r=0.2: ring {m2:.6f}, point {plate(0.5, 0.75):.6f}")
print(f"Poisson, edges 0, source {F:.0f}: centre series {pex:.4f}, grid h=1/20 {p20:.4f}, h=1/40 {p40:.4f}")
print(f"Poisson grid error: h=1/20 {pex - p20:.5f}, h=1/40 {pex - p40:.5f}, ratio {(pex - p20) / (pex - p40):.2f}")
print(f"Poisson ring r=0.25: {m3:.4f}; centre minus F r^2/4 = {pex - F * 0.25 ** 2 / 4:.4f}")
print(f"breaks 1, a source: centre {pex:.4f} C, above every edge (all 0 C)")
print(f"breaks 2, half-plane y>0 with edge 0: u=y has neighbour average {(2 + 2 + 2.1 + 1.9) / 4:.1f} = u at (0.5, 2); u=0 fits too")
print(f"breaks 3, edge average at (0.5, 0.75): 25.00, true {plate(0.5, 0.75):.2f}")
print("figure, 160 per metre; plate (100,50)-(260,210); centre (180,130), ring r=0.25 -> radius 40; point (0.5,0.75) -> (180,90)")
assert abs(plate(0.5, 0.5) - 25) < 1e-9                                  # series against symmetry
assert max(abs(a - b) for a, b in zip(line_s, line_g)) < 0.05 and max(inner) < 100
assert abs(m1 - 25) < 1e-9 and abs(m2 - plate(0.5, 0.75)) < 1e-9          # mean value, two circles
assert 3.8 < (pex - p20) / (pex - p40) < 4.2 and abs(m3 - (pex - F * 0.25 ** 2 / 4)) < 1e-9
print("ALL CHECKS PASS")
