-- Caplets on compounded SOFR: a volatility that falls in a straight line to zero across the period, squared and added up, is worth exactly one third of the period, so the variance time is the start date plus a third; 63 daily fixings bracket that third, and the random walk's double sum agrees.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic

open Real Finset intervalIntegral Filter Topology

/-! `Ts` is the start of the interest period and `Te` its end, `τ = Te - Ts` its length in years.
The shape `g(t)`, written `shape Ts Te t`, is the share of the volatility the compounded rate still carries at time `t`:
1 until the period starts, then `(Te - t) / τ`, falling in a straight line to 0 at `Te`.
The variance time is the area under `g(t)²` from today to `Te`. -/

/-- The shape: full volatility until the period starts, then a straight fall to zero. -/
noncomputable def shape (Ts Te t : ℝ) : ℝ := if t ≤ Ts then 1 else (Te - t) / (Te - Ts)

/-- The one-third rule: a share falling in a straight line from 1 to 0 over a period of length
`τ`, squared and added up, is worth exactly `τ / 3`. -/
theorem one_third_rule (τ : ℝ) (hτ : 0 < τ) :
    ∫ u in (0:ℝ)..τ, ((τ - u) / τ) ^ 2 = τ / 3 := by
  have h : ∀ u : ℝ, ((τ - u) / τ) ^ 2 = 1 - (2 / τ) * u + (1 / τ ^ 2) * u ^ 2 := by
    intro u; field_simp; ring
  simp_rw [h]
  rw [integral_add, integral_sub, integral_const_mul, integral_const_mul, integral_pow, integral_id,
    integral_const]
  · simp; field_simp; ring
  all_goals first
    | exact intervalIntegrable_const
    | exact (continuous_const.mul continuous_id).intervalIntegrable _ _
    | exact (continuous_const.mul (continuous_pow 2)).intervalIntegrable _ _
    | exact (continuous_const.sub (continuous_const.mul continuous_id)).intervalIntegrable _ _

/-- Averaging the volatility instead of its square gives half the period, not a third. -/
theorem averaged_volatility_gives_half (τ : ℝ) (hτ : 0 < τ) :
    ∫ u in (0:ℝ)..τ, (τ - u) / τ = τ / 2 := by
  have h : ∀ u : ℝ, (τ - u) / τ = 1 - (1 / τ) * u := by intro u; field_simp
  simp_rw [h]
  rw [integral_sub, integral_const_mul, integral_id, integral_const]
  · simp; field_simp; ring
  · exact intervalIntegrable_const
  · exact (continuous_const.mul continuous_id).intervalIntegrable _ _

