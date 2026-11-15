# The test spaces -- the check behind the card.  Standard library only.
# Part 1 lists every topology on a set of 1 to 4 points and tries four claims on each one.
# Part 2 works on the Cantor set through base-3 addresses that use only the digits 0 and 2.
# Every number is an exact integer; Cantor positions are counted in units of 1/1458 = 1/(2 x 3^6).
from math import gcd

def topologies(n):  # road 1: every family of subsets holding the empty and whole set, closed under pairs
    full, out = (1 << n) - 1, []
    for fam in range(1 << (1 << n)):
        if fam & 1 and fam >> full & 1:
            opens = [s for s in range(1 << n) if fam >> s & 1]
            if all(fam >> (u | v) & 1 and fam >> (u & v) & 1 for u in opens for v in opens):
                out.append(opens)
    return out

def preorders(n):  # road 2: a topology on a finite set is the same as a reflexive, transitive relation
    count, idx = 0, range(n)
    for r in range(1 << (n * n)):
        rel = lambda i, j: r >> (i * n + j) & 1
        if all(rel(i, i) for i in idx) and all(rel(i, k) or not (rel(i, j) and rel(j, k)) for i in idx for j in idx for k in idx):
            count += 1
    return count

def props(n, opens):
    full, T = (1 << n) - 1, set(opens)
    closed = {full ^ u for u in opens}
    t1 = all(1 << p in closed for p in range(n))                      # every single point is a closed set
    haus = all(any(u >> p & 1 and v >> q & 1 and u & v == 0 for u in opens for v in opens)
               for p in range(n) for q in range(n) if p != q)
    conn = not any(u and u != full and full ^ u in T for u in opens)  # no split into two open pieces
    cc_fails = any(s not in closed for s in range(1 << n))            # every subset is compact: is it closed?
    lim_fails = any(p != q and all(u >> p & 1 for u in opens if u >> q & 1) for p in range(n) for q in range(n))
    return t1, haus, conn, cc_fails, lim_fails, len(opens) == 1 << n

total = 0
print("points  topologies  preorders  T1  Hausdorff  discrete  connected  compact-not-closed  two-limits  T1-not-Hausdorff")
for n in range(1, 5):
    tops = topologies(n)
    P = [props(n, t) for t in tops]
    c = [sum(p[i] for p in P) for i in range(6)]
    bad = sum(1 for p in P if p[0] and not p[1])
    print(f"{n:>6}  {len(tops):>10}  {preorders(n):>9}  {c[0]:>2}  {c[1]:>9}  {c[5]:>8}  {c[2]:>9}  {c[3]:>18}  {c[4]:>10}  {bad:>16}")
    assert len(tops) == preorders(n) and bad == 0 and all(p[0] == p[1] == p[5] for p in P)
    assert c[2] == [1, 3, 19, 233][n - 1] and c[3] == c[4] == len(tops) - 1   # known connected counts; all but discrete fail
    total += len(tops)
print(f"T1 but not Hausdorff, searched over all {total} topologies on 1 to 4 points: none")
ind = props(2, [0, 3])
print(f"indiscrete on 2 points: open sets {{}} {{a,b}}; {{a}} compact and closed {not ind[3]}; a,a,a,... also converges to b {ind[4]}; connected {ind[2]}")
assert ind[3] and ind[4] and ind[2]

print("discrete N, d = 1 between different points: balls of radius 1/2 needed to cover the first N points: "
      + ", ".join(f"N={N}: {len({frozenset(m for m in range(N) if 2 * (m != k) < 1) for k in range(N)})}" for N in (10, 100, 1000)))
pairs = [(F, G) for F in range(64) for G in range(64)]   # open sets N minus F and N minus G, F and G inside {0..5}
first = [min(k for k in range(8) if not (F | G) >> k & 1) for F, G in pairs]
inside = all(not (F >> k & 1 or G >> k & 1) and k <= bin(F).count("1") + bin(G).count("1") for (F, G), k in zip(pairs, first))  # in both, by |F| + |G|
print(f"cofinite N: {len(pairs)} pairs of open sets missing parts of {{0..5}}, all overlap {inside}, first shared point at most {max(first)}")
assert inside and max(first) == 6
tails = [max([k for k in range(6) if F >> k & 1] + [-1]) + 1 for F in range(64) if not F >> 3 & 1]
print(f"cofinite N: 0,1,2,... enters each of the {len(tails)} open sets round 3 that miss part of {{0..5}} by term {max(tails)}")
assert all(all(not F >> k & 1 for k in range(t, 100)) for F, t in zip([F for F in range(64) if not F >> 3 & 1], tails))

