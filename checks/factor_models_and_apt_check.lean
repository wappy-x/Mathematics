-- Factor models: covariance splits into a factor part B Ω Bᵀ plus a specific part D, no arbitrage forces expected excess returns onto the line B λ, and an equal-weight basket's specific volatility is σ / √N.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Matrix.Mul

open MeasureTheory ProbabilityTheory Matrix

/-- The covariance split of a factor model. Each fund's return is a fixed intercept, plus its
loadings times the factor returns, plus a specific part:
`y i = α i + ∑ k, B i k * f k + ε i`. If every factor and every specific part has a finite
variance, and every specific part is uncorrelated with every factor, then the funds' covariance
matrix `Σ` equals `B Ω Bᵀ + D`, where `Ω` is the factors' covariance matrix and `D` is the
specific parts' covariance matrix. No normal distributions or independence are needed. -/
theorem covariance_eq_factor_part_add_specific_part
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    {ι κ : Type*} [Fintype ι] [Fintype κ]
    (α : ι → ℝ) (B : Matrix ι κ ℝ) (f : κ → Ω → ℝ) (ε : ι → Ω → ℝ)
    (hf : ∀ k, MemLp (f k) 2 P) (hε : ∀ i, MemLp (ε i) 2 P)
    (hfε : ∀ k i, cov[f k, ε i; P] = 0)
    (y : ι → Ω → ℝ) (hy : ∀ i ω, y i ω = α i + ∑ k, B i k * f k ω + ε i ω) :
    Matrix.of (fun i j => cov[y i, y j; P]) =
      B * Matrix.of (fun k l => cov[f k, f l; P]) * Bᵀ +
        Matrix.of (fun i j => cov[ε i, ε j; P]) := by
  classical
  ext i j
  have hF : ∀ i, MemLp (fun ω => ∑ k, B i k * f k ω) 2 P := fun i =>
    memLp_finsetSum _ (fun k _ => (hf k).const_mul (B i k))
  have hyi : ∀ i, y i = fun ω => ((fun ω => ∑ k, B i k * f k ω) + ε i) ω + α i := by
    intro i; funext ω; simp only [Pi.add_apply]; rw [hy]; ring
  have hint : ∀ i, Integrable ((fun ω => ∑ k, B i k * f k ω) + ε i) P := fun i =>
    ((hF i).add (hε i)).integrable (by norm_num)
  have hFF : cov[fun ω => ∑ k, B i k * f k ω, fun ω => ∑ l, B j l * f l ω; P]
      = ∑ k, ∑ l, B i k * B j l * cov[f k, f l; P] := by
    rw [covariance_fun_sum_fun_sum (X := fun k ω => B i k * f k ω)
      (Y := fun l ω => B j l * f l ω) (fun k => (hf k).const_mul _) (fun l => (hf l).const_mul _)]
    refine Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
    rw [covariance_const_mul_left, covariance_const_mul_right]; ring
  have hFe : cov[fun ω => ∑ k, B i k * f k ω, ε j; P] = 0 := by
    rw [covariance_fun_sum_left (X := fun k ω => B i k * f k ω) (fun k => (hf k).const_mul _) (hε j)]
    refine Finset.sum_eq_zero fun k _ => ?_
    rw [covariance_const_mul_left, hfε, mul_zero]
  have heF : cov[ε i, fun ω => ∑ l, B j l * f l ω; P] = 0 := by
    rw [covariance_fun_sum_right (X := fun l ω => B j l * f l ω) (fun l => (hf l).const_mul _) (hε i)]
    refine Finset.sum_eq_zero fun l _ => ?_
    rw [covariance_const_mul_right, covariance_comm, hfε, mul_zero]
  have lhs : cov[y i, y j; P] = ∑ k, ∑ l, B i k * B j l * cov[f k, f l; P] + cov[ε i, ε j; P] := by
    rw [hyi i, hyi j, covariance_add_const_left (hint i), covariance_add_const_right (hint j),
      covariance_add_left (hF i) (hε i) ((hF j).add (hε j)),
      covariance_add_right (hF i) (hF j) (hε j), covariance_add_right (hε i) (hF j) (hε j)]
    rw [hFF, hFe, heF]; ring
  rw [Matrix.of_apply, lhs, Matrix.add_apply, Matrix.of_apply]
  congr 1
  simp only [Matrix.mul_apply, Matrix.transpose_apply, Matrix.of_apply, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => ?_
  ring

/-- Arbitrage pricing theory, exact form. Take `n` tradable portfolios whose excess returns are
`μ + B g` exactly in every state of the world, with `μ` the expected excess returns, `B` the
loadings and `g` the factor surprises (no specific part left). Suppose there is no arbitrage:
no zero-cost position `w` (financed at the bank) earns a strictly positive payoff
`w ⬝ (μ + B g)` in every state. Then expected excess returns are linear in the loadings:
`μ = B λ` for some column `λ` of factor premia. -/
theorem apt_expected_excess_returns_linear_in_loadings
    {S ι κ : Type*} [Fintype ι] [Fintype κ]
    (μ : ι → ℝ) (B : Matrix ι κ ℝ) (g : S → κ → ℝ)
    (no_arbitrage : ¬ ∃ w : ι → ℝ, ∀ s, 0 < w ⬝ᵥ (μ + B *ᵥ g s)) :
    ∃ lam : κ → ℝ, μ = B *ᵥ lam := by
  classical
  by_contra h
  push Not at h
  have hx : μ ∉ LinearMap.range (Matrix.mulVecLin B) := by
    rintro ⟨lam, hl⟩; exact h lam (by simpa using hl.symm)
  obtain ⟨φ, hφx, hφp⟩ := Submodule.exists_dual_map_eq_bot_of_notMem hx inferInstance
  set w : ι → ℝ := fun i => φ (fun j => if i = j then 1 else 0) with hw
  have hφ : ∀ v, φ v = w ⬝ᵥ v := by
    intro v; rw [LinearMap.pi_apply_eq_sum_univ]; simp [w, dotProduct, mul_comm]
  have hB : ∀ v, φ (B *ᵥ v) = 0 := by
    intro v
    have : φ (B *ᵥ v) ∈ (LinearMap.range B.mulVecLin).map φ := ⟨B *ᵥ v, ⟨v, rfl⟩, rfl⟩
    rw [hφp] at this; simpa using this
  apply no_arbitrage
  rcases lt_or_gt_of_ne hφx with hneg | hpos
  · refine ⟨-w, fun s => ?_⟩
    rw [neg_dotProduct, dotProduct_add, ← hφ, ← hφ, hB]; linarith
  · refine ⟨w, fun s => ?_⟩
    rw [dotProduct_add, ← hφ, ← hφ, hB]; linarith

/-- Specific risk diversifies. Spread money equally over `N` funds whose specific parts each have
volatility `σ` (variance `σ ^ 2`) and are pairwise uncorrelated. The basket's specific part has
variance `σ ^ 2 / N`, so its specific volatility is `σ / √N`. -/
theorem equal_weight_basket_specific_volatility
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (N : ℕ) (ε : Fin N → Ω → ℝ) (hε : ∀ i, MemLp (ε i) 2 P)
    (σ : ℝ) (hσ : 0 ≤ σ) (hvar : ∀ i, Var[ε i; P] = σ ^ 2)
    (hunc : ∀ i j, i ≠ j → cov[ε i, ε j; P] = 0) :
    Var[fun ω => (1 / N : ℝ) * ∑ i, ε i ω; P] = σ ^ 2 / N ∧
      Real.sqrt (Var[fun ω => (1 / N : ℝ) * ∑ i, ε i ω; P]) = σ / Real.sqrt N := by
  have hsum : Var[fun ω => ∑ i, ε i ω; P] = N * σ ^ 2 := by
    rw [variance_fun_sum hε]
    have : ∀ i, ∑ j, cov[ε i, ε j; P] = σ ^ 2 := by
      intro i
      rw [Finset.sum_eq_single i]
      · rw [covariance_self (hε i).aemeasurable, hvar]
      · intro j _ hj; exact hunc i j (Ne.symm hj)
      · simp
    simp [this]
  have hv : Var[fun ω => (1 / N : ℝ) * ∑ i, ε i ω; P] = σ ^ 2 / N := by
    rw [variance_const_mul, hsum]
    rcases Nat.eq_zero_or_pos N with rfl | hN
    · simp
    · field_simp
  refine ⟨hv, ?_⟩
  rw [hv, Real.sqrt_div' _ (Nat.cast_nonneg _), Real.sqrt_sq hσ]

-- Card, Step 0: for 500 funds, every pair's covariance is 125250 numbers to estimate.
example : 500 * 501 / 2 = 125250 := by norm_num

-- Card, Step 0: a three-factor model needs 3 loadings per fund, the factors' 6 covariances
-- (3 variances and 3 cross terms) and one specific variance per fund: 2006 numbers.
example : 3 * 4 / 2 = 6 := by norm_num
example : 500 * 3 + 6 + 500 = 2006 := by norm_num

#print axioms covariance_eq_factor_part_add_specific_part
#print axioms apt_expected_excess_returns_linear_in_loadings
#print axioms equal_weight_basket_specific_volatility
