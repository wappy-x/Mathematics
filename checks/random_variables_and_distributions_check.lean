-- Random variables: the table of chances of a random variable with listable values adds to 1, its running total climbs from 0 to 1, and each jump of the running total is that value's chance.
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Topology.Order.Basic

open MeasureTheory Filter Topology

/-- Helper: the running total of `X` is the CDF of the law of `X`. -/
lemma rv_real_le_eq_cdf {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : Ω → ℝ) (hX : Measurable X) (x : ℝ) :
    μ.real {ω | X ω ≤ x} = ProbabilityTheory.cdf (μ.map X) x := by
  rw [ProbabilityTheory.cdf_eq_real, measureReal_def, measureReal_def,
    Measure.map_apply hX measurableSet_Iic]
  rfl

#print axioms rv_real_le_eq_cdf

/-- The table adds to 1: if a rule `X` gives each outcome one real number, its values can be
listed (finitely many or one after another), and every set of outcomes asked about has a chance,
then the chances `p(x) = P(X = x)` of the values of `X` add up to 1. -/
theorem pmf_sum_eq_one {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : Ω → ℝ) (hX : Measurable X) (hcount : (Set.range X).Countable) :
    ∑' x : Set.range X, μ.real (X ⁻¹' {(x : ℝ)}) = 1 := by
  have : Countable (Set.range X) := hcount.to_subtype
  have hmeas : ∀ x : Set.range X, MeasurableSet (X ⁻¹' {(x : ℝ)}) :=
    fun x => hX (measurableSet_singleton _)
  have hunion : (⋃ x : Set.range X, X ⁻¹' {(x : ℝ)}) = Set.univ := by
    ext ω; simp
  have hdisj : Pairwise (Function.onFun Disjoint fun x : Set.range X => X ⁻¹' {(x : ℝ)}) := by
    intro a b hab
    exact Disjoint.preimage _ (Set.disjoint_singleton.2 (Subtype.coe_injective.ne hab))
  have h := measure_iUnion (μ := μ) hdisj hmeas
  rw [hunion, measure_univ] at h
  simp only [Measure.real]
  rw [← ENNReal.tsum_toReal_eq (fun _ => measure_ne_top _ _), ← h]
  simp

/-- The running total `F(x) = P(X ≤ x)` never falls, tends to 0 far to the left,
and tends to 1 far to the right. -/
theorem cdf_climbs_from_zero_to_one {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX : Measurable X) :
    Monotone (fun x => μ.real {ω | X ω ≤ x}) ∧
    Tendsto (fun x => μ.real {ω | X ω ≤ x}) atBot (𝓝 0) ∧
    Tendsto (fun x => μ.real {ω | X ω ≤ x}) atTop (𝓝 1) := by
  have hF : (fun x => μ.real {ω | X ω ≤ x}) = ProbabilityTheory.cdf (μ.map X) :=
    funext (rv_real_le_eq_cdf μ X hX)
  rw [hF]
  exact ⟨ProbabilityTheory.monotone_cdf _, ProbabilityTheory.tendsto_cdf_atBot _,
    ProbabilityTheory.tendsto_cdf_atTop _⟩

/-- The jumps of the running total are the table's entries: just below `x` the running total
is `F(x) - p(x)`, it holds its step's top value `F(x)` at `x` itself (limit from the right),
and the chance of a window is a difference: `P(a < X ≤ b) = F(b) - F(a)` for `a ≤ b`. -/
theorem cdf_jump_eq_pmf {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (hX : Measurable X) (x a b : ℝ) (hab : a ≤ b) :
    Tendsto (fun s => μ.real {ω | X ω ≤ s}) (𝓝[<] x)
      (𝓝 (μ.real {ω | X ω ≤ x} - μ.real {ω | X ω = x})) ∧
    Tendsto (fun s => μ.real {ω | X ω ≤ s}) (𝓝[>] x) (𝓝 (μ.real {ω | X ω ≤ x})) ∧
    μ.real {ω | a < X ω ∧ X ω ≤ b} = μ.real {ω | X ω ≤ b} - μ.real {ω | X ω ≤ a} := by
  have hF : (fun x => μ.real {ω | X ω ≤ x}) = ProbabilityTheory.cdf (μ.map X) :=
    funext (rv_real_le_eq_cdf μ X hX)
  set F := ProbabilityTheory.cdf (μ.map X) with hFdef
  have hFx : μ.real {ω | X ω ≤ x} = F x := rv_real_le_eq_cdf μ X hX x
  refine ⟨?_, ?_, ?_⟩
  · rw [hF]
    have hjump : μ.real {ω | X ω = x} = F x - Function.leftLim F x := by
      have h1 : μ.real {ω | X ω = x} = (μ.map X).real {x} := by
        rw [measureReal_def, measureReal_def, Measure.map_apply hX (measurableSet_singleton x)]
        rfl
      rw [h1, measureReal_def, ← ProbabilityTheory.measure_cdf (μ := μ.map X),
        StieltjesFunction.measure_singleton]
      exact ENNReal.toReal_ofReal
        (sub_nonneg.2 (Monotone.leftLim_le (ProbabilityTheory.monotone_cdf _) le_rfl))
    rw [hFx, hjump, sub_sub_cancel]
    exact Monotone.tendsto_leftLim (ProbabilityTheory.monotone_cdf _) x
  · rw [hF, hFx]
    exact ((ProbabilityTheory.cdf (μ.map X)).right_continuous x).mono Set.Ioi_subset_Ici_self
  · have hset : {ω | a < X ω ∧ X ω ≤ b} = {ω | X ω ≤ b} \ {ω | X ω ≤ a} := by
      ext ω; simp [and_comm]
    rw [hset, measureReal_sdiff]
    · intro ω hω; exact le_trans hω hab
    · exact hX measurableSet_Iic

/-! Worked examples from the card, as whole-number counts and exact fractions. -/

/-- The raffle ticket 37: the payout rule on draws 1 to 100. -/
def rafflePayout (drawn : ℕ) : ℕ := if drawn = 37 then 100 else 0

-- 99 of the 100 draws are sent to $0, one to $100.
example : ((Finset.Icc 1 100).filter (fun d => rafflePayout d = 0)).card = 99 := by decide
example : ((Finset.Icc 1 100).filter (fun d => rafflePayout d = 100)).card = 1 := by decide
-- The table adds to 1, and the window P(0 < X ≤ 100) = F(100) - F(0) = 1/100.
example : (99 : ℚ) / 100 + 1 / 100 = 1 := by norm_num
example : (1 : ℚ) - 99 / 100 = 1 / 100 := by norm_num
-- The 77 bet: 10 of the 1,000 three-digit numbers end in 77, the same table 99/100 and 1/100.
example : ((Finset.range 1000).filter (fun n => n % 100 = 77)).card = 10 := by decide +kernel
example : (990 : ℚ) / 1000 = 99 / 100 ∧ (10 : ℚ) / 1000 = 1 / 100 := by norm_num
-- Three raffles: counts of the million equally likely triples by total payout.
example : 99 * 99 * 99 = 970299 := by norm_num
example : 3 * (1 * 99 * 99) = 29403 := by norm_num
example : 3 * (1 * 1 * 99) = 297 := by norm_num
example : 970299 + 29403 + 297 + 1 = 1000000 := by norm_num
-- F(100) for T counts 999,702 triples; winning at least once counts 29,701.
example : 970299 + 29403 = 999702 := by norm_num
example : 1000000 - 970299 = 29701 := by norm_num
-- Adding the three weekly chances gives 3/100, not the true 29701/1000000.
example : (1 : ℚ) / 100 + 1 / 100 + 1 / 100 = 3 / 100 ∧
    (3 : ℚ) / 100 ≠ 29701 / 1000000 := by norm_num

#print axioms pmf_sum_eq_one
#print axioms cdf_climbs_from_zero_to_one
#print axioms cdf_jump_eq_pmf
