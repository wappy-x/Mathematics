# d'Alembert by characteristics -- the check behind the card.  The open A string
# of a guitar, 65 cm long, is pulled 3 mm aside a third of the way along and let
# go from rest.  Road 1 is d'Alembert's formula, the held ends built in by the
# odd extension.  Road 2 rides the characteristics: the signal w = u_t - c u_x is
# read back along a right-moving line, then summed by RK4 along a left-moving
# one.  Road 3 marches the string in whole numbers on a grid of characteristics,
# ends held at zero.  Nothing is imported.
L, H, FREQ = 0.65, 3.0, 110                # string length (m), pluck height (mm), note (Hz)
c = 2 * L * FREQ                           # wave speed (m/s): the open A string
a = L / 3                                  # pluck point, m from the bridge
PER = 2 * L / c                            # one period (s)

def f(y): return H * y / a if y <= a else H * (L - y) / (L - a)    # starting shape, mm
def fp(y): return H / a if y < a else -H / (L - a)                 # its slope, mm per m
def fext(y):                               # f made odd about each end, period 2L
    y = y % (2 * L)
    return f(y) if y <= L else -f(2 * L - y)
def u(x, t): return (fext(x - c * t) + fext(x + c * t)) / 2         # road 1: d'Alembert
def fz(y): return f(y) if 0 <= y <= L else 0.0                      # mistake: ends ignored
def z(v): return 0.0 if abs(v) < 1e-9 else v                        # no "-0.00" in print
def fold(y):                               # a path at speed c, bounced between the ends
    y = y % (2 * L)
    return y if y <= L else 2 * L - y

def ride(x, t, n):                         # road 2: RK4 along the left-moving line
    w = lambda s: -c * fp(x + c * t - 2 * c * s)   # w = u_t - c u_x, read back to t = 0
    total, k = f(x + c * t), t / n         # start: the height where the line meets t = 0
    for i in range(n):
        s = i * k                          # du/ds = w(s) holds no u, so RK4 is Simpson
        k1, k2, k4 = w(s), w(s + k / 2), w(s + k)
        total += k * (k1 + 4 * k2 + k4) / 6
    return total

X, T = L / 2, PER / 10                     # 12th fret (half way), a tenth of a period
ans = u(X, T)
print(f"c = 2 x 0.65 m x {FREQ:g} Hz = {c:.0f} m/s; period 2L/c = {1000 * PER:.4f} ms; pluck at {100 * a:.4f} cm")
print(f"t = {1000 * T:.4f} ms: ct = {100 * c * T:.4f} cm; feet at {100 * (X - c * T):.4f} and {100 * (X + c * T):.4f} cm")
print(f"triangle: pieces {100 * a:.4f} and {100 * (L - a):.4f} cm, slopes {H / a:.4f} and {-H / (L - a):.4f} mm per m, steepest {H / a / 1000:.4f}")
print(f"f at the feet: {f(X - c * T):.4f} and {f(X + c * T):.4f} mm; started at f(32.5 cm) = {f(X):.4f} mm")
print(f"road 1, d'Alembert: u(32.5 cm, {1000 * T:.4f} ms) = {ans:.4f} mm")
vv, ww = c * fp(X + c * T) / 1000, -c * fp(X - c * T) / 1000      # m/s
print(f"signals at the point: v = u_t + c u_x = {vv:.4f} m/s, w = u_t - c u_x = {ww:.4f} m/s")
print(f"so u_t = (v + w)/2 = {(vv + ww) / 2:.4f} m/s and u_x = (v - w)/(2c) = {1000 * (vv - ww) / (2 * c):.4f} mm per m")
err = []
for n in (20, 40, 80):
    r = ride(X, T, n); err.append(abs(r - ans))
    print(f"road 2, RK4 {n} steps: {r:.6f} mm, error {err[-1]:.6f} mm, one step x jump / 6 = {T / n * c * (H / a + H / (L - a)) / 6:.6f} mm")
