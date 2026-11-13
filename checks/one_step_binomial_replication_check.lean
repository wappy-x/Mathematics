-- One step: in a market where the share ends at one of two prices, exactly one holding of shares and cash copies any contract, and once the forward factor sits strictly between the two moves, the only price that leaves no free money is that copy's cost.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic

namespace OneStepBinomial

/-! The model. The share costs `S` today and ends at `S * u` (up) or `S * d` (down) after `T`
years. The bank grows cash by `exp (r * T)`. The share pays a dividend yield `q`, reinvested in
more shares, so holding `Δ` shares at delivery takes `Δ * exp (-q * T)` shares today. -/

/-- What `Δ` shares at delivery and `B` in the bank today pay at delivery when the share ends at
price `x`. -/
noncomputable def payAt (r T Δ B x : ℝ) : ℝ :=
  Δ * x + B * Real.exp (r * T)

/-- The holding `(Δ, B)` copies the contract: it pays `Hu` in the up state and `Hd` in the
down state. -/
def Copies (S u d r T Hu Hd Δ B : ℝ) : Prop :=
  payAt r T Δ B (S * u) = Hu ∧ payAt r T Δ B (S * d) = Hd

/-- What the holding `(Δ, B)` costs today: the shares, made cheaper by the dividends they earn
before delivery, plus the cash in the bank. -/
noncomputable def copyCost (S q T Δ B : ℝ) : ℝ :=
  Δ * S * Real.exp (-q * T) + B

/-- The card's hedge ratio: shares held at delivery. -/
noncomputable def hedgeRatio (S u d Hu Hd : ℝ) : ℝ :=
  (Hu - Hd) / (S * (u - d))

/-- The card's bank balance today. -/
noncomputable def bankBalance (u d r T Hu Hd : ℝ) : ℝ :=
  Real.exp (-r * T) * ((u * Hd - d * Hu) / (u - d))

/-- A position of `a` shares at delivery, `b` in the bank today and `c` contracts, with the
contract quoted at `P` today, is an arbitrage: it costs nothing (or less) to open, never pays
less than zero at delivery, and pays more than zero in at least one state. -/
def IsArbitrage (S u d r q T Hu Hd P a b c : ℝ) : Prop :=
  copyCost S q T a b + c * P ≤ 0 ∧
    0 ≤ payAt r T a b (S * u) + c * Hu ∧
    0 ≤ payAt r T a b (S * d) + c * Hd ∧
    (0 < payAt r T a b (S * u) + c * Hu ∨ 0 < payAt r T a b (S * d) + c * Hd)

/-- With the contract quoted at `P`, no position in shares, cash and contracts is an arbitrage. -/
def NoArbitrage (S u d r q T Hu Hd P : ℝ) : Prop :=
  ∀ a b c, ¬ IsArbitrage S u d r q T Hu Hd P a b c

/-- The market of the share and the bank alone has no arbitrage (no contracts held). -/
def ShareBankNoArbitrage (S u d r q T : ℝ) : Prop :=
  ∀ a b, ¬ IsArbitrage S u d r q T 0 0 0 a b 0

lemma exp_fwd_eq (r q T : ℝ) :
    Real.exp ((r - q) * T) = Real.exp (r * T) * Real.exp (-q * T) := by
  rw [← Real.exp_add]; ring_nf

#print axioms exp_fwd_eq

lemma exp_neg_mul_exp (r T : ℝ) : Real.exp (-r * T) * Real.exp (r * T) = 1 := by
  rw [← Real.exp_add]; simp

#print axioms exp_neg_mul_exp

