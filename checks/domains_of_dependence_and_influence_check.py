# Dependence and influence -- the check behind the card.  Standard library only.
# A tap on a steel string, felt 10 cm away.  Roads: d'Alembert's formula; a grid
# stepped from neighbours only; the energy in a shrinking cone; in 3-D, a closed
# form against Kirchhoff's sphere average; for heat, an erf series against Simpson.
import math
T, RHO = 100.0, 0.01                 # tension N, mass per metre kg/m (illustrative)
C = math.sqrt(T / RHO)               # wave speed, m/s
V0, A, X = 0.5, 0.01, 0.10           # tap speed m/s, tap half-width m, listening point m
KAPPA = 1.2e-5                       # diffusivity of steel, m^2/s (typical value)

def tap(x, centre=0.0):              # starting velocity: V0 on the tap, half at its edges
    d = abs(x - centre)
    return V0 if d < A - 1e-12 else V0 / 2 if abs(d - A) < 1e-12 else 0.0

def string(x, t, taps=(0.0,)):       # road 1, d'Alembert: (1/2c) times the tap length inside [x-ct, x+ct]
    s = 0.0
    for p in taps:
        s += max(min(x + C * t, p + A) - max(x - C * t, p - A), 0.0)
    return V0 * s / (2 * C)

def grid(r, steps, taps=(0.0,), dx=0.001, n=500):   # road 2: each point sees only its two neighbours
    dt = r * dx / C
    old = [0.0] * (2 * n + 1)
    new = [dt * sum(tap((j - n) * dx, p) for p in taps) for j in range(2 * n + 1)]
    seen = [0.0, new[n + 100]]       # history at x = 10 cm
    for _ in range(steps - 1):
        nxt = [0.0] * (2 * n + 1)
        for j in range(1, 2 * n):
            nxt[j] = 2 * (1 - r * r) * new[j] + r * r * (new[j + 1] + new[j - 1]) - old[j]
        old, new = new, nxt
        seen.append(new[n + 100])
    return seen, new, dt

def cone_energy(t, x0=0.10, t0=0.0015, h=2e-5):     # road 3: (rho/2) sum of u_t^2 + c^2 u_x^2 over |x - x0| <= c(t0 - t)
    R, e, k = C * (t0 - t), 0.0, 0
    while -R + (k + 0.5) * h < R:
        x = x0 - R + (k + 0.5) * h
        ut = (string(x, t + h / C) - string(x, max(t - h / C, 0.0))) / ((t + h / C) - max(t - h / C, 0.0))
        ux = (string(x + h, t) - string(x - h, t)) / (2 * h)
        e += 0.5 * RHO * (ut * ut + C * C * ux * ux) * h
        k += 1
    return e

def halves_inside(t, x0=0.10, t0=0.0015):           # closed form: each half-tap carries rho V0^2 A / 2 of energy
    lo, hi = x0 - C * (t0 - t), x0 + C * (t0 - t)
    part = lambda p, q: max(min(q, hi) - max(p, lo), 0.0) / (2 * A)
    return RHO * V0 * V0 * A / 2 * (part(-A - C * t, A - C * t) + part(-A + C * t, A + C * t))

def ball_closed(r, t):               # 3-D, radial reduction: v0 (a^2 - (r - ct)^2) / (4 c r) inside the shell
    L = r - C * t
    return V0 * (A * A - L * L) / (4 * C * r) if abs(L) < A else 0.0

def ball_kirchhoff(r, t, m=200000):  # 3-D, Kirchhoff: t times the average tap speed on the sphere of radius ct
    R, s = C * t, 0.0
    for k in range(m):
        th = (k + 0.5) * math.pi / m
        if r * r + R * R + 2 * r * R * math.cos(th) < A * A:
            s += math.sin(th)
    return t * V0 * s * (math.pi / m) / 2

def erf(z):                          # erf from its all-positive series, 2/sqrt(pi) e^(-z^2) sum 2^n z^(2n+1)/(1.3...(2n+1))
    term, s, n = z, z, 0
    while abs(term) > 1e-17 * abs(s):
        n += 1
        term *= 2 * z * z / (2 * n + 1)
        s += term
    return 2 / math.sqrt(math.pi) * math.exp(-z * z) * s

