# Round tables and bracelets: fix one seat to kill the rotations, halve again if flipping counts the same

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../../../SYLLABUS.md#w04) → [Repeats, Groups and Double Counting](../../../SYLLABUS.md#w04-s02) → Round tables and bracelets

---

## General Overview

Eight friends come to dinner. The table is round, the chairs identical, no head of the table. How many different dinners are there?

In a row the eight make 40,320 orders: eight choices for the first place, seven for the next, down to one. That is 8!, spoken "eight factorial" ([Factorials](../01-Counting%20Principles/03-factorial.md)). Round a table it is too big. Ask everyone to move one chair clockwise: every guest keeps the same neighbours. Nothing about the dinner changed. Eight of those 40,320 orders are one dinner wearing eight labels.

So divide by eight: 40,320 / 8 = 5,040, which is 7!.

Now string six different beads — red, orange, yellow, green, blue, violet — on a ring. In a row they make 6! = 720 orders, and turning the ring changes nothing, as before: 720 / 6 = 120. A ring where turning is the only move allowed is a **necklace**. A **bracelet** can also be slipped off and turned over, which reverses the bead order; count a ring and its mirror image as one and the 120 halve to 60.

**Count the arrangements as if every position were labelled, then divide by how many labelled orders describe the same thing.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; which arrangements count as "the same" is a convention, fixed before any counting starts.

### The picture: twenty-four orders, six dinners

Four of them — Ada, Ben, Cleo, Dev — by initial. Each row is one dinner, four times over:

| The six dinners, each as its four row-orders |
| --- |
| ABCD, BCDA, CDAB, DABC |
| ABDC, BDCA, DCAB, CABD |
| ACBD, CBDA, BDAC, DACB |
| ACDB, CDBA, DBAC, BACD |
| ADBC, DBCA, BCAD, CADB |
| ADCB, DCBA, CBAD, BADC |

All 24 orders appear, four to a row: 24 / 4 = 6 dinners. Every row starts with Ada — the second road, below.

---

## The formula

Notation first, in words: $n!$ is the whole numbers from $n$ down to 1 multiplied together; it counts the ways of putting $n$ different things in a row.

Round a table, where rotating everyone counts as the same:

$$\frac{n!}{n} = (n-1)!$$

**Read it aloud:** each arrangement turns up once per position it can be rotated into, so divide the row count by the number of positions.

On a ring that can also be turned over, so an arrangement and its reverse are one:

$$\frac{n!}{2n} = \frac{(n-1)!}{2}$$

**Read it aloud:** turning over doubles the orders showing one ring, so divide by twice the number of positions.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $n$ | how many different things go round the ring | 8 guests, 6 beads | climbs steeply |
| $n!$ | their orders in a row, before dividing | 40,320 for eight guests | — |
| $(n-1)!$ | arrangements round a table, rotations as one | 5,040 dinners | — |
| $(n-1)!/2$ | arrangements on a bracelet, the flip as one too | 60 bracelets | — |
| $2n$ | moves leaving a bracelet unchanged: a turn, with or without a flip | 12 for six beads | more divided out, fewer bracelets |

### When it holds

- **All $n$ things different.** With a repeat, an arrangement can be its own mirror image and one division no longer serves for all: beads R R B B G Y make 16 bracelets, not the 15 halving predicts.
- **Rotating must change nothing that matters.** Numbered chairs, a head of the table, a seat facing the window: positions differ and the answer is the plain 40,320.
- **The flip must be possible and count as the same.** A bracelet turns over; a dinner table does not. Halving the table gives 2,520, and it is wrong: a flip swaps every guest's left neighbour for the right one.
- **At least three things before halving.** With two beads, turning the ring over does what turning it round does, and half of $(n-1)!$ is no whole number.

---

## Why it works

### Step 0: fix what "the same" means first

A count needs a rule saying when two pictures are one thing. Here: two seatings are the same when one becomes the other by moving everyone the same number of chairs round. A bracelet allows one move more, turning the ring over. Those moves sort the labelled orders into families, and the number wanted is how many families.

