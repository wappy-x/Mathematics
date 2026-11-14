-- The piecewise-flat hazard curve: a hazard held flat between node dates has an area that is a sum of rectangles, survival is the product of one e-to-the-minus factor per piece, a straight line in log survival between two nodes is the same as a flat hazard there, and a rising average hazard lags the rate in force.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.Calculus.Deriv.Mul

open MeasureTheory

/-- A hazard flat at `c` strictly between `a` and `b` is integrable there with area `c × (b - a)`. -/
theorem flat_piece_area (h : ℝ → ℝ) (a b c : ℝ) (hab : a ≤ b)
    (hflat : ∀ x ∈ Set.Ioo a b, h x = c) :
    IntervalIntegrable h volume a b ∧ (∫ y in a..b, h y) = c * (b - a) := by
  have hio : IntegrableOn h (Set.Ioo a b) volume :=
    (integrableOn_const (C := c) (by simp)).congr_fun (fun x hx => (hflat x hx).symm)
      measurableSet_Ioo
  refine ⟨?_, ?_⟩
  · rw [intervalIntegrable_iff_integrableOn_Ioc_of_le hab]
    exact (integrableOn_Ioc_iff_integrableOn_Ioo).2 hio
  · rw [intervalIntegral.integral_of_le hab, integral_Ioc_eq_integral_Ioo,
      setIntegral_congr_fun measurableSet_Ioo (fun x hx => hflat x hx)]
    simp [hab, mul_comm]

#print axioms flat_piece_area


/-- The staircase's area and survival. Take node dates `t 0 = 0 < t 1 < ... < t n` and a hazard
`h` that is flat at `lam k` strictly between `t k` and `t (k+1)` (its values at the nodes
themselves may be anything). For a date `x` in piece `k`, the area under the hazard from 0 to `x`
is the full rectangles of the finished pieces plus the part of the current piece reached so far,
and survival, e to the minus that area, is the product of one factor e^(-rate × width) per
finished piece times e^(-rate × time so far) for the current piece. -/
theorem staircase_area_and_survival (n : ℕ) (t lam : ℕ → ℝ) (h : ℝ → ℝ)
    (ht0 : t 0 = 0) (ht : ∀ k < n, t k < t (k + 1))
    (hflat : ∀ k < n, ∀ x ∈ Set.Ioo (t k) (t (k + 1)), h x = lam k)
    (k : ℕ) (hk : k < n) (x : ℝ) (hx : x ∈ Set.Icc (t k) (t (k + 1))) :
    (∫ y in (0 : ℝ)..x, h y)
        = (∑ j ∈ Finset.range k, lam j * (t (j + 1) - t j)) + lam k * (x - t k) ∧
    Real.exp (-∫ y in (0 : ℝ)..x, h y)
        = (∏ j ∈ Finset.range k, Real.exp (-(lam j * (t (j + 1) - t j))))
            * Real.exp (-(lam k * (x - t k))) := by
  have hpiece : ∀ j < n, IntervalIntegrable h volume (t j) (t (j + 1)) ∧
      (∫ y in t j..t (j + 1), h y) = lam j * (t (j + 1) - t j) :=
    fun j hj => flat_piece_area h _ _ _ (ht j hj).le (hflat j hj)
  have hsum : (∫ y in (0 : ℝ)..t k, h y)
      = ∑ j ∈ Finset.range k, lam j * (t (j + 1) - t j) := by
    rw [← ht0, ← intervalIntegral.sum_integral_adjacent_intervals
      (fun j hj => (hpiece j (by omega)).1)]
    exact Finset.sum_congr rfl (fun j hj => (hpiece j (by simp at hj; omega)).2)
  have hint0 : IntervalIntegrable h volume 0 (t k) := by
    rw [← ht0]; exact IntervalIntegrable.trans_iterate (fun j hj => (hpiece j (by omega)).1)
  have hlast := flat_piece_area h (t k) x (lam k) hx.1
    (fun y hy => hflat k hk y ⟨hy.1, lt_of_lt_of_le hy.2 hx.2⟩)
  have harea : (∫ y in (0 : ℝ)..x, h y)
      = (∑ j ∈ Finset.range k, lam j * (t (j + 1) - t j)) + lam k * (x - t k) := by
    rw [← intervalIntegral.integral_add_adjacent_intervals hint0 hlast.1, hsum, hlast.2]
  refine ⟨harea, ?_⟩
  rw [harea, neg_add, Real.exp_add, ← Finset.sum_neg_distrib, Real.exp_sum]

