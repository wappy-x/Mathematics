# Bellman-Ford: relax every edge n - 1 times, negative costs allowed, and a loop that still improves is a money machine

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Trees and Cheapest Routes](../README.md#s10) → Bellman-Ford

---

## General Overview

A dealing screen quotes three one-way prices. One US dollar buys 0.90 euro. One euro buys 0.85 pound. One pound buys 1.32 dollars.

Multiply the three: 0.90 × 0.85 × 1.32 = 1.0098. A dollar sent round the loop comes home as 1.0098 dollars, up 0.98%, in three trades, with no view taken on where prices are heading. Money that leaves and returns larger is an **arbitrage** — the word from here on.

Three currencies can be checked by hand. Hundreds cannot, and the paying loop may run through any five of them. So change what the arrows carry: each leg's **cost** is minus the logarithm of its rate. Multiplying rates becomes adding costs, and a loop that multiplies money above 1 becomes one whose costs add below 0 — free money as a cheapest route with negative costs.

Negative costs are what the greedy method cannot take: it settles the nearest dot and never reconsiders it ([Dijkstra's algorithm](05-dijkstra.md)). Lester Ford in 1956 and Richard Bellman in 1958 set out a method that locks nothing.

Their method goes over every quoted rate, called an arrow or edge, in rounds. Whenever a rate offers a cheaper way into a currency, it lowers that currency's cost: that step is to relax the arrow. With n currencies, it runs n − 1 rounds and one more.

**Relaxing every edge n − 1 times finds every cheapest route whenever no loop pays, since a cheapest route has at most n − 1 legs; an n-th round that still improves proves a loop pays — an arbitrage.**

**What kind of fact this is:** a method, resting on a theorem — n − 1 rounds suffice, a further improvement means a paying loop — proved on this card in Why it works.

### The picture: three currencies, three quoted rates

```mermaid
flowchart LR
    USD(("USD")) -->|"x 0.90"| EUR(("EUR"))
    EUR -->|"x 0.85"| GBP(("GBP"))
    GBP -->|"x 1.32"| USD
```

USD, EUR and GBP are the US dollar, the euro and the British pound. Each rate is one arrow. Round the loop they multiply to 1.0098.

---

## The formula

Notation first, in words. The market is a directed graph: a dot per currency, an arrow per quoted rate, $n$ of the first and $m$ of the second. On the arrow from $u$ to $v$, the rate $r(u \to v)$ is how much of $v$ one unit of $u$ buys; its cost is minus that rate's natural logarithm, written $\ln$ ([Logarithms](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md)):

$$w(u \to v) \;=\; -\ln r(u \to v)$$

**Read it aloud:** a leg's cost is minus the log of its rate, so a generous rate is cheap.

Next, $d(v)$: the smallest cost so far of a route from the start to $v$, infinity until one is found. To **relax** an arrow is to ask whether reaching $u$ and paying its cost beats the number at $v$, and keep the smaller:

$$d(v) \;\leftarrow\; \min\big(d(v),\; d(u) + w(u \to v)\big)$$

The method is three lines. Set $d$ to 0 at the start, infinity elsewhere. Do $n$ − 1 rounds, each relaxing all $m$ arrows in a fixed order. Do one more: if any relax still improves, a loop pays.

For a loop of $k$ legs, profit test and cost test are one test:

$$r_1 r_2 \cdots r_k > 1 \quad\Longleftrightarrow\quad w_1 + w_2 + \cdots + w_k < 0$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $r$ | a quoted rate: units bought per unit sold | 0.90, 0.85, 1.32 | the loop's product rises |
| $w$ | a leg's cost, minus the log of its rate | 0.105361, 0.162519, −0.277632 | routes through it dearer |
| $d$ | smallest cost so far at a currency | 0.105361 at EUR | — |
| $u$, $v$ | an arrow's ends, $u$ to $v$ | USD and EUR | — |
| $n$ | currencies listed | 3 | more rounds, $n$ − 1 of them |
| $m$ | rates quoted | 3 | each round is $m$ relaxes |
| $k$ | legs in a route or loop | 3 | — |

### When it holds

- **Every rate is positive**, or it has no logarithm and so no cost; and the currencies are finitely many, since the round count is $n$ − 1.
- **No loop pays**, where a cheapest route is wanted: riding a paying loop again lowers the total again, and the extra round reports that instead of an answer.
- **The rates are the ones dealt, and the loop is reachable from the start.** A fee is a positive cost on its leg, and enough of it turns a paying loop into a losing one.

---

## Why it works

### Step 0: a logarithm turns multiplying into adding

Profit round a loop means the rates multiply above 1. The logarithm rises with its input, so taking logs keeps that inequality, and the log of a product is the sum of the logs ([Log laws and log scales](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/06-log-laws-and-log-scales.md)). Negate every log and "above 1" becomes "below 0" — a route-finder on a trading screen.

```mermaid
flowchart LR
    USD(("USD")) -->|"cost 0.105361"| EUR(("EUR"))
    EUR -->|"cost 0.162519"| GBP(("GBP"))
    GBP -->|"cost -0.277632"| USD
```

The same legs as costs: the generous 1.32 turned negative, and the three total −0.009752.

### Step 1: after round $k$, every cheapest route of at most $k$ legs is on the table

Every number in $d$ is the cost of a real route, so none is ever too low; the rounds chase the numbers that are too high. Round 1 relaxes the arrows leaving the start, so every one-leg route lands. Cut the last arrow, $u$ to $v$, off a cheapest route of at most $k$ legs: what is left reaches $u$ in at most $k$ − 1 legs, on the table by round $k$ − 1, and round $k$ relaxes that arrow.

### Step 2: $n$ − 1 rounds are enough, when no loop pays

A cheapest route never has to visit a currency twice: cut out the stretch between two visits and a loop is gone, whose costs add to 0 or more when nothing pays, so the route is no dearer. A route with no repeat has at most $n$ − 1 legs, all on the table by round $n$ − 1: with three currencies, two rounds.

### Step 3: an $n$-th round that still improves is a money machine

If no loop pays, the table after $n$ − 1 rounds holds the cheapest costs and every arrow fails its relax question. A further improvement rules that case out: some loop pays. The detector is one round.

Round 3 drops USD from 0.000000 to −0.009752, and following each improvement back walks the loop: USD to EUR to GBP to USD, costs adding to −0.009752, rates multiplying to 1.009800. The fall does not stop. EUR reaches 0.095608 in the same round, and every later round pulls the table lower, so there is no cheapest route and no ceiling on the money.

<details>
<summary>Detailed proof: the induction and the exchange</summary>

Let $D_k(v)$ be the least cost of a route from the start to $v$ over at most $k$ arrows. **Claim 1:** after round $k$, $d(v) \le D_k(v)$. Induct: drop the last arrow, $u$ to $v$, of a $k$-arrow route costing $D_k(v)$; the rest is a $k$ − 1 case, so $u$ enters round $k$ at $D_k(v) - w(u \to v)$ or lower, and round $k$ relaxes that arrow.

**Claim 2:** with no negative-total loop, deleting the loop between two visits to a repeated currency never raises a cost, so a cheapest route needs at most $n$ − 1 arrows. Those costs admit no relax, so an improvement in round $n$ denies the hypothesis; following each improvement back to the currency it came from, $n$ times, closes the paying loop.

</details>

<details>
<summary>All pairs at once: Floyd-Warshall</summary>

Bellman-Ford answers from one currency; a desk wants every pair. Robert Floyd's 1962 loop — Algorithm 97, on a theorem of Stephen Warshall — keeps a square table `D(i,j)` of costs, one row and column per currency: for each currency `s` in turn and every pair `i`, `j`, keep the smaller of `D(i,j)` and `D(i,s) + D(s,j)`.

The outer loop is *which* currencies may be stepping-stones, not *how many* legs are allowed; move it inward and a different claim is proved. A negative number on the diagonal is then a paying loop: USD's own entry lands on −0.009752.

</details>

With no negative cost the greedy method is faster ([Dijkstra's algorithm](05-dijkstra.md)); the cheapest set of links holding a network together is another question ([The cheapest skeleton](04-minimum-spanning-trees.md)).

---

## Worked numbers, by hand

Start at USD and scan the legs in the check's order: GBP to USD, EUR to GBP, USD to EUR. Each leg comes before the leg that feeds it, the slowest order there is, so a round advances the answer by one leg.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the three costs | minus the log of 0.90, 0.85, 1.32 | 0.105361, 0.162519, −0.277632 |
| start | USD at 0, the others unreached | 0.000000 |
| round 1 | the one relax that fires | EUR 0.105361 |
| round 2 | 0.105361 + 0.162519 | GBP 0.267879 |
| round 3, the extra | 0.267879 − 0.277632 | **USD −0.009752** |
| the loop in money | 0.90 × 0.85 × 1.32 | **1.009800** |

Two rounds settled the table and the third moved it anyway: the certificate. Move the pound-to-dollar rate to 1.30 and it is gone — the rates multiply to 0.994500, down 0.55%, and round 3 offers USD 0.005515, no improvement on 0.000000.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Stopping after $n$ − 1 rounds | USD reads 0.000000 | the table looks settled; the extra round finds the loop |
| Product against 0, costs against 1 | 0.994500 > 0, 0.005515 < 1 | the losing market clears both, so nothing is detected |
| Adding the log, not subtracting | the loop totals 0.009752 | a generous rate looks dear, so arbitrage is missed |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Two roads reach the verdict: one adds costs, minus the log of each rate, over $n$ − 1 rounds and one more; the other never takes a log, multiplying rates along every route of at most three legs. The log itself is computed twice: from a series, and as the area under 1/t, which is what a natural log measures.

### Python

```python
# Bellman-Ford and arbitrage -- the check behind the card.  Nothing is imported.
# Three currencies, three quoted rates: USD->EUR 0.90, EUR->GBP 0.85, GBP->USD
# 1.32.  Road one adds costs, minus the log of each rate, relaxing every quoted
# rate n-1 rounds and once more.  Road two multiplies rates along every route.
CUR = ["USD", "EUR", "GBP"]
ARB = [("GBP", "USD", 1.32), ("EUR", "GBP", 0.85), ("USD", "EUR", 0.90)]
CLEAN = [("GBP", "USD", 1.30), ("EUR", "GBP", 0.85), ("USD", "EUR", 0.90)]
INF, SRC = float("inf"), "USD"
def ln(x):                        # natural log, from the series in (x-1)/(x+1)
    y = (x - 1.0) / (x + 1.0)
    total, term = 0.0, y
    for k in range(1, 40, 2):
        total, term = total + term / k, term * y * y
    return 2.0 * total
def ln_area(x):                   # the same log as the area under 1/t, by Simpson's rule
    h, total = (x - 1.0) / 2000, 1.0 + 1.0 / x
    for i in range(1, 2000):
        total += (4.0 if i % 2 else 2.0) / (1.0 + i * h)
    return total * h / 3.0
def rounds(market, extra):        # road one: relax every quoted rate, round after round
    d = {c: (0.0 if c == SRC else INF) for c in CUR}
    table, improved = [dict(d)], False
    for r in range(len(CUR) - 1 + extra):
        for a, b, rate in market:
            if d[a] < INF and d[a] - ln(rate) < d[b] - 1e-12:
                d[b], improved = d[a] - ln(rate), improved or r == len(CUR) - 1
        table.append(dict(d))
    return table, improved
def walks(market, legs):          # road two: every route of at most `legs` legs, rates multiplied
    best, frontier = {SRC: 1.0}, [(SRC, 1.0)]
    for _ in range(legs):
        frontier = [(b, m * rate) for c, m in frontier for a, b, rate in market if a == c]
        for c, m in frontier:
            best[c] = max(best.get(c, 0.0), m)
    return best
def trip(market): return market[0][2] * market[1][2] * market[2][2]
def cost_sum(market): return sum(-ln(rate) for _, _, rate in market)

(tab, neg), (tabc, negc) = rounds(ARB, 1), rounds(CLEAN, 1)
p, pc = trip(ARB), trip(CLEAN)
print("quoted market: " + ",  ".join(f"{a}->{b} {r:.2f}" for a, b, r in reversed(ARB)))
print("costs, minus the log of each rate: " + ",  ".join(f"{a}->{b} {-ln(r):.6f}" for a, b, r in reversed(ARB)))
print("scan order inside every round: " + ", ".join(f"{a}->{b}" for a, b, _ in ARB))
print(f"{'round':<6}" + "".join(f"{c:>10}" for c in CUR))
for lab, d in (("start", tab[0]), ("1", tab[1]), ("2", tab[2]), ("3", tab[3])):
    print(f"{lab:<6}" + "".join(f"{'inf':>10}" if d[c] == INF else f"{d[c]:10.6f}" for c in CUR))
print(f"round 3 still improves {SRC}, {tab[3][SRC]:.6f} against {tab[2][SRC]:.6f}, so a loop pays: {'yes' if neg else 'no'}")
print(f"loop USD->EUR->GBP->USD: costs added {cost_sum(ARB):.6f}, rates multiplied {p:.6f} ({(p - 1) * 100:+.2f}%)")
print(f"minus the log of {p:.6f} is {-ln(p):.6f}; best multiplier home over routes of at most 3 legs {walks(ARB, 3)[SRC]:.6f}")
print(f"the log of 1.32 by the series {ln(1.32):.6f}, by the area under 1/t {ln_area(1.32):.6f}")
print(f"market with GBP->USD at 1.30: rates multiplied {pc:.6f} ({(pc - 1) * 100:+.2f}%), costs added {cost_sum(CLEAN):.6f}")
print(f"its rounds 1 and 2 read as above; round 3 offers {SRC} {tabc[2]['GBP'] - ln(1.30):.6f}, no improvement, loop pays: {'yes' if negc else 'no'}")
print(f"mistake 1, stopping after 2 rounds: {SRC} reads {tab[2][SRC]:.6f}, not {tab[3][SRC]:.6f}")
print(f"mistake 2, thresholds crossed over: the losing market clears both, {pc:.6f} > 0 and {cost_sum(CLEAN):.6f} < 1")
print(f"mistake 3, plus the log instead of minus: the loop totals {-cost_sum(ARB):.6f}, above zero, arbitrage missed")
assert neg == (p > 1.0) and negc == (pc > 1.0)            # detector against multiplied rates
assert abs(cost_sum(ARB) + ln(p)) < 1e-12 and abs(cost_sum(CLEAN) + ln(pc)) < 1e-12
assert max(abs(ln(r) - ln_area(r)) for _, _, r in ARB) < 1e-9      # series against area
assert all(abs(tabc[2][c] + ln(walks(CLEAN, 2)[c])) < 1e-12 for c in CUR) and abs(tab[3][SRC] + ln(walks(ARB, 3)[SRC])) < 1e-12
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
quoted market: USD->EUR 0.90,  EUR->GBP 0.85,  GBP->USD 1.32
costs, minus the log of each rate: USD->EUR 0.105361,  EUR->GBP 0.162519,  GBP->USD -0.277632
scan order inside every round: GBP->USD, EUR->GBP, USD->EUR
round        USD       EUR       GBP
start   0.000000       inf       inf
1       0.000000  0.105361       inf
2       0.000000  0.105361  0.267879
3      -0.009752  0.095608  0.267879
round 3 still improves USD, -0.009752 against 0.000000, so a loop pays: yes
loop USD->EUR->GBP->USD: costs added -0.009752, rates multiplied 1.009800 (+0.98%)
minus the log of 1.009800 is -0.009752; best multiplier home over routes of at most 3 legs 1.009800
the log of 1.32 by the series 0.277632, by the area under 1/t 0.277632
market with GBP->USD at 1.30: rates multiplied 0.994500 (-0.55%), costs added 0.005515
its rounds 1 and 2 read as above; round 3 offers USD 0.005515, no improvement, loop pays: no
mistake 1, stopping after 2 rounds: USD reads 0.000000, not -0.009752
mistake 2, thresholds crossed over: the losing market clears both, 0.994500 > 0 and 0.005515 < 1
mistake 3, plus the log instead of minus: the loop totals 0.009752, above zero, arbitrage missed
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Bellman-Ford and arbitrage -- the same check as the Python, in Rust.  No crates.
// Three currencies, three quoted rates: USD->EUR 0.90, EUR->GBP 0.85, GBP->USD
// 1.32.  Road one adds costs, minus the log of each rate, relaxing every quoted
// rate n-1 rounds and once more.  Road two multiplies rates along every route.
const CUR: [&str; 3] = ["USD", "EUR", "GBP"];                   // USD 0, EUR 1, GBP 2
const ARB: [(usize, usize, f64); 3] = [(2, 0, 1.32), (1, 2, 0.85), (0, 1, 0.90)];
const CLEAN: [(usize, usize, f64); 3] = [(2, 0, 1.30), (1, 2, 0.85), (0, 1, 0.90)];
const INF: f64 = f64::INFINITY;
const SRC: usize = 0;
fn ln(x: f64) -> f64 {                   // natural log, from the series in (x-1)/(x+1)
    let y = (x - 1.0) / (x + 1.0);
    let (mut total, mut term) = (0.0, y);
    for k in (1..40).step_by(2) { total += term / k as f64; term *= y * y }
    2.0 * total
}
fn ln_area(x: f64) -> f64 {              // the same log as the area under 1/t, by Simpson's rule
    let (h, mut total) = ((x - 1.0) / 2000.0, 1.0 + 1.0 / x);
    for i in 1..2000 { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) / (1.0 + i as f64 * h) }
    total * h / 3.0
}
fn rounds(market: &[(usize, usize, f64); 3], extra: usize) -> (Vec<[f64; 3]>, bool) {
    let mut d = [INF; 3];                // road one: relax every quoted rate, round after round
    d[SRC] = 0.0;
    let (mut table, mut improved) = (vec![d], false);
    for r in 0..(CUR.len() - 1 + extra) {
        for &(a, b, rate) in market.iter() {
            if d[a] < INF && d[a] - ln(rate) < d[b] - 1e-12 {
                d[b] = d[a] - ln(rate); improved = improved || r == CUR.len() - 1;
            }
        }
        table.push(d);
    }
    (table, improved)
}
fn walks(market: &[(usize, usize, f64); 3], legs: usize) -> [f64; 3] {
    let (mut best, mut frontier) = ([0.0, 0.0, 0.0], vec![(SRC, 1.0)]);   // road two: rates multiplied
    best[SRC] = 1.0;
    for _ in 0..legs {
        let mut next = Vec::new();
        for &(c, m) in frontier.iter() { for &(a, b, r) in market.iter() { if a == c { next.push((b, m * r)) } } }
        for &(c, m) in next.iter() { if m > best[c] { best[c] = m } }
        frontier = next;
    }
    best
}
fn trip(m: &[(usize, usize, f64); 3]) -> f64 { m[0].2 * m[1].2 * m[2].2 }
fn cost_sum(m: &[(usize, usize, f64); 3]) -> f64 { m.iter().map(|&(_, _, r)| -ln(r)).sum() }
fn leg(a: usize, b: usize) -> String { format!("{}->{}", CUR[a], CUR[b]) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let ((tab, neg), (tabc, negc)) = (rounds(&ARB, 1), rounds(&CLEAN, 1));
    let (p, pc) = (trip(&ARB), trip(&CLEAN));
    println!("quoted market: {}", ARB.iter().rev().map(|&(a, b, r)|
        format!("{} {:.2}", leg(a, b), r)).collect::<Vec<String>>().join(",  "));
    println!("costs, minus the log of each rate: {}", ARB.iter().rev().map(|&(a, b, r)|
        format!("{} {:.6}", leg(a, b), -ln(r))).collect::<Vec<String>>().join(",  "));
    println!("scan order inside every round: {}", ARB.iter().map(|&(a, b, _)|
        leg(a, b)).collect::<Vec<String>>().join(", "));
    println!("{:<6}{:>10}{:>10}{:>10}", "round", CUR[0], CUR[1], CUR[2]);
    for (lab, d) in [("start", tab[0]), ("1", tab[1]), ("2", tab[2]), ("3", tab[3])].iter() {
        let cells: Vec<String> = (0..CUR.len()).map(|i|
            if d[i] == INF { format!("{:>10}", "inf") } else { format!("{:10.6}", d[i]) }).collect();
        println!("{:<6}{}", lab, cells.join(""));
    }
    println!("round 3 still improves {}, {:.6} against {:.6}, so a loop pays: {}", CUR[SRC], tab[3][SRC], tab[2][SRC], yn(neg));
    println!("loop USD->EUR->GBP->USD: costs added {:.6}, rates multiplied {:.6} ({:+.2}%)", cost_sum(&ARB), p, (p - 1.0) * 100.0);
    println!("minus the log of {:.6} is {:.6}; best multiplier home over routes of at most 3 legs {:.6}", p, -ln(p), walks(&ARB, 3)[SRC]);
    println!("the log of 1.32 by the series {:.6}, by the area under 1/t {:.6}", ln(1.32), ln_area(1.32));
    println!("market with GBP->USD at 1.30: rates multiplied {:.6} ({:+.2}%), costs added {:.6}", pc, (pc - 1.0) * 100.0, cost_sum(&CLEAN));
    println!("its rounds 1 and 2 read as above; round 3 offers {} {:.6}, no improvement, loop pays: {}", CUR[SRC], tabc[2][2] - ln(1.30), yn(negc));
    println!("mistake 1, stopping after 2 rounds: {} reads {:.6}, not {:.6}", CUR[SRC], tab[2][SRC], tab[3][SRC]);
    println!("mistake 2, thresholds crossed over: the losing market clears both, {:.6} > 0 and {:.6} < 1", pc, cost_sum(&CLEAN));
    println!("mistake 3, plus the log instead of minus: the loop totals {:.6}, above zero, arbitrage missed", -cost_sum(&ARB));
    assert!(neg == (p > 1.0) && negc == (pc > 1.0));                   // detector against multiplied rates
    assert!((cost_sum(&ARB) + ln(p)).abs() < 1e-12 && (cost_sum(&CLEAN) + ln(pc)).abs() < 1e-12);
    assert!(ARB.iter().map(|&(_, _, r)| (ln(r) - ln_area(r)).abs()).fold(0.0, f64::max) < 1e-9);
    let bw = walks(&CLEAN, 2);                                         // table against multiplied rates
    assert!((0..CUR.len()).all(|c| (tabc[2][c] + ln(bw[c])).abs() < 1e-12) && (tab[3][SRC] + ln(walks(&ARB, 3)[SRC])).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
quoted market: USD->EUR 0.90,  EUR->GBP 0.85,  GBP->USD 1.32
costs, minus the log of each rate: USD->EUR 0.105361,  EUR->GBP 0.162519,  GBP->USD -0.277632
scan order inside every round: GBP->USD, EUR->GBP, USD->EUR
round        USD       EUR       GBP
start   0.000000       inf       inf
1       0.000000  0.105361       inf
2       0.000000  0.105361  0.267879
3      -0.009752  0.095608  0.267879
round 3 still improves USD, -0.009752 against 0.000000, so a loop pays: yes
loop USD->EUR->GBP->USD: costs added -0.009752, rates multiplied 1.009800 (+0.98%)
minus the log of 1.009800 is -0.009752; best multiplier home over routes of at most 3 legs 1.009800
the log of 1.32 by the series 0.277632, by the area under 1/t 0.277632
market with GBP->USD at 1.30: rates multiplied 0.994500 (-0.55%), costs added 0.005515
its rounds 1 and 2 read as above; round 3 offers USD 0.005515, no improvement, loop pays: no
mistake 1, stopping after 2 rounds: USD reads 0.000000, not -0.009752
mistake 2, thresholds crossed over: the losing market clears both, 0.994500 > 0 and 0.005515 < 1
mistake 3, plus the log instead of minus: the loop totals 0.009752, above zero, arbitrage missed
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's three claims for any finite set of currencies and any real costs, negative ones included.

- When no loop pays, n − 1 rounds leave each currency's cheapest route cost on the table. No route costs less, and each number is infinity or a real route's cost.
- The n-th round improves some number exactly when a loop reachable from the start pays.
- With every rate positive, a loop's rates multiply above 1 exactly when its costs, minus the log of each rate, add below 0.
- 0.90 × 0.85 × 1.32 is exactly 1.0098, above 1; with 1.30 in place of 1.32 it is 0.9945, below 1.

The logs, the six-decimal costs and the round-by-round table are left to the Python and Rust checks.

```lean
-- Bellman-Ford: relaxing every arrow n - 1 times leaves every cheapest route cost on the table when no loop has a negative total, one more round improves something exactly when a loop reachable from the start has a negative total, and with positive rates and costs minus their logs a loop's rates multiply above 1 exactly when its costs add below 0.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Order.WithBot
import Mathlib.Algebra.Order.Monoid.WithTop
import Mathlib.Data.Fintype.Card
import Mathlib.Logic.Function.Iterate

namespace BellmanFord

variable {V : Type*}

/-- An arrow `(u, v, w)` runs from `u` to `v` and costs `w`. -/
abbrev Arrow (V : Type*) := V × V × ℝ

/-- `IsRoute E a b p`: the list of arrows `p`, each one quoted in `E`, leads from `a` to `b`,
each arrow starting where the one before it ended. The empty route leads from `a` to `a`. -/
inductive IsRoute (E : List (Arrow V)) : V → V → List (Arrow V) → Prop
  | nil (a : V) : IsRoute E a a []
  | cons {a b c : V} {w : ℝ} {p : List (Arrow V)} :
      (a, b, w) ∈ E → IsRoute E b c p → IsRoute E a c ((a, b, w) :: p)

/-- A route's cost: the costs of its arrows added up. -/
def routeCost (p : List (Arrow V)) : ℝ := (p.map fun e => e.2.2).sum

variable [DecidableEq V]

/-- Relax one arrow `u → v` of cost `w`: `d(v) ← min (d(v), d(u) + w)`. Infinity is `⊤`. -/
def relax (d : V → WithTop ℝ) (e : Arrow V) : V → WithTop ℝ :=
  Function.update d e.2.1 (min (d e.2.1) (d e.1 + (e.2.2 : WithTop ℝ)))

/-- One round: relax every arrow of `E` once, in the list's fixed order. -/
def relaxRound (E : List (Arrow V)) (d : V → WithTop ℝ) : V → WithTop ℝ :=
  E.foldl relax d

/-- The starting table: 0 at the start `s`, infinity everywhere else. -/
def startTable (s : V) : V → WithTop ℝ := fun v => if v = s then 0 else ⊤

/-- The table after `k` rounds of Bellman-Ford from `s`. -/
def table (E : List (Arrow V)) (s : V) (k : ℕ) : V → WithTop ℝ :=
  (relaxRound E)^[k] (startTable s)

end BellmanFord

open BellmanFord

variable {V : Type*} [DecidableEq V]

theorem bf_routeCost_cons (e : Arrow V) (p : List (Arrow V)) :
    routeCost (e :: p) = e.2.2 + routeCost p := by
  simp [routeCost]

theorem bf_routeCost_append (p q : List (Arrow V)) :
    routeCost (p ++ q) = routeCost p + routeCost q := by
  simp [routeCost]

theorem bf_route_append {E : List (Arrow V)} {a b c : V} {p q : List (Arrow V)}
    (hp : IsRoute E a b p) (hq : IsRoute E b c q) : IsRoute E a c (p ++ q) := by
  induction hp with
  | nil => simpa using hq
  | cons he _ ih => exact IsRoute.cons he (ih hq)

theorem bf_route_split {E : List (Arrow V)} {b c : V} {p : List (Arrow V)}
    (hp : IsRoute E b c p) (a : V) (ha : a ∈ p.map Prod.fst ++ [c]) :
    ∃ p1 p2, p = p1 ++ p2 ∧ IsRoute E b a p1 ∧ IsRoute E a c p2 := by
  induction hp with
  | nil x =>
    simp at ha
    subst ha
    exact ⟨[], [], rfl, IsRoute.nil _, IsRoute.nil _⟩
  | @cons x y z w q he hq ih =>
    by_cases hax : a = x
    · subst hax
      exact ⟨[], _, rfl, IsRoute.nil _, IsRoute.cons he hq⟩
    · have ha' : a ∈ q.map Prod.fst ++ [z] := by
        simp only [List.map_cons, List.cons_append, List.mem_cons] at ha
        rcases ha with h | h
        · exact absurd h hax
        · exact h
      obtain ⟨q1, q2, rfl, h1, h2⟩ := ih ha'
      exact ⟨(x, y, w) :: q1, q2, rfl, IsRoute.cons he h1, h2⟩

/-- Cutting loops: with no paying loop reachable from `s`, every route from a reachable
currency can be shortened to one with distinct currencies and no larger cost. -/
theorem bf_route_shorten {E : List (Arrow V)} {s : V}
    (hno : ∀ x q p, IsRoute E s x q → IsRoute E x x p → 0 ≤ routeCost p)
    {a c : V} {p : List (Arrow V)} (hp : IsRoute E a c p) :
    ∀ q, IsRoute E s a q →
      ∃ p', IsRoute E a c p' ∧ routeCost p' ≤ routeCost p ∧ (p'.map Prod.fst ++ [c]).Nodup := by
  induction hp with
  | nil x => intro _ _; exact ⟨[], IsRoute.nil _, le_rfl, by simp⟩
  | @cons x y z w r he hr ih =>
    intro q hq
    have hq' : IsRoute E s y (q ++ [(x, y, w)]) :=
      bf_route_append hq (IsRoute.cons he (IsRoute.nil _))
    obtain ⟨p', hp', hcost, hnd⟩ := ih (q ++ [(x, y, w)]) hq'
    by_cases hx : x ∈ p'.map Prod.fst ++ [z]
    · obtain ⟨p1, p2, rfl, h1, h2⟩ := bf_route_split hp' x hx
      have hloop := hno x q _ hq (IsRoute.cons he h1)
      refine ⟨p2, h2, ?_, ?_⟩
      · rw [bf_routeCost_cons] at hloop ⊢
        rw [bf_routeCost_append] at hcost
        simp only at hloop ⊢
        linarith
      · rw [List.map_append, List.append_assoc] at hnd
        exact (List.nodup_append.1 hnd).2.1
    · refine ⟨(x, y, w) :: p', IsRoute.cons he hp', ?_, ?_⟩
      · rw [bf_routeCost_cons, bf_routeCost_cons]
        simp only
        linarith
      · simp only [List.map_cons, List.cons_append]
        exact List.nodup_cons.2 ⟨hx, hnd⟩

theorem bf_route_length [Fintype V] {p : List (Arrow V)} {c : V}
    (hnd : (p.map Prod.fst ++ [c]).Nodup) : p.length ≤ Fintype.card V - 1 := by
  have := hnd.length_le_card
  simp at this
  omega

theorem bf_relax_le (d : V → WithTop ℝ) (e : Arrow V) (v : V) : relax d e v ≤ d v := by
  unfold relax
  by_cases h : v = e.2.1
  · subst h; simp
  · simp [Function.update_of_ne h]

theorem bf_foldl_le (L : List (Arrow V)) : ∀ (d : V → WithTop ℝ) (v : V),
    L.foldl relax d v ≤ d v := by
  induction L with
  | nil => intro d v; simp
  | cons e L ih =>
    intro d v
    simp only [List.foldl_cons]
    exact (ih _ v).trans (bf_relax_le d e v)

theorem bf_round_le (E : List (Arrow V)) (d : V → WithTop ℝ) (v : V) :
    relaxRound E d v ≤ d v := bf_foldl_le E d v

theorem bf_iterate_le (E : List (Arrow V)) (k : ℕ) : ∀ (d : V → WithTop ℝ) (v : V),
    (relaxRound E)^[k] d v ≤ d v := by
  induction k with
  | zero => intro d v; simp
  | succ k ih =>
    intro d v
    rw [Function.iterate_succ_apply]
    exact (ih _ v).trans (bf_round_le E d v)

theorem bf_foldl_arrow (L : List (Arrow V)) : ∀ (d : V → WithTop ℝ) (e : Arrow V), e ∈ L →
    L.foldl relax d e.2.1 ≤ d e.1 + (e.2.2 : WithTop ℝ) := by
  induction L with
  | nil => intro d e he; simp at he
  | cons e' L ih =>
    intro d e he
    simp only [List.foldl_cons]
    rcases List.mem_cons.1 he with h | h
    · subst h
      refine (bf_foldl_le L _ _).trans ?_
      unfold relax
      simp
    · refine (ih _ e h).trans ?_
      gcongr
      exact bf_relax_le d e' e.1

theorem bf_round_arrow (E : List (Arrow V)) (d : V → WithTop ℝ) {u v : V} {w : ℝ}
    (he : (u, v, w) ∈ E) : relaxRound E d v ≤ d u + (w : WithTop ℝ) :=
  bf_foldl_arrow E d (u, v, w) he

/-- After `k` rounds, the number at the end of a route with at most `k` arrows is no more than
the number at its start plus its cost. -/
theorem bf_iterate_route (E : List (Arrow V)) (k : ℕ) : ∀ (d : V → WithTop ℝ) (a c : V)
    (p : List (Arrow V)), IsRoute E a c p → p.length ≤ k →
    (relaxRound E)^[k] d c ≤ d a + (routeCost p : WithTop ℝ) := by
  induction k with
  | zero =>
    intro d a c p hp hlen
    have : p = [] := List.eq_nil_of_length_eq_zero (by omega)
    subst this
    cases hp
    simp [routeCost]
  | succ k ih =>
    intro d a c p hp hlen
    cases hp with
    | nil =>
      refine (bf_iterate_le E _ d a).trans ?_
      simp [routeCost]
    | @cons _ b _ w q he hq =>
      rw [Function.iterate_succ_apply]
      refine (ih _ b c q hq (by simp at hlen; omega)).trans ?_
      rw [bf_routeCost_cons, WithTop.coe_add, ← add_assoc]
      gcongr
      exact bf_round_arrow E d he

/-- Every number in the table is infinity or the cost of an actual route from the start. -/
def bf_Inv (E : List (Arrow V)) (s : V) (d : V → WithTop ℝ) : Prop :=
  ∀ v, d v = ⊤ ∨ ∃ p, IsRoute E s v p ∧ d v = (routeCost p : WithTop ℝ)

theorem bf_inv_relax {E : List (Arrow V)} {s : V} {d : V → WithTop ℝ} (hd : bf_Inv E s d)
    (e : Arrow V) (he : e ∈ E) : bf_Inv E s (relax d e) := by
  obtain ⟨u, v, w⟩ := e
  intro x
  unfold relax
  by_cases hx : x = v
  · subst hx
    simp only [Function.update_self]
    rcases min_choice (d x) (d u + (w : WithTop ℝ)) with h | h
    · rw [h]; exact hd x
    · rw [h]
      rcases hd u with h' | ⟨p, hp, h'⟩
      · left; rw [h']; simp
      · right
        refine ⟨p ++ [(u, x, w)], bf_route_append hp (IsRoute.cons he (IsRoute.nil _)), ?_⟩
        rw [h', bf_routeCost_append]
        simp [routeCost]
  · simp only [Function.update_of_ne hx]
    exact hd x

theorem bf_inv_foldl {E : List (Arrow V)} {s : V} (L : List (Arrow V)) (hL : ∀ e ∈ L, e ∈ E) :
    ∀ d, bf_Inv E s d → bf_Inv E s (L.foldl relax d) := by
  induction L with
  | nil => intro d hd; simpa using hd
  | cons e L ih =>
    intro d hd
    simp only [List.foldl_cons]
    exact ih (fun e' h => hL e' (List.mem_cons_of_mem _ h)) _
      (bf_inv_relax hd e (hL e (List.mem_cons_self ..)))

theorem bf_inv_table (E : List (Arrow V)) (s : V) (k : ℕ) : bf_Inv E s (table E s k) := by
  induction k with
  | zero =>
    intro v
    simp only [table, Function.iterate_zero, id, startTable]
    by_cases h : v = s
    · subst h; right; exact ⟨[], IsRoute.nil _, by simp [routeCost]⟩
    · left; simp [h]
  | succ k ih =>
    unfold table
    rw [Function.iterate_succ_apply']
    exact bf_inv_foldl E (fun e h => h) _ ih

/-- With no paying loop reachable from the start, the table after `n - 1` rounds is no more
than the cost of any route from the start. -/
theorem bf_table_le_route [Fintype V] (E : List (Arrow V)) (s : V)
    (hno : ∀ x q p, IsRoute E s x q → IsRoute E x x p → 0 ≤ routeCost p) (v : V)
    (p : List (Arrow V)) (hp : IsRoute E s v p) :
    table E s (Fintype.card V - 1) v ≤ (routeCost p : WithTop ℝ) := by
  obtain ⟨p', hp', hcost, hnd⟩ := bf_route_shorten hno hp [] (IsRoute.nil _)
  have h1 := bf_iterate_route E _ (startTable s) s v p' hp' (bf_route_length hnd)
  have h0 : startTable s s = 0 := by simp [startTable]
  rw [h0, zero_add] at h1
  exact h1.trans (WithTop.coe_le_coe.2 hcost)

theorem bf_fixed_route {E : List (Arrow V)} {d : V → WithTop ℝ}
    (hfix : ∀ u v w, (u, v, w) ∈ E → d v ≤ d u + (w : WithTop ℝ))
    {a c : V} {p : List (Arrow V)} (hp : IsRoute E a c p) :
    d c ≤ d a + (routeCost p : WithTop ℝ) := by
  induction hp with
  | nil => simp [routeCost]
  | @cons x y z w q he _ ih =>
    refine ih.trans ?_
    rw [bf_routeCost_cons, WithTop.coe_add, ← add_assoc]
    gcongr
    exact hfix _ _ _ he

#print axioms bf_routeCost_cons
#print axioms bf_routeCost_append
#print axioms bf_route_append
#print axioms bf_route_split
#print axioms bf_route_shorten
#print axioms bf_route_length
#print axioms bf_relax_le
#print axioms bf_foldl_le
#print axioms bf_round_le
#print axioms bf_iterate_le
#print axioms bf_foldl_arrow
#print axioms bf_round_arrow
#print axioms bf_iterate_route
#print axioms bf_inv_relax
#print axioms bf_inv_foldl
#print axioms bf_inv_table
#print axioms bf_table_le_route
#print axioms bf_fixed_route

/-- **Bellman-Ford finds every cheapest route.** On finitely many currencies, n of them, with
any real costs (negative allowed), if no loop pays (every route from a currency back to itself
costs 0 or more), then after n - 1 rounds the table at each currency v is the cheapest route
cost from the start: no route to v costs less, and the number is either infinity (no route)
or the cost of an actual route to v. -/
theorem bellman_ford_n_minus_one_rounds_find_cheapest_routes [Fintype V]
    (E : List (Arrow V)) (s : V)
    (hnoloop : ∀ x p, IsRoute E x x p → 0 ≤ routeCost p) (v : V) :
    (∀ p, IsRoute E s v p → table E s (Fintype.card V - 1) v ≤ (routeCost p : WithTop ℝ)) ∧
    (table E s (Fintype.card V - 1) v = ⊤ ∨
      ∃ p, IsRoute E s v p ∧ table E s (Fintype.card V - 1) v = (routeCost p : WithTop ℝ)) := by
  refine ⟨fun p hp => bf_table_le_route E s (fun x _ p _ hp => hnoloop x p hp) v p hp, ?_⟩
  rcases bf_inv_table E s (Fintype.card V - 1) v with h | h
  · exact Or.inl h
  · exact Or.inr h

/-- **The extra round is a money-machine detector.** On n currencies with any real costs,
the n-th round still lowers some currency's number exactly when some loop reachable from the
start pays: a route from the start reaches a currency x, and a route from x back to x costs
less than 0. -/
theorem extra_round_improves_iff_reachable_loop_pays [Fintype V]
    (E : List (Arrow V)) (s : V) :
    (∃ v, table E s (Fintype.card V) v < table E s (Fintype.card V - 1) v) ↔
      ∃ x q p, IsRoute E s x q ∧ IsRoute E x x p ∧ routeCost p < 0 := by
  constructor
  · rintro ⟨v, hv⟩
    by_contra hcon
    have hno : ∀ x q p, IsRoute E s x q → IsRoute E x x p → 0 ≤ routeCost p := by
      intro x q p hq hp
      by_contra h
      exact hcon ⟨x, q, p, hq, hp, not_le.1 h⟩
    rcases bf_inv_table E s (Fintype.card V) v with h | ⟨p, hp, h⟩
    · rw [h] at hv; exact not_top_lt hv
    · rw [h] at hv
      exact absurd (bf_table_le_route E s hno v p hp) (not_le.2 hv)
  · rintro ⟨x, q, p, hq, hp, hneg⟩
    by_contra hcon
    have hn : 0 < Fintype.card V := Fintype.card_pos_iff.2 ⟨s⟩
    have e : table E s (Fintype.card V) = relaxRound E (table E s (Fintype.card V - 1)) := by
      conv_lhs => rw [show Fintype.card V = (Fintype.card V - 1) + 1 by omega]
      exact Function.iterate_succ_apply' _ _ _
    set d := table E s (Fintype.card V - 1) with hd
    have key : ∀ v, d v ≤ relaxRound E d v := by
      intro v
      have := not_lt.1 (fun h => hcon ⟨v, h⟩)
      rw [e] at this
      exact this
    have hfix : ∀ u v w, (u, v, w) ∈ E → d v ≤ d u + (w : WithTop ℝ) := by
      intro u v w he
      exact (key v).trans (bf_round_arrow E d he)
    have hs : d s ≤ 0 := by
      have := bf_iterate_le E (Fintype.card V - 1) (startTable s) s
      rw [hd]
      unfold table
      simpa [startTable] using this
    have hx : d x ≤ (routeCost q : WithTop ℝ) := by
      have h1 := bf_fixed_route hfix hq
      calc d x ≤ d s + (routeCost q : WithTop ℝ) := h1
        _ ≤ 0 + (routeCost q : WithTop ℝ) := by gcongr
        _ = (routeCost q : WithTop ℝ) := zero_add _
    obtain ⟨r, hr⟩ := WithTop.ne_top_iff_exists.1 (ne_top_of_le_ne_top WithTop.coe_ne_top hx)
    have hl := bf_fixed_route hfix hp
    rw [← hr, ← WithTop.coe_add, WithTop.coe_le_coe] at hl
    linarith

/-- **Profit test and cost test are one test.** For a loop whose rates are all positive,
the rates multiply to more than 1 exactly when the costs, minus the log of each rate,
add to less than 0. -/
theorem rates_multiply_above_one_iff_costs_add_below_zero (rs : List ℝ)
    (hpos : ∀ r ∈ rs, 0 < r) :
    1 < rs.prod ↔ (rs.map fun r => -Real.log r).sum < 0 := by
  have h : ∀ l : List ℝ, (∀ r ∈ l, 0 < r) →
      0 < l.prod ∧ (l.map fun r => -Real.log r).sum = -Real.log l.prod := by
    intro l
    induction l with
    | nil => intro _; simp
    | cons a l ih =>
      intro hl
      obtain ⟨h1, h2⟩ := ih (fun r hr => hl r (List.mem_cons_of_mem _ hr))
      have ha := hl a (List.mem_cons_self ..)
      refine ⟨by rw [List.prod_cons]; exact mul_pos ha h1, ?_⟩
      simp only [List.map_cons, List.sum_cons, List.prod_cons, h2]
      rw [Real.log_mul ha.ne' h1.ne']
      ring
  obtain ⟨h1, h2⟩ := h rs hpos
  rw [h2, neg_lt_zero, Real.log_pos_iff h1.le]

-- The card's market: 0.90 × 0.85 × 1.32 = 1.0098, above 1, so the loop pays.
example : (90 / 100 : ℚ) * (85 / 100) * (132 / 100) = 10098 / 10000 := by norm_num
example : 1 < (90 / 100 : ℚ) * (85 / 100) * (132 / 100) := by norm_num
-- Move the pound-to-dollar rate to 1.30: 0.90 × 0.85 × 1.30 = 0.9945, below 1, no arbitrage.
example : (90 / 100 : ℚ) * (85 / 100) * (130 / 100) = 9945 / 10000 := by norm_num
example : (90 / 100 : ℚ) * (85 / 100) * (130 / 100) < 1 := by norm_num
-- Three currencies: n - 1 = 2 rounds, then one more.
example : 3 - 1 = 2 := by norm_num

#print axioms bellman_ford_n_minus_one_rounds_find_cheapest_routes
#print axioms extra_round_improves_iff_reachable_loop_pays
#print axioms rates_multiply_above_one_iff_costs_add_below_zero
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'bf_routeCost_cons' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_routeCost_append' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_route_append' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_route_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_route_shorten' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_route_length' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_relax_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_foldl_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_round_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_iterate_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_foldl_arrow' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_round_arrow' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_iterate_route' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_inv_relax' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_inv_foldl' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_inv_table' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_table_le_route' depends on axioms: [propext, Classical.choice, Quot.sound]
'bf_fixed_route' depends on axioms: [propext, Classical.choice, Quot.sound]
'bellman_ford_n_minus_one_rounds_find_cheapest_routes' depends on axioms: [propext, Classical.choice, Quot.sound]
'extra_round_improves_iff_reachable_loop_pays' depends on axioms: [propext, Classical.choice, Quot.sound]
'rates_multiply_above_one_iff_costs_add_below_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. An assert is a line that stops the program when a number comes out wrong.
> - **Kill the arbitrage.** In `ARB`, set the 1.32 to 1.30: round 3's offer rises above 0, the verdict flips to no, and no assert fires — both roads agree.
> - **Trust the first rounds.** In `rounds`, change `r == len(CUR) - 1` to `r == len(CUR)`, which never happens: nothing is flagged though the rates still multiply above 1, and the first assert stops it.
> - **Flip the sign.** In `rounds`, change both `- ln(rate)` to `+ ln(rate)`: generous rates look dear, round 3 improves nothing, and again the first assert stops it.

---

## The usual mistake

> [!warning]
> **Reading one negative cost as free money.** The pound-to-dollar leg costs −0.277632, which is no arbitrage: it is a rate above 1, one pound fetching more than a dollar. Only a loop's total counts; getting back to where the money started is the test.
>
> - **Stopping when the table stops changing.** After two rounds USD reads 0.000000; the extra round is where −0.009752 appears.
> - **Crossing the thresholds over.** The product is tested against 1, the cost total against 0, never the other way about: the losing 1.30 market clears 0.994500 > 0 and 0.005515 < 1 too.
> - **Losing the minus sign.** With plus the log the loop totals 0.009752, and the money machine is invisible.

---

## Where you meet it in real life

- **Currency desks.** Triangular arbitrage is hunted this way on streaming rates. Real gaps are a fraction of the 0.98% here, last seconds, and are mostly eaten by the fees.
- **Internet routing.** Distance-vector routing, RIP (the Routing Information Protocol) among others, is this method run by every router at once, the round limit doubling as a hop limit.
- **Deadlines and schedules.** Constraints like "job A starts three hours before job B" become arrows carrying costs, and the set can be met exactly when no loop has a negative total.

> **Say it back**
> Take minus the logarithm of each rate as a cost: multiplying rates becomes adding costs, and a paying loop becomes one whose costs add below zero. Bellman-Ford relaxes every arrow round after round, and after n − 1 rounds it holds every cheapest route, since a cheapest route never visits a currency twice. One extra round is the test: an improvement needs more legs, so it repeats a currency, so a loop pays. On 0.90, 0.85 and 1.32 it drops USD to −0.009752.

---

## What this builds on

- [Dijkstra's algorithm](05-dijkstra.md): cheapest routes, the relax step, and the lock that negative costs break.
- [Logarithms](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md): what a logarithm is, and that it rises with its input.
- [Log laws and log scales](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/06-log-laws-and-log-scales.md): the log of a product is the sum of the logs, the hinge of the card.

## Where this goes next

- [No arbitrage](../../12-Financial%20mathematics/03-Contracts%20and%20No-Arbitrage/02-no-arbitrage-and-the-law-of-one-price.md): the same test, no loop that pays, turned from a detector into the rule that prices a contract.

This card says whether a loop pays, not how much it will take before the rates move to close it: sizing the trade needs prices that move as the trade is made, which is where no-arbitrage pricing begins.

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Bellman, Richard. "On a Routing Problem." *Quarterly of Applied Mathematics* 16 (1958): 87–90. [doi:10.1090/qam/102435](https://doi.org/10.1090/qam/102435). Four pages: the rounds, and why $n$ − 1 of them suffice.
- Ford, L. R. *Network Flow Theory*. RAND Corporation, paper P-923, 1956. [Publisher page](https://www.rand.org/pubs/papers/P923.html). The earlier statement, hence both names.
- Floyd, Robert W. "Algorithm 97: Shortest Path." *Communications of the ACM* 5, no. 6 (1962): 345. [doi:10.1145/367766.368168](https://doi.org/10.1145/367766.368168). The all-pairs loop above, in one paragraph.
- Cormen, Thomas H., Charles E. Leiserson, Ronald L. Rivest, and Clifford Stein. *Introduction to Algorithms*, 4th ed. MIT Press, 2022. [Publisher page](https://mitpress.mit.edu/9780262046305/introduction-to-algorithms/). The textbook treatment, exchange exercise included.
