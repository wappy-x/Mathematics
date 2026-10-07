---
type: card
wing: 01-Foundations
shelf: Everyday Arithmetic
topic: Whole numbers
item: Multiplying and dividing
kind: method
status: verified
updated: 2026-09-06
needs_first:
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/01-place-value|place-value]]"
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/02-adding-and-subtracting|adding-and-subtracting]]"
next:
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/04-order-of-operations|order-of-operations]]"
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/07-fractions|fractions]]"
  - "[[Cards/01-Foundations/03-Powers, Roots and Logarithms/01-exponents-and-powers|exponents-and-powers]]"
tags:
  - mathematics
  - foundations
  - multiplying-and-dividing
---

# Multiplying and dividing: adding in one move, and sharing out what is left

Foundations → Everyday Arithmetic → Whole numbers → Multiplying and dividing

---

## General Overview

Twelve apples. Each one costs 75 cents. You hand over a $10 bill. Later the apples get shared by four friends. Two questions, and they are the two halves of this card.

You could get the cost by adding 75 twelve times, and lose your place halfway. **Multiplying is that same adding, done in one move.** Twelve lots of 75 cents is 900 cents: nine dollars, and a dollar of change.

Sharing runs it backwards. Twelve apples, four friends, three apples each, nothing left over. The money splits too: 900 cents into four is 225 cents each, $2.25.

Make it fourteen apples and the friends still get three each, but two sit there. Those two have a name: the **remainder**, and an answer that ignores them is no answer.

**Multiplying is adding the same number over and over, in one move. Dividing asks how many times that number goes in. The remainder is what would not go round again.**

### The picture: one row for every apple

```
one dot for every cent, one row for every apple (rows drawn short)

apple  1   . . . . . . . . . . . . .    75 cents
apple  2   . . . . . . . . . . . . .    75 cents
   ...            ...                      ...
apple 12   . . . . . . . . . . . . .    75 cents
                                       900 cents in the whole block
```

Count it row by row and you are adding 75 twelve times.

---

## The formula

Two plain statements, no letters in either.

**12 × 75 = 900**, read aloud: **"twelve apples at seventy-five cents each cost nine hundred cents."**

**14 = 4 × 3 + 2**, read aloud: **"fourteen apples is four friends with three each, and two left over."**

The second never says "divided". It says what the pile was made of: the honest way to write a division that does not come out even.

| Part | In our example | Push it up and the answer... |
| --- | --- | --- |
| the count | 12 apples | climbs by one more 75 |
| the price of one | 75 cents | climbs the same way |
| the total | 900 cents, or $9.00 | it is the answer |
| the sharers | 4 friends | each share falls |
| the share | 3 apples, or 225 cents | it is the answer |
| the remainder | 0 here, 2 out of 14 | it stays under 4 |

---

## Why it works

### Step 0: a block of dots, counted two ways

A dot for every cent: twelve rows, one per apple, 75 dots in a row. Count row by row and you are adding 75 twelve times. Turn the page a quarter turn and it is 75 rows of twelve. Nobody added a dot, so both counts give 900.

Two things fall out. **Order does not matter when you multiply**: twelve lots of 75 is 75 lots of twelve. And **dividing is that block with a different hole in it**: multiplying, you know both sides and want the dots; dividing, you know the dots and one side. That is why every division can be checked by multiplying back: four lots of 225 comes back to 900.

### Step 1: the leftover stays smaller than the number sharing

Fourteen apples now. Deal a round to the four friends, then a second, then a third. Two are left, and two cannot cover four friends. Two is the remainder: 14 = 4 × 3 + 2.

Why can the leftover never reach four? If it did, another round would go out.

The other way out is to cut those two apples in half and share them anyway. That move invents fractions: [fractions](07-fractions.md).

<details>
<summary>The exact statement, if you want it</summary>

For any pile shared by one or more people, exactly one share-and-leftover pair fits, the leftover under the number sharing. Formally: the division theorem, in the number theory wing.

</details>

### Step 2: why dividing by zero has no answer

"12 shared by 4 is 3" is shorthand for this: four lots of three make twelve. Every division is a multiplication asked backwards.

