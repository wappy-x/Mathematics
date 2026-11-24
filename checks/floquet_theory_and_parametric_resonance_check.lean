-- Floquet theory: for a 2 by 2 period matrix with determinant 1 the trace test decides boundedness or growth, Hill's equation has a period matrix of determinant 1, and every fundamental matrix is a periodic factor times a constant-matrix exponential.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic

open Matrix

/-- The trace test. Let M be a real 2 by 2 period (monodromy) matrix with determinant 1,
as for Hill's equation with no damping. If its trace lies strictly between -2 and 2, every
entry of every power M^n stays bounded, so every solution sampled once per period stays
bounded. If the trace is beyond ±2, there is a real Floquet multiplier μ with |μ| > 1 and a
nonzero start v with M^n v = μ^n v, so that solution grows like |μ|^n. -/
theorem trace_test_bounded_or_grows (M : Matrix (Fin 2) (Fin 2) ℝ) (hdet : M.det = 1) :
    (|M.trace| < 2 → ∃ C : ℝ, ∀ n : ℕ, ∀ i j : Fin 2, |(M ^ n) i j| ≤ C) ∧
    (2 < |M.trace| → ∃ μ : ℝ, ∃ v : Fin 2 → ℝ, v ≠ 0 ∧ 1 < |μ| ∧
        ∀ n : ℕ, (M ^ n) *ᵥ v = μ ^ n • v) := by
  rw [Matrix.det_fin_two] at hdet
  rw [Matrix.trace_fin_two]
  set a := M 0 0 with ha
  set b := M 0 1 with hb
  set c := M 1 0 with hc
  set d := M 1 1 with hd
  -- step formula for powers
  have hstep : ∀ n : ℕ, ∀ j : Fin 2,
      (M ^ (n+1)) 0 j = a * (M ^ n) 0 j + b * (M ^ n) 1 j ∧
      (M ^ (n+1)) 1 j = c * (M ^ n) 0 j + d * (M ^ n) 1 j := by
    intro n j
    rw [pow_succ']
    simp [Matrix.mul_apply, Fin.sum_univ_two, ha, hb, hc, hd]
  refine ⟨fun ht => ?_, fun ht => ?_⟩
  · set t := a + d with htdef
    have ht2 : 0 < 4 - t ^ 2 := by
      have := abs_lt.mp ht; nlinarith
    let Q : ℝ → ℝ → ℝ := fun x y => 2*c*x^2 + 2*(d-a)*x*y - 2*b*y^2
    have hinv : ∀ n : ℕ, ∀ j : Fin 2,
        Q ((M ^ n) 0 j) ((M ^ n) 1 j) = Q ((1 : Matrix (Fin 2) (Fin 2) ℝ) 0 j)
          ((1 : Matrix (Fin 2) (Fin 2) ℝ) 1 j) := by
      intro n j
      induction n with
      | zero => simp
      | succ n ih =>
        rw [← ih, (hstep n j).1, (hstep n j).2]
        simp only [Q]
        linear_combination (2*c*((M ^ n) 0 j)^2 + 2*(d-a)*((M ^ n) 0 j)*((M ^ n) 1 j)
          - 2*b*((M ^ n) 1 j)^2) * hdet
    have hQ : ∀ j : Fin 2, |Q ((1 : Matrix (Fin 2) (Fin 2) ℝ) 0 j)
          ((1 : Matrix (Fin 2) (Fin 2) ℝ) 1 j)| ≤ |2*c| + |2*b| := by
      intro j
      fin_cases j <;> simp [Q, abs_mul, Matrix.one_apply]
    set K := (|2*c| + |2*b|) ^ 2 / (4 - t ^ 2)
    refine ⟨Real.sqrt K, fun n i j => ?_⟩
    apply Real.abs_le_sqrt
    rw [le_div_iff₀ ht2]
    have hq := hinv n j
    have hqb := hQ j
    set x := (M ^ n) 0 j
    set y := (M ^ n) 1 j
    set q := Q ((1 : Matrix (Fin 2) (Fin 2) ℝ) 0 j) ((1 : Matrix (Fin 2) (Fin 2) ℝ) 1 j)
    simp only [Q] at hq
    have hb' : |2*b| * |q| ≤ (|2*c| + |2*b|) ^ 2 := by
      have := abs_nonneg (2*c); have := abs_nonneg (2*b); have := abs_nonneg q; nlinarith
    have hc' : |2*c| * |q| ≤ (|2*c| + |2*b|) ^ 2 := by
      have := abs_nonneg (2*c); have := abs_nonneg (2*b); have := abs_nonneg q; nlinarith
    have e1 : -2*b*q ≤ |2*b| * |q| := by
      have := neg_le_abs (2*b*q); rw [abs_mul] at this; linarith
    have e2 : 2*c*q ≤ |2*c| * |q| := by
      rw [← abs_mul]; exact le_abs_self _
    -- identities
    have id1 : -2*b*q = ((d-a)*x - 2*b*y)^2 + (4 - t^2) * x^2 := by
      rw [← hq, htdef]; linear_combination (4*x^2) * hdet
    have id2 : 2*c*q = (2*c*x + (d-a)*y)^2 + (4 - t^2) * y^2 := by
      rw [← hq, htdef]; linear_combination (4*y^2) * hdet
    fin_cases i
    · show x ^ 2 * (4 - t^2) ≤ _
      nlinarith [sq_nonneg ((d-a)*x - 2*b*y)]
    · show y ^ 2 * (4 - t^2) ≤ _
      nlinarith [sq_nonneg (2*c*x + (d-a)*y)]
  · suffices h : ∃ μ : ℝ, ∃ v : Fin 2 → ℝ, v ≠ 0 ∧ 1 < |μ| ∧ M *ᵥ v = μ • v by
      obtain ⟨μ, v, hv, hμ, hMv⟩ := h
      refine ⟨μ, v, hv, hμ, fun n => ?_⟩
      induction n with
      | zero => simp
      | succ n ih =>
        rw [pow_succ, ← Matrix.mulVec_mulVec, hMv, Matrix.mulVec_smul, ih, smul_smul, ← pow_succ']
    by_cases hb0 : b = 0
    · have had : a * d = 1 := by rw [hb0] at hdet; linarith
      by_cases ha1 : 1 < |a|
      · have hne : a - d ≠ 0 := by
          intro h
          have hda : d = a := by linarith
          rw [hda] at had ht
          have h1 : |a| = 1 := by
            have : |a| ^ 2 = 1 := by rw [sq_abs]; nlinarith
            nlinarith [abs_nonneg a]
          linarith
        refine ⟨a, ![a - d, c], ?_, ha1, ?_⟩
        · intro h
          have := congrFun h 0
          simp at this
          exact hne (by linarith)
        · ext i
          fin_cases i
          · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, ← ha, ← hb, hb0]
          · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, ← hc, ← hd]
            ring
      · rw [not_lt] at ha1
        have hd1 : 1 < |d| := by
          by_contra hcon
          rw [not_lt] at hcon
          have := abs_add_le a d
          linarith
        refine ⟨d, ![0, 1], ?_, hd1, ?_⟩
        · intro h
          have := congrFun h 1
          simp at this
        · ext i
          fin_cases i
          · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, ← hb, hb0]
          · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, ← hd]
    · have hμ : ∃ μ : ℝ, μ ^ 2 - (a + d) * μ + 1 = 0 ∧ 1 < |μ| := by
        have h4 : 0 ≤ (a + d) ^ 2 - 4 := by
          have := sq_abs (a + d)
          nlinarith [abs_nonneg (a + d)]
        have hs := Real.sq_sqrt h4
        have hs0 := Real.sqrt_nonneg ((a + d) ^ 2 - 4)
        rcases lt_abs.mp ht with h | h
        · refine ⟨((a + d) + Real.sqrt ((a + d) ^ 2 - 4)) / 2, ?_, ?_⟩
          · nlinarith
          · rw [lt_abs]; left; linarith
        · refine ⟨((a + d) - Real.sqrt ((a + d) ^ 2 - 4)) / 2, ?_, ?_⟩
          · nlinarith
          · rw [lt_abs]; right; linarith
      obtain ⟨μ, hμq, hμ1⟩ := hμ
      refine ⟨μ, ![b, μ - a], ?_, hμ1, ?_⟩
      · intro h
        have := congrFun h 0
        simp at this
        exact hb0 this
      · ext i
        fin_cases i
        · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, ← ha, ← hb]
          ring
        · simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, ← hc, ← hd]
          linear_combination (-1 : ℝ) * hμq - hdet

