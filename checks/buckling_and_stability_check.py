# Buckling -- the check behind the card.  Standard library only.  A 3 m steel scaffold tube,
# 48.3 mm across with a 4.0 mm wall, loaded end-on.  Road 1: Euler's formula with the end
# factor K.  Road 2: RK4 shooting on EI y'''' + P y'' = 0 for each pair of ends.  Road 3: the
# tube as a chain of stiff links and springs, stable while its energy matrix has no negative pivot.
import math
PI = math.pi
E, FY, L, D, T = 210e9, 235e6, 3.0, 0.0483, 0.0040    # Pa, Pa, m, m, m
DI = D - 2 * T                                        # inside diameter, m
A, I = PI / 4 * (D ** 2 - DI ** 2), PI / 64 * (D ** 4 - DI ** 4)
R, W, PSQ = math.sqrt(I / A), I / (D / 2), FY * A     # radius of gyration, section modulus, squash load
def euler(K, L=L, I=I, E=E): return PI ** 2 * E * I / (K * L) ** 2
def bisect(g, lo, hi, n=60):
    glo = g(lo)
    for _ in range(n):
        m = (lo + hi) / 2; gm = g(m)
        if glo * gm <= 0: hi = m
        else: lo, glo = m, gm
    return (lo + hi) / 2
def rk4(f, v, n=200, h=L / 200):                      # integrate v' = f(x, v) from 0 to L
    x = 0.0
    for _ in range(n):
        a = f(x, v); b = f(x + h / 2, [p + h / 2 * q for p, q in zip(v, a)])
        c = f(x + h / 2, [p + h / 2 * q for p, q in zip(v, b)]); d = f(x + h, [p + h * q for p, q in zip(v, c)])
        v = [p + h / 6 * (q1 + 2 * q2 + 2 * q3 + q4) for p, q1, q2, q3, q4 in zip(v, a, b, c, d)]; x += h
    return v
# Road 1: kL = pi, pi/2, 2 pi, and the root of tan(kL) = kL for fixed-pinned (written sin z - z cos z)
KL_FP = bisect(lambda z: math.sin(z) - z * math.cos(z), 4.0, 4.6)
ENDS = [("pinned-pinned", 1.0, "pin", "pin"), ("fixed-free", 2.0, "fix", "free"),
        ("fixed-pinned", PI / KL_FP, "fix", "pin"), ("fixed-fixed", 0.5, "fix", "fix")]
# Road 2: state (y, y', y'', y'''); each end condition zeroes two combinations of it
def top_bc(kind, v, k2):
    return {"pin": (v[0], v[2]), "fix": (v[0], v[1]), "free": (v[2], v[3] + k2 * v[1])}[kind]
def det(P, base, top):
    k2 = P / (E * I)
    f = lambda x, v: [v[1], v[2], v[3], -k2 * v[2]]   # EI y'''' + P y'' = 0
    starts = ([0, 1, 0, 0], [0, 0, 0, 1]) if base == "pin" else ([0, 0, 1, 0], [0, 0, 0, 1])
    (a, b), (c, d) = (top_bc(top, rk4(f, s), k2) for s in starts)
    return a * d - b * c
def shoot(base, top):                                 # first load, scanning in 1 kN steps, where det = 0
    P = 1e3
    while det(P, base, top) * det(P + 1e3, base, top) > 0 and P < 1e6: P += 1e3
    return bisect(lambda Q: det(Q, base, top), P, P + 1e3, 40)
# Road 3: N stiff links, a spring EI/h at each inner joint; energy matrix (EI/h^3) T^2 - (P/h) T
def negative_pivots(P, N):
    h, n = L / N, N - 1
    Tm = [[2.0 if i == j else -1.0 if abs(i - j) == 1 else 0.0 for j in range(n)] for i in range(n)]
    M = [[E * I / h ** 3 * sum(Tm[i][k] * Tm[k][j] for k in range(max(0, i - 1), min(n, i + 2)))
          - P / h * Tm[i][j] for j in range(n)] for i in range(n)]
    neg = 0
    for i in range(n):                                # elimination without row swaps keeps the pivot signs
        neg += M[i][i] < 0
        for r in range(i + 1, min(n, i + 3)):
            f = M[r][i] / M[i][i]
            for c in range(i, min(n, i + 3)): M[r][c] -= f * M[i][c]
    return neg
