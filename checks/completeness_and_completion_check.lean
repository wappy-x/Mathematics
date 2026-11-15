-- Complete space: every metric space has a completion (a complete metric space holding it densely with the same distances), the fractions are not complete, and nested closed sets with shrinking diameters in a complete space meet in exactly one point.
import Mathlib.Topology.MetricSpace.Completion
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.Instances.Rat
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Topology.Instances.ENNReal.Lemmas

open Filter Topology

universe u

/-- Every metric space `X` has a completion: a complete metric space `Y` and a map `X → Y`
that keeps every distance, whose image is dense in `Y` (every point of `Y` has points of
`X` as close as you like). -/
theorem every_metric_space_has_a_completion (X : Type u) [MetricSpace X] :
    ∃ (Y : Type u) (_ : MetricSpace Y) (ι : X → Y),
      CompleteSpace Y ∧ Isometry ι ∧ DenseRange ι := by
  exact ⟨UniformSpace.Completion X, inferInstance, (↑), inferInstance,
    UniformSpace.Completion.coe_isometry, UniformSpace.Completion.denseRange_coe⟩

/-- The fractions, with the distance `|x - y|`, are not complete: some Cauchy sequence of
fractions (the decimals of root 2) has no limit among the fractions. -/
theorem rationals_not_complete : ¬ CompleteSpace ℚ := by
  intro hQ
  have hcl : IsClosed (Set.range ((↑) : ℚ → ℝ)) :=
    Rat.isUniformEmbedding_coe_real.isUniformInducing.isComplete_range.isClosed
  have huniv : Set.range ((↑) : ℚ → ℝ) = Set.univ := by
    rw [← Rat.denseRange_cast.closure_range, hcl.closure_eq]
  have hmem : Real.sqrt 2 ∈ Set.range ((↑) : ℚ → ℝ) := by
    rw [huniv]; exact Set.mem_univ _
  exact irrational_sqrt_two hmem

/-- Cantor's intersection theorem: in a complete metric space, non-empty closed sets
`F 0 ⊇ F 1 ⊇ F 2 ⊇ ...` whose diameters shrink to 0 have exactly one point in common.
The diameter is measured in `[0, ∞]`, so an unbounded set such as `[n, ∞)` has
infinite diameter. -/
theorem cantor_intersection_unique {X : Type u} [MetricSpace X] [CompleteSpace X]
    (F : ℕ → Set X) (hclosed : ∀ n, IsClosed (F n)) (hne : ∀ n, (F n).Nonempty)
    (hnest : ∀ n, F (n + 1) ⊆ F n)
    (hdiam : Tendsto (fun n => Metric.ediam (F n)) atTop (𝓝 0)) :
    ∃! x, ∀ n, x ∈ F n := by
  have hanti : Antitone F := antitone_nat_of_succ_le hnest
  -- eventually the diameters are finite
  obtain ⟨N, hN⟩ : ∃ N, ∀ n ≥ N, Metric.ediam (F n) < 1 :=
    eventually_atTop.1 (hdiam.eventually (gt_mem_nhds (by norm_num)))
  set G : ℕ → Set X := fun n => F (n + N) with hG
  have hGb : ∀ n, Bornology.IsBounded (G n) := fun n =>
    Metric.isBounded_iff_ediam_ne_top.2 (ne_top_of_lt ((hN (n + N) (by omega)).trans ENNReal.one_lt_top))
  have hGd : Tendsto (fun n => Metric.diam (G n)) atTop (𝓝 0) := by
    have h1 : Tendsto (fun n => Metric.ediam (G n)) atTop (𝓝 0) :=
      hdiam.comp (tendsto_add_atTop_nat N)
    have h2 := (ENNReal.tendsto_toReal ENNReal.zero_ne_top).comp h1
    simpa [Metric.diam, Function.comp_def] using h2
  have hGi : ∀ M, (⋂ n ≤ M, G n).Nonempty := by
    intro M
    obtain ⟨x, hx⟩ := hne (M + N)
    refine ⟨x, Set.mem_iInter₂.2 fun n hn => ?_⟩
    exact hanti (by omega : n + N ≤ M + N) hx
  obtain ⟨x, hx⟩ := Metric.nonempty_iInter_of_nonempty_biInter
    (fun n => hclosed (n + N)) hGb hGi hGd
  have hxF : ∀ n, x ∈ F n := fun n =>
    hanti (by omega : n ≤ n + N) (Set.mem_iInter.1 hx n)
  refine ⟨x, hxF, fun y hy => ?_⟩
  have hle : edist y x ≤ 0 :=
    ge_of_tendsto' hdiam fun n => Metric.edist_le_ediam_of_mem (hy n) (hxF n)
  exact edist_le_zero.1 hle

