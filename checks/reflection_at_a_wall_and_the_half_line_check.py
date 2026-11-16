# Reflection at a wall -- the check behind the card.  Nothing is imported.
# The open A string of a guitar, wave speed 143 m/s.  A 4 cm stretch near the
# bridge is pinched into a tent 2 mm high at 10 cm and let go from rest.  The
# bridge is the wall at x = 0; the nut, 65 cm away, is too far to matter yet.
# Road 1: d'Alembert's formula on the data extended oddly (clamped end) or
# evenly (free end).  Road 2: march the string on a grid that knows only the
# wall (u = 0 there, or zero slope), never the mirror.  Road 3: total energy
# through the bounce, against its closed form.
L, FREQ = 0.65, 110                       # string length (m), note (Hz)
c = 2 * L * FREQ                          # wave speed, m/s
X0, W, H = 0.10, 0.02, 2.0                # tent centre (m), half-width (m), height (mm)
T1, T2 = X0 / c, 2 * X0 / c               # centre reaches the bridge; back where it began

def phi(y): return H * (1 - abs(y - X0) / W) if abs(y - X0) < W else 0.0   # mm
def dphi(y):                              # its slope, mm per mm
    if abs(y - X0) >= W: return 0.0
    return H / (1000 * W) if y < X0 else -H / (1000 * W)
def F_odd(y): return phi(y) if y >= 0 else -phi(-y)     # clamped end: mirror flipped
def F_even(y): return phi(abs(y))                       # free end: mirror upright
def F_none(y): return phi(y) if y >= 0 else 0.0         # mistake: no mirror at all
def F_two(y):                             # bridge and nut both clamped: odd about each, period 2L
    y %= 2 * L
    return phi(y) if y <= L else -phi(2 * L - y)
def u(F, x, t): return (F(x - c * t) + F(x + c * t)) / 2  # d'Alembert, released from rest
def z(v): return 0.0 if abs(v) < 5e-9 else v              # no "-0.0000" in print

def march(dx, clamped, T):                # road 2: the grid at Courant number 1
    n, steps = round(0.40 / dx), round(T * c / dx)
    old = [phi(j * dx) for j in range(n + 1)]
    def nxt(cur, prev, half):             # one step; the far end at 40 cm stays at 0
        out = [0.0] * (n + 1)
        for j in range(1, n):
            out[j] = (cur[j - 1] + cur[j + 1]) * (0.5 if half else 1.0) - (0.0 if half else prev[j])
        if not clamped:                   # zero slope: the node beyond the end copies node 1
            out[0] = cur[1] * (1.0 if half else 2.0) - (0.0 if half else prev[0])
        return out
    cur = nxt(old, None, True)
    gap = max(abs(cur[j] - u(F_odd if clamped else F_even, j * dx, dx / c)) for j in range(n + 1))
    for s in range(2, steps + 1):
        old, cur = cur, nxt(cur, old, False)
        F = F_odd if clamped else F_even
        gap = max(gap, max(abs(cur[j] - u(F, j * dx, s * dx / c)) for j in range(0, n + 1, 10)))
    return cur, gap

def energy(F, t, N=4000):                 # road 3: kinetic and stretch parts, midpoint rule
    kin = st = 0.0
    for i in range(N):
        x = (i + 0.5) * 0.40 / N          # strip of 0.1 mm; the tent's corners sit on strip edges
        a, b = slope(F, x - c * t), slope(F, x + c * t)
        kin += ((b - a) / 2) ** 2 * 0.40 / N      # (u_t / c)^2
        st += ((a + b) / 2) ** 2 * 0.40 / N       # (u_x)^2
    return kin, st
def slope(F, y):                          # slope of the extended data
    if F is F_odd: return dphi(abs(y))
    return dphi(y) if y >= 0 else -dphi(-y)

E0 = 2 * W * (H / (1000 * W)) ** 2        # closed form: tent's slope squared times its width
mm = lambda x: f"{z(x):.4f}"
print(f"c = 2 x 0.65 m x {FREQ} Hz = {c:.0f} m/s; tent: centre {100 * X0:.0f} cm, half-width {100 * W:.0f} cm, height {H:.0f} mm")
print(f"centre reaches the bridge at {1000 * T1:.4f} ms; back at 10 cm at {1000 * T2:.4f} ms")
print(f"road 1, clamped: u(10 cm, {1000 * T2:.4f} ms) = {mm(u(F_odd, X0, T2))} mm; u(30 cm) = {mm(u(F_odd, 0.30, T2))} mm")
print(f"road 1, free:    u(10 cm, {1000 * T2:.4f} ms) = {mm(u(F_even, X0, T2))} mm; bridge end at {1000 * T1:.4f} ms = {mm(u(F_even, 0, T1))} mm")
print(f"model holds until the right-going front reaches the nut: (65 - 12) cm / c = {1000 * (L - X0 - W) / c:.4f} ms")
print(f"try: tent at 20 cm, echo at {2000 * 0.20 / c:.4f} ms; high E at 330 Hz, c = {2 * L * 330:.0f} m/s, echo at {2000 * X0 / (2 * L * 330):.4f} ms")
gc, gf = march(0.001, True, T2), march(0.001, False, T2)
print(f"road 2, grid dx = 1 mm, step dx/c: clamped u(10 cm) = {mm(gc[0][100])} mm; free u(10 cm) = {mm(gf[0][100])} mm")
print(f"road 2, largest gap to road 1 over the run, mm, below 1e-9: clamped {'yes' if gc[1] < 1e-9 else 'no'}, free {'yes' if gf[1] < 1e-9 else 'no'}")
print(f"clamped end stays at 0: max |u(0, t)| over 200 times = {max(abs(u(F_odd, 0, i * T2 / 199)) for i in range(200)):.4f} mm")
print(f"bars at x = 1 cm, ct = 9.5 cm: incoming half {mm(F_odd(0.105) / 2)}, mirror half {mm(F_odd(-0.085) / 2)}, string {mm(u(F_odd, 0.01, 0.095 / c))} mm")
print("story at x = 1 cm: ct (cm), t (ms), u (mm), bridge slope; incoming half's slope alone")
for ct in (0, 4, 8.5, 9, 9.5, 10.5, 11, 12, 16):
    t = ct / 100 / c
    print(f"  {ct:4.1f}  {1000 * t:.4f}  {mm(u(F_odd, 0.01, t))}  {z(slope(F_odd, ct / 100)):.2f}; {z(dphi(ct / 100) / 2):.3f}")
