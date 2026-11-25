# Andre-Oort and o-minimality -- the check behind the card.  Standard library only.
# Five parts, each by two roads: (1) j = E4^3/Delta as an exact q-series, against
# 1728 + E6^2/Delta; (2) j at CM points from the series, against exact integers, with
# class numbers counted from reduced forms; (3) the level-2 modular polynomial, exactly
# at special pairs and numerically at tau = 1.1i; (4) class numbers by forms
# against Dirichlet's sum, and CM-point heights; (5) rational points of bounded height.
import math
def sigma(k, n): return sum(d ** k for d in range(1, n + 1) if n % d == 0)
def sci(v):                                   # 12 significant digits, same in Rust
    s, e, v = "-" if v < 0 else "", 0, abs(v)
    while v >= 10: v, e = v / 10, e + 1
    while v < 1: v, e = v * 10, e - 1
    return f"{s}{v:.11f}e{e}"
M = 12                                        # exact series to q^M
def mul(a, b): return [sum(a[i] * b[n - i] for i in range(n + 1)) for n in range(M + 1)]
E4 = [1] + [240 * sigma(3, n) for n in range(1, M + 1)]
E6 = [1] + [-504 * sigma(5, n) for n in range(1, M + 1)]
P = [1] + [0] * M                             # 1 / prod (1 - q^n)^24, so Delta = q / P
for n in range(1, M + 1):
    g = [1 if k % n == 0 else 0 for k in range(M + 1)]   # 1 / (1 - q^n)
    for _ in range(24): P = mul(P, g)
J = mul(mul(mul(E4, E4), E4), P)             # J[k] is the coefficient of q^(k-1) in j
J2 = mul(mul(E6, E6), P); J2[1] += 1728       # road 2: j = 1728 + E6^2 / Delta
print("j = 1/q +", " + ".join(f"{c} q^{k - 1}" for k, c in enumerate(J[1:7], 1)).replace(" q^0", "").replace("q^1 ", "q "), "+ ...")
assert J == J2 and J[0] == 1
N = 40                                        # numeric series to q^N
def cm(a, b): return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])
def cdiv(a, b):
    d = b[0] * b[0] + b[1] * b[1]
    return ((a[0] * b[0] + a[1] * b[1]) / d, (a[1] * b[0] - a[0] * b[1]) / d)
def ev(x, y):                                 # E4, E6, Delta at tau = x + iy
    r = math.exp(-2 * math.pi * y)
    q = (r * math.cos(2 * math.pi * x), r * math.sin(2 * math.pi * x))
    e4, e6, pr, qn = (1.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 0.0)
    for n in range(1, N + 1):
        qn = cm(qn, q)
        e4 = (e4[0] + 240 * sigma(3, n) * qn[0], e4[1] + 240 * sigma(3, n) * qn[1])
        e6 = (e6[0] - 504 * sigma(5, n) * qn[0], e6[1] - 504 * sigma(5, n) * qn[1])
        f = (1 - qn[0], -qn[1])
        for _ in range(24): pr = cm(pr, f)
    return e4, e6, cm(q, pr)
def jval(x, y):
    e4, e6, d = ev(x, y)
    return cdiv(cm(cm(e4, e4), e4), d), cdiv(cm(e6, e6), d)
qi = math.exp(-2 * math.pi)
part, s = [], 1 / qi
for k in range(7):
    if k: s += J[k] * qi ** (k - 1)
    part.append(s)
print(f"tau = i: q = {qi:.8f}; partial sums", " ".join(f"{v:.4f}" for v in part))
e4i, e6i, _ = ev(0.0, 1.0); e4r, e6r, _ = ev(-0.5, math.sqrt(3) / 2)
print(f"|E6(i)| < 1e-12: {abs(e6i[0]) + abs(e6i[1]) < 1e-12}; |E4(rho)| < 1e-12: {abs(e4r[0]) + abs(e4r[1]) < 1e-12}")
assert abs(part[-1] - 1728) < 0.01 and abs(e6i[0]) + abs(e6i[1]) < 1e-12 and abs(e4r[0]) + abs(e4r[1]) < 1e-12
def forms(D):                                 # primitive reduced forms of discriminant D
    out, a = [], 1
    while 3 * a * a <= -D:
        for b in range(-a + 1, a + 1):
            if (b * b - D) % (4 * a): continue
            c = (b * b - D) // (4 * a)
            if c >= a and not (c == a and b < 0) and math.gcd(math.gcd(a, b), c) == 1: out.append((a, b, c))
        a += 1
    return out
JX = {-3: 0, -4: 1728, -7: -3375, -8: 8000, -11: -32768, -12: 54000, -16: 287496, -19: -884736,
      -27: -12288000, -28: 16581375, -43: -884736000, -67: -147197952000, -163: -262537412640768000}
print("    D  h               exact j(tau_D)   from the series")
for D, jx in JX.items():
    (a, b, c), = forms(D)
    (jr, ji), (kr, _) = jval(-b / (2 * a), math.sqrt(-D) / (2 * a))
    print(f"{D:>5}  1 {jx:>24}   {sci(jr) if abs(jr) > 1e-6 else 'below 1e-6'}")
    assert abs(jr - jx) <= 1e-9 * max(1, abs(jx)) and abs(ji) <= 1e-9 * max(1, abs(jx)) and abs(kr + 1728 - jr) <= 1e-9 * max(1, abs(jx))
