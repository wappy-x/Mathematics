-- The logarithmic integral: the offset logarithmic integral Li(x), the area under 1/log t from 2 to x, equals x/log x + x/log² x + 2! x/log³ x + ⋯ + (K−1)! x/log^K x up to an error at most a fixed multiple of x/log^(K+1) x, each term comes from one round of integration by parts, and the full series diverges at every x > 1.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.Tactic.NormNum
import Mathlib.Topology.Algebra.Order.Floor

open Asymptotics Filter

lemma li_aux_intervalIntegrable (n : ℕ) {a b : ℝ} (ha : 1 < a) (hb : 1 < b) :
    IntervalIntegrable (fun t : ℝ => 1 / Real.log t ^ n) MeasureTheory.volume a b := by
  apply ContinuousOn.intervalIntegrable
  intro t ht
  have h1 : 1 < t := by
    rcases Set.mem_uIcc.mp ht with h | h <;> linarith [h.1]
  have hL : Real.log t ≠ 0 := (Real.log_pos h1).ne'
  apply ContinuousAt.continuousWithinAt
  exact continuousAt_const.div ((Real.continuousAt_log (by linarith)).pow n) (pow_ne_zero _ hL)

lemma li_aux_hasDerivAt (n : ℕ) {t : ℝ} (ht : 1 < t) :
    HasDerivAt (fun t : ℝ => t / Real.log t ^ (n + 1))
      (1 / Real.log t ^ (n + 1) - (n + 1 : ℝ) * (1 / Real.log t ^ (n + 2))) t := by
  have hL : Real.log t ≠ 0 := (Real.log_pos ht).ne'
  have ht0 : t ≠ 0 := by linarith
  have h1 := (Real.hasDerivAt_log ht0).fun_pow (n + 1)
  have h2 := (hasDerivAt_id' t).fun_div h1 (pow_ne_zero _ hL)
  convert h2 using 1
  rw [Nat.add_sub_cancel]
  field_simp
  push_cast
  ring

lemma li_aux_by_parts (n : ℕ) {a b : ℝ} (ha : 1 < a) (hb : 1 < b) :
    ∫ t in a..b, (1 / Real.log t ^ (n + 1) - (n + 1 : ℝ) * (1 / Real.log t ^ (n + 2))) =
      b / Real.log b ^ (n + 1) - a / Real.log a ^ (n + 1) := by
  apply intervalIntegral.integral_eq_sub_of_hasDerivAt
  · intro t ht
    have h1 : 1 < t := by
      rcases Set.mem_uIcc.mp ht with h | h <;> linarith [h.1]
    exact li_aux_hasDerivAt n h1
  · exact (li_aux_intervalIntegrable _ ha hb).sub
      ((li_aux_intervalIntegrable _ ha hb).const_mul _)

lemma li_aux_eventually_one_le (n : ℕ) :
    ∀ᶠ x : ℝ in atTop, 1 ≤ x / Real.log x ^ n := by
  have h := (Real.isLittleO_pow_log_id_atTop (n := n)).bound one_pos
  filter_upwards [h, eventually_ge_atTop (3 : ℝ)] with x hx hx3
  have hlog : 0 < Real.log x := Real.log_pos (by linarith)
  have hp : 0 < Real.log x ^ n := pow_pos hlog n
  rw [Real.norm_of_nonneg hp.le, id, Real.norm_of_nonneg (by linarith), one_mul] at hx
  rw [le_div_iff₀ hp, one_mul]
  exact hx

lemma li_aux_integral_isBigO (n : ℕ) :
    (fun x : ℝ => ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (n + 1))
      =O[atTop] (fun x : ℝ => x / Real.log x ^ (n + 1)) := by
  set x0 : ℝ := Real.exp (2 * (n + 1)) with hx0
  have hx0ge : 3 ≤ x0 := by
    have := Real.add_one_le_exp (2 * (n + 1 : ℝ))
    have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    linarith
  set C : ℝ := ∫ t in (2 : ℝ)..x0, 1 / Real.log t ^ (n + 1) with hC
  apply IsBigO.of_bound (|C| + 2)
  filter_upwards [eventually_ge_atTop x0, li_aux_eventually_one_le (n + 1)] with x hx hG
  have hx1 : 1 < x := by linarith
  have hlogx0 : Real.log x0 = 2 * (n + 1) := by rw [hx0, Real.log_exp]
  -- nonnegativity
  have hI0 : 0 ≤ ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (n + 1) := by
    apply intervalIntegral.integral_nonneg (by linarith)
    intro t ht
    have : 0 < Real.log t := Real.log_pos (by linarith [ht.1])
    positivity
  -- split
  have hsplit := intervalIntegral.integral_add_adjacent_intervals
    (li_aux_intervalIntegrable (n + 1) (a := 2) (b := x0) (by norm_num) (by linarith))
    (li_aux_intervalIntegrable (n + 1) (a := x0) (b := x) (by linarith) hx1)
  -- comparison on [x0, x]
  have hmono : (∫ t in x0..x, 1 / Real.log t ^ (n + 1)) ≤
      ∫ t in x0..x, 2 * (1 / Real.log t ^ (n + 1) - (n + 1 : ℝ) * (1 / Real.log t ^ (n + 2))) := by
    apply intervalIntegral.integral_mono_on hx
      (li_aux_intervalIntegrable (n + 1) (by linarith) hx1)
      (((li_aux_intervalIntegrable _ (by linarith) hx1).sub
        ((li_aux_intervalIntegrable _ (by linarith) hx1).const_mul _)).const_mul _)
    intro t ht
    have hlt : 2 * (n + 1 : ℝ) ≤ Real.log t := by
      rw [← hlogx0]
      exact Real.log_le_log (by linarith) ht.1
    have hL : 0 < Real.log t := by
      have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      linarith
    have hp : 0 < Real.log t ^ (n + 1) := pow_pos hL _
    have e : Real.log t ^ (n + 2) = Real.log t ^ (n + 1) * Real.log t := by ring
    rw [e]
    have key : (n + 1 : ℝ) * (1 / (Real.log t ^ (n + 1) * Real.log t)) ≤
        (1 / 2) * (1 / Real.log t ^ (n + 1)) := by
      rw [mul_one_div, one_div_mul_one_div, div_le_div_iff₀ (by positivity) (by positivity)]
      nlinarith [mul_le_mul_of_nonneg_right hlt hp.le]
    linarith
  rw [intervalIntegral.integral_const_mul, li_aux_by_parts n (by linarith) hx1] at hmono
  have hGx0 : 0 ≤ x0 / Real.log x0 ^ (n + 1) := by
    rw [hlogx0]; positivity
  have hGpos : 0 < x / Real.log x ^ (n + 1) := by linarith
  rw [Real.norm_of_nonneg hI0, Real.norm_of_nonneg hGpos.le]
  have hCabs : C ≤ |C| * (x / Real.log x ^ (n + 1)) := by
    calc C ≤ |C| := le_abs_self C
      _ = |C| * 1 := (mul_one _).symm
      _ ≤ |C| * (x / Real.log x ^ (n + 1)) := mul_le_mul_of_nonneg_left hG (abs_nonneg C)
  rw [← hsplit]
  linarith


lemma li_aux_step (k : ℕ) (x : ℝ) (hx : 2 ≤ x) :
    ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (k + 1) =
      x / Real.log x ^ (k + 1) - 2 / Real.log 2 ^ (k + 1) +
        (k + 1 : ℝ) * ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (k + 2) := by
  have h2 : (1 : ℝ) < 2 := by norm_num
  have hx1 : (1 : ℝ) < x := by linarith
  have key := li_aux_by_parts k h2 hx1
  rw [intervalIntegral.integral_sub (li_aux_intervalIntegrable _ h2 hx1)
    ((li_aux_intervalIntegrable _ h2 hx1).const_mul _), intervalIntegral.integral_const_mul] at key
  linarith

lemma li_aux_expansion (K : ℕ) (x : ℝ) (hx : 2 ≤ x) :
    ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (0 + 1) =
      ∑ k ∈ Finset.range K, (k.factorial : ℝ) * x / Real.log x ^ (k + 1) -
        ∑ k ∈ Finset.range K, (k.factorial : ℝ) * (2 / Real.log 2 ^ (k + 1)) +
        (K.factorial : ℝ) * ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (K + 1) := by
  induction K with
  | zero => simp
  | succ K ih =>
    rw [ih, li_aux_step K x hx, Finset.sum_range_succ, Finset.sum_range_succ,
      Nat.factorial_succ]
    push_cast
    ring

#print axioms li_aux_intervalIntegrable
#print axioms li_aux_hasDerivAt
#print axioms li_aux_by_parts
#print axioms li_aux_eventually_one_le
#print axioms li_aux_integral_isBigO
#print axioms li_aux_step
#print axioms li_aux_expansion

/-- The expansion of Li. For every fixed number of terms K, the offset logarithmic integral
Li(x) = ∫₂ˣ dt/log t equals x/log x + x/log² x + 2! x/log³ x + ⋯ + (K−1)! x/log^K x, with an
error at most a fixed multiple of x/log^(K+1) x as x → ∞. -/
theorem offset_li_asymptotic_expansion (K : ℕ) :
    (fun x : ℝ => (∫ t in (2 : ℝ)..x, 1 / Real.log t) -
        ∑ k ∈ Finset.range K, (k.factorial : ℝ) * x / Real.log x ^ (k + 1))
      =O[atTop] (fun x : ℝ => x / Real.log x ^ (K + 1)) := by
  have hE : (fun x : ℝ => (∫ t in (2 : ℝ)..x, 1 / Real.log t) -
        ∑ k ∈ Finset.range K, (k.factorial : ℝ) * x / Real.log x ^ (k + 1)) =ᶠ[atTop]
      (fun x : ℝ => (-∑ k ∈ Finset.range K, (k.factorial : ℝ) * (2 / Real.log 2 ^ (k + 1))) +
        (K.factorial : ℝ) * ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (K + 1)) := by
    filter_upwards [eventually_ge_atTop (2 : ℝ)] with x hx
    have h := li_aux_expansion K x hx
    simp only [zero_add, pow_one] at h
    rw [h]
    ring
  refine IsBigO.congr' ?_ hE.symm EventuallyEq.rfl
  refine IsBigO.add ?_ ((li_aux_integral_isBigO K).const_mul_left _)
  apply IsBigO.of_bound |(-∑ k ∈ Finset.range K, (k.factorial : ℝ) * (2 / Real.log 2 ^ (k + 1)))|
  filter_upwards [li_aux_eventually_one_le (K + 1)] with x hG
  rw [Real.norm_eq_abs, Real.norm_of_nonneg (by linarith)]
  exact le_mul_of_one_le_right (abs_nonneg _) hG

/-- One round of integration by parts. For x ≥ 2 and every k, the area under 1/log^(k+1) t
from 2 to x is x/log^(k+1) x − 2/log^(k+1) 2 plus (k+1) times the area under 1/log^(k+2) t.
With k = 0 this is Step 1: Li(x) = x/log x − 2/log 2 + ∫₂ˣ dt/log² t. -/
theorem integral_inv_log_pow_by_parts (k : ℕ) (x : ℝ) (hx : 2 ≤ x) :
    ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (k + 1) =
      x / Real.log x ^ (k + 1) - 2 / Real.log 2 ^ (k + 1) +
        (k + 1 : ℝ) * ∫ t in (2 : ℝ)..x, 1 / Real.log t ^ (k + 2) := by
  exact li_aux_step k x hx

/-- The expansion is asymptotic, not convergent. At every x > 1 the full series
x/log x + x/log² x + 2! x/log³ x + ⋯, with terms k! x/log^(k+1) x, does not converge. -/
theorem li_expansion_series_not_summable (x : ℝ) (hx : 1 < x) :
    ¬ Summable (fun k : ℕ => (k.factorial : ℝ) * x / Real.log x ^ (k + 1)) := by
  intro hs
  have hL : 0 < Real.log x := Real.log_pos hx
  have h1 := hs.tendsto_atTop_zero
  have h2 : Tendsto (fun k : ℕ => Real.log x * (Real.log x ^ k / (k.factorial : ℝ)))
      atTop (nhds (Real.log x * 0)) :=
    (FloorSemiring.tendsto_pow_div_factorial_atTop (Real.log x)).const_mul _
  have h3 := h1.mul h2
  rw [mul_zero, mul_zero] at h3
  have h4 : (fun k : ℕ => (k.factorial : ℝ) * x / Real.log x ^ (k + 1) *
      (Real.log x * (Real.log x ^ k / (k.factorial : ℝ)))) = fun _ => x := by
    funext k
    have hf : (k.factorial : ℝ) ≠ 0 := Nat.cast_ne_zero.mpr (Nat.factorial_ne_zero k)
    have hp : Real.log x ^ k ≠ 0 := pow_ne_zero _ hL.ne'
    field_simp
    ring
  rw [h4] at h3
  have := tendsto_nhds_unique tendsto_const_nhds h3
  linarith

-- The prime count at a thousand, from the card's table: π(1000) = 168.
example : Nat.primeCounting 1000 = 168 := by
  rw [Nat.primeCounting, Nat.primeCounting', Nat.count_eq_card_filter_range]
  decide +kernel
-- The sieve to ten million only needs primes up to 3,162, since 3,162² ≤ 10^7 < 3,163².
example : 3162 ^ 2 ≤ 10 ^ 7 ∧ 10 ^ 7 < 3163 ^ 2 := by norm_num
-- The expansion's coefficients 1, 1, 2!, 3!, 4!: the 2x/log³ x and 6x/log⁴ x of the predicted miss.
example : Nat.factorial 0 = 1 ∧ Nat.factorial 1 = 1 ∧ Nat.factorial 2 = 2 ∧
    Nat.factorial 3 = 6 ∧ Nat.factorial 4 = 24 := by decide

#print axioms offset_li_asymptotic_expansion
#print axioms integral_inv_log_pow_by_parts
#print axioms li_expansion_series_not_summable
