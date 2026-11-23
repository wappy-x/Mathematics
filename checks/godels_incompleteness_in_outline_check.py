# Godel's theorems -- the check behind the card.  Standard library only.  It
# runs the construction behind the proof, never an impossible program: it
# numbers sentences, builds the sentence G that speaks about its own number,
# and checks a proof in arithmetic step by step.  Nothing is imported.
CODES = {'0': 1, 'S': 2, '+': 3, '*': 4, '=': 5, '(': 6, ')': 7, '~': 8, 'x': 9, 'P': 10, 'D': 11}
SYMS = {v: k for k, v in CODES.items()}

def godel(s):                                # the code number: s read as base-16 digits
    n = 0
    for c in s: n = n * 16 + CODES[c]
    return n
def decode(n):                               # back again, by division only
    out = ""
    while n > 0: n, d = divmod(n, 16); out = SYMS[d] + out
    return out
def num(n):                                  # the numeral: a term whose value is n, in binary
    if n == 0: return "0"
    t = "S0"                                 # the leading 1; then double, adding S on a 1 bit
    for bit in bin(n)[3:]: t = ("S" if bit == "1" else "") + "(SS0*" + t + ")"
    return t
def value(t, i=0):                           # read a term's value off its symbols
    if t[i] == '0': return 0, i + 1
    if t[i] == 'S': v, j = value(t, i + 1); return v + 1, j
    a, j = value(t, i + 1); b, k = value(t, j + 1)       # '(' a op b ')'
    return (a + b if t[j] == '+' else a * b), k + 1
def diag(s): return s.replace('x', num(godel(s)))       # road A: on symbols
def diag_arith(n):                           # road B: the same map on numbers only
    lo, k, m = 0, 0, n
    while m and m % 16 != CODES['x']: lo += (m % 16) * 16 ** k; m //= 16; k += 1
    t = num(n)                                # m // 16: the digits left of x
    return ((m // 16) * 16 ** len(t) + godel(t)) * 16 ** k + lo

def row(name, v): print(f"{name:<44}{v}")
print("-- numbering --")
ONE = "S0+S0=SS0"
row("code of the sentence S0+S0=SS0 (1 + 1 = 2)", godel(ONE))
row("decoded back by division", decode(godel(ONE)))
X = "~P(D(x))"
gx = godel(X)
row("code of the template X = ~P(D(x))", gx)
row("numeral of that code, in symbols", len(num(gx)))
row("value read back off the numeral", value(num(gx))[0])
print("-- the sentence G = X with its own code put in --")
G = diag(X)
gg = godel(G)
row("length of G, in symbols", len(G))
row("digits in the code of G", len(str(gg)))
row("code of G begins", str(gg)[:12])
row("code of G ends", str(gg)[-12:])
inner = value(G[5:-2])[0]                    # road C: the term D is applied to inside G
row("D's argument inside G evaluates to", inner)
row("road A and road B agree on the code of G", godel(diag(X)) == diag_arith(gx))
row("D(argument) is the code of G itself", diag_arith(inner) == gg)

def term(s, i=0):                            # parse "SS0*SS0" style terms into trees
    if s[i] == '0': return ('0',), i + 1
    if s[i] == 'S': t, j = term(s, i + 1); return ('S', t), j
    a, j = term(s, i + 1); b, k = term(s, j + 1); return (s[j], a, b), k + 1
def show(t):                                 # a tree back to symbols
    if t[0] == '0': return '0'
    return 'S' + show(t[1]) if t[0] == 'S' else '(' + show(t[1]) + t[0] + show(t[2]) + ')'
def root(t, extra):                          # every rule that fits at the top of t
    out = []
    if t[0] == '+' and t[2] == ('0',): out.append(t[1])                          # a+0 = a
    if t[0] == '+' and t[2][0] == 'S': out.append(('S', ('+', t[1], t[2][1])))    # a+Sb = S(a+b)
    if t[0] == '*' and t[2] == ('0',): out.append(('0',))                        # a*0 = 0
    if t[0] == '*' and t[2][0] == 'S': out.append(('+', ('*', t[1], t[2][1]), t[1]))  # a*Sb = a*b+a
    if extra and t == ('0',): out.append(('S', ('0',)))                          # the bad axiom 0 = S0
    return out
def steps(t, extra=False):                   # every term one rule-use away from t
    out = root(t, extra)
    for k in range(1, len(t)):
        out += [t[:k] + (u,) + t[k + 1:] for u in steps(t[k], extra)]
    return out
def checker(chain, extra=False): return all(b in steps(a, extra) for a, b in zip(chain, chain[1:]))
def shortest(start, goal, cap):              # breadth-first proof search, capped
    level, seen = [start], {start}
    for d in range(cap + 1):
        if goal in level: return d
        level = [u for t in level for u in steps(t) if u not in seen and not seen.add(u)]
    return None

print("-- a proof in arithmetic: 2 x 2 = 4, one rule per line --")
chain = [term("(SS0*SS0)")[0]]
while steps(chain[-1]): chain.append(steps(chain[-1])[0])
for i, t in enumerate(chain): print(f"line {i:<3}{show(t)}")
four = ('S', ('S', ('S', ('S', ('0',)))))
best = shortest(chain[0], four, 20)
row("lines the checker accepts", checker(chain))
row("rule uses, first rule each time", len(chain) - 1)
row("rule uses, shortest proof by search", best)
row("2 x 2 by machine arithmetic", 2 * 2)
print("-- what breaks --")
bad = chain + [('S', four)]
row("2 x 2 = 5, checked with the true rules", checker(bad))
row("2 x 2 = 5, checked with 0 = S0 added", checker(bad, extra=True))
r = shortest(chain[0], four, best - 1)
row(f"search capped at {best - 1} rule uses", "none up to the cap" if r is None else r)
H = "~P(" + num(godel("~P(x)")) + ")"
pointed = value(H[3:-1])[0]                  # the number H's numeral stands for
row("H = ~P(x) filled without D points at", pointed)
row("digits in the code of H itself", len(str(godel(H))))
fits = [L for L in range(1, 401) if len(num(godel('0' * L))) <= L]
row("sentence holding its own numeral, 1 to 400", "none up to 400" if not fits else fits)
row("numeral of the smallest 8-symbol code", len(num(godel('0' * 8))))

assert decode(godel(ONE)) == ONE and godel(ONE) == 0x213215221
assert value(num(gx))[0] == gx == 0x8A6B6977          # numeral and code agree
assert godel(diag(X)) == diag_arith(gx)               # road A against road B
assert inner == gx and diag_arith(inner) == gg        # road C: G names itself
assert checker(chain) and value(show(chain[-1]))[0] == 2 * 2 and chain[-1] == four
assert best is not None and best <= len(chain) - 1 and r is None
assert not checker(bad) and checker(bad, extra=True)
assert decode(pointed) == "~P(x)"                     # H points at the template, not at itself
assert len(str(godel(H))) == len(str(CODES[H[0]] * 16 ** (len(H) - 1))) == len(str(16 ** len(H) - 1))  # from H's length
assert not fits
print("ALL CHECKS PASS")
