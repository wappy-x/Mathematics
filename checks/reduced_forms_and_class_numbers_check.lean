-- Reduced forms: every positive definite binary quadratic form is equivalent, by a whole-number renaming with determinant 1, to exactly one reduced form, renaming keeps the discriminant, and a reduced form has 3a^2 <= |D|, so the class number is a finite count.
import Mathlib.LinearAlgebra.Matrix.SpecialLinearGroup
import Mathlib.Data.Int.GCD
import Mathlib.Order.Interval.Finset.Defs
import Mathlib.Algebra.Order.Group.Int
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.LinearCombination

open Matrix MatrixGroups

/-- A binary quadratic form `(a, b, c)`, standing for `a x^2 + b x y + c y^2`. -/
abbrev Form := ℤ × ℤ × ℤ

/-- The discriminant `b^2 - 4ac` of the form `(a, b, c)`. -/
def disc (f : Form) : ℤ := f.2.1 ^ 2 - 4 * f.1 * f.2.2

/-- The renaming `x → p x + q y, y → r x + s y` given by the matrix `!![p, q; r, s]` in
`SL(2, ℤ)` (whole entries, `p s - q r = 1`), applied to the form `(a, b, c)`. -/
def rename (γ : SL(2, ℤ)) (f : Form) : Form :=
  let p := γ 0 0; let q := γ 0 1; let r := γ 1 0; let s := γ 1 1
  let a := f.1; let b := f.2.1; let c := f.2.2
  (a * p ^ 2 + b * p * r + c * r ^ 2,
   2 * a * p * q + b * (p * s + q * r) + 2 * c * r * s,
   a * q ^ 2 + b * q * s + c * s ^ 2)

/-- Two forms are equivalent when a renaming with determinant 1 turns the first into the second. -/
def Equivalent (f g : Form) : Prop := ∃ γ : SL(2, ℤ), rename γ f = g

/-- The form `(a, b, c)` is reduced: `-a < b ≤ a ≤ c`, and `b ≥ 0` when `a = c`. -/
abbrev IsReducedForm (f : Form) : Prop :=
  -f.1 < f.2.1 ∧ f.2.1 ≤ f.1 ∧ f.1 ≤ f.2.2 ∧ (f.1 = f.2.2 → 0 ≤ f.2.1)

/-- The form `(a, b, c)` is primitive: no whole number above 1 divides all three numbers. -/
abbrev IsPrimitiveForm (f : Form) : Prop := Int.gcd (Int.gcd f.1 f.2.1) f.2.2 = 1

/-- For the worked examples: the primitive reduced forms of discriminant `D` with `a ≤ N`,
listed as the card's code lists them (`a` from 1 to `N`, `b` from `-N` to `N`, and `c` read off
from `b^2 - 4ac = D`). With `3 a^2 ≤ |D|` (`three_mul_sq_le_neg_disc`) and `|b| ≤ a`, every
primitive reduced form of discriminant `D` lies in this list once `3 N^2 ≥ |D|`. -/
def reducedList (D N : ℤ) : Finset Form :=
  ((Finset.Icc 1 N ×ˢ Finset.Icc (-N) N).image
      fun ab => (ab.1, ab.2, (ab.2 ^ 2 - D) / (4 * ab.1))).filter
    fun f => IsReducedForm f ∧ IsPrimitiveForm f ∧ disc f = D

/-- The entries of a matrix in `SL(2, ℤ)` satisfy `p s - q r = 1`. -/
theorem sl2_det (γ : SL(2, ℤ)) : γ 0 0 * γ 1 1 - γ 0 1 * γ 1 0 = 1 := by
  have h := γ.det_coe
  rw [Matrix.det_fin_two] at h
  exact h

/-- Renaming by `γ` and then by `δ` is renaming by `γ * δ`. -/
theorem rename_mul (γ δ : SL(2, ℤ)) (f : Form) : rename δ (rename γ f) = rename (γ * δ) f := by
  obtain ⟨a, b, c⟩ := f
  simp only [rename, Matrix.SpecialLinearGroup.coe_mul, Matrix.mul_apply, Fin.sum_univ_two]
  refine Prod.ext ?_ (Prod.ext ?_ ?_) <;> simp only <;> ring

