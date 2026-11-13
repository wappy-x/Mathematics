-- Jensen's inequality: for a convex function on an interval holding a random variable's values, the function of the average is at most the average of the function, with the square and logarithm cases.
import Mathlib.Analysis.Convex.Integral
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Algebra.BigOperators.Intervals

open MeasureTheory ProbabilityTheory

theorem jensen_support_line_aux {s : Set ℝ} {φ : ℝ → ℝ} (hφ : ConvexOn ℝ s φ) {m y z : ℝ}
    (hy : y ∈ s) (hz : z ∈ s) (hym : y < m) (hmz : m < z) :
    ∃ c : ℝ, ∀ x ∈ s, φ m + c * (x - m) ≤ φ x := by
  have hm : m ∈ s := hφ.1.ordConnected.out hy hz ⟨hym.le, hmz.le⟩
  set S := (fun w => (φ m - φ w) / (m - w)) '' {w | w ∈ s ∧ w < m} with hS
  have hne : S.Nonempty := ⟨_, ⟨y, ⟨hy, hym⟩, rfl⟩⟩
  have hbdd : BddAbove S := by
    refine ⟨(φ z - φ m) / (z - m), ?_⟩
    rintro _ ⟨w, ⟨hw, hwm⟩, rfl⟩
    exact hφ.slope_mono_adjacent hw hz hwm hmz
  refine ⟨sSup S, fun x hx => ?_⟩
  rcases lt_trichotomy x m with hxm | rfl | hxm
  · have h1 : (φ m - φ x) / (m - x) ≤ sSup S := le_csSup hbdd ⟨x, ⟨hx, hxm⟩, rfl⟩
    have hpos : 0 < m - x := sub_pos.mpr hxm
    rw [div_le_iff₀ hpos] at h1
    nlinarith
  · simp
  · have h1 : sSup S ≤ (φ x - φ m) / (x - m) := by
      apply csSup_le hne
      rintro _ ⟨w, ⟨hw, hwm⟩, rfl⟩
      exact hφ.slope_mono_adjacent hw hx hwm hxm
    have hpos : 0 < x - m := sub_pos.mpr hxm
    rw [le_div_iff₀ hpos] at h1
    nlinarith

#print axioms jensen_support_line_aux

