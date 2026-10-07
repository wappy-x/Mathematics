# Derangements -- the check behind the card.  Nothing is imported.  Six colleagues
# draw names for Secret Santa, and a draw is good when nobody draws their own name.
# Three roads that share no arithmetic count the good draws: listing, the alternating
# sieve, and the recurrence.  Their share of all draws is then set against 1/e, twice.
TOP = 8

def factorial(n):                      # n! = 1 x 2 x ... x n, with 0! = 1
    out = 1
    for i in range(2, n + 1):
        out *= i
    return out

def every_draw(n):                     # every way to hand out n names, in order
    draws = [()]
    for k in range(n):
        draws = [p[:i] + (k,) + p[i:] for p in draws for i in range(k + 1)]
    return draws

def sieve_terms(n):                    # road two: the alternating sieve, in whole numbers
    return [(-1) ** k * (factorial(n) // factorial(k)) for k in range(n + 1)]

def row(name, values):
    print(f"{name:<19}" + "".join(f"{v:>6}" for v in values))

listed = [sum(1 for p in every_draw(n) if all(p[i] != i for i in range(n)))
          for n in range(TOP + 1)]     # road one: deal them all, keep the good ones
sieved = [sum(sieve_terms(n)) for n in range(TOP + 1)]
recurred = [1, 0]                      # road three: D(n) = (n-1) x (D(n-1) + D(n-2))
for n in range(2, TOP + 1):
    recurred.append((n - 1) * (recurred[n - 1] + recurred[n - 2]))
facts = [factorial(n) for n in range(TOP + 1)]
share = [listed[n] / facts[n] for n in range(1, TOP + 1)]
alt = sum((-1) ** k / factorial(k) for k in range(21))     # road one to 1/e
compounded = (1 + 1e-7) ** 10 ** 7                         # road two: a dollar, 10^7 times
terms = sieve_terms(6)
flat = f"{terms[0]}" + "".join(f" {'-' if t < 0 else '+'} {abs(t)}" for t in terms[1:])
print(f"Secret Santa, 6 colleagues: {facts[6]} draws in all, {listed[6]} with nobody drawing their own name")
row("n", list(range(TOP + 1)))
row("n!, all draws", facts)
row("D(n) by listing", listed)
row("D(n) by the sieve", sieved)
row("D(n) by recurrence", recurred)
print("D(n)/n!, n = 1 to 8: " + " ".join(f"{s:.4f}" for s in share))
print(f"sieve at n = 6: {flat} = {sieved[6]}")
print(f"pairs at n = 6: C(6,2) = {facts[6] // (facts[2] * facts[4])}, each leaving 4! = {facts[4]} draws, so the k = 2 term is {terms[2]}")
print("sieve running totals at n = 6: " + ", ".join(str(sum(terms[:k + 1])) for k in range(7)))
print(f"recurrence at n = 6: 5 x ({listed[5]} + {listed[4]}) = 5 x {listed[5] + listed[4]} = {recurred[6]}")
print(f"one-step form at n = 6: 6 x {listed[5]} + 1 = {6 * listed[5] + 1}")
print(f"1/e by the alternating sum to 20 terms: {alt:.6f}; by compounding a dollar 10000000 times: {1 / compounded:.6f}")
print(f"720 x (1/e) = {facts[6] * alt:.3f}, nearest whole number {int(facts[6] * alt + 0.5)}")
print(f"e by the same compounding: {compounded:.6f}; the 7th and 8th terms of the share: {1 / facts[7]:.6f} and {1 / facts[8]:.6f}")
print(f"names put back after each draw, own name barred: 5^6 = {5 ** 6} lists, not {listed[6]} draws")
print(f"mistake 1, subtract the six own-name blocks and stop: 720 - 6 x 120 = {facts[6] - 6 * facts[5]}; "
      f"mistake 2, drop the sieve's last term: {sieved[6] - terms[6]}; "
      f"mistake 3, recurrence read as 5 x 44 + 9: {5 * listed[5] + listed[4]}")
assert listed == sieved                                    # listing against the sieve
assert listed == recurred                                  # listing against the recurrence
assert listed[:7] == [1, 0, 1, 2, 9, 44, 265]              # against the counts worked by hand
assert abs(alt - 1 / compounded) < 1e-6                    # two roads to 1/e
print("ALL CHECKS PASS")