/-- Renaming by the identity changes nothing. -/
theorem rename_one (f : Form) : rename 1 f = f := by
  obtain ⟨a, b, c⟩ := f
  simp [rename]

theorem equivalent_trans {f g h : Form} (h1 : Equivalent f g) (h2 : Equivalent g h) :
    Equivalent f h := by
  obtain ⟨γ, rfl⟩ := h1
  obtain ⟨δ, rfl⟩ := h2
  exact ⟨γ * δ, (rename_mul γ δ f).symm⟩

theorem equivalent_symm {f g : Form} (h : Equivalent f g) : Equivalent g f := by
  obtain ⟨γ, rfl⟩ := h
  exact ⟨γ⁻¹, by rw [rename_mul, mul_inv_cancel, rename_one]⟩

/-- `u^2 + v^2 - 1 ≥ |u v|` for whole numbers `u, v` not both zero. -/
theorem abs_mul_le_sq_add_sq_sub_one (x y : ℤ) (hxy : x ≠ 0 ∨ y ≠ 0) :
    |x * y| ≤ x ^ 2 + y ^ 2 - 1 := by
  rw [abs_mul]
  have hx := abs_nonneg x
  have hy := abs_nonneg y
  have ex : x ^ 2 = |x| ^ 2 := (sq_abs x).symm
  have ey : y ^ 2 = |y| ^ 2 := (sq_abs y).symm
  rw [ex, ey]
  rcases hxy with h | h
  · have h' : 1 ≤ |x| := Int.one_le_abs h
    rcases (eq_or_lt_of_le hy) with h0 | h0
    · rw [← h0]; nlinarith
    · nlinarith [sq_nonneg (|x| - |y|)]
  · have h' : 1 ≤ |y| := Int.one_le_abs h
    rcases (eq_or_lt_of_le hx) with h0 | h0
    · rw [← h0]; nlinarith
    · nlinarith [sq_nonneg (|x| - |y|)]

/-- A reduced form `(a, b, c)` takes value at least `a + (c - a) y^2` at any nonzero `(x, y)`. -/
theorem reduced_value_ge (a b c x y : ℤ) (h1 : -a < b) (h2 : b ≤ a) (_h3 : a ≤ c)
    (hxy : x ≠ 0 ∨ y ≠ 0) : a + (c - a) * y ^ 2 ≤ a * x ^ 2 + b * x * y + c * y ^ 2 := by
  have ha : 0 < a := by linarith
  have hb : |b| ≤ a := abs_le.mpr ⟨by linarith, h2⟩
  have k := abs_mul_le_sq_add_sq_sub_one x y hxy
  have k2 : |b * (x * y)| ≤ a * (x ^ 2 + y ^ 2 - 1) := by
    rw [abs_mul]
    exact mul_le_mul hb k (abs_nonneg _) ha.le
  have k3 := neg_abs_le (b * (x * y))
  nlinarith

/-- If `g = rename γ f` with both reduced, then `f.1 ≤ g.1`. -/
theorem reduced_first_le (γ : SL(2, ℤ)) (f : Form) (hf : IsReducedForm f)
    (hg : IsReducedForm (rename γ f)) : f.1 ≤ (rename γ f).1 := by
  obtain ⟨a, b, c⟩ := f
  obtain ⟨h1, h2, h3, -⟩ := hf
  have hdet := sl2_det γ
  have hpr : γ 0 0 ≠ 0 ∨ γ 1 0 ≠ 0 := by
    by_contra h
    push Not at h
    rw [h.1, h.2] at hdet
    simp at hdet
  have := reduced_value_ge a b c (γ 0 0) (γ 1 0) h1 h2 h3 hpr
  have : 0 ≤ (c - a) * γ 1 0 ^ 2 := mul_nonneg (by simp only at h3 ⊢; linarith) (sq_nonneg _)
  simp only [rename] at *
  linarith

