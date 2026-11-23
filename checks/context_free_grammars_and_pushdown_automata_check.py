# Grammars and a stack -- the check behind the card.  Standard library only; nothing is imported.
# A song sheet is a string of sections: v verse, c chorus, b bridge.  An arch song climbs to one
# bridge and comes back down in mirror order, and the grammar  S -> vSv | cSc | b  says exactly that.
# Five roads must agree on all 29524 sheets of 0 to 9 sections: a stack machine built by hand, a
# stack machine built from the grammar, the table method (CYK) on Chomsky normal form, the
# grammar's strings listed by derivation, and the plain definition (one b, in the middle, a mirror).

# ---- the stack machine, written out here first (later cards copy this part) ----
# A move is (state, read, pop, push, next).  '' means read nothing or pop nothing; push is written
# top first.  The stack is a string whose last letter is the top; Z is the bottom marker, shown as ⊥.
# run() tries every choice, depth first, and returns the moves of a run that reaches state "yes"
# with the whole sheet read, or None.  Every stack symbol above Z costs at least one more section,
# so a run holding more of them than sections left is dropped: that keeps the search finite.
def run(moves, w, start="up", cap=None):
    todo, seen, far = [(start, 0, "Z", ())], set(), 0
    while todo:
        q, i, st, path = todo.pop()
        far = max(far, i)
        if q == "yes" and i == len(w): return path, far
        if (q, i, st) in seen: continue
        seen.add((q, i, st))
        for p, a, x, y, r in reversed(moves):
            if p != q or (a and w[i:i + 1] != a) or not st.endswith(x): continue
            s2, i2 = st[:len(st) - len(x)] + y[::-1], i + len(a)
            if len(s2) - 1 > len(w) - i2 or (cap is not None and len(s2) - 1 > cap): continue
            todo.append((r, i2, s2, path + ((a or "ε", s2),)))
    return None, far
HAND = [("up", "v", "", "v", "up"), ("up", "c", "", "c", "up"), ("up", "b", "", "", "down"),
        ("down", "v", "v", "", "down"), ("down", "c", "c", "", "down"), ("down", "", "Z", "", "yes")]
GUESS = [m for m in HAND if m[1] != "b"] + [("up", "", "", "", "down")]   # no bridge: guess the middle
RULES = [("S", "vSv"), ("S", "cSc"), ("S", "b")]
def from_grammar(rules):  # one state does the work: swap the top variable for a rule, or match a letter
    return ([("start", "", "", "S", "loop")] + [("loop", "", A, u, "loop") for A, u in rules]
            + [("loop", t, t, "", "loop") for t in "vcb"] + [("loop", "", "Z", "", "yes")])
GRAM = from_grammar(RULES)
def ok(moves, w, start="up", cap=None): return run(moves, w, start, cap)[0] is not None
# ---- road 3: the table method on Chomsky normal form, counting parse trees ----
CNF_BIN = [("S", "V", "P"), ("S", "C", "R"), ("P", "S", "V"), ("R", "S", "C")]
CNF_ONE = {"v": ["V"], "c": ["C"], "b": ["S"]}
def cyk(w, bins, ones):   # T[i, l]: for each variable, how many parse trees give w[i:i+l]
    n, splits = len(w), 0
    T = {(i, 1): {A: 1 for A in ones[w[i]]} for i in range(n)}
    for l in range(2, n + 1):
        for i in range(n - l + 1):
            cell = {}
            for k in range(1, l):
                splits += 1
                for A, B, C in bins:
                    m = T[i, k].get(B, 0) * T[i + k, l - k].get(C, 0)
                    if m: cell[A] = cell.get(A, 0) + m
            T[i, l] = cell
    return (T[0, n].get("S", 0) if n else 0), splits
# ---- road 4: list the grammar's strings; road 5: the plain definition ----
def listed(rules, nmax):  # expand the leftmost S every way; a form longer than nmax can only grow
    forms, done = ["S"], set()
    while forms:
        f = forms.pop(); j = f.find("S")
        if j < 0: done.add(f); continue
        forms += [g for g in (f[:j] + u + f[j + 1:] for _, u in rules) if len(g) <= nmax]
    return done
