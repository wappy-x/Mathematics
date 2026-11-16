-- Schwartz space and tempered distributions: the Fourier transform maps Schwartz space to itself, the sign function's transform is the principal value of 1/(πiξ), and the step's transform is half a spike plus half that.
import Mathlib.Analysis.Distribution.TemperedDistribution
import Mathlib.Basic.Real.Sign
import Mathlib.Analysis.Fourier.RiemannLebesgueLemma

open SchwartzMap FourierTransform MeasureTheory Filter Topology Complex

noncomputable section

theorem schwartz_oddQuot_integrable (φ : 𝓢(ℝ, ℂ)) :
    Integrable (fun ξ : ℝ => (φ ξ - φ (-ξ)) / (ξ : ℂ)) := by
  set M : ℝ := SchwartzMap.seminorm ℝ 0 0 (SchwartzMap.derivCLM ℝ ℂ φ) with hM
  have hM0 : 0 ≤ M := apply_nonneg _ _
  have hlip : LipschitzWith M.toNNReal φ := by
    refine lipschitzWith_of_nnnorm_deriv_le φ.differentiable fun x => ?_
    have := SchwartzMap.norm_le_seminorm ℝ (SchwartzMap.derivCLM ℝ ℂ φ) x
    rw [SchwartzMap.derivCLM_apply] at this
    rw [← NNReal.coe_le_coe, Real.coe_toNNReal _ hM0, coe_nnnorm]
    exact this
  have hmeas : AEStronglyMeasurable (fun ξ : ℝ => (φ ξ - φ (-ξ)) / (ξ : ℂ)) volume := by
    apply Measurable.aestronglyMeasurable
    exact ((φ.continuous.measurable).sub (φ.continuous.measurable.comp measurable_neg)).div
      Complex.measurable_ofReal
  have hbound : Integrable (fun ξ : ℝ =>
      (Set.Icc (-1 : ℝ) 1).indicator (fun _ => 2 * M) ξ + (‖φ ξ‖ + ‖φ (-ξ)‖)) := by
    refine Integrable.add ?_ (φ.integrable.norm.add (φ.integrable.comp_neg).norm)
    exact (continuous_const.integrableOn_Icc).integrable_indicator measurableSet_Icc
  refine hbound.mono' hmeas (Eventually.of_forall fun ξ => ?_)
  have hnum : ‖φ ξ - φ (-ξ)‖ ≤ M * (2 * |ξ|) := by
    have := hlip.dist_le_mul ξ (-ξ)
    simp only [dist_eq_norm, Real.coe_toNNReal _ hM0] at this
    convert this using 2
    rw [Real.norm_eq_abs, sub_neg_eq_add, ← two_mul, abs_mul, abs_two]
  rw [norm_div, Complex.norm_real, Real.norm_eq_abs]
  by_cases h1 : |ξ| ≤ 1
  · have hmem : ξ ∈ Set.Icc (-1 : ℝ) 1 := abs_le.mp h1
    rw [Set.indicator_of_mem hmem]
    rcases eq_or_ne ξ 0 with h0 | h0
    · subst h0; simp; positivity
    · have hpos : 0 < |ξ| := abs_pos.mpr h0
      rw [div_le_iff₀ hpos]
      nlinarith [norm_nonneg (φ ξ), norm_nonneg (φ (-ξ))]
  · push Not at h1
    have hmem : ξ ∉ Set.Icc (-1 : ℝ) 1 := fun h => by
      have := abs_le.mpr h; linarith
    rw [Set.indicator_of_notMem hmem, zero_add]
    rw [div_le_iff₀ (by linarith)]
    calc ‖φ ξ - φ (-ξ)‖ ≤ ‖φ ξ‖ + ‖φ (-ξ)‖ := norm_sub_le _ _
      _ ≤ (‖φ ξ‖ + ‖φ (-ξ)‖) * |ξ| := by
        nlinarith [norm_nonneg (φ ξ), norm_nonneg (φ (-ξ))]

#print axioms schwartz_oddQuot_integrable

