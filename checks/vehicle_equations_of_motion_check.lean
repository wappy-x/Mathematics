-- Equations of motion of a vehicle: mirror symmetry makes the linearised equations split into a longitudinal block and a lateral block, the turning-axes moment terms are the stated cross product, and a 2×2 block's trace and determinant give a complex mode's natural frequency, damping ratio and swing rate.
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Comp
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff

open Matrix

/-- In a real vector space, a vector equal to its own negative is zero. -/
lemma eq_zero_of_eq_neg_real {M : Type*} [AddCommGroup M] [Module ℝ M] {w : M}
    (h : w = -w) : w = 0 := by
  have h2 : (2 : ℝ) • w = w - -w := by rw [two_smul, sub_neg_eq_add]
  rw [← h, sub_self] at h2
  exact (smul_eq_zero.mp h2).resolve_left two_ne_zero

#print axioms eq_zero_of_eq_neg_real

/-- The small-disturbance split. Let the state be a pair (x, y): x the longitudinal
variables (u, w, q, θ) and y the lateral variables (v, r, p, φ), and let `F` give their
rates of change. Left-right mirror symmetry means that reflecting the aircraft
(y ↦ -y) leaves the longitudinal rates unchanged and flips the lateral rates.
Linearise about a symmetric trim point (x₀, 0) where `F` is differentiable: then a
longitudinal change produces no first-order lateral rate, and a lateral change
produces no first-order longitudinal rate, so the linear system is two separate
blocks. -/
theorem mirror_symmetry_splits_linearised_motion
    {E L : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [NormedAddCommGroup L] [NormedSpace ℝ L]
    (F : E × L → E × L)
    (hmirror : ∀ x y, F (x, -y) = ((F (x, y)).1, -(F (x, y)).2))
    (x₀ : E) (hF : DifferentiableAt ℝ F (x₀, 0)) :
    (∀ u : E, (fderiv ℝ F (x₀, 0) (u, 0)).2 = 0) ∧
    (∀ v : L, (fderiv ℝ F (x₀, 0) (0, v)).1 = 0) := by
  set S : E × L →L[ℝ] E × L :=
    (ContinuousLinearMap.fst ℝ E L).prod (-(ContinuousLinearMap.snd ℝ E L)) with hS
  have hSp : S (x₀, 0) = (x₀, 0) := by simp [hS]
  have hfun : F ∘ S = S ∘ F := by
    funext ⟨x, y⟩
    simp only [Function.comp_apply, hS, ContinuousLinearMap.prod_apply,
      ContinuousLinearMap.coe_fst', neg_apply,
      ContinuousLinearMap.coe_snd']
    rw [hmirror]
  have h1 : HasFDerivAt (F ∘ S) ((fderiv ℝ F (x₀, 0)).comp S) (x₀, 0) := by
    have hF' : HasFDerivAt F (fderiv ℝ F (x₀, 0)) (S (x₀, 0)) := by
      rw [hSp]; exact hF.hasFDerivAt
    exact hF'.comp (x₀, 0) S.hasFDerivAt
  have h2 : HasFDerivAt (S ∘ F) (S.comp (fderiv ℝ F (x₀, 0))) (x₀, 0) :=
    S.hasFDerivAt.comp (x₀, 0) hF.hasFDerivAt
  rw [hfun] at h1
  have heq := h1.unique h2
  have key : ∀ w, fderiv ℝ F (x₀, 0) (S w) = S (fderiv ℝ F (x₀, 0) w) := fun w => by
    have := congrArg (fun T : E × L →L[ℝ] E × L => T w) heq
    simpa using this
  constructor
  · intro u
    have h := congrArg Prod.snd (key (u, 0))
    have h' : (fderiv ℝ F (x₀, 0) (u, 0)).2 = -(fderiv ℝ F (x₀, 0) (u, 0)).2 := by
      simpa [hS] using h
    exact eq_zero_of_eq_neg_real h'
  · intro v
    have h := congrArg Prod.fst (key (0, v))
    have hS0 : S ((0 : E), v) = -((0 : E), v) := by
      ext <;> simp [hS]
    have hS1 : (S (fderiv ℝ F (x₀, 0) (0, v))).1 = (fderiv ℝ F (x₀, 0) (0, v)).1 := by
      simp [hS]
    rw [hS0, map_neg, hS1, Prod.fst_neg] at h
    exact eq_zero_of_eq_neg_real h.symm

/-- The turning-axes terms of the moment equations. For an aircraft symmetric about
its x–z plane the spin arrow is H = (I_x p - I_xz r, I_y q, I_z r - I_xz p), and the
cross product ω × H with ω = (p, q, r) is
((I_z - I_y) q r - I_xz p q, (I_x - I_z) r p + I_xz (p² - r²), (I_y - I_x) p q + I_xz q r). -/
theorem moment_equation_turning_terms (p q r Ix Iy Iz Ixz : ℝ) :
    ![p, q, r] ⨯₃ ![Ix * p - Ixz * r, Iy * q, Iz * r - Ixz * p] =
      ![(Iz - Iy) * q * r - Ixz * p * q,
        (Ix - Iz) * r * p + Ixz * (p ^ 2 - r ^ 2),
        (Iy - Ix) * p * q + Ixz * q * r] := by
  ext i
  fin_cases i <;> simp [cross_apply] <;> ring

/-- Two-state approximations by trace and determinant. If a real 2×2 matrix has a
complex (non-real) eigenvalue z = -σ + j ω_d, then its natural frequency
ω_n = |z| is the square root of the determinant, its damping ratio ζ = σ / |z|
equals -trace / (2 ω_n), and its swing rate ω_d is √(det - trace² / 4). -/
theorem two_by_two_mode_from_trace_and_det
    (A : Matrix (Fin 2) (Fin 2) ℝ) (z : ℂ)
    (heig : (A.charpoly.map (algebraMap ℝ ℂ)).IsRoot z) (hcomplex : z.im ≠ 0) :
    ‖z‖ = Real.sqrt A.det ∧
    -z.re / ‖z‖ = -A.trace / (2 * Real.sqrt A.det) ∧
    |z.im| = Real.sqrt (A.det - A.trace ^ 2 / 4) := by
  rw [Matrix.charpoly_fin_two] at heig
  simp only [Polynomial.IsRoot, Polynomial.eval_map, Polynomial.eval₂_add, Polynomial.eval₂_sub,
    Polynomial.eval₂_mul, Polynomial.eval₂_pow, Polynomial.eval₂_X, Polynomial.eval₂_C] at heig
  have hre := congrArg Complex.re heig
  have him := congrArg Complex.im heig
  simp [pow_two] at hre him
  have ht : A.trace = 2 * z.re := by
    have : (2 * z.re - A.trace) * z.im = 0 := by linarith
    rcases mul_eq_zero.mp this with h | h
    · linarith
    · exact absurd h hcomplex
  have hd : A.det = z.re ^ 2 + z.im ^ 2 := by
    rw [ht] at hre; linear_combination hre
  have hn : ‖z‖ = Real.sqrt A.det := by
    rw [Complex.norm_def, Complex.normSq_apply, hd]; congr 1; ring
  refine ⟨hn, ?_, ?_⟩
  · rw [← hn, ht]; ring
  · rw [hd, ht, ← Real.sqrt_sq_eq_abs]; congr 1; ring

#print axioms mirror_symmetry_splits_linearised_motion
#print axioms moment_equation_turning_terms
#print axioms two_by_two_mode_from_trace_and_det
