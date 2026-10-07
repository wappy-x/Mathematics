# Valid arguments -- the check behind the card.  Nothing is imported.  The
# landlord's rule: "if the rent is late, a $50 fee applies."  Four tenants
# argue from it.  1 for yes, 0 for no, over every case of (late, fee).
CASES = [(0, 0), (0, 1), (1, 0), (1, 1)]

def rule(late, fee):        # the rule, broken only by a late rent and no fee
    return 0 if late == 1 and fee == 0 else 1
def or_rule(late, fee):     # the second route: the same rule as "not late, or a fee"
    return 1 if late == 0 or fee == 1 else 0
def bad_rows(arg, r):       # cases where every premise holds and the conclusion fails
    return [c for c in CASES if all(arg[1](r, *c)) and not arg[2](*c)]
ARGS = [("Rosa  (ponens)", lambda r, l, f: [r(l, f), l], lambda l, f: f),
        ("Sam   (tollens)", lambda r, l, f: [r(l, f), 1 - f], lambda l, f: 1 - l),
        ("Tess  (consequent)", lambda r, l, f: [r(l, f), f], lambda l, f: l),
        ("Vic   (antecedent)", lambda r, l, f: [r(l, f), 1 - l], lambda l, f: 1 - f)]
print(f"{'argument':<19}{'premises hold':>14}{'counterexamples':>16}{'verdict':>9}{'second route':>14}")
holds, bad, second = [], [], []
for arg in ARGS:
    holds.append(sum(1 for c in CASES if all(arg[1](rule, *c))))
    bad.append(len(bad_rows(arg, rule)))
    second.append(len(bad_rows(arg, or_rule)))
    print(f"{arg[0]:<19}{holds[-1]:>14}{bad[-1]:>16}{'VALID' if not bad[-1] else 'INVALID':>9}{second[-1]:>14}")
rule_false = sum(1 for c in CASES if not rule(*c))
print(f"cases checked {len(CASES)}")
print(f"the rule by itself is false on cases {rule_false}")
print(f"both look-alikes fail on the same case: late {bad_rows(ARGS[2], rule)[0][0]}, fee {bad_rows(ARGS[2], rule)[0][1]}")
assert holds == [1, 1, 2, 2] and bad == second
assert bad == [0, 0, 1, 1] and rule_false == 1
assert bad_rows(ARGS[2], rule) == [(0, 1)] and bad_rows(ARGS[3], rule) == [(0, 1)]
print("ALL CHECKS PASS")
