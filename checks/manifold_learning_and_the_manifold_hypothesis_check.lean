-- Manifold learning: classical scaling turns centred squared distances between points in a plane back into their dot products, the table has at most two nonzero eigenvalues, and the spiral's length from angle 0 to t has the closed form ½(t√(t²+1) + ln(t + √(t²+1))).
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open Real

/-- Classical scaling: for points y₁, …, yₙ in a plane whose average is the origin, write
D_ij = |y_i − y_j|², r̄_i for the average of row i of D, and ḡ for the average of the whole
table. Then B_ij = −½(D_ij − r̄_i − r̄_j + ḡ) is exactly the dot product y_i · y_j. -/
theorem centred_squared_distances_give_dot_products {n : ℕ}
    (y : Fin n → EuclideanSpace ℝ (Fin 2)) (hcentre : ∑ i, y i = 0) (i j : Fin n) :
    let D : Fin n → Fin n → ℝ := fun a b => ‖y a - y b‖ ^ 2;
    let r : Fin n → ℝ := fun a => (∑ b, D a b) / n;
    let g : ℝ := (∑ a, r a) / n;
    -(1 / 2 : ℝ) * (D i j - r i - r j + g) = inner ℝ (y i) (y j) := by
  intro D r g
  have hn : (n : ℝ) ≠ 0 := by
    have : 0 < n := Fin.pos i
    exact_mod_cast this.ne'
  set S : ℝ := ∑ b, ‖y b‖ ^ 2 with hS
  have hinner : ∀ a, ∑ b, inner ℝ (y a) (y b) = 0 := by
    intro a
    rw [← inner_sum, hcentre, inner_zero_right]
  have hr : ∀ a, r a = ‖y a‖ ^ 2 + S / n := by
    intro a
    simp only [r, D, norm_sub_sq_real, Finset.sum_add_distrib, Finset.sum_sub_distrib,
      ← Finset.mul_sum, hinner, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul]
    field_simp
    ring
  have hg : g = 2 * S / n := by
    simp only [g, hr, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul]
    rw [← hS]
    field_simp
    ring
  rw [hg, hr i, hr j]
  simp only [D, norm_sub_sq_real]
  field_simp
  ring

/-- A table of dot products of points in a plane, B_ij = y_i · y_j, has at most two
eigenvalues that are not 0. -/
theorem dot_product_table_has_at_most_two_nonzero_eigenvalues {n : ℕ}
    (y : Fin n → EuclideanSpace ℝ (Fin 2))
    (hB : (Matrix.of fun i j => inner ℝ (y i) (y j) : Matrix (Fin n) (Fin n) ℝ).IsHermitian) :
    (Finset.univ.filter fun k => hB.eigenvalues k ≠ 0).card ≤ 2 := by
  rw [← Fintype.card_subtype, ← hB.rank_eq_card_non_zero_eigs]
  set Y : Matrix (Fin n) (Fin 2) ℝ := Matrix.of fun i k => y i k
  have hEq : (Matrix.of fun i j => inner ℝ (y i) (y j) : Matrix (Fin n) (Fin n) ℝ) =
      Y * Y.transpose := by
    ext a b
    simp [Y, Matrix.mul_apply, PiLp.inner_apply, mul_comm]
  rw [hEq]
  exact (Matrix.rank_mul_le_left _ _).trans (Matrix.rank_le_width _)

