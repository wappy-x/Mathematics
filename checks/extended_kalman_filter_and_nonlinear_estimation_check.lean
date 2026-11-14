-- Filtering a nonlinear plant: the average of sin θ over a normal belief is e^(-σ²/2) sin μ, not the tangent's sin μ, while the five unscented sample points reproduce a linear step's mean and covariance exactly and a normal law's averages of every polynomial in the angle up to degree four.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Polynomial.Degree.Defs
import Mathlib.Algebra.Polynomial.Eval.Degree
import Mathlib.Algebra.Polynomial.Degree.Lemmas

open MeasureTheory ProbabilityTheory Matrix
open scoped NNReal

/-- The card's five sigma points for a two-state belief with centre `x` and a square root `L`
of its covariance: the centre, then the centre plus and minus `√3` times each column of `L`. -/
noncomputable def sigmaPoints (x : Fin 2 → ℝ) (L : Matrix (Fin 2) (Fin 2) ℝ) : Fin 5 → Fin 2 → ℝ :=
  ![x,
    x + Real.sqrt 3 • (fun j => L j 0),
    x - Real.sqrt 3 • (fun j => L j 0),
    x + Real.sqrt 3 • (fun j => L j 1),
    x - Real.sqrt 3 • (fun j => L j 1)]

/-- The card's sigma-point weights: 1/3 on the centre, 1/6 on each of the other four. -/
noncomputable def sigmaWeights : Fin 5 → ℝ :=
  ![1 / 3, 1 / 6, 1 / 6, 1 / 6, 1 / 6]

lemma mgf_aux_hasDeriv (v t : ℝ) : HasDerivAt (fun t => Real.exp (v * t ^ 2 / 2))
    (v * t * Real.exp (v * t ^ 2 / 2)) t := by
  have h : HasDerivAt (fun t : ℝ => v * t ^ 2 / 2) (v * t) t := by
    have := ((hasDerivAt_pow 2 t).const_mul v).div_const 2
    convert this using 1; ring
  exact ((Real.hasDerivAt_exp _).comp t h).congr_deriv (by ring)

lemma gauss_moments (v : ℝ≥0) :
    ∫ x, x ^ 1 ∂gaussianReal 0 v = 0 ∧ ∫ x, x ^ 2 ∂gaussianReal 0 v = v ∧
    ∫ x, x ^ 3 ∂gaussianReal 0 v = 0 ∧ ∫ x, x ^ 4 ∂gaussianReal 0 v = 3 * (v : ℝ) ^ 2 := by
  have hm : ∀ n : ℕ, ∫ x, x ^ n ∂gaussianReal 0 v
      = iteratedDeriv n (fun t => Real.exp (v * t ^ 2 / 2)) 0 := by
    intro n
    have := iteratedDeriv_mgf_zero (X := fun x : ℝ => x) (μ := gaussianReal 0 v) (by simp) n
    rw [mgf_fun_id_gaussianReal] at this
    simp only [zero_mul, zero_add] at this
    rw [this]; rfl
  set f : ℝ → ℝ := fun t => Real.exp (v * t ^ 2 / 2) with hf
  have d1 : deriv f = fun t => v * t * f t := by
    funext t; exact (mgf_aux_hasDeriv v t).deriv
  have d2 : deriv (fun t => v * t * f t) = fun t => (v + v ^ 2 * t ^ 2) * f t := by
    funext t
    have h : HasDerivAt (fun t => v * t * f t) ((v + v ^ 2 * t ^ 2) * f t) t :=
      (((hasDerivAt_id t).const_mul (v:ℝ)).mul (mgf_aux_hasDeriv v t)).congr_deriv
        (by simp [f]; ring)
    exact h.deriv
  have d3 : deriv (fun t => (v + v ^ 2 * t ^ 2) * f t)
      = fun t => (3 * v ^ 2 * t + v ^ 3 * t ^ 3) * f t := by
    funext t
    have h : HasDerivAt (fun t => (v + v ^ 2 * t ^ 2) * f t)
        ((3 * v ^ 2 * t + v ^ 3 * t ^ 3) * f t) t :=
      ((((hasDerivAt_pow 2 t).const_mul ((v:ℝ)^2)).const_add (v:ℝ)).mul
        (mgf_aux_hasDeriv v t)).congr_deriv (by simp [f]; ring)
    exact h.deriv
  have d4 : deriv (fun t => (3 * v ^ 2 * t + v ^ 3 * t ^ 3) * f t) 0 = 3 * (v:ℝ) ^ 2 := by
    have h : HasDerivAt (fun t => (3 * v ^ 2 * t + v ^ 3 * t ^ 3) * f t) (3 * (v:ℝ) ^ 2) 0 :=
      ((((hasDerivAt_id (0:ℝ)).const_mul (3 * (v:ℝ)^2)).add
        ((hasDerivAt_pow 3 (0:ℝ)).const_mul ((v:ℝ)^3)))).mul
        (mgf_aux_hasDeriv v 0) |>.congr_deriv (by simp)
    exact h.deriv
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [hm, iteratedDeriv_one, d1]; simp
  · rw [hm, iteratedDeriv_succ, iteratedDeriv_one, d1, d2]; simp [f]
  · rw [hm, iteratedDeriv_succ, iteratedDeriv_succ, iteratedDeriv_one, d1, d2, d3]; simp
  · rw [hm, iteratedDeriv_succ, iteratedDeriv_succ, iteratedDeriv_succ, iteratedDeriv_one,
      d1, d2, d3, d4]

