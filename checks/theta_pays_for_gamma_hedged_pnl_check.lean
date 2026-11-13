-- Theta pays for gamma: given the Black-Scholes equation, the delta-hedged seller's one-step profit is exactly half the gamma times the gap between the priced squared move σ²S²δt and the actual squared move, so the seller wins on a step smaller than σS√δt, breaks even at it and loses beyond it, and the continuously hedged surplus at expiry is ½∫ e^(r(T-t)) (σ² - σ_real²) S_t² Γ_t dt.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Real Set

/-- **Theta pays for gamma: the seller's step** (The formula; Why it works, Steps 1 to 3).
A dealer has sold a call worth `V`, holds `Δ` shares at price `S`, and owes the bank `ΔS - V`.
Over one step of length `δt` the share moves by `δS`; the call's price changes by its
second-order expansion `δV = Θ δt + Δ δS + ½ Γ (δS)²`, the shares gain `Δ δS` and pay dividends
`q Δ S δt`, and the loan costs interest `r (ΔS - V) δt`. If the call's Greeks obey the
Black-Scholes equation at volatility `σ`, `Θ + ½σ²S²Γ + (r - q)SΔ = rV`, then the seller's
profit over the step is exactly `½ Γ (σ²S² δt - (δS)²)`: theta, net of financing, is the rent on
gamma, and the bend charges for the squared move that actually happened. -/
theorem delta_hedged_seller_step_is_half_gamma_times_variance_gap
    (V S Δ Γ Θ σ r q δt δS : ℝ)
    (hBS : Θ + 1 / 2 * σ ^ 2 * S ^ 2 * Γ + (r - q) * S * Δ = r * V) :
    -(Θ * δt + Δ * δS + 1 / 2 * Γ * δS ^ 2) + Δ * δS + q * Δ * S * δt
        - r * (Δ * S - V) * δt
      = 1 / 2 * Γ * (σ ^ 2 * S ^ 2 * δt - δS ^ 2) := by
  linear_combination (-δt) * hBS

/-- **The break-even move** (Step 4). With gamma positive, volatility `σ ≥ 0`, share price
`S > 0` and step `δt ≥ 0`, the seller's step `½ Γ (σ²S² δt - (δS)²)` is a profit exactly when the
move is smaller in size than `σ S √δt`, zero exactly when it equals `σ S √δt`, and a loss exactly
when it is bigger, whichever way the share went. -/
theorem break_even_move_is_sigma_S_root_dt
    (S Γ σ δt δS : ℝ) (hΓ : 0 < Γ) (hσ : 0 ≤ σ) (hS : 0 < S) (hδt : 0 ≤ δt) :
    (0 < 1 / 2 * Γ * (σ ^ 2 * S ^ 2 * δt - δS ^ 2) ↔ |δS| < σ * S * √δt) ∧
    (1 / 2 * Γ * (σ ^ 2 * S ^ 2 * δt - δS ^ 2) = 0 ↔ |δS| = σ * S * √δt) ∧
    (1 / 2 * Γ * (σ ^ 2 * S ^ 2 * δt - δS ^ 2) < 0 ↔ σ * S * √δt < |δS|) := by
  set a := σ * S * √δt with ha
  have ha0 : 0 ≤ a := by positivity
  have hsq : σ ^ 2 * S ^ 2 * δt = a ^ 2 := by
    rw [ha, mul_pow, mul_pow, Real.sq_sqrt hδt]
  have hd : δS ^ 2 = |δS| ^ 2 := (sq_abs δS).symm
  have hb0 : 0 ≤ |δS| := abs_nonneg δS
  rw [hsq, hd]
  have hΓ2 : 0 < 1 / 2 * Γ := by positivity
  refine ⟨?_, ?_, ?_⟩
  · rw [mul_pos_iff_of_pos_left hΓ2, sub_pos, sq_lt_sq₀ hb0 ha0]
  · rw [mul_eq_zero, sub_eq_zero]
    constructor
    · rintro (h | h)
      · linarith
      · exact ((pow_left_inj₀ ha0 hb0 two_ne_zero).mp h).symm
    · intro h; right; rw [h]
  · rw [← sq_lt_sq₀ ha0 hb0]
    constructor
    · intro h; by_contra h'; have h'' := not_lt.mp h'; nlinarith
    · intro h; nlinarith

