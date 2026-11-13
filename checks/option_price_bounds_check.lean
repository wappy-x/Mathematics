-- Option price bounds: under no arbitrage a European call costs between max(S e^{-qT} - K e^{-rT}, 0) and S e^{-qT}, and a European put between max(K e^{-rT} - S e^{-qT}, 0) and K e^{-rT}.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Tactic.NormNum

open Real MeasureTheory

/-! Setting. `Ω` is the set of possible states of the world on expiry day, and `ST ω` is the
share price on expiry day in state `ω`; share prices are never negative. A payoff is a function
`Ω → ℝ`, the cash it pays on expiry day. `price` gives each payoff its price today.

No arbitrage (Step 0) is encoded as: `price` is linear (a bundle costs the sum of its legs) and
monotone (a payoff that pays at least as much in every state cannot cost less today).
Step 1's two known prices: one share delivered at expiry costs `S * exp (-(q * T))` today
(the share side), and one dollar delivered at expiry costs `exp (-(r * T))` today, so `K`
dollars cost `K * exp (-(r * T))` (the cash side). The European call pays `max (ST - K) 0`
and the European put pays `max (K - ST) 0`, both on expiry day only. -/

/-- The card's main claim. Under no arbitrage, with a share side `S e^{-qT}` and a cash side
`K e^{-rT}`, a European call costs no more than the share side and no less than the larger of
(share side minus cash side) and zero; a European put costs no more than the cash side and no
less than the larger of (cash side minus share side) and zero. -/
theorem option_price_bounds {Ω : Type*} (ST : Ω → ℝ) (hST : ∀ ω, 0 ≤ ST ω)
    (price : (Ω → ℝ) →ₗ[ℝ] ℝ) (hmono : Monotone price)
    (S K r q T : ℝ) (hK : 0 ≤ K)
    (hshare : price ST = S * exp (-(q * T)))
    (hcash : price (fun _ => 1) = exp (-(r * T))) :
    (max (S * exp (-(q * T)) - K * exp (-(r * T))) 0 ≤ price (fun ω => max (ST ω - K) 0) ∧
      price (fun ω => max (ST ω - K) 0) ≤ S * exp (-(q * T))) ∧
    (max (K * exp (-(r * T)) - S * exp (-(q * T))) 0 ≤ price (fun ω => max (K - ST ω) 0) ∧
      price (fun ω => max (K - ST ω) 0) ≤ K * exp (-(r * T))) := by
  have hC0 : price 0 ≤ price (fun ω => max (ST ω - K) 0) :=
    hmono (fun ω => by simp)
  have hP0 : price 0 ≤ price (fun ω => max (K - ST ω) 0) :=
    hmono (fun ω => by simp)
  rw [map_zero] at hC0 hP0
  have hC1 := hmono (show ST - K • (fun _ : Ω => (1:ℝ)) ≤ (fun ω => max (ST ω - K) 0) from
    fun ω => by simp)
  have hC2 := hmono (show (fun ω => max (ST ω - K) 0) ≤ ST from
    fun ω => max_le (by linarith) (hST ω))
  have hP1 := hmono (show K • (fun _ : Ω => (1:ℝ)) - ST ≤ (fun ω => max (K - ST ω) 0) from
    fun ω => by simp)
  have hP2 := hmono (show (fun ω => max (K - ST ω) 0) ≤ K • (fun _ : Ω => (1:ℝ)) from
    fun ω => by simp only [Pi.smul_apply, smul_eq_mul, mul_one]; exact max_le (by linarith [hST ω]) hK)
  rw [map_sub, map_smul, hcash, hshare, smul_eq_mul] at hC1 hP1
  rw [hshare] at hC2
  rw [map_smul, hcash, smul_eq_mul] at hP2
  exact ⟨⟨max_le hC1 hC0, hC2⟩, ⟨max_le hP1 hP0, hP2⟩⟩

