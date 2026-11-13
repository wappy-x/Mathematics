-- Inverse transform: feeding a uniform draw on [0, 1] into a law's quantile (the least value whose cumulative chance reaches the draw) produces exactly that law, the quantile sits at or below x exactly when the draw sits at or below the cumulative chance at x, and the exponential law's quantile is −ln(1 − u)/λ.
import Mathlib.Probability.Distributions.Uniform
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw

open MeasureTheory ProbabilityTheory

/-- Helper: the quantile of a chance strictly between 0 and 1 is a least element, and
the quantile sits at or below x exactly when the chance sits at or below the CDF at x. -/
theorem quantile_aux (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (u : ℝ) (hu : u ∈ Set.Ioo 0 1) :
    IsLeast {y : ℝ | u ≤ cdf μ y} (sInf {y : ℝ | u ≤ cdf μ y}) ∧
      ∀ x : ℝ, sInf {y : ℝ | u ≤ cdf μ y} ≤ x ↔ u ≤ cdf μ x := by
  obtain ⟨hu0, hu1⟩ := hu
  set S := {y : ℝ | u ≤ cdf μ y} with hS
  have hne : S.Nonempty := by
    have h := (tendsto_cdf_atTop (μ := μ)).eventually (lt_mem_nhds hu1)
    obtain ⟨y, hy⟩ := h.exists
    exact ⟨y, hy.le⟩
  have hbdd : BddBelow S := by
    have h := (tendsto_cdf_atBot (μ := μ)).eventually (gt_mem_nhds hu0)
    obtain ⟨b, hb⟩ := Filter.eventually_atBot.mp h
    refine ⟨b, fun y hy => ?_⟩
    by_contra hlt
    push Not at hlt
    exact absurd (hb y hlt.le) (not_lt.mpr hy)
  set m := sInf S
  have hmem : m ∈ S := by
    have hc : ContinuousWithinAt (cdf μ) (Set.Ioi m) m :=
      ((cdf μ).right_continuous m).mono Set.Ioi_subset_Ici_self
    show u ≤ cdf μ m
    refine ge_of_tendsto hc (eventually_nhdsWithin_of_forall fun y hy => ?_)
    obtain ⟨s, hs, hsy⟩ := exists_lt_of_csInf_lt hne (Set.mem_Ioi.mp hy)
    exact le_trans hs (monotone_cdf μ hsy.le)
  have hleast : IsLeast S m := ⟨hmem, fun y hy => csInf_le hbdd hy⟩
  refine ⟨hleast, fun x => ⟨fun hx => le_trans hmem (monotone_cdf μ hx), fun hx => csInf_le hbdd hx⟩⟩

#print axioms quantile_aux

/-- The inverse-transform method. Let μ be any law on the real line, with cumulative
distribution function F = cdf μ, and let U be a draw that is uniform on [0, 1] under P.
Write Q(u) for the quantile: the least x with F(x) ≥ u. Then Q(U) follows the law μ:
the values returned have exactly the chosen distribution, so in particular
P(Q(U) ≤ x) = F(x) for every x. -/
theorem inverse_transform_sampling {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (U : Ω → ℝ) (hU : pdf.IsUniform U (Set.Icc 0 1) P) :
    HasLaw (fun ω => sInf {x : ℝ | U ω ≤ cdf μ x}) μ P := by
  set Q : ℝ → ℝ := fun u => sInf {x : ℝ | u ≤ cdf μ x} with hQ
  have hmapU : P.map U = volume.restrict (Set.Icc (0:ℝ) 1) := by
    rw [hU.map_eq, ProbabilityTheory.cond, Real.volume_Icc]; simp
  have hmono : MonotoneOn Q (Set.Ioo 0 1) := by
    intro u hu v hv huv
    rw [hQ]; dsimp only
    rw [(quantile_aux μ u hu).2]
    exact le_trans huv (quantile_aux μ v hv).1.1
  have hQae : AEMeasurable Q (P.map U) := by
    rw [hmapU, Measure.restrict_congr_set Ioo_ae_eq_Icc.symm]
    exact aemeasurable_restrict_of_monotoneOn measurableSet_Ioo hmono
  have hcomp : AEMeasurable (Q ∘ U) P := hQae.comp_aemeasurable hU.aemeasurable
  refine ⟨hcomp, ?_⟩
  have : IsProbabilityMeasure P := hU.isProbabilityMeasure (by simp) (by simp)
  show P.map (Q ∘ U) = μ
  refine Measure.ext_of_Iic _ _ fun x => ?_
  rw [← AEMeasurable.map_map_of_aemeasurable hQae hU.aemeasurable,
    Measure.map_apply_of_aemeasurable hQae measurableSet_Iic, hmapU,
    Measure.restrict_apply' measurableSet_Icc, ← ofReal_cdf]
  have hF0 := cdf_nonneg μ x
  have hF1 := cdf_le_one μ x
  calc volume (Q ⁻¹' Set.Iic x ∩ Set.Icc 0 1)
      = volume (Q ⁻¹' Set.Iic x ∩ Set.Ioo 0 1) :=
        measure_congr (Filter.EventuallyEqSet.rfl.inter Ioo_ae_eq_Icc.symm)
    _ = volume (Set.Iic (cdf μ x) ∩ Set.Ioo 0 1) := by
        congr 1
        ext u
        simp only [Set.mem_inter_iff, Set.mem_preimage, Set.mem_Iic]
        constructor
        · rintro ⟨h1, h2⟩
          exact ⟨(quantile_aux μ u h2).2 x |>.mp h1, h2⟩
        · rintro ⟨h1, h2⟩
          exact ⟨(quantile_aux μ u h2).2 x |>.mpr h1, h2⟩
    _ = volume (Set.Iic (cdf μ x) ∩ Set.Icc 0 1) :=
        measure_congr (Filter.EventuallyEqSet.rfl.inter Ioo_ae_eq_Icc)
    _ = ENNReal.ofReal (cdf μ x) := by
        rw [show Set.Iic (cdf μ x) ∩ Set.Icc 0 1 = Set.Icc 0 (cdf μ x) by
          ext u; simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_Icc]; constructor
          · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
          · rintro ⟨h1, h2⟩; exact ⟨h2, h1, by linarith⟩]
        simp

/-- The quantile is a true minimum and the CDF run backwards. For any law μ on the real
line with CDF F and any chance u strictly between 0 and 1, the values x with F(x) ≥ u have a
least element Q(u), and for every x, Q(u) ≤ x holds exactly when u ≤ F(x). This holds for
smooth curves, staircases and flat stretches alike. -/
theorem quantile_isLeast_and_le_iff (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (u : ℝ) (hu : u ∈ Set.Ioo 0 1) :
    IsLeast {y : ℝ | u ≤ cdf μ y} (sInf {y : ℝ | u ≤ cdf μ y}) ∧
      ∀ x : ℝ, sInf {y : ℝ | u ≤ cdf μ y} ≤ x ↔ u ≤ cdf μ x := by
  exact quantile_aux μ u hu

/-- The exponential quantile. For the exponential law with rate r > 0, whose CDF is
F(t) = 1 − e^(−rt) for t ≥ 0, the quantile of any chance u strictly between 0 and 1 is
Q(u) = −ln(1 − u)/r. -/
theorem exponential_quantile_eq (r : ℝ) (hr : 0 < r) (u : ℝ) (hu : u ∈ Set.Ioo 0 1) :
    sInf {t : ℝ | u ≤ cdf (expMeasure r) t} = -Real.log (1 - u) / r := by
  have := isProbabilityMeasure_expMeasure hr
  obtain ⟨hleast, hiff⟩ := quantile_isLeast_and_le_iff (expMeasure r) u hu
  obtain ⟨hu0, hu1⟩ := hu
  set q := -Real.log (1 - u) / r with hq
  have h1u : 0 < 1 - u := by linarith
  have hlog : Real.log (1 - u) < 0 := Real.log_neg h1u (by linarith)
  have hq0 : 0 ≤ q := by rw [hq]; exact div_nonneg (by linarith) hr.le
  have hrq : r * q = -Real.log (1 - u) := by rw [hq]; field_simp
  apply le_antisymm
  · rw [hiff, cdf_expMeasure_eq hr]; simp only [hq0, ↓reduceIte]; rw [hrq, neg_neg, Real.exp_log h1u]
    linarith
  · have hm := hleast.1
    simp only [Set.mem_ofPred_eq] at hm
    set m := sInf {t : ℝ | u ≤ cdf (expMeasure r) t}
    rw [cdf_expMeasure_eq hr] at hm
    split_ifs at hm with hm0
    · have h2 : Real.exp (-(r * m)) ≤ 1 - u := by linarith
      have h3 : -(r * m) ≤ Real.log (1 - u) := by
        rwa [← Real.exp_le_exp, Real.exp_log h1u]
      rw [hq, div_le_iff₀ hr]
      linarith
    · linarith

-- Toll booth: rate 1/4 car per minute, so the mean gap is 1/λ = 4 minutes.
example : (1 : ℚ) / (1 / 4) = 4 := by norm_num
-- Mistake 1: multiplying by the rate gives a mean of λ · 1 = 1/4 minute, not 4.
example : (1 / 4 : ℚ) * 1 = 1 / 4 := by norm_num
-- Passengers: chances 1/2, 3/10, 3/20, 1/20 add up to 1.
example : (1 / 2 : ℚ) + 3 / 10 + 3 / 20 + 1 / 20 = 1 := by norm_num
-- Running totals 1/2, 4/5, 19/20, 1.
example : (1 / 2 : ℚ) + 3 / 10 = 4 / 5 := by norm_num
example : (1 / 2 : ℚ) + 3 / 10 + 3 / 20 = 19 / 20 := by norm_num
-- A draw of 87/100 passes 1/2 and 4/5 and first reaches 19/20: it returns 3 passengers.
example : (1 / 2 : ℚ) < 87 / 100 ∧ (4 / 5 : ℚ) < 87 / 100 ∧ (87 / 100 : ℚ) ≤ 19 / 20 := by
  norm_num
-- Mean passenger count: 1·1/2 + 2·3/10 + 3·3/20 + 4·1/20 = 7/4.
example : (1 : ℚ) * (1 / 2) + 2 * (3 / 10) + 3 * (3 / 20) + 4 * (1 / 20) = 7 / 4 := by norm_num
-- Mistake 3: comparing u with each chance alone returns 1 half the time and 4 half the time,
-- for a mean of 5/2.
example : (1 : ℚ) * (1 / 2) + 4 * (1 / 2) = 5 / 2 := by norm_num

#print axioms inverse_transform_sampling
#print axioms quantile_isLeast_and_le_iff
#print axioms exponential_quantile_eq
