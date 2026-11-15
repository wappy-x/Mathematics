# Three Banach theorems on a footbridge joist: recovering its load from its sag.
# Standard library only.  Every number quoted on the card is printed here.
import math

L, EI, Q, NOISE = 4.0, 326645.0, 500.0, 1e-5  # span m, stiffness N m^2, load N/m, 0.01 mm
K1 = EI * (math.pi / L) ** 4                   # load per unit sag in mode 1, N/m^2


def solve_d2(rhs, h):
    # Thomas algorithm: (v[j-1] - 2 v[j] + v[j+1]) / h^2 = rhs[j], with v = 0 at both pins
    n = len(rhs)
    c, d, v = [0.0] * n, [0.0] * n, [0.0] * n
    for j in range(n):
        piv = -2.0 - (c[j - 1] if j else 0.0)
        c[j] = 1.0 / piv
        d[j] = (rhs[j] * h * h - (d[j - 1] if j else 0.0)) / piv
    for j in range(n - 1, -1, -1):
        v[j] = d[j] - c[j] * (v[j + 1] if j < n - 1 else 0.0)
    return v


def beam(load, h):  # T: sag from load, EI w'''' = load, w = w'' = 0 at the pins
    m = solve_d2([-x for x in load], h)       # bending moment: M'' = -load
    return solve_d2([-x / EI for x in m], h)  # sag: EI w'' = -M


def d2(u, h):
    n = len(u)
    return [((u[j - 1] if j else 0.0) - 2 * u[j] + (u[j + 1] if j < n - 1 else 0.0)) / h ** 2 for j in range(n)]


def load_of(v, h):  # A: load from sag, EI times the second difference applied twice
    return [EI * x for x in d2(d2(v, h), h)]


def nrm(v, h):  # the L2 size on the grid: square root of h times the sum of squares
    return math.sqrt(h * sum(x * x for x in v))


exact = 5 * Q * L ** 4 / (384 * EI)
series = sum(4 * Q / (n * math.pi) / (EI * (n * math.pi / L) ** 4) * math.sin(n * math.pi / 2)
             for n in range(1, 2000, 2))
