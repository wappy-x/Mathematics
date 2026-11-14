-- Tail dependence: the Gaussian copula's chance of "both in the tail, given one" falls to zero as the tail deepens for every correlation below one, while the Student-t copula's settles at the positive number 2 t_{ν+1}(-√((ν+1)(1-ρ)/(1+ρ))), which itself falls to zero as the degrees of freedom grow.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Gamma
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.Gamma
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Gamma.BohrMollerup
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Distributions.Gaussian.HasGaussianLaw.Independence

open Real MeasureTheory ProbabilityTheory Set Filter Topology

/-- The Student-t density with `n` degrees of freedom:
`f_n(x) = Γ((n+1)/2) / (√(nπ) Γ(n/2)) · (1 + x²/n)^(-(n+1)/2)`. -/
noncomputable def studentTDensity (n : ℕ) (x : ℝ) : ℝ :=
  Real.Gamma (((n : ℝ) + 1) / 2) / (√((n : ℝ) * π) * Real.Gamma ((n : ℝ) / 2)) *
    (1 + x ^ 2 / n) ^ (-(((n : ℝ) + 1) / 2))

/-- The card's `t_n(x)`: the t-curve area to the left of `x`, with `n` degrees of freedom. -/
noncomputable def studentTCDF (n : ℕ) (x : ℝ) : ℝ :=
  ∫ y in Iic x, studentTDensity n y

/-- The card's closed form for the t copula's tail dependence:
`λ_t = 2 t_{ν+1}(-√((ν+1)(1-ρ)/(1+ρ)))`. -/
noncomputable def tTailDependence (ν : ℕ) (ρ : ℝ) : ℝ :=
  2 * studentTCDF (ν + 1) (-√(((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ)))

lemma tdc_const_le (n : ℕ) (hn : 1 ≤ n) :
    Real.Gamma (((n : ℝ) + 1) / 2) / (√((n : ℝ) * π) * Real.Gamma ((n : ℝ) / 2)) ≤
      1 / √(2 * π) := by
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hs : (0 : ℝ) < n / 2 := by positivity
  have hG := Real.Gamma_pos_of_pos hs
  have hlc := Real.Gamma_mul_add_mul_le_rpow_Gamma_mul_rpow_Gamma hs (by linarith : (0:ℝ) < n / 2 + 1)
    (by norm_num : (0:ℝ) < 1/2) (by norm_num : (0:ℝ) < 1/2) (by norm_num)
  rw [Real.Gamma_add_one hs.ne', Real.mul_rpow hs.le hG.le, mul_comm ((n/2 : ℝ) ^ (1/2 : ℝ)),
    ← mul_assoc, ← Real.rpow_add hG, show (1/2 : ℝ) + 1/2 = 1 by norm_num, Real.rpow_one] at hlc
  have e1 : (1/2 : ℝ) * (n/2) + 1/2 * (n/2 + 1) = ((n:ℝ) + 1) / 2 := by ring
  rw [e1] at hlc
  have hsq : (n/2 : ℝ) ^ (1/2 : ℝ) = √(n/2) := by rw [Real.sqrt_eq_rpow]
  rw [hsq] at hlc
  have hpos : 0 < √((n : ℝ) * π) * Real.Gamma ((n : ℝ) / 2) := by positivity
  rw [div_le_iff₀ hpos]
  calc Real.Gamma (((n : ℝ) + 1) / 2) ≤ Real.Gamma (n/2) * √(n/2) := by linarith
    _ = 1 / √(2 * π) * (√((n : ℝ) * π) * Real.Gamma ((n : ℝ) / 2)) := by
      have h2 : √((n:ℝ) * π) = √(n/2) * √(2 * π) := by
        rw [← Real.sqrt_mul (by positivity)]; congr 1; ring
      rw [h2]
      have : 0 < √(2 * π) := by positivity
      field_simp

#print axioms tdc_const_le

lemma tdc_pow_le (n : ℕ) (hn : 1 ≤ n) (y : ℝ) :
    (1 + y ^ 2 / n) ^ (-(((n : ℝ) + 1) / 2)) ≤ 2 * (1 + y ^ 2)⁻¹ := by
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hb := one_add_mul_self_le_rpow_one_add (s := y ^ 2 / n) (by
    have : 0 ≤ y ^ 2 / n := by positivity
    linarith) (p := ((n : ℝ) + 1) / 2) (by linarith)
  have h1 : (1 + y ^ 2) / 2 ≤ 1 + ((n : ℝ) + 1) / 2 * (y ^ 2 / n) := by
    have : ((n : ℝ) + 1) / 2 * (y ^ 2 / n) = y ^ 2 / 2 + y ^ 2 / (2 * n) := by
      field_simp
    rw [this]
    have : 0 ≤ y ^ 2 / (2 * n) := by positivity
    nlinarith [sq_nonneg y]
  rw [Real.rpow_neg (by positivity)]
  have hpos : 0 < (1 + y ^ 2) / 2 := by positivity
  calc ((1 + y ^ 2 / ↑n) ^ (((n : ℝ) + 1) / 2))⁻¹ ≤ ((1 + y ^ 2) / 2)⁻¹ :=
        inv_anti₀ hpos (h1.trans hb)
    _ = 2 * (1 + y ^ 2)⁻¹ := by field_simp

#print axioms tdc_pow_le

lemma tdc_density_nonneg (n : ℕ) (y : ℝ) : 0 ≤ studentTDensity n y := by
  unfold studentTDensity
  have : 0 ≤ 1 + y ^ 2 / n := by positivity
  apply mul_nonneg
  · apply div_nonneg
    · exact Real.Gamma_nonneg_of_nonneg (by positivity)
    · exact mul_nonneg (Real.sqrt_nonneg _) (Real.Gamma_nonneg_of_nonneg (by positivity))
  · exact Real.rpow_nonneg this _

#print axioms tdc_density_nonneg

lemma tdc_density_pos (n : ℕ) (hn : 1 ≤ n) (y : ℝ) : 0 < studentTDensity n y := by
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  unfold studentTDensity
  have : 0 < 1 + y ^ 2 / n := by positivity
  apply mul_pos
  · apply div_pos
    · exact Real.Gamma_pos_of_pos (by positivity)
    · exact mul_pos (Real.sqrt_pos.2 (by positivity)) (Real.Gamma_pos_of_pos (by positivity))
  · exact Real.rpow_pos_of_pos this _

#print axioms tdc_density_pos

lemma tdc_density_le (n : ℕ) (hn : 1 ≤ n) (y : ℝ) : studentTDensity n y ≤ (1 + y ^ 2)⁻¹ := by
  unfold studentTDensity
  have h1 := tdc_const_le n hn
  have h2 := tdc_pow_le n hn y
  have h0 : 0 ≤ (1 + y ^ 2 / n) ^ (-(((n : ℝ) + 1) / 2)) := Real.rpow_nonneg (by positivity) _
  have h3 : 1 / √(2 * π) * 2 ≤ 1 := by
    have hs : 2 ≤ √(2 * π) := by
      rw [Real.le_sqrt (by norm_num) (by positivity)]; nlinarith [Real.two_le_pi]
    have : 0 < √(2 * π) := by positivity
    rw [div_mul_eq_mul_div, one_mul, div_le_one this]; exact hs
  have hi : 0 < (1 + y ^ 2)⁻¹ := by positivity
  calc _ ≤ 1 / √(2 * π) * (2 * (1 + y ^ 2)⁻¹) := by
        apply mul_le_mul h1 h2 h0 (by positivity)
    _ = (1 / √(2 * π) * 2) * (1 + y ^ 2)⁻¹ := by ring
    _ ≤ 1 * (1 + y ^ 2)⁻¹ := by gcongr
    _ = _ := one_mul _

#print axioms tdc_density_le

lemma tdc_continuous (n : ℕ) (hn : 1 ≤ n) : Continuous (studentTDensity n) := by
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  unfold studentTDensity
  apply Continuous.mul continuous_const
  apply Continuous.rpow_const (by fun_prop)
  intro x; left; positivity

#print axioms tdc_continuous

lemma tdc_integrable (n : ℕ) (hn : 1 ≤ n) : Integrable (studentTDensity n) := by
  refine integrable_inv_one_add_sq.mono' (tdc_continuous n hn).aestronglyMeasurable ?_
  refine Filter.Eventually.of_forall fun y => ?_
  rw [Real.norm_of_nonneg (tdc_density_nonneg n y)]
  exact tdc_density_le n hn y

#print axioms tdc_integrable

lemma tdc_cdf_le (n : ℕ) (hn : 1 ≤ n) (x : ℝ) : studentTCDF n x ≤ arctan x + π / 2 := by
  unfold studentTCDF
  rw [← integral_Iic_inv_one_add_sq]
  apply setIntegral_mono (tdc_integrable n hn).integrableOn integrable_inv_one_add_sq.integrableOn
  exact tdc_density_le n hn

#print axioms tdc_cdf_le

lemma tdc_cdf_nonneg (n : ℕ) (x : ℝ) : 0 ≤ studentTCDF n x :=
  setIntegral_nonneg measurableSet_Iic fun y _ => tdc_density_nonneg n y

#print axioms tdc_cdf_nonneg

lemma tdc_cdf_pos (n : ℕ) (hn : 1 ≤ n) (x : ℝ) : 0 < studentTCDF n x := by
  unfold studentTCDF
  rw [setIntegral_pos_iff_support_of_nonneg_ae
    (Filter.Eventually.of_forall fun y => tdc_density_nonneg n y) (tdc_integrable n hn).integrableOn]
  have : Function.support (studentTDensity n) = univ := by
    ext y; simp [(tdc_density_pos n hn y).ne']
  rw [this, univ_inter, Real.volume_Iic]; exact ENNReal.zero_lt_top

#print axioms tdc_cdf_pos

lemma tdc_Phi_le_exp (x : ℝ) (hx : x ≤ 0) :
    (gaussianReal 0 1).real (Iic x) ≤ exp (-(x ^ 2 / 2)) := by
  have h := measure_le_le_exp_mul_mgf (μ := gaussianReal 0 1) (X := id) (t := x) x hx
    (integrable_exp_mul_gaussianReal x)
  rw [mgf_id_gaussianReal] at h
  simp only [id] at h
  rw [show {ω : ℝ | ω ≤ x} = Iic x from rfl, ← Real.exp_add] at h
  convert h using 2
  push_cast; ring

#print axioms tdc_Phi_le_exp

lemma tdc_Phi_ge (a : ℝ) (ha : a ≤ 0) :
    (√(2 * π))⁻¹ * exp (-((a - 1) ^ 2 / 2)) ≤ (gaussianReal 0 1).real (Iic a) := by
  have h1 : (gaussianReal 0 1).real (Icc (a - 1) a) ≤ (gaussianReal 0 1).real (Iic a) :=
    measureReal_mono Icc_subset_Iic_self
  refine le_trans ?_ h1
  rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Icc
      (fun x _ => gaussianPDFReal_nonneg _ _ x))]
  have hc : ∫ x in Icc (a - 1) a, (√(2 * π))⁻¹ * exp (-((a - 1) ^ 2 / 2)) =
      (√(2 * π))⁻¹ * exp (-((a - 1) ^ 2 / 2)) := by
    rw [setIntegral_const]; simp
  rw [← hc]
  apply setIntegral_mono_on (continuous_const.integrableOn_Icc) (integrable_gaussianPDFReal _ _).integrableOn measurableSet_Icc
  intro x hx
  rw [gaussianPDFReal_def]
  simp only [NNReal.coe_one, mul_one, sub_zero]
  gcongr
  nlinarith [hx.1, hx.2]

