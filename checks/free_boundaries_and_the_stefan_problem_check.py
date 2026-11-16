# Free boundaries and the Stefan problem -- the check behind the card.  Standard
# library only.  A glass of ice at 0 C under a lid held at 20 C, melting for 20
# minutes.  Road 1: the Neumann closed form, its number lam found by bisection.
# Road 2: an enthalpy grid that never tracks the front, at three steps.
# Road 3: the heat through the lid against the heat stored, by Simpson's rule.
import math
K, RHO, C, LAT, T0 = 0.6, 1000.0, 4186.0, 334000.0, 20.0   # water, SI units
KS, CS, TI = 2.2, 2100.0, -10.0                # ice, for the -10 C break
KAP = K / (RHO * C)                            # water's diffusivity, m^2/s
ST = C * T0 / LAT                              # Stefan number
TEND = 1200.0                                  # 20 minutes, s
SQPI = math.sqrt(math.pi)

def erf(z):                                    # Taylor series, fine for z < 3
    term, total, n = z, z, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -z * z / n
        total += term / (2 * n + 1)
    return 2 / SQPI * total

def bisect(f, a, b):                           # f(a) < 0 < f(b)
    for _ in range(200):
        m = 0.5 * (a + b)
        a, b = (m, b) if f(m) < 0 else (a, m)
    return 0.5 * (a + b)

lam = bisect(lambda l: l * math.exp(l * l) * erf(l) - ST / SQPI, 0.0, 2.0)
def front(t): return 2 * lam * math.sqrt(KAP * t)
def speed(t): return lam * math.sqrt(KAP / t)
def temp(x, t): return T0 * (1 - erf(x / (2 * math.sqrt(KAP * t))) / erf(lam))

def enthalpy_front(n_cells, dt):               # H = heat content per m^3 above ice at 0 C
    h = 0.015 / n_cells
    H = [0.0] * (n_cells + 1)
    T = [T0] + [0.0] * n_cells
    for _ in range(round(TEND / dt)):
        for i in range(1, n_cells):
            H[i] += dt * K * (T[i + 1] - 2 * T[i] + T[i - 1]) / (h * h)
        for i in range(1, n_cells):
            T[i] = max(0.0, (H[i] - RHO * LAT) / (RHO * C))
    return h / 2 + h * sum(min(1.0, Hi / (RHO * LAT)) for Hi in H[1:])

def simpson(f, a, b, n=200):
    h = (b - a) / n
    return h / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * f(a + j * h) for j in range(n + 1))

def out(label, value): print(f"{label:<46}{value}")
out("diffusivity of water, 1e-7 m^2/s", f"{KAP * 1e7:.4f}")
out("Stefan number c*T0/L", f"{ST:.4f}")
out("lam, root of the Neumann equation", f"{lam:.6f}")
s20 = front(TEND)
out("by hand: exp(lam^2), erf(lam), product", f"{math.exp(lam * lam):.4f}, {erf(lam):.4f}, "
    f"{lam * math.exp(lam * lam) * erf(lam):.4f} = St/sqrt(pi) {ST / SQPI:.4f}")
out("sqrt(kappa t) at 20 min, mm", f"{1000 * math.sqrt(KAP * TEND):.3f}")
out("front after 5, 10 and 20 min, mm", f"{1000 * front(300):.3f}, {1000 * front(600):.3f}, {1000 * s20:.3f}")
out("front speed at 1 min and 20 min, mm/min", f"{60000 * speed(60):.3f} and {60000 * speed(TEND):.3f}")
print("minute   " + "".join(f"{m:>6}" for m in range(0, 21, 2)))
print("front mm " + "".join(f"{1000 * front(60 * m):>6.2f}" for m in range(0, 21, 2)))
qs = [math.sqrt(2 * K * T0 * 60 * m / (RHO * LAT)) for m in range(0, 21, 2)]
print("quasi mm " + "".join(f"{1000 * v:>6.2f}" for v in qs))
for m in (5, 10, 20):
    t = 60 * m
    row = [temp(x / 1000, t) if x / 1000 <= front(t) else 0.0 for x in range(10)]
    print(f"T at {m:>2} min, x = 0..9 mm, C " + " ".join(f"{v:5.2f}" for v in row))
