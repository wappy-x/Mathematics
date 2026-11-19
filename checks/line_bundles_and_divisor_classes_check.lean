-- Line bundles and divisors: on the complex projective plane two divisors are linearly equivalent exactly when they have the same degree, so every divisor is its degree times the line z = 0, and a ratio of forms is a function only when the degrees match.
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.Algebra.MvPolynomial.NoZeroDivisors
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Finsupp.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open MvPolynomial

/-- A product of powers of nonzero forms is a nonzero form, of degree the weighted sum of
the degrees. -/
theorem lb_prod_homogeneous (E : MvPolynomial (Fin 3) ℂ →₀ ℤ)
    (hE : ∀ P ∈ E.support, P ≠ 0 ∧ P.IsHomogeneous P.totalDegree) (f : ℤ → ℕ) :
    (E.prod fun P k => P ^ f k).IsHomogeneous (E.sum fun P k => P.totalDegree * f k) ∧
      (E.prod fun P k => P ^ f k) ≠ 0 := by
  refine ⟨?_, ?_⟩
  · unfold Finsupp.prod Finsupp.sum
    exact IsHomogeneous.prod _ _ _ fun P hP => (hE P hP).2.pow _
  · unfold Finsupp.prod
    exact Finset.prod_ne_zero_iff.mpr fun P hP => pow_ne_zero _ (hE P hP).1

#print axioms lb_prod_homogeneous

