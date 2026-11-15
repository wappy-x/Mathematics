-- Weak derivatives: a function with a kink but no jump on an interval has a weak derivative, the step of its slopes, which is unique almost everywhere, while a jump has no weak derivative at all.
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts

open MeasureTheory Set
open scoped ContDiff

lemma probe_inner_bounds {K : Set ℝ} {a b : ℝ} (hK : IsCompact K) (hKs : K ⊆ Ioo a b) :
    ∃ δ > 0, ∀ x ∈ K, a + δ < x ∧ x < b - δ := by
  obtain ⟨δ, hδ, hsub⟩ := hK.exists_thickening_subset_open isOpen_Ioo hKs
  refine ⟨δ / 2, by positivity, fun x hx => ⟨?_, ?_⟩⟩
  · have h : x - δ / 2 ∈ Metric.thickening δ K :=
      Metric.mem_thickening_iff.2 ⟨x, hx, by
        rw [Real.dist_eq, show x - δ / 2 - x = -(δ / 2) by ring, abs_neg, abs_of_pos (by positivity)]
        linarith⟩
    have := (hsub h).1
    linarith
  · have h : x + δ / 2 ∈ Metric.thickening δ K :=
      Metric.mem_thickening_iff.2 ⟨x, hx, by
        rw [Real.dist_eq, show x + δ / 2 - x = δ / 2 by ring, abs_of_pos (by positivity)]
        linarith⟩
    have := (hsub h).2
    linarith

