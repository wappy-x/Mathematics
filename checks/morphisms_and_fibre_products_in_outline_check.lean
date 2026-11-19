-- Morphisms of schemes: a ring map pulls prime ideals back to prime ideals, the point (3, 5) of y² = x³ + t goes to t = -2, and only the fibre over t = 0 is singular.
import Mathlib.RingTheory.Ideal.Maps
import Mathlib.RingTheory.Polynomial.Ideal
import Mathlib.Algebra.MvPolynomial.Basic
import Mathlib.Algebra.Polynomial.AlgebraMap
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Algebra.MvPolynomial.Polynomial

open MvPolynomial

/-- Points go forward because prime ideals pull back: for a ring map
`φ : A → B` that keeps sums, products and 1, the pullback
`φ⁻¹(𝔭) = {f : φ(f) ∈ 𝔭}` of a prime ideal `𝔭` of `B` is a prime ideal of `A`.
So every point of `Spec B` has a definite image in `Spec A`. -/
theorem pullback_of_prime_is_prime {A B : Type*} [CommRing A] [CommRing B]
    (φ : A →+* B) (𝔭 : Ideal B) (h𝔭 : 𝔭.IsPrime) : (𝔭.comap φ).IsPrime := by
  exact Ideal.comap_isPrime φ 𝔭

/-- The point (3, 5), the maximal ideal `⟨x - 3, y - 5⟩` of `ℚ[x, y]`, contracts
along the ring map `φ : ℚ[t] → ℚ[x, y]`, `t ↦ y² - x³`, to the ideal `⟨t + 2⟩`:
the point t = -2. Here `X 0` is x and `X 1` is y. -/
theorem contraction_of_three_five :
    Ideal.comap (Polynomial.aeval (X 1 ^ 2 - X 0 ^ 3 : MvPolynomial (Fin 2) ℚ))
        (Ideal.span {X 0 - C 3, X 1 - C 5}) =
      Ideal.span {Polynomial.X + Polynomial.C (2 : ℚ)} := by
  apply le_antisymm
  · intro p hp
    rw [Ideal.mem_comap] at hp
    let e : MvPolynomial (Fin 2) ℚ →ₐ[ℚ] ℚ := MvPolynomial.aeval ![(3 : ℚ), 5]
    have hle : Ideal.span {X 0 - C 3, X 1 - C 5} ≤ RingHom.ker e := by
      rw [Ideal.span_le]
      intro q hq
      simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hq
      rcases hq with rfl | rfl <;> simp [e]
    have h0 : e (Polynomial.aeval (X 1 ^ 2 - X 0 ^ 3 : MvPolynomial (Fin 2) ℚ) p) = 0 :=
      (RingHom.mem_ker).1 (hle hp)
    rw [← Polynomial.aeval_algHom_apply] at h0
    have he : e (X 1 ^ 2 - X 0 ^ 3 : MvPolynomial (Fin 2) ℚ) = -2 := by
      simp [e]; norm_num
    rw [he, Polynomial.coe_aeval_eq_eval] at h0
    have hX : (Polynomial.X + Polynomial.C (2 : ℚ)) = Polynomial.X - Polynomial.C (-2) := by
      simp [sub_eq_add_neg]
    rw [Ideal.mem_span_singleton, hX, Polynomial.dvd_iff_isRoot]
    exact h0
  · rw [Ideal.span_le, Set.singleton_subset_iff, SetLike.mem_coe, Ideal.mem_comap]
    have hm : Polynomial.aeval (X 1 ^ 2 - X 0 ^ 3 : MvPolynomial (Fin 2) ℚ)
        (Polynomial.X + Polynomial.C (2 : ℚ)) =
        (X 1 + C 5) * (X 1 - C 5) - (X 0 ^ 2 + C 3 * X 0 + C 9) * (X 0 - C 3) := by
      simp only [map_add, Polynomial.aeval_X, Polynomial.aeval_C, MvPolynomial.algebraMap_eq]
      rw [show (C 2 : MvPolynomial (Fin 2) ℚ) = 2 from map_ofNat C 2,
        show (C 3 : MvPolynomial (Fin 2) ℚ) = 3 from map_ofNat C 3,
        show (C 5 : MvPolynomial (Fin 2) ℚ) = 5 from map_ofNat C 5,
        show (C 9 : MvPolynomial (Fin 2) ℚ) = 9 from map_ofNat C 9]
      ring
    rw [hm]
    apply sub_mem
    · exact Ideal.mul_mem_left _ _ (Ideal.subset_span (by simp))
    · exact Ideal.mul_mem_left _ _ (Ideal.subset_span (by simp))

