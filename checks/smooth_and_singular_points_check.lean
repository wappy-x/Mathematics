-- Smooth and singular points: the Jacobian rank test gives the tangent space dimension n − rank J(P), the cone x² + y² = z² is singular only at its apex, and so is its slice by the plane 4z = 5y.
import Mathlib.RingTheory.Nullstellensatz
import Mathlib.RingTheory.KrullDimension.Polynomial
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.Data.ZMod.Basic

open MvPolynomial

/-- The Jacobian criterion. Let V be the zero set of equations f₁, …, f_s in n unknowns over a
field k, where the equations generate the vanishing ideal I(V), and let P be a point of V.
Let J(P) be the matrix of partial derivatives ∂fᵢ/∂xⱼ at P and let the tangent space T_P V be
the directions v with J(P) v = 0. Then dim T_P V = n − rank J(P), and P is smooth
(dim T_P V = dim V, the Krull dimension of the coordinate ring k[V]) exactly when
rank J(P) = n − dim V, written here as rank J(P) + dim V = n. -/
theorem jacobian_criterion_rank_test {k : Type*} [Field k] {n s : ℕ}
    (f : Fin s → MvPolynomial (Fin n) k) (V : Set (Fin n → k))
    (hV : V = zeroLocus k (Ideal.span (Set.range f)))
    (hI : vanishingIdeal k V = Ideal.span (Set.range f))
    (P : Fin n → k) (hP : P ∈ V) :
    let J : Matrix (Fin s) (Fin n) k := Matrix.of fun i j => eval P (pderiv j (f i))
    Module.finrank k (LinearMap.ker J.mulVecLin) = n - J.rank ∧
      (((Module.finrank k (LinearMap.ker J.mulVecLin) : ℕ) : WithBot ℕ∞) =
          ringKrullDim (MvPolynomial (Fin n) k ⧸ vanishingIdeal k V) ↔
        ((J.rank : ℕ) : WithBot ℕ∞) +
          ringKrullDim (MvPolynomial (Fin n) k ⧸ vanishingIdeal k V) = n) := by
  intro J
  have hrn := LinearMap.finrank_range_add_finrank_ker J.mulVecLin
  rw [Module.finrank_fin_fun] at hrn
  have hr : J.rank + Module.finrank k (LinearMap.ker J.mulVecLin) = n := hrn
  have hker : Module.finrank k (LinearMap.ker J.mulVecLin) = n - J.rank := by omega
  refine ⟨hker, ?_⟩
  generalize ringKrullDim (MvPolynomial (Fin n) k ⧸ vanishingIdeal k V) = d
  generalize Module.finrank k (LinearMap.ker J.mulVecLin) = a at hr
  generalize J.rank = r at hr
  subst hr
  constructor
  · rintro rfl
    norm_cast
  · intro h
    induction d using WithBot.recBotCoe with
    | bot =>
      exfalso
      have : ((r : ℕ) : WithBot ℕ∞) + ⊥ = ⊥ := WithBot.add_bot _
      rw [this] at h
      exact WithBot.bot_ne_coe (a := ((r + a : ℕ) : ℕ∞)) (by simpa using h)
    | coe e =>
      induction e using ENat.recTopCoe with
      | top =>
        exfalso
        have : ((r : ℕ) : WithBot ℕ∞) + ((⊤ : ℕ∞) : WithBot ℕ∞) = ((⊤ : ℕ∞) : WithBot ℕ∞) := by
          rw [← WithBot.coe_natCast, ← WithBot.coe_add]; simp
        rw [this] at h
        exact ENat.top_ne_natCast _ (WithBot.coe_injective (h.trans (WithBot.coe_natCast _).symm))
      | coe m =>
        have : r + m = r + a := by exact_mod_cast h
        have : m = a := by omega
        subst this; rfl

/-- The cone x² + y² − z² = 0 has exactly one singular point, its apex: the only point where the
equation and its three partial derivatives 2x, 2y, −2z all vanish is (0, 0, 0). This holds over
ℝ, ℂ, 𝔽₇ and 𝔽₁₃, over any field where 2 ≠ 0; over 𝔽₂ it fails. -/
theorem cone_singular_locus_is_apex {k : Type*} [Field k] (h2 : (2 : k) ≠ 0) :
    {P : Fin 3 → k | eval P (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) k) = 0 ∧
      ∀ j, eval P (pderiv j (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) k)) = 0} = {0} := by
  ext P
  simp only [Set.mem_ofPred_eq, Set.mem_singleton_iff, Fin.forall_fin_succ, IsEmpty.forall_iff, and_true]
  simp [h2]
  constructor
  · rintro ⟨-, h0, h1, h2'⟩
    funext i
    fin_cases i <;> simp [h0, h1, h2']
  · rintro rfl
    simp

/-- The slice of the cone by the plane 4z = 5y, a curve in 3-space cut by two equations, over ℝ or
ℂ (any field of characteristic zero): at a point P of the curve, the Jacobian matrix with rows
(2x, 2y, −2z) and (0, −5, 4) has rank below the needed 3 − 1 = 2 exactly when P is the apex, where
the slice's two lines cross. -/
theorem slice_singular_only_at_apex {k : Type*} [Field k] [CharZero k] (P : Fin 3 → k)
    (hcone : eval P (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) k) = 0)
    (hplane : eval P (4 * X 2 - 5 * X 1 : MvPolynomial (Fin 3) k) = 0) :
    let J : Matrix (Fin 2) (Fin 3) k := Matrix.of fun i j =>
      eval P (pderiv j (![X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2, 4 * X 2 - 5 * X 1] i))
    J.rank < 2 ↔ P = 0 := by
  intro J
  have hle : J.rank ≤ 2 := J.rank_le_height
  have key : J.rank < 2 ↔ ¬ LinearIndependent k J.row := by
    rw [linearIndependent_iff_card_eq_finrank_span, Set.finrank, ← Matrix.rank_eq_finrank_span_row,
      Fintype.card_fin]; omega
  rw [key, Fintype.linearIndependent_iff]
  simp only [Fin.sum_univ_two, not_forall, Fin.forall_fin_two]
  have hJ : ∀ i j, J.row i j = J i j := fun _ _ => rfl
  simp only [J, Matrix.row, Matrix.of_apply] at *
  have h4 : (4 : MvPolynomial (Fin 3) k) = C 4 := (map_ofNat C 4).symm
  have h5 : (5 : MvPolynomial (Fin 3) k) = C 5 := (map_ofNat C 5).symm
  simp [h4, h5, pderiv_X, Pi.single_apply, funext_iff, Fin.forall_fin_succ] at *
  constructor
  · rintro ⟨x, ⟨e0, e1, e2⟩, hx⟩
    have ha : x 0 ≠ 0 := by
      intro ha
      apply hx ha
      have : x 1 * (-5) = 0 := by linear_combination e1 - 2 * P 1 * ha
      simpa using this
    have hb : x 1 = 0 := by
      have : (9 : k) * x 1 = 0 := by
        linear_combination -(2 * x 0 * hplane) - 5 * e1 - 4 * e2
      simpa using this
    have p1 : P 1 = 0 := by rw [hb] at e1; simpa [ha] using e1
    have p2 : P 2 = 0 := by rw [hb] at e2; simpa [ha] using e2
    exact ⟨e0.resolve_left ha, p1, p2⟩
  · rintro ⟨h0, h1, h2⟩
    refine ⟨![1, 0], ?_, by simp⟩
    simp [h0, h1, h2]

