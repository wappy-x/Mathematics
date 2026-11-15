-- Function spaces C and Lp: continuous records on [0, 24] are complete under the worst-moment norm, have holes under every average p-norm, and those holes are filled by exactly Lp.
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Topology.ContinuousMap.Compact
import Mathlib.Tactic.NormNum

open MeasureTheory
open scoped ENNReal

/-- The day: times `t` from 0 to 24 hours. -/
abbrev Day : Type := Set.Icc (0 : ℝ) 24

/-- The day's averaging measure: length in hours divided by 24, so that every size is an
average over the day (each hour weighs 1/24). -/
noncomputable def dayMeasure : Measure Day :=
  (24⁻¹ : ℝ≥0∞) • (volume : Measure ℝ).comap ((↑) : Day → ℝ)

/-- The whole day has weight 1. -/
instance : IsProbabilityMeasure dayMeasure := by
  constructor
  rw [dayMeasure, Measure.smul_apply, smul_eq_mul,
    Measure.comap_apply _ Subtype.val_injective
      (fun s hs => (MeasurableEmbedding.subtype_coe measurableSet_Icc).measurableSet_image' hs)
      _ MeasurableSet.univ]
  rw [Set.image_univ, Subtype.range_coe_subtype, Set.ofPred_mem_eq, Real.volume_Icc]
  norm_num [ENNReal.inv_mul_cancel]

/-- Measures of sets of times: the hours they cover, divided by 24. -/
theorem dayMeasure_apply (s : Set Day) :
    dayMeasure s = 24⁻¹ * volume (((↑) : Day → ℝ) '' s) := by
  rw [dayMeasure, Measure.smul_apply, smul_eq_mul,
    (MeasurableEmbedding.subtype_coe measurableSet_Icc).comap_apply]

/-- Every nonempty open set of times has positive weight. -/
instance dayMeasure_isOpenPosMeasure : dayMeasure.IsOpenPosMeasure := by
  refine ⟨fun U hU ⟨x, hx⟩ => ?_⟩
  rw [dayMeasure_apply]
  obtain ⟨ε, hε, hball⟩ := Metric.isOpen_iff.mp hU x hx
  have hxc : (x : ℝ) ∈ closure (Set.Ioo (0 : ℝ) 24) := by
    rw [closure_Ioo (by norm_num)]; exact x.2
  obtain ⟨y, hy, hxy⟩ := Metric.mem_closure_iff.mp hxc ε hε
  have hsub : Set.Ioo (0 : ℝ) 24 ∩ Metric.ball (x : ℝ) ε ⊆ ((↑) : Day → ℝ) '' U := by
    intro z ⟨hz, hzb⟩
    refine ⟨⟨z, Set.Ioo_subset_Icc_self hz⟩, hball ?_, rfl⟩
    simpa [Metric.mem_ball, Subtype.dist_eq] using hzb
  have hpos : 0 < volume (Set.Ioo (0 : ℝ) 24 ∩ Metric.ball (x : ℝ) ε) :=
    (isOpen_Ioo.inter Metric.isOpen_ball).measure_pos _
      ⟨y, hy, by rw [Metric.mem_ball, dist_comm]; exact hxy⟩
  refine mul_ne_zero (by simp) ?_
  exact (hpos.trans_le (measure_mono hsub)).ne'

/-- A narrow spike: worst moment at least 1, average p-norm below any `ε > 0`. -/
theorem exists_spike (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞) {ε : ℝ} (hε : 0 < ε) :
    ∃ g : C(Day, ℝ), 1 ≤ ‖g‖ ∧ ‖ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ g‖ < ε := by
  have hp1 : (1 : ℝ≥0∞) ≤ p := Fact.out
  set r := p.toReal with hr
  have hr1 : 1 ≤ r := by
    rw [hr]; exact ENNReal.toReal_mono hp hp1 |>.trans_eq' (by simp)
  have hr0 : 0 < r := by linarith
  set δ : ℝ := 24 * (ε / 2) ^ r with hδ
  have hδpos : 0 < δ := by positivity
  let g : C(Day, ℝ) := ⟨fun t => max 0 (1 - (t : ℝ) / δ), by fun_prop⟩
  refine ⟨g, ?_, ?_⟩
  · have h0 : (0 : ℝ) ∈ Set.Icc (0 : ℝ) 24 := ⟨le_rfl, by norm_num⟩
    have := ContinuousMap.norm_coe_le_norm g ⟨0, h0⟩
    simpa [g] using this
  · set S : Set Day := {t | (t : ℝ) < δ} with hS
    have hSm : MeasurableSet S := measurableSet_lt (by fun_prop) measurable_const
    have hbound : ∀ t, ‖g t‖ ≤ ‖S.indicator (fun _ => (1 : ℝ)) t‖ := by
      intro t
      by_cases ht : t ∈ S
      · rw [Set.indicator_of_mem ht]
        simp only [g, ContinuousMap.coe_mk, Real.norm_eq_abs, norm_one]
        have t0 : (0 : ℝ) ≤ t := t.2.1
        rw [abs_of_nonneg (le_max_left _ _)]
        refine max_le (by norm_num) ?_
        have : 0 ≤ (t : ℝ) / δ := div_nonneg t0 hδpos.le
        linarith
      · rw [Set.indicator_of_notMem ht]
        simp only [S, Set.mem_ofPred_eq, not_lt] at ht
        simp only [g, ContinuousMap.coe_mk, norm_zero, Real.norm_eq_abs]
        have : 1 ≤ (t : ℝ) / δ := by rw [le_div_iff₀ hδpos]; linarith
        rw [abs_of_nonneg (le_max_left _ _)]
        exact max_le le_rfl (by linarith)
    have hμS : dayMeasure S ≤ ENNReal.ofReal ((ε / 2) ^ r) := by
      rw [dayMeasure_apply]
      have himg : ((↑) : Day → ℝ) '' S ⊆ Set.Ico 0 δ := by
        rintro _ ⟨t, ht, rfl⟩; exact ⟨t.2.1, ht⟩
      calc 24⁻¹ * volume (((↑) : Day → ℝ) '' S) ≤ 24⁻¹ * volume (Set.Ico 0 δ) := by
            gcongr
        _ = ENNReal.ofReal ((ε / 2) ^ r) := by
            rw [Real.volume_Ico, sub_zero, hδ, ENNReal.ofReal_mul (by norm_num),
              ← mul_assoc]
            simp [ENNReal.inv_mul_cancel]
    have hE : eLpNorm (fun t => g t) p dayMeasure ≤ ENNReal.ofReal (ε / 2) := by
      calc eLpNorm (fun t => g t) p dayMeasure
          ≤ eLpNorm (S.indicator fun _ => (1 : ℝ)) p dayMeasure :=
            eLpNorm_mono g.continuous.aestronglyMeasurable hbound
        _ ≤ ‖(1 : ℝ)‖ₑ * dayMeasure S ^ (1 / r) :=
            eLpNorm_indicator_const_le _ p hSm.nullMeasurableSet
        _ ≤ 1 * ENNReal.ofReal ((ε / 2) ^ r) ^ (1 / r) := by
            simp only [enorm_one]
            gcongr
        _ = ENNReal.ofReal (ε / 2) := by
            rw [one_mul, ENNReal.ofReal_rpow_of_nonneg (by positivity) (by positivity), one_div,
              Real.rpow_rpow_inv (by positivity) hr0.ne']
    have hnorm : ‖ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ g‖
        = (eLpNorm (fun t => g t) p dayMeasure).toReal := by
      rw [Lp.norm_def, eLpNorm_congr_ae (ContinuousMap.coeFn_toLp (E := ℝ) dayMeasure g)]
    rw [hnorm]
    calc (eLpNorm (fun t => g t) p dayMeasure).toReal ≤ (ENNReal.ofReal (ε / 2)).toReal :=
          ENNReal.toReal_mono ENNReal.ofReal_ne_top hE
      _ = ε / 2 := ENNReal.toReal_ofReal (by positivity)
      _ < ε := by linarith

/-- Under the worst-moment norm `‖f‖_∞ = sup |f(t)|` (Mathlib's norm on `C(Day, ℝ)`), the
continuous records form a complete space. Under the average p-norm, for `1 ≤ p < ∞`, they sit
inside `L^p[0, 24]` with no two records merged (`toLp` is injective, and its norm is the
p-norm); there they have holes: an average-Cauchy sequence of continuous records can miss its
limit, so `C[0, 24]` under the p-norm is not complete. `L^p[0, 24]` is complete and the
continuous records are dense in it, so `L^p[0, 24]` is the completion of `C[0, 24]` under the
p-norm. -/
theorem completion_of_continuous_records_is_lp (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞) :
    CompleteSpace C(Day, ℝ) ∧
    Function.Injective (ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ) ∧
    ¬ IsComplete (Set.range (ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ)) ∧
    DenseRange (ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ) ∧
    CompleteSpace (Lp ℝ p dayMeasure) := by
  have hinj : Function.Injective (ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ) :=
    ContinuousMap.toLp_injective dayMeasure
  refine ⟨inferInstance, hinj, ?_, ContinuousMap.toLp_denseRange ℝ dayMeasure ℝ hp,
    inferInstance⟩
  intro hc
  obtain ⟨K, hK⟩ := (ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ).antilipschitz_of_injective_of_isClosed_range
    hinj hc.isClosed
  obtain ⟨g, hg1, hg⟩ := exists_spike p hp (ε := 1 / ((K : ℝ) + 1)) (by positivity)
  have h1 := hK.le_mul_dist g 0
  rw [map_zero, dist_zero_right, dist_zero_right] at h1
  have hK0 : (0 : ℝ) ≤ K := K.2
  have h2 : (K : ℝ) * ‖ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ g‖ ≤ K * (1 / ((K : ℝ) + 1)) :=
    mul_le_mul_of_nonneg_left hg.le hK0
  have h3 : (K : ℝ) * (1 / ((K : ℝ) + 1)) < 1 := by
    rw [mul_one_div, div_lt_one (by positivity)]; linarith
  linarith

/-- An average never exceeds the worst moment, and a larger `p` never gives a smaller average:
for `1 ≤ p ≤ q`, `‖f‖_p ≤ ‖f‖_q ≤ ‖f‖_∞` for every continuous record `f` (with `p = 1, q = 2`
this is mean ≤ RMS ≤ worst moment). -/
theorem average_le_higher_average_le_worst_moment (p q : ℝ≥0∞) [Fact (1 ≤ p)] [Fact (1 ≤ q)]
    (hpq : p ≤ q) (f : C(Day, ℝ)) :
    ‖ContinuousMap.toLp (E := ℝ) p dayMeasure ℝ f‖ ≤
        ‖ContinuousMap.toLp (E := ℝ) q dayMeasure ℝ f‖ ∧
      ‖ContinuousMap.toLp (E := ℝ) q dayMeasure ℝ f‖ ≤ ‖f‖ := by
  constructor
  · rw [Lp.norm_def, Lp.norm_def,
      eLpNorm_congr_ae (ContinuousMap.coeFn_toLp (E := ℝ) (p := p) dayMeasure f),
      eLpNorm_congr_ae (ContinuousMap.coeFn_toLp (E := ℝ) (p := q) dayMeasure f)]
    exact ENNReal.toReal_mono (Lp.eLpNorm_ne_top (ContinuousMap.toLp (E := ℝ) q dayMeasure ℝ f) |>
      fun h => by rwa [eLpNorm_congr_ae (ContinuousMap.coeFn_toLp (E := ℝ) (p := q) dayMeasure f)] at h)
      (eLpNorm_le_eLpNorm_of_exponent_le hpq)
  · calc ‖ContinuousMap.toLp (E := ℝ) q dayMeasure ℝ f‖
        ≤ ‖(ContinuousMap.toLp (E := ℝ) q dayMeasure ℝ : C(Day, ℝ) →L[ℝ] Lp ℝ q dayMeasure)‖ * ‖f‖ :=
          ContinuousLinearMap.le_opNorm _ _
      _ ≤ 1 * ‖f‖ := by
          gcongr
          refine (ContinuousMap.toLp_norm_le dayMeasure).trans ?_
          simp [measureUnivNNReal]
      _ = ‖f‖ := one_mul _

/-- The comparison runs one way only: the worst moment can be any number of times the mean.
For every bound `M` there is a nonzero continuous record whose worst moment exceeds `M` times
its mean, so `sup_{f ≠ 0} ‖f‖_∞ / ‖f‖_1 = ∞`. -/
theorem worst_moment_not_bounded_by_mean (M : ℝ) :
    ∃ f : C(Day, ℝ), f ≠ 0 ∧ M * ‖ContinuousMap.toLp (E := ℝ) 1 dayMeasure ℝ f‖ < ‖f‖ := by
  obtain ⟨g, hg1, hg⟩ := exists_spike 1 ENNReal.one_ne_top (ε := 1 / (|M| + 1)) (by positivity)
  refine ⟨g, fun h => by rw [h, norm_zero] at hg1; norm_num at hg1, ?_⟩
  have hn := norm_nonneg (ContinuousMap.toLp (E := ℝ) 1 dayMeasure ℝ g)
  have hM : M ≤ |M| + 1 := by linarith [le_abs_self M]
  have h1 : M * ‖ContinuousMap.toLp (E := ℝ) 1 dayMeasure ℝ g‖
      ≤ (|M| + 1) * ‖ContinuousMap.toLp (E := ℝ) 1 dayMeasure ℝ g‖ :=
    mul_le_mul_of_nonneg_right hM hn
  have h2 : (|M| + 1) * ‖ContinuousMap.toLp (E := ℝ) 1 dayMeasure ℝ g‖ < (|M| + 1) * (1 / (|M| + 1)) :=
    mul_lt_mul_of_pos_left hg (by positivity)
  have h3 : (|M| + 1) * (1 / (|M| + 1)) = 1 := by field_simp
  linarith

-- Worked numbers, by hand (km/h, hours; 6 minutes = 1/10 h).
-- Tuesday's jam: mean 60 × 3 / 24 = 7.5, mean square 3600 × 3 / 24 = 450.
example : (60 * 3 / 24 : ℚ) = 15 / 2 := by norm_num
example : (3600 * 3 / 24 : ℚ) = 450 := by norm_num
-- Thursday's crash: mean 90 × 0.1 / 24 = 0.375, mean square 8100 × 0.1 / 24 = 33.75.
example : (90 * (1 / 10) / 24 : ℚ) = 3 / 8 := by norm_num
example : (8100 * (1 / 10) / 24 : ℚ) = 135 / 4 := by norm_num
-- Which day was worse: 7.5 / 0.375 = 20 on average; 90 / 60 = 1.5 at worst.
example : ((15 / 2) / (3 / 8) : ℚ) = 20 := by norm_num
example : (90 / 60 : ℚ) = 3 / 2 := by norm_num
-- Totals without the 1/24: 24 × 7.5 = 180 km and 24 × 0.375 = 9 km.
example : (24 * (15 / 2) : ℚ) = 180 ∧ (24 * (3 / 8) : ℚ) = 9 := by norm_num
-- Thursday through bins: 90 × 6 min over a 60-minute bin is 9; over a 15-minute bin, 36.
example : (90 * 6 / 60 : ℚ) = 9 ∧ (90 * 6 / 15 : ℚ) = 36 := by norm_num
-- A one-bin spike of 90 among N bins: worst / average = 90 / (90 / N) = N.
example : ∀ N ∈ ({24, 96, 288, 1440} : Finset ℚ), (90 : ℚ) / (90 / N) = N := by
  intro N hN
  simp only [Finset.mem_insert, Finset.mem_singleton] at hN
  rcases hN with rfl | rfl | rfl | rfl <;> norm_num
-- Ramp f_{1/4}: to the jam, 2 triangles of 60 × (1/4) / 2, over 24 h, is 0.625;
-- to f_{1/8}, 2 triangles of 30 × (1/4) / 2, over 24 h, is 1.25 × (1/4) = 0.3125.
example : (2 * (60 * (1 / 4) / 2) / 24 : ℚ) = 5 / 8 := by norm_num
example : (2 * (30 * (1 / 4) / 2) / 24 : ℚ) = 5 / 4 * (1 / 4) ∧ (5 / 4 * (1 / 4) : ℚ) = 5 / 16 := by
  norm_num

#print axioms dayMeasure_apply
#print axioms dayMeasure_isOpenPosMeasure
#print axioms exists_spike
#print axioms completion_of_continuous_records_is_lp
#print axioms average_le_higher_average_le_worst_moment
#print axioms worst_moment_not_bounded_by_mean
