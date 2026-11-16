# Gate and sinc, and the bell that is its own transform -- the check behind the card.
# Standard library only. Convention: f-hat(xi) = integral of f(t) e^(-2 pi i xi t) dt,
# t in seconds, xi in hertz. The gate is a camera shutter open for T = 1 ms.
# Roads: closed form; the defining integral by Simpson's rule at two step counts;
# the finite twin (a sampled sum, one bin of a length-1000 DFT); a series for Si.
import math

T = 0.001                                    # shutter open time, seconds
def sinc(u): return 1.0 if u == 0 else math.sin(math.pi * u) / (math.pi * u)
def one(t): return 1.0                       # the gate, inside its open interval
def gate_hat(xi): return T * sinc(xi * T)                       # road 1
def bell(t): return math.exp(-math.pi * (t / T) ** 2)          # bell with area T
def bell_hat(xi): return T * math.exp(-math.pi * (xi * T) ** 2)  # road 1
def ms(x): return "%.6f" % (0.0 if abs(x) < 5e-13 else 1000 * x)
def f6(x): return "%.6f" % (0.0 if abs(x) < 5e-10 else x)
def sci(x): return "%.2e" % x
def c2(x): return "%.2f" % (0.0 if abs(x) < 0.005 else x)
def cms(z): return ms(z.real) + (" - " if z.imag < -5e-13 else " + ") + ms(abs(z.imag)) + "i"
def probe(xi, t, sign=-1): a = 2 * math.pi * xi * t; return complex(math.cos(a), sign * math.sin(a))

def simpson(f, a, b, n):                     # n even: thin parabola-topped strips
    w = (b - a) / n; s = f(a) + f(b)
    for k in range(1, n): s += (4 if k % 2 else 2) * f(a + k * w)
    return s * w / 3

def by_integral(f, a, b, xi, n, sign=-1):    # road 2: the definition itself
    return simpson(lambda t: f(t) * probe(xi, t, sign), a, b, n)

def by_samples(f, xi, h, M, edge=1.0, step=True):   # road 3: the finite twin
    s = 0j                                   # edge: weight of the samples at n = -M, M
    for n in range(-M, M + 1):
        s += (edge if abs(n) == M else 1.0) * f(n * h) * probe(xi, n * h)
    return s * (h if step else 1.0)

print("convention: f-hat(xi) = integral f(t) e^(-2 pi i xi t) dt; t in s, xi in Hz; values in ms")
print("gate, T = 1 ms: closed form T sinc(xi T); Simpson on the open millisecond, 400 strips; errors at 200 and 400 strips:")
for xi in [0, 500, 1000, 1500, 2000]:
    a, b = by_integral(one, -T / 2, T / 2, xi, 200), by_integral(one, -T / 2, T / 2, xi, 400)
    e1, e2 = abs(a - gate_hat(xi)) / T, abs(b - gate_hat(xi)) / T
    print("  xi = %4d Hz: %s; %s; %s, %s of T" % (xi, ms(gate_hat(xi)), cms(b), sci(e1), sci(e2)))
    assert e1 < 1e-8 and e2 < 1e-9
print("first zeros 1/T for five pulse lengths, with Simpson at that frequency:")
for name, Ts in [("1/100 s", 1 / 100), ("1/250 s", 1 / 250), ("1/1000 s", 1 / 1000), ("1/4000 s", 1 / 4000), ("1 us pulse", 1e-6)]:
    z = by_integral(one, -Ts / 2, Ts / 2, 1 / Ts, 400)
    print("  %s: open %s ms, first zero 1/T = %s Hz, Simpson there %s" % (name, f6(1000 * Ts), f6(1 / Ts), cms(z)))
    assert abs(z) < 1e-15 and abs(by_integral(one, -Ts / 2, Ts / 2, 0.9 / Ts, 400)) > 0.1 * Ts
lobe = simpson(lambda u: sinc(u) ** 2, -1, 1, 2000)
si, term, k = 0.0, 2 * math.pi, 0              # Si(x) = sum (-1)^k x^(2k+1) / ((2k+1)(2k+1)!)
while abs(term) > 1e-17:
    si += term / (2 * k + 1); k += 1; term *= -(2 * math.pi) ** 2 / ((2 * k) * (2 * k + 1))
print("energy below 1 kHz: Simpson %s; 2 Si(2 pi)/pi %s (Si(2 pi) = %s, %d terms)" % (f6(lobe), f6(2 * si / math.pi), f6(si), k))
assert abs(lobe - 2 * si / math.pi) < 1e-9
peak, at = max((abs(sinc(1 + j / 10000)), 1000 + j / 10) for j in range(10001))
print("first side lobe, scan of 1000 to 2000 Hz in 0.1 Hz steps: largest |sinc| %s at %s Hz, %s dB" % (f6(peak), "%.1f" % at, "%.2f" % (20 * math.log10(peak))))
assert 0.2172 < peak < 0.2173 and 1430 < at < 1431
print("unit bell e^(-pi t^2), closed form e^(-pi xi^2) against Simpson on [-6, 6], 600 and 1200 strips:")
tail = math.exp(-36 * math.pi) / (6 * math.pi)
for xi in [0, 0.5, 1, 1.5]:
    a = by_integral(lambda t: math.exp(-math.pi * t * t), -6, 6, xi, 600)
    b = by_integral(lambda t: math.exp(-math.pi * t * t), -6, 6, xi, 1200)
    print("  xi = %.1f: %s; %s; %s" % (xi, f6(math.exp(-math.pi * xi * xi)), f6(a.real), f6(b.real)))
    assert abs(a - math.exp(-math.pi * xi * xi)) < 1e-12 and abs(b - a) < 1e-13
