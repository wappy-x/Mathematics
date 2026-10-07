# Finite fields -- the check behind the card.  Nothing is imported.  Four symbols,
# each two coefficients wrapped at 2: 0, 1, a, a + 1, where a is the letter x once
# x^2 + x + 1 is set to 0, so a^2 = a + 1.  A symbol packs into an integer: bit 0 the
# plain coefficient, bit 1 the coefficient of a, so a + 1 is 3.  Road one multiplies by
# shifting and XOR, then folds the top power away with the modulus; road two uses the
# coordinate rule worked out by hand from a^2 = a + 1.  The roads share no arithmetic.
NAMES, E = ["0", "1", "a", "a+1"], range(4)
def times(u, v, modulus=0b111):          # road one: shift, XOR, fold at x^2 + x + 1
    raw = (u if v & 1 else 0) ^ (u << 1 if v & 2 else 0)
    while raw.bit_length() > 2:          # a^2 and above folds back down
        raw ^= modulus << (raw.bit_length() - 3)
    return raw
def coord_times(u, v):                   # road two: (c + da)(e + ha), coefficient by coefficient
    c, d, e, h = u & 1, u >> 1, v & 1, v >> 1
    return (c * e + d * h) % 2 | ((c * h + d * e + d * h) % 2) << 1
def clock_recip(n):                      # reciprocals on an n-hour clock by search, 0 for none
    return [next((b for b in range(1, n) if a * b % n == 1), 0) for a in range(1, n)]
def bezout_recip(a, n):                  # the other road on a clock: Euclid's gcd, run backwards
    old, new, s_old, s_new = a, n, 1, 0
    while new:
        q = old // new
        old, new, s_old, s_new = new, old - q * new, s_new, s_old - q * s_new
    return s_old % n if old == 1 else 0
def row(values): return " ".join(str(v) for v in values)
def named(values): return " ".join(NAMES[v] for v in values)

print("column order: 0 1 a a+1")
for u in E:
    print(f"add {NAMES[u]:<5} : {named([u ^ v for v in E])}")
for u in E:
    print(f"times {NAMES[u]:<3} : {named([times(u, v) for v in E])}")
roots = [(x * x + x + 1) % 2 for x in (0, 1)]
print(f"x^2 + x + 1 at x = 0 and at x = 1, wrapped at 2: {roots[0]} and {roots[1]}, never 0")
agree = sum(times(u, v) == coord_times(u, v) for u in E for v in E)
spread = sum(times(u, v ^ w) == times(u, v) ^ times(u, w) for u in E for v in E for w in E)
print(f"two roads: {agree} of 16 products agree, and {spread} of 64 triples distribute")
recip = [next(b for b in range(1, 4) if times(a, b) == 1) for a in range(1, 4)]
print(f"reciprocals of 1, a, a + 1: {named(recip)}, since a times a + 1 = "
      f"{NAMES[times(2, 3)]} and a + 1 squared = {NAMES[times(3, 3)]}")
powers = [1]
for _ in range(3): powers.append(times(powers[-1], 2))
print(f"powers a^0 a^1 a^2 a^3: {named(powers)}")
week, twelve = clock_recip(7), clock_recip(12)
print(f"the seven-day week: 3 times 5 = {3 * 5}, wrapping at 7 to {3 * 5 % 7}")
print(f"week reciprocals of 1 2 3 4 5 6: {row(week)} by search, "
      f"{row([bezout_recip(a, 7) for a in range(1, 7)])} by Euclid")
have = [a for a in range(1, 12) if twelve[a - 1]]
print(f"the twelve-hour clock: 3 times 4 = {3 * 4}, wrapping to {3 * 4 % 12}; "
      f"of 1 to 11 only {row(have)} have a reciprocal")
print(f"the four-hour clock: 2 times 2 = {2 * 2}, wrapping to {2 * 2 % 4}, and "
      f"1 + 1 = {(1 + 1) % 4} where the field has 1 + 1 = {1 ^ 1}")
print(f"wrapping by x^2 + 1 instead: a + 1 squared = {times(3, 3, 0b101)}; "
      f"by x^2 + x: a times a + 1 = {times(2, 3, 0b110)}")
assert agree == 16 and spread == 64
assert recip == [1, 3, 2] and powers == [1, 2, 3, 1]
assert week == [bezout_recip(a, 7) for a in range(1, 7)] == [1, 4, 5, 2, 3, 6]
assert have == [1, 5, 7, 11] and times(3, 3, 0b101) == 0 and times(2, 3, 0b110) == 0
print("ALL CHECKS PASS")
