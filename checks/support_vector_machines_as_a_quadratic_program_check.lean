-- Support vector machines: any price list on the houses is a floor under every road's cost, the gap between a road and its prices is a sum of price times clearance surplus, and so a zero gap proves the road is the widest and gives every house off the kerb a price of zero.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Tactic.NormNum

open Finset

lemma svm_inner_self_eq_double_sum
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (c : ι → ℝ) :
    inner ℝ (∑ i, c i • x i) (∑ i, c i • x i)
      = ∑ i, ∑ j, c i * c j * inner ℝ (x i) (x j) := by
  rw [sum_inner]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [inner_sum]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [real_inner_smul_left, real_inner_smul_right]
  ring

lemma svm_sum_mul_inner
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (c : ι → ℝ) (w : E) :
    ∑ i, c i * inner ℝ w (x i) = inner ℝ w (∑ i, c i • x i) := by
  rw [inner_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [real_inner_smul_right]

lemma svm_double_sum_eq
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (y lam : ι → ℝ) :
    ∑ i, ∑ j, lam i * lam j * y i * y j * inner ℝ (x i) (x j)
      = ‖∑ i, (lam i * y i) • x i‖ ^ 2 := by
  rw [← real_inner_self_eq_norm_sq, svm_inner_self_eq_double_sum]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
  ring

lemma svm_dual_value_le
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (y : ι → ℝ) (hy : ∀ i, y i = 1 ∨ y i = -1)
    (w : E) (b : ℝ) (hfeas : ∀ i, 1 ≤ y i * (inner ℝ w (x i) + b))
    (lam : ι → ℝ) (hlam : ∀ i, 0 ≤ lam i) (hbal : ∑ i, lam i * y i = 0) :
    ∑ i, lam i - (1 / 2) * ∑ i, ∑ j, lam i * lam j * y i * y j * inner ℝ (x i) (x j)
      ≤ (1 / 2) * ‖w‖ ^ 2 := by
  set v : E := ∑ i, (lam i * y i) • x i with hv
  rw [svm_double_sum_eq]
  have h1 : ∑ i, lam i ≤ ∑ i, lam i * (y i * (inner ℝ w (x i) + b)) := by
    refine Finset.sum_le_sum fun i _ => ?_
    have := mul_le_mul_of_nonneg_left (hfeas i) (hlam i)
    linarith
  have h2 : ∑ i, lam i * (y i * (inner ℝ w (x i) + b)) = inner ℝ w v := by
    have : ∑ i, lam i * (y i * (inner ℝ w (x i) + b))
        = ∑ i, (lam i * y i) * inner ℝ w (x i) + b * ∑ i, lam i * y i := by
      rw [Finset.mul_sum, ← Finset.sum_add_distrib]
      refine Finset.sum_congr rfl fun i _ => ?_
      ring
    rw [this, hbal, svm_sum_mul_inner]
    ring
  have h3 : 0 ≤ ‖w - v‖ ^ 2 := by positivity
  rw [← real_inner_self_eq_norm_sq] at h3
  rw [inner_sub_left, inner_sub_right, inner_sub_right,
    real_inner_self_eq_norm_sq, real_inner_self_eq_norm_sq] at h3
  have h4 : inner ℝ v w = inner ℝ w v := real_inner_comm w v
  rw [← hv]
  linarith

lemma svm_gap_eq
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (y : ι → ℝ) (hy : ∀ i, y i = 1 ∨ y i = -1)
    (lam : ι → ℝ) (hbal : ∑ i, lam i * y i = 0) (w : E) (hw : w = ∑ i, (lam i * y i) • x i)
    (b : ℝ) :
    (1 / 2) * ‖w‖ ^ 2
      - (∑ i, lam i - (1 / 2) * ∑ i, ∑ j, lam i * lam j * y i * y j * inner ℝ (x i) (x j))
      = ∑ i, lam i * (y i * (inner ℝ w (x i) + b) - 1) := by
  have h2 : ∑ i, lam i * (y i * (inner ℝ w (x i) + b) - 1)
      = ∑ i, (lam i * y i) * inner ℝ w (x i) + b * ∑ i, lam i * y i - ∑ i, lam i := by
    rw [Finset.mul_sum, ← Finset.sum_add_distrib, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    ring
  rw [h2, hbal, svm_sum_mul_inner, svm_double_sum_eq, ← hw, real_inner_self_eq_norm_sq]
  ring

#print axioms svm_inner_self_eq_double_sum
#print axioms svm_sum_mul_inner
#print axioms svm_double_sum_eq
#print axioms svm_dual_value_le
#print axioms svm_gap_eq

/-- The widest road and its kerb houses. Houses `x i` carry labels `y i = ±1`. Suppose the road
`(w, b)` clears every house (`y i * (⟪w, x i⟫ + b) ≥ 1`), and the prices `lam i ≥ 0` balance the
two estates (`∑ lam i * y i = 0`) and build the road (`w = ∑ lam i * y i • x i`). If the dual value
`q(lam) = ∑ lam i - ½ ∑∑ lam i lam j y i y j ⟪x i, x j⟫` equals the road's cost `½‖w‖²`, then no road
that clears every house has a shorter `w` (so none is wider), and every house standing off its
kerb, with clearance score above 1, has price zero. -/
theorem widest_road_certificate_and_kerb_prices
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (y : ι → ℝ) (hy : ∀ i, y i = 1 ∨ y i = -1)
    (w : E) (b : ℝ) (hfeas : ∀ i, 1 ≤ y i * (inner ℝ w (x i) + b))
    (lam : ι → ℝ) (hlam : ∀ i, 0 ≤ lam i) (hbal : ∑ i, lam i * y i = 0)
    (hw : w = ∑ i, (lam i * y i) • x i)
    (hgap : ∑ i, lam i - (1 / 2) * ∑ i, ∑ j, lam i * lam j * y i * y j * inner ℝ (x i) (x j)
      = (1 / 2) * ‖w‖ ^ 2) :
    (∀ (w' : E) (b' : ℝ), (∀ i, 1 ≤ y i * (inner ℝ w' (x i) + b')) →
      (1 / 2) * ‖w‖ ^ 2 ≤ (1 / 2) * ‖w'‖ ^ 2) ∧
    (∀ i, 1 < y i * (inner ℝ w (x i) + b) → lam i = 0) := by
  refine ⟨fun w' b' hfeas' => ?_, fun i hi => ?_⟩
  · rw [← hgap]
    exact svm_dual_value_le x y hy w' b' hfeas' lam hlam hbal
  · have hid := svm_gap_eq x y hy lam hbal w hw b
    rw [hgap, sub_self] at hid
    have hnn : ∀ j ∈ (Finset.univ : Finset ι),
        0 ≤ lam j * (y j * (inner ℝ w (x j) + b) - 1) := fun j _ =>
      mul_nonneg (hlam j) (by linarith [hfeas j])
    have hz := (Finset.sum_eq_zero_iff_of_nonneg hnn).1 hid.symm i (Finset.mem_univ i)
    rcases mul_eq_zero.1 hz with h | h
    · exact h
    · linarith

/-- Weak duality (Step 2): any price list with every price at least zero and equal totals on the
two estates gives a dual value `q(lam)` that is a floor under the cost `½‖w‖²` of every road
`(w, b)` that clears every house. -/
theorem dual_value_le_road_cost
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (y : ι → ℝ) (hy : ∀ i, y i = 1 ∨ y i = -1)
    (w : E) (b : ℝ) (hfeas : ∀ i, 1 ≤ y i * (inner ℝ w (x i) + b))
    (lam : ι → ℝ) (hlam : ∀ i, 0 ≤ lam i) (hbal : ∑ i, lam i * y i = 0) :
    ∑ i, lam i - (1 / 2) * ∑ i, ∑ j, lam i * lam j * y i * y j * inner ℝ (x i) (x j)
      ≤ (1 / 2) * ‖w‖ ^ 2 := by
  exact svm_dual_value_le x y hy w b hfeas lam hlam hbal

/-- The gap identity (Step 3): when the road direction is built from the prices,
`w = ∑ lam i * y i • x i`, and the prices balance, `∑ lam i * y i = 0`, then for every offset `b`
the gap between the road's cost and the dual value is the sum of each price times its house's
clearance surplus: `½‖w‖² - q(lam) = ∑ lam i * (y i * (⟪w, x i⟫ + b) - 1)`. -/
theorem duality_gap_eq_sum_price_mul_surplus
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fintype ι]
    (x : ι → E) (y : ι → ℝ) (hy : ∀ i, y i = 1 ∨ y i = -1)
    (lam : ι → ℝ) (hbal : ∑ i, lam i * y i = 0) (w : E) (hw : w = ∑ i, (lam i * y i) • x i)
    (b : ℝ) :
    (1 / 2) * ‖w‖ ^ 2
      - (∑ i, lam i - (1 / 2) * ∑ i, ∑ j, lam i * lam j * y i * y j * inner ℝ (x i) (x j))
      = ∑ i, lam i * (y i * (inner ℝ w (x i) + b) - 1) := by
  exact svm_gap_eq x y hy lam hbal w hw b

/- The card's worked numbers, exactly, in fractions. Coordinates are in metres, written as
tenths: house 10 at (406/10, 507/10), house 57 at (286/10, 427/10), house 34 at (686/10, 152/10).
The road is w = (11/130, 16/130), b = -11278/1300; the prices are 1885/169000 on house 10,
1677/169000 on house 57 and 208/169000 on house 34. -/

-- The south kerb direction, house 57 to house 34, is (40, -27.5); (11, 16) is square to it.
example : (11 : ℚ) * 40 + 16 * (-55 / 2) = 0 := by norm_num

-- The length of (11, 16) is the square root of 377.
example : (11 : ℕ) ^ 2 + 16 ^ 2 = 377 := by norm_num

-- The climb from house 57 to house 10, (12, 8), along (11, 16) is 260 / √377, and the width
-- 2 / ‖w‖ squared is the same number squared: 260² / 377.
example : (11 : ℚ) * 12 + 16 * 8 = 260 := by norm_num
example : (2 : ℚ) ^ 2 / ((11 / 130) ^ 2 + (16 / 130) ^ 2) = 260 ^ 2 / 377 := by norm_num

-- The three kerb houses score exactly +1, -1 and -1.
example : (11 / 130 : ℚ) * (406 / 10) + (16 / 130) * (507 / 10) + (-11278 / 1300) = 1 := by
  norm_num
example : (11 / 130 : ℚ) * (286 / 10) + (16 / 130) * (427 / 10) + (-11278 / 1300) = -1 := by
  norm_num
example : (11 / 130 : ℚ) * (686 / 10) + (16 / 130) * (152 / 10) + (-11278 / 1300) = -1 := by
  norm_num

-- The prices balance the two estates: 1885 = 1677 + 208, and Southgate's split is the
-- foot of the square from house 10 onto the south kerb, 208 / 1885 of the way from 57 to 34.
example : (1885 : ℚ) / 169000 - 1677 / 169000 - 208 / 169000 = 0 := by norm_num
example : ((12 : ℚ) * 40 + 8 * (-55 / 2)) / (40 ^ 2 + (55 / 2) ^ 2) = 208 / 1885 := by norm_num

-- The prices build the road: w = ∑ lam i * y i • x i, coordinate by coordinate.
example : (1885 : ℚ) / 169000 * (406 / 10) - 1677 / 169000 * (286 / 10)
    - 208 / 169000 * (686 / 10) = 11 / 130 := by norm_num
example : (1885 : ℚ) / 169000 * (507 / 10) - 1677 / 169000 * (427 / 10)
    - 208 / 169000 * (152 / 10) = 16 / 130 := by norm_num

-- Zero gap: the dual value (sum of prices minus half of ‖w‖²) equals the road's cost ½‖w‖²,
-- both 377/33800, and the prices sum to ‖w‖².
example : ((1885 : ℚ) + 1677 + 208) / 169000 - (1 / 2) * ((11 / 130) ^ 2 + (16 / 130) ^ 2)
    = (1 / 2) * ((11 / 130) ^ 2 + (16 / 130) ^ 2) := by norm_num
example : (1 / 2 : ℚ) * ((11 / 130) ^ 2 + (16 / 130) ^ 2) = 377 / 33800 := by norm_num

-- The lost record at (60, 45) scores 97/50 = 1.94, positive: Northfield.
example : (11 / 130 : ℚ) * 60 + (16 / 130) * 45 + (-11278 / 1300) = 97 / 50 := by norm_num

#print axioms widest_road_certificate_and_kerb_prices
#print axioms dual_value_le_road_cost
#print axioms duality_gap_eq_sum_price_mul_surplus
