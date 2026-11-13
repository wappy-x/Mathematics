-- State prices: in a one-period market with two endings, the stock and the bank fix one price for a dollar paid in each ending, those prices price every payoff, rescaled they become weights adding to one, and no free money exists exactly when both are positive.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity

/-!
Setting, as on the card.

* `S0` is Acme's price today; `Su` and `Sd` are what Acme is worth in the up and down states.
* `R` is what 1 in the bank becomes over the period, so `R⁻¹` is the discount factor `D`,
  today's price of a dollar paid in both states.
* A pair `(ψu, ψd)` is a pair of state prices when it prices the two traded things:
  `ψu + ψd = D` (the bank) and `ψu * Su + ψd * Sd = S0` (Acme).
* A portfolio is `Δ` shares of Acme and `c` dollars in the bank. It costs `Δ * S0 + c`
  today and pays `Δ * Su + c * R` in the up state and `Δ * Sd + c * R` in the down state.
  Any real `Δ` and `c` are allowed: long or short, any size, no fees.
* The risk-neutral weights are `qu = ψu / D` and `qd = ψd / D`.
-/

/-- Free money: a portfolio of Acme and cash that costs nothing or less today, never pays
less than nothing, and pays something in at least one state. -/
def IsFreeMoney (S0 Su Sd R Δ c : ℝ) : Prop :=
  Δ * S0 + c ≤ 0 ∧ 0 ≤ Δ * Su + c * R ∧ 0 ≤ Δ * Sd + c * R ∧
    (0 < Δ * Su + c * R ∨ 0 < Δ * Sd + c * R)

lemma sp_price_identity (S0 Su Sd R ψu ψd Δ c : ℝ) (hR : R ≠ 0)
    (hbank : ψu + ψd = R⁻¹) (hacme : ψu * Su + ψd * Sd = S0) :
    Δ * S0 + c = ψu * (Δ * Su + c * R) + ψd * (Δ * Sd + c * R) := by
  have hRR : R * R⁻¹ = 1 := mul_inv_cancel₀ hR
  linear_combination (-Δ) * hacme + (-c * R) * hbank - c * hRR

lemma sp_psi_up (S0 Su Sd R ψu ψd : ℝ) (hR : R ≠ 0)
    (hbank : ψu + ψd = R⁻¹) (hacme : ψu * Su + ψd * Sd = S0) :
    R * ψu * (Su - Sd) = R * S0 - Sd := by
  have hRR : R * R⁻¹ = 1 := mul_inv_cancel₀ hR
  linear_combination R * hacme - R * Sd * hbank - Sd * hRR

lemma sp_psi_down (S0 Su Sd R ψu ψd : ℝ) (hR : R ≠ 0)
    (hbank : ψu + ψd = R⁻¹) (hacme : ψu * Su + ψd * Sd = S0) :
    R * ψd * (Su - Sd) = Su - R * S0 := by
  have hRR : R * R⁻¹ = 1 := mul_inv_cancel₀ hR
  linear_combination -R * hacme + R * Su * hbank + Su * hRR

#print axioms sp_price_identity
#print axioms sp_psi_up
#print axioms sp_psi_down

