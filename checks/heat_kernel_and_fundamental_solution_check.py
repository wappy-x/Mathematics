# The heat kernel in d dimensions: a hot spot in a 1 m copper rod, 10 s later.
# Standard library only. erf, Simpson's rule and the grid are written out here.
from math import sqrt, exp, log, pi

KAPPA, T, A, U0 = 1.11e-4, 10.0, 0.005, 100.0   # copper m^2/s; s; slice half-width m; K

def erf(z):                     # 2/sqrt(pi) e^(-z^2) sum 2^n z^(2n+1)/(1*3*...*(2n+1)): all terms positive
    if z < 0: return -erf(-z)
    s = term = z
    for n in range(1, 400):
        term *= 2 * z * z / (2 * n + 1); s += term
        if term < 1e-17 * s: break
    return 2 / sqrt(pi) * exp(-z * z) * s

def G(r2, t, d, k=KAPPA):       # the kernel at squared distance r2, in d dimensions
    return exp(-r2 / (4 * k * t)) / (4 * pi * k * t) ** (d / 2)

def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def box(x, t):                  # the 1 cm slice at 100 K, spread by t seconds: closed form
    w = 2 * sqrt(KAPPA * t)
    return U0 / 2 * (erf((x + A) / w) - erf((x - A) / w))

