-- The smooth Poincare conjecture in dimension four: this file records the open conjecture DIFF(4) in Mathlib's own words without claiming it, and proves the card's exact facts behind it: the E8 form is even, unimodular and positive definite yet not the diagonal form, Milnor's signature steps of 224 give 28, and the card's whole-number checks.
import Mathlib.Geometry.Manifold.PoincareConjecture
import Mathlib.LinearAlgebra.Matrix.Cartan.Basic
import Mathlib.NumberTheory.Bernoulli
import Mathlib.Data.Set.Card
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic

open Matrix

/-!
The card's main question, DIFF(4), is open as of 2026-11-24: no accepted proof or disproof. It
is recorded below as a definition, using Mathlib's statement of the smooth Poincaré conjecture
(`ContinuousMap.HomotopyEquiv.NonemptyDiffeomorphSphere`), and nothing here claims it or its
negation. The theorems are the exact parts the card proves or computes: the E8 form that
Freedman's manifold carries and that Rokhlin and Donaldson rule out smoothly, and Milnor's
signature road to 28 smooth 7-spheres. The E8 form is Mathlib's Cartan matrix `CartanMatrix.E 8`,
the card's eight simple roots dotted with each other, up to the order of the roots.
-/

/-- The smooth Poincaré conjecture in dimension four, DIFF(4) (statement only; open, not proved
here or anywhere as of 2026-11-24): for every Hausdorff space `M` and every smooth
4-dimensional atlas on it, if `M` has the 4-sphere's loops and holes (is homotopy equivalent to
the round 4-sphere), then `M` is smoothly the round 4-sphere (is diffeomorphic to it). A space
homotopy equivalent to the 4-sphere is automatically closed, so "closed" needs no separate
hypothesis. -/
def SmoothPoincareConjectureDimFour : Prop :=
  ∀ (M : Type) [TopologicalSpace M] [T2Space M],
    ContinuousMap.HomotopyEquiv.NonemptyDiffeomorphSphere M 4

/-- Helper: the E8 form on whole-number vectors, written out as twice a whole number. -/
theorem e8_quad_int (v : Fin 8 → ℤ) :
    v ⬝ᵥ (CartanMatrix.E 8 *ᵥ v) = 2 * (v 0 ^ 2 + v 1 ^ 2 + v 2 ^ 2 + v 3 ^ 2 + v 4 ^ 2 + v 5 ^ 2
      + v 6 ^ 2 + v 7 ^ 2 - (v 0 * v 2 + v 1 * v 3 + v 2 * v 3 + v 3 * v 4 + v 4 * v 5
      + v 5 * v 6 + v 6 * v 7)) := by
  rw [CartanMatrix.E_eight_eq]
  simp [dotProduct, mulVec, Fin.sum_univ_eight]
  ring

/-- Helper: the E8 form on real vectors, written out. -/
theorem e8_quad_real (v : Fin 8 → ℝ) :
    v ⬝ᵥ ((CartanMatrix.E 8).map (Int.cast : ℤ → ℝ) *ᵥ v) = 2 * (v 0 ^ 2 + v 1 ^ 2 + v 2 ^ 2
      + v 3 ^ 2 + v 4 ^ 2 + v 5 ^ 2 + v 6 ^ 2 + v 7 ^ 2 - (v 0 * v 2 + v 1 * v 3 + v 2 * v 3
      + v 3 * v 4 + v 4 * v 5 + v 5 * v 6 + v 6 * v 7)) := by
  rw [CartanMatrix.E_eight_eq]
  simp [dotProduct, mulVec, Fin.sum_univ_eight]
  ring

