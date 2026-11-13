-- Expectation as an integral: for a random variable X on any probability space and any Borel function g, the average of g(X) over the outcomes equals the integral of g against the law of X on the line, and when the law has a density f it is the integral of g times f.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory
open scoped ENNReal NNReal

/-- The change of variables formula, for signed `g`. Let `P` be a probability on the
outcome space `Ω`, `X` a measurable real function on it (a random variable), and `g` a
Borel function on the line. The law of `X` is `P.map X`, the probability that gives a
set `B` of values the chance that `X` lands in `B`. Then `g(X)` is integrable on the
outcome space exactly when `g` is integrable against the law, and in that case the
expectation of `g(X)`, its integral against `P`, equals the integral of `g` against the
law of `X`. -/
theorem expectation_of_g_of_X_eq_integral_against_law {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] {X : Ω → ℝ} (hX : Measurable X)
    {g : ℝ → ℝ} (hg : Measurable g) :
    (Integrable (fun ω => g (X ω)) P ↔ Integrable g (P.map X)) ∧
      (Integrable (fun ω => g (X ω)) P →
        ∫ ω, g (X ω) ∂P = ∫ t, g t ∂(P.map X)) := by
  constructor
  · exact (integrable_map_measure hg.aestronglyMeasurable hX.aemeasurable).symm
  · intro _
    exact (integral_map hX.aemeasurable hg.aestronglyMeasurable).symm

/-- The change of variables formula, for non-negative `g`. For a random variable `X` on a
probability space and any Borel function `g` with values in `[0, ∞]`, the integral of
`g(X)` against `P` equals the integral of `g` against the law of `X`. No finiteness is
needed: if one side is infinite, so is the other. -/
theorem expectation_of_nonneg_g_of_X_eq_integral_against_law {Ω : Type*}
    [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P] {X : Ω → ℝ}
    (hX : Measurable X) {g : ℝ → ℝ≥0∞} (hg : Measurable g) :
    ∫⁻ ω, g (X ω) ∂P = ∫⁻ t, g t ∂(P.map X) := by
  exact (lintegral_map hg hX).symm

/-- The density formula. Suppose the law of `X` has a density `f`: a non-negative Borel
function with `P(X ∈ B) = ∫_B f(t) dt` for every Borel set `B` of the line. Then for every
non-negative Borel function `g`, the expectation of `g(X)` is the length-integral of
`g(t) f(t)` over the line. -/
theorem expectation_of_nonneg_g_of_X_eq_integral_of_g_times_density {Ω : Type*}
    [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P] {X : Ω → ℝ}
    (hX : Measurable X) {f : ℝ → ℝ≥0} (hf : Measurable f)
    (hdens : ∀ B : Set ℝ, MeasurableSet B → P.map X B = ∫⁻ t in B, (f t : ℝ≥0∞))
    {g : ℝ → ℝ≥0∞} (hg : Measurable g) :
    ∫⁻ ω, g (X ω) ∂P = ∫⁻ t, g t * f t := by
  have hmeas : P.map X = volume.withDensity (fun t => (f t : ℝ≥0∞)) := by
    ext B hB
    rw [hdens B hB, withDensity_apply _ hB]
  rw [← lintegral_map hg hX, hmeas,
    lintegral_withDensity_eq_lintegral_mul _ hf.coe_nnreal_ennreal hg]
  refine lintegral_congr fun t => ?_
  simp only [Pi.mul_apply]
  exact mul_comm _ _

/-! The river: depth X(ω) = 4ω(1 - ω) m at a uniformly random mooring point ω of [0, 1] km.
Exact fractions only; the card's decimals are left out. -/

-- E[X] on the river: the integral of 4ω - 4ω^2 over [0, 1] is 2 - 4/3 = 2/3.
example : (4 : ℚ) / 2 - 4 / 3 = 2 / 3 := by norm_num

-- E[X] on the line: after u = √(1 - t), the integral of 1 - u^2 over [0, 1] is 1 - 1/3 = 2/3.
example : (1 : ℚ) - 1 / 3 = 2 / 3 := by norm_num

-- E[X^2] on the river: 16 × (1/3 - 1/2 + 1/5) = 16/30 = 8/15.
example : (16 : ℚ) * (1 / 3 - 1 / 2 + 1 / 5) = 8 / 15 := by norm_num

-- E[X^2] on the line: the integral of (1 - u^2)^2 is 1 - 2/3 + 1/5 = 8/15.
example : (1 : ℚ) - 2 / 3 + 1 / 5 = 8 / 15 := by norm_num

-- E[X^3] and E[X^4] on the line, from (1 - u^2)^k expanded: 16/35 and 128/315.
example : (1 : ℚ) - 3 / 3 + 3 / 5 - 1 / 7 = 16 / 35 := by norm_num
example : (1 : ℚ) - 4 / 3 + 6 / 5 - 4 / 7 + 1 / 9 = 128 / 315 := by norm_num

-- E[X^3] and E[X^4] on the river: 64 × ∫ ω^3 (1 - ω)^3 and 256 × ∫ ω^4 (1 - ω)^4, expanded.
example : (64 : ℚ) * (1 / 4 - 3 / 5 + 3 / 6 - 1 / 7) = 16 / 35 := by norm_num
example : (256 : ℚ) * (1 / 5 - 4 / 6 + 6 / 7 - 4 / 8 + 1 / 9) = 128 / 315 := by norm_num

-- Variance: 8/15 - (2/3)^2 = 24/45 - 20/45 = 4/45.
example : (8 : ℚ) / 15 - (2 / 3) ^ 2 = 4 / 45 := by norm_num

-- Variance directly on the river: the integral of (4ω - 4ω^2 - 2/3)^2 over [0, 1],
-- expanded as 16ω^2 - 32ω^3 + 16ω^4 - (16/3)ω + (16/3)ω^2 + 4/9.
example : (16 : ℚ) / 3 - 32 / 4 + 16 / 5 - 16 / 3 / 2 + 16 / 3 / 3 + 4 / 9 = 4 / 45 := by norm_num

-- Mistakes: depth read as uniform on [0, 1] m gives 1/2; (E[X])^2 = 4/9, not 8/15.
example : (1 : ℚ) / 2 ≠ 2 / 3 := by norm_num
example : ((2 : ℚ) / 3) ^ 2 = 4 / 9 ∧ (4 : ℚ) / 9 ≠ 8 / 15 := by norm_num

-- The payout (-2)^k on depth band k, which has probability 1/2^k - 1/2^(k+1) = 1/2^(k+1):
-- running totals after 1 to 6 bands are 1/2, 0, 1/2, 0, 1/2, 0.
example : (List.range 6).map (fun n => ∑ k ∈ Finset.range (n + 1),
    (-2 : ℚ) ^ k * (1 / 2 ^ k - 1 / 2 ^ (k + 1))) = [1 / 2, 0, 1 / 2, 0, 1 / 2, 0] := by
  simp [Finset.sum_range_succ, List.range_succ]; norm_num

#print axioms expectation_of_g_of_X_eq_integral_against_law
#print axioms expectation_of_nonneg_g_of_X_eq_integral_against_law
#print axioms expectation_of_nonneg_g_of_X_eq_integral_of_g_times_density
