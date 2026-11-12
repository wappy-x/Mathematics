-- Exponents: for a nonzero base and whole-number or negative exponents, multiplying powers adds the exponents, dividing subtracts them and a power of a power multiplies them; the subtraction rule forces a zero exponent to give 1 and a negative exponent to give 1 over the matching power; and the card's chain-message numbers come out exactly as it says.
import Mathlib.Algebra.GroupWithZero.Units.Basic
import Mathlib.Algebra.Field.Basic
import Mathlib.Algebra.Field.Rat
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

/-- The three rules of exponents. Take a base `a` that is not 0 and exponents `m`, `n` that
are whole numbers or their negatives. Multiplying powers of the same base adds the exponents,
`a^m × a^n = a^(m + n)`; dividing subtracts them, `a^m ÷ a^n = a^(m − n)`; and a power of a
power multiplies them, `(a^m)^n = a^(m × n)`. -/
theorem exponent_rules_add_subtract_multiply {K : Type*} [Field K] (a : K) (ha : a ≠ 0)
    (m n : ℤ) :
    a ^ m * a ^ n = a ^ (m + n) ∧ a ^ m / a ^ n = a ^ (m - n) ∧ (a ^ m) ^ n = a ^ (m * n) := by
  refine ⟨(zpow_add₀ ha m n).symm, (zpow_sub₀ ha m n).symm, (zpow_mul a m n).symm⟩

/-- Zero and negative powers have only one possible meaning. Take a base `a` that is not 0,
and any way `f` of giving a value to every whole-number or negative exponent. Suppose it agrees
with repeated multiplication for every count of 1 or more (`f n = a × a × ⋯ × a`, `n` copies),
and keeps the subtraction rule, `f (m − n) = f m ÷ f n`, for all whole numbers `m`, `n`. Then
the zero power must be 1, and the power `−n` must be 1 divided by the matching power `a^n`. -/
theorem zero_and_negative_powers_are_forced {K : Type*} [Field K] (a : K) (ha : a ≠ 0)
    (f : ℤ → K)
    (h_count : ∀ n : ℕ, 0 < n → f n = a ^ n)
    (h_sub : ∀ m n : ℕ, f ((m : ℤ) - n) = f m / f n) :
    f 0 = 1 ∧ ∀ n : ℕ, f (-(n : ℤ)) = 1 / a ^ n := by
  have h1 : f 1 = a := by simpa using h_count 1 (by norm_num)
  have h0 : f 0 = 1 := by
    have := h_sub 1 1
    simp only [Nat.cast_one, sub_self] at this
    rw [this, h1]
    exact div_self ha
  refine ⟨h0, fun n => ?_⟩
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp [h0]
  · have := h_sub 0 n
    simp only [Nat.cast_zero, zero_sub] at this
    rw [this, h0, h_count n hn]

-- The definition: 3^5 is five 3s multiplied together, round 5 of the chain.
example : (3 : ℚ) ^ 5 = 3 * 3 * 3 * 3 * 3 := by norm_num
example : (3 : ℚ) ^ 5 = 243 := by norm_num
example : (3 : ℚ) ^ 1 = 3 := by norm_num
example : (3 : ℚ) ^ 2 = 3 * 3 := by norm_num
example : (3 : ℚ) ^ 2 = 9 := by norm_num
-- The six rounds, and everyone holding the message.
example : (List.range 6).map (fun r => 3 ^ r) = [1, 3, 9, 27, 81, 243] := by decide
example : (1 : ℕ) + 3 + 9 + 27 + 81 + 243 = 364 := by norm_num
example : ∑ r ∈ Finset.range 6, (3 : ℕ) ^ r = 364 := by decide
example : (List.range 6).map (fun r => ∑ i ∈ Finset.range (r + 1), (3 : ℕ) ^ i) =
    [1, 4, 13, 40, 121, 364] := by decide
-- Round 5 by the other road: 3^2 × 3^3, or 9 × 27.
example : (3 : ℚ) ^ 2 * 3 ^ 3 = 3 ^ 5 := by norm_num
example : (9 : ℚ) * 27 = 243 := by norm_num
-- A power of a power: (3^2)^3 is 9 × 9 × 9, or 3^6.
example : ((3 : ℚ) ^ 2) ^ 3 = 3 ^ 6 := by norm_num
example : (9 : ℚ) * 9 * 9 = 729 := by norm_num
example : (3 : ℚ) ^ 6 = 729 := by norm_num
-- The ratios: 3^5 ÷ 3^2, 3^5 ÷ 3^5 and 3^2 ÷ 3^5, as plain fractions and as integer powers.
example : (243 : ℚ) / 9 = 27 := by norm_num
example : (3 : ℚ) ^ (5 : ℤ) / 3 ^ (2 : ℤ) = 3 ^ (3 : ℤ) := by norm_num
example : (243 : ℚ) / 243 = 1 := by norm_num
example : (3 : ℚ) ^ (0 : ℤ) = 1 := by norm_num
example : (9 : ℚ) / 243 = 1 / 27 := by norm_num
example : (3 : ℚ) ^ (-3 : ℤ) = 1 / 27 := by norm_num
example : (3 : ℚ) ^ (2 : ℤ) / 3 ^ (5 : ℤ) = 3 ^ (-3 : ℤ) := by norm_num
-- The ladder read backwards ends at round 0: 3 ÷ 3 = 1.
example : (3 : ℚ) / 3 = 1 := by norm_num
-- The three mistakes come out at 729, 15 and −27, none of them the right answer.
example : (3 : ℚ) ^ 6 = 729 ∧ (3 : ℚ) ^ 6 ≠ 3 ^ 2 * 3 ^ 3 := by norm_num
example : (3 : ℚ) * 5 = 15 ∧ (3 : ℚ) * 5 ≠ 3 ^ 5 := by norm_num
example : -((3 : ℚ) ^ 3) = -27 ∧ -((3 : ℚ) ^ 3) ≠ 3 ^ (-3 : ℤ) := by norm_num
-- Different bases: 3^2 × 5^2 is not 15^4.
example : (3 : ℚ) ^ 2 * 5 ^ 2 ≠ 15 ^ 4 := by norm_num
-- Try changing: a sixth round adds 729, not another 243.
example : (3 : ℕ) ^ 6 = 729 := by norm_num

#print axioms exponent_rules_add_subtract_multiply
#print axioms zero_and_negative_powers_are_forced
