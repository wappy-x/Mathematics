-- Integer programs: allowing fractions gives a ceiling on every yes-or-no plan, prices on the count and the budget give the same kind of ceiling, and one split plus a cut-off proves a plan best, checked on the 12 depot sites where A, D and L save £410k.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open Finset

/-- The whole plans: every yes-or-no choice `x i ∈ {0, 1}` for the `n` sites that opens exactly
`p` sites (`∑ x i = p`) and keeps the leases within the budget (`∑ a i * x i ≤ b`). -/
def wholePlans (n p : ℕ) (a : Fin n → ℝ) (b : ℝ) : Set (Fin n → ℝ) :=
  {x | (∀ i, x i = 0 ∨ x i = 1) ∧ ∑ i, x i = p ∧ ∑ i, a i * x i ≤ b}

/-- The fractional plans of the LP relaxation: the same count and budget, but each `x i` may be
anywhere from 0 to 1. -/
def fractionalPlans (n p : ℕ) (a : Fin n → ℝ) (b : ℝ) : Set (Fin n → ℝ) :=
  {x | (∀ i, 0 ≤ x i ∧ x i ≤ 1) ∧ ∑ i, x i = p ∧ ∑ i, a i * x i ≤ b}

/-- The total saving `∑ s i * x i` of a plan `x`. -/
def saving {n : ℕ} (s x : Fin n → ℝ) : ℝ := ∑ i, s i * x i

/-- The fractional answer is a ceiling (z_LP ≥ z_IP): for any sites, savings `s`, leases `a`,
depot count `p` and budget `b`, every whole plan saves no more than the best saving with
fractions allowed, `z_LP = sup {saving y | y a fractional plan}`. -/
theorem relaxation_is_a_ceiling (n p : ℕ) (s a : Fin n → ℝ) (b : ℝ)
    (x : Fin n → ℝ) (hx : x ∈ wholePlans n p a b) :
    saving s x ≤ sSup (saving s '' fractionalPlans n p a b) := by
  obtain ⟨h01, hsum, hb⟩ := hx
  have hxf : x ∈ fractionalPlans n p a b := by
    refine ⟨fun i => ?_, hsum, hb⟩
    rcases h01 i with h | h <;> rw [h] <;> norm_num
  refine le_csSup ?_ ⟨x, hxf, rfl⟩
  refine ⟨∑ i, |s i|, ?_⟩
  rintro _ ⟨y, ⟨hy, -, -⟩, rfl⟩
  unfold saving
  apply Finset.sum_le_sum
  intro i _
  obtain ⟨h0, h1⟩ := hy i
  calc s i * y i ≤ |s i * y i| := le_abs_self _
    _ = |s i| * y i := by rw [abs_mul, abs_of_nonneg h0]
    _ ≤ |s i| * 1 := mul_le_mul_of_nonneg_left h1 (abs_nonneg _)
    _ = |s i| := mul_one _

/-- The price certificate: put a price `y₁` on each depot and a price `y₂ ≥ 0` on each unit of
lease. Then every plan that obeys the rules, fractions allowed, saves at most
`∑ max(0, s i - y₁ - y₂ a i) + p y₁ + b y₂`. -/
theorem prices_give_a_ceiling (n p : ℕ) (s a : Fin n → ℝ) (b : ℝ) (y₁ y₂ : ℝ) (hy₂ : 0 ≤ y₂)
    (x : Fin n → ℝ) (hx : x ∈ fractionalPlans n p a b) :
    saving s x ≤ ∑ i, max 0 (s i - y₁ - y₂ * a i) + p * y₁ + b * y₂ := by
  obtain ⟨h01, hsum, hb⟩ := hx
  unfold saving
  have key : ∀ i, s i * x i ≤ max 0 (s i - y₁ - y₂ * a i) + y₁ * x i + y₂ * (a i * x i) := by
    intro i
    obtain ⟨h0, h1⟩ := h01 i
    have hm1 : (s i - y₁ - y₂ * a i) * x i ≤ max 0 (s i - y₁ - y₂ * a i) * x i :=
      mul_le_mul_of_nonneg_right (le_max_right _ _) h0
    have hm2 : max 0 (s i - y₁ - y₂ * a i) * x i ≤ max 0 (s i - y₁ - y₂ * a i) := by
      have := le_max_left 0 (s i - y₁ - y₂ * a i)
      nlinarith
    nlinarith
  calc ∑ i, s i * x i
      ≤ ∑ i, (max 0 (s i - y₁ - y₂ * a i) + y₁ * x i + y₂ * (a i * x i)) :=
        Finset.sum_le_sum (fun i _ => key i)
    _ = ∑ i, max 0 (s i - y₁ - y₂ * a i) + y₁ * ∑ i, x i + y₂ * ∑ i, a i * x i := by
        rw [Finset.sum_add_distrib, Finset.sum_add_distrib, Finset.mul_sum, Finset.mul_sum]
    _ ≤ ∑ i, max 0 (s i - y₁ - y₂ * a i) + p * y₁ + b * y₂ := by
        rw [hsum]
        have := mul_le_mul_of_nonneg_left hb hy₂
        nlinarith

