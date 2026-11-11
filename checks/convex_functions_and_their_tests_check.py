# Convex functions and their tests -- the check behind the card.  Standard library only.
# Bitterness B on a 0-10 tasting scale.  t = roast minutes past first crack (0 to 3),
# w = robusta share of the blend (0 to 0.5), k = how fast robusta's bitterness grows with
# roast time (1 in the model).  Three tests -- chord, tangent, curvature -- run on
# a grid of 42 recipes, for B and for two curves that fail; each has an independent road.
from math import exp, sqrt, log

def B(t, w, k=1.0):    return 1 + exp(t / 2) + k * t * w + 4 * w * w
def grad(t, w, k=1.0): return (exp(t / 2) / 2 + k * w, k * t + 8 * w)   # slopes, by hand
def hess(t, w, k=1.0): return ((exp(t / 2) / 4, k), (k, 8.0))           # curvatures, by hand
def S(t):              return 8 / (1 + exp(2 - t))                      # bitterness that levels off

def num_grad(f, p, h=1e-5):                       # slopes again, by central differences
    return tuple((f(p[0] + h * (i == 0), p[1] + h * (i == 1)) -
                  f(p[0] - h * (i == 0), p[1] - h * (i == 1))) / (2 * h) for i in range(2))

def num_hess(f, p, h=1e-3):                       # curvatures again, by second differences
    at = lambda a, b: f(p[0] + a * h, p[1] + b * h)
    hxy = (at(1, 1) - at(1, -1) - at(-1, 1) + at(-1, -1)) / (4 * h * h)
    return ((at(1, 0) - 2 * at(0, 0) + at(-1, 0)) / h ** 2, hxy), (hxy, (at(0, 1) - 2 * at(0, 0) + at(0, -1)) / h ** 2)

def eig(H):                                       # eigenvalues of a symmetric 2 x 2, smaller first
    tr, gap = H[0][0] + H[1][1], sqrt((H[0][0] - H[1][1]) ** 2 + 4 * H[0][1] ** 2)
    return (tr - gap) / 2, (tr + gap) / 2

dot = lambda u, v: u[0] * v[0] + u[1] * v[1]
mix = lambda th, x, y: (th * x[0] + (1 - th) * y[0], th * x[1] + (1 - th) * y[1])
GRID = [(0.5 * i, 0.1 * j) for i in range(7) for j in range(6)]
PAIRS = [(x, y) for n, x in enumerate(GRID) for y in GRID[n + 1:]]

def three_tests(f, g, pairs=PAIRS):              # least slack of each test over the grid
    chord = min(th * f(*x) + (1 - th) * f(*y) - f(*mix(th, x, y)) for x, y in pairs for th in (0.25, 0.5, 0.75))
    tang = min(f(*y) - f(*x) - dot(g(*x), (y[0] - x[0], y[1] - x[1])) for x in GRID for y in GRID if x != y)
    return chord, tang, min(eig(num_hess(f, p))[0] for p in GRID)

