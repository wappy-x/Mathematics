-- The law of a random variable: the law of a real random variable is a probability measure on the line, its distribution function fixes it, and every distribution function is the law of its quantile map.
import Mathlib.MeasureTheory.Measure.Stieltjes
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Constructions.BorelSpace.Order

open MeasureTheory Set Filter Topology

/-- A distribution function takes values between 0 and 1. -/
theorem stieltjes_nonneg_le_one (F : StieltjesFunction ℝ)
    (hbot : Tendsto F atBot (𝓝 0)) (htop : Tendsto F atTop (𝓝 1)) (x : ℝ) :
    0 ≤ F x ∧ F x ≤ 1 :=
  ⟨le_of_tendsto hbot (eventually_atBot.2 ⟨x, fun _ hy => F.mono hy⟩),
    ge_of_tendsto htop (eventually_atTop.2 ⟨x, fun _ hy => F.mono hy⟩)⟩

/-- For a draw `u` strictly between 0 and 1, the quantile is at most `x` exactly when `u ≤ F x`. -/
theorem quantile_le_iff (F : StieltjesFunction ℝ)
    (hbot : Tendsto F atBot (𝓝 0)) (htop : Tendsto F atTop (𝓝 1))
    {u : ℝ} (hu : u ∈ Ioo (0 : ℝ) 1) (x : ℝ) :
    sInf {y : ℝ | u ≤ F y} ≤ x ↔ u ≤ F x := by
  have hbdd : BddBelow {y : ℝ | u ≤ F y} := by
    obtain ⟨y0, hy0⟩ := eventually_atBot.1 (hbot.eventually (gt_mem_nhds hu.1))
    refine ⟨y0, fun y hy => ?_⟩
    by_contra h
    have := hy0 y (not_le.1 h).le
    have hy' : u ≤ F y := hy
    linarith
  have hne : {y : ℝ | u ≤ F y}.Nonempty := by
    obtain ⟨y, hy⟩ := (htop.eventually (lt_mem_nhds hu.2)).exists
    exact ⟨y, hy.le⟩
  constructor
  · intro h
    set q := sInf {y : ℝ | u ≤ F y}
    have hq : u ≤ F q := by
      have hc : Tendsto F (𝓝[>] q) (𝓝 (F q)) :=
        (F.right_continuous q).tendsto.mono_left (nhdsWithin_mono _ Ioi_subset_Ici_self)
      refine ge_of_tendsto hc ?_
      filter_upwards [self_mem_nhdsWithin] with y hy
      obtain ⟨a, ha, hay⟩ := exists_lt_of_csInf_lt hne (show q < y from hy)
      exact le_trans ha (F.mono hay.le)
    exact hq.trans (F.mono h)
  · intro h
    exact csInf_le hbdd h


/-- Outside (0, 1], the quantile formula returns Lean's default value 0. -/
theorem quantile_outside (F : StieltjesFunction ℝ)
    (hbot : Tendsto F atBot (𝓝 0)) (htop : Tendsto F atTop (𝓝 1))
    {u : ℝ} (hu : u ∈ Iic (0 : ℝ) ∪ Ioi 1) :
    sInf {y : ℝ | u ≤ F y} = 0 := by
  rcases hu with hu | hu
  · have : {y : ℝ | u ≤ F y} = univ :=
      eq_univ_of_forall fun y => le_trans hu (stieltjes_nonneg_le_one F hbot htop y).1
    rw [this, Real.sInf_univ]
  · have : {y : ℝ | u ≤ F y} = ∅ :=
      eq_empty_of_forall_notMem fun y hy => by
        have hy' : u ≤ F y := hy
        have := (stieltjes_nonneg_le_one F hbot htop y).2
        have : (1 : ℝ) < u := hu
        linarith
    rw [this, Real.sInf_empty]

