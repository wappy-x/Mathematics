-- The number families: each family (counting numbers, integers, fractions, reals) answers an operation the one before it cannot, the families nest, and the carpenter's tile diagonal is no fraction.
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Data.Real.Sqrt
import Mathlib.Data.Rat.Cast.CharZero
import Mathlib.Tactic.NormNum

/-- The ladder. Counting numbers cannot take away more than you have; integers always can.
Integers cannot always share out evenly; fractions always can, except by zero.
Fractions cannot always measure a diagonal (a square root); reals always can. -/
theorem number_families_ladder :
    (∀ a b : ℕ, a < b → ¬ ∃ n : ℕ, n + b = a) ∧
    (∀ a b : ℤ, ∃ x : ℤ, x + b = a) ∧
    (∃ a b : ℤ, b ≠ 0 ∧ ¬ ∃ x : ℤ, x * b = a) ∧
    (∀ a b : ℚ, b ≠ 0 → ∃ x : ℚ, x * b = a) ∧
    (∃ a : ℚ, 0 ≤ a ∧ ¬ ∃ x : ℚ, x * x = a) ∧
    (∀ a : ℝ, 0 ≤ a → ∃ x : ℝ, x * x = a) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro a b h
    omega
  · intro a b
    exact ⟨a - b, by ring⟩
  · exact ⟨1, 2, by norm_num, by omega⟩
  · intro a b hb
    exact ⟨a / b, div_mul_cancel₀ a hb⟩
  · refine ⟨2, by norm_num, ?_⟩
    rintro ⟨x, hx⟩
    have hx' : ((x : ℝ)) * (x : ℝ) = 2 := by exact_mod_cast hx
    have hs : Real.sqrt 2 = |(x : ℝ)| := by
      rw [← hx', Real.sqrt_mul_self_eq_abs]
    have hirr : Irrational |(x : ℝ)| := by
      rw [← hs]; exact irrational_sqrt_two
    exact hirr ⟨|x|, by simp⟩
  · intro a ha
    exact ⟨Real.sqrt a, Real.mul_self_sqrt ha⟩

/-- The families nest: going up throws nothing away. Each step up is one-to-one, and a counting
number or integer means the same thing whichever route it takes up the ladder. -/
theorem number_families_nest :
    Function.Injective (fun n : ℕ => (n : ℤ)) ∧
    Function.Injective (fun z : ℤ => (z : ℚ)) ∧
    Function.Injective (fun q : ℚ => (q : ℝ)) ∧
    (∀ n : ℕ, ((n : ℤ) : ℚ) = (n : ℚ)) ∧
    (∀ z : ℤ, ((z : ℚ) : ℝ) = (z : ℝ)) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · exact Nat.cast_injective
  · exact Int.cast_injective
  · exact Rat.cast_injective
  · intro n; simp
  · intro z; simp

/-- The diagonal of a square tile 30 cm a side (a length that times itself gives 900 + 900)
is 30 times root 2, and no fraction lands on it. -/
theorem tile_diagonal_not_a_fraction (d : ℝ) (hd : 0 ≤ d) (hsq : d * d = 30 * 30 + 30 * 30) :
    d = 30 * Real.sqrt 2 ∧ Irrational d := by
  have h2 : (0:ℝ) ≤ 30 * Real.sqrt 2 := by positivity
  have hd' : d = 30 * Real.sqrt 2 := by
    have : d * d = (30 * Real.sqrt 2) * (30 * Real.sqrt 2) := by
      have := Real.mul_self_sqrt (show (0:ℝ) ≤ 2 by norm_num)
      nlinarith
    exact (mul_self_inj hd h2).mp this
  refine ⟨hd', ?_⟩
  rw [hd']
  have h30 := irrational_sqrt_two.ratCast_mul (q := 30) (by norm_num)
  simpa using h30


-- The card's worked numbers, in centimetres.
example : (225 : ℤ) - 240 = -15 := by norm_num
example : (240 : ℤ) + (-15) = 225 := by norm_num
example : ¬ ∃ n : ℕ, n + 240 = 225 := by omega
example : 100 / 3 = 33 ∧ 100 % 3 = 1 := by decide
example : 33 * 3 + 1 = 100 := by decide
example : 33 * 3 = 99 := by decide
example : ¬ ∃ x : ℤ, x * 3 = 100 := by omega
example : (33 : ℚ) + 1 / 3 = 100 / 3 := by norm_num
example : ((33 : ℚ) + 1 / 3) * 3 = 100 := by norm_num
example : 30 * 30 + 30 * 30 = 1800 := by decide
example : 900 + 900 = 1800 := by decide
-- The tape marks 42.42 and 42.43, counted in hundredths of a centimetre: one squares under 1800, one over.
example : 4242 * 4242 = 17994564 ∧ 4243 * 4243 = 18003049 := by norm_num
example : 4242 * 4242 < 1800 * 100 * 100 ∧ 1800 * 100 * 100 < 4243 * 4243 := by norm_num
-- 3 is a counting number, an integer, a fraction (3 over 1) and a real, all the same 3.
example : (((3 : ℕ) : ℤ) : ℚ) = (3 : ℚ) / 1 := by norm_num

#print axioms number_families_ladder
#print axioms number_families_nest
#print axioms tile_diagonal_not_a_fraction