/-- Helper: the written-out E8 form is a sum of squares with positive weights (completing the
square along the diagram), so it is positive unless all eight numbers are zero. -/
theorem e8_quad_pos (a b c d e f g h : ℝ)
    (hne : ¬ (a = 0 ∧ b = 0 ∧ c = 0 ∧ d = 0 ∧ e = 0 ∧ f = 0 ∧ g = 0 ∧ h = 0)) :
    0 < 2 * (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 + e ^ 2 + f ^ 2 + g ^ 2 + h ^ 2 -
      (a * c + b * d + c * d + d * e + e * f + f * g + g * h)) := by
  have key : 2 * (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 + e ^ 2 + f ^ 2 + g ^ 2 + h ^ 2 -
      (a * c + b * d + c * d + d * e + e * f + f * g + g * h)) =
      2 * ((a - c / 2) ^ 2 + (b - d / 2) ^ 2 + (h - g / 2) ^ 2 + 3 / 4 * (g - 2 / 3 * f) ^ 2
        + 2 / 3 * (f - 3 / 4 * e) ^ 2 + 5 / 8 * (e - 4 / 5 * d) ^ 2
        + 3 / 4 * (c - 2 / 3 * d) ^ 2 + 1 / 60 * d ^ 2) := by ring
  rw [key]
  by_contra hle
  push Not at hle
  have s1 := sq_nonneg (a - c / 2)
  have s2 := sq_nonneg (b - d / 2)
  have s3 := sq_nonneg (h - g / 2)
  have s4 := sq_nonneg (g - 2 / 3 * f)
  have s5 := sq_nonneg (f - 3 / 4 * e)
  have s6 := sq_nonneg (e - 4 / 5 * d)
  have s7 := sq_nonneg (c - 2 / 3 * d)
  have s8 := sq_nonneg d
  have z (x : ℝ) (hx : x ^ 2 = 0) : x = 0 := pow_eq_zero_iff two_ne_zero |>.1 hx
  have hd : d = 0 := z _ (by linarith)
  have hc : c - 2 / 3 * d = 0 := z _ (by linarith)
  have he : e - 4 / 5 * d = 0 := z _ (by linarith)
  have hf : f - 3 / 4 * e = 0 := z _ (by linarith)
  have hg : g - 2 / 3 * f = 0 := z _ (by linarith)
  have ha : a - c / 2 = 0 := z _ (by linarith)
  have hb : b - d / 2 = 0 := z _ (by linarith)
  have hh : h - g / 2 = 0 := z _ (by linarith)
  apply hne
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> linarith

/-- Helper: a whole-number vector has square 1 exactly when it is plus or minus a basis vector. -/
theorem dot_self_eq_one_iff {n : ℕ} (v : Fin n → ℤ) :
    v ⬝ᵥ v = 1 ↔ ∃ p : Fin n × Bool, Pi.single p.1 (if p.2 then 1 else -1) = v := by
  constructor
  · intro h
    have hs : ∑ i, v i ^ 2 = 1 := by simpa [dotProduct, sq] using h
    have hle : ∀ i, v i ^ 2 ≤ 1 := fun i => by
      rw [← hs]
      exact Finset.single_le_sum (f := fun i => v i ^ 2) (fun j _ => sq_nonneg _)
        (Finset.mem_univ i)
    obtain ⟨i, hi⟩ : ∃ i, v i ≠ 0 := by
      by_contra hc
      push Not at hc
      simp [hc] at hs
    have hi1 : v i ^ 2 = 1 := by
      have := hle i
      have : 0 < v i ^ 2 := by positivity
      omega
    have hrest : ∀ j, j ≠ i → v j = 0 := by
      intro j hj
      have := Finset.add_sum_erase Finset.univ (fun i => v i ^ 2) (Finset.mem_univ i)
      have h2 : v j ^ 2 ≤ ∑ k ∈ Finset.univ.erase i, v k ^ 2 :=
        Finset.single_le_sum (f := fun k => v k ^ 2) (fun k _ => sq_nonneg _)
          (Finset.mem_erase.2 ⟨hj, Finset.mem_univ j⟩)
      have : v j ^ 2 = 0 := by nlinarith [sq_nonneg (v j)]
      exact pow_eq_zero_iff two_ne_zero |>.1 this
    have hpm : v i = 1 ∨ v i = -1 := by
      have : (v i - 1) * (v i + 1) = 0 := by nlinarith
      rcases mul_eq_zero.1 this with h | h
      · left; linarith
      · right; linarith
    refine ⟨(i, decide (v i = 1)), ?_⟩
    funext j
    by_cases hj : j = i
    · subst hj; rcases hpm with h | h <;> simp [h]
    · simp [hj, hrest j hj]
  · rintro ⟨⟨i, b⟩, rfl⟩
    cases b <;> simp [dotProduct, Pi.single_apply]

/-- Helper: the rank-8 diagonal form has exactly 16 vectors of square 1. -/
theorem diag_eight_unit_vectors_ncard : {v : Fin 8 → ℤ | v ⬝ᵥ v = 1}.ncard = 16 := by
  have : {v : Fin 8 → ℤ | v ⬝ᵥ v = 1} =
      Set.range (fun p : Fin 8 × Bool => (Pi.single p.1 (if p.2 then 1 else -1) : Fin 8 → ℤ)) := by
    ext v; exact dot_self_eq_one_iff v
  rw [this, ← Set.image_univ, Set.ncard_image_of_injective]
  · simp [Set.ncard_univ]
  · rintro ⟨i, a⟩ ⟨j, b⟩ h
    have hij : i = j := by
      by_contra hne
      have := congrFun h i
      cases a <;> simp [hne] at this
    subst hij
    have := congrFun h i
    cases a <;> cases b <;> simp at this ⊢

