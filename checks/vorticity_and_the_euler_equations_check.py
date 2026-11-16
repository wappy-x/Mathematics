# Vorticity and the Euler equations -- the check behind the card.  Standard library only.
# Bath plug: a swirl of circulation G in water, stretched along its axis at rate A
# by the flow into the drain (the Burgers vortex).  Smoke ring: a thin ring that
# widens as it nears a wall.  Roads: closed forms; a radial grid stepped by RK4;
# centred-difference residuals; quadrature; RK4 along a particle of the ring.
import math

NU, A, G, S0, RHO = 1.0e-6, 0.04, 0.01, 2.5e-3, 1000.0  # m^2/s, 1/s, m^2/s, m^2, kg/m^3

def core2(t, nu=NU): return 4 * nu / A + (S0 - 4 * nu / A) * math.exp(-A * t)  # delta^2
def om(r, s, g=G): return g / (math.pi * s) * math.exp(-r * r / s)              # vorticity
def swirl(r, s): return G / (2 * math.pi * r) * (1 - math.exp(-r * r / s))      # u_theta
def sci(v):
    e = math.floor(math.log10(abs(v))); m = v / 10 ** e
    return f"{m:.3f}e{e:+03d}"

def resid(x, y, h, s):               # steady equation u.grad(w) - A w - NU lap(w), centred
    w = lambda X, Y: om(math.hypot(X, Y), s)
    r = math.hypot(x, y); v = swirl(r, s)
    ux, uy = -A * x / 2 - v * y / r, -A * y / 2 + v * x / r
    wx = (w(x + h, y) - w(x - h, y)) / (2 * h); wy = (w(x, y + h) - w(x, y - h)) / (2 * h)
    lap = (w(x + h, y) + w(x - h, y) + w(x, y + h) + w(x, y - h) - 4 * w(x, y)) / h ** 2
    return ux * wx + uy * wy - A * w(x, y) - NU * lap, NU * lap

def grid(dr, T=60.0, dt=0.1, R=0.25):  # w_t = (A r/2) w_r + A w + NU (w_rr + w_r/r)
    n = round(R / dr); w = [om(i * dr, S0) for i in range(n + 1)]
    def rate(w):
        d = [0.0] * (n + 1); d[0] = A * w[0] + 4 * NU * (w[1] - w[0]) / dr ** 2
        for i in range(1, n):
            r = i * dr; wr = (w[i + 1] - w[i - 1]) / (2 * dr)
            d[i] = A * r / 2 * wr + A * w[i] + NU * ((w[i + 1] - 2 * w[i] + w[i - 1]) / dr ** 2 + wr / r)
        return d
    for _ in range(round(T / dt)):
        k1 = rate(w); k2 = rate([a + dt / 2 * b for a, b in zip(w, k1)])
        k3 = rate([a + dt / 2 * b for a, b in zip(w, k2)]); k4 = rate([a + dt * b for a, b in zip(w, k3)])
        w = [a + dt / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(w, k1, k2, k3, k4)]
    err = max(abs(w[i] - om(i * dr, core2(T))) for i in range(n + 1))
    return err, sum(w[i] * 2 * math.pi * i * dr * dr for i in range(1, n))

s = 4 * NU / A; d = math.sqrt(s); w0 = om(0.0, s)
lo, hi = 1.0, 2.0                    # peak swirl where e^x = 1 + 2x, x = r^2/delta^2
for _ in range(60):
    mid = (lo + hi) / 2; lo, hi = (mid, hi) if math.exp(mid) - 1 - 2 * mid < 0 else (lo, mid)
rs = d * math.sqrt(lo); vs = swirl(rs, s)
vscan = max(swirl(0.005 + i * 1e-6, s) for i in range(15001))
print("BATH PLUG, steady: G = 0.01 m^2/s, stretching A = 0.04 1/s, water NU = 1e-6 m^2/s")
print(f"  core radius delta = sqrt(4 NU/A) = {d * 1000:.2f} mm; peak vorticity {w0:.2f} 1/s")
print(f"  water on the axis spins at {w0 / 2:.2f} rad/s = {w0 / (4 * math.pi):.2f} turns/s")
print(f"  fastest swirl {vs:.4f} m/s at r = {rs * 1000:.2f} mm (scan: {vscan:.4f} m/s)")
_, lap0 = resid(1e-9, 0.0, 1e-4, s)
print(f"  budget on the axis, 1/s^2: stretching {A * w0:+.4f}, diffusion {lap0:+.4f}, inflow +0.0000")
r1, _ = resid(0.003, 0.004, 2e-4, s); r2, _ = resid(0.003, 0.004, 1e-4, s)
print(f"  residual at r = 5 mm: {sci(r1)} at h = 0.2 mm, {sci(r2)} at h = 0.1 mm (ratio {r1 / r2:.2f})")
print(f"  circulation 2 pi r u_theta at r = 50 mm: {2 * math.pi * 0.05 * swirl(0.05, s):.6f} m^2/s")

print("DRAINING: core radius 50 mm at the start; t s | delta mm, peak 1/s with NU | Euler (NU = 0)")
for t in (0, 25, 50, 100, 200):
    sn, se = core2(t), S0 * math.exp(-A * t)
    print(f"  {t:3d} | {math.sqrt(sn) * 1000:6.2f} {om(0, sn):7.2f} | {math.sqrt(se) * 1000:6.2f} {om(0, se):8.2f}")
