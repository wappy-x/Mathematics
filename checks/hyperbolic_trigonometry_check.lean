-- Hyperbolic trigonometry: in the half-plane model every triangle obeys the hyperbolic laws of cosines and sines, and a line through a point at distance d from a line meets it exactly when its tilt is below the angle of parallelism Π(d), where tan(Π/2) = e^(−d).
import Mathlib.Analysis.Complex.UpperHalfPlane.Metric
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan

open UpperHalfPlane Real

/-- The direction in which the hyperbolic straight line from `w` to `z` leaves `w`, drawn in
the half-plane map as a vector in ℂ. The line is a vertical line or a half-circle centred on
the edge; this vector is square to the radius at `w` and points along the arc toward `z`
(for `w = i` it is `(2x, x² + y² − 1)`, the card's `(1, k)` scaled by `2x`). It is `0` only
when `z = w`. -/
def tangentAt (w z : ℍ) : ℂ :=
  ⟨2 * w.im * (z.re - w.re), (z.re - w.re) ^ 2 + z.im ^ 2 - w.im ^ 2⟩

/-- The angle at corner `C` between the hyperbolic straight lines to `A` and to `B`. The
half-plane map keeps angles, so it is the flat angle between the two drawn directions. -/
noncomputable def cornerAngle (C A B : ℍ) : ℝ :=
  InnerProductGeometry.angle (tangentAt C A) (tangentAt C B)


lemma cosh_dist_eq_aux (z w : ℍ) :
    cosh (dist z w) = ((z.re - w.re) ^ 2 + z.im ^ 2 + w.im ^ 2) / (2 * z.im * w.im) := by
  rw [cosh_dist, Complex.dist_eq_re_im, Real.sq_sqrt (by positivity)]
  have hz := z.im_pos
  have hw := w.im_pos
  simp only [coe_re, coe_im]
  field_simp
  ring

lemma norm_tangentAt_aux (w z : ℍ) :
    ‖tangentAt w z‖ = 2 * w.im * z.im * sinh (dist w z) := by
  have hz := z.im_pos
  have hw := w.im_pos
  have hs : 0 ≤ sinh (dist w z) := Real.sinh_nonneg_iff.mpr dist_nonneg
  have h1 : 0 ≤ 2 * w.im * z.im * sinh (dist w z) := by positivity
  rw [Complex.norm_def, Real.sqrt_eq_iff_eq_sq (Complex.normSq_nonneg _) h1, mul_pow,
    Real.sinh_sq, cosh_dist_eq_aux, Complex.normSq_apply]
  simp only [tangentAt]
  field_simp
  ring

lemma law_of_sines_aux (x a b c : ℝ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) (hx : 0 ≤ sin x)
    (h : cosh c = cosh a * cosh b - sinh a * sinh b * cos x) :
    sin x / sinh c = √(1 - cosh a ^ 2 - cosh b ^ 2 - cosh c ^ 2 + 2 * cosh a * cosh b * cosh c)
      / (sinh a * sinh b * sinh c) := by
  have sa := Real.sinh_pos_iff.mpr ha
  have sb := Real.sinh_pos_iff.mpr hb
  have sc := Real.sinh_pos_iff.mpr hc
  have key : 1 - cosh a ^ 2 - cosh b ^ 2 - cosh c ^ 2 + 2 * cosh a * cosh b * cosh c
      = (sinh a * sinh b * sin x) ^ 2 := by
    rw [h]
    have e1 := Real.cosh_sq a
    have e2 := Real.cosh_sq b
    have e3 := Real.sin_sq_add_cos_sq x
    linear_combination (cosh b ^ 2 - 1) * e1 + sinh a ^ 2 * e2 - sinh a ^ 2 * sinh b ^ 2 * e3
  rw [key, Real.sqrt_sq (by positivity)]
  field_simp

#print axioms cosh_dist_eq_aux
#print axioms norm_tangentAt_aux
#print axioms law_of_sines_aux

/-- The hyperbolic law of cosines: for any three corners A, B, C of the hyperbolic plane
(the upper half-plane with its own distance), with sides a = BC, b = CA, c = AB and angle C
at corner C, cosh c = cosh a cosh b − sinh a sinh b cos C. At C = 90° this is the hyperbolic
Pythagoras, cosh c = cosh a cosh b. -/
theorem hyperbolic_law_of_cosines (A B C : ℍ) :
    cosh (dist A B) =
      cosh (dist B C) * cosh (dist C A)
        - sinh (dist B C) * sinh (dist C A) * cos (cornerAngle C B A) := by
  have hA := A.im_pos
  have hB := B.im_pos
  have hC := C.im_pos
  have hI : sinh (dist B C) * sinh (dist C A) * cos (cornerAngle C B A)
      = inner ℝ (tangentAt C B) (tangentAt C A) / (4 * C.im ^ 2 * B.im * A.im) := by
    unfold cornerAngle
    rw [InnerProductGeometry.cos_angle]
    rcases eq_or_ne (sinh (dist B C)) 0 with h | h
    · have : tangentAt C B = 0 := by
        rw [← norm_eq_zero, norm_tangentAt_aux, dist_comm, h]; ring
      simp [this, h]
    rcases eq_or_ne (sinh (dist C A)) 0 with h' | h'
    · have : tangentAt C A = 0 := by
        rw [← norm_eq_zero, norm_tangentAt_aux, h']; ring
      simp [this, h']
    rw [norm_tangentAt_aux, norm_tangentAt_aux, dist_comm C B]
    field_simp
    ring
  rw [hI, Complex.inner, cosh_dist_eq_aux, cosh_dist_eq_aux, cosh_dist_eq_aux]
  simp only [tangentAt, Complex.mul_re, Complex.conj_re, Complex.conj_im]
  field_simp
  ring

/-- The hyperbolic law of sines: in a triangle with three different corners A, B, C,
sin A / sinh a = sin B / sinh b = sin C / sinh c, where each side is the one facing the
corner of the same letter. -/
theorem hyperbolic_law_of_sines (A B C : ℍ) (hAB : A ≠ B) (hBC : B ≠ C) (hCA : C ≠ A) :
    sin (cornerAngle A B C) / sinh (dist B C) = sin (cornerAngle B C A) / sinh (dist C A) ∧
      sin (cornerAngle B C A) / sinh (dist C A) = sin (cornerAngle C A B) / sinh (dist A B) := by
  have ha : 0 < dist B C := dist_pos.mpr hBC
  have hb : 0 < dist C A := dist_pos.mpr hCA
  have hc : 0 < dist A B := dist_pos.mpr hAB
  have sinA : 0 ≤ sin (cornerAngle A B C) := Real.sin_nonneg_of_nonneg_of_le_pi
    (InnerProductGeometry.angle_nonneg _ _) (InnerProductGeometry.angle_le_pi _ _)
  have sinB : 0 ≤ sin (cornerAngle B C A) := Real.sin_nonneg_of_nonneg_of_le_pi
    (InnerProductGeometry.angle_nonneg _ _) (InnerProductGeometry.angle_le_pi _ _)
  have sinC : 0 ≤ sin (cornerAngle C A B) := Real.sin_nonneg_of_nonneg_of_le_pi
    (InnerProductGeometry.angle_nonneg _ _) (InnerProductGeometry.angle_le_pi _ _)
  have h1 := hyperbolic_law_of_cosines C B A
  have h2 := hyperbolic_law_of_cosines A C B
  have h3 := hyperbolic_law_of_cosines B A C
  simp only [dist_comm B A, dist_comm A C, dist_comm C B] at h1 h2 h3
  rw [law_of_sines_aux _ _ _ _ hc hb ha sinA h1, law_of_sines_aux _ _ _ _ ha hc hb sinB h2,
    law_of_sines_aux _ _ _ _ hb ha hc sinC h3]
  constructor <;> ring_nf

/-- The angle of parallelism. Put P at i and let L be the half-circle of radius e^(−d)
centred at 0, which the vertical through P meets square at distance d below P. The line
through P tilted θ from straight down (0 < θ ≤ 90°) is the half-circle centred at
−cos θ / sin θ with radius 1 / sin θ. It meets L exactly when θ < Π(d), where
tan(Π(d)/2) = e^(−d); equivalently cos Π(d) = tanh d. -/
theorem angle_of_parallelism (d θ : ℝ) (hd : 0 < d) (hθ : 0 < θ) (hθ' : θ ≤ π / 2) :
    dist UpperHalfPlane.I (⟨⟨0, exp (-d)⟩, exp_pos (-d)⟩ : ℍ) = d ∧
      ((∃ z : ℍ, ‖(z : ℂ)‖ = exp (-d) ∧ ‖(z : ℂ) + (cos θ / sin θ : ℝ)‖ = 1 / sin θ) ↔
        θ < 2 * arctan (exp (-d))) ∧
      cos (2 * arctan (exp (-d))) = tanh d := by
  set r := exp (-d) with hr_def
  have hr0 : 0 < r := exp_pos _
  have hr1 : r < 1 := Real.exp_lt_one_iff.mpr (by linarith)
  have hs : 0 < sin θ := Real.sin_pos_of_pos_of_lt_pi hθ (by linarith [Real.pi_pos])
  have hc : 0 ≤ cos θ := Real.cos_nonneg_of_neg_pi_div_two_le_of_le (by linarith) hθ'
  have hsc := Real.sin_sq_add_cos_sq θ
  have hsq : 0 < 1 + r ^ 2 := by positivity
  have hcosφ : cos (2 * arctan r) = (1 - r ^ 2) / (1 + r ^ 2) := by
    rw [Real.cos_two_mul, Real.cos_sq_arctan]
    field_simp
    ring
  have hsinφ : sin (2 * arctan r) = 2 * r / (1 + r ^ 2) := by
    rw [Real.sin_two_mul, Real.sin_arctan, Real.cos_arctan]
    have h1 : √(1 + r ^ 2) ^ 2 = 1 + r ^ 2 := Real.sq_sqrt hsq.le
    have h2 : 0 < √(1 + r ^ 2) := Real.sqrt_pos.mpr hsq
    field_simp
    exact h1.symm
  -- the angle condition in algebraic form
  have claimA : θ < 2 * arctan r ↔ (1 - r ^ 2) * sin θ < 2 * r * cos θ := by
    have hφ0 : 0 < arctan r := Real.arctan_pos.mpr hr0
    have hφ1 : arctan r < π / 2 := Real.arctan_lt_pi_div_two r
    have hsin : sin (θ - 2 * arctan r) = ((1 - r ^ 2) * sin θ - 2 * r * cos θ) / (1 + r ^ 2) := by
      rw [Real.sin_sub, hcosφ, hsinφ]
      field_simp
    constructor
    · intro h
      have : sin (θ - 2 * arctan r) < 0 :=
        Real.sin_neg_of_neg_of_neg_pi_lt (by linarith) (by linarith)
      rw [hsin, div_neg_iff] at this
      rcases this with ⟨_, h'⟩ | ⟨h', _⟩
      · linarith
      · linarith
    · intro h
      by_contra hn
      replace hn := not_lt.mp hn
      have : 0 ≤ sin (θ - 2 * arctan r) :=
        Real.sin_nonneg_of_nonneg_of_le_pi (by linarith) (by linarith)
      rw [hsin] at this
      have := div_nonneg_iff.mp this
      rcases this with ⟨h', _⟩ | ⟨_, h'⟩
      · linarith
      · linarith
  -- the intersection condition in algebraic form
  have claimB : (∃ z : ℍ, ‖(z : ℂ)‖ = r ∧ ‖(z : ℂ) + (cos θ / sin θ : ℝ)‖ = 1 / sin θ) ↔
      (1 - r ^ 2) * sin θ < 2 * r * cos θ := by
    constructor
    · rintro ⟨z, h1, h2⟩
      have hy := z.im_pos
      have e1 : (z : ℂ).re * (z : ℂ).re + (z : ℂ).im * (z : ℂ).im = r ^ 2 := by
        rw [← Complex.normSq_apply, ← Complex.sq_norm, h1]
      have e2 : ((z : ℂ).re + cos θ / sin θ) * ((z : ℂ).re + cos θ / sin θ)
          + (z : ℂ).im * (z : ℂ).im = (1 / sin θ) ^ 2 := by
        rw [← h2, Complex.sq_norm, Complex.normSq_apply]
        simp only [Complex.add_re, Complex.add_im, Complex.ofReal_re, Complex.ofReal_im, add_zero]
      simp only [coe_re, coe_im] at e1 e2
      set x := z.re
      set y := z.im
      set s := sin θ
      set c := cos θ
      have e2' : (x * s + c) ^ 2 + y ^ 2 * s ^ 2 = 1 := by
        field_simp at e2
        linear_combination e2
      have e3 : s * (2 * x * c - s * (1 - r ^ 2)) = 0 := by
        linear_combination e2' - s ^ 2 * e1 - hsc
      have e4 : 2 * x * c = s * (1 - r ^ 2) := by
        rcases mul_eq_zero.mp e3 with h | h
        · linarith
        · linarith
      have hpos : 0 < s * (1 - r ^ 2) := mul_pos hs (by nlinarith)
      have hc' : 0 < c := by
        rcases hc.lt_or_eq with h | h
        · exact h
        · rw [← h] at e4; linarith
      have hx : 0 < x := by nlinarith
      have hxr : x < r := by nlinarith
      nlinarith [mul_lt_mul_of_pos_left hxr hc']
    · intro h
      set s := sin θ
      set c := cos θ
      have hpos : 0 < s * (1 - r ^ 2) := mul_pos hs (by nlinarith)
      have hc' : 0 < c := by
        rcases hc.lt_or_eq with h' | h'
        · exact h'
        · rw [← h'] at h; nlinarith
      set x := s * (1 - r ^ 2) / (2 * c) with hx_def
      have hx : 0 < x := by positivity
      have hxr : x < r := by
        rw [hx_def, div_lt_iff₀ (by positivity)]
        linarith
      have hyy : 0 < r ^ 2 - x ^ 2 := by nlinarith
      set y := √(r ^ 2 - x ^ 2) with hy_def
      have hy : 0 < y := Real.sqrt_pos.mpr hyy
      have hyy' : y * y = r ^ 2 - x ^ 2 := Real.mul_self_sqrt hyy.le
      refine ⟨UpperHalfPlane.mk ⟨x, y⟩ hy, ?_, ?_⟩
      · rw [Complex.norm_def, Real.sqrt_eq_iff_eq_sq (Complex.normSq_nonneg _) hr0.le,
          Complex.normSq_apply]
        simp only []
        linear_combination hyy'
      · rw [Complex.norm_def, Real.sqrt_eq_iff_eq_sq (Complex.normSq_nonneg _) (by positivity),
          Complex.normSq_apply]
        simp only [ Complex.add_re, Complex.add_im, Complex.ofReal_re,
          Complex.ofReal_im, add_zero]
        rw [hyy', hx_def]
        field_simp
        linear_combination 4 * c ^ 2 * hsc
  refine ⟨?_, claimB.trans claimA.symm, ?_⟩
  · rw [dist_of_re_eq (by simp)]
    simp [Real.dist_eq]
    linarith
  · rw [hcosφ, Real.tanh_eq_sinh_div_cosh, Real.sinh_eq, Real.cosh_eq, hr_def, Real.exp_neg]
    have := exp_pos d
    field_simp

#print axioms hyperbolic_law_of_cosines
#print axioms hyperbolic_law_of_sines
#print axioms angle_of_parallelism
