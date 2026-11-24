-- Reverse convertibles: the note's repayment is the face value minus a put payoff, the coupon that makes the note worth its face value is the bond's interest plus the put's price divided by the bond's price, and a cheaper knock-in put gives a smaller coupon.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Order.MinMax

/-- The card's main claim (The formula, Why it works Steps 2 and 3). A note of face value `F`
pays the coupon rate `c` in cash at the end, `T` years out, and the buyer has sold `F/K` puts of
price `P`, so at riskless rate `r` it is worth `V = (1 + c) F e^{-rT} - (F/K) P` today. The note
is worth exactly its face value (`V = F`) if and only if the coupon is the fair coupon
`c = (F - F e^{-rT} + (F/K) P) / (F e^{-rT})`. For the barrier note put the down-and-in put's
price in place of `P`. -/
theorem fair_coupon_of_reverse_convertible (F K P r T c : ℝ) (hF : 0 < F) :
    (1 + c) * (F * Real.exp (-r * T)) - F / K * P = F ↔
      c = (F - F * Real.exp (-r * T) + F / K * P) / (F * Real.exp (-r * T)) := by
  have hE : 0 < F * Real.exp (-r * T) := mul_pos hF (Real.exp_pos _)
  rw [eq_div_iff hE.ne']
  constructor <;> intro h <;> linarith

/-- Why it works, Step 1: the repayment is the face value minus a put payoff. A note of face
value `F > 0` with strike `K > 0` repays the smaller of `F` and the value `(F/K) S_T` of `F/K`
shares, and that equals `F` minus the payoff `max (K - S_T) 0` of `F/K` puts with strike `K`. -/
theorem repayment_eq_face_minus_put_payoff (F K S_T : ℝ) (hF : 0 < F) (hK : 0 < K) :
    min F (F / K * S_T) = F - F / K * max (K - S_T) 0 := by
  have hFK : 0 < F / K := div_pos hF hK
  have hKK : F / K * K = F := div_mul_cancel₀ F hK.ne'
  rcases le_total S_T K with h | h
  · have h1 : F / K * S_T ≤ F := by nlinarith
    rw [min_eq_right h1, max_eq_left (by linarith)]
    nlinarith
  · have h1 : F ≤ F / K * S_T := by nlinarith
    rw [min_eq_left h1, max_eq_right (by linarith)]
    ring

/-- Why it works, Step 4: the barrier note earns the smaller coupon. Every path that converts the
barrier note also converts the plain one, so the down-and-in put is worth at most the put,
`P_di ≤ P`; then the fair coupon with `P_di` in place of `P` is at most the plain fair coupon. -/
theorem barrier_coupon_le_plain_coupon (F K P P_di r T : ℝ) (hF : 0 < F) (hK : 0 < K)
    (hP : P_di ≤ P) :
    (F - F * Real.exp (-r * T) + F / K * P_di) / (F * Real.exp (-r * T)) ≤
      (F - F * Real.exp (-r * T) + F / K * P) / (F * Real.exp (-r * T)) := by
  have hE : 0 < F * Real.exp (-r * T) := mul_pos hF (Real.exp_pos _)
  have hFK : 0 < F / K := div_pos hF hK
  apply div_le_div_of_nonneg_right _ hE.le
  nlinarith

-- Step 1 at S_T = 70 with F = K = 100: the note repays one share worth 70, and 100 - 1 * 30 = 70
example : min (100 : ℝ) (100 / 100 * 70) = 70 := by norm_num
example : (100 : ℝ) - 100 / 100 * max (100 - 70) 0 = 70 := by norm_num

-- Above the strike, at S_T = 130, the put pays nothing and the note repays the face value 100
example : min (100 : ℝ) (100 / 100 * 130) = 100 - 100 / 100 * max (100 - 130) 0 := by norm_num

#print axioms fair_coupon_of_reverse_convertible
#print axioms repayment_eq_face_minus_put_payoff
#print axioms barrier_coupon_le_plain_coupon
