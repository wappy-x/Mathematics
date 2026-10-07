# The keyhole contour -- the check behind the card.  Standard library only.
# Road one: the real integral of x^(a-1)/(1+x), summed after x = e^u.
# Road two: a trapezoid sum round the keyhole, against 2 pi i times the residue at -1.
# The branch of z^(a-1) is built by hand, argument in [0, 2 pi]: no library power of z.
import math

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def e(t): return complex(math.cos(t), math.sin(t))              # e^(it)
def power(rho, th, a): return rho ** (a - 1) * e((a - 1) * th)  # z^(a-1) at z = rho e^(i th)
def trap(g, lo, hi, n):                       # trapezoid sum of g from lo to hi, n steps
    h = (hi - lo) / n
    return h * (sum(g(lo + j * h) for j in range(1, n)) + (g(lo) + g(hi)) / 2)
def real_road(a):                             # x = e^u, dx = e^u du, u from -80 to 80
    return trap(lambda u: math.exp(a * u) / (1 + math.exp(u)), -80, 80, 4000)
def bank(a, th, r, R, n):                     # z = x e^(i th) on a bank, x from r to R, via x = e^u
    return trap(lambda u: power(math.exp(u), th, a) * math.exp(u) / (1 + math.exp(u)), math.log(r), math.log(R), n)
def circle(a, rho, t0, t1, n=4000):           # z = rho e^(it), dz = i z dt, t from t0 to t1
    return trap(lambda t: power(rho, t, a) * 1j * rho * e(t) / (1 + rho * e(t)), t0, t1, n)
def keyhole(a, r, R, n=4000, low=2 * math.pi):   # out along the top bank, round, in along the bottom, back round 0
    return (bank(a, 0, r, R, n), -bank(a, low, r, R, n), circle(a, R, 0, 2 * math.pi, n), circle(a, r, 2 * math.pi, 0, n))
res = lambda a: power(1, math.pi, a)          # (z + 1) F(z) = z^(a-1), at z = -1 = e^(i pi)
solve = lambda a: 2j * math.pi * res(a) / (1 - e(2 * math.pi * a))

for a in (0.25, 0.5, 0.75):
    print(f"a = {a:.2f}: pi/sin(pi a) = {math.pi / math.sin(math.pi * a):.6f}; real line, x = e^u: {real_road(a):.6f}; residue route: {show(solve(a))}")
    assert abs(real_road(a) - math.pi / math.sin(math.pi * a)) < 1e-8 and abs(solve(a) - real_road(a)) < 1e-8
print(f"a = 0.50: residue at -1 {show(res(0.5))}; bottom-bank factor e^(2 pi i a) {show(e(math.pi))}")
p = keyhole(0.5, 0.5, 4)
print(f"keyhole a = 0.50, r = 0.5, R = 4: top bank {show(p[0])}; bottom bank {show(p[1])}")
print(f"  big circle {show(p[2])}; small circle {show(p[3])}")
print(f"  four pieces {show(sum(p))}; 2 pi i x residue {show(2j * math.pi * res(0.5))}")
q = keyhole(0.25, 0.5, 4)
print(f"keyhole a = 0.25: four pieces {show(sum(q))}; 2 pi i x residue {show(2j * math.pi * res(0.25))}")
errs = [abs(sum(keyhole(0.5, 0.5, 4, n)) - 2j * math.pi * res(0.5)) for n in (250, 1000, 4000)]
print("keyhole error at n = 250, 1000, 4000 steps: " + ", ".join(f"{x:.9f}" for x in errs))
assert abs(sum(p) - 2j * math.pi * res(0.5)) < 1e-5 and abs(sum(q) - 2j * math.pi * res(0.25)) < 1e-5
big = [(abs(circle(0.5, R, 0, 2 * math.pi)), 2 * math.pi * R ** 0.5 / (R - 1)) for R in (4, 64, 1024)]
small = [(abs(circle(0.5, r, 2 * math.pi, 0)), 2 * math.pi * r ** 0.5 / (1 - r)) for r in (1 / 2, 1 / 64, 1 / 1024)]
print("big circle size (bound) at R = 4, 64, 1024: " + "; ".join(f"{s:.6f} ({b:.6f})" for s, b in big))
print("small circle size (bound) at r = 1/2, 1/64, 1/1024: " + "; ".join(f"{s:.6f} ({b:.6f})" for s, b in small))
assert all(s <= b for s, b in big + small) and big[2][0] < big[1][0] < big[0][0] and small[2][0] < small[1][0] < small[0][0]
w = keyhole(0.5, 0.5, 4, low=0)
print(f"mistake, bottom bank given the top value: four pieces {show(sum(w))}, not 6.283185 + 0.000000i")
print(f"mistake, arg(-1) taken as -pi: a = 0.50 gives {show(2j * math.pi * power(1, -math.pi, 0.5) / (1 - e(math.pi)))}")
print(f"mistake, bottom bank not reversed: a = 0.25 gives {show(2j * math.pi * res(0.25) / (1 + e(math.pi / 2)))}")
print(f"a = 1, no decay: big circle {show(circle(1, 4, 0, 2 * math.pi))} at R = 4, {show(circle(1, 64, 0, 2 * math.pi))} at R = 64")
d, o, s = 0.08, (180, 120), 25                # figure: 0 at (180, 120), 25 units per 1, r = 0.5, R = 4
pt = lambda rho, t: f"({o[0] + s * rho * math.cos(t):.2f}, {o[1] - s * rho * math.sin(t):.2f})"
print(f"figure, top bank {pt(0.5, d)} to {pt(4, d)}, bottom {pt(4, -d)} to {pt(0.5, -d)}, pole {pt(1, math.pi)}")
print("ALL CHECKS PASS")
