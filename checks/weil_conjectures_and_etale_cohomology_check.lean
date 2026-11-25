-- The Weil conjectures: for a genus-1 curve with trace a and a² ≤ 4q, both reciprocal roots of 1 - a t + q t² have size √q, so every count stays within 2 q^(n/2) of q^n + 1, and projective d-space over a field of q elements has 1 + q + ... + q^d points.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Projectivization.Cardinality
import Mathlib.Data.ZMod.Basic

open scoped LinearAlgebra.Projectivization

/-- The Riemann hypothesis for a genus-1 curve (Step 2 of the card). Let α and β be the
reciprocal roots of 1 - a t + q t², so α + β = a and α β = q, where a is the trace and q the
size of the base field. If Hasse's bound a² ≤ 4q holds, then α and β both have size exactly √q. -/
theorem riemann_hypothesis_genus_one (a : ℤ) (q : ℕ) (α β : ℂ)
    (hsum : α + β = a) (hprod : α * β = q) (hasse : a ^ 2 ≤ 4 * (q : ℤ)) :
    ‖α‖ = Real.sqrt q ∧ ‖β‖ = Real.sqrt q := by
  have key : Complex.normSq α = q ∧ Complex.normSq β = q := by
    have h1 := congrArg Complex.re hsum
    have h2 := congrArg Complex.im hsum
    have h3 := congrArg Complex.re hprod
    have h4 := congrArg Complex.im hprod
    simp only [Complex.add_re, Complex.add_im, Complex.mul_re, Complex.mul_im,
      Complex.intCast_re, Complex.intCast_im, Complex.natCast_re, Complex.natCast_im] at h1 h2 h3 h4
    have hasse' : ((a : ℝ)) ^ 2 ≤ 4 * (q : ℝ) := by exact_mod_cast hasse
    have hv : β.im = -α.im := by linarith
    rw [hv] at h3 h4
    have hx : α.re = β.re := by
      have h5 : α.im * (β.re - α.re) = 0 := by linarith
      rcases mul_eq_zero.mp h5 with h | h
      · rw [h] at h3
        rw [← h1] at hasse'
        nlinarith [sq_nonneg (α.re - β.re)]
      · linarith
    rw [Complex.normSq_apply, Complex.normSq_apply, hv, ← hx]
    rw [← hx] at h3
    constructor <;> linarith
  rw [Complex.norm_def, Complex.norm_def, key.1, key.2]
  exact ⟨rfl, rfl⟩

/-- Every count stays in its allowance (the chart). If the count over the field of q^n elements
is N_n = q^n + 1 - (α^n + β^n), with α + β = a, α β = q and a² ≤ 4q, then
|N_n - q^n - 1| ≤ 2 q^(n/2) for every n. -/
theorem genus_one_count_within_allowance (a : ℤ) (q : ℕ) (α β : ℂ)
    (hsum : α + β = a) (hprod : α * β = q) (hasse : a ^ 2 ≤ 4 * (q : ℤ))
    (N : ℕ → ℤ) (hN : ∀ n, (N n : ℂ) = (q : ℂ) ^ n + 1 - (α ^ n + β ^ n)) (n : ℕ) :
    |(N n : ℝ) - (q : ℝ) ^ n - 1| ≤ 2 * Real.sqrt q ^ n := by
  obtain ⟨ha, hb⟩ := riemann_hypothesis_genus_one a q α β hsum hprod hasse
  have h : (((N n : ℝ) - (q : ℝ) ^ n - 1 : ℝ) : ℂ) = -(α ^ n + β ^ n) := by
    push_cast
    rw [hN n]
    ring
  rw [← Real.norm_eq_abs, ← Complex.norm_real, h, norm_neg]
  calc ‖α ^ n + β ^ n‖ ≤ ‖α ^ n‖ + ‖β ^ n‖ := norm_add_le _ _
    _ = 2 * Real.sqrt q ^ n := by rw [norm_pow, norm_pow, ha, hb]; ring

/-- Projective space, counted (Step 1 of the card). Over a field K with q elements, the
projective space P^d, the lines through 0 in K^(d+1), has 1 + q + q² + ... + q^d points. -/
theorem card_projective_space (K : Type*) [Field K] [Fintype K] (d : ℕ) :
    Nat.card (ℙ K (Fin (d + 1) → K)) = ∑ i ∈ Finset.range (d + 1), Fintype.card K ^ i := by
  rw [Projectivization.card_of_finrank K (Fin (d + 1) → K) (Module.finrank_fin_fun K),
    Nat.card_eq_fintype_card]

-- y² = x³ - x over F_5: 7 affine points, plus O, gives N_1 = 8.
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 - p.1)).card + 1 = 8 := by decide
-- The trace a = 5 + 1 - 8 = -2, and Hasse's bound a² ≤ 4q holds: 4 ≤ 20.
example : (5 + 1 - 8 : ℤ) = -2 ∧ (-2 : ℤ) ^ 2 ≤ 4 * 5 := by norm_num
-- The reciprocal roots -1 ± 2i: sum -2, product (-1)² + 2² = 5.
example : (-1 : ℤ) + -1 = -2 ∧ (-1 : ℤ) ^ 2 + 2 ^ 2 = 5 := by norm_num
-- Over F_25: 25 + 1 - (a² - 2q) = 26 - (4 - 10) = 32.
example : (25 + 1 - ((-2) ^ 2 - 2 * 5) : ℤ) = 32 := by norm_num
-- Over F_125 and F_625, with s_n = α^n + β^n from s_n = a s_(n-1) - q s_(n-2):
-- s_3 = 22 gives 104, s_4 = -14 gives 640.
example : ((-2) * ((-2) ^ 2 - 2 * 5) - 5 * (-2) : ℤ) = 22 ∧ (125 + 1 - 22 : ℤ) = 104 := by norm_num
example : ((-2) * 22 - 5 * ((-2) ^ 2 - 2 * 5) : ℤ) = -14 ∧ (625 + 1 - (-14) : ℤ) = 640 := by norm_num
-- Genus 2, y² = x⁵ + x + 1 over F_5: 5 affine points and one at infinity, 6 in all.
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 5 + p.1 + 1)).card + 1 = 6 := by decide
-- P² over F_5: 124 nonzero triples fall into classes of 4, giving 31 = 1 + 5 + 25 points.
set_option maxRecDepth 10000 in
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5 × ZMod 5)).filter (· ≠ 0)).card = 4 * 31 ∧
    1 + 5 + 5 ^ 2 = 31 := by decide
-- The nodal cubic y² = x³ + x² over F_5 has 4 affine points plus O, 5 in all.
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 + p.1 ^ 2)).card + 1 = 5 := by decide
-- Leaving out O: a = 5 + 1 - 7 = -1, and the prediction over F_25 becomes 35, not 32.
example : (5 + 1 - 7 : ℤ) = -1 ∧ (26 - ((-1) ^ 2 - 2 * 5) : ℤ) = 35 := by norm_num
-- Reading α² + β² as a²: 26 - 4 = 22, not 32.
example : (26 - (-2) ^ 2 : ℤ) = 22 := by norm_num
-- Counting mod 25 instead of over F_25: 35 affine solutions plus O gives 36.
example : ((Finset.univ : Finset (ZMod 25 × ZMod 25)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 - p.1)).card + 1 = 36 := by decide

#print axioms riemann_hypothesis_genus_one
#print axioms genus_one_count_within_allowance
#print axioms card_projective_space
