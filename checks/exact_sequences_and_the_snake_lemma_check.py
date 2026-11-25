# Exact sequences and the snake lemma, checked by brute force on whole numbers.
# Row: 0 -> Z --times n--> Z --mod n--> Z/n -> 0 (metres -> half-metres -> leftover, for n = 2).
# Snake: multiply every module in the row by m and chase elements.
from math import gcd

W = range(-60, 61)   # a window of whole numbers, for searches in Z
L = 360              # a box [0, L) that every modulus here divides
B = range(-L, L)     # a wider window, so images cover the box

def index_in_box(image):              # |Z / image| = box points / image points in the box
    return L // len({y for y in image if 0 <= y < L})

def cosets(n, sub):                   # the members of (Z/n)/sub, each as a frozenset
    return sorted({frozenset((z + s) % n for s in sub) for z in range(n)}, key=min)

def snake(n, m, delta_on=True):
    ker_a = [x for x in W if m * x == 0]
    ker_b = [y for y in W if m * y == 0]
    ker_c = [z for z in range(n) if (m * z) % n == 0]
    coker_a, coker_b = range(m), range(m)
    im_c = {(m * z) % n for z in range(n)}
    coker_c = cosets(n, im_c)
    cls = lambda z: next(k for k in coker_c if z % n in k)
    chase = {}
    for z in ker_c:                   # lift, push down, pull back, take the class
        classes = set()
        for t in range(-3, 4):
            y = z + n * t                                  # lift: y mod n = z
            x = next(x for x in W if n * x == m * y)       # pull back: n x = m y
            classes.add(x % m)
        assert len(classes) == 1, "delta depends on the lift"
        chase[z] = classes.pop()
    delta = (lambda z: chase[z]) if delta_on else (lambda z: 0)
    spots = [  # (incoming source, incoming map, spot, outgoing map, zero of the target)
        ([0], lambda x: 0, ker_a, lambda x: n * x, 0),
        (ker_a, lambda x: n * x, ker_b, lambda y: y % n, 0),
        (ker_b, lambda y: y % n, ker_c, delta, 0),
        (ker_c, delta, coker_a, lambda x: (n * x) % m, 0),
        (coker_a, lambda x: (n * x) % m, coker_b, lambda y: cls(y), cls(0)),
        (coker_b, lambda y: cls(y), coker_c, lambda k: 0, 0)]
    exact = sum({f(x) for x in s} == {v for v in spot if g(v) == zero}
                for s, f, spot, g, zero in spots)
    sizes = [len(ker_a), len(ker_b), len(ker_c),
             index_in_box(m * x for x in B), index_in_box(m * y for y in B), len(coker_c)]
    return sizes, chase, exact

# 1. the row is exact, three spots, on the window
inj = [x for x in W if 2 * x == 0]
mid = {y for y in W if y % 2 == 0} == {2 * x for x in W if -60 <= 2 * x <= 60}
onto = {y % 2 for y in W} == {0, 1}
print(f"row 0 -> Z --x2--> Z --mod 2--> Z/2 -> 0: kernel of x2 {inj}; "
      f"image of x2 = kernel of mod 2: {mid}; mod 2 onto: {onto}")
assert inj == [0] and mid and onto
r = 7
print(f"ruler: {r} half-metres = {r // 2} metres + leftover {r % 2}; half + half = {1 + 1} half-metres "
      f"= {(1 + 1) // 2} metre, leftover {(1 + 1) % 2}; split model (0, 1) + (0, 1) = {(0, (1 + 1) % 2)}")
# 2. not split: no section, no retraction, and Z has no member of order 2
sections = [y for y in W if 2 * y == 0 and y % 2 == 1]
retractions = [c for c in W if 2 * c == 1]
order2_Z = [x for x in W if 2 * x == 0]
order2_split = [(x, t) for x in W for t in (0, 1) if 2 * x == 0 and (2 * t) % 2 == 0]
split_sections = [v for v in order2_split if v[1] == 1]      # s(1) = v with 2v = 0 and g'(v) = 1
print(f"sections s with s(1) odd and 2 s(1) = 0: {len(sections)} found; "
      f"retractions r(x) = c x with r(2) = 1: {len(retractions)} found")