theorem integrable_cexp_ofReal_mul_I_mul {f : ℝ → ℂ} (hf : Integrable f) {c : ℝ → ℝ}
    (hc : Continuous c) : Integrable (fun x => Complex.exp (↑(c x) * Complex.I) * f x) := by
  refine Integrable.mono' hf.norm ?_ (Eventually.of_forall fun x => ?_)
  · exact (by fun_prop : Continuous fun x => Complex.exp (↑(c x) * Complex.I)).aestronglyMeasurable.mul
      hf.aestronglyMeasurable
  · rw [norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul]

#print axioms integrable_cexp_ofReal_mul_I_mul

theorem schwartz_fourier_apply_eq (φ : 𝓢(ℝ, ℂ)) (t : ℝ) :
    (𝓕 φ : 𝓢(ℝ, ℂ)) t =
      ∫ ξ : ℝ, Complex.exp (↑(2 * Real.pi * (-(ξ * t))) * Complex.I) * φ ξ := by
  rw [SchwartzMap.fourier_coe, Real.fourier_real_eq]
  simp_rw [Circle.smul_def, Real.fourierChar_apply, smul_eq_mul]

#print axioms schwartz_fourier_apply_eq

theorem schwartz_fourier_sub_neg (φ : 𝓢(ℝ, ℂ)) (t : ℝ) :
    ∫ ξ : ℝ, Complex.exp (↑(2 * Real.pi * (-(ξ * t))) * Complex.I) * (φ ξ - φ (-ξ)) =
      (𝓕 φ : 𝓢(ℝ, ℂ)) t - (𝓕 φ : 𝓢(ℝ, ℂ)) (-t) := by
  rw [schwartz_fourier_apply_eq, schwartz_fourier_apply_eq]
  simp_rw [mul_sub]
  rw [integral_sub (integrable_cexp_ofReal_mul_I_mul φ.integrable (by fun_prop))
    (integrable_cexp_ofReal_mul_I_mul φ.integrable.comp_neg (by fun_prop))]
  congr 1
  rw [← integral_neg_eq_self]
  congr 1
  ext ξ
  simp only [neg_mul, neg_neg, mul_neg]

#print axioms schwartz_fourier_sub_neg

theorem interval_kernel_eq (ξ R : ℝ) :
    (ξ : ℂ) * ∫ t in (0 : ℝ)..R, (Complex.exp (↑(2 * Real.pi * (-(ξ * t))) * Complex.I) -
        Complex.exp (↑(2 * Real.pi * (ξ * t)) * Complex.I)) =
      (2 - Complex.exp (↑(2 * Real.pi * (-(ξ * R))) * Complex.I) -
        Complex.exp (↑(2 * Real.pi * (ξ * R)) * Complex.I)) / (2 * Real.pi * Complex.I) := by
  have hpi : (2 * Real.pi * Complex.I : ℂ) ≠ 0 := by
    simp [Real.pi_ne_zero, Complex.I_ne_zero]
  have hd : ∀ (c t : ℝ), HasDerivAt (fun t : ℝ => Complex.exp (↑(2 * Real.pi * (c * t)) * Complex.I))
      (Complex.exp (↑(2 * Real.pi * (c * t)) * Complex.I) * (2 * Real.pi * c * Complex.I)) t := by
    intro c t
    have h1 : HasDerivAt (fun t : ℝ => (↑(2 * Real.pi * (c * t)) * Complex.I : ℂ))
        (2 * Real.pi * c * Complex.I) t := by
      have := (((hasDerivAt_id t).const_mul (2 * Real.pi * c)).ofReal_comp).mul_const Complex.I
      convert this using 1
      · ext s; simp only [id]; push_cast; ring
      · push_cast; ring
    exact h1.cexp
  rw [← intervalIntegral.integral_const_mul]
  have hG : ∀ t : ℝ, HasDerivAt
      (fun t : ℝ => -(Complex.exp (↑(2 * Real.pi * (-ξ * t)) * Complex.I) +
          Complex.exp (↑(2 * Real.pi * (ξ * t)) * Complex.I)) / (2 * Real.pi * Complex.I))
      ((ξ : ℂ) * (Complex.exp (↑(2 * Real.pi * (-(ξ * t))) * Complex.I) -
        Complex.exp (↑(2 * Real.pi * (ξ * t)) * Complex.I))) t := by
    intro t
    have := (((hd (-ξ) t).add (hd ξ t)).neg).div_const (2 * Real.pi * Complex.I)
    convert this using 1
    have e1 : (-ξ * t) = -(ξ * t) := by ring
    rw [e1]
    field_simp
    push_cast
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hG t)
    (by apply Continuous.intervalIntegrable; fun_prop)]
  have e2 : (-ξ * R) = -(ξ * R) := by ring
  simp only [e2, mul_zero, Complex.ofReal_zero, zero_mul, Complex.exp_zero]
  field_simp
  ring

