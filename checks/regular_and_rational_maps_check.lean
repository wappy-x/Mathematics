-- Maps between varieties: regular maps match coordinate-ring maps one for one, the plane's polynomial map lands on the cone, and the camera from the cone's apex fails at the apex alone.
import Mathlib.RingTheory.Nullstellensatz
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.MvPolynomial.CommRing

open MvPolynomial

/-- A regular map from `V` to `W` (sets of points in `kⁿ` and `kᵐ`) is a list
`f = (f₁, …, fₘ)` of functions in the coordinate ring `k[V]` such that the pullback
of every equation of `W` is zero. Its pullback `ψ*` substitutes the `fᵢ` for the
target's coordinates. Regular maps match the `k`-algebra maps `k[W] → k[V]` one for
one, and the matching sends each map to substitution: `ψ*(g) = g(f₁, …, fₘ)`. -/
theorem regular_maps_match_coordinate_ring_maps {k : Type*} [Field k] {n m : ℕ}
    (V : Set (Fin n → k)) (W : Set (Fin m → k)) :
    ∃ e : {f : Fin m → MvPolynomial (Fin n) k ⧸ vanishingIdeal k V //
            ∀ g ∈ vanishingIdeal k W, aeval f g = 0} ≃
          ((MvPolynomial (Fin m) k ⧸ vanishingIdeal k W) →ₐ[k]
            (MvPolynomial (Fin n) k ⧸ vanishingIdeal k V)),
      ∀ f g, e f (Ideal.Quotient.mk (vanishingIdeal k W) g) = aeval f.1 g := by
  refine ⟨{
    toFun := fun f => Ideal.Quotient.liftₐ (vanishingIdeal k W) (aeval f.1) f.2
    invFun := fun φ => ⟨fun i => φ (Ideal.Quotient.mk _ (X i)), fun g hg => by
      have e : φ.comp (Ideal.Quotient.mkₐ k (vanishingIdeal k W)) =
          aeval (fun i => φ (Ideal.Quotient.mk (vanishingIdeal k W) (X i))) :=
        MvPolynomial.algHom_ext (fun i => by
          rw [AlgHom.comp_apply, Ideal.Quotient.mkₐ_eq_mk, aeval_X])
      rw [← e, AlgHom.comp_apply, Ideal.Quotient.mkₐ_eq_mk,
        Ideal.Quotient.eq_zero_iff_mem.mpr hg, map_zero]⟩
    left_inv := fun f => by
      apply Subtype.ext
      funext i
      exact aeval_X _ i
    right_inv := fun φ => by
      apply Ideal.Quotient.algHom_ext
      apply MvPolynomial.algHom_ext
      intro i
      exact aeval_X _ i }, ?_⟩
  intro f g
  rfl

/-- The camera `φ = (x : y : z)` projects the cone `x² + y² = z²` from its apex.
A formula for `φ` is a list `(F₀ : F₁ : F₂)` of polynomials that agrees with
`(x : y : z)` up to scale in the cone's coordinate ring, that is
`Fᵢ·x_j = F_j·xᵢ` once `x² + y² - z²` counts as zero. Over every field, the bad set
(the points of the cone where every formula gives the all-zero list) is exactly the
apex `(0, 0, 0)`. -/
theorem camera_bad_set_is_apex {k : Type*} [Field k] :
    {P : Fin 3 → k | P 0 ^ 2 + P 1 ^ 2 = P 2 ^ 2 ∧
      ∀ F : Fin 3 → MvPolynomial (Fin 3) k,
        (∀ i j, F i * X j - F j * X i ∈
          Ideal.span {(X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) k)}) →
        ∀ i, eval P (F i) = 0} = {0} := by
  ext P
  simp only [Set.mem_ofPred_eq, Set.mem_singleton_iff]
  constructor
  · rintro ⟨-, h⟩
    have hX := h (fun i => X i) (fun i j => by simp [mul_comm])
    funext i
    simpa using hX i
  · rintro rfl
    refine ⟨by simp, fun F hF i => ?_⟩
    rw [MvPolynomial.eval_zero]
    obtain ⟨c, hc⟩ := Ideal.mem_span_singleton'.mp (hF i (i + 1))
    have hij : i ≠ i + 1 := by fin_cases i <;> decide
    have key := congrArg (fun p : MvPolynomial (Fin 3) k => p.coeff (Finsupp.single (i + 1) 1)) hc
    have h1 : (F i * X (i + 1)).coeff (Finsupp.single (i + 1) 1) = constantCoeff (F i) := by
      have := MvPolynomial.coeff_mul_X (0 : Fin 3 →₀ ℕ) (i + 1) (F i)
      rw [zero_add] at this
      rw [this]
      rfl
    have h2 : (F (i + 1) * X i).coeff (Finsupp.single (i + 1) 1) = 0 := by
      classical
      rw [MvPolynomial.coeff_mul_X']
      simp [hij]
    have h3 : (c * (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) k)).coeff
        (Finsupp.single (i + 1) 1) = 0 := by
      classical
      have e : c * (X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2 : MvPolynomial (Fin 3) k) =
          c * monomial (Finsupp.single 0 2) 1 + c * monomial (Finsupp.single 1 2) 1
            - c * monomial (Finsupp.single 2 2) 1 := by
        simp only [X_pow_eq_monomial]; ring
      rw [e, coeff_sub, AddMonoidAlgebra.coeff_add, Finsupp.add_apply, MvPolynomial.coeff_mul_monomial',
        MvPolynomial.coeff_mul_monomial', MvPolynomial.coeff_mul_monomial']
      simp only [Finsupp.single_le_iff, Finsupp.single_apply]
      fin_cases i <;> simp
    rw [h3, coeff_sub, h1, h2, sub_zero] at key
    exact key.symm

