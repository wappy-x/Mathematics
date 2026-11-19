# Hodge star and Maxwell in forms -- the check behind the card.  Standard library only.
# Coordinates 0 = t (s), 1 = x, 2 = y, 3 = z (m).  A two-form is a 4x4 antisymmetric list F[a][b].
from math import pi, sqrt, cos, sin
C, MU0 = 299792458.0, 1.25663706127e-6            # CODATA 2022
EPS0 = 1.0 / (MU0 * C * C)
PAIRS = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
TRIPLES = [(0, 1, 2), (0, 1, 3), (0, 2, 3), (1, 2, 3)]

def sign(p):                                        # sign of a permutation of 0..3, by inversions
    return (-1) ** sum(1 for i in range(4) for j in range(i + 1, 4) if p[i] > p[j])
def form(E, B):                                     # F = E_i dx^i ^ dt + Bx dy^dz + By dz^dx + Bz dx^dy
    F = [[0.0] * 4 for _ in range(4)]
    for i in range(3):
        F[i + 1][0], F[0][i + 1] = E[i], -E[i]
    for (a, b), v in (((2, 3), B[0]), ((3, 1), B[1]), ((1, 2), B[2])):
        F[a][b], F[b][a] = v, -v
    return F
def fields(F):
    return [F[1][0], F[2][0], F[3][0]], [F[2][3], F[3][1], F[1][2]]
def rest(a, b):                                     # the other two coordinates, in order
    return [k for k in range(4) if k not in (a, b)]
def star(F, sg=-1.0):                               # road 1: (*F)_ab = sqrt|g| eps_abcd F^cd, g = diag(sg c^2, 1, 1, 1)
    gi = [1.0 / (sg * C * C), 1.0, 1.0, 1.0]
    S = [[0.0] * 4 for _ in range(4)]
    for a in range(4):
        for b in range(4):
            if a != b:
                c, d = rest(a, b)
                S[a][b] = C * sign((a, b, c, d)) * gi[c] * gi[d] * F[c][d]
    return S
def inner(A, B, sg=-1.0):                           # <A, B> from the inverse metric
    gi = [1.0 / (sg * C * C), 1.0, 1.0, 1.0]
    return sum(gi[a] * gi[b] * A[a][b] * B[a][b] for a, b in PAIRS)
def wedge(A, B):                                    # coefficient of dt^dx^dy^dz in A ^ B
    return sum(sign((a, b, *rest(a, b))) * A[a][b] * B[rest(a, b)[0]][rest(a, b)[1]] for a, b in PAIRS)
def basis(a, b):
    F = [[0.0] * 4 for _ in range(4)]
    F[a][b], F[b][a] = 1.0, -1.0
    return F
def d(Ffun, p, h):                                  # exterior derivative by central differences
    def dd(k, a, b):
        q1, q2 = list(p), list(p)
        q1[k] += h[k]; q2[k] -= h[k]
        return (Ffun(q1)[a][b] - Ffun(q2)[a][b]) / (2 * h[k])
    return [dd(a, b, c) + dd(b, c, a) + dd(c, a, b) for a, b, c in TRIPLES]
def z(v, n=6):                                      # print a rounded zero as 0, never -0
    return 0.0 if round(v, n) == 0 else v

# ---- the radio mast: 100 MHz, vertical mast, field 0.1 V/m at 10 km ----
f, r, E0 = 100e6, 10000.0, 0.1
lam, w, k = C / f, 2 * pi * f, 2 * pi * f / C
S_pow = E0 * E0 / (2 * MU0 * C)                    # mean power per square metre
eirp = 4 * pi * r * r * S_pow                       # the same, spread over a whole sphere of radius r
def wave(p, f0=f):
    ph = (2 * pi * f0 / C) * p[1] - 2 * pi * f0 * p[0]
    return form([0.0, 0.0, E0 * cos(ph)], [0.0, -E0 / C * cos(ph), 0.0])
print(f"wavelength (m)                    {lam:.6f}")
print(f"k (rad/m)                         {k:.6f}")
print(f"E0 (V/m), B0 = E0/c (nT)          {E0:.6f} {E0 / C * 1e9:.6f}")
print(f"power density (uW/m^2), 2 mu0 c   {S_pow * 1e6:.6f} {2 * MU0 * C:.2f}")
print(f"equivalent isotropic power (kW)   {eirp / 1e3:.6f}")
print(f"light time to 10 km (us), s^2     {r / C * 1e6:.6f} {z(-(C * (r / C)) ** 2 + r * r):.6f}")
print(f"2-form slots, 1-form slots, eqns  {len(PAIRS)} 4 {2 * len(TRIPLES)}")

