-- Canonical form: every constant-coefficient second-order equation in two variables becomes, after a linear change of coordinates with nonzero Jacobian, the plain wave, heat or Laplace equation up to lower-order terms, the coordinates come from the roots of A λ^2 - B λ + C = 0, and the moving strip's solutions are exactly F(x - (V + c)t) + G(x - (V - c)t).
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Data.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

namespace ReductionToCanonicalForm

open Complex

/-! A function of two variables is written curried, `u p q`. For the plane the variables are
`(x, y)`; for the strip they are `(t, x)`, time first, as on the card. -/

/-- The partial derivative in the first variable, `u_p`, at the point `(p, q)`. -/
noncomputable def d1 (u : ℝ → ℝ → ℝ) (p q : ℝ) : ℝ := deriv (fun s => u s q) p

/-- The partial derivative in the second variable, `u_q`, at the point `(p, q)`. -/
noncomputable def d2 (u : ℝ → ℝ → ℝ) (p q : ℝ) : ℝ := deriv (fun s => u p s) q

/-- The card's general equation's left side with constant coefficients,
`A u_pp + B u_pq + C u_qq + D u_p + E u_q + R u`, at `(p, q)`. Here `u_pq` is `(u_p)_q`, and
`R u` is the zeroth-order part of the card's "and the rest". -/
noncomputable def secondOrderOp (A B C D E R : ℝ) (u : ℝ → ℝ → ℝ) (p q : ℝ) : ℝ :=
  A * d1 (d1 u) p q + B * d2 (d1 u) p q + C * d2 (d2 u) p q + D * d1 u p q + E * d2 u p q
    + R * u p q

/-- The second-order part with each derivative replaced by a rate: `Q(p, q) = A p^2 + B p q + C q^2`.
For `ξ = a₁ x + b₁ y` the new coefficient `A'` is `Q(a₁, b₁)`; for `η = a₂ x + b₂ y`, `C'` is `Q(a₂, b₂)`. -/
def Q (A B C p q : ℝ) : ℝ := A * p ^ 2 + B * p * q + C * q ^ 2

/-- The new mixed coefficient `B' = 2A a₁ a₂ + B (a₁ b₂ + b₁ a₂) + 2C b₁ b₂`. -/
def Bmix (A B C a₁ b₁ a₂ b₂ : ℝ) : ℝ := 2 * A * a₁ * a₂ + B * (a₁ * b₂ + b₁ * a₂) + 2 * C * b₁ * b₂

/-- The Jacobian `J = a₁ b₂ - b₁ a₂` of the change `ξ = a₁ x + b₁ y`, `η = a₂ x + b₂ y`. -/
def jac (a₁ b₁ a₂ b₂ : ℝ) : ℝ := a₁ * b₂ - b₁ * a₂


open Function

lemma partial1_eq {U : ℝ × ℝ → ℝ} {p q : ℝ} (h : DifferentiableAt ℝ U (p, q)) :
    deriv (fun s => U (s, q)) p = fderiv ℝ U (p, q) (1, 0) := by
  have h1 : HasDerivAt (fun s : ℝ => (s, q)) ((1 : ℝ), (0 : ℝ)) p :=
    (hasDerivAt_id p).prodMk (hasDerivAt_const p q)
  exact (h.hasFDerivAt.comp_hasDerivAt p h1).deriv

lemma partial2_eq {U : ℝ × ℝ → ℝ} {p q : ℝ} (h : DifferentiableAt ℝ U (p, q)) :
    deriv (fun s => U (p, s)) q = fderiv ℝ U (p, q) (0, 1) := by
  have h1 : HasDerivAt (fun s : ℝ => (p, s)) ((0 : ℝ), (1 : ℝ)) q :=
    (hasDerivAt_const q p).prodMk (hasDerivAt_id q)
  exact (h.hasFDerivAt.comp_hasDerivAt q h1).deriv

lemma diff_fderiv_of_C2 {U : ℝ × ℝ → ℝ} (hU : ContDiff ℝ 2 U) :
    Differentiable ℝ (fderiv ℝ U) :=
  (hU.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)

lemma diff_apply_const {U : ℝ × ℝ → ℝ} (hU : ContDiff ℝ 2 U) (e : ℝ × ℝ) :
    Differentiable ℝ (fun y => fderiv ℝ U y e) :=
  fun z => (diff_fderiv_of_C2 hU z).clm_apply (differentiableAt_const e)

lemma fderiv_apply_const_eq {U : ℝ × ℝ → ℝ} (hU : ContDiff ℝ 2 U) (e v z : ℝ × ℝ) :
    fderiv ℝ (fun y => fderiv ℝ U y e) z v = fderiv ℝ (fderiv ℝ U) z v e := by
  rw [fderiv_clm_apply (diff_fderiv_of_C2 hU z) (differentiableAt_const e)]
  simp