/-- Splitting on a site and cutting off a branch proves a plan best: split on site `j`. If the
incumbent `x⋆` is a whole plan that beats or ties every whole plan with site `j` closed, and the
relaxation with site `j` open has a ceiling `U` no higher than the incumbent's saving, then no
whole plan at all saves more than the incumbent. -/
theorem split_and_cut_off_proves_best (n p : ℕ) (s a : Fin n → ℝ) (b : ℝ) (j : Fin n)
    (xstar : Fin n → ℝ) (hstar : xstar ∈ wholePlans n p a b)
    (hclosed : ∀ x ∈ wholePlans n p a b, x j = 0 → saving s x ≤ saving s xstar)
    (U : ℝ) (hopen : ∀ y ∈ fractionalPlans n p a b, y j = 1 → saving s y ≤ U)
    (hU : U ≤ saving s xstar) :
    ∀ x ∈ wholePlans n p a b, saving s x ≤ saving s xstar := by
  intro x hx
  rcases hx.1 j with h | h
  · exact hclosed x hx h
  · have hxf : x ∈ fractionalPlans n p a b := by
      obtain ⟨h01, hsum, hb⟩ := hx
      refine ⟨fun i => ?_, hsum, hb⟩
      rcases h01 i with h' | h' <;> rw [h'] <;> norm_num
    exact (hopen x hxf h).trans hU

/-! The depots: 12 sites A to L (0 to 11), choose exactly 3 within £200k of leases a year. -/

/-- Yearly lease of each site, £k: A 60, B 40, C 110, D 70, E 60, F 40, G 60, H 50, I 90, J 60, K 110, L 70. -/
def lease : Fin 12 → ℕ := ![60, 40, 110, 70, 60, 40, 60, 50, 90, 60, 110, 70]
/-- Yearly saving of each site, £k: A 145, B 40, C 240, D 140, E 115, F 70, G 70, H 80, I 125, J 115, K 110, L 125. -/
def save : Fin 12 → ℕ := ![145, 40, 240, 140, 115, 70, 70, 80, 125, 115, 110, 125]

-- There are 220 ways to pick 3 sites from 12, and 109 of them fit the £200k budget.
example : ((univ : Finset (Fin 12)).powersetCard 3).card = 220 := by decide +kernel
example : (((univ : Finset (Fin 12)).powersetCard 3).filter
    (fun T => ∑ i ∈ T, lease i ≤ 200)).card = 109 := by decide +kernel
-- Brute force: no choice of 3 sites within £200k saves more than £410k ...
example : ∀ i j k : Fin 12, i < j → j < k →
    lease i + lease j + lease k ≤ 200 → save i + save j + save k ≤ 410 := by decide +kernel
-- ... and A, D, L (sites 0, 3, 11) uses exactly £200k and saves £410k.
example : lease 0 + lease 3 + lease 11 = 200 ∧ save 0 + save 3 + save 11 = 410 := by decide
-- The relaxed best: A and F open, C at 3/4, D at 1/4: leases 200, savings 430.
example : (60 : ℚ) + 110 * (3 / 4) + 70 * (1 / 4) + 40 = 200 := by norm_num
example : (145 : ℚ) + 240 * (3 / 4) + 140 * (1 / 4) + 70 = 430 := by norm_num
-- Prices that make C and D break even: y₂ = 5/2, y₁ = -35; leftovers A 30, F 5; bound 430.
example : ((240 : ℚ) - 140) / (110 - 70) = 5 / 2 ∧ (240 : ℚ) - 5 / 2 * 110 = -35 := by norm_num
example : (145 : ℚ) - (-35) - 5 / 2 * 60 = 30 ∧ (70 : ℚ) - (-35) - 5 / 2 * 40 = 5 := by norm_num
example : 3 * (-35 : ℚ) + 200 * (5 / 2) + 30 + 5 = 430 := by norm_num
-- Branch C open: C and F open, A and B at a half each: leases 200, ceiling 805/2 (£402.5k) < 410.
example : (110 : ℚ) + 40 + 60 / 2 + 40 / 2 = 200 ∧ (240 : ℚ) + 70 + 145 / 2 + 40 / 2 = 805 / 2 := by
  norm_num
example : (805 / 2 : ℚ) < 410 := by norm_num
-- Integrality gap: 430 - 410 = 20 (£20k).
example : 430 - 410 = 20 := by norm_num
-- Mistakes: rounding to nearest gives A, C, F: leases 210 > 200, "saving" 455;
-- rounding down gives A, F: 2 depots, 215; greedy by value for money gives A, C: leases 170, 385.
example : lease 0 + lease 2 + lease 5 = 210 ∧ save 0 + save 2 + save 5 = 455 := by decide
example : save 0 + save 5 = 215 := by decide
example : lease 0 + lease 2 = 170 ∧ save 0 + save 2 = 385 := by decide
-- After A and C (£170k), no third site fits the £30k left.
example : ∀ i : Fin 12, 30 < lease i := by decide
-- A and D overlap by £50k: A, D, L really saves 360; C, F, H fits (200) and saves 390.
example : save 0 + save 3 + save 11 - 50 = 360 := by decide
example : lease 2 + lease 5 + lease 7 = 200 ∧ save 2 + save 5 + save 7 = 390 := by decide
-- Other budgets: at £190k the best is £400k (A, D, J); at £210k, £455k (A, C, F); at £240k, £525k (A, C, D).
example : ∀ i j k : Fin 12, i < j → j < k →
    lease i + lease j + lease k ≤ 190 → save i + save j + save k ≤ 400 := by decide +kernel
example : lease 0 + lease 3 + lease 9 = 190 ∧ save 0 + save 3 + save 9 = 400 := by decide
example : ∀ i j k : Fin 12, i < j → j < k →
    lease i + lease j + lease k ≤ 210 → save i + save j + save k ≤ 455 := by decide +kernel
example : ∀ i j k : Fin 12, i < j → j < k →
    lease i + lease j + lease k ≤ 240 → save i + save j + save k ≤ 525 := by decide +kernel
example : lease 0 + lease 2 + lease 3 = 240 ∧ save 0 + save 2 + save 3 = 525 := by decide

#print axioms relaxation_is_a_ceiling
#print axioms prices_give_a_ceiling
#print axioms split_and_cut_off_proves_best