### Step 1: every family holds one order per position

Take one dinner. Read it off from chair 1, then from chair 2, and so on to chair 8: eight row-orders, all the same dinner. No two agree, because the guests all differ: shift everyone by one chair, or by any number of chairs up to seven, and a different guest sits in chair 1. The family holds exactly 8 orders.

### Step 2: divide

There are 40,320 orders, every family holds 8, and no order sits in two families, since a family is everything reachable from one order by rotating. Counting family by family gives 40,320 / 8 = 5,040 — the rule of division: count as if the positions were labelled, then divide by the size of one family.

### Step 3: the same answer with one guest nailed down

Every family holds exactly one order with Ada in chair 1: rotate until she is there, and only one rotation does it. So the families match those orders one for one, and those orders put the other seven guests in the seven other chairs: 7! = 5,040. No division anywhere, and it is where the shape $(n-1)!$ comes from. Matching two collections one for one is a method of its own ([Bijections and double counting](05-bijection-and-double-counting.md)).

### Step 4: the flip halves it again

A ring reads as a row in twelve ways: six starting points, each taken in either direction. For R O Y G B V:

| The six turns | ROYGBV, OYGBVR, YGBVRO, GBVROY, BVROYG, VROYGB |
| --- | --- |
| The same ring turned over | VBGYOR, BGYORV, GYORVB, YORVBG, ORVBGY, RVBGYO |

Twelve strings, one bracelet: 720 / 12 = 60, which is also 120 / 2 — the flip pairs the 120 necklaces off two at a time.

<details>
<summary>Detailed proof: why every family is exactly the same size</summary>

Number the positions round the ring; all $n$ items differ.

**Turns.** Suppose a turn, short of a full circle, left an arrangement unchanged. Every position would then hold the same item as the position that far on, and that is a different position, so two positions hold the same item — which all items differing forbids. The $n$ turns give $n$ different orders.

**Flips.** A flip reverses the ring, and a flip followed by a turn gives $n$ such moves, $2n$ in all. Each pairs the positions off, leaving at most two where they were, so with $n$ at least 3 one genuine pair is swapped — and the arrangement survives only if that pair holds the same item. So a family holds $n$ orders on a table, $2n$ on a bracelet.

</details>

### Step 5: the division fails the moment two things match

Repeat a bead and an arrangement can survive a move. Its family is then smaller than the rest, and one division cannot serve all. Take six beads, two red, two blue, one green, one yellow: R R B B G Y. There are 180 different orders in a row and 30 necklaces, so halving gives 15 — but the brute force in the code finds 16 bracelets. The gap is the 2 necklaces left unchanged when the ring is turned over: they have no partner to pair with, so 16 = (30 + 2) / 2.

The general repair counts what each move leaves unchanged and averages over the moves ([Group actions](../../03-Algebra/08-Groups/08-group-actions-and-counting.md)). Where only the do-nothing move spares anything, that average collapses back to the division used here.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| eight guests in eight numbered chairs | 8 × 7 × 6 × 5 × 4 × 3 × 2 × 1 | 40,320 |
| rotations of one dinner | one per chair | 8 |
| dinners round the table | 40,320 / 8 | **5,040** |
| the same, Ada nailed to one chair | 7 × 6 × 5 × 4 × 3 × 2 × 1 | **5,040** |
| six different beads in a row | 6 × 5 × 4 × 3 × 2 × 1 | 720 |
| necklaces, turning only | 720 / 6 | 120 |
| bracelets, turning or flipping | 720 / 12 | **60** |
| by pairing the necklaces off | 120 / 2 | **60** |

