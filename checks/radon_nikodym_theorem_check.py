# The Radon-Nikodym theorem -- the check behind the card.  Standard library only;
# fractions keeps every die calculation exact.
# Die: fair die P against loaded die Q = (0.1, 0.1, 0.1, 0.1, 0.2, 0.4).
# Road 1: the definition: Q(face) / P(face), then tested on all 64 events.
# Road 2: the Hahn staircase: f(x) is the highest level t with x in the positive
#         set of Q - tP, each positive set found by searching all 64 events.
# Road 3: the proof's recipe: raise g by eps on the positive set of
#         (Q - integral of g) - eps P until nothing is left over.
# L2 check: von Neumann's route, h = dQ/d(P + Q), then h / (1 - h) = Q/P.
# Bus waits, rate 1 (P) against rate 2 (Q): positive sets of Q - tP found by
# maximising over intervals [0, b], and the staircase set against 2e^(-x).
# Failures: a die that never shows 6, and counting measure against length.
# The code checks finite cases and grids; that every sigma-finite pair has a
# density is the proof's work.
from fractions import Fraction as Fr
from math import exp, log

EV = [[i for i in range(6) if m >> i & 1] for m in range(64)]      # all 64 events
P = [Fr(1, 6)] * 6
Q = [Fr(1, 10)] * 4 + [Fr(2, 10), Fr(4, 10)]
def meas(w, A): return sum((w[i] for i in A), Fr(0))
def integ(f, w, A): return sum((f[i] * w[i] for i in A), Fr(0))
def dec(v): return " ".join(f"{float(x):.4f}" for x in v)
def faces(A): return " ".join(str(i + 1) for i in A) if A else "none"
def hahn(sig):                          # largest event of greatest signed size
    best = max(meas(sig, A) for A in EV)
    return max((A for A in EV if meas(sig, A) == best), key=len)

ratio = [Q[i] / P[i] for i in range(6)]                                # road 1
print(f"die, P: {dec(P)}; Q: {dec(Q)}")
print("die, density by ratio Q/P:", dec(ratio))
stair, shown = [Fr(0)] * 6, (3, 6, 9, 12, 18, 24, 27)
for k in range(31):                                                    # road 2
    t = Fr(k, 10)
    H = hahn([Q[i] - t * P[i] for i in range(6)])
    for i in H: stair[i] = max(stair[i], t)
    if k in shown: print(f"hahn, positive set of Q - {float(t):.1f} P: faces {faces(H)}; its size {float(meas(Q, H) - t * meas(P, H)):.4f}")
print("die, density by Hahn staircase:", dec(stair))
g, eps, totals, rnd = [Fr(0)] * 6, Fr(3, 10), [Fr(0)], 0               # road 3
while True:
    left = [Q[i] - g[i] * P[i] for i in range(6)]                      # nu_0 on each face
    H = hahn([left[i] - eps * P[i] for i in range(6)])
    rnd += 1
    if not H:
        print(f"recipe, round {rnd}: positive set empty; left over {float(sum(left)):.4f}")
        break
    for i in H: g[i] += eps
    assert all(integ(g, P, A) <= meas(Q, A) for A in EV)              # g stays in the class G
    totals.append(integ(g, P, range(6)))
    assert totals[-1] > totals[-2]
    print(f"recipe, round {rnd}: raise faces {faces(H)}; g = {dec(g)}; total {float(totals[-1]):.4f}")
h = [Q[i] / (P[i] + Q[i]) for i in range(6)]                           # L2 check
vn = [x / (1 - x) for x in h]
print("L2 route, h = dQ/d(P+Q):", dec(h), "| h/(1-h):", dec(vn))
assert ratio == stair == g                                            # three roads agree
assert vn == ratio                                                     # the L2 formula recovers Q/P
assert all(integ(g, P, A) == meas(Q, A) for A in EV)
assert totals[-1] == meas(Q, range(6))
print(f"die, event 'even' = faces 2 4 6: Q {float(meas(Q, [1, 3, 5])):.4f}; integral of f against P {float(integ(g, P, [1, 3, 5])):.4f}")
print(f"die, all 64 events: integral of f against P equals Q; best total m = {float(totals[-1]):.4f} = Q(whole die)")