def chain(N):
    lo, hi = 0.0, 2 * euler(1.0)
    for _ in range(50):
        m = (lo + hi) / 2; lo, hi = (lo, m) if negative_pivots(m, N) else (m, hi)
    return (lo + hi) / 2
# Bent tube: initial bow e0 sin(pi x/L); EI (y - y0)'' = -P y.  Road A: closed form e0/(1 - P/Pcr).
PE = euler(1.0)
def bow_formula(P, e0): return e0 / (1 - P / PE)
def bow_rk4(P, e0):                                   # Road B: linear, so two shots fix the start slope
    f = lambda x, v: [v[1], -e0 * (PI / L) ** 2 * math.sin(PI * x / L) - P / (E * I) * v[0], 0]
    end = lambda s: rk4(f, [0.0, s, 0.0])[0]
    s = -end(0.0) / (end(1.0) - end(0.0))
    return rk4(f, [0.0, s, 0.0], 100, L / 200)[0]   # 100 steps of L/200 lands at mid-height
def peak(P, e0, pe=PE): return P / A + P * e0 / (1 - P / pe) / W
def first_yield(e0, pe=PE): return bisect(lambda P: peak(P, e0, pe) - FY, 1.0, pe * (1 - 1e-12))
def first_yield_quad(e0, pe=PE):                      # the same load as the smaller root of
    qa, qb = 1 / (A * pe), FY / pe + 1 / A + e0 / W   # (fy - P/A)(1 - P/Pcr) = P e0 / W
    return (qb - math.sqrt(qb * qb - 4 * qa * FY)) / (2 * qa)
def rings(n=4000):                                    # A and I again from thin rings: dA = 2 pi r dr,
    dr, a, i = (D - DI) / 2 / n, 0.0, 0.0             # and a ring's I about a diameter is pi r^3 dr
    for k in range(n):
        r = DI / 2 + (k + 0.5) * dr
        a, i = a + 2 * PI * r * dr, i + PI * r ** 3 * dr
    return a, i
kn, mm, mpa = 1e-3, 1e3, 1e-6
print(f"inputs: D = {D * mm:.1f} mm, wall {T * mm:.1f} mm, inside {DI * mm:.1f} mm, L = {L:.0f} m, "
      f"E = {E * 1e-9:.0f} GPa, fy = {FY * mpa:.0f} MPa, pi^2 = {PI ** 2:.4f}")
print(f"tube: A = {A * 1e6:.1f} mm^2, I = {I * 1e12:.0f} mm^4, r = {R * mm:.2f} mm, W = {W * 1e9:.0f} mm^3, EI = {E * I:.0f} N m^2")
A2, I2 = rings()
assert abs(A2 - A) < 1e-9 * A and abs(I2 - I) < 1e-6 * I
print(f"tube again, from 4000 thin rings: A = {A2 * 1e6:.1f} mm^2, I = {I2 * 1e12:.0f} mm^4")
print(f"slenderness L/r = {L / R:.1f}; crossover pi sqrt(E/fy) = {PI * math.sqrt(E / FY):.1f}")
print(f"squash load fy A = {PSQ * kn:.1f} kN; Euler stress = {PE / A * mpa:.1f} MPa")
print(f"fixed-pinned root kL = {KL_FP:.4f}, so K = {PI / KL_FP:.4f}")
print("ends           K       road 1 kN  road 2 kN  share of squash  Le m")
for name, K, base, top in ENDS:
    p1, p2 = euler(K), shoot(base, top)
    assert abs(p1 - p2) < 1e-3 * p1, name
    print(f"{name:14} {K:.4f}  {p1 * kn:8.2f}  {p2 * kn:9.2f}  {p1 / PSQ * 100:13.1f} %  {K * L:.3f}")