def heat(x, t):                      # heat road 1: fraction of the hot spot's excess reaching x after t
    s = math.sqrt(4 * KAPPA * t)
    return 0.5 * (erf((x + A) / s) - erf((x - A) / s))

def heat_simpson(x, t, m=2000):      # heat road 2: the bell G(x - y, t) summed over the hot spot by Simpson's rule
    h = 2 * A / m
    G = lambda y: math.exp(-(x - y) ** 2 / (4 * KAPPA * t)) / math.sqrt(4 * math.pi * KAPPA * t)
    return h / 3 * sum((1 if k in (0, m) else 4 if k % 2 else 2) * G(-A + k * h) for k in range(m + 1))

def heat_log10(x, t):                # far tail: two roads to log10 of the fraction, no underflow
    s = math.sqrt(4 * KAPPA * t)
    z1, z2 = (x - A) / s, (x + A) / s
    asym = (-z1 * z1 - math.log(2 * z1 * math.sqrt(math.pi)) + math.log(1 - 1 / (2 * z1 * z1) + 3 / (4 * z1 ** 4))) / math.log(10)
    w, m = min(z2 - z1, 40 / z1), 20000
    hw = w / m
    I = hw / 3 * sum((1 if k in (0, m) else 4 if k % 2 else 2) * math.exp(-2 * z1 * k * hw - (k * hw) ** 2) for k in range(m + 1))
    simp = (-z1 * z1 + math.log(I / math.sqrt(math.pi))) / math.log(10)
    return asym, simp

ms, um = 1000.0, 1e6
print(f"string: c = sqrt({T:.0f} N / {RHO} kg/m) = {C:.0f} m/s; tap {V0} m/s on |x| <= {A*100:.0f} cm")
print(f"dependence of (10 cm, 1.00 ms): x from {(X - C*0.001)*100:.0f} cm to {(X + C*0.001)*100:.0f} cm; it holds {string(X, 0.001) * 2 * C / V0 * 100:.0f} cm of the tap")
print(f"influence of the tap at 1.00 ms: |x| <= {(A + C*0.001)*100:.0f} cm")
t_on, t_full = (X - A) / C, (X + A) / C
print(f"first motion at 10 cm: {t_on*ms:.2f} ms; full by {t_full*ms:.2f} ms; plateau {V0*A/C*um:.0f} um")
seen, _, dt = grid(1.0, 150)
gap = max(abs(seen[k] - string(X, k * dt)) for k in range(151))
first = next(k for k in range(151) if seen[k] != 0.0)
print(f"grid, Courant 1: largest gap to d'Alembert at 10 cm = {gap*um:.6f} um; first nonzero sample {first*dt*ms:.2f} ms")
print("string u(10 cm, t) um, t = 0.70 to 1.40 ms step 0.05:", " ".join(f"{string(X, (0.70 + 0.05*k)/ms)*um:.1f}" for k in range(15)))
print("3-D  u(10 cm, t) um, t = 0.70 to 1.40 ms step 0.05:", " ".join(f"{ball_closed(X, (0.70 + 0.05*k)/ms)*um:.4f}" for k in range(15)))
for tm in (0.95, 1.00, 1.20):
    print(f"3-D at {tm:.2f} ms: closed form {ball_closed(X, tm/ms)*um:.4f} um, Kirchhoff average {ball_kirchhoff(X, tm/ms)*um:.4f} um")
E = [(tm, cone_energy(tm / ms), halves_inside(tm / ms)) for tm in (0.0, 0.25, 0.5, 1.0, 1.25, 1.4)]
for tm, e, ex in E:
    print(f"energy in the cone to (10 cm, 1.50 ms) at {tm:.2f} ms: differences {e*1e6:.3f} uJ, half-taps {ex*1e6:.3f} uJ")
