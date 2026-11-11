# Value iteration and policy iteration on a reservoir, checked against each other,
# against the Bellman equation and against every policy of a small reservoir.
import itertools, math

RAIN = [0.2, 0.3, 0.3, 0.2]   # chance of 0, 1, 2, 3 bands of inflow in a month
OPS = [0]                     # multiply-adds, counted as the work is done

def acts(s): return [a for a in (0, 1, 2) if a <= s]   # release 0, 1 or 2 bands
def moves(n, s, a):           # (chance, next band, bands spilled) for each inflow
    return [(p, min(s - a + w, n - 1), max(0, s - a + w - (n - 1))) for w, p in enumerate(RAIN)]
def reward(n, s, a):          # £k: sales at a head that grows with the level, low-flow fine, flood damage
    return a * (10 + s) - (7 if a == 0 else 0) - 40 * sum(p * x for p, _, x in moves(n, s, a))
def q(n, V, s, a, g):
    OPS[0] += 4
    return reward(n, s, a) + g * sum(p * V[t] for p, t, _ in moves(n, s, a))
def greedy(n, V, g, old=None):  # best action at each band; keep the old one on a tie
    out = []
    for s in range(n):
        qs = {a: q(n, V, s, a, g) for a in acts(s)}
        best = max(qs.values())
        out.append(old[s] if old and qs[old[s]] >= best - 1e-9 else max(a for a in qs if qs[a] == best))
    return out
def backup(n, V, g): return [max(q(n, V, s, a, g) for a in acts(s)) for s in range(n)]
def solve(A, b):              # Gaussian elimination with partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for i in range(n):
        piv = max(range(i, n), key=lambda r: abs(M[r][i])); M[i], M[piv] = M[piv], M[i]
        for r in range(i + 1, n):
            f = M[r][i] / M[i][i]
            for c in range(i, n + 1): M[r][c] -= f * M[i][c]
            OPS[0] += n + 1 - i
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (M[i][n] - sum(M[i][c] * x[c] for c in range(i + 1, n))) / M[i][i]; OPS[0] += n - i
    return x
def longrun(n, pol):          # stationary distribution d: d P = d, entries add to 1
    P = chain(n, pol)
    A = [[P[j][i] - (1.0 if i == j else 0.0) for j in range(n)] for i in range(n - 1)] + [[1.0] * n]
    d = solve(A, [0.0] * (n - 1) + [1.0])
    return d, sum(d[s] * reward(n, s, pol[s]) for s in range(n))
def chain(n, pol):            # transition table of the reservoir under a fixed rule
    P = [[0.0] * n for _ in range(n)]
    for s in range(n):
        for p, t, _ in moves(n, s, pol[s]): P[s][t] += p
    return P
def evaluate(n, pol, g):      # solve V = r + g P V exactly
    P = chain(n, pol)
    A = [[(1.0 if i == j else 0.0) - g * P[i][j] for j in range(n)] for i in range(n)]
    return solve(A, [reward(n, s, pol[s]) for s in range(n)])
def policy_iteration(n, pol, g):
    rounds = []
    while len(rounds) < 50:                # a cap: a correct method needs far fewer
        V = evaluate(n, pol, g); new = greedy(n, V, g, pol)
        rounds.append((pol, V, sum(1 for s in range(n) if new[s] != pol[s])))
        if new == pol: break
        pol = new
    return rounds
def value_iteration(n, g, tol, cap=5000):
    V, hist = [0.0] * n, [[0.0] * n]
    while len(hist) <= cap:
        V = backup(n, V, g); hist.append(V)
        if max(abs(a - b) for a, b in zip(hist[-1], hist[-2])) < tol: break
    return hist
def gap(U, V): return max(abs(a - b) for a, b in zip(U, V))
def F1(v): return f"{v:.1f}"
def E1(v): m, e = f"{v:.1e}".split("e"); return f"{m}e{int(e)}"
def show(label, *vals): print(f"{label:<46}" + " ".join(vals))
def word(pol): return "".join(str(a) for a in pol)

N, G, EPS = 20, 0.95, 10.0
TOL = EPS * (1 - G) / (2 * G)
for b in (10, 19): show(f"rewards at band {b} for release 0, 1, 2", *[F1(reward(N, b, a)) for a in (0, 1, 2)])

# ---- policy iteration from 'release one band whenever there is water' ----
OPS[0] = 0
rounds = policy_iteration(N, [min(1, s) for s in range(N)], G)
ops_pi = OPS[0]; pol_pi, Vstar = rounds[-1][0], rounds[-1][1]
for k, (pol, V, ch) in enumerate(rounds):
    show(f"PI round {k + 1}: rule, V(10), error, changed", word(pol), F1(V[10]), F1(gap(V, Vstar)), str(ch))
resid = gap(backup(N, Vstar, G), Vstar)
show("PI: Bellman residual max|TV - V|", E1(resid))