/-- Core no-arbitrage fact for the share and the bank, under the band. -/
lemma share_bank_core (S u d r q T a b : ℝ)
    (hd : d < Real.exp ((r - q) * T)) (hu : Real.exp ((r - q) * T) < u)
    (hcost : copyCost S q T a b ≤ 0)
    (hX : 0 ≤ payAt r T a b (S * u)) (hY : 0 ≤ payAt r T a b (S * d))
    (hpos : 0 < payAt r T a b (S * u) ∨ 0 < payAt r T a b (S * d)) : False := by
  unfold copyCost at hcost
  unfold payAt at hX hY hpos
  have hE : 0 < Real.exp (r * T) := Real.exp_pos _
  have hF := exp_fwd_eq r q T
  set E := Real.exp (r * T)
  set G := Real.exp (-q * T)
  set F := Real.exp ((r - q) * T)
  have hZ : a * S * F + b * E ≤ 0 := by
    have := mul_nonpos_of_nonneg_of_nonpos hE.le hcost
    rw [hF]; nlinarith
  have hid : (F - d) * (a * (S * u) + b * E) + (u - F) * (a * (S * d) + b * E)
      = (u - d) * (a * S * F + b * E) := by ring
  have h1 : 0 ≤ (u - F) * (a * (S * d) + b * E) := mul_nonneg (by linarith) hY
  have h2 : 0 ≤ (F - d) * (a * (S * u) + b * E) := mul_nonneg (by linarith) hX
  have h3 : (u - d) * (a * S * F + b * E) ≤ 0 :=
    mul_nonpos_of_nonneg_of_nonpos (by linarith) hZ
  rcases hpos with h | h
  · have := mul_pos (show (0:ℝ) < F - d by linarith) h
    linarith
  · have := mul_pos (show (0:ℝ) < u - F by linarith) h
    linarith

#print axioms share_bank_core

lemma hedge_copies (S u d r T Hu Hd : ℝ) (hS : 0 < S) (hud : d < u) :
    Copies S u d r T Hu Hd (hedgeRatio S u d Hu Hd) (bankBalance u d r T Hu Hd) := by
  have h1 := exp_neg_mul_exp r T
  have hne : u - d ≠ 0 := sub_ne_zero.mpr hud.ne'
  have hS0 : S ≠ 0 := hS.ne'
  unfold Copies payAt hedgeRatio bankBalance
  constructor
  · have : Real.exp (-r * T) * ((u * Hd - d * Hu) / (u - d)) * Real.exp (r * T)
        = (u * Hd - d * Hu) / (u - d) := by
      rw [mul_comm _ (Real.exp (r * T)), ← mul_assoc, mul_comm (Real.exp (r * T)), h1, one_mul]
    rw [this]; field_simp; ring
  · have : Real.exp (-r * T) * ((u * Hd - d * Hu) / (u - d)) * Real.exp (r * T)
        = (u * Hd - d * Hu) / (u - d) := by
      rw [mul_comm _ (Real.exp (r * T)), ← mul_assoc, mul_comm (Real.exp (r * T)), h1, one_mul]
    rw [this]; field_simp; ring

#print axioms hedge_copies

