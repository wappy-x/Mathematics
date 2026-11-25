# Bochner spaces and the weak heat equation -- the check behind the card.
# Standard library only.  A copper rod 1 m long, ends held at 0 C, diffusivity
# 1.11e-4 m^2/s, starting at 100 C on 0.4 < x < 0.6 m and 0 C elsewhere.
# Roads: (1) the sine series with closed-form coefficients; (2) the heat kernel
# with images, integrated by Simpson's rule; (3) Galerkin on N sine modes, its
# matrices and loads by Simpson, solved by Gauss-Jordan, stepped by
# Crank-Nicolson; (4) the energy identity and the decay bound.
import math
PI, KAP, T, HOT, A, B = math.pi, 1.11e-4, 60.0, 100.0, 0.4, 0.6
E0 = 0.5 * HOT ** 2 * (B - A)                      # start energy, C^2 m

def sci(v):                                        # same digits in Rust
    if v == 0.0: return "0.000e+00"
    e = math.floor(math.log10(abs(v))); m = v / 10.0 ** e
    if abs(m) >= 9.9995: m /= 10.0; e += 1
    return f"{m:.3f}e{'+' if e >= 0 else '-'}{abs(e):02d}"
def lam(n): return (n * PI) ** 2                   # eigenvalue of -d2/dx2, 1/m^2
def bn(n): return 2 * HOT / (n * PI) * (math.cos(n * PI * A) - math.cos(n * PI * B))
def series(x, t, nmax=2000):
    return sum(bn(n) * math.sin(n * PI * x) * math.exp(-KAP * lam(n) * t) for n in range(1, nmax + 1))
def energy(t, nmax=2000): return sum(bn(n) ** 2 * math.exp(-2 * KAP * lam(n) * t) for n in range(1, nmax + 1)) / 4
def bound(t): return E0 * math.exp(-2 * PI ** 2 * KAP * t)
def weights(a, b, m): return [(b - a) / m / 3 * (1 if i in (0, m) else 4 if i % 2 else 2) for i in range(m + 1)]
def kernel(x, t, m=400):                           # heat kernel with images at 0 and 1 m
    s, w = 4 * KAP * t, weights(A, B, m); tot = 0.0
    for i in range(m + 1):
        y = A + (B - A) * i / m
        tot += w[i] * sum(math.exp(-(x - y - 2 * k) ** 2 / s) - math.exp(-(x + y - 2 * k) ** 2 / s) for k in (-1, 0, 1))
    return HOT * tot / math.sqrt(PI * s)
def solve(Am, Bm):                                 # Gauss-Jordan, partial pivoting: Am X = Bm
    n = len(Am); M = [Am[i][:] + Bm[i][:] for i in range(n)]
    for c in range(n):
        p = c
        for r in range(c + 1, n):
            if abs(M[r][c]) > abs(M[p][c]): p = r
        M[c], M[p] = M[p], M[c]; piv = M[c][c]; M[c] = [v / piv for v in M[c]]
        for r in range(n):
            if r != c and M[r][c] != 0.0:
                f = M[r][c]; M[r] = [a - f * b for a, b in zip(M[r], M[c])]
    return [row[n:] for row in M]

print(f"rod 1 m, kappa {sci(KAP)} m^2/s, 100 C on 0.4..0.6 m, t = {T:.0f} s; kappa pi^2 = {sci(KAP * PI ** 2)} /s")
print(f"spread 2 sqrt(kappa t) = {2 * math.sqrt(KAP * T):.4f} m; start energy 0.5||u0||^2 = {E0:.4f} C^2 m")
# ---- roads 1 and 2: the series and the kernel agree ----
for x, t in ((0.5, T), (0.4, T), (0.3, T), (0.05, 600.0)):  # the last needs the images
    s, k = series(x, t), kernel(x, t)
    print(f"u({x}, {t:.0f} s): series {s:.6f} C, kernel with images {k:.6f} C")
    assert abs(s - k) < 1e-6
