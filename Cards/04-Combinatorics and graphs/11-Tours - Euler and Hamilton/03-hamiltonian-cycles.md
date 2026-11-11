# Hamiltonian cycles: visit every vertex once and return, with no quick test, but enough edges guarantee one

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Tours - Euler and Hamilton](../README.md#s11) → Hamiltonian cycles

---

## General Overview

A distribution warehouse is built as a cube: eight corners, a walkway along each of its twelve edges. Number the corners 0 to 7 in three binary digits, one per direction of the building; two corners share a walkway exactly when their codes differ in one digit.

A courier signs a sheet at every corner, walking only the walkways, signing nowhere twice, finishing where the round began. One round works: 0, 1, 3, 2, 6, 7, 5, 4, back to 0. Six such rounds exist.

A tour like that, every vertex once and then home, is a **Hamiltonian cycle**. The twin question asks for every *edge* once: that is Euler's, and degrees settle it in a line ([Euler circuits](01-euler-circuits.md)). Swapping "edge" for "vertex" changes everything. No quick test is known, and since Karp's 1972 list this has been a standard hard problem. That list gathers problems tied so tightly that a quick test for any one would give a quick test for all.

Enough edges still force a round; that guarantee is this card. No count of edges explains a failure, though. Ten depots on fifteen links, three at each — the Petersen network, as well wired per depot as a cube corner — carry no round. A search over all 274 partial routes confirms it.

**A Hamiltonian cycle visits every vertex once and comes home; no quick test for one is known, but every vertex reaching at least half the vertices guarantees one.**

**What kind of fact this is:** a theorem, Dirac's, proved on this card in Why it works; the Hamiltonian cycle itself is a definition.

### The picture: the warehouse, floor by floor

```mermaid
flowchart TB
    subgraph U["upper floor"]
        direction LR
        c4["4 = 100"] --- c5["5 = 101"]
        c6["6 = 110"] --- c7["7 = 111"]
        c4 --- c6
        c5 --- c7
    end
    subgraph G["ground floor"]
        direction LR
        c0["0 = 000"] --- c1["1 = 001"]
        c2["2 = 010"] --- c3["3 = 011"]
        c0 --- c2
        c1 --- c3
    end
    c0 --- c4
    c1 --- c5
    c2 --- c6
    c3 --- c7
```

Twelve walkways: four per floor, four between them. The round above takes three ground walkways, a riser, three upstairs, and the last riser home.

---

## The formula

Notation first, in words. A network of dots and lines is $G$: dots are vertices, lines edges ([Graphs](../09-Graphs%20-%20Dots%20and%20Lines/01-graphs-vertices-and-edges.md)). The vertex count is $n$; the edges at one vertex are its degree, $\deg(v)$ ([Degrees and the handshaking lemma](../09-Graphs%20-%20Dots%20and%20Lines/02-degree-and-handshaking.md)). A network's smallest degree is $\delta(G)$, the Greek letter delta, read "the minimum degree of G".

A **Hamiltonian cycle** lists every vertex once, an edge joining each to the next and the last back to the first:

$$x_1 \to x_2 \to \cdots \to x_n \to x_1$$

Dirac's theorem, from 1952, is the guarantee:

$$\text{if } n \ge 3 \text{ and } \delta(G) \ge n/2, \text{ then } G \text{ has a Hamiltonian cycle}$$

**Read it aloud:** three vertices or more, each reaching at least half of them, is enough for a round through all.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $G$ | the network: vertices and edges | 8 corners, 12 walkways | — |
| $n$ | how many vertices | 8 | the bar rises with it |
| $\deg(v)$ | edges at one vertex | 3 at every corner | rounds get easier to find |
| $\delta(G)$ | the smallest degree anywhere | 3 | at half of $n$ the guarantee fires |
| $n/2$ | half the vertices: Dirac's bar | 4 | harder to clear |
| $x_1$, $x_i$, $x_k$, $x_n$ | a route's vertices in order: a full round ends at $x_n$, a part-route at $x_k$, with $x_i$ along the way | 0, 1, 3, 2, 6, 7, 5, 4 | — |

### When it holds

- **Three vertices or more, simply joined.** Two vertices and one edge make no cycle; a repeated edge, or an edge from a vertex to itself, serves no round.
- **Half exactly is enough.** Four gangways across the middle, each joining a corner to the opposite corner, lift every degree to 4 on a network of 8: the bar met exactly, and 72 rounds.
- **One way only.** Below the bar the theorem says nothing — the cube sits at degree 3 against a bar of 4, with six rounds regardless.

---

## Why it works

### Step 0: improve a route, rather than test the network

The proof never asks whether the network has a round. It takes a longest route and shows that enough degree closes it into a loop with nothing left out. Twice it assumes the opposite and counts until something impossible appears ([Proof by contradiction](../../01-Foundations/06-Proof/03-proof-by-contradiction.md)).

### Step 1: the ends of a longest route have nowhere new to go

Let $x_1$ and $x_k$ end a route with no repeats, through as many vertices as any route in the network. A neighbour of $x_1$ off that route could be hung on the front, making a longer one — so every neighbour of either end already lies on it.

### Step 2: the ends' neighbours must collide, and the collision closes the route

Each end has at least half of $n$ neighbours, all on the route. Mark where $x_1$'s neighbours sit, and mark one step past each of $x_k$'s: two lists, at least $n$ marks between them, in the fewer than $n$ positions after the first. Two marks must land together, giving a vertex $x_i$ joined to $x_1$ with the vertex before it joined to $x_k$.

That collision closes the route: from $x_1$ jump to $x_i$, run forward to $x_k$, jump back to the vertex before $x_i$, run backwards to $x_1$, every vertex used once.

### Step 3: the loop cannot have left a vertex out

The loop holds all of $x_1$'s neighbours, so more than half the vertices sit on it. Suppose one sits outside. Joined to the loop anywhere, it lets the loop be cut open there, and that route with the stray on the end beats the longest. Joined nowhere, its neighbours all lie outside, where fewer than half the vertices remain. Impossible either way, so the loop is a Hamiltonian cycle.

<details>
<summary>Detailed proof: the collision, counted exactly</summary>

With `x1 x2 ... xk` a longest path, collect `A = { i : x1 joined to xi }` and `B = { i : the vertex before xi joined to xk }`, both inside `2, ..., k`. Each holds one member per neighbour of its end, so at least `n` members sit in at most `n - 1` positions and some `i` lies in both. Then `x1, xi, xi+1, ..., xk, xi-1, ..., x1` is a cycle on every vertex of the path; `i = k` is the plain closing edge.

</details>

### Step 4: why the ten depots have none, and why no degree count says so

Every depot has three links, as every cube corner does: the same pattern, six rounds on one network and none on the other. Degrees alone cannot decide.

Two cheap ways to rule a round out do exist:

- a vertex whose deletion breaks the network into pieces, since deleting one vertex of a round leaves a single path;
- a two-sided network whose sides differ in size, since a round alternates sides ([Bipartite graphs](../09-Graphs%20-%20Dots%20and%20Lines/05-bipartite-graphs-and-odd-cycles.md)).

The cube clears both, four corners a side; the depots have no such vertex and no two sides at all, and still no round.

What settles the depots here is exhaustion: the search opens 274 partial routes and closes none — a verdict on one network, not a test. The general question sits on Karp's 1972 list (Karp's list).