#print axioms tdc_Phi_ge

lemma tdc_Phi_pos (a : ℝ) (ha : a ≤ 0) : 0 < (gaussianReal 0 1).real (Iic a) :=
  lt_of_lt_of_le (by positivity) (tdc_Phi_ge a ha)

#print axioms tdc_Phi_pos

lemma tdc_Phi_tendsto : Tendsto (fun a => (gaussianReal 0 1).real (Iic a)) atBot (𝓝 0) := by
  have := tendsto_cdf_atBot (μ := gaussianReal 0 1)
  refine this.congr fun a => ?_
  rw [cdf_eq_real]

#print axioms tdc_Phi_tendsto

lemma tdc_Phi_ratio (c : ℝ) (hc : 1 < c) :
    Tendsto (fun a => (gaussianReal 0 1).real (Iic (c * a)) / (gaussianReal 0 1).real (Iic a))
      atBot (𝓝 0) := by
  -- upper bound by √(2π) exp(-(c²-1)a²/2 - a + 1/2)
  have key : Tendsto (fun a : ℝ => √(2 * π) * exp (-(c ^ 2 * a ^ 2 / 2) + (a - 1) ^ 2 / 2))
      atBot (𝓝 0) := by
    have he : Tendsto (fun a : ℝ => -(c ^ 2 * a ^ 2 / 2) + (a - 1) ^ 2 / 2) atBot atBot := by
      have h1 : Tendsto (fun a : ℝ => -a) atBot atTop := tendsto_neg_atBot_atTop
      have h2 : Tendsto (fun a : ℝ => (c ^ 2 - 1) / 2 * (-a) + -1) atBot atTop := by
        apply tendsto_atTop_add_const_right
        exact Tendsto.const_mul_atTop (by nlinarith) h1
      have h3 := h1.atTop_mul_atTop₀ h2
      have h4 := (tendsto_neg_atTop_atBot.comp h3)
      refine (tendsto_atBot_add_const_right _ (1/2) h4).congr fun a => ?_
      simp only [Function.comp]; ring
    have := (Real.tendsto_exp_atBot.comp he).const_mul (√(2 * π))
    simpa using this
  apply tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds key
  · filter_upwards with a
    exact div_nonneg measureReal_nonneg measureReal_nonneg
  · filter_upwards [eventually_le_atBot (0 : ℝ)] with a ha
    have hca : c * a ≤ 0 := mul_nonpos_of_nonneg_of_nonpos (by linarith) ha
    have hP := tdc_Phi_pos a ha
    rw [div_le_iff₀ hP]
    calc (gaussianReal 0 1).real (Iic (c * a)) ≤ exp (-((c * a) ^ 2 / 2)) := tdc_Phi_le_exp _ hca
      _ = √(2 * π) * exp (-(c ^ 2 * a ^ 2 / 2) + (a - 1) ^ 2 / 2) *
            ((√(2 * π))⁻¹ * exp (-((a - 1) ^ 2 / 2))) := by
          have : 0 < √(2 * π) := by positivity
          rw [show √(2 * π) * exp (-(c ^ 2 * a ^ 2 / 2) + (a - 1) ^ 2 / 2) *
            ((√(2 * π))⁻¹ * exp (-((a - 1) ^ 2 / 2))) =
            (√(2 * π) * (√(2 * π))⁻¹) * (exp (-(c ^ 2 * a ^ 2 / 2) + (a - 1) ^ 2 / 2) *
              exp (-((a - 1) ^ 2 / 2))) by ring, ← Real.exp_add, mul_inv_cancel₀ this.ne']
          ring_nf
      _ ≤ _ := by gcongr; exact tdc_Phi_ge a ha

#print axioms tdc_Phi_ratio

lemma tdc_pair_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X Y : Ω → ℝ}
    (hX : HasLaw X (gaussianReal 0 1) P) (hY : HasLaw Y (gaussianReal 0 1) P)
    (hind : IndepFun X Y P) :
    HasLaw (fun ω => (X ω, Y ω)) ((gaussianReal 0 1).prod (gaussianReal 0 1)) P := by
  have := hX.isProbabilityMeasure
  refine ⟨hX.aemeasurable.prodMk hY.aemeasurable, ?_⟩
  rw [(indepFun_iff_map_prod_eq_prod_map_map hX.aemeasurable hY.aemeasurable).1 hind,
    hX.map_eq, hY.map_eq]

#print axioms tdc_pair_law

lemma tdc_lin_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X Y : Ω → ℝ}
    (hX : HasLaw X (gaussianReal 0 1) P) (hY : HasLaw Y (gaussianReal 0 1) P)
    (hind : IndepFun X Y P) (α β : ℝ) (hαβ : α ^ 2 + β ^ 2 = 1) :
    HasLaw (fun ω => α * X ω + β * Y ω) (gaussianReal 0 1) P := by
  have hα := gaussianReal_const_mul hX α
  have hβ := gaussianReal_const_mul hY β
  have hi : IndepFun (fun ω => α * X ω) (fun ω => β * Y ω) P :=
    hind.comp (measurable_const_mul α) (measurable_const_mul β)
  have h := gaussianReal_add_gaussianReal_of_indepFun hi hα hβ
  refine ⟨by fun_prop, ?_⟩
  have e : (fun ω => α * X ω + β * Y ω) = (fun ω => α * X ω) + (fun ω => β * Y ω) := rfl
  rw [e, h]
  congr 1
  · simp
  · ext; simp [hαβ]

#print axioms tdc_lin_law

lemma tdc_rot_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X Y : Ω → ℝ}
    (hX : HasLaw X (gaussianReal 0 1) P) (hY : HasLaw Y (gaussianReal 0 1) P)
    (hind : IndepFun X Y P) (ρ s : ℝ) (hρs : ρ ^ 2 + s ^ 2 = 1) :
    HasLaw (fun ω => (ρ * X ω + s * Y ω, s * X ω + -ρ * Y ω))
      ((gaussianReal 0 1).prod (gaussianReal 0 1)) P := by
  have := hX.isProbabilityMeasure
  have hA := tdc_lin_law hX hY hind ρ s hρs
  have hB := tdc_lin_law hX hY hind s (-ρ) (by nlinarith)
  have hXg : HasGaussianLaw X P := hX.hasGaussianLaw
  have hYg : HasGaussianLaw Y P := hY.hasGaussianLaw
  have hXY : HasGaussianLaw (fun ω => (X ω, Y ω)) P := IndepFun.hasGaussianLaw hXg hYg hind
  let L : ℝ × ℝ →L[ℝ] ℝ × ℝ :=
    (ρ • ContinuousLinearMap.fst ℝ ℝ ℝ + s • ContinuousLinearMap.snd ℝ ℝ ℝ).prod
      (s • ContinuousLinearMap.fst ℝ ℝ ℝ + (-ρ) • ContinuousLinearMap.snd ℝ ℝ ℝ)
  have hAB : HasGaussianLaw (fun ω => (ρ * X ω + s * Y ω, s * X ω + -ρ * Y ω)) P := by
    have := hXY.map_fun L
    convert this using 1
    ext ω <;> simp [L]
  have hX2 : MemLp X 2 P := hXg.memLp_two
  have hY2 : MemLp Y 2 P := hYg.memLp_two
  have hvX : Var[X; P] = 1 := by rw [hX.variance_eq, variance_id_gaussianReal]; rfl
  have hvY : Var[Y; P] = 1 := by rw [hY.variance_eq, variance_id_gaussianReal]; rfl
  have hcXY : cov[X, Y; P] = 0 := hind.covariance_eq_zero hX2 hY2
  have hcov : cov[fun ω => ρ * X ω + s * Y ω, fun ω => s * X ω + -ρ * Y ω; P] = 0 := by
    have e1 : (fun ω => ρ * X ω + s * Y ω) = (fun ω => ρ * X ω) + (fun ω => s * Y ω) := rfl
    have e2 : (fun ω => s * X ω + -ρ * Y ω) = (fun ω => s * X ω) + (fun ω => -ρ * Y ω) := rfl
    rw [e1, e2, covariance_add_left (hX2.const_mul _) (hY2.const_mul _)
      ((hX2.const_mul _).add (hY2.const_mul _)),
      covariance_add_right (hX2.const_mul _) (hX2.const_mul _) (hY2.const_mul _),
      covariance_add_right (hY2.const_mul _) (hX2.const_mul _) (hY2.const_mul _)]
    simp only [covariance_const_mul_left, covariance_const_mul_right]
    rw [covariance_self hX.aemeasurable, covariance_self hY.aemeasurable, hvX, hvY, hcXY,
      covariance_comm, hcXY]
    ring
  have hind' := hAB.indepFun_of_covariance_eq_zero hcov
  refine ⟨hA.aemeasurable.prodMk hB.aemeasurable, ?_⟩
  rw [(indepFun_iff_map_prod_eq_prod_map_map hA.aemeasurable hB.aemeasurable).1 hind',
    hA.map_eq, hB.map_eq]

#print axioms tdc_rot_law