-- P = (3, 4, 5) is on the cone: 3² + 4² − 5² = 0.
example : (3 : ℤ) ^ 2 + 4 ^ 2 - 5 ^ 2 = 0 := by norm_num
-- The gradient (2x, 2y, −2z) at P is (6, 8, −10).
example : ((2 : ℤ) * 3, (2 : ℤ) * 4, (-2 : ℤ) * 5) = (6, 8, -10) := by norm_num
-- The tangent plane 3x + 4y − 5z = 0 contains P itself, the line from the apex through P.
example : (3 : ℤ) * 3 + 4 * 4 - 5 * 5 = 0 := by norm_num
-- Implicit slopes at P: z_x = −6/(−10) = 3/5 and z_y = −8/(−10) = 4/5.
example : -(6 : ℚ) / (-10) = 3 / 5 ∧ -(8 : ℚ) / (-10) = 4 / 5 := by norm_num
-- Line test at P: direction (1, 0, 0) gives 6t + t², order 1.
example : ∀ t : ℤ, (3 + t) ^ 2 + 4 ^ 2 - 5 ^ 2 = 6 * t + t ^ 2 := by intro t; ring
-- Line test at P: direction (−1, 2, 1), inside the tangent plane, gives 4t², order 2.
example : ∀ t : ℤ, (3 - t) ^ 2 + (4 + 2 * t) ^ 2 - (5 + t) ^ 2 = 4 * t ^ 2 := by intro t; ring
-- Line test at the apex: direction (0, 1, 1) gives 0, the line lies in the cone.
example : ∀ t : ℤ, (0 * t) ^ 2 + t ^ 2 - t ^ 2 = 0 := by intro t; ring
-- Slice 4z = 5y: the 2 × 2 minors −10x, 8x, 8y − 10z at P = (3, 4, 5) are −30, 24, −18, not all zero.
example : (2 * 3 * (-5) : ℤ) = -30 ∧ (2 * 3 * 4 : ℤ) = 24 ∧ (2 * 4 * 4 - (-2 * 5) * (-5) : ℤ) = -18 := by
  norm_num
-- Over 𝔽₇ the cone has 49 = 7² points, and exactly 1 of them has zero gradient.
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 × ZMod 7 =>
    p.1 ^ 2 + p.2.1 ^ 2 - p.2.2 ^ 2 = 0).card = 49 := by decide
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 × ZMod 7 =>
    p.1 ^ 2 + p.2.1 ^ 2 - p.2.2 ^ 2 = 0 ∧ 2 * p.1 = 0 ∧ 2 * p.2.1 = 0 ∧ -2 * p.2.2 = 0).card = 1 := by
  decide
-- Over 𝔽₇ the slice 4z = 5y has 13 = 2 · 7 − 1 points.
example : (Finset.univ.filter fun p : ZMod 7 × ZMod 7 × ZMod 7 =>
    p.1 ^ 2 + p.2.1 ^ 2 - p.2.2 ^ 2 = 0 ∧ 4 * p.2.2 = 5 * p.2.1).card = 13 := by decide
-- Over 𝔽₂ the cone has 4 points and all 4 have zero gradient, since 2 = 0 there.
example : (Finset.univ.filter fun p : ZMod 2 × ZMod 2 × ZMod 2 =>
    p.1 ^ 2 + p.2.1 ^ 2 - p.2.2 ^ 2 = 0 ∧ 2 * p.1 = 0 ∧ 2 * p.2.1 = 0 ∧ -2 * p.2.2 = 0).card = 4 := by
  decide
-- The hyperboloid x² + y² − z² − 1 gives −1 at the origin, so the origin is not on it.
example : (0 : ℤ) ^ 2 + 0 ^ 2 - 0 ^ 2 - 1 = -1 := by norm_num

#print axioms jacobian_criterion_rank_test
#print axioms cone_singular_locus_is_apex
#print axioms slice_singular_only_at_apex
