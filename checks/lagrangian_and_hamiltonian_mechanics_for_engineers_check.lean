-- Lagrangian and Hamiltonian mechanics: feeding the two-link arm's kinetic minus potential energy through Lagrange's equation gives the manipulator equation M q'' + c + w, the energy stays fixed with the motors off, and a pendulum rod's multiplier gives the tension m (v² - g y) / l.
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open Real

noncomputable section

/-! ### How the card's objects are written here

A two-link arm in a vertical plane. The shoulder angle `θ1` is measured above horizontal, the
elbow angle `θ2` from the upper arm's line. `ω1`, `ω2` are the joint speeds.

The arm's numbers: upper arm mass `m1`, length `l1`, joint-to-centre distance `a1`, spin inertia
about its own centre `I1`; forearm mass `m2`, joint-to-centre distance `a2`, spin inertia `I2`;
gravity `g`.

A partial slope of the Lagrangian is `deriv` of one input with the others held. A motion is a
pair of paths `θ1 θ2 : ℝ → ℝ`; its speeds are `deriv θi t`, its accelerations `deriv (deriv θi) t`. -/

/-- The data of a two-link arm (The formula's table). -/
structure TwoLinkArm where
  m1 : ℝ
  m2 : ℝ
  l1 : ℝ
  a1 : ℝ
  a2 : ℝ
  I1 : ℝ
  I2 : ℝ
  g : ℝ

namespace TwoLinkArm

variable (A : TwoLinkArm)

/-- Kinetic energy (Step 1): each link's centre moves with the velocity of its centre point, and
spins about its centre. The upper arm's centre is `a1 (cos θ1, sin θ1)`; the forearm's centre is
`l1 (cos θ1, sin θ1) + a2 (cos (θ1 + θ2), sin (θ1 + θ2))`, and the forearm spins at `ω1 + ω2`. -/
def T (θ1 θ2 ω1 ω2 : ℝ) : ℝ :=
  1 / 2 * A.m1 * ((-(A.a1 * ω1 * sin θ1)) ^ 2 + (A.a1 * ω1 * cos θ1) ^ 2)
    + 1 / 2 * A.I1 * ω1 ^ 2
    + 1 / 2 * A.m2 * ((-(A.l1 * ω1 * sin θ1) - A.a2 * (ω1 + ω2) * sin (θ1 + θ2)) ^ 2
        + (A.l1 * ω1 * cos θ1 + A.a2 * (ω1 + ω2) * cos (θ1 + θ2)) ^ 2)
    + 1 / 2 * A.I2 * (ω1 + ω2) ^ 2

/-- Potential energy (Step 2): weight times height of each centre above the shoulder. -/
def V (θ1 θ2 : ℝ) : ℝ :=
  A.g * (A.m1 * A.a1 * sin θ1 + A.m2 * (A.l1 * sin θ1 + A.a2 * sin (θ1 + θ2)))

/-- The Lagrangian `L = T - V`. -/
def L (θ1 θ2 ω1 ω2 : ℝ) : ℝ := A.T θ1 θ2 ω1 ω2 - A.V θ1 θ2

/-- Mass matrix entry `M11`. -/
def M11 (θ2 : ℝ) : ℝ :=
  A.I1 + A.I2 + A.m1 * A.a1 ^ 2 + A.m2 * (A.l1 ^ 2 + A.a2 ^ 2 + 2 * A.l1 * A.a2 * cos θ2)

/-- Mass matrix entry `M12 = M21`, the off-diagonal entry that couples the joints. -/
def M12 (θ2 : ℝ) : ℝ := A.I2 + A.m2 * (A.a2 ^ 2 + A.l1 * A.a2 * cos θ2)

/-- Mass matrix entry `M22`. -/
def M22 : ℝ := A.I2 + A.m2 * A.a2 ^ 2

/-- Speed terms `c = h sin θ2 (-θ2'(2θ1' + θ2'), θ1'²)` with `h = m2 l1 a2`: first row. -/
def c1 (θ2 ω1 ω2 : ℝ) : ℝ := A.m2 * A.l1 * A.a2 * sin θ2 * (-(ω2 * (2 * ω1 + ω2)))

/-- Speed terms, second row. -/
def c2 (θ2 ω1 : ℝ) : ℝ := A.m2 * A.l1 * A.a2 * sin θ2 * ω1 ^ 2

/-- Gravity torque at the shoulder, `w1`. -/
def w1 (θ1 θ2 : ℝ) : ℝ :=
  A.g * ((A.m1 * A.a1 + A.m2 * A.l1) * cos θ1 + A.m2 * A.a2 * cos (θ1 + θ2))

/-- Gravity torque at the elbow, `w2`. -/
def w2 (θ1 θ2 : ℝ) : ℝ := A.g * (A.m2 * A.a2 * cos (θ1 + θ2))

end TwoLinkArm

open TwoLinkArm

theorem TwoLinkArm.T_eq (A : TwoLinkArm) (a b u v : ℝ) :
    A.T a b u v = 1 / 2 * A.M11 b * u ^ 2 + A.M12 b * u * v + 1 / 2 * A.M22 * v ^ 2 := by
  have e1 : sin a ^ 2 + cos a ^ 2 = 1 := sin_sq_add_cos_sq a
  have e2 : sin (a + b) ^ 2 + cos (a + b) ^ 2 = 1 := sin_sq_add_cos_sq _
  have e3 : sin a * sin (a + b) + cos a * cos (a + b) = cos b := by
    have h := cos_sub (a + b) a
    rw [show a + b - a = b by ring] at h
    linear_combination -h
  simp only [T, M11, M12, M22]
  linear_combination (1 / 2 * A.m1 * A.a1 ^ 2 * u ^ 2 + 1 / 2 * A.m2 * A.l1 ^ 2 * u ^ 2) * e1
    + 1 / 2 * A.m2 * A.a2 ^ 2 * (u + v) ^ 2 * e2 + A.m2 * A.l1 * A.a2 * u * (u + v) * e3

theorem TwoLinkArm.L_eq (A : TwoLinkArm) (a b u v : ℝ) :
    A.L a b u v = 1 / 2 * A.M11 b * u ^ 2 + A.M12 b * u * v + 1 / 2 * A.M22 * v ^ 2
      - A.V a b := by
  rw [L, T_eq]

theorem TwoLinkArm.hasDerivAt_M11 (A : TwoLinkArm) {f : ℝ → ℝ} {f' t : ℝ}
    (hf : HasDerivAt f f' t) :
    HasDerivAt (fun s => A.M11 (f s)) (-(2 * A.m2 * A.l1 * A.a2 * sin (f t)) * f') t := by
  have h := HasDerivAt.const_add (A.I1 + A.I2 + A.m1 * A.a1 ^ 2)
    (HasDerivAt.const_mul A.m2
      (HasDerivAt.const_add (A.l1 ^ 2 + A.a2 ^ 2)
        (HasDerivAt.const_mul (2 * A.l1 * A.a2) hf.cos)))
  convert h using 1 <;> first | rfl | ring

theorem TwoLinkArm.hasDerivAt_M12 (A : TwoLinkArm) {f : ℝ → ℝ} {f' t : ℝ}
    (hf : HasDerivAt f f' t) :
    HasDerivAt (fun s => A.M12 (f s)) (-(A.m2 * A.l1 * A.a2 * sin (f t)) * f') t := by
  have h := HasDerivAt.const_add A.I2
    (HasDerivAt.const_mul A.m2
      (HasDerivAt.const_add (A.a2 ^ 2) (HasDerivAt.const_mul (A.l1 * A.a2) hf.cos)))
  convert h using 1 <;> first | rfl | ring

theorem TwoLinkArm.hasDerivAt_V (A : TwoLinkArm) {f g : ℝ → ℝ} {f' g' t : ℝ}
    (hf : HasDerivAt f f' t) (hg : HasDerivAt g g' t) :
    HasDerivAt (fun s => A.V (f s) (g s)) (A.w1 (f t) (g t) * f' + A.w2 (f t) (g t) * g') t := by
  have hfg : HasDerivAt (fun s => f s + g s) (f' + g') t := hf.add hg
  have h := HasDerivAt.const_mul A.g
    (HasDerivAt.add (HasDerivAt.const_mul (A.m1 * A.a1) hf.sin)
      (HasDerivAt.const_mul A.m2
        (HasDerivAt.add (HasDerivAt.const_mul A.l1 hf.sin) (HasDerivAt.const_mul A.a2 hfg.sin))))
  convert h using 1 <;> first | rfl | (simp only [w1, w2]; ring)

theorem TwoLinkArm.deriv_L_ω1 (A : TwoLinkArm) (a b u v : ℝ) :
    deriv (fun w => A.L a b w v) u = A.M11 b * u + A.M12 b * v := by
  have h := HasDerivAt.sub_const (A.V a b)
    (HasDerivAt.add_const (1 / 2 * A.M22 * v ^ 2)
      (HasDerivAt.add (HasDerivAt.const_mul (1 / 2 * A.M11 b) (hasDerivAt_pow 2 u))
        (HasDerivAt.mul_const (HasDerivAt.const_mul (A.M12 b) (hasDerivAt_id' u)) v)))
  have hf : (fun w => A.L a b w v) = fun w => 1 / 2 * A.M11 b * w ^ 2 + A.M12 b * w * v
      + 1 / 2 * A.M22 * v ^ 2 - A.V a b := funext fun w => A.L_eq a b w v
  rw [hf]
  refine h.deriv.trans ?_
  simp
  ring

theorem TwoLinkArm.deriv_L_ω2 (A : TwoLinkArm) (a b u v : ℝ) :
    deriv (fun w => A.L a b u w) v = A.M12 b * u + A.M22 * v := by
  have h := HasDerivAt.sub_const (A.V a b)
    (HasDerivAt.add
      (HasDerivAt.const_add (1 / 2 * A.M11 b * u ^ 2)
        (HasDerivAt.const_mul (A.M12 b * u) (hasDerivAt_id' v)))
      (HasDerivAt.const_mul (1 / 2 * A.M22) (hasDerivAt_pow 2 v)))
  have hf : (fun w => A.L a b u w) = fun w => 1 / 2 * A.M11 b * u ^ 2 + A.M12 b * u * w
      + 1 / 2 * A.M22 * w ^ 2 - A.V a b := funext fun w => A.L_eq a b u w
  rw [hf]
  refine h.deriv.trans ?_
  simp
  ring

theorem TwoLinkArm.deriv_L_θ1 (A : TwoLinkArm) (a b u v : ℝ) :
    deriv (fun x => A.L x b u v) a = -A.w1 a b := by
  have h := HasDerivAt.const_sub
    (1 / 2 * A.M11 b * u ^ 2 + A.M12 b * u * v + 1 / 2 * A.M22 * v ^ 2)
    (A.hasDerivAt_V (hasDerivAt_id' a) (hasDerivAt_const a b))
  have hf : (fun x => A.L x b u v) = fun x => 1 / 2 * A.M11 b * u ^ 2 + A.M12 b * u * v
      + 1 / 2 * A.M22 * v ^ 2 - A.V x b := funext fun x => A.L_eq x b u v
  rw [hf]
  refine h.deriv.trans ?_
  ring

theorem TwoLinkArm.deriv_L_θ2 (A : TwoLinkArm) (a b u v : ℝ) :
    deriv (fun x => A.L a x u v) b
      = -(A.m2 * A.l1 * A.a2 * sin b * (u ^ 2 + u * v)) - A.w2 a b := by
  have h := HasDerivAt.sub
    (HasDerivAt.add_const (1 / 2 * A.M22 * v ^ 2)
      (HasDerivAt.add
        (HasDerivAt.mul_const
          (HasDerivAt.const_mul (1 / 2) (A.hasDerivAt_M11 (hasDerivAt_id' b))) (u ^ 2))
        (HasDerivAt.mul_const
          (HasDerivAt.mul_const (A.hasDerivAt_M12 (hasDerivAt_id' b)) u) v)))
    (A.hasDerivAt_V (hasDerivAt_const b a) (hasDerivAt_id' b))
  have hf : (fun x => A.L a x u v) = fun x => 1 / 2 * A.M11 x * u ^ 2 + A.M12 x * u * v
      + 1 / 2 * A.M22 * v ^ 2 - A.V a x := funext fun x => A.L_eq a x u v
  rw [hf]
  refine h.deriv.trans ?_
  ring

#print axioms TwoLinkArm.T_eq
#print axioms TwoLinkArm.L_eq
#print axioms TwoLinkArm.hasDerivAt_M11
#print axioms TwoLinkArm.hasDerivAt_M12
#print axioms TwoLinkArm.hasDerivAt_V
#print axioms TwoLinkArm.deriv_L_ω1
#print axioms TwoLinkArm.deriv_L_ω2
#print axioms TwoLinkArm.deriv_L_θ1
#print axioms TwoLinkArm.deriv_L_θ2

/-- The card's main claim (The formula, Why it works Steps 1 to 3). Write the two-link arm's
kinetic energy and potential energy in the joint angles and take `L = T - V`. Along any motion
`θ1(t), θ2(t)` (twice differentiable), Lagrange's expression for each joint,
`d/dt (∂L/∂θi') - ∂L/∂θi`, equals that joint's row of the manipulator equation
`M(q) q'' + c(q, q') + w(q)`, with `M`, `c` and `w` exactly as on the card. So Lagrange's equation
with motor torques `τ1`, `τ2` on the right is the manipulator equation `M q'' + c + w = τ`, and no
pin force appears. -/
theorem lagrange_equations_give_manipulator_equation (A : TwoLinkArm) (θ1 θ2 : ℝ → ℝ)
    (h1 : ContDiff ℝ 2 θ1) (h2 : ContDiff ℝ 2 θ2) (t : ℝ) :
    deriv (fun s => deriv (fun w => A.L (θ1 s) (θ2 s) w (deriv θ2 s)) (deriv θ1 s)) t
        - deriv (fun x => A.L x (θ2 t) (deriv θ1 t) (deriv θ2 t)) (θ1 t)
      = A.M11 (θ2 t) * deriv (deriv θ1) t + A.M12 (θ2 t) * deriv (deriv θ2) t
          + A.c1 (θ2 t) (deriv θ1 t) (deriv θ2 t) + A.w1 (θ1 t) (θ2 t) ∧
    deriv (fun s => deriv (fun w => A.L (θ1 s) (θ2 s) (deriv θ1 s) w) (deriv θ2 s)) t
        - deriv (fun x => A.L (θ1 t) x (deriv θ1 t) (deriv θ2 t)) (θ2 t)
      = A.M12 (θ2 t) * deriv (deriv θ1) t + A.M22 * deriv (deriv θ2) t
          + A.c2 (θ2 t) (deriv θ1 t) + A.w2 (θ1 t) (θ2 t) := by
  have hθ1 : HasDerivAt θ1 (deriv θ1 t) t := ((h1.differentiable (by norm_num)) t).hasDerivAt
  have hθ2 : HasDerivAt θ2 (deriv θ2 t) t := ((h2.differentiable (by norm_num)) t).hasDerivAt
  have hω1 : HasDerivAt (deriv θ1) (deriv (deriv θ1) t) t :=
    (h1.differentiable_deriv_two t).hasDerivAt
  have hω2 : HasDerivAt (deriv θ2) (deriv (deriv θ2) t) t :=
    (h2.differentiable_deriv_two t).hasDerivAt
  simp only [TwoLinkArm.deriv_L_ω1, TwoLinkArm.deriv_L_ω2, TwoLinkArm.deriv_L_θ1,
    TwoLinkArm.deriv_L_θ2]
  have k1 : deriv (fun s => A.M11 (θ2 s) * deriv θ1 s + A.M12 (θ2 s) * deriv θ2 s) t
      = (-(2 * A.m2 * A.l1 * A.a2 * sin (θ2 t)) * deriv θ2 t) * deriv θ1 t
          + A.M11 (θ2 t) * deriv (deriv θ1) t
        + ((-(A.m2 * A.l1 * A.a2 * sin (θ2 t)) * deriv θ2 t) * deriv θ2 t
          + A.M12 (θ2 t) * deriv (deriv θ2) t) :=
    (HasDerivAt.add (HasDerivAt.mul (A.hasDerivAt_M11 hθ2) hω1)
      (HasDerivAt.mul (A.hasDerivAt_M12 hθ2) hω2)).deriv
  have k2 : deriv (fun s => A.M12 (θ2 s) * deriv θ1 s + A.M22 * deriv θ2 s) t
      = (-(A.m2 * A.l1 * A.a2 * sin (θ2 t)) * deriv θ2 t) * deriv θ1 t
          + A.M12 (θ2 t) * deriv (deriv θ1) t
        + A.M22 * deriv (deriv θ2) t :=
    (HasDerivAt.add (HasDerivAt.mul (A.hasDerivAt_M12 hθ2) hω1)
      (HasDerivAt.const_mul A.M22 hω2)).deriv
  rw [k1, k2]
  simp only [TwoLinkArm.c1, TwoLinkArm.c2]
  constructor <;> ring

/-- With the motors off the energy cannot change (Step 6). If the arm moves by the manipulator
equation with `τ = 0` at every time, then the total energy `T + V` (the Hamiltonian `H`, which is
this same energy written in angles and momenta) has the same value at every time. -/
theorem energy_conserved_with_motors_off (A : TwoLinkArm) (θ1 θ2 : ℝ → ℝ)
    (h1 : ContDiff ℝ 2 θ1) (h2 : ContDiff ℝ 2 θ2)
    (row1 : ∀ t, A.M11 (θ2 t) * deriv (deriv θ1) t + A.M12 (θ2 t) * deriv (deriv θ2) t
          + A.c1 (θ2 t) (deriv θ1 t) (deriv θ2 t) + A.w1 (θ1 t) (θ2 t) = 0)
    (row2 : ∀ t, A.M12 (θ2 t) * deriv (deriv θ1) t + A.M22 * deriv (deriv θ2) t
          + A.c2 (θ2 t) (deriv θ1 t) + A.w2 (θ1 t) (θ2 t) = 0) (t : ℝ) :
    A.T (θ1 t) (θ2 t) (deriv θ1 t) (deriv θ2 t) + A.V (θ1 t) (θ2 t)
      = A.T (θ1 0) (θ2 0) (deriv θ1 0) (deriv θ2 0) + A.V (θ1 0) (θ2 0) := by
  have hE : ∀ s, HasDerivAt (fun s => A.T (θ1 s) (θ2 s) (deriv θ1 s) (deriv θ2 s)
      + A.V (θ1 s) (θ2 s)) 0 s := by
    intro s
    have hθ1 : HasDerivAt θ1 (deriv θ1 s) s := ((h1.differentiable (by norm_num)) s).hasDerivAt
    have hθ2 : HasDerivAt θ2 (deriv θ2 s) s := ((h2.differentiable (by norm_num)) s).hasDerivAt
    have hω1 : HasDerivAt (deriv θ1) (deriv (deriv θ1) s) s :=
      (h1.differentiable_deriv_two s).hasDerivAt
    have hω2 : HasDerivAt (deriv θ2) (deriv (deriv θ2) s) s :=
      (h2.differentiable_deriv_two s).hasDerivAt
    have k := HasDerivAt.add
      (HasDerivAt.add
        (HasDerivAt.add
          (HasDerivAt.mul (HasDerivAt.const_mul (1 / 2) (A.hasDerivAt_M11 hθ2)) (hω1.pow 2))
          (HasDerivAt.mul (HasDerivAt.mul (A.hasDerivAt_M12 hθ2) hω1) hω2))
        (HasDerivAt.const_mul (1 / 2 * A.M22) (hω2.pow 2)))
      (A.hasDerivAt_V hθ1 hθ2)
    have hf : (fun s => A.T (θ1 s) (θ2 s) (deriv θ1 s) (deriv θ2 s) + A.V (θ1 s) (θ2 s))
        = fun s => 1 / 2 * A.M11 (θ2 s) * deriv θ1 s ^ 2
          + A.M12 (θ2 s) * deriv θ1 s * deriv θ2 s + 1 / 2 * A.M22 * deriv θ2 s ^ 2
          + A.V (θ1 s) (θ2 s) := funext fun s => by rw [TwoLinkArm.T_eq]
    rw [hf]
    convert k using 1
    have r1 := row1 s
    have r2 := row2 s
    simp only [TwoLinkArm.c1, TwoLinkArm.c2] at r1 r2
    simp only [Pi.mul_apply, Pi.pow_apply]
    push_cast
    linear_combination (-deriv θ1 s) * r1 - deriv θ2 s * r2
  exact is_const_of_deriv_eq_zero (fun s => (hE s).differentiableAt) (fun s => (hE s).deriv) t 0

/-- A multiplier gives back the rod force (Step 5). A bob of mass `m` at `(x, y)` from the pivot
is held by a rod of length `l > 0`: `√(x² + y²) - l = 0` at every time. If it moves by Lagrange's
equations with multiplier `λ`, `m x'' = λ x / l` and `m y'' = -m g + λ y / l`, then the rod
tension `F = -λ` is `m (v² - g y) / l`, where `v² = x'² + y'²` is the bob's speed squared. -/
theorem pendulum_rod_tension_from_multiplier (m l g : ℝ) (hl : 0 < l) (x y lam : ℝ → ℝ)
    (hx : ContDiff ℝ 2 x) (hy : ContDiff ℝ 2 y)
    (rod : ∀ t, √(x t ^ 2 + y t ^ 2) - l = 0)
    (eqx : ∀ t, m * deriv (deriv x) t = lam t * x t / l)
    (eqy : ∀ t, m * deriv (deriv y) t = -m * g + lam t * y t / l) (t : ℝ) :
    -lam t = m * (deriv x t ^ 2 + deriv y t ^ 2 - g * y t) / l := by
  have dx : Differentiable ℝ x := hx.differentiable (by norm_num)
  have dy : Differentiable ℝ y := hy.differentiable (by norm_num)
  have ddx := hx.differentiable_deriv_two
  have ddy := hy.differentiable_deriv_two
  have hl0 : l ≠ 0 := hl.ne'
  have sq : ∀ s, x s ^ 2 + y s ^ 2 = l ^ 2 := by
    intro s
    have h' : √(x s ^ 2 + y s ^ 2) = l := by linarith [rod s]
    rw [← h', sq_sqrt (by positivity)]
  have first : ∀ s, x s * deriv x s + y s * deriv y s = 0 := by
    intro s
    have e : deriv (fun s => x s ^ 2 + y s ^ 2) s
        = 2 * (x s * deriv x s + y s * deriv y s) :=
      (HasDerivAt.add ((dx s).hasDerivAt.pow 2) ((dy s).hasDerivAt.pow 2)).deriv.trans
        (by push_cast; ring)
    have hc : (fun s => x s ^ 2 + y s ^ 2) = fun _ => l ^ 2 := funext sq
    rw [hc, deriv_const] at e
    linarith
  have second : ∀ s, deriv x s ^ 2 + x s * deriv (deriv x) s + deriv y s ^ 2
      + y s * deriv (deriv y) s = 0 := by
    intro s
    have e : deriv (fun s => x s * deriv x s + y s * deriv y s) s
        = deriv x s ^ 2 + x s * deriv (deriv x) s + deriv y s ^ 2
          + y s * deriv (deriv y) s :=
      (HasDerivAt.add (HasDerivAt.mul (dx s).hasDerivAt (ddx s).hasDerivAt)
        (HasDerivAt.mul (dy s).hasDerivAt (ddy s).hasDerivAt)).deriv.trans (by ring)
    have hc : (fun s => x s * deriv x s + y s * deriv y s) = fun _ => 0 := funext first
    rw [hc, deriv_const] at e
    linarith
  have ex : l * (m * deriv (deriv x) t) = lam t * x t := by
    rw [eqx t]; field_simp
  have ey : l * (m * deriv (deriv y) t) = -m * g * l + lam t * y t := by
    rw [eqy t]; field_simp
  have key : l * (-lam t * l) = l * (m * (deriv x t ^ 2 + deriv y t ^ 2 - g * y t)) := by
    linear_combination x t * ex + y t * ey + lam t * sq t - l * m * second t
  rw [eq_div_iff hl0]
  exact mul_left_cancel₀ hl0 key

/-- The card's arm: upper arm 4 kg, 0.5 m; forearm 2.5 kg, 0.4 m; uniform links, so each centre
is at half the length and each spin inertia is `m l² / 12`; gravity 9.81 m/s². -/
def cardArm : TwoLinkArm :=
  ⟨4, 5 / 2, 1 / 2, 1 / 4, 1 / 5, 4 * (1 / 2) ^ 2 / 12, 5 / 2 * (2 / 5) ^ 2 / 12, 981 / 100⟩

-- Mass matrix straight out: 1.591667, 0.383333, 0.133333 kg m² (exactly 191/120, 23/60, 2/15).
example : cardArm.M11 0 = 191 / 120 := by norm_num [cardArm, M11]
example : cardArm.M12 0 = 23 / 60 := by norm_num [cardArm, M12]
example : cardArm.M22 = 2 / 15 := by norm_num [cardArm, M22]
-- Held straight out: shoulder 26.9775 N m, elbow 4.9050 N m.
example : cardArm.w1 0 0 = 10791 / 400 ∧ cardArm.w2 0 0 = 981 / 200 := by norm_num [cardArm, w1, w2]
-- Start of the lift, shoulder 6 rad/s², elbow locked, at rest: 36.5275 and 7.2050 N m.
example : cardArm.M11 0 * 6 + cardArm.M12 0 * 0 + cardArm.c1 0 0 0 + cardArm.w1 0 0 = 14611 / 400 ∧
    cardArm.M12 0 * 6 + cardArm.M22 * 0 + cardArm.c2 0 0 + cardArm.w2 0 0 = 1441 / 200 := by norm_num [cardArm, M11, M12, M22, c1, c2, w1, w2]
-- Pendulum 2 kg from 60 degrees: bottom tension m g (3 - 2 cos θ0) = 39.2400 N, twice the weight.
example : (2 : ℝ) * (981 / 100) * (3 - 2 * cos (π / 3)) = 981 / 25 ∧
    (981 / 25 : ℝ) = 2 * (2 * (981 / 100)) := by norm_num [cos_pi_div_three]

#print axioms lagrange_equations_give_manipulator_equation
#print axioms energy_conserved_with_motors_off
#print axioms pendulum_rod_tension_from_multiplier