/-- What any tangent misses: if the angle `θ` has a normal law with centre `μ` and standard
deviation `σ`, then the average of `sin θ` is `e^(-σ²/2) sin μ`, not the tangent's `sin μ`. -/
theorem integral_sin_gaussianReal (μ : ℝ) (σ : ℝ≥0) :
    ∫ θ, Real.sin θ ∂(gaussianReal μ (σ ^ 2)) = Real.exp (-(σ : ℝ) ^ 2 / 2) * Real.sin μ := by
  have h := complexMGF_id_gaussianReal (μ := μ) (v := σ ^ 2) Complex.I
  unfold complexMGF at h
  have hint : Integrable (fun x : ℝ => Complex.exp (Complex.I * (id x : ℝ))) (gaussianReal μ (σ ^ 2)) := by
    refine Integrable.of_bound (C := 1) (by fun_prop) (Filter.Eventually.of_forall fun x => ?_)
    rw [mul_comm]; simp [Complex.norm_exp_ofReal_mul_I]
  have h3 : ∫ x, (Complex.exp (Complex.I * (id x : ℝ))).im ∂(gaussianReal μ (σ ^ 2))
      = (∫ x, Complex.exp (Complex.I * (id x : ℝ)) ∂(gaussianReal μ (σ ^ 2))).im :=
    integral_im hint
  have e1 : ∀ x : ℝ, (Complex.exp (Complex.I * (id x : ℝ))).im = Real.sin x := by
    intro x; rw [mul_comm]; simp [Complex.exp_ofReal_mul_I_im]
  simp_rw [e1] at h3
  have hc : (((σ ^ 2 : ℝ≥0) : ℝ) : ℂ) = (((σ : ℝ) ^ 2 : ℝ) : ℂ) := by push_cast; rfl
  rw [h3, h, hc, Complex.exp_im]
  set s : ℝ := (σ : ℝ) ^ 2 with hs
  have hre : (Complex.I * (μ : ℂ) + (s : ℂ) * Complex.I ^ 2 / 2).re = -s / 2 := by
    simp [Complex.I_sq]
  have him : (Complex.I * (μ : ℂ) + (s : ℂ) * Complex.I ^ 2 / 2).im = μ := by
    simp [Complex.I_sq]
  rw [hre, him]

/-- For a linear (affine) step `z ↦ F z + b`, the unscented filter is the Kalman filter:
pushing the five sigma points of a belief with centre `x` and covariance `P = L Lᵀ` through
the step and refitting with the weights 1/3, 1/6, 1/6, 1/6, 1/6 gives mean `F x + b` and
covariance `F P Fᵀ` exactly. -/
theorem unscented_exact_for_linear_step (x b : Fin 2 → ℝ) (F L P : Matrix (Fin 2) (Fin 2) ℝ)
    (hL : L * Lᵀ = P) :
    let y : Fin 5 → Fin 2 → ℝ := fun m => F *ᵥ sigmaPoints x L m + b
    let ybar : Fin 2 → ℝ := ∑ m, sigmaWeights m • y m
    ybar = F *ᵥ x + b ∧
      ∑ m, sigmaWeights m • vecMulVec (y m - ybar) (y m - ybar) = F * P * Fᵀ := by
  intro y ybar
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hbar : ybar = F *ᵥ x + b := by
    funext i
    simp only [ybar, y, Fin.sum_univ_five, sigmaPoints, sigmaWeights]
    simp [mulVec, dotProduct, Fin.sum_univ_two]
    ring
  refine ⟨hbar, ?_⟩
  rw [hbar, ← hL]
  ext i j
  simp only [y, Fin.sum_univ_five, sigmaPoints, sigmaWeights]
  fin_cases i <;> fin_cases j <;>
    simp [mulVec, dotProduct, Fin.sum_univ_two, vecMulVec_apply, Matrix.mul_apply] <;>
    ring_nf <;> rw [h3] <;> ring

