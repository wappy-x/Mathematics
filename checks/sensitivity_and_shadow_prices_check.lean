-- Shadow prices: at a best corner read off a final simplex tableau, the profit row under each slack is that limit's dual price, and moving one limit changes the best profit by that price times the change for as long as the corner's recomputed plan stays non-negative.
import Mathlib.Data.Matrix.ColumnRowPartitioned
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Real.Archimedean
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

/-! Setting, in the card's notation. The program is: maximise `c ⬝ᵥ x` subject to `A *ᵥ x ≤ b`
and `x ≥ 0`, so `A *ᵥ x + s = b` with slacks `s ≥ 0`. With slacks added the columns are
`fromCols A 1` (products `Sum.inl j`, then slack `Sum.inr i` = a single 1 in row `i`) and the
margins are `Sum.elim c 0`. The best profit is
`z*(b) = sSup ((fun x => c ⬝ᵥ x) '' {x | 0 ≤ x ∧ A *ᵥ x ≤ b})`.
A final simplex tableau is a basis `β` (one basic column per limit) whose matrix `B` is
invertible, whose corner `B⁻¹ *ᵥ b` is non-negative, and whose profit row
`r k = (y ᵥ* fromCols A 1) k - Sum.elim c 0 k`, with `y = c_B ᵥ* B⁻¹`, has no negative entry.
Moving limit `i` by `δ` replaces `b` by `b + Pi.single i δ` (that is, `b + δ e_i`). -/

