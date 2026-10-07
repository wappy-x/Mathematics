# Rooted trees -- the check behind the card.  Nothing is imported.  A 16-team knockout drawn as a binary tree:
# the final is the root, the 15 matches are the inner vertices, the 16 teams are the leaves.  Counts come by two
# roads sharing no arithmetic -- the tree built and scanned, and left/right addresses listed with no tree at all.
HEIGHT, SIZES = 4, {"jan.jpg": 4, "feb.jpg": 2, "mar.jpg": 5, "apr.jpg": 3}
FOLDER = ("photos", ("2025", ("jan.jpg", None, None), ("feb.jpg", None, None)),
                    ("2026", ("mar.jpg", None, None), ("apr.jpg", None, None)))
KEYS = ("4", ("2", ("1", None, None), ("3", None, None)), ("6", ("5", None, None), ("7", None, None)))
def full(h, a=""):                          # road one: the bracket, each vertex labelled by its address
    return (a, None, None) if h == 0 else (a, full(h - 1, a + "L"), full(h - 1, a + "R"))
def addresses(h):                           # road two: every address of length 0 to h, no tree at all
    out = [""]
    for k in range(h): out += [a + c for a in out if len(a) == k for c in "LR"]
    return out
def walk(t, order):                         # the card's three rules, each calling itself on a subtree
    if t[1] is None: return [t[0]]
    a, b, v = walk(t[1], order), walk(t[2], order), [t[0]]
    return v + a + b if order == "pre" else (a + v + b if order == "in" else a + b + v)
def mirror(t):                              # left and right swapped, all the way down
    return t if t[1] is None else (t[0], mirror(t[2]), mirror(t[1]))
def scan(t, d=0):                           # every vertex: its label, its depth, and leaf or not
    if t[1] is None: return [(t[0], d, True)]
    return [(t[0], d, False)] + scan(t[1], d + 1) + scan(t[2], d + 1)
def total(t, out):                          # post-order: a folder's megabytes, its contents finished first
    if t[1] is None: return SIZES[t[0]]
    mb = total(t[1], out) + total(t[2], out); out.append(f"{t[0]} {mb} MB"); return mb
def direct(t, out):                         # the mistake: totalled on the way in, loose files only
    if t[1] is None: return
    out.append(f"{t[0]} {sum(SIZES[c[0]] for c in (t[1], t[2]) if c[1] is None)} MB")
    direct(t[1], out); direct(t[2], out)
def dist(a, b):                             # steps between two vertices, read off their addresses
    return len(a) + len(b) - 2 * sum(1 for i in range(min(len(a), len(b))) if a[:i + 1] == b[:i + 1])
bracket, addrs, closed = full(HEIGHT), addresses(HEIGHT), 2 ** (HEIGHT + 1) - 1
s = scan(bracket); level = [sum(1 for x in s if x[1] == k) for k in range(HEIGHT + 1)]
teams, matches = [v for v, d, f in s if f], [v for v, d, f in s if not f]
lad = ("team 1", None, None)
for i in range(2, 17): lad = (f"match {i - 1}", lad, (f"team {i}", None, None))
ls, fs, tot, early = scan(lad), scan(FOLDER), [], []; total(FOLDER, tot); direct(FOLDER, early)
swaps = walk(mirror(FOLDER), "pre")[::-1] == walk(FOLDER, "post") and walk(mirror(FOLDER), "post")[::-1] == walk(FOLDER, "pre") and walk(mirror(FOLDER), "in")[::-1] == walk(FOLDER, "in")
print(f"bracket rooted at the final: height {max(x[1] for x in s)}, {len(s)} vertices, {len(s) - 1} edges")
print(f"vertices at depths 0 to {HEIGHT}: {' '.join(str(c) for c in level)}, adding to {sum(level)}")
print(f"the same total by doubling: 2^{HEIGHT + 1} - 1 = {closed}, leaves 2^{HEIGHT} = {2 ** HEIGHT}, inner 2^{HEIGHT} - 1 = {2 ** HEIGHT - 1}")
print(f"the tree walked instead: {len(teams)} teams at the leaves, {len(matches)} matches inside, so matches = teams - 1 = {len(teams) - 1}")
print(f"addresses of length 0 to {HEIGHT}, listed with no tree: {len(addrs)}; sorted, they are the pre-order: {'yes' if sorted(addrs) == walk(bracket, 'pre') else 'no'}")
print(f"the same {len(s)} vertices rooted at one team instead: height {max(dist('L' * HEIGHT, a) for a in addrs)}")
print(f"folder tree: {len(fs)} vertices, height {max(x[1] for x in fs)}, {len(fs) - len(SIZES)} folders, {len(fs) - 1} edges, files " + ", ".join(f"{k} {v} MB" for k, v in SIZES.items()))
for label, rule in (("pre-order,  the folder before its contents:", "pre"), ("in-order,   left, the folder, right:", "in"), ("post-order, the contents before the folder:", "post")):
    print(f"  {label:<43} {' '.join(walk(FOLDER, rule))}")
print(f"mirrored, then read backwards: pre-order swaps with post-order and in-order is unchanged: {'yes' if swaps else 'no'}")
print(f"megabytes finished in post-order: {', '.join(tot)}")
print(f"keys 1 to 7 set smaller-left, read in-order: {' '.join(walk(KEYS, 'in'))}")
print(f"mistake 1, five levels read as the height: 2^{HEIGHT + 2} - 1 = {2 ** (HEIGHT + 2) - 1}, not {closed}")
print(f"mistake 2, that formula on a knockout with byes: the ladder stands {max(x[1] for x in ls)} deep, so 2^16 - 1 = {2 ** 16 - 1}, where it holds {len(ls)} vertices and {sum(1 for x in ls if not x[2])} matches")
print(f"mistake 3, folders totalled on the way in: {', '.join(early)}")
assert sorted(addrs) == walk(bracket, "pre") and len(addrs) == closed == sum(level) and max(dist("L" * HEIGHT, a) for a in addrs) == 2 * HEIGHT and dist("LLLL", "LLLR") == 2
assert level == [2 ** k for k in range(HEIGHT + 1)] and len(matches) == len(teams) - 1 == 15
assert walk(KEYS, "in") == sorted(walk(KEYS, "pre")) and swaps
assert sum(1 for x in ls if not x[2]) == len(matches) and max(x[1] for x in ls) == 15 and tot == ["2025 6 MB", "2026 8 MB", "photos 14 MB"]
print("ALL CHECKS PASS")
