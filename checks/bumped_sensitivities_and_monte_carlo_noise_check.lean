-- Bumping a simulated price: the best bump balances bias against noise, so the error of a bumped delta falls like n^(-1/3) with fresh draws, n^(-2/5) for a jumping payoff with shared draws, and n^(-1/2) for a call with shared draws, whose noise shared draws cap.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Order.Filter.Extr

open Set

/-- The three error rates of a bumped Monte Carlo delta. Write `β₃ = V'''/6` for the bias
constant, so the bias squared is `β₃² h⁴`, and let `n` be the number of paths per price.

* Fresh draws: one path's variance is `c / h²`, the mean-square error is
  `β₃² h⁴ + c / (n h²)`, its best bump is `h* = (c / (2 β₃² n))^(1/6)`, and the smallest
  mean-square error is `3 (β₃²)^(1/3) (c/2)^(2/3) n^(-2/3)`, so the error falls like `n^(-1/3)`.
* Shared draws on a payoff that jumps: one path's variance is `c / h`, the mean-square error
  is `β₃² h⁴ + c / (n h)`, its best bump is `h* = (c / (4 β₃² n))^(1/5)`, and the smallest
  mean-square error is `5 (β₃²)^(1/5) (c/4)^(4/5) n^(-4/5)`, so the error falls like `n^(-2/5)`.
* Shared draws on a payoff with no jump: one path's variance `v(h)` stays below a bound `V`,
  and any bump with `h² ≤ n^(-1/2)` gives a mean-square error at most `(β₃² + V) / n`,
  so the error falls like `n^(-1/2)`. -/
