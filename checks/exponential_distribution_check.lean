-- Exponential: a constant hazard forces the chance of still waiting to be e^(−λt), the exponential law is exactly the memoryless law for a wait from 0 upward, and its mean is 1/λ, its variance 1/λ² and its median ln 2/λ.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory Set

lemma expMeasure_integral_eq (r : ℝ) (hr : 0 < r) (g : ℝ → ℝ) :
    ∫ x, g x ∂(expMeasure r) = ∫ x in Ioi 0, (r * Real.exp (-(r * x))) * g x := by
  have hpdf : gammaPDF 1 r = exponentialPDF r := rfl
  have hmeas : Measurable (exponentialPDF r) :=
    (measurable_exponentialPDFReal r).ennreal_ofReal
  rw [expMeasure, gammaMeasure, hpdf,
    integral_withDensity_eq_integral_toReal_smul hmeas
      (Filter.Eventually.of_forall fun x => ENNReal.ofReal_lt_top) g]
  rw [← integral_Ici_eq_integral_Ioi]
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Ici 0)]
  · refine setIntegral_congr_fun measurableSet_Ici fun x hx => ?_
    simp only [smul_eq_mul]
    rw [exponentialPDF_of_nonneg hx, ENNReal.toReal_ofReal (by positivity)]
  · intro x hx
    simp only [mem_Ici, not_le] at hx
    simp [exponentialPDF_of_neg hx]

lemma expMeasure_moment (r : ℝ) (hr : 0 < r) (n : ℕ) :
    ∫ x, x ^ n ∂(expMeasure r) = n.factorial / r ^ n := by
  rw [expMeasure_integral_eq r hr]
  have h := Real.integral_rpow_mul_exp_neg_mul_Ioi (a := (n : ℝ) + 1) (by positivity) hr
  rw [Real.Gamma_nat_eq_factorial] at h
  have h2 : ∫ x in Ioi 0, r * Real.exp (-(r * x)) * x ^ n
      = r * ∫ t in Ioi 0, t ^ ((n : ℝ) + 1 - 1) * Real.exp (-(r * t)) := by
    rw [← integral_const_mul]
    refine setIntegral_congr_fun measurableSet_Ioi fun x hx => ?_
    simp only [add_sub_cancel_right, Real.rpow_natCast]
    ring
  rw [h2, h, show ((n : ℝ) + 1) = ((n + 1 : ℕ) : ℝ) by push_cast; ring, Real.rpow_natCast]
  have hr0 : r ≠ 0 := hr.ne'
  rw [one_div, inv_pow, pow_succ]
  field_simp