for N in (10, 20, 40):
    print(f"road 3, {N} links, pinned-pinned: {chain(N) * kn:.2f} kN")
assert abs(chain(40) - PE) < 0.002 * PE and chain(10) < chain(20) < chain(40) < PE
print(f"40 kN on the pinned tube is {40e3 / PE:.2f} x Euler and {40e3 / PSQ * 100:.1f} % of squash")
print("load kN  bow mm (formula, rk4)  squeeze MPa  bending MPa  peak MPa, e0 = 3 mm")
for P in (0, 10e3, 20e3, 25e3, 28e3):
    b1, b2 = bow_formula(P, 3e-3), bow_rk4(P, 3e-3)
    assert abs(b1 - b2) < 1e-4 * b1
    print(f"{P * kn:5.0f}  {b1 * mm:8.2f} {b2 * mm:8.2f}  {P / A * mpa:15.1f}  {P * b1 / W * mpa:11.1f}  {peak(P, 3e-3) * mpa:8.1f}")
PY3, PY1 = first_yield(3e-3), first_yield(1e-3)
assert all(abs(first_yield(e) - first_yield_quad(e)) < 1e-6 * PY3 for e in (3e-3, 1e-3))
assert PY1 > PY3 and PY3 < PE
print(f"first yield, bow 3 mm: {PY3 * kn:.2f} kN; bow 1 mm: {PY1 * kn:.2f} kN")
loads = list(range(0, 29, 2))
print("chart load kN", " ".join(str(p) for p in loads))
print("chart squeeze only MPa", " ".join(f"{p * 1e3 / A * mpa:.0f}" for p in loads))
print("chart peak, bow 3 mm MPa", " ".join(f"{peak(p * 1e3, 3e-3) * mpa:.0f}" for p in loads))
print("chart peak, bow 1 mm MPa", " ".join(f"{peak(p * 1e3, 1e-3) * mpa:.0f}" for p in loads))
print("chart yield MPa", " ".join(f"{FY * mpa:.0f}" for p in loads))
FF = euler(0.5)
PYF = first_yield(1.5e-3, FF)
assert abs(PYF - first_yield_quad(1.5e-3, FF)) < 1e-6 * PYF
print(f"outside the range: fixed-fixed Euler {FF * kn:.1f} kN vs squash {PSQ * kn:.1f} kN; "
      f"with a 1.5 mm bow first yield at {PYF * kn:.1f} kN")
print(f"outside the range: 0.5 m pinned tube, Euler {euler(1.0, 0.5) * kn:.0f} kN, crushes at {PSQ * kn:.1f} kN")
solid = euler(1.0, L, PI / 64 * D ** 4)
assert solid > 1.9 * PE
print(f"wrong: solid-bar I gives {solid * kn:.2f} kN; K not squared, flagpole {PI ** 2 * E * I / (2 * L ** 2) * kn:.2f} kN")
print(f"wrong: fixed-fixed assumed for pinned couplers {FF * kn:.2f} kN")
print(f"try: 3.2 mm wall {euler(1.0, L, PI / 64 * (D ** 4 - (D - 0.0064) ** 4)) * kn:.2f} kN; 2 m tube "
      f"{euler(1.0, 2.0) * kn:.2f} kN; aluminium E = 70 GPa {euler(1.0, L, I, 70e9) * kn:.2f} kN")
print(f"try: 40 kN on a fixed-pinned tube is {40e3 / euler(PI / KL_FP) * 100:.0f} % of its Euler load")
print(f"figure, 60 px per m, inflection heights m: pinned 0, 3; fixed-free 3; fixed-pinned "
      f"{L * (1 - PI / KL_FP):.3f}, 3; fixed-fixed {L / 4:.2f}, {3 * L / 4:.2f}")
print("ALL CHECKS PASS")
