# The Radon-Nikodym derivative -- the check behind the card.  Standard library
# only.  A fair die P, a loaded die Q and a third die R, in exact fractions:
# the exchange rate Z = dQ/dP, the change-of-measure rule, the chain rule
# through R and the reciprocal rule back.  Then two roads that share none of
# that arithmetic: SplitMix64 rolls (seed 2026), and the bus-wait companion
# (waits exponential at rate 1 under P, rate 2 under Q) by Simpson's rule and
# by weighted draws.  Last, the four mistakes of the card, each computed.
from fractions import Fraction as F
import math

FACES = [1, 2, 3, 4, 5, 6]
P = [F(1, 6)] * 6
Q = [F(1, 10)] * 4 + [F(2, 10), F(4, 10)]
R = [F(1, 4), F(1, 4), F(2, 10), F(1, 10), F(1, 10), F(1, 10)]
Q0 = [F(0), F(2, 10), F(1, 10), F(1, 10), F(2, 10), F(4, 10)]  # never shows a 1

def rate(nu, mu):                  # d nu / d mu on a die: weight over weight
    return [n / m for n, m in zip(nu, mu)]

def mean(weights, values):         # the integral of values against weights
    return sum(w * v for w, v in zip(weights, values))

def show(x):
    return f"{x} = {float(x):.4f}" if x.denominator > 1 else f"{x}"

Z, ZQR, ZRP = rate(Q, P), rate(Q, R), rate(R, P)
ZPQ = rate(P, Q)
events = [[i for i in range(6) if mask >> i & 1] for mask in range(64)]
every_event = all(sum(Q[i] for i in A) == sum(Z[i] * P[i] for i in A) for A in events)
direct = mean(Q, FACES)
changed = mean(P, [f * z for f, z in zip(FACES, Z)])
chain = [a * b for a, b in zip(ZQR, ZRP)]
via_r = mean(R, [f * z for f, z in zip(FACES, ZQR)])
back = mean(Q, [f * z for f, z in zip(FACES, ZPQ)])

print(f"dice as decimals: P {float(P[0]):.4f} each; Q {', '.join(str(float(x)) for x in Q)}; "
      f"R {', '.join(str(float(x)) for x in R)}")
print("face | P | Q | R | Z = dQ/dP | dQ/dR | dR/dP | dP/dQ")
for i in range(6):
    print(f"{FACES[i]} | {P[i]} | {Q[i]} | {R[i]} | {float(Z[i]):.2f} | "
          f"{float(ZQR[i]):.2f} | {float(ZRP[i]):.2f} | {float(ZPQ[i]):.4f}")
print("figure, Z per face:", ", ".join(f"{float(z):.2f}" for z in Z))
print(f"Q(A) equals the sum over A of Z times P, for all {len(events)} events A:",
      "yes" if every_event else "no")
print(f"E_P[Z] = {mean(P, Z)}")
print(f"E_Q[face], directly: {show(direct)}")
print(f"E_P[face x Z], by the change of measure: {show(changed)}")
print("chain: dQ/dR x dR/dP equals dQ/dP on every face:", "yes" if chain == Z else "no")
print(f"E_R[face x dQ/dR], through the third die: {show(via_r)}")
print("reciprocal: dP/dQ x dQ/dP on the six faces:", ", ".join(str(a * b) for a, b in zip(ZPQ, Z)))
print(f"E_Q[dP/dQ] = {mean(Q, ZPQ)}; E_Q[face x dP/dQ] = {show(back)}; "
      f"E_P[face] = {show(mean(P, FACES))}")

state = 2026
def uniform():                     # SplitMix64, written out; 53 bits into [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2**64
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2**64
    return ((z ^ (z >> 31)) >> 11) / 2.0**53

N = 200000
zf = [float(z) for z in Z]
cum = [sum(float(q) for q in Q[:k + 1]) for k in range(6)]
s1 = s2 = s3 = s4 = 0.0
for _ in range(N):
    face = int(6 * uniform()) + 1  # a fair roll, weighted by the exchange rate
    w = face * zf[face - 1]
    s1 += w
    s2 += w * w
    u = uniform()                  # a loaded roll, by its cumulative weights
    f = next(k + 1 for k in range(6) if u < cum[k] or k == 5)
    s3 += f
    s4 += f * f
