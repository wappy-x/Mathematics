# Strong induction -- the check behind the card.  Nothing is imported.  A post
# office sells only 3-cent and 5-cent stamps.  Two roads to the payable amounts:
# build them by the strong step, or try every count of 3s against every count of 5s.
STAMPS = (3, 5)
BASES = (8, 9, 10)
MADE = {8: "3 + 5", 9: "3 + 3 + 3", 10: "5 + 5"}

def by_search(n):                       # every count of 3s against every count of 5s
    return any(t * 3 + f * 5 == n for t in range(n // 3 + 1) for f in range(n // 5 + 1))
def by_strong_step(limit, bases, reach):        # the proof itself, run forward
    paid = set(bases)
    for n in range(min(bases) + 1, limit + 1):
        if reach in STAMPS and n - reach in paid:    # lean on an amount already paid
            paid.add(n)
    return paid
paid = by_strong_step(40, BASES, 3)
searched = {n for n in range(41) if by_search(n)}
never = sorted(set(range(41)) - searched)
print(f"{'amount':>7}{'made from':>12}{'by the step':>13}{'by search':>11}")
for n in (7, 8, 9, 10, 11, 12, 13):
    made = MADE.get(n, f"{n - 3} + 3") if n >= 8 else "none"
    print(f"{n:>7}{made:>12}{'yes' if n in paid else 'no':>13}{'yes' if by_search(n) else 'no':>11}")
print(f"amounts that cannot be paid at all: {never} -- {len(never)} of them")
one_base = min(set(range(8, 41)) - by_strong_step(40, (8,), 3))
one_back = min(set(range(8, 41)) - by_strong_step(40, BASES, 1))
print(f"the three mistakes come out at {one_base}, {one_back} and 7")
assert paid == set(range(8, 41))
assert searched == set(range(41)) - {1, 2, 4, 7}
assert not by_search(7) and one_base == 9 and one_back == 11
print("ALL CHECKS PASS")
