# The Bellman operator contracts -- the check behind the card.  Standard library
# only.  A reservoir holds 0 to 4 units of water (1 unit = 10 million m^3); each
# month it releases a units for r(a) thousand pounds, then rain adds 0, 1 or 2.
# The best values are reached twice: by value iteration (pressing T) and by
# evaluating all 120 fixed release rules exactly, by elimination.
from math import log10
GAMMA, S = 0.95, range(5)
R = [0, 60, 100, 120, 130]                       # r(a): revenue, thousand pounds, for releasing a units
RAIN = [(0, 0.3), (1, 0.5), (2, 0.2)]            # inflow in units, with its probability

def p_next(s, a):                                # p(s' | s, a); water above 4 units spills
    d = [0.0] * 5
    for w, pw in RAIN:
        d[min(s - a + w, 4)] += pw
    return d

def q(V, s, a, g):                               # revenue now plus discounted expected value next month
    return R[a] + g * sum(p * v for p, v in zip(p_next(s, a), V))

def T(V, g=GAMMA):                               # the Bellman operator: best action in every state
    return [max(q(V, s, a, g) for a in range(s + 1)) for s in S]

def greedy(V):
    return [max(range(s + 1), key=lambda a: q(V, s, a, GAMMA)) for s in S]

def sup(U, W):                                   # ||U - W||_inf, the largest gap over states
    return max(abs(u - w) for u, w in zip(U, W))

def evaluate(pol):                               # solve (I - gamma P) V = r by Gaussian elimination
    M = [[(s == t) - GAMMA * p_next(s, pol[s])[t] for t in S] + [R[pol[s]]] for s in S]
    for c in S:
        piv = max(range(c, 5), key=lambda i: abs(M[i][c]))
        M[c], M[piv] = M[piv], M[c]
        for i in range(c + 1, 5):
            f = M[i][c] / M[c][c]
            M[i] = [x - f * y for x, y in zip(M[i], M[c])]
    V = [0.0] * 5
    for i in reversed(S):
        V[i] = (M[i][5] - sum(M[i][j] * V[j] for j in range(i + 1, 5))) / M[i][i]
    return V

fmt = lambda V: "[" + ", ".join(f"{v:.4f}" for v in V) + "]"
pols = [[0, a1, a2, a3, a4] for a1 in range(2) for a2 in range(3) for a3 in range(4) for a4 in range(5)]
vals = [evaluate(p) for p in pols]
Vstar = [max(v[s] for v in vals) for s in S]     # road 2: best of all 120 rules, state by state
best = max(range(len(pols)), key=lambda i: sum(vals[i]))
print(f"road 2, all {len(pols)} release rules by elimination: V* = {fmt(Vstar)}")
print(f"best rule releases {pols[best]}; its largest shortfall from V*: {sup(vals[best], Vstar):.9f}")
Vs = [[0.0] * 5]                                 # road 1: value iteration from V_0 = 0
for k in range(1000):
    Vs.append(T(Vs[-1]))
print(f"road 1, value iteration, 1000 sweeps from 0: V = {fmt(Vs[1000])}")
print(f"gap between roads {sup(Vs[1000], Vstar):.9f}; Bellman residual ||T V* - V*|| = {sup(T(Vstar), Vstar):.9f}")
assert sup(Vs[1000], Vstar) < 1e-9                   # two roads, one answer

state = 0x2026                                   # SplitMix64, seed 0x2026, for random value functions
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & (2**64 - 1)
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2**53
worst = 0.0
for _ in range(20000):
    U = [2000 * rnd() - 1000 for _ in S]
    W = [2000 * rnd() - 1000 for _ in S]
    worst = max(worst, sup(T(U), T(W)) / sup(U, W))
shift = sup(T([v + 100 for v in Vstar]), T(Vstar)) / 100
print(f"20000 random pairs: largest ||TU - TW|| / ||U - W|| = {worst:.6f}; V* + 100 against V*: {shift:.6f}")

err = [sup(V, Vstar) for V in Vs]
d1 = sup(Vs[1], Vs[0])
first = lambda n: GAMMA ** n / (1 - GAMMA) * d1             # first-step bound
last = lambda n: GAMMA / (1 - GAMMA) * sup(Vs[n], Vs[n - 1])  # last-step bound
q4 = [q(Vs[1], 4, a, GAMMA) for a in S]
print("sweep 2, full reservoir, release 0 to 4: " + ", ".join(f"{v:.4f}" for v in q4))
print(f"gamma / (1 - gamma) = {GAMMA / (1 - GAMMA):.4f}; ||V_1 - V_0|| = {d1:.4f}; over (1 - gamma): {d1 / (1 - GAMMA):.4f}; "
      f"gamma^198, gamma^199 times that: {first(198):.4f}, {first(199):.4f}")
