# Markov decision processes: states, actions, rewards and a transition rule -- the check behind the card.
# A reservoir in 20 levels, three releases, random rain. Roads: Bellman sweeps; exact policy value by
# elimination, with a certificate; every policy of a 6-level reservoir listed; a seeded simulation.
from functools import reduce
RAIN = [0.1, 0.2, 0.4, 0.2, 0.1]   # chance of 0, 1, 2, 3, 4 bands of inflow in a month
PAY = [0.0, 40.0, 75.0, 90.0]      # revenue, thousand pounds, for 0, 1, 2, 3 bands actually released
PENALTY, LOW, G, ACTS = 100.0, 2, 0.95, (1, 2, 3)   # penalty if the month ends at level 2 or below

def model(n, rain):                # p[s][a-1] = chances of next level s'; r[s][a-1] = expected reward
    p, r = [], []
    for s in range(n):
        prow, rrow = [], []
        for a in ACTS:
            row, rew = [0.0] * n, 0.0
            for w, q in enumerate(rain):
                if q == 0.0: continue
                out = min(a, s + w)            # cannot release water that is not there
                t = min(n - 1, s + w - out)    # anything above the top level spills
                row[t] += q
                rew += q * (PAY[out] - (PENALTY if t <= LOW else 0.0))
            prow.append(row); rrow.append(rew)
        p.append(prow); r.append(rrow)
    return p, r

def add(xs): return reduce(lambda t, x: t + x, xs, 0.0)   # plain left-to-right sum, as in Rust (sum() compensates)

def bracket(p, r, V, s, a, g):     # r(s,a) + g * sum over s' of p(s'|s,a) V(s')
    return r[s][a - 1] + g * add(x * v for x, v in zip(p[s][a - 1], V))

def argmax(p, r, V, s, g):          # the first best action
    b = [bracket(p, r, V, s, a, g) for a in ACTS]; return b.index(max(b)) + 1

def sweeps(p, r, n, g, tol, kmax):  # Bellman optimality sweeps from V = 0
    V, k = [0.0] * n, 0
    while k < kmax:
        W = [max(bracket(p, r, V, s, a, g) for a in ACTS) for s in range(n)]
        k, change, V = k + 1, max(abs(x - y) for x, y in zip(V, W)), W
        if change < tol: break
    return V, k

def evaluate(p, r, n, pol, g):     # solve (I - g P_pi) V = r_pi by Gaussian elimination
    M = [[(1.0 if i == j else 0.0) - g * p[i][pol[i] - 1][j] for j in range(n)] + [r[i][pol[i] - 1]] for i in range(n)]
    for c in range(n):
        piv = max(range(c, n), key=lambda i: abs(M[i][c]))
        M[c], M[piv] = M[piv], M[c]
        for i in range(c + 1, n):
            f = M[i][c] / M[c][c]
            M[i][c:] = [x - f * y for x, y in zip(M[i][c:], M[c][c:])]
    V = [0.0] * n
    for i in range(n - 1, -1, -1):
        V[i] = (M[i][n] - add(M[i][j] * V[j] for j in range(i + 1, n))) / M[i][i]
    return V

def splitmix(state):               # SplitMix64: the next state and a 64-bit random number
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, z ^ (z >> 31)

RAINMAP = [0, 1, 1, 2, 2, 2, 2, 3, 3, 4]   # a digit 0-9 gives rain with chances 0.1 0.2 0.4 0.2 0.1
def simulate(pol, g, months, seed):  # RUNS runs from S0: mean and standard error of the discounted total
    state, totals = seed, []
    for _ in range(RUNS):
        s, disc, tot = S0, 1.0, 0.0
        for _ in range(months):
            state, z = splitmix(state)
            w = RAINMAP[z % 10]
            out = min(pol[s], s + w); t = min(N - 1, s + w - out)
            tot += disc * (PAY[out] - (PENALTY if t <= LOW else 0.0))
            disc, s = disc * g, t
        totals.append(tot)
    mean = add(totals) / RUNS
    return mean, (add((x - mean) ** 2 for x in totals) / (RUNS - 1) / RUNS) ** 0.5

show, yn = (lambda V: " ".join(f"{v:.2f}" for v in V)), (lambda b: "yes" if b else "no")