/-- The length of the spiral (t cos t, t sin t) from angle 0 to angle t: its speed is
√(u² + 1), and adding up the speed gives ½(t√(t²+1) + ln(t + √(t²+1))). -/
theorem spiral_arc_length (t : ℝ) :
    ∫ u in (0 : ℝ)..t,
        √((deriv (fun v => v * cos v) u) ^ 2 + (deriv (fun v => v * sin v) u) ^ 2) =
      (1 / 2 : ℝ) * (t * √(t ^ 2 + 1) + log (t + √(t ^ 2 + 1))) := by
  have hd1 : ∀ u, deriv (fun v => v * cos v) u = cos u - u * sin u := by
    intro u
    have h : HasDerivAt (fun v => v * cos v) (1 * cos u + u * -sin u) u :=
      (hasDerivAt_id' u).mul (hasDerivAt_cos u)
    rw [h.deriv]; ring
  have hd2 : ∀ u, deriv (fun v => v * sin v) u = sin u + u * cos u := by
    intro u
    have h : HasDerivAt (fun v => v * sin v) (1 * sin u + u * cos u) u :=
      (hasDerivAt_id' u).mul (hasDerivAt_sin u)
    rw [h.deriv]; ring
  have hint : ∀ u, √((deriv (fun v => v * cos v) u) ^ 2 + (deriv (fun v => v * sin v) u) ^ 2)
      = √(u ^ 2 + 1) := by
    intro u
    rw [hd1, hd2]
    congr 1
    have := sin_sq_add_cos_sq u
    nlinarith [this]
  simp_rw [hint]
  have hpos : ∀ u : ℝ, 0 < √(u ^ 2 + 1) := fun u => Real.sqrt_pos.mpr (by positivity)
  have hgt : ∀ u : ℝ, 0 < u + √(u ^ 2 + 1) := by
    intro u
    have h1 : |u| < √(u ^ 2 + 1) := by
      rw [← Real.sqrt_sq_eq_abs]
      exact Real.sqrt_lt_sqrt (sq_nonneg _) (by linarith)
    linarith [neg_abs_le u]
  have hderiv : ∀ x ∈ Set.uIcc (0:ℝ) t,
      HasDerivAt (fun u : ℝ => (1 / 2 : ℝ) * (u * √(u ^ 2 + 1) + log (u + √(u ^ 2 + 1))))
        (√(x ^ 2 + 1)) x := by
    intro x _
    have hs : HasDerivAt (fun u : ℝ => √(u ^ 2 + 1)) (x / √(x ^ 2 + 1)) x := by
      have h := ((hasDerivAt_pow 2 x).add_const 1).sqrt (by positivity)
      convert h using 1
      field_simp
      ring
    have h := ((((hasDerivAt_id' x).mul hs).add (((hasDerivAt_id' x).add hs).log
      (hgt x).ne'))).const_mul (1 / 2 : ℝ)
    convert h using 1
    have h0 := (hpos x).ne'
    have h1 := (hgt x).ne'
    have hsq : √(x ^ 2 + 1) ^ 2 = x ^ 2 + 1 := Real.sq_sqrt (by positivity)
    have key : (1 + x / √(x ^ 2 + 1)) / (x + √(x ^ 2 + 1)) = 1 / √(x ^ 2 + 1) := by
      rw [div_eq_div_iff h1 h0]
      field_simp
      ring
    simp only [Pi.add_apply]
    rw [key]
    field_simp
    nlinarith [hsq]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv]
  · simp
  · exact (by fun_prop : Continuous fun u : ℝ => √(u ^ 2 + 1)).intervalIntegrable _ _

-- Photos A and B: lamp angles 3π/2 and 7π/2, one turn apart, so their spiral radii differ by 2π.
example : 7 * π / 2 - 3 * π / 2 = 2 * π := by ring
-- A 6 × 4 thumbnail has 24 pixels.
example : 6 * 4 = 24 := by norm_num
-- The 13 probe photos, every 45°, run from 270° to 810°: one and a half turns.
example : 270 + 45 * 12 = 810 := by norm_num
example : ((810 - 270 : ℚ)) / 360 = 3 / 2 := by norm_num
-- A and B, at 270° and 630°, are one full turn apart.
example : 630 - 270 = 360 := by norm_num

#print axioms centred_squared_distances_give_dot_products
#print axioms dot_product_table_has_at_most_two_nonzero_eigenvalues
#print axioms spiral_arc_length
