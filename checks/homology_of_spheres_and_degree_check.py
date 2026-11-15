# Homology of spheres, and degree -- the check behind the card.  Standard library only.
# Spheres are triangulated two ways; their homology over Z comes from an integer Smith form.
# Degrees come three ways: the fundamental cycle pushed through the map, preimages counted
# with signs, and the real map's turning angle added up.  Exact except the angle sums.
from itertools import combinations, product
import cmath, math

def closure(tops):                       # every face of the top simplices, by dimension
    cells = {}
    for t in tops:
        for k in range(1, len(t) + 1):
            cells.setdefault(k - 1, set()).update(combinations(t, k))
    return [sorted(cells[k]) for k in sorted(cells)]

def boundary(rows, cols):                # signed matrix of the boundary map
    where, m = {s: i for i, s in enumerate(rows)}, [[0] * len(cols) for _ in rows]
    for j, s in enumerate(cols):
        for i in range(len(s)):
            m[where[s[:i] + s[i + 1:]]][j] = (-1) ** i
    return m

def smith(m):                            # nonzero diagonal of the integer Smith form
    m, diag = [r[:] for r in m], []
    while m and m[0] and any(v for r in m for v in r):
        _, i, j = min((abs(v), i, j) for i, r in enumerate(m) for j, v in enumerate(r) if v)
        m[0], m[i] = m[i], m[0]
        for r in m:
            r[0], r[j] = r[j], r[0]
        p = m[0][0]
        for i in range(1, len(m)):       # clear the pivot's column, then its row
            m[i] = [a - m[i][0] // p * b for a, b in zip(m[i], m[0])]
        q = [v // p for v in m[0]]
        for r in m:
            r[1:] = [v - qj * r[0] for v, qj in zip(r[1:], q[1:])]
        if any(r[0] for r in m[1:]) or any(m[0][1:]):
            continue                     # a remainder is left: pivot again on it
        bad = [r for r in m[1:] if any(v % p for v in r[1:])]
        if bad:                          # p must divide the rest: if not, mix a row in
            m[0] = [a + b for a, b in zip(m[0], bad[0])]
        else:
            diag, m = diag + [abs(p)], [r[1:] for r in m[1:]]
    return diag

def homology(tops):                      # H_k as (rank, torsion), and simplex counts
    c = closure(tops)
    sf = [[]] + [smith(boundary(c[k - 1], c[k])) for k in range(1, len(c))] + [[]]
    return [(len(c[k]) - len(sf[k]) - len(sf[k + 1]), [d for d in sf[k + 1] if d > 1])
            for k in range(len(c))], [len(x) for x in c]

yn = lambda claim: "yes" if claim else "no"
name = lambda rank, tors: " + ".join(([f"Z^{rank}"] if rank > 1 else ["Z"] * rank)
                                     + [f"Z/{d}" for d in tors]) or "0"

def is_cycle(chain):                     # does the chain have zero boundary?
    rim = {}
    for s, c in chain.items():
        for i in range(len(s)):
            rim[s[:i] + s[i + 1:]] = rim.get(s[:i] + s[i + 1:], 0) + (-1) ** i * c
    return not any(rim.values())
def degree(src, tgt, f):                 # f takes src's cycle to d times tgt's cycle
    img = {}
    for s, c in src.items():
        im = [f(v) for v in s]
        if len(set(im)) == len(im):      # a squashed simplex contributes nothing
            sign = (-1) ** sum(a > b for a, b in combinations(im, 2))   # reordering sign
            img[tuple(sorted(im))] = img.get(tuple(sorted(im)), 0) + sign * c
    ratios = {img.get(t, 0) * c for t, c in tgt.items()}
    assert len(ratios) == 1 and all(t in tgt for t, v in img.items() if v)
    return ratios.pop()

def ring(n):                             # fundamental cycle of an n-gon circle
    return {**{(k, k + 1): 1 for k in range(n - 1)}, (0, n - 1): -1}
def cross(n):                            # fundamental cycle of the cross-polytope S^n
    return {tuple(2 * i + b for i, b in enumerate(s)): (-1) ** sum(s)
            for s in product((0, 1), repeat=n + 1)}
def signs(n_src, f):                     # walk the source; edges laid on target edge 0-1
    hits = [(f(k), f((k + 1) % n_src)) for k in range(n_src)]
    return [1 if h == (0, 1) else -1 for h in hits if h in ((0, 1), (1, 0))]

def turns(g, steps=720):                 # running total turn of g(t) round 0, in turns
    pts, out, tot = [g(2 * math.pi * s / steps) for s in range(steps + 1)], [0.0], 0.0
    for a, b in zip(pts, pts[1:]):
        step = b * a.conjugate()         # the small turn from one value to the next
        tot += math.atan2(step.imag, step.real)
        out.append(tot / (2 * math.pi))
    return out

power = lambda n: lambda t: cmath.exp(1j * n * t)                  # z^n on the unit circle
zigzag = lambda t: cmath.exp(1j * (3 * t if t <= 4 * math.pi / 3 else 8 * math.pi - 3 * t))
quad = lambda r: lambda t: (w := r * cmath.exp(1j * t)) * w - 4 * w + 5

print("homology over Z of S^n, triangulated as the boundary of an (n+1)-simplex:")
for n in range(5):
    hs, cnt = homology(list(combinations(range(n + 2), n + 1)))
    chi = sum((-1) ** k * c for k, c in enumerate(cnt))
    print(f"S{n}: simplices {cnt}, chi {chi}; " + ", ".join(f"H{k} {name(*h)}" for k, h in enumerate(hs)))
    assert hs == [(2 if n == 0 else 1, [])] + [(int(k == n), []) for k in range(1, n + 1)]
    assert chi == sum((-1) ** k * h[0] for k, h in enumerate(hs)) == 1 + (-1) ** n
for n in (1, 2, 3):                      # the square, the octahedron, the 16-cell
    hs, cnt = homology(list(cross(n)))
    print(f"S{n} as a cross-polytope: simplices {cnt}; " + ", ".join(f"H{k} {name(*h)}" for k, h in enumerate(hs)))
    assert hs == [(1, [])] + [(int(k == n), []) for k in range(1, n + 1)]
    assert is_cycle(cross(n)) and not is_cycle({**cross(n), tuple(range(0, 2 * n + 2, 2)): -1})
clock = lambda k: k % 3                  # hour hand at 10k degrees, minute hand at 120k
d_chain, sg, d_turn = degree(ring(36), ring(3), clock), signs(36, clock), round(turns(power(12))[-1])
print(f"clock, z^12 as a 36-gon onto a triangle: fundamental cycle goes to {d_chain} x the target's")
print(f"clock: source edges laid on target edge 0-1: {len(sg)}, signs sum {sum(sg)}; angle turns {d_turn}")
print("clock: minute hand at 12 when the hour hand is at", [30 * h for h in range(12)], "degrees")
ns = list(range(-3, 13))
maps = [(3 * max(abs(n), 1), (lambda s: lambda k: s * k % 3)((n > 0) - (n < 0))) for n in ns]
by_chain = [degree(ring(N), ring(3), f) for N, f in maps]
by_signs, by_turns = [sum(signs(N, f)) for N, f in maps], [round(turns(power(n))[-1]) for n in ns]
print(f"z^n for n = -3..12, by chain map: {by_chain}")
print(f"same, by signed preimages: {yn(by_signs == ns)}; by angle turns: {yn(by_turns == ns)}")
mirror, zig = (lambda k: -k % 12), lambda k: [0, 1, 2, 3, 0, 1, 2, 3, 0, 3, 2, 1][k]
m_turn, z_turn = turns(power(-1)), turns(zigzag)
print(f"mirror, z to conj(z) on a 12-gon: chain {degree(ring(12), ring(12), mirror)}, "
      f"preimage signs {signs(12, mirror)}, turns {round(m_turn[-1])}")
print(f"zigzag, 2 turns on then 1 back: chain {degree(ring(12), ring(4), zig)}, "
      f"preimage signs {signs(12, zig)}, turns {round(z_turn[-1])}")
d2, d3 = degree(ring(18), ring(9), lambda k: k % 9), degree(ring(9), ring(3), lambda k: k % 3)
d6 = degree(ring(18), ring(3), lambda k: k % 9 % 3)
print(f"z^3 after z^2: degrees {d2} and {d3}, composite {d6}; added instead: {d2 + d3}")
anti = [degree(cross(n), cross(n), lambda v: v ^ 1) for n in (1, 2, 3)]
refl = [[degree(cross(n), cross(n), lambda v, i=i: v ^ (v // 2 == i)) for i in range(n + 1)]
        for n in (1, 2, 3)]
print(f"antipode on S1, S2, S3 by chain map: {anti}")
print(f"reflections in one axis each: {refl}; products {[math.prod(r) for r in refl]}")
fta = [round(turns(quad(r))[-1]) for r in (1, 2, 3, 10)]
print(f"z^2 - 4z + 5 round radius 1, 2, 3, 10: turns {fta}; roots 2 +- i at radius {math.sqrt(5):.3f}")
print("chart, turns so far at each twelfth of the walk:")
for label, tr in (("clock", turns(power(12))), ("zigzag", z_turn), ("mirror", m_turn)):
    print(label, " ".join(f"{tr[60 * k]:.2f}" for k in range(13)))
assert d_chain == sum(sg) == d_turn == 12 and len(sg) == 12        # three roads, the clock
assert by_chain == by_signs == by_turns == ns                       # z^n has degree n
assert degree(ring(12), ring(12), mirror) == sum(signs(12, mirror)) == round(m_turn[-1]) == -1
assert degree(ring(12), ring(4), zig) == sum(signs(12, zig)) == round(z_turn[-1]) == 1
assert d6 == d2 * d3 == 6 and anti == [math.prod(r) for r in refl] == [1, -1, 1]
assert fta == [0, 0, 2, 2]
print("ALL CHECKS PASS")
