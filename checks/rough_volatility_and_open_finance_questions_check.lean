-- Open questions in finance mathematics: to first order in the vol of vol, rough Bergomi's at-the-money skew is ρη√(2H)/(2(H+1/2)(H+3/2)) times T^(H−1/2), its skew-stickiness ratio is H + 3/2 at every maturity, and Heston's first-order skew levels off at ρξ/(4σ₀) as the maturity shrinks.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real Filter Topology

/-- Helper: the rough kernel integrated over the triangle 0 < t < u < T. -/
theorem rough_kernel_double_integral (H T : ℝ) (hH : 0 < H) :
    (∫ t in (0 : ℝ)..T, ∫ u in t..T, (u - t) ^ (H - 1 / 2)) =
      T ^ (H + 3 / 2) / ((H + 1 / 2) * (H + 3 / 2)) := by
  have h1 : ∀ t : ℝ, (∫ u in t..T, (u - t) ^ (H - 1 / 2)) = (T - t) ^ (H + 1 / 2) / (H + 1 / 2) := by
    intro t
    rw [intervalIntegral.integral_comp_sub_right (fun x : ℝ => x ^ (H - 1 / 2)) t, sub_self,
      integral_rpow (Or.inl (by linarith))]
    have : H - 1 / 2 + 1 = H + 1 / 2 := by ring
    rw [this, zero_rpow (by linarith), sub_zero]
  simp_rw [h1]
  rw [intervalIntegral.integral_div,
    intervalIntegral.integral_comp_sub_left (fun x : ℝ => x ^ (H + 1 / 2)) T, sub_self, sub_zero,
    integral_rpow (Or.inl (by linarith))]
  have : H + 1 / 2 + 1 = H + 3 / 2 := by ring
  rw [this, zero_rpow (by linarith), sub_zero, div_div, mul_comm (H + 3 / 2)]

/-- Helper: the second-order Taylor remainder of exp(−κT), divided by T², tends to 0. -/
theorem exp_second_order_remainder_tendsto (κ : ℝ) (hκ : 0 < κ) :
    Tendsto (fun T : ℝ => (exp (-κ * T) - 1 - (-κ * T) - (-κ * T) ^ 2 / 2) / T ^ 2)
      (𝓝[>] 0) (𝓝 0) := by
  have hc : Tendsto (fun T : ℝ => κ ^ 3 * (2 / 9) * |T|) (𝓝[>] 0) (𝓝 0) := by
    apply tendsto_nhdsWithin_of_tendsto_nhds
    have : Continuous (fun T : ℝ => κ ^ 3 * (2 / 9) * |T|) := by fun_prop
    simpa using this.tendsto 0
  apply squeeze_zero_norm' _ hc
  filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < 1 / κ by positivity)] with T hT
  obtain ⟨hT0, hT1⟩ := hT
  have hx : |-κ * T| ≤ 1 := by
    rw [abs_le]
    have : κ * T < 1 := by rwa [lt_div_iff₀ hκ, mul_comm] at hT1
    constructor <;> nlinarith
  have hb := Real.exp_bound hx (n := 3) (by norm_num)
  simp only [Finset.sum_range_succ, Finset.sum_range_zero] at hb
  norm_num [Nat.factorial] at hb
  have hT2 : 0 < T ^ 2 := by positivity
  rw [Real.norm_eq_abs, abs_div, abs_of_pos hT2, div_le_iff₀ hT2]
  rw [abs_of_pos hκ, abs_of_pos hT0] at hb
  rw [abs_of_pos hT0]
  calc |exp (-κ * T) - 1 - -κ * T - (-κ * T) ^ 2 / 2|
      = |rexp (-(κ * T)) - (1 + -(κ * T) + (κ * T) ^ 2 / 2)| := by congr 1; ring_nf
    _ ≤ (κ * T) ^ 3 * (2 / 9) := hb
    _ = κ ^ 3 * (2 / 9) * T * T ^ 2 := by ring

/-- The skew power law (first order in the vol of vol η): the return-variance covariance is
Cov(x_T, I) = ρ η σ₀³ √(2H) ∫₀ᵀ ∫ₜᵀ (u − t)^(H − 1/2) du dt, the kernel integrated over the
triangle 0 < t < u < T, and the at-the-money skew is ψ(T) = Cov(x_T, I) / (2 σ₀³ T²).
Then ψ(T) = ρ η √(2H) / (2 (H + 1/2)(H + 3/2)) · T^(H − 1/2): short-dated skews steepen like
the maturity to the power H − 1/2. -/
theorem rough_bergomi_skew_power_law (H ρ η σ₀ T : ℝ) (hH : 0 < H) (hσ : 0 < σ₀) (hT : 0 < T) :
    (ρ * η * σ₀ ^ 3 * √(2 * H) *
        ∫ t in (0 : ℝ)..T, ∫ u in t..T, (u - t) ^ (H - 1 / 2)) / (2 * σ₀ ^ 3 * T ^ 2) =
      ρ * η * √(2 * H) / (2 * (H + 1 / 2) * (H + 3 / 2)) * T ^ (H - 1 / 2) := by
  rw [rough_kernel_double_integral H T hH]
  have hp : T ^ (H + 3 / 2) = T ^ (H - 1 / 2) * T ^ 2 := by
    rw [← rpow_natCast, ← rpow_add hT]; norm_num; ring_nf
  rw [hp]
  have h1 : H + 1 / 2 ≠ 0 := by linarith
  have h2 : H + 3 / 2 ≠ 0 := by linarith
  field_simp

