# The Hilbert transform and the analytic signal -- the check behind the card.
# Standard library only.  Convention: fhat(xi) = integral of f(t) e^(-2 pi i xi t) dt.
# H has multiplier -i sgn(xi) and kernel 1/(pi t); the analytic signal is z = s + i Hs.
from math import pi, sin, cos, exp, log, sqrt, atan2

def midpoint(g, a, b, n):                    # the integral of g from a to b, n cells
    h = (b - a) / n
    return h * sum(g(a + (k + 0.5) * h) for k in range(n))

# Road to the multiplier: (2/pi) times the integral of sin(x)/x from 0 to X tends to 1.
for X in [10, 100, 1000]:
    v = 2 / pi * midpoint(lambda x: sin(x) / x, 0, X, 100 * X)
    print("quarter turn: (2/pi) Si(%d) = %.6f, off by %.6f, bound 4/(pi X) = %.6f" % (X, v, abs(v - 1), 4 / (pi * X)))
    assert abs(v - 1) <= 4 / (pi * X)

# Kernel against multiplier, on a click f(t) = 1/(1 + t^2), t in ms, xi in kHz.
f = lambda t: 1 / (1 + t * t)
fh = midpoint(lambda t: f(t) * cos(pi * t), -200, 200, 40000)
print("click: fhat(0.5 kHz) by its integral %.6f ms, closed form pi e^(-pi) %.6f ms" % (fh, pi * exp(-pi)))
assert abs(fh - pi * exp(-pi)) < 1e-4
for t in [0.5, 1.0, 2.0]:
    exact = t / (1 + t * t)
    ker = [midpoint(lambda u: (f(t - u) - f(t + u)) / u, 0, R, 200 * R) / pi for R in (50, 100)]
    mul = midpoint(lambda x: 2 * pi * exp(-2 * pi * x) * sin(2 * pi * x * t), 0, 6, 60000)
    print("click Hf(%.1f ms): t/(1+t^2) %.6f; kernel R=50 %.6f, R=100 %.6f; multiplier %.6f"
          % (t, exact, ker[0], ker[1], mul))
    assert abs(ker[1] - exact) < 1e-6 and abs(mul - exact) < 1e-7

# The AM signal: s = A(t) cos(2 pi FC t), A = 1 + m cos(2 pi FM t), sampled 1 ms at 8 MHz.
FC, FM, FS = 1000e3, 1e3, 8e6                # carrier Hz, tone Hz, samples per second
def fft(a, sgn):                             # mixed-radix Cooley-Tukey, any n with factors 2 and 5
    n = len(a)
    if n == 1:
        return a[:]
    p = 2 if n % 2 == 0 else 5
    m = n // p
    subs = [fft(a[r::p], sgn) for r in range(p)]
    out = []
    for k in range(n):
        acc = 0j
        for r in range(p):
            ang = sgn * 2 * pi * r * k / n
            acc += subs[r][k % m] * complex(cos(ang), sin(ang))
        out.append(acc)
    return out
def hilbert(s, flip=1):                      # multiply bin k by -i sgn(k), zero at 0 and n/2
    n, X = len(s), fft([complex(v) for v in s], -1)
    for k in range(n):
        X[k] *= 0 if k == 0 or 2 * k == n else (-1j if 2 * k < n else 1j) * flip
    return [v.real / n for v in fft(X, 1)]
def am(m, fc, fm, n):
    t = [k / FS for k in range(n)]
    A = [1 + m * cos(2 * pi * fm * x) for x in t]
    return t, A, [a * cos(2 * pi * fc * x) for a, x in zip(A, t)]

t, A, s = am(0.5, FC, FM, 8000)
X = fft([complex(v) for v in s], -1)
for k in [999, 1000, 1001, 1500]:
    d = sum(s[j] * complex(cos(2 * pi * j * k / 8000), -sin(2 * pi * j * k / 8000)) for j in range(8000))
    print("bin %d (%d kHz): |FFT| %.6f, |direct DFT| %.6f" % (k, k, abs(X[k]), abs(d)))
    assert abs(X[k] - d) < 1e-6
hs = hilbert(s)
env = [sqrt(a * a + b * b) for a, b in zip(s, hs)]
gap_h = max(abs(b - a * sin(2 * pi * FC * x)) for a, b, x in zip(A, hs, t))
gap_e = max(abs(e - a) for e, a in zip(env, A))
print("largest gap, Hs against A sin: %.9f V; envelope against A: %.9f V" % (gap_h, gap_e))
assert gap_h < 1e-9 and gap_e < 1e-9
hhs = hilbert(hs)                            # H twice is minus the signal; energy is kept
ms_s, ms_h = sum(v * v for v in s) / 8000, sum(v * v for v in hs) / 8000
gap_hh = max(abs(a + b) for a, b in zip(hhs, s))
print("mean square: s %.6f V^2, Hs %.6f V^2, by hand (1 + 2 x 0.25^2)/2 = 0.562500; H(Hs) + s largest %.9f V" % (ms_s, ms_h, gap_hh))
assert abs(ms_s - 0.5625) < 1e-12 and abs(ms_h - 0.5625) < 1e-12 and gap_hh < 1e-9
n0 = 1601
ph = atan2(hs[n0], s[n0]) * 180 / pi
print("worked instant t = %.3f us: s %.6f V, Hs %.6f V, envelope %.6f V, A %.6f V, phase %.3f deg"
      % (t[n0] * 1e6, s[n0], hs[n0], env[n0], A[n0], ph))