```mermaid
flowchart TB
    q{"is there a round through every vertex?"}
    q -->|"every degree at least half of n"| y["yes, guaranteed: Dirac, as on the cube plus gangways"]
    q -->|"deleting one vertex breaks the network"| n1["no, cheaply"]
    q -->|"two sides, all edges crossing, sides unequal"| n2["no, cheaply"]
    q -->|"none of the three fires"| s["exhaustive search, as on the cube and the depots"]
```

Ore's theorem of 1960 asks less: two vertices with no edge between them need only have degrees adding to at least $n$. Step 2 used nothing more, so the collision survives; only Step 3's last count is restated, as a degree sum under $n$.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| walkways, Dirac's bar, every degree against it | 8 corners × 3 each ÷ 2 ends; 8 ÷ 2; 3 against 4 | 12, bar 4, silent |
| orders a blind sift would face, and routes opened | (8 − 1)! ÷ 2, against the search | 2520, 112 |
| rounds, one being 0-1-3-2-6-7-5-4-0 | both roads | **6** |
| four gangways: every degree, and the rounds | 3 + 1 against 4, then 4! × 3! ÷ 2 | fires, **72** |
| the depots against their bar, every route refused | 3 against 5, then both roads | silent, **0** |

Six rounds, found by searching. Four gangways lift every corner to half the network, turning the search into a guarantee. They also complete it: the codes split four-four by whether they hold an even or an odd count of 1s. Every corner now joins all four of the other kind. That network is K(4, 4), whose rounds number 4! × 3! ÷ 2 = 72: each side ordered, one start fixed, halved for direction. The depots have none.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Every walkway once, not every corner | 8 corners of odd degree: no walkway circuit | Euler's question, with its own answer |
| Dirac backwards: below the bar, no round | the cube's 6 rounds | Sufficient, never necessary |
| A route through every depot read as a round | 0-1-2-3-4-9-6-8-5-7 covers 10; 0 rounds | A round closes: the ends need an edge |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported, and every count is reached twice. Road one is backtracking: extend a route corner by corner, and when stuck, back up and take the next edge. Road two builds no route: it tallies how many routes from corner 0 cover each set of corners and stop at each corner in it, then closes the full sets. Beside them: the gangway count against K(4, 4)'s 4! × 3! ÷ 2, and a census of all six-corner networks.

### Python

