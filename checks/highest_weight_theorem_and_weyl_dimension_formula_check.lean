-- Highest weights: Weyl's dimension formula for SU(3) is a whole number and agrees with the traceless tensor count, checked on the card's quark, gluon and decuplet sizes.
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp

/-- Helper: `(n + 1).choose 2`, read as a rational number, is `(n + 1) n / 2`. -/
theorem succ_choose_two_cast (n : ℕ) : ((n + 1).choose 2 : ℚ) = (n + 1) * n / 2 := by
  have h : (n + 1) * n.choose 1 = (n + 1).choose 2 * 2 := Nat.add_one_mul_choose_eq n 1
  rw [Nat.choose_one_right] at h
  have h' : ((n + 1 : ℕ) : ℚ) * n = ((n + 1).choose 2 : ℚ) * 2 := by exact_mod_cast h
  push_cast at h'
  rw [eq_div_iff (by norm_num)]
  exact h'.symm

#print axioms succ_choose_two_cast

/-- Weyl's dimension formula for SU(3) gives the same size as the second road: for every
dominant integral highest weight `(a, b)` (two whole numbers at least 0), the Weyl size
`(a + 1)(b + 1)(a + b + 2)/2` equals the number of symmetric states of `a` quarks and `b`
antiquarks, `C(a + 2, 2) C(b + 2, 2)`, minus the trace part, `C(a + 1, 2) C(b + 1, 2)`. -/
theorem weyl_dimension_su3_eq_traceless_tensor_count (a b : ℕ) :
    ((a + 1 : ℚ) * (b + 1) * (a + b + 2)) / 2 =
      ((a + 2).choose 2 * (b + 2).choose 2 : ℚ) - ((a + 1).choose 2 * (b + 1).choose 2 : ℚ) := by
  rw [succ_choose_two_cast (a + 1), succ_choose_two_cast (b + 1),
    succ_choose_two_cast a, succ_choose_two_cast b]
  push_cast
  ring

/-- Weyl's product over the three positive roots of SU(3), `α₁`, `α₂` and `α₁ + α₂`, read
through the labels: a positive root with label coefficients `(c₁, c₂)` reads `c₁ x + c₂ y` off a
weight with labels `(x, y)`, and `ρ` has labels `(1, 1)`. Shifting `(a, b)` by `ρ`, multiplying
the three readings and dividing by the same product for `ρ` alone gives
`(a + 1)(b + 1)(a + b + 2)/2`. -/
theorem weyl_product_over_positive_roots_su3 (a b : ℕ) :
    (∏ c : Fin 3, ((![1, 0, 1] c : ℚ) * (a + 1) + (![0, 1, 1] c : ℚ) * (b + 1)) /
        ((![1, 0, 1] c : ℚ) * 1 + (![0, 1, 1] c : ℚ) * 1)) =
      ((a + 1 : ℚ) * (b + 1) * (a + b + 2)) / 2 := by
  simp only [Fin.prod_univ_three]
  simp
  ring

/-- Weyl's formula counts states: for every dominant integral weight `(a, b)` the product
`(a + 1)(b + 1)(a + b + 2)` is even, so the size it gives is a whole number. -/
theorem weyl_dimension_su3_is_whole_number (a b : ℕ) :
    2 ∣ (a + 1) * (b + 1) * (a + b + 2) := by
  rcases Nat.mod_two_eq_zero_or_one a with ha | ha <;>
    rcases Nat.mod_two_eq_zero_or_one b with hb | hb <;>
    · apply Nat.dvd_of_mod_eq_zero
      simp [Nat.mul_mod, Nat.add_mod, ha, hb]

-- Quarks (1, 0): 2 × 1 × 3 / 2 = 3.
example : (1 + 1) * (0 + 1) * (1 + 0 + 2) / 2 = 3 := by norm_num
-- Gluons (1, 1): 2 × 2 × 4 / 2 = 8.
example : (1 + 1) * (1 + 1) * (1 + 1 + 2) / 2 = 8 := by norm_num
-- Flavour decuplet (3, 0): 4 × 1 × 5 / 2 = 10.
example : (3 + 1) * (0 + 1) * (3 + 0 + 2) / 2 = 10 := by norm_num
-- Gluons by tensors: 9 − 1 = 8.
example : (1 + 2).choose 2 * (1 + 2).choose 2 - (1 + 1).choose 2 * (1 + 1).choose 2 = 8 := by decide
-- Decuplet by tensors: 10 − 0 = 10.
example : (3 + 2).choose 2 * (0 + 2).choose 2 - (3 + 1).choose 2 * (0 + 1).choose 2 = 10 := by decide
-- Quark times antiquark, sizes by Weyl's formula: 3 × 3 = 8 + 1.
example : ((1 + 1) * (0 + 1) * (1 + 0 + 2) / 2) * ((0 + 1) * (1 + 1) * (0 + 1 + 2) / 2) =
    (1 + 1) * (1 + 1) * (1 + 1 + 2) / 2 + (0 + 1) * (0 + 1) * (0 + 0 + 2) / 2 := by norm_num
-- Quark times quark, sizes by Weyl's formula: 3 × 3 = 6 + 3.
example : ((1 + 1) * (0 + 1) * (1 + 0 + 2) / 2) * ((1 + 1) * (0 + 1) * (1 + 0 + 2) / 2) =
    (2 + 1) * (0 + 1) * (2 + 0 + 2) / 2 + (0 + 1) * (1 + 1) * (0 + 1 + 2) / 2 := by norm_num
-- Three quarks, sizes by Weyl's formula: 3 × 3 × 3 = 10 + 8 + 8 + 1.
example : ((1 + 1) * (0 + 1) * (1 + 0 + 2) / 2) ^ 3 =
    (3 + 1) * (0 + 1) * (3 + 0 + 2) / 2 + (1 + 1) * (1 + 1) * (1 + 1 + 2) / 2 +
      (1 + 1) * (1 + 1) * (1 + 1 + 2) / 2 + (0 + 1) * (0 + 1) * (0 + 0 + 2) / 2 := by norm_num
-- The ten sizes with a + b ≤ 3, in the card's order: 1, 3, 3, 6, 8, 6, 10, 15, 15, 10.
example : (List.map (fun p : ℕ × ℕ => (p.1 + 1) * (p.2 + 1) * (p.1 + p.2 + 2) / 2)
    [(0, 0), (1, 0), (0, 1), (2, 0), (1, 1), (0, 2), (3, 0), (2, 1), (1, 2), (0, 3)]) =
    [1, 3, 3, 6, 8, 6, 10, 15, 15, 10] := by decide
-- Their sizes squared add to 805.
example : (List.map (fun p : ℕ × ℕ => ((p.1 + 1) * (p.2 + 1) * (p.1 + p.2 + 2) / 2) ^ 2)
    [(0, 0), (1, 0), (0, 1), (2, 0), (1, 1), (0, 2), (3, 0), (2, 1), (1, 2), (0, 3)]).sum =
    805 := by decide
-- Try changing: (2, 2) has size 3 × 3 × 6 / 2 = 27.
example : (2 + 1) * (2 + 1) * (2 + 2 + 2) / 2 = 27 := by norm_num

#print axioms weyl_dimension_su3_eq_traceless_tensor_count
#print axioms weyl_product_over_positive_roots_su3
#print axioms weyl_dimension_su3_is_whole_number
