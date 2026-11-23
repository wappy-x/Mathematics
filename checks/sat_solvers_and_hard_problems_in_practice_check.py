# SAT solvers: a five-a-side league's fixtures as clauses, solved by DPLL.
# Standard library only. Road 1: the solver. Road 2: a direct search over
# fixture lists that knows nothing of clauses. A verifier checks the rules.
import itertools, math
def solve(nv, clauses, count_all=False, cap=None):
    occ = {}
    for i, c in enumerate(clauses):
        for l in c: occ.setdefault(l, []).append(i)
    longc = [c for c in clauses if len(c) > 2]; shortc = [c for c in clauses if len(c) <= 2]
    val = [0] * (nv + 1); trail = []
    st = {'dec': 0, 'prop': 0, 'units': 0, 'init': 0, 'models': 0, 'first': None, 'capped': False, 'log': []}
    def tv(l): v = val[abs(l)]; return v if l > 0 else -v
    def assign(l): val[abs(l)] = 1 if l > 0 else -1; trail.append(abs(l))
    def prop(queue):  # unit propagation: a clause with one free literal forces it
        while queue:
            l = queue.pop()
            for i in occ.get(-l, []):
                free, nfree, sat = None, 0, False
                for m in clauses[i]:
                    t = tv(m)
                    if t == 1: sat = True; break
                    if t == 0: nfree += 1; free = m
                if sat: continue
                if nfree == 0: return False
                if nfree == 1: assign(free); st['prop'] += 1; queue.append(free)
        return True
    def pick():  # the unsatisfied clause with fewest free literals, long clauses first
        best = None
        for c in longc + shortc:
            if best is not None and len(c) == 2: break
            if any(tv(m) == 1 for m in c): continue
            fr = [m for m in c if tv(m) == 0]
            if best is None or len(fr) < len(best): best = fr
        return best
    def rec():
        b = pick()
        if b is None:
            st['models'] += 2 ** (nv - len(trail))
            if st['first'] is None: st['first'] = val[:]
            return not count_all
        for l in (b[0], -b[0]):
            if cap is not None and st['dec'] >= cap: st['capped'] = True; return True
            st['dec'] += 1; mark = len(trail); assign(l); before = st['prop']
            ok = prop([l])
            if not count_all: st['log'].append((l, st['prop'] - before, ok))
            if ok and rec(): return True
            while len(trail) > mark: val[trail.pop()] = 0
        return False
    q = [c[0] for c in clauses if len(c) == 1]; st['units'] = len(q)
    for l in q: assign(l)
    if prop(q): st['init'] = st['prop']; rec()
    return st
T = "ABCDEF"
def league(n, R, rules=True, clash=True):
    pairs = list(itertools.combinations(range(n), 2)); P = {p: i for i, p in enumerate(pairs)}
    x = lambda a, b, r: P[(min(a, b), max(a, b))] * R + r + 1
    cl = []
    for a, b in pairs:  # every pair meets in some round, and in only one
        cl.append([x(a, b, r) for r in range(R)])
        cl += [[-x(a, b, r), -x(a, b, s)] for r, s in itertools.combinations(range(R), 2)]
    for t in range(n):
        o = [u for u in range(n) if u != t]
        for r in range(R):
            if clash: cl += [[-x(t, u, r), -x(t, v, r)] for u, v in itertools.combinations(o, 2)]
            if clash and R >= n - 1: cl.append([x(t, u, r) for u in o])  # plays every round
    if rules:
        cl.append([x(0, 1, 4)])                       # A-B, the derby, in round 5
        cl.append([x(2, 5, 0)])                       # C-F, last season's cup final, in round 1
        cl += [[-x(3, 4, r)] for r in (0, 1, 4)]      # D-E only in round 3 or 4
        for r in range(R - 1):                        # B never meets C and D back to back
            cl += [[-x(1, 2, r), -x(1, 3, r + 1)], [-x(1, 3, r), -x(1, 2, r + 1)]]
    return len(pairs) * R, cl, pairs, x
def fixtures(val, pairs, R):
    return [[p for i, p in enumerate(pairs) if val[i * R + r + 1] == 1] for r in range(R)]
def obeys(rounds):  # the verifier: reads the rules, never the clauses
    rd = {p: r for r, ms in enumerate(rounds) for p in ms}
    once = all(sorted(t for p in ms for t in p) == list(range(6)) for ms in rounds) and len(rd) == 15
    btb = any({rd[(1, 2)], rd[(1, 3)]} == {r, r + 1} for r in range(4))
    return once and rd[(0, 1)] == 4 and rd[(2, 5)] == 0 and rd[(3, 4)] in (2, 3) and not btb
def all_schedules(left, rounds):  # road 2: build fixture lists match by match
    if not left: yield rounds; return
    def matchings(free):
        if not free: yield []; return
        a = free[0]
        for b in free[1:]:
            if (a, b) in left:
                for m in matchings([t for t in free if t not in (a, b)]): yield [(a, b)] + m
    for m in matchings(list(range(6))):
        yield from all_schedules(left - set(m), rounds + [m])
