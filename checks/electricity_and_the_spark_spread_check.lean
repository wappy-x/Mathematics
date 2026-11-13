-- Power that cannot be stored: a zero-cost power forward equals the average future spot price under the pricing weights, a plant's option is worth at least its locked-in margin, and splitting a month into blocks never lowers its value.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

open MeasureTheory

/-- A forward agreed today at price `F` pays `S_T - F` at time `T` and costs nothing to enter.
If every payoff's price today is `e^{-rT}` times its average under the pricing weights `Q`,
then the forward price is the average future spot price: `F = E^Q[S_T]`.
No storage or carry enters the argument. -/
theorem forward_price_eq_expected_spot {Ω : Type*} [MeasurableSpace Ω]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (S : Ω → ℝ) (hS : Integrable S Q)
    (r T F : ℝ) (hzero : Real.exp (-r * T) * ∫ ω, (S ω - F) ∂Q = 0) :
    F = ∫ ω, S ω ∂Q := by
  have hpos : 0 < Real.exp (-r * T) := Real.exp_pos _
  have h0 : ∫ ω, (S ω - F) ∂Q = 0 := by
    rcases mul_eq_zero.mp hzero with h | h
    · exact absurd h hpos.ne'
    · exact h
  rw [integral_sub hS (integrable_const F)] at h0
  simp at h0
  linarith

/-- The spark spread option, which pays `max(S_T - H G_T - K, 0)`, is worth at least the
discounted margin the forwards lock in, `e^{-rT} max(F_P - H F_G - K, 0)`, where the forwards
are the averages `F_P = E^Q[S_T]` and `F_G = E^Q[G_T]`. The difference is the value of being
allowed to stay off. -/
theorem spark_spread_option_ge_locked_in_margin {Ω : Type*} [MeasurableSpace Ω]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (S G : Ω → ℝ)
    (hS : Integrable S Q) (hG : Integrable G Q) (r T H K : ℝ) :
    Real.exp (-r * T) * max ((∫ ω, S ω ∂Q) - H * (∫ ω, G ω ∂Q) - K) 0 ≤
      Real.exp (-r * T) * ∫ ω, max (S ω - H * G ω - K) 0 ∂Q := by
  apply mul_le_mul_of_nonneg_left _ (Real.exp_pos _).le
  have hSG : Integrable (fun ω => S ω - H * G ω) Q := hS.sub (hG.const_mul H)
  have hf : Integrable (fun ω => S ω - H * G ω - K) Q := hSG.sub (integrable_const K)
  have hm : Integrable (fun ω => max (S ω - H * G ω - K) 0) Q := hf.pos_part
  refine max_le ?_ ?_
  · have h1 : ∫ ω, (S ω - H * G ω - K) ∂Q = (∫ ω, S ω ∂Q) - H * (∫ ω, G ω ∂Q) - K := by
      rw [integral_sub hSG (integrable_const K),
        integral_sub hS (hG.const_mul H), integral_const_mul]
      simp
    rw [← h1]
    exact integral_mono hf hm (fun ω => le_max_left _ _)
  · exact integral_nonneg (fun ω => le_max_right _ _)

