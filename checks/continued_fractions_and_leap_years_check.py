# Continued fractions and the leap year -- the check behind the card.  Nothing is
# imported.  A year is 365.2422 days; Euclid on the leftover 0.2422 = 1211/5000 gives
# the steps, stopping early gives the fractions, brute force is the second road.
LEFT = 1211 / 5000
def euclid_steps(a, b):                        # 1211/5000 -> 0, 4, 7, 1, 3, ...
    out = []
    while b: out.append(a // b); a, b = b, a % b
    return out
def stops(steps):                              # the early stops, as top/bottom
    top, t_before, bot, b_before, out = steps[0], 1, 1, 0, [(steps[0], 1)]
    for s in steps[1:]:
        top, t_before, bot, b_before = s * top + t_before, top, s * bot + b_before, bot
        out.append((top, bot))
    return out
def best_upto(cap):                            # closest fraction, bottom <= cap
    return min(((round(q * LEFT), q) for q in range(1, cap + 1)), key=lambda f: abs(LEFT - f[0] / f[1]))
steps = euclid_steps(1211, 5000); four = stops(steps)[1:5]
leaps = sum(1 for y in range(1, 401) if y % 4 == 0 and (y % 100 != 0 or y % 400 == 0))
print(f"{'a year, in days':<40}365.2422")
print(f"{'the leftover after 365 whole days':<40}0.2422 = 1211/5000")
print(f"{'the whole-number steps, from Euclid':<40}" + ", ".join(map(str, steps)))
rows = [(f"   stop after step {i}", p, q) for i, (p, q) in enumerate(four, 1)] + [("   the Gregorian rule", 97, 400)]
for name, p, q in rows: print(f"{name:<22}{p:>4}/{q:<5}{p / q:.6f}{(p / q - LEFT) * 400:>9.3f} days adrift per 400 years")
print(f"counting the real rule over 400 years: {400 // 4} minus {400 // 4 - leaps} century skips is {leaps} leap days")
print(f"every stop beats every fraction with a bottom up to its own; best up to 400 is {best_upto(400)[0]}/{best_upto(400)[1]}, not 97/400")
print("pi as 3.14159265358979, same trick: " + ", ".join(f"{p}/{q}" for p, q in stops(euclid_steps(314159265358979, 100000000000000))[:4]))
assert four == [(1, 4), (7, 29), (8, 33), (31, 128)] and leaps == 97
assert all(best_upto(q) == (p, q) for p, q in four) and best_upto(400) == (31, 128)
assert abs(97 / 400 - LEFT) > 20 * abs(31 / 128 - LEFT)
print("ALL CHECKS PASS")
