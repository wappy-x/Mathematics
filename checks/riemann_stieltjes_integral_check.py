# Stieltjes integrals -- the check behind the card.  Standard library only.
# A book of 1,000 contracts: 400 pay $0, 500 pay amounts spread evenly over
# $0 to $100, and 100 pay the $100 cap.  G(x) is the share paying at most x.
# The average payout is the integral of x against G, reached by four roads.
A, B = -20.0, 100.0

def G(x):                               # the accumulator: right-continuous
    if x < 0: return 0.0
    if x < 100: return 0.4 + 0.005 * x  # lump 0.4 at zero, then a steady rise
    return 1.0                          # lump 0.1 at the cap

def pay(x): return x                    # the integrand: dollars paid

def rs_sum(f, n, tag):                  # Stieltjes sum on n equal slices of [A, B]
    h = (B - A) / n
    return sum(f(A + (k + tag) * h) * (G(A + (k + 1) * h) - G(A + k * h)) for k in range(n))

book = [0.0] * 400 + [(k + 0.5) * 0.2 for k in range(500)] + [100.0] * 100
smooth = 0.005 * 100 ** 2 / 2           # road 1: antiderivative of x times the rate G'
jumps = 0.4 * pay(0) + 0.1 * pay(100)   # road 1: each lump times the payout there
split = smooth + jumps
by_hand = sum(book) / len(book)         # road 3: average the 1,000 contracts one by one
m = 100000                              # road 4: area above G, by a midpoint sum
tail = sum(1 - G((k + 0.5) * 100 / m) for k in range(m)) * 100 / m

print(f"book: {book.count(0.0)} at $0, {sum(1 for p in book if 0 < p < 100)} spread between, {book.count(100.0)} at $100")
print(f"chart, G at -20 -10 0- 0 20 40 60 80 100- 100: " + " ".join(f"{G(x):.2f}" for x in (-20, -10, -1e-9, 0, 20, 40, 60, 80, 100 - 1e-9, 100)))
print(f"lumps: {G(0) - G(-1e-9):.2f} at $0, {G(100) - G(100 - 1e-9):.2f} at $100; rate between them {(G(60) - G(20)) / 40:.3f} per dollar")
print(f"total weight G(b) - G(a) = {G(B) - G(A):.2f}; contracts paying something: {sum(1 for p in book if p > 0)}")
print(f"road 1, split: smooth part {smooth:.2f} + lumps {jumps:.2f} = {split:.2f}")
for n in (12, 120, 1200):               # road 2: lower and upper sums close on it
    lo, hi = rs_sum(pay, n, 0.0), rs_sum(pay, n, 1.0)
    print(f"road 2, n = {n}: slice width {(B - A) / n:.2f}, lower {lo:.3f}, upper {hi:.3f}, gap {hi - lo:.3f}")
    assert lo <= split <= hi and abs((hi - lo) - (B - A) / n * (G(B) - G(A))) < 1e-9
print(f"road 3, contract by contract: {len(book)} contracts, total {sum(book):.2f}, average {by_hand:.2f}")
print(f"road 4, area above G from 0 to 100: {tail:.2f}")
assert abs(by_hand - split) < 1e-9      # the list agrees with the formula
assert abs(tail - split) < 1e-6         # the area agrees with the formula
print(f"mistake 1, lumps dropped: {smooth:.2f}")
print(f"mistake 2, lumps dropped, divided by smooth weight {G(100 - 1e-9) - G(0):.2f}: {smooth / (G(100 - 1e-9) - G(0)):.2f}")
print(f"mistake 3, width instead of weight, integral of x from 0 to 100: {100 ** 2 / 2:.2f}")

def fee(x): return 1.0 if x > 0 else 0.0   # $1 on each contract that pays something
for n in (125, 1250):                   # 0 falls inside a slice, not on a cut
    lo, hi = rs_sum(fee, n, 0.0), rs_sum(fee, n, 1.0)
    print(f"shared jump, n = {n}: left tags {lo:.4f}, right tags {hi:.4f}")
    assert hi - lo > 0.39               # the tags never agree: no integral
print(f"fee by counting contracts: {sum(1 for p in book if p > 0) / len(book):.4f} per contract")
print("ALL CHECKS PASS")
