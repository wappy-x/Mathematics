-- Any payoff from a strip of options: every payoff with a continuous curvature on positive prices equals, at every finishing price, its value at the forward plus its slope times a forward plus puts below and calls above weighted by its curvature, the log payoff takes weights minus 100 over strike squared, and the log contract's dollar gamma is flat.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- Helper: `a (ln(y/100) + c)` has slope `a / x` at a positive price `x`. -/
lemma log_div_hundred_hasDerivAt (a c : ℝ) {x : ℝ} (hx : 0 < x) :
    HasDerivAt (fun y : ℝ => a * (Real.log (y / 100) + c)) (a / x) x := by
  have h := ((((hasDerivAt_id' (x := x)).div_const 100).log
    (by positivity)).add_const c).const_mul a
  convert h using 1
  field_simp

/-- Helper: the slope of `a (ln(y/100) + c)` at a positive price `x` is `a / x`. -/
lemma log_div_hundred_deriv (a c : ℝ) {x : ℝ} (hx : 0 < x) :
    deriv (fun y : ℝ => a * (Real.log (y / 100) + c)) x = a / x :=
  (log_div_hundred_hasDerivAt a c hx).deriv

/-- Helper: the curvature of `a (ln(y/100) + c)` at a positive price `x` is `-a / x^2`. -/
lemma log_div_hundred_deriv_deriv (a c : ℝ) {x : ℝ} (hx : 0 < x) :
    deriv (deriv (fun y : ℝ => a * (Real.log (y / 100) + c))) x = -a / x ^ 2 := by
  have heq : deriv (fun y : ℝ => a * (Real.log (y / 100) + c)) =ᶠ[nhds x]
      fun y => a * y⁻¹ := by
    filter_upwards [Ioi_mem_nhds hx] with y hy
    rw [log_div_hundred_deriv a c hy, div_eq_mul_inv]
  rw [heq.deriv_eq, ((hasDerivAt_inv hx.ne').const_mul a).deriv]
  field_simp

/-- The card's main claim, the spanning identity (Steps 1 and 2, pathwise). Let the payoff `g`
have a continuous curvature on the positive prices, and let the forward `F` and the finishing
price `S` be positive. Then `g S` equals cash `g F`, plus the slope `g' F` times a forward
position `S - F`, plus puts at every strike `K` from 0 to `F` held in the amount `g'' K`, plus
calls at every strike from `F` to infinity held in the amount `g'' K`. -/
theorem payoff_eq_cash_add_forward_add_curvature_weighted_strip
    (g : ℝ → ℝ) (hg : ContDiffOn ℝ 2 g (Set.Ioi 0)) (F S : ℝ) (hF : 0 < F) (hS : 0 < S) :
    g S = g F + deriv g F * (S - F)
      + (∫ K in (0 : ℝ)..F, deriv (deriv g) K * max (K - S) 0)
      + ∫ K in Set.Ioi F, deriv (deriv g) K * max (S - K) 0 := by
  have hopen : IsOpen (Set.Ioi (0 : ℝ)) := isOpen_Ioi
  have hd1 : ∀ x : ℝ, 0 < x → HasDerivAt g (deriv g x) x := fun x hx =>
    ((hg.differentiableOn (by norm_num)).differentiableAt (Ioi_mem_nhds hx)).hasDerivAt
  have hg1 : ContDiffOn ℝ 1 (deriv g) (Set.Ioi 0) := hg.deriv_of_isOpen hopen (by norm_num)
  have hd2 : ∀ x : ℝ, 0 < x → HasDerivAt (deriv g) (deriv (deriv g) x) x := fun x hx =>
    ((hg1.differentiableOn (by norm_num)).differentiableAt (Ioi_mem_nhds hx)).hasDerivAt
  have hc2 : ContinuousOn (deriv (deriv g)) (Set.Ioi 0) :=
    hg1.continuousOn_deriv_of_isOpen hopen (by norm_num)
  rcases le_or_gt S F with hSF | hFS
  · have hcall : (∫ K in Set.Ioi F, deriv (deriv g) K * max (S - K) 0) = 0 := by
      rw [setIntegral_congr_fun measurableSet_Ioi (g := fun _ => (0 : ℝ))]
      · simp
      · intro K hK
        simp only [Set.mem_Ioi] at hK
        simp [max_eq_right (by linarith : S - K ≤ 0)]
    have hput : (∫ K in (0 : ℝ)..F, deriv (deriv g) K * max (K - S) 0)
        = ∫ K in S..F, deriv (deriv g) K * (K - S) := by
      rw [intervalIntegral.integral_of_le hF.le, intervalIntegral.integral_of_le hSF]
      rw [setIntegral_congr_fun measurableSet_Ioc
        (g := (Set.Ioi S).indicator (fun K => deriv (deriv g) K * (K - S)))]
      · rw [setIntegral_indicator measurableSet_Ioi, Set.Ioc_inter_Ioi, max_eq_right hS.le]
      · intro K _
        by_cases h : S < K
        · simp [Set.indicator, h, max_eq_left (by linarith : 0 ≤ K - S)]
        · simp [Set.indicator, h, max_eq_right (by linarith : K - S ≤ 0)]
    have hftc : ∫ K in S..F, deriv (deriv g) K * (K - S)
        = (deriv g F * (F - S) - g F) - (deriv g S * (S - S) - g S) := by
      refine intervalIntegral.integral_eq_sub_of_hasDerivAt
        (f := fun x => deriv g x * (x - S) - g x) ?_ ?_
      · intro x hx
        rw [Set.uIcc_of_le hSF] at hx
        have hx0 : 0 < x := lt_of_lt_of_le hS hx.1
        have := ((hd2 x hx0).mul ((hasDerivAt_id x).sub_const S)).sub (hd1 x hx0)
        convert this using 1
        · rfl
        · simp only [id]
          ring
      · apply ContinuousOn.intervalIntegrable
        rw [Set.uIcc_of_le hSF]
        apply ContinuousOn.mul
        · exact hc2.mono (fun x hx => lt_of_lt_of_le hS hx.1)
        · exact (continuous_id.sub continuous_const).continuousOn
    rw [hcall, hput, hftc]
    ring
  · have hput : (∫ K in (0 : ℝ)..F, deriv (deriv g) K * max (K - S) 0) = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ))]
      · simp
      · intro K hK
        rw [Set.uIcc_of_le hF.le] at hK
        simp [max_eq_right (by linarith [hK.2] : K - S ≤ 0)]
    have hcall : (∫ K in Set.Ioi F, deriv (deriv g) K * max (S - K) 0)
        = ∫ K in F..S, deriv (deriv g) K * (S - K) := by
      rw [intervalIntegral.integral_of_le hFS.le]
      rw [setIntegral_congr_fun measurableSet_Ioi
        (g := (Set.Iic S).indicator (fun K => deriv (deriv g) K * (S - K)))]
      · rw [setIntegral_indicator measurableSet_Iic, Set.Ioi_inter_Iic]
      · intro K _
        by_cases h : K ≤ S
        · simp [Set.indicator, h]
        · simp [Set.indicator, h, max_eq_right (by linarith : S - K ≤ 0)]
    have hftc : ∫ K in F..S, deriv (deriv g) K * (S - K)
        = (deriv g S * (S - S) + g S) - (deriv g F * (S - F) + g F) := by
      refine intervalIntegral.integral_eq_sub_of_hasDerivAt
        (f := fun x => deriv g x * (S - x) + g x) ?_ ?_
      · intro x hx
        rw [Set.uIcc_of_le hFS.le] at hx
        have hx0 : 0 < x := lt_of_lt_of_le hF hx.1
        have := ((hd2 x hx0).mul ((hasDerivAt_id x).const_sub S)).add (hd1 x hx0)
        convert this using 1
        · rfl
        · simp only [id]
          ring
      · apply ContinuousOn.intervalIntegrable
        rw [Set.uIcc_of_le hFS.le]
        apply ContinuousOn.mul
        · exact hc2.mono (fun x hx => lt_of_lt_of_le hF hx.1)
        · exact (continuous_const.sub continuous_id).continuousOn
    rw [hcall, hput, hftc]
    ring

/-- Step 4: the log contract, paying `100 ln(S/100)`, is the case with curvature `-100/K^2`.
At every positive finishing price `S` it equals cash `100 ln(F/100)`, plus `100/F` forwards,
minus `100/K^2` of the put at each strike `K` below the forward, minus `100/K^2` of the call at
each strike above it: the options are sold, with weight one over strike squared. -/
theorem log_contract_eq_cash_add_forward_sub_inverse_square_strip
    (F S : ℝ) (hF : 0 < F) (hS : 0 < S) :
    100 * Real.log (S / 100) = 100 * Real.log (F / 100) + 100 / F * (S - F)
      - (∫ K in (0 : ℝ)..F, 100 / K ^ 2 * max (K - S) 0)
      - ∫ K in Set.Ioi F, 100 / K ^ 2 * max (S - K) 0 := by
  have hcd : ContDiffOn ℝ 2 (fun y : ℝ => 100 * (Real.log (y / 100) + 0)) (Set.Ioi 0) := by
    apply ContDiffOn.mul contDiffOn_const
    apply ContDiffOn.add _ contDiffOn_const
    apply ContDiffOn.log (contDiffOn_id.div_const 100)
    intro x hx
    simp only [Set.mem_Ioi] at hx
    simp only [id]
    positivity
  have key := payoff_eq_cash_add_forward_add_curvature_weighted_strip _ hcd F S hF hS
  have h1 : (∫ K in (0 : ℝ)..F,
      deriv (deriv (fun y : ℝ => 100 * (Real.log (y / 100) + 0))) K * max (K - S) 0)
      = -∫ K in (0 : ℝ)..F, 100 / K ^ 2 * max (K - S) 0 := by
    rw [← intervalIntegral.integral_neg]
    apply intervalIntegral.integral_congr_ae
    refine Filter.Eventually.of_forall (fun K hK => ?_)
    rw [Set.uIoc_of_le hF.le] at hK
    rw [log_div_hundred_deriv_deriv 100 0 hK.1]
    ring
  have h2 : (∫ K in Set.Ioi F,
      deriv (deriv (fun y : ℝ => 100 * (Real.log (y / 100) + 0))) K * max (S - K) 0)
      = -∫ K in Set.Ioi F, 100 / K ^ 2 * max (S - K) 0 := by
    rw [← integral_neg]
    apply setIntegral_congr_fun measurableSet_Ioi
    intro K hK
    simp only [Set.mem_Ioi] at hK
    dsimp only
    rw [log_div_hundred_deriv_deriv 100 0 (hF.trans hK)]
    ring
  rw [h1, h2, log_div_hundred_deriv 100 0 hF] at key
  rw [show 100 * Real.log (S / 100) = 100 * (Real.log (S / 100) + 0) by ring, key]
  ring

/-- Step 5: today's price of the log contract in the house model is
`100 D (ln(S/100) + c)` with `c = (r - q - σ²/2) T`. Its gamma times `S^2`, the dollar gamma,
is `-100 D` at every positive share price `S`: it does not depend on `S`. -/
theorem log_contract_dollar_gamma_is_flat (D c S : ℝ) (hS : 0 < S) :
    S ^ 2 * deriv (deriv (fun x : ℝ => 100 * D * (Real.log (x / 100) + c))) S = -100 * D := by
  rw [log_div_hundred_deriv_deriv (100 * D) c hS]
  field_simp

-- Step 4, strikes 30 apart: the book sells 100 × 30 / 90² = 10/27 (0.370370) of the 90-put
example : (100 * 30 : ℚ) / 90 ^ 2 = 10 / 27 := by norm_num
-- and 100 × 30 / 120² = 5/24 (0.208333) of the 120-call.
example : (100 * 30 : ℚ) / 120 ^ 2 = 5 / 24 := by norm_num
-- The put counts nearly twice as much as the call: (10/27) / (5/24) = 16/9, about 1.78.
example : ((10 : ℚ) / 27) / (5 / 24) = 16 / 9 := by norm_num
-- The square payoff (S_T - 100)² has curvature 2, so with strikes 30 apart it holds 60 of each.
example : (2 : ℤ) * 30 = 60 := by decide

#print axioms log_div_hundred_hasDerivAt
#print axioms log_div_hundred_deriv
#print axioms log_div_hundred_deriv_deriv
#print axioms payoff_eq_cash_add_forward_add_curvature_weighted_strip
#print axioms log_contract_eq_cash_add_forward_sub_inverse_square_strip
#print axioms log_contract_dollar_gamma_is_flat
