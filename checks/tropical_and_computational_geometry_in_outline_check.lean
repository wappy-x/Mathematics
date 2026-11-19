-- Tropical geometry and computation: a sum in a field with a valuation can vanish only if its two biggest terms tie, the tropical line min(0, X - 2, Y - 1) is exactly three rays from (2, 1), and the triangle of a degree-d curve has (d - 1)(d - 2)/2 interior lattice points.
import Mathlib.RingTheory.Valuation.Basic
import Mathlib.Algebra.Tropical.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic

/-- Helper: in a three-term zero sum, the valuation of one term is at least the smaller
valuation of the other two. -/
theorem helper_val {K Γ₀ : Type*} [Field K] [LinearOrderedAddCommMonoidWithTop Γ₀]
    (v : AddValuation K Γ₀) (a b c : K) (h : a + b + c = 0) :
    min (v b) (v c) ≤ v a := by
  have : a = -(b + c) := by linear_combination h
  rw [this, AddValuation.map_neg]
  exact AddValuation.map_add v b c

#print axioms helper_val

/-- Step 0, "a sum can vanish only if its two biggest terms cancel": in a field with a
valuation `v` (min convention, `v 0 = ⊤`), if three terms add to zero, then the smallest
of their three valuations is reached by at least two of them. -/
theorem min_valuation_attained_twice_of_sum_eq_zero
    {K Γ₀ : Type*} [Field K] [LinearOrderedAddCommMonoidWithTop Γ₀]
    (v : AddValuation K Γ₀) (a b c : K) (h : a + b + c = 0) :
    let m := min (min (v a) (v b)) (v c)
    (v a = m ∧ v b = m) ∨ (v a = m ∧ v c = m) ∨ (v b = m ∧ v c = m) := by
  intro m
  have ha := helper_val v a b c h
  have hb := helper_val v b a c (by linear_combination h)
  have hc := helper_val v c a b (by linear_combination h)
  simp only [m]
  rcases le_total (v a) (v b) with h1 | h1 <;> rcases le_total (v a) (v c) with h2 | h2 <;>
    rcases le_total (v b) (v c) with h3 | h3 <;>
    simp_all [le_antisymm_iff]

/-- The tropical line of `1 + t^(-2) x + t^(-1) y`: the points `(X, Y)` of the plane where the
minimum of `0`, `X - 2` and `Y - 1` is reached by at least two of the three terms are exactly
the three rays from `(2, 1)` in the directions `(1, 0)`, `(0, 1)` and `(-1, -1)`. -/
theorem tropical_line_eq_three_rays :
    {p : ℝ × ℝ | let m := min (min 0 (p.1 - 2)) (p.2 - 1)
        (0 = m ∧ p.1 - 2 = m) ∨ (0 = m ∧ p.2 - 1 = m) ∨ (p.1 - 2 = m ∧ p.2 - 1 = m)} =
      {p | ∃ s : ℝ, 0 ≤ s ∧ p = (2 + s, 1)} ∪ {p | ∃ s : ℝ, 0 ≤ s ∧ p = (2, 1 + s)} ∪
        {p | ∃ s : ℝ, 0 ≤ s ∧ p = (2 - s, 1 - s)} := by
  ext ⟨x, y⟩
  simp only [Set.mem_union, Set.mem_ofPred_eq, Prod.mk.injEq]
  have hm1 : min (min 0 (x - 2)) (y - 1) ≤ 0 := (min_le_left _ _).trans (min_le_left _ _)
  have hm2 : min (min 0 (x - 2)) (y - 1) ≤ x - 2 := (min_le_left _ _).trans (min_le_right _ _)
  have hm3 : min (min 0 (x - 2)) (y - 1) ≤ y - 1 := min_le_right _ _
  constructor
  · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩)
    · exact Or.inl (Or.inr ⟨y - 1, by linarith, by linarith, by ring⟩)
    · exact Or.inl (Or.inl ⟨x - 2, by linarith, by ring, by linarith⟩)
    · exact Or.inr ⟨2 - x, by linarith, by ring, by linarith⟩
  · rintro ((⟨s, hs, rfl, rfl⟩ | ⟨s, hs, rfl, rfl⟩) | ⟨s, hs, rfl, rfl⟩)
    · have hm : min (min 0 (2 + s - 2)) (1 - 1) = (0 : ℝ) :=
        le_antisymm (hm3.trans (by norm_num)) (le_min (le_min le_rfl (by linarith)) (by norm_num))
      exact Or.inr (Or.inl ⟨hm.symm, by rw [hm]; ring⟩)
    · have hm : min (min 0 (2 - 2)) (1 + s - 1) = (0 : ℝ) :=
        le_antisymm (hm1) (le_min (le_min le_rfl (by norm_num)) (by linarith))
      exact Or.inl ⟨hm.symm, by rw [hm]; ring⟩
    · have hm : min (min 0 (2 - s - 2)) (1 - s - 1) = (-s : ℝ) :=
        le_antisymm (hm3.trans (by linarith)) (le_min (le_min (by linarith) (by linarith)) (by linarith))
      exact Or.inr (Or.inr ⟨by rw [hm]; ring, by rw [hm]; ring⟩)

