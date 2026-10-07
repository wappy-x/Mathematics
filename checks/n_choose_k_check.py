# Combinations, n choose k -- the check behind the card.  Nothing is imported.
# A lottery draws 6 balls from 49; a 20-player squad fields a starting eleven.
# Every count is reached twice: once by multiplying and dividing, once by
# addition alone (Pascal's triangle) or by listing every line-up one by one.
LOTTO_N, LOTTO_K, SQUAD, ELEVEN = 49, 6, 20, 11

def fact(m):                              # m! = m x (m-1) x ... x 1, with 0! = 1
    out = 1
    for j in range(2, m + 1): out *= j
    return out

def ordered(n, k):                        # n x (n-1) x ... x (n-k+1): k factors
    out = 1
    for j in range(k): out *= n - j
    return out

def choose(n, k):                         # road one: the quotient, (n-k)! cancelled
    return 0 if k < 0 or k > n else ordered(n, k) // fact(k)

def yn(claim): return "yes" if claim else "no"

rows = [[1]]                              # road two: addition only, nothing multiplied
for n in range(1, LOTTO_N + 1):
    prev = rows[-1]
    rows.append([1] + [prev[j - 1] + prev[j] for j in range(1, n)] + [1])

full, elevens, nines = (1 << SQUAD) - 1, set(), set()
lineups = [0] * (SQUAD + 1)               # road three: list every line-up of the 20
for mask in range(1 << SQUAD):            # one bit per player, 1 = on the pitch
    bits = mask.bit_count()
    lineups[bits] += 1
    if bits == ELEVEN: elevens.add(mask)
    elif bits == SQUAD - ELEVEN: nines.add(mask)
paired = {full ^ m for m in elevens} == nines
toy = [f"{a}{b}" for a in range(1, 6) for b in range(a + 1, 6)]
drawn, orders = ordered(LOTTO_N, LOTTO_K), fact(LOTTO_K)
first_seven = " ".join(str(v) for v in rows[SQUAD][:7])

print(f"toy draw, 2 balls from 5, listed: {' '.join(toy)} = {len(toy)} tickets; C(5,2) = {choose(5, 2)}")
print(f"lottery, 6 balls from 49, in the order drawn: 49x48x47x46x45x44 = {drawn}")
print(f"orders of one ticket: 6! = {orders}")
print(f"divide the order out: {drawn} / {orders} = {drawn // orders} tickets")
print(f"the same count by addition alone, row 49 of Pascal's triangle: {rows[LOTTO_N][LOTTO_K]}")
print(f"squad of 20, an eleven in order: 20x19x...x10 = {ordered(SQUAD, ELEVEN)}, orders inside one eleven: 11! = {fact(ELEVEN)}")
print(f"divide the order out: {ordered(SQUAD, ELEVEN)} / {fact(ELEVEN)} = {choose(SQUAD, ELEVEN)} starting elevens")
print(f"the nine left out: C(20,9) = {choose(SQUAD, SQUAD - ELEVEN)}")
print(f"all {sum(lineups)} line-ups listed: 11 on the pitch {lineups[ELEVEN]}, 9 on the pitch {lineups[SQUAD - ELEVEN]}")
print(f"each eleven paired with the nine it leaves out, one to one: {yn(paired)}")
print(f"row 20 of Pascal, first seven entries: {first_seven}")
print(f"row 20 adds to {sum(rows[SQUAD])}, the number of line-ups listed: {yn(sum(rows[SQUAD]) == sum(lineups))}")
print(f"five penalty takers in order, same squad: 20x19x18x17x16 = {ordered(SQUAD, 5)}")
print(f"mistake 1, the order kept: {drawn}, not {drawn // orders}")
print(f"mistake 2, divided by 6 instead of 720: {drawn // LOTTO_K}")
print(f"mistake 3, each ball put back: 49^6 = {LOTTO_N ** LOTTO_K}")
print(f"mistake 4, eleven named positions: {ordered(SQUAD, ELEVEN)}, not {choose(SQUAD, ELEVEN)}")
assert rows[LOTTO_N][LOTTO_K] == choose(LOTTO_N, LOTTO_K)        # addition against dividing
assert lineups[ELEVEN] * fact(ELEVEN) == ordered(SQUAD, ELEVEN)  # listed sets x 11! = ordered
assert lineups[ELEVEN] == rows[SQUAD][ELEVEN] and paired         # listing against Pascal
assert sum(lineups) == sum(rows[SQUAD]) and len(toy) == choose(5, 2)
print("ALL CHECKS PASS")
