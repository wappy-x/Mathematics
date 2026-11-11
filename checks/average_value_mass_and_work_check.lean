-- Averages, mass and work: a continuous function on an interval of positive length takes its average value somewhere, and the card's day, tank and spring totals come out exactly.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.IntervalAverage

open Set intervalIntegral MeasureTheory Real

/-- **Mean value theorem for integrals.** Let a < b and let f be continuous on the closed
interval from a to b. Then at some point c of that interval, f takes its average value:
f(c) = (1/(b − a)) ∫_a^b f(t) dt, so ∫_a^b f(t) dt = f(c)(b − a). -/
theorem continuous_function_takes_its_average_value (f : ℝ → ℝ) (a b : ℝ) (hab : a < b)
    (hf : ContinuousOn f (Icc a b)) :
    ∃ c ∈ Icc a b, f c = (∫ t in a..b, f t) / (b - a) := by
  have hf' : ContinuousOn f (uIcc a b) := by rwa [uIcc_of_le hab.le]
  obtain ⟨c, hc, hfc⟩ := exists_eq_interval_average hab.ne hf'
  refine ⟨c, ?_, by rw [hfc, interval_average_eq_div]⟩
  rw [uIoo_of_le hab.le] at hc
  exact Ioo_subset_Icc_self hc

/-- **The average lies between the least and greatest values.** Let a < b and let f be continuous
on the closed interval from a to b. If lo ≤ f(t) ≤ hi at every t of the interval, then the total
lies between lo(b − a) and hi(b − a), and the average lies between lo and hi. -/
theorem average_between_least_and_greatest (f : ℝ → ℝ) (a b lo hi : ℝ) (hab : a < b)
    (hf : ContinuousOn f (Icc a b))
    (hlo : ∀ t ∈ Icc a b, lo ≤ f t) (hhi : ∀ t ∈ Icc a b, f t ≤ hi) :
    lo * (b - a) ≤ ∫ t in a..b, f t ∧ ∫ t in a..b, f t ≤ hi * (b - a) ∧
    lo ≤ (∫ t in a..b, f t) / (b - a) ∧ (∫ t in a..b, f t) / (b - a) ≤ hi := by
  have hint : IntervalIntegrable f volume a b :=
    (hf.mono (by rw [uIcc_of_le hab.le])).intervalIntegrable
  have h1 : lo * (b - a) ≤ ∫ t in a..b, f t := by
    have := intervalIntegral.integral_mono_on hab.le intervalIntegrable_const hint hlo
    simpa [mul_comm] using this
  have h2 : ∫ t in a..b, f t ≤ hi * (b - a) := by
    have := intervalIntegral.integral_mono_on hab.le hint intervalIntegrable_const hhi
    simpa [mul_comm] using this
  have hpos : 0 < b - a := sub_pos.mpr hab
  refine ⟨h1, h2, ?_, ?_⟩
  · rw [le_div_iff₀ hpos]; exact h1
  · rw [div_le_iff₀ hpos]; exact h2

/-- **Continuity cannot be dropped.** The heater that holds the room at 10 °C before noon and
20 °C from noon on averages 15 °C over the 24-hour day, yet the room is never at 15 °C. -/
theorem step_heater_never_reaches_its_average :
    (∫ t in (0 : ℝ)..24, (if t < 12 then (10 : ℝ) else 20)) / 24 = 15 ∧
    ∀ t : ℝ, (if t < 12 then (10 : ℝ) else 20) ≠ 15 := by
  refine ⟨?_, fun t => by split_ifs <;> norm_num⟩
  have hi : ∀ a b : ℝ, IntervalIntegrable (fun t : ℝ => if t < 12 then (10 : ℝ) else 20) volume a b := by
    intro a b
    have hm : Monotone (fun t : ℝ => if t < 12 then (10 : ℝ) else 20) := by
      intro x y hxy
      dsimp only
      split_ifs with h1 h2 h2 <;> first | (exfalso; linarith) | norm_num
    exact hm.intervalIntegrable
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := 12) (hi 0 12) (hi 12 24)]
  have e1 : ∫ t in (0:ℝ)..12, (if t < 12 then (10 : ℝ) else 20) = ∫ t in (0:ℝ)..12, (10:ℝ) := by
    apply intervalIntegral.integral_congr_ae
    have : ∀ᵐ x ∂(volume : Measure ℝ), x ≠ 12 := by
      rw [ae_iff]; simp
    filter_upwards [this] with x hx hmem
    rw [uIoc_of_le (by norm_num)] at hmem
    have : x < 12 := lt_of_le_of_ne hmem.2 hx
    simp [this]
  have e2 : ∫ t in (12:ℝ)..24, (if t < 12 then (10 : ℝ) else 20) = ∫ t in (12:ℝ)..24, (20:ℝ) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [uIcc_of_le (by norm_num)] at hx
    simp [not_lt.mpr hx.1]
  rw [e1, e2]; simp; norm_num

