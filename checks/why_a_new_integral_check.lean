-- Why a new integral: the reading that is 1 at rational minutes and 0 elsewhere has Lebesgue integral 0 over the hour, its finite switch-ons climb to it with integrals that follow, and a finite sum equals its value-sorted sum.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Order.Filter.AtTopBot.Basic

open MeasureTheory Filter Topology

theorem countable_indicator_setIntegral_eq_zero {s : Set ℝ} (hs : s.Countable) :
    ∫ t in Set.Icc (0 : ℝ) 60, s.indicator (fun _ => (1 : ℝ)) t = 0 := by
  rw [integral_indicator_const _ hs.measurableSet]
  simp only [Measure.real, Measure.restrict_apply hs.measurableSet,
    measure_mono_null Set.inter_subset_left (hs.measure_zero volume)]
  simp

#print axioms countable_indicator_setIntegral_eq_zero

/-- Sorted by value, the rational-minute reading (1 when the minute count is a
fraction of whole numbers, 0 otherwise) adds up over the hour from minute 0 to
minute 60, with length as the size of a set of times, to 0. -/
theorem rational_minute_reading_integral_eq_zero :
    ∫ t in Set.Icc (0 : ℝ) 60,
      (Set.range ((↑) : ℚ → ℝ)).indicator (fun _ => (1 : ℝ)) t = 0 := by
  exact countable_indicator_setIntegral_eq_zero (Set.countable_range _)

/-- Adding finitely many values in any order gives the same as adding, over each
value, the value times how many times it occurs (the till, heap by heap). -/
theorem sum_eq_sum_value_times_count {ι M : Type*} [Fintype ι] [CommSemiring M]
    [DecidableEq M] (c : ι → M) :
    ∑ i, c i = ∑ v ∈ Finset.univ.image c,
      v * ((Finset.univ.filter (fun i => c i = v)).card : M) := by
  have h := Finset.sum_comp (s := Finset.univ) (f := fun x : M => x) (g := c)
  rw [h]
  refine Finset.sum_congr rfl fun v _ => ?_
  simp [nsmul_eq_mul, mul_comm]

/-- Limits stop breaking: if a queue `q` lists every rational time in the hour,
and `r_N` reads 1 only at the first `N` times of the queue, then at every time of
the hour the readings `r_N` climb to the rational-minute reading, and their
integrals over the hour tend to its integral. -/
theorem rational_minute_switch_on_integrals_tendsto (q : ℕ → ℚ)
    (hq : ∀ x : ℚ, 0 ≤ x → x ≤ 60 → ∃ j, q j = x) :
    (∀ t ∈ Set.Icc (0 : ℝ) 60,
      Tendsto (fun N : ℕ =>
        ((fun j => (q j : ℝ)) '' Set.Iio N).indicator (fun _ => (1 : ℝ)) t)
        atTop (𝓝 ((Set.range ((↑) : ℚ → ℝ)).indicator (fun _ => (1 : ℝ)) t))) ∧
    Tendsto (fun N : ℕ => ∫ t in Set.Icc (0 : ℝ) 60,
        ((fun j => (q j : ℝ)) '' Set.Iio N).indicator (fun _ => (1 : ℝ)) t)
      atTop (𝓝 (∫ t in Set.Icc (0 : ℝ) 60,
        (Set.range ((↑) : ℚ → ℝ)).indicator (fun _ => (1 : ℝ)) t)) := by
  refine ⟨fun t ht => ?_, ?_⟩
  · by_cases hr : t ∈ Set.range ((↑) : ℚ → ℝ)
    · obtain ⟨x, rfl⟩ := hr
      have h0 : (0 : ℚ) ≤ x := by exact_mod_cast ht.1
      have h1 : x ≤ 60 := by exact_mod_cast ht.2
      obtain ⟨j, hj⟩ := hq x h0 h1
      rw [Set.indicator_of_mem (Set.mem_range_self x)]
      refine tendsto_const_nhds.congr' ?_
      filter_upwards [eventually_gt_atTop j] with N hN
      rw [Set.indicator_of_mem]
      exact ⟨j, hN, by simp [hj]⟩
    · rw [Set.indicator_of_notMem hr]
      refine tendsto_const_nhds.congr fun N => ?_
      rw [Set.indicator_of_notMem]
      rintro ⟨j, -, rfl⟩
      exact hr ⟨q j, rfl⟩
  · rw [countable_indicator_setIntegral_eq_zero (Set.countable_range _)]
    refine tendsto_const_nhds.congr fun N => ?_
    rw [countable_indicator_setIntegral_eq_zero ((Set.finite_Iio N).image _).countable]

-- The till, in cents: 37 coins, $23.45 by denomination.
example : 20 + 5 + 2 + 3 + 2 + 5 = 37 := by norm_num
example : 20 * 100 + 5 * 50 + 2 * 25 + 3 * 10 + 2 * 5 + 5 * 1 = 2345 := by norm_num
example : 20 * 100 = 2000 ∧ 5 * 50 = 250 := by norm_num
-- Small change, 25c and below: 12 coins, $0.95.
example : 2 + 3 + 2 + 5 = 12 ∧ 2 * 25 + 3 * 10 + 2 * 5 + 5 * 1 = 95 := by norm_num
-- Mistake, one coin per denomination: $1.91.
example : 100 + 50 + 25 + 10 + 5 + 1 = 191 := by norm_num
-- The till heap by heap equals the till coin by coin, on the actual coin list.
example : ([100, 50, 25, 10, 5, 1].map (fun v =>
      v * ((List.replicate 20 100 ++ List.replicate 5 50 ++ List.replicate 2 25 ++
        List.replicate 3 10 ++ List.replicate 2 5 ++ List.replicate 5 1).count v))).sum =
    (List.replicate 20 100 ++ List.replicate 5 50 ++ List.replicate 2 25 ++
      List.replicate 3 10 ++ List.replicate 2 5 ++ List.replicate 5 1).sum := by decide
-- Bounds 2 x 100 x 60 / n on the upper sums, n = 600, 6000, 60000, 600000.
example : (2 * 100 * 60 : ℚ) / 600 = 20 ∧ (2 * 100 * 60 : ℚ) / 6000 = 2 ∧
    (2 * 100 * 60 : ℚ) / 60000 = 1 / 5 ∧ (2 * 100 * 60 : ℚ) / 600000 = 1 / 50 := by norm_num
-- The value-sorted formula for the reading: 1 x 0 + 0 x 60 = 0.
example : 1 * 0 + 0 * 60 = 0 := by norm_num
-- Cover widths eps/2 + eps/4 + ... over the first N places add to eps (1 - 1/2^N); N = 10.
example : ∑ j ∈ Finset.range 10, (1 : ℚ) / 2 ^ (j + 1) = 1 - 1 / 2 ^ 10 := by
  norm_num [Finset.sum_range_succ]

#print axioms rational_minute_reading_integral_eq_zero
#print axioms sum_eq_sum_value_times_count
#print axioms rational_minute_switch_on_integrals_tendsto