/-- One step, two states, two instruments, one hedge. Take a share at `S > 0` that ends at
`S * u` or `S * d` with `u > d`, a bank growing cash by `exp (r * T)`, a dividend yield `q`, and
the forward factor strictly inside the band, `d < exp ((r - q) * T) < u`. Then for any payments
`Hu` (up) and `Hd` (down):
(1) a holding of shares and cash copies the contract exactly when the shares held at delivery are
`(Hu - Hd) / (S * (u - d))` and the cash today is `exp (-r * T) * (u * Hd - d * Hu) / (u - d)`,
so the copy exists and is the only one; and
(2) with the contract also trading at `P`, there is no arbitrage exactly when `P` equals that
copy's cost today. -/
theorem one_step_replication_price
    (S u d r q T Hu Hd P : ℝ) (hS : 0 < S) (hud : d < u)
    (hd : d < Real.exp ((r - q) * T)) (hu : Real.exp ((r - q) * T) < u) :
    (∀ Δ B, Copies S u d r T Hu Hd Δ B ↔
        Δ = hedgeRatio S u d Hu Hd ∧ B = bankBalance u d r T Hu Hd) ∧
      (NoArbitrage S u d r q T Hu Hd P ↔
        P = copyCost S q T (hedgeRatio S u d Hu Hd) (bankBalance u d r T Hu Hd)) := by
  have hne : u - d ≠ 0 := sub_ne_zero.mpr hud.ne'
  have hS0 : S ≠ 0 := hS.ne'
  have hE : 0 < Real.exp (r * T) := Real.exp_pos _
  have h1 := exp_neg_mul_exp r T
  have hcopy := hedge_copies S u d r T Hu Hd hS hud
  refine ⟨fun Δ B => ?_, ?_⟩
  · constructor
    · rintro ⟨hup, hdn⟩
      obtain ⟨hup0, hdn0⟩ := hcopy
      unfold payAt at hup hdn hup0 hdn0
      set Δ0 := hedgeRatio S u d Hu Hd
      set B0 := bankBalance u d r T Hu Hd
      have hΔ : (Δ - Δ0) * (S * (u - d)) = 0 := by linear_combination hup - hdn - hup0 + hdn0
      have hSud : S * (u - d) ≠ 0 := mul_ne_zero hS0 hne
      have hΔ' : Δ = Δ0 := by
        have := (mul_eq_zero.mp hΔ).resolve_right hSud
        linarith
      refine ⟨hΔ', ?_⟩
      have hB : (B - B0) * Real.exp (r * T) = 0 := by
        rw [hΔ'] at hup; linear_combination hup - hup0
      have := (mul_eq_zero.mp hB).resolve_right hE.ne'
      linarith
    · rintro ⟨rfl, rfl⟩; exact hcopy
  · obtain ⟨hup0, hdn0⟩ := hcopy
    set Δ0 := hedgeRatio S u d Hu Hd
    set B0 := bankBalance u d r T Hu Hd
    constructor
    · intro hna
      by_contra hP
      rcases lt_or_gt_of_ne hP with hlt | hgt
      · -- P below the copy's cost: buy the contract, sell the copy
        apply hna (-Δ0) (-B0 + (copyCost S q T Δ0 B0 - P)) 1
        unfold payAt at hup0 hdn0
        have hε : 0 < copyCost S q T Δ0 B0 - P := by linarith
        have hεE := mul_pos hε hE
        refine ⟨?_, ?_, ?_, Or.inl ?_⟩
        · unfold copyCost at *; linarith
        · unfold payAt; nlinarith
        · unfold payAt; nlinarith
        · unfold payAt; nlinarith
      · -- P above the copy's cost: sell the contract, buy the copy
        apply hna Δ0 (B0 + (P - copyCost S q T Δ0 B0)) (-1)
        unfold payAt at hup0 hdn0
        have hε : 0 < P - copyCost S q T Δ0 B0 := by linarith
        have hεE := mul_pos hε hE
        refine ⟨?_, ?_, ?_, Or.inl ?_⟩
        · unfold copyCost at *; linarith
        · unfold payAt; nlinarith
        · unfold payAt; nlinarith
        · unfold payAt; nlinarith
    · intro hP a b c harb
      obtain ⟨hc, hX, hY, hpos⟩ := harb
      apply share_bank_core S u d r q T (a + c * Δ0) (b + c * B0) hd hu
      · have : copyCost S q T (a + c * Δ0) (b + c * B0) = copyCost S q T a b + c * P := by
          rw [hP]; unfold copyCost; ring
        linarith
      · have : payAt r T (a + c * Δ0) (b + c * B0) (S * u) = payAt r T a b (S * u) + c * Hu := by
          rw [← hup0]; unfold payAt; ring
        linarith
      · have : payAt r T (a + c * Δ0) (b + c * B0) (S * d) = payAt r T a b (S * d) + c * Hd := by
          rw [← hdn0]; unfold payAt; ring
        linarith
      · have e1 : payAt r T (a + c * Δ0) (b + c * B0) (S * u) = payAt r T a b (S * u) + c * Hu := by
          rw [← hup0]; unfold payAt; ring
        have e2 : payAt r T (a + c * Δ0) (b + c * B0) (S * d) = payAt r T a b (S * d) + c * Hd := by
          rw [← hdn0]; unfold payAt; ring
        rw [e1, e2]; exact hpos

/-- The band is exactly right: with `S > 0` and `u > d`, the share and the bank alone admit no
arbitrage exactly when the forward factor lies strictly between the two moves,
`d < exp ((r - q) * T) < u`. -/
theorem share_bank_no_arbitrage_iff_band
    (S u d r q T : ℝ) (hS : 0 < S) (hud : d < u) :
    ShareBankNoArbitrage S u d r q T ↔
      d < Real.exp ((r - q) * T) ∧ Real.exp ((r - q) * T) < u := by
  have hE : 0 < Real.exp (r * T) := Real.exp_pos _
  have hF := exp_fwd_eq r q T
  constructor
  · intro hna
    by_contra hband
    rw [not_and_or, not_lt, not_lt] at hband
    rcases hband with h | h
    · -- forward at or below d: buy one share with borrowed cash
      apply hna 1 (-(S * Real.exp (-q * T)))
      refine ⟨?_, ?_, ?_, Or.inl ?_⟩
      · unfold copyCost; simp
      · unfold payAt; rw [hF] at h; nlinarith
      · unfold payAt; rw [hF] at h; nlinarith
      · unfold payAt; rw [hF] at h; nlinarith
    · -- forward at or above u: sell one share, bank the cash
      apply hna (-1) (S * Real.exp (-q * T))
      refine ⟨?_, ?_, ?_, Or.inr ?_⟩
      · unfold copyCost; simp
      · unfold payAt; rw [hF] at h; nlinarith
      · unfold payAt; rw [hF] at h; nlinarith
      · unfold payAt; rw [hF] at h; nlinarith
  · rintro ⟨hd, hu⟩ a b ⟨hc, hX, hY, hpos⟩
    simp only [mul_zero, add_zero] at hc hX hY hpos
    exact share_bank_core S u d r q T a b hd hu hc hX hY hpos

/-- The same number, regrouped: the copy's cost is the two payments weighed by
`(exp ((r - q) * T) - d) / (u - d)` and `(u - exp ((r - q) * T)) / (u - d)`, added, and
discounted once at the bank rate. -/
theorem copy_cost_eq_weighted_payments
    (S u d r q T Hu Hd : ℝ) (hS : 0 < S) (hud : d < u) :
    copyCost S q T (hedgeRatio S u d Hu Hd) (bankBalance u d r T Hu Hd) =
      Real.exp (-r * T) *
        ((Real.exp ((r - q) * T) - d) / (u - d) * Hu +
          (u - Real.exp ((r - q) * T)) / (u - d) * Hd) := by
  have hne : u - d ≠ 0 := sub_ne_zero.mpr hud.ne'
  have hS0 : S ≠ 0 := hS.ne'
  have hF := exp_fwd_eq r q T
  have h1 := exp_neg_mul_exp r T
  have hE : Real.exp (r * T) ≠ 0 := (Real.exp_pos _).ne'
  unfold copyCost hedgeRatio bankBalance
  rw [hF, eq_inv_of_mul_eq_one_left h1]
  field_simp
  ring

-- The card's toy market in exact fractions: S = 100, u = 6/5, d = 4/5, the bank multiplies cash
-- by 21/20, no dividend, and the call is struck at 100.
-- The call pays 20 up and 0 down.
example : max ((100 : ℚ) * (6 / 5) - 100) 0 = 20 := by norm_num
example : max ((100 : ℚ) * (4 / 5) - 100) 0 = 0 := by norm_num
-- Half a share at delivery: (20 - 0) / (100 * (6/5 - 4/5)) = 1/2.
example : ((20 : ℚ) - 0) / (100 * (6 / 5 - 4 / 5)) = 1 / 2 := by norm_num
-- Cash today: (u * Hd - d * Hu) / (u - d), discounted by 20/21, is -800/21.
example : (20 / 21 : ℚ) * ((6 / 5 * 0 - 4 / 5 * 20) / (6 / 5 - 4 / 5)) = -800 / 21 := by norm_num
-- The copy pays 20 up and 0 down.
example : (1 / 2 : ℚ) * 120 + (-800 / 21) * (21 / 20) = 20 := by norm_num
example : (1 / 2 : ℚ) * 80 + (-800 / 21) * (21 / 20) = 0 := by norm_num
-- The copy costs 250/21 today.
example : (1 / 2 : ℚ) * 100 + (-800 / 21) = 250 / 21 := by norm_num
-- The same toy market through the file's own definitions, with exp (r * T) = 21/20.
example : hedgeRatio 100 (6 / 5) (4 / 5) 20 0 = 1 / 2 := by
  norm_num [hedgeRatio]
example : bankBalance (6 / 5) (4 / 5) (Real.log (21 / 20)) 1 20 0 = -800 / 21 := by
  norm_num [bankBalance, Real.exp_neg, Real.exp_log]
example : copyCost 100 0 1 (1 / 2) (-800 / 21) = 250 / 21 := by
  norm_num [copyCost]

#print axioms one_step_replication_price
#print axioms share_bank_no_arbitrage_iff_band
#print axioms copy_cost_eq_weighted_payments

end OneStepBinomial
