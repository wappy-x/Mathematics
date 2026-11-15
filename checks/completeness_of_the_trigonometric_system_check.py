# Completeness of sines and cosines -- the check behind the card.  Standard library only.
# The siren is a square wave: +1 V on (0, pi), -1 V on (-pi, 0), phase x in radians.
# Energy means the integral of the square over one cycle, in V^2 rad.
# Every infinite object is a truncation: harmonics up to N, shown at several N.
import math

PI = math.pi

def simpson(fn, a, b, m):              # Simpson's rule with m (even) intervals
    h = (b - a) / m
    s = fn(a) + fn(b)
    for i in range(1, m):
        s += (4 if i % 2 else 2) * fn(a + i * h)
    return s * h / 3

def b_sq(k):                            # sine amount of the siren, closed form
    return 4 / (PI * k)

def partial(x, N, b):                   # S_N at x: odd sines up to N with amounts b(k)
    return sum(b(k) * math.sin(k * x) for k in range(1, N + 1, 2))

def missing_ledger(N, b, energy):       # energy minus the ledger of kept harmonics
    return energy - PI * sum(b(k) ** 2 for k in range(1, N + 1, 2))

def check(label, got, want, tol):
    assert abs(got - want) < tol, (label, got, want)

# 1. Rehearsal: 8 samples of one cycle and 8 sampled harmonics.
M = 8
xs = [-PI + (j + 0.5) * 2 * PI / M for j in range(M)]
fs = [1.0 if x > 0 else -1.0 for x in xs]
waves = [lambda x: 1 / math.sqrt(M)]
for n in (1, 2, 3):
    waves.append(lambda x, n=n: math.cos(n * x) * math.sqrt(2 / M))
    waves.append(lambda x, n=n: math.sin(n * x) * math.sqrt(2 / M))
waves.append(lambda x: math.sin(4 * x) / math.sqrt(M))
U = [[w(x) for x in xs] for w in waves]
dot = lambda u, v: sum(a * b for a, b in zip(u, v))
gram = max(abs(dot(U[i], U[j]) - (1 if i == j else 0)) for i in range(M) for j in range(M))
coef = [dot(u, fs) for u in U]
rebuilt = [sum(c * u[j] for c, u in zip(coef, U)) for j in range(M)]
print("rehearsal, M = 8 samples, 8 sampled harmonics")
print(f"  largest Gram error below 1e-12: {'yes' if gram < 1e-12 else 'no'}")
err = max(abs(r - f) for r, f in zip(rebuilt, fs))
print(f"  largest rebuild error below 1e-12: {'yes' if err < 1e-12 else 'no'}")
print(f"  sample energy {dot(fs, fs):.6f} = sum of squared amounts {sum(c * c for c in coef):.6f}")
print(f"  drop sin 3x: rebuild misses energy {coef[6] ** 2:.6f}")
assert gram < 1e-12, gram
assert err < 1e-12, err
check("rehearsal energy", sum(c * c for c in coef), dot(fs, fs), 1e-12)

# 2. The siren's sine amounts: closed form against Simpson.
print("sine amounts b_k = 4/(pi k): closed form, Simpson, energy pi b_k^2")
for k in (1, 3, 5):
    simp = 2 / PI * simpson(lambda x: math.sin(k * x), 0, PI, 200)
    print(f"  k = {k}: {b_sq(k):.6f} {simp:.6f} {PI * b_sq(k) ** 2:.6f}")
    check("b_k", simp, b_sq(k), 1e-6)

# 3. Missing energy ||f - S_N f||^2: ledger against a direct integral.
E = 2 * PI
print(f"siren energy ||f||^2 = {E:.6f} V^2 rad")
top = max(k for k in range(1, 100, 2) if 500 * k <= 44100 / 2)   # 500 Hz siren, 44.1 kHz audio
print(f"44.1 kHz copy keeps odd harmonics up to {top}: {500 * top} Hz <= {44100 // 2} Hz")
print("N, missing energy by ledger, by direct integral, share missing")
for N in (1, 3, 5, top):
    led = missing_ledger(N, b_sq, E)
    direct = 2 * simpson(lambda x: (1 - partial(x, N, b_sq)) ** 2, 0, PI, 6000)
    print(f"  {N}: {led:.6f} {direct:.6f} {100 * led / E:.4f}%")
    check("missing", direct, led, 1e-6)
