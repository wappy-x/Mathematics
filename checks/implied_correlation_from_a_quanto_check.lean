-- Correlation from a quanto price: in the quanto call model the price falls strictly as the correlation rises, so a quote names exactly one correlation in [-1, 1] when it lies between the prices at +1 and -1, and none otherwise.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open ProbabilityTheory

namespace QuantoImpliedCorrelation

/-- The standard normal distribution function `N(x)`: the bell-curve area left of `x`. -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The quanto forward `F_Q(ρ) = S · exp((r_f - q - ρ σ_S σ_X) T)`, in euros. -/
noncomputable def quantoForward (S rf q σS σX T ρ : ℝ) : ℝ :=
  S * Real.exp ((rf - q - ρ * σS * σX) * T)

/-- The cut-off `d₁ = (ln(F_Q/K) + σ_S² T / 2) / (σ_S √T)`. -/
noncomputable def d1 (S K rf q σS σX T ρ : ℝ) : ℝ :=
  (Real.log (quantoForward S rf q σS σX T ρ / K) + σS ^ 2 * T / 2) / (σS * Real.sqrt T)

/-- The quanto call price
`C(ρ) = X̄ e^{-r_d T} [F_Q(ρ) N(d₁) - K N(d₂)]`, with `d₂ = d₁ - σ_S √T`. -/
noncomputable def quantoCall (Xbar S K rd rf q σS σX T ρ : ℝ) : ℝ :=
  Xbar * Real.exp (-rd * T) *
    (quantoForward S rf q σS σX T ρ * N (d1 S K rf q σS σX T ρ)
      - K * N (d1 S K rf q σS σX T ρ - σS * Real.sqrt T))

/-- `N x` is the integral of the standard normal density over `(-∞, x]`. -/
lemma N_eq_integral (x : ℝ) : N x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold N
  rw [cdf_eq_real, MeasureTheory.measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (MeasureTheory.integral_nonneg (fun _ => gaussianPDFReal_nonneg _ _ _))]

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal
  fun_prop

lemma N_sub_N (a b : ℝ) : N b - N a = ∫ t in a..b, gaussianPDFReal 0 1 t := by
  rw [N_eq_integral, N_eq_integral]
  exact intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn

