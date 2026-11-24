-- Worst-of autocallables: in the last quarter the note pays no more than the same note on any one share, its payoff near 70 is the worst level plus a 30-point step minus a sold call, and the gamma of that step plus sold call is positive below S = K e^(-(r - q + σ²/2)T - (K/H)σ²T) and negative above it.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Finset.Lattice.Fold

open Real ProbabilityTheory

/-- `φ(x) = e^(-x²/2) / √(2π)`: the bell curve's height at `x`, the standard normal density. -/
noncomputable def stdNormalPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- The cash-side distance to the strike, `d₂ = (ln(S/K) + (r - q - σ²/2) T) / (σ√T)`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T)

/-- The share-side distance to the strike, `d₁ = d₂ + σ√T`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  bsD2 S K r q σ T + σ * √T

/-- Gamma near the knock-in, per point of the worst share, with time `T` left: the gamma of a
step of height `H` at level `K`, `-H e^(-rT) φ(d₂) d₁ / (S²σ²T)`, plus the gamma of the call
struck at `K` that the holder has sold, `-e^(-qT) φ(d₁) / (Sσ√T)`. The worst level itself is a
straight line and adds no gamma. -/
noncomputable def stepMinusCallGamma (S K H r q σ T : ℝ) : ℝ :=
  -(H * exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * bsD1 S K r q σ T) / (S ^ 2 * σ ^ 2 * T)
    - exp (-q * T) * stdNormalPDF (bsD1 S K r q σ T) / (S * σ * √T)

/-- The final payoff in the last quarter, per 100 of face, given the worst level `w` and the
yearly coupon `c`: 100 plus three coupons if the worst is at 100 or more, 100 if it is at 70 or
more, and the worst level itself below 70. -/
noncomputable def finalPay (c w : ℝ) : ℝ :=
  if 100 ≤ w then 100 + 300 * c else if 70 ≤ w then 100 else w

