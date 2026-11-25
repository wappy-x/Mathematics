# Stationary phase: the check behind the card. Standard library only.
# Bessel functions are written out twice: as the power series and as the
# defining angle integral. Every other integral is Simpson's rule written out.
import math
PI = math.pi

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

def j_series(n, r):  # sum of (-1)^k (r/2)^(2k+n) / (k! (k+n)!), 80 terms
    s, term = 0.0, (r / 2) ** n / math.factorial(n)
    for k in range(1, 81):
        s += term
        term *= -(r / 2) ** 2 / (k * (k + n))
    return s

def j_angle(n, r):  # (1/2pi) * integral over a full turn of cos(n t - r sin t), trapezoid
    m = 2 * int(r) + 80  # periodic integrand: error far below 1e-12 once m > r + 60
    return sum(math.cos(n * 2 * PI * k / m - r * math.sin(2 * PI * k / m)) for k in range(m)) / m

def lead(n, r):  # stationary-phase leading term
    return math.sqrt(2 / (PI * r)) * math.cos(r - n * PI / 2 - PI / 4)

def f6(x): return f"{x:.6f}"

# ---- the example: J0(10) ----
r = 10.0
js, ja = j_series(0, r), j_angle(0, r)
jsimp = simpson(lambda t: math.cos(r * math.sin(t)), 0, PI, 20000) / PI
amp, u = math.sqrt(2 / (PI * r)), r - PI / 4
print(f"J0(10): series {f6(js)}, angle integral {f6(ja)}, Simpson on [0, pi] {f6(jsimp)}")
print(f"leading term: sqrt(2/(pi r)) {f6(amp)}, r - pi/4 {f6(u)}, cos {f6(math.cos(u))}, product {f6(lead(0, r))}")
print(f"to four places: leading {lead(0, r):.4f}, true {ja:.4f}")
print(f"dropped pi/4: {f6(amp * math.cos(r))}; wrong sign of the curvature, cos(r + pi/4): {f6(amp * math.cos(r + PI / 4))}")
assert abs(js - ja) < 1e-12 and abs(jsimp - ja) < 1e-10
# ---- the gap shrinks like r^(-3/2) ----
for r in [10.0, 100.0, 1000.0]:
    J = j_angle(0, r)
    gap = J - lead(0, r)
    nxt = math.sqrt(2 / (PI * r)) * math.sin(r - PI / 4) / (8 * r)
    print(f"r={r:g}: J0 {J:.9f}, leading {lead(0, r):.9f}, gap {gap:.3e}, next term sin(u)/(8r) {nxt:.3e}, r^1.5 |gap| {r ** 1.5 * abs(gap):.4f}")
    assert abs(gap) <= 1.01 * math.sqrt(2 / PI) / 8 * r ** -1.5 + 0.1 * r ** -2.5
    assert abs(gap - nxt) < 0.2 * r ** -2.5
print(f"ceiling on r^1.5 |gap| for large r: sqrt(2/pi)/8 = {math.sqrt(2 / PI) / 8:.4f}")
assert abs(j_angle(0, 1000.0) - simpson(lambda t: math.cos(1000 * math.sin(t)), 0, PI, 200000) / PI) < 1e-10
print(f"J1(10): series {f6(j_series(1, 10))}, angle integral {f6(j_angle(1, 10))}, leading {f6(lead(1, 10))}")
print(f"J1(1000): angle integral {f6(j_angle(1, 1000))}, leading {f6(lead(1, 1000))}")
assert abs(j_series(1, 10) - j_angle(1, 10)) < 1e-12

# ---- van der Corput ----
def osc(phi, a, b, lam, n):  # |integral of e^(i lam phi)| over [a, b]
    c = simpson(lambda x: math.cos(lam * phi(x)), a, b, n)
    s = simpson(lambda x: math.sin(lam * phi(x)), a, b, n)
    return math.hypot(c, s)
for lam in [10.0, 100.0, 1000.0]:
    i1 = osc(lambda x: x + x * x, 0, 1, lam, 40000)
    assert abs(i1 - osc(lambda x: x + x * x, 0, 1, lam, 20000)) < 1e-9 and i1 <= 3 / lam
    i2 = osc(lambda x: x * x / 2, -1, 1, lam, 40000)
    assert i2 <= 8 / math.sqrt(lam) and abs(i2 - math.sqrt(2 * PI / lam)) < 2.5 / lam
    print(f"lambda={lam:g}: first-derivative |I| {i1:.6f} <= 3/lambda {3 / lam:.6f} (ratio {i1 * lam / 3:.3f});"
          f" second-derivative |I| {i2:.6f} <= 8/sqrt(lambda) {8 / math.sqrt(lam):.6f}, Fresnel sqrt(2 pi/lambda) {math.sqrt(2 * PI / lam):.6f}")
