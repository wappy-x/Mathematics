-- Dini's theorem: continuous functions on a closed interval [a, b] that rise (or fall) at every input toward a continuous limit converge to it uniformly, and dropping "closed" or "one direction" breaks this.
import Mathlib.Topology.UniformSpace.Dini
import Mathlib.Topology.Order.Compact
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Filter Topology

/-- For every stage n ≥ 1 there is an input x with 0 ≤ x < 1 and x ^ n = 1/2. -/
theorem dini_helper_exists_pow_eq_half (n : ℕ) (hn : n ≠ 0) :
    ∃ x : ℝ, 0 ≤ x ∧ x < 1 ∧ x ^ n = 1 / 2 := by
  refine ⟨(1 / 2 : ℝ) ^ ((n : ℝ)⁻¹), Real.rpow_nonneg (by norm_num) _,
    Real.rpow_lt_one (by norm_num) (by norm_num) (by positivity),
    Real.rpow_inv_natCast_pow (by norm_num) hn⟩

#print axioms dini_helper_exists_pow_eq_half

/-- Dini's theorem. Let f 0, f 1, f 2, … be continuous on the closed interval [a, b], rising at
every input (f 0 x ≤ f 1 x ≤ f 2 x ≤ ⋯), with f n x heading for f x at every x in [a, b], and
let the limit f be continuous on [a, b]. Then the convergence is uniform on [a, b]: for every
tolerance there is one stage after which every gap |f x − f n x| with x in [a, b] is within it,
so the worst gap E_n heads for 0. -/
theorem dini_rising_continuous_converges_uniformly_on_closed_interval (a b : ℝ)
    (F : ℕ → ℝ → ℝ) (f : ℝ → ℝ)
    (hF_cont : ∀ n, ContinuousOn (F n) (Set.Icc a b))
    (hF_rise : ∀ x ∈ Set.Icc a b, Monotone (fun n => F n x))
    (hf_cont : ContinuousOn f (Set.Icc a b))
    (h_lim : ∀ x ∈ Set.Icc a b, Tendsto (fun n => F n x) atTop (𝓝 (f x))) :
    TendstoUniformlyOn F f atTop (Set.Icc a b) := by
  exact Monotone.tendstoUniformlyOn_of_forall_tendsto isCompact_Icc hF_cont hF_rise hf_cont h_lim

/-- Falling sequences work the same way. Let f 0, f 1, … be continuous on [a, b], falling at
every input (f 0 x ≥ f 1 x ≥ ⋯), with f n x heading for f x at every x in [a, b], and let f be
continuous on [a, b]. Then the convergence is uniform on [a, b]. The card's bond example x^n on
[0, 9/10] is of this kind. -/
theorem dini_falling_continuous_converges_uniformly_on_closed_interval (a b : ℝ)
    (F : ℕ → ℝ → ℝ) (f : ℝ → ℝ)
    (hF_cont : ∀ n, ContinuousOn (F n) (Set.Icc a b))
    (hF_fall : ∀ x ∈ Set.Icc a b, Antitone (fun n => F n x))
    (hf_cont : ContinuousOn f (Set.Icc a b))
    (h_lim : ∀ x ∈ Set.Icc a b, Tendsto (fun n => F n x) atTop (𝓝 (f x))) :
    TendstoUniformlyOn F f atTop (Set.Icc a b) := by
  exact Antitone.tendstoUniformlyOn_of_forall_tendsto isCompact_Icc hF_cont hF_fall hf_cont h_lim

