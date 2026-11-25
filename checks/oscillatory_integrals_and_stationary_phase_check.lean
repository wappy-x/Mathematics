-- Stationary phase: van der Corput's first- and second-derivative bounds for the integral of a fast wave, and the uniform bound on the Bessel integral J0 they give.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.ContDiff.Deriv

open Real Complex
open scoped ContDiff

theorem vdc_sign_helper {f : ℝ → ℝ} {a b c : ℝ} (hc : 0 < c) (hf : ContinuousOn f (Set.Icc a b))
    (h : ∀ x ∈ Set.Icc a b, c ≤ |f x|) :
    (∀ x ∈ Set.Icc a b, c ≤ f x) ∨ (∀ x ∈ Set.Icc a b, f x ≤ -c) := by
  by_contra hne
  push Not at hne
  obtain ⟨⟨x, hx, hfx⟩, ⟨y, hy, hfy⟩⟩ := hne
  have hx' : f x ≤ -c := by
    rcases le_abs'.mp (h x hx) with h1 | h1 <;> linarith
  have hy' : c ≤ f y := by
    rcases le_abs'.mp (h y hy) with h1 | h1 <;> linarith
  have h0 : (0 : ℝ) ∈ Set.Icc (f x) (f y) := ⟨by linarith, by linarith⟩
  obtain ⟨z, hz, hfz⟩ := isPreconnected_Icc.intermediate_value hx hy hf h0
  have := h z hz
  rw [hfz, abs_zero] at this
  linarith

theorem vdc_level_helper {f : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b) (hf : ContinuousOn f (Set.Icc a b))
    (c : ℝ) : ∃ p ∈ Set.Icc a b, (p = a ∨ f p ≤ c) ∧ (p = b ∨ c ≤ f p) := by
  by_cases h1 : c ≤ f a
  · exact ⟨a, Set.left_mem_Icc.2 hab, Or.inl rfl, Or.inr h1⟩
  by_cases h2 : f b ≤ c
  · exact ⟨b, Set.right_mem_Icc.2 hab, Or.inr h2, Or.inl rfl⟩
  push Not at h1 h2
  obtain ⟨p, hp, hfp⟩ := intermediate_value_Icc hab hf ⟨h1.le, h2.le⟩
  exact ⟨p, hp, Or.inr hfp.le, Or.inr hfp.ge⟩

theorem vdc_norm_neg_helper (φ : ℝ → ℝ) (a b lam : ℝ) (hab : a ≤ b) :
    ‖∫ x in a..b, Complex.exp (Complex.I * ((lam * -φ x : ℝ) : ℂ))‖ =
      ‖∫ x in a..b, Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ))‖ := by
  have h : ∀ x, Complex.exp (Complex.I * ((lam * -φ x : ℝ) : ℂ)) =
      (starRingEnd ℂ) (Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ))) := by
    intro x
    rw [← Complex.exp_conj]
    congr 1
    simp [map_mul, Complex.conj_ofReal, Complex.conj_I]
  simp_rw [h]
  rw [intervalIntegral.integral_of_le hab, intervalIntegral.integral_of_le hab, integral_conj,
    Complex.norm_conj]

theorem vdc_deriv_nonneg_helper {f : ℝ → ℝ} {a b : ℝ} (hab : a < b)
    (hmono : MonotoneOn f (Set.Icc a b)) (hfd : Differentiable ℝ f) :
    ∀ x ∈ Set.Icc a b, 0 ≤ deriv f x := by
  intro x hx
  rw [← (hfd x).derivWithin (uniqueDiffOn_Icc hab x hx)]
  exact hmono.derivWithin_nonneg

