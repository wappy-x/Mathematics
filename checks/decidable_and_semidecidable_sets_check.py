# Decidable and semidecidable sets -- the check behind the card.  Nothing is imported.
# The programs are strings over seven symbols:  + - < > [ ] !  (! prints HELLO).
# Each program gets a number by length, then alphabet.  A lister runs them all by
# dovetailing: at stage s, program i takes its step t = s - i + 1, for i = 1 to s.
SYM = "+-<>[]!"
def well_formed(p):                     # brackets match: depth never below 0, ends at 0
    d = 0
    for c in p:
        d += (c == "[") - (c == "]")
        if d < 0: return False
    return d == 0
def all_programs(n):                    # by length, then alphabet in the order of SYM
    out, layer = [], [""]
    for _ in range(n):
        layer = [p + c for p in layer for c in SYM]
        out += [p for p in layer if well_formed(p)]
    return out
def count_by_depth(n):                  # second road: count strings by open-bracket depth
    ways, counts = {0: 1}, []
    for _ in range(n):
        new = {}
        for d, w in ways.items():
            for d2, k in ((d, 5), (d + 1, 1), (d - 1, 1)):
                if d2 >= 0: new[d2] = new.get(d2, 0) + w * k
        ways = new; counts.append(ways.get(0, 0))
    return counts
class Run:                              # one program, run one step at a time
    def __init__(self, p):
        self.p, self.pc, self.ptr, self.tape, self.steps, self.hello = p, 0, 0, {}, 0, None
        self.jump, stack = {}, []
        for i, c in enumerate(p):
            if c == "[": stack.append(i)
            elif c == "]": j = stack.pop(); self.jump[i], self.jump[j] = j, i
    def halted(self): return self.pc >= len(self.p)
    def config(self): return (self.pc, self.ptr, tuple(sorted((k, v) for k, v in self.tape.items() if v)))
    def step(self):                     # cells hold 0 to 255 and wrap round
        c, v = self.p[self.pc], self.tape.get(self.ptr, 0)
        self.steps += 1
        if c == "+": self.tape[self.ptr] = (v + 1) % 256
        elif c == "-": self.tape[self.ptr] = (v - 1) % 256
        elif c == ">": self.ptr += 1
        elif c == "<": self.ptr -= 1
        elif (c == "[" and v == 0) or (c == "]" and v != 0): self.pc = self.jump[self.pc]
        elif c == "!" and self.hello is None: self.hello = self.steps
        self.pc += 1
def run_alone(p, cap):                  # first road: one program on its own, up to cap steps
    r = Run(p)
    while not r.halted() and r.steps < cap: r.step()
    return r
def repeat_proof(p, cap):               # a repeated configuration proves the run never ends
    r, seen = Run(p), {}
    while not r.halted() and r.steps < cap:
        if r.config() in seen: return seen[r.config()], r.steps
        seen[r.config()] = r.steps; r.step()
    return None
def dovetail(progs, cap, stages):       # second road: the lister, one diagonal per stage
    runs, listed, cells = [], [], 0
    for s in range(1, stages + 1):
        if s <= len(progs): runs.append(Run(progs[s - 1]))
        for i, r in enumerate(runs, 1):
            cells += 1                  # grid cell (i, t = s - i + 1), visited or idle
            if r.halted() or r.steps >= cap: continue
            r.step()
            if r.hello == r.steps: listed.append((i, r.steps, s, cells))
    return listed
def W(i, t):                            # the cell's place in the diagonal walk
    s = i + t - 1
    return (s - 1) * s // 2 + i
