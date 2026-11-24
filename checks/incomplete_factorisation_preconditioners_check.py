# Incomplete factorisations -- the check behind the card.  Standard library
# only.  The heated plate's 5-point matrix: ILU(0), modified ILU(0), ILU(1),
# threshold dropping and diagonal shifts, used inside CG and BiCGSTAB.
import math
def grid(m, red_black=False, p=0.0):          # 5-point matrix; p = east-flow term
    cells = [(i, j) for j in range(m) for i in range(m)]
    if red_black: cells.sort(key=lambda c: (c[0] + c[1]) % 2)
    idx, A = {c: k for k, c in enumerate(cells)}, []
    for (i, j) in cells:
        row = {idx[(i, j)]: 4.0}
        for di, dj, v in ((-1, 0, -1 - p), (1, 0, -1 + p), (0, -1, -1.0), (0, 1, -1.0)):
            if (i + di, j + dj) in idx: row[idx[(i + di, j + dj)]] = v
        A.append(row)
    h, b = 1 / (m + 1), [0.0] * len(cells)    # heater: 1000 K/m^2 on the middle 0.25 m
    for (i, j), k in idx.items():
        if abs((i + 1) * h - 0.5) <= 0.125 and abs((j + 1) * h - 0.5) <= 0.125: b[k] = h * h * 1000
    return A, b, idx

def ilu(A, lev=0, tau=0.0, modified=False, shift=0.0):
    """Row-by-row LU keeping fill of level <= lev; returns (L, U), dropped fill, flops."""
    n, L, U, UL, drop, fl = len(A), [], [], [], {}, 0
    for i in range(n):
        w = dict(A[i]); w[i] *= 1 + shift; lv = {j: 0 for j in w}; k = -1
        while True:
            ks = [j for j in w if k < j < i]
            if not ks: break
            k = min(ks); w[k] /= U[k][k]; fl += 1
            for j, u in U[k].items():
                if j <= k: continue
                fl += 2; new = lv[k] + UL[k][j] + 1
                if j in w or new <= lev:
                    w[j] = w.get(j, 0.0) - w[k] * u; lv[j] = min(lv.get(j, new), new)
                else:                         # fill outside the kept pattern: drop it
                    drop[(i, j)] = drop.get((i, j), 0.0) - w[k] * u
                    if modified: w[i] -= w[k] * u; fl += 1
        size = math.sqrt(sum(v * v for v in A[i].values()))
        for j in [j for j in w if j != i and j not in A[i] and abs(w[j]) < tau * size]: del w[j]
        if w[i] <= 0: return None, (i, w[i]), fl   # breakdown: a pivot <= 0
        L.append({j: v for j, v in w.items() if j < i})
        U.append({j: v for j, v in w.items() if j >= i}); UL.append({j: lv[j] for j in U[-1]})
    return (L, U), drop, fl

def acc(pairs):                               # a plain left-to-right sum of products
    s = 0.0
    for a, c in pairs: s += a * c
    return s
def solve(F, r):                              # M z = r: forward with L, back with U
    L, U = F; n = len(r); y, z = [0.0] * n, [0.0] * n
    for i in range(n): y[i] = r[i] - acc((v, y[j]) for j, v in L[i].items())
    for i in range(n - 1, -1, -1):
        z[i] = (y[i] - acc((v, z[j]) for j, v in U[i].items() if j > i)) / U[i][i]
    return z

def mv(A, x): return [acc((v, x[j]) for j, v in row.items()) for row in A]
def dot(a, c): return acc(zip(a, c))
def rel(A, b, x): return math.sqrt(dot(r := [s - t for s, t in zip(b, mv(A, x))], r) / dot(b, b))
def nnz(F): return sum(len(l) + len(u) for l, u in zip(*F))
def pcg(A, b, F=None, steps=130):             # count = first step with ||r|| <= 1e-8 ||b||
    x, r, count, xs, hist = [0.0] * len(b), b[:], None, None, [0.0]
    z = solve(F, r) if F else r[:]; p = z[:]; rz = dot(r, z)
    for k in range(1, steps + 1):
        q = mv(A, p); a = rz / dot(p, q)
        x = [s + a * t for s, t in zip(x, p)]; r = [s - a * t for s, t in zip(r, q)]
        if count is None and dot(r, r) <= 1e-16 * dot(b, b): count, xs = k, x
        if k % 10 == 0: hist.append(math.log10(rel(A, b, x)))
        z = solve(F, r) if F else r[:]; rz, old = dot(r, z), rz
        p = [s + rz / old * t for s, t in zip(z, p)]
    return count, xs, hist

