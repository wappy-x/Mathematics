# The fundamental group -- the check behind the card.  Only Fraction is
# imported.  A lamp post stands at (0, 0) on a pavement of 1 m slabs, and the
# owner stands at X0 = (2, 0).  A walk is the list of slab corners the dog
# visits, 1 m apart, from X0 back to X0: a loop.  Joining is one, then the other.
from fractions import Fraction as F
X0 = (2, 0)

def walk(moves):                         # "N2 W4" -> the corners visited, from X0
    pts, step = [X0], {"N": (0, 1), "S": (0, -1), "E": (1, 0), "W": (-1, 0)}
    for m in moves.split():
        for _ in range(int(m[1:])):
            pts.append((pts[-1][0] + step[m[0]][0], pts[-1][1] + step[m[0]][1]))
    return pts

def join(a, b): return a + b[1:]         # a, then b: a ends where b starts
def rev(a): return a[::-1]               # the same walk, backwards

def wind_ray(p):                         # road 1: signed crossings of the ray
    n = 0                                # running east from the post
    for (x0, y0), (x1, y1) in zip(p, p[1:]):
        c = x0 * y1 - x1 * y0            # c > 0: the post is on the walker's left
        if y0 <= 0 < y1 and c > 0: n += 1
        if y1 <= 0 < y0 and c < 0: n -= 1
    return n

def quad(x, y):                          # quarter of the compass, seen from the post
    return 0 if x > 0 <= y else 1 if y > 0 else 2 if x < 0 else 3

def wind_quad(p):                        # road 2: count quarter turns, no ray at all
    total = 0
    for a, b in zip(p, p[1:]):
        d = (quad(*b) - quad(*a)) % 4
        assert d != 2, "one step swept half the compass"
        total += {0: 0, 1: 1, 3: -1}[d]
    assert total % 4 == 0
    return total // 4

def laps(p):                             # the same crossings, sign ignored
    return sum(1 for (x0, y0), (x1, y1) in zip(p, p[1:])
               if (y0 <= 0 < y1 and x0 * y1 > x1 * y0) or (y1 <= 0 < y0 and x0 * y1 < x1 * y0))

def cancel(p):                           # pull in every there-and-back spur
    st, k = [], 0
    for v in p:
        if len(st) >= 2 and st[-2] == v: st.pop(); k += 1
        else: st.append(v)
    return st, k

def timed(p):                            # the walk as a function of time s in [0, 1]
    def go(s):
        i, r = divmod(s * (len(p) - 1), 1)
        (xa, ya), (xb, yb) = p[int(i)], p[min(int(i) + 1, len(p) - 1)]
        return (xa + r * (xb - xa), ya + r * (yb - ya))
    return go

def dot(f, g):                           # the card's product: f at double speed, then g
    return lambda s: f(2 * s) if s <= F(1, 2) else g(2 * s - 1)

def pt(v): return f"({v[0]}, {v[1]})"   # a point, fractions printed as 1/2
def yn(claim): return "yes" if claim else "no"

def sq(v): return (v[0] ** 2 - v[1] ** 2, 2 * v[0] * v[1])   # doubles every bearing
def mirror(v): return (v[0], -v[1])                        # swaps north and south
def carry(f, p): return [f(v) for v in p]                  # f applied to a walk

A = walk("N2 W4 S4 E4 N2")               # once round the post, anticlockwise
B = rev(A)                               # once round, clockwise
C = walk("E1 N1 W1 S1")                  # round a bin beside the owner, not the post
D = walk("E1 N3 W6 S6 E6 N3 W1")         # a wider lap round the post
loops = {"stand": [X0], "a": A, "a-bar": B, "bin": C, "wide": D}
for name, p in loops.items():
    print(f"loop {name:<6} {len(p) - 1:>2} m   winding by the ray {wind_ray(p):>2}, by quarter turns {wind_quad(p):>2}")
