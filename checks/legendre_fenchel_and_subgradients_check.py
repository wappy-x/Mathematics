# The slope transform -- the check behind the card.  Standard library only.
# A washing line 2 m long at tension 100 N; a 10 N towel hangs from its middle.  A shape is the
# sag (m, down positive) at N equally spaced points; a load is a list of forces (N) there.
# Energy f(u) = T/(2h) x (sum of squared steps), in J.  Conjugate f*(F) = largest work minus energy.
# Roads: closed forms; brute-force grids; a tridiagonal solve against Green's function; the
# energy rebuilt from the conjugate alone by conjugate-gradient ascent.
import math

T, L, P, C = 100.0, 2.0, 10.0, 0.03          # tension N, length m, towel N, fence depth m

def k1(t): return 4 * t / L                  # one point in the middle: spring rate, N/m

def f1(u, t=T, c=None):                      # energy of the one-point line; +inf past the fence
    return math.inf if c is not None and u > c + 1e-12 else 0.5 * k1(t) * u * u

def fstar1(F, t=T, c=None):                  # its conjugate, closed form
    k = k1(t)
    return F * F / (2 * k) if c is None or F <= k * c else c * F - 0.5 * k * c * c

def grid_max(fun, lo, hi, n):                # brute force: largest value on an even grid
    best, arg = -math.inf, lo
    for i in range(n + 1):
        x = lo + (hi - lo) * i / n
        v = fun(x)
        if v > best: best, arg = v, x
    return best, arg

def one_point(t, p, c):                      # sag, conjugate, spring force, fence force
    k = k1(t); s = min(p / k, c)
    return s, fstar1(p, t, c), k * s, p - k * s

# ---- one point: compute the conjugate, rebuild the energy, read the slopes at the fence ----
print(f"one point: spring rate {k1(T):.4f} N/m, towel {P:.4f} N")
g, s = grid_max(lambda u: P * u - f1(u), -0.2, 0.2, 400000)
print(f"conjugate at 10 N: formula {fstar1(P):.6f} J, grid {g:.6f} J at sag {s:.6f} m")
assert abs(g - P * P / (2 * k1(T))) < 1e-9 and abs(s - 0.05) < 1e-6
b, _ = grid_max(lambda F: 0.05 * F - fstar1(F), 0.0, 40.0, 400000)
print(f"energy at 5 cm: rebuilt from the conjugate {b:.6f} J, direct {f1(0.05):.6f} J")
assert abs(b - f1(0.05)) < 1e-9
print(f"Fenchel-Young: {f1(0.05):.6f} + {fstar1(P):.6f} = {f1(0.05) + fstar1(P):.6f} = 10 x 0.05")
gc, sc = grid_max(lambda u: P * u - f1(u, c=C), -0.2, 0.2, 400000)
print(f"fence at 3 cm, conjugate at 10 N: formula {fstar1(P, c=C):.6f} J, grid {gc:.6f} J at sag {sc:.6f} m")
assert abs(gc - fstar1(P, c=C)) < 1e-9
ties = [F / 2 for F in range(41) if abs(f1(C) + fstar1(F / 2, c=C) - C * F / 2) < 1e-12]
print(f"slopes at the fence, read from the conjugate: {len(ties)} of 41 loads tie, {min(ties):.4f} N to {max(ties):.4f} N")
assert ties == [F / 2 for F in range(12, 41)]
d = 1e-7; left = (f1(C) - f1(C - d)) / d
print(f"left slope at 3 cm {left:.4f} N; right slope: none (the fence); gap at 5 N {f1(C) + fstar1(5, c=C) - C * 5:.6f} J")
assert abs(left - k1(T) * C) < 1e-4
_, _, sp, fe = one_point(T, P, C)
print(f"towel 10 N at the fence: spring {sp:.4f} N, fence {fe:.4f} N")
print(f"Green's function G(1, 1) {(L - 1) / (T * L):.4f} m/N; energy at the fence {f1(C):.4f} J; conjugate's slope past 6 N {(fstar1(12, c=C) - fstar1(10, c=C)) / 2:.4f} m")
for top in (100.0, 1000.0):
    r, _ = grid_max(lambda F: 0.04 * F - fstar1(F, c=C), 0.0, top, 100000)
    print(f"rebuilt at 4 cm (past the fence), loads up to {top:.0f} N: {r:.4f} J")
    assert abs(r - (0.01 * top + 0.09)) < 1e-9
r, _ = grid_max(lambda F: 0.02 * F - fstar1(F, c=C), -20.0, 20.0, 400000)
print(f"rebuilt at 2 cm: {r:.6f} J, direct {f1(0.02):.6f} J")
assert abs(r - f1(0.02)) < 1e-9
print("chart F 0..12:", " ".join(f"{fstar1(2.0 * i):.2f}" for i in range(7)), "|",
      " ".join(f"{fstar1(2.0 * i, c=C):.2f}" for i in range(7)))