def bicgstab(A, b, F=None):
    P = (lambda y: solve(F, y)) if F else (lambda y: y[:])
    x = [0.0] * len(b); r = b[:]; rh = b[:]; rho = al = om = 1.0; v = p = [0.0] * len(b)
    for k in range(1, 300):
        rho, old = dot(rh, r), rho; be = rho / old * al / om
        p = [s + be * (t - om * u) for s, t, u in zip(r, p, v)]; ph = P(p); v = mv(A, ph)
        al = rho / dot(rh, v); s = [t - al * u for t, u in zip(r, v)]; sh = P(s); t = mv(A, sh)
        om = dot(t, s) / dot(t, t); x = [c + al * d + om * e for c, d, e in zip(x, ph, sh)]
        r = [c - om * d for c, d in zip(s, t)]
        if dot(r, r) <= 1e-16 * dot(b, b): return k, x

def piv(F): return [F[1][i][i] for i in range(len(F[1]))]
def fmt(xs): return " ".join(f"{x:.4f}" for x in xs)
def yn(c): return "yes" if c else "no"
A4, _, _ = grid(4); F4, drop4, _ = ilu(A4); E4 = ilu(A4, lev=99)[0]
print(f"4 by 4 grid: 16 unknowns, {sum(map(len, A4))} nonzeros in A")
print(f"first fill: row 2, column 5 gets 0 - (-1)(-1)/4 = {drop4[(1, 4)]:.4f}, dropped by IC(0)")
print("IC(0) pivots:", fmt(piv(F4))); print("exact pivots:", fmt(piv(E4)))
offs = sorted({abs(i - j) for i, j in drop4})
print(f"dropped fill: {len(drop4)} entries, all {offs[0]} places off the diagonal, "
      f"sizes {min(map(abs, drop4.values())):.4f} to {max(map(abs, drop4.values())):.4f}")
R4 = [[A4[i].get(j, 0.0) - F4[1][i].get(j, 0.0) - acc((v, F4[1][k].get(j, 0.0)) for k, v in F4[0][i].items())
       for j in range(16)] for i in range(16)]
on = max(abs(R4[i][j]) for i in range(16) for j in A4[i])
off = max(abs(R4[i][j] - drop4.get((i, j), 0.0)) for i in range(16) for j in range(16))
print(f"A - LU below 1e-14 on the pattern: {yn(on < 1e-14)}; equal to the dropped fill off it: {yn(off < 1e-14)}")
print("figure, 16 by 16 pattern, dropped fill at", " ".join(f"{i+1}:{j+1}" for i, j in sorted(drop4) if i < j))
print("grid   unknowns   CG  IC(0)  MIC(0)  IC(1)  IC(0) red-black")
for m in (15, 31, 63):
    A, b, idx = grid(m); Ar, br, _ = grid(m, red_black=True); F, _, ffl = ilu(A); M, _, mfl = ilu(A, modified=True)
    runs = [pcg(A, b), pcg(A, b, F), pcg(A, b, M), pcg(A, b, ilu(A, lev=1)[0]), pcg(Ar, br, ilu(Ar)[0])]
    print(f"{m:>4} {m * m:>10} " + " ".join(f"{c:>5}" for c, _, _ in runs))
d = {}                                        # second road to the IC(0) pivots: the grid recurrence
for j in range(63):
    for i in range(63): d[(i, j)] = 4 - (1 / d[(i - 1, j)] if i else 0) - (1 / d[(i, j - 1)] if j else 0)
