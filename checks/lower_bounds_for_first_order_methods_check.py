# Lower bounds for first-order methods: the check behind the card.  Standard library only.
# The chain quadratic, its minimiser, the best point any gradient-span method can reach,
# and gradient descent, Nesterov, conjugate gradient and 1000 random span methods on it.
import math
L, N, K = 1.0, 21, 10                      # smoothness, coordinates, gradient calls

def grad(x):                               # gradient of the chain: (L/4)(A x - e1)
    n = len(x)
    return [L/4*(2*x[i] - (x[i-1] if i > 0 else 0.0) - (x[i+1] if i < n-1 else 0.0)
                 - (1.0 if i == 0 else 0.0)) for i in range(n)]
def f(x):
    s = x[0]**2 + x[-1]**2 + sum((x[i] - x[i+1])**2 for i in range(len(x) - 1))
    return L/8*s - L/4*x[0]
def solve(m, d, off, rhs):                 # elimination on an m x m tridiagonal system
    c, r = [0.0]*m, [0.0]*m
    for i in range(m):
        piv = d - (off*c[i-1] if i > 0 else 0.0)
        c[i] = off/piv
        r[i] = (rhs[i] - (off*r[i-1] if i > 0 else 0.0))/piv
    for i in range(m - 2, -1, -1):
        r[i] -= c[i]*r[i+1]
    return r
def pad(v): return v + [0.0]*(N - len(v))
def nnz(x): return sum(1 for v in x if abs(v) > 1e-15)
def lg(v): return f"{math.log10(v):.2f}"

xs = [1 - i/(N+1) for i in range(1, N+1)]
fs, R2 = f(xs), sum(v*v for v in xs)
elim = solve(N, 2.0, -1.0, [1.0] + [0.0]*(N-1))
assert max(abs(a - b) for a, b in zip(elim, xs)) < 1e-12
assert abs(fs + L/8*(1 - 1/(N+1))) < 1e-12 and abs(R2 - N*(2*N+1)/(6*(N+1))) < 1e-12
assert R2 <= (N+1)/3
print(f"chain: {N} coordinates, L {L:.0f}, start x0 = 0, {K} gradient calls")
print(f"minimiser x*_i = 1 - i/{N+1}: x*_1 {xs[0]:.6f}, x*_{N} {xs[-1]:.6f}; f* {fs:.6f}")
print(f"start distance R^2 {R2:.6f} (bound (n+1)/3 = {(N+1)/3:.6f}), R {math.sqrt(R2):.6f}")

def cg(steps):                             # conjugate gradient from 0, one product A p per step
    x = [0.0]*N; r = [-g for g in grad(x)]; p = r[:]
    for _ in range(steps):
        Ap = [g + (L/4 if i == 0 else 0.0) for i, g in enumerate(grad(p))]   # (L/4) A p
        rr = sum(u*u for u in r); a = rr/sum(u*v for u, v in zip(p, Ap))
        x = [u + a*v for u, v in zip(x, p)]; r = [u - a*v for u, v in zip(r, Ap)]
        p = [u + sum(w*w for w in r)/rr*v for u, v in zip(r, p)]
    return x
best_cf = -L/8*(1 - 1/(K+1))
best_el = f(pad(solve(K, 2.0, -1.0, [1.0] + [0.0]*(K-1))))
xcg = cg(K)
assert abs(best_cf - best_el) < 1e-12 and abs(best_cf - f(xcg)) < 1e-12 and nnz(xcg) == K
best, floor = (best_cf - fs)/(L*R2), 3/(32*(K+1)**2)
assert best >= floor
print(f"best after {K} calls: closed form {best_cf:.6f}; elimination {best_el:.6f}; conjugate gradient {f(xcg):.6f}")
print(f"gap after {K} calls: {best_cf - fs:.6f}; per unit L R^2: best possible {best:.6f}; floor 3/(32*{K+1}^2) {floor:.6f}")

def runs(a, b, nest):                      # gradient descent, heavy ball or Nesterov, K calls
    x, xp, z, t, sup = [0.0]*N, [0.0]*N, [0.0]*N, 1.0, []
    for _ in range(K):
        g = grad(z if nest else x)
        if nest:
            xn = [u - v/L for u, v in zip(z, g)]; tn = (1 + math.sqrt(1 + 4*t*t))/2
            z = [u + (t - 1)/tn*(u - v) for u, v in zip(xn, x)]; t = tn
        else:
            xn = [u - a*v/L + b*(u - w) for u, v, w in zip(x, g, xp)]
        xp, x = x, xn; sup.append(nnz(x))
    return (f(x) - fs)/(L*R2), sup
gd, sgd = runs(1.0, 0.0, False)
ne, sne = runs(1.0, 0.0, True)
assert sgd == sne == list(range(1, K+1))
assert best <= ne < gd <= 1/(2*K) and ne <= 2/(K+1)**2
print(f"nonzero coordinates after calls 1..{K}: gd {sgd}; nesterov {sne}")
print(f"gap per unit L R^2 after {K} calls: gd {gd:.6f} (guarantee {1/(2*K):.6f}); nesterov {ne:.6f} (guarantee {2/(K+1)**2:.6f})")

s = 2026                                   # SplitMix64, seed 2026
def rnd():
    global s
    s = (s + 0x9E3779B97F4A7C15) & (2**64 - 1); z = s
    z = ((z ^ (z >> 30))*0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27))*0x94D049BB133111EB) & (2**64 - 1)
    return ((z ^ (z >> 31)) >> 11)/2**53