```python
# Hamiltonian cycles -- the check behind the card.  Nothing is imported.  Three networks:
# the 8 corners of a cube-shaped warehouse, that cube plus four gangways across the middle,
# and the Petersen network of 10 depots.  Every round is counted twice, by backtracking over
# routes and by a tally over sets of corners that builds no route at all.
deg = lambda x: bin(x).count("1")          # a degree: the 1 bits of a neighbour set
low = lambda w: (w & -w).bit_length() - 1  # the lowest-numbered corner in a bit set
fact = lambda k: 1 if k < 2 else k * fact(k - 1)             # k! = 1 x 2 x ... x k
FMT = "{:<17}{:>3}{:>7}{:>9}{:>9}{:>5}{:>7}{:>10}{:>8}{:>9}"
def masks(n, edges):                       # each corner's neighbours, as bits
    return [sum(1 << (v if u == i else u) for u, v in edges if i in (u, v)) for i in range(n)]
def search(m, close=True):                 # road one: backtracking, a route at a time
    n, out, opened = len(m), [], [0]
    def walk(path, left):
        opened[0] += 1                     # one more partial route opened
        if not left and (not close or (m[path[-1]] >> path[0] & 1 and path[1] < path[-1])):
            out.append(path + [path[0]] if close else path)
        w = m[path[-1]] & left
        while w:
            b = w & -w; w -= b
            walk(path + [low(b)], left - b)
    walk([0], (1 << n) - 2)
    return out, opened[0]
def subsets(m):                            # road two: a tally over sets of corners
    n, full = len(m), (1 << len(m)) - 1
    cnt = [[0] * n for _ in range(full + 1)]; cnt[1][0] = 1   # one route: at 0, no step yet
    for s in range(1, full + 1, 2):        # every set of corners that holds corner 0
        for v in range(n):
            c, w = cnt[s][v], m[v] & ~s
            while c and w:
                b = w & -w; w -= b
                cnt[s | b][low(b)] += c    # the same routes, one corner longer
    return sum(cnt[full][v] for v in range(n) if m[0] >> v & 1) // 2
CUBE = [(x, y) for x in range(8) for y in range(x + 1, 8) if deg(x ^ y) == 1]
GANG = CUBE + [(x, 7 - x) for x in range(4)]          # gangways to opposite corners
PET = ([(i, (i + 1) % 5) for i in range(5)] + [(i, i + 5) for i in range(5)]
       + [(i + 5, (i + 2) % 5 + 5) for i in range(5)])
NETS = [("cube warehouse", 8, CUBE), ("cube + gangways", 8, GANG), ("Petersen depots", 10, PET)]
M, found, tally, opened = {}, {}, {}, {}
print(FMT.format("network", "n", "links", "min deg", "odd deg", "n/2", "Dirac", "(n-1)!/2", "search", "subsets"))
for name, n, edges in NETS:
    M[name] = m = masks(n, edges); rounds, opened[name] = search(m)
    found[name], tally[name] = len(rounds), subsets(m)
    d, e, o = min(map(deg, m)), sum(map(deg, m)) // 2, sum(x % 2 for x in map(deg, m))
    print(FMT.format(name, n, e, d, o, f"{n / 2:.1f}", "yes" if d >= n / 2 else "no", fact(n - 1) // 2, found[name], tally[name]))
print("one round on the cube: " + "-".join(map(str, search(M["cube warehouse"])[0][0])))
print(f"partial routes opened by the search: cube {opened['cube warehouse']}, Petersen {opened['Petersen depots']}")
print(f"rounds on cube + gangways, from the K(4,4) count 4! x 3! / 2: {fact(4) * fact(3) // 2}")
print("route over all 10 depots that will not close: " + "-".join(map(str, search(M["Petersen depots"], False)[0][0])))
pairs, dirac, ham, both = [(i, j) for i in range(6) for j in range(i + 1, 6)], 0, 0, 0
for bits in range(1 << 15):                # every network on 6 labelled corners
    m = masks(6, [pairs[i] for i in range(15) if bits >> i & 1])
    d, h = min(map(deg, m)) >= 3, bool(search(m)[0])
    dirac, ham, both = dirac + d, ham + h, both + (d and h)
print(f"of all {1 << 15} networks on 6 corners, {dirac} meet Dirac and all {both} of those have a round")
print(f"of the same {1 << 15}, {ham} have a round, so {ham - both} have one with Dirac silent")
assert [found[k] for k, _, _ in NETS] == [tally[k] for k, _, _ in NETS]   # the two roads agree
assert found["cube + gangways"] == fact(4) * fact(3) // 2 and found["cube + gangways"] == 72
assert found["cube warehouse"] == 6 and found["Petersen depots"] == 0
assert dirac == both < ham                 # Dirac is never wrong, and never necessary
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
network            n  links  min deg  odd deg  n/2  Dirac  (n-1)!/2  search  subsets
cube warehouse     8     12        3        8  4.0     no      2520       6        6
cube + gangways    8     16        4        0  4.0    yes      2520      72       72
Petersen depots   10     15        3       10  5.0     no    181440       0        0
one round on the cube: 0-1-3-2-6-7-5-4-0
partial routes opened by the search: cube 112, Petersen 274
rounds on cube + gangways, from the K(4,4) count 4! x 3! / 2: 72
route over all 10 depots that will not close: 0-1-2-3-4-9-6-8-5-7
of all 32768 networks on 6 corners, 1858 meet Dirac and all 1858 of those have a round
of the same 32768, 10078 have a round, so 8220 have one with Dirac silent
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Hamiltonian cycles -- the same check as hamiltonian_cycles_check.py, in Rust.  No crates.  Three
// networks: the 8 corners of a cube-shaped warehouse, that cube plus four gangways across the middle,
// and the Petersen network of 10 depots.  Every round is counted twice, by backtracking over routes
// and by a tally over sets of corners that builds no route at all.
fn deg(x: u64) -> u32 { x.count_ones() }             // a degree: the 1 bits of a neighbour set
fn low(w: u64) -> usize { w.trailing_zeros() as usize }   // the lowest corner in a bit set
fn fact(k: u64) -> u64 { if k < 2 { 1 } else { k * fact(k - 1) } }   // k! = 1 x 2 x ... x k
fn dash(r: &[usize]) -> String { r.iter().map(|v| v.to_string()).collect::<Vec<_>>().join("-") }
fn masks(n: usize, edges: &[(usize, usize)]) -> Vec<u64> {           // neighbours, as bits
    (0..n).map(|i| edges.iter().filter(|e| e.0 == i || e.1 == i).map(|e| 1u64 << if e.0 == i { e.1 } else { e.0 }).sum()).collect()
}
fn walk(m: &[u64], path: &mut Vec<usize>, left: u64, close: bool, out: &mut Vec<Vec<usize>>, opened: &mut u64) {
    *opened += 1; let end = path[path.len() - 1];   // one more partial route opened
    if left == 0 && (!close || (m[end] >> path[0] & 1 == 1 && path[1] < end)) {
        let mut r = path.clone(); if close { r.push(path[0]) } out.push(r);
    }
    let mut w = m[end] & left;
    while w != 0 {
        let b = w & w.wrapping_neg(); w -= b;
        path.push(low(b));
        walk(m, path, left - b, close, out, opened);
        path.pop();
    }
}
fn search(m: &[u64], close: bool) -> (Vec<Vec<usize>>, u64) {        // road one: backtracking
    let (mut out, mut opened) = (Vec::new(), 0u64);
    walk(m, &mut vec![0], (1u64 << m.len()) - 2, close, &mut out, &mut opened);
    (out, opened)
}
fn subsets(m: &[u64]) -> u64 {                      // road two: a tally over sets of corners
    let (n, full) = (m.len(), (1usize << m.len()) - 1);
    let mut cnt = vec![vec![0u64; n]; full + 1];
    cnt[1][0] = 1;                                  // one route: at 0, no step yet
    for s in (1..=full).step_by(2) {                // every set of corners that holds corner 0
        for v in 0..n {
            let (c, mut w) = (cnt[s][v], m[v] & !(s as u64));
            while c > 0 && w != 0 {
                let b = w & w.wrapping_neg(); w -= b;
                cnt[s | b as usize][low(b)] += c;   // the same routes, one corner longer
            }
        }
    }
    (0..n).filter(|&v| m[0] >> v & 1 == 1).map(|v| cnt[full][v]).sum::<u64>() / 2
}
fn main() {
    let cube: Vec<(usize, usize)> = (0..8).flat_map(|x| (x + 1..8).map(move |y| (x, y))).filter(|&(x, y)| deg((x ^ y) as u64) == 1).collect();
    let mut gang = cube.clone(); for x in 0..4 { gang.push((x, 7 - x)) }   // to opposite corners
    let pet: Vec<(usize, usize)> = (0..5).flat_map(|i| [(i, (i + 1) % 5), (i, i + 5), (i + 5, (i + 2) % 5 + 5)]).collect();
    let nets = [("cube warehouse", 8usize, &cube), ("cube + gangways", 8, &gang), ("Petersen depots", 10, &pet)];
    println!("{:<17}{:>3}{:>7}{:>9}{:>9}{:>5}{:>7}{:>10}{:>8}{:>9}", "network", "n", "links",
             "min deg", "odd deg", "n/2", "Dirac", "(n-1)!/2", "search", "subsets");
    let (mut mm, mut found, mut tally, mut opened) = (vec![], vec![], vec![], vec![]);
    for (name, n, edges) in nets {
        let m = masks(n, edges); let (rounds, op) = search(&m, true);
        let (t, d) = (subsets(&m), m.iter().map(|&x| deg(x)).min().unwrap());
        let (e, o) = (m.iter().map(|&x| deg(x)).sum::<u32>() / 2, m.iter().filter(|&&x| deg(x) % 2 == 1).count());
        println!("{:<17}{:>3}{:>7}{:>9}{:>9}{:>5}{:>7}{:>10}{:>8}{:>9}", name, n, e, d, o,
                 format!("{:.1}", n as f64 / 2.0), if d as f64 >= n as f64 / 2.0 { "yes" } else { "no" },
                 fact(n as u64 - 1) / 2, rounds.len(), t);
        mm.push(m); found.push(rounds.len() as u64); tally.push(t); opened.push(op);
    }
    println!("one round on the cube: {}", dash(&search(&mm[0], true).0[0]));
    println!("partial routes opened by the search: cube {}, Petersen {}", opened[0], opened[2]);
    println!("rounds on cube + gangways, from the K(4,4) count 4! x 3! / 2: {}", fact(4) * fact(3) / 2);
    println!("route over all 10 depots that will not close: {}", dash(&search(&mm[2], false).0[0]));
    let pairs: Vec<(usize, usize)> = (0..6).flat_map(|i| (i + 1..6).map(move |j| (i, j))).collect();
    let (mut dirac, mut ham, mut both) = (0u64, 0u64, 0u64);
    for bits in 0..1u32 << 15 {                     // every network on 6 labelled corners
        let m = masks(6, &(0..15).filter(|i| bits >> i & 1 == 1).map(|i| pairs[i]).collect::<Vec<_>>());
        let (d, h) = (m.iter().map(|&x| deg(x)).min().unwrap() >= 3, !search(&m, true).0.is_empty());
        dirac += d as u64; ham += h as u64; both += (d && h) as u64;
    }
    println!("of all {} networks on 6 corners, {} meet Dirac and all {} of those have a round", 1 << 15, dirac, both);
    println!("of the same {}, {} have a round, so {} have one with Dirac silent", 1 << 15, ham, ham - both);
    assert!(found == tally);                        // the two roads agree
    assert!(found[1] == fact(4) * fact(3) / 2 && found[1] == 72);      // search vs K(4,4) count
    assert!(found[0] == 6 && found[2] == 0);
    assert!(dirac == both && both < ham);           // Dirac is never wrong, and never necessary
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
network            n  links  min deg  odd deg  n/2  Dirac  (n-1)!/2  search  subsets
cube warehouse     8     12        3        8  4.0     no      2520       6        6
cube + gangways    8     16        4        0  4.0    yes      2520      72       72
Petersen depots   10     15        3       10  5.0     no    181440       0        0
one round on the cube: 0-1-3-2-6-7-5-4-0
partial routes opened by the search: cube 112, Petersen 274
rounds on cube + gangways, from the K(4,4) count 4! x 3! / 2: 72
route over all 10 depots that will not close: 0-1-2-3-4-9-6-8-5-7
of all 32768 networks on 6 corners, 1858 meet Dirac and all 1858 of those have a round
of the same 32768, 10078 have a round, so 8220 have one with Dirac silent
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Dirac's theorem and the two-sided test for every network, and checks the warehouse and depot numbers.

- Three vertices or more, simply joined, every degree at least $n/2$ as a fraction: a Hamiltonian cycle exists.
- A two-sided network, every edge crossing, with sides of different sizes, has no Hamiltonian cycle.
- The cube warehouse sits at degree 3, below its bar of 4, and still has a round.
- The cube has 12 walkways and degree 3 at every corner; the round 0-1-3-2-6-7-5-4-0 walks only walkways and signs every corner once.
- Four gangways lift every degree to 4, meeting the bar exactly, with 16 links in all.
- With gangways, each corner joins exactly the four whose count of 1s has the other parity: K(4, 4).
- The depots have 15 links, three at each, against a bar of 5.
- The route 0-1-2-3-4-9-6-8-5-7 covers all ten depots once, but its ends 7 and 0 are not joined.
- The arithmetic holds: (8 − 1)! ÷ 2 = 2520, (10 − 1)! ÷ 2 = 181440, and 4! × 3! ÷ 2 = 72.

Counting the rounds (6, 72, and none on the depots) and the six-corner census are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 433 lines</summary>

```lean
-- Hamiltonian cycles: a simple network on three or more vertices whose every degree is at least half the vertex count has a round through every vertex once (Dirac), a two-sided network with unequal sides has none, the cube warehouse has one below Dirac's bar, and the card's warehouse and depot numbers check out.
import Mathlib.Combinatorics.SimpleGraph.Hamiltonian
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Rat.Cast.Order
import Mathlib.Tactic

