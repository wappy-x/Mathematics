# Monotone functions and jumps -- the check behind the card.  Standard library
# only.  Road 1: the fare formula gives the one-sided limits.  Road 2: a meter
# driven metre by metre, read as highest value below and lowest value above.
# Road 3: the counting bound, jumps of size h or more <= rise / h.
def F(m): return 250 + 120 * -(-m // 1000)            # fare in cents at m metres
vals, fare = [], 250                                  # the meter, metre by metre
for m in range(0, 5001):
    if m % 1000 == 1: fare += 120                     # a new kilometre starts
    vals.append(fare)
d = lambda c: f"{c / 100:.2f}"
print("setup: taxi fare 2.50 + 1.20 per started km on [0, 5]; "
      "test staircase g on [0, 1] adds 2^-n at x = 1/n")
jumps = {}
for c in range(6):
    lf = 250 + 120 * c if c > 0 else None               # road 1: the formula
    rf = 250 + 120 * (c + 1) if c < 5 else None
    lb = max(vals[:1000 * c]) if c > 0 else None        # road 2: sup below
    rb = min(vals[1000 * c + 1:]) if c < 5 else None    # road 2: inf above
    assert (lf, rf) == (lb, rb) and (lf or 0) <= F(1000 * c) <= (rf or 10**9)
    j = (rf if rf else F(5000)) - (lf if lf is not None else F(0))
    jumps[c] = j
    print(f"at {c} km: left {d(lf) if lf else '-'}, value {d(F(1000 * c))}, "
          f"right {d(rf) if rf else '-'}, jump {d(j)}")
print("near 2 km from the left, 1.9, 1.99, 1.999 km:", ", ".join(d(F(m)) for m in (1900, 1990, 1999)),
      "| from the right, 2.1, 2.01, 2.001 km:", ", ".join(d(F(m)) for m in (2100, 2010, 2001)))
scan = [(m - 1, vals[m] - vals[m - 1]) for m in range(1, 5001) if vals[m] > vals[m - 1]]
print("meter scan: rises at", ", ".join(f"{m // 1000}" for m, _ in scan), "km; sizes",
      ", ".join(d(s) for _, s in scan) + "; total", d(sum(s for _, s in scan)))
rise = F(5000) - F(0)
assert [m for m, _ in scan] == [1000 * c for c in jumps if jumps[c]] and sum(s for _, s in scan) == rise
for h in (120, 50):
    n = sum(1 for j in jumps.values() if j >= h)
    print(f"rise {d(rise)}; jumps of at least {d(h)}: bound {rise // h}, found {n}")
    assert n <= rise / h
def g(x): return sum(2.0 ** -n for n in range(1, 61) if x >= 1 / n)   # by definition
brute = [g(1 / n) - g(1 / n - 1e-9) for n in range(1, 61)]
assert all(abs(b - 2.0 ** -n) < 1e-12 for n, b in zip(range(1, 61), brute))
print("g jumps at x = 1, 1/2, 1/3, 1/4 by definition:", ", ".join(f"{b:.6f}" for b in brute[:4]),
      "| formula 2^-n:", ", ".join(f"{2.0 ** -n:.6f}" for n in range(1, 5)))
grise = g(1) - g(0)
hs = (0.1, 0.01, 0.001, 0.000001)
found = [sum(1 for b in brute if b >= h) for h in hs]
assert all(n <= grise / h for n, h in zip(found, hs)) and found == [3, 6, 9, 19]
print(f"g rise {grise:.6f}; jumps of at least 0.1, 0.01, 0.001, 0.000001: found "
      + ", ".join(map(str, found)) + "; bounds " + ", ".join(f"{grise / h:.0f}" for h in hs))
print(f"mistakes: jump at 2 km measured from the value {d(F(2000) - max(vals[:2000]))}; "
      f"kerb jump dropped: {sum(1 for c in range(1, 6) if jumps[c])} jumps, {d(sum(jumps[c] for c in range(1, 6)))} of {d(rise)}")
X, Y = (lambda km: 60 + 56 * km), (lambda c: 200 - 25 * (c - 250) / 100)
print("figure, 56 px per km, 25 px per dollar; step heights y =", ", ".join(f"{Y(250 + 120 * k):.0f}" for k in range(1, 6))
      + "; jump edges x =", ", ".join(f"{X(c):.0f}" for c in range(5)))
print("ALL CHECKS PASS")