/-- The card's main claim. With two states, a bank and a stock that pays different amounts
in the two states, the two traded prices fix the state prices: exactly one pair solves
`ψu + ψd = D` and `ψu * Su + ψd * Sd = S0`, namely `ψu = (S0 - D Sd)/(Su - Sd)` and
`ψd = (D Su - S0)/(Su - Sd)`. Every payoff `(Hu, Hd)` can be copied with shares and cash,
and any such copy costs `ψu Hu + ψd Hd`. Rescaled by `D`, the state prices become weights
`qu`, `qd` adding to one, with `qu = (R S0 - Sd)/(Su - Sd)`; the price is the discounted
average `D (qu Hu + qd Hd)`, and under those weights Acme averages `R S0`. -/
theorem state_prices_price_every_payoff (S0 Su Sd R : ℝ) (hR : R ≠ 0) (hS : Su ≠ Sd) :
    (∃! ψ : ℝ × ℝ, ψ.1 + ψ.2 = R⁻¹ ∧ ψ.1 * Su + ψ.2 * Sd = S0) ∧
    ∀ ψu ψd : ℝ, ψu + ψd = R⁻¹ → ψu * Su + ψd * Sd = S0 →
      ψu = (S0 - R⁻¹ * Sd) / (Su - Sd) ∧ ψd = (R⁻¹ * Su - S0) / (Su - Sd) ∧
      (∀ Hu Hd : ℝ, ∃ Δ c : ℝ, Δ * Su + c * R = Hu ∧ Δ * Sd + c * R = Hd) ∧
      (∀ Hu Hd Δ c : ℝ, Δ * Su + c * R = Hu → Δ * Sd + c * R = Hd →
        Δ * S0 + c = ψu * Hu + ψd * Hd) ∧
      ψu / R⁻¹ + ψd / R⁻¹ = 1 ∧
      ψu / R⁻¹ = (R * S0 - Sd) / (Su - Sd) ∧
      (∀ Hu Hd : ℝ, ψu * Hu + ψd * Hd = R⁻¹ * (ψu / R⁻¹ * Hu + ψd / R⁻¹ * Hd)) ∧
      ψu / R⁻¹ * Su + ψd / R⁻¹ * Sd = R * S0 := by
  have hd : Su - Sd ≠ 0 := sub_ne_zero.mpr hS
  have key : ∀ ψu ψd : ℝ, ψu + ψd = R⁻¹ → ψu * Su + ψd * Sd = S0 →
      ψu = (S0 - R⁻¹ * Sd) / (Su - Sd) ∧ ψd = (R⁻¹ * Su - S0) / (Su - Sd) := by
    intro ψu ψd hb ha
    constructor
    · rw [eq_div_iff hd]; linear_combination ha - Sd * hb
    · rw [eq_div_iff hd]; linear_combination -ha + Su * hb
  refine ⟨⟨((S0 - R⁻¹ * Sd) / (Su - Sd), (R⁻¹ * Su - S0) / (Su - Sd)), ⟨?_, ?_⟩, ?_⟩, ?_⟩
  · field_simp; ring
  · field_simp; ring
  · rintro ⟨a, b⟩ ⟨hb, ha⟩
    obtain ⟨h1, h2⟩ := key a b hb ha
    simp only [Prod.mk.injEq]; exact ⟨h1, h2⟩
  · intro ψu ψd hb ha
    obtain ⟨h1, h2⟩ := key ψu ψd hb ha
    refine ⟨h1, h2, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · intro Hu Hd
      refine ⟨(Hu - Hd) / (Su - Sd), (Hd * Su - Hu * Sd) / ((Su - Sd) * R), ?_, ?_⟩
      · field_simp; ring
      · field_simp; ring
    · intro Hu Hd Δ c e1 e2
      rw [← e1, ← e2]; exact sp_price_identity S0 Su Sd R ψu ψd Δ c hR hb ha
    · rw [← add_div, hb, div_self (inv_ne_zero hR)]
    · rw [div_inv_eq_mul, eq_div_iff hd]
      linear_combination sp_psi_up S0 Su Sd R ψu ψd hR hb ha
    · intro Hu Hd
      field_simp
    · rw [div_inv_eq_mul, div_inv_eq_mul]; linear_combination R * ha