print("large N, ledger only: N, missing, N x missing (tends to 8/pi)")
for N in (99, 999, 9999):
    led = missing_ledger(N, b_sq, E)
    print(f"  {N}: {led:.6f} {N * led:.6f}")
print(f"  8/pi = {8 / PI:.6f}")
check("rate", 9999 * missing_ledger(9999, b_sq, E), 8 / PI, 1e-3)

# 4. Chart and bars.
pts = [(N, missing_ledger(N, b_sq, E)) for N in (1, 3, 9, 27, 81, 243, 729, 2187)]
print("chart, log10 N:", " ".join(f"{math.log10(n):.2f}" for n, _ in pts))
print("chart, log10 missing:", " ".join(f"{math.log10(m):.2f}" for _, m in pts))
slope = (math.log10(pts[-1][1]) - math.log10(pts[-2][1])) / (math.log10(2187) - math.log10(729))
print(f"chart, last slope: {slope:.3f}")
check("slope", slope, -1.0, 0.01)
print("bars, share of energy per harmonic:",
      " ".join(f"k={k}:{100 * PI * b_sq(k) ** 2 / E:.2f}%" for k in (1, 3, 5, 7, 9)))

# 5. The proof in numbers: ramp g (siren averaged over a window of half-width d).
d, N = 0.02, 99
b_g = lambda k: b_sq(k) * math.sin(k * d) / (k * d)
def g(x):                               # on (0, pi)
    return min(1.0, x / d, (PI - x) / d)
pieces = lambda fn: simpson(fn, 0, d, 200) + simpson(fn, d, PI - d, 6000) + simpson(fn, PI - d, PI, 200)
fg = 2 * pieces(lambda x: (1 - g(x)) ** 2)
print(f"proof, delta = {d}, N = {N}")
print(f"  ||f - g||^2: closed 4 delta/3 = {4 * d / 3:.6f}, Simpson {fg:.6f}")
check("f-g", fg, 4 * d / 3, 1e-9)
for k in (1, 3):
    simp = 2 / PI * pieces(lambda x: g(x) * math.sin(k * x))
    print(f"  b_{k}(g): closed {b_g(k):.6f}, Simpson {simp:.6f}")
    check("b_g", simp, b_g(k), 1e-8)
Eg = E - 8 * d / 3
gled = missing_ledger(N, b_g, Eg)
gdir = 2 * pieces(lambda x: (g(x) - partial(x, N, b_g)) ** 2)
print(f"  ||g - S_N g||^2: ledger {gled:.6f}, direct {gdir:.6f}, bound 4/(delta (N+1)^2) {4 / (d * (N + 1) ** 2):.6f}")
check("g ledger", gdir, gled, 1e-6)
assert gled <= 4 / (d * (N + 1) ** 2)
fs_n = math.sqrt(missing_ledger(N, b_sq, E))
bound = math.sqrt(4 * d / 3) + math.sqrt(gled)
print(f"  ||f - S_N f|| = {fs_n:.6f} <= {math.sqrt(4 * d / 3):.6f} + {math.sqrt(gled):.6f} = {bound:.6f}")
assert fs_n <= bound

# 6. What breaks.
N = 999
drop3 = missing_ledger(N, b_sq, E) + PI * b_sq(3) ** 2
print(f"breaks, N = {N}: harmonic 3 dropped, missing {drop3:.6f} (never below {PI * b_sq(3) ** 2:.6f})")
offset = missing_ledger(N, b_sq, E) + 0.25 * 2 * PI
print(f"breaks, N = {N}: sines only, siren + 0.5 V, missing {offset:.6f} (never below {0.5 * PI:.6f})")
si = simpson(lambda u: math.sin(u) / u if u else 1.0, 0, PI, 2000)
for N in (43, 999):
    peak = partial(PI / (N + 1), N, b_sq)
    print(f"breaks, sup norm: N = {N}, peak of S_N at pi/(N+1) = {peak:.6f}")
print(f"breaks, sup norm: limit (2/pi) Si(pi) = {2 / PI * si:.6f}")
check("gibbs", partial(PI / 1000, 999, b_sq), 2 / PI * si, 1e-5)
print("ALL CHECKS PASS")
