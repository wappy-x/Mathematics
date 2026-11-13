-- Estimation error: on average the minimum-variance optimiser reports no more risk than the true minimum and delivers at least it, and blending the measured covariance matrix with a multiple of the identity moves every eigenvalue toward that multiple and makes the matrix invertible.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Algebra.Order.Star.Real

open Matrix MeasureTheory

/-- Reported ≤ possible ≤ delivered (Why it works, Step 1). Let `Sig` be the true covariance
matrix of `p` stocks and let `S ω` be the covariance matrix measured from history `ω`, with `n`
months, centred on the sample mean and divided by `n`, so that on average `S` equals
`(n - 1) / n` times `Sig`. Let `w ω` be the minimum-variance weights (adding to 1) under the
measured matrix and `w₀` the minimum-variance weights under the true matrix. Then on average
the optimiser's reported variance `w ω ⬝ S ω ⬝ w ω` is at most the true minimum variance
`w₀ ⬝ Sig ⬝ w₀`, and in every history the true variance of the chosen weights is at least
that true minimum. -/
theorem reported_le_possible_le_delivered
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {p : ℕ} (n : ℕ) (hn : 0 < n)
    (Sig : Matrix (Fin p) (Fin p) ℝ) (hSig : Sig.PosSemidef)
    (S : Ω → Matrix (Fin p) (Fin p) ℝ)
    (hS_int : ∀ i j, Integrable (fun ω => S ω i j) μ)
    (hS_mean : ∀ i j, ∫ ω, S ω i j ∂μ = ((n - 1 : ℝ) / n) * Sig i j)
    (w : Ω → Fin p → ℝ) (hw_sum : ∀ ω, ∑ i, w ω i = 1)
    (hw_min : ∀ ω (v : Fin p → ℝ), ∑ i, v i = 1 →
      w ω ⬝ᵥ (S ω *ᵥ w ω) ≤ v ⬝ᵥ (S ω *ᵥ v))
    (w₀ : Fin p → ℝ) (hw₀_sum : ∑ i, w₀ i = 1)
    (hw₀_min : ∀ v : Fin p → ℝ, ∑ i, v i = 1 → w₀ ⬝ᵥ (Sig *ᵥ w₀) ≤ v ⬝ᵥ (Sig *ᵥ v)) :
    (∫ ω, w ω ⬝ᵥ (S ω *ᵥ w ω) ∂μ ≤ w₀ ⬝ᵥ (Sig *ᵥ w₀)) ∧
      ∀ ω, w₀ ⬝ᵥ (Sig *ᵥ w₀) ≤ w ω ⬝ᵥ (Sig *ᵥ w ω) := by
  have hq : 0 ≤ w₀ ⬝ᵥ (Sig *ᵥ w₀) := by
    simpa using hSig.dotProduct_mulVec_nonneg w₀
  refine ⟨?_, fun ω => hw₀_min (w ω) (hw_sum ω)⟩
  have hexp : ∀ ω, w₀ ⬝ᵥ (S ω *ᵥ w₀) = ∑ i, ∑ j, w₀ i * w₀ j * S ω i j := by
    intro ω
    simp only [dotProduct, mulVec, Finset.mul_sum]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    ring
  have hg_int : Integrable (fun ω => w₀ ⬝ᵥ (S ω *ᵥ w₀)) μ := by
    simp_rw [hexp]
    refine integrable_finsetSum _ fun i _ => integrable_finsetSum _ fun j _ => ?_
    exact (hS_int i j).const_mul _
  have hg : ∫ ω, w₀ ⬝ᵥ (S ω *ᵥ w₀) ∂μ = ((n - 1 : ℝ) / n) * (w₀ ⬝ᵥ (Sig *ᵥ w₀)) := by
    simp_rw [hexp]
    rw [integral_finsetSum _ fun i _ => integrable_finsetSum _ fun j _ =>
      (hS_int i j).const_mul _]
    simp_rw [integral_finsetSum _ fun j _ => (hS_int _ j).const_mul _]
    simp_rw [integral_const_mul, hS_mean]
    simp only [dotProduct, mulVec, Finset.mul_sum]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    ring
  have hc0 : 0 ≤ ((n - 1 : ℝ) / n) := by
    have : (1 : ℝ) ≤ n := by exact_mod_cast hn
    positivity
  have hc1 : ((n - 1 : ℝ) / n) ≤ 1 := by
    have : (0 : ℝ) < n := by exact_mod_cast hn
    rw [div_le_one this]; linarith
  by_cases hf : Integrable (fun ω => w ω ⬝ᵥ (S ω *ᵥ w ω)) μ
  · calc ∫ ω, w ω ⬝ᵥ (S ω *ᵥ w ω) ∂μ ≤ ∫ ω, w₀ ⬝ᵥ (S ω *ᵥ w₀) ∂μ :=
          integral_mono hf hg_int fun ω => hw_min ω w₀ hw₀_sum
      _ = ((n - 1 : ℝ) / n) * (w₀ ⬝ᵥ (Sig *ᵥ w₀)) := hg
      _ ≤ w₀ ⬝ᵥ (Sig *ᵥ w₀) := mul_le_of_le_one_left hq hc1
  · rw [integral_undef hf]; exact hq

/-- Blending moves every eigenvalue toward the average (Why it works, Step 3). If `v` is a
direction (eigenvector) of the measured matrix `S` with eigenvalue `λ`, then `v` is still a
direction of the shrunk matrix `S* = (1 - a) S + a τ I`, and its eigenvalue becomes
`(1 - a) λ + a τ`. -/
theorem shrunk_eigenvalue {p : ℕ} (S : Matrix (Fin p) (Fin p) ℝ) (a τ lam : ℝ)
    (v : Fin p → ℝ) (hv : S *ᵥ v = lam • v) :
    ((1 - a) • S + (a * τ) • (1 : Matrix (Fin p) (Fin p) ℝ)) *ᵥ v
      = ((1 - a) * lam + a * τ) • v := by
  rw [add_mulVec, smul_mulVec, smul_mulVec, one_mulVec, hv, smul_smul, add_smul]

/-- Shrinkage can always be inverted (Why it works, Step 3). If the measured matrix `S` is a
covariance matrix (positive semidefinite), even a singular one from fewer months than stocks,
the average variance `τ` is positive, and the intensity `a` is positive and at most 1, then
the shrunk matrix `(1 - a) S + a τ I` is positive definite, so its smallest eigenvalue is
above zero and it has an inverse. -/
theorem shrunk_posDef {p : ℕ} (S : Matrix (Fin p) (Fin p) ℝ) (hS : S.PosSemidef)
    (a τ : ℝ) (ha0 : 0 < a) (ha1 : a ≤ 1) (hτ : 0 < τ) :
    ((1 - a) • S + (a * τ) • (1 : Matrix (Fin p) (Fin p) ℝ)).PosDef ∧
      IsUnit ((1 - a) • S + (a * τ) • (1 : Matrix (Fin p) (Fin p) ℝ)) := by
  have hpd : ((1 - a) • S + (a * τ) • (1 : Matrix (Fin p) (Fin p) ℝ)).PosDef :=
    PosDef.posSemidef_add (hS.smul (by linarith)) (PosDef.one.smul (by positivity))
  exact ⟨hpd, hpd.isUnit⟩

#print axioms reported_le_possible_le_delivered
#print axioms shrunk_eigenvalue
#print axioms shrunk_posDef