theorem vdc1_mono_helper (φ : ℝ → ℝ) (a b lam δ : ℝ) (hab : a ≤ b)
    (hφ : ContDiff ℝ ∞ φ) (hmono : MonotoneOn (deriv φ) (Set.Icc a b))
    (hspeed : ∀ x ∈ Set.Icc a b, δ ≤ |deriv φ x|) (hδ : 0 < δ) (hlam : 0 < lam) :
    ‖∫ x in a..b, Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ))‖ ≤ 3 / (lam * δ) := by
  rcases hab.eq_or_lt with rfl | hab'
  · simp only [intervalIntegral.integral_same, norm_zero]; positivity
  have hφd : Differentiable ℝ φ := (contDiff_infty_iff_deriv.mp hφ).1
  have hf : ContDiff ℝ ∞ (deriv φ) := (contDiff_infty_iff_deriv.mp hφ).2
  set f := deriv φ with hfdef
  have hfd : Differentiable ℝ f := (contDiff_infty_iff_deriv.mp hf).1
  have hf'c : Continuous (deriv f) := (contDiff_infty_iff_deriv.mp hf).2.continuous
  have hsign := vdc_sign_helper hδ hfd.continuous.continuousOn hspeed
  have hne : ∀ x ∈ Set.Icc a b, f x ≠ 0 := fun x hx h => by
    have := hspeed x hx; rw [h, abs_zero] at this; linarith
  have hf'nn := vdc_deriv_nonneg_helper hab' hmono hfd
  set g : ℝ → ℝ := fun x => (f x)⁻¹ with hgdef
  set g' : ℝ → ℝ := fun x => -(deriv f x) / (f x) ^ 2 with hg'def
  have hg : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x := fun x hx =>
    (hfd x).hasDerivAt.inv (hne x hx)
  have hg'np : ∀ x ∈ Set.Icc a b, g' x ≤ 0 := by
    intro x hx
    simp only [g']
    exact div_nonpos_of_nonpos_of_nonneg (neg_nonpos.mpr (hf'nn x hx)) (sq_nonneg _)
  have hg'c : ContinuousOn g' (Set.Icc a b) :=
    (hf'c.continuousOn.neg).div (hfd.continuous.pow 2).continuousOn
      (fun x hx => pow_ne_zero 2 (hne x hx))
  have hgb : ∀ x ∈ Set.Icc a b, |g x| ≤ 1 / δ := by
    intro x hx
    simp only [g, abs_inv, one_div]
    exact inv_anti₀ hδ (hspeed x hx)
  have ha : a ∈ Set.Icc a b := Set.left_mem_Icc.2 hab
  have hb : b ∈ Set.Icc a b := Set.right_mem_Icc.2 hab
  have hgab : g a - g b ≤ 1 / δ := by
    have h1 := abs_le.mp (hgb a ha)
    have h2 := abs_le.mp (hgb b hb)
    rcases hsign with h | h
    · have : 0 < g b := inv_pos.mpr (lt_of_lt_of_le hδ (h b hb))
      linarith
    · have : g a < 0 := inv_lt_zero.mpr (by linarith [h a ha])
      linarith
  set K : ℂ := (Complex.I * (lam : ℂ))⁻¹ with hK
  set u : ℝ → ℂ := fun x => (g x : ℂ) * K with hu
  set u' : ℝ → ℂ := fun x => (g' x : ℂ) * K with hu'
  set v : ℝ → ℂ := fun x => Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ)) with hv
  set v' : ℝ → ℂ := fun x => v x * (Complex.I * ((lam * f x : ℝ) : ℂ)) with hv'
  have huD : ∀ x ∈ Set.uIcc a b, HasDerivAt u (u' x) x := by
    intro x hx
    rw [Set.uIcc_of_le hab] at hx
    exact ((hg x hx).ofReal_comp).mul_const K
  have hvD : ∀ x, HasDerivAt v (v' x) x := by
    intro x
    have h1 : HasDerivAt (fun y => lam * φ y) (lam * f x) x := (hφd x).hasDerivAt.const_mul lam
    exact ((h1.ofReal_comp).const_mul Complex.I).cexp
  have hlam0 : (lam : ℂ) ≠ 0 := by exact_mod_cast hlam.ne'
  have key : ∀ x ∈ Set.uIcc a b, Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ)) = u x * v' x := by
    intro x hx
    rw [Set.uIcc_of_le hab] at hx
    have hfx : (f x : ℂ) ≠ 0 := by exact_mod_cast hne x hx
    simp only [u, v', v, K, g]
    push_cast
    field_simp
  have hu'i : IntervalIntegrable u' MeasureTheory.volume a b := by
    apply ContinuousOn.intervalIntegrable
    rw [Set.uIcc_of_le hab]
    exact (Complex.continuous_ofReal.comp_continuousOn hg'c).mul continuousOn_const
  have hvc : Continuous v := continuous_iff_continuousAt.mpr fun x => (hvD x).continuousAt
  have hv'c : Continuous v' := by
    simp only [v']
    have : Continuous fun x => ((lam * f x : ℝ) : ℂ) :=
      Complex.continuous_ofReal.comp (continuous_const.mul hfd.continuous)
    exact hvc.mul (continuous_const.mul this)
  rw [intervalIntegral.integral_congr key,
    intervalIntegral.integral_mul_deriv_eq_deriv_mul huD (fun x _ => hvD x) hu'i
      (hv'c.intervalIntegrable a b)]
  have hvn : ∀ x, ‖v x‖ = 1 := fun x => by
    simp only [v]; exact Complex.norm_exp_I_mul_ofReal _
  have hKn : ‖K‖ = 1 / lam := by
    simp [K, abs_of_pos hlam]
  have hun : ∀ x, ‖u x * v x‖ = |g x| / lam := by
    intro x; rw [norm_mul, hvn, mul_one]; simp only [u]
    rw [norm_mul, hKn, Complex.norm_real, Real.norm_eq_abs]; ring
  have hint : ‖∫ x in a..b, u' x * v x‖ ≤ ∫ x in a..b, -g' x / lam := by
    apply intervalIntegral.norm_integral_le_of_norm_le hab
    · refine MeasureTheory.ae_of_all _ (fun x hx => ?_)
      have hx' : x ∈ Set.Icc a b := Set.Ioc_subset_Icc_self hx
      rw [norm_mul, hvn, mul_one]; simp only [u']
      rw [norm_mul, hKn, Complex.norm_real, Real.norm_eq_abs, abs_of_nonpos (hg'np x hx')]
      ring_nf; rfl
    · apply ContinuousOn.intervalIntegrable
      rw [Set.uIcc_of_le hab]
      exact hg'c.neg.div_const lam
  have hFTC : ∫ x in a..b, -g' x / lam = g a / lam - g b / lam := by
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun x => -g x / lam)]
    · ring
    · intro x hx
      rw [Set.uIcc_of_le hab] at hx
      exact (hg x hx).neg.div_const lam
    · apply ContinuousOn.intervalIntegrable
      rw [Set.uIcc_of_le hab]
      exact hg'c.neg.div_const lam
  calc ‖u b * v b - u a * v a - ∫ x in a..b, u' x * v x‖
      ≤ ‖u b * v b‖ + ‖u a * v a‖ + ‖∫ x in a..b, u' x * v x‖ :=
        (norm_sub_le _ _).trans (add_le_add_left (norm_sub_le _ _) _)
    _ ≤ |g b| / lam + |g a| / lam + (g a / lam - g b / lam) := by
        rw [hun, hun, ← hFTC]; linarith
    _ = (|g b| + |g a| + (g a - g b)) / lam := by ring
    _ ≤ (1 / δ + 1 / δ + 1 / δ) / lam := by
        gcongr
        · exact hgb b hb
        · exact hgb a ha
    _ = 3 / (lam * δ) := by field_simp; ring

theorem vdc1_gen_helper (φ : ℝ → ℝ) (a b lam δ : ℝ) (hab : a ≤ b)
    (hφ : ContDiff ℝ ∞ φ)
    (hmono : MonotoneOn (deriv φ) (Set.Icc a b) ∨ AntitoneOn (deriv φ) (Set.Icc a b))
    (hspeed : ∀ x ∈ Set.Icc a b, δ ≤ |deriv φ x|) (hδ : 0 < δ) (hlam : 0 < lam) :
    ‖∫ x in a..b, Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ))‖ ≤ 3 / (lam * δ) := by
  rcases hmono with h | h
  · exact vdc1_mono_helper φ a b lam δ hab hφ h hspeed hδ hlam
  · have hd : deriv (fun x => -φ x) = fun x => -deriv φ x := by
      funext x; exact deriv.fun_neg
    have := vdc1_mono_helper (fun x => -φ x) a b lam δ hab hφ.neg
      (by rw [hd]; exact h.neg) (by rw [hd]; simpa only [abs_neg] using hspeed) hδ hlam
    rwa [vdc_norm_neg_helper φ a b lam hab] at this

theorem vdc2_pos_helper (φ : ℝ → ℝ) (a b lam δ : ℝ) (hab : a ≤ b)
    (hφ : ContDiff ℝ ∞ φ)
    (hcurve : ∀ x ∈ Set.Icc a b, 1 ≤ deriv (deriv φ) x) (hlam : 0 < lam) (hδ : 0 < δ) :
    ‖∫ x in a..b, Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ))‖ ≤
      3 / (lam * δ) + 2 * δ + 3 / (lam * δ) := by
  have hf : ContDiff ℝ ∞ (deriv φ) := (contDiff_infty_iff_deriv.mp hφ).2
  set f := deriv φ with hfdef
  have hfd : Differentiable ℝ f := (contDiff_infty_iff_deriv.mp hf).1
  have hlin : ∀ x ∈ Set.Icc a b, ∀ y ∈ Set.Icc a b, x ≤ y → y - x ≤ f y - f x := by
    have hm : MonotoneOn (fun x => f x - x) (Set.Icc a b) := by
      apply monotoneOn_of_deriv_nonneg (convex_Icc a b)
      · exact (hfd.continuous.sub continuous_id).continuousOn
      · exact (hfd.sub differentiable_id).differentiableOn
      · intro x hx
        rw [interior_Icc] at hx
        have : deriv (fun x => f x - x) x = deriv f x - 1 := by
          exact ((hfd x).hasDerivAt.sub (hasDerivAt_id x)).deriv
        rw [this]
        linarith [hcurve x (Set.Ioo_subset_Icc_self hx)]
    intro x hx y hy hxy
    have := hm hx hy hxy
    simp only at this
    linarith
  have hmono : MonotoneOn f (Set.Icc a b) := fun x hx y hy hxy => by
    linarith [hlin x hx y hy hxy]
  obtain ⟨p, hp, hp1, hp2⟩ := vdc_level_helper hab hfd.continuous.continuousOn (-δ)
  obtain ⟨q, hq, hq1, hq2⟩ := vdc_level_helper hab hfd.continuous.continuousOn δ
  set F : ℝ → ℂ := fun x => Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ)) with hF
  have hFc : Continuous F := by
    have : Continuous φ := hφ.continuous
    simp only [F]; fun_prop
  have hFi : ∀ s t : ℝ, IntervalIntegrable F MeasureTheory.volume s t :=
    fun s t => hFc.intervalIntegrable s t
  have hsplit : ∫ x in a..b, F x = (∫ x in a..p, F x) + (∫ x in p..q, F x) + ∫ x in q..b, F x := by
    rw [intervalIntegral.integral_add_adjacent_intervals (hFi a p) (hFi p q),
      intervalIntegral.integral_add_adjacent_intervals (hFi a q) (hFi q b)]
  have hA : ‖∫ x in a..p, F x‖ ≤ 3 / (lam * δ) := by
    rcases hp1 with rfl | hfp
    · simp only [intervalIntegral.integral_same, norm_zero]; positivity
    · apply vdc1_gen_helper φ a p lam δ hp.1 hφ
        (Or.inl (hmono.mono (Set.Icc_subset_Icc le_rfl hp.2))) _ hδ hlam
      intro x hx
      have hx' : x ∈ Set.Icc a b := ⟨hx.1, hx.2.trans hp.2⟩
      have := hmono hx' hp hx.2
      exact le_abs.mpr (Or.inr (by linarith))
  have hC : ‖∫ x in q..b, F x‖ ≤ 3 / (lam * δ) := by
    rcases hq2 with rfl | hfq
    · simp only [intervalIntegral.integral_same, norm_zero]; positivity
    · apply vdc1_gen_helper φ q b lam δ hq.2 hφ
        (Or.inl (hmono.mono (Set.Icc_subset_Icc hq.1 le_rfl))) _ hδ hlam
      intro x hx
      have hx' : x ∈ Set.Icc a b := ⟨hq.1.trans hx.1, hx.2⟩
      have := hmono hq hx' hx.1
      exact le_abs.mpr (Or.inl (by linarith))
  have hpq : |q - p| ≤ 2 * δ := by
    rcases le_or_gt p q with hle | hlt
    · rw [abs_of_nonneg (by linarith)]
      rcases hq1 with rfl | hfq
      · have : p = q := le_antisymm hle hp.1
        rw [this]; linarith
      rcases hp2 with rfl | hfp
      · have : q = p := le_antisymm hq.2 hle
        rw [this]; linarith
      linarith [hlin p hp q hq hle]
    · exfalso
      rcases hq2 with rfl | hfq
      · linarith [hp.2]
      rcases hp1 with rfl | hfp
      · linarith [hq.1]
      linarith [hmono hq hp hlt.le]
  have hB : ‖∫ x in p..q, F x‖ ≤ 2 * δ := by
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := p) (b := q) (C := 1) (f := F)
      (fun x _ => by simp only [F]; exact (Complex.norm_exp_I_mul_ofReal _).le)
    linarith
  rw [hsplit]
  calc ‖(∫ x in a..p, F x) + (∫ x in p..q, F x) + ∫ x in q..b, F x‖
      ≤ ‖∫ x in a..p, F x‖ + ‖∫ x in p..q, F x‖ + ‖∫ x in q..b, F x‖ := norm_add₃_le
    _ ≤ 3 / (lam * δ) + 2 * δ + 3 / (lam * δ) := by gcongr