M = [Fr(1, 5)] * 5 + [Fr(0)]                                           # never shows a 6
st6 = [max(Fr(k, 10) for k in range(31) if i in hahn([Q[j] - Fr(k, 10) * M[j] for j in range(6)])) for i in range(6)]
got = integ(st6[:5] + [Fr(0)], M, range(6))
assert got + Q[5] == meas(Q, range(6))                               # short by exactly Q(face 6)
print(f"no abs. continuity, five-face die M: staircase {dec(st6)} (face 6 hits the cap 3.0); integral against M {float(got):.4f}; missing Q(6) = {float(Q[5]):.4f} on a set M calls 0")
wr = [P[i] / Q[i] for i in range(6)]
print(f"wrong way round, dP/dQ: {dec(wr)}; its integral against P {float(integ(wr, P, range(6))):.4f}")
V = [Fr(1, 10), Fr(1, 10), Fr(2, 10), Fr(2, 10), Fr(4, 10), Fr(0)]
f1 = [V[i] / M[i] for i in range(5)] + [Fr(0)]
f2 = f1[:5] + [Fr(7)]
agree = sum(integ(f1, M, A) == meas(V, A) == integ(f2, M, A) for A in EV)
bump = g[:5] + [g[5] + Fr(1, 10)]
differ = sum(integ(bump, P, A) != meas(Q, A) for A in EV)
assert agree == 64
assert differ == 32
print(f"uniqueness, V = {dec(V)} against M: versions {dec(f1)} and face-6 value 7 agree on {agree} of 64 events")
print(f"uniqueness, fair die: raise face 6 of f by 0.1, events that now disagree: {differ} of 64")
print("counting vs length, k grid points each given length 1/k: density against counting, total")
for k in (10, 100, 1000, 10 ** 6):
    print(f"  k = {k}: density {1 / k:.6f}, total {k * Fr(1, k)}")
print("counting vs length on [0, 1]: singletons force f = 0; integral of 0 = 0, length 1")

def gold(fn, a, b):                     # own golden-section search for a maximum
    r = (5 ** 0.5 - 1) / 2
    for _ in range(90):
        c, d = b - r * (b - a), a + r * (b - a)
        if fn(c) > fn(d): b = d
        else: a = c
    return (a + b) / 2
def bstar(t): return gold(lambda b: (1 - exp(-2 * b)) - t * (1 - exp(-b)), 0.0, 10.0)
for t in (0.25, 0.5, 1.0, 1.5):
    b = bstar(t)
    assert abs(b - log(2 / t)) < 1e-7
    print(f"bus, positive set of Q - {t} P is [0, b): best b {b:.6f}; ln(2/t) {log(2 / t):.6f}")
cuts = [bstar(j / 100) for j in range(1, 200)]
for x in (0.25, 0.5, 1.0, 2.0):
    s = max((j + 1) / 100 for j in range(199) if x < cuts[j])
    assert 0 <= 2 * exp(-x) - s < 0.01
    print(f"bus, x = {x}: staircase {s:.2f}; 2e^(-x) {2 * exp(-x):.4f}")
def simpson(fn, a, b, n=1000):
    w = (b - a) / n
    return w / 3 * sum(fn(a + i * w) * (1 if i in (0, n) else 4 if i % 2 else 2) for i in range(n + 1))
qa = simpson(lambda x: 2 * exp(-x) * exp(-x), 0.0, 1.0)
assert abs(qa - (1 - exp(-2))) < 1e-10
print(f"bus, Q([0, 1]) as integral of 2e^(-x) against P: {qa:.4f}; closed form 1 - e^(-2) {1 - exp(-2):.4f}")
pieces = [simpson(lambda x: 2 * exp(-2 * x), k, k + 1.0) for k in range(20)]
assert all(abs(pieces[k] - (exp(-2 * k) - exp(-2 * k - 2))) < 1e-10 for k in range(20))
print("sigma-finite, rate-2 wait against length, pieces [k, k+1), k = 0..3:", " ".join(f"{v:.4f}" for v in pieces[:4]),
      f"| 20 pieces glued: {sum(pieces):.6f}")
print("chart, loaded die weights: " + " ".join(f"{float(q):.2f}" for q in Q) + f"; fair die {float(P[0]):.2f}")
print("chart, recipe totals by round 0..8: " + " ".join(f"{float(v):.2f}" for v in totals))
print("ALL CHECKS PASS")
