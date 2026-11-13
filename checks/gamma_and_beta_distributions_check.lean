-- Gamma and beta: the wait for k independent exponential events at rate λ has the gamma law, the gamma law's constant is the gamma integral, and the beta integral equals Γ(a)Γ(b)/Γ(a+b).
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Distributions.Beta
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.ComplexMGF
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Real Set

lemma gammaAux_integral_eq {a r : ℝ} (ha : 0 < a) (hr : 0 < r) (g : ℝ → ℝ) :
    ∫ x, g x ∂(gammaMeasure a r) = ∫ x, gammaPDFReal a r x * g x := by
  have e : gammaPDF a r = fun x => ENNReal.ofReal (gammaPDFReal a r x) := rfl
  rw [gammaMeasure, e, integral_withDensity_eq_integral_toReal_smul
    (measurable_gammaPDFReal a r).ennreal_ofReal (ae_of_all _ fun _ => ENNReal.ofReal_lt_top)]
  congr 1 with x
  rw [ENNReal.toReal_ofReal (gammaPDFReal_nonneg ha hr x), smul_eq_mul]

lemma gammaAux_integrable_iff {a r : ℝ} (ha : 0 < a) (hr : 0 < r) (g : ℝ → ℝ) :
    Integrable g (gammaMeasure a r) ↔ Integrable (fun x => gammaPDFReal a r x * g x) := by
  have e : gammaPDF a r = fun x => ENNReal.ofReal (gammaPDFReal a r x) := rfl
  rw [gammaMeasure, e, integrable_withDensity_iff_integrable_smul'
    (measurable_gammaPDFReal a r).ennreal_ofReal (ae_of_all _ fun _ => ENNReal.ofReal_lt_top)]
  refine integrable_congr (ae_of_all _ fun x => ?_)
  simp only [ENNReal.toReal_ofReal (gammaPDFReal_nonneg ha hr x), smul_eq_mul]

