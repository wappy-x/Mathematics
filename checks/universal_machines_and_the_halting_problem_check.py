# Universal machines and the halting problem -- the check behind the card.
# Nothing is imported.  U is an interpreter, written out here, for a small slice
# of Python: whole-number variables, + - * // %, while and if.  It runs any
# program in that slice from its text alone.  No eval, exec or ast.  Then the
# diagonal program D is built and run against four would-be halting deciders.
OPS = {"+": lambda a, b: a + b, "-": lambda a, b: a - b, "*": lambda a, b: a * b,
       "//": lambda a, b: a // b, "%": lambda a, b: a % b}
TESTS = {"==": lambda a, b: a == b, "!=": lambda a, b: a != b, "<": lambda a, b: a < b}

def compile_text(text):           # program text -> numbered instructions with jumps
    code, open_blocks = [], []
    for line in [l for l in text.split("\n") if l.strip()] + [""]:
        depth = len(line) - len(line.lstrip())
        while open_blocks and (open_blocks[-1][0] >= depth or not line):
            head = open_blocks.pop()[1]
            if code[head][0] == "while":
                code.append(["goto", head])            # the loop jumps back to its test
            code[head][4] = len(code)                  # a failed test jumps past the block
        if not line:
            return code
        w = line.replace("(", " ").replace(")", " ").replace(",", " ").replace(":", " ").split()
        if w[0] in ("while", "if"):
            open_blocks.append((depth, len(code)))
            code.append([w[0], w[1], w[2], w[3], None])
        elif w[2] == "halts":
            code.append(["halts", w[0], w[3], w[4]])   # ask the plugged-in decider
        else:
            code.append(["set", w[0], w[2], "+", "0"] if len(w) == 3 else ["set"] + w[:1] + w[2:5])

def run(code, n, fuel, decider=None, wrap=None):
    # U: returns ("halts" | "loops" | "fuel", steps, variables).  "loops" only with proof:
    # the same line and the same variables came round twice, so it repeats forever.
    env, pc, steps, seen = {"n": n}, 0, 0, set()
    val = lambda a: int(a) if a.isdigit() else env.get(a, 0)
    while pc < len(code):
        config = (pc, tuple(sorted(env.items())))
        if config in seen:
            return "loops", steps, env
        seen.add(config)
        if steps >= fuel:
            return "fuel", steps, env
        ins, steps, pc = code[pc], steps + 1, pc + 1
        if ins[0] == "set":
            env[ins[1]] = OPS[ins[3]](val(ins[2]), val(ins[4]))
            if wrap:
                env[ins[1]] %= wrap
        elif ins[0] == "goto":
            pc = ins[1]
        elif ins[0] == "halts":
            answer, cost = decider(val(ins[2]), val(ins[3]), fuel - steps)
            if answer is None:
                return "fuel", fuel, env
            env[ins[1]], steps = answer, steps + cost
        elif not TESTS[ins[2]](val(ins[1]), val(ins[3])):
            pc = ins[4]
    return "halts", steps, env

NAMES = ["countdown", "collatz", "even-stop", "count-up", "below-3", "D"]
TEXTS = ["while n != 0:\n    n = n - 1",
         "steps = 0\nwhile n != 1:\n    r = n % 2\n    if r == 0:\n        n = n // 2\n"
         "    if r == 1:\n        n = 3 * n\n        n = n + 1\n    steps = steps + 1",
         "r = n % 2\nwhile r == 1:\n    r = 1",
         "while n != 0:\n    n = n + 1",
         "while 2 < n:\n    n = n",
         "r = halts(n, n)\nwhile r == 1:\n    r = 1"]       # D, program number 5
CODE = [compile_text(t) for t in TEXTS]
FUEL = 10000
show = lambda o: {"halts": "halts", "loops": "loops", "fuel": "running"}[o[0]] + f" {o[1]}"

print("U compiles countdown to", " | ".join(f"{k}: " + " ".join(str(p) for p in ins)
                                           for k, ins in enumerate(CODE[0])))
for k in (0, 2, 40):
    print(f"U runs countdown on {k}: {show(run(CODE[0], k, FUEL))} steps")
    assert run(CODE[0], k, FUEL)[:2] == ("halts", 3 * k + 1)  # one test, one subtract, one jump back
m, moves = 27, 0                                          # Collatz as a direct loop, a second road
while m != 1:
    m, moves = (m // 2 if m % 2 == 0 else 3 * m + 1), moves + 1
c27 = run(CODE[1], 27, FUEL)
print(f"U runs collatz on 27: {show(c27)} steps, {c27[2]['steps']} moves; a direct loop counts {moves}")
assert c27[0] == "halts" and c27[2]["steps"] == moves

# Left running: the card proves these never stop.  Collatz on 0 halves 0 to 0 for
# ever, while its move counter climbs; count-up from 1 or more only grows.
RUNNING = {(1, 0), (3, 1), (3, 2), (3, 3), (3, 4)}
TRUTH = []
print("program   " + "".join(f"{'input ' + str(x):>14}" for x in range(5)))
for i in range(5):                                       # the program-against-input table
    row = [run(CODE[i], x, FUEL) for x in range(5)]
    assert all((o[0] == "fuel") == ((i, x) in RUNNING) for x, o in enumerate(row))
    TRUTH.append([1 if o[0] == "halts" else 0 for o in row])
    print(f"{NAMES[i]:10}" + "".join(f"{show(o):>14}" for o in row))
diag = [TRUTH[i][i] for i in range(5)]
flip = [1 - b for b in diag]
print("diagonal, 1 = halts:", diag, " flipped:", flip)

def table_decider(default):        # right on all 25 table entries, guesses elsewhere
    return lambda a, b, budget: ((TRUTH[a][b] if a < 5 and b < 5 else default), 0)

def cap_decider(cap):              # says 1 if the run halts within cap steps
    def h(a, b, budget):
        out, used, _ = run(CODE[a], b, min(cap, budget), h)
        if out == "fuel" and budget < cap:
            return None, 0                               # the caller ran out of fuel first
        return (1 if out == "halts" else 0), used
    return h

d_row = [1 if run(CODE[5], x, FUEL, table_decider(1))[0] == "halts" else 0 for x in range(5)]
print("D on inputs 0 to 4, 1 = halts:", d_row)
assert d_row == flip and all(d_row[i] != TRUTH[i][i] for i in range(5))
for label, h in [("table, guess 1", table_decider(1)), ("table, guess 0", table_decider(0)),
                 ("cap 100", cap_decider(100)), ("cap 300", cap_decider(300))]:
    said = h(5, 5, FUEL)[0]
    did = run(CODE[5], 5, FUEL, h)
    print(f"H = {label}: says H(5, 5) = {said}; D on 5 {show(did)} steps")
    assert did[0] != "fuel"                              # D's run ended, or provably repeats
    assert said != (1 if did[0] == "halts" else 0)       # every decider is wrong on D
    assert not label.startswith("cap") or did[:2] == ("halts", int(label[4:]) + 2)  # N + 2

copier = compile_text("r = halts(n, n)\nwhile r == 0:\n    r = 0")
print(f"copier, no flip, H = table, guess 1: says 1; copier on 5 {show(run(copier, 5, FUEL, table_decider(1)))} steps")
assert run(copier, 5, FUEL, table_decider(1))[0] == "halts"   # no contradiction without the flip
print(f"cap 100 on countdown 40: {show(run(CODE[0], 40, 100))} steps; uncapped: {show(run(CODE[0], 40, FUEL))} steps")
up8 = run(CODE[3], 1, FUEL, wrap=256)
print(f"count-up on 1 with numbers kept 0 to 255: {show(up8)} steps")
assert up8[:2] == ("halts", 3 * 255 + 1)
print("ALL CHECKS PASS")
