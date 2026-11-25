-- General elliptic operators: for the river operator L u = -u'' + 2u' on (0, 1) with zero ends, this file proves the Fredholm test at the principal eigenvalue pi^2 + 1, the eigenpairs k^2 pi^2 + 1 with positive principal and adjoint modes and Hopf's slopes, and that the principal eigenvalue is simple with the only positive mode.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue

open Real Set

lemma river_hd_sin (c x : ℝ) : HasDerivAt (fun y => sin (c * y)) (c * cos (c * x)) x := by
  have := ((hasDerivAt_id x).const_mul c).sin
  convert this using 1 <;> simp [mul_comm]

lemma river_hd_cos (c x : ℝ) : HasDerivAt (fun y => cos (c * y)) (-(c * sin (c * x))) x := by
  have := ((hasDerivAt_id x).const_mul c).cos
  convert this using 1 <;> simp [mul_comm]

lemma river_hd_expneg (x : ℝ) : HasDerivAt (fun y => exp (-y)) (-exp (-x)) x := by
  have := (hasDerivAt_neg x).exp
  convert this using 1; ring

lemma river_C2 {u : ℝ → ℝ} (hu : ContDiff ℝ 2 u) :
    Differentiable ℝ u ∧ Differentiable ℝ (deriv u) ∧ Continuous (deriv (deriv u)) := by
  have h := contDiff_succ_iff_deriv.mp (show ContDiff ℝ (1 + 1) u from hu)
  refine ⟨h.1, ?_, ?_⟩
  · exact (contDiff_one_iff_deriv.mp h.2.2).1
  · exact (contDiff_one_iff_deriv.mp h.2.2).2

lemma river_of_derivs {u u1 u2 : ℝ → ℝ} (h1 : ∀ x, HasDerivAt u (u1 x) x)
    (h2 : ∀ x, HasDerivAt u1 (u2 x) x) (hc : Continuous u2) :
    ContDiff ℝ 2 u ∧ deriv u = u1 ∧ deriv u1 = u2 := by
  have e1 : deriv u = u1 := funext fun x => (h1 x).deriv
  have e2 : deriv u1 = u2 := funext fun x => (h2 x).deriv
  refine ⟨?_, e1, e2⟩
  rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
  refine ⟨fun x => (h1 x).differentiableAt, by simp, ?_⟩
  rw [e1, contDiff_one_iff_deriv, e2]
  exact ⟨fun x => (h2 x).differentiableAt, hc⟩

lemma river_deriv_es (c : ℝ) :
    deriv (fun y => exp y * sin (c * y)) = fun x => exp x * (sin (c * x) + c * cos (c * x)) := by
  funext x
  have := (hasDerivAt_exp x).fun_mul (river_hd_sin c x)
  rw [this.deriv]; ring

lemma river_deriv_es2 (c : ℝ) :
    deriv (fun x => exp x * (sin (c * x) + c * cos (c * x))) =
      fun x => exp x * ((1 - c ^ 2) * sin (c * x) + 2 * c * cos (c * x)) := by
  funext x
  have := (hasDerivAt_exp x).fun_mul ((river_hd_sin c x).fun_add ((river_hd_cos c x).const_mul c))
  rw [this.deriv]; ring

lemma river_deriv_ens :
    deriv (fun y => exp (-y) * sin (π * y)) =
      fun x => exp (-x) * (π * cos (π * x) - sin (π * x)) := by
  funext x
  have := (river_hd_expneg x).fun_mul (river_hd_sin π x)
  rw [this.deriv]; ring

lemma river_deriv_ens2 :
    deriv (fun x => exp (-x) * (π * cos (π * x) - sin (π * x))) =
      fun x => exp (-x) * ((1 - π ^ 2) * sin (π * x) - 2 * π * cos (π * x)) := by
  funext x
  have := (river_hd_expneg x).fun_mul (((river_hd_cos π x).const_mul π).fun_sub (river_hd_sin π x))
  rw [this.deriv]; ring

#print axioms river_hd_sin
#print axioms river_hd_cos
#print axioms river_hd_expneg
#print axioms river_C2
#print axioms river_of_derivs
#print axioms river_deriv_es
#print axioms river_deriv_es2
#print axioms river_deriv_ens
#print axioms river_deriv_ens2