print(f"members killed by 2: in Z {len(order2_Z)}, in Z (+) Z/2 {len(order2_split)}; split row sections: {split_sections}")
assert sections == [] and retractions == [] and len(order2_Z) == 1 and len(order2_split) == 2
assert split_sections == [(0, 1)]
# 3. the snake on the row, multiplied by 2
sizes, chase, exact = snake(2, 2)
print(f"snake n = 2, m = 2: kernels {sizes[:3]}, cokernels {sizes[3:]}")
y = 1; x = next(x for x in W if 2 * x == 2 * y)
print(f"  chase of the half: lift to {y} half-metre, double to {2 * y}, pull back to {x} metre, class {x % 2} (odd)")
pulls = [next(x for x in W if 2 * x == 2 * y) for y in range(-5, 8, 2)]
print(f"  pull-backs for the lifts -5, -3, ..., 7: {pulls}, classes mod 2: {sorted({x % 2 for x in pulls})}")
print(f"  delta: {chase}; same class for lifts 1 + 2t, t = -3..3; exact at {exact} of 6 spots")
assert sizes == [1, 1, 2, 2, 2, 2] and chase == {0: 0, 1: 1} and exact == 6
# alternating count: |ker a| |ker c| |coker b| = |ker b| |coker a| |coker c|
lhs, rhs = sizes[0] * sizes[2] * sizes[4], sizes[1] * sizes[3] * sizes[5]
print(f"  order count: {sizes[0]} * {sizes[2]} * {sizes[4]} = {lhs}, {sizes[1]} * {sizes[3]} * {sizes[5]} = {rhs}")
assert lhs == rhs
# 4. the split row 0 -> Z -> Z (+) Z/2 -> Z/2 -> 0, also multiplied by 2: delta is zero
ker_b = [(x, t) for x in W for t in (0, 1) if 2 * x == 0]
img = {(2 * x, 0) for x in B if 0 <= 2 * x < L}
split_sizes = [len([x for x in W if 2 * x == 0]), len(ker_b), len([z for z in range(2) if (2 * z) % 2 == 0]),
               index_in_box(2 * x for x in B), 2 * L // len(img), len(cosets(2, {(2 * z) % 2 for z in range(2)}))]
d_split = set()
for t in range(-3, 4):               # lift 1 to (2t, 1), double it, pull back through x -> (x, 0)
    doubled = (2 * (2 * t), (2 * 1) % 2)
    d_split.add(next(x for x in W if (x, 0) == doubled) % 2)
print(f"split row snake: kernels {split_sizes[:3]}, cokernels {split_sizes[3:]}, delta(1) = {d_split}")
assert split_sizes == [1, 2, 2, 2, 4, 2] and d_split == {0}
# 5. the same snake on other rows: gcd(n, m) members in ker c and in coker c
for n, m in [(4, 6), (2, 3)]:
    sizes, chase, exact = snake(n, m)
    print(f"snake n = {n}, m = {m}: kernels {sizes[:3]}, cokernels {sizes[3:]}, delta {chase}, exact at {exact} of 6")
    assert sizes[2] == sizes[5] == gcd(n, m) and sizes[3] == sizes[4] == m and exact == 6
# 6. what breaks
_, _, exact0 = snake(2, 2, delta_on=False)
print(f"mistake, no connecting map (delta = 0): exact at {exact0} of 6 spots")
assert exact0 == 4
print(f"mistake, ends equal so middles equal: Z has {len(order2_Z)} member killed by 2, Z (+) Z/2 has {len(order2_split)}")
comp_zero = all((4 * x) % 2 == 0 for x in W)
i_img, i_ker = index_in_box(4 * x for x in B), index_in_box(y for y in B if y % 2 == 0)
gap = i_img // i_ker
print(f"mistake, composite zero only: x4 then mod 2 composes to zero: {comp_zero}; "
      f"image index {i_img}, kernel index {i_ker}, {gap} classes left over")
assert comp_zero and gap == 2
# five lemma: no map b from the twisted row to the split row with identity ends
maps = [(p, t) for p in W for t in (0, 1) if (2 * p, (2 * t) % 2) == (1, 0)]
print(f"five lemma: maps b with b(1) = (p, t) and identity ends: {len(maps)} found")
assert maps == []
# hypothesis dropped: a = times 2, c = identity, b(x) = (x, x mod 2) commutes but is not onto
f, g = (lambda x: 2 * x), (lambda y: y % 2)                 # the twisted row
f2, g2 = (lambda x: (x, 0)), (lambda v: v[1])               # the split row
a, b, c = (lambda x: 2 * x), (lambda y: (y, y % 2)), (lambda z: z)
comm = all(b(f(x)) == f2(a(x)) and g2(b(x)) == c(g(x)) for x in W)
hit = {b(y) for y in B}
box_hits = len({v for v in hit if 0 <= v[0] < L})
print(f"mistake, five lemma with a = x2: b(x) = (x, x mod 2) commutes {comm}, misses (0, 1) {(0, 1) not in hit}, "
      f"coker b has {2 * L // box_hits} members")
assert comm and (0, 1) not in hit and 2 * L // box_hits == 2
print("ALL CHECKS PASS")