#print axioms interval_kernel_eq

theorem schwartz_interval_odd_formula (φ : 𝓢(ℝ, ℂ)) (R : ℝ) (hR : 0 ≤ R) :
    ∫ t in (0:ℝ)..R, ((𝓕 φ : 𝓢(ℝ, ℂ)) t - (𝓕 φ : 𝓢(ℝ, ℂ)) (-t)) =
      (2 * (∫ ξ : ℝ, (φ ξ - φ (-ξ)) / (ξ : ℂ))
        - 𝓕 (fun ξ : ℝ => (φ ξ - φ (-ξ)) / (ξ : ℂ)) R
        - 𝓕 (fun ξ : ℝ => (φ ξ - φ (-ξ)) / (ξ : ℂ)) (-R)) / (4 * Real.pi * Complex.I) := by
  set g : ℝ → ℂ := fun ξ => (φ ξ - φ (-ξ)) / (ξ : ℂ) with hg
  have hgi : Integrable g := schwartz_oddQuot_integrable φ
  have hψi : Integrable (fun ξ : ℝ => φ ξ - φ (-ξ)) := φ.integrable.sub φ.integrable.comp_neg
  have hgψ : ∀ ξ : ℝ, (ξ : ℂ) * g ξ = φ ξ - φ (-ξ) := by
    intro ξ
    rcases eq_or_ne ξ 0 with h0 | h0
    · subst h0; simp
    · simp only [g]; field_simp [Complex.ofReal_ne_zero.mpr h0]
  set k : ℝ → ℝ → ℂ := fun t ξ => (Complex.exp (↑(2 * Real.pi * (-(ξ * t))) * Complex.I) -
        Complex.exp (↑(2 * Real.pi * (ξ * t)) * Complex.I)) * (φ ξ - φ (-ξ)) with hk
  have hpt : ∀ t : ℝ, (𝓕 φ : 𝓢(ℝ, ℂ)) t - (𝓕 φ : 𝓢(ℝ, ℂ)) (-t) = (1/2) * ∫ ξ, k t ξ := by
    intro t
    have h1 := schwartz_fourier_sub_neg φ t
    have h2 := schwartz_fourier_sub_neg φ (-t)
    simp only [neg_neg, mul_neg] at h2
    simp only [k, sub_mul]
    rw [integral_sub (integrable_cexp_ofReal_mul_I_mul hψi (by fun_prop))
      (integrable_cexp_ofReal_mul_I_mul hψi (by fun_prop))]
    rw [h1, h2]
    ring
  simp_rw [hpt]
  rw [intervalIntegral.integral_const_mul]
  have hint : Integrable (Function.uncurry k) ((volume.restrict (Set.Ioc 0 R)).prod volume) := by
    refine Integrable.mono' ((integrable_const (2:ℝ)).mul_prod hψi.norm) ?_ ?_
    · apply Continuous.aestronglyMeasurable
      have := φ.continuous
      simp only [k]
      fun_prop
    · refine Eventually.of_forall fun p => ?_
      simp only [Function.uncurry, k]
      rw [norm_mul]
      gcongr
      calc _ ≤ _ := norm_sub_le _ _
        _ = 2 := by rw [Complex.norm_exp_ofReal_mul_I, Complex.norm_exp_ofReal_mul_I]; norm_num
  rw [intervalIntegral.integral_of_le hR, integral_integral_swap hint]
  have hin : ∀ ξ : ℝ, ∫ t in Set.Ioc 0 R, k t ξ =
      g ξ * ((2 - Complex.exp (↑(2 * Real.pi * (-(ξ * R))) * Complex.I) -
        Complex.exp (↑(2 * Real.pi * (ξ * R)) * Complex.I)) / (2 * Real.pi * Complex.I)) := by
    intro ξ
    rw [← intervalIntegral.integral_of_le hR]
    simp only [k]
    rw [intervalIntegral.integral_mul_const, ← hgψ, ← interval_kernel_eq]
    ring
  simp_rw [hin]
  have hF1 : 𝓕 g R = ∫ ξ : ℝ, Complex.exp (↑(2 * Real.pi * (-(ξ * R))) * Complex.I) * g ξ := by
    rw [Real.fourier_real_eq]
    simp_rw [Circle.smul_def, Real.fourierChar_apply, smul_eq_mul]
  have hF2 : 𝓕 g (-R) = ∫ ξ : ℝ, Complex.exp (↑(2 * Real.pi * (ξ * R)) * Complex.I) * g ξ := by
    rw [Real.fourier_real_eq]
    simp_rw [Circle.smul_def, Real.fourierChar_apply, smul_eq_mul, mul_neg, neg_neg]
  rw [hF1, hF2]
  have hre : ∀ ξ : ℝ, g ξ * ((2 - Complex.exp (↑(2 * Real.pi * (-(ξ * R))) * Complex.I) -
        Complex.exp (↑(2 * Real.pi * (ξ * R)) * Complex.I)) / (2 * Real.pi * Complex.I)) =
      (2 * g ξ - Complex.exp (↑(2 * Real.pi * (-(ξ * R))) * Complex.I) * g ξ -
        Complex.exp (↑(2 * Real.pi * (ξ * R)) * Complex.I) * g ξ) / (2 * Real.pi * Complex.I) := by
    intro ξ; ring
  simp_rw [hre]
  rw [integral_div, integral_sub, integral_sub, integral_const_mul]
  · ring
  · exact hgi.const_mul 2
  · exact integrable_cexp_ofReal_mul_I_mul hgi (by fun_prop)
  · exact (hgi.const_mul 2).sub (integrable_cexp_ofReal_mul_I_mul hgi (by fun_prop))
  · exact integrable_cexp_ofReal_mul_I_mul hgi (by fun_prop)

