# Paley-Wiener-Schwartz -- the check behind the card.  Standard library only.
# Units: time t in ms, frequency in kHz, so xi*t is a pure number.
# Convention: f-hat(zeta) = integral of f(t) e^(-2 pi i zeta t) dt, with a complex
# frequency zeta = xi + i*eta.  Every transform is computed here.  Roads: closed
# forms against Simpson's rule at two step counts, the slope rule against the
# transform of the second slope, and narrow bumps that settle on the spike's slope.
import math, cmath
PI = math.pi

def simpson(f, a, b, n):              # n even; f may return complex numbers
    h = (b - a) / n
    s = f(a) + f(b)
    for k in range(1, n):
        s += (4 if k % 2 else 2) * f(a + k * h)
    return s * h / 3

def ft(f, z, a, b, n):                # transform of f (zero outside [a, b]) at complex z
    return simpson(lambda t: f(t) * cmath.exp(-2j * PI * z * t), a, b, n)

def bump(t, k):                       # smooth shutter exp(1 - 1/u), u = 1 - 4t^2: k-th slope
    u = 1 - 4 * t * t
    if u <= 1e-9: return 0.0
    p = math.exp(1 - 1 / u)
    if k == 0: return p
    if k == 1: return p * (-8 * t / u**2)
    return p * (64 * t * t / u**4 - 8 / u**2 - 128 * t * t / u**3)

g = lambda t: 1.0                     # the hard shutter, open from -0.5 to 0.5 ms
g_hat = lambda z: cmath.sin(PI * z) / (PI * z)
phi = lambda t: bump(t, 0)
def lnsinh(x): return x + math.log((1 - math.exp(-2 * x)) / 2)

# 1. both shutters obey the window bound |f-hat(zeta)| <= (area) e^(pi |eta|)
area = simpson(phi, -0.5, 0.5, 4000).real
print(f"smooth shutter area = {area:.6f} ms (hard shutter area = 1.000000 ms)")
for xi, eta in [(0.25, 0.0), (0.25, 1.0), (2.0, 2.0), (0.5, 5.0)]:
    z = complex(xi, eta)
    exact, simp = abs(g_hat(z)), abs(ft(g, z, -0.5, 0.5, 2000))
    sm = abs(ft(phi, z, -0.5, 0.5, 4000))
    sm2 = abs(ft(phi, z, -0.5, 0.5, 8000))
    bound = math.exp(PI * abs(eta))
    assert abs(exact - simp) < 1e-9 * max(1, exact) and abs(sm - sm2) < 1e-9 * max(1, sm)
    assert exact <= bound and sm <= area * bound
    print(f"zeta = {xi:.2f}+{eta:.2f}i  hard {exact:.6f} (Simpson {simp:.6f})  bound {bound:.6f}"
          f"  ratio {exact / bound:.6f}  smooth {sm:.6f}  ratio {sm / (area * bound):.6f}")
    if (xi, eta) == (0.25, 1.0):                      # the hand computation
        sh = math.sinh(PI)
        print(f"by hand: sinh(pi) = {sh:.6f}  |sin(pi zeta)| = {math.sqrt(0.5 + sh * sh):.6f}"
              f"  |pi zeta| = {abs(PI * z):.6f}")

# 2. read the window off the growth: b(eta) = ln|f-hat(i eta)| / (2 pi eta) -> 0.5 ms
etas = list(range(1, 11))
hard = [(lnsinh(PI * e) - math.log(PI * e)) / (2 * PI * e) for e in etas]
smooth = [math.log(abs(ft(phi, 1j * e, -0.5, 0.5, 4000))) / (2 * PI * e) for e in etas]
spike = [math.log(2 * PI * e) / (2 * PI * e) for e in etas]
assert abs(hard[0] - math.log(abs(ft(g, 1j, -0.5, 0.5, 2000))) / (2 * PI)) < 1e-9
assert abs(smooth[9] - math.log(abs(ft(phi, 10j, -0.5, 0.5, 8000))) / (20 * PI)) < 1e-9
print(f"by hand: ln sinh(10 pi) = {lnsinh(10 * PI):.6f}  ln(10 pi) = {math.log(10 * PI):.6f}")
print("chart eta (kHz):", " ".join(f"{e}" for e in etas))
for name, row in [("hard", hard), ("smooth", smooth), ("spike slope", spike)]:
    print(f"chart {name}:", " ".join(f"{v:.3f}" for v in row))
far = [(lnsinh(PI * e) - math.log(PI * e)) / (2 * PI * e) for e in (100, 1000, 10000)]
print("hard shutter b at eta = 100, 1000, 10000 kHz:", " ".join(f"{v:.6f}" for v in far))
assert hard[9] < far[0] < far[1] < far[2] < 0.5 and 0.5 - far[2] < 1e-3
print(f"type = 2 pi b = {2 * PI * 0.5:.6f} ms; window width = 2b = 1.000000 ms")
up, down = (math.log(abs(ft(g, s * 10j, 0, 1, 2000))) / (20 * PI) for s in (1, -1))
assert abs(up - hard[9] - 0.5) < 1e-9 and abs(down - hard[9] + 0.5) < 1e-9   # shift by 0.5 ms
print(f"shutter open 0 to 1 ms, b up and down at eta = 1000 kHz: {far[1] + 0.5:.6f} {far[1] - 0.5:.6f};"
      f" width {2 * far[1]:.6f} ms, type over pi {2 * far[1] + 1:.6f} ms")

