# Flux limiters: TVD schemes on a square slug of pollutant -- the check behind the card.
# Standard library only; math supplies sin, pi and log2.  Road 1: the exact answer (after
# one lap round the loop the slug is back where it began).  Road 2: total variation measured
# every step, against Harten's coefficients C computed from the limiter.  Road 3: a second
# scheme, MUSCL slopes with an SSP Runge-Kutta step.  Road 4: errors at four grid sizes.
from math import sin, pi, log2

C, H, NU, N = 2.0, 0.25, 0.5, 40           # river km/h; cell km; Courant number; cells on the loop
DT = NU * H / C                            # time step, h
LIM = {"upwind": lambda r: 0.0, "Lax-Wendroff": lambda r: 1.0,
       "minmod": lambda r: max(0.0, min(1.0, r)),
       "van Leer": lambda r: (r + abs(r)) / (1.0 + abs(r)),
       "superbee": lambda r: max(0.0, min(2.0 * r, 1.0), min(r, 2.0)),
       "phi = 1 for r > 0": lambda r: 1.0 if r > 0 else 0.0}
TVD = ("minmod", "van Leer", "superbee")

def jumps(u): return [u[(j + 1) % len(u)] - u[j] for j in range(len(u))]   # d[j] = u_(j+1) - u_j
def tv(u): return sum(abs(d) for d in jumps(u))

def step(u, phi, nu=NU, cs=None):          # flux form; cs collects Harten's C_(j-1/2)
    d = jumps(u)
    g = [phi(d[j - 1] / d[j]) * d[j] if d[j] != 0 else 0.0 for j in range(len(u))]
    new = [u[j] - nu * ((u[j] + (1 - nu) / 2 * g[j]) - (u[j - 1] + (1 - nu) / 2 * g[j - 1])) for j in range(len(u))]
    if cs is not None:                     # incremental form u_j - C_(j-1/2) d_(j-1/2), built separately
        for j in range(len(u)):
            if d[j - 1] != 0:
                c = nu * (1 + (1 - nu) / 2 * (g[j] - g[j - 1]) / d[j - 1])
                cs[0], cs[1] = min(cs[0], c), max(cs[1], c)
                cs[2] = max(cs[2], abs(u[j] - c * d[j - 1] - new[j]))
    return new

def mm(a, b): return 0.0 if a * b <= 0 else (a if abs(a) < abs(b) else b)
def muscl(u, nu=NU):                       # forward Euler on minmod-limited slopes, one step
    d = jumps(u)
    e = [u[j] + 0.5 * mm(d[j - 1], d[j]) for j in range(len(u))]           # value at the right edge
    return [u[j] - nu * (e[j] - e[j - 1]) for j in range(len(u))]
def ssprk2(u): return [0.5 * a + 0.5 * b for a, b in zip(u, muscl(muscl(u)))]

def lap(u0, f, n):                         # n steps; returns end state, largest TV, TV never rose?
    u, top, mono = u0[:], tv(u0), True
    for _ in range(n):
        v = f(u)
        mono = mono and tv(v) <= tv(u) + 1e-12
        u, top = v, max(top, tv(v))
    return u, top, mono

slug = [1.0 if 10 <= j < 20 else 0.0 for j in range(N)]
steps = round(N / NU)
print(f"river {C:.1f} km/h, cell h = {H:.2f} km, Courant number nu = {NU:.2f}, step {DT:.4f} h, {N} cells on a 10 km loop"
      f" (Flow problems' 0.1 h step gave nu = {C * 0.1 / H:.2f})")
print(f"one lap = {steps} steps = {steps * DT:.2f} h; slug 1 mg/L in the 10 cells at 2.50 to 4.75 km; total variation TV = {tv(slug):.4f}")
v = [LIM[s](0.5) for s in TVD]
print(f"phi(0.5): minmod {v[0]:.4f}, van Leer {v[1]:.4f}, superbee {v[2]:.4f}")
assert abs(v[0] - 1 / 2) < 1e-15 and abs(v[1] - 2 / 3) < 1e-15 and abs(v[2] - 1) < 1e-15
rs = [k / 100 for k in range(-200, 1001)]
def inside(phi): return all(0 <= phi(r) <= min(2 * r, 2) + 1e-15 or (r <= 0 and phi(r) == 0) for r in rs)
for s in ("Lax-Wendroff", "minmod", "van Leer", "superbee"):
    out = [r for r in rs if not (0 <= LIM[s](r) <= max(0.0, min(2 * r, 2)))]
    print(f"  {s:<12} inside Sweby's TVD region for r = -2..10: {'yes' if not out else 'no, outside for r <= %.2f' % out[-1]}")
    assert inside(LIM[s]) == (s in TVD)

print("first step by hand, cells at 2.25 | 2.50 | 4.75 | 5.00 km:")
for s in ("Lax-Wendroff", "minmod"):
    u1 = step(slug, LIM[s])
    print(f"  {s:<12} {u1[9]:.4f} | {u1[10]:.4f} | {u1[19]:.4f} | {u1[20]:.4f}; TV {tv(u1):.4f}")
