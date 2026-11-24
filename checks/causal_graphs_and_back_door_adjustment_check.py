# Causal graphs and back-door adjustment -- the check behind the card.  Standard
# library only.  Data: kidney-stone treatments A (open surgery) and B (keyhole surgery),
# cures by stone size (Charig et al., BMJ, 1986).  Three variables are invented for
# the lesson: M, stone-free at discharge, R, readmitted, and F, a follow-up letter;
# they leave the size-treatment-cure table exactly as recorded.
# Roads: the back-door formula on the counts; the cut-graph model enumerated
# exactly; a seeded randomised trial in that model; d-separation read from the
# graph against independence computed from the numbers; the back-door rule
# against the bias of every possible adjustment set.
from itertools import product

N_ = ["Z", "T", "M", "Y", "R", "F"]               # size, treatment, stone-free, cured, readmitted, follow-up letter
ARROWS = [(0, 1), (0, 2), (0, 3), (1, 2), (2, 3), (1, 4), (3, 4), (4, 5)]
CURE = {(0, 0): (81, 87), (0, 1): (192, 263), (1, 0): (234, 270), (1, 1): (55, 80)}  # (t, z): cured, n
NZ = [sum(CURE[(t, z)][1] for t in (0, 1)) for z in (0, 1)]; TOT = sum(NZ)
p = {k: c / n for k, (c, n) in CURE.items()}
print("treatment  size   cured/n  rate")
for (t, z), (c, n) in CURE.items():
    print(f"{'AB'[t]:<10} {['small', 'large'][z]:<6} {c:>3}/{n:<3}  {c / n:.3f}")
cn = [[sum(CURE[(t, z)][i] for z in (0, 1)) for i in (0, 1)] for t in (0, 1)]
naive = [c / n for c, n in cn]
print(f"pooled: A {cn[0][0]}/{cn[0][1]} = {naive[0]:.3f}, B {cn[1][0]}/{cn[1][1]} = {naive[1]:.3f}, gap A-B {100 * (naive[0] - naive[1]):+.1f} points; "
      f"size shares small {NZ[0]}/{TOT} = {NZ[0] / TOT:.3f}, large {NZ[1]}/{TOT} = {NZ[1] / TOT:.3f}")
# Road 1: the back-door formula on the counts, adjusting for size
adj = [sum(p[(t, z)] * NZ[z] / TOT for z in (0, 1)) for t in (0, 1)]
for t in (0, 1):
    print(f"back-door, {'AB'[t]}: {p[(t, 0)]:.4f} x {NZ[0]}/{TOT} + {p[(t, 1)]:.4f} x {NZ[1]}/{TOT} = {adj[t]:.4f} ({100 * adj[t]:.1f}%)")
TRUE_GAP = adj[0] - adj[1]
print(f"adjusted gap A-B {100 * TRUE_GAP:+.1f} points")

# The model: P(z) P(t|z) P(m|t,z) P(y|m,z) P(r|t,y).  Cure depends on treatment only through M.
H, L, PF = 0.95, [0.40, 0.30], [0.20, 0.90]        # P(cured | stone-free); P(cured | not), by size; P(letter | r)
PM = {(t, z): (p[(t, z)] - L[z]) / (H - L[z]) for t in (0, 1) for z in (0, 1)}
PR = {(0, 1): 0.10, (0, 0): 0.50, (1, 1): 0.05, (1, 0): 0.40}   # (t, y): P(readmitted)
print(f"model inputs: P(cured | stone-free) {H:.2f}; P(cured | not) small {L[0]:.2f}, large {L[1]:.2f}; "
      f"P(readmitted | cured, not): A {PR[(0, 1)]:.2f}, {PR[(0, 0)]:.2f}; B {PR[(1, 1)]:.2f}, {PR[(1, 0)]:.2f}; "
      f"P(follow-up letter | readmitted, not) {PF[1]:.2f}, {PF[0]:.2f}")
print("model, P(stone-free | t, z): " + ", ".join(f"{'AB'[t]} {['small', 'large'][z]} {PM[(t, z)]:.4f}" for t, z in PM))
def bern(q, v): return q if v else 1 - q
def joint(force=None):                             # force=t cuts the arrow into T and sets it
    out = {}
    for z, t, m, y, r, f in product((0, 1), repeat=6):
        pt = CURE[(t, z)][1] / NZ[z] if force is None else float(t == force)
        out[(z, t, m, y, r, f)] = (NZ[z] / TOT * pt * bern(PM[(t, z)], m)
                                   * bern(H if m else L[z], y) * bern(PR[(t, y)], r) * bern(PF[r], f))
    return out
J = joint()
def P(fix, J=J): return sum(q for k, q in J.items() if all(k[i] == v for i, v in fix.items()))
for t, z in CURE:                                  # the model reproduces the recorded table
    assert abs(P({1: t, 0: z, 3: 1}) / P({1: t, 0: z}) - p[(t, z)]) < 1e-12
do = [P({3: 1}, joint(t)) for t in (0, 1)]         # Road 2: the cut graph, enumerated
print(f"cut graph: P(cured | do A) {do[0]:.4f}, P(cured | do B) {do[1]:.4f}")
assert abs(do[0] - adj[0]) < 1e-12 and abs(do[1] - adj[1]) < 1e-12

