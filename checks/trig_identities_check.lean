-- Trig identities: for every pair of angles the sine and cosine of their sum come from each angle's sine and cosine, sine squared plus cosine squared is one with the double- and half-angle formulas following, and two locked booms' rises fold into one sine R sin(θ + φ) that peaks at R.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Tactic.NormNum

open Real

/-! Angles are in radians, Mathlib's unit; the card allows degrees or radians, one unit per
formula. Every real number is an angle: negative angles and angles past a full turn included. -/

/-- The addition formulas. For every two angles θ and β, the sine of the sum crosses the pairs
and adds, sin(θ + β) = sin θ cos β + cos θ sin β, and the cosine matches them and subtracts,
cos(θ + β) = cos θ cos β − sin θ sin β. -/
theorem sin_and_cos_of_a_sum (θ β : ℝ) :
    sin (θ + β) = sin θ * cos β + cos θ * sin β ∧
      cos (θ + β) = cos θ * cos β - sin θ * sin β := by
  exact ⟨sin_add θ β, cos_add θ β⟩

/-- The Pythagorean identity and what follows from it. For every angle θ: sine squared plus
cosine squared is one; sin 2θ = 2 sin θ cos θ; cos 2θ = cos²θ − sin²θ = 2cos²θ − 1 = 1 − 2sin²θ;
and the half angles have sizes |sin(θ/2)| = √((1 − cos θ)/2) and |cos(θ/2)| = √((1 + cos θ)/2),
the root giving the size only, the sign set by where θ/2 points. -/
theorem pythagorean_double_and_half_angles (θ : ℝ) :
    sin θ ^ 2 + cos θ ^ 2 = 1 ∧
      sin (2 * θ) = 2 * sin θ * cos θ ∧
      cos (2 * θ) = cos θ ^ 2 - sin θ ^ 2 ∧
      cos θ ^ 2 - sin θ ^ 2 = 2 * cos θ ^ 2 - 1 ∧
      2 * cos θ ^ 2 - 1 = 1 - 2 * sin θ ^ 2 ∧
      |sin (θ / 2)| = √((1 - cos θ) / 2) ∧
      |cos (θ / 2)| = √((1 + cos θ) / 2) := by
  have h1 := sin_sq_add_cos_sq θ
  have h2 := sin_sq_add_cos_sq (θ / 2)
  have hc : cos θ = cos (2 * (θ / 2)) := by ring_nf
  rw [cos_two_mul] at hc
  refine ⟨h1, sin_two_mul θ, ?_, ?_, ?_, ?_, ?_⟩
  · rw [cos_two_mul]; linarith
  · linarith
  · linarith
  · rw [← Real.sqrt_sq_eq_abs]; congr 1; linarith
  · rw [← Real.sqrt_sq_eq_abs]; congr 1; linarith

/-- Two locked booms fold into one sine. A main boom of length L₁ at angle θ carries a jib of
length L₂ locked at a bend β steeper. With P = L₁ + L₂ cos β, Q = L₂ sin β and
R = √(P² + Q²), and R not 0, there is an offset angle φ with cosine P/R and sine Q/R such
that, at every boom angle θ, the tip's height L₁ sin θ + L₂ sin(θ + β) equals P sin θ + Q cos θ
and equals R sin(θ + φ). Also R = √(L₁² + L₂² + 2 L₁ L₂ cos β), the height never exceeds R, and
it reaches R when θ + φ is a quarter turn. -/
theorem two_locked_booms_fold_into_one_sine (L₁ L₂ β : ℝ)
    (hR : √((L₁ + L₂ * cos β) ^ 2 + (L₂ * sin β) ^ 2) ≠ 0) :
    let P := L₁ + L₂ * cos β
    let Q := L₂ * sin β
    let R := √(P ^ 2 + Q ^ 2)
    ∃ φ : ℝ, cos φ = P / R ∧ sin φ = Q / R ∧
      R = √(L₁ ^ 2 + L₂ ^ 2 + 2 * L₁ * L₂ * cos β) ∧
      (∀ θ : ℝ, L₁ * sin θ + L₂ * sin (θ + β) = P * sin θ + Q * cos θ ∧
        P * sin θ + Q * cos θ = R * sin (θ + φ)) ∧
      (∀ θ : ℝ, L₁ * sin θ + L₂ * sin (θ + β) ≤ R) ∧
      L₁ * sin (π / 2 - φ) + L₂ * sin (π / 2 - φ + β) = R := by
  intro P Q R
  set z : ℂ := ⟨P, Q⟩ with hz
  have hnorm : ‖z‖ = R := by
    rw [Complex.norm_def, Complex.normSq_mk]; simp only [R]; congr 1; ring
  have hRpos : 0 < R := lt_of_le_of_ne (Real.sqrt_nonneg _) (Ne.symm hR)
  have hz0 : z ≠ 0 := by
    intro h; rw [h, norm_zero] at hnorm; linarith
  have hcos : cos (Complex.arg z) = P / R := by rw [Complex.cos_arg hz0, hnorm]
  have hsin : sin (Complex.arg z) = Q / R := by rw [Complex.sin_arg, hnorm]
  set φ := Complex.arg z
  have hRne : R ≠ 0 := hRpos.ne'
  have key : ∀ θ, L₁ * sin θ + L₂ * sin (θ + β) = P * sin θ + Q * cos θ := by
    intro θ; simp only [P, Q]; rw [sin_add]; ring
  have key2 : ∀ θ, P * sin θ + Q * cos θ = R * sin (θ + φ) := by
    intro θ; rw [sin_add, hcos, hsin]; field_simp
  refine ⟨φ, hcos, hsin, ?_, fun θ => ⟨key θ, key2 θ⟩, ?_, ?_⟩
  · simp only [R, P, Q]; congr 1
    have := sin_sq_add_cos_sq β
    linear_combination L₂ ^ 2 * this
  · intro θ; rw [key, key2]
    have := sin_le_one (θ + φ)
    nlinarith
  · rw [key, key2]
    have : π / 2 - φ + φ = π / 2 := by ring
    rw [this, sin_pi_div_two, mul_one]

-- The bend is 30°, π/6: sin 30° = 1/2 exactly, so Q = 10 × 1/2 = 5 m.
example : (10 : ℝ) * sin (π / 6) = 5 := by
  rw [sin_pi_div_six]; norm_num
-- sin 30° and cos 30° = √3/2, squared, add to 1.
example : sin (π / 6) ^ 2 + cos (π / 6) ^ 2 = 1 := by
  rw [sin_pi_div_six, cos_pi_div_six, div_pow (√3), Real.sq_sqrt (by norm_num : (0 : ℝ) ≤ 3)]
  norm_num
-- Straighten the knuckle (bend 0): R = √(30² + 10² + 2·30·10·cos 0) = 40 m, the booms laid straight.
example : √((30 : ℝ) ^ 2 + 10 ^ 2 + 2 * 30 * 10 * cos 0) = 40 := by
  rw [cos_zero, Real.sqrt_eq_iff_mul_self_eq (by norm_num) (by norm_num)]
  norm_num
-- With the bend straight, P = 30 + 10 cos 0 = 40 and Q = 10 sin 0 = 0.
example : (30 : ℝ) + 10 * cos 0 = 40 ∧ (10 : ℝ) * sin 0 = 0 := by
  simp; norm_num

#print axioms sin_and_cos_of_a_sum
#print axioms pythagorean_double_and_half_angles
#print axioms two_locked_booms_fold_into_one_sine
