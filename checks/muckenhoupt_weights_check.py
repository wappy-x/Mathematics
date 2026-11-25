# Muckenhoupt weights -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  Nothing imported knows the answer.
import math

def F(x, e):                       # antiderivative of |x|^e, for e > -1
    return math.copysign(abs(x) ** (e + 1) / (e + 1), x)

def avg_exact(a, b, e):            # road 1: average of |x|^e over [a, b], closed form
    return (F(b, e) - F(a, e)) / (b - a)

def simpson(g, lo, hi, n=2000):
    h = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4 if k % 2 else 2) * g(lo + k * h) for k in range(1, n))
    return s * h / 3

def from_zero(c, e):               # integral of x^e over [0, c], by x = c u^8: no antiderivative
    return simpson(lambda u: 8 * c ** (e + 1) * u ** (8 * e + 7), 0.0, 1.0)

def avg_simpson(a, b, e):          # road 2: the same average by Simpson's rule
    side = lambda x: math.copysign(from_zero(abs(x), e), x)
    return (side(b) - side(a)) / (b - a)

def Q(a, b, g, avg=avg_exact):     # the A2 product on [a, b]: average of w times average of 1/w
    return avg(a, b, g) * avg(a, b, -g)

def a2_constant(g):                # sup of Q over all intervals; by scaling, intervals [u, 1]
    u0 = max((k / 1000 for k in range(-1000, 1000)), key=lambda u: Q(u, 1, g))
    lo, hi, r = u0 - 0.001, min(u0 + 0.001, 0.9999), (math.sqrt(5) - 1) / 2
    for _ in range(60):            # golden-section search on the best grid cell
        m1, m2 = hi - r * (hi - lo), lo + r * (hi - lo)
        if Q(m1, 1, g) < Q(m2, 1, g): lo = m1
        else: hi = m2
    return (lo + hi) / 2, Q((lo + hi) / 2, 1, g)

G = 0.5
print(f"weight w(x) = |x|^{G}")
for a in (0.01, 1, 100):          # intervals [0, a] at three scales
    e1, e2, s = avg_exact(0, a, G), avg_exact(0, a, -G), Q(0, a, G, avg_simpson)
    print(f"I=[0,{a}]: avg w={e1:.6f} avg 1/w={e2:.6f} product={e1 * e2:.6f} simpson={s:.6f}")
    assert abs(e1 * e2 - 1 / (1 - G * G)) < 1e-12 and abs(s - e1 * e2) < 1e-9
for h in (1, 0.5, 0.1):
    e, s = Q(2 - h, 2 + h, G), Q(2 - h, 2 + h, G, avg_simpson)
    print(f"centred at 2, half-width {h}: avg w={avg_exact(2 - h, 2 + h, G):.6f} avg 1/w={avg_exact(2 - h, 2 + h, -G):.6f} product={e:.6f} simpson={s:.6f}")
    assert abs(e - s) < 1e-9 and 1 < e < 1 / (1 - G * G)
print(f"symmetric [-1,1]: product={Q(-1, 1, G):.6f}")
u, A2 = a2_constant(G)
brute = max(Q(i / 20, j / 20, G) for i in range(-60, 61) for j in range(i + 1, 61))
print(f"A2 constant: worst interval [{u:.4f}, 1], [w]_A2={A2:.6f}; grid of 7260 intervals: {brute:.6f}")
s0 = -(2 - math.sqrt(3)) ** 2     # road 3, by hand: the worst left end is -(2 - sqrt 3)^2, product 3/2
r0 = math.sqrt(-s0)
print(f"by hand: r = 2 - sqrt 3 = {r0:.6f}, y = r/(1+r^2) = {r0 / (1 + r0 * r0):.6f}, left end {s0:.6f}, product {Q(s0, 1, G):.6f}")
assert abs(u - s0) < 1e-6 and abs(A2 - 1.5) < 1e-12 and brute <= A2 + 1e-12 and A2 - brute < 2e-3
US = (-1, -0.6, -0.3, -0.2, -0.15, -0.1, -0.07, -0.05, -0.03, -0.01, 0, 0.1, 0.3, 0.5, 0.7, 0.9)
for g in (0.5, 0.75):
    print(f"chart gamma={g}: " + ", ".join(f"{Q(x, 1, g):.4f}" for x in US))
for g in (0.0, 0.25, 0.5, 0.75, 0.9, 0.99):
    c = a2_constant(g)[1]
    print(f"table gamma={g:.2f}: [w]_A2={c:.4f}  on [0,1]: {1 / (1 - g * g):.4f}")
    fine = max(Q(k / 20000, 1, g) for k in range(-20000, 20000))   # road 2: exhaustive grid of left ends
    assert c >= 1 / (1 - g * g) - 1e-12 and fine <= c + 1e-12 and c - fine < 1e-4 * c
M = lambda x: 1.0 if 0 <= x <= 1 else 1 / (2 * max(x, 1 - x))   # Mg for the gate g on [0,1]
for x in (-0.5, 0.3, 1.5):          # brute force: largest centred average over 40000 half-widths
    b = max((min(x + h, 1) - max(x - h, 0)) / (2 * h) for h in (k / 10000 for k in range(1, 40001)))
    print(f"gate: Mg({x}) = {M(x):.6f}, brute force {b:.6f}")
    assert abs(b - M(x)) < 1e-4
