-- The characteristic equation: every sequence obeying a two-term rule with fixed weights is a fitted mix of the root sequences of its quadratic, and for Fibonacci that mix is Binet's formula.
import Mathlib.NumberTheory.Real.GoldenRatio
import Mathlib.Tactic.NormNum

/-- A two-term step rule a(n) = c1·a(n−1) + c2·a(n−2) with fixed real weights and c2 ≠ 0,
whose characteristic quadratic r^2 = c1·r + c2 has real roots r and s
(that is, x^2 − c1·x − c2 = (x − r)(x − s)), is solved by the roots:
if r ≠ s, every solution is A·r^n + B·s^n for exactly one pair (A, B);
if r = s, a single root standing twice, every solution is (A + B·n)·r^n for exactly one pair (A, B). -/
theorem two_term_rule_solved_by_characteristic_roots
    (c1 c2 : ℝ) (hc2 : c2 ≠ 0) (r s : ℝ)
    (hroots : ∀ x : ℝ, x ^ 2 - c1 * x - c2 = (x - r) * (x - s))
    (a : ℕ → ℝ) (ha : ∀ n, a (n + 2) = c1 * a (n + 1) + c2 * a n) :
    (r ≠ s → ∃! AB : ℝ × ℝ, ∀ n : ℕ, a n = AB.1 * r ^ n + AB.2 * s ^ n) ∧
    (r = s → ∃! AB : ℝ × ℝ, ∀ n : ℕ, a n = (AB.1 + AB.2 * n) * r ^ n) := by
  obtain ⟨hc1, hc2'⟩ : c1 = r + s ∧ c2 = -(r * s) := by
    have h0 := hroots 0
    have h1 := hroots 1
    constructor <;> nlinarith
  subst hc1 hc2'
  have hr : r ≠ 0 := by rintro rfl; simp at hc2
  have key : ∀ (f : ℕ → ℝ), f 0 = a 0 → f 1 = a 1 →
      (∀ n, f (n + 2) = (r + s) * f (n + 1) + -(r * s) * f n) → ∀ n, a n = f n := by
    intro f h0 h1 hf
    have : ∀ n, a n = f n ∧ a (n + 1) = f (n + 1) := by
      intro n
      induction n with
      | zero => exact ⟨h0.symm, h1.symm⟩
      | succ k ih =>
        refine ⟨ih.2, ?_⟩
        rw [ha, hf, ih.1, ih.2]
    exact fun n => (this n).1
  constructor
  · intro hrs
    have hd : r - s ≠ 0 := sub_ne_zero.mpr hrs
    refine ⟨((a 1 - s * a 0) / (r - s), (r * a 0 - a 1) / (r - s)), ?_, ?_⟩
    · apply key
      · simp only [pow_zero]; field_simp; ring
      · simp only [pow_one]; field_simp; ring
      · intro n; simp only [pow_succ]; ring
    · rintro ⟨A, B⟩ h
      have e0 := h 0
      have e1 := h 1
      simp only [pow_zero, pow_one, mul_one] at e0 e1
      simp only [Prod.mk.injEq]
      constructor
      · field_simp; rw [e0, e1]; ring
      · field_simp; rw [e0, e1]; ring
  · intro hrs
    subst hrs
    refine ⟨(a 0, a 1 / r - a 0), ?_, ?_⟩
    · apply key
      · simp
      · simp only [pow_one, Nat.cast_one]; field_simp; ring
      · intro n; push_cast; simp only [pow_succ]; ring
    · rintro ⟨A, B⟩ h
      have e0 := h 0
      have e1 := h 1
      simp only [pow_zero, pow_one, mul_one, Nat.cast_zero, Nat.cast_one, mul_zero, add_zero] at e0 e1
      simp only [Prod.mk.injEq]
      constructor
      · exact e0.symm
      · rw [e0, e1]; field_simp; ring

