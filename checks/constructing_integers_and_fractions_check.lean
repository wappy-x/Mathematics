-- Building the integers and fractions: integers built as pairs of counting numbers and fractions as pairs of integers with no bottom 0, the two sameness tests are sameness rules, adding and multiplying give the same answer whichever pairs are picked, and the pairs behave exactly like a − b and a ÷ b.
import Mathlib.Data.Rat.Cast.Lemmas
import Mathlib.Order.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Zify
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith

namespace ConstructingIntegersAndFractions

/-! An integer is a pair `(a, b)` of counting numbers: `a` paid in, `b` owed, worth `a − b`.
A fraction is a pair `(a, b)` of integers: top `a`, bottom `b`, worth `a ÷ b`.
These are the card's tests and rules, word for word. -/

/-- Integer test: `(a, b) ~ (c, d)` when `a + d = c + b` (addition only). -/
abbrev intSame (p q : ℕ × ℕ) : Prop := p.1 + q.2 = q.1 + p.2

/-- Integer adding: `(a, b) + (c, d) = (a + c, b + d)`. -/
def intAdd (p q : ℕ × ℕ) : ℕ × ℕ := (p.1 + q.1, p.2 + q.2)

/-- Integer multiplying: `(a, b) × (c, d) = (ac + bd, ad + bc)`. -/
def intMul (p q : ℕ × ℕ) : ℕ × ℕ := (p.1 * q.1 + p.2 * q.2, p.1 * q.2 + p.2 * q.1)

/-- Fraction test: `(a, b) ~ (c, d)` when `a × d = b × c` (multiplication only). -/
abbrev fracSame (p q : ℤ × ℤ) : Prop := p.1 * q.2 = p.2 * q.1

/-- Fraction adding: `(a, b) + (c, d) = (ad + bc, bd)`. -/
def fracAdd (p q : ℤ × ℤ) : ℤ × ℤ := (p.1 * q.2 + p.2 * q.1, p.2 * q.2)

/-- Fraction multiplying: `(a, b) × (c, d) = (ac, bd)`. -/
def fracMul (p q : ℤ × ℤ) : ℤ × ℤ := (p.1 * q.1, p.2 * q.2)

