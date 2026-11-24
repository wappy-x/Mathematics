# Games in turns -- the check behind the card.  Nothing is imported.  A rival bakery
# goes In next to one of the chain's shops or stays Out; after In the chain will Fight
# (price war) or Accommodate.  Synthetic pounds a month, (rival, chain): Out (0, 2000),
# Fight (-1000, -1000), Accommodate (1000, 1000).  Roads: (1) backward induction; (2)
# every profile tested for Nash and subgame perfection; (3) a threat's belief threshold.
OUT, FIGHT, ACC = (0, 2000), (-1000, -1000), (1000, 1000)

def chain_store(towns, acc_chain=ACC[1]):    # flat tree of (player, payoffs, kids); leaf: -1
    nodes = []                                # players 0..towns-1 are rivals, `towns` the chain
    def build(k, pay):
        i = len(nodes)
        nodes.append(None)
        if k == towns:
            nodes[i] = (-1, tuple(pay), [])
            return i
        def add(rival, chain):                 # town k's payoffs go to rival k and the chain
            return build(k + 1, [v + (rival if n == k else chain if n == towns else 0) for n, v in enumerate(pay)])
        c = len(nodes)
        nodes.append(None)
        nodes[c] = (towns, None, [add(*FIGHT), add(ACC[0], acc_chain)])
        nodes[i] = (k, None, [c, add(*OUT)])
        return i
    build(0, [0] * (towns + 1))
    return nodes

def solve(nodes, i, plan, visits):            # road 1: backward induction
    visits[0] += 1
    player, pay, kids = nodes[i]
    if player < 0:
        return pay
    values = [solve(nodes, c, plan, visits) for c in kids]
    plan[i] = max(range(len(kids)), key=lambda j: (values[j][player], -j))   # ties: first child
    return values[plan[i]]

def run(nodes):
    plan, visits = [0] * len(nodes), [0]
    return plan, solve(nodes, 0, plan, visits), visits[0]

def play(nodes, i, prof):                     # follow a profile down to a leaf
    while nodes[i][0] >= 0:
        i = nodes[i][2][prof[i]]
    return nodes[i][1]

def stable(nodes, h, prof, owners):           # nobody gains by changing own moves, from h
    for p, own in owners.items():
        base = play(nodes, h, prof)[p]
        for bits in range(2 ** len(own)):
            alt = list(prof)
            for b, n in enumerate(own):
                alt[n] = bits >> b & 1
            if play(nodes, h, alt)[p] > base:
                return False
    return True

def exhaustive(nodes):                        # road 2: every profile, tested
    dec = [i for i, n in enumerate(nodes) if n[0] >= 0]
    owners = {}
    for i in dec:
        owners.setdefault(nodes[i][0], []).append(i)
    ne, spe = [], []
    for bits in range(2 ** len(dec)):
        prof = [0] * len(nodes)
        for b, n in enumerate(dec):
            prof[n] = bits >> b & 1
        if stable(nodes, 0, prof, owners):
            ne.append(prof)
            if all(stable(nodes, h, prof, owners) for h in dec):
                spe.append(prof)
    return dec, ne, spe

def layout(nodes, i, depth, xs, pos):         # figure: leaves 110 apart, parents centred
    if nodes[i][0] < 0:
        x = 70 + 110 * len(xs)
        xs.append(x)
    else:
        x = sum(layout(nodes, c, depth + 1, xs, pos)[0] for c in nodes[i][2]) / 2
    pos[i] = (x, 40 + 80 * depth)
    return pos[i]

fmt = lambda p: "(" + ", ".join(str(v) for v in p) + ")"
MOVES = [("In", "Out"), ("Fight", "Accommodate")]
g = chain_store(1)
plan, spe_pay, visits = run(g)
print(f"entry game: {len(g)} nodes, payoffs listed (rival, chain)")
print(f"chain's node: Fight gives the chain {FIGHT[1]}, Accommodate {ACC[1]} -> {MOVES[1][plan[1]]}")
print(f"rival's node: In gives the rival {ACC[0]}, Out {OUT[0]} -> {MOVES[0][plan[0]]}")
print(f"road 1, backward induction: rival {MOVES[0][plan[0]]}, chain {MOVES[1][plan[1]]}, payoffs {fmt(spe_pay)}, nodes visited {visits}")
dec, ne, spe = exhaustive(g)
name = lambda p: f"rival {MOVES[0][p[0]]} / chain {MOVES[1][p[1]]} {fmt(play(g, 0, p))}"
print(f"road 2, all {2 ** len(dec)} profiles, Nash equilibria: " + "; ".join(name(p) for p in ne))
print(f"road 2, subgame perfect: " + "; ".join(name(p) for p in spe) + f"; matches road 1: {'yes' if spe == [plan] else 'no'}")
q_formula = (ACC[0] - OUT[0]) / (ACC[0] - FIGHT[0])
j = 0
while j * FIGHT[0] + (100 - j) * ACC[0] > 100 * OUT[0]:
    j += 1
