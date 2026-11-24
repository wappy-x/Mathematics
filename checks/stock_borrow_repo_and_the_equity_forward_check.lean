-- Stock borrow and repo: with a borrow fee b the forward is F = S e^((r - q - b)T), a quote gives the fee back as b = r - q - ln(F/S)/T and the repo rate as r - b = q + ln(F/S)/T, unequal fees pin the forward only to a band, and a box spread fixes the discount factor with no dividend or fee inside.
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open Real

/-! Notation, as on the card. `S` is Acme's price today, `F` the forward price, `r` the bank rate,
`q` the dividend yield, `b` the borrow fee, all continuously compounded, and `T` the years to
delivery. The repo rate is `r - b`. The card's model (one fee for borrowers and lenders, the fee
and the dividend known for the term, the share can be borrowed, the rate fits the trade) is what
makes the prepaid forward `S e^(-(q+b)T)`: buy that fraction of a share, lend it out, and reinvest
the dividend and the fee until it is one whole share on delivery day. -/

/-- The card's main claim. The fee for lending a share is income to whoever holds it, so it lowers
the forward exactly as a dividend does: `F = S e^((r - q - b)T)`. Run backwards, for a positive
spot, a positive quote and `T > 0`, the quote read with the bank rate and the dividend gives the
fee back, and only one fee fits: `b = r - q - ln(F/S)/T`. In repo terms the same quote gives the
repo rate `r - b = q + ln(F/S)/T`. -/
theorem borrow_fee_read_from_forward (S F r q b T : ℝ) (hS : 0 < S) (hF : 0 < F) (hT : 0 < T) :
    (F = S * exp ((r - q - b) * T) ↔ b = r - q - log (F / S) / T) ∧
    (F = S * exp ((r - q - b) * T) ↔ r - b = q + log (F / S) / T) := by
  have key : ∀ x : ℝ, F = S * exp (x * T) ↔ x = log (F / S) / T := by
    intro x
    constructor
    · intro h
      have hx : F / S = exp (x * T) := by
        rw [h]; field_simp
      rw [hx, log_exp]; field_simp
    · intro h
      have hx : x * T = log (F / S) := by
        rw [h]; field_simp
      rw [hx, exp_log (div_pos hF hS)]; field_simp
  constructor
  · rw [key]; constructor <;> intro h <;> linarith
  · rw [key]; constructor <;> intro h <;> linarith

/-- Step 3 and the detailed proof's band. Shorts pay the fee `bs`, lenders receive `bl ≤ bs`.
The holder's trade (sell the forward at `F`, borrow `S e^(-(q+bl)T)`, buy that fraction of a share
and lend it out) nets `F - S e^(-(q+bl)T) e^(rT)` on delivery day; the short seller's trade nets
`S e^(-(q+bs)T) e^(rT) - F`. Neither makes a riskless profit exactly when
`S e^((r-q-bs)T) ≤ F ≤ S e^((r-q-bl)T)`, and this band is not empty. With one fee
(`bs = bl = b`) it shrinks to the single forward `S e^((r-q-b)T)`. -/
theorem no_arbitrage_band_with_two_fees (S F r q bs bl T : ℝ)
    (hS : 0 ≤ S) (hT : 0 ≤ T) (hfee : bl ≤ bs) :
    ((F - S * exp (-((q + bl) * T)) * exp (r * T) ≤ 0 ∧
        S * exp (-((q + bs) * T)) * exp (r * T) - F ≤ 0) ↔
      (S * exp ((r - q - bs) * T) ≤ F ∧ F ≤ S * exp ((r - q - bl) * T))) ∧
    S * exp ((r - q - bs) * T) ≤ S * exp ((r - q - bl) * T) := by
  have e1 : exp (-((q + bl) * T)) * exp (r * T) = exp ((r - q - bl) * T) := by
    rw [← exp_add]; ring_nf
  have e2 : exp (-((q + bs) * T)) * exp (r * T) = exp ((r - q - bs) * T) := by
    rw [← exp_add]; ring_nf
  refine ⟨?_, ?_⟩
  · rw [mul_assoc, mul_assoc, e1, e2]
    constructor
    · rintro ⟨h1, h2⟩; exact ⟨by linarith, by linarith⟩
    · rintro ⟨h1, h2⟩; exact ⟨by linarith, by linarith⟩
  · apply mul_le_mul_of_nonneg_left _ hS
    apply exp_le_exp.mpr
    apply mul_le_mul_of_nonneg_right _ hT
    linarith

/-- The box spread. Parity at strike `K` says call minus put is `g = D (F - K)`. At two strikes
`K1 < K2` the forward cancels: the box fixes the discount factor `D = (g1 - g2)/(K2 - K1)` with no
dividend or fee inside, and then parity gives the forward back as `F = K1 + g1/D`. -/
theorem box_spread_discount_factor (K1 K2 D F g1 g2 : ℝ) (hK : K1 < K2)
    (h1 : g1 = D * (F - K1)) (h2 : g2 = D * (F - K2)) :
    D = (g1 - g2) / (K2 - K1) ∧ (D ≠ 0 → F = K1 + g1 / D) := by
  have hne : K2 - K1 ≠ 0 := by linarith
  refine ⟨?_, ?_⟩
  · rw [eq_div_iff hne, h1, h2]; ring
  · intro hD
    rw [h1]; field_simp; ring

-- Card, Step 4: repo rate 5% less a 1% fee is 4% (in percent).
example : (5 : ℤ) - 1 = 4 := by norm_num
-- Card, Step 5: carry 2%, dividend 2%: implied repo 2% + 2% = 4%, implied fee 5% - 2% - 2% = 1%.
example : (2 : ℤ) + 2 = 4 := by norm_num
example : (5 : ℤ) - 2 - 2 = 1 := by norm_num
-- Card, worked numbers: the parity card's implied yield 5% - 2% = 3%.
example : (5 : ℤ) - 2 = 3 := by norm_num
-- Card, Step 5: the box at strikes 90 and 110 pays 110 - 90 = 20 dollars for certain.
example : (110 : ℤ) - 90 = 20 := by norm_num

#print axioms borrow_fee_read_from_forward
#print axioms no_arbitrage_band_with_two_fees
#print axioms box_spread_discount_factor