lemma derivs_eq {u : ℝ → ℝ → ℝ} (hu : ContDiff ℝ 2 (uncurry u)) (p q : ℝ) :
    d1 u p q = fderiv ℝ (uncurry u) (p, q) (1, 0) ∧
    d2 u p q = fderiv ℝ (uncurry u) (p, q) (0, 1) ∧
    d1 (d1 u) p q = fderiv ℝ (fderiv ℝ (uncurry u)) (p, q) (1, 0) (1, 0) ∧
    d2 (d1 u) p q = fderiv ℝ (fderiv ℝ (uncurry u)) (p, q) (0, 1) (1, 0) ∧
    d2 (d2 u) p q = fderiv ℝ (fderiv ℝ (uncurry u)) (p, q) (0, 1) (0, 1) := by
  have hU1 : Differentiable ℝ (uncurry u) := hu.differentiable (by norm_num)
  have e1 : d1 u = fun p q => fderiv ℝ (uncurry u) (p, q) (1, 0) := by
    funext p q; exact partial1_eq (hU1 _)
  have e2 : d2 u = fun p q => fderiv ℝ (uncurry u) (p, q) (0, 1) := by
    funext p q; exact partial2_eq (hU1 _)
  refine ⟨partial1_eq (hU1 _), partial2_eq (hU1 _), ?_, ?_, ?_⟩
  · rw [e1]
    show deriv (fun s => (fun y => fderiv ℝ (uncurry u) y (1, 0)) (s, q)) p = _
    rw [partial1_eq (diff_apply_const hu _ _), fderiv_apply_const_eq hu]
  · rw [e1]
    show deriv (fun s => (fun y => fderiv ℝ (uncurry u) y (1, 0)) (p, s)) q = _
    rw [partial2_eq (diff_apply_const hu _ _), fderiv_apply_const_eq hu]
  · rw [e2]
    show deriv (fun s => (fun y => fderiv ℝ (uncurry u) y (0, 1)) (p, s)) q = _
    rw [partial2_eq (diff_apply_const hu _ _), fderiv_apply_const_eq hu]

lemma fderiv_comp_clm {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (L : ℝ × ℝ →L[ℝ] ℝ × ℝ)
    (z : ℝ × ℝ) : fderiv ℝ (W ∘ L) z = (fderiv ℝ W (L z)).comp L := by
  rw [fderiv_comp z ((hW.differentiable (by norm_num)) (L z)) L.differentiableAt,
    ContinuousLinearMap.fderiv]

lemma hess_comp_clm {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (L : ℝ × ℝ →L[ℝ] ℝ × ℝ)
    (z v e : ℝ × ℝ) :
    fderiv ℝ (fderiv ℝ (W ∘ L)) z v e = fderiv ℝ (fderiv ℝ W) (L z) (L v) (L e) := by
  rw [← fderiv_apply_const_eq (hW.comp L.contDiff)]
  have : (fun y => fderiv ℝ (W ∘ L) y e) = (fun y => fderiv ℝ W y (L e)) ∘ L := by
    funext y; simp [fderiv_comp_clm hW L y]
  rw [this, fderiv_comp z (diff_apply_const hW _ _) L.differentiableAt,
    ContinuousLinearMap.fderiv]
  simp only [ContinuousLinearMap.coe_comp, Function.comp_apply]
  rw [fderiv_apply_const_eq hW]

/-- The chain rule for the linear change `ξ = a₁ x + b₁ y`, `η = a₂ x + b₂ y`. -/
lemma key_change {A B C D E R a₁ b₁ a₂ b₂ : ℝ} {w : ℝ → ℝ → ℝ}
    (hw : ContDiff ℝ 2 (uncurry w)) (x y : ℝ) :
    secondOrderOp A B C D E R (fun x y => w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) x y =
      Q A B C a₁ b₁ * d1 (d1 w) (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)
      + Bmix A B C a₁ b₁ a₂ b₂ * d2 (d1 w) (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)
      + Q A B C a₂ b₂ * d2 (d2 w) (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)
      + (D * a₁ + E * b₁) * d1 w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)
      + (D * a₂ + E * b₂) * d2 w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)
      + R * w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y) := by
  set L : ℝ × ℝ →L[ℝ] ℝ × ℝ :=
    (a₁ • ContinuousLinearMap.fst ℝ ℝ ℝ + b₁ • ContinuousLinearMap.snd ℝ ℝ ℝ).prod
      (a₂ • ContinuousLinearMap.fst ℝ ℝ ℝ + b₂ • ContinuousLinearMap.snd ℝ ℝ ℝ) with hLdef
  have hL : ∀ z : ℝ × ℝ, L z = (a₁ * z.1 + b₁ * z.2, a₂ * z.1 + b₂ * z.2) := by
    intro z; simp [L]
  set u : ℝ → ℝ → ℝ := fun x y => w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y) with hudef
  have hU : uncurry u = uncurry w ∘ L := by
    funext z; rw [Function.comp_apply, hL]; rfl
  have huC : ContDiff ℝ 2 (uncurry u) := by rw [hU]; exact hw.comp L.contDiff
  obtain ⟨h1, h2, h3, h4, h5⟩ := derivs_eq huC x y
  obtain ⟨g1, g2, g3, g4, g5⟩ := derivs_eq hw (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)
  have hsym : IsSymmSndFDerivAt ℝ (uncurry w) (a₁ * x + b₁ * y, a₂ * x + b₂ * y) :=
    (hw.contDiffAt).isSymmSndFDerivAt (by simp)
  have hz : L (x, y) = (a₁ * x + b₁ * y, a₂ * x + b₂ * y) := by rw [hL]
  have he1 : L (1, 0) = a₁ • ((1 : ℝ), (0 : ℝ)) + a₂ • ((0 : ℝ), (1 : ℝ)) := by
    rw [hL]; ext <;> simp
  have he2 : L (0, 1) = b₁ • ((1 : ℝ), (0 : ℝ)) + b₂ • ((0 : ℝ), (1 : ℝ)) := by
    rw [hL]; ext <;> simp
  simp only [secondOrderOp]
  rw [h1, h2, h3, h4, h5, g1, g2, g3, g4, g5, hU]
  simp only [fderiv_comp_clm hw, hess_comp_clm hw, ContinuousLinearMap.coe_comp,
    Function.comp_apply]
  rw [hz, he1, he2]
  simp only [map_add, map_smul, add_apply, FunLike.coe_smul,
    Pi.smul_apply, smul_eq_mul]
  rw [hsym.eq ((1 : ℝ), (0 : ℝ)) ((0 : ℝ), (1 : ℝ))]
  simp only [hudef, Q, Bmix]
  ring

