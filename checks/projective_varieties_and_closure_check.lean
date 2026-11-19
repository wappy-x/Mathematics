-- Projective varieties: the padded lens equation xy = z^2 is exactly the projective closure of the hyperbola xy = 1, it adds the two points (1 : 0 : 0) and (0 : 1 : 0), and a system must be padded through a graded basis, not equation by equation.
import Mathlib.LinearAlgebra.Projectivization.Basic
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.FieldTheory.IsAlgClosed.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.MvPolynomial.Polynomial
import Mathlib.Algebra.Polynomial.Roots

open MvPolynomial
open scoped LinearAlgebra.Projectivization

namespace ProjectiveClosure

variable {k : Type*} [Field k]

/-- The common zeros, in the projective plane, of a set of polynomials in x, y, z
(read at a representative of each point; for homogeneous polynomials every representative
gives the same answer). -/
def projZeros (S : Set (MvPolynomial (Fin 3) k)) : Set (ℙ k (Fin 3 → k)) :=
  {p | ∀ G ∈ S, eval p.rep G = 0}

/-- The point (a : b : 1) of the projective plane: the affine point (a, b) in the chart z = 1. -/
def chartZ (a b : k) : ℙ k (Fin 3 → k) :=
  Projectivization.mk k ![a, b, 1] (fun h => by simpa using congrFun h 2)

/-- The point (a : b : c) of the projective plane with a ≠ 0. -/
def ptX (a b c : k) (ha : a ≠ 0) : ℙ k (Fin 3 → k) :=
  Projectivization.mk k ![a, b, c] (fun h => ha (by simpa using congrFun h 0))

/-- The point (0 : 1 : 0), the beam case. -/
def ptBeam : ℙ k (Fin 3 → k) :=
  Projectivization.mk k ![0, 1, 0] (fun h => by simpa using congrFun h 1)

/-- The lens curve xy = 1, placed in the projective plane through the chart z = 1. -/
def lens (k : Type*) [Field k] : Set (ℙ k (Fin 3 → k)) :=
  {p | ∃ a b : k, a * b = 1 ∧ p = chartZ a b}

/-- The padded lens equation F = xy - z^2. -/
noncomputable def lensF : MvPolynomial (Fin 3) k := X 0 * X 1 - X 2 ^ 2

lemma eval_smul_of_isHomogeneous {G : MvPolynomial (Fin 3) k} {n : ℕ} (hG : G.IsHomogeneous n)
    (c : k) (v : Fin 3 → k) : eval (c • v) G = c ^ n * eval v G := by
  rw [eval_eq, eval_eq, Finset.mul_sum]
  refine Finset.sum_congr rfl fun d hd => ?_
  rw [hG.degree_eq_sum_deg_support hd]
  simp only [Pi.smul_apply, smul_eq_mul, mul_pow, Finset.prod_mul_distrib,
    Finset.prod_pow_eq_pow_sum]
  ring

#print axioms eval_smul_of_isHomogeneous

lemma rep_mk_eq_smul (v : Fin 3 → k) (hv : v ≠ 0) :
    ∃ c : k, c ≠ 0 ∧ (Projectivization.mk k v hv).rep = c • v := by
  obtain ⟨a, ha⟩ := (Projectivization.mk_eq_mk_iff k _ _ (Projectivization.rep_ne_zero _) hv).mp
    (Projectivization.mk_rep (Projectivization.mk k v hv))
  exact ⟨a, a.ne_zero, by rw [← ha, Units.smul_def]⟩

#print axioms rep_mk_eq_smul

lemma rep_eq_smul_of_eq_mk (p : ℙ k (Fin 3 → k)) (v : Fin 3 → k) (hv : v ≠ 0)
    (hp : p = Projectivization.mk k v hv) : ∃ c : k, c ≠ 0 ∧ p.rep = c • v := by
  subst hp
  exact rep_mk_eq_smul v hv

#print axioms rep_eq_smul_of_eq_mk

