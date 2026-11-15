# Tempered distributions -- the check behind the card.  Standard library only;
# Simpson's rule, the DFT and an erf series are written out here.  The signal is
# a steady 8 m/s wind plus one gust carrying 3 m of extra air at t0 = 2 s.  A
# delta has no value at a point, so the code only ever pairs it with probes or
# uses a gust box of stated width eps as its stand-in.
import math
PI, U, A, T0 = math.pi, 8.0, 3.0, 2.0          # wind m/s, gust m, gust time s

def simpson(f, a, b, n):                       # Simpson's rule, n even
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

def erf(x):                                    # Taylor series, fine for x < 3
    term, total, n = x, x, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -x * x / n
        total += term / (2 * n + 1)
    return 2 / math.sqrt(PI) * total

def z(x):                                      # print -0.000000 as 0.000000
    return 0.0 if abs(x) < 5e-13 else x

def cplx(c):
    return f"{z(c.real):.6f}{z(c.imag):+.6f}i"

def gauss(w):                                  # the probe: a bell 1 rad/s wide
    return math.exp(-w * w / 2)

def gauss_hat(t):                              # its transform, the wing 07 pair
    return math.sqrt(2 * PI) * math.exp(-t * t / 2)

def dft(x, dt):                                # dt * sum x_n e^(-2 pi i k n / N)
    N = len(x)
    return [dt * sum(x[n] * complex(math.cos(2 * PI * k * n / N), -math.sin(2 * PI * k * n / N))
                     for n in range(N)) for k in range(N)]

# ---- finite rehearsal: 8 samples, 0.5 s apart; the gust is one sample of +6 m/s ----
dt = 0.5
x = [U + (A / dt if n == round(T0 / dt) else 0) for n in range(8)]
X = dft(x, dt)
y = [1 / (1 + k) for k in range(8)]
Y = dft(y, dt)
left, right = sum(X[k] * y[k] for k in range(8)), sum(x[n] * Y[n] for n in range(8))
print("wind samples (m/s):", " ".join(f"{v:g}" for v in x))
print("dt * DFT:", " ".join(f"{z(c.real):g}" for c in X), "| imaginary parts all 0:",
      "yes" if all(abs(c.imag) < 1e-12 for c in X) else "no")
print(f"probe moved across: sum X_k y_k = {cplx(left)}, sum x_n Y_n = {cplx(right)}")
assert abs(left - right) < 1e-12                               # the DFT matrix is symmetric
for N in (8, 16, 32, 64, 128):
    L = N * dt
    XN = dft([U + (A / dt if n == round(T0 / dt) else 0) for n in range(N)], dt)
    mags = [abs(c) for c in XN[1:]]
    print(f"N={N:3d} record {L:4g} s: zero bin {XN[0].real:7.3f}, bin width {2 * PI / L:.6f} rad/s, "
          f"steady area {(XN[0].real - A) * 2 * PI / L:.6f}, gust bins {min(mags):.6f} to {max(mags):.6f}")
    assert abs((XN[0].real - A) * 2 * PI / L - 2 * PI * U) < 1e-9 and abs(max(mags) - A) < 1e-9

# ---- the constant: no pointwise transform, but a limit against every probe ----
FL = lambda w, L: U * L if abs(w) < 1e-12 else 2 * U * math.sin(w * L / 2) / w
print(f"truncated transform of {U:g} at w = 1:", ", ".join(f"L={L} {FL(1, L):.6f}" for L in (8, 16, 32)))
for L in (1, 2, 4, 8):
    r1 = simpson(lambda w: FL(w, L) * gauss(w), -12, 12, 6000)         # in frequency
    r2 = U * simpson(gauss_hat, -L / 2, L / 2, 2000)                     # moved onto the probe
    r3 = 2 * PI * U * erf(L / (2 * math.sqrt(2)))                        # erf series
    print(f"L={L}: pairing {r1:.6f} | moved {r2:.6f} | series {r3:.6f} | gap to limit {2 * PI * U - r3:.6f}")
    assert abs(r1 - r3) < 1e-6 and abs(r2 - r3) < 1e-9
