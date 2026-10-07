# Translation invariance and the Vitali set: what a computer can check.
# Road 1 merges exact intervals; road 2 counts grid cells. Road 1 counts
# distinct fractions; road 2 sums Euler's totient from a sieve.
from fractions import Fraction as F
from math import sin, cos, pi

def length_by_merging(pieces):          # pieces: list of [a, b) with exact ends
    total, reach = F(0), None
    for a, b in sorted(pieces):
        if reach is None or a >= reach:
            total += b - a; reach = b
        elif b > reach:
            total += b - reach; reach = b
    return total

def length_by_grid(pieces, n=400):      # count cells of width 1/n whose midpoint is inside
    lo = min(min(a, b) for a, b in pieces); hi = max(max(a, b) for a, b in pieces)
    hits = 0
    for k in range(int(lo * n) - 1, int(hi * n) + 1):
        mid = F(2 * k + 1, 2 * n)
        if any(min(a, b) <= mid < max(a, b) for a, b in pieces): hits += 1
    return F(hits, n)

def rotate(pieces, q):                  # slide round the wheel, cutting at the seam 0
    out = []
    for a, b in pieces:
        a2, b2 = a + q, b + q
        if b2 <= 1: out.append((a2, b2))
        elif a2 >= 1: out.append((a2 - 1, b2 - 1))
        else: out += [(a2, F(1)), (F(0), b2 - 1)]
    return out

def show(pieces, l="[", r=")"): return " ".join(f"{l}{float(a):g},{float(b):g}{r}" for a, b in pieces)
A = [(F(1, 10), F(3, 10)), (F(1, 2), F(9, 10))]
lenA = length_by_merging(A)
print(f"set A {show(A)}, length by merging {float(lenA):g}, by grid {float(length_by_grid(A)):g}")
R = rotate(A, F(1, 4))
print(f"A rotated by 0.25: {show(R)}, length by merging {float(length_by_merging(R)):g}, by grid {float(length_by_grid(R)):g}")
assert length_by_grid(A) == lenA and length_by_grid(R) == lenA
spread = {length_by_grid(rotate(A, F(k, 20))) for k in range(20)}
print(f"A rotated by k/20, k = 0..19: {len(spread)} distinct length(s), {float(min(spread)):g} to {float(max(spread)):g}")
assert spread == {lenA}
S3 = [(3 * a, 3 * b) for a, b in A]
print(f"A stretched by 3: {show(S3)}, length {float(length_by_merging(S3)):g} = 3 x {float(lenA):g}")
assert length_by_grid(S3) == 3 * length_by_grid(A)
Sm = [(-2 * b, -2 * a) for a, b in A]
print(f"A stretched by -2: {show(Sm, "(", "]")}, length {float(length_by_merging(Sm)):g}; c times length gives {float(-2 * lenA):g}")
assert length_by_merging(Sm) == length_by_grid(Sm) == 2 * lenA

# A finite wheel of 360 positions and 12 rotations (steps of 30): choice sets tile it.
N, STEP = 360, 30
for name, pick in (("smallest in each group", lambda r: r), ("scrambled choice", lambda r: r + STEP * ((7 * r) % 12))):
    V = [pick(r) for r in range(STEP)]
    cover = [0] * N
    for j in range(N // STEP):
        for v in V: cover[(v + STEP * j) % N] += 1
    assert all(c == 1 for c in cover)
    print(f"finite wheel, {name}: {len(V)} points, size {len(V) / N:.4f}, 12 copies cover every position exactly {min(cover)} time(s), total {12 * F(len(V), N)}")
V = list(range(STEP))
d0 = [1 if 0 in {(v + STEP * j) % N for v in V} else 0 for j in range(12)]
print(f"point mass at 0: gives V {d0[0]}, V rotated by 30 {d0[1]}, sum over 12 copies {sum(d0)}")

# The real wheel: rational rotations with denominator <= n that fit as disjoint copies.
def by_fractions(n): return len({F(a, d) for d in range(1, n + 1) for a in range(d)})
def by_totient(n):
    phi = list(range(n + 1))
    for p in range(2, n + 1):
        if phi[p] == p:
            for m in range(p, n + 1, p): phi[m] -= phi[m] // p
    return sum(phi[1:])
for n in list(range(1, 11)) + [100]:
    k1, k2 = by_fractions(n), by_totient(n)
    assert k1 == k2
    print(f"denominators <= {n}: {k1} disjoint copies of V fit, so a measurable V would have length <= 1/{k1} = {1 / k1:.6f}")

# Any positive size c: total of the copies passes 1; size 0: total stays 0.
for num, den in ((1, 10), (1, 100), (1, 1000)):
    c, total, copies = F(num, den), F(0), 0
    while total <= 1: total += c; copies += 1
    assert copies == den // num + 1
    print(f"size {float(c):g}: total passes 1 after {copies} copies, and grows without bound")
print(f"size 0: total after 1000000 copies {sum(F(0) for _ in range(10 ** 6))}")

# figure: wheel of radius 75 at (180,120); A on radius 60, A rotated by 0.25 on radius 90.
def pt(r, x): return f"({180 + r * sin(2 * pi * x):.1f},{120 - r * cos(2 * pi * x):.1f})"
for r, arcs in ((60, [(0.1, 0.3), (0.5, 0.9)]), (90, [(0.35, 0.55), (0.75, 1.15)])):
    print("figure," + ",".join(f" r={r} arc {a:g}-{b:g} from {pt(r, a)} to {pt(r, b)}" for a, b in arcs))
