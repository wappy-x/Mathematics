-- Shape across strikes and expiries: if every never-negative payoff has a non-negative price, call prices fall in strike by at most the discounted strike gap, sit under the chord of their neighbours, and, at a matched moneyness, the normalized call never falls with expiry.
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.LinearAlgebra.Pi
import Mathlib.Tactic

open Real

/-!
The market is model-free. `Ω` is the set of possible outcomes, `S ω` is Acme's price at the
expiry in outcome `ω`, and `P` sends a payoff at the expiry to its price today. Holding a
portfolio prices it as the sum of its legs (`P` is linear), and Step 0 of the card says a payoff
that is never negative cannot have a negative price (`hpos`). The call at strike `K` costs
`P (fun ω => max (S ω - K) 0)`, and the discount factor `D` is the price of one dollar at expiry.
-/

/-- A positive linear pricing map is monotone: a payoff that is everywhere at most another
costs at most the other. -/
theorem price_mono_of_pos_linear
    {Ω : Type*} (P : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (hpos : ∀ f : Ω → ℝ, (∀ ω, 0 ≤ f ω) → 0 ≤ P f)
    (g h : Ω → ℝ) (hgh : ∀ ω, g ω ≤ h ω) : P g ≤ P h := by
  have := hpos (h - g) (fun ω => by simp only [Pi.sub_apply]; linarith [hgh ω])
  rw [map_sub] at this
  linarith

#print axioms price_mono_of_pos_linear

/-- The strike rules, inside one expiry. If prices are linear and a never-negative payoff never
has a negative price, then for strikes `K₁ < K₂ < K₃` evenly spaced: a call never costs more than
a lower-strike call, never less by more than the discounted gap `D (K₂ - K₁)`, and the
butterfly `C(K₁) - 2 C(K₂) + C(K₃)` is not negative. -/
theorem call_price_falls_capped_and_bends_up_in_strike
    {Ω : Type*} (P : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (hpos : ∀ f : Ω → ℝ, (∀ ω, 0 ≤ f ω) → 0 ≤ P f)
    (S : Ω → ℝ) (D K₁ K₂ K₃ : ℝ) (hD : P (fun _ => 1) = D)
    (h₁₂ : K₁ < K₂) (h₂₃ : K₂ < K₃) (heven : K₂ - K₁ = K₃ - K₂) :
    0 ≤ P (fun ω => max (S ω - K₁) 0) - P (fun ω => max (S ω - K₂) 0) ∧
    P (fun ω => max (S ω - K₁) 0) - P (fun ω => max (S ω - K₂) 0) ≤ D * (K₂ - K₁) ∧
    0 ≤ P (fun ω => max (S ω - K₁) 0) - 2 * P (fun ω => max (S ω - K₂) 0)
        + P (fun ω => max (S ω - K₃) 0) := by
  have hmono := price_mono_of_pos_linear P hpos
  refine ⟨?_, ?_, ?_⟩
  · have := hmono (fun ω => max (S ω - K₂) 0) (fun ω => max (S ω - K₁) 0)
      (fun ω => max_le_max (by linarith) le_rfl)
    linarith
  · have h := hmono (fun ω => max (S ω - K₁) 0)
      ((fun ω => max (S ω - K₂) 0) + (K₂ - K₁) • (fun _ => (1 : ℝ)))
      (fun ω => by
        simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, mul_one]
        rcases le_total (S ω - K₁) 0 with h | h
        · rw [max_eq_right h]
          linarith [le_max_right (S ω - K₂) 0]
        · rw [max_eq_left h]
          linarith [le_max_left (S ω - K₂) 0])
    rw [map_add, map_smul, hD, smul_eq_mul] at h
    linarith
  · have h := hmono ((fun ω => max (S ω - K₂) 0) + (fun ω => max (S ω - K₂) 0))
      ((fun ω => max (S ω - K₁) 0) + (fun ω => max (S ω - K₃) 0))
      (fun ω => by
        simp only [Pi.add_apply]
        rcases le_total (S ω - K₂) 0 with h | h
        · rw [max_eq_right h]
          linarith [le_max_right (S ω - K₁) 0, le_max_right (S ω - K₃) 0]
        · rw [max_eq_left h]
          linarith [le_max_left (S ω - K₁) 0, le_max_left (S ω - K₃) 0])
    rw [map_add, map_add] at h
    linarith

/-- Unequal spacing changes the weights, not the argument: for strikes `K₁ < K₂ < K₃` the middle
call costs at most the blend of the outer two with weights `(K₃ - K₂)/(K₃ - K₁)` on the low call
and `(K₂ - K₁)/(K₃ - K₁)` on the high one. -/
theorem call_price_below_chord_in_strike
    {Ω : Type*} (P : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (hpos : ∀ f : Ω → ℝ, (∀ ω, 0 ≤ f ω) → 0 ≤ P f)
    (S : Ω → ℝ) (K₁ K₂ K₃ : ℝ) (h₁₂ : K₁ < K₂) (h₂₃ : K₂ < K₃) :
    P (fun ω => max (S ω - K₂) 0) ≤
      (K₃ - K₂) / (K₃ - K₁) * P (fun ω => max (S ω - K₁) 0)
        + (K₂ - K₁) / (K₃ - K₁) * P (fun ω => max (S ω - K₃) 0) := by
  have hmono := price_mono_of_pos_linear P hpos
  have h13 : 0 < K₃ - K₁ := by linarith
  have h := hmono (fun ω => max (S ω - K₂) 0)
    (((K₃ - K₂) / (K₃ - K₁)) • (fun ω => max (S ω - K₁) 0)
      + ((K₂ - K₁) / (K₃ - K₁)) • (fun ω => max (S ω - K₃) 0))
    (fun ω => by
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div, le_div_iff₀ h13]
      have a1 := le_max_left (S ω - K₁) 0
      have a2 := le_max_right (S ω - K₁) 0
      have a3 := le_max_left (S ω - K₃) 0
      have a4 := le_max_right (S ω - K₃) 0
      rcases le_total (S ω - K₂) 0 with h | h
      · rw [max_eq_right h]
        nlinarith
      · rw [max_eq_left h]
        nlinarith)
  rw [map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul] at h
  exact h

/-- The calendar rule. Two expiries `T₁ < T₂`; `P₁` prices payoffs at the near expiry, `S₁ ω` is
Acme's price there, and `V ω` is what the far call (strike `K₂`, still alive for `T₂ - T₁` years)
is worth there. The far call costs `P₁ V` today, the near call costs
`P₁ (fun ω => max (S₁ ω - K₁) 0)`, and the far call's worth at the near expiry is at least zero
and at least its forward intrinsic `S₁ e^{-q(T₂-T₁)} - K₂ e^{-r(T₂-T₁)}`. With the forward
`F(T) = S e^{(r-q)T}` and the discount factor `D(T) = e^{-rT}`, if the two strikes have the same
moneyness `K₁ / F(T₁) = K₂ / F(T₂)`, then the near call divided by `D(T₁) F(T₁)` is at most the
far call divided by `D(T₂) F(T₂)`. -/
theorem normalized_call_never_falls_with_expiry
    {Ω : Type*} (P₁ : (Ω → ℝ) →ₗ[ℝ] ℝ)
    (hpos : ∀ f : Ω → ℝ, (∀ ω, 0 ≤ f ω) → 0 ≤ P₁ f)
    (S₁ V : Ω → ℝ) (S r q T₁ T₂ K₁ K₂ C₁ C₂ : ℝ)
    (hS : 0 < S) (hT : T₁ < T₂)
    (hC₁ : C₁ = P₁ (fun ω => max (S₁ ω - K₁) 0)) (hC₂ : C₂ = P₁ V)
    (hV₀ : ∀ ω, 0 ≤ V ω)
    (hVfwd : ∀ ω, S₁ ω * exp (-q * (T₂ - T₁)) - K₂ * exp (-r * (T₂ - T₁)) ≤ V ω)
    (hmatch : K₁ / (S * exp ((r - q) * T₁)) = K₂ / (S * exp ((r - q) * T₂))) :
    C₁ / (exp (-r * T₁) * (S * exp ((r - q) * T₁))) ≤
      C₂ / (exp (-r * T₂) * (S * exp ((r - q) * T₂))) := by
  set a := exp (-q * (T₂ - T₁)) with ha_def
  set b := exp (-r * (T₂ - T₁)) with hb_def
  have ha : 0 < a := exp_pos _
  -- matched moneyness gives `K₂ b = K₁ a`
  have hm : K₁ * exp ((r - q) * T₂) = K₂ * exp ((r - q) * T₁) := by
    have hF1 : 0 < S * exp ((r - q) * T₁) := mul_pos hS (exp_pos _)
    have hF2 : 0 < S * exp ((r - q) * T₂) := mul_pos hS (exp_pos _)
    rw [div_eq_div_iff hF1.ne' hF2.ne'] at hmatch
    have : S * (K₁ * exp ((r - q) * T₂)) = S * (K₂ * exp ((r - q) * T₁)) := by
      linarith
    exact mul_left_cancel₀ hS.ne' this
  set c := exp (-r * T₂ + q * T₁) with hc_def
  have hac : a = exp ((r - q) * T₂) * c := by
    rw [ha_def, hc_def, ← exp_add]; congr 1; ring
  have hbc : b = exp ((r - q) * T₁) * c := by
    rw [hb_def, hc_def, ← exp_add]; congr 1; ring
  have hK : K₂ * b = K₁ * a := by
    rw [hac, hbc]; linear_combination (-c) * hm
  -- the far call dominates `a` copies of the near call's payoff
  have key : a * C₁ ≤ C₂ := by
    have h := price_mono_of_pos_linear P₁ hpos
      (a • (fun ω => max (S₁ ω - K₁) 0)) V
      (fun ω => by
        simp only [Pi.smul_apply, smul_eq_mul]
        rcases le_total (S₁ ω - K₁) 0 with h | h
        · rw [max_eq_right h]
          linarith [hV₀ ω]
        · rw [max_eq_left h]
          have := hVfwd ω
          rw [hK] at this
          linarith)
    rw [map_smul, smul_eq_mul] at h
    rw [hC₁, hC₂]
    exact h
  have e1 : exp (-r * T₁) * (S * exp ((r - q) * T₁)) = S * exp (-q * T₁) := by
    rw [mul_left_comm, ← exp_add]; congr 2; ring
  have e2 : exp (-r * T₂) * (S * exp ((r - q) * T₂)) = S * exp (-q * T₁) * a := by
    rw [mul_left_comm, ← exp_add, mul_assoc, ha_def, ← exp_add]; congr 2; ring
  have hd : 0 < S * exp (-q * T₁) := mul_pos hS (exp_pos _)
  rw [e1, e2, div_le_div_iff₀ hd (mul_pos hd ha)]
  nlinarith

-- Step 2's tent, the 90/100/110 butterfly payoff, at the four finishes the card checks.
example : max (85 - 90 : ℤ) 0 - 2 * max (85 - 100) 0 + max (85 - 110) 0 = 0 := by norm_num
example : max (95 - 90 : ℤ) 0 - 2 * max (95 - 100) 0 + max (95 - 110) 0 = 5 := by norm_num
example : max (105 - 90 : ℤ) 0 - 2 * max (105 - 100) 0 + max (105 - 110) 0 = 5 := by norm_num
example : max (130 - 90 : ℤ) 0 - 2 * max (130 - 100) 0 + max (130 - 110) 0 = 0 := by norm_num

-- Step 1's 90/100 call spread pays 5 at 95 and 10 above 100 (here at 130).
example : max (95 - 90 : ℤ) 0 - max (95 - 100) 0 = 5 := by norm_num
example : max (130 - 90 : ℤ) 0 - max (130 - 100) 0 = 10 := by norm_num

-- Strikes 90, 100, 120: the weights are two parts of the 90-call to one of the 120-call.
example : ((120 - 100 : ℚ) / (120 - 90), (100 - 90 : ℚ) / (120 - 90)) = (2 / 3, 1 / 3) := by
  norm_num

-- The hand-made sheet, in cents: the 90/100/110 butterfly hands over 90 cents,
-- and the 120-call quoted above the 110-call hands over 20 cents.
example : (2 * 1060 - 1510 - 520 : ℤ) = 90 := by norm_num
example : (540 - 520 : ℤ) = 20 := by norm_num

#print axioms call_price_falls_capped_and_bends_up_in_strike
#print axioms call_price_below_chord_in_strike
#print axioms normalized_call_never_falls_with_expiry
