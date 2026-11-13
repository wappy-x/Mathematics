-- Conditional expectation as a projection: for a square-integrable X, the error X - E[X | G] is orthogonal to every square-integrable G-measurable Z, so E[(X - Z)^2] = E[(X - M)^2] + E[(M - Z)^2], M is the unique closest G-measurable forecast, and the law of total variance follows.
import Mathlib.Probability.CondVar
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Real
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.BigOperators.Intervals

open MeasureTheory ProbabilityTheory

theorem condExp_error_orthogonal_aux {Ω : Type*} {m m₀ : MeasurableSpace Ω}
    (hm : m ≤ m₀) {μ : Measure[m₀] Ω} [IsProbabilityMeasure μ] {X Z : Ω → ℝ}
    (hX : MemLp X 2 μ) (hZm : StronglyMeasurable[m] Z) (hZ : MemLp Z 2 μ) :
    ∫ ω, (X ω - μ[X | m] ω) * Z ω ∂μ = 0 := by
  have hXi : Integrable X μ := hX.integrable one_le_two
  have hM : MemLp (μ[X | m]) 2 μ := hX.condExp one_le_two
  have hXZ : Integrable (X * Z) μ := memLp_one_iff_integrable.1 (hX.mul hZ)
  have hMZ : Integrable (μ[X | m] * Z) μ := memLp_one_iff_integrable.1 (hM.mul hZ)
  have h1 : ∫ ω, (X * Z) ω ∂μ = ∫ ω, (μ[X | m] * Z) ω ∂μ := by
    rw [← integral_condExp hm]
    exact integral_congr_ae (condExp_mul_of_stronglyMeasurable_right hZm hXZ hXi)
  have : (fun ω => (X ω - μ[X | m] ω) * Z ω) = fun ω => (X * Z) ω - (μ[X | m] * Z) ω := by
    funext ω; simp only [Pi.mul_apply]; ring
  rw [this, integral_sub hXZ hMZ, h1, sub_self]

#print axioms condExp_error_orthogonal_aux

/-- For a quantity X with finite mean square on a probability space and a sub-sigma-algebra G,
the error X - E[X | G] has zero average product with every known (G-measurable) quantity Z of
finite mean square, and the mean squared error of Z is the error of E[X | G] plus the mean
squared distance between E[X | G] and Z (Pythagoras). -/
theorem condExp_error_orthogonal_and_pythagoras {Ω : Type*} {m m₀ : MeasurableSpace Ω}
    (hm : m ≤ m₀) {μ : Measure[m₀] Ω} [IsProbabilityMeasure μ] {X Z : Ω → ℝ}
    (hX : MemLp X 2 μ) (hZm : Measurable[m] Z) (hZ : MemLp Z 2 μ) :
    ∫ ω, (X ω - μ[X | m] ω) * Z ω ∂μ = 0 ∧
    ∫ ω, (X ω - Z ω) ^ 2 ∂μ =
      ∫ ω, (X ω - μ[X | m] ω) ^ 2 ∂μ + ∫ ω, (μ[X | m] ω - Z ω) ^ 2 ∂μ := by
  refine ⟨condExp_error_orthogonal_aux hm hX hZm.stronglyMeasurable hZ, ?_⟩
  have hM : MemLp (μ[X | m]) 2 μ := hX.condExp one_le_two
  have hMZm : StronglyMeasurable[m] (μ[X | m] - Z) :=
    stronglyMeasurable_condExp.sub hZm.stronglyMeasurable
  have h0 := condExp_error_orthogonal_aux hm hX hMZm (hM.sub hZ)
  have i1 : Integrable (fun ω => (X ω - μ[X | m] ω) ^ 2) μ := (hX.sub hM).integrable_sq
  have i2 : Integrable (fun ω => (μ[X | m] ω - Z ω) ^ 2) μ := (hM.sub hZ).integrable_sq
  have i3 : Integrable (fun ω => (X ω - μ[X | m] ω) * (μ[X | m] - Z) ω) μ :=
    memLp_one_iff_integrable.1 ((hX.sub hM).mul (hM.sub hZ))
  have : (fun ω => (X ω - Z ω) ^ 2) = fun ω => ((X ω - μ[X | m] ω) ^ 2
      + (μ[X | m] ω - Z ω) ^ 2) + 2 * ((X ω - μ[X | m] ω) * (μ[X | m] - Z) ω) := by
    funext ω; simp only [Pi.sub_apply]; ring
  have i12 : Integrable (fun ω => (X ω - μ[X | m] ω) ^ 2 + (μ[X | m] ω - Z ω) ^ 2) μ :=
    i1.add i2
  have i3' : Integrable (fun ω => 2 * ((X ω - μ[X | m] ω) * (μ[X | m] - Z) ω)) μ :=
    i3.const_mul 2
  rw [this, integral_add i12 i3', integral_add i1 i2, integral_const_mul,
    h0, mul_zero, add_zero]