/-- Step 5's model-free road: any rule of the form "average the payoff over a spread of expiry
prices, then discount" lands inside all four bounds, provided the expiry price is never
negative and averages to the forward price `S e^{(r-q)T}`. -/
theorem discounted_average_lies_within_bounds (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (S K r q T : ℝ) (hK : 0 ≤ K)
    (hnonneg : ∀ᵐ x ∂μ, 0 ≤ x) (hint : Integrable (fun x => x) μ)
    (hmean : ∫ x, x ∂μ = S * exp ((r - q) * T)) :
    (max (S * exp (-(q * T)) - K * exp (-(r * T))) 0 ≤ exp (-(r * T)) * ∫ x, max (x - K) 0 ∂μ ∧
      exp (-(r * T)) * ∫ x, max (x - K) 0 ∂μ ≤ S * exp (-(q * T))) ∧
    (max (K * exp (-(r * T)) - S * exp (-(q * T))) 0 ≤ exp (-(r * T)) * ∫ x, max (K - x) 0 ∂μ ∧
      exp (-(r * T)) * ∫ x, max (K - x) 0 ∂μ ≤ K * exp (-(r * T))) := by
  have he : exp (-(r * T)) * (S * exp ((r - q) * T)) = S * exp (-(q * T)) := by
    rw [mul_left_comm, ← exp_add]; congr 2; ring
  have hpos : 0 < exp (-(r * T)) := exp_pos _
  have hcI : Integrable (fun x => max (x - K) 0) μ := (hint.sub (integrable_const K)).pos_part
  have hpI : Integrable (fun x => max (K - x) 0) μ := ((integrable_const K).sub hint).pos_part
  have hc0 : 0 ≤ ∫ x, max (x - K) 0 ∂μ := integral_nonneg (fun x => le_max_right _ _)
  have hp0 : 0 ≤ ∫ x, max (K - x) 0 ∂μ := integral_nonneg (fun x => le_max_right _ _)
  have hc1 : ∫ x, (x - K) ∂μ ≤ ∫ x, max (x - K) 0 ∂μ :=
    integral_mono (hint.sub (integrable_const K)) hcI (fun x => le_max_left _ _)
  have hc2 : ∫ x, max (x - K) 0 ∂μ ≤ ∫ x, x ∂μ :=
    integral_mono_ae hcI hint (hnonneg.mono fun x hx => max_le (by linarith) hx)
  have hp1 : ∫ x, (K - x) ∂μ ≤ ∫ x, max (K - x) 0 ∂μ :=
    integral_mono ((integrable_const K).sub hint) hpI (fun x => le_max_left _ _)
  have hp2 : ∫ x, max (K - x) 0 ∂μ ≤ ∫ _x, K ∂μ :=
    integral_mono_ae hpI (integrable_const K) (hnonneg.mono fun x hx => max_le (by linarith) hK)
  rw [integral_sub hint (integrable_const K), integral_const, hmean] at hc1
  rw [integral_sub (integrable_const K) hint, integral_const, hmean] at hp1
  rw [integral_const] at hp2
  simp only [probReal_univ, smul_eq_mul, one_mul] at hc1 hp1 hp2
  rw [hmean] at hc2
  refine ⟨⟨max_le ?_ (mul_nonneg hpos.le hc0), ?_⟩, ⟨max_le ?_ (mul_nonneg hpos.le hp0), ?_⟩⟩
  · have := mul_le_mul_of_nonneg_left hc1 hpos.le
    rw [mul_sub, he] at this; linarith
  · have := mul_le_mul_of_nonneg_left hc2 hpos.le
    rw [he] at this; linarith
  · have := mul_le_mul_of_nonneg_left hp1 hpos.le
    rw [mul_sub, he] at this; linarith
  · have := mul_le_mul_of_nonneg_left hp2 hpos.le
    linarith

/-- The detailed proof's four expiry-day identities: each arbitrage trade's legs add up to a
payoff that never goes below zero, whatever the expiry price `x` (never negative) and strike
`K` (never negative). Call floor, call ceiling, put ceiling, put floor, in that order. -/
theorem arbitrage_legs_never_lose (x K : ℝ) (hx : 0 ≤ x) (hK : 0 ≤ K) :
    (max (x - K) 0 - x + K = max (K - x) 0 ∧ 0 ≤ max (K - x) 0) ∧
    (x - max (x - K) 0 = min x K ∧ 0 ≤ min x K) ∧
    (K - max (K - x) 0 = min x K ∧ 0 ≤ min x K) ∧
    (max (K - x) 0 + x - K = max (x - K) 0 ∧ 0 ≤ max (x - K) 0) := by
  refine ⟨⟨?_, le_max_right _ _⟩, ⟨?_, le_min hx hK⟩, ⟨?_, le_min hx hK⟩, ⟨?_, le_max_right _ _⟩⟩
  · rcases le_total x K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  · rcases le_total x K with h | h
    · rw [max_eq_right (by linarith), min_eq_left h]; ring
    · rw [max_eq_left (by linarith), min_eq_right h]; ring
  · rcases le_total x K with h | h
    · rw [max_eq_left (by linarith), min_eq_left h]; ring
    · rw [max_eq_right (by linarith), min_eq_right h]; ring
  · rcases le_total x K with h | h
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring

/-! The card's whole-number worked examples: the four trades' legs added up on expiry day,
at expiry prices 80, 100, 120 and 160 (strike 100, and strike 130 for the put floor). -/

-- Call under its floor (strike 100): legs add to 20, 0, 0, 0.
example : max ((80 : ℝ) - 100) 0 - 80 + 100 = 20 := by norm_num
example : max ((100 : ℝ) - 100) 0 - 100 + 100 = 0 := by norm_num
example : max ((120 : ℝ) - 100) 0 - 120 + 100 = 0 := by norm_num
example : max ((160 : ℝ) - 100) 0 - 160 + 100 = 0 := by norm_num
-- Call over its ceiling (strike 100): legs add to 80, 100, 100, 100.
example : (80 : ℝ) - max (80 - 100) 0 = 80 := by norm_num
example : (100 : ℝ) - max (100 - 100) 0 = 100 := by norm_num
example : (120 : ℝ) - max (120 - 100) 0 = 100 := by norm_num
example : (160 : ℝ) - max (160 - 100) 0 = 100 := by norm_num
-- Put over its ceiling (strike 100): legs add to 80, 100, 100, 100.
example : (100 : ℝ) - max (100 - 80) 0 = 80 := by norm_num
example : (100 : ℝ) - max (100 - 100) 0 = 100 := by norm_num
example : (100 : ℝ) - max (100 - 120) 0 = 100 := by norm_num
example : (100 : ℝ) - max (100 - 160) 0 = 100 := by norm_num
-- Put under its floor (strike 130): legs add to 0, 0, 0, 30.
example : max ((130 : ℝ) - 80) 0 + 80 - 130 = 0 := by norm_num
example : max ((130 : ℝ) - 100) 0 + 100 - 130 = 0 := by norm_num
example : max ((130 : ℝ) - 120) 0 + 120 - 130 = 0 := by norm_num
example : max ((130 : ℝ) - 160) 0 + 160 - 130 = 30 := by norm_num
-- Intrinsic value at the 130 strike with Acme at 100: 30 (not the put floor).
example : max ((130 : ℝ) - 100) 0 = 30 := by norm_num

#print axioms option_price_bounds
#print axioms discounted_average_lies_within_bounds
#print axioms arbitrage_legs_never_lose
