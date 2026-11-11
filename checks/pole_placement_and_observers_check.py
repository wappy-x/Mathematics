# Pole placement and an observer for the cart and pendulum -- the check behind the card.
# Standard library only.  State x = (p, v, theta, w): cart position m, cart speed m/s, lean rad,
# lean rate rad/s.  Input u = cart acceleration the motor commands, m/s^2.
# Near upright: p'' = u and theta'' = 16 theta - c u, with c = 1/l = 16/9.81 per m.
def plant(l):
    return ([[0.0, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 1], [0, 0, 9.81 / l, 0]], [0.0, 1, 0, -1 / l])
L0 = 9.81 / 16                                    # model rod length, 0.613125 m
A, B = plant(L0); c = 1 / L0
def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def tr(X): return [list(r) for r in zip(*X)]
def eye(n): return [[float(i == j) for j in range(n)] for i in range(n)]
def poly(roots):                                  # coefficients of (s - r1)(s - r2)..., highest power first
    p = [1 + 0j]
    for r in roots: p = [a - r * b for a, b in zip(p + [0], [0] + p)]
    return [z.real for z in p]
def charpoly(M):                                  # Faddeev-LeVerrier: det(sI - M), never sees the gain's formula
    n, Mk, cf = len(M), [[0.0] * len(M) for _ in M], [1.0]
    for k in range(1, n + 1):
        Mk = mm(M, [[Mk[i][j] + (cf[-1] if i == j else 0) for j in range(n)] for i in range(n)])
        cf.append(-sum(Mk[i][i] for i in range(n)) / k)
    return cf
def roots(cf):                                    # Durand-Kerner: all roots of a polynomial at once
    n, z = len(cf) - 1, [(0.4 + 0.9j) ** k for k in range(len(cf) - 1)]
    for _ in range(500):
        for i in range(n):
            num = sum(a * z[i] ** (n - k) for k, a in enumerate(cf)); den = 1
            for j in range(n):
                if j != i: den *= z[i] - z[j]
            z[i] -= num / den
    return sorted(z, key=lambda w: (round(w.real, 6), w.imag))
def stable(cf):                                   # Routh's first column all positive
    r0, r1 = cf[0::2], cf[1::2] + [0.0] * (len(cf[0::2]) - len(cf[1::2]))
    while any(abs(v) > 0 for v in r1):
        if r1[0] <= 0 or r0[0] <= 0: return False
        r0, r1 = r1, [r0[i + 1] - r0[0] * r1[i + 1] / r1[0] for i in range(len(r1) - 1)] + [0.0]
    return r0[0] > 0
def ackermann(A, b, target):                      # K = (last row of Ctrb^-1) * target(A), Ctrb = [b, Ab, ...]
    n, cols, v = len(A), [], [[x] for x in b]
    for _ in A: cols.append([r[0] for r in v]); v = mm(A, v)
    M = [cols[j][:] + [float(j == n - 1)] for j in range(n)]          # solve Ctrb^T q = e_n
    for i in range(n):
        piv = max(range(i, n), key=lambda r: abs(M[r][i])); M[i], M[piv] = M[piv], M[i]
        for r in range(n):
            if r != i: f = M[r][i] / M[i][i]; M[r] = [a - f * b2 for a, b2 in zip(M[r], M[i])]
    q, P = [[M[i][n] / M[i][i] for i in range(n)]], [[0.0] * n for _ in A]
    for a in target: P = [[x + a * y for x, y in zip(rp, re)] for rp, re in zip(mm(P, A), eye(n))]
    return mm(q, P)[0]
def hand_K(t):                                    # match s^4 + (k2 - c k4)s^3 + (k1 - 16 - c k3)s^2 - 16k2 s - 16k1
    k1, k2 = -t[4] / 16, -t[3] / 16
    return [k1, k2, (k1 - 16 - t[2]) / c, (k2 - t[1]) / c]
def joined(K, Lg, Cm, l=L0):                      # 8 states: true x, estimate xh; xh' = A xh + B u + L(y - C xh)
    At, Bt = plant(l); LC = mm(Lg, Cm)
    top = [At[i] + [-Bt[i] * K[j] for j in range(4)] for i in range(4)]
    return top + [LC[i] + [A[i][j] - B[i] * K[j] - LC[i][j] for j in range(4)] for i in range(4)]