lemma eq_mk_of_rep_eq_smul (p : ℙ k (Fin 3 → k)) (w : Fin 3 → k) (hw : w ≠ 0) (c : k)
    (h : p.rep = c • w) : p = Projectivization.mk k w hw := by
  rw [← Projectivization.mk_rep p]
  exact (Projectivization.mk_eq_mk_iff' k _ _ _ hw).mpr ⟨c, h.symm⟩

#print axioms eq_mk_of_rep_eq_smul

lemma eval_zero_of_forall_ne_zero [Infinite k] (G : MvPolynomial (Fin 3) k)
    (g : Fin 3 → Polynomial k) (h : ∀ t : k, t ≠ 0 → eval (fun i => (g i).eval t) G = 0) :
    eval (fun i => (g i).eval 0) G = 0 := by
  have key : ∀ t : k, (eval₂ Polynomial.C g G).eval t = eval (fun i => (g i).eval t) G := by
    intro t
    rw [MvPolynomial.polynomial_eval_eval₂]
    have : (Polynomial.evalRingHom t).comp Polynomial.C = RingHom.id k :=
      RingHom.ext fun x => by simp
    rw [this]
    rfl
  have hP : eval₂ Polynomial.C g G = 0 := by
    apply Polynomial.eq_zero_of_infinite_isRoot
    refine (Set.finite_singleton (0 : k)).infinite_compl.mono ?_
    intro t ht
    simp only [Set.mem_compl_iff, Set.mem_singleton_iff] at ht
    simp only [Set.mem_ofPred_eq, Polynomial.IsRoot.def, key]
    exact h t ht
  rw [← key, hP, Polynomial.eval_zero]

#print axioms eval_zero_of_forall_ne_zero

lemma eval_lens_of_subset {S : Set (MvPolynomial (Fin 3) k)} (hlens : lens k ⊆ projZeros S)
    {G : MvPolynomial (Fin 3) k} (hG : G ∈ S) {n : ℕ} (hn : G.IsHomogeneous n) (a b : k)
    (hab : a * b = 1) : eval ![a, b, 1] G = 0 := by
  have h1 := hlens ⟨a, b, hab, rfl⟩ G hG
  obtain ⟨c, hc, hrep⟩ := rep_eq_smul_of_eq_mk (chartZ a b) ![a, b, 1] _ rfl
  rw [hrep, eval_smul_of_isHomogeneous hn] at h1
  exact (mul_eq_zero.mp h1).resolve_left (pow_ne_zero _ hc)

#print axioms eval_lens_of_subset

/-- Over an algebraically closed field such as ℂ, the projective closure of the hyperbola
xy = 1 is the conic xy = z^2: the conic contains the affine curve, and every projective
variety (the common zeros of some homogeneous polynomials) that contains the affine curve
contains the whole conic, including its points at infinity. -/
theorem projective_closure_of_xy_eq_one [IsAlgClosed k] :
    lens k ⊆ projZeros {lensF} ∧
      ∀ S : Set (MvPolynomial (Fin 3) k), (∀ G ∈ S, ∃ n, G.IsHomogeneous n) →
        lens k ⊆ projZeros S → projZeros {lensF} ⊆ projZeros S := by
  refine ⟨?_, ?_⟩
  · rintro p ⟨a, b, hab, rfl⟩ G hG
    rw [Set.mem_singleton_iff] at hG
    subst hG
    obtain ⟨c, hc, hrep⟩ := rep_eq_smul_of_eq_mk (chartZ a b) ![a, b, 1] _ rfl
    rw [hrep]
    simp [lensF]
    linear_combination c ^ 2 * hab
  · intro S hS hlens p hp G hG
    obtain ⟨n, hn⟩ := hS G hG
    have hF := hp lensF rfl
    simp only [lensF, map_sub, map_mul, map_pow, eval_X] at hF
    by_cases h2 : p.rep 2 = 0
    · rw [h2] at hF
      have h01 : p.rep 0 * p.rep 1 = 0 := by linear_combination hF
      rcases mul_eq_zero.mp h01 with h0 | h1
      · -- the beam (0 : 1 : 0)
        have hv : p.rep = p.rep 1 • ![0, 1, 0] := by
          ext i; fin_cases i <;> simp [h0, h2]
        rw [hv, eval_smul_of_isHomogeneous hn]
        have := eval_zero_of_forall_ne_zero G ![Polynomial.X ^ 2, 1, Polynomial.X] (by
          intro t ht
          have e : (fun i => (![Polynomial.X ^ 2, 1, Polynomial.X] i).eval t) =
              t • ![t, t⁻¹, 1] := by
            ext i; fin_cases i <;> simp [ht, pow_two]
          rw [e, eval_smul_of_isHomogeneous hn,
            eval_lens_of_subset hlens hG hn t t⁻¹ (mul_inv_cancel₀ ht), mul_zero])
        have e0 : (fun i => (![Polynomial.X ^ 2, 1, Polynomial.X] i).eval (0 : k)) =
            ![0, 1, 0] := by
          ext i; fin_cases i <;> simp
        rw [e0] at this
        rw [this, mul_zero]
      · -- the star (1 : 0 : 0)
        have hv : p.rep = p.rep 0 • ![1, 0, 0] := by
          ext i; fin_cases i <;> simp [h1, h2]
        rw [hv, eval_smul_of_isHomogeneous hn]
        have := eval_zero_of_forall_ne_zero G ![1, Polynomial.X ^ 2, Polynomial.X] (by
          intro t ht
          have e : (fun i => (![1, Polynomial.X ^ 2, Polynomial.X] i).eval t) =
              t • ![t⁻¹, t, 1] := by
            ext i; fin_cases i <;> simp [ht, pow_two]
          rw [e, eval_smul_of_isHomogeneous hn,
            eval_lens_of_subset hlens hG hn t⁻¹ t (inv_mul_cancel₀ ht), mul_zero])
        have e0 : (fun i => (![1, Polynomial.X ^ 2, Polynomial.X] i).eval (0 : k)) =
            ![1, 0, 0] := by
          ext i; fin_cases i <;> simp
        rw [e0] at this
        rw [this, mul_zero]
    · have hp' : p ∈ lens k := by
        refine ⟨p.rep 0 / p.rep 2, p.rep 1 / p.rep 2, ?_, ?_⟩
        · field_simp
          linear_combination hF
        · apply eq_mk_of_rep_eq_smul p _ _ (p.rep 2)
          ext i; fin_cases i <;> simp <;> field_simp
      exact hlens hp' G hG

/-- Setting z = 0 in the padded equation leaves its top-degree part xy, so the conic
xy = z^2 meets the line at infinity in exactly two points: the star (1 : 0 : 0) and the
beam (0 : 1 : 0). -/
theorem points_at_infinity_of_xy_eq_z_sq :
    {p ∈ projZeros ({lensF} : Set (MvPolynomial (Fin 3) k)) | eval p.rep (X 2) = 0} =
      {ptX 1 0 0 one_ne_zero, ptBeam} := by
  ext p
  simp only [Set.mem_sep_iff, Set.mem_insert_iff, Set.mem_singleton_iff, eval_X]
  constructor
  · rintro ⟨h1, h2⟩
    have hF := h1 lensF rfl
    simp only [lensF, map_sub, map_mul, map_pow, eval_X, h2] at hF
    have h01 : p.rep 0 * p.rep 1 = 0 := by linear_combination hF
    rcases mul_eq_zero.mp h01 with h0 | h1'
    · right
      exact eq_mk_of_rep_eq_smul p _ _ (p.rep 1) (by ext i; fin_cases i <;> simp [h0, h2])
    · left
      exact eq_mk_of_rep_eq_smul p _ _ (p.rep 0) (by ext i; fin_cases i <;> simp [h1', h2])
  · rintro (rfl | rfl)
    · obtain ⟨c, hc, hrep⟩ :=
        rep_eq_smul_of_eq_mk (ptX (k := k) 1 0 0 one_ne_zero) ![1, 0, 0] _ rfl
      rw [hrep]
      refine ⟨fun G hG => ?_, by simp⟩
      rw [Set.mem_singleton_iff] at hG
      subst hG
      simp [lensF, hrep]
    · obtain ⟨c, hc, hrep⟩ := rep_eq_smul_of_eq_mk (ptBeam (k := k)) ![0, 1, 0] _ rfl
      rw [hrep]
      refine ⟨fun G hG => ?_, by simp⟩
      rw [Set.mem_singleton_iff] at hG
      subst hG
      simp [lensF, hrep]

/-- Homogenise the ideal, not each equation: padding xy - 1 and y - 2 one by one gives
xy - z^2 and y - 2z, whose common zeros are the solution (1 : 4 : 2) and an extra point
(1 : 0 : 0); padding the graded Gröbner basis x - 1/2, y - 2 gives x - z/2 and y - 2z,
whose only common zero is (1 : 4 : 2), the closure of the one solution (1/2, 2). -/
theorem homogenise_graded_basis_not_equations (h2 : (2 : k) ≠ 0) :
    projZeros ({lensF, X 1 - C 2 * X 2} : Set (MvPolynomial (Fin 3) k)) =
        {ptX 1 4 2 one_ne_zero, ptX 1 0 0 one_ne_zero} ∧
      projZeros ({X 0 - C (1 / 2) * X 2, X 1 - C 2 * X 2} : Set (MvPolynomial (Fin 3) k)) =
        {ptX 1 4 2 one_ne_zero} := by
  refine ⟨?_, ?_⟩
  · ext p
    simp only [projZeros, Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
    constructor
    · intro h
      have hF := h lensF (Or.inl rfl)
      have hL := h (X 1 - C 2 * X 2) (Or.inr rfl)
      simp only [lensF, map_sub, map_mul, map_pow, eval_X, eval_C] at hF hL
      by_cases hc : p.rep 2 = 0
      · right
        have hb : p.rep 1 = 0 := by linear_combination hL + 2 * hc
        exact eq_mk_of_rep_eq_smul p _ _ (p.rep 0) (by ext i; fin_cases i <;> simp [hb, hc])
      · left
        have hca : p.rep 2 = 2 * p.rep 0 := by
          have : p.rep 2 * (p.rep 2 - 2 * p.rep 0) = 0 := by
            linear_combination -hF + p.rep 0 * hL
          linear_combination (mul_eq_zero.mp this).resolve_left hc
        refine eq_mk_of_rep_eq_smul p _ _ (p.rep 0) ?_
        ext i; fin_cases i
        · simp
        · simp; linear_combination hL + 2 * hca
        · simp; linear_combination hca
    · rintro (rfl | rfl) G hG
      · obtain ⟨c, hc, hrep⟩ :=
          rep_eq_smul_of_eq_mk (ptX (k := k) 1 4 2 one_ne_zero) ![1, 4, 2] _ rfl
        rw [hrep]
        rcases hG with rfl | rfl
        · simp [lensF]; ring
        · simp; ring
      · obtain ⟨c, hc, hrep⟩ :=
          rep_eq_smul_of_eq_mk (ptX (k := k) 1 0 0 one_ne_zero) ![1, 0, 0] _ rfl
        rw [hrep]
        rcases hG with rfl | rfl
        · simp [lensF]
        · simp
  · ext p
    simp only [projZeros, Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
    constructor
    · intro h
      have hA := h (X 0 - C (1 / 2) * X 2) (Or.inl rfl)
      have hB := h (X 1 - C 2 * X 2) (Or.inr rfl)
      simp only [map_sub, map_mul, eval_X, eval_C] at hA hB
      refine eq_mk_of_rep_eq_smul p _ _ (p.rep 2 / 2) ?_
      ext i; fin_cases i
      · simp; linear_combination hA
      · simp; field_simp; linear_combination 2 * hB
      · simp; field_simp
    · rintro rfl G hG
      obtain ⟨c, hc, hrep⟩ :=
        rep_eq_smul_of_eq_mk (ptX (k := k) 1 4 2 one_ne_zero) ![1, 4, 2] _ rfl
      rw [hrep]
      rcases hG with rfl | rfl
      · simp; field_simp; ring
      · simp; ring

/-- The number of points of the projective plane over ZMod p (each counted once, through
the representative whose first nonzero coordinate is 1) that satisfy a test. -/
def projCount (p : ℕ) [NeZero p] (P : ZMod p → ZMod p → ZMod p → Bool) : ℕ :=
  ((Finset.univ : Finset (ZMod p × ZMod p × ZMod p)).filter (fun v =>
    (v.1 = 1 ∨ (v.1 = 0 ∧ v.2.1 = 1) ∨ (v.1 = 0 ∧ v.2.1 = 0 ∧ v.2.2 = 1)) ∧
      P v.1 v.2.1 v.2.2 = true)).card

/-- The number of affine points (a, b) over ZMod p that satisfy a test. -/
def affCount (p : ℕ) [NeZero p] (P : ZMod p → ZMod p → Bool) : ℕ :=
  ((Finset.univ : Finset (ZMod p × ZMod p)).filter (fun v => P v.1 v.2 = true)).card

-- The object 100 mm out: x = 2, y = 1/2 is on xy = 1.
example : (2 : ℚ) * (1 / 2) - 1 = 0 := by norm_num
-- Its projective name (4 : 1 : 2) satisfies xy = z^2.
example : (4 : ℤ) * 1 - 2 ^ 2 = 0 := by norm_num
-- In the chart x = 1 the object sits at (1/4, 1/2) on the parabola y = z^2.
example : (1 / 4 : ℚ) = (1 / 2) ^ 2 := by norm_num
-- The house cone: (3 : 4 : 5) is on x^2 + y^2 = z^2, and its image (1 : 9 : 3) is on xy = z^2.
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 5 ^ 2 ∧ (5 - 4 : ℤ) * (5 + 4) = 3 ^ 2 := by norm_num
-- Over F_7: the affine lens curve has 6 points and its closure xy = z^2 has 8 = 7 + 1.
example : affCount 7 (fun a b => a * b == 1) = 6 := by decide
example : projCount 7 (fun x y z => x * y == z ^ 2) = 8 := by decide
-- Over F_7 the house cone x^2 + y^2 = z^2 also has 8 points.
example : projCount 7 (fun x y z => x ^ 2 + y ^ 2 == z ^ 2) = 8 := by decide
-- Padding xy - 1 and y - 2 one by one: 2 points over F_7; padding the basis (2x - z, y - 2z): 1.
example : projCount 7 (fun x y z => x * y == z ^ 2 && y == 2 * z) = 2 := by decide
example : projCount 7 (fun x y z => 2 * x == z && y == 2 * z) = 1 := by decide
-- x^2y - xz^2 has 15 points over F_7; after the round trip through x = 1 it has 8.
example : projCount 7 (fun x y z => x ^ 2 * y == x * z ^ 2) = 15 := by decide
-- The lex basis of {xy - 1, x^2 - y}, padded to {xz - y^2, y^3 - z^3}: 4 points over F_7;
-- the padded graded basis {x^2 - yz, xy - z^2, xz - y^2}: 3, the affine solutions.
example : affCount 7 (fun a b => a * b == 1 && b == a ^ 2) = 3 := by decide
example : projCount 7 (fun x y z => x * z == y ^ 2 && y ^ 3 == z ^ 3) = 4 := by decide
example : projCount 7 (fun x y z => x ^ 2 == y * z && x * y == z ^ 2 && x * z == y ^ 2) = 3 := by
  decide

#print axioms projective_closure_of_xy_eq_one
#print axioms points_at_infinity_of_xy_eq_z_sq
#print axioms homogenise_graded_basis_not_equations

end ProjectiveClosure