/-- For a function of the angle alone, the unscented mean is right through the fourth-order
term: for every polynomial `p` of degree at most 4, the weighted average of `p` over the
sigma points' angles (`μ` with total weight 2/3, `μ ± √3 σ` with weight 1/6 each) equals the
average of `p θ` when `θ` has a normal law with centre `μ` and standard deviation `σ`. -/
theorem unscented_mean_exact_degree_le_four (p : Polynomial ℝ) (hp : p.natDegree ≤ 4)
    (μ : ℝ) (σ : ℝ≥0) :
    (2 / 3) * p.eval μ + (1 / 6) * p.eval (μ + Real.sqrt 3 * σ)
        + (1 / 6) * p.eval (μ - Real.sqrt 3 * σ)
      = ∫ θ, p.eval θ ∂(gaussianReal μ (σ ^ 2)) := by
  set q : Polynomial ℝ := p.comp (Polynomial.X + Polynomial.C μ) with hq
  have hqe : ∀ x, q.eval x = p.eval (x + μ) := by intro x; simp [q]
  have hqd : q.natDegree < 5 := by
    have hc := Polynomial.natDegree_comp_le (p := p) (q := Polynomial.X + Polynomial.C μ)
    have h1 : (Polynomial.X + Polynomial.C μ).natDegree ≤ 1 := by
      exact (Polynomial.natDegree_add_le _ _).trans (by simp)
    have hm : p.natDegree * (Polynomial.X + Polynomial.C μ).natDegree ≤ 4 :=
      (Nat.mul_le_mul hp h1).trans (by norm_num)
    rw [hq]; omega
  have hshift : ∫ θ, p.eval θ ∂(gaussianReal μ (σ ^ 2))
      = ∫ x, q.eval x ∂(gaussianReal 0 (σ ^ 2)) := by
    have hmap : (gaussianReal 0 (σ ^ 2)).map (fun x => x + μ) = gaussianReal μ (σ ^ 2) := by
      rw [gaussianReal_map_add_const]; simp
    rw [← hmap, integral_map (by fun_prop) (by fun_prop)]
    simp [hqe]
  have hev : ∀ x, q.eval x = q.coeff 0 + q.coeff 1 * x ^ 1 + q.coeff 2 * x ^ 2
      + q.coeff 3 * x ^ 3 + q.coeff 4 * x ^ 4 := by
    intro x
    rw [Polynomial.eval_eq_sum_range' hqd]
    simp [Finset.sum_range_succ]
  have hI : ∀ n : ℕ, Integrable (fun x : ℝ => x ^ n) (gaussianReal 0 (σ ^ 2)) := fun n =>
    integrable_pow_of_mem_interior_integrableExpSet (X := fun x : ℝ => x) (by simp) n
  obtain ⟨m1, m2, m3, m4⟩ := gauss_moments (σ ^ 2)
  have hR : ∫ x, q.eval x ∂(gaussianReal 0 (σ ^ 2))
      = q.coeff 0 + q.coeff 2 * (σ : ℝ) ^ 2 + q.coeff 4 * (3 * (σ : ℝ) ^ 4) := by
    simp_rw [hev]
    rw [integral_add (by fun_prop) ((hI 4).const_mul _), integral_add (by fun_prop) ((hI 3).const_mul _),
      integral_add (by fun_prop) ((hI 2).const_mul _), integral_add (by fun_prop) ((hI 1).const_mul _)]
    rw [integral_const_mul, integral_const_mul, integral_const_mul, integral_const_mul,
      m1, m2, m3, m4, integral_const]
    simp only [probReal_univ, smul_eq_mul, one_mul]
    push_cast; ring
  rw [hshift, hR]
  have e0 : p.eval μ = q.eval 0 := by rw [hqe]; simp
  have e1 : p.eval (μ + Real.sqrt 3 * σ) = q.eval (Real.sqrt 3 * σ) := by rw [hqe]; ring_nf
  have e2 : p.eval (μ - Real.sqrt 3 * σ) = q.eval (-(Real.sqrt 3 * σ)) := by rw [hqe]; ring_nf
  rw [e0, e1, e2, hev, hev, hev]
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  ring_nf
  rw [show Real.sqrt 3 ^ 4 = (Real.sqrt 3 ^ 2) ^ 2 by ring, h3]
  ring

-- The pole length: g / l = 16 with g = 9.81 m/s² and l = 0.613125 m.
example : ((981 : ℚ) / 100) / (613125 / 1000000) = 16 := by norm_num

-- The five weights sum to 1.
example : (1 / 3 : ℚ) + 4 * (1 / 6) = 1 := by norm_num

-- Along the angle, the points' second moment is σ² (2 × 1/6 × 3) and their fourth is
-- 3 σ⁴ (2 × 1/6 × 9), both a normal law's.
example : (2 : ℚ) * (1 / 6) * 3 = 1 := by norm_num
example : (2 : ℚ) * (1 / 6) * 9 = 3 := by norm_num

-- The continuous slope A = [[0, 1], [κ, 0]] squares to κ I, at upright (κ = 16) and at the
-- bottom (κ = -16).
example : !![(0 : ℤ), 1; 16, 0] * !![(0 : ℤ), 1; 16, 0] = !![(16 : ℤ), 0; 0, 16] := by decide
example : !![(0 : ℤ), 1; -16, 0] * !![(0 : ℤ), 1; -16, 0] = !![(-16 : ℤ), 0; 0, -16] := by decide

#print axioms mgf_aux_hasDeriv
#print axioms gauss_moments
#print axioms integral_sin_gaussianReal
#print axioms unscented_exact_for_linear_step
#print axioms unscented_mean_exact_degree_le_four
