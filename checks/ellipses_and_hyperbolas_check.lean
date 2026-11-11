-- Ellipses and hyperbolas: with foci at (-c, 0) and (c, 0), the points whose distances to the foci add to 2a are exactly the solutions of x^2/a^2 + y^2/(a^2 - c^2) = 1, the points whose distances differ by 2a are exactly the solutions of x^2/a^2 - y^2/(c^2 - a^2) = 1, and on the ellipse the distance to the focus (c, 0) is a - (c/a)x, between a - c and a + c.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic

lemma dist_vec2 (p : EuclideanSpace ℝ (Fin 2)) (u v : ℝ) :
    dist p !₂[u, v] = Real.sqrt ((p 0 - u) ^ 2 + (p 1 - v) ^ 2) := by
  rw [EuclideanSpace.dist_eq, Fin.sum_univ_two]
  simp [Real.dist_eq, sq_abs]

lemma core_sum (a c x y L R : ℝ) (hL : L ^ 2 = (x + c) ^ 2 + y ^ 2)
    (hR : R ^ 2 = (x - c) ^ 2 + y ^ 2) (h : L + R = 2 * a) :
    a * L = a ^ 2 + c * x ∧ a * R = a ^ 2 - c * x ∧
      x ^ 2 * (a ^ 2 - c ^ 2) + a ^ 2 * y ^ 2 = a ^ 2 * (a ^ 2 - c ^ 2) := by
  have h1 : a * L = a ^ 2 + c * x := by
    have hR' : R = 2 * a - L := by linarith
    subst hR'
    linear_combination (1/4) * hL - (1/4) * hR
  refine ⟨h1, by linear_combination a * h - h1, ?_⟩
  linear_combination -a ^ 2 * hL + (a * L + a ^ 2 + c * x) * h1

lemma core_diff (a c x y L R : ℝ) (ha : 0 < a) (hL : L ^ 2 = (x + c) ^ 2 + y ^ 2)
    (hR : R ^ 2 = (x - c) ^ 2 + y ^ 2) (h : |L - R| = 2 * a) :
    x ^ 2 * (a ^ 2 - c ^ 2) + a ^ 2 * y ^ 2 = a ^ 2 * (a ^ 2 - c ^ 2) := by
  have hsq : (a * L) ^ 2 = (a ^ 2 + c * x) ^ 2 := by
    rcases (abs_eq (by linarith : (0:ℝ) ≤ 2 * a)).1 h with h | h
    · have h1 : a * L = a ^ 2 + c * x := by
        have hR' : R = L - 2 * a := by linarith
        subst hR'
        linear_combination (1/4) * hL - (1/4) * hR
      rw [h1]
    · have h1 : a * L = -(a ^ 2 + c * x) := by
        have hR' : R = L + 2 * a := by linarith
        subst hR'
        linear_combination -(1/4) * hL + (1/4) * hR
      rw [h1]; ring
  linear_combination -a ^ 2 * hL + hsq

lemma core_back (a c x y L R : ℝ) (ha : 0 < a) (hL0 : 0 ≤ L) (hR0 : 0 ≤ R)
    (hL : L ^ 2 = (x + c) ^ 2 + y ^ 2) (hR : R ^ 2 = (x - c) ^ 2 + y ^ 2)
    (h : x ^ 2 * (a ^ 2 - c ^ 2) + a ^ 2 * y ^ 2 = a ^ 2 * (a ^ 2 - c ^ 2)) :
    a * L = |a ^ 2 + c * x| ∧ a * R = |a ^ 2 - c * x| := by
  constructor
  · rw [← pow_left_inj₀ (by positivity) (abs_nonneg _) two_ne_zero, sq_abs]
    linear_combination a ^ 2 * hL + h
  · rw [← pow_left_inj₀ (by positivity) (abs_nonneg _) two_ne_zero, sq_abs]
    linear_combination a ^ 2 * hR + h

#print axioms dist_vec2
#print axioms core_sum
#print axioms core_diff
#print axioms core_back