-- The day: T(t) = 10 + t(24 − t)/10. Its total over 24 hours is 470.4 = 2352/5 degree-hours.
example : ∫ t in (0 : ℝ)..24, (10 + t * (24 - t) / 10) = 2352 / 5 := by
  have : (fun t : ℝ => 10 + t * (24 - t) / 10) = fun t => 10 + ((12/5) * t - t^2/10) := by
    ext t; ring
  rw [this]
  have c1 : Continuous fun t : ℝ => (12/5) * t - t^2/10 := by fun_prop
  have c2 : Continuous fun t : ℝ => (12/5) * t := by fun_prop
  have c3 : Continuous fun t : ℝ => t^2/10 := by fun_prop
  rw [intervalIntegral.integral_add intervalIntegrable_const (c1.intervalIntegrable _ _)]
  rw [intervalIntegral.integral_sub (c2.intervalIntegrable _ _) (c3.intervalIntegrable _ _)]
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_div]
  simp [integral_pow, integral_id]
  norm_num

-- The day's mean: 470.4 / 24 = 19.6 = 98/5 °C.
example : (∫ t in (0 : ℝ)..24, (10 + t * (24 - t) / 10)) / 24 = 98 / 5 := by
  have h : ∫ t in (0 : ℝ)..24, (10 + t * (24 - t) / 10) = 2352 / 5 := by
    have : (fun t : ℝ => 10 + t * (24 - t) / 10) = fun t => 10 + ((12/5) * t - t^2/10) := by
      ext t; ring
    rw [this]
    have c1 : Continuous fun t : ℝ => (12/5) * t - t^2/10 := by fun_prop
    have c2 : Continuous fun t : ℝ => (12/5) * t := by fun_prop
    have c3 : Continuous fun t : ℝ => t^2/10 := by fun_prop
    rw [intervalIntegral.integral_add intervalIntegrable_const (c1.intervalIntegrable _ _)]
    rw [intervalIntegral.integral_sub (c2.intervalIntegrable _ _) (c3.intervalIntegrable _ _)]
    rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_div]
    simp [integral_pow, integral_id]
    norm_num
  rw [h]; norm_num

-- By hand: the antiderivative read at the ends, 240 + (6912 − 4608)/10 = 470.4, and 470.4 / 24 = 19.6.
example : (10 * 24 + (12 * 24 ^ 2 - 24 ^ 3 / 3) / 10 : ℚ) = 240 + (6912 - 4608) / 10 := by norm_num
example : (240 + (6912 - 4608) / 10 : ℚ) = 2352 / 5 := by norm_num
example : (2352 / 5 / 24 : ℚ) = 98 / 5 := by norm_num

-- The midpoint of the extremes: (T(12) + T(0))/2 = (24.4 + 10)/2 = 17.2, not 19.6.
example : ((10 + 12 * (24 - 12) / 10) + (10 + 0 * (24 - 0) / 10)) / 2 = (86 / 5 : ℚ) := by norm_num

-- The 24 readings on the hour average 235/12 = 19.5833… °C.
example : (∑ k ∈ Finset.range 24, (10 + (k : ℚ) * (24 - k) / 10)) / 24 = 235 / 12 := by
  norm_num [Finset.sum_range_succ]

