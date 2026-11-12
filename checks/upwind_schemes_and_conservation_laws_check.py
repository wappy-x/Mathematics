# Flow problems: upwind, centred and Lax-Wendroff steps on a river pulse -- the
# check behind the card.  Standard library only; math supplies exp, sqrt, cos, sin, pi.
# Road 1: the exact shifted pulse.  Road 2: each grid scheme, stepped with no formula.
# Road 3: the modified equation, a Gaussian widened by the numerical diffusivity.
from math import exp, sqrt, cos, sin, pi, log10

C, H, DT, T = 2.0, 0.25, 0.1, 3.0          # river km/h; cell km; step h; run h
NU = C * DT / H                             # Courant number, 0.8
LO, HI = -4.0, 12.0                         # the reach of river on the grid, km

def f(x): return 10.0 * exp(-x * x)        # the spill at t = 0, mg/L

def step(s, a, b, c, nu):                   # one update from neighbours a | b | c
    if s == "upwind": return b - nu * (b - a)
    if s == "downwind": return b - nu * (c - b)
    if s == "centred": return b - nu / 2 * (c - a)
    return b - nu / 2 * (c - a) + nu * nu / 2 * (c - 2 * b + a)     # Lax-Wendroff

def run(s, h=H, nu=NU, t=T):
    n = round((HI - LO) / h) + 1
    u = [f(LO + i * h) for i in range(n)]
    for _ in range(round(t / (nu * h / C))):
        u = [0.0] + [step(s, u[i - 1], u[i], u[i + 1], nu) for i in range(1, n - 1)] + [u[n - 2]]
    return u

def at(u, x, h=H): return u[round((x - LO) / h)]
def gauss(x, t, alpha):                     # road 3: spill shifted by ct, variance 1/2 + 2 alpha t
    v = 0.5 + 2 * alpha * t
    return 10.0 * sqrt(0.5 / v) * exp(-(x - C * t) ** 2 / (2 * v))

def alpha_num(h, nu): return C * h * (1 - nu) / 2      # numerical diffusivity, km^2/h

print(f"river {C:.1f} km/h, cell h = {H:.2f} km, step {DT:.1f} h, Courant number nu = {NU:.2f}, {round(T / DT)} steps to {T:.1f} h")
up, lw, ce = run("upwind"), run("Lax-Wendroff"), run("centred")
xs = [LO + i * H for i in range(len(up))]
an = alpha_num(H, NU)
mass = sum(up) * H
print(f"exact: peak {f(0):.4f} mg/L at {C * T:.0f} km; mass 10 sqrt(pi) = {10 * sqrt(pi):.7f} mg/L km")
print(f"upwind: peak {max(up):.4f}, lowest {min(up):.4f}, mass {mass:.7f}")
print(f"numerical diffusivity c h (1 - nu)/2 = {an:.4f} km^2/h = {an * 1e6 / 3600:.2f} m^2/s")
print(f"modified equation: variance 0.5 + 2 x {an:.2f} x {T:.0f} = {0.5 + 2 * an * T:.4f} km^2, peak {gauss(C * T, T, an):.4f}")
gap_mod = max(abs(u - gauss(x, T, an)) for x, u in zip(xs, up))
gap_ex = max(abs(u - f(x - C * T)) for x, u in zip(xs, up))
print(f"upwind's largest gap: from the exact pulse {gap_ex:.4f}, from the modified equation {gap_mod:.4f}")
print(f"upwind peak sits {gauss(C * T, T, an) - max(up):.4f} below the modified equation's; the water at 6.00 km came from {C * T - C * DT:.2f} km")
print(f"Lax-Wendroff: peak {max(lw):.4f}, lowest {min(lw):.4f}, mass {sum(lw) * H:.7f}")
print(f"centred: peak {max(ce):.4f}, lowest {min(ce):.4f}")
print(f"Lax-Wendroff with negatives clipped to zero: mass {sum(max(v, 0.0) for v in lw) * H:.7f}")

print("one upwind step by hand, cells at 5.75 and 6.00 km, t = 2.9 -> 3.0 h:")
u29 = run("upwind", t=2.9)
a, b = at(u29, 5.75), at(u29, 6.0)
print(f"  {b:.4f} - {NU:.1f} x ({b:.4f} - {a:.4f}) = {b - NU * (b - a):.4f}; grid {at(up, 6.0):.4f}")

print("growth factor |g| per step: measured on a periodic grid of 16 cells | formula")
def measured(s, m, nu=NU):                  # feed in cos(xi j), xi = 2 pi m / 16; energy ratio
    xi = 2 * pi * m / 16
    u = [cos(xi * j) for j in range(16)]
    v = [step(s, u[j - 1], u[j], u[(j + 1) % 16], nu) for j in range(16)]
    return sqrt(sum(w * w for w in v) / sum(w * w for w in u)), xi
form = {"upwind": lambda x: sqrt(1 - 2 * NU * (1 - NU) * (1 - cos(x))),
        "centred": lambda x: sqrt(1 + NU * NU * sin(x) ** 2),
        "Lax-Wendroff": lambda x: sqrt(1 - NU * NU * (1 - NU * NU) * (1 - cos(x)) ** 2)}
worst = 0.0
for s in ("upwind", "centred", "Lax-Wendroff"):
    row = []
    for m in (2, 4, 8):
        g, xi = measured(s, m)
        worst = max(worst, abs(g - form[s](xi)))
        row.append(f"{g:.4f} | {form[s](xi):.4f}")
    print(f"  {s:<12} xi = pi/4, pi/2, pi: " + ";  ".join(row))