wE, wE2 = avg_exact(-1, 2, G) * 3, avg_simpson(-1, 2, G) * 3
wr = wE / 16 / (2 / 3)              # w-length times alpha^2, over the weighted energy 2/3
print(f"gate: w-length where Mg > 1/4 = {wE:.6f} (simpson {wE2:.6f}); weak ratio {wr:.6f}")
print(f"gate: weak bound 9 [w]_A2^2 = {9 * A2 * A2:.4f}; ratio to bound {wr / (9 * A2 * A2):.4f}")
left = simpson(lambda v: math.exp(1.5 * v) / (4 * (1 + math.exp(v)) ** 2), -60.0, 80.0, 20000)
tot = 2 / 3 + 0.5 + left            # weighted energy of Mg: on the gate, right tail, left tail
print(f"gate: left tail {left:.6f} (pi/8 = {math.pi / 8:.6f}); energy of Mg {tot:.6f}; strong ratio {math.sqrt(tot / (2 / 3)):.4f}")
assert abs(wE - wE2) < 1e-9 and abs(left - math.pi / 8) < 1e-9
EPS = ((1e-2, "1e-2"), (1e-4, "1e-4"), (1e-8, "1e-8"))
for eps, lab in EPS:               # gamma = 1: the average of 1/w on [0,1] diverges
    print(f"gamma=1, 1/w counted from {lab}: product on [0,1] = {math.log(1 / eps) / 2:.6f}")

def test_ratio(g, eps):            # f = 1/w on [eps,1]; Mf(x) >= average over [0, 2x]
    S = lambda m: math.log(m / eps) if g == 1 else (m ** (1 - g) - eps ** (1 - g)) / (1 - g)
    num = sum(simpson(lambda v: S(min(2 * math.exp(v), 1)) ** 2 * math.exp((g - 1) * v) / 4, lo, hi)
              for lo, hi in ((math.log(eps), -math.log(2)), (-math.log(2), 0.0)))
    return math.sqrt(num / S(1.0))
for eps, lab in EPS:
    L, r1, r5 = math.log(1 / eps), test_ratio(1, eps), test_ratio(0.5, eps)
    exact = math.sqrt(((L ** 3 - math.log(2) ** 3) / 12 + L * L * math.log(2) / 4) / L)
    print(f"test eps={lab}: gamma=1 M-ratio>={r1:.4f} (closed form {exact:.4f}), gamma=0.5 M-ratio>={r5:.4f}")
    assert abs(r1 - exact) < 1e-6
print(f"gamma=0.5 limit as eps -> 0: sqrt(2 sqrt 2 - 1) = {math.sqrt(2 * math.sqrt(2) - 1):.4f}")
assert abs(r5 - math.sqrt(2 * math.sqrt(2) - 1)) < 1e-3

def hilbert_ratio(eps):            # gamma = 1, same f: |Hf| at x = -t is ln((t+eps)/(eps(1+t)))/(pi t)
    num = simpson(lambda v: math.log((math.exp(v) + eps) / (eps * (1 + math.exp(v)))) ** 2,
                  math.log(eps) - 30, 0.0, 20000) / math.pi ** 2
    return math.sqrt(num / math.log(1 / eps))
def hilbert_ratio2(eps):           # road 2: |Hf| as log1p(t/eps) - log1p(t), cut 40 below ln eps, 30000 steps
    num = simpson(lambda v: (math.log1p(math.exp(v) / eps) - math.log1p(math.exp(v))) ** 2,
                  math.log(eps) - 40, 0.0, 30000) / math.pi ** 2
    return math.sqrt(num / math.log(1 / eps))
for t in (0.001, 0.1, 0.5):         # road 2 for Hf: the kernel integral of 1/(y(t+y)) over [1e-4, 1], y = e^v
    k = simpson(lambda v: 1 / (t + math.exp(v)), math.log(1e-4), 0.0, 20000) / math.pi
    c = math.log((t + 1e-4) / (1e-4 * (1 + t))) / (math.pi * t)
    print(f"gamma=1, eps=1e-4: |Hf(-{t})| by kernel {k:.6f}, closed form {c:.6f}")
    assert abs(k - c) < 1e-8
hr, hr2 = [hilbert_ratio(e) for e, _ in EPS], [hilbert_ratio2(e) for e, _ in EPS]
print("gamma=1 H-ratio on x<0: " + ", ".join(f"{x:.4f}" for x in hr) + "; second cut-off: " + ", ".join(f"{x:.4f}" for x in hr2))
assert hr[0] < hr[1] < hr[2] and hr[2] > 3
assert all(abs(x - y) < 1e-6 for x, y in zip(hr, hr2))

for p in (2.0, 1.75, 1.6, 1.55):  # openness: |x|^0.5 is in A_p for every p above 1.5
    e1, e2 = avg_exact(0, 1, G), avg_exact(0, 1, -G / (p - 1))
    print(f"A_p product on [0,1], p={p:.2f}: {e1 * e2 ** (p - 1):.6f}")

def osc_log(a, b):                 # mean oscillation of ln x on [a, b], 0 <= a < b, by Simpson
    xlx = lambda x: x * math.log(x) - x if x > 0 else 0.0
    m = (xlx(b) - xlx(a)) / (b - a)            # the mean of ln x on [a, b]
    g = lambda x: abs(math.log(x) - m) if x > 0 else 0.0
    c = math.exp(m)                            # where ln x crosses its mean: split there
    return sum(simpson(lambda u: g(lo + (hi - lo) * u ** 8) * 8 * (hi - lo) * u ** 7, 0.0, 1.0, 20000)
               for lo, hi in ((a, c), (c, b))) / (b - a)
o = osc_log(0, 1)
print(f"BMO: mean oscillation of ln|x| on [0,1] = {o:.6f} (2/e = {2 / math.e:.6f}); on [1,3] = {osc_log(1, 3):.6f}")
print(f"log w = {G} ln|x|: oscillation {G * o:.6f} <= ln([w]_A2 + 1) = {math.log(A2 + 1):.6f}")
assert abs(o - 2 / math.e) < 1e-6 and G * o <= math.log(A2 + 1)
print("ALL CHECKS PASS")