/-- The skew-stickiness ratio is H + 3/2 at every maturity: a shock moves each forward
variance ξᵘ by ξ₀ η √(2H) u^(H − 1/2), so the regression slope of the at-the-money volatility
on the index's log-move is ρ η √(2H) / (2T) · ∫₀ᵀ u^(H − 1/2) du; divided by the first-order
skew ψ(T) above, everything cancels except H + 3/2 (1.6 at H = 0.1). -/
theorem rough_bergomi_skew_stickiness_ratio (H ρ η σ₀ T : ℝ) (hH : 0 < H) (hρ : ρ ≠ 0)
    (hη : η ≠ 0) (hσ : 0 < σ₀) (hT : 0 < T) :
    (ρ * η * √(2 * H) / (2 * T) * ∫ u in (0 : ℝ)..T, u ^ (H - 1 / 2)) /
      ((ρ * η * σ₀ ^ 3 * √(2 * H) *
        ∫ t in (0 : ℝ)..T, ∫ u in t..T, (u - t) ^ (H - 1 / 2)) / (2 * σ₀ ^ 3 * T ^ 2)) =
      H + 3 / 2 := by
  rw [rough_bergomi_skew_power_law H ρ η σ₀ T hH hσ hT, integral_rpow (Or.inl (by linarith))]
  have e : H - 1 / 2 + 1 = H + 1 / 2 := by ring
  have hp : T ^ (H + 1 / 2) = T ^ (H - 1 / 2) * T := by
    rw [← rpow_add_one hT.ne', e]
  rw [e, zero_rpow (by linarith), sub_zero, hp]
  have h1 : H + 1 / 2 ≠ 0 := by linarith
  have h2 : H + 3 / 2 ≠ 0 := by linarith
  have hs : √(2 * H) ≠ 0 := by positivity
  have hq : T ^ (H - 1 / 2) ≠ 0 := (rpow_pos_of_pos hT _).ne'
  have hT' : T ≠ 0 := hT.ne'
  field_simp

/-- Heston's skew levels off: with pull speed κ > 0 and vol of vol ξ, Heston's first-order
skew ρ ξ / (2 σ₀ T²) · (T/κ − (1 − e^(−κT))/κ²) tends to the finite limit ρ ξ / (4 σ₀) as the
maturity T shrinks to 0, where rough Bergomi's skew grows without limit. -/
theorem heston_skew_short_maturity_limit (ρ ξ σ₀ κ : ℝ) (hσ : 0 < σ₀) (hκ : 0 < κ) :
    Tendsto (fun T : ℝ => ρ * ξ / (2 * σ₀ * T ^ 2) * (T / κ - (1 - exp (-κ * T)) / κ ^ 2))
      (𝓝[>] 0) (𝓝 (ρ * ξ / (4 * σ₀))) := by
  have key := (exp_second_order_remainder_tendsto κ hκ).const_mul (ρ * ξ / (2 * σ₀ * κ ^ 2))
  have key2 := (tendsto_const_nhds (x := ρ * ξ / (4 * σ₀))).add key
  rw [mul_zero, add_zero] at key2
  apply key2.congr'
  filter_upwards [self_mem_nhdsWithin] with T hT
  have hT0 : T ≠ 0 := (show (0 : ℝ) < T from hT).ne'
  have hk : κ ≠ 0 := hκ.ne'
  have hs : σ₀ ≠ 0 := hσ.ne'
  field_simp
  ring

-- The card's worked numbers at H = 1/10: (H + 1/2)(H + 3/2) = 0.96 = 24/25.
example : ((1 : ℚ) / 10 + 1 / 2) * (1 / 10 + 3 / 2) = 24 / 25 := by norm_num

-- The skew-stickiness ratio at H = 1/10: H + 3/2 = 1.6 = 8/5.
example : (1 : ℚ) / 10 + 3 / 2 = 8 / 5 := by norm_num

-- The kernel's power at H = 1/10: H − 1/2 = −0.4 = −2/5, and the steepening exponent 1/2 − H = 2/5.
example : (1 : ℚ) / 10 - 1 / 2 = -2 / 5 := by norm_num

#print axioms rough_kernel_double_integral
#print axioms exp_second_order_remainder_tendsto
#print axioms rough_bergomi_skew_power_law
#print axioms rough_bergomi_skew_stickiness_ratio
#print axioms heston_skew_short_maturity_limit
