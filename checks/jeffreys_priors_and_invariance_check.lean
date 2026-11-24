-- Jeffreys priors: rewriting the parameter multiplies the Fisher information by the square of the stretch factor, so the Jeffreys prior is the same belief on every scale, and for the coin it is Beta(1/2, 1/2).
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Probability.Distributions.Bernoulli
import Mathlib.Probability.Distributions.Beta
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory Filter Topology

/-- The Fisher information of one observation at `θ`: the average, under the law `P θ`, of the
squared score, where the score is the slope in `θ` of the log-likelihood `ℓ θ x`. -/
noncomputable def fisherInfo {Ω : Type*} [MeasurableSpace Ω] (P : ℝ → Measure Ω)
    (ℓ : ℝ → Ω → ℝ) (θ : ℝ) : ℝ :=
  ∫ x, (deriv (fun t => ℓ t x) θ) ^ 2 ∂(P θ)

/-- One flip of a coin with chance of heads `θ` (heads is `true`), using Mathlib's Bernoulli law;
outside `[0, 1]` the chance is clipped, which never matters for `0 < θ < 1`. -/
noncomputable def coinLaw (θ : ℝ) : Measure Bool :=
  bernoulliMeasure true false (Set.projIcc (0 : ℝ) 1 zero_le_one θ)

/-- The log-likelihood of one flip: `log θ` for a head, `log (1 - θ)` for a tail. -/
noncomputable def coinLogLik (θ : ℝ) (b : Bool) : ℝ :=
  if b then Real.log θ else Real.log (1 - θ)

