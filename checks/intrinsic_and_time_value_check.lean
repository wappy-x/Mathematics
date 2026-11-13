-- Intrinsic and time value: given only the no-arbitrage call-spread bound, a call's time value rises strictly up to the strike at the share price and never rises after it, and put-call parity gives the partner identity and the floor of minus the carry.
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Order.Filter.Extr

open Real

/-- The peak sits at the strike. Fix the share price `S`, and let `C K` be the price of the
European call struck at `K`. Suppose the only thing known is the no-arbitrage call-spread bound:
for strikes `K ≤ K'`, the spread `C K - C K'` costs at least nothing and at most the strike gap
paid at the expiry date, `e^{-rT} (K' - K)`. With a positive rate `r` and time `T`, the call's
time value `C K - max (S - K) 0` rises strictly as the strike climbs to `S`, never rises as the
strike climbs past `S`, and so is largest at the strike `K = S`. No pricing model is used. -/
theorem call_time_value_peaks_at_strike (S r T : ℝ) (C : ℝ → ℝ) (hr : 0 < r) (hT : 0 < T)
    (hspread : ∀ K K' : ℝ, K ≤ K' →
      0 ≤ C K - C K' ∧ C K - C K' ≤ exp (-(r * T)) * (K' - K)) :
    StrictMonoOn (fun K => C K - max (S - K) 0) (Set.Iic S) ∧
    AntitoneOn (fun K => C K - max (S - K) 0) (Set.Ici S) ∧
    IsMaxOn (fun K => C K - max (S - K) 0) Set.univ S := by
  have he : exp (-(r * T)) < 1 := by
    rw [Real.exp_lt_one_iff]; nlinarith [mul_pos hr hT]
  have hmono : StrictMonoOn (fun K => C K - max (S - K) 0) (Set.Iic S) := by
    intro a ha b hb hab
    simp only [Set.mem_Iic] at ha hb
    simp only
    have h1 : max (S - a) 0 = S - a := max_eq_left (by linarith)
    have h2 : max (S - b) 0 = S - b := max_eq_left (by linarith)
    rw [h1, h2]
    obtain ⟨_, hu⟩ := hspread a b hab.le
    have : exp (-(r * T)) * (b - a) < b - a := by
      have : 0 < b - a := by linarith
      nlinarith
    linarith
  have hanti : AntitoneOn (fun K => C K - max (S - K) 0) (Set.Ici S) := by
    intro a ha b hb hab
    simp only [Set.mem_Ici] at ha hb
    simp only
    have h1 : max (S - a) 0 = 0 := max_eq_right (by linarith)
    have h2 : max (S - b) 0 = 0 := max_eq_right (by linarith)
    rw [h1, h2]
    obtain ⟨hl, _⟩ := hspread a b hab
    linarith
  refine ⟨hmono, hanti, ?_⟩
  intro K _
  simp only [Set.mem_ofPred_eq]
  rcases le_total K S with h | h
  · exact hmono.monotoneOn (Set.mem_Iic.mpr h) (Set.mem_Iic.mpr le_rfl) h
  · exact hanti (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr h) h

/-- The partner identity. If a call and a put on the same share, strike and date satisfy
put-call parity, `C - P = S e^{-qT} - K e^{-rT}`, then for an in-the-money call (`K < S`) the
call's time value equals the put's premium plus the carry,
`K (1 - e^{-rT}) - S (1 - e^{-qT})`. -/
theorem call_time_value_eq_put_add_carry (S K r q T C P : ℝ)
    (hparity : C - P = S * exp (-(q * T)) - K * exp (-(r * T))) (hitm : K < S) :
    C - max (S - K) 0 = P + (K * (1 - exp (-(r * T))) - S * (1 - exp (-(q * T)))) := by
  rw [max_eq_left (by linarith)]
  linarith

/-- How far below zero a put's time value can go. Under put-call parity, with a call premium
that is not negative, an in-the-money put (`S < K`) has time value `P - max (K - S) 0` at least
minus the carry, `-(K (1 - e^{-rT}) - S (1 - e^{-qT}))`. -/
theorem put_time_value_ge_neg_carry (S K r q T C P : ℝ)
    (hparity : C - P = S * exp (-(q * T)) - K * exp (-(r * T))) (hC : 0 ≤ C) (hitm : S < K) :
    -(K * (1 - exp (-(r * T))) - S * (1 - exp (-(q * T)))) ≤ P - max (K - S) 0 := by
  rw [max_eq_left (by linarith)]
  linarith

-- The card's whole-number intrinsic values, with Acme at 100.
-- The house call, struck at 100: exercising now pays nothing.
example : max ((100 : ℝ) - 100) 0 = 0 := by norm_num
-- The 130-put: exercising now pays 30.
example : max ((130 : ℝ) - 100) 0 = 30 := by norm_num
-- The 130-call: the floor at zero, not minus 30.
example : max ((100 : ℝ) - 130) 0 = 0 := by norm_num
-- The 60-call: the call's intrinsic value is 40, the put's formula would wrongly give 0.
example : max ((100 : ℝ) - 60) 0 = 40 := by norm_num
example : max ((60 : ℝ) - 100) 0 = 0 := by norm_num

#print axioms call_time_value_peaks_at_strike
#print axioms call_time_value_eq_put_add_carry
#print axioms put_time_value_ge_neg_carry