lemma gammaAux_pdf_integrable {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    Integrable (gammaPDFReal a r) := by
  have := isProbabilityMeasure_gammaMeasure ha hr
  have h := (gammaAux_integrable_iff ha hr (fun _ => (1 : ℝ))).1 (integrable_const _)
  simpa using h

lemma gammaAux_pdf_integral {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    ∫ x, gammaPDFReal a r x = 1 := by
  have := isProbabilityMeasure_gammaMeasure ha hr
  have h := gammaAux_integral_eq ha hr (fun _ => (1 : ℝ))
  simpa using h.symm

lemma gammaAux_tilt {a r t : ℝ} (hr : 0 ≤ r) (ht : t < r) (x : ℝ) :
    gammaPDFReal a r x * exp (t * x) = (r / (r - t)) ^ a * gammaPDFReal a (r - t) x := by
  have hrt : 0 < r - t := by linarith
  unfold gammaPDFReal
  split_ifs with hx
  · have h1 : exp (-(r * x)) * exp (t * x) = exp (-((r - t) * x)) := by
      rw [← exp_add]; ring_nf
    have h2 : (r / (r - t)) ^ a * (r - t) ^ a = r ^ a := by
      rw [div_rpow hr hrt.le, div_mul_cancel₀ _ (rpow_pos_of_pos hrt a).ne']
    calc r ^ a / Gamma a * x ^ (a - 1) * exp (-(r * x)) * exp (t * x)
        = r ^ a / Gamma a * x ^ (a - 1) * (exp (-(r * x)) * exp (t * x)) := by ring
      _ = (r / (r - t)) ^ a * (r - t) ^ a / Gamma a * x ^ (a - 1) * exp (-((r - t) * x)) := by
          rw [h1, h2]
      _ = _ := by ring
  · simp

lemma gammaAux_integrable_of_lt {a r t : ℝ} (ha : 0 < a) (hr : 0 < r) (ht : t < r) :
    Integrable (fun x => exp (t * x)) (gammaMeasure a r) := by
  rw [gammaAux_integrable_iff ha hr]
  simp_rw [gammaAux_tilt hr.le ht]
  exact (gammaAux_pdf_integrable ha (by linarith)).const_mul _

lemma gammaAux_mgf_of_lt {a r t : ℝ} (ha : 0 < a) (hr : 0 < r) (ht : t < r) :
    mgf id (gammaMeasure a r) t = (r / (r - t)) ^ a := by
  rw [mgf, gammaAux_integral_eq ha hr]
  simp only [id]
  simp_rw [gammaAux_tilt hr.le ht]
  rw [integral_const_mul, gammaAux_pdf_integral ha (by linarith), mul_one]

lemma gammaAux_not_integrable_of_ge {a r t : ℝ} (ha : 1 ≤ a) (hr : 0 < r) (ht : r ≤ t) :
    ¬ Integrable (fun x => exp (t * x)) (gammaMeasure a r) := by
  rw [gammaAux_integrable_iff (by linarith) hr]
  intro h
  have hc : 0 < r ^ a / Gamma a := div_pos (rpow_pos_of_pos hr a) (Gamma_pos_of_pos (by linarith))
  have h2 : IntegrableOn (fun _ : ℝ => r ^ a / Gamma a) (Ioi 1) := by
    refine h.integrableOn.mono' aestronglyMeasurable_const ?_
    refine (ae_restrict_iff' measurableSet_Ioi).2 (ae_of_all _ fun x (hx : 1 < x) => ?_)
    rw [Real.norm_eq_abs, abs_of_pos hc]
    unfold gammaPDFReal
    simp only [show (0:ℝ) ≤ x by linarith, ↓reduceIte]
    have e1 : 1 ≤ x ^ (a - 1) := one_le_rpow hx.le (by linarith)
    have e2 : 1 ≤ exp (-(r * x)) * exp (t * x) := by
      rw [← exp_add]; exact one_le_exp_iff.2 (by nlinarith)
    calc r ^ a / Gamma a = r ^ a / Gamma a * 1 * 1 := by ring
      _ ≤ r ^ a / Gamma a * x ^ (a - 1) * (exp (-(r * x)) * exp (t * x)) := by gcongr
      _ = _ := by ring
  rw [integrableOn_const_iff] at h2
  rcases h2 with h2 | h2
  · simp only [enorm_eq_zero] at h2; linarith
  · simp at h2

#print axioms gammaAux_integral_eq
#print axioms gammaAux_integrable_iff
#print axioms gammaAux_pdf_integrable
#print axioms gammaAux_pdf_integral
#print axioms gammaAux_tilt
#print axioms gammaAux_integrable_of_lt
#print axioms gammaAux_mgf_of_lt
#print axioms gammaAux_not_integrable_of_ge

/-- The wait for several events. Let the gaps `X 0, …, X (k-1)` between events be independent,
each with the exponential law at one steady rate `λ > 0` (a rate per unit of time, not a scale),
and let the number of events awaited `k` be positive. Then the total wait `X 0 + ⋯ + X (k-1)`,
the time of the `k`-th event, has the gamma law with shape `k` and rate `λ`, whose density is
`λ^k t^(k-1) e^(-λt) / Γ(k)` for `t ≥ 0`. -/
theorem wait_for_k_exponential_events_has_gamma_law
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {k : ℕ} (hk : 0 < k) {lam : ℝ} (hlam : 0 < lam) {X : Fin k → Ω → ℝ}
    (hind : iIndepFun X P) (hX : ∀ i, HasLaw (X i) (expMeasure lam) P) :
    HasLaw (fun ω => ∑ i, X i ω) (gammaMeasure k lam) P := by
  have hP : IsProbabilityMeasure P := hind.isProbabilityMeasure
  have hmeas : ∀ i, AEMeasurable (X i) P := fun i => (hX i).aemeasurable
  have hSm : AEMeasurable (fun ω => ∑ i, X i ω) P := by fun_prop
  refine ⟨hSm, ?_⟩
  have hk' : (0 : ℝ) < k := by exact_mod_cast hk
  have hk1 : (1 : ℝ) ≤ k := by exact_mod_cast hk
  have : IsProbabilityMeasure (gammaMeasure k lam) := isProbabilityMeasure_gammaMeasure hk' hlam
  have : IsProbabilityMeasure (P.map (fun ω => ∑ i, X i ω)) := (Measure.isProbabilityMeasure_map_iff hSm).2 hP
  have hmgf : mgf id (P.map (fun ω => ∑ i, X i ω)) = mgf id (gammaMeasure k lam) := by
    ext t
    rw [mgf_id_map hSm]
    have hsum : (fun ω => ∑ i, X i ω) = ∑ i, X i := by ext ω; simp
    rw [hsum, hind.mgf_sum₀ hmeas]
    have hi : ∀ i, mgf (X i) P t = mgf id (expMeasure lam) t := fun i => by
      rw [← mgf_id_map (hmeas i), (hX i).map_eq]
    simp_rw [hi]
    rw [Finset.prod_const, Finset.card_univ, Fintype.card_fin, expMeasure]
    rcases lt_or_ge t lam with ht | ht
    · rw [gammaAux_mgf_of_lt one_pos hlam ht, gammaAux_mgf_of_lt hk' hlam ht, rpow_one,
        rpow_natCast]
    · have h1 : mgf id (gammaMeasure 1 lam) t = 0 :=
        integral_undef (gammaAux_not_integrable_of_ge le_rfl hlam ht)
      have h2 : mgf id (gammaMeasure k lam) t = 0 :=
        integral_undef (gammaAux_not_integrable_of_ge hk1 hlam ht)
      rw [h1, h2, zero_pow hk.ne']
  have hset : integrableExpSet id (gammaMeasure k lam) = Iio lam := by
    ext t
    simp only [integrableExpSet, id, mem_ofPred_eq, mem_Iio]
    constructor
    · intro h
      by_contra hc
      exact gammaAux_not_integrable_of_ge hk1 hlam (not_lt.1 hc) h
    · intro h
      exact gammaAux_integrable_of_lt hk' hlam h
  apply Measure.ext_of_complexMGF_id_eq
  ext z
  by_cases hz : z.re < lam
  · apply eqOn_complexMGF_of_mgf hmgf
    show z.re ∈ interior (integrableExpSet id _)
    rw [integrableExpSet_eq_of_mgf hmgf, hset, interior_Iio]
    exact hz
  · have hng : ¬ Integrable (fun x => exp (z.re * x)) (gammaMeasure k lam) :=
      gammaAux_not_integrable_of_ge hk1 hlam (not_lt.1 hz)
    have hnS : ¬ Integrable (fun x => exp (z.re * x)) (P.map (fun ω => ∑ i, X i ω)) := by
      intro h
      have hm : z.re ∈ integrableExpSet id (P.map (fun ω => ∑ i, X i ω)) := h
      rw [integrableExpSet_eq_of_mgf hmgf, hset] at hm
      exact hz hm
    rw [complexMGF_undef aemeasurable_id hnS, complexMGF_undef aemeasurable_id hng]

/-- The gamma law's constant is the gamma integral. For a positive shape `α` and a positive
rate `λ`, the area under the curve `λ^α t^(α-1) e^(-λt)` over all positive `t` is `Γ(α)`, so
dividing by `Γ(α)` makes the area 1. -/
theorem gamma_density_area_eq_gamma_integral {α lam : ℝ} (hα : 0 < α) (hlam : 0 < lam) :
    ∫ t in Ioi (0 : ℝ), lam ^ α * t ^ (α - 1) * exp (-(lam * t)) = Gamma α := by
  simp_rw [mul_assoc]
  rw [integral_const_mul, integral_rpow_mul_exp_neg_mul_Ioi hα hlam, ← mul_assoc,
    div_rpow zero_le_one hlam.le, one_rpow, mul_one_div_cancel (rpow_pos_of_pos hlam _).ne',
    one_mul]

/-- The beta integral is a ratio of gamma integrals. For positive `a` and `b`, the area under
`v^(a-1) (1-v)^(b-1)` for `v` from 0 to 1 is `Γ(a) Γ(b) / Γ(a+b)`. -/
theorem beta_integral_eq_ratio_of_gamma_integrals {a b : ℝ} (ha : 0 < a) (hb : 0 < b) :
    ∫ v in (0 : ℝ)..1, v ^ (a - 1) * (1 - v) ^ (b - 1) = Gamma a * Gamma b / Gamma (a + b) := by
  have hB := beta_eq_betaIntegralReal a b ha hb
  rw [beta] at hB
  rw [hB, Complex.betaIntegral, intervalIntegral.integral_of_le zero_le_one,
    intervalIntegral.integral_of_le zero_le_one, ← RCLike.re_to_complex, ← integral_re]
  · refine setIntegral_congr_fun measurableSet_Ioc fun x ⟨hx1, hx2⟩ ↦ ?_
    norm_cast
    rw [← Complex.ofReal_cpow, ← Complex.ofReal_cpow, RCLike.re_to_complex,
      Complex.re_mul_ofReal, Complex.ofReal_re]
    all_goals linarith
  · convert Complex.betaIntegral_convergent (u := a) (v := b) (by simpa) (by simpa)
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le (by simp), IntegrableOn]

-- The card's whole-number worked examples, exactly. The rate 0.2 per minute is written 1/5.
-- Γ(k) = (k-1)! for k = 1, 2, 3, 4: the areas 1, 1, 2, 6.
example : Gamma 1 = 1 ∧ Gamma 2 = 1 ∧ Gamma 3 = 2 ∧ Gamma 4 = 6 := by
  simp [Nat.factorial]
-- The prior's constant: B(2, 8) = Γ(2) Γ(8) / Γ(10) = 1! 7! / 9! = 1/72.
example : Gamma 2 * Gamma 8 / Gamma 10 = 1 / 72 := by
  simp [Nat.factorial]
  norm_num
example : (Nat.factorial 1 * Nat.factorial 7 : ℚ) / Nat.factorial 9 = 1 / 72 := by
  norm_num [Nat.factorial]
-- Counting recovers it: n = 2 + 8 - 1 = 9 points, and n · C(n-1, a-1) = 9 · C(8, 1) = 72 = 1/B(2, 8).
example : 2 + 8 - 1 = 9 ∧ 9 * Nat.choose 8 1 = 72 := by decide
-- The desk: λt = (1/5) · 20 = 4 emails expected in 20 minutes, and 1 + 4 + 4²/2 = 13,
-- so P(T > 20) = 13 e^(-4).
example : (1 / 5 : ℚ) * 20 = 4 ∧ (1 : ℚ) + 4 + 4 ^ 2 / 2 = 13 := by norm_num
-- Three emails at rate 1/5: average α/λ = 15, E[T²] = α(α+1)/λ² = 300, variance α/λ² = 75 = 300 - 15²,
-- mode (α-1)/λ = 10.
example : (3 : ℚ) / (1 / 5) = 15 ∧ (3 : ℚ) * 4 / (1 / 5) ^ 2 = 300 ∧
    (3 : ℚ) / (1 / 5) ^ 2 = 75 ∧ (300 : ℚ) - 15 ^ 2 = 75 ∧ ((3 : ℚ) - 1) / (1 / 5) = 10 := by
  norm_num
-- The prior Beta(2, 8): average a/(a+b) = 1/5, E[V²] = a(a+1)/((a+b)(a+b+1)) = 3/55,
-- variance ab/((a+b)²(a+b+1)) = 4/275 = 3/55 - (1/5)², mode (a-1)/(a+b-2) = 1/8.
example : (2 : ℚ) / (2 + 8) = 1 / 5 ∧ (2 : ℚ) * 3 / (10 * 11) = 3 / 55 ∧
    (2 : ℚ) * 8 / ((2 + 8) ^ 2 * (2 + 8 + 1)) = 4 / 275 ∧ (3 : ℚ) / 55 - (1 / 5) ^ 2 = 4 / 275 ∧
    ((2 : ℚ) - 1) / (2 + 8 - 2) = 1 / 8 := by
  norm_num

#print axioms wait_for_k_exponential_events_has_gamma_law
#print axioms gamma_density_area_eq_gamma_integral
#print axioms beta_integral_eq_ratio_of_gamma_integrals
