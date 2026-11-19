# Zeros on the line -- the check behind the card.  Standard library only.  Hardy's function Z(t) two
# ways (Euler-Maclaurin zeta and Riemann-Siegel); sign changes of Z against an argument-principle count;
# Gram's law and its first failure; Hardy's integrals; the zero count N(T) at the verified height.
import math, cmath
BERN = [1 / 6, -1 / 30, 1 / 42, -1 / 30, 5 / 66]          # Bernoulli numbers B2, B4, ..., B10
def zeta(s):                     # head sum + tail integral + end corrections (Euler-Maclaurin)
    N = max(20, int(abs(s.imag) / 2) + 10)
    z = sum(n ** -s for n in range(1, N)) + N ** (1 - s) / (s - 1) + N ** -s / 2
    r, f = s * N ** (-s - 1), 2.0
    for k, b in enumerate(BERN):
        z += b / f * r
        r *= (s + 2 * k + 1) * (s + 2 * k + 2) / N ** 2; f *= (2 * k + 3) * (2 * k + 4)
    return z
def theta(t):                    # arg of Gamma(1/4 + it/2) - (t/2) log pi, Stirling after 10 shifts
    w = 10.25 + 0.5j * t
    lg = (w - 0.5) * cmath.log(w) - w + 1 / (12 * w) - 1 / (360 * w ** 3) + 1 / (1260 * w ** 5)
    return lg.imag - sum(math.atan2(t / 2, 0.25 + k) for k in range(10)) - t / 2 * math.log(math.pi)
def theta_st(t):                 # the same angle from its large-t series
    return t / 2 * math.log(t / (2 * math.pi)) - t / 2 - math.pi / 8 + 1 / (48 * t) + 7 / (5760 * t ** 3)
def Z_em(t):                     # Z(t) = e^(i theta) zeta(1/2 + it), a complex number that should be real
    return cmath.exp(1j * theta(t)) * zeta(0.5 + 1j * t)
def Z_rs(t):                     # Riemann-Siegel: a short cosine sum plus its first correction
    a = math.sqrt(t / (2 * math.pi)); m = int(a); p = a - m; th = theta_st(t)
    main = 2 * sum(math.cos(th - t * math.log(n)) / math.sqrt(n) for n in range(1, m + 1))
    return main + (-1) ** (m - 1) * a ** -0.5 * math.cos(2 * math.pi * (p * p - p - 1 / 16)) / math.cos(2 * math.pi * p)
def changes(v): return sum(1 for a, b in zip(v, v[1:]) if a * b < 0)
def grid(f, a, b, h): return [f(a + k * h) for k in range(round((b - a) / h) + 1)]
def gram(n):                     # the height g_n where theta(g_n) = n pi, by bisection
    lo, hi = 10.0, 1e4
    for _ in range(100):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if theta(mid) < n * math.pi else (lo, mid)
    return lo
def box(T, h=0.02):              # argument principle: turns of zeta round -0.5..1.5 x 1..T
    c = [complex(-0.5, 1), complex(1.5, 1), complex(1.5, T), complex(-0.5, T), complex(-0.5, 1)]
    pts = [a + (b - a) * k / n for a, b in zip(c, c[1:]) for n in [round(abs(b - a) / h)] for k in range(n)] + [c[0]]
    v = [zeta(s) for s in pts]
    return sum(cmath.phase(w / u) for u, w in zip(v, v[1:])) / (2 * math.pi)
N0 = lambda T: theta(T) / math.pi + 1                       # smooth zero count, log-gamma road
N1 = lambda T: T / (2 * math.pi) * math.log(T / (2 * math.pi * math.e)) + 7 / 8   # simple formula
def height(n):                   # invert the smooth count: the height of zero number n
    lo, hi = 10.0, 1e14
    for _ in range(200):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if N0(mid) < n else (lo, mid)
    return lo
z_rs, z_em = grid(Z_rs, 10, 100, 0.05), [z.real for z in grid(Z_em, 10, 100, 0.05)]
coarse = [changes(grid(Z_rs, 10, 100, h)) for h in (1, 2, 3)]
inside, above = box(100), box(101.5)
ts = [10 + k * 0.37 for k in range(785)]
gap = max(abs(Z_em(t).real - Z_rs(t)) for t in ts)
imag = max(abs(Z_em(t).imag) for t in [k * 0.37 for k in range(812)])
print(f"theta(100): log-gamma road {theta(100):.6f}, Stirling road {theta_st(100):.6f}; theta/pi + 1 = {N0(100):.4f}")
print(f"Z(0) = zeta(1/2) = {Z_em(0).real:.6f}; Z real on 0..300: largest imaginary part below 1e-6: {imag < 1e-6}")
lo, hi = 14.0, 15.0                                         # first zero: bisection on the sign of Z
for _ in range(50):
    mid = (lo + hi) / 2; lo, hi = (mid, hi) if Z_em(mid).real * Z_em(lo).real > 0 else (lo, mid)