Eight friends could dine a different way nightly for years; a jeweller stocking every bracelet of six chosen beads needs 60, not 120.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Leaving the chairs numbered | 40,320 | Each dinner counted once per rotation |
| Halving the table as well | 2,520 | A flip swaps left and right neighbours: a different dinner |
| Halving a ring whose beads repeat: R R B B G Y | 15 instead of 16 | Two of the 30 necklaces are their own mirror image |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported, not even the factorial. Two roads share no arithmetic: the closed formula, and a brute force that builds every order in a row, labels each with the smallest member of its family, and counts the labels. A third counts the orders with one guest nailed to a chair. A second case, six beads with two red and two blue, is where halving goes wrong.

### Python

```python
# Round tables and bracelets -- the check behind the card.  Nothing is imported.
# Eight guests sit round one table; six different beads hang on one bracelet.
# Every count is reached twice: once from the factorial, once by listing every
# order in a row and sorting that whole list into classes.
def fact(n):                                   # n!, written out rather than imported
    out = 1
    for k in range(2, n + 1): out *= k
    return out

def orders(items):                             # every order of the items in a row
    if len(items) <= 1: return [tuple(items)]
    out = []
    for i in range(len(items)): out += [(items[i],) + r for r in orders(items[:i] + items[i + 1:])]
    return out

def distinct(items):                           # repeated items make the same order twice
    return sorted(set(orders(items)))
def turns(s):                                  # the rotations of one order
    return [s[k:] + s[:k] for k in range(len(s))]

def tag(s, flip):                              # one name shared by a whole class
    return min(turns(s) + (turns(s[::-1]) if flip else []))

def classes(seqs, flip):                       # class name -> how many orders it holds
    out = {}
    for t in [tag(s, flip) for s in seqs]: out[t] = out.get(t, 0) + 1
    return out

def size(cls):                                 # the size every class shares, 0 if they differ
    return min(cls.values()) if len(set(cls.values())) == 1 else 0
def mirrors(cls):                              # classes unchanged by turning the ring over
    return sum(1 for t in cls if tag(t[::-1], False) == t)

table, four = distinct(tuple(range(8))), distinct(tuple(range(4)))
beads, three = distinct(tuple(range(6))), distinct(tuple(range(3)))
mixed = distinct((0, 0, 1, 1, 2, 3))           # beads R R B B G Y
seatings, small = classes(table, False), classes(four, False)
necks, bracs = classes(beads, False), classes(beads, True)
mneck, mbrac = classes(mixed, False), classes(mixed, True)
fixed = sum(1 for s in table if s[0] == 0)     # guest 0 nailed to one chair
print(f"8 guests in 8 numbered chairs: 8! = {len(table)} orders in a row")
print(f"one seating turns up once per rotation: classes of {size(seatings)}")
print(f"{len(table)} / {size(seatings)} = {len(seatings)} seatings round the table, and 7! = {fact(7)}")
print(f"nailing one guest to one chair and ordering the other 7: {fixed}")
print(f"treating clockwise and anticlockwise as one would give {len(seatings) // 2}, not {len(seatings)}")
print(f"4 guests, the picture: 4! = {len(four)} orders, {len(four)} / 4 = {len(small)} seatings")
print(f"6 different beads: 6! = {len(beads)} orders, {len(beads)} / 6 = {len(necks)} necklaces")
print(f"turning the ring over pairs them off: {len(necks)} / 2 = {len(bracs)} bracelets, and 5!/2 = {fact(5) // 2}")
print(f"brute force, orders sorted into turn-or-flip classes: {len(bracs)} classes of {size(bracs)}")
print(f"necklaces of 6 different beads unchanged by the flip: {mirrors(necks)}")
print(f"3 different beads: {len(classes(three, False))} necklaces, {len(classes(three, True))} bracelet")
print(f"beads R R B B G Y: {len(mixed)} different orders, {len(mneck)} necklaces")
print(f"halving those {len(mneck)} gives {len(mneck) // 2}, but brute force finds {len(mbrac)} bracelets")
print(f"{mirrors(mneck)} necklaces are unchanged by the flip: ({len(mneck)} + {mirrors(mneck)}) / 2 = {len(mbrac)}")
assert len(table) == fact(8) and len(seatings) == fact(7) and fixed == fact(7)
assert size(seatings) == 8 and len(seatings) * size(seatings) == len(table)
assert len(necks) == fact(5) and len(bracs) == fact(5) // 2 and mirrors(necks) == 0
assert 2 * len(mbrac) == len(mneck) + mirrors(mneck) and len(mbrac) != len(mneck) // 2
print("ALL CHECKS PASS")
```

