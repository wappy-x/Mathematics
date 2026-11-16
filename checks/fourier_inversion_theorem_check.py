# Fourier inversion -- the check behind the card.  Standard library only.
# Convention: fhat(xi) = integral of f(t) e^(-2 pi i xi t) dt, t in seconds, xi in
# hertz; the inverse has no factor in front.  The shutter is open (f = 1) for T = 1 ms.
# Two rebuilds: the sharp cut-off S_W (keep |xi| < W) and the bell rebuild G_eps
# (multiply the spectrum by e^(-pi eps^2 xi^2)).  Roads: closed forms through Si and
# erf, each a series written out here; the inverse integral on the frequency side by
# Simpson's rule at n and 2n strips; the blur on the time side, also by Simpson.
from math import pi, sin, cos, exp, sqrt, log

T = 0.001                                         # shutter open time, seconds
def f6(x): return "%.6f" % (0.0 if abs(x) < 5e-7 else x)
def sci(x): return "%.2e" % x
def c2(x): return "%.2f" % (0.0 if abs(x) < 0.005 else x)
def fhat(xi): return T if xi == 0 else sin(pi * T * xi) / (pi * xi)   # spectrum, s

def si(x):                                        # Si(x): area under sin(u)/u, 0 to x
    if x < 0: return -si(-x)
    if x <= 20:                                   # power series, 80 terms
        a, s = x, 0.0
        for k in range(80):
            s += a / (2 * k + 1)
            a *= -x * x / ((2 * k + 2) * (2 * k + 3))
        return s
    fa, ga, c = 0.0, 0.0, 1.0                     # large x: asymptotic series, 9 terms
    for k in range(9):
        fa += c / x ** (2 * k + 1)
        ga += c * (2 * k + 1) / x ** (2 * k + 2)
        c *= -(2 * k + 1) * (2 * k + 2)
    return pi / 2 - fa * cos(x) - ga * sin(x)

def erf(x):                                       # erf(x) = (2/sqrt(pi)) area under e^(-u^2)
    if x < 0: return -erf(-x)
    if x <= 4:                                    # power series, 100 terms
        a, s = x, 0.0
        for k in range(100):
            s += a / (2 * k + 1)
            a *= -x * x / (k + 1)
        return 2 * s / sqrt(pi)
    s, c = 0.0, 1.0                               # large x: erfc asymptotic, 7 terms
    for k in range(7):
        s += c
        c *= -(2 * k + 1) / (2 * x * x)
    return 1 - exp(-x * x) / (x * sqrt(pi)) * s

def simpson(g, a, b, n):
    w = (b - a) / n; s = g(a) + g(b)
    for k in range(1, n): s += (4 if k % 2 else 2) * g(a + k * w)
    return s * w / 3

def sharp_closed(t, W): return (si(2 * pi * W * (t + T / 2)) - si(2 * pi * W * (t - T / 2))) / pi
def bell_closed(t, e): return (erf(sqrt(pi) * (t + T / 2) / e) - erf(sqrt(pi) * (t - T / 2) / e)) / 2
def sharp_freq(t, W, n): return 2 * simpson(lambda x: fhat(x) * cos(2 * pi * x * t), 0, W, n)
def bell_freq(t, e, n): return 2 * simpson(lambda x: fhat(x) * exp(-pi * (e * x) ** 2) * cos(2 * pi * x * t), 0, 4 / e, n)
def dirichlet(u, W): return 2 * W if u == 0 else sin(2 * pi * W * u) / (pi * u)
def sharp_time(t, W, n): return simpson(lambda s: dirichlet(t - s, W), -T / 2, T / 2, n)
def bell_time(t, e, n): return simpson(lambda s: exp(-pi * ((t - s) / e) ** 2) / e, -T / 2, T / 2, n)

print("shutter open T = 1 ms; fhat in ms at 0, 500, 1000 Hz: %s, %s, %s" % tuple(f6(1000 * fhat(x)) for x in (0, 500, 1000)))
def lobes(m): return 2 * sum(simpson(lambda u: abs(sin(pi * u) / (pi * u)) if u else 1.0, k, k + 1, 40) for k in range(m))
areas = [lobes(10), lobes(100), lobes(1000)]
print("area under |fhat| on [-W, W], W = 10 kHz, 100 kHz, 1 MHz: %s, %s, %s" % tuple(f6(a) for a in areas))
print("growth per decade: %s, %s; (4/pi^2) ln 10 = %s" % (f6(areas[1] - areas[0]), f6(areas[2] - areas[1]), f6(4 / pi ** 2 * log(10))))
assert abs(areas[2] - areas[1] - 4 / pi ** 2 * log(10)) < 1e-5            # the area never settles
print("by hand: erf(9 sqrt(pi)) = %s, erf(sqrt(pi)) = %s, erf(5 sqrt(pi)) = %s" % (f6(erf(9 * sqrt(pi))), f6(erf(sqrt(pi))), f6(erf(5 * sqrt(pi)))))
print("by hand: Si(18 pi) = %s, Si(2 pi) = %s, Si(10 pi) = %s; area of |f| / eps = %s" % (f6(si(18 * pi)), f6(si(2 * pi)), f6(si(10 * pi)), f6(T / 1e-4)))
print("bell peak 1/eps = %s per s, spread eps/sqrt(2 pi) = %s ms, fade at 10 kHz = %s; D_W peak 2W = %s per s"
      % (f6(1 / 1e-4), f6(0.1 / sqrt(2 * pi)), f6(exp(-pi * (1e-4 * 1e4) ** 2)), f6(dirichlet(0, 10000))))
