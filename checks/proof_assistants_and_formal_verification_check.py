# Proof assistants -- the check behind the card.  Nothing is imported.  A tiny
# proof checker (the "kernel") accepts a proof only if every line follows from
# earlier lines by one of its eight rules.  Road 1: it checks an 11-step proof
# that no fraction p/q squares to 2.  Road 2: search.  Road 3: factors of 2.
def parse(side):                  # "4*k*k+4*k+1" -> {"kk": 4, "k": 4, "": 1}
    poly = {}
    for term in side.split("+"):
        c, mono = 1, ""
        for f in term.strip().split("*"):
            if f.isdigit(): c *= int(f)
            else: mono += f
        mono = "".join(sorted(mono))
        poly[mono] = poly.get(mono, 0) + c
    return poly
def mul(a, b):
    out = {}
    for ma, ca in a.items():
        for mb, cb in b.items():
            m = "".join(sorted(ma + mb))
            out[m] = out.get(m, 0) + ca * cb
    return out
def subst(poly, x, t):            # replace the letter x by the polynomial t
    out = {}
    for mono, c in poly.items():
        term = {"": c}
        for v in mono: term = mul(term, t if v == x else {v: 1})
        for m, d in term.items(): out[m] = out.get(m, 0) + d
    return out
def fact(claim):                  # "L = R", "L < R", "L <= R" or "FALSE"
    for op in ("<=", "<", "="):
        if op in claim:
            l, r = claim.split(op)
            return (op, parse(l), parse(r))
    return ("FALSE",)
def var(poly):                    # the letter, if poly is one bare letter
    m = next(iter(poly))
    return m if len(poly) == 1 and poly[m] == 1 and len(m) == 1 else None
