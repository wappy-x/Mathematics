-- The Weil pairing: any pairing that multiplies in each slot and gives 1 on a point paired with itself is fixed on the span of P and T by the one value e(P, T) through the determinant rule, alternation follows from swapping when m is odd, and y² = x³ − x has p + 1 points mod every prime p that leaves 3 on division by 4.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Algebra.QuadraticAlgebra.Defs
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Algebra.Group.Int.Even
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.LegendreSymbol.QuadraticChar.Basic

open WeierstrassCurve

/-- The card's curve y² = x³ − x, over any commutative ring. -/
def curveE (R : Type*) [CommRing R] : WeierstrassCurve R :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := -1, a₆ := 0 }

/-- Helper: a pairing that multiplies in the left slot turns whole-number multiples there
into powers. -/
theorem pairing_zpow_left {M G : Type*} [AddCommGroup M] [CommGroup G] (e : M → M → G)
    (hleft : ∀ P P' Q, e (P + P') Q = e P Q * e P' Q) (n : ℤ) (P Q : M) :
    e (n • P) Q = e P Q ^ n := by
  let f : M →+ Additive G := AddMonoidHom.mk' (fun P => Additive.ofMul (e P Q)) (by
    intro a b; simp [hleft])
  have := map_zsmul f n P
  simpa [f] using congrArg Additive.toMul this

/-- Helper: the same for the right slot. -/
theorem pairing_zpow_right {M G : Type*} [AddCommGroup M] [CommGroup G] (e : M → M → G)
    (hright : ∀ P Q Q', e P (Q + Q') = e P Q * e P Q') (n : ℤ) (P Q : M) :
    e P (n • Q) = e P Q ^ n :=
  pairing_zpow_left (fun Q P => e P Q) (fun Q Q' P => hright P Q Q') n Q P