lemma tdc_rpow_Ioc (a t : ℝ) (ha : 0 < a) (ht : 0 ≤ t) :
    ∫ x in Ioc 0 t, x ^ (a - 1) = t ^ a / a := by
  rw [← intervalIntegral.integral_of_le ht, integral_rpow (Or.inl (by linarith))]
  simp [Real.zero_rpow ha.ne']

#print axioms tdc_rpow_Ioc

lemma tdc_rpow_integrableOn (a t : ℝ) (ha : 0 < a) (ht : 0 ≤ t) :
    IntegrableOn (fun x : ℝ => x ^ (a - 1)) (Ioc 0 t) :=
  (intervalIntegrable_iff_integrableOn_Ioc_of_le ht).1 (intervalIntegral.intervalIntegrable_rpow' (by linarith))

#print axioms tdc_rpow_integrableOn

lemma tdc_gamma_bounds (a r t : ℝ) (ha : 0 < a) (hr : 0 < r) (ht : 0 ≤ t) :
    r ^ a / Gamma a * exp (-(r * t)) * (t ^ a / a) ≤ (gammaMeasure a r).real (Ioc 0 t) ∧
    (gammaMeasure a r).real (Ioc 0 t) ≤ r ^ a / Gamma a * (t ^ a / a) := by
  have hC : 0 < r ^ a / Gamma a := div_pos (Real.rpow_pos_of_pos hr a) (Real.Gamma_pos_of_pos ha)
  set C := r ^ a / Gamma a
  have hmeas : (gammaMeasure a r) (Ioc 0 t) = ∫⁻ x in Ioc 0 t, gammaPDF a r x := by
    rw [gammaMeasure, withDensity_apply _ measurableSet_Ioc]
  have hpdf : ∀ x ∈ Ioc 0 t, gammaPDF a r x = ENNReal.ofReal (C * x ^ (a - 1) * exp (-(r * x))) :=
    fun x hx => gammaPDF_of_nonneg hx.1.le
  have hint := tdc_rpow_integrableOn a t ha ht
  have hup : (gammaMeasure a r) (Ioc 0 t) ≤ ENNReal.ofReal (C * (t ^ a / a)) := by
    rw [hmeas, ← tdc_rpow_Ioc a t ha ht, ← integral_const_mul,
      ofReal_integral_eq_lintegral_ofReal (hint.const_mul C)]
    · apply setLIntegral_mono' measurableSet_Ioc
      intro x hx
      rw [hpdf x hx]
      apply ENNReal.ofReal_le_ofReal
      have : exp (-(r * x)) ≤ 1 := by
        rw [Real.exp_le_one_iff]; nlinarith [hx.1]
      have : 0 ≤ C * x ^ (a - 1) := mul_nonneg hC.le (Real.rpow_nonneg hx.1.le _)
      nlinarith
    · refine (ae_restrict_iff' measurableSet_Ioc).2 (Eventually.of_forall fun x hx => ?_)
      exact mul_nonneg hC.le (Real.rpow_nonneg hx.1.le _)
  have hlow : ENNReal.ofReal (C * exp (-(r * t)) * (t ^ a / a)) ≤ (gammaMeasure a r) (Ioc 0 t) := by
    rw [hmeas, ← tdc_rpow_Ioc a t ha ht, ← integral_const_mul,
      ofReal_integral_eq_lintegral_ofReal (hint.const_mul _)]
    · apply setLIntegral_mono' measurableSet_Ioc
      intro x hx
      rw [hpdf x hx]
      apply ENNReal.ofReal_le_ofReal
      have : exp (-(r * t)) ≤ exp (-(r * x)) := by
        rw [Real.exp_le_exp]; nlinarith [hx.2]
      have : 0 ≤ C * x ^ (a - 1) := mul_nonneg hC.le (Real.rpow_nonneg hx.1.le _)
      nlinarith
    · refine (ae_restrict_iff' measurableSet_Ioc).2 (Eventually.of_forall fun x hx => ?_)
      exact mul_nonneg (mul_nonneg hC.le (Real.exp_pos _).le) (Real.rpow_nonneg hx.1.le _)
  have hfin : (gammaMeasure a r) (Ioc 0 t) ≠ ⊤ := ne_top_of_le_ne_top ENNReal.ofReal_ne_top hup
  constructor
  · rw [measureReal_def]
    rw [← ENNReal.ofReal_le_iff_le_toReal hfin]; exact hlow
  · rw [measureReal_def]
    exact ENNReal.toReal_le_of_le_ofReal (by positivity) hup

#print axioms tdc_gamma_bounds

lemma tdc_sq_rpow (x b : ℝ) : (x ^ 2) ^ (b / 2) = |x| ^ b := by
  rw [← sq_abs, ← Real.rpow_natCast, ← Real.rpow_mul (abs_nonneg x)]
  congr 1; push_cast; ring

#print axioms tdc_sq_rpow

lemma tdc_moment_integrable (ν : ℕ) :
    Integrable (fun x : ℝ => (x ^ 2) ^ ((ν : ℝ) / 2)) (gaussianReal 0 1) := by
  rcases Nat.eq_zero_or_pos ν with h | h
  · subst h; simp
  have hm := (memLp_id_gaussianReal (μ := 0) (v := 1) (ν : NNReal)).integrable_norm_rpow
    (by simp; omega) (by simp)
  refine hm.congr (Eventually.of_forall fun x => ?_)
  simp [tdc_sq_rpow]

#print axioms tdc_moment_integrable

lemma tdc_scaled_limit (ν : ℕ) (hν : 1 ≤ ν) (g : ℝ → ℝ) (hg : Measurable g)
    (hg0 : ∀ x, 0 ≤ g x) (hg1 : ∀ x, g x ≤ 1) :
    Tendsto (fun q : ℝ => ∫ x, (q ^ 2) ^ ((ν : ℝ) / 2) * (Iic 0).indicator
        (fun x => g x * (gammaMeasure ((ν : ℝ) / 2) (1 / 2)).real (Ioc 0 (ν * x ^ 2 / q ^ 2))) x
        ∂(gaussianReal 0 1))
      atBot (𝓝 (∫ x, (Iic 0).indicator (fun x => (1 / 2 : ℝ) ^ ((ν : ℝ) / 2) /
        Gamma ((ν : ℝ) / 2) / ((ν : ℝ) / 2) * (ν : ℝ) ^ ((ν : ℝ) / 2) *
          (g x * (x ^ 2) ^ ((ν : ℝ) / 2))) x ∂(gaussianReal 0 1))) := by
  set a : ℝ := (ν : ℝ) / 2 with ha_def
  have hνr : (1 : ℝ) ≤ ν := by exact_mod_cast hν
  have ha : 0 < a := by rw [ha_def]; positivity
  set μV := gammaMeasure a (1 / 2)
  have : IsProbabilityMeasure μV := isProbabilityMeasure_gammaMeasure ha (by norm_num)
  set C : ℝ := (1 / 2 : ℝ) ^ a / Gamma a with hC_def
  have hC : 0 < C := div_pos (Real.rpow_pos_of_pos (by norm_num) a) (Real.Gamma_pos_of_pos ha)
  set K : ℝ := C / a * (ν : ℝ) ^ a with hK_def
  have hK : 0 < K := by positivity
  have hHmono : Monotone (fun t : ℝ => μV.real (Ioc 0 t)) := fun t t' h =>
    measureReal_mono (Ioc_subset_Ioc_right h)
  have hHm : Measurable (fun t : ℝ => μV.real (Ioc 0 t)) := hHmono.measurable
  -- key identity: (q²)^a * t^a = ν^a (x²)^a
  have hscale : ∀ q x : ℝ, q ≠ 0 → (q ^ 2) ^ a * (ν * x ^ 2 / q ^ 2) ^ a = (ν : ℝ) ^ a * (x ^ 2) ^ a := by
    intro q x hq
    have hq2 : 0 < q ^ 2 := by positivity
    rw [← Real.mul_rpow hq2.le (by positivity), ← Real.mul_rpow (by positivity) (by positivity)]
    congr 1; field_simp
  -- bounds on (q²)^a * H(t)
  have hbounds : ∀ q x : ℝ, q ≠ 0 →
      K * (x ^ 2) ^ a * exp (-(1 / 2 * (ν * x ^ 2 / q ^ 2))) ≤
        (q ^ 2) ^ a * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2)) ∧
      (q ^ 2) ^ a * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2)) ≤ K * (x ^ 2) ^ a := by
    intro q x hq
    have ht : 0 ≤ (ν : ℝ) * x ^ 2 / q ^ 2 := by positivity
    obtain ⟨h1, h2⟩ := tdc_gamma_bounds a (1 / 2) _ ha (by norm_num) ht
    have hq2a : 0 < (q ^ 2) ^ a := Real.rpow_pos_of_pos (by positivity) a
    have hs := hscale q x hq
    constructor
    · have := mul_le_mul_of_nonneg_left h1 hq2a.le
      calc K * (x ^ 2) ^ a * exp (-(1 / 2 * (ν * x ^ 2 / q ^ 2)))
          = C * exp (-(1 / 2 * (ν * x ^ 2 / q ^ 2))) / a *
              ((q ^ 2) ^ a * (ν * x ^ 2 / q ^ 2) ^ a) := by
            rw [hs, hK_def]; ring
        _ = (q ^ 2) ^ a * (C * exp (-(1 / 2 * (ν * x ^ 2 / q ^ 2))) *
              ((ν * x ^ 2 / q ^ 2) ^ a / a)) := by ring
        _ ≤ _ := this
    · have := mul_le_mul_of_nonneg_left h2 hq2a.le
      calc (q ^ 2) ^ a * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2)) ≤ _ := this
        _ = C / a * ((q ^ 2) ^ a * (ν * x ^ 2 / q ^ 2) ^ a) := by ring
        _ = K * (x ^ 2) ^ a := by rw [hs, hK_def]; ring
  have hmom := tdc_moment_integrable ν
  apply tendsto_integral_filter_of_dominated_convergence (fun x => K * (x ^ 2) ^ a)
  · refine Eventually.of_forall fun q => ?_
    apply Measurable.aestronglyMeasurable
    apply Measurable.const_mul
    apply Measurable.indicator _ measurableSet_Iic
    apply hg.mul
    exact hHm.comp (by fun_prop)
  · filter_upwards [eventually_lt_atBot (0 : ℝ)] with q hq
    refine Eventually.of_forall fun x => ?_
    have hq0 : q ≠ 0 := hq.ne
    have hq2a : 0 < (q ^ 2) ^ a := Real.rpow_pos_of_pos (by positivity) a
    by_cases hx : x ≤ 0
    · rw [indicator_of_mem (show x ∈ Iic 0 from hx)]
      have hH0 : 0 ≤ μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2)) := measureReal_nonneg
      rw [Real.norm_of_nonneg (mul_nonneg hq2a.le (mul_nonneg (hg0 x) hH0))]
      have := (hbounds q x hq0).2
      calc (q ^ 2) ^ a * (g x * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2)))
          = g x * ((q ^ 2) ^ a * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2))) := by ring
        _ ≤ 1 * ((q ^ 2) ^ a * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2))) := by
          apply mul_le_mul_of_nonneg_right (hg1 x) (mul_nonneg hq2a.le hH0)
        _ ≤ K * (x ^ 2) ^ a := by rw [one_mul]; exact this
    · rw [indicator_of_notMem (show x ∉ Iic 0 from hx), mul_zero, norm_zero]
      positivity
  · exact hmom.const_mul K
  · refine Eventually.of_forall fun x => ?_
    by_cases hx : x ≤ 0
    · simp only [indicator_of_mem (show x ∈ Iic 0 from hx)]
      -- squeeze
      have hlimexp : Tendsto (fun q : ℝ => K * (x ^ 2) ^ a * exp (-(1 / 2 * (ν * x ^ 2 / q ^ 2))))
          atBot (𝓝 (K * (x ^ 2) ^ a)) := by
        have h0 : Tendsto (fun q : ℝ => (ν : ℝ) * x ^ 2 / q ^ 2) atBot (𝓝 0) := by
          have := (tendsto_inv_atBot_zero (𝕜 := ℝ)).pow 2
          have h2 := this.const_mul ((ν : ℝ) * x ^ 2)
          simp only [zero_pow two_ne_zero, mul_zero] at h2
          refine h2.congr fun q => ?_
          rw [inv_pow, div_eq_mul_inv]
        have h1 := ((h0.const_mul (1 / 2)).neg).rexp.const_mul (K * (x ^ 2) ^ a)
        simpa using h1
      have hlim : Tendsto (fun q : ℝ => (q ^ 2) ^ a * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2)))
          atBot (𝓝 (K * (x ^ 2) ^ a)) := by
        apply tendsto_of_tendsto_of_tendsto_of_le_of_le' hlimexp tendsto_const_nhds
        · filter_upwards [eventually_lt_atBot (0 : ℝ)] with q hq
          exact (hbounds q x hq.ne).1
        · filter_upwards [eventually_lt_atBot (0 : ℝ)] with q hq
          exact (hbounds q x hq.ne).2
      have := hlim.const_mul (g x)
      refine this.congr' (Eventually.of_forall fun q => ?_) |>.trans ?_
      · ring
      · rw [show g x * (K * (x ^ 2) ^ a) = K * (g x * (x ^ 2) ^ a) by ring]
    · simp only [indicator_of_notMem (show x ∉ Iic 0 from hx), mul_zero]
      exact tendsto_const_nhds