low = min(runs(0.2 + 1.6*rnd(), 0.9*rnd(), False)[0] for _ in range(1000))
assert low >= best
print(f"1000 random heavy-ball methods (step 0.2..1.8, momentum 0..0.9): smallest gap {low:.6f}")

def calls(bound, eps):
    k = 1
    while bound(k) > eps: k += 1
    return k
for eps, lab in ((1e-4, "0.0001"), (1e-6, "0.000001")):
    c = [calls(lambda k: 3/(32*(k+1)**2), eps), calls(lambda k: 2/(k+1)**2, eps), calls(lambda k: 1/(2*k), eps)]
    assert c[0] < c[1] < c[2] and 2*c[0] + 1 <= 2000
    print(f"calls to promise a gap <= {lab} L R^2: floor {c[0]}, nesterov {c[1]}, gd {c[2]}")
ks = [1, 2, 4, 8, 16, 32, 64, 128]
print("chart k", *ks)
print("chart log10, gd guarantee      ", *[lg(1/(2*k)) for k in ks])
print("chart log10, nesterov guarantee", *[lg(2/(k+1)**2) for k in ks])
print("chart log10, floor             ", *[lg(3/(32*(k+1)**2)) for k in ks], "; nesterov - floor", lg(64/3))

for kap in (100.0, 10000.0):               # strongly convex chain, n = 2000, mu = L/kappa
    mu, m = L/kap, 2000; c = (L - mu)/4; q = (math.sqrt(kap) - 1)/(math.sqrt(kap) + 1)
    xst = solve(m, 2*c + mu, -c, [c] + [0.0]*(m-1)); r2 = sum(v*v for v in xst)
    gap = c/2*(xst[0] - solve(K, 2*c + mu, -c, [c] + [0.0]*(K-1))[0])
    lb = mu/2*q**(2*K)*r2
    assert gap >= lb and abs(xst[4] - q**5) < 1e-9
    d = [math.log(10)/(-2*math.log(q)), math.log(10)/(-math.log(1 - 1/math.sqrt(kap))), math.log(10)/(-math.log(1 - 1/kap))]
    print(f"strongly convex chain, kappa {kap:.0f}: x*_5 {xst[4]:.6f} = q^5 {q**5:.6f}; best gap after {K} calls {gap:.3e} >= floor {lb:.3e}")
    print(f"  calls per tenfold cut: floor {d[0]:.2f}, nesterov {d[1]:.2f}, gd {d[2]:.2f}")

t, R, G = 10, 1.0, 1.0                     # nonsmooth: b max_{i<=t} x_i + (a/2)|x|^2
a, b = (G/R)/(1 + math.sqrt(t)), G*math.sqrt(t)/(1 + math.sqrt(t))
fn = lambda x: b*max(x[:t]) + a/2*sum(v*v for v in x)
fmin = -b**2/(2*a*t)
scan = min(b*c + a*t*c*c/2 for c in [-j*1e-6 for j in range(500001)])
x, fb = [0.0]*t, math.inf
for _ in range(t):                         # subgradient method, step R/(G sqrt t)
    fb = min(fb, fn(x)); i = x.index(max(x))
    x = [v - R/(G*math.sqrt(t))*(a*v + (b if j == i else 0.0)) for j, v in enumerate(x)]
assert abs(scan - fmin) < 1e-9 and fb >= 0 and abs(-fmin - R*G/(2*(1 + math.sqrt(t)))) < 1e-12
print(f"nonsmooth, t {t}, R 1, G 1: weights a {a:.4f}, b {b:.4f}; min {fmin:.6f} (scan {scan:.6f}); best of {t} queried points {fb:.6f}")
print(f"  floor RG/(2(1+sqrt t)) {-fmin:.6f}; subgradient guarantee RG/sqrt t {R*G/math.sqrt(t):.6f}")

print("figure, x*        ", " ".join(f"{v:.3f}" for v in xs))
print("figure, 10 calls  ", " ".join(f"{v:.3f}" for v in pad(solve(K, 2.0, -1.0, [1.0] + [0.0]*(K-1)))))
x0 = [0.0]*N                               # one Newton step x0 - H^-1 grad f(x0), H = (L/4) A
xn = [u - v for u, v in zip(x0, solve(N, L/2, -L/4, grad(x0)))]
g21 = abs(f(cg(N)) - fs)/(L*R2); newton = abs(f(xn) - fs)
def bowl(x): return L/2*sum((u - v)**2 for u, v in zip(x, xs))   # the round bowl (L/2)|x - x*|^2
def gbowl(x): return [L*(u - v) for u, v in zip(x, xs)]           # and its gradient
xr = [u - g/L for u, g in zip(x0, gbowl(x0))]; round_gap = bowl(xr)   # one gradient step 1/L
assert g21 < 1e-12 and newton < 1e-12 and round_gap < 1e-15
print(f"breaks: {N} calls on {N} coordinates: cg gap {g21:.6f}, below the floor {3/(32*(N+1)**2):.6f}")
print(f"breaks: one Newton step (a Hessian solve, outside the span): gap {newton:.6f}")
print(f"breaks: round bowl (L/2)|x - x*|^2: gd lands on x* in 1 call, gap {round_gap:.6f}")
for k in (20, 40):
    r2 = sum((1 - i/(2*k + 2))**2 for i in range(1, 2*k + 2))
    print(f"try: k {k}, chain of {2*k+1}: best possible {1/(16*(k+1)*r2):.6f}, floor {3/(32*(k+1)**2):.6f}")
print("ALL CHECKS PASS")