print("by hand: message angle %.3f deg, cos %.6f, carrier angle %.3f deg"
      % (360 * FM * t[n0], cos(2 * pi * FM * t[n0]), (360 * FC * t[n0]) % 360))
assert abs(env[n0] - A[n0]) < 1e-9 and abs(ph - 45) < 1e-6
def inst_freq(s, hs):                        # phase step per sample, in kHz
    z = [complex(a, b) for a, b in zip(s, hs)]
    return [atan2((z[k + 1] * z[k].conjugate()).imag, (z[k + 1] * z[k].conjugate()).real) / (2 * pi) * FS / 1e3
            for k in range(len(z) - 1)]
fr = inst_freq(s, hs)
print("instantaneous frequency: %.3f kHz to %.3f kHz" % (min(fr), max(fr)))
assert abs(min(fr) - 1000) < 1e-6 and abs(max(fr) - 1000) < 1e-6
print("chart t us: [" + ", ".join("%.3f" % (t[401 * k] * 1e6) for k in range(20)) + "]")
z0 = lambda v: 0.0 if abs(v) < 5e-7 else v     # no "-0.000" from rounding noise
print("chart s V: [" + ", ".join("%.3f" % z0(s[401 * k]) for k in range(20)) + "]")
print("chart envelope V: [" + ", ".join("%.3f" % env[401 * k] for k in range(20)) + "]")
print("chart -envelope V: [" + ", ".join("%.3f" % -env[401 * k] for k in range(20)) + "]")

# What breaks.
print("mistake, s + Hs at the worked instant: %.6f V; |s| one sample later: %.6f V"
      % (abs(s[n0] + hs[n0]), abs(s[n0 + 1])))
print("mistake, sign flipped: frequency %.3f kHz" % min(inst_freq(s, hilbert(s, -1))))
t2, A2, s2 = am(0.5, FC, FM, 10000)          # 1.25 ms: 1.25 tone cycles, the loop has a seam
e2 = [sqrt(a * a + b * b) for a, b in zip(s2, hilbert(s2))]
g_all = max(abs(e - a) for e, a in zip(e2, A2))
g_mid = max(abs(e2[k] - A2[k]) for k in range(2000, 8001))
print("record 1.25 ms: largest envelope gap %.6f V; between 0.25 and 1 ms %.6f V" % (g_all, g_mid))
assert g_all > 0.01 and g_mid < g_all / 5
t3, A3, s3 = am(1.5, FC, FM, 8000)
e3 = [sqrt(a * a + b * b) for a, b in zip(s3, hilbert(s3))]
print("depth 1.5 at t = 500 us: message %.6f V, envelope %.6f V" % (A3[4000], e3[4000]))
assert abs(e3[4000] - abs(A3[4000])) < 1e-9
t4, A4, s4 = am(0.5, 1e3, 2e3, 8000)         # carrier below the tone: Bedrosian fails
e4 = [sqrt(a * a + b * b) for a, b in zip(s4, hilbert(s4))]
g4 = max(abs(e - a) for e, a in zip(e4, A4))
print("1 kHz carrier, 2 kHz tone: largest envelope gap %.6f V" % g4)
assert g4 > 0.1

# The 1 ms gate (the shutter): Hf = (1/pi) ln|(t + 1/2)/(t - 1/2)|, t in ms; tail T/(pi t).
Hg = lambda x: log(abs((x + 0.5) / (x - 0.5))) / pi
F = lambda x: ((x + 0.5) * log(x + 0.5) - (x - 0.5) * log(x - 0.5)) / pi
for x in [1, 10, 100]:
    print("gate Hf(%d ms) = %.6f, tail 1/(pi t) = %.6f" % (x, Hg(x), 1 / (pi * x)))
num = midpoint(Hg, 1, 10, 90000)
print("area of |Hf| from 1 to 10 ms: antiderivative %.6f ms, integral %.6f ms" % (F(10) - F(1), num))
assert abs(num - (F(10) - F(1))) < 1e-8
for R in [100, 1000, 10000]:
    print("area of |Hf| from 1 to %d ms: %.6f ms" % (R, F(R) - F(1)))
print("growth per decade, (1/pi) ln 10 = %.6f ms" % (log(10) / pi))
print("ALL CHECKS PASS")
