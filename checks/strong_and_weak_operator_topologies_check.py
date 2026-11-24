# Operator topologies: the check behind the card.  Standard library only.
# The delay S (one sample later) and the advance S* (drop the first sample),
# its adjoint, on lists of samples.  The finite rehearsal is the clip
# (3, 1, 4, 1, 5); the infinite case is the fading tail u_k = 1/k, held to
# K terms plus its remainder.  Roads: tail sums against pi^2/6 minus partial
# sums; lag readings summed directly against H_n / n; Cauchy-Schwarz bounds;
# cut matrices against the endless list; exact integer probes for the net;
# switched-off copies against Goldstine's all-ones limit.
import math

def dot(a, b): return sum(x * y for x, y in zip(a, b))
def delay(u, n): return [0.0] * n + list(u)          # S^n on the endless list
def advance(u, n): return list(u[n:])                 # S*^n: drop n samples
def cut_adv(v, n): return (v[n:] + [0.0] * len(v))[:len(v)]   # S*^n cut to N
def cut_del(v, n): return ([0.0] * n + v)[:len(v)]            # S^n cut to N
def opnorm(f, ft, N):                                 # power iteration on f^T f
    x = [1.0 + 0.1 * i for i in range(N)]
    for _ in range(60):
        y = ft(f(x)); s = math.sqrt(dot(y, y))
        if s == 0.0: return 0.0
        x = [v / s for v in y]
    return math.sqrt(dot(f(x), f(x)))

print("1. the clip u = (3, 1, 4, 1, 5) on the endless list")
u = [3.0, 1.0, 4.0, 1.0, 5.0]
adv = [dot(advance(u, n), advance(u, n)) for n in range(6)]
dl = [dot(delay(u, n), delay(u, n)) for n in range(6)]
lag = [dot(u, delay(u, n)) for n in range(6)]
print("   n             " + " ".join(f"{n:4d}" for n in range(6)))
print("   energy S*^n u " + " ".join(f"{v:4.0f}" for v in adv))
print("   energy S^n u  " + " ".join(f"{v:4.0f}" for v in dl))
print("   <u, S^n u>    " + " ".join(f"{v:4.0f}" for v in lag))
assert adv == [52, 43, 42, 26, 25, 0] and dl == [52] * 6
assert lag == [dot(advance(u, n), u) for n in range(6)]          # <u, S^n u> = <S*^n u, u>
far = [math.sqrt(sum((a - b) ** 2 for a, b in zip(delay(u, n) + [0.0] * n, delay(u, 2 * n)))) for n in (5, 50)]
print(f"   |S^n u - S^2n u| at n = 5, 50: {far[0]:.4f} {far[1]:.4f}; sqrt(2 x 52) = {math.sqrt(104):.4f}")
assert all(abs(d - math.sqrt(104)) < 1e-12 for d in far)
wit = [advance([0.0] * n + [1.0], n) for n in (1, 10, 1000)]
print(f"   S*^n e_(n+1) = e_1 at n = 1, 10, 1000: {all(w == [1.0] for w in wit)}, so |S*^n| = 1")
assert all(w == [1.0] for w in wit)                               # the click past the cut survives
g = [opnorm(lambda v, n=n: cut_adv(v, n), lambda v, n=n: cut_del(v, n), 5) for n in range(1, 7)]
print("   cut to N = 5: |S*^n|, n = 1..6: " + " ".join(f"{v:.4f}" for v in g))
assert all(abs(v - 1) < 1e-9 for v in g[:4]) and g[4] == g[5] == 0.0
back = all(advance(delay(u, n), n) == u for n in (1, 10, 1000))
print(f"   S*^n S^n u = u at n = 1, 10, 1000: {back}, energy 52 at every n")
assert back                                                       # advance after delay gives u back