/-- Log-linear survival is the same choice as a flat hazard. On a stretch from `a` to `b`
(with `0 ≤ a < b`), let survival be `S x = e^(-∫₀ˣ h)` for a hazard `h` that is integrable up to
`b` and continuous inside the stretch. Then `ln S` runs along the straight line between
`ln S a` and `ln S b`, with `w = (x - a)/(b - a)` the fraction of the way across, exactly when
the hazard is one constant on the stretch. -/
theorem log_linear_survival_iff_flat_hazard (h : ℝ → ℝ) (a b : ℝ) (ha : 0 ≤ a) (hab : a < b)
    (hint : IntervalIntegrable h volume 0 b) (hcont : ContinuousOn h (Set.Ioo a b)) :
    (∀ x ∈ Set.Icc a b,
        Real.log (Real.exp (-∫ y in (0 : ℝ)..x, h y))
          = (1 - (x - a) / (b - a)) * Real.log (Real.exp (-∫ y in (0 : ℝ)..a, h y))
            + (x - a) / (b - a) * Real.log (Real.exp (-∫ y in (0 : ℝ)..b, h y)))
      ↔ ∃ c : ℝ, ∀ x ∈ Set.Ioo a b, h x = c := by
  simp only [Real.log_exp]
  have hI : ∀ x ∈ Set.Icc (0 : ℝ) b, IntervalIntegrable h volume 0 x := fun x hx =>
    hint.mono_set (by
      rw [Set.uIcc_of_le hx.1, Set.uIcc_of_le (ha.trans hab.le)]
      exact Set.Icc_subset_Icc le_rfl hx.2)
  have hba : b - a ≠ 0 := by linarith
  constructor
  · intro H
    refine ⟨((∫ y in (0 : ℝ)..b, h y) - ∫ y in (0 : ℝ)..a, h y) / (b - a), fun x hx => ?_⟩
    have hd1 : HasDerivAt (fun u => ∫ y in (0 : ℝ)..u, h y) (h x) x :=
      intervalIntegral.integral_hasDerivAt_right (hI x ⟨ha.trans hx.1.le, hx.2.le⟩)
        (hcont.stronglyMeasurableAtFilter isOpen_Ioo x hx)
        (hcont.continuousAt (isOpen_Ioo.mem_nhds hx))
    have hG : HasDerivAt (fun u => (∫ y in (0 : ℝ)..a, h y) + (u - a) / (b - a)
        * ((∫ y in (0 : ℝ)..b, h y) - ∫ y in (0 : ℝ)..a, h y))
        (((∫ y in (0 : ℝ)..b, h y) - ∫ y in (0 : ℝ)..a, h y) / (b - a)) x := by
      have h1 : HasDerivAt (fun u : ℝ => u - a) 1 x := (hasDerivAt_id x).sub_const a
      have h2 : HasDerivAt (fun u : ℝ => (u - a) / (b - a)) (1 / (b - a)) x :=
        HasDerivAt.div_const h1 (b - a)
      have := (HasDerivAt.mul_const h2
        ((∫ y in (0 : ℝ)..b, h y) - ∫ y in (0 : ℝ)..a, h y)).const_add (∫ y in (0 : ℝ)..a, h y)
      convert this using 1
      field_simp
    have heq : (fun u => ∫ y in (0 : ℝ)..u, h y) =ᶠ[nhds x]
        (fun u => (∫ y in (0 : ℝ)..a, h y) + (u - a) / (b - a)
          * ((∫ y in (0 : ℝ)..b, h y) - ∫ y in (0 : ℝ)..a, h y)) := by
      filter_upwards [isOpen_Ioo.mem_nhds hx] with y hy
      have := H y ⟨hy.1.le, hy.2.le⟩
      linear_combination -this
    exact hd1.unique (hG.congr_of_eventuallyEq heq)
  · rintro ⟨c, hc⟩ x hx
    have hIa : IntervalIntegrable h volume 0 a := hI a ⟨ha, hab.le⟩
    have hx' := flat_piece_area h a x c hx.1 (fun y hy => hc y ⟨hy.1, lt_of_lt_of_le hy.2 hx.2⟩)
    have hb' := flat_piece_area h a b c hab.le hc
    rw [← intervalIntegral.integral_add_adjacent_intervals hIa hx'.1,
      ← intervalIntegral.integral_add_adjacent_intervals hIa hb'.1, hx'.2, hb'.2]
    field_simp
    ring

/-- The average hazard from today lags the rate in force. With the staircase as above, write
`(∫₀ᵀ h) / T` for the average hazard to the horizon `T`. On piece `k`: the rate in force is
recovered from the two averages at its ends; the rate in force minus the new average equals the
start date times the average's climb per year; and on any piece after the first, if the average
rose across the piece then the rate in force is above both averages. -/
theorem average_hazard_lags_rate_in_force (n : ℕ) (t lam : ℕ → ℝ) (h : ℝ → ℝ)
    (ht0 : t 0 = 0) (ht : ∀ k < n, t k < t (k + 1))
    (hflat : ∀ k < n, ∀ x ∈ Set.Ioo (t k) (t (k + 1)), h x = lam k)
    (k : ℕ) (hk : k < n) :
    lam k = ((∫ y in (0 : ℝ)..t (k + 1), h y) / t (k + 1) * t (k + 1)
              - (∫ y in (0 : ℝ)..t k, h y) / t k * t k) / (t (k + 1) - t k) ∧
    lam k - (∫ y in (0 : ℝ)..t (k + 1), h y) / t (k + 1)
      = t k * ((∫ y in (0 : ℝ)..t (k + 1), h y) / t (k + 1)
                - (∫ y in (0 : ℝ)..t k, h y) / t k) / (t (k + 1) - t k) ∧
    (0 < k → (∫ y in (0 : ℝ)..t k, h y) / t k < (∫ y in (0 : ℝ)..t (k + 1), h y) / t (k + 1) →
      (∫ y in (0 : ℝ)..t k, h y) / t k < lam k ∧
      (∫ y in (0 : ℝ)..t (k + 1), h y) / t (k + 1) < lam k) := by
  have hpos : ∀ j, j ≤ n → 0 < j → 0 < t j := by
    intro j
    induction j with
    | zero => intro _ h0; omega
    | succ m ih =>
      intro hm _
      rcases Nat.eq_zero_or_pos m with rfl | hm0
      · simpa [ht0] using ht 0 (by omega)
      · exact (ih (by omega) hm0).trans (ht m (by omega))
  have hpiece : ∀ j < n, IntervalIntegrable h volume (t j) (t (j + 1)) ∧
      (∫ y in t j..t (j + 1), h y) = lam j * (t (j + 1) - t j) :=
    fun j hj => flat_piece_area h _ _ _ (ht j hj).le (hflat j hj)
  have hint0 : IntervalIntegrable h volume 0 (t k) := by
    rw [← ht0]; exact IntervalIntegrable.trans_iterate (fun j hj => (hpiece j (by omega)).1)
  have hstep : (∫ y in (0 : ℝ)..t (k + 1), h y)
      = (∫ y in (0 : ℝ)..t k, h y) + lam k * (t (k + 1) - t k) := by
    rw [← intervalIntegral.integral_add_adjacent_intervals hint0 (hpiece k hk).1, (hpiece k hk).2]
  have hT1 : 0 < t (k + 1) := hpos (k + 1) (by omega) (by omega)
  have hlt : t k < t (k + 1) := ht k hk
  rw [hstep]
  rcases Nat.eq_zero_or_pos k with rfl | hk0
  · simp only [ht0, intervalIntegral.integral_same, zero_add, div_zero, zero_mul, sub_zero,
      zero_div] at hT1 hlt ⊢
    refine ⟨?_, ?_, fun h0 => absurd h0 (lt_irrefl 0)⟩
    · field_simp
    · field_simp
      ring
  · have hT0 : 0 < t k := hpos k hk.le hk0
    have hd : 0 < t (k + 1) - t k := by linarith
    have key : lam k - ((∫ y in (0 : ℝ)..t k, h y) + lam k * (t (k + 1) - t k)) / t (k + 1)
        = t k * (((∫ y in (0 : ℝ)..t k, h y) + lam k * (t (k + 1) - t k)) / t (k + 1)
          - (∫ y in (0 : ℝ)..t k, h y) / t k) / (t (k + 1) - t k) := by
      field_simp
      ring
    refine ⟨?_, key, fun _ hrise => ?_⟩
    · rw [div_mul_cancel₀ _ hT1.ne', div_mul_cancel₀ _ hT0.ne']
      field_simp
      ring
    · have hgap : 0 < lam k - ((∫ y in (0 : ℝ)..t k, h y) + lam k * (t (k + 1) - t k))
          / t (k + 1) := by
        rw [key]
        exact div_pos (mul_pos hT0 (by linarith)) hd
      constructor <;> linarith

/-! The card's van, in percentage points: rates 2, 4, 6 on the pieces from 0 to 1, 1 to 3 and
3 to 5 years. -/

-- Areas (cumulative hazard, in percent-years) at 1, 3 and 5 years: 2, 10, 22.
example : ∑ j ∈ Finset.range 1, [(2 : ℚ), 4, 6].getD j 0 * ([(0 : ℚ), 1, 3, 5].getD (j + 1) 0
    - [(0 : ℚ), 1, 3, 5].getD j 0) = 2 := by
  norm_num [Finset.sum_range_succ]
example : ∑ j ∈ Finset.range 2, [(2 : ℚ), 4, 6].getD j 0 * ([(0 : ℚ), 1, 3, 5].getD (j + 1) 0
    - [(0 : ℚ), 1, 3, 5].getD j 0) = 10 := by
  norm_num [Finset.sum_range_succ]
example : ∑ j ∈ Finset.range 3, [(2 : ℚ), 4, 6].getD j 0 * ([(0 : ℚ), 1, 3, 5].getD (j + 1) 0
    - [(0 : ℚ), 1, 3, 5].getD j 0) = 22 := by
  norm_num [Finset.sum_range_succ]
-- Inside a piece: the area at 2.5 years is 2 + 4 × 1.5 = 8.
example : (2 : ℚ) * 1 + 4 * (5 / 2 - 1) = 8 := by norm_num
-- At 2 years, w = 1/2 and log-linear gives the midpoint of -2 and -10, which is -6 = -(2 + 4 × 1).
example : ((2 : ℚ) - 1) / (3 - 1) = 1 / 2 ∧
    (1 - (1 : ℚ) / 2) * (-2) + 1 / 2 * (-10) = -6 ∧ (2 : ℚ) + 4 * 1 = 6 := by norm_num
-- At 4 years, the midpoint of -10 and -22 is -16 = -(10 + 6 × 1).
example : (1 - (1 : ℚ) / 2) * (-10) + 1 / 2 * (-22) = -16 ∧ (10 : ℚ) + 6 * 1 = 16 := by norm_num
-- Average hazards to 1, 3 and 5 years: 2, 10/3 and 22/5 = 4.4.
example : (2 : ℚ) / 1 = 2 ∧ (10 : ℚ) / 3 = 10 / 3 ∧ (22 : ℚ) / 5 = 44 / 10 := by norm_num
-- Rates in force recovered from the averages: (10/3 × 3 - 2 × 1)/2 = 4 and (22/5 × 5 - 10/3 × 3)/2 = 6.
example : ((10 : ℚ) / 3 * 3 - 2 * 1) / (3 - 1) = 4 ∧
    ((22 : ℚ) / 5 * 5 - 10 / 3 * 3) / (5 - 3) = 6 := by norm_num
-- The gaps: 4 - 10/3 = 2/3 point and 6 - 22/5 = 8/5 = 1.6 points, each the start date times the
-- average's climb per year.
example : (4 : ℚ) - 10 / 3 = 1 * (10 / 3 - 2) / (3 - 1) ∧ (4 : ℚ) - 10 / 3 = 2 / 3 := by norm_num
example : (6 : ℚ) - 22 / 5 = 3 * (22 / 5 - 10 / 3) / (5 - 3) ∧ (6 : ℚ) - 22 / 5 = 16 / 10 := by
  norm_num
-- Reversing the rates changes the five-year area: 6 × 1 + 4 × 2 + 2 × 2 = 18, not 22.
example : (6 : ℚ) * 1 + 4 * 2 + 2 * 2 = 18 := by norm_num
-- A flat 4.4% over five years has the same area, 22, as the staircase.
example : (22 : ℚ) / 5 * 5 = 22 := by norm_num
-- With 6% held on past year 5, the area at seven years is 22 + 6 × 2 = 34.
example : (22 : ℚ) + 6 * (7 - 5) = 34 := by norm_num

#print axioms staircase_area_and_survival
#print axioms log_linear_survival_iff_flat_hazard
#print axioms average_hazard_lags_rate_in_force
