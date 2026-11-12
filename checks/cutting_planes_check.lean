-- Cutting planes: the Gomory fractional cut from a tableau row keeps every whole-number point, the corner with a fractional right side breaks it, and on the festival example the cut 3 x1 + x2 <= 16 keeps all 45 whole bookings.
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Data.Rat.Floor
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- The Gomory fractional cut is valid. Take a tableau row
`x_B + ∑ⱼ āⱼ xⱼ = b̄` (the sum runs over the non-basic variables).
At any point where the basic variable and every non-basic variable are whole numbers
and the non-basic variables are not negative, the row's fractional parts satisfy
`∑ⱼ f(āⱼ) xⱼ ≥ f(b̄)`, where `f(v) = v - ⌊v⌋` is the fractional part. -/
theorem gomory_fractional_cut_keeps_whole_points
    {ι : Type*} [Fintype ι] (a : ι → ℝ) (b : ℝ) (xB : ℤ) (x : ι → ℤ)
    (hx : ∀ j, 0 ≤ x j)
    (hrow : (xB : ℝ) + ∑ j, a j * (x j : ℝ) = b) :
    Int.fract b ≤ ∑ j, Int.fract (a j) * (x j : ℝ) := by
  set S : ℝ := ∑ j, Int.fract (a j) * (x j : ℝ) with hSdef
  have hS : 0 ≤ S := Finset.sum_nonneg (fun j _ =>
    mul_nonneg (Int.fract_nonneg _) (by exact_mod_cast hx j))
  have hsplit : ∀ j, a j * (x j : ℝ) = (⌊a j⌋ : ℝ) * (x j : ℝ) + Int.fract (a j) * (x j : ℝ) := by
    intro j; rw [Int.fract]; ring
  have hb : b = (((xB + ∑ j, ⌊a j⌋ * x j : ℤ)) : ℝ) + S := by
    rw [← hrow]; simp_rw [hsplit]; rw [Finset.sum_add_distrib, Int.cast_add, Int.cast_sum]; simp only [Int.cast_mul]; ring
  rw [hb, Int.fract_intCast_add]
  have h0 : (0 : ℤ) ≤ ⌊S⌋ := Int.floor_nonneg.mpr hS
  have h0' : (0 : ℝ) ≤ (⌊S⌋ : ℝ) := by exact_mod_cast h0
  rw [Int.fract]; linarith

/-- The corner breaks the cut. At the corner every non-basic variable is zero,
so the cut's left side is 0. When the row's right side is fractional
(`f(b̄) ≠ 0`), 0 falls short of `f(b̄)`, so the corner is removed. -/
theorem gomory_fractional_cut_removes_corner
    {ι : Type*} [Fintype ι] (a : ι → ℝ) (b : ℝ) (x : ι → ℝ)
    (hcorner : ∀ j, x j = 0)
    (hfrac : Int.fract b ≠ 0) :
    ∑ j, Int.fract (a j) * x j < Int.fract b := by
  have hzero : ∑ j, Int.fract (a j) * x j = 0 := by simp [hcorner]
  rw [hzero]
  exact lt_of_le_of_ne (Int.fract_nonneg b) (Ne.symm hfrac)

/-- On the festival (money in £5k units, time in 2-hour slots), every whole booking
of `x₁` headliners and `x₂` smaller acts with `12 x₁ + x₂ ≤ 58` and `2 x₁ + x₂ ≤ 12`
obeys the cut `3 x₁ + x₂ ≤ 16`. -/
theorem festival_cut_keeps_whole_bookings (x₁ x₂ : ℤ) (h₁ : 0 ≤ x₁) (h₂ : 0 ≤ x₂)
    (hbudget : 12 * x₁ + x₂ ≤ 58) (hstage : 2 * x₁ + x₂ ≤ 12) :
    3 * x₁ + x₂ ≤ 16 := by
  have _ := h₁
  omega

/-! ### The card's worked numbers -/

