# Graphical models -- the check behind the card.  Standard library only.
# A late delivery L is caused by traffic T or a van breakdown B; a late L sets off
# the late-order alarm A.  Every variable is 0 or 1.  A factor is (variables, table),
# read as table[x0 + 2*x1 + 4*x2 + ...] for its variables x0, x1, x2, ...
# Roads: brute force over every state; variable elimination; sum-product messages;
# on the week chain also the forward-backward recursions of the HMM card.
def cpt(p1):                          # P(child = 1 | parents) -> table over (parents, child)
    return [1 - p for p in p1] + list(p1)
def val(f, x):
    return f[1][sum(x[v] << j for j, v in enumerate(f[0]))]
def brute(n, F, ev):                  # add the product of factors over every state
    tot, one, terms = 0.0, [0.0] * n, 0
    for s in range(2 ** n):
        x = [(s >> i) & 1 for i in range(n)]
        if any(x[v] != e for v, e in ev.items()): continue
        w = 1.0
        for f in F: w *= val(f, x)
        terms += 1; tot += w
        for i in range(n): one[i] += w * x[i]
    return tot, [o / tot for o in one], terms * (len(F) - 1)
def restrict(f, ev):                  # fix the evidence variables inside one factor
    keep, out = [v for v in f[0] if v not in ev], []
    for k in range(2 ** len(keep)):
        x = {v: (k >> j) & 1 for j, v in enumerate(keep)}; x.update(ev); out.append(val(f, x))
    return (keep, out)
def ve(F, order, ev):                 # variable elimination: sum out `order`, return P(the one left = 1 | ev)
    F, mults, big = [restrict(f, ev) for f in F], 0, 0
    for v in order:
        use, F = [f for f in F if v in f[0]], [f for f in F if v not in f[0]]
        vs, t = sorted({u for f in use for u in f[0]} - {v}), []
        for k in range(2 ** len(vs)):
            x, s = {u: (k >> j) & 1 for j, u in enumerate(vs)}, 0.0
            for xv in (0, 1):
                x[v], w = xv, 1.0
                for f in use: w *= val(f, x)
                s += w; mults += len(use) - 1
            t.append(s)
        F.append((vs, t)); big = max(big, len(t))
    p = [1.0, 1.0]
    for vs, t in F:
        for xq in (0, 1): p[xq] *= t[xq] if vs else t[0]
    return p[1] / (p[0] + p[1]), p[0] + p[1], mults + 2 * (len(F) - 1), big
def bp(n, F, rounds):                 # sum-product, every message updated every round
    nb = [[a for a, f in enumerate(F) if v in f[0]] for v in range(n)]
    fv = {(a, v): [1.0, 1.0] for a, f in enumerate(F) for v in f[0]}
    for _ in range(rounds):
        vf = {}
        for (a, v) in fv:
            m = [1.0, 1.0]
            for b in nb[v]:
                if b != a: m = [m[0] * fv[(b, v)][0], m[1] * fv[(b, v)][1]]
            vf[(a, v)] = [m[0] / (m[0] + m[1]), m[1] / (m[0] + m[1])]
        for (a, v) in fv:
            vs, t = F[a]; m = [0.0, 0.0]
            for k in range(2 ** len(vs)):
                x = {u: (k >> j) & 1 for j, u in enumerate(vs)}; w = t[k]
                for u in vs:
                    if u != v: w *= vf[(a, u)][x[u]]
                m[x[v]] += w
            fv[(a, v)] = [m[0] / (m[0] + m[1]), m[1] / (m[0] + m[1])]
    out = []
    for v in range(n):
        m = [1.0, 1.0]
        for b in nb[v]: m = [m[0] * fv[(b, v)][0], m[1] * fv[(b, v)][1]]
        out.append(m[1] / (m[0] + m[1]))
    return out
def net(pT, pB, late, alarm):         # T = 0, B = 1, L = 2, A = 3
    return [([0], cpt([pT])), ([1], cpt([pB])), ([0, 1, 2], cpt(late)), ([2, 3], cpt(alarm))]