name = lambda p: T[p[0]] + "-" + T[p[1]]
nv, cl, pairs, x = league(6, 5)
print(f"league: 6 teams, 5 rounds, {nv} yes-or-no variables, {len(cl)} clauses")
print(f"assignments a blind search would face: 2^{nv} = {2 ** nv:,}")
base = league(6, 5, rules=False)[1]; fam = lambda c: (len(c), c[0] > 0, len({(abs(l) - 1) // 5 for l in c}))  # size, sign, pairs
parts = [sum(fam(c) == k for c in base) for k in ((5, True, 1), (2, False, 1), (2, False, 2), (5, True, 5))] + [len(cl) - len(base)]
print("clauses: pair meets", parts[0], "| pair once", parts[1], "| once a round", parts[2], "| every round", parts[3], "| rules", parts[4])
s = solve(nv, cl)
print(f"unit clauses set {s['units']} variables before any guess, and these force {s['init']} more")
for k, (l, f, ok) in enumerate(s['log']):
    p, r = pairs[(abs(l) - 1) // 5], (abs(l) - 1) % 5 + 1
    print(f"  decision {k + 1}: {name(p)} in round {r} {'yes' if l > 0 else 'no'}, forces {f} more")
print(f"decisions {s['dec']}, forced {s['prop']}, total {s['units'] + s['dec'] + s['prop']} of {nv}")
rounds = fixtures(s['first'], pairs, 5)
for r, ms in enumerate(rounds): print(f"  round {r + 1}: " + " ".join(name(p) for p in ms))
print("verifier, reading the rules not the clauses: every rule kept:", "yes" if obeys(rounds) else "no")
assert obeys(rounds)
c = solve(nv, cl, count_all=True)
every = list(all_schedules(set(pairs), []))
good = [sc for sc in every if obeys(sc)]
print(f"road 2, fixture lists built directly: {len(every)} in all, {len(good)} keep the rules")
print(f"road 1, the solver counting every model: {c['models']} models in {c['dec']} decisions")
assert len(every) == 6 * math.factorial(5) and c['models'] == len(good) == 9
assert s['init'] == 2 * (4 + 4 + 4)  # A-B and C-F each rule out 4 other rounds and 4 + 4 rival matches
free = solve(*league(6, 5, rules=False)[:2], count_all=True)['models']; print(f"no extra rules: the solver counts {free} models")
assert free == len(every)
pts = []; print("teams | variables | clauses | in n - 1 rounds: decisions | in n - 2 rounds: decisions, answer")
for n in (4, 6, 8, 10):
    a = league(n, n - 1, rules=False); sa = solve(a[0], a[1])
    b = league(n, n - 2, rules=False); sb = solve(b[0], b[1])
    assert sa['models'] == 1 and sb['models'] == 0
    print(f"{n} | {a[0]} | {len(a[1])} | {sa['dec']} | {sb['dec']}, no schedule "
          f"({n * (n - 1) // 2} matches, {n // 2 * (n - 2)} slots)")
    pts.append((math.log10(sa['dec']), math.log10(sb['dec'])))
print("chart, log10 decisions:", " ".join(f"{a:.2f}/{b:.2f}" for a, b in pts))
for n in (12, 16, 20):
    a = league(n, n - 1, rules=False); sa = solve(a[0], a[1]); assert sa['models'] == 1
    print(f"{n} teams in {n - 1} rounds: {a[0]} variables, {len(a[1])} clauses, {sa['dec']} decisions, found")
mc = league(6, 5, clash=False)[1]; bad = fixtures(solve(nv, mc)['first'], pairs, 5); per = [len(ms) for ms in bad]
print(f"mistake 1, the once-a-round and every-round clauses dropped: {len(mc)} clauses, {len(cl) - len(mc)} fewer; "
      f"matches per round {' '.join(map(str, per))}; rules kept: {'yes' if obeys(bad) else 'no'}")
assert max(per) > 3 and not obeys(bad) and len(cl) - len(mc) == parts[2] + parts[3]
b = league(12, 10, rules=False); cp = solve(b[0], b[1], cap=100000)
print("mistake 2, 12 teams in 10 rounds, capped at 100,000 decisions:",
      "still undecided after 100,000 decisions" if cp['capped'] else "decided")
assert cp['capped']
print(f"mistake 3, blind search: 2^75 is about {2 ** 75 / 1e22:.2f}e22 assignments, against {s['dec']} decisions")
print(f"sudoku on an n by n grid as SAT: one variable per cell and digit, {4 ** 3} for 4 by 4, {9 ** 3} for 9 by 9")
assert sum(parts) == len(cl) and parts == [15, 15 * math.comb(5, 2), 6 * 5 * math.comb(5, 2), 6 * 5, 1 + 1 + 3 + 2 * 4]  # counted, against formulas
print("ALL CHECKS PASS")