gap = max(abs(d[c] - F[1][k][k]) for c, k in idx.items())
print(f"IC(0) pivots by the grid recurrence d = 4 - 1/d(west) - 1/d(south): agree to 1e-12: {yn(gap < 1e-12)}")
n, nz = m * m, sum(map(len, A)); cg_step, pc_step = 2 * nz + 10 * n, 4 * nz + 9 * n
print(f"63 by 63: n = {n}, nonzeros {nz}; IC(1) factor {nnz(ilu(A, lev=1)[0])}; IC(0) factor costs {ffl} flops, MIC(0) {mfl}")
print(f"flops per step: CG {cg_step}, preconditioned CG {pc_step}")
tot = [runs[0][0] * cg_step, runs[1][0] * pc_step + ffl, runs[2][0] * pc_step + mfl]
print(f"flops to 1e-8: CG {tot[0]}, IC(0) {tot[1]}, MIC(0) {tot[2]}")
for name, (c, _, h) in zip(("CG", "IC(0)", "MIC(0)"), runs):
    print(f"chart, {name:<6} log10 relative residual, steps 0 to 120 by 10:", " ".join(f"{v:.2f}" for v in h[:13]))
mid = idx[(31, 31)]; xc, xi = runs[0][1], runs[1][1]; kap = (math.sin(63 * math.pi / 128) / math.sin(math.pi / 128)) ** 2
diff, top = max(abs(s - t) for s, t in zip(xc, xi)), max(map(abs, xc))
print(f"centre temperature: CG {xc[mid]:.4f} C, IC(0) {xi[mid]:.4f} C; largest gap {diff / top:.2e} of the peak {top:.4f} C")
print(f"condition number of A: {kap:.1f}; bound on each answer's relative error {kap * 1e-8:.8f}")
A15, b15, _ = grid(15); c15 = pcg(A15, b15, ilu(A15, lev=99)[0], steps=1)[0]
print(f"15 by 15 with the full factor (no dropping): {c15} step")
print(f"estimate, 1023 by 1023: CG {runs[0][0] * 16}, IC(0) {runs[1][0] * 16}, MIC(0) {runs[2][0] * 4} steps")
K = [{0: 3.0, 1: -2.0, 3: 2.0}, {0: -2.0, 1: 3.0, 2: -2.0}, {1: -2.0, 2: 3.0, 3: -2.0}, {0: 2.0, 2: -2.0, 3: 3.0}]
fails = ilu(K)[1]; shifted = [ilu(K, shift=s)[0] for s in (0.1, 0.2)]
print(f"Kershaw: IC(0) pivot {fails[0] + 1} comes out {fails[1]:.4f}; exact pivots {fmt(piv(ilu(K, lev=99)[0]))}")
print(f"Kershaw shifted 10%: {'breaks' if shifted[0] is None else 'works'}; 20%: pivots {fmt(piv(shifted[1]))}")
G = ilu(A, tau=0.01, lev=99)[0]; cT = pcg(A, b, G)
print(f"CG with a threshold factor (tau 0.01, not symmetric): no pass in 130 steps, log10 residual {cT[2][-1]:.2f}")
mic_gap = max(abs(v - 1) for v in solve(M, [sum(r.values()) for r in A]))
print(f"MIC(0) keeps row sums: M^-1 (A times ones) = ones to 1e-12: {yn(mic_gap < 1e-12)}")
Aw, bw, _ = grid(63, p=0.5); out = [(bicgstab(Aw, bw)[0], nz)]
for opt in (dict(), dict(lev=1), dict(lev=99, tau=1e-2), dict(lev=99, tau=1e-3)):
    Fw = ilu(Aw, **opt)[0]; out.append((bicgstab(Aw, bw, Fw)[0], nnz(Fw)))
print("plate with flow, BiCGSTAB steps (factor nonzeros): none, ILU(0), ILU(1), tau 1e-2, tau 1e-3:",
      ", ".join(f"{c} ({z})" for c, z in out))
assert drop4[(1, 4)] == -0.25 and offs == [3] and len(drop4) == 18 and on < 1e-14 and off < 1e-14
assert all(s >= t - 1e-12 for s, t in zip(piv(F4), piv(E4))) and gap < 1e-12
assert runs[0][0] > 2 * runs[1][0] > 2 * runs[2][0] and runs[4][0] > runs[1][0] and c15 == 1
assert diff < 2 * kap * 1e-8 * top and mic_gap < 1e-12 and tot[2] < tot[1] < tot[0]
assert fails[0] == 3 and fails[1] < 0 and shifted[0] is None and min(piv(shifted[1])) > 0
assert cT[0] is None and out[1][1] == nz and out[0][0] > out[1][0] > out[2][0] > out[3][0]
print("ALL CHECKS PASS")
