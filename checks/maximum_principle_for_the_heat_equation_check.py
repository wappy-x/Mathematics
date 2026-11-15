# Diffusion's maximum principle -- the check behind the card.  Standard library only.
# A 1 m copper rod, ends held at 20 C, starts with a tent-shaped hot spot 20 cm wide
# peaking at 100 C.  Roads: a sine series, an explicit grid, the equation's residual
# by centred differences, and a barrier built by hand.  Then the three breaks,
# ending with Tychonoff's solution on an endless rod.
import math

PI = math.pi
KAPPA = 1.0 / 9009.0               # copper's diffusivity, m^2/s (9009 s per m^2)
END, PEAK, W = 20.0, 80.0, 0.1      # end temperature, C; hot spot's rise, K; half-width, m
XS = [i / 20 for i in range(21)]    # chart positions, m


def total(xs):                      # plain left-to-right sum, as in the Rust check
    s = 0.0
    for v in xs:
        s += v
    return s


def tent(x):                        # the start, C
    return END + PEAK * max(0.0, 1.0 - abs(x - 0.5) / W)


def b(n):                           # sine coefficient of the tent's rise
    return 4 * PEAK * math.sin(n * PI / 2) * (1 - math.cos(n * PI * W)) / (W * (n * PI) ** 2)


def rod(x, t, n_max=40):            # road 1: the sine series, C
    return END + total(b(n) * math.exp(-KAPPA * (n * PI) ** 2 * t) * math.sin(n * PI * x)
                       for n in range(1, n_max + 1))


def grid(m, steps, t_end):          # road 2: explicit grid; profile and extremes over the run
    h = 1.0 / m
    dt = t_end / steps
    r = KAPPA * dt / (h * h)
    u = [tent(i * h) for i in range(m + 1)]
    hi, lo = max(u), min(u)
    for _ in range(steps):
        u = [u[0]] + [u[i] + r * (u[i - 1] - 2 * u[i] + u[i + 1]) for i in range(1, m)] + [u[m]]
        hi, lo = max(hi, max(u)), min(lo, min(u))
    return u, hi, lo, r


def row(vals):
    return ", ".join(f"{v:.2f}" for v in vals)


def resid(f, x, t, dx, dt, k):      # u_t - k u_xx by centred differences
    ut = (f(x, t + dt) - f(x, t - dt)) / (2 * dt)
    return ut - k * (f(x + dx, t) - 2 * f(x, t) + f(x - dx, t)) / (dx * dx)


print(f"setup: kappa = 1/9009 = {KAPPA * 1e4:.4f}e-4 m^2/s; boundary max {max(map(tent, XS)):.1f} C, min {END:.1f} C")
print(f"b_1 = 320*(1 - cos(0.1 pi))/(0.1 pi^2) = {b(1):.4f} K; b_2 = {b(2):.4f}; b_3 = {b(3):.4f} K")
s0 = END + total(b(n) * math.sin(n * PI * 0.45) for n in range(1, 2001))
print(f"start at x=0.45: tent {tent(0.45):.4f}, series N=2000 {s0:.4f}, tail bound {4 * PEAK * 2 / (W * PI ** 2) / 2000:.4f}")
assert abs(s0 - tent(0.45)) < 4 * PEAK * 2 / (W * PI ** 2) / 2000
for t in (0, 60, 600):
    vals = [tent(x) for x in XS] if t == 0 else [rod(x, t) for x in XS]
    print(f"profile t={t} s, x=0,0.05..1: {row(vals)}")
print(f"series uses 40 terms; log10 of the first omitted term at t=60 s: {math.log10(abs(b(41))) - KAPPA * (41 * PI) ** 2 * 60 / math.log(10):.1f}")
for t in (60, 300, 600, 1800):
    prof = [rod(i / 200, t) for i in range(201)]
    assert 20.0 - 1e-9 <= min(prof) and max(prof) <= 100.0
    print(f"t={t} s: rod max {max(prof):.4f} C at x={prof.index(max(prof)) / 200:.3f} m, min {min(prof):.4f} C")
