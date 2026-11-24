# BiCGSTAB and short recurrences -- the check behind the card.  Standard library only.
# Card 03-10's road network by five Krylov methods; a rush hour; an 8-link ring.
from math import sqrt, log10
M64, state, FL = (1 << 64) - 1, [0], [0]     # FL counts flops as they happen
def nxt():                                   # SplitMix64, written out
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64; z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
def unif(): return (nxt() >> 11) / 9007199254740992.0
def sci(v): m, x = f"{v:.3e}".split("e"); return m + "e" + str(int(x))  # as Rust
def dot(u, v):
    FL[0] += 2 * len(u); acc = 0.0
    for a, b in zip(u, v): acc += a * b
    return acc
def axpy(a, x, y): FL[0] += 2 * len(x); return [a * p + q for p, q in zip(x, y)]
def nrm(v): return sqrt(dot(v, v))
R, C = 250, 200; n = R * C
OFF = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, -1), (-1, 1)]  # k ^ 1 reverses k
nb = [[((i // C + dr) % R) * C + (i % C + dc) % C for dr, dc in OFF] for i in range(n)]
def network(lo, span):                       # card 03-10's network; exits lo..lo+span
    state[0] = 20261111; t, e, W, s = [0.0] * n, [0.0] * n, [], [0.0] * n
    for j in range(n):                       # illustrative traffic numbers
        t[j] = [1.0, 2.0, 5.0, 10.0, 30.0][nxt() % 5]; e[j] = lo + span * unif()
        g = [0.5 + unif() for _ in range(6)]; tot = dot(g, [1.0] * 6)
        W.append([(1.0 - e[j]) * v / tot for v in g]); s[j] = 0.5 + unif()
    ptr, col, val = [0], [], []              # compressed sparse rows of A
    for i in range(n):
        col.append(i); val.append(1.0 / t[i])
        for k in range(6): col.append(nb[i][k]); val.append(-W[nb[i][k]][k ^ 1] / t[nb[i][k]])
        ptr.append(len(col))
    def B(v):                                # B = A M^-1: scale by t, then A
        FL[0] += 2 * len(val) + n; x = [a * c for a, c in zip(t, v)]; y = [0.0] * n
        for i in range(n):
            acc = 0.0
            for p in range(ptr[i], ptr[i + 1]): acc += val[p] * x[col[p]]
            y[i] = acc
        return y
    def BT(v):                               # B^T = M^-1 A^T: A^T first, then scale
        FL[0] += 2 * len(val) + n; y = [0.0] * n
        for i in range(n):
            for p in range(ptr[i], ptr[i + 1]): y[col[p]] += val[p] * v[i]
        return [a * c for a, c in zip(t, y)]
    return t, e, s, B, BT
def gmres(op, b, tol, kmax):                 # card 03-10's GMRES, Givens rotations
    bn = nrm(b); FL[0] += len(b); Q, H, cs, sn, g, hist = [[v / bn for v in b]], [], [], [], [bn], [1.0]
    for k in range(kmax):
        w = op(Q[k]); h = []
        for q in Q: h.append(dot(w, q)); w = axpy(-h[-1], q, w)
        h.append(nrm(w))
        for j in range(k): h[j], h[j + 1] = cs[j] * h[j] + sn[j] * h[j + 1], -sn[j] * h[j] + cs[j] * h[j + 1]
        r = sqrt(h[k] * h[k] + h[k + 1] * h[k + 1]); hk = h[k + 1] if h[k + 1] != 0.0 else 1.0
        cs.append(h[k] / r); sn.append(h[k + 1] / r); FL[0] += len(b); Q.append([v / hk for v in w])
        h[k] = r; g.append(-sn[k] * g[k]); g[k] = cs[k] * g[k]; H.append(h); hist.append(abs(g[k + 1]) / bn)
        if hist[-1] < tol: break
    m = len(H); y = [0.0] * m; u = [0.0] * len(b)
    for i in range(m - 1, -1, -1):           # back-substitute the small system
        acc = g[i]
        for j in range(i + 1, m): acc -= H[j][i] * y[j]
        y[i] = acc / H[i][i]
    for j in range(m): u = axpy(y[j], Q[j], u)
    return u, hist, len(hist) - 1
def restarted(op, b, m, tol, pmax):          # GMRES(m): keep m + 1 basis vectors
    u, r, hist, prods, bn = [0.0] * len(b), b, [1.0], 0, nrm(b)
    while hist[-1] >= tol and prods < pmax:
        du, h, _ = gmres(op, r, tol * bn / nrm(r), m); u = axpy(1.0, du, u)
        r = axpy(-1.0, op(u), b); prods += len(h); hist.append(nrm(r) / bn)
    return u, hist, prods
def bicg(op, opT, b, rt, tol, kmax):         # two-sided Lanczos, coupled form
    u, r, p, pt, h, bn, keep = [0.0] * len(b), b, b, rt, [1.0], nrm(b), [(b, rt)]; rho = dot(rt, b)
    for k in range(kmax):
        v = op(p); d = dot(pt, v)
        if d == 0.0: return u, h, "breakdown at step " + str(k + 1)
        al = rho / d; u = axpy(al, p, u); r = axpy(-al, v, r); rt = axpy(-al, opT(pt), rt)
        rn = dot(rt, r); be = rn / rho; rho = rn; p = axpy(be, p, r); pt = axpy(be, pt, rt); h.append(nrm(r) / bn)
        if k < 5: keep.append((r, rt, al))     # the first six pairs, for the check
        if h[-1] < tol: break
    return u, h, keep
def cgs(op, b, tol, kmax):                   # Sonneveld: BiCG's polynomial squared
    u, r, w, p, h, bn = [0.0] * len(b), b, b, b, [1.0], nrm(b); rho = dot(b, b)
    for k in range(kmax):
        v = op(p); al = rho / dot(b, v); q = axpy(-al, v, w); w2 = axpy(1.0, q, w)
        u = axpy(al, w2, u); r = axpy(-al, op(w2), r); rn = dot(b, r); be = rn / rho; rho = rn
        w = axpy(be, q, r); p = axpy(be, axpy(be, p, q), w); h.append(nrm(r) / bn)
        if h[-1] < tol: break
    return u, h, None
def bicgstab(op, b, rt, tol, kmax):          # van der Vorst: BiCG times a smoother
    u, r, p, h, bn, steps = [0.0] * len(b), b, b, [1.0], nrm(b), []; rho = dot(rt, b)
    for k in range(kmax):
        v = op(p); d = dot(rt, v)
        if d == 0.0: return u, h, "breakdown at step " + str(k + 1)
        al = rho / d; sv = axpy(-al, v, r); tv = op(sv); om = dot(tv, sv) / dot(tv, tv)
        u = axpy(om, sv, axpy(al, p, u)); r = axpy(-om, tv, sv); rn = dot(rt, r)
        be = rn / rho * al / om; rho = rn; p = axpy(be, axpy(-om, v, p), r); h.append(nrm(r) / bn); steps.append((al, om, nrm(sv) / bn))
        if h[-1] < tol: break
    return u, h, steps
def run(lo, span, label):                    # all five methods on one network
    t, e, s, B, BT = network(lo, span); out = {}
    for nm, f, vec in (("gmres", lambda: gmres(B, s, 1e-10, 200), None), ("gmres5", lambda: restarted(B, s, 5, 1e-10, 400), 9),
                       ("bicg", lambda: bicg(B, BT, s, s, 1e-10, 200), 8), ("cgs", lambda: cgs(B, s, 1e-10, 200), 9),
                       ("bicgstab", lambda: bicgstab(B, s, s, 1e-10, 200), 8)):
        FL[0] = 0; u, h, info = f(); fl = FL[0]; x = [a * c for a, c in zip(t, u)]
        pr = info if nm[:5] == "gmres" else 2 * (len(h) - 1); vec = vec or len(h) + 2
        out[nm] = (h, x, nrm(axpy(-1.0, B(u), s)) / nrm(s), info)
        print(f"{label},{nm},products={pr},residual={sci(h[-1])},true={sci(out[nm][2])},vectors={vec},bytes={8 * n * vec:,},flops={fl:,}")
        assert out[nm][2] < 3e-10 and h[-1] < 1e-10
    hg, hb, hc, hs = (out[m][0] for m in ("gmres", "bicg", "cgs", "bicgstab"))
    for j in range(1, len(hg)):              # GMRES is best at equal powers of B
        assert j >= len(hb) or hg[j] <= hb[j] * (1 + 1e-9)
        assert 2 * j >= len(hg) or j >= len(hc) or hg[2 * j] <= hc[j] * (1 + 1e-9)
        assert 2 * j >= len(hg) or j >= len(hs) or hg[2 * j] <= hs[j] * (1 + 1e-9)
    gap = max(abs(a - c) / c for a, c in zip(out["bicgstab"][1], out["gmres"][1])); assert gap < 1e-8 and all(hs[k + 1] <= out["bicgstab"][3][k][2] * (1 + 1e-12) for k in range(len(hs) - 1))  # never above the half step
    print(f"{label},bicgstab_vs_gmres_max_rel_gap={sci(gap)},cars={dot(out['bicgstab'][1], [1.0] * n):.1f},links={n:,},bytes_per_vector={8 * n:,},gmres_basis_bytes={8 * n * len(hg):,}")
    return t, e, s, B, BT, out
t, e, s, B, BT, easy = run(0.3, 0.2, "easy")
st, keep, bn2, Bs = easy["bicgstab"][3], easy["bicg"][3], dot(s, s), B(s); sB = dot(s, Bs); hv = axpy(-bn2 / sB, Bs, s); Bh = B(hv); r1 = axpy(-st[0][1], Bh, hv)
assert abs(st[0][0] - bn2 / sB) < 1e-12 and abs(st[0][2] - nrm(hv) / sqrt(bn2)) < 1e-12 and abs(dot(Bh, r1)) < 1e-10 * nrm(Bh) * nrm(hv)  # best omega: r1 at right angles to B h
print(f"step1,s.s={bn2:.4f},s.Bs={sB:.4f},Bs.Bs={dot(Bs, Bs):.4f},alpha={st[0][0]:.6f},half_step={st[0][2]:.6f},omega={st[0][1]:.6f},full_step={easy['bicgstab'][0][1]:.6f},gmres_2={easy['gmres'][0][2]:.6f}")
x = easy["bicgstab"][1]; cin, cout = dot(s, [1.0] * n), dot(e, [a / c for a, c in zip(x, t)])
assert abs(cin - cout) < 1e-8 * cin and abs(dot(x, [1.0] * n) - 1214445.5) < 0.1   # card 03-10
print(f"balance,cars_in_per_min={cin:.4f},cars_out_per_min={cout:.4f}")
bio = max(abs(dot(keep[i][1], keep[j][0])) / nrm(keep[i][1]) / nrm(keep[j][0]) for i in range(6) for j in range(6) if i != j); ag = max(abs(keep[k + 1][2] - st[k][0]) / abs(st[k][0]) for k in range(5))
z = [unif() for _ in range(n)]; a1, a2 = B(BT(z)), BT(B(z)); nn = nrm(axpy(-1.0, a2, a1)) / nrm(a1); assert bio < 1e-10 and nn > 0.01 and ag < 1e-8
print(f"lanczos,max_cos_between_shadow_i_and_residual_j={sci(bio)},alpha_gap_bicg_vs_bicgstab={sci(ag)},non_normal_gap={nn:.4f}"); print("products,gmres,bicg,cgs,bicgstab")
for p in range(0, 25, 4):
    print(str(p) + "," + ",".join(sci(h[q]) if q < len(h) else "-" for h, q in
          ((easy["gmres"][0], p), (easy["bicg"][0], p // 2), (easy["cgs"][0], p // 2), (easy["bicgstab"][0], p // 2))))
rush = run(0.02, 0.03, "rush")[5]
for nm in ("bicg", "cgs", "bicgstab"):                # count rises; find the worst
    h = rush[nm][0]; print(f"rush,{nm},rises={sum(1 for k in range(1, len(h)) if h[k] > h[k - 1])},largest={sci(max(h[1:]))}")
assert max(rush["cgs"][0][1:]) > 10.0 and max(rush["bicgstab"][0][1:]) < 1.0; print("chart,products," + ",".join(str(p) for p in range(0, 77, 4)))
for nm, d in (("gmres", 1), ("cgs", 2), ("bicgstab", 2)):
    print(f"chart,{nm}," + ",".join(f"{log10(rush[nm][0][p // d]):.2f}" for p in range(0, 77, 4)))
N, ring, ringT = 8, lambda v: [v[-1]] + v[:-1], lambda v: v[1:] + [v[0]]; e1 = [1.0] + [0.0] * 7  # the shift Z: entry i moves to i + 1
hf = gmres(ring, e1, 1e-12, N)[1]; _, hr, pr = restarted(ring, e1, 4, 1e-12, 40)
why, why2 = bicg(ring, ringT, e1, e1, 1e-12, N)[2], bicgstab(ring, e1, e1, 1e-12, N)[2]
assert max(hf[1:N]) == 1.0 and hf[N] < 1e-15 and hr[-1] == 1.0 and why == why2 == "breakdown at step 1"
print(f"ring,gmres_full_residual_after_7={hf[7]:.6f},after_8={sci(hf[N])},gmres4_after_{pr}_products={hr[-1]:.6f}")
print(f"ring,bicg={why},bicgstab={why2},shadow.Bp={dot(e1, ring(e1)):.1f},normal={all(ring(ringT(v)) == ringT(ring(v)) for v in ([0.0] * i + [1.0] + [0.0] * (N - 1 - i) for i in range(N)))}")
print("ALL CHECKS PASS")