-- 24 midpoint strips, each read at its middle, average 2353/120 = 19.608333… °C.
example : (∑ k ∈ Finset.range 24,
    (10 + ((k : ℚ) + 1 / 2) * (24 - ((k : ℚ) + 1 / 2)) / 10)) / 24 = 2353 / 120 := by
  norm_num [Finset.sum_range_succ]

-- The temperature equals its mean at t = 12 − 4√3 ≈ 5.0718 h and at t = 12 + 4√3 ≈ 18.9282 h.
example : 10 + (12 - 4 * √3) * (24 - (12 - 4 * √3)) / 10 = (98 / 5 : ℝ) ∧
    10 + (12 + 4 * √3) * (24 - (12 + 4 * √3)) / 10 = (98 / 5 : ℝ) := by
  have h : √3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  constructor <;> nlinarith [h]

-- The tank's mass: ∫₀⁴ 1000π(y/2)² dy = 250π · 4³/3 = 16000π/3 kg (about 16,755.2 kg).
example : ∫ y in (0 : ℝ)..4, 1000 * π * (y / 2) ^ 2 = 16000 * π / 3 := by
  have : (fun y : ℝ => 1000 * π * (y / 2) ^ 2) = fun y => (250 * π) * y ^ 2 := by ext y; ring
  rw [this, intervalIntegral.integral_const_mul, integral_pow]; ring

-- The same mass with no calculus: one third of the cylinder, π · 2² · 4 / 3 cubic metres at 1000 kg each.
example : 1000 * (π * 2 ^ 2 * 4 / 3) = 16000 * π / 3 := by ring

-- The pump's work, for any pull of gravity g: ∫₀⁴ g · 1000π(y/2)² · (4 − y) dy equals the
-- whole mass times g times a 1 m lift (with g = 9.81, about 164,368.1 J).
example (g : ℝ) : ∫ y in (0 : ℝ)..4, g * (1000 * π * (y / 2) ^ 2) * (4 - y) = (16000 * π / 3) * g * 1 := by
  have : (fun y : ℝ => g * (1000 * π * (y / 2) ^ 2) * (4 - y)) = fun y => (1000 * g * π) * y ^ 2 - (250 * g * π) * y ^ 3 := by ext y; ring
  have c1 : Continuous fun y : ℝ => (1000 * g * π) * y ^ 2 := by fun_prop
  have c2 : Continuous fun y : ℝ => (250 * g * π) * y ^ 3 := by fun_prop
  rw [this, intervalIntegral.integral_sub (c1.intervalIntegrable _ _) (c2.intervalIntegrable _ _)]
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul, integral_pow, integral_pow]; ring

-- The mistake of lifting from the tip, y instead of 4 − y, gives three times the true work.
example (g : ℝ) : ∫ y in (0 : ℝ)..4, g * (1000 * π * (y / 2) ^ 2) * y = 3 * ((16000 * π / 3) * g * 1) := by
  have : (fun y : ℝ => g * (1000 * π * (y / 2) ^ 2) * y) = fun y => (250 * g * π) * y ^ 3 := by ext y; ring
  rw [this, intervalIntegral.integral_const_mul, integral_pow]; ring

-- The mistake of a cylinder of radius 2 m gives three times the true mass.
example : 1000 * π * 2 ^ 2 * 4 = 3 * (16000 * π / 3) := by ring

-- The spring: F(x) = 200x newtons over the first 0.3 m does 9 J; the spring's own pull, −200x, does −9 J.
example : ∫ x in (0 : ℝ)..(3 / 10), 200 * x = 9 := by
  rw [intervalIntegral.integral_const_mul, integral_id]; norm_num
example : ∫ x in (0 : ℝ)..(3 / 10), -200 * x = -9 := by
  rw [intervalIntegral.integral_const_mul, integral_id]; norm_num

#print axioms continuous_function_takes_its_average_value
#print axioms average_between_least_and_greatest
#print axioms step_heater_never_reaches_its_average
