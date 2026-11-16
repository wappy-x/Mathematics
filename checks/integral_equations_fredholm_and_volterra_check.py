# Integral equations -- the check behind the card.  Standard library only.
# A 1 m strip of tarp roof hangs like a cable between two beams; rain ponds
# in its sag.  Roads to the sag: (1) closed form, (2) the Fredholm series,
# (3) Volterra marching from one end, plus the residual of -u'' = lam (h0 + u).
import math

RHO, GRAV, TENS, H0 = 1000.0, 9.81, 1962.0, 0.01  # kg/m^3, m/s^2, N/m, m
LAM = RHO * GRAV / TENS                            # lambda, 1/m^2

# polynomials in x: coefficient lists, lowest power first
def padd(p, q):
    n = max(len(p), len(q))
    return [(p[k] if k < len(p) else 0.0) + (q[k] if k < len(q) else 0.0) for k in range(n)]
def pscale(p, c): return [c * a for a in p]
def pmulx(p): return [0.0] + p
def pint(p): return [0.0] + [a / (k + 1) for k, a in enumerate(p)]  # integral from 0 to x
def peval(p, x):
    s = 0.0
    for a in reversed(p): s = s * x + a
    return s

def green(p):  # (G p)(x) = (1 - x) int_0^x y p(y) dy + x int_x^1 (1 - y) p(y) dy
    a = pint(pmulx(p))
    b = pint(padd(p, pscale(pmulx(p), -1.0)))
    return padd(padd(a, pscale(pmulx(a), -1.0)), padd([0.0, peval(b, 1.0)], pscale(pmulx(b), -1.0)))

def exact(x, lam):  # closed form: -u'' = lam (H0 + u), u(0) = u(1) = 0
    r = math.sqrt(lam)
    return H0 * (math.cos(r * (x - 0.5)) / math.cos(r / 2) - 1.0)

def neumann(lam, n):  # Fredholm: u = f + lam G f + lam^2 G^2 f + ..., n terms
    term = pscale(green([1.0]), lam * H0)
    u, mids = term, [peval(term, 0.5)]
    for _ in range(n - 1):
        term = pscale(green(term), lam)
        u = padd(u, term)
        mids.append(peval(term, 0.5))
    return u, mids

def volterra(s0, h, lam, passes):  # Picard on u = s0 x - lam int_0^x (x - y)(h + u(y)) dy
    u, gaps = [0.0, s0], []
    for _ in range(passes):
        new = padd([0.0, s0], pscale(pint(pint(padd([h], u))), -lam))
        gaps.append(abs(peval(new, 1.0) - peval(u, 1.0)))
        u = new
    return u, gaps

def shoot(lam, passes):  # choose the start slope so the far end lands on 0
    a = volterra(1.0, 0.0, lam, passes)[0]
    b = volterra(0.0, H0, lam, passes)[0]
    s0 = -peval(b, 1.0) / peval(a, 1.0)
    return padd(pscale(a, s0), b), s0

def g_sin(n, x, panels=2000):  # Simpson's rule for int_0^1 G(x, y) sin(n pi y) dy
    def simpson(f, lo, hi):
        w = (hi - lo) / panels
        s = f(lo) + f(hi) + sum((4 if k % 2 else 2) * f(lo + k * w) for k in range(1, panels))
        return s * w / 3
    left = simpson(lambda y: y * (1 - x) * math.sin(n * math.pi * y), 0.0, x)
    return left + simpson(lambda y: x * (1 - y) * math.sin(n * math.pi * y), x, 1.0)

mm = lambda v: 1000.0 * v
r = math.sqrt(LAM)
print(f"lambda = rho g / T = {LAM:.4f} 1/m^2; sqrt(lambda)/2 = {r / 2:.6f}; cos of it = {math.cos(r / 2):.6f}")
print(f"pi^2 = {math.pi ** 2:.4f} 1/m^2; critical tension rho g / pi^2 = {RHO * GRAV / math.pi ** 2:.2f} N/m")
rain, ex = LAM * H0 * 0.5 * 0.5 / 2, exact(0.5, LAM)
print(f"rain alone, no ponding (Green's formula): midpoint sag {mm(rain):.4f} mm")
print(f"road 1, closed form: midpoint sag {mm(ex):.4f} mm, {ex / rain:.4f} times the rain-alone sag")

u_n, mids = neumann(LAM, 30)
print("road 2, Fredholm series, midpoint terms: " + ", ".join(f"{mm(t):.4f}" for t in mids[:5]) + " mm")
for n in (1, 2, 4, 8, 16, 30):
    print(f"  sum of {n:2d} terms: {mm(sum(mids[:n])):.6f} mm")