L, U = 6, 1458
fr = lambda a, b=U: "0" if a == 0 else str(a // b) if a % b == 0 else f"{a // gcd(a, b)}/{b // gcd(a, b)}"
pts = [tuple(2 * (i >> (L - 1 - k) & 1) for k in range(L)) for i in range(1 << L)]
val = lambda a: sum(2 * d * 3 ** (L - 1 - k) for k, d in enumerate(a))
first_diff = lambda a, b: next(k + 1 for k in range(L) if a[k] != b[k])
V = [val(a) for a in pts]
D = [[0 if a == b else U // 3 ** first_diff(a, b) for b in pts] for a in pts]   # address distance 3^-n
O = [[abs(x - y) for y in V] for x in V]                                         # ordinary distance
m = len(pts)
strong = sum(1 for i in range(m) for j in range(m) for k in range(m) if D[i][k] > max(D[i][j], D[j][k]))
plain = sum(1 for i in range(m) for j in range(m) for k in range(m) if O[i][k] > max(O[i][j], O[j][k]))
print(f"Cantor level {L}: {m} points, {m ** 3} triples; strong triangle fails for address distance {strong}, for ordinary distance {plain}")
assert strong == 0 and plain > 0
sand = all(D[i][j] <= O[i][j] <= 3 * D[i][j] for i in range(m) for j in range(m) if i != j)
print(f"sandwich d <= |x - y| <= 3d on all {m * (m - 1)} ordered pairs: {sand}")
assert sand
ok = 0
for i in range(m):
    for j in range(i + 1, m):
        n = first_diff(pts[i], pts[j])
        pre = val(pts[i][:n - 1] + (0,) * (L - n + 1))
        lo, g, hi = pre + U // 3 ** n, pre + 3 * U // (2 * 3 ** n), pre + 2 * U // 3 ** n
        ok += V[i] < lo < g < hi <= V[j]
print(f"gap between: every one of {m * (m - 1) // 2} pairs has a deleted gap strictly between its points: {ok == m * (m - 1) // 2}")
assert ok == m * (m - 1) // 2
x, y, z = pts[0], pts[16], pts[24]
print(f"worked: x={fr(val(x))} y={fr(val(y))} z={fr(val(z))}; first differences n(x,y)={first_diff(x, y)} n(y,z)={first_diff(y, z)} n(x,z)={first_diff(x, z)}")
print(f"worked: d(x,y)={fr(D[0][16])} d(y,z)={fr(D[16][24])} d(x,z)={fr(D[0][24])}; |x-y|={fr(O[0][16])} |y-z|={fr(O[16][24])} |x-z|={fr(O[0][24])}")
assert (D[0][24], O[0][24]) == (U // 9, 8 * U // 27) and D[0][24] <= max(D[0][16], D[16][24]) and O[0][24] > max(O[0][16], O[16][24])
g = 3 * U // (2 * 9)
left = sum(1 for v in V if v < g)
print(f"worked: gap point g={fr(g)}; level-{L} points left of g {left}, right of g {m - left}")
assert left == 16 and fr(g) == "1/6"
near = [fr(val(tuple(2 if k == n else 0 for k in range(L)))) for n in range(L)]
flip = all(O[i][i ^ 1] == 4 for i in range(m))   # change the last digit: another point 2/729 away
print(f"no isolated point: from 0 the points {' '.join(near)}; every level-{L} point has another at {fr(4)}: {flip}")
assert flip and near[1] == "2/9"

state, seq = 2026, []   # 1000 points of C, 12 digits each, from a 64-bit linear congruential generator
for k in range(1000 * 12):
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    seq.append(2 * (state >> 63))
seq = [seq[12 * k:12 * k + 12] for k in range(1000)]
kept, sizes, prefix = list(range(1000)), [1000], []
for r in range(8):   # pigeonhole: keep the digit that more terms share
    zeros = [k for k in kept if seq[k][r] == 0]
    twos = [k for k in kept if seq[k][r] == 2]
    kept, dig = (zeros, 0) if len(zeros) >= len(twos) else (twos, 2)
    prefix.append(dig)
    sizes.append(len(kept))
    assert 2 * len(kept) >= sizes[-2] and all(seq[k][:r + 1] == prefix for k in kept)
v12 = [sum(d * 3 ** (11 - j) for j, d in enumerate(seq[k])) for k in kept]   # in units of 1/531441 = 3^-12
spread = max(v12) - min(v12)
print(f"compact by pigeonhole: terms kept {' '.join(map(str, sizes))}; shared address 0.{''.join(map(str, prefix))}; "
      f"kept terms spread {fr(spread, 3 ** 12)}, bound {fr(81, 3 ** 12)}")
assert 0 < spread <= 81

hund = lambda v: (2 * (3000 * U + 36000 * v) + U) // (2 * U)   # pixel x times 100, rounded: 360 px per unit
px = lambda v: f"{hund(v) // 100}.{hund(v) % 100:02d}"
for lev in range(4):
    ends = sorted(sum(2 * (i >> (lev - 1 - k) & 1) * 3 ** (L - 1 - k) * 2 for k in range(lev)) for i in range(1 << lev))
    print(f"figure,level {lev}, {len(ends)} pieces of length {fr(U // 3 ** lev)}: " + " ".join(f"{px(e)}-{px(e + U // 3 ** lev)}" for e in ends))
print(f"figure,x {px(val(x))} y {px(val(y))} z {px(val(z))} g {px(g)}")
print("ALL CHECKS PASS")
