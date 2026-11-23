# F-algebras and folds -- the check behind the card.  Nothing is imported.
# The expression type is a functor F: one layer, a literal or an operator over
# two holes.  fold is the only recursive function the algebras use; every job
# on the tree is an algebra, one step of rules handed to fold.  No functools.reduce.

def fmap(f, layer):                     # F on arrows: apply f to each hole, keep the shape
    return layer if layer[0] == "lit" else (layer[0], f(layer[1]), f(layer[2]))

def In(layer): return ("T", layer)      # in: one layer of trees becomes a tree
def out(tree): return tree[1]           # out: read a tree's top layer back

def fold(alg, tree):                    # fold the children first, then one step of alg
    return alg(fmap(lambda child: fold(alg, child), out(tree)))

lit = lambda n: In(("lit", n))          # the three ways to build one layer
node = lambda op, a, b: In((op, a, b))

def evaluate(l):                        # the algebra on whole numbers
    return l[1] if l[0] == "lit" else l[1] + l[2] if l[0] == "add" else l[1] * l[2]

def clock(m):                           # the same rules on an m-hour clock
    return lambda l: l[1] % m if l[0] == "lit" else evaluate(l) % m

size = lambda l: 1 if l[0] == "lit" else 1 + l[1] + l[2]
height = lambda l: 0 if l[0] == "lit" else 1 + max(l[1], l[2])
show = lambda l: str(l[1]) if l[0] == "lit" else f"({l[1]} {'+' if l[0] == 'add' else '*'} {l[2]})"

def drop_digit(l):                      # leaves lose their last digit, operators kept
    return l[1] // 10 if l[0] == "lit" else evaluate(l)

def postorder(t):                       # road two: the walk from Rooted trees, no fold
    l = out(t)
    return [l[1]] if l[0] == "lit" else postorder(l[1]) + postorder(l[2]) + [l[0]]

def stack_run(tokens):                  # evaluate the post-order list with a stack
    stack = []
    for tok in tokens:
        if tok in ("add", "mul"):
            b, a = stack.pop(), stack.pop()
            stack.append(a + b if tok == "add" else a * b)
        else:
            stack.append(tok)
    return stack[0]

def fold_list(nil, cons, xs):           # the list functor 1 + N x X, and its fold
    return nil if not xs else cons(xs[0], fold_list(nil, cons, xs[1:]))

def receipt(p):                         # 3 coffees at p pence, 2 sandwiches at 240 pence
    return node("add", node("mul", lit(3), lit(p)), node("mul", lit(2), lit(240)))

t, log = receipt(125), []
def traced(l):
    v = evaluate(l)
    log.append(f"  {l[0]} {' '.join(str(x) for x in l[1:])} -> {v}")
    return v
total = fold(traced, t)
rpn = postorder(t)
lines = [out(q)[1] * out(p)[1] for _, q, p in (out(s) for s in out(t)[1:])]   # road three: each line read off
via_list = fold_list(0, lambda x, acc: x + acc, lines)                          # the tree, then a list fold
print("expression: 3 x 125 + 2 x 240, prices in pence")
print(f"tree, printed by a fold: {fold(show, t)}")
print(f"fold, evaluate: {total} pence = £{total // 100}.{total % 100:02d}")
print(f"fold, count nodes: {fold(size, t)}; fold, height: {fold(height, t)}")
print(f"fold, the 10-hour clock: {fold(clock(10), t)}")
print("the evaluate fold, in the order its steps run:")
for line in log:
    print(line)
print(f"road two, a stack run on the post-order list {' '.join(str(x) for x in rpn)}: {stack_run(rpn)}")
print(f"road three, a list fold over the line totals read off the tree, {lines}: {via_list}")

X = range(5)                            # functor laws on every layer over {0, 1, 2, 3, 4}
layers = [("lit", 2), ("lit", 3)] + [(op, a, b) for op in ("add", "mul") for a in X for b in X]
f, g = (lambda x: (x + 1) % 5), (lambda x: 2 * x % 5)
ident = all(fmap(lambda x: x, l) == l for l in layers)
comp = all(fmap(lambda x: g(f(x)), l) == fmap(g, fmap(f, l)) for l in layers)
print(f"functor laws on all {len(layers)} layers over 0 to 4: identity {'yes' if ident else 'no'}, composition {'yes' if comp else 'no'}")

