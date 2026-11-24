-- The speed limit: some smooth convex cost keeps every gradient-span method at least 3 L R^2 / (32 (k+1)^2) above its lowest value after k gradient calls, because on the chain quadratic each gradient uncovers only one more coordinate.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Order.Filter.Extr
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.FDeriv.Mul

open Matrix

/-- The chain's tridiagonal matrix `A` on `n` coordinates: 2 on the main diagonal,
−1 on the two diagonals next to it, 0 elsewhere. -/
def chainMatrix (n : ℕ) : Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j =>
    if i = j then 2 else if (i : ℕ) + 1 = j ∨ (j : ℕ) + 1 = i then -1 else 0

/-- The list `e₁ = (1, 0, …, 0)` on `n` coordinates. -/
def firstUnit (n : ℕ) : Fin n → ℝ := fun i => if (i : ℕ) = 0 then 1 else 0

/-- The chain quadratic `f(x) = (L/8) xᵀ A x − (L/4) x₁`. Its quadratic part `xᵀ A x`
equals `x₁² + Σ (xᵢ − xᵢ₊₁)² + xₙ²`, the card's sum of squared jumps. -/
noncomputable def chainCost (n : ℕ) (L : ℝ) (x : Fin n → ℝ) : ℝ :=
  L / 8 * (x ⬝ᵥ (chainMatrix n *ᵥ x)) - L / 4 * (firstUnit n ⬝ᵥ x)

/-- A list on `n` places, read as a sequence on all of `ℕ` that is zero from place `n` on. -/
noncomputable def chainExt {n : ℕ} (x : Fin n → ℝ) (i : ℕ) : ℝ :=
  if h : i < n then x ⟨i, h⟩ else 0

/-- The chain operator on sequences, cut to the first `m` places. -/
noncomputable def chainOp (m : ℕ) (U : ℕ → ℝ) (i : ℕ) : ℝ :=
  if i < m then 2 * U i - (if i = 0 then 0 else U (i - 1)) - (if i + 1 < m then U (i + 1) else 0)
  else 0

/-- The straight line on `s` places: `1 − (i+1)/(s+1)` before place `s`, zero after. -/
noncomputable def chainLine (s : ℕ) (i : ℕ) : ℝ :=
  if i < s then 1 - ((i : ℝ) + 1) / ((s : ℝ) + 1) else 0

lemma chainExt_coe {n : ℕ} (x : Fin n → ℝ) (i : Fin n) : chainExt x i = x i := by
  simp [chainExt]

lemma dotProduct_eq_range {n : ℕ} (x y : Fin n → ℝ) :
    x ⬝ᵥ y = ∑ i ∈ Finset.range n, chainExt x i * chainExt y i := by
  rw [dotProduct, ← Fin.sum_univ_eq_sum_range (fun i => chainExt x i * chainExt y i)]
  simp [chainExt_coe]

