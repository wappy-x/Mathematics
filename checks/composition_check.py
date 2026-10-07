# Composing functions -- the check behind the card.  Nothing is imported.  A $50 item and two offers: 20% off, and $5 off.
# Each offer is a rule that takes a price in whole cents and hands back a price.  Every chain is walked step by step, then
# again as one collapsed rule, and the two roads must agree.
PRICE, COUPON, OTHER = 5000, 500, 8000
def percent_off(c): return c * 4 // 5            # the 20% offer: keep four fifths; these prices are whole multiples of five cents, so it is exact
def coupon_off(c): return c - COUPON             # the $5 offer
def nothing(c): return c                         # the do-nothing rule
def money(c): return f"${c // 100}.{c % 100:02d}"
def chain(rules, c):                             # do the first rule, feed its answer to the next
    steps = [c]
    for rule in rules: steps.append(rule(steps[-1]))
    return steps
def walk(rules, c): return " -> ".join(money(s) for s in chain(rules, c))
pc, cp = chain([percent_off, coupon_off], PRICE)[-1], chain([coupon_off, percent_off], PRICE)[-1]
pc_rule, cp_rule = percent_off(PRICE) - COUPON, percent_off(PRICE) - percent_off(COUPON)   # each chain again, as one rule
pc2, cp2 = chain([percent_off, coupon_off], OTHER)[-1], chain([coupon_off, percent_off], OTHER)[-1]
none_then_pc = chain([nothing, percent_off], PRICE)[-1]
def row(name, value): print(f"{name:<38}{value}")
row("item price", money(PRICE))
row("20% off, then $5 off, step by step", walk([percent_off, coupon_off], PRICE))
row("$5 off, then 20% off, step by step", walk([coupon_off, percent_off], PRICE))
row("coupon after percent, as one rule", f"0.8 x price - {money(COUPON)} = {money(pc_rule)}")
row("percent after coupon, as one rule", f"0.8 x price - {money(percent_off(COUPON))} = {money(cp_rule)}")
row("the two orders differ by", f"{money(cp - pc)}, which is 20% of the {money(COUPON)} coupon")
row(f"on an {money(OTHER)} item, the two orders", f"{money(pc2)} and {money(cp2)}, still {money(cp2 - pc2)} apart")
row("do nothing, then 20% off", f"{money(none_then_pc)} -- 20% off on its own")
assert pc == 3500 and cp == 3600 and cp - pc == 100
assert pc == pc_rule and cp == cp_rule and percent_off(COUPON) == 400
assert pc2 == 5900 and cp2 == 6000 and none_then_pc == 4000
print("ALL CHECKS PASS")
