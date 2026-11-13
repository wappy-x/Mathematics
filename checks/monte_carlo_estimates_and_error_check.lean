-- Monte Carlo: the average of n independent draws of g(U) aims exactly at E[g(U)], its spread is σ/√n, and Chebyshev bounds its chance of missing by ε or more by σ²/(nε²).
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory

lemma mc_aemeas {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    {P : Measure Ω} {ν : Measure α}
    (n : ℕ) (U : Fin n → Ω → α) (g : α → ℝ)
    (hlaw : ∀ i, P.map (U i) = ν) (hg : MemLp g 2 ν) (i : Fin n) :
    AEMeasurable g (P.map (U i)) := by
  rw [hlaw i]; exact hg.aestronglyMeasurable.aemeasurable

lemma mc_memLp {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    {P : Measure Ω} {ν : Measure α}
    (n : ℕ) (U : Fin n → Ω → α) (g : α → ℝ)
    (hU : ∀ i, Measurable (U i))
    (hlaw : ∀ i, P.map (U i) = ν) (hg : MemLp g 2 ν) (i : Fin n) :
    MemLp (fun ω => g (U i ω)) 2 P := by
  have : MemLp g 2 (P.map (U i)) := by rw [hlaw i]; exact hg
  exact this.comp_of_map (hU i).aemeasurable

lemma mc_var_sum {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    {P : Measure Ω} [IsProbabilityMeasure P] {ν : Measure α}
    (n : ℕ) (U : Fin n → Ω → α) (g : α → ℝ)
    (hU : ∀ i, Measurable (U i))
    (hind : iIndepFun U P)
    (hlaw : ∀ i, P.map (U i) = ν)
    (hg : MemLp g 2 ν) :
    variance (fun ω => ∑ i, g (U i ω)) P = n * variance g ν := by
  have hind' : iIndepFun (fun i => (fun _ => g) i ∘ U i) P :=
    hind.comp₀ (fun _ => g) (fun i => (hU i).aemeasurable) (mc_aemeas n U g hlaw hg)
  have h1 : (fun ω => ∑ i, g (U i ω)) = ∑ i, (fun ω => g (U i ω)) := by
    funext ω; simp [Finset.sum_apply]
  rw [h1, IndepFun.variance_sum (fun i _ => mc_memLp n U g hU hlaw hg i)
    (fun i _ j _ hij => hind'.indepFun hij)]
  have h2 : ∀ i, variance (fun ω => g (U i ω)) P = variance g ν := by
    intro i
    rw [← hlaw i, variance_map (mc_aemeas n U g hlaw hg i) (hU i).aemeasurable]
    rfl
  simp [h2]

lemma mc_var_avg {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    {P : Measure Ω} [IsProbabilityMeasure P] {ν : Measure α}
    (n : ℕ) (hn : 0 < n) (U : Fin n → Ω → α) (g : α → ℝ)
    (hU : ∀ i, Measurable (U i))
    (hind : iIndepFun U P)
    (hlaw : ∀ i, P.map (U i) = ν)
    (hg : MemLp g 2 ν) :
    variance (fun ω => (∑ i, g (U i ω)) / n) P = variance g ν / n := by
  simp_rw [div_eq_mul_inv]
  rw [variance_mul_const, mc_var_sum n U g hU hind hlaw hg]
  have : (n : ℝ) ≠ 0 := by positivity
  field_simp

/-- **The square-root-of-n error bar (Step 3).** Let `U 0, …, U (n−1)` be `n ≥ 1` random
points, independent of each other, each drawn from the intended law `ν`, and let `g` be a
function with finite variance under `ν` (its square has a finite average). Score each draw
`X i = g (U i)` and average the scores: `Î_n = (X 0 + ⋯ + X (n−1)) / n`. Then the average's
variance is one draw's variance `σ²` divided by `n`, and its standard deviation, the
standard error, is `σ / √n`. This holds exactly at every `n`; no bell curve is needed. -/
theorem monte_carlo_standard_error {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    {P : Measure Ω} [IsProbabilityMeasure P] {ν : Measure α}
    (n : ℕ) (hn : 0 < n) (U : Fin n → Ω → α) (g : α → ℝ)
    (hU : ∀ i, Measurable (U i))
    (hind : iIndepFun U P)
    (hlaw : ∀ i, P.map (U i) = ν)
    (hg : MemLp g 2 ν) :
    variance (fun ω => (∑ i, g (U i ω)) / n) P = variance g ν / n ∧
      Real.sqrt (variance (fun ω => (∑ i, g (U i ω)) / n) P)
        = Real.sqrt (variance g ν) / Real.sqrt n := by
  have h := mc_var_avg n hn U g hU hind hlaw hg
  refine ⟨h, ?_⟩
  rw [h, Real.sqrt_div' _ (Nat.cast_nonneg n)]

/-- **The average is right on average (Step 2).** Under the same conditions, the long-run
average of the estimate `Î_n` is the target `I = E[g(U)]`, the integral of `g` against the
law `ν`: the estimator has no bias. -/
theorem monte_carlo_unbiased {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    {P : Measure Ω} [IsProbabilityMeasure P] {ν : Measure α}
    (n : ℕ) (hn : 0 < n) (U : Fin n → Ω → α) (g : α → ℝ)
    (hU : ∀ i, Measurable (U i))
    (hind : iIndepFun U P)
    (hlaw : ∀ i, P.map (U i) = ν)
    (hg : MemLp g 2 ν) :
    ∫ ω, (∑ i, g (U i ω)) / n ∂P = ∫ x, g x ∂ν := by
  have hi : ∀ i, ∫ ω, g (U i ω) ∂P = ∫ x, g x ∂ν := by
    intro i
    rw [← hlaw i, integral_map (hU i).aemeasurable]
    rw [hlaw i]; exact hg.aestronglyMeasurable
  rw [integral_div, integral_finsetSum _ (fun i _ =>
    (mc_memLp n U g hU hlaw hg i).integrable one_le_two)]
  simp only [hi, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have : (n : ℝ) ≠ 0 := by positivity
  field_simp

/-- **Chebyshev's guarantee (Detailed proof).** Under the same conditions, for any tolerance
`ε > 0`, the chance that the estimate `Î_n` misses the target `I = E[g(U)]` by `ε` or more
is at most `σ² / (n ε²)`, where `σ²` is one draw's variance. -/
theorem monte_carlo_chebyshev {Ω α : Type*} [MeasurableSpace Ω] [MeasurableSpace α]
    {P : Measure Ω} [IsProbabilityMeasure P] {ν : Measure α}
    (n : ℕ) (hn : 0 < n) (U : Fin n → Ω → α) (g : α → ℝ)
    (hU : ∀ i, Measurable (U i))
    (hind : iIndepFun U P)
    (hlaw : ∀ i, P.map (U i) = ν)
    (hg : MemLp g 2 ν) (ε : ℝ) (hε : 0 < ε) :
    P {ω | ε ≤ |(∑ i, g (U i ω)) / n - ∫ x, g x ∂ν|}
      ≤ ENNReal.ofReal (variance g ν / (n * ε ^ 2)) := by
  have hY : MemLp (fun ω => (∑ i, g (U i ω)) / n) 2 P := by
    have := memLp_finsetSum Finset.univ (fun i _ => mc_memLp n U g hU hlaw hg i)
    simpa [div_eq_mul_inv] using this.mul_const ((n : ℝ)⁻¹)
  have h := meas_ge_le_variance_div_sq hY hε
  rw [monte_carlo_unbiased n hn U g hU hind hlaw hg,
    mc_var_avg n hn U g hU hind hlaw hg, div_div] at h
  exact h

-- The grid door: of the 100 × 100 cell centres ((2i+1)/200, (2j+1)/200), 7,857 lie in the
-- quarter circle, since x² + y² ≤ 1 is (2i+1)² + (2j+1)² ≤ 4·100².
example : ((List.range 100).flatMap fun i => (List.range 100).map fun j => (i, j)).countP
    (fun ij => (2 * ij.1 + 1) ^ 2 + (2 * ij.2 + 1) ^ 2 ≤ 4 * 100 * 100) = 7857 := by
  decide +kernel
-- The seeded run: 7,856 of 10,000 darts inside, so the estimate is 4 × 7856/10000 = 3.1424.
example : (4 : ℚ) * 7856 / 10000 = 31424 / 10000 := by norm_num
-- The first 20 darts: 17 inside, estimate 4 × 17/20 = 3.40.
example : (4 : ℚ) * 17 / 20 = 340 / 100 := by norm_num
-- Four times the darts halve the error bar and a hundred times divide it by ten: 2² = 4, 10² = 100.
example : (2 : ℕ) ^ 2 = 4 ∧ (10 : ℕ) ^ 2 = 100 := by decide

#print axioms mc_aemeas
#print axioms mc_memLp
#print axioms mc_var_sum
#print axioms mc_var_avg
#print axioms monte_carlo_standard_error
#print axioms monte_carlo_unbiased
#print axioms monte_carlo_chebyshev
