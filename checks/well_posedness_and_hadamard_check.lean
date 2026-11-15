-- Well posed: running the heat equation backwards on a square plate, and Hadamard's steady plate given value and slope on one edge, both fail the third demand, because no single constant bounds the change in the solution by the change in the data, and the backward growth factor of a fine pattern beats every power of its pattern number.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum

open Real Set

namespace WellPosednessAndHadamard

/-- A classical solution of the heat equation on the square plate `(0, L) × (0, L)` from
yesterday (`t = 0`) to today (`t = τ`), with the frame held at 0 above room temperature:
`u` is twice continuously differentiable in `(t, x, y)`, `u_t = κ (u_xx + u_yy)` inside the
plate for `0 ≤ t ≤ τ`, and `u = 0` on all four edges for `0 ≤ t ≤ τ`. -/
def IsPlateHeatSolution (κ L τ : ℝ) (u : ℝ → ℝ → ℝ → ℝ) : Prop :=
  ContDiff ℝ 2 (fun p : ℝ × ℝ × ℝ => u p.1 p.2.1 p.2.2) ∧
  (∀ t ∈ Icc 0 τ, ∀ x ∈ Ioo 0 L, ∀ y ∈ Ioo 0 L,
    deriv (fun s => u s x y) t =
      κ * (deriv (fun x' => deriv (fun x'' => u t x'' y) x') x +
        deriv (fun y' => deriv (fun y'' => u t x y'') y') y)) ∧
  (∀ t ∈ Icc 0 τ, ∀ z ∈ Icc 0 L,
    u t 0 z = 0 ∧ u t L z = 0 ∧ u t z 0 = 0 ∧ u t z L = 0)

lemma deriv_cos_mul_const (k c : ℝ) :
    deriv (fun x => cos (k * x) * c) = fun x => -(k * sin (k * x)) * c := by
  funext x
  have h := (((hasDerivAt_id x).const_mul k).cos).mul_const c
  simp only [id, mul_one] at h
  rw [h.deriv]; ring

#print axioms deriv_cos_mul_const

lemma deriv_sin_mul_const (k c : ℝ) :
    deriv (fun x => sin (k * x) * c) = fun x => (k * cos (k * x)) * c := by
  funext x
  have h := (((hasDerivAt_id x).const_mul k).sin).mul_const c
  simp only [id, mul_one] at h
  rw [h.deriv]; ring

#print axioms deriv_sin_mul_const

lemma deriv2_sin_mul_const (k c x : ℝ) :
    deriv (fun x' => deriv (fun x'' => sin (k * x'') * c) x') x = -(k ^ 2) * sin (k * x) * c := by
  rw [deriv_sin_mul_const]
  have e : (fun x' => (k * cos (k * x')) * c) = fun x' => cos (k * x') * (k * c) := by
    funext x'; ring
  rw [e, deriv_cos_mul_const]; ring

#print axioms deriv2_sin_mul_const

lemma deriv_exp_neg_mul_const (a c : ℝ) :
    deriv (fun s => exp (-a * s) * c) = fun s => -a * exp (-a * s) * c := by
  funext s
  have h := (((hasDerivAt_id s).const_mul (-a)).exp).mul_const c
  simp only [id, mul_one] at h
  rw [h.deriv]; ring

#print axioms deriv_exp_neg_mul_const

lemma heat_mode_isSolution (κ L τ k lam : ℝ) (hlam : lam = κ * (2 * k ^ 2))
    (hkL : sin (k * L) = 0) :
    IsPlateHeatSolution κ L τ (fun t x y => exp (-lam * t) * (sin (k * x) * sin (k * y))) := by
  refine ⟨?_, ?_, ?_⟩
  · fun_prop
  · intro t _ x _ y _
    simp only
    rw [deriv_exp_neg_mul_const]
    have e1 : (fun x'' => exp (-lam * t) * (sin (k * x'') * sin (k * y))) =
        fun x'' => sin (k * x'') * (exp (-lam * t) * sin (k * y)) := by funext x''; ring
    have e2 : (fun y'' => exp (-lam * t) * (sin (k * x) * sin (k * y''))) =
        fun y'' => sin (k * y'') * (exp (-lam * t) * sin (k * x)) := by funext y''; ring
    rw [e1, e2, deriv2_sin_mul_const, deriv2_sin_mul_const, hlam]
    ring
  · intro t _ z _
    simp [hkL]

#print axioms heat_mode_isSolution

