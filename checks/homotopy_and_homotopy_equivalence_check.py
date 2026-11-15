# Homotopy and homotopy equivalence -- the check behind the card.  Standard library only.
# A lamp post is the disc of radius 0.1 m round (0, 0); the owner stands at (2, 0).
# A walk is a loop s -> point, s in [0, 1]; a homotopy H(s, t) is one walk per frame t.
from fractions import Fraction as F
from math import atan2, cos, pi, sin, sqrt

N, POST, U = 360, 0.1, (cos(1.0), sin(1.0))       # samples per walk; post radius; ray direction

def wound(k):                                      # k turns round the post on the 2 m ring
    return lambda s: (2 * cos(2 * pi * k * s), 2 * sin(2 * pi * k * s))
def bench(s):                                      # a 1 m circle round a bench at (3, 0)
    return (3 - cos(2 * pi * s), -sin(2 * pi * s))
def phi(s): return 2 * s if s <= 0.5 else 2 - 2 * s   # once round, then back the same way
def there_back(s): return wound(1)(phi(s))

def pts(f): return [f(j / N) for j in range(N)]
def closest(p): return min(sqrt(x * x + y * y) for x, y in p)
def wind_angle(p):                                 # road 1: add the turns between neighbours
    tot = 0.0
    for (x0, y0), (x1, y1) in zip(p, p[1:] + p[:1]):
        tot += atan2(x0 * y1 - y0 * x1, x0 * x1 + y0 * y1)
    return round(tot / (2 * pi))
def wind_ray(p):                                   # road 2: signed crossings of a ray from the post
    n = 0
    for (x0, y0), (x1, y1) in zip(p, p[1:] + p[:1]):
        c0, c1 = U[0] * y0 - U[1] * x0, U[0] * y1 - U[1] * x1
        if (c0 < 0) != (c1 < 0):
            a = c0 / (c0 - c1)
            if (x0 + a * (x1 - x0)) * U[0] + (y0 + a * (y1 - y0)) * U[1] > 0:
                n += 1 if c0 < 0 else -1
    return n
def frame(H, t): return pts(lambda s: H(s, t))
def straight(f):                                   # slide every point straight to the owner
    return lambda s, t: ((1 - t) * f(s)[0] + 2 * t, (1 - t) * f(s)[1])
def report(H):                                     # closest approach and winding, frame by frame
    out = []
    for j in range(11):
        p = frame(H, j / 10)
        d = closest(p)
        out.append((d, None if d <= POST else wind_angle(p), None if d <= POST else wind_ray(p)))
    return out
def w(v): return "hits post" if v is None else f"winding {v:2d}"

walks = [("wound once", wound(1)), ("wound the other way", wound(-1)),
         ("round the bench", bench), ("round, then back", there_back)]
print(f"post radius {POST} m at (0, 0); owner at (2, 0); {N} samples per walk")
wind = {}
for name, f in walks:
    p = pts(f)
    wind[name] = (wind_angle(p), wind_ray(p))
    print(f"{name:20s} closest {closest(p):.6f} m, winding by angle sum {wind[name][0]:2d}, by ray {wind[name][1]:2d}")
sb, sw = report(straight(bench)), report(straight(wound(1)))
print("straight slide to the owner, frame by frame:")
for j in range(11):
    print(f"t={j / 10:.1f}  bench {sb[j][0]:.6f} m {w(sb[j][1])}  |  wound once {sw[j][0]:.6f} m {w(sw[j][1])}")
mid = straight(wound(1))(0.5, 0.5)
print(f"wound once, gamma(1/2) = ({wound(1)(0.5)[0]:.6f}, {abs(wound(1)(0.5)[1]):.6f}); H(1/2, 1/2) = ({abs(mid[0]):.6f}, {abs(mid[1]):.6f}): the straight slide crosses the post")
tight = report(lambda s, t: ((1 - 0.75 * t) * wound(1)(s)[0], (1 - 0.75 * t) * wound(1)(s)[1]))
print(f"pull the wound lead tight, radius 2 -> 0.5 m: windings {[r[1] for r in tight]}, closest at t=1 {tight[10][0]:.6f} m")
undo = report(lambda s, t: wound(1)((1 - t) * phi(s)))
print(f"round-then-back, unwind the angle: windings {[r[1] for r in undo]}, closest {min(r[0] for r in undo):.6f} m")
end = frame(lambda s, t: wound(1)((1 - t) * phi(s)), 1.0)
print(f"  last frame stays at the owner: {'yes' if max(abs(x - 2) + abs(y) for x, y in end) < 1e-12 else 'no'}")
jump = [wind_angle(frame(lambda s, t: wound(1)(s) if t < 0.5 else (2.0, 0.0), j / 10)) for j in range(11)]
print(f"mistake, frames that jump at t=0.5: windings {jump}, never nearer the post than 2 m")
# The lawn: a disc of radius 5 m.  Squash it to its centre with H(x, t) = (1 - t) x, exactly.
lawn = [(a, b) for a in range(-5, 6) for b in range(-5, 6) if a * a + b * b <= 25]
inside = all(((1 - F(j, 10)) ** 2) * (a * a + b * b) <= 25 for a, b in lawn for j in range(11))
print(f"lawn grid: {len(lawn)} points; every frame inside the lawn: {'yes' if inside else 'no'}; "
      f"(3, 4) at t=1/2 -> ({F(1, 2) * 3}, {F(1, 2) * 4}); at t=1 all at (0, 0)")
