# Cantor's diagonal -- the check behind the card.  Nothing is imported.  Five
# hotel guests hold five reals between 0 and 1.  Read down the diagonal, write a
# 4 in every place (a 5 where the digit read is a 4), and the number is nobody's.
GUESTS = [(1, 7), (1, 2), (1, 3), (5, 9), (1, 8)]
PLACES = 5
def digits(p, q):                 # long division, greedy: 1/2 -> "500000", never "499999"
    out, left = "", p
    for _ in range(PLACES + 1):
        out += str(left * 10 // q)
        left = left * 10 % q
    return out
def bump(d):                      # add 1 to a digit, 9 goes round to 0
    return str((int(d) + 1) % 10)
rows = [digits(p, q) for p, q in GUESTS]
diagonal = "".join(rows[i][i] for i in range(PLACES))
safer = "".join("5" if d == "4" else "4" for d in diagonal)   # the 4-or-5 rule
built = "".join(bump(d) for d in diagonal)                    # the popular add-1 rule
for i, ((p, q), row) in enumerate(zip(GUESTS, rows)):
    print(f"guest {i + 1}  {p}/{q}  0.{row}   diagonal digit {row[i]}")
print(f"the diagonal reads {diagonal}, the 4-or-5 rule builds 0.{safer}")
print(f"the popular add-1 rule builds 0.{built}")
print(f"as whole numbers {int(built)} is none of " + " ".join(str(int(r[:PLACES])) for r in rows))
across = "".join(bump(d) for d in rows[0][:PLACES])           # bumped row 1, not the diagonal
trap = "".join(bump(d) for d in "49999")                      # a list of 0.4999... rows
print(f"the three mistakes come out at 0.{diagonal}, 0.{across} and 0.{trap}")
assert diagonal == "".join(str((p * 10 ** (i + 1) // q) % 10) for i, (p, q) in enumerate(GUESTS))
assert safer == "44444" and all(safer[i] != rows[i][i] for i in range(PLACES))
assert int(built) == 21461 and all(built[i] != rows[i][i] for i in range(PLACES))
print("ALL CHECKS PASS")
