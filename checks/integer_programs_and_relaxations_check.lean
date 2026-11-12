-- Integer programs: the best score over whole points is never above the best score with fractions allowed, prices on the limits certify such a ceiling, and over the convex hull of the whole points the best score is exactly the whole-number best.
import Mathlib.Analysis.Convex.Hull
import Mathlib.Data.Matrix.Mul
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum

open Matrix

variable {m n : Type*} [Fintype m] [Fintype n]

/-- The relaxed region `P = {x : A x ≤ b, x ≥ 0}`: every point that fits, fractions allowed. -/
def relaxedRegion (A : Matrix m n ℝ) (b : m → ℝ) : Set (n → ℝ) :=
  {x | A *ᵥ x ≤ b ∧ 0 ≤ x}

/-- The whole points `S = {x : A x ≤ b, x ≥ 0, x whole}`. -/
def wholePoints (A : Matrix m n ℝ) (b : m → ℝ) : Set (n → ℝ) :=
  {x | x ∈ relaxedRegion A b ∧ ∀ i, ∃ k : ℤ, x i = k}

/-- The LP relaxation is a ceiling: if `z_IP` is the best score `c ⬝ x` over the whole points
of `{x : A x ≤ b, x ≥ 0}`, and `z_LP` is the best score over the same region with fractions
allowed, then `z_LP ≥ z_IP`. -/
theorem relaxation_bounds_integer_optimum (A : Matrix m n ℝ) (b : m → ℝ) (c : n → ℝ)
    (zIP zLP : ℝ)
    (hIP : IsGreatest ((fun x => c ⬝ᵥ x) '' wholePoints A b) zIP)
    (hLP : IsGreatest ((fun x => c ⬝ᵥ x) '' relaxedRegion A b) zLP) :
    zIP ≤ zLP := by
  obtain ⟨⟨x, hx, rfl⟩, -⟩ := hIP
  exact hLP.2 ⟨x, hx.1, rfl⟩

/-- Prices certify a ceiling: if prices `y ≥ 0` on the limits make every unknown cost at least
its score (`Aᵀ y ≥ c`), then every point with `A x ≤ b` and `x ≥ 0` has
`c ⬝ x ≤ y ⬝ (A x) ≤ y ⬝ b`. -/
theorem price_certificate_bounds_score (A : Matrix m n ℝ) (b : m → ℝ) (c : n → ℝ)
    (y : m → ℝ) (x : n → ℝ)
    (hy : 0 ≤ y) (hcover : c ≤ y ᵥ* A) (hAx : A *ᵥ x ≤ b) (hx : 0 ≤ x) :
    c ⬝ᵥ x ≤ y ⬝ᵥ (A *ᵥ x) ∧ y ⬝ᵥ (A *ᵥ x) ≤ y ⬝ᵥ b := by
  refine ⟨?_, ?_⟩
  · rw [dotProduct_mulVec]
    unfold dotProduct
    exact Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_right (hcover i) (hx i)
  · unfold dotProduct
    exact Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_left (hAx i) (hy i)

/-- The convex hull is exact: if `z_IP` is the best score over the whole points `S`, then the
best score over `conv S` is again exactly `z_IP`. -/
theorem convex_hull_relaxation_exact (A : Matrix m n ℝ) (b : m → ℝ) (c : n → ℝ) (zIP : ℝ)
    (hIP : IsGreatest ((fun x => c ⬝ᵥ x) '' wholePoints A b) zIP) :
    IsGreatest ((fun x => c ⬝ᵥ x) '' convexHull ℝ (wholePoints A b)) zIP := by
  obtain ⟨⟨x, hx, rfl⟩, hub⟩ := hIP
  refine ⟨⟨x, subset_convexHull ℝ _ hx, rfl⟩, ?_⟩
  have hlin : IsLinearMap ℝ (fun x : n → ℝ => c ⬝ᵥ x) :=
    ⟨fun u v => dotProduct_add c u v, fun r u => dotProduct_smul r c u⟩
  have hsub : convexHull ℝ (wholePoints A b) ⊆ {z | c ⬝ᵥ z ≤ c ⬝ᵥ x} :=
    convexHull_min (fun z hz => hub ⟨z, hz, rfl⟩) (convex_halfSpace_le hlin _)
  rintro _ ⟨z, hz, rfl⟩
  exact hsub hz

/-! The festival: `h` headliners and `t` smaller acts, fees `60h + 5t ≤ 290` (in £k),
hours `4h + 2t ≤ 24`, tickets `5500h + 1000t`. -/

-- There are 45 whole bookings (every whole booking has h ≤ 4 and t ≤ 12, so 30 is plenty).
example : ((Finset.range 30 ×ˢ Finset.range 30).filter
    (fun p : ℕ × ℕ => 60 * p.1 + 5 * p.2 ≤ 290 ∧ 4 * p.1 + 2 * p.2 ≤ 24)).card = 45 := by
  decide +kernel

-- The best whole booking is (4, 4): it fits, and no whole booking sells more than 26,000.
example : 60 * 4 + 5 * 4 = 260 ∧ 4 * 4 + 2 * 4 = 24 ∧ 5500 * 4 + 1000 * 4 = 26000 := by
  norm_num
example : ∀ h ∈ Finset.range 30, ∀ t ∈ Finset.range 30,
    60 * h + 5 * t ≤ 290 → 4 * h + 2 * t ≤ 24 → 5500 * h + 1000 * t ≤ 26000 := by
  decide

-- The relaxed corner (23/5, 14/5), that is 4.6 headliners and 2.8 smaller acts, uses the
-- whole budget and all the hours, and sells 28,100 tickets.
example : (60 : ℚ) * (23 / 5) + 5 * (14 / 5) = 290 ∧ (4 : ℚ) * (23 / 5) + 2 * (14 / 5) = 24 ∧
    (5500 : ℚ) * (23 / 5) + 1000 * (14 / 5) = 28100 := by
  norm_num

-- Prices y = (70, 325) make both acts break even, and certify the same ceiling, 28,100.
example : 60 * 70 + 4 * 325 = 5500 ∧ 5 * 70 + 2 * 325 = 1000 ∧ 290 * 70 + 24 * 325 = 28100 := by
  norm_num

-- The integrality gap is 2,100 tickets; five headliners cost 300 > 290, so h ≤ 4.
example : 28100 - 26000 = 2100 ∧ 5 * 60 = 300 ∧ 300 > 290 := by
  norm_num

-- Rounding fails: (5, 3) costs 315 > 290, and (4, 2) sells 24,000, 2,000 short.
example : 60 * 5 + 5 * 3 = 315 ∧ 5500 * 4 + 1000 * 2 = 24000 ∧ 26000 - 24000 = 2000 := by
  norm_num

#print axioms relaxation_bounds_integer_optimum
#print axioms price_certificate_bounds_score
#print axioms convex_hull_relaxation_exact
