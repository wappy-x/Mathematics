-- Lax pairs and inverse scattering: KdV holds exactly when the Schrödinger operator L = −∂² + u changes by the commutator [B, L], such a flow keeps every eigenvalue of a self-adjoint L fixed, and each one-soliton −2κ² sech²(κ(x − 4κ²t − x₀)) solves KdV.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.InnerProductSpace.Symmetric
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Tactic

open scoped ContDiff

/-- The Schrödinger operator with potential `v`: `(L f)(x) = −f''(x) + v(x) f(x)`. -/
noncomputable def schrL (v f : ℝ → ℝ) : ℝ → ℝ :=
  fun x => -deriv (deriv f) x + v x * f x

/-- Lax's partner operator: `(B f)(x) = −4 f'''(x) + 6 v(x) f'(x) + 3 v'(x) f(x)`. -/
noncomputable def laxB (v f : ℝ → ℝ) : ℝ → ℝ :=
  fun x => -4 * deriv (deriv (deriv f)) x + 6 * v x * deriv f x + 3 * deriv v x * f x

lemma lax_smooth_deriv (g : ℝ → ℝ) (hg : ContDiff ℝ ∞ g) : ContDiff ℝ ∞ (deriv g) :=
  (contDiff_infty_iff_deriv.mp hg).2

#print axioms lax_smooth_deriv

lemma lax_deriv_add (a b : ℝ → ℝ) (ha : ContDiff ℝ ∞ a) (hb : ContDiff ℝ ∞ b) :
    deriv (fun x => a x + b x) = fun x => deriv a x + deriv b x := by
  funext x
  exact deriv_add (ha.differentiable (by simp) x) (hb.differentiable (by simp) x)

#print axioms lax_deriv_add

lemma lax_deriv_mul (a b : ℝ → ℝ) (ha : ContDiff ℝ ∞ a) (hb : ContDiff ℝ ∞ b) :
    deriv (fun x => a x * b x) = fun x => deriv a x * b x + a x * deriv b x := by
  funext x
  exact deriv_mul (ha.differentiable (by simp) x) (hb.differentiable (by simp) x)

#print axioms lax_deriv_mul

lemma lax_deriv_neg (a : ℝ → ℝ) : deriv (fun x => -a x) = fun x => -deriv a x := by
  funext x
  exact deriv.fun_neg

#print axioms lax_deriv_neg

lemma lax_commutator (v f : ℝ → ℝ) (hv : ContDiff ℝ ∞ v) (hf : ContDiff ℝ ∞ f) (x : ℝ) :
    laxB v (schrL v f) x - schrL v (laxB v f) x
      = (6 * v x * deriv v x - deriv (deriv (deriv v)) x) * f x := by
  obtain ⟨f1, e1⟩ : ∃ g, deriv f = g := ⟨_, rfl⟩
  have s1 : ContDiff ℝ ∞ f1 := e1 ▸ lax_smooth_deriv f hf
  obtain ⟨f2, e2⟩ : ∃ g, deriv f1 = g := ⟨_, rfl⟩
  have s2 : ContDiff ℝ ∞ f2 := e2 ▸ lax_smooth_deriv f1 s1
  obtain ⟨f3, e3⟩ : ∃ g, deriv f2 = g := ⟨_, rfl⟩
  have s3 : ContDiff ℝ ∞ f3 := e3 ▸ lax_smooth_deriv f2 s2
  obtain ⟨f4, e4⟩ : ∃ g, deriv f3 = g := ⟨_, rfl⟩
  have s4 : ContDiff ℝ ∞ f4 := e4 ▸ lax_smooth_deriv f3 s3
  obtain ⟨f5, e5⟩ : ∃ g, deriv f4 = g := ⟨_, rfl⟩
  obtain ⟨v1, d1⟩ : ∃ g, deriv v = g := ⟨_, rfl⟩
  have t1 : ContDiff ℝ ∞ v1 := d1 ▸ lax_smooth_deriv v hv
  obtain ⟨v2, d2⟩ : ∃ g, deriv v1 = g := ⟨_, rfl⟩
  have t2 : ContDiff ℝ ∞ v2 := d2 ▸ lax_smooth_deriv v1 t1
  obtain ⟨v3, d3⟩ : ∃ g, deriv v2 = g := ⟨_, rfl⟩
  have t3 : ContDiff ℝ ∞ v3 := d3 ▸ lax_smooth_deriv v2 t2
  unfold schrL laxB
  simp only [e1, e2, d1]
  simp (disch := fun_prop) only [lax_deriv_add, lax_deriv_mul, lax_deriv_neg,
    deriv_const_mul_field', e1, e2, e3, e4, e5, d1, d2, d3]
  ring

#print axioms lax_commutator


lemma sol_affine (G G' : ℝ → ℝ) (hG : ∀ z, HasDerivAt G (G' z) z) (C a b : ℝ) :
    deriv (fun y => C * G (a * y + b)) = fun y => C * a * G' (a * y + b) := by
  funext y
  have hθ : HasDerivAt (fun y => a * y + b) a y := by
    simpa using ((hasDerivAt_id y).const_mul a).add_const b
  have := ((hG _).comp y hθ).const_mul C
  exact this.deriv.trans (by ring)

#print axioms sol_affine

lemma sol_d0 (z : ℝ) : HasDerivAt (fun z => 1 / Real.cosh z ^ 2)
    (-2 * Real.sinh z / Real.cosh z ^ 3) z := by
  have hc : Real.cosh z ≠ 0 := (Real.cosh_pos z).ne'
  have := ((Real.hasDerivAt_cosh z).fun_pow 2).fun_inv (pow_ne_zero 2 hc)
  convert this using 1
  · funext w; simp [one_div]
  · field_simp; ring

#print axioms sol_d0

lemma sol_d1 (z : ℝ) : HasDerivAt (fun z => -2 * Real.sinh z / Real.cosh z ^ 3)
    (-2 / Real.cosh z ^ 2 + 6 * Real.sinh z ^ 2 / Real.cosh z ^ 4) z := by
  have hc : Real.cosh z ≠ 0 := (Real.cosh_pos z).ne'
  have := ((Real.hasDerivAt_sinh z).const_mul (-2)).div ((Real.hasDerivAt_cosh z).fun_pow 3)
    (pow_ne_zero 3 hc)
  convert this using 1
  field_simp; ring

#print axioms sol_d1

lemma sol_d2 (z : ℝ) : HasDerivAt
    (fun z => -2 / Real.cosh z ^ 2 + 6 * Real.sinh z ^ 2 / Real.cosh z ^ 4)
    (16 * Real.sinh z / Real.cosh z ^ 3 - 24 * Real.sinh z ^ 3 / Real.cosh z ^ 5) z := by
  have hc : Real.cosh z ≠ 0 := (Real.cosh_pos z).ne'
  have h1 := ((hasDerivAt_const z (-2 : ℝ)).div ((Real.hasDerivAt_cosh z).fun_pow 2)
    (pow_ne_zero 2 hc))
  have h2 := (((Real.hasDerivAt_sinh z).fun_pow 2).const_mul 6).div ((Real.hasDerivAt_cosh z).fun_pow 4)
    (pow_ne_zero 4 hc)
  convert h1.add h2 using 1
  field_simp; ring

#print axioms sol_d2


/-- **KdV is a Lax equation.** Let the wave `u t x` be smooth in `x` at every time `t`. At a
time `t`, KdV `u_t − 6 u u_x + u_xxx = 0` holds at every point `x` exactly when the Schrödinger
operator `L = −∂² + u` changes in time by its commutator with `B = −4∂³ + 6u∂ + 3u_x`:
`L_t f = B (L f) − L (B f)` for every smooth test function `f`. -/
theorem kdv_iff_lax_equation (u : ℝ → ℝ → ℝ) (hu : ∀ t, ContDiff ℝ ∞ (u t)) (t : ℝ) :
    (∀ x, deriv (fun s => u s x) t - 6 * u t x * deriv (u t) x
        + deriv (deriv (deriv (u t))) x = 0) ↔
    (∀ f : ℝ → ℝ, ContDiff ℝ ∞ f → ∀ x,
        deriv (fun s => schrL (u s) f x) t
          = laxB (u t) (schrL (u t) f) x - schrL (u t) (laxB (u t) f) x) := by
  have time : ∀ (f : ℝ → ℝ) (x : ℝ),
      deriv (fun s => schrL (u s) f x) t = deriv (fun s => u s x) t * f x := by
    intro f x
    simp only [schrL]
    rw [deriv_const_add, deriv_mul_const_field]
  constructor
  · intro h f hf x
    rw [time, lax_commutator (u t) f (hu t) hf x]
    have := h x
    congr 1
    linarith
  · intro h x
    have := h (fun _ => 1) contDiff_const x
    rw [time, lax_commutator (u t) _ (hu t) contDiff_const x] at this
    simp only [mul_one] at this
    linarith

/-- **A Lax flow keeps the eigenvalues fixed.** Let `L(t)` be self-adjoint and change in time by
a commutator, `L_t = B L − L B`. If `ψ(t)` is a nonzero eigenvector, `L(t) ψ(t) = E(t) ψ(t)`,
with `ψ` and `E` differentiable in time, then the eigenvalue `E(t)` never changes. -/
theorem lax_flow_eigenvalue_const {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (L B : ℝ → V →L[ℝ] V) (ψ : ℝ → V) (E : ℝ → ℝ)
    (hL : ∀ t, HasDerivAt L (B t * L t - L t * B t) t)
    (hsymm : ∀ t, ((L t : V →L[ℝ] V) : V →ₗ[ℝ] V).IsSymmetric)
    (hψ : Differentiable ℝ ψ) (hE : Differentiable ℝ E)
    (heig : ∀ t, L t (ψ t) = E t • ψ t) (hne : ∀ t, ψ t ≠ 0) :
    ∀ t, E t = E 0 := by
  intro t
  have key : ∀ s, deriv E s = 0 := by
    intro s
    have h1 : HasDerivAt (fun r => L r (ψ r))
        ((B s * L s - L s * B s) (ψ s) + L s (deriv ψ s)) s :=
      (hL s).clm_apply (hψ s).hasDerivAt
    have h2 : HasDerivAt (fun r => E r • ψ r) (E s • deriv ψ s + deriv E s • ψ s) s :=
      (hE s).hasDerivAt.smul (hψ s).hasDerivAt
    have hfun : (fun r => L r (ψ r)) = fun r => E r • ψ r := funext heig
    rw [hfun] at h1
    have heq := h1.unique h2
    have hi := congrArg (fun v => inner ℝ v (ψ s)) heq
    simp only [sub_apply, mul_apply_eq_comp, inner_add_left,
      inner_sub_left, real_inner_smul_left] at hi
    have s1 := hsymm s (B s (ψ s)) (ψ s)
    have s2 := hsymm s (deriv ψ s) (ψ s)
    simp only [ContinuousLinearMap.coe_coe] at s1 s2
    rw [s1, s2, heig s, map_smul, real_inner_smul_left, real_inner_smul_right,
      real_inner_smul_right] at hi
    have hpos : inner ℝ (ψ s) (ψ s) ≠ 0 := inner_self_ne_zero.mpr (hne s)
    have : deriv E s * inner ℝ (ψ s) (ψ s) = 0 := by linarith
    exact (mul_eq_zero.mp this).resolve_right hpos
  exact is_const_of_deriv_eq_zero hE key t 0


/-- **Each bound state is a soliton.** For every decay rate `κ` and centre `x₀`, the wave
`u(t, x) = −2κ² sech²(κ(x − 4κ²t − x₀))`, of depth `2κ²` and speed `4κ²`, solves KdV
`u_t − 6 u u_x + u_xxx = 0` at every time and place. -/
theorem kdv_one_soliton (κ x₀ t x : ℝ) :
    let u : ℝ → ℝ → ℝ := fun s y => -2 * κ ^ 2 / Real.cosh (κ * (y - 4 * κ ^ 2 * s - x₀)) ^ 2
    deriv (fun s => u s x) t - 6 * u t x * deriv (u t) x + deriv (deriv (deriv (u t))) x = 0 := by
  intro u
  have e0 : u t = fun y => (-2 * κ ^ 2) * (fun z => 1 / Real.cosh z ^ 2)
      (κ * y + -(κ * (4 * κ ^ 2 * t + x₀))) := by
    funext y
    simp only [u]
    rw [show κ * y + -(κ * (4 * κ ^ 2 * t + x₀)) = κ * (y - 4 * κ ^ 2 * t - x₀) by ring]
    ring
  have et : (fun s => u s x) = fun s => (-2 * κ ^ 2) * (fun z => 1 / Real.cosh z ^ 2)
      ((-4 * κ ^ 3) * s + κ * (x - x₀)) := by
    funext s
    simp only [u]
    rw [show (-4 * κ ^ 3) * s + κ * (x - x₀) = κ * (x - 4 * κ ^ 2 * s - x₀) by ring]
    ring
  have d1 := sol_affine _ _ sol_d0 (-2 * κ ^ 2) κ (-(κ * (4 * κ ^ 2 * t + x₀)))
  have d2 := sol_affine _ _ sol_d1 (-2 * κ ^ 2 * κ) κ (-(κ * (4 * κ ^ 2 * t + x₀)))
  have d3 := sol_affine _ _ sol_d2 (-2 * κ ^ 2 * κ * κ) κ (-(κ * (4 * κ ^ 2 * t + x₀)))
  have dt := sol_affine _ _ sol_d0 (-2 * κ ^ 2) (-4 * κ ^ 3) (κ * (x - x₀))
  rw [et, dt, e0, d1, d2, d3]
  beta_reduce
  rw [show (-4 * κ ^ 3) * t + κ * (x - x₀) = κ * x + -(κ * (4 * κ ^ 2 * t + x₀)) by ring]
  set θ := κ * x + -(κ * (4 * κ ^ 2 * t + x₀))
  have hc : Real.cosh θ ≠ 0 := (Real.cosh_pos θ).ne'
  have hq := Real.cosh_sq θ
  field_simp
  linear_combination (-48 * κ ^ 5 * Real.sinh θ) * hq

-- The well −6 sech² x has size ℓ(ℓ + 1) = 6 with ℓ = 2, so bound states κ = 2 and κ = 1.
example : (2 : ℕ) * (2 + 1) = 6 := by norm_num
-- Soliton depths 2κ² = 8 and 2; speeds 4κ² = 16 and 4.
example : 2 * (2 : ℕ) ^ 2 = 8 ∧ 2 * (1 : ℕ) ^ 2 = 2 := by norm_num
example : 4 * (2 : ℕ) ^ 2 = 16 ∧ 4 * (1 : ℕ) ^ 2 = 4 := by norm_num
-- Norming constants: c₂² = 16 ÷ 4/3 = 12 and c₁² = 4 ÷ 2/3 = 6.
example : (16 : ℚ) / (4 / 3) = 12 ∧ (4 : ℚ) / (2 / 3) = 6 := by norm_num
-- Matrix entries at t = 0: A₁₁ = 6/2 = 3, A₂₂ = 12/4 = 3, A₁₂² = 72/9 = 8.
example : (6 : ℚ) / 2 = 3 ∧ (12 : ℚ) / 4 = 3 ∧ (6 * 12 : ℚ) / (1 + 2) ^ 2 = 8 := by norm_num
-- The determinant at t = 0, with y = e^(−2x): (1 + 3y)(1 + 3y²) − 8y³ = (1 + y)³.
example (y : ℚ) : (1 + 3 * y) * (1 + 3 * y ^ 2) - 8 * y ^ 3 = (1 + y) ^ 3 := by ring
-- Growth rates 8κ³ of ln c²: 8 for κ = 1 and 64 for κ = 2.
example : 8 * (1 : ℕ) ^ 3 = 8 ∧ 8 * (2 : ℕ) ^ 3 = 64 := by norm_num
-- Conserved integrals from κ = 2, 1: ∫u = −4(2 + 1) = −12 and ∫u² = (16/3)(2³ + 1³) = 48.
example : -4 * ((2 : ℚ) + 1) = -12 ∧ (16 / 3 : ℚ) * (2 ^ 3 + 1 ^ 3) = 48 := by norm_num

#print axioms kdv_iff_lax_equation
#print axioms lax_flow_eigenvalue_const
#print axioms kdv_one_soliton