/-- Abel's identity for Hill's equation x'' + q(t) x = 0. Take the solution x₁ starting at
position 1, speed 0 and the solution x₂ starting at position 0, speed 1 (velocities v₁, v₂).
The fundamental matrix Φ(t), with these two solutions as its columns, has determinant 1 at
every time; in particular the period matrix M = Φ(T) has determinant 1. -/
theorem hill_fundamental_matrix_det_eq_one (q x₁ v₁ x₂ v₂ : ℝ → ℝ)
    (hx₁ : ∀ t, HasDerivAt x₁ (v₁ t) t) (hv₁ : ∀ t, HasDerivAt v₁ (-(q t * x₁ t)) t)
    (hx₂ : ∀ t, HasDerivAt x₂ (v₂ t) t) (hv₂ : ∀ t, HasDerivAt v₂ (-(q t * x₂ t)) t)
    (h₁ : x₁ 0 = 1 ∧ v₁ 0 = 0) (h₂ : x₂ 0 = 0 ∧ v₂ 0 = 1) :
    ∀ t, (!![x₁ t, x₂ t; v₁ t, v₂ t] : Matrix (Fin 2) (Fin 2) ℝ).det = 1 := by
  intro t
  rw [Matrix.det_fin_two_of]
  let W : ℝ → ℝ := fun s => x₁ s * v₂ s - x₂ s * v₁ s
  have hW : ∀ s, HasDerivAt W 0 s := by
    intro s
    have := ((hx₁ s).mul (hv₂ s)).sub ((hx₂ s).mul (hv₁ s))
    convert this using 1
    ring
  have hdW : Differentiable ℝ W := fun s => (hW s).differentiableAt
  have := is_const_of_deriv_eq_zero hdW (fun s => (hW s).deriv) t 0
  simp only [W] at this
  rw [this, h₁.1, h₁.2, h₂.1, h₂.2]
  ring

