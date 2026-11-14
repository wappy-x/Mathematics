-- Support vector machines: when every order scores at least 1 on its own side, each order lies at least 1/|w| from the boundary and the empty strip is exactly 2/|w| wide, the best soft-margin weights are a weighted sum of the training orders, and the squared and radial kernels are dot products of hidden features; the card's six-order numbers are checked.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Analysis.InnerProductSpace.Projection.Basic
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Topology.Algebra.InfiniteSum.Real

open Metric RealInnerProductSpace

namespace KernelsAndSupportVectorMachines

/-- Distance from a point to a hyperplane `w · p + b = c`. -/
lemma infDist_hyperplane {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (w : E) (hw : w ≠ 0) (b c : ℝ) (x : E) :
    infDist x {p | ⟪w, p⟫ + b = c} = |⟪w, x⟫ + b - c| / ‖w‖ := by
  have hn : 0 < ‖w‖ := norm_pos_iff.mpr hw
  have hn2 : ‖w‖ ^ 2 ≠ 0 := by positivity
  set t := (⟪w, x⟫ + b - c) / ‖w‖ ^ 2 with ht
  have hmem : x - t • w ∈ {p | ⟪w, p⟫ + b = c} := by
    simp only [Set.mem_ofPred_eq, inner_sub_right, real_inner_smul_right,
      real_inner_self_eq_norm_sq, ht]
    field_simp
    ring
  apply le_antisymm
  · calc infDist x _ ≤ dist x (x - t • w) := infDist_le_dist_of_mem hmem
      _ = |⟪w, x⟫ + b - c| / ‖w‖ := by
        rw [dist_eq_norm, sub_sub_cancel, norm_smul, Real.norm_eq_abs, ht, abs_div,
          abs_of_pos (by positivity : (0 : ℝ) < ‖w‖ ^ 2)]
        field_simp
  · rw [le_infDist ⟨_, hmem⟩]
    intro p hp
    simp only [Set.mem_ofPred_eq] at hp
    rw [div_le_iff₀ hn, dist_eq_norm]
    have h1 : ⟪w, x⟫ + b - c = ⟪w, x - p⟫ := by rw [inner_sub_right]; linarith
    rw [h1, mul_comm]
    exact abs_real_inner_le_norm _ _

/-- A product of sums over `Fin n` multi-indices. -/
lemma sum_prod_multiIndex {d : ℕ} (f : Fin d → ℝ) (n : ℕ) :
    ∑ i : Fin n → Fin d, ∏ j, f (i j) = (∑ k, f k) ^ n := by
  rw [Finset.sum_pow', Fintype.piFinset_univ]

/-- Index set for the exponential feature map: a degree `n` and a multi-index. -/
abbrev Idx (d : ℕ) : Type := Σ n : ℕ, (Fin n → Fin d)

/-- Features whose dot product is `exp ⟪x, y⟫`. -/
noncomputable def feat {d : ℕ} (x : EuclideanSpace ℝ (Fin d)) : Idx d → ℝ :=
  fun p => Real.sqrt (1 / (p.1.factorial : ℝ)) * ∏ j, x (p.2 j)

lemma feat_mul {d : ℕ} (x y : EuclideanSpace ℝ (Fin d)) (p : Idx d) :
    feat x p * feat y p = 1 / (p.1.factorial : ℝ) * ∏ j, (x (p.2 j) * y (p.2 j)) := by
  have h : Real.sqrt (1 / (p.1.factorial : ℝ)) * Real.sqrt (1 / (p.1.factorial : ℝ)) =
      1 / (p.1.factorial : ℝ) := Real.mul_self_sqrt (by positivity)
  simp only [feat, Finset.prod_mul_distrib]
  linear_combination (∏ j, x (p.2 j)) * (∏ j, y (p.2 j)) * h

lemma summable_feat {d : ℕ} (x y : EuclideanSpace ℝ (Fin d)) :
    Summable (fun p : Idx d => feat x p * feat y p) := by
  apply Summable.of_norm
  rw [summable_sigma_of_nonneg (fun _ => norm_nonneg _)]
  refine ⟨fun n => Summable.of_finite, ?_⟩
  convert Real.summable_pow_div_factorial (∑ k, |x k| * |y k|) using 1
  ext n
  simp only [tsum_fintype, feat_mul, norm_mul, norm_prod, Real.norm_eq_abs]
  rw [← Finset.mul_sum, sum_prod_multiIndex (fun k => |x k| * |y k|)]
  rw [abs_of_pos (by positivity : (0 : ℝ) < 1 / (n.factorial : ℝ))]
  ring

lemma exists_exp_inner_feature (d : ℕ) :
    ∃ ψ : EuclideanSpace ℝ (Fin d) → lp (fun _ : Idx d => ℝ) 2,
      ∀ x y, ⟪ψ x, ψ y⟫ = Real.exp ⟪x, y⟫ := by
  have hmem : ∀ x : EuclideanSpace ℝ (Fin d), Memℓp (feat x) 2 := by
    intro x
    apply memℓp_gen
    convert summable_feat x x using 1
    ext p
    rw [ENNReal.toReal_ofNat, Real.rpow_two, Real.norm_eq_abs, sq_abs, sq]
  refine ⟨fun x => ⟨feat x, hmem x⟩, fun x y => ?_⟩
  rw [lp.inner_eq_tsum]
  simp only [Real.inner_apply]
  have hs := summable_feat y x
  rw [(summable_feat x y).tsum_sigma' (fun _ => Summable.of_finite),
    Real.exp_eq_exp_ℝ, NormedSpace.exp_eq_tsum_div]
  refine tsum_congr fun n => ?_
  simp only [tsum_fintype, feat_mul]
  rw [← Finset.mul_sum, sum_prod_multiIndex (fun k => x k * y k)]
  have hxy : ⟪x, y⟫ = ∑ k, x k * y k := by simp [PiLp.inner_apply, mul_comm]
  rw [hxy]
  ring


/-- **The gap is 2 over the length of the weights** (Step 1). Take weights `w ≠ 0` and a bias `b`
in any space with a dot product, and training orders `x i` labelled `y i = +1` (fraud) or `−1`
(honest). Scale so that every order scores at least 1 on its own side:
`y i (w · x i + b) ≥ 1`. Then every order lies at least `1/|w|` from the boundary
`w · x + b = 0`, the orders that score exactly ±1 (the support vectors) lie exactly `1/|w|` from
it, and the strip between the edges `w · x + b = +1` and `w · x + b = −1` is `2/|w|` wide: every
point of one edge is exactly `2/|w|` from the other edge. -/
theorem svm_margin_eq_two_div_norm {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    {m : ℕ} (w : E) (hw : w ≠ 0) (b : ℝ) (x : Fin m → E) (y : Fin m → ℝ)
    (hy : ∀ i, y i = 1 ∨ y i = -1) (hfit : ∀ i, 1 ≤ y i * (⟪w, x i⟫ + b)) :
    (∀ i, 1 / ‖w‖ ≤ infDist (x i) {p | ⟪w, p⟫ + b = 0}) ∧
    (∀ i, y i * (⟪w, x i⟫ + b) = 1 → infDist (x i) {p | ⟪w, p⟫ + b = 0} = 1 / ‖w‖) ∧
    (∀ p : E, ⟪w, p⟫ + b = 1 → infDist p {q | ⟪w, q⟫ + b = -1} = 2 / ‖w‖) ∧
    (∀ p : E, ⟪w, p⟫ + b = -1 → infDist p {q | ⟪w, q⟫ + b = 1} = 2 / ‖w‖) := by
  have hn : 0 < ‖w‖ := norm_pos_iff.mpr hw
  refine ⟨fun i => ?_, fun i hi => ?_, fun p hp => ?_, fun p hp => ?_⟩
  · rw [infDist_hyperplane w hw b 0, sub_zero]
    have h1 : 1 ≤ |⟪w, x i⟫ + b| := by
      have := hfit i
      rcases hy i with h | h <;> rw [h] at this
      · exact le_abs.mpr (Or.inl (by linarith))
      · exact le_abs.mpr (Or.inr (by linarith))
    gcongr
  · rw [infDist_hyperplane w hw b 0, sub_zero]
    rcases hy i with h | h <;> rw [h] at hi
    · rw [show ⟪w, x i⟫ + b = 1 by linarith]; norm_num
    · rw [show ⟪w, x i⟫ + b = -1 by linarith]; norm_num
  · rw [infDist_hyperplane w hw b (-1), hp]; norm_num
  · rw [infDist_hyperplane w hw b 1, hp]; norm_num

/-- **The best weights are a weighted sum of the training orders** (Step 3). Take training
orders `x i` with labels `y i` and a price `C` per unit of slack. Suppose the weights `w`, bias
`b` and slacks `ξ` meet every limit `y i (w · x i + b) ≥ 1 − ξ i`, `ξ i ≥ 0`, and no other
choice meeting the limits has a lower cost `½|w|² + C Σ ξ i`. Then `w` is a weighted sum of the
orders: `w = Σ c i x i` for some numbers `c i`. -/
theorem svm_best_weights_are_weighted_sum {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℝ E] {m : ℕ} (x : Fin m → E) (y : Fin m → ℝ) (C : ℝ)
    (w : E) (b : ℝ) (ξ : Fin m → ℝ)
    (hfeas : ∀ i, 1 - ξ i ≤ y i * (⟪w, x i⟫ + b) ∧ 0 ≤ ξ i)
    (hbest : ∀ (w' : E) (b' : ℝ) (ξ' : Fin m → ℝ),
      (∀ i, 1 - ξ' i ≤ y i * (⟪w', x i⟫ + b') ∧ 0 ≤ ξ' i) →
      ‖w‖ ^ 2 / 2 + C * ∑ i, ξ i ≤ ‖w'‖ ^ 2 / 2 + C * ∑ i, ξ' i) :
    ∃ c : Fin m → ℝ, w = ∑ i, c i • x i := by
  set K : Submodule ℝ E := Submodule.span ℝ (Set.range x) with hK
  have : FiniteDimensional ℝ K := FiniteDimensional.span_of_finite ℝ (Set.finite_range x)
  set u := K.starProjection w with hu
  have hv : w - u ∈ Kᗮ := K.sub_starProjection_mem_orthogonal w
  have huK : u ∈ K := K.starProjection_apply_mem w
  have hinner : ∀ i, ⟪w, x i⟫ = ⟪u, x i⟫ := by
    intro i
    have h0 : ⟪x i, w - u⟫ = 0 :=
      (Submodule.mem_orthogonal K (w - u)).mp hv (x i) (Submodule.subset_span ⟨i, rfl⟩)
    rw [inner_sub_right, real_inner_comm w (x i), real_inner_comm u (x i)] at h0
    linarith
  have hfeas' : ∀ i, 1 - ξ i ≤ y i * (⟪u, x i⟫ + b) ∧ 0 ≤ ξ i := fun i => by
    rw [← hinner i]; exact hfeas i
  have hle := hbest u b ξ hfeas'
  have hperp : ⟪u, w - u⟫ = 0 := (Submodule.mem_orthogonal K (w - u)).mp hv u huK
  have hpy : ‖w‖ ^ 2 = ‖u‖ ^ 2 + ‖w - u‖ ^ 2 := by
    have := norm_add_sq_real u (w - u)
    rw [add_sub_cancel, hperp] at this
    linarith
  have hz : ‖w - u‖ ^ 2 ≤ 0 := by linarith
  have hwu : w = u := by
    have : ‖w - u‖ = 0 := by nlinarith [norm_nonneg (w - u)]
    exact sub_eq_zero.mp (norm_eq_zero.mp this)
  have hwK : w ∈ K := hwu ▸ huK
  obtain ⟨c, hc⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp hwK
  exact ⟨c, hc.symm⟩

/-- **A kernel is a dot product of features nobody has to compute** (Step 4). For orders in the
plane, the lifted features `φ(x) = (x₁², √2 x₁x₂, x₂²)` have `φ(x) · φ(x') = (x · x')²`. And
for orders of any `d` numbers and any reach setting `γ ≥ 0`, the radial kernel
`K(x, x') = e^{−γ |x − x'|²}` is a dot product of hidden features: there is a space with a dot
product and a feature map `φ` into it with `K(x, x') = φ(x) · φ(x')` for every pair of orders. -/
theorem kernels_are_feature_dot_products :
    (∀ x₁ x₂ x₁' x₂' : ℝ,
      x₁ ^ 2 * x₁' ^ 2 + (√2 * x₁ * x₂) * (√2 * x₁' * x₂') + x₂ ^ 2 * x₂' ^ 2 =
        (x₁ * x₁' + x₂ * x₂') ^ 2) ∧
    (∀ (d : ℕ) (γ : ℝ), 0 ≤ γ →
      ∃ (H : Type) (_ : NormedAddCommGroup H) (_ : InnerProductSpace ℝ H)
        (φ : EuclideanSpace ℝ (Fin d) → H),
        ∀ x x' : EuclideanSpace ℝ (Fin d), Real.exp (-γ * ‖x - x'‖ ^ 2) = ⟪φ x, φ x'⟫) := by
  refine ⟨fun x₁ x₂ x₁' x₂' => ?_, fun d γ hγ => ?_⟩
  · have h2 : (√2) ^ 2 = 2 := Real.sq_sqrt (by norm_num)
    linear_combination (x₁ * x₂ * x₁' * x₂') * h2
  · obtain ⟨ψ, hψ⟩ := exists_exp_inner_feature d
    refine ⟨lp (fun _ : Idx d => ℝ) 2, inferInstance, inferInstance,
      fun x => Real.exp (-γ * ‖x‖ ^ 2) • ψ (Real.sqrt (2 * γ) • x), fun x x' => ?_⟩
    rw [real_inner_smul_left, real_inner_smul_right, hψ, real_inner_smul_left,
      real_inner_smul_right, ← Real.exp_add, ← Real.exp_add, norm_sub_sq_real]
    have hs : Real.sqrt (2 * γ) * Real.sqrt (2 * γ) = 2 * γ := Real.mul_self_sqrt (by linarith)
    congr 1
    linear_combination (-⟪x, x'⟫) * hs

/-! The card's six orders, by hand. Honest at (0, 0), (1, 0), (0, 1); fraud at (2, 2), (3, 3),
(4, 1). The SVM's score is `s = ⅔ (x₁ + x₂) − 5/3`, so `w = (⅔, ⅔)` and `b = −5/3`. -/

/-- The hard-margin score of an order `(x₁, x₂)`. -/
def s6 (p : ℚ × ℚ) : ℚ := 2 / 3 * (p.1 + p.2) - 5 / 3

-- Support vectors score exactly −1 (honest) and +1 (fraud).
example : s6 (1, 0) = -1 ∧ s6 (0, 1) = -1 ∧ s6 (2, 2) = 1 := by norm_num [s6]
-- The other three orders sit beyond their edges: (0, 0) honest, (3, 3) and (4, 1) fraud.
example : s6 (0, 0) ≤ -1 ∧ 1 ≤ s6 (3, 3) ∧ 1 ≤ s6 (4, 1) := by norm_num [s6]
-- Edges at x₁ + x₂ = 1 and 4, boundary halfway at 5/2.
example : (1 + 4 : ℚ) / 2 = 5 / 2 ∧ s6 (5 / 2, 0) = 0 := by norm_num [s6]
-- |w|² = 8/9, the margin squared (2/|w|)² = 9/2 = (3/√2)², and the gap to each side
-- squared (1/|w|)² = 9/8 (1.0607²).
example : (2 / 3 : ℚ) ^ 2 + (2 / 3) ^ 2 = 8 / 9 ∧ (4 : ℚ) / (8 / 9) = 9 / 2 ∧
    (9 : ℚ) / 2 = 3 ^ 2 / 2 ∧ (1 : ℚ) / (8 / 9) = 9 / 8 := by norm_num
-- The weights on the orders: α = 2/9, 2/9, 4/9 for (1, 0), (0, 1), (2, 2). They rebuild w,
-- their signed sum is 0, and their total is |w|² = 8/9.
example : (4 / 9 : ℚ) * 2 - 2 / 9 * 1 - 2 / 9 * 0 = 2 / 3 ∧
    (4 / 9 : ℚ) * 2 - 2 / 9 * 0 - 2 / 9 * 1 = 2 / 3 ∧
    (4 / 9 : ℚ) - 2 / 9 - 2 / 9 = 0 ∧ (2 / 9 : ℚ) + 2 / 9 + 4 / 9 = 8 / 9 := by norm_num
-- The perceptron's line x₁ + x₂ = 3 passes (2, 2) at distance |4 − 3|/√2: squared 1/2 (0.7071²).
example : ((2 + 2 - 3 : ℚ)) ^ 2 / 2 = 1 / 2 := by norm_num
-- The seventh order, honest at (3, 2): along (1, 2) the frauds (2, 2) and (4, 1) sit at 6 and it
-- sits at 7, so the clearance is (6 − 7)/√5 < 0.
example : (2 * 1 + 2 * 2 : ℤ) = 6 ∧ (4 * 1 + 1 * 2 : ℤ) = 6 ∧ (3 * 1 + 2 * 2 : ℤ) = 7 := by decide

/-- The soft-margin score with `C = 1`: `w = (½, ½)`, `b = −3/2`, boundary `x₁ + x₂ = 3`. -/
def s7 (p : ℚ × ℚ) : ℚ := 1 / 2 * (p.1 + p.2) - 3 / 2

-- Slack `max(0, 1 − y s)`: 1/2 for the fraud at (2, 2), 2 for the honest order at (3, 2), and
-- 0 for the other five; the strip is 2/|w| wide, squared 8 (2.8284²).
example : max 0 (1 - s7 (2, 2)) = 1 / 2 ∧ max 0 (1 + s7 (3, 2)) = 2 ∧
    max 0 (1 + s7 (0, 0)) = 0 ∧ max 0 (1 + s7 (1, 0)) = 0 ∧ max 0 (1 + s7 (0, 1)) = 0 ∧
    max 0 (1 - s7 (3, 3)) = 0 ∧ max 0 (1 - s7 (4, 1)) = 0 ∧
    (4 : ℚ) / ((1 / 2) ^ 2 + (1 / 2) ^ 2) = 8 := by norm_num [s7]
-- One radial kernel value: |(1, 0) − (2, 2)|² = 5, and γ = 1/2 gives the exponent 5/2.
example : (1 - 2 : ℤ) ^ 2 + (0 - 2) ^ 2 = 5 ∧ (1 / 2 : ℚ) * 5 = 5 / 2 := by norm_num
-- The full shop's kernel table: 20,000 × 20,000 = 400 million entries, 3.2 GB at 8 bytes each.
example : 20000 * 20000 = 400000000 ∧ 20000 * 20000 * 8 = 3200000000 := by norm_num

#print axioms infDist_hyperplane
#print axioms sum_prod_multiIndex
#print axioms feat
#print axioms feat_mul
#print axioms summable_feat
#print axioms exists_exp_inner_feature
#print axioms svm_margin_eq_two_div_norm
#print axioms svm_best_weights_are_weighted_sum
#print axioms kernels_are_feature_dot_products

end KernelsAndSupportVectorMachines
