# Proof by contrapositive -- the check behind the card.  Nothing is imported.
# The car park sign: "if your ticket is validated, you pay nothing."  Four
# drivers, read by the sign, by its flip, and by its converse.  Then the twin
# claim: if a number times itself is odd, the number is odd.
DRIVERS = [("Vic", 1, 0), ("Wes", 1, 6), ("Yaz", 0, 0), ("Zed", 0, 6)]

def kept(if_part, then_part):   # an if-then breaks only when the if part holds and the then part fails
    return 0 if if_part == 1 and then_part == 0 else 1

print(f"{'name':<5}{'validated':>11}{'paid':>6}{'the sign':>10}{'the flip':>10}{'the converse':>14}")
sign, flip, converse = [], [], []
for name, val, paid in DRIVERS:
    sign.append(kept(val, 1 if paid == 0 else 0))            # validated -> pays nothing
    flip.append(kept(1 if paid > 0 else 0, 1 - val))         # paid something -> not validated
    converse.append(kept(1 if paid == 0 else 0, val))        # pays nothing -> validated
    print(f"{name:<5}{val:>11}{paid:>6}{sign[-1]:>10}{flip[-1]:>10}{converse[-1]:>14}")
print(f"the flip disagrees with the sign on rows {sum(1 for a, b in zip(sign, flip) if a != b)}")
print(f"the converse disagrees with the sign on rows {sum(1 for a, b in zip(sign, converse) if a != b)}")
n, k = 6, 3
print(f"{n} = 2 x {k}, so {n} x {n} = 2 x ({k} x {n}) = 2 x {k * n} = {n * n}, even")
print(f"7 x 7 = {7 * 7}, odd")
odd_ones = [m for m in range(1, 21) if (m * m) % 2 == 1]
print(f"whole numbers 1 to 20 with n x n odd {len(odd_ones)}, every one of them odd")
assert sign == [1, 0, 1, 1] and flip == sign and converse == [1, 1, 0, 1]
assert n * n == 2 * (k * n) and (n * n) % 2 == 0 and (7 * 7) % 2 == 1
assert odd_ones == list(range(1, 21, 2)) and len(odd_ones) == 10
print("ALL CHECKS PASS")
