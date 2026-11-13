-- Key-rate durations: when the tents add up to one at every maturity, the key-rate DV01s add up to the ordinary DV01, a book with every key-rate DV01 at zero is flat to first order against every tent-shaped curve move, and an upper triangular hedge table with no zero on its diagonal gives exactly one set of hedge notionals.
import Mathlib.Analysis.Calculus.FDeriv.Add
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Asymptotics Filter Topology

/-! A curve is a vector of zero rates `z : τ → ℝ`, one per maturity in the finite set `τ`.
A position's value is a function `V` of the curve. A tent is a curve move `w : τ → ℝ`
(its height at each maturity). One basis point is `δ`. -/

/-- Key-rate DV01 for the tent `w` (first-order form): minus `δ` times the derivative of
the value in the direction of the tent, i.e. `-δ ∑ₜ (∂V/∂zₜ) w(t)`. -/
noncomputable def keyRateDV01 {τ : Type*} [Fintype τ] (V : (τ → ℝ) → ℝ) (z : τ → ℝ)
    (δ : ℝ) (w : τ → ℝ) : ℝ :=
  -δ * fderiv ℝ V z w

/-- Ordinary (parallel) DV01 (first-order form): the key-rate DV01 of the move that raises
every zero rate by the same amount. -/
noncomputable def dv01 {τ : Type*} [Fintype τ] (V : (τ → ℝ) → ℝ) (z : τ → ℝ) (δ : ℝ) : ℝ :=
  -δ * fderiv ℝ V z (fun _ => 1)

/-- Sum rule. If the tents add up to 1 at every maturity, then the key-rate DV01s of any
position add up to its ordinary DV01. -/
theorem key_rate_dv01s_sum_to_dv01 {τ ι : Type*} [Fintype τ] [Fintype ι]
    (V : (τ → ℝ) → ℝ) (z : τ → ℝ) (δ : ℝ) (w : ι → τ → ℝ)
    (hw : ∀ t, ∑ k, w k t = 1) :
    ∑ k, keyRateDV01 V z δ (w k) = dv01 V z δ := by
  have h : (∑ k, w k) = fun _ => (1 : ℝ) := by
    funext t; simp [Finset.sum_apply, hw t]
  simp only [keyRateDV01, dv01]
  rw [← Finset.mul_sum, ← map_sum, h]

/-- Flat book. If a book's value is differentiable at today's curve and every one of its
key-rate DV01s is zero, then for every curve move built from the tents (pillar moves `a k`,
move `∑ₖ a k • w k`), the change in value is smaller than first order in the size of the
move: the book is flat to first order against every tent-shaped move. -/
theorem zero_key_rates_flat_against_tent_moves {τ ι : Type*} [Fintype τ] [Fintype ι]
    (V : (τ → ℝ) → ℝ) (z : τ → ℝ) (δ : ℝ) (hδ : δ ≠ 0) (w : ι → τ → ℝ)
    (hV : DifferentiableAt ℝ V z)
    (h0 : ∀ k, keyRateDV01 V z δ (w k) = 0) :
    (fun a : ι → ℝ => V (z + ∑ k, a k • w k) - V z) =o[𝓝 0] (fun a => ‖a‖) := by
  set L := fderiv ℝ V z with hL
  have hLw : ∀ k, L (w k) = 0 := by
    intro k
    have := h0 k
    simp only [keyRateDV01] at this
    rcases mul_eq_zero.mp this with h | h
    · exact absurd (neg_eq_zero.mp h) hδ
    · exact h
  let g : (ι → ℝ) →L[ℝ] (τ → ℝ) :=
    ∑ k, (ContinuousLinearMap.proj k : (ι → ℝ) →L[ℝ] ℝ).smulRight (w k)
  have hg : ∀ a, g a = ∑ k, a k • w k := by
    intro a
    simp [g]
  have hf : HasFDerivAt (fun a : ι → ℝ => z + g a) g 0 := by
    exact g.hasFDerivAt.const_add z
  have hV' : HasFDerivAt V L ((fun a : ι → ℝ => z + g a) 0) := by
    simpa using hV.hasFDerivAt
  have hF := hV'.comp (0 : ι → ℝ) hf
  have hzero : L.comp g = 0 := by
    ext a
    simp only [ContinuousLinearMap.comp_apply, hg, map_sum, map_smul, hLw, smul_zero,
      Finset.sum_const_zero, zero_apply]
  rw [hzero] at hF
  have := hF.isLittleO.norm_right
  simpa [Function.comp_def, hg] using this