def grid(m):                    # explicit grid on the whole 1 m rod, ends held at 0 K above the room
    N, n = 400 * m, 445 * m * m; h, dt = 1.0 / N, T / n
    r = KAPPA * dt / h ** 2; assert r <= 0.5
    u = [U0 if abs(-0.5 + i * h) < A - 1e-12 else 0.0 for i in range(N + 1)]
    for i in (N // 2 - 2 * m, N // 2 + 2 * m): u[i] = U0 / 2      # slice edges fall on nodes
    for _ in range(n):
        u = [0.0] + [u[i] + r * (u[i - 1] - 2 * u[i] + u[i + 1]) for i in range(1, N)] + [0.0]
    return u[N // 2], h, r

sig = sqrt(2 * KAPPA * T)
print(f"hand: heat in the slice {U0:.0f} K x {200*A:.0f} cm = {U0*2*A:.2f} K m; 4 kappa t = {4*KAPPA*T:.3e} m^2;"
      f" sqrt(4 pi kappa t) = {sqrt(4*pi*KAPPA*T):.5f} m; 1/that = {1/sqrt(4*pi*KAPPA*T):.4f} per m")
print(f"rod: kappa {KAPPA:.3e} m^2/s, t = {T:.0f} s, width sqrt(2 kappa t) = {100*sig:.2f} cm")
OMEGA = {1: 2.0, 2: 2 * pi, 3: 4 * pi}         # size of the unit sphere's surface in d dimensions
close = {1: erf(sqrt(0.5)), 2: 1 - exp(-0.5), 3: erf(sqrt(0.5)) - sqrt(2 / pi) * exp(-0.5)}
for d in (1, 2, 3):
    mass = simpson(lambda r: OMEGA[d] * r ** (d - 1) * G(r * r, T, d), 0, 0.5, 2000)
    msq = simpson(lambda r: OMEGA[d] * r ** (d + 1) * G(r * r, T, d), 0, 0.5, 2000)
    near = simpson(lambda r: OMEGA[d] * r ** (d - 1) * G(r * r, T, d), 0, sig, 2000)
    print(f"d = {d}: peak {G(0, T, d):.4e} per m^{d}; total {mass:.9f}; rms distance {100*sqrt(msq):.2f} cm"
          f" (sqrt(2 d kappa t) {100*sqrt(2*d*KAPPA*T):.2f}); share within {100*sig:.2f} cm {near:.4f} (closed form {close[d]:.4f})")
    assert abs(mass - 1) < 1e-9
    assert abs(msq - 2 * d * KAPPA * T) < 1e-12
    assert abs(near - close[d]) < 1e-9

p, res = (0.02, 0.01, 0.01), []                  # the 3-d kernel put back into u_t = kappa Lap u
g3 = lambda q, t: G(sum(c * c for c in q), t, 3)
for h in (0.002, 0.001):
    ut = (g3(p, T + h * 50) - g3(p, T - h * 50)) / (h * 100)
    lap = sum((g3([c + h * (j == i) for j, c in enumerate(p)], T) - 2 * g3(p, T)
               + g3([c - h * (j == i) for j, c in enumerate(p)], T)) / h ** 2 for i in range(3))
    res.append(ut - KAPPA * lap)
print(f"d = 3 at (2, 1, 1) cm: u_t = {ut:.4f}, kappa Lap u = {KAPPA*lap:.4f} per m^3 per s;"
      f" residual {res[0]:.3e} then {res[1]:.3e}, ratio {res[0]/res[1]:.2f}")
assert abs(res[0] / res[1] - 4) < 0.1
assert abs(ut - KAPPA * lap) < 1e-3 * abs(ut)

exact = box(0, T)
conv = simpson(lambda y: U0 * G(y * y, T, 1), -A, A, 200)
point = U0 * 2 * A * G(0, T, 1)
print(f"rod centre at 10 s: erf form {exact:.4f} K, kernel convolution {conv:.4f} K, point mass {point:.4f} K"
      f" ({100*(point/exact-1):.2f}% high)")
assert abs(conv - exact) < 1e-9
assert abs(point / exact - 1) < 0.002
errs = []
for m in (1, 2, 4):
    c, h, r = grid(m); errs.append(abs(c - exact))
    print(f"grid h = {1000*h:.3f} mm, r = {r:.4f}: centre {c:.6f} K, error {errs[-1]:.2e} K")
print(f"observed order {log(errs[0]/errs[1], 2):.2f}, {log(errs[1]/errs[2], 2):.2f}")
assert 1.8 < log(errs[1] / errs[2], 2) < 2.2
print(f"first image term from the held ends, at the centre: {2*U0*2*A*G(1.0, T, 1):.1e} K")

b = 0.1                          # the kernel tends to a point mass: test bump e^(-x^2/(2b^2)), b = 10 cm
for t in (10.0, 1.0, 0.1):
    v = simpson(lambda x: G(x * x, t, 1) * exp(-x * x / (2 * b * b)), -1, 1, 4000)
    print(f"t = {t:4.1f} s: integral of G times bump {v:.6f}; exact b/sqrt(b^2+2 kappa t)"
          f" {b/sqrt(b*b+2*KAPPA*t):.6f}; 1 - kappa t/b^2 {1-KAPPA*t/b**2:.6f}")
    assert abs(v - b / sqrt(b * b + 2 * KAPPA * t)) < 1e-9

for t in (2.5, 10.0, 40.0):
    print(f"figure, t = {t:4.1f} s, x = -12..12 cm step 2: " + ", ".join(f"{box(x/100, t):.2f}" for x in range(-12, 13, 2)))
print(f"peaks at 2.5, 10, 40 s: {box(0, 2.5):.2f} {box(0, 10):.2f} {box(0, 40):.2f} K")

def tych(x, t0, K=80):           # Tychonoff, scaled kappa = 1: sum g^(k)(t) x^(2k)/(2k)!, g = e^(-1/t^2)
    a = [-((-1) ** j) * (j + 1) / t0 ** 2 for j in range(K + 2)]
    bk = [exp(a[0])]
    for k in range(1, K + 2): bk.append(sum(j * a[j] * bk[k - j] for j in range(1, k + 1)) / k)
    s, c = 0.0, 1.0
    for k in range(K + 1):
        s += c * bk[k]; c *= (k + 1) / ((2 * k + 1) * (2 * k + 2)) * x * x / t0
    return s, abs(c * bk[K + 1])     # the sum to term K, and the first omitted term, K + 1
print(f"Tychonoff, scaled: x in m, time unit (1 m)^2/kappa = {1/KAPPA:.0f} s, so kappa = 1")
for t in (0.4, 0.2, 0.1):
    print(f"Tychonoff, scaled, t = {t}: u(0) = {tych(0, t)[0]:.3e}, u(1) = {tych(1, t)[0]:.3e}, u(2) = {tych(2, t)[0]:.3e}")
print(f"Tychonoff, largest first omitted term (term 81) over these: {max(tych(x, t)[1] for x in (1, 2) for t in (0.4, 0.2, 0.1)):.1e}")
tr = []
for h in (0.01, 0.005):
    ut = (tych(1, 0.4 + h)[0] - tych(1, 0.4 - h)[0]) / (2 * h)
    uxx = (tych(1 + h, 0.4)[0] - 2 * tych(1, 0.4)[0] + tych(1 - h, 0.4)[0]) / h ** 2
    tr.append(ut - uxx)
print(f"Tychonoff at x = 1, t = 0.4: u_t = {ut:.4f}, u_xx = {uxx:.4f}; residual {tr[0]:.2e} then {tr[1]:.2e}")
assert abs(tr[0] / tr[1] - 4) < 0.2
assert tych(1, 0.1)[0] < 1e-25 < tych(1, 0.4)[0]

B = lambda x, t: exp(x * x / (4 * (1 - t))) / sqrt(1 - t)     # the proof's barrier, scaled, S = 1
br = (B(0.5, 0.51) - B(0.5, 0.49)) / 0.02 - (B(0.51, 0.5) - 2 * B(0.5, 0.5) + B(0.49, 0.5)) / 1e-4
print(f"barrier at x = 0.5, t = 0.5, scaled: u_t - u_xx = {br:.2e} (step 0.01)")
assert abs(br) < 1e-3

print(f"mistake 1, width sqrt(kappa t): {100*sqrt(KAPPA*T):.2f} cm, not {100*sig:.2f}")
print(f"mistake 2, 3-d spread taken as the 1-d width: {100*sig:.2f} cm, rms is {100*sqrt(6*KAPPA*T):.2f}")
print(f"mistake 3, 1-d prefactor in 3-d: total {4*pi*KAPPA*T:.5f} m^2, not 1")
print("peak falls from 10 s to 40 s, d = 1, 2, 3: " + " ".join(f"{G(0, 10, d)/G(0, 40, d):.1f}" for d in (1, 2, 3)))
print(f"mistake 4, 3-d peak from 10 s to 40 s: falls by {G(0,10,3)/G(0,40,3):.1f}, not {G(0,10,1)/G(0,40,1):.1f}")
print(f"finance: volatility 0.20, kappa = volatility^2/2 = {0.2**2/2:.2f} per year; width after 1 year {sqrt(2*0.02*1):.4f} in log price")
print("ALL CHECKS PASS")
