# Wave energy and finite speed on a 65 cm guitar string, tapped 5 cm from the bridge.
# Roads: d'Alembert with mirror images at the ends; the closed-form energy; a sine-mode
# series; the energy in a shrinking window against the leak formula.
from math import pi, sin, cos, sqrt

L, F1 = 0.65, 329.63                   # string length, m; open high E string, Hz
C = 2 * L * F1                         # wave speed, m/s
RHO = 7850 * pi * 0.000127 ** 2        # mass per metre, kg/m: steel wire 0.254 mm across
TEN = RHO * C * C                      # tension, N
EI = 2e11 * pi * 0.000127 ** 4 / 4     # bending stiffness of that wire, N m^2
XC, A, V0 = 0.05, 0.01, 0.5            # tap centre and half-width, m; peak speed, m/s
XP = 0.325                             # pickup point at the 12th fret, m
MS, UJ = 1e-3, 1e-6                    # one millisecond, one microjoule

def gamma(s, xc):                      # integral of the tap's speed from 0 to s
    if s <= xc - A: return 0.0
    if s >= xc + A: return V0 * A
    return V0 * ((s - xc + A) / 2 + A / (2 * pi) * sin(pi * (s - xc) / A))

def u(x, t, xc=XC):                    # d'Alembert, ends fixed by odd mirror images
    def big_g(s):
        s = (s + L) % (2 * L) - L
        return gamma(abs(s), xc)
    return (big_g(x + C * t) - big_g(x - C * t)) / (2 * C)

def rates(x, t, xc=XC, h=1e-6):        # speed u_t and slope u_x by centred differences
    ut = (u(x, t + h / C, xc) - u(x, t - h / C, xc)) / (2 * h / C)
    ux = (u(x + h, t, xc) - u(x - h, t, xc)) / (2 * h)
    return ut, ux

def energy(t, lo=0.0, hi=L, n=6500, xc=XC):   # (kinetic, stretch) in J, Simpson's rule
    k = p = 0.0
    if hi <= lo: return 0.0, 0.0
    step = (hi - lo) / n
    for i in range(n + 1):
        w = 1 if i in (0, n) else (4 if i % 2 else 2)
        ut, ux = rates(lo + i * step, t, xc)
        k += w * RHO / 2 * ut * ut
        p += w * TEN / 2 * ux * ux
    return k * step / 3, p * step / 3

def mode_coef(n):                      # b_n = (2/L) * integral of g sin(n pi x / L)
    m, h, s = 400, 2 * A / 400, 0.0
    for i in range(m + 1):
        x = XC - A + i * h
        w = 1 if i in (0, m) else (4 if i % 2 else 2)
        s += w * V0 * (1 + cos(pi * (x - XC) / A)) / 2 * sin(n * pi * x / L)
    return 2 / L * s * h / 3

def series_u(x, t, nmax, stiff):       # sine modes; a stiff wire has faster short waves
    s = 0.0
    for n in range(1, nmax + 1):
        k = n * pi / L
        w = C * k * sqrt(1 + stiff * EI / TEN * k * k)
        s += B[n - 1] / w * sin(w * t) * sin(k * x)
    return s

print(f"string: c = {C:.3f} m/s, rho = {RHO * 1e3:.4f} g/m, tension = {TEN:.2f} N, EI = {EI:.2e} N m^2")
E0 = 3 * RHO * V0 ** 2 * A / 8
print(f"energy, closed form 3 rho v0^2 a / 8 = {E0 / UJ:.6f} uJ")
B = [mode_coef(n) for n in range(1, 2001)]
for nmax in (200, 2000):
    em = sum(RHO * L * b * b / 4 for b in B[:nmax])
    print(f"energy, sum over {nmax} modes = {em / UJ:.6f} uJ, tail {(E0 - em) / UJ:.2e} uJ")
print("time ms | kinetic uJ | stretch uJ | total uJ")
totals, split = [], {}
for j in range(13):
    k, p = energy(0.02 * j * MS)
    totals.append(k + p); split[j] = (k, p)
    print(f"{0.02 * j:7.2f} | {k / UJ:10.6f} | {p / UJ:10.6f} | {(k + p) / UJ:8.6f}")
k117, p117 = energy(0.1167 * MS)
print(f"mid-reflection 0.1167 ms: kinetic {k117 / UJ:.6f} uJ, stretch {p117 / UJ:.6f} uJ")
print("bridge window [0, 10 cm - c t]: energy inside")
win = []
for j in range(12):
    t = 0.02 * j * MS
    k, p = energy(t, 0.0, 0.10 - C * t, 2000)
    win.append(k + p)
    print(f"  t = {0.02 * j:.2f} ms: right wall {(0.10 - C * t) * 100:6.3f} cm, energy {(k + p) / UJ:.6f} uJ")
