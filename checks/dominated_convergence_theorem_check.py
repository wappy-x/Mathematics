# Dominated convergence -- the check behind the card.  Standard library only.
# Spam at 2 per hour: cut the hour into n slots, each holding one spam with
# chance 2/n.  The count K is binomial(n, 2/n); its masses p_n(k) tend to the
# Poisson(2) masses q(k).  A sum over k is an integral against counting measure.
# Road one builds each mass as a product; road two by a recursion or a closed
# form.  Then the roof 2^k/k!, the swapped limits, Scheffe's total error,
# x^n on [0, 1] under the roof 1, and what breaks when no roof exists.
KMAX = 60                                     # counts above 60: the roof's tail is printed
NS = (10, 100, 1000)

def exp_series(t, terms=90):                  # e^t from its power series
    s, term = 0.0, 1.0
    for j in range(terms):
        s += term
        term *= t / (j + 1)
    return s

def roof(k):                                  # g(k) = 2^k / k!
    r = 1.0
    for i in range(k):
        r *= 2 / (i + 1)
    return r

def binom_product(n, k):                      # [n(n-1)...(n-k+1)/n^k] x 2^k/k! x (1 - 2/n)^(n-k)
    if k > n:
        return 0.0
    c = 1.0
    for i in range(k):
        c *= (n - i) / n * 2 / (i + 1)
    return c * (1 - 2 / n) ** (n - k)

def binom_recursion(n):                       # p(k+1) = p(k) x (n-k)/(k+1) x 2/(n-2)
    p = [(1 - 2 / n) ** n]
    for k in range(KMAX):
        p.append(p[-1] * (n - k) / (k + 1) * 2 / (n - 2))
    return p

def midpoint(f, m=200000):                    # integral over [0, 1] by midpoints
    return sum(f((i + 0.5) / m) for i in range(m)) / m

# the limit q(k) = e^(-2) 2^k/k!, two ways to e^(-2)
e_a, e_b = exp_series(-2.0), 1 / exp_series(2.0)
q = [e_a * roof(k) for k in range(KMAX + 1)]
q2 = [e_b]
for k in range(KMAX):
    q2.append(q2[-1] * 2 / (k + 1))
assert max(abs(a - b) for a, b in zip(q, q2)) < 1e-15
print(f"e^(-2): series {e_a:.10f}, 1/(series for e^2) {e_b:.10f}")
print(f"by hand, n = 10, k = 2: 10 x 9/100 = {10 * 9 / 100:.4f}, roof {roof(2):.4f}, 0.8^8 = {0.8 ** 8:.4f},"
      f" product {10 * 9 / 100 * roof(2) * 0.8 ** 8:.4f}; q(2) = e^(-2) x 2 = {e_a:.6f} x 2 = {q[2]:.4f}")

P = {n: [binom_product(n, k) for k in range(KMAX + 1)] for n in NS}
for n in NS:
    assert max(abs(a - b) for a, b in zip(P[n], binom_recursion(n))) < 1e-13
print("k   n = 10   n = 100  n = 1000  Poisson  roof 2^k/k!")
for k in range(9):
    print(f"{k}   {P[10][k]:.4f}   {P[100][k]:.4f}   {P[1000][k]:.4f}    {q[k]:.4f}   {roof(k):.4f}")

# the roof: p_n(k) <= 2^k/k! at every count, for every n
under = [all(binom_product(n, k) <= roof(k) for k in range(n + 1)) for n in NS]
print("roof holds at every count: " + ", ".join(f"n = {n} {'yes' if u else 'no'}" for n, u in zip(NS, under)))
assert all(under)
tail = sum(roof(k) for k in range(KMAX + 1, 200))
print(f"roof totals: sum 2^k/k! = {sum(roof(k) for k in range(200)):.4f} = e^2; sum k^2 2^k/k! = "
      f"{sum(k * k * roof(k) for k in range(200)):.4f} = 6e^2; tail above k = {KMAX}: {tail:.1e}")

