# Integer programs: when the answer must be whole, and the relaxation that bounds it

[Syllabus](../../../SYLLABUS.md) → [Optimization](../README.md) → [Integer and Combinatorial Optimisation](../README.md#s05) → Integer programs

---

## General Overview

A summer festival is booking acts for its one stage. A headliner costs £60k and draws about 5,500 extra tickets. A smaller act costs £5k and draws about 1,000.

A headliner needs 4 hours of stage time (a long set plus a long changeover); a smaller act needs 2. The booking budget is £290k and the stage licence gives 24 hours over the weekend.

The organiser wants as many tickets sold as possible. So the choice is how many of each kind to book, the thing made largest is tickets, and the limits are money and hours.

Allow fractions, and the answer is quick: book 4.6 headliners and 2.8 smaller acts, 7.4 acts in all, for 28,100 tickets. Nobody can book 0.6 of a band, so 7.4 acts is no answer.

But the number 28,100 is still useful. No real booking can beat it, because every real booking was already on the list the fractional answer was chosen from.

The best real booking turns out to be 4 headliners and 4 smaller acts: 8 acts, 26,000 tickets. That is more acts than the fractional answer, not fewer.

The distance between the two, 2,100 tickets or 8.08%, is the **integrality gap**. A better way of writing down the same festival can shrink it. Adding the plain fact "at most 4 headliners, since five would cost £300k" closes it to zero.

**Solve the problem with fractions allowed to get a ceiling no whole answer can beat; the gap between that ceiling and the best whole answer measures how much the model hides, and a tighter way of writing the same whole answers shrinks it.**

**What kind of fact this is:** two theorems, proved on this card in Why it works (the relaxed best is a ceiling, and on the convex hull it is exact). The festival's ticket counts adding up act by act is a model: an assumption, not a law.

### The picture: the festival's choices, to scale

<p align="center"><img src="../figures/integer-programs-and-relaxations.svg" alt="The festival's relaxed region, a four-sided shape with corners at (0, 0), (0, 12), (4.6, 2.8) and (4.83, 0); the 45 whole bookings as dots; their convex hull shaded, with corners (0, 0), (4, 0), (4, 4) and (0, 12); the relaxed best at (4.6, 2.8) and the best whole booking at (4, 4)" width="420"></p>

Headliners across, smaller acts up. The solid outline is every booking that fits the money and the hours, fractions allowed. The dots are the 45 whole bookings. The shaded shape, with a dashed edge, is the smallest convex shape holding all the dots. The open circle is the fractional best; the filled one is the best whole booking.

---

## The formula

An **integer program** is a linear program whose unknowns must be whole numbers. The festival's, in the notation of the linear-programming shelf ($c^T x$ for the score, $Ax \le b$ for the limits, entry by entry):

$$z_{IP} = \max\ c^T x \ \text{ over } S = \{x : Ax \le b,\ x \ge 0,\ x \text{ whole}\}, \qquad z_{LP} = \max\ c^T x \ \text{ over } P = \{x : Ax \le b,\ x \ge 0\}$$

$$z_{LP} \ge z_{IP}, \qquad \text{gap} = \frac{z_{LP} - z_{IP}}{z_{IP}}$$

**Read it aloud:** the best score over whole bookings is never above the best score once fractions are allowed, and the gap is how far above it sits, as a share of the whole-number best.

Dropping "whole" is the **LP relaxation** (LP: linear program; relaxation: the same problem with a rule loosened). This card maximises, so the relaxation gives a ceiling. For a problem that minimises a cost, the same argument gives a floor.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x = (h, t)$ | the booking: $h$ headliners, $t$ smaller acts | best whole $(4, 4)$; relaxed $(4.6, 2.8)$ | — (the solver chooses it) |
| $c$ | tickets each kind of act draws | $(5500, 1000)$ | more tickets; the best mix can shift |
| $A$ | what each act uses: fees in £k, stage hours | `[[60, 5], [4, 2]]` | fewer bookings fit |
| $b$ | what is available: budget, hours | $(290, 24)$ | more bookings fit |
| $P$ | the relaxed region: every booking that fits, fractions allowed | the solid outline | — |
| $S$ | the whole bookings that fit | 45 dots | — |
| $\operatorname{conv} S$ | the convex hull of $S$: the smallest convex shape holding every dot | corners $(0,0)$, $(4,0)$, $(4,4)$, $(0,12)$ | — |
| $z_{LP}$ | best tickets over $P$: the ceiling | 28,100 | — |
| $z_{IP}$ | best tickets over $S$: the answer | 26,000 | — |
| gap | $z_{LP} - z_{IP}$, also as a share of $z_{IP}$ | 2,100 tickets, 8.08% | the ceiling says less about the answer |
| $y = (y_1, y_2)$ | prices on £1k of budget and on one stage hour, in tickets | $(70, 325)$ | — (Step 2 finds them) |

The convex hull and the set-builder braces $\{x : Ax \le b\}$ ("every $x$ with $Ax \le b$") come from [Convex sets](../01-Convexity/02-convex-sets.md): a set is **convex** when the straight segment between any two of its points stays inside it. [Integer programs](../../14-Applied%20and%20computational/05-Operations%20Research/03-integer-programming-and-branch-and-bound.md) in the computing wing already bounds a depot choice by its fractional relaxation and quotes its gap. This card spends its space on why the bound holds, how to certify it, and how to compare two ways of writing the same problem.

### When it holds

- **Every whole booking must lie inside the relaxation.** That is the only thing the ceiling rests on. Add a limit that some whole booking breaks, such as "at most 7 acts", and the model no longer describes the festival: its best whole booking drops to 25,000 tickets, missing the real 26,000, and its relaxed best is no longer a guaranteed ceiling for the real festival.
- **The relaxation must be solved to the end, or certified.** A corner found halfway through a solve is just a booking; its score is not a ceiling. The prices of Step 2 are a ceiling whether or not the solve finished.
- **The direction must be stated.** For a maximum the relaxation is a ceiling. For a minimum it is a floor. Mixing them up gives a "bound" on the wrong side.
- **The score must add up act by act.** If two headliners share fans, 5,500 each overstates, and the ceiling and the answer are wrong together.
- **Whole must really mean whole.** If the stage could be rented by the hour to a share of an act, fractions are allowed, the relaxation is the true problem and there is no gap.

---

## Why it works

### Step 0: loosening a rule can only widen the menu

Every whole booking is also a fractional booking: 4 is a perfectly good value of a number allowed to be 4.37. So $S$ sits inside $P$. Choosing the best from a bigger menu can only do as well or better. That one sentence is the whole proof of $z_{LP} \ge z_{IP}$, and it is why a relaxation is worth solving even when its answer is nonsense.

### Step 1: solve the relaxation at a corner

With fractions allowed, the festival is a linear program, and a linear score is best at a corner of $P$ ([Corners are enough](../04-Linear%20Programming/02-corners-and-the-fundamental-theorem.md) shows why). $P$ has four corners, each where two limits cross:

| Corner $(h, t)$ | Which limits cross | Tickets |
| --- | --- | ---: |
| $(0, 0)$ | no headliners, no smaller acts | 0 |
| $(0, 12)$ | no headliners; 24 hours used | 12,000 |
| $(4.6, 2.8)$ | budget and hours both used up | **28,100** |
| $(4.83, 0)$ | budget used up, no smaller acts | 26,583.33 |

The best corner books 4.6 headliners and 2.8 smaller acts. It spends exactly £290k and exactly 24 hours: headliners pull the score up, the budget stops them at 4.83, and the hours force a trade.

### Step 2: certify the ceiling with prices

A second road to the ceiling needs no search. Put a price, in tickets, on each unit of every limit: $y_1$ per £1k of budget and $y_2$ per stage hour, neither negative. If the prices make every act cost at least the tickets it draws, then any booking's tickets are at most the cost of everything it uses, which is at most the cost of everything available:

$$c^T x \le y^T A x \le y^T b \quad \text{whenever } A^T y \ge c,\ y \ge 0,\ Ax \le b,\ x \ge 0.$$

Pick the prices so both acts exactly break even: $60y_1 + 4y_2 = 5500$ and $5y_1 + 2y_2 = 1000$. Then $y_1 = 70$ tickets per £1k and $y_2 = 325$ tickets per hour. The ceiling is $290 \times 70 + 24 \times 325 = 28{,}100$. The same number as the corner search, reached without listing a single corner.

These are the dual prices of [LP duality](../04-Linear%20Programming/04-lp-duality-and-complementary-slackness.md). That such prices always exist to match the relaxed best is the strong duality theorem, proved there; on this card the two roads agree on the numbers, which is the evidence.

### Step 3: measure the gap, and see why rounding fails

The whole bookings are few enough to list: 45 of them. The best is $(4, 4)$: £260k in fees, all 24 hours, 26,000 tickets, and the listing shows it is the only one at that score. The gap is $28{,}100 - 26{,}000 = 2{,}100$ tickets, or $2{,}100 / 26{,}000 = 8.08\%$.

The fractional corner is a poor guide to the answer. Rounding it to the nearest whole booking, $(5, 3)$, costs £315k, over the budget. Rounding it down, $(4, 2)$, sells 24,000, 2,000 short. The best booking keeps 4 headliners and spends the hours the 0.6 of a headliner would have used on more smaller acts. That move only shows up by looking at whole bookings, which is the job of [Branch and bound](03-branch-and-bound.md).

### Step 4: the same whole bookings, written two ways, give two ceilings

A model is a list of limits, and many lists allow exactly the same whole bookings. They can still have different relaxations.

Suppose the licence were written as 25 hours. Every act uses an even number of hours, so no whole booking can use the 25th hour: the 45 whole bookings are the same. But fractional bookings can, and the relaxed best moves to $(4.55, 3.4)$ with 28,425 tickets. The ceiling is weaker and the gap grows to 9.33%.

Going the other way, add a limit every whole booking obeys: $h \le 4$, because five headliners cost £300k, over £290k. The budget alone allows 4.83 headliners; whole headliners stop at 4. The whole bookings are again the same 45, but the corner $(4.6, 2.8)$ is now cut off, and the relaxed best lands on $(4, 4)$ itself, 26,000 tickets. Gap zero.

| Formulation | Whole bookings | Relaxed best | Ceiling | Gap |
| --- | ---: | --- | ---: | ---: |
| licence written as 25 hours | 45 | $(4.55, 3.4)$ | 28,425 | 9.33% |
| as written, 24 hours | 45 | $(4.6, 2.8)$ | 28,100 | 8.08% |
| plus $h \le 4$ | 45 | $(4, 4)$ | 26,000 | 0% |

One formulation is **tighter** than another when its relaxed region sits inside the other's while holding the same whole points. A tighter one never gives a worse ceiling, and in a search a better ceiling at every branch lets a solver discard more branches unopened.

### Step 5: the tightest possible relaxation is exact

The tightest region that still holds every whole booking is $\operatorname{conv} S$, the convex hull of the dots. Its best score is exactly the whole-number best:

$$\max_{x \in \operatorname{conv} S} c^T x = z_{IP}.$$

The reason: every point of the hull is a weighted average of whole bookings, and a linear score of an average is the same average of the scores, so it can never beat the best score being averaged.

<details>
<summary>Detailed proof: the hull's best is the whole-number best</summary>

Take any point $x$ of $\operatorname{conv} S$. By the meaning of the convex hull, $x$ is a weighted average of finitely many whole bookings: $x$ equals the sum of weights times bookings, the weights not negative and adding to 1. The score $c^T x$ is linear, so $c^T x$ equals the same weights times the bookings' scores. Each of those scores is at most $z_{IP}$, and weights adding to 1 cannot lift an average above its largest term. So $c^T x \le z_{IP}$ for every point of the hull. The best whole booking is itself in the hull, so the maximum is reached: it equals $z_{IP}$.

For the festival, $S$ is a finite set of 45 points, so its hull is a polygon. In general, for a region $P$ whose limits use rational numbers (fractions of whole numbers), the hull of its whole points is again a region cut out by finitely many straight limits; that is Meyer's theorem (Sources), stated here, not proved.

</details>

Here the code builds the hull straight from the 45 dots, and its corners, $(0, 0)$, $(4, 0)$, $(4, 4)$ and $(0, 12)$, are exactly the corners of $P$ with $h \le 4$ added. So the one extra limit already gives the hull.

Real models are rarely this kind: the hull can need enormously many limits, and finding them is as hard as the problem. Solving integer programs in general is NP-hard (no method is known that is fast on every case; Karp's 1972 list in Sources includes 0-1 integer programs).

[Cutting planes](04-cutting-planes.md) adds hull limits a few at a time, and [Total unimodularity](05-total-unimodularity.md) picks out the matrices whose $P$ already equals the hull.

---

## Worked numbers, by hand

The festival, maximising tickets.

| Step | Arithmetic | Value |
| --- | --- | --- |
| Relaxed corner: budget and hours both full | $60h + 5t = 290$, $4h + 2t = 24$ | $h = 4.6$, $t = 2.8$: 7.4 acts |
| Its tickets | $5500 \times 4.6 + 1000 \times 2.8$ | 28,100 |
| Prices that make both acts break even | $60y_1 + 4y_2 = 5500$, $5y_1 + 2y_2 = 1000$ | $y_1 = 70$, $y_2 = 325$ |
| Price ceiling | $290 \times 70 + 24 \times 325$ | 28,100 |
| Best whole booking (listing all 45) | $(4, 4)$: fees $60 \times 4 + 5 \times 4 = 260$, hours $4 \times 4 + 2 \times 4 = 24$ | 26,000 tickets |
| Integrality gap | $28{,}100 - 26{,}000$; $2{,}100 / 26{,}000$ | 2,100 tickets, 8.08% |
| Add $h \le 4$ | five headliners cost $5 \times 60 = 300 > 290$ | ceiling 26,000, gap 0% |
| **Answer** | | **book 4 headliners and 4 smaller acts: 26,000 tickets** |

The festival books 8 acts and sells 26,000 extra tickets; the ceiling of 28,100, matched by the prices and closed by $h \le 4$, proves no booking within £290k and 24 hours sells more.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Round the 7.4-act corner to nearest, $(5, 3)$ | £315k of fees, over £290k | Rounding ignores the limits; the corner sat on two of them |
| Round it down, $(4, 2)$ | 24,000 tickets, 2,000 short | The best whole booking is not next to the fractional one |
| Read the ceiling as the answer | 28,100 promised, 2,100 no booking sells | The ceiling holds fractional bookings too |
| Read "7.4 acts" as a cap and add $h + t \le 7$ | best found $(4, 3)$, 25,000 tickets | A false limit cuts off the real best, 8 acts. 7.4 was the ticket-best corner; $P$ allows up to 12 acts at $(0, 12)$ |
| Write the licence as 25 hours | ceiling 28,425, gap 9.33% | Same whole bookings, looser region: a weaker ceiling |

---

## Code, from first principles, and it actually runs

The script works in exact fractions (a rational type in Rust) and takes three roads to the festival's numbers. Road 1 lists every corner of the relaxed region and keeps the best. Road 2 solves for the two prices and checks they make a valid ceiling equal to road 1's. Road 3 lists all 45 whole bookings, finds the best, builds their convex hull and checks the hull's corners against the corners of the region with $h \le 4$ added. It then compares the three formulations and computes every wrong answer in the table above. The figure's corners come from the line starting `figure,`.

### Python

```python
# Integer programs and relaxations: the festival's headliners h and smaller acts t.
# Maximise tickets 5500h + 1000t with fees 60h + 5t <= 290 (in £k) and stage
# hours 4h + 2t <= 24, h and t whole. Exact fractions throughout.
from fractions import Fraction as Fr

C = (5500, 1000)                 # extra tickets per headliner, per smaller act
BUDGET = (60, 5, 290)            # fees in £k: 60h + 5t <= 290
HOURS = (4, 2, 24)               # stage hours: 4h + 2t <= 24
SIGNS = [(-1, 0, 0), (0, -1, 0)] # h >= 0 and t >= 0, written as -h <= 0, -t <= 0

def show(q):                     # exact fraction -> decimal text, at most 2 places
    n = abs(q.numerator) * 100 * 2 + q.denominator
    n //= 2 * q.denominator      # rounded half up
    s = str(n // 100) + ("." + "%02d" % (n % 100)).rstrip("0").rstrip(".")
    return ("-" if q < 0 else "") + s

def corners(rows):               # every crossing of two limits that obeys all limits
    out = []
    for i in range(len(rows)):
        for j in range(i + 1, len(rows)):
            (a1, b1, r1), (a2, b2, r2) = rows[i], rows[j]
            det = a1 * b2 - a2 * b1
            if det == 0:
                continue
            p = (Fr(r1 * b2 - r2 * b1, det), Fr(a1 * r2 - a2 * r1, det))
            if all(a * p[0] + b * p[1] <= r for a, b, r in rows) and p not in out:
                out.append(p)
    return sorted(out)

def tickets(p):
    return C[0] * p[0] + C[1] * p[1]

def relax(rows):                 # the LP relaxation: best corner (road 1)
    best = max(corners(rows), key=tickets)
    return tickets(best), best

def whole_plans(rows):           # road 3: list every whole plan
    return [(h, t) for h in range(0, 30) for t in range(0, 30)
            if all(a * h + b * t <= r for a, b, r in rows)]

def hull(points):                # convex hull of the whole plans, monotone chain
    pts = sorted(set(points))
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return sorted(lower[:-1] + upper[:-1])

def pt(p):
    return "(" + show(Fr(p[0])) + ", " + show(Fr(p[1])) + ")"

P = [BUDGET, HOURS] + SIGNS
print("corners of the relaxed region P, with tickets:")
for p in corners(P):
    print("  h, t =", pt(p), " tickets", show(tickets(p)))
z_lp, x_lp = relax(P)
print("relaxation: best corner", pt(x_lp), "=", show(x_lp[0] + x_lp[1]), "acts, tickets", show(z_lp))
print("  fees", show(60 * x_lp[0] + 5 * x_lp[1]), "of 290; hours", show(4 * x_lp[0] + 2 * x_lp[1]), "of 24")

# Road 2: prices y on the budget and the hours, from the two tight limits.
det = BUDGET[0] * HOURS[1] - HOURS[0] * BUDGET[1]
y1 = Fr(C[0] * HOURS[1] - HOURS[0] * C[1], det)
y2 = Fr(BUDGET[0] * C[1] - C[0] * BUDGET[1], det)
bound = y1 * BUDGET[2] + y2 * HOURS[2]
print("prices: y1 =", show(y1), "tickets per £1k, y2 =", show(y2), "tickets per hour")
print("  covers a headliner:", show(60 * y1 + 4 * y2), ">= 5500; a smaller act:", show(5 * y1 + 2 * y2), ">= 1000")
print("  price bound 290 x", show(y1), "+ 24 x", show(y2), "=", show(bound))
assert y1 >= 0 and y2 >= 0 and 60 * y1 + 4 * y2 >= C[0] and 5 * y1 + 2 * y2 >= C[1]
assert bound == z_lp             # certificate meets the corner search

S = whole_plans(P)
z_ip = max(tickets(p) for p in S)
best = [p for p in S if tickets(p) == z_ip]
print("whole plans:", str(len(S)) + "; best", pt(best[0]), "=", best[0][0] + best[0][1], "acts, tickets", z_ip)
print("  fees", 60 * best[0][0] + 5 * best[0][1], "of 290; hours", 4 * best[0][0] + 2 * best[0][1], "of 24")
assert len(best) == 1 and z_lp >= z_ip
gap = z_lp - z_ip
print("integrality gap:", show(gap), "tickets =", show(100 * gap / z_ip) + "%")

H = hull(S)
print("corners of conv S:", " ".join(pt(p) for p in H))
assert all(p[0] <= 4 for p in S)  # the listing agrees: no whole plan has 5 headliners
print("five headliners cost", BUDGET[0] * 5, ">", str(BUDGET[2]) + ", so every whole plan has h <= 4")
tight = P + [(1, 0, 4)]          # add 'at most 4 headliners': 5 would cost £300k
assert corners(tight) == [(Fr(a), Fr(b)) for a, b in H]  # inequalities give the hull
z_hull = max(tickets(p) for p in H)
print("formulations, same whole plans, different bounds:")
loose = [BUDGET, (4, 2, 25)] + SIGNS            # licence written as 25 hours
z_loose, x_loose = relax(loose)
assert sorted(whole_plans(loose)) == sorted(S)
for name, z, x in [("25-hour licence", z_loose, x_loose), ("as written, 24 hours", z_lp, x_lp),
                   ("plus h <= 4 (= conv S)", relax(tight)[0], relax(tight)[1])]:
    print("  %-23s bound %8s at %-12s gap %s%%" % (name, show(z), pt(x), show(100 * (z - z_ip) / z_ip)))
assert z_hull == z_ip == relax(tight)[0] and z_loose > z_lp

print("what breaks:")
up = tuple(int(v + Fr(1, 2)) for v in x_lp)    # the relaxed corner rounded to nearest
fee_up = BUDGET[0] * up[0] + BUDGET[1] * up[1]
print("  round", show(x_lp[0]) + ",", show(x_lp[1]), "to nearest " + pt(up) + ": fees", fee_up, ">", str(BUDGET[2]) + ", not allowed")
dn = tuple(int(v) for v in x_lp)               # rounded down
print("  round down to " + pt(dn) + ": tickets", str(tickets(dn)) + ",", z_ip - tickets(dn), "short of best")
print("  read the bound as the answer: promises", show(gap), "tickets no plan sells")
cap7 = whole_plans(P + [(1, 1, 7)])
z7 = max(tickets(p) for p in cap7)
print("  add the false cap h + t <= 7: best " + pt(max(cap7, key=tickets)) + ", tickets", z7)
most = max(corners(P), key=lambda p: p[0] + p[1])
print("  (most acts anywhere in P:", show(most[0] + most[1]) + ", at " + pt(most) + ")")
assert fee_up > BUDGET[2]                       # rounding to nearest breaks the budget
assert tickets(dn) < z_ip and z7 < z_ip
print("figure, P", " ".join(pt(p) for p in corners(P)) + "; conv S", " ".join(pt(p) for p in H) + "; LP",
      pt(x_lp) + "; best", pt(best[0]))
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
corners of the relaxed region P, with tickets:
  h, t = (0, 0)  tickets 0
  h, t = (0, 12)  tickets 12000
  h, t = (4.6, 2.8)  tickets 28100
  h, t = (4.83, 0)  tickets 26583.33
relaxation: best corner (4.6, 2.8) = 7.4 acts, tickets 28100
  fees 290 of 290; hours 24 of 24
prices: y1 = 70 tickets per £1k, y2 = 325 tickets per hour
  covers a headliner: 5500 >= 5500; a smaller act: 1000 >= 1000
  price bound 290 x 70 + 24 x 325 = 28100
whole plans: 45; best (4, 4) = 8 acts, tickets 26000
  fees 260 of 290; hours 24 of 24
integrality gap: 2100 tickets = 8.08%
corners of conv S: (0, 0) (0, 12) (4, 0) (4, 4)
five headliners cost 300 > 290, so every whole plan has h <= 4
formulations, same whole plans, different bounds:
  25-hour licence         bound    28425 at (4.55, 3.4)  gap 9.33%
  as written, 24 hours    bound    28100 at (4.6, 2.8)   gap 8.08%
  plus h <= 4 (= conv S)  bound    26000 at (4, 4)       gap 0%
what breaks:
  round 4.6, 2.8 to nearest (5, 3): fees 315 > 290, not allowed
  round down to (4, 2): tickets 24000, 2000 short of best
  read the bound as the answer: promises 2100 tickets no plan sells
  add the false cap h + t <= 7: best (4, 3), tickets 25000
  (most acts anywhere in P: 12, at (0, 12))
figure, P (0, 0) (0, 12) (4.6, 2.8) (4.83, 0); conv S (0, 0) (0, 12) (4, 0) (4, 4); LP (4.6, 2.8); best (4, 4)
ALL CHECKS PASS
```

### Rust

```rust
// Integer programs and relaxations: the festival's headliners h and smaller acts t.
// Maximise tickets 5500h + 1000t with fees 60h + 5t <= 290 (in £k) and stage
// hours 4h + 2t <= 24, h and t whole. Exact fractions throughout.
use std::cmp::Ordering;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Q { n: i64, d: i64 }       // a fraction n/d, d > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q {
    let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn z(n: i64) -> Q { q(n, 1) }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }

type Row = (i64, i64, i64);       // a*h + b*t <= r
type P2 = (Q, Q);
const C: (i64, i64) = (5500, 1000);
const BUDGET: Row = (60, 5, 290);
const HOURS: Row = (4, 2, 24);
const SIGNS: [Row; 2] = [(-1, 0, 0), (0, -1, 0)];

fn show(x: Q) -> String {          // exact fraction -> decimal text, at most 2 places
    let n = (x.n.abs() * 100 * 2 + x.d) / (2 * x.d);
    let frac = format!(".{:02}", n % 100);
    let frac = frac.trim_end_matches('0').trim_end_matches('.');
    format!("{}{}{}", if x.n < 0 { "-" } else { "" }, n / 100, frac)
}
fn pt(p: P2) -> String { format!("({}, {})", show(p.0), show(p.1)) }
fn tickets(p: P2) -> Q { z(C.0) * p.0 + z(C.1) * p.1 }
fn obeys(rows: &[Row], p: P2) -> bool { rows.iter().all(|&(a, b, r)| z(a) * p.0 + z(b) * p.1 <= z(r)) }

fn corners(rows: &[Row]) -> Vec<P2> {   // every crossing of two limits that obeys all limits
    let mut out: Vec<P2> = Vec::new();
    for i in 0..rows.len() {
        for j in i + 1..rows.len() {
            let ((a1, b1, r1), (a2, b2, r2)) = (rows[i], rows[j]);
            let det = a1 * b2 - a2 * b1;
            if det == 0 { continue; }
            let p = (q(r1 * b2 - r2 * b1, det), q(a1 * r2 - a2 * r1, det));
            if obeys(rows, p) && !out.contains(&p) { out.push(p); }
        }
    }
    out.sort(); out
}
fn relax(rows: &[Row]) -> (Q, P2) {     // the LP relaxation: best corner (road 1)
    let mut best = corners(rows)[0];
    for p in corners(rows) { if tickets(p) > tickets(best) { best = p; } }
    (tickets(best), best)
}
fn whole_plans(rows: &[Row]) -> Vec<(i64, i64)> {   // road 3: list every whole plan
    let mut v = Vec::new();
    for h in 0..30 { for t in 0..30 { if obeys(rows, (z(h), z(t))) { v.push((h, t)); } } }
    v
}
fn wt(p: (i64, i64)) -> i64 { C.0 * p.0 + C.1 * p.1 }
fn hull(points: &[(i64, i64)]) -> Vec<(i64, i64)> {   // convex hull, monotone chain
    let mut pts = points.to_vec(); pts.sort(); pts.dedup();
    let cross = |o: (i64, i64), a: (i64, i64), b: (i64, i64)| (a.0 - o.0) * (b.1 - o.1) - (a.1 - o.1) * (b.0 - o.0);
    let (mut lower, mut upper): (Vec<(i64, i64)>, Vec<(i64, i64)>) = (vec![], vec![]);
    for &p in pts.iter() {
        while lower.len() >= 2 && cross(lower[lower.len() - 2], lower[lower.len() - 1], p) <= 0 { lower.pop(); }
        lower.push(p);
    }
    for &p in pts.iter().rev() {
        while upper.len() >= 2 && cross(upper[upper.len() - 2], upper[upper.len() - 1], p) <= 0 { upper.pop(); }
        upper.push(p);
    }
    lower.pop(); upper.pop(); lower.extend(upper); lower.sort(); lower
}
fn zp(p: (i64, i64)) -> P2 { (z(p.0), z(p.1)) }
fn down(x: Q) -> i64 { x.n.div_euclid(x.d) }   // round down to a whole number
fn join(v: &[P2]) -> String { v.iter().map(|&p| pt(p)).collect::<Vec<_>>().join(" ") }

fn main() {
    let p_rows: Vec<Row> = vec![BUDGET, HOURS, SIGNS[0], SIGNS[1]];
    println!("corners of the relaxed region P, with tickets:");
    for p in corners(&p_rows) { println!("  h, t = {}  tickets {}", pt(p), show(tickets(p))); }
    let (z_lp, x_lp) = relax(&p_rows);
    println!("relaxation: best corner {} = {} acts, tickets {}", pt(x_lp), show(x_lp.0 + x_lp.1), show(z_lp));
    println!("  fees {} of 290; hours {} of 24", show(z(60) * x_lp.0 + z(5) * x_lp.1), show(z(4) * x_lp.0 + z(2) * x_lp.1));

    // Road 2: prices y on the budget and the hours, from the two tight limits.
    let det = BUDGET.0 * HOURS.1 - HOURS.0 * BUDGET.1;
    let y1 = q(C.0 * HOURS.1 - HOURS.0 * C.1, det);
    let y2 = q(BUDGET.0 * C.1 - C.0 * BUDGET.1, det);
    let bound = y1 * z(BUDGET.2) + y2 * z(HOURS.2);
    println!("prices: y1 = {} tickets per £1k, y2 = {} tickets per hour", show(y1), show(y2));
    println!("  covers a headliner: {} >= 5500; a smaller act: {} >= 1000", show(z(60) * y1 + z(4) * y2), show(z(5) * y1 + z(2) * y2));
    println!("  price bound 290 x {} + 24 x {} = {}", show(y1), show(y2), show(bound));
    assert!(y1 >= z(0) && y2 >= z(0) && z(60) * y1 + z(4) * y2 >= z(C.0) && z(5) * y1 + z(2) * y2 >= z(C.1));
    assert!(bound == z_lp);                // certificate meets the corner search

    let s = whole_plans(&p_rows);
    let z_ip = s.iter().map(|&p| wt(p)).max().unwrap();
    let best: Vec<(i64, i64)> = s.iter().cloned().filter(|&p| wt(p) == z_ip).collect();
    println!("whole plans: {}; best {} = {} acts, tickets {}", s.len(), pt(zp(best[0])), best[0].0 + best[0].1, z_ip);
    println!("  fees {} of 290; hours {} of 24", 60 * best[0].0 + 5 * best[0].1, 4 * best[0].0 + 2 * best[0].1);
    assert!(best.len() == 1 && z_lp >= z(z_ip));
    let gap = z_lp - z(z_ip);
    println!("integrality gap: {} tickets = {}%", show(gap), show(z(100) * gap / z(z_ip)));

    let h: Vec<P2> = hull(&s).into_iter().map(zp).collect();
    println!("corners of conv S: {}", join(&h));
    assert!(s.iter().all(|p| p.0 <= 4));   // the listing agrees: no whole plan has 5 headliners
    println!("five headliners cost {} > {}, so every whole plan has h <= 4", BUDGET.0 * 5, BUDGET.2);
    let mut tight = p_rows.clone(); tight.push((1, 0, 4));   // at most 4 headliners: 5 would cost £300k
    assert!(corners(&tight) == h);         // inequalities give the hull
    let z_hull = h.iter().map(|&p| tickets(p)).max().unwrap();
    println!("formulations, same whole plans, different bounds:");
    let loose: Vec<Row> = vec![BUDGET, (4, 2, 25), SIGNS[0], SIGNS[1]];   // licence written as 25 hours
    let (z_loose, x_loose) = relax(&loose);
    assert!(whole_plans(&loose) == s);
    for (name, zz, x) in [("25-hour licence", z_loose, x_loose), ("as written, 24 hours", z_lp, x_lp),
                          ("plus h <= 4 (= conv S)", relax(&tight).0, relax(&tight).1)] {
        println!("  {:<23} bound {:>8} at {:<12} gap {}%", name, show(zz), pt(x), show(z(100) * (zz - z(z_ip)) / z(z_ip)));
    }
    assert!(z_hull == z(z_ip) && relax(&tight).0 == z(z_ip) && z_loose > z_lp);

    println!("what breaks:");
    let up = (down(x_lp.0 + q(1, 2)), down(x_lp.1 + q(1, 2)));   // the relaxed corner rounded to nearest
    let fee_up = BUDGET.0 * up.0 + BUDGET.1 * up.1;
    println!("  round {}, {} to nearest {}: fees {} > {}, not allowed", show(x_lp.0), show(x_lp.1), pt(zp(up)), fee_up, BUDGET.2);
    let dn = (down(x_lp.0), down(x_lp.1));   // rounded down
    println!("  round down to {}: tickets {}, {} short of best", pt(zp(dn)), wt(dn), z_ip - wt(dn));
    println!("  read the bound as the answer: promises {} tickets no plan sells", show(gap));
    let mut capped = p_rows.clone(); capped.push((1, 1, 7));
    let cap7 = whole_plans(&capped);
    let z7 = cap7.iter().map(|&p| wt(p)).max().unwrap();
    let b7 = *cap7.iter().find(|&&p| wt(p) == z7).unwrap();
    println!("  add the false cap h + t <= 7: best {}, tickets {}", pt(zp(b7)), z7);
    let mut most = corners(&p_rows)[0];
    for p in corners(&p_rows) { if p.0 + p.1 > most.0 + most.1 { most = p; } }
    println!("  (most acts anywhere in P: {}, at {})", show(most.0 + most.1), pt(most));
    assert!(fee_up > BUDGET.2);           // rounding to nearest breaks the budget
    assert!(wt(dn) < z_ip && z7 < z_ip);
    println!("figure, P {}; conv S {}; LP {}; best {}", join(&corners(&p_rows)), join(&h), pt(x_lp), pt(zp(best[0])));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
corners of the relaxed region P, with tickets:
  h, t = (0, 0)  tickets 0
  h, t = (0, 12)  tickets 12000
  h, t = (4.6, 2.8)  tickets 28100
  h, t = (4.83, 0)  tickets 26583.33
relaxation: best corner (4.6, 2.8) = 7.4 acts, tickets 28100
  fees 290 of 290; hours 24 of 24
prices: y1 = 70 tickets per £1k, y2 = 325 tickets per hour
  covers a headliner: 5500 >= 5500; a smaller act: 1000 >= 1000
  price bound 290 x 70 + 24 x 325 = 28100
whole plans: 45; best (4, 4) = 8 acts, tickets 26000
  fees 260 of 290; hours 24 of 24
integrality gap: 2100 tickets = 8.08%
corners of conv S: (0, 0) (0, 12) (4, 0) (4, 4)
five headliners cost 300 > 290, so every whole plan has h <= 4
formulations, same whole plans, different bounds:
  25-hour licence         bound    28425 at (4.55, 3.4)  gap 9.33%
  as written, 24 hours    bound    28100 at (4.6, 2.8)   gap 8.08%
  plus h <= 4 (= conv S)  bound    26000 at (4, 4)       gap 0%
what breaks:
  round 4.6, 2.8 to nearest (5, 3): fees 315 > 290, not allowed
  round down to (4, 2): tickets 24000, 2000 short of best
  read the bound as the answer: promises 2100 tickets no plan sells
  add the false cap h + t <= 7: best (4, 3), tickets 25000
  (most acts anywhere in P: 12, at (0, 12))
figure, P (0, 0) (0, 12) (4.6, 2.8) (4.83, 0); conv S (0, 0) (0, 12) (4, 0) (4, 4); LP (4.6, 2.8); best (4, 4)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the three general facts of Why it works for every matrix $A$, limits $b$ and score $c$, and checks the festival's arithmetic.

- If both bests exist, the best score over whole bookings is never above the best score with fractions allowed: $z_{IP} \le z_{LP}$.
- Suppose prices $y \ge 0$ make every act cost at least the tickets it draws: $A^T y \ge c$. Then every booking in $P$ has $c^T x \le y^T A x \le y^T b$.
- If $z_{IP}$ is the best score over the whole bookings, then the best score over the convex hull $\operatorname{conv} S$ is exactly $z_{IP}$.
- For the festival: 45 whole bookings, none above 26,000 tickets; the corner $(4.6, 2.8)$ sells 28,100; prices $(70, 325)$ give 28,100.
- Also: the gap is 2,100 tickets, five headliners cost £300k, and rounding gives £315k or 24,000 tickets.

Finding the corners, the hull's corners, the 25-hour model and the false cap of 7 acts are left to the Python and Rust checks.

```lean
-- Integer programs: the best score over whole points is never above the best score with fractions allowed, prices on the limits certify such a ceiling, and over the convex hull of the whole points the best score is exactly the whole-number best.
import Mathlib.Analysis.Convex.Hull
import Mathlib.Data.Matrix.Mul
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum

open Matrix

variable {m n : Type*} [Fintype m] [Fintype n]

/-- The relaxed region `P = {x : A x ≤ b, x ≥ 0}`: every point that fits, fractions allowed. -/
def relaxedRegion (A : Matrix m n ℝ) (b : m → ℝ) : Set (n → ℝ) :=
  {x | A *ᵥ x ≤ b ∧ 0 ≤ x}

/-- The whole points `S = {x : A x ≤ b, x ≥ 0, x whole}`. -/
def wholePoints (A : Matrix m n ℝ) (b : m → ℝ) : Set (n → ℝ) :=
  {x | x ∈ relaxedRegion A b ∧ ∀ i, ∃ k : ℤ, x i = k}

/-- The LP relaxation is a ceiling: if `z_IP` is the best score `c ⬝ x` over the whole points
of `{x : A x ≤ b, x ≥ 0}`, and `z_LP` is the best score over the same region with fractions
allowed, then `z_LP ≥ z_IP`. -/
theorem relaxation_bounds_integer_optimum (A : Matrix m n ℝ) (b : m → ℝ) (c : n → ℝ)
    (zIP zLP : ℝ)
    (hIP : IsGreatest ((fun x => c ⬝ᵥ x) '' wholePoints A b) zIP)
    (hLP : IsGreatest ((fun x => c ⬝ᵥ x) '' relaxedRegion A b) zLP) :
    zIP ≤ zLP := by
  obtain ⟨⟨x, hx, rfl⟩, -⟩ := hIP
  exact hLP.2 ⟨x, hx.1, rfl⟩

/-- Prices certify a ceiling: if prices `y ≥ 0` on the limits make every unknown cost at least
its score (`Aᵀ y ≥ c`), then every point with `A x ≤ b` and `x ≥ 0` has
`c ⬝ x ≤ y ⬝ (A x) ≤ y ⬝ b`. -/
theorem price_certificate_bounds_score (A : Matrix m n ℝ) (b : m → ℝ) (c : n → ℝ)
    (y : m → ℝ) (x : n → ℝ)
    (hy : 0 ≤ y) (hcover : c ≤ y ᵥ* A) (hAx : A *ᵥ x ≤ b) (hx : 0 ≤ x) :
    c ⬝ᵥ x ≤ y ⬝ᵥ (A *ᵥ x) ∧ y ⬝ᵥ (A *ᵥ x) ≤ y ⬝ᵥ b := by
  refine ⟨?_, ?_⟩
  · rw [dotProduct_mulVec]
    unfold dotProduct
    exact Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_right (hcover i) (hx i)
  · unfold dotProduct
    exact Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_left (hAx i) (hy i)

/-- The convex hull is exact: if `z_IP` is the best score over the whole points `S`, then the
best score over `conv S` is again exactly `z_IP`. -/
theorem convex_hull_relaxation_exact (A : Matrix m n ℝ) (b : m → ℝ) (c : n → ℝ) (zIP : ℝ)
    (hIP : IsGreatest ((fun x => c ⬝ᵥ x) '' wholePoints A b) zIP) :
    IsGreatest ((fun x => c ⬝ᵥ x) '' convexHull ℝ (wholePoints A b)) zIP := by
  obtain ⟨⟨x, hx, rfl⟩, hub⟩ := hIP
  refine ⟨⟨x, subset_convexHull ℝ _ hx, rfl⟩, ?_⟩
  have hlin : IsLinearMap ℝ (fun x : n → ℝ => c ⬝ᵥ x) :=
    ⟨fun u v => dotProduct_add c u v, fun r u => dotProduct_smul r c u⟩
  have hsub : convexHull ℝ (wholePoints A b) ⊆ {z | c ⬝ᵥ z ≤ c ⬝ᵥ x} :=
    convexHull_min (fun z hz => hub ⟨z, hz, rfl⟩) (convex_halfSpace_le hlin _)
  rintro _ ⟨z, hz, rfl⟩
  exact hsub hz

/-! The festival: `h` headliners and `t` smaller acts, fees `60h + 5t ≤ 290` (in £k),
hours `4h + 2t ≤ 24`, tickets `5500h + 1000t`. -/

-- There are 45 whole bookings (every whole booking has h ≤ 4 and t ≤ 12, so 30 is plenty).
example : ((Finset.range 30 ×ˢ Finset.range 30).filter
    (fun p : ℕ × ℕ => 60 * p.1 + 5 * p.2 ≤ 290 ∧ 4 * p.1 + 2 * p.2 ≤ 24)).card = 45 := by
  decide +kernel

-- The best whole booking is (4, 4): it fits, and no whole booking sells more than 26,000.
example : 60 * 4 + 5 * 4 = 260 ∧ 4 * 4 + 2 * 4 = 24 ∧ 5500 * 4 + 1000 * 4 = 26000 := by
  norm_num
example : ∀ h ∈ Finset.range 30, ∀ t ∈ Finset.range 30,
    60 * h + 5 * t ≤ 290 → 4 * h + 2 * t ≤ 24 → 5500 * h + 1000 * t ≤ 26000 := by
  decide

-- The relaxed corner (23/5, 14/5), that is 4.6 headliners and 2.8 smaller acts, uses the
-- whole budget and all the hours, and sells 28,100 tickets.
example : (60 : ℚ) * (23 / 5) + 5 * (14 / 5) = 290 ∧ (4 : ℚ) * (23 / 5) + 2 * (14 / 5) = 24 ∧
    (5500 : ℚ) * (23 / 5) + 1000 * (14 / 5) = 28100 := by
  norm_num

-- Prices y = (70, 325) make both acts break even, and certify the same ceiling, 28,100.
example : 60 * 70 + 4 * 325 = 5500 ∧ 5 * 70 + 2 * 325 = 1000 ∧ 290 * 70 + 24 * 325 = 28100 := by
  norm_num

-- The integrality gap is 2,100 tickets; five headliners cost 300 > 290, so h ≤ 4.
example : 28100 - 26000 = 2100 ∧ 5 * 60 = 300 ∧ 300 > 290 := by
  norm_num

-- Rounding fails: (5, 3) costs 315 > 290, and (4, 2) sells 24,000, 2,000 short.
example : 60 * 5 + 5 * 3 = 315 ∧ 5500 * 4 + 1000 * 2 = 24000 ∧ 26000 - 24000 = 2000 := by
  norm_num

#print axioms relaxation_bounds_integer_optimum
#print axioms price_certificate_bounds_score
#print axioms convex_hull_relaxation_exact
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'relaxation_bounds_integer_optimum' depends on axioms: [propext, Classical.choice, Quot.sound]
'price_certificate_bounds_score' depends on axioms: [propext, Classical.choice, Quot.sound]
'convex_hull_relaxation_exact' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the festival as given, so expect some to stop the run; read the printed lines above the stop.
> - **Guess first: does a bigger budget help a lot?** Set the budget in `BUDGET` to 300. Five headliners now fit, the best booking becomes $(5, 0)$ at 27,500 tickets, and the gap falls to 4.73%. Then an assert stops the run: the hull printed just above has a corner at $(5, 0)$, so "at most 4 headliners" is no longer true. A limit true for one budget is false for another.
> - **Guess first: does the gap depend on the crowd numbers?** Set a headliner's draw in `C` to 4000. The corner stays at $(4.6, 2.8)$ and the best at $(4, 4)$, but the ceiling is 21,200 against 20,000: gap 6%.
> - **Guess first: what if smaller acts draw 3,000?** Set `C = (5500, 3000)`. The relaxed best jumps to $(0, 12)$: 12 acts and 36,000 tickets, already whole, so there is no gap. Then the price assert stops the run, because the prices assumed the budget was full, and here it is not.

---

## The usual mistake

> [!warning]
> **Rounding the relaxed answer and calling it the answer.** The 7.4-act corner sits where the budget and the hours both run out, so nudging it in any direction breaks a limit or wastes one. Rounded to nearest, $(5, 3)$ costs £315k, over budget. Rounded down, $(4, 2)$ sells 24,000, while the best, $(4, 4)$, sells 26,000. The relaxation gives a ceiling, not a booking.
>
> - **Treating the ceiling as a promise.** 28,100 tickets is what no booking can beat, not what any booking reaches: 2,100 of it, 8.08%, is the gap.
> - **Adding a limit that looks obvious but is false.** "At most 7 acts", read off the 7.4 corner, cuts off the real best and leaves 25,000.
> - **Judging a model by its whole answers alone.** The 25-hour and 24-hour versions allow the same 45 bookings, yet one ceiling is 28,425 and the other 28,100. Solvers live on ceilings, so the tighter model is the better model.
> - **Using a half-finished relaxed solve as a bound.** A corner's score is a ceiling only once it is proved best; prices that cover every act, like $70$ and $325$, are a ceiling at any time.

---

## Where you meet it in real life

- **Every integer solver's log.** Commercial and open-source solvers print the best whole answer found, the best ceiling still open, and the gap between them, and stop when the gap reaches a set tolerance. That printed number is the search gap of [Branch and bound](03-branch-and-bound.md): the highest ceiling still open minus the best booking found. It falls to 0 when the answer is proved. The integrality gap on this card is fixed by the model, and a tighter formulation is what shrinks it.
- **Airline crew rostering.** Each pairing of flights is a yes-or-no choice, and planners stop once the relaxation's bound shows the roster is within a fraction of a percent of the best.
- **Choosing what to build.** Factories, warehouses, cell towers: modellers pick the tighter formulation because the same model then solves far faster. [Four classic models](06-classic-integer-models-knapsack-assignment-and-covering.md) shows the standard ones.
- **Prices from a relaxation.** The prices of Step 2 are where [Lagrangian relaxation](07-lagrangian-relaxation-and-decomposition.md) starts: price the awkward limit and solve what is left.
- **Approximation guarantees.** A heuristic's promise to land within a stated factor of the best is usually proved against a relaxation's bound; see [Heuristics with a promise](08-heuristics-and-approximation-guarantees.md).

> **Say it back**
> An integer program asks for the best whole-number decision, such as how many acts to book. Dropping "whole" gives the LP relaxation, whose best, here 28,100 tickets at 7.4 acts, is a ceiling because every whole booking was on its menu. Prices on the budget and the hours certify the same ceiling without a search. The best whole booking, 4 headliners and 4 smaller acts at 26,000, sits 2,100 below it, 8.08% of the answer: the integrality gap. Writing the same bookings with a tighter list of limits, such as adding "at most 4 headliners", shrinks the gap, and the convex hull of the whole bookings closes it.

---

## What this builds on

- [Linear programs](../04-Linear%20Programming/01-linear-programs-and-polyhedra.md): the relaxation is one. [Corners are enough](../04-Linear%20Programming/02-corners-and-the-fundamental-theorem.md) puts its best at a corner, and [LP duality](../04-Linear%20Programming/04-lp-duality-and-complementary-slackness.md) supplies the prices that certify it.
- [Integer programs](../../14-Applied%20and%20computational/05-Operations%20Research/03-integer-programming-and-branch-and-bound.md): the computing wing's depot choice, which first used a fractional ceiling and quoted its gap.

## Where this goes next

- [Yes-or-no variables](02-modelling-with-binary-variables-big-m-and-indicators.md): the next card. Writing switches and if-then rules with 0-or-1 unknowns, where a careless constant gives the kind of loose relaxation Step 4 measures.
- [Branch and bound](03-branch-and-bound.md): splitting on a fractional variable and using this card's ceiling to discard whole branches.
- [Cutting planes](04-cutting-planes.md): adding hull limits a few at a time until the relaxed best is whole, as $h \le 4$ does here.
- [Total unimodularity](05-total-unimodularity.md): the matrices whose relaxation is already the convex hull, so the gap is always zero.
- [Heuristics with a promise](08-heuristics-and-approximation-guarantees.md): a quick whole answer with a proved guarantee against a relaxation's prices, the honest version of the mistake on this card.

The open question: when the hull needs too many limits to write down, which few of them are worth adding?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Land, A. H., and A. G. Doig. "An Automatic Method of Solving Discrete Programming Problems." *Econometrica* 28, no. 3 (1960): 497–520. [doi:10.2307/1910129](https://doi.org/10.2307/1910129). The first method to search whole answers using the relaxation's ceiling.
- Meyer, R. R. "On the Existence of Optimal Solutions to Integer and Mixed-Integer Programming Problems." *Mathematical Programming* 7 (1974): 223–235. [doi:10.1007/BF01585518](https://doi.org/10.1007/BF01585518). The convex hull of the whole points is again cut out by finitely many limits when the data are rational.
- Karp, Richard M. "Reducibility among Combinatorial Problems." In *Complexity of Computer Computations*, 85–103. 1972. [doi:10.1007/978-1-4684-2001-2_9](https://doi.org/10.1007/978-1-4684-2001-2_9). The list of hard problems that includes 0-1 integer programming.
- Wolsey, Laurence A. *Integer Programming*, 2nd ed. Wiley, 2020. [Publisher page](https://www.wiley.com/en-us/Integer+Programming%2C+2nd+Edition-p-9781119606536). Relaxations, bounds and comparing formulations, at this card's level.
- Conforti, Michele, Gérard Cornuéjols, and Giacomo Zambelli. *Integer Programming*. Graduate Texts in Mathematics 271. Springer, 2014. [doi:10.1007/978-3-319-11008-0](https://doi.org/10.1007/978-3-319-11008-0). The convex hull, formulation strength and the proofs in full.