/-- If `g = rename γ f` with both reduced, `g.1 = f.1` and `f.1 < f.2.2`, then `g = f`. -/
theorem reduced_eq_of_first_eq (γ : SL(2, ℤ)) (f : Form) (hf : IsReducedForm f)
    (hg : IsReducedForm (rename γ f)) (he : (rename γ f).1 = f.1) (hlt : f.1 < f.2.2) :
    rename γ f = f := by
  obtain ⟨a, b, c⟩ := f
  obtain ⟨h1, h2, h3, -⟩ := hf
  simp only at h1 h2 h3 hlt
  have ha : 0 < a := by linarith
  have hdet := sl2_det γ
  obtain ⟨g1, g2, -, -⟩ := hg
  simp only [rename] at he g1 g2 ⊢
  set p := γ 0 0
  set q := γ 0 1
  set r := γ 1 0
  set s := γ 1 1
  have hr : r = 0 := by
    by_contra hr
    have k := reduced_value_ge a b c p r h1 h2 h3 (Or.inr hr)
    have : 1 ≤ r ^ 2 := by
      have := Int.one_le_abs hr
      nlinarith [sq_abs r]
    nlinarith
  rw [hr] at hdet g1 g2 ⊢
  have hps : p * s = 1 := by linarith
  rcases Int.eq_one_or_neg_one_of_mul_eq_one' hps with ⟨hp, hs⟩ | ⟨hp, hs⟩
  · rw [hp, hs] at g1 g2 ⊢
    have hq : q = 0 := by
      rcases lt_trichotomy q 0 with h | h | h
      · exfalso
        have : a * q ≤ -a := by nlinarith
        nlinarith
      · exact h
      · exfalso
        have : a ≤ a * q := by nlinarith
        nlinarith
    rw [hq]
    refine Prod.ext ?_ (Prod.ext ?_ ?_) <;> simp only <;> ring
  · rw [hp, hs] at g1 g2 ⊢
    have hq : q = 0 := by
      rcases lt_trichotomy q 0 with h | h | h
      · exfalso
        have : a * q ≤ -a := by nlinarith
        nlinarith
      · exact h
      · exfalso
        have : a ≤ a * q := by nlinarith
        nlinarith
    rw [hq]
    refine Prod.ext ?_ (Prod.ext ?_ ?_) <;> simp only <;> ring


theorem disc_rename' (γ : SL(2, ℤ)) (f : Form) : disc (rename γ f) = disc f := by
  obtain ⟨a, b, c⟩ := f
  have hdet := sl2_det γ
  simp only [disc, rename]
  linear_combination (b ^ 2 - 4 * a * c) * (γ 0 0 * γ 1 1 - γ 0 1 * γ 1 0 + 1) * hdet

/-- The shift `x → x + k y`. -/
def shiftM (k : ℤ) : SL(2, ℤ) := ⟨!![1, k; 0, 1], by simp [det_fin_two_of]⟩
/-- The turn `x → -y, y → x`. -/
def turnM : SL(2, ℤ) := ⟨!![0, -1; 1, 0], by simp [det_fin_two_of]⟩

theorem rename_shiftM (k a b c : ℤ) :
    rename (shiftM k) (a, b, c) = (a, 2 * a * k + b, a * k ^ 2 + b * k + c) := by
  simp only [rename, shiftM]
  simp

theorem rename_turnM (a b c : ℤ) : rename turnM (a, b, c) = (c, -b, a) := by
  simp [rename, turnM]