lemma chain_mulVec_eq {n : ℕ} (x : Fin n → ℝ) (i : Fin n) :
    (chainMatrix n *ᵥ x) i = chainOp n (chainExt x) i := by
  have hi := i.isLt
  have key : (chainMatrix n *ᵥ x) i = ∑ l ∈ Finset.range n,
      ((if l = (i : ℕ) then 2 * chainExt x l else 0) - (if l + 1 = (i : ℕ) then chainExt x l else 0)
        - (if l = (i : ℕ) + 1 then chainExt x l else 0)) := by
    rw [mulVec, dotProduct,
      ← Fin.sum_univ_eq_sum_range (fun l => ((if l = (i : ℕ) then 2 * chainExt x l else 0)
        - (if l + 1 = (i : ℕ) then chainExt x l else 0)
        - (if l = (i : ℕ) + 1 then chainExt x l else 0)))]
    apply Finset.sum_congr rfl
    intro l _
    rw [chainExt_coe]
    simp only [chainMatrix, of_apply, Fin.ext_iff]
    by_cases h1 : (i : ℕ) = l
    · simp [h1]
    · by_cases h2 : (i : ℕ) + 1 = l
      · simp [h1, h2, show ¬ (l : ℕ) = i by omega, show ¬ (l : ℕ) + 1 = i by omega]
      · by_cases h3 : (l : ℕ) + 1 = i
        · simp [h1, h2, h3, show ¬ (l : ℕ) = i by omega, show ¬ (l : ℕ) = i + 1 by omega]
        · simp [h1, h2, h3, show ¬ (l : ℕ) = i by omega, show ¬ (l : ℕ) = i + 1 by omega]
  rw [key, Finset.sum_sub_distrib, Finset.sum_sub_distrib, Finset.sum_ite_eq', Finset.sum_ite_eq']
  simp only [chainOp, if_pos hi, Finset.mem_range]
  congr 2
  rcases Nat.eq_zero_or_pos (i : ℕ) with h0 | h0
  · simp [h0]
  · obtain ⟨j, hj⟩ : ∃ j, (i : ℕ) = j + 1 := ⟨(i : ℕ) - 1, by omega⟩
    rw [hj]
    simp only [Nat.add_right_cancel_iff, Finset.sum_ite_eq', Finset.mem_range]
    simp [show j < n by omega]

lemma chainOp_sum (m : ℕ) (U V : ℕ → ℝ) :
    ∑ i ∈ Finset.range m, V i * chainOp m U i =
      2 * ∑ i ∈ Finset.range m, V i * U i
        - ∑ i ∈ Finset.range (m - 1), (V (i + 1) * U i + V i * U (i + 1)) := by
  rcases m with _ | p
  · simp
  · simp only [Nat.add_sub_cancel]
    have h1 : ∑ i ∈ Finset.range (p + 1), V i * chainOp (p + 1) U i =
        ∑ i ∈ Finset.range (p + 1), (2 * (V i * U i))
          - ∑ i ∈ Finset.range (p + 1), V i * (if i = 0 then 0 else U (i - 1))
          - ∑ i ∈ Finset.range (p + 1), V i * (if i + 1 < p + 1 then U (i + 1) else 0) := by
      rw [← Finset.sum_sub_distrib, ← Finset.sum_sub_distrib]
      apply Finset.sum_congr rfl
      intro i hi
      rw [Finset.mem_range] at hi
      simp only [chainOp, if_pos hi]; ring
    have h2 : ∑ i ∈ Finset.range (p + 1), V i * (if i = 0 then 0 else U (i - 1)) =
        ∑ i ∈ Finset.range p, V (i + 1) * U i := by
      rw [Finset.sum_range_succ']; simp
    have h3 : ∑ i ∈ Finset.range (p + 1), V i * (if i + 1 < p + 1 then U (i + 1) else 0) =
        ∑ i ∈ Finset.range p, V i * U (i + 1) := by
      rw [Finset.sum_range_succ]
      simp only [lt_irrefl, if_false, mul_zero, add_zero]
      apply Finset.sum_congr rfl
      intro i hi
      rw [Finset.mem_range] at hi
      rw [if_pos (by omega)]
    rw [h1, h2, h3, ← Finset.mul_sum, Finset.sum_add_distrib]; ring

lemma chainOp_quad_nonneg (m : ℕ) (U : ℕ → ℝ) :
    0 ≤ ∑ i ∈ Finset.range m, U i * chainOp m U i := by
  rw [chainOp_sum]
  rcases m with _ | p
  · simp
  · simp only [Nat.add_sub_cancel]
    have hid : 2 * ∑ i ∈ Finset.range (p + 1), U i * U i
        - ∑ i ∈ Finset.range p, (U (i + 1) * U i + U i * U (i + 1)) =
        U 0 ^ 2 + U p ^ 2 + ∑ i ∈ Finset.range p, (U i - U (i + 1)) ^ 2 := by
      have e1 := Finset.sum_range_succ (fun i => U i * U i) p
      have e2 := Finset.sum_range_succ' (fun i => U i * U i) p
      have e3 : ∑ i ∈ Finset.range p, (U i - U (i + 1)) ^ 2 =
          ∑ i ∈ Finset.range p, U i * U i + ∑ i ∈ Finset.range p, U (i + 1) * U (i + 1)
            - ∑ i ∈ Finset.range p, (U (i + 1) * U i + U i * U (i + 1)) := by
        rw [← Finset.sum_add_distrib, ← Finset.sum_sub_distrib]
        apply Finset.sum_congr rfl; intro i _; ring
      rw [e3]; linarith
    rw [hid]
    have := Finset.sum_nonneg (fun i (_ : i ∈ Finset.range p) => sq_nonneg (U i - U (i + 1)))
    positivity

lemma chainOp_line (m s : ℕ) (hs : s ≤ m) (i : ℕ) (hi : i < s) :
    chainOp m (chainLine s) i = if i = 0 then 1 else 0 := by
  have hs1 : (0 : ℝ) < (s : ℝ) + 1 := by positivity
  have hnext : (if i + 1 < m then chainLine s (i + 1) else 0) =
      1 - ((i : ℝ) + 2) / ((s : ℝ) + 1) := by
    by_cases h : i + 1 < s
    · rw [if_pos (by omega)]; simp only [chainLine, if_pos h]; push_cast; ring
    · have : i + 1 = s := by omega
      have hc : ((i : ℝ) + 2) = (s : ℝ) + 1 := by rw [← this]; push_cast; ring
      rw [hc, div_self hs1.ne']
      split_ifs <;> simp [chainLine, show ¬ (i + 1 < s) from h]
  rw [chainOp, if_pos (show i < m by omega), hnext]
  rcases Nat.eq_zero_or_pos i with h0 | h0
  · subst h0; simp [chainLine, hi]; field_simp; ring
  · obtain ⟨j, rfl⟩ : ∃ j, i = j + 1 := ⟨i - 1, by omega⟩
    simp [chainLine, hi, show j < s by omega]
    field_simp; ring


lemma chainExt_mulVec {n : ℕ} (c : Fin n → ℝ) :
    chainExt (chainMatrix n *ᵥ c) = chainOp n (chainExt c) := by
  funext i
  by_cases h : i < n
  · simp only [chainExt, dif_pos h]
    exact chain_mulVec_eq c ⟨i, h⟩
  · simp [chainExt, chainOp, h]

lemma chain_dot_symm {n : ℕ} (a b : Fin n → ℝ) :
    a ⬝ᵥ (chainMatrix n *ᵥ b) = b ⬝ᵥ (chainMatrix n *ᵥ a) := by
  rw [dotProduct_eq_range, dotProduct_eq_range, chainExt_mulVec, chainExt_mulVec,
    chainOp_sum, chainOp_sum]
  congr 1
  · congr 1; apply Finset.sum_congr rfl; intro i _; ring
  · apply Finset.sum_congr rfl; intro i _; ring

lemma chain_dot_nonneg {n : ℕ} (a : Fin n → ℝ) : 0 ≤ a ⬝ᵥ (chainMatrix n *ᵥ a) := by
  rw [dotProduct_eq_range, chainExt_mulVec]
  exact chainOp_quad_nonneg _ _

/-- The chain operator on `m` coordinates, acting on the first `m` of `n` coordinates. -/
noncomputable def padOp (n m : ℕ) :
    EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n) :=
  LinearMap.toContinuousLinearMap
  { toFun := fun u => WithLp.toLp 2 (fun i : Fin n => chainOp m (chainExt (WithLp.ofLp u)) i)
    map_add' := by
      intro u v; ext i
      simp only [PiLp.toLp_apply, PiLp.add_apply, chainOp, chainExt, WithLp.ofLp_add, Pi.add_apply]
      split_ifs <;> ring
    map_smul' := by
      intro c u; ext i
      simp only [PiLp.toLp_apply, PiLp.smul_apply, chainOp, chainExt, WithLp.ofLp_smul,
        Pi.smul_apply, smul_eq_mul, RingHom.id_apply]
      split_ifs <;> ring }

lemma padOp_ext {n m : ℕ} (hmn : m ≤ n) (u : EuclideanSpace ℝ (Fin n)) :
    chainExt (WithLp.ofLp (padOp n m u)) = chainOp m (chainExt (WithLp.ofLp u)) := by
  funext i
  by_cases h : i < n
  · simp [chainExt, h, padOp]
  · simp [chainExt, chainOp, h, show ¬ i < m by omega]

lemma inner_eq_range {n : ℕ} (u v : EuclideanSpace ℝ (Fin n)) :
    inner ℝ u v = ∑ i ∈ Finset.range n, chainExt (WithLp.ofLp u) i * chainExt (WithLp.ofLp v) i := by
  rw [EuclideanSpace.inner_eq_star_dotProduct, dotProduct_comm, dotProduct_eq_range]
  simp

lemma sum_chainOp_cut {n m : ℕ} (hmn : m ≤ n) (U V : ℕ → ℝ) :
    ∑ i ∈ Finset.range n, V i * chainOp m U i = ∑ i ∈ Finset.range m, V i * chainOp m U i := by
  symm
  apply Finset.sum_subset (Finset.range_subset_range.2 hmn)
  intro i _ hi
  rw [Finset.mem_range] at hi
  simp [chainOp, hi]

lemma padOp_symm {n m : ℕ} (hmn : m ≤ n) (u v : EuclideanSpace ℝ (Fin n)) :
    inner ℝ u (padOp n m v) = inner ℝ (padOp n m u) v := by
  rw [inner_eq_range, inner_eq_range, padOp_ext hmn, padOp_ext hmn, sum_chainOp_cut hmn]
  rw [Finset.sum_congr rfl (fun i _ => mul_comm (chainOp m (chainExt (WithLp.ofLp u)) i) _),
    sum_chainOp_cut hmn, chainOp_sum, chainOp_sum]
  congr 1
  · congr 1; apply Finset.sum_congr rfl; intro i _; ring
  · apply Finset.sum_congr rfl; intro i _; ring

lemma padOp_nonneg {n m : ℕ} (hmn : m ≤ n) (u : EuclideanSpace ℝ (Fin n)) :
    0 ≤ inner ℝ u (padOp n m u) := by
  rw [inner_eq_range, padOp_ext hmn, sum_chainOp_cut hmn]
  exact chainOp_quad_nonneg _ _

lemma chainExt_sq_le {n : ℕ} (x : Fin n → ℝ) (N : ℕ) :
    ∑ i ∈ Finset.range N, chainExt x i ^ 2 ≤ ∑ i ∈ Finset.range n, chainExt x i ^ 2 := by
  have h1 : ∑ i ∈ Finset.range N, chainExt x i ^ 2 ≤
      ∑ i ∈ Finset.range (max N n), chainExt x i ^ 2 :=
    Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_subset_range.2 (le_max_left _ _))
      (fun i _ _ => sq_nonneg _)
  have h2 : ∑ i ∈ Finset.range (max N n), chainExt x i ^ 2 =
      ∑ i ∈ Finset.range n, chainExt x i ^ 2 := by
    symm
    apply Finset.sum_subset (Finset.range_subset_range.2 (le_max_right _ _))
    intro i _ hi
    rw [Finset.mem_range] at hi
    simp [chainExt, hi]
  linarith

lemma padOp_norm_le {n m : ℕ} (hmn : m ≤ n) (u : EuclideanSpace ℝ (Fin n)) :
    ‖padOp n m u‖ ≤ 4 * ‖u‖ := by
  set U := chainExt (WithLp.ofLp u) with hU
  have hn2 : ‖u‖ ^ 2 = ∑ i ∈ Finset.range n, U i ^ 2 := by
    rw [← real_inner_self_eq_norm_sq, inner_eq_range]
    apply Finset.sum_congr rfl; intro i _; ring
  have hT2 : ‖padOp n m u‖ ^ 2 = ∑ i ∈ Finset.range m, chainOp m U i ^ 2 := by
    rw [← real_inner_self_eq_norm_sq, inner_eq_range, padOp_ext hmn, sum_chainOp_cut hmn]
    apply Finset.sum_congr rfl; intro i _; ring
  have hterm : ∀ i ∈ Finset.range m, chainOp m U i ^ 2 ≤
      8 * U i ^ 2 + 4 * (if i = 0 then 0 else U (i - 1)) ^ 2 + 4 * U (i + 1) ^ 2 := by
    intro i hi
    rw [Finset.mem_range] at hi
    simp only [chainOp, if_pos hi]
    split_ifs
    · nlinarith [sq_nonneg (U i), sq_nonneg (U (i + 1)), sq_nonneg (U i + 2 * U (i + 1))]
    · nlinarith [sq_nonneg (U i), sq_nonneg (U (i + 1)), sq_nonneg (U i + 2 * U (i + 1))]
    · nlinarith [sq_nonneg (2 * U i + U (i - 1) + U (i + 1)), sq_nonneg (U (i - 1) - U (i + 1))]
    · nlinarith [sq_nonneg (U i + 2 * U (i - 1)), sq_nonneg (U (i + 1))]
  have hsum := Finset.sum_le_sum hterm
  rw [Finset.sum_add_distrib, Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum,
    ← Finset.mul_sum] at hsum
  have hA : ∑ i ∈ Finset.range m, U i ^ 2 ≤ ∑ i ∈ Finset.range n, U i ^ 2 := chainExt_sq_le _ _
  have hB : ∑ i ∈ Finset.range m, (if i = 0 then 0 else U (i - 1)) ^ 2 ≤
      ∑ i ∈ Finset.range n, U i ^ 2 := by
    rcases m with _ | p
    · simp; exact Finset.sum_nonneg (fun i _ => sq_nonneg _)
    · rw [Finset.sum_range_succ']; simp
      exact chainExt_sq_le _ _
  have hC : ∑ i ∈ Finset.range m, U (i + 1) ^ 2 ≤ ∑ i ∈ Finset.range n, U i ^ 2 := by
    have := Finset.sum_range_succ' (fun i => U i ^ 2) m
    have h2 := chainExt_sq_le (WithLp.ofLp u) (m + 1)
    rw [← hU] at h2
    nlinarith [sq_nonneg (U 0)]
  have hsq : ‖padOp n m u‖ ^ 2 ≤ (4 * ‖u‖) ^ 2 := by
    rw [hT2, mul_pow, hn2]; nlinarith
  nlinarith [norm_nonneg (padOp n m u), norm_nonneg u]

/-- The coordinates from place `j` on are all zero. -/
def zeroFrom (n j : ℕ) : Submodule ℝ (EuclideanSpace ℝ (Fin n)) where
  carrier := {v | ∀ i : Fin n, j ≤ (i : ℕ) → v i = 0}
  add_mem' := by intro a b ha hb i hi; simp [ha i hi, hb i hi]
  zero_mem' := by intro i _; simp
  smul_mem' := by intro c a ha i hi; simp [ha i hi]

lemma zeroFrom_ext {n j : ℕ} {v : EuclideanSpace ℝ (Fin n)} (hv : v ∈ zeroFrom n j) :
    ∀ l, j ≤ l → chainExt (WithLp.ofLp v) l = 0 := by
  intro l hl
  by_cases h : l < n
  · simp only [chainExt, dif_pos h]; exact hv ⟨l, h⟩ hl
  · simp [chainExt, h]

lemma zeroFrom_mono {n j₁ j₂ : ℕ} (h : j₁ ≤ j₂) : zeroFrom n j₁ ≤ zeroFrom n j₂ := by
  intro v hv i hi; exact hv i (le_trans h hi)

lemma padOp_zeroFrom {n m j : ℕ} {v : EuclideanSpace ℝ (Fin n)} (hv : v ∈ zeroFrom n j) :
    padOp n m v ∈ zeroFrom n (j + 1) := by
  intro i hi
  have h0 := zeroFrom_ext hv
  simp only [padOp, LinearMap.coe_toContinuousLinearMap', LinearMap.coe_mk, AddHom.coe_mk,
    PiLp.toLp_apply, chainOp]
  rw [h0 i (by omega), h0 (i - 1) (by omega), h0 (i + 1) (by omega)]
  split_ifs <;> simp

lemma sum_range_sq_affine (a b : ℝ) (N : ℕ) :
    ∑ i ∈ Finset.range N, (a + b * i) ^ 2 =
      N * a ^ 2 + a * b * N * (N - 1) + b ^ 2 * (N - 1) * N * (2 * N - 1) / 6 := by
  induction N with
  | zero => simp
  | succ N ih => rw [Finset.sum_range_succ, ih]; push_cast; ring


/-- The cost used for the lower bound: the chain on the first `m` coordinates, moved to start at `x₀`. -/
noncomputable def lbCost (n m : ℕ) (L : ℝ) (x₀ x : EuclideanSpace ℝ (Fin n)) : ℝ :=
  L / 8 * inner ℝ (x - x₀) (padOp n m (x - x₀))
    - L / 4 * inner ℝ (WithLp.toLp 2 (firstUnit n) : EuclideanSpace ℝ (Fin n)) (x - x₀)

/-- **The lower bound (Nesterov; Bubeck, Theorem 3.14).** Fix a curvature limit `L > 0`,
a number of gradient calls `k` and `n ≥ 2k + 1` coordinates, and a start `x₀`. Then there
is a convex cost `f` on `n` coordinates, differentiable with curvature at most `L`
(its gradient changes by at most `L` per unit moved), with a minimiser `x*` different
from the start, such that every method meeting the span condition
`xⱼ ∈ x₀ + span {∇f(x₀), …, ∇f(xⱼ₋₁)}` (for `j = 0, …, k`) is still above the lowest value
after `k` calls by at least `3 L ‖x₀ − x*‖² / (32 (k + 1)²)`. -/
theorem no_gradient_method_beats_one_over_k_squared
    (n k : ℕ) (hn : 2 * k + 1 ≤ n) (L : ℝ) (hL : 0 < L)
    (x₀ : EuclideanSpace ℝ (Fin n)) :
    ∃ f : EuclideanSpace ℝ (Fin n) → ℝ,
      ConvexOn ℝ Set.univ f ∧ Differentiable ℝ f ∧
      (∀ x y, ‖gradient f x - gradient f y‖ ≤ L * ‖x - y‖) ∧
      ∃ xstar : EuclideanSpace ℝ (Fin n), IsMinOn f Set.univ xstar ∧ xstar ≠ x₀ ∧
        ∀ xs : ℕ → EuclideanSpace ℝ (Fin n),
          (∀ j ≤ k, xs j - x₀ ∈
            Submodule.span ℝ ((fun i => gradient f (xs i)) '' Set.Iio j)) →
          3 * L * ‖x₀ - xstar‖ ^ 2 / (32 * ((k : ℝ) + 1) ^ 2) ≤ f (xs k) - f xstar := by
  set m := 2 * k + 1 with hm
  set T := padOp n m with hT
  set e : EuclideanSpace ℝ (Fin n) := WithLp.toLp 2 (firstUnit n) with he
  set w : ℕ → EuclideanSpace ℝ (Fin n) :=
    fun s => WithLp.toLp 2 (fun i : Fin n => chainLine s i) with hw
  set f := lbCost n m L x₀ with hf
  have hmn : m ≤ n := hn
  have he_ext : chainExt (WithLp.ofLp e) = fun i => if i = 0 then (1 : ℝ) else 0 := by
    funext i
    by_cases h : i < n
    · simp [chainExt, h, e, firstUnit]
    · simp [chainExt, h, show i ≠ 0 by omega]
  have hw_ext : ∀ s, s ≤ n → chainExt (WithLp.ofLp (w s)) = chainLine s := by
    intro s hs; funext i
    by_cases h : i < n
    · simp [chainExt, h, w]
    · simp [chainExt, h, chainLine, show ¬ i < s by omega]
  have hsymm : ∀ u v, inner ℝ u (T v) = inner ℝ (T u) v := padOp_symm hmn
  have hpsd : ∀ u, 0 ≤ inner ℝ u (T u) := padOp_nonneg hmn
  have hmatch : ∀ s, s ≤ m → ∀ u ∈ zeroFrom n s, inner ℝ (T (w s)) u = inner ℝ e u := by
    intro s hs u hu
    rw [inner_eq_range, inner_eq_range, hT, padOp_ext hmn, hw_ext s (by omega), he_ext]
    apply Finset.sum_congr rfl
    intro i _
    by_cases hi : i < s
    · rw [chainOp_line m s hs i hi]
    · rw [zeroFrom_ext hu i (by omega)]; simp
  have hw_mem : ∀ s, w s ∈ zeroFrom n s := by
    intro s i hi; simp [w, chainLine, show ¬ (i : ℕ) < s by omega]
  have he_mem : e ∈ zeroFrom n 1 := by
    intro i hi; simp [e, firstUnit]; omega
  have he_w : ∀ s, s ≤ n → inner ℝ e (w s) = 1 - 1 / ((s : ℝ) + 1) := by
    intro s hs
    rw [inner_eq_range, he_ext, hw_ext s hs]
    simp only [ite_mul, one_mul, zero_mul, Finset.sum_ite_eq', Finset.mem_range,
      if_pos (show 0 < n by omega)]
    rcases Nat.eq_zero_or_pos s with h0 | h0
    · subst h0; simp [chainLine]
    · simp [chainLine, h0]
  have hkey : ∀ u v, inner ℝ (T v) u = inner ℝ e u → inner ℝ (T v) v = inner ℝ e v →
      L / 8 * inner ℝ u (T u) - L / 4 * inner ℝ e u =
        L / 8 * inner ℝ (u - v) (T (u - v)) - L / 8 * inner ℝ e v := by
    intro u v h1 h2
    have a1 : inner ℝ u (T v) = inner ℝ e u := by rw [real_inner_comm]; exact h1
    have a2 : inner ℝ v (T u) = inner ℝ e u := by rw [hsymm]; exact h1
    have a3 : inner ℝ v (T v) = inner ℝ e v := by rw [real_inner_comm]; exact h2
    rw [map_sub, inner_sub_left, inner_sub_right, inner_sub_right, a1, a2, a3]; ring
  have hlow : ∀ u v, inner ℝ (T v) u = inner ℝ e u → inner ℝ (T v) v = inner ℝ e v →
      -(L / 8) * inner ℝ e v ≤ L / 8 * inner ℝ u (T u) - L / 4 * inner ℝ e u := by
    intro u v h1 h2
    rw [hkey u v h1 h2]
    nlinarith [mul_nonneg hL.le (hpsd (u - v))]
  have hTw : T (w m) = e := by
    ext i
    have := congrFun (padOp_ext hmn (w m)) i
    simp only [chainExt, dif_pos i.isLt] at this
    rw [← hT, hw_ext m hmn] at this
    rw [this]
    by_cases hi : (i : ℕ) < m
    · rw [chainOp_line m m le_rfl i hi]; simp [e, firstUnit]
    · simp [chainOp, hi, e, firstUnit]; omega
  have hgrad : ∀ x, HasGradientAt f ((L / 4) • (T (x - x₀) - e)) x := by
    intro x
    rw [hasGradientAt_iff_hasFDerivAt]
    have hu : HasFDerivAt (fun y : EuclideanSpace ℝ (Fin n) => y - x₀)
        (ContinuousLinearMap.id ℝ (EuclideanSpace ℝ (Fin n))) x :=
      hasFDerivAt_sub_const x₀
    have hTu : HasFDerivAt (fun y : EuclideanSpace ℝ (Fin n) => T (y - x₀))
        (T.comp (ContinuousLinearMap.id ℝ (EuclideanSpace ℝ (Fin n)))) x :=
      T.hasFDerivAt.comp x hu
    have hq := HasFDerivAt.inner ℝ hu hTu
    have hl : HasFDerivAt (fun y : EuclideanSpace ℝ (Fin n) => inner ℝ e (y - x₀))
        ((innerSL ℝ e).comp (ContinuousLinearMap.id ℝ (EuclideanSpace ℝ (Fin n)))) x :=
      (innerSL ℝ e).hasFDerivAt.comp x hu
    have hfd := (hq.const_mul (L / 8)).sub (hl.const_mul (L / 4))
    refine HasFDerivAt.congr_fderiv hfd ?_
    ext h
    simp only [InnerProductSpace.toDual_apply_apply, ContinuousLinearMap.sub_apply,
      ContinuousLinearMap.smul_apply, ContinuousLinearMap.coe_comp', Function.comp_apply,
      ContinuousLinearMap.prod_apply, fderivInnerCLM_apply, ContinuousLinearMap.coe_id', id,
      innerSL_apply_apply, smul_eq_mul]
    rw [real_inner_smul_left, hsymm (x - x₀) h, real_inner_comm (T (x - x₀)) h, inner_sub_left]
    ring
  refine ⟨f, ?_, fun x => (hgrad x).differentiableAt, ?_, x₀ + w m, ?_, ?_, ?_⟩
  · -- convexity
    refine ⟨convex_univ, ?_⟩
    intro x _ y _ a b ha hb hab
    obtain rfl : b = 1 - a := by linarith
    have hxy : a • x + (1 - a) • y - x₀ = a • (x - x₀) + (1 - a) • (y - x₀) := by module
    simp only [hf, lbCost, smul_eq_mul, hxy, ← hT, ← he]
    set u := x - x₀
    set v := y - x₀
    have e1 : inner ℝ (a • u + (1 - a) • v) (T (a • u + (1 - a) • v)) =
        a * a * inner ℝ u (T u) + a * (1 - a) * inner ℝ u (T v)
          + (1 - a) * a * inner ℝ v (T u) + (1 - a) * (1 - a) * inner ℝ v (T v) := by
      simp only [map_add, map_smul, inner_add_left, inner_add_right, real_inner_smul_left,
        real_inner_smul_right]; ring
    have e2 : inner ℝ e (a • u + (1 - a) • v) = a * inner ℝ e u + (1 - a) * inner ℝ e v := by
      simp only [inner_add_right, real_inner_smul_right]
    have e4 : inner ℝ v (T u) = inner ℝ u (T v) := by
      rw [hsymm v u]; exact real_inner_comm _ _
    have hp := hpsd (u - v)
    simp only [map_sub, inner_sub_left, inner_sub_right] at hp
    rw [e4] at hp
    rw [e1, e2, e4]
    nlinarith [mul_nonneg (mul_nonneg (mul_nonneg hL.le ha) hb) hp]
  · -- gradient changes by at most L per unit
    intro x y
    have hd : T (x - x₀) - e - (T (y - x₀) - e) = T (x - y) := by
      rw [sub_sub_sub_cancel_right, ← map_sub, sub_sub_sub_cancel_right]
    rw [(hgrad x).gradient, (hgrad y).gradient, ← smul_sub, hd, norm_smul, Real.norm_eq_abs, abs_of_pos (by positivity)]
    have := padOp_norm_le hmn (x - y)
    rw [← hT] at this
    nlinarith
  · -- x₀ + w m is a minimiser
    intro x _
    have h1 := hlow (x - x₀) (w m) (by rw [hTw]) (by rw [hTw])
    have h2 := hkey (w m) (w m) (by rw [hTw]) (by rw [hTw])
    simp only [sub_self, map_zero, inner_zero_left, mul_zero, zero_sub] at h2
    show f (x₀ + w m) ≤ f x
    simp only [hf, lbCost, add_sub_cancel_left, ← hT, ← he]
    linarith
  · -- it is not the start
    intro h
    have h0 : w m = 0 := by simpa using h
    have := congrArg (fun v : EuclideanSpace ℝ (Fin n) => v ⟨0, by omega⟩) h0
    simp [w, chainLine] at this
    have h3 := this (by omega)
    have h4' : ((m : ℝ) + 1)⁻¹ = 1 := by linarith
    rw [inv_eq_one] at h4'
    have h4 : (m : ℝ) = 0 := by linarith
    have h5 : m = 0 := by exact_mod_cast h4
    omega
  · -- the lower bound
    intro xs hspan
    have hsupp : ∀ j, j ≤ k → xs j - x₀ ∈ zeroFrom n j := by
      intro j
      induction j using Nat.strong_induction_on with
      | _ j ih =>
        intro hj
        refine Submodule.span_le.2 ?_ (hspan j hj)
        rintro _ ⟨i, hi, rfl⟩
        rw [Set.mem_Iio] at hi
        show gradient f (xs i) ∈ zeroFrom n j
        rw [(hgrad (xs i)).gradient]
        have h1 : T (xs i - x₀) ∈ zeroFrom n j :=
          zeroFrom_mono (by omega) (padOp_zeroFrom (ih i hi (by omega)))
        have h2 : e ∈ zeroFrom n j := zeroFrom_mono (show 1 ≤ j by omega) he_mem
        exact (zeroFrom n j).smul_mem _ ((zeroFrom n j).sub_mem h1 h2)
    have hlowk := hlow (xs k - x₀) (w k) (hmatch k (by omega) _ (hsupp k le_rfl))
      (hmatch k (by omega) _ (hw_mem k))
    rw [he_w k (by omega)] at hlowk
    have h2 := hkey (w m) (w m) (by rw [hTw]) (by rw [hTw])
    simp only [sub_self, map_zero, inner_zero_left, mul_zero, zero_sub] at h2
    rw [he_w m hmn] at h2
    have hfk : f (xs k) = L / 8 * inner ℝ (xs k - x₀) (T (xs k - x₀))
        - L / 4 * inner ℝ e (xs k - x₀) := rfl
    have hfs : f (x₀ + w m) = -(L / 8) * (1 - 1 / ((m : ℝ) + 1)) := by
      simp only [hf, lbCost, add_sub_cancel_left, ← hT, ← he]
      rw [he_w m hmn]; linarith
    have hK : (0 : ℝ) < (k : ℝ) + 1 := by positivity
    have hmK : (m : ℝ) + 1 = 2 * ((k : ℝ) + 1) := by rw [hm]; push_cast; ring
    have hgap : L / (16 * ((k : ℝ) + 1)) ≤ f (xs k) - f (x₀ + w m) := by
      rw [hfs, hmK]
      have : L / (16 * ((k : ℝ) + 1)) =
          -(L / 8) * (1 - 1 / ((k : ℝ) + 1)) + L / 8 * (1 - 1 / (2 * ((k : ℝ) + 1))) := by
        field_simp; ring
      rw [this]; linarith
    -- the squared distance
    have hR : ‖x₀ - (x₀ + w m)‖ ^ 2 =
        (m : ℝ) * (1 - 1 / ((m : ℝ) + 1)) ^ 2
          + (1 - 1 / ((m : ℝ) + 1)) * (-1 / ((m : ℝ) + 1)) * m * (m - 1)
          + (-1 / ((m : ℝ) + 1)) ^ 2 * (m - 1) * m * (2 * m - 1) / 6 := by
      rw [sub_add_cancel_left, norm_neg, ← real_inner_self_eq_norm_sq, inner_eq_range,
        hw_ext m hmn, ← sum_range_sq_affine]
      symm
      rw [← Finset.sum_subset (Finset.range_subset_range.2 hmn)]
      · apply Finset.sum_congr rfl
        intro i hi
        rw [Finset.mem_range] at hi
        simp only [chainLine, if_pos hi]
        field_simp; ring
      · intro i _ hi
        rw [Finset.mem_range] at hi
        simp [chainLine, hi]
    have hR2 : 3 * ‖x₀ - (x₀ + w m)‖ ^ 2 ≤ 2 * ((k : ℝ) + 1) := by
      rw [hR]
      have hmc : (m : ℝ) = 2 * ((k : ℝ) + 1) - 1 := by linarith
      rw [hmK, hmc]
      field_simp
      nlinarith
    calc 3 * L * ‖x₀ - (x₀ + w m)‖ ^ 2 / (32 * ((k : ℝ) + 1) ^ 2)
        ≤ L * (2 * ((k : ℝ) + 1)) / (32 * ((k : ℝ) + 1) ^ 2) := by
          apply div_le_div_of_nonneg_right _ (by positivity)
          nlinarith
      _ = L / (16 * ((k : ℝ) + 1)) := by field_simp; ring
      _ ≤ f (xs k) - f (x₀ + w m) := hgap

/-- **Each gradient uncovers one more coordinate (Step 1).** The chain's gradient is
`(L/4)(A x − e₁)`. If a point `x` is zero in every coordinate from place `j` on
(counting places from 0), then that gradient is zero in every coordinate from place
`j + 1` on: each entry of `A x` looks only one place to each side. -/
theorem chain_gradient_uncovers_one_coordinate (n j : ℕ) (L : ℝ) (x : Fin n → ℝ)
    (hx : ∀ i : Fin n, j ≤ (i : ℕ) → x i = 0) :
    ∀ i : Fin n, j + 1 ≤ (i : ℕ) →
      (L / 4) * ((chainMatrix n *ᵥ x) i - firstUnit n i) = 0 := by
  intro i hi
  have h1 : (chainMatrix n *ᵥ x) i = 0 := by
    simp only [mulVec, dotProduct]
    apply Finset.sum_eq_zero
    intro l _
    by_cases hl : j ≤ (l : ℕ)
    · simp [hx l hl]
    · have hne : i ≠ l := by intro h; subst h; omega
      have : ¬ ((i : ℕ) + 1 = l ∨ (l : ℕ) + 1 = i) := by omega
      simp [chainMatrix, hne, this]
  have h2 : firstUnit n i = 0 := by simp [firstUnit]; omega
  rw [h1, h2]; ring

/-- **The best point with k coordinates is a straight line (Step 2).** On a chain of
`k` coordinates with `L > 0`, the point `xᵢ = 1 − i/(k+1)` (for `i = 1, …, k`) solves
`A x = e₁`, it minimises the chain, and the lowest value is `−(L/8)(1 − 1/(k+1))`. -/
theorem chain_minimiser_is_a_straight_line (k : ℕ) (L : ℝ) (hL : 0 < L) :
    let xline : Fin k → ℝ := fun i => 1 - ((i : ℕ) + 1 : ℝ) / ((k : ℝ) + 1)
    chainMatrix k *ᵥ xline = firstUnit k ∧
      chainCost k L xline = -(L / 8) * (1 - 1 / ((k : ℝ) + 1)) ∧
      ∀ y : Fin k → ℝ, chainCost k L xline ≤ chainCost k L y := by
  intro xline
  have hext : chainExt xline = chainLine k := by
    funext i; simp only [chainExt, chainLine, xline]; split_ifs <;> rfl
  have hA : chainMatrix k *ᵥ xline = firstUnit k := by
    funext i
    rw [chain_mulVec_eq, hext, chainOp_line k k le_rfl i i.isLt]
    simp [firstUnit]
  have he : firstUnit k ⬝ᵥ xline = 1 - 1 / ((k : ℝ) + 1) := by
    rw [dotProduct_eq_range, hext]
    have : ∀ i ∈ Finset.range k, chainExt (firstUnit k) i * chainLine k i =
        if i = 0 then chainLine k i else 0 := by
      intro i hi
      rw [Finset.mem_range] at hi
      simp only [chainExt, dif_pos hi, firstUnit]
      split_ifs <;> simp
    rw [Finset.sum_congr rfl this, Finset.sum_ite_eq']
    rcases Nat.eq_zero_or_pos k with h0 | h0
    · subst h0; simp
    · simp [Finset.mem_range, h0, chainLine]
  have hcost : chainCost k L xline = -(L / 8) * (1 - 1 / ((k : ℝ) + 1)) := by
    rw [chainCost, hA, dotProduct_comm, he]; ring
  refine ⟨hA, hcost, fun y => ?_⟩
  have h := chain_dot_nonneg (y - xline)
  rw [mulVec_sub, dotProduct_sub, sub_dotProduct, sub_dotProduct, hA,
    chain_dot_symm xline y, hA] at h
  have h2 : chainCost k L y - chainCost k L xline =
      L / 8 * (y ⬝ᵥ (chainMatrix k *ᵥ y) - y ⬝ᵥ firstUnit k - (y ⬝ᵥ firstUnit k
        - xline ⬝ᵥ firstUnit k)) := by
    rw [chainCost, chainCost, hA, dotProduct_comm (firstUnit k) y,
      dotProduct_comm (firstUnit k) xline]; ring
  nlinarith [mul_nonneg hL.le h]


-- The card's worked numbers: chain of 21 coordinates, L = 1, start 0, k = 10 calls.
-- Squared start distance: the sum of (i/22)^2 for i = 1..21 is 3311/484, below (21 + 1)/3.
example : (∑ i ∈ Finset.range 22, ((i : ℚ) / 22) ^ 2) = 3311 / 484 := by
  norm_num [Finset.sum_range_succ]
example : (3311 : ℚ) / 484 ≤ 22 / 3 := by norm_num
-- Lowest value of the full chain, and of the best point in 10 coordinates.
example : -(1 : ℚ) / 8 * (1 - 1 / 22) = -21 / 176 := by norm_num
example : -(1 : ℚ) / 8 * (1 - 1 / 11) = -10 / 88 := by norm_num
-- The gap 1/176, the gap per unit L R^2, and the theorem's floor 3/(32 * 11^2) below it.
example : (1 : ℚ) / 8 * (1 / 11 - 1 / 22) = 1 / 176 := by norm_num
example : ((1 : ℚ) / 176) / (3311 / 484) = 11 / 13244 := by norm_num
example : (3 : ℚ) / (32 * 11 ^ 2) ≤ 11 / 13244 := by norm_num
-- Calls to promise a gap at most 0.0001 L R^2: floor 30, Nesterov 141, gradient descent 5000.
example : (3 : ℚ) / (32 * 31 ^ 2) ≤ 1 / 10000 ∧ 1 / 10000 < (3 : ℚ) / (32 * 30 ^ 2) := by norm_num
example : (2 : ℚ) / 142 ^ 2 ≤ 1 / 10000 ∧ 1 / 10000 < (2 : ℚ) / 141 ^ 2 := by norm_num
example : (1 : ℚ) / (2 * 5000) ≤ 1 / 10000 ∧ 1 / 10000 < (1 : ℚ) / (2 * 4999) := by norm_num
-- Calls to promise a gap at most 0.000001 L R^2: floor 306, Nesterov 1414, gradient descent 500000.
example : (3 : ℚ) / (32 * 307 ^ 2) ≤ 1 / 1000000 ∧ 1 / 1000000 < (3 : ℚ) / (32 * 306 ^ 2) := by
  norm_num
example : (2 : ℚ) / 1415 ^ 2 ≤ 1 / 1000000 ∧ 1 / 1000000 < (2 : ℚ) / 1414 ^ 2 := by norm_num
example : (1 : ℚ) / (2 * 500000) ≤ 1 / 1000000 ∧ 1 / 1000000 < (1 : ℚ) / (2 * 499999) := by
  norm_num

#print axioms no_gradient_method_beats_one_over_k_squared
#print axioms chain_gradient_uncovers_one_coordinate
#print axioms chain_minimiser_is_a_straight_line
#print axioms chainExt_coe
#print axioms dotProduct_eq_range
#print axioms chain_mulVec_eq
#print axioms chainOp_sum
#print axioms chainOp_quad_nonneg
#print axioms chainOp_line
#print axioms chainExt_mulVec
#print axioms chain_dot_symm
#print axioms chain_dot_nonneg
#print axioms padOp_ext
#print axioms inner_eq_range
#print axioms sum_chainOp_cut
#print axioms padOp_symm
#print axioms padOp_nonneg
#print axioms chainExt_sq_le
#print axioms padOp_norm_le
#print axioms zeroFrom_ext
#print axioms zeroFrom_mono
#print axioms padOp_zeroFrom
#print axioms sum_range_sq_affine
