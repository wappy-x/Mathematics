# Maximum principles on a 1 m square steel plate, temperatures as rises above the 20 C room (K).
# Scene 1: top bar 80 K, other bars 0 K, faces cooled (c = 40 per m^2) or insulated (c = 0).
# Scene 2: rim 0 K, heater inside f = 100 K per m^2, bounded by comparison with barriers.
# Roads: sine series, a grid swept to its neighbour average, symmetry, and hand barriers.
from math import pi, sin, sqrt, exp
F, C, TOP = 5000 / 50, 2 * 10 / (50 * 0.01), 80.0    # f = heat / conductivity; c = 2 air / (k t)

def rim(x, y, c, top=TOP):          # top bar `top`, others 0: sum of sin(n pi x) sinh(b y)/sinh(b)
    return sum(4 * top / (n * pi) * sin(n * pi * x) * (exp(b * (y - 1)) - exp(-b * (y + 1)))
               / (1 - exp(-2 * b)) for n in range(1, 800, 2) for b in [sqrt((n * pi) ** 2 + c)])

def heated(x, y, c):                 # rim 0, source F: each sine mode in x solved exactly in y
    return sum(4 * F / (m * pi) / k ** 2 * sin(m * pi * x) * (1 - (exp(k * (y - 1)) + exp(-k * y))
               / (1 + exp(-k))) for m in range(1, 400, 2) for k in [sqrt((m * pi) ** 2 + c)])

