-- The RLC circuit: when a battery V is switched onto a series coil L, resistor R and empty capacitor C with R below 2√(L/C), the charge q(t) = CV[1 − e^(at)(cos bt − (a/b) sin bt)] solves L q'' + R q' + q/C = V from q(0) = 0, i(0) = 0, peaks at CV(1 + e^(aπ/b)), and the heat R i² over all time is exactly half the battery's work, CV²/2.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Basic.Complex.Basic
import Mathlib.Tactic.NormNum

open Real MeasureTheory

namespace RLCCircuit

/-- The decay rate a = −R/(2L): the real part of the roots of L r² + R r + 1/C = 0. -/
noncomputable def decayRate (L R : ℝ) : ℝ := -R / (2 * L)

/-- The ringing rate b = √(1/(LC) − a²): the imaginary part of those roots. -/
noncomputable def ringRate (L R C : ℝ) : ℝ := Real.sqrt (1 / (L * C) - decayRate L R ^ 2)

/-- The charge on the capacitor t seconds after the switch closes, from the card's detailed proof:
q(t) = CV[1 − e^(at)(cos bt − (a/b) sin bt)]. -/
noncomputable def charge (L R C V : ℝ) (t : ℝ) : ℝ :=
  let a := decayRate L R
  let b := ringRate L R C
  C * V * (1 - Real.exp (a * t) * (Real.cos (b * t) - a / b * Real.sin (b * t)))

lemma charge_eq (L R C V : ℝ) : charge L R C V = fun t =>
    C * V * (1 - Real.exp (decayRate L R * t) * (Real.cos (ringRate L R C * t)
      - decayRate L R / ringRate L R C * Real.sin (ringRate L R C * t))) := rfl

lemma q_hasDerivAt (k a b t : ℝ) (hb : b ≠ 0) :
    HasDerivAt (fun t => k * (1 - Real.exp (a * t) * (Real.cos (b * t) - a / b * Real.sin (b * t))))
      (k * (a ^ 2 + b ^ 2) / b * Real.exp (a * t) * Real.sin (b * t)) t := by
  have h1 : HasDerivAt (fun t => a * t) a t := by simpa using (hasDerivAt_id t).const_mul a
  have h2 : HasDerivAt (fun t => b * t) b t := by simpa using (hasDerivAt_id t).const_mul b
  have he := h1.exp
  have hc := h2.cos
  have hs := (h2.sin).const_mul (a / b)
  have := ((he.mul (hc.sub hs)).const_sub 1).const_mul k
  convert this using 1
  simp only [Pi.sub_apply]
  field_simp
  ring

lemma i_hasDerivAt (m a b t : ℝ) :
    HasDerivAt (fun t => m * Real.exp (a * t) * Real.sin (b * t))
      (m * Real.exp (a * t) * (a * Real.sin (b * t) + b * Real.cos (b * t))) t := by
  have h1 : HasDerivAt (fun t => a * t) a t := by simpa using (hasDerivAt_id t).const_mul a
  have h2 : HasDerivAt (fun t => b * t) b t := by simpa using (hasDerivAt_id t).const_mul b
  have := ((h1.exp).const_mul m).mul h2.sin
  convert this using 1
  ring

lemma loop_core (L R C V a b t : ℝ) (hC : C ≠ 0) (hb : b ≠ 0) (hR : R = -2 * a * L)
    (hab : L * C * (a ^ 2 + b ^ 2) = 1) :
    L * (C * V * (a ^ 2 + b ^ 2) / b * Real.exp (a * t) * (a * Real.sin (b * t) + b * Real.cos (b * t)))
      + R * (C * V * (a ^ 2 + b ^ 2) / b * Real.exp (a * t) * Real.sin (b * t))
      + C * V * (1 - Real.exp (a * t) * (Real.cos (b * t) - a / b * Real.sin (b * t))) / C = V := by
  subst hR
  have e : C * V * (1 - Real.exp (a * t) * (Real.cos (b * t) - a / b * Real.sin (b * t))) / C
      = V * (1 - Real.exp (a * t) * (Real.cos (b * t) - a / b * Real.sin (b * t))) := by
    field_simp
  rw [e]
  have hb' : b * b⁻¹ = 1 := mul_inv_cancel₀ hb
  linear_combination (V * Real.exp (a * t) * (Real.cos (b * t) - a / b * Real.sin (b * t))) * hab
    + (L * C * (a ^ 2 + b ^ 2) * V * Real.exp (a * t) * Real.cos (b * t)) * hb'

