# Integrable functions -- the check behind the card.  Standard library only.
# River bed against a 0.5 m marker: h(x) = 4x(1 - x) - 0.5 metres, 0 <= x <= 1 km.
# Road 1: exact algebra on numbers p + q*sqrt(2), p and q fractions, using the
#   antiderivative and the crossing points 1/2 -+ sqrt(2)/4.
# Road 2: Lebesgue's road, chopping the depth axis: lower simple functions built
#   from the lengths of the level sets {h >= t}, which are square roots.
# Road 3: Riemann's road, chopping the x axis: midpoint sums on 2^16 cells.
# The code checks these functions and finite stages; the theorems are the proof's work.
from fractions import Fraction as Q
from math import sqrt

class R2:                                       # p + q*sqrt(2), kept exact
    def __init__(s, p, q=0): s.p, s.q = Q(p), Q(q)
    def __add__(s, o): return R2(s.p + o.p, s.q + o.q)
    def __sub__(s, o): return R2(s.p - o.p, s.q - o.q)
    def __mul__(s, o): return R2(s.p * o.p + 2 * s.q * o.q, s.p * o.q + s.q * o.p)
    def __float__(s): return float(s.p) + float(s.q) * sqrt(2)
    def __str__(s): return f"{s.p} + ({s.q})sqrt2"

def H(x):                                       # antiderivative of h: 2x^2 - (4/3)x^3 - x/2
    x2 = x * x
    return R2(2) * x2 - R2(Q(4, 3)) * x2 * x - R2(Q(1, 2)) * x
f10 = lambda v: f"{float(v):.10f}"

print("four reaches of 250 m, midpoint depths | d | h = d - 0.5")
d4 = [Q(7, 16), Q(15, 16), Q(15, 16), Q(7, 16)]
h4 = [v - Q(1, 2) for v in d4]
mean = lambda vs: sum(Q(1, 4) * v for v in vs)
pos = lambda vs: mean([max(v, 0) for v in vs])
neg = lambda vs: mean([max(-v, 0) for v in vs])
print(f"four reaches: d = {', '.join(map(str, d4))} | h = {', '.join(map(str, h4))}")
print(f"four reaches: h+ {pos(h4)}, h- {neg(h4)}, net {pos(h4) - neg(h4)}, |h| {mean(map(abs, h4))}, "
      f"d {mean(d4)}, d - 1/2 {mean(d4) - Q(1, 2)}")
assert pos(h4) - neg(h4) == mean(d4) - Q(1, 2) == Q(3, 16)
for a in range(-3, 4):
    for b in range(-3, 4):
        z = [a * u + b * v for u, v in zip(d4, h4)]
        assert pos(z) - neg(z) == a * mean(d4) + b * mean(h4)   # parts road against linearity
        assert abs(mean(z)) <= mean(map(abs, z))
print("four reaches: 49 pairs (a, b), a*d + b*h: parts difference equals a*int d + b*int h")

a, b, zero, one = R2(Q(1, 2), Q(-1, 4)), R2(Q(1, 2), Q(1, 4)), R2(0), R2(1)
P = H(b) - H(a)                                  # h+ lives between the crossings
N = zero - ((H(a) - H(zero)) + (H(one) - H(b)))  # h- lives outside them
by_d = R2(2 - Q(4, 3)) - R2(Q(1, 2))             # linearity: int d - int 0.5, no crossings used
assert P.p == 0 and P.q == Q(1, 6) and N.p == Q(-1, 6) and (P - N).q == 0
assert (P - N).p == by_d.p
print(f"crossings: x = {float(a):.10f} and {float(b):.10f} km; channel {float(b) - float(a):.10f} km, "
      f"shoals together {1 - (float(b) - float(a)):.10f} km")
print(f"exact: int h+ = {P} = {f10(P)}")
print(f"exact: int h- = {N} = {f10(N)}")
print(f"exact: int h = {P - N} = {f10(P - N)}; int d - 0.5 = {by_d.p}; int |h| = {P + N} = {f10(P + N)}")
m3 = [1000 * float(v) for v in (P, N, P + N, P - N)]
print("per metre of width, m^3: fill {:.1f}, dredge {:.1f}, moved {:.1f}, net {:.1f}".format(*m3))

print("Lebesgue lower sums, levels 2^-n: n | h+ | gap | h- | gap")
for n in (2, 4, 8, 12, 16, 20):
    step, sp, sn, k = 2.0 ** -n, 0.0, 0.0, 1
    while k * step <= 0.5:
        sp += step * sqrt(0.5 - k * step)        # length of {h >= t} is sqrt(0.5 - t)
        sn += step * (1 - sqrt(0.5 + k * step))  # length of {h <= -t} is 1 - sqrt(0.5 + t)
        k += 1
    gp, gn = float(P) - sp, float(N) - sn
    assert 0 <= gp <= step * sqrt(2) / 2 and 0 <= gn <= step * (1 - sqrt(2) / 2)
    print(f"lower sums, n = {n}: {sp:.10f} | {gp:.10f} | {sn:.10f} | {gn:.10f}")