/-- Equal distribution functions give equal laws: if two real random variables X and Y,
possibly on different probability spaces, have P(X ≤ t) = P'(Y ≤ t) for every real t,
then their laws agree on every Borel set of the line. -/
theorem law_determined_by_distribution_function
    {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    (P : Measure Ω) (P' : Measure Ω') [IsProbabilityMeasure P] [IsProbabilityMeasure P']
    (X : Ω → ℝ) (Y : Ω' → ℝ) (hX : Measurable X) (hY : Measurable Y)
    (hF : ∀ t : ℝ, P {ω | X ω ≤ t} = P' {ω | Y ω ≤ t}) :
    P.map X = P'.map Y := by
  refine Measure.ext_of_Iic _ _ fun t => ?_
  rw [Measure.map_apply hX measurableSet_Iic, Measure.map_apply hY measurableSet_Iic]
  exact hF t

/-- The law is a probability measure: for a measurable real random variable X on a
probability space, the law gives each Borel set B the probability of the draws that land
in it, P(X⁻¹(B)), and it has total 1. -/
theorem law_is_probability_measure
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (hX : Measurable X) :
    IsProbabilityMeasure (P.map X) ∧
      ∀ B : Set ℝ, MeasurableSet B → P.map X B = P (X ⁻¹' B) := by
  exact ⟨inferInstance, fun _ hB => Measure.map_apply hX hB⟩

/-- Every distribution function is some variable's law: for F non-decreasing, continuous
from the right, with limits 0 at minus infinity and 1 at plus infinity, the quantile map
Q(u) = inf {x : F(x) ≥ u}, on draws u uniform on (0, 1), is measurable and its law is the
measure μ_F built from F. -/
theorem quantile_map_has_law
    (F : StieltjesFunction ℝ)
    (hbot : Tendsto F atBot (𝓝 0)) (htop : Tendsto F atTop (𝓝 1)) :
    Measurable (fun u : ℝ => sInf {x : ℝ | u ≤ F x}) ∧
      (volume.restrict (Ioo (0 : ℝ) 1)).map (fun u : ℝ => sInf {x : ℝ | u ≤ F x}) = F.measure := by
  set Q : ℝ → ℝ := fun u => sInf {x : ℝ | u ≤ F x} with hQdef
  have hpre : ∀ x, Q ⁻¹' Iic x ∩ Ioo 0 1 = Iic (F x) ∩ Ioo 0 1 := by
    intro x
    ext u
    simp only [mem_inter_iff, mem_preimage, mem_Iic]
    constructor
    · rintro ⟨h, hu⟩
      exact ⟨(quantile_le_iff F hbot htop hu x).1 h, hu⟩
    · rintro ⟨h, hu⟩
      exact ⟨(quantile_le_iff F hbot htop hu x).2 h, hu⟩
  have hQ : Measurable Q := by
    refine measurable_of_Iic fun x => ?_
    have hcover : Q ⁻¹' Iic x = (Q ⁻¹' Iic x ∩ Ioo 0 1) ∪
        (Q ⁻¹' Iic x ∩ (Iic 0 ∪ Ioi 1)) ∪ (Q ⁻¹' Iic x ∩ {1}) := by
      ext u
      simp only [mem_union, mem_inter_iff, mem_Ioo, mem_Iic, mem_Ioi, mem_singleton_iff]
      constructor
      · intro h
        rcases lt_trichotomy u 1 with h1 | h1 | h1
        · by_cases h0 : u ≤ 0
          · exact Or.inl (Or.inr ⟨h, Or.inl h0⟩)
          · exact Or.inl (Or.inl ⟨h, not_le.1 h0, h1⟩)
        · exact Or.inr ⟨h, h1⟩
        · exact Or.inl (Or.inr ⟨h, Or.inr h1⟩)
      · rintro ((⟨h, _⟩ | ⟨h, _⟩) | ⟨h, _⟩) <;> exact h
    have hT : Q ⁻¹' Iic x ∩ (Iic 0 ∪ Ioi 1) = (Iic 0 ∪ Ioi 1) ∩ {_u | (0 : ℝ) ≤ x} := by
      ext u
      simp only [mem_inter_iff, mem_preimage, mem_Iic]
      constructor
      · rintro ⟨h, hu⟩
        refine ⟨hu, ?_⟩
        have := quantile_outside F hbot htop hu
        change Q u ≤ x at h
        rw [hQdef] at h
        simp only at h
        rw [this] at h
        exact h
      · rintro ⟨hu, h⟩
        refine ⟨?_, hu⟩
        have := quantile_outside F hbot htop hu
        change Q u ≤ x
        rw [hQdef]
        simp only
        rw [this]
        exact h
    rw [hcover, hpre, hT]
    refine ((measurableSet_Iic.inter measurableSet_Ioo).union
      ((measurableSet_Iic.union measurableSet_Ioi).inter (MeasurableSet.const _))).union ?_
    exact (subsingleton_singleton.anti inter_subset_right).measurableSet
  refine ⟨hQ, ?_⟩
  have : IsFiniteMeasure (volume.restrict (Ioo (0 : ℝ) 1)) :=
    isFiniteMeasure_restrict.2 (by simp)
  refine Measure.ext_of_Iic _ _ fun x => ?_
  rw [Measure.map_apply hQ measurableSet_Iic,
    Measure.restrict_apply (hQ measurableSet_Iic), hpre, F.measure_Iic hbot x, sub_zero]
  obtain ⟨h0, h1⟩ := stieltjes_nonneg_le_one F hbot htop x
  apply le_antisymm
  · calc volume (Iic (F x) ∩ Ioo 0 1) ≤ volume (Icc 0 (F x)) :=
          measure_mono fun u hu => ⟨hu.2.1.le, hu.1⟩
      _ = ENNReal.ofReal (F x) := by rw [Real.volume_Icc, sub_zero]
  · calc ENNReal.ofReal (F x) = volume (Ioo 0 (F x)) := by rw [Real.volume_Ioo, sub_zero]
      _ ≤ volume (Iic (F x) ∩ Ioo 0 1) :=
          measure_mono fun u hu => ⟨hu.2.le, hu.1, lt_of_lt_of_le hu.2 h1⟩

/-! The card's worked numbers, exactly. The claim pays $0 on a draw u ≤ 3/10 and
(u - 3/10)/(7/10) × $1,000 above it; its distribution function is 3/10 + 7/10 × t/1,000
on [0, 1000). -/

/-- The claim rule. -/
def claim (u : ℚ) : ℚ := if u ≤ 3 / 10 then 0 else (u - 3 / 10) / (7 / 10) * 1000

/-- The claim's distribution function, on the dollar range 0 ≤ t < 1000. -/
def claimF (t : ℚ) : ℚ := 3 / 10 + 7 / 10 * t / 1000

-- the band's preimage runs from draw 0.44 to draw 0.65; the rule sends them to $200 and $500
example : claimF 200 = 44 / 100 ∧ claimF 500 = 65 / 100 := by norm_num [claimF]
example : claim (44 / 100) = 200 ∧ claim (65 / 100) = 500 := by norm_num [claim]
-- law of the band (200, 500]: 0.21
example : claimF 500 - claimF 200 = 21 / 100 := by norm_num [claimF]
-- law of (0, 200]: 0.14; distribution function at $250: 0.475
example : claimF 200 - 3 / 10 = 14 / 100 ∧ claimF 250 = 475 / 1000 := by norm_num [claimF]
-- law above $900 is 0.07, and $0, the band, or above $900 together: 0.58
example : 1 - claimF 900 = 7 / 100 ∧ 3 / 10 + (claimF 500 - claimF 200) + (1 - claimF 900) = 58 / 100 := by
  norm_num [claimF]
-- quantile at u = 0.9 is $6000/7, which is $857.14 to the cent
example : claim (9 / 10) = 6000 / 7 := by norm_num [claim]

-- ten tickets at u = (2i + 1)/20: three pay $0, the other seven pay seven different amounts
example : ((Finset.range 10).filter (fun i : ℕ => claim ((2 * i + 1) / 20) = 0)).card = 3 := by decide +kernel
example : (((Finset.range 10).image (fun i : ℕ => claim ((2 * i + 1) / 20))).erase 0).card = 7 := by decide +kernel
-- the band (200, 500] collects tickets 4, 5 and 6
example : (Finset.range 10).filter (fun i : ℕ => 200 < claim ((2 * i + 1) / 20) ∧ claim ((2 * i + 1) / 20) ≤ 500)
    = {4, 5, 6} := by decide +kernel
-- tickets 4, 5, 6 are not in the coarse sigma-algebra {nothing, 0-4, 5-9, everything}
example : ({4, 5, 6} : Finset ℕ) ∉
    ({∅, Finset.range 5, Finset.range 10 \ Finset.range 5, Finset.range 10} : Finset (Finset ℕ)) := by decide

#print axioms law_determined_by_distribution_function
#print axioms law_is_probability_measure
#print axioms quantile_map_has_law
#print axioms stieltjes_nonneg_le_one
#print axioms quantile_le_iff
#print axioms quantile_outside