a2, s2 = grid(1.0, 100, taps=(0.0, 0.30))[0][100], grid(1.0, 100)[0][100]
print(f"second tap at 30 cm: u(10 cm, 1.00 ms) = {s2*um:.3f} um without, {a2*um:.3f} um with")
lg = [heat_log10(X, ts) for ts in (0.001, 1.0)]
for ts, (l1, l2) in zip(("1 ms", "1 s"), lg):
    print(f"heat, kappa = {KAPPA*1e6:.0f} mm^2/s: fraction at 10 cm after {ts} = 10^{l1:.2f} (tail series), 10^{l2:.2f} (Simpson)")
print(f"heat fraction at 10 cm after 100 s: erf series {heat(X, 100.0):.6f}, Simpson {heat_simpson(X, 100.0):.6f}")
print(f"second hot spot at 30 cm: heat at 10 cm after 100 s goes from {heat(X, 100.0):.6f} to {heat(X, 100.0) + heat(X - 0.30, 100.0):.6f}")
lo, hi = 10.0, 2000.0                # golden-section search for the heat peak at 10 cm
gr = (math.sqrt(5) - 1) / 2
while hi - lo > 1e-3:
    m1, m2 = hi - gr * (hi - lo), lo + gr * (hi - lo)
    lo, hi = (m1, hi) if heat(X, m1) < heat(X, m2) else (lo, m2)
tp = (lo + hi) / 2
print(f"heat peak at 10 cm: {tp:.1f} s, {heat(X, tp)*100:.2f} % of the excess; point-source rule x^2/(2 kappa) = {X*X/(2*KAPPA):.1f} s")
print(f"what breaks: timing from the tap centre gives {X/C*ms:.2f} ms, but u there is already {string(X, X/C)*um:.0f} um")
print(f"what breaks: forgetting the tap width puts the influence edge at {C*0.001*100:.0f} cm, not {(A + C*0.001)*100:.0f} cm")
print(f"what breaks: 3-D read as a string at 1.50 ms gives {string(X, 0.0015)*um:.0f} um; 3-D is at {ball_closed(X, 0.0015)*um:.0f} um")
s11, last11, dt11 = grid(1.1, 136)
f11 = next(k for k in range(137) if s11[k] != 0.0)
print(f"what breaks: Courant 1.1, first motion at {f11*dt11*ms:.2f} ms; largest |u| at {136*dt11*ms:.2f} ms = 10^{math.log10(max(abs(v) for v in last11)*um):.1f} um")
print(f"figure, px: tap ({40 + 10*(-1+15):.0f}..{40 + 10*(1+15):.0f}, 260); P ({40 + 10*(10+15):.0f}, {260 - 150*1.0:.0f}); base ({40 + 10*(0+15):.0f}..{40 + 10*(20+15):.0f}, 260); first motion y {260 - 150*t_on*ms:.0f}")
assert gap < 1e-12                                   # the neighbour-only grid lands on d'Alembert's formula
assert abs(first * dt - t_on) < dt + 1e-12            # and the grid's first motion sits at the cone's edge
assert all(abs(e - ex) < 0.01 * V0 * V0 * RHO * A for _, e, ex in E)    # differenced energy matches the half-tap count
assert all(E[k + 1][1] <= E[k][1] + 1e-9 for k in range(len(E) - 1))    # energy in the shrinking cone never rises
assert all(abs(ball_closed(X, tm / ms) - ball_kirchhoff(X, tm / ms)) < 1e-3 * V0 * A * A / (4 * C * X) for tm in (0.95, 1.0, 1.2))
assert abs(a2 - s2) < 1e-15 and abs(s2 - string(X, 0.001)) < 1e-12   # data outside [0, 20] cm changes nothing
assert all(abs(l1 - l2) < 0.01 for l1, l2 in lg)      # two roads to the heat's far tail
assert abs(heat(X, 100.0) - heat_simpson(X, 100.0)) < 1e-9 and heat(X - 0.30, 100.0) > 1e-6
assert abs(tp - X * X / (2 * KAPPA)) < 0.01 * tp     # the peak time matches the point-source rule
assert f11 * dt11 > t_on + 0.05e-3                   # Courant 1.1: the grid's cone is too narrow to see the tap in time
print("ALL CHECKS PASS")
