# Equivalence relations and partitions: a sameness rule cuts a set into blocks, and the blocks give the rule back

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Relations and Functions](../README.md#s08) → Equivalence relations and partitions

---

## General Overview

A day has 24 hours, numbered 0 to 23. The kitchen clock has 12 readings, taking the 12 on its face as 0: at hour 15 the dial shows 3, at hour 23 it shows 11, at hour 3 it shows 3 again.

Take this rule: two hours count as the same when the dial shows the same for both. That is a relation on the 24 hours — a set of ordered pairs, [Relations](01-relations.md) — and 48 of the 24 × 24 = 576 pairs are in it.

The rule sorts the day: 0 with 12, 1 with 13, 2 with 14, up to 11 with 23. Twelve piles of two, every hour in exactly one, none left over. A split like that is a **partition**, and each pile is a **block**.

**A rule that is reflexive, symmetric and transitive cuts a set into blocks that cover everything and never overlap, and "in the same block" is that rule handed back.**

**What kind of fact this is:** a theorem, proved on this card in Why it works.

### The picture: two hours in, one block out

```mermaid
flowchart LR
  H0["hour 0"] --> B0["{0, 12}"]
  H12["hour 12"] --> B0
  H1["hour 1"] --> B1["{1, 13}"]
  H13["hour 13"] --> B1
  H11["hour 11"] --> B11["{11, 23}"]
  H23["hour 23"] --> B11
```

Three of the twelve blocks. The rest look the same.

---

## The formula

The rule is the object:

**same reading on a 12-hour dial: hour a and hour b are linked when the dial shows the same number for both**

Here a and b are any two of the 24 hours, possibly the same. Three of the four tests from [Relations](01-relations.md) settle it:

- **Reflexive:** every hour is linked to itself.
- **Symmetric:** if a is linked to b, then b is linked to a.
- **Transitive:** if a is linked to b and b is linked to c, then a is linked to c.

Pass all three and it is an **equivalence relation**, a sameness rule. The blocks fall out:

**the 24 hours, cut into 12 blocks of 2: {0, 12}, {1, 13}, {2, 14}, ... , {11, 23}**

**Read it aloud:** a rule that passes all three tests sorts the 24 hours into 12 blocks of two, one per dial reading.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| the dial reading | the hour, minus 12 when it is 12 or more | hour 15 shows 3 |
| a sameness rule, or equivalence relation | a relation passing all three tests | same reading on a dial |
| a block, formally an equivalence class | all the rule links one thing to, itself included | the block of hour 0 is {0, 12} |
| a partition | non-empty blocks, never overlapping, covering the set | the 12 blocks, {0, 12} up to {11, 23} |

Books write a ~ b for "linked", [a] for a's block.

### When it holds

- **Reflexive.** Drop it and a member can miss its own block. "Same reading, different hour" has 24 pairs, and hour 0 is not in its own block.
- **Symmetric.** Drop it and a can sit in b's block while b sits outside a's.
- **Transitive.** Drop it and blocks overlap. "Readings at most 1 apart, no wrap" links 2 with 3 and 3 with 4, but not 2 with 4.
- **Piles that cover the set.** Every member must sit in a pile. Leave one sock on the floor and "same pile" fails reflexive: 26 pairs, no partition.

---

## Why it works

### Reflexive fills a block

The block of an hour is everything the rule links it to. Hour 0: to 12, and to itself, so {0, 12}. Reflexive is the only reason 0 is in there. Drop it and an hour sits outside its own block — no cover, no partition.

### Symmetric and transitive stop blocks overlapping

Suppose the block of a and the block of b share an hour, h. Then a is linked to h, and b to h. Symmetric turns the second round: h is linked to b. Transitive joins them: a is linked to b. Anything in a's block is linked to a, so to b, so it sits in b's block — and the same the other way. One block, two labels.

So two blocks match exactly or share nothing: cover, no overlap — a partition.

### Piles first, rule second

A sock drawer: 9 socks in 3 piles by colour, 4 black, 3 white, 2 grey. Already a partition — no pile empty, no sock in two piles, none on the floor.

Say two socks are linked when they share a pile. A sock is in its own pile, sharing reads both ways, and a chain of sharing stays in one pile because a sock has only one. Reflexive, symmetric, transitive — and the blocks come back as the piles. Rule and partition are one object described twice.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| hours in a day | 0 to 23 | 24 |
| ordered pairs to ask about | 24 × 24 | 576 |
| dial readings, so blocks | 15 shows 3, 23 shows 11 | **12** |
| linked pairs, counted by blocks | 12 × 2 × 2 | **48** |
| linked pairs in the sock drawer | 4 × 4 + 3 × 3 + 2 × 2 | **29** |

A block of 2 holds 2 × 2 = 4 linked pairs, so twelve blocks give 48 — the same 48 the code gets counting pair by pair.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| "Same reading, and not the same hour" | 24 pairs | Reflexive gone, transitive with it: hour 0 is not in its own block |
| "Readings at most 1 apart, no wrap" | 136 pairs | Transitive gone: 2 with 3, 3 with 4, not 2 with 4, blocks overlap |
| One grey sock left on the floor | 26 pairs | The piles stop covering the drawer: no partition |

---

## Code, from first principles, and it actually runs

Nothing is imported. Both rules go through the three tests straight off the definitions — one pair at a time, one triple for transitive. Their blocks are collected. Second road: the blocks hand back the rule "in the same block", checked against the original on all 576 pairs, the pairs re-counted from block sizes. Then the three broken rules.

### Python

```python
# Equivalence relations and partitions -- the check behind the card.  Nothing is imported.  "Same reading on a 12-hour dial" on the 24 hours of a day, a sock drawer sorted into piles, and three rules that break.
HOURS, SOCKS, PILES = list(range(24)), list(range(9)), [[0, 1, 2, 3], [4, 5, 6], [7, 8]]; pile = {s: i for i, p in enumerate(PILES) for s in p}
def dial(h): return h - 12 if h >= 12 else h          # what a 12-hour face shows at hour h
def tests(rule, S):                                   # straight off the definitions: pairs, and triples for transitive
    return (all(rule(a, a) for a in S), all(rule(b, a) for a in S for b in S if rule(a, b)),
            all(rule(a, c) for a in S for b in S for c in S if rule(a, b) and rule(b, c)))
def blocks(rule, S): return sorted({tuple(b for b in S if rule(a, b)) for a in S})
def linked(rule, S): return sum(1 for a in S for b in S if rule(a, b))
def yn(t): return ", ".join(f"{n} {'yes' if v else 'no'}" for n, v in zip(("reflexive", "symmetric", "transitive"), t))
def fmt(bs): return ", ".join("{" + ", ".join(str(x) for x in b) + "}" for b in bs)
same, sockrule = (lambda a, b: dial(a) == dial(b)), (lambda a, b: pile[a] == pile[b])
B, PILE_TUPLES = blocks(same, HOURS), sorted(tuple(p) for p in PILES)
inblock = lambda a, b: any(a in blk and b in blk for blk in B)      # second road: the blocks hand a rule back
loose, near, floor = (lambda a, b: same(a, b) and a != b), (lambda a, b: abs(dial(a) - dial(b)) <= 1), (lambda a, b: sockrule(a, b) and a != 8 and b != 8)
agree = all(same(a, b) == inblock(a, b) for a in HOURS for b in HOURS)
print(f"24 hours, {len(HOURS) * len(HOURS)} ordered pairs to ask about; hour 3 shows {dial(3)}, hour 15 shows {dial(15)}, hour 23 shows {dial(23)}")
print("same reading on a 12-hour dial: " + yn(tests(same, HOURS)))
print(f"{len(B)} blocks of {len(B[0])}: {fmt(B[:3])}, ... , {fmt(B[-1:])}")
print(f"linked ordered pairs: {len(B)} blocks x {len(B[0])} x {len(B[0])} = {linked(same, HOURS)}")
print(f"those blocks back to a rule, in the same block: {linked(inblock, HOURS)} pairs, agrees on all {len(HOURS) * len(HOURS)} pairs: {'yes' if agree else 'no'}")
print(f"sock drawer, {len(SOCKS)} socks in piles of 4, 3 and 2: " + yn(tests(sockrule, SOCKS)))
print(f"linked ordered pairs: 4 x 4 + 3 x 3 + 2 x 2 = {linked(sockrule, SOCKS)}")
print(f"that rule's blocks are the {len(PILES)} piles back again: {'yes' if blocks(sockrule, SOCKS) == PILE_TUPLES else 'no'}")
print(f"same reading, different hour: {linked(loose, HOURS)} pairs, " + yn(tests(loose, HOURS)) + "; hour 0 is not in its own block")
print(f"readings at most 1 apart, no wrap: {linked(near, HOURS)} pairs, " + yn(tests(near, HOURS)) + "; 2 with 3 and 3 with 4 but not 2 with 4")
print(f"a sock left on the floor: {linked(floor, SOCKS)} pairs, " + yn(tests(floor, SOCKS)) + "; that sock is in no pile")
assert tests(same, HOURS) == (True, True, True) and len(B) == 12 and B[0] == (0, 12) and B[11] == (11, 23) and linked(same, HOURS) == 48
assert agree and linked(inblock, HOURS) == sum(len(b) * len(b) for b in B) and linked(sockrule, SOCKS) == 4 * 4 + 3 * 3 + 2 * 2 and blocks(sockrule, SOCKS) == PILE_TUPLES
assert (linked(loose, HOURS), linked(near, HOURS), linked(floor, SOCKS)) == (24, 136, 26) and not loose(0, 0) and not floor(8, 8) and near(2, 3) and near(3, 4) and not near(2, 4) and (tests(loose, HOURS), tests(near, HOURS), tests(floor, SOCKS)) == ((False, True, False), (True, True, False), (False, True, True))
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
24 hours, 576 ordered pairs to ask about; hour 3 shows 3, hour 15 shows 3, hour 23 shows 11
same reading on a 12-hour dial: reflexive yes, symmetric yes, transitive yes
12 blocks of 2: {0, 12}, {1, 13}, {2, 14}, ... , {11, 23}
linked ordered pairs: 12 blocks x 2 x 2 = 48
those blocks back to a rule, in the same block: 48 pairs, agrees on all 576 pairs: yes
sock drawer, 9 socks in piles of 4, 3 and 2: reflexive yes, symmetric yes, transitive yes
linked ordered pairs: 4 x 4 + 3 x 3 + 2 x 2 = 29
that rule's blocks are the 3 piles back again: yes
same reading, different hour: 24 pairs, reflexive no, symmetric yes, transitive no; hour 0 is not in its own block
readings at most 1 apart, no wrap: 136 pairs, reflexive yes, symmetric yes, transitive no; 2 with 3 and 3 with 4 but not 2 with 4
a sock left on the floor: 26 pairs, reflexive no, symmetric yes, transitive yes; that sock is in no pile
ALL CHECKS PASS
```

### Rust

Same numbers, built with `rustc --edition 2021 -O`.

```rust
// Equivalence relations and partitions -- the same check as the Python, in Rust.  No crates.  "Same reading on a 12-hour dial" on the 24 hours of a day, a sock drawer sorted into piles, and three rules that break.
type Rule = fn(i64, i64) -> bool;
fn dial(h: i64) -> i64 { if h >= 12 { h - 12 } else { h } }        // what a 12-hour face shows at hour h
fn pile(s: i64) -> i64 { if s < 4 { 0 } else if s < 7 { 1 } else { 2 } }
fn same(a: i64, b: i64) -> bool { dial(a) == dial(b) }
fn sockrule(a: i64, b: i64) -> bool { pile(a) == pile(b) }
fn loose(a: i64, b: i64) -> bool { same(a, b) && a != b }
fn near(a: i64, b: i64) -> bool { (dial(a) - dial(b)).abs() <= 1 }
fn floor(a: i64, b: i64) -> bool { sockrule(a, b) && a != 8 && b != 8 }   // one grey sock left out of every pile
fn inblock(a: i64, b: i64) -> bool { blocks(same, &hours()).iter().any(|blk| blk.contains(&a) && blk.contains(&b)) }
fn hours() -> Vec<i64> { (0..24).collect() }   fn socks() -> Vec<i64> { (0..9).collect() }
fn tests(r: Rule, s: &[i64]) -> [bool; 3] {                        // straight off the definitions: pairs, and triples for transitive
    [s.iter().all(|&a| r(a, a)), s.iter().all(|&a| s.iter().all(|&b| !r(a, b) || r(b, a))), s.iter().all(|&a| s.iter().all(|&b| s.iter().all(|&c| !(r(a, b) && r(b, c)) || r(a, c))))]
}
fn blocks(r: Rule, s: &[i64]) -> Vec<Vec<i64>> {
    let mut out: Vec<Vec<i64>> = s.iter().map(|&a| s.iter().cloned().filter(|&b| r(a, b)).collect()).collect(); out.sort(); out.dedup(); out
}
fn linked(r: Rule, s: &[i64]) -> usize { s.iter().map(|&a| s.iter().filter(|&&b| r(a, b)).count()).sum() }
fn yn(t: [bool; 3]) -> String { ["reflexive", "symmetric", "transitive"].iter().zip(t).map(|(n, v)| format!("{} {}", n, if v { "yes" } else { "no" })).collect::<Vec<String>>().join(", ") }
fn fmt(bs: &[Vec<i64>]) -> String { bs.iter().map(|b| format!("{{{}}}", b.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))).collect::<Vec<String>>().join(", ") }
fn main() {
    let (h, s, piles) = (hours(), socks(), vec![vec![0i64, 1, 2, 3], vec![4, 5, 6], vec![7, 8]]);
    let b = blocks(same, &h);                                      // second road: those blocks hand a rule back
    let agree = h.iter().all(|&x| h.iter().all(|&y| same(x, y) == inblock(x, y)));
    println!("24 hours, {} ordered pairs to ask about; hour 3 shows {}, hour 15 shows {}, hour 23 shows {}", h.len() * h.len(), dial(3), dial(15), dial(23));
    println!("same reading on a 12-hour dial: {}", yn(tests(same, &h)));
    println!("{} blocks of {}: {}, ... , {}", b.len(), b[0].len(), fmt(&b[..3]), fmt(&b[b.len() - 1..]));
    println!("linked ordered pairs: {} blocks x {} x {} = {}", b.len(), b[0].len(), b[0].len(), linked(same, &h));
    println!("those blocks back to a rule, in the same block: {} pairs, agrees on all {} pairs: {}", linked(inblock, &h), h.len() * h.len(), if agree { "yes" } else { "no" });
    println!("sock drawer, {} socks in piles of 4, 3 and 2: {}", s.len(), yn(tests(sockrule, &s)));
    println!("linked ordered pairs: 4 x 4 + 3 x 3 + 2 x 2 = {}", linked(sockrule, &s));
    println!("that rule's blocks are the {} piles back again: {}", piles.len(), if blocks(sockrule, &s) == piles { "yes" } else { "no" });
    println!("same reading, different hour: {} pairs, {}; hour 0 is not in its own block", linked(loose, &h), yn(tests(loose, &h)));
    println!("readings at most 1 apart, no wrap: {} pairs, {}; 2 with 3 and 3 with 4 but not 2 with 4", linked(near, &h), yn(tests(near, &h)));
    println!("a sock left on the floor: {} pairs, {}; that sock is in no pile", linked(floor, &s), yn(tests(floor, &s)));
    assert!(tests(same, &h) == [true, true, true] && b.len() == 12 && b[0] == vec![0, 12] && b[11] == vec![11, 23] && linked(same, &h) == 48);
    assert!(agree && linked(inblock, &h) == b.iter().map(|x| x.len() * x.len()).sum::<usize>() && linked(sockrule, &s) == 4 * 4 + 3 * 3 + 2 * 2 && blocks(sockrule, &s) == piles);
    assert!((linked(loose, &h), linked(near, &h), linked(floor, &s)) == (24, 136, 26) && !loose(0, 0) && !floor(8, 8) && near(2, 3) && near(3, 4) && !near(2, 4) && tests(loose, &h) == [false, true, false] && tests(near, &h) == [true, true, false] && tests(floor, &s) == [false, true, true]);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
24 hours, 576 ordered pairs to ask about; hour 3 shows 3, hour 15 shows 3, hour 23 shows 11
same reading on a 12-hour dial: reflexive yes, symmetric yes, transitive yes
12 blocks of 2: {0, 12}, {1, 13}, {2, 14}, ... , {11, 23}
linked ordered pairs: 12 blocks x 2 x 2 = 48
those blocks back to a rule, in the same block: 48 pairs, agrees on all 576 pairs: yes
sock drawer, 9 socks in piles of 4, 3 and 2: reflexive yes, symmetric yes, transitive yes
linked ordered pairs: 4 x 4 + 3 x 3 + 2 x 2 = 29
that rule's blocks are the 3 piles back again: yes
same reading, different hour: 24 pairs, reflexive no, symmetric yes, transitive no; hour 0 is not in its own block
readings at most 1 apart, no wrap: 136 pairs, reflexive yes, symmetric yes, transitive no; 2 with 3 and 3 with 4 but not 2 with 4
a sock left on the floor: 26 pairs, reflexive no, symmetric yes, transitive yes; that sock is in no pile
ALL CHECKS PASS
```

The two outputs match line for line: all counting.

### Lean

Lean proves the theorem for every set and every sameness rule, not just the clock and the sock drawer.

- A rule that is reflexive, symmetric and transitive cuts the set into a partition. "In the same block" is that rule handed back.
- If two blocks share a member, they are the same block. Symmetric and transitive are all this needs.
- Piles that form a partition give a sameness rule, "in the same pile". Its blocks are the piles again.
- The card's counts come out as it says: 576 pairs, 48 linked, 12 blocks, 29 sock pairs, and 24, 136 and 26 for the broken rules.

The yes-or-no runs of the three tests, pair by pair on each rule, are left to the Python and Rust checks.

```lean
-- Equivalence relations and partitions: a reflexive, symmetric and transitive rule cuts any set into non-empty blocks that cover it and never overlap, "in the same block" gives the rule back, a partition gives a sameness rule whose blocks are the piles, and the card's clock and sock counts come out as it says.
import Mathlib.Order.Setoid.Partition
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Finset.Image

/-- The block of `a` under a rule `r`: everything the rule links `a` to. -/
def block {α : Type*} (r : α → α → Prop) (a : α) : Set α := {b | r a b}

/-- All the blocks of a rule `r`, one for each member (two members may share one block). -/
def blocks {α : Type*} (r : α → α → Prop) : Set (Set α) := Set.range (block r)

/-- "In the same pile": the rule a collection of piles `c` hands back. -/
def samePile {α : Type*} (c : Set (Set α)) (a b : α) : Prop := ∃ B ∈ c, a ∈ B ∧ b ∈ B

/-- A rule that is reflexive, symmetric and transitive cuts the set into blocks that form a
partition: no block is empty, and every member sits in exactly one block. And "in the same
block" is that rule handed back: `a` is linked to `b` exactly when some block holds both. -/
theorem equivalence_relation_cuts_set_into_partition {α : Type*} (r : α → α → Prop)
    (hrefl : ∀ a, r a a) (hsymm : ∀ a b, r a b → r b a)
    (htrans : ∀ a b c, r a b → r b c → r a c) :
    Setoid.IsPartition (blocks r) ∧ ∀ a b, r a b ↔ samePile (blocks r) a b := by
  have key : ∀ a b, r a b ↔ samePile (blocks r) a b := by
    intro a b
    constructor
    · intro h
      exact ⟨block r a, ⟨a, rfl⟩, hrefl a, h⟩
    · rintro ⟨B, ⟨c, rfl⟩, ha, hb⟩
      exact htrans _ _ _ (hsymm _ _ ha) hb
  refine ⟨⟨?_, ?_⟩, key⟩
  · rintro ⟨a, ha⟩
    have h1 : a ∈ block r a := hrefl a
    rw [ha] at h1
    exact h1
  · intro a
    refine ⟨block r a, ⟨⟨a, rfl⟩, hrefl a⟩, ?_⟩
    rintro B ⟨⟨c, rfl⟩, hB⟩
    have hB' : r c a := hB
    ext x
    constructor
    · intro hx
      exact htrans _ _ _ (hsymm _ _ hB') hx
    · intro hx
      exact htrans _ _ _ hB' hx

/-- Symmetric and transitive stop blocks overlapping: if the block of `a` and the block of `b`
share a member `h`, they are the same block. -/
theorem blocks_that_share_a_member_are_equal {α : Type*} (r : α → α → Prop)
    (hsymm : ∀ a b, r a b → r b a) (htrans : ∀ a b c, r a b → r b c → r a c) {a b h : α}
    (ha : h ∈ block r a) (hb : h ∈ block r b) : block r a = block r b := by
  ext x
  simp only [block, Set.mem_setOf_eq] at *
  constructor
  · intro hax
    exact htrans _ _ _ (htrans _ _ _ hb (hsymm _ _ ha)) hax
  · intro hbx
    exact htrans _ _ _ (htrans _ _ _ ha (hsymm _ _ hb)) hbx

/-- Piles first, rule second: for piles that form a partition (none empty, every member in
exactly one pile), "in the same pile" is reflexive, symmetric and transitive, and its blocks
are exactly the piles again. -/
theorem partition_gives_equivalence_relation_with_piles_as_blocks {α : Type*}
    (c : Set (Set α)) (hc : Setoid.IsPartition c) :
    (∀ a, samePile c a a) ∧ (∀ a b, samePile c a b → samePile c b a) ∧
      (∀ a b d, samePile c a b → samePile c b d → samePile c a d) ∧
      blocks (samePile c) = c := by
  obtain ⟨hne, hu⟩ := hc
  have hblock : ∀ a B, B ∈ c → a ∈ B → block (samePile c) a = B := by
    intro a B hB ha
    ext x
    constructor
    · rintro ⟨B', hB', ha', hx⟩
      have : B' = B := (hu a).unique ⟨hB', ha'⟩ ⟨hB, ha⟩
      subst this
      exact hx
    · intro hx
      exact ⟨B, hB, ha, hx⟩
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro a
    obtain ⟨B, ⟨hB, ha⟩, _⟩ := hu a
    exact ⟨B, hB, ha, ha⟩
  · rintro a b ⟨B, hB, ha, hb⟩
    exact ⟨B, hB, hb, ha⟩
  · rintro a b d ⟨B, hB, ha, hb⟩ ⟨B', hB', hb', hd⟩
    have : B' = B := (hu b).unique ⟨hB', hb'⟩ ⟨hB, hb⟩
    subst this
    exact ⟨B', hB', ha, hd⟩
  · ext S
    constructor
    · rintro ⟨a, rfl⟩
      obtain ⟨B, ⟨hB, ha⟩, _⟩ := hu a
      rw [hblock a B hB ha]
      exact hB
    · intro hS
      have hn : S.Nonempty := Set.nonempty_iff_ne_empty.2 fun h => hne (h ▸ hS)
      obtain ⟨a, ha⟩ := hn
      exact ⟨a, hblock a S hS ha⟩

/-- What a 12-hour face shows at hour `h` of the day. -/
def dial (h : ℕ) : ℕ := if 12 ≤ h then h - 12 else h

/-- Which pile sock `s` is in: socks 0 to 3 black, 4 to 6 white, 7 and 8 grey. -/
def pile (s : ℕ) : ℕ := if s < 4 then 0 else if s < 7 then 1 else 2

/-- The 24 hours of the day, and all 576 ordered pairs of them. -/
def hours : Finset ℕ := Finset.range 24
def hourPairs : Finset (ℕ × ℕ) := hours ×ˢ hours
/-- The 9 socks, and all 81 ordered pairs of them. -/
def socks : Finset ℕ := Finset.range 9
def sockPairs : Finset (ℕ × ℕ) := socks ×ˢ socks

-- The dial readings the card quotes.
example : dial 3 = 3 ∧ dial 15 = 3 ∧ dial 23 = 11 := by decide
-- 24 hours give 24 × 24 = 576 ordered pairs to ask about.
set_option maxRecDepth 4000 in
example : hourPairs.card = 576 := by decide
-- "Same reading on a 12-hour dial" links 48 of them: 12 blocks × 2 × 2.
set_option maxRecDepth 4000 in
example : (hourPairs.filter fun p => dial p.1 = dial p.2).card = 48 := by decide
example : 12 * 2 * 2 = 48 := by decide
-- The rule cuts the 24 hours into 12 blocks; hour 0's block is {0, 12}, hour 11's is {11, 23}.
example : (hours.image fun a => hours.filter fun b => dial a = dial b).card = 12 := by decide
example : hours.filter (fun b => dial 0 = dial b) = {0, 12} := by decide
example : hours.filter (fun b => dial 11 = dial b) = {11, 23} := by decide
-- The sock drawer: "same pile" links 4 × 4 + 3 × 3 + 2 × 2 = 29 ordered pairs.
example : (sockPairs.filter fun p => pile p.1 = pile p.2).card = 29 := by decide
example : 4 * 4 + 3 * 3 + 2 * 2 = 29 := by decide
-- That rule's blocks are the three piles back again.
example : (socks.image fun a => socks.filter fun b => pile a = pile b) =
    {{0, 1, 2, 3}, {4, 5, 6}, {7, 8}} := by decide
-- Broken rule 1, "same reading, and not the same hour": 24 pairs, and hour 0 is not in its own
-- block, though 0 links to 12 and 12 back to 0.
set_option maxRecDepth 4000 in
example : (hourPairs.filter fun p => dial p.1 = dial p.2 ∧ p.1 ≠ p.2).card = 24 := by decide
example : ¬ (dial 0 = dial 0 ∧ (0 : ℕ) ≠ 0) ∧ (dial 0 = dial 12 ∧ (0 : ℕ) ≠ 12) ∧
    (dial 12 = dial 0 ∧ (12 : ℕ) ≠ 0) := by decide
-- Broken rule 2, "readings at most 1 apart, no wrap": 136 pairs; 2 with 3 and 3 with 4, not 2 with 4.
set_option maxRecDepth 4000 in
example : (hourPairs.filter fun p => dial p.1 ≤ dial p.2 + 1 ∧ dial p.2 ≤ dial p.1 + 1).card = 136 := by
  decide
example : (dial 2 ≤ dial 3 + 1 ∧ dial 3 ≤ dial 2 + 1) ∧ (dial 3 ≤ dial 4 + 1 ∧ dial 4 ≤ dial 3 + 1) ∧
    ¬ (dial 2 ≤ dial 4 + 1 ∧ dial 4 ≤ dial 2 + 1) := by decide
-- Broken rule 3, one grey sock (sock 8) left on the floor: 26 pairs, and sock 8 is in no pile.
example : (sockPairs.filter fun p => pile p.1 = pile p.2 ∧ p.1 ≠ 8 ∧ p.2 ≠ 8).card = 26 := by decide
example : ¬ (pile 8 = pile 8 ∧ (8 : ℕ) ≠ 8 ∧ (8 : ℕ) ≠ 8) := by decide

#print axioms equivalence_relation_cuts_set_into_partition
#print axioms blocks_that_share_a_member_are_equal
#print axioms partition_gives_equivalence_relation_with_piles_as_blocks
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'equivalence_relation_cuts_set_into_partition' depends on axioms: [propext, Quot.sound]
'blocks_that_share_a_member_are_equal' depends on axioms: [propext, Quot.sound]
'partition_gives_equivalence_relation_with_piles_as_blocks' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. One assert will fire.
> - **Put a 24-hour face on the clock.** The dial shows the hour itself: 24 blocks of one, 24 linked pairs, sameness collapsed into equality.
> - **Move a sock.** Make the piles 4, 4 and 1: linked pairs go to 33 and the assert pinned to 29 fires.

---

## The usual mistake

> [!warning]
> **Treating the blocks as something you choose afterwards.** Once a rule passes the three tests the blocks are decided, one per dial reading — and the blocks decide the rule right back. Grab either end and you hold both.
>
> - Checking symmetric and transitive, forgetting reflexive. "Same reading, and not the same hour" is symmetric and nothing more: hour 0 falls out of its own block, and transitive falls too — 0 links to 12, 12 back to 0, but not 0 to 0.
> - Reading transitive as "everything is linked to everything". It only says a chain has a shortcut: hour 3 stays linked to 15 and itself, nothing more.

---

## Where you meet it in real life

- **Group by.** A pivot table, or GROUP BY in SQL, drops rows into piles by one column: "same value there" is the rule, the piles its blocks.
- **Clock arithmetic.** Any number in place of 12, and the blocks get names and an arithmetic of their own: [Residue classes](../../02-Number%20theory/03-Clock%20Arithmetic/03-residue-classes.md).
- **Sorting anything.** Recycling bins, laundry, a deck split by suit: every item in one place.

> **Say it back**
> A rule is a sameness rule when everything is linked to itself, links work both ways, and every chain has a shortcut. "Same reading on a 12-hour dial" passes all three and cuts the 24 hours into 12 blocks of two, {0, 12} up to {11, 23}. Reflexive puts each hour in a block; symmetric and transitive stop blocks overlapping. Backwards: socks in piles are a partition, and "in the same pile" is the rule those piles hand back.

---

## What this builds on

- [Relations](01-relations.md): a relation as the set of ordered pairs where a link holds, and three of its four tests.
- [Set operations](../07-Sets/03-set-operations.md): overlap and cover, all a partition asks about.

## Where this goes next

- [Orders](07-partial-and-total-orders.md): swap symmetric for antisymmetric and the same kind of list becomes a ranking, not piles.
- [Residue classes](../../02-Number%20theory/03-Clock%20Arithmetic/03-residue-classes.md): each block collapsed to one new thing — the quotient — that you can add and multiply.

Left open: when blocks are added, does the answer depend on which member names each block?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Hammack, Richard. *Book of Proof*, 3rd ed., 2018. [Book page](https://richardhammack.github.io/BookOfProof/). Chapter 11 proves the classes partition the set.
- Halmos, Paul R. *Naive Set Theory*. Springer, 1974. [doi:10.1007/978-1-4757-1645-0](https://doi.org/10.1007/978-1-4757-1645-0). Section 7 builds it from ordered pairs alone.
- Enderton, Herbert B. *Elements of Set Theory*. Academic Press, 1977. [Publisher page](https://shop.elsevier.com/books/elements-of-set-theory/enderton/978-0-12-238440-0). Chapter 3 runs it both ways.
