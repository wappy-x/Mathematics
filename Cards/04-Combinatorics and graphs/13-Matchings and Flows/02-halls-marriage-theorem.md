# Hall's theorem: everyone on the left can be matched exactly when no group of them shares too few options

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Matchings and Flows](../README.md#s13) → Hall's theorem

---

## General Overview

A small hotel is hiring. Six applicants, Ana, Ben, Cleo, Dev, Eve and Fay, and six posts: front desk, kitchen, laundry, bar, maintenance, accounts. Each applicant is qualified for some posts. One person per post, one post per person. Can all six be placed?

Everyone qualifies for something, yet it cannot be done. Ana, Ben and Cleo are qualified only for front desk and accounts: three people, two posts. One of them is always left out. Five placements is the ceiling.

Philip Hall proved in 1935 that crowding is the only thing that can go wrong. If no group is squeezed into fewer posts than it has members, a full placement exists, and the proof builds one.

**A full placement exists exactly when every group of applicants is between them qualified for at least as many posts as the group has members.**

**What kind of fact this is:** a theorem, proved on this card in Why it works.

### The picture: where the hiring jams

```mermaid
flowchart LR
    Ana --- desk["front desk"]
    Ana --- acc["accounts"]
    Ben --- desk
    Ben --- acc
    Cleo --- acc
    Dev --- kit["kitchen"]
    Dev --- lau["laundry"]
    Dev --- bar["bar"]
    Eve --- lau
    Eve --- main["maintenance"]
    Fay --- bar
    Fay --- main
    Fay --- kit
```

Applicants on the left, posts on the right, one line per qualification: 13 lines. Ana, Ben and Cleo touch two posts between them; Dev, Eve and Fay reach four. One crowded group stops the whole placement.

---

## The formula

The hiring is a **bipartite graph**: dots in two groups, every line running across, none inside a group ([Matchings](01-matchings-and-augmenting-paths.md)). Call it $G$, the applicants $A$, the posts $B$. A **matching** is a set of lines, no two sharing an applicant or a post. It **covers** $A$ when every applicant is on one of its lines: a full placement.

Write $S$ for any group of applicants and $N(S)$ for the posts it reaches, every post at least one member is qualified for ($N$ for neighbours). Bars count members: $\lvert S\rvert$ applicants, $\lvert N(S)\rvert$ posts.

$$\lvert N(S)\rvert \;\ge\; \lvert S\rvert \qquad \text{for every group } S \text{ of applicants}$$

**Read it aloud:** no group of applicants is qualified, between them, for fewer posts than the group has members.

That is **Hall's condition**. The theorem: a matching covering $A$ exists exactly when it holds.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $G$ | the bipartite graph | 6 applicants, 6 posts, 13 lines | more lines, more room |
| $A$ | the side to be covered | the six applicants | more ways to crowd |
| $B$ | the other side | the six posts | easier to place |
| $S$, $T$ | any group of applicants; $\lvert S\rvert$ counts its members | Ana, Ben, Cleo, so 3 | — |
| $N(S)$ | the posts that group reaches; $\lvert N(S)\rvert$ counts them | front desk and accounts, so 2 | — |
| $a$, $b$ | one applicant and one post she qualifies for | Cleo, accounts | — |
| $\nu(G)$ | the largest matching's size, read "nu of G" | 5 before the repair, 6 after | — |
| $d$ | the defect: the worst group's members minus its posts | 1 before the repair, 0 after | fewer placed |

One helper formula. The **defect** is the worst crowding: the most by which any group, the empty one included, outnumbers its posts. It is never below 0.

$$\nu(G) \;=\; \lvert A\rvert - \max_S \bigl(\lvert S\rvert - \lvert N(S)\rvert\bigr)$$

**Read it aloud:** the most applicants that can be placed is all of them minus the worst crowding. The hotel's defect is 1, so 5 can start. Hall's condition is defect 0.

### When it holds

- **Finitely many applicants.** The induction must reach the bottom. With infinitely many, the condition can hold and placement still fail: one applicant qualified for posts 1, 2, 3, …, and applicant 1 for post 1 alone, applicant 2 for post 2 alone, and so on.
- **Two sides, lines only across.** If lines may join two applicants, the condition is not enough; a different test (Tutte's) takes over.
- **One side covered, not both.** With more posts than applicants, some posts stay empty.
- **Existence, not a best choice.** Whether anyone would swap, and what a placement costs, are separate questions ([Stable matching](04-stable-matching-gale-shapley.md), [The assignment problem](../../14-Applied%20and%20computational/05-Operations%20Research/05-assignment-and-the-hungarian-algorithm.md)).

---

## Why it works

### Step 0: one obstruction is obvious, and the theorem says it is the only one

A crowded group plainly blocks a placement. What needs proving is that nothing else can: no subtler tangle, no unlucky order of hiring. The proof builds a placement from the condition alone.

### Step 1: any full placement forces the condition

Take a full placement and any group $S$. Its members hold $\lvert S\rvert$ different posts, since no post is shared, and each of those posts is one its holder is qualified for, so each lies in $N(S)$. Hence $\lvert N(S)\rvert \ge \lvert S\rvert$.

So Ana, Ben and Cleo, reaching two posts, prove without any search that the hotel cannot place all six.

### Step 2: the condition is enough, by working down to a smaller hiring

The other direction is an induction on the number of applicants ([Strong induction and the least element](../../01-Foundations/06-Proof/05-strong-induction-and-well-ordering.md)): assume the theorem for every hiring with fewer applicants. With no applicants there is nothing to place.

Call a group **tight** when it reaches exactly as many posts as it has members, as Ana and Ben do. Two cases.

**Case 1, room to spare everywhere.** Every non-empty group short of all of $A$ reaches more posts than it has members. Place any applicant $a$ in any post $b$ she is qualified for, and delete both. Each remaining group loses at most that one post, and it had one to spare. The condition survives, and the induction places the rest.

**Case 2, some tight group.** Let $S$ be tight, neither empty nor all of $A$. A group inside $S$ reaches the same posts as before, so the condition holds for $S$ alone, and the induction places $S$ into all of $N(S)$. Delete $S$ and $N(S)$, and take any group $T$ of the applicants left. The induction places them too, once $T$ still reaches at least $\lvert T\rvert$ posts.

<details>
<summary>Detailed proof of the last step</summary>

Every post reached by $S$ or $T$ in the original hiring lies either in $N(S)$ or among the posts $T$ reaches after the deletion, and those two sets share nothing. So $\lvert N(S)\rvert$ plus $T$'s new reach is at least $\lvert N(S \cup T)\rvert$, which is at least $\lvert S\rvert + \lvert T\rvert$ by Hall's condition on the group $S \cup T$ (the members of $S$ and of $T$ together). Cancelling $\lvert N(S)\rvert = \lvert S\rvert$ leaves $T$'s new reach at least $\lvert T\rvert$. Together the two placements cover $A$.

</details>

### Step 3: when it fails, the worst group counts who is left out

Say the worst group beats its reach by $d$, the defect. At least $d$ applicants go unplaced, since that group has $d$ more members than posts. The count is exact: add $d$ spare posts everyone is qualified for. Every non-empty group's reach grows by $d$, so everyone is placed; at most $d$ sit in spare posts, so at least $\lvert A\rvert - d$ hold real ones. The bounds meet: at the hotel, 5 exactly.

Another road: treat the hiring as a network with a pipe along every line. A full placement is a flow of $\lvert A\rvert$ units, and a crowded group is a cheap place to cut the network: [Max-flow min-cut](06-max-flow-min-cut.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the qualification lines | Ana 2, Ben 2, Cleo 1, Dev 3, Eve 2, Fay 3 | 13 |
| groups to check | each applicant in or out: 2 × 2 × 2 × 2 × 2 × 2 | 64 |
| the group Ana, Ben, Cleo | posts reached: front desk, accounts | 2 |
| its gap | 3 members − 2 posts | **1** |
| largest placement | 6 applicants − gap 1 | **5** |
| Cleo trains on the laundry: one new line | that group now reaches front desk, accounts, laundry | 3 |
| worst gap after the repair | the largest gap over all 64 groups | **0** |
| full placements after the repair | counted one at a time | **4** |

Five start and one cannot; one extra qualification gives a full staff, four different ways.

### The picture: one line repairs it

```mermaid
flowchart LR
    Ana --- desk["front desk"]
    Ana --- acc["accounts"]
    Ben --- desk
    Ben --- acc
    Cleo --- acc
    Cleo --- lau["laundry"]
```

The crowded corner after Cleo's laundry training: three applicants, three posts. The other three keep their lines.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Checking applicants one at a time | 6 of 6 pass, yet only 5 are placed | Nobody is stuck alone; the trio is stuck together |
| Counting the trio's lines, not the posts they reach | 5 lines for 3 members, so it looks comfortable | Ana's two lines and Ben's two land on the same two posts |
| Deleting the accounts post after the repair | 5 placed, gap back to 1 | Ana and Ben are squeezed onto front desk alone |

---

## Code, from first principles, and it actually runs

Nothing is imported. Both hirings are settled three ways that share no arithmetic: Hall's condition on all 64 groups; an augmenting-path search that never mentions Hall; and a census of complete placements. A third hiring, the repaired one minus accounts, tests the defect count.

An augmenting path runs from an unplaced applicant to an empty post, switching between unused and used lines. Swapping which of its lines are used places one more applicant ([Matchings](01-matchings-and-augmenting-paths.md)).

### Python

```python
# Hall's theorem -- the check behind the card.  Nothing is imported.  Six
# applicants and six jobs at a small hotel; a line joins an applicant to a job
# she is qualified for.  Three roads: Hall's condition over all 64 groups, an
# augmenting-path search that never mentions Hall, and a census of placements.
JOBS = ["front desk", "kitchen", "laundry", "bar", "maintenance", "accounts"]
NAMES = ["Ana", "Ben", "Cleo", "Dev", "Eve", "Fay"]
BLOCKED = [[0, 5], [0, 5], [5], [1, 2, 3], [2, 4], [3, 4, 1]]
REPAIRED = [[0, 5], [0, 5], [5, 2], [1, 2, 3], [2, 4], [3, 4, 1]]
NO_ACCOUNTS = [[j for j in a if j != 5] for a in REPAIRED]

def worst_gap(adj):                        # road one: Hall's count on every group
    gap, who = 0, ()
    for mask in range(1 << len(adj)):
        group = tuple(i for i in range(len(adj)) if mask >> i & 1)
        short = len(group) - len({j for i in group for j in adj[i]})
        if short > gap: gap, who = short, group
    return gap, who

def augment(adj, i, taken, seen):          # road two: the alternating-path search
    for j in adj[i]:
        if not seen[j]:
            seen[j] = True
            if taken[j] < 0 or augment(adj, taken[j], taken, seen):
                taken[j] = i
                return True
    return False

def hold(adj):                             # which applicant holds each job, -1 none
    taken = [-1] * len(JOBS)
    for i in range(len(adj)): augment(adj, i, taken, [False] * len(JOBS))
    return taken

def census(adj, i=0, used=()):             # road three: count complete placements
    if i == len(adj): return 1
    return sum(census(adj, i + 1, used + (j,)) for j in adj[i] if j not in used)
def size(taken): return sum(1 for i in taken if i >= 0)    # jobs that ended up filled

n, (gap_b, trio) = len(NAMES), worst_gap(BLOCKED)
gap_r, gap_c = worst_gap(REPAIRED)[0], worst_gap(NO_ACCOUNTS)[0]
held_b, held_r, held_c = hold(BLOCKED), hold(REPAIRED), hold(NO_ACCOUNTS)
full_b, full_r = census(BLOCKED), census(REPAIRED)
left_out = ", ".join(NAMES[i] for i in range(n) if i not in held_b)
trio_names, trio_lines = ", ".join(NAMES[i] for i in trio), sum(len(BLOCKED[i]) for i in trio)
trio_reach, singles = len({j for i in trio for j in BLOCKED[i]}), sum(1 for a in BLOCKED if a)
pairs = " ".join(f"{NAMES[i]}-{JOBS[j]}" for j, i in sorted(enumerate(held_r), key=lambda p: p[1]))
print(f"applicants {n}, jobs {len(JOBS)}; qualification lines: blocked {sum(len(a) for a in BLOCKED)}, repaired {sum(len(a) for a in REPAIRED)}")
print(f"blocked : worst group of all {1 << n} is {trio_names} -- {len(trio)} applicants, {trio_reach} jobs, gap {gap_b}")
print(f"blocked : augmenting paths place {size(held_b)}; Hall's count {n} - {gap_b} = {n - gap_b}; left out {left_out}")
print(f"repaired: worst gap over all {1 << n} groups is {gap_r}")
print(f"repaired: augmenting paths place {size(held_r)}; Hall's count {n} - {gap_r} = {n - gap_r}")
print(f"repaired: {pairs}")
print(f"complete placements by census: blocked {full_b}, repaired {full_r}")
print(f"mistake 1, one applicant at a time: {singles} of {n} applicants pass, yet only {size(held_b)} are placed")
print(f"mistake 2, the trio's lines counted, not the jobs they reach: {trio_lines} lines, {trio_reach} jobs")
print(f"mistake 3, accounts post deleted from the repaired graph: gap {gap_c}, {size(held_c)} placed")
assert size(held_b) == n - gap_b and size(held_r) == n - gap_r
assert (full_b > 0) == (size(held_b) == n) and (full_r > 0) == (size(held_r) == n)
assert full_r == 4 and size(held_c) == n - gap_c
assert trio == (0, 1, 2) and trio_reach == 2 and singles == n
print("ALL CHECKS PASS")
```

**Ran 2026-09-23 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
applicants 6, jobs 6; qualification lines: blocked 13, repaired 14
blocked : worst group of all 64 is Ana, Ben, Cleo -- 3 applicants, 2 jobs, gap 1
blocked : augmenting paths place 5; Hall's count 6 - 1 = 5; left out Cleo
repaired: worst gap over all 64 groups is 0
repaired: augmenting paths place 6; Hall's count 6 - 0 = 6
repaired: Ana-accounts Ben-front desk Cleo-laundry Dev-kitchen Eve-maintenance Fay-bar
complete placements by census: blocked 0, repaired 4
mistake 1, one applicant at a time: 6 of 6 applicants pass, yet only 5 are placed
mistake 2, the trio's lines counted, not the jobs they reach: 5 lines, 2 jobs
mistake 3, accounts post deleted from the repaired graph: gap 1, 5 placed
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`. Groups and filled posts are kept as bits.

```rust
// Hall's theorem -- the same check as halls_marriage_theorem_check.py, in Rust.
// No crates.  Six applicants and six jobs at a small hotel; a line joins an
// applicant to a job she is qualified for.  Three roads: Hall's condition over
// all 64 groups, an augmenting-path search that never mentions Hall, and a
// census of placements.  Groups and used jobs are kept as bits here.
const JOBS: [&str; 6] = ["front desk", "kitchen", "laundry", "bar", "maintenance", "accounts"];
const NAMES: [&str; 6] = ["Ana", "Ben", "Cleo", "Dev", "Eve", "Fay"];

fn worst_gap(adj: &[Vec<usize>]) -> (i32, Vec<usize>) {   // road one: Hall's count
    let (mut gap, mut who) = (0i32, Vec::new());
    for mask in 0..(1u32 << adj.len()) {
        let group: Vec<usize> = (0..adj.len()).filter(|i| mask >> i & 1 == 1).collect();
        let mut reach = 0u32;
        for &i in &group { for &j in &adj[i] { reach |= 1 << j } }
        let short = group.len() as i32 - reach.count_ones() as i32;
        if short > gap { gap = short; who = group }
    }
    (gap, who)
}
fn augment(adj: &[Vec<usize>], i: usize, taken: &mut [i32], seen: &mut [bool]) -> bool {
    for &j in &adj[i] {                                  // road two: alternating paths
        if !seen[j] {
            seen[j] = true;
            if taken[j] < 0 || augment(adj, taken[j] as usize, taken, seen) {
                taken[j] = i as i32;
                return true;
            }
        }
    }
    false
}
fn hold(adj: &[Vec<usize>]) -> Vec<i32> {                // who holds each job, -1 none
    let mut taken = vec![-1i32; JOBS.len()];
    for i in 0..adj.len() { augment(adj, i, &mut taken, &mut vec![false; JOBS.len()]); }
    taken
}
fn census(adj: &[Vec<usize>], i: usize, used: u32) -> u64 {   // road three: placements
    if i == adj.len() { return 1 }
    let mut total = 0;
    for &j in &adj[i] { if used >> j & 1 == 0 { total += census(adj, i + 1, used | 1 << j) } }
    total
}
fn size(taken: &[i32]) -> usize { taken.iter().filter(|&&i| i >= 0).count() }
fn lines(adj: &[Vec<usize>]) -> usize { adj.iter().map(|a| a.len()).sum() }

fn main() {
    let blocked: Vec<Vec<usize>> = vec![vec![0, 5], vec![0, 5], vec![5], vec![1, 2, 3], vec![2, 4], vec![3, 4, 1]];
    let repaired: Vec<Vec<usize>> = vec![vec![0, 5], vec![0, 5], vec![5, 2], vec![1, 2, 3], vec![2, 4], vec![3, 4, 1]];
    let no_accounts: Vec<Vec<usize>> = repaired.iter().map(|a| a.iter().copied().filter(|&j| j != 5).collect()).collect();
    let n = NAMES.len();
    let (gap_b, trio) = worst_gap(&blocked);
    let (gap_r, gap_c) = (worst_gap(&repaired).0, worst_gap(&no_accounts).0);
    let (held_b, held_r, held_c) = (hold(&blocked), hold(&repaired), hold(&no_accounts));
    let (full_b, full_r) = (census(&blocked, 0, 0), census(&repaired, 0, 0));
    let left_out: Vec<&str> = (0..n).filter(|i| !held_b.contains(&(*i as i32))).map(|i| NAMES[i]).collect();
    let trio_names: Vec<&str> = trio.iter().map(|&i| NAMES[i]).collect();
    let trio_lines: usize = trio.iter().map(|&i| blocked[i].len()).sum();
    let mut reach = 0u32;
    for &i in &trio { for &j in &blocked[i] { reach |= 1 << j } }
    let (trio_reach, singles) = (reach.count_ones(), blocked.iter().filter(|a| !a.is_empty()).count());
    let mut order: Vec<(usize, i32)> = held_r.iter().copied().enumerate().collect();
    order.sort_by_key(|p| p.1);
    let pairs: Vec<String> = order.iter().map(|&(j, i)| format!("{}-{}", NAMES[i as usize], JOBS[j])).collect();
    println!("applicants {}, jobs {}; qualification lines: blocked {}, repaired {}", n, JOBS.len(), lines(&blocked), lines(&repaired));
    println!("blocked : worst group of all {} is {} -- {} applicants, {} jobs, gap {}", 1 << n, trio_names.join(", "), trio.len(), trio_reach, gap_b);
    println!("blocked : augmenting paths place {}; Hall's count {} - {} = {}; left out {}", size(&held_b), n, gap_b, n as i32 - gap_b, left_out.join(", "));
    println!("repaired: worst gap over all {} groups is {}", 1 << n, gap_r);
    println!("repaired: augmenting paths place {}; Hall's count {} - {} = {}", size(&held_r), n, gap_r, n as i32 - gap_r);
    println!("repaired: {}", pairs.join(" "));
    println!("complete placements by census: blocked {}, repaired {}", full_b, full_r);
    println!("mistake 1, one applicant at a time: {} of {} applicants pass, yet only {} are placed", singles, n, size(&held_b));
    println!("mistake 2, the trio's lines counted, not the jobs they reach: {} lines, {} jobs", trio_lines, trio_reach);
    println!("mistake 3, accounts post deleted from the repaired graph: gap {}, {} placed", gap_c, size(&held_c));
    assert!(size(&held_b) as i32 == n as i32 - gap_b && size(&held_r) as i32 == n as i32 - gap_r);
    assert!((full_b > 0) == (size(&held_b) == n) && (full_r > 0) == (size(&held_r) == n));
    assert!(full_r == 4 && size(&held_c) as i32 == n as i32 - gap_c);
    assert!(trio == vec![0, 1, 2] && trio_reach == 2 && singles == n);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
applicants 6, jobs 6; qualification lines: blocked 13, repaired 14
blocked : worst group of all 64 is Ana, Ben, Cleo -- 3 applicants, 2 jobs, gap 1
blocked : augmenting paths place 5; Hall's count 6 - 1 = 5; left out Cleo
repaired: worst gap over all 64 groups is 0
repaired: augmenting paths place 6; Hall's count 6 - 0 = 6
repaired: Ana-accounts Ben-front desk Cleo-laundry Dev-kitchen Eve-maintenance Fay-bar
complete placements by census: blocked 0, repaired 4
mistake 1, one applicant at a time: 6 of 6 applicants pass, yet only 5 are placed
mistake 2, the trio's lines counted, not the jobs they reach: 5 lines, 2 jobs
mistake 3, accounts post deleted from the repaired graph: gap 1, 5 placed
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Hall's theorem and the defect count for every hiring with finitely many applicants, and checks the hotel's numbers.

- A full placement exists exactly when every group of applicants reaches at least as many posts as it has members.
- The posts may be infinitely many; only the applicants must be finite.
- With at least one post, the most applicants that can be placed is all of them minus the defect.
- The defect is the worst crowding over every group, the empty one included.
- The blocked hiring has 13 lines, the repaired one 14, and there are 64 groups to check.
- Ana, Ben and Cleo have 5 lines between them but reach only 2 posts, front desk and accounts.
- Every applicant alone qualifies for something, yet the worst gap in the blocked hiring is 1.
- The blocked hiring places five: Ana-accounts, Ben-front desk, Dev-kitchen, Eve-maintenance, Fay-bar.
- After Cleo's laundry training the worst gap is 0, and Cleo-laundry joins those five to place all six.
- The census finds no full placement before the repair and exactly 4 after it.
- Deleting the accounts post from the repaired hiring brings the gap back to 1.

The augmenting-path search, which places applicants without ever mentioning Hall, is left to the Python and Rust checks.

```lean
-- Hall's theorem: with finitely many applicants, every applicant can get a post of her own exactly when every group of applicants is qualified, between them, for at least as many posts as the group has members; and in general the most that can be placed is the number of applicants minus the worst group's shortfall.
import Mathlib.Combinatorics.Hall.Basic
import Mathlib.Data.Set.Card
import Mathlib.Data.ENat.Lattice
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Lattice

/-! Applicants form a type `α` with finitely many members, posts form any type `β`, and
`r a b` says applicant `a` is qualified for post `b`: one line of the bipartite graph, always
running from an applicant to a post. A group of applicants is `S : Finset α`, and the posts it
reaches, `N(S)` on the card, are `{b | ∃ a ∈ S, r a b}`. Their sizes are counted in `ℕ∞`
(`Set.encard`), so a group that reaches infinitely many posts counts as reaching `⊤`.
A full placement is a one-to-one map `f : α → β` sending every applicant to a post she is
qualified for. A partial placement is a set `P` of placed applicants and a map `f` that is
one-to-one on `P` and gives each of them a post she is qualified for. -/

/-- Hall's theorem. With finitely many applicants, every applicant can be given a post she is
qualified for, no post shared, exactly when every group `S` of applicants is qualified, between
them, for at least `|S|` posts: `|N(S)| ≥ |S|` for every group `S`. -/
theorem full_placement_iff_hall_condition {α β : Type*} [Finite α] (r : α → β → Prop) :
    (∃ f : α → β, Function.Injective f ∧ ∀ a, r a (f a)) ↔
      ∀ S : Finset α, (S.card : ℕ∞) ≤ {b | ∃ a ∈ S, r a b}.encard := by
  classical
  have := Fintype.ofFinite α
  constructor
  · rintro ⟨f, hf, hr⟩ S
    calc (S.card : ℕ∞) = ((S : Set α)).encard := by simp
      _ ≤ _ := Set.encard_le_encard_of_injOn
          (fun a ha => (⟨a, ha, hr a⟩ : ∃ a' ∈ S, r a' (f a))) hf.injOn
  · intro h
    have key : ∀ a, ∃ t : Finset β, (t : Set β) ⊆ {b | r a b} ∧
        ((t.card : ℕ∞) = min ({b | r a b}.encard) (Nat.card α)) := by
      intro a
      obtain ⟨t, hts, htc⟩ :=
        Set.exists_subset_encard_eq (min_le_left ({b | r a b}.encard) ((Nat.card α : ℕ∞)))
      have hfin : t.Finite := Set.finite_of_encard_le_coe (htc ▸ min_le_right _ _)
      refine ⟨hfin.toFinset, by simpa using hts, ?_⟩
      rw [← htc, ← Set.encard_coe_eq_coe_finsetCard]; simp
    choose t hts htc using key
    suffices hall : ∀ S : Finset α, S.card ≤ (S.biUnion t).card by
      obtain ⟨f, hf, hft⟩ := (Finset.all_card_le_biUnion_card_iff_exists_injective t).1 hall
      exact ⟨f, hf, fun a => hts a (hft a)⟩
    intro S
    by_cases hbig : ∃ a ∈ S, ((Nat.card α : ℕ) : ℕ∞) ≤ {b | r a b}.encard
    · obtain ⟨a, ha, hle⟩ := hbig
      have h1 : (t a).card = Nat.card α := by
        have := htc a; rw [min_eq_right hle] at this; exact_mod_cast this
      calc S.card ≤ Nat.card α := by rw [Nat.card_eq_fintype_card]; exact S.card_le_univ
        _ = (t a).card := h1.symm
        _ ≤ _ := Finset.card_le_card (Finset.subset_biUnion_of_mem t ha)
    · push Not at hbig
      have heq : ∀ a ∈ S, (t a : Set β) = {b | r a b} := by
        intro a ha
        have hc := htc a
        rw [min_eq_left (hbig a ha).le] at hc
        exact (t a).finite_toSet.eq_of_subset_of_encard_le (hts a)
          (by rw [Set.encard_coe_eq_coe_finsetCard, hc])
      have hU : ((S.biUnion t : Finset β) : Set β) = {b | ∃ a ∈ S, r a b} := by
        ext b
        simp only [Finset.coe_biUnion, Set.mem_iUnion, Set.mem_ofPred_eq, Finset.mem_coe,
          exists_prop]
        constructor
        · rintro ⟨a, ha, hb⟩; exact ⟨a, ha, hts a hb⟩
        · rintro ⟨a, ha, hb⟩
          refine ⟨a, ha, ?_⟩
          show b ∈ (t a : Set β)
          rw [heq a ha]; exact hb
      have := h S
      rw [← hU, Set.encard_coe_eq_coe_finsetCard] at this
      exact_mod_cast this

/-- Helper: the defect formula holds once there is at least one post (`[Nonempty β]`). -/
theorem max_placed_eq_card_sub_defect_of_nonempty {α β : Type*} [Finite α] [Nonempty β]
    (r : α → β → Prop) :
    IsGreatest
      {k : ℕ∞ | ∃ (P : Finset α) (f : α → β), Set.InjOn f P ∧ (∀ a ∈ P, r a (f a)) ∧
        k = (P.card : ℕ∞)}
      ((Nat.card α : ℕ∞) - ⨆ S : Finset α, ((S.card : ℕ∞) - {b | ∃ a ∈ S, r a b}.encard)) := by
  classical
  have := Fintype.ofFinite α
  set D : Finset α → ℕ∞ := fun S => (S.card : ℕ∞) - {b | ∃ a ∈ S, r a b}.encard with hD
  obtain ⟨S0, hS0⟩ := Finite.exists_max D
  have hsup : (⨆ S : Finset α, D S) = D S0 := le_antisymm (iSup_le hS0) (le_iSup D S0)
  change IsGreatest _ ((Nat.card α : ℕ∞) - ⨆ S : Finset α, D S)
  rw [hsup, Nat.card_eq_fintype_card]
  set n := Fintype.card α
  have hDle : D S0 ≤ (S0.card : ℕ∞) := tsub_le_self
  obtain ⟨d, hd⟩ : ∃ d : ℕ, D S0 = d :=
    ⟨(D S0).toNat, (ENat.natCast_toNat (ne_top_of_le_ne_top (ENat.natCast_ne_top _) hDle)).symm⟩
  rw [hd]
  constructor
  · -- existence: add `d` extra posts open to everyone and apply Hall's theorem
    let r' : α → β ⊕ Fin d → Prop := fun a x => Sum.elim (r a) (fun _ => True) x
    obtain ⟨f', hf', hr'⟩ := (full_placement_iff_hall_condition r').2 (by
      intro S
      rcases S.eq_empty_or_nonempty with rfl | ⟨a0, ha0⟩
      · simp
      have h1 : (S.card : ℕ∞) ≤ {b | ∃ a ∈ S, r a b}.encard + d := by
        have h := hS0 S
        rw [hd] at h
        rw [add_comm]; exact tsub_le_iff_right.1 h
      have hdisj : Disjoint (Sum.inl '' {b | ∃ a ∈ S, r a b}) (Set.range (Sum.inr : Fin d → β ⊕ Fin d)) := by
        rw [Set.disjoint_left]
        rintro _ ⟨b, -, rfl⟩ ⟨i, hi⟩
        cases hi
      calc (S.card : ℕ∞) ≤ {b | ∃ a ∈ S, r a b}.encard + d := h1
        _ = (Sum.inl '' {b | ∃ a ∈ S, r a b}).encard +
            (Set.range (Sum.inr : Fin d → β ⊕ Fin d)).encard := by
          rw [Sum.inl_injective.injOn.encard_image, Sum.inr_injective.encard_range]; simp
        _ = (Sum.inl '' {b | ∃ a ∈ S, r a b} ∪ Set.range (Sum.inr : Fin d → β ⊕ Fin d)).encard :=
          (Set.encard_union_eq hdisj).symm
        _ ≤ _ := by
          apply Set.encard_le_encard
          rintro x (⟨b, ⟨a, ha, hb⟩, rfl⟩ | ⟨i, rfl⟩)
          · exact ⟨a, ha, hb⟩
          · exact ⟨a0, ha0, trivial⟩)
    let f : α → β := fun a => Sum.elim id (fun _ => Classical.arbitrary β) (f' a)
    let P' := Finset.univ.filter (fun a => ∃ b, f' a = Sum.inl b)
    have hP' : ∀ a ∈ P', f' a = Sum.inl (f a) := by
      intro a ha
      obtain ⟨b, hb⟩ := (Finset.mem_filter.1 ha).2
      simp [f, hb]
    have hQ : (Finset.univ.filter (fun a => ¬ ∃ b, f' a = Sum.inl b)).card ≤ d := by
      calc _ ≤ (Finset.univ.map ⟨(Sum.inr : Fin d → β ⊕ Fin d), Sum.inr_injective⟩).card := by
            apply Finset.card_le_card_of_injOn f'
            · intro a ha
              have ha' := (Finset.mem_filter.1 ha).2
              rcases hfa : f' a with b | i
              · exact (ha' ⟨b, hfa⟩).elim
              · simp
            · exact hf'.injOn
        _ = d := by simp
    have hsplit : P'.card + (Finset.univ.filter (fun a => ¬ ∃ b, f' a = Sum.inl b)).card = n := by
      rw [Finset.card_filter_add_card_filter_not, Finset.card_univ]
    have hdn : d ≤ n := by
      have h1 : (d : ℕ∞) ≤ S0.card := hd ▸ hDle
      have h2 : d ≤ S0.card := by exact_mod_cast h1
      have h3 : S0.card ≤ n := S0.card_le_univ
      omega
    obtain ⟨P, hPP', hPc⟩ := Finset.exists_subset_card_eq (s := P') (n := n - d) (by omega)
    refine ⟨P, f, ?_, ?_, ?_⟩
    · intro a1 h1 a2 h2 h
      apply hf'
      rw [hP' a1 (hPP' h1), hP' a2 (hPP' h2), h]
    · intro a ha
      have := hr' a
      rw [hP' a (hPP' ha)] at this
      exact this
    · rw [hPc]; exact (ENat.natCast_sub n d).symm
  · -- upper bound
    rintro k ⟨P, f, hinj, hr, rfl⟩
    by_cases hN : (S0.card : ℕ∞) ≤ {b | ∃ a ∈ S0, r a b}.encard
    · have : D S0 = 0 := tsub_eq_zero_of_le hN
      rw [hd] at this
      have hd0 : d = 0 := by exact_mod_cast this
      subst hd0
      simp only [Nat.cast_zero, tsub_zero, Nat.cast_le]
      exact P.card_le_univ
    · push Not at hN
      have hfin : {b | ∃ a ∈ S0, r a b}.Finite := Set.finite_of_encard_le_coe hN.le
      set m := hfin.toFinset.card
      have hm : {b | ∃ a ∈ S0, r a b}.encard = m := by
        rw [← Set.encard_coe_eq_coe_finsetCard]; simp
      rw [hm] at hN
      have hmlt : m < S0.card := by exact_mod_cast hN
      have hdm : d = S0.card - m := by
        have : D S0 = ((S0.card - m : ℕ) : ℕ∞) := by
          simp only [hD, hm]; push_cast [hmlt.le]; rfl
        rw [hd] at this; exact_mod_cast this
      have h1 : (P ∩ S0).card ≤ m := by
        have : ((P ∩ S0 : Finset α) : Set α).encard ≤ {b | ∃ a ∈ S0, r a b}.encard := by
          apply Set.encard_le_encard_of_injOn
          · intro a ha
            simp only [Finset.coe_inter, Set.mem_inter_iff, Finset.mem_coe] at ha
            exact ⟨a, ha.2, hr a ha.1⟩
          · exact hinj.mono (by simp)
        rw [hm, Set.encard_coe_eq_coe_finsetCard] at this
        exact_mod_cast this
      have h2 : (P \ S0).card ≤ n - S0.card := by
        calc (P \ S0).card ≤ (Finset.univ \ S0).card :=
              Finset.card_le_card (Finset.sdiff_subset_sdiff (Finset.subset_univ _) le_rfl)
          _ = n - S0.card := by rw [Finset.card_univ_sdiff]
      have h3 := Finset.card_inter_add_card_sdiff P S0
      have h4 : S0.card ≤ n := S0.card_le_univ
      have : P.card ≤ n - d := by omega
      calc (P.card : ℕ∞) ≤ ((n - d : ℕ) : ℕ∞) := by exact_mod_cast this
        _ = (n : ℕ∞) - d := by push_cast [show d ≤ n by omega]; rfl

#print axioms max_placed_eq_card_sub_defect_of_nonempty

/-- The defect formula. With finitely many applicants and at least one post, the largest number that can be placed
(each in a post she is qualified for, no post shared) is the number of applicants minus the
defect: the most by which any group, the empty one included, outnumbers the posts it reaches,
`ν(G) = |A| - max_S (|S| - |N(S)|)`. -/
theorem max_placed_eq_card_sub_defect {α β : Type*} [Finite α] [Nonempty β] (r : α → β → Prop) :
    IsGreatest
      {k : ℕ∞ | ∃ (P : Finset α) (f : α → β), Set.InjOn f P ∧ (∀ a ∈ P, r a (f a)) ∧
        k = (P.card : ℕ∞)}
      ((Nat.card α : ℕ∞) - ⨆ S : Finset α, ((S.card : ℕ∞) - {b | ∃ a ∈ S, r a b}.encard)) := by
  exact max_placed_eq_card_sub_defect_of_nonempty r

/-! The hotel. Applicants 0 to 5 are Ana, Ben, Cleo, Dev, Eve, Fay. Posts 0 to 5 are front desk,
kitchen, laundry, bar, maintenance, accounts. Each list is the posts that applicant qualifies for. -/

/-- The blocked hiring from the card. -/
def blocked : Fin 6 → Finset (Fin 6) := ![{0, 5}, {0, 5}, {5}, {1, 2, 3}, {2, 4}, {3, 4, 1}]

/-- The repaired hiring: Cleo also trains on the laundry. -/
def repaired : Fin 6 → Finset (Fin 6) := ![{0, 5}, {0, 5}, {5, 2}, {1, 2, 3}, {2, 4}, {3, 4, 1}]

/-- The repaired hiring with the accounts post deleted. -/
def noAccounts : Fin 6 → Finset (Fin 6) := ![{0}, {0}, {2}, {1, 2, 3}, {2, 4}, {3, 4, 1}]

-- Qualification lines: 13 in the blocked hiring, 14 after the repair.
example : ∑ a, (blocked a).card = 13 ∧ ∑ a, (repaired a).card = 14 := by decide
-- Groups to check: each of 6 applicants in or out, 2^6 = 64.
example : Fintype.card (Finset (Fin 6)) = 64 := by decide
-- Ana, Ben, Cleo reach two posts, front desk and accounts: 3 members, 2 posts, gap 1.
example : ({0, 1, 2} : Finset (Fin 6)).biUnion blocked = {0, 5} ∧
    (({0, 1, 2} : Finset (Fin 6)).biUnion blocked).card = 2 := by decide
-- Mistake 2: the trio has 5 lines but reaches only 2 posts.
example : (blocked 0).card + (blocked 1).card + (blocked 2).card = 5 := by decide
-- Mistake 1: every applicant alone passes, all 6 qualify for something.
example : ∀ a, (blocked a).Nonempty := by decide
-- Blocked: the worst gap over all 64 groups is 1.
example : (∀ S : Finset (Fin 6), S.card ≤ (S.biUnion blocked).card + 1) ∧
    ∃ S : Finset (Fin 6), S.card = (S.biUnion blocked).card + 1 := by decide
-- Blocked: 6 - 1 = 5 placed; Ana-accounts, Ben-front desk, Dev-kitchen, Eve-maintenance, Fay-bar.
example : (∀ a ∈ ({0, 1, 3, 4, 5} : Finset (Fin 6)), ∀ a' ∈ ({0, 1, 3, 4, 5} : Finset (Fin 6)),
      (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a = (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a' → a = a') ∧
    ∀ a ∈ ({0, 1, 3, 4, 5} : Finset (Fin 6)), (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a ∈ blocked a := by
  decide
-- Repaired: the worst gap over all 64 groups is 0, Hall's condition holds.
example : ∀ S : Finset (Fin 6), S.card ≤ (S.biUnion repaired).card := by decide
-- Repaired: Ana-accounts, Ben-front desk, Cleo-laundry, Dev-kitchen, Eve-maintenance, Fay-bar.
example : Function.Injective (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) ∧
    ∀ a, (![5, 0, 2, 1, 4, 3] : Fin 6 → Fin 6) a ∈ repaired a := by decide
-- Complete placements by census: blocked 0, repaired 4.
example : ((Fintype.piFinset blocked).filter Function.Injective).card = 0 ∧
    ((Fintype.piFinset repaired).filter Function.Injective).card = 4 := by
  decide
-- Mistake 3: delete accounts from the repaired hiring and the gap is back to 1.
example : (∀ S : Finset (Fin 6), S.card ≤ (S.biUnion noAccounts).card + 1) ∧
    ∃ S : Finset (Fin 6), S.card = (S.biUnion noAccounts).card + 1 := by decide

#print axioms full_placement_iff_hall_condition
#print axioms max_placed_eq_card_sub_defect
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'max_placed_eq_card_sub_defect_of_nonempty' depends on axioms: [propext, Classical.choice, Quot.sound]
'full_placement_iff_hall_condition' depends on axioms: [propext, Classical.choice, Quot.sound]
'max_placed_eq_card_sub_defect' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. Each change makes an assert stop the program.
> - **Repair the blocked hiring too.** Change the third list in `BLOCKED` to `[5, 2]`. The worst gap becomes 0, and the last assert stops it.
> - **First choices only.** In `augment`, change `for j in adj[i]` to `for j in adj[i][:1]`. The repaired hiring places 5 while Hall's count says 6: the first assert.
> - **Let two applicants share a post.** In `census`, drop `if j not in used`. The blocked hiring now shows placements: the second assert.

---

## The usual mistake

> [!warning]
> **Checking one applicant at a time.** All 6 pass that test, and the placement still stops at 5. The obstruction is a group, not a person. Counting a group's lines instead of its posts hides it too: the trio has 5 lines and 2 posts.
>
> - **Checking only the whole side.** All six reach all six posts. The crowded group has three members, so only a scan across every size finds it.
> - **Taking it for a pairing everyone accepts.** The theorem gives existence, nothing more ([Stable matching](04-stable-matching-gale-shapley.md)).

---

## Where you meet it in real life

- **Rosters and timetables.** Staff qualified for some shifts, rooms licensed for some classes: the condition says whether a full roster exists.
- **Filling a grid.** Adding a row to a Latin square filled in row by row (a grid where no symbol repeats in a row or column) means giving each column a symbol it may still take. Hall's condition always holds there, so a grid of complete rows can always be finished.
- **The even case is free.** If every applicant qualifies for the same number of posts, and every post has that many qualified applicants, the condition holds unchecked: a group's lines all land in its reach, and each post there takes only that many.

> **Say it back**
> A full placement gives every applicant a post nobody else takes. It exists exactly when no group reaches fewer posts than it has members. One direction is counting: a placement gives each group its own posts. The other is a construction: either every group has a post to spare, so one pair is settled and set aside, or some group is exactly full and is settled inside its own posts. When the condition fails, the worst crowding counts who is left out: 1 at the hotel.

---

## What this builds on

- [Matchings](01-matchings-and-augmenting-paths.md): matchings, and the search the code's second road uses.
- [Strong induction and the least element](../../01-Foundations/06-Proof/05-strong-induction-and-well-ordering.md): why Step 2 may lean on any smaller hiring.

## Where this goes next

- [Konig's theorem](03-konigs-theorem-and-vertex-cover.md): the same fact as the fewest dots touching every line.
- [Max-flow min-cut](06-max-flow-min-cut.md): the crowded group as the cheapest cut of a network.
- [The assignment problem](../../14-Applied%20and%20computational/05-Operations%20Research/05-assignment-and-the-hungarian-algorithm.md): from "a placement exists" to "the cheapest one".

Checking the condition meant listing all 64 groups, a count that doubles with each applicant; finding the crowded group without that list is [Konig's theorem](03-konigs-theorem-and-vertex-cover.md).

---

## Sources

Verified 23 Sep 2026: every link below resolves to the publisher's page.

- Hall, P. "On Representatives of Subsets." *Journal of the London Mathematical Society* s1-10, no. 1 (1935): 26–30. [doi:10.1112/jlms/s1-10.37.26](https://doi.org/10.1112/jlms/s1-10.37.26). The original, stated for a family of sets (pick one member from each set, all different) rather than a graph.
- Diestel, Reinhard. *Graph Theory*, 6th ed. Graduate Texts in Mathematics 173. Springer, 2025. [Book page, with the free electronic edition](https://diestel-graph-theory.com/). Section 2.1: Hall's theorem, three proofs.
- van Lint, J. H., and R. M. Wilson. *A Course in Combinatorics*, 2nd ed. Cambridge University Press, 2001. [Publisher page](https://www.cambridge.org/core/books/course-in-combinatorics/84B89574496561D5E3A960863B85E4B7). Chapter 5: Hall's own set form.
- Bondy, J. A., and U. S. R. Murty. *Graph Theory*. Graduate Texts in Mathematics 244. Springer, 2008. [doi:10.1007/978-1-84628-970-5](https://doi.org/10.1007/978-1-84628-970-5). Chapter 16, matchings: Hall's theorem and its consequences.
