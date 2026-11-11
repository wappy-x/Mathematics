# Subgradients -- the check behind the card.  Standard library only.
# A roaster needs 100 kg of beans a week.  Kenyan beans cost £9/kg for the first
# 40 kg, £14/kg from 40 to 70 kg and £20/kg past 70 kg; Brazilian beans at £12/kg
# fill the rest.  Roads: the max rule, a brute-force test of the definition,
# one-sided difference slopes, and a full enumeration of the purchase.
LINES = [(9, 0), (14, -200), (20, -620)]      # total Kenyan cost C(q) = max of a*q + b
NEED, P, KNEE = 100, 12, 40                   # kg needed, £/kg substitute, the volume break
QS = [i / 2 for i in range(0, 201)]           # every half kilo from 0 to 100

def cost(q, lines=LINES): return max(a * q + b for a, b in lines)
def net(q, p=P, c=cost): return c(q) + p * (NEED - q)   # what the week's beans cost, £

def max_rule(q, lines=LINES):                 # slopes of the lines that touch the top at q
    top = cost(q, lines)
    act = [a for a, b in lines if a * q + b == top]
    return min(act), max(act)

def brute(f, x, ys, gs):                      # every g with f(y) >= f(x) + g (y - x) for all y
    return [g for g in gs if all(f(y) - f(x) >= g * (y - x) for y in ys)]

def one_sided(f, x, h=1e-3): return (f(x) - f(x - h)) / h, (f(x + h) - f(x)) / h

def best(f, qs=QS):
    q = min(qs, key=f)
    return q, f(q)

def num(v): return f"{v:g}"

print("Kenyan cost C(q) at 0, 40, 70, 100 kg:", ", ".join(num(cost(q)) for q in (0, 40, 70, 100)))
print("at 40 kg the three lines read", ", ".join(num(a * KNEE + b) for a, b in LINES) + f"; 60 kg of Brazilian costs £{num(P * (NEED - KNEE))}")
lo, hi = max_rule(KNEE)
left, right = one_sided(cost, KNEE)
G = [i / 100 for i in range(0, 2501)]                  # trial slopes £0.00 .. £25.00 per kg
ok = brute(cost, KNEE, QS, G)
print(f"one-sided slopes of C at 40 kg (h = 0.001): {left:.3f} and {right:.3f}")
print(f"max rule at 40 kg: active slopes {lo} and {hi}, so dC(40) = [{lo}, {hi}]")
print(f"brute force at 40 kg: g from {ok[0]:.2f} to {ok[-1]:.2f} passes ({len(ok)} of {len(G)} tried)")
print("max rule at 55 and 70 kg: dC(55) = [%d, %d], dC(70) = [%d, %d]" % (max_rule(55) + max_rule(70)))
assert abs(left - lo) < 1e-6 and abs(right - hi) < 1e-6          # road 1 against road 3
assert (ok[0], ok[-1]) == (lo, hi) and len(ok) == 501           # road 1 against road 2
assert max_rule(55) == (14, 14) and max_rule(70) == (14, 20)

print("net cost F(q) at 0, 40, 70, 100 kg:", ", ".join(num(net(q)) for q in (0, 40, 70, 100)))
dlo, dhi = lo - P, hi - P
okF = brute(net, KNEE, QS, [i / 100 for i in range(-1000, 1001)])
print(f"dF(40) = dC(40) - 12 = [{dlo}, {dhi}]; brute force gives [{okF[0]:.2f}, {okF[-1]:.2f}]; 0 inside: {dlo <= 0 <= dhi}")
qb, fb = best(net)
print(f"enumeration of all 201 half-kilo plans: cheapest at {num(qb)} kg, £{num(fb)}")
assert (okF[0], okF[-1]) == (dlo, dhi) and dlo <= 0 <= dhi
assert qb == KNEE and fb == 1080
keep = [p / 2 for p in range(0, 61) if net(KNEE, p / 2) == best(lambda q: net(q, p / 2))[1]]
print(f"substitute prices (in 50p steps) at which 40 kg is among the cheapest: £{num(keep[0])} to £{num(keep[-1])}")
for p in (8, 15):
    q, f = best(lambda q: net(q, p))
    print(f"  substitute at £{p}: best buy {num(q)} kg of Kenyan, £{num(f)}")
