# Lambda calculus: two plus three with functions only, then a reducer that reads the program.
# Standard library only. A term is ('v', name), ('l', name, body) or ('a', function, argument).
def parse(s):
    toks, i = s.replace('(', ' ( ').replace(')', ' ) ').replace('.', ' . ').replace('λ', ' λ ').split(), 0
    def term():
        nonlocal i
        if toks[i] == 'λ':
            x, i = toks[i + 1], i + 3                  # skip λ, the name and the dot
            return ('l', x, term())
        t = atom()
        while i < len(toks) and toks[i] != ')':
            if toks[i] == 'λ': return ('a', t, term())  # a lambda argument runs to the end
            t = ('a', t, atom())                     # application groups to the left
        return t
    def atom():
        nonlocal i
        if toks[i] == '(':
            i += 1; t = term(); i += 1
            return t
        i += 1
        return ('v', toks[i - 1])
    return term()

def show(t):
    if t[0] == 'v': return t[1]
    if t[0] == 'l': return 'λ' + t[1] + '.' + show(t[2])
    f, a = show(t[1]), show(t[2])
    return ('(' + f + ')' if t[1][0] == 'l' else f) + ' ' + ('(' + a + ')' if t[2][0] != 'v' else a)

def free(t):
    if t[0] == 'v': return {t[1]}
    if t[0] == 'l': return free(t[2]) - {t[1]}
    return free(t[1]) | free(t[2])

def subst(t, x, s, rename=True):
    """t with every free x replaced by s; a binder that would capture a free name of s is renamed."""
    if t[0] == 'v': return s if t[1] == x else t
    if t[0] == 'a': return ('a', subst(t[1], x, s, rename), subst(t[2], x, s, rename))
    y, b = t[1], t[2]
    if y == x: return t
    if rename and y in free(s):
        z = y + "'"
        while z in free(s) | free(b): z += "'"
        y, b = z, subst(b, y, ('v', z))
    return ('l', y, subst(b, x, s, rename))

def step(t, order='normal', rename=True):
    """One beta step, or None at a normal form. normal = leftmost outermost; args = arguments first."""
    if t[0] == 'v': return None
    if t[0] == 'l':
        b = step(t[2], order, rename)
        return None if b is None else ('l', t[1], b)
    if order == 'normal' and t[1][0] == 'l': return subst(t[1][2], t[1][1], t[2], rename)
    f = step(t[1], order, rename)
    if f is not None: return ('a', f, t[2])
    a = step(t[2], order, rename)
    if a is not None: return ('a', t[1], a)
    return subst(t[1][2], t[1][1], t[2], rename) if t[1][0] == 'l' else None

def reduce(t, order='normal', cap=1000, trace=None):
    for n in range(cap + 1):
        if trace is not None: trace.append(t)
        u = step(t, order)
        if u is None: return t, n
        if u == t: return None, -n - 1              # the term came back unchanged: a proof it never stops
        t = u
    return None, cap                                 # still running after cap steps

def num(n):
    body = ('v', 'x')
    for _ in range(n): body = ('a', ('v', 'f'), body)
    return ('l', 'f', ('l', 'x', body))

def decode(t):
    """Read a normal form λf.λx.f (f (.. x)) back as a count of f's, else None."""
    if t[0] != 'l' or t[2][0] != 'l': return None
    f, x, b, k = t[1], t[2][1], t[2][2], 0
    while b[0] == 'a' and b[1] == ('v', f): b, k = b[2], k + 1
    return k if b == ('v', x) and f != x else None

def run(t, env):
    """Road 2: an environment evaluator. Numbers are host integers; inc adds one. No substitution."""
    if t[0] == 'v': return env[t[1]]
    if t[0] == 'l': return ('clo', t[1], t[2], env)
    f, a = run(t[1], env), run(t[2], env)
    return a + 1 if f == 'inc' else run(f[2], {**f[3], f[1]: a})

