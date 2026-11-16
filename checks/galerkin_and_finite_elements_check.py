# Galerkin and finite elements -- the check behind the card.  Standard library only.  An L-shaped
# floor slab, 6 m x 5 m less the corner x > 4 m, y > 2.5 m; a mat puts in p = 2 W/m^2 through
# b = 0.1 m of concrete with k = 2 W/(m K) (illustrative).  The rise u above the 5 C edges solves
# -Laplacian(u) = f = p/(k b), u = 0 on the edges.  Nothing imported solves anything.
import math
P, KC, B = 2.0, 2.0, 0.1
F = P / (KC * B)                                    # f = 10 K/m^2
HS = [0.5, 0.25, 0.125, 0.0625, 0.03125]            # element leg h, in metres
SIDES = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1)]   # where a hat reaches
def level(h, notch=True):             # the mesh: nodes, numbered unknowns, triangles
    nx, ny = round(6 / h), round(5 / h)
    cell = lambda i, j: 0 <= i < nx and 0 <= j < ny and not (notch and i * h >= 4 and j * h >= 2.5)
    near = lambda i, j: [cell(i - a, j - b) for a in (0, 1) for b in (0, 1)]
    nodes = [(i, j) for i in range(nx + 1) for j in range(ny + 1) if any(near(i, j))]
    idx = {n: k for k, n in enumerate(n for n in nodes if all(near(*n)))}
    tris = [t for i in range(nx) for j in range(ny) if cell(i, j) for t in
            (((i, j), (i + 1, j), (i + 1, j + 1)), ((i, j), (i + 1, j + 1), (i, j + 1)))]
    return dict(h=h, nodes=nodes, idx=idx, tris=tris, A=h * h * len(tris) / 2)
def element(h, t):                    # one triangle's stiffness, from its corners' coordinates
    x = [(a * h, b * h) for a, b in t]
    a2 = (x[1][0] - x[0][0]) * (x[2][1] - x[0][1]) - (x[2][0] - x[0][0]) * (x[1][1] - x[0][1])
    g = [((x[(k + 1) % 3][1] - x[(k + 2) % 3][1]) / a2, (x[(k + 2) % 3][0] - x[(k + 1) % 3][0]) / a2)
         for k in range(3)]
    return [[a2 / 2 * (g[p][0] * g[q][0] + g[p][1] * g[q][1]) for q in range(3)] for p in range(3)], a2 / 2
def assemble(L, idx, share=3.0, scale=1.0):        # road 1: add each triangle into its rows
    K, b = [dict() for _ in idx], [0.0] * len(idx)
    for t in L['tris']:
        ke, area = element(L['h'], t)
        for p in range(3):
            if t[p] in idx:
                b[idx[t[p]]] += F * area / share
                for q in range(3):
                    if t[q] in idx:
                        K[idx[t[p]]][idx[t[q]]] = K[idx[t[p]]].get(idx[t[q]], 0.0) + ke[p][q] * scale
    return K, b
def stencil(L):                       # road 2: the 5-point difference stencil, written directly
    idx, K = L['idx'], [dict() for _ in L['idx']]
    for (i, j), k in idx.items():
        K[k] = {k: 4.0, **{idx[n]: -1.0 for n in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)) if n in idx}}
    return K, [F * L['h'] ** 2] * len(idx)
def cg(K, b):                         # conjugate gradients, written out
    rows, n = [list(r.items()) for r in K], len(b)
    x, r, p, it = [0.0] * n, b[:], b[:], 0
    rr = stop = sum(v * v for v in b)
    while rr > 1e-26 * stop:
        Ap = [sum(v * p[c] for c, v in row) for row in rows]
        al = rr / sum(p[k] * Ap[k] for k in range(n))
        x, r = [x[k] + al * p[k] for k in range(n)], [r[k] - al * Ap[k] for k in range(n)]
        rn = sum(v * v for v in r)
        p, rr, it = [r[k] + rn / rr * p[k] for k in range(n)], rn, it + 1
    return x, it