/-- Hedge existence and uniqueness. If the swaps' key-rate table (rows: pillars, columns:
swaps, both in maturity order) is upper triangular with no zero on its diagonal, then for
any key-rate DV01s of the bond there is exactly one set of swap notionals whose key-rate
DV01s match them at every pillar. -/
theorem triangular_hedge_exists_unique {n : ℕ} (M : Matrix (Fin n) (Fin n) ℝ)
    (hM : M.BlockTriangular id) (hdiag : ∀ i, M i i ≠ 0) (KR : Fin n → ℝ) :
    ∃! h : Fin n → ℝ, M.mulVec h = KR := by
  have hdet : IsUnit M.det := by
    rw [Matrix.det_of_isUpperTriangular hM]
    exact isUnit_iff_ne_zero.mpr (Finset.prod_ne_zero_iff.mpr fun i _ => hdiag i)
  refine ⟨M⁻¹.mulVec KR, ?_, ?_⟩
  · show M.mulVec (M⁻¹.mulVec KR) = KR
    rw [Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hdet, Matrix.one_mulVec]
  · intro h hh
    show h = M⁻¹.mulVec KR
    rw [← hh, Matrix.mulVec_mulVec, Matrix.nonsing_inv_mul _ hdet, Matrix.one_mulVec]

/-! The card's three tents, with pillars at 2, 5 and 10 years. -/

/-- The 2-year tent. -/
noncomputable def tent2 (t : ℝ) : ℝ := if t ≤ 2 then 1 else if t ≤ 5 then (5 - t) / 3 else 0
/-- The 5-year tent. -/
noncomputable def tent5 (t : ℝ) : ℝ :=
  if t ≤ 2 then 0 else if t ≤ 5 then (t - 2) / 3 else if t ≤ 10 then (10 - t) / 5 else 0
/-- The 10-year tent. -/
noncomputable def tent10 (t : ℝ) : ℝ := if t ≤ 5 then 0 else if t ≤ 10 then (t - 5) / 5 else 1

-- The bond's final payment at 7 years: 0.60 to the 5-year pillar, 0.40 to the 10-year.
example : tent5 7 = 3 / 5 ∧ tent10 7 = 2 / 5 ∧ tent2 7 = 0 := by
  simp only [tent2, tent5, tent10]; norm_num
-- The 2-year tent at 3 and 4 years (shown as 0.67 and 0.33).
example : tent2 3 = 2 / 3 ∧ tent2 4 = 1 / 3 := by
  simp only [tent2]; norm_num
-- At every whole year from 1 to 10 the three tents add up to 1.
example : ∀ t ∈ Finset.Icc (1 : ℕ) 10, tent2 t + tent5 t + tent10 t = 1 := by
  intro t ht; fin_cases ht <;> simp only [tent2, tent5, tent10] <;> norm_num
-- In cents: 282.83 + 3,735.38 + 2,178.25 = 6,196.46.
example : (28283 : ℕ) + 373538 + 217825 = 619646 := by norm_num
-- In cents: the 5-year pillar, 43.74 + 111.24 + 199.05 + 182.37 + 3,198.98 = 3,735.38.
example : (4374 : ℕ) + 11124 + 19905 + 18237 + 319898 = 373538 := by norm_num
-- In cents: the 10-year pillar, 45.59 + 2,132.66 = 2,178.25.
example : (4559 : ℕ) + 213266 = 217825 := by norm_num

#print axioms key_rate_dv01s_sum_to_dv01
#print axioms zero_key_rates_flat_against_tent_moves
#print axioms triangular_hedge_exists_unique
