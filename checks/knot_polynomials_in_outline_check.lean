-- Knot polynomials in outline: the writhe factor cancels a kink's -A^3, the loop score d = -A^2 - A^-2 is exactly what makes move R2 harmless, the bracket rules give Jones's skein relation, and the trefoil's numbers come out as the card says.
import Mathlib.Algebra.Polynomial.Laurent
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

open LaurentPolynomial

/-- Move R1 (the kink). A positive twist expands into `A` times (the strand plus a loop, worth
`d` times the bracket `b` of the diagram without the twist) plus `A⁻¹` times the strand alone, and
adds 1 to the writhe. A negative twist swaps the two weights and takes 1 off the writhe. Either way
the writhe-corrected bracket `(-A^3)^(-w) * ⟨D⟩` is unchanged, when `d = -A^2 - A^-2`. -/
theorem corrected_bracket_unchanged_by_kink {K : Type*} [Field K] (A d b : K) (w : ℤ)
    (hA : A ≠ 0) (hd : d = -A ^ 2 - A ^ (-2 : ℤ)) :
    (-A ^ 3) ^ (-(w + 1)) * (A * (d * b) + A⁻¹ * b) = (-A ^ 3) ^ (-w) * b ∧
    (-A ^ 3) ^ (-(w - 1)) * (A⁻¹ * (d * b) + A * b) = (-A ^ 3) ^ (-w) * b := by
  have h3 : (-A ^ 3 : K) ≠ 0 := neg_ne_zero.mpr (pow_ne_zero 3 hA)
  have e2 : A ^ (-2 : ℤ) = (A ^ 2)⁻¹ := by rw [zpow_neg]; norm_cast
  subst hd
  rw [e2]
  constructor
  · rw [show -(w + 1) = -w + (-1 : ℤ) by ring, zpow_add₀ h3, zpow_neg_one]
    field_simp
    ring
  · rw [show -(w - 1) = -w + (1 : ℤ) by ring, zpow_add₀ h3, zpow_one]
    field_simp
    ring

/-- Move R2 (the poke). Two strands overlapping in two crossings expand into four states: AA and BB
give the strands joined across (bracket `y`) with weights `A·A` and `A⁻¹·A⁻¹`, AB gives the strands
pushed apart (bracket `x`) with weight `A·A⁻¹`, and BA gives the joined picture plus a separate loop,
worth `d * y`, with weight `A⁻¹·A`. The total equals the bracket `x` of the diagram before the move,
for every pair of pictures, exactly when the loop score is `d = -A^2 - A^-2`. -/
theorem bracket_unchanged_by_poke_iff {K : Type*} [Field K] (A d : K) (hA : A ≠ 0) :
    (∀ x y : K, A * A * y + A * A⁻¹ * x + A⁻¹ * A * (d * y) + A⁻¹ * A⁻¹ * y = x) ↔
      d = -A ^ 2 - A ^ (-2 : ℤ) := by
  have e2 : A ^ (-2 : ℤ) = (A ^ 2)⁻¹ := by rw [zpow_neg]; norm_cast
  rw [e2]
  constructor
  · intro h
    have h1 := h 0 1
    simp only [mul_zero, mul_one, add_zero] at h1
    rw [inv_mul_cancel₀ hA, one_mul] at h1
    linear_combination h1
  · intro hd x y
    subst hd
    field_simp
    ring

/-- The skein relation. Let `L₊`, `L₋`, `L₀`, `L∞` be diagrams alike except at one crossing:
positive, switched, smoothed along the arrows, smoothed against them. The bracket rule gives
`⟨L₊⟩ = A⟨L₀⟩ + A⁻¹⟨L∞⟩` and `⟨L₋⟩ = A⁻¹⟨L₀⟩ + A⟨L∞⟩`. If `L₀` has writhe `w`, then `L₊` has
`w + 1` and `L₋` has `w - 1`, and `V(L) = (-A^3)^(-w(L)) ⟨L⟩`. With `t = A^-4` (so `t^(1/2) = A^-2`),
`t⁻¹ V(L₊) - t V(L₋) = (t^(1/2) - t^(-1/2)) V(L₀)`. -/
theorem skein_relation_of_bracket {K : Type*} [Field K] (A bp bm b0 binf : K) (w : ℤ)
    (hA : A ≠ 0) (hp : bp = A * b0 + A⁻¹ * binf) (hm : bm = A⁻¹ * b0 + A * binf) :
    (A ^ (-4 : ℤ))⁻¹ * ((-A ^ 3) ^ (-(w + 1)) * bp) - A ^ (-4 : ℤ) * ((-A ^ 3) ^ (-(w - 1)) * bm) =
      (A ^ (-2 : ℤ) - (A ^ (-2 : ℤ))⁻¹) * ((-A ^ 3) ^ (-w) * b0) := by
  have h3 : (-A ^ 3 : K) ≠ 0 := neg_ne_zero.mpr (pow_ne_zero 3 hA)
  have e2 : A ^ (-2 : ℤ) = (A ^ 2)⁻¹ := by rw [zpow_neg]; norm_cast
  have e4 : A ^ (-4 : ℤ) = (A ^ 4)⁻¹ := by rw [zpow_neg]; norm_cast
  subst hp hm
  rw [e2, e4, show -(w + 1) = -w + (-1 : ℤ) by ring, show -(w - 1) = -w + (1 : ℤ) by ring,
    zpow_add₀ h3, zpow_add₀ h3, zpow_neg_one, zpow_one]
  field_simp
  ring

