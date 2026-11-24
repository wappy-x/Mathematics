-- Global bifurcations: x = sech^2(t/2) is a homoclinic loop of x'' = x - 1.5x^2 that keeps the energy identity (x')^2 = x^2 - x^3, and the saddle of x' = y, y' = mu y + x - x^2 + xy has eigenvalues (mu ± sqrt(mu^2 + 4))/2, one positive and one negative, summing to mu.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation

open Real Filter Topology

lemma sechsq_hasDerivAt (t : ℝ) :
    HasDerivAt (fun t : ℝ => 1 / Real.cosh (t / 2) ^ 2)
      (-(Real.sinh (t / 2) / Real.cosh (t / 2) ^ 3)) t := by
  have hc : Real.cosh (t / 2) ≠ 0 := (Real.cosh_pos _).ne'
  have h1 : HasDerivAt (fun t : ℝ => t / 2) (1 / 2) t := by
    simpa using (hasDerivAt_id t).div_const 2
  have h2 := (h1.cosh).pow 2
  have h3 := h2.inv (pow_ne_zero 2 hc)
  have : (fun t : ℝ => 1 / Real.cosh (t / 2) ^ 2) = fun t => (Real.cosh (t / 2) ^ 2)⁻¹ := by
    funext s; simp
  rw [this]
  convert h3 using 1
  simp only [Pi.pow_apply]
  field_simp
  ring

lemma sechsq_deriv :
    deriv (fun t : ℝ => 1 / Real.cosh (t / 2) ^ 2) =
      fun t => -(Real.sinh (t / 2) / Real.cosh (t / 2) ^ 3) := by
  funext t; exact (sechsq_hasDerivAt t).deriv

lemma sechsq_hasDerivAt2 (t : ℝ) :
    HasDerivAt (fun t : ℝ => -(Real.sinh (t / 2) / Real.cosh (t / 2) ^ 3))
      (-((Real.cosh (t / 2) * (1 / 2) * Real.cosh (t / 2) ^ 3 -
        Real.sinh (t / 2) * (3 * Real.cosh (t / 2) ^ 2 * (Real.sinh (t / 2) * (1 / 2)))) /
        (Real.cosh (t / 2) ^ 3) ^ 2)) t := by
  have hc : Real.cosh (t / 2) ≠ 0 := (Real.cosh_pos _).ne'
  have h1 : HasDerivAt (fun t : ℝ => t / 2) (1 / 2) t := by
    simpa using (hasDerivAt_id t).div_const 2
  have h3 := ((h1.sinh).div ((h1.cosh).pow 3) (pow_ne_zero 3 hc)).neg
  convert h3 using 2

lemma sechsq_bound (t : ℝ) : 1 / Real.cosh (t / 2) ^ 2 ≤ 4 * Real.exp (-t) := by
  have hc := Real.cosh_pos (t / 2)
  rw [Real.cosh_eq]
  have e1 : Real.exp (t / 2) * Real.exp (-(t / 2)) = 1 := by
    rw [← Real.exp_add]; simp
  have e2 : Real.exp (-t) = Real.exp (-(t / 2)) ^ 2 := by
    rw [← Real.exp_nat_mul]; congr 1; ring
  have p1 := Real.exp_pos (t / 2)
  have p2 := Real.exp_pos (-(t / 2))
  rw [e2, div_le_iff₀ (by positivity)]
  nlinarith [sq_nonneg (Real.exp (-(t / 2))), mul_pos p1 p2, sq_nonneg (Real.exp (-(t / 2)) ^ 2)]

#print axioms sechsq_hasDerivAt
#print axioms sechsq_deriv
#print axioms sechsq_hasDerivAt2
#print axioms sechsq_bound

/-- The path x(t) = sech^2(t/2), written as 1 / cosh(t/2)^2, solves x'' = x - 1.5 x^2 at every
time, sits at the top x = 1 at t = 0, and tends to the saddle at 0 both as t runs forward and as
t runs backward: it is a homoclinic loop that leaves the saddle and returns to it. -/
theorem sech_sq_is_homoclinic_loop :
    let x : ℝ → ℝ := fun t => 1 / Real.cosh (t / 2) ^ 2
    (∀ t : ℝ, deriv (deriv x) t = x t - 3 / 2 * x t ^ 2) ∧
    x 0 = 1 ∧
    Tendsto x atTop (𝓝 0) ∧
    Tendsto x atBot (𝓝 0) := by
  intro x
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro t
    show deriv (deriv (fun t : ℝ => 1 / Real.cosh (t / 2) ^ 2)) t = _
    rw [sechsq_deriv, (sechsq_hasDerivAt2 t).deriv]
    have hc : Real.cosh (t / 2) ≠ 0 := (Real.cosh_pos _).ne'
    have hs : Real.sinh (t / 2) ^ 2 = Real.cosh (t / 2) ^ 2 - 1 := by
      rw [Real.cosh_sq]; ring
    simp only [x]
    field_simp
    rw [hs]
    ring
  · simp [x]
  · have hx : ∀ t, x t = 1 / Real.cosh (t / 2) ^ 2 := fun t => rfl
    have h4 : Tendsto (fun t : ℝ => 4 * Real.exp (-t)) atTop (𝓝 0) := by
      simpa using (Real.tendsto_exp_neg_atTop_nhds_zero).const_mul 4
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds h4 ?_ ?_
    · intro t; rw [hx]; positivity
    · intro t; rw [hx]; exact sechsq_bound t
  · have hx : ∀ t, x t = 1 / Real.cosh (t / 2) ^ 2 := fun t => rfl
    have h4 : Tendsto (fun t : ℝ => 4 * Real.exp t) atBot (𝓝 0) := by
      simpa using (Real.tendsto_exp_atBot).const_mul 4
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds h4 ?_ ?_
    · intro t; rw [hx]; positivity
    · intro t
      rw [hx]
      have := sechsq_bound (-t)
      rw [neg_neg, neg_div, Real.cosh_neg] at this
      exact this

/-- Along the loop x(t) = sech^2(t/2) the energy identity (x')^2 = x^2 - x^3 holds at every
time. -/
theorem sech_sq_loop_energy_identity :
    let x : ℝ → ℝ := fun t => 1 / Real.cosh (t / 2) ^ 2
    ∀ t : ℝ, deriv x t ^ 2 = x t ^ 2 - x t ^ 3 := by
  intro x t
  show deriv (fun t : ℝ => 1 / Real.cosh (t / 2) ^ 2) t ^ 2 = _
  rw [sechsq_deriv]
  have hc : Real.cosh (t / 2) ≠ 0 := (Real.cosh_pos _).ne'
  have hs : Real.sinh (t / 2) ^ 2 = Real.cosh (t / 2) ^ 2 - 1 := by
    rw [Real.cosh_sq]; ring
  simp only [x]
  field_simp
  rw [hs]

/-- For every dial value mu, the Jacobian of x' = y, y' = mu y + x - x^2 + xy at the rest
(0, 0) is the table [[0, 1], [1, mu]]. Its eigenvalues are (mu + sqrt(mu^2 + 4))/2 and
(mu - sqrt(mu^2 + 4))/2: the first is positive (the way out), the second negative (the way in),
so (0, 0) is a true saddle, and their sum is mu, the trace. -/
theorem saddle_eigenvalues_real_opposite_sign_sum_mu (μ : ℝ) :
    let J : Matrix (Fin 2) (Fin 2) ℝ := !![0, 1; 1, μ]
    let lu := (μ + Real.sqrt (μ ^ 2 + 4)) / 2
    let ls := (μ - Real.sqrt (μ ^ 2 + 4)) / 2
    (lu • (1 : Matrix (Fin 2) (Fin 2) ℝ) - J).det = 0 ∧
    (ls • (1 : Matrix (Fin 2) (Fin 2) ℝ) - J).det = 0 ∧
    0 < lu ∧ ls < 0 ∧ lu + ls = μ := by
  intro J lu ls
  have hpos : (0:ℝ) ≤ μ ^ 2 + 4 := by positivity
  have hsq := Real.sq_sqrt hpos
  have hgt : |μ| < Real.sqrt (μ ^ 2 + 4) := by
    rw [← Real.sqrt_sq_eq_abs]
    exact Real.sqrt_lt_sqrt (sq_nonneg _) (by linarith)
  have ha := abs_lt.mp hgt
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simp only [J, lu, Matrix.det_fin_two]
    simp [Matrix.smul_apply]
    nlinarith [hsq]
  · simp only [J, ls, Matrix.det_fin_two]
    simp [Matrix.smul_apply]
    nlinarith [hsq]
  · simp only [lu]; linarith [ha.1, ha.2, le_abs_self μ, neg_abs_le μ]
  · simp only [ls]; linarith [ha.1, ha.2, le_abs_self μ, neg_abs_le μ]
  · simp only [lu, ls]; ring

#print axioms sech_sq_is_homoclinic_loop
#print axioms sech_sq_loop_energy_identity
#print axioms saddle_eigenvalues_real_opposite_sign_sum_mu
