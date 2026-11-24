# Convolutional networks -- the check behind the card.  Nothing is imported.
# A synthetic 28 x 28 digit "7" (ink 1, paper 0, drawn by the rule below) goes
# through 8 filters of 3 x 3, each bias -1, then ReLU = max(0, value).  Roads:
# size and parameter formulas against counting; a sliding loop against the
# same layer written as a 784 x 5408 matrix; shift proofs against comparing
# every number.
N, K, F = 28, 3, 8
NAMES = ["ink below", "ink below-right", "ink right", "ink above-right",
         "ink above", "ink above-left", "ink left", "ink below-left"]
DIRS = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
sign = lambda v: (v > 0) - (v < 0)
yn = lambda c: "yes" if c else "no"
W = [[[sign(di * a + dj * b) for dj in (-1, 0, 1)] for di in (-1, 0, 1)] for a, b in DIRS]
B = [-1] * F

def digit(dr, dc):                     # the 7: a top bar and a slanting stroke
    x = [[0] * N for _ in range(N)]
    ink = [(r, c) for r in (6, 7) for c in range(7, 21)]
    ink += [(r, 19 - (r - 8) // 2 + d) for r in range(8, 23) for d in (0, 1)]
    for r, c in ink:
        if 0 <= r + dr < N and 0 <= c + dc < N:
            x[r + dr][c + dc] = 1
    return x

def conv(x, s=1, flip=False, pad=0):   # road one: slide each filter, gather
    x = [[0] * (N + 2 * pad)] * pad + [[0] * pad + r + [0] * pad for r in x] + [[0] * (N + 2 * pad)] * pad
    m = (len(x) - K) // s + 1
    out = []
    for f in range(F):
        w = [row[::-1] for row in W[f][::-1]] if flip else W[f]
        out.append([[max(0, B[f] + sum(w[a][b] * x[i * s + a][j * s + b]
                     for a in range(K) for b in range(K))) for j in range(m)] for i in range(m)])
    return out

def shift(y, dr, dc):                  # move every map, filling with zeros
    m = len(y[0])
    return [[[y[f][i - dr][j - dc] if 0 <= i - dr < m and 0 <= j - dc < m else 0
              for j in range(m)] for i in range(m)] for f in range(len(y))]

def pool(y, p=2):                      # max over p x p blocks, stride p
    m = len(y[0]) // p
    return [[[max(y[f][p * i + a][p * j + b] for a in range(p) for b in range(p))
              for j in range(m)] for i in range(m)] for f in range(len(y))]

def diff(y, z):                        # how many numbers disagree
    return sum(u != v for g, h in zip(y, z) for r, q in zip(g, h) for u, v in zip(r, q))

def kept(y, z):                        # active values of y that z keeps in place
    act = [(f, i, j) for f in range(len(y)) for i in range(len(y[0])) for j in range(len(y[0])) if y[f][i][j]]
    return sum(y[f][i][j] == z[f][i][j] for f, i, j in act), len(act)

def size(n, k, p, s):                  # the formula
    return (n + 2 * p - k) // s + 1

def fits(n, k, p, s):                  # count window starts that fit
    return sum(1 for i in range(0, n + 2 * p) if i % s == 0 and i + k <= n + 2 * p)

x = digit(0, 0)
y = conv(x)
m = size(N, K, 0, 1)
links = [(f * m * m + i * m + j, (i + a) * N + j + b, (f, a, b))   # road two:
         for f in range(F) for i in range(m) for j in range(m)     # the layer
         for a in range(K) for b in range(K)]                      # as a matrix
acc = [B[o // (m * m)] for o in range(F * m * m)]
flat = [v for row in x for v in row]
for o, p, (f, a, b) in links:          # scatter each input into its outputs
    acc[o] += W[f][a][b] * flat[p]
y2 = [[[max(0, acc[f * m * m + i * m + j]) for j in range(m)] for i in range(m)] for f in range(F)]
slots = len({s for _, _, s in links})
dense = N * N * F * m * m
print(f"image {N} x {N}, ink pixels {sum(flat)}; {F} filters of {K} x {K}, bias -1 each")
for f in range(F):
    print(f"filter {f + 1} {NAMES[f]:<15} {W[f]}")
print(f"output side, formula (28 + 2*0 - 3)//1 + 1 = {m}; window starts counted: {fits(N, K, 0, 1)}")
print(f"output numbers {m} x {m} x {F} = {F * m * m}")
print(f"parameters, formula {F} x ({K * K} + 1) = {F * (K * K + 1)}; slots counted in the matrix {slots} + biases {F}")
print(f"dense layer to the same output: {N * N} x {F * m * m} = {dense} weights, {dense + F * m * m} with biases")
print(f"matrix entries the layer can set: {len(links)} of {dense} ({100 * len(links) / dense:.2f} %)")
print(f"dense weights per conv parameter, whole part: {dense // (F * (K * K + 1))}")
print(f"sliding loop and matrix agree on all {F * m * m} outputs: {yn(y == y2)}")
pt = [x[5 + a][9:12] for a in range(K)]
print(f"by hand, filter 1 at row 5, col 9: patch {pt} -> {sum(W[0][a][b] * pt[a][b] for a in range(K) for b in range(K))} - 1 -> {y[0][5][9]}")
print(f"figure, ink pixels {sum(flat)}; window rows 5-7, cols 9-11; filter 1 active cells {sum(v > 0 for r in y[0] for v in r)}")
active = [sum(v > 0 for r in y[f] for v in r) for f in range(F)]
print(f"active (non-zero) values per map {active}, total {sum(active)}")
for dr, dc in [(0, 1), (1, 0), (3, -2)]:
    ys = conv(digit(dr, dc))
    print(f"shift ({dr}, {dc}): conv(shift x) vs shift(conv x) disagree at {diff(ys, shift(y, dr, dc))} of {F * m * m}; "
          f"unshifted maps disagree at {diff(ys, y)}")
y1 = conv(digit(0, 1))
print(f"after shift (0, 1), filter 1 at row 5, col 10: {y1[0][5][10]}")
P, P2 = pool(y), pool(conv(digit(0, 2)))
print(f"max pool 2 x 2: {len(P[0])} x {len(P[0])} x {F} = {F * len(P[0]) ** 2} numbers")
gs = lambda z: [sum(v for r in z[f] for v in r) for f in range(F)]
Pb = [[[0] * (m // 2) for _ in range(m // 2)] for _ in range(F)]      # pooling, road two: every cell of the
for f, r, c in [(f, r, c) for f in range(F) for r in range(m) for c in range(m)]:   # matrix road raises its block's max
    Pb[f][r // 2][c // 2] = max(Pb[f][r // 2][c // 2], y2[f][r][c])
same = lambda u, v: sum(a > 0 and a == b for g, k in zip(u, v) for r, q in zip(g, k) for a, b in zip(r, q))   # recount
tot, rc = [0] * 6, [0, 0]
for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
    z = conv(digit(*d))
    a, b, c, e = *kept(y, z), *kept(P, pool(z))
    rc = [rc[0] + same(y, z), rc[1] + same(Pb, pool(z))]
    g = sum(u == v for u, v in zip(gs(y), gs(z)))
    tot = [t + v for t, v in zip(tot, (a, b, c, e, g, F))]
    print(f"shift {d}: raw values kept {a} of {b}; pooled kept {c} of {e}; map sums kept {g} of {F}")
print(f"over the four 1-pixel shifts: raw {tot[0]} of {tot[1]} ({100 * tot[0] / tot[1]:.0f} %), pooled "
      f"{tot[2]} of {tot[3]} ({100 * tot[2] / tot[3]:.0f} %), map sums {tot[4]} of {tot[5]} ({100 * tot[4] / tot[5]:.0f} %)")
print(f"pooled, 2-pixel shift vs pooled map moved 1 cell: disagree at {diff(P2, shift(P, 0, 1))}")
print(f"map sums {gs(y)}; after shift (3, -2) {gs(conv(digit(3, -2)))}")
s2, s2s = conv(x, 2), conv(digit(0, 1), 2)
m2 = size(N, K, 0, 2)
sub = [[[y[f][2 * i][2 * j] for j in range(m2)] for i in range(m2)] for f in range(F)]
print(f"stride 2: side (28 - 3)//2 + 1 = {m2}, counted {fits(N, K, 0, 2)}; equals every 2nd stride-1 value: {yn(s2 == sub)}")
best = min(diff(s2s, shift(s2, 0, c)) for c in (0, 1))   # not still, not moved 1 cell
print(f"stride 2, 1-pixel shift: no shifted copy, disagree at {best} of {F * m2 * m2}; "
      f"2-pixel shift vs moved 1 cell: {diff(conv(digit(0, 2), 2), shift(s2, 0, 1))}")
cases = [(28, 3, 0, 1), (28, 3, 1, 1), (28, 5, 0, 1), (28, 3, 0, 2), (26, 2, 0, 2), (224, 7, 3, 2)]
print("side n k p s -> formula, counted: " + "; ".join(f"{c} -> {size(*c)}, {fits(*c)}" for c in cases))
print(f"mistake, bias forgotten: {F} x {K * K} = {F * K * K} parameters, not {F * (K * K + 1)}")
print(f"mistake, side as n - k: {N - K}, not {m}; numbers {F * (N - K) ** 2}, not {F * m * m}")
yp, ye = conv(x, pad=1), conv(digit(0, 8), pad=1)
print(f"breaks, padding 1 (side {len(yp[0])}), shift (0, 8) pushes ink past the edge: disagree at {diff(ye, shift(yp, 0, 8))}")
yf = conv(x, flip=True)
print(f"mistake, flipping the filter (textbook convolution): filter 1 map equals filter 5 map: {yn(yf[0] == y[4])}")
assert m == fits(N, K, 0, 1) and all(size(*c) == fits(*c) for c in cases)   # formula vs count
assert slots + F == F * (K * K + 1)                          # slots counted vs formula
assert y == y2                                               # gather against scatter
assert sum(W[0][a][b] * pt[a][b] for a in range(K) for b in range(K)) - 1 == y[0][5][9] == 2   # by hand
assert all(diff(conv(digit(dr, dc)), shift(y, dr, dc)) == 0 for dr, dc in [(0, 1), (1, 0), (3, -2)])
assert diff(P2, shift(P, 0, 1)) == 0                         # pooled map moves 1 cell
assert gs(y) == gs(conv(digit(3, -2)))                       # map sums do not move
assert Pb == P                                               # pooling: gather vs scatter
assert tot[:4] == [rc[0], 4 * sum(active), rc[1], 4 * sum(v > 0 for g in Pb for r in g for v in r)]   # recount
assert tot[2] * tot[1] > tot[0] * tot[3]                     # pooling keeps a larger share
assert s2 == sub                                             # stride = subsampling
assert best > 0                                              # stride breaks 1-pixel shifts
assert diff(ye, shift(yp, 0, 8)) > 0                         # padding breaks at the edge
print("ALL CHECKS PASS")
