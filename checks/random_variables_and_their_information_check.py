# Random variables and their information -- the check behind the card.
# Nothing is imported.  A toy league: each side scores 0 to 3 goals, home and
# away independent.  The 16 final scores are the outcomes; a set of scores is
# a 16-bit mask.  The total T = home + away generates sigma(T), built by two
# roads; Doob-Dynkin is then tested on every yes/no question about the score.
# The code checks one finite space exactly; the general theorem is the proof's.
PH = [25, 35, 25, 15]                    # P(home scores 0, 1, 2, 3), in hundredths
PA = [35, 35, 20, 10]                    # P(away scores 0, 1, 2, 3), in hundredths
SCORES = [(h, a) for h in range(4) for a in range(4)]
FULL = (1 << 16) - 1

def mask(test):                          # the set of scores passing a test
    return sum(1 << i for i, (h, a) in enumerate(SCORES) if test(h, a))

def prob(m):                             # road one: add score by score, in 1/10000
    return sum(PH[h] * PA[a] for i, (h, a) in enumerate(SCORES) if m >> i & 1)

def dec(n, d=10000):                     # n/d rounded to 4 places, integers only
    r = (20000 * n + d) // (2 * d)
    return f"{r // 10000}.{r % 10000:04d}"

def closure(gens):                       # sigma road one: complements, unions, repeat
    s, rounds = set(gens), [len(set(gens))]
    while True:
        new = s | {FULL ^ m for m in s} | {x | y for x in s for y in s}
        if new == s:
            return s, rounds
        s = new
        rounds.append(len(s))

def level_sets(f):                       # the scores sharing each value of f
    out = {}
    for i, (h, a) in enumerate(SCORES):
        out.setdefault(f(h, a), []).append(i)
    return out

def g_of(y, f):                          # build g with y = g(f) if one exists, else None
    g = {}
    for v, idx in sorted(level_sets(f).items()):
        vals = sorted({y(*SCORES[i]) for i in idx})
        if len(vals) > 1:
            return None, (v, vals)
        g[v] = vals[0]
    return g, None

total = lambda h, a: h + a
thresholds = [mask(lambda h, a, t=t: h + a <= t) for t in range(6)]
sig, rounds = closure(thresholds)
pre = {mask(lambda h, a, b=b: b >> (h + a) & 1) for b in range(1 << 7)}   # sigma road two
atoms = level_sets(total)
print("P(home scores 0..3): " + ", ".join(dec(x, 100) for x in PH) + "; P(away scores 0..3): " + ", ".join(dec(x, 100) for x in PA))
print(f"each side scores 0 to 3 goals: scores 16, questions about the score 2^16 = {1 << 16}")
print(f"sigma(T) from the thresholds 'T <= t?': {len(sig)} sets, rounds {' -> '.join(map(str, rounds))}")
print(f"sigma(T) as preimages of all 2^7 sets of totals: {len(pre)} sets; same family: {'yes' if sig == pre else 'no'}")
print("atoms, scores per total 0..6: " + ", ".join(str(len(atoms[t])) for t in range(7)))
print("total 2 atom: " + ", ".join(f"{SCORES[i][0]}-{SCORES[i][1]}" for i in atoms[2]))
const_on_atoms = [m for m in range(1 << 16)
                  if all(len({m >> i & 1 for i in idx}) == 1 for idx in atoms.values())]
agree = all((m in sig) == (m in set(const_on_atoms)) for m in range(1 << 16))
print(f"of {1 << 16} questions: in sigma(T) {len(sig)}, constant on every atom {len(const_on_atoms)}, "
      f"agree on all: {'yes' if agree else 'no'}")
questions = [
    ("more than 3 goals", lambda h, a: h + a > 3),
    ("no goals at all", lambda h, a: h + a == 0),
    ("total is even", lambda h, a: (h + a) % 2 == 0),
    ("margin is even", lambda h, a: (h - a) % 2 == 0),
    ("home won", lambda h, a: h > a),
    ("draw", lambda h, a: h == a),
    ("both teams scored", lambda h, a: h > 0 and a > 0),
]
print("question            | scores | P      | in sigma(T) | g(0..6) or the atom that splits")
verdict = {}
for name, test in questions:
    m = mask(test)
    g, clash = g_of(lambda h, a: int(test(h, a)), total)
    verdict[name] = (m in sig, g is not None)
    shown = "".join(str(g[t]) for t in range(7)) if g else f"total {clash[0]} gives {clash[1]}"
    print(f"{name:19} | {bin(m).count('1'):6} | {dec(prob(m))} | {'yes' if m in sig else 'no':11} | {shown}")
