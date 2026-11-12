# Von Neumann analysis and the CFL condition -- the check behind the card.  Standard
# library only.  A 1 m steel bar, ends held at 0, nodes h = 1 cm apart (j = 0..100).
# Road 1: run each scheme in a loop.  Road 2: feed one wave e^(i xi j h) into the
# scheme's stencil, read off g, and project the loop's output onto that wave.
# Road 3: closed forms, the bar's exact Fourier series and d'Alembert's formula.
import math, cmath
H, J, ALPHA, C = 0.01, 100, 1.25e-5, 5000.0      # m, cells, m^2/s (steel), m/s (sound)
PHI = [k * math.pi / J for k in range(1, J)]     # xi*h for the bar's 99 sine modes
S2 = lambda p: math.sin(p / 2) ** 2

def tot(xs):                   # plain left-to-right sum, the same in both languages
    s = 0.0
    for x in xs:
        s += x
    return s

def poly(w, phi):              # sum of w[m] e^(i m phi): the stencil seen by one wave
    return complex(tot(a * math.cos(m * phi) for m, a in w),
                   tot(a * math.sin(m * phi) for m, a in w))

def g_feed(st, phi):           # largest |g| that solves the stencil's equation
    if len(st) == 2:           # two levels:   new(phi) g = old(phi)
        return abs(poly(st[1], phi) / poly(st[0], phi))
    b = poly(st[2], phi)       # three levels: g^2 = mid(phi) g + old(phi)
    d = cmath.sqrt(b * b + 4 * poly(st[1], phi))
    return max(abs((b + d) / 2), abs((b - d) / 2))

def heat(r, steps):            # explicit heat step; a torch has heated the middle 10 cm
    U = [100.0 if 46 <= j <= 54 else 50.0 if j in (45, 55) else 0.0 for j in range(J + 1)]
    hist, prev = [], U
    for n in range(steps + 1):
        if n % 30 == 0:
            hist.append(math.log10(max(abs(u) for u in U)))
        if n < steps:
            prev = U
            U = [0.0] + [r * U[j - 1] + (1 - 2 * r) * U[j] + r * U[j + 1] for j in range(1, J)] + [0.0]
    return U, prev, hist

def mode(U, k):                # sine coefficient b_k of the readings U
    return 2 / J * tot(U[j] * math.sin(k * math.pi * j / J) for j in range(1, J))

def tent(x, c0, w):            # the pulse, extended odd and 2-periodic so the ends stay at 0
    x = (x + 1) % 2 - 1
    return max(0.0, 1 - abs(x - c0) / w) if x >= 0 else -max(0.0, 1 - abs(-x - c0) / w)

def exact_wave(j, t, c0, w):   # d'Alembert: half the pulse runs each way
    return (tent(j * H - C * t, c0, w) + tent(j * H + C * t, c0, w)) / 2 + 0.0

def wave(nu, steps, c0, w):    # leapfrog for u_tt = c^2 u_xx, bar starting at rest
    U0 = [tent(j * H, c0, w) for j in range(J + 1)]
    d2 = lambda U, j: U[j - 1] - 2 * U[j] + U[j + 1]
    U = [0.0] + [U0[j] + nu * nu / 2 * d2(U0, j) for j in range(1, J)] + [0.0]
    for _ in range(steps - 1):
        U0, U = U, [0.0] + [2 * U[j] - U0[j] + nu * nu * d2(U, j) for j in range(1, J)] + [0.0]
    return U0, U

ftcs = lambda r: ([(0, 1.0)], [(-1, r), (0, 1 - 2 * r), (1, r)])
print("== heat: 1 m steel bar, ends at 0 C, alpha = 1.25e-5 m^2/s, h = 0.01 m, middle 10 cm at 100 C ==")
print(f"limit h^2/(2 alpha) = {H * H / (2 * ALPHA):.4f} s; on this grid exactly r <= "
      f"{1 / (2 * S2(PHI[-1])):.6f}, dt <= {H * H / (2 * ALPHA * S2(PHI[-1])):.5f} s")
chart = []
for r in (0.4, 0.5, 0.51):
    dt, gk = r * H * H / ALPHA, [1 - 4 * r * S2(p) for p in PHI]
    assert max(abs(abs(a) - g_feed(ftcs(r), p)) for a, p in zip(gk, PHI)) < 1e-12  # fed = formula
    U, prev, hist = heat(r, 300)
    chart.append(hist)
    U0 = heat(r, 0)[0]
    spect = tot(mode(U0, k) * gk[k - 1] ** 300 * math.sin(k * math.pi / 2) for k in range(1, J))
    assert abs(spect - U[50]) < 1e-9 * max(1.0, abs(U[50]))         # loop = sum of waves times g^n
    k = 99 if r > 0.45 else 1                                       # a mode still above round-off
    ratio = mode(U, k) / mode(prev, k)
    assert abs(ratio - gk[k - 1]) < 1e-9                            # measured growth = predicted g
    t = 300 * dt
    true = tot(200 / (k * math.pi) * (math.cos(0.45 * k * math.pi) - math.cos(0.55 * k * math.pi))
               * math.exp(-ALPHA * (k * math.pi) ** 2 * t) * math.sin(k * math.pi / 2) for k in range(1, 400))
    print(f"r = {r:.2f}: dt = {dt:.2f} s; g(k=1) = {gk[0]:.6f}, g(k=99) = {gk[98]:.6f}, measured g(k={k}) = {ratio:.6f}")
    print(f"  300 steps = {t:.0f} s: middle {U[50]:.4f} C, true bar {true:.4f} C, true error {U[50] - true:.4f} C")
    assert r > 0.5 or abs(U[50] - true) < 0.03                      # stable grid tracks the true bar