/-- The ellipse. Put the two foci at (-c, 0) and (c, 0), with 0 ≤ c (c is the distance from the
centre to each focus) and the right gap: the fixed sum 2a is longer than the gap 2c between the
foci. Then a point (x, y) of the plane has distances to the two foci adding to 2a exactly when
x^2/a^2 + y^2/b^2 = 1, where b^2 = a^2 - c^2. -/
theorem ellipse_fixed_sum_iff_standard_form (a c : ℝ) (hc : 0 ≤ c) (hca : c < a)
    (p : EuclideanSpace ℝ (Fin 2)) :
    dist p !₂[-c, 0] + dist p !₂[c, 0] = 2 * a ↔
      p 0 ^ 2 / a ^ 2 + p 1 ^ 2 / (a ^ 2 - c ^ 2) = 1 := by
  have ha : 0 < a := by linarith
  have hb : 0 < a ^ 2 - c ^ 2 := by nlinarith
  rw [dist_vec2, dist_vec2]
  set x := p 0
  set y := p 1
  set L := Real.sqrt ((x - -c) ^ 2 + (y - 0) ^ 2) with hLdef
  set R := Real.sqrt ((x - c) ^ 2 + (y - 0) ^ 2) with hRdef
  have hL : L ^ 2 = (x + c) ^ 2 + y ^ 2 := by
    rw [hLdef, Real.sq_sqrt (by positivity)]; ring
  have hR : R ^ 2 = (x - c) ^ 2 + y ^ 2 := by
    rw [hRdef, Real.sq_sqrt (by positivity)]; ring
  have hL0 : 0 ≤ L := Real.sqrt_nonneg _
  have hR0 : 0 ≤ R := Real.sqrt_nonneg _
  rw [div_add_div _ _ (by positivity) hb.ne', div_eq_one_iff_eq (by positivity)]
  constructor
  · intro h
    have := (core_sum a c x y L R hL hR h).2.2
    linear_combination this
  · intro h
    have h' : x ^ 2 * (a ^ 2 - c ^ 2) + a ^ 2 * y ^ 2 = a ^ 2 * (a ^ 2 - c ^ 2) := by
      linear_combination h
    obtain ⟨h1, h2⟩ := core_back a c x y L R ha hL0 hR0 hL hR h'
    have hx : x ^ 2 ≤ a ^ 2 := by nlinarith [sq_nonneg y]
    have hx' : |x| ≤ a := abs_le_of_sq_le_sq' hx ha.le |> fun h => abs_le.2 h
    obtain ⟨hx1, hx2⟩ := abs_le.1 hx'
    rw [abs_of_nonneg (by nlinarith)] at h1
    rw [abs_of_nonneg (by nlinarith)] at h2
    have : a * (L + R) = a * (2 * a) := by linear_combination h1 + h2
    exact mul_left_cancel₀ ha.ne' this

/-- The hyperbola. Same foci (-c, 0) and (c, 0), with the right gap for a hyperbola: the fixed
difference 2a lies between 0 and the gap 2c. Then a point (x, y) has distances to the two foci
differing by 2a (either one the larger) exactly when x^2/a^2 - y^2/b^2 = 1, where now
b^2 = c^2 - a^2: one sign flips in each formula. -/
theorem hyperbola_fixed_difference_iff_standard_form (a c : ℝ) (ha : 0 < a) (hac : a < c)
    (p : EuclideanSpace ℝ (Fin 2)) :
    |dist p !₂[-c, 0] - dist p !₂[c, 0]| = 2 * a ↔
      p 0 ^ 2 / a ^ 2 - p 1 ^ 2 / (c ^ 2 - a ^ 2) = 1 := by
  have hb : 0 < c ^ 2 - a ^ 2 := by nlinarith
  rw [dist_vec2, dist_vec2]
  set x := p 0
  set y := p 1
  set L := Real.sqrt ((x - -c) ^ 2 + (y - 0) ^ 2) with hLdef
  set R := Real.sqrt ((x - c) ^ 2 + (y - 0) ^ 2) with hRdef
  have hL : L ^ 2 = (x + c) ^ 2 + y ^ 2 := by
    rw [hLdef, Real.sq_sqrt (by positivity)]; ring
  have hR : R ^ 2 = (x - c) ^ 2 + y ^ 2 := by
    rw [hRdef, Real.sq_sqrt (by positivity)]; ring
  have hL0 : 0 ≤ L := Real.sqrt_nonneg _
  have hR0 : 0 ≤ R := Real.sqrt_nonneg _
  rw [div_sub_div _ _ (by positivity) hb.ne', div_eq_one_iff_eq (by positivity)]
  constructor
  · intro h
    have := core_diff a c x y L R ha hL hR h
    linear_combination -this
  · intro h
    have h' : x ^ 2 * (a ^ 2 - c ^ 2) + a ^ 2 * y ^ 2 = a ^ 2 * (a ^ 2 - c ^ 2) := by
      linear_combination -h
    obtain ⟨h1, h2⟩ := core_back a c x y L R ha hL0 hR0 hL hR h'
    have hx : a ^ 2 ≤ x ^ 2 := by nlinarith [sq_nonneg y]
    rcases le_total 0 x with hx0 | hx0
    · have hxa : a ≤ x := by nlinarith
      rw [abs_of_nonneg (by nlinarith)] at h1
      rw [abs_of_nonpos (by nlinarith)] at h2
      have : a * (L - R) = a * (2 * a) := by linear_combination h1 - h2
      rw [mul_left_cancel₀ ha.ne' this, abs_of_pos (by linarith)]
    · have hxa : x ≤ -a := by nlinarith
      rw [abs_of_nonpos (by nlinarith)] at h1
      rw [abs_of_nonneg (by nlinarith)] at h2
      have : a * (L - R) = a * (-(2 * a)) := by linear_combination h1 - h2
      rw [mul_left_cancel₀ ha.ne' this, abs_neg, abs_of_pos (by linarith)]

/-- A fixed sum splits into two exact distances. On the ellipse (foci (-c, 0) and (c, 0),
0 ≤ c < a, distances adding to 2a), with eccentricity e = c/a the distance to the focus (c, 0)
is R = a - e x and the distance to (-c, 0) is L = a + e x. So the distance to the sun at (c, 0)
is never below a - c (perihelion) and never above a + c (aphelion). -/
theorem ellipse_focal_distances (a c : ℝ) (hc : 0 ≤ c) (hca : c < a)
    (p : EuclideanSpace ℝ (Fin 2))
    (hp : dist p !₂[-c, 0] + dist p !₂[c, 0] = 2 * a) :
    dist p !₂[c, 0] = a - c / a * p 0 ∧ dist p !₂[-c, 0] = a + c / a * p 0 ∧
      a - c ≤ dist p !₂[c, 0] ∧ dist p !₂[c, 0] ≤ a + c := by
  have ha : 0 < a := by linarith
  have hb : 0 < a ^ 2 - c ^ 2 := by nlinarith
  rw [dist_vec2, dist_vec2] at hp ⊢
  set x := p 0
  set y := p 1
  set L := Real.sqrt ((x - -c) ^ 2 + (y - 0) ^ 2) with hLdef
  set R := Real.sqrt ((x - c) ^ 2 + (y - 0) ^ 2) with hRdef
  have hL : L ^ 2 = (x + c) ^ 2 + y ^ 2 := by
    rw [hLdef, Real.sq_sqrt (by positivity)]; ring
  have hR : R ^ 2 = (x - c) ^ 2 + y ^ 2 := by
    rw [hRdef, Real.sq_sqrt (by positivity)]; ring
  obtain ⟨h1, h2, h3⟩ := core_sum a c x y L R hL hR hp
  have hx : x ^ 2 ≤ a ^ 2 := by nlinarith [sq_nonneg y]
  obtain ⟨hx1, hx2⟩ := abs_le.1 (abs_le_of_sq_le_sq' hx ha.le |> fun h => abs_le.2 h)
  have eR : R = a - c / a * x := by
    field_simp
    linear_combination h2
  have eL : L = a + c / a * x := by
    field_simp
    linear_combination h1
  have hcx1 : c / a * x ≤ c := by
    rw [div_mul_eq_mul_div, div_le_iff₀ ha]; nlinarith
  have hcx2 : -c ≤ c / a * x := by
    rw [div_mul_eq_mul_div, le_div_iff₀ ha]; nlinarith
  refine ⟨eR, eL, ?_, ?_⟩ <;> rw [eR] <;> linarith

-- The orbit: a = 100, e = 0.2 = 1/5, so c = 20 and b^2 = 100^2 - 20^2 = 9600.
example : (100 : ℚ) * (1 / 5) = 20 := by norm_num
example : (100 : ℤ) ^ 2 - 20 ^ 2 = 9600 := by decide
-- Perihelion a - c = 80 and aphelion a + c = 120; they add to 2a = 200.
example : (100 : ℤ) - 20 = 80 ∧ (100 : ℤ) + 20 = 120 ∧ (80 : ℤ) + 120 = 2 * 100 := by decide
-- The spot T, 60 across: R = 100 - (1/5)(60) = 88 and L = 100 + 12 = 112, adding to 200.
example : (100 : ℚ) - 1 / 5 * 60 = 88 ∧ (100 : ℚ) + 1 / 5 * 60 = 112 := by norm_num
-- T's height squared is y^2 = 9600 (1 - 60^2/100^2) = 6144, and then the distance formula gives
-- exactly 88 to the sun at (20, 0) and 112 to the empty focus at (-20, 0).
example : (9600 : ℚ) * (1 - 60 ^ 2 / 100 ^ 2) = 6144 := by norm_num
example : ((60 : ℤ) - 20) ^ 2 + 6144 = 88 ^ 2 ∧ ((60 : ℤ) + 20) ^ 2 + 6144 = 112 ^ 2 := by decide
-- The directrix x = a/e = 500: at T, 88 / (500 - 60) = 1/5, the eccentricity.
example : (100 : ℚ) / (1 / 5) = 500 ∧ (88 : ℚ) / (500 - 60) = 1 / 5 := by norm_num
-- The comet: foci (±20, 0), difference 32, so a = 16, b^2 = 20^2 - 16^2 = 144 = 12^2,
-- e = 20/16 = 5/4, and its tip passes the sun at 20 - 16 = 4.
example : (20 : ℤ) ^ 2 - 16 ^ 2 = 12 ^ 2 ∧ (20 : ℤ) - 16 = 4 := by decide
example : (20 : ℚ) / 16 = 5 / 4 := by norm_num
-- The comet's directrix x = a/e = 12.8 = 64/5: at its tip, 4 / (16 - 64/5) = 5/4.
example : (16 : ℚ) / (5 / 4) = 64 / 5 ∧ (4 : ℚ) / (16 - 64 / 5) = 5 / 4 := by norm_num
-- The orbit's general equation 24x^2 + 25y^2 + 960x - 230400 = 0 (sun at the origin):
-- completing the square gives 24(x + 20)^2 + 25y^2 = 240000, with denominators 10000 and 9600,
-- and e^2 = 1 - 24/25 = (1/5)^2.
example : (230400 : ℤ) + 24 * 20 ^ 2 = 240000 ∧ 960 = 2 * 24 * 20 := by decide
example : (240000 : ℚ) / 24 = 10000 ∧ (240000 : ℚ) / 25 = 9600 ∧ 1 - (24 : ℚ) / 25 = (1 / 5) ^ 2 := by
  norm_num
-- The comet's general equation 9x^2 - 16y^2 - 2304 = 0: denominators 2304/9 = 256 = 16^2 and
-- 2304/16 = 144 = 12^2, and e^2 = 1 + 9/16 = (5/4)^2.
example : (2304 : ℤ) = 9 * 16 ^ 2 ∧ (2304 : ℤ) = 16 * 12 ^ 2 := by decide
example : 1 + (9 : ℚ) / 16 = (5 / 4) ^ 2 := by norm_num

#print axioms ellipse_fixed_sum_iff_standard_form
#print axioms hyperbola_fixed_difference_iff_standard_form
#print axioms ellipse_focal_distances