/-- The plane's map `ψ(s, t) = (s² - t², 2st, s² + t²)` lands on the cone: putting it
into `x² + y² - z²` gives zero, as an identity of polynomials, over every field. -/
theorem psi_lands_on_cone {R : Type*} [CommRing R] (s t : R) :
    (s ^ 2 - t ^ 2) ^ 2 + (2 * s * t) ^ 2 = (s ^ 2 + t ^ 2) ^ 2 := by
  ring

-- ψ(2, 1) = (3, 4, 5) and ψ(3, 2) = (5, 12, 13), both on the cone.
example : ((2 : ℤ) ^ 2 - 1 ^ 2, 2 * 2 * 1, (2 : ℤ) ^ 2 + 1 ^ 2) = (3, 4, 5) := by norm_num
example : ((3 : ℤ) ^ 2 - 2 ^ 2, 2 * 3 * 2, (3 : ℤ) ^ 2 + 2 ^ 2) = (5, 12, 13) := by norm_num
example : (3 : ℤ) ^ 2 + 4 ^ 2 - 5 ^ 2 = 0 := by norm_num
example : (5 : ℤ) ^ 2 + 12 ^ 2 - 13 ^ 2 = 0 := by norm_num
-- z - x pulls back to 2t²: at (s, t) = (2, 1) it is 2, and at (3, 4, 5) it is 5 - 3 = 2.
example : ((2 : ℤ) ^ 2 + 1 ^ 2) - (2 ^ 2 - 1 ^ 2) = 2 * 1 ^ 2 ∧ (5 : ℤ) - 3 = 2 := by norm_num
-- Mistake 1: last entry s² + 2t² sends (2, 1) to (3, 4, 6), with cone value -11.
example : (2 : ℤ) ^ 2 + 2 * 1 ^ 2 = 6 ∧ (3 : ℤ) ^ 2 + 4 ^ 2 - 6 ^ 2 = -11 := by norm_num
-- Step 3 at degree 4: 15 monomials, 6 multiples of the cone's equation, 9 = 2·4 + 1 survive.
example : Nat.choose (4 + 2) 2 = 15 ∧ 4 * 3 / 2 = 6 ∧ 15 - 6 = 2 * 4 + 1 := by decide
-- Over F₁₃, -1 is a square: 5² = -1.
example : (5 : ZMod 13) ^ 2 = -1 := by decide
-- Over F₇ the cone has 49 points.
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7 × ZMod 7)).filter
    (fun v => v.1 ^ 2 + v.2.1 ^ 2 = v.2.2 ^ 2)).card = 49 := by decide
-- Over F₇, ψ reaches only 25 of the cone's 49 points.
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).image
    (fun v => (v.1 ^ 2 - v.2 ^ 2, 2 * v.1 * v.2, v.1 ^ 2 + v.2 ^ 2))).card = 25 := by decide
-- Aimed at the screen, the camera fails where z = 0: 1 cone point over F₇, 25 over F₁₃.
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun v => v.1 ^ 2 + v.2 ^ 2 = 0)).card = 1 := by decide
example : ((Finset.univ : Finset (ZMod 13 × ZMod 13)).filter
    (fun v => v.1 ^ 2 + v.2 ^ 2 = 0)).card = 25 := by decide

#print axioms regular_maps_match_coordinate_ring_maps
#print axioms camera_bad_set_is_apex
#print axioms psi_lands_on_cone
