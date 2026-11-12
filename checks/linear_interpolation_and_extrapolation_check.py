# Linear interpolation and extrapolation -- the check behind the card.  Standard library only.
# Illustrative tide: height H = 2.5 + 1.8 cos(w (t - 6 - 0.1 x)) metres above chart datum, t hours
# after midnight, x km up the estuary from the harbour-mouth gauge, w = 2 pi / 12.42 radians an hour.
# Road 1: the exact curve.  Road 2: the line through two readings, built two ways.  Road 3: the error
# against the bound M h^2 / 8, the point xi of the error formula, and the observed order as h shrinks.
# Then bilinear interpolation three ways, extrapolation past 10 am, and an eight-quote yield curve.
import math
PI = 3.141592653589793
W = 2 * PI / 12.42

def cos(z):                                     # written out with + - * / only, so Python and Rust
    while z > PI:                               # agree to the bit; math.cos is only a cross-check
        z -= 2 * PI
    while z < -PI:
        z += 2 * PI
    z, sign = abs(z), 1.0
    if z > PI / 2:
        z, sign = PI - z, -1.0
    term, total = 1.0, 1.0
    for k in range(1, 20):
        term = -term * z * z / ((2 * k - 1) * (2 * k))
        total += term
    return sign * total
def H(t, x=0.0): return 2.5 + 1.8 * cos(W * (t - 6 - 0.1 * x))
def H2(t): return -1.8 * W * W * cos(W * (t - 6))      # d2H/dt2 at the mouth; d2H/dx2 is 0.01 times it
def M(t1, t2, x1=0.0, x2=0.0):                  # largest |d2H/dt2| over the box: |cos| peaks at an end
    p, q = W * (t1 - 6 - 0.1 * x2), W * (t2 - 6 - 0.1 * x1)              # of the phase range, or at 0 or pi
    return 1.8 * W * W * (1.0 if p <= PI <= q or p <= 0 <= q else max(abs(cos(p)), abs(cos(q))))
def line(t, a, b, Ha, Hb):                      # weights form: (1 - s) Ha + s Hb
    s = (t - a) / (b - a)
    return (1 - s) * Ha + s * Hb
def slope_form(t, a, b, Ha, Hb): return Ha + (t - a) * ((Hb - Ha) / (b - a))
def e(x, d): return f"{x:.{d}e}"
def d2(f, u, d=1e-3): return (f(u + d) - 2 * f(u) + f(u - d)) / (d * d)   # second difference: H'' by another road

assert max(abs(cos(0.01 * i) - math.cos(0.01 * i)) for i in range(-700, 701)) < 1e-14   # library cross-check
a, b, t = 9.0, 10.0, 9.0 + 1 / 3
Ha, Hb = H(a), H(b)
print(f"readings: 9 am {Ha:.4f} m, 10 am {Hb:.4f} m; slope {(Hb - Ha) / (b - a):.4f} m per hour; w = {W:.6f}")
L, L2, T = line(t, a, b, Ha, Hb), slope_form(t, a, b, Ha, Hb), H(t)
err, Mab = T - L, M(a, b)
bt, bh = Mab / 2 * (t - a) * (b - t), Mab * (b - a) ** 2 / 8
print(f"9:20 am: line {L:.4f} m (slope form {L2:.4f}), true {T:.4f} m, true error H - L {err:.4f} m")
print(f"ceiling M on [9, 10] {Mab:.4f} m/h^2; bound M/2 (t-a)(b-t) {bt:.4f}, M h^2/8 {bh:.4f}; bound over |error| {bt / abs(err):.2f}")
assert abs(L - L2) < 1e-15 and abs(err) <= bt <= bh and abs(T - 2.2925) < 1e-4
assert all(abs(H2(u) - d2(H, u)) < 1e-5 for u in (a, 9.5, b)) and abs(Mab - max(abs(d2(H, a + i / 400)) for i in range(401))) < 1e-5
c = 2 * err / ((t - a) * (t - b))               # the error formula says c = H''(xi) for some xi in [9, 10]
lo, hi = a, b                                   # H'' rises on [9, 10]: bisect for xi
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if H2(mid) < c else (lo, mid)
print(f"error formula: 2 e / ((t-a)(t-b)) = {c:.6f} = H''(xi) at xi = {lo:.4f} h, inside [9, 10]; H'' runs {H2(a):.4f} to {H2(b):.4f}")
assert H2(a) < c < H2(b) and a < lo < b
print(f"at 9:30: true error {H(9.5) - line(9.5, a, b, Ha, Hb):.5f} m; estimate -H''(9.5)/8 = {-H2(9.5) / 8:.5f} m")
assert abs(-H2(9.5) / 8 / (H(9.5) - line(9.5, a, b, Ha, Hb)) - 1) < 0.01
errs = []
for k in range(13):                             # interval of width h = 4^-k centred on 9:30, error at its centre
    h = 0.25 ** k
    errs.append(H(9.5) - line(9.5, 9.5 - h / 2, 9.5 + h / 2, H(9.5 - h / 2), H(9.5 + h / 2)))
