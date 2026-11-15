# Eikonal and traffic -- the check behind the card.  Standard library only.
# Sound: arrival time T = min over the speaker towers of distance / c, against a fast-sweeping
# grid that knows no formula, and the residual |grad T| c = 1 by centred differences.
# Traffic: a motorway lane blocked for 6 min.  Rankine-Hugoniot and the backward wave speed
# against Newell's minimum formula for the car count N(x, t), which knows neither.
from math import sqrt

C = 343.0                                    # speed of sound in air at 20 C, m/s
TOWERS = ((0.0, 0.0), (100.0, 0.0))          # speaker towers at the two ends of the straight, m
def dists(x, y): return [sqrt((x - a) ** 2 + (y - b) ** 2) for a, b in TOWERS]
def T(x, y): return min(dists(x, y)) / C     # first arrival: the viscosity solution, s
def Tlate(x, y): return max(dists(x, y)) / C # later arrival: also |grad T| = 1/c off the ridge

def grad_c(f, x, y, d=0.01):                 # |grad f| times c, by centred differences
    gx = (f(x + d, y) - f(x - d, y)) / (2 * d); gy = (f(x, y + d) - f(x, y - d)) / (2 * d)
    return sqrt(gx * gx + gy * gy) * C

def sweep(h, X0=-20.0, LX=140.0, LY=60.0):  # road 2: fast sweeping with the upwind update
    nx, ny = round(LX / h) + 1, round(LY / h) + 1
    INF = 1e9; G = [[INF] * ny for _ in range(nx)]
    for a, b in TOWERS: G[round((a - X0) / h)][round(b / h)] = 0.0
    f = h / C
    for _ in range(2):
        for I in (range(nx), range(nx - 1, -1, -1)):
            for J in (range(ny), range(ny - 1, -1, -1)):
                for i in I:
                    Gi = G[i]; Gl = G[i - 1] if i > 0 else None; Gr = G[i + 1] if i < nx - 1 else None
                    for j in J:
                        a = min(Gl[j] if Gl else INF, Gr[j] if Gr else INF)
                        b = min(Gi[j - 1] if j > 0 else INF, Gi[j + 1] if j < ny - 1 else INF)
                        t = min(a, b) + f if abs(a - b) >= f else (a + b + sqrt(2 * f * f - (a - b) ** 2)) / 2
                        if t < Gi[j]: Gi[j] = t
    err = max(abs(G[i][j] - T(X0 + i * h, j * h)) for i in range(nx) for j in range(ny))
    return G[round((30 - X0) / h)][round(40 / h)], err

print("SOUND: towers at (0, 0) m and (100, 0) m, c = 343 m/s; seat at (30, 40) m")
d = dists(30, 40)
print(f"seat: {d[0]:.2f} m from the near tower, {d[1]:.2f} m from the far one")
print(f"first arrival T = {T(30, 40):.4f} s; later arrival {Tlate(30, 40):.4f} s; gap {1000 * (Tlate(30, 40) - T(30, 40)):.1f} ms")
print(f"ridge seat (50, 40): {dists(50, 40)[0]:.2f} m from both towers, T = {T(50, 40):.4f} s")
r_seat, r_late, r_ridge = grad_c(T, 30, 40), grad_c(Tlate, 30, 40), grad_c(T, 50, 40)
print(f"residual |grad T| c: seat {r_seat:.6f}, later arrival at seat {r_late:.6f}, on the ridge {r_ridge:.4f}")
errs = []
for h in (1.0, 0.5, 0.25):
    seat, err = sweep(h); errs.append(err)
    print(f"road 2, fast sweeping h = {h} m: seat {seat:.4f} s, largest error {1000 * err:.2f} ms")