# The ground: the lawn minus the post.  Retract it onto the 2 m ring: H(x, t) = (1 - t) x + t * 2x/|x|.
ground = [(a / 10, b / 10) for a in range(-50, 51) for b in range(-50, 51) if 1 < a * a + b * b <= 2500]
worst, low = 0.0, 9.0
for x, y in ground:
    r = sqrt(x * x + y * y)
    for j in range(11):
        t = j / 10
        hx, hy = (1 - t) * x + t * 2 * x / r, (1 - t) * y + t * 2 * y / r
        d = sqrt(hx * hx + hy * hy)
        worst, low = max(worst, abs(d - ((1 - t) * r + 2 * t))), min(low, d)
ring = [(x, y) for x, y in ground if abs(x * x + y * y - 4) < 1e-9]
fixed = all(abs(2 * x / sqrt(x * x + y * y) - x) + abs(2 * y / sqrt(x * x + y * y) - y) < 1e-12 for x, y in ring)
hx, hy = 0.5 * 0.3 + 0.5 * 2 * 0.3 / 0.5, 0.5 * 0.4 + 0.5 * 2 * 0.4 / 0.5
print(f"ground grid: {len(ground)} points, 0.1 m apart; closest any frame comes to the post {low:.6f} m")
print(f"  distance (1-t)|x| + 2t by formula and directly agree to 1e-12: {'yes' if worst < 1e-12 else 'no'}")
print(f"  (0.3, 0.4), |x| = {sqrt(0.3 * 0.3 + 0.4 * 0.4):.6f}, at t=1/2 -> ({hx:.6f}, {hy:.6f}); at t=1 -> ({2 * 0.3 / 0.5:.6f}, {2 * 0.4 / 0.5:.6f})")
print(f"  {len(ring)} grid points on the ring, all left where they are: {'yes' if fixed else 'no'}")
# Cut test: a homeomorphism keeps the number of pieces left after removing two points.
def pieces_bfs(nodes, nbrs):
    seen, n = set(), 0
    for v in nodes:
        if v not in seen:
            n, todo = n + 1, [v]
            seen.add(v)
            while todo:
                for u in nbrs(todo.pop()):
                    if u in nodes and u not in seen:
                        seen.add(u)
                        todo.append(u)
    return n
def pieces_uf(nodes, nbrs):
    par = {v: v for v in nodes}
    def root(v):
        while par[v] != v:
            v = par[v]
        return v
    for v in nodes:
        for u in nbrs(v):
            if u in nodes:
                par[root(u)] = root(v)
    return len({root(v) for v in nodes})
ring12 = set(range(12)) - {0, 6}
step12 = lambda v: [(v + 1) % 12, (v - 1) % 12]
grid = {(a, b) for a in range(-5, 6) for b in range(-5, 6) if 4 <= a * a + b * b <= 25} - {(3, 0), (-3, 0)}
step4 = lambda v: [(v[0] + 1, v[1]), (v[0] - 1, v[1]), (v[0], v[1] + 1), (v[0], v[1] - 1)]
rc, gc = (pieces_bfs(ring12, step12), pieces_uf(ring12, step12)), (pieces_bfs(grid, step4), pieces_uf(grid, step4))
print(f"cut two opposite points: ring of 12 -> {rc[0]} pieces (union-find {rc[1]}); "
      f"ground model of {len(grid) + 2} -> {gc[0]} piece (union-find {gc[1]})")
print(f"mistake, one round trip: point -> ring -> point is the identity; ring -> point -> ring "
      f"winds {wind_angle(pts(lambda s: (2.0, 0.0)))}, the identity loop {wind['wound once'][0]}")
print(f"figure,post r=0.1,ring c=(0,0) r=2,frame c=(1,0) r=1,bench c=(3,0) r=1,frame c=(2.5,0) r=0.5")
assert [wind[n] for n, _ in walks] == [(1, 1), (-1, -1), (0, 0), (0, 0)]       # two roads agree
assert all(abs(sw[j][0] - abs(2 - 0.4 * j)) < 1e-9 for j in range(11))       # sampled = exact |2 - 4t|
assert [r[1] for r in sw] == [1] * 5 + [None] + [0] * 5 and all(r[1] == 0 for r in sb)
assert all(abs(r[0] - 2) < 1e-9 for r in sb)                                  # bench: 2 m in every frame
assert [r[1] for r in tight] == [1] * 11 and abs(tight[10][0] - 0.5) < 1e-12 and [r[1] for r in undo] == [0] * 11
assert inside and len(lawn) == 81 and worst < 1e-12 and fixed and len(ring) == 12
assert rc == (2, 2) and gc == (1, 1) and jump == [1] * 5 + [0] * 6
print("ALL CHECKS PASS")