# Road 3: a randomised trial in the model world, SplitMix64
M64, state = (1 << 64) - 1, 20261123
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
NSIM, seed = 200000, state
cnt = [[0, 0], [0, 0]]                             # [t] = [cured, n]
for _ in range(NSIM):
    z = 1 if uniform() < NZ[1] / TOT else 0
    t = 1 if uniform() < 0.5 else 0
    m = 1 if uniform() < PM[(t, z)] else 0
    cnt[t][0] += 1 if uniform() < (H if m else L[z]) else 0
    cnt[t][1] += 1
sim = [c / n for c, n in cnt]
se = (sum(r * (1 - r) / c[1] for r, c in zip(sim, cnt))) ** 0.5
print(f"trial: seed {seed}, {NSIM} patients by coin; A {cnt[0][0]}/{cnt[0][1]} = {sim[0]:.4f}, "
      f"B {cnt[1][0]}/{cnt[1][1]} = {sim[1]:.4f}, gap {100 * (sim[0] - sim[1]):+.2f} points (SE {100 * se:.2f})")
assert abs(sim[0] - sim[1] - TRUE_GAP) < 4 * se

# Road 4: d-separation from the graph, against independence in the numbers
def desc(v):
    out, todo = set(), [v]
    while todo:
        for a, b in ARROWS:
            if a == todo[-1] and b not in out:
                out.add(b); todo.append(b); break
        else:
            todo.pop()
    return out
def paths(a, b, seen):                             # every simple path, ignoring direction
    if a == b:
        yield seen; return
    for u, v in ARROWS:
        for x, y in ((u, v), (v, u)):
            if x == a and y not in seen:
                yield from paths(y, b, seen + [y])
def blocked(path, S):
    for i in range(1, len(path) - 1):
        v = path[i]
        if (path[i - 1], v) in ARROWS and (path[i + 1], v) in ARROWS:   # a collider
            if v not in S and not (desc(v) & S): return True
        elif v in S: return True
    return False
def dsep(a, b, S): return all(blocked(q, S) for q in paths(a, b, [a]))
def gap_ci(a, b, S):                               # largest |P(a,b,s)P(s) - P(a,s)P(b,s)|
    g = 0.0
    for vals in product((0, 1), repeat=len(S) + 2):
        s = dict(zip(sorted(S), vals[2:]))
        g = max(g, abs(P({a: vals[0], b: vals[1], **s}) * P(s) - P({a: vals[0], **s}) * P({b: vals[1], **s})))
    return g
n_st = n_sep = 0
for a in range(6):
    for b in range(a + 1, 6):
        rest = [v for v in range(6) if v not in (a, b)]
        for k in range(16):
            S = {rest[i] for i in range(4) if k >> i & 1}
            sep, g = dsep(a, b, S), gap_ci(a, b, S)
            assert sep == (g < 1e-12)              # the graph rule against the numbers
            n_st += 1; n_sep += sep
print(f"d-separation: {n_st} statements, {n_sep} separated by the graph; numbers agree on all {n_st}")
for a, b, S in ((1, 3, set()), (1, 3, {0}), (1, 3, {0, 2}), (1, 3, {0, 2, 4}), (1, 3, {0, 2, 5}), (0, 4, {1}), (0, 4, {1, 3})):
    nm = "{" + ", ".join(N_[v] for v in sorted(S)) + "}"
    print(f"  {N_[a]} vs {N_[b]} given {nm:<10} graph: {'separated' if dsep(a, b, S) else 'connected':<9}  largest gap {gap_ci(a, b, S):.6f}")

# Road 5: the back-door rule against the bias of every adjustment set
def backdoor(S):
    return not (desc(1) & S) and all(blocked(q, S) for q in paths(1, 3, [1]) if (q[1], 1) in ARROWS)
bars = []
for k in range(8):
    S = sorted({[0, 2, 4][i] for i in range(3) if k >> i & 1})
    est = [sum(P({1: t, 3: 1, **dict(zip(S, v))}) / P({1: t, **dict(zip(S, v))}) * P(dict(zip(S, v)))
               for v in product((0, 1), repeat=len(S))) for t in (0, 1)]
    ok = backdoor(set(S))
    assert ok == (abs(est[0] - est[1] - TRUE_GAP) < 1e-12)
    bars.append(round(100 * (est[0] - est[1]), 9) + 0.0)
    nm = "{" + ", ".join(N_[v] for v in S) + "}"
    print(f"adjust for {nm:<10} A {est[0]:.4f}  B {est[1]:.4f}  gap {bars[-1]:+5.1f}  back-door {'yes' if ok else 'no'}")
assert abs(bars[0] - 100 * (naive[0] - naive[1])) < 1e-9   # holding nothing fixed gives the pooled gap
assert naive[0] < naive[1] and adj[0] > adj[1]                 # the reversal: B ahead pooled, A ahead adjusted
assert abs(bars[3]) < 1e-9                         # holding the mediator fixed erases the whole effect
print("bars, gap A-B in points: " + ", ".join(f"{b:.1f}" for b in bars))
print("ALL CHECKS PASS")
