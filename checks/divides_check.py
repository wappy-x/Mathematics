# Divides -- the check behind the card.  Nothing is imported.  The 60-minute
# hour: which lesson lengths split it exactly.  Road one tests every length
# from 1 to 60.  Road two tests only 1 to 7 and takes both ends of each pair.
HOUR = 60

def divides(a, b):              # does a go into b with nothing left over?
    if a == 0:                  # 0 times anything is 0, so 0 reaches nothing else
        return b == 0
    return b % a == 0

brute = [a for a in range(1, HOUR + 1) if divides(a, HOUR)]
pairs = [(a, HOUR // a) for a in range(1, 8) if divides(a, HOUR)]
from_pairs = sorted({n for pair in pairs for n in pair})     # the check, second road
print("the pairs that multiply to 60   " + "  ".join(f"{a} x {b}" for a, b in pairs))
print("divisors of 60, smallest first  " + " ".join(str(a) for a in brute))
print("their partners, same order      " + " ".join(str(HOUR // a) for a in brute))
print(f"how many divisors 60 has        {len(brute)}")
print(f"tested 1 up to 7, because 8 x 8 = {8 * 8} is past {HOUR}")
print(f"8 does not divide 60:  60 = 8 x {HOUR // 8} + {HOUR % 8}")
print(f"12 divides 60:  {divides(12, HOUR)}         60 divides 12:  {divides(HOUR, 12)}")
print(f"1 divides 60:   {divides(1, HOUR)}         60 divides 0:   {divides(HOUR, 0)}")
print(f"0 divides 60:   {divides(0, HOUR)}        0 divides 0:    {divides(0, 0)}")
print(f"stopping the list at 6 finds only {len([a for a in brute if a <= 6])} of the {len(brute)}")

assert brute == [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60]
assert from_pairs == brute and len(brute) == 12
assert all(a * (HOUR // a) == HOUR for a in brute) and HOUR % 8 == 4 and HOUR // 8 == 7
print("ALL CHECKS PASS")
