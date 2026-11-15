# Inner products and Hilbert spaces -- the check behind the card.  Standard library only.
# Two 8-sample clips (thousands of counts, 8,000 samples a second): B hears A one sample
# late, plus a little noise.  Roads: inner products summed directly; Cauchy-Schwarz rebuilt
# from the split y = t x + r; polarization from meter readings alone; the parallelogram law
# on four meters, exact and on random pairs; truncations of 1/n against pi^2/6.
from fractions import Fraction as Fr
import math

A, B = [2, 5, 3, -1, -4, -3, -2, 0], [1, 2, 5, 3, -1, -3, -3, -4]
ip = lambda x, y: sum(a.conjugate() * b for a, b in zip(x, y))   # conjugate the first slot
sq2 = lambda x: ip(x, x).real                                    # squared RMS-type length
n2, n1 = lambda x: math.sqrt(sq2(x)), lambda x: sum(abs(a) for a in x)
npk = lambda x: max(abs(a) for a in x)                           # the peak meter
pre = lambda x: [Fr(a) - Fr(b, 2) for a, b in zip(x, [0] + x[:-1])]
sqE = lambda x: sum(a * a for a in pre(x))                       # pre-emphasised energy
add = lambda x, y, c=1: [a + c * b for a, b in zip(x, y)]
shift = lambda x, k: [0] * k + x[:len(x) - k]
f4 = lambda v: f"{v:.4f}"
cx = lambda z: f"{int(z.real)}{'+' if z.imag >= 0 else '-'}{abs(int(z.imag))}i"
I = [1, 1j, -1, -1j]                                             # i to the powers 0, 1, 2, 3

# 1. correlation of the two clips at each lag: the cosine of the angle between them
print("lag,inner product,squared lengths,correlation")
for k in range(4):
    x = shift(A, k)
    print(f"lag {k},{ip(x, B)},{sq2(x):.0f} {sq2(B):.0f},{f4(ip(x, B) / (n2(x) * n2(B)))}")
best = max(range(4), key=lambda k: ip(shift(A, k), B) / n2(shift(A, k)))
print(f"delay,{best} sample,{1000 * best / 8000:.3f} ms")
assert best == 1                                                 # B is A, one sample late
# 2. Cauchy-Schwarz as a split: B = t (shifted A) + r with r perpendicular to shifted A
for k in (0, 1):
    x = shift(A, k)
    t = Fr(ip(x, B), ip(x, x)); r = [b - t * a for a, b in zip(x, B)]
    assert ip(x, r) == 0 and sq2(B) == sq2(r) + t * t * sq2(x)   # Pythagoras, exactly
    gap = sq2(x) * sq2(B) - ip(x, B) ** 2
    assert gap == sq2(x) * sq2(r)                                # the slack is the remainder
    print(f"split lag {k},t {t},r squared {float(sq2(r)):.4f},bound {f4(n2(x) * n2(B))},gap {gap} = {sq2(x) * sq2(B)} - {ip(x, B) ** 2}")
print("lag 1 remainder,", [int(a) for a in r])
assert r == [1, 0, 0, 0, 0, 1, 0, -2]                            # the noise, recovered
# 3. polarization: the inner product from four meter readings, real and complex
S, D = add(A, B), add(A, B, -1)
print(f"polarize real,{sq2(S)} {sq2(D)},{(sq2(S) - sq2(D)) // 4}")
assert (sq2(S) - sq2(D)) / 4 == ip(A, B) == 43
dft = lambda x: [sum(a * I[(-k * n) % 4] for n, a in enumerate(x)) for k in range(3)]
X, Y = dft(A[:4]), dft(B[:4])                                   # half-spectrum of the first frame
print("frame coefficients,", " ".join(cx(z) for z in X), "|", " ".join(cx(z) for z in Y))
reads = [sq2(add(X, Y, I[m])) for m in range(4)]
pol = sum(I[-m % 4] * reads[m] for m in range(4)) / 4
print("polarize complex,", " ".join(f"{v:.0f}" for v in reads), cx(pol), "direct", cx(ip(X, Y)))
assert pol == ip(X, Y) == 98 - 25j                              # four lengths give the product
z = ip(X, Y)
print(f"complex CS,squared lengths {sq2(X):.0f} {sq2(Y):.0f},{abs(z) ** 2:.0f} {sq2(X) * sq2(Y):.0f},gap {sq2(X) * sq2(Y) - abs(z) ** 2:.0f},{f4(abs(z))} {f4(n2(X) * n2(Y))}")
assert abs(z) ** 2 < sq2(X) * sq2(Y)
print("no conjugate,", cx(X[1] * X[1]), "|", cx(sum(a * a for a in X)), "against", f"{sq2(X):.0f}",
      "| real polarization,", f"{(sq2(add(X, Y)) - sq2(add(X, Y, -1))) / 4:.0f}")
# 4. the parallelogram test on four meters, on the clips and on the two unit samples
E0, E1 = [1, 0], [0, 1]
print("meters on A B A+B A-B,sum", " ".join(str(n1(v)) for v in (A, B, S, D)) + ",peak", " ".join(str(npk(v)) for v in (A, B, S, D)))
for name, nm in (("RMS", sq2), ("pre-emphasis", sqE), ("sum", lambda x: n1(x) ** 2), ("peak", lambda x: npk(x) ** 2)):
    lhs, rhs = nm(S) + nm(D), 2 * nm(A) + 2 * nm(B)
    l0, r0 = nm(add(E0, E1)) + nm(add(E0, E1, -1)), 2 * nm(E0) + 2 * nm(E1)
    print(f"parallelogram {name},clips {float(lhs):.2f} vs {float(rhs):.2f},unit samples {float(l0):.2f} vs {float(r0):.2f}")
