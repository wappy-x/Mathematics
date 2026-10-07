# Characteristic functions and inversion -- the check behind the card.
# Standard library only: math supplies cos, sin, exp, log, sqrt and pi, nothing
# more.  Integrals are Simpson's rule written out; random draws come from
# SplitMix64 (seed 2026) and Box-Muller, written out, so Rust draws the same.
from math import cos, sin, exp, log, sqrt, pi

SD, NDRAW = 2.0, 200000            # the scale's error: normal, mean 0 g, sd 2 g
M64 = (1 << 64) - 1

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def dens(x, mu=0.0, sd=SD):        # the bell in grams
    z = (x - mu) / sd
    return exp(-0.5 * z * z) / (sd * sqrt(2 * pi))

def phi(t, sd=SD):                 # road 1, the card's formula: a bell in t
    return exp(-0.5 * sd * sd * t * t)

def invert(x, phi_re, phi_im, sign=1.0, T=10.0):   # f(x) = (1/2pi) integral of e^{-itx} phi(t)
    g = lambda t: phi_re(t) * cos(t * x) + sign * phi_im(t) * sin(t * x)
    return simpson(g, -T, T, 4000) / (2 * pi)

def die_phi(t, shift=0):           # a fair die: (1/6) sum of e^{itj}, j = 1..6
    return (sum(cos(t * (j + shift)) for j in range(1, 7)) / 6,
            sum(sin(t * (j + shift)) for j in range(1, 7)) / 6)

state = 2026                       # SplitMix64 seed
def uniform():                     # a number in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    z ^= z >> 31
    return ((z >> 11) + 1) / 9007199254740992.0

def normal():                      # Box-Muller, cosine half
    u1 = uniform()
    u2 = uniform()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

acc = [[0.0, 0.0] for _ in range(4)]
for _ in range(NDRAW):
    x1 = SD * normal()
    x2 = SD * normal()
    for k, v in enumerate((cos(0.5 * x1), 1.0 if -2.0 < x1 < 2.0 else 0.0,
                           cos(0.5 * (x1 + x2)), cos(0.5 * (x1 + x1)))):
        acc[k][0] += v
        acc[k][1] += v * v
def mean_se(k):
    m = acc[k][0] / NDRAW
    return m, sqrt((acc[k][1] - NDRAW * m * m) / (NDRAW - 1) / NDRAW)
sim, se = mean_se(0); sim_in, se_in = mean_se(1); sim_2, se_2 = mean_se(2); sim_d, se_d = mean_se(3)

re05 = simpson(lambda x: cos(0.5 * x) * dens(x), -40.0, 40.0, 4000)
im05 = simpson(lambda x: sin(0.5 * x) * dens(x), -40.0, 40.0, 4000)
re1 = simpson(lambda x: cos(1.0 * x) * dens(x), -40.0, 40.0, 4000)
moments = [simpson(lambda z: z ** (2 * k) * dens(z, 0.0, 1.0), -12.0, 12.0, 4000) for k in range(8)]
terms, fact = [], 1.0
for k in range(8):
    terms.append((-1) ** k * moments[k] / fact)
    fact *= (2 * k + 1) * (2 * k + 2)
zero = lambda t: 0.0
f_inv = [invert(x, phi, zero) for x in (0.0, 2.0, 4.0)]
levy_g = lambda t: 4.0 * phi(t) if t == 0 else (sin(2.0 * t) - sin(-2.0 * t)) / t * phi(t)
levy = simpson(levy_g, -10.0, 10.0, 4000) / (2 * pi)
area = simpson(dens, -2.0, 2.0, 4000)
b_re, b_im = (lambda t: cos(t) * phi(t)), (lambda t: sin(t) * phi(t))   # scale reading 1 g heavy
right, wrong = invert(1.0, b_re, b_im), invert(1.0, b_re, b_im, -1.0)
die_p = [invert(k, lambda t: die_phi(t)[0], lambda t: die_phi(t)[1], 1.0, pi) for k in range(1, 8)]
die_bad = [invert(3.0, lambda t: die_phi(t)[0], lambda t: die_phi(t)[1], 1.0, T) for T in (10.0, 20.0, 40.0)]
die_bad_exact = [T / (6 * pi) + sum(sin(T * m) / (6 * pi * m) for m in (-2, -1, 1, 2, 3)) for T in (10.0, 20.0, 40.0)]
gap = lambda t: sqrt((die_phi(t)[0] - die_phi(t, 4)[0]) ** 2 + (die_phi(t)[1] - die_phi(t, 4)[1]) ** 2)
probe_gap = max(gap(k * pi / 2) for k in range(5))
sd_die = sqrt(35 / 12)
s = 1.0 / (sd_die * sqrt(1000))
clt = (sum(cos(s * (j - 3.5)) for j in range(1, 7)) / 6) ** 1000