print("2. the fading tail u_k = 1/k, K = 200000 terms plus remainder")
K = 200000
Z = math.pi ** 2 / 6
def rem(K): return 1 / K - 1 / (2 * K * K) + 1 / (6 * K ** 3)    # Euler-Maclaurin estimate of sum of 1/k^2 past K
NS = (1, 2, 5, 10, 20, 50, 100, 200, 500, 1000)
print(f"   |u| = pi/sqrt(6) = {math.sqrt(Z):.6f}")
print("      n  |S*^n u|  |S^n u|  <u,S^n u>  bound |S*^n u||u|")
st, wk, ls = [], [], []
tail = [1 / k for k in range(1, K + 1)]                          # the tail u, K terms
for n in NS:
    direct = sum(1 / (k * k) for k in range(n + 1, K + 1)) + rem(K)
    viaz = Z - sum(1 / (k * k) for k in range(1, n + 1))
    assert abs(direct - viaz) < 1e-12                                # road 1: two tail sums
    lagd = sum(1 / (k * (k + n)) for k in range(1, K + 1))
    hn = sum(1 / k for k in range(1, n + 1)) / n
    assert 0 < hn - lagd < 1.0 / K                                   # road 2: H_n / n
    s = math.sqrt(viaz)
    assert hn <= s * math.sqrt(Z)                                    # road 3: Cauchy-Schwarz
    d = delay(tail, n); ln = math.sqrt(dot(d, d) + rem(K))           # |S^n u|, measured on the delayed list
    assert abs(ln - math.sqrt(Z)) < 1e-12                            # the delay keeps the length pi/sqrt(6)
    st.append(s); wk.append(hn); ls.append(ln)
    print(f"   {n:4d}  {s:.6f}  {ln:.6f}  {hn:.6f}   {s * math.sqrt(Z):.6f}")
assert all(abs(s * math.sqrt(n) - 1) < 0.6 for s, n in zip(st, NS))   # tail like 1/sqrt(n)
print("   chart n         " + " ".join(f"{n:5d}" for n in NS))
print("   chart strong    " + " ".join(f"{v:.3f}" for v in st))
print("   chart length    " + " ".join(f"{v:.3f}" for v in ls))
print("   chart weak      " + " ".join(f"{v:.3f}" for v in wk))

print("3. a net with no sequence: T_mn v = v_1 (e_m + m e_n), probed by w = u = (1/k)")
for q in (10, 100, 1000):                                            # eps = 1/q
    m = 2 * q + 1; n = 2 * m * q + 1                                 # 1/m < eps/2, m/n < eps/2
    num, den = n + m * m, m * n                                      # 1/m + m/n, exactly
    assert num * q < den                                             # reading below eps
    print(f"   eps 1/{q:<4d}: m {m:5d}, n {n:8d}, reading {num * q / den:.5f} x eps, |T_mn| = {math.sqrt(1 + m * m):.3f}")

print("4. Goldstine: x_n = (1, .., 1, 0, ..) in the ball of c0, read by y in l1")
print("      n  sum 2^-k  sum 1/k^2  sup-distance to all-ones")
for n in (1, 2, 5, 10, 100, 1000):
    r1 = sum(2.0 ** -k for k in range(1, n + 1)); r2 = sum(1 / (k * k) for k in range(1, n + 1))
    assert abs(r1 - (1 - 2.0 ** -n)) < 1e-15 and abs((Z - r2) - (1 / n - 1 / (2 * n * n))) < 0.2 / n ** 3
    print(f"   {n:4d}  {r1:.6f}  {r2:.6f}   1")
print(f"   limits: 1.000000 and pi^2/6 = {Z:.6f}; all-ones is in l-infinity, not in c0")

print("5. what breaks")
b9 = advance(delay(u, 9), 9); energy9 = dot(b9, b9)
print(f"   strong limit 0 taken as norm limit: |S*^1000| = {opnorm(lambda v: cut_adv(v, 1000), lambda v: cut_del(v, 1000), 1001):.4f}, not 0")
print(f"   weak limit 0 taken as strong limit: |S^1000 u| = {ls[-1]:.4f}, not 0")
print(f"   limit of the product as product of limits: S*^9 S^9 u has energy {energy9:.0f}, not 0")
assert b9 == u and energy9 == 52                                  # weak limits do not multiply
print(f"   cut matrix trusted: N = 5 gives |S*^5| = {g[4]:.0f}; the endless list gives 1")

print("ALL CHECKS PASS")
