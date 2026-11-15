# Fredholm alternative for the light balance in a long round tunnel, standard library only.
# Rehearsal: the tunnel as an N-sided prism; form factors by crossed strings; the round tunnel is N -> infinity.
import math

RHO, E0, R, PI = 0.8, 100.0, 2.0, math.pi  # paint reflectance, lamp output W/m2, radius m
def form_factors(N):  # F[i][j]: share of light leaving wall i that lands on wall j
    c = [math.sin(k * PI / N) for k in range(N + 1)]
    F = [[0.0] * N for _ in range(N)]
    for i in range(N):
        for j in range(N):
            m = (j - i) % N
            if m > 0:
                F[i][j] = (2 * c[m] - c[m + 1] - c[m - 1]) / (2 * c[1])
    return F
def eliminate(M):  # row reduction with partial pivoting; returns rank and reduced rows
    M = [r[:] for r in M]
    rank, rows, cols = 0, len(M), len(M[0])
    for col in range(cols):
        p = max(range(rank, rows), key=lambda r: abs(M[r][col]), default=None)
        if p is None or abs(M[p][col]) < 1e-9:
            continue
        M[rank], M[p] = M[p], M[rank]
        for r in range(rows):
            if r != rank:
                f = M[r][col] / M[rank][col]
                M[r] = [a - f * b for a, b in zip(M[r], M[rank])]
        rank += 1
    return rank, M
def solve(A, b):  # A square and invertible
    rank, M = eliminate([row + [v] for row, v in zip(A, b)])
    assert rank == len(A)
    return [M[i][-1] / M[i][i] for i in range(len(A))]
def minus(F, s):  # the matrix I - s F
    return [[(i == j) - s * F[i][j] for j in range(len(F))] for i in range(len(F))]
def null_vector(M):  # one-dimensional null space: fix the first entry at 1
    n = len(M)
    return solve(M[:n - 1] + [[1.0] + [0.0] * (n - 1)], [0.0] * (n - 1) + [1.0])
def quarter(v, k):  # average over quarter k of the wall: 0 ceiling, 1 and 3 sides, 2 floor
    q = len(v) // 4
    return sum(v[k * q:(k + 1) * q]) / q
def lam(n):  # eigenvalues of the round tunnel's kernel |sin((x - y)/2)|/4, on cos(n x)
    return 1.0 / (1.0 - 4.0 * n * n)
def arc_avg(n, a, b):  # average of cos(n x) over a < x < b
    return (math.sin(n * b) - math.sin(n * a)) / (n * (b - a))