cells = 2 ** 16
rp = rn = 0.0
for i in range(cells):
    x = (i + 0.5) / cells
    v = 4 * x * (1 - x) - 0.5
    rp, rn = rp + max(v, 0.0) / cells, rn + max(-v, 0.0) / cells
assert abs(rp - float(P)) < 1e-8 and abs(rn - float(N)) < 1e-8
print(f"midpoint sums, 2^16 cells: h+ {rp:.10f}, h- {rn:.10f}, net {rp - rn:.10f}, |h| {rp + rn:.10f}")
assert float(P - N) <= 2 / 3 and abs(float(P - N)) <= float(P + N)
print(f"monotone: int h = {float(P - N):.10f} <= int d = 0.6666666667; triangle: |int h| <= int |h| = {f10(P + N)}")

print("spike s(x) = 1/(2 sqrt x) on (0, 1], int s = 1: eps | N | tail 1/(4N) | tail by cells | delta | worst window")
for den in (10, 100):
    eps = Q(1, den)
    Nc = den // 2 + 1                            # smallest whole N with 1/(4N) < eps/2
    delta = eps / (2 * Nc)
    capped = 0.0
    for i in range(cells):
        capped += min(1 / (2 * sqrt((i + 0.5) / cells)), Nc) / cells
    tail = 1 - capped
    worst = max(sqrt(c / 1000 + float(delta)) - sqrt(c / 1000) for c in range(0, 1000))
    assert abs(tail - 1 / (4 * Nc)) < 1e-6          # truncation tail: cells against 1/(4N)
    assert worst < float(eps)                        # every window of length delta carries less than eps
    print(f"spike, eps {eps}: N {Nc} | {1 / (4 * Nc):.6f} | {tail:.6f} | {delta} | {worst:.10f}")

ln2 = 0.0
for k in range(1, 61):
    ln2 += 1 / (k * 2.0 ** k)
print(f"ln 2 by the series sum 1/(k 2^k): {ln2:.6f}; 1.5 ln 2: {1.5 * ln2:.6f}")
for k in (10, 20, 40):
    low = sum(Q(1, 2 ** (j + 1)) * 2 ** j for j in range(k))   # piece length times least value of 1/x
    cs = 0.0                                     # delta = 1: midpoint sums of 1/x, 200 cells per piece
    for j in range(k):
        a0 = 2.0 ** -(j + 1); wd = a0 / 200
        cs += sum(wd / (a0 + (i + 0.5) * wd) for i in range(200))
    print(f"1/x on (delta/2^{k}, delta]: at least {low}; by cells {cs:.4f}; exactly {k} ln 2 = {k * ln2:.4f}")
    assert low <= cs and abs(cs - k * ln2) < 1e-4

print("endless bed w = +1, -1/2, +1/3, ... one km each: km | int w, in order | int w+ | int w-")
S = Wp = Wm = 0.0
chart_order = []
for n in range(1, 100001):
    v = (1 if n % 2 else -1) / n
    S, Wp, Wm = S + v, Wp + max(v, 0), Wm + max(-v, 0)
    if n % 3 == 0 and n <= 30: chart_order.append(S)
    if n in (10, 100, 1000, 10000, 100000): print(f"in order, {n} km: {S:.6f} | {Wp:.6f} | {Wm:.6f}")
assert abs(S - ln2) < 1 / 100000
for j in range(1, 17):                           # each dyadic block of km adds at least 1/4 to both parts
    blk = range(2 ** j + 1, 2 ** (j + 1) + 1)
    assert sum(1 / n for n in blk if n % 2) >= 0.25            # pools: at least 2^(j-1) terms of at least 1/2^(j+1)
    assert sum(1 / n for n in blk if n % 2 == 0) >= 0.25       # bars: the same count
R, chart_re, odd, even = 0.0, [], 1, 2
for m in range(1, 100001):                       # two pools, then one bar
    R += 1 / odd + 1 / (odd + 2) - 1 / even
    odd, even = odd + 4, even + 2
    if m <= 10: chart_re.append(R)
    if m in (10, 1000, 100000): print(f"two pools then a bar, {3 * m} pieces: {R:.6f}")
assert abs(R - 1.5 * ln2) < 1e-4
print("chart, in order after 3..30 km:", " ".join(f"{v:.2f}" for v in chart_order))
print("chart, rearranged after 1..10 blocks:", " ".join(f"{v:.2f}" for v in chart_re), f"| levels {ln2:.2f} {1.5 * ln2:.2f}")

px = lambda x, dep: (30 + 300 * x, 30 + 160 * dep)
ctrl = R2(Q(1, 4), Q(-1, 8))                     # (2 - sqrt2)/8: tangents at 0 and at the crossing meet here
pts = [px(float(a), 0.5), px(float(b), 0.5), px(float(ctrl), 1 - sqrt(2) / 2), px(1 - float(ctrl), 1 - sqrt(2) / 2)]
print("figure, crossings", " ".join(f"{u:.2f} {w:.2f}" for u, w in pts[:2]), "| shoal controls",
      " ".join(f"{u:.2f} {w:.2f}" for u, w in pts[2:]), "| bed 30 30 Q 180 350 330 30 | channel control 180 270")
print("ALL CHECKS PASS")