/-- The whole bookings: pairs (headliners, smaller acts) inside both limits. -/
def wholeBookings : Finset (ℕ × ℕ) :=
  (range 13 ×ˢ range 13).filter (fun p => 12 * p.1 + p.2 ≤ 58 ∧ 2 * p.1 + p.2 ≤ 12)

-- There are 45 whole bookings.
example : wholeBookings.card = 45 := by decide

-- All 45 whole bookings pass the cut 3 x₁ + x₂ ≤ 16.
example : ∀ p ∈ wholeBookings, 3 * p.1 + p.2 ≤ 16 := by decide

-- The second cut 10 x₁ + x₂ ≤ 48 also keeps all 45 whole bookings.
example : ∀ p ∈ wholeBookings, 10 * p.1 + p.2 ≤ 48 := by decide

-- The best whole booking is (4, 4): 26,000 tickets (5,500 per headliner, 1,000 per smaller act).
example : (4, 4) ∈ wholeBookings ∧
    ∀ p ∈ wholeBookings, 5500 * p.1 + 1000 * p.2 ≤ 5500 * 4 + 1000 * 4 := by decide
example : 5500 * 4 + 1000 * 4 = 26000 := by norm_num

-- (4, 4) scores exactly 16 on the cut.
example : 3 * 4 + 4 = 16 := by norm_num

-- The relaxed corner (4.6, 2.8) = (23/5, 14/5) meets both limits exactly, gives 28,100 tickets,
-- and scores 16.6 > 16 on the cut.
example : (12 : ℚ) * (23/5) + 14/5 = 58 ∧ (2 : ℚ) * (23/5) + 14/5 = 12 := by norm_num
example : (5500 : ℚ) * (23/5) + 1000 * (14/5) = 28100 := by norm_num
example : (3 : ℚ) * (23/5) + 14/5 = 83/5 ∧ (16 : ℚ) < 83/5 := by norm_num

-- The tableau row x₁ + (1/10) s₁ - (1/10) s₂ = 23/5 holds at every point,
-- with s₁ = 58 - 12 x₁ - x₂ and s₂ = 12 - 2 x₁ - x₂.
example (x₁ x₂ : ℚ) :
    x₁ + (1/10) * (58 - 12 * x₁ - x₂) - (1/10) * (12 - 2 * x₁ - x₂) = 23/5 := by ring

-- The fractional parts: f(0.1) = 0.1, f(-0.1) = 0.9, f(4.6) = 0.6, and ⌊-0.1⌋ = -1.
example : Int.fract ((1 : ℚ)/10) = 1/10 := by norm_num
example : Int.fract (-(1 : ℚ)/10) = 9/10 := by norm_num
example : Int.fract ((23 : ℚ)/5) = 3/5 := by norm_num
example : ⌊(-(1 : ℚ)/10)⌋ = -1 := by norm_num

-- Back into acts: the slack cut (1/10) s₁ + (9/10) s₂ ≥ 3/5 is 3 x₁ + x₂ ≤ 16.
example (x₁ x₂ : ℚ) :
    (1/10) * (58 - 12 * x₁ - x₂) + (9/10) * (12 - 2 * x₁ - x₂) - 3/5 = 16 - (3 * x₁ + x₂) := by
  ring

-- Re-solved corner (14/3, 2) after the first cut: on the cut and the budget, 27,666.67 = 83000/3 tickets.
example : (3 : ℚ) * (14/3) + 2 = 16 ∧ (12 : ℚ) * (14/3) + 2 = 58 ∧
    (5500 : ℚ) * (14/3) + 1000 * 2 = 83000/3 := by norm_num

-- With the budget in millions, the recipe's cut 38 x₁ + 19 x₂ ≤ 222 throws out (4, 4).
example : 38 * 4 + 19 * 4 = 228 ∧ 222 < 228 := by norm_num

#print axioms gomory_fractional_cut_keeps_whole_points
#print axioms gomory_fractional_cut_removes_corner
#print axioms festival_cut_keeps_whole_bookings
