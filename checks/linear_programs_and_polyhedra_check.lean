-- Linear programs: the best plans of a standard-form linear program form a face, the slack form is the same shape as the picture, and resource prices bound the profit, checked on the furniture workshop.
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Real.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib

open Matrix

/-- The polyhedron of a standard-form program: every `x` with `A x = b` and `x ≥ 0`, entry by entry. -/
def standardPolyhedron {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) : Set (Fin n → ℝ) :=
  {x | A *ᵥ x = b ∧ 0 ≤ x}

/-- The best plans: points of the polyhedron whose cost `c ⬝ᵥ x` is no larger than any other point's. -/
def bestPlans {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ) :
    Set (Fin n → ℝ) :=
  {x | x ∈ standardPolyhedron A b ∧ ∀ y ∈ standardPolyhedron A b, c ⬝ᵥ x ≤ c ⬝ᵥ y}

/-- The set of best plans is always a face, never a scatter of points: for a linear program
minimise `c ⬝ᵥ x` subject to `A x = b`, `x ≥ 0`, if some best plan exists, then there is a set
`S` of variables such that the best plans are exactly the points of the polyhedron where every
variable in `S` is zero. -/
theorem best_plans_form_a_face {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (hbest : (bestPlans A b c).Nonempty) :
    ∃ S : Finset (Fin n),
      bestPlans A b c = {x | x ∈ standardPolyhedron A b ∧ ∀ i ∈ S, x i = 0} := by
  classical
  obtain ⟨x0, hx0⟩ := hbest
  refine ⟨Finset.univ.filter (fun i => ∀ x ∈ bestPlans A b c, x i = 0), ?_⟩
  have hw : ∀ i, ∃ w ∈ bestPlans A b c,
      (i ∉ Finset.univ.filter (fun i => ∀ x ∈ bestPlans A b c, x i = 0) → w i ≠ 0) := by
    intro i
    by_cases hi : i ∈ Finset.univ.filter (fun i => ∀ x ∈ bestPlans A b c, x i = 0)
    · exact ⟨x0, hx0, fun h => (h hi).elim⟩
    · simp only [Finset.mem_filter, Finset.mem_univ, true_and, not_forall] at hi
      obtain ⟨w, hwB, hwi⟩ := hi
      exact ⟨w, hwB, fun _ => hwi⟩
  choose w hwB hwS using hw
  have hval : ∀ u ∈ bestPlans A b c, c ⬝ᵥ u = c ⬝ᵥ x0 := fun u hu =>
    le_antisymm (hu.2 x0 hx0.1) (hx0.2 u hu.1)
  set t : ℝ := 1 / ((n : ℝ) + 1) with ht
  have htpos : 0 < t := by positivity
  set z : Fin n → ℝ := t • (x0 + ∑ i, w i) with hz
  have hzA : A *ᵥ z = b := by
    have h1 : ∀ i, A *ᵥ w i = b := fun i => (hwB i).1.1
    rw [hz, mulVec_smul, mulVec_add, mulVec_sum, hx0.1.1]
    simp only [h1, Finset.sum_const, Finset.card_univ, Fintype.card_fin]
    funext k
    simp only [Pi.smul_apply, Pi.add_apply, nsmul_eq_mul, Pi.mul_apply, smul_eq_mul, Pi.natCast_apply, ht]
    field_simp
    ring
  have hzapp : ∀ j, z j = t * (x0 j + ∑ i, w i j) := by
    intro j; simp [hz, Finset.sum_apply, mul_add]
  have hz0 : 0 ≤ z := by
    intro j
    rw [hzapp]
    have : 0 ≤ ∑ i, w i j := Finset.sum_nonneg (fun i _ => (hwB i).1.2 j)
    have := hx0.1.2 j
    simp only [Pi.zero_apply] at *
    positivity
  have hzc : c ⬝ᵥ z = c ⬝ᵥ x0 := by
    rw [hz, dotProduct_smul, dotProduct_add, dotProduct_sum]
    simp only [fun i => hval (w i) (hwB i), Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul, smul_eq_mul, ht]
    field_simp
    ring
  have hzB : z ∈ bestPlans A b c := ⟨⟨hzA, hz0⟩, fun y hy => hzc ▸ hx0.2 y hy⟩
  have hzpos : ∀ i, i ∉ Finset.univ.filter (fun i => ∀ x ∈ bestPlans A b c, x i = 0) → 0 < z i := by
    intro i hi
    have hwi : 0 < w i i := lt_of_le_of_ne ((hwB i).1.2 i) (Ne.symm (hwS i hi))
    rw [hzapp]
    have : w i i ≤ ∑ k, w k i :=
      Finset.single_le_sum (f := fun k => w k i) (fun k _ => (hwB k).1.2 i) (Finset.mem_univ i)
    have := hx0.1.2 i
    simp only [Pi.zero_apply] at *
    have : 0 < x0 i + ∑ k, w k i := by linarith
    positivity
  clear_value z t
  ext x
  constructor
  · intro hx
    refine ⟨hx.1, fun i hi => ?_⟩
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hi
    exact hi x hx
  · rintro ⟨hxP, hxS⟩
    -- either x i = 0 or z i > 0
    have hor : ∀ i, x i = 0 ∧ z i = 0 ∨ 0 < z i := by
      intro i
      by_cases hi : i ∈ Finset.univ.filter (fun i => ∀ x ∈ bestPlans A b c, x i = 0)
      · left
        refine ⟨hxS i hi, ?_⟩
        simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hi
        exact hi z hzB
      · exact Or.inr (hzpos i hi)
    set T : ℝ := 1 + ∑ i, x i / z i with hT
    have hsum0 : 0 ≤ ∑ i, x i / z i :=
      Finset.sum_nonneg (fun i _ => div_nonneg (hxP.2 i) (hz0 i))
    have hTpos : 0 < T := by linarith
    set ε : ℝ := 1 / T with hε
    have hεpos : 0 < ε := by positivity
    have hεx : ∀ i, ε * x i ≤ z i := by
      intro i
      rcases hor i with ⟨h1, h2⟩ | h
      · rw [h1, h2]; simp
      · have hle : x i / z i ≤ ∑ k, x k / z k :=
          Finset.single_le_sum (f := fun k => x k / z k)
            (fun k _ => div_nonneg (hxP.2 k) (hz0 k)) (Finset.mem_univ i)
        have hxi : x i = z i * (x i / z i) := by field_simp
        rw [hε, div_mul_eq_mul_div, one_mul, div_le_iff₀ hTpos]
        calc x i = z i * (x i / z i) := hxi
          _ ≤ z i * T := by
            apply mul_le_mul_of_nonneg_left _ (le_of_lt h)
            linarith
    clear_value ε
    set y : Fin n → ℝ := z + ε • (z - x) with hy
    have hyP : y ∈ standardPolyhedron A b := by
      refine ⟨?_, ?_⟩
      · rw [hy, mulVec_add, mulVec_smul, mulVec_sub, hzA, hxP.1]; simp
      · intro i
        have := hεx i
        have := hz0 i
        simp only [hy, Pi.add_apply, Pi.smul_apply, Pi.sub_apply, smul_eq_mul, Pi.zero_apply] at *
        nlinarith
    have hcy : c ⬝ᵥ y = c ⬝ᵥ z + ε * (c ⬝ᵥ z - c ⬝ᵥ x) := by
      rw [hy, dotProduct_add, dotProduct_smul, dotProduct_sub, smul_eq_mul]
    have h1 := hx0.2 y hyP
    have hxz : c ⬝ᵥ x ≤ c ⬝ᵥ z := by
      rw [hcy, hzc] at h1
      have : 0 ≤ ε * (c ⬝ᵥ x0 - c ⬝ᵥ x) := by linarith
      have := nonneg_of_mul_nonneg_right this hεpos
      linarith
    refine ⟨hxP, fun y' hy' => ?_⟩
    have := hx0.2 y' hy'
    linarith

/-- The slack form is the same shape as the picture: adding one slack `s = b - A x` per
"at most" limit matches each allowed plan `x ≥ 0`, `A x ≤ b` with exactly one point
`(x, s) ≥ 0` satisfying `A x + s = b`. -/
theorem slack_form_same_shape {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) :
    Set.BijOn (fun x : Fin n → ℝ => (x, b - A *ᵥ x))
      {x | 0 ≤ x ∧ A *ᵥ x ≤ b}
      {p : (Fin n → ℝ) × (Fin m → ℝ) | 0 ≤ p.1 ∧ 0 ≤ p.2 ∧ A *ᵥ p.1 + p.2 = b} := by
  refine ⟨?_, ?_, ?_⟩
  · rintro x ⟨hx, hAx⟩
    exact ⟨hx, sub_nonneg.mpr hAx, add_sub_cancel _ _⟩
  · intro x _ y _ h
    exact (Prod.mk.inj h).1
  · rintro ⟨u, s⟩ ⟨hu, hs, heq⟩
    refine ⟨u, ⟨hu, ?_⟩, ?_⟩
    · rw [← heq]; exact le_add_of_nonneg_right hs
    · simp only [Prod.mk.injEq, true_and]
      rw [← heq]; simp

/-- Prices prove that no plan earns more: if non-negative prices `y` on the resources make every
product "cost" at least its profit (`p ≤ y A`, entry by entry), then every allowed plan
`x ≥ 0`, `A x ≤ b` earns at most what the resources would fetch, `p ⬝ᵥ x ≤ y ⬝ᵥ b`. -/
theorem prices_bound_profit {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (p : Fin n → ℝ) (y : Fin m → ℝ) (hy : 0 ≤ y) (hprice : p ≤ y ᵥ* A)
    (x : Fin n → ℝ) (hx : 0 ≤ x) (hAx : A *ᵥ x ≤ b) :
    p ⬝ᵥ x ≤ y ⬝ᵥ b := by
  calc p ⬝ᵥ x ≤ (y ᵥ* A) ⬝ᵥ x := dotProduct_le_dotProduct_of_nonneg_right hprice hx
    _ = y ⬝ᵥ (A *ᵥ x) := (dotProduct_mulVec y A x).symm
    _ ≤ y ⬝ᵥ b := dotProduct_le_dotProduct_of_nonneg_left hAx hy

/-! The workshop: timber, labour and finish; tables, chairs and three slacks. -/

/-- The workshop's standard-form table `A`. -/
def workshopA : Matrix (Fin 3) (Fin 5) ℤ := !![4, 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1]

-- The best corner from basis x1, x2, s2: x = (32, 16, 0, 8, 0) meets A x = b = (160, 120, 64).
example : workshopA *ᵥ ![32, 16, 0, 8, 0] = ![160, 120, 64] := by
  ext i; fin_cases i <;> simp [workshopA, mulVec, dotProduct, Fin.sum_univ_succ]
-- Its standard-form cost with c = (-19, -20, 0, 0, 0) is p* = -928.
example : ![(-19 : ℤ), -20, 0, 0, 0] ⬝ᵥ ![32, 16, 0, 8, 0] = -928 := by
  simp [dotProduct, Fin.sum_univ_succ]
-- The other corners solve A x = b too: (0, 0), (40, 0), (0, 32) with their slacks.
example : workshopA *ᵥ ![0, 0, 160, 120, 64] = ![160, 120, 64] ∧
    workshopA *ᵥ ![40, 0, 0, 0, 24] = ![160, 120, 64] ∧
    workshopA *ᵥ ![0, 32, 96, 88, 0] = ![160, 120, 64] := by
  refine ⟨?_, ?_, ?_⟩ <;> (ext i; fin_cases i <;> simp [workshopA, mulVec, dotProduct, Fin.sum_univ_succ])
-- Profit at the four corners: £0, £760, £928, £640.
example : 19 * 0 + 20 * 0 = 0 ∧ 19 * 40 + 20 * 0 = 760 ∧ 19 * 32 + 20 * 16 = 928 ∧
    19 * 0 + 20 * 32 = 640 := by norm_num
-- Prices y = (3, 0, 7): y A = (19, 20, 3, 0, 7) and y b = 928.
example : ![(3 : ℤ), 0, 7] ᵥ* workshopA = ![19, 20, 3, 0, 7] := by
  ext j; fin_cases j <;> simp [workshopA, vecMul, dotProduct, Fin.sum_univ_succ]
example : ![(3 : ℤ), 0, 7] ⬝ᵥ ![160, 120, 64] = 928 := by
  simp [dotProduct, Fin.sum_univ_succ]
-- Five variables, three in each basis: 10 possible bases.
example : Nat.choose 5 3 = 10 := by decide
-- Labour is redundant: 3/4 of timber plus 1/2 of "x2 ≥ 0" gives 3 x1 + x2 ≤ 120.
example (x₁ x₂ : ℝ) (ht : 4 * x₁ + 2 * x₂ ≤ 160) (h2 : 0 ≤ x₂) : 3 * x₁ + x₂ ≤ 120 := by
  linarith
-- A search of every whole-number week finds nothing above £928.
example : ∀ x₁ < 41, ∀ x₂ < 33, 4 * x₁ + 2 * x₂ ≤ 160 → 3 * x₁ + x₂ ≤ 120 →
    x₁ + 2 * x₂ ≤ 64 → 19 * x₁ + 20 * x₂ ≤ 928 := by decide
-- Chairs at £38: both ends of the finish edge earn £1,216.
example : 19 * 0 + 38 * 32 = 1216 ∧ 19 * 32 + 38 * 16 = 1216 := by norm_num

#print axioms best_plans_form_a_face
#print axioms slack_form_same_shape
#print axioms prices_bound_profit