print("k, V_k(full), error ||V_k - V*||, ratio to previous, gamma^k e_0, last-step bound, first-step bound")
for k in (1, 2, 3, 10, 50, 100, 200):
    print(f"{k}, {Vs[k][4]:.4f}, {err[k]:.4f}, {err[k] / err[k - 1]:.6f}, {GAMMA ** k * err[0]:.4f}, "
          f"{last(k):.4f}, {first(k):.4f}")
ratios = [err[k] / err[k - 1] for k in range(1, 301)]
print(f"error ratios over sweeps 1 to 300: smallest {min(ratios):.6f}, largest {max(ratios):.6f}")
fn = lambda ok: next(n for n in range(1, 1001) if ok(n))
n_first, n_last, n_true = fn(lambda n: first(n) <= 0.1), fn(lambda n: last(n) <= 0.1), fn(lambda n: err[n] <= 0.1)
print(f"within 0.1 (100 pounds): first-step bound promises n = {n_first}, last-step bound stops at n = {n_last}, "
      f"true at n = {n_true}")
for k in (1, 2):
    pk = greedy(Vs[k])
    print(f"greedy rule after sweep {k}: {pk}, loss {sup(evaluate(pk), Vstar):.4f}, "
          f"bound 2 gamma e_k / (1 - gamma) = {2 * GAMMA * err[k] / (1 - GAMMA):.4f}")
settle = 1 + max(k for k in range(301) if greedy(Vs[k]) != pols[best])
print(f"greedy rule equals the best rule from sweep {settle} on; error then {err[settle]:.4f}")
W1, p1 = [0.0] * 5, greedy(Vs[1])               # sweep 1's rule valued again: 2000 fixed-rule sweeps, no elimination
for _ in range(2000):
    W1 = [q(W1, s, p1[s], GAMMA) for s in S]
print(f"greedy rule after sweep 1, valued by 2000 fixed-rule sweeps instead: loss {sup(W1, Vstar):.4f}")

V1 = [[0.0] * 5]                                 # break 1: gamma = 1, nothing discounts the future
for k in range(1000):
    V1.append(T(V1[-1], 1.0))
steps1 = [sup(V1[k], V1[k - 1]) for k in (10, 100, 1000)]
print(f"gamma = 1: step ||V_k - V_k-1|| at k = 10, 100, 1000: {steps1[0]:.4f}, {steps1[1]:.4f}, {steps1[2]:.4f}; "
      f"V_1000(full) = {V1[1000][4]:.4f}")
naive = fn(lambda n: sup(Vs[n], Vs[n - 1]) <= 0.1)  # break 2: stop when the step is small
print(f"stop when step <= 0.1: sweep {naive}, step {sup(Vs[naive], Vs[naive - 1]):.4f}, true error {err[naive]:.4f}")
sumn = lambda U, W: sum(abs(u - w) for u, w in zip(U, W))  # break 3: the total gap, not the largest
U = Vstar[:2] + [Vstar[2] + 100] + Vstar[3:]
print("one sweep, change in each state: " + ", ".join(f"{u - w:.4f}" for u, w in zip(T(U), T(Vstar))))
print(f"total-gap norm, V* + 100 at half full against V*: before {sumn(U, Vstar):.4f}, after one sweep "
      f"{sumn(T(U), T(Vstar)):.4f}, ratio {sumn(T(U), T(Vstar)) / sumn(U, Vstar):.6f}")
print("chart, sweep: " + ", ".join(str(k) for k in range(0, 201, 20)))
print("chart, log10 error: " + ", ".join(f"{log10(err[k]):.3f}" for k in range(0, 201, 20)))
print("chart, log10 gamma^k e_0: " + ", ".join(f"{log10(GAMMA ** k * err[0]):.3f}" for k in range(0, 201, 20)))

assert worst <= GAMMA + 1e-12 and abs(shift - GAMMA) < 1e-9          # T contracts, by exactly gamma at worst
assert all(err[k] <= GAMMA * err[k - 1] + 1e-9 for k in range(1, 301))
assert all(err[n] <= last(n) + 1e-9 and last(n) <= first(n) + 1e-9 for n in range(1, 301))
assert all(abs(q(Vs[k], s, greedy(Vs[k])[s], GAMMA) - T(Vs[k])[s]) < 1e-9 for k in range(1, 301) for s in S)  # greedy wins the max
assert greedy(Vs[1000]) == pols[best]                                    # road 1's final rule is road 2's best rule
assert abs(sup(W1, Vstar) - sup(evaluate(p1), Vstar)) < 1e-9 and sup(W1, Vstar) <= 2 * GAMMA * err[1] / (1 - GAMMA)
assert steps1[2] > 1 and err[naive] > 0.1 and sumn(T(U), T(Vstar)) > sumn(U, Vstar)  # the breaks really break
print("ALL CHECKS PASS")
