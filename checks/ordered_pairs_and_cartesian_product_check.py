# Ordered pairs and the Cartesian product -- the check behind the card.  Nothing
# is imported.  A deck is every (suit, rank) pair: 4 suits, 13 ranks, 52 cards.
# The cafe menu is every (drink, pastry) pair: 2 drinks, 3 pastries, 6 combos.
SUITS = ["clubs", "diamonds", "hearts", "spades"]
RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
def product(first, second):        # every member of first with every member of second
    return {(a, b) for a in first for b in second}
def row(name, value):
    print(f"{name:<34}{value:>5}")
deck = product(SUITS, RANKS)
flipped = product(RANKS, SUITS)              # the same combinations, slots swapped
by_suit = sum(len(RANKS) for suit in SUITS)  # the second road: 13 + 13 + 13 + 13
menu = product(["coffee", "tea"], ["croissant", "scone", "muffin"])
LISTED = {("coffee", "croissant"), ("coffee", "scone"), ("coffee", "muffin"),
          ("tea", "croissant"), ("tea", "scone"), ("tea", "muffin")}
row("suits in a deck", len(SUITS))
row("ranks in a suit", len(RANKS))
row("cards, 4 suits times 13 ranks", len(deck))
row("cards, counted a suit at a time", by_suit)
row("(hearts, king) is a card", str(("hearts", "king") in deck))
row("(king, hearts) is a card", str(("king", "hearts") in deck))
row("cards the two orders share", len(deck & flipped))
row("combos, 2 drinks times 3 pastries", len(menu))
row("combos, listed one by one", len(LISTED))
row("4 suits times no ranks at all", len(product(SUITS, [])))
print(f"the two mistakes come out at {len(SUITS) + len(RANKS)} and {len(SUITS) * (len(RANKS) - 1)}")
assert len(deck) == 52 and by_suit == 52 and len(deck) == by_suit
assert ("hearts", "king") in deck and ("king", "hearts") not in deck and len(deck & flipped) == 0
assert menu == LISTED and len(product(SUITS, [])) == 0
print("ALL CHECKS PASS")