/-- Helper: if `Pᵀ M P = 1`, then the first column of `P` has square 1 under `M`. -/
theorem first_column_square_one (P M : Matrix (Fin 8) (Fin 8) ℤ) (hP : Pᵀ * M * P = 1) :
    (fun k => P k 0) ⬝ᵥ (M *ᵥ (fun k => P k 0)) = 1 := by
  have key : (fun k => P k 0) ⬝ᵥ (M *ᵥ (fun k => P k 0)) = (Pᵀ * M * P) 0 0 := by
    simp only [dotProduct, mulVec, Matrix.mul_apply, transpose_apply, Finset.mul_sum,
      Finset.sum_mul]
    rw [Finset.sum_comm]
    exact Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun k _ => by ring
  rw [key, hP]; rfl

/-- The E8 form is even, unimodular and positive definite, so its signature is 8: every
diagonal entry is 2, the form is symmetric, every whole-number vector has an even square
`v · E8 v`, the determinant is 1, and every nonzero real vector has a positive square. -/
theorem e8_form_even_unimodular_positive_definite :
    (∀ i, CartanMatrix.E 8 i i = 2) ∧ (CartanMatrix.E 8).IsSymm ∧
      (∀ v : Fin 8 → ℤ, Even (v ⬝ᵥ (CartanMatrix.E 8 *ᵥ v))) ∧
      (CartanMatrix.E 8).det = 1 ∧
      ∀ v : Fin 8 → ℝ, v ≠ 0 →
        0 < v ⬝ᵥ ((CartanMatrix.E 8).map (Int.cast : ℤ → ℝ) *ᵥ v) := by
  refine ⟨CartanMatrix.E_diag 8, CartanMatrix.E_isSymm 8, fun v => ?_, CartanMatrix.E₈_det,
    fun v hv => ?_⟩
  · rw [e8_quad_int]; exact even_two_mul _
  · rw [e8_quad_real]
    apply e8_quad_pos
    rintro ⟨h0, h1, h2, h3, h4, h5, h6, h7⟩
    apply hv
    funext i
    fin_cases i <;> simpa

/-- E8 is not the diagonal form: no whole-number vector has square `v · E8 v = 1`, so no
whole-number change of basis `P` turns E8 into the diagonal form (`Pᵀ E8 P = 1`); the diagonal
form of rank 8 has exactly 16 vectors of square 1 (plus or minus each basis vector). With
Donaldson's theorem (a smooth closed simply connected 4-manifold with a positive definite form
has the diagonal form), this is why Freedman's E8 manifold has no smooth structure. -/
theorem e8_not_diagonal :
    (∀ v : Fin 8 → ℤ, v ⬝ᵥ (CartanMatrix.E 8 *ᵥ v) ≠ 1) ∧
      (¬ ∃ P : Matrix (Fin 8) (Fin 8) ℤ, Pᵀ * CartanMatrix.E 8 * P = 1) ∧
      {v : Fin 8 → ℤ | v ⬝ᵥ v = 1}.ncard = 16 := by
  have hev : ∀ v : Fin 8 → ℤ, Even (v ⬝ᵥ (CartanMatrix.E 8 *ᵥ v)) := fun v => by
    rw [e8_quad_int]; exact even_two_mul _
  refine ⟨fun v h => ?_, ?_, diag_eight_unit_vectors_ncard⟩
  · have := hev v
    rw [h] at this
    exact Int.not_even_one this
  · rintro ⟨P, hP⟩
    have := hev (fun k => P k 0)
    rw [first_column_square_one P _ hP] at this
    exact Int.not_even_one this

/-- Milnor's signature road to 28. On a closed 8-manifold with `p₁ = 0`, the Â-genus is
`−p₂/1440` and the signature is `7p₂/45`. If `−p₂/1440` is a whole number, the signature is a
whole multiple of 224. And `k` copies of the E8 plumbing, of signature `8k`, reach a multiple of
224 exactly when 28 divides `k`, so 28 is the smallest such number of copies. -/
theorem milnor_signature_steps (p₂ : ℤ) (hA : ∃ a : ℤ, -(p₂ : ℚ) / 1440 = a) :
    (∃ m : ℤ, 7 * (p₂ : ℚ) / 45 = 224 * m) ∧ ∀ k : ℕ, 224 ∣ 8 * k ↔ 28 ∣ k := by
  obtain ⟨a, ha⟩ := hA
  refine ⟨⟨-a, ?_⟩, fun k => by omega⟩
  have h : (p₂ : ℚ) = -1440 * a := by rw [← ha]; ring
  rw [h]; push_cast; ring