def even(poly): return all(c % 2 == 0 for c in poly.values())
def odd_clash(a, b): return a.get("", 0) % 2 == 1 and even({m: c for m, c in a.items() if m}) and even(b)
BUGGY, SHOW = False, False        # switches: a planted kernel bug, and printing each step
def rule_ok(rule, f, got, givens):
    if rule == "subst":           # from x = t and L = R: L and R with x replaced by t
        (op1, x, t), (op2, l, r) = got
        return op1 == "=" and var(x) and op2 == f[0] and f[1:] == (subst(l, var(x), t), subst(r, var(x), t))
    if rule == "halve":           # from 2A = 2B: A = B
        op, l, r = got[0]
        return op == "=" and even(l) and even(r) and f == ("=", {m: c // 2 for m, c in l.items()}, {m: c // 2 for m, c in r.items()})
    if rule == "clash":           # odd = even can never hold
        op, l, r = got[0]
        if BUGGY: return op == "=" and l.get("", 0) % 2 == 1      # the bug: forgets the other terms
        return op == "=" and f == ("FALSE",) and (odd_clash(l, r) or odd_clash(r, l))
    if rule == "half":            # from x = 2*y and 1 <= x: y < x, and 1 <= y
        (op1, x, t), (op2, one, x2) = got
        y = next(iter(t))
        return (op1 == "=" and op2 == "<=" and one == {"": 1} and x2 == x and t == {y: 2}
                and f in (("<", {y: 1}, x), ("<=", {"": 1}, {y: 1})))
    if rule == "descent":         # a smaller solution, so the smallest q was not the smallest
        (op1, l, r), pos, less = got
        k, m = next(iter(l))[0], var(less[1])
        g1, g2 = fact(givens[0]), fact(givens[1])
        return (f == ("FALSE",) and (op1, l, r) == ("=", subst(g1[1], "p", {k: 1}), subst(g1[2], "q", {m: 1}))
                and pos == ("<=", g2[1], subst(g2[2], "q", {m: 1})) and less == ("<", {m: 1}, {"q": 1}))
    return False
def check(proof, givens, seen, facts=None, case=None):
    facts, f = dict(facts or {}), None
    for i, (label, claim, rule, refs, sub) in enumerate(proof):
        f, why = fact(claim), ""
        try:
            got = [facts[r] for r in refs]
            if rule == "even":    # x = 2*y, because the odd case x = 2*y+1 ends in FALSE
                x, y = var(f[1]), next(iter(f[2]))
                ok = f[0] == "=" and x and f[2] == {y: 2} and y not in seen and sub != []
                why = check(sub, givens, seen | {y}, facts, f"{x} = 2*{y}+1") if ok else ""
                ok = ok and why == "FALSE"
            else:
                ok = (rule == "given" and claim in givens or rule == "case" and i == 0 and claim == case
                      or rule_ok(rule, f, got, givens))
        except (KeyError, IndexError, ValueError, StopIteration, TypeError):
            ok = False
        if SHOW: print(f"  {label:<4}{claim:<22}{rule:<8}{','.join(refs):<9}{'ok' if ok else 'REJECTED'}")
        if not ok: return why if why.startswith("rejected") else f"rejected at step {label}"
        facts[label] = f
        seen = seen | (set("".join(f[1]) + "".join(f[2])) if len(f) > 1 else set())
    return "FALSE" if f == ("FALSE",) else "no contradiction"
ODD_P = [("3a", "p = 2*k+1", "case", [], []), ("3b", "4*k*k+4*k+1 = 2*q*q", "subst", ["3a", "1"], []),
         ("3c", "FALSE", "clash", ["3b"], [])]
ODD_Q = [("6a", "q = 2*m+1", "case", [], []), ("6b", "2*k*k = 4*m*m+4*m+1", "subst", ["6a", "5"], []),
         ("6c", "FALSE", "clash", ["6b"], [])]
PROOF = [("1", "p*p = 2*q*q", "given", [], []), ("2", "1 <= q", "given", [], []),
         ("3", "p = 2*k", "even", [], ODD_P), ("4", "4*k*k = 2*q*q", "subst", ["3", "1"], []),
         ("5", "2*k*k = q*q", "halve", ["4"], []), ("6", "q = 2*m", "even", [], ODD_Q),
         ("7", "2*k*k = 4*m*m", "subst", ["6", "5"], []), ("8", "k*k = 2*m*m", "halve", ["7"], []),
         ("9", "m < q", "half", ["6", "2"], []), ("10", "1 <= m", "half", ["6", "2"], []),
         ("11", "FALSE", "descent", ["8", "10", "9"], [])]
GIVENS = ["p*p = 2*q*q", "1 <= q"]
def swap(proof, old, new):        # the same proof with one piece of text replaced
    return [(a, b.replace(old, new), c, d, swap(e, old, new)) for a, b, c, d, e in proof]
def twos(n): return 0 if n % 2 else 1 + twos(n // 2)    # how many times 2 divides n
print("kernel rules: given, case, subst, halve, clash, even, half, descent (8)\n"
      "  step claim                 rule    uses     verdict")
SHOW = True; verdict = check(PROOF, GIVENS, set("pq")); SHOW = False
print(f"road 1, the checker: {verdict} reached from the givens, so no such p and q exist")
B, sols, near, p = 10000, [], [], 0          # road 2: for each q, walk p up to the root of 2*q*q
for q in range(1, B + 1):
    while (p + 1) * (p + 1) <= 2 * q * q: p += 1
    if p * p == 2 * q * q: sols.append((p, q))
    near += [f"{c}/{q}" for c in (p, p + 1) if abs(c * c - 2 * q * q) == 1]
print(f"road 2, search 1 <= q <= {B}: solutions {sols if sols else 'none up to ' + str(B)}")
print(f"  misses by exactly 1: {' '.join(near)}")
print(f"  99*99 = {99 * 99} and 2*70*70 = {2 * 70 * 70}; 99/70 squared = {99 * 99 / 4900:.6f}")
N = 20000                                    # road 3: an even count of 2s can never equal an odd one
ev, od = sum(twos(n * n) % 2 == 0 for n in range(1, N + 1)), sum(twos(2 * n * n) % 2 == 1 for n in range(1, N + 1))
print(f"road 3, factors of 2 for n = 1 to {N}: n*n has an even count {ev} times, 2*n*n an odd count {od} times")
print("what breaks:")
FORGED = [("k*k = q*q", ("5", "k*k = q*q", "halve", ["4"], [])), ("4*k*k = 3*q*q", ("4", "4*k*k = 3*q*q", "subst", ["3", "1"], [])),
          ("q < m", ("9", "q < m", "half", ["6", "2"], [])), ("p = 2*q, reusing q", ("3", "p = 2*q", "even", [], swap(ODD_P, "k", "q"))),
          ("p = 2*k, odd case left out", ("3", "p = 2*k", "even", [], []))]
forged = [check([f if s[0] == f[0] else s for s in PROOF], GIVENS, set("pq")) for d, f in FORGED]
for (d, f), v in zip(FORGED, forged): print(f"  step {f[0]} forged as {d}: {v}")
m2 = check([s for s in PROOF if s[0] != "2"], GIVENS[:1], set("pq"))
zero = [(a, b) for a in range(3) for b in range(3) if a * a == 2 * b * b]
print(f"  given 1 <= q dropped: {m2}; the search finds p, q = {zero[0]}, so the shorter claim is false")
bug = [("1", "k+1 = 2*q", "given", [], []), ("2", "FALSE", "clash", ["1"], [])]
BUGGY = True; b1 = check(bug, ["k+1 = 2*q"], set("kq")); BUGGY = False; b2 = check(bug, ["k+1 = 2*q"], set("kq"))
kq = [(k, q) for k in range(4) for q in range(4) if k + 1 == 2 * q]
print(f"  buggy clash rule on k+1 = 2*q: {b1}; correct kernel: {b2}; yet k, q = {kq[0]} solves it")
h3 = check([("1", "3*k*k = 2*q*q", "given", [], []), ("2", "k*k = q*q", "halve", ["1"], [])], ["3*k*k = 2*q*q"], set("kq"))
le = check([("9", "m <= q", "given", [], []) if s[0] == "9" else s for s in PROOF], GIVENS + ["m <= q"], set("pq"))
print(f"  halve on 3*k*k = 2*q*q, an odd side: {h3}; descent fed m <= q, not m < q: {le}")
print("try changing:")
m5 = check(swap(PROOF, '2*q*q', '3*q*q'), ['p*p = 3*q*q', '1 <= q'], set('pq')); print(f"  3 in place of 2: {m5}")
four = [(a, b) for b in range(1, 4) for a in range(9) if a * a == 4 * b * b]
m4 = check(swap(PROOF, '2*q*q', '4*q*q'), ['p*p = 4*q*q', '1 <= q'], set('pq')); print(f"  4 in place of 2: {m4}; the search finds {four}")
print(f"  whole-number square root of 2: {(r := max(n for n in range(3) if n * n <= 2))}, and {r}*{r} = {r * r}, not 2")
print("record (quoted, not computed): BB(5) = 47176870, settled in 2024 in Coq")
assert verdict == "FALSE" and forged == [f"rejected at step {n}" for n in (5, 4, 9, 3, 3)] and h3 == "rejected at step 2" and le == "rejected at step 11"
assert sols == [] and near[5] == "99/70" and len(near) == 11 and zero == [(0, 0)]
assert ev == N and od == N and m2 == "rejected at step 9" and m4 == "rejected at step 5" and m5 == "rejected at step 3c"
assert b1 == "FALSE" and b2 == "rejected at step 2" and kq[0] == (1, 1) and four == [(2, 1), (4, 2), (6, 3)]
print("ALL CHECKS PASS")
