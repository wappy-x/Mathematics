# One-to-one and onto -- the check behind the card.  Nothing is imported.  The
# 24-hour clock read onto a 12-hour dial, then eight guests seated two ways.
# Route 1 reads the arrows forwards; route 2 counts the arrivals at each output.
DIAL, SEATS, TEN = list(range(1, 13)), list(range(1, 9)), list(range(1, 11))
def dial(h): return h % 12 if h % 12 else 12   # 00:00 and 12:00 both give dial 12
def arrivals(pairs, codomain):                 # route 2: inputs landing on each output
    return [sum(1 for _, b in pairs if b == c) for c in codomain]
def verdict(pairs, codomain):
    hits = [b for _, b in pairs]
    assert set(hits) <= set(codomain), "an output landed outside the codomain"
    one_to_one, onto = len(set(hits)) == len(pairs), set(codomain) <= set(hits)   # route 1
    n = arrivals(pairs, codomain)
    assert (one_to_one, onto) == (max(n) <= 1, min(n) >= 1)                       # the routes agree
    return ("one-to-one" if one_to_one else "not one-to-one") + (" and onto" if onto else " and not onto")
def show(label, pairs, codomain, unit):
    n = arrivals(pairs, codomain)
    print(f"{label}: {verdict(pairs, codomain)}")
    print(f"  arrivals at each {unit}: {' '.join(str(x) for x in n)} -- {sum(n)} in total, {n.count(0)} with none arriving")
clock, seated = [(h, dial(h)) for h in range(24)], [(g, g) for g in range(1, 9)]   # guest 1 in seat 1, and so on
nine, crowd = seated + [(9, 1)], [(g, s) for g, s in zip(range(1, 9), [1, 2, 3, 3, 5, 6, 7, 8])]   # a ninth guest; two guests take seat 3
show("the clock, 24 hours (0 to 23) onto 12 dial numbers", clock, DIAL, "dial number")
print(f"  01:00 gives dial {dial(1)}, 13:00 gives dial {dial(13)}, 12:00 gives dial {dial(12)}, 00:00 gives dial {dial(0)}")
show("eight guests, eight numbered seats", seated, SEATS, "seat")
show("the same eight guests in a ten-seat row", seated, TEN, "seat")
print(f"breaks: nine guests into eight seats -- {verdict(nine, SEATS)}, one seat holds {max(arrivals(nine, SEATS))}")
print(f"breaks: two guests crowd seat 3 -- {verdict(crowd, SEATS)}, {8 - arrivals(crowd, SEATS).count(0)} seats of 8 filled")
assert verdict(clock, DIAL) == "not one-to-one and onto" and arrivals(clock, DIAL) == [2] * 12
assert verdict(seated, SEATS) == "one-to-one and onto" and verdict(seated, TEN) == "one-to-one and not onto"
assert max(arrivals(nine, SEATS)) == 2 and arrivals(crowd, SEATS).count(0) == 1 and sum(arrivals(clock, DIAL)) == 24
print("ALL CHECKS PASS")
