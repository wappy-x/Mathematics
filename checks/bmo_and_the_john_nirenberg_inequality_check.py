# BMO and the John-Nirenberg inequality -- the check behind the card.  Standard library only.
# f(t) = ln|t|, and the partner of a 1 V gate open from t = 0 to t = 1 s:
# Hg(t) = (1/pi) ln|t/(t - 1)| volts.  Every mean oscillation is found two ways:
# exactly, from an antiderivative split where f crosses its mean, and by the midpoint rule.
from math import log, exp, pi, e, sqrt

xl = lambda t: t * log(abs(t)) if t != 0 else 0.0
LOG = (lambda t: log(abs(t)), lambda t: xl(t) - t, lambda m: [exp(m), -exp(m)])
def partner(p, q):                            # (1/pi) ln|(t-p)/(t-q)|: H of a 1 V gate on [p, q]
    def roots(m):
        r = exp(pi * m)
        return [(p + r * q) / (1 + r)] + ([(p - r * q) / (1 - r)] if abs(r - 1) > 1e-12 else [])
    return (lambda t: log(abs((t - p) / (t - q))) / pi, lambda t: (xl(t - p) - xl(t - q)) / pi, roots)
HG = partner(0.0, 1.0)

def osc(fn, a, b, m=None):                    # (mean on [a,b], average of |f - m|), exactly
    h, F, roots = fn
    mean = (F(b) - F(a)) / (b - a)
    m = mean if m is None else m
    pts = [a] + sorted(t for t in roots(m) if a < t < b) + [b]
    s = 0.0
    for p, q in zip(pts, pts[1:]):
        sg = 1 if h(p + 0.37 * (q - p)) > m else -1
        s += sg * (F(q) - F(p) - m * (q - p))
    return mean, s / (b - a)
def mid(f, a, b, n):
    w = (b - a) / n
    return w * sum(f(a + (k + 0.5) * w) for k in range(n))
def golden(f, lo, hi):
    g = (sqrt(5) - 1) / 2
    for _ in range(120):
        x1, x2 = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(x1) > f(x2): hi = x2
        else: lo = x1
    return (lo + hi) / 2

# 1. ln|t| on [0, 1]: mean -1, mean oscillation 2/e; the same on [0, a] and [-a, a].
m01, o01 = osc(LOG, 0.0, 1.0)
o_mid = mid(lambda v: 3 * v * v * abs(3 * log(v) + 1), 0, 1, 200000)   # t = v^3 tames the log
print("ln|t| on [0,1]: mean %.6f; mean oscillation exact %.6f, midpoint %.6f, 2/e = %.6f" % (m01, o01, o_mid, 2 / e))
assert abs(m01 + 1) < 1e-12 and abs(o01 - 2 / e) < 1e-12 and abs(o_mid - 2 / e) < 1e-6
for lab, a in [("0.001", 0.001), ("1000", 1000.0)]:
    print("ln|t| on [0,%s]: mean %.6f, mean oscillation %.6f; on [-%s,%s]: %.6f"
          % (lab, osc(LOG, 0, a)[0], osc(LOG, 0, a)[1], lab, lab, osc(LOG, -a, a)[1]))
    assert abs(osc(LOG, 0, a)[1] - 2 / e) < 1e-9 and abs(osc(LOG, -a, a)[1] - 2 / e) < 1e-9
# 2. Its BMO norm: by scaling and mirroring, every interval is some [u, 1] with -1 <= u < 1.
grid = max(osc(LOG, -1 + k / 1000, 1.0)[1] for k in range(2000))
u = golden(lambda u: osc(LOG, u, 1.0)[1], -0.5, 0.0)
B = osc(LOG, u, 1.0)[1]
c = mid(lambda v: 3 * v * v * abs(3 * log(v) - osc(LOG, u, 1)[0]), 0, 1, 200000)
c += mid(lambda v: 3 * v * v * abs(3 * log(v) - osc(LOG, u, 1)[0]), 0, (-u) ** (1 / 3), 200000)
print("BMO norm of ln|t|: largest at [%.5f, 1], mean %.6f, oscillation %.6f; midpoint %.6f; grid of 2000 %.6f"
      % (u, osc(LOG, u, 1)[0], B, c / (1 - u), grid))
assert grid <= B + 1e-12 and B - grid < 1e-5 and abs(c / (1 - u) - B) < 1e-6 and B > 2 / e