A, C, M, F = (1.0, 0.4), (3.0, 0.1), (2.0, 0.25), (3.0, 0.4)
bA, bC, bM = B(*A), B(*C), B(*M)
gA, gC, d = grad(*A), grad(*C), (C[0] - A[0], C[1] - A[1])
tanC, floorF = bA + dot(gA, d), bA + dot(gA, (F[0] - A[0], F[1] - A[1]))
HA, nA = hess(*A), num_hess(B, A)
quot = [(B(*mix(1 - s, A, C)) - bA) / s for s in (0.5, 0.1, 0.01, 0.001)]
mono = dot((gC[0] - gA[0], gC[1] - gA[1]), d)
mu, L = eig(hess(0, 0))[0], eig(hess(3, 0))[1]                 # Hessian rises with t only
eg = [eig(num_hess(B, p)) for p in GRID]
mu_g, L_g = min(e[0] for e in eg), max(e[1] for e in eg)
lo, hi = tanC + mu / 2 * dot(d, d), tanC + L / 2 * dot(d, d)
okB = three_tests(B, grad)
G, gG = (lambda t, w: B(t, w, 4.0)), (lambda t, w: grad(t, w, 4.0))
badG = three_tests(G, gG)
axisG = three_tests(G, gG, [(x, y) for x, y in PAIRS if x[0] == y[0] or x[1] == y[1]])[0]
HG = hess(1, 0, 4.0)
s1, s3 = S(1), S(3)
d1, d3 = s1 * (8 - s1) / 8, s3 * (8 - s3) / 8                   # S' = S(8 - S)/8
c1, c3 = d1 * (8 - 2 * s1) / 8, d3 * (8 - 2 * s3) / 8           # S'' = S'(8 - 2S)/8
n3 = (S(3.001) - 2 * s3 + S(2.999)) / 1e-6
tanS1 = s3 + d3 * (1 - 3)
th = [0.1 * i for i in range(11)]
print("model: B(t, w) = 1 + e^(t/2) + t*w + 4*w^2; t in [0, 3] min, w in [0, 0.5]")
print(f"prices: arabica 9.00, robusta 5.00 pounds/kg; e^(1/2) = {exp(0.5):.4f}, e^1 = {exp(1):.4f}, e^(3/2) = {exp(1.5):.4f}")
for name, p, b in (("A", A, bA), ("C", C, bC), ("halfway", M, bM)):
    print(f"recipe {name} ({p[0]:.0f} min, {100 * p[1]:.0f}% robusta): B = {b:.4f}, cost {9 - 4 * p[1]:.2f} pounds/kg")
print(f"chord: average of A and C {(bA + bC) / 2:.4f}, halfway {bM:.4f}, gap {(bA + bC) / 2 - bM:.4f}")
print(f"slopes at A by formula ({gA[0]:.4f}, {gA[1]:.4f}); by central differences ({num_grad(B, A)[0]:.4f}, {num_grad(B, A)[1]:.4f})")
print(f"tangent at A predicts C: {bA:.4f} + {gA[0] * d[0]:.4f} + ({gA[1] * d[1]:.4f}) = {tanC:.4f}; true {bC:.4f}; gap {bC - tanC:.4f}")
print(f"tangent floor at (3 min, 40%): {floorF:.4f} > 6, out of spec untasted; true {B(*F):.4f}")
print(f"Hessian at A by formula [[{HA[0][0]:.4f}, {HA[0][1]:.4f}], [{HA[1][0]:.4f}, {HA[1][1]:.4f}]]"
      f"; by second differences [[{nA[0][0]:.4f}, {nA[0][1]:.4f}], [{nA[1][0]:.4f}, {nA[1][1]:.4f}]]")
print(f"at A: determinant {HA[0][0] * HA[1][1] - 1:.4f}, trace {HA[0][0] + 8:.4f}, eigenvalues {eig(HA)[0]:.4f} and {eig(HA)[1]:.4f}")
print(f"determinant 2e^(t/2) - 1 is at least {2 * exp(0) - 1:.4f} for t >= 0; turns negative below t = {-2 * log(2):.4f}")
print("step 1 quotients, s = 0.5, 0.1, 0.01, 0.001: " + ", ".join(f"{q:.4f}" for q in quot)
      + f"; limit {dot(gA, d):.4f}; ceiling {bC - bA:.4f}")
