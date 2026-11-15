-- Neumann series: if a bounded linear map K on a complete normed space has ‖K‖ < 1, then x = b + Kx has exactly one solution, the sum b + Kb + K²b + ⋯, and after n terms the error is at most ‖K‖ⁿ‖b‖ / (1 − ‖K‖).
import Mathlib.Analysis.Normed.Operator.NormedSpace
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.Normed.Ring.Units
import Mathlib.Topology.Algebra.InfiniteSum.Module

open Finset Matrix

/-- If a linear map `K` on a complete normed space never stretches an input by more than a
factor `‖K‖ < 1`, then `x = b + K x` has exactly one solution `x`, the series
`b + K b + K² b + ⋯` adds up to it, and after `n` terms the error is at most
`‖K‖ⁿ ‖b‖ / (1 − ‖K‖)`. -/
theorem neumann_series_solves_with_error_bound
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (K : X →L[ℝ] X) (hK : ‖K‖ < 1) (b : X) :
    ∃ x : X, x = b + K x ∧ (∀ y : X, y = b + K y → y = x) ∧
      HasSum (fun k : ℕ => (K ^ k) b) x ∧
      ∀ n : ℕ, ‖x - ∑ k ∈ range n, (K ^ k) b‖ ≤ ‖K‖ ^ n * ‖b‖ / (1 - ‖K‖) := by
  have hn0 : 0 ≤ ‖K‖ := norm_nonneg K
  set g : ℕ → X := fun k => (K ^ k) b with hg
  have hbound : ∀ k, ‖g k‖ ≤ ‖K‖ ^ k * ‖b‖ := by
    intro k
    induction k with
    | zero => simp [g]
    | succ k ih =>
      have : g (k + 1) = K (g k) := by
        simp only [g, pow_succ']; rfl
      rw [this, pow_succ', mul_assoc]
      exact (K.le_opNorm _).trans (mul_le_mul_of_nonneg_left ih hn0)
  have hgeo : Summable (fun k : ℕ => ‖K‖ ^ k * ‖b‖) :=
    (summable_geometric_of_lt_one hn0 hK).mul_right _
  have hsum : Summable g := Summable.of_norm_bounded hgeo hbound
  refine ⟨∑' k, g k, ?_, ?_, hsum.hasSum, ?_⟩
  · have h1 : K (∑' k, g k) = ∑' k, g (k + 1) := by
      rw [K.map_tsum hsum]
      congr 1
      funext k
      simp only [g, pow_succ']; rfl
    rw [h1, hsum.tsum_eq_zero_add]
    simp [g]
  · intro y hy
    have hfix : (∑' k, g k) = b + K (∑' k, g k) := by
      have h1 : K (∑' k, g k) = ∑' k, g (k + 1) := by
        rw [K.map_tsum hsum]
        congr 1
        funext k
        simp only [g, pow_succ']; rfl
      rw [h1, hsum.tsum_eq_zero_add]
      simp [g]
    have hd : y - ∑' k, g k = K (y - ∑' k, g k) := by
      rw [map_sub]
      nth_rewrite 1 [hy, hfix]
      abel
    have hle : ‖y - ∑' k, g k‖ ≤ ‖K‖ * ‖y - ∑' k, g k‖ := by
      nth_rewrite 1 [hd]
      exact K.le_opNorm _
    have hz : ‖y - ∑' k, g k‖ = 0 := by
      have := norm_nonneg (y - ∑' k, g k)
      nlinarith
    exact sub_eq_zero.mp (norm_eq_zero.mp hz)
  · intro n
    rw [← hsum.sum_add_tsum_nat_add n, add_sub_cancel_left]
    have hs : HasSum (fun k : ℕ => ‖K‖ ^ (k + n) * ‖b‖) (‖K‖ ^ n * ‖b‖ / (1 - ‖K‖)) := by
      have := (hasSum_geometric_of_lt_one hn0 hK).mul_left (‖K‖ ^ n * ‖b‖)
      convert this using 1
      · funext k
        rw [pow_add]
        ring
      · field_simp
    exact tsum_of_norm_bounded hs (fun k => hbound (k + n))

/-- The series of maps `I + K + K² + ⋯` itself converges in the operator norm, its sum is a
two-sided inverse of `I − K`, and that inverse has norm at most `1 / (1 − ‖K‖)`. -/
theorem neumann_series_inverts_one_sub
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (K : X →L[ℝ] X) (hK : ‖K‖ < 1) :
    ∃ T : X →L[ℝ] X, HasSum (fun k : ℕ => K ^ k) T ∧
      (1 - K) * T = 1 ∧ T * (1 - K) = 1 ∧ ‖T‖ ≤ 1 / (1 - ‖K‖) := by
  have hs : Summable (fun k : ℕ => K ^ k) := summable_geometric_of_norm_lt_one hK
  refine ⟨∑' k, K ^ k, hs.hasSum, mul_neg_geom_series K hK, geom_series_mul_neg K hK, ?_⟩
  have h := tsum_geometric_le_of_norm_lt_one K hK
  have h1 : ‖(1 : X →L[ℝ] X)‖ ≤ 1 := ContinuousLinearMap.norm_id_le
  rw [one_div]
  linarith

/-- Small changes never destroy an inverse: if `A` has a bounded inverse `A⁻¹` and
`‖E‖ < 1 / ‖A⁻¹‖`, then `A + E` has a bounded two-sided inverse too. -/
theorem invertible_of_small_perturbation
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (A Ainv E : X →L[ℝ] X) (hright : A * Ainv = 1) (hleft : Ainv * A = 1)
    (hE : ‖E‖ < 1 / ‖Ainv‖) :
    ∃ B : X →L[ℝ] X, (A + E) * B = 1 ∧ B * (A + E) = 1 := by
  have hpos : 0 < ‖Ainv‖ := by
    by_contra h
    have h0 : ‖Ainv‖ = 0 := le_antisymm (not_lt.mp h) (norm_nonneg _)
    rw [h0, div_zero] at hE
    exact absurd hE (not_lt.mpr (norm_nonneg _))
  let u : (X →L[ℝ] X)ˣ := ⟨A, Ainv, hright, hleft⟩
  have hE' : ‖E‖ < ‖(↑u⁻¹ : X →L[ℝ] X)‖⁻¹ := by
    simpa [u, one_div] using hE
  let v := u.add E hE'
  have hv : (v : X →L[ℝ] X) = A + E := by simp [v, u]
  refine ⟨↑v⁻¹, ?_, ?_⟩
  · rw [← hv]; exact v.mul_inv
  · rw [← hv]; exact v.inv_mul

/-! ### The card's worked numbers, exactly, with shares as fractions -/

/-- The three departments' shares: rows IT, HR, Facilities. -/
abbrev shares : Matrix (Fin 3) (Fin 3) ℚ :=
  !![0, 1/10, 1/5; 3/20, 0, 1/10; 1/20, 1/10, 0]

/-- The direct costs in pounds. -/
abbrev direct : Fin 3 → ℚ := ![40000, 20000, 30000]

-- The loop strength q: the row sums are 0.30, 0.25 and 0.15.
example : (∑ j, |shares 0 j|, ∑ j, |shares 1 j|, ∑ j, |shares 2 j|)
    = ((3 : ℚ)/10, (1 : ℚ)/4, (3 : ℚ)/20) := by
  simp [shares, Fin.sum_univ_three]; norm_num

-- Second term: Kb = (8000, 9000, 4000).
example : shares *ᵥ direct = ![8000, 9000, 4000] := by
  ext i; fin_cases i <;> simp [shares, direct, Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;>
    norm_num

-- Third term: K²b = (1700, 1600, 1300).
example : shares *ᵥ (shares *ᵥ direct) = ![1700, 1600, 1300] := by
  ext i; fin_cases i <;> simp [shares, direct, Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;>
    norm_num

-- S₃ = b + Kb + K²b = (49700, 30600, 35300).
example : direct + shares *ᵥ direct + shares *ᵥ (shares *ᵥ direct)
    = ![49700, 30600, 35300] := by
  ext i; fin_cases i <;> simp [shares, direct, dotProduct, Fin.sum_univ_three, vecHead, vecTail] <;>
    norm_num

/-- The full costs exactly, as fractions of a pound: about 50234.01, 31097.24 and 35621.42. -/
abbrev fullCosts : Fin 3 → ℚ := ![32200000/641, 59800000/1923, 68500000/1923]

-- The full costs solve x = b + Kx.
example : fullCosts = direct + shares *ᵥ fullCosts := by
  ext i; fin_cases i <;> simp [fullCosts, shares, direct, vecHead, vecTail] <;> norm_num

-- Charging out: each department keeps 1 minus its column sum of its full cost for the
-- earning departments, and these add back to the 90000 pounds spent.
example : ∑ j, (1 - ∑ i, shares i j) * fullCosts j = ∑ j, direct j := by
  simp [fullCosts, shares, direct, Fin.sum_univ_three]; norm_num

-- Rounds the promise needs for £1: 0.3ⁿ × 40000 / 0.7 ≤ 1 first at n = 10.
example : ((3 : ℚ)/10) ^ 10 * 40000 / (7/10) ≤ 1 ∧ 1 < ((3 : ℚ)/10) ^ 9 * 40000 / (7/10) := by
  norm_num

-- Norm 2, yet the series converges: K₂ = [[0, 2], [1/10, 0]] squares to (1/5) I,
-- and x = (15/4, 11/8) = (3.75, 1.375) solves x = (1, 1) + K₂ x.
example : (!![0, 2; 1/10, 0] : Matrix (Fin 2) (Fin 2) ℚ) * !![0, 2; 1/10, 0]
    = !![1/5, 0; 0, 1/5] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> norm_num

example : (![15/4, 11/8] : Fin 2 → ℚ)
    = ![1, 1] + (!![0, 2; 1/10, 0] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![15/4, 11/8] := by
  ext i; fin_cases i <;> simp [vecHead, vecTail] <;> norm_num

-- A loop too strong: A = 100 + 1.25 B, B = 0.9 A has loop gain 1.125 and only the solution
-- A = −800, B = −720.
example : ((5 : ℚ)/4) * (9/10) = 9/8 ∧ (-800 : ℚ) = 100 + 5/4 * (-720) ∧ (-720 : ℚ) = 9/10 * (-800) := by
  norm_num

-- Stopping when a round changes x = 100 + 0.9x by under £1: the change 100 × 0.9ⁿ⁻¹ first
-- drops below 1 at round n = 45.
example : (100 : ℚ) * (9/10) ^ 44 < 1 ∧ 1 ≤ (100 : ℚ) * (9/10) ^ 43 := by
  norm_num

#print axioms neumann_series_solves_with_error_bound
#print axioms neumann_series_inverts_one_sub
#print axioms invertible_of_small_perturbation
