-- Riesz-Fischer: for 1 ≤ p < ∞ on any measure space, every Cauchy sequence in Lp has a limit in Lp, a norm-convergent sequence has a subsequence converging almost everywhere, and simple functions with finite-measure support come arbitrarily close to every Lp function.
import Mathlib.MeasureTheory.Function.LpSpace.Complete
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.MeasureTheory.Function.SimpleFuncDenseLp

open MeasureTheory Filter Topology
open scoped ENNReal

variable {α : Type*} [MeasurableSpace α]

/-- Riesz-Fischer. For a power p with 1 ≤ p < ∞ and any measure space, a sequence in Lp
(functions with finite p-norm, two functions equal almost everywhere counted as one) whose
terms crowd together (a Cauchy sequence) converges in the p-norm to a member of Lp. -/
theorem lp_cauchy_seq_has_limit_in_lp (μ : Measure α) (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞)
    (f : ℕ → Lp ℝ p μ) (hf : CauchySeq f) :
    ∃ g : Lp ℝ p μ, Tendsto f atTop (𝓝 g) := by
  exact cauchySeq_tendsto_of_complete hf

/-- The subsequence corollary. For 1 ≤ p < ∞ and any measure space, if f n converges to f
in the p-norm, some subsequence f (n k) converges to f at almost every point. -/
theorem lp_limit_has_ae_convergent_subsequence (μ : Measure α) (p : ℝ≥0∞) [Fact (1 ≤ p)]
    (hp : p ≠ ∞) (f : ℕ → Lp ℝ p μ) (g : Lp ℝ p μ) (hfg : Tendsto f atTop (𝓝 g)) :
    ∃ n : ℕ → ℕ, StrictMono n ∧ ∀ᵐ x ∂μ, Tendsto (fun k => f (n k) x) atTop (𝓝 (g x)) := by
  exact (tendstoInMeasure_of_tendsto_Lp hfg).exists_seq_tendsto_ae

/-- Simple functions are dense. For 1 ≤ p < ∞ and any measure space, for every function f
with finite p-norm and every ε > 0 there is a simple function φ, zero outside a set of
finite measure, with ‖f - φ‖_p < ε. -/
theorem simple_functions_dense_in_lp (μ : Measure α) (p : ℝ≥0∞) (hp1 : 1 ≤ p) (hp : p ≠ ∞)
    (f : α → ℝ) (hf : MemLp f p μ) (ε : ℝ) (hε : 0 < ε) :
    ∃ φ : SimpleFunc α ℝ, μ (Function.support φ) < ∞ ∧ eLpNorm (f - ⇑φ) p μ < ENNReal.ofReal ε := by
  obtain ⟨φ, hφ, hφmem⟩ := hf.exists_simpleFunc_eLpNorm_sub_lt hp
    (ε := ENNReal.ofReal ε) (by simpa using hε)
  exact ⟨φ, φ.measure_support_lt_top_of_memLp hφmem
    (zero_lt_one.trans_le hp1).ne' hp, hφ⟩

-- The wind week (3, 5, 8, 2, 6, 4, 7): its squared 2-norm under counting measure is 203.
example : ([3, 5, 8, 2, 6, 4, 7].map (fun x : ℕ => x ^ 2)).sum = 203 := by decide

-- Its squared distance to the week cut after three days is 4 + 36 + 16 + 49 = 105.
example : ([2, 6, 4, 7].map (fun x : ℕ => x ^ 2)).sum = 105 := by decide

-- Under the uniform probability 1/7 per day the squared 2-norm is 203 / 7 = 29.
example : (203 : ℕ) = 7 * 29 := by norm_num

-- The staircase at k = 8 takes 32 values: the numbers ⌊256 / n⌋ for n = 1, ..., 257.
example : ((Finset.Icc 1 257).image (fun n : ℕ => 256 / n)).card = 32 := by decide +kernel

#print axioms lp_cauchy_seq_has_limit_in_lp
#print axioms lp_limit_has_ae_convergent_subsequence
#print axioms simple_functions_dense_in_lp
