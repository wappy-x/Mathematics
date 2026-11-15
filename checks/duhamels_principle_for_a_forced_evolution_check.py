# Duhamel's principle for a forced evolution -- the check behind the card.  Standard library only.
# A room heated by a radiator on 06:00-07:00 and 09:00-12:00 (t = 0 is 06:00, t in hours).
# Rehearsal: one number u = temperature above 12 C, u' = -k u + q on(t).
# Profile: u(x, t) across a 4 m room, u' = kappa u'' + f, walls held at 12 C.
# Roads: Duhamel in closed form, a sum of nudges, RK4 and Crank-Nicolson steppers.
import math
PI = math.pi
K, Q, U0, BLOCKS = 0.5, 5.0, 4.0, ((0.0, 1.0), (3.0, 6.0))

def close(a, b, tol):
    assert abs(a - b) <= tol, (a, b)

def block_part(rate, a, b, t, size):  # integral over [a, min(b, t)] of size e^(-rate (t - s)) ds
    if t <= a:
        return 0.0
    e = min(b, t)
    return size / rate * (math.exp(-rate * (t - e)) - math.exp(-rate * (t - a)))

def duhamel(t, rate=K, start=U0):
    return start * math.exp(-rate * t) + sum(block_part(rate, a, b, t, Q) for a, b in BLOCKS)

def on(s):
    return 1.0 if any(a <= s < b for a, b in BLOCKS) else 0.0

# Road three: RK4 on u' = -k u + q on(t) itself, 0.01 h steps; rate and forcing fixed within a step.
def rk4(rate_of, dt=0.01, steps=600, u=U0):
    for j in range(steps):
        w, a = on((j + 0.5) * dt) * Q, rate_of((j + 0.5) * dt)  # switches fall on step edges
        k1 = a * u + w
        k2 = a * (u + dt / 2 * k1) + w
        k3 = a * (u + dt / 2 * k2) + w
        k4 = a * (u + dt * k3) + w
        u += dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    return u

# 1. The one-number room: the start and each heating block, carried forward to time t.
print("room, t (h), clock, start part, block 1, block 2, rise (C), temperature (C)")
for t in range(9):
    p0, p1, p2 = U0 * math.exp(-K * t), block_part(K, 0, 1, t, Q), block_part(K, 3, 6, t, Q)
    close(p0 + p1 + p2, rk4(lambda s: -K, steps=100 * t), 1e-9)  # against road three, hour by hour
    print(f"room, {t}, {6 + t:02d}:00, {p0:.6f}, {p1:.6f}, {p2:.6f}, {p0 + p1 + p2:.6f}, {12 + p0 + p1 + p2:.2f}")
noon = duhamel(6.0)
# Road two: add the nudges q on(s) ds slice by slice, each decayed by its age t - s (slice middle).
print("nudges, slice width ds (h), sum of nudges at noon, error")
for ds in (0.5, 0.1, 0.01, 0.001):
    m = round(6.0 / ds)
    tot = U0 * math.exp(-K * 6.0) + sum(math.exp(-K * (6.0 - (j + .5) * ds)) * Q * on((j + .5) * ds) * ds for j in range(m))
    print(f"nudges, {ds}, {tot:.6f}, {tot - noon:.9f}")
    close(tot, noon, 0.2 * ds * ds)  # midpoint slices: error falls like ds squared
r = rk4(lambda s: -K)
close(r, noon, 1e-9)
close(noon, 4 * math.exp(-3) + 10 * (math.exp(-2.5) - math.exp(-3)) + 10 * (1 - math.exp(-1.5)), 1e-12)
print(f"room at noon, Duhamel {noon:.6f}, RK4 {r:.6f}, temperature {12 + noon:.2f} C")
print("chart, temperature every half hour, " + ", ".join(f"{12 + duhamel(j / 2):.2f}" for j in range(17)))
print("chart, target, " + ", ".join(f"{12 + 10 * on(j / 2):.0f}" for j in range(17)))

# 2. The profile: sine modes sin(n pi x / L) diagonalise the flow; mode n decays at lam_n.
L, KAP, QR, RA, RB = 4.0, 0.8, 40.0, 0.25, 0.75  # radiator band 0.25-0.75 m heats at 40 C/h
lam = lambda n: KAP * (n * PI / L) ** 2
qn = lambda n: 2 * QR / (n * PI) * (math.cos(n * PI * RA / L) - math.cos(n * PI * RB / L))
un0 = lambda n: 2 * U0 / (n * PI) * (1 - math.cos(n * PI))
def coef(n, t):
    return un0(n) * math.exp(-lam(n) * t) + sum(block_part(lam(n), a, b, t, qn(n)) for a, b in BLOCKS)
