# The binomial series and e -- the check behind the card.  Nothing imported.
# Road one: a series, term by term.  Road two never touches it: Heron's root,
# a dollar compounded a million times, a direct count of clean draws.
N = 1000000

def binom_terms(a, x, count):            # C(a, k) x^k for k = 0 .. count - 1
    terms, c, p = [], 1.0, 1.0
    for k in range(count):
        terms.append(c * p)
        c, p = c * (a - k) / (k + 1), p * x   # next coefficient, next power
    return terms

def heron(s):                            # road two to a root: average y and s / y
    y = s
    for _ in range(60): y = (y + s / y) / 2
    return y

def exp_sum(x, count):                   # 1 + x + x^2/2! + ..., count terms
    total, term = 0.0, 1.0
    for k in range(count):
        total, term = total + term, term * x / (k + 1)
    return total

def ladder(step, times):                 # (1 + step) multiplied in, times times
    y = 1.0
    for _ in range(times):
        y = y * (1 + step)
    return y

def clean(n, pos=0, used=0):             # draws of n names, nobody on their own
    return 1 if pos == n else sum(clean(n, pos + 1, used | 1 << j) for j in range(n) if j != pos and not used >> j & 1)

t = binom_terms(0.5, 0.1, 6)
sums = [sum(t[:k + 1]) for k in range(6)]
root, root2 = sum(binom_terms(0.5, 0.1, 20)), heron(1.1)
print("C(1/2, k), k = 0..5:", " ".join(f"{v:.8f}" for v in binom_terms(0.5, 1, 6)))
print("terms, k = 0..5:", " ".join(f"{v:.10f}" for v in t))
print("partial sums:   ", " ".join(f"{v:.10f}" for v in sums))
print(f"root of 1.1: 20 terms {root:.12f}, Heron {root2:.12f}")
print(f"error after 4 terms {sums[3] - root2:.10f}, first term left out {-t[4]:.10f}")
print("root of 4, x = 3, by 5, 10, 20 terms:", " ".join(f"{sum(binom_terms(0.5, 3, m)):.2f}" for m in (5, 10, 20)))
print(f"no k! in the coefficients, 4 terms: {sum(v * f for v, f in zip(t, (1, 1, 2, 6))):.6f}")
e, e2, inv, inv2 = exp_sum(1, 20), ladder(1 / N, N), exp_sum(-1, 20), ladder(-1 / N, N)
print(f"e: series {e:.12f}, compounded {N} times {e2:.12f}")
print(f"1/e: series {inv:.12f}, (1 - 1/{N})^{N} {inv2:.12f}")
print(f"series at 1 times series at -1: {e * inv:.12f}")
print("chart, series to 1/n!, n = 1..8:", " ".join(f"{exp_sum(1, n + 1):.2f}" for n in range(1, 9)))
print("chart, (1 + 1/n)^n, n = 1..8:   ", " ".join(f"{ladder(1 / n, n):.2f}" for n in range(1, 9)))
print("n  counted       n!/e  share     gap to 1/e  bound 1/(n+1)!")
fact = 1
for n in range(1, 10):
    fact *= n
    d, share = clean(n), clean(n) / fact
    if 4 <= n <= 8:
        print(f"{n}  {d:7d}  {fact * inv:10.3f}  {share:.6f}  {share - inv:+.6f}   {1 / (fact * (n + 1)):.6f}")
    assert abs(share - inv) < 1 / (fact * (n + 1))  # counted share within the tail bound
print(f"signs dropped, six people: 720 x {exp_sum(1, 7):.6f} = {720 * exp_sum(1, 7):.0f}")
assert abs(root - root2) < 1e-14                  # binomial series against Heron
assert abs(e - e2) < 2e-6                         # series against compounding
assert abs(inv - inv2) < 1e-6                     # alternating series against discounting
