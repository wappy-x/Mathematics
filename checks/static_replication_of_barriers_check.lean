-- Static barrier hedges: the mirror term (B/S)^a U(B^2/S, t) of any option price U obeys the Black-Scholes equation and equals U on the barrier, its payoff lives below the barrier when the strike is at or above it, and at r = q it is (K/B) puts struck at B^2/K.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic

/-- The Black-Scholes equation at share price `S` and date `t`, for a worth `V(S, t)`:
`∂V/∂t + (r - q) S ∂V/∂S + ½ σ² S² ∂²V/∂S² = r V`, each slope taken with the other variable
held still. -/
def ObeysBlackScholes (V : ℝ → ℝ → ℝ) (r q σ S t : ℝ) : Prop :=
  deriv (fun u => V S u) t
      + (r - q) * S * deriv (fun x => V x t) S
      + 1 / 2 * σ ^ 2 * S ^ 2 * deriv (fun x => deriv (fun y => V y t) x) S
    = r * V S t

/-- **The mirror claim is a tradable exact hedge** (Why it works, Step 5 and its detailed proof).
Volatility `σ > 0` and the barrier `B > 0` are fixed; `r` and `q` are any bank rate and dividend
yield. Let `U(y, t)` be any option price: smooth for share prices `y > 0` before expiry `T`, and
obeying the Black-Scholes equation there. Put `a = 2(r - q)/σ² - 1` and
`M(S, t) = (B/S)^a U(B²/S, t)`. Then `M` obeys the Black-Scholes equation at every share price
`S > 0` before expiry, so it is the price of a European contract; and on the barrier `S = B` it
equals `U` at every date. With `U` the plain call, the call minus `M` is worth zero on the wall at
every moment. -/
theorem mirror_term_obeys_black_scholes_and_matches_on_wall
    (U : ℝ → ℝ → ℝ) (r q σ B T : ℝ) (hσ : 0 < σ) (hB : 0 < B)
    (hU : ∀ y t, 0 < y → t < T → ContDiffAt ℝ 2 (fun p : ℝ × ℝ => U p.1 p.2) (y, t))
    (hpde : ∀ y t, 0 < y → t < T → ObeysBlackScholes U r q σ y t) :
    let a := 2 * (r - q) / σ ^ 2 - 1
    let M : ℝ → ℝ → ℝ := fun S t => (B / S) ^ a * U (B ^ 2 / S) t
    (∀ S t, 0 < S → t < T → ObeysBlackScholes M r q σ S t) ∧ (∀ t, M B t = U B t) := by
  intro a M
  have ha : (a + 1) * σ ^ 2 = 2 * (r - q) := by
    simp only [a]; field_simp; ring
  clear_value a
  refine ⟨?_, ?_⟩
  swap
  · intro t
    have h1 : B / B = 1 := div_self hB.ne'
    have h2 : B ^ 2 / B = B := by field_simp
    simp only [M, h1, h2, Real.one_rpow, one_mul]
  intro S t hS ht
  set V : ℝ → ℝ := fun y => U y t with hVdef
  have hVc : ContDiffOn ℝ 2 V (Set.Ioi 0) := by
    intro y hy
    have h := hU y t hy ht
    have : ContDiffAt ℝ 2 V y :=
      h.comp (f := fun y : ℝ => (y, t)) y (contDiffAt_id.prodMk contDiffAt_const)
    exact this.contDiffWithinAt
  have hD1c : ContDiffOn ℝ 1 (deriv V) (Set.Ioi 0) :=
    hVc.deriv_of_isOpen isOpen_Ioi (by norm_num)
  have hVd : ∀ x : ℝ, 0 < x → HasDerivAt V (deriv V x) x := fun x hx =>
    (((hVc.differentiableOn (by norm_num)) x hx).differentiableAt
      (isOpen_Ioi.mem_nhds hx)).hasDerivAt
  have hD1d : ∀ x : ℝ, 0 < x → HasDerivAt (deriv V) (deriv (deriv V) x) x := fun x hx =>
    (((hD1c.differentiableOn (by norm_num)) x hx).differentiableAt
      (isOpen_Ioi.mem_nhds hx)).hasDerivAt
  have hP : ∀ x : ℝ, 0 < x → HasDerivAt (fun x => (B / x) ^ a) (-a * (B / x) ^ a / x) x := by
    intro x hx
    have hBx : 0 < B / x := div_pos hB hx
    have hd : HasDerivAt (fun x : ℝ => B / x) (-B / x ^ 2) x :=
      ((hasDerivAt_const x B).div (hasDerivAt_id' x) hx.ne').congr_deriv (by ring)
    refine (hd.rpow_const (p := a) (Or.inl hBx.ne')).congr_deriv ?_
    rw [Real.rpow_sub_one hBx.ne']
    field_simp
  have hQ : ∀ x : ℝ, 0 < x → HasDerivAt (fun x => B ^ 2 / x) (-(B ^ 2) / x ^ 2) x := by
    intro x hx
    refine ((hasDerivAt_const x (B ^ 2)).div (hasDerivAt_id' x) hx.ne').congr_deriv ?_
    ring
  have hP' : ∀ x : ℝ, 0 < x → HasDerivAt (fun x => -a * (B / x) ^ a / x)
      ((((-a) * (-a * (B / x) ^ a / x)) * x - (-a * (B / x) ^ a) * 1) / x ^ 2) x := by
    intro x hx
    exact ((hP x hx).const_mul (-a)).div (hasDerivAt_id' x) hx.ne'
  have hF : ∀ x : ℝ, 0 < x → HasDerivAt (fun y => M y t)
      (-a * (B / x) ^ a / x * V (B ^ 2 / x)
        + (B / x) ^ a * (deriv V (B ^ 2 / x) * (-(B ^ 2) / x ^ 2))) x := by
    intro x hx
    exact (hP x hx).mul ((hVd (B ^ 2 / x) (by positivity)).comp x (hQ x hx))
  have hderivM : deriv (fun y => M y t) =ᶠ[nhds S] fun x =>
      -a * (B / x) ^ a / x * V (B ^ 2 / x)
        + (B / x) ^ a * (deriv V (B ^ 2 / x) * (-(B ^ 2) / x ^ 2)) := by
    filter_upwards [Ioi_mem_nhds hS] with x hx
    exact (hF x hx).deriv
  have hR : HasDerivAt (fun x : ℝ => -(B ^ 2) / x ^ 2)
      ((0 * S ^ 2 - (-(B ^ 2)) * (2 * S)) / (S ^ 2) ^ 2) S := by
    have := (hasDerivAt_const S (-(B ^ 2))).div (hasDerivAt_pow 2 S) (by positivity)
    exact this.congr_deriv (by simp)
  have hG := ((hP' S hS).mul ((hVd (B ^ 2 / S) (by positivity)).comp S (hQ S hS))).add
    ((hP S hS).mul (((hD1d (B ^ 2 / S) (by positivity)).comp S (hQ S hS)).mul hR))
  have htime : deriv (fun u => M S u) t = (B / S) ^ a * deriv (fun u => U (B ^ 2 / S) u) t := by
    simp only [M]
    exact congrFun (deriv_const_mul_field' _) t
  have hp := hpde (B ^ 2 / S) t (by positivity) ht
  unfold ObeysBlackScholes at hp ⊢
  rw [hderivM.deriv_eq, (hF S hS).deriv, htime]
  erw [hG.deriv]
  simp only [Function.comp_apply, Pi.mul_apply, M]
  change deriv (fun u => U (B ^ 2 / S) u) t + (r - q) * (B ^ 2 / S) * deriv V (B ^ 2 / S) +
      1 / 2 * σ ^ 2 * (B ^ 2 / S) ^ 2 * deriv (deriv V) (B ^ 2 / S) = r * V (B ^ 2 / S) at hp
  change _ = r * ((B / S) ^ a * V (B ^ 2 / S))
  linear_combination (norm := skip) (B / S) ^ a * hp
    + (B / S) ^ a * (a / 2 * V (B ^ 2 / S) + B ^ 2 / S * deriv V (B ^ 2 / S)) * ha
  field_simp
  ring

/-- **The mirror payoff lives below the wall** (When it holds, last point; Step 5, fact 2). With
barrier `B > 0` and strike `K` at or above it, the mirror strike `B²/K` is at or below the barrier,
and the mirror payoff `g(x) = (B/x)^a (B²/x - K)⁺` is zero at every expiry price `x ≥ B²/K`,
whatever the exponent `a`. So it leaves the knock-out's payoff above the barrier untouched. -/
theorem mirror_payoff_zero_at_or_above_mirror_strike
    (a B K : ℝ) (hB : 0 < B) (hBK : B ≤ K) :
    B ^ 2 / K ≤ B ∧
      ∀ x : ℝ, B ^ 2 / K ≤ x → (B / x) ^ a * max (B ^ 2 / x - K) 0 = 0 := by
  have hK : 0 < K := lt_of_lt_of_le hB hBK
  refine ⟨?_, ?_⟩
  · rw [div_le_iff₀ hK]
    nlinarith
  · intro x hx
    have hm : 0 < B ^ 2 / K := by positivity
    have hx0 : 0 < x := lt_of_lt_of_le hm hx
    have h1 : B ^ 2 / x ≤ K := by
      rw [div_le_iff₀ hx0]
      rw [div_le_iff₀ hK] at hx
      linarith
    rw [max_eq_right (by linarith), mul_zero]

/-- **At r = q the mirror payoff is K/B puts** (The formula, after the table). When the bank rate
equals the dividend yield and `σ > 0`, the exponent is `a = -1`, and for barrier `B > 0`, strike
`K > 0` and every expiry price `x > 0` the mirror payoff `(B/x)^a (B²/x - K)⁺` equals
`(K/B)(B²/K - x)⁺`: `K/B` puts struck at `B²/K`. -/
theorem mirror_payoff_at_equal_rates_is_puts
    (r q σ B K : ℝ) (hrq : r = q) (hσ : 0 < σ) (hB : 0 < B) (hK : 0 < K) :
    2 * (r - q) / σ ^ 2 - 1 = -1 ∧
      ∀ x : ℝ, 0 < x →
        (B / x) ^ (2 * (r - q) / σ ^ 2 - 1) * max (B ^ 2 / x - K) 0
          = K / B * max (B ^ 2 / K - x) 0 := by
  have ha : 2 * (r - q) / σ ^ 2 - 1 = -1 := by subst hrq; simp
  refine ⟨ha, ?_⟩
  intro x hx
  rw [ha, Real.rpow_neg_one, inv_div, mul_max_of_nonneg _ _ (by positivity),
    mul_max_of_nonneg _ _ (by positivity), mul_zero, mul_zero]
  congr 1
  field_simp

-- House market: r = 5%, q = 2%, σ = 20% give the mirror exponent a = 1/2.
example : (2 * (5 / 100 - 2 / 100) / (20 / 100) ^ 2 - 1 : ℝ) = 1 / 2 := by norm_num
-- Barrier 80, strike 100: the mirror strike B²/K is 64 and the put ratio K/B is 5/4 (1.25 puts).
example : ((80 : ℝ) ^ 2 / 100) = 64 := by norm_num
example : ((100 : ℝ) / 80) = 5 / 4 := by norm_num

#print axioms mirror_term_obeys_black_scholes_and_matches_on_wall
#print axioms mirror_payoff_zero_at_or_above_mirror_strike
#print axioms mirror_payoff_at_equal_rates_is_puts
