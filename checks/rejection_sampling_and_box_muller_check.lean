-- Rejection sampling and Box-Muller: the draws a rejection sampler keeps follow the target law exactly and are kept with chance 1/M, two independent uniforms on (0, 1] turned into a radius and an angle give two independent standard normals, and the card's raised exponential sits above the size of a normal draw with keep chance e^(−(y−1)²/2).
import Mathlib.Probability.Distributions.Uniform
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.ConditionalProbability
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.MeasureTheory.Function.JacobianOneDim

open MeasureTheory ProbabilityTheory

/-- Rejection sampling. Let f be a target density on the real line (nonnegative, area 1) and
g a proposal density (nonnegative), with an envelope constant M such that f(y) ≤ M g(y) at
every point. Draw Y with density g and a fresh uniform U on (0, 1], independent of Y, and
keep Y when U ≤ f(Y) / (M g(Y)). Then a draw is kept with chance 1/M, and the kept draws
have exactly the target's cumulative curve: P(Y ≤ y | kept) = F(y), the area under f to
the left of y, for every y. -/
theorem rejection_sampling_kept_draws_follow_target {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P]
    (f g : ℝ → ℝ) (M : ℝ)
    (hf_nonneg : ∀ y, 0 ≤ f y) (hf_meas : Measurable f) (hf_int : Integrable f)
    (hf_one : ∫ y, f y = 1)
    (hg_nonneg : ∀ y, 0 ≤ g y) (hg_meas : Measurable g)
    (h_envelope : ∀ y, f y ≤ M * g y)
    (Y U : Ω → ℝ)
    (hY : HasLaw Y (volume.withDensity fun y => ENNReal.ofReal (g y)) P)
    (hU : pdf.IsUniform U (Set.Ioc 0 1) P)
    (h_indep : IndepFun Y U P) :
    (P {ω | U ω ≤ f (Y ω) / (M * g (Y ω))}).toReal = 1 / M ∧
      ∀ y : ℝ, (P[Y ⁻¹' Set.Iic y | {ω | U ω ≤ f (Y ω) / (M * g (Y ω))}]).toReal =
        ∫ t in Set.Iic y, f t := by
  have hM : 0 < M := by
    by_contra hM
    rw [not_lt] at hM
    have hf0 : (fun y => f y) = fun _ => (0:ℝ) := by
      funext y
      exact le_antisymm ((h_envelope y).trans (by nlinarith [hg_nonneg y])) (hf_nonneg y)
    rw [hf0] at hf_one
    simp at hf_one
  set h : ℝ → ℝ := fun y => f y / (M * g y) with hh_def
  have hh_meas : Measurable h := hf_meas.div (measurable_const.mul hg_meas)
  have hYm := hY.aemeasurable
  have hUm := hU.aemeasurable
  have hmapY : P.map Y = volume.withDensity fun y => ENNReal.ofReal (g y) := hY.map_eq
  have hmapU : P.map U = volume[|Set.Ioc (0:ℝ) 1] := hU.map_eq
  have hjoint : P.map (fun ω => (Y ω, U ω)) = (P.map Y).prod (P.map U) :=
    (indepFun_iff_map_prod_eq_prod_map_map hYm hUm).1 h_indep
  have hUIic : ∀ c, 0 ≤ c → c ≤ 1 → (P.map U) (Set.Iic c) = ENNReal.ofReal c := by
    intro c hc0 hc1
    rw [hmapU, cond_apply measurableSet_Ioc]
    have : Set.Ioc (0:ℝ) 1 ∩ Set.Iic c = Set.Ioc 0 c := by
      ext x
      simp only [Set.mem_inter_iff, Set.mem_Ioc, Set.mem_Iic]
      constructor
      · rintro ⟨⟨h1, _⟩, h3⟩; exact ⟨h1, h3⟩
      · rintro ⟨h1, h3⟩; exact ⟨⟨h1, h3.trans hc1⟩, h3⟩
    rw [this]
    simp [Real.volume_Ioc]
  have key : ∀ A : Set ℝ, MeasurableSet A →
      P (Y ⁻¹' A ∩ {ω | U ω ≤ h (Y ω)}) = ∫⁻ t in A, ENNReal.ofReal (f t / M) := by
    intro A hA
    have hW : MeasurableSet {p : ℝ × ℝ | p.1 ∈ A ∧ p.2 ≤ h p.1} :=
      (measurable_fst hA).inter (measurableSet_le measurable_snd (hh_meas.comp measurable_fst))
    have hpre : Y ⁻¹' A ∩ {ω | U ω ≤ h (Y ω)} =
        (fun ω => (Y ω, U ω)) ⁻¹' {p : ℝ × ℝ | p.1 ∈ A ∧ p.2 ≤ h p.1} := rfl
    rw [hpre, ← Measure.map_apply_of_aemeasurable (hYm.prodMk hUm) hW, hjoint,
      Measure.prod_apply hW, hmapY,
      lintegral_withDensity_eq_lintegral_mul _ (by fun_prop) (measurable_measure_prodMk_left hW),
      ← lintegral_indicator hA]
    refine lintegral_congr fun y => ?_
    simp only [Pi.mul_apply, Set.indicator]
    split_ifs with hy
    · have hpre2 : Prod.mk y ⁻¹' {p : ℝ × ℝ | p.1 ∈ A ∧ p.2 ≤ h p.1} = Set.Iic (h y) := by
        ext u; simp [hy]
      rw [hpre2]
      rcases (hg_nonneg y).lt_or_eq with hgpos | hg0
      · have h0 : 0 ≤ h y := div_nonneg (hf_nonneg y) (mul_nonneg hM.le hgpos.le)
        have h1 : h y ≤ 1 := (div_le_one (mul_pos hM hgpos)).2 (h_envelope y)
        rw [hUIic _ h0 h1, ← ENNReal.ofReal_mul hgpos.le]
        congr 1
        simp only [hh_def]
        field_simp
      · have hf0 : f y = 0 :=
          le_antisymm (by simpa [← hg0] using h_envelope y) (hf_nonneg y)
        simp [← hg0, hf0]
    · have hpre2 : Prod.mk y ⁻¹' {p : ℝ × ℝ | p.1 ∈ A ∧ p.2 ≤ h p.1} = ∅ := by
        ext u; simp [hy]
      simp [hpre2]
  have hK_univ : P {ω | U ω ≤ h (Y ω)} = ENNReal.ofReal (1 / M) := by
    have := key Set.univ MeasurableSet.univ
    rw [Set.preimage_univ, Set.univ_inter, Measure.restrict_univ] at this
    rw [this, ← ofReal_integral_eq_lintegral_ofReal]
    · congr 1
      rw [integral_div, hf_one]
    · exact hf_int.div_const M
    · exact Filter.Eventually.of_forall fun y => div_nonneg (hf_nonneg y) hM.le
  refine ⟨by rw [hK_univ, ENNReal.toReal_ofReal (by positivity)], fun y => ?_⟩
  rw [ProbabilityTheory.cond, Measure.smul_apply,
    Measure.restrict_apply₀ (hYm.restrict.nullMeasurable measurableSet_Iic),
    key _ measurableSet_Iic, hK_univ, ← ofReal_integral_eq_lintegral_ofReal]
  · rw [smul_eq_mul, ENNReal.toReal_mul, ENNReal.toReal_inv, ENNReal.toReal_ofReal (by positivity),
      ENNReal.toReal_ofReal, integral_div]
    · field_simp
    · exact integral_nonneg fun t => div_nonneg (hf_nonneg t) hM.le
  · exact (hf_int.div_const M).integrableOn
  · exact Filter.Eventually.of_forall fun t => div_nonneg (hf_nonneg t) hM.le

/-- Box-Muller. Take two independent uniforms U₁ and U₂ on (0, 1]. Set
R = √(−2 ln U₁) and Θ = 2πU₂, and return Z₁ = R cos Θ and Z₂ = R sin Θ. Then the pair
(Z₁, Z₂) has the law of two independent standard normal draws: its joint law is the
product of two copies of the standard bell curve. -/
theorem box_muller_gives_independent_standard_normals {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P]
    (U₁ U₂ : Ω → ℝ)
    (hU₁ : pdf.IsUniform U₁ (Set.Ioc 0 1) P) (hU₂ : pdf.IsUniform U₂ (Set.Ioc 0 1) P)
    (h_indep : IndepFun U₁ U₂ P) :
    HasLaw
      (fun ω => (Real.sqrt (-2 * Real.log (U₁ ω)) * Real.cos (2 * Real.pi * U₂ ω),
                 Real.sqrt (-2 * Real.log (U₁ ω)) * Real.sin (2 * Real.pi * U₂ ω)))
      ((gaussianReal 0 1).prod (gaussianReal 0 1)) P := by
  have hU₁m := hU₁.aemeasurable
  have hU₂m := hU₂.aemeasurable
  set T : ℝ × ℝ → ℝ × ℝ := fun u =>
    (Real.sqrt (-2 * Real.log u.1) * Real.cos (2 * Real.pi * u.2),
      Real.sqrt (-2 * Real.log u.1) * Real.sin (2 * Real.pi * u.2)) with hT
  have hTm : Measurable T := by fun_prop
  have hjoint : P.map (fun ω => (U₁ ω, U₂ ω)) =
      (volume.restrict (Set.Ioo (0:ℝ) 1)).prod (volume.restrict (Set.Ioo (0:ℝ) 1)) := by
    rw [(indepFun_iff_map_prod_eq_prod_map_map hU₁m hU₂m).1 h_indep, hU₁.map_eq, hU₂.map_eq,
      Measure.restrict_congr_set Ioo_ae_eq_Ioc]
    simp [ProbabilityTheory.cond, Real.volume_Ioc]
  have hcomp : (fun ω => (Real.sqrt (-2 * Real.log (U₁ ω)) * Real.cos (2 * Real.pi * U₂ ω),
                 Real.sqrt (-2 * Real.log (U₁ ω)) * Real.sin (2 * Real.pi * U₂ ω))) =
      T ∘ (fun ω => (U₁ ω, U₂ ω)) := rfl
  refine ⟨hTm.comp_aemeasurable (hU₁m.prodMk hU₂m), ?_⟩
  rw [hcomp, ← AEMeasurable.map_map_of_aemeasurable hTm.aemeasurable (hU₁m.prodMk hU₂m), hjoint,
    gaussianReal_of_var_ne_zero 0 one_ne_zero,
    prod_withDensity (measurable_gaussianPDF _ _) (measurable_gaussianPDF _ _),
    ← Measure.volume_eq_prod]
  set ψ : ℝ × ℝ → ENNReal := fun z => gaussianPDF 0 1 z.1 * gaussianPDF 0 1 z.2 with hψ
  have hψm : Measurable ψ := by
    simp only [hψ]
    exact ((measurable_gaussianPDF _ _).comp measurable_fst).mul
      ((measurable_gaussianPDF _ _).comp measurable_snd)
  -- one-dimensional changes of variables
  have himθ : (fun θ : ℝ => (θ + Real.pi) / (2 * Real.pi)) '' Set.Ioo (-Real.pi) Real.pi =
      Set.Ioo 0 1 := by
    ext u
    simp only [Set.mem_image, Set.mem_Ioo]
    constructor
    · rintro ⟨θ, ⟨h1, h2⟩, rfl⟩
      constructor
      · apply div_pos <;> linarith [Real.pi_pos]
      · rw [div_lt_one (by linarith [Real.pi_pos])]; linarith
    · rintro ⟨h1, h2⟩
      refine ⟨2 * Real.pi * u - Real.pi, ⟨by nlinarith [Real.pi_pos], by nlinarith [Real.pi_pos]⟩, ?_⟩
      field_simp
      ring
  have hθ : ∀ k : ℝ → ENNReal, ∫⁻ u in Set.Ioo 0 1, k u =
      ∫⁻ θ in Set.Ioo (-Real.pi) Real.pi,
        ENNReal.ofReal (1 / (2 * Real.pi)) * k ((θ + Real.pi) / (2 * Real.pi)) := by
    intro k
    rw [← himθ, lintegral_image_eq_lintegral_abs_deriv_mul measurableSet_Ioo
      (f' := fun _ => 1 / (2 * Real.pi))]
    · simp only [abs_of_pos (show 0 < 1 / (2 * Real.pi) by positivity)]
    · intro x _
      apply HasDerivAt.hasDerivWithinAt
      have := ((hasDerivAt_id x).add_const Real.pi).div_const (2 * Real.pi)
      simpa using this
    · intro a _ b _ hab
      have h2 : (2 * Real.pi) ≠ 0 := by positivity
      simp only at hab
      field_simp at hab
      linarith
  have himr : (fun r : ℝ => Real.exp (-r ^ 2 / 2)) '' Set.Ioi 0 = Set.Ioo 0 1 := by
    ext u
    simp only [Set.mem_image, Set.mem_Ioi, Set.mem_Ioo]
    constructor
    · rintro ⟨r, hr, rfl⟩
      refine ⟨Real.exp_pos _, ?_⟩
      rw [← Real.exp_zero]
      apply Real.exp_lt_exp.2
      have : 0 < r ^ 2 := by positivity
      linarith
    · rintro ⟨h1, h2⟩
      have hl : Real.log u < 0 := Real.log_neg h1 h2
      refine ⟨Real.sqrt (-2 * Real.log u), Real.sqrt_pos.2 (by linarith), ?_⟩
      rw [Real.sq_sqrt (by linarith)]
      rw [show -(-2 * Real.log u) / 2 = Real.log u by ring, Real.exp_log h1]
  have hr : ∀ k : ℝ → ENNReal, ∫⁻ u in Set.Ioo 0 1, k u =
      ∫⁻ r in Set.Ioi 0, ENNReal.ofReal (r * Real.exp (-r ^ 2 / 2)) * k (Real.exp (-r ^ 2 / 2)) := by
    intro k
    rw [← himr, lintegral_image_eq_lintegral_abs_deriv_mul measurableSet_Ioi
      (f' := fun r => -(r * Real.exp (-r ^ 2 / 2)))]
    · refine setLIntegral_congr_fun measurableSet_Ioi fun r hr => ?_
      simp only [Set.mem_Ioi] at hr
      rw [abs_neg, abs_of_pos (by positivity)]
    · intro x _
      apply HasDerivAt.hasDerivWithinAt
      have := (((hasDerivAt_pow 2 x).neg).div_const 2).exp
      convert this using 1
      simp
      ring
    · intro a ha b hb hab
      simp only [Set.mem_Ioi] at ha hb
      have := Real.exp_injective hab
      nlinarith
  ext S hS
  rw [Measure.map_apply hTm hS, ← lintegral_indicator_one (hTm hS), withDensity_apply _ hS,
    ← lintegral_indicator hS]
  have hneg : MeasurePreserving (fun p : ℝ × ℝ => -p) volume volume := by
    rw [Measure.volume_eq_prod]
    exact (Measure.measurePreserving_neg (volume : Measure ℝ)).prod
      (Measure.measurePreserving_neg (volume : Measure ℝ))
  have hF : Measurable ((T ⁻¹' S).indicator (1 : ℝ × ℝ → ENNReal)) :=
    measurable_one.indicator (hTm hS)
  have hG : Measurable (S.indicator ψ) := hψm.indicator hS
  have hpolm : Measurable fun q : ℝ × ℝ =>
      ENNReal.ofReal q.1 • S.indicator ψ (-(polarCoord.symm q)) :=
    (ENNReal.measurable_ofReal.comp measurable_fst).smul
      (hG.comp continuous_polarCoord_symm.measurable.neg)
  have htarget : (volume : Measure (ℝ × ℝ)).restrict polarCoord.target =
      (volume.restrict (Set.Ioi (0:ℝ))).prod (volume.restrict (Set.Ioo (-Real.pi) Real.pi)) := by
    rw [Measure.volume_eq_prod, Measure.prod_restrict]
    rfl
  rw [← hneg.lintegral_comp hG, ← lintegral_comp_polarCoord_symm,
    lintegral_prod _ hF.aemeasurable, htarget, lintegral_prod _ hpolm.aemeasurable,
    hr (fun u1 => ∫⁻ u2 in Set.Ioo 0 1, (T ⁻¹' S).indicator 1 (u1, u2))]
  refine setLIntegral_congr_fun measurableSet_Ioi fun r hr0 => ?_
  simp only [Set.mem_Ioi] at hr0
  rw [hθ, ← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
  refine setLIntegral_congr_fun measurableSet_Ioo fun θ hθ0 => ?_
  have hpt : T (Real.exp (-r ^ 2 / 2), (θ + Real.pi) / (2 * Real.pi)) =
      -(polarCoord.symm (r, θ)) := by
    have hsq : Real.sqrt (-2 * Real.log (Real.exp (-r ^ 2 / 2))) = r := by
      rw [Real.log_exp, show -2 * (-r ^ 2 / 2) = r ^ 2 by ring, Real.sqrt_sq hr0.le]
    have hang : 2 * Real.pi * ((θ + Real.pi) / (2 * Real.pi)) = θ + Real.pi := by
      field_simp
    simp only [hT, polarCoord_symm_apply, hsq, hang, Real.cos_add_pi, Real.sin_add_pi]
    ext <;> simp
  by_cases hmem : -(polarCoord.symm (r, θ)) ∈ S
  · rw [Set.indicator_of_mem (show _ ∈ T ⁻¹' S by rw [Set.mem_preimage, hpt]; exact hmem),
      Set.indicator_of_mem hmem]
    have hg0 : ∀ x, 0 ≤ gaussianPDFReal 0 1 x := fun x => gaussianPDFReal_nonneg _ _ x
    simp only [Pi.one_apply, mul_one, smul_eq_mul, hψ, gaussianPDF]
    rw [← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (hg0 _),
      ← ENNReal.ofReal_mul hr0.le]
    congr 1
    simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero, polarCoord_symm_apply,
      Prod.fst_neg, Prod.snd_neg]
    have hsq : (√(2 * Real.pi))⁻¹ * (√(2 * Real.pi))⁻¹ = 1 / (2 * Real.pi) := by
      rw [← mul_inv, Real.mul_self_sqrt (by positivity), one_div]
    have he : Real.exp (-(-(r * Real.cos θ)) ^ 2 / 2) * Real.exp (-(-(r * Real.sin θ)) ^ 2 / 2) =
        Real.exp (-r ^ 2 / 2) := by
      rw [← Real.exp_add]
      congr 1
      linear_combination (-r ^ 2 / 2) * Real.cos_sq_add_sin_sq θ
    rw [show r * ((√(2 * Real.pi))⁻¹ * Real.exp (-(-(r * Real.cos θ)) ^ 2 / 2) *
        ((√(2 * Real.pi))⁻¹ * Real.exp (-(-(r * Real.sin θ)) ^ 2 / 2))) =
        r * ((√(2 * Real.pi))⁻¹ * (√(2 * Real.pi))⁻¹) *
          (Real.exp (-(-(r * Real.cos θ)) ^ 2 / 2) * Real.exp (-(-(r * Real.sin θ)) ^ 2 / 2))
        by ring, hsq, he]
    ring
  · rw [Set.indicator_of_notMem (show _ ∉ T ⁻¹' S by rw [Set.mem_preimage, hpt]; exact hmem),
      Set.indicator_of_notMem hmem]
    simp

/-- The card's envelope. For the size of a normal draw, f(y) = √(2/π) e^(−y²/2), against the
exponential proposal g(y) = e^(−y), the constant M = √(2e/π) works at every point:
f(y) ≤ M g(y), and the keep chance is f(y) / (M g(y)) = e^(−(y−1)²/2). It is also the smallest
constant that works: any M' with f(y) ≤ M' g(y) for every y ≥ 0 is at least √(2e/π). -/
theorem half_normal_exponential_envelope :
    (∀ y : ℝ, Real.sqrt (2 / Real.pi) * Real.exp (-y ^ 2 / 2) ≤
        Real.sqrt (2 * Real.exp 1 / Real.pi) * Real.exp (-y)) ∧
      (∀ y : ℝ, Real.sqrt (2 / Real.pi) * Real.exp (-y ^ 2 / 2) /
          (Real.sqrt (2 * Real.exp 1 / Real.pi) * Real.exp (-y)) =
        Real.exp (-(y - 1) ^ 2 / 2)) ∧
      ∀ M' : ℝ, (∀ y : ℝ, 0 ≤ y →
          Real.sqrt (2 / Real.pi) * Real.exp (-y ^ 2 / 2) ≤ M' * Real.exp (-y)) →
        Real.sqrt (2 * Real.exp 1 / Real.pi) ≤ M' := by
  have hs : Real.sqrt (2 * Real.exp 1 / Real.pi) = Real.sqrt (2 / Real.pi) * Real.exp (1/2) := by
    rw [show 2 * Real.exp 1 / Real.pi = (2 / Real.pi) * Real.exp (1/2) ^ 2 by
      rw [← Real.exp_nat_mul]; norm_num; ring]
    rw [Real.sqrt_mul (by positivity), Real.sqrt_sq (Real.exp_pos _).le]
  have hc : 0 < Real.sqrt (2 / Real.pi) := Real.sqrt_pos.2 (by positivity)
  rw [hs]
  refine ⟨fun y => ?_, fun y => ?_, fun M' hM' => ?_⟩
  · rw [mul_assoc]
    apply mul_le_mul_of_nonneg_left _ hc.le
    rw [← Real.exp_add]
    apply Real.exp_le_exp.2
    nlinarith [sq_nonneg (y - 1)]
  · rw [div_eq_iff (by positivity)]
    rw [show Real.exp (-(y - 1) ^ 2 / 2) * (Real.sqrt (2 / Real.pi) * Real.exp (1 / 2) * Real.exp (-y))
        = Real.sqrt (2 / Real.pi) * (Real.exp (-(y - 1) ^ 2 / 2) * Real.exp (1 / 2) * Real.exp (-y))
        by ring, ← Real.exp_add, ← Real.exp_add]
    congr 2
    ring
  · have h1 := hM' 1 zero_le_one
    have h2 : Real.sqrt (2 / Real.pi) * Real.exp (1 / 2) =
        Real.sqrt (2 / Real.pi) * Real.exp (-1 ^ 2 / 2) / Real.exp (-1) := by
      rw [mul_div_assoc, ← Real.exp_sub]
      norm_num
    rw [h2]
    exact (div_le_iff₀ (Real.exp_pos _)).2 h1

#print axioms rejection_sampling_kept_draws_follow_target
#print axioms box_muller_gives_independent_standard_normals
#print axioms half_normal_exponential_envelope
