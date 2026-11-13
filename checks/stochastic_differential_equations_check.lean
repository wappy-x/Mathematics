-- Stochastic differential equations: the formula S₀ e^((μ - σ²/2)t + σw) starts at S₀ and its Ito's-lemma drift and noise size are exactly μ times it and σ times it, the logarithm of the price has the constant drift μ - σ²/2, and the ordinary-calculus guess S₀ e^(μt + σw) gets the drift μ + σ²/2 instead.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Tactic.NormNum

theorem sde_deriv_exp_left (c k b x : ℝ) :
    deriv (fun s => c * Real.exp (k * s + b)) x = k * (c * Real.exp (k * x + b)) := by
  have h : HasDerivAt (fun s => c * Real.exp (k * s + b)) (c * (Real.exp (k * x + b) * (k * 1))) x :=
    ((((hasDerivAt_id x).const_mul k).add_const b).exp).const_mul c
  rw [h.deriv]; ring

theorem sde_deriv_exp_right (c k b x : ℝ) :
    deriv (fun s => c * Real.exp (b + k * s)) x = k * (c * Real.exp (b + k * x)) := by
  have h : HasDerivAt (fun s => c * Real.exp (b + k * s)) (c * (Real.exp (b + k * x) * (k * 1))) x :=
    ((((hasDerivAt_id x).const_mul k).const_add b).exp).const_mul c
  rw [h.deriv]; ring

#print axioms sde_deriv_exp_left
#print axioms sde_deriv_exp_right

/-- The card's Step 3, the check that the formula solves the share's SDE dS = μS dt + σS dW.
Write the candidate as a function of time t and Brownian position w,
f(t, w) = S₀ e^((μ - σ²/2)t + σw), with constant μ and σ. It starts at S₀, and Ito's lemma reads off
its drift f_t + ½ f_ww and its noise size f_w: the drift is exactly μ times f and the noise size is
exactly σ times f, at every time and every Brownian position. That is the share's SDE, term for term.
(Mathlib has no Ito integral yet, so this states the calculus identity that Ito's lemma turns into
the SDE, not the almost-sure integral equation itself.) -/
theorem exp_formula_has_share_sde_drift_and_noise (S₀ μ σ : ℝ) (f : ℝ → ℝ → ℝ)
    (hf : f = fun t w => S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * w)) :
    f 0 0 = S₀ ∧
    ∀ t w : ℝ,
      deriv (fun s => f s w) t + 1 / 2 * deriv (fun v => deriv (fun u => f t u) v) w
          = μ * f t w ∧
        deriv (fun u => f t u) w = σ * f t w := by
  subst hf
  refine ⟨by simp, fun t w => ?_⟩
  have h1 : (fun v => deriv (fun u => S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * u)) v)
      = fun v => σ * S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * v) := by
    funext v; rw [sde_deriv_exp_right]; ring
  simp only []
  rw [h1]
  constructor
  · rw [sde_deriv_exp_left, sde_deriv_exp_right (σ * S₀)]
    ring
  · rw [sde_deriv_exp_right]

/-- The card's Step 2, how the candidate is found. Apply Ito's lemma to the logarithm g = ln of a
positive price S following dS = μS dt + σS dW: the drift g'(S)·μS + ½ g''(S)·σ²S² is the constant
μ - σ²/2, and the noise size g'(S)·σS is the constant σ, whatever the price. -/
theorem log_price_has_constant_drift_and_noise (μ σ S : ℝ) (hS : 0 < S) :
    deriv Real.log S * (μ * S) + 1 / 2 * deriv (deriv Real.log) S * (σ * S) ^ 2 = μ - σ ^ 2 / 2 ∧
      deriv Real.log S * (σ * S) = σ := by
  have hS' : S ≠ 0 := hS.ne'
  rw [Real.deriv_log', deriv_inv]
  constructor
  · field_simp; ring
  · field_simp

/-- The common mistake. The ordinary-chain-rule guess h(t, w) = S₀ e^(μt + σw) has Ito drift
h_t + ½ h_ww equal to (μ + σ²/2) times h, not μ times h: it solves the SDE with drift μ + σ²/2,
not the share's SDE. Its noise size h_w is σ times h, as before. -/
theorem ordinary_chain_rule_guess_has_wrong_drift (S₀ μ σ : ℝ) (h : ℝ → ℝ → ℝ)
    (hh : h = fun t w => S₀ * Real.exp (μ * t + σ * w)) :
    ∀ t w : ℝ,
      deriv (fun s => h s w) t + 1 / 2 * deriv (fun v => deriv (fun u => h t u) v) w
          = (μ + σ ^ 2 / 2) * h t w ∧
        deriv (fun u => h t u) w = σ * h t w := by
  subst hh
  intro t w
  have h1 : (fun v => deriv (fun u => S₀ * Real.exp (μ * t + σ * u)) v)
      = fun v => σ * S₀ * Real.exp (μ * t + σ * v) := by
    funext v; rw [sde_deriv_exp_right]; ring
  simp only []
  rw [h1]
  constructor
  · rw [sde_deriv_exp_left, sde_deriv_exp_right (σ * S₀)]
    ring
  · rw [sde_deriv_exp_right]

-- The share: μ = 0.05 = 1/20 and σ = 0.20 = 1/5 a year.
-- The log drift μ - σ²/2 is 0.03.
example : (1 / 20 : ℚ) - 1 / 2 * (1 / 5) ^ 2 = 3 / 100 := by norm_num
-- The ordinary-calculus guess's drift μ + σ²/2 is 0.07.
example : (1 / 20 : ℚ) + 1 / 2 * (1 / 5) ^ 2 = 7 / 100 := by norm_num
-- Drift total μt equals noise spread σ√t when t = σ²/μ², at 16 years.
example : ((1 / 5 : ℚ) ^ 2) / (1 / 20) ^ 2 = 16 := by norm_num
-- The solution at W₁ = 0.5 has exponent 0.03 + 0.2 × 0.5 = 0.13; the guess has 0.05 + 0.1 = 0.15.
example : (3 / 100 : ℚ) + 1 / 5 * (1 / 2) = 13 / 100 ∧ (1 / 20 : ℚ) + 1 / 5 * (1 / 2) = 15 / 100 := by
  norm_num
-- The chance of ending below $100 is the normal chance below -0.03/0.2 = -0.15.
example : -(3 / 100 : ℚ) / (1 / 5) = -15 / 100 := by norm_num

#print axioms exp_formula_has_share_sde_drift_and_noise
#print axioms log_price_has_constant_drift_and_noise
#print axioms ordinary_chain_rule_guess_has_wrong_drift
