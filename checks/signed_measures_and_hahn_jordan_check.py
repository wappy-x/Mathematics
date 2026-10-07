# Signed measures, Hahn and Jordan -- the check behind the card.  Standard
# library only; fractions keeps every die probability exact.
# The die: P fair, Q loaded (0.1, 0.1, 0.1, 0.1, 0.2, 0.4), nu = Q - P.
# Road 1: the definition -- test all 64 events for positivity by testing every
#         subset, as the Hahn proof's "largest positive set" does.
# Road 2: the sign of q_i - p_i face by face, as a density would give it.
# Road 3: total variation as the best sum |nu(E_1)| + ... over all 203 ways
#         to cut the six faces into blocks; and the distance by brute force.
# Bus waits: rate 1 against rate 2, by bisection and midpoint integration.
# The code checks these examples exactly; only the proof covers every space.
from fractions import Fraction as F
import math

p = [F(1, 6)] * 6
q = [F(1, 10)] * 4 + [F(2, 10), F(4, 10)]
nu = [qi - pi for pi, qi in zip(p, q)]
d6 = lambda x: f"{float(x):.6f}"
faces = lambda m: "{" + ", ".join(str(i + 1) for i in range(6) if m >> i & 1) + "}"
size = lambda w, m: sum((w[i] for i in range(6) if m >> i & 1), F(0))
subs = lambda m: [b for b in range(64) if b & m == b]

print("face: p_i fair | q_i loaded | nu = q_i - p_i")
for i in range(6):
    print(f"face {i + 1}: {d6(p[i])} | {d6(q[i])} | {d6(nu[i])}")

# Road 1: positive set = every subset has nu >= 0; negative = every subset <= 0
pos = [m for m in range(64) if all(size(nu, b) >= 0 for b in subs(m))]
neg = [m for m in range(64) if all(size(nu, b) <= 0 for b in subs(m))]
m_best = max(pos, key=lambda m: size(nu, m))
hahn = [m for m in pos if (63 ^ m) in neg]
print(f"road 1, events tested: 64; positive sets: {len(pos)}; negative sets: {len(neg)}")
print(f"road 1, largest nu over positive sets: {d6(size(nu, m_best))} at {faces(m_best)}")
print(f"road 1, Hahn splits found: {len(hahn)}: {faces(hahn[0])} and {faces(63 ^ hahn[0])}")

# Road 2: the sign of each face's difference
plus = sum(1 << i for i in range(6) if nu[i] > 0)
print(f"road 2, faces with q_i > p_i: {faces(plus)}; faces with q_i < p_i: {faces(63 ^ plus)}")
assert hahn == [plus] and pos == subs(plus) and neg == subs(63 ^ plus)

# Jordan: nu+(A) = nu(A n Omega+), nu-(A) = -nu(A n Omega-)
nplus = [max(x, F(0)) for x in nu]
nminus = [max(-x, F(0)) for x in nu]
jp, jm = size(nplus, 63), size(nminus, 63)
assert jp == size(nu, m_best)
print(f"Jordan, nu+ by face: {' '.join(d6(x) for x in nplus)}")
print(f"Jordan, nu- by face: {' '.join(d6(x) for x in nminus)}")
print(f"Jordan, nu+(Omega) {d6(jp)} | nu-(Omega) {d6(jm)} | nu(Omega) {d6(size(nu, 63))}")

def partitions(items):                         # every way to cut a list into blocks
    if not items:
        yield []
        return
    first, rest = items[0], items[1:]
    for part in partitions(rest):
        for k in range(len(part)):
            yield part[:k] + [[first] + part[k]] + part[k + 1:]
        yield [[first]] + part

parts = list(partitions(list(range(6))))
best_cut = max(sum(abs(sum(nu[i] for i in blk)) for blk in pt) for pt in parts)
tv_abs = sum(abs(x) for x in nu)
assert len(parts) == 203 and best_cut == jp + jm
print(f"total variation |nu|(Omega): nu+ + nu- {d6(jp + jm)} | sum |q_i - p_i| {d6(tv_abs)}"
      f" | best of {len(parts)} partitions {d6(best_cut)}")