#print axioms tdc_scaled_limit

lemma tdc_event_iff (ν q z v : ℝ) (hν : 0 < ν) (hq : q < 0) :
    z / √(v / ν) ≤ q ↔ (z ≤ 0 ∧ 0 < v ∧ v ≤ ν * z ^ 2 / q ^ 2) := by
  have hq2 : 0 < q ^ 2 := by nlinarith
  constructor
  · intro h
    have hv : 0 < v := by
      by_contra hv; push Not at hv
      have : √(v / ν) = 0 := Real.sqrt_eq_zero'.2 (div_nonpos_of_nonpos_of_nonneg hv hν.le)
      rw [this, div_zero] at h; linarith
    have hw : 0 < √(v / ν) := Real.sqrt_pos.2 (div_pos hv hν)
    have hw2 : √(v / ν) ^ 2 = v / ν := Real.sq_sqrt (div_pos hv hν).le
    rw [div_le_iff₀ hw] at h
    have hz : z < 0 := by nlinarith
    refine ⟨hz.le, hv, ?_⟩
    rw [le_div_iff₀ hq2]
    have hqw : q * √(v / ν) < 0 := mul_neg_of_neg_of_pos hq hw
    have h1 : (q * √(v / ν)) ^ 2 ≤ z ^ 2 := by
      have := mul_self_le_mul_self (neg_nonneg.2 hqw.le) (neg_le_neg h)
      nlinarith
    rw [mul_pow, hw2] at h1
    have : q ^ 2 * (v / ν) * ν = v * q ^ 2 := by field_simp
    nlinarith
  · rintro ⟨hz, hv, hvz⟩
    have hw : 0 < √(v / ν) := Real.sqrt_pos.2 (div_pos hv hν)
    have hw2 : √(v / ν) ^ 2 = v / ν := Real.sq_sqrt (div_pos hv hν).le
    rw [div_le_iff₀ hw]
    rw [le_div_iff₀ hq2] at hvz
    have h1 : q ^ 2 * √(v / ν) ^ 2 ≤ z ^ 2 := by
      rw [hw2]
      have : q ^ 2 * (v / ν) * ν = v * q ^ 2 := by field_simp
      have h3 : q ^ 2 * (v / ν) * ν ≤ z ^ 2 * ν := by nlinarith
      exact le_of_mul_le_mul_right h3 hν
    nlinarith [mul_neg_of_neg_of_pos hq hw]

#print axioms tdc_event_iff

lemma tdc_prod_meas (μV : Measure ℝ) [IsProbabilityMeasure μV] (T : ℝ → Set ℝ)
    (hT : MeasurableSet {p : ℝ × ℝ | p.2 ∈ T p.1}) (g : ℝ → ℝ) (hg : Measurable g) :
    (((gaussianReal 0 1).prod (gaussianReal 0 1)).prod μV).real
        {p | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧ 0 < p.2 ∧ p.2 ≤ g p.1.1} =
      ∫ x, (Iic 0).indicator
        (fun x => (gaussianReal 0 1).real (T x) * μV.real (Ioc 0 (g x))) x ∂(gaussianReal 0 1) := by
  set μG := gaussianReal 0 1
  have hA : MeasurableSet {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1} :=
    (measurableSet_le measurable_fst measurable_const).inter hT
  have hS : MeasurableSet {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧ 0 < p.2 ∧
      p.2 ≤ g p.1.1} := by
    have e : {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧ 0 < p.2 ∧ p.2 ≤ g p.1.1} =
        (Prod.fst ⁻¹' {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1}) ∩
          ({p | 0 < p.2} ∩ {p | p.2 ≤ g p.1.1}) := by
      ext p; simp [and_assoc]
    rw [e]
    exact (hA.preimage measurable_fst).inter ((measurableSet_lt measurable_const measurable_snd).inter
      (measurableSet_le measurable_snd (hg.comp (measurable_fst.comp measurable_fst))))
  have hmono : Monotone (fun t : ℝ => μV (Ioc 0 t)) := fun t t' h =>
    measure_mono (Ioc_subset_Ioc_right h)
  have hHm : Measurable (fun x : ℝ => μV (Ioc 0 (g x))) := hmono.measurable.comp hg
  have hTm : Measurable (fun x : ℝ => μG (T x)) := measurable_measure_prodMk_left hT
  have h1 : (((μG.prod μG).prod μV)) {p | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧ 0 < p.2 ∧
      p.2 ≤ g p.1.1} = ∫⁻ x, (Iic 0).indicator (fun x => μG (T x) * μV (Ioc 0 (g x))) x ∂μG := by
    rw [Measure.prod_apply hS]
    have e2 : ∀ p : ℝ × ℝ, μV (Prod.mk p ⁻¹' {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧
        0 < p.2 ∧ p.2 ≤ g p.1.1}) = {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1}.indicator
          (fun p => μV (Ioc 0 (g p.1))) p := by
      intro p
      by_cases hp : p.1 ≤ 0 ∧ p.2 ∈ T p.1
      · rw [indicator_of_mem (by exact hp)]
        congr 1; ext v; simp [hp.1, hp.2, Ioc]
      · rw [indicator_of_notMem (by exact hp)]
        have : Prod.mk p ⁻¹' {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧
            0 < p.2 ∧ p.2 ≤ g p.1.1} = ∅ := by
          ext v; simp only [mem_preimage, mem_ofPred_eq, mem_empty_iff_false, iff_false]
          intro h; exact hp ⟨h.1, h.2.1⟩
        rw [this, measure_empty]
    simp_rw [e2]
    rw [lintegral_prod (fun p : ℝ × ℝ => {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1}.indicator
      (fun p => μV (Ioc 0 (g p.1))) p)
      (by exact ((hHm.comp measurable_fst).indicator hA).aemeasurable)]
    apply lintegral_congr; intro x
    by_cases hx : x ≤ 0
    · rw [indicator_of_mem (by exact hx)]
      have : ∀ y, {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1}.indicator (fun p => μV (Ioc 0 (g p.1)))
          (x, y) = (T x).indicator (fun _ => μV (Ioc 0 (g x))) y := by
        intro y
        by_cases hy : y ∈ T x
        · rw [indicator_of_mem (by exact ⟨hx, hy⟩), indicator_of_mem hy]
        · rw [indicator_of_notMem (by exact fun h => hy h.2), indicator_of_notMem hy]
      simp_rw [this]
      have hTx : MeasurableSet (T x) := measurable_prodMk_left hT
      rw [lintegral_indicator_const hTx, mul_comm]
    · rw [indicator_of_notMem (by exact hx)]
      have : ∀ y, {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1}.indicator (fun p => μV (Ioc 0 (g p.1)))
          (x, y) = 0 := fun y => indicator_of_notMem (by exact fun h => hx h.1) _
      simp_rw [this, lintegral_zero]
  rw [measureReal_def, h1, ← integral_toReal]
  · apply integral_congr_ae; refine Eventually.of_forall fun x => ?_
    by_cases hx : x ≤ 0
    · simp only [indicator_of_mem (show x ∈ Iic 0 from hx), ENNReal.toReal_mul, measureReal_def]
    · simp only [indicator_of_notMem (show x ∉ Iic 0 from hx), ENNReal.toReal_zero]
  · exact ((hTm.mul hHm).indicator measurableSet_Iic).aemeasurable
  · refine Eventually.of_forall fun x => ?_
    by_cases hx : x ≤ 0
    · rw [indicator_of_mem (show x ∈ Iic 0 from hx)]
      exact ENNReal.mul_lt_top (measure_lt_top _ _) (measure_lt_top _ _)
    · rw [indicator_of_notMem (show x ∉ Iic 0 from hx)]; exact ENNReal.zero_lt_top

#print axioms tdc_prod_meas

lemma tdc_phi_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-(x ^ 2 / 2)) := by
  simp [gaussianPDFReal_def, neg_div]

#print axioms tdc_phi_eq

lemma tdc_half (f : ℝ → ℝ) :
    ∫ x, (Iic 0).indicator f x ∂(gaussianReal 0 1) =
      ∫ x in Ioi 0, gaussianPDFReal 0 1 x * f (-x) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have e : (fun x => gaussianPDFReal 0 1 x • (Iic 0).indicator f x) =
      (Iic 0).indicator (fun x => gaussianPDFReal 0 1 x * f x) := by
    ext x; by_cases hx : x ∈ Iic (0 : ℝ) <;> simp [hx]
  rw [e, integral_indicator measurableSet_Iic]
  have := integral_comp_neg_Iic (0 : ℝ) (fun x => gaussianPDFReal 0 1 (-x) * f (-x))
  simp only [neg_neg, neg_zero] at this
  rw [this]
  apply setIntegral_congr_fun measurableSet_Ioi
  intro x _
  simp only [tdc_phi_eq, neg_sq]

#print axioms tdc_half

lemma tdc_Phi_integral (t : ℝ) :
    (gaussianReal 0 1).real (Iic t) = ∫ w in Iic t, gaussianPDFReal 0 1 w := by
  rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun x _ => gaussianPDFReal_nonneg _ _ x))]

#print axioms tdc_Phi_integral

lemma tdc_Iic_scale (f : ℝ → ℝ) (m C : ℝ) (hm : 0 < m) :
    ∫ y in Iic C, f (m * y) = m⁻¹ * ∫ w in Iic (m * C), f w := by
  have h1 := integral_comp_neg_Iic C (fun z => f (-(m * z)))
  simp only [mul_neg, neg_neg] at h1
  rw [h1]
  have h2 := integral_comp_mul_left_Ioi (fun u => f (-u)) (-C) hm
  rw [h2, smul_eq_mul]
  have h3 := integral_comp_neg_Ioi (m * -C) f
  rw [h3]; congr 2; ring_nf

#print axioms tdc_Iic_scale