def prolong(v, fine):                 # a coarse broken surface, read off on the halved mesh
    return {(i, j): (v.get((i // 2, j // 2), 0.0) + v.get(((i + 1) // 2, (j + 1) // 2), 0.0)) / 2
            for (i, j) in fine['nodes']}
def restrict(r, coarse):              # its transpose: halved-mesh numbers tested on coarse hats
    return {(i, j): r.get((2 * i, 2 * j), 0.0) + sum(r.get((2 * i + a, 2 * j + b), 0.0) for a, b in SIDES) / 2
            for (i, j) in coarse['idx']}
def edge_energy(v):                   # a(w, w) on right triangles = sum of squared edge jumps
    return sum((v[(i + a, j + b)] - v[(i, j)]) ** 2 for (i, j) in v for a, b in ((1, 0), (0, 1)) if (i + a, j + b) in v)
def series(a, b, N=399):              # exact energy of the a x b rectangle: sine series, odd m, n <= N
    E = sum(64 * F * F * a * b / (math.pi ** 6 * m * m * n * n * (m * m / a ** 2 + n * n / b ** 2))
            for m in range(1, N + 1, 2) for n in range(1, N + 1, 2))
    return E, 64 * F * F * a * b / math.pi ** 4 / 8 * (a * a + b * b) / (6 * (N - 1) ** 3)

L0 = level(0.5)
ke, area = element(0.5, L0['tris'][0])
print(f"slab area {L0['A']:.1f} m^2, f = p/(k b) = {F:.1f} K/m^2")
print("element, legs 0.5 m:", " / ".join(" ".join(f"{v:.2f}" for v in row) for row in ke), f"; load per corner {F * area / 3:.5f} K")
K0, b0 = assemble(L0, L0['idx'])
S0, c0 = stencil(L0)
gap = max(abs(K0[k].get(c, 0.0) - S0[k].get(c, 0.0)) for k in range(len(K0)) for c in set(K0[k]) | set(S0[k]))
print(f"200 triangles: {len(L0['nodes'])} nodes, {len(b0)} unknowns; row 40: diagonal {K0[40][40]:.1f}, side "
      f"{K0[40][41]:.1f}, load {b0[40]:.2f} K; gap to the stencil {gap:.1f}, load gap {max(abs(b0[k] - c0[k]) for k in range(len(b0))):.1f}")
runs = {}
for name, notch in (("L", True), ("rect", False)):
    for h in HS:
        L = level(h, notch)
        K, b = assemble(L, L['idx'])
        u, it = cg(K, b)
        m = max(L['idx'], key=lambda n: u[L['idx'][n]])
        E = sum(b[k] * u[k] for k in range(len(b)))
        runs[(name, h)] = (L, K, u, E, m)
        print(f"{name:4s} {len(L['tris']):5d} triangles, h {h:.5f} m: {len(b):5d} unknowns, CG {it:3d} steps, energy "
              f"{E:.4f} K^2, mean rise {E / (F * L['A']):.4f} K, peak {max(u):.4f} K at ({m[0] * h:.4f}, {m[1] * h:.4f}) m")
Ex, tail = series(6.0, 5.0)
print(f"rect by sine series: energy {Ex:.4f} K^2, tail below {tail:.6f} K^2; true errors "
      f"{', '.join(f'{math.sqrt(Ex - runs[('rect', h)][3]):.4f}' for h in HS)} K")
order = {}
for name in ("L", "rect"):
    d = [runs[(name, HS[k + 1])][3] - runs[(name, HS[k])][3] for k in range(4)]
    order[name] = [0.5 * math.log2(d[k] / d[k + 1]) for k in range(3)]
    print(f"{name:4s} step norms sqrt(dE): {', '.join(f'{math.sqrt(x):.4f}' for x in d)} K; observed orders "
          f"{', '.join(f'{x:.3f}' for x in order[name])}")
    print(f"chart, {name}, log10 h: {', '.join(f'{math.log10(h):.2f}' for h in HS[:4])}; log10 step norm: "
          f"{', '.join(f'{math.log10(math.sqrt(x)):.2f}' for x in d)}")
ext = {nm: runs[(nm, HS[4])][3] + (runs[(nm, HS[4])][3] - runs[(nm, HS[3])][3]) / (2 ** (2 * s) - 1)
       for nm, s in (("L", 2 / 3), ("rect", 1))}
print(f"extrapolated energy: rect {ext['rect']:.4f} K^2 (series {Ex:.4f}), L {ext['L']:.3f} K^2")
Lc, Kc, uc, Ec, mc = runs[("L", 0.5)]
Lf, Kf, uf, Ef, mf = runs[("L", 0.03125)]
vf = {n: (uf[Lf['idx'][n]] if n in Lf['idx'] else 0.0) for n in Lf['nodes']}
vc = {n: (uc[Lc['idx'][n]] if n in Lc['idx'] else 0.0) for n in Lc['nodes']}
chain = [runs[("L", h)][0] for h in HS]
res = {}
for name, coarse in (("Galerkin", vc), ("interpolant", {(i, j): vf[(16 * i, 16 * j)] for (i, j) in Lc['nodes']})):
    for L in chain[1:]:
        coarse = prolong(coarse, L)
    w = {n: vf[n] - coarse[n] for n in vf}
    wl = [w[n] for n in Lf['idx']]
    r = {n: sum(v * wl[c] for c, v in Kf[k].items()) for n, k in Lf['idx'].items()}
    for L in chain[-2::-1]:
        r = restrict(r, L)
    res[name] = (math.sqrt(edge_energy(w)), max(abs(x) for x in r.values()))
print(f"Cea at 200 triangles, against 51200: Galerkin error {res['Galerkin'][0]:.4f} K (sqrt(E_f - E_h) = "
      f"{math.sqrt(Ef - Ec):.4f} K), interpolant error {res['interpolant'][0]:.4f} K")
i, j = mc
print(f"hottest node row: 4 x {uc[Lc['idx'][mc]]:.4f} - ({' + '.join(f'{vc[n]:.4f}' for n in ((i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1)))})"
      f" = {4 * vc[mc] - sum(vc[n] for n in ((i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1))):.4f} K")
print(f"orthogonality, largest a(error, coarse hat): Galerkin {res['Galerkin'][1]:.4f} K, interpolant {res['interpolant'][1]:.4f} K")
print(f"node values not exact: largest gap at the 79 nodes {max(abs(vc[n] - vf[(16 * n[0], 16 * n[1])]) for n in Lc['idx']):.4f} K")
print(f"estimated true error at 200 triangles {math.sqrt(ext['L'] - Ec):.3f} K, "
      f"{100 * math.sqrt((ext['L'] - Ec) / ext['L']):.1f} % of {math.sqrt(ext['L']):.3f} K")
lam = math.pi ** 2 * (1 / 36 + 1 / 25)
print(f"Lax-Milgram: lambda1 of the 6 m x 5 m box {lam:.5f} /m^2, C_P^2 <= {1 / lam:.4f} m^2, M = 1, "
      f"alpha >= {1 / (1 + 1 / lam):.4f}, Cea factor M/alpha <= {1 + 1 / lam:.4f}")
Ka, ba = assemble(Lc, {n: k for k, n in enumerate(Lc['nodes'])})
print(f"mistake, edges not held: largest row sum {max(abs(sum(r.values())) for r in Ka):.1f}, load sum {sum(ba):.1f} K")
for h in (0.5, 0.25):
    L = level(h)
    print(f"mistake, 1/h scaling from the cable card: peak {max(cg(*assemble(L, L['idx'], scale=1 / h))[0]):.4f} K at {len(L['tris'])} triangles")
print(f"mistake, whole triangle load on each corner: peak {max(cg(*assemble(Lc, Lc['idx'], share=1.0))[0]):.4f} K")
print(f"figure, corner (4.00, 2.50) m, hottest node at 200 triangles ({mc[0] * 0.5:.2f}, {mc[1] * 0.5:.2f}) m, {5 + max(uc):.2f} C")
assert gap < 1e-12 and max(abs(b0[k] - c0[k]) for k in range(len(b0))) < 1e-12   # road 1 = road 2
assert abs(res['Galerkin'][0] ** 2 - (Ef - Ec)) < 1e-6 * (Ef - Ec)           # edge sum = Pythagoras
assert res['Galerkin'][0] < res['interpolant'][0] and res['Galerkin'][1] < 1e-8 < res['interpolant'][1]
assert all(Ex - runs[("rect", h)][3] > 0 for h in HS) and abs(ext['rect'] - Ex) < 1e-3   # series road
assert 0.6 < order["L"][2] < 0.9 and abs(order["rect"][2] - 1) < 0.01         # the corner costs order
print("ALL CHECKS PASS")