orders = [math.log(abs(errs[k] / errs[k + 1])) / math.log(4) for k in range(8)]
print("order: true error at 9:30 for h = 4^-k, k = 0..12: " + ", ".join(e(x, 2) for x in errs[:7]))
print("       " + ", ".join(e(x, 2) for x in errs[7:]) + "; observed order k=0..7 " + ", ".join(f"{o:.2f}" for o in orders))
print("chart, log10 h: " + ", ".join(f"{math.log10(0.25 ** k):.2f}" for k in range(9)) + "; log10 |error|: " + ", ".join(f"{math.log10(abs(x)):.2f}" for x in errs[:9]))
assert all(abs(o - 2) < 0.01 for o in orders) and abs(errs[12]) < 1e-14

print("extrapolating the 9-10 am line: t, line, true, true error, factor (t-9)(t-10), bound M[9,t]/2 x factor, ratio")
for tt in (10.5, 11.0, 12.0, 13.0):
    Lt, Tt = line(tt, a, b, Ha, Hb), H(tt)
    bd = M(a, tt) / 2 * (tt - a) * (tt - b)
    print(f"  {tt:5.2f} h: {Lt:7.4f} m, {Tt:.4f} m, {Tt - Lt:.4f} m, {(tt - a) * (tt - b):5.2f}, {bd:.4f} m, {bd / abs(Tt - Lt):.2f}")
    assert abs(Tt - Lt) <= bd and abs(M(a, tt) - max(abs(d2(H, a + (tt - a) * i / 400)) for i in range(401))) < 1e-5
assert line(13.0, a, b, Ha, Hb) < 0 < H(13.0) and abs(H(13.0) - line(13.0, a, b, Ha, Hb)) > 100 * abs(err)
w13 = (1 - (13.0 - a) / (b - a), (13.0 - a) / (b - a))          # the line's two weights at 1 pm
print(f"weights at 13 h: {w13[0]:.2f} and {w13[1]:.2f}; reading errors d move the line by up to {abs(w13[0]) + abs(w13[1]):.2f} d")
assert abs(line(13.0, a, b, Ha + 1e-3, Hb - 1e-3) - line(13.0, a, b, Ha, Hb) + (abs(w13[0]) + abs(w13[1])) * 1e-3) < 1e-12
grid = [6 + 0.5 * i for i in range(17)]
print("chart, true tide 6 am to 2 pm by half hours: " + ", ".join(f"{H(g):.2f}" for g in grid))
print("chart, the 9-10 am line extended: " + ", ".join(f"{line(g, a, b, Ha, Hb):.2f}" for g in grid))