**Ran 2026-09-14 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
8 guests in 8 numbered chairs: 8! = 40320 orders in a row
one seating turns up once per rotation: classes of 8
40320 / 8 = 5040 seatings round the table, and 7! = 5040
nailing one guest to one chair and ordering the other 7: 5040
treating clockwise and anticlockwise as one would give 2520, not 5040
4 guests, the picture: 4! = 24 orders, 24 / 4 = 6 seatings
6 different beads: 6! = 720 orders, 720 / 6 = 120 necklaces
turning the ring over pairs them off: 120 / 2 = 60 bracelets, and 5!/2 = 60
brute force, orders sorted into turn-or-flip classes: 60 classes of 12
necklaces of 6 different beads unchanged by the flip: 0
3 different beads: 2 necklaces, 1 bracelet
beads R R B B G Y: 180 different orders, 30 necklaces
halving those 30 gives 15, but brute force finds 16 bracelets
2 necklaces are unchanged by the flip: (30 + 2) / 2 = 16
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Round tables and bracelets -- the same check as the Python, in Rust.  No
// crates.  Eight guests sit round one table; six different beads hang on one
// bracelet.  Every count is reached twice: once from the factorial, once by
// listing every order in a row and sorting that whole list into classes.
use std::collections::{BTreeMap, BTreeSet};
type Seq = Vec<u8>;

fn fact(n: u64) -> u64 {                        // n!, written out rather than imported
    let mut out = 1;
    for k in 2..=n { out *= k }
    out
}

fn orders(items: &[u8]) -> Vec<Seq> {           // every order of the items in a row
    if items.len() <= 1 { return vec![items.to_vec()] }
    let mut out = Vec::new();
    for i in 0..items.len() {
        let mut rest = items.to_vec();
        let head = rest.remove(i);
        for tail in orders(&rest) { let mut one = vec![head]; one.extend(tail); out.push(one) }
    }
    out
}

fn distinct(items: &[u8]) -> Vec<Seq> {         // repeated items make the same order twice
    orders(items).into_iter().collect::<BTreeSet<Seq>>().into_iter().collect()
}
fn turns(s: &[u8]) -> Vec<Seq> {                // the rotations of one order
    (0..s.len()).map(|k| { let mut v = s[k..].to_vec(); v.extend_from_slice(&s[..k]); v }).collect()
}

fn tag(s: &[u8], flip: bool) -> Seq {           // one name shared by a whole class
    let mut family = turns(s);
    if flip { let mut back = s.to_vec(); back.reverse(); family.extend(turns(&back)) }
    family.into_iter().min().unwrap()
}

fn classes(seqs: &[Seq], flip: bool) -> BTreeMap<Seq, usize> {   // class name -> orders it holds
    let mut out = BTreeMap::new();
    for s in seqs { *out.entry(tag(s, flip)).or_insert(0) += 1 }
    out
}

fn size(cls: &BTreeMap<Seq, usize>) -> usize {  // the size every class shares, 0 if they differ
    let found: BTreeSet<usize> = cls.values().copied().collect();
    if found.len() == 1 { *found.iter().next().unwrap() } else { 0 }
}
fn mirrors(cls: &BTreeMap<Seq, usize>) -> usize {   // classes unchanged by turning the ring over
    cls.keys().filter(|t| { let mut b = t.to_vec(); b.reverse(); tag(&b, false) == **t }).count()
}

