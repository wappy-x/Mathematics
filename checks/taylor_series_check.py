# Taylor series -- the check behind the card.  Standard library only.
# Road one: partial sums T_n(x), built term by term here.  Road two: the
# closed form (math.exp, sin, cos, log).  Road three: the remainder bound
# from Taylor's theorem, which must cover the gap between the first two.
import math

def taylor(pattern, x, n):               # exp, sin, cos: sign pattern times x^k/k!
    total, p = 0.0, 1.0
    for k in range(n + 1):
        total += pattern[k % 4] * p
        p = p * x / (k + 1)
    return total

def ln_taylor(x, n):                     # ln(1 + x) = x - x^2/2 + x^3/3 - ...
    total, p = 0.0, 1.0
    for k in range(1, n + 1):
        p *= x
        total += (1 if k % 2 else -1) * p / k
    return total

def bound(x, n, top):                    # top * |x|^(n+1) / (n+1)!
    b = top
    for j in range(1, n + 2):
        b = b * abs(x) / j
    return b

g = lambda x: 0.0 if x == 0 else math.exp(-1 / (x * x))   # the smooth impostor
sci = lambda v: f"{v:.3e}"
EXP, SIN, COS = (1, 1, 1, 1), (0, 1, 0, -1), (1, 0, -1, 0)

rows = []
for n in (2, 5, 10, 15, 20):
    t = taylor(EXP, 2.0, n)
    rows.append((abs(math.exp(2) - t), bound(2, n, 9)))
    print(f"exp(2), n = {n:2d}: T_n = {t:.10f}, error {sci(rows[-1][0])}, bound {sci(rows[-1][1])}")
need = next(n for n in range(50) if bound(2, n, 9) < 0.001)
print(f"exp(2) = {math.exp(2):.10f}; first n with bound under 0.001: {need} (bound {sci(bound(2, need, 9))})")
es = abs(taylor(SIN, 2.0, 19) - math.sin(2)); ec = abs(taylor(COS, 2.0, 18) - math.cos(2))
print(f"sin(2), n = 19: error {sci(es)}, bound {sci(bound(2, 19, 1))}")
print(f"cos(2), n = 18: error {sci(ec)}, bound {sci(bound(2, 18, 1))}")
el = abs(ln_taylor(0.5, 20) - math.log(1.5)); bl = 0.5 ** 21 / (21 * 0.5)
print(f"ln(1.5), n = 20: error {sci(el)}, bound {sci(bl)}")
e2 = abs(ln_taylor(1.0, 1000) - math.log(2))
print(f"ln(2), n = 1000: error {sci(e2)}, bound {sci(1 / 1001)}")
far = [ln_taylor(1.5, n) for n in (10, 20, 40)]
print(f"ln(2.5) = {math.log(2.5):.4f}, but T_10, T_20, T_40 at x = 1.5: {far[0]:.1f}, {far[1]:.1f}, {far[2]:.1f}")
print(f"impostor g(0.5) = {g(0.5):.10f}; every T_n(0.5) = 0, so the error stays {g(0.5):.10f}")
hs = (0.2, 0.1, 0.05)
print("g(h)/h at h = 0.2, 0.1, 0.05: " + ", ".join(sci(g(h) / h) for h in hs))
q10 = [g(h) / h ** 10 for h in hs]
print("g(h)/h^10 at h = 0.2, 0.1, 0.05: " + ", ".join(sci(v) for v in q10))
print(f"second difference at 0, h = 0.1: {sci((g(0.1) - 2 * g(0) + g(-0.1)) / 0.01)}")
print("chart, g(x) at x = 0, 0.25, ..., 2: " + " ".join(f"{g(i / 4):.2f}" for i in range(9)))
print(f"mistake, factorials dropped: 1 + 2 + 4 + ... + 2^20 = {sum(2 ** k for k in range(21))}")
assert all(err <= b for err, b in rows) and rows[-1][0] < 1e-12       # roads one, two, three agree
assert es <= bound(2, 19, 1) and ec <= bound(2, 18, 1) and el <= bl and e2 <= 1 / 1001
assert abs(far[2]) > 1000 * abs(math.log(2.5))                          # beyond radius 1: no convergence
assert g(0.5) > 0.018 and q10[0] > q10[1] > q10[2] and q10[2] < 1e-150  # flat to every order, yet not zero
print("ALL CHECKS PASS")
