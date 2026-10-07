# Classifying states -- the check behind the card.  A token needs a six to leave S
# for a ring A, B, C, D; a coin moves it one square either way; D sends it to jail J.
# Fraction is exact arithmetic and knows nothing about chains.
from fractions import Fraction as F
N, S6, H2 = "SABCJ", F(1, 6), F(1, 2)
RULES = {"doubles": [F(1, 6), F(5, 6)], "at once": [F(1), F(0)], "no key": [F(0), F(1)]}
MASK, SEED, RUNS, HORIZON = (1 << 64) - 1, 20260929, 20000, 5000

def chain(rule):                         # rows S, A, B, C, J; the rule sets jail to A, J
    (a, j), z = RULES[rule], F(0)
    return [[1 - S6, S6, z, z, z], [z, z, H2, z, H2], [z, H2, z, H2, z], [z, z, H2, z, H2], [z, a, z, z, j]]

def boolmul(x, y):
    return [[any(x[i][k] and y[k][j] for k in range(5)) for j in range(5)] for i in range(5)]

def reach_powers(p):                     # road one: I or P or ... or P^4
    arrow = [[x > 0 for x in row] for row in p]
    pk = r = [[i == j for j in range(5)] for i in range(5)]
    for _ in range(4):
        pk = boolmul(pk, arrow)
        r = [[r[i][j] or pk[i][j] for j in range(5)] for i in range(5)]
    return r
def reach_search(p):                     # road two: follow arrows, depth first
    out = []
    for i in range(5):
        seen, stack = {i}, [i]
        while stack:
            u = stack.pop()
            for v in range(5):
                if p[u][v] > 0 and v not in seen:
                    seen.add(v); stack.append(v)
        out.append([j in seen for j in range(5)])
    return out

def classes(r):
    cs = []
    for i in range(5):
        c = tuple(j for j in range(5) if r[i][j] and r[j][i])
        if c not in cs: cs.append(c)
    return cs
def gcd(a, b):                           # Euclid
    return gcd(b, a % b) if b else a
def return_lengths(p, i, most):          # every n <= most with P^n(i,i) > 0
    arrow = [[x > 0 for x in row] for row in p]
    pk, out = arrow, []
    for n in range(1, most + 1):
        if pk[i][i]: out.append(n)
        pk = boolmul(pk, arrow)
    return out
def period_levels(p, c):                 # gcd of level jumps along arrows in class c
    lvl, queue = {c[0]: 0}, [c[0]]
    for u in queue:
        for v in c:
            if p[u][v] > 0 and v not in lvl:
                lvl[v] = lvl[u] + 1; queue.append(v)
    g = 0
    for u in c:
        for v in c:
            if p[u][v] > 0: g = gcd(g, abs(lvl[u] + 1 - lvl[v]))
    return g

def return_chance(p, i, reach):          # exact first-step equations for f_i
    ks = [k for k in range(5) if k != i and reach[k][i]]
    m = [[F(a == b) - p[a][b] for b in ks] + [p[a][i]] for a in ks]
    for c in range(len(ks)):             # Gauss-Jordan elimination in fractions
        piv = next(r for r in range(c, len(ks)) if m[r][c] != 0)
        m[c], m[piv] = m[piv], m[c]
        m[c] = [x / m[c][c] for x in m[c]]
        for r in range(len(ks)):
            if r != c: m[r] = [x - m[r][c] * y for x, y in zip(m[r], m[c])]
    h = [m[ks.index(k)][-1] if k in ks else F(0) for k in range(5)]
    return p[i][i] + sum(p[i][k] * h[k] for k in range(5) if k != i), h

def powers_row(p, i, n):                 # row i of P^0 .. P^n, floats
    row, rows = [1.0 if j == i else 0.0 for j in range(5)], []
    for _ in range(n + 1):
        rows.append(row)
        row = [sum(row[k] * float(p[k][j]) for k in range(5)) for j in range(5)]
    return rows

def uniform(s):                          # SplitMix64, the wing's generator
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def simulate(p, i, reach):               # share of runs back at i within HORIZON turns
    s, back = SEED + i, 0
    for _ in range(RUNS):
        x = i
        for _ in range(HORIZON):         # a run ends early where no arrows lead back
            if not reach[x][i]: break
            s, u = uniform(s)
            acc, y = 0.0, 4
            for j in range(5):
                acc += float(p[x][j])
                if u < acc: y = j; break
            x = y
            if x == i: back += 1; break
    f = back / RUNS
    return f, (f * (1 - f) / RUNS) ** 0.5

print(f"simulation: SplitMix64 seed {SEED}, {RUNS} runs per state, at most {HORIZON} turns a run, "
      "asserts within 4 standard errors; periods from return lengths up to 30 turns")
for rule in RULES:
    p = chain(rule)
    rp, rs = reach_powers(p), reach_search(p)
    assert rp == rs                                              # powers agree with search
    print(f"jail rule '{rule}': classes " + " ".join("{" + ",".join(N[k] for k in c) + "}" for c in classes(rp)))
    shut = {}                                                    # state -> is its class closed?
    for c in classes(rp):
        closed = all(p[i][j] == 0 for i in c for j in range(5) if j not in c)
        d = period_levels(p, c)
        for i in c:
            g = 0
            for n in return_lengths(p, i, 30): g = gcd(g, n)
            assert g == d                                        # return lengths agree with levels
            shut[i] = closed
        print(f"  class {''.join(N[k] for k in c)}: {'closed' if closed else 'open'}, period {d if d else 'none'}")
    for i in range(5):
        f, h = return_chance(p, i, rp)
        rows = powers_row(p, i, 1000)
        v, v500 = sum(r[i] for r in rows), sum(r[i] for r in rows[:501])
        fs, se = simulate(p, i, rp)
        assert abs(fs - float(f)) <= 4 * se + 1e-12              # simulation within 4 standard errors
        assert (f == 1) == shut[i]                               # recurrent exactly when the class is closed
        if f < 1: assert abs(v - 1 / (1 - float(f))) < 1e-9       # visits = 1/(1 - f) when f < 1
        else: assert v > 1.5 * v500                              # visits keep growing when f = 1
        print(f"  {N[i]}: f = {str(f):>3} = {float(f):.4f}, simulated {fs:.4f} +- {se:.4f}, visits to n=1000 {v:9.4f}, "
              + ("recurrent" if f == 1 else "transient"))
        if rule == "no key" and i == 1:
            hs = ", ".join(f"{N[k]} {h[k]}" for k in range(5) if k != i)
            print(f"  worked, 'no key': chance of reaching A from {hs}; f_A = 1/2 x {h[2]} + 1/2 x {h[4]} = {f}")
for rule in ("doubles", "at once"):
    rows = powers_row(chain(rule), 1, 201)
    print(f"figure, P^n(A,A), n = 0..16, '{rule}': " + ", ".join(f"{r[1]:.2f}" for r in rows[:17]))
    print(f"limit, '{rule}': P^200 from A: " + " ".join(f"{N[j]} {rows[200][j]:.4f}" for j in range(5)) + f"; P^201(A,A) = {rows[201][1]:.4f}")
    print(f"return lengths at A up to 8 turns, '{rule}': {', '.join(map(str, return_lengths(chain(rule), 1, 8)))}")
print("figure, node centres: S (40,60) A (140,60) B (280,60) C (280,180) J (140,180), radius 22")
print("ALL CHECKS PASS")
