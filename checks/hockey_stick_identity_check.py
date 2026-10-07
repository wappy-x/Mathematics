# The hockey stick -- the check behind the card.  Nothing is imported.  Tins are
# stacked in a triangular pile five layers deep: 1, 3, 6, 10, 15 tins, 35 in all.
# The 35 is reached by four roads sharing no arithmetic: Pascal's triangle built
# by addition alone, the factorial formula, laying the tins out one position at a
# time, and listing every 3-tin pick from 7 labelled tins.
TOP, K, N = 10, 2, 6                       # triangle depth; the stick's column, its last row
def triangle(top):                         # road one: each entry from the two above it
    rows = [[1]]
    for n in range(1, top + 1):
        rows.append([1] + [rows[-1][j - 1] + rows[-1][j] for j in range(1, n)] + [1])
    return rows
def choose(n, k):                          # road two: n! / (k! (n-k)!), zero off the row
    if k < 0 or k > n: return 0
    f = [1]                                # the factorials 0!, 1!, ..., n!, written out here
    for i in range(1, n + 1): f.append(f[-1] * i)
    return f[n] // (f[k] * f[n - k])
def layer(m):                              # road three: a triangle of tins, m rows deep
    return [(r, c) for r in range(1, m + 1) for c in range(1, r + 1)]
def listed(items, size):                   # road four: every pick of that size, listed
    if size == 0: return [[]]
    return [[x] + rest for j, x in enumerate(items)
            for rest in listed(items[j + 1:], size - 1)]
def stick(k, n, rows):                     # the diagonal C(k,k), C(k+1,k), ..., C(n,k)
    return [rows[i][k] for i in range(k, n + 1)]
def totals(xs):                            # running totals, one entry at a time
    out = []
    for x in xs: out.append(x + (out[-1] if out else 0))
    return out

rows = triangle(TOP)
bar = stick(K, N, rows)
running = totals(bar)
next_column = [choose(i + 1, K + 1) for i in range(K, N + 1)]
layers = [len(layer(m)) for m in range(1, N - K + 2)]
total = running[-1]
picks = listed(list(range(1, N + 2)), K + 1)
by_largest = [len([p for p in picks if p[-1] == i + 1]) for i in range(K, N + 1)]
flat = totals(stick(1, N, rows))[-1]
deep = totals(stick(3, 7, rows))[-1]
print(f"a {N - K + 1}-layer pile of tins, layer by layer: {' + '.join(str(x) for x in bar)} = {total} tins")
print(f"the same layers by laying tins out one position at a time: {layers}")
print(f"the stick at k = {K}, its running total, and the next column one row down:")
for j, i in enumerate(range(K, N + 1)):
    print(f"  row {i}: C({i},{K}) = {bar[j]:<3} running total {running[j]:<3} "
          f"C({i + 1},{K + 1}) = {next_column[j]}")
print(f"the blade C({N + 1},{K + 1}) read straight off row {N + 1}: {rows[N + 1][K + 1]}")
print(f"picks of {K + 1} from {N + 1} labelled tins, listed one by one: {len(picks)}")
print(f"those picks split by their largest label: {by_largest}")
print(f"the stick at k = 1, rows 1 to {N}: 1 + 2 + 3 + 4 + 5 + 6 = {flat} = C(7,2) = {choose(7, 2)}")
print(f"the stick at k = 3, rows 3 to 7: 1 + 4 + 10 + 20 + 35 = {deep} = C(8,4) = {choose(8, 4)}")
print(f"mistake 1, stick started one row late: {total - bar[0]}, not {total}")
print(f"mistake 2, blade read as C({N},{K + 1}): {choose(N, K + 1)}, not {total}")
print(f"mistake 3, blade read as C({N + 1},{K}): {choose(N + 1, K)}, not {total}")
print(f"mistake 4, row {N} added instead of the diagonal: {sum(rows[N])}, not {total}")
assert bar == layers                                    # triangle by addition vs. tins laid out
assert running == next_column and rows[N + 1][K + 1] == total   # running totals vs. factorials
assert by_largest == layers and len(picks) == total     # every pick listed, split by its largest
assert flat == choose(7, 2) and deep == choose(8, 4)    # running totals vs. the factorial formula
print("ALL CHECKS PASS")
