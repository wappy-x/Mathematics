# Triangles: the angle sum and the two-sides-beat-the-third test.  math supplies
# cos, sin, acos, hypot and pi, nothing more.  Fence panels 3, 4 and 8 m, then 3, 4
# and 5 m.  Two roads: the rule on the card, and panels on a grid, swung round.
import math

def rule(p):                                  # road one: the two shorter against the longest
    return sum(sorted(p)[:2]) > max(p)

def gap(b, a, c, t):                          # b hinged at A = (0, 0), turned t up from the
    x, y = b * math.cos(t), b * math.sin(t)   # long panel A to B = (c, 0); a hinged at B:
    return math.hypot(x - c, y) - a           # how far the tip of b sits beyond a's reach

def swing(b, a, c, n=3600):                   # road two: every position of the swing
    g = [gap(b, a, c, math.pi * k / n) for k in range(n + 1)]
    return min(g) < 0 < max(g), min(g), max(g)

def angle(p, q, r):                           # angle at corner p, from the dot product
    u, v = (q[0] - p[0], q[1] - p[1]), (r[0] - p[0], r[1] - p[1])
    cos = (u[0] * v[0] + u[1] * v[1]) / (math.hypot(*u) * math.hypot(*v))
    return math.acos(max(-1.0, min(1.0, cos))) * 180 / math.pi

yn = lambda v: "yes" if v else "no"
by_rule = [rule((3, 4, c)) for c in range(1, 9)]
by_swing = [swing(3, 4, c)[0] for c in range(1, 9)]
s5, s8, closest7 = swing(3, 4, 5), swing(3, 4, 8), swing(3, 4, 7)[1]
lo, hi = 0.0, math.pi                         # bisect for where the 3 m tip meets the 4 m panel
for _ in range(100):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if gap(3, 4, 5, mid) < 0 else (lo, mid)
A, B, C = (0.0, 0.0), (5.0, 0.0), (3 * math.cos(lo), 3 * math.sin(lo))
angA, angB, angC = angle(A, B, C), angle(B, C, A), angle(C, A, B)
missing = 180 - angC - angB                   # the rule: the third corner from the other two
s, worst, pts = 2026, 0.0, []                 # second case: 1000 triangles from our own LCG
for _ in range(6000):
    s = (1103515245 * s + 12345) % 2**31
    pts.append(10 * s / 2**31)
for i in range(0, 6000, 6):
    P, Q, R = (pts[i], pts[i + 1]), (pts[i + 2], pts[i + 3]), (pts[i + 4], pts[i + 5])
    worst = max(worst, abs(angle(P, Q, R) + angle(Q, R, P) + angle(R, P, Q) - 180))
print(f"panels [3, 4, 8]: two shorter end to end {3 + 4} m vs longest 8 m -> triangle: {yn(rule((3, 4, 8)))}")
print(f"swing the 3 m panel through a half-turn: closest the loose ends get {s8[1]:.3f} m")
print(f"3 m tip to B over the swing: {s5[1] + 4:.3f} to {s5[2] + 4:.3f} m with the 5 m panel, {s8[1] + 4:.3f} to {s8[2] + 4:.3f} m with the 8 m")
print("third panel with 3 m and 4 m, c = 1..8, by the rule:  " + " ".join(map(yn, by_rule)))
print("third panel with 3 m and 4 m, c = 1..8, by the swing: " + " ".join(map(yn, by_swing)))
print(f"so the third panel must lie strictly between {4 - 3} m and {4 + 3} m")
print(f"panels [3, 4, 5]: swing closes at A = {lo * 180 / math.pi:.2f} deg, C at ({C[0]:.3f}, {C[1]:.3f})")
print(f"grid angles by dot product: A {angA:.2f}, B {angB:.2f}, C {angC:.2f}, sum {angA + angB + angC:.2f}")
print(f"missing angle by the rule: 180 - {angC:.2f} - {angB:.2f} = {missing:.2f}")
print(f"exterior angle at B: 180 - {angB:.2f} = {180 - angB:.2f} = A + C")
print(f"1000 random triangles: angle sum within 1e-9 deg of 180 every time: {yn(worst < 1e-9)}")
print(f"mistake 1, order 8, 3, 4, first two against the third: {8 + 3} > 4 says {yn(8 + 3 > 4)}")
print(f"mistake 2, panels [3, 4, 7]: closest the loose ends get {closest7:.3f} m, only lying flat")
print(f"mistake 3, 360 - {angC:.2f} - {angB:.2f} = {360 - angC - angB:.2f}, more than a half-turn")
print(f"figure 1, 1 m = 40 units: 8 m panel x 20 to {20 + 8 * 40}, 3 m panel ends x {20 + 3 * 40}, 4 m panel starts x {340 - 4 * 40}")
print(f"figure 2, 1 m = 50 units: A (55, 200), B ({55 + 5 * 50}, 200), C ({55 + 50 * C[0]:.0f}, {200 - 50 * C[1]:.0f})")
assert by_rule == by_swing                    # two roads agree on every third panel, 1 m to 8 m
assert abs(s8[1] - (8 - (3 + 4))) < 1e-12  # the swing's closest approach is the shortfall
assert abs(missing - lo * 180 / math.pi) < 1e-9 and abs(math.hypot(C[0] - 5, C[1]) - 4) < 1e-9  # closed on the 4 m panel, at the rule's corner
assert worst < 1e-9                           # the sum holds on triangles nobody chose
print("ALL CHECKS PASS")