# ---- value iteration from V = 0 ----
OPS[0] = 0
hist = value_iteration(N, G, TOL)
ops_vi = OPS[0]; K = len(hist) - 1; Vk = hist[-1]; pol_vi = greedy(N, Vk, G)
show("VI: stop when a sweep changes less than", f"{TOL:.4f}")
show("VI: sweeps, last change, error to V*", str(K), f"{gap(hist[K], hist[K - 1]):.4f}", f"{gap(Vk, Vstar):.4f}")
show("VI: rule after the last sweep", word(pol_vi))
show("VI: bound 0.95/0.05 * last change", f"{G / (1 - G) * gap(hist[K], hist[K - 1]):.4f}")
show("VI sweep 1: V at bands 8 to 13", *[F1(hist[1][s]) for s in range(8, 14)])
show("VI sweep 2 at band 10: q for release 0, 1, 2", *[f"{q(N, hist[1], 10, a, G):.2f}" for a in (0, 1, 2)])
errs = [gap(hist[k], Vstar) for k in range(K + 1)]
show("VI error ratio, sweeps 1/0, 2/1, 94/93", *[f"{errs[k] / errs[k - 1]:.4f}" for k in (1, 2, K)])
marks = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
show("log10 VI error at sweeps 0, 10, ..., 90", *[f"{math.log10(errs[k]):.2f}" for k in marks])
show("log10 bound 0.95^k * error(0)", *[f"{math.log10(G ** k * errs[0]):.2f}" for k in marks])
show("work: VI total, per sweep", str(ops_vi), str(ops_vi // K))
show("work: PI total, per round", str(ops_pi), str(ops_pi // len(rounds)))
for k in (0, 1, 4):
    show(f"chart: V, PI round {k + 1}, bands 0-19 by 3", *[f"{rounds[k][1][s]:.0f}" for s in range(0, 20, 3)])

# ---- long run under the best rule: the stationary distribution d ----
d, avg = longrun(N, pol_pi)
show("long run: share of months holding, 1, 2", *[f"{sum(d[s] for s in range(N) if pol_pi[s] == a):.4f}" for a in (0, 1, 2)])
show("long run: £k a month, (1-gamma) d.V*", f"{avg:.4f}", f"{(1 - G) * sum(d[s] * Vstar[s] for s in range(N)):.4f}")

# ---- a 6-band reservoir: every rule listed ----
n6 = 6
allp = list(itertools.product(*[acts(s) for s in range(n6)]))
vals = [evaluate(n6, list(p), G) for p in allp]
top = [i for i, V in enumerate(vals) if all(V[s] >= W[s] - 1e-9 for W in vals for s in range(n6))]
pi6 = policy_iteration(n6, [min(1, s) for s in range(n6)], G)[-1]
vi6 = value_iteration(n6, G, TOL)
show("6 bands: rules listed, best rule", str(len(allp)), word(allp[top[0]]))
show("6 bands: PI rule, VI rule, VI value error", word(pi6[0]), word(greedy(n6, vi6[-1], G)), f"{gap(vals[top[0]], vi6[-1]):.4f}")

# ---- what breaks ----
early = greedy(N, hist[10], G)
show("rule after 10 sweeps, worst loss £k", word(early), F1(gap(evaluate(N, early, G), Vstar)))
naive = value_iteration(N, G, EPS)
show("stop at change < 10: sweeps, true error", str(len(naive) - 1), F1(gap(naive[-1], Vstar)))
h1 = value_iteration(N, 1.0, TOL, cap=400)
ch1 = [gap(h1[k], h1[k - 1]) for k in (94, 400)]
pol1 = greedy(N, h1[-1], 1.0); avg1 = longrun(N, pol1)[1]
show("gamma 1: change at sweeps 94 and 400", F1(ch1[0]), f"{ch1[1]:.4f}")
show("gamma 1: rule, its long-run £k a month", word(pol1), f"{avg1:.4f}")
for g in (0.9, 0.99):
    show(f"try gamma {g}: VI sweeps, PI rounds", str(len(value_iteration(N, g, EPS * (1 - g) / (2 * g))) - 1),
         str(len(policy_iteration(N, [min(1, s) for s in range(N)], g))))
show("try eps 1: VI sweeps", str(len(value_iteration(N, G, 1 * (1 - G) / (2 * G))) - 1))

assert pol_vi == pol_pi and len(rounds) < 50                        # two methods, one rule
assert resid < 1e-9 and gap(Vk, Vstar) < EPS / 2                    # Bellman certificate; VI's bound
assert len(top) == 1 and list(allp[top[0]]) == pi6[0] == greedy(n6, vi6[-1], G)   # enumeration
assert abs(errs[K] / errs[K - 1] - G) < 1e-3                        # contraction rate
assert abs(avg - (1 - G) * sum(d[s] * Vstar[s] for s in range(N))) < 1e-9   # stationary identity
assert gap(naive[-1], Vstar) > EPS and len(h1) == 401                # the two failures happen
assert abs(ch1[1] - avg1) < 1e-6                                     # gamma 1: change = average reward
print("ALL CHECKS PASS")
