# The order book -- the check behind the card.  Standard library only.
# Prices are whole cents (10001 = $100.01); sizes are shares.  Two matching
# engines, built differently, must give the same trades and the same book.
from math import exp
def canon(entries):                      # entries: (side, price, id, shares), queue order kept
    out = {"B": {}, "S": {}}
    for side, px, oid, q in entries: out[side].setdefault(px, []).append((oid, q))
    return sorted(out["B"].items(), reverse=True), sorted(out["S"].items())
def engine_a(orders, newest_first=False):
    # Road 1: one queue per price level, oldest order at the front.
    book, tape, snaps = {"B": {}, "S": {}}, [], []
    for oid, side, px, qty in orders:
        opp = book["S" if side == "B" else "B"]
        while qty and opp:
            best = min(opp) if side == "B" else max(opp)
            if px is not None and (best > px if side == "B" else best < px): break
            head = opp[best][-1 if newest_first else 0]
            fill = min(qty, head[1]); head[1] -= fill; qty -= fill
            tape.append((oid, head[0], best, fill))
            if head[1] == 0: opp[best].remove(head)
            if not opp[best]: del opp[best]
        if qty and px is not None: book[side].setdefault(px, []).append([oid, qty])
        snaps.append(canon((s, p, o, q) for s in "BS" for p in book[s] for o, q in book[s][p]))
    return tape, snaps
def engine_b(orders):
    # Road 2: no levels.  One flat list, sorted by (price, arrival) for every incoming order.
    rest, tape, snaps = [], [], []
    for seq, (oid, side, px, qty) in enumerate(orders):
        sgn = 1 if side == "B" else -1   # a buy wants the lowest ask, a sell the highest bid
        cands = sorted((r for r in rest if r[2] != side and (px is None or sgn * (px - r[3]) >= 0)),
                       key=lambda r: (sgn * r[3], r[0]))
        for r in cands:
            if not qty: break
            fill = min(qty, r[4]); r[4] -= fill; qty -= fill
            tape.append((oid, r[1], r[3], fill))
        rest = [r for r in rest if r[4]]
        if qty and px is not None: rest.append([seq, oid, side, px, qty])
        snaps.append(canon((r[2], r[3], r[1], r[4]) for r in rest))
    return tape, snaps
def tops(snap):                          # best bid, its shares, best ask, its shares, 3-level depths
    bids, asks = snap
    if not bids or not asks: return None
    qs = lambda lv: sum(q for _, q in lv[1])
    return bids[0][0], qs(bids[0]), asks[0][0], qs(asks[0]), sum(map(qs, bids[:3])), sum(map(qs, asks[:3]))
def ofi_book(prev, cur):                 # OFI road A: compare two snapshots of the best queues
    b0, qb0, a0, qa0 = prev[:4]; b1, qb1, a1, qa1 = cur[:4]
    return (qb1 if b1 >= b0 else 0) - (qb0 if b1 <= b0 else 0) - (qa1 if a1 <= a0 else 0) + (qa0 if a1 >= a0 else 0)
def ofi_order(order, prev, tape):        # OFI road B: what this one order did to the best queues
    oid, side, px, qty = order
    fills = [f for f in tape if f[0] == oid]
    rested = qty - sum(f[3] for f in fills) if px is not None else 0
    if side == "B": return sum(f[3] for f in fills if f[2] == prev[2]) + (rested if rested and px >= prev[0] else 0)
    return -sum(f[3] for f in fills if f[2] == prev[0]) - (rested if rested and px <= prev[2] else 0)
def audit(orders, tape, snaps):          # OFI both roads, and count crossed books
    tot_a = tot_b = crossed = 0
    for n in range(1, len(orders)):
        p, c = tops(snaps[n - 1]), tops(snaps[n])
        if c and c[0] >= c[2]: crossed += 1
        if p and c: tot_a += ofi_book(p, c); tot_b += ofi_order(orders[n], p, tape)
    return tot_a, tot_b, crossed

d = lambda c: f"{c / 100:.2f}"
TEN = [(1, "B", 9998, 300), (2, "S", 10002, 200), (3, "B", 9999, 100), (4, "S", 10001, 300),
       (5, "B", 9999, 200), (6, "S", 10001, 100), (7, "S", 10003, 400), (8, "B", None, 350),
       (9, "S", 9998, 100), (10, "B", 10000, 200)]
(tape, snaps), (tape_b, snaps_b) = engine_a(TEN), engine_b(TEN)
print("event  order          bid     ask  spread      mid  Qbid  Qask  imbal   OFI-A OFI-B")
for n, (oid, side, px, qty) in enumerate(TEN):
    t = tops(snaps[n]); p = tops(snaps[n - 1]) if n else None
    what = f"{side} {'mkt' if px is None else d(px)} x{qty}"
    if not t: print(f"{n + 1:>5}  {what:<14}   (one side empty)"); continue
    fa, fb = (ofi_book(p, t), ofi_order(TEN[n], p, tape)) if p else ("-", "-")
    print(f"{n + 1:>5}  {what:<14} {d(t[0]):>6} {d(t[2]):>7} {d(t[2] - t[0]):>7} {(t[0] + t[2]) / 200:8.3f}"
          f" {t[1]:>5} {t[3]:>5} {(t[1] - t[3]) / (t[1] + t[3]):6.3f} {fa:>7} {fb:>5}")
for oid, maker, px, q in tape: print(f"trade: order {oid} takes {q} shares from order {maker} at {d(px)}")
for label, n in (("after order 7:", 6), ("after order 10:", 9)):
    side = lambda lvs: "  ".join(f"{d(p)}:{'+'.join(str(q) for _, q in lv)}" for p, lv in lvs)
    print(f"{label:<16}asks {side(snaps[n][1])}  |  bids {side(snaps[n][0])}")
