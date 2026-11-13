-- The Borel-Cantelli lemmas: if the chances of a list of events add up to a finite number then with probability 1 only finitely many of them happen, if the events are independent and their chances add up to infinity then with probability 1 infinitely many happen, and convergence in probability gives almost sure convergence along a subsequence.
import Mathlib.Probability.BorelCantelli
import Mathlib.MeasureTheory.OuterMeasure.BorelCantelli
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases

open MeasureTheory ProbabilityTheory Filter Topology
open scoped ENNReal

/-- The Borel-Cantelli lemmas. On a probability space, take a list of events A 0, A 1, A 2, ...
"Infinitely many of them happen" is the lim sup of the sets, ⋂ N, ⋃ n ≥ N, A n.
First lemma: if the chances P (A n) add up to a finite number, the chance that infinitely many
of the events happen is 0. Second lemma: if the events are independent and their chances add
up to infinity, the chance that infinitely many of them happen is 1. -/
theorem borel_cantelli_lemmas {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (hA : ∀ n, MeasurableSet (A n)) :
    ((∑' n, P (A n)) ≠ ∞ → P (limsup A atTop) = 0) ∧
    (iIndepSet A P → (∑' n, P (A n)) = ∞ → P (limsup A atTop) = 1) := by
  exact ⟨fun h => measure_limsup_atTop_eq_zero h,
    fun hind hsum => measure_limsup_eq_one hA hind hsum⟩

/-- The first lemma needs no independence and holds for any measure, not only probabilities:
if the measures of countably many measurable sets add up to a finite number, the set of points
lying in infinitely many of them has measure 0. -/
theorem first_borel_cantelli_any_measure {α : Type*} [MeasurableSpace α]
    (μ : Measure α) (A : ℕ → Set α) (hA : ∀ n, MeasurableSet (A n))
    (hsum : (∑' n, μ (A n)) ≠ ∞) :
    μ (limsup A atTop) = 0 := by
  exact measure_limsup_atTop_eq_zero hsum

/-- The corollary. If random variables X n converge to X in probability (for every tolerance
ε > 0, the chance that X n is more than ε from X goes to 0), then some subsequence X (n k),
with rising indices n k, converges to X almost surely: at every outcome outside a set of
probability zero. -/
theorem subsequence_converges_almost_surely {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (Y : Ω → ℝ) (hX : ∀ n, Measurable (X n)) (hY : Measurable Y)
    (hconv : ∀ ε : ℝ, 0 < ε →
      Tendsto (fun n => P {ω | ε < |X n ω - Y ω|}) atTop (𝓝 0)) :
    ∃ ns : ℕ → ℕ, StrictMono ns ∧
      ∀ᵐ ω ∂P, Tendsto (fun k => X (ns k) ω) atTop (𝓝 (Y ω)) := by
  have hm : TendstoInMeasure P X atTop Y := by
    rw [tendstoInMeasure_iff_dist]
    intro ε hε
    have h2 := hconv (ε / 2) (by positivity)
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds h2
      (fun _ => zero_le) ?_
    intro n
    apply measure_mono
    intro ω hω
    simp only [Set.mem_ofPred_eq, Real.dist_eq] at hω ⊢
    linarith
  exact hm.exists_seq_tendsto_ae

/-! ### The card's worked numbers: a fair die rolled forever -/

-- A six has chance 1/6; a miss has chance 1 - 1/6 = 5/6.
example : (1 : ℚ) - 1/6 = 5/6 := by norm_num
-- The run-start chances 6^(-1), 6^(-2), 6^(-3) are 1/6, 1/36, 1/216.
example : (1/6 : ℚ) ^ 1 = 1/6 ∧ (1/6 : ℚ) ^ 2 = 1/36 ∧ (1/6 : ℚ) ^ 3 = 1/216 := by norm_num
-- Their sum: (1/6) / (1 - 1/6) = 1/5.
example : (1/6 : ℚ) / (1 - 1/6) = 1/5 := by norm_num
-- Partial sums against the closed form (1 - 6^(-n))/5, for n = 1 to 6.
example : ∀ n ∈ Finset.range 7,
    ∑ k ∈ Finset.range n, (1/6 : ℚ) ^ (k + 1) = (1 - (1/6 : ℚ) ^ n) / 5 := by
  intro n hn
  rw [Finset.mem_range] at hn
  interval_cases n <;> norm_num [Finset.sum_range_succ]
-- A run-start at roll 1 or 2: 1/6 + 1/36 - 1/216 = 41/216 (the overlap is rolls 1 to 3 all sixes).
example : (1/6 : ℚ) + 1/36 - 1/216 = 41/216 := by norm_num
-- The union bound from N = 3: the run-start chances from 3 on add to 6^(-2)/5 = 1/180.
example : (1/6 : ℚ) ^ 3 / (1 - 1/6) = (1/6) ^ 2 / 5 ∧ (1/6 : ℚ) ^ 2 / 5 = 1/180 := by norm_num
-- Mean number of run-starts, the sum of their chances: 1/5.
-- Chebyshev for the share of sixes: variance (1/6)(5/6)/n = 5/(36 n); with tolerance 1/20 the
-- miss bound 5/(36 n (1/20)^2) is 500/(9 n), which is 5/9 at n = 100.
example : (1/6 : ℚ) * (5/6) = 5/36 := by norm_num
example : ∀ n : ℚ, n ≠ 0 → 5 / (36 * n * (1/20) ^ 2) = 500 / (9 * n) := by
  intro n hn
  field_simp
  norm_num
example : (500 : ℚ) / (9 * 100) = 5/9 := by norm_num
-- Tail of the bounds along the squares beyond K: 500/(9K), 5/9 at K = 100 and 1/18 at K = 1000.
example : (500 : ℚ) / (9 * 1000) = 1/18 := by norm_num
-- The subsequence: misses of at most 2^(-k) at step n_k have chances adding to at most 1.
example : ∀ m : ℕ, ∑ k ∈ Finset.range m, (1/2 : ℚ) ^ (k + 1) ≤ 1 := by
  intro m
  have h : ∑ k ∈ Finset.range m, (1/2 : ℚ) ^ (k + 1) = 1 - (1/2) ^ m := by
    induction m with
    | zero => simp
    | succ m ih => rw [Finset.sum_range_succ, ih, pow_succ]; ring
  rw [h]
  have : (0 : ℚ) ≤ (1/2) ^ m := by positivity
  linarith

#print axioms borel_cantelli_lemmas
#print axioms first_borel_cantelli_any_measure
#print axioms subsequence_converges_almost_surely