/-- The variance time: the squared shape, added up from today to the period's end, is the
start date plus one third of the period, `v = Ts + τ / 3`. -/
theorem variance_time (Ts Te : ℝ) (h0 : 0 ≤ Ts) (h : Ts < Te) :
    ∫ t in (0:ℝ)..Te, shape Ts Te t ^ 2 = Ts + (Te - Ts) / 3 := by
  have hτ : 0 < Te - Ts := by linarith
  have hint1 : IntervalIntegrable (fun t ↦ shape Ts Te t ^ 2) MeasureTheory.volume 0 Ts := by
    refine (intervalIntegrable_const : IntervalIntegrable (fun _ : ℝ ↦ (1:ℝ))
      MeasureTheory.volume 0 Ts).congr ?_
    intro t ht
    rw [Set.uIoc_of_le h0] at ht
    simp [shape, ht.2]
  have hint2 : IntervalIntegrable (fun t ↦ shape Ts Te t ^ 2) MeasureTheory.volume Ts Te := by
    have hc : Continuous (fun t : ℝ ↦ ((Te - t) / (Te - Ts)) ^ 2) := by fun_prop
    refine (hc.intervalIntegrable Ts Te).congr ?_
    intro t ht
    rw [Set.uIoc_of_le h.le] at ht
    simp [shape, not_le.mpr ht.1]
  rw [← integral_add_adjacent_intervals hint1 hint2]
  have e1 : ∫ t in (0:ℝ)..Ts, shape Ts Te t ^ 2 = ∫ t in (0:ℝ)..Ts, (1:ℝ) := by
    refine integral_congr_ae (MeasureTheory.ae_of_all _ ?_)
    intro t ht
    rw [Set.uIoc_of_le h0] at ht
    simp [shape, ht.2]
  have e2 : ∫ t in Ts..Te, shape Ts Te t ^ 2 = ∫ t in Ts..Te, ((Te - t) / (Te - Ts)) ^ 2 := by
    refine integral_congr_ae (MeasureTheory.ae_of_all _ ?_)
    intro t ht
    rw [Set.uIoc_of_le h.le] at ht
    simp [shape, not_le.mpr ht.1]
  have e3 : ∫ t in Ts..Te, ((Te - t) / (Te - Ts)) ^ 2
      = ∫ u in (0:ℝ)..(Te - Ts), (((Te - Ts) - u) / (Te - Ts)) ^ 2 := by
    have hs := integral_comp_add_right (fun t ↦ ((Te - t) / (Te - Ts)) ^ 2) (a := 0)
      (b := Te - Ts) Ts
    simp only [zero_add, sub_add_cancel] at hs
    rw [← hs]
    refine integral_congr (fun u _ ↦ ?_)
    ring_nf
  rw [e1, e2, e3, one_third_rule _ hτ, integral_const]
  simp

/-- The sums of `j` and of `j²` over the first `n` whole numbers. -/
lemma sum_range_id_real (n : ℕ) : ∑ j ∈ range n, (j:ℝ) = (n:ℝ) * (n - 1) / 2 := by
  induction n with
  | zero => simp
  | succ k ih => rw [sum_range_succ, ih]; push_cast; ring

lemma sum_range_sq_real (n : ℕ) : ∑ j ∈ range n, (j:ℝ) ^ 2 = (n:ℝ) * (n - 1) * (2 * n - 1) / 6 := by
  induction n with
  | zero => simp
  | succ k ih => rw [sum_range_succ, ih]; push_cast; ring

/-- Daily fixings, each day's rate set at that day's start: during day `j + 1` the share still
unset is `(n - (j + 1)) / n`, and the squared shares, each held for `h = τ / n`, add to
`τ (n - 1)(2n - 1) / (6 n²)`. -/
theorem fixings_set_at_start (τ : ℝ) (n : ℕ) (hn : 0 < n) :
    ∑ j ∈ range n, (τ / n) * (((n:ℝ) - (j + 1)) / n) ^ 2
      = τ * ((n:ℝ) - 1) * (2 * n - 1) / (6 * (n:ℝ) ^ 2) := by
  have hn' : (n:ℝ) ≠ 0 := by positivity
  have key : ∀ j : ℕ, (τ / n) * (((n:ℝ) - (j + 1)) / n) ^ 2
      = (τ / n ^ 3) * ((n:ℝ) - 1) ^ 2 - (τ / n ^ 3) * (2 * ((n:ℝ) - 1)) * j
        + (τ / n ^ 3) * (j:ℝ) ^ 2 := by
    intro j; field_simp; ring
  simp_rw [key]
  rw [sum_add_distrib, sum_sub_distrib, ← mul_sum, ← mul_sum, ← mul_sum, sum_range_id_real,
    sum_range_sq_real, sum_const, card_range, nsmul_eq_mul]
  field_simp; ring

