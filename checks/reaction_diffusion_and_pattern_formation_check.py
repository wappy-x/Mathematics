# Reaction-diffusion on a simulated fish skin: Fisher's front speed and Turing's stripes.
# Illustrative constants: growth r = 1 per day, spreading D = 0.01 mm^2/day.
# Scaled units: length sqrt(D/r) = 0.1 mm, time 1/r = 1 day.
import math
R, D = 1.0, 0.01
ELL = math.sqrt(D / R)  # mm per scaled length unit

def fmt_e(x):
    return "%.3e" % x

# Part 1: Fisher's front, u_t = u_xx + u(1 - u) in scaled units, where c* = 2.
c_mm = 2 * math.sqrt(R * D)
c_star = c_mm / (ELL * R)
print("front speed c* = %.3f mm/day; 5 mm of bare skin covered in %.1f days" % (c_mm, 5.0 / c_mm))
print("wrong: sqrt(rD) = %.3f mm/day; diffusion alone: half cover stays at the edge, blurred by sqrt(2Dt) = %.3f mm at 25 days" % (math.sqrt(R * D), math.sqrt(2 * D * 25)))

def min_shape(c):  # the front shape U(xi) leaving the saddle U = 1 by RK4; returns its lowest value
    mu = (-c + math.sqrt(c * c + 4)) / 2
    U, W, h, low = 1 - 1e-6, -1e-6 * mu, 0.01, 1.0
    F = lambda U, W: (W, -c * W - U * (1 - U))
    for _ in range(10000):
        k1 = F(U, W); k2 = F(U + h / 2 * k1[0], W + h / 2 * k1[1])
        k3 = F(U + h / 2 * k2[0], W + h / 2 * k2[1]); k4 = F(U + h * k3[0], W + h * k3[1])
        U += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]); W += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        low = min(low, U)
    return low
for c in (1.8, 2.2):
    print("shape at speed %.2f mm/day: scaled c^2 - 4 = %.2f, lowest density %s" % (c * ELL, c * c - 4, fmt_e(min_shape(c))))
assert min_shape(1.8) < -1e-6 and min_shape(2.2) > 0  # below c* the shape must go negative

def fisher(dx):  # explicit grid on [0, 140], no-flux ends; returns front positions at t = 10..60
    dt, n = 0.4 * dx * dx, int(round(140 / dx)) + 1
    u = [1.0 if i * dx < 10 else 0.0 for i in range(n)]
    per, pos = int(round(10 / dt)), []
    for s in range(1, 6 * per + 1):
        new = u[:]
        for i in range(1, n - 1):
            new[i] = u[i] + dt * ((u[i - 1] - 2 * u[i] + u[i + 1]) / (dx * dx) + u[i] * (1 - u[i]))
        new[0], new[n - 1] = new[1], new[n - 2]
        u = new
        if s % per == 0:
            i = next(j for j in range(n - 1) if u[j] >= 0.5 > u[j + 1])
            pos.append((i + (u[i] - 0.5) / (u[i] - u[i + 1])) * dx)
    return pos
speeds = []
for dx in (0.5, 0.25, 0.125):
    p = fisher(dx)
    speeds.append((p[5] - p[3]) / 20)
    print("grid %.4f mm: speed over days 40-60 = %.4f mm/day" % (dx * ELL, speeds[-1] * ELL))
print("front at days 10..60 (mm): " + " ".join("%.2f" % (x * ELL) for x in p) + "; bare skin crossed by day 30 = %.2f mm" % ((p[2] - 10) * ELL))
order = math.log2((speeds[1] - speeds[0]) / (speeds[2] - speeds[1]))
rich = speeds[2] + (speeds[2] - speeds[1]) / 3
bram = c_star - 1.5 * math.log(60 / 40) / 20
print("observed order %.2f; extrapolated speed %.4f; Bramson c* - 1.5 l ln(60/40)/20 = %.4f mm/day" % (order, rich * ELL, bram * ELL))
assert all(v < c_star for v in speeds) and abs(rich - bram) < 0.003 and 1.7 < order < 2.3

# Part 2: Turing's instability in the Schnakenberg model, u_t = u_xx + f, v_t = d v_xx + g.
A, B = 0.1, 0.9
f = lambda u, v: A - u + u * u * v
g = lambda u, v: B - u * u * v
u0, v0 = A + B, B / ((A + B) * (A + B))
fu, fv, gu, gv = -1 + 2 * u0 * v0, u0 * u0, -2 * u0 * v0, -u0 * u0
h = 1e-4
num = [(f(u0 + h, v0) - f(u0 - h, v0)) / (2 * h), (f(u0, v0 + h) - f(u0, v0 - h)) / (2 * h),
       (g(u0 + h, v0) - g(u0 - h, v0)) / (2 * h), (g(u0, v0 + h) - g(u0, v0 - h)) / (2 * h)]
assert max(abs(x - y) for x, y in zip(num, (fu, fv, gu, gv))) < 1e-8
tr, det = fu + gv, fu * gv - fv * gu
print("uniform state u0 = %.3f, v0 = %.3f; fu fv gu gv = %.2f %.2f %.2f %.2f; trace %.2f, det %.2f" % (u0, v0, fu, fv, gu, gv, tr, det))
assert tr < 0 and det > 0 and abs(f(u0, v0)) + abs(g(u0, v0)) < 1e-12

def sigma(k2, d):  # larger growth rate of the mode cos(kx), per day
    p, q = fu - k2, gv - d * k2
    disc = (p + q) * (p + q) - 4 * (p * q - fv * gu)
    return (p + q + math.sqrt(disc)) / 2 if disc >= 0 else (p + q) / 2