lemma factor_beats_power_pos (κ L τ : ℝ) (hκ : 0 < κ) (hL : 0 < L)
    (hτ : 0 < τ) (C : ℝ) (p : ℕ) :
    ∃ m : ℕ, 1 ≤ m ∧
      C * (m : ℝ) ^ p < exp (κ * π ^ 2 * ((m : ℝ) ^ 2 + (m : ℝ) ^ 2) / L ^ 2 * τ) := by
  set b : ℝ := 2 * κ * π ^ 2 / L ^ 2 * τ with hbdef
  have hb : 0 < b := by positivity
  have hc : (0 : ℝ) < 1 / (|C| + 1) := by positivity
  have h1 := (isLittleO_pow_exp_pos_mul_atTop p hb).def hc
  have h2 := (tendsto_natCast_atTop_atTop (R := ℝ)).eventually h1
  obtain ⟨m, hm, hm1⟩ := (h2.and (Filter.eventually_ge_atTop 1)).exists
  refine ⟨m, hm1, ?_⟩
  have hm1' : (1 : ℝ) ≤ m := by exact_mod_cast hm1
  have hexp : exp (b * m) ≤ exp (κ * π ^ 2 * ((m : ℝ) ^ 2 + (m : ℝ) ^ 2) / L ^ 2 * τ) := by
    apply exp_le_exp.mpr
    have : κ * π ^ 2 * ((m : ℝ) ^ 2 + (m : ℝ) ^ 2) / L ^ 2 * τ = b * (m * m) := by
      rw [hbdef]; ring
    rw [this]
    apply mul_le_mul_of_nonneg_left _ hb.le
    nlinarith
  simp only [norm_pow, Real.norm_eq_abs, abs_exp] at hm
  have hm0 : (0:ℝ) ≤ m := by linarith
  rw [abs_of_nonneg hm0] at hm
  have hmp : 0 ≤ (m:ℝ) ^ p := by positivity
  have key : (|C| + 1) * (m:ℝ) ^ p ≤ exp (b * m) := by
    have := mul_le_mul_of_nonneg_left hm (by positivity : (0:ℝ) ≤ |C| + 1)
    calc (|C| + 1) * (m:ℝ) ^ p ≤ (|C| + 1) * (1 / (|C| + 1) * exp (b * m)) := this
      _ = exp (b * m) := by field_simp
  have hmp' : 0 < (m:ℝ) ^ p := by positivity
  calc C * (m:ℝ) ^ p ≤ |C| * (m:ℝ) ^ p := mul_le_mul_of_nonneg_right (le_abs_self C) hmp
    _ < (|C| + 1) * (m:ℝ) ^ p := by nlinarith
    _ ≤ exp (b * m) := key
    _ ≤ _ := hexp

#print axioms factor_beats_power_pos

/-- Hadamard's third demand for heat run backwards, with size measured as the largest
absolute value over the closed plate: one constant `C` serves for all pairs of solutions,
so that whenever today's pictures differ by at most `δ` everywhere on the plate, yesterday's
temperatures differ by at most `C δ` everywhere on the plate. -/
def BackwardHeatStable (κ L τ C : ℝ) : Prop :=
  ∀ u₁ u₂ : ℝ → ℝ → ℝ → ℝ, IsPlateHeatSolution κ L τ u₁ → IsPlateHeatSolution κ L τ u₂ →
    ∀ δ : ℝ, (∀ x ∈ Icc 0 L, ∀ y ∈ Icc 0 L, |u₁ τ x y - u₂ τ x y| ≤ δ) →
      ∀ x ∈ Icc 0 L, ∀ y ∈ Icc 0 L, |u₁ 0 x y - u₂ 0 x y| ≤ C * δ

