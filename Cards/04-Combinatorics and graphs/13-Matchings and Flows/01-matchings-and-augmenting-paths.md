# Matchings: pair up vertices with no one used twice, and a matching is largest exactly when no alternating route can improve it

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Matchings and Flows](../README.md#s13) → Matchings

---

## General Overview

A 10k fun run needs five jobs covered: registration, first aid, water, parking and timing. Five volunteers have ticked the jobs they can do.

| Volunteer | Can do |
| --- | --- |
| Priya | registration, first aid |
| Omar | water, parking |
| Lena | first aid, timing |
| Sam | water, parking |
| Tomas | registration |

In sheet order, each person takes the first free job on their list. Priya takes registration, Omar water, Lena first aid, Sam parking. Tomas's only job is gone. Four jobs covered, timing empty, Tomas idle.

Every unused tick touches a person or job already taken, so nothing can be added. Yet Tomas can take registration, Priya move to first aid, Lena move to timing: five covered. That chain of swaps runs from a free person to a free job, and this card proves such a chain is the only thing a pairing can ever be missing.

**A pairing is as large as it can be exactly when no chain of swaps runs from an unpaired person to an unpaired job.**

**What kind of fact this is:** a theorem, Berge's, proved on this card in Why it works; matching, maximal and maximum are definitions.

### The picture: where greedy stops

```mermaid
flowchart LR
    Priya ===|paired| reg["registration"]
    Priya --- fa["first aid"]
    Omar ===|paired| wat["water"]
    Omar --- par["parking"]
    Lena ===|paired| fa
    Lena --- tim["timing"]
    Sam --- wat
    Sam ===|paired| par
    Tomas --- reg
```

One line per tick, 9 in all; thick lines are greedy's four pairs. Tomas and timing touch none.

---

## The formula

The sign-up sheet is a **bipartite graph** $G$: dots in two groups, volunteers and jobs, every line running from one group to the other ([Bipartite graphs](../09-Graphs%20-%20Dots%20and%20Lines/05-bipartite-graphs-and-odd-cycles.md)). A **matching** $M$ is a set of lines no two sharing a dot: nobody works two jobs. Bars count lines, so $\lvert M\rvert$ is the matching's size. A dot on a line of $M$ is **matched**; any other dot is **free**.

**Maximal**: no line can be added as it stands. **Maximum**: no matching of $G$ is larger; that size is $\nu(G)$, read "nu of G". **Perfect**: every dot is matched. Greedy's four pairs are maximal, not maximum.

An **alternating path** switches at every step between lines outside $M$ and lines inside it. It is **augmenting**, written $P$, when both its ends are free. The shortest has one line: an unused line between two free dots. Maximal means none of those; maximum, by the theorem below, means none of any length.

$$M \text{ is maximum} \iff G \text{ has no augmenting path for } M$$

**Read it aloud:** a matching is as big as possible exactly when no alternating route joins two free dots.

The repair, where a triangle between two sets of lines means the lines in exactly one of them:

$$\lvert M \triangle P\rvert = \lvert M\rvert + 1$$

**Read it aloud:** flip every line of an augmenting path, in for out and out for in, and the matching grows by one.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $G$ | the graph: people and jobs as dots, ticks as lines | 5 and 5 dots, 9 lines | more lines, more room to pair |
| $M$ | a matching: lines sharing no dot | greedy's 4 pairs | — |
| $\lvert M\rvert$ | its size, the count of pairs | 4, then 5 | — |
| $\nu(G)$ | the largest size any matching of $G$ reaches | 5 | — |
| $P$ | an augmenting path: alternating, free at both ends | Tomas's 5-line route to timing | a longer route moves more people |
| $u$, $w$ | the two free ends of $P$ | Tomas and timing | — |
| $M \triangle P$ | lines in exactly one of $M$ and $P$: the flipped matching | the 5 pairs after the swap | — |
| $M^*$ | a larger matching, used in the proof | the other perfect matching | — |

### When it holds

- **Any finite graph, not only two-sided ones.** The proof never uses the two groups; the code's simple search does, since an odd loop can fool it, and general graphs need Edmonds' blossom method, a later wing.
- **Both ends free.** A route ending at a matched dot only moves the gap: stopping the swap at Lena leaves 4 pairs.
- **Size, not preference or cost.** Who would rather do what, and what a pairing costs, are [Stable matching](04-stable-matching-gale-shapley.md) and [The assignment problem](../../14-Applied%20and%20computational/05-Operations%20Research/05-assignment-and-the-hungarian-algorithm.md).

---

## Why it works

### Step 0: a route between two free dots has one spare line

An augmenting path starts and ends at free dots, so its first and last lines are outside $M$. In between, lines alternate. So it holds one more outside line than inside line. Tomas's route has 5 lines: 3 out, 2 in.

### Step 1: a route means the matching is not maximum

Flip the path: its outside lines join $M$, its inside lines leave. Each middle dot swaps one partner for another; the two free ends gain one each; other dots are untouched. The result is a matching one line larger: on the sheet, two pairs leave, three join.

### Step 2: no route means the matching is maximum

Suppose a larger matching $M^*$ exists. Keep the lines in exactly one of the two. Each dot touches at most one line of each, so at most two kept lines. Such lines fall into pieces, each a path or a closed loop, alternating between $M$ and $M^*$.

A loop holds equal numbers of each; a path, equal numbers or one more of one kind. Since $M^*$ is larger, some piece is a path starting and ending with lines of $M^*$. Its ends are free in $M$, so it is augmenting. Turned round: no augmenting path means no larger matching.

On the sheet, greedy and the other perfect matching differ on all 9 lines, 5 against 4: Tomas's route, 3 against 2, and the loop Omar-water-Sam-parking, 2 against 2.

<details>
<summary>Detailed proof</summary>

Let $\lvert M^*\rvert > \lvert M\rvert$ and keep the lines of $M \triangle M^*$. Each dot lies on at most one line of each matching, so on at most two kept lines, one from each.

A connected piece in which every dot has at most two lines is a path or a cycle. Consecutive lines share a dot, so they come from different matchings. An alternating cycle has even length and equal counts; a path has equal counts or one more of one kind.

Lines shared by both matchings are dropped from each count equally, so the kept lines still hold more of $M^*$. Some piece is therefore a path $P$ whose first and last lines lie in $M^*$. Let $u$ be an end. If $M$ matched $u$, that line of $M$ is not in $M^*$, since $u$ already has its $M^*$ line in $P$; so it is kept, and $P$ would continue past $u$. It does not, so $u$ is free in $M$, and likewise the other end $w$. So $P$ is augmenting for $M$. With Step 1, $M$ is maximum if and only if no augmenting path exists.

</details>

### Step 3: the theorem is also a method

Start from any matching, even the empty one. Search for an augmenting path, flip it, repeat. Each flip adds a pair, and pairs cannot outnumber half the dots, so the loop ends; an empty search certifies a maximum. Claude Berge proved the theorem in 1957.

The code's search starts at a free volunteer: a free job ends the route, a taken one hands the search to its holder.

A second road: treat each tick as a pipe carrying one unit from volunteers to jobs. An augmenting path is then a route carrying one more unit, taken properly in [Flows](05-flow-networks-and-ford-fulkerson.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| lines on the sheet | Priya 2, Omar 2, Lena 2, Sam 2, Tomas 1 | 9 |
| greedy, in sheet order | Priya-registration, Omar-water, Lena-first aid, Sam-parking | 4 |
| free after greedy | Tomas, and timing | 2 dots |
| augmenting route | Tomas, registration, Priya, first aid, Lena, timing | 5 lines, 3 out, 2 in |
| after the flip | 4 − 2 + 3 | **5** |
| every set of the 9 lines | 2 × 2 × … × 2, nine times | 512 sets |
| of those, matchings of size 0 to 5 | counted one by one | 1, 9, 28, 35, 16, 2 |
| largest | the last non-zero count | **5** |
| perfect matchings | Tomas, Priya, Lena forced; Omar and Sam can swap | **2** |

Every job is staffed by moving two people, not by finding a sixth.

### The picture: after the swap

```mermaid
flowchart LR
    Priya --- reg["registration"]
    Priya ===|paired| fa["first aid"]
    Omar ===|paired| wat["water"]
    Omar --- par["parking"]
    Lena --- fa
    Lena ===|paired| tim["timing"]
    Sam --- wat
    Sam ===|paired| par
    Tomas ===|paired| reg
```

Five thick lines, no dot on two of them.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Stop when nothing can be added | 4 pairs | Maximal is not maximum: the fix also removes lines |
| Swap only as far as Lena | 4 pairs, Lena idle | The route ended at a matched dot, so the gap only moved |
| Rerun greedy in a luckier order | only 20 of 120 orders reach 5 | Greedy needs Tomas, Priya, Lena in that order: luck, not a guarantee |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one runs greedy, finds the augmenting path and flips it: 5. Road two tries all 512 sets of lines and counts matchings by size: 5 again. It also tests Berge on all 91 matchings, and recounts perfect matchings over all 120 ways to hand out the jobs.

### Python

```python
# Matchings and augmenting paths -- the check behind the card.  Nothing is imported.
# Five volunteers, five tasks, nine 'can do' lines.  Road one: a greedy pairing repaired
# by an alternating route.  Road two: all 512 sets of lines, for the largest and for Berge.
TASKS = ["registration", "first aid", "water", "parking", "timing"]
NAMES = ["Priya", "Omar", "Lena", "Sam", "Tomas"]
CAN = [[0, 1], [2, 3], [1, 4], [2, 3], [0]]
LINES = [(v, t) for v in range(5) for t in CAN[v]]
def greedy(order):                  # each takes the first task on their list still free
    owner = [-1] * 5
    for v in order:
        free = [t for t in CAN[v] if owner[t] < 0]
        if free: owner[free[0]] = v
    return owner
def route(v, owner, seen):          # alternating route from volunteer v to a free task
    for t in CAN[v]:
        if t not in seen:
            seen.add(t)
            if owner[t] < 0: return [v, t]
            rest = route(owner[t], owner, seen)
            if rest: return [v, t] + rest
def augmenting(owner):              # the first route found from an unpaired volunteer
    routes = [route(v, owner, set()) for v in range(5) if v not in owner]
    return next((r for r in routes if r), None)
def flip(owner, r):                 # the route's outside lines go in, its inside lines out
    owner = owner[:]
    for i in range(0, len(r), 2): owner[r[i + 1]] = r[i]
    return owner
def perms(xs):                      # every order of a list, written out here
    return [[x] + p for x in xs for p in perms([y for y in xs if y != x])] if xs else [[]]
size = lambda owner: sum(1 for v in owner if v >= 0)
show = lambda owner: ", ".join(f"{NAMES[v]}-{TASKS[t]}" for t, v in enumerate(owner) if v >= 0)
g = greedy(range(5)); r = augmenting(g); fixed = flip(g, r); half = flip(g, r[:4])
by_size, agree, perfect = [0] * 6, 0, []
for mask in range(1 << len(LINES)):                         # road two: every set of lines
    pick = [LINES[i] for i in range(len(LINES)) if mask >> i & 1]
    if len({v for v, _ in pick}) < len(pick) or len({t for _, t in pick}) < len(pick): continue
    by_size[len(pick)] += 1
    owner = [next((v for v, u in pick if u == t), -1) for t in range(5)]
    if len(pick) == 5: perfect.append(owner)
    agree += (augmenting(owner) is not None) == (len(pick) < 5)
census = sum(all(p[v] in CAN[v] for v in range(5)) for p in perms(list(range(5))))
orders = perms(list(range(5))); hits = sum(size(greedy(o)) == 5 for o in orders)
best, other = max(k for k in range(6) if by_size[k]), [p for p in perfect if p != fixed][0]
print(f"volunteers 5, tasks 5, can-do lines {len(LINES)}")
print(f"greedy, in listed order: {show(g)}; size {size(g)}")
print(f"augmenting route: {' - '.join((NAMES if i % 2 == 0 else TASKS)[x] for i, x in enumerate(r))}; {len(r) - 1} lines, {len(r) // 2} out, {len(r) // 2 - 1} in")
print(f"after the flip: {show(fixed)}; size {size(fixed)}; route left: {'yes' if augmenting(fixed) else 'none'}")
print(f"matchings by size 0 to 5, from all {1 << len(LINES)} sets of lines: {by_size}")
print(f"largest by brute force: {best}; perfect matchings: {len(perfect)}; by all 120 orders of tasks: {census}")
print(f"Berge on every matching, route found exactly when size < 5: {agree} of {sum(by_size)}")
print(f"greedy orders of volunteers that reach 5: {hits} of {len(orders)}")
print(f"the other perfect matching: {show(other)}")
print(f"lines in exactly one of greedy and it: {sum((g[t] == v) != (other[t] == v) for v, t in LINES)}, "
      f"{sum(other[t] == v != g[t] for v, t in LINES)} from it, {sum(g[t] == v != other[t] for v, t in LINES)} from greedy")
print(f"mistake, flip the route only as far as Lena: {show(half)}; size {size(half)}")
assert best == size(fixed) and size(g) < best                    # two roads to 5
assert agree == sum(by_size)                                     # Berge on all matchings
assert len(perfect) == census                                    # two counts of perfect
assert hits * 6 == len(orders)       # greedy wins only when Tomas, Priya, Lena come in that order
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
volunteers 5, tasks 5, can-do lines 9
greedy, in listed order: Priya-registration, Lena-first aid, Omar-water, Sam-parking; size 4
augmenting route: Tomas - registration - Priya - first aid - Lena - timing; 5 lines, 3 out, 2 in
after the flip: Tomas-registration, Priya-first aid, Omar-water, Sam-parking, Lena-timing; size 5; route left: none
matchings by size 0 to 5, from all 512 sets of lines: [1, 9, 28, 35, 16, 2]
largest by brute force: 5; perfect matchings: 2; by all 120 orders of tasks: 2
Berge on every matching, route found exactly when size < 5: 91 of 91
greedy orders of volunteers that reach 5: 20 of 120
the other perfect matching: Tomas-registration, Priya-first aid, Sam-water, Omar-parking, Lena-timing
lines in exactly one of greedy and it: 9, 5 from it, 4 from greedy
mistake, flip the route only as far as Lena: Tomas-registration, Priya-first aid, Omar-water, Sam-parking; size 4
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Matchings and augmenting paths -- the same check as the Python, in Rust.  No crates.
// Five volunteers, five tasks, nine 'can do' lines.  Road one: a greedy pairing repaired
// by an alternating route.  Road two: all 512 sets of lines, for the largest and for Berge.
const TASKS: [&str; 5] = ["registration", "first aid", "water", "parking", "timing"];
const NAMES: [&str; 5] = ["Priya", "Omar", "Lena", "Sam", "Tomas"];
const CAN: [&[i32]; 5] = [&[0, 1], &[2, 3], &[1, 4], &[2, 3], &[0]];
type Pairs = [i32; 5];                           // which volunteer holds each task, -1 none
fn greedy(order: &[i32]) -> Pairs {              // each takes the first task on their list still free
    let mut owner = [-1; 5];
    for &v in order {
        if let Some(&t) = CAN[v as usize].iter().find(|&&t| owner[t as usize] < 0) { owner[t as usize] = v }
    }
    owner
}
fn route(v: i32, owner: &Pairs, seen: &mut Vec<i32>) -> Option<Vec<i32>> {  // alternating route to a free task
    for &t in CAN[v as usize] {
        if seen.contains(&t) { continue }
        seen.push(t);
        if owner[t as usize] < 0 { return Some(vec![v, t]) }
        if let Some(rest) = route(owner[t as usize], owner, seen) { return Some([vec![v, t], rest].concat()) }
    }
    None
}
fn augmenting(owner: &Pairs) -> Option<Vec<i32>> {  // the first route found from an unpaired volunteer
    (0..5).filter(|v| !owner.contains(v)).find_map(|v| route(v, owner, &mut Vec::new()))
}
fn flip(owner: &Pairs, r: &[i32]) -> Pairs {     // the route's outside lines go in, its inside lines out
    let mut out = *owner;
    for i in (0..r.len()).step_by(2) { out[r[i + 1] as usize] = r[i] }
    out
}
fn perms(xs: &[i32]) -> Vec<Vec<i32>> {          // every order of a list, written out here
    if xs.is_empty() { return vec![vec![]] }
    xs.iter().flat_map(|&x| { let rest: Vec<i32> = xs.iter().copied().filter(|&y| y != x).collect();
        perms(&rest).into_iter().map(move |p| [vec![x], p].concat()) }).collect()
}
fn size(o: &Pairs) -> usize { o.iter().filter(|&&v| v >= 0).count() }
fn show(o: &Pairs) -> String {
    (0..5).filter(|&t| o[t] >= 0).map(|t| format!("{}-{}", NAMES[o[t] as usize], TASKS[t])).collect::<Vec<_>>().join(", ")
}
fn main() {
    let lines: Vec<(i32, i32)> = (0..5).flat_map(|v| CAN[v as usize].iter().map(move |&t| (v, t))).collect();
    let g = greedy(&[0, 1, 2, 3, 4]); let r = augmenting(&g).unwrap();
    let (fixed, half) = (flip(&g, &r), flip(&g, &r[..4]));
    let (mut by_size, mut agree, mut perfect) = ([0usize; 6], 0, Vec::new());
    for mask in 0u32..(1 << lines.len()) {       // road two: every set of lines
        let pick: Vec<(i32, i32)> = (0..lines.len()).filter(|i| mask >> i & 1 == 1).map(|i| lines[i]).collect();
        let (mut vs, mut ts) = (vec![], vec![]);
        if pick.iter().any(|&(v, t)| { let clash = vs.contains(&v) || ts.contains(&t); vs.push(v); ts.push(t); clash }) { continue }
        by_size[pick.len()] += 1;
        let mut owner = [-1; 5]; for &(v, t) in &pick { owner[t as usize] = v }
        if pick.len() == 5 { perfect.push(owner) }
        if augmenting(&owner).is_some() == (pick.len() < 5) { agree += 1 }
    }
    let (best, orders) = ((0..6).filter(|&k| by_size[k] > 0).max().unwrap(), perms(&[0, 1, 2, 3, 4]));
    let census = orders.iter().filter(|p| (0..5).all(|v| CAN[v].contains(&p[v]))).count();
    let hits = orders.iter().filter(|o| size(&greedy(o)) == 5).count();
    let other = *perfect.iter().find(|&&p| p != fixed).unwrap();
    let words: Vec<&str> = r.iter().enumerate().map(|(i, &x)| if i % 2 == 0 { NAMES[x as usize] } else { TASKS[x as usize] }).collect();
    let held = |o: &Pairs, v: i32, t: i32| o[t as usize] == v;
    println!("volunteers 5, tasks 5, can-do lines {}", lines.len());
    println!("greedy, in listed order: {}; size {}", show(&g), size(&g));
    println!("augmenting route: {}; {} lines, {} out, {} in", words.join(" - "), r.len() - 1, r.len() / 2, r.len() / 2 - 1);
    println!("after the flip: {}; size {}; route left: {}", show(&fixed), size(&fixed), if augmenting(&fixed).is_some() { "yes" } else { "none" });
    println!("matchings by size 0 to 5, from all {} sets of lines: {:?}", 1 << lines.len(), by_size);
    println!("largest by brute force: {}; perfect matchings: {}; by all 120 orders of tasks: {}", best, perfect.len(), census);
    println!("Berge on every matching, route found exactly when size < 5: {} of {}", agree, by_size.iter().sum::<usize>());
    println!("greedy orders of volunteers that reach 5: {} of {}", hits, orders.len());
    println!("the other perfect matching: {}", show(&other));
    println!("lines in exactly one of greedy and it: {}, {} from it, {} from greedy",
        lines.iter().filter(|&&(v, t)| held(&g, v, t) != held(&other, v, t)).count(),
        lines.iter().filter(|&&(v, t)| held(&other, v, t) && !held(&g, v, t)).count(),
        lines.iter().filter(|&&(v, t)| held(&g, v, t) && !held(&other, v, t)).count());
    println!("mistake, flip the route only as far as Lena: {}; size {}", show(&half), size(&half));
    assert!(best == size(&fixed) && size(&g) < best);                 // two roads to 5
    assert!(agree == by_size.iter().sum::<usize>());                  // Berge on all matchings
    assert!(perfect.len() == census);                                 // two counts of perfect
    assert!(hits * 6 == orders.len());  // greedy wins only when Tomas, Priya, Lena come in that order
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
volunteers 5, tasks 5, can-do lines 9
greedy, in listed order: Priya-registration, Lena-first aid, Omar-water, Sam-parking; size 4
augmenting route: Tomas - registration - Priya - first aid - Lena - timing; 5 lines, 3 out, 2 in
after the flip: Tomas-registration, Priya-first aid, Omar-water, Sam-parking, Lena-timing; size 5; route left: none
matchings by size 0 to 5, from all 512 sets of lines: [1, 9, 28, 35, 16, 2]
largest by brute force: 5; perfect matchings: 2; by all 120 orders of tasks: 2
Berge on every matching, route found exactly when size < 5: 91 of 91
greedy orders of volunteers that reach 5: 20 of 120
the other perfect matching: Tomas-registration, Priya-first aid, Sam-water, Omar-parking, Lena-timing
lines in exactly one of greedy and it: 9, 5 from it, 4 from greedy
mistake, flip the route only as far as Lena: Tomas-registration, Priya-first aid, Omar-water, Sam-parking; size 4
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Berge's theorem and the repair for every finite graph, and checks the sign-up sheet's numbers.

- A matching is maximum exactly when the graph has no augmenting path for it.
- Flipping an augmenting path $P$ gives a matching: the lines of $M \triangle P$, one more than $M$.
- On the sheet: 9 lines, and greedy's 4 pairs are maximal, since no unused tick can be added.
- Tomas's route has 3 lines out and 2 in. Flipping it gives 5 pairs; stopping at Lena gives 4.
- Of the 512 sets of lines, the matchings of size 0 to 5 number 1, 9, 28, 35, 16 and 2.
- Only 20 of the 120 greedy orders reach 5. Greedy and the other perfect matching differ on all 9 lines.

Running the search code, and recounting perfect matchings over all 120 ways to hand out the jobs, is left to the Python and Rust checks.

<details>
<summary>The Lean proof, 563 lines</summary>

```lean
-- Matchings: in any finite graph a matching is as large as possible exactly when no augmenting path exists, and flipping an augmenting path gives a matching one line larger.
import Mathlib.Combinatorics.SimpleGraph.Matching

open SimpleGraph

/-! A matching is a `Subgraph` of `G` in which every dot it uses has exactly one partner
(Mathlib's `Subgraph.IsMatching`); its size is the number of its lines, `M.edgeSet.ncard`. -/

/-- An augmenting path for the matching `M`: a path (no dot repeated) between two different dots
that are both free in `M`, whose lines switch between outside `M` and inside `M` at every step.
"Alternating" is Mathlib's `IsAlternating`: wherever two lines of the path meet at a dot,
exactly one of them is in `M`. -/
def IsAugmentingPath {V : Type*} {G : SimpleGraph V} (M : G.Subgraph) {u w : V}
    (p : G.Walk u w) : Prop :=
  p.IsPath ∧ u ≠ w ∧ u ∉ M.verts ∧ w ∉ M.verts ∧
    p.toSubgraph.spanningCoe.IsAlternating M.spanningCoe

/-! Helper lemmas for the proofs below. -/
theorem matchAux_two_mul_ncard {V : Type*} [Finite V] (N : SimpleGraph V)
    (hN : ∀ v w w', N.Adj v w → N.Adj v w' → w = w') :
    2 * N.edgeSet.ncard = {v | ∃ w, N.Adj v w}.ncard := by
  classical
  have := Fintype.ofFinite V
  have h1 := N.sum_degrees_eq_twice_card_edges
  have h2 : N.edgeSet.ncard = N.edgeFinset.card := by
    rw [← Set.ncard_coe_finset, coe_edgeFinset]
  have h3 : ∀ v, N.degree v = if ∃ w, N.Adj v w then 1 else 0 := by
    intro v
    split_ifs with h
    · obtain ⟨w, hw⟩ := h
      rw [← card_neighborFinset_eq_degree, Finset.card_eq_one]
      refine ⟨w, ?_⟩
      ext y
      simp only [mem_neighborFinset, Finset.mem_singleton]
      exact ⟨fun hy => hN _ _ _ hy hw, fun hy => hy ▸ hw⟩
    · rw [← card_neighborFinset_eq_degree, Finset.card_eq_zero]
      ext y
      simp only [mem_neighborFinset, Finset.notMem_empty, iff_false]
      exact fun hy => h ⟨y, hy⟩
  simp_rw [h3, Finset.sum_boole] at h1
  rw [h2, ← h1, Set.ncard_eq_toFinset_card', Set.toFinset_ofPred]
  simp

#print axioms matchAux_two_mul_ncard

theorem matchAux_exists_free {V : Type*} [Finite V] (N N' : SimpleGraph V)
    (hN : ∀ v w w', N.Adj v w → N.Adj v w' → w = w')
    (hN' : ∀ v w w', N'.Adj v w → N'.Adj v w' → w = w')
    (hlt : N.edgeSet.ncard < N'.edgeSet.ncard) :
    ∃ x y, (∀ z, ¬ N.Adj x z) ∧ N'.Adj x y := by
  by_contra hcon
  push Not at hcon
  have hsub : {v | ∃ w, N'.Adj v w} ⊆ {v | ∃ w, N.Adj v w} := by
    rintro v ⟨w, hw⟩
    by_contra hv
    simp only [Set.mem_ofPred_eq, not_exists] at hv
    exact hcon v w hv hw
  have := Set.ncard_le_ncard hsub (Set.toFinite _)
  rw [← matchAux_two_mul_ncard N hN, ← matchAux_two_mul_ncard N' hN'] at this
  omega

#print axioms matchAux_exists_free

theorem matchAux_exists_edge {V : Type*} {G : SimpleGraph V} {a b v : V} (p : G.Walk a b)
    (hab : a ≠ b) (hv : v ∈ p.support) : ∃ y, s(v, y) ∈ p.edges := by
  rcases Walk.mem_support_iff_exists_mem_edges.mp hv with rfl | ⟨e, he, hve⟩
  · refine ⟨p.penultimate, ?_⟩
    have := p.toSubgraph_adj_penultimate (Walk.not_nil_of_ne hab)
    rw [Walk.adj_toSubgraph_iff_mem_edges] at this
    rwa [Sym2.eq_swap]
  · obtain ⟨y, rfl⟩ := Sym2.mem_iff_exists.mp hve
    exact ⟨y, he⟩

#print axioms matchAux_exists_edge

theorem matchAux_internal {V : Type*} {G : SimpleGraph V} {a b v : V} {p : G.Walk a b}
    (hp : p.IsPath) (hv : v ∈ p.support) (hva : v ≠ a) (hvb : v ≠ b) :
    ∃ y₁ y₂, y₁ ≠ y₂ ∧ s(v, y₁) ∈ p.edges ∧ s(v, y₂) ∈ p.edges := by
  obtain ⟨n, rfl, hn⟩ := Walk.mem_support_iff_exists_getVert.mp hv
  have h0 : n ≠ 0 := by rintro rfl; simp at hva
  have hl : n ≠ p.length := by rintro rfl; simp at hvb
  refine ⟨p.getVert (n - 1), p.getVert (n + 1), ?_, ?_, ?_⟩
  · intro h
    have := hp.getVert_injOn (by rw [Set.mem_ofPred_eq]; lia) (by rw [Set.mem_ofPred_eq]; lia) h
    lia
  · have := p.toSubgraph_adj_getVert (i := n - 1) (by lia)
    rw [show n - 1 + 1 = n by lia, Walk.adj_toSubgraph_iff_mem_edges] at this
    rwa [Sym2.eq_swap]
  · have := p.toSubgraph_adj_getVert (i := n) (by lia)
    rwa [Walk.adj_toSubgraph_iff_mem_edges] at this

#print axioms matchAux_internal

/-- Augmenting path data, phrased with edge lists. -/
def MatchAug {V : Type*} {G : SimpleGraph V} (N : SimpleGraph V) {u w : V} (p : G.Walk u w) :
    Prop :=
  p.IsPath ∧ u ≠ w ∧ (∀ y, ¬ N.Adj u y) ∧ (∀ y, ¬ N.Adj w y) ∧
    ∀ v x x', x ≠ x' → s(v, x) ∈ p.edges → s(v, x') ∈ p.edges → (N.Adj v x ↔ ¬ N.Adj v x')

theorem matchAux_reverse {V : Type*} {G : SimpleGraph V} {N : SimpleGraph V} {u w : V}
    {p : G.Walk u w} (h : MatchAug N p) : MatchAug N p.reverse := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  refine ⟨h1.reverse, h2.symm, h4, h3, ?_⟩
  intro v x x' hx hvx hvx'
  rw [Walk.edges_reverse, List.mem_reverse] at hvx hvx'
  exact h5 v x x' hx hvx hvx'

#print axioms matchAux_reverse

theorem matchAux_key {V : Type*} [Finite V] (G : SimpleGraph V) :
    ∀ n : ℕ, ∀ N N' : SimpleGraph V, N ≤ G → N' ≤ G →
      (∀ v w w', N.Adj v w → N.Adj v w' → w = w') →
      (∀ v w w', N'.Adj v w → N'.Adj v w' → w = w') →
      N'.edgeSet.ncard = n → N.edgeSet.ncard < n →
      ∃ (u w : V) (p : G.Walk u w), MatchAug N p ∧
        ∀ e ∈ p.edges, e ∈ N.edgeSet ∨ e ∈ N'.edgeSet := by
  intro n
  induction n with
  | zero => intros; omega
  | succ n ih =>
    intro N N' hNG hN'G hN hN' hcard hlt
    obtain ⟨x0, x1, hx0, h01⟩ := matchAux_exists_free N N' hN hN' (by omega)
    have hG01 : G.Adj x0 x1 := hN'G h01
    have hne01 : x0 ≠ x1 := hG01.ne
    by_cases hx1 : ∃ x2, N.Adj x1 x2
    swap
    · push Not at hx1
      refine ⟨x0, x1, Walk.cons hG01 Walk.nil, ⟨?_, hne01, hx0, hx1, ?_⟩, ?_⟩
      · simp [Walk.cons_isPath_iff, hne01]
      · intro v x x' hx hvx hvx'
        simp only [Walk.edges_cons, Walk.edges_nil, List.mem_cons, List.not_mem_nil,
          or_false] at hvx hvx'
        exact absurd (Sym2.congr_right.mp (hvx.trans hvx'.symm)) hx
      · intro e he
        simp only [Walk.edges_cons, Walk.edges_nil, List.mem_cons, List.not_mem_nil,
          or_false] at he
        subst he
        exact Or.inr h01
    obtain ⟨x2, h12⟩ := hx1
    have hne12 : x1 ≠ x2 := (hNG h12).ne
    have hx0x2 : x0 ≠ x2 := by
      rintro rfl
      exact hx0 x1 h12.symm
    set N2 := N.deleteEdges {s(x1, x2)} with hN2def
    set N2' := N'.deleteEdges {s(x0, x1)} with hN2'def
    have hN2adj : ∀ a b, N2.Adj a b ↔ N.Adj a b ∧ ¬ s(a, b) = s(x1, x2) := by
      intro a b; simp [N2]
    have hN2'adj : ∀ a b, N2'.Adj a b ↔ N'.Adj a b ∧ ¬ s(a, b) = s(x0, x1) := by
      intro a b; simp [N2']
    have hfin : ∀ H : SimpleGraph V, H.edgeSet.Finite := fun H => Set.toFinite _
    have hc1 : N2'.edgeSet.ncard = n := by
      rw [hN2'def, edgeSet_deleteEdges,
        Set.ncard_sdiff_singleton_of_mem (show s(x0, x1) ∈ N'.edgeSet from h01)]
      omega
    have hc2 : N2.edgeSet.ncard < n := by
      have h1 : N2.edgeSet.ncard = N.edgeSet.ncard - 1 := by
        rw [hN2def, edgeSet_deleteEdges,
          Set.ncard_sdiff_singleton_of_mem (show s(x1, x2) ∈ N.edgeSet from h12)]
      have hpos : 0 < N.edgeSet.ncard := (Set.ncard_pos (hfin _)).mpr ⟨s(x1, x2), h12⟩
      omega
    have hN2m : ∀ v w w', N2.Adj v w → N2.Adj v w' → w = w' := fun v w w' h h' =>
      hN v w w' ((hN2adj _ _).mp h).1 ((hN2adj _ _).mp h').1
    have hN2'm : ∀ v w w', N2'.Adj v w → N2'.Adj v w' → w = w' := fun v w w' h h' =>
      hN' v w w' ((hN2'adj _ _).mp h).1 ((hN2'adj _ _).mp h').1
    obtain ⟨u, w, p2, hp2, hp2e⟩ := ih N2 N2' (le_trans (deleteEdges_le _) hNG)
      (le_trans (deleteEdges_le _) hN'G) hN2m hN2'm hc1 hc2
    -- isolated vertices
    have hiso : ∀ z, (∀ y, ¬ N2.Adj z y ∧ ¬ N2'.Adj z y) → ∀ (a b : V) (q : G.Walk a b),
        a ≠ b → (∀ e ∈ q.edges, e ∈ N2.edgeSet ∨ e ∈ N2'.edgeSet) → z ∉ q.support := by
      intro z hz a b q hab hqe hzq
      obtain ⟨y, hy⟩ := matchAux_exists_edge q hab hzq
      rcases hqe _ hy with h | h
      · exact (hz y).1 h
      · exact (hz y).2 h
    have hx0i : ∀ y, ¬ N2.Adj x0 y ∧ ¬ N2'.Adj x0 y := by
      intro y
      refine ⟨fun h => hx0 y ((hN2adj _ _).mp h).1, fun h => ?_⟩
      obtain ⟨h1, h2⟩ := (hN2'adj _ _).mp h
      exact h2 (by rw [hN' _ _ _ h1 h01])
    have hx1i : ∀ y, ¬ N2.Adj x1 y ∧ ¬ N2'.Adj x1 y := by
      intro y
      refine ⟨fun h => ?_, fun h => ?_⟩
      · obtain ⟨h1, h2⟩ := (hN2adj _ _).mp h
        exact h2 (by rw [hN _ _ _ h1 h12])
      · obtain ⟨h1, h2⟩ := (hN2'adj _ _).mp h
        exact h2 (by rw [hN' _ _ _ h1 h01.symm, Sym2.eq_swap])
    have hx2 : ∀ y, ¬ N2.Adj x2 y := by
      intro y h
      obtain ⟨h1, h2⟩ := (hN2adj _ _).mp h
      exact h2 (by rw [hN _ _ _ h1 h12.symm, Sym2.eq_swap])
    have hNiff : ∀ a b, a ≠ x1 → a ≠ x2 → (N.Adj a b ↔ N2.Adj a b) := by
      intro a b ha1 ha2
      rw [hN2adj]
      refine ⟨fun h => ⟨h, fun he => ?_⟩, fun h => h.1⟩
      rcases Sym2.eq_iff.mp he with ⟨h1, -⟩ | ⟨h1, -⟩
      · exact ha1 h1
      · exact ha2 h1
    have halt2 : ∀ (a b : V) (q : G.Walk a b), MatchAug N2 q → ∀ x x', x ≠ x' →
        s(x2, x) ∈ q.edges → s(x2, x') ∈ q.edges → False := by
      intro a b q hq x x' hxx h h'
      have := hq.2.2.2.2 x2 x x' hxx h h'
      rw [iff_false_left (hx2 x), not_not] at this
      exact hx2 x' this
    have hEsub : ∀ e, e ∈ N2.edgeSet ∨ e ∈ N2'.edgeSet → e ∈ N.edgeSet ∨ e ∈ N'.edgeSet := by
      intro e he
      rw [hN2def, hN2'def, edgeSet_deleteEdges, edgeSet_deleteEdges] at he
      rcases he with he | he
      · exact Or.inl he.1
      · exact Or.inr he.1
    -- the case where the path starts at x2
    have key : ∀ (s w : V) (q : G.Walk s w), s = x2 → MatchAug N2 q →
        (∀ e ∈ q.edges, e ∈ N2.edgeSet ∨ e ∈ N2'.edgeSet) →
        ∃ (u w : V) (p : G.Walk u w), MatchAug N p ∧
          ∀ e ∈ p.edges, e ∈ N.edgeSet ∨ e ∈ N'.edgeSet := by
      intro s w q hs hq hqe
      subst hs
      have h0q := hiso x0 hx0i _ _ q hq.2.1 hqe
      have h1q := hiso x1 hx1i _ _ q hq.2.1 hqe
      refine ⟨x0, w, Walk.cons hG01 (Walk.cons (hNG h12) q), ⟨?_, ?_, hx0, ?_, ?_⟩, ?_⟩
      · rw [Walk.cons_isPath_iff, Walk.cons_isPath_iff]
        refine ⟨⟨hq.1, h1q⟩, ?_⟩
        rw [Walk.support_cons, List.mem_cons, not_or]
        exact ⟨hne01, h0q⟩
      · rintro rfl
        exact h0q q.end_mem_support
      · intro y hy
        have hw1 : w ≠ x1 := by rintro rfl; exact h1q q.end_mem_support
        have hw2 : w ≠ s := fun h => hq.2.1 h.symm
        exact hq.2.2.2.1 y ((hNiff w y hw1 hw2).mp hy)
      · intro v x x' hxx hvx hvx'
        simp only [Walk.edges_cons, List.mem_cons] at hvx hvx'
        rcases hvx with h | h | h <;> rcases hvx' with h' | h' | h'
        · exact absurd (Sym2.congr_right.mp (h.trans h'.symm)) hxx
        · rcases Sym2.eq_iff.mp h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
          · rcases Sym2.eq_iff.mp h' with ⟨h1, -⟩ | ⟨h1, -⟩
            · exact absurd h1 hne01
            · exact absurd h1 hx0x2
          · rcases Sym2.eq_iff.mp h' with ⟨-, rfl⟩ | ⟨h1, -⟩
            · exact iff_of_false (fun h => hx0 _ h.symm) (not_not.mpr h12)
            · exact absurd h1 hne12
        · have hv := Walk.fst_mem_support_of_mem_edges q h'
          rcases Sym2.eq_iff.mp h with ⟨rfl, -⟩ | ⟨rfl, -⟩
          · exact absurd hv h0q
          · exact absurd hv h1q
        · rcases Sym2.eq_iff.mp h' with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
          · rcases Sym2.eq_iff.mp h with ⟨h1, -⟩ | ⟨h1, -⟩
            · exact absurd h1 hne01
            · exact absurd h1 hx0x2
          · rcases Sym2.eq_iff.mp h with ⟨-, rfl⟩ | ⟨h1, -⟩
            · exact iff_of_true h12 (fun h => hx0 _ h.symm)
            · exact absurd h1 hne12
        · exact absurd (Sym2.congr_right.mp (h.trans h'.symm)) hxx
        · have hv := Walk.fst_mem_support_of_mem_edges q h'
          rcases Sym2.eq_iff.mp h with ⟨rfl, -⟩ | ⟨rfl, rfl⟩
          · exact absurd hv h1q
          · refine iff_of_true h12.symm (fun h => hxx ?_)
            exact (hN _ _ _ h h12.symm).symm
        · have hv := Walk.fst_mem_support_of_mem_edges q h
          rcases Sym2.eq_iff.mp h' with ⟨rfl, -⟩ | ⟨rfl, -⟩
          · exact absurd hv h0q
          · exact absurd hv h1q
        · have hv := Walk.fst_mem_support_of_mem_edges q h
          rcases Sym2.eq_iff.mp h' with ⟨rfl, -⟩ | ⟨rfl, rfl⟩
          · exact absurd hv h1q
          · refine iff_of_false (fun h => hxx ?_) (not_not.mpr h12.symm)
            exact hN _ _ _ h h12.symm
        · have hv := Walk.fst_mem_support_of_mem_edges q h
          have hv1 : v ≠ x1 := by rintro rfl; exact h1q hv
          by_cases hv2 : v = s
          · subst hv2
            exact (halt2 _ _ q hq x x' hxx h h').elim
          · rw [hNiff v x hv1 hv2, hNiff v x' hv1 hv2]
            exact hq.2.2.2.2 v x x' hxx h h'
      · intro e he
        simp only [Walk.edges_cons, List.mem_cons] at he
        rcases he with rfl | rfl | he
        · exact Or.inr h01
        · exact Or.inl h12
        · exact hEsub e (hqe e he)
    by_cases hu : u = x2
    · exact key u w p2 hu hp2 hp2e
    by_cases hw : w = x2
    · refine key w u p2.reverse hw (matchAux_reverse hp2) ?_
      intro e he
      rw [Walk.edges_reverse, List.mem_reverse] at he
      exact hp2e e he
    have h1p := hiso x1 hx1i _ _ p2 hp2.2.1 hp2e
    refine ⟨u, w, p2, ⟨hp2.1, hp2.2.1, ?_, ?_, ?_⟩, fun e he => hEsub e (hp2e e he)⟩
    · intro y hy
      have hu1 : u ≠ x1 := by rintro rfl; exact h1p p2.start_mem_support
      exact hp2.2.2.1 y ((hNiff u y hu1 hu).mp hy)
    · intro y hy
      have hw1 : w ≠ x1 := by rintro rfl; exact h1p p2.end_mem_support
      exact hp2.2.2.2.1 y ((hNiff w y hw1 hw).mp hy)
    · intro v x x' hxx h h'
      have hv := Walk.fst_mem_support_of_mem_edges p2 h
      have hv1 : v ≠ x1 := by rintro rfl; exact h1p hv
      by_cases hv2 : v = x2
      · subst hv2
        exact (halt2 _ _ p2 hp2 x x' hxx h h').elim
      · rw [hNiff v x hv1 hv2, hNiff v x' hv1 hv2]
        exact hp2.2.2.2.2 v x x' hxx h h'

#print axioms matchAux_key

theorem matchAux_flip {V : Type*} [Finite V] {G : SimpleGraph V} (M : G.Subgraph)
    (hM : M.IsMatching) {u w : V} (p : G.Walk u w) (hpath : p.IsPath) (hne : u ≠ w)
    (hu : ∀ y, ¬ M.Adj u y) (hw : ∀ y, ¬ M.Adj w y)
    (halt : ∀ v x x', x ≠ x' → s(v, x) ∈ p.edges → s(v, x') ∈ p.edges →
      (M.Adj v x ↔ ¬ M.Adj v x')) :
    ∃ M' : G.Subgraph, M'.IsMatching ∧ M'.edgeSet = symmDiff M.edgeSet p.edgeSet ∧
      M'.edgeSet.ncard = M.edgeSet.ncard + 1 := by
  let S : SimpleGraph V :=
    { Adj := fun a b => (M.Adj a b ∧ s(a, b) ∉ p.edges) ∨ (s(a, b) ∈ p.edges ∧ ¬ M.Adj a b)
      symm := ⟨fun a b h => by
        rcases h with ⟨h1, h2⟩ | ⟨h1, h2⟩
        · exact Or.inl ⟨h1.symm, by rwa [Sym2.eq_swap]⟩
        · exact Or.inr ⟨by rwa [Sym2.eq_swap], fun h => h2 h.symm⟩⟩
      loopless := ⟨fun a h => by
        rcases h with ⟨h1, -⟩ | ⟨h1, -⟩
        · exact (M.adj_sub h1).ne rfl
        · exact (p.adj_of_mem_edges h1).ne rfl⟩ }
  have hSadj : ∀ a b, S.Adj a b ↔
      (M.Adj a b ∧ s(a, b) ∉ p.edges) ∨ (s(a, b) ∈ p.edges ∧ ¬ M.Adj a b) := fun _ _ => Iff.rfl
  have hInt : ∀ v x, M.Adj v x → v ∈ p.support → s(v, x) ∈ p.edges := by
    intro v x hvx hv
    have hvu : v ≠ u := by rintro rfl; exact hu x hvx
    have hvw : v ≠ w := by rintro rfl; exact hw x hvx
    obtain ⟨y₁, y₂, hy, h1, h2⟩ := matchAux_internal hpath hv hvu hvw
    by_cases hm : M.Adj v y₁
    · rwa [hM.eq_of_adj_left hvx hm]
    · have hm2 : M.Adj v y₂ := by
        have := halt v y₁ y₂ hy h1 h2
        tauto
      rwa [hM.eq_of_adj_left hvx hm2]
  have hS : ∀ v x x', S.Adj v x → S.Adj v x' → x = x' := by
    intro v x x' h h'
    by_contra hxx
    rw [hSadj] at h h'
    rcases h with ⟨a1, a2⟩ | ⟨a1, a2⟩ <;> rcases h' with ⟨b1, b2⟩ | ⟨b1, b2⟩
    · exact hxx (hM.eq_of_adj_left a1 b1)
    · exact a2 (hInt v x a1 (Walk.fst_mem_support_of_mem_edges p b1))
    · exact b2 (hInt v x' b1 (Walk.fst_mem_support_of_mem_edges p a1))
    · have := halt v x x' hxx a1 b1
      tauto
  have hsupp : {v | ∃ y, S.Adj v y} = insert u (insert w {v | ∃ y, M.spanningCoe.Adj v y}) := by
    ext v
    simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Subgraph.spanningCoe_adj]
    constructor
    · rintro ⟨y, h⟩
      rw [hSadj] at h
      rcases h with ⟨h1, -⟩ | ⟨h1, -⟩
      · exact Or.inr (Or.inr ⟨y, h1⟩)
      · by_cases hvu : v = u
        · exact Or.inl hvu
        by_cases hvw : v = w
        · exact Or.inr (Or.inl hvw)
        obtain ⟨y₁, y₂, hy, e1, e2⟩ :=
          matchAux_internal hpath (Walk.fst_mem_support_of_mem_edges p h1) hvu hvw
        have := halt v y₁ y₂ hy e1 e2
        by_cases hm : M.Adj v y₁
        · exact Or.inr (Or.inr ⟨y₁, hm⟩)
        · exact Or.inr (Or.inr ⟨y₂, by tauto⟩)
    · rintro (rfl | rfl | ⟨y, hy⟩)
      · refine ⟨p.snd, Or.inr ⟨?_, hu _⟩⟩
        have := p.toSubgraph_adj_snd (Walk.not_nil_of_ne hne)
        rwa [Walk.adj_toSubgraph_iff_mem_edges] at this
      · refine ⟨p.penultimate, Or.inr ⟨?_, hw _⟩⟩
        have := p.toSubgraph_adj_penultimate (Walk.not_nil_of_ne hne)
        rw [Walk.adj_toSubgraph_iff_mem_edges] at this
        rwa [Sym2.eq_swap]
      · by_cases he : s(v, y) ∈ p.edges
        · have hvu : v ≠ u := by rintro rfl; exact hu y hy
          have hvw : v ≠ w := by rintro rfl; exact hw y hy
          obtain ⟨y₁, y₂, hyy, e1, e2⟩ :=
            matchAux_internal hpath (Walk.fst_mem_support_of_mem_edges p he) hvu hvw
          have := halt v y₁ y₂ hyy e1 e2
          by_cases hm : M.Adj v y₁
          · exact ⟨y₂, Or.inr ⟨e2, by tauto⟩⟩
          · exact ⟨y₁, Or.inr ⟨e1, hm⟩⟩
        · exact ⟨y, Or.inl ⟨hy, he⟩⟩
  have hMm : ∀ v x x', M.spanningCoe.Adj v x → M.spanningCoe.Adj v x' → x = x' :=
    fun v x x' h h' => hM.eq_of_adj_left h h'
  have hcount := matchAux_two_mul_ncard S hS
  have hcountM := matchAux_two_mul_ncard M.spanningCoe hMm
  rw [hsupp, Set.ncard_insert_of_notMem, Set.ncard_insert_of_notMem, ← hcountM,
    Subgraph.edgeSet_spanningCoe] at hcount
  rotate_left
  · simp only [Set.mem_ofPred_eq, Subgraph.spanningCoe_adj, not_exists]
    exact hw
  · simp only [Set.mem_insert_iff, Set.mem_ofPred_eq, Subgraph.spanningCoe_adj, not_or,
      not_exists]
    exact ⟨hne, hu⟩
  let M' : G.Subgraph :=
    { verts := {v | ∃ y, S.Adj v y}
      Adj := S.Adj
      adj_sub := fun {a b} h => by
        rcases h with ⟨h1, -⟩ | ⟨h1, -⟩
        · exact M.adj_sub h1
        · exact p.adj_of_mem_edges h1
      edge_vert := fun {a b} h => ⟨b, h⟩
      symm := S.symm }
  have hE : M'.edgeSet = S.edgeSet := by
    ext e
    induction e using Sym2.ind with
    | _ a b => rfl
  have hE2 : M'.edgeSet = symmDiff M.edgeSet p.edgeSet := by
    ext e
    induction e using Sym2.ind with
    | _ a b =>
      rw [Subgraph.mem_edgeSet, Set.mem_symmDiff, Subgraph.mem_edgeSet, Walk.mem_edgeSet]
  refine ⟨M', ?_, hE2, ?_⟩
  · intro v hv
    obtain ⟨y, hy⟩ := hv
    exact ⟨y, hy, fun z hz => hS v z y hz hy⟩
  · rw [hE]
    omega

#print axioms matchAux_flip

theorem matchAux_of_aug {V : Type*} {G : SimpleGraph V} (M : G.Subgraph) {u w : V}
    (p : G.Walk u w) (hp : IsAugmentingPath M p) :
    p.IsPath ∧ u ≠ w ∧ (∀ y, ¬ M.Adj u y) ∧ (∀ y, ¬ M.Adj w y) ∧
      ∀ v x x', x ≠ x' → s(v, x) ∈ p.edges → s(v, x') ∈ p.edges →
        (M.Adj v x ↔ ¬ M.Adj v x') := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := hp
  refine ⟨h1, h2, fun y hy => h3 (M.edge_vert hy), fun y hy => h4 (M.edge_vert hy), ?_⟩
  intro v x x' hxx h h'
  have := @h5 v x x' hxx (by simpa [Walk.adj_toSubgraph_iff_mem_edges] using h)
    (by simpa [Walk.adj_toSubgraph_iff_mem_edges] using h')
  simpa using this

#print axioms matchAux_of_aug

/-- Berge's theorem: in any finite graph, a matching is maximum (no matching of the graph has more
lines) exactly when the graph has no augmenting path for it. -/
theorem matching_maximum_iff_no_augmenting_path {V : Type*} [Finite V] (G : SimpleGraph V)
    (M : G.Subgraph) (hM : M.IsMatching) :
    (∀ M' : G.Subgraph, M'.IsMatching → M'.edgeSet.ncard ≤ M.edgeSet.ncard) ↔
      ¬ ∃ (u w : V) (p : G.Walk u w), IsAugmentingPath M p := by
  constructor
  · rintro hmax ⟨u, w, p, hp⟩
    obtain ⟨h1, h2, h3, h4, h5⟩ := matchAux_of_aug M p hp
    obtain ⟨M', hM', -, hc⟩ := matchAux_flip M hM p h1 h2 h3 h4 h5
    have := hmax M' hM'
    omega
  · intro hno M' hM'
    by_contra hlt
    push Not at hlt
    obtain ⟨u, w, p, hp, -⟩ := matchAux_key G _ M.spanningCoe M'.spanningCoe M.spanningCoe_le
      M'.spanningCoe_le (fun _ _ _ h h' => hM.eq_of_adj_left h h')
      (fun _ _ _ h h' => hM'.eq_of_adj_left h h') rfl
      (by rw [Subgraph.edgeSet_spanningCoe, Subgraph.edgeSet_spanningCoe]; exact hlt)
    apply hno
    refine ⟨u, w, p, hp.1, hp.2.1, ?_, ?_, ?_⟩
    · intro hu
      obtain ⟨y, hy, -⟩ := hM hu
      exact hp.2.2.1 y hy
    · intro hw
      obtain ⟨y, hy, -⟩ := hM hw
      exact hp.2.2.2.1 y hy
    · intro v x x' hxx h h'
      simp only [Subgraph.spanningCoe_adj, Walk.adj_toSubgraph_iff_mem_edges] at h h' ⊢
      exact hp.2.2.2.2 v x x' hxx h h'

/-- The repair: flip every line of an augmenting path `P`, in for out and out for in. The lines in
exactly one of `M` and `P`, `M △ P`, form a matching, and it has one more line than `M`. -/
theorem augmenting_path_flip_adds_one {V : Type*} [Finite V] (G : SimpleGraph V)
    (M : G.Subgraph) (hM : M.IsMatching) {u w : V} (p : G.Walk u w)
    (hp : IsAugmentingPath M p) :
    ∃ M' : G.Subgraph, M'.IsMatching ∧ M'.edgeSet = symmDiff M.edgeSet p.edgeSet ∧
      M'.edgeSet.ncard = M.edgeSet.ncard + 1 := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := matchAux_of_aug M p hp
  exact matchAux_flip M hM p h1 h2 h3 h4 h5

/-! The card's sign-up sheet. Volunteers 0 to 4 are Priya, Omar, Lena, Sam, Tomas; jobs 0 to 4
are registration, first aid, water, parking, timing. A line `(v, t)` is a tick: volunteer `v`
can do job `t`. A pairing is a set of ticks with no volunteer and no job used twice. -/

/-- The nine ticks on the sheet. -/
def ticks : Finset (Fin 5 × Fin 5) :=
  {(0, 0), (0, 1), (1, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 3), (4, 0)}

/-- A set of ticks is a pairing when no volunteer and no job appears twice. -/
def IsPairing (S : Finset (Fin 5 × Fin 5)) : Prop :=
  S ⊆ ticks ∧ (∀ a ∈ S, ∀ b ∈ S, a.1 = b.1 → a = b) ∧ (∀ a ∈ S, ∀ b ∈ S, a.2 = b.2 → a = b)

instance (S : Finset (Fin 5 × Fin 5)) : Decidable (IsPairing S) := by
  unfold IsPairing; infer_instance

/-- Greedy in sheet order: Priya-registration, Omar-water, Lena-first aid, Sam-parking. -/
def greedyPairs : Finset (Fin 5 × Fin 5) := {(0, 0), (1, 2), (2, 1), (3, 3)}
/-- Tomas's route, lines outside greedy: Tomas-registration, Priya-first aid, Lena-timing. -/
def routeOut : Finset (Fin 5 × Fin 5) := {(4, 0), (0, 1), (2, 4)}
/-- Tomas's route, lines inside greedy: Priya-registration, Lena-first aid. -/
def routeIn : Finset (Fin 5 × Fin 5) := {(0, 0), (2, 1)}
/-- The other perfect pairing: Omar and Sam swap water and parking. -/
def otherPerfect : Finset (Fin 5 × Fin 5) := {(4, 0), (0, 1), (3, 2), (1, 3), (2, 4)}

-- Nine lines on the sheet.
example : ticks.card = 9 := by decide
-- Greedy is a pairing of 4 lines, and maximal: no unused tick can be added as it stands.
example : IsPairing greedyPairs ∧ greedyPairs.card = 4 := by decide
example : ∀ e ∈ ticks, e ∉ greedyPairs → ¬ IsPairing (insert e greedyPairs) := by decide
-- The augmenting route has 5 lines, 3 out and 2 in; flipping it gives 4 - 2 + 3 = 5 pairs.
example : routeOut ⊆ ticks ∧ Disjoint routeOut greedyPairs ∧ routeIn ⊆ greedyPairs ∧
    routeOut.card = 3 ∧ routeIn.card = 2 := by decide
example : IsPairing ((greedyPairs \ routeIn) ∪ routeOut) ∧
    ((greedyPairs \ routeIn) ∪ routeOut).card = 5 := by decide
example : 4 - 2 + 3 = 5 := by norm_num
-- Swapping only as far as Lena (Tomas in, Priya moved, Lena dropped) still gives 4 pairs.
example : IsPairing (((greedyPairs \ routeIn) ∪ routeOut).erase (2, 4)) ∧
    (((greedyPairs \ routeIn) ∪ routeOut).erase (2, 4)).card = 4 := by decide
/-- The same nine ticks as a list, so a set of ticks can be named by a 9-bit number. -/
def tickList : List (Fin 5 × Fin 5) :=
  [(0, 0), (0, 1), (1, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 3), (4, 0)]
/-- The set of ticks picked out by the bits of `m`, for `m` from 0 to 511. -/
def pick (m : ℕ) : List (Fin 5 × Fin 5) :=
  ((List.range 9).filter (fun i => m.testBit i)).filterMap (fun i => tickList[i]?)
/-- No volunteer and no job used twice. -/
def pairingB (l : List (Fin 5 × Fin 5)) : Bool :=
  decide (l.map Prod.fst).Nodup && decide (l.map Prod.snd).Nodup
/-- How many of the 512 sets of ticks are pairings of size `k`. -/
def pairingsOfSize (k : ℕ) : ℕ :=
  ((List.range 512).filter (fun m => pairingB (pick m) && (pick m).length == k)).length

/-- Each volunteer's ticks, in sheet order. -/
def canDo (v : Fin 5) : List (Fin 5) := [[0, 1], [2, 3], [1, 4], [2, 3], [0]].getD v.val []
/-- Greedy: in the given order, each volunteer takes the first job on their list still free. -/
def greedyRun (order : List (Fin 5)) : List (Fin 5 × Fin 5) :=
  order.foldl (fun acc v =>
    match (canDo v).find? (fun t => !(acc.any (fun e => e.2 == t))) with
    | some t => acc ++ [(v, t)]
    | none => acc) []

/-- Every way to put `x` somewhere into a list. -/
def insertEverywhere (x : Fin 5) : List (Fin 5) → List (List (Fin 5))
  | [] => [[x]]
  | y :: ys => (x :: y :: ys) :: (insertEverywhere x ys).map (y :: ·)
/-- Every order of a list, written out here. -/
def allOrders : List (Fin 5) → List (List (Fin 5))
  | [] => [[]]
  | x :: xs => (allOrders xs).flatMap (insertEverywhere x)

-- The list holds the same nine ticks.
example : tickList.toFinset = ticks ∧ tickList.length = 9 := by decide
-- Greedy in sheet order gives exactly the four pairs above.
example : (greedyRun (List.finRange 5)).toFinset = greedyPairs := by decide +kernel
-- 512 sets of lines; the pairings among them, by size 0 to 5: 1, 9, 28, 35, 16, 2 (91 in all).
-- The largest size reached is 5, and exactly 2 pairings are perfect.
example : 2 ^ 9 = 512 := by norm_num
example : (List.range 7).map pairingsOfSize = [1, 9, 28, 35, 16, 2, 0] := by decide +kernel
example : ((List.range 512).filter (fun m => pairingB (pick m))).length = 91 := by decide +kernel
-- Only 20 of the 120 orders of volunteers let greedy reach 5.
example : (allOrders (List.finRange 5)).length = 120 ∧
    ((allOrders (List.finRange 5)).filter (fun o => (greedyRun o).length == 5)).length = 20 := by
  decide +kernel
-- Greedy and the other perfect pairing differ on all 9 lines: 5 from it, 4 from greedy.
example : (symmDiff greedyPairs otherPerfect).card = 9 ∧ (otherPerfect \ greedyPairs).card = 5 ∧
    (greedyPairs \ otherPerfect).card = 4 := by decide

#print axioms matching_maximum_iff_no_augmenting_path
#print axioms augmenting_path_flip_adds_one
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'matchAux_two_mul_ncard' depends on axioms: [propext, Classical.choice, Quot.sound]
'matchAux_exists_free' depends on axioms: [propext, Classical.choice, Quot.sound]
'matchAux_exists_edge' depends on axioms: [propext, Classical.choice, Quot.sound]
'matchAux_internal' depends on axioms: [propext, Classical.choice, Quot.sound]
'matchAux_reverse' depends on axioms: [propext, Quot.sound]
'matchAux_key' depends on axioms: [propext, Classical.choice, Quot.sound]
'matchAux_flip' depends on axioms: [propext, Classical.choice, Quot.sound]
'matchAux_of_aug' depends on axioms: [propext, Classical.choice, Quot.sound]
'matching_maximum_iff_no_augmenting_path' depends on axioms: [propext, Classical.choice, Quot.sound]
'augmenting_path_flip_adds_one' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The fourth assert is pinned to this sheet's greedy count.
> - **Tomas also ticks first aid.** Set his list to `[0, 1]`. Greedy still stalls at 4 and the same route repairs it; perfect matchings double to 4, 40 of 120 orders reach 5, and the fourth assert stops it.
> - **Lena lists timing first.** Set her list to `[4, 1]`. Greedy leaves first aid empty and the route shrinks to 3 lines, ending at first aid; 60 of 120 orders reach 5, and the fourth assert stops it.
> - **Priya lists first aid first.** Set her list to `[1, 0]`. Greedy reaches 5 alone, no route exists, and the program halts: there is nothing to flip.

---

## The usual mistake

> [!warning]
> **Reading "nothing can be added" as "as large as possible".** Greedy's four pairs take no fifth line, yet five pairs exist. Only the absence of an augmenting path certifies a maximum.
>
> - **Stopping a swap at a busy dot.** Swapping only as far as Lena still gives 4.
> - **Rerunning greedy until it works.** Only 20 of 120 orders reach 5, and greedy never knows it failed.
> - **Counting lines instead of pairs.** Nine ticks do not promise five pairs: of the 91 matchings, only 2 reach 5.

---

## Where you meet it in real life

- **Rostering and dispatch.** Nurses to shifts, drivers to waiting riders, reviewers to papers: one each, and a stuck draft is repaired by a chain of reassignments.
- **Hiring.** Whether every applicant can be placed at all is decided by [Hall's theorem](02-halls-marriage-theorem.md).
- **Network flow.** Pairing is the smallest case of pushing traffic through pipes, leading to [Max-flow min-cut](06-max-flow-min-cut.md).

> **Say it back**
> A matching pairs dots along lines, no dot used twice. A matching that takes no extra line may still not be the largest. An augmenting path runs between two free dots, alternating out and in, with one spare outside line; flipping it adds a pair. If no such path exists, the matching is the largest, because any larger one would leave such a path in the difference.

---

## What this builds on

- [Bipartite graphs](../09-Graphs%20-%20Dots%20and%20Lines/05-bipartite-graphs-and-odd-cycles.md): the two-sided graph, and the odd loops that complicate the search outside it.

## Where this goes next

- [Hall's theorem](02-halls-marriage-theorem.md): when a matching can cover one whole side.
- [Stable matching](04-stable-matching-gale-shapley.md): pairings that respect preferences, not only size.
- [The assignment problem](../../14-Applied%20and%20computational/05-Operations%20Research/05-assignment-and-the-hungarian-algorithm.md): the cheapest perfect matching when every pair has a cost.
- [Total unimodularity](../../15-Optimization/05-Integer%20and%20Combinatorial%20Optimisation/05-total-unimodularity.md): why matching problems solved with fractions still land on whole pairs.
- Permanent against determinant: counting perfect matchings, the 2 here, is easy to state and hard to compute.

Berge says when a matching is stuck but not why; which crowded group of volunteers blocks a full pairing is the question [Hall's theorem](02-halls-marriage-theorem.md) answers.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Berge, Claude. "Two Theorems in Graph Theory." *Proceedings of the National Academy of Sciences* 43, no. 9 (1957): 842–844. [doi:10.1073/pnas.43.9.842](https://doi.org/10.1073/pnas.43.9.842). The augmenting-path theorem, stated for any graph.
- Diestel, Reinhard. *Graph Theory*, 6th ed. Graduate Texts in Mathematics 173. Springer, 2025. [Book page, with the free electronic edition](https://diestel-graph-theory.com/). Chapter 2: alternating and augmenting paths, and the search in two-sided graphs.
- Bondy, J. A., and U. S. R. Murty. *Graph Theory*. Graduate Texts in Mathematics 244. Springer, 2008. [Publisher page](https://link.springer.com/book/9781846289699). The matching chapter proves Berge by the difference of two matchings, as in Step 2.
- Lovász, László, and Michael D. Plummer. *Matching Theory*. AMS Chelsea Publishing, 2009. [doi:10.1090/chel/367](https://doi.org/10.1090/chel/367). The full theory, including the blossom method for graphs with odd loops.
