# Phragmen-Lindelof -- the check behind the card.  Standard library only.
# Strip |Im z| < pi/2, f(z) = exp(exp z).  Road one: closed forms.  Road two: complex
# arithmetic written out here and grid searches.  Then the damper of the proof, the
# half-plane, and the three-lines bound for exp(z^2) on the strip 0 <= Re z <= 1.
import math
H = math.pi / 2

def cexp(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
def f(z): return cexp(cexp(z))                           # exp(exp z), built by hand
def top(h, pts): return max(((abs(h(z)), z) for z in pts), key=lambda p: p[0])  # (largest |h|, where)
def row(v, d=2): return " ".join(f"{x:.{d}f}" for x in v)

edges = [complex(k / 100, s * H) for k in range(-300, 301) for s in (1, -1)]
e_max, _ = top(f, edges)
print(f"strip |Im z| < pi/2, f = exp(exp z): largest |f| on both edges, x from -3 to 3: {e_max:.6f}")
print(f"exp z on the top edge at x = 1: {cexp(complex(1, H)).real:.6f} + {cexp(complex(1, H)).imag:.6f}i")
print(f"f(1): by hand {abs(f(1 + 0j)):.6f}; closed form e^e {math.exp(math.e):.6f}")
xs = [k / 2 for k in range(-4, 3)]
print("chart, x:", row(xs, 1))
print("chart, |f(x)| on the centre line:", row([abs(f(complex(x, 0))) for x in xs]))
print("growth: ln ln |f(x)| at x = 1, 2, 3:", row([math.log(math.log(abs(f(complex(x, 0))))) for x in (1, 2, 3)], 6))
A, c, b, eps = 1.0, 0.5, 0.75, 0.01
dl = math.cos(b * H)
print(f"damper, A = 1, c = 0.5, b = 0.75, eps = 0.01: delta = cos(b pi/2) = {dl:.6f}")
r_closed = math.log(A / (eps * dl)) / (b - c)
x = 0.0
while A * math.exp(c * x) - 2 * eps * dl * math.cosh(b * x) > 0: x += 0.001
print(f"end walls under control from |x| = R: closed form {r_closed:.2f}; scan {x:.2f}")
print("bound at z = 1 once the damper comes off, eps = 0.01, 0.001, 0.0001:",
      row([math.exp(2 * e * math.cosh(b)) for e in (0.01, 0.001, 0.0001)], 6))
hd = lambda z: cexp(-eps * (cexp(b * z) + cexp(-b * z)))   # the damper h = exp(-2 eps cosh bz), built by hand
print(f"half-plane: |e^z| at z = e is {abs(cexp(complex(math.e, 0))):.6f}, the same as |f(1)|")
g3 = lambda z: cexp(z * z)                                # three lines: exp(z^2)
ys = [k / 1000 for k in range(-3000, 3001)]
M = lambda t: top(g3, [complex(t, y) for y in ys])[0]
m0, m1 = M(0.0), M(1.0)
ths = [k / 4 for k in range(5)]
grid, bound = [M(t) for t in ths], [m0 ** (1 - t) * m1 ** t for t in ths]
print(f"three lines, exp(z^2) on 0 <= Re z <= 1: M0 = {m0:.6f}, M1 = {m1:.6f}")
print("chart, theta:", row(ths))
print("chart, M(theta) by grid search:", row(grid, 3), "| closed form e^(theta^2):", row([math.exp(t * t) for t in ths], 3))
print("chart, bound M0^(1-theta) M1^theta:", row(bound, 3))
g = lambda z: g3(z) * cexp((z - 1) * math.log(m0)) * cexp(-z * math.log(m1))  # f M0^(z-1) M1^(-z)
gm, gz = top(g, [complex(k / 100, y / 100) for k in range(101) for y in range(-300, 301)])
print(f"g = exp(z^2 - z): largest |g| on the grid {gm:.6f}, on an edge: {'yes' if gz.real in (0, 1) else 'no'}; |g(1/2)| = {abs(g(0.5 + 0j)):.6f}")
print(f"break 1, no growth limit: edges {e_max:.6f}, f(1) = {abs(f(1 + 0j)):.6f}")
f2 = lambda z: f(z / 2)
w_max = top(f2, [complex(k / 100, s * 2 * H) for k in range(-300, 301) for s in (1, -1)])[0]
print(f"break 2, strip twice as wide, exp(exp(z/2)) on |Im z| < pi: edges {w_max:.6f}, at z = 2 {abs(f2(2 + 0j)):.6f}")
rm, rz = top(f, [complex(k / 100, y * H / 50) for k in range(-200, 201) for y in range(-50, 51)])
print(f"break 3, rectangle |x| <= 2: largest |f| {rm:.6f} at x = {rz.real:.0f}, y = {abs(rz.imag):.0f}, an end wall")
print(f"break 4, arithmetic mean of M0, M1: {(m0 + m1) / 2:.6f}, against the geometric {bound[2]:.6f}; true M(1/2) {grid[2]:.6f}")
assert abs(e_max - 1) < 1e-12 and abs(abs(f(1 + 0j)) - math.exp(math.e)) < 1e-9   # edges; e^e
assert all(abs(p - math.exp(t * t)) < 1e-9 and abs(q - math.exp(t)) < 1e-9 and p <= q + 1e-12 for p, q, t in zip(grid, bound, ths))
assert abs(x - r_closed) < 0.01 and abs(dl - math.sin(math.pi / 8)) < 1e-12        # R two ways; delta = sin(pi/8)
assert all(abs(hd(complex(k / 10, y * H / 10))) <= math.exp(-eps * dl * math.exp(b * abs(k / 10))) + 1e-15
           for k in range(-300, 301) for y in range(-10, 11))                 # Step 1's damper bound
assert gm <= 1 + 1e-12 and gz.real in (0, 1) and abs(rm - math.exp(math.exp(2))) < 1e-6
print("ALL CHECKS PASS")