lemma tdc_I1_formula (ν : ℕ) :
    ∫ x, (Iic 0).indicator (fun x => (x ^ 2) ^ ((ν : ℝ) / 2)) x ∂(gaussianReal 0 1) =
      (√(2 * π))⁻¹ * ((1 / 2 : ℝ) ^ (-((ν : ℝ) + 1) / 2) * (1 / 2) * Gamma (((ν : ℝ) + 1) / 2)) := by
  rw [tdc_half]
  have e : ∫ x in Ioi 0, gaussianPDFReal 0 1 x * ((-x) ^ 2) ^ ((ν : ℝ) / 2) =
      ∫ x in Ioi 0, (√(2 * π))⁻¹ * (x ^ (ν : ℝ) * exp (-(1 / 2) * x ^ (2 : ℝ))) := by
    apply setIntegral_congr_fun measurableSet_Ioi
    intro x hx
    simp only [tdc_phi_eq, neg_sq, tdc_sq_rpow, abs_of_pos (show 0 < x from hx), Real.rpow_two]
    ring_nf
  rw [e, integral_const_mul, integral_rpow_mul_exp_neg_mul_rpow (by norm_num)
    (by have : (0 : ℝ) ≤ ν := Nat.cast_nonneg ν; linarith) (by norm_num)]

#print axioms tdc_I1_formula

lemma tdc_I1_pos (ν : ℕ) :
    0 < ∫ x, (Iic 0).indicator (fun x => (x ^ 2) ^ ((ν : ℝ) / 2)) x ∂(gaussianReal 0 1) := by
  rw [tdc_I1_formula]
  have : 0 < Gamma (((ν : ℝ) + 1) / 2) := Real.Gamma_pos_of_pos (by positivity)
  positivity


#print axioms tdc_I1_pos

lemma tdc_algebra (ν : ℕ) (y : ℝ) :
    (2 * π)⁻¹ * (√((ν : ℝ) + 1))⁻¹ *
      (((1 + y ^ 2 / ((ν : ℝ) + 1)) / 2) ^ (-(((ν : ℝ) + 1) + 1) / 2) * (1 / 2) *
        Gamma ((((ν : ℝ) + 1) + 1) / 2)) =
    (√(2 * π))⁻¹ * ((1 / 2 : ℝ) ^ (-((ν : ℝ) + 1) / 2) * (1 / 2) * Gamma (((ν : ℝ) + 1) / 2)) *
      studentTDensity (ν + 1) y := by
  unfold studentTDensity
  push_cast
  set n : ℝ := (ν : ℝ) + 1 with hn
  have hn0 : 0 < n := by positivity
  set u : ℝ := 1 + y ^ 2 / n with hu
  have hu0 : 0 < u := by positivity
  have hG : 0 < Gamma (n / 2) := Real.Gamma_pos_of_pos (by positivity)
  set e : ℝ := -((n + 1) / 2)
  have h1 : (u / 2) ^ (-(n + 1) / 2) = u ^ e * (2 ^ (n / 2) * √2) := by
    rw [Real.div_rpow hu0.le (by norm_num), show -(n + 1) / 2 = e by ring, div_eq_mul_inv,
      ← Real.rpow_neg (by norm_num), show -e = n / 2 + 1 / 2 by ring,
      Real.rpow_add (by norm_num), Real.sqrt_eq_rpow]
  have h2 : (1 / 2 : ℝ) ^ (-n / 2) = 2 ^ (n / 2) := by
    rw [one_div, Real.inv_rpow (by norm_num), ← Real.rpow_neg (by norm_num)]; congr 1; ring
  rw [h1, h2]
  have hs2 : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have hsp : √π * √π = π := Real.mul_self_sqrt Real.pi_pos.le
  rw [Real.sqrt_mul (by norm_num), Real.sqrt_mul hn0.le]
  have : 0 < √2 := by positivity
  have : 0 < √π := Real.sqrt_pos.2 Real.pi_pos
  have : 0 < √n := Real.sqrt_pos.2 hn0
  have : 0 < Real.pi := Real.pi_pos
  field_simp
  rw [show (2 : ℝ) * π = √2 * √2 * (√π * √π) by rw [hs2, hsp]]
  ring

#print axioms tdc_algebra