# 3. the real line measures smoothness, not width: decay at half-integer kHz
ts = 48 ** -0.25                                  # phi'' = 0 only at +-ts, where 384 t^4 = 8
l1 = 4 * abs(bump(ts, 1))                         # so integral of |phi''| = 4 x steepest slope
l1s = 2 * simpson(lambda t: bump(t, 2), ts, 0.5, 4000) - simpson(lambda t: bump(t, 2), -ts, ts, 4000)
assert abs(bump(ts, 2)) < 1e-9 and abs(l1 - l1s) < 1e-9
print(f"integral of |second slope| = 4 x steepest slope = {l1:.9f}, at t = {ts:.6f} ms"
      f" (Simpson between the zeros {l1s:.9f})")
for xi in (1.5, 2.5, 4.5, 8.5, 16.5):
    h = abs(g_hat(xi))
    s = ft(phi, xi, -0.5, 0.5, 4000)
    s2 = ft(lambda t: bump(t, 2), xi, -0.5, 0.5, 4000)   # transform of the 2nd slope
    assert abs(s2 + (2 * PI * xi)**2 * s) < 1e-9          # slope rule: (2 pi i xi)^2
    assert abs(h - 1 / (PI * xi)) < 1e-12
    bnd = l1 / (2 * PI * xi)**2
    assert abs(s) <= bnd
    print(f"xi = {xi:4.1f} kHz  hard {h:.6f}  smooth {abs(s):.9f}  "
          f"bound {bnd:.9f}  ratio {abs(s) / bnd:.6f}")

# 4. L2 converse: g-hat^2 = sinc^2 has type 2 pi; its inverse is silent past 1 ms
K = 200.0
sinc2 = lambda x: 1.0 if x == 0 else (math.sin(PI * x) / (PI * x))**2
print(f"inverse of sinc^2, cut at {K:.0f} kHz, tail bound {2 / (PI**2 * K):.6f}:")
for t in (0.0, 0.5, 1.5):
    v = 2 * simpson(lambda x: sinc2(x) * math.cos(2 * PI * x * t), 0, K, 40000)
    tri = max(0.0, 1 - abs(t))
    assert abs(v - tri) < 2 / (PI**2 * K)
    print(f"  t = {t:.1f} ms  inverse {v:.6f}  triangle {tri:.6f}  gap {abs(v - tri):.6f}")

# 5. the spike's slope: narrow bumps rho_w (area 1, width w) whose slopes settle
for w in (1.0, 0.1, 0.01):
    d = lambda t: bump(t / w, 1) / (w * w * area)
    a = ft(d, 1.0, -w / 2, w / 2, 2000)
    b = ft(d, 1j, -w / 2, w / 2, 2000)
    print(f"w = {w:.3f} ms  at 1 kHz {a.imag:.6f}i  at 1i kHz {b.real:.6f}")
assert abs(a.imag - 2 * PI) < 1e-3 and abs(b.real + 2 * PI) < 1e-3
print(f"limit 2 pi i zeta: {2 * PI:.6f}i and {-2 * PI:.6f}")

# 6. what breaks
gb = [(-PI * (1j * e)**2).real / (2 * PI * e) for e in (1, 10, 100)]   # ln|e^(-pi zeta^2)| at i eta
tail, bq = math.exp(-64 * PI) / (8 * PI), []    # share of the bell's area more than 8 ms from its peak
for e in (1, 10):                               # the defining integral at zeta = i eta, cut at eta -+ 8
    v = simpson(lambda t: math.exp(-PI * t * t + 2 * PI * e * t), e - 8, e + 8, 2000)
    assert abs(v / math.exp(PI * e * e) - 1) < 1e-9
    bq.append(math.log(v) / (2 * PI * e))
print(f"bell by Simpson on [eta - 8, eta + 8] ms, tail share below {tail:.1e}:"
      f" b at eta = 1, 10: {bq[0]:.6f} {bq[1]:.6f}")
print("bell e^(-pi t^2): b at eta = 1, 10, 100:", " ".join(f"{v:.6f}" for v in gb))
ex, im = math.log(abs(cmath.exp(PI * 10))), abs(cmath.exp(PI * 1j * 10))
print(f"e^(pi zeta): ln size at 10 kHz {ex:.6f}; size at 10i kHz {im:.6f}, so b = 0")
print(f"half-width misread as width: {PI / (2 * PI):.6f} ms instead of 1.000000 ms")
print("ALL CHECKS PASS")