/-- The periodic lens (Floquet form). If the fundamental matrix satisfies
Φ(t + T) = Φ(t) M and B is a constant matrix with e^{BT} = M, then P(t) = Φ(t) e^{-Bt}
repeats every period T, and Φ(t) = P(t) e^{Bt}. -/
theorem floquet_periodic_factor {n : Type*} [Fintype n] [DecidableEq n]
    (Φ : ℝ → Matrix n n ℝ) (M B : Matrix n n ℝ) (T : ℝ)
    (hshift : ∀ t, Φ (t + T) = Φ t * M) (hB : NormedSpace.exp (T • B) = M) :
    (∀ t, Φ (t + T) * NormedSpace.exp (-((t + T) • B)) = Φ t * NormedSpace.exp (-(t • B))) ∧
    (∀ t, Φ t = (Φ t * NormedSpace.exp (-(t • B))) * NormedSpace.exp (t • B)) := by
  have hc : ∀ s r : ℝ, Commute (s • B) (r • B) := fun s r =>
    ((Commute.refl B).smul_left s).smul_right r
  constructor
  · intro t
    rw [hshift, show -((t + T) • B) = -(T • B) + -(t • B) by rw [add_smul]; abel,
      Matrix.exp_add_of_commute _ _ ((hc T t).neg_left.neg_right), ← hB, mul_assoc (Φ t),
      ← mul_assoc (NormedSpace.exp (T • B)),
      ← Matrix.exp_add_of_commute _ _ (hc T T).neg_right, add_neg_cancel, NormedSpace.exp_zero,
      one_mul]
  · intro t
    rw [mul_assoc, ← Matrix.exp_add_of_commute _ _ (hc t t).neg_left, neg_add_cancel,
      NormedSpace.exp_zero, mul_one]

/-- With no pump at average stiffness 1/4, the period matrix over 2π is -I:
trace -2 and determinant 1, on the edge of the trace test. -/
example : (-1 : Matrix (Fin 2) (Fin 2) ℝ).trace = -2 ∧ (-1 : Matrix (Fin 2) (Fin 2) ℝ).det = 1 := by
  norm_num [Matrix.trace_fin_two, Matrix.det_fin_two]

#print axioms trace_test_bounded_or_grows
#print axioms hill_fundamental_matrix_det_eq_one
#print axioms floquet_periodic_factor