/-- The Fredholm alternative at the principal eigenvalue, for the river: with a continuous
source `f`, the problem `-u'' + 2u' - (π² + 1) u = f` on `(0, 1)` with `u(0) = u(1) = 0` has a
classical (twice continuously differentiable) solution exactly when the source scores zero
against the adjoint's positive mode: `∫₀¹ f(x) e^{-x} sin(πx) dx = 0`. -/
theorem river_fredholm_alternative_at_principal_eigenvalue (f : ℝ → ℝ) (hf : Continuous f) :
    (∃ u : ℝ → ℝ, ContDiff ℝ 2 u ∧ u 0 = 0 ∧ u 1 = 0 ∧
        ∀ x ∈ Ioo (0 : ℝ) 1,
          -deriv (deriv u) x + 2 * deriv u x - (π ^ 2 + 1) * u x = f x) ↔
      ∫ x in (0 : ℝ)..1, f x * (exp (-x) * sin (π * x)) = 0 := by
  constructor
  · rintro ⟨u, hu, h0, h1, heq⟩
    obtain ⟨hd, hd', hc''⟩ := river_C2 hu
    have hc' : Continuous (deriv u) := hd'.continuous
    set F : ℝ → ℝ := fun x => -deriv u x * (exp (-x) * sin (π * x))
      + u x * (exp (-x) * (π * cos (π * x) - sin (π * x)))
      + 2 * u x * (exp (-x) * sin (π * x)) with hFdef
    have hFc : Continuous F := by
      simp only [hFdef]; fun_prop
    have hF : ∀ x ∈ Ioo (0 : ℝ) 1, HasDerivAt F (f x * (exp (-x) * sin (π * x))) x := by
      intro x hx
      have hv := (river_hd_expneg x).fun_mul (river_hd_sin π x)
      have hv' := (river_hd_expneg x).fun_mul
        (((river_hd_cos π x).const_mul π).fun_sub (river_hd_sin π x))
      have hux := (hd x).hasDerivAt
      have hux' := (hd' x).hasDerivAt
      have := ((hux'.fun_neg.fun_mul hv).fun_add (hux.fun_mul hv')).fun_add
        ((hux.const_mul 2).fun_mul hv)
      convert this using 1
      have e := heq x hx
      linear_combination (-(exp (-x) * sin (π * x))) * e
    have key := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le zero_le_one
      hFc.continuousOn hF
      ((by fun_prop : Continuous fun x => f x * (exp (-x) * sin (π * x))).intervalIntegrable 0 1)
    rw [key]
    simp [hFdef, h0, h1]
  · intro hI
    set A : ℝ → ℝ := fun x => ∫ t in (0 : ℝ)..x, f t * (exp (-t) * cos (π * t)) with hAdef
    set B : ℝ → ℝ := fun x => ∫ t in (0 : ℝ)..x, f t * (exp (-t) * sin (π * t)) with hBdef
    have hA : ∀ x, HasDerivAt A (f x * (exp (-x) * cos (π * x))) x := fun x =>
      ((by fun_prop : Continuous fun t => f t * (exp (-t) * cos (π * t))).integral_hasStrictDerivAt
        0 x).hasDerivAt
    have hB : ∀ x, HasDerivAt B (f x * (exp (-x) * sin (π * x))) x := fun x =>
      ((by fun_prop : Continuous fun t => f t * (exp (-t) * sin (π * t))).integral_hasStrictDerivAt
        0 x).hasDerivAt
    have hA0 : A 0 = 0 := by simp [hAdef]
    have hB0 : B 0 = 0 := by simp [hBdef]
    have hB1 : B 1 = 0 := hI
    have hAc : Continuous A := continuous_iff_continuousAt.2 fun x => (hA x).continuousAt
    have hBc : Continuous B := continuous_iff_continuousAt.2 fun x => (hB x).continuousAt
    clear_value A B
    have hpi : π ≠ 0 := pi_ne_zero
    set w : ℝ → ℝ := fun x => π⁻¹ * (cos (π * x) * B x - sin (π * x) * A x) with hw
    set w1 : ℝ → ℝ := fun x => -(sin (π * x) * B x + cos (π * x) * A x) with hw1
    set w2 : ℝ → ℝ := fun x => -π * (cos (π * x) * B x - sin (π * x) * A x) - exp (-x) * f x
      with hw2
    have dw : ∀ x, HasDerivAt w (w1 x) x := by
      intro x
      have := (((river_hd_cos π x).fun_mul (hB x)).fun_sub ((river_hd_sin π x).fun_mul (hA x))).const_mul π⁻¹
      convert this using 1
      simp only [hw1]; field_simp; ring
    have dw1 : ∀ x, HasDerivAt w1 (w2 x) x := by
      intro x
      have := (((river_hd_sin π x).fun_mul (hB x)).fun_add ((river_hd_cos π x).fun_mul (hA x))).fun_neg
      convert this using 1
      simp only [hw2]
      linear_combination (exp (-x) * f x) * sin_sq_add_cos_sq (π * x)
    have du : ∀ x, HasDerivAt (fun x => exp x * w x) (exp x * (w x + w1 x)) x := by
      intro x
      have := (hasDerivAt_exp x).fun_mul (dw x)
      convert this using 1; ring
    have du1 : ∀ x, HasDerivAt (fun x => exp x * (w x + w1 x))
        (exp x * (w x + 2 * w1 x + w2 x)) x := by
      intro x
      have := (hasDerivAt_exp x).fun_mul ((dw x).fun_add (dw1 x))
      convert this using 1; ring
    have hc2 : Continuous fun x => exp x * (w x + 2 * w1 x + w2 x) := by
      simp only [hw, hw1, hw2]; fun_prop
    obtain ⟨hC, e1, e2⟩ := river_of_derivs du du1 hc2
    refine ⟨fun x => exp x * w x, hC, ?_, ?_, fun x _ => ?_⟩
    · simp [hw, hA0, hB0]
    · simp [hw, hB1]
    · rw [e1, e2]
      have hex : exp x * exp (-x) = 1 := by rw [← exp_add]; simp
      simp only [hw, hw1, hw2]
      field_simp
      linear_combination π * f x * hex