/-- The conditional expectation is the closest known quantity in mean square: no known Z of
finite mean square has a smaller mean squared error, and a known Z ties it exactly when Z equals
E[X | G] almost surely. -/
theorem condExp_is_unique_closest_known {Ω : Type*} {m m₀ : MeasurableSpace Ω}
    (hm : m ≤ m₀) {μ : Measure[m₀] Ω} [IsProbabilityMeasure μ] {X Z : Ω → ℝ}
    (hX : MemLp X 2 μ) (hZm : Measurable[m] Z) (hZ : MemLp Z 2 μ) :
    ∫ ω, (X ω - μ[X | m] ω) ^ 2 ∂μ ≤ ∫ ω, (X ω - Z ω) ^ 2 ∂μ ∧
    (∫ ω, (X ω - Z ω) ^ 2 ∂μ = ∫ ω, (X ω - μ[X | m] ω) ^ 2 ∂μ ↔ Z =ᵐ[μ] μ[X | m]) := by
  have hP := (condExp_error_orthogonal_and_pythagoras hm hX hZm hZ).2
  have hM : MemLp (μ[X | m]) 2 μ := hX.condExp one_le_two
  have i2 : Integrable (fun ω => (μ[X | m] ω - Z ω) ^ 2) μ := (hM.sub hZ).integrable_sq
  have hnn : 0 ≤ ∫ ω, (μ[X | m] ω - Z ω) ^ 2 ∂μ := integral_nonneg fun ω => sq_nonneg _
  refine ⟨by rw [hP]; linarith, ?_⟩
  rw [hP]
  constructor
  · intro h
    have h0 : ∫ ω, (μ[X | m] ω - Z ω) ^ 2 ∂μ = 0 := by linarith
    rw [integral_eq_zero_iff_of_nonneg (fun ω => sq_nonneg _) i2] at h0
    filter_upwards [h0] with ω hω
    simp only [Pi.zero_apply] at hω
    have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 hω
    linarith
  · intro h
    have : (fun ω => (μ[X | m] ω - Z ω) ^ 2) =ᵐ[μ] fun _ => (0 : ℝ) := by
      filter_upwards [h] with ω hω
      rw [hω]; ring
    rw [integral_congr_ae this, integral_zero, add_zero]

/-- Law of total variance: for X with finite mean square, the variance of X is the average
conditional variance (the spread inside the known groups) plus the variance of E[X | G]
(the spread between them). -/
theorem law_of_total_variance {Ω : Type*} {m m₀ : MeasurableSpace Ω}
    (hm : m ≤ m₀) {μ : Measure[m₀] Ω} [IsProbabilityMeasure μ] {X : Ω → ℝ}
    (hX : MemLp X 2 μ) :
    Var[X; μ] = μ[Var[X; μ | m]] + Var[μ[X | m]; μ] := by
  exact (integral_condVar_add_variance_condExp hm hX).symm

/-! The card's rainfall example: eight equally likely cases, so every average is a sum over
`Fin 8` divided by 8. The sums below are 8 times the card's averages. -/

