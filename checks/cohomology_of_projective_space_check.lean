-- Cohomology of projective space: projective n-space splits into one affine cell for each k from 0 to n, so over a field with q elements it has 1 + q + ... + q^n points, and the circle x^2 + y^2 = 25z^2 meets the hyperbola xy = 12z^2 in exactly 2 × 2 = 4 points of the complex projective plane.
import Mathlib.LinearAlgebra.Projectivization.Cardinality
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Complex.Basic
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.FieldSimp

open scoped LinearAlgebra.Projectivization Matrix

/-- Two coordinate vectors in the cell normal form (last nonzero coordinate equal to 1) that
differ by a scalar factor are equal. -/
theorem cell_rep_unique_aux {K : Type*} [Field K] {n : ℕ} (w w' : Fin (n + 1) → K) (c : K)
    (hc : c • w = w') (k k' : Fin (n + 1)) (hk : w k = 1) (hk' : ∀ j, k < j → w j = 0)
    (hl : w' k' = 1) (hl' : ∀ j, k' < j → w' j = 0) : w' = w := by
  have hcj : ∀ j, w' j = c * w j := fun j => by rw [← hc]; rfl
  have hkk : k = k' := by
    rcases lt_trichotomy k k' with h | h | h
    · have := hk' k' h
      rw [hcj, this, mul_zero] at hl
      exact absurd hl zero_ne_one
    · exact h
    · have := hl' k h
      rw [hcj, hk, mul_one] at this
      rw [hcj, this, zero_mul] at hl
      exact absurd hl zero_ne_one
  subst hkk
  have : c = 1 := by rw [hcj, hk, mul_one] at hl; exact hl
  subst this
  rw [← hc, one_smul]

/-- The two conic equations are unchanged by scaling the coordinate vector. -/
theorem conics_smul_iff (a : ℂ) (ha : a ≠ 0) (v : Fin 3 → ℂ) :
    ((a • v) 0 ^ 2 + (a • v) 1 ^ 2 = 25 * (a • v) 2 ^ 2 ∧ (a • v) 0 * (a • v) 1 = 12 * (a • v) 2 ^ 2)
      ↔ (v 0 ^ 2 + v 1 ^ 2 = 25 * v 2 ^ 2 ∧ v 0 * v 1 = 12 * v 2 ^ 2) := by
  have ha2 : a ^ 2 ≠ 0 := pow_ne_zero 2 ha
  simp only [Pi.smul_apply, smul_eq_mul]
  constructor
  · rintro ⟨h1, h2⟩
    refine ⟨mul_left_cancel₀ ha2 ?_, mul_left_cancel₀ ha2 ?_⟩
    · linear_combination h1
    · linear_combination h2
  · rintro ⟨h1, h2⟩
    exact ⟨by linear_combination a ^ 2 * h1, by linear_combination a ^ 2 * h2⟩

/-- Solving the two conics in an affine chart. -/
theorem conics_affine_solutions (a b : ℂ) (h1 : a ^ 2 + b ^ 2 = 25) (h2 : a * b = 12) :
    (a = 3 ∧ b = 4) ∨ (a = 4 ∧ b = 3) ∨ (a = -3 ∧ b = -4) ∨ (a = -4 ∧ b = -3) := by
  have hp : (a + b - 7) * (a + b + 7) = 0 := by linear_combination h1 + 2 * h2
  have hm : (a - b - 1) * (a - b + 1) = 0 := by linear_combination h1 - 2 * h2
  rcases mul_eq_zero.1 hp with hp | hp <;> rcases mul_eq_zero.1 hm with hm | hm
  · right; left; constructor
    · linear_combination (hp + hm) / 2
    · linear_combination (hp - hm) / 2
  · left; constructor
    · linear_combination (hp + hm) / 2
    · linear_combination (hp - hm) / 2
  · right; right; left; constructor
    · linear_combination (hp + hm) / 2
    · linear_combination (hp - hm) / 2
  · right; right; right; constructor
    · linear_combination (hp + hm) / 2
    · linear_combination (hp - hm) / 2

/-- A vector with last coordinate 1 is not zero. -/
theorem affine_vec_ne_zero (a b : ℂ) : (![a, b, 1] : Fin 3 → ℂ) ≠ 0 := by
  intro h
  have := congrFun h 2
  simp at this

/-- Two points (a : b : 1) and (a' : b' : 1) agree only when a = a' and b = b'. -/
theorem affine_mk_eq (a b a' b' : ℂ)
    (h : Projectivization.mk ℂ ![a, b, 1] (affine_vec_ne_zero a b)
      = Projectivization.mk ℂ ![a', b', 1] (affine_vec_ne_zero a' b')) : a = a' ∧ b = b' := by
  rw [Projectivization.mk_eq_mk_iff'] at h
  obtain ⟨c, hc⟩ := h
  have h0 := congrFun hc 0
  have h1 := congrFun hc 1
  have h2 := congrFun hc 2
  simp at h0 h1 h2
  subst h2
  simp at h0 h1
  exact ⟨h0.symm, h1.symm⟩

/-- The conic equations hold for a vector exactly when they hold for any other vector
representing the same projective point. -/
theorem conics_of_mk_eq (v w : Fin 3 → ℂ) (hv : v ≠ 0) (hw : w ≠ 0)
    (h : Projectivization.mk ℂ v hv = Projectivization.mk ℂ w hw) :
    (v 0 ^ 2 + v 1 ^ 2 = 25 * v 2 ^ 2 ∧ v 0 * v 1 = 12 * v 2 ^ 2)
      ↔ (w 0 ^ 2 + w 1 ^ 2 = 25 * w 2 ^ 2 ∧ w 0 * w 1 = 12 * w 2 ^ 2) := by
  rw [Projectivization.mk_eq_mk_iff] at h
  obtain ⟨c, hc⟩ := h
  rw [← hc]
  exact conics_smul_iff (c : ℂ) c.ne_zero w

/-- One cell in each dimension: every point of projective n-space over a field K has exactly
one coordinate vector whose last nonzero coordinate is 1. If that coordinate sits in place k,
the point lies in the k-th cell, a copy of K^k given by the k free coordinates before it; so
projective n-space is the disjoint union of the cells K^0, K^1, ..., K^n (over the complex
numbers, one cell in each even real dimension 0, 2, ..., 2n). -/
theorem projective_space_point_has_unique_cell_representative {K : Type*} [Field K] {n : ℕ}
    (P : ℙ K (Fin (n + 1) → K)) :
    ∃! w : Fin (n + 1) → K,
      (∃ hw : w ≠ 0, Projectivization.mk K w hw = P) ∧
      ∃ k : Fin (n + 1), w k = 1 ∧ ∀ j : Fin (n + 1), k < j → w j = 0 := by
  classical
  induction P using Projectivization.ind with
  | h v hv =>
  have hne : (Finset.univ.filter (fun i => v i ≠ 0)).Nonempty := by
    by_contra h
    apply hv
    funext i
    by_contra hi
    exact h ⟨i, by simpa using hi⟩
  set k := (Finset.univ.filter (fun i => v i ≠ 0)).max' hne with hkdef
  have hvk : v k ≠ 0 := by
    have := Finset.max'_mem _ hne
    simpa using this
  have hvj : ∀ j, k < j → v j = 0 := by
    intro j hj
    by_contra h
    have : j ≤ k := Finset.le_max' _ j (by simpa using h)
    exact absurd hj (not_lt.mpr this)
  have hw : (v k)⁻¹ • v ≠ 0 := smul_ne_zero (inv_ne_zero hvk) hv
  refine ⟨(v k)⁻¹ • v, ⟨⟨hw, ?_⟩, k, ?_, ?_⟩, ?_⟩
  · rw [Projectivization.mk_eq_mk_iff' K _ _ hw hv]
    exact ⟨_, rfl⟩
  · simp [hvk]
  · intro j hj
    simp [hvj j hj]
  · rintro w' ⟨⟨hw', hP⟩, k', hl, hl'⟩
    rw [Projectivization.mk_eq_mk_iff' K _ _ hw' hv] at hP
    obtain ⟨a, ha⟩ := hP
    refine cell_rep_unique_aux _ _ (a * (v k)) ?_ k k' (by simp [hvk]) ?_ hl hl'
    · rw [← ha, mul_smul, smul_inv_smul₀ hvk]
    · intro j hj
      simp [hvj j hj]

/-- Point counts read the cells: over a finite field with q elements, projective n-space has
1 + q + q^2 + ... + q^n points, one block of q^k points for each cell K^k; for the plane,
1 + p + p^2 points over the integers mod p. -/
theorem card_projective_space_eq_sum_pow {K : Type*} [Field K] [Finite K] (n : ℕ) :
    Nat.card (ℙ K (Fin (n + 1) → K)) = ∑ k ∈ Finset.range (n + 1), Nat.card K ^ k := by
  exact Projectivization.card_of_finrank K _ (by simp)

/-- Bezout for the card's two conics: the circle x^2 + y^2 = 25z^2 and the hyperbola
xy = 12z^2, each of degree 2, meet in exactly 2 × 2 = 4 points of the complex projective
plane, namely (3 : 4 : 1), (4 : 3 : 1), (−3 : −4 : 1) and (−4 : −3 : 1), none at infinity. -/
theorem circle_meets_hyperbola_in_four_projective_points :
    {P : ℙ ℂ (Fin 3 → ℂ) |
        P.rep 0 ^ 2 + P.rep 1 ^ 2 = 25 * P.rep 2 ^ 2 ∧ P.rep 0 * P.rep 1 = 12 * P.rep 2 ^ 2}.ncard
      = 4 := by
  set f : ℂ → ℂ → ℙ ℂ (Fin 3 → ℂ) :=
    fun a b => Projectivization.mk ℂ ![a, b, 1] (affine_vec_ne_zero a b) with hf
  have hinj : ∀ a b a' b', f a b = f a' b' → a = a' ∧ b = b' :=
    fun a b a' b' h => affine_mk_eq a b a' b' h
  rw [Set.ncard_eq_four]
  refine ⟨f 3 4, f 4 3, f (-3) (-4), f (-4) (-3), ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro h; have := (hinj _ _ _ _ h).1; norm_num at this
  · intro h; have := (hinj _ _ _ _ h).1; norm_num at this
  · intro h; have := (hinj _ _ _ _ h).1; norm_num at this
  · intro h; have := (hinj _ _ _ _ h).1; norm_num at this
  · intro h; have := (hinj _ _ _ _ h).1; norm_num at this
  · intro h; have := (hinj _ _ _ _ h).1; norm_num at this
  ext P
  induction P using Projectivization.ind with
  | h v hv =>
  simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
  rw [conics_of_mk_eq _ v (Projectivization.rep_ne_zero _) hv (Projectivization.mk_rep _)]
  constructor
  · rintro ⟨h1, h2⟩
    have hz : v 2 ≠ 0 := by
      intro hz
      rw [hz] at h1 h2
      have h0 : v 0 = 0 ∨ v 1 = 0 := by
        rcases mul_eq_zero.1 (show v 0 * v 1 = 0 by simpa using h2) with h | h
        · exact Or.inl h
        · exact Or.inr h
      apply hv
      have hb : v 0 = 0 ∧ v 1 = 0 := by
        rcases h0 with h | h
        · rw [h] at h1; refine ⟨h, ?_⟩; simpa using h1
        · rw [h] at h1; refine ⟨?_, h⟩; simpa using h1
      funext i
      fin_cases i
      · exact hb.1
      · exact hb.2
      · exact hz
    have key : Projectivization.mk ℂ v hv = f (v 0 / v 2) (v 1 / v 2) := by
      rw [hf]
      simp only
      rw [Projectivization.mk_eq_mk_iff']
      refine ⟨v 2, ?_⟩
      funext i
      fin_cases i <;> simp <;> field_simp
    rw [key]
    have e1 : (v 0 / v 2) ^ 2 + (v 1 / v 2) ^ 2 = 25 := by
      field_simp
      linear_combination h1
    have e2 : (v 0 / v 2) * (v 1 / v 2) = 12 := by
      field_simp
      linear_combination h2
    rcases conics_affine_solutions _ _ e1 e2 with ⟨ha, hb⟩ | ⟨ha, hb⟩ | ⟨ha, hb⟩ | ⟨ha, hb⟩ <;>
      rw [ha, hb] <;> simp
  · intro h
    have hc : ∀ a b : ℂ, a ^ 2 + b ^ 2 = 25 → a * b = 12 →
        Projectivization.mk ℂ v hv = f a b →
        (v 0 ^ 2 + v 1 ^ 2 = 25 * v 2 ^ 2 ∧ v 0 * v 1 = 12 * v 2 ^ 2) := by
      intro a b hab1 hab2 he
      rw [conics_of_mk_eq v _ hv (affine_vec_ne_zero a b) he]
      simp
      exact ⟨hab1, hab2⟩
    rcases h with h | h | h | h
    · exact hc _ _ (by norm_num) (by norm_num) h
    · exact hc _ _ (by norm_num) (by norm_num) h
    · exact hc _ _ (by norm_num) (by norm_num) h
    · exact hc _ _ (by norm_num) (by norm_num) h

-- Point counts of the plane over the integers mod p: 7, 13, 31 and 57 at p = 2, 3, 5, 7,
-- and 57 = 49 + 7 + 1 by cell.
example : ∑ k ∈ Finset.range 3, 2 ^ k = 7 := by decide
example : ∑ k ∈ Finset.range 3, 3 ^ k = 13 := by decide
example : ∑ k ∈ Finset.range 3, 5 ^ k = 31 := by decide
example : ∑ k ∈ Finset.range 3, 7 ^ k = 57 ∧ 57 = 7 ^ 2 + 7 + 1 := by decide

-- The quadric surface counts 9, 16, 36 and 64 points, which fit 1 + 2p + p^2.
example : [2, 3, 5, 7].map (fun p => 1 + 2 * p + p ^ 2) = [9, 16, 36, 64] := by decide

-- On the line x + y = 7z: the circle gives 2x^2 − 14x + 24 = 0 and the hyperbola
-- −x^2 + 7x − 12 = 0, both with roots x = 3 and 4, so each curve has class 2h.
example : ∀ x ∈ ({3, 4} : Finset ℤ), 2 * x ^ 2 - 14 * x + 24 = 0 ∧ -x ^ 2 + 7 * x - 12 = 0 := by
  decide

-- The eliminant x^4 − 25x^2 + 144 has roots −4, −3, 3, 4, and the four points lie on both curves.
example : ∀ x ∈ ({-4, -3, 3, 4} : Finset ℤ), x ^ 4 - 25 * x ^ 2 + 144 = 0 := by decide
example : ∀ p ∈ ({(3, 4), (4, 3), (-3, -4), (-4, -3)} : Finset (ℤ × ℤ)),
    p.1 ^ 2 + p.2 ^ 2 = 25 ∧ p.1 * p.2 = 12 := by decide

-- The Jacobian 2(x^2 − y^2) at the four points is 14, −14, 14, −14: never 0, clean crossings.
example : ([(3, 4), (4, 3), (-3, -4), (-4, -3)] : List (ℤ × ℤ)).map
    (fun p => 2 * (p.1 ^ 2 - p.2 ^ 2)) = [-14, 14, -14, 14] := by decide

-- The tangent line y = 5z on the circle: x^2 + 25 = 25 leaves x^2 = 0, a double root at x = 0.
example : ∀ x : ℤ, x ^ 2 + 5 ^ 2 = 25 ↔ x * x = 0 := by
  intro x; constructor <;> intro h <;> nlinarith

-- The parallel lines y = 0 and y = z meet at the cross product (−1 : 0 : 0), a point at infinity.
example : crossProduct ![(0 : ℤ), 1, 0] ![0, 1, -1] = ![-1, 0, 0] := by
  simp [cross_apply]

-- The lines x = 0, y = 0 and x + y = z have coefficient determinant −1: no common point, h^3 = 0.
example : Matrix.det !![(1 : ℤ), 0, 0; 0, 1, 0; 1, 1, -1] = -1 := by
  simp [Matrix.det_fin_three]

#print axioms cell_rep_unique_aux
#print axioms conics_smul_iff
#print axioms conics_affine_solutions
#print axioms affine_vec_ne_zero
#print axioms affine_mk_eq
#print axioms conics_of_mk_eq
#print axioms projective_space_point_has_unique_cell_representative
#print axioms card_projective_space_eq_sum_pow
#print axioms circle_meets_hyperbola_in_four_projective_points