hk = lambda u: 100 * min(u * u, (u - 0.06) ** 2)          # two rest positions: not convex
cj = lambda F: grid_max(lambda u: F * u - hk(u), -0.2, 0.26, 4600)[0]
bb, _ = grid_max(lambda F: 0.03 * F - cj(F), -20.0, 20.0, 200)
print(f"two rest positions, at 3 cm: energy {hk(0.03):.4f} J, rebuilt {bb:.4f} J")
assert abs(bb) < 1e-9

# ---- N points: the same line, finer and finer ----
def solve(N, F):                             # Thomas algorithm for K u = F, K = (T/h) tridiag(-1, 2, -1)
    a = T * (N + 1) / L; cp, dp = [0.0] * N, [0.0] * N
    for i in range(N):
        m = 2 * a + (a * cp[i - 1] if i else 0.0)
        cp[i] = -a / m; dp[i] = (F[i] + (a * dp[i - 1] if i else 0.0)) / m
    u = [0.0] * N
    for i in range(N - 1, -1, -1): u[i] = dp[i] - (cp[i] * u[i + 1] if i < N - 1 else 0.0)
    return u

def dot(x, y): return sum(p * q for p, q in zip(x, y))
def fstar(N, F): return 0.5 * dot(F, solve(N, F))            # the conjugate, via the equilibrium sag
def energy(N, u):
    w = [0.0] + u + [0.0]; h = L / (N + 1)
    return T / (2 * h) * sum((w[i + 1] - w[i]) ** 2 for i in range(N + 1))
def kslope(N, u):                            # size of K u as a load density in L2
    w = [0.0] + u + [0.0]; h = L / (N + 1)
    return math.sqrt(sum((T / h * (2 * w[i] - w[i - 1] - w[i + 1])) ** 2 for i in range(1, N + 1)) / h)

def rebuild(N, u):                           # max over loads of work - f*: conjugate gradients
    F = [0.0] * N; r = u[:]; p = r[:]; rr = dot(r, r)
    for _ in range(3 * N + 10):
        if rr < 1e-30 * dot(u, u): break
        Mp = solve(N, p); al = rr / dot(p, Mp)
        F = [x + al * y for x, y in zip(F, p)]; r = [x - al * y for x, y in zip(r, Mp)]
        rn = dot(r, r); p = [x + rn / rr * y for x, y in zip(r, p)]; rr = rn
    return dot(F, u) - fstar(N, F)

print("N, h; tent: energy, rebuilt, slope size; step: energy, rebuilt; sine: energy, rebuilt, slope size")
for N in (1, 3, 7, 15, 31, 63, 127):
    h = L / (N + 1); xs = [h * (i + 1) for i in range(N)]
    towel = [P if i == N // 2 else 0.0 for i in range(N)]
    tent = solve(N, towel)
    assert max(abs(tent[i] - P * min(x, L - x) / (T * L)) for i, x in enumerate(xs)) < 1e-12  # Green's function
    assert abs(fstar(N, towel) - 0.25) < 1e-12 and abs(energy(N, tent) + fstar(N, towel) - dot(towel, tent)) < 1e-12
    step = [0.05 if 0.5 <= x <= 1.5 else 0.0 for x in xs]
    sine = [0.05 * math.sin(math.pi * x / 2) for x in xs]
    row = []
    for u, exact in ((tent, 0.25), (step, 0.25 / h), (sine, 0.5 * T * 0.01 * math.sin(math.pi * h / 4) ** 2 / h ** 2)):
        e, rb = energy(N, u), rebuild(N, u)
        assert abs(e - exact) < 1e-9 * exact and abs(rb - e) < 1e-8 * e
        row += [e, rb]
    st, ss = kslope(N, tent), kslope(N, sine)
    assert abs(st - P / math.sqrt(h)) < 1e-9 * st and abs(ss - 0.2 * T * math.sin(math.pi * h / 4) ** 2 / h ** 2) < 1e-9 * ss
    print(f"{N:4d} {h:.4f}  {row[0]:.6f} {row[1]:.6f} {st:8.4f}  {row[2]:.6f} {row[3]:.6f}  {row[4]:.6f} {row[5]:.6f} {ss:8.4f}")
spread = [P / 7] * 7; tent7 = solve(7, [P if i == 3 else 0.0 for i in range(7)])
print(f"N=7: towel spread evenly is not a slope at the tent: gap {energy(7, tent7) + fstar(7, spread) - dot(spread, tent7):.6f} J")
print(f"limits: sine energy {T * 0.05 ** 2 * math.pi ** 2 / 8:.6f} J, sine slope size {T * 0.05 * math.pi ** 2 / 4:.4f}; tent slope grows like 10/sqrt(h)")
for t, p, c in ((T, 16.0, C), (200.0, P, C), (T, P, 0.06)):
    s, fs, sp, fe = one_point(t, p, c)
    print(f"try T={t:.0f} N, towel {p:.0f} N, fence {100 * c:.0f} cm: sag {s:.4f} m, conjugate {fs:.4f} J, spring {sp:.4f} N, fence {fe:.4f} N")
print("ALL CHECKS PASS")