/-- Two of the card's examples showing a condition is needed. (1) Not closed: on [0, 1) the
continuous functions x^n fall at every input to the continuous limit 0, yet the convergence is
not uniform. (2) Not one direction: on [0, 1] the continuous functions x^n − x^(2n) head for the
continuous limit 0 at every input, yet the convergence is not uniform; where x^n = 1/2 the gap
is 1/4 at every stage. -/
theorem dini_fails_without_closed_interval_or_one_direction :
    ((∀ x ∈ Set.Ico (0 : ℝ) 1, Antitone (fun n : ℕ => x ^ n)) ∧
      (∀ x ∈ Set.Ico (0 : ℝ) 1, Tendsto (fun n : ℕ => x ^ n) atTop (𝓝 0)) ∧
      ¬ TendstoUniformlyOn (fun (n : ℕ) (x : ℝ) => x ^ n) (fun _ => 0) atTop (Set.Ico 0 1)) ∧
    ((∀ x ∈ Set.Icc (0 : ℝ) 1, Tendsto (fun n : ℕ => x ^ n - x ^ (2 * n)) atTop (𝓝 0)) ∧
      (∀ (n : ℕ) (x : ℝ), x ^ n = 1 / 2 → x ^ n - x ^ (2 * n) = 1 / 4) ∧
      ¬ TendstoUniformlyOn (fun (n : ℕ) (x : ℝ) => x ^ n - x ^ (2 * n)) (fun _ => 0) atTop
        (Set.Icc 0 1)) := by
  refine ⟨⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩⟩
  · intro x hx m k hmk
    exact pow_le_pow_of_le_one hx.1 hx.2.le hmk
  · intro x hx
    exact tendsto_pow_atTop_nhds_zero_of_lt_one hx.1 hx.2
  · intro h
    rw [Metric.tendstoUniformlyOn_iff] at h
    obtain ⟨n, hn, hn1⟩ :=
      ((h (1 / 2) (by norm_num)).and (eventually_ge_atTop 1)).exists
    obtain ⟨x, hx0, hx1, hxn⟩ := dini_helper_exists_pow_eq_half n (by omega)
    have := hn x ⟨hx0, hx1⟩
    rw [hxn, Real.dist_eq] at this
    norm_num [abs_of_neg] at this
  · intro x hx
    rcases eq_or_lt_of_le hx.2 with h1 | h1
    · subst h1
      simp
    · have h2 : Tendsto (fun n : ℕ => x ^ (2 * n)) atTop (𝓝 0) := by
        have := tendsto_pow_atTop_nhds_zero_of_lt_one (sq_nonneg x)
          (by nlinarith [hx.1] : x ^ 2 < 1)
        simpa [pow_mul] using this
      simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hx.1 h1).sub h2
  · intro n x hx
    rw [pow_mul', hx]
    norm_num
  · intro h
    rw [Metric.tendstoUniformlyOn_iff] at h
    obtain ⟨n, hn, hn1⟩ :=
      ((h (1 / 4) (by norm_num)).and (eventually_ge_atTop 1)).exists
    obtain ⟨x, hx0, hx1, hxn⟩ := dini_helper_exists_pow_eq_half n (by omega)
    have := hn x ⟨hx0, hx1.le⟩
    rw [pow_mul', hxn, Real.dist_eq] at this
    norm_num [abs_of_neg] at this

/-! The card's exact worked numbers, with the tolerance 1/10 (ten cents). -/

-- The one cutoff on [0, 9/10] is year 22: (9/10)^21 is not under 1/10, (9/10)^22 is.
example : (9 / 10 : ℚ) ^ 22 < 1 / 10 ∧ ¬ ((9 / 10 : ℚ) ^ 21 < 1 / 10) := by norm_num
-- Single-input cutoffs: 4 at x = 1/2 and 11 at x = 4/5.
example : (1 / 2 : ℚ) ^ 4 < 1 / 10 ∧ ¬ ((1 / 2 : ℚ) ^ 3 < 1 / 10) := by norm_num
example : (4 / 5 : ℚ) ^ 11 < 1 / 10 ∧ ¬ ((4 / 5 : ℚ) ^ 10 < 1 / 10) := by norm_num
-- 230 at x = 99/100 and 2302 at x = 999/1000, cleared of fractions:
-- (p/q)^n < 1/10 means 10 · p^n < q^n.
set_option exponentiation.threshold 3000 in
example : 10 * 99 ^ 230 < 100 ^ 230 ∧ ¬ (10 * 99 ^ 229 < 100 ^ 229) := by decide
set_option exponentiation.threshold 3000 in
example : 10 * 999 ^ 2302 < 1000 ^ 2302 ∧ ¬ (10 * 999 ^ 2301 < 1000 ^ 2301) := by decide
-- The bump x^n − x^(2n) where x^n = 1/2: the gap is 1/2 − 1/4 = 1/4.
example : (1 / 2 : ℚ) - (1 / 2) ^ 2 = 1 / 4 := by norm_num
-- The step 1 on (0, 1/n) at n = 22: the input 1/44 lies inside, so its gap is 1.
example : (0 : ℚ) < 1 / 44 ∧ (1 / 44 : ℚ) < 1 / 22 := by norm_num

#print axioms dini_rising_continuous_converges_uniformly_on_closed_interval
#print axioms dini_falling_continuous_converges_uniformly_on_closed_interval
#print axioms dini_fails_without_closed_interval_or_one_direction