fn main() {
    let (table, four) = (distinct(&[0, 1, 2, 3, 4, 5, 6, 7]), distinct(&[0, 1, 2, 3]));
    let (beads, three) = (distinct(&[0, 1, 2, 3, 4, 5]), distinct(&[0, 1, 2]));
    let mixed = distinct(&[0, 0, 1, 1, 2, 3]);  // beads R R B B G Y
    let (seatings, small) = (classes(&table, false), classes(&four, false));
    let (necks, bracs) = (classes(&beads, false), classes(&beads, true));
    let (mneck, mbrac) = (classes(&mixed, false), classes(&mixed, true));
    let fixed = table.iter().filter(|s| s[0] == 0).count();   // guest 0 nailed to one chair
    println!("8 guests in 8 numbered chairs: 8! = {} orders in a row", table.len());
    println!("one seating turns up once per rotation: classes of {}", size(&seatings));
    println!("{} / {} = {} seatings round the table, and 7! = {}", table.len(), size(&seatings), seatings.len(), fact(7));
    println!("nailing one guest to one chair and ordering the other 7: {}", fixed);
    println!("treating clockwise and anticlockwise as one would give {}, not {}", seatings.len() / 2, seatings.len());
    println!("4 guests, the picture: 4! = {} orders, {} / 4 = {} seatings", four.len(), four.len(), small.len());
    println!("6 different beads: 6! = {} orders, {} / 6 = {} necklaces", beads.len(), beads.len(), necks.len());
    println!("turning the ring over pairs them off: {} / 2 = {} bracelets, and 5!/2 = {}", necks.len(), bracs.len(), fact(5) / 2);
    println!("brute force, orders sorted into turn-or-flip classes: {} classes of {}", bracs.len(), size(&bracs));
    println!("necklaces of 6 different beads unchanged by the flip: {}", mirrors(&necks));
    println!("3 different beads: {} necklaces, {} bracelet", classes(&three, false).len(), classes(&three, true).len());
    println!("beads R R B B G Y: {} different orders, {} necklaces", mixed.len(), mneck.len());
    println!("halving those {} gives {}, but brute force finds {} bracelets", mneck.len(), mneck.len() / 2, mbrac.len());
    println!("{} necklaces are unchanged by the flip: ({} + {}) / 2 = {}", mirrors(&mneck), mneck.len(), mirrors(&mneck), mbrac.len());
    assert!(table.len() as u64 == fact(8) && seatings.len() as u64 == fact(7) && fixed as u64 == fact(7));
    assert!(size(&seatings) == 8 && seatings.len() * size(&seatings) == table.len());
    assert!(necks.len() as u64 == fact(5) && bracs.len() as u64 == fact(5) / 2 && mirrors(&necks) == 0);
    assert!(2 * mbrac.len() == mneck.len() + mirrors(&mneck) && mbrac.len() != mneck.len() / 2);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-14 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
8 guests in 8 numbered chairs: 8! = 40320 orders in a row
one seating turns up once per rotation: classes of 8
40320 / 8 = 5040 seatings round the table, and 7! = 5040
nailing one guest to one chair and ordering the other 7: 5040
treating clockwise and anticlockwise as one would give 2520, not 5040
4 guests, the picture: 4! = 24 orders, 24 / 4 = 6 seatings
6 different beads: 6! = 720 orders, 720 / 6 = 120 necklaces
turning the ring over pairs them off: 120 / 2 = 60 bracelets, and 5!/2 = 60
brute force, orders sorted into turn-or-flip classes: 60 classes of 12
necklaces of 6 different beads unchanged by the flip: 0
3 different beads: 2 necklaces, 1 bracelet
beads R R B B G Y: 180 different orders, 30 necklaces
halving those 30 gives 15, but brute force finds 16 bracelets
2 necklaces are unchanged by the flip: (30 + 2) / 2 = 16
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to eight guests and six beads, so expect one to stop the program.
> - **Seat them along a bench.** Make `turns` return `[s]`: every order becomes its own class, the table count climbs back to 40,320, and the first assert stops the run.
> - **Turn the dinner table over.** Change `classes(table, False)` to `classes(table, True)`: the count falls to the 2,520 the fifth line names as wrong, and the first assert stops it.
> - **Make the two blue beads different.** Change `(0, 0, 1, 1, 2, 3)` to `(0, 0, 1, 2, 3, 4)`: one matching pair cannot make an arrangement its own mirror image, so halving is right again, and the last assert stops the run.

---

## The usual mistake

> [!warning]
> **Dividing when the arrangements were not all counted the same number of times.** It works here only because every dinner appears 8 times among the 40,320 orders and every bracelet 12 times among the 720. Repeat a bead and it stops: with R R B B G Y, halving the 30 necklaces gives 15, where the real count is 16.
>
> - **Leaving the chairs numbered.** 40,320 answers another question — eight guests in chairs that can be told apart.
> - **Halving the dinner table.** 2,520 treats a seating and its mirror image as one dinner.
> - **Calling every round count $(n-1)!$.** A key ring turns over, so six different keys go on it in 60 ways, not 120.

---

## Where you meet it in real life

- **Seating plans.** A round table for eight has 5,040 arrangements, not 40,320; a host who fixes one guest and works round is using the second road.
- **Bead work.** A piece that can only turn: 120 necklaces. One that can also be worn either way up: 60 bracelets.
- **Round trips.** A van that leaves a depot, calls once at each of seven stops and returns has 5,040 routes, half of them the same loop backwards.
- **Repeats, not rotations.** The same division handles identical items ([Arranging with repeats](01-multiset-permutations.md)) and interchangeable groups ([Splitting into groups](03-splitting-into-groups.md)).

> **Say it back**
> A round table has no first chair, so the 40,320 ways of lining eight guests up count every dinner eight times over. Divide by eight: 5,040 dinners, which is 7! — also the count with one guest nailed to a chair and the other seven ordered round. A bracelet allows one move more — turn it over and the bead order reverses — so six different beads make 60 bracelets against 120 necklaces. All of it needs every arrangement counted the same number of times: repeat a bead and it fails, as R R B B G Y shows with 16 bracelets where halving said 15.

---

## What this builds on

- [Factorials](../01-Counting%20Principles/03-factorial.md): the 40,320 orders in a row that everything here starts from.
- [Combinations, n choose k](../01-Counting%20Principles/05-n-choose-k.md): the same habit of dividing out an order nobody wanted counted.
- [Group actions](../../03-Algebra/08-Groups/08-group-actions-and-counting.md): the turns and the flip as a set of moves, and the count that survives unequal families.

## Where this goes next

Every division here needed the families to come out equal, a promise dividing cannot make on its own. Matching one collection against another can, and [Bijections and double counting](05-bijection-and-double-counting.md) turns that into a method: Step 3 already used it, with Ada nailed to her chair.

---

## Sources

Verified 14 Sep 2026: every link below resolves to the publisher's page.

- Rosen, Kenneth H. *Discrete Mathematics and Its Applications*. McGraw Hill. [Publisher page](https://www.mheducation.com/highered/product/discrete-mathematics-and-its-applications-rosen.html). The rule of division, seating round a table its example.
- Brualdi, Richard A. *Introductory Combinatorics* (Classic Version), 5th ed. Pearson. [Publisher page](https://www.pearson.com/en-us/subject-catalog/p/introductory-combinatorics-classic-version/P200000006138/9780137981045). Circular permutations in full; Pólya counting for the general case.
- Levin, Oscar. *Discrete Mathematics: An Open Introduction*, 3rd ed. [Full text, free](https://discrete.openmathbooks.org/dmoi3.html). The factorial and the choose count, built from the product rule.
- Stanley, Richard P. *Enumerative Combinatorics*, vol. 1, 2nd ed. Cambridge University Press. [doi:10.1017/CBO9781139058520](https://doi.org/10.1017/CBO9781139058520). Counting up to a set of moves, treated as counting orbits.