def simulate(M, z, T, K=None, h=0.001):           # RK4; returns samples every 0.25 s, settling times, peak push
    f = lambda z: [sum(a * b for a, b in zip(r, z)) for r in M]
    out, ts, tp, umax = [], 0.0, 0.0, 0.0
    for i in range(int(round(T / h))):
        if i % 250 == 0: out.append(z[:])
        if abs(z[2]) > 0.001: ts = i * h         # lean outside 2% of the 0.05 rad knock
        if abs(z[0]) > 0.01: tp = i * h          # cart more than 1 cm from home
        if K: umax = max(umax, abs(sum(k * x for k, x in zip(K, z[-4:]))))
        k1 = f(z); k2 = f([a + h / 2 * b for a, b in zip(z, k1)]); k3 = f([a + h / 2 * b for a, b in zip(z, k2)])
        k4 = f([a + h * b for a, b in zip(z, k3)]); z = [a + h / 6 * (b + 2 * d + 2 * e + g) for a, b, d, e, g in zip(z, k1, k2, k3, k4)]
    return out, ts, tp, umax, z
def show(name, v, d=3): print(f"{name:<38}" + "  ".join(f"{x:9.{d}f}" for x in v))
def cl(K, Ap=A, Bp=B): return [[Ap[i][j] - Bp[i] * K[j] for j in range(4)] for i in range(4)]
def blocks(t_cart, t_pend):                       # observer by duality: Ackermann on (A^T, C^T), transposed back
    lc = ackermann(tr([[0.0, 1], [0, 0]]), [1.0, 0], poly(t_cart))
    lp = ackermann(tr([[0.0, 1], [16, 0]]), [1.0, 0], poly(t_pend))
    return [[lc[0], 0], [lc[1], 0], [0, lp[0]], [0, lp[1]]]
C2 = [[1.0, 0, 0, 0], [0, 0, 1.0, 0]]            # two readings: cart position (motor count), lean (pivot encoder)

# ---- road 1 and 2: the gain by matching coefficients and by Ackermann's formula ----
ctrl = [-3 + 3j, -3 - 3j, -6 + 6j, -6 - 6j]; obs = [-10, -10]
target = poly(ctrl); K = hand_K(target); K_ack = ackermann(A, B, target)
show("model rod l m, c 1/m, knock deg", [L0, c, 0.05 * 180 / 3.141592653589793], 6)
show("hand: k1 - 16 - a2, k2 - a3", [K[0] - 16 - target[2], K[1] - target[1]], 4)
show("target polynomial s^4..s^0", target, 4); show("K by matching coefficients", K); show("K by Ackermann", K_ack)
show("charpoly of A - BK", charpoly(cl(K)), 4)
for z in roots(charpoly(cl(K))): print(f"  closed-loop pole  {z.real:8.4f} {z.imag:+8.4f}j")
k2s = [(16 + 16) * L0, 8 * L0]                     # rod alone, poles -4, -4: u = l (32 theta + 8 w)
show("rod alone, poles -4,-4: l*32, l*8", k2s, 4)
# ---- the observer, by duality, and by hand: cart s^2 + l1 s + l2, rod s^2 + l1 s + (l2 - 16) ----
Lg = blocks(obs, obs); show("L, cart rows", [Lg[0][0], Lg[1][0]], 4); show("L, rod rows", [Lg[2][1], Lg[3][1]], 4)
ho = poly(obs); hand_L = [ho[1], ho[2], ho[1], ho[2] + 16]; show("L by hand: cart l1 l2, rod l1 l2", hand_L, 4)
show("charpoly of A - LC", charpoly([[A[i][j] - mm(Lg, C2)[i][j] for j in range(4)] for i in range(4)]), 4)
# ---- road 3: separation, the joined loop's polynomial is the product of the two ----
J8 = joined(K, Lg, C2); prod = poly(ctrl + obs * 2)
show("joined charpoly, s^8..s^4", charpoly(J8)[:5], 2); show("joined charpoly, s^3..s^0", charpoly(J8)[5:], 2)
show("controller x observer, s^8..s^4", prod[:5], 2); show("controller x observer, s^3..s^0", prod[5:], 2)
# ---- road 4: simulate; knock of 0.05 rad, estimate starts at zero ----
x0 = [0.0, 0, 0.05, 0]
sf, tsf, tpf, uf, _ = simulate(cl(K), x0, 4.0, K)
sj, tsj, tpj, uj, _ = simulate(J8, x0 + [0.0] * 4, 4.0, K)
show("state fed back: rod, cart, push", [tsf, tpf, uf]); show("observer in loop: rod, cart, push", [tsj, tpj, uj])
print("chart, t s      " + " ".join(f"{0.25 * i:6.2f}" for i in range(13)))
print("chart, lean mrad" + " ".join(f"{1000 * z[2]:6.1f}" for z in sj[:13]))
print("chart, estimate " + " ".join(f"{1000 * z[6]:6.1f}" for z in sj[:13]))
print("chart, exact x  " + " ".join(f"{1000 * z[2]:6.1f}" for z in sf[:13]))
# ---- what breaks ----
show("sign flipped u = +Kx, poles real", [z.real for z in roots(charpoly(cl([-k for k in K])))])
Kw = ackermann(A, [0.0, 1, 0, c], target); show("designed with +c, real poles", [z.real for z in roots(charpoly(cl(Kw)))])
L1 = [[0.0, 0], [0, 0], [0, Lg[2][1]], [0, Lg[3][1]]]   # angle only: the cart estimate just counts its own pushes
show("angle only: charpoly A - LC", [x if abs(x) > 1e-9 else 0.0 for x in charpoly([[A[i][j] - mm(L1, C2)[i][j] for j in range(4)] for i in range(4)])], 2)
_, _, _, _, zb = simulate(joined(K, L1, C2), [0.0, 0.1, 0, 0] + [0.0] * 4, 10.0)
_, _, _, _, zg = simulate(J8, [0.0, 0.1, 0, 0] + [0.0] * 4, 10.0)
show("cart bumped 0.1 m/s: p, v at 10 s", [zb[0], zb[1], zg[0], zg[1]], 4)
_, tss, tps, us, _ = simulate(joined(K, blocks([-1, -1], [-1, -1]), C2), x0 + [0.0] * 4, 12.0, K)
show("observer poles at -1: rod, cart, push", [tss, tps, us])
# ---- honesty: the real rod is not the model rod ----
def edge(lo, hi):                                 # bisection on the true rod length, model fixed
    for _ in range(60):
        mid = (lo + hi) / 2
        if stable(charpoly(joined(K, Lg, C2, mid))) == stable(charpoly(joined(K, Lg, C2, lo))): lo = mid
        else: hi = mid
    return lo
