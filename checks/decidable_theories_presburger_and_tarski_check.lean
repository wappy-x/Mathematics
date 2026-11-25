-- Decidable theories: every set of whole numbers that plus alone describes repeats with a fixed period after some point, so the squares and times cannot be described with plus, and over the reals some x solves x^2 + bx + c = 0 exactly when b^2 - 4c >= 0.
import Mathlib.ModelTheory.Arithmetic.Presburger.Definability
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Real.Sqrt

open FirstOrder Language

/-- Every set of whole numbers that a formula of Presburger arithmetic (0, 1 and plus on the
numbers 0, 1, 2, ...; "less than" is itself written with plus) describes is eventually periodic:
from some point k on, it repeats with some period p > 0. -/
theorem presburger_definable_eventually_periodic (s : Set ℕ)
    (hs : (∅ : Set ℕ).Definable₁ presburger s) :
    ∃ k, ∃ p > 0, ∀ x ≥ k, x ∈ s ↔ x + p ∈ s := by
  exact presburger.definable₁_iff_ultimately_periodic.mp hs

/-- The squares 0, 1, 4, 9, ... have no formula with plus alone, and neither does times:
the set of triples (x, y, z) with x = y * z is not Presburger definable. -/
theorem squares_and_times_not_presburger_definable :
    ¬ (∅ : Set ℕ).Definable₁ presburger {x | ∃ n, x = n * n} ∧
    ¬ (∅ : Set ℕ).Definable presburger {v : Fin 3 → ℕ | v 0 = v 1 * v 2} := by
  refine ⟨?_, presburger.mul_not_definable⟩
  intro hsqr
  rw [presburger.definable₁_iff_ultimately_periodic] at hsqr
  rcases hsqr with ⟨k, p, hp, h⟩
  specialize h ((max k p) * (max k p)) ((Nat.le_mul_self _).trans' (le_max_left _ _))
  have h' := h.mp ⟨max k p, rfl⟩
  rcases h' with ⟨x, h₁⟩
  by_cases h₂ : x ≤ max k p
  · apply Nat.mul_self_le_mul_self at h₂
    grind
  · simp only [not_le, Nat.lt_iff_add_one_le] at h₂
    apply Nat.mul_self_le_mul_self at h₂
    grind

/-- Tarski's quadratic case: over the real numbers, some x solves x^2 + bx + c = 0
exactly when b^2 - 4c >= 0. -/
theorem exists_real_root_quadratic_iff (b c : ℝ) :
    (∃ x : ℝ, x ^ 2 + b * x + c = 0) ↔ b ^ 2 - 4 * c ≥ 0 := by
  constructor
  · rintro ⟨x, hx⟩
    nlinarith [sq_nonneg (2 * x + b)]
  · intro h
    refine ⟨(-b + Real.sqrt (b ^ 2 - 4 * c)) / 2, ?_⟩
    have hs := Real.sq_sqrt (show (0:ℝ) ≤ b ^ 2 - 4 * c by linarith)
    nlinarith [hs]

-- "There is y with 3y = x + 1" holds exactly when x leaves remainder 2 on division by 3,
-- checked for x from 0 to 59 (y up to 60 is enough).
example : ∀ x < 60, (∃ y ≤ 60, 3 * y = x + 1) ↔ x % 3 = 2 := by decide

-- "There is y with x = 2y or x = 2y + 1" is true for every x from 0 to 59.
example : ∀ x < 60, ∃ y ≤ 30, x = 2 * y ∨ x = 2 * y + 1 := by decide

-- Stamps of 3p and 5p: every amount from 8p to 59p can be made.
example : ∀ x < 60, 8 ≤ x → ∃ y ≤ 20, ∃ w ≤ 12, x = 3 * y + 5 * w := by decide

-- 1p, 2p, 4p and 7p cannot be made, so 7p is the largest amount missed.
example : ∀ x ∈ ({1, 2, 4, 7} : Finset ℕ), ¬ ∃ y ≤ 7, ∃ w ≤ 7, x = 3 * y + 5 * w := by decide

-- b = -6, c = 8: the test gives 36 - 32 = 4, and x = 2 and x = 4 are roots.
example : (-6 : ℤ) ^ 2 - 4 * 8 = 4 := by norm_num
example : (2 : ℝ) ^ 2 + (-6) * 2 + 8 = 0 ∧ (4 : ℝ) ^ 2 + (-6) * 4 + 8 = 0 := by norm_num

-- b = 1, c = 1: the test gives -3, so there is no real root.
example : (1 : ℤ) ^ 2 - 4 * 1 = -3 := by norm_num

-- x^2 - 2: the test gives 8, but no whole number x up to 1000 has x * x = 2.
example : (0 : ℤ) ^ 2 - 4 * (-2) = 8 := by norm_num
example : ∀ x < 1001, x * x ≠ 2 := by decide +kernel

#print axioms presburger_definable_eventually_periodic
#print axioms squares_and_times_not_presburger_definable
#print axioms exists_real_root_quadratic_iff