/-- Backward heat is ill posed, however short the time gone back. On a square plate of
side `L > 0` with diffusivity `κ > 0` and its edges held at 0, rebuilding yesterday's
temperature from today's picture `τ > 0` seconds later fails the third demand in the
largest-value measure: no constant `C` bounds how far yesterday's temperatures can move
by `C` times how far today's pictures move. -/
theorem backward_heat_not_stable (κ L τ : ℝ) (hκ : 0 < κ) (hL : 0 < L) (hτ : 0 < τ) :
    ¬ ∃ C : ℝ, BackwardHeatStable κ L τ C := by
  rintro ⟨C, hC⟩
  obtain ⟨m, hm1, hm⟩ := factor_beats_power_pos κ L τ hκ hL hτ C 0
  simp only [pow_zero, mul_one] at hm
  set lam : ℝ := κ * π ^ 2 * ((m : ℝ) ^ 2 + (m : ℝ) ^ 2) / L ^ 2 with hlamdef
  set k : ℝ := π * m / L with hkdef
  have hm1' : (1 : ℝ) ≤ m := by exact_mod_cast hm1
  have hlam : lam = κ * (2 * k ^ 2) := by rw [hlamdef, hkdef]; field_simp; ring
  have hkL' : k * L = m * π := by rw [hkdef]; field_simp
  have hkL : sin (k * L) = 0 := by rw [hkL']; exact sin_nat_mul_pi m
  have hsol := heat_mode_isSolution κ L τ k lam hlam hkL
  have h0 : IsPlateHeatSolution κ L τ (fun _ _ _ => 0) := by
    have := heat_mode_isSolution κ L τ 0 0 (by ring) (by simp)
    simpa using this
  have hdata : ∀ x ∈ Icc 0 L, ∀ y ∈ Icc 0 L,
      |(fun t x y => exp (-lam * t) * (sin (k * x) * sin (k * y))) τ x y -
        (fun (_ _ _ : ℝ) => (0:ℝ)) τ x y| ≤ exp (-lam * τ) := by
    intro x _ y _
    simp only [sub_zero]
    rw [abs_mul, abs_mul, abs_of_pos (exp_pos _)]
    have h1 := abs_sin_le_one (k * x)
    have h2 := abs_sin_le_one (k * y)
    have h3 : |sin (k * x)| * |sin (k * y)| ≤ 1 := by
      nlinarith [abs_nonneg (sin (k * x)), abs_nonneg (sin (k * y))]
    have := exp_pos (-lam * τ)
    nlinarith
  set x0 : ℝ := L / (2 * m) with hx0
  have hx0mem : x0 ∈ Icc 0 L := by
    constructor
    · positivity
    · rw [hx0, div_le_iff₀ (by positivity)]; nlinarith
  have hkx0 : k * x0 = π / 2 := by rw [hkdef, hx0]; field_simp
  have h := hC _ _ hsol h0 _ hdata x0 hx0mem x0 hx0mem
  simp only [mul_zero, exp_zero, sub_zero, hkx0, sin_pi_div_two, mul_one,
    abs_one] at h
  have hE : exp (-lam * τ) * exp (lam * τ) = 1 := by rw [← exp_add]; simp
  have hEpos := exp_pos (-lam * τ)
  nlinarith

/-- The backward growth factor has no ceiling, and no measure of size that counts a fixed
number of derivatives rescues it. Going back `τ > 0` seconds multiplies pattern `(m, m)` by
`A_mm(τ) = e^(λ_mm τ)` with `λ_mm = κ π² (m² + m²) / L²`. For every constant `C` and every
number of derivatives `p` (each derivative weighting pattern `m` by about `m`), some pattern
`m` grows by more than `C m^p`: an exponential beats every power. With `p = 0` this says the
factors exceed every constant. -/
theorem backward_factor_beats_every_power (κ L τ : ℝ) (hκ : 0 < κ) (hL : 0 < L)
    (hτ : 0 < τ) (C : ℝ) (p : ℕ) :
    ∃ m : ℕ, C * (m : ℝ) ^ p < exp (κ * π ^ 2 * ((m : ℝ) ^ 2 + (m : ℝ) ^ 2) / L ^ 2 * τ) := by
  obtain ⟨m, _, hm⟩ := factor_beats_power_pos κ L τ hκ hL hτ C p
  exact ⟨m, hm⟩

/-- A classical solution of Hadamard's problem on the steady square plate `(0, L) × (0, L)`:
`u` is twice continuously differentiable, solves Laplace's equation `u_xx + u_yy = 0` inside
the plate, and has value 0 on the bottom edge `y = 0`; the other edges are left free. Its
data is its slope up the plate on the bottom edge, `u_y(x, 0)`. -/
def IsHadamardSolution (L : ℝ) (u : ℝ → ℝ → ℝ) : Prop :=
  ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2) ∧
  (∀ x ∈ Ioo 0 L, ∀ y ∈ Ioo 0 L,
    deriv (fun x' => deriv (fun x'' => u x'' y) x') x +
      deriv (fun y' => deriv (fun y'' => u x y'') y') y = 0) ∧
  (∀ x ∈ Icc 0 L, u x 0 = 0)

lemma deriv_const_mul_sinh (k c : ℝ) :
    deriv (fun y => c * sinh (k * y)) = fun y => c * (k * cosh (k * y)) := by
  funext y
  have h := (((hasDerivAt_id y).const_mul k).sinh).const_mul c
  simp only [id, mul_one] at h
  rw [h.deriv]; ring

#print axioms deriv_const_mul_sinh

lemma deriv_const_mul_cosh (k c : ℝ) :
    deriv (fun y => c * cosh (k * y)) = fun y => c * (k * sinh (k * y)) := by
  funext y
  have h := (((hasDerivAt_id y).const_mul k).cosh).const_mul c
  simp only [id, mul_one] at h
  rw [h.deriv]; ring

#print axioms deriv_const_mul_cosh

