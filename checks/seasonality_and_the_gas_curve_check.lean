-- Seasonal curves: the summer-to-winter storage trade is worth something exactly when the spread beats storage cost plus interest, nothing floors the spread from below, the level-times-cosine shape is a straight-line fit in logs, and twelve evenly spaced months make the fit's columns orthogonal.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real Finset

/-! Notation, as on the card. `F_s` is the summer (July) forward and `F_w` the winter (January)
forward, for delivery at times `t_s` and `t_w` in years from 1 April, so `τ = t_w - t_s`. `c` is
the all-in storage cost paid at `t_w`, and `r` the rate at which money is borrowed and lent,
continuously compounded. The storage trade (buy July, store, sell January) is worth, today,
`-F_s e^(-r t_s) + (F_w - c) e^(-r t_w)`: the July payment and the January receipt less the fee,
each discounted to 1 April. -/

lemma sum12_shift3 (f : ℕ → ℝ) (c : ℝ) (h : ∀ m, f m + f (m + 3) = c) :
    ∑ m ∈ range 12, f m = 6 * c := by
  have h0 := h 0; have h1 := h 1; have h2 := h 2
  have h6 := h 6; have h7 := h 7; have h8 := h 8
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num at h0 h1 h2 h6 h7 h8
  linarith

lemma sum12_shift6 (f : ℕ → ℝ) (c : ℝ) (h : ∀ m, f m + f (m + 6) = c) :
    ∑ m ∈ range 12, f m = 6 * c := by
  have h0 := h 0; have h1 := h 1; have h2 := h 2
  have h3 := h 3; have h4 := h 4; have h5 := h 5
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num at h0 h1 h2 h3 h4 h5
  linarith

lemma angle_add6 (m : ℕ) : 2 * π * ((m + 6 : ℕ) : ℝ) / 12 = 2 * π * m / 12 + π := by
  push_cast; ring

lemma angle_add3 (m : ℕ) : 2 * π * ((m + 3 : ℕ) : ℝ) / 12 = 2 * π * m / 12 + π / 2 := by
  push_cast; ring

/-- The card's main claim: storage caps how far winter can rise above summer, at the cost of
storing plus interest, and nothing caps how far it can fall. For every January price, the storage
trade is worth nothing or less today exactly when the spread `F_w - F_s` is at most
`c + F_s (e^(rτ) - 1)`; and for every level `M`, however low, some January price puts the spread
below `M` while the storage trade still offers no free money. -/
theorem storage_caps_winter_spread_with_no_floor (r c F_s t_s t_w : ℝ) :
    (∀ F_w : ℝ, -F_s * exp (-(r * t_s)) + (F_w - c) * exp (-(r * t_w)) ≤ 0 ↔
        F_w - F_s ≤ c + F_s * (exp (r * (t_w - t_s)) - 1)) ∧
    (∀ M : ℝ, ∃ F_w : ℝ, F_w - F_s < M ∧
        -F_s * exp (-(r * t_s)) + (F_w - c) * exp (-(r * t_w)) ≤ 0) := by
  have hE : exp (-(r * t_s)) = exp (r * (t_w - t_s)) * exp (-(r * t_w)) := by
    rw [← exp_add]; ring_nf
  have hD : 0 < exp (-(r * t_w)) := exp_pos _
  have key : ∀ F_w : ℝ, -F_s * exp (-(r * t_s)) + (F_w - c) * exp (-(r * t_w)) ≤ 0 ↔
      F_w - F_s ≤ c + F_s * (exp (r * (t_w - t_s)) - 1) := by
    intro F_w
    rw [hE]
    have : -F_s * (exp (r * (t_w - t_s)) * exp (-(r * t_w))) + (F_w - c) * exp (-(r * t_w)) =
        (F_w - c - F_s * exp (r * (t_w - t_s))) * exp (-(r * t_w)) := by ring
    rw [this]
    constructor
    · intro h
      by_contra hc
      have : 0 < (F_w - c - F_s * exp (r * (t_w - t_s))) * exp (-(r * t_w)) :=
        mul_pos (by linarith) hD
      linarith
    · intro h
      exact mul_nonpos_of_nonpos_of_nonneg (by linarith) hD.le
  refine ⟨key, fun M => ?_⟩
  refine ⟨min (F_s + M - 1) (c + F_s * exp (r * (t_w - t_s))), ?_, ?_⟩
  · have := min_le_left (F_s + M - 1) (c + F_s * exp (r * (t_w - t_s)))
    linarith
  · rw [key]
    have := min_le_right (F_s + M - 1) (c + F_s * exp (r * (t_w - t_s)))
    linarith

