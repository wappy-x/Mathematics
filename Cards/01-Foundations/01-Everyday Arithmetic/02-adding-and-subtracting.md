# Adding and subtracting: combining and taking away, with carrying and borrowing

[Syllabus](../../../SYLLABUS.md) → [Foundations](../../../SYLLABUS.md#w01) → [Everyday Arithmetic](../../../SYLLABUS.md#w01-s01) → Adding and subtracting

---

## General Overview

A market stall. Apples are 75 cents each. You and three friends take twelve of them between you, and pay with a $10 bill.

Two questions come out of that: what do the apples cost, and what comes back? They are one machine run in two directions. Pushing prices together is **adding**; pulling one number back out of another is **subtracting**. The first gives the bill, 900 cents; the second gives the change, 100 cents, which is four quarters, one each.

Nobody handles twelve numbers as a lump. You work in columns, ones under ones and tens under tens, trading whenever a column overflows or comes up short. School called those two trades **carrying** and **borrowing** — the second a poor name, since nothing is ever paid back.

**Adding puts piles of the same size together. Subtracting takes one pile out of another. Carrying and borrowing are trades: ten of one size for one of the size up, and back again.**

```
apples in the bag    the bill so far    (one block = one apple, 75 cents)
     2   ██                             150 cents
     6   ██████                         450 cents
    12   ████████████                   900 cents
```

Every apple adds another 75 cents, the note is 1000 cents, and the gap at the end is your change. All in whole cents, because whole numbers are the subject.

---

## The formula

Nothing to memorise. Two sums, written in columns and worked right to left:

```
    75          1000
  + 75        -  900
  ----        ------
   150           100      check:  100 + 900 = 1000
```

The left-hand sum carries twice, and that second carry becomes a new column. The right-hand one trades a thousand down into ten hundreds.

**The check.** Subtraction is addition asked backwards, so it checks itself: add the answer back to what you took away. 100 plus 900 gives back 1000, the note, so you never have to trust the borrowing.

| Name | What it is | Here |
| --- | --- | --- |
| top number | what you start with | 75, and 1000 the note |
| bottom number | what you add on or take away | 75, and 900 the bill |
| sum | what the two come to | 150 |
| difference | what is left after taking away | 100 |
| carry | moved a column left when a total hits ten | 1, twice |
| borrow | handed down when a column is short | 1, from the thousands |

---

## Why it works

75 is not one thing. It is 7 tens and 5 ones, which is all the written digits ever meant, and the whole content of [Place value](01-place-value.md). Piles of the same size can be counted together, so you never handle 75 as a quantity, only its piles.

Two apples: 7 tens and 7 tens is 14 tens, 5 ones and 5 ones is 10 ones. True, and unwritable, since there is no digit for fourteen and none for ten. So trade. Ten ones are worth one ten: the ones pile drops to 0, the tens pile goes to 15. Ten tens are worth one hundred: the tens pile drops to 5 and a hundreds pile of 1 appears. That is 1 hundred, 5 tens, 0 ones, or 150. Both trades were carrying, and that is all carrying ever is.

Twelve apples need nothing new: twelve sevens in the tens column is 84 tens, twelve fives in the ones is 60 ones, together 900. Subtracting runs the trade backwards. 1000 take away 900 finds the hundreds column empty, so one thousand comes down as ten hundreds and the change is 100. Nothing is lost either way, because the ten that arrives cost exactly the one that left.

---

## Worked numbers, by hand

Twelve apples at 75 cents, a $10 bill, four friends, all in cents.

| Step | Arithmetic | Value |
| --- | --- | --- |
| one apple | given | 75 |
| two apples, ones column | 5 + 5: write 0, carry 1 | 0 |
| two apples, tens column | 7 + 7 + carry 1: write 5, carry 1 in front | 150 |
| twelve apples | 84 tens and 60 ones | **900** |
| the change | 1000 take away 900 | **100** |
| the check | 100 + 900 | 1000, the note back |
| three apples each | 75 + 75 + 75 | 225 |

The change is four quarters, so each friend gets 25 cents back with their apples.

### What breaks if you drop a piece

| Mistake | What comes out |
| --- | --- |
| The carry is dropped, not moved left | Ten ones lost at every overflow, and a bill far below 900. |
| A short column takes the smaller digit from the bigger | More change than the note, which cannot happen. |
| The subtraction is done the wrong way round | An answer past zero: a debt, not change. |

Swapping the numbers in an addition changes nothing. In a subtraction it changes everything.

---
## Code, from first principles, and it actually runs

The house example the plain way, one price added on at a time, then the same bill again as a cross-check: the twelve tens digits and the twelve ones digits, added as piles.

### Python

```python
# The check behind the card: twelve apples at 75 cents, a $10 bill, four
# friends, everything in whole cents.  Nothing is imported.
APPLES, PRICE, PAID, QUARTER = 12, 75, 1000, 25
# First way: put one apple's price on the pile at a time, keeping the bill.
bill, running = 0, []
for _ in range(APPLES):
    bill = bill + PRICE
    running.append(bill)
# Second way, the cross-check: the same total by piles -- twelve sevens in
# the tens column and twelve fives in the ones, exactly as on the card.
tens, ones = 0, 0
for _ in range(APPLES):
    tens, ones = tens + 7, ones + 5
piles = tens * 10 + ones
change = PAID - bill
share = PRICE + PRICE + PRICE
print(f"one apple, cents           {PRICE:>5}")
print(f"twelve apples, added up    {bill:>5}")
print(f"twelve apples, by piles    {piles:>5}")
print(f"   twelve sevens {tens} tens, twelve fives {ones} ones")
print(f"paid with, cents           {PAID:>5}")
print(f"change, cents              {change:>5}")
print(f"check: change + bill       {change + bill:>5}")
print(f"one friend's three apples  {share:>5}")
print(f"one friend's quarter       {QUARTER:>5}")
print("running bill, cents:  " + " ".join(str(v) for v in running))
assert bill == piles, "the two roads to the bill must agree"
assert change + bill == PAID, "the change plus the bill must give back the note"
assert share + share + share + share == bill, "four shares must be the whole basket"
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
one apple, cents              75
twelve apples, added up      900
twelve apples, by piles      900
   twelve sevens 84 tens, twelve fives 60 ones
paid with, cents            1000
change, cents                100
check: change + bill        1000
one friend's three apples    225
one friend's quarter          25
running bill, cents:  75 150 225 300 375 450 525 600 675 750 825 900
ALL CHECKS PASS
```

### Rust

```rust
// The check behind the card, in Rust: twelve apples at 75 cents, a $10 bill,
// four friends, everything in whole cents.  No crates, nothing imported.
fn main() {
    const APPLES: i64 = 12;
    const PRICE: i64 = 75;
    const PAID: i64 = 1000;
    const QUARTER: i64 = 25;
    // First way: put one apple's price on the pile at a time, keeping the bill.
    let mut bill = 0i64;
    let mut running: Vec<i64> = Vec::new();
    for _ in 0..APPLES {
        bill = bill + PRICE;
        running.push(bill);
    }
    // Second way, the cross-check: the same total by piles -- twelve sevens in
    // the tens column and twelve fives in the ones, exactly as on the card.
    let (mut tens, mut ones) = (0i64, 0i64);
    for _ in 0..APPLES {
        tens = tens + 7;
        ones = ones + 5;
    }
    let piles = tens * 10 + ones;
    let change = PAID - bill;
    let share = PRICE + PRICE + PRICE;
    println!("one apple, cents           {:>5}", PRICE);
    println!("twelve apples, added up    {:>5}", bill);
    println!("twelve apples, by piles    {:>5}", piles);
    println!("   twelve sevens {} tens, twelve fives {} ones", tens, ones);
    println!("paid with, cents           {:>5}", PAID);
    println!("change, cents              {:>5}", change);
    println!("check: change + bill       {:>5}", change + bill);
    println!("one friend's three apples  {:>5}", share);
    println!("one friend's quarter       {:>5}", QUARTER);
    let cents: Vec<String> = running.iter().map(|v| v.to_string()).collect();
    println!("running bill, cents:  {}", cents.join(" "));
    assert!(bill == piles, "the two roads to the bill must agree");
    assert!(change + bill == PAID, "the change plus the bill must give back the note");
    assert!(share + share + share + share == bill, "four shares must be the whole basket");
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
one apple, cents              75
twelve apples, added up      900
twelve apples, by piles      900
   twelve sevens 84 tens, twelve fives 60 ones
paid with, cents            1000
change, cents                100
check: change + bill        1000
one friend's three apples    225
one friend's quarter          25
running bill, cents:  75 150 225 300 375 450 525 600 675 750 825 900
ALL CHECKS PASS
```

Same numbers, same labels, line for line.

---

> [!TIP]
> **Try changing**
> - **Apples at 80 cents.** Set PRICE to 80. The ones column is 0 and 0 every time, so twelve additions go by without a single carry. Round prices are easy for this reason.
> - **A thirteenth apple.** Set APPLES to 13. The bill climbs past 900, and the change left over no longer splits four ways. That is the next card.

---

## The usual mistake

> [!warning]
> **Treating carrying as a rule you were told to obey.** It is a trade, and it goes both ways: ten ones for one ten going up, one ten for ten ones coming down. Anyone who has made change for a twenty has done both without noticing. Once it is a trade, "borrow across the zeros" stops being a thing to memorise: the zeros are empty columns, so you walk left until a column has something in it.

---

## Where you meet it in real life

- **Change at a till.** A trader counting up from 900 to 1000 in quarters is subtracting without ever borrowing, and lands on the same 100 cents.
- **Any running balance.** A bank statement is one long column of additions and subtractions, kept in whole cents for the reason this card is: whole numbers do not drift.
- **Inside every computer.** The same rule with two digits instead of ten, so a carry happens at two. A chip's adder does one column, then passes the carry left.

> **Say it back**
> A written number is already a stack of piles: 75 is 7 tens and 5 ones. To add, put piles of the same size together, and when a pile passes nine, trade ten of it for one of the next size up, a column left: carrying. To subtract, take pile from pile, and when a column is short, trade one of the bigger size down into ten of the smaller: borrowing. Twelve apples at 75 cents come to 900 cents and the change from a 1000-cent note is 100 cents. Add the change back: if the note comes back, you were right.

---

## What this builds on

- [Place value](01-place-value.md): that 75 means 7 tens and 5 ones, and that the column a digit sits in decides what it is worth. Every trade here moves between two of those columns.

## Where this goes next

- [Multiplying and dividing](03-multiplying-and-dividing.md): adding the same number over and over is what multiplying is for. Twelve apples was twelve additions here and is one multiplication there.

---

## Sources

Verified 6 Sep 2026: both links resolve to the publisher's page.

- Fuson, Karen C., and Diane J. Briars. "Using a Base-Ten Blocks Learning/Teaching Approach for First- and Second-Grade Place-Value and Multidigit Addition and Subtraction." *Journal for Research in Mathematics Education* 21, no. 3 (1990): 180-206. [doi:10.5951/jresematheduc.21.3.0180](https://doi.org/10.5951/jresematheduc.21.3.0180). Carrying and borrowing taught as physical trades.
- Knuth, Donald E. *The Art of Computer Programming, Volume 2: Seminumerical Algorithms*, 3rd ed. Addison-Wesley. [Publisher page](https://www.informit.com/store/art-of-computer-programming-volume-2-seminumerical-9780201896848). Section 4.3.1 is the column method in full, in any base.