#print axioms schwartz_interval_odd_formula

theorem schwartz_fourier_Ioi_sub_Iio (φ : 𝓢(ℝ, ℂ)) :
    (∫ t in Set.Ioi (0:ℝ), (𝓕 φ : 𝓢(ℝ, ℂ)) t) - (∫ t in Set.Iio (0:ℝ), (𝓕 φ : 𝓢(ℝ, ℂ)) t) =
      (∫ ξ : ℝ, (φ ξ - φ (-ξ)) / (ξ : ℂ)) / (2 * Real.pi * Complex.I) := by
  have hFi : Integrable (fun t => (𝓕 φ : 𝓢(ℝ, ℂ)) t) := (𝓕 φ).integrable
  set g : ℝ → ℂ := fun ξ => (φ ξ - φ (-ξ)) / (ξ : ℂ) with hg
  have hIio : ∫ t in Set.Iio (0:ℝ), (𝓕 φ : 𝓢(ℝ, ℂ)) t =
      ∫ t in Set.Ioi (0:ℝ), (𝓕 φ : 𝓢(ℝ, ℂ)) (-t) := by
    rw [integral_comp_neg_Ioi, neg_zero, integral_Iic_eq_integral_Iio]
  rw [hIio, ← integral_sub hFi.integrableOn hFi.comp_neg.integrableOn]
  have hT1 := intervalIntegral_tendsto_integral_Ioi 0 (hFi.sub hFi.comp_neg).integrableOn
    tendsto_id
  have hT2 : Tendsto (fun R : ℝ => (2 * (∫ ξ, g ξ) - 𝓕 g R - 𝓕 g (-R)) /
      (4 * Real.pi * Complex.I)) atTop
      (𝓝 ((2 * (∫ ξ, g ξ) - 0 - 0) / (4 * Real.pi * Complex.I))) := by
    have hRL := Real.zero_at_infty_fourier g
    have h1 : Tendsto (fun R : ℝ => 𝓕 g R) atTop (𝓝 0) :=
      hRL.mono_left (by rw [cocompact_eq_atBot_atTop]; exact le_sup_right)
    have h2 : Tendsto (fun R : ℝ => 𝓕 g (-R)) atTop (𝓝 0) :=
      (hRL.mono_left (by rw [cocompact_eq_atBot_atTop]; exact le_sup_left)).comp
        tendsto_neg_atTop_atBot
    exact ((tendsto_const_nhds.sub h1).sub h2).div_const _
  have heq : (fun R : ℝ => ∫ t in (0:ℝ)..id R,
      ((𝓕 φ : 𝓢(ℝ, ℂ)) t - (𝓕 φ : 𝓢(ℝ, ℂ)) (-t))) =ᶠ[atTop]
      fun R : ℝ => (2 * (∫ ξ, g ξ) - 𝓕 g R - 𝓕 g (-R)) / (4 * Real.pi * Complex.I) := by
    filter_upwards [eventually_ge_atTop 0] with R hR
    exact schwartz_interval_odd_formula φ R hR
  have := tendsto_nhds_unique (hT1.congr' heq) hT2
  simp only [Pi.sub_apply] at this
  rw [this]
  ring

#print axioms schwartz_fourier_Ioi_sub_Iio

theorem schwartz_integral_fourier (φ : 𝓢(ℝ, ℂ)) :
    (∫ t in Set.Ioi (0:ℝ), (𝓕 φ : 𝓢(ℝ, ℂ)) t) + (∫ t in Set.Iio (0:ℝ), (𝓕 φ : 𝓢(ℝ, ℂ)) t) =
      φ 0 := by
  have hFi : Integrable (fun t => (𝓕 φ : 𝓢(ℝ, ℂ)) t) := (𝓕 φ).integrable
  rw [add_comm, ← integral_Iic_eq_integral_Iio, intervalIntegral.integral_Iic_add_Ioi
    hFi.integrableOn hFi.integrableOn]
  have h := congrArg (fun f : 𝓢(ℝ, ℂ) => f 0) (fourierInv_fourier_eq (E := 𝓢(ℝ, ℂ)) (F := 𝓢(ℝ, ℂ)) φ)
  rw [← h, SchwartzMap.fourierInv_coe, Real.fourierInv_eq]
  simp

#print axioms schwartz_integral_fourier

theorem schwartz_pv_tendsto (φ : 𝓢(ℝ, ℂ)) :
    Tendsto (fun η : ℝ => ∫ ξ in {ξ : ℝ | η < |ξ|}, φ ξ / ((Real.pi : ℂ) * Complex.I * ξ))
      (𝓝[>] 0) (𝓝 ((∫ ξ : ℝ, (φ ξ - φ (-ξ)) / (ξ : ℂ)) / (2 * Real.pi * Complex.I))) := by
  set g : ℝ → ℂ := fun ξ => (φ ξ - φ (-ξ)) / (ξ : ℂ) with hg
  have hgi : Integrable g := schwartz_oddQuot_integrable φ
  have hS : ∀ η : ℝ, MeasurableSet {ξ : ℝ | η < |ξ|} := fun η =>
    measurableSet_lt measurable_const continuous_abs.measurable
  have key : ∀ η : ℝ, 0 < η →
      ∫ ξ in {ξ : ℝ | η < |ξ|}, φ ξ / ((Real.pi : ℂ) * Complex.I * ξ) =
        (∫ ξ, {ξ : ℝ | η < |ξ|}.indicator g ξ) / (2 * Real.pi * Complex.I) := by
    intro η hη
    set S := {ξ : ℝ | η < |ξ|} with hSdef
    set f : ℝ → ℂ := fun ξ => S.indicator (fun ξ => φ ξ / ((Real.pi : ℂ) * Complex.I * ξ)) ξ
      with hfdef
    have hf : Integrable f := by
      refine Integrable.mono' ((φ.integrable.norm).div_const (Real.pi * η)) ?_ ?_
      · exact (Measurable.indicator (φ.continuous.measurable.div (by fun_prop))
          (hS η)).aestronglyMeasurable
      · refine Eventually.of_forall fun ξ => ?_
        by_cases hξ : ξ ∈ S
        · simp only [f, Set.indicator_of_mem hξ]
          have h1 : η < |ξ| := hξ
          rw [norm_div, norm_mul, norm_mul, Complex.norm_real, Complex.norm_I, Complex.norm_real,
            Real.norm_eq_abs, Real.norm_eq_abs, abs_of_pos Real.pi_pos, mul_one]
          apply div_le_div_of_nonneg_left (norm_nonneg _) (by positivity)
          nlinarith [Real.pi_pos]
        · simp only [f, Set.indicator_of_notMem hξ, norm_zero]; positivity
    have hneg : ∫ ξ, f ξ = ∫ ξ, f (-ξ) := (integral_neg_eq_self f volume).symm
    have hsum : ∀ ξ, f ξ + f (-ξ) = S.indicator g ξ / (Real.pi * Complex.I) := by
      intro ξ
      by_cases hξ : ξ ∈ S
      · have hξ' : -ξ ∈ S := by simpa [S] using hξ
        simp only [f, Set.indicator_of_mem hξ, Set.indicator_of_mem hξ', g]
        have h1 : η < |ξ| := hξ
        have hx : (ξ : ℂ) ≠ 0 := by
          rw [Complex.ofReal_ne_zero]; rintro rfl; simp at h1; linarith
        have hpi : (Real.pi : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr Real.pi_ne_zero
        push_cast
        field_simp
        ring
      · have hξ' : -ξ ∉ S := by simpa [S] using hξ
        simp [f, Set.indicator_of_notMem hξ, Set.indicator_of_notMem hξ']
    have h2 : 2 * ∫ ξ, f ξ = (∫ ξ, S.indicator g ξ) / (Real.pi * Complex.I) := by
      rw [two_mul]
      nth_rewrite 2 [hneg]
      rw [← integral_add hf hf.comp_neg]
      simp_rw [hsum]
      rw [integral_div]
    rw [← integral_indicator (hS η)]
    change ∫ ξ, f ξ = _
    have h2' : (2 : ℂ) ≠ 0 := two_ne_zero
    rw [mul_comm] at h2
    rw [eq_div_iff (by simp [Real.pi_ne_zero, Complex.I_ne_zero])]
    rw [show (∫ ξ, f ξ) * (2 * (Real.pi : ℂ) * Complex.I) = ((∫ ξ, f ξ) * 2) * (Real.pi * Complex.I)
      by ring, h2]
    field_simp [Real.pi_ne_zero, Complex.I_ne_zero]
  have hlim : Tendsto (fun η : ℝ => ∫ ξ, {ξ : ℝ | η < |ξ|}.indicator g ξ) (𝓝[>] 0)
      (𝓝 (∫ ξ, g ξ)) := by
    refine tendsto_integral_filter_of_dominated_convergence (fun ξ => ‖g ξ‖) ?_ ?_ hgi.norm ?_
    · exact Eventually.of_forall fun η => (hgi.aestronglyMeasurable.indicator (hS η))
    · exact Eventually.of_forall fun η => Eventually.of_forall fun ξ =>
        norm_indicator_le_norm_self _ _
    · refine Eventually.of_forall fun ξ => ?_
      rcases eq_or_ne ξ 0 with h0 | h0
      · have : ∀ η, {ξ : ℝ | η < |ξ|}.indicator g 0 = g 0 := by
          intro η; simp [g, Set.indicator]
        subst h0; simp only [this]; exact tendsto_const_nhds
      · apply tendsto_const_nhds.congr'
        filter_upwards [Ioo_mem_nhdsGT (abs_pos.mpr h0)] with η hη
        rw [Set.indicator_of_mem (show η < |ξ| from hη.2)]
  refine (hlim.div_const (2 * Real.pi * Complex.I)).congr' ?_
  filter_upwards [self_mem_nhdsWithin] with η hη
  exact (key η hη).symm

#print axioms schwartz_pv_tendsto

/-- The sign function (−1 before time 0, +1 after) is a tempered distribution, and its
Fourier transform is the principal value of `1/(πiξ)`: for every Schwartz probe `φ`, the
reading `ŝgn(φ) = sgn(φ̂)` equals the limit, as the balanced gap `(−η, η)` around 0 shrinks,
of `∫_{|ξ|>η} φ(ξ)/(πiξ) dξ`. -/
theorem fourier_sign_eq_pv_one_div_pi_I_xi :
    ∃ u : 𝓢'(ℝ, ℂ), (∀ ψ : 𝓢(ℝ, ℂ), u ψ = ∫ t : ℝ, (Real.sign t : ℂ) * ψ t) ∧
      ∀ φ : 𝓢(ℝ, ℂ),
        Tendsto
          (fun η : ℝ => ∫ ξ in {ξ : ℝ | η < |ξ|}, φ ξ / ((Real.pi : ℂ) * Complex.I * ξ))
          (𝓝[>] 0) (𝓝 (𝓕 u φ)) := by
  have : (volume.restrict (Set.Ioi (0:ℝ))).HasTemperateGrowth :=
    ⟨⟨_, (Measure.integrable_pow_neg_integrablePower (volume : Measure ℝ)).restrict⟩⟩
  have : (volume.restrict (Set.Iio (0:ℝ))).HasTemperateGrowth :=
    ⟨⟨_, (Measure.integrable_pow_neg_integrablePower (volume : Measure ℝ)).restrict⟩⟩
  have hval : ∀ ψ : 𝓢(ℝ, ℂ), ((volume.restrict (Set.Ioi (0:ℝ))).toTemperedDistribution -
      (volume.restrict (Set.Iio (0:ℝ))).toTemperedDistribution) ψ =
        (∫ t in Set.Ioi (0:ℝ), ψ t) - ∫ t in Set.Iio (0:ℝ), ψ t := by
    intro ψ
    simp
  refine ⟨(volume.restrict (Set.Ioi (0:ℝ))).toTemperedDistribution -
    (volume.restrict (Set.Iio (0:ℝ))).toTemperedDistribution, fun ψ => ?_, fun φ => ?_⟩
  · rw [hval, ← integral_indicator measurableSet_Ioi, ← integral_indicator measurableSet_Iio,
      ← integral_sub (ψ.integrable.indicator measurableSet_Ioi)
        (ψ.integrable.indicator measurableSet_Iio)]
    congr 1
    ext t
    rcases lt_trichotomy t 0 with h | h | h
    · simp [Real.sign_of_neg h, Set.indicator, h, not_lt.mpr h.le]
    · subst h; simp
    · simp [Real.sign_of_pos h, Set.indicator, h, not_lt.mpr h.le]
  · rw [TemperedDistribution.fourier_apply, hval, schwartz_fourier_Ioi_sub_Iio]
    exact schwartz_pv_tendsto φ

/-- Schwartz space is closed under the Fourier transform: for every Schwartz probe `φ`
on the line, its transform `ξ ↦ ∫ e^(−2πiξt) φ(t) dt` (hertz convention) is again a
Schwartz probe. -/
theorem fourier_maps_schwartz_to_schwartz (φ : 𝓢(ℝ, ℂ)) :
    ∃ ψ : 𝓢(ℝ, ℂ), ∀ ξ : ℝ,
      ψ ξ = ∫ t : ℝ, Complex.exp (-(2 * (Real.pi : ℂ) * ξ * t) * Complex.I) * φ t := by
  refine ⟨𝓕 φ, fun ξ => ?_⟩
  rw [schwartz_fourier_apply_eq]
  congr 1
  ext t
  congr 2
  push_cast
  ring

/-- The step `H` (0 before time 0, 1 after) is a tempered distribution, and its Fourier
transform is half a spike at 0 plus the principal value of `1/(2πiξ)`:
`Ĥ(φ) = φ(0)/2 + lim_{η→0} ∫_{|ξ|>η} φ(ξ)/(2πiξ) dξ` for every Schwartz probe `φ`. -/
theorem fourier_step_eq_half_delta_add_pv :
    ∃ u : 𝓢'(ℝ, ℂ), (∀ ψ : 𝓢(ℝ, ℂ), u ψ = ∫ t in Set.Ioi (0 : ℝ), ψ t) ∧
      ∀ φ : 𝓢(ℝ, ℂ),
        Tendsto
          (fun η : ℝ => φ 0 / 2 +
            ∫ ξ in {ξ : ℝ | η < |ξ|}, φ ξ / (2 * (Real.pi : ℂ) * Complex.I * ξ))
          (𝓝[>] 0) (𝓝 (𝓕 u φ)) := by
  have : (volume.restrict (Set.Ioi (0:ℝ))).HasTemperateGrowth :=
    ⟨⟨_, (Measure.integrable_pow_neg_integrablePower (volume : Measure ℝ)).restrict⟩⟩
  refine ⟨(volume.restrict (Set.Ioi (0:ℝ))).toTemperedDistribution, fun ψ => by simp,
    fun φ => ?_⟩
  have hval : ∀ ψ : 𝓢(ℝ, ℂ), (volume.restrict (Set.Ioi (0:ℝ))).toTemperedDistribution ψ =
      ∫ t in Set.Ioi (0:ℝ), ψ t := fun ψ => by simp
  rw [TemperedDistribution.fourier_apply, hval]
  have h1 := schwartz_fourier_Ioi_sub_Iio φ
  have h2 := schwartz_integral_fourier φ
  have hA : ∫ t in Set.Ioi (0:ℝ), (𝓕 φ : 𝓢(ℝ, ℂ)) t =
      φ 0 / 2 + (1 / 2) * ((∫ ξ : ℝ, (φ ξ - φ (-ξ)) / (ξ : ℂ)) / (2 * Real.pi * Complex.I)) := by
    rw [← h1, ← h2]
    ring
  rw [hA]
  have hfun : (fun η : ℝ => φ 0 / 2 +
      ∫ ξ in {ξ : ℝ | η < |ξ|}, φ ξ / (2 * (Real.pi : ℂ) * Complex.I * ξ)) =
      fun η : ℝ => φ 0 / 2 + (1 / 2) *
        ∫ ξ in {ξ : ℝ | η < |ξ|}, φ ξ / ((Real.pi : ℂ) * Complex.I * ξ) := by
    ext η
    rw [← integral_const_mul]
    congr 2
    ext ξ
    ring
  rw [hfun]
  exact ((schwartz_pv_tendsto φ).const_mul (1 / 2)).const_add (φ 0 / 2)

/-- The card's 2 ms shutter at 250 Hz: its two spikes give `e^(πiξT) − e^(−πiξT) = 2i·sin(πξT)`,
and at `ξ = 1/4`, `T = 2` the factor `2·sin(πξT)` is exactly 2, since `sin(π/2) = 1`. -/
example : 2 * Real.sin (Real.pi * (1 / 4) * 2) = 2 := by
  norm_num [show Real.pi * (1 / 4) * 2 = Real.pi / 2 by ring]

#print axioms fourier_sign_eq_pv_one_div_pi_I_xi
#print axioms fourier_maps_schwartz_to_schwartz
#print axioms fourier_step_eq_half_delta_add_pv
