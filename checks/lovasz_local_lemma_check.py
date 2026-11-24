# The Lovasz local lemma -- the check behind the card.  Nothing is imported.  A
# 10-SAT formula: 1000 on/off variables, 3800 clauses of 10.  The rule e p (d+1) <= 1
# is tested, resampling finds a setting, and a ring of six clauses is listed in full.
def rnd(n, s=[2026]):                     # a fixed pseudo-random stream, the same in Rust
    s[0] = (s[0] * 6364136223846793005 + 1442695040888963407) & ((1 << 64) - 1)
    return (s[0] >> 33) % n
def C(n, k): return 1 if k == 0 else C(n, k - 1) * (n - k + 1) // k   # n choose k
E, f = 0.0, 1                             # e = 1/0! + 1/1! + 1/2! + ...
for j in range(20): E, f = E + 1 / f, f * (j + 1)
def formula(layers, colour):              # sets of 10: one shuffle of all 1000 per layer
    sets, bad = [], []
    for p in (list(range(1000)) for _ in range(layers)):
        for i in range(999, 0, -1): j = rnd(i + 1); p[i], p[j] = p[j], p[i]
        for b in range(0, 1000, 10): sets.append(p[b:b + 10]); bad.append([rnd(2) for _ in range(10)])
    use = [[c for c, vs in enumerate(sets) if v in vs] for v in range(1000)]   # clauses per variable
    d = max(len({o for v in vs for o in use[v]}) - 1 for vs in sets)   # neighbours, worst set
    x = [rnd(2) for _ in range(1000)]
    fails = lambda c: len({x[v] for v in sets[c]}) == 1 if colour else [x[v] for v in sets[c]] == bad[c]
    start, fixes = sum(map(fails, range(len(sets)))), 0
    while (c := next((c for c in range(len(sets)) if fails(c)), None)) is not None:
        for v in sets[c]: x[v] = rnd(2)   # resample the failing clause's variables
        fixes += 1
    ok = all(0 < sum(x[v] for v in vs) < 10 if colour else any(x[v] != b for v, b in zip(vs, bb))
             for vs, bb in zip(sets, bad))   # checked literal by literal, not by fails()
    return len(sets), d, start, fixes, ok
d_top = next(d for d in range(2000) if E * (d + 2) / 1024 > 1)   # step d up until the rule breaks
(m, d, start, fixes, ok), (h, hd, hs, hf, hok) = formula(38, False), formula(19, True)
hist = [0] * 64                           # ring: clause i fails iff v_i, a_i, b_i = 0 and v_i+1 = 1
for a in range(1 << 18):
    hist[sum(1 << i for i in range(6) if a & (1 << i | 3 << 6 + 2 * i | 1 << (i + 1) % 6) == 1 << (i + 1) % 6)] += 1
P = [[1, 0], [0, 1]]                      # second road to the ring: a 2 x 2 matrix to the 5th and 6th powers
for _ in range(6): P5, P = P, [[P[i][0] * 4 + P[i][1] * 4, P[i][0] * 3 + P[i][1] * 4] for i in range(2)]
worst = max(sum(hist[q] for q in range(64) if q & S == 0 and q >> i & 1) / sum(hist[q] for q in range(64) if q & S == 0)
            for i in range(6) for S in range(64) if not S >> i & 1)
erd = lambda n, k: 2 * C(n, k) < 2 ** C(k, 2)
lll = lambda n, k: E * (sum(C(k, i) * C(n - k, k - i) for i in range(2, k)) + 1) / 2 ** (C(k, 2) - 1) <= 1
def top(test, k, lo):                      # largest n passing the test: double, then halve the gap
    while test(2 * lo, k): lo *= 2
    for step in (1 << t for t in range(lo.bit_length() - 1, -1, -1)): lo += step if test(lo + step, k) else 0
    return lo
rows = [(k, top(erd, k, k), top(lll, k, k)) for k in (10, 20, 30, 40)]
none = sum(not any(all(z >> v & 1 == c >> v & 1 for v in range(10)) for c in range(1024)) for z in range(1024))
print(f"10-SAT: p = 1/1024; e = {E:.9f}; e x p x (d + 1) at d = 375: {E * 376 / 1024:.5f}, at 376: {E * 377 / 1024:.5f}")
print(f"largest d the rule allows: {int(1024 / E) - 1} by floor(1024/e) - 1, {d_top} by stepping up")
print(f"formula: 1000 variables, {m} clauses of 10, each variable in {m // 100}; worst clause meets {d} others")
print(f"union bound: {m}/1024 = {m / 1024:.2f}, over 1, so counting alone says nothing")
print(f"resampling: {start} clauses fail at the random start; after {fixes} fixes, all hold: {['no', 'yes'][ok]}")
print(f"2-colouring {h} ten-sets: rule allows d up to {int(512 / E) - 1}, worst here {hd}; "
      f"{hs} one-colour at start, after {hf} fixes none: {['no', 'yes'][hok]}")
print(f"ring of 6 clauses, 4 variables each, d = 2: e x 3/16 = {E * 3 / 16:.5f}")
print(f"ring good settings: {hist[0]} of {1 << 18} by listing, {P[0][0] + P[1][1]} by matrix power, share {hist[0] / (1 << 18):.5f}")
print(f"lemma's floor (2/3)^6 = {(2 / 3) ** 6:.5f}; worst chance a clause fails given others hold: {worst:.5f}, cap 1/3")
print("Ramsey, largest n each test clears (counting, local lemma, ratio):")
for k, a, b in rows: print(f"k = {k}: {a}, {b}, {b / a:.2f}")
print(f"mistake, drop the e: 1024 clauses on 10 variables give p(d+1) = {1024 / 1024:.1f}; settings that work: {none}")
assert d_top == int(1024 / E) - 1 == 375 and d <= d_top and ok and hok and hd <= int(512 / E) - 1
assert hist[0] == P[0][0] + P[1][1] and abs(worst - P5[1][0] / (P5[1][0] + P[0][0] + P[1][1])) < 1e-12  # listing against the matrix powers
assert hist[0] / (1 << 18) >= (2 / 3) ** 6 and worst <= 1 / 3  # the lemma's two claims, listed
assert [r[1:] for r in rows] == [(100, 104), (5817, 7753), (272717, 406690), (11490820, 18213047)] and not any(erd(a + 1, k) or lll(b + 1, k) for k, a, b in rows)
print("ALL CHECKS PASS")