/-- Basic facts: b > 0, R = -2aL, LC(a²+b²) = 1. -/
lemma rates_facts (L R C : ℝ) (hL : 0 < L) (hC : 0 < C) (hR0 : 0 ≤ R)
    (hR : R < 2 * Real.sqrt (L / C)) :
    0 < ringRate L R C ∧ R = -2 * decayRate L R * L ∧
      L * C * (decayRate L R ^ 2 + ringRate L R C ^ 2) = 1 := by
  have hsq : R ^ 2 < 4 * (L / C) := by
    have h0 : 0 ≤ Real.sqrt (L / C) := Real.sqrt_nonneg _
    have h1 : Real.sqrt (L / C) ^ 2 = L / C := Real.sq_sqrt (by positivity)
    nlinarith
  have hpos : 0 < 1 / (L * C) - decayRate L R ^ 2 := by
    rw [decayRate]
    have : R ^ 2 * C < 4 * L := by
      have := mul_lt_mul_of_pos_right hsq hC
      rwa [mul_assoc, div_mul_cancel₀ _ hC.ne'] at this
    rw [sub_pos, div_pow, lt_div_iff₀ (by positivity), div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
    nlinarith
  refine ⟨Real.sqrt_pos.mpr hpos, ?_, ?_⟩
  · rw [decayRate]; field_simp
  · rw [ringRate, Real.sq_sqrt hpos.le]; field_simp; ring

lemma charge_hasDerivAt (L R C V t : ℝ) (hb : ringRate L R C ≠ 0) :
    HasDerivAt (charge L R C V)
      (C * V * (decayRate L R ^ 2 + ringRate L R C ^ 2) / ringRate L R C
        * Real.exp (decayRate L R * t) * Real.sin (ringRate L R C * t)) t := by
  rw [charge_eq]; exact q_hasDerivAt _ _ _ _ hb

lemma deriv_charge (L R C V : ℝ) (hb : ringRate L R C ≠ 0) :
    deriv (charge L R C V) = fun t =>
      C * V * (decayRate L R ^ 2 + ringRate L R C ^ 2) / ringRate L R C
        * Real.exp (decayRate L R * t) * Real.sin (ringRate L R C * t) :=
  funext fun t => (charge_hasDerivAt L R C V t hb).deriv

lemma exp_mul_bdd_tendsto (a M : ℝ) (ha : a < 0) (f : ℝ → ℝ) (hf : ∀ t, |f t| ≤ M) :
    Filter.Tendsto (fun t => Real.exp (a * t) * f t) Filter.atTop (nhds 0) := by
  have hE : Filter.Tendsto (fun t => Real.exp (a * t)) Filter.atTop (nhds 0) :=
    Real.tendsto_exp_atBot.comp (Filter.tendsto_id.const_mul_atTop_of_neg ha)
  refine squeeze_zero_norm (fun t => ?_) (by simpa using hE.mul_const M)
  rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
  exact mul_le_mul_of_nonneg_left (hf t) (Real.exp_pos _).le

/-- The switch-on solution. A battery of steady voltage V is switched onto a coil of inductance
L > 0, a resistor R ≥ 0 and an empty capacitor C > 0 in series, with R below 2√(L/C) so that it
rings. Then the charge q(t) = CV[1 − e^(at)(cos bt − (a/b) sin bt)], with a = −R/(2L) and
b = √(1/(LC) − a²), is smooth, obeys Kirchhoff's loop law L q'' + R q' + q/C = V at every
instant, and starts empty with no current: q(0) = 0 and q'(0) = 0. -/
theorem charge_solves_loop_law (L R C V : ℝ) (hL : 0 < L) (hC : 0 < C) (hR0 : 0 ≤ R)
    (hR : R < 2 * Real.sqrt (L / C)) :
    ContDiff ℝ 2 (charge L R C V) ∧
    (∀ t, L * deriv (deriv (charge L R C V)) t + R * deriv (charge L R C V) t
        + charge L R C V t / C = V) ∧
    charge L R C V 0 = 0 ∧ deriv (charge L R C V) 0 = 0 := by
  obtain ⟨hb, hRa, hab⟩ := rates_facts L R C hL hC hR0 hR
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [charge_eq]; fun_prop
  · intro t
    rw [deriv_charge L R C V hb.ne', (i_hasDerivAt _ _ _ t).deriv, charge_eq]
    beta_reduce
    exact loop_core L R C V _ _ t hC.ne' hb.ne' hRa hab
  · simp [charge_eq]
  · rw [deriv_charge L R C V hb.ne']; simp

/-- The current and the overshoot. Under the same conditions the current is
i(t) = CV (a² + b²)/b · e^(at) sin bt (the cosines cancel), so it is zero at t = π/b, where the
charge stops rising at its peak CV(1 + e^(aπ/b)). -/
theorem current_formula_and_peak (L R C V : ℝ) (hL : 0 < L) (hC : 0 < C) (hR0 : 0 ≤ R)
    (hR : R < 2 * Real.sqrt (L / C)) :
    (∀ t, HasDerivAt (charge L R C V)
      (C * V * (decayRate L R ^ 2 + ringRate L R C ^ 2) / ringRate L R C
        * Real.exp (decayRate L R * t) * Real.sin (ringRate L R C * t)) t) ∧
    deriv (charge L R C V) (π / ringRate L R C) = 0 ∧
    charge L R C V (π / ringRate L R C)
      = C * V * (1 + Real.exp (decayRate L R * π / ringRate L R C)) := by
  obtain ⟨hb, hRa, hab⟩ := rates_facts L R C hL hC hR0 hR
  have hπ : ringRate L R C * (π / ringRate L R C) = π := by field_simp
  refine ⟨fun t => charge_hasDerivAt L R C V t hb.ne', ?_, ?_⟩
  · rw [deriv_charge L R C V hb.ne']; simp [hπ]
  · rw [charge_eq]; beta_reduce
    rw [hπ, Real.cos_pi, Real.sin_pi, mul_div_assoc]; ring

/-- Half the energy is heat. With R > 0 the ringing dies, and the heat R i² summed over all time
after switch-on is CV²/2: half of the battery's work V · CV, whatever the resistance. -/
theorem heat_is_half_battery_work (L R C V : ℝ) (hL : 0 < L) (hC : 0 < C) (hR0 : 0 < R)
    (hR : R < 2 * Real.sqrt (L / C)) :
    ∫ t in Set.Ioi 0, R * deriv (charge L R C V) t ^ 2 = C * V ^ 2 / 2 := by
  obtain ⟨hb, hRa, hab⟩ := rates_facts L R C hL hC hR0.le hR
  have ha : decayRate L R < 0 := by
    rw [decayRate]; exact div_neg_of_neg_of_pos (by linarith) (by linarith)
  rw [deriv_charge L R C V hb.ne']
  set a := decayRate L R with ha_def
  set b := ringRate L R C with hb_def
  set K := C * V * (a ^ 2 + b ^ 2) / b with hK
  set i : ℝ → ℝ := fun t => K * Real.exp (a * t) * Real.sin (b * t) with hi_def
  set q := charge L R C V with hq_def
  have hq : ∀ t, HasDerivAt q (i t) t := fun t => charge_hasDerivAt L R C V t hb.ne'
  have hloop : ∀ t, L * (K * Real.exp (a * t) * (a * Real.sin (b * t) + b * Real.cos (b * t)))
      + R * i t + q t / C = V := by
    intro t
    rw [hq_def, charge_eq]
    exact loop_core L R C V a b t hC.ne' hb.ne' hRa hab
  let G : ℝ → ℝ := fun t => V * q t - L * i t ^ 2 / 2 - q t ^ 2 / (2 * C)
  have hG : ∀ t, HasDerivAt G (R * i t ^ 2) t := by
    intro t
    have hit := i_hasDerivAt K a b t
    have := ((((hq t).const_mul V).sub (((hit.pow 2).const_mul L).div_const 2)).sub
      (((hq t).pow 2).div_const (2 * C)))
    convert this using 1
    have hl := hloop t
    simp only [hi_def, Nat.cast_ofNat, show (2 : ℕ) - 1 = 1 from rfl, pow_one] at hl ⊢
    linear_combination (K * Real.exp (a * t) * Real.sin (b * t)) * hl
  have hqlim : Filter.Tendsto q Filter.atTop (nhds (C * V)) := by
    have hbd : ∀ t, |Real.cos (b * t) - a / b * Real.sin (b * t)| ≤ 1 + |a / b| := by
      intro t
      have h1 := abs_sub (Real.cos (b * t)) (a / b * Real.sin (b * t))
      rw [abs_mul] at h1
      nlinarith [Real.abs_cos_le_one (b * t), Real.abs_sin_le_one (b * t), abs_nonneg (a / b)]
    have := ((exp_mul_bdd_tendsto a _ ha _ hbd).const_sub 1).const_mul (C * V)
    rw [hq_def, charge_eq]
    simpa using this
  have hilim : Filter.Tendsto i Filter.atTop (nhds 0) := by
    have := (exp_mul_bdd_tendsto a 1 ha (fun t => Real.sin (b * t))
      (fun t => Real.abs_sin_le_one _)).const_mul K
    simp only [mul_zero] at this
    refine this.congr (fun t => ?_)
    simp only [hi_def]; ring
  have hGlim : Filter.Tendsto G Filter.atTop (nhds (C * V ^ 2 / 2)) := by
    have := ((hqlim.const_mul V).sub (((hilim.pow 2).const_mul L).div_const 2)).sub
      ((hqlim.pow 2).div_const (2 * C))
    convert this using 2
    field_simp
    ring
  have hq0 : q 0 = 0 := by rw [hq_def]; simp [charge_eq]
  have hi0 : i 0 = 0 := by simp [hi_def]
  rw [integral_Ioi_of_hasDerivAt_of_nonneg' (fun x _ => hG x) (fun x _ => by positivity) hGlim]
  simp [G, hq0, hi0]

/-! The card's circuit: L = 1 H, R = 2 ohms, C = 0.2 = 1/5 F, V = 10 V. -/

-- Divided by L: R/L = 2 and 1/(LC) = 5, so the law is q'' + 2q' + 5q = 10.
example : (2 : ℚ) / 1 = 2 ∧ (1 : ℚ) / (1 * (1 / 5)) = 5 := by norm_num
-- The roots of r² + 2r + 5 = 0 are −1 ± 2i.
example : ((-1 + 2 * Complex.I) ^ 2 + 2 * (-1 + 2 * Complex.I) + 5 : ℂ) = 0 := by
  ring_nf; rw [Complex.I_sq]; ring
example : ((-1 - 2 * Complex.I) ^ 2 + 2 * (-1 - 2 * Complex.I) + 5 : ℂ) = 0 := by
  ring_nf; rw [Complex.I_sq]; ring
-- a = −R/(2L) = −1 and b = √(1/(LC) − a²) = √4 = 2.
example : decayRate 1 2 = -1 := by norm_num [decayRate]
example : ringRate 1 2 (1 / 5) = 2 := by
  rw [ringRate, decayRate, show (1 : ℝ) / (1 * (1 / 5)) - (-2 / (2 * 1)) ^ 2 = 2 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Final charge: 5K = 10, so K = 2 = C × V.
example : (1 / 5 : ℚ) * 10 = 2 ∧ (5 : ℚ) * 2 = 10 := by norm_num
-- Fitting the start: A = −2, B = −1 satisfy A + 2 = 0 and −A + 2B = 0.
example : (-2 : ℚ) + 2 = 0 ∧ -(-2 : ℚ) + 2 * (-1) = 0 := by norm_num
-- The general formula gives the card's q(t) = 2 − e^(−t)(2 cos 2t + sin 2t).
example : charge 1 2 (1 / 5) 10
    = fun t => 2 - Real.exp (-t) * (2 * Real.cos (2 * t) + Real.sin (2 * t)) := by
  have ha : decayRate 1 2 = -1 := by norm_num [decayRate]
  have hb : ringRate 1 2 (1 / 5) = 2 := by
    rw [ringRate, decayRate, show (1 : ℝ) / (1 * (1 / 5)) - (-2 / (2 * 1)) ^ 2 = 2 ^ 2 by norm_num]
    exact Real.sqrt_sq (by norm_num)
  funext t
  simp only [charge, ha, hb]
  ring_nf
-- The current's size: CV(a² + b²)/b = 2 × 5 / 2 = 5, so i = 5 e^(−t) sin 2t.
example : (1 / 5 : ℚ) * 10 * ((-1) ^ 2 + 2 ^ 2) / 2 = 5 := by norm_num
-- Critical resistance: R² = 4L/C = 20, and 2² = 4 is below it.
example : 4 * (1 : ℚ) / (1 / 5) = 20 ∧ (2 : ℚ) ^ 2 < 20 := by norm_num
-- Energy: the battery gives 10 × 2 = 20 J, the capacitor keeps 2²/(2 × 1/5) = 10 J, heat 10 J.
example : (10 : ℚ) * 2 = 20 ∧ (2 : ℚ) ^ 2 / (2 * (1 / 5)) = 10 ∧ (20 : ℚ) - 10 = 10 := by norm_num
-- The mistake q·C for q/C: the steady charge would be V/C = 50, not 2.
example : (10 : ℚ) / (1 / 5) = 50 := by norm_num

#print axioms charge_eq
#print axioms q_hasDerivAt
#print axioms i_hasDerivAt
#print axioms loop_core
#print axioms rates_facts
#print axioms charge_hasDerivAt
#print axioms deriv_charge
#print axioms exp_mul_bdd_tendsto
#print axioms charge_solves_loop_law
#print axioms current_formula_and_peak
#print axioms heat_is_half_battery_work

end RLCCircuit
