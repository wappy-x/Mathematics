# Chain rule -- the check behind the card.  Nothing is imported.  A car leaves
# town: s(t) = 60t + 20t^2 km after t hours; the road climbs, so G(s) = 0.05s +
# 0.0002s^2 litres are burned by km s; fuel costs 1.80 $/L.  Cost rate at t = 1.
P, T = 1.80, 1.0
def s(t): return 60 * t + 20 * t * t                 # km driven by hour t
def G(x): return 0.05 * x + 0.0002 * x * x            # litres burned by km x
def C(t): return P * G(s(t))                          # dollars spent by hour t
def mul(a, b):                                        # multiply two coefficient lists
    out = [0.0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b): out[i + j] += x * y
    return out
def fmt(v, d=3): return "[" + ", ".join(f"{x:.{d}f}" for x in v) + "]"
# road 1: three rates, each from the power rule, multiplied
inner, middle = 60 + 40 * T, 0.05 + 0.0004 * s(T)
chain = P * middle * inner
# road 2: expand C(t) into powers of t, then differentiate term by term
sc = [0.0, 60.0, 20.0]
cc = [P * (0.05 * a + 0.0002 * b) for a, b in zip(sc + [0.0, 0.0], mul(sc, sc))]
expanded = sum(k * c * T ** (k - 1) for k, c in enumerate(cc) if k > 0)
print(f"at t = 1 h: distance {s(T):.0f} km, fuel used {G(s(T)):.2f} L, cost {C(T):.3f} $")
print(f"rates: ds/dt = {inner:.0f} km/h, dG/ds at 80 km = {middle:.3f} L/km, price {P:.2f} $/L")
print(f"road 1, rates multiplied: {P:.2f} x {middle:.3f} x {inner:.0f} = {chain:.2f} $/h")
print(f"road 2, C(t) expanded, coefficients {fmt(cc)}; C'(1) = {expanded:.2f} $/h")
errs = []
for h in (0.1, 0.01, 0.001, 0.0001):                  # road 3: shrinking secants
    q = (C(T + h) - C(T)) / h
    errs.append(q - chain)
    print(f"road 3, secant over h = {h:g} h: {q:.6f} $/h, error {q - chain:.6f}")
lo, hi = 0.0, 0.1                                     # largest step within 0.01 $/h
for _ in range(60):
    mid = (lo + hi) / 2
    if (C(T + mid) - C(T)) / mid - chain < 0.01: lo = mid
    else: hi = mid
print(f"tolerance: every forward step under {lo:.5f} h ({lo * 3600:.1f} s) lands within 0.01 $/h")
h = 0.01; k = s(T + h) - s(T); r = 20 * h; e = 0.0002 * k
proof = P * (middle + e) * (inner + r)
print(f"proof pieces at h = 0.01: k = {k:.3f} km, r = {r:.3f}, e = {e:.7f}, product {proof:.6f}")
def Cp(t): return P * G(80 + 0 * t)                  # a parked car: s stays at 80 km
print(f"parked car, s held at 80 km: secant over h = 0.01 is {(Cp(T + h) - Cp(T)) / h:.2f}; chain gives {P * middle * 0:.2f}")
print(f"mistake 1, dG/ds read at 1 instead of 80: {P * (0.05 + 0.0004 * T) * inner:.3f} $/h")
print(f"mistake 2, average speed 80 km/h in place of 100: {P * middle * s(T) / T:.3f} $/h")
print(f"mistake 3, inner rate dropped: {P * middle:.4f} $ per km, not per hour")
def Gc(x): return 0.06 * x if x <= 80 else 4.8 + 0.09 * (x - 80)   # climb starts at km 80
left = (P * Gc(s(T)) - P * Gc(s(T - 0.001))) / 0.001
right = (P * Gc(s(T + 0.001)) - P * Gc(s(T))) / 0.001
print(f"corner at km 80: cost rate from the left {left:.2f} $/h, from the right {right:.2f} $/h")
pts = [i / 4 for i in range(9)]
print("chart, cost C(t) at t = 0, 0.25, ..., 2:", fmt([C(t) for t in pts], 2))
print("chart, tangent at t = 1:", fmt([C(T) + chain * (t - T) for t in pts], 2))
assert abs(chain - expanded) < 1e-9                   # product of rates = term-by-term
assert abs(errs[-1]) < 1e-3 and 9 < errs[0] / errs[1] < 11   # secants close in, tenfold
assert abs(proof - (C(T + h) - C(T)) / h) < 1e-9      # remainder form = direct secant
assert abs((right - left) - P * (0.09 - 0.06) * 100) < 0.01   # the corner's jump
print("ALL CHECKS PASS")