print(f"step 4 slopes at C ({gC[0]:.4f}, {gC[1]:.4f}); slope change along C - A: {mono:.4f}")
print(f"mu, least eigenvalue on the box (t = 0): formula {mu:.4f}, grid {mu_g:.4f}")
print(f"L, largest eigenvalue on the box (t = 3): formula {L:.4f}, grid {L_g:.4f}")
print(f"sandwich for C: {tanC:.4f} + {mu / 2 * dot(d, d):.4f} = {lo:.4f} <= {bC:.4f} <= {hi:.4f}")
print(f"grid: {len(GRID)} recipes, {len(PAIRS)} pairs x 3 weights, {len(GRID) * (len(GRID) - 1)} ordered pairs")
print("B, least slack: chord {:.6f}, tangent {:.6f}, least eigenvalue {:.4f}".format(*okB))
print("k = 4, least slack: chord {:.4f}, tangent {:.4f}, least eigenvalue {:.4f}".format(*badG))
print(f"k = 4, chords along the axes only: least slack {axisG:.6f}; diagonal at t = 1: {HG[0][0]:.4f} and {HG[1][1]:.4f}; determinant {HG[0][0] * 8 - 16:.4f}")
print(f"k = 4 chord: (0 min, 50%) {G(0, 0.5):.4f}, (2 min, 0%) {G(2, 0):.4f}, average {(G(0, 0.5) + G(2, 0)) / 2:.4f}; halfway (1 min, 25%) {G(1, 0.25):.4f}")
print(f"levelling curve: S(1) = {s1:.4f}, S(3) = {s3:.4f}, slope at 3 {d3:.4f}; tangent at 3 claims S(1) >= {tanS1:.4f}")
print(f"levelling curve: S''(1) = {c1:.4f}, S''(3) = {c3:.4f}, by second differences {n3:.4f}")
print(f"try: k = 1.5, least eigenvalue at t = 0: {eig(hess(0, 0, 1.5))[0]:.4f}; switch-off k = {sqrt(2):.4f}")
print(f"try: t = -2, determinant {2 * exp(-1) - 1:.4f}, least eigenvalue {eig(hess(-2, 0))[0]:.4f}")
print(f"try: tangent at C predicts A: {bC + dot(gC, (-d[0], -d[1])):.4f}; true {bA:.4f}")
print("chart theta: " + ", ".join(f"{x:.1f}" for x in th))
print("chart B from A to C: " + ", ".join(f"{B(*mix(1 - x, A, C)):.2f}" for x in th))
print("chart chord: " + ", ".join(f"{(1 - x) * bA + x * bC:.2f}" for x in th))
print("chart tangent at A: " + ", ".join(f"{bA + x * dot(gA, d):.2f}" for x in th))
assert all(abs(u - v) < 1e-6 for p in GRID for u, v in zip(grad(*p), num_grad(B, p)))       # slopes two ways
assert all(abs(hess(*p)[i][j] - num_hess(B, p)[i][j]) < 1e-4 for p in GRID for i in range(2) for j in range(2))
assert min(okB) > 0 and max(badG) < 0 and axisG > 0                    # three tests agree, both ways
assert tanC < bC and abs(quot[-1] - dot(gA, d)) < 1e-2 and max(quot) <= bC - bA and mono > 0
assert abs(mu - mu_g) < 1e-5 and abs(L - L_g) < 1e-5 and lo <= bC <= hi   # mu and L two ways
assert tanS1 > s1 and c1 > 0 > c3 and abs(n3 - c3) < 1e-5              # the levelling curve fails
assert abs(tanS1 - (s3 - (S(3 + 1e-5) - S(3 - 1e-5)) / 1e-5)) < 1e-6    # its tangent value two ways
assert abs(tanC - bA - (B(*mix(1 - 1e-5, A, C)) - B(*mix(1 + 1e-5, A, C))) / 2e-5) < 1e-6   # tangent at A two ways
mats = [HA, hess(0, 0), hess(3, 0), hess(0, 0, 1.5), hess(-2, 0)] + [num_hess(f, p) for f in (B, G) for p in GRID]
assert all(l1 <= l2 and abs(l1 + l2 - H[0][0] - H[1][1]) < 1e-9 and abs(l1 * l2 - H[0][0] * H[1][1] + H[0][1] * H[1][0]) < 1e-9
           for H in mats for l1, l2 in [eig(H)])   # every eigenvalue pair: sum = trace, product = determinant
print("ALL CHECKS PASS")