/-- Step 4's count: the Newton triangle of a degree-`d` curve, with corners `(0, 0)`, `(d, 0)`
and `(0, d)`, has `(d - 1)(d - 2)/2` interior lattice points, the genus of a smooth plane curve
of degree `d`. -/
theorem newton_triangle_interior_lattice_points (d : ℕ) :
    (((Finset.Ioo 0 d) ×ˢ (Finset.Ioo 0 d)).filter (fun p : ℕ × ℕ => p.1 + p.2 < d)).card =
      (d - 1) * (d - 2) / 2 := by
  rw [Finset.card_filter, Finset.sum_product]
  have hin : ∀ i ∈ Finset.Ioo 0 d,
      (∑ j ∈ Finset.Ioo 0 d, if i + j < d then 1 else 0) = d - 1 - i := by
    intro i hi
    rw [← Finset.card_filter]
    have : (Finset.Ioo 0 d).filter (fun j => i + j < d) = Finset.Ioo 0 (d - i) := by
      ext j; simp only [Finset.mem_filter, Finset.mem_Ioo]; omega
    rw [this, Nat.card_Ioo]; omega
  rw [Finset.sum_congr rfl hin]
  have hI : Finset.Ioo 0 d = (Finset.range (d - 1)).map (addLeftEmbedding 1) := by
    ext i
    simp only [Finset.mem_Ioo, Finset.mem_map, Finset.mem_range, addLeftEmbedding_apply]
    constructor
    · intro hi; exact ⟨i - 1, by omega, by omega⟩
    · rintro ⟨k, hk, rfl⟩; omega
  rw [hI, Finset.sum_map]
  have : ∀ k ∈ Finset.range (d - 1), d - 1 - (addLeftEmbedding 1 k) = d - 1 - 1 - k := by
    intro k _; simp only [addLeftEmbedding_apply]; omega
  rw [Finset.sum_congr rfl this, Finset.sum_range_reflect (fun k => k) (d - 1), Finset.sum_range_id, Nat.sub_sub]

-- Min-plus arithmetic: 3 ⊕ 5 = 3 and 3 ⊙ 5 = 8.
example : MinTropical.trop (3 : ℤ) + MinTropical.trop 5 = MinTropical.trop 3 := by decide
example : MinTropical.trop (3 : ℤ) * MinTropical.trop 5 = MinTropical.trop 8 := by decide

-- The shopper at prices (1, 3): the costs are 0, -1 and 2, so A (cost -1) wins alone.
example : min (min (0 : ℤ) (1 - 2)) (3 - 1) = -1 ∧ (1 - 2 : ℤ) < 0 ∧ (1 - 2 : ℤ) < 3 - 1 := by
  norm_num

-- Prices (3, 3): the costs are 0, 1 and 2, so "nothing" wins alone and (3, 3) is off the line.
example : (0 : ℤ) < 3 - 2 ∧ (0 : ℤ) < 3 - 1 := by norm_num

-- Prices (2, 1): a three-way tie, the vertex.
example : (0 : ℤ) = 2 - 2 ∧ (2 - 2 : ℤ) = 1 - 1 := by norm_num

-- Balancing: the three ray directions add to (0, 0).
example : ((1 : ℤ), (0 : ℤ)) + (0, 1) + (-1, -1) = (0, 0) := by decide

-- Newton triangle (0, 0), (1, 0), (0, 1): each edge turned a quarter turn left gives the
-- inward normals (0, 1), (-1, -1), (1, 0), the three rays.
example : [((0 : ℤ) - 0, (1 : ℤ) - 0), (0 - 1, 0 - 1), (1 - 0, 0 - 0)] =
    [(0, 1), (-1, -1), (1, 0)] := by decide

-- Interior lattice points: degree 3 has 1, degree 4 has 3, degree 5 has 6.
example : (((Finset.Ioo 0 3) ×ˢ (Finset.Ioo 0 3)).filter
    (fun p : ℕ × ℕ => p.1 + p.2 < 3)).card = 1 := by decide
example : (((Finset.Ioo 0 4) ×ˢ (Finset.Ioo 0 4)).filter
    (fun p : ℕ × ℕ => p.1 + p.2 < 4)).card = 3 := by decide
example : (((Finset.Ioo 0 5) ×ˢ (Finset.Ioo 0 5)).filter
    (fun p : ℕ × ℕ => p.1 + p.2 < 5)).card = 6 := by decide

-- Growth shapes: Bezout's 2^n and the doubly exponential 2^(2^n) at n = 5; 2^10 and 2^20.
example : (2 : ℕ) ^ 5 = 32 ∧ (2 : ℕ) ^ 2 ^ 5 = 4294967296 := by norm_num
example : (2 : ℕ) ^ 10 = 1024 ∧ (2 : ℕ) ^ 20 = 1048576 := by norm_num

#print axioms min_valuation_attained_twice_of_sum_eq_zero
#print axioms tropical_line_eq_three_rays
#print axioms newton_triangle_interior_lattice_points