/-- **The continuously hedged book at expiry** (Step 5 and the detailed proof). Along one path
of the share `S_t`, with the call's gamma `Γ_t` along it, both continuous on `[0, T]`: once the
noise and drift terms cancel, the seller's surplus `E` (wealth minus the call's model value)
grows by `dE = rE dt + ½ (σ² - σ_real²) S_t² Γ_t dt` from `E₀ = 0`. Then at expiry
`E_T = ½ ∫₀ᵀ e^(r(T-t)) (σ² - σ_real²) S_t² Γ_t dt`: each instant's variance gap, weighted by
gamma and the squared price, carried to expiry at the bank rate. -/
theorem hedged_surplus_at_expiry_is_gamma_weighted_variance_gap
    (E S Γ : ℝ → ℝ) (r σ σreal T : ℝ) (hT : 0 ≤ T)
    (hS : ContinuousOn S (Icc 0 T)) (hΓ : ContinuousOn Γ (Icc 0 T))
    (hE : ContinuousOn E (Icc 0 T))
    (hdE : ∀ t ∈ Ioo 0 T,
      HasDerivAt E (r * E t + 1 / 2 * (σ ^ 2 - σreal ^ 2) * S t ^ 2 * Γ t) t)
    (hE0 : E 0 = 0) :
    E T = 1 / 2 * ∫ t in (0 : ℝ)..T,
      exp (r * (T - t)) * (σ ^ 2 - σreal ^ 2) * S t ^ 2 * Γ t := by
  set f : ℝ → ℝ := fun t => 1 / 2 * (σ ^ 2 - σreal ^ 2) * S t ^ 2 * Γ t with hf
  have hG : ∀ t ∈ Ioo 0 T, HasDerivAt (fun t => exp (r * (T - t)) * E t)
      (1 / 2 * (exp (r * (T - t)) * (σ ^ 2 - σreal ^ 2) * S t ^ 2 * Γ t)) t := by
    intro t ht
    have h1 : HasDerivAt (fun t => r * (T - t)) (r * (0 - 1)) t :=
      ((hasDerivAt_const t T).sub (hasDerivAt_id t)).const_mul r
    have h2 := (h1.exp).mul (hdE t ht)
    convert h2 using 1
    ring
  have hcont : ContinuousOn (fun t => exp (r * (T - t)) * E t) (Icc 0 T) := by
    apply ContinuousOn.mul _ hE
    fun_prop
  have hint : IntervalIntegrable
      (fun t => 1 / 2 * (exp (r * (T - t)) * (σ ^ 2 - σreal ^ 2) * S t ^ 2 * Γ t))
      MeasureTheory.volume 0 T := by
    apply ContinuousOn.intervalIntegrable_of_Icc hT
    apply ContinuousOn.mul continuousOn_const
    apply ContinuousOn.mul _ hΓ
    apply ContinuousOn.mul _ (hS.pow 2)
    apply ContinuousOn.mul _ continuousOn_const
    fun_prop
  have key := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hT hcont hG hint
  rw [intervalIntegral.integral_const_mul] at key
  rw [key]
  simp [hE0]

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year, 252 trading days.
-- Rent per unit of gamma, ½σ²S² = 0.5 × 0.04 × 10,000 = 200.
example : (1 / 2 : ℚ) * (1 / 5) ^ 2 * 100 ^ 2 = 200 := by norm_num
-- Carry on the hedge, (r - q)SΔ = 0.03 × 100 × 0.586851 = 1.760553.
example : ((5 / 100 : ℚ) - 2 / 100) * 100 * (586851 / 1000000) = 1760553 / 1000000 := by
  norm_num
-- Theta from the identity: 0.461350 - 1.760553 - 3.790116 = -5.089319.
example : (461350 / 1000000 : ℚ) - 1760553 / 1000000 - 3790116 / 1000000
    = -5089319 / 1000000 := by norm_num
-- Daily break-even, σS√(1/252) = 20/√252, lies between $1.25 and $1.27.
example : 5 / 4 < (1 / 5 : ℝ) * 100 * √(1 / 252) ∧
    (1 / 5 : ℝ) * 100 * √(1 / 252) < 127 / 100 := by
  have h1 : (1 / 16 : ℝ) < √(1 / 252) := by
    rw [Real.lt_sqrt (by norm_num)]; norm_num
  have h2 : √(1 / 252 : ℝ) < 127 / 2000 := by
    rw [Real.sqrt_lt' (by norm_num)]; norm_num
  constructor <;> linarith
-- Weekly hedge: five trading days give √5 times the daily break-even.
example : (1 / 5 : ℝ) * 100 * √(5 / 252) = √5 * ((1 / 5 : ℝ) * 100 * √(1 / 252)) := by
  rw [show (5 / 252 : ℝ) = 5 * (1 / 252) by norm_num, Real.sqrt_mul (by norm_num)]
  ring
-- Step 6: n steps of noise size T/n add to variance n (T/n)² = T²/n; going from 21 to 252
-- rebalances divides the variance by 12.
example : ((21 : ℚ) * (1 / 21) ^ 2) / (252 * (1 / 252) ^ 2) = 12 := by norm_num

#print axioms delta_hedged_seller_step_is_half_gamma_times_variance_gap
#print axioms break_even_move_is_sigma_S_root_dt
#print axioms hedged_surplus_at_expiry_is_gamma_weighted_variance_gap