# 3. The gate g has BMO norm 1/2; its partner Hg is unbounded but has a finite BMO norm.
gate = lambda t: 1.0 if 0 < t < 1 else 0.0
gm = mid(gate, -1, 1, 20000) / 2
go = mid(lambda t: abs(gate(t) - gm), -1, 1, 20000) / 2
gbest = max(2 * th * (1 - th) for th in [k / 1000 for k in range(1001)])   # share th of I inside the gate
print("gate g: on [-1,1] mean %.6f, mean oscillation %.6f; over all intervals 2 th (1 - th) peaks at %.6f" % (gm, go, gbest))
assert abs(go - 0.5) < 1e-9 and abs(gbest - go) < 1e-12
print("Hg at 0.001 s past the edge: %.3f V; at 0.000001 s: %.3f V" % (HG[0](1.001), HG[0](1.000001)))
mH, oH = osc(HG, 0.0, 1.0)
oH_mid = 2 * mid(lambda v: 3 * v * v * abs(HG[0](v ** 3)), 0, 0.5 ** (1 / 3), 200000)
print("Hg on [0,1]: mean %.6f; mean oscillation exact %.6f, midpoint %.6f, (2/pi) ln 2 = %.6f" % (mH, oH, oH_mid, 2 * log(2) / pi))
assert abs(mH) < 1e-12 and abs(oH - 2 * log(2) / pi) < 1e-12 and abs(oH_mid - oH) < 1e-6
s = golden(lambda s: osc(HG, 0.5 - s, 0.5 + s)[1], 0.3, 1.5)
BH = osc(HG, 0.5 - s, 0.5 + s)[1]
gridH = max(osc(HG, -2 + 0.02 * i, -2 + 0.02 * j)[1] for i in range(250) for j in range(i + 1, 251))
print("BMO norm of Hg: largest at [%.4f, %.4f], half-width %.6f, oscillation %.6f V; grid of 31375 intervals %.6f V"
      % (0.5 - s, 0.5 + s, s, BH, gridH))
assert gridH <= BH + 1e-9 and BH - gridH < 1e-3

# 4. Singular integrals map L-infinity into BMO: ||Hf||_BMO <= 2 (sqrt 2 + ln(3)/pi) ||f||_inf.
hor = mid(lambda s: 1 / (pi * (2 * exp(s) - 1)) + 1 / (pi * (2 * exp(s) + 1)), 0, 30, 300000)  # t = +-2e^s
print("smoothness constant, integral of |K(t-1) - K(t)| over |t| > 2: %.6f, ln(3)/pi = %.6f" % (hor, log(3) / pi))
assert abs(log(3) / pi - hor) < 1e-9
C = 2 * (sqrt(2) + log(3) / pi)
print("bound: 2 x (sqrt 2 + ln(3)/pi) = 2 x (%.6f + %.6f) = %.6f; Hg uses %.6f of it, ratio %.6f" % (sqrt(2), log(3) / pi, C, BH, BH / C))
near, far = partner(0.5, 1.0), partner(0.0, 0.5)   # I = [0.75, 1.25], centre 1, doubled I = [0.5, 1.5]
n1 = osc(near, 0.75, 1.25, 0.0)[1]
n2 = max(abs(far[0](0.75 + k / 10000) - far[0](1.0)) for k in range(5001))
mI, oI = osc(HG, 0.75, 1.25)
oI_mid = sum(mid(lambda v: 3 * v * v * abs(log(abs(1 + 1 / (sg * v ** 3))) / pi - mI), 0, 0.25 ** (1 / 3), 100000) for sg in (1, -1)) / 0.5
print("I = [0.75,1.25]: near part average |Hf1| %.6f <= sqrt 2; far part |Hf2 - Hf2(1)| at most %.6f <= ln(3)/pi;"
      " so MO <= 2 x %.6f = %.6f; true MO %.6f, midpoint %.6f" % (n1, n2, n1 + n2, 2 * (n1 + n2), oI, oI_mid))
assert n1 <= sqrt(2) and n2 <= log(3) / pi and oI <= 2 * (n1 + n2) and abs(oI - oI_mid) < 1e-6

# 5. John-Nirenberg: share of I where |f - f_I| > lam is at most e exp(-lam / (2e ||f||_BMO)).
N = 1000000
JN = lambda lam, b: e * exp(-lam / (2 * e * b))
tlog = lambda lam: exp(-1 - lam) + max(0.0, 1 - exp(lam - 1))
for lam in [1, 2, 4, 8]:
    cnt = sum(1 for k in range(N) if abs(log((k + 0.5) / N) + 1) > lam) / N
    print("ln|t|, I = [0,1], lam = %d: share exact %.6f, grid %.6f; bound %.6f; bound/true %.1f"
          % (lam, tlog(lam), cnt, JN(lam, B), JN(lam, B) / tlog(lam)))
    assert abs(cnt - tlog(lam)) < 2e-6 and tlog(lam) <= JN(lam, B)
