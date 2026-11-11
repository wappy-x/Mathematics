-- Stirling's approximation: n! divided by √(2πn)·(n/e)^n tends to 1, at every n ≥ 1 the true n! is that estimate times e^θ with 0 < θ < 1/(12n), and Wallis's factorial products pin π/2 between P_m and P_m·(2m+1)/(2m).
import Mathlib.Analysis.SpecialFunctions.Stirling
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open Real Filter Topology Nat

lemma stirling_aux_eq (n : ℕ) :
    (n ! : ℝ) / (√(2 * π * n) * ((n : ℝ) / exp 1) ^ n) = Stirling.stirlingSeq n / √π := by
  unfold Stirling.stirlingSeq
  rw [div_div, show (2 * π * n : ℝ) = π * (2 * n) by ring,
    Real.sqrt_mul (by positivity)]
  ring

/-- Telescoped Robbins bound. -/
lemma stirling_aux_tele (n : ℕ) (hn : 1 ≤ n) (k : ℕ) :
    Real.log (Stirling.stirlingSeq n) - Real.log (Stirling.stirlingSeq (n + k))
      ≤ 1 / (12 * n) - 1 / (12 * (n + k)) := by
  induction k with
  | zero => simp
  | succ k ih =>
    have h := Stirling.log_stirlingSeq_sdiff_le (n + k)
    have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
    have hk : (0 : ℝ) ≤ k := by positivity
    calc Real.log (Stirling.stirlingSeq n) - Real.log (Stirling.stirlingSeq (n + (k + 1)))
        = (Real.log (Stirling.stirlingSeq n) - Real.log (Stirling.stirlingSeq (n + k)))
          + (Real.log (Stirling.stirlingSeq (n + k))
            - Real.log (Stirling.stirlingSeq (n + k + 1))) := by
          rw [← add_assoc]; ring
      _ ≤ (1 / (12 * n) - 1 / (12 * (n + k)))
          + 1 / (12 * ((n + k : ℕ) : ℝ) * (((n + k : ℕ) : ℝ) + 1)) := add_le_add ih h
      _ = _ := by
          have : (0 : ℝ) < n + k := by linarith
          push_cast
          field_simp
          ring

lemma stirling_aux_upper (n : ℕ) (hn : 1 ≤ n) :
    Real.log (Stirling.stirlingSeq n) - Real.log √π ≤ 1 / (12 * n) := by
  have hlim : Tendsto (fun k : ℕ => Real.log (Stirling.stirlingSeq n)
      - Real.log (Stirling.stirlingSeq (n + k))) atTop
      (𝓝 (Real.log (Stirling.stirlingSeq n) - Real.log √π)) := by
    refine tendsto_const_nhds.sub ?_
    have h1 : Tendsto (fun k : ℕ => Stirling.stirlingSeq (n + k)) atTop (𝓝 √π) := by
      have := Stirling.tendsto_stirlingSeq_sqrt_pi.comp (tendsto_add_atTop_nat n)
      simpa [Function.comp_def, add_comm] using this
    exact (Real.continuousAt_log (by positivity)).tendsto.comp h1
  refine le_of_tendsto hlim (Eventually.of_forall fun k => ?_)
  have := stirling_aux_tele n hn k
  have : 0 ≤ 1 / (12 * ((n : ℝ) + k)) := by positivity
  linarith

lemma stirling_aux_step (m : ℕ) :
    0 < Real.log (Stirling.stirlingSeq (m + 1)) - Real.log (Stirling.stirlingSeq (m + 2)) ∧
    Real.log (Stirling.stirlingSeq (m + 1)) - Real.log (Stirling.stirlingSeq (m + 2))
      < 1 / (12 * ((m + 1 : ℕ) : ℝ) * (((m + 1 : ℕ) : ℝ) + 1)) := by
  have hs := Stirling.log_stirlingSeq_sdiff_hasSum m
  set r : ℝ := ((1 : ℝ) / (2 * ((m + 1 : ℕ) : ℝ) + 1)) ^ 2 with hr
  have hr0 : 0 < r := by positivity
  have hr1 : r < 1 := by
    rw [hr]; push_cast
    rw [div_pow, one_pow, div_lt_one (by positivity)]
    have : (0 : ℝ) ≤ m := by positivity
    nlinarith
  constructor
  · refine hasSum_lt (f := fun _ => (0 : ℝ)) (i := 0) (fun k => by positivity) ?_ hasSum_zero hs
    positivity
  · have hg : HasSum (fun j : ℕ ↦ r ^ (j + 1) / 3)
        ((1 : ℝ) / (12 * ((m + 1 : ℕ) : ℝ) * (((m + 1 : ℕ) : ℝ) + 1))) := by
      have := ((hasSum_geometric_of_lt_one hr0.le hr1).mul_right r).div_const 3
      convert this using 1
      · ext j; ring
      · have hm0 : (0 : ℝ) ≤ m := by positivity
        have h1r : (1 : ℝ) - r = 4 * (m + 1) * (m + 2) / (2 * m + 3) ^ 2 := by
          rw [hr]; push_cast; field_simp; ring
        rw [h1r, hr]; push_cast; field_simp; ring
    refine hasSum_lt (i := 1) (fun j => ?_) ?_ hs hg
    · simp only
      rw [div_eq_mul_one_div (r ^ (j+1)) 3, mul_comm]
      gcongr
      have : (0:ℝ) ≤ j := by positivity
      push_cast
      linarith
    · have : 0 < r ^ 2 := by positivity
      norm_num
      linarith

