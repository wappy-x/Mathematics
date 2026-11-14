-- Simulating a default time: reading a uniform draw off any survival curve gives a default date that falls by date t with chance exactly 1 - S(t), and the hazard budget -ln U is an exponential draw with average 1.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Topology.Instances.ENNReal.Lemmas

open MeasureTheory Set
open scoped NNReal ENNReal

/-- The default time read off the survival curve `S` at the draw `u`: the earliest date
`t ≥ 0` at which the curve is at or below `u`, and `∞` ("never") if there is none. -/
noncomputable def defaultTime (S : ℝ≥0 → ℝ) (u : ℝ) : ℝ≥0∞ :=
  ⨅ t ∈ {t : ℝ≥0 | S t ≤ u}, (t : ℝ≥0∞)

/-- An earlier default is a higher ticket: for a survival curve that never rises and is
right-continuous, the default time read off at the draw `u` comes at or before the date `t`
exactly when the curve at `t` has already fallen to `u` or below. -/
theorem defaultTime_le_iff (S : ℝ≥0 → ℝ) (hanti : Antitone S)
    (hright : ∀ t : ℝ≥0, ContinuousWithinAt S (Ici t) t) (u : ℝ) (t : ℝ≥0) :
    defaultTime S u ≤ (t : ℝ≥0∞) ↔ S t ≤ u := by
  constructor
  · intro h
    by_contra hlt
    push Not at hlt
    have hev : ∀ᶠ s in nhdsWithin t (Ici t), u < S s :=
      (hright t) (isOpen_Ioi.mem_nhds hlt)
    obtain ⟨v, hv, hsub⟩ := mem_nhdsGE_iff_exists_Ico_subset.mp hev
    have hge : (v : ℝ≥0∞) ≤ defaultTime S u := by
      unfold defaultTime
      refine le_iInf₂ fun s hs => ?_
      simp only [mem_ofPred_eq] at hs
      rw [ENNReal.coe_le_coe]
      by_contra hsv
      push Not at hsv
      rcases le_or_gt t s with hts | hst
      · have := hsub ⟨hts, hsv⟩
        simp only [mem_ofPred_eq] at this
        linarith
      · have := hanti hst.le
        linarith
    have : (v : ℝ≥0∞) ≤ t := hge.trans h
    rw [ENNReal.coe_le_coe] at this
    exact absurd hv (not_lt.mpr this)
  · intro h
    unfold defaultTime
    exact iInf₂_le t (by simpa using h)

/-- Simulating a default time: let `S` be any survival curve (it starts at 1, stays at or
above 0, never rises, and is right-continuous). Draw `U` uniformly from `[0, 1]` and take the
default time to be the earliest date at which `S` is at or below `U`. Then for every date `t`
the chance that this default time comes at or before `t` is exactly `1 - S(t)`, the default
chance by `t`. -/
theorem simulated_default_time_has_survival_curve (S : ℝ≥0 → ℝ) (hzero : S 0 = 1)
    (hnonneg : ∀ t, 0 ≤ S t) (hanti : Antitone S)
    (hright : ∀ t : ℝ≥0, ContinuousWithinAt S (Ici t) t) (t : ℝ≥0) :
    volume {u ∈ Icc (0 : ℝ) 1 | defaultTime S u ≤ (t : ℝ≥0∞)} = ENNReal.ofReal (1 - S t) := by
  have hset : {u ∈ Icc (0 : ℝ) 1 | defaultTime S u ≤ (t : ℝ≥0∞)} = Icc (S t) 1 := by
    ext u
    simp only [mem_ofPred_eq, mem_Icc, defaultTime_le_iff S hanti hright]
    have := hnonneg t
    constructor
    · rintro ⟨⟨_, h1⟩, h2⟩
      exact ⟨h2, h1⟩
    · rintro ⟨h2, h1⟩
      exact ⟨⟨by linarith, h1⟩, h2⟩
  rw [hset, Real.volume_Icc]

/-- The log turns the curve into a budget: for a uniform draw `U` on `[0, 1]`, the hazard
budget `E = -ln U` exceeds any `x ≥ 0` with chance `e^{-x}`, so `E` is an exponential draw
with average 1. -/
theorem hazard_budget_is_exponential (x : ℝ) (hx : 0 ≤ x) :
    volume {u ∈ Icc (0 : ℝ) 1 | x < -Real.log u} = ENNReal.ofReal (Real.exp (-x)) := by
  have hexp : Real.exp (-x) ≤ 1 := Real.exp_le_one_iff.mpr (by linarith)
  have hset : {u ∈ Icc (0 : ℝ) 1 | x < -Real.log u} = Ioo 0 (Real.exp (-x)) := by
    ext u
    simp only [mem_ofPred_eq, mem_Icc, mem_Ioo]
    constructor
    · rintro ⟨⟨h0, h1⟩, h2⟩
      rcases h0.lt_or_eq with hpos | hzero
      · refine ⟨hpos, ?_⟩
        rw [← Real.log_lt_iff_lt_exp hpos]
        linarith
      · subst hzero
        simp at h2
        linarith
    · rintro ⟨hpos, hlt⟩
      refine ⟨⟨hpos.le, by linarith⟩, ?_⟩
      rw [← Real.log_lt_iff_lt_exp hpos] at hlt
      linarith
  rw [hset, Real.volume_Ioo, sub_zero]

-- The van's cumulative hazard by year 5: 2% for one year, 4% for two, 6% for two, total 0.22.
example : (2 / 100 : ℚ) * 1 + (4 / 100) * 2 + (6 / 100) * 2 = 22 / 100 := by norm_num

-- The van's cumulative hazard by year 3 is 0.10, the budget spent before the 6% step.
example : (2 / 100 : ℚ) * 1 + (4 / 100) * 2 = 1 / 10 := by norm_num

-- The flat 2% game: the average lifetime is 1 / 0.02 = 50 rounds.
example : (1 : ℚ) / (2 / 100) = 50 := by norm_num

#print axioms defaultTime_le_iff
#print axioms simulated_default_time_has_survival_curve
#print axioms hazard_budget_is_exponential