So "12 shared by 0" asks for a number of zeros adding up to twelve: the check tries every whole number under 100 and finds none. "0 shared by 0" breaks the other way, because every number fits, and endless answers is no answer.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| twelve apples | 12 × 75 | **900 cents, or $9.00** |
| change from the bill | 1000 − 900 | 100 cents, or $1.00 |
| apples each | 12 shared by 4 | 3 each, 0 over |
| money each | 900 shared by 4 | 225 cents, or $2.25 |
| check the split | 4 × 225 | 900, it rebuilds |
| a pile of 14 apples | 14 shared by 4 | 3 each, 2 over |

Nine dollars for the apples, a dollar back, everyone owes $2.25.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| 3 apples each out of 14, then stop | 12 apples | Two vanish. The leftover is part of the answer. |
| "12 shared by 0" answered with 0 | 0 | Backwards, that says 0 lots of 0 is 12. |
| Never checking the share backwards | a quiet wrong number | 4 lots of 225 must rebuild 900. |

---

## Code, from first principles, and it actually runs

The house example twice: the plain way, then the same answers by a route that cannot borrow them — 75 added to itself twelve times, the shares added back up.

### Python

```python
# Multiplying and dividing -- the check behind the card.  Nothing is imported.
# The plain way first, then the same answers again by adding, as a cross-check.

def added_up(count, size):            # size added to itself, count times over
    total = 0
    for _ in range(count):
        total = total + size
    return total

def row(label, value): print(f"{label:<36}{value:>28}")

cost = 12 * 75                        # twelve apples at 75 cents each
change = 1000 - cost                  # handed over a $10 bill, which is 1000 cents
each, over = cost // 4, cost % 4      # the money split four ways
zeros = [q for q in range(0, 100) if added_up(q, 0) == 12]   # nothing here works
assert cost == added_up(12, 75), "adding 75 twelve times must give the same total"
assert added_up(each, 4) + over == cost, "four lots of 225 must rebuild the 900"
assert added_up(14 // 4, 4) + 14 % 4 == 14, "three each and two over must rebuild 14"
row("12 apples at 75 cents each", f"{cost} cents")
row("that in dollars", f"{cost // 100}.{cost % 100:02d}")
row("change from the 1000-cent bill", f"{change} cents")
row("cross-check, 75 added 12 times", f"{added_up(12, 75)} cents")
row("900 cents shared by 4 friends", f"{each} each, {over} over")
row("each friend pays, in dollars", f"{each // 100}.{each % 100:02d}")
row("cross-check, 4 lots of 225", f"{added_up(each, 4) + over} cents")
row("12 apples shared by 4 friends", f"{12 // 4} each, {12 % 4} over")
row("14 apples shared by 4 friends", f"{14 // 4} each, {14 % 4} over")
row("cross-check, 4 lots of 3, plus 2", f"{added_up(14 // 4, 4) + 14 % 4} apples")
row("any number of 0s adding up to 12", f"{len(zeros)} found under 100")
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
12 apples at 75 cents each                             900 cents
that in dollars                                             9.00
change from the 1000-cent bill                         100 cents
cross-check, 75 added 12 times                         900 cents
900 cents shared by 4 friends                   225 each, 0 over
each friend pays, in dollars                                2.25
cross-check, 4 lots of 225                             900 cents
12 apples shared by 4 friends                     3 each, 0 over
14 apples shared by 4 friends                     3 each, 2 over
cross-check, 4 lots of 3, plus 2                       14 apples
any number of 0s adding up to 12               0 found under 100
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, no crates.

```rust
// Multiplying and dividing -- the same check as multiplying_and_dividing_check.py.
// Standard library only, no crates.  The plain way first, then the same answers
// again by adding, as a cross-check.
// Compile: rustc --edition 2021 -O multiplying_and_dividing_check.rs -o /tmp/muldiv

fn added_up(count: i64, size: i64) -> i64 {   // size added to itself, count times over
    let mut total = 0;
    for _ in 0..count {
        total = total + size;
    }
    total
}

fn row(label: &str, value: String) {
    println!("{:<36}{:>28}", label, value);
}

