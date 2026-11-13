-- Barrier Greeks: for a down-and-out call priced as a call minus its mirror image, the price is zero at the barrier, the delta there is twice the call's delta plus a C(B)/B, the gamma there is -(1 + a)/B times that delta, and the vega there is zero.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic

lemma bgw_div_hasDerivAt (k S : ℝ) (hS : 0 < S) :
    HasDerivAt (fun S : ℝ => k / S) (-(k / S) / S) S := by
  have h := (hasDerivAt_inv hS.ne').const_mul k
  simp only [← div_eq_mul_inv] at h
  convert h using 1
  field_simp

lemma bgw_pow_hasDerivAt (B a S : ℝ) (hB : 0 < B) (hS : 0 < S) :
    HasDerivAt (fun S : ℝ => (B / S) ^ a) (-(a / S) * (B / S) ^ a) S := by
  have hpos : 0 < B / S := div_pos hB hS
  have h := (bgw_div_hasDerivAt B S hS).rpow_const (p := a) (Or.inl hpos.ne')
  convert h using 1
  rw [Real.rpow_sub_one hpos.ne']
  field_simp

lemma bgw_V_hasDerivAt (C : ℝ → ℝ) (B a S c1 c2 : ℝ) (hB : 0 < B) (hS : 0 < S)
    (h1 : HasDerivAt C c1 S) (h2 : HasDerivAt C c2 (B ^ 2 / S)) :
    HasDerivAt (fun S : ℝ => C S - (B / S) ^ a * C (B ^ 2 / S))
      (c1 + (B / S) ^ a * (a / S * C (B ^ 2 / S) + (B ^ 2 / S) / S * c2)) S := by
  have hx := bgw_div_hasDerivAt (B ^ 2) S hS
  have hcomp : HasDerivAt (fun S : ℝ => C (B ^ 2 / S)) (c2 * (-(B ^ 2 / S) / S)) S :=
    h2.comp S hx
  have := h1.sub ((bgw_pow_hasDerivAt B a S hB hS).mul hcomp)
  convert this using 1
  ring

#print axioms bgw_div_hasDerivAt
#print axioms bgw_pow_hasDerivAt
#print axioms bgw_V_hasDerivAt

/-- The card's wall formulas. Let `C` be the plain call's price as a function of the share
price, smooth (twice continuously differentiable) for positive prices, and let the down-and-out
call be `V(S) = C(S) - (B/S)^a C(B^2/S)` with barrier `B > 0`. At the wall `S = B` the price is
zero, the delta is `V'(B) = 2 Δ(B) + a C(B)/B` (twice the plain delta plus a drift piece), and the
gamma is `V''(B) = -((1 + a)/B) V'(B)`: the plain gamma cancels exactly. -/
theorem down_out_wall_delta_and_gamma (C : ℝ → ℝ) (B a : ℝ) (hB : 0 < B)
    (hC : ContDiffOn ℝ 2 C (Set.Ioi 0)) :
    let V : ℝ → ℝ := fun S => C S - (B / S) ^ a * C (B ^ 2 / S)
    V B = 0 ∧
    HasDerivAt V (2 * deriv C B + a * C B / B) B ∧
    HasDerivAt (deriv V) (-((1 + a) / B) * (2 * deriv C B + a * C B / B)) B := by
  intro V
  have hBB : B ^ 2 / B = B := by field_simp
  have hopen : IsOpen (Set.Ioi (0 : ℝ)) := isOpen_Ioi
  have h2 : ContDiffOn ℝ ((1 : WithTop ℕ∞) + 1) C (Set.Ioi 0) := by
    simpa [one_add_one_eq_two] using hC
  obtain ⟨hd, -, hdd⟩ := (contDiffOn_succ_iff_deriv_of_isOpen hopen).1 h2
  have hdd' : DifferentiableOn ℝ (deriv C) (Set.Ioi 0) := hdd.differentiableOn one_ne_zero
  have hCd : ∀ x : ℝ, 0 < x → HasDerivAt C (deriv C x) x := fun x hx =>
    ((hd x hx).differentiableAt (hopen.mem_nhds hx)).hasDerivAt
  have hCdd : ∀ x : ℝ, 0 < x → HasDerivAt (deriv C) (deriv (deriv C) x) x := fun x hx =>
    ((hdd' x hx).differentiableAt (hopen.mem_nhds hx)).hasDerivAt
  have hpos : ∀ S : ℝ, 0 < S → 0 < B ^ 2 / S := fun S hS => div_pos (by positivity) hS
  have hVd : ∀ S : ℝ, 0 < S → HasDerivAt V
      (deriv C S + (B / S) ^ a * (a / S * C (B ^ 2 / S) + (B ^ 2 / S) / S * deriv C (B ^ 2 / S))) S :=
    fun S hS => bgw_V_hasDerivAt C B a S _ _ hB hS (hCd S hS) (hCd _ (hpos S hS))
  have hBa : (B / B) ^ a = 1 := by rw [div_self hB.ne', Real.one_rpow]
  refine ⟨?_, ?_, ?_⟩
  · simp only [V, hBB, hBa]; ring
  · convert hVd B hB using 1
    rw [hBB, hBa]; field_simp; ring
  · have heq : deriv V =ᶠ[nhds B] fun S =>
        deriv C S + (B / S) ^ a * (a / S * C (B ^ 2 / S) + (B ^ 2 / S) / S * deriv C (B ^ 2 / S)) := by
      filter_upwards [hopen.mem_nhds hB] with S hS
      exact (hVd S hS).deriv
    have hx := bgw_div_hasDerivAt (B ^ 2) B hB
    have hC1 : HasDerivAt C (deriv C B) (B ^ 2 / B) := by rw [hBB]; exact hCd B hB
    have hC2 : HasDerivAt (deriv C) (deriv (deriv C) B) (B ^ 2 / B) := by
      rw [hBB]; exact hCdd B hB
    have hCx : HasDerivAt (fun S : ℝ => C (B ^ 2 / S)) (deriv C B * (-(B ^ 2 / B) / B)) B :=
      hC1.comp B hx
    have hCdx : HasDerivAt (fun S : ℝ => deriv C (B ^ 2 / S))
        (deriv (deriv C) B * (-(B ^ 2 / B) / B)) B := hC2.comp B hx
    have hxS : HasDerivAt (fun S : ℝ => (B ^ 2 / S) / S)
        (((-(B ^ 2 / B) / B) * B - (B ^ 2 / B) * 1) / B ^ 2) B :=
      hx.div (hasDerivAt_id' B) hB.ne'
    have hall := (hCdd B hB).add ((bgw_pow_hasDerivAt B a B hB hB).mul
      (((bgw_div_hasDerivAt a B hB).mul hCx).add (hxS.mul hCdx)))
    refine HasDerivAt.congr_of_eventuallyEq ?_ heq
    convert hall using 1
    simp only [Pi.mul_apply, Pi.add_apply, hBB, hBa]; field_simp; ring

/-- The knock-out's delta at any share price `S > 0` is the plain delta plus an extra:
`V'(S) = Δ(S) + (B/S)^a [ (a/S) C(x) + (x/S) Δ(x) ]` with mirror price `x = B^2/S`. -/
theorem down_out_delta_formula (C : ℝ → ℝ) (B a S : ℝ) (hB : 0 < B) (hS : 0 < S)
    (hC : DifferentiableOn ℝ C (Set.Ioi 0)) :
    let V : ℝ → ℝ := fun S => C S - (B / S) ^ a * C (B ^ 2 / S)
    HasDerivAt V
      (deriv C S + (B / S) ^ a * (a / S * C (B ^ 2 / S) + (B ^ 2 / S) / S * deriv C (B ^ 2 / S))) S := by
  intro V
  have hopen : IsOpen (Set.Ioi (0 : ℝ)) := isOpen_Ioi
  have hCd : ∀ x : ℝ, 0 < x → HasDerivAt C (deriv C x) x := fun x hx =>
    ((hC x hx).differentiableAt (hopen.mem_nhds hx)).hasDerivAt
  exact bgw_V_hasDerivAt C B a S _ _ hB hS (hCd S hS) (hCd _ (div_pos (by positivity) hS))

/-- Vega is zero at the wall. Let `C S σ` be the plain call's price at share price `S` and
volatility `σ`, and let the drift exponent `a = 2(r - q)/σ^2 - 1` move with `σ`. Then the
down-and-out price `V(S, σ) = C(S, σ) - (B/S)^a C(B^2/S, σ)` at `S = B` has derivative zero in
`σ`, at every volatility. -/
theorem down_out_vega_zero_at_wall (C : ℝ → ℝ → ℝ) (B r q σ₀ : ℝ) (hB : 0 < B) :
    let V : ℝ → ℝ → ℝ := fun S σ =>
      C S σ - (B / S) ^ (2 * (r - q) / σ ^ 2 - 1) * C (B ^ 2 / S) σ
    HasDerivAt (fun σ => V B σ) 0 σ₀ := by
  intro V
  have hBB : B ^ 2 / B = B := by field_simp
  have h : (fun σ => V B σ) = fun _ => (0 : ℝ) := by
    funext σ
    simp only [V, hBB, div_self hB.ne', Real.one_rpow]; ring
  rw [h]
  exact hasDerivAt_const _ _

-- House market: r = 5%, q = 2%, σ = 20% give drift exponent a = 1/2.
example : 2 * ((5 : ℝ) / 100 - 2 / 100) / (20 / 100) ^ 2 - 1 = 1 / 2 := by norm_num
-- Mirror price at S = 100 with B = 80: x = 80^2/100 = 64.
example : (80 : ℝ) ^ 2 / 100 = 64 := by norm_num
-- Wall gamma factor (1 + a)/B with a = 1/2, B = 80: 1.5/80 = 3/160.
example : (1 + (1 : ℝ) / 2) / 80 = 3 / 160 := by norm_num
-- Static replication with r = q: a = -1, and K/B = 100/80 = 1.25 puts struck at B^2/K = 64.
example : 2 * ((2 : ℝ) / 100 - 2 / 100) / (20 / 100) ^ 2 - 1 = -1 := by norm_num
example : (100 : ℝ) / 80 = 5 / 4 ∧ (80 : ℝ) ^ 2 / 100 = 64 := by norm_num

#print axioms down_out_wall_delta_and_gamma
#print axioms down_out_delta_formula
#print axioms down_out_vega_zero_at_wall