/-- Splitting a month into blocks can only add value. The month is split into blocks `i`
with `h i ≥ 0` hours each (at least one hour in all) and block power prices `P i`; the
baseload price is their hour-weighted average. One baseload decision for the month is worth
no more than the hour-weighted average of separate decisions, one per block. -/
theorem block_options_ge_baseload_option {Ω ι : Type*} [MeasurableSpace Ω]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (s : Finset ι) (h : ι → ℝ)
    (hh : ∀ i ∈ s, 0 ≤ h i) (hpos : 0 < ∑ i ∈ s, h i)
    (P : ι → Ω → ℝ) (hP : ∀ i ∈ s, Integrable (P i) Q) (G : Ω → ℝ) (hG : Integrable G Q)
    (r T H K : ℝ) :
    Real.exp (-r * T) *
        ∫ ω, max ((∑ i ∈ s, h i * P i ω) / (∑ i ∈ s, h i) - H * G ω - K) 0 ∂Q ≤
      (∑ i ∈ s, h i * (Real.exp (-r * T) * ∫ ω, max (P i ω - H * G ω - K) 0 ∂Q)) /
        (∑ i ∈ s, h i) := by
  set W := ∑ i ∈ s, h i with hW
  set E := Real.exp (-r * T) with hE
  have hEpos : 0 < E := Real.exp_pos _
  have hmi : ∀ i ∈ s, Integrable (fun ω => h i * max (P i ω - H * G ω - K) 0) Q := by
    intro i hi
    exact ((((hP i hi).sub (hG.const_mul H)).sub (integrable_const K)).pos_part).const_mul _
  have hsum : Integrable (fun ω => ∑ i ∈ s, h i * max (P i ω - H * G ω - K) 0) Q :=
    integrable_finsetSum s hmi
  have hpt : ∀ ω, max ((∑ i ∈ s, h i * P i ω) / W - H * G ω - K) 0 ≤
      (∑ i ∈ s, h i * max (P i ω - H * G ω - K) 0) / W := by
    intro ω
    have hnn : 0 ≤ ∑ i ∈ s, h i * max (P i ω - H * G ω - K) 0 :=
      Finset.sum_nonneg (fun i hi => mul_nonneg (hh i hi) (le_max_right _ _))
    refine max_le ?_ (div_nonneg hnn hpos.le)
    have heq : (∑ i ∈ s, h i * P i ω) / W - H * G ω - K =
        (∑ i ∈ s, h i * (P i ω - H * G ω - K)) / W := by
      field_simp
      simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul]
      rw [hW]
      ring
    rw [heq]
    apply div_le_div_of_nonneg_right _ hpos.le
    exact Finset.sum_le_sum (fun i hi => mul_le_mul_of_nonneg_left (le_max_left _ _) (hh i hi))
  have hint : ∫ ω, max ((∑ i ∈ s, h i * P i ω) / W - H * G ω - K) 0 ∂Q ≤
      ∫ ω, (∑ i ∈ s, h i * max (P i ω - H * G ω - K) 0) / W ∂Q :=
    integral_mono_of_nonneg (Filter.Eventually.of_forall (fun ω => le_max_right _ _))
      (hsum.div_const W) (Filter.Eventually.of_forall hpt)
  have hrhs : ∫ ω, (∑ i ∈ s, h i * max (P i ω - H * G ω - K) 0) / W ∂Q =
      (∑ i ∈ s, h i * ∫ ω, max (P i ω - H * G ω - K) 0 ∂Q) / W := by
    rw [integral_div, integral_finsetSum s hmi]
    congr 1
    refine Finset.sum_congr rfl (fun i _ => ?_)
    exact integral_const_mul _ _
  calc E * ∫ ω, max ((∑ i ∈ s, h i * P i ω) / W - H * G ω - K) 0 ∂Q
      ≤ E * ((∑ i ∈ s, h i * ∫ ω, max (P i ω - H * G ω - K) 0 ∂Q) / W) := by
        rw [← hrhs]; exact mul_le_mul_of_nonneg_left hint hEpos.le
    _ = (∑ i ∈ s, h i * (E * ∫ ω, max (P i ω - H * G ω - K) 0 ∂Q)) / W := by
        rw [mul_div_assoc', Finset.mul_sum]
        congr 1
        refine Finset.sum_congr rfl (fun i _ => ?_)
        ring

-- July 2027 has 31 days of 24 hours.
example : 31 * 24 = 744 := by norm_num

-- 1 July 2027 is a Thursday (Monday = 0, so weekday 3), by Sakamoto's rule as the card's code writes it.
example : (2027 + 2027 / 4 - 2027 / 100 + 2027 / 400 + 5 + 1 + 6) % 7 = 3 := by decide

-- Starting on a Thursday, July 2027 has 22 weekdays, so 22 × 16 = 352 peak hours.
example : ((Finset.range 31).filter (fun d => (3 + d) % 7 < 5)).card = 22 := by decide
example : ((Finset.range 31).filter (fun d => (3 + d) % 7 < 5)).card * 16 = 352 := by decide

-- Off-peak hours: 744 - 352 = 392.
example : 744 - 352 = 392 := by norm_num

-- Peak $60, baseload $50: 50 × 744 = 60 × 352 + off-peak × 392 gives off-peak = 2010/49 (about $41.02).
example : (50 : ℚ) * 744 = 60 * 352 + (2010 / 49) * 392 := by norm_num

-- Fuel per MWh: heat rate 15/2 times gas $3 is $45/2; the spark spread is 50 - 45/2 = 55/2;
-- fuel plus the $5 cost is 55/2 as well.
example : (15 / 2 : ℚ) * 3 = 45 / 2 := by norm_num
example : (50 : ℚ) - 15 / 2 * 3 = 55 / 2 := by norm_num
example : (15 / 2 : ℚ) * 3 + 5 = 55 / 2 := by norm_num

-- The payoff at expiry, power minus 55/2 or nothing, at power $30 and $20 (chart points).
example : max ((30 : ℚ) - 55 / 2) 0 = 5 / 2 := by norm_num
example : max ((20 : ℚ) - 55 / 2) 0 = 0 := by norm_num

-- The peaker: heat rate 15 at gas $3 burns $45, so $50 power exactly covers fuel plus $5 cost.
example : max ((50 : ℚ) - 15 * 3 - 5) 0 = 0 := by norm_num

#print axioms forward_price_eq_expected_spot
#print axioms spark_spread_option_ge_locked_in_margin
#print axioms block_options_ge_baseload_option