print("  cut-off |t| = 6, tail bound e^(-36 pi)/(6 pi) = %s" % sci(tail))
d = 1e-5
g = lambda x: by_integral(lambda t: math.exp(-math.pi * t * t), -6, 6, x, 1200).real
slope = (g(0.5 + d) - g(0.5 - d)) / (2 * d)
print("slope at xi = 0.5: difference quotient %s; -2 pi xi g-hat %s" % (f6(slope), f6(-math.pi * g(0.5))))
assert abs(slope + math.pi * g(0.5)) < 1e-6
print("shutter flicker pass-through, sinc(nu T) for the gate and e^(-pi (nu T)^2) for the bell:")
for nu in [100, 1000, 1500]:
    print("  nu = %4d Hz: gate %s, bell %s" % (nu, f6(gate_hat(nu) / T), f6(bell_hat(nu) / T)))
print("benchmark, h = 20 us (50 kHz), bins every 50 Hz of a length-1000 DFT; gap = sampled - exact:")
for xi in [0, 500, 1000, 1500]:
    gs, bs = by_samples(one, xi, T / 50, 25, 0.5), by_samples(bell, xi, T / 50, 300)
    print("  bin %2d, %4d Hz: gate %s gap %s; bell %s gap %s" % (xi // 50, xi, ms(gs.real), sci(1000 * (gs.real - gate_hat(xi))), ms(bs.real), sci(1000 * (bs.real - bell_hat(xi)))))
    assert abs(bs - bell_hat(xi)) < 1e-18 and abs(gs.imag) < 1e-15
    assert abs(gs.real - gate_hat(xi)) < 1e-3 * T   # half-weight edges: the gap is aliasing only
g1, g2 = [by_samples(one, 1500, T / m, m // 2, 0.5).real - gate_hat(1500) for m in (50, 100)]
print("gate gap at 1500 Hz: h = 20 us %s ms, h = 10 us %s ms, ratio %s" % (sci(1000 * g1), sci(1000 * g2), "%.4f" % (g1 / g2)))
assert 3.9 < g1 / g2 < 4.1 and abs(g1) > 1e-4 * T
shut = by_integral(one, 0, T, 500, 400, -1)     # shutter opening at t = 0 instead of centred
print("shutter on [0, T] at 500 Hz: Simpson %s; T sinc(1/2) e^(-i pi/2) %s" % (cms(shut), cms(complex(0, -gate_hat(500)))))
assert abs(shut - complex(0, -gate_hat(500))) < 1e-12
print("chart, xi = 0 to 4000 Hz in 250 Hz steps, gate in ms: " + ", ".join(c2(1000 * gate_hat(250 * j)) for j in range(17)))
print("chart, xi = 0 to 4000 Hz in 250 Hz steps, bell in ms: " + ", ".join(c2(1000 * bell_hat(250 * j)) for j in range(17)))
wrong = lambda xi: by_integral(one, -T / 2, T / 2, xi / (2 * math.pi), 400)   # kernel e^(-i xi t)
print("mistake, kernel e^(-i xi t) with xi in Hz: at 1000 Hz %s; first zero at %s Hz, Simpson there %s" % (cms(wrong(1000)), f6(2 * math.pi / T), cms(wrong(2 * math.pi / T))))
assert abs(wrong(2 * math.pi / T)) < 1e-15 and abs(wrong(1000) - gate_hat(1000)) > 0.9 * T
nostep = by_samples(one, 0, T / 50, 25, 0.5, step=False).real
print("mistake, no step h in the sum, gate at 0 Hz: %s instead of %s ms" % (f6(nostep), ms(gate_hat(0))))
assert abs(nostep - gate_hat(0) / (T / 50)) < 1e-9      # a count of samples: the area over h
full = by_samples(one, 1000, T / 50, 25).real
print("mistake, edge samples at full weight: 0 Hz %s ms, 1000 Hz %s ms" % (ms(by_samples(one, 0, T / 50, 25).real), ms(full)))
assert abs(full + T / 50) < 1e-15
flip = by_integral(one, 0, T, 500, 400, +1)
print("mistake, sign flipped to e^(+2 pi i xi t): shutter on [0, T] %s; centred gate %s, unchanged" % (cms(flip), cms(by_integral(one, -T / 2, T / 2, 500, 400, +1))))
assert abs(flip - shut.conjugate()) < 1e-15 and abs(flip - shut) > T
area = [2 * sum(simpson(lambda u: abs(sinc(u)), j, j + 1, 40) for j in range(W)) for W in (10, 100, 1000)]
print("hypothesis fails: area under |sinc| on [-W, W], W = 10, 100, 1000: %s, %s, %s; per decade %s, %s against (4/pi^2) ln 10 = %s"
      % (f6(area[0]), f6(area[1]), f6(area[2]), f6(area[1] - area[0]), f6(area[2] - area[1]), f6(4 / math.pi ** 2 * math.log(10))))
assert abs(area[2] - area[1] - 4 / math.pi ** 2 * math.log(10)) < 0.01
print("ALL CHECKS PASS")