# dominated convergence: mean and E[K^2] follow the masses
for n in NS:
    m1 = sum(k * p for k, p in enumerate(P[n]))
    m2 = sum(k * k * p for k, p in enumerate(P[n]))
    print(f"n = {n}: mean {m1:.4f} (formula 2), E[K^2] {m2:.4f} (formula 6 - 4/n = {6 - 4 / n:.4f}),"
          f" variance {m2 - m1 * m1:.4f}")
    assert abs(m2 - (6 - 4 / n)) < 1e-9
m1 = sum(k * p for k, p in enumerate(q))
m2 = sum(k * k * p for k, p in enumerate(q))
print(f"Poisson: mean {m1:.4f}, E[K^2] {m2:.4f} (formula 2 + 4 = 6), variance {m2 - m1 * m1:.4f}")
assert abs(m2 - 6) < 1e-12

# Scheffe: equal totals turn pointwise convergence into total-error convergence
qb = 1 - sum(q[:5])
L1 = {}
for n in NS:
    L1[n] = sum(abs(a - b) for a, b in zip(P[n], q))
    pos = sum(max(b - a, 0.0) for a, b in zip(P[n], q))
    over = [k for k in range(KMAX + 1) if P[n][k] > q[k]]
    print(f"Scheffe, n = {n}: sum |p - q| = {L1[n]:.4f}; 2 x sum (q - p)+ = {2 * pos:.4f};"
          f" Le Cam bound 8/n = {8 / n:.4f}; p above q at counts {over}")
    assert abs(L1[n] - 2 * pos) < 1e-12
    assert L1[n] <= 8 / n
    pb = 1 - sum(P[n][:5])
    print(f"  burst of 5 or more: binomial {pb:.4f}, Poisson {qb:.4f}, gap {abs(pb - qb):.4f}"
          f" <= half the total error {L1[n] / 2:.4f}")
    assert abs(pb - qb) <= L1[n] / 2
for lab, row in (("n = 10", P[10]), ("n = 100", P[100]), ("Poisson", q)):
    print(f"chart %, {lab}: " + ", ".join(f"{100 * v:.2f}" for v in row[:9]))

# x^n on [0, 1] under the roof 1 (bounded convergence)
spike = {}
for n in (1, 10, 100, 1000):
    I = midpoint(lambda x: x ** n)
    spike[n] = (n + 1) * I
    print(f"x^n, n = {n}: midpoint sum {I:.6f}, exact 1/(n+1) = {1 / (n + 1):.6f};"
          f" at x = 0.999 still {0.999 ** n:.4f}")
    assert abs(I - 1 / (n + 1)) < 1e-6
print("chart roof g = 1: " + ", ".join(f"{1.0:.2f}" for j in range(11)))
for n in (5, 20):
    print(f"chart x^n, n = {n}: " + ", ".join(f"{(j / 10) ** n:.2f}" for j in range(11)))

# what breaks
env = [sum(max(1 if k == n else 0 for n in range(1, R + 1)) for k in range(1, R + 1)) for R in NS]
print(f"breaks, sliding mass at count n: total 1, limit 0 at every count;"   # all the chance at count n
      f" smallest roof summed over counts 1..R = {env[0]}, {env[1]}, {env[2]} for R = 10, 100, 1000")
for n in NS:                                  # storm hour: n^2 spams with chance 1/n
    s_l1 = sum(abs((1 - 1 / n) * a - b) for a, b in zip(P[n], q)) + 1 / n
    s_mean = sum(k * (1 - 1 / n) * p for k, p in enumerate(P[n])) + n * n / n
    print(f"breaks, storm hour, n = {n}: total error {s_l1:.4f}, mean {s_mean:.4f} (formula 2(1 - 1/n) + n = {2 * (1 - 1 / n) + n:.4f})")
    assert abs(s_mean - (2 * (1 - 1 / n) + n)) < 1e-9
print(f"breaks, spike (n+1)x^n: integral {spike[10]:.4f}, {spike[100]:.4f}, {spike[1000]:.4f} at n = 10, 100, 1000; limit 0 below x = 1")
assert abs(spike[1000] - 1) < 1e-3
print(f"breaks, the limit as roof: p_10(2) = {P[10][2]:.4f} > q(2) = {q[2]:.4f}")
assert P[10][2] > q[2]
print("ALL CHECKS PASS")