one = [D for D in range(-3, -2001, -1) if D % 4 in (0, 1) and len(forms(D)) == 1]
print(f"class number 1 for -2000 <= D <= -3: {len(one)} discriminants, the 13 above: {one == list(JX)}")
assert one == list(JX)
j15 = [jval(-b / (2 * a), math.sqrt(15) / (2 * a))[0] for a, b, c in forms(-15)]
print(f"D = -15, forms {forms(-15)}: j = {j15[0][0]:.4f}, {j15[1][0]:.4f}; sum {j15[0][0] + j15[1][0]:.3f}, product {j15[0][0] * j15[1][0]:.1f}")
assert abs(j15[0][0] + j15[1][0] + 191025) < 1e-3 and abs(j15[0][0] * j15[1][0] + 121287375) < 1
def phi2(X, Y): return [X**3, Y**3, -X*X*Y*Y, 1488*X*X*Y, 1488*X*Y*Y, -162000*X*X, -162000*Y*Y,
                        40773375*X*Y, 8748000000*X, 8748000000*Y, -157464000000000]
x0, y0 = 0.0, 1.1                             # road 2 for the coefficients: Phi_2 vanishes at every tau
ja, jb = jval(x0, y0)[0][0], jval(2 * x0, 2 * y0)[0][0]
t = phi2(ja, jb)
print(f"tau = 1.1i: j(tau) = {sci(ja)}, j(2 tau) = {sci(jb)}, |Phi_2| / largest term < 1e-10: {abs(sum(t)) < 1e-10 * max(map(abs, t))}")
assert abs(sum(t)) < 1e-10 * max(map(abs, t))
print(f"tau = 1.1i is special too: 100 tau^2 + 121 = 0, and (100, 0, 121) is a reduced form of D = -48400: {(100, 0, 121) in forms(-48400)}")
small = [v for v in JX.values() if abs(v) < 10**9]
on2 = [(X, Y) for X in small for Y in small if sum(phi2(X, Y)) == 0]
print(f"special pairs among the {len(small)} values under 10^9 in size: on Phi_2 = 0: {len(on2)}; on X = Y: {len(small)};"
      f" on X + Y = 1728: {sum(X + Y == 1728 for X in small for Y in small)}")
print("on Phi_2 = 0:", " ".join(f"({X},{Y})" for X, Y in on2 if X <= Y))
assert (1728, 287496) in on2 and (0, 54000) in on2 and (-3375, 16581375) in on2
def jac(n, m):                                # Jacobi symbol (n/m), m odd
    n, r = n % m, 1
    while n:
        while n % 2 == 0:
            n //= 2
            if m % 8 in (3, 5): r = -r
        n, m = m, n
        if n % 4 == 3 and m % 4 == 3: r = -r
        n %= m
    return r if m == 1 else 0
print("       D      h  h/sqrt|D|  max height of (Re tau, Im tau^2)")
for m in (15, 103, 1003, 10003, 100003, 1000003):   # D = -m, fundamental, D = 1 mod 4
    F = forms(-m)
    hd = -sum(jac(n, m) * n for n in range(1, m)) // m   # Dirichlet: h = -(1/m) sum chi(n) n
    ht = max(max(abs(b) // math.gcd(b, 2 * a), 2 * a // math.gcd(b, 2 * a), m // math.gcd(m, 4 * a * a), 4 * a * a // math.gcd(m, 4 * a * a)) for a, b, c in F)
    print(f"{-m:>8} {len(F):>6}  {len(F) / math.sqrt(m):.4f}  {ht}")
    assert hd == len(F) and ht <= 2 * m
def phi(n): return sum(1 for a in range(1, n + 1) if math.gcd(a, n) == 1)
def rats(T, lo, hi): return [(p, r) for r in range(1, T + 1) for p in range(lo * r, min(hi * r, T) + 1) if math.gcd(p, r) == 1]
X = rats(100, 0, 1)                           # every fraction in [0, 1] of height <= 100
grid = sum(1 for a, b in X for p, r in X if p * b * b == a * a * r)   # every (x, y) pair, y = x^2 by cross-multiplication
count = {T: 1 + sum(phi(b) for b in range(1, math.isqrt(T) + 1)) for T in (100, 10000, 1000000)}
print("      T  y = x^2: grid search  sum of phi  count / T  sin(pi x) = 0, x = 0..T")
for T, form in count.items():
    print(f"{T:>7}  {grid if T == 100 else '-':>20}  {form:>10}  {form / T:.4f}  {T + 1:>8}")
    assert abs(form / T - 3 / math.pi ** 2) < 0.03
assert grid == count[100]                     # the grid search against the totient sum
Y = rats(25, 1, 2)                            # every y = p/r in [1, 2] of height <= 25
two = [(a, b, p, r) for a, b in X if b <= 25 for p, r in Y if p ** b == 2 ** a * r ** b]   # (p/r)^b = 2^a
print(f"y = 2^x on [0, 1], every rational (x, y) of height <= 25 tested by y^b = 2^a: {len(two)} points, x = 0 and 1; 3/pi^2 = {3 / math.pi ** 2:.4f}")
assert two == [(0, 1, 1, 1), (1, 1, 2, 1)]
print("ALL CHECKS PASS")