/-- The shape as a straight-line fit in logs. With level `L > 0`, amplitude `β` and peak date
`t_0`, the curve `L e^(β cos(2π(t - t_0)))` equals `e^(a + A cos(2πt) + B sin(2πt))` with
`a = ln L`, `A = β cos(2π t_0)` and `B = β sin(2π t_0)`; and when `β ≥ 0` it is the hypotenuse
`√(A² + B²)` of the legs `A` and `B`. -/
theorem level_times_cosine_is_log_linear_fit (L β t₀ t : ℝ) (hL : 0 < L) (hβ : 0 ≤ β) :
    L * exp (β * cos (2 * π * (t - t₀))) =
        exp (log L + β * cos (2 * π * t₀) * cos (2 * π * t) +
          β * sin (2 * π * t₀) * sin (2 * π * t)) ∧
    √((β * cos (2 * π * t₀)) ^ 2 + (β * sin (2 * π * t₀)) ^ 2) = β := by
  constructor
  · rw [add_assoc, exp_add, exp_log hL]
    congr 2
    rw [show 2 * π * (t - t₀) = 2 * π * t - 2 * π * t₀ by ring, cos_sub]
    ring
  · have : (β * cos (2 * π * t₀)) ^ 2 + (β * sin (2 * π * t₀)) ^ 2 = β ^ 2 := by
      have := sin_sq_add_cos_sq (2 * π * t₀)
      linear_combination β ^ 2 * this
    rw [this, sqrt_sq hβ]

/-- Step 5's detailed proof: over the twelve evenly spaced months `θ_m = 2π m / 12`,
`m = 0, …, 11`, the cosines sum to zero, the sines sum to zero, the products of cosine and sine
sum to zero, and the squares of the cosines and of the sines each sum to six. So the constant,
cosine and sine columns are orthogonal, with diagonal entries 12, 6 and 6. -/
theorem twelve_month_columns_orthogonal :
    ∑ m ∈ range 12, cos (2 * π * m / 12) = 0 ∧
    ∑ m ∈ range 12, sin (2 * π * m / 12) = 0 ∧
    ∑ m ∈ range 12, cos (2 * π * m / 12) * sin (2 * π * m / 12) = 0 ∧
    ∑ m ∈ range 12, cos (2 * π * m / 12) ^ 2 = 6 ∧
    ∑ m ∈ range 12, sin (2 * π * m / 12) ^ 2 = 6 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · have := sum12_shift6 (fun m : ℕ => cos (2 * π * m / 12)) 0
      (fun m => by rw [angle_add6, cos_add_pi]; ring)
    simpa using this
  · have := sum12_shift6 (fun m : ℕ => sin (2 * π * m / 12)) 0
      (fun m => by rw [angle_add6, sin_add_pi]; ring)
    simpa using this
  · have := sum12_shift3 (fun m : ℕ => cos (2 * π * m / 12) * sin (2 * π * m / 12)) 0
      (fun m => by rw [angle_add3, cos_add_pi_div_two, sin_add_pi_div_two]; ring)
    simpa using this
  · have := sum12_shift3 (fun m : ℕ => cos (2 * π * m / 12) ^ 2) 1
      (fun m => by
        rw [angle_add3, cos_add_pi_div_two]
        have := sin_sq_add_cos_sq (2 * π * m / 12); linear_combination this)
    simpa using this
  · have := sum12_shift3 (fun m : ℕ => sin (2 * π * m / 12) ^ 2) 1
      (fun m => by
        rw [angle_add3, sin_add_pi_div_two]
        have := sin_sq_add_cos_sq (2 * π * m / 12); linear_combination this)
    simpa using this

/-! The card's exact numbers, in dollars per MMBtu. -/

-- All-in storage cost: space 0.50 plus pumping 0.05 each way is 0.60.
example : (1 / 2 : ℚ) + 1 / 20 + 1 / 20 = 3 / 5 := by norm_num

-- Quoted spreads: January 3.50 less July 2.50 is 1.00; January 2.80 less July 2.50 is 0.30.
example : (7 / 2 : ℚ) - 5 / 2 = 1 ∧ (14 / 5 : ℚ) - 5 / 2 = 3 / 10 := by norm_num

-- Lift the level 20%: both forwards times 1.2 turn the 1.00 spread into 1.20.
example : (6 / 5 : ℚ) * (7 / 2) - 6 / 5 * (5 / 2) = 6 / 5 := by norm_num

#print axioms sum12_shift3
#print axioms sum12_shift6
#print axioms angle_add6
#print axioms angle_add3
#print axioms storage_caps_winter_spread_with_no_floor
#print axioms level_times_cosine_is_log_linear_fit
#print axioms twelve_month_columns_orthogonal
