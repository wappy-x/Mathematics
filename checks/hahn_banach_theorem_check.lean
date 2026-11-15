-- Hahn-Banach: a linear rule kept under a sublinear bound on a subspace of a real vector space extends to the whole space under the same bound, and in a normed space it keeps its norm.
import Mathlib.Analysis.Convex.Cone.Extension
import Mathlib.Analysis.Normed.Module.HahnBanach

/-- Hahn-Banach, sublinear form. Let `X` be a real vector space, `M` a subspace, and `s` a
sublinear bound on `X`: `s (x + y) ≤ s x + s y`, and `s (t • x) = t * s x` for every `t ≥ 0`.
If a linear rule `φ` on `M` satisfies `φ m ≤ s m` for every `m` in `M`, then some linear rule
`Φ` on all of `X` agrees with `φ` on `M` and satisfies `Φ x ≤ s x` for every `x` in `X`. -/
theorem linear_rule_under_sublinear_bound_extends
    {X : Type*} [AddCommGroup X] [Module ℝ X]
    (M : Submodule ℝ X) (φ : M →ₗ[ℝ] ℝ) (s : X → ℝ)
    (hs_add : ∀ x y : X, s (x + y) ≤ s x + s y)
    (hs_smul : ∀ t : ℝ, 0 ≤ t → ∀ x : X, s (t • x) = t * s x)
    (hφ : ∀ m : M, φ m ≤ s m) :
    ∃ Φ : X →ₗ[ℝ] ℝ, (∀ m : M, Φ m = φ m) ∧ ∀ x : X, Φ x ≤ s x := by
  obtain ⟨g, hg, hle⟩ := exists_extension_of_le_sublinear ⟨M, φ⟩ s
    (fun c hc x => hs_smul c hc.le x) hs_add hφ
  exact ⟨g, hg, hle⟩

/-- Hahn-Banach, norm form. In any real normed space `X` (complete or not), a bounded linear
functional `φ` on a subspace `M` extends to a bounded linear functional `Φ` on all of `X`
that agrees with `φ` on `M` and has the same norm: `‖Φ‖ = ‖φ‖`. -/
theorem bounded_functional_extends_keeping_norm
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (M : Submodule ℝ X) (φ : M →L[ℝ] ℝ) :
    ∃ Φ : X →L[ℝ] ℝ, (∀ m : M, Φ m = φ m) ∧ ‖Φ‖ = ‖φ‖ := by
  simpa using exists_extension_norm_eq M φ

/-- Norming functional. In any real normed space `X`, every nonzero `x` has a bounded linear
functional `g` of norm 1 that reads off its size exactly: `g x = ‖x‖`. -/
theorem norming_functional_exists
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (x : X) (hx : x ≠ 0) :
    ∃ g : X →L[ℝ] ℝ, ‖g‖ = 1 ∧ g x = ‖x‖ := by
  simpa using exists_dual_vector ℝ x (norm_ne_zero_iff.mpr hx)

-- The card's three-state market, in exact fractions (0.95 = 19/20).
-- Down-state price from the two bonds, and the flat-plus-up total.
example : ((95 : ℚ) - 89) / (100 - 40) = 1 / 10 := by norm_num
example : (95 : ℚ) / 100 - 1 / 10 = 17 / 20 := by norm_num
-- Floor witness: 8/15 government plus 2/3 corporate costs £110; minus the share it pays
-- (20, 20, -20), so s = 19/20 * 20 = 19 and the floor is 110 - 19 = 91.
example : (8 / 15 : ℚ) * 95 + 2 / 3 * 89 = 110 := by norm_num
example : (8 / 15 : ℚ) * 100 + 2 / 3 * 40 - 60 = 20 ∧ (8 / 15 : ℚ) * 100 + 2 / 3 * 100 - 100 = 20 ∧
    (8 / 15 : ℚ) * 100 + 2 / 3 * 100 - 140 = -20 := by norm_num
example : (110 : ℚ) - 19 / 20 * 20 = 91 := by norm_num
-- Ceiling witness: 2/15 government minus 4/3 corporate costs -£106; plus the share it pays
-- (20, -20, 20), so s = 19 and the ceiling is 19 + 106 = 125.
example : (2 / 15 : ℚ) * 95 - 4 / 3 * 89 = -106 := by norm_num
example : (2 / 15 : ℚ) * 100 - 4 / 3 * 40 + 60 = 20 ∧ (2 / 15 : ℚ) * 100 - 4 / 3 * 100 + 100 = -20 ∧
    (2 / 15 : ℚ) * 100 - 4 / 3 * 100 + 140 = 20 := by norm_num
example : (19 / 20 : ℚ) * 20 + 106 = 125 := by norm_num
-- Band ends from the share price 91 + 40 w_u, with 0 ≤ w_u ≤ 17/20.
example : (91 : ℚ) + 40 * 0 = 91 ∧ (91 : ℚ) + 40 * (17 / 20) = 125 := by norm_num
-- Midpoint rule: state prices 1/10, 17/40, 17/40 price G at 95, B at 89, the share at 108,
-- and sum to 19/20, the bonds' norm.
example : (100 : ℚ) * (1 / 10 + 17 / 40 + 17 / 40) = 95 ∧
    (40 : ℚ) * (1 / 10) + 100 * (17 / 40 + 17 / 40) = 89 ∧
    (60 : ℚ) * (1 / 10) + 100 * (17 / 40) + 140 * (17 / 40) = 108 ∧
    (1 / 10 : ℚ) + 17 / 40 + 17 / 40 = 19 / 20 := by norm_num

#print axioms linear_rule_under_sublinear_bound_extends
#print axioms bounded_functional_extends_keeping_norm
#print axioms norming_functional_exists
