# Inverse functions -- the check behind the card.  Nothing is imported.  Celsius to Fahrenheit,
# F = 1.8 x C + 32, is undone by C = (F - 32) / 1.8.  The 24-hour clock read onto a 12-hour dial is
# not.  Two roads back: the undo rule, and a search of every input for the ones that land there.
CELSIUS = [-40, 0, 20, 100]
def to_f(c): return 1.8 * c + 32                                  # forwards: Celsius to Fahrenheit
def to_c(f): return (f - 32) / 1.8                                # the undo: Fahrenheit to Celsius
def dial(h): return 12 if h % 12 == 0 else h % 12                 # forwards: 24-hour clock to dial
def lands_on(rule, inputs, target):                               # the search road: who lands there
    return [x for x in inputs if rule(x) == target]
def fmt(x): return f"{x:.10f}".rstrip("0").rstrip(".")
fahr, hours = [to_f(c) for c in CELSIUS], range(24)
home = [to_c(f) for f in fahr]
back = sum(1 for c, h in zip(CELSIUS, home) if abs(c - h) < 1e-9)
found, readings = lands_on(to_f, range(-50, 101), to_f(20)), sorted({dial(h) for h in hours})
one, per, morning = lands_on(dial, hours, 1), [len(lands_on(dial, hours, d)) for d in readings], lands_on(dial, range(12), 1)
print(f"the rule: F = 1.8 x C + 32, so 20 C -> {fmt(to_f(20))} F")
print(f"the undo: C = (F - 32) / 1.8, so 68 F -> {fmt(to_c(68))} C")
print(f"round trip, {', '.join(fmt(c) for c in CELSIUS)} C -> {', '.join(fmt(f) for f in fahr)} F -> {', '.join(fmt(c) for c in home)} C -- {back} of {len(CELSIUS)} home")
print(f"search road, whole degrees -50 to 100 C landing on 68 F: {', '.join(str(c) for c in found)} -- {len(found)} input")
print(f"the one temperature both scales share: 1.8 x -40 + 32 = {fmt(to_f(-40))}")
print(f"the clock: {len(list(hours))} hours onto {len(readings)} dial readings, readings reached {len(readings)} of 12")
print(f"hours landing on dial 1: 01:00 and 13:00 -- {len(one)} inputs, so no undo")
print(f"hours behind each reading: {' '.join(str(p) for p in per)} -- {sum(per)} in total")
print(f"cut the day at noon, 00:00 to 11:00: hours landing on dial 1 = {len(morning)}, so the undo exists")
print(f"undone in the wrong order, 68 / 1.8 - 32 = {68 / 1.8 - 32:.4f}; only the +32 undone, 68 - 32 = {68 - 32}")
assert fahr == [-40.0, 32.0, 68.0, 212.0] and to_f(-40) == -40.0 and back == 4
assert found == [20] and len(found) == 1 and fmt(to_c(68)) == "20"
assert list(one) == [1, 13] and readings == list(range(1, 13)) and dial(12) == 12 and dial(13) == 1
assert per == [2] * 12 and sum(per) == 24 and len(morning) == 1 and [len(lands_on(dial, range(12), d)) for d in readings] == [1] * 12
print("ALL CHECKS PASS")