rate8 = LAM / 8
true_tail, bound_tail = sum(mids[16:]), mids[15] * rate8 / (1 - rate8)
print(f"  tail after 16 terms: true {mm(true_tail) * 1e3:.4f} um, bound with lambda/8 = {rate8:.3f}: {mm(bound_tail) * 1e3:.4f} um")
ratio = mids[29] / mids[28]
print(f"  term ratio {ratio:.6f}; lambda/pi^2 = {LAM / math.pi ** 2:.6f}")

u_v, s0 = shoot(LAM, 14)
slope_cf = H0 * r * math.tan(r / 2)
print(f"road 3, Volterra shooting: start slope {s0:.6f}; closed form {slope_cf:.6f}; Fredholm {u_n[1]:.6f}")
print(f"  midpoint sag {mm(peval(u_v, 0.5)):.6f} mm")
gaps = volterra(s0, H0, LAM, 9)[1]
m0 = LAM * (H0 / 2 + s0 / 6)  # largest first gap on [0, 1]
for n in (2, 4, 6):
    bound = 2 * m0 * LAM ** n / math.factorial(2 * n + 2)
    print(f"  Picard pass {n}: gap at far end {mm(gaps[n]) * 1e3:.4f} um, factorial bound {mm(bound) * 1e3:.4f} um")

res = []
for h in (0.01, 0.005):
    x = 0.3
    d2 = (peval(u_n, x + h) - 2 * peval(u_n, x) + peval(u_n, x - h)) / h ** 2
    res.append(-d2 - LAM * (H0 + peval(u_n, x)))
    print(f"residual of -u'' - lambda (h0 + u) at x = 0.3 m, step {h} m: {res[-1] * 1e6:.4f}e-6 1/m")

print("what breaks:")
far = peval(volterra(LAM * H0 / 2, H0, LAM, 14)[0], 1.0)
print(f"  Volterra started at the rain-alone slope {LAM * H0 / 2:.4f}: far end at {mm(far):.4f} mm, not 0")
lam_hi = 12.0
_, mids_hi = neumann(lam_hi, 30)
print(f"  tension {RHO * GRAV / lam_hi:.1f} N/m (lambda 12): Fredholm terms {mm(mids_hi[0]):.4f} mm, then {mm(mids_hi[29]):.1f} mm at term 30")
u_hi, _ = shoot(lam_hi, 20)
print(f"  same tension, Volterra shooting: midpoint {mm(peval(u_hi, 0.5)):.4f} mm; closed form {mm(exact(0.5, lam_hi)):.4f} mm")
shrink = [g_sin(n, 0.5) / math.sin(n * math.pi / 2) for n in (1, 49)]
print(f"  G shrinks mode 1 by {shrink[0]:.6f} (1/pi^2 = {1 / math.pi ** 2:.6f}), mode 49 by {shrink[1] * 1e5:.4f}e-5 (1/(49 pi)^2 = {1e5 / (49 * math.pi) ** 2:.4f}e-5)")
fake = TENS * 1e-6 / shrink[1]
print(f"  first kind: 1 um of sag noise in mode 49 reads as {fake:.2f} Pa of load; the rain is {RHO * GRAV * H0:.2f} Pa")

xs = [k / 10 for k in range(11)]
print("chart rain alone (mm): " + ", ".join(f"{mm(LAM * H0 * x * (1 - x) / 2):.2f}" for x in xs))
print("chart ponded (mm):     " + ", ".join(f"{mm(exact(x, LAM)):.2f}" for x in xs))
worst = max(max(abs(peval(u_n, x) - exact(x, LAM)), abs(peval(u_v, x) - exact(x, LAM))) for x in xs)

assert abs(peval(u_n, 0.5) - ex) < 1e-9            # Fredholm series meets the closed form
assert abs(peval(u_v, 0.5) - ex) < 1e-9            # Volterra shooting meets the closed form
assert worst < 1e-9                                 # ... at every chart point
assert abs(s0 - slope_cf) < 1e-9 and abs(u_n[1] - slope_cf) < 1e-9
assert abs(ratio - LAM / math.pi ** 2) < 1e-6      # series shrinks at lambda/pi^2 per term
assert true_tail <= bound_tail                      # the lambda/8 tail bound holds
assert all(gaps[n] <= 2 * m0 * LAM ** n / math.factorial(2 * n + 2) for n in range(9))
assert abs(res[0]) < 1e-4 and 3.5 < res[0] / res[1] < 4.5  # residual falls like step^2
assert abs(shrink[0] - 1 / math.pi ** 2) < 1e-9 and abs(shrink[1] * (49 * math.pi) ** 2 - 1) < 1e-6
assert mids_hi[29] > 100 * mids_hi[0]               # lambda > pi^2: the series blows up
assert abs(peval(u_hi, 0.5) - exact(0.5, lam_hi)) < 1e-9
print("ALL CHECKS PASS")
