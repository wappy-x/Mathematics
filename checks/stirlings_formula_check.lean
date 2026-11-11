-- Stirling's formula: as the real number s grows, the gamma integral Γ(s + 1) divided by √(2πs) (s/e)^s tends to 1, the integrand t^s e^(-t) peaks at t = s with height (s/e)^s, the bell fitted there has area √(2πs) (s/e)^s, and the card's whole-number factorials 10!, 9! and 52! check out.
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Gamma.BohrMollerup
import Mathlib.Analysis.SpecialFunctions.Stirling
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum

open Real Filter Topology MeasureTheory

/-- Log-convexity bounds: for `n ≥ 1` and `0 ≤ x ≤ 1`, `log Γ(n + x + 1)` lies between
`log n! + x log n` and `log n! + x log (n + 1)`. -/
theorem stirling_aux_log_gamma_bounds (n : ℕ) (hn : 1 ≤ n) (x : ℝ) (hx0 : 0 ≤ x) (hx1 : x ≤ 1) :
    Real.log (n.factorial : ℝ) + x * Real.log n ≤ Real.log (Real.Gamma (n + x + 1)) ∧
      Real.log (Real.Gamma (n + x + 1)) ≤ Real.log (n.factorial : ℝ) + x * Real.log (n + 1) := by
  have hfeq : ∀ {y : ℝ}, 0 < y →
      (Real.log ∘ Real.Gamma) (y + 1) = (Real.log ∘ Real.Gamma) y + Real.log y := by
    intro y hy
    simp only [Function.comp_apply]
    rw [Real.Gamma_add_one hy.ne', Real.log_mul hy.ne' (Real.Gamma_pos_of_pos hy).ne', add_comm]
  have hm : ((n + 1 : ℕ) : ℝ) + x = n + x + 1 := by push_cast; ring
  have hfm : (Real.log ∘ Real.Gamma) ((n + 1 : ℕ) : ℝ) = Real.log (n.factorial : ℝ) := by
    simp only [Function.comp_apply]
    rw [Nat.cast_succ, Real.Gamma_nat_eq_factorial]
  rcases hx0.eq_or_lt with h0 | hxpos
  · subst h0
    have : ((n : ℝ) + 0 + 1) = ((n + 1 : ℕ) : ℝ) := by push_cast; ring
    rw [this, Nat.cast_succ, Real.Gamma_nat_eq_factorial]
    constructor <;> simp
  constructor
  · have := Real.BohrMollerup.f_add_nat_ge Real.convexOn_log_Gamma hfeq
      (n := n + 1) (by omega) hxpos
    rw [hm, hfm] at this
    have e : ((n + 1 : ℕ) : ℝ) - 1 = n := by push_cast; ring
    rw [e] at this
    simpa using this
  · have := Real.BohrMollerup.f_add_nat_le Real.convexOn_log_Gamma hfeq
      (n := n + 1) (by omega) hxpos hx1
    rw [hm, hfm] at this
    push_cast at this
    simpa using this

/-- The logarithm of the Stirling formula: for `t > 0`,
`log (√(2πt) (t/e)^t) = log (2πt) / 2 + t (log t - 1)`. -/
theorem stirling_aux_log_formula (t : ℝ) (ht : 0 < t) :
    Real.log (√(2 * π * t) * (t / exp 1) ^ t) = Real.log (2 * π * t) / 2 + t * (Real.log t - 1) := by
  have h2 : 0 < 2 * π * t := by positivity
  rw [Real.log_mul (Real.sqrt_pos.mpr h2).ne' (Real.rpow_pos_of_pos (by positivity) _).ne',
    Real.log_sqrt h2.le, Real.log_rpow (by positivity), Real.log_div ht.ne' (exp_pos 1).ne',
    Real.log_exp]

/-- Stirling's formula for whole numbers, in logarithms. -/
theorem stirling_aux_nat_log :
    Tendsto (fun n : ℕ => Real.log (n.factorial : ℝ) -
      (Real.log (2 * π * n) / 2 + n * (Real.log n - 1))) atTop (𝓝 0) := by
  have h1 : Tendsto (fun n : ℕ => Real.log (Stirling.stirlingSeq n)) atTop
      (𝓝 (Real.log (√π))) :=
    Stirling.tendsto_stirlingSeq_sqrt_pi.log (by positivity)
  have h2 := h1.sub_const (Real.log π / 2)
  rw [Real.log_sqrt pi_pos.le, sub_self] at h2
  refine h2.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  rw [Stirling.log_stirlingSeq_formula, Real.log_div hn'.ne' (exp_pos 1).ne', Real.log_exp,
    show (2 * π * n : ℝ) = π * (2 * n) by ring, Real.log_mul pi_pos.ne' (by positivity)]
  ring

/-- Stirling's formula for real s. The factorial of s, Γ(s + 1), is about √(2πs) times (s/e)
to the s, in ratio: as s grows without bound through the real numbers (whole or not), the truth
Γ(s + 1) divided by the formula √(2πs) (s/e)^s heads for 1. -/
theorem gamma_succ_div_stirling_tendsto_one :
    Tendsto (fun s : ℝ => Real.Gamma (s + 1) / (√(2 * π * s) * (s / exp 1) ^ s))
      atTop (𝓝 1) := by
  set d : ℕ → ℝ := fun n => Real.log (n.factorial : ℝ) -
      (Real.log (2 * π * n) / 2 + n * (Real.log n - 1)) with hd
  have hdlim : Tendsto d atTop (𝓝 0) := stirling_aux_nat_log
  have hlolim : Tendsto (fun n : ℕ => d n - (Real.log (n + 1) - Real.log n) / 2 - 1 / (n : ℝ))
      atTop (𝓝 0) := by
    have := (hdlim.sub (tendsto_log_nat_add_one_sub_log.div_const 2)).sub
      tendsto_one_div_atTop_nhds_zero_nat
    simpa using this
  have hhilim : Tendsto (fun n : ℕ => d n + (Real.log (n + 1) - Real.log n)) atTop (𝓝 0) := by
    have := hdlim.add tendsto_log_nat_add_one_sub_log
    simpa using this
  have hfl : Tendsto (fun s : ℝ => ⌊s⌋₊) atTop atTop := tendsto_nat_floor_atTop
  -- the log of the ratio tends to 0
  have hlog : Tendsto (fun s : ℝ => Real.log (Real.Gamma (s + 1)) -
      (Real.log (2 * π * s) / 2 + s * (Real.log s - 1))) atTop (𝓝 0) := by
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' (hlolim.comp hfl) (hhilim.comp hfl) ?_ ?_
    all_goals
      filter_upwards [eventually_ge_atTop 1] with s hs
      simp only [Function.comp_apply, hd]
      have hs0 : 0 < s := by linarith
      have hn1 : 1 ≤ ⌊s⌋₊ := Nat.one_le_floor_iff s |>.mpr hs
      set n := ⌊s⌋₊ with hn
      have hns : (n : ℝ) ≤ s := Nat.floor_le hs0.le
      have hsn : s < n + 1 := Nat.lt_floor_add_one s
      have hn0 : (0 : ℝ) < n := by exact_mod_cast hn1
      set x := s - n with hx
      have hb := stirling_aux_log_gamma_bounds n hn1 x (by linarith) (by linarith)
      rw [show (n : ℝ) + x + 1 = s + 1 by rw [hx]; ring] at hb
      have hl2s : Real.log (2 * π * s) = Real.log (2 * π) + Real.log s :=
        Real.log_mul (by positivity) hs0.ne'
      have hl2n : Real.log (2 * π * n) = Real.log (2 * π) + Real.log n :=
        Real.log_mul (by positivity) hn0.ne'
      rw [hl2s, hl2n]
      -- K1: s (log n - log s) ≤ n - s
      have K1 : s * (Real.log n - Real.log s) ≤ n - s := by
        have h1 := Real.log_le_sub_one_of_pos (div_pos hn0 hs0)
        rw [Real.log_div hn0.ne' hs0.ne'] at h1
        have h2 := mul_le_mul_of_nonneg_left h1 hs0.le
        have h3 : s * ((n : ℝ) / s - 1) = n - s := by field_simp
        linarith
      -- K2: s (log s - log n) ≤ x + 1/n
      have K2 : s * (Real.log s - Real.log n) ≤ x + 1 / n := by
        have h1 := Real.log_le_sub_one_of_pos (div_pos hs0 hn0)
        rw [Real.log_div hs0.ne' hn0.ne'] at h1
        have h2 := mul_le_mul_of_nonneg_left h1 hs0.le
        have h3 : s * (s / (n : ℝ) - 1) = x + x ^ 2 / n := by rw [hx]; field_simp; ring
        have h4 : x ^ 2 / (n : ℝ) ≤ 1 / n := by
          apply div_le_div_of_nonneg_right _ hn0.le
          nlinarith
        linarith
      have K3 : Real.log n ≤ Real.log s := Real.log_le_log hn0 hns
      have K4 : Real.log s ≤ Real.log (n + 1) := Real.log_le_log hs0 hsn.le
      have K5 : x * (Real.log (n + 1) - Real.log n) ≤ Real.log (n + 1) - Real.log n := by
        have : Real.log n ≤ Real.log (n + 1) := Real.log_le_log hn0 (by linarith)
        nlinarith
      have K6 : x * Real.log n = s * Real.log n - n * Real.log n := by rw [hx]; ring
      linarith [hb.1, hb.2]
  have hexp := (Real.continuous_exp.tendsto 0).comp hlog
  rw [Real.exp_zero] at hexp
  refine hexp.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with s hs
  simp only [Function.comp_apply]
  rw [← stirling_aux_log_formula s hs, ← Real.log_div (Real.Gamma_pos_of_pos (by linarith)).ne'
    (by positivity), Real.exp_log (div_pos (Real.Gamma_pos_of_pos (by linarith)) (by positivity))]

/-- Step 1, the peak. For s > 0 the integrand t^s e^(-t) of the gamma integral, over t > 0,
is highest at t = s, and its height there, s^s e^(-s), is (s/e)^s. -/
theorem gamma_integrand_peak (s : ℝ) (hs : 0 < s) :
    IsMaxOn (fun t : ℝ => t ^ s * exp (-t)) (Set.Ioi 0) s ∧
      s ^ s * exp (-s) = (s / exp 1) ^ s := by
  refine ⟨fun t ht => ?_, ?_⟩
  · have ht : 0 < t := ht
    show t ^ s * exp (-t) ≤ s ^ s * exp (-s)
    rw [rpow_def_of_pos ht, rpow_def_of_pos hs, ← exp_add, ← exp_add]
    apply exp_le_exp.mpr
    have h1 := log_le_sub_one_of_pos (div_pos ht hs)
    rw [log_div ht.ne' hs.ne'] at h1
    have h2 : s * (log t - log s) ≤ s * (t / s - 1) := mul_le_mul_of_nonneg_left h1 hs.le
    have h3 : s * (t / s - 1) = t - s := by field_simp
    nlinarith
  · rw [div_rpow hs.le (exp_pos 1).le, exp_one_rpow, div_eq_mul_inv, exp_neg]

/-- Step 3, the bell's area. For s > 0 the bell with the peak's height (s/e)^s and width √s,
(s/e)^s e^(-(t - s)^2/(2s)), has area √(2πs) times (s/e)^s over the whole real line. -/
theorem stirling_bell_area (s : ℝ) (hs : 0 < s) :
    ∫ t : ℝ, (s / exp 1) ^ s * exp (-(t - s) ^ 2 / (2 * s)) = √(2 * π * s) * (s / exp 1) ^ s := by
  rw [integral_const_mul, mul_comm]
  congr 1
  have := integral_sub_right_eq_self (μ := volume) (fun t : ℝ => exp (-t ^ 2 / (2 * s))) s
  rw [this]
  have h : (fun t : ℝ => exp (-t ^ 2 / (2 * s))) = fun t => exp (-(1 / (2 * s)) * t ^ 2) := by
    funext t; congr 1; ring
  rw [h, integral_gaussian]
  congr 1
  field_simp

-- 10 cards: 3,628,800 orders.
example : Nat.factorial 10 = 3628800 := by norm_num [Nat.factorial]
-- The shift-by-one mistake reads the formula as Γ(10) = 9! = 362880.
example : Nat.factorial 9 = 362880 := by norm_num [Nat.factorial]
-- 52 cards: 52! rounds to 8.065818 × 10^67 at the card's seven figures.
example : 80658175 * 10 ^ 60 ≤ Nat.factorial 52 ∧ Nat.factorial 52 < 80658185 * 10 ^ 60 := by
  decide

#print axioms stirling_aux_log_gamma_bounds
#print axioms stirling_aux_log_formula
#print axioms stirling_aux_nat_log
#print axioms gamma_succ_div_stirling_tendsto_one
#print axioms gamma_integrand_peak
#print axioms stirling_bell_area
