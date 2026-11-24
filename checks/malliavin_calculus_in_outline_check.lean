-- Malliavin calculus in outline: for a standard normal Z the slope moves onto a weight, E[f'(Z)] = E[Z f(Z)]; the digital's weighted average E[1{Z > a} Z] is the bell-curve height φ(a); and the delta of any bounded payoff on the zero-rate share is E[g(S_T) W_T] / (S₀ σ T).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory ProbabilityTheory
open scoped ContDiff

/-! The model: `Z` is a standard normal number, the measure `gaussianReal 0 1`, so an average
`E[h(Z)]` is `∫ z, h z ∂(gaussianReal 0 1)`. Brownian motion at the expiry is `W_T = √T Z`.
The share with no interest is `S_T = S₀ exp(-σ²T/2 + σ W_T)`.
`φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, the bell curve's height at `x`.
Wiener space and the Malliavin derivative `D_t` itself are not in Mathlib; this file states the
one-normal identity of Step 0 that the card calls "all of Malliavin calculus", the digital's
weighted average, and the Greek of Step 3 that integration by parts delivers. -/

lemma malliavin_integrable_gaussianReal_iff {μ : ℝ} {v : NNReal} (hv : v ≠ 0) {h : ℝ → ℝ} :
    Integrable h (gaussianReal μ v) ↔ Integrable (fun x => gaussianPDFReal μ v x * h x) := by
  rw [gaussianReal_of_var_ne_zero _ hv, integrable_withDensity_iff_integrable_smul'
    (measurable_gaussianPDF _ _) (ae_of_all _ fun _ => gaussianPDF_lt_top)]
  simp [toReal_gaussianPDF]

#print axioms malliavin_integrable_gaussianReal_iff

lemma malliavin_integrable_one_add_abs_pow (μ : ℝ) (v : NNReal) (n : ℕ) :
    Integrable (fun x : ℝ => (1 + |x|) ^ n) (gaussianReal μ v) := by
  refine ((integrable_exp_mul_gaussianReal (μ := μ) (v := v) (n : ℝ)).add
    (integrable_exp_mul_gaussianReal (μ := μ) (v := v) (-(n : ℝ)))).mono'
    (by fun_prop) (ae_of_all _ fun x => ?_)
  have h1 : (1 + |x|) ^ n ≤ Real.exp (n * |x|) := by
    rw [Real.exp_nat_mul]
    exact pow_le_pow_left₀ (by positivity) (by linarith [Real.add_one_le_exp |x|]) n
  have h2 : Real.exp (n * |x|) ≤ Real.exp (n * x) + Real.exp (-n * x) := by
    rcases abs_cases x with ⟨hx, _⟩ | ⟨hx, _⟩
    · rw [hx]; linarith [Real.exp_pos (-n * x)]
    · rw [hx]; ring_nf; linarith [Real.exp_pos (n * x)]
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  exact h1.trans h2

#print axioms malliavin_integrable_one_add_abs_pow

lemma malliavin_hasDerivAt_gaussianPDFReal_x (m : ℝ) (v : NNReal) (x : ℝ) :
    HasDerivAt (gaussianPDFReal m v) (-((x - m) / v) * gaussianPDFReal m v x) x := by
  have h0 : HasDerivAt (fun y : ℝ => (y - m) ^ 2) (2 * (x - m)) x := by
    simpa using ((hasDerivAt_id x).sub_const m).fun_pow 2
  have := ((h0.fun_neg.div_const (2 * (v : ℝ))).exp).const_mul (Real.sqrt (2 * Real.pi * v))⁻¹
  rw [gaussianPDFReal_def]
  convert this using 1
  · by_cases hv : (v : ℝ) = 0
    · simp [hv]
    · simp only [neg_div]; field_simp

#print axioms malliavin_hasDerivAt_gaussianPDFReal_x

lemma malliavin_hasDerivAt_gaussianPDFReal_m (m : ℝ) (v : NNReal) (x : ℝ) :
    HasDerivAt (fun m => gaussianPDFReal m v x) ((x - m) / v * gaussianPDFReal m v x) m := by
  have h0 : HasDerivAt (fun y : ℝ => (x - y) ^ 2) (-(2 * (x - m))) m := by
    simpa using ((hasDerivAt_id m).const_sub x).fun_pow 2
  have := ((h0.fun_neg.div_const (2 * (v : ℝ))).exp).const_mul (Real.sqrt (2 * Real.pi * v))⁻¹
  simp only [gaussianPDFReal]
  convert this using 1
  · by_cases hv : (v : ℝ) = 0
    · simp [hv]
    · simp only [neg_div]; field_simp

#print axioms malliavin_hasDerivAt_gaussianPDFReal_m

lemma malliavin_integral_affine (k : ℝ → ℝ) (hk : Measurable k) (m c : ℝ) (hc : c ≠ 0) :
    ∫ z, k (m + c * z) ∂(gaussianReal 0 1) =
      ∫ y, gaussianPDFReal m ⟨c ^ 2, sq_nonneg c⟩ y * k y := by
  have hv : (⟨c ^ 2, sq_nonneg c⟩ : NNReal) ≠ 0 := by
    intro h; apply hc
    have : c ^ 2 = 0 := congrArg (fun x : NNReal => (x : ℝ)) h
    exact (pow_eq_zero_iff two_ne_zero).mp this
  have hmap : (gaussianReal 0 1).map (fun z => m + c * z) = gaussianReal m ⟨c ^ 2, sq_nonneg c⟩ := by
    have : (fun z : ℝ => m + c * z) = (m + ·) ∘ (c * ·) := rfl
    rw [this, ← Measure.map_map (measurable_const_add m) (measurable_const_mul c),
      gaussianReal_map_const_mul, gaussianReal_map_const_add]
    congr 1
    · simp
    · ext; simp; rfl
  rw [← integral_map (by fun_prop) hk.aestronglyMeasurable, hmap,
    integral_gaussianReal_eq_integral_smul hv]
  simp only [smul_eq_mul]

#print axioms malliavin_integral_affine

lemma malliavin_integrable_abs_add_one_mul_exp {b : ℝ} (hb : 0 < b) :
    Integrable (fun x : ℝ => (|x| + 1) * Real.exp (-b * x ^ 2)) := by
  have := (integrable_mul_exp_neg_mul_sq hb).norm.add (integrable_exp_neg_mul_sq hb)
  convert this using 1
  ext x
  simp [abs_of_pos (Real.exp_pos _)]
  ring

#print axioms malliavin_integrable_abs_add_one_mul_exp

lemma malliavin_hasDerivAt_integral_pdf (h : ℝ → ℝ) (hh : Measurable h) (C : ℝ)
    (hC : ∀ y, |h y| ≤ C) (v : NNReal) (hv : v ≠ 0) (m0 : ℝ) :
    HasDerivAt (fun m => ∫ y, gaussianPDFReal m v y * h y)
      (∫ y, ((y - m0) / v * gaussianPDFReal m0 v y) * h y) m0 := by
  have hvpos : (0 : ℝ) < v := by positivity
  set K := (Real.sqrt (2 * Real.pi * v))⁻¹ with hK
  have hK0 : 0 ≤ K := by positivity
  have hC0 : 0 ≤ C := (abs_nonneg _).trans (hC 0)
  set bound : ℝ → ℝ := fun y => (|y - m0| + 1) / v *
    (K * Real.exp (1 / (2 * v) + -(1 / (4 * v)) * (y - m0) ^ 2)) * C with hbound
  have hb : 0 < 1 / (4 * (v : ℝ)) := by positivity
  have ib : Integrable bound := by
    have := ((malliavin_integrable_abs_add_one_mul_exp hb).comp_sub_right m0).const_mul
      (K * Real.exp (1 / (2 * v)) * C / v)
    convert this using 1
    ext y
    simp only [hbound, Real.exp_add]
    ring
  refine (hasDerivAt_integral_of_dominated_loc_of_deriv_le (Metric.ball_mem_nhds m0 one_pos)
    (Filter.Eventually.of_forall fun m =>
      ((measurable_gaussianPDFReal m v).mul hh).aestronglyMeasurable)
    (((integrable_gaussianPDFReal m0 v).mul_const C).mono'
      ((measurable_gaussianPDFReal m0 v).mul hh).aestronglyMeasurable
      (ae_of_all _ fun y => ?_))
    (((measurable_id.sub_const m0).div_const _).mul (measurable_gaussianPDFReal m0 v)
      |>.mul hh).aestronglyMeasurable
    (ae_of_all _ fun y m hm => ?_) ib
    (ae_of_all _ fun y m _ =>
      (malliavin_hasDerivAt_gaussianPDFReal_m m v y).mul_const (h y))).2
  · rw [Real.norm_eq_abs, Pi.mul_apply, abs_mul, abs_of_nonneg (gaussianPDFReal_nonneg _ _ _)]
    exact mul_le_mul_of_nonneg_left (hC y) (gaussianPDFReal_nonneg _ _ _)
  · rw [Metric.mem_ball, Real.dist_eq] at hm
    have hm' := abs_lt.mp hm
    have h1 : |y - m| ≤ |y - m0| + 1 := by
      calc |y - m| = |(y - m0) - (m - m0)| := by ring_nf
        _ ≤ |y - m0| + |m - m0| := abs_sub _ _
        _ ≤ |y - m0| + 1 := by linarith
    have hq : (y - m0) ^ 2 ≤ 2 * (y - m) ^ 2 + 2 := by
      nlinarith [sq_nonneg (y - m - (m - m0))]
    have h2 : -(y - m) ^ 2 / (2 * v) ≤ 1 / (2 * v) + -(1 / (4 * v)) * (y - m0) ^ 2 := by
      have e : -(y - m) ^ 2 / (2 * v) - (1 / (2 * v) + -(1 / (4 * v)) * (y - m0) ^ 2) =
          ((y - m0) ^ 2 - 2 * (y - m) ^ 2 - 2) / (4 * v) := by
        field_simp; ring
      have : ((y - m0) ^ 2 - 2 * (y - m) ^ 2 - 2) / (4 * v) ≤ 0 :=
        div_nonpos_of_nonpos_of_nonneg (by linarith) (by positivity)
      linarith
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_div, abs_of_pos hvpos,
      abs_of_nonneg (gaussianPDFReal_nonneg _ _ _), gaussianPDFReal]
    simp only [hbound]
    gcongr
    exact hC y

#print axioms malliavin_hasDerivAt_integral_pdf

/-- **Step 0: integration by parts for one normal number.** For a smooth `f` that does not
grow too fast (it and its slope are bounded by a polynomial), the average slope of `f` at a
standard normal `Z` equals the average of `Z` times `f(Z)`: `E[f'(Z)] = E[Z f(Z)]`.
The derivative moves off `f` and onto the weight `Z`. -/
theorem gaussian_integration_by_parts (f : ℝ → ℝ) (hf : ContDiff ℝ ∞ f)
    (C : ℝ) (n : ℕ) (hfC : ∀ x, |f x| ≤ C * (1 + |x|) ^ n)
    (hf'C : ∀ x, |deriv f x| ≤ C * (1 + |x|) ^ n) :
    ∫ z, deriv f z ∂(gaussianReal 0 1) = ∫ z, z * f z ∂(gaussianReal 0 1) := by
  have h1 : (1 : NNReal) ≠ 0 := one_ne_zero
  have hdiff : Differentiable ℝ f := hf.differentiable (by simp)
  have hP := malliavin_integrable_one_add_abs_pow 0 1
  have iF : Integrable f (gaussianReal 0 1) :=
    ((hP n).const_mul C).mono' hdiff.continuous.aestronglyMeasurable
      (ae_of_all _ fun x => by simpa using hfC x)
  have iF' : Integrable (deriv f) (gaussianReal 0 1) :=
    ((hP n).const_mul C).mono' (measurable_deriv f).aestronglyMeasurable
      (ae_of_all _ fun x => by simpa using hf'C x)
  have iZF : Integrable (fun x => x * f x) (gaussianReal 0 1) := by
    refine ((hP (n + 1)).const_mul C).mono'
      (continuous_id.mul hdiff.continuous).aestronglyMeasurable (ae_of_all _ fun x => ?_)
    rw [Real.norm_eq_abs, abs_mul, pow_succ]
    have h0 : 0 ≤ C * (1 + |x|) ^ n := (abs_nonneg _).trans (hfC x)
    calc |x| * |f x| ≤ (1 + |x|) * (C * (1 + |x|) ^ n) :=
          mul_le_mul (by linarith) (hfC x) (abs_nonneg _) (by positivity)
      _ = C * ((1 + |x|) ^ n * (1 + |x|)) := by ring
  rw [malliavin_integrable_gaussianReal_iff h1] at iF iF' iZF
  rw [integral_gaussianReal_eq_integral_smul h1, integral_gaussianReal_eq_integral_smul h1]
  simp only [smul_eq_mul]
  have key := integral_mul_deriv_eq_deriv_mul_of_integrable
    (u := gaussianPDFReal 0 1) (v := f) (u' := fun x => -((x - 0) / ((1 : NNReal) : ℝ)) * gaussianPDFReal 0 1 x)
    (v' := deriv f)
    (fun x _ => malliavin_hasDerivAt_gaussianPDFReal_x 0 1 x)
    (fun x _ => (hdiff x).hasDerivAt) iF'
    (by simpa [Pi.mul_def, mul_assoc, mul_comm, mul_left_comm] using iZF.neg) iF
  rw [key, ← integral_neg]
  congr 1; ext x; simp; ring

/-- **The digital's weight.** For a step `f = 1{z > a}`, whose slope is a spike, the weighted
average is still a plain number: `E[1{Z > a} Z] = φ(a)`, the bell curve's height at `a`.
At `a = 0.1` this is the card's 0.396953. -/
theorem digital_weighted_average_eq_bell_height (a : ℝ) :
    ∫ z, (if a < z then (1 : ℝ) else 0) * z ∂(gaussianReal 0 1) = gaussianPDFReal 0 1 a := by
  have h1 : (1 : NNReal) ≠ 0 := one_ne_zero
  have iZ : Integrable (fun x : ℝ => x) (gaussianReal 0 1) :=
    (memLp_id_gaussianReal 1).integrable le_rfl
  rw [malliavin_integrable_gaussianReal_iff h1] at iZ
  rw [integral_gaussianReal_eq_integral_smul h1]
  have e : (fun z => gaussianPDFReal 0 1 z • ((if a < z then (1 : ℝ) else 0) * z)) =
      Set.indicator (Set.Ioi a) (fun z => z * gaussianPDFReal 0 1 z) := by
    ext z; by_cases h : a < z <;> simp [h, Set.indicator, mul_comm]
  rw [e, integral_indicator measurableSet_Ioi]
  have hlim : Filter.Tendsto (fun x => -gaussianPDFReal 0 1 x) Filter.atTop (nhds 0) := by
    have : Filter.Tendsto (fun x : ℝ => -(x - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) Filter.atTop
        Filter.atBot := by
      simp only [sub_zero, NNReal.coe_one, mul_one, neg_div]
      exact Filter.tendsto_neg_atTop_atBot.comp
        ((Filter.tendsto_pow_atTop two_ne_zero).atTop_div_const two_pos)
    have := (Real.tendsto_exp_atBot.comp this).const_mul (Real.sqrt (2 * Real.pi * ((1 : NNReal) : ℝ)))⁻¹
    simpa [gaussianPDFReal] using this.neg
  have := integral_Ioi_of_hasDerivAt_of_tendsto' (a := a) (f := fun x => -gaussianPDFReal 0 1 x)
    (f' := fun z => z * gaussianPDFReal 0 1 z)
    (fun x _ => by simpa using (malliavin_hasDerivAt_gaussianPDFReal_x 0 1 x).fun_neg)
    (by simpa [mul_comm] using iZ.integrableOn) hlim
  rw [this]; simp

/-- **Step 3: the Greek by Malliavin integration by parts.** For a payoff `g` of the final
share price that is measurable and bounded (the digital qualifies), with today's price
`S₀ > 0`, volatility `σ > 0`, time `T > 0` and no interest, the slope of `E[g(S_T)]` in `S₀`
is the average of the payoff times the year-end noise `W_T = √T Z`, divided by `S₀ σ T`:
`Δ = E[g(S_T) W_T] / (S₀ σ T)`. The payoff is never differentiated. -/
theorem malliavin_weight_gives_delta (g : ℝ → ℝ) (hg : Measurable g) (C : ℝ)
    (hgC : ∀ x, |g x| ≤ C) (S₀ σ T : ℝ) (hS : 0 < S₀) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
      (fun s => ∫ z, g (s * Real.exp (-(σ ^ 2 / 2 * T) + σ * (Real.sqrt T * z)))
        ∂(gaussianReal 0 1))
      ((∫ z, g (S₀ * Real.exp (-(σ ^ 2 / 2 * T) + σ * (Real.sqrt T * z))) *
          (Real.sqrt T * z) ∂(gaussianReal 0 1)) / (S₀ * σ * T))
      S₀ := by
  set μ0 := -(σ ^ 2 / 2 * T) with hμ0
  set c := σ * Real.sqrt T with hcdef
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hc : 0 < c := mul_pos hσ hsT
  set h : ℝ → ℝ := fun y => g (Real.exp y) with hhdef
  have hh : Measurable h := hg.comp Real.measurable_exp
  set v : NNReal := ⟨c ^ 2, sq_nonneg c⟩ with hvdef
  have hv : v ≠ 0 := by
    intro h0; apply hc.ne'
    have : c ^ 2 = 0 := congrArg (fun x : NNReal => (x : ℝ)) h0
    exact (pow_eq_zero_iff two_ne_zero).mp this
  have hpt : ∀ s, 0 < s → ∀ z,
      g (s * Real.exp (μ0 + σ * (Real.sqrt T * z))) = h (Real.log s + μ0 + c * z) := by
    intro s hs z
    simp only [hhdef]
    rw [show Real.log s + μ0 + c * z = Real.log s + (μ0 + σ * (Real.sqrt T * z)) by
      rw [hcdef]; ring, Real.exp_add (Real.log s), Real.exp_log hs]
  set G : ℝ → ℝ := fun m => ∫ y, gaussianPDFReal m v y * h y with hG
  have hF : ∀ s, 0 < s →
      ∫ z, g (s * Real.exp (μ0 + σ * (Real.sqrt T * z))) ∂(gaussianReal 0 1) =
        G (Real.log s + μ0) := by
    intro s hs
    simp only [hG]
    rw [← malliavin_integral_affine h hh _ c hc.ne']
    exact integral_congr_ae (ae_of_all _ fun z => hpt s hs z)
  set m0 := Real.log S₀ + μ0 with hm0
  have hGd := malliavin_hasDerivAt_integral_pdf h hh C (fun y => hgC _) v hv m0
  have hcomp := hGd.comp S₀ ((Real.hasDerivAt_log hS.ne').add_const μ0)
  have hfinal := hcomp.congr_of_eventuallyEq (f₁ := fun s =>
      ∫ z, g (s * Real.exp (μ0 + σ * (Real.sqrt T * z))) ∂(gaussianReal 0 1))
    (by filter_upwards [lt_mem_nhds hS] with s hs using hF s hs)
  convert hfinal using 1
  have e1 : ∫ y, ((y - m0) / v * gaussianPDFReal m0 v y) * h y =
      c⁻¹ * ∫ z, z * h (m0 + c * z) ∂(gaussianReal 0 1) := by
    rw [← integral_const_mul]
    have := malliavin_integral_affine (fun y => (y - m0) / v * h y)
      ((measurable_id.sub_const m0).div_const _ |>.mul hh) m0 c hc.ne'
    rw [show (fun y => (y - m0) / v * gaussianPDFReal m0 v y * h y) =
      fun y => gaussianPDFReal m0 v y * ((y - m0) / v * h y) by ext y; ring, ← this]
    refine integral_congr_ae (ae_of_all _ fun z => ?_)
    have hvc : ((v : NNReal) : ℝ) = c ^ 2 := rfl
    rw [hvc]
    field_simp
    ring
  have e2 : ∫ z, g (S₀ * Real.exp (μ0 + σ * (Real.sqrt T * z))) * (Real.sqrt T * z)
      ∂(gaussianReal 0 1) = Real.sqrt T * ∫ z, z * h (m0 + c * z) ∂(gaussianReal 0 1) := by
    rw [← integral_const_mul]
    refine integral_congr_ae (ae_of_all _ fun z => ?_)
    dsimp only
    rw [hpt S₀ hS z, hm0]
    ring
  rw [e2, e1]
  have hT' : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT.le
  generalize ∫ z, z * h (m0 + c * z) ∂(gaussianReal 0 1) = I
  rw [hcdef]
  field_simp
  rw [hT']
  ring

/-! The card's exact worked steps: `S₀ = K = 100`, `σ = 1/5`, `T = 1`. -/

-- d₂ = (ln(100/100) - (1/5)²/2 · 1) / ((1/5) √1) = -1/10 (the card's -0.100000).
example : (Real.log (100 / 100) - (1 / 5 : ℝ) ^ 2 / 2 * 1) / ((1 / 5) * Real.sqrt 1) = -1 / 10 := by
  norm_num
-- The digital pays exactly when W_T > (ln(100/100) + (1/5)²/2 · 1) / (1/5) = 1/10.
example : (Real.log (100 / 100) + (1 / 5 : ℝ) ^ 2 / 2 * 1) / (1 / 5) = 1 / 10 := by
  norm_num
-- The divisor S₀ σ T = 100 · 1/5 · 1 = 20.
example : (100 : ℚ) * (1 / 5) * 1 = 20 := by norm_num
-- D_t W_T³ = 3 W_T²: the slope of w ↦ w³ is 3w².
example (w : ℝ) : deriv (fun x : ℝ => x ^ 3) w = 3 * w ^ 2 := by
  simp
-- The average of W over a year has variance ∫₀¹ (1 - t)² dt = 1/3 (Clark-Ocone, D_t F = T - t).
example : ∫ t in (0 : ℝ)..1, (1 - t) ^ 2 = 1 / 3 := by
  rw [intervalIntegral.integral_comp_sub_left (fun x : ℝ => x ^ 2)]
  norm_num [integral_pow]

#print axioms gaussian_integration_by_parts
#print axioms digital_weighted_average_eq_bell_height
#print axioms malliavin_weight_gives_delta
