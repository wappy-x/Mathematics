# Kleene's recursion theorem -- the check behind the card.  Standard library
# only, and nothing is imported.  No eval or exec: the Python quine is checked
# by Python's own % formatting and by a hand-written repr and fill.  The toy
# language is a stack of texts, run by the interpreter below:
#   L<n>:<text> push the n characters   D duplicate the top   W swap the top two
#   Q quote: w becomes L<len w>:w       C join: a, b become a+b   N w becomes len(w)
#   E run the top text as a fresh program   H ask a decider about the top text:
#     "halts" -> loop for ever, "never halts" -> carry on    G the same, unflipped
# A run says "loops" only on a repeated configuration (text, place, stack).

def quote(w):                            # the program that pushes w and stops
    return "L" + str(len(w)) + ":" + w

def run(prog, budget, decide):
    pc, st, steps, seen = 0, [], 0, set()
    while True:
        if pc == len(prog):
            return "halts", steps, (st[-1] if st else "")
        key = (prog, pc, tuple(st))
        if key in seen:
            return "loops", steps, ""
        seen.add(key)
        if steps >= budget:
            return "running", steps, ""
        steps += 1
        if pc < 0:                       # spinning: nothing ever changes
            continue
        c, pc = prog[pc], pc + 1
        if c == "L":
            j = pc
            while j < len(prog) and prog[j] in "0123456789":
                j += 1
            if j == pc or j >= len(prog) or prog[j] != ":" or j + 1 + int(prog[pc:j]) > len(prog):
                return "crash", steps, ""
            n = int(prog[pc:j])
            st.append(prog[j + 1:j + 1 + n])
            pc = j + 1 + n
        elif c in "DQNEHG" and len(st) >= 1 or c in "WC" and len(st) >= 2:
            w = st.pop()
            if c == "D": st += [w, w]
            elif c == "Q": st.append(quote(w))
            elif c == "N": st.append(str(len(w)))
            elif c == "W": st[-1:] = [w, st[-1]]
            elif c == "C": st[-1] += w
            elif c == "E": prog, pc, st = w, 0, []
            else:
                yes, used = decide(w, budget - steps)
                steps += used
                if steps >= budget:
                    return "running", steps, ""
                if yes == (c == "H"):
                    pc = -1
        else:
            return "crash", steps, ""

def cap(n):                              # "halts if a run of n steps sees it halt"
    def d(w, left):
        status, used, _ = run(w, min(n, left), d)
        return status == "halts", used
    return d

always_yes = lambda w, left: (True, 0)
always_no = lambda w, left: (False, 0)
B = "DQWC"                               # rebuilds the whole program from its literal
def self_prog(task):                     # the recursion theorem's construction
    return quote(B + task) + B + task
def show(r):
    n = f"{r[1]} step" + ("" if r[1] == 1 else "s")
    return f"halts after {n}, output {r[2] or '(empty)'}" if r[0] == "halts" else f"{r[0]} after {n}"
def yn(claim):
    return "yes" if claim else "no"

def myrepr(w):                           # Python's repr of a plain string, written out
    return "'" + w.replace("\\", "\\\\").replace("'", "\\'") + "'"
def fill(t, args):                       # Python's % formatting, written out
    out, i, slots = "", 0, 0
    while i < len(t):
        if t[i] != "%":
            out, i = out + t[i], i + 1
            continue
        code, i = t[i + 1], i + 2
        if code == "%":
            out += "%"
            continue
        if slots < len(args):
            out += myrepr(args[slots]) if code == "r" else args[slots]
        slots += 1
    return (out if slots == len(args) else None), slots

src = "s='s=%r;print(s%%s)';print(s%s)"
s = "s=%r;print(s%%s)"
print(f"python line: {src}  ({len(src)} characters)")
print(f"s quoted by repr: {myrepr(s)}")
road1, road2 = s % s, fill(s, [s])[0]           # road 1 is Python's own %, asserted below
print(f"its output, by a hand-written repr and fill: equals the line: {yn(road2 == src)}")
quine = self_prog("")
rq = run(quine, 10000, always_no)
print(f"toy quine {quine} ({len(quine)} characters): {show(rq)}; equals itself: {yn(rq[2] == quine)}")
words = [""]
for _ in range(4):
    words += [w + c for w in words if len(w) == len(words[-1]) for c in "DQWC"]
found = [p for p in (quote(a) + b for a in words for b in words) if run(p, 50, always_no)[2] == p]
print(f"search: {len(words) ** 2} programs (one literal of up to 4 of DQWC, then up to 4 of DQWC): quines {found}")
own = self_prog("N")
ro = run(own, 10000, always_no)
print(f"self-length {own} ({len(own)} characters): {show(ro)}")
fixed = [("quote it", "QE", quote), ("print its length", "NQE", lambda w: quote(str(len(w)))),
         ("run it, then add !", "L5:L1:!CCE", lambda w: w + "L1:!C")]
for name, task, f in fixed:
    e = self_prog(task)
    a, b = run(e, 10000, always_no), run(f(e), 10000, always_no)
    print(f"fixed point of '{name}': e = {e} ({len(e)} characters)")
    print(f"  e: {show(a)}; f(e) = {f(e)}: {show(b)}")
    assert (a[0], a[2]) == (b[0], b[2])                  # e behaves like f(e)
con = self_prog("H")
print(f"contrary program C = {con}: get my own code, ask the decider, do the opposite")
for name, d, want in [("always halts", always_yes, 6 + 1), ("always never halts", always_no, 6),
                      ("halts within 100 steps", cap(100), 6 + 100), ("halts within 300 steps", cap(300), 6 + 300)]:
    says, _ = d(con, 10000)
    r = run(con, 10000, d)
    print(f"decider '{name}': says {'halts' if says else 'never halts'}; C {show(r)}")
    assert says != (r[0] == "halts")                     # every decider is wrong about C
    assert r[1] == want                                  # C's own 6 steps, plus 1 spin or the cap spent
nq = "L2:DCDC"
print(f"mistake 1, copy without quoting: {nq} outputs {run(nq, 100, always_no)[2]}")
bad = "s=%r;print(s%s)"
try:
    bad % bad; ok = True
except TypeError:
    ok = False
print(f"mistake 2, % for %%: {fill(bad, [bad])[1]} slots, 1 value; runs: {yn(ok)}")
agree = self_prog("G")
ra = run(agree, 10000, always_yes)
print(f"mistake 3, no flip: {agree} with 'always halts': {show(ra)}; decider right: {yn(ra[0] == 'halts')}")
assert road1 == src and road2 == src and not ok          # two roads to the quine
assert rq[2] == quine and found == [quine]                # construction against search
assert ro[2] == str(len(own)) and run(nq, 100, always_no)[2] != nq
print("ALL CHECKS PASS")