-- Bernoulli numbers B4 = −1/30 and B6 = 1/42 (Mathlib's `bernoulli`).
example : bernoulli 4 = -1 / 30 ∧ bernoulli 6 = 1 / 42 := by
  have h5 : bernoulli' 5 = 0 := by
    rw [bernoulli'_def]; norm_num [Finset.sum_range_succ, Nat.choose]
  refine ⟨by rw [bernoulli_eq_bernoulli'_of_ne_one (by decide), bernoulli'_four], ?_⟩
  rw [bernoulli_eq_bernoulli'_of_ne_one (by decide), bernoulli'_def]
  norm_num [Finset.sum_range_succ, Nat.choose, h5]
-- Road 1 to 28, the bP formula 2^(2k−2) (2^(2k−1) − 1) × numerator(4|B_2k|/k):
-- k = 2 gives 4 × 7 × 1 = 28; k = 3 gives 16 × 31 × 2 = 992.
example : 2 ^ 2 * (2 ^ 3 - 1) * ((4 * |(-1 / 30 : ℚ)| / 2).num) = 28 ∧
    2 ^ 4 * (2 ^ 5 - 1) * ((4 * |(1 / 42 : ℚ)| / 3).num) = 992 := by norm_num
-- k = 4 gives 64 × 127 × 1 = 8,128, which divides the table's 16,256 = 2 × 8,128.
example : 2 ^ 6 * (2 ^ 7 - 1) * 1 = 8128 ∧ 16256 % 8128 = 0 ∧ 16256 = 2 * 8128 := by decide
-- What breaks: at k = 1 the formula gives 1 × 1 × 2 = 2, though the 3-sphere has 1 smooth structure.
example : 2 ^ 0 * (2 ^ 1 - 1) * ((4 * |(1 / 6 : ℚ)| / 1).num) = 2 := by norm_num
-- Try changing: k = 5 gives 256 × 511 × 2 = 261,632.
example : 2 ^ 8 * (2 ^ 9 - 1) * 2 = 261632 := by decide
-- Road 2 to 28: steps of p₂ are 1440, signature steps 7 × 1440 / 45 = 224, and 224 / 8 = 28.
example : 7 * 1440 / 45 = 224 ∧ 7 * 1440 % 45 = 0 ∧ 224 / 8 = 28 := by decide
-- The L and Â coefficients: L = (7p₂ − p₁²)/45 and Â = (−4p₂ + 7p₁²)/5760, so Â = −p₂/1440 at p₁ = 0.
example : (-4 : ℚ) / 5760 = -1 / 1440 := by norm_num
-- Copies of the E8 plumbing below 60 whose signature 8k is a multiple of 224: 28 and 56.
example : (List.range 60).filter (fun k => k ≠ 0 ∧ 224 ∣ 8 * k) = [28, 56] := by decide
-- Below 100: 28, 56 and 84.
example : (List.range 100).filter (fun k => k ≠ 0 ∧ 224 ∣ 8 * k) = [28, 56, 84] := by decide
-- E8's diagonal is all 2s, so the form is even.
example : ∀ i, CartanMatrix.E 8 i i = 2 := by decide
-- Rokhlin's test: a smooth even form needs signature divisible by 16; E8 gives 8 mod 16 = 8.
example : 8 % 16 = 8 ∧ ¬ (16 ∣ 8) := by decide
-- E8's 240 vectors of square 2: 4 × C(8, 2) + 2^7 = 112 + 128 = 240; the diagonal form has
-- 2 × 8 = 16 vectors of square 1.
example : 4 * Nat.choose 8 2 = 112 ∧ 2 ^ 7 = 128 ∧ 112 + 128 = 240 ∧ 2 * 8 = 16 := by decide
-- Whitney disc self-crossing dimension 2 + 2 − d in a level of dimension d = 4, 5, 6, 7: 0, −1, −2, −3.
example : (List.range' 4 4).map (fun d : ℕ => (2 + 2 : ℤ) - d) = [0, -1, -2, -3] := by decide

#print axioms e8_quad_int
#print axioms e8_quad_real
#print axioms e8_quad_pos
#print axioms dot_self_eq_one_iff
#print axioms diag_eight_unit_vectors_ncard
#print axioms first_column_square_one
#print axioms e8_form_even_unimodular_positive_definite
#print axioms e8_not_diagonal
#print axioms milnor_signature_steps
