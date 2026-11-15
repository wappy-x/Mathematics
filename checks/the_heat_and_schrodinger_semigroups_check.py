# Two evolutions -- the check behind the card.  Standard library only.
# A 1 m bar, ends held at 0; A = -d^2/dx^2, modes e_n = sqrt2 sin(n pi x), eigenvalues lam_n = n^2 pi^2.
# Heat multiplies mode n by e^(-lam_n z), z = kappa t / L^2, L = 1 m.  The wave multiplies it by e^(-i lam_n s).
# Start: the struck bar, 100 C on 0.4 < x < 0.6 m and 0 C elsewhere; the pulse has the same shape.
import math
PI, S2, NM, Z = math.pi, math.sqrt(2.0), 2000, 0.006     # modes kept; z = s = 0.006 (60 s at kappa = 1e-4)
lam = [(n * PI) ** 2 for n in range(NM + 1)]
def coef(n):                               # <e_n, f> for the struck bar, closed form
    return 100 * S2 / (n * PI) * (math.cos(0.4 * n * PI) - math.cos(0.6 * n * PI))
c = [0.0] + [coef(n) for n in range(1, NM + 1)]
def heat(z):  return [c[n] * math.exp(-lam[n] * z) for n in range(NM + 1)]
def wave(s):  return [c[n] * complex(math.cos(lam[n] * s), -math.sin(lam[n] * s)) for n in range(NM + 1)]
def size(a, N=NM):  return math.sqrt(sum(abs(a[n]) ** 2 for n in range(1, N + 1)))
def bend(a, N=NM):  return math.sqrt(sum(lam[n] ** 2 * abs(a[n]) ** 2 for n in range(1, N + 1)))
def simpson(f, a, b, m=2000):
    h = (b - a) / m
    return (f(a) + f(b) + sum((4 if j % 2 else 2) * f(a + j * h) for j in range(1, m))) * h / 3
def gram(m, n):                            # int_0.4^0.6 e_m e_n dx, closed form
    F = lambda k, x: math.sin(k * PI * x) / (k * PI) if k else x
    return sum(sg * (F(k, 0.6) - F(k, 0.4)) for sg, k in ((1, abs(m - n)), (-1, m + n)))
def band(a, M=199):                        # share of |psi|^2 on 0.4 < x < 0.6, modes 1..M
    odd = range(1, M + 1, 2)
    num = sum((a[m].conjugate() * a[n]).real * gram(m, n) for m in odd for n in odd)
    return num / sum(abs(a[n]) ** 2 for n in odd)
print("struck bar: 100 C on 0.4 < x < 0.6 of a 1 m bar, ends held at 0 C; modes sqrt2 sin(n pi x)")
for n in (1, 3, 5):
    sim = simpson(lambda x: 100 * S2 * math.sin(n * PI * x), 0.4, 0.6)
    print(f"c_{n} = {c[n]:.6f} closed form, {sim:.6f} Simpson")
    assert abs(sim - c[n]) < 1e-9
print("Parseval: sum c_n^2 to N = 10, 100, 2000: " + ", ".join(f"{size(c, N)**2:.4f}" for N in (10, 100, 2000))
      + f"; exact 2000, size sqrt(2000) = {math.sqrt(2000):.6f}")
