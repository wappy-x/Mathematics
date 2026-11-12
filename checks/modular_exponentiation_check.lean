-- Powers on the clock: square-and-multiply, keeping only the remainder after every step, always gives the remainder of b to the e divided by n, with at most two multiplications per halving of e and no product as big as n × n.
import Mathlib.Data.Nat.Log
import Mathlib.Tactic.NormNum.Pow
import Mathlib.Tactic.NormNum.DivMod

/-- Square-and-multiply on a clock of size n. Day 0 reads 1 and day 1 reads the base b (its
remainder). For a day count of 2 or more: halve it, dropping the spare day when it is odd, find
that reading, square it and keep the remainder; on an odd day count multiply once more by the base
and keep the remainder again. -/
def ladder (b n : ℕ) : ℕ → ℕ
  | 0 => 1 % n
  | 1 => b % n
  | e + 2 =>
    let r := ladder b n ((e + 2) / 2)
    if (e + 2) % 2 = 0 then r * r % n else r * r % n * (b % n) % n
decreasing_by omega

/-- How many multiplications the ladder makes: none for day 0 or day 1, and on each rung above
one squaring plus one more multiplication by the base when the day count is odd. -/
def ladderMults : ℕ → ℕ
  | 0 => 0
  | 1 => 0
  | e + 2 => ladderMults ((e + 2) / 2) + 1 + (e + 2) % 2
decreasing_by omega

/-- Modular exponentiation by square-and-multiply is correct. For every base b, every whole-number
day count e and every clock size n, climbing the ladder (square on each rung, one more b on the
odd rungs, throw away everything but the remainder after each multiplication) gives exactly the
remainder of b to the power e divided by n: the same reading as multiplying by b one night at a
time. -/
theorem square_and_multiply_gives_power_mod (b e n : ℕ) : ladder b n e = b ^ e % n := by
  induction e using Nat.strong_induction_on with
  | _ e ih =>
    match e, ih with
    | 0, _ => simp [ladder]
    | 1, _ => simp [ladder]
    | e + 2, ih =>
      rw [ladder]
      have h := ih ((e + 2) / 2) (by omega)
      simp only [h]
      have hsq : b ^ ((e + 2) / 2) % n * (b ^ ((e + 2) / 2) % n) % n
          = b ^ (2 * ((e + 2) / 2)) % n := by
        rw [← Nat.mul_mod, two_mul, pow_add]
      split_ifs with hp
      · rw [hsq]
        congr 1
        congr 1
        omega
      · have h2 : e + 2 = 2 * ((e + 2) / 2) + 1 := by omega
        have h3 : b ^ (e + 2) = b ^ (2 * ((e + 2) / 2)) * b := by
          rw [← pow_succ]
          congr 1
        rw [hsq, h3, Nat.mul_mod_mod, Nat.mod_mul_mod]

/-- The ladder is short. For a day count e of at least 1, it makes at most two multiplications per
halving, at most 2 × log₂ e in all; and doubling the day count adds one rung, one multiplication,
not double the work. -/
theorem ladder_uses_at_most_two_multiplications_per_halving (e : ℕ) (he : 1 ≤ e) :
    ladderMults e ≤ 2 * Nat.log 2 e ∧ ladderMults (2 * e) = ladderMults e + 1 := by
  constructor
  · induction e using Nat.strong_induction_on with
    | _ e ih =>
      match e, ih, he with
      | 1, _, _ => simp [ladderMults]
      | e + 2, ih, _ =>
        rw [ladderMults]
        have h := ih ((e + 2) / 2) (by omega) (by omega)
        have hl : Nat.log 2 (e + 2) = Nat.log 2 ((e + 2) / 2) + 1 := by
          rw [Nat.log_div_base]
          have : 1 ≤ Nat.log 2 (e + 2) := Nat.log_pos (by norm_num) (by omega)
          omega
        omega
  · obtain ⟨k, rfl⟩ : ∃ k, e = k + 1 := ⟨e - 1, by omega⟩
    have : 2 * (k + 1) = (2 * k) + 2 := by omega
    rw [this, ladderMults]
    have h1 : (2 * k + 2) / 2 = k + 1 := by omega
    have h2 : (2 * k + 2) % 2 = 0 := by omega
    rw [h1, h2]

/-- What falls off never piles up. On a clock of size n, every reading on the ladder is a
remainder, so both products the ladder forms on the next rung, the squaring and the extra
multiplication by the base, stay below n × n. -/
theorem ladder_products_stay_below_modulus_squared (b n e : ℕ) (hn : 0 < n) :
    ladder b n e * ladder b n e < n * n ∧
      ladder b n e * ladder b n e % n * (b % n) < n * n := by
  have h : ladder b n e < n := by
    rw [square_and_multiply_gives_power_mod]
    exact Nat.mod_lt _ hn
  constructor
  · exact Nat.mul_lt_mul'' h h
  · exact Nat.mul_lt_mul'' (Nat.mod_lt _ hn) (Nat.mod_lt _ hn)

-- The question: 7 to the 123, mod 1000, is 343.
example : 7 ^ 123 % 1000 = 343 := by norm_num
-- The day counts halve to 1: 123, 61, 30, 15, 7, 3, 1.
example : 123 / 2 = 61 ∧ 61 / 2 = 30 ∧ 30 / 2 = 15 ∧ 15 / 2 = 7 ∧ 7 / 2 = 3 ∧ 3 / 2 = 1 := by
  decide
-- Climbing back by hand: 7, 343, 543, 943, 249, 7, 343.
example : 7 * 7 % 1000 * 7 % 1000 = 343 ∧ 343 * 343 % 1000 * 7 % 1000 = 543 ∧
    543 * 543 % 1000 * 7 % 1000 = 943 ∧ 943 * 943 % 1000 = 249 ∧
    249 * 249 % 1000 * 7 % 1000 = 7 ∧ 7 * 7 % 1000 * 7 % 1000 = 343 := by decide
-- The ladder itself on the card's rungs.
example : ladder 7 1000 1 = 7 ∧ ladder 7 1000 3 = 343 ∧ ladder 7 1000 7 = 543 ∧
    ladder 7 1000 15 = 943 ∧ ladder 7 1000 30 = 249 ∧ ladder 7 1000 61 = 7 ∧
    ladder 7 1000 123 = 343 := by decide +kernel
-- Eleven multiplications instead of 123.
example : ladderMults 123 = 11 := by decide +kernel
-- Day 7 with nothing thrown away is 823543, which still ends in 543; the biggest product is 889249.
example : 7 ^ 7 = 823543 ∧ 823543 % 1000 = 543 ∧ 943 * 943 = 889249 := by norm_num
-- Day 4: the true number is 2401 and the counter shows 401.
example : 7 ^ 4 = 2401 ∧ 2401 % 1000 = 401 := by norm_num
-- Skipping the spare 7s: six squarings reach day 64, which reads 401, not 343.
example : 7 ^ 64 % 1000 = 401 := by norm_num

#print axioms square_and_multiply_gives_power_mod
#print axioms ladder_uses_at_most_two_multiplications_per_halving
#print axioms ladder_products_stay_below_modulus_squared
