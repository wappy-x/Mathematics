# Manifold learning check: Isomap on 600 photos of one guitar under changing light.
# Standard library only. Random numbers come from SplitMix64, written out below.
import heapq, math

M64 = (1 << 64) - 1
state = [0]
def rand():  # SplitMix64: a float in [0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def gauss():  # Box-Muller: one standard normal draw
    u1, u2 = rand(), rand()
    return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)

# A 6 x 4 thumbnail, 24 grey levels. Three lighting patterns, perpendicular, each of length 1:
# side light brightens the right-hand columns, top light the top rows, front light every pixel.
PX = [(i % 6 - 2.5) / math.sqrt(70.0) for i in range(24)]
PY = [(1.5 - i // 6) / math.sqrt(30.0) for i in range(24)]
PZ = [1.0 / math.sqrt(24.0) for i in range(24)]
T0, T1, HMAX = 1.5 * math.pi, 4.5 * math.pi, 12.0  # key lamp 270 to 810 degrees; fill 0 to 12
def make(n, sigma, seed=2026):  # 13 probe photos (fill 6), then random knob settings
    state[0] = seed
    knobs = [(T0 + j * math.pi / 4.0, HMAX / 2.0) for j in range(13)]
    while len(knobs) < n:  # t drawn so that nearly equal areas of the sheet get equal shares
        knobs.append((math.sqrt(T0 * T0 + (T1 * T1 - T0 * T0) * rand()), HMAX * rand()))
    return knobs, [[128.0 + t * math.cos(t) * PX[i] + t * math.sin(t) * PY[i] + h * PZ[i]
                    + sigma * gauss() for i in range(24)] for t, h in knobs]
def sheet_s(t):  # length of the spiral (t cos t, t sin t) from angle 0 to angle t, closed form
    w = math.sqrt(t * t + 1.0)
    return 0.5 * (t * w + math.log(t + w))
def simpson(a, b, m):  # the same length by Simpson's rule on the speed sqrt(t^2 + 1)
    f = lambda t: math.sqrt(t * t + 1.0)
    hh = (b - a) / m
    return (f(a) + f(b) + sum((4.0 if j % 2 else 2.0) * f(a + j * hh) for j in range(1, m))) * hh / 3.0
def graph(E, order, k):  # k-nearest-neighbour graph, then Dijkstra from every photo
    n = len(E)
    adj = [dict() for _ in range(n)]
    for i in range(n):
        for j in order[i][1:k + 1]:
            adj[i][j] = adj[j][i] = E[i][j]
    G = []
    for s in range(n):
        d = [math.inf] * n
        d[s] = 0.0
        heap = [(0.0, s)]
        while heap:
            du, u = heapq.heappop(heap)
            if du > d[u]: continue
            for v, w in adj[u].items():
                if du + w < d[v]:
                    d[v] = du + w
                    heapq.heappush(heap, (d[v], v))
        G.append(d)
    return G
def eigen(A, r, iters, shift=0.0):  # power iteration on A + shift I, each vector kept perpendicular to the earlier ones
    vals, vecs = [], []
    for c in range(r):
        v = [1.0 + ((i * 7 + c * 3) % 11) / 10.0 for i in range(len(A))]
        for _ in range(iters):
            for u in vecs:
                dot = sum(a * b for a, b in zip(v, u))
                v = [a - dot * b for a, b in zip(v, u)]
            w = [sum(a * b for a, b in zip(row, v)) + shift * x for row, x in zip(A, v)]
            nrm = math.sqrt(sum(a * a for a in w))
            v = [a / nrm for a in w]
        vals.append(sum(a * sum(b * c for b, c in zip(row, v)) for a, row in zip(v, A)))
        vecs.append(v)
    return vals, vecs
def mds(G, r, shift=0.0):  # classical scaling: a table of distances -> r coordinates per photo
    n = len(G)
    D2 = [[x * x for x in row] for row in G]
    rm = [sum(row) / n for row in D2]
    gm = sum(rm) / n
    B = [[-0.5 * (D2[i][j] - rm[i] - rm[j] + gm) for j in range(n)] for i in range(n)]
    vals, vecs = eigen(B, r, 60, shift)
    Y = [[v[i] * math.sqrt(max(l, 0.0)) for l, v in zip(vals, vecs)] for i in range(n)]
    return vals, Y
def corr(a, b):
    ma, mb = sum(a) / len(a), sum(b) / len(b)
    sab = sum((x - ma) * (y - mb) for x, y in zip(a, b))
    return sab / math.sqrt(sum((x - ma) * (x - ma) for x in a) * sum((y - mb) * (y - mb) for y in b))
def isomap(E, order, k, s, hs):  # graph distances, coordinates, eigenvalues, both correlations
    G = graph(E, order, k)
    vals, Y = mds(G, 3)
    if Y[0][0] > 0:  # a convention: the first probe photo sits at the left
        Y = [[-y[0], y[1], y[2]] for y in Y]
    if corr([y[1] for y in Y], hs) < 0:  # and the fill dimmer points up
        Y = [[y[0], -y[1], y[2]] for y in Y]
    return G, Y, vals, corr([y[0] for y in Y], s), corr([y[1] for y in Y], hs)
def run(n, sigma, k):
    knobs, ph = make(n, sigma)
    E = [[math.sqrt(sum((x - y) * (x - y) for x, y in zip(p, q))) for q in ph] for p in ph]  # straight lines
    order = [sorted(range(n), key=lambda j: E[i][j]) for i in range(n)]
    s = [sheet_s(t) - sheet_s(T0) for t, h in knobs]
    return knobs, ph, E, order, s, [h for t, h in knobs]

knobs, ph, E, order, s, hs = run(600, 0.05, 10)
print("photos 600, pixels 24, neighbours k = 10, sensor noise 0.05 grey levels")
sAB, simAB = sheet_s(T0 + 2 * math.pi) - sheet_s(T0), simpson(T0, T0 + 2 * math.pi, 200)
G, Y, vals, c1, c2 = isomap(E, order, 10, s, hs)
print(f"A at 270 deg, B at 630 deg, fill 6: radii {T0:.3f} and {T0 + 2 * math.pi:.3f}, gap 2 pi = {2 * math.pi:.3f}")
print(f"A-B straight line {E[0][8]:.3f}; s(A) {sheet_s(T0):.3f}, s(B) {sheet_s(T0 + 2 * math.pi):.3f}, along the sheet {sAB:.3f} (Simpson {simAB:.3f})")
print(f"A-B through the graph {G[0][8]:.3f}, {100 * (G[0][8] / sAB - 1):.1f}% long; on the Isomap map {Y[8][0] - Y[0][0]:.3f} apart")
print(f"whole roll along the sheet {s[12]:.3f} (Simpson {simpson(T0, T1, 200):.3f})")
print("angle_deg, straight, sheet, graph, isomap_1, pca_1")
n = 600
mean = [sum(p[i] for p in ph) / n for i in range(24)]
X = [[p[i] - mean[i] for i in range(24)] for p in ph]
C = [[sum(x[i] * x[j] for x in X) / (n - 1) for j in range(24)] for i in range(24)]
pv, pvec = eigen(C, 3, 300)
Z = [[sum(a * b for a, b in zip(x, v)) for v in pvec] for x in X]
if Z[0][0] > 0: Z = [[-z[0], z[1], z[2]] for z in Z]
for j in range(13):
    print(f"{270 + 45 * j}, {E[0][j]:.2f}, {s[j]:.2f}, {G[0][j]:.2f}, {Y[j][0]:.2f}, {Z[j][0]:.2f}")
top = mds(G, 3, max(0.0, -vals[2]))[0]  # shifted by the most negative eigenvalue's size: the largest positive ones
print(f"isomap eigenvalues, largest in size {vals[0]:.0f}, {vals[1]:.0f}, then {vals[2]:.0f}; largest three {top[0]:.0f}, {top[1]:.0f}, {top[2]:.0f}")
print(f"isomap: corr(coord 1, sheet length) {c1:.5f}, corr(coord 2, fill) {c2:.4f}")
tr = sum(C[i][i] for i in range(24))
print(f"pca shares {pv[0] / tr:.4f}, {pv[1] / tr:.4f}, {pv[2] / tr:.4f}; top three {(pv[0] + pv[1] + pv[2]) / tr:.5f}")
p1, p2 = corr([z[0] for z in Z], s), corr([z[1] for z in Z], s)
print(f"pca: corr(pc 1, sheet length) {p1:.4f}, corr(pc 2, sheet length) {p2:.4f}, corr(pc 3, fill) {abs(corr([z[2] for z in Z], hs)):.4f}")
Gb, _, _, b1, _ = isomap(E, order, 20, s, hs)
print(f"break, k = 20: start to end through the graph {Gb[0][12]:.2f} against {s[12]:.2f} along the sheet; corr {b1:.4f}")
print(f"break, k = 2: photos unreachable from the first {sum(1 for x in graph(E, order, 2)[0] if x == math.inf)}")
for lab, nn, sg, kk in [("k = 6", 600, 0.05, 6), ("k = 14", 600, 0.05, 14), ("noise 0.5", 600, 0.5, 10), ("300 photos", 300, 0.05, 10)]:
    _, _, Et, ot, st, ht = run(nn, sg, kk)
    Gt, _, _, t1, t2 = isomap(Et, ot, kk, st, ht)
    print(f"try {lab}: end to end {Gt[0][12]:.2f}, corr {t1:.4f}, {t2:.4f}")

assert abs(sAB - simAB) < 1e-6 and abs(s[12] - simpson(T0, T1, 200)) < 1e-6  # closed form against Simpson
assert abs(E[0][8] - 2 * math.pi) < 0.3            # neighbouring turns sit one gap of 2 pi apart
assert 1.0 < G[0][8] / sAB < 1.06                  # the graph follows the sheet, a little long
assert c1 > 0.999                                  # Isomap's first coordinate is the sheet length
assert c2 > 0.95                                   # and its second is the fill dimmer
assert max(abs(p1), abs(p2)) < 0.5                 # PCA's flat view does not unroll
assert Gb[0][12] < 0.5 * s[12]                     # too many neighbours: a short cut
assert 0 < top[2] < 0.25 * top[1] and top[2] < -vals[2]  # a third direction, smaller than the distortion
print("ALL CHECKS PASS")
