# Similar triangles and scale -- the check behind the card.  Standard library
# only.  A metre stick and a flagpole stand on level ground in the same sun.
# The pole's height is found twice: by scaling the stick (road one) and by
# hunting the height that makes the sun's angle match (road two).  Areas are
# found by the formula and by counting 1 cm squares.  A river is crossed too.
import math
h, s, S = 1.0, 0.8, 9.6                 # stick height, stick shadow, pole shadow (m)
k = S / s                               # road one: the scale factor
H1 = h * k

def cos_at_tip(height, shadow):         # cosine at the tip: dot product of the sides over their lengths
    return shadow / math.sqrt(shadow * shadow + height * height)

lo, hi = 0.0, 1000.0                    # road two: bisection on the pole height
for _ in range(200):
    mid = (lo + hi) / 2
    if cos_at_tip(mid, S) > cos_at_tip(h, s): lo = mid
    else: hi = mid
H2 = (lo + hi) / 2
assert abs(H1 - H2) < 1e-9

def count_cm2(hc, sc):                  # squares of 1 cm whose centre lies under the ray
    return sum(1 for i in range(sc) for j in range(hc)
               if (2 * j + 1) * sc + (2 * i + 1) * hc < 2 * hc * sc)
a_stick, a_pole = h * s / 2, H1 * S / 2
c_stick, c_pole = count_cm2(100, 80), count_cm2(1200, 960)
assert abs(c_pole / 1e4 - a_pole) / a_pole < 0.005
assert abs(c_pole / c_stick - k * k) / (k * k) < 0.01

near, on, back = 30.0, 10.0, 6.0        # river: marker Q is 30 m along, R 10 m on, S 6 m back
w1 = back * near / on                   # road one: scale the small triangle
x1, y1, x2, y2 = on + near, -back, near, 0.0   # road two: line S to Q meets the line x = 0
w2 = y1 + (0 - x1) * (y2 - y1) / (x2 - x1)
assert abs(w1 - w2) < 1e-9

print(f"flagpole: stick {h:.1f} m casts {s:.1f} m, pole casts {S:.1f} m")
print(f"scale factor k = {k:.0f}")
print(f"road 1, scale the stick: pole height {H1:.6f} m")
print(f"road 2, match the sun's angle by bisection: pole height {H2:.6f} m")
sun, top = math.degrees(math.atan2(h, s)), math.degrees(math.atan2(s, h))
print(f"angles: sun {sun:.1f} at both tips, top {top:.1f}, with the right angle {sun + top + 90:.1f}")
print(f"areas by formula: stick {a_stick:.6f} m^2, pole {a_pole:.6f} m^2")
print(f"areas by counting 1 cm squares: stick {c_stick / 1e4:.4f} m^2, pole {c_pole / 1e4:.4f} m^2")
print(f"area ratio: formula {a_pole / a_stick:.4f}, counted {c_pole / c_stick:.4f}, k^2 = {k * k:.0f}")
print(f"river: factor {near / on:.0f}, road 1, scale the 6 m walk: width {w1:.6f} m")
print(f"river: road 2, intersect the sight line: width {w2:.6f} m")
print(f"mistake, ratio upside down: {s * S / h:.6f} m")
print(f"mistake, area scaled by k: {a_stick * k:.6f} m^2")
print(f"mistake, stick shadow read later at 1.2 m: {h * S / 1.2:.6f} m")
g, m = 220.0, 16.0                      # figures: ground line and units per metre
print(f"figure, flag (1 m = 16): pole (40.0,{g:.1f})-(40.0,{g - H1 * m:.1f}), tip ({40 + S * m:.1f},{g:.1f}), "
      f"stick top (260.0,{g - h * m:.1f}), tip ({260 + s * m:.1f},{g:.1f})")
print(f"figure, river (1 m = 6): P (50,150), T (50,{150 - w1 * 6:.0f}), Q ({50 + near * 6:.0f},150), "
      f"R ({50 + (near + on) * 6:.0f},150), S ({50 + (near + on) * 6:.0f},{150 + back * 6:.0f})")
print("ALL CHECKS PASS")
