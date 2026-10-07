# Conjugate and modulus -- the check behind the card.  Standard library only.
# Drone z = 3 + 4i km from its depot, second drone w = 6 + 8i, beacon p = 1 + 2i.
# Two roads: the conjugate's algebra, and roads that never use it (a 2-by-2
# linear solve for division, the longest shadow of an arrow for its length).
import math

def fmt(z):
    re, im = z.real + 0.0, z.imag + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def conj(z): return complex(z.real, -z.imag)           # flip across the real axis
def modulus(z): return math.sqrt((z * conj(z)).real)   # road one: |z| = sqrt(z z-bar)
def divide(p, z): return p * conj(z) / (z * conj(z)).real

def longest_shadow(z):          # road two: max of a cos t + b sin t over directions t
    a, b = z.real, z.imag
    s = lambda t: a * math.cos(t) + b * math.sin(t)
    n = 7200
    t0 = max((-math.pi + 2 * math.pi * k / n for k in range(n)), key=s)
    lo, hi = t0 - 2 * math.pi / n, t0 + 2 * math.pi / n
    for _ in range(200):                                # ternary search near the best
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (m1, hi) if s(m1) < s(m2) else (lo, m2)
    return s((lo + hi) / 2)

def cramer(p, z):               # road two: solve (a + bi)(x + iy) = c + di as two real equations
    a, b, c, d = z.real, z.imag, p.real, p.imag        # a x - b y = c,  b x + a y = d
    det = a * a + b * b
    return complex((c * a + d * b) / det, (a * d - b * c) / det)

z, w, p = 3 + 4j, 6 + 8j, 1 + 2j
sc, ox, oy = 15, 50, 165
pix = lambda q: f"({ox + sc * q.real:.0f}, {oy - sc * q.imag:.0f})"
q1, q2 = divide(p, z), cramer(p, z)
print(f"figure, scale {sc} px per km, depot {pix(0j)}; z {pix(z)}; z-bar {pix(conj(z))}; w {pix(w)}; circle radius {sc * modulus(z):.0f}")
print(f"drone z = {fmt(z)}; conjugate z-bar = {fmt(conj(z))}")
print(f"z times z-bar = {fmt(z * conj(z))}")
print(f"|z| by sqrt(z z-bar) = {modulus(z):.6f}; by longest shadow = {longest_shadow(z):.6f}")
print(f"(1 + 2i)(3 - 4i) = {fmt(p * conj(z))}; divide by {(z * conj(z)).real:.0f}")
print(f"(1 + 2i)/(3 + 4i) by the conjugate = {fmt(q1)}")
print(f"by solving 3x - 4y = 1, 4x + 3y = 2 = {fmt(q2)}")
print(f"multiply back: (3 + 4i)({fmt(q1)}) = {fmt(z * q1)}")
print(f"second drone w = {fmt(w)}: |w - z| = {modulus(w - z):.6f}; by longest shadow = {longest_shadow(w - z):.6f}")
print(f"|w| = {modulus(w):.6f}; |z| + |w - z| = {modulus(z) + modulus(w - z):.6f}")
print(f"beacon p = {fmt(p)}: zp = {fmt(z * p)}; |zp| = {modulus(z * p):.6f}; |z||p| = {modulus(z) * modulus(p):.6f}")
print(f"triangle: |z + p| = {modulus(z + p):.6f} <= |z| + |p| = {modulus(z) + modulus(p):.6f}")
print(f"reverse: ||z| - |p|| = {abs(modulus(z) - modulus(p)):.6f} <= |z - p| = {modulus(z - p):.6f}")
print(f"mirror: |z-bar| = {modulus(conj(z)):.6f}; |z - z-bar| = {modulus(z - conj(z)):.6f}")
print(f"mistake 1, no square root: {(z * conj(z)).real:.6f}, not {modulus(z):.6f}")
print(f"mistake 2, top multiplied only: {fmt(p * conj(z))}, not {fmt(q1)}")
print(f"mistake 3, conjugate taken as reciprocal: {fmt(conj(z))}, not {fmt(divide(1, z))}")
print(f"mistake 4, difference of moduli as distance: {abs(modulus(z) - modulus(conj(z))):.6f}, not {modulus(z - conj(z)):.6f}")
assert abs(q1 - q2) < 1e-12                                     # division, two roads
assert abs(modulus(z) - longest_shadow(z)) < 1e-9               # length, two roads
assert abs(modulus(w - z) - longest_shadow(w - z)) < 1e-9       # distance, two roads
assert abs(modulus(z * p) - modulus(z) * modulus(p)) < 1e-12    # |zp| = |z||p|
print("ALL CHECKS PASS")