print(f"first zero, by bisection on the sign of Z between 14 and 15: {lo:.6f}")
print(f"sign changes of Z on 10..100, step 0.05: Riemann-Siegel {changes(z_rs)}, Euler-Maclaurin {changes(z_em)}")
print(f"sign changes on 10..100 at steps 1, 2, 3: {coarse[0]}, {coarse[1]}, {coarse[2]}")
print(f"argument principle, box -0.5..1.5 x 1..100: {inside:.0f} zeros in the strip; to height 101.5: {above:.0f}")
print(f"Riemann-Siegel against Euler-Maclaurin on 10..300: largest gap {gap:.4f}")
print("chart t = 0, 1, ..., 50, Z(t): " + ", ".join(f"{Z_em(t).real:.2f}" for t in range(51)))
bad = next(n for n in range(200) if (-1) ** n * Z_em(gram(n)).real < 0)
g = [gram(n) for n in (0, 1, bad - 1, bad, bad + 1)]
sc = [changes([Z_em(a + (b - a) * k / 400).real for k in range(401)]) for a, b in ((g[2], g[3]), (g[3], g[4]))]
print(f"Gram points g_0 = {g[0]:.4f}, g_1 = {g[1]:.4f}; Z(g_0) = {Z_em(g[0]).real:.4f}, Z(g_1) = {Z_em(g[1]).real:.4f}")
print(f"first failure of Gram's law: n = {bad}, g = {g[3]:.4f}, Z(g) = {Z_em(g[3]).real:.4f}; "
      f"sign changes g_{bad - 1}..g_{bad}: {sc[0]}, g_{bad}..g_{bad + 1}: {sc[1]}")
hardy = []
for T in (100, 200, 300):        # midpoint rule, step 0.05
    pts = [(k + 0.5) * 0.05 for k in range(20 * T)]
    zs = [Z_em(t) for t in pts]
    I, J, K = (0.05 * sum(v) for v in ([z.real for z in zs], [abs(z) for z in zs], [zeta(0.5 + 1j * t).real for t in pts]))
    hardy.append((T, I, J, K))
    print(f"T = {T}: integral of Z {I:.2f}; of |Z| {J:.2f}; of Re zeta(1/2 + it) {K:.2f}")
T = 3e12
print(f"N(T) at T = 3e12: theta road {N0(T):,.0f}; simple formula {N1(T):,.0f}; "
      f"without the -T/2pi term {T / (2 * math.pi) * math.log(T / (2 * math.pi)):,.0f}")
h13 = height(1e13)
print(f"Riemann-Siegel terms at T = 3e12: {int(math.sqrt(T / (2 * math.pi))):,}")
print(f"height where the smooth count reaches 10^13: {h13:,.0f}")
H, NH = 3000175332800, 12363153437138                       # verified height; its proved exact count
print(f"verified height {H:,}: smooth count {N0(H):,.0f}; proved exact count {NH:,}")
print("zeros per unit height N(T)/T: " + ", ".join(f"T = {u}: {N0(v) / v:.2f}" for u, v in (("100", 100), ("10^6", 1e6), ("3e12", 3e12))))
for name, x in (("Levinson 1974", 0.3474), ("Conrey 1989", 0.4088), ("checked to 3e12", 1.0)):
    print(f"bars, {name:16s} {'#' * round(40 * x):40s} {x:.4f}")
assert changes(z_rs) == changes(z_em) == round(inside) == round(N0(100)) == 29
assert abs(theta(100) - theta_st(100)) < 1e-9 and gap < 0.02 and imag < 1e-6     # two roads to theta, to Z
assert bad == 126 and sc == [0, 2] and abs(g[0] - 17.8456) < 1e-4 and abs(lo - 14.134725142) < 1e-8                # published Gram data
assert all(abs(K - T) < 0.05 * T and abs(I) < 0.1 * J for T, I, J, K in hardy)    # Hardy's comparison
assert abs(N0(T) - N1(T)) < 0.05 and abs(N0(100) - N1(100)) < 1e-3 and coarse[1] < 29   # log-gamma against simple formula
assert abs(N0(H) - NH) < 2 and 2.44e12 < h13 < 2.45e12      # published: exact count; Gourdon's height 2.44... x 10^12
print("ALL CHECKS PASS")