/-- Only the fibre over 0 degenerates: over a field where 2 and 3 are not zero,
the fibre `y² = x³ + t` has a singular point (the equation and both slopes
`-3x²` and `2y` vanish) exactly when `t = 0`. -/
theorem fibre_singular_iff_t_eq_zero {K : Type*} [Field K]
    (h2 : (2 : K) ≠ 0) (h3 : (3 : K) ≠ 0) (t : K) :
    (∃ x y : K, y ^ 2 = x ^ 3 + t ∧ -3 * x ^ 2 = 0 ∧ 2 * y = 0) ↔ t = 0 := by
  constructor
  · rintro ⟨x, y, h, hx, hy⟩
    have hx0 : x = 0 := by
      have : x ^ 2 = 0 := by
        have h3' : (-3 : K) ≠ 0 := neg_ne_zero.mpr h3
        exact (mul_eq_zero.mp hx).resolve_left h3'
      exact pow_eq_zero_iff (two_ne_zero) |>.mp this
    have hy0 : y = 0 := (mul_eq_zero.mp hy).resolve_left h2
    subst hx0; subst hy0
    simpa using h.symm
  · rintro rfl
    exact ⟨0, 0, by ring, by ring, by ring⟩

-- Images of (3, 5) and (2, 3) under (x, y) ↦ y² - x³.
example : (5 : ℤ) ^ 2 - 3 ^ 3 = -2 := by norm_num
example : (3 : ℤ) ^ 2 - 2 ^ 3 = 1 := by norm_num

-- The pullback of t² - 4, checked at (3, 5).
example : ((5 : ℤ) ^ 2 - 3 ^ 3) ^ 2 - 4 = 0 := by norm_num

-- The cofactor identity that puts φ(t + 2) inside ⟨x - 3, y - 5⟩.
example (x y : ℤ) :
    (y + 5) * (y - 5) - (x ^ 2 + 3 * x + 9) * (x - 3) = y ^ 2 - x ^ 3 + 2 := by ring

-- Fibre sizes over F_7 for t = 0, ..., 6: 7, 11, 8, 12, 2, 6, 3.
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + 0)).card = 7 := by decide
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + 1)).card = 11 := by decide
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + 2)).card = 8 := by decide
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + 3)).card = 12 := by decide
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + 4)).card = 2 := by decide
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + 5)).card = 6 := by decide
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + 6)).card = 3 := by decide
example : 7 + 11 + 8 + 12 + 2 + 6 + 3 = 7 ^ 2 := by norm_num

-- X ×_S Y over F_7 with t eliminated: y² = x³ + u⁶ has 73 points, 7 × 1 + 11 × 6.
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7 × ZMod 7)).filter
    (fun p => p.2.1 ^ 2 = p.1 ^ 3 + p.2.2 ^ 6)).card = 73 := by decide
example : 7 * 1 + 11 * 6 = 73 := by norm_num
-- The plain product without the agreement equation: 49 × 7 = 343.
example : 49 * 7 = 343 := by norm_num

-- The fibre over 0 over F_7 has exactly one singular point.
example : ((Finset.univ : Finset (ZMod 7 × ZMod 7)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 ∧ -3 * p.1 ^ 2 = 0 ∧ 2 * p.2 = 0)).card = 1 := by decide

-- The discriminant -16(4a³ + 27b²) at a = 0, b = -2 is -1728 = -432 × (-2)².
example : (-16 : ℤ) * (4 * 0 ^ 3 + 27 * (-2) ^ 2) = -1728 := by norm_num
example : (-432 : ℤ) * (-2) ^ 2 = -1728 := by norm_num

#print axioms pullback_of_prime_is_prime
#print axioms contraction_of_three_five
#print axioms fibre_singular_iff_t_eq_zero