/-- Only the exponential law forgets. Let μ be the law of a wait: a probability measure on the
real line that gives no chance to negative waits and is not the wait of 0 with certainty. Then
the wait is memoryless, P(T > s + t) = P(T > s) · P(T > t) for all s, t ≥ 0 (so that, given
s quiet minutes, the chance of t more is the same as from a fresh start), exactly when μ is the
exponential law with some rate λ > 0. -/
theorem memoryless_iff_exponential (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (hneg : μ (Iio 0) = 0) (hpos : μ (Ioi 0) ≠ 0) :
    (∀ s t : ℝ, 0 ≤ s → 0 ≤ t → μ (Ioi (s + t)) = μ (Ioi s) * μ (Ioi t)) ↔
      ∃ r : ℝ, 0 < r ∧ μ = expMeasure r := by
  constructor
  · intro hmem
    set f : ℝ → ℝ := fun t => μ.real (Ioi t) with hf
    have hfmul : ∀ s t, 0 ≤ s → 0 ≤ t → f (s + t) = f s * f t := by
      intro s t hs ht
      simp only [hf, measureReal_def, hmem s t hs ht, ENNReal.toReal_mul]
    have hcdf : ∀ t, f t = 1 - cdf μ t := by
      intro t
      rw [cdf_eq_real, hf]
      simp only
      rw [← compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic]
    have hanti : ∀ s t, s ≤ t → f t ≤ f s := by
      intro s t hst
      rw [hcdf, hcdf]
      linarith [monotone_cdf μ hst]
    have hle1 : ∀ t, f t ≤ 1 := fun t => by rw [hcdf]; linarith [cdf_nonneg μ t]
    have hf0 : f 0 = 1 := by
      have h := hfmul 0 0 le_rfl le_rfl
      simp only [add_zero] at h
      have hne : f 0 ≠ 0 := by
        simp only [hf, measureReal_def]
        exact ENNReal.toReal_ne_zero.2 ⟨hpos, measure_ne_top μ _⟩
      exact mul_left_cancel₀ hne (h.symm.trans (mul_one _).symm)
    have hpow : ∀ n : ℕ, ∀ u, 0 ≤ u → f (n * u) = f u ^ n := by
      intro n u hu
      induction n with
      | zero => simp [hf0]
      | succ n ih =>
        push_cast
        rw [add_mul, one_mul, hfmul _ _ (by positivity) hu, ih, pow_succ]
    have hfpos : ∀ t, 0 ≤ t → 0 < f t := by
      have hc := (cdf μ).right_continuous 0
      rw [Metric.continuousWithinAt_iff] at hc
      obtain ⟨δ, hδ, hδ'⟩ := hc (1 / 2) (by norm_num)
      have hc0 : cdf μ 0 = 0 := by linarith [hcdf 0]
      intro t ht
      obtain ⟨n, hn⟩ := exists_nat_gt (t / δ)
      have hnpos : (0 : ℝ) < n := lt_of_le_of_lt (by positivity) hn
      have hu : 0 ≤ t / n := by positivity
      have hlt : t / n < δ := by
        rw [div_lt_iff₀ hnpos]
        rw [div_lt_iff₀ hδ] at hn
        linarith
      have hfu : 0 < f (t / n) := by
        have := hδ' (x := t / n) hu (by rw [Real.dist_eq, sub_zero, abs_of_nonneg hu]; exact hlt)
        rw [Real.dist_eq, hc0, sub_zero] at this
        rw [hcdf]
        linarith [le_abs_self (cdf μ (t / n))]
      have := hpow n (t / n) hu
      rw [mul_div_cancel₀ _ hnpos.ne'] at this
      rw [this]
      exact pow_pos hfu n
    have hf1 : f 1 < 1 := by
      by_contra hcon
      have h1 : f 1 = 1 := le_antisymm (hle1 1) (not_lt.1 hcon)
      have hev := (tendsto_cdf_atTop μ).eventually (lt_mem_nhds (by norm_num : (1 / 2 : ℝ) < 1))
      obtain ⟨a, ha⟩ := Filter.eventually_atTop.1 hev
      obtain ⟨n, hn⟩ := exists_nat_ge a
      have h2 := ha n hn
      have h3 := hpow n 1 zero_le_one
      rw [mul_one, h1, one_pow, hcdf] at h3
      linarith
    set r := -Real.log (f 1) with hr_def
    have hr : 0 < r := by
      have := Real.log_neg (hfpos 1 zero_le_one) hf1
      linarith
    have hnat : ∀ m n : ℕ, 0 < n → f (m / n) = Real.exp (-(r * (m / n))) := by
      intro m n hn
      have hnR : (0 : ℝ) < n := by exact_mod_cast hn
      have hpos' : 0 < f (m / n) := hfpos _ (by positivity)
      have e1 := hpow n (m / n) (by positivity)
      rw [mul_div_cancel₀ _ hnR.ne'] at e1
      have e2 := hpow m 1 zero_le_one
      rw [mul_one] at e2
      have e3 : (n : ℝ) * Real.log (f (m / n)) = m * Real.log (f 1) := by
        rw [← Real.log_pow, ← Real.log_pow, ← e1, ← e2]
      rw [← Real.exp_log hpos']
      congr 1
      rw [hr_def]
      field_simp
      linarith
    have hrat : ∀ q : ℚ, 0 ≤ q → f q = Real.exp (-(r * q)) := by
      intro q hq
      have hnum : (q.num.toNat : ℤ) = q.num := Int.toNat_of_nonneg (Rat.num_nonneg.2 hq)
      have hq' : (q : ℝ) = (q.num.toNat : ℝ) / (q.den : ℝ) := by
        rw [Rat.cast_def]
        congr 1
        exact_mod_cast hnum.symm
      rw [hq']
      exact hnat _ _ q.den_pos
    have hexp : ∀ t, 0 ≤ t → f t = Real.exp (-(r * t)) := by
      intro t ht
      have hft := hfpos t ht
      set τ := -Real.log (f t) / r with hτ
      have hτe : Real.exp (-(r * τ)) = f t := by
        rw [hτ, mul_div_cancel₀ _ hr.ne', neg_neg, Real.exp_log hft]
      by_contra hne
      rcases lt_or_gt_of_ne hne with hlt | hgt
      · rw [← hτe, Real.exp_lt_exp] at hlt
        have htτ : t < τ := by nlinarith
        obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn htτ
        have hq0 : (0 : ℝ) ≤ q := le_trans ht hq1.le
        have hfq := hrat q (by exact_mod_cast hq0)
        have h1 : f t < f q := by
          rw [hfq, ← hτe, Real.exp_lt_exp]; nlinarith
        linarith [hanti t q hq1.le]
      · rw [← hτe, Real.exp_lt_exp] at hgt
        have htτ : τ < t := by nlinarith
        have hτ0 : 0 ≤ τ := by
          rw [hτ]
          apply div_nonneg _ hr.le
          linarith [Real.log_nonpos hft.le (hle1 t)]
        obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn htτ
        have hq0 : (0 : ℝ) ≤ q := le_trans hτ0 hq1.le
        have hfq := hrat q (by exact_mod_cast hq0)
        have h1 : f q < f t := by
          rw [hfq, ← hτe, Real.exp_lt_exp]; nlinarith
        linarith [hanti q t hq2.le]
    refine ⟨r, hr, ?_⟩
    have := isProbabilityMeasure_expMeasure hr
    apply Measure.eq_of_cdf
    ext x
    rw [cdf_expMeasure_eq hr]
    split_ifs with hx
    · have := hcdf x
      rw [hexp x hx] at this
      linarith
    · rw [cdf_eq_real]
      apply le_antisymm _ measureReal_nonneg
      calc μ.real (Iic x) ≤ μ.real (Iio 0) :=
            measureReal_mono (Iic_subset_Iio.2 (not_le.1 hx))
        _ = 0 := by rw [measureReal_def, hneg, ENNReal.toReal_zero]
  · rintro ⟨r, hr, rfl⟩ s t hs ht
    have key : ∀ x, 0 ≤ x → expMeasure r (Ioi x) = ENNReal.ofReal (Real.exp (-(r * x))) := by
      intro x hx
      have hle : 0 ≤ 1 - Real.exp (-(r * x)) :=
        sub_nonneg.2 (Real.exp_le_one_iff.2 (by nlinarith))
      rw [← compl_Iic, prob_compl_eq_one_sub measurableSet_Iic, ← ofReal_cdf,
        cdf_expMeasure_eq hr, ite_eq_left_of_eq_true _ _ (eq_true hx), ← ENNReal.ofReal_one, ← ENNReal.ofReal_sub _ hle]
      congr 1
      ring
    rw [key _ (add_nonneg hs ht), key s hs, key t ht, ← ENNReal.ofReal_mul (Real.exp_pos _).le,
      ← Real.exp_add]
    congr 2
    ring

/-- A constant hazard forces the exponential survival curve. Let λ > 0 and let S(t), the chance
of still waiting after t minutes, start at S(0) = 1, be continuous from 0 on, and fall at a rate
proportional to itself, S'(t) = −λ S(t) for t > 0 (the hazard −S'/S is the constant λ). Then
S(t) = e^(−λt) for every t ≥ 0. -/
theorem constant_hazard_survival_eq_exp (S : ℝ → ℝ) (lam : ℝ) (hlam : 0 < lam)
    (h0 : S 0 = 1) (hcont : ContinuousOn S (Ici 0))
    (hderiv : ∀ t : ℝ, 0 < t → HasDerivAt S (-lam * S t) t) :
    ∀ t : ℝ, 0 ≤ t → S t = Real.exp (-(lam * t)) := by
  intro t ht
  rcases ht.eq_or_lt with rfl | ht
  · simp [h0]
  set g : ℝ → ℝ := fun x => S x * Real.exp (lam * x) with hg
  have hgc : ContinuousOn g (Icc 0 t) :=
    (hcont.mono Icc_subset_Ici_self).mul
      (Real.continuous_exp.comp (continuous_const.mul continuous_id)).continuousOn
  have hgd : ∀ x ∈ Ioo 0 t, HasDerivAt g 0 x := by
    intro x hx
    have h1 := hderiv x hx.1
    have h2 : HasDerivAt (fun y => Real.exp (lam * y)) (Real.exp (lam * x) * lam) x := by
      simpa using ((hasDerivAt_id x).const_mul lam).exp
    convert h1.mul h2 using 1
    ring
  obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope g (fun _ => 0) ht hgc hgd
  have hgt : g t = g 0 := by
    have h := hc'.symm
    rw [div_eq_zero_iff] at h
    rcases h with h | h
    · linarith
    · linarith
  simp only [hg, h0, mul_zero, Real.exp_zero, mul_one] at hgt
  have hpos := Real.exp_pos (lam * t)
  rw [Real.exp_neg]
  field_simp
  linarith

/-- The mean, the spread and the median. For the exponential law with rate λ > 0, the mean wait
is 1/λ, the variance is 1/λ², and the median ln 2/λ splits the waits in half:
P(T ≤ ln 2/λ) = 1/2. -/
theorem exponential_mean_variance_median (r : ℝ) (hr : 0 < r) :
    ∫ x, x ∂(expMeasure r) = 1 / r ∧
    variance id (expMeasure r) = 1 / r ^ 2 ∧
    (expMeasure r).real (Iic (Real.log 2 / r)) = 1 / 2 := by
  have := isProbabilityMeasure_expMeasure hr
  have h1 : ∫ x, x ∂(expMeasure r) = 1 / r := by
    have := expMeasure_moment r hr 1
    simpa using this
  have h2 : ∫ x, x ^ 2 ∂(expMeasure r) = 2 / r ^ 2 := by
    have := expMeasure_moment r hr 2
    simpa using this
  refine ⟨h1, ?_, ?_⟩
  · have hint : Integrable (fun x : ℝ => x ^ 2) (expMeasure r) := by
      apply Integrable.of_integral_ne_zero
      rw [h2]
      positivity
    have hmem : MemLp id 2 (expMeasure r) :=
      (memLp_two_iff_integrable_sq aestronglyMeasurable_id).2 hint
    rw [variance_eq_sub hmem]
    simp only [Pi.pow_apply, id]
    rw [h2, h1]
    field_simp
    ring
  · rw [← cdf_eq_real, cdf_expMeasure_eq hr, ite_eq_left_of_eq_true _ _ (eq_true (by positivity)),
      mul_div_cancel₀ _ hr.ne', Real.exp_neg, Real.exp_log two_pos]
    norm_num

-- The rate: 12 emails per hour is 12/60 = 1/5 per minute.
example : (12 : ℚ) / 60 = 1 / 5 := by norm_num
-- Mean wait 1/λ = 5 minutes; E[T²] = 2/λ² = 50; variance 50 − 5² = 25 = 1/λ²; spread 5 = mean.
example : 1 / ((1 : ℚ) / 5) = 5 := by norm_num
example : 2 / ((1 : ℚ) / 5) ^ 2 = 50 := by norm_num
example : (50 : ℚ) - 5 ^ 2 = 25 ∧ 1 / ((1 : ℚ) / 5) ^ 2 = 25 := by norm_num
-- The exponents λt at 5, 10 and 15 minutes are 1, 2 and 3.
example : (1 : ℚ) / 5 * 5 = 1 ∧ (1 : ℚ) / 5 * 10 = 2 ∧ (1 : ℚ) / 5 * 15 = 3 := by norm_num
-- Memoryless at the desk: P(T > 15) / P(T > 10) = e^(−3) / e^(−2) = e^(−1) = P(T > 5).
example : Real.exp (-3) / Real.exp (-2) = Real.exp (-1) := by
  rw [← Real.exp_sub]; norm_num
-- One-minute slices with chance 1/5 each: quiet for 10 minutes has chance (4/5)^10.
example : (1 - (1 : ℚ) / 5) ^ 10 = 1048576 / 9765625 := by norm_num
-- What breaks: a 12-minute mean wait puts the exponent at 10/12 = 5/6, not 2.
example : (10 : ℚ) / 12 = 5 / 6 := by norm_num
-- What breaks: a wait uniform on 10 minutes remembers: P(T > 7 | T > 5) = 3/5, fresh P(T > 2) = 4/5.
example : ((10 : ℚ) - 7) / (10 - 5) = 3 / 5 ∧ ((10 : ℚ) - 2) / 10 = 4 / 5 := by norm_num

#print axioms expMeasure_integral_eq
#print axioms expMeasure_moment
#print axioms memoryless_iff_exponential
#print axioms constant_hazard_survival_eq_exp
#print axioms exponential_mean_variance_median