e1, c1 = grid(1e-3); e2, c2 = grid(5e-4)
print(f"  grid at 60 s: peak exact {om(0, core2(60)):.4f} 1/s; max error {sci(e1)} at dr = 1 mm, "
      f"{sci(e2)} at 0.5 mm, order {math.log2(e1 / e2):.2f}")
print(f"  circulation on the grid at 60 s: {c1:.6f} and {c2:.6f} m^2/s (start {G:.6f})")
bkm = G / (math.pi * S0) * (math.exp(A * 100) - 1) / A
quad = sum(om(0, S0 * math.exp(-A * (k + 0.5) * 0.01)) for k in range(10000)) * 0.01
print(f"  Euler: integral of peak vorticity over 0..100 s = {bkm:.2f} (midpoint sum {quad:.2f})")

print("ZERO-VISCOSITY LIMIT, steady: NU m^2/s | delta mm | peak 1/s | swirl at 30 mm m/s | loss W/m")
loss = []
for nu in (1e-6, 1e-7, 1e-8, 1e-9):
    sv = 4 * nu / A; dl = 8 * math.sqrt(sv) / 4000
    p = RHO * nu * sum(om((k + 0.5) * dl, sv) ** 2 * 2 * math.pi * (k + 0.5) * dl * dl for k in range(4000))
    loss.append(p)
    print(f"  {nu:.0e} | {math.sqrt(sv) * 1000:6.3f} | {om(0, sv):9.1f} | {swirl(0.03, sv):.5f} | {sci(p)}")
lv = G / (2 * math.pi * 0.03); pf = RHO * G * G * A / (8 * math.pi)
print(f"  Euler line vortex: swirl at 30 mm {lv:.5f} m/s, loss 0; formula RHO G^2 A/(8 pi) = {sci(pf)} W/m")

print("SMOKE RING in air: radius 50 mm, core 5 mm, circulation 0.075 m^2/s")
GR, R0, C0 = 0.075, 0.05, 0.005
spd = lambda R, c: GR / (4 * math.pi * R) * (math.log(8 * R / c) - 0.25)
wr0 = GR / (math.pi * C0 ** 2); c1r = C0 * math.sqrt(R0 / 0.1)
print(f"  core vorticity {wr0:.1f} 1/s; ring speed {spd(R0, C0):.4f} m/s")
r, w, b, nst = R0, wr0, 1.0, 1000; h = 2 * math.log(2) / b / nst
f = lambda r, w: (b * r / 2, w * (b * r / 2) / r)       # dr/dt = u_r, dw/dt = w u_r / r
for _ in range(nst):
    k1 = f(r, w); k2 = f(r + h / 2 * k1[0], w + h / 2 * k1[1])
    k3 = f(r + h / 2 * k2[0], w + h / 2 * k2[1]); k4 = f(r + h * k3[0], w + h * k3[1])
    r += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]); w += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
wv = GR / (math.pi * c1r ** 2)
print(f"  widened to 100 mm: w/r kept {wr0 * 0.1 / R0:.1f}; core volume kept {wv:.1f} (core {c1r * 1000:.2f} mm); "
      f"RK4 {w:.1f} 1/s at r = {r * 1000:.2f} mm")
print(f"  ring speed at 100 mm: {spd(0.1, c1r):.4f} m/s")
print(f"PIPE, laminar: wall vorticity 4 U/R = {4 * 1.0 / 0.025:.0f} 1/s; Re = U D/NU = {1.0 * 0.05 / NU:.0f}")

print("MISTAKES")
s100 = core2(100)
print(f"  drop stretching: peak at 100 s {G * math.exp(-A * 100) / (math.pi * s100):.3f} 1/s, "
      f"not {om(0, s100):.2f}; circulation {G * math.exp(-A * 100):.6f} m^2/s")
print(f"  Euler for the core: delta at 300 s {math.sqrt(S0 * math.exp(-A * 300)) * 1000:.3f} mm, "
      f"not {math.sqrt(core2(300)) * 1000:.2f} mm")
print(f"  vorticity read as spin: {w0 / (2 * math.pi):.2f} turns/s, not {w0 / (4 * math.pi):.2f}")
print(f"  ring widened without stretching: {wr0:.1f} 1/s, not {wv:.1f}")
print("chart r mm:    " + ", ".join(str(k) for k in range(0, 31, 2)))
for t in (0, 25, 100):
    print(f"chart w t={t:3d}: " + ", ".join(f"{om(k / 1000, core2(t)):.2f}" for k in range(0, 31, 2)))
print("chart r mm:    " + ", ".join(str(k) for k in range(4, 41, 4)))
for nu in (1e-6, 1e-8):
    print(f"chart u {nu:.0e}: " + ", ".join(f"{swirl(k / 1000, 4 * nu / A):.3f}" for k in range(4, 41, 4)))
print("chart u Euler: " + ", ".join(f"{G / (2 * math.pi * k / 1000):.3f}" for k in range(4, 41, 4)))

assert abs(vs - vscan) < 1e-6 and abs(A * w0 + lap0) < 1e-3 * A * w0  # budget closes on the axis
assert abs(r2) < 0.01 * A * om(0.01, s) and 3.5 < r1 / r2 < 4.5      # closed form solves the PDE
assert e1 < 0.01 and 1.8 < math.log2(e1 / e2) < 2.2 and abs(c2 - G) < 1e-5  # grid agrees
assert abs(quad - bkm) < 1e-3 * bkm
assert all(abs(p - pf) < 1e-6 * pf for p in loss)                   # loss does not vanish
assert abs(w - wv) < 1e-6 * wv and abs(r - 0.1) < 1e-9
print("ALL CHECKS PASS")