tl, d = 0.058 * MS, 1e-5 * MS
slope = (sum(energy(tl + d, 0, 0.10 - C * (tl + d), 2000)) - sum(energy(tl - d, 0, 0.10 - C * (tl - d), 2000))) / (2 * d)
ut, ux = rates(0.10 - C * tl, tl)
leak = -RHO * C / 2 * (ut - C * ux) ** 2
print(f"at 0.058 ms: dE/dt = {slope * MS / UJ:.4f} uJ/ms; leak formula -(rho c/2)(u_t - c u_x)^2 = {leak * MS / UJ:.4f} uJ/ms")
T0 = 0.6 * MS
print(f"pickup cone to (32.5 cm, 0.60 ms): base {(XP - C * T0) * 100:.2f} to {(XP + C * T0) * 100:.2f} cm")
cone = [sum(energy(t * MS, XP - C * (T0 - t * MS), XP + C * (T0 - t * MS), 2000)) for t in (0.0, 0.3, 0.55)]
print("  energy inside at 0, 0.30, 0.55 ms: " + ", ".join(f"{e / UJ:.6f}" for e in cone) + " uJ")
print(f"  u(32.5 cm, 0.60 ms) = {u(XP, T0) * 1e6:.6f} um; first motion at {(XP - XC - A) / C / MS:.4f} ms")
late = series_u(XP, 0.65 * MS, 2000, 0)
print(f"  u(32.5 cm, 0.65 ms) = {u(XP, 0.65 * MS) * 1e6:.6f} um by d'Alembert, {late * 1e6:.6f} um by 2000 modes")
d1, d2 = u(XP, 0.45 * MS, 0.55), u(XP, 0.55 * MS, 0.55)
print(f"second tap at 55 cm changes u(32.5 cm) by {d1 * 1e6:.6f} um at 0.45 ms, {d2 * 1e6:.6f} um at 0.55 ms; "
      f"front {(0.54 - XP) / C / MS:.4f} ms")
print(f"wrong: kinetic energy only, at 0.20 ms = {split[10][0] / UJ:.6f} uJ")
print(f"wrong: arrival timed from the tap centre = {(XP - XC) / C / MS:.4f} ms")
slow = sum(energy(0.2 * MS, XP - C * T0 + C / 2 * 0.2 * MS, XP + C * T0 - C / 2 * 0.2 * MS, 2000))
print(f"wrong: window shrinking at c/2, energy inside at 0.20 ms = {slow / UJ:.6f} uJ")
s1, s2 = series_u(XP, 0.55 * MS, 1000, 1), series_u(XP, 0.55 * MS, 2000, 1)
ideal = series_u(XP, 0.55 * MS, 2000, 0)
print(f"stiff wire, u(32.5 cm, 0.55 ms): {s1 * 1e6:.6f} um (1000 modes), {s2 * 1e6:.6f} um (2000 modes); "
      f"ideal series {abs(ideal) * 1e6:.6f} um")
SX, ST = 6.0, 6.0 * C / 10             # figure: px per cm, px per ms (45-degree characteristics)
fx = lambda cm: 50 + SX * cm
fy = lambda ms: 250 - ST * ms
print(f"figure, px: scale {SX:.0f} per cm, {ST:.1f} per ms; tap ({fx(4):.1f}..{fx(6):.1f}, 250); P ({fx(32.5):.1f}, {fy(0.6):.1f}); "
      f"base ({fx((XP - C * T0) * 100):.1f}..{fx((XP + C * T0) * 100):.1f}); bridge apex y {fy(0.10 / C / MS):.1f}; "
      f"top y {fy(0.7):.1f}")
assert abs(totals[0] - E0) < 1e-6 * E0, "energy from the motion must match the closed form"
assert max(abs(e - E0) for e in totals) < 1e-6 * E0, "energy must stay fixed"
assert abs(sum(RHO * L * b * b / 4 for b in B) - E0) < 1e-6 * E0, "modes must carry the same energy"
assert all(b <= a + 1e-9 * E0 for a, b in zip(win, win[1:])), "window energy must never rise"
assert abs(slope - leak) < 1e-4 * abs(leak), "rate must equal the leak formula"
assert max(cone) < 1e-12 * E0 and abs(u(XP, T0)) + abs(d1) < 1e-15, "empty cone must stay empty"
assert abs(u(XP, 0.65 * MS) - late) < 1e-6 * abs(late), "d'Alembert and modes must agree after the front"
assert slow > 0.4 * E0 and abs(s2) > 1e3 * abs(ideal), "hypotheses failing must show"
print("ALL CHECKS PASS")