for lam in [0.5, 1.0, 2.0]:
    cnt = sum(1 for k in range(N) if abs(HG[0]((k + 0.5) / N)) > lam) / N
    ex = 2 / (1 + exp(pi * lam))
    print("Hg, I = [0,1], lam = %.1f V: share exact %.6f, grid %.6f; bound %.6f" % (lam, ex, cnt, JN(lam, BH)))
    assert abs(cnt - ex) < 2e-6 and ex <= JN(lam, BH)
al = e * B                                    # the stopping level of the proof, alpha = e ||f||_BMO
avg16, avg8 = osc(LOG, 0, 1 / 16, -1.0)[1], osc(LOG, 0, 1 / 8, -1.0)[1]   # averages of |ln t + 1|
print("stopping level alpha = e x ||f||_BMO = %.6f x %.6f = %.6f; [0,1/8] averages %.6f (go on), [0,1/16] averages %.6f (stop), <= 2 alpha = %.6f"
      % (e, B, al, avg8, avg16, 2 * al))
assert avg8 <= al < avg16 <= 2 * al and 1 / 16 <= 1 / al
for k in [1, 2, 3]:
    print("generation %d: box [0, 16^-%d] of length %.8f; its mean differs from f_I by %.6f; beyond lam = %.6f the share is at most %.8f"
          % (k, k, 16.0 ** -k, osc(LOG, 0, 16.0 ** -k)[0] + 1, k * 2 * al, 16.0 ** -k))
    assert tlog(k * 2 * al) <= 16.0 ** -k
beta = 0.5                                    # the rate of Step 6
ei = exp(-1) / (1 - beta) + (exp(beta) - exp(-1)) / (1 + beta)
ei_mid = mid(lambda v: 4 * v ** 3 * exp(beta * abs(4 * log(v) + 1)), 0, 1, 200000)
print("average of exp(beta |ln t + 1|) on [0,1], beta = %.1f: exact %.6f, midpoint %.6f; finite exactly when beta is below 1" % (beta, ei, ei_mid))
assert abs(ei - ei_mid) < 1e-6

# 6. What breaks: no single interval decides; a bounded factor; units.
for lab, a in [("1", 1.0), ("0.01", 0.01), ("0.000001", 0.000001)]:
    sq_mo = 2 * mid(lambda v: 2 * v * abs(1 / v - 2 / sqrt(a)), 0, (a / 4) ** 0.5, 20000) / a   # t = v^2
    sl = mid(lambda v: 3 * v * v * abs(3 * log(v)), 0, a ** (1 / 3), 20000) / a
    print("on [0,%s]: t^(-1/2) mean oscillation %.6f; on [-%s,%s]: sgn(t) ln|t| mean oscillation %.6f, 1 - ln a = %.6f"
          % (lab, sq_mo, lab, lab, sl, 1 - log(a)))
    assert abs(sq_mo - 1 / sqrt(a)) < 1e-6 * sq_mo and abs(sl - (1 - log(a))) < 1e-4
for lam in [8, 98]:
    print("I = [0,1], lam = %d: t^(-1/2) share 1/(2+lam)^2 = %.6f; ln|t| share 10^%.2f" % (lam, 1 / (2 + lam) ** 2, log(tlog(lam), 10)))
print("I = [0,1], lam = 5: 10 ln|t| share %.6f; ln|t| share %.6f" % (tlog(0.5), tlog(5)))

# 7. Chart points.
ts = [-0.95 + 0.1 * k for k in range(30)]
print("chart t s: [" + ", ".join("%.2f" % t for t in ts) + "]")
print("chart g V: [" + ", ".join("%.0f" % (1 if 0 < t < 1 else 0) for t in ts) + "]")
print("chart Hg V: [" + ", ".join("%.3f" % HG[0](t) for t in ts) + "]")
ls = list(range(0, 17, 2))
sq = lambda lam: 1 / (2 + lam) ** 2 + max(0.0, 1 - 1 / (2 - lam) ** 2) if lam < 1 else 1 / (2 + lam) ** 2
print("chart log10 share ln|t|: [" + ", ".join("%.2f" % log(tlog(x), 10) for x in ls) + "]")
print("chart log10 bound ln|t|: [" + ", ".join("%.2f" % log(min(1, JN(x, B)), 10) for x in ls) + "]")
print("chart log10 share t^(-1/2): [" + ", ".join("%.2f" % log(sq(x), 10) for x in ls) + "]")
print("ALL CHECKS PASS")
