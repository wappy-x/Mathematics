# Action-angle variables and KAM -- the check behind the card.  Imports only math's sin, cos, atan2, sqrt, pi.
# Oscillator H = p^2/2 + 2 q^2 (omega = 2) at E = 1; the 1 m pendulum; the standard map p' = p + K sin t, t' = t + p'.
from math import sin, cos, atan2, sqrt, pi
W, E, N = 2.0, 1.0, 2000; h, qm, pm = pi / N, sqrt(2 * E) / W, sqrt(2 * E)   # one period pi s in N RK4 steps
f = lambda q, p: (p, -W * W * q)                         # Hamilton's equations: q' = p, p' = -4 q
q, p, loop, gap = 0.0, pm, 0.0, 0.0                      # loop: sum of p dq = p q' dt = p^2 dt round the orbit
for i in range(1, N + 1):                                # RK4 round one orbit, tracking the loop and the angle
    a1, b1 = f(q, p); a2, b2 = f(q + h / 2 * a1, p + h / 2 * b1); a3, b3 = f(q + h / 2 * a2, p + h / 2 * b2)
    a4, b4 = f(q + h * a3, p + h * b3); q2 = q + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4)
    p2 = p + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4); loop += h * p2 * p2; q, p = q2, p2
    th = atan2(W * q, p) % (2 * pi); gap = max(gap, abs((th - W * i * h + pi) % (2 * pi) - pi))
    if i == N // 4: th_q = th
def simpson(g, n=200): return pi / 6 / n * sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(i * pi / 2 / n) for i in range(n + 1))
J, G = loop / (2 * pi), 9.81                             # the action; pendulum: H = p^2/2 + G (1 - cos t), per unit m l^2
def pend(deg, dk=1e-5):                                  # k = sin(amplitude / 2); returns J, dE/dJ, 2 pi / T, T
    k = sin(deg * pi / 360); T = 4 / sqrt(G) * simpson(lambda u: 1 / sqrt(1 - k * k * sin(u) * sin(u)))
    act = lambda k: 8 / pi * sqrt(G) * k * k * simpson(lambda u: cos(u) * cos(u) / sqrt(1 - k * k * sin(u) * sin(u)))
    return act(k), 2 * G * (4 * k * dk) / (act(k + dk) - act(k - dk)), 2 * pi / T, T
def run(K, x, y, n, a=1.0, b=0.0, c=0.0, d=1.0):         # n steps of the standard map with its tangent matrix
    for _ in range(n):
        kc = K * cos(x); y += K * sin(x); x += y; c, d = c + kc * a, d + kc * b; a, b = a + c, b + d
    return x, y, a, b, d
def residue(K, m, n, p):                                 # symmetric orbit through t = pi, by half-orbit shooting
    for _ in range(40):
        x, y, a, b, d = run(K, pi, p, (n + 1) // 2)
        r, s = (x - pi - pi * m, b) if n % 2 == 0 else (2 * x - y - 2 * pi * (1 + m), 2 * b - d)
        p -= max(-0.02, min(0.02, r / s))
    x, y, a, b, d = run(K, pi, p, n); return p, (2 - a - d) / 4, abs(x - pi - 2 * pi * m) + abs(y - p)
def critical(m, n, p=0.0, lo=0.95, hi=1.0):              # follow the orbit up to K = 0.95, then bisect on R = 1/4
    for i in range(96): p = residue(i / 100, m, n, p or 2 * pi * m / n)[0]
    for _ in range(40):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if 0 <= residue(mid, m, n, p)[1] < 0.25 else (lo, mid)
    return lo, p
def drift(K, t, p, steps=100000, lo=9.0, hi=-9.0):      # iterate; stop if |p| passes 2 pi (one whole turn per kick)
    for i in range(steps):
        p += K * sin(t); t = (t + p) % (2 * pi); lo, hi = min(lo, p), max(hi, p)
        if abs(p) > 2 * pi: return i + 1, lo, hi
    return steps, lo, hi
print(f"oscillator, mass 1 kg, stiffness {W * W:g} N/m, omega = 2, E = {E:g}: q_max = {qm:.4f}, p_max = {pm:.4f}, period {2 * pi / W:.4f} s")
print(f"area: ellipse pi q_max p_max = {pi * qm * pm:.6f}, RK4 loop sum of p dq = {loop:.6f}; J = {J:.6f}, omega J = {W * J:.6f}")
print(f"angle atan2(omega q, p): at a quarter period {th_q:.6f} rad, largest gap from 2 t over the orbit {gap:.1e} rad")
print(f"mistakes: no 2 pi, J = {loop:.4f}, omega J = {W * loop:.4f}; omega^2 = 2, E/omega = {E / sqrt(2):.4f}; half loop, J = {J / 2:.4f}")
pd = [pend(d) for d in (20, 60, 120)]
for d, (j, de, wt, T) in zip((20, 60, 120), pd):
    print(f"pendulum 1 m, {d} deg: J = {j:.4f}, omega = dE/dJ = {de:.4f}, 2 pi/T = {wt:.4f} rad/s, T = {T:.3f} s")
print(f"small swings: omega = sqrt(g/l) = {sqrt(G):.4f} rad/s, T = {2 * pi / sqrt(G):.3f} s")
fib, gold = [(5, 8), (8, 13), (13, 21), (21, 34), (34, 55), (55, 89)], (sqrt(5) - 1) / 2
print(f"golden mean {gold:.6f}: n^2 |gold - m/n| =", " ".join(f"{m}/{n} {n * n * abs(gold - m / n):.4f}" for m, n in fib[3:]), f"(1/sqrt5 = {1 / sqrt(5):.4f})")
crit = [critical(m, n) for m, n in fib]
print("K where the residue reaches 1/4:", " ".join(f"{m}/{n} {c[0]:.6f}" for (m, n), c in zip(fib, crit)))
for (m, n), (_, p0) in list(zip(fib, crit))[3:]:
    print(f"chart, residue {m}/{n} at K = 0.90..0.98:", " ".join(f"{residue(0.9 + i / 100, m, n, p0)[1]:.3f}" for i in range(9)))
for K, t0, p0 in ((0.5, 0.0, 1.0), (0.9, 0.001, 0.0), (1.0, 0.001, 0.0), (1.2, 0.001, 0.0)):
    s, lo, hi = drift(K, t0, p0); print(f"standard map K = {K}, start ({t0}, {p0}): {s} steps, p from {lo:.4f} to {hi:.4f}")
print("of 20 starts 1e-13 apart from (0.001, 0.0), passing |p| = 2 pi in 100000 kicks:", ", ".join(f"K = {K:.1f}: {sum(drift(K, 0.001 + i * 1e-13, 0.0)[0] < 100000 for i in range(20))}" for K in (1.0, 1.1, 1.2)))
assert abs(loop - pi * qm * pm) < 1e-9 and abs(J - E / W) < 1e-9 and gap < 1e-9   # loop area = 2 pi E / omega; angle turns at omega
assert all(abs(de / wt - 1) < 1e-6 for _, de, wt, _ in pd) and pd[0][1] > pd[1][1] > pd[2][1]   # dE/dJ = 2 pi/T
assert all(abs(c[0] - 0.9716) < 0.0015 for c in crit[2:]) and abs(crit[4][0] - crit[5][0]) < 1e-4   # orders agree
assert drift(0.9, 0.001, 0.0)[2] < pi < drift(1.2, 0.001, 0.0)[2]          # fenced in below K_c, escapes above
print("ALL CHECKS PASS")
