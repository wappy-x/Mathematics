-- Putting the adjustments together: when the bank's funding spread equals (1 - R) times its own hazard, DVA and the funding benefit are the same amount, and the bilateral charges are one all-in rate times one exposure annuity.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory ProbabilityTheory Real

/-! Notation, as on the card.

* `g t` is the discounted expected exposure `D(t) * E[V(t)]` at date `t`
  (independence of default and exposure is already used to write it this way).
* A default time with constant hazard `lam` has the exponential law `expMeasure lam`.
* A charge "on default" is `(1 - R) * E[g(τ); τ ≤ T]`, a charge "while alive" is
  `rate * ∫₀ᵀ g(t) e^{-lam t} dt`. -/

lemma setIntegral_expMeasure_Iic_eq (lam T : ℝ) (g : ℝ → ℝ) (hlam : 0 < lam) (hT : 0 ≤ T) :
    ∫ t in Set.Iic T, g t ∂(expMeasure lam)
      = ∫ t in (0 : ℝ)..T, g t * (lam * exp (-lam * t)) := by
  have hE : expMeasure lam = volume.withDensity (exponentialPDF lam) := rfl
  have hmeas : Measurable (exponentialPDF lam) :=
    (measurable_exponentialPDFReal lam).ennreal_ofReal
  rw [hE, restrict_withDensity measurableSet_Iic,
    integral_withDensity_eq_integral_toReal_smul hmeas
      (Filter.Eventually.of_forall fun x => ENNReal.ofReal_lt_top) g]
  have hpt : ∀ x, (exponentialPDF lam x).toReal • g x
      = Set.indicator (Set.Ici 0) (fun t => g t * (lam * exp (-lam * t))) x := by
    intro x
    by_cases hx : 0 ≤ x
    · rw [Set.indicator_of_mem (Set.mem_Ici.mpr hx), exponentialPDF_of_nonneg hx,
        smul_eq_mul, ENNReal.toReal_ofReal (by positivity)]
      ring_nf
    · rw [Set.indicator_of_notMem (by simpa using hx), exponentialPDF_of_neg (by linarith)]
      simp
  simp_rw [hpt]
  rw [setIntegral_indicator measurableSet_Ici, Set.inter_comm, Set.Ici_inter_Iic,
    integral_Icc_eq_integral_Ioc, intervalIntegral.integral_of_le hT]

#print axioms setIntegral_expMeasure_Iic_eq

/-- **DVA and the funding benefit are the same money.** Let the bank's own default
time have constant hazard `lamB > 0`, and let its unsecured funding spread be the
market price of that default, `sF = (1 - R) * lamB`. Then DVA, the expected
discounted fraction `1 - R` of what the bank owes that it fails to pay by `T`,
equals FBA, the spread `sF` saved on the amount owed for as long as the bank is
alive to borrow, discounted. -/
theorem dva_eq_funding_benefit (R lamB sF T : ℝ) (g : ℝ → ℝ)
    (hlamB : 0 < lamB) (hT : 0 ≤ T) (hsF : sF = (1 - R) * lamB) :
    (1 - R) * ∫ t in Set.Iic T, g t ∂(expMeasure lamB)
      = sF * ∫ t in (0 : ℝ)..T, g t * exp (-lamB * t) := by
  rw [setIntegral_expMeasure_Iic_eq lamB T g hlamB hT, hsF, mul_assoc]
  congr 1
  rw [← intervalIntegral.integral_const_mul]
  congr 1
  ext t
  ring

/-- **The exposure annuity in closed form.** For a bought option the discounted
expected exposure is flat, `D(t) * EE(t) = C₀` at every date, so with survival
`e^{-λ t}` the exposure annuity is `A_E = ∫₀ᵀ D(t) EE(t) e^{-λ t} dt = C₀ (1 - e^{-λ T}) / λ`. -/
theorem exposure_annuity_of_flat_exposure (C0 lam T : ℝ) (D EE : ℝ → ℝ)
    (hlam : 0 < lam) (hflat : ∀ t, D t * EE t = C0) :
    ∫ t in (0 : ℝ)..T, D t * EE t * exp (-lam * t)
      = C0 * (1 - exp (-lam * T)) / lam := by
  simp_rw [hflat]
  rw [intervalIntegral.integral_const_mul]
  rw [intervalIntegral.integral_comp_mul_left Real.exp (neg_ne_zero.mpr hlam.ne'), integral_exp,
    smul_eq_mul]
  have hl : lam ≠ 0 := hlam.ne'
  field_simp
  rw [mul_zero, neg_zero, exp_zero]
  ring

/-- **The bilateral stack is one rate times one annuity.** For the uncollateralised
bought trade (DVA = 0, MVA = 0), with counterparty hazard `lam > 0`, recovery `R`,
funding spread `sF`, hurdle rate `h` and capital `k` per dollar of exposure, take
CVA `= (1 - R) E[g(τ); τ ≤ T]`, FVA `= sF A_E`, KVA `= h k A_E` with
`A_E = ∫₀ᵀ g(t) e^{-lam t} dt`. Then the charges
`C₀ - V_adj`, where `V_adj = C₀ - CVA + DVA - FVA - MVA - KVA`, equal
`((1 - R) lam + sF + h k) A_E`. -/
theorem bilateral_charges_eq_rate_times_annuity (C0 R lam sF h k T : ℝ) (g : ℝ → ℝ)
    (hlam : 0 < lam) (hT : 0 ≤ T) :
    let AE := ∫ t in (0 : ℝ)..T, g t * exp (-lam * t)
    let CVA := (1 - R) * ∫ t in Set.Iic T, g t ∂(expMeasure lam)
    let DVA : ℝ := 0
    let FVA := sF * AE
    let MVA : ℝ := 0
    let KVA := h * k * AE
    C0 - (C0 - CVA + DVA - FVA - MVA - KVA) = ((1 - R) * lam + sF + h * k) * AE := by
  intro AE CVA DVA FVA MVA KVA
  have hC : CVA = (1 - R) * lam * AE := by
    simp only [CVA, AE]
    rw [setIntegral_expMeasure_Iic_eq lam T g hlam hT, mul_assoc]
    congr 1
    rw [← intervalIntegral.integral_const_mul]
    congr 1
    ext t
    ring
  simp only [DVA, FVA, MVA, KVA, hC]
  ring

-- The card's exact rate arithmetic (percentages written as fractions).
-- Capital per dollar: k = 8% × 100% × 1.4 = 0.112.
example : (8 / 100 : ℚ) * (100 / 100) * (14 / 10) = 112 / 1000 := by norm_num
-- All-in rate: (1 - 40%) × 2% + 1% + 10% × 0.112 = 0.012 + 0.010 + 0.0112 = 0.0332.
example : (1 - 40 / 100 : ℚ) * (2 / 100) = 12 / 1000 := by norm_num
example : (10 / 100 : ℚ) * (112 / 1000) = 112 / 10000 := by norm_num
example : (1 - 40 / 100 : ℚ) * (2 / 100) + 1 / 100 + (10 / 100) * (112 / 1000) = 332 / 10000 := by
  norm_num
-- The bank's own hazard from its spread: λ_B = s_F / (1 - R) = 1% / 60% = 1/60.
example : (1 / 100 : ℚ) / (1 - 40 / 100) = 1 / 60 := by norm_num
example : (1 - 40 / 100 : ℚ) * (1 / 60) = 1 / 100 := by norm_num

#print axioms dva_eq_funding_benefit
#print axioms exposure_annuity_of_flat_exposure
#print axioms bilateral_charges_eq_rate_times_annuity
