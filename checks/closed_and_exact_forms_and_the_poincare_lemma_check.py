# Closed and exact forms -- the check behind the card.  Standard library only.
# A market maker sells three contracts on tomorrow's weather in a valley: Rain,
# Wind, Calm.  x = (x1, x2, x3) counts shares sold; a trade dx costs the price
# one-form w = p1 dx1 + p2 dx2 + p3 dx3 dollars.  Is w closed?  Exact?  Then the
# same two questions for a two-form: the wind's flux through a gate.
import math

B = 100.0                                         # liquidity, dollars

def lmsr(x, b=B):                                 # prices from the log cost function
    e = [math.exp(xi / b) for xi in x]
    return [ei / sum(e) for ei in e]

def naive(x, s=300):                              # a desk's straight-line rule
    return [1 / 3 + (x[i] - x[(i + 1) % 3]) / s for i in range(3)]

def cost(x):                                      # the potential, in closed form
    return B * math.log(sum(math.exp(xi / B) for xi in x))

def rate(f, x, i, j, h=1e-3):                     # d f_i / d x_j, central difference
    up, dn = list(x), list(x)
    up[j] += h
    dn[j] -= h
    return (f(up)[i] - f(dn)[i]) / (2 * h)

def simpson(g, n):                                # integral of g over [0, 1], n even
    s = g(0.0) + g(1.0) + sum((4 if k % 2 else 2) * g(k / n) for k in range(1, n))
    return s / (3 * n)

def leg(f, a, b, n=20):                           # line integral of f . dx along a to b
    d = [b[i] - a[i] for i in range(len(a))]
    return simpson(lambda t: sum(c * e for c, e in
                                 zip(f([a[i] + t * d[i] for i in range(len(a))]), d)), n)

def route(f, pts, n=20):
    return sum(leg(f, a, b, n) for a, b in zip(pts, pts[1:]))

def radial(f, x, n):                              # Poincare's potential: the straight ray
    return simpson(lambda t: sum(c * e for c, e in zip(f([t * xi for xi in x]), x)), n)

def fx(v):                                        # fixed decimals, never "-0.000000"
    return f"{v + 0.0:.6f}".replace("-0.000000", "0.000000")

x = [60.0, 30.0, 0.0]
p = lmsr(x)
print("trade: buy 60 Rain and 30 Wind from x = (0, 0, 0); b = 100 dollars")
print(f"prices at (60, 30, 0): Rain {fx(p[0])}, Wind {fx(p[1])}, Calm {fx(p[2])}")
ex = [math.exp(xi / B) for xi in x]
print(f"exp(x/b): {', '.join(fx(e) for e in ex)}; sum Z {fx(sum(ex))}; "
      f"C(0) {fx(cost([0, 0, 0]))}, C(x) {fx(cost(x))}")
for i, j in [(0, 1), (1, 2), (0, 2)]:
    print(f"closed test x{i+1},x{j+1}: dp{i+1}/dx{j+1} {fx(rate(lmsr, x, i, j))}, "
          f"dp{j+1}/dx{i+1} {fx(rate(lmsr, x, j, i))}, formula -p{i+1}p{j+1}/b {fx(-p[i] * p[j] / B)}")
