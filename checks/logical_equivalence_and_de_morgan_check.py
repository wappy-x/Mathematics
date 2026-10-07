# Logical equivalence and De Morgan -- the check behind the card.  Nothing is imported.
# Four dishes, one per way nuts and dairy can fall.  Each sentence is worked twice: with
# and/or/not, then with 1s and 0s (and = the smaller, or = the larger, not = 1 minus it).
DISHES = [(1, 1), (1, 0), (0, 1), (0, 0)]        # (nuts, dairy); 1 means yes

def word(v): return "yes" if v else "no"
def line(cells): return "".join(f"{c:<{w}}" for c, w in zip(cells, (6, 6, 7, 23, 22, 23, 0)))
def same(x, y): return sum(1 for p, q in zip(x, y) if p == q)

note, customer, notboth, either = [], [], [], []
print(line(("dish", "nuts", "dairy", "no nuts and no dairy", "not (nuts or dairy)", "not (nuts and dairy)", "(no nuts) or (no dairy)")))
for i, (n, d) in enumerate(DISHES, 1):
    a = (not n) and (not d)                      # the menu note, read straight
    b = not (n or d)                             # her reading -- law 1's other side
    c = not (n and d)                            # "not both nuts and dairy"
    e = (not n) or (not d)                       # law 2's other side
    assert int(a) == min(1 - n, 1 - d) and int(b) == 1 - max(n, d) and a == b        # law 1
    assert int(c) == 1 - min(n, d) and int(e) == max(1 - n, 1 - d) and c == e        # law 2
    note.append(int(a)); customer.append(int(b)); notboth.append(int(c)); either.append(int(e))
    print(line((i, word(n), word(d), word(a), word(b), word(c), word(e))))
print(f"{'rows checked':<44}{len(DISHES)}")
print(f"{'rows where law 1 holds':<44}{same(note, customer)}")
print(f"{'rows where law 2 holds':<44}{same(notboth, either)}")
print(f"{'dishes the menu note lets through':<44}{sum(note)}")
print(f"{'dishes not-both lets through':<44}{sum(notboth)}")
print(f"{'rows where not-both and the note disagree':<44}{len(DISHES) - same(note, notboth)}")
assert note == [0, 0, 0, 1] and customer == [0, 0, 0, 1] and notboth == [0, 1, 1, 1] and either == [0, 1, 1, 1]
assert same(note, customer) == 4 and same(notboth, either) == 4 and same(note, notboth) == 2
assert sum(note) == 1 and sum(notboth) == 3
print("ALL CHECKS PASS")