lemma hasDerivAt_N (x : ℝ) : HasDerivAt N (gaussianPDFReal 0 1 x) x := by
  have h : N = fun y => N 0 + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [← N_sub_N]
    ring
  rw [h]
  exact ((continuous_stdPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma N_pos (x : ℝ) : 0 < N x := by
  have h1 := N_sub_N (x - 1) x
  have h2 : 0 < ∫ t in (x - 1)..x, gaussianPDFReal 0 1 t :=
    intervalIntegral.intervalIntegral_pos_of_pos
      (continuous_stdPDF.intervalIntegrable _ _)
      (fun t => gaussianPDFReal_pos 0 1 t one_ne_zero) (by linarith)
  have h3 : 0 ≤ N (x - 1) := cdf_nonneg _ _
  linarith

/-- The cut-off `d₁` is affine in the correlation. -/
lemma d1_eq (S K rf q σS σX T ρ : ℝ) (hS : 0 < S) (hK : 0 < K) :
    d1 S K rf q σS σX T ρ =
      (Real.log S - Real.log K + (rf - q - ρ * σS * σX) * T + σS ^ 2 * T / 2) /
        (σS * Real.sqrt T) := by
  unfold d1 quantoForward
  rw [Real.log_div (by positivity) hK.ne', Real.log_mul hS.ne' (Real.exp_pos _).ne',
    Real.log_exp]
  ring

/-- The density identity `F_Q φ(d₁) = K φ(d₁ - σ_S √T)`. -/
lemma forward_pdf_identity (S K rf q σS σX T ρ : ℝ) (hS : 0 < S) (hK : 0 < K)
    (hσS : 0 < σS) (hT : 0 < T) :
    quantoForward S rf q σS σX T ρ * gaussianPDFReal 0 1 (d1 S K rf q σS σX T ρ) =
      K * gaussianPDFReal 0 1 (d1 S K rf q σS σX T ρ - σS * Real.sqrt T) := by
  set s := σS * Real.sqrt T with hs
  have hspos : 0 < s := by positivity
  have hsq : s ^ 2 = σS ^ 2 * T := by
    rw [hs, mul_pow, Real.sq_sqrt hT.le]
  set d := d1 S K rf q σS σX T ρ with hd
  have hF : 0 < quantoForward S rf q σS σX T ρ := by
    unfold quantoForward; positivity
  have hds : d * s = Real.log (quantoForward S rf q σS σX T ρ / K) + s ^ 2 / 2 := by
    rw [hd, d1, hsq, div_mul_cancel₀ _ hspos.ne']
  have hlog : quantoForward S rf q σS σX T ρ = K * Real.exp (d * s - s ^ 2 / 2) := by
    rw [hds, add_sub_cancel_right, Real.exp_log (div_pos hF hK)]
    field_simp
  rw [hlog]
  simp only [gaussianPDFReal, NNReal.coe_one, sub_zero]
  rw [mul_assoc K, mul_comm (Real.exp _), mul_assoc, ← Real.exp_add]
  congr 3
  ring

#print axioms N_eq_integral
#print axioms continuous_stdPDF
#print axioms N_sub_N
#print axioms hasDerivAt_N
#print axioms N_pos
#print axioms d1_eq
#print axioms forward_pdf_identity

lemma quantoCall_hasDerivAt_aux
    (Xbar S K rd rf q σS σX T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T) (ρ : ℝ) :
    HasDerivAt (fun r => quantoCall Xbar S K rd rf q σS σX T r)
      (-(Xbar * Real.exp (-rd * T) * quantoForward S rf q σS σX T ρ *
          N (d1 S K rf q σS σX T ρ) * σS * σX * T)) ρ := by
  set s := σS * Real.sqrt T with hs
  have hspos : 0 < s := by positivity
  have hfun : (fun r => quantoCall Xbar S K rd rf q σS σX T r) = fun r =>
      Xbar * Real.exp (-rd * T) *
        (S * Real.exp ((rf - q - r * σS * σX) * T) *
            N ((Real.log S - Real.log K + (rf - q - r * σS * σX) * T + σS ^ 2 * T / 2) / s)
          - K * N ((Real.log S - Real.log K + (rf - q - r * σS * σX) * T + σS ^ 2 * T / 2) / s
            - s)) := by
    funext r
    rw [quantoCall, d1_eq S K rf q σS σX T r hS hK, quantoForward]
  have hlin : HasDerivAt (fun r : ℝ => (rf - q - r * σS * σX) * T) (-(σS * σX) * T) ρ := by
    have := ((hasDerivAt_id ρ).mul_const (σS * σX)).const_sub (rf - q) |>.mul_const T
    convert this using 1
    · funext r; simp only [id]; ring
    · ring
  have hF : HasDerivAt (fun r : ℝ => S * Real.exp ((rf - q - r * σS * σX) * T))
      (S * (Real.exp ((rf - q - ρ * σS * σX) * T) * (-(σS * σX) * T))) ρ :=
    (hlin.exp).const_mul S
  have hd : HasDerivAt (fun r : ℝ =>
      (Real.log S - Real.log K + (rf - q - r * σS * σX) * T + σS ^ 2 * T / 2) / s)
      ((-(σS * σX) * T) / s) ρ :=
    ((hlin.const_add (Real.log S - Real.log K)).add_const (σS ^ 2 * T / 2)).div_const s
  set d := (Real.log S - Real.log K + (rf - q - ρ * σS * σX) * T + σS ^ 2 * T / 2) / s
    with hdd
  have hN1 := (hasDerivAt_N d).comp ρ hd
  have hN2 := (hasDerivAt_N (d - s)).comp ρ (hd.sub_const s)
  have key := forward_pdf_identity S K rf q σS σX T ρ hS hK hσS hT
  rw [d1_eq S K rf q σS σX T ρ hS hK] at key
  rw [hfun]
  have htot := ((hF.mul hN1).sub (hN2.const_mul K)).const_mul (Xbar * Real.exp (-rd * T))
  refine htot.congr_deriv ?_
  rw [d1_eq S K rf q σS σX T ρ hS hK]
  unfold quantoForward at key ⊢
  simp only [Function.comp_apply]
  rw [← hs, ← hdd] at key ⊢
  linear_combination (Xbar * Real.exp (-rd * T) * ((-(σS * σX) * T) / s)) * key

lemma quantoCall_strictAnti_aux
    (Xbar S K rd rf q σS σX T : ℝ)
    (hXbar : 0 < Xbar) (hS : 0 < S) (hK : 0 < K)
    (hσS : 0 < σS) (hσX : 0 < σX) (hT : 0 < T) :
    StrictAnti (fun ρ => quantoCall Xbar S K rd rf q σS σX T ρ) := by
  refine strictAnti_of_hasDerivAt_neg
    (fun ρ => quantoCall_hasDerivAt_aux Xbar S K rd rf q σS σX T hS hK hσS hT ρ) ?_
  intro ρ
  have hF : 0 < quantoForward S rf q σS σX T ρ := by
    unfold quantoForward; positivity
  have hN := N_pos (d1 S K rf q σS σX T ρ)
  apply neg_neg_of_pos
  positivity

#print axioms quantoCall_hasDerivAt_aux
#print axioms quantoCall_strictAnti_aux

/-- **Implied correlation exists and is unique exactly inside the band.**
With a positive fixed rate, share price, strike, both volatilities and time to expiry
(any rates and dividend), a quoted quanto price `Cm` is matched by exactly one correlation
`ρ ∈ [-1, 1]` if and only if `C(1) ≤ Cm ≤ C(-1)`. A quote outside that band names no correlation. -/
theorem implied_correlation_exists_unique_iff_in_band
    (Xbar S K rd rf q σS σX T : ℝ)
    (hXbar : 0 < Xbar) (hS : 0 < S) (hK : 0 < K)
    (hσS : 0 < σS) (hσX : 0 < σX) (hT : 0 < T) (Cm : ℝ) :
    (∃! ρ : ℝ, ρ ∈ Set.Icc (-1 : ℝ) 1 ∧ quantoCall Xbar S K rd rf q σS σX T ρ = Cm) ↔
      (quantoCall Xbar S K rd rf q σS σX T 1 ≤ Cm ∧
        Cm ≤ quantoCall Xbar S K rd rf q σS σX T (-1)) := by
  have hanti := quantoCall_strictAnti_aux Xbar S K rd rf q σS σX T hXbar hS hK
    hσS hσX hT
  have hcont : Continuous (fun ρ => quantoCall Xbar S K rd rf q σS σX T ρ) :=
    continuous_iff_continuousAt.2 fun ρ =>
      (quantoCall_hasDerivAt_aux Xbar S K rd rf q σS σX T hS hK hσS hT ρ).continuousAt
  constructor
  · rintro ⟨ρ, ⟨hρ, hfρ⟩, _⟩
    exact ⟨hfρ ▸ hanti.antitone hρ.2, hfρ ▸ hanti.antitone hρ.1⟩
  · rintro ⟨h1, h2⟩
    obtain ⟨ρ, hρ, hfρ⟩ := intermediate_value_Icc' (by norm_num : (-1 : ℝ) ≤ 1)
      hcont.continuousOn ⟨h1, h2⟩
    refine ⟨ρ, ⟨hρ, hfρ⟩, ?_⟩
    rintro y ⟨_, hy⟩
    exact hanti.injective (hy.trans hfρ.symm)

/-- **The quanto price falls strictly as the correlation rises.**
When the fixed rate, share price, strike, both volatilities and time to expiry are positive,
a larger correlation always gives a strictly smaller quanto call price. -/
theorem quantoCall_strictAnti_in_correlation
    (Xbar S K rd rf q σS σX T : ℝ)
    (hXbar : 0 < Xbar) (hS : 0 < S) (hK : 0 < K)
    (hσS : 0 < σS) (hσX : 0 < σX) (hT : 0 < T) :
    StrictAnti (fun ρ => quantoCall Xbar S K rd rf q σS σX T ρ) := by
  exact quantoCall_strictAnti_aux Xbar S K rd rf q σS σX T hXbar hS hK hσS hσX hT

/-- **The slope in the correlation.**
`∂C/∂ρ = -X̄ e^{-r_d T} F_Q N(d₁) σ_S σ_X T` at every correlation `ρ`. -/
theorem quantoCall_hasDerivAt_correlation
    (Xbar S K rd rf q σS σX T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσS : 0 < σS) (hT : 0 < T) (ρ : ℝ) :
    HasDerivAt (fun r => quantoCall Xbar S K rd rf q σS σX T r)
      (-(Xbar * Real.exp (-rd * T) * quantoForward S rf q σS σX T ρ *
          N (d1 S K rf q σS σX T ρ) * σS * σX * T)) ρ := by
  exact quantoCall_hasDerivAt_aux Xbar S K rd rf q σS σX T hS hK hσS hT ρ

-- Worked numbers from the card, as exact fractions.
-- Back to ρ from the forward's growth: (0.03 - 0.01 - 0.014) / (0.20 × 0.10) = 0.30.
example : ((3 : ℚ) / 100 - 1 / 100 - 14 / 1000) / ((1 / 5) * (1 / 10)) = 3 / 10 := by norm_num
-- The product pinned: ρ σ_S σ_X = 0.30 × 0.20 × 0.10 = 0.006, and ρ σ_X = 0.03.
example : (3 : ℚ) / 10 * (1 / 5) * (1 / 10) = 6 / 1000 := by norm_num
example : (3 : ℚ) / 10 * (1 / 10) = 3 / 100 := by norm_num
-- Only ρ σ_X is identified: 0.60 × 0.05 = 0.20 × 0.15 = 0.10 × 0.30 = 1.00 × 0.03 = 0.03.
example : (3 : ℚ) / 5 * (1 / 20) = 3 / 100 ∧ (1 : ℚ) / 5 * (3 / 20) = 3 / 100 ∧
    (1 : ℚ) / 10 * (3 / 10) = 3 / 100 ∧ (1 : ℚ) * (3 / 100) = 3 / 100 := by norm_num
-- At ρ = +1 the forward is exactly today's price: 0.03 - 0.01 - 1 × 0.20 × 0.10 = 0.
example : quantoForward 100 (3 / 100) (1 / 100) (1 / 5) (1 / 10) 1 1 = 100 := by
  norm_num [quantoForward]

#print axioms implied_correlation_exists_unique_iff_in_band
#print axioms quantoCall_strictAnti_in_correlation
#print axioms quantoCall_hasDerivAt_correlation

end QuantoImpliedCorrelation