lemma tdc_inner_eq (ν : ℕ) (x y : ℝ) (hx : 0 < x) :
    gaussianPDFReal 0 1 x * (x ^ 2) ^ ((ν : ℝ) / 2) *
        (x / √((ν : ℝ) + 1) * gaussianPDFReal 0 1 (x / √((ν : ℝ) + 1) * y)) =
      (2 * π)⁻¹ * (√((ν : ℝ) + 1))⁻¹ *
        (x ^ ((ν : ℝ) + 1) * exp (-((1 + y ^ 2 / ((ν : ℝ) + 1)) / 2) * x ^ (2 : ℝ))) := by
  have hn0 : 0 < (ν : ℝ) + 1 := by positivity
  have hsn : √((ν : ℝ) + 1) ^ 2 = (ν : ℝ) + 1 := Real.sq_sqrt hn0.le
  have hsn0 : 0 < √((ν : ℝ) + 1) := Real.sqrt_pos.2 hn0
  rw [tdc_phi_eq, tdc_phi_eq, tdc_sq_rpow, abs_of_pos hx, Real.rpow_add_one hx.ne', Real.rpow_two]
  have h2 : (√(2 * π))⁻¹ * (√(2 * π))⁻¹ = (2 * π)⁻¹ := by
    rw [← mul_inv, Real.mul_self_sqrt (by positivity)]
  have he : exp (-(x ^ 2 / 2)) * exp (-((x / √((ν : ℝ) + 1) * y) ^ 2 / 2)) =
      exp (-((1 + y ^ 2 / ((ν : ℝ) + 1)) / 2) * x ^ 2) := by
    rw [← Real.exp_add]; congr 1
    rw [mul_pow, div_pow, hsn]; field_simp; ring
  calc _ = ((√(2 * π))⁻¹ * (√(2 * π))⁻¹) * (√((ν : ℝ) + 1))⁻¹ * (x ^ (ν : ℝ) * x *
        (exp (-(x ^ 2 / 2)) * exp (-((x / √((ν : ℝ) + 1) * y) ^ 2 / 2)))) := by
          field_simp
    _ = _ := by rw [h2, he]

#print axioms tdc_inner_eq

lemma tdc_inner_integral (ν : ℕ) (y : ℝ) :
    ∫ x in Ioi 0, gaussianPDFReal 0 1 x * (x ^ 2) ^ ((ν : ℝ) / 2) *
        (x / √((ν : ℝ) + 1) * gaussianPDFReal 0 1 (x / √((ν : ℝ) + 1) * y)) =
      (∫ x, (Iic 0).indicator (fun x => (x ^ 2) ^ ((ν : ℝ) / 2)) x ∂(gaussianReal 0 1)) *
        studentTDensity (ν + 1) y := by
  have hn0 : 0 < (ν : ℝ) + 1 := by positivity
  rw [setIntegral_congr_fun measurableSet_Ioi (fun x hx => tdc_inner_eq ν x y hx),
    integral_const_mul, integral_rpow_mul_exp_neg_mul_rpow (by norm_num) (by linarith)
      (by positivity), tdc_I1_formula, tdc_algebra]

#print axioms tdc_inner_integral

lemma tdc_inner_integrable (ν : ℕ) (y : ℝ) :
    IntegrableOn (fun x => gaussianPDFReal 0 1 x * (x ^ 2) ^ ((ν : ℝ) / 2) *
        (x / √((ν : ℝ) + 1) * gaussianPDFReal 0 1 (x / √((ν : ℝ) + 1) * y))) (Ioi 0) := by
  have hn0 : 0 < (ν : ℝ) + 1 := by positivity
  have h := (integrableOn_rpow_mul_exp_neg_mul_rpow (s := (ν : ℝ) + 1) (p := 2)
    (b := (1 + y ^ 2 / ((ν : ℝ) + 1)) / 2) (by linarith) (by norm_num) (by positivity)).const_mul
    ((2 * π)⁻¹ * (√((ν : ℝ) + 1))⁻¹)
  exact IntegrableOn.congr_fun h (fun x hx => (tdc_inner_eq ν x y hx).symm) measurableSet_Ioi

#print axioms tdc_inner_integrable

lemma tdc_student_identity (ν : ℕ) (hν : 1 ≤ ν) (k : ℝ) (hk : 0 < k) :
    ∫ x, (Iic 0).indicator (fun x => (gaussianReal 0 1).real (Iic (k * x)) *
        (x ^ 2) ^ ((ν : ℝ) / 2)) x ∂(gaussianReal 0 1) =
      (∫ x, (Iic 0).indicator (fun x => (x ^ 2) ^ ((ν : ℝ) / 2)) x ∂(gaussianReal 0 1)) *
        studentTCDF (ν + 1) (-(k * √((ν : ℝ) + 1))) := by
  have hn0 : 0 < (ν : ℝ) + 1 := by positivity
  set sn := √((ν : ℝ) + 1) with hsn_def
  have hsn0 : 0 < sn := Real.sqrt_pos.2 hn0
  set c := -(k * sn) with hc_def
  set I1 := ∫ x, (Iic 0).indicator (fun x => (x ^ 2) ^ ((ν : ℝ) / 2)) x ∂(gaussianReal 0 1)
  set F : ℝ → ℝ → ℝ := fun x y => gaussianPDFReal 0 1 x * (x ^ 2) ^ ((ν : ℝ) / 2) *
        (x / sn * gaussianPDFReal 0 1 (x / sn * y)) with hF_def
  rw [tdc_half]
  -- Step 1: rewrite the integrand as an integral over y
  have step1 : ∀ x ∈ Ioi (0 : ℝ), gaussianPDFReal 0 1 x * ((gaussianReal 0 1).real (Iic (k * -x)) *
      ((-x) ^ 2) ^ ((ν : ℝ) / 2)) = ∫ y in Iic c, F x y := by
    intro x hx
    have hx0 : 0 < x := hx
    have hm : 0 < x / sn := div_pos hx0 hsn0
    have hsc := tdc_Iic_scale (gaussianPDFReal 0 1) (x / sn) c hm
    have hmc : x / sn * c = k * -x := by rw [hc_def]; field_simp
    rw [hmc, ← tdc_Phi_integral] at hsc
    have hΦ : (gaussianReal 0 1).real (Iic (k * -x)) =
        x / sn * ∫ y in Iic c, gaussianPDFReal 0 1 (x / sn * y) := by
      rw [hsc, ← mul_assoc, mul_inv_cancel₀ hm.ne', one_mul]
    simp only [hF_def]
    rw [hΦ, neg_sq]
    have e : (fun y => gaussianPDFReal 0 1 x * (x ^ 2) ^ ((ν : ℝ) / 2) *
        (x / sn * gaussianPDFReal 0 1 (x / sn * y))) = fun y =>
        (gaussianPDFReal 0 1 x * (x ^ 2) ^ ((ν : ℝ) / 2) * (x / sn)) *
          gaussianPDFReal 0 1 (x / sn * y) := by
      ext y; ring
    rw [e, integral_const_mul]; ring
  rw [setIntegral_congr_fun measurableSet_Ioi step1]
  -- Step 2: swap
  have hFm : Measurable (Function.uncurry F) := by
    simp only [hF_def]
    fun_prop
  have hint : Integrable (Function.uncurry F)
      ((volume.restrict (Ioi (0 : ℝ))).prod (volume.restrict (Iic c))) := by
    rw [integrable_prod_iff' hFm.aestronglyMeasurable]
    constructor
    · exact Eventually.of_forall fun y => tdc_inner_integrable ν y
    · have : (fun y => ∫ x in Ioi 0, ‖Function.uncurry F (x, y)‖) =
          fun y => I1 * studentTDensity (ν + 1) y := by
        ext y
        rw [← tdc_inner_integral ν y]
        apply setIntegral_congr_fun measurableSet_Ioi
        intro x hx
        simp only [Function.uncurry_apply_pair, hF_def]
        apply Real.norm_of_nonneg
        have hx0 : 0 < x := hx
        have := gaussianPDFReal_nonneg 0 1 x
        have := gaussianPDFReal_nonneg 0 1 (x / sn * y)
        have : 0 ≤ (x ^ 2) ^ ((ν : ℝ) / 2) := Real.rpow_nonneg (sq_nonneg x) _
        have : 0 ≤ x / sn := (div_pos hx0 hsn0).le
        positivity
      rw [this]
      exact ((tdc_integrable (ν + 1) (by omega)).integrableOn).const_mul I1
  rw [integral_integral_swap hint]
  -- Step 3: inner integrals
  have step3 : ∀ y, ∫ x in Ioi 0, F x y = I1 * studentTDensity (ν + 1) y := fun y =>
    tdc_inner_integral ν y
  simp_rw [step3]
  rw [integral_const_mul]
  rfl

#print axioms tdc_student_identity

lemma tdc_prod_law {Ω α β : Type*} [MeasurableSpace Ω] [MeasurableSpace α] [MeasurableSpace β]
    {P : Measure Ω} [IsFiniteMeasure P] {X : Ω → α} {Y : Ω → β} {μ : Measure α} {ν : Measure β}
    (hX : HasLaw X μ P) (hY : HasLaw Y ν P) (hind : IndepFun X Y P) :
    HasLaw (fun ω => (X ω, Y ω)) (μ.prod ν) P := by
  refine ⟨hX.aemeasurable.prodMk hY.aemeasurable, ?_⟩
  rw [(indepFun_iff_map_prod_eq_prod_map_map hX.aemeasurable hY.aemeasurable).1 hind,
    hX.map_eq, hY.map_eq]

#print axioms tdc_prod_law

lemma tdc_region {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X Y V : Ω → ℝ}
    (μV : Measure ℝ) [IsProbabilityMeasure μV]
    (h3 : HasLaw (fun ω => ((X ω, Y ω), V ω)) (((gaussianReal 0 1).prod (gaussianReal 0 1)).prod μV) P)
    (ρ s : ℝ) (hs : 0 < s) (g : ℝ → ℝ) (hg : Measurable g) :
    P.real {ω | X ω ≤ 0 ∧ ρ * X ω + s * Y ω ≤ X ω ∧ 0 < V ω ∧ V ω ≤ g (X ω)} =
      ∫ x, (Iic 0).indicator (fun x => (gaussianReal 0 1).real (Iic ((1 - ρ) / s * x)) *
        μV.real (Ioc 0 (g x))) x ∂(gaussianReal 0 1) ∧
    P.real {ω | X ω ≤ 0 ∧ ρ * X ω + s * Y ω < X ω ∧ 0 < V ω ∧ V ω ≤ g (X ω)} =
      ∫ x, (Iic 0).indicator (fun x => (gaussianReal 0 1).real (Iic ((1 - ρ) / s * x)) *
        μV.real (Ioc 0 (g x))) x ∂(gaussianReal 0 1) := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have hmeasS : ∀ T : ℝ → Set ℝ, MeasurableSet {p : ℝ × ℝ | p.2 ∈ T p.1} →
      MeasurableSet {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧ 0 < p.2 ∧ p.2 ≤ g p.1.1} := by
    intro T hT
    have hA : MeasurableSet {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1} :=
      (measurableSet_le measurable_fst measurable_const).inter hT
    have e : {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ p.1.2 ∈ T p.1.1 ∧ 0 < p.2 ∧ p.2 ≤ g p.1.1} =
        (Prod.fst ⁻¹' {p : ℝ × ℝ | p.1 ≤ 0 ∧ p.2 ∈ T p.1}) ∩
          ({p | 0 < p.2} ∩ {p | p.2 ≤ g p.1.1}) := by
      ext p; simp [and_assoc]
    rw [e]
    exact (hA.preimage measurable_fst).inter ((measurableSet_lt measurable_const measurable_snd).inter
      (measurableSet_le measurable_snd (hg.comp (measurable_fst.comp measurable_fst))))
  have hTle : ∀ x, {y : ℝ | ρ * x + s * y ≤ x} = Iic ((1 - ρ) / s * x) := by
    intro x; ext y; simp only [mem_ofPred_eq, mem_Iic]
    rw [div_mul_eq_mul_div, le_div_iff₀ hs]; constructor <;> intro h <;> linarith
  have hTlt : ∀ x, {y : ℝ | ρ * x + s * y < x} = Iio ((1 - ρ) / s * x) := by
    intro x; ext y; simp only [mem_ofPred_eq, mem_Iio]
    rw [div_mul_eq_mul_div, lt_div_iff₀ hs]; constructor <;> intro h <;> linarith
  constructor
  · have hT : MeasurableSet {p : ℝ × ℝ | p.2 ∈ {y : ℝ | ρ * p.1 + s * y ≤ p.1}} :=
      measurableSet_le (f := fun p : ℝ × ℝ => ρ * p.1 + s * p.2) (g := fun p : ℝ × ℝ => p.1)
        (by fun_prop) (by fun_prop)
    have := h3.measureReal_eq (hmeasS (fun x => {y : ℝ | ρ * x + s * y ≤ x}) hT)
    have h2 := tdc_prod_meas μV (fun x => {y : ℝ | ρ * x + s * y ≤ x}) hT g hg
    simp only [mem_ofPred_eq] at this h2
    rw [this, h2]
    simp_rw [hTle]
  · have hT : MeasurableSet {p : ℝ × ℝ | p.2 ∈ {y : ℝ | ρ * p.1 + s * y < p.1}} :=
      measurableSet_lt (f := fun p : ℝ × ℝ => ρ * p.1 + s * p.2) (g := fun p : ℝ × ℝ => p.1)
        (by fun_prop) (by fun_prop)
    have := h3.measureReal_eq (hmeasS (fun x => {y : ℝ | ρ * x + s * y < x}) hT)
    have h2 := tdc_prod_meas μV (fun x => {y : ℝ | ρ * x + s * y < x}) hT g hg
    simp only [mem_ofPred_eq] at this h2
    rw [this, h2]
    simp_rw [hTlt, measureReal_congr (Iio_ae_eq_Iic (μ := gaussianReal 0 1))]

#print axioms tdc_region

lemma tdc_univ_region {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X Y V : Ω → ℝ}
    (μV : Measure ℝ) [IsProbabilityMeasure μV]
    (h3 : HasLaw (fun ω => ((X ω, Y ω), V ω)) (((gaussianReal 0 1).prod (gaussianReal 0 1)).prod μV) P)
    (g : ℝ → ℝ) (hg : Measurable g) :
    P.real {ω | X ω ≤ 0 ∧ 0 < V ω ∧ V ω ≤ g (X ω)} =
      ∫ x, (Iic 0).indicator (fun x => 1 * μV.real (Ioc 0 (g x))) x ∂(gaussianReal 0 1) := by
  have hT : MeasurableSet {p : ℝ × ℝ | p.2 ∈ (fun _ : ℝ => (univ : Set ℝ)) p.1} := by simp
  have hS : MeasurableSet {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ p.1.2 ∈ (fun _ : ℝ => (univ : Set ℝ)) p.1.1 ∧
      0 < p.2 ∧ p.2 ≤ g p.1.1} := by
    simp only [mem_univ, true_and]
    exact (measurableSet_le (f := fun p : (ℝ × ℝ) × ℝ => p.1.1) (by fun_prop) measurable_const).inter
      ((measurableSet_lt measurable_const measurable_snd).inter
      (measurableSet_le measurable_snd (hg.comp (measurable_fst.comp measurable_fst))))
  have := h3.measureReal_eq hS
  simp only [mem_univ, true_and] at this
  rw [this]
  have h2 := tdc_prod_meas μV (fun _ => univ) hT g hg
  simp only [mem_univ, true_and, probReal_univ] at h2
  exact h2

#print axioms tdc_univ_region

lemma tdc_sq_div_mono (ν q z w : ℝ) (hν : 0 ≤ ν) (h : z ^ 2 ≤ w ^ 2) :
    ν * z ^ 2 / q ^ 2 ≤ ν * w ^ 2 / q ^ 2 :=
  div_le_div_of_nonneg_right (mul_le_mul_of_nonneg_left h hν) (sq_nonneg q)

#print axioms tdc_sq_div_mono

lemma tdc_indicator_const_mul (K : ℝ) (f : ℝ → ℝ) (μ : Measure ℝ) :
    ∫ x, (Iic 0).indicator (fun x => K * f x) x ∂μ = K * ∫ x, (Iic 0).indicator f x ∂μ := by
  rw [← integral_const_mul]
  congr 1; ext x
  by_cases hx : x ∈ Iic (0 : ℝ) <;> simp [hx]

#print axioms tdc_indicator_const_mul

/-- **The Gaussian copula has zero tail dependence** (The formula; Why it works, Step 1). Let the
two names' scores be bell-curve draws with correlation `ρ`: `G₁ = Z₁` and
`G₂ = ρ Z₁ + √(1 - ρ²) Z₂` for two independent standard bell-curve draws `Z₁`, `Z₂`. For every
correlation `-1 ≤ ρ < 1`, the chance that both scores are below a cutoff `a`, divided by the chance
that the first one is (that is, the chance name 2 is in its tail given name 1 is), tends to zero
as the cutoff is pushed out to minus infinity. -/
theorem gaussian_copula_tail_dependence_eq_zero
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) P) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) P)
    (hind : IndepFun Z₁ Z₂ P) (ρ : ℝ) (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ < 1) :
    Tendsto
      (fun a : ℝ =>
        P.real {ω | Z₁ ω ≤ a ∧ ρ * Z₁ ω + √(1 - ρ ^ 2) * Z₂ ω ≤ a} / P.real {ω | Z₁ ω ≤ a})
      atBot (𝓝 0) := by
  have := hZ₁.isProbabilityMeasure
  have hL := tdc_pair_law hZ₁ hZ₂ hind
  set s := √(1 - ρ ^ 2) with hs_def
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs1 : s ≤ 1 := by
    rw [hs_def, Real.sqrt_le_one]; nlinarith [sq_nonneg ρ]
  -- choose c > 1, d > 0 with the inclusion
  obtain ⟨c, d, hc, hd, hincl⟩ : ∃ c d : ℝ, 1 < c ∧ 0 < d ∧ ∀ a : ℝ, a < 0 → ∀ x y : ℝ,
      x ≤ a → ρ * x + s * y ≤ a → x ≤ c * a ∨ (x ≤ a ∧ y ≤ d * a) := by
    rcases le_or_gt ρ 0 with hρ | hρ
    · refine ⟨2, 1, by norm_num, by norm_num, fun a ha x y hx hy => Or.inr ⟨hx, ?_⟩⟩
      have h1 : 0 ≤ ρ * x := mul_nonneg_of_nonpos_of_nonpos hρ (by linarith)
      have h2 : s * y ≤ a := by linarith
      have hy0 : y ≤ 0 := by
        by_contra h; push Not at h; nlinarith
      have : y ≤ s * y := by nlinarith
      linarith
    · refine ⟨2 / (1 + ρ), 1 - ρ * (2 / (1 + ρ)), ?_, ?_, fun a ha x y hx hy => ?_⟩
      · rw [lt_div_iff₀ (by linarith)]; linarith
      · have : ρ * (2 / (1 + ρ)) < 1 := by
          rw [mul_div_assoc', div_lt_one (by linarith)]; linarith
        linarith
      · by_cases hxc : x ≤ 2 / (1 + ρ) * a
        · exact Or.inl hxc
        · right; refine ⟨hx, ?_⟩
          push Not at hxc
          have hd' : 0 < 1 - ρ * (2 / (1 + ρ)) := by
            have : ρ * (2 / (1 + ρ)) < 1 := by
              rw [mul_div_assoc', div_lt_one (by linarith)]; linarith
            linarith
          have h1 : ρ * (2 / (1 + ρ) * a) < ρ * x := mul_lt_mul_of_pos_left hxc hρ
          have h2 : s * y < (1 - ρ * (2 / (1 + ρ))) * a := by nlinarith
          have hda : (1 - ρ * (2 / (1 + ρ))) * a < 0 := mul_neg_of_pos_of_neg hd' ha
          have hy0 : y ≤ 0 := by
            by_contra h; push Not at h; nlinarith
          have : y ≤ s * y := by nlinarith
          linarith
  have hcd := (tdc_Phi_ratio c hc).add ((tdc_Phi_tendsto).comp
    (Tendsto.const_mul_atBot hd tendsto_id))
  rw [add_zero] at hcd
  apply tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hcd
  · filter_upwards with a
    exact div_nonneg measureReal_nonneg measureReal_nonneg
  · filter_upwards [eventually_lt_atBot (0 : ℝ)] with a ha
    have hden : P.real {ω | Z₁ ω ≤ a} = (gaussianReal 0 1).real (Iic a) :=
      hZ₁.measureReal_eq (p := fun x => x ≤ a) measurableSet_Iic
    have hP := tdc_Phi_pos a ha.le
    rw [hden, div_le_iff₀ hP]
    have hsub : {ω | Z₁ ω ≤ a ∧ ρ * Z₁ ω + s * Z₂ ω ≤ a} ⊆
        {ω | Z₁ ω ≤ c * a} ∪ {ω | (Z₁ ω, Z₂ ω) ∈ Iic a ×ˢ Iic (d * a)} := by
      intro ω ⟨h1, h2⟩
      rcases hincl a ha _ _ h1 h2 with h | h
      · exact Or.inl h
      · exact Or.inr h
    have e1 : P.real {ω | Z₁ ω ≤ c * a} = (gaussianReal 0 1).real (Iic (c * a)) :=
      hZ₁.measureReal_eq (p := fun x => x ≤ c * a) measurableSet_Iic
    have e2 : P.real {ω | (Z₁ ω, Z₂ ω) ∈ Iic a ×ˢ Iic (d * a)} =
        (gaussianReal 0 1).real (Iic a) * (gaussianReal 0 1).real (Iic (d * a)) := by
      rw [hL.measureReal_eq (p := fun z => z ∈ Iic a ×ˢ Iic (d * a))
        (measurableSet_Iic.prod measurableSet_Iic)]
      simp only [Set.ofPred_mem_eq]
      rw [measureReal_prod_prod]
    calc P.real {ω | Z₁ ω ≤ a ∧ ρ * Z₁ ω + s * Z₂ ω ≤ a}
        ≤ P.real ({ω | Z₁ ω ≤ c * a} ∪ {ω | (Z₁ ω, Z₂ ω) ∈ Iic a ×ˢ Iic (d * a)}) :=
          measureReal_mono hsub
      _ ≤ P.real {ω | Z₁ ω ≤ c * a} + P.real {ω | (Z₁ ω, Z₂ ω) ∈ Iic a ×ˢ Iic (d * a)} :=
          measureReal_union_le _ _
      _ = _ := by
          rw [e1, e2]
          simp only [Function.comp, id]
          rw [add_mul, div_mul_cancel₀ _ hP.ne']
          ring

/-- **The t copula's tail dependence is positive, with the card's closed form** (The formula;
Why it works, Step 2). Build the Gaussian pair `G₁ = Z₁`, `G₂ = ρ Z₁ + √(1 - ρ²) Z₂` as above,
and one shared chi-square draw `V` with `ν ≥ 1` degrees of freedom (the gamma law with shape `ν/2`
and rate `1/2`), with `Z₁`, `Z₂`, `V` independent. Divide both scores by the same mood `√(V/ν)`:
`Yᵢ = Gᵢ / √(V/ν)`. For every correlation `-1 < ρ < 1`, the chance that both `Yᵢ` are below a
cutoff `q`, divided by the chance that `Y₁` is, tends as `q → -∞` to
`λ_t = 2 t_{ν+1}(-√((ν+1)(1-ρ)/(1+ρ)))`, and this limit is strictly positive. -/
theorem t_copula_tail_dependence_eq_and_pos
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {Z₁ Z₂ V : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) P) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) P)
    (ν : ℕ) (hν : 1 ≤ ν) (hV : HasLaw V (gammaMeasure ((ν : ℝ) / 2) (1 / 2)) P)
    (hind : iIndepFun ![Z₁, Z₂, V] P) (ρ : ℝ) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) :
    Tendsto
      (fun q : ℝ =>
        P.real {ω | Z₁ ω / √(V ω / ν) ≤ q ∧
            (ρ * Z₁ ω + √(1 - ρ ^ 2) * Z₂ ω) / √(V ω / ν) ≤ q} /
          P.real {ω | Z₁ ω / √(V ω / ν) ≤ q})
      atBot (𝓝 (tTailDependence ν ρ)) ∧
    0 < tTailDependence ν ρ := by
  refine ⟨?_, ?_⟩
  swap
  · unfold tTailDependence
    have := tdc_cdf_pos (ν + 1) (by omega) (-√(((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ)))
    linarith
  have hPprob := hZ₁.isProbabilityMeasure
  have hνr : (0 : ℝ) < ν := by exact_mod_cast hν
  have ha : (0 : ℝ) < (ν : ℝ) / 2 := by positivity
  set μV := gammaMeasure ((ν : ℝ) / 2) (1 / 2) with hμV
  have : IsProbabilityMeasure μV := isProbabilityMeasure_gammaMeasure ha (by norm_num)
  set s := √(1 - ρ ^ 2) with hs_def
  have hs2 : s ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt (by nlinarith)
  have hs : 0 < s := Real.sqrt_pos.2 (by nlinarith)
  have hρs : ρ ^ 2 + s ^ 2 = 1 := by rw [hs2]; ring
  set k := (1 - ρ) / s with hk_def
  have hk : 0 < k := div_pos (by linarith) hs
  -- independence and laws
  have hmeas : ∀ i, AEMeasurable (![Z₁, Z₂, V] i) P := by
    intro i; fin_cases i
    · exact hZ₁.aemeasurable
    · exact hZ₂.aemeasurable
    · exact hV.aemeasurable
  have h01 : IndepFun Z₁ Z₂ P := by
    have := hind.indepFun (show (0 : Fin 3) ≠ 1 by decide); simpa using this
  have h12V : IndepFun (fun ω => (Z₁ ω, Z₂ ω)) V P := by
    have := hind.indepFun_prodMk₀ hmeas 0 1 2 (by decide) (by decide); simpa using this
  have hL12 := tdc_prod_law hZ₁ hZ₂ h01
  have h3 := tdc_prod_law hL12 hV h12V
  set A : Ω → ℝ := fun ω => ρ * Z₁ ω + s * Z₂ ω with hA_def
  set B : Ω → ℝ := fun ω => s * Z₁ ω + -ρ * Z₂ ω with hB_def
  have hLAB : HasLaw (fun ω => (A ω, B ω)) ((gaussianReal 0 1).prod (gaussianReal 0 1)) P :=
    tdc_rot_law hZ₁ hZ₂ h01 ρ s hρs
  have hABV : IndepFun (fun ω => (A ω, B ω)) V P :=
    h12V.comp (φ := fun p : ℝ × ℝ => (ρ * p.1 + s * p.2, s * p.1 + -ρ * p.2)) (ψ := id)
      (by fun_prop) measurable_id
  have h3' := tdc_prod_law hLAB hV hABV
  have hZ1 : ∀ ω, ρ * A ω + s * B ω = Z₁ ω := by
    intro ω; simp only [hA_def, hB_def]; linear_combination Z₁ ω * hρs
  -- the integrals
  set H : ℝ → ℝ := fun t => μV.real (Ioc 0 t) with hH_def
  set Jf : ℝ → ℝ := fun q => ∫ x, (Iic 0).indicator (fun x => (gaussianReal 0 1).real
    (Iic (k * x)) * H (ν * x ^ 2 / q ^ 2)) x ∂(gaussianReal 0 1) with hJf_def
  set J1 : ℝ → ℝ := fun q => ∫ x, (Iic 0).indicator (fun x => 1 * H (ν * x ^ 2 / q ^ 2)) x
    ∂(gaussianReal 0 1) with hJ1_def
  have hN : ∀ q : ℝ, q < 0 → P.real {ω | Z₁ ω / √(V ω / ν) ≤ q ∧
      (ρ * Z₁ ω + s * Z₂ ω) / √(V ω / ν) ≤ q} = 2 * Jf q := by
    intro q hq
    have hgm : Measurable (fun x : ℝ => (ν : ℝ) * x ^ 2 / q ^ 2) := by fun_prop
    have r1 := (tdc_region μV h3 ρ s hs _ hgm).1
    have r2 := (tdc_region μV h3' ρ s hs _ hgm).2
    have hset : {ω | Z₁ ω / √(V ω / ν) ≤ q ∧ (ρ * Z₁ ω + s * Z₂ ω) / √(V ω / ν) ≤ q} =
        {ω | Z₁ ω ≤ 0 ∧ ρ * Z₁ ω + s * Z₂ ω ≤ Z₁ ω ∧ 0 < V ω ∧ V ω ≤ ν * Z₁ ω ^ 2 / q ^ 2} ∪
        {ω | A ω ≤ 0 ∧ ρ * A ω + s * B ω < A ω ∧ 0 < V ω ∧ V ω ≤ ν * A ω ^ 2 / q ^ 2} := by
      ext ω
      simp only [mem_ofPred_eq, mem_union, hZ1]
      rw [tdc_event_iff _ _ _ _ hνr hq, tdc_event_iff _ _ _ _ hνr hq]
      simp only [hA_def]
      constructor
      · rintro ⟨⟨h1, h2, h3⟩, ⟨h4, h5, h6⟩⟩
        rcases le_or_gt (ρ * Z₁ ω + s * Z₂ ω) (Z₁ ω) with h | h
        · exact Or.inl ⟨h1, h, h2, h3⟩
        · exact Or.inr ⟨h4, h, h5, h6⟩
      · rintro (⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩)
        · refine ⟨⟨h1, h3, h4⟩, ⟨by linarith, h3, le_trans h4 (tdc_sq_div_mono _ _ _ _
            hνr.le (by nlinarith))⟩⟩
        · refine ⟨⟨by linarith, h3, le_trans h4 (tdc_sq_div_mono _ _ _ _
            hνr.le (by nlinarith))⟩, ⟨h1, h3, h4⟩⟩
    have hdisj : Disjoint
        {ω | Z₁ ω ≤ 0 ∧ ρ * Z₁ ω + s * Z₂ ω ≤ Z₁ ω ∧ 0 < V ω ∧ V ω ≤ ν * Z₁ ω ^ 2 / q ^ 2}
        {ω | A ω ≤ 0 ∧ ρ * A ω + s * B ω < A ω ∧ 0 < V ω ∧ V ω ≤ ν * A ω ^ 2 / q ^ 2} := by
      rw [Set.disjoint_left]
      intro ω h1 h2
      simp only [mem_ofPred_eq, hZ1] at h1 h2
      simp only [hA_def] at h2
      linarith [h1.2.1, h2.2.1]
    have hnm : NullMeasurableSet
        {ω | A ω ≤ 0 ∧ ρ * A ω + s * B ω < A ω ∧ 0 < V ω ∧ V ω ≤ ν * A ω ^ 2 / q ^ 2} P := by
      have hm : MeasurableSet {p : (ℝ × ℝ) × ℝ | p.1.1 ≤ 0 ∧ ρ * p.1.1 + s * p.1.2 < p.1.1 ∧
          0 < p.2 ∧ p.2 ≤ ν * p.1.1 ^ 2 / q ^ 2} := by
        refine (measurableSet_le (f := fun p : (ℝ × ℝ) × ℝ => p.1.1) (by fun_prop)
          measurable_const).inter
          ((measurableSet_lt (f := fun p : (ℝ × ℝ) × ℝ => ρ * p.1.1 + s * p.1.2)
            (g := fun p : (ℝ × ℝ) × ℝ => p.1.1) (by fun_prop) (by fun_prop)).inter
          ((measurableSet_lt (f := fun _ : (ℝ × ℝ) × ℝ => (0 : ℝ)) (g := fun p : (ℝ × ℝ) × ℝ => p.2)
            measurable_const (by fun_prop)).inter
          (measurableSet_le (f := fun p : (ℝ × ℝ) × ℝ => p.2)
            (g := fun p : (ℝ × ℝ) × ℝ => (ν : ℝ) * p.1.1 ^ 2 / q ^ 2) (by fun_prop) (by fun_prop))))
      exact h3'.aemeasurable.nullMeasurable hm
    rw [hset, measureReal_union₀ hnm hdisj.aedisjoint, r1, r2]
    simp only [hJf_def, hH_def]
    ring
  have hD : ∀ q : ℝ, q < 0 → P.real {ω | Z₁ ω / √(V ω / ν) ≤ q} = J1 q := by
    intro q hq
    have hgm : Measurable (fun x : ℝ => (ν : ℝ) * x ^ 2 / q ^ 2) := by fun_prop
    have := tdc_univ_region (Y := Z₂) μV h3 _ hgm
    rw [show J1 q = ∫ x, (Iic 0).indicator (fun x => 1 * μV.real (Ioc 0 (ν * x ^ 2 / q ^ 2))) x
      ∂(gaussianReal 0 1) from rfl, ← this]
    congr 1; ext ω
    simp only [mem_ofPred_eq]
    rw [tdc_event_iff _ _ _ _ hνr hq]
  -- limits
  set K : ℝ := (1 / 2 : ℝ) ^ ((ν : ℝ) / 2) / Gamma ((ν : ℝ) / 2) / ((ν : ℝ) / 2) *
    (ν : ℝ) ^ ((ν : ℝ) / 2) with hK_def
  have hK : 0 < K := by
    have := Real.Gamma_pos_of_pos ha
    positivity
  have hΦm : Measurable (fun x : ℝ => (gaussianReal 0 1).real (Iic (k * x))) := by
    have : Monotone (fun t : ℝ => (gaussianReal 0 1).real (Iic t)) := fun t t' h =>
      measureReal_mono (Iic_subset_Iic.2 h)
    exact this.measurable.comp (measurable_const_mul k)
  have limf := tdc_scaled_limit ν hν (fun x => (gaussianReal 0 1).real (Iic (k * x))) hΦm
    (fun x => measureReal_nonneg) (fun x => by simp)
  have lim1 := tdc_scaled_limit ν hν (fun _ => 1) measurable_const (fun _ => zero_le_one)
    (fun _ => le_refl 1)
  rw [← hK_def] at limf lim1
  set I1 := ∫ x, (Iic 0).indicator (fun x => (x ^ 2) ^ ((ν : ℝ) / 2)) x ∂(gaussianReal 0 1)
  have hI1 : 0 < I1 := tdc_I1_pos ν
  have hlimf : ∫ x, (Iic 0).indicator (fun x => K * ((gaussianReal 0 1).real (Iic (k * x)) *
      (x ^ 2) ^ ((ν : ℝ) / 2))) x ∂(gaussianReal 0 1) =
      K * (I1 * studentTCDF (ν + 1) (-(k * √((ν : ℝ) + 1)))) := by
    rw [tdc_indicator_const_mul, tdc_student_identity ν hν k hk]
  have hlim1 : ∫ x, (Iic 0).indicator (fun x => K * (1 * (x ^ 2) ^ ((ν : ℝ) / 2))) x
      ∂(gaussianReal 0 1) = K * I1 := by
    rw [tdc_indicator_const_mul]; simp only [one_mul]; rfl
  rw [hlimf] at limf
  rw [hlim1] at lim1
  have hratio := (limf.const_mul 2).div lim1 (mul_pos hK hI1).ne'
  have htarget : 2 * (K * (I1 * studentTCDF (ν + 1) (-(k * √((ν : ℝ) + 1))))) / (K * I1) =
      tTailDependence ν ρ := by
    unfold tTailDependence
    have hk2 : k * √((ν : ℝ) + 1) = √(((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ)) := by
      have h1 : k = √((1 - ρ) / (1 + ρ)) := by
        rw [hk_def, hs_def]
        have e : (1 - ρ) / (1 + ρ) = (1 - ρ) ^ 2 / (1 - ρ ^ 2) := by
          have : (1 : ℝ) + ρ ≠ 0 := by linarith
          have : (1 : ℝ) - ρ ^ 2 ≠ 0 := by nlinarith
          field_simp; ring
        rw [e, Real.sqrt_div' _ (by nlinarith : (0:ℝ) ≤ 1 - ρ ^ 2), Real.sqrt_sq (by linarith)]
      rw [h1, ← Real.sqrt_mul (div_pos (by linarith) (by linarith)).le]
      congr 1; ring
    rw [hk2]
    field_simp
  rw [← htarget]
  refine hratio.congr' ?_
  filter_upwards [eventually_lt_atBot (0 : ℝ)] with q hq
  rw [hN q hq, hD q hq]
  have hM : 0 < (q ^ 2) ^ ((ν : ℝ) / 2) := Real.rpow_pos_of_pos (by nlinarith) _
  simp only [Pi.div_apply, hJf_def, hJ1_def, hH_def, hμV]
  rw [integral_const_mul, integral_const_mul, mul_left_comm, mul_div_mul_left _ _ hM.ne']

/-- **The t copula turns Gaussian as the degrees of freedom grow** (Why it works, Step 2): for a
fixed correlation `-1 < ρ < 1`, the t copula's tail dependence
`2 t_{ν+1}(-√((ν+1)(1-ρ)/(1+ρ)))` tends to zero as `ν → ∞`. -/
theorem t_tail_dependence_tendsto_zero (ρ : ℝ) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) :
    Tendsto (fun ν : ℕ => tTailDependence ν ρ) atTop (𝓝 0) := by
  have hc : 0 < (1 - ρ) / (1 + ρ) := div_pos (by linarith) (by linarith)
  have hx : Tendsto (fun ν : ℕ => -√(((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ))) atTop atBot := by
    apply tendsto_neg_atTop_atBot.comp
    apply tendsto_sqrt_atTop.comp
    have : (fun ν : ℕ => ((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ)) =
        fun ν : ℕ => ((ν : ℝ) + 1) * ((1 - ρ) / (1 + ρ)) := by ext; ring
    rw [this]
    apply Tendsto.atTop_mul_const hc
    exact tendsto_atTop_add_const_right _ _ tendsto_natCast_atTop_atTop
  have ha : Tendsto (fun ν : ℕ => 2 * (arctan (-√(((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ))) + π / 2))
      atTop (𝓝 0) := by
    have := (tendsto_nhds_of_tendsto_nhdsWithin tendsto_arctan_atBot).comp hx
    have h2 := (this.add_const (π / 2)).const_mul 2
    simpa using h2
  apply tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds ha
  · intro ν; unfold tTailDependence; have := tdc_cdf_nonneg (ν + 1)
      (-√(((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ))); simp only; linarith
  · intro ν; unfold tTailDependence
    have := tdc_cdf_le (ν + 1) (by omega) (-√(((ν : ℝ) + 1) * (1 - ρ) / (1 + ρ)))
    simp only; linarith

-- Worked numbers, by hand: the number inside the root, (4+1)(1-0.20)/(1+0.20) = 10/3 = 3.3333.
example : ((4 : ℚ) + 1) * (1 - 1 / 5) / (1 + 1 / 5) = 10 / 3 := by norm_num

-- Joint default if independent: 0.05 × 0.05 = 0.0025, the card's 0.25%.
example : (1 / 20 : ℚ) * (1 / 20) = 1 / 400 := by norm_num

-- Completing the square in the t pair's density (Detailed proof, Step 2).
example (ρ y₁ y₂ : ℝ) :
    y₁ ^ 2 - 2 * ρ * y₁ * y₂ + y₂ ^ 2 = (y₂ - ρ * y₁) ^ 2 + (1 - ρ ^ 2) * y₁ ^ 2 := by ring

#print axioms gaussian_copula_tail_dependence_eq_zero
#print axioms t_copula_tail_dependence_eq_and_pos
#print axioms t_tail_dependence_tendsto_zero