print(f"error ratios as h halves: {errs[0] / errs[1]:.2f}, {errs[1] / errs[2]:.2f} (order about 1, slowed by log(1/h) at the towers)")
print(f"hand timing, gun to finish 100 m: {100 / C:.4f} s; try, 35 C day, c = 352 m/s: seat {50 / 352:.4f} s")
xs = [-20 + 10 * k for k in range(15)]
print("chart, row 40 m back, first arrival ms:", ", ".join(f"{1000 * T(x, 40):.0f}" for x in xs))
print("chart, row 40 m back, later arrival ms:", ", ".join(f"{1000 * Tlate(x, 40):.0f}" for x in xs))

VF, W, RJ = 90.0, 18.0, 150.0                # free speed km/h, backward wave speed km/h, jam cars/km
RC = W * RJ / (VF + W); QC = VF * RC         # critical density, capacity
RU = 15.0; QU = VF * RU; TAU = 0.1           # arriving density and flow; lane blocked 0.1 h = 6 min
def q(r): return min(VF * r, W * (RJ - r))   # Newell's triangular flow rule, cars/h
S = (q(RJ) - q(RU)) / (RJ - RU)              # Rankine-Hugoniot speed of the tail, km/h
L = -S * TAU                                 # jam length when the lane reopens, km
TEND = TAU + L / (W + S); XEND = -W * (TEND - TAU)   # head (at -W) meets tail (at S)
D = RJ * 0.5 * L * TEND                      # car-hours stopped: the jam's area in (x, t) times RJ
CAUGHT = (QU - RU * S) * TEND                # cars that cross the tail
def car_delay(n):                            # car n starts at -n/RU km, drives at VF until the tail
    t1 = n / (RU * (VF - S)); t2 = TAU - S * t1 / W
    return t2 - t1, t2 + (-S * t1) / VF      # stopped time, arrival at the crash site

def N0(x): return -RU * x                    # car count at the crash, t = 0
def newell(x, t):                            # road 2: Newell's minimum formula, no shock rule inside
    best = min(N0(x - VF * t), N0(x + W * t) + RJ * W * t)
    tp = min(TAU, t + x / W) if x <= 0 else min(TAU, t - x / VF)   # latest usable blocked moment
    return min(best, QC * (t - tp) - RC * x) if tp >= 0 else best
def rho(x, t, e=1e-7): return -(newell(x + e, t) - newell(x - e, t)) / (2 * e)
def bisect(f, lo, hi):
    for _ in range(60):
        m = (lo + hi) / 2
        if f(m): hi = m
        else: lo = m
    return (lo + hi) / 2