/-! The card's worked numbers for the right trefoil. -/

-- The state sum over all eight states: AAA, three states with one B, three with two Bs, BBB.
example {K : Type*} [Field K] (A d : K) (hA : A ≠ 0) (hd : d = -A ^ 2 - A ^ (-2 : ℤ)) :
    A ^ 3 * d + 3 * A + 3 * (A ^ (-1 : ℤ) * d) + A ^ (-3 : ℤ) * d ^ 2 =
      A ^ (-7 : ℤ) - A ^ (-3 : ℤ) - A ^ 5 := by
  have e1 : A ^ (-1 : ℤ) = A⁻¹ := zpow_neg_one A
  have e2 : A ^ (-2 : ℤ) = (A ^ 2)⁻¹ := by rw [zpow_neg]; norm_cast
  have e3 : A ^ (-3 : ℤ) = (A ^ 3)⁻¹ := by rw [zpow_neg]; norm_cast
  have e7 : A ^ (-7 : ℤ) = (A ^ 7)⁻¹ := by rw [zpow_neg]; norm_cast
  subst hd
  rw [e1, e2, e3, e7]
  field_simp
  ring

-- The span of the bracket: 5 - (-7) = 12 = 4 × 3 crossings.
example : (5 : ℤ) - (-7) = 4 * 3 := by norm_num

-- The writhe factor (-A^3)^(-3) = -A^-9 applied to the bracket.
example {K : Type*} [Field K] (A : K) (hA : A ≠ 0) :
    (-A ^ 3) ^ (-3 : ℤ) * (A ^ (-7 : ℤ) - A ^ (-3 : ℤ) - A ^ 5) =
      -A ^ (-16 : ℤ) + A ^ (-12 : ℤ) + A ^ (-4 : ℤ) := by
  have e : (-A ^ 3) ^ (-3 : ℤ) = ((-A ^ 3) ^ 3)⁻¹ := by rw [zpow_neg]; norm_cast
  have e3 : A ^ (-3 : ℤ) = (A ^ 3)⁻¹ := by rw [zpow_neg]; norm_cast
  have e4 : A ^ (-4 : ℤ) = (A ^ 4)⁻¹ := by rw [zpow_neg]; norm_cast
  have e7 : A ^ (-7 : ℤ) = (A ^ 7)⁻¹ := by rw [zpow_neg]; norm_cast
  have e12 : A ^ (-12 : ℤ) = (A ^ 12)⁻¹ := by rw [zpow_neg]; norm_cast
  have e16 : A ^ (-16 : ℤ) = (A ^ 16)⁻¹ := by rw [zpow_neg]; norm_cast
  rw [e, e3, e4, e7, e12, e16]
  field_simp
  ring

-- The skein road, writing `s` for `t^(1/2)`: two separate rings give `-s - s⁻¹`,
-- the Hopf link gives `-s - s^5`, and the right trefoil gives `t + t^3 - t^4 = s^2 + s^6 - s^8`.
example {K : Type*} [Field K] (s : K) (hs : s ≠ 0) :
    s ^ 2 * (s ^ 2 * (-s - s⁻¹) + (s - s⁻¹) * 1) = -s - s ^ 5 := by
  field_simp
  ring

example {K : Type*} [Field K] (s : K) (hs : s ≠ 0) :
    s ^ 2 * (s ^ 2 * 1 + (s - s⁻¹) * (-s - s ^ 5)) = s ^ 2 + s ^ 6 - s ^ 8 := by
  field_simp
  ring

-- The right trefoil and its mirror have different Jones polynomials.
example : (T 1 + T 3 - T 4 : LaurentPolynomial ℤ) ≠ T (-1) + T (-3) - T (-4) := by
  intro h
  have := congrArg (fun p : LaurentPolynomial ℤ => p.coeff 1) h
  simp at this

#print axioms corrected_bracket_unchanged_by_kink
#print axioms bracket_unchanged_by_poke_iff
#print axioms skein_relation_of_bracket
