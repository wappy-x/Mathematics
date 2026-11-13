-- Risk reversal and butterfly: the ATM, risk reversal and butterfly quotes determine the two wing vols uniquely by the add-and-subtract formulas, the quote map has determinant 1, and both wings are positive exactly when ATM plus butterfly exceeds half the absolute risk reversal.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Group.Abs
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-- Turning the quotes back into vols: for any ATM vol, risk reversal and butterfly, the wing vols
satisfy `RR = σ_25c - σ_25p` and `BF = (σ_25c + σ_25p)/2 - σ_ATM` exactly when
`σ_25c = σ_ATM + BF + RR/2` and `σ_25p = σ_ATM + BF - RR/2`. So every quote triple comes from
exactly one vol triple, given by these formulas. -/
theorem wing_vols_from_quotes (atm rr bf c p : ℝ) :
    (rr = c - p ∧ bf = (c + p) / 2 - atm) ↔
      (c = atm + bf + rr / 2 ∧ p = atm + bf - rr / 2) := by
  constructor
  · rintro ⟨h1, h2⟩
    constructor <;> linarith
  · rintro ⟨h1, h2⟩
    constructor <;> linarith

/-- The map from the vols (put, ATM, call) to the quotes (ATM, RR, BF) is multiplication by a
fixed matrix whose determinant is 1, so the map can always be undone. -/
theorem quote_matrix_det_eq_one :
    (!![0, 1, 0; -1, 0, 1; 1 / 2, -1, 1 / 2] : Matrix (Fin 3) (Fin 3) ℝ).det = 1 := by
  rw [Matrix.det_fin_three]
  simp
  norm_num

/-- Positive wings: both recovered wing vols `σ_ATM + BF ± RR/2` are positive exactly when
`σ_ATM + BF > |RR| / 2`. -/
theorem wing_vols_pos_iff (atm rr bf : ℝ) :
    (0 < atm + bf + rr / 2 ∧ 0 < atm + bf - rr / 2) ↔ |rr| / 2 < atm + bf := by
  constructor
  · rintro ⟨h1, h2⟩
    rcases abs_cases rr with ⟨h, _⟩ | ⟨h, _⟩ <;> rw [h] <;> linarith
  · intro h
    have h1 := le_abs_self rr
    have h2 := neg_abs_le rr
    constructor <;> linarith

-- The card's house quotes, in hundredths of a vol point: ATM 10.00 = 1000, RR -1.00 = -100,
-- BF +0.25 = 25. The call vol 9.75 = 975 and the put vol 10.75 = 1075.
example : (1000 : ℝ) + 25 + (-100) / 2 = 975 := by norm_num
example : (1000 : ℝ) + 25 - (-100) / 2 = 1075 := by norm_num
-- Back-out: the recovered vols rebuild RR -1.00 and BF +0.25.
example : (975 : ℝ) - 1075 = -100 := by norm_num
example : ((975 : ℝ) + 1075) / 2 - 1000 = 25 := by norm_num
-- Positive wings on the house quotes: 1000 + 25 > |-100| / 2.
example : |(-100 : ℝ)| / 2 < 1000 + 25 := by norm_num [abs_of_neg]
-- Mistake row "put the whole RR on each wing": the wings end up 200 apart, twice the quote.
example : ((1000 : ℝ) + 25 + (-100)) - (1000 + 25 - (-100)) = 2 * (-100) := by norm_num

#print axioms wing_vols_from_quotes
#print axioms quote_matrix_det_eq_one
#print axioms wing_vols_pos_iff