lmin, lmax = edge(L0, 0.05), edge(L0, 50.0); mr = lambda l: max(z.real for z in roots(charpoly(joined(K, Lg, C2, l))))
_, tsl, tpl, ul, _ = simulate(joined(K, Lg, C2, 1.1 * L0), x0 + [0.0] * 4, 10.0, K)
show("stable for true rod, m: from, to", [lmin, lmax], 4); show("true rod 10% long: rod, cart, push", [tsl, tpl, ul])
# ---- try changing ----
K2 = hand_K(poly([2 * z for z in ctrl])); s2 = simulate(cl(K2), x0, 4.0, K2)
show("try: controller twice as fast", [s2[1], s2[2], s2[3]])
s3 = simulate(joined(K, blocks([-40, -40], [-40, -40]), C2), x0 + [0.0] * 4, 4.0, K)
show("try: observer at -40: rod, cart, push", [s3[1], s3[2], s3[3]]); show("  its L, rod rows", blocks([-40, -40], [-40, -40])[3], 1)
K4 = hand_K(poly([z / 2 for z in ctrl])); s4 = simulate(cl(K4), x0, 8.0, K4)
show("try: controller half as fast", [s4[1], s4[2], s4[3]])
px = lambda z: f"({30 + 25 * (z.real + 11):.0f}, {200 - 25 * z.imag:.0f})"   # SVG: 25 px per 1/s, re -11 at x = 30
print(f"figure, 25 px per 1/s, damping {3 / abs(ctrl[0]):.4f}, open loop 0 0 {A[3][2] ** 0.5:.0f} {-A[3][2] ** 0.5:.0f}; in px: controller "
      + " ".join(px(z) for z in ctrl) + ", observer " + px(complex(obs[0])) + ", open loop " + " ".join(px(complex(r)) for r in (0, 4, -4)))

assert max(abs(a - b) for a, b in zip(K, K_ack)) < 1e-9, "matching coefficients vs Ackermann"
assert max(abs(a - b) for a, b in zip(charpoly(cl(K)), target)) < 1e-8, "Faddeev-LeVerrier finds the chosen poles"
assert max(abs(a - b) / max(1, abs(b)) for a, b in zip(charpoly(J8), prod)) < 1e-9, "separation: product polynomial"
assert max(abs(a - b) for a, b in zip(hand_L, [Lg[0][0], Lg[1][0], Lg[2][1], Lg[3][1]])) < 1e-9, "duality vs hand"
hs = [simulate(M, z, 4.0, K, 0.0005)[1:3] for M, z in ((cl(K), x0), (J8, x0 + [0.0] * 4))]
assert tsj < 2.0 and tpj < 2.0 and tsf < tsj and max(abs(a - b) for a, b in zip(hs[0] + hs[1], (tsf, tpf, tsj, tpj))) < 2e-3, "settles inside 2 s, observer costs time, same at half the step"
assert abs(zb[0] - 0.1 * 10) < 1e-9 and abs(zb[1] - 0.1) < 1e-6 and abs(zg[0]) < 1e-3, "angle-only observer never sees the bump"
assert not stable(charpoly(cl(Kw))) and mr(lmin + 5e-4) < 0 < mr(lmin - 5e-4) and mr(lmax - 5e-4) < 0 < mr(lmax + 5e-4) and tsl < 10, "wrong sign fails; Routh edges match the roots"
print("ALL CHECKS PASS")
