# If-then -- the check behind the card.  Nothing is imported.  The phone
# warranty: "if the screen cracks in the first year, we replace it free."
# Four customers, 1 for yes and 0 for no.  Two routes to the same column.
CASES = [("Ana", 1, 1), ("Ben", 1, 0), ("Cal", 0, 1), ("Dee", 0, 0)]

def kept(crack, free):        # broken only when it cracked and was not replaced
    return 0 if crack == 1 and free == 0 else 1

def or_route(crack, free):    # second route: no crack, or a free replacement
    return 1 if crack == 0 or free == 1 else 0

print(f"{'name':<5}{'crack':>7}{'free':>6}{'if-then':>9}{'not-crack-or-free':>19}{'converse':>10}{'contra':>8}")
promise, second, converse, contra = [], [], [], []
for name, crack, free in CASES:
    promise.append(kept(crack, free))
    second.append(or_route(crack, free))
    converse.append(kept(free, crack))            # if replaced free, then it cracked
    contra.append(kept(1 - free, 1 - crack))      # if not replaced free, then no crack
    print(f"{name:<5}{crack:>7}{free:>6}{promise[-1]:>9}{second[-1]:>19}{converse[-1]:>10}{contra[-1]:>8}")
broken = sum(1 for v in promise if v == 0)
conv_gap = sum(1 for a, b in zip(promise, converse) if a != b)
con_gap = sum(1 for a, b in zip(promise, contra) if a != b)
print(f"customers checked {len(CASES)}")
print(f"rows where the warranty is broken {broken}")
print(f"converse disagrees on rows {conv_gap}")
print(f"contrapositive disagrees on rows {con_gap}")
assert len(promise) == 4 and promise == [1, 0, 1, 1] and second == promise
assert converse == [1, 1, 0, 1] and conv_gap == 2
assert contra == [1, 0, 1, 1] and con_gap == 0 and broken == 1
print("ALL CHECKS PASS")
