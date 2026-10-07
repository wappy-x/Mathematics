# Euclid's algorithm -- the check behind the card.  Nothing is imported.  Two
# cable drums, 1071 m and 462 m, to be cut into equal lengths with nothing
# left over.  Plain way: divide, keep the remainder, repeat.  Second road:
# try every length that divides both and keep the biggest.  They must agree.
def euclid(a, b):                # the gcd, how many divisions it took, the divisions
    rows, steps = [], 0
    while b:
        rows.append((f"{a} = {a // b} x {b} + {a % b}", a % b))
        a, b, steps = b, a % b, steps + 1
    return a, steps, rows
def biggest_common_divisor(a, b):     # the slow road, kept for the cross-check
    return max(d for d in range(1, min(a, b) + 1) if a % d == 0 and b % d == 0)
def row(name, value):
    print(f"{name:<52}{value:>4}")
g, steps, rows = euclid(1071, 462)
for text, r in rows:
    row(text, r)
row(f"the last non-zero remainder, after {steps} divisions", g)
row("every length tried, the biggest that divides both", biggest_common_divisor(1071, 462))
row(f"pieces at {g} m: {1071 // g} from one drum, {462 // g} from the other", 1071 // g + 462 // g)
row(f"cut at 7 m instead: {1071 // 7} and {462 // 7}", 1071 // 7 + 462 // 7)
row(f"cut at 3 m instead: {1071 // 3} and {462 // 3}", 1071 // 3 + 462 // 3)
row("stop at 147 m: metres wasted off the 462 m drum", 462 % 147)
gf, sf, _ = euclid(55, 34)
print(f"slowest pair its size: gcd(55, 34) = {gf}, {sf} divisions, ceiling 5 x 2 = {5 * 2}")
assert (g, steps) == (21, 3) and 1071 % g == 0 and 462 % g == 0
assert g == biggest_common_divisor(1071, 462)
assert 1071 // g + 462 // g == 73 and 1071 // 7 + 462 // 7 == 219
print("ALL CHECKS PASS")
