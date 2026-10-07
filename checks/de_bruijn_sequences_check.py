# De Bruijn sequences -- the check behind the card.  Nothing is imported.  Main case: n = 2 digits,
# codes of length k = 3.  Three roads: an Euler circuit, brute force over every string, the formula.
def codes(n, k):                                   # every k-digit code, in order
    out = [""]
    for _ in range(k): out = [s + str(d) for s in out for d in range(n)]
    return out
def leaving(n, k):                                 # window -> codes leaving it, smallest first
    out = {}
    for c in codes(n, k): out.setdefault(c[:-1], []).append(c)
    return out
def wrapped(s, k):                                 # the k-digit codes read round the cycle
    r = s + s[:k - 1]
    return [r[i:i + k] for i in range(len(s))]
def circuit(n, k):                                 # road 1: Hierholzer, smallest edge first
    out, stack, path = leaving(n, k), ["0" * (k - 1)], []
    while stack:
        v = stack[-1]
        if out.get(v): stack.append(out[v].pop(0)[1:])        # walk on, using up an edge
        else: path.append(stack.pop())                        # stuck: park this window
    path.reverse()                                            # windows in circuit order
    trail = [path[i] + path[i + 1][-1] for i in range(len(path) - 1)]
    return trail, path[0] + "".join(v[-1] for v in path[1:])
def brute(n, k):                                   # road 2: try every string of length n^k
    every = ("".join(str(m // n ** i % n) for i in range(n ** k)) for m in range(n ** (n ** k)))
    return [s for s in every if len(set(wrapped(s, k))) == n ** k]
def by_formula(n, k):                              # road 3: (n!)^(n^(k-1)) / n^k
    f = 1
    for i in range(2, n + 1): f *= i
    return f ** (n ** (k - 1)) // n ** k
def greedy(n, k):                                  # a walk that never goes back to re-splice
    out, v, walk = leaving(n, k), "0" * (k - 1), []
    while out.get(v): e = out[v].pop(0); walk.append(e); v = e[1:]
    return walk
def yn(c): return "yes" if c else "no"
trail, typed = circuit(2, 3); seq = typed[:8]; good = brute(2, 3); rounds = wrapped(seq, 3)
ins = [sum(c[1:] == v for c in codes(2, 3)) for v in codes(2, 2)]     # tallied off the edge list
outs = [sum(c[:-1] == v for c in codes(2, 3)) for v in codes(2, 2)]
cycles = sorted({min(s[i:] + s[:i] for i in range(8)) for s in good}); ncyc = len(good) // len(seq)
flat = [seq[i:i + 3] for i in range(6)]; miss = sorted(set(codes(2, 3)) - set(flat))
extra = [(n, k, len(brute(n, k)) // n ** k, by_formula(n, k)) for n, k in ((2, 4), (3, 2))]
walk, (_, pin_typed) = greedy(2, 3), circuit(10, 4); pin = pin_typed[:10 ** 4]
nv, ne, pins = len(codes(2, 2)), len(codes(2, 3)), set(wrapped(pin, 4)); L, ng = len(seq), len(good)
naive, npin = 3 * ne, len(pins)
print(f"n = 2, k = 3: {nv} windows as vertices, {ne} codes as edges, in- and out-degree {min(ins + outs)} to {max(ins + outs)}")
print(f"Euler circuit, edge by edge: {' '.join(trail)}")
print(f"start window plus a digit per edge: {typed}, {len(typed)} presses; cycle = first {len(seq)} digits: {seq}")
print(f"codes round the cycle = those edges in order: {yn(rounds == trail)}; all {len(set(rounds))} distinct, against {naive} digits listed one by one")
print(f"brute force over all {2 ** 8} strings of length {L}: {ng} work, {ng} / {L} rotations = {ncyc} cycles: {' '.join(cycles)}")
print(f"the count by formula (n!)^(n^(k-1)) / n^k: {by_formula(2, 3)}, agrees with brute force: {yn(by_formula(2, 3) == ncyc)}")
for n, k, b, f in extra: print(f"n = {n}, k = {k}: brute force {b} cycles, formula {f}, agree: {yn(b == f)}")
print(f"mistake, cycle typed with no wrap: {len(set(flat))} codes of {ne}, missing {' '.join(miss)}")
print(f"mistake, greedy walk with no re-splice: stops after {len(walk)} codes: {' '.join(walk)}")
print(f"keypad lock, n = 10, k = 4: {10 ** 3} windows as vertices, {10 ** 4} codes as edges")
print(f"its circuit: {len(pin_typed)} presses, cycle {len(pin)} digits starting {pin[:12]}, all {npin} PINs once: {yn(npin == 10 ** 4)}")
print(f"against {4 * 10 ** 4} presses for every PIN separately: {4 * 10 ** 4 - len(pin_typed)} saved")
assert seq == "00010111" and rounds == trail and len(set(rounds)) == 8
assert cycles == ["00010111", "00011101"] and len(good) == 16 and min(ins + outs) == max(ins + outs) == 2
assert by_formula(2, 3) == ncyc and all(b == f for _, _, b, f in extra)
assert len(pin_typed) == 10 ** 4 + 3 and npin == 10 ** 4 and len(walk) == 4 and len(set(flat)) == 6
print("ALL CHECKS PASS")