levels = [[]]                           # F applied k times to the empty set, leaves 2 and 3
for k in range(3):
    prev = levels[-1]
    levels.append([lit(2), lit(3)] + [node(op, a, b) for op in ("add", "mul") for a in prev for b in prev])
rec = [0]
for k in range(4):
    rec.append(2 + 2 * rec[-1] ** 2)
print(f"trees built in k layers, k = 0 to 3, by listing: {[len(x) for x in levels]}")
print(f"the same by the count a(k+1) = 2 + 2 a(k)^2, k = 0 to 4: {rec}")
trees = levels[3]
lambek = all(In(out(s)) == s and fold(lambda l: fmap(In, l), s) == out(s) for s in trees)
same_eval = all(fold(evaluate, s) == stack_run(postorder(s)) for s in trees)
fusion = all(fold(clock(10), s) == fold(evaluate, s) % 10 for s in trees)
same_size = all(fold(size, s) == len(postorder(s)) for s in trees)
print(f"on all {len(trees)} trees: in undoes out, and out is a fold: {'yes' if lambek else 'no'}")
print(f"on all {len(trees)} trees: evaluate fold = stack run {'yes' if same_eval else 'no'}; "
      f"clock fold = last digit of evaluate {'yes' if fusion else 'no'}; size = list length {'yes' if same_size else 'no'}")

def commuting(m, small):                # every map small -> m-hour clock, tested on the square
    good = []
    for code in range(m ** len(small)):
        h = [code // m ** i % m for i in range(len(small))]
        look = lambda c: h[small.index(c)]
        if all(h[i] == clock(m)(fmap(look, out(s))) for i, s in enumerate(small)):
            good.append(h)
    return good

small = levels[2]
good = commuting(3, small)
print(f"maps from the {len(small)} trees of height at most 1 to the 3-hour clock: {3 ** len(small)}; "
      f"squares commuting: {len(good)}; it is the fold: {'yes' if good == [[fold(clock(3), s) for s in small]] else 'no'}")

toks = fold(lambda l: [l[1]] if l[0] == "lit" else l[1] + [l[0]] + l[2], t)   # the bill's tokens, brackets lost
flat = toks[0]                          # a calculator with no precedence: each operator as it comes
for op, x in zip(toks[1::2], toks[2::2]):
    flat = flat + x if op == "add" else flat * x
subsets, sizes = [[]], [1]              # list every subset of {0, ..., 4}: each member left out, or put in
for x in range(5):
    subsets = subsets + [s + [x] for s in subsets]
    sizes.append(len(subsets))
dropped = fold(drop_digit, t)
cells = {"A1": ("add", ("ref", "B1"), ("lit", 1)), "B1": ("mul", ("lit", 2), ("ref", "A1"))}
path, cell = ["A1"], "A1"
while True:
    nxt = [e[1] for e in cells[cell][1:] if e[0] == "ref"][0]
    if nxt in path:
        break
    path.append(nxt)
    cell = nxt
print(f"mistake 1, a calculator read left to right over {' '.join(str(x) for x in toks)}: {flat}")
print(f"mistake 2, fusing 'drop the last digit', no algebra map: fold gives {dropped}, but {total} drops to {total // 10}")
print(f"mistake 3, A1 = B1 + 1 and B1 = 2 x A1: unfolding {' -> '.join(path + [nxt])} meets A1 again after {len(path)} steps: a cycle, no finite tree, no fold")
print(f"no initial algebra for the power-set functor: subsets listed for sets of 0 to 5 members: {sizes}, never n")
print(f"try: price 140 gives {fold(evaluate, receipt(140))}; the 7-hour clock gives {fold(clock(7), t)}; "
      f"the 2-hour clock: {2 ** len(small)} maps, {len(commuting(2, small))} commuting")
assert total == stack_run(rpn) == via_list                      # three roads to the total
assert ident and comp and lambek                                 # functor laws, Lambek
assert same_eval and fusion and same_size                        # fold against walk, on 202 trees
assert [len(x) for x in levels] == rec[:4]                       # listing against the count
assert len(good) == 1 and good[0] == [fold(clock(3), s) for s in small]   # uniqueness, by brute force
assert dropped != total // 10 and flat != total                  # the mistakes really differ
assert sizes == [2 ** n for n in range(6)]                       # the listing against 2^n
print("ALL CHECKS PASS")
