-- Beyond Merton: Kou's double-exponential jump transform, and the drift corrections that put the average Kou and variance gamma price on the forward.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals

open MeasureTheory ProbabilityTheory

/-- Kou's jump law: a jump in the log price is up with chance `p`, exponential with rate `η₁`,
or down with chance `1 - p`, minus an exponential with rate `η₂`. Built from Mathlib's
exponential density `exponentialPDFReal`. -/
noncomputable def kouJumpPDF (p η₁ η₂ x : ℝ) : ℝ :=
  p * exponentialPDFReal η₁ x + (1 - p) * exponentialPDFReal η₂ (-x)

lemma kou_exp_pdf_eq_indicator (η : ℝ) (z : ℂ) :
    (fun x : ℝ => Complex.exp (z * x) * (exponentialPDFReal η x : ℂ)) =
      (Set.Ici (0 : ℝ)).indicator (fun x : ℝ => (η : ℂ) * Complex.exp ((z - η) * x)) := by
  funext x
  by_cases hx : 0 ≤ x
  · simp only [Set.indicator, Set.mem_Ici, hx, ite_true, exponentialPDFReal, gammaPDFReal]
    simp only [Real.rpow_one, Real.Gamma_one, div_one, sub_self, Real.rpow_zero, mul_one]
    push_cast
    rw [mul_left_comm, ← Complex.exp_add]
    congr 2
    ring
  · simp [Set.indicator, hx, exponentialPDFReal, gammaPDFReal]

lemma kou_exp_pdf_integrable (η : ℝ) (z : ℂ) (h : z.re < η) :
    Integrable (fun x : ℝ => Complex.exp (z * x) * (exponentialPDFReal η x : ℂ)) := by
  rw [kou_exp_pdf_eq_indicator, integrable_indicator_iff measurableSet_Ici]
  refine (integrableOn_Ici_iff_integrableOn_Ioi).mpr ?_
  exact (integrableOn_exp_mul_complex_Ioi (a := z - η) (by simpa using h) 0).const_mul _

lemma kou_exp_pdf_integral (η : ℝ) (z : ℂ) (h : z.re < η) :
    ∫ x : ℝ, Complex.exp (z * x) * (exponentialPDFReal η x : ℂ) = η / (η - z) := by
  rw [kou_exp_pdf_eq_indicator, integral_indicator measurableSet_Ici,
    integral_Ici_eq_integral_Ioi, integral_const_mul,
    integral_exp_mul_complex_Ioi (a := z - η) (by simpa using h) 0]
  have hne : (η : ℂ) - z ≠ 0 := by
    intro h0
    have := congrArg Complex.re h0
    simp at this
    linarith
  have hne' : z - (η : ℂ) ≠ 0 := by
    intro h0; apply hne; rw [← neg_sub, h0, neg_zero]
  simp only [Complex.ofReal_zero, mul_zero, Complex.exp_zero]
  field_simp
  ring

lemma kou_exp_pdf_neg_integrable (η : ℝ) (z : ℂ) (h : -η < z.re) :
    Integrable (fun x : ℝ => Complex.exp (z * x) * (exponentialPDFReal η (-x) : ℂ)) := by
  have := (kou_exp_pdf_integrable η (-z) (by simp; linarith)).comp_neg
  refine this.congr (ae_of_all _ fun x => ?_)
  simp

lemma kou_exp_pdf_neg_integral (η : ℝ) (z : ℂ) (h : -η < z.re) :
    ∫ x : ℝ, Complex.exp (z * x) * (exponentialPDFReal η (-x) : ℂ) = η / (η + z) := by
  have := kou_exp_pdf_integral η (-z) (by simp; linarith)
  rw [← integral_neg_eq_self] at this
  rw [sub_neg_eq_add] at this
  rw [← this]
  congr 1
  funext x
  simp

lemma kou_jump_transform_aux (p η₁ η₂ : ℝ) (z : ℂ) (h₁ : z.re < η₁) (h₂ : -η₂ < z.re) :
    ∫ x : ℝ, Complex.exp (z * x) * (kouJumpPDF p η₁ η₂ x : ℂ)
      = p * η₁ / (η₁ - z) + (1 - p) * η₂ / (η₂ + z) := by
  have hfun : (fun x : ℝ => Complex.exp (z * x) * (kouJumpPDF p η₁ η₂ x : ℂ)) =
      fun x : ℝ => (p : ℂ) * (Complex.exp (z * x) * (exponentialPDFReal η₁ x : ℂ)) +
        ((1 - p : ℝ) : ℂ) * (Complex.exp (z * x) * (exponentialPDFReal η₂ (-x) : ℂ)) := by
    funext x
    simp only [kouJumpPDF]
    push_cast
    ring
  rw [hfun, integral_add ((kou_exp_pdf_integrable η₁ z h₁).const_mul _)
    ((kou_exp_pdf_neg_integrable η₂ z h₂).const_mul _), integral_const_mul, integral_const_mul,
    kou_exp_pdf_integral η₁ z h₁, kou_exp_pdf_neg_integral η₂ z h₂]
  push_cast
  ring