/-- The determinant rule. Let `e` be a pairing on a commutative group of points `M` with values
in a commutative group `G`, written multiplicatively. If `e` multiplies when either point is
added to (bilinear) and gives 1 on a point paired with itself (alternating), then on the span of
two points `P` and `T` it is fixed by the single value `e(P, T)`:
`e(aP + bT, cP + dT) = e(P, T)^(ad − bc)` for all whole numbers `a`, `b`, `c`, `d`.
With `T = ι(P)` this is the card's 120 × 120 check of `e₁₁`, and with `b = d = 0`, `c = 1`
it is the MOV identity `e(dP, T) = e(P, T)^d`. -/
theorem pairing_determinant_rule {M G : Type*} [AddCommGroup M] [CommGroup G] (e : M → M → G)
    (hleft : ∀ P P' Q, e (P + P') Q = e P Q * e P' Q)
    (hright : ∀ P Q Q', e P (Q + Q') = e P Q * e P Q')
    (halt : ∀ P, e P P = 1) (P T : M) (a b c d : ℤ) :
    e (a • P + b • T) (c • P + d • T) = e P T ^ (a * d - b * c) := by
  have hTP : e T P = (e P T)⁻¹ := by
    have h := halt (P + T)
    rw [hleft, hright, hright, halt, halt] at h
    rw [eq_inv_iff_mul_eq_one, mul_comm]
    simpa using h
  rw [hleft, pairing_zpow_left e hleft, pairing_zpow_left e hleft, hright, hright,
    pairing_zpow_right e hright, pairing_zpow_right e hright,
    pairing_zpow_right e hright, pairing_zpow_right e hright, halt, halt, hTP]
  simp only [one_zpow, one_mul, mul_one, inv_zpow', ← zpow_mul, ← zpow_add]
  congr 1; ring

/-- Alternation for odd m (the card's Step 4): if swapping the two points inverts the value,
and every value is an m-th root of unity with m odd, then every point pairs to 1 with itself. -/
theorem pairing_alternating_of_odd {M G : Type*} [CommGroup G] (e : M → M → G) (m : ℕ)
    (hswap : ∀ P Q, e P Q * e Q P = 1) (hroot : ∀ P Q, e P Q ^ m = 1) (hm : Odd m) (P : M) :
    e P P = 1 := by
  obtain ⟨k, rfl⟩ := hm
  have h2 := hswap P P
  have h := hroot P P
  rw [pow_succ, pow_mul, sq, h2, one_pow, one_mul] at h
  exact h

/-- The point count (the card's Step 6): for a prime p that leaves 3 on division by 4, the curve
y² = x³ − x over 𝔽_p has exactly p + 1 points, counting the point O at infinity. -/
theorem card_points_curveE_of_mod_four_eq_three (p : ℕ) [Fact p.Prime] (hp : p % 4 = 3) :
    Nat.card (curveE (ZMod p)).toAffine.Point = p + 1 := by
  classical
  have hp2 : p ≠ 2 := by rintro rfl; norm_num at hp
  have hchar : ringChar (ZMod p) ≠ 2 := by rw [ZMod.ringChar_zmod_n]; exact hp2
  have two_ne : (2 : ZMod p) ≠ 0 := by
    intro h
    have : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
    rw [ZMod.natCast_eq_zero_iff] at this
    exact hp2 ((Nat.prime_dvd_prime_iff_eq (Fact.out) Nat.prime_two).mp this)
  have : (curveE (ZMod p)).IsElliptic := by
    rw [isElliptic_iff]
    have : (curveE (ZMod p)).Δ = 2 ^ 6 := by
      simp only [Δ, b₂, b₄, b₆, b₈, curveE]; ring
    rw [this]
    exact (IsUnit.mk0 _ two_ne).pow 6
  set W := (curveE (ZMod p)).toAffine
  have eqv := (Equiv.subtypeUnivEquiv (fun _ => trivial)).symm.trans
    (Affine.pointEquivSubtype (W' := W) (p := fun _ => True) trivial)
  have hS : ∀ xy : ZMod p × ZMod p,
      (∃ _ : W.Equation xy.1 xy.2, True) ↔ xy.2 ^ 2 = xy.1 ^ 3 - xy.1 := by
    intro xy
    simp only [exists_prop, and_true, W, Affine.equation_iff, curveE]
    constructor <;> intro h <;> linear_combination h
  rw [Nat.card_congr (eqv.trans (Equiv.optionCongr (Equiv.subtypeEquivRight hS))),
    Nat.card_eq_fintype_card, Fintype.card_option, Fintype.card_subtype]
  congr 1
  rw [Finset.card_filter, Fintype.sum_prod_type]
  simp only [← Finset.card_filter]
  have hsq : ∀ a : ZMod p,
      ((Finset.univ.filter (fun y : ZMod p => y ^ 2 = a)).card : ℤ)
        = quadraticChar (ZMod p) a + 1 := by
    intro a
    rw [← quadraticChar_card_sqrts hchar a]
    simp
  have hneg : quadraticChar (ZMod p) (-1) = -1 := by
    rw [quadraticChar_neg_one_iff_not_isSquare, FiniteField.isSquare_neg_one_iff, ZMod.card]
    simp [hp]
  have hsum : ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - x) = 0 := by
    have h1 := Equiv.sum_comp (Equiv.neg (ZMod p)) (fun x => quadraticChar (ZMod p) (x ^ 3 - x))
    have h2 : ∀ x : ZMod p, quadraticChar (ZMod p) ((-x) ^ 3 - -x)
        = - quadraticChar (ZMod p) (x ^ 3 - x) := by
      intro x
      rw [show (-x) ^ 3 - -x = (-1) * (x ^ 3 - x) by ring, map_mul, hneg, neg_one_mul]
    simp only [Equiv.neg_apply, h2, Finset.sum_neg_distrib] at h1
    linarith
  have key : ((∑ x : ZMod p,
      (Finset.univ.filter (fun y : ZMod p => y ^ 2 = x ^ 3 - x)).card : ℕ) : ℤ) = p := by
    push_cast
    simp only [hsq, Finset.sum_add_distrib, hsum]
    simp
  exact_mod_cast key

/-! ### The card's whole-number examples -/

-- e₂ over ℚ, by Miller's formula `(x_Q − x_P)/(x_P − x_Q)` with the sign (−1)² = 1.
example : ((1 : ℚ) - 0) / (0 - 1) = -1 := by norm_num
example : ((-1 : ℚ) - 1) / (1 - (-1)) = -1 := by norm_num
-- The 2-torsion over ℚ: x³ − x is 0 at x = 0, 1, −1.
example : ∀ x ∈ ({0, 1, -1} : Finset ℚ), x ^ 3 - x = 0 := by norm_num

-- Mod 43: 43 affine points (x, y) on y² = x³ − x; with O, 44 = 43 + 1.
example : (Finset.univ.filter
    (fun xy : ZMod 43 × ZMod 43 => xy.2 ^ 2 = xy.1 ^ 3 - xy.1)).card = 43 := by decide
-- G = (2, 7), P = (10, 42), 2P = (24, 30) and Q = 7P = (16, 9) lie on the curve mod 43.
example : (7 : ZMod 43) ^ 2 = 2 ^ 3 - 2 := by decide
example : (42 : ZMod 43) ^ 2 = 10 ^ 3 - 10 := by decide
example : (30 : ZMod 43) ^ 2 = 24 ^ 3 - 24 := by decide
example : (9 : ZMod 43) ^ 2 = 16 ^ 3 - 16 := by decide
-- The tangent slope at P is (3·10² − 1)/(2·42) = 1, and it gives 2P = (24, 30).
example : (1 : ZMod 43) * (2 * 42) = 3 * 10 ^ 2 - 1 := by decide
example : (1 : ZMod 43) ^ 2 - 2 * 10 = 24 ∧ (1 : ZMod 43) * (10 - 24) - 42 = 30 := by decide

-- The embedding degree of 11 over 𝔽₄₃ is 2: 11 divides 43² − 1 but not 43 − 1.
example : 11 ∣ 43 ^ 2 - 1 ∧ ¬ 11 ∣ 43 ^ 1 - 1 := by decide
-- The house curve y² = x³ − 2 mod 13: 18 affine points, 19 with O, and embedding degree 18.
example : (Finset.univ.filter
    (fun xy : ZMod 13 × ZMod 13 => xy.2 ^ 2 = xy.1 ^ 3 - 2)).card = 18 := by decide
example : (13 : ZMod 19) ^ 18 = 1 ∧ ∀ k < 18, 0 < k → (13 : ZMod 19) ^ k ≠ 1 := by decide

/-! The field 𝔽₄₃² as numbers `a + bi` with `i² = −1`: `QuadraticAlgebra (ZMod 43) (-1) 0`,
where `⟨a, b⟩` is `a + bi`. -/

-- The first Miller value: (21 + 42i)/9 = 31 + 19i.
example : (⟨9, 0⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) * ⟨31, 19⟩ = ⟨21, 42⟩ := by decide
-- α = −(18 + 34i)/(34 + 18i) = 18 + 35i.
example : (⟨18, 35⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) * ⟨34, 18⟩ = -⟨18, 34⟩ := by decide
-- α is an 11th root of unity other than 1.
example : (⟨18, 35⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) ^ 11 = 1 := by decide
example : (⟨18, 35⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) ≠ 1 := by decide
-- MOV: β = 7 + 34i is α⁷, and no smaller power of α gives β.
example : (⟨18, 35⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) ^ 7 = ⟨7, 34⟩ := by decide
example : ∀ k < 7, (⟨18, 35⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) ^ k ≠ ⟨7, 34⟩ := by decide
-- The three-party key with secrets 2, 5, 9: α⁹⁰ = 2 + 13i.
set_option maxRecDepth 4000 in
example : (⟨18, 35⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) ^ 90 = ⟨2, 13⟩ := by decide
-- Mistake 2, the sign dropped: (25 + 8i)¹¹ = −1.
example : (⟨25, 8⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) ^ 11 = -1 := by decide
-- Mistake 3, G of order 22 put into e₁₁: (22 + 20i)¹¹ = 33i.
example : (⟨22, 20⟩ : QuadraticAlgebra (ZMod 43) (-1) 0) ^ 11 = ⟨0, 33⟩ := by decide

#print axioms pairing_zpow_left
#print axioms pairing_zpow_right
#print axioms pairing_determinant_rule
#print axioms pairing_alternating_of_odd
#print axioms card_points_curveE_of_mod_four_eq_three