for r in [10.0, 100.0]:
    bound = (8 * math.sqrt(2) / math.sqrt(r) + 4 * math.sqrt(3) / r) / PI
    print(f"uniform bound on |J0({r:g})|: {bound:.4f} against {abs(j_angle(0, r)):.4f}, ratio {bound / abs(j_angle(0, r)):.2f}")
    assert abs(j_angle(0, r)) <= bound
    mu2 = min(math.sin(PI / 6 + k * PI / 1500) for k in range(1001))  # road 2: least |phi''| on [pi/6, 5pi/6]
    mu1 = min(math.cos(k * PI / 6000) for k in range(1001))           # least |phi'| on [0, pi/6]
    assert abs((8 / math.sqrt(r * mu2) + 2 * 3 / (r * mu1)) / PI - bound) < 1e-9   # the lemma's 8 and 3, piece by piece

# ---- what breaks: a flat stationary point, phase x^3 ----
g43 = simpson(lambda v: math.exp(-v ** 3), 0, 6, 6000)  # Gamma(4/3)
limit = 2 * math.cos(PI / 6) * g43
print(f"cubic phase limit 2 cos(pi/6) Gamma(4/3) = {limit:.4f} (Gamma(4/3) {g43:.6f})")
for lam in [10.0, 100.0, 1000.0, 10000.0]:
    ic = 2 * simpson(lambda x: math.cos(lam * x ** 3), 0, 1, 400000)
    print(f"lambda={lam:g}: integral of cos(lambda x^3) on [-1, 1] {ic:.6f}, times lambda^(1/3) {ic * lam ** (1 / 3):.4f}, times lambda^(1/2) {ic * lam ** 0.5:.4f}")
assert abs(ic * lam ** (1 / 3) - limit) < 0.01 and abs(g43 - 0.8929795116) < 1e-8
# ---- what breaks: the ends of the interval (imaginary part of the J0 integral) ----
for r in [10.0, 100.0, 1000.0]:
    im = simpson(lambda t: math.sin(r * math.sin(t)), 0, PI, 200000) / PI
    sp = math.sqrt(2 / (PI * r)) * math.sin(r - PI / 4)
    print(f"r={r:g}: imaginary part {im:.6f}, stationary point alone {sp:.6f}, gap {im - sp:.6f}, r x gap {r * (im - sp):.4f}")
print(f"end-point prediction for r x gap: 2/pi = {2 / PI:.4f}")
assert abs(r * (im - sp) - 2 / PI) < 0.01

# ---- zeros of J0 and the drum's round notes ----
note = 100 / (2 * PI * 0.15)  # wave speed 100 m/s, radius 0.15 m: hertz per unit of j
print(f"drum: hertz per unit of j = {note:.6f}")
for k in [1, 2, 3, 10]:
    beta = (k - 0.25) * PI
    lo, hi = beta - 0.3, beta + 0.3
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if j_angle(0, lo) * j_angle(0, mid) > 0 else (lo, mid)
    jz, mc = (lo + hi) / 2, beta + 1 / (8 * beta)
    print(f"zero {k}: true {jz:.6f}, (k - 1/4) pi {beta:.6f}, with 1/(8 beta) {mc:.6f}; note {note * jz:.1f} Hz, predicted {note * beta:.1f} Hz, {note * mc:.1f} Hz")
    assert abs(mc - jz) < 0.005 / k ** 2
    if k == 1: assert abs(jz - 2.404825557695773) < 1e-9
    if k == 1: assert abs(note * jz - 255.2) < 0.05     # the fundamental on Drumheads: 255.2 Hz

# ---- the sphere and the circle ----
for rho in [10.25, 100.25]:
    q = 2 * PI * simpson(lambda t: math.cos(2 * PI * rho * math.cos(t)) * math.sin(t), 0, PI, 40000)
    cf = 2 * math.sin(2 * PI * rho) / rho
    print(f"sphere rho={rho:g}: quadrature {q:.6f}, two poles 2 sin(2 pi rho)/rho {cf:.6f}, rho x value {rho * q:.4f}")
    assert abs(q - cf) < 1e-9
rho = 10.3
circ = 2 * PI * j_angle(0, 2 * PI * rho)
cl = 2 / math.sqrt(rho) * math.cos(2 * PI * rho - PI / 4)
print(f"circle rho=10.3: 2 pi J0(2 pi rho) {circ:.6f}, two points (2/sqrt(rho)) cos(2 pi rho - pi/4) {cl:.6f}, envelope 2/sqrt(rho) {2 / math.sqrt(rho):.6f}")
assert abs(circ - cl) < 0.01

# ---- chart points ----
print("chart r: " + ", ".join(str(r) for r in range(1, 21)))
print("chart J0: " + ", ".join(f"{j_angle(0, r):.3f}" for r in range(1, 21)))
print("chart leading: " + ", ".join(f"{lead(0, r):.3f}" for r in range(1, 21)))
print("ALL CHECKS PASS")