rows = [("phi(0.5) formula exp(-2 t^2)", phi(0.5)), ("phi(0.5) Simpson, real part", re05),
        ("phi(0.5) Simpson, |imaginary part|", abs(im05)), ("phi(0.5) simulated, 200000 draws", sim),
        ("  standard error", se), ("phi(1) formula", phi(1.0)), ("phi(1) Simpson", re1),
        ("f(0) by inversion", f_inv[0]), ("f(0) density formula", dens(0.0)),
        ("f(2) by inversion", f_inv[1]), ("f(2) density formula", dens(2.0)),
        ("f(4) by inversion", f_inv[2]), ("f(4) density formula", dens(4.0)),
        ("P(-2<X<2) Levy inversion", levy), ("P(-2<X<2) Simpson on density", area),
        ("P(-2<X<2) simulated", sim_in), ("  standard error", se_in),
        ("series for exp(-1/2), 8 terms", sum(terms)), ("exp(-1/2)", exp(-0.5)),
        ("two weighings X1+X2: phi(0.5)^2", phi(0.5) ** 2), ("  simulated", sim_2), ("  standard error", se_2),
        ("one weighing doubled 2X: phi(1)", phi(1.0)), ("  simulated", sim_d), ("  standard error", se_d),
        ("biased scale, f(1), right sign", right), ("wrong: sign flipped, f(1)", wrong),
        ("wrong: no 1/(2 pi), f(0)", 2 * pi * f_inv[0]),
        ("die vs die+4, max gap at t = k pi/2", probe_gap), ("die vs die+4, gap at t = 1", gap(1.0)),
        ("1000 rolls standardized, phi(1)", clt), ("spread of the average, sd/sqrt(1000)", sd_die / sqrt(1000))]
for name, v in rows:
    print(f"{name:<38}{v:>12.6f}")
print("series terms k=0..7    " + " ".join(f"{v:.6f}" for v in terms))
print("die P(X=k) by inversion, k=1..7  " + " ".join(f"{abs(v):.6f}" for v in die_p))
print("wrong: die as a density, T=10,20,40  " + " ".join(f"{v:.4f}" for v in die_bad))
print("  closed form                        " + " ".join(f"{v:.4f}" for v in die_bad_exact))
print("chart, density %/g, x=-6..6   " + " ".join(f"{100 * dens(x):.2f}" for x in range(-6, 7)))
for sd in (1.0, 2.0):
    print(f"chart, phi sd={sd:.0f}, t=-1.5..1.5  " + " ".join(f"{phi(-1.5 + 0.25 * i, sd):.2f}" for i in range(13)))
print("chart, die |phi|, t=k pi/8  " + " ".join(f"{sqrt(sum(c * c for c in die_phi(k * pi / 8))):.2f}" for k in range(17)))

assert abs(re05 - phi(0.5)) < 1e-9, "integral road lands on the bell formula"
assert abs(sim - phi(0.5)) < 4 * se, "simulated average of cos(tX) within 4 standard errors"
assert abs(f_inv[0] - dens(0.0)) < 1e-9, "inversion returns the density at the peak"
assert abs(f_inv[2] - dens(4.0)) < 1e-9, "inversion returns the density in the tail"
assert abs(levy - area) < 1e-8, "Levy's interval formula against the integrated density"
assert abs(sim_in - levy) < 4 * se_in, "Levy's interval formula against the simulated count"
assert abs(sum(terms) - exp(-0.5)) < 1e-5, "series from integrated moments"
assert abs(die_p[2] - 1 / 6) < 1e-9, "die face 3 recovered from its characteristic function"
assert abs(die_p[6]) < 1e-9, "no face 7 recovered"
assert max(abs(a - b) for a, b in zip(die_bad, die_bad_exact)) < 1e-6, "die failure matches its closed form"
assert abs(sim_2 - phi(0.5) ** 2) < 4 * se_2, "independent weighings: transforms multiply"
assert abs(sim_d - phi(0.5) ** 2) > 10 * se_d, "a copied weighing breaks the product rule"
assert abs(clt - exp(-0.5)) < 1e-3, "1000 rolls: the bell in t appears"
assert abs(sim_d - phi(1.0)) < 4 * se_d, "a copied weighing follows phi at the doubled rate"
assert abs(right - dens(1.0, 1.0)) < 1e-9 and abs(wrong - dens(1.0, -1.0)) < 1e-9, "right sign finds the bias, wrong sign mirrors it"
assert probe_gap < 1e-12 and gap(1.0) > 0.05, "die and die+4 agree at k pi/2 but not at t = 1"
print("ALL CHECKS PASS")