centre = {}
for m, steps in ((50, 375), (100, 1500)):
    u, hi, lo, r = grid(m, steps, 600.0)
    centre[m] = u[m // 2]
    assert hi <= 100.0 + 1e-12 and lo >= 20.0 - 1e-12
    print(f"grid h=1/{m}, r={r:.4f}: centre at 600 s {u[m // 2]:.4f} C; over the run max {hi:.4f}, min {lo:.4f}")
exact = rod(0.5, 600)
ratio = (centre[50] - exact) / (centre[100] - exact)
print(f"centre at 600 s: series {exact:.4f} C; grid error ratio {ratio:.2f}")
assert abs(centre[100] - exact) < 0.01 and 3.5 < ratio < 4.5
for k in (1e-3, 5e-4):              # road 3: the equation's residual
    res = resid(rod, 0.3, 600.0, k, 1e4 * k, KAPPA)
    print(f"residual u_t - kappa u_xx at (0.3 m, 600 s), dx={k:.4f} m, dt={1e4 * k:.0f} s: {res * 1e9:.2f} nK/s")
    assert abs(res) < 1e-7
lam = KAPPA * PI ** 2               # road 4: the barrier 20 + 80 exp(-lam t) sin(pi x)
half = math.log(2) / lam
bar = END + PEAK * math.exp(-lam * 600)
print(f"barrier: decay rate kappa pi^2 = {lam * 1e3:.4f}e-3 per s, half-life {half:.1f} s; centre cap at 600 s {bar:.2f} C")
print(f"barrier factor exp(-{lam * 600:.4f}) = {math.exp(-lam * 600):.4f}; b_1 term at the centre {b(1) * math.exp(-lam * 600):.4f} K of the rise {exact - END:.4f} K")
ok = all(rod(i / 50, t) <= END + PEAK * math.exp(-lam * t) * math.sin(PI * i / 50) + 1e-9
         for i in range(51) for t in (60, 300, 600, 1800))
print(f"barrier above the series at 51 points x 4 times: {'yes' if ok else 'no'}")
assert ok and exact < bar
q = (exact - END) / PEAK
print(f"plate 1 m square, hot square spot: centre at 600 s 20 + 80*{q:.4f}^2 = {END + PEAK * q * q:.4f} C, rod {exact:.4f} C")
u, hi, lo, r = grid(50, 30, 60.0)
print(f"try: grid h=1/50, r={r:.4f} > 1/2: after 60 s max {hi:.1f} C, min {lo:.1f} C")
# ---- what breaks ----
A = 10.0                            # heater: source kappa pi^2 A sin(pi x), start and ends 20 C
def heater(x, t):
    return END + A * (1 - math.exp(-lam * t)) * math.sin(PI * x)


src = resid(heater, 0.5, 600.0, 1e-3, 10.0, KAPPA)
print(f"breaks 1, heater: residual = source {src * 1e3:.4f} mK/s, formula {lam * A * 1e3:.4f} mK/s; "
      f"centre at 600 s {heater(0.5, 600):.4f} C, boundary max 20.0000 C")
assert abs(src - lam * A) < 1e-6 and heater(0.5, 600) > END + 4
back = lambda x, t: math.exp(lam * t) * math.sin(PI * x)
res = resid(back, 0.5, 600.0, 1e-3, 10.0, -KAPPA)
print(f"breaks 2, time run backward, u_t = -kappa u_xx (residual {res * 1e9:.2f} nK/s): "
      f"1 K sine bump at 600 s {back(0.5, 600):.4f} K, boundary max 1.0000 K")
assert abs(res) < 1e-7 and back(0.5, 600) > 1.9

def tych(x, t, K=120):              # Tychonoff: sum g^(k)(t) x^(2k)/(2k)!, g = exp(-1/t^2)
    h = [-((-1) ** n) * (n + 1) / t ** (n + 2) for n in range(K + 1)]  # Taylor coefficients of -1/(t+s)^2
    c = [math.exp(h[0])]
    for n in range(1, K + 1):       # coefficients of exp(h): n c_n = sum j h_j c_(n-j)
        c.append(total(j * h[j] * c[n - j] for j in range(1, n + 1)) / n)
    ratio, terms = 1.0, []
    for k in range(K + 1):          # g^(k) = k! c_k, ratio = k!/(2k)!
        if k > 0:
            ratio *= k / ((2 * k) * (2 * k - 1))
        terms.append(c[k] * ratio * x ** (2 * k))
    return total(terms[:K]), terms[K], c

_, _, c = tych(1.0, 0.5)
print(f"breaks 3, Tychonoff g'(0.5)/g = 2/0.5^3: series {c[1] / c[0]:.6f}, closed form {2 / 0.5 ** 3:.6f}")
assert abs(c[1] / c[0] - 16) < 1e-9 and abs(2 * c[2] / c[0] - (4 / 0.5 ** 6 - 6 / 0.5 ** 4)) < 1e-6
for x, t in ((0.0, 1.0), (1.0, 0.5), (3.0, 0.3)):
    val, last, _ = tych(x, t)
    tail = f"log10 of first omitted term {math.log10(abs(last)):.0f}" if x else "exact, one term"
    print(f"  u({x:.0f} m, {t:.1f} scaled = {t * 9009:.1f} s) = {val:.4f} K from a 0 K start; {tail}")
p, ref = [1.0], 0.0                 # second road at (1 m, 0.5): g^(k)(t) = P_k(1/t) e^(-1/t^2), with
for k in range(20):                 # P_(k+1)(s) = 2 s^3 P_k(s) - s^2 P_k'(s), summed at s = 1/t = 2
    ref += total(a * 2.0 ** i for i, a in enumerate(p)) * math.exp(-4) / math.factorial(2 * k)
    p = [2 * (p[i - 3] if i > 2 else 0) - (i - 1) * (p[i - 1] if 0 < i - 1 < len(p) else 0) for i in range(len(p) + 3)]
assert abs(tych(1.0, 0.5)[0] - ref) < 1e-12
for k in (0.01, 0.005):
    res = resid(lambda x, t: tych(x, t)[0], 1.0, 0.5, k, k, 1.0)
    print(f"  residual u_t - u_xx at (1, 0.5) scaled, step {k}: {res:.6f}")
    assert abs(res) < 10 * k * k
print("ALL CHECKS PASS")
