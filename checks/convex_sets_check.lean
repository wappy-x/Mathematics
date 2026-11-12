-- Convex sets: every polyhedron {x : Ax ≤ b} in any number of entries is convex, a convex set holds every finite mix of its points, and the convex hull is exactly the set of all finite mixes.
import Mathlib.Analysis.Convex.Combination
import Mathlib.Analysis.Convex.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Finset

/-- A set cut out by finitely many straight-line rules (a polyhedron
`{x : a_iᵀ x ≤ b_i for every row i}`, with `m` walls in `n` entries) is convex:
every mix `θ x + (1 - θ) y` with `0 ≤ θ ≤ 1` of two of its points is again in it. -/
theorem polyhedron_is_convex (m n : ℕ) (A : Fin m → Fin n → ℝ) (b : Fin m → ℝ) :
    Convex ℝ {x : Fin n → ℝ | ∀ i, ∑ j, A i j * x j ≤ b i} := by
  intro x hx y hy a c ha hc hac i
  have h1 : ∑ j, A i j * x j ≤ b i := hx i
  have h2 : ∑ j, A i j * y j ≤ b i := hy i
  calc ∑ j, A i j * (a • x + c • y) j
      = a * ∑ j, A i j * x j + c * ∑ j, A i j * y j := by
        simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, mul_add, Finset.sum_add_distrib,
          Finset.mul_sum]
        congr 1 <;> apply Finset.sum_congr rfl <;> intro j _ <;> ring
    _ ≤ a * b i + c * b i := by gcongr
    _ = b i := by rw [← add_mul, hac, one_mul]

/-- A convex set holds every mix of finitely many of its points, not only two-way mixes:
if `s_1, …, s_k` lie in `C`, the weights `θ_i` are not negative and add to one,
then `θ_1 s_1 + … + θ_k s_k` lies in `C`. -/
theorem convex_set_holds_every_mix (n : ℕ) (C : Set (Fin n → ℝ)) (hC : Convex ℝ C)
    (k : ℕ) (s : Fin k → Fin n → ℝ) (θ : Fin k → ℝ)
    (hs : ∀ i, s i ∈ C) (hθ : ∀ i, 0 ≤ θ i) (hsum : ∑ i, θ i = 1) :
    ∑ i, θ i • s i ∈ C := by
  exact hC.sum_mem (fun i _ => hθ i) hsum (fun i _ => hs i)

