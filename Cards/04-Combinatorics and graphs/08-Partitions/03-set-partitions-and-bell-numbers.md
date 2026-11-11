# Set partitions and Bell numbers: splitting distinct people into unnamed teams of any sizes

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Partitions](../README.md#s08) → Set partitions and Bell numbers

---

## General Overview

Four friends leave a restaurant at midnight: Ada, Ben, Cleo and Dara. They share taxis home: any number of cars, and nobody walks. The cars carry no numbers, so the only thing the evening settles is who rides with whom.

Fifteen ways. Ada and Ben in one car with Cleo and Dara in the other is one; swapping the two cars changes nothing, since neither is "the first". Ada and Cleo together, Ben and Dara together, is a different way: the friends have names even though the cars do not. All four in one car counts, and so does four cars, one each.

Add a fifth friend and fifteen becomes fifty-two; add a sixth and it is 203. The counts are named after Eric Temple Bell, who wrote about them in 1934.

A cut like this is a **set partition**, and its groups are its **blocks**. Every person is in one block, no block is empty, and how many blocks there are is not fixed.

**Write B(n) for the number of ways to cut n named people into unnamed non-empty groups; each count is built from the smaller ones by asking who shares a group with the newest person.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; the set partition it counts is a definition.

### The picture: fifteen splits, sorted by Dara's company

```mermaid
flowchart TB
    A["Four friends, unnamed taxis<br/>15 splits in all"]
    A -->|"Dara rides with all three"| B["nobody left over: 1"]
    A -->|"Dara rides with two of them"| C["one left over: 3"]
    A -->|"Dara rides with one of them"| D["two left over: 6"]
    A -->|"Dara rides alone"| E["three left over: 5"]
```

Dara has one taxi, so every split lands in exactly one branch: 1 + 3 + 6 + 5 = 15.

---

## The formula

Two pieces of notation carry the card, both written as functions rather than with subscripts. $B(n)$, read "B of n", is the number of splits of n named people: the Bell number. $C(n, k)$, read "n choose k", counts the ways to pick k of n, order ignored ([Pascal's rule](../03-Binomial%20Coefficients%20and%20Identities/01-pascals-rule-and-the-triangle.md)).

$$B(n+1) = C(n,0)\,B(0) + C(n,1)\,B(1) + \cdots + C(n,n)\,B(n)$$

**Read it aloud:** choose who is left out of the newest person's group, split those left out any way at all, and add over how many are left out.

A formula that builds each count out of the smaller ones, as this one does, is a **recurrence**.

The sum stands on a floor:

$$B(0) = 1$$

An empty crowd splits exactly one way: into no groups at all.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $n$ | people already there, before the newest joins | 3: Ada, Ben and Cleo | climbs faster than doubling |
| $B(n)$ | splits of $n$ named people into unnamed groups | B(4) = 15, B(5) = 52 | — |
| $k$ | people left out of the newest person's group | 0, 1, 2 or 3 | — |
| $C(n,k)$ | ways to pick $k$ of $n$, order ignored | C(3,2) = 3 | more ways to leave people out |
| $B(0)$ | the one split of an empty crowd: no groups | 1 | every later count scales with it |

### When it holds

- **People told apart, groups not.** Two unnamed cars take the four friends 7 ways; number the cars and it is 14.
- **No empty block.** An empty car is not a group; allow one and no count exists, since another can always be added.
- **Any number of blocks.** Fix it at two and the answer drops to 7, not 15.

---

## Why it works

### Step 0: one person's company splits the count

Each of the fifteen splits answers "who rides with Dara?" once and only once. A count breaks apart along any such question and the pieces add (as [Pascal's rule](../03-Binomial%20Coefficients%20and%20Identities/01-pascals-rule-and-the-triangle.md) does with one item in or out).

### Step 1: describe the branch by who is left over

Take n + 1 people and single out one, the last to join: Dara, among the four friends. Her taxi is fixed once it is known which of the other n ride with her — equivalently, which do **not**. Call those the leftover, and write k for how many there are: the leftover is what still has to be split.

### Step 2: two free choices, and nothing else

Inside the branch "the leftover holds k people", two choices build the split.

- **Which k people are left over.** Picked from the other n, order ignored: C(n, k) ways.
- **How the leftover splits.** Whatever they do among themselves is a split of k people: B(k) ways.

The rest is forced: everyone else rides with Dara, and that car is the last block. Read backwards, Dara's car names the leftover and the other cars are its split: nothing is built twice or missed. The branch holds C(n, k) × B(k) splits.

### Step 3: add the branches

The leftover can be anyone from nobody to everybody, so k runs from 0 to n, and the branches cover every split once:

$$B(n+1) = C(n,0)\,B(0) + C(n,1)\,B(1) + \cdots + C(n,n)\,B(n).$$

For the four friends, n + 1 = 4, so n = 3, and the branches are 1 × 1, 3 × 1, 3 × 2 and 1 × 5: that is 1 + 3 + 6 + 5 = 15.

### Step 4: the floor, and then everything

With B(0) = 1 nothing else is needed: B(1) = 1, B(2) = 1 + 1 = 2, B(3) = 1 + 2 + 2 = 5, then 15, 52, 203, 877, 4140 — and the run below builds all 4,140 splits of eight people to check that last one.

<details>
<summary>Detailed proof: the branch is a one-for-one match</summary>

Number the people 1 to n + 1, the newest last. Let P be a split, D the block holding n + 1, and L the members of 1 to n outside D — the leftover. Deleting D from P leaves non-empty, non-overlapping blocks holding exactly L: a split of L. So P gives a pair, the set L and a split of it.

Backwards: take any k-member L and any split Q of it, build D from n + 1 together with everything outside L, and set D beside Q's blocks. Every person appears once, and D meets no block of Q, since those hold only members of L. The result is a split of all n + 1 people with leftover L and other blocks Q.

The two constructions undo each other, so splits with a leftover of size k match those pairs one for one: C(n, k) choices of L, B(k) splits of each. Every split holds n + 1 in one block, so it sits in one branch only, and k never passes n. Adding over k = 0 to n gives the recurrence.

</details>

A second route reaches the same numbers by addition alone. Each row starts with the last entry of the row above; every further entry is the entry to its left plus the entry above that. The rows run 1 / 1 2 / 2 3 5 / 5 7 10 15 / 15 20 27 37 52, each starting on one Bell number and ending on the next. This is A. C. Aitken's triangle of 1933, also called the Bell triangle, the name the code uses. Why it must always agree is not proved here; the run checks it to 4,140.

---

## Worked numbers, by hand

The four friends, one branch at a time.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the fifteen listed, sorted by taxis used | 1 + 7 + 6 + 1 | **15** |
| Dara rides with all three | 1 way to leave nobody out, times B(0) = 1 | 1 |
| Dara rides with two of them | 3 ways to leave one out, times B(1) = 1 | 3 |
| Dara rides with one of them | 3 ways to leave two out, times B(2) = 2 | 6 |
| Dara rides alone | 1 way to leave all three out, times B(3) = 5 | 5 |
| the four branches added | 1 + 3 + 6 + 5 | **15** |
| a fifth friend joins | 1 × 1 + 4 × 1 + 6 × 2 + 4 × 5 + 1 × 15 | **52** |

Fifteen possible ends to the evening for four friends, fifty-two for five.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Two taxis given numbers | 14, not 7 | Each split is counted once per numbering |
| Only the group sizes kept | 5, not 15 | Who rides with whom is discarded |
| B(0) taken as 0 | 0, not 15 | The recurrence has nothing to stand on |
| The recurrence run at n = 4 for B(4) | 52, not 15 | Row n builds B(n + 1), so B(4) needs n = 3 |

The code prints all four.

---

## Code, from first principles, and it actually runs

Nothing is imported. The count is reached three ways that share no arithmetic: listing every split by walking the people in one at a time, running the recurrence with C(n, k) built from Pascal's rule, and filling Aitken's triangle by addition. The wrong answers are computed too.

### Python

```python
# Set partitions and Bell numbers -- the check behind the card.  Nothing is imported.  Four
# friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names, so a split
# records only who rides with whom.  Three roads share no arithmetic: every split listed,
# the recurrence on the newest friend's taxi-mates, and the addition-only Bell triangle.
NAMES, TOP = "ABCD", 8
def splits(n):                             # road one: list every split, friend by friend
    if n == 0: return [()]
    out = []
    for rest in splits(n - 1):
        out.append(rest + ((n - 1,),))     # the newest friend takes a taxi alone
        for i in range(len(rest)): out.append(rest[:i] + (rest[i] + (n - 1,),) + rest[i + 1:])
    return out
def choose(n, k):                          # Pascal's rule written out, nothing imported
    row = [1]
    for _ in range(n): row = [1] + [row[j - 1] + row[j] for j in range(1, len(row))] + [1]
    return row[k] if 0 <= k <= n else 0
def by_recurrence(top, floor):             # road two: B(n+1) = C(n,0)B(0) + ... + C(n,n)B(n)
    B = [floor]
    for n in range(top): B.append(sum(choose(n, k) * B[k] for k in range(n + 1)))
    return B
def triangle(top):                         # road three: addition alone
    rows = [[1]]
    for _ in range(top):
        row = [rows[-1][-1]]
        for x in rows[-1]: row.append(row[-1] + x)
        rows.append(row)
    return rows
def show(s):                               # one split written out, smallest taxi first
    return "|".join("".join(NAMES[i] for i in b) for b in sorted(s, key=lambda b: (len(b), b)))
def yn(claim): return "yes" if claim else "no"
listed = [len(splits(n)) for n in range(TOP + 1)]
B = by_recurrence(TOP, 1)
dead = by_recurrence(4, 0)                 # the same recurrence with the floor set to 0
rows = triangle(TOP)
four = splits(4)
by_taxis = [sum(1 for s in four if len(s) == k) for k in range(5)]
mates = [sum(1 for s in four if 4 - len(next(b for b in s if 3 in b)) == k) for k in range(4)]
formula = [choose(3, k) * B[k] for k in range(4)]
patterns = {tuple(sorted(len(b) for b in s)) for s in four}
two_named = 2 ** 4 - 2                     # every yes-or-no labelling but the two that empty a taxi
print("four friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names")
for k, word in ((1, "one taxi   "), (2, "two taxis  "), (3, "three taxis"), (4, "four taxis ")):
    print(f"  {word} ({by_taxis[k]}): " + "  ".join(sorted(show(s) for s in four if len(s) == k)))
print(f"listed one at a time: {listed[4]} splits of four friends and {listed[5]} of five")
print(f"Dara's taxi-mates: all three -> 1 x B(0) = {formula[0]}; two of the three -> 3 x B(1) = "
      f"{formula[1]}; one of the three -> 3 x B(2) = {formula[2]}; nobody -> 1 x B(3) = {formula[3]}")
print(f"recurrence: B(4) = 1x1 + 3x1 + 3x2 + 1x5 = {B[4]};  B(5) = 1x1 + 4x1 + 6x2 + 4x5 + 1x15 = {B[5]}")
print(f"B(0) to B({TOP}) by recurrence: {B}")
print(f"the same numbers by listing every split: {yn(listed == B)}; "
      f"from the Bell triangle: {yn([r[0] for r in rows] == B)}")
print("Bell triangle, rows 0 to 4: " + " / ".join(" ".join(str(x) for x in r) for r in rows[:5]))
print(f"mistake, taxis numbered: four friends into two named taxis, neither empty = {two_named} ways, not {by_taxis[2]}")
print(f"mistake, only the group sizes kept: {len(patterns)} size patterns, not {B[4]}")
print(f"mistake, B(0) taken as 0: the recurrence gives B(1) to B(4) = {dead[1:]}, not {B[4]}")
print(f"mistake, index slipped: C(4,0)B(0) + ... + C(4,4)B(4) = {B[5]}, which is B(5), not B(4)")
assert listed == B                                    # every split listed, against the recurrence
assert [r[0] for r in rows] == B                      # addition alone, against the recurrence
assert mates == formula and by_taxis == [0, 1, 7, 6, 1]
assert two_named == 2 * by_taxis[2]                   # labellings, against the listed two-taxi splits
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
four friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names
  one taxi    (1): ABCD
  two taxis   (7): AB|CD  AC|BD  AD|BC  A|BCD  B|ACD  C|ABD  D|ABC
  three taxis (6): A|B|CD  A|C|BD  A|D|BC  B|C|AD  B|D|AC  C|D|AB
  four taxis  (1): A|B|C|D
listed one at a time: 15 splits of four friends and 52 of five
Dara's taxi-mates: all three -> 1 x B(0) = 1; two of the three -> 3 x B(1) = 3; one of the three -> 3 x B(2) = 6; nobody -> 1 x B(3) = 5
recurrence: B(4) = 1x1 + 3x1 + 3x2 + 1x5 = 15;  B(5) = 1x1 + 4x1 + 6x2 + 4x5 + 1x15 = 52
B(0) to B(8) by recurrence: [1, 1, 2, 5, 15, 52, 203, 877, 4140]
the same numbers by listing every split: yes; from the Bell triangle: yes
Bell triangle, rows 0 to 4: 1 / 1 2 / 2 3 5 / 5 7 10 15 / 15 20 27 37 52
mistake, taxis numbered: four friends into two named taxis, neither empty = 14 ways, not 7
mistake, only the group sizes kept: 5 size patterns, not 15
mistake, B(0) taken as 0: the recurrence gives B(1) to B(4) = [0, 0, 0, 0], not 15
mistake, index slipped: C(4,0)B(0) + ... + C(4,4)B(4) = 52, which is B(5), not B(4)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Set partitions and Bell numbers -- the same check as the Python, in Rust.  No crates.  Four
// friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names, so a split
// records only who rides with whom.  Three roads share no arithmetic: every split listed,
// the recurrence on the newest friend's taxi-mates, and the addition-only Bell triangle.
const NAMES: [char; 4] = ['A', 'B', 'C', 'D'];
const TOP: usize = 8;
fn splits(n: usize) -> Vec<Vec<Vec<usize>>> {    // road one: list every split, friend by friend
    if n == 0 { return vec![Vec::new()] }
    let mut out: Vec<Vec<Vec<usize>>> = Vec::new();
    for rest in splits(n - 1) {
        let mut alone = rest.clone(); alone.push(vec![n - 1]); out.push(alone);   // a taxi alone
        for i in 0..rest.len() {                 // or one of the taxis already going
            let mut joined = rest.clone(); joined[i].push(n - 1); out.push(joined);
        }
    }
    out
}
fn choose(n: usize, k: usize) -> u64 {           // Pascal's rule written out, nothing imported
    let mut row: Vec<u64> = vec![1];
    for _ in 0..n {
        let mut next: Vec<u64> = vec![1];
        for j in 1..row.len() { next.push(row[j - 1] + row[j]) }
        next.push(1); row = next;
    }
    if k <= n { row[k] } else { 0 }
}
fn by_recurrence(top: usize, floor: u64) -> Vec<u64> {  // road two: B(n+1) = C(n,0)B(0) + ...
    let mut b = vec![floor];
    for n in 0..top { let next: u64 = (0..=n).map(|k| choose(n, k) * b[k]).sum(); b.push(next) }
    b
}
fn triangle(top: usize) -> Vec<Vec<u64>> {       // road three: addition alone
    let mut rows: Vec<Vec<u64>> = vec![vec![1]];
    for _ in 0..top {
        let prev = rows[rows.len() - 1].clone(); let mut row = vec![prev[prev.len() - 1]];
        for x in &prev { row.push(row[row.len() - 1] + x) }
        rows.push(row)
    }
    rows
}
fn show(s: &Vec<Vec<usize>>) -> String {         // one split written out, smallest taxi first
    let mut blocks = s.clone();
    blocks.sort_by_key(|b| (b.len(), b.clone()));
    blocks.iter().map(|b| b.iter().map(|&i| NAMES[i]).collect::<String>()).collect::<Vec<String>>().join("|")
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let listed: Vec<u64> = (0..=TOP).map(|n| splits(n).len() as u64).collect();
    let (b, dead) = (by_recurrence(TOP, 1), by_recurrence(4, 0));   // dead: the floor set to 0
    let (rows, four) = (triangle(TOP), splits(4));
    let by_taxis: Vec<u64> = (0..5).map(|k| four.iter().filter(|s| s.len() == k).count() as u64).collect();
    let mates: Vec<u64> = (0..4).map(|k| four.iter()
        .filter(|s| 4 - s.iter().find(|t| t.contains(&3)).unwrap().len() == k).count() as u64).collect();
    let formula: Vec<u64> = (0..4).map(|k| choose(3, k) * b[k]).collect();
    let patterns: std::collections::BTreeSet<Vec<usize>> = four.iter()
        .map(|s| { let mut v: Vec<usize> = s.iter().map(|t| t.len()).collect(); v.sort(); v }).collect();
    let (two_named, tri_left) = (2u64.pow(4) - 2, rows.iter().map(|r| r[0]).collect::<Vec<u64>>());
    println!("four friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names");
    for (k, word) in [(1usize, "one taxi   "), (2, "two taxis  "), (3, "three taxis"), (4, "four taxis ")] {
        let mut cells: Vec<String> = four.iter().filter(|s| s.len() == k).map(show).collect(); cells.sort();
        println!("  {} ({}): {}", word, by_taxis[k], cells.join("  "));
    }
    println!("listed one at a time: {} splits of four friends and {} of five", listed[4], listed[5]);
    println!("Dara's taxi-mates: all three -> 1 x B(0) = {}; two of the three -> 3 x B(1) = {}; \
one of the three -> 3 x B(2) = {}; nobody -> 1 x B(3) = {}", formula[0], formula[1], formula[2], formula[3]);
    println!("recurrence: B(4) = 1x1 + 3x1 + 3x2 + 1x5 = {};  B(5) = 1x1 + 4x1 + 6x2 + 4x5 + 1x15 = {}", b[4], b[5]);
    println!("B(0) to B({}) by recurrence: {:?}", TOP, b);
    println!("the same numbers by listing every split: {}; from the Bell triangle: {}", yn(listed == b), yn(tri_left == b));
    println!("Bell triangle, rows 0 to 4: {}", rows[..5].iter()
        .map(|r| r.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(" ")).collect::<Vec<String>>().join(" / "));
    println!("mistake, taxis numbered: four friends into two named taxis, neither empty = {} ways, not {}", two_named, by_taxis[2]);
    println!("mistake, only the group sizes kept: {} size patterns, not {}", patterns.len(), b[4]);
    println!("mistake, B(0) taken as 0: the recurrence gives B(1) to B(4) = {:?}, not {}", &dead[1..], b[4]);
    println!("mistake, index slipped: C(4,0)B(0) + ... + C(4,4)B(4) = {}, which is B(5), not B(4)", b[5]);
    assert!(listed == b);                        // every split listed, against the recurrence
    assert!(tri_left == b);                      // addition alone, against the recurrence
    assert!(mates == formula && by_taxis == vec![0, 1, 7, 6, 1]);
    assert!(two_named == 2 * by_taxis[2]);       // labellings, against the listed two-taxi splits
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
four friends -- Ada, Ben, Cleo, Dara -- share taxis home; the taxis have no names
  one taxi    (1): ABCD
  two taxis   (7): AB|CD  AC|BD  AD|BC  A|BCD  B|ACD  C|ABD  D|ABC
  three taxis (6): A|B|CD  A|C|BD  A|D|BC  B|C|AD  B|D|AC  C|D|AB
  four taxis  (1): A|B|C|D
listed one at a time: 15 splits of four friends and 52 of five
Dara's taxi-mates: all three -> 1 x B(0) = 1; two of the three -> 3 x B(1) = 3; one of the three -> 3 x B(2) = 6; nobody -> 1 x B(3) = 5
recurrence: B(4) = 1x1 + 3x1 + 3x2 + 1x5 = 15;  B(5) = 1x1 + 4x1 + 6x2 + 4x5 + 1x15 = 52
B(0) to B(8) by recurrence: [1, 1, 2, 5, 15, 52, 203, 877, 4140]
the same numbers by listing every split: yes; from the Bell triangle: yes
Bell triangle, rows 0 to 4: 1 / 1 2 / 2 3 5 / 5 7 10 15 / 15 20 27 37 52
mistake, taxis numbered: four friends into two named taxis, neither empty = 14 ways, not 7
mistake, only the group sizes kept: 5 size patterns, not 15
mistake, B(0) taken as 0: the recurrence gives B(1) to B(4) = [0, 0, 0, 0], not 15
mistake, index slipped: C(4,0)B(0) + ... + C(4,4)B(4) = 52, which is B(5), not B(4)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the recurrence and its floor for every n, counting the splits themselves.

- B(n + 1) = C(n,0) B(0) + C(n,1) B(1) + ... + C(n,n) B(n), for every n.
- B(0) = 1: an empty crowd splits exactly one way.
- Any finite set of named people splits in B(n) ways, where n is how many it holds.
- B(0) to B(8) are 1, 1, 2, 5, 15, 52, 203, 877, 4140, and two numbered taxis take the four friends 14 ways.

Listing every split, Aitken's triangle, the 5 size patterns and the zero floor are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 271 lines</summary>

```lean
-- Set partitions and Bell numbers: the number B(n) of ways to split n named people into unnamed non-empty groups satisfies B(0) = 1 and B(n + 1) = C(n,0) B(0) + ... + C(n,n) B(n), equals Mathlib's Bell number for any finite set, and the card's counts 15, 52, ..., 4140 come out as it says.
import Mathlib.Order.Partition.Finpartition
import Mathlib.Combinatorics.Enumerative.Bell

section BellHelpers

open Finset

/-- The finsets of blocks that split `s`: every block inside `s`, every member of `s` in some
block, two blocks sharing a member are equal, and no block is empty. -/
noncomputable def splitBlocks {α : Type*} [DecidableEq α] (s : Finset α) : Finset (Finset (Finset α)) := by
  classical
  exact s.powerset.powerset.filter fun F =>
    (∀ x ∈ s, ∃ p ∈ F, x ∈ p) ∧ (∀ p ∈ F, ∀ q ∈ F, ∀ x, x ∈ p → x ∈ q → p = q) ∧ ∅ ∉ F

theorem mem_splitBlocks {α : Type*} [DecidableEq α] (s : Finset α) (F : Finset (Finset α)) :
    F ∈ splitBlocks s ↔ (∀ p ∈ F, p ⊆ s) ∧ (∀ x ∈ s, ∃ p ∈ F, x ∈ p) ∧
      (∀ p ∈ F, ∀ q ∈ F, ∀ x, x ∈ p → x ∈ q → p = q) ∧ ∅ ∉ F := by
  classical
  unfold splitBlocks
  simp only [mem_filter, mem_powerset]
  constructor
  · rintro ⟨h1, h2⟩
    exact ⟨fun p hp => mem_powerset.mp (h1 hp), h2⟩
  · rintro ⟨h1, h2⟩
    exact ⟨fun p hp => mem_powerset.mpr (h1 p hp), h2⟩

/-- A finpartition is the same thing as its set of blocks. -/
noncomputable def finpartitionEquivSplitBlocks {α : Type*} [DecidableEq α] (s : Finset α) :
    Finpartition s ≃ {F // F ∈ splitBlocks s} where
  toFun P := ⟨P.parts, (mem_splitBlocks s _).mpr
    ⟨fun _ hp => P.subset hp, fun _ hx => P.exists_mem hx,
     fun _ hp _ hq _ hxp hxq => P.eq_of_mem_parts hp hq hxp hxq, P.empty_notMem_parts⟩⟩
  invFun F := by
    have h := (mem_splitBlocks s F.1).mp F.2
    exact Finpartition.ofExistsUnique F.1 h.1
      (fun x hx => by
        obtain ⟨p, hp, hxp⟩ := h.2.1 x hx
        exact ⟨p, ⟨hp, hxp⟩, fun q hq => h.2.2.1 q hq.1 p hp x hq.2 hxp⟩) h.2.2.2
  left_inv P := by ext1; rfl
  right_inv F := Subtype.ext rfl

theorem card_finpartition_eq_card_splitBlocks {α : Type*} [DecidableEq α] (s : Finset α) :
    Fintype.card (Finpartition s) = #(splitBlocks s) := by
  rw [Fintype.card_congr (finpartitionEquivSplitBlocks s), Fintype.card_coe]

theorem splitBlocks_empty {α : Type*} [DecidableEq α] :
    splitBlocks (∅ : Finset α) = {∅} := by
  ext F
  rw [mem_splitBlocks, mem_singleton]
  constructor
  · rintro ⟨h1, -, -, h4⟩
    rw [Finset.eq_empty_iff_forall_notMem]
    intro p hp
    have := h1 p hp
    rw [Finset.subset_empty] at this
    exact h4 (this ▸ hp)
  · rintro rfl
    simp

/-- Blocks of `insert a s` whose block holding `a` is `insert a t`, versus blocks of `s \ t`. -/
theorem card_splitBlocks_fiber {α : Type*} [DecidableEq α] {a : α} {s t : Finset α}
    (ha : a ∉ s) (ht : t ⊆ s) :
    #((splitBlocks (insert a s)).filter (insert a t ∈ ·)) = #(splitBlocks (s \ t)) := by
  refine Finset.card_nbij' (fun F => F.erase (insert a t)) (fun G => insert (insert a t) G)
    ?_ ?_ ?_ ?_
  · intro F hF
    simp only [coe_filter, Set.mem_ofPred_eq] at hF
    obtain ⟨hF, hat⟩ := hF
    rw [mem_splitBlocks] at hF
    obtain ⟨h1, h2, h3, h4⟩ := hF
    rw [mem_coe, mem_splitBlocks]
    refine ⟨?_, ?_, ?_, ?_⟩
    · intro p hp x hx
      rw [mem_erase] at hp
      have hxs := h1 p hp.2 hx
      rw [mem_insert] at hxs
      rw [mem_sdiff]
      rcases hxs with rfl | hxs
      · exact absurd (h3 p hp.2 _ hat x hx (mem_insert_self _ _)) hp.1
      · refine ⟨hxs, fun hxt => hp.1 (h3 p hp.2 _ hat x hx (mem_insert_of_mem hxt))⟩
    · intro x hx
      rw [mem_sdiff] at hx
      obtain ⟨p, hp, hxp⟩ := h2 x (mem_insert_of_mem hx.1)
      refine ⟨p, mem_erase.mpr ⟨?_, hp⟩, hxp⟩
      rintro rfl
      rw [mem_insert] at hxp
      rcases hxp with rfl | hxp
      · exact ha hx.1
      · exact hx.2 hxp
    · intro p hp q hq x hxp hxq
      exact h3 p (mem_of_mem_erase hp) q (mem_of_mem_erase hq) x hxp hxq
    · intro h
      exact h4 (mem_of_mem_erase h)
  · intro G hG
    rw [mem_coe, mem_splitBlocks] at hG
    obtain ⟨h1, h2, h3, h4⟩ := hG
    have key : ∀ p ∈ G, ∀ x, x ∈ p → x ∉ insert a t := by
      intro p hp x hxp hx
      have := h1 p hp hxp
      rw [mem_sdiff] at this
      rw [mem_insert] at hx
      rcases hx with rfl | hx
      · exact ha this.1
      · exact this.2 hx
    simp only [coe_filter, Set.mem_ofPred_eq]
    refine ⟨?_, mem_insert_self _ _⟩
    rw [mem_splitBlocks]
    refine ⟨?_, ?_, ?_, ?_⟩
    · intro p hp
      rw [mem_insert] at hp
      rcases hp with rfl | hp
      · exact insert_subset_insert _ ht
      · intro x hx
        exact mem_insert_of_mem (mem_sdiff.mp (h1 p hp hx)).1
    · intro x hx
      by_cases hxt : x ∈ insert a t
      · exact ⟨_, mem_insert_self _ _, hxt⟩
      · rw [mem_insert] at hx
        rcases hx with rfl | hx
        · exact absurd (mem_insert_self _ _) hxt
        · have : x ∈ s \ t := mem_sdiff.mpr ⟨hx, fun h => hxt (mem_insert_of_mem h)⟩
          obtain ⟨p, hp, hxp⟩ := h2 x this
          exact ⟨p, mem_insert_of_mem hp, hxp⟩
    · intro p hp q hq x hxp hxq
      rw [mem_insert] at hp hq
      rcases hp with rfl | hp <;> rcases hq with rfl | hq
      · rfl
      · exact absurd hxp (key q hq x hxq)
      · exact absurd hxq (key p hp x hxp)
      · exact h3 p hp q hq x hxp hxq
    · intro h
      rw [mem_insert] at h
      rcases h with h | h
      · exact absurd h.symm (insert_ne_empty _ _)
      · exact h4 h
  · intro F hF
    simp only [coe_filter, Set.mem_ofPred_eq] at hF
    exact insert_erase hF.2
  · intro G hG
    rw [mem_coe, mem_splitBlocks] at hG
    apply erase_insert
    intro h
    have := hG.1 _ h (mem_insert_self a t)
    exact ha (mem_sdiff.mp this).1

theorem card_splitBlocks_insert {α : Type*} [DecidableEq α] {a : α} {s : Finset α}
    (ha : a ∉ s) :
    #(splitBlocks (insert a s)) = ∑ t ∈ s.powerset, #(splitBlocks (s \ t)) := by
  have hcover : splitBlocks (insert a s) =
      s.powerset.biUnion (fun t => (splitBlocks (insert a s)).filter (insert a t ∈ ·)) := by
    ext F
    simp only [mem_biUnion, mem_filter, mem_powerset]
    constructor
    · intro hF
      have h := (mem_splitBlocks _ F).mp hF
      obtain ⟨p, hp, hap⟩ := h.2.1 a (mem_insert_self a s)
      refine ⟨p.erase a, ?_, hF, ?_⟩
      · intro x hx
        rw [mem_erase] at hx
        have := h.1 p hp hx.2
        rw [mem_insert] at this
        exact this.resolve_left hx.1
      · rw [insert_erase hap]; exact hp
    · rintro ⟨_, _, hF, _⟩; exact hF
  rw [hcover, card_biUnion]
  · refine sum_congr rfl fun t ht => ?_
    exact card_splitBlocks_fiber ha (mem_powerset.mp ht)
  · intro t ht u hu htu
    rw [Function.onFun, disjoint_left]
    intro F hFt hFu
    rw [mem_filter] at hFt hFu
    have h := (mem_splitBlocks _ F).mp hFt.1
    have heq := h.2.2.1 _ hFt.2 _ hFu.2 a (mem_insert_self a t) (mem_insert_self a u)
    apply htu
    have hat : a ∉ t := fun h => ha (mem_powerset.mp ht h)
    have hau : a ∉ u := fun h => ha (mem_powerset.mp hu h)
    rw [← erase_insert hat, heq, erase_insert hau]

theorem card_splitBlocks_eq_bell {α : Type*} [DecidableEq α] (n : ℕ) :
    ∀ s : Finset α, #s = n → #(splitBlocks s) = Nat.bell n := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro s hs
    rcases n with _ | n
    · rw [card_eq_zero] at hs
      subst hs
      rw [splitBlocks_empty, card_singleton, Nat.bell_zero]
    · have hne : s.Nonempty := by rw [← card_pos, hs]; omega
      obtain ⟨a, ha⟩ := hne
      have hs' : #(s.erase a) = n := by rw [card_erase_of_mem ha, hs]; rfl
      rw [← insert_erase ha, card_splitBlocks_insert (notMem_erase a s)]
      have : ∀ t ∈ (s.erase a).powerset, #(splitBlocks ((s.erase a) \ t)) = Nat.bell (n - #t) := by
        intro t ht
        rw [mem_powerset] at ht
        apply ih
        · have := card_le_card ht; omega
        · rw [card_sdiff_of_subset ht, hs']
      rw [sum_congr rfl this, sum_powerset_apply_card (fun m => Nat.bell (n - m)), hs',
        Nat.bell_succ, ← Nat.range_succ_eq_Iic]
      simp only [smul_eq_mul]

#print axioms splitBlocks
#print axioms mem_splitBlocks
#print axioms finpartitionEquivSplitBlocks
#print axioms card_finpartition_eq_card_splitBlocks
#print axioms splitBlocks_empty
#print axioms card_splitBlocks_fiber
#print axioms card_splitBlocks_insert
#print axioms card_splitBlocks_eq_bell

end BellHelpers

/-- B(n): the number of set partitions of `n` named people (the members of `Fin n`). A
`Finpartition` of the whole set is a set of blocks with no names, none empty, that cover every
person without overlapping; how many blocks there are is free. -/
def setSplits (n : ℕ) : ℕ := Fintype.card (Finpartition (Finset.univ : Finset (Fin n)))

/-- B(n) agrees with Mathlib's Bell number. -/
theorem setSplits_eq_bell (n : ℕ) : setSplits n = Nat.bell n := by
  unfold setSplits
  convert (card_finpartition_eq_card_splitBlocks (Finset.univ : Finset (Fin n))).trans
    (card_splitBlocks_eq_bell _ _ rfl) using 2
  simp

#print axioms setSplits_eq_bell

/-- The card's recurrence: splitting `n + 1` named people into unnamed non-empty groups, by
choosing who is left out of the newest person's group and splitting those left out, gives
B(n + 1) = C(n,0) B(0) + C(n,1) B(1) + ... + C(n,n) B(n), for every `n`. -/
theorem set_partitions_bell_recurrence (n : ℕ) :
    setSplits (n + 1) = ∑ k ∈ Finset.range (n + 1), n.choose k * setSplits k := by
  rw [setSplits_eq_bell, Nat.bell_succ, ← Nat.range_succ_eq_Iic,
    ← Finset.sum_range_reflect]
  refine Finset.sum_congr rfl fun j hj => ?_
  rw [Finset.mem_range] at hj
  rw [setSplits_eq_bell, Nat.add_sub_cancel, Nat.choose_symm (by omega), Nat.sub_sub_self (by omega)]

/-- The floor: an empty crowd splits exactly one way, into no groups at all, so B(0) = 1. -/
theorem set_partitions_of_empty_crowd : setSplits 0 = 1 := by
  rw [setSplits_eq_bell, Nat.bell_zero]

/-- For any finite set of named people, the number of ways to split it into unnamed non-empty
groups is the Bell number of its size (Mathlib's `Nat.bell`, A000110). -/
theorem card_set_partitions_eq_bell {α : Type*} [DecidableEq α] (s : Finset α) :
    Fintype.card (Finpartition s) = Nat.bell s.card := by
  rw [card_finpartition_eq_card_splitBlocks]
  exact card_splitBlocks_eq_bell _ s rfl

-- B(0) to B(8): 1, 1, 2, 5, 15, 52, 203, 877, 4140.
example : [Nat.bell 0, Nat.bell 1, Nat.bell 2, Nat.bell 3, Nat.bell 4, Nat.bell 5, Nat.bell 6,
    Nat.bell 7, Nat.bell 8] = [1, 1, 2, 5, 15, 52, 203, 877, 4140] := by
  norm_num [Nat.bell_succ, ← Nat.range_succ_eq_Iic, Finset.sum_range_succ, Nat.choose]
-- Four friends, sorted by Dara's company: 1 x B(0) + 3 x B(1) + 3 x B(2) + 1 x B(3) = 1 + 3 + 6 + 5 = 15.
example : Nat.choose 3 0 * 1 = 1 ∧ Nat.choose 3 1 * 1 = 3 ∧ Nat.choose 3 2 * 2 = 6 ∧
    Nat.choose 3 3 * 5 = 5 ∧ 1 + 3 + 6 + 5 = 15 := by decide
-- The fifteen listed, sorted by taxis used: 1 + 7 + 6 + 1 = 15.
example : 1 + 7 + 6 + 1 = 15 := by decide
-- A fifth friend: 1 x 1 + 4 x 1 + 6 x 2 + 4 x 5 + 1 x 15 = 52.
example : Nat.choose 4 0 * 1 + Nat.choose 4 1 * 1 + Nat.choose 4 2 * 2 + Nat.choose 4 3 * 5 +
    Nat.choose 4 4 * 15 = 52 := by decide
-- Two numbered taxis, neither empty: 14 ways (2 ^ 4 - 2), twice the 7 with unnamed taxis.
example : Fintype.card {f : Fin 4 → Fin 2 // Function.Surjective f} = 14 := by decide
example : 2 ^ 4 - 2 = 14 ∧ 14 = 2 * 7 := by decide
-- The index slipped: C(4,0) B(0) + ... + C(4,4) B(4) is 52, which is B(5), not B(4) = 15.
example : Nat.choose 4 0 * 1 + Nat.choose 4 1 * 1 + Nat.choose 4 2 * 2 + Nat.choose 4 3 * 5 +
    Nat.choose 4 4 * 15 ≠ 15 := by decide

#print axioms set_partitions_bell_recurrence
#print axioms set_partitions_of_empty_crowd
#print axioms card_set_partitions_eq_bell
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'splitBlocks' depends on axioms: [propext, Classical.choice, Quot.sound]
'mem_splitBlocks' depends on axioms: [propext, Classical.choice, Quot.sound]
'finpartitionEquivSplitBlocks' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_finpartition_eq_card_splitBlocks' depends on axioms: [propext, Classical.choice, Quot.sound]
'splitBlocks_empty' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_splitBlocks_fiber' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_splitBlocks_insert' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_splitBlocks_eq_bell' depends on axioms: [propext, Classical.choice, Quot.sound]
'setSplits_eq_bell' depends on axioms: [propext, Classical.choice, Quot.sound]
'set_partitions_bell_recurrence' depends on axioms: [propext, Classical.choice, Quot.sound]
'set_partitions_of_empty_crowd' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_set_partitions_eq_bell' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts hold the three roads against each other, so a change to one road stops the program.
> - **Move the floor.** In `by_recurrence(TOP, 1)`, make the 1 a 2. Every Bell number doubles while the listing stays put, and the first assert stops it.
> - **Never let the newest friend ride alone.** Delete the line that gives them a taxi of their own: the listing then finds no split of even one person.
> - **Nudge the triangle.** Add 1 inside its addition. Its left-hand column drifts off the Bell numbers and the second assert stops it, while the other two roads still agree.

---

## The usual mistake

> [!warning]
> **Treating the groups as places rather than as company.** A block is known only by who is in it, so a split and every rearrangement of its blocks are one split. Two numbered cars take the four friends 14 ways, two unnamed cars 7: labelled containers never give a smaller answer, sorted out in [The twelvefold way](06-twelvefold-way.md).
>
> - **Reading the recurrence off by one.** C(4,0)B(0) + … + C(4,4)B(4) is 52, which is B(5), not B(4).
> - **Dropping the empty split.** B(0) = 1, not 0; set it to 0 and every Bell number is 0.
> - **Keeping the sizes and losing the names.** Four friends then give 5 size patterns, not 15 splits: the count on [Integer partitions](01-integer-partitions.md).

---

## Where you meet it in real life

- **Clustering.** Sorting readings or customers into groups, with no fixed number of groups. The Bell number is the size of the search: eight items already allow 4,140 groupings, so every clustering method is a shortcut, not a survey.
- **Rhyme schemes.** A four-line stanza's scheme splits its lines into rhyming groups — AABB, ABAB, ABBA, AAAA and the rest. Fifteen schemes, the same fifteen: the rhymes have no names and the lines do.
- **Saying which things count as the same.** Declaring an equivalence and cutting a set into blocks are one act ([Equivalence relations and partitions](../../01-Foundations/08-Relations%20and%20Functions/06-equivalence-relations-and-partitions.md)), so B(n) counts those declarations too.

> **Say it back**
> A set partition cuts named people into non-empty groups that have no names, and the number of groups is free. The Bell number B(n) counts them: 1, 1, 2, 5, 15, 52, 203 from n = 0 up. To add one more person, choose who is left out of that person's group, in C(n, k) ways, and split those left out in B(k) ways. Adding over the leftover's size gives B(n + 1), on the floor B(0) = 1. Four friends get home 15 ways; five do it 52 ways.

---

## What this builds on

- [Pascal's rule](../03-Binomial%20Coefficients%20and%20Identities/01-pascals-rule-and-the-triangle.md): C(n, k) itself, and the habit of breaking a count apart by singling out one item.
- [Equivalence relations and partitions](../../01-Foundations/08-Relations%20and%20Functions/06-equivalence-relations-and-partitions.md): what a partition is, and why its blocks cover everything without overlapping.

## Where this goes next

- [Stirling numbers of the second kind](04-stirling-numbers-second-kind.md): the same splits counted with the number of groups held fixed.

Sorted by how many taxis they use, the fifteen splits fall 1, 7, 6, 1 — and this card never says why, which is the question [Stirling numbers of the second kind](04-stirling-numbers-second-kind.md) answers.

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Olver, F. W. J., et al., eds. "§26.7 Set Partitions: Bell Numbers." *NIST Digital Library of Mathematical Functions*. [dlmf.nist.gov/26.7](https://dlmf.nist.gov/26.7). Free; equation [26.7.6](https://dlmf.nist.gov/26.7.E6) is this card's recurrence, in DLMF's B(n) notation.
- "A000110: Bell or exponential numbers." On-Line Encyclopedia of Integer Sequences. [Sequence page](https://oeis.org/A000110). Its first nine terms are the run's nine numbers.
- Aitken, A. C. "A Problem in Combinations." *Mathematical Notes* (Edinburgh Mathematical Society) 28 (1933): xviii–xxiii. [doi:10.1017/S1757748900002334](https://doi.org/10.1017/S1757748900002334). The addition-only triangle.
- O'Connor, J. J., and E. F. Robertson. "Eric Temple Bell." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Bell/). Dates *Exponential Numbers*, the 1934 paper behind the name.
