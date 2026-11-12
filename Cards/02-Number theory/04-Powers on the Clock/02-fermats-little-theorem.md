# Fermat's little theorem: raise a number the prime dial does not divide to one below the dial size and it reads 1

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Powers on the Clock](../README.md#s04) → Fermat's little theorem

---

## General Overview

A lock dial with 13 positions, numbered 0 to 12. Set it to 1 and double: 2, 4, 8, then 16, which runs off the end, so the dial comes round to 3 ([Congruence](../03-Clock%20Arithmetic/01-congruence-mod-n.md)). Keep doubling. After twelve doublings it reads 1 again: 4,096 is 315 whole dials and 1 over.

Twelve is one less than 13, and 13 is **prime**: nothing divides it but itself and 1 ([Primes and composites](../01-Divisibility%20and%20Primes/05-primes-and-composites.md)). Take any number 13 does not divide, start at 1 and multiply by it twelve times, and the dial reads 1.

**On a prime-sized dial, take a number the dial size does not divide, start at 1 and multiply by it one time fewer than there are positions: the reading is 1.**

**What kind of fact this is:** a theorem, proved on this card in Why it works.

Fermat stated it without proof in a letter to Frénicle de Bessy, 18 October 1640. It is his *little* theorem, not the Last Theorem. Huge powers get cheap: 2 taken a thousand times over runs to 302 digits; this drops the work to four multiplications.

### The picture: doubling deals the dial to itself

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Where doubling sends each position on a 13-position dial"
    x-axis "The position you start on" [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    y-axis "The position doubling lands on" 0 --> 13
    line [2, 4, 6, 8, 10, 12, 1, 3, 5, 7, 9, 11]
```

The line climbs, falls off the top, climbs again. Twelve starting positions, twelve landings, each used once. That shuffle is the engine of the proof.

---

## The formula

The dial is the statement:

**Start at 1 and multiply by 2 twelve times = 4,096 = 315 × 13 + 1, so the 13-dial reads 1**

**Read it aloud:** 2 multiplied in twelve times makes 4,096; take off 315 whole turns of the 13-dial and 1 is left.

| Piece | Plain meaning | Here |
| --- | --- | --- |
| the dial size | how many positions there are, and it must be prime | 13 |
| the number | what you multiply by | 2 |
| the power | one less than the dial size | 12 |
| the reading | what is left when whole dials come off | 1 |

With letters, the dial size is p, for prime, and the number a, which p must not divide: a to the p − 1 ≡ 1 (mod p). The ≡ means the same reading on the dial; the (mod p) says which dial.

One more doubling takes that 1 back to 2: 2 taken thirteen times over is 8,192, and the dial reads 2. That second form, a to the p ≡ a (mod p), needs no condition.

### When it holds

- **The dial size is prime.** On a 15-dial, 2 taken fourteen times over reads 4, not 1.
- **The dial size does not divide the number.** Start from 26 on the 13-dial: it reads 0.
- **The power is one less than the dial size.** 2 taken thirteen times over reads 2, not 1.

---

## Why it works

### Step 0: doubling deals the positions out again

The live positions are 1 to 12; 0 is stuck, leave it out. Double each and take off whole dials: 2, 4, 6, 8, 10, 12, 1, 3, 5, 7, 9, 11. The same twelve numbers, shuffled.

### Step 1: nothing lands on 0, nothing lands twice

Doubling lands on 0 only if 13 divides twice the position, and 13 is prime, so it would divide the 2 or the position; it divides neither ([Euclid's lemma](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/06-euclids-lemma.md)). Nor can two land together: doubling can be undone, and an undoable move cannot merge two things ([The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md)).

### Step 2: twelve into twelve means the same twelve

Twelve go in, twelve come out, none 0, none repeated. There are only twelve non-zero readings, so all get used.

### Step 3: multiply the row, two ways

The row multiplied: 1 × 2 × 3 × … × 12 = 479,001,600. The doubled row, before dials come off, is the same twelve each carrying a 2: 4,096 × 479,001,600 = 1,961,990,553,600. The same twelve readings, so both products read 12.

### Step 4: cancel the row

So 4,096 times the row's product reads the same as that product alone. It cancels: every factor, 1 up to 12, is smaller than the prime 13, so 13 cannot divide it ([Euclid's lemma](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/06-euclids-lemma.md)), and what 13 does not divide has an undo ([The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md)). Multiply both sides by it.

What is left is 4,096 alone, reading 1. That is the theorem.

The other classical route expands a bracket raised to a power, every middle term carrying a factor of 13. Drop the word prime from the statement and you get [Euler's theorem](04-eulers-theorem.md), the same shuffle over a shorter row.

---

## Worked numbers, by hand

2 taken a thousand times over, on the 13-dial. Readings repeat every twelve steps, so only the leftover matters. Some starting numbers repeat sooner, but the shorter loop's length always divides twelve.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the round trip | 4,096 = 315 × 13 + 1 | 1 |
| split the thousand | 1000 ÷ 12 | 83, remainder 4 |
| what is left | 16 − 13 | **3** |
| the long way, as a check | 2, a thousand times | **3** |

The 83 round trips each read 1, so they cost nothing; only 2 taken four times over is left, 16, reading 3.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Splitting the thousand by 13 | 1 | 12 is left, a whole round trip |
| Starting from 26, a multiple of 13 | 0 | 26 sits on 0 and stays |
| A 15-dial, power 14 | 4 | 15 is 3 × 5, so the row will not cancel |

Doubling still shuffles this 15-dial; the cancelling is what dies.

---

## Code, from first principles, and it actually runs

Nothing is imported. The dial is built by hand: multiply, take off whole dials, repeat. The thousandth power is worked twice, long way and short.

### Python

```python
# Fermat's little theorem -- the check behind the card.  Nothing is imported.  A
# 13-position lock dial, base 2: twelve doublings land on 1, the twelve doubled
# positions are the twelve positions shuffled, and 2 to the 1000 collapses to 3.
DIAL, BASE = 13, 2

def turn(base, times, dial):      # the reading after that many multiplications
    out = 1
    for _ in range(times): out = (out * base) % dial
    return out

def row(name, value): print(f"{name:<44}{value:>14}")
whole, left = BASE ** (DIAL - 1), 1000 % (DIAL - 1)   # 4096 in full; 1000 split by 12
doubles = [(BASE * k) % DIAL for k in range(1, DIAL)]
plain, shuffled = 1, 1                                # 1 x 2 x ... x 12, and each doubled
for k in range(1, DIAL): plain, shuffled = plain * k, shuffled * (BASE * k)
row("2 doubled twelve times", whole)
row(f"{whole} = {whole // DIAL} x {DIAL} + 1, so the dial shows", whole % DIAL)
row(f"2 to the {DIAL} = {BASE ** DIAL}, so the dial shows", turn(BASE, DIAL, DIAL))
print("1 to 12, each doubled: " + " ".join(str(d) for d in doubles))
row("1 to 12 multiplied", plain)
row("the twelve doubles multiplied", shuffled)
row("both of those, on the 13-dial", plain % DIAL)
row(f"1000 = {1000 // (DIAL - 1)} x {DIAL - 1} + {left}, leftover exponent", left)
row(f"2 to the {left} = {BASE ** left}, so the dial shows", turn(BASE, left, DIAL))
row("2 to the 1000 the long way, on the 13-dial", turn(BASE, 1000, DIAL))
print(f"gone wrong: cut by 13 -> {turn(BASE, 1000 % DIAL, DIAL)}, base 26 -> {turn(2 * DIAL, DIAL - 1, DIAL)}, 14 on a 15-dial ({BASE ** 14}) -> {turn(BASE, 14, 15)}")
assert whole == 4096 and whole == 315 * DIAL + 1 and turn(BASE, DIAL - 1, DIAL) == 1
assert sorted(doubles) == list(range(1, DIAL)) and shuffled % DIAL == plain % DIAL == 12
assert turn(BASE, 1000, DIAL) == turn(BASE, left, DIAL) == 16 % DIAL == 3
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
2 doubled twelve times                                4096
4096 = 315 x 13 + 1, so the dial shows                   1
2 to the 13 = 8192, so the dial shows                    2
1 to 12, each doubled: 2 4 6 8 10 12 1 3 5 7 9 11
1 to 12 multiplied                               479001600
the twelve doubles multiplied                1961990553600
both of those, on the 13-dial                           12
1000 = 83 x 12 + 4, leftover exponent                    4
2 to the 4 = 16, so the dial shows                       3
2 to the 1000 the long way, on the 13-dial               3
gone wrong: cut by 13 -> 1, base 26 -> 0, 14 on a 15-dial (16384) -> 4
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Fermat's little theorem -- the same check as the Python one, in Rust.  No crates.
// A 13-position lock dial, base 2: twelve doublings land on 1, the twelve doubled
// positions are the twelve positions shuffled, and 2 to the 1000 collapses to 3.
const DIAL: i64 = 13;
const BASE: i64 = 2;

fn turn(base: i64, times: i64, dial: i64) -> i64 {   // the reading after that many multiplications
    let mut out = 1;
    for _ in 0..times { out = (out * base) % dial; }
    out
}

fn row(name: &str, value: i64) { println!("{:<44}{:>14}", name, value); }

fn main() {
    let whole = BASE.pow(DIAL as u32 - 1);           // 4096, written out in full
    let left = 1000 % (DIAL - 1);                    // 1000 split by 12
    let doubles: Vec<i64> = (1..DIAL).map(|k| (BASE * k) % DIAL).collect();
    let (mut plain, mut shuffled) = (1i64, 1i64);    // 1 x 2 x ... x 12, and each doubled
    for k in 1..DIAL { plain *= k; shuffled *= BASE * k; }
    let marks: Vec<String> = doubles.iter().map(|d| d.to_string()).collect();
    row("2 doubled twelve times", whole);
    row(&format!("{} = {} x {} + 1, so the dial shows", whole, whole / DIAL, DIAL), whole % DIAL);
    row(&format!("2 to the {} = {}, so the dial shows", DIAL, BASE.pow(DIAL as u32)), turn(BASE, DIAL, DIAL));
    println!("1 to 12, each doubled: {}", marks.join(" "));
    row("1 to 12 multiplied", plain);
    row("the twelve doubles multiplied", shuffled);
    row("both of those, on the 13-dial", plain % DIAL);
    row(&format!("1000 = {} x {} + {}, leftover exponent", 1000 / (DIAL - 1), DIAL - 1, left), left);
    row(&format!("2 to the {} = {}, so the dial shows", left, BASE.pow(left as u32)), turn(BASE, left, DIAL));
    row("2 to the 1000 the long way, on the 13-dial", turn(BASE, 1000, DIAL));
    println!("gone wrong: cut by 13 -> {}, base 26 -> {}, 14 on a 15-dial ({}) -> {}",
             turn(BASE, 1000 % DIAL, DIAL), turn(2 * DIAL, DIAL - 1, DIAL), BASE.pow(14), turn(BASE, 14, 15));
    let mut sorted = doubles.clone(); sorted.sort();
    assert!(whole == 4096 && whole == 315 * DIAL + 1 && turn(BASE, DIAL - 1, DIAL) == 1);
    assert!(sorted == (1..DIAL).collect::<Vec<i64>>() && shuffled % DIAL == 12 && plain % DIAL == 12);
    assert!(turn(BASE, 1000, DIAL) == 16 % DIAL && turn(BASE, left, DIAL) == 3);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
2 doubled twelve times                                4096
4096 = 315 x 13 + 1, so the dial shows                   1
2 to the 13 = 8192, so the dial shows                    2
1 to 12, each doubled: 2 4 6 8 10 12 1 3 5 7 9 11
1 to 12 multiplied                               479001600
the twelve doubles multiplied                1961990553600
both of those, on the 13-dial                           12
1000 = 83 x 12 + 4, leftover exponent                    4
2 to the 4 = 16, so the dial shows                       3
2 to the 1000 the long way, on the 13-dial               3
gone wrong: cut by 13 -> 1, base 26 -> 0, 14 on a 15-dial (16384) -> 4
ALL CHECKS PASS
```

### Lean

Lean proves the theorem for every prime dial and every whole number, not just 13 and 2. It proves both forms on this card and the shuffle the proof rests on, and it re-checks the card's 13-dial numbers. The printed tables and the long-way runs stay with the Python and Rust checks.

<details>
<summary>The Lean proof, 80 lines</summary>

```lean
-- Fermat's little theorem: for a prime p and a whole number a that p does not divide, a to the power p − 1 leaves remainder 1 on division by p, and a to the power p always reads a.
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Data.Int.GCD
import Mathlib.Tactic.NormNum.Prime

/-- Fermat's little theorem, as the card states it: on a prime-sized dial p, take a number a
that the dial size does not divide, start at 1 and multiply by a one time fewer than there are
positions (p − 1 times); the dial reads 1, that is a ^ (p − 1) ≡ 1 (mod p). -/
theorem fermat_little_pow_pred_eq_one (p : ℕ) (hp : p.Prime) (a : ℤ) (ha : ¬ (p : ℤ) ∣ a) :
    a ^ (p - 1) ≡ 1 [ZMOD p] := by
  have hcop : IsCoprime a (p : ℤ) := by
    have hirr : Irreducible (p : ℤ) := (Nat.prime_iff_prime_int.mp hp).irreducible
    exact ((Irreducible.coprime_iff_not_dvd hirr).mpr ha).symm
  exact Int.ModEq.pow_card_sub_one_eq_one hp hcop

/-- The second form, which needs no condition on the number: on a prime-sized dial p, multiply
by a as many times as there are positions and the dial reads a, that is a ^ p ≡ a (mod p). -/
theorem fermat_little_pow_self (p : ℕ) (hp : p.Prime) (a : ℤ) :
    a ^ p ≡ a [ZMOD p] := by
  exact Int.ModEq.pow_prime_eq_self hp a

/-- The engine of the proof: on a prime dial p, multiplying every live position 1, …, p − 1 by a
number a that p does not divide deals the same p − 1 positions out again, shuffled; nothing
lands on 0 and nothing lands twice. -/
theorem fermat_multiply_shuffles_live_positions (p : ℕ) (hp : p.Prime) (a : ℕ) (ha : ¬ p ∣ a) :
    (Finset.Icc 1 (p - 1)).image (fun k => a * k % p) = Finset.Icc 1 (p - 1) := by
  have hcop : Nat.gcd p a = 1 := (Nat.Prime.coprime_iff_not_dvd hp).mpr ha
  have hsub : (Finset.Icc 1 (p - 1)).image (fun k => a * k % p) ⊆ Finset.Icc 1 (p - 1) := by
    intro x hx
    simp only [Finset.mem_image, Finset.mem_Icc] at hx ⊢
    obtain ⟨k, ⟨hk1, hk2⟩, rfl⟩ := hx
    constructor
    · rcases Nat.eq_zero_or_pos (a * k % p) with h | h
      · exfalso
        have hdvd : p ∣ a * k := Nat.dvd_of_mod_eq_zero h
        rcases (Nat.Prime.dvd_mul hp).mp hdvd with h' | h'
        · exact ha h'
        · have := Nat.le_of_dvd (by omega) h'
          omega
      · omega
    · have := Nat.mod_lt (a * k) hp.pos
      omega
  have hinj : Set.InjOn (fun k => a * k % p) (Finset.Icc 1 (p - 1) : Set ℕ) := by
    intro k hk l hl hkl
    simp only [Finset.coe_Icc, Set.mem_Icc] at hk hl
    have h : a * k ≡ a * l [MOD p] := hkl
    have h2 : k ≡ l [MOD p] := Nat.ModEq.cancel_left_of_coprime hcop h
    unfold Nat.ModEq at h2
    rwa [Nat.mod_eq_of_lt (by omega), Nat.mod_eq_of_lt (by omega)] at h2
  apply Finset.eq_of_subset_of_card_le hsub
  rw [Finset.card_image_of_injOn hinj]

-- 13 is prime; twelve doublings make 4,096 = 315 × 13 + 1, so the 13-dial reads 1.
example : Nat.Prime 13 := by norm_num
example : 2 ^ 12 = 4096 ∧ 4096 = 315 * 13 + 1 := by norm_num
example : 2 ^ 12 % 13 = 1 := by norm_num
example : (2 : ℤ) ^ 12 ≡ 1 [ZMOD 13] := by decide
-- One more doubling: 2 ^ 13 = 8,192, and the dial reads 2.
example : 2 ^ 13 = 8192 ∧ 2 ^ 13 % 13 = 2 := by norm_num
-- Doubling deals 1 to 12 out again: 2, 4, 6, 8, 10, 12, 1, 3, 5, 7, 9, 11.
example : (List.range' 1 12).map (fun k => 2 * k % 13) = [2, 4, 6, 8, 10, 12, 1, 3, 5, 7, 9, 11] := by
  decide
-- The row multiplied, and the doubled row: both read 12 on the 13-dial.
example : Nat.factorial 12 = 479001600 := by decide
example : 4096 * 479001600 = 1961990553600 := by norm_num
example : 479001600 % 13 = 12 ∧ 1961990553600 % 13 = 12 := by norm_num
-- 2 taken a thousand times over: 1000 = 83 × 12 + 4, 2 ^ 4 = 16 reads 3, and so does 2 ^ 1000.
example : 1000 = 83 * 12 + 4 := by norm_num
example : 2 ^ 4 % 13 = 3 := by norm_num
example : 2 ^ 1000 % 13 = 3 := by decide +kernel
-- What breaks: splitting 1000 by 13 leaves 12, which reads 1; 26 reads 0; a 15-dial reads 4.
example : 1000 % 13 = 12 ∧ 2 ^ 12 % 13 = 1 := by norm_num
example : 26 ^ 12 % 13 = 0 := by decide
example : 2 ^ 14 = 16384 ∧ 2 ^ 14 % 15 = 4 ∧ ¬ Nat.Prime 15 := by norm_num
-- The undo of 2 on the 13-dial: 2 ^ 11 reads 7, and 2 × 7 is one dial and 1 over.
example : 2 ^ 11 % 13 = 7 ∧ 2 * 7 = 1 * 13 + 1 := by norm_num

#print axioms fermat_little_pow_pred_eq_one
#print axioms fermat_little_pow_self
#print axioms fermat_multiply_shuffles_live_positions
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'fermat_little_pow_pred_eq_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'fermat_little_pow_self' depends on axioms: [propext, Classical.choice, Quot.sound]
'fermat_multiply_shuffles_live_positions' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to house numbers, so expect one to fire.
> - **Start from 3.** Set the base to 3: the row still shuffles, the twelfth power still reads 1, the thousandth still reads 3. Only the first assert fires.
> - **Move to a 15-dial.** Set the dial to 15 and the power to 14: the reading is 4, the last wrong answer above.

---

## The usual mistake

> [!warning]
> **Cutting the power down by the dial size instead of by one less.** On the 13-dial, split 1000 by **12**, not by 13. Twelve steps is the round trip. Split by 13 and the leftover of 12 answers 1 instead of 3.
>
> - **Forgetting the exclusion.** Start from 26 and the reading is 0 forever: multiples of the dial size are stuck.
> - **A dial that is not prime.** A 15-dial with power 14 reads 4. The fix is a different count: [Euler's theorem](04-eulers-theorem.md).
> - **Reading it backwards.** A prime dial always gives 1. That only prime dials do is a different claim, and false: [The Fermat test](../06-Codes%20and%20Secrets/04-fermat-test-and-carmichael.md).

---

## Where you meet it in real life

- **Dividing on a prime dial.** The dial does not divide 2, so its undo is 2 raised to the power two below the dial size: 2 to the 11 is 7, and 2 × 7 is one dial and 1 over ([The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md), [Powers on the clock](01-modular-exponentiation.md)).
- **Screening primes at speed.** Software hunting big primes throws a power at a candidate and reads the dial: failure means composite ([The Fermat test](../06-Codes%20and%20Secrets/04-fermat-test-and-carmichael.md)).
- **Public-key encryption.** A message decrypts back to itself because of this fact in Euler's wider form: [Euler's theorem](04-eulers-theorem.md), then [RSA in outline](../06-Codes%20and%20Secrets/03-rsa-in-outline.md).

> **Say it back**
> Take a prime-sized dial, 13, and a number it does not divide, 2. Twelve multiplications, one less than 13, and it reads 1. Multiplying every position by 2 only deals the same twelve out in a new order, so the row's product is unchanged; cancel it and 1 remains. That is why huge powers shrink: 2 taken a thousand times over reads 3, like 2 taken four times over.

---

## What this builds on

- [Congruence](../03-Clock%20Arithmetic/01-congruence-mod-n.md): what a reading on a dial means.
- [Euclid's lemma](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/06-euclids-lemma.md): a prime dividing a product divides a factor, used in Steps 1 and 4.
- [The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md): undoing a multiplication, used in Steps 1 and 4.
- [Powers on the clock](01-modular-exponentiation.md): powers on a clock without the huge number.
- [Exponents](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/01-exponents-and-powers.md): what "taken twelve times over" means.

## Where this goes next

- [Euler's theorem](04-eulers-theorem.md): the same statement without the word prime.
- [The Fermat test](../06-Codes%20and%20Secrets/04-fermat-test-and-carmichael.md): the theorem as a primality test, and the composites that pass anyway.

Left open: on a dial that is not prime, like 15, what power brings the reading back to 1?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Euler, Leonhard. "Theorematum quorundam ad numeros primos spectantium demonstratio" (1741). [Euler Archive, E54](https://scholarlycommons.pacific.edu/euler-works/54/). The first published proof.
- Gauss, Carl Friedrich. *Disquisitiones Arithmeticae*, 1801. [Wikisource, Third Section](https://en.wikisource.org/wiki/Translation:Disquisitiones_Arithmeticae/Third_Section), free; [Clarke translation](https://yalebooks.yale.edu/book/9780300094732/disquisitiones-arithmeticae/), paid. Articles 49 to 51, the shuffle made standard.
- Ireland, Kenneth, and Michael Rosen. *A Classical Introduction to Modern Number Theory*, 2nd ed. Springer, 1990. [doi:10.1007/978-1-4757-2103-4](https://link.springer.com/book/10.1007/978-1-4757-2103-4). Chapter 4, the theorem in its wider setting.