# road 2: the star against its definition A ^ *B = <A, B> vol, vol = c dt^dx^dy^dz, all 36 pairs
err = max(abs(wedge(basis(*P), star(basis(*Q))) - inner(basis(*P), basis(*Q)) * C) for P in PAIRS for Q in PAIRS)
names = "t x y z".split()
for a, b in PAIRS:
    S = star(basis(a, b))
    m, n = rest(a, b)
    unit = "c" if abs(S[m][n]) > 1 else "(1/c)"
    print(f"*(d{names[a]}^d{names[b]}) = {'+' if S[m][n] > 0 else '-'}{unit} d{names[m]}^d{names[n]}")
ss_m, ss_e = ([star(star(basis(*P), sg), sg)[P[0]][P[1]] for P in PAIRS] for sg in (-1.0, 1.0))
print(f"** on the six planes, (-,+,+,+)   {' '.join(f'{v:+.0f}' for v in ss_m)}")
print(f"** on the six planes, (+,+,+,+)   {' '.join(f'{v:+.0f}' for v in ss_e)}")

# the wave at a crest (phase 0): F, *F, **F
F = wave([0.0, 0.0, 0.0, 0.0])
E1, B1 = fields(star(F))
E2, B2 = fields(star(star(F)))
print(f"*F: E_y (V/m), B_z (nT)           {E1[1]:.6f} {B1[2] * 1e9:.6f}")
print(f"**F: E_z (V/m)                    {E2[2]:.6f}")
print(f"c^2<F,F> = c^2B^2 - E^2, F^F      {z(inner(F, F) * C * C):.6f} {z(wedge(F, F)):.6f}")

# road 3: Maxwell, by forms against vector calculus, where the field's derivative peaks (phase -pi/2)
p0, h = [0.25 / f, 0.0, 0.0, 0.0], [1e-4 / C, 1e-4, 1e-4, 1e-4]
Ez, By = (lambda t, x: wave([t, x, 0, 0])[3][0]), (lambda t, x: wave([t, x, 0, 0])[3][1])
curlE_y = -(Ez(p0[0], h[1]) - Ez(p0[0], -h[1])) / (2 * h[1])
dBy_dt = (By(p0[0] + h[0], 0.0) - By(p0[0] - h[0], 0.0)) / (2 * h[0])
print(f"Faraday y: curl E, dB/dt (V/m^2)  {curlE_y:.6f} {dBy_dt:.6f}")
dF = d(wave, p0, h)
dsF = d(lambda q: star(wave(q)), p0, h)
dsF_e = d(lambda q: star(wave(q), 1.0), p0, h)
print(f"wave: max |dF|, max |d*F|         {z(max(map(abs, dF))):.6f} {z(max(map(abs, dsF))):.6f}")
print(f"wave, all-plus star: d*F Ampere z {abs(dsF_e[0]):.6f}")
dsF_g = d(lambda q: star(wave(q, 1e9)), p0, [1e-5 / C, 1e-5, 1e-5, 1e-5])
print(f"try: 1 GHz, max |d*F|, E0 k       {z(max(map(abs, dsF_g))):.6f} {E0 * 2 * pi * 1e9 / C:.6f}")

# sources: uniform charge 1 nC/m^3 and current 1 A/m^2 along z; vector solution E = rho r/(3 eps0), B = mu0 J (-y, x, 0)/2
rho, J = 1e-9, 1.0
src = lambda q: form([rho * q[1] / (3 * EPS0), rho * q[2] / (3 * EPS0), rho * q[3] / (3 * EPS0)],
                     [-MU0 * J * q[2] / 2, MU0 * J * q[1] / 2, 0.0])
ps = [0.0, 0.3, -0.2, 0.5]
dsS = d(lambda q: star(src(q)), ps, [1e-3 / C, 1e-3, 1e-3, 1e-3])
want = [-J, 0.0, 0.0, rho]                          # current three-form: rho dx^dy^dz - J dx^dy^dt
print(f"d*F / (mu0 c): dtdxdy, dxdydz     {dsS[0] / (MU0 * C):.6f} {dsS[3] / (MU0 * C) * 1e9:.6f}")
print(f"source field: max |dF|            {z(max(map(abs, d(src, ps, [1e-3 / C, 1e-3, 1e-3, 1e-3])))):.6f}")