/-- The integer degree splits into its positive and negative parts. -/
theorem lb_degree_split (E : MvPolynomial (Fin 3) ℂ →₀ ℤ) :
    (E.sum fun P k => k * (P.totalDegree : ℤ)) =
      ((E.sum fun P k => P.totalDegree * k.toNat : ℕ) : ℤ) -
        ((E.sum fun P k => P.totalDegree * (-k).toNat : ℕ) : ℤ) := by
  unfold Finsupp.sum
  push_cast
  rw [← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun P _ => ?_
  rw [← mul_sub, Int.toNat_sub_toNat_neg, mul_comm]

#print axioms lb_degree_split

/-- Linear equivalence to zero is degree zero, for any weighted sum of nonzero forms. -/
theorem lb_key (E : MvPolynomial (Fin 3) ℂ →₀ ℤ)
    (hE : ∀ P ∈ E.support, P ≠ 0 ∧ P.IsHomogeneous P.totalDegree) :
    (∃ (n : ℕ) (F G : MvPolynomial (Fin 3) ℂ), F ≠ 0 ∧ G ≠ 0 ∧
        F.IsHomogeneous n ∧ G.IsHomogeneous n ∧
        Associated (F * E.prod fun P k => P ^ (-k).toNat)
          (G * E.prod fun P k => P ^ k.toNat)) ↔
      (E.sum fun P k => k * (P.totalDegree : ℤ)) = 0 := by
  obtain ⟨hA, hA0⟩ := lb_prod_homogeneous E hE fun k => (-k).toNat
  obtain ⟨hB, hB0⟩ := lb_prod_homogeneous E hE fun k => k.toNat
  rw [lb_degree_split, sub_eq_zero, Int.natCast_inj]
  constructor
  · rintro ⟨n, F, G, hF0, hG0, hF, hG, u, hu⟩
    have hu0 : (u : MvPolynomial (Fin 3) ℂ) ≠ 0 := u.ne_zero
    have hui : (u⁻¹ : (MvPolynomial (Fin 3) ℂ)ˣ).val ≠ 0 := u⁻¹.ne_zero
    have hudeg : (u : MvPolynomial (Fin 3) ℂ).totalDegree = 0 := by
      have := congrArg totalDegree u.mul_inv
      rw [totalDegree_mul_of_isDomain hu0 hui, totalDegree_one] at this
      omega
    have h1 := congrArg totalDegree hu
    rw [totalDegree_mul_of_isDomain (mul_ne_zero hF0 hA0) hu0, hudeg, add_zero,
      totalDegree_mul_of_isDomain hF0 hA0, totalDegree_mul_of_isDomain hG0 hB0,
      hF.totalDegree hF0, hG.totalDegree hG0, hA.totalDegree hA0, hB.totalDegree hB0] at h1
    omega
  · intro h
    refine ⟨_, _, _, hB0, hA0, hB, h ▸ hA, ?_⟩
    rw [mul_comm]

#print axioms lb_key

/-- Scaling the point multiplies a form of degree m by c^m. -/
theorem lb_eval_smul {m : ℕ} (F : MvPolynomial (Fin 3) ℂ) (hF : F.IsHomogeneous m) (c : ℂ)
    (v : Fin 3 → ℂ) : eval (c • v) F = c ^ m * eval v F := by
  rw [eval_eq, eval_eq, Finset.mul_sum]
  refine Finset.sum_congr rfl fun d hd => ?_
  have hdeg : ∑ i ∈ d.support, d i = m := by
    have := hF (mem_support_iff.mp hd)
    rw [← Finsupp.degree_apply, Finsupp.degree_eq_weight_one]
    exact this
  simp only [Pi.smul_apply, smul_eq_mul, mul_pow, Finset.prod_mul_distrib, Finset.prod_pow_eq_pow_sum]
  rw [hdeg]
  ring

#print axioms lb_eval_smul

/-- The Picard group of the plane is the whole numbers, read by degree. Over ℂ, take two
divisors D and D' on the projective plane: finite sums of curves V(P) with whole-number
weights, each P an irreducible form (every term of the same total degree). D and D' are
linearly equivalent, D - D' = div(F/G) for two nonzero forms F and G of the same degree n,
exactly when they have the same degree Σ (weight × degree of the curve).
Here "div(F/G) = D - D'" is written without fractions: F times the curves D - D' carries with
negative weight equals G times the curves with positive weight, up to a nonzero constant. -/
theorem linearly_equivalent_iff_same_degree
    (D D' : MvPolynomial (Fin 3) ℂ →₀ ℤ)
    (hD : ∀ P ∈ D.support, Irreducible P ∧ P.IsHomogeneous P.totalDegree)
    (hD' : ∀ P ∈ D'.support, Irreducible P ∧ P.IsHomogeneous P.totalDegree) :
    (∃ (n : ℕ) (F G : MvPolynomial (Fin 3) ℂ), F ≠ 0 ∧ G ≠ 0 ∧
        F.IsHomogeneous n ∧ G.IsHomogeneous n ∧
        Associated (F * (D - D').prod fun P k => P ^ (-k).toNat)
          (G * (D - D').prod fun P k => P ^ k.toNat)) ↔
      (D.sum fun P k => k * (P.totalDegree : ℤ)) = D'.sum fun P k => k * (P.totalDegree : ℤ) := by
  have hE : ∀ P ∈ (D - D').support, P ≠ 0 ∧ P.IsHomogeneous P.totalDegree := by
    intro P hP
    rw [Finsupp.mem_support_iff, Finsupp.sub_apply] at hP
    by_cases h : D P = 0
    · have h' : P ∈ D'.support := by
        rw [Finsupp.mem_support_iff]; intro h'; rw [h, h', sub_zero] at hP; exact hP rfl
      exact ⟨(hD' P h').1.ne_zero, (hD' P h').2⟩
    · have h' : P ∈ D.support := Finsupp.mem_support_iff.mpr h
      exact ⟨(hD P h').1.ne_zero, (hD P h').2⟩
  rw [lb_key _ hE, Finsupp.sum_sub_index (fun _ _ _ => sub_mul _ _ _), sub_eq_zero]

/-- Every curve is a multiple of the line: on the complex projective plane each divisor D is
linearly equivalent to (deg D) copies of the line L = V(z), that is [D] = (deg D)[L]. -/
theorem divisor_class_eq_degree_times_line
    (D : MvPolynomial (Fin 3) ℂ →₀ ℤ)
    (hD : ∀ P ∈ D.support, Irreducible P ∧ P.IsHomogeneous P.totalDegree) :
    ∃ (n : ℕ) (F G : MvPolynomial (Fin 3) ℂ), F ≠ 0 ∧ G ≠ 0 ∧
      F.IsHomogeneous n ∧ G.IsHomogeneous n ∧
      Associated
        (F * (D - Finsupp.single (X 2) (D.sum fun P k => k * (P.totalDegree : ℤ))).prod
          fun P k => P ^ (-k).toNat)
        (G * (D - Finsupp.single (X 2) (D.sum fun P k => k * (P.totalDegree : ℤ))).prod
          fun P k => P ^ k.toNat) := by
  set d := D.sum fun P k => k * (P.totalDegree : ℤ) with hd
  have hE : ∀ P ∈ (D - Finsupp.single (X 2) d).support,
      P ≠ 0 ∧ P.IsHomogeneous P.totalDegree := by
    intro P hP
    by_cases h : D P = 0
    · rw [Finsupp.mem_support_iff, Finsupp.sub_apply, h, zero_sub, neg_ne_zero,
        Finsupp.single_apply_ne_zero] at hP
      obtain ⟨rfl, -⟩ := hP
      rw [totalDegree_X]
      exact ⟨X_ne_zero 2, isHomogeneous_X ℂ 2⟩
    · have h' : P ∈ D.support := Finsupp.mem_support_iff.mpr h
      exact ⟨(hD P h').1.ne_zero, (hD P h').2⟩
  refine (lb_key _ hE).mpr ?_
  rw [Finsupp.sum_sub_index (fun _ _ _ => sub_mul _ _ _),
    Finsupp.sum_single_index (zero_mul _), totalDegree_X, ← hd]
  simp

/-- A ratio of forms is a function on the plane only when the degrees match: scaling the
point's coordinates by a nonzero c multiplies F/G, with F of degree m and G of degree n, by
c^(m - n). Equal degrees give the same value at every representative of the point; C/L, of
degrees 2 and 1, doubles when the coordinates double. -/
theorem ratio_of_forms_scales {m n : ℕ} (F G : MvPolynomial (Fin 3) ℂ)
    (hF : F.IsHomogeneous m) (hG : G.IsHomogeneous n) (c : ℂ) (hc : c ≠ 0) (v : Fin 3 → ℂ) :
    eval (c • v) F / eval (c • v) G = c ^ ((m : ℤ) - n) * (eval v F / eval v G) := by
  rw [lb_eval_smul F hF, lb_eval_smul G hG, mul_div_mul_comm, zpow_sub₀ hc, zpow_natCast,
    zpow_natCast]

-- f = E/(C L) at (1 : 2 : 3), with E = y^2 z - x^3 + 2z^3, C = x^2 + y^2 - 34z^2, L = z: -65/903.
example : ((2 : ℚ) ^ 2 * 3 - 1 ^ 3 + 2 * 3 ^ 3) / ((1 ^ 2 + 2 ^ 2 - 34 * 3 ^ 2) * 3) = -65 / 903 := by
  norm_num
-- The same at (2 : 4 : 6) and at (-5 : -10 : -15): f is a function.
example : ((4 : ℚ) ^ 2 * 6 - 2 ^ 3 + 2 * 6 ^ 3) / ((2 ^ 2 + 4 ^ 2 - 34 * 6 ^ 2) * 6) = -65 / 903 := by
  norm_num
example : ((-10 : ℚ) ^ 2 * (-15) - (-5) ^ 3 + 2 * (-15) ^ 3) /
    (((-5) ^ 2 + (-10) ^ 2 - 34 * (-15) ^ 2) * (-15)) = -65 / 903 := by
  norm_num
-- Values E = 65, C = -301, L = 3 at (1 : 2 : 3), and the degree of D = E - C - L is 3 - 2 - 1 = 0.
example : (2 : ℤ) ^ 2 * 3 - 1 ^ 3 + 2 * 3 ^ 3 = 65 ∧ (1 : ℤ) ^ 2 + 2 ^ 2 - 34 * 3 ^ 2 = -301 ∧
    (3 : ℤ) - 2 - 1 = 0 := by
  norm_num
-- The gluing rule at (1 : 2 : 3): (E/z^3) / (E/x^3) = (65/27) / 65 = 1/27 = (1/3)^3.
example : ((65 : ℚ) / 27) / 65 = 1 / 27 ∧ ((1 : ℚ) / 3) ^ 3 = 1 / 27 := by norm_num
-- Mistake 1: C/L at (2 : 4 : 6) is 2 times C/L at (1 : 2 : 3).
example : ((2 : ℚ) ^ 2 + 4 ^ 2 - 34 * 6 ^ 2) / 6 = 2 * ((1 ^ 2 + 2 ^ 2 - 34 * 3 ^ 2) / 3) := by
  norm_num
-- Sections of O(d) for d = 1, 2, 3: the monomials x^a y^b z^e with a + b + e = d number 3, 6, 10.
example : ((Finset.univ : Finset (Fin 2 × Fin 2 × Fin 2)).filter
    (fun t => t.1.val + t.2.1.val + t.2.2.val = 1)).card = 3 := by decide
example : ((Finset.univ : Finset (Fin 3 × Fin 3 × Fin 3)).filter
    (fun t => t.1.val + t.2.1.val + t.2.2.val = 2)).card = 6 := by decide
example : ((Finset.univ : Finset (Fin 4 × Fin 4 × Fin 4)).filter
    (fun t => t.1.val + t.2.1.val + t.2.2.val = 3)).card = 10 := by decide
-- Bezout by elimination: x^3 + x^2 - 36 = (x - 3)(x^2 + 4x + 12), and (2h)(3h) = 6.
example (x : ℤ) : x ^ 3 + x ^ 2 - 36 = (x - 3) * (x ^ 2 + 4 * x + 12) := by ring
example : (2 : ℤ) * 3 = 6 := by norm_num
-- (3, 5) lies on both curves: 3^2 + 5^2 = 34 and 5^2 = 3^3 - 2.
example : (3 : ℤ) ^ 2 + 5 ^ 2 = 34 ∧ (5 : ℤ) ^ 2 = 3 ^ 3 - 2 := by norm_num
-- The slope m = -3/5 gives (3m^2 - 10m - 3 : -5m^2 - 6m + 5 : m^2 + 1) = (3 : 5 : 1).
example : (3 * (-3/5 : ℚ) ^ 2 - 10 * (-3/5) - 3) / ((-3/5 : ℚ) ^ 2 + 1) = 3 ∧
    (-5 * (-3/5 : ℚ) ^ 2 - 6 * (-3/5) + 5) / ((-3/5 : ℚ) ^ 2 + 1) = 5 := by
  norm_num
-- The torus y^2 = x^3 - x: pole orders 2a + 3b of x^a y^b (b = 0, 1) never equal 1.
example : ∀ a b : Fin 5, b.val < 2 → 2 * a.val + 3 * b.val ≠ 1 := by decide
-- Reed-Solomon (255, 223): distance 255 - 223 + 1 = 33, corrects (255 - 223)/2 = 16 errors.
example : 255 - 223 + 1 = 33 ∧ (255 - 223) / 2 = 16 := by norm_num
-- Hodge numbers: b2 of the plane is 0 + 1 + 0 = 1; of the quartic surface 1 + 20 + 1 = 22.
example : 0 + 1 + 0 = 1 ∧ 1 + 20 + 1 = 22 := by norm_num

#print axioms linearly_equivalent_iff_same_degree
#print axioms divisor_class_eq_degree_times_line
#print axioms ratio_of_forms_scales