x0, x1, x = 0.0, 6.0, 2.0                       # bilinear: mooring 2 km up, between mouth (0) and quay (6)
C = [[H(a, x0), H(a, x1)], [H(b, x0), H(b, x1)]]
s, r = (t - a) / (b - a), (x - x0) / (x1 - x0)
B1 = line(x, x0, x1, line(t, a, b, C[0][0], C[1][0]), line(t, a, b, C[0][1], C[1][1]))   # time first
B2 = line(t, a, b, line(x, x0, x1, C[0][0], C[0][1]), line(x, x0, x1, C[1][0], C[1][1]))   # distance first
B3 = (1 - s) * (1 - r) * C[0][0] + (1 - s) * r * C[0][1] + s * (1 - r) * C[1][0] + s * r * C[1][1]
T2, Mt = H(t, x), M(a, b, x0, x1)
Mx = 0.01 * Mt                                  # distance enters the phase times 0.1, so its bend is 0.01 times
bound2 = Mt / 2 * (t - a) * (b - t) + Mx / 2 * (x - x0) * (x1 - x)
bound8 = (Mt * (b - a) ** 2 + Mx * (x1 - x0) ** 2) / 8                # the formula's whole-box form
print(f"corners: mouth {C[0][0]:.4f}, {C[1][0]:.4f}; quay {C[0][1]:.4f}, {C[1][1]:.4f} m at 9 and 10 am; s = r = 1/3")
print(f"bilinear at 9:20, 2 km: time first {B1:.4f}, distance first {B2:.4f}, four weights {B3:.4f}; true {T2:.4f}; true error {T2 - B3:.4f} m")
print(f"ceilings: |H_tt| {Mt:.4f}, |H_xx| {Mx:.6f}; bound {bound2:.4f} m, box form {bound8:.4f} m; bound over |error| {bound2 / abs(T2 - B3):.2f}")
assert abs(B1 - B2) < 1e-14 and abs(B1 - B3) < 1e-14 and abs(T2 - B3) <= bound2 <= bound8
box = [(a + i / 50, x0 + (x1 - x0) * j / 50) for i in range(51) for j in range(51)]
assert abs(Mt - max(abs(d2(lambda u: H(u, q), p)) for p, q in box)) < 1e-5 and abs(Mx - max(abs(d2(lambda v: H(p, v), q)) for p, q in box)) < 1e-7
print("cost: weights form 3 + 4 = 7 flops a reading; slope form 3, once the slope (3 flops) is stored; bilinear 3 readings, 21 flops")

print(f"mistake, nearest reading (9 am): {Ha:.4f} m, error {T - Ha:.4f}")
print(f"mistake, 20 minutes as s = 0.20: {line(9.2, a, b, Ha, Hb):.4f} m, error {T - line(9.2, a, b, Ha, Hb):.4f}")
print(f"mistake, weights swapped: {s * Ha + (1 - s) * Hb:.4f} m, error {T - (s * Ha + (1 - s) * Hb):.4f}")
avg4 = (C[0][0] + C[0][1] + C[1][0] + C[1][1]) / 4
print(f"mistake, plain average of four corners: {avg4:.4f} m, error {T2 - avg4:.4f}")

mats = [1, 2, 3, 5, 7, 10, 20, 30]              # illustrative yield quotes, percent a year, annual compounding
ylds = [4.10, 3.95, 3.90, 3.95, 4.05, 4.20, 4.60, 4.40]
def curve(m, flat_end):
    if m >= 30 and flat_end:
        return ylds[-1]
    j = max(i for i in range(7) if mats[i] <= m) if m < 30 else 6
    return line(m, mats[j], mats[j + 1], ylds[j], ylds[j + 1])
assert all(abs(curve(m, f) - y) < 1e-12 for m, y in zip(mats, ylds) for f in (True, False))
def pv(y, n):                                   # $1,000,000 due in n years, discounted at y percent a year
    d = 1.0
    for _ in range(n):
        d = d / (1 + y / 100)
    return 1e6 * d
y50a, y50b = curve(50, False), curve(50, True)
print(f"yield curve: 4 years {curve(4, False):.3f}%, 15 years {curve(15, False):.3f}%; both rules hit all 8 quotes")
print(f"50 years: line through 20 and 30 extended {y50a:.3f}%, flat after 30 {y50b:.3f}%")
print(f"$1,000,000 due in 50 years: worth ${pv(y50a, 50):,.0f} or ${pv(y50b, 50):,.0f} today; gap ${pv(y50a, 50) - pv(y50b, 50):,.0f}")
assert abs(y50a - 4.0) < 1e-12 and abs(pv(4.0, 50) - 1e6 / 1.04 ** 50) < 1e-6 and pv(y50a, 50) > pv(y50b, 50)
print("ALL CHECKS PASS")
