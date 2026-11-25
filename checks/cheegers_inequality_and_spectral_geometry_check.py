# Cheeger's inequality and spectral geometry -- the check behind the card.
# Standard library only.  Flat torus 2 pi by 2 pi, unit sphere, and a dumbbell:
# two unit spheres joined by a tube 1 m long and 0.1 m round.  Eigenvalues are
# counted against Weyl's law, then the first note is set against Cheeger's h.
import math
PI = math.pi

def isqrt(n):                                  # largest r with r*r <= n
    r = 0
    while (r + 1) * (r + 1) <= n:
        r += 1
    return r

def torus_brute(lam):                          # road one: every (m, n) pair
    return sum(1 for m in range(-20, 21) for n in range(-20, 21) if m * m + n * n <= lam)

def torus_rows(lam):                           # road two: one row of m at a time
    return sum(2 * isqrt(lam - m * m) + 1 for m in range(-isqrt(lam), isqrt(lam) + 1))

P = 1000000007                                 # a prime; rank mod P bounds rank over Q
def harmonic_dim(k):                           # kernel of the flat Laplacian, degree k -> k-2
    mons = lambda d: [(a, b, d - a - b) for a in range(d + 1) for b in range(d + 1 - a)]
    cols, rows = mons(k), mons(k - 2) if k >= 2 else []
    where = {m: i for i, m in enumerate(rows)}
    A = [[0] * len(cols) for _ in rows]
    for j, (a, b, c) in enumerate(cols):
        for e, (da, db, dc) in ((a, (2, 0, 0)), (b, (0, 2, 0)), (c, (0, 0, 2))):
            if e >= 2:
                A[where[(a - da, b - db, c - dc)]][j] += e * (e - 1)
    rk = lambda d: [math.factorial(d // 2) // (math.factorial(a // 2) * math.factorial(b // 2) * math.factorial(c // 2)) * (1 - (a | b | c) % 2) for a, b, c in mons(d)]
    assert k % 2 or k < 2 or [sum(u * v for u, v in zip(row, rk(k))) for row in A] == [k * (k + 1) * v for v in rk(k - 2)]  # radial road: Lap r^k = k(k+1) r^(k-2)
    rank, r = 0, 0
    for col in range(len(cols)):               # Gaussian elimination modulo P
        piv = next((i for i in range(r, len(rows)) if A[i][col] % P), None)
        if piv is None:
            continue
        A[r], A[piv] = A[piv], A[r]
        inv = pow(A[r][col], P - 2, P)
        for i in range(len(rows)):
            if i != r and A[i][col] % P:
                f = A[i][col] * inv % P
                A[i] = [(x - f * y) % P for x, y in zip(A[i], A[r])]
        r += 1
        rank += 1
    assert rank == len(rows)                   # full rank mod P forces full rank over Q
    return len(cols) - rank

def lap_ratio(k, ph=1.0, th=0.3, d=1e-4):      # card 08's chart formula, by differences
    Y = lambda p, t: math.sin(p) ** k * math.cos(k * t)
    y0 = Y(ph, th)
    dph = (math.sin(ph + d / 2) * (Y(ph + d, th) - y0) - math.sin(ph - d / 2) * (y0 - Y(ph - d, th))) / (d * d * math.sin(ph))
    dth = (Y(ph, th + d) - 2 * y0 + Y(ph, th - d)) / (d * d * math.sin(ph) ** 2)
    return (dph + dth) / y0

C = 0.1                                        # neck circumference, m
R0 = C / (2 * PI)                              # neck radius
ALPHA = math.asin(R0)
SJ, NECK = PI - ALPHA, 1.0                     # bell length along the metal; tube length
def sphere_r(s): return math.sin(s)
def bell_r(s):                                 # dumbbell profile: bell, tube, bell
    if s <= SJ: return math.sin(s)
    if s <= SJ + NECK: return R0
    return math.sin(2 * SJ + NECK - s)

def lam1_mesh(prof, length, N):                # rotational mesh, Sturm-count bisection
    h = length / N
    mass = [2 * PI * prof((i + 0.5) * h) * h for i in range(N)]
    cond = [2 * PI * prof((i + 1) * h) / h for i in range(N - 1)]
    diag = [((cond[i - 1] if i else 0) + (cond[i] if i < N - 1 else 0)) / mass[i] for i in range(N)]
    off2 = [cond[i] ** 2 / (mass[i] * mass[i + 1]) for i in range(N - 1)]
    def below(x):                              # eigenvalues under x, by Sylvester's law
        q, cnt = diag[0] - x, 0
        for i in range(N):
            if i:
                q = diag[i] - x - off2[i - 1] / (q if q != 0 else 1e-300)
            cnt += q < 0
        return cnt
    lo, hi = 0.0, 10.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if below(mid) >= 2 else (mid, hi)
    return (lo + hi) / 2

nt, wt = torus_brute(100), PI * 100
print(f"torus 2pi x 2pi: eigenvalues m^2 + n^2 <= 100: brute {nt}, by rows {torus_rows(100)}; Weyl pi x 100 = {wt:.1f}")
chart = [torus_brute(l) for l in range(10, 101, 10)]
print("chart, torus count at lambda = 10..100:", chart)
print("chart, Weyl pi x lambda:", [round(PI * l, 1) for l in range(10, 101, 10)])
mult = [harmonic_dim(k) for k in range(11)]
print(f"sphere multiplicity by exact rank, k = 0..10: {mult}")
print(f"sphere eigenvalue k(k+1), chart formula by differences, k = 1, 2, 3: " + ", ".join(f"{-lap_ratio(k):.6f}" for k in (1, 2, 3)))
ns, ws = sum(mult), PI * 4 * PI * 110 / (4 * PI * PI)
print(f"sphere: eigenvalues <= 110 with multiplicity {ns}, (K + 1)^2 = {11 ** 2}; Weyl = {ws:.1f}")
print(f"globe, radius 6371 km: lambda1 = 2/6371^2 = {2e8 / 6371 ** 2:.4f} x 1e-8 per km2")
for N in (200, 400):
    l = lam1_mesh(sphere_r, PI, N)
    print(f"sphere lambda1 on a {N}-cell mesh: {l:.6f}, error {l - 2:.6f}")
print("sphere caps, alpha deg: area, rim, rim/area")
for a in (30, 60, 90):
    t = math.radians(a)
    print(f"  {a:2d}: {2 * PI * (1 - math.cos(t)):.6f}  {2 * PI * math.sin(t):.6f}  {math.sin(t) / (1 - math.cos(t)):.6f}")
hs = min(math.sin(t) / (1 - math.cos(t)) for t in [i * PI / 2000 for i in range(1, 1001)])
print(f"sphere: h = {hs:.6f}; Cheeger h^2/4 = {hs * hs / 4:.6f} <= lambda1 = 2 <= Buser 10 h^2 = {10 * hs * hs:.6f}")
ht, hd = 4 * PI / (2 * PI * PI), 2 * math.sqrt(PI / (2 * PI * PI))
print(f"torus half-cuts: two circles {ht:.6f}, one disc {hd:.6f}; h^2/4 = {ht * ht / 4:.6f} <= 1 <= 10 h^2 = {10 * ht * ht:.6f}")
q = [(i + 0.5) * (PI / 2) / 20000 for i in range(20000)]
dq = (PI / 2) / 20000
iu2 = sum(math.cos(p) ** 2 * 2 * PI * math.sin(p) for p in q) * dq
igu = sum(math.sin(p) ** 2 * 2 * PI * math.sin(p) for p in q) * dq
igw = sum(2 * math.cos(p) * math.sin(p) * 2 * PI * math.sin(p) for p in q) * dq
coa = sum(2 * PI * math.sqrt(1 - (i + 0.5) / 20000) for i in range(20000)) / 20000
print(f"proof on the hemisphere: int u^2 {iu2:.6f} (2pi/3 {2 * PI / 3:.6f}), int |grad u|^2 {igu:.6f}, ratio {igu / iu2:.6f}")
print(f"  int |grad w| {igw:.6f}, coarea int length dt {coa:.6f}, 2 sqrt(..) {2 * math.sqrt(iu2 * igu):.6f}")
Ab = 2 * PI * (1 + math.cos(ALPHA))
LT = 2 * SJ + NECK
hn = C / Ab
ray = (4 * C / NECK) / (2 * Ab + C * NECK / 3)
lds = [lam1_mesh(bell_r, LT, N) for N in (2000, 4000)]
print(f"dumbbell: bell area {Ab:.6f}, neck cut h <= {hn:.6f}, test-function bound {ray:.6f}, C/(2pi) = {C / (2 * PI):.6f}")
print(f"dumbbell lambda1 on 2000 and 4000 cells: {lds[0]:.6f}, {lds[1]:.6f}")
print(f"  Cheeger: h <= 2 sqrt(lambda1) = {2 * math.sqrt(lds[1]):.6f}; no-curvature Buser 10 h^2 <= {10 * hn * hn:.6f} < lambda1")
print(f"mistake 1, sphere eigenvalues without multiplicity: {len(mult)} against Weyl {ws:.1f}")
print(f"mistake 2, torus with m, n >= 0 only: {sum(1 for m in range(11) for n in range(11) if m * m + n * n <= 100)} against {wt:.1f}")
c30 = math.sin(PI / 6) / (1 - math.cos(PI / 6))
print(f"mistake 3, any cut's ratio as h: 30-degree cap {c30:.6f} gives lambda1 >= {c30 * c30 / 4:.6f}, but lambda1 = 2")
assert nt == torus_rows(100) == 317 and abs(nt - wt) < 2 * math.sqrt(wt)    # two counts, Weyl
assert mult == [2 * k + 1 for k in range(11)] and ns == 121                 # rank against 2k+1
assert all(abs(-lap_ratio(k) - k * (k + 1)) < 1e-5 for k in (1, 2, 3))      # chart against k(k+1)
assert abs(lam1_mesh(sphere_r, PI, 400) - 2) < 1e-4 and abs(hs - 1) < 1e-9  # mesh against exact
assert abs(igu / iu2 - 2) < 1e-6 and abs(igw - coa) < 1e-4 and hs * iu2 <= igw <= 2 * math.sqrt(iu2 * igu)
assert lds[1] <= ray + 1e-6 and abs(lds[1] - lds[0]) < 1e-4 and 10 * hn * hn < lds[1]
print("ALL CHECKS PASS")