assert (keep[0], keep[-1]) == (lo, hi)

ab = lambda x: abs(x)
X = [i / 2 for i in range(-10, 11)]
g1 = [i / 100 for i in range(-200, 201)]
a0, a1 = brute(ab, 0, X, g1), brute(ab, 2.5, X, g1)
print(f"|x| at 0: g from {a0[0]:.2f} to {a0[-1]:.2f} passes; at 2.5: only {a1[0]:.2f} ({len(a1)} value)")
assert (a0[0], a0[-1], len(a0)) == (-1, 1, 201) and a1 == [1]
Y2 = [(u / 2, v / 2) for u in range(-10, 11) for v in range(-10, 11)]
G2 = [(u / 4, v / 4) for u in range(-8, 9) for v in range(-8, 9)]
def brute2(f, x):
    return [g for g in G2 if all(f(y) - f(x) >= g[0] * (y[0] - x[0]) + g[1] * (y[1] - x[1]) for y in Y2)]
n1 = lambda y: abs(y[0]) + abs(y[1])
ninf = lambda y: max(abs(y[0]), abs(y[1]))
s1, sinf = brute2(n1, (3, 0)), brute2(ninf, (3, -3))
print(f"||x||_1 at (3, 0): {len(s1)} of {len(G2)} trial g pass, g1 = {num(s1[0][0])}, g2 from {num(s1[0][1])} to {num(s1[-1][1])}")
print("||x||_inf at (3, -3): passing g =", " ".join(f"({num(a)}, {num(b)})" for a, b in sinf))
g11 = s1[-1]                                                     # the subgradient (1, 1) at (3, 0)
st = (3 - g11[0], 0 - g11[1])                                    # one step along minus it
print(f"||x||_1 from (3, 0) along minus ({num(g11[0])}, {num(g11[1])}) to ({num(st[0])}, {num(st[1])}): {num(n1(st))}, was {num(n1((3, 0)))}")
assert s1 == [(1, v / 4) for v in range(-4, 5)]                 # {1} x [-1, 1]
assert sinf == [(t / 4, t / 4 - 1) for t in range(0, 5)]        # segment from (0, -1) to (1, 0)

print("what breaks:")
print(f"  right slope taken as the derivative: +{hi - P} says move left; 38 kg costs £{num(net(38))}")
wrong = (min(a for a, b in LINES), max(a for a, b in LINES))
qw, fw = best(lambda q: net(q, 18))
print(f"  every piece counted, not only active: [{wrong[0]}, {wrong[1]}]; at £18 that keeps 40 kg (£{num(net(40, 18))}), best is {num(qw)} kg at £{num(fw)}")
disc = lambda q: min(14 * q, 9 * q + 200)                      # a discount past 40 kg: concave
dl, dr = one_sided(disc, KNEE)
od = brute(disc, KNEE, QS, G)
qd, fd = best(lambda q: net(q, P, disc))
print(f"  discount tier: slopes {dl:.0f} then {dr:.0f}, {len(od)} subgradients at 40 kg; 40 kg costs £{num(net(40, P, disc))}, best is {num(qd)} kg at £{num(fd)}")
assert net(38) > net(KNEE) and qw == 70 and fw < net(40, 18) and od == [] and qd == 100

sx = lambda q: 40 + 2.8 * q                                      # figure: q 0..100 -> x 40..320
sy = lambda f: 210 - 0.425 * (f - 1000)                          # £1000..£1400 -> y 210..40
pts = " ".join(f"{sx(q):.1f},{sy(net(q)):.1f}" for q in (0, 40, 70, 100))
sup = " ".join(f"{s:+d}:{sx(20):.1f},{sy(1080 + s * -20):.1f}-{sx(60):.1f},{sy(1080 + s * 20):.1f}" for s in (-1, 0, 1))
print("figure, F polyline", pts, "| supporting lines", sup)
print("ALL CHECKS PASS")