#print axioms vdc_sign_helper
#print axioms vdc_level_helper
#print axioms vdc_norm_neg_helper
#print axioms vdc_deriv_nonneg_helper
#print axioms vdc1_mono_helper
#print axioms vdc1_gen_helper
#print axioms vdc2_pos_helper

/-- Van der Corput's first-derivative test: if the phase `φ` is smooth, its speed `φ'` is
monotone (only rises or only falls) on `[a, b]` and has size at least 1 there, then for every
`λ > 0` the integral of the wave `e^{iλφ(x)}` over `[a, b]` has size at most `3 / λ`. -/
theorem van_der_corput_first_derivative (φ : ℝ → ℝ) (a b lam : ℝ) (hab : a ≤ b)
    (hφ : ContDiff ℝ ∞ φ)
    (hmono : MonotoneOn (deriv φ) (Set.Icc a b) ∨ AntitoneOn (deriv φ) (Set.Icc a b))
    (hspeed : ∀ x ∈ Set.Icc a b, 1 ≤ |deriv φ x|) (hlam : 0 < lam) :
    ‖∫ x in a..b, Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ))‖ ≤ 3 / lam := by
  simpa using vdc1_gen_helper φ a b lam 1 hab hφ hmono hspeed one_pos hlam

/-- Van der Corput's second-derivative test: if the phase `φ` is smooth and its curvature `φ''`
has size at least 1 on `[a, b]`, then for every `λ > 0` the integral of the wave `e^{iλφ(x)}`
over `[a, b]` has size at most `8 / √λ`, whatever the length of the interval. -/
theorem van_der_corput_second_derivative (φ : ℝ → ℝ) (a b lam : ℝ) (hab : a ≤ b)
    (hφ : ContDiff ℝ ∞ φ)
    (hcurve : ∀ x ∈ Set.Icc a b, 1 ≤ |deriv (deriv φ) x|) (hlam : 0 < lam) :
    ‖∫ x in a..b, Complex.exp (Complex.I * ((lam * φ x : ℝ) : ℂ))‖ ≤ 8 / Real.sqrt lam := by
  have hs : 0 < Real.sqrt lam := Real.sqrt_pos.mpr hlam
  have hδ : 0 < 1 / Real.sqrt lam := by positivity
  have harith : 3 / (lam * (1 / Real.sqrt lam)) + 2 * (1 / Real.sqrt lam) +
      3 / (lam * (1 / Real.sqrt lam)) = 8 / Real.sqrt lam := by
    rw [mul_one_div, Real.div_sqrt]; ring
  have hf2 : ContDiff ℝ ∞ (deriv (deriv φ)) :=
    (contDiff_infty_iff_deriv.mp (contDiff_infty_iff_deriv.mp hφ).2).2
  rcases vdc_sign_helper one_pos hf2.continuous.continuousOn hcurve with h | h
  · rw [← harith]; exact vdc2_pos_helper φ a b lam _ hab hφ h hlam hδ
  · have hd : deriv (deriv (fun x => -φ x)) = fun x => -deriv (deriv φ) x := by
      have : deriv (fun x => -φ x) = fun x => -deriv φ x := by funext x; exact deriv.fun_neg
      rw [this]; funext x; exact deriv.fun_neg
    have := vdc2_pos_helper (fun x => -φ x) a b lam _ hab hφ.neg
      (by rw [hd]; intro x hx; linarith [h x hx]) hlam hδ
    rw [vdc_norm_neg_helper φ a b lam hab, harith] at this
    exact this

/-- The uniform bound on `J₀` from van der Corput: for every `r > 0`,
`|J₀(r)| = |(1/π) ∫₀^π cos(r sin θ) dθ| ≤ (1/π)(8√2/√r + 4√3/r)`. -/
theorem bessel_j0_uniform_bound (r : ℝ) (hr : 0 < r) :
    |(1 / π) * ∫ θ in (0 : ℝ)..π, Real.cos (r * Real.sin θ)| ≤
      (1 / π) * (8 * Real.sqrt 2 / Real.sqrt r + 4 * Real.sqrt 3 / r) := by
  set F : ℝ → ℂ := fun θ => Complex.exp (Complex.I * ((r * Real.sin θ : ℝ) : ℂ)) with hF
  have hFc : Continuous F := by simp only [F]; fun_prop
  have hFi : ∀ s t : ℝ, IntervalIntegrable F MeasureTheory.volume s t :=
    fun s t => hFc.intervalIntegrable s t
  have hre : ∫ θ in (0 : ℝ)..π, Real.cos (r * Real.sin θ) = (∫ θ in (0 : ℝ)..π, F θ).re := by
    rw [← Complex.reCLM_apply,
      ← ContinuousLinearMap.intervalIntegral_comp_comm Complex.reCLM (hFi 0 π)]
    congr 1; funext θ
    simp only [F, Complex.reCLM_apply]
    rw [mul_comm Complex.I, Complex.exp_ofReal_mul_I_re]
  have s3 : 0 < Real.sqrt 3 := by positivity
  have s3sq : Real.sqrt 3 * Real.sqrt 3 = 3 := Real.mul_self_sqrt (by norm_num)
  have hpi : 0 < π := Real.pi_pos
  -- first-derivative pieces
  have hd1 : deriv (fun x => 2 / Real.sqrt 3 * Real.sin x) =
      fun x => 2 / Real.sqrt 3 * Real.cos x := by
    funext x; exact ((Real.hasDerivAt_sin x).const_mul _).deriv
  have hanti : ∀ s t : ℝ, 0 ≤ s → t ≤ π →
      AntitoneOn (deriv (fun x => 2 / Real.sqrt 3 * Real.sin x)) (Set.Icc s t) := by
    intro s t hs ht x hx y hy hxy
    rw [hd1]
    exact mul_le_mul_of_nonneg_left
      (Real.antitoneOn_cos ⟨hs.trans hx.1, hx.2.trans ht⟩ ⟨hs.trans hy.1, hy.2.trans ht⟩ hxy)
      (by positivity)
  have he1 : ∀ x : ℝ, r * Real.sqrt 3 / 2 * (2 / Real.sqrt 3 * Real.sin x) = r * Real.sin x := by
    intro x; field_simp
  have hlam1 : 0 < r * Real.sqrt 3 / 2 := by positivity
  have hval1 : 3 / (r * Real.sqrt 3 / 2) = 2 * Real.sqrt 3 / r := by
    field_simp; nlinarith [s3sq]
  have hkey : 2 / Real.sqrt 3 * (Real.sqrt 3 / 2) = 1 := by field_simp
  have hA : ‖∫ x in (0 : ℝ)..(π / 6), F x‖ ≤ 2 * Real.sqrt 3 / r := by
    have h := van_der_corput_first_derivative (fun x => 2 / Real.sqrt 3 * Real.sin x) 0 (π / 6)
      (r * Real.sqrt 3 / 2) (by positivity) (contDiff_const.mul Real.contDiff_sin)
      (Or.inr (hanti 0 (π / 6) le_rfl (by linarith)))
      (by
        intro x hx
        rw [hd1]
        have hc : Real.sqrt 3 / 2 ≤ Real.cos x := by
          rw [← Real.cos_pi_div_six]
          exact Real.antitoneOn_cos ⟨hx.1, by linarith [hx.2]⟩ ⟨by positivity, by linarith⟩ hx.2
        have : 1 ≤ 2 / Real.sqrt 3 * Real.cos x := by
          rw [← hkey]; exact mul_le_mul_of_nonneg_left hc (by positivity)
        exact this.trans (le_abs_self _))
      hlam1
    simp only [he1, hval1] at h
    exact h
  have hC : ‖∫ x in (5 * π / 6)..π, F x‖ ≤ 2 * Real.sqrt 3 / r := by
    have h := van_der_corput_first_derivative (fun x => 2 / Real.sqrt 3 * Real.sin x)
      (5 * π / 6) π
      (r * Real.sqrt 3 / 2) (by linarith) (contDiff_const.mul Real.contDiff_sin)
      (Or.inr (hanti (5 * π / 6) π (by positivity) le_rfl))
      (by
        intro x hx
        rw [hd1]
        have hc : Real.cos x ≤ -(Real.sqrt 3 / 2) := by
          rw [← Real.cos_pi_div_six, ← Real.cos_pi_sub]
          exact Real.antitoneOn_cos ⟨by linarith, by linarith⟩
            ⟨by linarith [hx.1], hx.2⟩ (by linarith [hx.1])
        have : 2 / Real.sqrt 3 * Real.cos x ≤ -1 := by
          rw [← hkey, ← mul_neg]; exact mul_le_mul_of_nonneg_left hc (by positivity)
        exact le_abs.mpr (Or.inr (by linarith)))
      hlam1
    simp only [he1, hval1] at h
    exact h
  -- second-derivative piece
  have hd2 : deriv (deriv (fun x => 2 * Real.sin x)) = fun x => -(2 * Real.sin x) := by
    have : deriv (fun x => 2 * Real.sin x) = fun x => 2 * Real.cos x := by
      funext x; exact ((Real.hasDerivAt_sin x).const_mul _).deriv
    rw [this]; funext x
    have := ((Real.hasDerivAt_cos x).const_mul (2 : ℝ)).deriv
    rw [this]; ring
  have he2 : ∀ x : ℝ, r / 2 * (2 * Real.sin x) = r * Real.sin x := by intro x; ring
  have hB : ‖∫ x in (π / 6)..(5 * π / 6), F x‖ ≤ 8 * Real.sqrt 2 / Real.sqrt r := by
    have h := van_der_corput_second_derivative (fun x => 2 * Real.sin x) (π / 6) (5 * π / 6)
      (r / 2) (by linarith) (contDiff_const.mul Real.contDiff_sin)
      (by
        intro x hx
        rw [hd2]
        have hs : 1 / 2 ≤ Real.sin x := by
          rw [← Real.sin_pi_div_six]
          rcases le_total x (π / 2) with hx2 | hx2
          · exact Real.strictMonoOn_sin.monotoneOn ⟨by linarith, by linarith⟩
              ⟨by linarith [hx.1], hx2⟩ hx.1
          · rw [← Real.sin_pi_sub x]
            exact Real.strictMonoOn_sin.monotoneOn ⟨by linarith, by linarith⟩
              ⟨by linarith [hx.2], by linarith⟩ (by linarith [hx.2])
        rw [abs_neg, abs_of_pos (by linarith)]
        linarith)
      (by positivity)
    simp only [he2] at h
    rw [Real.sqrt_div' r (by norm_num : (0 : ℝ) ≤ 2)] at h
    have hsr : 0 < Real.sqrt r := Real.sqrt_pos.mpr hr
    have hs2 : 0 < Real.sqrt 2 := by positivity
    calc _ ≤ 8 / (Real.sqrt r / Real.sqrt 2) := h
      _ = 8 * Real.sqrt 2 / Real.sqrt r := by field_simp
  have hsplit : ∫ x in (0 : ℝ)..π, F x =
      (∫ x in (0 : ℝ)..(π / 6), F x) + (∫ x in (π / 6)..(5 * π / 6), F x) +
        ∫ x in (5 * π / 6)..π, F x := by
    rw [intervalIntegral.integral_add_adjacent_intervals (hFi 0 (π / 6)) (hFi (π / 6) (5 * π / 6)),
      intervalIntegral.integral_add_adjacent_intervals (hFi 0 (5 * π / 6)) (hFi (5 * π / 6) π)]
  have hnorm : ‖∫ x in (0 : ℝ)..π, F x‖ ≤
      8 * Real.sqrt 2 / Real.sqrt r + 4 * Real.sqrt 3 / r := by
    rw [hsplit]
    calc _ ≤ ‖∫ x in (0 : ℝ)..(π / 6), F x‖ + ‖∫ x in (π / 6)..(5 * π / 6), F x‖ +
          ‖∫ x in (5 * π / 6)..π, F x‖ := norm_add₃_le
      _ ≤ 2 * Real.sqrt 3 / r + 8 * Real.sqrt 2 / Real.sqrt r + 2 * Real.sqrt 3 / r := by
          gcongr
      _ = 8 * Real.sqrt 2 / Real.sqrt r + 4 * Real.sqrt 3 / r := by ring
  rw [hre, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < 1 / π)]
  gcongr
  exact (Complex.abs_re_le_norm _).trans hnorm

-- Step 2's arithmetic at λ = 100 with δ = λ^(-1/2) = 1/10: 2δ + 6/(λδ) = 8/√100 = 8/10.
example : (2 : ℚ) * (1 / 10) + 6 / (100 * (1 / 10)) = 8 / 10 := by norm_num

#print axioms van_der_corput_first_derivative
#print axioms van_der_corput_second_derivative
#print axioms bessel_j0_uniform_bound