CAP, N = 2000, 5
progs = all_programs(N)
num = {p: i for i, p in enumerate(progs, 1)}
by_len = [sum(1 for p in progs if len(p) == k) for k in range(1, N + 1)]
print("programs of length 1 to 5    " + " ".join(str(c) for c in by_len) + f", total {len(progs)}")
print("same counts by bracket depth " + " ".join(str(c) for c in count_by_depth(N)))
alone = [run_alone(p, CAP) for p in progs]
yes = {num[r.p]: r.hello for r in alone if r.hello}
silent = sum(1 for r in alone if r.halted() and not r.hello)
running = [r.p for r in alone if not r.halted() and not r.hello]
proved = sum(1 for p in running if repeat_proof(p, CAP))
print(f"run alone, {CAP} steps each:  {len(yes)} print HELLO, {silent} halt silent, {len(running)} still running")
print(f"of the {len(running)} still running: {proved} proved endless by a repeat, {len(running) - proved} unknown")
print("the unknown ones: " + " ".join(p for p in running if not repeat_proof(p, CAP)))
listed = dovetail(progs, CAP, len(progs) + CAP - 1)
print(f"the lister, {len(progs) + CAP - 1} stages: {len(listed)} programs listed")
print("first six listed (number, program, step, stage):")
for i, t, s, c in listed[:6]: print(f"  #{i} {progs[i - 1]}  step {t}  stage {s}")
for p in ("!", "+[]", "+[-]!", "-[-]!", "+[>+]"): print(f"program {p:6} is number {num[p]}")
i, t, s, c = next(x for x in listed if progs[x[0] - 1] == "-[-]!")
print(f"-[-]! prints at step {t}, listed at stage {s} = {i} + {t} - 1")
print(f"grid cells walked by then: counted {c:,}, by formula {W(i, t):,}")
s0 = sum(by_len[:4])
print(f"worked: {s0} shorter + {i - s0} = #{i}; steps 2 + 2 x {(t - 3) // 2} + 1 = {t}; "
      f"cells {s - 1} x {s} / 2 = {(s - 1) * s // 2:,}, plus {i}")
walk = [(k, st - k + 1) for st in range(1, 5) for k in range(1, st + 1)]
print("diagonal walk, cells 1 to 10: " + " ".join(f"({k},{u})={W(k, u)}" for k, u in walk))
last = max(s for i, t, s, c in listed)
print(f"last new listing at stage {last}; stages {last + 1} to {len(progs) + CAP - 1} add nothing")
a, b = repeat_proof("+[]", 50)
print(f"+[] repeats its configuration at steps {a} and {b}: proved never to print")
assert repeat_proof("+[>+]", CAP) is None
print(f"+[>+] after {CAP} steps: no repeat found, tape cells used {len(run_alone('+[>+]', CAP).tape)}")
# what breaks
late = sorted((t, progs[i - 1]) for i, t in yes.items() if t > 100)
print("printers a 100-step cap calls never: " + ", ".join(f"{p} (step {t})" for t, p in late))
stuck = num[running[0]]
print(f"one at a time: stuck on #{stuck} {running[0]}, lists {sum(1 for i in yes if i < stuck)} of {len(yes)}")
print(f"asked about +[>+], the lister is still silent after {len(progs) + CAP - 1} stages")
# the decidable cousin: prints HELLO within 100 steps; decided by two listers side by side
def two_listers(progs, cap):            # lister A: yes by step cap; lister B: settled no
    runs, answer = [], {}
    for s in range(1, len(progs) + cap):
        if s <= len(progs): runs.append(Run(progs[s - 1]))
        for i, r in enumerate(runs, 1):
            if i in answer: continue
            if r.halted() or r.steps >= cap: answer[i] = "no"; continue
            r.step()
            if r.hello: answer[i] = "yes"
    return answer
ans = two_listers(progs, 100)
direct = {i: "yes" if (r.hello or 0) and r.hello <= 100 else "no" for i, r in enumerate(alone, 1)}
print(f"within 100 steps: {sum(1 for v in ans.values() if v == 'yes')} yes, "
      f"{sum(1 for v in ans.values() if v == 'no')} no, every one answered, agreeing with a direct run")
# the reduction: P halts exactly when P' = (P with ! deleted) + ! prints HELLO
short = [p for p in progs if len(p) <= 4]
pairs = [(run_alone(p, CAP), run_alone(p.replace("!", "") + "!", CAP + 1)) for p in short]
print(f"reduction on {len(short)} programs up to length 4: {sum(1 for r, q in pairs if r.halted())} halt, "
      f"{sum(1 for r, q in pairs if q.hello)} of their P' print HELLO")
for p in ("+[]", "+[-]"):
    q = run_alone(p + "!", CAP)
    print(f"  {p:5} -> {p + '!':6} " + (f"prints at step {q.hello}" if q.hello else "repeat at steps %d and %d" % repeat_proof(p + "!", CAP)))
assert by_len == count_by_depth(N) and len(progs) == 5373
assert sorted((i, t) for i, t, s, c in listed) == sorted(yes.items())
assert num["+[>+]"] not in {i for i, t, s, c in listed}     # the lister stays silent on +[>+]
assert all(c == W(i, t) for i, t, s, c in listed)
assert all(ans[i] == direct[i] for i in direct) and len(ans) == len(progs)
assert all(r.halted() == (q.hello is not None) for r, q in pairs)
assert [p for t, p in late] == ["+[+]!", "-[-]!"] and len(yes) - len(late) == sum(1 for v in ans.values() if v == "yes")
print("ALL CHECKS PASS")
