# Complex steps and dual numbers -- the check behind the card.  Python standard
# library only; fractions gives the exact answer, used only inside an assert.
# Road one: the exact slope -(F/y)(1 - 1.05^-30) and a term-by-term sum.
# Road two: the complex step Im P(y + ih) / h at many steps h.  Road three: a
# dual number carried through the same pricing code.  For contrast: the central
# difference.  Each number type counts its real operations (flops).
import math
from fractions import Fraction
OPS = [0]
def tick(n): OPS[0] += n
def sci(x, d=2):                                # 1.23e-5, the same in Rust
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"
class R:                                        # a plain real number, counted
    def __init__(s, a): s.a = a
    def addc(s, k): tick(1); return R(s.a + k)
    def add(s, o): tick(1); return R(s.a + o.a)
    def mul(s, o): tick(1); return R(s.a * o.a)
    def scal(s, k): tick(1); return R(k * s.a)
    def recip(s): tick(1); return R(1.0 / s.a)
    def mag(s): return R(abs(s.a))
class Cx:                                       # a + b i, i * i = -1, written out
    def __init__(s, a, b): s.a, s.b = a, b
    def addc(s, k): tick(1); return Cx(s.a + k, s.b)
    def add(s, o): tick(2); return Cx(s.a + o.a, s.b + o.b)
    def mul(s, o): tick(6); return Cx(s.a * o.a - s.b * o.b, s.a * o.b + s.b * o.a)
    def scal(s, k): tick(2); return Cx(k * s.a, k * s.b)
    def recip(s):
        tick(5); den = s.a * s.a + s.b * s.b
        return Cx(s.a / den, -s.b / den)
    def mag(s): return Cx(math.sqrt(s.a * s.a + s.b * s.b), 0.0)   # abs() of a complex
class Dual:                                     # a + b eps, eps * eps = 0
    def __init__(s, a, b): s.a, s.b = a, b
    def addc(s, k): tick(1); return Dual(s.a + k, s.b)
    def add(s, o): tick(2); return Dual(s.a + o.a, s.b + o.b)
    def mul(s, o): tick(4); return Dual(s.a * o.a, s.a * o.b + s.b * o.a)
    def scal(s, k): tick(2); return Dual(k * s.a, k * s.b)
    def recip(s):
        tick(3); r = 1.0 / s.a
        return Dual(r, -s.b * r * r)
    def mag(s): return Dual(abs(s.a), s.b if s.a >= 0.0 else -s.b)
C, F, N, Y = 5.0, 100.0, 30, 0.05               # 5% annual coupon, $100 face, 30 years, 5% yield
EX = -1537.2451026882836                        # exact dP/dy, rounded once (asserted below)
def legs(y, guard=False):                       # ONE pricing routine for every number type
    if guard: y = y.mag()                       # "a negative yield is a typo": take abs
    v = y.addc(1.0).recip()                     # one year's discount factor 1/(1+y)
    d = v; s = d.scal(C)
    for _ in range(N - 1):
        d = d.mul(v); s = s.add(d.scal(C))      # coupon t is worth C v^t today
    return v, d, s                              # v, v^30, the coupons' value
def price(y, guard=False):
    v, d, s = legs(y, guard)
    return s.add(d.scal(F))                     # plus the face value in year 30
def cs(h, y=Y): return price(Cx(y, h)).b / h    # the complex step
def cd(h): return (price(R(Y + h)).a - price(R(Y - h)).a) / (2 * h)
def rel(x): return (x - EX) / EX
g = 1.0
for _ in range(N): g *= 1.0 + Y                 # road one: 1.05^30, then the closed form
cf = -(F / Y) * (1.0 - 1.0 / g)
d1 = d2 = d3 = 0.0; v = 1.0 / (1.0 + Y); vt = 1.0
for t in range(1, N + 1):                       # road one again: term by term
    vt *= v; c = C + (F if t == N else 0.0)
    d1 -= c * t * vt * v; d2 += c * t * (t + 1) * vt * v * v; d3 -= c * t * (t + 1) * (t + 2) * vt * v * v * v