#print axioms stirling_aux_eq
#print axioms stirling_aux_tele
#print axioms stirling_aux_upper
#print axioms stirling_aux_step

/-- **Stirling's approximation.** The factorial of n is, in ratio, the square root of 2πn times
n over e to the nth power: the ratio n! / (√(2πn)·(n/e)^n) heads for 1 as n grows. -/
theorem factorial_div_stirling_tendsto_one :
    Tendsto (fun n : ℕ => (n ! : ℝ) / (√(2 * π * n) * ((n : ℝ) / exp 1) ^ n)) atTop (𝓝 1) := by
  simp_rw [stirling_aux_eq]
  have h : √π ≠ 0 := by positivity
  simpa [div_self h] using Stirling.tendsto_stirlingSeq_sqrt_pi.div_const √π

/-- **The sharper statement, true from n = 1 up.** For every positive whole number n,
n! = √(2πn)·(n/e)^n·e^θ for some repair exponent θ with 0 < θ < 1/(12n): the estimate is
always a little low, and the factor that repairs it lies strictly between 1 and e^(1/(12n)). -/
theorem factorial_eq_stirling_mul_exp_theta (n : ℕ) (hn : 1 ≤ n) :
    ∃ θ : ℝ, 0 < θ ∧ θ < 1 / (12 * n) ∧
      (n ! : ℝ) = √(2 * π * n) * ((n : ℝ) / exp 1) ^ n * exp θ := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have hspos := Stirling.stirlingSeq'_pos m
  refine ⟨Real.log (Stirling.stirlingSeq (m + 1)) - Real.log √π, ?_, ?_, ?_⟩
  · obtain ⟨h1, -⟩ := stirling_aux_step m
    have h2 := Real.log_le_log (by positivity)
      (Stirling.sqrt_pi_le_stirlingSeq (n := m + 2) (by omega))
    linarith
  · obtain ⟨-, h1⟩ := stirling_aux_step m
    have h2 := stirling_aux_upper (m + 2) (by omega)
    have e : 1 / (12 * ((m + 1 : ℕ) : ℝ) * (((m + 1 : ℕ) : ℝ) + 1)) + 1 / (12 * ((m + 2 : ℕ) : ℝ))
        = 1 / (12 * ((m + 1 : ℕ) : ℝ)) := by
      push_cast; field_simp; ring
    linarith
  · have hpi : 0 < √π := by positivity
    rw [Real.exp_sub, Real.exp_log hspos, Real.exp_log hpi]
    have := stirling_aux_eq (m + 1)
    have hd : 0 < √(2 * π * ((m + 1 : ℕ) : ℝ)) * (((m + 1 : ℕ) : ℝ) / exp 1) ^ (m + 1) := by
      positivity
    rw [← this]
    field_simp

/-- **Wallis's bracket (Step 3).** For every positive whole number m, with
P_m = 2^(4m)·(m!)^4 / (((2m)!)^2·(2m+1)), the number π/2 lies between P_m and
P_m·(2m+1)/(2m). -/
theorem wallis_bracket_pi_div_two (m : ℕ) (hm : 1 ≤ m) :
    (2 : ℝ) ^ (4 * m) * (m ! : ℝ) ^ 4 / (((2 * m) ! : ℝ) ^ 2 * (2 * m + 1)) ≤ π / 2 ∧
      π / 2 ≤ (2 : ℝ) ^ (4 * m) * (m ! : ℝ) ^ 4 / (((2 * m) ! : ℝ) ^ 2 * (2 * m + 1)) *
        ((2 * m + 1) / (2 * m)) := by
  rw [← Real.Wallis.W_eq_factorial_ratio]
  refine ⟨Real.Wallis.W_le m, ?_⟩
  have h := Real.Wallis.le_W m
  have hm' : (1 : ℝ) ≤ m := by exact_mod_cast hm
  have hW := Real.Wallis.W_pos m
  have hpi := Real.pi_pos
  rw [div_mul_eq_mul_div, div_le_iff₀ (by positivity)] at h
  rw [mul_div_assoc', le_div_iff₀ (by positivity)]
  nlinarith

-- Twenty runners finish in 20! orders: 20 × 19 × … × 1 = 2432902008176640000.
example : (20 : ℕ)! = 2432902008176640000 := by decide
-- The repair exponent at n = 20 lies below 1/(12 × 20) = 1/240.
example : (12 : ℕ) * 20 = 240 := by norm_num

#print axioms factorial_div_stirling_tendsto_one
#print axioms factorial_eq_stirling_mul_exp_theta
#print axioms wallis_bracket_pi_div_two