a, b = slope(F_odd, 0.01 - T1 * c), slope(F_odd, 0.01 + T1 * c)
v3 = c * (slope(F_odd, 0.03 + T1 * c) - slope(F_odd, 0.03 - T1 * c)) / 2   # past the overlap
print(f"at {1000 * T1:.4f} ms: max |u| over 0 to 4 cm = {max(abs(u(F_odd, i / 1000, T1)) for i in range(41)):.4f} mm; "
      f"velocity at 1 cm = {c * (b - a) / 2:.2f} m/s, at 3 cm = {z(v3):.2f} m/s, incoming half alone {c * b / 2:.2f} m/s")
trace = [u(F_odd, X0, k / 100 / c) for k in range(25)]
print("pickup at 10 cm, ct = 0, 1, ..., 24 cm; t (ms):", ", ".join(f"{1000 * k / 100 / c:.2f}" for k in range(25)))
print("pickup at 10 cm, u (mm):", ", ".join(f"{z(v):.1f}" for v in trace))
fr = [energy(F_odd, t) for t in (0, T1, T2)]
print(f"energy / start, clamped, at 0, {1000 * T1:.4f}, {1000 * T2:.4f} ms: " + "; ".join(f"total {(k + s) / E0:.4f}, kinetic {k / E0:.4f}" for k, s in fr))
print(f"figure, panels t = 0, {1000 * T1:.2f}, {1000 * T2:.2f} ms: peaks (cm, mm) (10, {mm(u(F_odd, X0, 0))}) ghost (-10, {mm(u(F_odd, -X0, 0))}); (20, {mm(u(F_odd, 0.2, T1))}) ghost (-20, {mm(u(F_odd, -0.2, T1))}); (10, {mm(u(F_odd, X0, T2))}) (30, {mm(u(F_odd, 0.3, T2))}) ghost (-10, {mm(u(F_odd, -X0, T2))})")
m1, m2, m3 = u(F_none, X0, T2), u(F_even, X0, T2), u(F_odd, X0, T1)
print(f"mistake 1, no mirror: u(10 cm, {1000 * T2:.4f} ms) = {mm(m1)} mm; the half sits at -10 cm, past the bridge")
print(f"mistake 2, even mirror at a clamped end: u(10 cm) = {mm(m2)} mm, and the bridge moves {mm(u(F_even, 0, T1))} mm")
print(f"mistake 3, echo time x0/c = {1000 * T1:.4f} ms: u(10 cm) then = {mm(m3)} mm; the echo is due at {1000 * T2:.4f} ms")
m4, m5 = u(F_odd, 0.55, L / c), u(F_two, 0.55, L / c)   # half a period: the nut has been reached
print(f"hypothesis fails, nut ignored: at half a period, {1000 * L / c:.4f} ms, u(55 cm) = {mm(m4)} mm; with both ends {mm(m5)} mm")
assert abs(u(F_odd, X0, T2) + H / 2) < 1e-12 and abs(u(F_even, X0, T2) - H / 2) < 1e-12  # flipped, upright
assert gc[1] < 1e-9 and gf[1] < 1e-9 and abs(gc[0][100] + 1) < 1e-9  # grid knows only the wall
assert all(abs(u(F_odd, 0, i * T2 / 199)) < 1e-12 for i in range(200))  # mirror holds the bridge at 0
assert all(abs((k + s) / E0 - 1) < 1e-9 for k, s in fr) and abs(fr[1][0] / E0 - 0.75) < 1e-9  # energy
assert abs(u(F_even, 0, T1) - H) < 1e-12 and abs(m1) < 1e-12  # free end doubles; no mirror loses it
assert abs(m4 + H / 2) < 1e-12 and abs(m5 + H) < 1e-12  # past the nut the one-end answer misses half
print("ALL CHECKS PASS")