exact = cost(x) - cost([0, 0, 0])
stairs = route(lmsr, [[0, 0, 0], [60, 0, 0], [60, 30, 0]])
r10, r20 = radial(lmsr, x, 10), radial(lmsr, x, 20)
print(f"potential C(x) - C(0), closed form: {fx(exact)} dollars")
print(f"radial formula, Simpson 10 / 20 steps: {fx(r10)} / {fx(r20)}")
print(f"radial formula errors, 10 / 20 steps: {abs(r10 - exact):.10f} / {abs(r20 - exact):.10f}")
print(f"staircase route, Rain first then Wind: {fx(stairs)}")
sq = [[0, 0, 0], [0, 100, 0], [100, 100, 0], [100, 0, 0], [0, 0, 0]]
pts = [[sq[k // 2][i] + (k % 2) * (sq[k // 2 + 1][i] - sq[k // 2][i]) / 2 for i in range(3)]
       for k in range(8)] + [sq[4]]
cum_l, cum_n = [0.0], [0.0]
for a, b in zip(pts, pts[1:]):
    cum_l.append(cum_l[-1] + leg(lmsr, a, b))
    cum_n.append(cum_n[-1] + leg(naive, a, b))
print("chart, shares traded: " + ", ".join(str(50 * k) for k in range(9)))
print("chart, cash paid, log-cost maker: " + ", ".join(f"{v + 0.0:.2f}".replace("-0.00", "0.00") for v in cum_l))
print("chart, cash paid, straight-line rule: " + ", ".join(f"{v + 0.0:.2f}".replace("-0.00", "0.00") for v in cum_n))
defect = rate(naive, x, 1, 0) - rate(naive, x, 0, 1)
print(f"straight-line rule: dp1/dx2 {fx(rate(naive, x, 0, 1))}, dp2/dx1 {fx(rate(naive, x, 1, 0))}, "
      f"defect {fx(defect)} per share squared")
print(f"round trip, log-cost maker: trader nets {fx(-cum_l[-1])} dollars")
print(f"round trip, straight-line rule: trader nets {fx(-cum_n[-1])} dollars; "
      f"defect x area {fx(defect * 100 * 100)}")
print(f"reverse lap on the straight-line rule: trader nets {fx(-route(naive, sq[::-1]))}")
lap50, lap150 = -route(lambda c: lmsr(c, 50.0), sq), -route(lambda c: naive(c, 150.0), sq)
print(f"try: b = 50, log-cost lap: trader nets {fx(lap50)}; straight-line rule over 150: trader nets {fx(lap150)}")

def wind(q):                                      # m/s at q in km: air sinking, spreading
    return [q[0], q[1], -2 * q[2]]

def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]

def alpha(q, weight=True, n=20):                  # K(beta): integral of t^(k-1) (v(tq) x q)
    return [simpson(lambda t: (t if weight else 1) * cross(wind([t * c for c in q]), q)[i], n)
            for i in range(3)]

def curl(f, q):
    r = lambda i, j: rate(f, q, i, j)
    return [r(2, 1) - r(1, 2), r(0, 2) - r(2, 0), r(1, 0) - r(0, 1)]

q = [1.0, 1.0, 0.5]
div = sum(rate(wind, q, i, i) for i in range(3))
print(f"wind at (1, 1, 0.5) km: {', '.join(fx(c) for c in wind(q))} m/s; closed test d(beta) = div {fx(div)}")
a = alpha(q)
print(f"potential alpha = K(beta) at that point: {', '.join(fx(c) for c in a)}; formula (yz, -xz, 0)")
print(f"d(alpha) by finite differences: {', '.join(fx(c) for c in curl(alpha, q))}")
gate = [[1, 0, 0], [1, 1, 0], [1, 1, 1], [1, 0, 1], [1, 0, 0]]
flux = sum(wind([1, (j + 0.5) / 40, (k + 0.5) / 40])[0] for j in range(40) for k in range(40)) / 1600
circ = route(alpha, gate)
bad = route(lambda c: alpha(c, False), gate)
print(f"gate x = 1 km, 1 km by 1 km: flux {fx(flux)}, circulation of alpha {fx(circ)} (m/s)km^2")
print(f"mistake, dropping the t weight: circulation {fx(bad)}")

def angle(c):                                     # d(theta) round a carousel's centre
    r2 = c[0] ** 2 + c[1] ** 2
    return [-c[1] / r2, c[0] / r2]

print(f"angle form at (1, 2): dP/dy {fx(rate(angle, [1, 2], 0, 1))}, dQ/dx {fx(rate(angle, [1, 2], 1, 0))}")
box = [[1, -1], [1, 1], [-1, 1], [-1, -1], [1, -1]]
l8, l64 = route(angle, box, 8), route(angle, box, 64)
print(f"lap round the centre, Simpson 8 / 64 steps a side: {fx(l8)} / {fx(l64)}; 2 pi {fx(2 * math.pi)}")
src = lambda c: [ci / sum(e * e for e in c) ** 1.5 for ci in c]

def sph(n):                                       # flux out of the unit sphere, n rings
    total = 0.0
    for k in range(n):
        ph = (k + 0.5) * math.pi / n
        for m in range(2 * n):
            th = (m + 0.5) * math.pi / n
            c = [math.sin(ph) * math.cos(th), math.sin(ph) * math.sin(th), math.cos(ph)]
            total += sum(u * w for u, w in zip(src(c), c)) * math.sin(ph) * (math.pi / n) ** 2
    return total

print(f"point source: div at (1, 2, 2) {fx(sum(rate(src, [1, 2, 2], i, i) for i in range(3)))}; "
      f"sphere flux 50 / 100 rings {fx(sph(50))} / {fx(sph(100))}; 4 pi {fx(4 * math.pi)}")
assert abs(rate(lmsr, x, 0, 1) - rate(lmsr, x, 1, 0)) < 1e-9          # closed, by differences
assert abs(rate(lmsr, x, 0, 1) + p[0] * p[1] / B) < 1e-8             # against the formula
assert abs(r20 - exact) < 1e-6 and abs(stairs - exact) < 1e-6        # three roads, one potential
assert abs(cum_l[-1]) < 1e-6 and abs(-cum_n[-1] - defect * 1e4) < 1e-6  # loop = defect x area
assert abs(lap50) < 1e-6 and abs(lap150 - 2 * defect * 1e4) < 1e-6     # exact at any b; half the 300, twice the defect
assert all(abs(u - w) < 1e-6 for u, w in zip(a, [q[1] * q[2], -q[0] * q[2], 0]))
assert all(abs(u - w) < 1e-6 for u, w in zip(curl(alpha, q), wind(q)))   # d(alpha) = beta
assert abs(flux - circ) < 1e-9 and abs(bad - 1.5) < 1e-9
assert abs(l64 - 2 * math.pi) < 1e-6 and abs(sph(100) - 4 * math.pi) < 1e-3
print("ALL CHECKS PASS")
