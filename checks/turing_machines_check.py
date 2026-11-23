# Turing machines -- the check behind the card.  Standard library only.
# The tape machine below is the shelf's simulator kit; later cards copy it.
# A rule table is plain text, one row per line: state read write move next.
B = "_"  # the blank symbol; the card writes it as an open box

def table(text):
    return {(s, r): (w, m, n) for s, r, w, m, n in (l.split() for l in text.strip().splitlines())}
def show(tape, head):
    lo, hi = min(min(tape), head), max(max(tape), head)
    return "".join(f"[{tape.get(i, B)}]" if i == head else tape.get(i, B) for i in range(lo, hi + 1))

def run(rules, word, state, cap=100000, trace=None):
    # Halts when the table has no row for (state, symbol under the head).
    tape, head, steps = {i: c for i, c in enumerate(word)}, 0, 0
    while (state, tape.get(head, B)) in rules:
        if steps == cap: return None, state, steps
        read = tape.get(head, B)
        write, move, nxt = rules[(state, read)]
        tape[head] = write
        head += 1 if move == "R" else -1
        steps += 1
        if trace is not None:
            trace.append(f"{steps:>4}  {state:<6} {read}  {write} {move}  {nxt:<6} {show(tape, head)}")
        state = nxt
    return "".join(tape[i] for i in sorted(tape)).strip(B), state, steps

ADD_ONE = table("""
right 0 0 R right
right 1 1 R right
right _ _ L carry
carry 1 0 L carry
carry 0 1 L done
carry _ 1 L done""")

def value(s):  # road 2: binary place value, by hand
    v = 0
    for c in s: v = 2 * v + (c == "1")
    return v

def binary(v, width):
    s = ""
    while v > 0: s, v = str(v % 2) + s, v // 2
    return s.rjust(width, "0")
def trailing_ones(s):
    return len(s) - len(s.rstrip("1"))

# ---- the odometer: 10111 is 23 miles; one more mile ----
trace = []
out, state, steps = run(ADD_ONE, "10111", "right", trace=trace)
print(f"add one to 10111 = {value('10111')}; step  state  read  write move  next  tape after, head in [ ]")
print("\n".join(trace))
print(f"result {out} = {value(out)}, halted in {state} after {steps} steps")
assert out == binary(value("10111") + 1, 5) == "11000"
assert state == "done" and [l.split()[-1] for l in trace] == "1[0]111 10[1]11 101[1]1 1011[1] 10111[_] 1011[1]_ 101[1]0_ 10[1]00_ 1[0]000_ [1]1000_".split()
n, t = 5, trailing_ones("10111")
print(f"steps = n + t + 2 = {n} + {t} + 2 = {n + t + 2}")
assert steps == n + t + 2

# ---- every odometer reading of 1 to 10 digits: machine against arithmetic ----
count = good_value = good_steps = 0
for width in range(1, 11):
    for v in range(2 ** width):
        s = binary(v, width)
        o, q, k = run(ADD_ONE, s, "right")
        count += 1
        good_value += (q == "done" and value(o) == v + 1 and len(o) == max(width, len(binary(v + 1, 1))))
        good_steps += (k == width + trailing_ones(s) + 2)
print(f"readings checked {count}; value + 1 agrees {good_value}; steps = n + t + 2 {good_steps}")
assert count == good_value == good_steps == 2046
print("worst case, all ones: " + "  ".join(f"n={w}:{run(ADD_ONE, '1' * w, 'right')[2]}" for w in (5, 10, 20)))

# ---- what breaks ----
no_blank = dict(ADD_ONE); del no_blank[("carry", B)]
o, q, k = run(no_blank, "11111", "right")
print(f"wrong: no (carry, _) row, 11111 -> {o} = {value(o)}, halted in {q}")
assert value(o) != value("11111") + 1
moves_r = dict(ADD_ONE); moves_r[("carry", "1")] = ("0", "R", "carry")
o = run(moves_r, "10111", "right")[0]
print(f"wrong: carry moves R, 10111 -> {o} = {value(o)}")
o = run(ADD_ONE, "10111", "carry")[0]
print(f"wrong: carry starts at the left end, 10111 -> {o} = {value(o)}")
capped = run(ADD_ONE, "11111", "right", cap=11)
print(f"wrong: cap of 11 steps on 11111 -> still running after {capped[2]} steps (it halts at step 12)")
assert capped[0] is None and run(ADD_ONE, "11111", "right")[2] == 12

# ---- the bracket checker: cross off each ) with the nearest open ( to its left ----
BRACKETS = table("""
seek ( ( R seek
seek X X R seek
seek ) X L back
seek _ _ L check
back X X L back
back ( X R seek
back _ _ R reject
check X X L check
check ( ( R reject
check _ _ R accept""")

# The stack machine, copied from the Grammars and a stack card (path, cap and progress tracking cut); it returns
# its accepting run's move count, or None.  A move is (state, read, pop, push, next); '' means read or pop nothing.
def stack_machine(moves, w, start="up"):
    todo, seen = [(start, 0, "Z", 0)], set()  # Z marks the stack's bottom; the last number counts moves
    while todo:
        q, i, st, k = todo.pop()
        if q == "yes" and i == len(w): return k
        if (q, i, st) in seen: continue
        seen.add((q, i, st))
        for p, a, x, y, r in reversed(moves):
            if p != q or (a and w[i:i + 1] != a) or not st.endswith(x): continue
            s2, i2 = st[:len(st) - len(x)] + y[::-1], i + len(a)
            if len(s2) - 1 > len(w) - i2: continue
            todo.append((r, i2, s2, k + 1))
    return None
NEST = [("up", "(", "", "(", "up"), ("up", ")", "(", "", "up"), ("up", "", "Z", "", "yes")]
for w in ("(()())", "(()", "())("):
    o, q, k = run(BRACKETS, w, "seek")
    print(f"brackets {w:<7} -> {q} after {k} steps, tape {o}")
agree, balanced, worst = 0, [0] * 13, [(0, "")] * 13
for length in range(13):
    for code in range(2 ** length):
        w = "".join("()"[(code >> i) & 1] for i in range(length))
        o, q, k = run(BRACKETS, w, "seek")
        agree += ((q == "accept") == (stack_machine(NEST, w) is not None))
        balanced[length] += (q == "accept")
        if k > worst[length][0]: worst[length] = (k, w)  # the first string with the most steps
print(f"bracket strings of length 0 to 12: {2 ** 13 - 1}; tape machine agrees with stack machine on {agree}")
assert agree == 2 ** 13 - 1
catalan = [1]
for k in range(1, 7): catalan.append(catalan[-1] * 2 * (2 * k - 1) // (k + 1))
print("balanced strings of length 0,2,..,12:", " ".join(str(balanced[2 * k]) for k in range(7)), "| Catalan:", " ".join(map(str, catalan)))
assert [balanced[2 * k] for k in range(7)] == catalan
sm = {m: stack_machine(NEST, worst[m][1]) for m in (4, 8, 12)}  # stack moves on the same worst strings
print("worst-case steps, tape machine against stack machine: " + "  ".join(f"n={m}:{worst[m][0]}/{sm[m]}" for m in sm))
assert all(sm[m] == m + 1 for m in sm)  # one move per bracket, then one to pop the bottom marker

# ---- try changing ----
for w in ("11111", "0", "0111"):
    o, q, k = run(ADD_ONE, w, "right")
    print(f"try: {w} -> {o} = {value(o)} in {k} steps")
print("ALL CHECKS PASS")