def strongest(t):                           # the wave carrying most of the centred error, by a DFT
    e = [v - f(LO + j * H - C * t) for j, v in enumerate(run("centred", t=t))]
    amp = lambda m: abs(sum(w * complex(cos(2 * pi * m * j / len(e)), -sin(2 * pi * m * j / len(e))) for j, w in enumerate(e)))
    return 2 * pi * max(range(1, len(e) // 2 + 1), key=amp) / len(e)
for t in (1.0, 3.0):
    xi = strongest(t)
    g = sqrt(1 + NU * NU * sin(xi) ** 2)
    print(f"centred error at {t:.1f} h: strongest wave xi = {xi / pi:.3f} pi, {2 * pi / xi:.1f} cells long,"
          f" grown x{g ** round(t / DT):.1f} in {round(t / DT)} steps from a spill weight of 1 in {exp((xi / H) ** 2 / 4):.0f}")
print(f"the xi = pi/2 wave: grown x{sqrt(1 + NU * NU) ** 30:.0f} in 30 steps from a spill weight of 1 in {exp((pi / 2 / H) ** 2 / 4):.0f}")

print("order: largest error at 3 h against the exact pulse, nu = 0.8")
eu, el = [], []
for h in (0.25, 0.125, 0.0625):
    u1, u2 = run("upwind", h), run("Lax-Wendroff", h)
    x1 = [LO + i * h for i in range(len(u1))]
    eu.append(max(abs(u - f(x - C * T)) for x, u in zip(x1, u1)))
    el.append(max(abs(u - f(x - C * T)) for x, u in zip(x1, u2)))
    print(f"  h = {h:<6} upwind {eu[-1]:.4f} (peak {max(u1):.4f}, modified eq {gauss(C * T, T, alpha_num(h, NU)):.4f})"
          f"   Lax-Wendroff {el[-1]:.4f}")
print(f"  ratios as h halves: upwind {eu[0] / eu[1]:.2f}, {eu[1] / eu[2]:.2f}; Lax-Wendroff {el[0] / el[1]:.2f}, {el[1] / el[2]:.2f}")

print("how it moves: peak (and lowest) by time, mg/L")
for t in (0.5, 1.0, 2.0, 3.0):
    a1, a2, a3 = run("upwind", t=t), run("Lax-Wendroff", t=t), run("centred", t=t)
    print(f"  t = {t:.1f} h: upwind {max(a1):.4f} (modified eq {gauss(C * t, t, an):.4f}); Lax-Wendroff {max(a2):.4f}"
          f" ({min(a2):.4f}); centred {max(a3):.4f} ({min(a3):.4f})")

dn = run("downwind")
big = run("upwind", nu=1.2)
late = run("centred", t=12.0)
print(f"what breaks: downwind at 3 h, largest |u| = 10^{log10(max(abs(v) for v in dn)):.1f} mg/L")
print(f"what breaks: upwind with nu = 1.2 (step 0.15 h), peak {max(big):.4f}, lowest {min(big):.4f}")
print(f"what breaks: centred at 12 h, largest |u| = 10^{log10(max(abs(v) for v in late)):.1f} mg/L")
print(f"what breaks: fitting the upwind smear as real mixing gives {an * 1e6 / 3600:.2f} m^2/s of mixing that is not there")
for nu in (1.0, 0.5):
    w = run("upwind", nu=nu)
    print(f"try: upwind nu = {nu:.1f}: peak {max(w):.4f}, modified eq {gauss(C * T, T, alpha_num(H, nu)):.4f}")

lab = [2.0 + 0.5 * i for i in range(17)]
print("chart, x km:", ", ".join(f"{x:.1f}" for x in lab))
for name, u in (("exact 3 h", None), ("upwind 3 h", up), ("Lax-Wendroff 3 h", lw)):
    print(f"chart, {name}:", ", ".join(f"{(f(x - C * T) if u is None else at(u, x)):.2f}" for x in lab))
ce1 = run("centred", t=1.0)
lab1 = [-1.0 + 0.5 * i for i in range(13)]
print("chart, centred 1 h:", ", ".join(f"{at(ce1, x):.2f}" for x in lab1))
print("chart, exact 1 h:", ", ".join(f"{f(x - C):.2f}" for x in lab1))
px = lambda x: 60 + (x + 0.5) * 320
print("figure, cells " + " ".join(f"{6 + x:.2f}" for x in (-0.5, -0.25, 0.0, 0.25)) + " km at px "
      + " ".join(f"{px(x):.0f}" for x in (-0.5, -0.25, 0.0, 0.25))
      + f"; foot {6 - C * DT:.2f} km at px {px(-C * DT):.0f}; 2.9 h at y 180, 3.0 h at y {180 - DT * 1200:.0f}")

assert abs(max(up) - gauss(C * T, T, an)) < 0.02        # grid peak meets the modified equation
assert gap_mod < 0.1 * gap_ex                            # modified equation explains the error
assert abs(mass - 10 * sqrt(pi)) < 1e-6                  # conservation form keeps the mass
assert worst < 1e-12                                     # measured growth meets von Neumann
assert 1.6 < eu[0] / eu[1] < 2.2 and 1.6 < eu[1] / eu[2] < 2.2   # upwind: order 1
assert 3.4 < el[0] / el[1] < 4.4 and 3.4 < el[1] / el[2] < 4.4   # Lax-Wendroff: order 2
assert min(up) >= 0.0 and max(up) <= 10.0 and min(lw) < -0.1 and max(ce) > 50.0
print("ALL CHECKS PASS")