print(f"road 2 error ratios: {err[0] / err[1]:.2f} {err[1] / err[2]:.2f} (first order: a corner sits inside one step)")
N = 30                                     # road 3: cells of L/30; time step L/(30c)
F = [12 * j if j <= 10 else 6 * (N - j) for j in range(N + 1)]    # 40 x f, whole numbers
assert all((F[j - 1] + F[j + 1]) % 2 == 0 for j in range(1, N))   # first step stays whole
rows = [F, [0] + [(F[j - 1] + F[j + 1]) // 2 for j in range(1, N)] + [0]]   # from rest
for n in range(2, 2 * N + 1):              # u(t + dt) = u(x - dx) + u(x + dx) - u(t - dt)
    p, q = rows[-1], rows[-2]
    rows.append([0] + [p[j - 1] + p[j + 1] - q[j] for j in range(1, N)] + [0])
print(f"grid: dx = L/30 = {100 * L / N:.4f} cm, dt = dx/c = {1000 * L / N / c:.4f} ms; corners travel {c / 10:.1f} cm per ms; extension repeats every {200 * L:.0f} cm")
gap = max(abs(rows[6][j] / 40 - u(j * L / N, 6 * PER / (2 * N))) for j in range(N + 1))
print(f"road 3, grid in 1/40 mm: u(32.5 cm, 6 steps) = {rows[6][15]}/40 = {rows[6][15] / 40:.4f} mm; every point within 1e-12 mm of road 1: {'yes' if gap < 1e-12 else 'no'}")
half = all(rows[N][j] == -F[N - j] for j in range(N + 1)); full = rows[2 * N] == F
print(f"grid at half a period, the start flipped and mirrored: {'yes' if half else 'no'}; after a whole period, the start: {'yes' if full else 'no'}")
lc, rc = fold(a - c * T), fold(a + c * T)  # the two corners ride x = a -/+ ct
print(f"corners at {100 * lc:.4f} cm ({u(lc, T):.4f} mm) and {100 * rc:.4f} cm ({u(rc, T):.4f} mm)")
for m in (1 / 6, 1 / 3, 1 / 2, 1):         # the corners through one period
    t = m * PER; p, q = fold(a - c * t), fold(a + c * t)
    print(f"moment {1000 * t:.4f} ms: corners at {100 * p:.2f} cm ({z(u(p, t)):.2f} mm), {100 * q:.2f} cm ({z(u(q, t)):.2f} mm)")
e = 1e-4; sl, sr = (u(rc, T) - u(rc - e, T)) / e, (u(rc + e, T) - u(rc, T)) / e
print(f"slopes either side of the right corner: {sl:.4f} and {sr:.4f} mm per m; jump {sl - sr:.4f}, half the start's {H / a + H / (L - a):.4f}")
print(f"half a period, {1000 * PER / 2:.4f} ms: u(43.33 cm) = {u(L - a, PER / 2):.4f} mm, u(32.5 cm) = {u(X, PER / 2):.4f} mm")
def res(x, t, h):                          # (u_tt / c^2 - u_xx) by centred differences, mm per m^2
    k = h / (2 * c)
    return (u(x, t + k) - 2 * u(x, t) + u(x, t - k)) / (c * k) ** 2 - (u(x + h, t) - 2 * u(x, t) + u(x - h, t)) / h ** 2
rr = [res(rc, T, h) for h in (1e-3, 5e-4)]
print(f"residual at 32.5 cm: {abs(z(res(X, T, 1e-3))):.4f}; at the right corner: h = 1 mm {rr[0]:.1f}, h = 0.5 mm {rr[1]:.1f} mm per m^2")
print(f"mistake 1, no 1/2: {2 * ans:.4f} mm; mistake 2, right-mover only f(x - ct): {f(X - c * T):.4f} mm")
print(f"mistake 3, ends ignored: bridge at {1000 * T:.4f} ms moves to {(fz(-c * T) + fz(c * T)) / 2:.4f} mm;"
      f" 32.5 cm at half a period {z((fz(X - L) + fz(X + L)) / 2):.4f} mm, not {u(X, PER / 2):.4f}")
for t in (0, PER / 10, PER / 2):
    print(f"chart, t = {1000 * t:.4f} ms:", ", ".join(f"{z(u(j * L / 15, t)):.2f}" for j in range(16)))
print("figure, corner paths (cm, ms):", "; ".join(f"({100 * x:.2f}, {1000 * s / c:.4f})" for x, s in
      [(a, 0), (0, a), (L, L - a), (L - a, L), (L, L + a), (0, 2 * L - a), (a, 2 * L)]))
assert abs(ans - 2.025) < 1e-12 and abs(u(X, 0) - 2.25) < 1e-12                       # by hand
assert all(abs(err[i] - T / n * c * (H / a + H / (L - a)) / 6) < 1e-9 for i, n in enumerate((20, 40, 80)))
assert abs(err[0] / err[1] - 2) < 1e-6 and abs(err[1] / err[2] - 2) < 1e-6          # road 2 converges
assert rows[6][15] == 81 and gap < 1e-12 and half and full                           # road 3, exact
assert abs(sl - sr - (H / a + H / (L - a)) / 2) < 1e-6                                # half the jump
assert abs(res(X, T, 1e-3)) < 1e-3 and rr[1] / rr[0] > 1.9                           # corner: no u_xx
print("ALL CHECKS PASS")