/-- Step 0: the geometric sequence r^n obeys the rule a(n) = c1·a(n−1) + c2·a(n−2)
exactly when r squared equals c1·r + c2, the characteristic equation. -/
theorem geometric_obeys_rule_iff_characteristic_equation (c1 c2 r : ℝ) :
    (∀ n : ℕ, r ^ (n + 2) = c1 * r ^ (n + 1) + c2 * r ^ n) ↔ r ^ 2 = c1 * r + c2 := by
  constructor
  · intro h
    simpa using h 0
  · intro h n
    calc r ^ (n + 2) = r ^ n * r ^ 2 := by ring
      _ = c1 * r ^ (n + 1) + c2 * r ^ n := by rw [h]; ring

/-- Binet's formula: the Fibonacci number F(n) equals (φ^n − ψ^n)/√5,
with φ = (1 + √5)/2 and ψ = (1 − √5)/2, exactly, at every step n. -/
theorem binet_formula (n : ℕ) :
    (Nat.fib n : ℝ) = (((1 + √5) / 2) ^ n - ((1 - √5) / 2) ^ n) / √5 := by
  rw [Real.coe_fib_eq]

-- The hallway two tiles wide and ten long: F(11) = 89 coverings.
example : Nat.fib 11 = 89 := by decide
-- F(0) .. F(12), as the step rule builds them.
example : (List.range 13).map Nat.fib = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144] := by decide
-- Weights 5, −6: the roots of r^2 − 5r + 6 = 0 are 2 and 3.
example : (2 : ℤ) ^ 2 - 5 * 2 + 6 = 0 ∧ (3 : ℤ) ^ 2 - 5 * 3 + 6 = 0 := by norm_num
-- The fit A + B = 2, 2A + 3B = 5 gives A = B = 1.
example : (1 : ℤ) + 1 = 2 ∧ 2 * 1 + 3 * 1 = 5 := by norm_num
-- 2^n + 3^n obeys a(n) = 5a(n−1) − 6a(n−2) and runs 2, 5, 13, 35, 97, 275, 793, 2315, 6817.
example : ∀ n < 7, (2 : ℤ) ^ (n + 2) + 3 ^ (n + 2) = 5 * (2 ^ (n + 1) + 3 ^ (n + 1)) - 6 * (2 ^ n + 3 ^ n) := by
  decide
example : (List.range 9).map (fun n => (2 : ℤ) ^ n + 3 ^ n) = [2, 5, 13, 35, 97, 275, 793, 2315, 6817] := by
  decide
-- Weights 4, −4: r^2 = 4r − 4 has the single root 2; from 1 and 6, A = 1 and B = 2.
example : (2 : ℤ) ^ 2 = 4 * 2 - 4 ∧ (1 : ℤ) = 1 ∧ ((1 : ℤ) + 2) * 2 = 6 := by norm_num
-- (1 + 2n)·2^n obeys a(n) = 4a(n−1) − 4a(n−2) and runs 1, 6, 20, 56, 144, 352, 832, 1920.
example : ∀ n < 6, (1 + 2 * ((n + 2 : ℕ) : ℤ)) * 2 ^ (n + 2)
    = 4 * ((1 + 2 * ((n + 1 : ℕ) : ℤ)) * 2 ^ (n + 1)) - 4 * ((1 + 2 * (n : ℤ)) * 2 ^ n) := by
  decide
example : (List.range 8).map (fun n : ℕ => (1 + 2 * (n : ℤ)) * 2 ^ n) = [1, 6, 20, 56, 144, 352, 832, 1920] := by
  decide
-- The three mistakes: 2^7 = 128, 11·(−2)^4 − 9·(−3)^4 = −553, 3·2^4 − 3^4 = −33.
example : (2 : ℤ) ^ 7 = 128 := by norm_num
example : 11 * (-2 : ℤ) ^ 4 - 9 * (-3) ^ 4 = -553 := by norm_num
example : 3 * (2 : ℤ) ^ 4 - 3 ^ 4 = -33 := by norm_num

#print axioms two_term_rule_solved_by_characteristic_roots
#print axioms geometric_obeys_rule_iff_characteristic_equation
#print axioms binet_formula