theorem bumped_delta_error_rates (β₃ c n : ℝ) (hβ : β₃ ≠ 0) (hc : 0 < c) (hn : 0 < n) :
    (IsMinOn (fun h : ℝ => β₃ ^ 2 * h ^ 4 + c / (n * h ^ 2)) (Ioi 0)
        ((c / (2 * β₃ ^ 2 * n)) ^ (1 / 6 : ℝ)) ∧
      β₃ ^ 2 * ((c / (2 * β₃ ^ 2 * n)) ^ (1 / 6 : ℝ)) ^ 4
          + c / (n * ((c / (2 * β₃ ^ 2 * n)) ^ (1 / 6 : ℝ)) ^ 2)
        = 3 * (β₃ ^ 2) ^ (1 / 3 : ℝ) * (c / 2) ^ (2 / 3 : ℝ) * n ^ (-(2 / 3) : ℝ)) ∧
    (IsMinOn (fun h : ℝ => β₃ ^ 2 * h ^ 4 + c / (n * h)) (Ioi 0)
        ((c / (4 * β₃ ^ 2 * n)) ^ (1 / 5 : ℝ)) ∧
      β₃ ^ 2 * ((c / (4 * β₃ ^ 2 * n)) ^ (1 / 5 : ℝ)) ^ 4
          + c / (n * (c / (4 * β₃ ^ 2 * n)) ^ (1 / 5 : ℝ))
        = 5 * (β₃ ^ 2) ^ (1 / 5 : ℝ) * (c / 4) ^ (4 / 5 : ℝ) * n ^ (-(4 / 5) : ℝ)) ∧
    (∀ (v : ℝ → ℝ) (V : ℝ), (∀ h, 0 < h → v h ≤ V) →
      ∀ h : ℝ, 0 < h → h ^ 2 ≤ n ^ (-(1 / 2) : ℝ) →
        β₃ ^ 2 * h ^ 4 + v h / n ≤ (β₃ ^ 2 + V) / n) := by
  have ha : 0 < β₃ ^ 2 := by positivity
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩, ?_⟩
  · set x := c / (2 * β₃ ^ 2 * n) with hxdef
    have hx : 0 < x := by positivity
    set s := x ^ (1 / 6 : ℝ) with hsdef
    have hs : 0 < s := Real.rpow_pos_of_pos hx _
    have hs6 : s ^ 6 = x := by
      rw [hsdef, show (1 / 6 : ℝ) = ((6 : ℕ) : ℝ)⁻¹ by norm_num]
      exact Real.rpow_inv_natCast_pow hx.le (by norm_num)
    have hcx : c = 2 * β₃ ^ 2 * n * s ^ 6 := by
      rw [hs6, hxdef]; field_simp
    intro h hh
    simp only [mem_ofPred_eq, mem_Ioi] at hh ⊢
    rw [← sub_nonneg]
    have key : β₃ ^ 2 * h ^ 4 + c / (n * h ^ 2) - (β₃ ^ 2 * s ^ 4 + c / (n * s ^ 2))
        = β₃ ^ 2 * (h ^ 2 - s ^ 2) ^ 2 * (h ^ 2 + 2 * s ^ 2) / h ^ 2 := by
      rw [hcx]; field_simp; ring
    rw [key]; positivity
  · set x := c / (2 * β₃ ^ 2 * n) with hxdef
    have hx : 0 < x := by positivity
    set s := x ^ (1 / 6 : ℝ) with hsdef
    have hs : 0 < s := Real.rpow_pos_of_pos hx _
    have hs6 : s ^ 6 = x := by
      rw [hsdef, show (1 / 6 : ℝ) = ((6 : ℕ) : ℝ)⁻¹ by norm_num]
      exact Real.rpow_inv_natCast_pow hx.le (by norm_num)
    have hcx : c = 2 * β₃ ^ 2 * n * s ^ 6 := by
      rw [hs6, hxdef]; field_simp
    have hs4 : s ^ 4 = x ^ (2 / 3 : ℝ) := by
      rw [hsdef, ← Real.rpow_natCast, ← Real.rpow_mul hx.le]; norm_num
    have h1 : (β₃ ^ 2) ^ (1 / 3 : ℝ) * (β₃ ^ 2) ^ (2 / 3 : ℝ) = β₃ ^ 2 := by
      rw [← Real.rpow_add ha]; norm_num
    have h2 : n ^ (2 / 3 : ℝ) * n ^ (-(2 / 3) : ℝ) = 1 := by
      rw [← Real.rpow_add hn]; norm_num
    have hc2 : c / 2 = x * (β₃ ^ 2 * n) := by rw [hxdef]; field_simp
    calc β₃ ^ 2 * s ^ 4 + c / (n * s ^ 2) = 3 * β₃ ^ 2 * s ^ 4 := by
          rw [hcx]; field_simp; ring
      _ = 3 * (β₃ ^ 2) ^ (1 / 3 : ℝ) * (c / 2) ^ (2 / 3 : ℝ) * n ^ (-(2 / 3) : ℝ) := by
          rw [hc2, Real.mul_rpow hx.le (by positivity), Real.mul_rpow ha.le hn.le, ← hs4]
          linear_combination (-3 * s ^ 4) * h1
            - 3 * s ^ 4 * (β₃ ^ 2) ^ (1 / 3 : ℝ) * (β₃ ^ 2) ^ (2 / 3 : ℝ) * h2
  · set x := c / (4 * β₃ ^ 2 * n) with hxdef
    have hx : 0 < x := by positivity
    set s := x ^ (1 / 5 : ℝ) with hsdef
    have hs : 0 < s := Real.rpow_pos_of_pos hx _
    have hs5 : s ^ 5 = x := by
      rw [hsdef, show (1 / 5 : ℝ) = ((5 : ℕ) : ℝ)⁻¹ by norm_num]
      exact Real.rpow_inv_natCast_pow hx.le (by norm_num)
    have hcx : c = 4 * β₃ ^ 2 * n * s ^ 5 := by
      rw [hs5, hxdef]; field_simp
    intro h hh
    simp only [mem_ofPred_eq, mem_Ioi] at hh ⊢
    rw [← sub_nonneg]
    have key : β₃ ^ 2 * h ^ 4 + c / (n * h) - (β₃ ^ 2 * s ^ 4 + c / (n * s))
        = β₃ ^ 2 * (h - s) ^ 2 * (h ^ 3 + 2 * h ^ 2 * s + 3 * h * s ^ 2 + 4 * s ^ 3) / h := by
      rw [hcx]; field_simp; ring
    rw [key]; positivity
  · set x := c / (4 * β₃ ^ 2 * n) with hxdef
    have hx : 0 < x := by positivity
    set s := x ^ (1 / 5 : ℝ) with hsdef
    have hs : 0 < s := Real.rpow_pos_of_pos hx _
    have hs5 : s ^ 5 = x := by
      rw [hsdef, show (1 / 5 : ℝ) = ((5 : ℕ) : ℝ)⁻¹ by norm_num]
      exact Real.rpow_inv_natCast_pow hx.le (by norm_num)
    have hcx : c = 4 * β₃ ^ 2 * n * s ^ 5 := by
      rw [hs5, hxdef]; field_simp
    have hs4 : s ^ 4 = x ^ (4 / 5 : ℝ) := by
      rw [hsdef, ← Real.rpow_natCast, ← Real.rpow_mul hx.le]; norm_num
    have h1 : (β₃ ^ 2) ^ (1 / 5 : ℝ) * (β₃ ^ 2) ^ (4 / 5 : ℝ) = β₃ ^ 2 := by
      rw [← Real.rpow_add ha]; norm_num
    have h2 : n ^ (4 / 5 : ℝ) * n ^ (-(4 / 5) : ℝ) = 1 := by
      rw [← Real.rpow_add hn]; norm_num
    have hc2 : c / 4 = x * (β₃ ^ 2 * n) := by rw [hxdef]; field_simp
    calc β₃ ^ 2 * s ^ 4 + c / (n * s) = 5 * β₃ ^ 2 * s ^ 4 := by
          rw [hcx]; field_simp; ring
      _ = 5 * (β₃ ^ 2) ^ (1 / 5 : ℝ) * (c / 4) ^ (4 / 5 : ℝ) * n ^ (-(4 / 5) : ℝ) := by
          rw [hc2, Real.mul_rpow hx.le (by positivity), Real.mul_rpow ha.le hn.le, ← hs4]
          linear_combination (-5 * s ^ 4) * h1
            - 5 * s ^ 4 * (β₃ ^ 2) ^ (1 / 5 : ℝ) * (β₃ ^ 2) ^ (4 / 5 : ℝ) * h2
  · intro v V hv h hh hh2
    have hn2 : (n ^ (-(1 / 2) : ℝ)) ^ 2 = n⁻¹ := by
      rw [← Real.rpow_natCast, ← Real.rpow_mul hn.le]; norm_num
      exact Real.rpow_neg_one n
    have h4 : h ^ 4 ≤ n⁻¹ := by
      rw [← hn2, show h ^ 4 = (h ^ 2) ^ 2 by ring]
      exact pow_le_pow_left₀ (by positivity) hh2 2
    have hvh := hv h hh
    rw [add_div]
    have : β₃ ^ 2 * h ^ 4 ≤ β₃ ^ 2 / n := by
      rw [div_eq_mul_inv]; exact mul_le_mul_of_nonneg_left h4 ha.le
    have : v h / n ≤ V / n := div_le_div_of_nonneg_right hvh hn.le
    linarith