/-- No arbitrage exactly when every state price is positive (the first fundamental theorem
of asset pricing, in one period with two states): in the same market, no portfolio of Acme
and cash is free money if and only if both state prices are above zero. -/
theorem no_free_money_iff_state_prices_positive (S0 Su Sd R ψu ψd : ℝ) (hR : R ≠ 0)
    (hS : Su ≠ Sd) (hbank : ψu + ψd = R⁻¹) (hacme : ψu * Su + ψd * Sd = S0) :
    (∀ Δ c : ℝ, ¬ IsFreeMoney S0 Su Sd R Δ c) ↔ (0 < ψu ∧ 0 < ψd) := by
  have hd : Su - Sd ≠ 0 := sub_ne_zero.mpr hS
  have P := fun Δ c => sp_price_identity S0 Su Sd R ψu ψd Δ c hR hbank hacme
  constructor
  · intro h
    constructor
    · by_contra hu
      push Not at hu
      apply h (1 / (Su - Sd)) (-Sd / ((Su - Sd) * R))
      have e1 : 1 / (Su - Sd) * Su + -Sd / ((Su - Sd) * R) * R = 1 := by field_simp; ring
      have e2 : 1 / (Su - Sd) * Sd + -Sd / ((Su - Sd) * R) * R = 0 := by field_simp; ring
      unfold IsFreeMoney
      rw [P, e1, e2]
      refine ⟨by linarith, by norm_num, le_refl _, Or.inl one_pos⟩
    · by_contra hu
      push Not at hu
      apply h (-1 / (Su - Sd)) (Su / ((Su - Sd) * R))
      have e1 : -1 / (Su - Sd) * Su + Su / ((Su - Sd) * R) * R = 0 := by field_simp; ring
      have e2 : -1 / (Su - Sd) * Sd + Su / ((Su - Sd) * R) * R = 1 := by field_simp; ring
      unfold IsFreeMoney
      rw [P, e1, e2]
      refine ⟨by linarith, le_refl _, by norm_num, Or.inr one_pos⟩
  · rintro ⟨hu, hdn⟩ Δ c ⟨hc, hpu, hpd, hpos⟩
    rw [P] at hc
    rcases hpos with h | h
    · have := mul_pos hu h
      have := mul_nonneg hdn.le hpd
      linarith
    · have := mul_nonneg hu.le hpu
      have := mul_pos hdn h
      linarith

/-- The band for the bank. With a positive bank factor and Acme higher in the up state than
in the down state, both state prices are positive exactly when the banked price sits strictly
between Acme's two endings: `Sd < R S0 < Su`. -/
theorem state_prices_positive_iff_bank_inside_band (S0 Su Sd R ψu ψd : ℝ) (hR : 0 < R)
    (hS : Sd < Su) (hbank : ψu + ψd = R⁻¹) (hacme : ψu * Su + ψd * Sd = S0) :
    (0 < ψu ∧ 0 < ψd) ↔ (Sd < R * S0 ∧ R * S0 < Su) := by
  have e1 := sp_psi_up S0 Su Sd R ψu ψd hR.ne' hbank hacme
  have e2 := sp_psi_down S0 Su Sd R ψu ψd hR.ne' hbank hacme
  have hd : 0 < Su - Sd := sub_pos.mpr hS
  constructor
  · rintro ⟨hu, hdn⟩
    have a := mul_pos (mul_pos hR hu) hd
    have b := mul_pos (mul_pos hR hdn) hd
    constructor <;> linarith
  · rintro ⟨h1, h2⟩
    have hRd := mul_pos hR hd
    constructor
    · have : 0 < R * ψu * (Su - Sd) := by linarith
      have : R * ψu * (Su - Sd) = ψu * (R * (Su - Sd)) := by ring
      exact pos_of_mul_pos_left (by linarith) hRd.le
    · have : 0 < R * ψd * (Su - Sd) := by linarith
      have : R * ψd * (Su - Sd) = ψd * (R * (Su - Sd)) := by ring
      exact pos_of_mul_pos_left (by linarith) hRd.le


/-! Worked numbers from the card, as exact fractions. Acme is 100 today and 120 or 90 in a
year; the bank turns 20 into 21, so `R = 21/20` and a sure dollar costs `20/21`. -/