fn main() {
    let cost = 12 * 75;                        // twelve apples at 75 cents each
    let change = 1000 - cost;                  // handed over a $10 bill, 1000 cents
    let (each, over) = (cost / 4, cost % 4);   // the money split four ways
    let zeros = (0..100).filter(|&q| added_up(q, 0) == 12).count();  // nothing works
    assert!(cost == added_up(12, 75), "adding 75 twelve times must give the same total");
    assert!(added_up(each, 4) + over == cost, "four lots of 225 must rebuild the 900");
    assert!(added_up(14 / 4, 4) + 14 % 4 == 14, "three each and two over must rebuild 14");
    row("12 apples at 75 cents each", format!("{} cents", cost));
    row("that in dollars", format!("{}.{:02}", cost / 100, cost % 100));
    row("change from the 1000-cent bill", format!("{} cents", change));
    row("cross-check, 75 added 12 times", format!("{} cents", added_up(12, 75)));
    row("900 cents shared by 4 friends", format!("{} each, {} over", each, over));
    row("each friend pays, in dollars", format!("{}.{:02}", each / 100, each % 100));
    row("cross-check, 4 lots of 225", format!("{} cents", added_up(each, 4) + over));
    row("12 apples shared by 4 friends", format!("{} each, {} over", 12 / 4, 12 % 4));
    row("14 apples shared by 4 friends", format!("{} each, {} over", 14 / 4, 14 % 4));
    row("cross-check, 4 lots of 3, plus 2", format!("{} apples", added_up(14 / 4, 4) + 14 % 4));
    row("any number of 0s adding up to 12", format!("{} found under 100", zeros));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
12 apples at 75 cents each                             900 cents
that in dollars                                             9.00
change from the 1000-cent bill                         100 cents
cross-check, 75 added 12 times                         900 cents
900 cents shared by 4 friends                   225 each, 0 over
each friend pays, in dollars                                2.25
cross-check, 4 lots of 225                             900 cents
12 apples shared by 4 friends                     3 each, 0 over
14 apples shared by 4 friends                     3 each, 2 over
cross-check, 4 lots of 3, plus 2                       14 apples
any number of 0s adding up to 12               0 found under 100
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess the answer first. Then run it.
> - **Put the price up to 80 cents.** Change both 75s: the cost line and its cross-check.
> - **Make it seven friends.** Change the 4s in the sharing line and its cross-check. The money stops dividing evenly; the rebuild still holds.

---

## The usual mistake

> [!warning]
> **Believing "divided by zero" has a hidden answer, zero or infinity.** It has neither. Division is multiplication backwards, so "12 shared by 0" asks what number of zeros adds up to 12. The check finds 0 of them.
>
> Two smaller traps:
> - **Dropping the remainder.** Handing 3 apples each out of 14 accounts for 12 and loses two.
> - **Swapping the numbers when dividing.** Multiplying can be swapped, dividing cannot: 12 apples shared by 4 friends is nothing like 4 shared by 12.

---

## Where you meet it in real life

- **The shelf label.** The price per unit is a division: the pack price shared over what is in the pack.
- **Splitting a bill.** The total shared by the table, and the odd cents that will not divide are a remainder.
- **Time.** Minutes into hours, days into weeks: a division, and the remainder is what you say out loud.

> **Say it back**
> Multiplying is adding the same number again and again, in one move: 12 apples at 75 cents is 900 cents, and the $10 bill leaves a dollar of change. It works because a block of dots counts the same whichever way you turn it, so order does not matter. Dividing is that block backwards: hand the pile round until you cannot go again, and what is left is the remainder.

---

## What this builds on

- [place-value](01-place-value.md): reading 900 as nine hundred, a $10 bill as 1000 cents.
- [adding-and-subtracting](02-adding-and-subtracting.md): the cross-check here is nothing but adding.

## Where this goes next

- [order-of-operations](04-order-of-operations.md): which goes first when they share a line.
- [fractions](07-fractions.md): what to do with the two apples left over. Cut them.
- [exponents-and-powers](../03-Powers%2C%20Roots%20and%20Logarithms/01-exponents-and-powers.md): multiplying a number by itself, over and over.

---

## Sources

Verified 6 Sep 2026: every link below resolves to the publisher's page.

- Euclid. *Elements*, Book VII, Propositions 1 and 2, in Joyce's edition. [VII.1](https://mathcs.clarku.edu/~djoyce/elements/bookVII/propVII1.html) and [VII.2](https://mathcs.clarku.edu/~djoyce/elements/bookVII/propVII2.html). Dividing as repeated taking away.
- Weisstein, Eric W. "Division by Zero." *MathWorld*. [mathworld.wolfram.com](https://mathworld.wolfram.com/DivisionbyZero.html). Why it is left undefined.
- Python documentation, the built-in [divmod](https://docs.python.org/3/library/functions.html#divmod). Share and leftover, handed back together.
