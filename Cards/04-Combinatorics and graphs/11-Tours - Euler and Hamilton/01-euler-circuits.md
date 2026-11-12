# Euler circuits: a closed route using every edge once exists exactly when the graph is connected and every degree is even

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Tours - Euler and Hamilton](../README.md#s11) → Euler circuits

---

## General Overview

In 1735 Königsberg stood on both banks of the Pregel with two islands in it: four land masses, seven bridges. The town puzzle asked for a walk crossing every bridge exactly once. Nobody managed it, and Leonhard Euler proved nobody could.

Count bridge-ends, not bridges: the island A carries 5, the north bank B 3, the south bank C 3, the east island D 3. That count is a land's **degree** ([Degrees and the handshaking lemma](../09-Graphs%20-%20Dots%20and%20Lines/02-degree-and-handshaking.md)), and all four are odd, which settles it.

Odd is fatal: passing *through* a land spends two bridge-ends, one in and one out, so they pair off. Only the start and the finish leave an end unpaired, so at most two lands may be odd. Königsberg has four.

The count runs forwards too. A snowplough must clear every street of a 3 x 3 grid — nine junctions, 12 streets — and finish at the depot. Four junctions carry three streets, so no closed sweep exists: four extra passes are needed, and the code builds the 16-pass route.

Vocabulary, once. A route repeating no line is a **trail** ([Walks, paths and cycles](../09-Graphs%20-%20Dots%20and%20Lines/03-walks-paths-and-cycles.md)); closed means it ends where it began. A closed trail covering every line once is an **Euler circuit**, the open one an **Euler trail**.

The title uses the formal words: a network of dots and lines is a graph, a dot is a vertex, a line is an edge, and "in one piece" is connected.

**A closed route using every line once exists exactly when the lines sit in one piece and every dot has an even number of line-ends, because passing through a dot spends two of them.**

**What kind of fact this is:** a theorem, proved both ways in Why it works; Hierholzer's splice, Step 4, is the method that builds the route.

### The picture: four lands, seven bridges, all tallies odd

```mermaid
flowchart TB
    B["B, north bank<br/>3 bridge-ends"]
    A["A, Kneiphof island<br/>5 bridge-ends"]
    D["D, east island<br/>3 bridge-ends"]
    C["C, south bank<br/>3 bridge-ends"]
    A -- "two bridges" --- B
    A -- "two bridges" --- C
    A -- "one bridge" --- D
    B -- "one bridge" --- D
    C -- "one bridge" --- D
```

Two bridges reach the north bank, two the south, one the east island: the island's tally is 5. The four tallies add to 14, twice the bridge count.

---

## The formula

Notation first, in words. $G$ is the network, $V$ its dots, $E$ its lines. A line may be repeated — Königsberg's doubled bridges are two lines between one pair — or join a dot to itself, laying two ends there. $\deg(v)$ is a dot's degree, $k$ the count of odd-degree dots, $T$ a trail.

$$\text{some closed trail } T \text{ covers every line of } G \iff G \text{ is in one piece and } \deg(v) \text{ is even at every dot } v$$

**Read it aloud:** one closed sweep covers every line exactly when the network holds together and no dot has an odd number of line-ends.

The open twin is the same statement with $k = 2$: two odd dots, and the trail must run from one to the other.

"In one piece" is asked of the lines, each reachable from every other ([Connected or not](../09-Graphs%20-%20Dots%20and%20Lines/04-connectivity-and-breadth-first-search.md)); dots carrying no line sit out. And $k$ is never odd, the degrees adding to twice the line count — so 0 and 2 exhaust the cases that work.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $G$ | the network of dots and lines | Königsberg | — |
| $V$ | its dots | A, B, C, D | more places to pass |
| $E$ | its lines, repeats allowed | seven bridges | a longer route |
| $\deg(v)$ | line-ends at a dot | deg(A) = 5 | odd ones block a closed route |
| $k$ | dots of odd degree | 4 | 0 closed, 2 open, more none |
| $T$ | a trail: no line repeated | the grid's 16-pass route | — |

### When it holds

- **Finitely many lines.** The proof takes a longest trail, which an endless network need not have.
- **Lines scored honestly.** Score the two north bridges as one and the island reads even, so the test lies.
- **One piece.** Two triangles apart have every degree 2 and no route covering both: the check prints 0 odd dots, no route.
- **Lines, not dots, and no arrows.** Every dot once is [Hamiltonian cycles](03-hamiltonian-cycles.md); one-way lines have their own test ([Directed graphs](../09-Graphs%20-%20Dots%20and%20Lines/06-directed-graphs-and-topological-order.md)).

---

## Why it works

### Step 0: passing through a dot spends two line-ends

Watch a route pass a dot part way along: it arrives on one line and leaves on another, two of that dot's ends spent together. Only the start and the finish spend a single end.

### Step 1: so even degrees and one piece are forced

Suppose a closed trail covers every line. Tally the ends spent at one dot: each visit spends two, the closing arrival pairing with the opening departure. Every line is used once, so all the ends there are spent in pairs — the degree is even. One piece follows too, the stretch of trail between any two lines joining them. Königsberg fails the first test four times over.

### Step 2: a longest trail closes, and leftovers splice into it

Now the other direction: a network in one piece, every degree even. No trail repeats a line, so trails cannot run on for ever: take a longest one. Were it to stop away from its start, that dot would have spent two ends per visit plus the arrival that never left — an odd number — while its degree is even. So a free line hangs there and extends the trail: the longest trail closes.

Were a line unused, then, since the lines sit in one piece, some unused line would touch a dot of the trail. Strip the trail's lines: every dot loses an even number of ends, so the leftovers are even too. Walking them from that dot until stuck comes back — a closed loop. Splice it in there, going round the detour before carrying on, and the trail is longer again. So the longest trail covers every line and closes: an Euler circuit.

### Step 3: two odd dots, and one phantom line

Join the two odd dots with one extra line: every degree turns even, so Step 2 gives a closed route. Delete the phantom line and an open trail is left, running between those two dots. Königsberg with an eighth bridge B-C is the check's second row: B and C rise from 3 to 4, leaving A and D the odd pair, verdict an open trail. Four odd dots or more defeat every ordering, Step 1 allowing two unpaired ends at most.

### Step 4: Hierholzer's method is Step 2, run forwards

Hierholzer's 1873 procedure is Step 2 as instructions. Walk from the start along unused lines until stuck, which means being back at the start. If lines remain, one touches the tour, so begin a fresh loop there and splice it in. The code keeps a stack of dots and writes one down only once no unused line is left at it — the postponement is the splice.

### The picture: two squares sharing a corner, spliced at C

```mermaid
flowchart LR
    A["A"] --- B["B"]
    B --- C["C, the shared corner"]
    C --- D["D"]
    D --- A
    C --- E["E"]
    E --- F["F"]
    F --- G["G"]
    G --- C
```

Every dot is even and the lines are in one piece, so a closed route exists. From A the code returns A-B-C-E-F-G-C-D-A: the first square as far as C, the second square from C back to C, then the rest of the first.

A second proof instead cuts such a network into loops sharing no lines and glues them at shared dots; how far loops reach in general is the Cycle double cover conjecture, in Where this goes next.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| bridge-ends per land | island, north, south, east | A 5, B 3, C 3, D 3 |
| the tallies added | 5 + 3 + 3 + 3 | 14 = 2 × 7 |
| odd lands, and the verdict | 4 is neither 0 nor 2 | **4, no route** |
| an eighth bridge B-C | B, C turn even | **open trail, A to D** |
| the grid's odd junctions | B, D, F, H, paired at 2 + 2 | **4 extra passes** |
| the swept route | 12 streets + 4 repeats | **16 passes, closed** |

Königsberg's walk never existed, and the plough drives 16 street-lengths to clear 12.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Two odd dots read as closed | Königsberg plus a bridge B-C: open trail only | Two odd dots are an open trail's ends |
| Skipping the one-piece test | two triangles apart: 0 odd dots, no route | Even degrees cannot join separate pieces |
| Sweeping the grid unrepeated | 12 streets, 4 odd junctions, no route | A failing network must change, not re-order |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Six networks face the same question, and every verdict comes twice by roads sharing no arithmetic: this card's degree count, and a brute-force hunt trying every order of the lines from every dot, knowing no theorem. Hierholzer builds the routes, audited against the list of lines. The grid's four extra passes come twice too: from pairing the odd junctions, and from trying every set of repeats.

### Python

```python
# Euler circuits -- the check behind the card.  Nothing is imported.  Konigsberg's seven
# bridges, the same map with an eighth, two separate triangles, a figure-eight of two squares,
# and a 3 x 3 street grid before and after four streets are repeated.  Every verdict is
# reached twice: by counting odd dots, and by hunting a route line by line.
def dots(edges): return sorted({v for e in edges for v in e})
def deg(edges, v): return sum((a == v) + (b == v) for a, b in edges)
def odds(edges): return [v for v in dots(edges) if deg(edges, v) % 2]
def steps(edges, start):                            # steps out from one dot, settled by relaxing
    d, both = {start: 0}, [x for a, b in edges for x in ((a, b), (b, a))]
    for a, b in [e for _ in both for e in both]:     # enough passes to reach every ring
        if a in d and d.get(b, len(both)) > d[a] + 1: d[b] = d[a] + 1
    return d
def hunt(here, left, home):                         # road two: try every order of the lines
    if not left: return home is None or here == home
    for i, (u, v) in enumerate(left):
        rest = left[:i] + left[i + 1:]
        if (u == here and hunt(v, rest, home)) or (v == here and hunt(u, rest, home)): return True
    return False
def hierholzer(edges, start):                       # walk till stuck, splice the loops in
    left, stack, route = list(edges), [start], []
    while stack:
        on = [e for e in left if stack[-1] in e]
        if not on: route.append(stack.pop())
        else: left.remove(on[0]); stack.append(on[0][1] if on[0][0] == stack[-1] else on[0][0])
    return route[::-1]
def once_each(edges, route):                        # independent audit of a finished route
    return sorted(tuple(sorted(p)) for p in zip(route, route[1:])) == sorted(tuple(sorted(e)) for e in edges)
def repeats(edges):                                 # cheapest set of repeats, every set tried
    sets = [[e for i, e in enumerate(edges) if m >> i & 1] for m in range(1 << len(edges))]
    return min((s for s in sets if not odds(edges + s)), key=len)
KON = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
EIGHT = [("A", "B"), ("B", "C"), ("C", "D"), ("D", "A"), ("C", "E"), ("E", "F"), ("F", "G"), ("G", "C")]
GRID = [("A", "B"), ("B", "C"), ("D", "E"), ("E", "F"), ("G", "H"), ("H", "I"),
        ("A", "D"), ("D", "G"), ("B", "E"), ("E", "H"), ("C", "F"), ("F", "I")]
EXTRA, ODD = repeats(GRID), odds(GRID); e8 = hierholzer(EIGHT, "A")
CASES = [("Konigsberg, 7 bridges", KON), ("Konigsberg, an eighth bridge B-C", KON + [("B", "C")]),
         ("two separate triangles", [("A", "B"), ("B", "C"), ("C", "A"), ("D", "E"), ("E", "F"), ("F", "D")]),
         ("figure-eight of two squares", EIGHT), ("3 x 3 street grid", GRID), ("grid, 4 streets repeated", GRID + EXTRA)]
say = lambda shut, ajar: "closed route" if shut else ("open trail" if ajar else "no route")
yn = lambda claim: "yes" if claim else "no"          # the two verdict labels, printed below
print(f"{'graph':<36}{'dots':>5}{'lines':>6}{'odd':>4}{'one piece':>10}   {'by degrees':<14}by hand")
for name, es in CASES:
    piece = len(steps(es, es[0][0])) == len(dots(es))
    one = (piece and not odds(es), piece and len(odds(es)) in (0, 2))
    two = (any(hunt(s, tuple(es), s) for s in dots(es)), any(hunt(s, tuple(es), None) for s in dots(es)))
    print(f"{name:<36}{len(dots(es)):>5}{len(es):>6}{len(odds(es)):>4}{yn(piece):>10}   {say(*one):<14}{say(*two)}")
    assert one == two                               # the degree count against the brute-force hunt
print(f"Konigsberg degrees: {', '.join(f'{v} {deg(KON, v)}' for v in dots(KON))}, adding to "
      f"{sum(deg(KON, v) for v in dots(KON))} = 2 x {len(KON)} bridges")
print(f"figure-eight from A, the second square spliced in at C: {'-'.join(e8)}")
swept = hierholzer(GRID + EXTRA, "A")
costs = [steps(GRID, ODD[0])[ODD[i]] + steps(GRID, ODD[j])[ODD[k]] for i, j, k in ((1, 2, 3), (2, 1, 3), (3, 1, 2))]
print(f"grid odd junctions {' '.join(ODD)}: the three ways to pair them cost {costs} extra passes")
print(f"cheapest repeats, every set of streets tried: {len(EXTRA)}, namely {' '.join('-'.join(e) for e in EXTRA)}")
print(f"the swept route, {len(GRID)} streets + {len(EXTRA)} repeats = {len(swept) - 1} passes, closed "
      f"{yn(swept[0] == swept[-1])}, every street once {yn(once_each(GRID + EXTRA, swept))}: {'-'.join(swept)}")
assert once_each(EIGHT, e8) and e8[0] == e8[-1] and len(e8) - 1 == len(EIGHT)
assert len(EXTRA) == min(costs) and len(swept) - 1 == len(GRID) + len(EXTRA)
assert sum(deg(KON, v) for v in dots(KON)) == 2 * len(KON) and len(odds(KON)) == 4
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
graph                                dots lines odd one piece   by degrees    by hand
Konigsberg, 7 bridges                   4     7   4       yes   no route      no route
Konigsberg, an eighth bridge B-C        4     8   2       yes   open trail    open trail
two separate triangles                  6     6   0        no   no route      no route
figure-eight of two squares             7     8   0       yes   closed route  closed route
3 x 3 street grid                       9    12   4       yes   no route      no route
grid, 4 streets repeated                9    16   0       yes   closed route  closed route
Konigsberg degrees: A 5, B 3, C 3, D 3, adding to 14 = 2 x 7 bridges
figure-eight from A, the second square spliced in at C: A-B-C-E-F-G-C-D-A
grid odd junctions B D F H: the three ways to pair them cost [4, 4, 4] extra passes
cheapest repeats, every set of streets tried: 4, namely E-F G-H D-G B-E
the swept route, 12 streets + 4 repeats = 16 passes, closed yes, every street once yes: A-B-C-F-E-D-G-H-I-F-E-B-E-H-G-D-A
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Euler circuits -- the same check as the Python, in Rust.  No crates.  Konigsberg's seven bridges, the
// same map with an eighth, two triangles apart, a figure-eight of squares, and a 3 x 3 street grid before
// and after four streets are repeated.  Every verdict comes twice: odd-dot count, brute hunt.
use std::collections::BTreeMap;         type E = (&'static str, &'static str);
fn dots(edges: &[E]) -> Vec<&'static str> {                   // the dots, in order, no repeats
    let mut v: Vec<&'static str> = edges.iter().flat_map(|&(a, b)| [a, b]).collect(); v.sort(); v.dedup(); v }
fn deg(edges: &[E], v: &str) -> usize {                       // line-ends at one dot
    edges.iter().map(|&(a, b)| (a == v) as usize + (b == v) as usize).sum() }
fn odds(edges: &[E]) -> Vec<&'static str> {                   // the dots of odd degree
    dots(edges).into_iter().filter(|v| deg(edges, v) % 2 == 1).collect() }
fn steps(edges: &[E], start: &'static str) -> BTreeMap<&'static str, usize> {
    let both: Vec<E> = edges.iter().flat_map(|&(a, b)| [(a, b), (b, a)]).collect();
    let (mut d, far) = (BTreeMap::from([(start, 0usize)]), both.len());
    for _ in 0..far { for &(a, b) in &both {                  // enough passes to reach every ring
        if let Some(&k) = d.get(a) { if *d.get(b).unwrap_or(&far) > k + 1 { d.insert(b, k + 1); } } } }
    d }
fn hunt(here: &'static str, left: &[E], home: Option<&'static str>) -> bool {
    if left.is_empty() { return home.map_or(true, |h| h == here); }
    for i in 0..left.len() {                                  // road two: try every order of the lines
        let mut rest = left.to_vec(); let (u, v) = rest.remove(i);
        if (u == here && hunt(v, &rest, home)) || (v == here && hunt(u, &rest, home)) { return true; } }
    false }
fn hierholzer(edges: &[E], start: &'static str) -> Vec<&'static str> {
    let (mut left, mut stack, mut route) = (edges.to_vec(), vec![start], Vec::new());
    while let Some(&v) = stack.last() {                       // walk till stuck, splice the loops in
        match left.iter().position(|e| e.0 == v || e.1 == v) {
            None => { route.push(stack.pop().unwrap()); }
            Some(i) => { let e = left.remove(i); stack.push(if e.0 == v { e.1 } else { e.0 }); } } }
    route.reverse(); route }
fn once_each(edges: &[E], route: &[&'static str]) -> bool {    // independent audit of a finished route
    let key = |a: &'static str, b: &'static str| if a <= b { (a, b) } else { (b, a) };
    let mut walked: Vec<E> = route.windows(2).map(|w| key(w[0], w[1])).collect();
    let mut want: Vec<E> = edges.iter().map(|&(a, b)| key(a, b)).collect();
    walked.sort(); want.sort(); walked == want }
fn repeats(edges: &[E]) -> Vec<E> {                           // cheapest set of repeats, every set tried
    let mut best = edges.to_vec();
    for m in 0..(1u32 << edges.len()) {
        let extra: Vec<E> = (0..edges.len()).filter(|i| m >> i & 1 == 1).map(|i| edges[i]).collect();
        let mut all = edges.to_vec(); all.extend(&extra);
        if odds(&all).is_empty() && extra.len() < best.len() { best = extra; } }
    best }
fn main() {
    let kon: Vec<E> = vec![("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")];
    let eight: Vec<E> = vec![("A", "B"), ("B", "C"), ("C", "D"), ("D", "A"), ("C", "E"), ("E", "F"), ("F", "G"), ("G", "C")];
    let grid: Vec<E> = vec![("A", "B"), ("B", "C"), ("D", "E"), ("E", "F"), ("G", "H"), ("H", "I"),
                            ("A", "D"), ("D", "G"), ("B", "E"), ("E", "H"), ("C", "F"), ("F", "I")];
    let tri: Vec<E> = vec![("A", "B"), ("B", "C"), ("C", "A"), ("D", "E"), ("E", "F"), ("F", "D")];
    let (extra, odd) = (repeats(&grid), odds(&grid));
    let (mut kon8, mut grid2) = (kon.clone(), grid.clone());
    kon8.push(("B", "C")); grid2.extend(&extra);
    let (e8, swept) = (hierholzer(&eight, "A"), hierholzer(&grid2, "A"));
    let cases: Vec<(&str, &Vec<E>)> = vec![("Konigsberg, 7 bridges", &kon),
        ("Konigsberg, an eighth bridge B-C", &kon8), ("two separate triangles", &tri),
        ("figure-eight of two squares", &eight), ("3 x 3 street grid", &grid), ("grid, 4 streets repeated", &grid2)];
    let say = |shut: bool, ajar: bool| if shut { "closed route" } else if ajar { "open trail" } else { "no route" };
    let yn = |claim: bool| if claim { "yes" } else { "no" };  // the two verdict labels, printed below
    println!("{:<36}{:>5}{:>6}{:>4}{:>10}   {:<14}by hand", "graph", "dots", "lines", "odd", "one piece", "by degrees");
    for (name, es) in &cases {
        let (piece, o) = (steps(es, es[0].0).len() == dots(es).len(), odds(es));
        let one = (piece && o.is_empty(), piece && (o.is_empty() || o.len() == 2));
        let two = (dots(es).iter().any(|&s| hunt(s, es, Some(s))), dots(es).iter().any(|&s| hunt(s, es, None)));
        println!("{:<36}{:>5}{:>6}{:>4}{:>10}   {:<14}{}", name, dots(es).len(), es.len(), o.len(),
                 yn(piece), say(one.0, one.1), say(two.0, two.1));
        assert!(one == two); }                                // the degree count against the brute-force hunt
    let kd: Vec<String> = dots(&kon).iter().map(|v| format!("{} {}", v, deg(&kon, v))).collect();
    let total: usize = dots(&kon).iter().map(|v| deg(&kon, v)).sum();
    println!("Konigsberg degrees: {}, adding to {} = 2 x {} bridges", kd.join(", "), total, kon.len());
    println!("figure-eight from A, the second square spliced in at C: {}", e8.join("-"));
    let costs: Vec<usize> = [(1usize, 2usize, 3usize), (2, 1, 3), (3, 1, 2)].iter()
        .map(|&(i, j, k)| steps(&grid, odd[0])[odd[i]] + steps(&grid, odd[j])[odd[k]]).collect();
    println!("grid odd junctions {}: the three ways to pair them cost {:?} extra passes", odd.join(" "), costs);
    let names: Vec<String> = extra.iter().map(|(a, b)| format!("{}-{}", a, b)).collect();
    println!("cheapest repeats, every set of streets tried: {}, namely {}", extra.len(), names.join(" "));
    println!("the swept route, {} streets + {} repeats = {} passes, closed {}, every street once {}: {}", grid.len(),
             extra.len(), swept.len() - 1, yn(swept[0] == swept[swept.len() - 1]), yn(once_each(&grid2, &swept)), swept.join("-"));
    assert!(once_each(&eight, &e8) && e8[0] == e8[e8.len() - 1] && e8.len() - 1 == eight.len());
    assert!(extra.len() == *costs.iter().min().unwrap() && swept.len() - 1 == grid.len() + extra.len());
    assert!(total == 2 * kon.len() && odds(&kon).len() == 4);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
graph                                dots lines odd one piece   by degrees    by hand
Konigsberg, 7 bridges                   4     7   4       yes   no route      no route
Konigsberg, an eighth bridge B-C        4     8   2       yes   open trail    open trail
two separate triangles                  6     6   0        no   no route      no route
figure-eight of two squares             7     8   0       yes   closed route  closed route
3 x 3 street grid                       9    12   4       yes   no route      no route
grid, 4 streets repeated                9    16   0       yes   closed route  closed route
Konigsberg degrees: A 5, B 3, C 3, D 3, adding to 14 = 2 x 7 bridges
figure-eight from A, the second square spliced in at C: A-B-C-E-F-G-C-D-A
grid odd junctions B D F H: the three ways to pair them cost [4, 4, 4] extra passes
cheapest repeats, every set of streets tried: 4, namely E-F G-H D-G B-E
the swept route, 12 streets + 4 repeats = 16 passes, closed yes, every street once yes: A-B-C-F-E-D-G-H-I-F-E-B-E-H-G-D-A
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's rule for every network with finitely many lines, repeated lines and self-joining lines included.

- A closed route using every line once exists exactly when the lines sit in one piece and every dot has an even degree.
- An open route can use every line once, from one dot to a different one. It exists exactly when those two are the only odd dots and the lines sit in one piece.
- On finitely many dots, the degrees add up to twice the line count, so the number of odd dots is never odd.
- It also re-checks the card's numbers: Königsberg's tallies 5, 3, 3, 3 adding to 14, and the eighth bridge leaving A and D odd.
- The same goes for the two triangles' degrees, the figure-eight route, the grid's odd junctions B, D, F, H, and its 16-pass sweep.

Hierholzer's method, the brute-force hunt and the cheapest set of repeats are left to the Python and Rust checks.

```lean
-- Euler circuits: a finite network whose lines may repeat or loop has a closed route using every line exactly once exactly when its lines sit in one piece and every dot has even degree, with an open route between the two odd dots when there are exactly two, and the card's Königsberg, figure-eight and street-grid numbers check out.
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Data.Sym.Sym2
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Algebra.BigOperators.Ring.Nat

/-! A network is a finite multiset `E` of lines, each line a pair of dots `(a, b)`.
A line may be repeated (Königsberg's doubled bridges) or join a dot to itself (a loop, `(a, a)`).
A route is a list of dots; it walks the lines between consecutive dots. -/

namespace EulerCircuits

variable {V : Type*} [DecidableEq V]

/-- The degree of a dot: its line-ends. A repeated line counts each time, a loop counts twice. -/
def degree (E : Multiset (V × V)) (v : V) : ℕ :=
  (E.map Prod.fst).count v + (E.map Prod.snd).count v

/-- The route walks every line of `E` exactly once: the lines between consecutive dots of the
route, taken without direction, are exactly the lines of `E`, with repeats counted. -/
def UsesEveryLineOnce (E : Multiset (V × V)) (route : List V) : Prop :=
  Multiset.ofList ((route.zip route.tail).map fun p => s(p.1, p.2)) = E.map fun p => s(p.1, p.2)

/-- The lines sit in one piece: any two lines are joined through the network, so an end of one
reaches an end of the other. Dots carrying no line sit out. -/
def LinesInOnePiece (E : Multiset (V × V)) : Prop :=
  ∀ e ∈ E, ∀ f ∈ E, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable e.1 f.1

/-! Helper lemmas for the proofs below. -/

theorem degree_cons (p : V × V) (E : Multiset (V × V)) (v : V) :
    degree (p ::ₘ E) v = degree E v + (if v = p.1 then 1 else 0) + (if v = p.2 then 1 else 0) := by
  simp only [degree, Multiset.map_cons, Multiset.count_cons]
  omega
#print axioms degree_cons

theorem degree_add (E F : Multiset (V × V)) (v : V) :
    degree (E + F) v = degree E v + degree F v := by
  simp only [degree, Multiset.map_add, Multiset.count_add]
  omega
#print axioms degree_add

theorem degree_eq_zero_of (E : Multiset (V × V)) (v : V) (h : ∀ p ∈ E, p.1 ≠ v ∧ p.2 ≠ v) :
    degree E v = 0 := by
  simp only [degree, Nat.add_eq_zero_iff, Multiset.count_eq_zero, Multiset.mem_map]
  constructor
  · rintro ⟨p, hp, rfl⟩
    exact (h p hp).1 rfl
  · rintro ⟨p, hp, rfl⟩
    exact (h p hp).2 rfl
#print axioms degree_eq_zero_of

theorem exists_edge_of_degree_pos (E : Multiset (V × V)) (v : V) (h : 0 < degree E v) :
    ∃ p ∈ E, ∃ x, p = (v, x) ∨ p = (x, v) := by
  by_contra hc
  push Not at hc
  have h0 : degree E v = 0 := degree_eq_zero_of E v (fun p hp =>
    ⟨fun h1 => (hc p hp p.2).1 (Prod.ext h1 rfl), fun h2 => (hc p hp p.1).2 (Prod.ext rfl h2)⟩)
  omega
#print axioms exists_edge_of_degree_pos

theorem degree_eq_sum (E : Multiset (V × V)) (v : V) :
    degree E v = ((E.map fun p => s(p.1, p.2)).map (Sym2.lift
      ⟨fun a b => (if v = a then 1 else 0) + (if v = b then 1 else 0),
        fun _ _ => Nat.add_comm _ _⟩)).sum := by
  induction E using Multiset.induction_on with
  | empty => simp [degree]
  | cons p E ih =>
    rw [degree_cons, ih, Multiset.map_cons, Multiset.map_cons, Multiset.sum_cons, Sym2.lift_mk]
    dsimp only
    omega
#print axioms degree_eq_sum

theorem degree_eq_of_uses (E : Multiset (V × V)) (r : List V) (h : UsesEveryLineOnce E r)
    (v : V) : degree E v = degree (Multiset.ofList (r.zip r.tail)) v := by
  rw [degree_eq_sum E v, degree_eq_sum _ v]
  congr 2
  unfold UsesEveryLineOnce at h
  rw [← h, Multiset.map_coe]
#print axioms degree_eq_of_uses

theorem reach_of_mem (E : Multiset (V × V)) (p : V × V) (hp : p ∈ E) :
    (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable p.1 p.2 := by
  obtain ⟨a, b⟩ := p
  by_cases h : a = b
  · subst h
    exact SimpleGraph.Reachable.refl _
  · exact SimpleGraph.Adj.reachable ((SimpleGraph.fromRel_adj _ _ _).2 ⟨h, Or.inl hp⟩)
#print axioms reach_of_mem

theorem reach_mono {E F : Multiset (V × V)} (h : ∀ p ∈ E, p ∈ F) {a b : V}
    (hr : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable a b) :
    (SimpleGraph.fromRel fun a b => (a, b) ∈ F).Reachable a b :=
  hr.mono (fun x y hxy => by
    rw [SimpleGraph.fromRel_adj] at hxy ⊢
    exact ⟨hxy.1, hxy.2.imp (h _) (h _)⟩)
#print axioms reach_mono

theorem reach_filter (E : Multiset (V × V)) (Q : V → Prop) [DecidablePred Q]
    (hQ : ∀ p ∈ E, (Q p.1 ↔ Q p.2)) {a y : V}
    (h : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable a y) (ha : Q a) :
    Q y ∧ (SimpleGraph.fromRel fun a b => (a, b) ∈ E.filter fun p => Q p.1).Reachable a y := by
  rw [SimpleGraph.reachable_iff_reflTransGen] at h
  induction h with
  | refl => exact ⟨ha, SimpleGraph.Reachable.refl _⟩
  | tail _ hbc ih =>
    obtain ⟨hb, hr⟩ := ih
    rw [SimpleGraph.fromRel_adj] at hbc
    obtain ⟨hne, hbc | hcb⟩ := hbc
    · exact ⟨(hQ _ hbc).1 hb, hr.trans (SimpleGraph.Adj.reachable
        ((SimpleGraph.fromRel_adj _ _ _).2 ⟨hne, Or.inl (Multiset.mem_filter.2 ⟨hbc, hb⟩)⟩))⟩
    · have hc := (hQ _ hcb).2 hb
      exact ⟨hc, hr.trans (SimpleGraph.Adj.reachable
        ((SimpleGraph.fromRel_adj _ _ _).2 ⟨hne, Or.inr (Multiset.mem_filter.2 ⟨hcb, hc⟩)⟩))⟩
#print axioms reach_filter

theorem reach_erase (E : Multiset (V × V)) (p : V × V) (u x : V)
    (hux : p = (u, x) ∨ p = (x, u)) {y : V}
    (h : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u y) :
    (SimpleGraph.fromRel fun a b => (a, b) ∈ E.erase p).Reachable u y ∨
      (SimpleGraph.fromRel fun a b => (a, b) ∈ E.erase p).Reachable x y := by
  rw [SimpleGraph.reachable_iff_reflTransGen] at h
  induction h with
  | refl => exact Or.inl (SimpleGraph.Reachable.refl _)
  | @tail b c _ hbc ih =>
    rw [SimpleGraph.fromRel_adj] at hbc
    obtain ⟨hne, hq⟩ := hbc
    by_cases hin : (b, c) ∈ E.erase p ∨ (c, b) ∈ E.erase p
    · have hadj : (SimpleGraph.fromRel fun a b => (a, b) ∈ E.erase p).Adj b c :=
        (SimpleGraph.fromRel_adj _ _ _).2 ⟨hne, hin⟩
      exact ih.imp (fun h => h.trans hadj.reachable) (fun h => h.trans hadj.reachable)
    · push Not at hin
      have hc : c = u ∨ c = x := by
        rcases hq with hq | hq
        · have hp : (b, c) = p := by
            by_contra hne'
            exact hin.1 ((Multiset.mem_erase_of_ne hne').2 hq)
          rcases hux with rfl | rfl
          · exact Or.inr (Prod.mk.inj hp).2
          · exact Or.inl (Prod.mk.inj hp).2
        · have hp : (c, b) = p := by
            by_contra hne'
            exact hin.2 ((Multiset.mem_erase_of_ne hne').2 hq)
          rcases hux with rfl | rfl
          · exact Or.inl (Prod.mk.inj hp).1
          · exact Or.inr (Prod.mk.inj hp).1
      rcases hc with rfl | rfl
      · exact Or.inl (SimpleGraph.Reachable.refl _)
      · exact Or.inr (SimpleGraph.Reachable.refl _)
#print axioms reach_erase

theorem edge_at_start (E : Multiset (V × V)) (u : V) (e : V × V) (he : e ∈ E)
    (h : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u e.1) :
    ∃ p ∈ E, ∃ x, p = (u, x) ∨ p = (x, u) := by
  rw [SimpleGraph.reachable_iff_reflTransGen] at h
  rcases h.cases_head with h | ⟨c, hc, _⟩
  · exact ⟨e, he, e.2, Or.inl (Prod.ext h.symm rfl)⟩
  · rw [SimpleGraph.fromRel_adj] at hc
    rcases hc.2 with h | h
    · exact ⟨(u, c), h, c, Or.inl rfl⟩
    · exact ⟨(c, u), h, c, Or.inr rfl⟩
#print axioms edge_at_start

theorem degree_erase (E : Multiset (V × V)) (p : V × V) (hp : p ∈ E) (u x : V)
    (hx : p = (u, x) ∨ p = (x, u)) (v : V) :
    degree E v = degree (E.erase p) v + (if v = u then 1 else 0) + (if v = x then 1 else 0) := by
  conv_lhs => rw [← Multiset.cons_erase hp]
  rw [degree_cons]
  rcases hx with rfl | rfl
  · rfl
  · simp only
    omega
#print axioms degree_erase

theorem eq_of_degree_zero (E : Multiset (V × V)) (u w : V) (h0 : degree E u = 0)
    (hpar : (degree E u + (if u = u then 1 else 0) + (if u = w then 1 else 0)) % 2 = 0) :
    u = w := by
  by_contra h
  simp [h0, h] at hpar
#print axioms eq_of_degree_zero

theorem reach_of_parity : ∀ n : ℕ, ∀ (E : Multiset (V × V)) (u w : V), Multiset.card E ≤ n →
    (∀ v, (degree E v + (if v = u then 1 else 0) + (if v = w then 1 else 0)) % 2 = 0) →
    (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u w := by
  intro n
  induction n with
  | zero =>
    intro E u w hc hpar
    have hE : E = 0 := Multiset.card_eq_zero.1 (by omega)
    subst hE
    have := eq_of_degree_zero 0 u w (by simp [degree]) (hpar u)
    subst this
    exact SimpleGraph.Reachable.refl _
  | succ n ih =>
    intro E u w hc hpar
    by_cases hd : degree E u = 0
    · have := eq_of_degree_zero E u w hd (hpar u)
      subst this
      exact SimpleGraph.Reachable.refl _
    · obtain ⟨p, hp, x, hx⟩ := exists_edge_of_degree_pos E u (Nat.pos_of_ne_zero hd)
      have hc' : Multiset.card (E.erase p) ≤ n := by
        rw [Multiset.card_erase_of_mem hp, Nat.pred_eq_sub_one]
        omega
      have hr := ih (E.erase p) x w hc' (fun v => by
        have h1 := hpar v
        have h2 := degree_erase E p hp u x hx v
        omega)
      have hr' := reach_mono (fun q hq => Multiset.mem_of_mem_erase hq) hr
      have hux : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u x := by
        rcases hx with rfl | rfl
        · exact reach_of_mem E _ hp
        · exact (reach_of_mem E _ hp).symm
      exact hux.trans hr'
#print axioms reach_of_parity

theorem lines_append : ∀ (rb ra : List V) (u x : V), rb.getLast? = some u → ra.head? = some x →
    ((rb ++ ra).zip (rb ++ ra).tail).map (fun p => s(p.1, p.2)) =
      (rb.zip rb.tail).map (fun p => s(p.1, p.2)) ++
        s(u, x) :: (ra.zip ra.tail).map (fun p => s(p.1, p.2))
  | [], _, _, _, h, _ => by simp at h
  | [a], ra, u, x, h, h' => by
    cases ra with
    | nil => simp at h'
    | cons c t =>
      simp only [List.getLast?_singleton, Option.some.injEq, List.head?_cons] at h h'
      subst h h'
      simp
  | a :: b :: t, ra, u, x, h, h' => by
    have ih := lines_append (b :: t) ra u x (by rw [List.getLast?_cons_cons] at h; exact h) h'
    simp only [List.cons_append, List.tail_cons, List.zip_cons_cons, List.map_cons] at ih ⊢
    rw [ih]
#print axioms lines_append

theorem uses_append (A B : Multiset (V × V)) (ra rb : List V) (u x : V)
    (hb : UsesEveryLineOnce B rb) (ha : UsesEveryLineOnce A ra)
    (hbl : rb.getLast? = some u) (hah : ra.head? = some x) :
    UsesEveryLineOnce (B + (u, x) ::ₘ A) (rb ++ ra) := by
  unfold UsesEveryLineOnce at *
  rw [lines_append rb ra u x hbl hah, ← Multiset.coe_add, ← Multiset.cons_coe, hb, ha]
  simp [Multiset.map_add]
#print axioms uses_append

theorem route_base (E : Multiset (V × V)) (u w : V) (hE : E = 0)
    (hpar : ∀ v, (degree E v + (if v = u then 1 else 0) + (if v = w then 1 else 0)) % 2 = 0) :
    ∃ r : List V, r.head? = some u ∧ r.getLast? = some w ∧ UsesEveryLineOnce E r := by
  subst hE
  have := eq_of_degree_zero 0 u w (by simp [degree]) (hpar u)
  subst this
  exact ⟨[u], rfl, rfl, by simp [UsesEveryLineOnce]⟩
#print axioms route_base

theorem route_of_parity : ∀ n : ℕ, ∀ (E : Multiset (V × V)) (u w : V), Multiset.card E ≤ n →
    (∀ v, (degree E v + (if v = u then 1 else 0) + (if v = w then 1 else 0)) % 2 = 0) →
    (∀ e ∈ E, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u e.1) →
    ∃ r : List V, r.head? = some u ∧ r.getLast? = some w ∧ UsesEveryLineOnce E r := by
  intro n
  induction n with
  | zero =>
    intro E u w hc hpar _
    exact route_base E u w (Multiset.card_eq_zero.1 (by omega)) hpar
  | succ n ih =>
    intro E u w hc hpar hconn
    classical
    by_cases hE : E = 0
    · exact route_base E u w hE hpar
    obtain ⟨e, he⟩ := Multiset.exists_mem_of_ne_zero hE
    obtain ⟨p, hp, x, hx⟩ := edge_at_start E u e he (hconn e he)
    obtain ⟨E', hE'⟩ : ∃ E', E' = E.erase p := ⟨_, rfl⟩
    have hcons : p ::ₘ E' = E := hE' ▸ Multiset.cons_erase hp
    have hcE' : Multiset.card E' ≤ n := by
      rw [hE', Multiset.card_erase_of_mem hp, Nat.pred_eq_sub_one]
      omega
    have hdeg : ∀ v, degree E v = degree E' v + (if v = u then 1 else 0) +
        (if v = x then 1 else 0) := fun v => hE' ▸ degree_erase E p hp u x hx v
    have hpar' : ∀ v, (degree E' v + (if v = x then 1 else 0) +
        (if v = w then 1 else 0)) % 2 = 0 := fun v => by
      have h1 := hpar v
      have h2 := hdeg v
      omega
    have hxw : (SimpleGraph.fromRel fun a b => (a, b) ∈ E').Reachable x w :=
      reach_of_parity _ E' x w le_rfl hpar'
    obtain ⟨Q, hQdef⟩ : ∃ Q : V → Prop,
        Q = fun v => (SimpleGraph.fromRel fun a b => (a, b) ∈ E').Reachable x v := ⟨_, rfl⟩
    have hQx : Q x := by subst hQdef; exact SimpleGraph.Reachable.refl _
    have hQw : Q w := by rw [hQdef]; exact hxw
    have hQ : ∀ q ∈ E', (Q q.1 ↔ Q q.2) := fun q hq => by
      rw [hQdef]
      exact ⟨fun h => h.trans (reach_of_mem E' q hq),
        fun h => h.trans (reach_of_mem E' q hq).symm⟩
    have hQ' : ∀ q ∈ E', (¬Q q.1 ↔ ¬Q q.2) := fun q hq => not_congr (hQ q hq)
    obtain ⟨A, hA⟩ : ∃ A, A = E'.filter fun q => Q q.1 := ⟨_, rfl⟩
    obtain ⟨B, hB⟩ : ∃ B, B = E'.filter fun q => ¬Q q.1 := ⟨_, rfl⟩
    have hAB : A + B = E' := by rw [hA, hB]; exact Multiset.filter_add_not _ _
    have hdA : ∀ v, ¬Q v → degree A v = 0 := fun v hv => degree_eq_zero_of A v (fun q hq => by
      rw [hA, Multiset.mem_filter] at hq
      exact ⟨fun h => hv (h ▸ hq.2), fun h => hv (h ▸ (hQ q hq.1).1 hq.2)⟩)
    have hdB : ∀ v, Q v → degree B v = 0 := fun v hv => degree_eq_zero_of B v (fun q hq => by
      rw [hB, Multiset.mem_filter] at hq
      exact ⟨fun h => hq.2 (h ▸ hv), fun h => (hQ' q hq.1).1 hq.2 (h ▸ hv)⟩)
    have hdE' : ∀ v, degree E' v = degree A v + degree B v := fun v => by
      rw [← degree_add, hAB]
    have hparA : ∀ v, (degree A v + (if v = x then 1 else 0) +
        (if v = w then 1 else 0)) % 2 = 0 := by
      intro v
      by_cases hv : Q v
      · have h1 := hpar' v
        have h2 := hdE' v
        have h3 := hdB v hv
        omega
      · have h1 : v ≠ x := fun h => hv (h ▸ hQx)
        have h2 : v ≠ w := fun h => hv (h ▸ hQw)
        simp [hdA v hv, h1, h2]
    have hparB : ∀ v, (degree B v + (if v = u then 1 else 0) +
        (if v = u then 1 else 0)) % 2 = 0 := by
      intro v
      by_cases hv : Q v
      · rw [hdB v hv]
        omega
      · have h1 : v ≠ x := fun h => hv (h ▸ hQx)
        have h2 : v ≠ w := fun h => hv (h ▸ hQw)
        have h3 := hpar' v
        have h4 := hdE' v
        have h5 := hdA v hv
        rw [if_neg h1, if_neg h2] at h3
        omega
    have hconnA : ∀ e ∈ A, (SimpleGraph.fromRel fun a b => (a, b) ∈ A).Reachable x e.1 := by
      intro e he
      rw [hA, Multiset.mem_filter] at he
      rw [hA]
      exact (reach_filter E' Q hQ (by rw [hQdef] at he; exact he.2) hQx).2
    have hconnB : ∀ e ∈ B, (SimpleGraph.fromRel fun a b => (a, b) ∈ B).Reachable u e.1 := by
      intro e he
      rw [hB, Multiset.mem_filter] at he
      have heE : e ∈ E := by rw [← hcons]; exact Multiset.mem_cons_of_mem he.1
      have hr := reach_erase E p u x hx (hconn e heE)
      rw [← hE'] at hr
      rcases hr with h | h
      · have hu : ¬Q u := fun hu => he.2 (by
          rw [hQdef] at hu ⊢
          exact hu.trans h)
        rw [hB]
        exact (reach_filter E' (fun v => ¬Q v) hQ' h hu).2
      · exact absurd (by rw [hQdef]; exact h) he.2
    have hcA : Multiset.card A ≤ n := by
      have := Multiset.card_le_card (Multiset.le_iff_exists_add.2 ⟨B, hAB.symm⟩)
      omega
    have hcB : Multiset.card B ≤ n := by
      have := Multiset.card_le_card (Multiset.le_iff_exists_add.2 ⟨A, (add_comm A B ▸ hAB).symm⟩)
      omega
    obtain ⟨ra, ha1, ha2, ha3⟩ := ih A x w hcA hparA hconnA
    obtain ⟨rb, hb1, hb2, hb3⟩ := ih B u u hcB hparB hconnB
    refine ⟨rb ++ ra, by simp [hb1], by simp [ha2], ?_⟩
    have huse := uses_append A B ra rb u x hb3 ha3 hb2 ha1
    unfold UsesEveryLineOnce at huse ⊢
    rw [huse, ← hcons, ← hAB]
    rcases hx with rfl | rfl
    · simp only [Multiset.map_cons, Multiset.map_add, Multiset.add_cons]
      rw [add_comm]
    · simp only [Multiset.map_cons, Multiset.map_add, Multiset.add_cons, Sym2.eq_swap]
      rw [add_comm]
#print axioms route_of_parity

theorem route_parity : ∀ (r : List V) (a b : V), r.head? = some a → r.getLast? = some b → ∀ v,
    (degree (Multiset.ofList (r.zip r.tail)) v + (if v = a then 1 else 0) +
      (if v = b then 1 else 0)) % 2 = 0
  | [], _, _, h, _, _ => by simp at h
  | [c], a, b, ha, hb, v => by
    simp only [List.head?_cons, List.getLast?_singleton, Option.some.injEq] at ha hb
    subst ha hb
    have : degree (Multiset.ofList ([c].zip [c].tail)) v = 0 := by simp [degree]
    rw [this]
    split_ifs <;> omega
  | c :: d :: t, a, b, ha, hb, v => by
    have ih := route_parity (d :: t) d b rfl (by rw [List.getLast?_cons_cons] at hb; exact hb) v
    simp only [List.head?_cons, Option.some.injEq] at ha
    subst ha
    have : (Multiset.ofList ((c :: d :: t).zip (c :: d :: t).tail)) =
        (c, d) ::ₘ Multiset.ofList ((d :: t).zip (d :: t).tail) := rfl
    rw [this, degree_cons]
    simp only at ih ⊢
    omega
#print axioms route_parity

theorem mem_of_uses (E : Multiset (V × V)) (r : List V) (h : UsesEveryLineOnce E r)
    (e : V × V) (he : e ∈ E) : e.1 ∈ r := by
  have hm : s(e.1, e.2) ∈ (Multiset.ofList ((r.zip r.tail).map fun p => s(p.1, p.2))) := by
    unfold UsesEveryLineOnce at h
    rw [h]
    exact Multiset.mem_map_of_mem _ he
  rw [Multiset.mem_coe, List.mem_map] at hm
  obtain ⟨⟨a, b⟩, hab, heq⟩ := hm
  have hz := List.of_mem_zip hab
  rcases Sym2.eq_iff.1 heq with ⟨h1, _⟩ | ⟨_, h2⟩
  · rw [← h1]; exact hz.1
  · rw [← h2]; exact List.mem_of_mem_tail hz.2
#print axioms mem_of_uses

theorem route_reach (E : Multiset (V × V)) : ∀ r : List V,
    (∀ p ∈ r.zip r.tail, s(p.1, p.2) ∈ E.map fun q => s(q.1, q.2)) →
    ∀ a ∈ r, ∀ b ∈ r, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable a b
  | [], _, a, ha, _, _ => by simp at ha
  | [c], _, a, ha, b, hb => by
    simp only [List.mem_singleton] at ha hb
    subst ha hb
    exact SimpleGraph.Reachable.refl _
  | c :: d :: t, h, a, ha, b, hb => by
    have ih := route_reach E (d :: t) (fun p hp => h p (List.mem_cons_of_mem _ hp))
    have hcd : (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable c d := by
      have hm := h (c, d) List.mem_cons_self
      simp only [Multiset.mem_map] at hm
      obtain ⟨q, hq, hq'⟩ := hm
      rcases Sym2.eq_iff.1 hq' with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · rw [← h1, ← h2]; exact reach_of_mem E q hq
      · rw [← h1, ← h2]; exact (reach_of_mem E q hq).symm
    have hd : ∀ y ∈ c :: d :: t, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable y d := by
      intro y hy
      rcases List.mem_cons.1 hy with rfl | hy
      · exact hcd
      · exact ih y hy d List.mem_cons_self
    exact (hd a ha).trans (hd b hb).symm
#print axioms route_reach

theorem one_piece_of_uses (E : Multiset (V × V)) (r : List V) (h : UsesEveryLineOnce E r) :
    LinesInOnePiece E := by
  intro e he f hf
  apply route_reach E r _ e.1 (mem_of_uses E r h e he) f.1 (mem_of_uses E r h f hf)
  intro p hp
  unfold UsesEveryLineOnce at h
  rw [← h]
  exact Multiset.mem_coe.2 (List.mem_map.2 ⟨p, hp, rfl⟩)
#print axioms one_piece_of_uses

/-- Euler's and Hierholzer's theorem. A finite network (lines may repeat or loop) has a closed
route using every line exactly once exactly when its lines sit in one piece and every dot has an
even number of line-ends. -/
theorem closed_route_using_every_line_once_iff_one_piece_and_even_degrees
    (E : Multiset (V × V)) :
    (∃ route : List V, route.head? = route.getLast? ∧ UsesEveryLineOnce E route) ↔
      LinesInOnePiece E ∧ ∀ v : V, Even (degree E v) := by
  constructor
  · rintro ⟨r, hhl, hr⟩
    refine ⟨one_piece_of_uses E r hr, fun v => ?_⟩
    rw [degree_eq_of_uses E r hr v]
    cases hh : r.head? with
    | none =>
      have : r = [] := List.head?_eq_none_iff.1 hh
      subst this
      simp [degree]
    | some a =>
      have hl : r.getLast? = some a := hhl.symm.trans hh
      have := route_parity r a a hh hl v
      rw [Nat.even_iff]
      omega
  · rintro ⟨h1, h2⟩
    by_cases hE : E = 0
    · subst hE
      exact ⟨[], rfl, by simp [UsesEveryLineOnce]⟩
    · obtain ⟨e, he⟩ := Multiset.exists_mem_of_ne_zero hE
      obtain ⟨r, ha, hb, hr⟩ := route_of_parity _ E e.1 e.1 le_rfl (fun v => by
        have := Nat.even_iff.1 (h2 v)
        omega) (fun f hf => h1 e he f hf)
      exact ⟨r, by rw [ha, hb], hr⟩

/-- The open twin. For two different dots u and w, a route from u to w using every line exactly
once exists exactly when the lines sit in one piece and u and w are the only dots of odd degree. -/
theorem open_route_using_every_line_once_iff_one_piece_and_two_odd_ends
    (E : Multiset (V × V)) (u w : V) (huw : u ≠ w) :
    (∃ route : List V, route.head? = some u ∧ route.getLast? = some w ∧ UsesEveryLineOnce E route) ↔
      LinesInOnePiece E ∧ ∀ v : V, (Odd (degree E v) ↔ v = u ∨ v = w) := by
  constructor
  · rintro ⟨r, ha, hb, hr⟩
    refine ⟨one_piece_of_uses E r hr, fun v => ?_⟩
    have hp := route_parity r u w ha hb v
    rw [← degree_eq_of_uses E r hr v] at hp
    rw [Nat.odd_iff]
    by_cases hu : v = u
    · subst hu
      rw [if_pos rfl, if_neg huw] at hp
      simp only [true_or, iff_true]
      omega
    · by_cases hw : v = w
      · subst hw
        rw [if_neg hu, if_pos rfl] at hp
        simp only [or_true, iff_true]
        omega
      · rw [if_neg hu, if_neg hw] at hp
        simp only [hu, hw, or_self, iff_false]
        omega
  · rintro ⟨h1, h2⟩
    have hpar : ∀ v, (degree E v + (if v = u then 1 else 0) +
        (if v = w then 1 else 0)) % 2 = 0 := by
      intro v
      have h := h2 v
      rw [Nat.odd_iff] at h
      by_cases hu : v = u
      · subst hu
        rw [if_pos rfl, if_neg huw]
        have := h.2 (Or.inl rfl)
        omega
      · by_cases hw : v = w
        · subst hw
          rw [if_neg hu, if_pos rfl]
          have := h.2 (Or.inr rfl)
          omega
        · rw [if_neg hu, if_neg hw]
          have : ¬degree E v % 2 = 1 := fun hd => (h.1 hd).elim hu hw
          omega
    have hu : 0 < degree E u := ((h2 u).2 (Or.inl rfl)).pos
    obtain ⟨p, hp, x, hx⟩ := exists_edge_of_degree_pos E u hu
    have hconn : ∀ f ∈ E, (SimpleGraph.fromRel fun a b => (a, b) ∈ E).Reachable u f.1 := by
      intro f hf
      rcases hx with rfl | rfl
      · exact h1 _ hp f hf
      · exact (reach_of_mem E _ hp).symm.trans (h1 _ hp f hf)
    exact route_of_parity _ E u w le_rfl hpar hconn

/-- The handshake count. On finitely many dots the degrees add up to twice the number of lines,
so the number of odd dots is never odd. -/
theorem degrees_add_to_twice_the_lines [Fintype V] (E : Multiset (V × V)) :
    ∑ v, degree E v = 2 * Multiset.card E ∧
      Even (Finset.univ.filter fun v => Odd (degree E v)).card := by
  have hsum : ∑ v, degree E v = 2 * Multiset.card E := by
    induction E using Multiset.induction_on with
    | empty => simp [degree]
    | cons p E ih =>
      simp only [degree_cons, Finset.sum_add_distrib, ih, Multiset.card_cons]
      simp
      omega
  refine ⟨hsum, ?_⟩
  rw [← Finset.even_sum_iff_even_card_odd, hsum]
  exact even_two_mul _

-- Königsberg: A = 0 (island), B = 1 (north bank), C = 2 (south bank), D = 3 (east island).
def konigsberg : Multiset (Fin 4 × Fin 4) :=
  {(0, 1), (0, 1), (0, 2), (0, 2), (0, 3), (1, 3), (2, 3)}

-- Bridge-ends per land: A 5, B 3, C 3, D 3.
example : degree konigsberg 0 = 5 ∧ degree konigsberg 1 = 3 ∧
    degree konigsberg 2 = 3 ∧ degree konigsberg 3 = 3 := by decide
-- The tallies add to 14 = 2 × 7 bridges.
example : ∑ v, degree konigsberg v = 14 ∧ Multiset.card konigsberg = 7 := by decide
-- All four lands are odd: 4 is neither 0 nor 2.
example : (Finset.univ.filter fun v => Odd (degree konigsberg v)) = Finset.univ := by decide
-- An eighth bridge B-C: B and C rise to 4, leaving A and D the odd pair.
example : (Finset.univ.filter fun v => Odd (degree ((1, 2) ::ₘ konigsberg) v)) = {0, 3} := by
  decide

-- Two triangles apart, A-B-C and D-E-F: every degree is 2, so 0 odd dots, yet no route covers both.
example : ∀ v : Fin 6,
    degree ({(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)} : Multiset (Fin 6 × Fin 6)) v = 2 := by
  decide

-- The figure-eight of two squares: A..G = 0..6, the shared corner C = 2.
def figureEight : Multiset (Fin 7 × Fin 7) :=
  {(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 5), (5, 6), (6, 2)}

-- Every dot is even.
example : ∀ v, Even (degree figureEight v) := by decide
-- The route A-B-C-E-F-G-C-D-A uses every line once and closes.
example : UsesEveryLineOnce figureEight [0, 1, 2, 4, 5, 6, 2, 3, 0] := by
  unfold UsesEveryLineOnce; decide

-- The 3 x 3 street grid: junctions A..I = 0..8, 12 streets.
def grid : Multiset (Fin 9 × Fin 9) :=
  {(0, 1), (1, 2), (3, 4), (4, 5), (6, 7), (7, 8),
   (0, 3), (3, 6), (1, 4), (4, 7), (2, 5), (5, 8)}

-- 12 streets; the odd junctions are B, D, F, H.
example : Multiset.card grid = 12 := by decide
example : (Finset.univ.filter fun v => Odd (degree grid v)) = {1, 3, 5, 7} := by decide
-- Repeat the four streets E-F, G-H, D-G, B-E: every junction turns even.
example : ∀ v, Even (degree (grid + {(4, 5), (6, 7), (3, 6), (1, 4)}) v) := by decide
-- The swept route A-B-C-F-E-D-G-H-I-F-E-B-E-H-G-D-A: 16 passes, closed, every street once.
example : UsesEveryLineOnce (grid + {(4, 5), (6, 7), (3, 6), (1, 4)})
    [0, 1, 2, 5, 4, 3, 6, 7, 8, 5, 4, 1, 4, 7, 6, 3, 0] := by
  unfold UsesEveryLineOnce; decide

#print axioms closed_route_using_every_line_once_iff_one_piece_and_even_degrees
#print axioms open_route_using_every_line_once_iff_one_piece_and_two_odd_ends
#print axioms degrees_add_to_twice_the_lines

end EulerCircuits
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'EulerCircuits.degree_cons' depends on axioms: [propext, Quot.sound]
'EulerCircuits.degree_add' depends on axioms: [propext, Quot.sound]
'EulerCircuits.degree_eq_zero_of' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.exists_edge_of_degree_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.degree_eq_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.degree_eq_of_uses' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.reach_of_mem' depends on axioms: [propext, Quot.sound]
'EulerCircuits.reach_mono' depends on axioms: [propext, Quot.sound]
'EulerCircuits.reach_filter' depends on axioms: [propext, Quot.sound]
'EulerCircuits.reach_erase' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.edge_at_start' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.degree_erase' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.eq_of_degree_zero' depends on axioms: [propext, Quot.sound]
'EulerCircuits.reach_of_parity' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.lines_append' depends on axioms: [propext]
'EulerCircuits.uses_append' depends on axioms: [propext, Quot.sound]
'EulerCircuits.route_base' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.route_of_parity' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.route_parity' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.mem_of_uses' depends on axioms: [propext, Quot.sound]
'EulerCircuits.route_reach' depends on axioms: [propext, Quot.sound]
'EulerCircuits.one_piece_of_uses' depends on axioms: [propext, Quot.sound]
'EulerCircuits.closed_route_using_every_line_once_iff_one_piece_and_even_degrees' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.open_route_using_every_line_once_iff_one_piece_and_two_odd_ends' depends on axioms: [propext, Classical.choice, Quot.sound]
'EulerCircuits.degrees_add_to_twice_the_lines' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Start the splice elsewhere.** Change `hierholzer(EIGHT, "A")` to `hierholzer(EIGHT, "E")`: the route becomes E-C-B-A-D-C-G-F-E, the *first* square now spliced in at C.
> - **Take a street out of the grid.** Delete `("B", "E")` from `GRID`: eleven streets, odd junctions D E F H, repeats down to 3, the sweep to 14 passes. Both roads move together, so every assert holds.
> - **Break the test.** Change `in (0, 2)` to `in (0, 2, 4)`: the degree road now calls four odd dots passable, the hunt still says no, and the first assert stops the program on Königsberg's row.

---

## The usual mistake

> [!warning]
> **Asking for every dot once instead of every line once.** Königsberg's four lands can be toured one after another and back to the start; its seven bridges cannot be walked in one go. Covering lines is a degree count; covering dots is [Hamiltonian cycles](03-hamiltonian-cycles.md), for which no cheap test is known.
>
> - **Two odd dots read as a closed tour.** They give an *open* trail, from one odd dot to the other.
> - **Forgetting the one-piece test.** Two triangles apart have every degree 2 and 0 odd dots, and no route covers both: even degrees are half the theorem.
> - **Mis-scoring lines.** A repeated line counts separately, a self-joining line lays two ends; score them loosely and the arithmetic lies.
> - **Crediting Euler with both halves.** His 1735 argument rules the walk out when too many lands are odd. That the test is *enough* is Hierholzer's, in 1873.

---

## Where you meet it in real life

- **Snowploughs, gritters, sweepers, postal rounds.** Every line must be covered and the depot wants the vehicle back. Once streets have lengths and the repeats must be picked cheaply, the question becomes [The Chinese postman](02-chinese-postman.md).
- **Reading a genome.** Overlapping fragments are lines and a reconstruction is a trail covering them, so sequence assembly rests on Euler circuits, not dot tours — the trick of [De Bruijn sequences](05-de-bruijn-sequences.md).
- **One-stroke drawing, cutter paths, inspection routes.** "Without lifting the pen" is the open case: with two odd dots, start at one.

> **Say it back**
> A closed route using every line once is an Euler circuit. Passing through a dot spends two of its line-ends, so every degree must be even and the lines must sit in one piece. Those conditions are enough as well: a longest trail must close, and leftovers splice in as detours — Hierholzer's method. Two odd dots give an open trail instead. Königsberg's four lands are all odd, so its bridges cannot be walked in one go; a plough on 12 grid streets meets four odd junctions and needs four extra passes.

---

## What this builds on

- [Degrees and the handshaking lemma](../09-Graphs%20-%20Dots%20and%20Lines/02-degree-and-handshaking.md): the degree, and why odd dots come in pairs.
- [Connected or not](../09-Graphs%20-%20Dots%20and%20Lines/04-connectivity-and-breadth-first-search.md): what "in one piece" means, and the flood that tests it.

## Where this goes next

- [The Chinese postman](02-chinese-postman.md): choosing the repeats at least cost once streets have lengths.
- [Hamiltonian cycles](03-hamiltonian-cycles.md): every dot once instead of every line once, an easy test turned hard search.
- [De Bruijn sequences](05-de-bruijn-sequences.md): Euler circuits at work, building the shortest string holding every window.
- Cycle double cover: the conjecture that any network with no single line whose removal splits it has loops covering every line exactly twice, still unproved.

This card says whether a closed sweep exists and builds one when it does; the cheapest way to fix a network that fails is [The Chinese postman](02-chinese-postman.md).

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Euler, Leonhard. "Solutio problematis ad geometriam situs pertinentis." *Commentarii academiae scientiarum Petropolitanae* 8 (1741): 128–140; written 1735, in the volume for 1736, catalogued E53. [Euler Archive page, with the full text](https://scholarlycommons.pacific.edu/euler-works/53/). The bridges, and the half ruling walks out.
- Hierholzer, Carl, and Chr. Wiener. "Ueber die Möglichkeit, einen Linienzug ohne Wiederholung und ohne Unterbrechung zu umfahren." *Mathematische Annalen* 6 (1873): 30–32. [doi:10.1007/BF01442866](https://doi.org/10.1007/BF01442866). The other half, and the code's splice.
- Diestel, Reinhard. *Graph Theory*, 5th ed. Springer, 2017. [Publisher page](https://link.springer.com/book/10.1007/978-3-662-53622-3). Section 1.8, the modern statement.
- Biggs, Norman L., E. Keith Lloyd, and Robin J. Wilson. *Graph Theory 1736–1936*. Oxford University Press, paperback 1999. [Publisher page](https://global.oup.com/academic/product/graph-theory-1736-1936-9780198539162). Translations of both papers.