gaps = [abs(size(q, m) - size(p, m)) for m in range(64)]
dist = max(gaps)
winners = [faces(m) for m in range(64) if gaps[m] == dist]
overlap = sum(min(a, b) for a, b in zip(p, q))
assert dist == tv_abs / 2 == 1 - overlap
print(f"distance, max over 64 events |Q(A) - P(A)|: {d6(dist)} at {' and '.join(winners)}")
print(f"distance, half of |nu|(Omega): {d6(tv_abs / 2)} | sum min(p_i, q_i): {d6(overlap)}, 1 minus it {d6(1 - overlap)}")
print(f"distance, Q({{5, 6}}) {d6(size(q, 48))} - P({{5, 6}}) {d6(size(p, 48))}")

# any other split nu = mu1 - mu2 costs more: here mu1 = Q, mu2 = P
extra = [qi - x for qi, x in zip(q, nplus)]
assert size(q, 63) + size(p, 63) > jp + jm
print(f"other split Q - P: Q(Omega) + P(Omega) = {d6(size(q, 63) + size(p, 63))}"
      f" against |nu|(Omega) {d6(jp + jm)}; Q - nu+ by face: {' '.join(d6(e) for e in extra)}")

# what breaks
s456 = size(nu, 0b111000)
print(f"breaks, {{4, 5, 6}}: nu = {d6(s456)} > 0, but nu({{4}}) = {d6(nu[3])}: not a positive set")
print(f"breaks, |nu(Omega)| read as total variation: {d6(abs(size(nu, 63)))}")
print(f"breaks, full sum read as the distance: {d6(tv_abs)}")
sign = lambda k: 1 if k % 2 == 0 else -1      # evens minus odds, counting measure
order2 = [k for t in range(1, 1001) for k in (4 * t - 2, 4 * t, 2 * t - 1)]
run = lambda ks: [sum(sign(k) for k in ks[:n]) for n in range(1, len(ks) + 1)]
nat, re2 = run(list(range(1, 3001))), run(order2)
assert nat[-1] == 0 and re2[-1] == 2000 - 1000
print(f"breaks, evens minus odds, order 1, 2, 3, ...: partial sums {' '.join(map(str, nat[:9]))} ... after 3000: {nat[-1]}")
print(f"breaks, evens minus odds, order 2, 4, 1, 6, 8, 3, ...: {' '.join(map(str, re2[:9]))} ... after 3000: {re2[-1]}")

# bus waits in minutes: P rate 1, Q rate 2; nu = Q - P has density fQ - fP
fP, fQ = (lambda x: math.exp(-x)), (lambda x: 2 * math.exp(-2 * x))
lo, hi = 0.0, 5.0                              # bisection for fQ = fP
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if fQ(mid) > fP(mid) else (lo, mid)
cross = (lo + hi) / 2
def midpoint(g, a, b, n):
    h = (b - a) / n
    return h * sum(g(a + (k + 0.5) * h) for k in range(n))
nu_plus = midpoint(lambda x: fQ(x) - fP(x), 0.0, cross, 100000)
tv_bus = midpoint(lambda x: abs(fQ(x) - fP(x)), 0.0, 40.0, 400000)
closed = math.exp(-math.log(2)) - math.exp(-2 * math.log(2))
scan = max((math.exp(-k / 1000) - math.exp(-2 * k / 1000), k / 1000) for k in range(1, 5001))
assert abs(cross - math.log(2)) < 1e-12 and abs(nu_plus - closed) < 1e-8
assert abs(tv_bus - 2 * closed) < 1e-6 and abs(scan[0] - closed) < 1e-6
print(f"bus, densities cross at (bisection): {cross:.6f} min; ln 2 = {math.log(2):.6f}")
print(f"bus, nu+ = integral of fQ - fP up to the crossing: {nu_plus:.6f}; closed form {closed:.6f}")
print(f"bus, best wait window [0, t] on a grid: t = {scan[1]:.3f}, Q - P = {scan[0]:.6f}")
print(f"bus, |nu|(Omega) = integral of |fQ - fP|: {tv_bus:.6f}; distance {tv_bus / 2:.6f}")
xs = [k / 4 for k in range(13)]
print("chart, wait x min:", " ".join(f"{x:.2f}" for x in xs))
print("chart, fP rate 1:", " ".join(f"{fP(x):.2f}" for x in xs))
print("chart, fQ rate 2:", " ".join(f"{fQ(x):.2f}" for x in xs))
print("figure, bar ends y (450 px per unit, baseline 140):", " ".join(str(140 - 450 * x) for x in nu))
print("ALL CHECKS PASS")
