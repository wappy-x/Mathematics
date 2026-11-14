-- Attribution: the fund's return minus the benchmark's splits exactly into allocation, selection and interaction, the four notional portfolios give the same split, and linked multi-period effects add to the compounded gap.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- Brinson attribution. For any finite set of sectors, fund weights `w`, benchmark weights `W`,
fund sector returns `r` and benchmark sector returns `b`, with each weight list adding to 1,
the active return `R - B` (where `R = ∑ wᵢ rᵢ` and `B = ∑ Wᵢ bᵢ`) equals
allocation `∑ (wᵢ - Wᵢ)(bᵢ - B)` plus selection `∑ Wᵢ (rᵢ - bᵢ)` plus
interaction `∑ (wᵢ - Wᵢ)(rᵢ - bᵢ)`, exactly. -/
theorem active_return_eq_allocation_add_selection_add_interaction
    {ι : Type*} [Fintype ι] (w W r b : ι → ℝ)
    (hw : ∑ i, w i = 1) (hW : ∑ i, W i = 1) :
    (∑ i, w i * r i) - (∑ i, W i * b i) =
      (∑ i, (w i - W i) * (b i - ∑ j, W j * b j)) +
      (∑ i, W i * (r i - b i)) +
      (∑ i, (w i - W i) * (r i - b i)) := by
  simp only [mul_sub, sub_mul, Finset.sum_sub_distrib, ← Finset.sum_mul, hw, hW]
  ring

/-- The four notional portfolios. With Q1 = benchmark weights and benchmark returns,
Q2 = fund weights and benchmark returns, Q3 = benchmark weights and fund returns,
Q4 = fund weights and fund returns, and each weight list adding to 1:
allocation is Q2 - Q1, selection is Q3 - Q1, and interaction is Q4 - Q3 - Q2 + Q1. -/
theorem notional_portfolios_give_allocation_selection_interaction
    {ι : Type*} [Fintype ι] (w W r b : ι → ℝ)
    (hw : ∑ i, w i = 1) (hW : ∑ i, W i = 1) :
    let Q1 := ∑ i, W i * b i
    let Q2 := ∑ i, w i * b i
    let Q3 := ∑ i, W i * r i
    let Q4 := ∑ i, w i * r i
    (∑ i, (w i - W i) * (b i - Q1)) = Q2 - Q1 ∧
    (∑ i, W i * (r i - b i)) = Q3 - Q1 ∧
    (∑ i, (w i - W i) * (r i - b i)) = Q4 - Q3 - Q2 + Q1 := by
  intro Q1 Q2 Q3 Q4
  refine ⟨?_, ?_, ?_⟩
  · simp only [Q1, Q2, mul_sub, sub_mul, Finset.sum_sub_distrib, ← Finset.sum_mul, hw, hW]
    ring
  · simp only [Q1, Q3, mul_sub, Finset.sum_sub_distrib]
  · simp only [Q1, Q2, Q3, Q4, mul_sub, sub_mul, Finset.sum_sub_distrib]
    ring

/-- Linking across months. Over `n` months with fund returns `R t` and benchmark returns `B t`,
the compounded gap `∏ (1 + R t) - ∏ (1 + B t)` equals the sum over months of that month's
active return `R t - B t`, scaled by the fund's growth over the months before it and the
benchmark's growth over the months after it. -/
theorem compounded_active_return_eq_linked_sum (n : ℕ) (R B : ℕ → ℝ) :
    (∏ t ∈ range n, (1 + R t)) - (∏ t ∈ range n, (1 + B t)) =
      ∑ t ∈ range n,
        (∏ s ∈ range t, (1 + R s)) * (R t - B t) * (∏ s ∈ Ico (t + 1) n, (1 + B s)) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, Finset.prod_range_succ, Finset.prod_range_succ]
    have hsum : ∑ t ∈ range n,
        (∏ s ∈ range t, (1 + R s)) * (R t - B t) * (∏ s ∈ Ico (t + 1) (n + 1), (1 + B s)) =
        (∑ t ∈ range n,
          (∏ s ∈ range t, (1 + R s)) * (R t - B t) * (∏ s ∈ Ico (t + 1) n, (1 + B s))) *
          (1 + B n) := by
      rw [Finset.sum_mul]
      refine Finset.sum_congr rfl fun t ht => ?_
      rw [Finset.mem_range] at ht
      rw [Finset.prod_Ico_succ_top (by omega)]
      ring
    rw [hsum, ← ih, Finset.Ico_self, Finset.prod_empty]
    ring

/-! The card's example, as exact fractions of 1 (0.6 = 3/5, 6.8% = 17/250, and so on).
Sector 0 is shares, sector 1 is bonds. -/

-- benchmark return B = 2.0%
example : (∑ i : Fin 2, (![1/2, 1/2] : Fin 2 → ℚ) i * (![3/50, -1/50] : Fin 2 → ℚ) i) = 1/50 := by
  norm_num [Fin.sum_univ_two]

-- fund return R = 3.2%
example : (∑ i : Fin 2, (![3/5, 2/5] : Fin 2 → ℚ) i * (![17/250, -11/500] : Fin 2 → ℚ) i) = 4/125 := by
  norm_num [Fin.sum_univ_two]

-- allocation A = 0.8 points
example : (∑ i : Fin 2, ((![3/5, 2/5] : Fin 2 → ℚ) i - (![1/2, 1/2] : Fin 2 → ℚ) i) *
    ((![3/50, -1/50] : Fin 2 → ℚ) i - 1/50)) = 1/125 := by
  norm_num [Fin.sum_univ_two]

-- selection S = 0.3 points
example : (∑ i : Fin 2, (![1/2, 1/2] : Fin 2 → ℚ) i *
    ((![17/250, -11/500] : Fin 2 → ℚ) i - (![3/50, -1/50] : Fin 2 → ℚ) i)) = 3/1000 := by
  norm_num [Fin.sum_univ_two]

-- interaction I = 0.1 points
example : (∑ i : Fin 2, ((![3/5, 2/5] : Fin 2 → ℚ) i - (![1/2, 1/2] : Fin 2 → ℚ) i) *
    ((![17/250, -11/500] : Fin 2 → ℚ) i - (![3/50, -1/50] : Fin 2 → ℚ) i)) = 1/1000 := by
  norm_num [Fin.sum_univ_two]

-- check: 0.8 + 0.3 + 0.1 = 1.2 points = 3.2% - 2.0%
example : (1/125 : ℚ) + 3/1000 + 1/1000 = 4/125 - 1/50 := by norm_num

-- two months: compounded gap 1.032 × 0.99 - 1.02 × 1.01 = -0.852 points
example : (1 + 4/125 : ℚ) * (1 - 1/100) - (1 + 1/50) * (1 + 1/100) = -213/25000 := by norm_num

-- linked: 1.2 × 1.01 + (-2.0) × 1.032 = -0.852 points
example : (4/125 - 1/50 : ℚ) * (1 + 1/100) + (1 + 4/125) * (-1/100 - 1/100) = -213/25000 := by
  norm_num

-- linked allocation 0.8 × 1.01 + 0.4 × 1.032 = 1.2208 points
example : (1/125 : ℚ) * (1 + 1/100) + (1 + 4/125) * (1/250) = 7630/625000 := by norm_num

#print axioms active_return_eq_allocation_add_selection_add_interaction
#print axioms notional_portfolios_give_allocation_selection_interaction
#print axioms compounded_active_return_eq_linked_sum