def profile(x, t, N):
    return sum(coef(n, t) * math.sin(n * PI * x / L) for n in range(1, N + 1))
print(f"flow, mode 1 decays at {lam(1):.6f} per hour, mode 10 at {lam(10):.6f} per hour")
XS = (0.5, 2.0, 3.5)
ref = [profile(x, 6.0, 20000) for x in XS]
print("modes, N, error at 0.5 m, at 2.0 m, at 3.5 m (C, against N = 20000)")
for N in (10, 40, 160, 640):
    err = [profile(x, 6.0, N) - v for x, v in zip(XS, ref)]
    print("modes, " + str(N) + ", " + ", ".join(f"{e:.9f}" for e in err))
    if N == 10:
        err10 = err[0]
assert abs(err10) > 0.05 and abs(profile(0.5, 6.0, 640) - ref[0]) < 1e-5
# Crank-Nicolson on M cells: (I - dt/2 A) u_new = (I + dt/2 A) u + dt f, solved by the Thomas sweep.
M, dt = 160, 0.01
h = L / M
u = [0.0] + [U0] * (M - 1) + [0.0]
src = [QR * (1.0 if RA < j * h < RB else 0.5 if abs(j * h - RA) < 1e-9 or abs(j * h - RB) < 1e-9 else 0.0) for j in range(M + 1)]
c = KAP * dt / (2 * h * h)
for step in range(600):
    w = on((step + 0.5) * dt)
    rhs = [u[j] + c * (u[j - 1] - 2 * u[j] + u[j + 1]) + dt * w * src[j] for j in range(1, M)]
    cp, dp = [0.0] * (M - 1), [0.0] * (M - 1)
    for i in range(M - 1):
        den = (1 + 2 * c) + (c * cp[i - 1] if i else 0.0)
        cp[i], dp[i] = -c / den, (rhs[i] + (c * dp[i - 1] if i else 0.0)) / den
    for i in range(M - 2, -1, -1):
        u[i + 1] = dp[i] - (cp[i] * u[i + 2] if i < M - 2 else 0.0)
cn = [u[round(x / h)] for x in XS]
for a, b in zip(cn, ref):
    close(a, b, 2e-3)
print("profile at noon (C), x = 0.5 m, 2.0 m, 3.5 m: modes " + ", ".join(f"{12 + v:.3f}" for v in ref)
      + "; Crank-Nicolson " + ", ".join(f"{12 + v:.3f}" for v in cn))
# The forcing is not in the domain D(A); the mild solution at noon is.  Sizes as RMS over the room.
print("domain, N, RMS of A f_N (C/h^2), RMS of A u_N at noon (C/h)")
for N in (10, 100, 1000, 10000):
    aq = math.sqrt(0.5 * sum((lam(n) * qn(n)) ** 2 for n in range(1, N + 1)))
    au = math.sqrt(0.5 * sum((lam(n) * coef(n, 6.0)) ** 2 for n in range(1, N + 1)))
    print(f"domain, {N}, {aq:.3f}, {au:.6f}")
assert aq > 1e5 and au < 30

# 3. What breaks.
wrong_age = U0 * math.exp(-K * 6) + sum(Q / K * (math.exp(-K * a) - math.exp(-K * b)) for a, b in BLOCKS)
close(wrong_age, 4 * math.exp(-3) + 10 * (1 - math.exp(-0.5)) + 10 * (math.exp(-1.5) - math.exp(-3)), 1e-12)
print(f"breaks, carry each nudge by its arrival time s, not its age: {12 + wrong_age:.2f} C, true {12 + noon:.2f} C")
print(f"breaks, add the nudges with no decay: {12 + U0 + Q * 4:.2f} C")
print(f"breaks, drop the start term: {12 + noon - U0 * math.exp(-3):.2f} C")
win = rk4(lambda s: -1.5 if 1 <= s < 3 else -K)  # window open 07:00-09:00 triples the loss rate
step_by_step = (duhamel(1.0) * math.exp(-3) * math.exp(-1.5)) + block_part(K, 3, 6, 6, Q)
close(win, step_by_step, 1e-9)
print(f"breaks, window open 07:00-09:00, one fixed flow: {12 + noon:.2f} C, true {12 + win:.2f} C")
print(f"breaks, 10 modes at the radiator: off by {err10:.3f} C")
print("ALL CHECKS PASS")