/-- Rewrite the parameter as `φ`, with `θ = h φ`. If the model is smooth (each log-likelihood has
a slope at `h φ`) and the relabelling is smooth at `φ`, the information on the new scale is the
old information times the square of the stretch factor `dθ/dφ`, so its square root is the old
root times the stretch factor `|dθ/dφ|`: exactly how a density must change. -/
theorem fisher_info_scales_by_square_of_stretch_factor {Ω : Type*} [MeasurableSpace Ω]
    (P : ℝ → Measure Ω) (ℓ : ℝ → Ω → ℝ) (h : ℝ → ℝ) (φ : ℝ)
    (hh : DifferentiableAt ℝ h φ)
    (hℓ : ∀ x, DifferentiableAt ℝ (fun t => ℓ t x) (h φ)) :
    fisherInfo (fun ψ => P (h ψ)) (fun ψ x => ℓ (h ψ) x) φ
        = fisherInfo P ℓ (h φ) * (deriv h φ) ^ 2 ∧
      Real.sqrt (fisherInfo (fun ψ => P (h ψ)) (fun ψ x => ℓ (h ψ) x) φ)
        = Real.sqrt (fisherInfo P ℓ (h φ)) * |deriv h φ| := by
  have hd : ∀ x, deriv (fun t => ℓ (h t) x) φ = deriv (fun t => ℓ t x) (h φ) * deriv h φ := by
    intro x
    exact deriv_comp (h := h) (h₂ := fun t => ℓ t x) φ (hℓ x) hh
  have h1 : fisherInfo (fun ψ => P (h ψ)) (fun ψ x => ℓ (h ψ) x) φ
      = fisherInfo P ℓ (h φ) * (deriv h φ) ^ 2 := by
    unfold fisherInfo
    simp_rw [hd, mul_pow]
    exact integral_mul_const _ _
  refine ⟨h1, ?_⟩
  rw [h1, Real.sqrt_mul' _ (sq_nonneg _), Real.sqrt_sq_eq_abs]

/-- The Jeffreys prior does not depend on the label. Write the parameter as `φ = g θ`, with
`h` undoing `g` near `θ`. The Jeffreys prior built on the `φ` scale, `√I_φ`, carried back to the
`θ` scale by the stretch factor `|dφ/dθ|`, is the Jeffreys prior built on `θ`, `√I_θ`. -/
theorem jeffreys_prior_same_on_every_scale {Ω : Type*} [MeasurableSpace Ω]
    (P : ℝ → Measure Ω) (ℓ : ℝ → Ω → ℝ) (g h : ℝ → ℝ) (θ : ℝ)
    (hhg : ∀ᶠ t in 𝓝 θ, h (g t) = t)
    (hg : DifferentiableAt ℝ g θ) (hh : DifferentiableAt ℝ h (g θ))
    (hℓ : ∀ x, DifferentiableAt ℝ (fun t => ℓ t x) θ) :
    Real.sqrt (fisherInfo (fun ψ => P (h ψ)) (fun ψ x => ℓ (h ψ) x) (g θ)) * |deriv g θ|
      = Real.sqrt (fisherInfo P ℓ θ) := by
  have hθ : h (g θ) = θ := hhg.self_of_nhds
  have hℓ' : ∀ x, DifferentiableAt ℝ (fun t => ℓ t x) (h (g θ)) := by
    intro x; rw [hθ]; exact hℓ x
  have key := (fisher_info_scales_by_square_of_stretch_factor P ℓ h (g θ) hh hℓ').2
  have hc : deriv h (g θ) * deriv g θ = 1 := by
    have e : deriv (h ∘ g) θ = deriv (fun t => t) θ := Filter.EventuallyEq.deriv_eq hhg
    rw [deriv_comp θ hh hg, deriv_id''] at e
    exact e
  rw [key, hθ, mul_assoc, ← abs_mul, hc, abs_one, mul_one]

/-- The coin: one flip has Fisher information `1/(θ(1 - θ))`, and its square root is `π` times
the Beta(1/2, 1/2) density, so the Jeffreys prior for the coin is Beta(1/2, 1/2). -/
theorem coin_jeffreys_prior_is_beta_half_half (θ : ℝ) (h0 : 0 < θ) (h1 : θ < 1) :
    fisherInfo coinLaw coinLogLik θ = 1 / (θ * (1 - θ)) ∧
      Real.sqrt (fisherInfo coinLaw coinLogLik θ) = Real.pi * betaPDFReal (1 / 2) (1 / 2) θ := by
  have hθ1 : 0 < 1 - θ := by linarith
  have hproj : (Set.projIcc (0 : ℝ) 1 zero_le_one θ : ℝ) = θ := by
    rw [Set.projIcc_of_mem _ ⟨h0.le, h1.le⟩]
  have dT : deriv (fun t => coinLogLik t true) θ = 1 / θ := by
    simp only [coinLogLik, ite_true]
    rw [Real.deriv_log, one_div]
  have dF : deriv (fun t => coinLogLik t false) θ = -(1 / (1 - θ)) := by
    simp only [coinLogLik, Bool.false_eq_true, ite_false]
    have := ((hasDerivAt_id' θ).const_sub 1).log hθ1.ne'
    rw [this.deriv]
    simp; ring
  have hI : fisherInfo coinLaw coinLogLik θ = 1 / (θ * (1 - θ)) := by
    unfold fisherInfo coinLaw
    rw [integral_bernoulliMeasure, hproj, dT, dF]
    simp only [smul_eq_mul]
    field_simp
    ring
  refine ⟨hI, ?_⟩
  have hB : beta (1 / 2) (1 / 2) = Real.pi := by
    unfold beta
    rw [Real.Gamma_one_half_eq, show (1 / 2 : ℝ) + 1 / 2 = 1 by norm_num, Real.Gamma_one,
      div_one, Real.mul_self_sqrt Real.pi_pos.le]
  rw [hI, betaPDFReal, ite_eq_left_of_eq_true _ _ (eq_true ⟨h0, h1⟩), hB]
  have e : (1 / 2 : ℝ) - 1 = -(1 / 2) := by norm_num
  rw [e, Real.rpow_neg h0.le, Real.rpow_neg hθ1.le, ← Real.sqrt_eq_rpow, ← Real.sqrt_eq_rpow,
    Real.sqrt_div' _ (mul_pos h0 hθ1).le, Real.sqrt_one, Real.sqrt_mul h0.le]
  field_simp

-- Information per flip at θ = 1/2 and at θ = 1/10: 4 and 100/9 (the card's 11.1111).
example : (1 : ℚ) / ((1 / 2) * (1 - 1 / 2)) = 4 := by norm_num
example : (1 : ℚ) / ((1 / 10) * (1 - 1 / 10)) = 100 / 9 := by norm_num
-- The new coin, 7 heads in 10. Jeffreys Beta(1/2, 1/2) to Beta(7.5, 3.5): mean 7.5/11 = 15/22.
example : ((1 / 2 : ℚ) + 7) / ((1 / 2 + 7) + (1 / 2 + 3)) = 15 / 22 := by norm_num
-- Its posterior variance 7.5 × 3.5 / (11² × 12) = 35/1936 (standard deviation 0.1345).
example : ((15 / 2 : ℚ) * (7 / 2)) / (11 ^ 2 * 12) = 35 / 1936 := by norm_num
-- Flat on θ, Beta(1, 1) to Beta(8, 4): mean 2/3.
example : ((1 : ℚ) + 7) / ((1 + 7) + (1 + 3)) = 2 / 3 := by norm_num
-- Flat on θ², Beta(2, 1) to Beta(9, 4): mean 9/13 (the card's 0.6923).
example : ((2 : ℚ) + 7) / ((2 + 7) + (1 + 3)) = 9 / 13 := by norm_num
-- The information itself, not its root, Beta(0, 0) to Beta(7, 3): mean 7/10.
example : ((0 : ℚ) + 7) / ((0 + 7) + (0 + 3)) = 7 / 10 := by norm_num
-- Flip until the 7th head: information 7/(θ²(1 - θ)) is 56 at θ = 1/2; Beta(7, 3.5) has mean 2/3.
example : (7 : ℚ) / ((1 / 2) ^ 2 * (1 - 1 / 2)) = 56 := by norm_num
example : (7 : ℚ) / (7 + 7 / 2) = 2 / 3 := by norm_num
-- Poisson rate, 45 emails in 3 hours: Jeffreys Gamma(45.5, 3) mean 91/6 (15.1667 an hour);
-- flat on λ Gamma(46, 3) mean 46/3; flat on log λ Gamma(45, 3) mean 15; zero emails, Jeffreys 1/6.
example : ((1 / 2 : ℚ) + 45) / 3 = 91 / 6 := by norm_num
example : ((1 : ℚ) + 45) / 3 = 46 / 3 := by norm_num
example : ((0 : ℚ) + 45) / 3 = 15 := by norm_num
example : ((1 / 2 : ℚ) + 0) / 3 = 1 / 6 := by norm_num
-- Normal spread: fill errors 1, -3, 2, -1, 1 ml have sum of squares Q = 16.
example : (([1, -3, 2, -1, 1] : List ℤ).map (fun x => x ^ 2)).sum = 16 := by decide
-- Information 2/σ² is 1/2 at σ = 2.
example : (2 : ℚ) / 2 ^ 2 = 1 / 2 := by norm_num
-- E σ² = (Q/2)/(a - 1): Jeffreys a = 5/2 gives 16/3; flat in σ, a = 2, gives 8; flat in σ², a = 3/2, gives 16.
example : ((16 : ℚ) / 2) / (5 / 2 - 1) = 16 / 3 := by norm_num
example : ((16 : ℚ) / 2) / (2 - 1) = 8 := by norm_num
example : ((16 : ℚ) / 2) / (3 / 2 - 1) = 16 := by norm_num

#print axioms fisher_info_scales_by_square_of_stretch_factor
#print axioms jeffreys_prior_same_on_every_scale
#print axioms coin_jeffreys_prior_is_beta_half_half