m1, m3 = s1 / N, s3 / N
se1 = math.sqrt((s2 / N - m1 * m1) / N)
se3 = math.sqrt((s4 / N - m3 * m3) / N)
print(f"draws, seed 2026: {N} fair rolls, mean of face x Z = {m1:.4f} (s.e. {se1:.4f})")
print(f"draws: {N} loaded rolls, mean face = {m3:.4f} (s.e. {se3:.4f})")

def simpson(g, a, b, n):           # Simpson's rule, n even
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n))
    return s * h / 3

zb = lambda t: 2 * math.exp(-t)    # bus: dQ/dP at wait t minutes
pb = lambda t: math.exp(-t)
ez = simpson(lambda t: zb(t) * pb(t), 0.0, 40.0, 4000)
et = simpson(lambda t: t * zb(t) * pb(t), 0.0, 40.0, 4000)
eq = simpson(lambda t: t * 2 * math.exp(-2 * t), 0.0, 40.0, 4000)
sw = sw2 = 0.0
for _ in range(N):
    t = -math.log(1.0 - uniform())  # a rate-1 wait, weighted by the exchange rate
    w = t * zb(t)
    sw += w
    sw2 += w * w
mw = sw / N
sew = math.sqrt((sw2 / N - mw * mw) / N)
print(f"bus: E_P[Z] by Simpson = {ez:.6f}")
print(f"bus: E_Q[T] by Simpson on the rate-2 density = {eq:.6f}; exact 1/2")
print(f"bus: E_P[T x Z] by Simpson = {et:.6f}")
print(f"bus: {N} rate-1 draws, mean of T x Z = {mw:.4f} (s.e. {sew:.4f})")
ts = [0.5 * k for k in range(7)]
print("figure, t:", ", ".join(f"{t:.1f}" for t in ts))
print("figure, P density:", ", ".join(f"{pb(t):.2f}" for t in ts))
print("figure, Q density:", ", ".join(f"{2 * math.exp(-2 * t):.2f}" for t in ts))
print("figure, Z(t):", ", ".join(f"{zb(t):.2f}" for t in ts))

forgot = mean(P, FACES)
twice = mean(Q, [f * z for f, z in zip(FACES, Z)])
Z0 = rate(Q0, P)
dropped = sum(Q0[i] * FACES[i] / Z0[i] for i in range(6) if Z0[i] > 0)
print(f"mistake 1, Z forgotten: E_P[face] = {show(forgot)}, not 22/5")
print(f"mistake 2, Z applied under Q: E_Q[face x Z] = {show(twice)}, above the top face")
print(f"mistake 3, Q' never shows 1, Z' = {', '.join(str(z) for z in Z0)}: "
      f"sum of face / Z' under Q' = {show(dropped)}, not 7/2")
tries = [F(1), F(10), F(1000)]
print(f"mistake 4, P not << Q': P({{1}}) = {P[0]}, but f(1) x Q'({{1}}) for f(1) = 1, 10, 1000:",
      ", ".join(str(f * Q0[0]) for f in tries))

assert every_event and direct == F(22, 5)                     # exact: Q(A) on all 64 events
assert Z == [F(3, 5)] * 4 + [F(6, 5), F(12, 5)]               # each rate against the hand value
assert ZPQ == [F(5, 3)] * 4 + [F(5, 6), F(5, 12)]             # each rate back against the hand value
assert changed == direct and mean(P, Z) == 1                  # change of measure; Z averages 1
assert chain == Z and via_r == direct and back == forgot      # chain through R; reciprocal back
assert abs(m1 - 4.4) < 4 * se1 and abs(m3 - 4.4) < 4 * se3  # draws against the exact answer
assert abs(et - 0.5) < 1e-6 and abs(mw - 0.5) < 4 * sew      # bus: Simpson and draws against 1/2
assert abs(eq - 0.5) < 1e-6 and abs(ez - 1) < 1e-6           # bus: rate-2 mean; Z averages 1
assert twice == F(189, 25) and dropped == F(10, 3)            # the mistakes, exactly
print("ALL CHECKS PASS")