theorem exists_reduced (n : ℕ) : ∀ f : Form, f.1 ≤ n → 0 < f.1 → disc f < 0 →
    ∃ g, IsReducedForm g ∧ Equivalent f g := by
  induction n with
  | zero => intro f h1 h2; simp at h1; omega
  | succ n ih =>
    rintro ⟨a, b, c⟩ hn ha hD
    simp only at hn ha
    simp only [disc] at hD
    have h2a : 0 < 2 * a := by omega
    set m := (b + a - 1) % (2 * a) with hm
    set q := (b + a - 1) / (2 * a) with hq
    have hm0 : 0 ≤ m := Int.emod_nonneg _ h2a.ne'
    have hm1 : m < 2 * a := Int.emod_lt_of_pos _ h2a
    have hmq : m + 2 * a * q = b + a - 1 := by
      have := Int.emod_add_ediv_mul (b + a - 1) (2 * a); rw [hm, hq]; linarith
    set c' := a * (-q) ^ 2 + b * (-q) + c with hc'
    set b' := 2 * a * (-q) + b with hb'
    have e1 : Equivalent (a, b, c) (a, b', c') := ⟨shiftM (-q), rename_shiftM _ _ _ _⟩
    have hD' : b' ^ 2 - 4 * a * c' < 0 := by
      have := disc_rename' (shiftM (-q)) (a, b, c)
      rw [rename_shiftM] at this
      simp only [disc] at this
      linarith
    have hb1 : -a < b' := by rw [hb']; linarith
    have hb2 : b' ≤ a := by rw [hb']; linarith
    have hcpos : 0 < c' := by nlinarith [sq_nonneg b']
    rcases lt_or_ge c' a with hlt | hge
    · obtain ⟨g, hg, hfg⟩ := ih (c', -b', a) (by simp only; omega) hcpos
        (by simp only [disc]; linarith)
      exact ⟨g, hg, equivalent_trans e1
        (equivalent_trans ⟨turnM, rename_turnM _ _ _⟩ hfg)⟩
    · by_cases hc : c' = a ∧ b' < 0
      · refine ⟨(a, -b', a), ?_, equivalent_trans e1 ⟨turnM, by rw [rename_turnM, hc.1]⟩⟩
        refine ⟨by linarith, by linarith, le_refl _, fun _ => by linarith⟩
      · refine ⟨(a, b', c'), ?_, e1⟩
        refine ⟨hb1, hb2, hge, fun h => ?_⟩
        by_contra hneg
        exact hc ⟨h.symm, by linarith⟩

/-- **Reduction.** Every positive form (`a > 0` and discriminant below 0) is equivalent, by a
whole-number renaming with determinant 1, to exactly one reduced form. -/
theorem exists_unique_reduced_equivalent (f : Form) (ha : 0 < f.1) (hD : disc f < 0) :
    ∃! g : Form, IsReducedForm g ∧ Equivalent f g := by
  obtain ⟨g, hg, hfg⟩ := exists_reduced f.1.toNat f (by omega) ha hD
  refine ⟨g, ⟨hg, hfg⟩, ?_⟩
  rintro g' ⟨hg', hfg'⟩
  have e : Equivalent g g' := equivalent_trans (equivalent_symm hfg) hfg'
  obtain ⟨γ, hγ⟩ := e
  obtain ⟨δ, hδ⟩ : Equivalent g' g := ⟨γ⁻¹, by rw [← hγ, rename_mul, mul_inv_cancel, rename_one]⟩
  have l1 := reduced_first_le γ g hg (hγ ▸ hg')
  have l2 := reduced_first_le δ g' hg' (hδ ▸ hg)
  rw [hγ] at l1
  rw [hδ] at l2
  have hdisc : disc g' = disc g := by rw [← hγ, disc_rename']
  have hga : g'.1 = g.1 := le_antisymm l2 l1
  rcases lt_or_eq_of_le hg.2.2.1 with hlt | heq
  · have := reduced_eq_of_first_eq γ g hg (hγ ▸ hg') (hγ ▸ hga) hlt
    rw [← hγ, this]
  rcases lt_or_eq_of_le hg'.2.2.1 with hlt' | heq'
  · have := reduced_eq_of_first_eq δ g' hg' (hδ ▸ hg) (hδ ▸ hga.symm) hlt'
    rw [← this, hδ]
  obtain ⟨a, b, c⟩ := g
  obtain ⟨a', b', c'⟩ := g'
  simp only at hga heq heq' hdisc hg hg' ⊢
  simp only [disc] at hdisc
  subst hga
  have hb : 0 ≤ b := hg.2.2.2 heq
  have hb' : 0 ≤ b' := hg'.2.2.2 heq'
  have : b' ^ 2 = b ^ 2 := by rw [← heq, ← heq'] at hdisc; linarith
  have : b' = b := by nlinarith
  rw [this, ← heq, ← heq']

/-- **Step 0.** A renaming with determinant 1 does not change the discriminant. -/
theorem disc_rename (γ : SL(2, ℤ)) (f : Form) : disc (rename γ f) = disc f := by
  exact disc_rename' γ f

/-- **Step 4.** A reduced form of discriminant `D` has `3 a^2 ≤ |D|`, so the list of reduced
forms of one discriminant is finite. -/
theorem three_mul_sq_le_neg_disc (f : Form) (hf : IsReducedForm f) : 3 * f.1 ^ 2 ≤ -disc f := by
  obtain ⟨a, b, c⟩ := f
  obtain ⟨h1, h2, h3, -⟩ := hf
  simp only [disc] at *
  have ha : 0 < a := by linarith
  nlinarith

/-! Worked examples from the card. -/

/-- The shift `x → x + k y` (matrix `!![1, k; 0, 1]`, determinant 1). -/
def shiftBy (k : ℤ) : SL(2, ℤ) := ⟨!![1, k; 0, 1], by simp [det_fin_two_of]⟩
/-- The turn `x → -y, y → x` (matrix `!![0, -1; 1, 0]`, determinant 1). -/
def turnMat : SL(2, ℤ) := ⟨!![0, -1; 1, 0], by simp [det_fin_two_of]⟩

-- (3, 8, 7) has discriminant 64 - 84 = -20.
example : disc (3, 8, 7) = -20 := by decide +kernel
-- Shift with k = -1: (3, 8, 7) becomes (3, 2, 2).
example : rename (shiftBy (-1)) (3, 8, 7) = (3, 2, 2) := by
  simp [rename, shiftBy]
-- Turn: (3, 2, 2) becomes (2, -2, 3).
example : rename turnMat (3, 2, 2) = (2, -2, 3) := by
  simp [rename, turnMat]
-- Shift with k = 1: (2, -2, 3) becomes (2, 2, 3).
example : rename (shiftBy 1) (2, -2, 3) = (2, 2, 3) := by
  simp [rename, shiftBy]
-- (2, -2, 3) is not reduced (b = -a is outside the window); (2, 2, 3) and (1, 0, 5) are.
example : ¬ IsReducedForm (2, -2, 3) ∧ IsReducedForm (2, 2, 3) ∧ IsReducedForm (1, 0, 5) := by decide +kernel
-- The search's renaming x → -x - 2y, y → x + y turns (3, 8, 7) into (2, 2, 3) in one step.
example : Equivalent (3, 8, 7) (2, 2, 3) :=
  ⟨⟨!![-1, -2; 1, 1], by simp [det_fin_two_of]⟩, by simp [rename]⟩
-- Class numbers: h(-4) = 1, h(-20) = 2, h(-23) = 3, h(-32) = 2, h(-163) = 1.
example : reducedList (-4) 2 = {(1, 0, 1)} := by decide +kernel
example : reducedList (-20) 3 = {(1, 0, 5), (2, 2, 3)} := by decide +kernel
example : reducedList (-23) 3 = {(1, 1, 6), (2, -1, 3), (2, 1, 3)} := by decide +kernel
example : reducedList (-32) 4 = {(1, 0, 8), (3, 2, 3)} := by decide +kernel
example : reducedList (-163) 8 = {(1, 1, 41)} := by decide +kernel

#print axioms sl2_det
#print axioms rename_mul
#print axioms rename_one
#print axioms equivalent_trans
#print axioms equivalent_symm
#print axioms abs_mul_le_sq_add_sq_sub_one
#print axioms reduced_value_ge
#print axioms reduced_first_le
#print axioms reduced_eq_of_first_eq
#print axioms disc_rename'
#print axioms rename_shiftM
#print axioms rename_turnM
#print axioms exists_reduced
#print axioms exists_unique_reduced_equivalent
#print axioms disc_rename
#print axioms three_mul_sq_le_neg_disc