/-- At the best bump the two parts of the error balance in a fixed ratio: with fresh draws
the noise squared `c / (n h*²)` is twice the bias squared `β₃² h*⁴` (noise over bias is
`√2`), and for a payoff that jumps the noise squared `c / (n h*)` is four times the bias
squared (noise over bias is 2). -/
theorem best_bump_noise_to_bias (β₃ c n : ℝ) (hβ : β₃ ≠ 0) (hc : 0 < c) (hn : 0 < n) :
    c / (n * ((c / (2 * β₃ ^ 2 * n)) ^ (1 / 6 : ℝ)) ^ 2)
        = 2 * (β₃ ^ 2 * ((c / (2 * β₃ ^ 2 * n)) ^ (1 / 6 : ℝ)) ^ 4) ∧
    c / (n * (c / (4 * β₃ ^ 2 * n)) ^ (1 / 5 : ℝ))
        = 4 * (β₃ ^ 2 * ((c / (4 * β₃ ^ 2 * n)) ^ (1 / 5 : ℝ)) ^ 4) := by
  have ha : 0 < β₃ ^ 2 := by positivity
  constructor
  · set x := c / (2 * β₃ ^ 2 * n) with hxdef
    have hx : 0 < x := by positivity
    set s := x ^ (1 / 6 : ℝ) with hsdef
    have hs : 0 < s := Real.rpow_pos_of_pos hx _
    have hs6 : s ^ 6 = x := by
      rw [hsdef, show (1 / 6 : ℝ) = ((6 : ℕ) : ℝ)⁻¹ by norm_num]
      exact Real.rpow_inv_natCast_pow hx.le (by norm_num)
    have hcx : c = 2 * β₃ ^ 2 * n * s ^ 6 := by
      rw [hs6, hxdef]; field_simp
    rw [hcx]; field_simp
  · set x := c / (4 * β₃ ^ 2 * n) with hxdef
    have hx : 0 < x := by positivity
    set s := x ^ (1 / 5 : ℝ) with hsdef
    have hs : 0 < s := Real.rpow_pos_of_pos hx _
    have hs5 : s ^ 5 = x := by
      rw [hsdef, show (1 / 5 : ℝ) = ((5 : ℕ) : ℝ)⁻¹ by norm_num]
      exact Real.rpow_inv_natCast_pow hx.le (by norm_num)
    have hcx : c = 4 * β₃ ^ 2 * n * s ^ 5 := by
      rw [hs5, hxdef]; field_simp
    rw [hcx]; field_simp

