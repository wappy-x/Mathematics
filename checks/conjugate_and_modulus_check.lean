-- Conjugate and modulus: a complex number times its conjugate is its squared length, which gives the modulus, division by a nonzero number, and the product and triangle rules for lengths.
import Mathlib.Analysis.Complex.Norm

open Complex ComplexConjugate

/-- For every complex number z = a + bi, the conjugate z-bar = a - bi flips the sign of the
imaginary part, z times z-bar is the real number a² + b², the modulus |z| is √(a² + b²),
and so z times z-bar is |z|², the squared distance from 0 to z. -/
theorem mul_conj_eq_sq_modulus (z : ℂ) :
    conj z = (z.re : ℂ) - (z.im : ℂ) * I ∧
    z * conj z = ((z.re ^ 2 + z.im ^ 2 : ℝ) : ℂ) ∧
    ‖z‖ = Real.sqrt (z.re ^ 2 + z.im ^ 2) ∧
    z * conj z = ((‖z‖ ^ 2 : ℝ) : ℂ) := by
  refine ⟨?_, ?_, Complex.norm_eq_sqrt_sq_add_sq z, ?_⟩
  · apply Complex.ext <;> simp
  · rw [Complex.mul_conj, Complex.normSq_apply]; push_cast; ring
  · rw [Complex.mul_conj, Complex.normSq_eq_norm_sq]

/-- To divide p by a nonzero complex number z, multiply by z-bar and divide by the real
number |z|²: p / z = p z-bar / |z|². -/
theorem div_eq_mul_conj_div_sq_modulus (p z : ℂ) (hz : z ≠ 0) :
    p / z = p * conj z / ((‖z‖ ^ 2 : ℝ) : ℂ) := by
  have h : ((‖z‖ ^ 2 : ℝ) : ℂ) = z * conj z := by
    rw [Complex.mul_conj, Complex.normSq_eq_norm_sq]
  have hc : conj z ≠ 0 := by simpa using hz
  rw [h]; field_simp

/-- Lengths multiply, |zw| = |z||w|; the length of a sum is at most the sum of the lengths,
|z + w| ≤ |z| + |w| (the triangle inequality); and two distances from 0 differ by at most
the distance between the points, ||z| - |w|| ≤ |z - w| (the reverse triangle inequality). -/
theorem modulus_mul_and_triangle (z w : ℂ) :
    ‖z * w‖ = ‖z‖ * ‖w‖ ∧
    ‖z + w‖ ≤ ‖z‖ + ‖w‖ ∧
    |‖z‖ - ‖w‖| ≤ ‖z - w‖ := by
  exact ⟨Complex.norm_mul z w, norm_add_le z w, abs_norm_sub_norm_le z w⟩

-- The drone times its flip: (3 + 4i)(3 - 4i) = 25.
example : ((3 : ℂ) + 4 * I) * conj ((3 : ℂ) + 4 * I) = 25 := by
  apply Complex.ext <;> simp <;> norm_num

-- The drone is 5 km from the depot: |3 + 4i| = 5.
example : ‖(3 : ℂ) + 4 * I‖ = 5 := by
  rw [Complex.norm_eq_sqrt_sq_add_sq]
  simp
  rw [show (3:ℝ) ^ 2 + 4 ^ 2 = 5 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]

-- The beacon times the flip: (1 + 2i)(3 - 4i) = 11 + 2i.
example : ((1 : ℂ) + 2 * I) * conj ((3 : ℂ) + 4 * I) = 11 + 2 * I := by
  apply Complex.ext <;> simp <;> norm_num

-- The quotient: (1 + 2i)/(3 + 4i) = (11 + 2i)/25.
example : ((1 : ℂ) + 2 * I) / ((3 : ℂ) + 4 * I) = (11 + 2 * I) / 25 := by
  have h : (3 : ℂ) + 4 * I ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  rw [div_eq_div_iff h (by norm_num)]
  apply Complex.ext <;> simp <;> norm_num

-- The reciprocal: 1/(3 + 4i) = (3 - 4i)/25.
example : (1 : ℂ) / ((3 : ℂ) + 4 * I) = (3 - 4 * I) / 25 := by
  have h : (3 : ℂ) + 4 * I ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  rw [div_eq_div_iff h (by norm_num)]
  apply Complex.ext <;> simp <;> norm_num

-- Distance between the drones: |(6 + 8i) - (3 + 4i)| = 5.
example : ‖((6 : ℂ) + 8 * I) - ((3 : ℂ) + 4 * I)‖ = 5 := by
  rw [Complex.norm_eq_sqrt_sq_add_sq]
  simp
  norm_num
  rw [show (25:ℝ) = 5 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]

-- The second drone is 10 km out, so the triangle inequality is an equality: 10 = 5 + 5.
example : ‖(6 : ℂ) + 8 * I‖ = ‖(3 : ℂ) + 4 * I‖ + ‖((6 : ℂ) + 8 * I) - ((3 : ℂ) + 4 * I)‖ := by
  have h1 : ‖(3 : ℂ) + 4 * I‖ = 5 := by
    rw [Complex.norm_eq_sqrt_sq_add_sq]
    simp
    rw [show (3:ℝ) ^ 2 + 4 ^ 2 = 5 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  have h2 : ‖((6 : ℂ) + 8 * I) - ((3 : ℂ) + 4 * I)‖ = 5 := by
    rw [Complex.norm_eq_sqrt_sq_add_sq]
    simp
    norm_num
    rw [show (25:ℝ) = 5 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  have h3 : ‖(6 : ℂ) + 8 * I‖ = 10 := by
    rw [Complex.norm_eq_sqrt_sq_add_sq]
    simp
    rw [show (6:ℝ) ^ 2 + 8 ^ 2 = 10 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  rw [h1, h2, h3]; norm_num

-- Mirror to drone: (3 + 4i) - (3 - 4i) = 8i, a distance of 8 km.
example : ‖((3 : ℂ) + 4 * I) - conj ((3 : ℂ) + 4 * I)‖ = 8 := by
  rw [Complex.norm_eq_sqrt_sq_add_sq]
  simp
  norm_num

-- Drone times beacon: (3 + 4i)(1 + 2i) = -5 + 10i.
example : ((3 : ℂ) + 4 * I) * ((1 : ℂ) + 2 * I) = -5 + 10 * I := by
  apply Complex.ext <;> simp <;> norm_num

#print axioms mul_conj_eq_sq_modulus
#print axioms div_eq_mul_conj_div_sq_modulus
#print axioms modulus_mul_and_triangle