-- rainfall X, seasonal means M, temperature T, in the order winter dry/wet, spring, summer, autumn
-- error X - M is orthogonal to the four season indicators and to T
example : (∑ i : Fin 8, ((![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i
    - (![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i)
    * (![5, 5, 11, 11, 19, 19, 13, 13] : Fin 8 → ℤ) i) = 0 := by decide

example : ∀ s : Fin 4, (∑ i : Fin 8, if i.val / 2 = s.val then
    ((![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i
      - (![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i) else 0) = 0 := by decide

-- E[X] = 55, E[X^2] = 3650, E[M^2] = 3550
example : (∑ i : Fin 8, (![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i) = 8 * 55 := by decide
example : (∑ i : Fin 8, (![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i ^ 2) = 8 * 3650 := by
  decide
example : (∑ i : Fin 8, (![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i ^ 2) = 8 * 3550 := by
  decide

-- Pythagoras with Z = 55: 625 = 100 + 525
example : (∑ i : Fin 8, ((![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i - 55) ^ 2) = 8 * 625 ∧
    (∑ i : Fin 8, ((![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i
      - (![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i) ^ 2) = 8 * 100 ∧
    (∑ i : Fin 8, ((![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i - 55) ^ 2) = 8 * 525 := by
  decide

-- the line 7 + 4T: error 225 = 100 + 125
example : (∑ i : Fin 8, ((![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i
      - (7 + 4 * (![5, 5, 11, 11, 19, 19, 13, 13] : Fin 8 → ℤ) i)) ^ 2) = 8 * 225 ∧
    (∑ i : Fin 8, ((![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i
      - (7 + 4 * (![5, 5, 11, 11, 19, 19, 13, 13] : Fin 8 → ℤ) i)) ^ 2) = 8 * 125 := by
  decide

-- the hand table
example : (30 + 60 + 90 + 40 : ℚ) / 4 = 55 := by norm_num
example : ((25 : ℚ) ^ 2 + 5 ^ 2 + 35 ^ 2 + 15 ^ 2) / 4 = 525 := by norm_num
example : (3650 : ℤ) - 55 ^ 2 = 625 ∧ (100 : ℤ) + 525 = 625 := by norm_num
example : (100 : ℚ) + ((3 : ℚ) ^ 2 + 9 ^ 2 + 7 ^ 2 + 19 ^ 2) / 4 = 225 := by norm_num
example : (400 : ℤ) + 125 = 525 := by norm_num

-- the peeking forecast Z = X: E[(X - M)(M - X)] = -100, not 0
example : (∑ i : Fin 8, ((![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i
    - (![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i)
    * ((![30, 30, 60, 60, 90, 90, 40, 40] : Fin 8 → ℤ) i
      - (![20, 40, 50, 70, 80, 100, 30, 50] : Fin 8 → ℤ) i)) = 8 * (-100) := by decide

-- desert month 0, 0, 0, 40: squared loss 300 vs 400, absolute loss 15 vs 10
example : ((0 - 10 : ℚ) ^ 2 * 3 + (40 - 10) ^ 2) / 4 = 300 ∧ ((40 : ℚ) ^ 2) / 4 = 400 ∧
    (|(0 - 10 : ℚ)| * 3 + |(40 - 10 : ℚ)|) / 4 = 15 ∧ (40 : ℚ) / 4 = 10 := by norm_num

-- X = 2^k with probability 3/4^k: the mean-square partial sums are 15, 30, 60
example : (∑ k ∈ Finset.Icc 1 5, (3 : ℚ) / 4 ^ k * (2 ^ k) ^ 2) = 15 ∧
    (∑ k ∈ Finset.Icc 1 10, (3 : ℚ) / 4 ^ k * (2 ^ k) ^ 2) = 30 ∧
    (∑ k ∈ Finset.Icc 1 20, (3 : ℚ) / 4 ^ k * (2 ^ k) ^ 2) = 60 := by
  norm_num [Finset.sum_Icc_succ_top]

#print axioms condExp_error_orthogonal_and_pythagoras
#print axioms condExp_is_unique_closest_known
#print axioms law_of_total_variance