f6 = lambda xs: " ".join(f"{x:.6f}" for x in xs)
LATE, ALARM = [0.05, 0.40, 0.90, 0.95], [0.03, 0.90]
F = net(0.10, 0.02, LATE, ALARM)
# ---- the delivery: P(breakdown | alarm), three roads ----
g = [sum(cpt(LATE)[t + 2 * b + 4 * l] * cpt(ALARM)[l + 2] for l in (0, 1)) for b in (0, 1) for t in (0, 1)]
h = [0.9 * g[2 * b] + 0.1 * g[2 * b + 1] for b in (0, 1)]
print(f"by hand: g(T,B) for (0,0) (1,0) (0,1) (1,1): {f6(g)}; h(B): {f6(h)}; P(B) h(B): {0.98 * h[0]:.6f} {0.02 * h[1]:.6f}")
Z, mb, bm = brute(4, F, {3: 1})
pv, Zv, vm, _ = ve(F, [2, 0], {3: 1})
mbp = bp(4, F + [([3], [0.0, 1.0])], 10)
print(f"P(alarm) = {Z:.6f}; P(breakdown and alarm) = {Z * mb[1]:.6f}; per 20,000 orders: {20000 * Z:.0f} alarms, {20000 * Z * mb[1]:.0f} of them breakdowns")
print(f"P(breakdown | alarm): brute force {mb[1]:.6f}  elimination {pv:.6f}  sum-product {mbp[1]:.6f}")
print(f"multiplications: brute force over 8 states {bm}, elimination {vm}\nall marginals given the alarm (T B L A): brute force {f6(mb)}")
print(f"                                         sum-product {f6(mbp)}")
assert abs(mb[1] - pv) < 1e-12 and abs(Z - Zv) < 1e-12 and abs(0.02 * h[1] - Z * mb[1]) < 1e-15
assert all(abs(a - b) < 1e-12 for a, b in zip(mb, mbp))
# ---- independence read from the graph ----
_, mt, _ = brute(4, F, {}); pTB = brute(4, F, {0: 1, 1: 1})[0]
eT1, eT0 = brute(4, F, {3: 1, 0: 1}), brute(4, F, {3: 1, 0: 0})
print(f"no evidence: P(T=1, B=1) = {pTB:.6f} = P(T=1) P(B=1) = {mt[0] * mt[1]:.6f}")
print(f"given the alarm: P(B=1 | A) = {mb[1]:.6f}; add traffic {eT1[1][1]:.6f}; add no traffic {eT0[1][1]:.6f}")
print(f"given the alarm: P(T=1, B=1 | A) = {brute(4, F, {3: 1, 0: 1, 1: 1})[0] / Z:.6f} against P(T|A) P(B|A) = {mb[0] * mb[1]:.6f}")
gL = [brute(4, F, {2: 1, 3: 1, 0: t, 1: b})[0] / brute(4, F, {2: 1, 0: t, 1: b})[0] for t in (0, 1) for b in (0, 1)]
print(f"P(A=1 | L=1, T, B) for the four (T, B): {f6(gL)}")
assert abs(pTB - mt[0] * mt[1]) < 1e-15 and eT1[1][1] < mb[1] < eT0[1][1]
assert all(abs(g - 0.9) < 1e-12 for g in gL)
# ---- the week chain: B_d = van faulty on day d, A_d = that day's alarm ----
em = [ve(F, [2, 0], {1: b})[0] for b in (0, 1)]       # P(A = 1 | B = b): T and L summed out
P, nu, ys = [[0.99, 0.01], [0.49, 0.51]], [0.98, 0.02], [0, 1, 1, 0, 1]
def chain(N, ys):
    G = [([0], cpt([nu[1]]))] + [([n - 1, n], cpt([P[0][1], P[1][1]])) for n in range(1, N)]
    return G + [([n], [1 - em[0], 1 - em[1]] if ys[n] == 0 else em) for n in range(N)]
def fwd_bwd(ys):
    e = lambda b, y: em[b] if y else 1 - em[b]
    al = [[nu[b] * e(b, ys[0]) for b in (0, 1)]]
    for y in ys[1:]: al.append([sum(al[-1][a] * P[a][b] for a in (0, 1)) * e(b, y) for b in (0, 1)])
    be = [[1.0, 1.0]]
    for y in reversed(ys[1:]): be.insert(0, [sum(P[a][b] * e(b, y) * be[0][b] for b in (0, 1)) for a in (0, 1)])
    L = al[-1][0] + al[-1][1]
    return L, [al[n][1] * be[n][1] / L for n in range(len(ys))]