bet = lambda h, a: 19 if h + a > 3 else 0                 # 10 staked on over 3.5, returns 19
gb, _ = g_of(bet, total)
gbv = [gb[t] for t in range(7)] if gb else []              # empty when the bet is no function of T
print(f"10 staked on over 3.5 returns g(T), g = {gbv}")
gm, clash = g_of(lambda h, a: h - a, total)
print(f"home margin as g(T): {'exists' if gm else 'none'}; total {clash[0]} gives margins {clash[1]}")
# probabilities by a second road: the law of T by convolution, and a running total
law = [sum(PH[h] * PA[t - h] for h in range(4) if 0 <= t - h <= 3) for t in range(7)]
home_win2 = sum(PH[h] * sum(PA[:h]) for h in range(4))
print("law of T, P(T = 0..6): " + ", ".join(dec(p) for p in law))
print(f"P(more than 3): by scores {dec(prob(mask(lambda h, a: h + a > 3)))}, by the law of T {dec(sum(law[4:]))}")
print(f"P(home won): by scores {dec(prob(mask(lambda h, a: h > a)))}, by home goals and a running total {dec(home_win2)}")
hw = mask(lambda h, a: h > a)
cond = [(prob(hw & mask(lambda h, a, t=t: h + a == t)), law[t]) for t in range(7)]
print("P(home won | T = t), t = 0..6: " + ", ".join(dec(n, d) for n, d in cond))
print(f"  total 1 by hand: {cond[1][0]}/{cond[1][1]} = {dec(*cond[1])}")
# what breaks
coarse, _ = closure([mask(lambda h, a: h + a > 3)])
print(f"mistake 1, home won read off the total: P(home won | T = 1) = {dec(*cond[1])}, not 0 or 1")
print(f"mistake 2, sigma(T) taken as its 7 values: it has 2^7 = {len(sig)} sets")
print(f"mistake 3, only 'more than 3?' recorded: {len(coarse)} sets; settles 'exactly 2 goals': "
      f"{'yes' if mask(lambda h, a: h + a == 2) in coarse else 'no'}")
sq, _ = closure([mask(lambda h, a, v=v: (h + a) ** 2 == v) for v in range(37)])
print(f"relabelled total T*T generates the same family: {'yes' if sq == sig else 'no'}")
cx = lambda h: 95 + 50 * h                                 # the picture: 50 units per goal
cy = lambda a: 185 - 50 * a
ends = [(max(0, t - 3), min(3, t)) for t in range(7)]
print("figure, cell 50, grid x 70..270, y 10..210, total lines from (x, y) to (x, y): "
      + "; ".join(f"{t}: {cx(h)},{cy(t - h)} {cx(k)},{cy(t - k)}" for t, (h, k) in enumerate(ends)))
assert sig == pre and len(sig) == 2 ** len(atoms) == 128                  # two roads, one sigma(T)
assert agree and len(const_on_atoms) == 128                               # Doob-Dynkin on 65536 questions
assert [v for v, _ in verdict.values()] == [True, True, True, True, False, False, False]
assert all(v == w for v, w in verdict.values())                          # membership = a g exists
assert sum(law[4:]) == prob(mask(lambda h, a: h + a > 3)) and home_win2 == prob(hw)
assert len(coarse) == 4 and mask(lambda h, a: h + a == 2) not in coarse    # mistake 3
assert sq == sig and gm is None and gbv == [0, 0, 0, 0, 19, 19, 19]       # T*T; margin; the bet's g by hand
assert cond[1] == (PH[1] * PA[0], PH[0] * PA[1] + PH[1] * PA[0])           # 1-0 over 1-0 or 0-1, by hand
print("ALL CHECKS PASS")
