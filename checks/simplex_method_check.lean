-- The simplex method: a corner whose profit row has no negative entry is a best plan, a ratio-test step along an edge keeps the plan allowed and changes profit by the gain per unit times the step, and resource prices that cover every product's profit bound every plan's profit.
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Real.Basic
import Mathlib.Tactic

open Matrix

/-- Helper: an invertible column-selection `A.submatrix id β` forces `β` to be injective. -/
lemma simplex_basis_injective {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (β : Fin m → Fin n)
    (hB : IsUnit (A.submatrix id β).det) : Function.Injective β := by
  intro i i' h
  by_contra hne
  apply hB.ne_zero
  exact Matrix.det_zero_of_column_eq hne (fun k => by simp [h])

/-- Helper: a sum against a vector that vanishes off the basic columns is a sum over the basis. -/
lemma simplex_sum_basic {m n : ℕ} (β : Fin m → Fin n) (hβ : Function.Injective β)
    (f x : Fin n → ℝ) (hx : ∀ k, k ∉ Set.range β → x k = 0) :
    ∑ k, f k * x k = ∑ i, f (β i) * x (β i) := by
  have himg : ∑ k ∈ Finset.univ.image β, f k * x k = ∑ i, f (β i) * x (β i) :=
    Finset.sum_image (fun i _ i' _ h => hβ h)
  rw [← himg]
  symm
  apply Finset.sum_subset (Finset.subset_univ _)
  intro k _ hk
  rw [hx k ?_, mul_zero]
  rintro ⟨i, rfl⟩
  exact hk (Finset.mem_image_of_mem β (Finset.mem_univ i))

/-- Helper: the same, when one extra non-basic coordinate `j` may be non-zero. -/
lemma simplex_sum_enter {m n : ℕ} (β : Fin m → Fin n) (hβ : Function.Injective β)
    (j : Fin n) (hj : j ∉ Set.range β)
    (f x : Fin n → ℝ) (hx : ∀ k, k ≠ j → k ∉ Set.range β → x k = 0) :
    ∑ k, f k * x k = ∑ i, f (β i) * x (β i) + f j * x j := by
  set x' : Fin n → ℝ := fun k => if k = j then 0 else x k with hx'
  have h1 : ∑ k, f k * x k = ∑ k, f k * x' k + ∑ k, f k * (if k = j then x j else 0) := by
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl (fun k _ => ?_)
    by_cases hk : k = j
    · subst hk; simp [hx']
    · simp [hx', hk]
  have h2 : ∑ k, f k * (if k = j then x j else 0) = f j * x j := by simp
  have h3 : ∀ k, k ∉ Set.range β → x' k = 0 := by
    intro k hk
    by_cases hkj : k = j
    · simp [hx', hkj]
    · simp [hx', hkj, hx k hkj hk]
  rw [h1, h2, simplex_sum_basic β hβ f x' h3]
  congr 1
  refine Finset.sum_congr rfl (fun i _ => ?_)
  have : β i ≠ j := fun h => hj ⟨i, h⟩
  simp [hx', this]

#print axioms simplex_basis_injective
#print axioms simplex_sum_basic
#print axioms simplex_sum_enter

/-- The stopping test. Take a linear program in standard form: maximise `c ⬝ᵥ x` subject to
`A *ᵥ x = b` and `x ≥ 0`. Pick one basic column `β i` of `A` per limit `i`, so that the basis
matrix `B` (those columns) is invertible, and let `xstar` be its corner: basic variables
`B⁻¹ *ᵥ b`, the rest zero. If that corner is allowed (`B⁻¹ *ᵥ b ≥ 0`) and every non-basic entry
of the profit row `r = (c_B ᵥ* B⁻¹) ᵥ* A - c` is non-negative, then the corner is an allowed
plan and no allowed plan earns more. -/
theorem simplex_stopping_test_proves_optimal {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (β : Fin m → Fin n) (B : Matrix (Fin m) (Fin m) ℝ) (hBdef : B = A.submatrix id β)
    (hB : IsUnit B.det)
    (xstar : Fin n → ℝ)
    (hbasic : ∀ i, xstar (β i) = (B⁻¹ *ᵥ b) i)
    (hnonbasic : ∀ k, k ∉ Set.range β → xstar k = 0)
    (hfeas : ∀ i, 0 ≤ (B⁻¹ *ᵥ b) i)
    (hstop : ∀ k, k ∉ Set.range β → 0 ≤ (((c ∘ β) ᵥ* B⁻¹) ᵥ* A) k - c k) :
    A *ᵥ xstar = b ∧ 0 ≤ xstar ∧
      ∀ x : Fin n → ℝ, 0 ≤ x → A *ᵥ x = b → c ⬝ᵥ x ≤ c ⬝ᵥ xstar := by
  subst hBdef
  have hβ := simplex_basis_injective A β hB
  have hAx : A *ᵥ xstar = (A.submatrix id β) *ᵥ ((A.submatrix id β)⁻¹ *ᵥ b) := by
    ext r
    simp only [mulVec, dotProduct, submatrix_apply, id]
    rw [simplex_sum_basic β hβ (A r) xstar hnonbasic]
    exact Finset.sum_congr rfl (fun i _ => by rw [hbasic i]; rfl)
  have hfeasible : A *ᵥ xstar = b := by
    rw [hAx, mulVec_mulVec, mul_nonsing_inv _ hB, one_mulVec]
  refine ⟨hfeasible, ?_, ?_⟩
  · intro k
    by_cases hk : k ∈ Set.range β
    · obtain ⟨i, rfl⟩ := hk
      simp only [Pi.zero_apply]
      rw [hbasic i]
      exact hfeas i
    · simp only [Pi.zero_apply]
      rw [hnonbasic k hk]
  · intro x hx hAxb
    set y := (c ∘ β) ᵥ* (A.submatrix id β)⁻¹ with hy
    have hyB : y ᵥ* (A.submatrix id β) = c ∘ β := by
      rw [hy, vecMul_vecMul, nonsing_inv_mul _ hB, vecMul_one]
    have hcover : c ≤ y ᵥ* A := by
      intro k
      by_cases hk : k ∈ Set.range β
      · obtain ⟨i, rfl⟩ := hk
        have h1 : (y ᵥ* A) (β i) = (y ᵥ* (A.submatrix id β)) i := by
          simp [vecMul, dotProduct, submatrix_apply]
        rw [h1, hyB]
        simp
      · have := hstop k hk
        linarith
    have hcstar : c ⬝ᵥ xstar = y ⬝ᵥ b := by
      rw [hy, ← dotProduct_mulVec]
      simp only [dotProduct]
      rw [simplex_sum_basic β hβ c xstar hnonbasic]
      exact Finset.sum_congr rfl (fun i _ => by rw [hbasic i]; rfl)
    calc c ⬝ᵥ x ≤ (y ᵥ* A) ⬝ᵥ x := dotProduct_le_dotProduct_of_nonneg_right hcover hx
      _ = y ⬝ᵥ (A *ᵥ x) := (dotProduct_mulVec y A x).symm
      _ = c ⬝ᵥ xstar := by rw [hAxb, hcstar]

/-- One pivot's walk along an edge, and the ratio test. At an allowed corner, as above, let the
non-basic variable `j` enter and rise by `t ≥ 0`, with the other non-basic variables held at
zero; each basic variable falls at the rate `d = B⁻¹ *ᵥ (column j of A)`. The moved point still
satisfies `A *ᵥ x = b`; its profit is the old profit plus `(-r j) * t`, so it never falls when
`r j < 0`; and it stays allowed exactly when `t` is at most every ratio `xB i / d i` over the rows
with `d i > 0`. (When no `d i` is positive, every step is allowed: the program is unbounded.) -/
theorem simplex_ratio_test_step {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (β : Fin m → Fin n) (B : Matrix (Fin m) (Fin m) ℝ) (hBdef : B = A.submatrix id β)
    (hB : IsUnit B.det)
    (xstar : Fin n → ℝ)
    (hbasic : ∀ i, xstar (β i) = (B⁻¹ *ᵥ b) i)
    (hnonbasic : ∀ k, k ∉ Set.range β → xstar k = 0)
    (hfeas : ∀ i, 0 ≤ (B⁻¹ *ᵥ b) i)
    (j : Fin n) (hj : j ∉ Set.range β)
    (t : ℝ) (ht : 0 ≤ t)
    (xt : Fin n → ℝ)
    (hxt_enter : xt j = t)
    (hxt_basic : ∀ i, xt (β i) = (B⁻¹ *ᵥ b) i - t * (B⁻¹ *ᵥ (fun i' => A i' j)) i)
    (hxt_rest : ∀ k, k ≠ j → k ∉ Set.range β → xt k = 0) :
    A *ᵥ xt = b ∧
      c ⬝ᵥ xt = c ⬝ᵥ xstar + (-((((c ∘ β) ᵥ* B⁻¹) ᵥ* A) j - c j)) * t ∧
      ((((c ∘ β) ᵥ* B⁻¹) ᵥ* A) j - c j < 0 → c ⬝ᵥ xstar ≤ c ⬝ᵥ xt) ∧
      (0 ≤ xt ↔ ∀ i, 0 < (B⁻¹ *ᵥ (fun i' => A i' j)) i →
        t ≤ (B⁻¹ *ᵥ b) i / (B⁻¹ *ᵥ (fun i' => A i' j)) i) := by
  subst hBdef
  have hβ := simplex_basis_injective A β hB
  set B := A.submatrix id β with hBB
  set v := B⁻¹ *ᵥ b with hv
  set a : Fin m → ℝ := fun i' => A i' j with ha
  set d := B⁻¹ *ᵥ a with hd
  have hrest : ∀ k, k ≠ j → k ∉ Set.range β → xt k = 0 := hxt_rest
  have hsum : ∀ f : Fin n → ℝ, ∑ k, f k * xt k = ∑ i, f (β i) * (v i - t * d i) + f j * t := by
    intro f
    rw [simplex_sum_enter β hβ j hj f xt hrest, hxt_enter]
    congr 1
    exact Finset.sum_congr rfl (fun i _ => by rw [hxt_basic i])
  have hBv : B *ᵥ v = b := by rw [hv, mulVec_mulVec, mul_nonsing_inv _ hB, one_mulVec]
  have hBd : B *ᵥ d = a := by rw [hd, mulVec_mulVec, mul_nonsing_inv _ hB, one_mulVec]
  have hsplit : ∀ f : Fin m → ℝ, ∑ i, f i * (v i - t * d i) = ∑ i, f i * v i - t * ∑ i, f i * d i := by
    intro f
    rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl (fun i _ => by ring)
  have hstar : c ⬝ᵥ xstar = ∑ i, c (β i) * v i := by
    simp only [dotProduct]
    rw [simplex_sum_basic β hβ c xstar hnonbasic]
    exact Finset.sum_congr rfl (fun i _ => by rw [hbasic i])
  have hrj : (((c ∘ β) ᵥ* B⁻¹) ᵥ* A) j = ∑ i, c (β i) * d i := by
    have h1 : (((c ∘ β) ᵥ* B⁻¹) ᵥ* A) j = ((c ∘ β) ᵥ* B⁻¹) ⬝ᵥ a := by
      simp [vecMul, dotProduct, ha]
    rw [h1, ← dotProduct_mulVec]
    rfl
  have hprofit : c ⬝ᵥ xt = c ⬝ᵥ xstar + (-((((c ∘ β) ᵥ* B⁻¹) ᵥ* A) j - c j)) * t := by
    have h1 : c ⬝ᵥ xt = ∑ k, c k * xt k := rfl
    rw [h1, hsum c, hsplit, hstar, hrj]
    ring
  refine ⟨?_, hprofit, ?_, ?_⟩
  · ext r
    have h1 : (A *ᵥ xt) r = ∑ k, A r k * xt k := rfl
    have h2 : b r = ∑ i, A r (β i) * v i := by
      rw [← hBv]; rfl
    have h3 : A r j = ∑ i, A r (β i) * d i := (congrFun hBd r).symm
    rw [h1, hsum (A r), hsplit, h2, h3]
    ring
  · intro hneg
    rw [hprofit]
    have : 0 ≤ (-((((c ∘ β) ᵥ* B⁻¹) ᵥ* A) j - c j)) * t := mul_nonneg (by linarith) ht
    linarith
  · constructor
    · intro hnn i hdi
      have h0 := hnn (β i)
      simp only [Pi.zero_apply] at h0
      rw [hxt_basic i] at h0
      rw [le_div_iff₀ hdi]
      linarith
    · intro hratio k
      simp only [Pi.zero_apply]
      by_cases hk : k ∈ Set.range β
      · obtain ⟨i, rfl⟩ := hk
        rw [hxt_basic i]
        by_cases hdi : 0 < d i
        · have := hratio i hdi
          rw [le_div_iff₀ hdi] at this
          linarith
        · replace hdi : d i ≤ 0 := not_lt.mp hdi
          have h1 := hfeas i
          have h2 : t * d i ≤ 0 := mul_nonpos_of_nonneg_of_nonpos ht hdi
          linarith
      · by_cases hkj : k = j
        · rw [hkj, hxt_enter]; exact ht
        · rw [hrest k hkj hk]

/-- The price bound. For limits `A *ᵥ x ≤ b` with `x ≥ 0`, if the resource prices `y ≥ 0`
cover each product's profit (`c ≤ y ᵥ* A`), then no allowed plan earns more than the
resources are worth: `c ⬝ᵥ x ≤ y ⬝ᵥ b`. -/
theorem prices_bound_every_plan {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ) (y : Fin m → ℝ)
    (hy : 0 ≤ y) (hcover : c ≤ y ᵥ* A)
    (x : Fin n → ℝ) (hx : 0 ≤ x) (hAx : A *ᵥ x ≤ b) :
    c ⬝ᵥ x ≤ y ⬝ᵥ b := by
  calc c ⬝ᵥ x ≤ (y ᵥ* A) ⬝ᵥ x := dotProduct_le_dotProduct_of_nonneg_right hcover hx
    _ = y ⬝ᵥ (A *ᵥ x) := (dotProduct_mulVec y A x).symm
    _ ≤ y ⬝ᵥ b := dotProduct_le_dotProduct_of_nonneg_left hAx hy

-- The workshop's best plan, 32 tables and 16 chairs, fits all three limits and earns £928.
example : 4 * 32 + 2 * 16 ≤ 160 ∧ 3 * 32 + 1 * 16 ≤ 120 ∧ 1 * 32 + 2 * 16 ≤ 64 := by decide
example : 19 * 32 + 20 * 16 = 928 := by norm_num
-- In standard form, x = (32, 16, 0, 8, 0) solves the three equations.
example : 4 * 32 + 2 * 16 + 0 = 160 ∧ 3 * 32 + 1 * 16 + 8 = 120 ∧ 1 * 32 + 2 * 16 + 0 = 64 := by
  decide
-- The prices £3, £0, £7 cover tables (19) and chairs (20), and value the week's stock at £928.
example : 4 * 3 + 3 * 0 + 1 * 7 = 19 ∧ 2 * 3 + 1 * 0 + 2 * 7 = 20 := by decide
example : 160 * 3 + 120 * 0 + 64 * 7 = 928 := by norm_num
-- The four corners' profits: (0, 0) 0, (0, 32) 640, (32, 16) 928, (40, 0) 760.
example : 19 * 0 + 20 * 0 = 0 ∧ 19 * 0 + 20 * 32 = 640 ∧ 19 * 40 + 20 * 0 = 760 := by decide
-- Pivot 1: ratios 40, 40, 64; profit 0 + 19 × 40 = 760.
example : (160 : ℚ) / 4 = 40 ∧ (120 : ℚ) / 3 = 40 ∧ (64 : ℚ) / 1 = 64 := by norm_num
example : 0 + 19 * 40 = 760 := by norm_num
-- Pivot 2: chairs' entry -20 + 19 × 1/3 = -41/3; ratios 0, 120, 72/5; profit stays 760.
example : (-20 : ℚ) + 19 * (1 / 3) = -41 / 3 := by norm_num
example : (0 : ℚ) / (2 / 3) = 0 ∧ (40 : ℚ) / (1 / 3) = 120 ∧ (24 : ℚ) / (5 / 3) = 72 / 5 := by
  norm_num
example : (760 : ℚ) + 41 / 3 * 0 = 760 := by norm_num
-- Pivot 3: ratios 40, 8; profit 760 + 21 × 8 = 928.
example : (40 : ℚ) / 1 = 40 ∧ (24 : ℚ) / 3 = 8 := by norm_num
example : 760 + 21 * 8 = 928 := by norm_num
-- Skipping the ratio test: (64, 0) leaves timber slack -96 and labour slack -72, "earning" £1,216.
example : (160 : ℤ) - 4 * 64 = -96 ∧ (120 : ℤ) - 3 * 64 = -72 ∧ 19 * 64 = 1216 := by decide
-- Stopping at the step-0 pivot leaves £760, short by £168.
example : 928 - 760 = 168 := by norm_num
-- 10 ways to pick 3 basic columns of 5; the 3-variable Klee–Minty cube takes 2^3 - 1 = 7 pivots.
example : Nat.choose 5 3 = 10 := by decide
example : 2 ^ 3 - 1 = 7 := by decide

#print axioms simplex_stopping_test_proves_optimal
#print axioms simplex_ratio_test_step
#print axioms prices_bound_every_plan