print(f"TRAFFIC: free {VF:.0f} km/h, wave back {W:.0f} km/h, jam {RJ:.0f} cars/km; capacity {QC:.0f} cars/h at {RC:.0f} cars/km")
print(f"arriving {QU:.0f} cars/h at {RU:.0f} cars/km; lane blocked {60 * TAU:.0f} min")
print(f"tail speed (0 - {QU:.0f})/({RJ:.0f} - {RU:.0f}) = {S:.1f} km/h; jam {L:.2f} km, {RJ * L:.0f} cars at reopening")
print(f"count: {RU * L:.0f} cars were on that km + {QU * TAU:.0f} arrived = {RU * L + QU * TAU:.0f}")
print(f"head at {-W:.0f} km/h meets tail at {60 * TEND:.1f} min, {XEND:.2f} km; jam outlives the crash by {60 * (TEND - TAU):.1f} min")
print(f"cars cross the tail at {QU:.0f} + {RU:.0f} x {-S:.0f} = {QU - RU * S:.0f} cars/h for {60 * TEND:.1f} min")
print(f"delay {D:.3f} car-hours over {CAUGHT:.1f} cars = {60 * D / CAUGHT:.2f} min each; first car {60 * car_delay(0)[0]:.2f} min")
x6 = bisect(lambda x: rho(x, TAU) > 82.5, -3.0, -0.2)
x12h = bisect(lambda x: rho(x, 0.2) < 87.5, -1.9, -0.5); x12t = bisect(lambda x: rho(x, 0.2) > 82.5, -3.0, -1.9)
print(f"road 2, Newell: tail at 6 min {x6:.4f} km; at 12 min tail {x12t:.4f} km, head {x12h:.4f} km")
print(f"road 2, Newell: cars in the jam at 6 min N(-1, 6 min) - N(0, 6 min) = {newell(-1, TAU) - newell(0, TAU):.4f}")
n = 3600; Dn = sum((QU * k / n - newell(0, k / n) + QU * (k + 1) / n - newell(0, (k + 1) / n)) / 2 for k in range(n)) / n
print(f"road 2, Newell: delay = area between free and real counts at the crash site = {Dn:.4f} car-hours")
t100 = bisect(lambda t: newell(0, t) >= 100, TAU, 0.3); tl = bisect(lambda t: newell(0, t) >= QU * t - 1e-9, TAU, 0.3)
dl, ar = car_delay(100)
print(f"car 100: formula arrives {60 * ar:.3f} min, stopped {60 * dl:.3f} min; Newell arrives {60 * t100:.3f} min, free {60 * 100 / QU:.3f} min")
print(f"last delayed car passes the crash site at {60 * tl:.3f} min, car {QU * tl:.1f}")
for m in range(0, 19, 3):
    t = m / 60; tail = S * t; head = min(0.0, -W * (t - TAU))
    where = f"tail {tail + 0.0:5.2f} km, head {head + 0.0:5.2f} km, jam {head - tail:.2f} km" if t <= TEND else "jam gone"
    print(f"story, {m:2d} min: {where}; past the crash N(0, t) = {newell(0, t) + 0.0:5.1f}, free {QU * t:5.1f}")
print(f"mistake 1, jam gone at reopening: {RJ * 0.5 * L * TAU:.3f} car-hours, not {D:.3f}")
print(f"mistake 2, tail at -{W:.0f} km/h: jam {W * TAU:.1f} km holding {RJ * W * TAU:.0f} cars, but only {RU * W * TAU + QU * TAU:.0f} arrived")
print(f"mistake 3, later arrival at the seat: {Tlate(30, 40):.4f} s, not {T(30, 40):.4f} s")
for ru, tau in ((20.0, 0.1), (15.0, 0.2)):
    s = -VF * ru / (RJ - ru); te = tau * W / (W + s)
    print(f"try, arriving {ru:.0f} cars/km, blocked {60 * tau:.0f} min: jam ends at {60 * te:.1f} min, {-W * (te - tau):.2f} km, delay {RJ * 0.5 * (-s * tau) * te:.3f} car-hours")
print(f"figure, tail (0, 0) to ({XEND:.2f} km, {60 * TEND:.1f} min); head (0, 6.0 min) to the same; free front to (0, {60 * tl:.1f} min)")
print("figure, cars 0 100 200 300 stop at", " ".join(f"({S * k / (RU * (VF - S)) + 0.0:.3f} km, {60 * k / (RU * (VF - S)):.2f} min)" for k in (0, 100, 200, 300)),
      "and leave at", " ".join(f"{60 * (TAU - S * k / (RU * (VF - S)) / W):.2f}" for k in (0, 100, 200, 300)), "min")
assert abs(r_seat - 1) < 1e-6 and abs(r_ridge - 1) > 0.3                     # T obeys the eikonal, not on the ridge
assert errs[2] < 0.0015 and errs[0] > errs[1] > errs[2]                      # the grid settles on min, not max
assert abs(x6 + L) < 1e-9 and abs(x12t - S * 0.2) < 1e-9 and abs(x12h + W * 0.1) < 1e-9   # Newell meets RH, -W
assert abs(Dn - D) < 1e-9 and abs(newell(-1, TAU) - newell(0, TAU) - RJ * L) < 1e-9          # Newell meets areas
assert abs(t100 - ar) < 1e-9 and abs(QU * tl - CAUGHT) < 1e-6               # arrival times agree
print("ALL CHECKS PASS")