lemma package {A B C D E R α β γ a₁ b₁ a₂ b₂ k : ℝ} (hJ : jac a₁ b₁ a₂ b₂ ≠ 0) (hk : k ≠ 0)
    (h1 : Q A B C a₁ b₁ = k * α) (h2 : Bmix A B C a₁ b₁ a₂ b₂ = k * β)
    (h3 : Q A B C a₂ b₂ = k * γ) :
    ∃ a₁ b₁ a₂ b₂ k D' E' R' : ℝ, jac a₁ b₁ a₂ b₂ ≠ 0 ∧ k ≠ 0 ∧
        ∀ w : ℝ → ℝ → ℝ, ContDiff ℝ 2 (Function.uncurry w) → ∀ x y : ℝ,
          secondOrderOp A B C D E R (fun x y => w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) x y =
            k * secondOrderOp α β γ D' E' R' w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y) := by
  refine ⟨a₁, b₁, a₂, b₂, k, (D * a₁ + E * b₁) / k, (D * a₂ + E * b₂) / k, R / k, hJ, hk,
    fun w hw x y => ?_⟩
  rw [key_change hw, h1, h2, h3]
  simp only [secondOrderOp]
  field_simp

/-- Reduction to canonical form. Take a second-order equation
`A u_xx + B u_xy + C u_yy + D u_x + E u_y + R u = 0` with constant coefficients, `A, B, C` not
all zero. Then there are new coordinates `ξ = a₁ x + b₁ y`, `η = a₂ x + b₂ y` with Jacobian
`J ≠ 0`, a nonzero factor `k` and new lower-order coefficients such that, for every twice
continuously differentiable `w`, the function `u(x, y) = w(ξ, η)` has
left side = `k` × (the plain form in `w` at `(ξ, η)`), so `u` solves the equation exactly when `w`
solves the plain form:
* hyperbolic, `B^2 - 4AC > 0`: the wave equation `w_ξξ - w_ηη + … = 0`;
* parabolic, `B^2 - 4AC = 0`: `w_ηη + … = 0`, the heat equation when the `w_ξ` term survives;
* elliptic, `B^2 - 4AC < 0`: Laplace's equation `w_ξξ + w_ηη + … = 0`.
Here `…` stands for first- and zeroth-order terms. -/
theorem reduction_to_canonical_form (A B C D E R : ℝ) (h2 : ¬(A = 0 ∧ B = 0 ∧ C = 0)) :
    (0 < B ^ 2 - 4 * A * C →
      ∃ a₁ b₁ a₂ b₂ k D' E' R' : ℝ, jac a₁ b₁ a₂ b₂ ≠ 0 ∧ k ≠ 0 ∧
        ∀ w : ℝ → ℝ → ℝ, ContDiff ℝ 2 (Function.uncurry w) → ∀ x y : ℝ,
          secondOrderOp A B C D E R (fun x y => w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) x y =
            k * secondOrderOp 1 0 (-1) D' E' R' w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) ∧
    (B ^ 2 - 4 * A * C = 0 →
      ∃ a₁ b₁ a₂ b₂ k D' E' R' : ℝ, jac a₁ b₁ a₂ b₂ ≠ 0 ∧ k ≠ 0 ∧
        ∀ w : ℝ → ℝ → ℝ, ContDiff ℝ 2 (Function.uncurry w) → ∀ x y : ℝ,
          secondOrderOp A B C D E R (fun x y => w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) x y =
            k * secondOrderOp 0 0 1 D' E' R' w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) ∧
    (B ^ 2 - 4 * A * C < 0 →
      ∃ a₁ b₁ a₂ b₂ k D' E' R' : ℝ, jac a₁ b₁ a₂ b₂ ≠ 0 ∧ k ≠ 0 ∧
        ∀ w : ℝ → ℝ → ℝ, ContDiff ℝ 2 (Function.uncurry w) → ∀ x y : ℝ,
          secondOrderOp A B C D E R (fun x y => w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) x y =
            k * secondOrderOp 1 0 1 D' E' R' w (a₁ * x + b₁ * y) (a₂ * x + b₂ * y)) := by
  refine ⟨fun hΔ => ?_, fun hΔ => ?_, fun hΔ => ?_⟩
  · by_cases hA : A = 0
    · by_cases hC : C = 0
      · have hB : B ≠ 0 := fun hB => h2 ⟨hA, hB, hC⟩
        exact package (a₁ := 1) (b₁ := 1) (a₂ := 1) (b₂ := -1) (k := B) (α := 1) (β := 0)
          (γ := -1) (by unfold jac; norm_num) hB (by unfold Q; rw [hA, hC]; ring)
          (by unfold Bmix; rw [hA, hC]; ring) (by unfold Q; rw [hA, hC]; ring)
      · set s := Real.sqrt (B ^ 2 - 4 * A * C) with hsdef
        have hs : 0 < s := Real.sqrt_pos.2 hΔ
        have hs2 : s ^ 2 = B ^ 2 - 4 * A * C := Real.sq_sqrt hΔ.le
        have hsB : s ^ 2 = B ^ 2 := by rw [hs2, hA]; ring
        exact package (a₁ := 0) (b₁ := 1) (a₂ := 2 * C / s) (b₂ := -B / s) (k := C) (α := 1)
          (β := 0) (γ := -1) (by unfold jac; simp [hC, hs.ne']) hC (by unfold Q; ring)
          (by unfold Bmix; ring)
          (by unfold Q; rw [hA]; field_simp; linear_combination hsB)
    · set s := Real.sqrt (B ^ 2 - 4 * A * C) with hsdef
      have hs : 0 < s := Real.sqrt_pos.2 hΔ
      have hs2 : s ^ 2 = B ^ 2 - 4 * A * C := Real.sq_sqrt hΔ.le
      exact package (a₁ := 1) (b₁ := 0) (a₂ := -B / s) (b₂ := 2 * A / s) (k := A) (α := 1)
        (β := 0) (γ := -1) (by unfold jac; simp [hA, hs.ne']) hA (by unfold Q; ring)
        (by unfold Bmix; ring)
        (by unfold Q; field_simp; linear_combination hs2)
  · by_cases hA : A = 0
    · have hB : B = 0 := by
        have : B ^ 2 = 0 := by rw [hA] at hΔ; linarith
        exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 this
      have hC : C ≠ 0 := fun hC => h2 ⟨hA, hB, hC⟩
      exact package (a₁ := 1) (b₁ := 0) (a₂ := 0) (b₂ := 1) (k := C) (α := 0) (β := 0)
        (γ := 1) (by unfold jac; norm_num) hC (by unfold Q; rw [hA]; ring)
        (by unfold Bmix; rw [hA, hB]; ring) (by unfold Q; ring)
    · exact package (a₁ := -B) (b₁ := 2 * A) (a₂ := 1) (b₂ := 0) (k := A) (α := 0) (β := 0)
        (γ := 1) (by unfold jac; simp [hA]) hA (by unfold Q; linear_combination (-A) * hΔ)
        (by unfold Bmix; ring) (by unfold Q; ring)
  · have hA : A ≠ 0 := by
      intro hA; rw [hA] at hΔ; nlinarith [sq_nonneg B]
    set s := Real.sqrt (-(B ^ 2 - 4 * A * C)) with hsdef
    have hs : 0 < s := Real.sqrt_pos.2 (by linarith)
    have hs2 : s ^ 2 = -(B ^ 2 - 4 * A * C) := Real.sq_sqrt (by linarith)
    exact package (a₁ := 1) (b₁ := 0) (a₂ := -B / s) (b₂ := 2 * A / s) (k := A) (α := 1)
      (β := 0) (γ := 1) (by unfold jac; simp [hA, hs.ne']) hA (by unfold Q; ring)
      (by unfold Bmix; ring)
      (by unfold Q; field_simp; linear_combination (-1) * hs2)

/-- The recipe from the characteristic slopes, for `A ≠ 0`. The new coefficients of
`ξ = a₁ x + b₁ y`, `η = a₂ x + b₂ y` are `A' = Q(a₁, b₁)`, `B' = Bmix`, `C' = Q(a₂, b₂)`.
* Hyperbolic: two different real roots `λ₁ ≠ λ₂` of `A λ^2 - B λ + C = 0`; then
  `ξ = y - λ₁ x`, `η = y - λ₂ x` have `J ≠ 0`, `A' = C' = 0` and `B' ≠ 0`, leaving `w_ξη + … = 0`.
* Parabolic: `B^2 - 4AC = 0` and `λ` the (double) root; then `ξ = y - λ x`, `η = x` have
  `J ≠ 0`, `A' = B' = 0` and `C' = A`, leaving `w_ηη + … = 0`.
* Elliptic: complex roots `α ± iβ` with `β ≠ 0`; then `ξ = y - α x`, `η = β x` have `J ≠ 0`,
  `B' = 0` and `A' = C' ≠ 0`, leaving `w_ξξ + w_ηη + … = 0`. -/
theorem characteristic_coordinates_recipe (A B C : ℝ) (hA : A ≠ 0) :
    (∀ l₁ l₂ : ℝ, l₁ ≠ l₂ → A * l₁ ^ 2 - B * l₁ + C = 0 → A * l₂ ^ 2 - B * l₂ + C = 0 →
      jac (-l₁) 1 (-l₂) 1 ≠ 0 ∧ Q A B C (-l₁) 1 = 0 ∧ Q A B C (-l₂) 1 = 0 ∧
        Bmix A B C (-l₁) 1 (-l₂) 1 ≠ 0) ∧
    (B ^ 2 - 4 * A * C = 0 → ∀ l : ℝ, A * l ^ 2 - B * l + C = 0 →
      jac (-l) 1 1 0 ≠ 0 ∧ Q A B C (-l) 1 = 0 ∧ Bmix A B C (-l) 1 1 0 = 0 ∧ Q A B C 1 0 = A) ∧
    (∀ α β : ℝ, β ≠ 0 →
      (A : ℂ) * (α + β * I) ^ 2 - B * (α + β * I) + C = 0 →
      jac (-α) 1 β 0 ≠ 0 ∧ Bmix A B C (-α) 1 β 0 = 0 ∧ Q A B C (-α) 1 = Q A B C β 0 ∧
        Q A B C (-α) 1 ≠ 0) := by
  refine ⟨fun l₁ l₂ hne h1 h2 => ?_, fun hΔ l hl => ?_, fun α β hβ h => ?_⟩
  · have hsub : l₁ - l₂ ≠ 0 := sub_ne_zero.2 hne
    have hB : B = A * (l₁ + l₂) := by
      apply mul_left_cancel₀ hsub; linear_combination h2 - h1
    have hC : C = A * l₁ * l₂ := by linear_combination h1 + l₁ * hB
    refine ⟨?_, ?_, ?_, ?_⟩
    · unfold jac; intro h; apply hne; linarith
    · unfold Q; linear_combination h1
    · unfold Q; linear_combination h2
    · unfold Bmix
      have e : 2 * A * -l₁ * -l₂ + B * (-l₁ * 1 + 1 * -l₂) + 2 * C * 1 * 1 =
          -A * (l₁ - l₂) ^ 2 := by rw [hB, hC]; ring
      rw [e]
      exact mul_ne_zero (neg_ne_zero.2 hA) (pow_ne_zero 2 hsub)
  · have hB : B = 2 * A * l := by
      have h0 : (2 * A * l - B) ^ 2 = 0 := by linear_combination (4 * A) * hl + hΔ
      have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h0
      linarith
    exact ⟨by unfold jac; norm_num, by unfold Q; linear_combination hl,
      by unfold Bmix; rw [hB]; ring, by unfold Q; ring⟩
  · have hre := congrArg Complex.re h
    have him := congrArg Complex.im h
    simp [sq] at hre him
    have hB : B = 2 * A * α := by
      apply mul_left_cancel₀ hβ; linear_combination (-1) * him
    have hq : Q A B C (-α) 1 = A * β ^ 2 := by unfold Q; linear_combination hre
    refine ⟨by unfold jac; simpa using hβ, by unfold Bmix; rw [hB]; ring,
      by rw [hq]; unfold Q; ring, ?_⟩
    rw [hq]; exact mul_ne_zero hA (pow_ne_zero 2 hβ)

/-- The moving strip's solutions. With wave speed `c > 0` on the steel and line speed `V`,
a twice continuously differentiable displacement `u(t, x)` solves
`u_tt + 2V u_xt - (c^2 - V^2) u_xx = 0` everywhere exactly when it is
`F(x - (V + c) t) + G(x - (V - c) t)` for two twice continuously differentiable shapes `F`, `G`:
a part running downstream at `V + c` and a part running at `V - c`
(for the card's strip, `x - 100 t` and `x + 60 t`). -/
theorem moving_strip_general_solution (c V : ℝ) (hc : 0 < c) (u : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (Function.uncurry u)) :
    (∀ t x : ℝ, secondOrderOp 1 (2 * V) (-(c ^ 2 - V ^ 2)) 0 0 0 u t x = 0) ↔
      ∃ F G : ℝ → ℝ, ContDiff ℝ 2 F ∧ ContDiff ℝ 2 G ∧
        ∀ t x : ℝ, u t x = F (x - (V + c) * t) + G (x - (V - c) * t) := by
  have hc0 : c ≠ 0 := hc.ne'
  have hQ1 : Q 1 (2 * V) (-(c ^ 2 - V ^ 2)) (-(V + c)) 1 = 0 := by unfold Q; ring
  have hQ2 : Q 1 (2 * V) (-(c ^ 2 - V ^ 2)) (-(V - c)) 1 = 0 := by unfold Q; ring
  have hBm : Bmix 1 (2 * V) (-(c ^ 2 - V ^ 2)) (-(V + c)) 1 (-(V - c)) 1 = -4 * c ^ 2 := by
    unfold Bmix; ring
  constructor
  · intro hPDE
    set w : ℝ → ℝ → ℝ := fun ξ η => u ((η - ξ) / (2 * c)) (ξ + (V + c) * ((η - ξ) / (2 * c)))
      with hwdef
    have hwC : ContDiff ℝ 2 (uncurry w) := by
      have : uncurry w = uncurry u ∘ (fun z : ℝ × ℝ =>
          ((z.2 - z.1) / (2 * c), z.1 + (V + c) * ((z.2 - z.1) / (2 * c)))) := by
        funext z; rfl
      rw [this]; exact hu.comp (by fun_prop)
    have hu_eq : u = fun t x => w (-(V + c) * t + 1 * x) (-(V - c) * t + 1 * x) := by
      funext t x; simp only [hwdef]; congr 1 <;> field_simp <;> ring
    have hmix : ∀ ξ η, d2 (d1 w) ξ η = 0 := by
      intro ξ η
      obtain ⟨t, x, hξ, hη⟩ : ∃ t x : ℝ, -(V + c) * t + 1 * x = ξ ∧ -(V - c) * t + 1 * x = η :=
        ⟨(η - ξ) / (2 * c), ξ + (V + c) * ((η - ξ) / (2 * c)), by ring, by field_simp; ring⟩
      have h := hPDE t x
      rw [hu_eq, key_change hwC, hξ, hη, hQ1, hQ2, hBm] at h
      have h' : (-4 * c ^ 2) * d2 (d1 w) ξ η = 0 := by linear_combination h
      exact (mul_eq_zero.1 h').resolve_left (mul_ne_zero (by norm_num) (pow_ne_zero 2 hc0))
    have hWd : Differentiable ℝ (uncurry w) := hwC.differentiable (by norm_num)
    have hd1 : ∀ ξ, Differentiable ℝ (fun s => d1 w ξ s) := by
      intro ξ
      have e : (fun s => d1 w ξ s) =
          (fun y => fderiv ℝ (uncurry w) y (1, 0)) ∘ (fun s : ℝ => (ξ, s)) := by
        funext s; exact (derivs_eq hwC ξ s).1
      rw [e]
      exact (diff_apply_const hwC _).comp (differentiable_const ξ |>.prodMk differentiable_id)
    have hconst : ∀ ξ η, d1 w ξ η = d1 w ξ 0 := fun ξ η =>
      is_const_of_deriv_eq_zero (hd1 ξ) (fun s => hmix ξ s) η 0
    have hdiff : ∀ η', Differentiable ℝ (fun s => w s η') := fun η' =>
      hWd.comp (differentiable_id.prodMk (differentiable_const η'))
    have hwη : ∀ ξ η, w ξ η - w ξ 0 = w 0 η - w 0 0 := by
      intro ξ η
      refine is_const_of_deriv_eq_zero ((hdiff η).sub (hdiff 0)) (fun s => ?_) ξ 0
      rw [deriv_sub (hdiff η s) (hdiff 0 s)]
      exact sub_eq_zero.2 (hconst s η)
    refine ⟨fun ξ => w ξ 0, fun η => w 0 η - w 0 0, ?_, ?_, fun t x => ?_⟩
    · exact hwC.comp (contDiff_id.prodMk contDiff_const)
    · exact (hwC.comp (contDiff_const.prodMk contDiff_id)).sub contDiff_const
    · have h := congrFun (congrFun hu_eq t) x
      have e1 : -(V + c) * t + 1 * x = x - (V + c) * t := by ring
      have e2 : -(V - c) * t + 1 * x = x - (V - c) * t := by ring
      simp only [e1, e2] at h
      rw [h]
      linarith [hwη (x - (V + c) * t) (x - (V - c) * t)]
  · rintro ⟨F, G, hF, hG, huFG⟩ t x
    set w : ℝ → ℝ → ℝ := fun ξ η => F ξ + G η with hwdef
    have hwC : ContDiff ℝ 2 (uncurry w) := by
      show ContDiff ℝ 2 (fun z : ℝ × ℝ => F z.1 + G z.2)
      exact (hF.comp contDiff_fst).add (hG.comp contDiff_snd)
    have hu_eq : u = fun t x => w (-(V + c) * t + 1 * x) (-(V - c) * t + 1 * x) := by
      funext t x; rw [huFG]; simp only [hwdef]; congr 1 <;> congr 1 <;> ring
    have hd1w : ∀ ξ s, d1 w ξ s = deriv F ξ := by
      intro ξ s; simp only [d1, hwdef]; exact deriv_add_const (G s)
    have hmix : d2 (d1 w) = fun _ _ => 0 := by
      funext ξ η; simp only [d2, hd1w]; simp
    rw [hu_eq, key_change hwC, hQ1, hQ2, hBm, hmix]
    ring

/-! The card's whole-number worked examples, exactly. -/

-- Strip, c = 80 m/s, V = 20 m/s: A, B, C = 1, 40, -6000 and B^2 - 4AC = 25600.
example : (2 * 20 : ℤ) = 40 ∧ -((80 : ℤ) ^ 2 - 20 ^ 2) = -6000 := by norm_num
example : (40 : ℤ) ^ 2 - 4 * 1 * (-6000) = 25600 := by norm_num
-- The characteristic speeds 100 and -60 m/s are the roots of λ^2 - 40 λ - 6000 = 0.
example : (100 : ℤ) ^ 2 - 40 * 100 - 6000 = 0 ∧ (-60 : ℤ) ^ 2 - 40 * (-60) - 6000 = 0 := by norm_num
-- ξ = x - 100 t, η = x + 60 t: A', B', C' = 0, -25600, 0 and J = -160.
example : Q 1 40 (-6000) (-100) 1 = 0 ∧ Bmix 1 40 (-6000) (-100) 1 60 1 = -25600 ∧
    Q 1 40 (-6000) 60 1 = 0 ∧ jac (-100) 1 60 1 = -160 := by norm_num [Q, Bmix, jac]
-- The invariant: B'^2 - 4A'C' = 655360000 = J^2 (B^2 - 4AC) = 25600 × 25600.
example : (-25600 : ℤ) ^ 2 - 4 * 0 * 0 = 655360000 ∧ (-160 : ℤ) ^ 2 * 25600 = 655360000 ∧
    (25600 : ℤ) * 25600 = 655360000 := by norm_num
-- The strip's frame s = x - 20 t, r = 80 t: A', B', C' = -6400, 0, 6400, so v_rr = v_ss.
example : Q 1 40 (-6000) (-20) 1 = -6400 ∧ Bmix 1 40 (-6000) (-20) 1 80 0 = 0 ∧
    Q 1 40 (-6000) 80 0 = 6400 := by norm_num [Q, Bmix]
-- Round trip 2/100 + 2/60 = 4/75 s, and the tone (6400 - 400)/(2 × 2 × 80) = 75/4 = 18.75 Hz,
-- the inverse of the round trip; the still strip's tone is 80/(2 × 2) = 20 Hz.
example : (2 : ℚ) / 100 + 2 / 60 = 4 / 75 ∧ ((6400 : ℚ) - 400) / (2 * 2 * 80) = 75 / 4 ∧
    1 / ((2 : ℚ) / 100 + 2 / 60) = 75 / 4 ∧ (80 : ℚ) / (2 * 2) = 20 := by norm_num
-- Tone at line speed 0, 40, 80 m/s: 20, 15, 0 Hz.
example : ((80 : ℚ) ^ 2 - 0 ^ 2) / (2 * 2 * 80) = 20 ∧ ((80 : ℚ) ^ 2 - 40 ^ 2) / (2 * 2 * 80) = 15 ∧
    ((80 : ℚ) ^ 2 - 80 ^ 2) / (2 * 2 * 80) = 0 := by norm_num
-- Parabolic example u_xx + 2u_xy + u_yy - u_y = 0: B^2 - 4AC = 0, double root 1;
-- ξ = y - x, η = x give A', B', C' = 0, 0, 1, D', E' = -1, 0 and J = -1: w_ηη = w_ξ.
example : (2 : ℤ) ^ 2 - 4 * 1 * 1 = 0 ∧ (1 : ℤ) * 1 ^ 2 - 2 * 1 + 1 = 0 := by norm_num
example : Q 1 2 1 (-1) 1 = 0 ∧ Bmix 1 2 1 (-1) 1 1 0 = 0 ∧ Q 1 2 1 1 0 = 1 ∧
    (0 : ℝ) * (-1) + (-1) * 1 = -1 ∧ (0 : ℝ) * 1 + (-1) * 0 = 0 ∧ jac (-1) 1 1 0 = -1 := by
  norm_num [Q, Bmix, jac]
-- Elliptic example u_xx + 2u_xy + 5u_yy = 0: B^2 - 4AC = -16, roots 1 ± 2i;
-- ξ = y - x, η = 2x give A', B', C' = 4, 0, 4.
example : (2 : ℤ) ^ 2 - 4 * 1 * 5 = -16 := by norm_num
example : (1 : ℂ) * (1 + 2 * I) ^ 2 - 2 * (1 + 2 * I) + 5 = 0 := by
  ring_nf; simp [Complex.ext_iff]
example : Q 1 2 5 (-1) 1 = 4 ∧ Bmix 1 2 5 (-1) 1 2 0 = 0 ∧ Q 1 2 5 2 0 = 4 := by
  norm_num [Q, Bmix]
-- What breaks: still-strip speeds ±80 m/s give A', C' = -2800, 3600; slipped signs give
-- 8000, -4800; the elliptic case with η = x gives 4, 0, 1; the parabolic case with
-- η = 2(y - x) gives J = 0.
example : Q 1 40 (-6000) (-80) 1 = -2800 ∧ Q 1 40 (-6000) 80 1 = 3600 := by norm_num [Q]
example : Q 1 40 (-6000) 100 1 = 8000 ∧ Q 1 40 (-6000) (-60) 1 = -4800 := by norm_num [Q]
example : Q 1 2 5 (-1) 1 = 4 ∧ Bmix 1 2 5 (-1) 1 1 0 = 0 ∧ Q 1 2 5 1 0 = 1 := by norm_num [Q, Bmix]
example : jac (-1) 1 (-2) 2 = 0 := by norm_num [jac]
-- Tricomi y u_xx + u_yy: B^2 - 4AC = -4y is -4 at y = 1 and 4 at y = -1.
example : (0 : ℤ) ^ 2 - 4 * 1 * 1 = -4 ∧ (0 : ℤ) ^ 2 - 4 * (-1) * 1 = 4 := by norm_num
-- Try changing: V = 40 m/s gives speeds 120 and -40 m/s and 15 Hz; L = 1 m gives a round trip
-- of 2/75 s and 75/2 = 37.5 Hz; C = 10 in the elliptic example gives -36, β = 3, and 9, 0, 9.
example : (120 : ℤ) ^ 2 - 80 * 120 - 4800 = 0 ∧ (-40 : ℤ) ^ 2 - 80 * (-40) - 4800 = 0 := by norm_num
example : (1 : ℚ) / 100 + 1 / 60 = 2 / 75 ∧ 1 / ((1 : ℚ) / 100 + 1 / 60) = 75 / 2 := by norm_num
example : (2 : ℤ) ^ 2 - 4 * 1 * 10 = -36 ∧ Q 1 2 10 (-1) 1 = 9 ∧ Bmix 1 2 10 (-1) 1 3 0 = 0 ∧
    Q 1 2 10 3 0 = 9 := by norm_num [Q, Bmix]

#print axioms partial1_eq
#print axioms partial2_eq
#print axioms diff_fderiv_of_C2
#print axioms diff_apply_const
#print axioms fderiv_apply_const_eq
#print axioms derivs_eq
#print axioms fderiv_comp_clm
#print axioms hess_comp_clm
#print axioms key_change
#print axioms package
#print axioms reduction_to_canonical_form
#print axioms characteristic_coordinates_recipe
#print axioms moving_strip_general_solution

end ReductionToCanonicalForm