lw1 = step(slug, LIM["Lax-Wendroff"])
assert abs(lw1[19] - (1 + NU / 2 - NU * NU / 2)) < 1e-15 and abs(tv(lw1) - 2.5) < 1e-12
m1 = step(slug, LIM["minmod"])
r20 = (m1[20] - m1[19]) / (m1[21] - m1[20])
m2 = step(m1, LIM["minmod"])[20]
print(f"second minmod step at 5.00 km: r = {r20:.4f}, phi = {LIM['minmod'](r20):.4f}, value {m2:.4f}")
assert abs(m2 - 0.8125) < 1e-15                          # by hand: 0.5 + 0.25 + 0.0625
s1 = ssprk2(slug)
print(f"MUSCL + SSP-RK2, step 1, cells at 5.00 | 5.25 km: {s1[20]:.4f} | {s1[21]:.4f}")
assert abs(s1[20] - 7 / 16) < 1e-15 and abs(s1[21] - 1 / 16) < 1e-15   # by hand: 0.875 / 2, 0.125 / 2

print("one lap | largest TV on the way | TV at end | highest | lowest | L1 error mg/L km | mass")
ends = {}
for s in ("upwind", "Lax-Wendroff", "minmod", "van Leer", "superbee", "MUSCL + SSP-RK2"):
    f = ssprk2 if s[0] == "M" else (lambda u, p=LIM[s]: step(u, p))
    u, top, mono = lap(slug, f, steps)
    ends[s] = u
    err = H * sum(abs(a - b) for a, b in zip(u, slug))
    print(f"  {s:<15} {top:.4f} | {tv(u):.4f} | {max(u):.4f} | {min(u):.4f} | {err:.4f} | {H * sum(u):.4f}")
    assert abs(H * sum(u) - 2.5) < 1e-12                       # conservation form keeps the pollutant
    if s != "Lax-Wendroff": assert mono and top <= 2 + 1e-12 and -1e-12 <= min(u) and max(u) <= 1 + 1e-12
assert tv(ends["Lax-Wendroff"]) > 3.0 and max(ends["Lax-Wendroff"]) > 1.15
assert H * sum(abs(a - b) for a, b in zip(ends["minmod"], slug)) < 0.6 * H * sum(abs(a - b) for a, b in zip(ends["upwind"], slug))

for s in ("minmod", "van Leer", "superbee", "Lax-Wendroff"):
    cs, u = [9.0, -9.0, 0.0], slug[:]
    for _ in range(steps): u = step(u, LIM[s], cs=cs)
    print(f"Harten's C over the lap, {s:<12}: {cs[0]:.4f} to {cs[1]:.4f}; incremental form matches to {cs[2]:.1e}")
    assert cs[2] < 1e-14
    assert (NU * NU - 1e-12 <= cs[0] and cs[1] <= NU * (2 - NU) + 1e-12) == (s in TVD)
print(f"bound for any limiter in the region: nu^2 = {NU * NU:.4f} to nu(2 - nu) = {NU * (2 - NU):.4f}")

print("what breaks:")
for s, nu in (("phi = 1 for r > 0", NU), ("minmod", 1.2)):
    u, top, mono = lap(slug, lambda w, p=LIM[s], q=nu: step(w, p, q), round(N / nu))
    print(f"  {s} at nu = {nu:.1f}: largest TV {top:.4f}, highest {max(u):.4f}, lowest {min(u):.4f}")
    assert top > 2.2 and not mono

print("smooth wave 0.5 + 0.5 sin(2 pi x / 10 km), one lap: L1 error | max error at N = 40, 80, 160, 320")
ords = {}
for s in ("upwind", "Lax-Wendroff", "minmod", "van Leer", "superbee"):
    e1, e8, top = [], [], []
    for n in (40, 80, 160, 320):
        h = 10.0 / n
        u0 = [0.5 + 0.5 * sin(2 * pi * j * h / 10) for j in range(n)]
        u = u0[:]
        for _ in range(2 * n): u = step(u, LIM[s])
        e1.append(h * sum(abs(a - b) for a, b in zip(u, u0)))
        e8.append(max(abs(a - b) for a, b in zip(u, u0)))
        top.append(max(u))
    p1, p8 = log2(e1[2] / e1[3]), log2(e8[2] / e8[3])
    ords[s] = (p1, p8)
    print(f"  {s:<12} " + "  ".join(f"{a:.6f}|{b:.6f}" for a, b in zip(e1, e8)) + f"; orders {p1:.2f} | {p8:.2f}; crest at N = 40: {top[0]:.4f}")
assert abs(ords["upwind"][0] - 1) < 0.1 and abs(ords["Lax-Wendroff"][0] - 2) < 0.05 and abs(ords["Lax-Wendroff"][1] - 2) < 0.05
assert ords["minmod"][0] > 1.8 and ords["minmod"][1] < 1.5 and ords["van Leer"][1] < 1.5

xs = range(2, 25)
print("chart, km " + ", ".join(f"{j * H:.2f}" for j in xs))
for s, u in (("exact", slug), ("Lax-Wendroff", ends["Lax-Wendroff"]), ("minmod", ends["minmod"])):
    print(f"  {s}: " + ", ".join(f"{u[j]:.2f}" for j in xs))
def px(r, p): return f"({40 + 100 * r:.0f}, {200 - 80 * p:.1f})"
print("figure, Sweby diagram, x = 40 + 100 r, y = 200 - 80 phi: r = 0.5 minmod " + px(0.5, v[0]) + ", van Leer " + px(0.5, v[1])
      + ", superbee " + px(0.5, v[2]) + "; r = 3 van Leer " + px(3, LIM["van Leer"](3)) + ", superbee " + px(3, LIM["superbee"](3)))
print("ALL CHECKS PASS")