-- Decimals of root 2, as whole numbers: a_n * 10^-n with a_n^2 ≤ 2 * 10^(2n) < (a_n + 1)^2.
example : 1 ^ 2 ≤ 2 ∧ 2 < 2 ^ 2 := by decide
example : 14 ^ 2 ≤ 2 * 10 ^ 2 ∧ 2 * 10 ^ 2 < 15 ^ 2 := by decide
example : 141 ^ 2 ≤ 2 * 10 ^ 4 ∧ 2 * 10 ^ 4 < 142 ^ 2 := by norm_num
example : 1414 ^ 2 ≤ 2 * 10 ^ 6 ∧ 2 * 10 ^ 6 < 1415 ^ 2 := by norm_num
example : 14142 ^ 2 ≤ 2 * 10 ^ 8 ∧ 2 * 10 ^ 8 < 14143 ^ 2 := by norm_num

-- How far each square falls short of 2: 1, 0.04, 0.0119, 0.000604, 0.00003836.
example : (2 : ℚ) - 1 ^ 2 = 1 := by norm_num
example : (2 : ℚ) - (14 / 10) ^ 2 = 4 / 100 := by norm_num
example : (2 : ℚ) - (141 / 100) ^ 2 = 119 / 10000 := by norm_num
example : (2 : ℚ) - (1414 / 1000) ^ 2 = 604 / 10 ^ 6 := by norm_num
example : (2 : ℚ) - (14142 / 10000) ^ 2 = 3836 / 10 ^ 8 := by norm_num

-- Newton's list b_{n+1} = (b_n + 2 / b_n) / 2 from 1: 3/2, 17/12, 577/408, 665857/470832.
example : ((1 : ℚ) + 2 / 1) / 2 = 3 / 2 := by norm_num
example : ((3 / 2 : ℚ) + 2 / (3 / 2)) / 2 = 17 / 12 := by norm_num
example : ((17 / 12 : ℚ) + 2 / (17 / 12)) / 2 = 577 / 408 := by norm_num
example : ((577 / 408 : ℚ) + 2 / (577 / 408)) / 2 = 665857 / 470832 := by norm_num

-- Street grid, corner (3, 4): walk 7 blocks, straight 5; 5^2 = 25 ≤ 7^2 = 49 ≤ 2 × 5^2 = 50.
example : 3 + 4 = 7 ∧ 3 ^ 2 + 4 ^ 2 = 5 ^ 2 := by decide
example : 5 ^ 2 = 25 ∧ 7 ^ 2 = 49 ∧ 5 ^ 2 ≤ 7 ^ 2 ∧ 7 ^ 2 ≤ 2 * 5 ^ 2 := by decide

-- What breaks: f(x) = x/(1+x) squeezes d(10, 100) = 90 down to 90/1111.
example : |(100 : ℚ) / (1 + 100) - 10 / (1 + 10)| = 90 / 1111 := by norm_num [abs_of_pos]

-- What breaks: d(1/10, 1/1000) = 0.099 on (0, 1].
example : |(1 : ℚ) / 10 - 1 / 1000| = 99 / 1000 := by norm_num [abs_of_pos]

-- Cantor nest in the fractions: 99/70 matches the digits of root 2 to 4 places, not to 5.
example : 99 * 10 ^ 4 / 70 = 14142 ∧ 99 * 10 ^ 5 / 70 = 141428 ∧ 141428 ≠ 141421 := by decide

#print axioms every_metric_space_has_a_completion
#print axioms rationals_not_complete
#print axioms cantor_intersection_unique