/-- Each day's rate set at that day's end instead: during day `j + 1` the unset share is
`(n - j) / n`, and the sum is `τ (n + 1)(2n + 1) / (6 n²)`. -/
theorem fixings_set_at_end (τ : ℝ) (n : ℕ) (hn : 0 < n) :
    ∑ j ∈ range n, (τ / n) * (((n:ℝ) - j) / n) ^ 2
      = τ * ((n:ℝ) + 1) * (2 * n + 1) / (6 * (n:ℝ) ^ 2) := by
  have hn' : (n:ℝ) ≠ 0 := by positivity
  have key : ∀ j : ℕ, (τ / n) * (((n:ℝ) - j) / n) ^ 2
      = (τ / n ^ 3) * (n:ℝ) ^ 2 - (τ / n ^ 3) * (2 * (n:ℝ)) * j + (τ / n ^ 3) * (j:ℝ) ^ 2 := by
    intro j; field_simp; ring
  simp_rw [key]
  rw [sum_add_distrib, sum_sub_distrib, ← mul_sum, ← mul_sum, ← mul_sum, sum_range_id_real,
    sum_range_sq_real, sum_const, card_range, nsmul_eq_mul]
  field_simp; ring

/-- The two timings bracket the third: for any number of fixings, set-at-start falls short of
`1/3` of the period and set-at-end overshoots it. -/
theorem fixings_bracket_the_third (n : ℕ) (hn : 0 < n) :
    ((n:ℝ) - 1) * (2 * n - 1) / (6 * (n:ℝ) ^ 2) < 1 / 3 ∧
      1 / 3 < ((n:ℝ) + 1) * (2 * n + 1) / (6 * (n:ℝ) ^ 2) := by
  have h1 : (1:ℝ) ≤ n := by exact_mod_cast hn
  have h6 : (0:ℝ) < 6 * (n:ℝ) ^ 2 := by positivity
  constructor
  · rw [div_lt_iff₀ h6]; nlinarith
  · rw [lt_div_iff₀ h6]; nlinarith

/-- As the fixings get finer, the set-at-start share tends to exactly one third. -/
theorem fixings_tend_to_one_third :
    Tendsto (fun n : ℕ ↦ ((n:ℝ) - 1) * (2 * n - 1) / (6 * (n:ℝ) ^ 2)) atTop (𝓝 (1 / 3)) := by
  have h : Tendsto (fun n : ℕ ↦ 1 / (n:ℝ)) atTop (𝓝 0) := tendsto_one_div_atTop_nhds_zero_nat
  have h2 : Tendsto (fun n : ℕ ↦ 1 / 3 - (1 / 2) * (1 / (n:ℝ)) + (1 / 6) * (1 / (n:ℝ)) ^ 2)
      atTop (𝓝 (1 / 3 - (1 / 2) * 0 + (1 / 6) * 0 ^ 2)) :=
    ((tendsto_const_nhds (x := (1 / 3 : ℝ))).sub (h.const_mul (1 / 2 : ℝ))).add
      ((h.pow 2).const_mul (1 / 6 : ℝ))
  rw [show (1 / 3 : ℝ) - 1 / 2 * 0 + 1 / 6 * 0 ^ 2 = 1 / 3 by norm_num] at h2
  refine h2.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have : (n:ℝ) ≠ 0 := by have : (1:ℝ) ≤ n := by exact_mod_cast hn
                         positivity
  field_simp; ring

/-- The random walk's road: the shared time of two points on one walk is the earlier time, and
over `n` fixings the double sum of `min j k` is `(n - 1) n (2n - 1) / 6`, the same sum of
squares as above. -/
theorem random_walk_double_sum (n : ℕ) :
    ∑ j ∈ range n, ∑ k ∈ range n, ((min j k : ℕ) : ℝ) = ((n:ℝ) - 1) * n * (2 * n - 1) / 6 := by
  induction n with
  | zero => simp
  | succ k ih =>
    have hrow : ∀ j ∈ range k, ((min j k : ℕ) : ℝ) = j := fun j hj ↦ by
      rw [min_eq_left (mem_range.mp hj).le]
    have hcol : ∀ j ∈ range k, ((min k j : ℕ) : ℝ) = j := fun j hj ↦ by
      rw [min_eq_right (mem_range.mp hj).le]
    rw [sum_range_succ]
    simp_rw [sum_range_succ (fun x ↦ ((min _ x : ℕ) : ℝ))]
    rw [sum_add_distrib, ih, sum_congr rfl hrow, sum_congr rfl hcol, sum_range_id_real]
    simp only [min_self]
    push_cast; ring