def cube(N):                         # unit cube, rim 0, source F: double sine series at the centre
    s = 0.0
    for m in range(1, N, 2):
        for n in range(1, N, 2):
            k = pi * sqrt(m * m + n * n)
            s += 16 * F / (pi * pi * m * n * k * k) * (1 - 2 * exp(-k / 2) / (1 + exp(-k))) \
                * (-1) ** ((m + n) // 2 - 1)
    return s

def relax(n, top, src, c):           # sweep u = (neighbours + h^2 src) / (4 + h^2 c) until settled
    h, w = 1 / n, 2 / (1 + sin(pi / n))
    u = [[0.0] * (n + 1) for _ in range(n + 1)]          # u[i][j] at x = i h, y = j h
    for i in range(n + 1):
        u[i][n] = top
    while True:
        big = 0.0
        for i in range(1, n):
            for j in range(1, n):
                new = (u[i+1][j] + u[i-1][j] + u[i][j+1] + u[i][j-1] + h * h * src) / (4 + h * h * c)
                big = max(big, abs(new - u[i][j]))
                u[i][j] += w * (new - u[i][j])
        if big < 1e-11:
            return u

def relax3(n):                       # the cube on a grid: six neighbours
    h, w = 1 / n, 2 / (1 + sin(pi / n))
    u = [[[0.0] * (n + 1) for _ in range(n + 1)] for _ in range(n + 1)]
    while True:
        big = 0.0
        for i in range(1, n):
            for j in range(1, n):
                for k in range(1, n):
                    new = (u[i+1][j][k] + u[i-1][j][k] + u[i][j+1][k] + u[i][j-1][k]
                           + u[i][j][k+1] + u[i][j][k-1] + h * h * F) / 6
                    big = max(big, abs(new - u[i][j][k]))
                    u[i][j][k] += w * (new - u[i][j][k])
        if big < 1e-11:
            return u[n // 2][n // 2][n // 2]

N = 40
G0, GC, GH = relax(N, TOP, 0, 0), relax(N, TOP, 0, C), relax(N, 0, F, 0)
pts = [(i, j) for i in range(1, N) for j in range(1, N)]
f2 = lambda v: ", ".join(f"{t:.2f}" for t in v)
low = lambda x, y: max(0.0, F * (0.25 - (x - 0.5) ** 2 - (y - 0.5) ** 2) / 4)   # inner-disc bowl
upp = lambda x, y: F * x * (1 - x) / 2                                          # strip barrier
print(f"setup: c = 2*10/(50*0.01) = {C:.2f} per m^2; f = 5000/50 = {F:.2f} K per m^2")
print(f"scene 1 centre, insulated: four turns 80/4 = {TOP / 4:.4f}, series {rim(.5, .5, 0):.4f}, grid {G0[20][20]:.4f}")
print(f"scene 1 centre, cooled c=40: series {rim(.5, .5, C):.4f}, grid {GC[20][20]:.4f}")
print(f"midline x=0.5, y=0,0.1..1, insulated series: {f2([rim(.5, k / 10, 0) for k in range(10)] + [TOP])}")
print(f"midline x=0.5, y=0,0.1..1, cooled series:    {f2([rim(.5, k / 10, C) for k in range(10)] + [TOP])}")
print(f"midline x=0.5, y=0,0.1..1, cooled grid:      {f2([GC[20][4 * k] for k in range(11)])}")
for name, g in (("insulated", G0), ("cooled", GC)):
    i, j = max(pts, key=lambda p: g[p[0]][p[1]])
    print(f"{name} grid: interior max {g[i][j]:.4f} at ({i / N:.3f}, {j / N:.3f}), "
          f"min {min(g[a][b] for a, b in pts):.4f}; rim 0 to 80")
gap = min(G0[i][j] - GC[i][j] for i, j in pts)
print(f"comparison: insulated minus cooled at every grid point >= 0: {'yes' if gap >= 0 else 'no'}")
d0, dc = rim(.5, .5, 0, 80.5) - rim(.5, .5, 0), rim(.5, .5, C, 80.5) - rim(.5, .5, C)
print(f"stability: top bar 80 -> 80.5 moves the centre {d0:.4f} (insulated), {dc:.4f} (cooled), cap 0.5")
p20, p40, pex = relax(20, 0, F, 0)[10][10], GH[20][20], heated(.5, .5, 0)
print(f"scene 2 centre: series {pex:.4f}, grid h=1/20 {p20:.4f}, h=1/40 {p40:.4f}, error ratio {(pex - p20) / (pex - p40):.2f}")
print(f"scene 2 first omitted series term at the centre: {4 * F / (401 * pi) ** 3:.7f}")
print(f"barriers at the centre: strip 100*0.5*0.5/2 = {upp(.5, .5):.4f}, outer disc 100*(1/2)/4 = {F * 0.5 / 4:.4f}, "
      f"inner disc 100*0.25/4 = {low(.5, .5):.4f}")
print(f"midline y=0.5, x=0,0.1..1, lower bowl: {f2([low(k / 10, .5) for k in range(11)])}")
print(f"midline y=0.5, x=0,0.1..1, series:     {f2([heated(k / 10, .5, 0) for k in range(11)])}")
print(f"midline y=0.5, x=0,0.1..1, strip:      {f2([upp(k / 10, .5) for k in range(11)])}")
ok = all(low(i / N, j / N) <= GH[i][j] <= upp(i / N, j / N) for i, j in pts)
print(f"sandwich bowl <= u <= strip at all {len(pts)} grid points: {'yes' if ok else 'no'}; grid max {max(GH[i][j] for i, j in pts):.4f}")
pc = heated(.5, .5, C)
print(f"scene 2 cooled c=40: centre {pc:.4f}, below the insulated {pex:.4f}")
c100, c200, g10, g20 = cube(100), cube(200), relax3(10), relax3(20)
print(f"d=1 rod: bowl 100/8 = {F / 8:.4f}, exact {F * 0.25 / 2:.4f}, strip {F / 8:.4f}")
print(f"d=2 plate: bowl 100/16 = {F / 16:.4f}, exact {pex:.4f}, strip {F / 8:.4f}")
print(f"d=3 cube: bowl 100/24 = {F / 24:.4f}, exact {c200:.4f}, strip {F / 8:.4f}")
print(f"cube centre: series N=100 {c100:.6f}, N=200 {c200:.6f}; grid h=1/10 {g10:.4f}, h=1/20 {g20:.4f}, "
      f"error ratio {(c200 - g10) / (c200 - g20):.2f}")
zs, zg = 10 * C / F * heated(.5, .5, C), relax(N, 0, 10 * C, C)[20][20]   # u = -10 + z
print(f"cold frame at -10 K, cooled: centre series {zs - 10:.4f}, grid {zg - 10:.4f}; rim -10, room 0")
print(f"in C, room 20: scene 1 centre {20 + rim(.5, .5, C):.2f}, series 2.5 cm below the hot bar {20 + rim(.5, .975, C):.2f}; "
      f"scene 2 {20 + F / 16:.2f} <= {20 + pex:.2f} <= {20 + F / 8:.2f}; cold frame {30 + zs - 20:.2f}; heat 5000*0.01 = {50.0:.0f} W")
s, res = lambda x, y: 10 * sin(pi * x) * sin(pi * y), []
for e in (0.01, 0.005):
    dxx = (s(.3 + e, .6) - 2 * s(.3, .6) + s(.3 - e, .6)) / e ** 2
    dyy = (s(.3, .6 + e) - 2 * s(.3, .6) + s(.3, .6 - e)) / e ** 2
    res += [abs(dxx - dyy), abs(-dxx - dyy - 2 * pi * pi * s(.3, .6))]
    print(f"breaks residuals at (0.3, 0.6), step {e}: u_xx - u_yy {abs(dxx - dyy):.6f}, "
          f"-u_xx - u_yy - 2 pi^2 u {abs(-dxx - dyy - 2 * pi * pi * s(.3, .6)):.6f}")
print(f"breaks 1-2, u = 10 sin(pi x) sin(pi y): rim 0, centre {s(.5, .5):.4f} K, above every rim point")
print(f"breaks 3, heater inside: centre {pex:.4f} K above a 0 K rim; grid min {min(GH[i][j] for i, j in pts):.4f}")
print(f"breaks 4, inner bowl without the max(0, .) at a corner: {F * (0.25 - 0.5) / 4:.4f} K, below the rim's 0 K")
assert abs(rim(.5, .5, 0) - TOP / 4) < 1e-9 and abs(G0[20][20] - TOP / 4) < 1e-6   # series, grid, symmetry
assert max(abs(rim(.5, k / 10, C) - GC[20][4 * k]) for k in range(10)) < 0.1         # two roads, cooled
assert gap >= 0 and max(GC[i][j] for i, j in pts) < TOP and min(GC[i][j] for i, j in pts) > 0
assert 3.8 < (pex - p20) / (pex - p40) < 4.2 and ok and F / 16 < pex < F / 8 and pc < pex
assert abs(c200 - g20) < 0.03 and 3.8 < (c200 - g10) / (c200 - g20) < 4.2 and F / 24 < c200 < F / 8
assert abs(zs - zg) < 0.01 and -10 < zs - 10 < 0
assert 0 < d0 <= 0.5 and 0 < dc < d0 and res[0] < 1e-6 and 3.9 < res[1] / res[3] < 4.1
print("ALL CHECKS PASS")