print("Round tunnel, radius 2 m; the top quarter of the wall emits 100 W/m2 (illustrative)")
F4 = form_factors(4)
print(f"N=4 form factors: next wall {F4[0][1]:.6f}, opposite wall {F4[0][2]:.6f}, row sum {sum(F4[0]):.6f}")
assert abs(F4[0][1] - (1 - 1 / math.sqrt(2))) < 1e-12 and abs(F4[0][2] - (math.sqrt(2) - 1)) < 1e-12
print(f"round kernel eigenvalues: n=0 {lam(0):.6f}, n=1 {lam(1):.6f}, n=2 {lam(2):.6f}")
print("Painted walls, rho = 0.8: quarter averages of radiosity B, W/m2")
floors, gaps, Ns = [], [], [4, 8, 16, 32, 64, 128]
for N in Ns:
    F = form_factors(N)
    E = [E0 if i < N // 4 else 0.0 for i in range(N)]
    B = solve(minus(F, RHO), E)
    mu = [sum(F[0][m] * math.cos(2 * PI * n * m / N) for m in range(N)) for n in range(N)]
    cs = [[(math.cos(2 * PI * n * m / N), math.sin(2 * PI * n * m / N)) for m in range(N)] for n in range(N)]
    Ec = [sum(E[m] * cs[n][m][0] for m in range(N)) / N for n in range(N)]
    Es = [sum(E[m] * cs[n][m][1] for m in range(N)) / N for n in range(N)]
    B2 = [sum((Ec[n] * cs[n][i][0] + Es[n] * cs[n][i][1]) / (1 - RHO * mu[n]) for n in range(N)) for i in range(N)]
    assert max(abs(x - y) for x, y in zip(B, B2)) < 1e-9          # road 2: the eigenmodes
    assert abs((1 - RHO) * sum(B) - sum(E)) < 1e-9                # absorbed = emitted
    floors.append(quarter(B, 2))
    print(f"N={N:<4} floor {quarter(B, 2):.4f} ceiling {quarter(B, 0):.4f} mean {sum(B) / N:.4f}"
          f"  mu1 {mu[1]:.6f} mu2 {mu[2]:.6f}")
fl, ce = E0 * RHO / (1 - RHO) / 4, E0 + E0 * RHO / (1 - RHO) / 4
for n in range(1, 4000):
    En = 2 * E0 * math.sin(n * PI / 4) / (n * PI)
    g = En * RHO * lam(n) / (1 - RHO * lam(n))
    fl, ce = fl + g * arc_avg(n, 3 * PI / 4, 5 * PI / 4), ce + g * arc_avg(n, -PI / 4, PI / 4)
print(f"round floor {fl:.4f} ceiling {ce:.4f} mean {E0 / 4 / (1 - RHO):.4f}  (eigen series)")
errs = [f - fl for f in floors]
assert all(0.2 < errs[k + 1] / errs[k] < 0.3 for k in range(5))  # error falls like 1/N^2
print("log10 N:", " ".join(f"{math.log10(N):.3f}" for N in Ns), "| log10 floor error:", " ".join(f"{math.log10(e):.3f}" for e in errs))
B, E = [0.0] * 4, [E0, 0.0, 0.0, 0.0]
gap = E0 / (1 + RHO * (math.sqrt(2) - 1))  # by hand: ceiling row minus floor row
for _ in range(200):  # road 3: bounce by bounce, B <- E + rho F B
    B = [E[i] + RHO * sum(F4[i][j] * B[j] for j in range(4)) for i in range(4)]
assert abs(B[2] - floors[0]) < 1e-9 and abs(B[0] - B[2] - gap) < 1e-9
print(f"N=4 after 200 bounces: floor {B[2]:.4f}, side {B[1]:.4f}, ceiling minus floor {B[0] - B[2]:.4f} = by hand {gap:.4f}")
print("White walls, (I - K) J = q with q the net output of each wall, W/m2")
for N in Ns:
    F, q4 = form_factors(N), N // 4
    a = null_vector([list(col) for col in zip(*minus(F, 1.0))])  # adjoint null space
    assert max(abs(x - 1) for x in a) < 1e-9
    q = [E0 if i < q4 else (-E0 if 2 * q4 <= i < 3 * q4 else 0.0) for i in range(N)]
    r1 = eliminate(minus(F, 1.0))[0]
    r2 = eliminate([row + [v] for row, v in zip(minus(F, 1.0), q)])[0]
    assert r1 == r2 == N - 1
    J = solve(minus(F, 1.0)[:N - 1] + [[1.0] * N], q[:N - 1] + [0.0])
    assert abs(J[-1] - sum(F[-1][k] * J[k] for k in range(N)) - q[-1]) < 1e-9  # the dropped row holds
    gaps.append(quarter(J, 0) - quarter(J, 2))
    print(f"N={N:<4} rank {r1} of {N}, adjoint null vector all 1s, ceiling minus floor {quarter(J, 0) - quarter(J, 2):.4f}")
cf = 2 * E0
for n in range(1, 4000, 2):
    qn = 4 * E0 * math.sin(n * PI / 4) / (n * PI)
    cf += qn * lam(n) / (1 - lam(n)) * (arc_avg(n, -PI / 4, PI / 4) - arc_avg(n, 3 * PI / 4, 5 * PI / 4))
print(f"round ceiling minus floor {cf:.4f}  (eigen series, J_n = q_n / (1 - lambda_n) for n >= 1)")
assert all(0.2 < (gaps[k + 1] - cf) / (gaps[k] - cf) < 0.3 for k in range(5))  # N-gon gap closes on cf like 1/N^2
qbad = [E0, 0.0, -80.0, 0.0]
side = 2 * R * math.sin(PI / 4)
r1, r2 = eliminate(minus(F4, 1.0))[0], eliminate([row + [v] for row, v in zip(minus(F4, 1.0), qbad)])[0]
assert (r1, r2) == (3, 4)
print(f"floor absorbs only 80: N=4 wall {side:.4f} m, mismatch {sum(qbad) * side:.4f} W/m, round {20 * PI * R / 2:.4f} W/m; rank {r1} vs {r2}")
J, means = [0.0] * 4, []
for k in range(1, 1001):
    J = [qbad[i] + sum(F4[i][j] * J[j] for j in range(4)) for i in range(4)]
    if k in (10, 100, 1000):
        means.append(sum(J) / 4)
assert all(abs(m - 5 * k) < 1e-6 for m, k in zip(means, (10, 100, 1000)))
print("mean J after 10, 100, 1000 bounces:", " ".join(f"{m:.1f}" for m in means))
w, h = 4.0, 3.0  # square-cornered corridor: floor, right wall, ceiling, left wall
d = math.hypot(w, h)
s = (w + h - d) / 2
Fc = [[0, s / w, (2 * d - 2 * h) / (2 * w), s / w], [s / h, 0, s / h, (2 * d - 2 * w) / (2 * h)],
      [(2 * d - 2 * h) / (2 * w), s / w, 0, s / w], [s / h, (2 * d - 2 * w) / (2 * h), s / h, 0]]
ac = null_vector([list(col) for col in zip(*minus(Fc, 1.0))])
assert max(abs(x * w - y) for x, y in zip(ac, (w, h, w, h))) < 1e-9
qc = [0.0, -E0, E0, 0.0]
rc = (eliminate(minus(Fc, 1.0))[0], eliminate([row + [v] for row, v in zip(minus(Fc, 1.0), qc)])[0])
assert rc == (3, 4)
print(f"corridor {w:.0f} m x {h:.0f} m: rows of F {Fc[0][1]:.4f} {Fc[0][2]:.4f} | {Fc[1][0]:.4f} {Fc[1][3]:.4f}; adjoint null vector "
      + " ".join(f"{x * w:.4f}" for x in ac))
print(f"q = (0, -100, 100, 0): plain sum {sum(qc):.1f}, width-weighted sum {sum(x * w * y for x, y in zip(ac, qc)):.1f} W/m; rank {rc[0]} vs {rc[1]}")
ratios = []
for N in (10, 100, 1000, 10000):  # multiply by x on [0, 1]: (I - M_x) u = 1 gives u = 1/(1 - x)
    norm = math.sqrt(sum(1 / (1 - (i + 0.5) / N) ** 2 for i in range(N)) / N)
    ratios.append(norm / math.sqrt(N))
    print(f"multiply by x, N={N:<6} norm of u {norm:.4f}, divided by sqrt(N) {norm / math.sqrt(N):.4f}")
assert abs(ratios[-1] - PI / math.sqrt(2)) < 1e-3
print(f"figure, radius 160 px = 2 m, square vertex {210 + 160 * math.sin(PI / 4):.3f} {210 - 160 * math.cos(PI / 4):.3f}, octagon vertex {210 + 160 * math.sin(0.0):.3f} {210 - 160 * math.cos(0.0):.3f}")
print("ALL CHECKS PASS")