theorem jensen_ae_eq_of_le_aux {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {X : Ω → ℝ} {m : ℝ} (hX : Integrable X μ)
    (hle : ∀ᵐ ω ∂μ, m ≤ X ω) (hint : ∫ ω, X ω ∂μ = m) : ∀ᵐ ω ∂μ, X ω = m := by
  have h0 : ∫ ω, (X ω - m) ∂μ = 0 := by
    rw [integral_sub hX (integrable_const m), hint]; simp
  have hnn : 0 ≤ᵐ[μ] fun ω => X ω - m := by
    filter_upwards [hle] with ω h; simp [h]
  have := (integral_eq_zero_iff_of_nonneg_ae hnn (hX.sub (integrable_const m))).1 h0
  filter_upwards [this] with ω h
  simpa [sub_eq_zero] using h

#print axioms jensen_ae_eq_of_le_aux

/-- Jensen's inequality. Let `X` be a random variable on a probability space and `φ` a function
that bends upward (is convex) on an interval `s` holding every value of `X`. If the averages of
`X` and of `φ(X)` both exist, then `φ` of the average is at most the average of `φ`:
`φ(E[X]) ≤ E[φ(X)]`. -/
theorem jensen_convex_map_expectation_le {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {s : Set ℝ} {φ : ℝ → ℝ} {X : Ω → ℝ}
    (hφ : ConvexOn ℝ s φ) (hXs : ∀ᵐ ω ∂μ, X ω ∈ s)
    (hX : Integrable X μ) (hφX : Integrable (fun ω => φ (X ω)) μ) :
    φ (∫ ω, X ω ∂μ) ≤ ∫ ω, φ (X ω) ∂μ := by
  set m := ∫ ω, X ω ∂μ with hm
  -- constant case helper
  have hconst : (∀ᵐ ω ∂μ, X ω = m) → φ m ≤ ∫ ω, φ (X ω) ∂μ := by
    intro hae
    have : (fun ω => φ (X ω)) =ᵐ[μ] fun _ => φ m := by
      filter_upwards [hae] with ω h; rw [h]
    rw [integral_congr_ae this]; simp
  by_cases hz : ∃ z ∈ s, m < z
  · by_cases hy : ∃ y ∈ s, y < m
    · obtain ⟨z, hzs, hmz⟩ := hz
      obtain ⟨y, hys, hym⟩ := hy
      obtain ⟨c, hc⟩ := jensen_support_line_aux hφ hys hzs hym hmz
      have h1 : Integrable (fun ω => X ω - m) μ := hX.sub (integrable_const m)
      have h2 : Integrable (fun ω => c * (X ω - m)) μ := h1.const_mul c
      have hlin : Integrable (fun ω => φ m + c * (X ω - m)) μ := (integrable_const _).add h2
      have hcalc : ∫ ω, (φ m + c * (X ω - m)) ∂μ = φ m := by
        rw [integral_add (integrable_const _) h2,
          integral_const_mul, integral_sub hX (integrable_const m)]
        simp [← hm]
      calc φ m = ∫ ω, (φ m + c * (X ω - m)) ∂μ := hcalc.symm
        _ ≤ ∫ ω, φ (X ω) ∂μ := by
          apply integral_mono_ae hlin hφX
          filter_upwards [hXs] with ω h using hc _ h
    · push Not at hy
      apply hconst
      exact jensen_ae_eq_of_le_aux hX (by filter_upwards [hXs] with ω h using hy _ h) hm.symm
  · push Not at hz
    apply hconst
    have hneg := jensen_ae_eq_of_le_aux (m := -m) (X := fun ω => -X ω) hX.neg
      (by filter_upwards [hXs] with ω h; simpa using hz _ h)
      (by show ∫ ω, -X ω ∂μ = -m; rw [integral_neg])
    filter_upwards [hneg] with ω h; simpa using h

/-- The logarithm bends downward, so for a positive random variable whose average and average
logarithm both exist, the average of the logarithms is at most the logarithm of the average:
`E[ln X] ≤ ln E[X]`. -/
theorem expectation_log_le_log_expectation {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] {X : Ω → ℝ}
    (hpos : ∀ᵐ ω ∂μ, 0 < X ω) (hX : Integrable X μ)
    (hlogX : Integrable (fun ω => Real.log (X ω)) μ) :
    ∫ ω, Real.log (X ω) ∂μ ≤ Real.log (∫ ω, X ω ∂μ) := by
  have h := jensen_convex_map_expectation_le (μ := μ) (s := Set.Ioi 0)
    (φ := fun x => -Real.log x) (X := X) strictConcaveOn_log_Ioi.concaveOn.neg hpos hX hlogX.neg
  simp only [integral_neg] at h
  linarith

/-- The square of the average never beats the average of the square, and the gap is exactly
the variance: `(E[X])² ≤ E[X²]` and `E[X²] - (E[X])² = Var(X)`. -/
theorem sq_expectation_le_expectation_sq_and_gap_eq_variance {Ω : Type*} [MeasurableSpace Ω]
    {μ : Measure Ω} [IsProbabilityMeasure μ] {X : Ω → ℝ}
    (hX : Integrable X μ) (hX2 : Integrable (fun ω => X ω ^ 2) μ) :
    (∫ ω, X ω ∂μ) ^ 2 ≤ ∫ ω, X ω ^ 2 ∂μ ∧
      ∫ ω, X ω ^ 2 ∂μ - (∫ ω, X ω ∂μ) ^ 2 = variance X μ := by
  have hL2 : MemLp X 2 μ := (memLp_two_iff_integrable_sq hX.aestronglyMeasurable).2 hX2
  have hv : ∫ ω, X ω ^ 2 ∂μ - (∫ ω, X ω ∂μ) ^ 2 = variance X μ := by
    rw [variance_eq_sub hL2]; rfl
  refine ⟨?_, hv⟩
  have := variance_nonneg X μ
  linarith

-- The fund: growth 3/2 or 3/5, chance 1/2 each. Average growth is 21/20 (1.05).
example : (1/2 : ℚ) * (3/2) + (1/2) * (3/5) = 21/20 := by norm_num
-- Average of the squares is 261/200 (1.305); square of the average is 441/400 (1.1025).
example : (1/2 : ℚ) * (3/2)^2 + (1/2) * (3/5)^2 = 261/200 := by norm_num
example : (21/20 : ℚ)^2 = 441/400 := by norm_num
-- The square gap, 81/400 (0.2025), equals the variance computed by its definition.
example : (261/200 : ℚ) - (21/20)^2 = 81/400 := by norm_num
example : (1/2 : ℚ) * (3/2 - 21/20)^2 + (1/2) * (3/5 - 21/20)^2 = 81/400 := by norm_num
-- A head then a tail multiplies wealth by 9/10; the median ten-year run turns $100 into $59.049.
example : (3/2 : ℚ) * (3/5) = 9/10 := by norm_num
example : (100 : ℚ) * (9/10)^5 = 59049/1000 := by norm_num
-- Of the 2^10 = 1024 ten-year runs, 638 end below the start: k heads end below exactly when
-- (3/2)^k (3/5)^(10-k) < 1, that is 3^10 < 2^k 5^(10-k).
example : 2 ^ 10 = 1024 := by norm_num
example : ((Finset.range 11).filter (fun k => 3 ^ 10 < 2 ^ k * 5 ^ (10 - k))).sum
    (fun k => Nat.choose 10 k) = 638 := by decide
-- The cube on returns -2/5 or 1/10: average cube -63/2000 (-0.0315) lies below the cube of the
-- average return, -27/8000 (-0.003375), so the inequality runs the wrong way.
example : (1/2 : ℚ) * (-2/5)^3 + (1/2) * (1/10)^3 = -63/2000 := by norm_num
example : ((1/2 : ℚ) * (-2/5) + (1/2) * (1/10))^3 = -27/8000 := by norm_num
example : (-63/2000 : ℚ) < -27/8000 := by norm_num

#print axioms jensen_convex_map_expectation_le
#print axioms expectation_log_le_log_expectation
#print axioms sq_expectation_le_expectation_sq_and_gap_eq_variance