app = lambda *ts: ts[0] if len(ts) == 1 else ('a', app(*ts[:-1]), ts[-1])
SUCC, PLUS = parse('λn.λf.λx.f (n f x)'), parse('λm.λn.λf.λx.m f (n f x)')
TIMES, BAD = parse('λm.λn.λf.m (n f)'), parse('λm.λn.λf.λx.m (n f) x')
assert parse('λf.λx.f (f x)') == num(2) and parse('λf.λx.x') == num(0)
for name, t in [('two', num(2)), ('three', num(3)), ('succ', SUCC), ('plus', PLUS)]:
    print(f'term,{name},{show(t)}')
trace = []
five, steps = reduce(app(PLUS, num(2), num(3)), trace=trace)
for k, t in enumerate(trace): print(f'trace,{k},{show(t)}')
host = run(app(PLUS, num(2), num(3), ('v', 'inc'), ('v', 'zero')), {'inc': 'inc', 'zero': 0})
print(f'answer,decoded {decode(five)},host run {host},plain 2 + 3 = {2 + 3},beta steps {steps}')
assert decode(five) == 2 + 3 == host and five == num(5) and steps == 6
grid = [(m, n) for m in range(7) for n in range(7)]
for m, n in grid:
    r, s = reduce(app(PLUS, num(m), num(n)))
    r2, s2 = reduce(app(PLUS, num(m), num(n)), order='args')
    h = run(app(PLUS, num(m), num(n), ('v', 'inc'), ('v', 'zero')), {'inc': 'inc', 'zero': 0})
    assert decode(r) == m + n == h and r == r2 and s == s2 == 6
    assert decode(reduce(app(SUCC, num(m)))[0]) == m + 1
    assert decode(reduce(app(TIMES, num(m), num(n)))[0]) == m * n
print(f'grid,plus m n for m and n in 0..6: {len(grid)} pairs,all decode to m + n,both orders agree,6 steps each')
K = parse('λx.λy.x')
good, bad = step(app(K, ('v', 'y'))), step(app(K, ('v', 'y')), rename=False)
print(f'break,capture: (λx.λy.x) y,renamed {show(good)},naive {show(bad)}')
print(f"break,capture: then applied to z,renamed {show(step(app(good, ('v', 'z'))))},naive {show(step(app(bad, ('v', 'z'))))}")
assert step(app(good, ('v', 'z'))) == ('v', 'y') and step(app(bad, ('v', 'z'))) == ('v', 'z')
size = lambda t: 1 if t[0] == 'v' else 1 + size(t[2]) if t[0] == 'l' else 1 + size(t[1]) + size(t[2])
t = app(num(3), num(2))
for _ in range(12): t = step(t, rename=False)
print(f'break,capture: three two (power) naive,after 12 steps no answer,term size {size(t)} nodes against {size(num(8))} for 8')
assert decode(t) is None and size(t) > 1000 * size(num(8))
r, s = reduce(app(BAD, num(2), num(3)))
print(f'break,bracket moved: λm.λn.λf.λx.m (n f) x on two three,decodes to {decode(r)},not 5')
assert decode(r) == 6
OMEGA = parse('(λx.x x) (λx.x x)')
r, s = reduce(OMEGA)
print(f'break,omega {show(OMEGA)},after {-s} step the same term returns: no normal form')
assert r is None and s == -1
KO = app(K, ('v', 'y'), OMEGA)
r1, s1 = reduce(KO)
r2, s2 = reduce(KO, order='args')
print(f'break,(λx.λy.x) y omega,normal order {show(r1)} in {s1} steps')
print(f"break,(λx.λy.x) y omega,arguments first {'loops: omega returns unchanged' if s2 < 0 else 'still running'}")
assert show(r1) == 'y' and s1 == 2 and r2 is None
for label, t in [('times two three', app(TIMES, num(2), num(3))), ('three two (power)', app(num(3), num(2))),
                 ('plus twenty thirty', app(PLUS, num(20), num(30)))]:
    r, s = reduce(t)
    print(f'try,{label},decodes to {decode(r)},beta steps {s}')
assert decode(reduce(app(num(3), num(2)))[0]) == 2 ** 3
print('ALL CHECKS PASS')