lemma gamma_mgf (a r c : ℝ) (ha : 0 < a) (hr : 0 < r) (hc : c < r) :
    ∫ g : ℝ, Real.exp (c * g) * gammaPDFReal a r g = (r / (r - c)) ^ a := by
  have hfun : (fun g : ℝ => Real.exp (c * g) * gammaPDFReal a r g) =
      (Set.Ici (0 : ℝ)).indicator
        (fun g : ℝ => r ^ a / Real.Gamma a * (g ^ (a - 1) * Real.exp (-((r - c) * g)))) := by
    funext g
    by_cases hg : 0 ≤ g
    · simp only [Set.indicator, Set.mem_Ici, hg, ite_true, gammaPDFReal]
      have : Real.exp (-((r - c) * g)) = Real.exp (c * g) * Real.exp (-(r * g)) := by
        rw [← Real.exp_add]; congr 1; ring
      rw [this]; ring
    · simp [Set.indicator, hg, gammaPDFReal]
  rw [hfun, integral_indicator measurableSet_Ici, integral_Ici_eq_integral_Ioi,
    integral_const_mul, Real.integral_rpow_mul_exp_neg_mul_Ioi ha (by linarith)]
  have hG : Real.Gamma a ≠ 0 := (Real.Gamma_pos_of_pos ha).ne'
  rw [Real.div_rpow hr.le (by linarith), one_div, Real.inv_rpow (by linarith)]
  field_simp

#print axioms kou_exp_pdf_eq_indicator
#print axioms kou_exp_pdf_integrable
#print axioms kou_exp_pdf_integral
#print axioms kou_exp_pdf_neg_integrable
#print axioms kou_exp_pdf_neg_integral
#print axioms kou_jump_transform_aux
#print axioms gamma_mgf

/-- Kou's compensator keeps the forward (Steps 1 and 2). When `η₁ > 1`, one jump's average
of `e^J` is finite, and Kou's exponent at `z = 1`, `T(μ + σ²/2 + λ(E[e^J] - 1))`, equals
`(r - q)T`, so the average future price is the forward, exactly when
`μ = r - q - σ²/2 - λζ` with `ζ = p η₁/(η₁ - 1) + (1 - p) η₂/(η₂ + 1) - 1`. -/
theorem kou_compensator_keeps_forward (r q σ lam p η₁ η₂ T μ : ℝ)
    (hη₁ : 1 < η₁) (hη₂ : 0 < η₂) (hT : 0 < T) :
    T * (μ + σ ^ 2 / 2 + lam * ((∫ x : ℝ, Real.exp x * kouJumpPDF p η₁ η₂ x) - 1)) = (r - q) * T ↔
      μ = r - q - σ ^ 2 / 2 - lam * (p * η₁ / (η₁ - 1) + (1 - p) * η₂ / (η₂ + 1) - 1) := by
  have hE : (∫ x : ℝ, Real.exp x * kouJumpPDF p η₁ η₂ x)
      = p * η₁ / (η₁ - 1) + (1 - p) * η₂ / (η₂ + 1) := by
    have hc := kou_jump_transform_aux p η₁ η₂ 1 (by simpa using hη₁) (by simp; linarith)
    apply Complex.ofReal_injective
    rw [← integral_complex_ofReal]
    simp only [one_mul] at hc
    push_cast
    rw [← hc]
  rw [hE]
  constructor
  · intro h
    have h' : T * (μ + σ ^ 2 / 2 + lam * (p * η₁ / (η₁ - 1) + (1 - p) * η₂ / (η₂ + 1) - 1))
        = T * (r - q) := by rw [h]; ring
    have := mul_left_cancel₀ hT.ne' h'
    linarith
  · intro h
    rw [h]
    ring

