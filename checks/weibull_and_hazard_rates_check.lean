-- Weibull and hazards: a lifetime whose hazard is a power of age has survival chance e^(-(t/η)^k), the shape k says whether old survivors are safer, the same, or worse off than new ones, and the area under that survival curve is η Γ(1 + 1/k).
import Mathlib.MeasureTheory.Integral.Gamma
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Probability.CDF

open MeasureTheory Real

/-- The survival function of a lifetime law `μ` on the real line: `S(t) = P(T > t)`. -/
noncomputable def survival (μ : Measure ℝ) (t : ℝ) : ℝ := μ.real (Set.Ioi t)

/-- The hazard at age `t`: the death rate among those still alive, `h(t) = -S'(t) / S(t)`
(for a law with a density `f` this is `f(t) / S(t)`). -/
noncomputable def hazard (μ : Measure ℝ) (t : ℝ) : ℝ := -deriv (survival μ) t / survival μ t

/-- The Weibull survival curve with shape `k` and scale `η`: `S(t) = e^(-(t/η)^k)`. -/
noncomputable def weibullSurvival (k η t : ℝ) : ℝ := Real.exp (-(t / η) ^ k)

lemma survival_eq_one_sub_cdf (μ : Measure ℝ) [IsProbabilityMeasure μ] (t : ℝ) :
    survival μ t = 1 - ProbabilityTheory.cdf μ t := by
  rw [ProbabilityTheory.cdf_eq_real, survival, ← Set.compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic]

lemma sub_add_lt (k a b : ℝ) (hk : k < 1) (ha : 0 < a) (hb : 0 < b) :
    (a + b) ^ k < a ^ k + b ^ k := by
  have hab : 0 < a + b := by linarith
  have h1 : a / (a + b) < (a / (a + b)) ^ k :=
    self_lt_rpow_of_lt_one (by positivity) (by rw [div_lt_one hab]; linarith) hk
  have h2 : b / (a + b) < (b / (a + b)) ^ k :=
    self_lt_rpow_of_lt_one (by positivity) (by rw [div_lt_one hab]; linarith) hk
  rw [div_rpow ha.le hab.le] at h1
  rw [div_rpow hb.le hab.le] at h2
  have hp : 0 < (a + b) ^ k := by positivity
  have : a / (a + b) + b / (a + b) = 1 := by field_simp
  have h3 : 1 < (a ^ k + b ^ k) / (a + b) ^ k := by rw [add_div]; linarith
  rwa [one_lt_div hp] at h3

lemma super_add_lt (k a b : ℝ) (hk : 1 < k) (ha : 0 < a) (hb : 0 < b) :
    a ^ k + b ^ k < (a + b) ^ k := by
  have hab : 0 < a + b := by linarith
  have h1 : (a / (a + b)) ^ k < a / (a + b) :=
    rpow_lt_self_of_lt_one (by positivity) (by rw [div_lt_one hab]; linarith) hk
  have h2 : (b / (a + b)) ^ k < b / (a + b) :=
    rpow_lt_self_of_lt_one (by positivity) (by rw [div_lt_one hab]; linarith) hk
  rw [div_rpow ha.le hab.le] at h1
  rw [div_rpow hb.le hab.le] at h2
  have hp : 0 < (a + b) ^ k := by positivity
  have : a / (a + b) + b / (a + b) = 1 := by field_simp
  have h3 : (a ^ k + b ^ k) / (a + b) ^ k < 1 := by rw [add_div]; linarith
  rwa [div_lt_one hp] at h3

#print axioms survival_eq_one_sub_cdf
#print axioms sub_add_lt
#print axioms super_add_lt