print(f"series: 2000 modes, first omitted term {sci(abs(bn(2001)) * math.exp(-KAP * lam(2001) * T))} C")
# ---- road 3: Galerkin, assembled by Simpson on 2000 intervals ----
NM, xs, w = 80, [i / 2000 for i in range(2001)], weights(0.0, 1.0, 2000)
S = [[math.sin(k * PI * x) for x in xs] for k in range(1, NM + 1)]
C = [[k * PI * math.cos(k * PI * x) for x in xs] for k in range(1, NM + 1)]
WS = [[a * b for a, b in zip(w, r)] for r in S]; WC = [[a * b for a, b in zip(w, r)] for r in C]
MM = [[sum(a * b for a, b in zip(WS[j], S[k])) for k in range(NM)] for j in range(NM)]
KK = [[sum(a * b for a, b in zip(WC[j], C[k])) for k in range(NM)] for j in range(NM)]
wl = weights(A, B, 800)
F = [HOT * sum(wl[i] * math.sin(k * PI * (A + 0.2 * i / 800)) for i in range(801)) for k in range(1, NM + 1)]
off = max(abs(MM[j][k]) + abs(KK[j][k]) / lam(80) for j in range(NM) for k in range(NM) if j != k)
assert off < 1e-12 and all(abs(MM[k][k] - 0.5) < 1e-12 and abs(KK[k][k] / lam(k + 1) - 0.5) < 1e-12 for k in range(NM))
print("mass matrix 1/2 I, stiffness diag(lambda_k/2): off-diagonal below 1e-12 (stiffness over lambda_80), as orthogonality says")

def galerkin(N, dt):
    Mn, Kn = [r[:N] for r in MM[:N]], [r[:N] for r in KK[:N]]
    c = [r[0] for r in solve(Mn, [[f] for f in F[:N]])]
    h = KAP * dt / 2
    St = solve([[Mn[i][j] + h * Kn[i][j] for j in range(N)] for i in range(N)],
               [[Mn[i][j] - h * Kn[i][j] for j in range(N)] for i in range(N)])
    en = lambda v, G: 0.5 * sum(v[i] * G[i][j] * v[j] for i in range(N) for j in range(N))
    e_start, diss, worst, c0 = en(c, Mn), 0.0, 0.0, c[:]
    for n in range(round(T / dt)):
        cn = [sum(St[i][j] * c[j] for j in range(N)) for i in range(N)]
        diss += KAP * dt * 2 * en([(a + b) / 2 for a, b in zip(c, cn)], Kn); c = cn
        worst = max(worst, en(c, Mn) / bound((n + 1) * dt))
    return c0, c, e_start, en(c, Mn), diss, worst
def at(c, x): return sum(ck * math.sin((k + 1) * PI * x) for k, ck in enumerate(c))
def rms_gap(c, t): return math.sqrt(0.5 * sum((ck - bn(k + 1) * math.exp(-KAP * lam(k + 1) * t)) ** 2 for k, ck in enumerate(c)))

print("Galerkin, Crank-Nicolson dt = 0.5 s")
print(" N | u_N(0.5,60) C | gap to series C | rms err t=0 C | rms err t=60 C | 1st omitted C | E_N(60) C^2 m | kappa int|du/dx|^2 | max E/bound")
runs = {}
for N in (5, 20, 80):
    c0, c, es, et, diss, worst = runs[N] = galerkin(N, 0.5)
    assert max(abs(a - bn(k + 1)) for k, a in enumerate(c0)) < 1e-6        # quadrature against closed form
    assert abs(es - et - diss) < 1e-9 * E0 and worst <= 1.0                  # energy identity, decay bound
    r0 = math.sqrt(2 * (E0 - sum(bn(n) ** 2 for n in range(1, N + 1)) / 4))
    r60 = math.sqrt(0.5 * sum(bn(n) ** 2 * math.exp(-2 * KAP * lam(n) * T) for n in range(N + 1, 2001)))
    om = abs(bn(N + 1 + N % 2)) * math.exp(-KAP * lam(N + 1 + N % 2) * T)
    g = at(c, 0.5) - series(0.5, T)
    print(f"{N:2d} | {at(c, 0.5):13.6f} | {g:15.6f} | {r0:13.4f} | {sci(r60):>14} | {sci(om):>13} | {et:13.4f} | {diss:18.4f} | {worst:.4f}")