b, qb, a, qa, db, da = tops(snaps[-1])
imb = (qb - qa) / (qb + qa); s = (a - b) / 100; m = (a + b) / 200
wmid_w = (a * qb + b * qa) / (qb + qa) / 100          # weight each price by the OTHER side's queue
wmid_i = m + imb * s / 2                              # mid plus imbalance times half the spread
left = {o[0]: o[3] for o in TEN}                      # Road 3: rebuild the book from the trade tape alone
for oid, maker, px, q in tape: left[oid] -= q; left[maker] -= q
rebuilt = {}
for oid, side, px, qty in TEN:
    if px is not None and left[oid]: rebuilt[(side, px)] = rebuilt.get((side, px), 0) + left[oid]
engine_lv = {(sd, p): sum(q for _, q in lv) for sd, lvs in zip("BS", snaps[-1]) for p, lv in lvs}
ofi_a, ofi_b, _ = audit(TEN, tape, snaps)
m2 = (tops(snaps[1])[0] + tops(snaps[1])[2]) / 200
print(f"spread {s:.2f}   mid {m:.3f}   top imbalance {imb:.3f}   depth, 3 levels: bids {db} asks {da}"
      f"   depth imbalance {(db - da) / (db + da):.3f}")
print(f"weighted mid, by weights {wmid_w:.3f}   by mid + I*s/2 {wmid_i:.3f}")
print(f"OFI orders 3-10: road A {ofi_a}   road B {ofi_b}   mid moved {m - m2:+.3f} since order 2")
print(f"book rebuilt from tape equals engine book: {rebuilt == engine_lv}   engines agree: {tape == tape_b and snaps == snaps_b}")
sub, rest_sh, traded = sum(o[3] for o in TEN), sum(engine_lv.values()), sum(f[3] for f in tape)
print(f"shares: submitted {sub} = resting {rest_sh} + 2 x traded {traded}")
wrong_lifo = engine_a(TEN, newest_first=True)[0][2]
print(f"wrong: newest first at a level, order 9 fills order {wrong_lifo[1]} (right: order {tape[2][1]})")
got9 = sum(f[3] for f in tape if f[0] == 9)
print(f"wrong: order 9 priced at its own limit ${got9 * 9998 / 100:.2f} (right: ${sum(f[2] * f[3] for f in tape if f[0] == 9) / 100:.2f})")
print(f"wrong: spread from last two trade prices {abs(tape[1][2] - tape[2][2]) / 100:.2f} (right: {s:.2f})")
print(f"wrong: weight each price by its own queue {(b * qb + a * qa) / (qb + qa) / 100:.3f} (right: {wmid_w:.3f})")
for label, ords in (("try: order 5 before order 3", [TEN[i] for i in (0, 1, 4, 3, 2, 5, 6, 7, 8, 9)]),
                    ("try: market buy of 450", TEN[:7] + [(8, "B", None, 450)] + TEN[8:]),
                    ("try: order 10 bids 100.01", TEN[:9] + [(10, "B", 10001, 200)])):
    tp, sn = engine_a(ords); t = tops(sn[-1])
    print(f"{label}: {len(tp)} trades, order 9 fills order {[f[1] for f in tp if f[0] == 9][0]}, "
          f"bid {d(t[0])} x{t[1]}, ask {d(t[2])} x{t[3]}, spread {d(t[2] - t[0])}")

x = 20260928                                          # Road 4: a random stress test, own generator
def rnd():
    global x
    x = (x * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return (x >> 11) / 2 ** 53
orders, counts = [], []
for sec in range(500):                                # orders per second ~ Poisson(4), Knuth's method
    k, p = 0, rnd()
    while p > exp(-4.0): k += 1; p *= rnd()
    counts.append(k)
    for _ in range(k):
        side = "B" if rnd() < 0.5 else "S"
        px = None if rnd() < 0.2 else 9995 + int(rnd() * 11)
        orders.append((len(orders) + 1, side, px, 100 * (1 + int(rnd() * 5))))
mean = sum(counts) / len(counts); var = sum((c - mean) ** 2 for c in counts) / len(counts)
(ta, sa), (tb, sb) = engine_a(orders), engine_b(orders); ra, rb, crossed = audit(orders, ta, sa)
print(f"random: {len(orders)} orders in 500 s, per second mean {mean:.3f} variance {var:.3f}")
print(f"random: {len(ta)} trades, {sum(f[3] for f in ta)} shares, engines agree: {ta == tb and sa == sb}, crossed books {crossed}")
print(f"random: OFI road A {ra}   road B {rb}")

assert tape == tape_b and snaps == snaps_b, "two engines, same ten orders"
assert ([(f[2], f[3]) for f in tape], tops(snaps[-1]), ofi_a) == ([(10001, 300), (10001, 50), (9999, 100)],
        (10000, 200, 10001, 50, 700, 650), 350), "the hand-worked tape, top of book, depths and OFI"
assert rebuilt == engine_lv, "book rebuilt from the tape must equal the engine's book"
assert abs(wmid_w - wmid_i) < 1e-9, "weighted mid = mid + imbalance x half-spread"
assert ofi_a == ofi_b, "order flow imbalance, snapshot road vs order road"
assert ta == tb and sa == sb, "random stress test: two engines, same trades, same books"
assert ra == rb, "random stress test: OFI by snapshots vs by orders"
assert crossed == 0, "random stress test: best bid always below best ask"
print("ALL CHECKS PASS")
