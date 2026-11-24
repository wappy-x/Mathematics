# Jensen's formula and order of growth -- the check behind the card.  Standard
# library only.  Road one: the circle average of ln|f|, summed at N points.
# Road two: ln|f(0)| plus ln(R/|a|) for each known zero a, their number checked
# by the argument principle.  Then the order of sin z and e^(z^2), and the zero bound.
import math
N = 4096
def circ(r, n, k): t = 2 * math.pi * k / n; return r * math.cos(t), r * math.sin(t)
def avg(lnf, r, n=N): return sum(lnf(*circ(r, n, k)) for k in range(n)) / n
def lnsin(x, y):            # ln|sin z| = ln sqrt(sin^2 x + sinh^2 y), written so e^|y| cannot overflow
    e = math.exp(-2 * abs(y)); return abs(y) + 0.5 * math.log(math.sin(x) ** 2 * e + ((1 - e) / 2) ** 2)
def lnsinc(x, y): return lnsin(x, y) - 0.5 * math.log(x * x + y * y)           # ln|sin z / z|
def lnlin(x, y): return 0.5 * math.log((x - 0.5) ** 2 + y * y)                # ln|z - 1/2|
def winding(r, n):          # turns of sin z round |z| = r: arg = atan2(cos x tanh y, sin x)
    tot, prev = 0.0, None
    for k in range(n + 1):
        x, y = circ(r, n, k)
        a = math.atan2(math.cos(x) * math.tanh(y), math.sin(x))
        if prev is not None: tot += (a - prev + math.pi) % (2 * math.pi) - math.pi
        prev = a
    return round(tot / (2 * math.pi))
def zeros(r): return winding(r, 64 * int(r) + 256) - 1      # zeros of sin z / z: drop the one at 0
def lnM(r, g=lnsin, n=3600): return max(g(*circ(r, n, k)) for k in range(n))   # ln of max |g| on |z| = r
def f6(v): return f"{0.0 if abs(v) < 5e-7 else v:.6f}"
print("chart, ln|e^(it) - 1/2| at t = 0, 30, ..., 360 degrees:",
      " ".join(f"{lnlin(*circ(1, 12, k)):.3f}" for k in range(13)))
a1, ln2 = avg(lnlin, 1), math.log(2)
print(f"z - 1/2 on |z| = 1: circle average {f6(a1)}; ln|f(0)| = {f6(math.log(0.5))}; correction ln 2 = {f6(ln2)}")
R, n10 = 10.0, zeros(10)
terms = [math.log(R / (k * math.pi)) for k in range(1, 4)]
a10, j10 = avg(lnsinc, R), 0.0 + 2 * sum(terms)               # ln|f(0)| = ln 1 = 0
print(f"sin z / z on |z| = 10: zeros inside by the argument principle {n10}, at +-pi, +-2pi, +-3pi")
print("  ln(10/pi), ln(10/2pi), ln(10/3pi) = " + ", ".join(f6(v) for v in terms))
print(f"  circle average {f6(a10)}; Jensen: 0 + 2 x their sum = {f6(j10)}")
rs = [10, 100, 1000]
osin = [math.log(lnM(r)) / math.log(r) for r in rs]
oexp = [math.log(lnM(r, lambda x, y: x * x - y * y)) / math.log(r) for r in rs]   # ln|e^(z^2)| = x^2 - y^2
print("order estimate ln ln M(r) / ln r at r = 10, 100, 1000: sin z " + " ".join(f"{v:.4f}" for v in osin)
      + "; e^(z^2) " + " ".join(f"{v:.4f}" for v in oexp))
print(f"  ln M(10) by sampling {f6(lnM(10))}; ln sinh 10 = {f6(math.log(math.sinh(10)))}")
big = [zeros(r) + 1 for r in (100, 1000)]
print(f"zeros of sin z in |z| < 100 and 1000: {big[0]} and {big[1]}; 2r/pi = {200 / math.pi:.2f} and {2000 / math.pi:.2f}")
radii = [10, 20, 30, 40, 50]
cnt = [zeros(r) for r in radii]
bnd = [(lnM(2 * r) - math.log(2 * r)) / ln2 for r in radii]   # (ln M(2r) - ln|f(0)|) / ln 2, f(0) = 1
print("chart, zeros of sin z / z in |z| < r, r = 10..50:", " ".join(map(str, cnt)))
print("chart, Jensen bound (ln M(2r) - ln|f(0)|) / ln 2:", " ".join(f"{v:.1f}" for v in bnd))
sq, inv = avg(lambda x, y: 2 * lnlin(x, y), 1), avg(lambda x, y: -lnlin(x, y), 1)
print(f"mistake 1, no correction: Jensen would give ln|f(0)| = {f6(-ln2)}, the circle gives {f6(a1)}")
print(f"mistake 2, (z - 1/2)^2 counted once: {f6(2 * -ln2 + ln2)}; circle {f6(sq)}; counted twice {f6(2 * -ln2 + 2 * ln2)}")
print(f"mistake 3, pole of 1/(z - 1/2) added like a zero: {f6(ln2 + ln2)}; circle {f6(inv)}; subtracted {f6(ln2 - ln2)}")
print(f"mistake 4, size on the real line only: largest |sin x| for -100 <= x <= 100 is "
      f"{max(abs(math.sin(x / 100)) for x in range(-10000, 10001)):.6f}, yet {big[0]} zeros in |z| < 100")
assert abs(a1 - (lnlin(0, 0) + math.log(1 / 0.5))) < 1e-9 and abs(a10 - j10) < 1e-9   # two roads agree
assert n10 == 6 and cnt == [2 * int(r / math.pi) for r in radii] and big == [63, 637]
assert all(c <= b and abs(b - (math.log(math.sinh(2 * r) / (2 * r))) / ln2) < 1e-9 for c, b, r in zip(cnt, bnd, radii))
assert abs(lnM(10) - math.log(math.sinh(10))) < 1e-9
assert abs(osin[2] - 1) < 0.001 and abs(oexp[0] - 2) < 1e-9 and abs(sq) < 1e-9 and abs(inv) < 1e-9
print("ALL CHECKS PASS")