namespace HamiltonianCycles

open SimpleGraph

lemma hc_mod_one {n a b : ℕ} (ha : a < n) (hb : b < n) (h : (n - b + a) % n = 1) :
    a = b + 1 ∨ (a = 0 ∧ b = n - 1) := by
  by_cases hab : b ≤ a
  · rw [show n - b + a = (a - b) + n by omega, Nat.add_mod_right,
      Nat.mod_eq_of_lt (by omega)] at h
    omega
  · rw [Nat.mod_eq_of_lt (by omega)] at h
    omega

lemma hc_of_cyclic {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V) (N : ℕ)
    (hN : Fintype.card V = N) (h3 : 3 ≤ N) (g : ℕ → V)
    (hinj : ∀ i j, i < N → j < N → g i = g j → i = j)
    (hadj : ∀ i, i + 1 < N → G.Adj (g i) (g (i + 1)))
    (hclose : G.Adj (g (N - 1)) (g 0)) :
    ∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle := by
  subst hN
  have hc : cycleGraph (Fintype.card V) ⊑ G := by
    refine ⟨⟨⟨fun i => g i.val, ?_⟩, ?_⟩⟩
    · intro a b hab
      have ha := a.isLt
      have hb := b.isLt
      rw [cycleGraph_adj', Fin.val_sub, Fin.val_sub] at hab
      rcases hab with h | h
      · rcases hc_mod_one ha hb h with h1 | ⟨h1, h2⟩
        · have := hadj b.val (by omega)
          rw [← h1] at this
          exact this.symm
        · have := hclose
          rw [← h2, ← h1] at this
          exact this.symm
      · rcases hc_mod_one hb ha h with h1 | ⟨h1, h2⟩
        · have := hadj a.val (by omega)
          rw [← h1] at this
          exact this
        · have := hclose
          rw [← h2, ← h1] at this
          exact this
    · intro a b h
      exact Fin.ext (hinj _ _ a.isLt b.isLt h)
  exact (isHamiltonian_iff_cycleGraph_isContained h3).mpr hc (by omega)

lemma hc_support_eq_cons {V : Type*} {G : SimpleGraph V} {b c : V} (q : G.Walk b c) :
    q.support = b :: q.support.tail := by
  cases q <;> rfl

lemma hc_alt_count {V : Type*} [DecidableEq V] (G : SimpleGraph V) (S : Finset V)
    (hcross : ∀ u v, G.Adj u v → (u ∈ S ↔ v ∉ S)) {u v : V} (p : G.Walk u v) :
    (p.support.tail.countP (fun x => decide (x ∈ S)) : ℤ) -
      (p.support.tail.countP (fun x => decide (x ∉ S)) : ℤ) =
      (if v ∈ S then 1 else 0) - (if u ∈ S then 1 else 0) := by
  induction p with
  | nil => simp
  | cons h q ih =>
    rename_i a b c
    rw [Walk.support_cons, List.tail_cons, hc_support_eq_cons q, List.countP_cons,
      List.countP_cons]
    rw [hc_support_eq_cons q, List.tail_cons] at ih
    have := hcross _ _ h
    by_cases hb : b ∈ S <;> by_cases ha : a ∈ S <;> simp_all <;> omega

/-- A path given by a function: `f 0, …, f (m - 1)` are distinct and consecutive ones adjacent. -/
def HcPathFn {V : Type*} (G : SimpleGraph V) (f : ℕ → V) (m : ℕ) : Prop :=
  (∀ i j, i < m → j < m → f i = f j → i = j) ∧ ∀ i, i + 1 < m → G.Adj (f i) (f (i + 1))

lemma hc_pathFn_le {V : Type*} [Fintype V] {G : SimpleGraph V} {f : ℕ → V} {m : ℕ}
    (h : HcPathFn G f m) : m ≤ Fintype.card V := by
  have := Finset.card_le_card_of_injOn f (s := Finset.range m) (t := Finset.univ)
    (fun _ _ => Finset.mem_coe.mpr (Finset.mem_univ _))
    (fun i hi j hj hij => h.1 i j (by simpa using hi) (by simpa using hj) hij)
  simpa using this

#print axioms hc_mod_one
#print axioms hc_of_cyclic
#print axioms hc_support_eq_cons
#print axioms hc_alt_count
#print axioms HcPathFn
#print axioms hc_pathFn_le

/-- Dirac's theorem (1952). A simple network on `n ≥ 3` vertices in which every vertex has degree
at least `n / 2` (half as a fraction, not rounded down) has a Hamiltonian cycle: a closed route
through every vertex exactly once. -/
theorem dirac_min_degree_half_gives_hamiltonian_cycle {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj]
    (hn : 3 ≤ Fintype.card V) (hδ : (Fintype.card V : ℚ) / 2 ≤ G.minDegree) :
    ∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle := by
  classical
  obtain ⟨n, hnV⟩ : ∃ n, Fintype.card V = n := ⟨_, rfl⟩
  rw [hnV] at hn hδ
  have hδ' : n ≤ 2 * G.minDegree := by
    rw [div_le_iff₀ (by norm_num)] at hδ
    exact_mod_cast (by linarith : (n : ℚ) ≤ 2 * G.minDegree)
  have hdeg : ∀ v, n ≤ 2 * G.degree v := fun v => by
    have := G.minDegree_le_degree v
    omega
  obtain ⟨v0⟩ : Nonempty V := Fintype.card_pos_iff.mp (by omega)
  let P : ℕ → Prop := fun m => ∃ f : ℕ → V, HcPathFn G f m
  have hP1 : P 1 := ⟨fun _ => v0, fun i j hi hj _ => by omega, fun i hi => by omega⟩
  have hspec := Nat.findGreatest_spec (P := P) (m := 1) (n := n) (by omega) hP1
  have hm1 := Nat.le_findGreatest (P := P) (m := 1) (n := n) (by omega) hP1
  set m := Nat.findGreatest P n with hm_def
  have hmax : ∀ (g : ℕ → V) k, m < k → ¬ HcPathFn G g k := fun g k hk hg =>
    Nat.findGreatest_is_greatest hk (hnV ▸ hc_pathFn_le hg) ⟨g, hg⟩
  obtain ⟨f, hfinj, hfadj⟩ := hspec
  have hmn : m ≤ n := hnV ▸ hc_pathFn_le ⟨hfinj, hfadj⟩
  -- every neighbour of the first vertex lies on the path
  have hN0 : ∀ u, G.Adj (f 0) u → ∃ j, j < m ∧ f j = u := by
    intro u hu
    by_contra hcon
    push Not at hcon
    apply hmax (fun j => if j = 0 then u else f (j - 1)) (m + 1) (by omega)
    refine ⟨?_, ?_⟩
    · intro i j hi hj hij
      by_cases hi0 : i = 0 <;> by_cases hj0 : j = 0
      · omega
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij.symm (hcon _ (by omega))
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij (hcon _ (by omega))
      · simp only [hi0, hj0, ite_false] at hij
        have := hfinj _ _ (by omega) (by omega) hij
        omega
    · intro i hi
      by_cases hi0 : i = 0
      · subst hi0
        simp only [ite_true, show (0 + 1 = 0) = False by simp, ite_false]
        exact hu.symm
      · simp only [hi0, show (i + 1 = 0) = False by simp, ite_false, Nat.add_sub_cancel]
        have := hfadj (i - 1) (by omega)
        rwa [show i - 1 + 1 = i by omega] at this
  -- every neighbour of the last vertex lies on the path
  have hNk : ∀ u, G.Adj (f (m - 1)) u → ∃ j, j < m ∧ f j = u := by
    intro u hu
    by_contra hcon
    push Not at hcon
    apply hmax (fun j => if j < m then f j else u) (m + 1) (by omega)
    refine ⟨?_, ?_⟩
    · intro i j hi hj hij
      by_cases hi0 : i < m <;> by_cases hj0 : j < m
      · simp only [hi0, hj0, ite_true] at hij
        exact hfinj _ _ hi0 hj0 hij
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij (hcon _ hi0)
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij.symm (hcon _ hj0)
      · omega
    · intro i hi
      by_cases him : i + 1 < m
      · simp only [him, show i < m by omega, ite_true]
        exact hfadj i him
      · simp only [him, show i < m by omega, ite_true, ite_false]
        rw [show i = m - 1 by omega]
        exact hu
  -- the two index sets of Pósa's argument
  obtain ⟨A, hA_def⟩ : ∃ A : Finset ℕ,
      A = (Finset.range (m - 1)).filter (fun i => G.Adj (f 0) (f (i + 1))) := ⟨_, rfl⟩
  obtain ⟨B, hB_def⟩ : ∃ B : Finset ℕ,
      B = (Finset.range (m - 1)).filter (fun i => G.Adj (f i) (f (m - 1))) := ⟨_, rfl⟩
  have hA : G.degree (f 0) ≤ A.card := by
    rw [← G.card_neighborFinset_eq_degree]
    refine le_trans (Finset.card_le_card ?_) (Finset.card_image_le (f := fun i => f (i + 1)))
    intro u hu
    rw [mem_neighborFinset] at hu
    obtain ⟨j, hj, rfl⟩ := hN0 u hu
    have hj0 : j ≠ 0 := by
      rintro rfl
      exact hu.ne rfl
    rw [Finset.mem_image]
    refine ⟨j - 1, ?_, by simp only [show j - 1 + 1 = j by omega]⟩
    rw [hA_def, Finset.mem_filter, Finset.mem_range]
    refine ⟨by omega, ?_⟩
    rwa [show j - 1 + 1 = j by omega]
  have hB : G.degree (f (m - 1)) ≤ B.card := by
    rw [← G.card_neighborFinset_eq_degree]
    refine le_trans (Finset.card_le_card ?_) (Finset.card_image_le (f := f))
    intro u hu
    rw [mem_neighborFinset] at hu
    obtain ⟨j, hj, rfl⟩ := hNk u hu
    have hjk : j ≠ m - 1 := by
      rintro rfl
      exact hu.ne rfl
    rw [Finset.mem_image]
    refine ⟨j, ?_, rfl⟩
    rw [hB_def, Finset.mem_filter, Finset.mem_range]
    exact ⟨by omega, hu.symm⟩
  have hAm : A.card ≤ m - 1 := by
    have := Finset.card_filter_le (Finset.range (m - 1)) (fun i => G.Adj (f 0) (f (i + 1)))
    rw [hA_def]
    simpa using this
  have hd0 := hdeg (f 0)
  have hdk := hdeg (f (m - 1))
  obtain ⟨i, hi⟩ := Finset.inter_nonempty_of_card_lt_card_add_card
    (hA_def ▸ Finset.filter_subset _ _ : A ⊆ Finset.range (m - 1))
    (hB_def ▸ Finset.filter_subset _ _ : B ⊆ Finset.range (m - 1))
    (by rw [Finset.card_range]; omega)
  rw [Finset.mem_inter, hA_def, hB_def, Finset.mem_filter, Finset.mem_filter,
    Finset.mem_range] at hi
  obtain ⟨⟨him, hi0⟩, -, hik⟩ := hi
  -- the cycle through all vertices of the path
  set g : ℕ → V := fun j => if j ≤ i then f j else f (m + i - j) with hg_def
  have hginj : ∀ a b, a < m → b < m → g a = g b → a = b := by
    intro a b ha hb hab
    simp only [hg_def] at hab
    by_cases hai : a ≤ i <;> by_cases hbi : b ≤ i
    · simp only [hai, hbi, ite_true] at hab
      exact hfinj _ _ ha hb hab
    · simp only [hai, hbi, ite_true, ite_false] at hab
      have := hfinj _ _ ha (by omega) hab
      omega
    · simp only [hai, hbi, ite_true, ite_false] at hab
      have := hfinj _ _ (by omega) hb hab
      omega
    · simp only [hai, hbi, ite_false] at hab
      have := hfinj _ _ (by omega) (by omega) hab
      omega
  have hgadj : ∀ a, a + 1 < m → G.Adj (g a) (g (a + 1)) := by
    intro a ha
    simp only [hg_def]
    by_cases h1 : a + 1 ≤ i
    · simp only [h1, show a ≤ i by omega, ite_true]
      exact hfadj a (by omega)
    · by_cases h2 : a = i
      · subst h2
        simp only [le_refl, ite_true, h1, ite_false]
        rwa [show m + a - (a + 1) = m - 1 by omega]
      · simp only [h1, show ¬ a ≤ i by omega, ite_false]
        have := hfadj (m + i - (a + 1)) (by omega)
        rw [show m + i - (a + 1) + 1 = m + i - a by omega] at this
        exact this.symm
  have hgclose : G.Adj (g (m - 1)) (g 0) := by
    simp only [hg_def, Nat.zero_le, ite_true, show ¬ m - 1 ≤ i by omega, ite_false]
    rw [show m + i - (m - 1) = i + 1 by omega]
    exact hi0.symm
  -- the path already covers every vertex
  have hmeq : m = n := by
    by_contra hne
    have hlt : m < n := lt_of_le_of_ne hmn hne
    have himg : ((Finset.range m).image g).card = m := by
      rw [Finset.card_image_of_injOn (fun a ha b hb hab => hginj a b
        (by simpa using ha) (by simpa using hb) hab), Finset.card_range]
    obtain ⟨w, -, hw⟩ := Finset.exists_mem_notMem_of_card_lt_card
      (s := (Finset.range m).image g) (t := Finset.univ)
      (by rw [himg, Finset.card_univ, hnV]; exact hlt)
    have hw' : ∀ c, c < m → g c ≠ w := fun c hc h =>
      hw (Finset.mem_image.mpr ⟨c, Finset.mem_range.mpr hc, h⟩)
    by_cases hconn : ∃ c, c < m ∧ G.Adj (g c) w
    · obtain ⟨c, hc, hcw⟩ := hconn
      let r : ℕ → ℕ := fun j => if c + 1 + j < m then c + 1 + j else c + 1 + j - m
      apply hmax (fun j => if j < m then g (r j) else w) (m + 1) (by omega)
      refine ⟨?_, ?_⟩
      · intro a b ha hb hab
        by_cases ham : a < m <;> by_cases hbm : b < m
        · simp only [ham, hbm, ite_true] at hab
          have hra : r a < m := by simp only [r]; split_ifs <;> omega
          have hrb : r b < m := by simp only [r]; split_ifs <;> omega
          have := hginj _ _ hra hrb hab
          simp only [r] at this
          split_ifs at this <;> omega
        · simp only [ham, hbm, ite_true, ite_false] at hab
          exact absurd hab (hw' _ (by simp only [r]; split_ifs <;> omega))
        · simp only [ham, hbm, ite_true, ite_false] at hab
          exact absurd hab.symm (hw' _ (by simp only [r]; split_ifs <;> omega))
        · omega
      · intro a ha
        by_cases ham : a + 1 < m
        · simp only [ham, show a < m by omega, ite_true]
          simp only [r]
          by_cases h1 : c + 1 + (a + 1) < m
          · simp only [h1, show c + 1 + a < m by omega, ite_true]
            rw [show c + 1 + (a + 1) = c + 1 + a + 1 by omega]
            exact hgadj _ (by omega)
          · by_cases h2 : c + 1 + a < m
            · simp only [h1, h2, ite_true, ite_false]
              rw [show c + 1 + a = m - 1 by omega, show c + 1 + (a + 1) - m = 0 by omega]
              exact hgclose
            · simp only [h1, h2, ite_false]
              rw [show c + 1 + (a + 1) - m = c + 1 + a - m + 1 by omega]
              exact hgadj _ (by omega)
        · simp only [ham, show a < m by omega, ite_true, ite_false]
          simp only [r]
          simp only [show ¬ (c + 1 + a < m) by omega, ite_false]
          rw [show c + 1 + a - m = c by omega]
          exact hcw
    · push Not at hconn
      have hsub : G.neighborFinset w ⊆ (insert w ((Finset.range m).image g))ᶜ := by
        intro u hu
        rw [mem_neighborFinset] at hu
        rw [Finset.mem_compl, Finset.mem_insert, Finset.mem_image]
        rintro (rfl | ⟨c, hc, rfl⟩)
        · exact hu.ne rfl
        · exact hconn c (Finset.mem_range.mp hc) hu.symm
      have hcard := Finset.card_le_card hsub
      rw [card_neighborFinset_eq_degree, Finset.card_compl,
        Finset.card_insert_of_notMem hw, himg, hnV] at hcard
      have hdw := hdeg w
      have := hA
      omega
  exact hc_of_cyclic G m (hnV.trans hmeq.symm) (by omega) g hginj hgadj hgclose

/-- A cheap "no". If every edge joins one side `S` to the other side, and the two sides hold
different numbers of vertices, the network has no Hamiltonian cycle: a round alternates sides. -/
theorem no_hamiltonian_cycle_of_unequal_sides {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) (S : Finset V)
    (hcross : ∀ u v, G.Adj u v → (u ∈ S ↔ v ∉ S)) (hsides : S.card ≠ Sᶜ.card) :
    ¬ ∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle := by
  rintro ⟨a, p, hp⟩
  have h := hc_alt_count G S hcross p
  simp only [sub_self] at h
  have hcount := (Walk.isHamiltonianCycle_iff_isCycle_and_support_count_tail_eq_one.mp hp).2
  have hval : (p.support.tail : Multiset V) = (Finset.univ : Finset V).val := by
    ext x
    rw [Multiset.coe_count, hcount x,
      Multiset.count_eq_one_of_mem Finset.univ.nodup (Finset.mem_univ x)]
  have hS : p.support.tail.countP (fun x => decide (x ∈ S)) = S.card := by
    rw [← Multiset.coe_countP, hval, Multiset.countP_eq_card_filter]
    rw [← Finset.filter_val, Finset.card_val]
    congr 1
    ext x; simp
  have hT : p.support.tail.countP (fun x => decide (x ∉ S)) = Sᶜ.card := by
    rw [← Multiset.coe_countP, hval, Multiset.countP_eq_card_filter]
    rw [← Finset.filter_val, Finset.card_val]
    congr 1
    ext x; simp
  rw [hS, hT] at h
  omega

/-! The networks on the card. -/

/-- The cube warehouse: corners `0`–`7` in three binary digits, joined when the codes differ in
exactly one digit. -/
def cube : SimpleGraph (Fin 8) where
  Adj x y := x.val ^^^ y.val = 1 ∨ x.val ^^^ y.val = 2 ∨ x.val ^^^ y.val = 4
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cube.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _ ∨ _))

/-- The cube plus four gangways, each joining a corner `x` to the opposite corner `7 - x`. -/
def cubeGangways : SimpleGraph (Fin 8) where
  Adj x y := cube.Adj x y ∨ x.val + y.val = 7
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cubeGangways.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _))

