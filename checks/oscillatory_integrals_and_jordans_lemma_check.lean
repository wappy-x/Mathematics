-- Jordan's lemma: for a > 0 the integral of g(z) e^(iaz) over the upper half-circle of radius R is at most π/a times the largest size of g on that arc, the click's cosine integral of cos(ax)/(1 + x²) over the real line is π e^(−|a|), and the tilted pulse's improper integral of x sin(ax)/(1 + x²) is π e^(−a) for a > 0.
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic

open Complex Filter Topology MeasureTheory

/-! Helper lemmas for the proofs below. -/

lemma jl_jordan_exp_integral_le (c : ℝ) (hc : 0 < c) :
    ∫ t in (0 : ℝ)..Real.pi, Real.exp (-(c * Real.sin t)) ≤ Real.pi / c := by
  have hpi := Real.pi_pos
  set k := 2 / Real.pi * c with hkdef
  have hk : 0 < k := by positivity
  have h1 : ∀ t ∈ Set.Icc (0 : ℝ) Real.pi, Real.exp (-(c * Real.sin t)) ≤
      Real.exp (-(k * t)) + Real.exp (-(k * (Real.pi - t))) := by
    intro t ht
    rcases le_total t (Real.pi / 2) with h | h
    · have := Real.mul_le_sin ht.1 h
      have : k * t ≤ c * Real.sin t := by
        rw [hkdef]; nlinarith
      have := Real.exp_le_exp.mpr (neg_le_neg this)
      have := Real.exp_pos (-(k * (Real.pi - t)))
      linarith
    · have := Real.mul_le_sin (x := Real.pi - t) (by linarith [ht.2]) (by linarith)
      rw [Real.sin_pi_sub] at this
      have : k * (Real.pi - t) ≤ c * Real.sin t := by
        rw [hkdef]; nlinarith
      have := Real.exp_le_exp.mpr (neg_le_neg this)
      have := Real.exp_pos (-(k * t))
      linarith
  have hint : ∀ u : ℝ, IntervalIntegrable (fun t => Real.exp (-(u * t))) volume 0 Real.pi :=
    fun u => (by fun_prop : Continuous fun t => Real.exp (-(u * t))).intervalIntegrable _ _
  have hE : ∫ t in (0 : ℝ)..Real.pi, Real.exp (-(k * t)) = (1 - Real.exp (-(k * Real.pi))) / k := by
    have := intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun t => -Real.exp (-k * t) / k) (f' := fun t => Real.exp (-k * t))
      (a := 0) (b := Real.pi) (fun x _ => by
        have h0 : HasDerivAt (fun t : ℝ => -k * t) (-k) x := by
          simpa using (hasDerivAt_id x).const_mul (-k)
        have := h0.exp.neg.div_const k
        convert this using 1
        field_simp) (by simpa [neg_mul] using hint k)
    simp only [neg_mul] at this
    rw [this]; field_simp; simp; ring
  calc ∫ t in (0 : ℝ)..Real.pi, Real.exp (-(c * Real.sin t))
      ≤ ∫ t in (0 : ℝ)..Real.pi, (Real.exp (-(k * t)) + Real.exp (-(k * (Real.pi - t)))) :=
        intervalIntegral.integral_mono_on hpi.le
          ((by fun_prop : Continuous fun t => Real.exp (-(c * Real.sin t))).intervalIntegrable _ _)
          ((by fun_prop : Continuous fun t =>
            Real.exp (-(k * t)) + Real.exp (-(k * (Real.pi - t)))).intervalIntegrable _ _) h1
    _ = 2 * ((1 - Real.exp (-(k * Real.pi))) / k) := by
        rw [intervalIntegral.integral_add (hint k)
          ((by fun_prop : Continuous fun t => Real.exp (-(k * (Real.pi - t)))).intervalIntegrable _ _),
          intervalIntegral.integral_comp_sub_left (fun t => Real.exp (-(k * t)))]
        simp only [sub_self, sub_zero]
        rw [hE]; ring
    _ ≤ Real.pi / c := by
        have := Real.exp_pos (-(k * Real.pi))
        have hkpi : k * Real.pi = 2 * c := by rw [hkdef]; field_simp
        rw [hkpi] at this ⊢
        have e : 2 * ((1 - Real.exp (-(2 * c))) / k) = Real.pi * (1 - Real.exp (-(2 * c))) / c := by
          rw [hkdef]; field_simp
        rw [e]
        apply div_le_div_of_nonneg_right _ hc.le
        nlinarith

#print axioms jl_jordan_exp_integral_le

lemma jl_integrable_exp_neg_abs : Integrable (fun v : ℝ => Real.exp (-|v|)) := by
  refine (integrable_inv_one_add_sq.const_mul 2).mono'
    (by fun_prop : Continuous fun v : ℝ => Real.exp (-|v|)).aestronglyMeasurable
    (Eventually.of_forall fun v => ?_)
  rw [Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
  have h := Real.quadratic_le_exp_of_nonneg (abs_nonneg v)
  have hv : v ^ 2 = |v| ^ 2 := (sq_abs v).symm
  rw [Real.exp_neg, ← div_eq_mul_inv, inv_eq_one_div, div_le_div_iff₀ (Real.exp_pos _) (by positivity)]
  nlinarith [abs_nonneg v]

#print axioms jl_integrable_exp_neg_abs

lemma jl_integrable_abs_mul_exp_neg_abs : Integrable (fun v : ℝ => |v| * Real.exp (-|v|)) := by
  refine (integrable_inv_one_add_sq.const_mul 27).mono'
    (by fun_prop : Continuous fun v : ℝ => |v| * Real.exp (-|v|)).aestronglyMeasurable
    (Eventually.of_forall fun v => ?_)
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  set t := |v| with ht
  have t0 : 0 ≤ t := abs_nonneg v
  have hv : v ^ 2 = t ^ 2 := (sq_abs v).symm
  have h := Real.add_one_le_exp (t / 3)
  have h3 : (t / 3 + 1) ^ 3 ≤ Real.exp t := by
    have : Real.exp t = Real.exp (t / 3) ^ 3 := by rw [← Real.exp_nat_mul]; ring_nf
    rw [this]; exact pow_le_pow_left₀ (by positivity) h 3
  rw [Real.exp_neg, hv, ← div_eq_mul_inv, ← div_eq_mul_inv, div_le_div_iff₀ (Real.exp_pos _) (by positivity)]
  nlinarith [sq_nonneg t, mul_nonneg t0 (sq_nonneg t)]

#print axioms jl_integrable_abs_mul_exp_neg_abs

lemma jl_integral_Ioi_exp (c : ℂ) (hc : c.re = -1) :
    ∫ v : ℝ in Set.Ioi 0, Complex.exp (c * v) = -1 / c := by
  rw [integral_exp_mul_complex_Ioi (by rw [hc]; norm_num) 0]; simp

#print axioms jl_integral_Ioi_exp

lemma jl_integral_Ioi_mul_exp (c : ℂ) (hc : c.re = -1) :
    ∫ v : ℝ in Set.Ioi 0, (v : ℂ) * Complex.exp (c * v) = 1 / c ^ 2 := by
  have hc0 : c ≠ 0 := by rintro rfl; simp at hc
  have hnorm : ∀ v : ℝ, ‖(v : ℂ) * Complex.exp (c * v)‖ = |v| * Real.exp (-v) := by
    intro v; rw [norm_mul, Complex.norm_exp]; simp [hc]
  have hnorm' : ∀ v : ℝ, ‖Complex.exp (c * v)‖ = Real.exp (-v) := by
    intro v; rw [Complex.norm_exp]; simp [hc]
  have hint : IntegrableOn (fun v : ℝ => (v : ℂ) * Complex.exp (c * v)) (Set.Ioi 0) := by
    have hg : IntegrableOn (fun v : ℝ => v * Real.exp (-v)) (Set.Ioi 0) := by
      have := Real.GammaIntegral_convergent (s := 2) two_pos
      refine this.congr_fun (fun v _ => ?_) measurableSet_Ioi
      norm_num [Real.rpow_one]; ring
    refine Integrable.mono' hg
      (by fun_prop : Continuous fun v : ℝ => (v : ℂ) * Complex.exp (c * v)).aestronglyMeasurable ?_
    refine (ae_restrict_iff' measurableSet_Ioi).mpr (Eventually.of_forall fun v hv => ?_)
    rw [hnorm, abs_of_pos hv]
  have hA : Tendsto (fun v : ℝ => (v : ℂ) * Complex.exp (c * v)) atTop (𝓝 0) := by
    rw [tendsto_zero_iff_norm_tendsto_zero]
    have hlim : Tendsto (fun v : ℝ => v * Real.exp (-v)) atTop (𝓝 0) := by
      simpa using Real.tendsto_pow_mul_exp_neg_atTop_nhds_zero 1
    refine hlim.congr' ?_
    filter_upwards [eventually_ge_atTop 0] with v hv
    rw [hnorm, abs_of_nonneg hv]
  have hB : Tendsto (fun v : ℝ => Complex.exp (c * v)) atTop (𝓝 0) := by
    rw [tendsto_zero_iff_norm_tendsto_zero]
    simpa [hnorm'] using Real.tendsto_exp_neg_atTop_nhds_zero
  have hF : Tendsto (fun v : ℝ => ((v : ℂ) / c - 1 / c ^ 2) * Complex.exp (c * v)) atTop (𝓝 0) := by
    have := (hA.const_mul (1 / c)).sub (hB.const_mul (1 / c ^ 2))
    simp only [mul_zero, sub_zero] at this
    refine this.congr (fun v => ?_)
    ring
  have := integral_Ioi_of_hasDerivAt_of_tendsto' (a := 0) (m := 0)
    (f := fun v : ℝ => ((v : ℂ) / c - 1 / c ^ 2) * Complex.exp (c * v))
    (f' := fun v : ℝ => (v : ℂ) * Complex.exp (c * v)) ?_ hint hF
  · rw [this]; simp
  · intro x _
    have h1 : HasDerivAt (fun v : ℝ => (v : ℂ)) 1 x := (hasDerivAt_id x).ofReal_comp
    have h2 : HasDerivAt (fun v : ℝ => c * (v : ℂ)) c x := by simpa using h1.const_mul c
    have := ((h1.div_const c).sub_const (1 / c ^ 2)).mul h2.cexp
    convert this using 1
    field_simp
    ring

#print axioms jl_integral_Ioi_mul_exp

lemma jl_split_line (F : ℝ → ℂ) (hF : Integrable F) :
    ∫ v, F v = (∫ v in Set.Ioi 0, F v) + ∫ v in Set.Ioi 0, F (-v) := by
  rw [← integral_add_compl (s := Set.Ioi (0 : ℝ)) measurableSet_Ioi hF, Set.compl_Ioi,
    integral_comp_neg_Ioi, neg_zero]

#print axioms jl_split_line

open scoped FourierTransform in
lemma jl_cos_formula (φ G : ℝ → ℝ) (hφc : Continuous φ) (hφi : Integrable φ) (hG : Integrable G)
    (hF : ∀ ξ, 𝓕 (fun v => (φ v : ℂ)) ξ = (G (2 * Real.pi * ξ) : ℂ)) (x : ℝ) :
    ∫ u, Real.cos (u * x) * G u = 2 * Real.pi * φ x := by
  have hpi : (2 * Real.pi) ≠ 0 := by positivity
  have h1 : Integrable (𝓕 (fun v => (φ v : ℂ))) := by
    rw [show 𝓕 (fun v => (φ v : ℂ)) = fun ξ => ((G (2 * Real.pi * ξ)) : ℂ) from funext hF]
    exact (hG.comp_mul_left' hpi).ofReal
  have h2 := (hφi.ofReal).fourierInv_fourier_eq h1
    (Complex.continuous_ofReal.comp hφc).continuousAt (v := x)
  rw [Real.fourierInv_eq'] at h2
  simp_rw [hF] at h2
  set H : ℝ → ℂ := fun u => Complex.exp (((u * x : ℝ) : ℂ) * I) * (G u : ℂ) with hHdef
  have h3 : (fun v : ℝ => Complex.exp (((2 * Real.pi * inner ℝ v x : ℝ) : ℂ) * I) •
      ((G (2 * Real.pi * v) : ℝ) : ℂ)) = fun v => H (2 * Real.pi * v) := by
    ext v
    simp only [hHdef, smul_eq_mul]
    congr 3
    simp
    ring
  rw [h3, Measure.integral_comp_mul_left] at h2
  have hH : Integrable H := by
    refine Integrable.mono' hG.norm
      (((by fun_prop : Continuous fun u : ℝ => Complex.exp (((u * x : ℝ) : ℂ) * I)).aestronglyMeasurable).mul
        hG.ofReal.aestronglyMeasurable) (Eventually.of_forall fun u => ?_)
    simp only [hHdef, norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul, Complex.norm_real]
    rfl
  have h4 : ∫ u, H u = ((2 * Real.pi * φ x : ℝ) : ℂ) := by
    rw [abs_inv, abs_of_pos (by positivity : (0 : ℝ) < 2 * Real.pi)] at h2
    have hpi' : (2 * (Real.pi : ℂ)) ≠ 0 := by exact_mod_cast hpi
    rw [Complex.real_smul] at h2
    push_cast at h2 ⊢
    rw [← h2]
    field_simp
  have h5 := integral_re hH
  rw [h4] at h5
  simp only [RCLike.re_to_complex, Complex.ofReal_re] at h5
  rw [← h5]
  refine integral_congr_ae (Eventually.of_forall fun u => ?_)
  simp only [hHdef, Complex.mul_re, Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im,
    Complex.ofReal_re, Complex.ofReal_im, mul_zero, sub_zero]

#print axioms jl_cos_formula

open scoped FourierTransform in
lemma jl_fourier_exp_neg_abs (ξ : ℝ) :
    𝓕 (fun v : ℝ => ((Real.exp (-|v|) : ℝ) : ℂ)) ξ =
      ((2 / (1 + (2 * Real.pi * ξ) ^ 2) : ℝ) : ℂ) := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  set ω : ℝ := 2 * Real.pi * ξ with hω
  set F : ℝ → ℂ := fun v => Complex.exp (((-2 * Real.pi * v * ξ : ℝ) : ℂ) * I) •
    ((Real.exp (-|v|) : ℝ) : ℂ) with hFdef
  have hF : Integrable F := by
    refine Integrable.mono' jl_integrable_exp_neg_abs
      (by fun_prop : Continuous F).aestronglyMeasurable (Eventually.of_forall fun v => ?_)
    refine le_of_eq ?_
    simp only [hFdef, smul_eq_mul, norm_mul, Complex.norm_exp_ofReal_mul_I, Complex.norm_real,
      Real.norm_eq_abs, one_mul]
    simp [abs_of_pos (Real.exp_pos _)]
  rw [jl_split_line F hF]
  have e1 : ∫ v in Set.Ioi 0, F v = ∫ v : ℝ in Set.Ioi 0, Complex.exp ((-1 - ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_of_pos (show (0 : ℝ) < v from hv), Complex.ofReal_exp,
      ← Complex.exp_add]
    congr 1; simp only [hω]; push_cast; ring
  have e2 : ∫ v in Set.Ioi 0, F (-v) = ∫ v : ℝ in Set.Ioi 0, Complex.exp ((-1 + ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_neg, abs_of_pos (show (0 : ℝ) < v from hv),
      Complex.ofReal_exp, ← Complex.exp_add]
    congr 1; simp only [hω]; push_cast; ring
  rw [e1, e2, jl_integral_Ioi_exp _ (by simp), jl_integral_Ioi_exp _ (by simp)]
  have h1 : (-1 - ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h2 : (-1 + ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h3 : (1 + (ω : ℂ) ^ 2) ≠ 0 := by exact_mod_cast (by positivity : (1 + ω ^ 2) ≠ 0)
  push_cast
  field_simp
  ring_nf
  simp only [I_sq]
  ring

#print axioms jl_fourier_exp_neg_abs

open scoped FourierTransform in
lemma jl_fourier_abs_mul_exp_neg_abs (ξ : ℝ) :
    𝓕 (fun v : ℝ => ((|v| * Real.exp (-|v|) : ℝ) : ℂ)) ξ =
      ((2 * (1 - (2 * Real.pi * ξ) ^ 2) / (1 + (2 * Real.pi * ξ) ^ 2) ^ 2 : ℝ) : ℂ) := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  set ω : ℝ := 2 * Real.pi * ξ with hω
  set F : ℝ → ℂ := fun v => Complex.exp (((-2 * Real.pi * v * ξ : ℝ) : ℂ) * I) •
    ((|v| * Real.exp (-|v|) : ℝ) : ℂ) with hFdef
  have hF : Integrable F := by
    refine Integrable.mono' jl_integrable_abs_mul_exp_neg_abs
      (by fun_prop : Continuous F).aestronglyMeasurable (Eventually.of_forall fun v => ?_)
    refine le_of_eq ?_
    simp only [hFdef, smul_eq_mul, norm_mul, Complex.norm_exp_ofReal_mul_I, Complex.norm_real,
      Real.norm_eq_abs, one_mul]
    simp [abs_of_pos (Real.exp_pos _)]
  rw [jl_split_line F hF]
  have e1 : ∫ v in Set.Ioi 0, F v =
      ∫ v : ℝ in Set.Ioi 0, (v : ℂ) * Complex.exp ((-1 - ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_of_pos (show (0 : ℝ) < v from hv), Complex.ofReal_mul,
      Complex.ofReal_exp]
    rw [mul_left_comm, ← Complex.exp_add]
    congr 2; simp only [hω]; push_cast; ring
  have e2 : ∫ v in Set.Ioi 0, F (-v) =
      ∫ v : ℝ in Set.Ioi 0, (v : ℂ) * Complex.exp ((-1 + ω * I) * v) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun v hv => ?_)
    simp only [hFdef, smul_eq_mul, abs_neg, abs_of_pos (show (0 : ℝ) < v from hv),
      Complex.ofReal_mul, Complex.ofReal_exp]
    rw [mul_left_comm, ← Complex.exp_add]
    congr 2; simp only [hω]; push_cast; ring
  rw [e1, e2, jl_integral_Ioi_mul_exp _ (by simp), jl_integral_Ioi_mul_exp _ (by simp)]
  have h1 : (-1 - ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h2 : (-1 + ω * I) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  have h3 : (1 + (ω : ℂ) ^ 2) ≠ 0 := by exact_mod_cast (by positivity : (1 + ω ^ 2) ≠ 0)
  have h4 : (-1 - ω * I) * (-1 + ω * I) = 1 + (ω : ℂ) ^ 2 := by
    ring_nf; simp only [I_sq]; ring
  push_cast
  field_simp
  ring_nf
  simp only [I_sq, I_pow_four]
  ring

#print axioms jl_fourier_abs_mul_exp_neg_abs

lemma jl_integrable_two_div : Integrable (fun u : ℝ => 2 / (1 + u ^ 2)) := by
  simpa [div_eq_mul_inv] using integrable_inv_one_add_sq.const_mul 2

#print axioms jl_integrable_two_div

lemma jl_integrable_G1 : Integrable (fun u : ℝ => 2 * (1 - u ^ 2) / (1 + u ^ 2) ^ 2) := by
  refine (integrable_inv_one_add_sq.const_mul 2).mono'
    ((by fun_prop : Continuous fun u : ℝ => 2 * (1 - u ^ 2)).div (by fun_prop)
      (fun u => by positivity)).aestronglyMeasurable
    (Eventually.of_forall fun u => ?_)
  have h1 : 0 < 1 + u ^ 2 := by positivity
  rw [Real.norm_eq_abs, abs_div, abs_of_pos (by positivity : (0 : ℝ) < (1 + u ^ 2) ^ 2),
    div_le_iff₀ (by positivity), abs_mul, abs_two]
  have : |1 - u ^ 2| ≤ 1 + u ^ 2 := abs_le.mpr ⟨by nlinarith [sq_nonneg u], by nlinarith [sq_nonneg u]⟩
  have e : 2 * (1 + u ^ 2)⁻¹ * (1 + u ^ 2) ^ 2 = 2 * (1 + u ^ 2) := by field_simp
  rw [e]; linarith

#print axioms jl_integrable_G1

lemma jl_cos_lorentz (x : ℝ) :
    ∫ u, Real.cos (u * x) * (2 / (1 + u ^ 2)) = 2 * Real.pi * Real.exp (-|x|) :=
  jl_cos_formula (fun v => Real.exp (-|v|)) (fun u => 2 / (1 + u ^ 2)) (by fun_prop)
    jl_integrable_exp_neg_abs jl_integrable_two_div jl_fourier_exp_neg_abs x

#print axioms jl_cos_lorentz

lemma jl_cos_G1 (x : ℝ) :
    ∫ u, Real.cos (u * x) * (2 * (1 - u ^ 2) / (1 + u ^ 2) ^ 2) =
      2 * Real.pi * (|x| * Real.exp (-|x|)) :=
  jl_cos_formula (fun v => |v| * Real.exp (-|v|)) (fun u => 2 * (1 - u ^ 2) / (1 + u ^ 2) ^ 2)
    (by fun_prop) jl_integrable_abs_mul_exp_neg_abs jl_integrable_G1
    jl_fourier_abs_mul_exp_neg_abs x

#print axioms jl_cos_G1

lemma jl_w_tendsto {l : Filter ℝ} (hl : Tendsto (fun x : ℝ => |x|) l atTop) :
    Tendsto (fun x : ℝ => x / (1 + x ^ 2)) l (𝓝 0) := by
  have h0 := tendsto_inv_atTop_zero.comp hl
  refine squeeze_zero_norm' ?_ h0
  filter_upwards [hl.eventually_gt_atTop 0] with x hx
  have h1 : 0 < 1 + x ^ 2 := by positivity
  rw [Real.norm_eq_abs, abs_div, abs_of_pos h1, div_le_iff₀ h1, Function.comp_apply,
    ← sq_abs x]
  rw [inv_mul_eq_div, le_div_iff₀ hx]
  nlinarith

#print axioms jl_w_tendsto

/-- Jordan's lemma. Let a > 0 and let C_R be the upper half-circle z = R e^(it), 0 ≤ t ≤ π, of
radius R > 0. Let g be continuous on that arc, and let M be at least g's size at every point of
the arc (for example M = M_R, g's largest size there). Then the integral of g(z) e^(iaz) dz along
the arc, with dz = i R e^(it) dt, has size at most (π / a) · M: the arc's length R has cancelled. -/
theorem jordans_lemma_upper_arc_bound (g : ℂ → ℂ) (a R M : ℝ) (ha : 0 < a) (hR : 0 < R)
    (hg : ContinuousOn g (Metric.sphere (0 : ℂ) R ∩ {z : ℂ | 0 ≤ z.im}))
    (hM : ∀ t ∈ Set.Icc (0 : ℝ) Real.pi, ‖g (R * Complex.exp (t * I))‖ ≤ M) :
    ‖∫ t in (0 : ℝ)..Real.pi,
        g (R * Complex.exp (t * I)) * Complex.exp (I * a * (R * Complex.exp (t * I))) *
          (I * R * Complex.exp (t * I))‖ ≤ Real.pi / a * M := by
  have hpi := Real.pi_pos
  have hM0 : 0 ≤ M := le_trans (norm_nonneg _) (hM 0 ⟨le_rfl, hpi.le⟩)
  have hb : ∀ t ∈ Set.Icc (0 : ℝ) Real.pi,
      ‖g (R * Complex.exp (t * I)) * Complex.exp (I * a * (R * Complex.exp (t * I))) *
          (I * R * Complex.exp (t * I))‖ ≤ M * R * Real.exp (-((a * R) * Real.sin t)) := by
    intro t ht
    rw [norm_mul, norm_mul, Complex.norm_exp]
    have e1 : (I * a * (R * Complex.exp (t * I))).re = -((a * R) * Real.sin t) := by
      simp [Complex.mul_re, Complex.mul_im, exp_ofReal_mul_I_re, exp_ofReal_mul_I_im]; ring
    have e2 : ‖I * R * Complex.exp (t * I)‖ = R := by
      rw [norm_mul, norm_mul, Complex.norm_exp_ofReal_mul_I]; simp [abs_of_pos hR]
    rw [e1, e2]
    have := hM t ht
    have := Real.exp_pos (-((a * R) * Real.sin t))
    calc ‖g (R * Complex.exp (t * I))‖ * Real.exp (-((a * R) * Real.sin t)) * R
        ≤ M * Real.exp (-((a * R) * Real.sin t)) * R := by gcongr
      _ = _ := by ring
  calc _ ≤ ∫ t in (0 : ℝ)..Real.pi, M * R * Real.exp (-((a * R) * Real.sin t)) :=
        intervalIntegral.norm_integral_le_of_norm_le hpi.le
          (Eventually.of_forall fun t ht => hb t ⟨ht.1.le, ht.2⟩)
          ((by fun_prop : Continuous fun t =>
            M * R * Real.exp (-((a * R) * Real.sin t))).intervalIntegrable _ _)
    _ = M * R * ∫ t in (0 : ℝ)..Real.pi, Real.exp (-((a * R) * Real.sin t)) :=
        intervalIntegral.integral_const_mul _ _
    _ ≤ M * R * (Real.pi / (a * R)) := by
        gcongr
        exact jl_jordan_exp_integral_le (a * R) (by positivity)
    _ = Real.pi / a * M := by field_simp

/-- The click's content at frequency a. For every real a, the integral over the whole real line
of cos(ax) / (1 + x²) is π e^(−|a|); at a = 0 this is π, the area under the pulse. -/
theorem integral_cos_mul_div_one_add_sq (a : ℝ) :
    ∫ x : ℝ, Real.cos (a * x) / (1 + x ^ 2) = Real.pi * Real.exp (-|a|) := by
  have h := jl_cos_lorentz a
  have e : (fun x : ℝ => Real.cos (a * x) / (1 + x ^ 2)) =
      fun x => (1 / 2) * (Real.cos (x * a) * (2 / (1 + x ^ 2))) := by
    ext x; rw [mul_comm a x]; field_simp
  rw [e, integral_const_mul, h]; ring

/-- The tilted pulse, where Jordan's lemma earns its keep. For a > 0, the integral of
x sin(ax) / (1 + x²) from A to B tends to π e^(−a) as A → −∞ and B → +∞ independently:
the improper integral over the whole real line exists and equals π e^(−a). -/
theorem tendsto_integral_mul_sin_div_one_add_sq (a : ℝ) (ha : 0 < a) :
    Tendsto (fun p : ℝ × ℝ => ∫ x in p.1..p.2, x * Real.sin (a * x) / (1 + x ^ 2))
      (atBot ×ˢ atTop) (𝓝 (Real.pi * Real.exp (-a))) := by
  have ha' : a ≠ 0 := ha.ne'
  set w : ℝ → ℝ := fun x => x / (1 + x ^ 2) with hw
  set K : ℝ → ℝ := fun x => Real.cos (x * a) * (2 * (1 - x ^ 2) / (1 + x ^ 2) ^ 2) with hKdef
  have hK : Integrable K :=
    jl_integrable_G1.bdd_mul (c := 1) (by fun_prop : Continuous fun x : ℝ => Real.cos (x * a)).aestronglyMeasurable
      (Eventually.of_forall fun x => by simpa using Real.abs_cos_le_one (x * a))
  have hKval : ∫ x, K x = 2 * Real.pi * (a * Real.exp (-a)) := by
    rw [hKdef, jl_cos_G1 a, abs_of_pos ha]
  have hibp : ∀ A B : ℝ, ∫ x in A..B, x * Real.sin (a * x) / (1 + x ^ 2) =
      w B * (-Real.cos (a * B) / a) - w A * (-Real.cos (a * A) / a) +
        1 / (2 * a) * ∫ x in A..B, K x := by
    intro A B
    have hd1 : ∀ x ∈ Set.uIcc A B, HasDerivAt w ((1 - x ^ 2) / (1 + x ^ 2) ^ 2) x := by
      intro x _
      have h1 : (1 + x ^ 2) ≠ 0 := by positivity
      have := (hasDerivAt_id x).div (((hasDerivAt_id x).pow 2).const_add 1) h1
      convert this using 1
      · ext y; simp [hw]
      · simp; field_simp; ring
    have hd2 : ∀ x ∈ Set.uIcc A B,
        HasDerivAt (fun x => -Real.cos (a * x) / a) (Real.sin (a * x)) x := by
      intro x _
      have h0 : HasDerivAt (fun x : ℝ => a * x) a x := by
        simpa using (hasDerivAt_id x).const_mul a
      have := ((Real.hasDerivAt_cos (a * x)).comp x h0).neg.div_const a
      convert this using 1
      · ext y; simp
      · field_simp
    have hi := intervalIntegral.integral_mul_deriv_eq_deriv_mul hd1 hd2
      (((by fun_prop : Continuous fun x : ℝ => 1 - x ^ 2).div (by fun_prop)
        (fun x => by positivity)).intervalIntegrable _ _)
      ((by fun_prop : Continuous fun x : ℝ => Real.sin (a * x)).intervalIntegrable _ _)
    have e1 : (∫ x in A..B, x * Real.sin (a * x) / (1 + x ^ 2)) =
        ∫ x in A..B, w x * Real.sin (a * x) := by
      refine intervalIntegral.integral_congr (fun x _ => ?_)
      simp only [hw]; ring
    have e2 : (∫ x in A..B, (1 - x ^ 2) / (1 + x ^ 2) ^ 2 * (-Real.cos (a * x) / a)) =
        -(1 / (2 * a)) * ∫ x in A..B, K x := by
      rw [← intervalIntegral.integral_const_mul]
      refine intervalIntegral.integral_congr (fun x _ => ?_)
      simp only [hKdef]
      rw [mul_comm x a]
      field_simp
    rw [e1, hi, e2]
    ring
  have hT1 : Tendsto (fun p : ℝ × ℝ => ∫ x in p.1..p.2, K x) (atBot ×ˢ atTop) (𝓝 (∫ x, K x)) :=
    intervalIntegral_tendsto_integral hK tendsto_fst tendsto_snd
  have hbd : ∀ {l : Filter (ℝ × ℝ)} {f : ℝ × ℝ → ℝ}, Tendsto (fun p => w (f p)) l (𝓝 0) →
      Tendsto (fun p => w (f p) * (-Real.cos (a * f p) / a)) l (𝓝 0) := by
    intro l f hf
    refine squeeze_zero_norm (a := fun p => ‖w (f p)‖ * (1 / a)) (fun p => ?_) ?_
    · rw [norm_mul]
      gcongr
      rw [Real.norm_eq_abs, abs_div, abs_neg, abs_of_pos ha]
      gcongr
      exact Real.abs_cos_le_one _
    · simpa using hf.norm.mul_const (1 / a)
  have hT2 := hbd (l := atBot ×ˢ atTop) (f := Prod.snd)
    ((jl_w_tendsto tendsto_abs_atTop_atTop).comp tendsto_snd)
  have hT3 := hbd (l := atBot ×ˢ atTop) (f := Prod.fst)
    ((jl_w_tendsto tendsto_abs_atBot_atTop).comp tendsto_fst)
  have hT := (hT2.sub hT3).add (hT1.const_mul (1 / (2 * a)))
  rw [hKval] at hT
  convert hT using 1
  · ext p; exact hibp p.1 p.2
  · congr 1; field_simp; ring

/-! The card's exact worked steps at a = 1. -/

-- The pole inside: 1 + z² = (z − i)(z + i).
example (z : ℂ) : 1 + z ^ 2 = (z - I) * (z + I) := by
  linear_combination I_sq

-- The residue at i: e^(i·i) / (2i) = −(e^(−1)/2) i.
example : Complex.exp (I * I) / (2 * I) = -((Real.exp (-1) / 2 : ℝ) : ℂ) * I := by
  rw [I_mul_I]; push_cast; field_simp; ring_nf; simp [I_sq]

-- The loop value: 2πi × e^(−1)/(2i) = π e^(−1).
example : 2 * (Real.pi : ℂ) * I * (Complex.exp (-1) / (2 * I)) =
    ((Real.pi * Real.exp (-1) : ℝ) : ℂ) := by
  push_cast; field_simp

-- Jordan's bound for the tilted pulse at R = 16, a = 1: π · 16 / (1 · (16² − 1)) = 16π/255.
example : Real.pi * 16 / (1 * (16 ^ 2 - 1)) = 16 * Real.pi / 255 := by
  ring

#print axioms jordans_lemma_upper_arc_bound
#print axioms integral_cos_mul_div_one_add_sq
#print axioms tendsto_integral_mul_sin_div_one_add_sq
