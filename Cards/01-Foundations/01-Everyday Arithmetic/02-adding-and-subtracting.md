# Adding and subtracting: combining and taking away, with carrying and borrowing

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Everyday Arithmetic](../README.md#s01) → Adding and subtracting

---

## General Overview

A market stall. Apples are 75 cents each. You and three friends take twelve of them between you, and pay with a $10 bill.

Two questions come out of that: what do the apples cost, and what comes back? They are one machine run in two directions. Pushing prices together is **adding**; pulling one number back out of another is **subtracting**. The first gives the bill, 900 cents; the second gives the change, 100 cents, which is four quarters, one each.

Nobody handles twelve numbers as a lump. You work in columns, ones under ones and tens under tens, trading whenever a column overflows or comes up short. School called those two trades **carrying** and **borrowing** — the second a poor name, since nothing is ever paid back.

**Adding puts piles of the same size together. Subtracting takes one pile out of another. Carrying and borrowing are trades: ten of one size for one of the size up, and back again.**

**What kind of fact this is:** a method, shown on this card in Why it works to give the right answer every time. It rests on what written digits mean, from [Place value](01-place-value.md).

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

**Read it aloud:** 75 plus 75 is 150. 1000 take away 900 is 100, and 100 plus 900 gives back the 1000.

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

### When it holds

- **Ones under ones, tens under tens.** Put the 7 of one 75 under the 5 of the other and you add tens to ones. The bill comes out wrong.
- **One unit for every number.** The card counts everything in whole cents. Take a bill in cents from a note counted in dollars and the answer means nothing.
- **A trade is ten for one, never another count.** Ten ones are worth one ten because the columns go up in tens. Carry at any other count and the digits no longer say what the pile is worth.
- **The bill is no bigger than the note.** Change is the note take away the bill. If the bill were bigger, there would be no change, only a debt: [Negative numbers](06-negative-numbers.md), numbers below zero.

---

## Why it works

75 is not one thing. It is 7 tens and 5 ones, which is all the written digits ever meant, and the whole content of [Place value](01-place-value.md). Piles of the same size can be counted together, so you never handle 75 as a quantity, only its piles.

Two apples: 7 tens and 7 tens is 14 tens, 5 ones and 5 ones is 10 ones. True, and unwritable, since there is no digit for fourteen and none for ten.

So trade. Ten ones are worth one ten: the ones pile drops to 0, the tens pile goes to 15. Ten tens are worth one hundred: the tens pile drops to 5 and a hundreds pile of 1 appears.

That is 1 hundred, 5 tens, 0 ones, or 150. Both trades were carrying, and that is all carrying ever is.

Twelve apples need nothing new: twelve sevens in the tens column is 84 tens, twelve fives in the ones is 60 ones, together 900.

Subtracting runs the trade backwards. 1000 take away 900 finds the hundreds column empty, so one thousand comes down as ten hundreds and the change is 100. Nothing is lost either way, because the ten that arrives cost exactly the one that left.

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

### Lean

Lean proves that carrying and borrowing give the right answer for every pair of whole numbers.

- Adding two whole numbers in columns, with carrying, writes out exactly the digits of their sum.
- When the bill is no bigger than the note, borrowing in columns gives digits 0 to 9. Their value is the note take away the bill.
- Adding the change back to the bill gives back the note.
- The card's own sums come out exact: 75 + 75 is 150, twelve apples are 900 cents, and the change is 100.

The running bill, apple by apple, is left to the Python and Rust checks.

<details>
<summary>The Lean proof, 187 lines</summary>

```lean
-- Adding and subtracting: adding two whole numbers column by column with carrying, and taking a smaller number from a bigger one column by column with borrowing, always gives the right answer, and adding the change back to the bill gives back the note.
import Mathlib.Data.Nat.Digits.Defs
import Mathlib.Tactic.NormNum

/-! Written numbers are lists of base-ten digits, ones column first, as `Nat.digits 10` gives
them: 75 is `[5, 7]`. Lining two such lists up entry by entry puts ones under ones and tens
under tens. -/

/-- Column addition with carrying, worked right to left (ones column first). In each column add
the two digits and the carry; write the ones digit of that total and carry the tens one column
left. A column missing from the shorter number counts as 0. A carry left over at the end becomes
a new column in front. -/
def addColumns : ℕ → List ℕ → List ℕ → List ℕ
  | carry, [], [] => if carry = 0 then [] else [carry]
  | carry, a :: as, [] => (a + carry) % 10 :: addColumns ((a + carry) / 10) as []
  | carry, [], b :: bs => (b + carry) % 10 :: addColumns ((b + carry) / 10) [] bs
  | carry, a :: as, b :: bs => (a + b + carry) % 10 :: addColumns ((a + b + carry) / 10) as bs

/-- Column subtraction with borrowing, worked right to left (ones column first). In each column
take the bottom digit and any borrow from the top digit. If the column is short, trade one from
the next column left down into ten here and borrow it there. A column missing from the bottom
number counts as 0. -/
def subColumns : ℕ → List ℕ → List ℕ → List ℕ
  | _, [], _ => []
  | borrow, a :: as, [] =>
      if borrow ≤ a then (a - borrow) :: subColumns 0 as []
      else (a + 10 - borrow) :: subColumns 1 as []
  | borrow, a :: as, b :: bs =>
      if b + borrow ≤ a then (a - b - borrow) :: subColumns 0 as bs
      else (a + 10 - b - borrow) :: subColumns 1 as bs

/-- Helper: column addition with any starting carry below 10. -/
theorem addColumns_digits_aux : ∀ (k m n c : ℕ), m + n ≤ k → c < 10 →
    addColumns c (Nat.digits 10 m) (Nat.digits 10 n) = Nat.digits 10 (m + n + c) := by
  intro k
  induction k with
  | zero =>
    intro m n c hk hc
    have hm : m = 0 := by omega
    have hn : n = 0 := by omega
    subst hm hn
    by_cases h : c = 0
    · subst h; simp [addColumns]
    · simp [addColumns, h, Nat.digits_of_lt 10 c h hc]
  | succ k ih =>
    intro m n c hk hc
    rcases Nat.eq_zero_or_pos m with hm | hm <;> rcases Nat.eq_zero_or_pos n with hn | hn
    · subst hm hn
      by_cases h : c = 0
      · subst h; simp [addColumns]
      · simp [addColumns, h, Nat.digits_of_lt 10 c h hc]
    · subst hm
      rw [Nat.digits_def' (by norm_num) hn]
      simp only [Nat.digits_zero, addColumns]
      have ih' := ih 0 (n / 10) ((n % 10 + c) / 10) (by omega) (by omega)
      simp only [Nat.digits_zero] at ih'
      rw [ih']
      rw [Nat.digits_def' (by norm_num) (by omega : 0 < 0 + n + c)]
      have e1 : (n % 10 + c) % 10 = (0 + n + c) % 10 := by omega
      have e2 : 0 + n / 10 + (n % 10 + c) / 10 = (0 + n + c) / 10 := by omega
      rw [e1, e2]
    · subst hn
      rw [Nat.digits_def' (by norm_num) hm]
      simp only [Nat.digits_zero, addColumns]
      have ih' := ih (m / 10) 0 ((m % 10 + c) / 10) (by omega) (by omega)
      simp only [Nat.digits_zero] at ih'
      rw [ih']
      rw [Nat.digits_def' (by norm_num) (by omega : 0 < m + 0 + c)]
      have e1 : (m % 10 + c) % 10 = (m + 0 + c) % 10 := by omega
      have e2 : m / 10 + 0 + (m % 10 + c) / 10 = (m + 0 + c) / 10 := by omega
      rw [e1, e2]
    · rw [Nat.digits_def' (by norm_num) hm, Nat.digits_def' (by norm_num) hn]
      simp only [addColumns]
      rw [ih (m / 10) (n / 10) ((m % 10 + n % 10 + c) / 10) (by omega) (by omega)]
      rw [Nat.digits_def' (by norm_num) (by omega : 0 < m + n + c)]
      have e1 : (m % 10 + n % 10 + c) % 10 = (m + n + c) % 10 := by omega
      have e2 : m / 10 + n / 10 + (m % 10 + n % 10 + c) / 10 = (m + n + c) / 10 := by omega
      rw [e1, e2]

#print axioms addColumns_digits_aux

/-- Helper: column subtraction with a borrow of 0 or 1. -/
theorem subColumns_digits_aux : ∀ (m n b : ℕ), b ≤ 1 → n + b ≤ m →
    (∀ d ∈ subColumns b (Nat.digits 10 m) (Nat.digits 10 n), d < 10) ∧
      Nat.ofDigits 10 (subColumns b (Nat.digits 10 m) (Nat.digits 10 n)) = m - n - b := by
  intro m
  induction m using Nat.strong_induction_on with
  | _ m ih =>
    intro n b hb hnb
    rcases Nat.eq_zero_or_pos m with hm | hm
    · subst hm
      simp [subColumns]
    · rw [Nat.digits_def' (by norm_num) hm]
      rcases Nat.eq_zero_or_pos n with hn | hn
      · subst hn
        simp only [Nat.digits_zero, subColumns]
        by_cases h : b ≤ m % 10
        · simp only [h, ite_true]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) 0 0 (by omega) (by omega)
          simp only [Nat.digits_zero] at h1 h2
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega
        · simp only [h, ite_false]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) 0 1 (by omega) (by omega)
          simp only [Nat.digits_zero] at h1 h2
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega
      · rw [Nat.digits_def' (by norm_num) hn]
        simp only [subColumns]
        by_cases h : n % 10 + b ≤ m % 10
        · simp only [h, ite_true]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) (n / 10) 0 (by omega) (by omega)
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega
        · simp only [h, ite_false]
          obtain ⟨h1, h2⟩ := ih (m / 10) (by omega) (n / 10) 1 (by omega) (by omega)
          refine ⟨?_, ?_⟩
          · intro d hd
            simp only [List.mem_cons] at hd
            rcases hd with hd | hd
            · omega
            · exact h1 d hd
          · rw [Nat.ofDigits_cons, h2]; omega

#print axioms subColumns_digits_aux

/-- Carrying gives the right answer every time: adding the written digits of any two whole
numbers column by column, ones under ones, trading ten in a column for one in the next, writes
out exactly the digits of their sum. -/
theorem column_addition_gives_the_sum (m n : ℕ) :
    addColumns 0 (Nat.digits 10 m) (Nat.digits 10 n) = Nat.digits 10 (m + n) := by
  have := addColumns_digits_aux (m + n) m n 0 le_rfl (by norm_num)
  simpa using this

/-- Borrowing gives the right answer every time the bill is no bigger than the note: taking the
written digits of the bill from those of the note column by column, trading one in a column for
ten in the next column right when a column is short, writes out a proper number (every digit
0 to 9) whose value is the note take away the bill. -/
theorem column_subtraction_gives_the_difference (note bill : ℕ) (h : bill ≤ note) :
    (∀ d ∈ subColumns 0 (Nat.digits 10 note) (Nat.digits 10 bill), d < 10) ∧
      Nat.ofDigits 10 (subColumns 0 (Nat.digits 10 note) (Nat.digits 10 bill)) = note - bill := by
  have := subColumns_digits_aux note bill 0 (by norm_num) (by omega)
  simpa using this

/-- Subtraction checks itself: when the bill is no bigger than the note, the change (the note
take away the bill) added back to the bill gives back the note. -/
theorem change_add_bill_eq_note (note bill : ℕ) (h : bill ≤ note) :
    (note - bill) + bill = note := by
  omega

-- 75 + 75 by columns: 5 + 5 is 10, write 0 carry 1; 7 + 7 + 1 is 15, write 5 carry 1 in front.
example : addColumns 0 [5, 7] [5, 7] = [0, 5, 1] := by norm_num [addColumns]
example : Nat.digits 10 150 = [0, 5, 1] := by norm_num
example : 75 + 75 = 150 := by norm_num
-- Twelve apples at 75 cents: 84 tens and 60 ones make 900 cents.
example : 12 * 7 = 84 ∧ 12 * 5 = 60 := by norm_num
example : 84 * 10 + 60 = 900 := by norm_num
example : 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 + 75 = 900 := by norm_num
-- 1000 take away 900 by columns: the thousand comes down as ten hundreds; the change is 100.
example : subColumns 0 [0, 0, 0, 1] [0, 0, 9] = [0, 0, 1, 0] := by decide
example : 1000 - 900 = 100 := by norm_num
-- The check: 100 + 900 gives back the 1000.
example : 100 + 900 = 1000 := by norm_num
-- One friend's three apples, and four shares make the whole basket.
example : 75 + 75 + 75 = 225 := by norm_num
example : 225 + 225 + 225 + 225 = 900 := by norm_num
-- The change is four quarters.
example : 25 + 25 + 25 + 25 = 100 := by norm_num

#print axioms column_addition_gives_the_sum
#print axioms column_subtraction_gives_the_difference
#print axioms change_add_bill_eq_note
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'addColumns_digits_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'subColumns_digits_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'column_addition_gives_the_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
'column_subtraction_gives_the_difference' depends on axioms: [propext, Classical.choice, Quot.sound]
'change_add_bill_eq_note' depends on axioms: [propext, Quot.sound]
```

---

> [!TIP]
> **Try changing**
> - **Apples at 80 cents.** Set PRICE to 80. The ones column is 0 and 0 every time, so twelve additions go by without a single carry out of the ones column. Round prices are easy for this reason.
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

Left open: adding 75 twelve times is slow, so is there one move that goes straight to 900?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Fuson, Karen C., and Diane J. Briars. "Using a Base-Ten Blocks Learning/Teaching Approach for First- and Second-Grade Place-Value and Multidigit Addition and Subtraction." *Journal for Research in Mathematics Education* 21, no. 3 (1990): 180-206. [doi:10.5951/jresematheduc.21.3.0180](https://doi.org/10.5951/jresematheduc.21.3.0180). Carrying and borrowing taught as physical trades.
- Knuth, Donald E. *The Art of Computer Programming, Volume 2: Seminumerical Algorithms*, 3rd ed. Addison-Wesley. [Publisher page](https://www.informit.com/store/art-of-computer-programming-volume-2-seminumerical-9780201896848). Section 4.3.1 is the column method in full, in any base.