Lw, fb = fwd_bwd(ys); Zw, bw, _ = brute(5, chain(5, ys), {}); sw = bp(5, chain(5, ys), 8)
print(f"alarm chance given the van: healthy {em[0]:.6f}, faulty {em[1]:.6f}")
print(f"alarm week {ys}: chance of the week {Lw:.8f} (forward), {Zw:.8f} (all 32 weeks)")
print(f"P(van faulty), Mon-Fri: forward-backward {f6(fb)}")
print(f"                        sum-product      {f6(sw)}")
print(f"                        all 32 weeks     {f6(bw)}")
assert abs(Lw - Zw) < 1e-15 and all(abs(a - b) < 1e-12 and abs(a - c) < 1e-12 for a, b, c in zip(fb, sw, bw))
for N in (5, 10, 20, 30):
    G = chain(N, [1] * N); vN = ve(G, list(range(N - 1)), {})[2]
    bN = brute(N, G, {})[2] if N <= 10 else 2 ** N * (2 * N - 1)
    print(f"chain of {N:2d} days: multiplications, brute force {bN:,}, elimination {vN}")
    assert (N > 10 or bN == 2 ** N * (2 * N - 1)) and vN == 8 * (N - 1) + 2
# ---- what breaks ----
eT = [ve(F, [3, 1], {0: t})[0] for t in (0, 1)]        # P(late | traffic t): alarm, breakdown summed out
assert all(abs(eT[t] - brute(4, F, {0: t, 2: 1})[0] / brute(4, F, {0: t})[0]) < 1e-12 for t in (0, 1))
H = [([0], cpt([0.10]))] + [([0, i], cpt(eT)) for i in range(1, 11)] + [([i, 10 + i], cpt(ALARM)) for i in range(1, 11)]
ev = {10 + i: int(i <= 4) for i in range(1, 11)}         # alarms on orders 1 to 4 of 10
good, bad = ve(H, list(range(2, 11)) + [0], ev), ve(H, [0] + list(range(2, 11)), ev)
print(f"hub: P(order 1 late | its alarm and 3 of 9 others) = {good[0]:.6f}; largest table: leaves first {good[3]}, hub first {bad[3]}")
print(f"hub: multiplications, leaves first {good[2]}, hub first {bad[2]}")
assert abs(good[0] - bad[0]) < 1e-12 and abs(good[0] - brute(21, H, ev)[1][1]) < 1e-12 and bad[3] == 1024
W = [([0], cpt([0.10])), ([1], cpt([0.02])), ([0, 1, 2], cpt(LATE)), ([0, 1, 3], cpt(LATE)),
     ([2, 4], cpt(ALARM)), ([3, 5], cpt(ALARM)), ([4], [0.0, 1.0]), ([5], [0.0, 1.0])]
ex, lp = brute(6, W, {4: 1, 5: 1})[1], [bp(6, W, r)[1] for r in (50, 51)]
print(f"loop (two orders, same van): P(B=1 | both alarms) exact {ex[1]:.6f}, loopy sum-product {lp[0]:.6f}")
print(f"wrong answers: unnormalised {Z * mb[1]:.6f}; arrow read backwards P(A | B=1) {em[1]:.6f}")
assert abs(lp[0] - lp[1]) < 1e-12 and abs(lp[0] - ex[1]) > 0.01
# ---- try changing ----
print(f"try: false alarms 0.01: P(B | A) = {ve(net(0.10, 0.02, LATE, [0.01, 0.90]), [2, 0], {3: 1})[0]:.6f}")
print(f"try: traffic 0.30: P(B | A) = {ve(net(0.30, 0.02, LATE, ALARM), [2, 0], {3: 1})[0]:.6f}")
print(f"try: alarm week [1, 1, 1, 1, 1]: P(faulty) {f6(fwd_bwd([1, 1, 1, 1, 1])[1])}")
print("ALL CHECKS PASS")