lemma hadamard_mode_isSolution (L k : ℝ) :
    IsHadamardSolution L (fun x y => cos (k * x) * sinh (k * y)) := by
  refine ⟨?_, ?_, ?_⟩
  · fun_prop
  · intro x _ y _
    simp only
    rw [deriv_cos_mul_const, deriv_const_mul_sinh]
    have e1 : (fun x' => -(k * sin (k * x')) * sinh (k * y)) =
        fun x' => sin (k * x') * (-k * sinh (k * y)) := by funext x'; ring
    have e2 : (fun y' => cos (k * x) * (k * cosh (k * y'))) =
        fun y' => (cos (k * x) * k) * cosh (k * y') := by funext y'; ring
    rw [e1, e2, deriv_sin_mul_const, deriv_const_mul_cosh]
    ring
  · intro x _
    simp

#print axioms hadamard_mode_isSolution

lemma sinh_ge_sq_div_four {y : ℝ} (hy : 0 ≤ y) : y ^ 2 / 4 ≤ sinh y := by
  rw [sinh_eq]
  have h1 := quadratic_le_exp_of_nonneg hy
  have h2 : exp (-y) ≤ 1 := by rw [exp_le_one_iff]; linarith
  nlinarith

#print axioms sinh_ge_sq_div_four

/-- Hadamard's example: Laplace's equation given value and slope on one edge fails the third
demand. On a square plate of side `L > 0`, with value 0 on the bottom edge and the slope
`u_y(x, 0)` as data, no constant `C` makes every pair of solutions whose slope data differ by
at most `δ` along the bottom edge differ by at most `C δ` everywhere on the closed plate.
(The slope data `sin(kx)/k`, of size `1/k`, gives the solution `sin(kx) sinh(ky)/k²`.) -/
theorem hadamard_cauchy_laplace_not_stable (L : ℝ) (hL : 0 < L) :
    ¬ ∃ C : ℝ, ∀ u₁ u₂ : ℝ → ℝ → ℝ, IsHadamardSolution L u₁ → IsHadamardSolution L u₂ →
      ∀ δ : ℝ, (∀ x ∈ Icc 0 L,
          |deriv (fun y => u₁ x y) 0 - deriv (fun y => u₂ x y) 0| ≤ δ) →
        ∀ x ∈ Icc 0 L, ∀ y ∈ Icc 0 L, |u₁ x y - u₂ x y| ≤ C * δ := by
  rintro ⟨C, hC⟩
  set k : ℝ := (4 * |C| + 1) / L ^ 2 with hkdef
  have hk : 0 < k := by positivity
  have h0 : IsHadamardSolution L (fun _ _ => 0) := by
    have := hadamard_mode_isSolution L 0
    simpa using this
  have hdata : ∀ x ∈ Icc 0 L,
      |deriv (fun y => (fun x y => cos (k * x) * sinh (k * y)) x y) 0 -
        deriv (fun y => (fun (_ _ : ℝ) => (0:ℝ)) x y) 0| ≤ k := by
    intro x _
    simp only
    rw [deriv_const_mul_sinh]
    simp only [mul_zero, cosh_zero, mul_one, deriv_const, sub_zero]
    rw [abs_mul, abs_of_pos hk]
    have := abs_cos_le_one (k * x)
    nlinarith [abs_nonneg (cos (k * x))]
  have h := hC _ _ (hadamard_mode_isSolution L k) h0 k hdata 0 ⟨le_refl _, hL.le⟩ L
    ⟨hL.le, le_refl _⟩
  simp only [mul_zero, cos_zero, one_mul, sub_zero] at h
  have hs := sinh_ge_sq_div_four (mul_pos hk hL).le
  have hpos : 0 ≤ sinh (k * L) := le_trans (by positivity) hs
  rw [abs_of_nonneg hpos] at h
  have hCk : C * k ≤ |C| * k := mul_le_mul_of_nonneg_right (le_abs_self C) hk.le
  have hkL : k * L ^ 2 = 4 * |C| + 1 := by rw [hkdef]; field_simp
  nlinarith

-- The worked pattern (5, 5): m² + n² = 5² + 5² = 50.
example : (5 : ℕ) ^ 2 + 5 ^ 2 = 50 := by norm_num
-- Pattern (m, m) on the 100 cm plate has patches 100/m cm wide: 20 cm for m = 5, 10 cm for m = 10.
example : (100 : ℕ) / 5 = 20 ∧ (100 : ℕ) / 10 = 10 := by norm_num

#print axioms backward_heat_not_stable
#print axioms backward_factor_beats_every_power
#print axioms hadamard_cauchy_laplace_not_stable

end WellPosednessAndHadamard
