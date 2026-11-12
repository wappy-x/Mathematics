-- Complex eigenvalues: for a constant real 2-by-2 matrix with trace^2 < 4 det and eigenpair alpha + i beta, p + i q, the solutions of x' = A x are exactly e^(alpha t) times mixes of p cos(beta t) - q sin(beta t) and p sin(beta t) + q cos(beta t), p and q span the plane, and each turn of 2 pi / beta multiplies the state by e^(alpha 2 pi / beta).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.Analysis.Complex.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas

open Matrix Complex

/-- The real solution built from one complex solution `w e^(λt)`, with `λ = α + iβ` and
`w = p + iq`: `c₁` times its real part plus `c₂` times its imaginary part,
`e^(αt) (c₁ (p cos βt − q sin βt) + c₂ (p sin βt + q cos βt))`. -/
noncomputable def spiral (α β : ℝ) (p q : Fin 2 → ℝ) (c₁ c₂ t : ℝ) : Fin 2 → ℝ :=
  Real.exp (α * t) • (c₁ • (Real.cos (β * t) • p - Real.sin (β * t) • q) +
    c₂ • (Real.sin (β * t) • p + Real.cos (β * t) • q))

lemma spiral_eig_parts (A : Matrix (Fin 2) (Fin 2) ℝ) (α β : ℝ) (p q : Fin 2 → ℝ)
    (heig : A.map (fun r : ℝ => (r : ℂ)) *ᵥ (fun i => (p i : ℂ) + (q i : ℂ) * I) =
      ((α : ℂ) + (β : ℂ) * I) • (fun i => (p i : ℂ) + (q i : ℂ) * I)) :
    A *ᵥ p = α • p - β • q ∧ A *ᵥ q = β • p + α • q := by
  have h0 := congrFun heig 0
  have h1 := congrFun heig 1
  simp only [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Matrix.map_apply, Pi.smul_apply,
    smul_eq_mul] at h0 h1
  have h0r := congrArg Complex.re h0
  have h0i := congrArg Complex.im h0
  have h1r := congrArg Complex.re h1
  have h1i := congrArg Complex.im h1
  simp at h0r h0i h1r h1i
  refine ⟨?_, ?_⟩ <;> ext i <;> fin_cases i <;>
    simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> linarith

#print axioms spiral_eig_parts

