# Round tables and bracelets -- the check behind the card.  Nothing is imported.
# Eight guests sit round one table; six different beads hang on one bracelet.
# Every count is reached twice: once from the factorial, once by listing every
# order in a row and sorting that whole list into classes.
def fact(n):                                   # n!, written out rather than imported
    out = 1
    for k in range(2, n + 1): out *= k
    return out

def orders(items):                             # every order of the items in a row
    if len(items) <= 1: return [tuple(items)]
    out = []
    for i in range(len(items)): out += [(items[i],) + r for r in orders(items[:i] + items[i + 1:])]
    return out

def distinct(items):                           # repeated items make the same order twice
    return sorted(set(orders(items)))
def turns(s):                                  # the rotations of one order
    return [s[k:] + s[:k] for k in range(len(s))]

def tag(s, flip):                              # one name shared by a whole class
    return min(turns(s) + (turns(s[::-1]) if flip else []))

def classes(seqs, flip):                       # class name -> how many orders it holds
    out = {}
    for t in [tag(s, flip) for s in seqs]: out[t] = out.get(t, 0) + 1
    return out

def size(cls):                                 # the size every class shares, 0 if they differ
    return min(cls.values()) if len(set(cls.values())) == 1 else 0
def mirrors(cls):                              # classes unchanged by turning the ring over
    return sum(1 for t in cls if tag(t[::-1], False) == t)

table, four = distinct(tuple(range(8))), distinct(tuple(range(4)))
beads, three = distinct(tuple(range(6))), distinct(tuple(range(3)))
mixed = distinct((0, 0, 1, 1, 2, 3))           # beads R R B B G Y
seatings, small = classes(table, False), classes(four, False)
necks, bracs = classes(beads, False), classes(beads, True)
mneck, mbrac = classes(mixed, False), classes(mixed, True)
fixed = sum(1 for s in table if s[0] == 0)     # guest 0 nailed to one chair
print(f"8 guests in 8 numbered chairs: 8! = {len(table)} orders in a row")
print(f"one seating turns up once per rotation: classes of {size(seatings)}")
print(f"{len(table)} / {size(seatings)} = {len(seatings)} seatings round the table, and 7! = {fact(7)}")
print(f"nailing one guest to one chair and ordering the other 7: {fixed}")
print(f"treating clockwise and anticlockwise as one would give {len(seatings) // 2}, not {len(seatings)}")
print(f"4 guests, the picture: 4! = {len(four)} orders, {len(four)} / 4 = {len(small)} seatings")
print(f"6 different beads: 6! = {len(beads)} orders, {len(beads)} / 6 = {len(necks)} necklaces")
print(f"turning the ring over pairs them off: {len(necks)} / 2 = {len(bracs)} bracelets, and 5!/2 = {fact(5) // 2}")
print(f"brute force, orders sorted into turn-or-flip classes: {len(bracs)} classes of {size(bracs)}")
print(f"necklaces of 6 different beads unchanged by the flip: {mirrors(necks)}")
print(f"3 different beads: {len(classes(three, False))} necklaces, {len(classes(three, True))} bracelet")
print(f"beads R R B B G Y: {len(mixed)} different orders, {len(mneck)} necklaces")
print(f"halving those {len(mneck)} gives {len(mneck) // 2}, but brute force finds {len(mbrac)} bracelets")
print(f"{mirrors(mneck)} necklaces are unchanged by the flip: ({len(mneck)} + {mirrors(mneck)}) / 2 = {len(mbrac)}")
assert len(table) == fact(8) and len(seatings) == fact(7) and fixed == fact(7)
assert size(seatings) == 8 and len(seatings) * size(seatings) == len(table)
assert len(necks) == fact(5) and len(bracs) == fact(5) // 2 and mirrors(necks) == 0
assert 2 * len(mbrac) == len(mneck) + mirrors(mneck) and len(mbrac) != len(mneck) // 2
print("ALL CHECKS PASS")
