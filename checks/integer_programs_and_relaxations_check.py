# Integer programs and relaxations: the festival's headliners h and smaller acts t.
# Maximise tickets 5500h + 1000t with fees 60h + 5t <= 290 (in £k) and stage
# hours 4h + 2t <= 24, h and t whole. Exact fractions throughout.
from fractions import Fraction as Fr

C = (5500, 1000)                 # extra tickets per headliner, per smaller act
BUDGET = (60, 5, 290)            # fees in £k: 60h + 5t <= 290
HOURS = (4, 2, 24)               # stage hours: 4h + 2t <= 24
SIGNS = [(-1, 0, 0), (0, -1, 0)] # h >= 0 and t >= 0, written as -h <= 0, -t <= 0

def show(q):                     # exact fraction -> decimal text, at most 2 places
    n = abs(q.numerator) * 100 * 2 + q.denominator
    n //= 2 * q.denominator      # rounded half up
    s = str(n // 100) + ("." + "%02d" % (n % 100)).rstrip("0").rstrip(".")
    return ("-" if q < 0 else "") + s

def corners(rows):               # every crossing of two limits that obeys all limits
    out = []
    for i in range(len(rows)):
        for j in range(i + 1, len(rows)):
            (a1, b1, r1), (a2, b2, r2) = rows[i], rows[j]
            det = a1 * b2 - a2 * b1
            if det == 0:
                continue
            p = (Fr(r1 * b2 - r2 * b1, det), Fr(a1 * r2 - a2 * r1, det))
            if all(a * p[0] + b * p[1] <= r for a, b, r in rows) and p not in out:
                out.append(p)
    return sorted(out)

def tickets(p):
    return C[0] * p[0] + C[1] * p[1]

def relax(rows):                 # the LP relaxation: best corner (road 1)
    best = max(corners(rows), key=tickets)
    return tickets(best), best

def whole_plans(rows):           # road 3: list every whole plan
    return [(h, t) for h in range(0, 30) for t in range(0, 30)
            if all(a * h + b * t <= r for a, b, r in rows)]

def hull(points):                # convex hull of the whole plans, monotone chain
    pts = sorted(set(points))
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return sorted(lower[:-1] + upper[:-1])

def pt(p):
    return "(" + show(Fr(p[0])) + ", " + show(Fr(p[1])) + ")"

P = [BUDGET, HOURS] + SIGNS
print("corners of the relaxed region P, with tickets:")
for p in corners(P):
    print("  h, t =", pt(p), " tickets", show(tickets(p)))
z_lp, x_lp = relax(P)
print("relaxation: best corner", pt(x_lp), "=", show(x_lp[0] + x_lp[1]), "acts, tickets", show(z_lp))
print("  fees", show(60 * x_lp[0] + 5 * x_lp[1]), "of 290; hours", show(4 * x_lp[0] + 2 * x_lp[1]), "of 24")

# Road 2: prices y on the budget and the hours, from the two tight limits.
det = BUDGET[0] * HOURS[1] - HOURS[0] * BUDGET[1]
y1 = Fr(C[0] * HOURS[1] - HOURS[0] * C[1], det)
y2 = Fr(BUDGET[0] * C[1] - C[0] * BUDGET[1], det)
bound = y1 * BUDGET[2] + y2 * HOURS[2]
print("prices: y1 =", show(y1), "tickets per £1k, y2 =", show(y2), "tickets per hour")
print("  covers a headliner:", show(60 * y1 + 4 * y2), ">= 5500; a smaller act:", show(5 * y1 + 2 * y2), ">= 1000")
print("  price bound 290 x", show(y1), "+ 24 x", show(y2), "=", show(bound))
assert y1 >= 0 and y2 >= 0 and 60 * y1 + 4 * y2 >= C[0] and 5 * y1 + 2 * y2 >= C[1]
assert bound == z_lp             # certificate meets the corner search

S = whole_plans(P)
z_ip = max(tickets(p) for p in S)
best = [p for p in S if tickets(p) == z_ip]
print("whole plans:", str(len(S)) + "; best", pt(best[0]), "=", best[0][0] + best[0][1], "acts, tickets", z_ip)
print("  fees", 60 * best[0][0] + 5 * best[0][1], "of 290; hours", 4 * best[0][0] + 2 * best[0][1], "of 24")
assert len(best) == 1 and z_lp >= z_ip
gap = z_lp - z_ip
print("integrality gap:", show(gap), "tickets =", show(100 * gap / z_ip) + "%")

H = hull(S)
print("corners of conv S:", " ".join(pt(p) for p in H))
assert all(p[0] <= 4 for p in S)  # the listing agrees: no whole plan has 5 headliners
print("five headliners cost", BUDGET[0] * 5, ">", str(BUDGET[2]) + ", so every whole plan has h <= 4")
tight = P + [(1, 0, 4)]          # add 'at most 4 headliners': 5 would cost £300k
assert corners(tight) == [(Fr(a), Fr(b)) for a, b in H]  # inequalities give the hull
z_hull = max(tickets(p) for p in H)
print("formulations, same whole plans, different bounds:")
loose = [BUDGET, (4, 2, 25)] + SIGNS            # licence written as 25 hours
z_loose, x_loose = relax(loose)
assert sorted(whole_plans(loose)) == sorted(S)
for name, z, x in [("25-hour licence", z_loose, x_loose), ("as written, 24 hours", z_lp, x_lp),
                   ("plus h <= 4 (= conv S)", relax(tight)[0], relax(tight)[1])]:
    print("  %-23s bound %8s at %-12s gap %s%%" % (name, show(z), pt(x), show(100 * (z - z_ip) / z_ip)))
assert z_hull == z_ip == relax(tight)[0] and z_loose > z_lp

print("what breaks:")
up = tuple(int(v + Fr(1, 2)) for v in x_lp)    # the relaxed corner rounded to nearest
fee_up = BUDGET[0] * up[0] + BUDGET[1] * up[1]
print("  round", show(x_lp[0]) + ",", show(x_lp[1]), "to nearest " + pt(up) + ": fees", fee_up, ">", str(BUDGET[2]) + ", not allowed")
dn = tuple(int(v) for v in x_lp)               # rounded down
print("  round down to " + pt(dn) + ": tickets", str(tickets(dn)) + ",", z_ip - tickets(dn), "short of best")
print("  read the bound as the answer: promises", show(gap), "tickets no plan sells")
cap7 = whole_plans(P + [(1, 1, 7)])
z7 = max(tickets(p) for p in cap7)
print("  add the false cap h + t <= 7: best " + pt(max(cap7, key=tickets)) + ", tickets", z7)
most = max(corners(P), key=lambda p: p[0] + p[1])
print("  (most acts anywhere in P:", show(most[0] + most[1]) + ", at " + pt(most) + ")")
assert fee_up > BUDGET[2]                       # rounding to nearest breaks the budget
assert tickets(dn) < z_ip and z7 < z_ip
print("figure, P", " ".join(pt(p) for p in corners(P)) + "; conv S", " ".join(pt(p) for p in H) + "; LP",
      pt(x_lp) + "; best", pt(best[0]))
print("ALL CHECKS PASS")
