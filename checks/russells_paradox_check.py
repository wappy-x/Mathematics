# Russell's paradox -- the check behind the card.  Nothing is imported.  Three
# villagers: Ada shaves herself, Ben does not, Cyd is the barber who shaves the
# villagers who do not shave themselves.  Then the same trap again, for sets.
VILLAGERS = ["Ada", "Ben", "Cyd"]
LISTS = [[v for i, v in enumerate(VILLAGERS) if n >> i & 1] for n in range(8)]
SETS = [frozenset(l) for l in LISTS]           # the second road: sets, not barbers

def shaves_self(v, lst): return v == "Ada" or (v == "Cyd" and "Cyd" in lst)
def promise_ok(v, lst): return (v in lst) == (not shaves_self(v, lst))
def row(name, value): print(f"{name:<46}{value:>2}")

kept = sum(1 for l in LISTS if all(promise_ok(v, l) for v in VILLAGERS))
others = sum(1 for l in LISTS if promise_ok("Ada", l) and promise_ok("Ben", l))
broken = sum(1 for l in LISTS if not promise_ok("Cyd", l))
holders = sum(1 for s in SETS if s in s)       # a real self-membership test
russell = frozenset(s for s in SETS if s not in s)
biggest = max(len(s) for s in SETS)
row("villagers in the village", len(VILLAGERS))
row("lists of villagers there are, in all", len(LISTS))
row("lists that get Ada and Ben right", others)
row("lists that keep the barber's whole promise", kept)
row("lists that break it at the barber himself", broken)
row("of the eight sets, ones that hold themselves", holders)
row("the Russell set, how many it holds", len(russell))
row("the most members any one of the eight holds", biggest)
row("how many of the eight hold eight", sum(1 for s in SETS if len(s) == 8))
row("the Russell set found among the eight", int(russell in SETS))
assert len(LISTS) == 8 and others == 2 and kept == 0 and broken == 8
assert holders == 0 and len(russell) == 8 and biggest == 3 and russell not in SETS
print("ALL CHECKS PASS")