lemma spiral_cross_ne (A : Matrix (Fin 2) (Fin 2) ℝ) (hA : A.trace ^ 2 < 4 * A.det)
    (v : Fin 2 → ℝ) (hv : v ≠ 0) : (A *ᵥ v) 0 * v 1 - (A *ᵥ v) 1 * v 0 ≠ 0 := by
  rw [Matrix.trace_fin_two, Matrix.det_fin_two] at hA
  simp only [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
  intro h
  apply hv
  set a := A 0 0
  set b := A 0 1
  set c := A 1 0
  set d := A 1 1
  have hb : b ≠ 0 := by
    intro hb; rw [hb] at hA; nlinarith [sq_nonneg (a - d)]
  have e : (2*b*v 1 + (a-d)*v 0)^2 + (4*(a*d-b*c) - (a+d)^2) * v 0^2
      = 4*b*((a * v 0 + b * v 1) * v 1 - (c * v 0 + d * v 1) * v 0) := by ring
  rw [h, mul_zero] at e
  have hK : 0 < 4*(a*d-b*c) - (a+d)^2 := by linarith
  have h0 : v 0 ^ 2 = 0 := by
    nlinarith [sq_nonneg (2*b*v 1 + (a-d)*v 0), sq_nonneg (v 0), mul_nonneg hK.le (sq_nonneg (v 0))]
  have h0' : v 0 = 0 := by simpa using h0
  rw [h0'] at h
  have : b * v 1 ^ 2 = 0 := by linarith
  have h1 : v 1 = 0 := by
    rcases mul_eq_zero.mp this with h | h
    · exact absurd h hb
    · simpa using h
  ext i; fin_cases i
  · simpa using h0'
  · simpa using h1

#print axioms spiral_cross_ne

lemma spiral_beta_det (A : Matrix (Fin 2) (Fin 2) ℝ) (α β : ℝ) (p q : Fin 2 → ℝ)
    (hA : A.trace ^ 2 < 4 * A.det)
    (hw : (fun i => (p i : ℂ) + (q i : ℂ) * I) ≠ 0)
    (heig : A.map (fun r : ℝ => (r : ℂ)) *ᵥ (fun i => (p i : ℂ) + (q i : ℂ) * I) =
      ((α : ℂ) + (β : ℂ) * I) • (fun i => (p i : ℂ) + (q i : ℂ) * I)) :
    β * (p 0 * q 1 - p 1 * q 0) ≠ 0 := by
  obtain ⟨hp, hq⟩ := spiral_eig_parts A α β p q heig
  by_cases hp0 : p = 0
  · have hq0 : q ≠ 0 := by
      rintro rfl; apply hw; ext i; simp [hp0]
    have := spiral_cross_ne A hA q hq0
    rw [hq] at this
    simp at this
    convert this using 1; ring
  · have := spiral_cross_ne A hA p hp0
    rw [hp] at this
    simp at this
    convert this using 1; ring

#print axioms spiral_beta_det

lemma spiral_hasDerivAt (A : Matrix (Fin 2) (Fin 2) ℝ) (α β : ℝ) (p q : Fin 2 → ℝ)
    (hp : A *ᵥ p = α • p - β • q) (hq : A *ᵥ q = β • p + α • q) (c₁ c₂ t : ℝ) :
    HasDerivAt (fun s => spiral α β p q c₁ c₂ s) (A *ᵥ spiral α β p q c₁ c₂ t) t := by
  have hE : HasDerivAt (fun s => Real.exp (α * s)) (Real.exp (α * t) * α) t := by
    simpa using ((hasDerivAt_id t).const_mul α).exp
  have hC : HasDerivAt (fun s => Real.cos (β * s)) (-Real.sin (β * t) * β) t := by
    simpa using ((hasDerivAt_id t).const_mul β).cos
  have hS : HasDerivAt (fun s => Real.sin (β * s)) (Real.cos (β * t) * β) t := by
    simpa using ((hasDerivAt_id t).const_mul β).sin
  have hu := (((hC.smul_const p).sub (hS.smul_const q)).const_smul c₁).add
    (((hS.smul_const p).add (hC.smul_const q)).const_smul c₂)
  have h := hE.smul hu
  unfold spiral
  convert h using 1
  simp only [Matrix.mulVec_smul, Matrix.mulVec_add, Matrix.mulVec_sub, hp, hq]
  ext i
  simp only [Pi.smul_apply, Pi.add_apply, Pi.sub_apply, smul_eq_mul]
  ring

#print axioms spiral_hasDerivAt

/-- Complex eigenvalues give every solution: let `A` be a constant real 2-by-2 matrix whose
eigenvalues are not real (trace² < 4 × determinant), and let `λ = α + iβ` be an eigenvalue with
eigenvector `w = p + iq` (p, q real). Then a state `x(t)` solves `x' = A x` exactly when
`x(t) = e^(αt) (c₁ (p cos βt − q sin βt) + c₂ (p sin βt + q cos βt))` for some real `c₁`, `c₂`;
the real and imaginary parts of `w e^(λt)` are real solutions, and their mixes are all of them. -/
theorem solution_iff_spiral (A : Matrix (Fin 2) (Fin 2) ℝ) (α β : ℝ) (p q : Fin 2 → ℝ)
    (hA : A.trace ^ 2 < 4 * A.det)
    (hw : (fun i => (p i : ℂ) + (q i : ℂ) * I) ≠ 0)
    (heig : A.map (fun r : ℝ => (r : ℂ)) *ᵥ (fun i => (p i : ℂ) + (q i : ℂ) * I) =
      ((α : ℂ) + (β : ℂ) * I) • (fun i => (p i : ℂ) + (q i : ℂ) * I))
    (x : ℝ → Fin 2 → ℝ) :
    (∀ t, HasDerivAt x (A *ᵥ x t) t) ↔ ∃ c₁ c₂ : ℝ, ∀ t, x t = spiral α β p q c₁ c₂ t := by
  obtain ⟨hp, hq⟩ := spiral_eig_parts A α β p q heig
  have hD : p 0 * q 1 - p 1 * q 0 ≠ 0 := right_ne_zero_of_mul (spiral_beta_det A α β p q hA hw heig)
  constructor
  · intro hx
    set D := p 0 * q 1 - p 1 * q 0
    refine ⟨(x 0 0 * q 1 - x 0 1 * q 0) / D, (p 0 * x 0 1 - p 1 * x 0 0) / D, ?_⟩
    set c₁ := (x 0 0 * q 1 - x 0 1 * q 0) / D with hc₁
    set c₂ := (p 0 * x 0 1 - p 1 * x 0 0) / D with hc₂
    have hlip : ∀ _t : ℝ, LipschitzOnWith ‖(Matrix.toLin' A).toContinuousLinearMap‖₊
        (fun y : Fin 2 → ℝ => A *ᵥ y) Set.univ := fun _ =>
      ((Matrix.toLin' A).toContinuousLinearMap.lipschitzWith).lipschitzOnWith
    have key := ODE_solution_unique_univ (v := fun _ y => A *ᵥ y) (s := fun _ => Set.univ)
      (t₀ := 0) hlip (fun t => ⟨hx t, trivial⟩)
      (fun t => ⟨spiral_hasDerivAt A α β p q hp hq c₁ c₂ t, trivial⟩) ?_
    · intro t; exact congrFun key t
    · ext i
      fin_cases i
      · simp [spiral, hc₁, hc₂]; field_simp; ring
      · simp [spiral, hc₁, hc₂]; field_simp; ring
  · rintro ⟨c₁, c₂, h⟩ t
    have : x = fun s => spiral α β p q c₁ c₂ s := funext h
    subst this
    exact spiral_hasDerivAt A α β p q hp hq c₁ c₂ t

/-- They fit any start, in exactly one way: under the same hypotheses, the real part `p` and the
imaginary part `q` of the eigenvector point in different directions, so every start is
`c₁ p + c₂ q` for one pair `c₁`, `c₂`. -/
theorem eigenvector_parts_independent (A : Matrix (Fin 2) (Fin 2) ℝ) (α β : ℝ) (p q : Fin 2 → ℝ)
    (hA : A.trace ^ 2 < 4 * A.det)
    (hw : (fun i => (p i : ℂ) + (q i : ℂ) * I) ≠ 0)
    (heig : A.map (fun r : ℝ => (r : ℂ)) *ᵥ (fun i => (p i : ℂ) + (q i : ℂ) * I) =
      ((α : ℂ) + (β : ℂ) * I) • (fun i => (p i : ℂ) + (q i : ℂ) * I)) :
    LinearIndependent ℝ ![p, q] := by
  have hD : p 0 * q 1 - p 1 * q 0 ≠ 0 := right_ne_zero_of_mul (spiral_beta_det A α β p q hA hw heig)
  rw [LinearIndependent.pair_iff]
  intro s t h
  have h0 := congrFun h 0
  have h1 := congrFun h 1
  simp at h0 h1
  have e1 : s * (p 0 * q 1 - p 1 * q 0) = 0 := by linear_combination q 1 * h0 - q 0 * h1
  have e2 : t * (p 0 * q 1 - p 1 * q 0) = 0 := by linear_combination p 0 * h1 - p 1 * h0
  exact ⟨(mul_eq_zero.mp e1).resolve_right hD, (mul_eq_zero.mp e2).resolve_right hD⟩

/-- One turn: under the same hypotheses, every solution of `x' = A x` returns after
`T = 2π/β` to `e^(αT)` times where it was, so it spirals in when `α < 0`, out when `α > 0`,
and closes into a loop when `α = 0`. -/
theorem solution_after_one_turn (A : Matrix (Fin 2) (Fin 2) ℝ) (α β : ℝ) (p q : Fin 2 → ℝ)
    (hA : A.trace ^ 2 < 4 * A.det)
    (hw : (fun i => (p i : ℂ) + (q i : ℂ) * I) ≠ 0)
    (heig : A.map (fun r : ℝ => (r : ℂ)) *ᵥ (fun i => (p i : ℂ) + (q i : ℂ) * I) =
      ((α : ℂ) + (β : ℂ) * I) • (fun i => (p i : ℂ) + (q i : ℂ) * I))
    (x : ℝ → Fin 2 → ℝ) (hx : ∀ t, HasDerivAt x (A *ᵥ x t) t) (t : ℝ) :
    x (t + 2 * Real.pi / β) = Real.exp (α * (2 * Real.pi / β)) • x t := by
  have hβ : β ≠ 0 := left_ne_zero_of_mul (spiral_beta_det A α β p q hA hw heig)
  obtain ⟨c₁, c₂, h⟩ := (solution_iff_spiral A α β p q hA hw heig x).mp hx
  rw [h, h]
  have e : β * (t + 2 * Real.pi / β) = β * t + 2 * Real.pi := by field_simp
  unfold spiral
  rw [e, Real.cos_add_two_pi, Real.sin_add_two_pi, smul_smul, ← Real.exp_add]
  congr 2
  ring

/-! The card's worked numbers for the shock absorber, A = [[0, 1], [-5, -2]]. -/

-- Trace 0 + (-2) = -2 and determinant 0 × (-2) - 1 × (-5) = 5.
example : (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℤ).trace = -2 ∧
    (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℤ).det = 5 := by
  rw [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]; norm_num

-- Discriminant (-2)^2 - 4 × 5 = -16, so trace^2 < 4 det: the eigenvalues are not real.
example : (-2 : ℤ) ^ 2 - 4 * 5 = -16 ∧ (-2 : ℤ) ^ 2 < 4 * 5 := by norm_num

-- λ = -1 + 2i solves λ^2 + 2λ + 5 = 0.
example : ((-1 + 2 * I) ^ 2 + 2 * (-1 + 2 * I) + 5 : ℂ) = 0 := by
  ring_nf; rw [I_sq]; ring

-- Eigenvector w = (1, -1 + 2i): A w = (-1 + 2i, -3 - 4i) = λ w.
example : (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℂ) *ᵥ ![1, -1 + 2 * I] =
    (-1 + 2 * I) • ![1, -1 + 2 * I] := by
  ext i; fin_cases i
  · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
  · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two]; ring_nf; rw [I_sq]; ring

-- Fit the start: (10, 0) = 10 p + 5 q with p = (1, -1) and q = (0, 2).
example : (10 : ℤ) • ![1, -1] + (5 : ℤ) • ![0, 2] = ![10, 0] := by decide

-- Rate at the start: A × (10, 0) = (0, -50), a point on the right heading down: clockwise.
example : (!![0, 1; -5, -2] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![10, 0] = ![0, -50] := by decide

-- Velocity coefficients of cos 2t and sin 2t: 10 × (-1) + 5 × 2 = 0 and 5 × (-1) - 10 × 2 = -25.
example : (10 : ℤ) * (-1) + 5 * 2 = 0 ∧ (5 : ℤ) * (-1) - 10 * 2 = -25 := by norm_num

-- One turn takes 2π / 2 = π seconds.
example : 2 * Real.pi / 2 = Real.pi := by ring

#print axioms solution_iff_spiral
#print axioms eigenvector_parts_independent
#print axioms solution_after_one_turn
