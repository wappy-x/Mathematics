-- Lagrangian mechanics: the Euler-Lagrange expression keeps its form under any smooth change of coordinate, a coordinate missing from the Lagrangian has a conserved momentum, and the swing's Lagrangian gives the pendulum equation.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring

/-! ### How the card's objects are written here

A Lagrangian with one coordinate is a real function `L x v` of the position `x` and the speed `v`.
Its two slopes are partial derivatives, written with `deriv` of one input while the other is held:
* slope in the speed: `deriv (fun v => L x v) v` (this is the momentum `p`);
* slope in the position: `deriv (fun y => L y v) x`.

A motion is a path `q : ℝ → ℝ` in time; its speed at time `t` is `deriv q t`.
The Euler-Lagrange equation `d/dt (∂L/∂q') = ∂L/∂q` along the path says that the momentum
`t ↦ ∂L/∂v (q t, q' t)` has derivative `∂L/∂x (q t, q' t)` at every time `t`.

With several coordinates, positions and speeds are lists `Fin n → ℝ`; the slope in coordinate
`i` changes entry `i` alone, through `Function.update`. -/

/-- The card's main claim, in the form its detailed proof gives: the Euler-Lagrange equations
keep their form in any convenient coordinate. Let `x = X(q)` be a smooth change of coordinate and
`L̃(q, q') = L(X(q), X'(q) q')` the same Lagrangian written in `q`. Along any smooth path `q(t)`,
with `x(t) = X(q(t))`, the Euler-Lagrange expression in `q` equals the one in `x` times `dx/dq`:
`d/dt L̃_{q'} - L̃_q = (d/dt L_{x'} - L_x) · dx/dq`. So one side vanishes exactly when the other
does, wherever `dx/dq ≠ 0`. -/
theorem euler_lagrange_keeps_form_under_change_of_coordinate
    (L : ℝ → ℝ → ℝ) (X q : ℝ → ℝ)
    (hL : ContDiff ℝ 2 (Function.uncurry L)) (hX : ContDiff ℝ 2 X) (hq : ContDiff ℝ 2 q)
    (t : ℝ) :
    deriv (fun s => deriv (fun w => L (X (q s)) (deriv X (q s) * w)) (deriv q s)) t
        - deriv (fun r => L (X r) (deriv X r * deriv q t)) (q t)
      = (deriv (fun s => deriv (fun v => L (X (q s)) v) (deriv (fun u => X (q u)) s)) t
          - deriv (fun y => L y (deriv (fun u => X (q u)) t)) (X (q t))) * deriv X (q t) := by
  set F := Function.uncurry L with hFdef
  have hFd : Differentiable ℝ F := hL.differentiable (by norm_num)
  have hF1 : ContDiff ℝ 1 (fderiv ℝ F) := hL.fderiv_right (by norm_num)
  set Lx : ℝ × ℝ → ℝ := fun p => fderiv ℝ F p (1, 0) with hLx
  set Lv : ℝ × ℝ → ℝ := fun p => fderiv ℝ F p (0, 1) with hLv
  have hLvd : Differentiable ℝ Lv :=
    (hF1.clm_apply contDiff_const).differentiable (by norm_num)
  -- chain rule for L along a curve
  have chain : ∀ (α β : ℝ → ℝ) (α' β' r : ℝ), HasDerivAt α α' r → HasDerivAt β β' r →
      HasDerivAt (fun r => L (α r) (β r)) (Lx (α r, β r) * α' + Lv (α r, β r) * β') r := by
    intro α β α' β' r ha hb
    have h := (hFd (α r, β r)).hasFDerivAt.comp_hasDerivAt r (ha.prodMk hb)
    have e : fderiv ℝ F (α r, β r) (α', β') = Lx (α r, β r) * α' + Lv (α r, β r) * β' := by
      have : ((α', β') : ℝ × ℝ) = α' • ((1 : ℝ), (0 : ℝ)) + β' • ((0 : ℝ), (1 : ℝ)) := by
        ext <;> simp
      rw [this, map_add, map_smul, map_smul]
      simp only [hLx, hLv, smul_eq_mul]; ring
    rw [e] at h
    exact h
  have hXd : Differentiable ℝ X := hX.differentiable (by norm_num)
  have hqd : Differentiable ℝ q := hq.differentiable (by norm_num)
  have hX' : Differentiable ℝ (deriv X) :=
    ((contDiff_succ_iff_deriv (n := 1)).1 hX).2.2.differentiable (by norm_num)
  have hq' : Differentiable ℝ (deriv q) :=
    ((contDiff_succ_iff_deriv (n := 1)).1 hq).2.2.differentiable (by norm_num)
  -- velocity of x
  have hxv : ∀ s, deriv (fun u => X (q u)) s = deriv X (q s) * deriv q s := by
    intro s
    exact ((hXd (q s)).hasDerivAt.comp s (hqd s).hasDerivAt).deriv
  -- inner derivatives
  have h1 : ∀ s, deriv (fun w => L (X (q s)) (deriv X (q s) * w)) (deriv q s)
      = Lv (X (q s), deriv X (q s) * deriv q s) * deriv X (q s) := by
    intro s
    have := chain (fun _ => X (q s)) (fun w => deriv X (q s) * w) 0 (deriv X (q s)) (deriv q s)
      (hasDerivAt_const _ _) ((hasDerivAt_id _).const_mul _ |>.congr_deriv (by simp))
    simpa using this.deriv
  have h2 : deriv (fun r => L (X r) (deriv X r * deriv q t)) (q t)
      = Lx (X (q t), deriv X (q t) * deriv q t) * deriv X (q t)
        + Lv (X (q t), deriv X (q t) * deriv q t) * (deriv (deriv X) (q t) * deriv q t) := by
    have := chain X (fun r => deriv X r * deriv q t) (deriv X (q t))
      (deriv (deriv X) (q t) * deriv q t) (q t) (hXd _).hasDerivAt
      ((hX' _).hasDerivAt.mul_const _)
    exact this.deriv
  have h3 : ∀ s, deriv (fun v => L (X (q s)) v) (deriv X (q s) * deriv q s)
      = Lv (X (q s), deriv X (q s) * deriv q s) := by
    intro s
    have := chain (fun _ => X (q s)) (fun v => v) 0 1 (deriv X (q s) * deriv q s)
      (hasDerivAt_const _ _) (hasDerivAt_id _)
    simpa using this.deriv
  have h4 : deriv (fun y => L y (deriv X (q t) * deriv q t)) (X (q t))
      = Lx (X (q t), deriv X (q t) * deriv q t) := by
    have := chain (fun y => y) (fun _ => deriv X (q t) * deriv q t) 1 0 (X (q t))
      (hasDerivAt_id _) (hasDerivAt_const _ _)
    simpa using this.deriv
  set P : ℝ → ℝ := fun s => Lv (X (q s), deriv X (q s) * deriv q s) with hP
  have hPd : DifferentiableAt ℝ P t := by
    have hc : DifferentiableAt ℝ (fun s => (X (q s), deriv X (q s) * deriv q s)) t :=
      ((hXd.comp hqd) t).prodMk (((hX'.comp hqd) t).mul (hq' t))
    exact (hLvd _).comp t hc
  have hlhs : (fun s => deriv (fun w => L (X (q s)) (deriv X (q s) * w)) (deriv q s))
      = fun s => P s * deriv X (q s) := funext h1
  have hrhs : (fun s => deriv (fun v => L (X (q s)) v) (deriv (fun u => X (q u)) s)) = P := by
    funext s; rw [hxv s, h3 s]
  have hD : deriv (fun s => P s * deriv X (q s)) t
      = deriv P t * deriv X (q t) + P t * (deriv (deriv X) (q t) * deriv q t) := by
    have := hPd.hasDerivAt.mul ((hX' (q t)).hasDerivAt.comp t (hqd t).hasDerivAt)
    exact this.deriv
  rw [hlhs, hrhs, hD, h2, hxv t, h4]
  simp only [hP]
  ring

/-- A coordinate missing from the Lagrangian gives a conserved momentum (Step 4). Let `L` be a
Lagrangian in `n` coordinates that does not depend on coordinate `i` (it is cyclic). If a motion
`q` obeys the Euler-Lagrange equation in every coordinate, then the momentum of coordinate `i`,
`p = ∂L/∂q_i'`, has the same value at every time. -/
theorem cyclic_coordinate_momentum_conserved {n : ℕ}
    (L : (Fin n → ℝ) → (Fin n → ℝ) → ℝ) (i : Fin n)
    (h_cyclic : ∀ x v c, L (Function.update x i c) v = L x v)
    (q : ℝ → Fin n → ℝ)
    (h_EL : ∀ j t,
      HasDerivAt (fun s => deriv (fun c => L (q s) (Function.update (deriv q s) j c)) (deriv q s j))
        (deriv (fun c => L (Function.update (q t) j c) (deriv q t)) (q t j)) t) :
    ∀ s t,
      deriv (fun c => L (q s) (Function.update (deriv q s) i c)) (deriv q s i)
        = deriv (fun c => L (q t) (Function.update (deriv q t) i c)) (deriv q t i) := by
  intro s t
  have h0 : ∀ t, deriv (fun c => L (Function.update (q t) i c) (deriv q t)) (q t i) = 0 := by
    intro t
    simp only [h_cyclic]
    exact deriv_const _ _
  apply is_const_of_deriv_eq_zero (f := fun s =>
    deriv (fun c => L (q s) (Function.update (deriv q s) i c)) (deriv q s i))
  · intro u; exact (h_EL i u).differentiableAt
  · intro u; rw [(h_EL i u).deriv, h0]

/-- The swing (Step 1): with mass `m > 0`, rod length `l > 0` and gravity `g`, the Lagrangian
`L = ½ m l² θ'² + m g l cos θ` fed through the Euler-Lagrange equation gives the pendulum
equation `θ'' + (g/l) sin θ = 0`. The mass cancels and the rods' pull never appears. -/
theorem swing_lagrangian_gives_pendulum_equation (m l g : ℝ) (hm : 0 < m) (hl : 0 < l)
    (θ : ℝ → ℝ)
    (h_EL : ∀ t,
      HasDerivAt
        (fun s => deriv (fun w => 1 / 2 * m * l ^ 2 * w ^ 2 + m * g * l * Real.cos (θ s)) (deriv θ s))
        (deriv (fun x => 1 / 2 * m * l ^ 2 * (deriv θ t) ^ 2 + m * g * l * Real.cos x) (θ t)) t) :
    ∀ t, deriv (deriv θ) t + g / l * Real.sin (θ t) = 0 := by
  intro t
  have hk : ∀ s, deriv (fun w => 1 / 2 * m * l ^ 2 * w ^ 2 + m * g * l * Real.cos (θ s)) (deriv θ s)
      = m * l ^ 2 * deriv θ s := by
    intro s
    have : HasDerivAt (fun w => 1 / 2 * m * l ^ 2 * w ^ 2 + m * g * l * Real.cos (θ s))
        (1 / 2 * m * l ^ 2 * (2 * deriv θ s ^ 1 * 1) + 0) (deriv θ s) :=
      (((hasDerivAt_id _).pow 2).const_mul _).add (hasDerivAt_const _ _)
    rw [this.deriv]; ring
  have hp : deriv (fun x => 1 / 2 * m * l ^ 2 * (deriv θ t) ^ 2 + m * g * l * Real.cos x) (θ t)
      = -(m * g * l * Real.sin (θ t)) := by
    have : HasDerivAt (fun x => 1 / 2 * m * l ^ 2 * (deriv θ t) ^ 2 + m * g * l * Real.cos x)
        (0 + m * g * l * -Real.sin (θ t)) (θ t) :=
      (hasDerivAt_const _ _).add ((Real.hasDerivAt_cos _).const_mul _)
    rw [this.deriv]; ring
  have h := h_EL t
  rw [hp] at h
  have hfun : (fun s => deriv (fun w => 1 / 2 * m * l ^ 2 * w ^ 2 + m * g * l * Real.cos (θ s))
      (deriv θ s)) = fun s => m * l ^ 2 * deriv θ s := funext hk
  rw [hfun] at h
  have hc : m * l ^ 2 ≠ 0 := by positivity
  have h2 : HasDerivAt (deriv θ) ((m * l ^ 2)⁻¹ * -(m * g * l * Real.sin (θ t))) t := by
    have := h.const_mul (m * l ^ 2)⁻¹
    have e : (fun y => (m * l ^ 2)⁻¹ * (m * l ^ 2 * deriv θ y)) = deriv θ := by
      funext y; rw [← mul_assoc, inv_mul_cancel₀ hc, one_mul]
    rw [e] at this
    exact this
  rw [h2.deriv]
  field_simp
  ring

/-- Worked numbers: the swing's constant `m l² = 30 × 2² = 120` kg m². -/
example : (30 : ℕ) * 2 ^ 2 = 120 := by norm_num

/-- Worked numbers: at release from 30 degrees (`π/6`), the pendulum equation gives the angular
acceleration `-(g/l) sin θ = -(9.81 / 2) × 1/2 = -2.4525` rad/s², written as the exact fraction
`-981/400`. -/
example : -((981 / 100 : ℝ) / 2) * Real.sin (Real.pi / 6) = -981 / 400 := by
  rw [Real.sin_pi_div_six]; norm_num

#print axioms euler_lagrange_keeps_form_under_change_of_coordinate
#print axioms cyclic_coordinate_momentum_conserved
#print axioms swing_lagrangian_gives_pendulum_equation