/-- A power-law hazard forces the Weibull law. Let `T` be a lifetime that is positive, whose
survival curve `S(t) = P(T > t)` stays above 0 and is smooth (has a slope) at every positive age.
If the hazard at every positive age is `h(t) = (k/η)(t/η)^(k-1)`, with shape `k > 0` and scale
`η > 0`, then the chance of still being alive at every age `t ≥ 0` is `S(t) = e^(-(t/η)^k)`. -/
theorem power_law_hazard_forces_weibull (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (k η : ℝ) (hk : 0 < k) (hη : 0 < η)
    (hT : μ (Set.Iic 0) = 0)
    (hpos : ∀ t, 0 < t → 0 < survival μ t)
    (hdiff : ∀ t, 0 < t → DifferentiableAt ℝ (survival μ) t)
    (hhaz : ∀ t, 0 < t → hazard μ t = k / η * (t / η) ^ (k - 1)) :
    ∀ t, 0 ≤ t → survival μ t = weibullSurvival k η t := by
  intro t ht
  set S := survival μ with hSdef
  have hS0 : S 0 = 1 := by
    rw [hSdef, survival_eq_one_sub_cdf, ProbabilityTheory.cdf_eq_real, measureReal_def, hT]
    simp
  rcases ht.eq_or_lt with h0 | htpos
  · subst h0
    rw [hS0, weibullSurvival, zero_div, Real.zero_rpow hk.ne', neg_zero, Real.exp_zero]
  set f : ℝ → ℝ := fun x => S x * Real.exp ((x / η) ^ k) with hf
  have hderiv : ∀ x, 0 < x → HasDerivAt f 0 x := by
    intro x hx
    have hS := (hdiff x hx).hasDerivAt
    have hpow : HasDerivAt (fun y : ℝ => (y / η) ^ k) (1 / η * k * (x / η) ^ (k - 1)) x :=
      ((hasDerivAt_id x).div_const η).rpow_const (Or.inl (div_pos hx hη).ne')
    have hE := hpow.exp
    have hprod := hS.mul hE
    have hh := hhaz x hx
    have hSx := hpos x hx
    unfold hazard at hh
    rw [div_eq_iff hSx.ne'] at hh
    convert hprod using 1
    rw [← hSdef] at hh
    have : deriv S x = -(k / η * (x / η) ^ (k - 1) * S x) := by linarith
    rw [this]; ring
  have hcont0 : ContinuousWithinAt S (Set.Ici 0) 0 := by
    have h := ((ProbabilityTheory.cdf μ).right_continuous 0).const_sub 1
    refine ContinuousWithinAt.congr h (fun y _ => ?_) ?_
    · rw [hSdef, survival_eq_one_sub_cdf]
    · rw [hSdef, survival_eq_one_sub_cdf]
  have hcont : ContinuousOn f (Set.Icc 0 t) := by
    intro x hx
    apply ContinuousWithinAt.mul
    · rcases hx.1.eq_or_lt with h0 | hxpos
      · subst h0
        exact hcont0.mono Set.Icc_subset_Ici_self
      · exact (hdiff x hxpos).continuousAt.continuousWithinAt
    · apply ContinuousAt.continuousWithinAt
      apply Real.continuous_exp.continuousAt.comp
      exact ((continuous_id.div_const η).continuousAt).rpow_const (Or.inr hk.le)
  obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope f (fun _ => (0 : ℝ)) htpos hcont
    (fun x hx => hderiv x hx.1)
  have hfeq : f t = f 0 := by
    have hne : t - 0 ≠ 0 := by linarith
    rw [eq_div_iff hne] at hc'
    linarith
  have hf0 : f 0 = 1 := by
    simp only [hf, hS0, zero_div, Real.zero_rpow hk.ne', Real.exp_zero, mul_one]
  rw [hf0] at hfeq
  simp only [hf] at hfeq
  rw [weibullSurvival, Real.exp_neg]
  exact eq_inv_of_mul_eq_one_left hfeq

/-- Reading the shape. For a Weibull lifetime, the chance that a unit already alive at age `s`
lasts `t` more, `S(s + t) / S(s)`, compared with a new unit lasting `t`, `S(t)`, for any ages
`s, t > 0`: below shape 1 the old unit is safer, at shape 1 the two are equal (no memory), above
shape 1 the old unit is worse off (wear-out). -/
theorem weibull_shape_reads_ageing (k η s t : ℝ) (hk : 0 < k) (hη : 0 < η)
    (hs : 0 < s) (ht : 0 < t) :
    (k < 1 → weibullSurvival k η t < weibullSurvival k η (s + t) / weibullSurvival k η s) ∧
    (k = 1 → weibullSurvival k η (s + t) / weibullSurvival k η s = weibullSurvival k η t) ∧
    (1 < k → weibullSurvival k η (s + t) / weibullSurvival k η s < weibullSurvival k η t) := by
  have hq : ∀ x, weibullSurvival k η (s + x) / weibullSurvival k η s
      = Real.exp (-((s / η + x / η) ^ k - (s / η) ^ k)) := by
    intro x
    unfold weibullSurvival
    rw [← Real.exp_sub, add_div]; ring_nf
  have ha : 0 < s / η := div_pos hs hη
  have hb : 0 < t / η := div_pos ht hη
  refine ⟨fun h1 => ?_, fun h1 => ?_, fun h1 => ?_⟩
  · rw [hq]; unfold weibullSurvival
    apply Real.exp_lt_exp.mpr
    have := sub_add_lt k _ _ h1 ha hb
    linarith
  · rw [hq]; unfold weibullSurvival
    subst h1
    simp only [Real.rpow_one]; ring_nf
  · rw [hq]; unfold weibullSurvival
    apply Real.exp_lt_exp.mpr
    have := super_add_lt k _ _ h1 ha hb
    linarith

/-- The average life is the area under the survival curve, and for a Weibull with shape `k > 0`
and scale `η > 0` that area is `η Γ(1 + 1/k)`. -/
theorem weibull_mean_life (k η : ℝ) (hk : 0 < k) (hη : 0 < η) :
    ∫ t in Set.Ioi (0 : ℝ), weibullSurvival k η t = η * Real.Gamma (1 + 1 / k) := by
  have h := integral_comp_mul_right_Ioi (fun x : ℝ => Real.exp (-x ^ k)) 0 (inv_pos.mpr hη)
  simp only [zero_mul, smul_eq_mul, inv_inv] at h
  unfold weibullSurvival
  simp_rw [div_eq_mul_inv]
  rw [h, integral_exp_neg_rpow hk, add_comm, one_mul, one_div]


-- Worked numbers, by hand: shape 3, scale 1,000 hours, a bulb that has burned 800 hours.
-- Cumulative hazard at 800 h: (800/1000)^3 = 64/125 (that is, 0.512).
example : ((800 : ℚ) / 1000) ^ 3 = 64 / 125 := by norm_num
-- Cumulative hazard at 1,000 h: (1000/1000)^3 = 1.
example : ((1000 : ℚ) / 1000) ^ 3 = 1 := by norm_num
-- Hazard at 1,000 h: 3 × 1000^2 / 1000^3 = 3 per 1,000 hours.
example : (3 : ℚ) * 1000 ^ 2 / 1000 ^ 3 = 3 / 1000 := by norm_num
-- A fresh bulb over 200 h: cumulative hazard (200/1000)^3 = 1/125 (0.008).
example : ((200 : ℚ) / 1000) ^ 3 = 1 / 125 := by norm_num
-- The 800-hour bulb over 200 more: hazard packed in is 1 - 64/125 = 61/125 (0.488).
example : ((1000 : ℚ) / 1000) ^ 3 - (800 / 1000) ^ 3 = 61 / 125 := by norm_num
-- Weibull plot: -ln S at 500 h and 1,000 h are 1/8 and 1, a ratio of 8 = 2^3.
example : ((500 : ℚ) / 1000) ^ 3 = 1 / 8 ∧ (8 : ℕ) = 2 ^ 3 := by norm_num
-- Scale back from 500 h: 500^3 × 8 = 1000^3, so 500 / (1/8)^(1/3) = 1,000 hours.
example : (500 : ℕ) ^ 3 * 8 = 1000 ^ 3 := by norm_num

#print axioms power_law_hazard_forces_weibull
#print axioms weibull_shape_reads_ageing
#print axioms weibull_mean_life