lemma interval_integral_eq_of_zero_outside {F : ℝ → ℝ} {a a' b' b : ℝ} (h1 : a ≤ a')
    (h3 : b' ≤ b) (hF : IntervalIntegrable F volume a' b')
    (hz : ∀ t, t ≤ a' ∨ b' ≤ t → F t = 0) :
    ∫ t in a..b, F t = ∫ t in a'..b', F t := by
  have e1 : EqOn F 0 (uIcc a a') := fun t ht => by
    rw [uIcc_of_le h1] at ht; exact hz t (Or.inl ht.2)
  have e3 : EqOn F 0 (uIcc b' b) := fun t ht => by
    rw [uIcc_of_le h3] at ht; exact hz t (Or.inr ht.1)
  have z1 : IntervalIntegrable F volume a a' :=
    (intervalIntegrable_congr (fun t ht => (e1 (uIoc_subset_uIcc ht)).symm)).1
      (intervalIntegrable_const (c := (0 : ℝ)))
  have z3 : IntervalIntegrable F volume b' b :=
    (intervalIntegrable_congr (fun t ht => (e3 (uIoc_subset_uIcc ht)).symm)).1
      (intervalIntegrable_const (c := (0 : ℝ)))
  rw [← intervalIntegral.integral_add_adjacent_intervals z1 (hF.trans z3),
    ← intervalIntegral.integral_add_adjacent_intervals hF z3,
    intervalIntegral.integral_congr e1, intervalIntegral.integral_congr e3]
  simp

lemma interval_integral_eq_integral_probe {f φ : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hφs : tsupport φ ⊆ Ioo a b) :
    ∫ t in a..b, f t * φ t = ∫ t, φ t • f t := by
  rw [intervalIntegral.integral_of_le hab, setIntegral_eq_integral_of_forall_compl_eq_zero]
  · simp [smul_eq_mul, mul_comm]
  · intro x hx
    have : φ x = 0 := image_eq_zero_of_notMem_tsupport (fun h => hx (Ioo_subset_Ioc_self (hφs h)))
    simp [this]

lemma integrable_probe {g φ : ℝ → ℝ} {a b : ℝ} (hg : LocallyIntegrableOn g (Ioo a b))
    (hφ : Continuous φ) (hφc : HasCompactSupport φ) (hφs : tsupport φ ⊆ Ioo a b) :
    Integrable (fun t => φ t • g t) := by
  have h : IntegrableOn (fun t => g t * φ t) (tsupport φ) :=
    (hg.integrableOn_compact_subset hφs hφc).mul_continuousOn hφ.continuousOn hφc
  have h' := h.integrable_of_forall_notMem_eq_zero
    (fun x hx => by simp [image_eq_zero_of_notMem_tsupport hx])
  simpa [smul_eq_mul, mul_comm] using h'

#print axioms probe_inner_bounds
#print axioms interval_integral_eq_of_zero_outside
#print axioms interval_integral_eq_integral_probe
#print axioms integrable_probe

/-- A kink has a weak derivative, the step of its two slopes. On an interval `(a, b)` with a kink
at `c`, let `u` be continuous on `(a, b)` (so it has no jump at the kink), with ordinary slope
`g t` at every `t` other than `c`, and let `g` be integrable on `(a, b)`. Then `g` is the weak
derivative of `u`: for every probe `φ` (smooth, zero outside a closed and bounded piece lying
inside `(a, b)`), the integral of `u φ'` over `(a, b)` is minus the integral of `g φ`. The value
of `g` at the kink itself plays no part. -/
theorem weak_derivative_of_kink_is_step {u g : ℝ → ℝ} {a c b : ℝ} (hac : a < c) (hcb : c < b)
    (hu : ContinuousOn u (Ioo a b))
    (hderiv : ∀ t ∈ Ioo a c ∪ Ioo c b, HasDerivAt u (g t) t)
    (hg : IntervalIntegrable g volume a b)
    (φ : ℝ → ℝ) (hφ : ContDiff ℝ ∞ φ) (hφc : HasCompactSupport φ) (hφs : tsupport φ ⊆ Ioo a b) :
    ∫ t in a..b, u t * deriv φ t = -∫ t in a..b, g t * φ t := by
  obtain ⟨δ, hδ, hK⟩ := probe_inner_bounds hφc hφs
  set a' := min (a + δ) ((a + c) / 2) with ha'
  set b' := max (b - δ) ((c + b) / 2) with hb'
  have h1 : a < a' := lt_min (by linarith) (by linarith)
  have h2 : a' < c := lt_of_le_of_lt (min_le_right _ _) (by linarith)
  have h3 : c < b' := lt_of_lt_of_le (by linarith) (le_max_right _ _)
  have h4 : b' < b := max_lt (by linarith) (by linarith)
  have hsub : Icc a' b' ⊆ Ioo a b := Icc_subset_Ioo h1 h4
  have hout : ∀ t, t ≤ a' ∨ b' ≤ t → t ∉ tsupport φ := by
    intro t ht hmem
    have := hK t hmem
    rcases ht with ht | ht
    · have : a' ≤ a + δ := min_le_left _ _
      linarith
    · have : b - δ ≤ b' := le_max_left _ _
      linarith
  have hφ0 : ∀ t, t ≤ a' ∨ b' ≤ t → φ t = 0 := fun t ht =>
    image_eq_zero_of_notMem_tsupport (hout t ht)
  have hdφ0 : ∀ t, t ≤ a' ∨ b' ≤ t → deriv φ t = 0 := fun t ht =>
    Function.notMem_support.1 (fun h => hout t ht (support_deriv_subset h))
  have hdiff : Differentiable ℝ φ := hφ.differentiable (by simp)
  have hcd : Continuous (deriv φ) := hφ.continuous_deriv (by exact_mod_cast le_top)
  have hdφ : ∀ t, HasDerivAt φ (deriv φ t) t := fun t => (hdiff t).hasDerivAt
  have I1 : IntervalIntegrable (fun t => g t * φ t) volume a b :=
    hg.mul_continuousOn hφ.continuous.continuousOn
  have I1' : IntervalIntegrable (fun t => g t * φ t) volume a' b' :=
    I1.mono_set (by
      rw [uIcc_of_le (h1.trans (h2.trans (h3.trans h4))).le, uIcc_of_le (h2.trans h3).le]
      exact Icc_subset_Icc h1.le h4.le)
  have I2 : IntervalIntegrable (fun t => u t * deriv φ t) volume a' b' :=
    ContinuousOn.intervalIntegrable (by
      rw [uIcc_of_le (h2.trans h3).le]; exact (hu.mono hsub).mul hcd.continuousOn)
  have IF : IntervalIntegrable (fun t => g t * φ t + u t * deriv φ t) volume a' b' := I1'.add I2
  have IFl : IntervalIntegrable (fun t => g t * φ t + u t * deriv φ t) volume a' c :=
    IF.mono_set (by
      rw [uIcc_of_le h2.le, uIcc_of_le (h2.trans h3).le]; exact Icc_subset_Icc le_rfl h3.le)
  have IFr : IntervalIntegrable (fun t => g t * φ t + u t * deriv φ t) volume c b' :=
    IF.mono_set (by
      rw [uIcc_of_le h3.le, uIcc_of_le (h2.trans h3).le]; exact Icc_subset_Icc h2.le le_rfl)
  have hl : ∫ t in a'..c, (g t * φ t + u t * deriv φ t) = u c * φ c - u a' * φ a' :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le h2.le
      ((hu.mono (Icc_subset_Ioo h1 (h3.trans h4))).mul hφ.continuous.continuousOn)
      (fun t ht => (hderiv t (Or.inl ⟨h1.trans ht.1, ht.2⟩)).mul (hdφ t)) IFl
  have hr : ∫ t in c..b', (g t * φ t + u t * deriv φ t) = u b' * φ b' - u c * φ c :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le h3.le
      ((hu.mono (Icc_subset_Ioo (h1.trans h2) h4)).mul hφ.continuous.continuousOn)
      (fun t ht => (hderiv t (Or.inr ⟨ht.1, ht.2.trans h4⟩)).mul (hdφ t)) IFr
  have hsum := intervalIntegral.integral_add_adjacent_intervals IFl IFr
  rw [hl, hr, hφ0 a' (Or.inl le_rfl), hφ0 b' (Or.inr le_rfl),
    intervalIntegral.integral_add I1' I2] at hsum
  rw [interval_integral_eq_of_zero_outside h1.le h4.le I2
      (fun t ht => by simp [hdφ0 t ht]),
    interval_integral_eq_of_zero_outside h1.le h4.le I1'
      (fun t ht => by simp [hφ0 t ht])]
  linarith

/-- There is only one weak derivative, up to single instants. If `g₁` and `g₂` are both locally
integrable on `(a, b)` and both are weak derivatives of the same `u` (each passes the test
against every probe), then `g₁ = g₂` at almost every time in `(a, b)`. -/
theorem weak_derivative_unique_ae {u g₁ g₂ : ℝ → ℝ} {a b : ℝ}
    (hg₁ : LocallyIntegrableOn g₁ (Ioo a b)) (hg₂ : LocallyIntegrableOn g₂ (Ioo a b))
    (h₁ : ∀ φ : ℝ → ℝ, ContDiff ℝ ∞ φ → HasCompactSupport φ → tsupport φ ⊆ Ioo a b →
      ∫ t in a..b, u t * deriv φ t = -∫ t in a..b, g₁ t * φ t)
    (h₂ : ∀ φ : ℝ → ℝ, ContDiff ℝ ∞ φ → HasCompactSupport φ → tsupport φ ⊆ Ioo a b →
      ∫ t in a..b, u t * deriv φ t = -∫ t in a..b, g₂ t * φ t) :
    ∀ᵐ t, t ∈ Ioo a b → g₁ t = g₂ t := by
  by_cases hab : a ≤ b
  · have key := isOpen_Ioo.ae_eq_zero_of_integral_contDiff_smul_eq_zero
      (μ := volume) (f := fun t => g₁ t - g₂ t) (hg₁.sub hg₂) (by
        intro φ hφ hφc hφs
        have e1 := h₁ φ hφ hφc hφs
        have e2 := h₂ φ hφ hφc hφs
        rw [interval_integral_eq_integral_probe hab hφs] at e1 e2
        simp_rw [smul_sub]
        rw [integral_sub (integrable_probe hg₁ hφ.continuous hφc hφs)
          (integrable_probe hg₂ hφ.continuous hφc hφs)]
        linarith)
    filter_upwards [key] with t ht hmem
    exact sub_eq_zero.1 (ht hmem)
  · exact Filter.Eventually.of_forall fun t ht => absurd (ht.1.trans ht.2).le hab

/-- A jump has no weak derivative. The switch that is `0` before time `c` and `J ≠ 0` after it,
on an interval `(a, b)` containing `c`, has no locally integrable function `f` on `(a, b)` that
passes the weak-derivative test against every probe. (Its derivative is `J` times the delta at
`c`, a distribution and not a function, so the switch lies in no `W^{1,p}`.) -/
theorem jump_has_no_weak_derivative {a c b J : ℝ} (hac : a < c) (hcb : c < b) (hJ : J ≠ 0) :
    ¬ ∃ f : ℝ → ℝ, LocallyIntegrableOn f (Ioo a b) ∧
      ∀ φ : ℝ → ℝ, ContDiff ℝ ∞ φ → HasCompactSupport φ → tsupport φ ⊆ Ioo a b →
        ∫ t in a..b, (if c < t then J else 0) * deriv φ t = -∫ t in a..b, f t * φ t := by
  rintro ⟨f, hf, hweak⟩
  have hab : a ≤ b := (hac.trans hcb).le
  have key : ∀ φ : ℝ → ℝ, ContDiff ℝ ∞ φ → HasCompactSupport φ → tsupport φ ⊆ Ioo a b →
      ∫ t in a..b, f t * φ t = J * φ c := by
    intro φ hφ hφc hφs
    have hdiff : Differentiable ℝ φ := hφ.differentiable (by simp)
    have hcd : Continuous (deriv φ) := hφ.continuous_deriv (by exact_mod_cast le_top)
    have hb0 : φ b = 0 := image_eq_zero_of_notMem_tsupport (fun h => (hφs h).2.false)
    set F : ℝ → ℝ := fun t => (if c < t then J else 0) * deriv φ t with hF
    have eqL : EqOn F 0 (uIoc a c) := fun t ht => by
      rw [uIoc_of_le hac.le] at ht
      simp [F, not_lt.2 ht.2]
    have eqR : EqOn F (fun t => J * deriv φ t) (uIoc c b) := fun t ht => by
      rw [uIoc_of_le hcb.le] at ht
      simp [F, ht.1]
    have iL : IntervalIntegrable F volume a c :=
      (intervalIntegrable_congr (fun t ht => (eqL ht).symm)).1
        (intervalIntegrable_const (c := (0 : ℝ)))
    have iR : IntervalIntegrable F volume c b :=
      (intervalIntegrable_congr (fun t ht => (eqR ht).symm)).1
        ((hcd.const_mul J).intervalIntegrable c b)
    have hL : ∫ t in a..b, F t = -(J * φ c) := by
      rw [← intervalIntegral.integral_add_adjacent_intervals iL iR,
        intervalIntegral.integral_congr_ae (Filter.Eventually.of_forall fun t ht => eqL ht),
        intervalIntegral.integral_congr_ae (Filter.Eventually.of_forall fun t ht => eqR ht),
        intervalIntegral.integral_const_mul,
        intervalIntegral.integral_deriv_eq_sub (fun x _ => hdiff x) (hcd.intervalIntegrable c b),
        hb0]
      simp
    have := hweak φ hφ hφc hφs
    rw [hL] at this
    linarith
  set U : Set ℝ := Ioo a b \ {c} with hU
  have hUo : IsOpen U := isOpen_Ioo.sdiff isClosed_singleton
  have hae := hUo.ae_eq_zero_of_integral_contDiff_smul_eq_zero (μ := volume)
    (hf.mono_set sdiff_subset) (by
      intro φ hφ hφc hφs
      have hs : tsupport φ ⊆ Ioo a b := hφs.trans sdiff_subset
      have hc0 : φ c = 0 := image_eq_zero_of_notMem_tsupport (fun h => (hφs h).2 rfl)
      rw [← interval_integral_eq_integral_probe hab hs, key φ hφ hφc hs, hc0, mul_zero])
  set r : ℝ := min (c - a) (b - c) / 2 with hr
  have hr0 : 0 < r := by
    have : 0 < min (c - a) (b - c) := lt_min (by linarith) (by linarith)
    positivity
  have hra : r < c - a := by
    have : min (c - a) (b - c) ≤ c - a := min_le_left _ _
    linarith
  have hrb : r < b - c := by
    have : min (c - a) (b - c) ≤ b - c := min_le_right _ _
    linarith
  let ρ : ContDiffBump c := ⟨r / 2, r, by positivity, by linarith⟩
  have hρs : tsupport ρ ⊆ Ioo a b := by
    rw [ρ.tsupport_eq, Real.closedBall_eq_Icc]
    exact Icc_subset_Ioo (by linarith) (by linarith)
  have hρc : ρ c = 1 := ρ.one_of_mem_closedBall (Metric.mem_closedBall_self (by positivity))
  have h1 := key ρ ρ.contDiff ρ.hasCompactSupport hρs
  rw [interval_integral_eq_integral_probe hab hρs, hρc, mul_one] at h1
  have h0 : ∫ t, ρ t • f t = 0 := by
    apply integral_eq_zero_of_ae
    filter_upwards [hae, Measure.ae_ne volume c] with t ht htc
    by_cases hmem : t ∈ Ioo a b
    · simp [ht ⟨hmem, htc⟩]
    · simp [image_eq_zero_of_notMem_tsupport (fun h => hmem (hρs h))]
  exact hJ (h1.symm.trans h0)

-- Worked numbers from the card, exactly (MW, hours, MW/h), for the tent u(t) = 4(1 - |t - 1|).
-- The ramps: (4 - 0) MW over 1 h, and (0 - 4) MW over 1 h.
example : ((4 : ℚ) - 0) / 1 = 4 ∧ ((0 : ℚ) - 4) / 1 = -4 := by norm_num
-- The tent is zero at both ends, 17:00 and 19:00, and 4 MW at 18:00, so it lies in H^1_0.
example : (4 : ℝ) * (1 - |0 - 1|) = 0 ∧ (4 : ℝ) * (1 - |2 - 1|) = 0 ∧ (4 : ℝ) * (1 - |1 - 1|) = 4 := by
  norm_num
-- End terms at 18:00 cancel for any probe height φ(1).
example (x : ℝ) : 4 * x - 4 * x = 0 := by ring
-- Squared load 2 × 16/3 = 32/3, squared ramp 16 × 2 = 32, H^1 norm squared 32/3 + 32 = 128/3.
example : (2 : ℚ) * (16 / 3) = 32 / 3 ∧ (16 : ℚ) * 2 = 32 ∧ (32 / 3 : ℚ) + 32 = 128 / 3 := by norm_num
-- W^{1,1} norm: 4 MWh + 8 MW = 12; W^{1,∞} norm: max of 4 MW and 4 MW/h = 4.
example : (4 : ℕ) + 8 = 12 ∧ max (4 : ℕ) 4 = 4 := by decide
-- The ramp jumps by -4 - 4 = -8 at 18:00, so u'' = -8 δ₁.
example : (-4 : ℤ) - 4 = -8 := by decide
-- Grid at N = 4 (h = 1/2, nodes 0, 2, 4, 2, 0): sum u^2 = 12, sum u'^2 = 32, sum u''^2 = 128 = 64/h.
example : (1 / 2 : ℚ) * (0 ^ 2 + 2 ^ 2 + 4 ^ 2 + 2 ^ 2 + 0 ^ 2) = 12 := by norm_num
example : (1 / 2 : ℚ) * (((2 - 0) / (1 / 2)) ^ 2 + ((4 - 2) / (1 / 2)) ^ 2
    + ((2 - 4) / (1 / 2)) ^ 2 + ((0 - 2) / (1 / 2)) ^ 2) = 32 := by norm_num
example : (1 / 2 : ℚ) * (((4 - 2 * 2 + 0) / (1 / 2) ^ 2) ^ 2 + ((2 - 2 * 4 + 2) / (1 / 2) ^ 2) ^ 2
    + ((0 - 2 * 2 + 4) / (1 / 2) ^ 2) ^ 2) = 64 / (1 / 2) := by norm_num
-- Grid sums of u^2 at N = 16 and 64 are 32/3 + 16 h^2 / 3: 43/4 and 2049/192.
example : (32 / 3 : ℚ) + 16 * (1 / 8) ^ 2 / 3 = 43 / 4 := by norm_num
example : (32 / 3 : ℚ) + 16 * (1 / 32) ^ 2 / 3 = 2049 / 192 := by norm_num
-- Second-step sums 64/h at h = 1/8, 1/32, 1/128: 512, 2048, 8192.
example : (64 : ℚ) / (1 / 8) = 512 ∧ (64 : ℚ) / (1 / 32) = 2048 ∧ (64 : ℚ) / (1 / 128) = 8192 := by
  norm_num
-- Rounding the corner at ε = 1/4: H^1 distance squared 8ε³/5 + 32ε/3 = 323/120, bending energy 32/ε = 128.
example : (8 : ℚ) * (1 / 4) ^ 3 / 5 + 32 * (1 / 4) / 3 = 323 / 120 ∧ (32 : ℚ) / (1 / 4) = 128 := by
  norm_num
-- In minutes: value term 32/3 × 60 = 640, slope term 32/60 = 8/15.
example : (32 / 3 : ℚ) * 60 = 640 ∧ (32 : ℚ) / 60 = 8 / 15 := by norm_num

#print axioms weak_derivative_of_kink_is_step
#print axioms weak_derivative_unique_ae
#print axioms jump_has_no_weak_derivative