def arch(w): return len(w) % 2 == 1 and w.count("b") == 1 and w[len(w) // 2] == "b" and w == w[::-1]
def sheets(alpha, nmax):
    lvl, out = [""], [""]
    for _ in range(nmax): lvl = [s + a for s in lvl for a in alpha]; out += lvl
    return out
def queue_ok(w):          # the mistake: read the first half back first in, first out
    line, down = [], False
    for a in w:
        if not down:
            if a == "b": down = True
            else: line.append(a)
        elif not line or line.pop(0) != a: return False
    return down and not line
def choose(n, k):
    r = 1
    for j in range(k): r = r * (n - j) // (j + 1)
    return r
def show(st): return st.replace("Z", "⊥") or "(empty)"
SONG, BAD, DEEP = "vvcbcvv", "vvcbvcv", "vvccbccvv"
print(f"song sheet {SONG}: {len(SONG)} sections, verse verse chorus bridge chorus verse verse")
path, _ = run(HAND, SONG)
print("hand-built machine, move by move (stack bottom to top):")
for k, (a, st) in enumerate(path, 1): print(f"  move {k}  read {a}  stack {show(st)}")
gpath, i, forms = run(GRAM, SONG, "start")[0], 0, []
for a, st in gpath:
    i += a != "ε"; f = SONG[:i] + st[::-1].replace("Z", "")
    if not forms or forms[-1] != f: forms.append(f)
trees, splits7 = cyk(SONG, CNF_BIN, CNF_ONE)
print(f"grammar-built machine: {len(gpath)} moves; derivation {' ⇒ '.join(forms)}")
print(f"parse trees for {SONG}: {trees}; table method used {splits7} splits")
bad_far = run(HAND, BAD)[1]
print(f"bad sheet {BAD}: hand-built {'accepts' if ok(HAND, BAD) else 'rejects'}, grammar-built "
      f"{'accepts' if ok(GRAM, BAD, 'start') else 'rejects'}; stuck after {bad_far} sections")
ALL, LIST = sheets("vcb", 9), listed(RULES, 9)
votes = [(ok(HAND, w), ok(GRAM, w, "start"), cyk(w, CNF_BIN, CNF_ONE)[0] > 0, w in LIST, arch(w)) for w in ALL]
agree, yes = sum(len(set(v)) == 1 for v in votes), [w for w, v in zip(ALL, votes) if v[4]]
bylen = [sum(len(w) == n for w in yes) for n in (1, 3, 5, 7, 9)]
most = max(cyk(w, CNF_BIN, CNF_ONE)[0] for w in yes)
print(f"all sheets of 0 to 9 sections: {len(ALL)}; all five roads agree on {agree}")
print(f"arch songs of 1 3 5 7 9 sections: {' '.join(map(str, bylen))}; total {len(yes)}; most parse trees {most}")
def arch_of(n): h = ("vc" * n)[:(n - 1) // 2]; return h + "b" + h[::-1]
big = {n: (len(run(HAND, arch_of(n))[0]), cyk(arch_of(n), CNF_BIN, CNF_ONE)[1]) for n in (7, 15, 101)}
print("cost at 7, 15, 101 sections: stack moves " + ", ".join(str(big[n][0]) for n in big)
      + "; table splits " + ", ".join(str(big[n][1]) for n in big))
print("what breaks:")
qa = [w for w in ALL if queue_ok(w)]
print(f"  queue for stack: vvcbvvc {'accepted' if queue_ok('vvcbvvc') else 'rejected'}, {SONG} "
      f"{'accepted' if queue_ok(SONG) else 'rejected'}; accepts {len(qa)} sheets, {sum(arch(w) for w in qa)} of them arch")
hold3 = len(sheets("vc", 3)); miss3 = sum(not ok(HAND, w, cap=3) for w in yes)
print(f"  fixed memory, stack capped at 3 ({hold3} contents): {DEEP} "
      f"{'accepted' if ok(HAND, DEEP, cap=3) else 'rejected'}; misses {miss3} of {len(yes)} arch songs")
EVEN = sheets("vc", 8); ga = [w for w in EVEN if ok(GUESS, w)]; mirrors = sum(len(w) % 2 == 0 and w == w[::-1] for w in ga)
print(f"  no bridge: vccv hand-built {'accepts' if ok(HAND, 'vccv') else 'rejects'}, guessing machine "
      f"{'accepts' if ok(GUESS, 'vccv') else 'rejects'}; of {len(EVEN)} bridge-less sheets it accepts "
      f"{len(ga)}, even mirrors {mirrors}")
AMB_BIN, AMB_ONE = [("S", "S", "S")], {t: ["S"] for t in "vcb"}
amb7, amb9 = cyk(SONG, AMB_BIN, AMB_ONE)[0], cyk(DEEP, AMB_BIN, AMB_ONE)[0]
print(f"  grammar S -> SS | v | c | b: {SONG} has {amb7} parse trees, closed form {choose(12, 6) // 7}")
print("try changing:")
L11 = listed(RULES, 11)
print(f"  cap 4: misses {sum(not ok(HAND, w, cap=4) for w in yes)} of {len(yes)} up to 9 sections, "
      f"{sum(not ok(HAND, w, cap=4) for w in L11)} of {len(L11)} up to 11")
R2 = RULES + [("S", "vSc"), ("S", "cSv")]; L2 = listed(R2, 9); G2 = from_grammar(R2)
print(f"  add S -> vSc | cSv: {len(L2)} songs up to 9 sections; grammar-built accepts "
      f"{sum(ok(G2, w, 'start') for w in L2)}, hand-built {sum(ok(HAND, w) for w in L2)}")
print(f"  ambiguous grammar on {DEEP}: {amb9} parse trees, closed form {choose(16, 8) // 9}")
print(f"  arch songs up to 15 sections: {len(listed(RULES, 15))}")
assert path[-1] == ("ε", "") and [st for _, st in path[:3]] == ["Zv", "Zvv", "Zvvc"] and len(path) == len(SONG) + 1
assert forms == ["S", "vSv", "vvSvv", "vvcScvv", SONG] and len(gpath) == 13 and trees == 1
assert not ok(HAND, BAD) and not ok(GRAM, BAD, "start") and bad_far == 4
assert agree == len(ALL) == 29524 and bylen == [2 ** k for k in range(5)] and most == 1
assert all(big[n] == (n + 1, (n ** 3 - n) // 6) for n in big) and big[101][1] == 171700
assert len(qa) == 31 and sum(arch(w) for w in qa) == 13 and not queue_ok(SONG)
assert miss3 == 16 and not ok(HAND, DEEP, cap=3) and ok(HAND, DEEP) and hold3 == 15
assert len(ga) == 31 and mirrors == 31 and not ok(HAND, "vccv")
assert amb7 == choose(12, 6) // 7 == 132 and amb9 == choose(16, 8) // 9 == 1430
assert len(L2) == 341 == sum(ok(G2, w, "start") for w in L2) and len(listed(RULES, 15)) == 255
print("ALL CHECKS PASS")