print(f"limit 2 pi x {U:g} = {2 * PI * U:.6f}; without the 2 pi the wind inverts to {U / (2 * PI):.6f} m/s")
print("chart L=4:", ", ".join(f"{FL(k / 4, 4):.2f}" for k in range(-8, 9)))
print("chart L=8:", ", ".join(f"{FL(k / 4, 8):.2f}" for k in range(-8, 9)))

# ---- the gust: a box of width eps, height A/eps, centred at t0 = 2 s ----
def box_hat(w, eps):                           # transform of the box, by Simpson
    re = simpson(lambda t: A / eps * math.cos(w * t), T0 - eps / 2, T0 + eps / 2, 200)
    im = simpson(lambda t: -A / eps * math.sin(w * t), T0 - eps / 2, T0 + eps / 2, 200)
    return complex(re, im)
for eps in (0.5, 0.1, 0.02):
    vals = [abs(box_hat(w, eps)) for w in (1, 10)]
    exact = [A * abs(math.sin(w * eps / 2)) / (w * eps / 2) for w in (1, 10)]
    print(f"gust box {eps} s: |spectrum| at w=1 {vals[0]:.6f}, at w=10 {vals[1]:.6f}")
    assert max(abs(v - e) for v, e in zip(vals, exact)) < 1e-7
print("box 0.5 s fades:", ", ".join(f"w={w} {A * abs(math.sin(w / 4)) / (w / 4):.6f} (bound {12 / w:g})"
                                      for w in (10, 100, 1000)))
lhs = simpson(lambda w: (box_hat(w, 0.5) * gauss(w)).real, -12, 12, 1200)
rhs = simpson(lambda t: A / 0.5 * gauss_hat(t), T0 - 0.25, T0 + 0.25, 200)
print(f"box 0.5 s, transform on signal {lhs:.6f}, on probe {rhs:.6f}; delta limit {A * gauss_hat(T0):.6f}")
assert abs(lhs - rhs) < 1e-8
print(f"delta hat on the probe: integral of probe {simpson(gauss, -12, 12, 2000):.6f}; "
      f"1 hat on the probe: integral of its transform {simpson(gauss_hat, -12, 12, 2000):.6f} = 2 pi x probe(0)")

# ---- invert the whole spectrum 16 pi delta + 3 e^(-2 i w), against psi(t) = e^(-t^2/2) ----
inv_psi = lambda w: simpson(lambda t: math.exp(-t * t / 2) * math.cos(w * t), -10, 10, 400) / (2 * PI)
spec = 2 * PI * U * inv_psi(0) + A * simpson(lambda w: math.cos(T0 * w) * inv_psi(w), -10, 10, 400)
sig = U * simpson(lambda t: math.exp(-t * t / 2), -10, 10, 400) + A * math.exp(-T0 * T0 / 2)
print(f"inverse check: spectrum on inverse probe {spec:.6f}, wind on probe {sig:.6f}, "
      f"closed form {U * math.sqrt(2 * PI) + A * math.exp(-T0 * T0 / 2):.6f}")
assert abs(spec - sig) < 1e-9

# ---- not tempered: e^t against the probe sech t on [-M, M] ----
for M in (8, 16, 32):
    v = simpson(lambda t: math.exp(t) / math.cosh(t), -M, M, 4000)
    print(f"e^t against sech, M={M}: {v:.6f}; 1 against sech: {simpson(lambda t: 1 / math.cosh(t), -M, M, 4000):.6f}")
    assert abs(v - 2 * M) < 1e-6

# ---- try changing ----
c = A * complex(math.cos(3), -math.sin(3))
print(f"gust at 3 s, spectrum at w = 1: {cplx(c)}, size {abs(c):.6f}; wind 16 m/s weight {32 * PI:.6f}")
print(f"box 0.1 s at w = 10: {A * math.sin(0.5) / 0.5:.6f}")
print("ALL CHECKS PASS")