s_c = (math.sqrt(det) + math.sqrt(det - fu * gv)) / fu
d_c = s_c * s_c
lo, hi = 1.0, 20.0  # second road: bisect on the scanned worst determinant
for _ in range(50):
    mid = (lo + hi) / 2
    worst = min((fu - q) * (gv - mid * q) - fv * gu for q in [i * 1e-4 for i in range(1, 15000)])
    lo, hi = (mid, hi) if worst > 0 else (lo, mid)
print("threshold: sqrt(d_c) = %.3f; d_c formula %.4f, scan %.4f; D_v must exceed %.4f mm^2/day" % (s_c, d_c, lo, d_c * D))
assert abs(d_c - lo) < 1e-3
kc = math.sqrt(math.sqrt(det / d_c))
print("first stripe spacing at onset 2 pi/k_c = %.3f mm" % (2 * math.pi / kc * ELL))
d = 20.0
m = fu * d + gv
q1, q2 = [(m + s * math.sqrt(m * m - 4 * d * det)) / (2 * d) for s in (1, -1)]
print("d = 20: m = %.2f; unstable k^2 from %.4f to %.4f (scaled); spacings %.3f to %.3f mm" % (m, q2, q1, 2 * math.pi / math.sqrt(q1) * ELL, 2 * math.pi / math.sqrt(q2) * ELL))
kbest = max((sigma((i * 1e-4) * (i * 1e-4), d), i * 1e-4) for i in range(1, 20000))[1]
print("fastest mode: k = %.3f rad/mm, spacing %.3f mm, growth %.4f per day" % (kbest / ELL, 2 * math.pi / kbest * ELL, sigma(kbest * kbest, d)))
for dd in (5.0, d_c, 20.0):
    print("sigma, d = %.2f, k = 1..10 rad/mm: " % dd + " ".join("%.3f" % sigma((j * ELL) * (j * ELL), dd) for j in range(1, 11)))

def splitmix(seed):
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
        z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
        yield ((z ^ (z >> 31)) >> 11) / 2 ** 53

def ring(d, L, n, T, start, every=0):  # explicit grid on a ring of skin; returns u, v and a log
    dx = L / n; dt = 0.2 * dx * dx / d
    u, v, log = list(start), [v0] * n, []
    steps = int(round(T / dt)); per = int(round(every / dt)) if every else 0
    for s in range(steps + 1):
        if per and s % per == 0:
            peaks = sum(1 for i in range(n) if u[i] > u[i - 1] and u[i] >= u[(i + 1) % n] and u[i] > u0)
            log.append((round(s * dt), max(abs(x - u0) for x in u), peaks))
        if s == steps: break
        un, vn = [0.0] * n, [0.0] * n
        for i in range(n):
            l, p, uuv = i - 1, (i + 1) % n, u[i] * u[i] * v[i]
            un[i] = u[i] + dt * ((u[l] - 2 * u[i] + u[p]) / (dx * dx) + A - u[i] + uuv)
            vn[i] = v[i] + dt * (d * (v[l] - 2 * v[i] + v[p]) / (dx * dx) + B - uuv)
        u, v = un, vn
    return u, v, log
rng, LR, NR = splitmix(7), 64.0, 128  # ring length (scaled) and grid points
noise = [u0 + 0.01 * (2 * next(rng) - 1) for _ in range(NR)]
u, v, log = ring(20.0, LR, NR, 100.0, noise, every=5)
for t, amp, pk in log[:9]:
    print("day %3d: largest departure %s, peaks %d" % (t, fmt_e(amp), pk))
print("day 100: %d stripes on a %.1f mm ring, spacing %.3f mm; predicted %.2f" % (log[-1][2], LR * ELL, LR * ELL / log[-1][2], LR / (2 * math.pi / kbest)))
assert log[-1][2] == 5 and abs(LR / (2 * math.pi / kbest) - log[-1][2]) < 0.5
print("stripe profile u, every 0.2 mm: " + " ".join("%.2f" % u[i] for i in range(0, NR, 4)))
k5 = 2 * math.pi * 5 / 64  # third road: one small mode grows at sigma(k)
one = [u0 + 1e-6 * math.cos(k5 * i * 0.5) for i in range(128)]
mlog = ring(20.0, 64.0, 128, 20.0, one, every=10)[2]
rate = math.log(mlog[2][1] / mlog[1][1]) / 10
print("mode 5 (k = %.3f rad/mm) grows at %.4f per day on the grid; formula %.4f" % (k5 / ELL, rate, sigma(k5 * k5, d)))
print("mode 5 alone, per day: reaction %.3f; activator spreading %.3f; substrate spreading %.3f; together %.3f" % (sigma(0.0, d), -k5 * k5, -d * k5 * k5, sigma(k5 * k5, d)))
assert abs(rate - sigma(k5 * k5, d)) < 0.003
eq = ring(1.0, 64.0, 128, 100.0, noise[:128])[0]
small = ring(20.0, 7.0, 14, 100.0, noise[:14])[0]
print("equal diffusion d = 1: departure at day 100 = %s" % fmt_e(max(abs(x - u0) for x in eq)))
print("0.7 mm ring, d = 20: departure at day 100 = %s" % fmt_e(max(abs(x - u0) for x in small)))
assert max(abs(x - u0) for x in eq) < 1e-5 and max(abs(x - u0) for x in small) < 1e-5
print("ALL CHECKS PASS")