peaks = []
for W, e, n in [(10000, 1e-4, 4000), (100000, 1e-5, 40000)]:
    print("W = %d kHz, eps = %s ms; Simpson at %d and %d strips" % (W // 1000, f6(1000 * e), n, 2 * n))
    gap = 0.0
    for name, closed, freq, time in [("sharp cut-off S_W", sharp_closed, sharp_freq, sharp_time),
                                     ("bell rebuild G_eps", bell_closed, bell_freq, bell_time)]:
        p = W if closed is sharp_closed else e
        nf = n if closed is sharp_closed else 4 * n
        print("  %s at t ms: closed form | frequency side | time side" % name)
        for tm in (0.0, 0.4, 0.5, 0.6, 1.0):
            t = tm / 1000
            c, a, b, a2 = closed(t, p), freq(t, p, 2 * nf), time(t, p, 2 * n), freq(t, p, nf)
            gap = max(gap, abs(a - a2))
            print("    t = %.1f: %s | %s | %s" % (tm, f6(c), f6(a), f6(b)))
            assert abs(c - a) < 1e-7 and abs(c - b) < 1e-7                # three roads agree
    tail = 2 * T * exp(-16 * pi) / (8 * pi * e)
    print("  largest gap n vs 2n strips: %s; bell cut at 4/eps, tail bound %s" % (sci(gap), sci(tail)))
    scan = [(sharp_closed(k * 1e-7, W), k / 10000) for k in range(4000, 5001)]
    top, at = max(scan)
    hi = max(bell_closed(k * 1e-7, e) for k in range(0, 10001))
    lo = min(bell_closed(k * 1e-7, e) for k in range(0, 10001))
    peaks.append(top)
    print("  scan 0.4 to 0.5 ms: largest S_W %s at t = %.4f ms; G_eps over 0 to 1 ms stays in [%s, %s]" % (f6(top), at, f6(lo), f6(hi)))
    l1 = 2 * sum(simpson(lambda t: abs(bell_closed(t, e) - (j < 0)), T / 2 + j * e / 2, T / 2 + (j + 1) * e / 2, 200)
                 for j in range(-round(T / e), 20))
    print("  mean error, area of |G_eps - f|: %s ms; 2 eps/pi = %s ms" % (f6(1000 * l1), f6(1000 * 2 * e / pi)))
    print("  middle miss 1 - S_W(0): %s; 2/(pi^2 W T) = %s" % (f6(1 - sharp_closed(0, W)), f6(2 / (pi ** 2 * W * T))))
    assert abs(l1 - 2 * e / pi) < 1e-6 * 2 * e / pi                         # mean error is 2 eps/pi
    assert abs(1 - sharp_closed(0, W) - 2 / (pi ** 2 * W * T)) < 0.1 * 2 / (pi ** 2 * W * T)
    assert lo >= 0 and hi <= 1 and abs(bell_closed(T / 2, e) - 0.5) < 1e-12   # no overshoot, midpoint
print("single-edge overshoot limit 1/2 + Si(pi)/pi = %s" % f6(0.5 + si(pi) / pi))
assert min(peaks) > 0.5 + si(pi) / pi - 1e-3                               # overshoot never shrinks
print("mistake, 1/(2 pi) in front with xi in hertz: G_eps(0) = %s instead of %s" % (f6(bell_closed(0, 1e-4) / (2 * pi)), f6(bell_closed(0, 1e-4))))
print("mistake, edge read as 1: S_W(0.5 ms) = %s at 100 kHz, G_eps(0.5 ms) = %s" % (f6(sharp_closed(T / 2, 100000)), f6(bell_closed(T / 2, 1e-5))))
print("mistake, no damping: integral of e^(2 pi i xi u) over |xi| < L at u = 0.1 ms, per s:")
print("  L = 10, 12.5, 15, 17.5 kHz: %s" % ", ".join(f6(dirichlet(1e-4, L)) for L in (10000, 12500, 15000, 17500)))
ts = [0.3 + 0.01 * k for k in range(41)]
print("chart t ms: " + ", ".join("%.2f" % t for t in ts))
print("chart shutter: " + ", ".join("%.2f" % (1 if t < 0.499 else 0.5 if t < 0.501 else 0) for t in ts))
print("chart S_W 10 kHz: " + ", ".join(c2(sharp_closed(t / 1000, 10000)) for t in ts))
print("chart G_eps 0.1 ms: " + ", ".join(c2(bell_closed(t / 1000, 1e-4)) for t in ts))
print("ALL CHECKS PASS")
