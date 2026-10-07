# Quantifiers -- the check behind the card.  Nothing is imported.  An office of
# six people and the three keys they carry.  Each claim is scanned twice: once
# across the people, once down the keys.
KEYS = ["front", "store", "server"]
OFFICE = ["Ana", "Ben", "Cara", "Dev", "Eve", "Finn"]
CARRIES = {"Ana": ["front", "store"], "Ben": ["front"], "Cara": ["front", "server"],
           "Dev": ["front"], "Eve": ["front", "server"], "Finn": ["store"]}
def keys_of(person): return len(CARRIES[person])                 # keys this one carries
def holders_of(key, people): return sum(1 for p in people if key in CARRIES[p])
def row(name, value): print(f"{name:<46}{str(value):>5}")
def verdicts(people, pad):              # the two claims, on whichever room we hand it
    reach = max(holders_of(k, people) for k in KEYS)
    has_key, master = min(keys_of(p) for p in people) >= 1, reach == len(people)
    row(pad + "everyone has a key", has_key)
    row(pad + "there is one key everyone has", master)
    row(pad + "largest reach of any one key", reach)
    return has_key, master, reach

across = sum(keys_of(p) for p in OFFICE)           # carryings, added across the people
down = sum(holders_of(k, OFFICE) for k in KEYS)    # the same carryings, added down keys
row(f"people {len(OFFICE)}, keys {len(KEYS)}, carryings added across", across)
print("keys carried, person by person   " + "  ".join(f"{p} {keys_of(p)}" for p in OFFICE))
print("people reached, key by key       " + "  ".join(f"{k} {holders_of(k, OFFICE)}" for k in KEYS))
row("the same carryings added down the keys", down)
full = verdicts(OFFICE, "")
print("shrink the office to the five who carry front")
small = verdicts(OFFICE[:5], "  ")
assert across == 9 and down == across
assert full == (True, False, 5) and small == (True, True, 5)
print("ALL CHECKS PASS")
