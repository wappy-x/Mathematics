-- Stress, strain and bending: a beam pinned at both ends with a point load P at mid-span, obeying E I v'' = -M, sags P L^3 / (48 E I) at the middle, with the card's sag curve and energy check.
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

/-- If `f' = g'` on `[a, b]` then `f - g` is constant there. -/
lemma beam_sub_const_of_deriv_eq {f g g' : ℝ → ℝ} (hf : Differentiable ℝ f)
    (hg : ∀ x, HasDerivAt g (g' x) x) {a b : ℝ}
    (h : ∀ x ∈ Set.Icc a b, deriv f x = g' x) :
    ∀ x ∈ Set.Icc a b, f x - g x = f a - g a := by
  have hgd : Differentiable ℝ g := fun x => (hg x).differentiableAt
  have hd : Differentiable ℝ (fun x => f x - g x) := hf.sub hgd
  intro x hx
  exact constant_of_has_deriv_right_zero (f := fun x => f x - g x) hd.continuous.continuousOn
    (fun y hy => by
      have h1 : HasDerivAt (fun x => f x - g x) (deriv f y - g' y) y :=
        (hf y).hasDerivAt.sub (hg y)
      rw [h y (Set.Ico_subset_Icc_self hy), sub_self] at h1
      exact h1.hasDerivWithinAt) x hx

/-- The sag curve on the left half, shared by the first two theorems. -/
lemma beam_sag_left (P L E I : ℝ) (hL : 0 < L) (hE : 0 < E) (hI : 0 < I)
    (v : ℝ → ℝ) (hv : Differentiable ℝ v) (hv' : Differentiable ℝ (deriv v))
    (hbend : ∀ x ∈ Set.Icc 0 L, E * I * deriv (deriv v) x = -(P * min x (L - x) / 2))
    (h0 : v 0 = 0) (hLend : v L = 0) :
    ∀ x ∈ Set.Icc 0 (L / 2), v x = P * x * (3 * L ^ 2 - 4 * x ^ 2) / (48 * E * I) := by
  have hEI : E * I ≠ 0 := by positivity
  set K := P / (E * I) with hK
  have hdd : ∀ x ∈ Set.Icc 0 L, deriv (deriv v) x = -(K * min x (L - x) / 2) := by
    intro x hx
    calc deriv (deriv v) x = (E * I * deriv (deriv v) x) / (E * I) := by field_simp
      _ = -(K * min x (L - x) / 2) := by rw [hbend x hx, hK]; ring
  -- A: slope on the left half
  have hA := beam_sub_const_of_deriv_eq (f := deriv v) (g := fun x => -K / 4 * x ^ 2)
    (g' := fun x => -K * x / 2) hv'
    (fun x => by
      have := (hasDerivAt_pow 2 x).const_mul (-K / 4)
      convert this using 1; push_cast; ring)
    (a := 0) (b := L / 2)
    (fun x hx => by
      rw [hdd x ⟨hx.1, by linarith [hx.2]⟩, min_eq_left (by linarith [hx.2])]; ring)
  -- B: slope on the right half
  have hB := beam_sub_const_of_deriv_eq (f := deriv v) (g := fun x => K / 4 * (L - x) ^ 2)
    (g' := fun x => -K * (L - x) / 2) hv'
    (fun x => by
      have := ((hasDerivAt_id x).const_sub L).pow 2 |>.const_mul (K / 4)
      convert this using 1
      · funext y; simp only [id, Pi.pow_apply]
      · simp only [id]; norm_num; ring)
    (a := L / 2) (b := L)
    (fun x hx => by
      rw [hdd x ⟨by linarith [hx.1], hx.2⟩, min_eq_right (by linarith [hx.1])]; ring)
  have hBL := hB L ⟨by linarith, le_refl L⟩
  have hAm := hA (L / 2) ⟨by linarith, le_refl _⟩
  -- C: sag on the left half
  have hC := beam_sub_const_of_deriv_eq (f := v)
    (g := fun x => deriv v 0 * x - K / 12 * x ^ 3)
    (g' := fun x => deriv v 0 - K / 4 * x ^ 2) hv
    (fun x => by
      have := ((hasDerivAt_id x).const_mul (deriv v 0)).sub ((hasDerivAt_pow 3 x).const_mul (K / 12))
      convert this using 1
      · funext y; simp only [id, Pi.sub_apply]
      · norm_num; ring)
    (a := 0) (b := L / 2)
    (fun x hx => by
      have := hA x hx
      linarith)
  -- D: sag on the right half
  have hD := beam_sub_const_of_deriv_eq (f := v)
    (g := fun x => deriv v L * (x - L) - K / 12 * (L - x) ^ 3)
    (g' := fun x => deriv v L + K / 4 * (L - x) ^ 2) hv
    (fun x => by
      have := (((hasDerivAt_id x).sub_const L).const_mul (deriv v L)).sub
        ((((hasDerivAt_id x).const_sub L).pow 3).const_mul (K / 12))
      convert this using 1
      · funext y; simp only [id, Pi.pow_apply, Pi.sub_apply]
      · simp only [id]; norm_num; ring)
    (a := L / 2) (b := L)
    (fun x hx => by
      have := hB x hx
      linarith)
  have hCm := hC (L / 2) ⟨by linarith, le_refl _⟩
  have hDL := hD L ⟨by linarith, le_refl L⟩
  have hsum : (deriv v 0 + deriv v L) * L = 0 := by
    rw [h0, hLend] at *
    linear_combination -2 * hCm - 2 * hDL
  have hsum' : deriv v 0 + deriv v L = 0 := by
    rcases mul_eq_zero.mp hsum with h | h
    · exact h
    · exact absurd h hL.ne'
  have hu0 : deriv v 0 = K * L ^ 2 / 16 := by
    linear_combination (-1/2) * hAm - (1/2) * hBL + (1/2) * hsum'
  intro x hx
  have := hC x hx
  rw [h0, hu0] at this
  have hx' : v x = K * L ^ 2 / 16 * x - K / 12 * x ^ 3 := by linarith
  rw [hx', hK]
  field_simp
  ring

#print axioms beam_sub_const_of_deriv_eq
#print axioms beam_sag_left

/-- The mid-span sag of a pinned beam. A beam of span `L > 0` and bending stiffness `E I`
(with `E > 0`, `I > 0`) rests on a pin at each end and carries a load `P` at mid-span, so the
bending moment at `x` is `M(x) = P * min x (L - x) / 2`. If its sag `v` (twice differentiable)
satisfies `E I v''(x) = -M(x)` along the span and `v(0) = v(L) = 0`, then the sag at
mid-span is `δ = v(L/2) = P L^3 / (48 E I)`. -/
theorem midspan_sag_eq_PL_cubed_div_48EI (P L E I : ℝ) (hL : 0 < L) (hE : 0 < E) (hI : 0 < I)
    (v : ℝ → ℝ) (hv : Differentiable ℝ v) (hv' : Differentiable ℝ (deriv v))
    (hbend : ∀ x ∈ Set.Icc 0 L, E * I * deriv (deriv v) x = -(P * min x (L - x) / 2))
    (h0 : v 0 = 0) (hLend : v L = 0) :
    v (L / 2) = P * L ^ 3 / (48 * E * I) := by
  rw [beam_sag_left P L E I hL hE hI v hv hv' hbend h0 hLend (L / 2) ⟨by linarith, le_refl _⟩]
  have hEI : E * I ≠ 0 := by positivity
  field_simp
  ring

/-- The sag curve. Under the same conditions, on the left half of the span the sag is
`v(x) = P x (3 L^2 - 4 x^2) / (48 E I)` for `0 ≤ x ≤ L/2` (mirrored on the right half). -/
theorem sag_curve_left_half (P L E I : ℝ) (hL : 0 < L) (hE : 0 < E) (hI : 0 < I)
    (v : ℝ → ℝ) (hv : Differentiable ℝ v) (hv' : Differentiable ℝ (deriv v))
    (hbend : ∀ x ∈ Set.Icc 0 L, E * I * deriv (deriv v) x = -(P * min x (L - x) / 2))
    (h0 : v 0 = 0) (hLend : v L = 0) :
    ∀ x ∈ Set.Icc 0 (L / 2), v x = P * x * (3 * L ^ 2 - 4 * x ^ 2) / (48 * E * I) := by
  exact beam_sag_left P L E I hL hE hI v hv hv' hbend h0 hLend

/-- The second road, through energy. With the moment `M(x) = P * min x (L - x) / 2` of a
load `P ≠ 0` at mid-span of a span `L > 0`, the sag found from the stored energy,
`δ = (1/P) ∫₀ᴸ M(x)^2 / (E I) dx`, is again `P L^3 / (48 E I)`. -/
theorem energy_sag_eq_PL_cubed_div_48EI (P L E I : ℝ) (hP : P ≠ 0) (hL : 0 < L)
    (hE : 0 < E) (hI : 0 < I) :
    (1 / P) * ∫ x in (0 : ℝ)..L, (P * min x (L - x) / 2) ^ 2 / (E * I)
      = P * L ^ 3 / (48 * E * I) := by
  have hEI : E * I ≠ 0 := by positivity
  have hcont : Continuous (fun x : ℝ => (P * min x (L - x) / 2) ^ 2 / (E * I)) := by
    fun_prop
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := L / 2)
    (hcont.intervalIntegrable _ _) (hcont.intervalIntegrable _ _)]
  set c := P ^ 2 / (4 * E * I) / 3 with hc
  have h1 : ∫ x in (0 : ℝ)..L / 2, (P * min x (L - x) / 2) ^ 2 / (E * I)
      = c * (L / 2) ^ 3 - c * 0 ^ 3 := by
    refine intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun x => c * x ^ 3)
      (fun x hx => ?_) (hcont.intervalIntegrable _ _)
    rw [Set.uIcc_of_le (by linarith)] at hx
    have := (hasDerivAt_pow 3 x).const_mul c
    convert this using 1
    rw [min_eq_left (by linarith [hx.2]), hc]
    field_simp
    ring
  have h2 : ∫ x in L / 2..L, (P * min x (L - x) / 2) ^ 2 / (E * I)
      = -c * (L - L) ^ 3 - -c * (L - L / 2) ^ 3 := by
    refine intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun x => -c * (L - x) ^ 3)
      (fun x hx => ?_) (hcont.intervalIntegrable _ _)
    rw [Set.uIcc_of_le (by linarith)] at hx
    have := (((hasDerivAt_id' x).const_sub L).pow 3).const_mul (-c)
    convert this using 1
    rw [min_eq_right (by linarith [hx.1]), hc]
    field_simp
    ring
  rw [h1, h2, hc]
  field_simp
  ring

-- The card's whole-number worked steps.
-- Largest bending moment: P L / 4 = 2000 * 4 / 4 = 2000 N m.
example : (2000 : ℝ) * 4 / 4 = 2000 := by norm_num
-- The moment M(x) = P min(x, L - x) / 2 at mid-span x = 2 m of the 4 m joist is 2000 N m.
example : (2000 : ℝ) * min 2 (4 - 2) / 2 = 2000 := by norm_num
-- Stress limit: 60% of the 275 MPa yield stress is 165 MPa.
example : (3 / 5 : ℚ) * 275 = 165 := by norm_num
-- Clamped ends: P L^3 / (192 E I) is a quarter of P L^3 / (48 E I).
example : (192 : ℕ) = 4 * 48 := by decide

#print axioms midspan_sag_eq_PL_cubed_div_48EI
#print axioms sag_curve_left_half
#print axioms energy_sag_eq_PL_cubed_div_48EI
