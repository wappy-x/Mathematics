-- Hypothesis tests: under a true null, a p-value from a statistic with a continuous law has chance exactly u of being at most u, and an exact p-value from any law has chance at most u.
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Measure.Regular
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

open MeasureTheory

/-- Helper: if a random number `S` lands in an upper set `U` of the line, and each tail
event `t ≤ S` with `t ∈ U` has chance at most `u`, then `S ∈ U` has chance at most `u`. -/
lemma upperSet_preimage_le {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsFiniteMeasure μ] (S : Ω → ℝ) (hS : Measurable S)
    (U : Set ℝ) (hU : IsUpperSet U) (u : ℝ) (hu : 0 ≤ u)
    (h : ∀ t ∈ U, μ.real {ω | t ≤ S ω} ≤ u) :
    μ.real (S ⁻¹' U) ≤ u := by
  have hUm : MeasurableSet U := hU.ordConnected.measurableSet
  by_contra hlt
  push Not at hlt
  have hν : (μ.map S) U = μ (S ⁻¹' U) := Measure.map_apply hS hUm
  have hr : ENNReal.ofReal u < (μ.map S) U := by
    rw [hν, ← ofReal_measureReal]
    exact (ENNReal.ofReal_lt_ofReal_iff_of_nonneg hu).2 hlt
  obtain ⟨K, hKU, hK, hrK⟩ :=
    hUm.exists_lt_isCompact_of_ne_top (measure_ne_top (μ.map S) U) hr
  rcases K.eq_empty_or_nonempty with rfl | hne
  · simp at hrK
  · have hm := hK.sInf_mem hne
    have hKsub : K ⊆ Set.Ici (sInf K) := fun x hx => csInf_le hK.bddBelow hx
    have h1 : (μ.map S) K ≤ (μ.map S) (Set.Ici (sInf K)) := measure_mono hKsub
    rw [Measure.map_apply hS measurableSet_Ici] at h1
    have h2 := h (sInf K) (hKU hm)
    have h3 : μ {ω | sInf K ≤ S ω} ≤ ENNReal.ofReal u := by
      rw [← ofReal_measureReal]
      exact ENNReal.ofReal_le_ofReal h2
    exact absurd (hrK.trans_le (h1.trans h3)) (lt_irrefl _)

#print axioms upperSet_preimage_le

/-- Under the null hypothesis, let the statistic `T` (on the card, `T = |Z|`) have a
continuous law, with `G t = P(T ≤ t)`. The p-value of a trial not yet run is the random
number `1 - G T`. Then for every `u` between 0 and 1, the chance that the p-value is at
most `u` is exactly `u`: the p-value is spread evenly between 0 and 1, so the rule
"reject when `p ≤ α`" rejects a true null with chance exactly `α`. -/
theorem p_value_uniform_under_null {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (T : Ω → ℝ) (hT : Measurable T)
    (hG : Continuous fun t : ℝ => μ.real {ω | T ω ≤ t})
    (u : ℝ) (hu0 : 0 ≤ u) (hu1 : u ≤ 1) :
    μ.real {ω | 1 - μ.real {ω' | T ω' ≤ T ω} ≤ u} = u := by
  have hGm : Monotone fun t : ℝ => μ.real {ω | T ω ≤ t} :=
    fun a b hab => measureReal_mono (fun ω (hω : T ω ≤ a) => le_trans hω hab)
  -- Upper bound: the chance is at most `u`.
  have hup : μ.real {ω | 1 - μ.real {ω' | T ω' ≤ T ω} ≤ u} ≤ u := by
    refine upperSet_preimage_le μ T hT {t | 1 - μ.real {ω' | T ω' ≤ t} ≤ u} ?_ u hu0 ?_
    · intro a b hab ha
      simp only [Set.mem_ofPred_eq] at ha ⊢
      linarith [hGm hab]
    · intro t ht
      simp only [Set.mem_ofPred_eq] at ht
      have hlt : μ.real {ω' | T ω' ≤ t} ≤ μ.real {ω' | T ω' < t} := by
        have hlim : Filter.Tendsto (fun s : ℝ => μ.real {ω' | T ω' ≤ s})
            (nhdsWithin t (Set.Iio t)) (nhds (μ.real {ω' | T ω' ≤ t})) :=
          (hG.continuousAt.tendsto).mono_left nhdsWithin_le_nhds
        refine le_of_tendsto hlim ?_
        refine eventually_nhdsWithin_of_forall fun s hs => ?_
        exact measureReal_mono (fun ω (hω : T ω ≤ s) => lt_of_le_of_lt hω hs)
      have hc : {ω | t ≤ T ω} = {ω' | T ω' < t}ᶜ := by
        ext ω; simp
      rw [hc, probReal_compl_eq_one_sub (measurableSet_lt hT measurable_const)]
      linarith
  -- Lower bound: the chance is at least `u`.
  have hlow : u ≤ μ.real {ω | 1 - μ.real {ω' | T ω' ≤ T ω} ≤ u} := by
    have hmeas : MeasurableSet {ω | μ.real {ω' | T ω' ≤ T ω} < 1 - u} :=
      measurableSet_lt (hGm.measurable.comp hT) measurable_const
    have hc : {ω | 1 - μ.real {ω' | T ω' ≤ T ω} ≤ u} =
        {ω | μ.real {ω' | T ω' ≤ T ω} < 1 - u}ᶜ := by
      ext ω; simp only [Set.mem_ofPred_eq, Set.mem_compl_iff, not_lt]
      constructor <;> intro h <;> linarith
    have hpre : {ω | μ.real {ω' | T ω' ≤ T ω} < 1 - u} =
        (fun ω => -T ω) ⁻¹' {s | μ.real {ω' | T ω' ≤ -s} < 1 - u} := by
      ext ω; simp
    have hkey : μ.real {ω | μ.real {ω' | T ω' ≤ T ω} < 1 - u} ≤ 1 - u := by
      rw [hpre]
      refine upperSet_preimage_le μ (fun ω => -T ω) hT.neg _ ?_ (1 - u) (by linarith) ?_
      · intro a b hab ha
        simp only [Set.mem_ofPred_eq] at ha ⊢
        exact lt_of_le_of_lt (hGm (neg_le_neg hab)) ha
      · intro s hs
        simp only [Set.mem_ofPred_eq] at hs
        have he : {ω | s ≤ -T ω} = {ω' | T ω' ≤ -s} := by
          ext ω; simp [le_neg]
        rw [he]
        exact hs.le
    rw [hc, probReal_compl_eq_one_sub hmeas]
    linarith
  exact le_antisymm hup hlow

/-- When the law of the statistic `T` may jump, as it does for counts, the p-value computed
exactly from that law is the chance of a value at least as large, `P(T ≥ t)` at `t = T`.
Under the null it is slightly careful: for every `u` between 0 and 1, the chance that this
p-value is at most `u` is at most `u`. -/
theorem exact_p_value_le_under_null {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (T : Ω → ℝ) (hT : Measurable T)
    (u : ℝ) (hu0 : 0 ≤ u) (hu1 : u ≤ 1) :
    μ.real {ω | μ.real {ω' | T ω ≤ T ω'} ≤ u} ≤ u := by
  refine upperSet_preimage_le μ T hT {t | μ.real {ω' | t ≤ T ω'} ≤ u} ?_ u hu0 ?_
  · intro a b hab ha
    simp only [Set.mem_ofPred_eq] at ha ⊢
    exact le_trans (measureReal_mono (fun ω (hω : b ≤ T ω) => le_trans hab hω)) ha
  · intro t ht
    exact ht

-- The card's worked numbers, as exact fractions.
-- Observed gap: 45/100 - 35/100 = 1/10.
example : (45 : ℚ) / 100 - 35 / 100 = 1 / 10 := by norm_num
-- Pooled rate under the null: 80 of 200 recovered, 2/5 = 0.40.
example : (45 + 35 : ℚ) / 200 = 2 / 5 := by norm_num
-- Variance of the gap: 0.40 × 0.60 × 2 / 100 = 0.0048 = 3/625.
example : (2 / 5 : ℚ) * (1 - 2 / 5) * (2 / 100) = 3 / 625 := by norm_num
-- z squared: 0.10² / 0.0048 = 25/12, so z = 1.443376...
example : ((1 / 10 : ℚ) ^ 2) / (3 / 625) = 25 / 12 := by norm_num
-- Four times the patients, same gap (180/400 vs 140/400): z squared is 4 × 25/12, so z doubles.
example : ((180 : ℚ) / 400 - 140 / 400) ^ 2 /
    ((320 / 800) * (1 - 320 / 800) * (2 / 400)) = 4 * (25 / 12) := by norm_num
-- Every pair of counts, 0 to 100 recoveries in each group: 101 × 101 = 10,201 pairs.
example : (Finset.range 101 ×ˢ Finset.range 101).card = 10201 := by
  norm_num [Finset.card_product]

#print axioms p_value_uniform_under_null
#print axioms exact_p_value_le_under_null
