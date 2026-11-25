# Turing degrees and the arithmetical hierarchy -- the check behind the card.  Nothing is imported.
# Programs use six symbols  + - < > [ ]  on a row of cells holding 0, 1, 2, ... with no top
# ("-" leaves 0 at 0).  Input n starts in cell 0.  A program halts when it runs off its end.
# The interpreter is the one explained on the Decidable and semidecidable card, without "!".
class Run:
    def __init__(self, p, n):
        self.p, self.pc, self.ptr, self.tape, self.steps = p, 0, 0, ({0: n} if n else {}), 0
        self.jump, stack = {}, []
        for i, c in enumerate(p):
            if c == "[": stack.append(i)
            elif c == "]": j = stack.pop(); self.jump[i], self.jump[j] = j, i
    def halted(self): return self.pc >= len(self.p)
    def config(self): return (self.pc, self.ptr, tuple(sorted((k, v) for k, v in self.tape.items() if v)))
    def step(self):
        c, v = self.p[self.pc], self.tape.get(self.ptr, 0)
        self.steps += 1
        if c == "+": self.tape[self.ptr] = v + 1
        elif c == "-": self.tape[self.ptr] = max(v - 1, 0)
        elif c == ">": self.ptr += 1
        elif c == "<": self.ptr -= 1
        elif (c == "[" and v == 0) or (c == "]" and v != 0): self.pc = self.jump[self.pc]
        self.pc += 1
def certify(p, n, cap):                 # ("h", t): halts at step t; ("l", a, b): a repeat proves a loop
    r, seen = Run(p, n), {}
    while not r.halted() and r.steps < cap:
        if r.config() in seen: return ("l", seen[r.config()], r.steps)
        seen[r.config()] = r.steps; r.step()
    return ("h", r.steps) if r.halted() else ("?",)
def oracle(p, cap=5000):                # stand-in for a HALT oracle: every answer carries a proof
    a = certify(p, 0, cap)
    assert a[0] != "?", "the stand-in has no proof for " + p
    return a[0] == "h"
def not_total(e, ask, limit):           # oracle machine: ask HALT about "n plus signs, then e"
    for n in range(limit):
        if not ask("+" * n + e): return n, n + 1
    return None, limit
def blocks(prefix):                     # quantifier blocks, bounded quantifiers dropped
    out = []
    for q, var, bounded in prefix:
        if not bounded and (not out or out[-1] != q): out.append(q)
    return out
def level(prefix):
    b = blocks(prefix)
    return ("Sigma" if b[0] == "E" else "Pi") + str(len(b)) if b else "Delta0"
def negate(prefix): return [("A" if q == "E" else "E", v, bd) for q, v, bd in prefix]
def dual(lv): return lv.replace("Sigma", "P").replace("Pi", "Sigma").replace("P", "Pi")
def show(prefix): return " ".join(("exists " if q == "E" else "forall ") + v for q, v, bd in prefix)
ZOO = ["[-]", "[]", "-[]", "+[]", ">+<[[-]>-<]>[]"]
print("programs on inputs 0 to 9 (h halts, l loops, proved by a repeated configuration):")
table = {e: [certify(e, n, 5000) for n in range(10)] for e in ZOO}
for e in ZOO:
    row = table[e]
    print(f"  {e:15} {' '.join(a[0] for a in row)}   halting inputs {sum(a[0] == 'h' for a in row)} of 10")
print("[-] on input n halts at step:", " ".join(str(a[1]) for a in table["[-]"]))
a = certify("[]", 1, 50)
print(f"[] on input 1 repeats its configuration at steps {a[1]} and {a[2]}")
F = {"HALT": ([("E", "s", 0)], "H(e,0,s)"),
     "TOT": ([("A", "n", 0), ("E", "s", 0)], "H(e,n,s)"),
     "FIN": ([("E", "m", 0), ("A", "n", 0), ("A", "s", 0)], "n <= m or not H(e,n,s)"),
     "PROVABLE": ([("E", "p", 0)], "Proof(p,y)"),
     "UPTO": ([("A", "n<=m", 1), ("E", "s", 0)], "H(e,n,s)")}
print("quantifier blocks (bounded quantifiers dropped, repeats merged):")
for name, (pre, mat) in F.items():
    print(f"  {name:8} {show(pre) + ' : ' + mat:55} {level(pre):7} complement {level(negate(pre))}")