assert abs(series - exact) < 1e-12
print(f"joist: span {L:.0f} m, EI = {EI:.0f} N m^2, uniform load {Q:.0f} N/m")
print(f"midspan sag: 5qL^4/384EI = {exact * 1e3:.6f} mm; sine series, 1000 modes = {series * 1e3:.6f} mm")
print("   N  grid sag mm  error mm   1/||T_N|| N/m^2  ||T_N^-1|| N/m^2")
prev, chart_x, chart_lo, chart_hi = None, [], [], []
for N in (3, 7, 15, 31, 63, 127):
    h = L / (N + 1)
    w = beam([Q] * N, h)
    err = w[N // 2] - exact

    def lam(k):  # closed form: eigenvalue k of the load-from-sag matrix
        return EI * (4 / h ** 2) ** 2 * math.sin(k * math.pi / (2 * (N + 1))) ** 4
    v = [1.0] * N  # road 2: inverse power iteration through the solver finds the gentlest mode
    for _ in range(60):
        u = beam(v, h)
        s = nrm(u, h)
        v = [x / s for x in u]
    lo = 1 / nrm(beam(v, h), h)
    assert abs(lo / lam(1) - 1) < 1e-9
    top = [math.sin(N * math.pi * (j + 1) / (N + 1)) for j in range(N)]  # road 3: the stencil itself
    assert nrm([a - lam(N) * b for a, b in zip(load_of(top, h), top)], h) < 1e-9 * lam(N) * nrm(top, h)
    assert lam(N) <= 16 * EI / h ** 4  # Gershgorin: no row of the stencil sums past 16 EI / h^4
    if prev is not None:
        assert 3.9 < prev / err < 4.1  # the grid error falls 4 times per halving of the spacing
    prev = err
    chart_x.append(f"{math.log10(N):.3f}")
    chart_lo.append(f"{math.log10(lo):.3f}")
    chart_hi.append(f"{math.log10(lam(N)):.3f}")
    print(f"{N:4d} {w[N // 2] * 1e3:11.6f} {err * 1e3:10.6f} {lo:16.1f} {lam(N):17.1f}")
assert abs(lo / K1 - 1) < 1e-3
print(f"limit: 1/||T|| = EI (pi/L)^4 = {K1:.1f} N/m^2, so ||T|| = {1e6 / K1:.4f} micrometres of sag per N/m")
print(f"chart: log10 N {', '.join(chart_x)}")
print(f"chart: log10 1/||T_N|| {', '.join(chart_lo)}")
print(f"chart: log10 ||T_N^-1|| {', '.join(chart_hi)}")
for n in (1, 2, 5, 10, 20):
    print(f"0.01 mm of sag noise in mode {n:2d} -> load error {NOISE * K1 * n ** 4:10.1f} N/m")

# uniform boundedness: R_N keeps N sine modes of the sag and multiplies mode n by EI (n pi / L)^4
print(f"noisy sag: mode n has amplitude 0.01 mm / n; L2 size {NOISE * math.sqrt(L / 2 * math.pi ** 2 / 6) * 1e3:.6f} mm")
print("   N      ||R_N|| N/m^2  ||R_N w_noisy|| N/m  ||R_N w_true - q|| N/m")
for N in (1, 5, 10, 20, 40, 80):
    s6 = N * (N + 1) * (2 * N + 1) * (3 * N ** 4 + 6 * N ** 3 - 3 * N + 1) // 42  # sum of n^6, exact
    noisy = math.sqrt(L / 2 * sum((NOISE / n * K1 * n ** 4) ** 2 for n in range(1, N + 1)))
    assert abs(noisy / (NOISE * K1 * math.sqrt(L / 2 * s6)) - 1) < 1e-12
    gap = math.sqrt(Q * Q * L - L / 2 * sum((4 * Q / (n * math.pi)) ** 2 for n in range(1, N + 1, 2)))
    if N == 10:  # road 2 for the gap: midpoint rule on (q - its first ten sine modes)^2 over the span
        M = 20000
        quad = sum((Q - sum(4 * Q / (n * math.pi) * math.sin(n * math.pi * (i + 0.5) / M)
                            for n in range(1, 11, 2))) ** 2 for i in range(M)) * L / M
        assert abs(math.sqrt(quad) / gap - 1) < 1e-6
    print(f"{N:4d} {K1 * N ** 4:18.1f} {noisy:20.1f} {gap:22.1f}")

# closed graph: ripples w_n = (0.01 mm / n) sin(n pi x / L) shrink, their loads grow
for n in (1, 10, 100):
    size = NOISE / n * math.sqrt(L / 2)
    print(f"ripple n = {n:3d}: ||w_n|| = {size * 1e3:.6f} mm, ||A w_n|| = {size * K1 * n ** 4:.1f} N/m")
h = L / 128
rip = [NOISE / 10 * math.sin(10 * math.pi * (j + 1) / 128) for j in range(127)]
assert abs(nrm(load_of(rip, h), h) / nrm(rip, h) / (K1 * 10 ** 4) - 1) < 0.02  # grid agrees within 2%

# completeness dropped: finite sequences only, not a Banach space under either norm
ones = [1.0] * 1000
print(f"finite sequences, 1000 ones: max norm {max(ones):.0f}, sum norm {sum(ones):.0f}, inverse gain {sum(ones) / max(ones):.0f}")
f = lambda k, x: k * x[k - 1]  # f_k(x) = k x_k on a finite sequence x
gains = [abs(f(k, [0.0] * (k - 1) + [1.0])) for k in (1, 10, 100)]  # at e_k, of max norm 1
assert gains == [1, 10, 100]  # and |k x_k| <= k max |x|, so ||f_k|| = k
print(f"f_k(x) = k x_k, max norm: |f_k(e_k)| = {', '.join(f'{g:.0f}' for g in gains)} at k = 1, 10, 100, so ||f_k|| = k")
tops = [max(abs(f(k, x)) for k in range(1, len(x) + 1)) for x in ([0.5, -0.25, 0.125], [1.0] * 10, [0.0] * 99 + [1.0])]
print(f"  sup over k of |f_k(x)|: {tops[0]:.3f} at (0.5, -0.25, 0.125); {tops[1]:.3f} at ten ones; {tops[2]:.3f} at e_100")
print("ALL CHECKS PASS")