/-- The links of the Petersen network of ten depots: an outer five-cycle, five spokes, and an
inner five-pointed star. -/
def petersenLinks : List (Fin 10 × Fin 10) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0),
   (0, 5), (1, 6), (2, 7), (3, 8), (4, 9),
   (5, 7), (6, 8), (7, 9), (8, 5), (9, 6)]

/-- The Petersen network of ten depots. -/
def petersen : SimpleGraph (Fin 10) where
  Adj x y := (x, y) ∈ petersenLinks ∨ (y, x) ∈ petersenLinks
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel petersen.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _))

/-- Dirac's bar is sufficient, never necessary. The cube warehouse's smallest degree, 3, is
below its bar of 8 / 2 = 4, and still it has a Hamiltonian cycle. -/
theorem cube_has_hamiltonian_cycle_below_dirac_bar :
    (cube.minDegree : ℚ) < 8 / 2 ∧ ∃ a : Fin 8, ∃ p : cube.Walk a a, p.IsHamiltonianCycle := by
  refine ⟨?_, ?_⟩
  · have h : cube.minDegree = 3 := by decide
    have h' : (cube.minDegree : ℚ) = 3 := by rw [h]; norm_num
    rw [h', lt_div_iff₀ (by norm_num)]; norm_num
  · refine hc_of_cyclic cube 8 (by simp) (by norm_num)
      (fun i => ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD i 0) ?_ ?_ ?_
    · have key : ∀ i < 8, ∀ j < 8, ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD i 0 =
          ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD j 0 → i = j := by decide
      exact fun i j hi hj => key i hi j hj
    · have key : ∀ i < 7, cube.Adj (([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD i 0)
          (([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD (i + 1) 0) := by decide
      exact fun i hi => key i (by omega)
    · decide

/-! The card's worked numbers. -/

-- The cube: 12 walkways, every corner of degree 3, bar 8 / 2 = 4, so Dirac is silent.
example : cube.edgeFinset.card = 12 := by decide
example : ∀ v, cube.degree v = 3 := by decide
example : cube.minDegree = 3 ∧ 2 * 3 < 8 := by decide

-- The round 0, 1, 3, 2, 6, 7, 5, 4, back to 0: every step a walkway, every corner once.
example : List.IsChain cube.Adj [0, 1, 3, 2, 6, 7, 5, 4, 0] ∧
    ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).Nodup := by decide

-- A blind sift faces (8 - 1)! / 2 = 2520 orders.
example : Nat.factorial (8 - 1) / 2 = 2520 := by decide

-- Four gangways: every degree 3 + 1 = 4, meeting the bar 8 / 2 exactly; 16 links in all.
example : ∀ v, cubeGangways.degree v = 4 := by decide
example : cubeGangways.minDegree = 4 ∧ 8 ≤ 2 * 4 := by decide
example : cubeGangways.edgeFinset.card = 16 := by decide

-- The gangway network is K(4, 4): every corner is joined to exactly the four corners whose
-- count of 1s has the other parity; its rounds number 4! × 3! / 2 = 72.
example : ∀ x y : Fin 8, cubeGangways.Adj x y ↔
    (x.val % 2 + x.val / 2 % 2 + x.val / 4) % 2 ≠ (y.val % 2 + y.val / 2 % 2 + y.val / 4) % 2 := by decide
example : Nat.factorial 4 * Nat.factorial 3 / 2 = 72 := by decide

-- The depots: 15 links, three at each, against a bar of 10 / 2 = 5, so Dirac is silent.
example : petersen.edgeFinset.card = 15 := by decide
example : ∀ v, petersen.degree v = 3 := by decide
example : petersen.minDegree = 3 ∧ 2 * 3 < 10 := by decide

-- The route 0-1-2-3-4-9-6-8-5-7 touches all ten depots, but its ends 7 and 0 are not joined.
example : List.IsChain petersen.Adj [0, 1, 2, 3, 4, 9, 6, 8, 5, 7] ∧
    ([0, 1, 2, 3, 4, 9, 6, 8, 5, 7] : List (Fin 10)).Nodup ∧ ¬ petersen.Adj 7 0 := by decide

-- A blind sift of ten depots faces (10 - 1)! / 2 = 181440 orders.
example : Nat.factorial (10 - 1) / 2 = 181440 := by decide

#print axioms dirac_min_degree_half_gives_hamiltonian_cycle
#print axioms no_hamiltonian_cycle_of_unequal_sides
#print axioms cube_has_hamiltonian_cycle_below_dirac_bar

end HamiltonianCycles
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'HamiltonianCycles.hc_mod_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'HamiltonianCycles.hc_of_cyclic' depends on axioms: [propext, Classical.choice, Quot.sound]
'HamiltonianCycles.hc_support_eq_cons' does not depend on any axioms
'HamiltonianCycles.hc_alt_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'HamiltonianCycles.HcPathFn' does not depend on any axioms
'HamiltonianCycles.hc_pathFn_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'HamiltonianCycles.dirac_min_degree_half_gives_hamiltonian_cycle' depends on axioms: [propext, Classical.choice, Quot.sound]
'HamiltonianCycles.no_hamiltonian_cycle_of_unequal_sides' depends on axioms: [propext, Classical.choice, Quot.sound]
'HamiltonianCycles.cube_has_hamiltonian_cycle_below_dirac_bar' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to these three networks, so expect one to stop.
> - **Drop the rule keeping one direction.** Remove `path[1] < path[-1]`. Each round is then counted twice, once each way round, while the subset tally is unmoved: the first assert stops it.
> - **Lower the bar below half.** Change the census test `>= 3` to `>= 2`. 12068 networks clear it and only 10078 have a round: 1990 false guarantees, and the fourth assert stops it.
> - **Take a walkway out of the cube.** Drop one pair from `CUBE`. Every walkway lies in four of the six rounds, so two survive. The gangway network is built on `CUBE`, so it loses rounds too, and the second assert, pinned to 72, stops it first.

---

## The usual mistake

> [!warning]
> **Reading Dirac's theorem as a test.** It only ever says yes. Of the 10078 networks on six corners that have a round, it catches 1858; the other 8220 have one with the guarantee silent. "Dirac fails, so no round" is the commonest wrong step, and the cube refutes it six times over.
>
> - **Asking for every edge once.** That is a degree count; this is not. All eight cube corners have odd degree, so no circuit covers each walkway once, while six rounds cover each corner.
> - **Taking a route through everything as a round.** The depots have a route touching all ten, 0-1-2-3-4-9-6-8-5-7, and no round: its ends are not joined, and no reshuffle joins them.
> - **Halving with whole numbers.** The bar is $n/2$ as a fraction; rounding it down on an odd vertex count manufactures guarantees.

---

## Where you meet it in real life

- **Position encoders.** The round 0, 1, 3, 2, 6, 7, 5, 4 is the reflected binary code: one digit flips per step, so a sensor on three tracks cannot straddle two positions and read a third.
- **Vehicle routing.** Cost each edge and ask for the cheapest round: this search is the travelling salesman's skeleton ([The travelling salesman](04-travelling-salesman-in-outline.md)).
- **The postman, not the courier.** Covering every street instead has an efficient algorithm ([The Chinese postman](02-chinese-postman.md)).
- **Shortest string holding every code.** A sequence containing each binary block of one length once is a round through every vertex of one network ([De Bruijn sequences](05-de-bruijn-sequences.md)).

> **Say it back**
> A Hamiltonian cycle visits every vertex once and returns home. Euler's twin question, every edge once, has a cheap degree test; this one has none. Dirac's theorem gives a one-way guarantee: three vertices or more, every degree at least half the vertices. Its proof takes a longest route and counts the ends' neighbours until they must collide, closing it. The warehouse has six rounds with the bar unmet; four gangways meet it and lift the count to 72; the ten depots have none.

---

## What this builds on

- [Euler circuits](01-euler-circuits.md): the edge-covering twin, and the cheap degree test this question lacks.
- [Proof by contradiction](../../01-Foundations/06-Proof/03-proof-by-contradiction.md): the shape of Steps 1 and 3.

## Where this goes next

- [The travelling salesman](04-travelling-salesman-in-outline.md): the same round with a cost on every edge, where finding one stops being the hard part.
- Karp's list: where "no quick test is known" becomes a precise claim about a family of problems.

The search opened 274 partial routes where a blind sift of ten depots faces 181440 orders — encouraging until the depots number a thousand. What to do when the exact answer is out of reach is the next card's business.

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Dirac, G. A. "Some theorems on abstract graphs." *Proceedings of the London Mathematical Society* s3-2, no. 1 (1952): 69–81. [Publisher page, London Mathematical Society](https://londmathsoc.onlinelibrary.wiley.com/doi/10.1112/plms/s3-2.1.69). The guarantee proved here.
- Ore, Øystein. "Note on Hamilton Circuits." *The American Mathematical Monthly* 67, no. 1 (1960): 55. [Journal page, JSTOR](https://www.jstor.org/stable/2308928). The degree-sum version.
- Karp, Richard M. "Reducibility among Combinatorial Problems." In *Complexity of Computer Computations*, 85–103. Plenum Press, 1972. [Chapter page](https://link.springer.com/chapter/10.1007/978-1-4684-2001-2_9). The list holding this problem.
- Bondy, J. A., and U. S. R. Murty. *Graph Theory*. Springer, 2008. [Publisher page](https://link.springer.com/book/9781846289699). Step 4's conditions, and the Petersen network.