fac = [math.exp(-KAP * lam(k) * T) for k in (1, 3, 5)]
h5 = [bn(k) * math.sin(k * PI / 2) * f for k, f in zip((1, 3, 5), fac)]
print(f"by hand, N = 5 at the centre: b_1, b_3, b_5 = {bn(1):.4f}, {bn(3):.4f}, {bn(5):.4f} C; decay {fac[0]:.6f}, {fac[1]:.6f}, {fac[2]:.6f}")
print(f"  terms {h5[0]:.4f} + ({h5[1]:.4f}) + {h5[2]:.4f} = {h5[0] + h5[1] + h5[2]:.4f} C, the 5-mode series exactly")
assert abs(runs[80][3] - energy(T)) < 2e-3 and abs(at(runs[80][1], 0.4) - series(0.4, T)) < 2e-4  # CN error, dt 0.5 s
errs = [rms_gap(galerkin(80, dt)[1], T) for dt in (2.0, 1.0, 0.5)]
o1, o2 = math.log2(errs[0] / errs[1]), math.log2(errs[1] / errs[2])
print(f"Crank-Nicolson time error, N = 80, dt 2, 1, 0.5 s: {sci(errs[0])}, {sci(errs[1])}, {sci(errs[2])} C rms; orders {o1:.3f}, {o2:.3f}")
assert 1.9 < o1 < 2.1 and 1.9 < o2 < 2.1
# ---- the path: continuous in L^2, not in H^1_0 ----
LEAD, TAIL = 2 * HOT ** 2 / math.sqrt(8 * PI * KAP), 2 * E0 - sum(0.5 * bn(n) ** 2 for n in range(1, 100001))  # Parseval
print(f"t s | rms ||u(t)-u0|| C | two jumps alone C | ||du/dx||^2 C^2/m | times sqrt(t)  (two-jump limit {LEAD:.1f}; 100000 modes + Parseval tail {TAIL:.4f} C^2)")
prev = 0.0
for t in (0.06, 0.6, 6.0, 60.0):
    d2, g2 = TAIL, 0.0                             # modes above 100000 have died, each adding b_n^2 / 2 to the gap^2
    for n in range(1, 100001):
        b, q = bn(n), math.exp(-KAP * lam(n) * t)
        d2 += 0.5 * b * b * (1 - q) ** 2; g2 += 0.5 * b * b * lam(n) * q * q
    cf = math.sqrt(HOT ** 2 * math.sqrt(4 * KAP * t) * (2 - math.sqrt(2)) / math.sqrt(PI))  # two erf steps on a line
    print(f"{t:5.2f} | {math.sqrt(d2):17.4f} | {cf:17.4f} | {g2:17.1f} | {g2 * math.sqrt(t):.1f}")
    assert prev < math.sqrt(d2) < 30 and (t > 1 or abs(math.sqrt(d2) - cf) < 1e-6) and (t > 10 or abs(g2 * math.sqrt(t) / LEAD - 1) < 0.01); prev = math.sqrt(d2)
EL = energy(T)
print(f"exact E(60) = {EL:.4f} C^2 m; int_0^60 ||du/dx||^2 dt = (E0 - E(60))/kappa = {sci((E0 - EL) / KAP)} C^2 s/m; int ||u'||^2_(H^-1) = {(E0 - EL) * KAP:.6f} C^2 m^3/s")
# ---- what breaks ----
LS = [sum(bn(n) ** 2 * KAP * lam(n) * (1 - math.exp(-2 * KAP * lam(n) * T)) for n in range(1, N + 1)) / 4 for N in (5, 20, 80)]
print(f"u' in L^2(0,60; L^2) instead: int ||u_N'||^2 dt for N = 5, 20, 80 = {LS[0]:.4f}, {LS[1]:.4f}, {LS[2]:.4f} C^2 m/s, growing")
assert LS[2] > 4 * LS[1] and LS[1] > 3 * LS[0]
grow = 1e-6 * math.exp(KAP * lam(21) * T)
print(f"backward in time: 1e-6 C in mode 21 becomes {sci(grow)} C after 60 s")
mean = HOT * (B - A)                               # insulated ends keep the mean, C
ins = 0.5 * (mean ** 2 + 0.5 * sum((2 * HOT / (n * PI) * (math.sin(n * PI * B) - math.sin(n * PI * A))) ** 2 * math.exp(-2 * KAP * lam(n) * 3600) for n in range(1, 2001)))
print(f"insulated ends, cosine series: mean {mean:.1f} C never decays, energy {ins:.4f} C^2 m at 3600 s, bound {bound(3600):.4f}")
assert ins > 100 * bound(3600) and abs(ins - 0.5 * mean ** 2) < 1e-6
# ---- chart points ----
print("chart, x m:       " + " ".join(f"{i / 20:.2f}" for i in range(21)))
print("chart, start:     " + " ".join(f"{HOT if 8 <= i <= 12 else 0.0:.2f}" for i in range(21)))
print("chart, N=5, t=0:  " + " ".join(f"{at(runs[5][0], i / 20):.2f}" for i in range(21)))
print("chart, t=60 s:    " + " ".join(f"{series(i / 20, T):.2f}" for i in range(21)))
print("chart, t s:       " + " ".join(f"{60 * i}" for i in range(11)))
print("chart, energy:    " + " ".join(f"{E0 if i == 0 else energy(60 * i):.1f}" for i in range(11)))
print("chart, bound:     " + " ".join(f"{bound(60 * i):.1f}" for i in range(11)))
assert all(energy(60 * i) <= bound(60 * i) for i in range(1, 11))
print("ALL CHECKS PASS")