lemma sp_weak {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (y b' : Fin m → ℝ) (c : Fin n → ℝ)
    (hy : 0 ≤ y) (hc : c ≤ y ᵥ* A) (x : Fin n → ℝ) (hx : 0 ≤ x) (hAx : A *ᵥ x ≤ b') :
    c ⬝ᵥ x ≤ y ⬝ᵥ b' := by
  calc c ⬝ᵥ x ≤ (y ᵥ* A) ⬝ᵥ x :=
        Finset.sum_le_sum fun j _ => mul_le_mul_of_nonneg_right (hc j) (hx j)
    _ = y ⬝ᵥ (A *ᵥ x) := (dotProduct_mulVec _ _ _).symm
    _ ≤ y ⬝ᵥ b' := Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_left (hAx i) (hy i)

#print axioms sp_weak

lemma sp_dual_feas {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (c : Fin n → ℝ) (y : Fin m → ℝ)
    (hopt : ∀ k, 0 ≤ (y ᵥ* fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)) k
                      - Sum.elim c (0 : Fin m → ℝ) k) :
    0 ≤ y ∧ c ≤ y ᵥ* A := by
  refine ⟨fun i => ?_, fun j => ?_⟩
  · have := hopt (Sum.inr i)
    simpa [vecMul_fromCols, vecMul_one] using this
  · have := hopt (Sum.inl j)
    simp only [vecMul_fromCols, Sum.elim_inl] at this
    exact sub_nonneg.mp this

#print axioms sp_dual_feas

lemma sp_attained {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (c : Fin n → ℝ)
    (β : Fin m → Fin n ⊕ Fin m) (B : Matrix (Fin m) (Fin m) ℝ)
    (hBdef : B = (fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)).submatrix id β)
    (hB : IsUnit B.det) (b' : Fin m → ℝ) (hb' : 0 ≤ B⁻¹ *ᵥ b') :
    ∃ x : Fin n → ℝ, 0 ≤ x ∧ A *ᵥ x ≤ b' ∧
      c ⬝ᵥ x = ((Sum.elim c (0 : Fin m → ℝ) ∘ β) ᵥ* B⁻¹) ⬝ᵥ b' := by
  classical
  set M := fromCols A (1 : Matrix (Fin m) (Fin m) ℝ) with hM
  set v := B⁻¹ *ᵥ b' with hv
  let P : Matrix (Fin n ⊕ Fin m) (Fin m) ℝ := Matrix.of fun k j => if β j = k then 1 else 0
  have hMP : M * P = B := by
    ext r j
    simp [P, Matrix.mul_apply, hBdef]
  have hcP : Sum.elim c (0 : Fin m → ℝ) ᵥ* P = Sum.elim c (0 : Fin m → ℝ) ∘ β := by
    ext j
    simp [P, Matrix.vecMul, dotProduct]
  set w := P *ᵥ v with hw
  have hw0 : 0 ≤ w := by
    intro k
    simp only [hw, Matrix.mulVec, dotProduct, Pi.zero_apply]
    exact Finset.sum_nonneg fun j _ => by
      simp only [P, Matrix.of_apply]
      split_ifs
      · simpa using hb' j
      · simp
  have hMw : M *ᵥ w = b' := by
    rw [hw, mulVec_mulVec, hMP, hv, mulVec_mulVec, mul_nonsing_inv _ hB, one_mulVec]
  refine ⟨w ∘ Sum.inl, fun j => hw0 _, ?_, ?_⟩
  · have h := hMw
    rw [hM, fromCols_mulVec, one_mulVec] at h
    intro i
    have hi := congrFun h i
    simp only [Pi.add_apply] at hi
    have := hw0 (Sum.inr i)
    simp only [Pi.zero_apply] at this
    simp only [Function.comp_apply] at hi ⊢
    linarith
  · rw [← dotProduct_mulVec, ← hv, ← hcP, ← dotProduct_mulVec, ← hw]
    simp [dotProduct, Fintype.sum_sum_type]

#print axioms sp_attained

lemma sp_value {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (c : Fin n → ℝ)
    (β : Fin m → Fin n ⊕ Fin m) (B : Matrix (Fin m) (Fin m) ℝ)
    (hBdef : B = (fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)).submatrix id β)
    (hB : IsUnit B.det)
    (y : Fin m → ℝ) (hydef : y = (Sum.elim c (0 : Fin m → ℝ) ∘ β) ᵥ* B⁻¹)
    (hopt : ∀ k, 0 ≤ (y ᵥ* fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)) k
                      - Sum.elim c (0 : Fin m → ℝ) k)
    (b' : Fin m → ℝ) (hb' : 0 ≤ B⁻¹ *ᵥ b') :
    sSup ((fun x => c ⬝ᵥ x) '' {x | 0 ≤ x ∧ A *ᵥ x ≤ b'}) = y ⬝ᵥ b' := by
  obtain ⟨hy, hc⟩ := sp_dual_feas A c y hopt
  obtain ⟨x, hx, hAx, hcx⟩ := sp_attained A c β B hBdef hB b' hb'
  apply IsGreatest.csSup_eq
  refine ⟨⟨x, ⟨hx, hAx⟩, by simp [hcx, hydef]⟩, ?_⟩
  rintro _ ⟨x', ⟨hx', hAx'⟩, rfl⟩
  exact sp_weak A y b' c hy hc x' hx' hAx'

#print axioms sp_value

/-- The card's formula. Take the final simplex tableau of the program and its prices
`yᵀ = c_Bᵀ B⁻¹`. Move one limit `i` by `δ`. As long as the corner's plan recomputed for the new
limit, `B⁻¹ (b + δ e_i)`, stays non-negative, the best profit moves by the price times the change:
`z*(b + δ e_i) = z*(b) + y_i δ`. -/
theorem shadow_price_exact_over_its_range {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (β : Fin m → Fin n ⊕ Fin m) (B : Matrix (Fin m) (Fin m) ℝ)
    (hBdef : B = (fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)).submatrix id β)
    (hB : IsUnit B.det)
    (y : Fin m → ℝ) (hydef : y = (Sum.elim c (0 : Fin m → ℝ) ∘ β) ᵥ* B⁻¹)
    (hfeas : 0 ≤ B⁻¹ *ᵥ b)
    (hopt : ∀ k, 0 ≤ (y ᵥ* fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)) k
                      - Sum.elim c (0 : Fin m → ℝ) k)
    (i : Fin m) (δ : ℝ) (hrange : 0 ≤ B⁻¹ *ᵥ (b + Pi.single i δ)) :
    sSup ((fun x => c ⬝ᵥ x) '' {x | 0 ≤ x ∧ A *ᵥ x ≤ b + Pi.single i δ})
      = sSup ((fun x => c ⬝ᵥ x) '' {x | 0 ≤ x ∧ A *ᵥ x ≤ b}) + y i * δ := by
  rw [sp_value A c β B hBdef hB y hydef hopt _ hrange,
    sp_value A c β B hBdef hB y hydef hopt _ hfeas, dotProduct_add, dotProduct_single]

/-- The shadow price is the dual variable, printed in the slack's column. At the same final
tableau, the profit-row entry under slack `i` is exactly `y i`; the prices `y` are a feasible
dual (no price is negative, and what each product uses is worth at least its profit); their
value `y ⬝ᵥ b` equals the best profit; and no feasible dual has a smaller value. -/
theorem shadow_price_is_dual_price_in_slack_column {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (β : Fin m → Fin n ⊕ Fin m) (B : Matrix (Fin m) (Fin m) ℝ)
    (hBdef : B = (fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)).submatrix id β)
    (hB : IsUnit B.det)
    (y : Fin m → ℝ) (hydef : y = (Sum.elim c (0 : Fin m → ℝ) ∘ β) ᵥ* B⁻¹)
    (hfeas : 0 ≤ B⁻¹ *ᵥ b)
    (hopt : ∀ k, 0 ≤ (y ᵥ* fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)) k
                      - Sum.elim c (0 : Fin m → ℝ) k) :
    (∀ i, (y ᵥ* fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)) (Sum.inr i)
            - Sum.elim c (0 : Fin m → ℝ) (Sum.inr i) = y i) ∧
      0 ≤ y ∧ c ≤ y ᵥ* A ∧
      y ⬝ᵥ b = sSup ((fun x => c ⬝ᵥ x) '' {x | 0 ≤ x ∧ A *ᵥ x ≤ b}) ∧
      ∀ y' : Fin m → ℝ, 0 ≤ y' → c ≤ y' ᵥ* A → y ⬝ᵥ b ≤ y' ⬝ᵥ b := by
  obtain ⟨hy, hc⟩ := sp_dual_feas A c y hopt
  refine ⟨fun i => by simp [vecMul_fromCols, vecMul_one], hy, hc,
    (sp_value A c β B hBdef hB y hydef hopt b hfeas).symm, ?_⟩
  intro y' hy' hc'
  obtain ⟨x, hx, hAx, hcx⟩ := sp_attained A c β B hBdef hB b hfeas
  rw [← hydef] at hcx
  rw [← hcx]
  exact sp_weak A y' b c hy' hc' x hx hAx

/-- At a non-degenerate best corner (every basic amount strictly positive), the price is
two-sided: the best profit, as a function of limit `i` alone, has slope exactly `y i` there,
for one unit more and for one unit less alike. -/
theorem shadow_price_two_sided_at_nondegenerate_corner {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (β : Fin m → Fin n ⊕ Fin m) (B : Matrix (Fin m) (Fin m) ℝ)
    (hBdef : B = (fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)).submatrix id β)
    (hB : IsUnit B.det)
    (y : Fin m → ℝ) (hydef : y = (Sum.elim c (0 : Fin m → ℝ) ∘ β) ᵥ* B⁻¹)
    (hnondeg : ∀ k, 0 < (B⁻¹ *ᵥ b) k)
    (hopt : ∀ k, 0 ≤ (y ᵥ* fromCols A (1 : Matrix (Fin m) (Fin m) ℝ)) k
                      - Sum.elim c (0 : Fin m → ℝ) k)
    (i : Fin m) :
    HasDerivAt
      (fun t : ℝ => sSup ((fun x => c ⬝ᵥ x) '' {x | 0 ≤ x ∧ A *ᵥ x ≤ b + Pi.single i t}))
      (y i) 0 := by
  have hlin : HasDerivAt (fun t : ℝ => y ⬝ᵥ b + y i * t) (y i) 0 := by
    simpa using ((hasDerivAt_id (0 : ℝ)).const_mul (y i)).const_add (y ⬝ᵥ b)
  apply hlin.congr_of_eventuallyEq
  have hev : ∀ᶠ t in nhds (0 : ℝ), 0 ≤ B⁻¹ *ᵥ (b + Pi.single i t) := by
    have hall : ∀ᶠ t in nhds (0 : ℝ), ∀ k, 0 < (B⁻¹ *ᵥ (b + Pi.single i t)) k := by
      rw [Filter.eventually_all]
      intro k
      have hcont : Continuous fun t : ℝ => (B⁻¹ *ᵥ b) k + B⁻¹ k i * t := by fun_prop
      have h0 := hcont.continuousAt (x := (0 : ℝ))
      have := h0.eventually (lt_mem_nhds (by simpa using hnondeg k))
      refine this.mono fun t ht => ?_
      rw [mulVec_add, mulVec_single]
      simpa [mul_comm] using ht
    exact hall.mono fun t ht k => (ht k).le
  refine hev.mono fun t ht => ?_
  simp only
  rw [sp_value A c β B hBdef hB y hydef hopt _ ht, dotProduct_add, dotProduct_single]

/-! The workshop: tables and chairs; timber, labour and finish. -/

-- The plan 32 tables and 16 chairs uses 160 m of timber, 112 of the 120 hours, 64 litres of finish.
example : (!![4, 2; 3, 1; 1, 2] : Matrix (Fin 3) (Fin 2) ℤ) *ᵥ ![32, 16] = ![160, 112, 64] := by
  decide

-- Its profit is £928.
example : (![19, 20] : Fin 2 → ℤ) ⬝ᵥ ![32, 16] = 928 := by decide

-- The prices £3, £0, £7 value the stocks at £928, the dual check.
example : (![3, 0, 7] : Fin 3 → ℤ) ⬝ᵥ ![160, 120, 64] = 928 := by decide

-- At those prices a table's stock is worth exactly £19 and a chair's exactly £20 (profit-row entry 0).
example : (![3, 0, 7] : Fin 3 → ℤ) ᵥ* !![4, 2; 3, 1; 1, 2] = ![19, 20] := by decide

-- The stool (1 m, 1 h, 1 l): its stock is worth £10, so r = 1 at a £9 margin and r = -1 at £11.
example : (![3, 0, 7] : Fin 3 → ℤ) ⬝ᵥ ![1, 1, 1] - 9 = 1 := by decide
example : (![3, 0, 7] : Fin 3 → ℤ) ⬝ᵥ ![1, 1, 1] - 11 = -1 := by decide

-- Finish range ends: 928 + 7 × (40 - 64) = 760 = 19 × 40, and 928 + 7 × (160 - 64) = 1600 = 20 × 80.
example : (928 : ℤ) + 7 * (40 - 64) = 760 ∧ (19 : ℤ) * 40 = 760 := by decide
example : (928 : ℤ) + 7 * (160 - 64) = 1600 ∧ (20 : ℤ) * 80 = 1600 := by decide

-- With the stool at £11: 32 tables, 8 chairs, 16 stools use 160 m, 120 h, 64 l and earn £944 = 928 + 16.
example : (!![4, 2, 1; 3, 1, 1; 1, 2, 1] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![32, 8, 16]
    = ![160, 120, 64] := by decide
example : (![19, 20, 11] : Fin 3 → ℤ) ⬝ᵥ ![32, 8, 16] = 944 ∧ (944 : ℤ) = 928 + 16 * 1 := by decide

-- The mistakes: £7 for 100 more litres predicts 1628, not 1600; 16 forced stools at £9 give 912.
example : (928 : ℤ) + 7 * 100 = 1628 ∧ (928 : ℤ) - 16 * 1 = 912 := by decide

#print axioms shadow_price_exact_over_its_range
#print axioms shadow_price_is_dual_price_in_slack_column
#print axioms shadow_price_two_sided_at_nondegenerate_corner