assert 0 < 2000 - size(c) ** 2 < 4000 / NM
def cn(N, q, s, steps=600):                # Crank-Nicolson: (I + q ds/2 A_N) u_new = (I - q ds/2 A_N) u
    h = 1.0 / (N + 1); xs = [(j + 1) * h for j in range(N)]
    u = [complex(100.0 if 0.4 + 1e-9 < x < 0.6 - 1e-9 else 50.0 if abs(abs(x - 0.5) - 0.1) < 1e-9 else 0.0) for x in xs]
    r, n0 = q * s / steps / (2 * h * h), math.sqrt(h * sum(abs(v) ** 2 for v in u))
    cp = [-r / (1 + 2 * r)]
    for j in range(1, N): cp.append(-r / (1 + 2 * r + r * cp[-1]))
    for _ in range(steps):
        d = [(1 - 2 * r) * u[j] + r * ((u[j - 1] if j else 0) + (u[j + 1] if j < N - 1 else 0)) for j in range(N)]
        dp = [d[0] / (1 + 2 * r)]
        for j in range(1, N): dp.append((d[j] + r * dp[-1]) / (1 + 2 * r + r * cp[j - 1]))
        u[N - 1] = dp[N - 1]
        for j in range(N - 2, -1, -1): u[j] = dp[j] - cp[j] * u[j + 1]
    w = [0.5 if abs(abs(x - 0.5) - 0.1) < 1e-9 else 1.0 if abs(x - 0.5) < 0.1 else 0.0 for x in xs]
    sz = math.sqrt(h * sum(abs(v) ** 2 for v in u))
    bd = math.sqrt(h * sum(abs(((u[j-1] if j else 0) - 2*u[j] + (u[j+1] if j < N-1 else 0)) / h**2) ** 2 for j in range(N)))
    return n0, sz, u[(N - 1) // 2].real, h * sum(wj * abs(v) ** 2 for wj, v in zip(w, u)) / sz ** 2, bd
print(f"finite rehearsal: Crank-Nicolson on N grid points, 600 steps to z = s = {Z}")
print("N      start size  heat: size  middle C   bend         wave: size  band share  bend")
grid = {}
for N in (99, 399, 1599):
    a0, ha, hm, _, hb = cn(N, 1.0, Z); b0, wa, _, wsh, wb = cn(N, 1j, Z)
    grid[N] = (hm, wsh, hb, wb)
    print(f"{N:<6} {a0:.6f}   {ha:.6f}   {hm:.4f}    {hb:.4e}   {wa:.6f}   {wsh:.4f}      {wb:.4e}")
    assert abs(wa - b0) < 1e-9 * b0 and ha < 0.95 * a0           # the wave keeps size exactly, heat loses it
H, W = heat(Z), wave(Z)
hmid = sum(H[n] * S2 * math.sin(n * PI * 0.5) for n in range(1, NM + 1))
hshare = lambda z: sum(c[n] ** 2 * math.exp(-lam[n] * z) for n in range(1, NM + 1)) / 2000
print(f"modes ({NM}): heat size {size(H):.6f}, middle {hmid:.4f} C, band share of heat {hshare(Z):.4f}, bend {bend(H):.4e}")
print(f"modes ({NM}): wave size {size(W):.6f}, band share (199 modes) {band(W):.4f}")
mt = [H[n] * S2 * math.sin(n * PI * 0.5) for n in (1, 3, 5, 7, 9)]
print("by hand, n = 1, 3, 5, 7, 9: e^(-lam_n z) = " + ", ".join(f"{math.exp(-lam[n] * Z):.6f}" for n in (1, 3, 5, 7, 9))
      + "; middle terms " + ", ".join(f"{v:.4f}" for v in mt) + f" C; sum {sum(mt):.4f} C")
assert abs(hmid - grid[1599][0]) < 0.01 and abs(band(W) - grid[1599][1]) < 0.01 and abs(size(W) - size(c)) < 1e-9
print("bend ||A u|| cut at N = 10, 100, 1000:")
print("  start ", ", ".join(f"{bend(c, N):.4e}" for N in (10, 100, 1000)))
print("  heat  ", ", ".join(f"{bend(H, N):.4e}" for N in (10, 100, 1000)))
print("  wave  ", ", ".join(f"{bend(W, N):.4e}" for N in (10, 100, 1000)))
assert bend(H, 1000) - bend(H, 100) < 1e-6 and bend(W, 1000) > 9 * bend(W, 100)
print("mode sizes |c_n| at z = s = 0.006:  n, start, heat, wave")
for n in (1, 3, 5, 7, 9, 11, 13, 15):
    print(f"  {n:<3} {abs(c[n]):.4f}  {abs(H[n]):.4f}  {abs(W[n]):.4f}")
best = max(lam[n] * math.exp(-lam[n] * Z) for n in range(1, NM + 1))
print(f"smoothing: max_n lam_n e^(-lam_n z) = {best:.4f} <= 1/(e z) = {1/(math.e*Z):.4f}; "
      f"||A T f|| = {bend(H):.4f} <= ||f||/(e z) = {math.sqrt(2000)/(math.e*Z):.4f}")
assert 1 / (math.e * Z) - best < 0.1 and bend(H) <= math.sqrt(2000) / (math.e * Z)   # mode 4 nearly attains 1/(e z)
print(f"contraction: ||T(z)|| = e^(-pi^2 z) = {math.exp(-PI**2*Z):.6f}; ||U(s)|| = 1 for every s, forward or back")
g = [0.0] + [1600 * S2 / (n * PI) ** 3 * (n % 2) for n in range(1, NM + 1)]   # g = 400 x(1 - x), A g = 800
print(f"Stone: g = 400x(1-x) is in D(A), ||A g|| by modes {bend(g):.4f} (exact 800)")
assert 0 < 800 - bend(g) < 0.1
eg0 = ef0 = None
for s in (1e-2, 1e-3, 1e-4):
    eg = math.sqrt(sum(abs(complex(math.cos(lam[n]*s) - 1, -math.sin(lam[n]*s)) / s + 1j * lam[n]) ** 2 * g[n] ** 2 for n in range(1, NM + 1)))
    ef = math.sqrt(sum(abs(complex(math.cos((n*PI)**2*s) - 1, -math.sin((n*PI)**2*s))) ** 2 / s ** 2 * coef(n) ** 2 for n in range(1, 20001)))
    print(f"  s = {s:.0e}: ||(U(s)g - g)/s + iAg|| = {eg:.4f};  struck bar ||(U(s)f - f)/s|| = {ef:.4e}")
    assert eg0 is None or (eg < 0.7 * eg0 and ef > 3 * ef0)
    eg0, ef0 = eg, ef
rev = max(abs(complex(math.cos(lam[n] * 2 / PI) - 1, math.sin(lam[n] * 2 / PI))) for n in range(1, NM + 1))
print(f"revival, any start: at s = 2/pi = {2/PI:.6f} every phase is back to 1 (max error below 1e-6)")
R = 1 / (4 * PI)                           # odd n only: n^2 - 1 is a multiple of 8
W2 = wave(R / 2)
p25, p75 = (abs(sum(W2[n] * S2 * math.sin(n * PI * x) for n in range(1, NM + 1))) for x in (0.25, 0.75))
print(f"revival, struck pulse: at s = 1/(4 pi) = {R:.6f} band share {band(wave(R)):.6f} = start {band(c):.6f}")
print(f"  halfway, s = {R/2:.6f}: band share {band(W2):.4f}; |psi| at 0.25 and 0.75 m = {p25:.2f}, {p75:.2f}; 100/sqrt2 = {100/S2:.2f}")
print(f"heat at z = 1/(4 pi): band share {hshare(R):.4f}; mode 1 keeps e^(-pi/4) = {math.exp(-PI/4):.6f}")
assert rev < 1e-6 and abs(band(wave(R)) - band(c)) < 1e-9 and band(W2) < 1e-3 and abs(p25 - 100 / S2) < 0.1 and abs(p75 - 100 / S2) < 0.1
hb, m = 6.62607015e-34 / (2 * PI), 9.1093837139e-31
print(f"electron: hbar/2m = {hb/(2*m):.6e} m^2/s; 1 nm box: one unit of s = {1e-18/(hb/(2*m))*1e15:.4f} fs, "
      f"so s = 0.006 is {0.006e-3/(hb/(2*m)):.4f} fs and 1/(4 pi) is {R*1e-3/(hb/(2*m)):.4f} fs")
print(f"mistake: wave without the i: size {size(H):.6f} after s = 0.006, not {size(W):.6f}")
print(f"mistake: heat run back 60 s: mode 21 multiplied by {math.exp(lam[21]*Z):.4e}")
print("chart, z or s = 0, 0.005, ..., 0.08: heat share in 0.4..0.6; wave band share")
zs = [0.005 * k for k in range(17)]
print("  heat:", ", ".join(f"{hshare(z):.2f}" for z in zs))
print("  wave:", ", ".join(f"{band(wave(z)):.2f}" for z in zs))
print("ALL CHECKS PASS")