/-- Shared draws cap a call's noise: on one path with growth factor `G ≥ 0`, the discounted
call payoffs `e^(-rT) max(sG - K, 0)` at `s = S + h` and `s = S - h` differ by at most
`2h e^(-rT) G`, so that path's difference divided by `2h` is at most its discounted growth
factor, whatever the bump. -/
theorem shared_draws_call_difference_capped (S K r T G h : ℝ) (hG : 0 ≤ G) (hh : 0 ≤ h) :
    |Real.exp (-r * T) * max ((S + h) * G - K) 0 - Real.exp (-r * T) * max ((S - h) * G - K) 0|
      ≤ 2 * h * Real.exp (-r * T) * G := by
  have hE : 0 < Real.exp (-r * T) := Real.exp_pos _
  rw [← mul_sub, abs_mul, abs_of_pos hE]
  have h1 := abs_max_sub_max_le_abs ((S + h) * G - K) ((S - h) * G - K) 0
  have h2 : |((S + h) * G - K) - ((S - h) * G - K)| = 2 * h * G := by
    rw [show ((S + h) * G - K) - ((S - h) * G - K) = 2 * h * G by ring]
    exact abs_of_nonneg (by positivity)
  rw [h2] at h1
  calc Real.exp (-r * T) * |max ((S + h) * G - K) 0 - max ((S - h) * G - K) 0|
      ≤ Real.exp (-r * T) * (2 * h * G) := mul_le_mul_of_nonneg_left h1 hE.le
    _ = 2 * h * Real.exp (-r * T) * G := by ring

-- A thousand times the paths buys only ten times the accuracy at the fresh-draw rate n^(-1/3).
example : (10 : ℕ) ^ 3 = 1000 := by decide

#print axioms bumped_delta_error_rates
#print axioms best_bump_noise_to_bias
#print axioms shared_draws_call_difference_capped
