# Rice's theorem and reductions -- the check behind the card.  Nothing is
# imported.  The tape machine is the one explained on the Turing-machines card;
# here a rule may also carry one side effect: delete a file.  The code never
# decides the undecidable.  It runs the reduction f, which turns a machine M and
# an input w into a macro, and checks on seven machines that the macro deletes a
# file exactly when M stops on w.  Road one runs M; road two runs the macro.
B, SYMS, CAP = "_", "_01", 1000

def table(text):                        # "A_:1RB" means: in A reading _, write 1, go R, enter B
    out = {}                            # a trailing "!" makes that rule delete a file
    for t in text.split():
        out[(t[0], t[1])] = (t[3], t[4], t[5:].rstrip("!"), t.endswith("!"))
    return out

def run(rules, start, w, cap):
    """Run until the machine stops (it enters the halt state H, or no row applies),
    a repeated configuration (a proof of looping), or the cap."""
    tape, head, state, deletes = dict(enumerate(w)), 0, start, []
    seen = {(state, head, tuple(sorted(tape.items())))}
    for step in range(1, cap + 1):
        if (state, tape.get(head, B)) not in rules:      # no row: stopped after step - 1 steps
            return "halts", step - 1, deletes, sum(v == "1" for v in tape.values())
        write, move, state, act = rules[(state, tape.get(head, B))]
        tape[head] = write
        head += 1 if move == "R" else -1
        if act:
            deletes.append(step)
        if state == "H":
            return "halts", step, deletes, sum(v == "1" for v in tape.values())
        config = (state, head, tuple(sorted((k, v) for k, v in tape.items() if v != B)))
        if config in seen:
            return "repeats", step, deletes, None
        seen.add(config)
    return "running", cap, deletes, None

def reduce_to_macro(m, w, disarm=True):
    """The reduction f: a macro that writes w, walks back, runs M with its own deletes
    switched off, and deletes one file only if M stops: enters H, or meets a missing row."""
    n, out = len(w), {}
    for i, ch in enumerate(w):          # writing phase: n steps
        for s in SYMS:
            out[(f"w{i}", s)] = (ch, "R", f"w{i + 1}" if i + 1 < n else "b0", False)
    for j in range(n):                  # walking back: n steps
        for s in SYMS:
            out[(f"b{j}", s)] = (s, "L", f"b{j + 1}" if j + 1 < n else "m.A", False)
    for (q, s), (wr, mv, nx, act) in m.items():
        out[("m." + q, s)] = (wr, mv, "DEL" if nx == "H" else "m." + nx, act and not disarm)
    for q in ({"A"} | {q for q, _ in m} | {r[2] for r in m.values()}) - {"H"}:
        for s in SYMS:                  # M has no row here, so it stops: delete, then stop
            out.setdefault(("m." + q, s), (s, "R", "H", True))
    for s in SYMS:                      # M has stopped: delete the file, then stop
        out[("DEL", s)] = (s, "R", "H", True)
    return out, ("w0" if n else "m.A")

MACHINES = [
    ("flip", "A0:1RA A1:0RA A_:_RH", "10"),
    ("bb2", "A_:1RB A1:1LB B_:1LA B1:1RH", ""),
    ("bb4", "A_:1RB A1:1LB B_:1LA B1:_LC C_:1RH C1:1LD D_:1RD D1:_RA", ""),
    ("pingpong", "A_:_RB A1:1RB B_:_LA B1:1LA", ""),
    ("rightward", "A_:_RA A0:0RA A1:1RA", ""),
    ("delete-loop", "A_:_RB! B_:_LC C_:_RB", ""),
    ("flip-norow", "A0:1RA A1:0RA", "10"),   # flip with no blank row: stops where no row applies
]

def say(v, k):                          # never "loops" without a repeated configuration
    if v == "halts":
        return f"halts at step {k}"
    if v == "repeats":
        return f"loops: configuration repeats at step {k}"
    return f"still running after {k} steps"

print(f"{'machine':<12} | {'input':<5} | {'road one: M on w':<40} | road two: the macro f(M, w)")
results, agree = {}, 0
for name, text, w in MACHINES:
    m = table(text)
    v1, k1, d1, ones = run(m, "A", w, CAP)
    macro, start = reduce_to_macro(m, w)
    v2, k2, d2, _ = run(macro, start, "", CAP + 2 * len(w) + 1)
    results[name] = (v1, k1, d1, ones, v2, k2, d2, macro, start)
    one = say(v1, k1) + (f", {ones} ones on the tape" if name.startswith("bb") and v1 == "halts" else "")
    two = f"deletes a file at step {d2[0]}, then halts" if d2 else say(v2, k2) + ", no delete"
    print(f"{name:<12} | {w or '-':<5} | {one:<40} | {two}")
    if v1 == "halts":                   # yes goes to yes, at the predicted step 2n + k + 1
        assert d2 == [2 * len(w) + k1 + 1] and v2 == "halts"
        agree += 1
    elif v1 == "repeats":               # a proved loop goes to a proved loop with no delete
        assert d2 == [] and v2 == "repeats" and k2 == 2 * len(w) + k1
        agree += 1
    else:                               # unknown stays unknown, and no delete within the cap
        assert d2 == [] and v2 == "running"
        agree += 1
print(f"machines checked: {len(MACHINES)}; macro deletes exactly when M stops: {agree} of {len(MACHINES)}")
n_flip = len(MACHINES[0][2])
print(f"flip on {MACHINES[0][2]}: write {n_flip} + walk back {n_flip} + run {results['flip'][1]} + delete 1"
      f" = step {2 * n_flip + results['flip'][1] + 1}")
assert results["bb2"][1] == 6 and results["bb2"][3] == 4        # the published 2-state record
assert results["bb4"][1] == 107 and results["bb4"][3] == 13     # Brady's 1983 4-state record
assert results["rightward"][0] == "running"

print("what breaks:")
bb4_macro, bb4_start = results["bb4"][7], results["bb4"][8]
v, k, d, _ = run(bb4_macro, bb4_start, "", 100)
print(f"  sandbox capped at 100 steps on f(bb4): {say(v, k)}, {len(d)} deletes seen;"
      f" uncapped, it deletes at step {results['bb4'][6][0]}")
assert v == "running" and d == [] and results["bb4"][6] == [108]
ping_macro = results["pingpong"][7]
says = any(r[3] for r in ping_macro.values())
print(f"  text scan of f(pingpong) for a delete rule: {'yes' if says else 'no'};"
      f" the run {say(results['pingpong'][4], results['pingpong'][5])}, no delete")
assert says and results["pingpong"][6] == []
evil = table(MACHINES[5][1])
naive, s0 = reduce_to_macro(evil, "", disarm=False)
v, k, d, _ = run(naive, s0, "", CAP)
print(f"  f without switching off M's deletes, on delete-loop: deletes at step {d[0]},"
      f" though M {say(results['delete-loop'][0], results['delete-loop'][1])}")
assert d == [1] and v == "repeats" and results["delete-loop"][6] == []
print("ALL CHECKS PASS")