/-- The share-side and cash-side densities are linked: `e^(-qT) φ(d₁) S = e^(-rT) K φ(d₂)`. -/
lemma pdf_d1_mul_eq (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    exp (-q * T) * stdNormalPDF (bsD1 S K r q σ T) * S
      = exp (-r * T) * K * stdNormalPDF (bsD2 S K r q σ T) := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hne : σ * √T ≠ 0 := by positivity
  have hd2 : bsD2 S K r q σ T * (σ * √T) = log S - log K + (r - q - σ ^ 2 / 2) * T := by
    unfold bsD2
    rw [div_mul_cancel₀ _ hne, Real.log_div hS.ne' hK.ne']
  have key : -q * T + -(bsD1 S K r q σ T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + log S
      = -r * T + log K + -(bsD2 S K r q σ T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) := by
    unfold bsD1
    simp only [NNReal.coe_one, sub_zero]
    have : (bsD2 S K r q σ T + σ * √T) ^ 2
        = bsD2 S K r q σ T ^ 2 + 2 * (bsD2 S K r q σ T * (σ * √T)) + σ ^ 2 * √T ^ 2 := by ring
    rw [this, hd2, hsq]
    ring
  unfold stdNormalPDF gaussianPDFReal
  have e1 : exp (-q * T) * ((√(2 * π * ((1 : NNReal) : ℝ)))⁻¹
      * exp (-(bsD1 S K r q σ T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)))) * S
      = (√(2 * π * ((1 : NNReal) : ℝ)))⁻¹
        * exp (-q * T + -(bsD1 S K r q σ T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + log S) := by
    rw [Real.exp_add, Real.exp_add, Real.exp_log hS]; ring
  have e2 : exp (-r * T) * K * ((√(2 * π * ((1 : NNReal) : ℝ)))⁻¹
      * exp (-(bsD2 S K r q σ T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))))
      = (√(2 * π * ((1 : NNReal) : ℝ)))⁻¹
        * exp (-r * T + log K + -(bsD2 S K r q σ T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) := by
    rw [Real.exp_add, Real.exp_add, Real.exp_log hK]; ring
  rw [e1, e2, key]

/-- The gamma is a negative multiple of `log S - log S*`. -/
lemma stepMinusCallGamma_eq (S K H r q σ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) :
    stepMinusCallGamma S K H r q σ T
      = -(exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * H / (S ^ 2 * σ ^ 2 * T * (σ * √T)))
        * (log S - log (K * exp (-(r - q + σ ^ 2 / 2) * T - (K / H) * σ ^ 2 * T))) := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hne : σ * √T ≠ 0 := by positivity
  have hrel := pdf_d1_mul_eq S K r q σ T hS hK hσ hT
  have hphi1 : exp (-q * T) * stdNormalPDF (bsD1 S K r q σ T)
      = exp (-r * T) * K * stdNormalPDF (bsD2 S K r q σ T) / S := by
    rw [← hrel]; field_simp
  have hd2 : bsD2 S K r q σ T = (log S - log K + (r - q - σ ^ 2 / 2) * T) / (σ * √T) := by
    unfold bsD2; rw [Real.log_div hS.ne' hK.ne']
  rw [Real.log_mul hK.ne' (Real.exp_pos _).ne', Real.log_exp]
  unfold stepMinusCallGamma
  rw [mul_div_assoc (exp (-q * T)), ← mul_div_assoc, hphi1]
  unfold bsD1
  rw [hd2]
  field_simp
  rw [hsq]
  ring

#print axioms pdf_d1_mul_eq
#print axioms stepMinusCallGamma_eq

/-- Gamma changes sign near the knock-in. For a step of height `H > 0` at level `K > 0` plus a
sold call struck at `K`, with volatility `σ > 0` and time left `T > 0`, the gamma at share level
`S > 0` is positive below `S* = K e^(-(r - q + σ²/2)T - (K/H)σ²T)`, zero at `S*` and negative
above it. (With `K = 70`, `H = 30`, `σ = 20%`, `T = 0.25`, `r = 5%`, `q = 2%`, `S*` is 67.54.) -/
theorem step_minus_call_gamma_changes_sign (S K H r q σ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) :
    let Sstar := K * exp (-(r - q + σ ^ 2 / 2) * T - (K / H) * σ ^ 2 * T)
    (0 < stepMinusCallGamma S K H r q σ T ↔ S < Sstar) ∧
      (stepMinusCallGamma S K H r q σ T = 0 ↔ S = Sstar) ∧
      (stepMinusCallGamma S K H r q σ T < 0 ↔ Sstar < S) := by
  intro Sstar
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hSstar : 0 < Sstar := by positivity
  have hC : 0 < exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * H
      / (S ^ 2 * σ ^ 2 * T * (σ * √T)) := by
    have : 0 < stdNormalPDF (bsD2 S K r q σ T) :=
      gaussianPDFReal_pos _ _ _ one_ne_zero
    positivity
  have hg := stepMinusCallGamma_eq S K H r q σ T hS hK hH hσ hT
  rw [hg]
  set C := exp (-r * T) * stdNormalPDF (bsD2 S K r q σ T) * H / (S ^ 2 * σ ^ 2 * T * (σ * √T))
  have hlt : S < Sstar ↔ log S - log Sstar < 0 := by
    rw [sub_neg]; exact (Real.log_lt_log_iff hS hSstar).symm
  have hgt : Sstar < S ↔ 0 < log S - log Sstar := by
    rw [sub_pos]; exact (Real.log_lt_log_iff hSstar hS).symm
  have heq : S = Sstar ↔ log S - log Sstar = 0 := by
    rw [sub_eq_zero]
    exact ⟨fun h => by rw [h], fun h => Real.log_injOn_pos hS hSstar h⟩
  refine ⟨?_, ?_, ?_⟩
  · rw [hlt]
    constructor
    · intro h; by_contra h'; have h'' := not_lt.mp h'; nlinarith
    · intro h; nlinarith
  · rw [heq]
    constructor
    · intro h
      have : C * (log S - log Sstar) = 0 := by linarith
      rcases mul_eq_zero.mp this with h1 | h1
      · exact absurd h1 hC.ne'
      · exact h1
    · intro h; rw [h]; ring
  · rw [hgt]
    constructor
    · intro h; by_contra h'; have h'' := not_lt.mp h'; nlinarith
    · intro h; nlinarith

/-- A worst-of note pays only as well as its weakest share. In the last quarter, with a coupon
`c ≥ 0`, the note on the worst of the three levels pays no more than the same note on any one
of the three shares alone. -/
theorem worst_of_pays_at_most_each_share (c : ℝ) (hc : 0 ≤ c) (S : Fin 3 → ℝ) (i : Fin 3) :
    finalPay c (Finset.univ.inf' Finset.univ_nonempty S) ≤ finalPay c (S i) := by
  have hle : Finset.univ.inf' Finset.univ_nonempty S ≤ S i :=
    Finset.inf'_le _ (Finset.mem_univ i)
  set w := Finset.univ.inf' Finset.univ_nonempty S
  unfold finalPay
  split_ifs <;> linarith

/-- Below the call level the payoff is the worst level, plus a step of `100 - 70 = 30` at 70,
minus a call struck at 70 that the holder has sold: `W + 30·1{W ≥ 70} - max(W - 70, 0)`. -/
theorem final_pay_eq_step_minus_call (c W : ℝ) (hW : W < 100) :
    finalPay c W = W + (if 70 ≤ W then 30 else 0) - max (W - 70) 0 := by
  unfold finalPay
  by_cases h2 : 70 ≤ W
  · simp only [not_le.mpr hW, h2, ite_true, ite_false, max_eq_left (sub_nonneg.mpr h2)]
    ring
  · simp only [not_le.mpr hW, h2, ite_false,
      max_eq_right (sub_nonpos.mpr (le_of_lt (not_le.mp h2)))]
    ring

-- If Borex is the worst share and ends at 60, the holder gets 60.
example (c : ℝ) : finalPay c 60 = 60 := by norm_num [finalPay]
-- The step at 70 is 30 points high: 100 back against the worst level 70.
example : (100 : ℤ) - 70 = 30 := by norm_num
-- At 80 the decomposition gives 80 + 30 - 10 = 100, the repayment.
example : (80 : ℤ) + 30 - max (80 - 70) 0 = 100 := by norm_num

#print axioms step_minus_call_gamma_changes_sign
#print axioms worst_of_pays_at_most_each_share
#print axioms final_pay_eq_step_minus_call