assert U[50] > 1000 and abs(gk[0]) < 1                              # r = 0.51: k = 1 alone looks safe
print(f"r = 0.51 at 1224 s: neighbour reads {U[49]:.1f} C")
for r, h in zip(("0.40", "0.50", "0.51"), chart):
    print(f"chart log10 max|U|, r = {r}, n = 0..300 by 30:", " ".join(f"{v:.3f}" for v in h))

print("== max |g| over the 99 modes: one wave fed through each stencil ==")
def lf(nu, p):                 # closed form for leapfrog: roots of g^2 - 2 beta g + 1 = 0
    beta = 1 - 2 * nu * nu * S2(p)
    return max(1.0, abs(beta) + math.sqrt(max(0.0, beta * beta - 1)))
rows = [("heat explicit", "r = 0.51", ftcs(0.51), lambda p: abs(1 - 2.04 * S2(p))),
        ("heat implicit", "r = 5", ([(-1, -5.0), (0, 11.0), (1, -5.0)], [(0, 1.0)]), lambda p: 1 / (1 + 20 * S2(p)))]
for nu, s in ((0.5, "nu = 0.5"), (1.2, "nu = 1.2")):
    rows += [("transport centred", s, ([(0, 1.0)], [(-1, nu / 2), (0, 1.0), (1, -nu / 2)]),
              lambda p, nu=nu: math.sqrt(1 + (nu * math.sin(p)) ** 2)),
             ("transport upwind", s, ([(0, 1.0)], [(-1, nu), (0, 1 - nu)]),
              lambda p, nu=nu: math.sqrt(1 - 4 * nu * (1 - nu) * S2(p))),
             ("transport Lax-Wendroff", s, ([(0, 1.0)], [(-1, (nu * nu + nu) / 2), (0, 1 - nu * nu), (1, (nu * nu - nu) / 2)]),
              lambda p, nu=nu: math.sqrt(1 - 4 * nu * nu * (1 - nu * nu) * S2(p) ** 2))]
for nu, s in ((0.9, "nu = 0.9"), (1.0, "nu = 1"), (1.02, "nu = 1.02")):
    rows.append(("wave leapfrog", s, ([(0, 1.0)], [(0, -1.0)], [(-1, nu * nu), (0, 2 - 2 * nu * nu), (1, nu * nu)]),
                 lambda p, nu=nu: lf(nu, p)))
for name, s, st, closed in rows:
    mx = max(g_feed(st, p) for p in PHI)
    assert abs(mx - max(closed(p) for p in PHI)) < 1e-9             # stencil fed a wave = closed form
    print(f"{name:22} {s:9} max|g| = {mx:.6f}  {'stable' if mx <= 1 + 1e-12 else 'grows'}")

print("== sound in the bar: c = 5000 m/s, tent pulse 1 um high, 10 cm wide ==")
print(f"CFL limit h/c = {H / C * 1e6:.2f} us; on this grid exactly nu <= {1 / math.sin(PHI[-1] / 2):.7f}")
for nu, s, n in ((0.9, "0.9", 100), (1.0, "1", 100), (1.02, "1.02", 50)):
    prev, U = wave(nu, n, 0.5, 0.05)
    t = n * nu * H / C
    err = max(abs(U[j] - exact_wave(j, t, 0.5, 0.05)) for j in range(J + 1))
    print(f"nu = {s}: dt = {nu * H / C * 1e6:.2f} us, {n} steps = {t * 1e6:.0f} us; middle {U[50]:.6f} um,"
          f" exact {exact_wave(50, t, 0.5, 0.05):.6f}; worst true error {err:.3e} um")
assert err > 1e5                                                    # nu = 1.02 has blown up
b = 1 - 2 * 1.02 * 1.02 * S2(PHI[-1])
ratio = mode(U, 99) / mode(prev, 99)
print(f"nu = 1.02: mode k = 99 grows by {ratio:.6f} a step; root of g^2 - 2 beta g + 1 = {b - math.sqrt(b * b - 1):.6f}")
assert abs(ratio - (b - math.sqrt(b * b - 1))) < 1e-6
prev, U = wave(1.0, 70, 0.5, 0.05)
assert max(abs(U[j] - exact_wave(j, 1.4e-4, 0.5, 0.05)) for j in range(J + 1)) < 1e-12   # nu = 1: exact at 70 steps too
U = wave(2.0, 5, 0.40, 0.03)[1]                                     # pulse outside the stencil's reach
ex = exact_wave(50, 5 * 2.0 * H / C, 0.40, 0.03)
print(f"nu = 2 (dt = {2.0 * H / C * 1e6:.2f} us), pulse at 0.40 m: after 5 steps (20 us) the middle computes {U[50]:.6f} um; exact {ex:.6f} um")
assert U[50] == 0.0 and ex > 0.4
for hh in (0.01, 0.001):
    dt = 0.5 * hh * hh / ALPHA
    print(f"heat, r = 0.5, h = {hh} m: dt = {dt:.3f} s, reach h/dt = {hh / dt * 100:.2f} cm/s, "
          f"1200 s costs {round(1200 / dt) * (round(1 / hh) - 1) * 5} flops")
print("figure, 5 steps: stencil reach 5 cells; sound reach 2.5 cells at nu = 0.5, 10 cells at nu = 2")
print("ALL CHECKS PASS")