p0 = price(R(Y)).a; p1 = price(R(Y + 1e-4)).a; K = d3 / (6 * EX)
print(f"bond: price at 5% = {p0:.12f}; 1.05^30 = {g:.12f}; u = 2^-53 = {sci(2.0 ** -53)}")
print(f"exact dP/dy {EX:.10f}; closed form in doubles rel err {sci(rel(cf))}, term by term {sci(rel(d1))}")
print(f"d2P/dy2 = {d2:.6f}, d3P/dy3 = {d3:.6f}; complex-step law: rel err = -{K:.6f} h^2")
print(f"1bp bump: P(5.01%) = {p1:.12f}, change {p1 - p0:.12f}; true DV01 {-EX * 1e-4:.12f}")
print("k   complex step      rel err     central difference  rel err")
er, ec, lc, ld = {}, {}, [], []
for k in list(range(1, 17)) + [20, 100, 300]:
    h = float(f"1e-{k}"); a = cs(h); er[k] = rel(a)
    tail = ""
    if k <= 16:
        ec[k] = rel(cd(h)); tail = f"{cd(h):18.9f}  {sci(ec[k]):>9}"
        lc.append(f"{math.log10(abs(er[k])):.2f}"); ld.append(f"{math.log10(abs(ec[k])):.2f}")
    print(f"{k:<3} {a:16.9f}  {sci(er[k]):>9}  {tail}".rstrip())
print("chart complex step log10 |rel err|: " + ", ".join(lc))
print("chart central log10 |rel err|: " + ", ".join(ld))
print("complex step: order from k to k+1 (theory 2): " + ", ".join(f"{math.log10(er[k] / er[k + 1]):.4f}" for k in range(2, 6))
      + f"; law at h=1e-3 {sci(-K * 1e-6)}")
OPS[0] = 0; du = price(Dual(Y, 1.0)); n_du = OPS[0]
OPS[0] = 0; p_r = price(R(Y)); n_r = OPS[0]
OPS[0] = 0; c20 = price(Cx(Y, 1e-20)); n_cx = OPS[0]
print(f"dual: P(5% + eps) = {du.a:.12f} + ({du.b:.10f}) eps, rel err {sci(rel(du.b))}")
print(f"complex at h=1e-20: real {c20.a:.12f}, imag {sci(c20.b, 9)}; imag/h minus dual {sci(c20.b / 1e-20 - du.b)}")
v, d, s = legs(Dual(Y, 1.0))
print(f"by hand (dual): v = {v.a:.12f} + ({v.b:.12f}) eps; v^30 = {d.a:.12f} + ({d.b:.9f}) eps")
print(f"by hand (dual): coupons {s.a:.9f} + ({s.b:.9f}) eps; face 100 v^30 = {F * d.a:.9f} + ({F * d.b:.9f}) eps")
print(f"flops: one price {n_r}, central difference {2 * n_r + 2}, complex step {n_cx + 1}, dual {n_du}")
gc = price(Cx(Y, 1e-20), True).b / 1e-20 + 0.0      # the abs() guard left in the code
gd = price(Dual(Y, 1.0), True)
sr = 2 * (p0 - price(Cx(Y, 1e-20)).a) / 1e-40; s4 = 2 * (p0 - price(Cx(Y, 1e-4)).a) / 1e-8
print(f"break, abs() guard: complex step {gc:.9f}, dual {gd.b:.9f}")
print(f"break, 2nd derivative from the real part: h=1e-20 {sci(sr)}, h=1e-4 {s4:.6f} (exact {d2:.6f})")
avg = (cs(1e-2) + cd(1e-2)) / 2
s320 = cs(float("1e-320"))
print(f"try: mean of complex step and central at h=1e-2 {avg:.9f}, rel err {sci(rel(avg))}")
print(f"try: h=1e-320 (subnormal) gives {s320:.9f}, rel err {sci(rel(s320))}; seed 1e-4: {price(Dual(Y, 1e-4)).b:.12f}")
assert abs(Fraction(EX) - (-2000) * (1 - Fraction(20, 21) ** 30)) < Fraction(1, 2 ** 43)
assert abs(rel(cf)) < 1e-14 and abs(rel(d1)) < 1e-14       # two roads to the exact slope
assert abs(er[20]) < 4e-15 and abs(rel(du.b)) < 4e-15        # complex step and dual: full accuracy
assert min(abs(e) for e in ec.values()) > 1e-11              # the best central difference is 1000x worse
assert abs(er[3] / (-K * 1e-6) - 1) < 1e-3                   # error follows -h^2 f'''/(6 f')
assert abs(er[3] + ec[3]) < 1e-3 * abs(er[3])                # equal size, opposite sign
assert gc == 0.0 and abs(rel(gd.b)) < 4e-15                  # abs() kills the complex step, not the dual
assert abs((complex(1 + Y, 1e-20) ** -30).imag / 1e-20 + 30 * 1.05 ** -31) < 1e-9   # library cross-check
print("ALL CHECKS PASS")