/-- One Kou jump's transform (Step 1): for every complex `z` with `-η₂ < Re z < η₁`,
the average of `e^(zJ)` over Kou's jump law is `p η₁/(η₁ - z) + (1 - p) η₂/(η₂ + z)`. -/
theorem kou_jump_transform (p η₁ η₂ : ℝ) (z : ℂ) (h₁ : z.re < η₁) (h₂ : -η₂ < z.re) :
    ∫ x : ℝ, Complex.exp (z * x) * (kouJumpPDF p η₁ η₂ x : ℂ)
      = p * η₁ / (η₁ - z) + (1 - p) * η₂ / (η₂ + z) := by
  exact kou_jump_transform_aux p η₁ η₂ z h₁ h₂

/-- The variance gamma correction (Steps 3 and 4). The clock `G` has Mathlib's gamma density
with shape `T/ν` and rate `1/ν` (mean `T`, variance `νT`); given the clock, the Brownian part
averages `e^(θG + σW(G))` to `e^((θ + σ²/2)G)`. When `1 - θν - σ²ν/2 > 0`, the average of
`S_T/S`, namely `e^((r - q + ω)T)` times the clock average, equals the forward factor
`e^((r - q)T)` exactly when `ω = (1/ν) ln(1 - θν - σ²ν/2)`. -/
theorem vg_correction_keeps_forward (r q ω θ σ ν T : ℝ) (hν : 0 < ν) (hT : 0 < T)
    (hVG : 0 < 1 - θ * ν - σ ^ 2 * ν / 2) :
    Real.exp ((r - q + ω) * T) *
        (∫ g : ℝ, Real.exp ((θ + σ ^ 2 / 2) * g) * gammaPDFReal (T / ν) (1 / ν) g)
      = Real.exp ((r - q) * T) ↔
      ω = 1 / ν * Real.log (1 - θ * ν - σ ^ 2 * ν / 2) := by
  set L := 1 - θ * ν - σ ^ 2 * ν / 2 with hL
  have hc : θ + σ ^ 2 / 2 < 1 / ν := by
    rw [lt_div_iff₀ hν]; nlinarith
  rw [gamma_mgf (T / ν) (1 / ν) (θ + σ ^ 2 / 2) (div_pos hT hν) (one_div_pos.mpr hν) hc]
  have hratio : 1 / ν / (1 / ν - (θ + σ ^ 2 / 2)) = 1 / L := by
    have hν0 : ν ≠ 0 := hν.ne'
    have hL0 : L ≠ 0 := hVG.ne'
    have hden : 1 / ν - (θ + σ ^ 2 / 2) = L / ν := by rw [hL]; field_simp; ring
    rw [hden]; field_simp
  rw [hratio, Real.rpow_def_of_pos (one_div_pos.mpr hVG), ← Real.exp_add,
    Real.exp_eq_exp, one_div, Real.log_inv]
  constructor
  · intro h
    have h' : (ω - 1 / ν * Real.log L) * T = 0 := by
      have : (ω - 1 / ν * Real.log L) * T = (r - q + ω) * T + -Real.log L * (T / ν) - (r - q) * T := by
        field_simp; ring
      rw [this, h]; ring
    rcases mul_eq_zero.mp h' with h0 | h0
    · linarith
    · exact absurd h0 hT.ne'
  · intro h
    rw [h]
    field_simp
    ring

/-- House compensator (Worked numbers): `0.4 × 10/9 + 0.6 × 5/6 - 1 = -1/18 = -0.055556`. -/
example : (2 / 5 : ℚ) * 10 / (10 - 1) + (3 / 5) * 5 / (5 + 1) - 1 = -1 / 18 := by norm_num

/-- House Kou drift: `0.05 - 0.02 - 0.02 + 1 × 1/18 = 59/900 = 0.065556`. -/
example : (1 / 20 : ℚ) - 1 / 50 - (1 / 5) ^ 2 / 2 - 1 * (-1 / 18) = 59 / 900 := by norm_num

/-- House inside of the variance gamma logarithm: `1 + 0.028 - 0.004 = 1.024 = 128/125`. -/
example : (1 : ℚ) - (-7 / 50) * (1 / 5) - (1 / 5) ^ 2 * (1 / 5) / 2 = 128 / 125 := by norm_num

/-- House variances (Step 5): Kou `σ² + 2λ(p/η₁² + (1 - p)/η₂²) = 0.096`,
variance gamma `σ² + θ²ν = 0.04392`. -/
example : (1 / 5 : ℚ) ^ 2 + 1 * 2 * (2 / 5 / 10 ^ 2 + 3 / 5 / 5 ^ 2) = 12 / 125 ∧
    (1 / 5 : ℚ) ^ 2 + (-7 / 50) ^ 2 * (1 / 5) = 549 / 12500 := by norm_num

#print axioms kou_compensator_keeps_forward
#print axioms kou_jump_transform
#print axioms vg_correction_keeps_forward
