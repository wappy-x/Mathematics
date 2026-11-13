-- Black-Scholes by hedging: one option short Δ shares is riskless and earns the bank rate exactly when Δ is the option's price slope and its worth obeys V_t + (r - q) S V_S + ½ σ² S² V_SS = r V, whatever the stock's real drift μ; cash and the prepaid forward obey that equation.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Real

/-- Helper: the time slope of a discount factor, `d/du e^(-a (T - u)) = a e^(-a (T - u))`. -/
lemma hasDerivAt_discount (a T t : ℝ) :
    HasDerivAt (fun u : ℝ => exp (-a * (T - u))) (exp (-a * (T - t)) * a) t := by
  have h : HasDerivAt (fun u : ℝ => -a * (T - u)) a t := by
    have := ((hasDerivAt_id t).const_sub T).const_mul (-a)
    simpa using this
  exact h.exp

/-- Helper: the price slope of `x e^c - d` is `e^c`, at every price. -/
lemma deriv_linear_price (c d : ℝ) :
    (fun x : ℝ => deriv (fun y : ℝ => y * exp c - d) x) = fun _ => exp c := by
  funext x
  simp

/-- The hedging argument (Steps 3 and 4). Let the option's worth `V(S, t)` be smooth near
today's price `S > 0` and date `t`, and let the stock follow geometric Brownian motion with real
drift `μ` and volatility `σ > 0`, paying a steady dividend yield `q`. Hold one option and short
`Δ` shares. By Itô's lemma the book `Π = V - Δ S` changes by `drift · dt + shock · dW`, where
the shock is the option's `σ S V_S` minus the shares' `Δ σ S`, and the drift is the option's
`V_t + μ S V_S + ½ σ² S² V_SS`, minus the shares' `Δ μ S`, minus the dividends owed `q S Δ`.
Then, for every value of `μ`: the book is riskless and earns the bank rate `r` on its value
exactly when `Δ = V_S` and `V` obeys the Black–Scholes–Merton equation
`V_t + (r - q) S V_S + ½ σ² S² V_SS = r V`. The real drift `μ` drops out. -/
theorem hedged_book_riskless_at_bank_rate_iff_black_scholes
    (V : ℝ → ℝ → ℝ) (S t r q σ μ Δ : ℝ) (hS : 0 < S) (hσ : 0 < σ)
    (hV : ContDiffAt ℝ 2 (fun p : ℝ × ℝ => V p.1 p.2) (S, t)) :
    let Vt := deriv (fun u => V S u) t
    let VS := deriv (fun x => V x t) S
    let VSS := deriv (fun x => deriv (fun y => V y t) x) S
    let shock := σ * S * VS - Δ * (σ * S)
    let drift := (Vt + μ * S * VS + 1 / 2 * σ ^ 2 * S ^ 2 * VSS) - Δ * (μ * S) - q * S * Δ
    (shock = 0 ∧ drift = r * (V S t - Δ * S)) ↔
      (Δ = VS ∧ Vt + (r - q) * S * VS + 1 / 2 * σ ^ 2 * S ^ 2 * VSS = r * V S t) := by
  intro Vt VS VSS shock drift
  have hσS : σ * S ≠ 0 := mul_ne_zero hσ.ne' hS.ne'
  constructor
  · rintro ⟨h1, h2⟩
    have hΔ : Δ = VS := by
      have : (VS - Δ) * (σ * S) = 0 := by simp only [shock] at h1; linarith
      rcases mul_eq_zero.mp this with h | h
      · linarith
      · exact absurd h hσS
    refine ⟨hΔ, ?_⟩
    simp only [drift] at h2
    subst hΔ
    linarith
  · rintro ⟨hΔ, h⟩
    subst hΔ
    refine ⟨by simp only [shock]; ring, ?_⟩
    simp only [drift]
    linarith

/-- The equation does not know which contract it describes. Cash in the bank,
`V(S, t) = K e^(-r (T - t))`, and the prepaid forward, one funded share minus the funded strike,
`V(S, t) = S e^(-q (T - t)) - K e^(-r (T - t))`, both obey
`V_t + (r - q) S V_S + ½ σ² S² V_SS = r V` at every price `S` and date `t`. -/
theorem cash_and_prepaid_forward_obey_black_scholes (r q σ K T : ℝ) :
    (∀ S t : ℝ,
      deriv (fun u => K * exp (-r * (T - u))) t
        + (r - q) * S * deriv (fun _ : ℝ => K * exp (-r * (T - t))) S
        + 1 / 2 * σ ^ 2 * S ^ 2 * deriv (fun x => deriv (fun _ : ℝ => K * exp (-r * (T - t))) x) S
        = r * (K * exp (-r * (T - t)))) ∧
    (∀ S t : ℝ,
      deriv (fun u => S * exp (-q * (T - u)) - K * exp (-r * (T - u))) t
        + (r - q) * S * deriv (fun x => x * exp (-q * (T - t)) - K * exp (-r * (T - t))) S
        + 1 / 2 * σ ^ 2 * S ^ 2 *
            deriv (fun x => deriv (fun y => y * exp (-q * (T - t)) - K * exp (-r * (T - t))) x) S
        = r * (S * exp (-q * (T - t)) - K * exp (-r * (T - t)))) := by
  refine ⟨fun S t => ?_, fun S t => ?_⟩
  · have h1 := ((hasDerivAt_discount r T t).const_mul K).deriv
    rw [h1]
    simp only [deriv_const]
    ring
  · have h1 : HasDerivAt (fun u => S * exp (-q * (T - u)) - K * exp (-r * (T - u)))
        (S * (exp (-q * (T - t)) * q) - K * (exp (-r * (T - t)) * r)) t :=
      ((hasDerivAt_discount q T t).const_mul S).sub ((hasDerivAt_discount r T t).const_mul K)
    rw [h1.deriv, deriv_linear_price, deriv_const]
    have h2 := (((hasDerivAt_id S).mul_const (exp (-q * (T - t)))).sub_const
      (K * exp (-r * (T - t)))).deriv
    simp only [id] at h2
    rw [h2]
    ring

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, one year.
-- Half the variance, ½ σ² = 0.02.
example : (1 / 2 : ℚ) * (1 / 5) ^ 2 = 2 / 100 := by norm_num
-- d₁ = (ln 1 + (r - q + ½ σ²) · 1) / (σ · 1) = 0.25.
example : ((0 : ℚ) + (5 / 100 - 2 / 100 + 2 / 100) * 1) / (1 / 5 * 1) = 1 / 4 := by norm_num
-- d₂ = d₁ - σ √1 = 0.25 - 0.20 = 0.05.
example : (1 / 4 : ℚ) - 1 / 5 = 5 / 100 := by norm_num
-- What the shares carry is (r - q) S Δ = 3 Δ: (0.05 - 0.02) × 100 = 3.
example : (5 / 100 - 2 / 100 : ℚ) * 100 = 3 := by norm_num
-- What the bend pays is ½ σ² S² Γ = 200 Γ: ½ × 0.2² × 100² = 200.
example : (1 / 2 : ℚ) * (1 / 5) ^ 2 * 100 ^ 2 = 200 := by norm_num
-- Step 4: the two share-slope terms collect, -q S V_S + r S V_S = (r - q) S V_S.
example (r q S VS : ℚ) : -q * S * VS + r * S * VS = (r - q) * S * VS := by ring

#print axioms hasDerivAt_discount
#print axioms deriv_linear_price
#print axioms hedged_book_riskless_at_bank_rate_iff_black_scholes
#print axioms cash_and_prepaid_forward_obey_black_scholes