/-- The river's eigenpairs: for every `k ≥ 1`, `eˣ sin(kπx)` vanishes at both ends and solves
`-φ'' + 2φ' = (k²π² + 1) φ`. The principal mode `eˣ sin(πx)` and the adjoint mode
`e^{-x} sin(πx)` are both positive inside; the adjoint mode solves `-v'' - 2v' = (π² + 1) v`
with zero ends; and the principal mode leaves the ends at Hopf's nonzero slopes
`φ'(0) = π` and `φ'(1) = -eπ`. -/
theorem river_eigenpairs_positive_modes_and_hopf_slopes :
    (∀ k : ℕ, 1 ≤ k →
      (∀ x : ℝ,
        -deriv (deriv fun y => exp y * sin (k * π * y)) x
            + 2 * deriv (fun y => exp y * sin (k * π * y)) x
          = ((k : ℝ) ^ 2 * π ^ 2 + 1) * (exp x * sin (k * π * x))) ∧
      exp 0 * sin (k * π * 0) = 0 ∧ exp 1 * sin (k * π * 1) = 0) ∧
    (∀ x ∈ Ioo (0 : ℝ) 1, 0 < exp x * sin (π * x) ∧ 0 < exp (-x) * sin (π * x)) ∧
    (∀ x : ℝ,
      -deriv (deriv fun y => exp (-y) * sin (π * y)) x
          - 2 * deriv (fun y => exp (-y) * sin (π * y)) x
        = (π ^ 2 + 1) * (exp (-x) * sin (π * x))) ∧
    exp (-0) * sin (π * 0) = 0 ∧ exp (-1) * sin (π * 1) = 0 ∧
    deriv (fun y => exp y * sin (π * y)) 0 = π ∧
    deriv (fun y => exp y * sin (π * y)) 1 = -(exp 1 * π) := by
  refine ⟨fun k _ => ⟨fun x => ?_, by simp, by simp [sin_nat_mul_pi]⟩, fun x hx => ?_, fun x => ?_,
    by simp, by simp, ?_, ?_⟩
  · rw [river_deriv_es, river_deriv_es2]; ring
  · have hs : 0 < sin (π * x) := sin_pos_of_pos_of_lt_pi (by nlinarith [pi_pos, hx.1])
      (by nlinarith [pi_pos, hx.2])
    exact ⟨mul_pos (exp_pos _) hs, mul_pos (exp_pos _) hs⟩
  · rw [river_deriv_ens, river_deriv_ens2]; ring
  · rw [river_deriv_es]; simp
  · rw [river_deriv_es]; simp