# road two: the reduction HALT <=m TOT, e -> [-]e, checked configuration by configuration
progs, layer = [], [""]
for _ in range(4):
    layer = [p + c for p in layer for c in "+-<>[]"]
    progs += [p for p in layer if all(p[:k].count("[") >= p[:k].count("]") for k in range(len(p) + 1))
              and p.count("[") == p.count("]")]
match, closed, halting = True, True, 0
for e in progs:
    base = certify(e, 0, 60)
    halting += base[0] == "h"
    for n in range(5):
        r, q = Run("[-]" + e, n), Run(e, 0)
        for _ in range(1 + 2 * n): r.step()
        for t in range(61):
            c1, c2 = r.config(), q.config()
            match &= (c1[0] - 3, c1[1], c1[2]) == c2 and r.halted() == q.halted()
            if q.halted(): break
            r.step(); q.step()
        if base[0] == "h": closed &= certify("[-]" + e, n, 200) == ("h", 1 + 2 * n + base[1])
print(f"reduction e -> [-]e on all {len(progs)} programs up to 4 symbols, inputs 0 to 4, 60 steps:")
print(f"  configurations agree at every step: {'yes' if match else 'no'}")
print(f"  {halting} halt on 0 within 60 steps; steps on n = 1 + 2n + steps of e: {'yes' if closed else 'no'}")
print(f"  -[] halts on 0 at step {certify('-[]', 0, 99)[1]}; [-]-[] on 0 to 4 at steps",
      " ".join(str(certify("[-]-[]", n, 99)[1]) for n in range(5)))
loops = all(certify("[-]+[]", n, 99)[0] == "l" for n in range(5)) and certify("+[]", 0, 99)[0] == "l"
print(f"  +[] loops on 0; [-]+[] loops on 0 to 4: {'yes' if loops else 'no'}")
# road three: an oracle machine for "not total" against a direct scan of the certified runs
print("oracle machine for 'not total', at most 30 questions to the HALT stand-in:")
found = {}
for e in ZOO:
    w, asked = not_total(e, oracle, 30)
    direct = next((n for n, a in enumerate(table[e]) if a[0] == "l"), None)
    found[e] = (w, direct)
    print(f"  {e:15} " + (f"oracle says no at question {asked}: witness n = {w}; direct scan {direct}"
                          if w is not None else f"still searching after {asked} questions, all yes"))
print("not in HALT, one question: +[] ->", "oracle yes -> answer no" if oracle("+[]") else "oracle no -> answer yes")
print("Post's theorem, levels against oracles:")
for k in range(1, 4):
    print(f"  Sigma{k}: semidecidable with oracle 0{chr(39) * (k - 1)}   Delta{k + 1}: decidable with oracle 0{chr(39) * k}")
# what breaks
naive = {name: len(pre) for name, (pre, mat) in F.items()}
print(f"mistake 1, counting quantifiers not blocks: FIN has {naive['FIN']}, read as Sigma{naive['FIN']}")
print(f"mistake 2, counting the bounded quantifier: UPTO read as Pi{naive['UPTO']}, true level {level(F['UPTO'][0])}")
nt = sum(any(a[0] == "l" for a in table[e]) for e in ZOO)
none = sum(all(a[0] == "l" for a in table[e]) for e in ZOO)
print(f"mistake 3, 'not total' read as 'halts on no input': {nt} of {len(ZOO)} not total, {none} of {len(ZOO)} halt on none")
capped = lambda p: certify(p, 0, 100)[0] == "h"
w100, asked100 = not_total("[-]", capped, 200)
print(f"mistake 4, a 100-step cap as the oracle: [-] called not total at n = {w100}, question {asked100}; "
      f"that question halts at step {certify('+' * w100 + '[-]', 0, 999)[1]}")
assert match and closed and loops and halting > 0                                   # simulation = closed form
assert all(w == d for w, d in found.values() if w is not None) and found["[-]"] == (None, None)
assert all(level(negate(pre)) == dual(level(pre)) for pre, m in F.values())
assert [name for name, (pre, m) in F.items() if naive[name] != len(blocks(pre))] == ["FIN", "UPTO"]
assert [level(F[k][0]) for k in ("HALT", "TOT", "FIN", "PROVABLE", "UPTO")] == ["Sigma1", "Pi2", "Sigma2", "Sigma1", "Sigma1"]  # by hand
assert w100 == min(n for n in range(200) if n + 1 + 2 * n > 100) and (nt, none) == (4, 1)
print("ALL CHECKS PASS")