print(f"figure,post (0, 0); owner {X0}; a turns at {A[2]} {A[6]} {A[10]} {A[14]}; "
      f"wide turns at {D[4]} {D[10]} {D[16]} {D[22]}; bin {C[1]} {C[2]} {C[3]}")
pairs = [(x, y) for x in loops.values() for y in loops.values()]
adds = all(wind_ray(join(x, y)) == wind_ray(x) + wind_ray(y) == wind_quad(join(x, y)) for x, y in pairs)
print(f"windings add when two loops are joined: {yn(adds)}, checked on {len(pairs)} pairs")
print("joined   length  winding  spurs pulled in  left after pulling")
for name, p in [("a.a", join(A, A)), ("a.a-bar", join(A, B)), ("a-bar.a", join(B, A)),
                ("a.bin", join(A, C)), ("a.a.a", join(A, join(A, A)))]:
    red, k = cancel(p)
    print(f"{name:<8} {len(p) - 1:>4} m {wind_ray(p):>8} {k:>16} {len(red) - 1:>14} m")
ta, tc = timed(A), timed([X0])
left, right = dot(dot(ta, ta), ta), dot(ta, dot(ta, ta))
print(f"(a.a).a gives the three laps times {F(1, 4)}, {F(1, 4)}, {F(1, 2)}; "
      f"a.(a.a) gives {F(1, 2)}, {F(1, 4)}, {F(1, 4)}")
print(f"at time 1/4: (a.a).a is at {pt(left(F(1, 4)))}, a.(a.a) at {pt(right(F(1, 4)))}")
print(f"at time 1/4: stand.a is at {pt(dot(tc, ta)(F(1, 4)))}, a alone at {pt(ta(F(1, 4)))}")
squeeze = {t: [((1 - t) * x + t * X0[0], (1 - t) * y + t * X0[1]) for x, y in A] for t in (F(1, 4), F(1, 2), F(3, 4))}
on_post = (0, 0) in squeeze[F(1, 2)]
print(f"squeeze a straight toward the owner: winding {wind_ray(squeeze[F(1, 4)])} at t = 1/4, "
      f"{wind_ray(squeeze[F(3, 4)])} at t = 3/4; a corner on the post at t = 1/2: {yn(on_post)}")
print(f"a.a-bar: unsigned laps {laps(join(A, B))}, signed winding {wind_ray(join(A, B))}")
print(f"basepoint after each map: mirror {mirror(X0)}, squaring {sq(X0)}")
print(f"squaring a.a gives winding {wind_quad(carry(sq, join(A, A)))}; "
      f"squaring each a, then joining, gives {wind_quad(join(carry(sq, A), carry(sq, A)))}")
print("loop      n   mirror  squaring  squaring after mirror")
for name, p in loops.items():
    print(f"{name:<6} {wind_quad(p):>4} {wind_quad(carry(mirror, p)):>8} {wind_quad(carry(sq, p)):>9}"
          f" {wind_quad(carry(sq, carry(mirror, p))):>22}")
assert [wind_ray(p) for p in loops.values()] == [0, 1, -1, 0, 1]          # read off by hand
assert all(wind_ray(p) == wind_quad(p) for p in loops.values()) and adds  # two roads agree
assert laps(join(A, B)) == 2 and cancel(join(A, B)) == ([X0], 16) and cancel(join(A, A))[1] == 0    # a.a-bar shrinks
assert left(F(1, 4)) == A[16] and right(F(1, 4)) == (-2, 0)               # not equal on the nose
assert wind_ray(squeeze[F(1, 4)]) == 1 and wind_ray(squeeze[F(3, 4)]) == 0 and on_post
assert wind_quad(carry(sq, join(A, A))) == 2 * wind_ray(join(A, A)) == 4  # squaring a.a: 2 x 2
assert all(wind_quad(carry(sq, p)) == 2 * wind_ray(p) and wind_quad(carry(mirror, p)) == -wind_ray(p)
           and wind_quad(carry(sq, carry(mirror, p))) == -2 * wind_ray(p) for p in loops.values())
print("ALL CHECKS PASS")