print(f"road 3, belief in a fight that keeps the rival out: formula {ACC[0] - OUT[0]}/{ACC[0] - FIGHT[0]} = {q_formula:.2f}; grid {j}/100 = {j / 100:.2f}")
print(f"rival's expected gain from In if a fight is believed 0.40 likely: {(40 * FIGHT[0] + 60 * ACC[0]) // 100}; 0.60 likely: {(60 * FIGHT[0] + 40 * ACC[0]) // 100}")
com = [(pen, run(chain_store(1, ACC[1] - pen))) for pen in (2500, 1500)]
for pen, (cplan, cpay, _) in com:
    print(f"commitment, penalty {pen}: Accommodate pays the chain {ACC[1]} - {pen} = {ACC[1] - pen}; chain {MOVES[1][cplan[1]]}, "
          f"rival {MOVES[0][cplan[0]]}, payoffs {fmt(cpay)}; worth {cpay[1] - spe_pay[1]} a month to the chain")
g2 = chain_store(2)
plan2 = run(g2)[0]
dec2, ne2, spe2 = exhaustive(g2)
same2 = len(spe2) == 1 and all(spe2[0][i] == plan2[i] for i in dec2)
print(f"two towns: {2 ** len(dec2)} profiles, {len(ne2)} Nash equilibria, {len(spe2)} subgame perfect; matches road 1: {'yes' if same2 else 'no'}")
g3 = chain_store(3)
plan3, pay3, visits3 = run(g3)
d3 = sum(1 for n in g3 if n[0] >= 0)
print(f"three towns: backward induction visits {visits3} nodes ({d3} decisions, {visits3 - d3} leaves); the table has 2^{d3} = {2 ** d3} profiles")
last = [i for i, n in enumerate(g3) if n[0] == 3 and g3[n[2][0]][0] < 0]
print(f"three towns, payoffs {fmt(pay3)}; town-3 chain nodes {len(last)}, accommodating at {sum(plan3[i] for i in last)}")
scared = [1 if n[0] in (0, 1, 2) else 0 for n in g3]          # every rival Out, chain Fight
early = plan3[:1] + [0] + plan3[2:]                            # chain fights in town 1 only
print(f"if every rival believed 'always fight': chain {play(g3, 0, scared)[3]}; fighting in town 1, then accommodating: chain {play(g3, 0, early)[3]}")
TAKES, END = [(4, 1), (2, 8), (16, 4), (8, 32)], (64, 16)
cen = []
for m, pay in enumerate(TAKES):
    cen += [(m % 2, None, [2 * m + 1, 2 * m + 2]), (-1, pay, [])]
cen.append((-1, END, []))
cplan2, cval, _ = run(cen)
print(f"centipede: backward induction takes at move {cplan2[0] + 1} with {fmt(cval)}; passing to the end pays {fmt(END)}")
ult = [(0, None, [])]                                          # offers 0..100 tenpences of 1000p
for o in range(101):
    ult[0][2].append(len(ult))
    ult += [(1, None, [len(ult) + 1, len(ult) + 2]), (-1, (0, 0), []), (-1, (100 - o, o), [])]
uplan, uval, _ = run(ult)
print(f"ultimatum over £10 (1000p) in 10p steps: offer {10 * uplan[0]}p, proposer keeps {10 * uval[0]}p ({len(ult)} nodes)")
print(f"mistakes: rival trusting (Out, Fight) gives up {spe_pay[0] - OUT[0]}; chain carrying out the threat loses {ACC[1] - FIGHT[1]}; "
      f"one reputation fight costs {pay3[3] - play(g3, 0, early)[3]}")
pos = {}
layout(g, 0, 0, [], pos)
print("figure, " + ", ".join(f"{k} ({pos[i][0]:.1f}, {pos[i][1]})" for k, i in
      [("rival", 0), ("chain", 1), ("fight", 2), ("accommodate", 3), ("out", 4)]))
assert spe == [plan] and plan[0] == 0 and plan[1] == 1          # road 2 agrees with road 1
assert len(ne) == 2 and play(g, 0, ne[0]) == OUT                 # the empty-threat equilibrium
assert j / 100 == q_formula                                      # road 3: grid meets formula
assert same2 and pay3[3] == 3 * ACC[1] and visits3 == len(g3) == 53
assert com[0][1][1] == OUT and cval == TAKES[0] and uplan[0] == 1
print("ALL CHECKS PASS")
