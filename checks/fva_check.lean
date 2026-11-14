-- FVA: when a bought option's discounted exposure is flat the funding cost integral equals spread times price times Northwind's expected survival time, the collateral account telescopes to discounted payoff minus price, and a cash stream's linear funding cost is the spread times each payment times its date times its discount factor.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

open Real intervalIntegral

/-- Helper: a step function (constant `c` before date `k`, zero after) is interval integrable. -/
theorem step_integrable (c k a b : ℝ) :
    IntervalIntegrable (fun t : ℝ => if t < k then c else 0) MeasureTheory.volume a b := by
  have : (fun t : ℝ => if t < k then c else 0) = Set.indicator (Set.Iio k) (fun _ => c) := by
    ext t; simp [Set.indicator_apply]
  rw [this, intervalIntegrable_iff]
  exact (intervalIntegrable_iff.mp intervalIntegrable_const).indicator measurableSet_Iio

/-- Helper: the integral over `[0, Y]` of a step paying `c` before date `k ∈ [0, Y]` is `k * c`. -/
theorem step_integral (c k Y : ℝ) (h0 : 0 ≤ k) (hkY : k ≤ Y) :
    ∫ t in (0:ℝ)..Y, (if t < k then c else 0) = k * c := by
  rw [← integral_add_adjacent_intervals (step_integrable c k 0 k) (step_integrable c k k Y)]
  have e1 : ∫ t in (0:ℝ)..k, (if t < k then c else 0) = ∫ t in (0:ℝ)..k, c := by
    apply intervalIntegral.integral_congr_ae
    filter_upwards [MeasureTheory.Measure.ae_ne MeasureTheory.volume k] with t ht hmem
    rw [Set.uIoc_of_le h0] at hmem
    simp [lt_of_le_of_ne hmem.2 ht]
  have e2 : ∫ t in k..Y, (if t < k then c else 0) = ∫ t in k..Y, (0:ℝ) := by
    apply integral_congr
    intro t ht
    rw [Set.uIcc_of_le hkY] at ht
    simp [not_lt.mpr ht.1]
  rw [e1, e2]
  simp

/-- Step 4 of the card: the funding cost adjustment of a bought option.
FCA is the funding spread `s_F` times the integral over the trade's life `[0, T]` of the
discount factor `e^{-r t}`, times the expected positive exposure `EPE t`, times the
counterparty's survival chance `e^{-λ_C t}`. If the discounted exposure `e^{-r t} EPE(t)` equals
today's clean price `C₀` at every date (as it does for a bought option), and the hazard is
positive, the integral closes: `FCA = s_F · C₀ · (1 - e^{-λ_C T}) / λ_C`. -/
theorem fca_flat_discounted_exposure (sF r lamC C0 T : ℝ) (EPE : ℝ → ℝ)
    (hT : 0 ≤ T) (hlam : 0 < lamC)
    (hflat : ∀ t ∈ Set.Icc (0 : ℝ) T, exp (-r * t) * EPE t = C0) :
    sF * ∫ t in (0 : ℝ)..T, exp (-r * t) * EPE t * exp (-lamC * t)
      = sF * C0 * ((1 - exp (-lamC * T)) / lamC) := by
  have h1 : ∫ t in (0:ℝ)..T, exp (-r * t) * EPE t * exp (-lamC * t)
      = ∫ t in (0:ℝ)..T, C0 * exp (-lamC * t) := by
    apply integral_congr
    intro t ht
    rw [Set.uIcc_of_le hT] at ht
    simp only
    rw [hflat t ht]
  have h2 : ∫ t in (0:ℝ)..T, exp (-lamC * t) = (1 - exp (-lamC * T)) / lamC := by
    rw [integral_eq_sub_of_hasDerivAt (f := fun t => -exp (-lamC * t) / lamC)]
    · field_simp
      simp
      ring
    · intro x _
      have := (((hasDerivAt_id x).const_mul (-lamC)).exp.neg).div_const lamC
      convert this using 1
      · ext t; simp [neg_div]
      · simp only [id]; field_simp
    · exact (continuous_exp.comp (continuous_const.mul continuous_id)).intervalIntegrable _ _
  rw [h1, intervalIntegral.integral_const_mul, h2]
  ring

/-- Step 1 of the card (the detailed proof): the collateral account telescopes.
Cut the life at dates `t 0, t 1, …, t n`, with trade values `V 0, …, V n`. At date `t (k+1)` the
bank receives `V (k+1) - V k · e^{r (t (k+1) - t k)}` (new collateral minus old collateral
returned with interest at the collateral rate `r`). Discounted to today at `r` and added up,
these net cash flows equal `e^{-r t n} V n - e^{-r t 0} V 0`: the discounted final value
minus the starting value. The bank's own borrowing rate never appears. -/
theorem collateral_account_telescopes (r : ℝ) (t V : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ Finset.range n,
        exp (-r * t (k + 1)) * (V (k + 1) - V k * exp (r * (t (k + 1) - t k)))
      = exp (-r * t n) * V n - exp (-r * t 0) * V 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, ih]
    have key : exp (-r * t (n + 1)) * exp (r * (t (n + 1) - t n)) = exp (-r * t n) := by
      rw [← exp_add]; ring_nf
    linear_combination (-V n) * key

/-- The card's second example: a bought stream paying `C` at each year `k = 1, …, Y`, discounted
at the collateral rate `ρ`. The funding need at date `t` is the value of the payments still to
come; its discounted value is the sum of the payments after `t`, each discounted to today.
The linear FVA, the spread `s_F` times that need integrated over `[0, Y]`, equals the spread
times each payment times its date times its discount factor. -/
theorem stream_linear_fva (sF C ρ : ℝ) (Y : ℕ) :
    sF * ∫ t in (0 : ℝ)..(Y : ℝ),
        ∑ k ∈ Finset.Icc 1 Y, (if t < (k : ℝ) then C * exp (-ρ * k) else 0)
      = sF * ∑ k ∈ Finset.Icc 1 Y, (k : ℝ) * C * exp (-ρ * k) := by
  congr 1
  rw [integral_finsetSum (fun k _ => step_integrable _ _ _ _)]
  apply Finset.sum_congr rfl
  intro k hk
  rw [Finset.mem_Icc] at hk
  rw [step_integral _ _ _ (by positivity) (by exact_mod_cast hk.2)]
  ring

#print axioms step_integrable
#print axioms step_integral
#print axioms fca_flat_discounted_exposure
#print axioms collateral_account_telescopes
#print axioms stream_linear_fva