assert n1(S) ** 2 + n1(D) ** 2 == 1924 and npk(S) ** 2 + npk(D) ** 2 == 80   # both fail
print("one lucky pair (A and 2A), sum meter,", n1(add(A, A, 2)) ** 2 + n1(add(A, A, -2)) ** 2,
      2 * n1(A) ** 2 + 2 * n1(add(A, A)) ** 2)
pk = lambda x, y: Fr(npk(add(x, y)) ** 2 - npk(add(x, y, -1)) ** 2, 4)
print(f"polarized peak,A B {pk(A, B)},A+B B {pk(add(A, B), B)},B B {pk(B, B)},sum of parts {pk(A, B) + pk(B, B)}")
assert pk(add(A, B), B) != pk(A, B) + pk(B, B)                  # not additive: no inner product
# 5. the pre-emphasis meter's hidden inner product, recovered by polarization
pE = lambda x, y: (sqE(add(x, y)) - sqE(add(x, y, -1))) / 4
direct = sum(a * b for a, b in zip(pre(A), pre(B)))
G = [[pE([int(i == j) for j in range(3)], [int(k == j) for j in range(3)]) for k in range(3)] for i in range(3)]
print("pre-emphasis,", f"{float(sqE(A)):.2f} {float(sqE(B)):.2f}", f"polarized {float(pE(A, B)):.2f} direct {float(direct):.2f}")
print("pre-emphasis Gram, three samples,", " | ".join(" ".join(str(g) for g in row) for row in G))
assert pE(A, B) == direct and G[0][0] == Fr(5, 4) and G[0][1] == Fr(-1, 2) and G[0][2] == 0
# 6. random pairs from SplitMix64, seed 20261115: worst Cauchy-Schwarz ratio, worst law defect
st = [20261115]
def rnd():
    st[0] = (st[0] + 0x9E3779B97F4A7C15) % 2 ** 64; z = st[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return (z ^ (z >> 31)) >> 11
u = lambda: rnd() / 2 ** 52 - 1.0
worst, dfl = 0.0, {"RMS": 0.0, "sum": 0.0, "peak": 0.0}
for _ in range(2000):
    x = [complex(u(), u()) for _ in range(8)]; y = [complex(u(), u()) for _ in range(8)]
    worst = max(worst, abs(ip(x, y)) / (n2(x) * n2(y)))
    for name, nm in (("RMS", n2), ("sum", n1), ("peak", npk)):
        q = nm(add(x, y)) ** 2 + nm(add(x, y, -1)) ** 2 - 2 * nm(x) ** 2 - 2 * nm(y) ** 2
        dfl[name] = max(dfl[name], abs(q) / (nm(x) ** 2 + nm(y) ** 2))
print(f"random 2000 complex pairs,worst ratio {f4(worst)},law defect RMS sum peak {f4(dfl['RMS'])} {f4(dfl['sum'])} {f4(dfl['peak'])}")
assert worst < 1 and dfl["RMS"] < 1e-12 and dfl["sum"] > 0.1 and dfl["peak"] > 0.1
# 7. completeness: the list 1, 1/2, 1/3, ... cut at N; the cuts settle, the limit is not a finite list
full = math.pi * math.pi / 6
for N in (10, 100, 1000, 10000):
    sN = sum(1 / (n * n) for n in range(1, N + 1)); gapN = sum(1 / (n * n) for n in range(N + 1, 2 * N + 1))
    print(f"truncate N {N},energy {sN:.6f},N times missing {N * (full - sN):.4f},distance to 2N {math.sqrt(gapN):.6f}")
    assert abs(N * (full - sN) - 1) < 1.0 / N                    # the missing energy is about 1/N
print(f"limit energy pi^2/6,{full:.6f}")
# 8. figure: unit balls of four meters on two samples, radius in four directions
h = math.sqrt(0.5)
nE2 = lambda v: math.sqrt(v[0] * v[0] + (v[1] - v[0] / 2) * (v[1] - v[0] / 2))
for name, nm in (("sum", n1), ("RMS", n2), ("peak", npk), ("pre-emphasis", nE2)):
    print(f"figure,{name} radius at 0 45 90 135 degrees," + " ".join(f4(1 / nm(d)) for d in ([1.0, 0.0], [h, h], [0.0, 1.0], [-h, h])))
lo, hi = (9 - math.sqrt(17)) / 8, (9 + math.sqrt(17)) / 8         # eigenvalues of [[5/4,-1/2],[-1/2,1]]
ax = [1.0, 2 * (1.25 - lo)]; ax = [a / math.sqrt(ax[0] ** 2 + ax[1] ** 2) for a in ax]
print(f"figure,pre-emphasis ellipse semi-axes {f4(1 / math.sqrt(lo))} {f4(1 / math.sqrt(hi))},tilt {math.degrees(math.atan2(ax[1], ax[0])):.1f} degrees")
assert abs(1 / nE2(ax) - 1 / math.sqrt(lo)) < 1e-12               # eigen formula meets the meter
# 9. try changing: the speech-standard coefficient 0.97; a 4-power meter
pre97 = lambda x: sum((Fr(a) - Fr(97 * b, 100)) ** 2 for a, b in zip(x, [0] + x[:-1]))
print(f"try coefficient 0.97,clips {float(pre97(S) + pre97(D)):.4f} vs {float(2 * pre97(A) + 2 * pre97(B)):.4f}")
assert pre97(S) + pre97(D) == 2 * pre97(A) + 2 * pre97(B)        # any fixed filter keeps the law
n4sq = lambda x: math.sqrt(sum(a ** 4 for a in x))
print(f"try 4-power meter,clips {n4sq(S) + n4sq(D):.2f} vs {2 * n4sq(A) + 2 * n4sq(B):.2f}")
print("ALL CHECKS PASS")