/-- **The rules do not depend on the pick (well defined).** For integer pairs: if `p ~ p'` and
`q ~ q'`, then `p + q ~ p' + q'` and `p × q ~ p' × q'`. For fraction pairs with no bottom 0: if
`p ~ p'` and `q ~ q'`, then `p + q ~ p' + q'` and `p × q ~ p' × q'`, and the sum and the product
again have no bottom 0. -/
theorem rules_do_not_depend_on_the_pick :
    (∀ p p' q q' : ℕ × ℕ, intSame p p' → intSame q q' →
        intSame (intAdd p q) (intAdd p' q') ∧ intSame (intMul p q) (intMul p' q')) ∧
    (∀ p p' q q' : ℤ × ℤ, p.2 ≠ 0 → p'.2 ≠ 0 → q.2 ≠ 0 → q'.2 ≠ 0 →
        fracSame p p' → fracSame q q' →
        fracSame (fracAdd p q) (fracAdd p' q') ∧ fracSame (fracMul p q) (fracMul p' q') ∧
        (fracAdd p q).2 ≠ 0 ∧ (fracMul p q).2 ≠ 0) := by
  refine ⟨fun p p' q q' h1 h2 => ⟨?_, ?_⟩, fun p p' q q' hp hp' hq hq' h1 h2 => ⟨?_, ?_, ?_, ?_⟩⟩
  · simp only [intSame, intAdd] at *; omega
  · simp only [intSame, intMul] at *
    zify at h1 h2 ⊢
    linear_combination ((q.1 : ℤ) - q.2) * h1 + ((p'.1 : ℤ) - p'.2) * h2
  · simp only [fracSame, fracAdd] at *
    linear_combination q.2 * q'.2 * h1 + p.2 * p'.2 * h2
  · simp only [fracSame, fracMul] at *
    linear_combination q.1 * q'.2 * h1 + p.2 * p'.1 * h2
  · simp only [fracAdd]; exact mul_ne_zero hp hq
  · simp only [fracMul]; exact mul_ne_zero hp hq

/-- **Each test is a sameness rule.** The integer test, and the fraction test on pairs with no
bottom 0, each match every pair with itself, work both ways, and chain (transitive). -/
theorem tests_are_sameness_rules :
    Equivalence intSame ∧
    Equivalence (fun p q : {p : ℤ × ℤ // p.2 ≠ 0} => fracSame p.1 q.1) := by
  refine ⟨⟨fun _ => rfl, fun h => by simp only [intSame] at *; omega,
    fun h1 h2 => by simp only [intSame] at *; omega⟩,
    ⟨fun p => mul_comm _ _, fun h => by simp only [fracSame] at *; linear_combination -h, ?_⟩⟩
  intro x y z h1 h2
  simp only [fracSame] at *
  apply mul_left_cancel₀ y.2
  linear_combination z.1.2 * h1 + x.1.2 * h2

/-- **The rules are the familiar ones.** Reading an integer pair `(a, b)` as `a − b`: two pairs
pass the test exactly when they are worth the same, the sum and product rules give the sum and
product of the worths, and every integer is some pair's worth. Reading a fraction pair `(a, b)`
with no bottom 0 as `a ÷ b`: the same three facts hold for the fractions. -/
theorem rules_are_the_familiar_ones :
    (∀ p q : ℕ × ℕ, intSame p q ↔ (p.1 : ℤ) - p.2 = (q.1 : ℤ) - q.2) ∧
    (∀ p q : ℕ × ℕ, ((intAdd p q).1 : ℤ) - (intAdd p q).2 = ((p.1 : ℤ) - p.2) + ((q.1 : ℤ) - q.2)) ∧
    (∀ p q : ℕ × ℕ, ((intMul p q).1 : ℤ) - (intMul p q).2 = ((p.1 : ℤ) - p.2) * ((q.1 : ℤ) - q.2)) ∧
    (∀ z : ℤ, ∃ p : ℕ × ℕ, (p.1 : ℤ) - p.2 = z) ∧
    (∀ p q : ℤ × ℤ, p.2 ≠ 0 → q.2 ≠ 0 →
        (fracSame p q ↔ (p.1 : ℚ) / p.2 = (q.1 : ℚ) / q.2)) ∧
    (∀ p q : ℤ × ℤ, p.2 ≠ 0 → q.2 ≠ 0 →
        ((fracAdd p q).1 : ℚ) / (fracAdd p q).2 = (p.1 : ℚ) / p.2 + (q.1 : ℚ) / q.2) ∧
    (∀ p q : ℤ × ℤ, p.2 ≠ 0 → q.2 ≠ 0 →
        ((fracMul p q).1 : ℚ) / (fracMul p q).2 = (p.1 : ℚ) / p.2 * ((q.1 : ℚ) / q.2)) ∧
    (∀ x : ℚ, ∃ p : ℤ × ℤ, p.2 ≠ 0 ∧ (p.1 : ℚ) / p.2 = x) := by
  refine ⟨fun p q => ?_, fun p q => ?_, fun p q => ?_, fun z => ?_, fun p q hp hq => ?_,
    fun p q hp hq => ?_, fun p q hp hq => ?_, fun x => ?_⟩
  · simp only [intSame]; omega
  · simp only [intAdd]; push_cast; ring
  · simp only [intMul]; push_cast; ring
  · refine ⟨(z.toNat, (-z).toNat), ?_⟩
    simp only
    omega
  · simp only [fracSame]
    have hp' : (p.2 : ℚ) ≠ 0 := by exact_mod_cast hp
    have hq' : (q.2 : ℚ) ≠ 0 := by exact_mod_cast hq
    rw [div_eq_div_iff hp' hq']
    constructor
    · intro h
      have : ((p.1 * q.2 : ℤ) : ℚ) = ((p.2 * q.1 : ℤ) : ℚ) := by rw [h]
      push_cast at this
      linarith
    · intro h
      have : ((p.1 * q.2 : ℤ) : ℚ) = ((p.2 * q.1 : ℤ) : ℚ) := by push_cast; linarith
      exact_mod_cast this
  · have hp' : (p.2 : ℚ) ≠ 0 := by exact_mod_cast hp
    have hq' : (q.2 : ℚ) ≠ 0 := by exact_mod_cast hq
    simp only [fracAdd]
    push_cast
    field_simp
  · have hp' : (p.2 : ℚ) ≠ 0 := by exact_mod_cast hp
    have hq' : (q.2 : ℚ) ≠ 0 := by exact_mod_cast hq
    simp only [fracMul]
    push_cast
    field_simp
  · refine ⟨(x.num, (x.den : ℤ)), ?_, ?_⟩
    · simp only; exact_mod_cast x.den_ne_zero
    · simp only; push_cast; exact Rat.num_div_den x

/-! The card's worked numbers. -/

-- (3, 5) and (0, 2) are the same integer, −2: 3 + 2 = 0 + 5; (5, 3) is not.
example : intSame (3, 5) (0, 2) ∧ ¬ intSame (3, 5) (5, 3) := by decide
example : ((3 : ℕ) : ℤ) - 5 = -2 ∧ ((0 : ℕ) : ℤ) - 2 = -2 := by norm_num

-- −2 + −2 two ways: (3, 7) and (0, 4), both worth −4.
example : intAdd (3, 5) (0, 2) = (3, 7) ∧ intAdd (0, 2) (0, 2) = (0, 4) ∧ intSame (3, 7) (0, 4) := by
  decide

-- −2 × −2 two ways: (10, 6) and (4, 0), both worth 4; debt times debt is credit.
example : intMul (3, 5) (0, 2) = (10, 6) ∧ intMul (0, 2) (0, 2) = (4, 0) ∧ intSame (10, 6) (4, 0) := by
  decide

-- (1, 2), (2, 4) and (3, 6) are the same fraction: 1 × 4 = 2 × 2 and 2 × 6 = 4 × 3.
example : fracSame (1, 2) (2, 4) ∧ fracSame (2, 4) (3, 6) := by decide

-- Half plus a third two ways: (5, 6) and (20, 24), the same since 20 × 6 = 120 = 24 × 5.
example : fracAdd (1, 2) (1, 3) = (5, 6) ∧ fracAdd (2, 4) (2, 6) = (20, 24) ∧
    fracSame (20, 24) (5, 6) := by decide

-- Half times a third two ways: (1, 6) and (4, 24), the same fraction.
example : fracMul (1, 2) (1, 3) = (1, 6) ∧ fracMul (2, 4) (2, 6) = (4, 24) ∧
    fracSame (1, 6) (4, 24) := by decide

-- Broken sum (tops plus tops): (2, 5) and (3, 8) are not the same, as 2 × 8 = 16, not 15.
example : (((1 : ℤ) + 1, (2 : ℤ) + 3) : ℤ × ℤ) = (2, 5) ∧
    (((1 : ℤ) + 2, (2 : ℤ) + 6) : ℤ × ℤ) = (3, 8) ∧ ¬ fracSame (2, 5) (3, 8) := by decide

-- Rounded division misleads: (1, 3) and (33, 100) are not the same fraction.
example : ¬ fracSame (1, 3) (33, 100) := by decide

-- Broken integer product (entry by entry): (0, 2) × (0, 2) gives (0, 4), worth −4.
example : ((0 : ℕ) * 0, (2 : ℕ) * 2) = (0, 4) ∧ ¬ intSame (0, 4) (4, 0) := by decide

-- A bottom of 0 breaks the chain: (1, 2) ~ (0, 0) ~ (3, 4), but (1, 2) is not (3, 4).
example : fracSame (1, 2) (0, 0) ∧ fracSame (0, 0) (3, 4) ∧ ¬ fracSame (1, 2) (3, 4) := by decide

#print axioms rules_do_not_depend_on_the_pick
#print axioms tests_are_sameness_rules
#print axioms rules_are_the_familiar_ones

end ConstructingIntegersAndFractions
