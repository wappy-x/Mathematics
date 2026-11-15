# Weak derivatives and Sobolev spaces -- the check behind the card.  Standard
# library only.  The load: an illustrative evening peak on a feeder, 4 MW above
# base at 18:00, ramping up from 17:00 and down to 19:00.  With t in hours after
# 17:00, u(t) = 4(1 - |t - 1|) on (0, 2).  The kink at t = 1 has no slope; the
# weak derivative g = +4 then -4 MW/h is tested against smooth probes.
import math

def u(t): return 4.0 * (1.0 - abs(t - 1.0)) if 0.0 <= t <= 2.0 else 0.0
def g(t): return 4.0 if t < 1.0 else -4.0                     # the claimed weak derivative
def switch(t): return 4.0 if t > 1.0 else 0.0                 # a 4 MW block switched on at 18:00

def bump(t, c, r):                                            # smooth probe, zero off (c - r, c + r)
    s = (t - c) / r
    return math.exp(-1.0 / (1.0 - s * s)) if abs(s) < 1.0 else 0.0

def dbump(t, c, r):                                           # its slope, by the chain rule
    s = (t - c) / r
    return bump(t, c, r) * (-2.0 * s / (r * (1.0 - s * s) ** 2)) if abs(s) < 1.0 else 0.0

def gauss(f, a, b, n=2000):                                   # two-point Gauss on n pieces:
    h, q = (b - a) / n, (b - a) / n / (2.0 * math.sqrt(3.0))  # never samples an end point
    return sum(f(a + (k + 0.5) * h - q) + f(a + (k + 0.5) * h + q) for k in range(n)) * h / 2.0

def integral(f, a, b, cuts=(1.0,)):                           # split at kinks and jumps
    pts = [a] + [x for x in cuts if a < x < b] + [b]
    return sum(gauss(f, pts[k], pts[k + 1]) for k in range(len(pts) - 1))

def grid(n):                                                  # the finite rehearsal: n steps of h
    h = 2.0 / n
    vals = [u(i * h) for i in range(n + 1)]
    trap = h * sum(v * v for v in vals)                      # ends are 0, so this is the trapezoid sum
    slope = sum(h * ((vals[i + 1] - vals[i]) / h) ** 2 for i in range(n))
    bend = sum(h * ((vals[i + 1] - 2 * vals[i] + vals[i - 1]) / h ** 2) ** 2 for i in range(1, n))
    return h, vals, trap, slope, bend

print("finite rehearsal, N = 16 steps, probe centred 0.7, half-width 0.4:")
h, vals, _, _, _ = grid(16)
ph = [bump(i * h, 0.7, 0.4) for i in range(17)]
left = sum(vals[i] * (ph[i + 1] - ph[i]) for i in range(16))
right = -sum((vals[i + 1] - vals[i]) * ph[i + 1] for i in range(16))
print(f"  sum u_i (phi_i+1 - phi_i) = {left:.9f};  -sum (u_i+1 - u_i) phi_i+1 = {right:.9f}")
assert abs(left - right) < 1e-12                              # summation by parts, no boundary term

print("weak derivative test, integral u phi' against -integral g phi:")
for c, r in [(0.9, 0.5), (0.7, 0.4), (1.2, 0.6)]:
    lhs = integral(lambda t: u(t) * dbump(t, c, r), c - r, c + r)
    rhs = -integral(lambda t: g(t) * bump(t, c, r), c - r, c + r)
    print(f"  probe c = {c:.1f}, r = {r:.1f}:  {lhs:.9f}  {rhs:.9f}")
    assert abs(lhs - rhs) < 1e-9
c, r = 1.0, 0.5
bump_area = integral(lambda t: bump(t, c, r), c - r, c + r)
wrong = integral(lambda t: u(t) * dbump(t, c, r), c - r, c + r) + integral(lambda t: 4.0 * bump(t, c, r), c - r, c + r)
print(f"mistake 1, slope +4 everywhere: residual on probe c = 1.0, r = 0.5 is {wrong:.6f}")
assert abs(wrong - 4.0 * bump_area) < 1e-9                    # 8 times the right half of the probe

