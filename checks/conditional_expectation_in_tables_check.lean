-- Conditional expectation: averaging the conditional averages of X given each value of a finitely-valued Y, weighted by the chance of that value, gives back the plain average of X (the tower rule); the conditional average is the best guess of X from Y in squared error; and a random number of claims, independent of their sizes, has average total E[N] times E[X].
import Mathlib.Probability.ConditionalProbability
import Mathlib.Probability.Notation
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

lemma ce_decomp {Ω R : Type*} [MeasurableSpace Ω] [Fintype R] [MeasurableSpace R]
    [DiscreteMeasurableSpace R] (P : Measure Ω) [IsProbabilityMeasure P]
    (Y : Ω → R) (hY : Measurable Y) (F : Ω → ℝ) (hF : Integrable F P) :
    ∫ ω, F ω ∂P = ∑ y, P.real (Y ⁻¹' {y}) * ∫ ω, F ω ∂(P[|Y ← y]) := by
  have hsum := sum_meas_smul_cond_fiber hY P
  have hint : Integrable F (∑ y, P (Y ⁻¹' {y}) • P[|Y ← y]) := by rw [hsum]; exact hF
  rw [integrable_finsetSum_measure] at hint
  calc ∫ ω, F ω ∂P = ∫ ω, F ω ∂(∑ y, P (Y ⁻¹' {y}) • P[|Y ← y]) := by rw [hsum]
    _ = _ := by
      rw [integral_finsetSum_measure hint]
      refine Finset.sum_congr rfl fun y _ => ?_
      rw [integral_smul_measure, smul_eq_mul, measureReal_def]

lemma ce_cond_eval {Ω R : Type*} [MeasurableSpace Ω] [MeasurableSpace R]
    [DiscreteMeasurableSpace R] (P : Measure Ω)
    (Y : Ω → R) (hY : Measurable Y) (F : Ω → R → ℝ) (y : R) :
    ∫ ω, F ω (Y ω) ∂(P[|Y ← y]) = ∫ ω, F ω y ∂(P[|Y ← y]) := by
  refine integral_congr_ae ?_
  filter_upwards [ae_cond_mem (μ := P) (hY (measurableSet_singleton y))] with ω hω
  rw [Set.mem_preimage, Set.mem_singleton_iff] at hω
  rw [hω]

lemma ce_memLp_comp {Ω R : Type*} [MeasurableSpace Ω] [Fintype R] [MeasurableSpace R]
    [DiscreteMeasurableSpace R] (P : Measure Ω) [IsProbabilityMeasure P]
    (Y : Ω → R) (hY : Measurable Y) (k : R → ℝ) : MemLp (fun ω => k (Y ω)) 2 P :=
  MemLp.of_bound ((Measurable.of_discrete (f := k)).comp hY).aestronglyMeasurable
    (∑ y, ‖k y‖) (ae_of_all _ fun ω =>
      Finset.single_le_sum (f := fun y => ‖k y‖) (fun _ _ => norm_nonneg _)
        (Finset.mem_univ (Y ω)))

lemma ce_memLp_cond {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (X : Ω → ℝ)
    (hX : MemLp X 2 P) (s : Set Ω) (hs : P s ≠ 0) : MemLp X 2 (P[|s]) := by
  rw [ProbabilityTheory.cond]
  exact (hX.restrict s).smul_measure (ENNReal.inv_ne_top.mpr hs)

lemma ce_sq_dev {Ω : Type*} [MeasurableSpace Ω] (Q : Measure Ω) [IsProbabilityMeasure Q]
    (X : Ω → ℝ) (hX : MemLp X 2 Q) (c : ℝ) :
    ∫ ω, (X ω - c) ^ 2 ∂Q = ∫ ω, X ω ^ 2 ∂Q - 2 * c * ∫ ω, X ω ∂Q + c ^ 2 := by
  have h1 := hX.integrable_sq
  have h2 := hX.integrable one_le_two
  have : (fun ω => (X ω - c) ^ 2) = fun ω => (X ω ^ 2 - 2 * c * X ω) + c ^ 2 := by
    funext ω; ring
  have hA : Integrable (fun ω => X ω ^ 2 - 2 * c * X ω) Q := h1.sub (h2.const_mul _)
  have hB : Integrable (fun ω => 2 * c * X ω) Q := h2.const_mul _
  rw [this, integral_add hA (integrable_const _), integral_sub h1 hB, integral_const_mul,
    integral_const]
  simp

#print axioms ce_decomp
#print axioms ce_cond_eval
#print axioms ce_memLp_comp
#print axioms ce_memLp_cond
#print axioms ce_sq_dev

/-- The tower rule. `Y` takes finitely many values (the regions), each with a positive
chance, and `X` has an average. `E[X | Y = y]` is the average of `X` under the chances
rescaled to the outcomes with `Y = y` (Mathlib's conditional measure `P[|Y ← y]`).
Then the average of the random amount `E[X | Y] = g(Y)` is the plain average of `X`, and
it equals the sum over regions of `P(Y = y)` times `E[X | Y = y]`. -/
theorem tower_rule {Ω R : Type*} [MeasurableSpace Ω] [Fintype R] [MeasurableSpace R]
    [DiscreteMeasurableSpace R] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (Y : Ω → R) (hY : Measurable Y) (hX : Integrable X P)
    (hpos : ∀ y, 0 < P (Y ⁻¹' {y})) :
    ∫ ω, (∫ ω', X ω' ∂(P[|Y ← Y ω])) ∂P = ∫ ω, X ω ∂P ∧
      ∑ y, P.real (Y ⁻¹' {y}) * ∫ ω, X ω ∂(P[|Y ← y]) = ∫ ω, X ω ∂P := by
  have h2 : ∑ y, P.real (Y ⁻¹' {y}) * ∫ ω, X ω ∂(P[|Y ← y]) = ∫ ω, X ω ∂P :=
    (ce_decomp P Y hY X hX).symm
  refine ⟨?_, h2⟩
  rw [← h2, ce_decomp P Y hY _
    ((ce_memLp_comp P Y hY (fun y => ∫ ω', X ω' ∂(P[|Y ← y]))).integrable one_le_two)]
  refine Finset.sum_congr rfl fun y _ => ?_
  have := cond_isProbabilityMeasure (μ := P) (hpos y).ne'
  rw [ce_cond_eval P Y hY (fun _ y => ∫ ω', X ω' ∂(P[|Y ← y])) y, integral_const]
  simp

/-- The best guess from the information. With `g(y) = E[X | Y = y]` and `X` of finite
variance, any rival guess `h(Y)` that uses only the region has average squared error equal
to that of `g(Y)` plus `∑ P(Y = y) (g(y) - h(y))²`. So `E[X | Y]` has the smallest average
squared error, and shifting every guess by `c` costs exactly `c²`. -/
theorem cond_expectation_best_guess {Ω R : Type*} [MeasurableSpace Ω] [Fintype R]
    [MeasurableSpace R] [DiscreteMeasurableSpace R] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (Y : Ω → R) (hY : Measurable Y) (hX : MemLp X 2 P)
    (hpos : ∀ y, 0 < P (Y ⁻¹' {y})) (h : R → ℝ) :
    ∫ ω, (X ω - h (Y ω)) ^ 2 ∂P =
      ∫ ω, (X ω - ∫ ω', X ω' ∂(P[|Y ← Y ω])) ^ 2 ∂P +
        ∑ y, P.real (Y ⁻¹' {y}) * ((∫ ω, X ω ∂(P[|Y ← y])) - h y) ^ 2 := by
  have hI1 : Integrable (fun ω => (X ω - h (Y ω)) ^ 2) P :=
    (hX.sub (ce_memLp_comp P Y hY h)).integrable_sq
  have hI2 : Integrable (fun ω => (X ω - ∫ ω', X ω' ∂(P[|Y ← Y ω])) ^ 2) P :=
    (hX.sub (ce_memLp_comp P Y hY (fun y => ∫ ω', X ω' ∂(P[|Y ← y])))).integrable_sq
  rw [ce_decomp P Y hY _ hI1, ce_decomp P Y hY _ hI2, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun y _ => ?_
  have := cond_isProbabilityMeasure (μ := P) (hpos y).ne'
  have hXy := ce_memLp_cond P X hX _ (hpos y).ne'
  rw [ce_cond_eval P Y hY (fun ω y => (X ω - h y) ^ 2) y,
    ce_cond_eval P Y hY (fun ω y => (X ω - ∫ ω', X ω' ∂(P[|Y ← y])) ^ 2) y]
  rw [ce_sq_dev _ X hXy, ce_sq_dev _ X hXy]
  ring

/-- The random-sum shortcut (frequency times severity). The month has `N` claims, at most
`M`, with sizes `X 0, X 1, …`; every claim follows the same law as `X 0`, which has an
average, and the number of claims does not depend on any claim's size. Then the average
total `S = X 0 + … + X (N - 1)` is `E[N] × E[X]`. -/
theorem random_sum_mean {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (N : Ω → ℕ) (hN : Measurable N) (M : ℕ) (hNM : ∀ ω, N ω ≤ M)
    (X : ℕ → Ω → ℝ) (hX0 : Integrable (X 0) P) (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hindep : ∀ i, IndepFun N (X i) P) :
    ∫ ω, (∑ i ∈ Finset.range (N ω), X i ω) ∂P = (∫ ω, (N ω : ℝ) ∂P) * ∫ ω, X 0 ω ∂P := by
  have hXi : ∀ i, Integrable (X i) P := fun i => (hident i).integrable_iff.mpr hX0
  let φ : ℕ → ℕ → ℝ := fun i n => if i < n then 1 else 0
  have hφm : ∀ i, Measurable (φ i) := fun i => Measurable.of_discrete
  have hφb : ∀ i ω, ‖φ i (N ω)‖ ≤ 1 := by
    intro i ω; simp only [φ]; split_ifs <;> simp
  have hind_int : ∀ i, Integrable (fun ω => φ i (N ω)) P := fun i =>
    Integrable.of_bound ((hφm i).comp hN).aestronglyMeasurable 1 (ae_of_all _ (hφb i))
  have hsplit : ∀ (f : ℕ → ℝ) (n : ℕ), n ≤ M →
      ∑ i ∈ Finset.range n, f i = ∑ i ∈ Finset.range M, φ i n * f i := by
    intro f n hn
    simp only [φ, ite_mul, one_mul, zero_mul]
    simp_rw [← Finset.mem_range (n := n)]
    rw [Finset.sum_ite_mem, Finset.inter_eq_right.mpr (Finset.range_subset_range.mpr hn)]
  have hL : (fun ω => ∑ i ∈ Finset.range (N ω), X i ω) =
      fun ω => ∑ i ∈ Finset.range M, φ i (N ω) * X i ω := by
    funext ω; exact hsplit (fun i => X i ω) (N ω) (hNM ω)
  have hR : (fun ω => (N ω : ℝ)) = fun ω => ∑ i ∈ Finset.range M, φ i (N ω) := by
    funext ω
    have := hsplit (fun _ => 1) (N ω) (hNM ω)
    simpa using this
  have hterm : ∀ i, ∫ ω, φ i (N ω) * X i ω ∂P = (∫ ω, φ i (N ω) ∂P) * ∫ ω, X 0 ω ∂P := by
    intro i
    have hI : IndepFun (fun ω => φ i (N ω)) (X i) P :=
      (hindep i).comp (hφm i) measurable_id
    rw [← (hident i).integral_eq]
    exact hI.integral_mul_eq_mul_integral ((hφm i).comp hN).aestronglyMeasurable
      (hXi i).aestronglyMeasurable
  rw [hL, hR, integral_finsetSum _ (fun i _ => ?_), integral_finsetSum _ (fun i _ => hind_int i),
    Finset.sum_mul]
  · exact Finset.sum_congr rfl fun i _ => hterm i
  · exact (hXi i).bdd_mul ((hφm i).comp hN).aestronglyMeasurable (ae_of_all _ (hφb i))

/-! The card's claims table. Chances are counts out of 100 claims, so every number is whole
or a fraction; no decimals appear. Rows: North 30, 15, 5; Inland 15, 12, 3; Coast 6, 6, 8,
for claims of $1,000, $5,000 and $20,000. -/

-- E[X | North] = 2,050 / 0.50 = 4,100: the North row in counts, divided by its 50 claims.
example : ((1000 * 30 + 5000 * 15 + 20000 * 5) / 50 : ℚ) = 4100 := by norm_num

-- E[X | Inland] = 1,350 / 0.30 = 4,500.
example : ((1000 * 15 + 5000 * 12 + 20000 * 3) / 30 : ℚ) = 4500 := by norm_num

-- E[X | Coast] = 1,960 / 0.20 = 9,800, with the Coast chances rescaled to 3/10, 3/10, 2/5.
example : ((1000 * 6 + 5000 * 6 + 20000 * 8) / 100 : ℚ) = 1960 := by norm_num
example : ((1960 : ℚ) / (20 / 100)) = 9800 := by norm_num
example : ((6 : ℚ) / 20, (6 : ℚ) / 20, (8 : ℚ) / 20) = (3 / 10, 3 / 10, 2 / 5) := by norm_num

-- Tower terms and the tower rule: 2,050 + 1,350 + 1,960 = 5,360.
example : ((50 : ℚ) / 100 * 4100, (30 : ℚ) / 100 * 4500, (20 : ℚ) / 100 * 9800) =
    (2050, 1350, 1960) := by norm_num
example : ((50 : ℚ) / 100 * 4100 + 30 / 100 * 4500 + 20 / 100 * 9800) = 5360 := by norm_num

-- Check by columns: column totals 51, 33, 16, and 1,000 × 0.51 + 5,000 × 0.33 + 20,000 × 0.16 = 5,360.
example : (30 + 15 + 6, 15 + 12 + 6, 5 + 3 + 8) = (51, 33, 16) := by decide
example : ((1000 * 51 + 5000 * 33 + 20000 * 16) / 100 : ℚ) = 5360 := by norm_num

-- Equal weights on the region means give 18,400 / 3 (about 6,133.33), not 5,360.
example : ((4100 + 4500 + 9800) / 3 : ℚ) = 18400 / 3 ∧ (18400 / 3 : ℚ) ≠ 5360 := by norm_num

-- Squared errors: variance 44,030,400; between regions 4,958,400; within regions 39,072,000.
example : ((1000 ^ 2 * 51 + 5000 ^ 2 * 33 + 20000 ^ 2 * 16) / 100 - 5360 ^ 2 : ℚ) = 44030400 := by
  norm_num
example : ((50 * (4100 - 5360) ^ 2 + 30 * (4500 - 5360) ^ 2 + 20 * (9800 - 5360) ^ 2) / 100 : ℚ) =
    4958400 := by norm_num
example : ((30 * (1000 - 4100) ^ 2 + 15 * (5000 - 4100) ^ 2 + 5 * (20000 - 4100) ^ 2
    + 15 * (1000 - 4500) ^ 2 + 12 * (5000 - 4500) ^ 2 + 3 * (20000 - 4500) ^ 2
    + 6 * (1000 - 9800) ^ 2 + 6 * (5000 - 9800) ^ 2 + 8 * (20000 - 9800) ^ 2) / 100 : ℚ) =
    39072000 := by norm_num
example : (44030400 : ℚ) = 39072000 + 4958400 := by norm_num

-- Shifting every regional guess by 500 adds 500 × 500: 39,322,000.
example : (39072000 + 500 * 500 : ℚ) = 39322000 := by norm_num

-- The month: E[N] = 0 × 1/10 + 1 × 3/10 + 2 × 4/10 + 3 × 2/10 = 17/10, and 17/10 × 5,360 = 9,112.
example : ((0 * 1 + 1 * 3 + 2 * 4 + 3 * 2) / 10 : ℚ) = 17 / 10 := by norm_num
example : ((17 : ℚ) / 10 * 5360) = 9112 := by norm_num

-- E[S | N = n] = n × 5,360 for n = 0 to 3.
example : ((0 : ℚ) * 5360, (1 : ℚ) * 5360, (2 : ℚ) * 5360, (3 : ℚ) * 5360) = (0, 5360, 10720, 16080) := by
  norm_num

-- Storm months (three-claim months are all Coast): the tower gives
-- 3/10 × 5,360 + 4/10 × 2 × 5,360 + 2/10 × 3 × 9,800 = 11,776, not 9,112.
example : ((3 : ℚ) / 10 * 5360 + 4 / 10 * (2 * 5360) + 2 / 10 * (3 * 9800)) = 11776 := by norm_num

#print axioms tower_rule
#print axioms cond_expectation_best_guess
#print axioms random_sum_mean
