# Sequential quadratic programming -- the check behind the card.  Standard library only.
# Three pumps.  Choose their powers p_i (kW) to MINIMISE total power f(p) = p1 + p2 + p3,
# subject to: demand, flow Q(p) = sum sqrt(p_i / a_i) = 150 L/s, and head H(p) = sum k_i sqrt(p_i / a_i) >= 35 m,
# held as an equality.  Written c(p) = (150 - Q, 35 - H): c_1 = 0, c_2 <= 0, prices mu = (nu, lam).
# Road 1: SQP, each step a quadratic model solved through its KKT linear system, guarded by an l1 merit function.
# Road 2: the same problem in flows, where it is a convex quadratic with straight rules: one linear solve.
# Road 3: a scan of every feasible plan on a 0.1 L/s grid of flows: demand met, head at least 35 m.
import math
A, K, DEM, HEAD, RHO = [0.02, 0.03, 0.05], [0.1, 0.2, 0.4], 150.0, 35.0, 20.0

def gauss(M, r):                         # solve M z = r by elimination with row swaps
    n = len(r)
    M = [list(row) + [v] for row, v in zip(M, r)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(M[i][c]))
        if abs(M[p][c]) < 1e-12:
            return None                  # singular: no unique solution
        M[c], M[p] = M[p], M[c]
        for i in range(n):
            if i != c:
                m = M[i][c] / M[c][c]
                M[i] = [u - m * v for u, v in zip(M[i], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

flows = lambda p: [math.sqrt(pi / ai) for pi, ai in zip(p, A)]
miss = lambda p: [DEM - sum(flows(p)), HEAD - sum(k * q for k, q in zip(K, flows(p)))]
jac = lambda p: [[-q / (2 * pi) for q, pi in zip(flows(p), p)], [-k * q / (2 * pi) for k, q, pi in zip(K, flows(p), p)]]
hdiag = lambda p, mu: [(mu[0] + mu[1] * k) * q / (4 * pi * pi) for k, q, pi in zip(K, flows(p), p)]  # Hessian of L
viol = lambda p: abs(miss(p)[0]) + max(0.0, miss(p)[1])
merit = lambda p, rho=RHO: sum(p) + rho * viol(p)
f4 = lambda v: ", ".join(f"{round(u, 9) + 0.0:.4f}" for u in v)   # + 0.0 turns -0 into 0
dist = lambda u, v: math.sqrt(sum((x - y) ** 2 for x, y in zip(u, v)))

def kkt(p, mu, h=None):        # [B J^T; J 0] [d; mu+] = [-grad f; -c], solved in one 5 x 5 system
    J, h = jac(p), hdiag(p, mu) if h is None else h
    M = [[h[i] if j == i else 0 for j in range(3)] + [J[0][i], J[1][i]] for i in range(3)] + [J[0] + [0, 0], J[1] + [0, 0]]
    z = gauss(M, [-1, -1, -1] + [-v for v in miss(p)])
    return None if z is None else (z[:3], z[3:])

def ls_prices(p):                        # least-squares prices: make grad f + J^T mu as small as possible
    J = jac(p)
    return gauss([[sum(J[i][t] * J[j][t] for t in range(3)) for j in range(2)] for i in range(2)], [-sum(J[i]) for i in range(2)])

def sqp(p, mu, steps, soc=True, rho=RHO):
    hist = [(p, mu, 1.0, "start")]
    for _ in range(steps):
        d, mu1 = kkt(p, mu)
        slope, a, tag = sum(d) - rho * viol(p), 1.0, "full"
        while True:
            x = [pi + a * di for pi, di in zip(p, d)]
            if min(x) > 0 and merit(x, rho) <= merit(p, rho) + 1e-4 * a * slope:
                break
            if a == 1.0 and soc and min(x) > 0:      # second-order correction: shortest move that re-meets the rules
                J, cx = jac(p), miss(x)
                w = gauss([[sum(J[i][t] * J[j][t] for t in range(3)) for j in range(2)] for i in range(2)], [-v for v in cx])
                y = [x[t] + J[0][t] * w[0] + J[1][t] * w[1] for t in range(3)]
                if min(y) > 0 and merit(y, rho) <= merit(p, rho) + 1e-4 * slope:
                    x, tag = y, "corrected"
                    break
            a /= 2
        p, mu = x, mu1
        hist.append((p, mu, a, tag))
    return hist

# ---- road 2: in flows the problem is Lagrange's: 2 a_i q_i = nu + lam k_i, sum q = 150, k.q = head ----
flowform = lambda hd: gauss([[2 * A[i] if j == i else 0 for j in range(3)] + [-1, -K[i]] for i in range(3)] + [[1, 1, 1, 0, 0], K + [0, 0]], [0, 0, 0, DEM, hd])
z = flowform(HEAD)
PS = [A[i] * z[i] ** 2 for i in range(3)]
print(f"road 2, flow form: flows {f4(z[:3])} L/s, powers {f4(PS)} kW, total {sum(PS):.4f} kW, nu {z[3]:.4f}, lam {z[4]:.4f}")

# ---- road 1: SQP from 100 kW on every pump ----
p0 = [100.0, 100.0, 100.0]
mu0 = ls_prices(p0)
J0, h0, c0 = jac(p0), hdiag(p0, mu0), miss(p0)
print(f"start: flows {f4(flows(p0))} L/s, total {sum(flows(p0)):.4f} L/s, head {HEAD - c0[1]:.4f} m, misses {f4(c0)}")
print(f"start: demand row {f4(J0[0])}; head row {f4(J0[1])}; prices mu0 {f4(mu0)}; curvature {f4(h0)}")
S = [[sum(J0[j][i] * J0[l][i] / h0[i] for i in range(3)) for l in range(2)] for j in range(2)]
R = [c0[j] - sum(J0[j][i] / h0[i] for i in range(3)) for j in range(2)]
mh = gauss(S, R)                         # by hand: eliminate d, leaving 2 equations in the 2 new prices
dh = [-(1 + J0[0][i] * mh[0] + J0[1][i] * mh[1]) / h0[i] for i in range(3)]
print(f"by hand: [{f4(S[0])}; {f4(S[1])}] mu = ({f4(R)}); mu1 {f4(mh)}; step d {f4(dh)} kW")
H = sqp(p0, mu0, 4)
assert dist(dh, [H[1][0][i] - p0[i] for i in range(3)]) < 1e-9 and dist(mh, H[1][1]) < 1e-9
err = [dist(p, PS) for p, *_ in H]
print("k | powers (kW) | total kW | demand miss L/s | head miss m | prices | step | merit | error kW")
for k, (p, mu, a, tag) in enumerate(H):
    print(f"{k} | {f4(p)} | {sum(p):.4f} | {miss(p)[0]:.6f} | {miss(p)[1]:.6f} | {f4(mu)} | {f'{a:g} {tag}' if k else tag} | {merit(p):.4f} | {err[k]:.3e}")
print("error ratios e(k+1)/e(k)^2:", " ".join(f"{err[k + 1] / err[k] ** 2:.4f}" for k in range(4)))
print("chart, log10 error at k = 0..4:", " ".join(f"{math.log10(e):.2f}" for e in err[:5]))
first = next(k for k, (p, *_) in enumerate(H) if max(abs(v) for v in miss(p)) < 1e-3)
p, mu = H[4][0], H[4][1]
gl = [1 + jac(p)[0][i] * mu[0] + jac(p)[1][i] * mu[1] for i in range(3)]
u = [K[2] - K[1], K[0] - K[2], K[1] - K[0]]                     # flow changes keeping both rules: (1,1,1) x k
z = [-u[i] / jac(p)[0][i] for i in range(3)]                     # the same move in powers: J z = 0
curv = sum(hdiag(p, mu)[i] * z[i] ** 2 for i in range(3)) / sum(v * v for v in z)
print(f"feasible to 0.001 after {first} steps; step 4: KKT residual {max(abs(v) for v in gl):.1e}, head price {mu[1]:.4f} > 0, curvature on allowed step {curv:.6f}")
assert first == 3 and max(abs(v) for v in gl) < 1e-6 and mu[1] > 0 and curv > 0 and dist(p, PS) < 1e-6
assert all(err[k + 1] < 0.02 * err[k] ** 2 for k in range(3)) and all(merit(H[k + 1][0]) < merit(H[k][0]) for k in range(3))
nd = max(abs((miss([p[t] + 1e-5 * (t == i) for t in range(3)])[j] - miss([p[t] - 1e-5 * (t == i) for t in range(3)])[j]) / 2e-5 - jac(p)[j][i]) for i in range(3) for j in range(2))
print(f"rule gradients against central differences: largest gap {nd:.1e}")
assert nd < 1e-6

# ---- road 3: every plan on a 0.1 L/s grid of flows that meets demand with at least 35 m of head ----
best, n = (1e9, 0, 0), 0
for n1 in range(1501):
    for n2 in range(1501 - n1):
        q = (n1 / 10, n2 / 10, DEM - n1 / 10 - n2 / 10)
        if sum(k * v for k, v in zip(K, q)) >= HEAD - 1e-9:   # the head rule as a floor: no binding assumed
            n, best = n + 1, min(best, (sum(a * v * v for a, v in zip(A, q)), n1, n2))
print(f"road 3, scan of {n} feasible plans: lowest {best[0]:.4f} kW at flows {f4([best[1] / 10, best[2] / 10, DEM - best[1] / 10 - best[2] / 10])} L/s; SQP total {sum(p):.4f} kW")
assert abs(best[0] - sum(p)) < 1e-6 and abs(sum(p) - sum(PS)) < 1e-6

# ---- what breaks ----
print("model with f's own Hessian (zero):", "singular" if kkt(p0, mu0, h=[0, 0, 0]) is None else "solvable")
assert kkt(p0, [0.0, 0.0]) is None and kkt(p0, mu0, h=[0, 0, 0]) is None
far = [300.0, 300.0, 300.0]
d, _ = kkt(far, ls_prices(far))
G = sqp(far, ls_prices(far), 6)
print(f"from 300 kW each, unguarded full step lands at {f4([far[i] + d[i] for i in range(3)])} kW; guarded steps {' '.join(f'{g[2]:g}' for g in G[1:])}, error {'below' if dist(G[-1][0], PS) < 1e-6 else 'ABOVE'} 1e-6")
assert min(far[i] + d[i] for i in range(3)) < 0 and dist(G[-1][0], PS) < 1e-6
assert miss(far)[1] < 0 and abs(merit(far) - sum(far) - RHO * abs(miss(far)[0])) < 1e-9   # head slack there: no fine for it
pen = lambda r: gauss([[2 * A[i] if j == i else 0 for j in range(3)] + [-1] for i in range(3)] + [[1, 1, 1, 0]], [r * k for k in K] + [DEM])
power = lambda q: sum(a * x * x for a, x in zip(A, q))   # in flows: head priced at r per m, demand held
w, w0, L = pen(5.0), pen(0.0), flowform(25.0)
pw = [A[i] * w[i] ** 2 for i in range(3)]
print(f"penalty weight 5 < head price 10: merit lowest at head {sum(k * q for k, q in zip(K, w)):.4f} m, merit {merit(pw, 5):.4f} < {merit(PS, 5):.4f} kW")
print(f"head limit 25 m held as equality: head price {L[4]:.4f} kW per m, total {power(L[:3]):.4f} kW; rule dropped {power(w0[:3]):.4f} kW at {sum(k * q for k, q in zip(K, w0)):.4f} m")
assert merit(pw, 5) < merit(PS, 5) - 1 and viol(pw) > 1 and L[4] < 0 and power(L[:3]) > power(w0[:3])
pf = [A[i] * q * q for i, q in enumerate((54.0, 44.0, 52.0))]   # a feasible plan near the answer
d, _ = kkt(pf, [1.0, 10.0])
pd = [pf[i] + d[i] for i in range(3)]
print(f"Maratos: start {f4(pf)} kW, misses {f4(miss(pf))}; full step total {sum(pf):.4f} -> {sum(pd):.4f} kW, violation 0 -> {viol(pd):.4f}")
print(f"Maratos: merit {merit(pf):.4f} -> {merit(pd):.4f} kW, rejected; error {dist(pf, PS):.4f} -> {dist(pd, PS):.4f}")
N, C = sqp(pf, [1.0, 10.0], 4, soc=False), sqp(pf, [1.0, 10.0], 4)
print(f"Maratos, no correction: steps {' '.join(f'{g[2]:g}' for g in N[1:])}, error after 4 {dist(N[-1][0], PS):.4f}")
print(f"Maratos, with correction: steps {' '.join(f'{g[2]:g} {g[3]}' for g in C[1:])}, error after 4 {'below' if dist(C[-1][0], PS) < 1e-6 else 'ABOVE'} 1e-6")
assert merit(pd) > merit(pf) and dist(pd, PS) < 0.15 * dist(pf, PS) and dist(N[-1][0], PS) > 1 and dist(C[-1][0], PS) < 1e-6
print("ALL CHECKS PASS")