/-- The principal eigenvalue `π² + 1` is simple and its mode is the only positive one: every
twice continuously differentiable solution of `-u'' + 2u' = (π² + 1) u` on `(0, 1)` with
`u(0) = u(1) = 0` is a constant multiple of `eˣ sin(πx)` on `[0, 1]`, and every higher mode
`eˣ sin(kπx)` with `k ≥ 2` is negative somewhere inside. -/
theorem river_principal_eigenvalue_simple_and_only_positive_mode :
    (∀ u : ℝ → ℝ, ContDiff ℝ 2 u → u 0 = 0 → u 1 = 0 →
      (∀ x ∈ Ioo (0 : ℝ) 1, -deriv (deriv u) x + 2 * deriv u x = (π ^ 2 + 1) * u x) →
      ∃ c : ℝ, ∀ x ∈ Icc (0 : ℝ) 1, u x = c * (exp x * sin (π * x))) ∧
    (∀ k : ℕ, 2 ≤ k → ∃ x ∈ Ioo (0 : ℝ) 1, exp x * sin (k * π * x) < 0) := by
  constructor
  · intro u hu h0 h1 heq
    obtain ⟨hd, hd', hc''⟩ := river_C2 hu
    have hc' : Continuous (deriv u) := hd'.continuous
    set W : ℝ → ℝ := fun x =>
      exp (-x) * ((deriv u x - u x) * sin (π * x) - π * u x * cos (π * x)) with hWdef
    have hWc : Continuous W := by simp only [hWdef]; fun_prop
    have hW : ∀ x ∈ Ioo (0 : ℝ) 1, HasDerivAt W 0 x := by
      intro x hx
      have hux := (hd x).hasDerivAt
      have hux' := (hd' x).hasDerivAt
      have := (river_hd_expneg x).fun_mul
        (((hux'.fun_sub hux).fun_mul (river_hd_sin π x)).fun_sub
          ((hux.const_mul π).fun_mul (river_hd_cos π x)))
      convert this using 1
      have e := heq x hx
      linear_combination (exp (-x) * sin (π * x)) * e
    have hW0 : W 0 = 0 := by simp [hWdef, h0]
    have hWz : ∀ x ∈ Ioo (0 : ℝ) 1, W x = 0 := by
      intro x hx
      have key := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hx.1.le
        hWc.continuousOn (fun y hy => hW y ⟨hy.1, hy.2.trans hx.2⟩)
        (intervalIntegrable_const (c := (0 : ℝ)))
      simp only [intervalIntegral.integral_zero, hW0] at key
      linarith
    have hsin : ∀ x ∈ Ioo (0 : ℝ) 1, 0 < sin (π * x) := fun x hx =>
      sin_pos_of_pos_of_lt_pi (by nlinarith [pi_pos, hx.1]) (by nlinarith [pi_pos, hx.2])
    set q : ℝ → ℝ := fun x => exp (-x) * u x / sin (π * x) with hqdef
    have hq : ∀ x ∈ Ioo (0 : ℝ) 1, HasDerivAt q 0 x := by
      intro x hx
      have hs := (hsin x hx).ne'
      have := ((river_hd_expneg x).fun_mul (hd x).hasDerivAt).fun_div (river_hd_sin π x) hs
      convert this using 1
      have hw := hWz x hx
      simp only [hWdef] at hw
      rw [eq_comm, div_eq_zero_iff]
      left
      linear_combination hw
    have hconst : ∀ x ∈ Ioo (0 : ℝ) 1, q x = q (1 / 2) := fun x hx =>
      isOpen_Ioo.is_const_of_deriv_eq_zero isPreconnected_Ioo
        (fun y hy => (hq y hy).differentiableAt.differentiableWithinAt)
        (fun y hy => (hq y hy).deriv) hx ⟨by norm_num, by norm_num⟩
    refine ⟨q (1 / 2), fun x hx => ?_⟩
    rcases eq_or_lt_of_le hx.1 with h | h
    · subst h; simp [h0]
    rcases eq_or_lt_of_le hx.2 with h' | h'
    · subst h'; simp [h1]
    have hx' : x ∈ Ioo (0 : ℝ) 1 := ⟨h, h'⟩
    have e := hconst x hx'
    have hs := (hsin x hx').ne'
    have hex : exp x * exp (-x) = 1 := by rw [← exp_add]; simp
    rw [← e]
    simp only [hqdef]
    rw [eq_comm, div_mul_eq_mul_div, div_eq_iff hs]
    linear_combination (u x * sin (π * x)) * hex
  · intro k hk
    have hk' : (2 : ℝ) ≤ k := by exact_mod_cast hk
    refine ⟨3 / (2 * k), ⟨by positivity, by rw [div_lt_one (by positivity)]; linarith⟩, ?_⟩
    have harg : (k : ℝ) * π * (3 / (2 * k)) = π / 2 + π := by field_simp; ring
    rw [harg, sin_add_pi, sin_pi_div_two]
    have := exp_pos (3 / (2 * (k : ℝ)))
    linarith

-- The card's whole-number numbers: time unit T = (1000 m)² / κ = 100 days,
-- Péclet number 20 × 1000 / 10,000 = 2, and the drift's extra cost b²/4 = 2²/4 = 1.
example : (1000 : ℝ) ^ 2 / 10000 = 100 := by norm_num
example : (20 : ℝ) * 1000 / 10000 = 2 := by norm_num
example : (2 : ℝ) ^ 2 / 4 = 1 := by norm_num

#print axioms river_fredholm_alternative_at_principal_eigenvalue
#print axioms river_eigenpairs_positive_modes_and_hopf_slopes
#print axioms river_principal_eigenvalue_simple_and_only_positive_mode
