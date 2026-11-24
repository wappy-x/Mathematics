# Cauchy product and Mertens' theorem -- the check behind the card.  Nothing is
# imported.  The product of two series adds the grid of products a_k * b_m
# along its diagonals k + m = n.  Road one convolves the term lists; road two
# uses closed forms, and an independent ln 2 from Simpson's rule.

def cauchy(a, b):                        # c_n = a_0 b_n + a_1 b_(n-1) + ... + a_n b_0
    out = []
    for n in range(len(a)):
        s = 0.0
        for k in range(n + 1):
            s += a[k] * b[n - k]
        out.append(s)
    return out
def running(terms):                      # partial sums: entry N totals terms 0..N
    out, s = [], 0.0
    for t in terms:
        s += t
        out.append(s)
    return out
def simpson(f, a, b, panels):            # parabolas through each pair of strips
    h, s = (b - a) / panels, f(a) + f(b)
    for i in range(1, panels):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

geo = [0.5 ** n for n in range(2001)]                 # 1 + 1/2 + 1/4 + ..., sum 2
c = cauchy(geo[:60], geo[:60])
C, A = running(c), running(geo[:60])
print("house: c_n for n=0..5: " + " ".join(f"{x:.4f}" for x in c[:6]))
print(f"house: C_10={C[10]:.6f}  4-13/1024={4 - 13 / 1024:.6f}  A_10*B_10={A[10] ** 2:.6f}")
print(f"house: C_59={C[59]:.6f}  A*B={A[59] * A[59]:.6f}")
assert all(abs(c[n] - (n + 1) / 2 ** n) < 1e-15 for n in range(60))   # count the diagonal
assert all(abs(C[N] - (4 - (N + 3) / 2 ** N)) < 1e-12 for N in range(60))
same = running([x * x for x in geo[:60]])[59]
print(f"mistake, positions matched a_n*b_n: {same:.6f}, not 4")
L = simpson(lambda t: 1.0 / (1.0 + t), 0.0, 1.0, 2000)
alt = [(-1) ** n / (n + 1) for n in range(2001)]      # 1 - 1/2 + 1/3 - ..., sum ln 2
m = cauchy(geo, alt); M = running(m)
print(f"ln 2 by Simpson={L:.9f}  2 ln 2={2 * L:.9f}")
print("mertens: C_N at N=10, 100, 1000, 2000: " + " ".join(f"{M[N]:.6f}" for N in (10, 100, 1000, 2000)))
assert abs((M[1999] + M[2000]) / 2 - 2 * L) < 1e-6   # neighbours straddle 2 ln 2
sizes = running([abs(x) for x in m])
print(f"mertens: (n+1)|c_n| at n=1000: {1001 * abs(m[1000]):.6f}; sum |c_n| to 100, 1000: {sizes[100]:.6f} {sizes[1000]:.6f}")
sq = [(-1) ** n / (n + 1) ** 0.5 for n in range(1000001)]   # 1 - 1/sqrt 2 + 1/sqrt 3 - ...
P = running(sq)
S = (P[999999] + P[1000000]) / 2                      # average two neighbouring totals
d = cauchy(sq[:200], sq[:200]); D = running(d)
print(f"conditional: S={S:.6f}  S^2={S * S:.6f}")
print("conditional: |c_n| for n=0..5: " + " ".join(f"{abs(x):.4f}" for x in d[:6]))
assert all(abs(d[n]) >= 2 * (n + 1) / (n + 2) for n in range(200))   # never below 1
print(f"conditional: |c_n| >= 2(n+1)/(n+2) >= 1 for every n < 200; C_98={D[98]:.6f}  C_99={D[99]:.6f}")
for name, line in (("house", C), ("mertens", M), ("conditional", D)):
    print(f"chart {name} C_N, N=0..12: " + " ".join(f"{x:.2f}" for x in line[:13]))
v = 1 / 1.05                                          # one year's discount at 5%
due = [v ** n for n in range(1500)]                   # 1 now and every year after
late = [0.0] + due[1:]                                # 1 at the end of every year
rising = cauchy(due, late)                            # n paid at the end of year n
print(f"bond at 5%: due={running(due)[-1]:.6f}  level={running(late)[-1]:.6f}  rising={running(rising)[-1]:.6f}")
assert abs(running(rising)[-1] - 21 * 20) < 1e-6 and abs(rising[7] - 7 * v ** 7) < 1e-12
print("ALL CHECKS PASS")