/-! The card's example: `Ts = 1.75`, `Te = 2.0`, 63 daily fixings. -/

theorem example_variance_times :
    (7 / 4 : ℝ) + (1 / 4) / 3 = 11 / 6 ∧
      |(7 / 4 : ℝ) + (1 / 4) * (63 - 1) * (2 * 63 - 1) / (6 * 63 ^ 2) - 1.831360| < 5e-7 ∧
      |(7 / 4 : ℝ) + (1 / 4) * (63 + 1) * (2 * 63 + 1) / (6 * 63 ^ 2) - 1.835328| < 5e-7 ∧
      |(11 / 6 : ℝ) - 1.833333| < 5e-7 := by
  refine ⟨by norm_num, ?_, ?_, ?_⟩ <;> rw [abs_sub_lt_iff] <;> constructor <;> norm_num

/-- At the money, Black's two distances are mirror images: `d₂ = -d₁`. -/
theorem atm_d2_eq_neg_d1 (F σ v : ℝ) (hF : 0 < F) (hσ : 0 < σ) (hv : 0 < v) :
    let d1 := (log (F / F) + σ ^ 2 * v / 2) / (σ * √v)
    d1 - σ * √v = -d1 := by
  intro d1
  have hs : 0 < √v := Real.sqrt_pos.mpr hv
  have hsq : √v ^ 2 = v := sq_sqrt hv.le
  have hd : d1 = σ * √v / 2 := by
    simp only [d1, div_self hF.ne', log_one, zero_add]
    rw [div_eq_iff (by positivity)]
    linear_combination (-σ ^ 2 / 2) * hsq
  rw [hd]; ring

/-- The bell curve's height at `x`. -/
noncomputable def bellHeight (x : ℝ) : ℝ := rexp (-x ^ 2 / 2) / √(2 * π)

/-- Bachelier's caplet on the clock `v`: `τ D [m N(d) + s φ(d)]` with `s = σ_N √v`, `m = F - K`
and `d = m / s`. The bell-curve area `N` is left as any function: at the money it drops out. -/
noncomputable def bachelierCaplet (N : ℝ → ℝ) (τ D F K σN v : ℝ) : ℝ :=
  τ * D * ((F - K) * N ((F - K) / (σN * √v)) + σN * √v * bellHeight ((F - K) / (σN * √v)))

/-- At the money the Bachelier caplet grows with the square root of the clock: the ratio of the
prices on two clocks is the square root of their ratio, whatever the normal volatility. -/
theorem bachelier_atm_ratio (N : ℝ → ℝ) (τ D F σN v₁ v₂ : ℝ) (hτ : 0 < τ) (hD : 0 < D)
    (hσ : 0 < σN) (h₁ : 0 < v₁) :
    bachelierCaplet N τ D F F σN v₂ / bachelierCaplet N τ D F F σN v₁ = √(v₂ / v₁) := by
  have hs : 0 < √v₁ := Real.sqrt_pos.mpr h₁
  have hφ : 0 < bellHeight 0 := by unfold bellHeight; positivity
  simp only [bachelierCaplet, sub_self, zero_div, zero_mul, zero_add]
  rw [Real.sqrt_div' _ h₁.le]
  field_simp

#print axioms one_third_rule
#print axioms averaged_volatility_gives_half
#print axioms variance_time
#print axioms sum_range_id_real
#print axioms sum_range_sq_real
#print axioms fixings_set_at_start
#print axioms fixings_set_at_end
#print axioms fixings_bracket_the_third
#print axioms fixings_tend_to_one_third
#print axioms random_walk_double_sum
#print axioms example_variance_times
#print axioms atm_d2_eq_neg_d1
#print axioms bachelier_atm_ratio