/-- The smallest convex set holding the points of `S` (Mathlib's `convexHull`) is exactly
the set of every mix of finitely many points of `S`. -/
theorem convex_hull_is_every_mix (n : ℕ) (S : Set (Fin n → ℝ)) :
    convexHull ℝ S =
      {x | ∃ (k : ℕ) (s : Fin k → Fin n → ℝ) (θ : Fin k → ℝ),
        (∀ i, s i ∈ S) ∧ (∀ i, 0 ≤ θ i) ∧ ∑ i, θ i = 1 ∧ x = ∑ i, θ i • s i} := by
  ext x
  constructor
  · intro hx
    rw [mem_convexHull_iff_exists_fintype] at hx
    obtain ⟨ι, _, w, z, hw₀, hw₁, hz, hx⟩ := hx
    let e := Fintype.equivFin ι
    refine ⟨Fintype.card ι, z ∘ e.symm, w ∘ e.symm, fun i => hz _, fun i => hw₀ _, ?_, ?_⟩
    · rw [← hw₁]
      exact Fintype.sum_equiv e.symm _ _ (fun _ => rfl)
    · rw [← hx]
      exact (Fintype.sum_equiv e.symm _ _ (fun _ => rfl)).symm
  · rintro ⟨k, s, θ, hs, hθ, hsum, rfl⟩
    exact mem_convexHull_of_exists_fintype θ s hθ hsum hs rfl

/-! The card's own exact numbers. Shares are (Robusta, Brazil, Ethiopian); prices 6, 8, 14. -/

/-- The card's six walls `A x ≤ b`. -/
def blendWalls : Fin 6 → Fin 3 → ℝ :=
  ![![-1, 0, 0], ![0, -1, 0], ![0, 0, -1], ![1, 1, 1], ![-1, -1, -1], ![6, 8, 14]]

def blendLimits : Fin 6 → ℝ := ![0, 0, 0, 1, -1, 9]

-- House (2/5, 2/5, 1/5) passes all six walls.
example : (![2/5, 2/5, 1/5] : Fin 3 → ℝ) ∈
    {x : Fin 3 → ℝ | ∀ i, ∑ j, blendWalls i j * x j ≤ blendLimits i} := by
  intro i
  fin_cases i <;> simp [blendWalls, blendLimits, Fin.sum_univ_three] <;> norm_num

-- House costs 42/5 a kilo (£8.40).
example : (6 : ℚ) * (2/5) + 8 * (2/5) + 14 * (1/5) = 42/5 := by norm_num

-- The corners (0, 5/6, 1/6) and (5/8, 0, 3/8) cost exactly 9.
example : (6 : ℚ) * 0 + 8 * (5/6) + 14 * (1/6) = 9 := by norm_num
example : (6 : ℚ) * (5/8) + 8 * 0 + 14 * (3/8) = 9 := by norm_num

-- No Ethiopian, cost exactly 9: (-1/2, 3/2, 0) has a negative share, so it is out.
example : (6 : ℚ) * (-1/2) + 8 * (3/2) = 9 ∧ (-1/2 : ℚ) + 3/2 = 1 ∧ (-1/2 : ℚ) < 0 := by norm_num

-- House = 1/9 Dark + 5/9 Bright + 1/3 Breakfast, with weights adding to one.
example : (1/9 : ℚ) + 5/9 + 1/3 = 1 ∧
    (1/9 : ℚ) * (1/2) + 5/9 * (1/2) + 1/3 * (1/5) = 2/5 ∧
    (1/9 : ℚ) * (1/2) + 5/9 * (1/5) + 1/3 * (7/10) = 2/5 ∧
    (1/9 : ℚ) * 0 + 5/9 * (3/10) + 1/3 * (1/10) = 1/5 := by norm_num

-- Area: the £9 line cuts off 25/96, leaving 23/96 of the triangle's 1/2.
example : (1/2 : ℚ) * (5/8) * (5/6) = 25/96 ∧ (1/2 : ℚ) - 25/96 = 23/96 := by norm_num

-- The 30% rule dents the set: (7/10, 3/10, 0) and (7/10, 0, 3/10) obey it,
-- their midpoint (7/10, 3/20, 3/20) has a share that is neither 0 nor at least 3/10.
example : ((7/10 : ℚ) + 7/10) / 2 = 7/10 ∧ ((3/10 : ℚ) + 0) / 2 = 3/20 ∧
    (3/20 : ℚ) ≠ 0 ∧ (3/20 : ℚ) < 3/10 := by norm_num

-- Blends in 24ths: 325 in all, 160 cost at most 9.
example : ((range 25 ×ˢ range 25).filter (fun p : ℕ × ℕ => p.1 + p.2 ≤ 24)).card = 325 := by
  decide +kernel
example : ((range 25 ×ˢ range 25).filter (fun p : ℕ × ℕ =>
    p.1 + p.2 ≤ 24 ∧ 6 * p.1 + 8 * p.2 + 14 * (24 - p.1 - p.2) ≤ 9 * 24)).card = 160 := by
  decide +kernel

-- 160 passing blends give 12,720 pairs; mixes of three blends in sixths number 28.
example : Nat.choose 160 2 = 12720 := by decide +kernel
example : ((range 7 ×ˢ range 7).filter (fun p : ℕ × ℕ => p.1 + p.2 ≤ 6)).card = 28 := by decide +kernel

#print axioms polyhedron_is_convex
#print axioms convex_set_holds_every_mix
#print axioms convex_hull_is_every_mix