-- The two tickets: 10/21 each (0.476190), adding to the sure dollar's 20/21 (0.952381).
example : ((100 : ℚ) - 20 / 21 * 90) / (120 - 90) = 10 / 21 ∧
    ((20 : ℚ) / 21 * 120 - 100) / (120 - 90) = 10 / 21 ∧
    (10 / 21 : ℚ) + 10 / 21 = 20 / 21 ∧ (21 / 20 : ℚ)⁻¹ = 20 / 21 := by norm_num

-- Acme priced as 120 up tickets and 90 down tickets: 100.
example : (120 : ℚ) * (10 / 21) + 90 * (10 / 21) = 100 := by norm_num

-- The call (20 up tickets) costs 200/21 (9.523810), the put (10 down tickets) 100/21
-- (4.761905); call minus put equals Acme minus 100 sure dollars.
example : (20 : ℚ) * (10 / 21) = 200 / 21 ∧ (10 : ℚ) * (10 / 21) = 100 / 21 ∧
    (200 / 21 : ℚ) - 100 / 21 = 100 - 100 * (20 / 21) := by norm_num

-- The forward at 105 pays 15 up and -15 down, and costs 0.
example : (10 / 21 : ℚ) * 15 + (10 / 21) * (-15) = 0 := by norm_num

-- The up ticket copied: 1/30 of a share (0.033333) and -20/7 in cash (-2.857143) pay 1 up,
-- 0 down, and cost 10/21.
example : (1 / 30 : ℚ) * 120 + (-20 / 7) * (21 / 20) = 1 ∧
    (1 / 30 : ℚ) * 90 + (-20 / 7) * (21 / 20) = 0 ∧
    (1 / 30 : ℚ) * 100 + (-20 / 7) = 10 / 21 := by norm_num

-- The risk-neutral weights are 1/2 and 1/2; 105 sits halfway between 90 and 120; the call
-- as a discounted average is 200/21; under the weights Acme averages 105 = 100 × 21/20.
example : (10 / 21 : ℚ) / (20 / 21) = 1 / 2 ∧
    ((21 / 20 : ℚ) * 100 - 90) / (120 - 90) = 1 / 2 ∧
    (20 / 21 : ℚ) * (1 / 2 * 20 + 1 / 2 * 0) = 200 / 21 ∧
    (1 / 2 : ℚ) * 120 + 1 / 2 * 90 = 105 ∧ (21 / 20 : ℚ) * 100 = 105 := by norm_num

-- What breaks. Real odds 7/10 at the bank's rate give 40/3 (13.333333); at Acme's real
-- average of 111 (11 percent) they give 1400/111 (12.612613); the weights without the
-- discount give 10; the only rate that works is 147/100, i.e. 47 percent.
example : (20 / 21 : ℚ) * (7 / 10 * 20 + 3 / 10 * 0) = 40 / 3 ∧
    (7 / 10 : ℚ) * 120 + 3 / 10 * 90 = 111 ∧
    (7 / 10 * 20 : ℚ) / (111 / 100) = 1400 / 111 ∧
    (1 / 2 : ℚ) * 20 + 1 / 2 * 0 = 10 ∧
    (7 / 10 * 20 : ℚ) / (200 / 21) = 147 / 100 := by norm_num

-- A bank factor of 5/4 (1.25), outside the band: the down ticket costs -2/15 (-0.133333),
-- and selling one share while lending 100 leaves 5 up and 35 down.
example : ((5 / 4 : ℚ)⁻¹ * 120 - 100) / (120 - 90) = -2 / 15 ∧
    (-1 : ℚ) * 120 + 100 * (5 / 4) = 5 ∧ (-1 : ℚ) * 90 + 100 * (5 / 4) = 35 ∧
    (-1 : ℚ) * 100 + 100 = 0 := by norm_num

-- The band for this market: 90 < 105 < 120.
example : (90 : ℚ) < 21 / 20 * 100 ∧ (21 / 20 : ℚ) * 100 < 120 := by norm_num

#print axioms state_prices_price_every_payoff
#print axioms no_free_money_iff_state_prices_positive
#print axioms state_prices_positive_iff_bank_inside_band
