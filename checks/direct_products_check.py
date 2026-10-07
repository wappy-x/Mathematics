# Direct products -- the check behind the card.  Nothing is imported.  A padlock
# with one 3-position dial and one 5-position dial: its group is the ordered
# pairs, each dial wrapping on its own.  Two roads: pairs are built and walked,
# and every return time is re-derived from a least common multiple.
M, N = 3, 5
def gcd(a, b):                           # Euclid, used only by the formula road
    while b: a, b = b, a % b
    return a
def lcm(a, b): return a * b // gcd(a, b)
def dial(a, m): return m // gcd(a, m)    # one dial's own return time
def add(p, q, m, n):                     # the componentwise rule
    return ((p[0] + q[0]) % m, (p[1] + q[1]) % n)
def order(p, m, n):                      # road one: repeat the pair until home
    x, k = p, 1
    while x != (0, 0):
        x, k = add(x, p, m, n), k + 1
    return k
def walk(p, m, n):                       # every setting that pair reaches
    out, x = [], (0, 0)
    while x not in out:
        out.append(x)
        x = add(x, p, m, n)
    return out
def restore(a, b): return (10 * a + 6 * b) % (M * N)    # a pair back to a reading
def show(ps): return " ".join(f"({a},{b})" for a, b in ps)
def nums(vs): return " ".join(str(v) for v in vs)
pairs = [(a, b) for a in range(M) for b in range(N)]    # every setting: 3 by 5
reads = [(k % M, k % N) for k in range(M * N)]          # reading k to its pair
cycle = walk((1, 1), M, N)
walked = [order(p, M, N) for p in reads]
formula = [lcm(dial(a, M), dial(b, N)) for a, b in reads]
sums = all(restore(*add(p, q, M, N)) == (restore(*p) + restore(*q)) % (M * N)
           for p in pairs for q in pairs)
sw = [(a, b) for a in range(2) for b in range(2)]
sw_ord, d4 = [order(p, 2, 2) for p in sw], [order((a, 0), 4, 1) for a in range(4)]
big = [order((a, b), 6, 4) for a in range(6) for b in range(4)]
print(f"padlock: {M} positions x {N} positions = {M * N} settings; pairs {len(pairs)}")
print(f"joint cycle from (1,1): {show(cycle)}")
print(f"the grid, rows the {M}-dial, columns the {N}-dial, entries the reading:")
for a in range(M):
    print(f"  row {a}" + "".join(f"{restore(a, b):>5}" for b in range(N)))
print(f"order of (1,1): walked {order((1, 1), M, N)}, lcm({M},{N}) = {lcm(M, N)}; "
      f"settings reached {len(cycle)}")
print(f"orders by reading 0 to {M * N - 1}: {nums(walked)}")
print(f"reading 14 is the pair ({14 % M},{14 % N}); the reverse "
      f"(10 x {14 % M} + 6 x {14 % N}) mod {M * N} gives {restore(14 % M, 14 % N)}")
print(f"all {len(pairs) ** 2} pair sums match the {M * N}-clock: {str(sums).lower()}")
print(f"two switches {show(sw)}: orders {nums(sw_ord)}, largest {max(sw_ord)}")
print(f"one 4-dial, readings 0 1 2 3: orders {nums(d4)}, largest {max(d4)}")
print(f"6 positions x 4 positions: {6 * 4} settings, largest order {max(big)}, "
      f"lcm(6,4) = {lcm(6, 4)}, gcd(6,4) = {gcd(6, 4)}")
print(f"mistakes: adding the dials gives {M + N} settings, not {M * N}; "
      f"multiplying the switch return times gives 4, not {order((1, 1), 2, 2)}")
print(f"the switches' joint step reaches only {show(walk((1, 1), 2, 2))}; "
      f"gcd(2,2) = {gcd(2, 2)} while gcd({M},{N}) = {gcd(M, N)}")
assert walked == formula and walked[1] == M * N and len(cycle) == M * N
assert walked == [M * N // gcd(k, M * N) for k in range(M * N)]
assert sums and sorted(reads) == pairs and all(restore(k % M, k % N) == k for k in range(M * N))
assert sw_ord == [1, 2, 2, 2] and d4 == [1, 4, 2, 4] and max(big) == lcm(6, 4)
print("ALL CHECKS PASS")