# road 4: chart against chart, a boost along x at beta (inverse map t = g(t' + b x'/c), x = g(x' + b c t'))
def boost(F, beta):
    g = 1 / sqrt(1 - beta * beta)
    M = [[g, g * beta / C, 0, 0], [g * beta * C, g, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    return [[sum(M[a][m] * F[a][b] * M[b][n] for a in range(4) for b in range(4)) for n in range(4)] for m in range(4)]
Fs = src(ps)
chart = max(abs(x[a][b] - y[a][b]) / (abs(y[a][b]) or 1.0)
            for G in (F, Fs) for x, y in [(star(boost(G, 0.6)), boost(star(G), 0.6))] for a, b in PAIRS)
print(f"boost 0.6c: E_z (V/m), c^2<F,F>   {fields(boost(F, 0.6))[0][2]:.6f} {z(inner(boost(F, 0.6), boost(F, 0.6)) * C * C):.6f}")
print(f"source field c^2<F,F>, both charts {inner(Fs, Fs) * C * C:.6f} {inner(boost(Fs, 0.6), boost(Fs, 0.6)) * C * C:.6f}")
print(f"try: boost -0.6c, E_z (V/m)       {fields(boost(F, -0.6))[0][2]:.6f}")
print(f"try: 20 km, same power, E0 (V/m)  {sqrt(2 * MU0 * C * eirp / (4 * pi * 20000.0 ** 2)):.6f}")

# a hole in space: a monopole of 1 Wb, B = g r/(4 pi |r|^3); closed, yet its flux through a sphere is not 0
gm, n, R = 1.0, 200, 2.0                            # the sphere: radius 2 m round the point, n x 2n midpoint cells
mono = lambda q: form([0, 0, 0], [gm * q[m] / (4 * pi * (q[1] ** 2 + q[2] ** 2 + q[3] ** 2) ** 1.5) for m in (1, 2, 3)])
dFm = max(map(abs, d(mono, [0, 1, 1, 1], [1e-4] * 4)))
flux = sum(sum(b * x for b, x in zip(fields(mono(q))[1], q[1:])) * R * sin(th) * (pi / n) ** 2 for i in range(n) for j in range(2 * n)
           for th, ph in [((i + 0.5) * pi / n, (j + 0.5) * pi / n)] for q in [[0.0, R * sin(th) * cos(ph), R * sin(th) * sin(ph), R * cos(th)]])
print(f"monopole: |dF| at (1,1,1) m, flux {z(dFm):.6f} {flux:.4f}")

assert err < 1e-15, "star against its definition A ^ *B = <A,B> vol"
assert all(v == -1.0 for v in ss_m) and all(v == 1.0 for v in ss_e), "star twice: -1 in spacetime, +1 all-plus"
assert abs(E1[1] - E0) < 1e-12 and abs(E2[2] + E0) < 1e-12, "*F turns the vertical wave horizontal; **F = -F"
assert max(map(abs, dF)) < 1e-6 * E0 * k and max(map(abs, dsF)) < 1e-6 * E0 * k, "the radio wave solves both lines"
assert abs(curlE_y + E0 * k) < 1e-6 and abs(dBy_dt - E0 * k) < 1e-6, "Faraday terms against E0 k by hand"
assert abs(abs(dsF_e[0]) - 2 * E0 * k) < 1e-6, "all-plus star: the two Ampere terms add"
assert all(abs(dsS[i] / (MU0 * C) - want[i]) < 1e-6 * max(abs(want[i]), rho) for i in range(4)), "d*F = mu0 c J"
assert chart < 1e-9 and abs(inner(boost(Fs, 0.6), boost(Fs, 0.6)) / inner(Fs, Fs) - 1) < 1e-9, "star and c^2<F,F> ignore a boost"
assert abs(fields(boost(F, 0.6))[0][2] - 0.5 * E0) < 1e-12, "Doppler factor sqrt(0.4/1.6) = 0.5"
assert dFm < 1e-6 and abs(flux - gm) < 1e-4, "monopole: dF = 0 off the point; flux of its B through the sphere = g"
print("ALL CHECKS PASS")