N, S0 = 20, 10
p, r = model(N, RAIN)
nonzero = sum(1 for s in range(N) for a in ACTS for x in p[s][a - 1] if x > 0.0)
assert all(abs(sum(p[s][a - 1]) - 1.0) < 1e-12 for s in range(N) for a in ACTS)
print(f"model: {N} levels x {len(ACTS)} releases, table {N * len(ACTS) * N} entries, {nonzero} not zero, rows sum to 1; {3 ** N:,} policies")
print(f"rain 0-4 bands, chances {show(RAIN)}; r(2,a) for low, medium, high: {show(r[2])}")
assert abs(r[2][2] - (0.1 * -25 + 0.2 * -10 + 0.4 * -10 + 0.2 * -10 + 0.1 * 90)) < 1e-12
V, k = sweeps(p, r, N, G, 1e-6, 10000)
pol = [argmax(p, r, V, s, G) for s in range(N)]
print(f"road 1: {k} sweeps from V = 0 until no level changes by 1e-6")
print(f"V* levels 0-9:   {show(V[:10])}")
print(f"V* levels 10-19: {show(V[10:])}")
print("best release (1 low, 2 medium, 3 high) by level 0-19: " + "".join(map(str, pol)))
VP = evaluate(p, r, N, pol, G)
gain = max(bracket(p, r, VP, s, a, G) - VP[s] for s in range(N) for a in ACTS)
print(f"road 2: exact value of that policy differs from road 1 by under 1e-4: {yn(max(abs(x - y) for x, y in zip(V, VP)) < 1e-4)}")
print(f"certificate: no switch of one action gains over 1e-9 anywhere: {yn(gain < 1e-9)}")
assert max(abs(x - y) for x, y in zip(V, VP)) < 1e-4 and gain < 1e-9
nxt = [add(x * v for x, v in zip(p[S0][a - 1], VP)) for a in ACTS]
print(f"level {S0}: V*(7..13) = {show(VP[7:14])}")
print(f"level {S0}: r = {show(r[S0])}; average next V* = {show(nxt)}")
print(f"level {S0}: brackets = {show([bracket(p, r, VP, S0, a, G) for a in ACTS])}")
assert abs(nxt[2] - (0.1 * VP[7] + 0.2 * VP[8] + 0.4 * VP[9] + 0.2 * VP[10] + 0.1 * VP[11])) < 1e-9
n6 = 6                             # road 3: a 6-level reservoir, every one of 3^6 policies valued exactly
p6, r6 = model(n6, RAIN)
pols6 = [[c // 3 ** i % 3 + 1 for i in range(n6)] for c in range(3 ** n6)]
vals6 = [evaluate(p6, r6, n6, pl, G) for pl in pols6]
i6 = max(range(len(pols6)), key=lambda i: add(vals6[i]))   # the first policy with the largest total
dominates = all(vals6[i6][s] >= w[s] - 1e-9 for w in vals6 for s in range(n6))
V6, _ = sweeps(p6, r6, n6, G, 1e-10, 10000)
pol6 = [argmax(p6, r6, V6, s, G) for s in range(n6)]
print(f"road 3: 6 levels, {len(pols6)} policies listed; best {''.join(map(str, pols6[i6]))} beats or ties all at every level: {yn(dominates)}; Bellman picks {''.join(map(str, pol6))}")
assert dominates and pols6[i6] == pol6 and max(abs(x - y) for x, y in zip(vals6[i6], V6)) < 1e-8
RUNS, MONTHS, SEED = 4000, 300, 2026   # road 4: simulate the policy with SplitMix64
mean, se = simulate(pol, G, MONTHS, SEED)
print(f"road 4: {RUNS} runs of {MONTHS} months from level {S0}: mean {mean:.2f}, standard error {se:.2f}")
assert abs(mean - VP[S0]) < 4 * se
# what breaks
myo = [max(ACTS, key=lambda a: r[s][a - 1]) for s in range(N)]
pc, rc = model(N, [0.0, 0.0, 1.0, 0.0, 0.0])
Vc, _ = sweeps(pc, rc, N, G, 1e-10, 10000)
cert = [argmax(pc, rc, Vc, s, G) for s in range(N)]
vm, vc = evaluate(p, r, N, myo, G)[S0], evaluate(p, r, N, cert, G)[S0]
print(f"breaks: this month's reward only {''.join(map(str, myo))}: {vm:.2f}")
print(f"breaks: rain always 2 bands {''.join(map(str, cert))}: promises {Vc[S0]:.2f}, delivers {vc:.2f}")
g1 = [sweeps(p, r, N, 1.0, 0.0, k)[0][S0] for k in (100, 200, 400)]
print(f"breaks: gamma = 1, V(10) after 100, 200, 400 sweeps: {show(g1)}; rise per sweep {(g1[2] - g1[1]) / 200:.2f}")
assert vm < VP[S0] and vc < VP[S0] < Vc[S0] and g1[2] - g1[1] > 0.9 * (g1[1] - g1[0])
# counting: d linked reservoirs on one river, each with 20 levels and 3 releases
print("reservoirs  states  actions  sweep cost  policy digits")
for d in (1, 2, 3, 10):
    st, ac = N ** d, 3 ** d
    digits = int(d * N ** d * 0.47712125471966244) + 1   # digits of 3^(d * 20^d), log10(3) written out
    print(f"{d} {st:,} {ac:,} {st * ac * st:,} {digits:,}")
    assert d > 2 or digits == len(str(3 ** (d * N ** d)))
# the Try-changing box: other discount factors, one year of months, another seed
for g in (0.8, 0.99):
    Vg, kg = sweeps(p, r, N, g, 1e-6, 100000)
    pg = [argmax(p, r, Vg, s, g) for s in range(N)]
    mg, sg = simulate(pg, g, MONTHS, SEED)
    print(f"try: gamma {g}: {kg} sweeps, best release {''.join(map(str, pg))}, V*(10) {Vg[S0]:.2f}, simulated {mg:.2f} (se {sg:.2f})")
(m12, s12), (m7, s7) = simulate(pol, G, 12, SEED), simulate(pol, G, MONTHS, 7)
print(f"try: 12 months: simulated mean {m12:.2f} (se {s12:.2f}); seed 7: mean {m7:.2f} (se {s7:.2f})")
print("ALL CHECKS PASS")