print(f"mistake 2, jumps: probes centred at 1, height phi(1) = {bump(1.0, 1.0, 0.5):.6f}")
for r in [0.5, 0.05, 0.005]:
    sp = integral(lambda t: switch(t) * dbump(t, 1.0, r), 1.0 - r, 1.0 + r)
    gp = integral(lambda t: g(t) * dbump(t, 1.0, r), 1.0 - r, 1.0 + r)
    area = integral(lambda t: bump(t, 1.0, r), 1.0 - r, 1.0 + r)
    print(f"  r = {r:<6} integral switch phi' {sp:.6f}  integral g phi' {gp:.6f}  integral phi {area:.6f}")
    assert abs(sp + 4.0 / math.e) < 1e-9 and abs(gp - 8.0 / math.e) < 1e-9   # -4 phi(1) and 8 phi(1)

run, worst = 0.0, 0.0                                         # absolute continuity: u is the running integral of g
for i in range(2000):
    run += g((i + 0.5) / 1000) / 1000
    worst = max(worst, abs(run - u((i + 1) / 1000)))
print(f"running integral of g reproduces u: largest gap {worst:.1e} MW")
assert worst < 1e-12

L2, D2 = 32 / 3, 32.0                                         # closed forms, MW^2 h and (MW/h)^2 h
norms = {}
for p in [1, 2]:
    up = integral(lambda t: abs(u(t)) ** p, 0.0, 2.0)
    gp = integral(lambda t: abs(g(t)) ** p, 0.0, 2.0)
    norms[p] = (up, gp, (up + gp) ** (1 / p))
    print(f"W^(1,{p}): integral |u|^{p} = {up:.6f}, integral |g|^{p} = {gp:.6f}, norm {norms[p][2]:.6f}")
    assert abs(norms[p][2] - (2 * 4 ** p * (p + 2) / (p + 1)) ** (1 / p)) < 1e-9
slopes = [abs(vals[i + 1] - vals[i]) / h for i in range(16)]
print(f"W^(1,inf): max |u| = {max(vals):.6f}, max |g| = {max(slopes):.6f}, norm {max(max(vals), max(slopes)):.6f}")
print(f"H^1 norm squared {norms[2][2] ** 2:.6f} = 32/3 + 32 = {L2 + D2:.6f}; u(0) = {u(0):.1f}, u(2) = {u(2):.1f}")
assert abs(norms[2][2] ** 2 - 128 / 3) < 1e-9

print("truncation:     N        h   sum u^2    sum u'^2    sum u''^2")
for n in [4, 16, 64, 256]:
    h, _, trap, slope, bend = grid(n)
    print(f"           {n:6d} {h:8.5f} {trap:9.6f} {slope:11.6f} {bend:12.3f}")
    assert abs(trap - (L2 + 16 * h * h / 3)) < 1e-9 and abs(slope - D2) < 1e-9 and abs(bend - 64 / h) < 1e-6

print("rounding the corner over 1 - eps to 1 + eps by a parabola:")
for eps in [0.25, 0.0625, 0.015625]:
    v = lambda t: 4 - 2 * eps - 2 * (t - 1) ** 2 / eps
    dv = lambda t: -4 * (t - 1) / eps
    d0 = integral(lambda t: (u(t) - v(t)) ** 2, 1 - eps, 1 + eps)
    d1 = integral(lambda t: (g(t) - dv(t)) ** 2, 1 - eps, 1 + eps)
    print(f"  eps {eps:<9} peak {4 - 2 * eps:.4f}  H^1 distance squared {d0 + d1:.6f}"
          f"  distance {math.sqrt(d0 + d1):.6f}  integral v''^2 {32 / eps:.0f}")
    assert abs(d0 + d1 - (8 * eps ** 3 / 5 + 32 * eps / 3)) < 1e-9

mins = 30.0                                                   # mistake 4: the same load in minutes
uvals = [0.0, 2.0, 4.0, 2.0, 0.0]
slope_min = sum(mins * ((uvals[i + 1] - uvals[i]) / mins) ** 2 for i in range(4))
print(f"mistake 4, minutes: integral u^2 = {L2 * 60:.3f} MW^2 min, integral u'^2 = {slope_min:.6f}")
assert abs(slope_min - D2 / 60) < 1e-12
X = lambda t: 40 + 160 * t                                    # figure scale: 160 px per hour,
Y = lambda m: 130 - 25 * m                                    # 25 px per MW, 10 px per MW/h
print(f"figure, tent px: ({X(0):.0f}, {Y(u(0)):.0f}) ({X(1):.0f}, {Y(u(1)):.0f}) ({X(2):.0f}, {Y(u(2)):.0f});"
      f" rounded peak ({X(1):.0f}, {Y(3.5):.1f}); slope px: +4 at y {220 - 40}, -4 at y {220 + 40},"
      f" rounded from x {X(0.75):.0f} to {X(1.25):.0f}")
print("ALL CHECKS PASS")