# road 3: heat in through the lid against latent plus sensible heat stored
q_in = 2 * K * T0 * math.sqrt(TEND) / (erf(lam) * math.sqrt(math.pi * KAP))
latent = RHO * LAT * s20
sensible = RHO * C * simpson(lambda x: temp(x, TEND), 0.0, s20)
out("heat in through the lid, kJ/m^2", f"{q_in / 1000:.3f}")
out("melting the ice (latent), kJ/m^2", f"{latent / 1000:.3f}")
out("warming the melt water (sensible), kJ/m^2", f"{sensible / 1000:.3f}")
out("stored / in", f"{(latent + sensible) / q_in:.8f}")
out("shares: latent, sensible, %", f"{100 * latent / q_in:.1f}, {100 * sensible / q_in:.1f}")
dx = 1e-3 * s20                                # Stefan condition at 20 min, two sides
grad = (temp(s20 + dx, TEND) - temp(s20 - dx, TEND)) / (2 * dx)
lid = -K * (temp(dx, TEND) - temp(-dx, TEND)) / (2 * dx)
out("W/m^2 at 20 min: lid, -k T_x(s), rho L s'", f"{lid:.1f}, {-K * grad:.1f}, {RHO * LAT * speed(TEND):.1f}")
# road 2: the enthalpy grid, explicit, r = kappa*dt/h^2 = 0.4587 on every grid
grid = []
for n_cells, dt in ((30, 0.8), (60, 0.2), (120, 0.05)):
    sg = enthalpy_front(n_cells, dt)
    grid.append(sg)
    out(f"grid h = {15 / n_cells:.3f} mm, dt = {dt} s, front mm", f"{1000 * sg:.3f}  error {1e6 * (sg - s20):+.1f} um  ratio {KAP * dt / (0.015 / n_cells) ** 2:.4f}")
# two-phase: ice starting at -10 C also soaks up heat ahead of the front
kaps = KS / (RHO * CS)
nu, sts = math.sqrt(KAP / kaps), CS * (0 - TI) / LAT
lam2 = bisect(lambda l: l - ST * math.exp(-l * l) / (SQPI * erf(l))
              + sts * math.exp(-nu * nu * l * l) / (nu * SQPI * (1 - erf(nu * l))), 1e-9, 2.0)
s_cold = 2 * lam2 * math.sqrt(KAP * TEND)
out("ice at -10 C: lam, front after 20 min mm", f"{lam2:.6f}, {1000 * s_cold:.3f}")
mist = [60 * speed(60) * 20, qs[-1], lam * math.sqrt(KAP * TEND)]
out("mistakes, mm: constant speed, quasi, no 2", ", ".join(f"{1000 * v:.3f}" for v in mist))
out("off by, %: -10 C ice, quasi-steady", f"{100 * (s_cold / s20 - 1):+.1f}, {100 * (qs[-1] / s20 - 1):+.1f}")
# centred-difference residual of the heat equation at mid-layer, 20 min, two steps
x0, res = 0.5 * s20, []
for d, e in ((0.1 * s20, 40.0), (0.05 * s20, 20.0)):
    res.append((temp(x0, TEND + e) - temp(x0, TEND - e)) / (2 * e)
               - KAP * (temp(x0 + d, TEND) - 2 * temp(x0, TEND) + temp(x0 - d, TEND)) / (d * d))
out("heat-eq residual, 1e-6 K/s, step d and d/2", f"{res[0] * 1e6:.4f}, {res[1] * 1e6:.4f}")
assert abs(lam - math.sqrt(ST / 2) * (1 - ST / 6)) < 0.01 * lam   # small-St series
assert abs((latent + sensible) / q_in - 1) < 1e-8          # energy is conserved
assert max(abs(g - s20) for g in grid) < 1e-3 * s20       # the grid agrees with Neumann
assert 3.5 < res[0] / res[1] < 4.5                          # order 2: the formula solves the equation
assert abs(-K * grad / (RHO * LAT * speed(TEND)) - 1) < 1e-5   # the Stefan condition
assert s_cold < s20 < qs[-1] < mist[0]                      # each break's direction
print("ALL CHECKS PASS")
