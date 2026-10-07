# The complex derivative -- the check behind the card.  Standard library only.
# Road one: the quotient (f(z0 + h) - f(z0)) / h along three directions, the step h shrinking.
# Road two: partial derivatives of u = Re f and v = Im f by central differences, then Cauchy-Riemann.
import math

def show(w):                                          # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

def quotient(f, z0, t, theta):                        # step of length t at angle theta
    h = complex(t * math.cos(theta), t * math.sin(theta))
    return (f(z0 + h) - f(z0)) / h

def partials(f, x, y, d=1e-5):                        # u_x, u_y, v_x, v_y by central differences
    fx = (f(complex(x + d, y)) - f(complex(x - d, y))) / (2 * d)
    fy = (f(complex(x, y + d)) - f(complex(x, y - d))) / (2 * d)
    return fx.real, fy.real, fx.imag, fy.imag

def three(f, z0, t):                                  # quotients at 0, 45 and 90 degrees
    return [quotient(f, z0, t, k * math.pi / 4) for k in (0, 1, 2)]

square = lambda z: z * z                              # the square filter
mirror = lambda z: complex(z.real, -z.imag)           # the mirror filter, z-bar
size2 = lambda z: complex(z.real ** 2 + z.imag ** 2, 0.0)          # |z|^2
cross = lambda z: complex(math.sqrt(abs(z.real * z.imag)), 0.0)    # sqrt(|xy|)
z0 = 1 + 1j
print(f"square filter: f(1 + i) = {show(square(z0))}, closed form 2 z0 = {show(2 * z0)}")
gaps = {}
for t in (0.1, 0.01, 0.001):
    qs = three(square, z0, t)
    gaps[t] = max(abs(q - 2 * z0) for q in qs)
    print(f"square |h| = {t}: 0 deg {show(qs[0])}, 45 deg {show(qs[1])}, 90 deg {show(qs[2])}, worst gap {gaps[t]:.6f}")
ux, uy, vx, vy = partials(square, z0.real, z0.imag)
print(f"square partials at (1, 1): u_x {ux:.6f}, v_y {vy:.6f}, u_y {uy:.6f}, -v_x {-vx:.6f}")
d_real, d_imag = complex(ux, vx), complex(vy, -uy)
print(f"square: u_x + i v_x = {show(d_real)}, v_y - i u_y = {show(d_imag)}; stretch {abs(d_real):.6f}, "
      f"turn {math.atan2(vx, ux):.6f} rad = {math.degrees(math.atan2(vx, ux)):.6f} deg")
print(f"wrong sign u_y = v_x on the square: {uy:.6f} against {vx:.6f}, so z^2 would be rejected")
for t in (0.1, 0.001):
    qs = three(mirror, z0, t)
    print(f"mirror |h| = {t}: 0 deg {show(qs[0])}, 45 deg {show(qs[1])}, 90 deg {show(qs[2])}")
mx, my, nx, ny = partials(mirror, z0.real, z0.imag)
print(f"mirror partials: u_x {mx:.6f}, v_y {ny:.6f}, u_y {my:.6f}, -v_x {0.0 - nx:.6f}: u_x = v_y fails")
qa, qb = three(size2, z0, 0.001), three(size2, 0j, 0.001)
sx, sy, tx, ty = partials(size2, z0.real, z0.imag)
print(f"|z|^2 at 1 + i, |h| = 0.001: 0 deg {show(qa[0])}, 90 deg {show(qa[2])}; u_x {sx:.6f}, v_y {ty:.6f}")
print(f"|z|^2 at 0, |h| = 0.001: 0 deg {show(qb[0])}, 45 deg {show(qb[1])}, 90 deg {show(qb[2])}")
qc, pc = three(cross, 0j, 0.001), partials(cross, 0.0, 0.0)
print(f"sqrt(|xy|) at 0: partials {' '.join(f'{p:.6f}' for p in pc)}; quotient 0 deg {show(qc[0])}, 45 deg {show(qc[1])}")
S, O = 40, (140, 160)                                 # figure: 40 units per 1, 0 at (140, 160)
P = lambda w: f"({O[0] + S * w.real:.0f},{O[1] - S * w.imag:.0f})"
print(f"figure, {S} units per 1, 0 at ({O[0]},{O[1]}), step 0.5: z0 " + P(z0) + " steps " + P(z0 + 0.5) + " " + P(z0 + 0.5j) + "; square " + P(square(z0))
      + " arrows " + P(square(z0) + d_real * 0.5) + " " + P(square(z0) + d_real * 0.5j))
print("figure, mirror " + P(mirror(z0)) + " arrows " + P(mirror(z0 + 0.5)) + " " + P(mirror(z0 + 0.5j)))
assert all(abs(gaps[t] - t) < 1e-9 for t in gaps)             # quotient minus 2 z0 is exactly h
assert abs(d_real - 2 * z0) < 1e-6 and abs(d_imag - 2 * z0) < 1e-6   # partials road meets 2 z0
assert all(abs(q - complex(math.cos(k * math.pi / 2), -math.sin(k * math.pi / 2))) < 1e-9
           for k, q in enumerate(three(mirror, z0, 0.001)))   # mirror quotient is e^(-2 i theta)
assert max(map(abs, pc)) < 1e-12 and abs(qc[1] - (0.5 - 0.5j)) < 1e-9 and all(abs(abs(q) - 0.001) < 1e-12 for q in qb)
print("ALL CHECKS PASS")
