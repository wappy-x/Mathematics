# Stable matching -- the check behind the card.  Nothing is imported.  Road one
# runs deferred acceptance, round by round, from either side.  Road two lists
# all 3! = 6 matchings and tests each for a blocking pair.
DOC, HOS = ["Asha", "Ben", "Carys"], ["Northgate", "Riverside", "Southbank"]
DP = [[0, 1, 2], [0, 2, 1], [1, 2, 0]]           # each doctor's list, best first
HP = [[2, 1, 0], [1, 0, 2], [0, 2, 1]]           # each hospital's list, best first
ALL = [[a, b, 3 - a - b] for a in range(3) for b in range(3) if a != b]   # m[d] = hospital
def accept(pp, rp, log=None, defer=True):        # pp propose to rp; returns proposer -> partner
    held, nxt, free, props, rounds = {}, [0] * 3, [0, 1, 2], 0, 0
    while free:
        rounds, offers = rounds + 1, {}
        for p in free:
            offers.setdefault(pp[p][nxt[p]], []).append(p); nxt[p] += 1; props += 1
        free = []
        for r, ps in offers.items():
            pool = ps + ([held[r]] if r in held else [])
            held[r] = held[r] if r in held and not defer else min(pool, key=rp[r].index)
            free += [p for p in pool if p != held[r]]
        if log is not None:
            log.append(f"round {rounds}: " + " ".join(f"{DOC[p]}->{HOS[r]}" for r, ps in offers.items()
                       for p in ps) + "; rejected: " + (" ".join(DOC[p] for p in sorted(free)) or "nobody"))
    return [r for p, r in sorted((p, r) for r, p in held.items())], props, rounds
def blocking(m, dp, hp):                          # pairs who both prefer each other to their partners
    return [(d, h) for d in range(3) for h in range(3)
            if dp[d].index(h) < dp[d].index(m[d]) and hp[h].index(d) < hp[h].index(m.index(h))]
def names(m): return " ".join(f"{DOC[d]}-{HOS[m[d]]}" for d in range(3))
def pairs(bs): return " ".join(f"({DOC[d]}, {HOS[h]})" for d, h in bs)
md, pd, rd = accept(DP, HP, log := [])
hm, ph, rh = accept(HP, DP); mh = [hm.index(d) for d in range(3)]   # hospital-proposing, turned round
stable = [m for m in ALL if not blocking(m, DP, HP)]
best = [min((m[d] for m in stable), key=DP[d].index) for d in range(3)]
worst = [max((m[d] for m in stable), key=DP[d].index) for d in range(3)]
rank = lambda m: ([DP[d].index(m[d]) + 1 for d in range(3)], [HP[h].index(m.index(h)) + 1 for h in range(3)])
print(f"doctors 3, hospitals 3; possible matchings 3! = {len(ALL)}")
print("\n".join(log))
print(f"doctor-proposing  : {names(md)}; proposals {pd}, rounds {rd}")
print(f"hospital-proposing: {names(mh)}; proposals {ph}, rounds {rh}")
for m in ALL:
    print(f"listing: {names(m)}  blocked by {pairs(blocking(m, DP, HP)) or 'nobody'}")
print(f"stable by listing: {len(stable)} of {len(ALL)}; best per doctor {names(best)}; worst {names(worst)}")
print(f"ranks, doctors then hospitals: doctor-proposing {rank(md)[0]} {rank(md)[1]}; hospital-proposing {rank(mh)[0]} {rank(mh)[1]}")
counts, most = [0, 0, 0], 0
for dp in [[a, b, c] for a in ALL for b in ALL for c in ALL]:
    for hp in [[a, b, c] for a in ALL for b in ALL for c in ALL]:
        m, p, _ = accept(dp, hp); most = max(most, p)
        st = [s for s in ALL if not blocking(s, dp, hp)]
        counts[0] += not blocking(m, dp, hp)
        counts[1] += all(min((s[d] for s in st), key=dp[d].index) == m[d] for d in range(3))
        counts[2] += all(max((s.index(h) for s in st), key=hp[h].index) == m.index(h) for h in range(3))
print(f"all {len(ALL) ** 6} profiles: stable {counts[0]}, doctors best {counts[1]}, hospitals worst {counts[2]}; most proposals {most}; bounds 3*3 = {3 * 3}, 3*3-3+1 = {3 * 3 - 3 + 1}")
ia = accept(DP, HP, defer=False)[0]
happy = min(ALL, key=lambda m: sum(rank(m)[0]))
print(f"mistake 1, accept for good: {names(ia)}; blocking {pairs(blocking(ia, DP, HP))}")
print(f"mistake 2, most doctor happiness: {names(happy)}, rank sum {sum(rank(happy)[0])}; blocking {pairs(blocking(happy, DP, HP))}")
print(f"mistake 3, doctors short of first choice under doctor-proposing: {sum(r > 1 for r in rank(md)[0])}; blocking pairs {len(blocking(md, DP, HP))}")
assert md == best                                 # doctor-proposing = each doctor's best, by listing
assert mh == worst                                # hospital-proposing = each doctor's worst, by listing
assert counts == [len(ALL) ** 6] * 3              # stable, doctor-best, hospital-worst in every profile
assert most == 3 * 3 - 3 + 1                      # the proposal bound is reached, never passed
print("ALL CHECKS PASS")
