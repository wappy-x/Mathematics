-- The interpolation error theorem: the error of the polynomial through n + 1 distinct nodes is the (n + 1)-th derivative at some point of the span, over (n + 1)!, times the product of the distances to the nodes.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.Topology.Algebra.Polynomial

/-! The nodes are `x 0, ..., x n`, distinct. The interpolating polynomial is Mathlib's
`Lagrange.interpolate univ x (fun i => f (x i))`, the one polynomial of degree at most `n`
through the points `(x i, f (x i))`. The node polynomial `ω(t) = (t - x 0) ⋯ (t - x n)` is
Mathlib's `Lagrange.nodal univ x`. The point where the error is read is `t`, and `[a, b]` is the
smallest closed interval holding `t` and all the nodes. "f has n + 1 derivatives across the span"
is stated as in Mathlib's Taylor theorem: the `n`-th derivative is continuous on `[a, b]` and
differentiable inside it; derivatives are taken within `[a, b]`. -/

open Polynomial Lagrange Finset Set
open scoped Nat

/-- Repeated Rolle: if `F 0` vanishes at `N + 1` increasing points of `[a, b]` and each `F k`
has derivative `F (k + 1)` inside, then `F N` vanishes between the outer points. -/
theorem rolle_chain {a b : ℝ} : ∀ (N : ℕ) (F : ℕ → ℝ → ℝ),
    (∀ k < N, ContinuousOn (F k) (Icc a b)) →
    (∀ k < N, ∀ y ∈ Ioo a b, HasDerivAt (F k) (F (k + 1) y) y) →
    ∀ z : Fin (N + 1) → ℝ, StrictMono z → (∀ i, z i ∈ Icc a b) → (∀ i, F 0 (z i) = 0) →
    ∃ ξ, z 0 ≤ ξ ∧ ξ ≤ z (Fin.last N) ∧ (0 < N → z 0 < ξ ∧ ξ < z (Fin.last N)) ∧
      F N ξ = 0 := by
  intro N
  induction N with
  | zero =>
    intro F _ _ z _ _ hz0
    exact ⟨z 0, le_rfl, le_rfl, fun h => absurd h (lt_irrefl 0), hz0 0⟩
  | succ N ih =>
    intro F hc hd z hz hzab hz0
    have hstep : ∀ i : Fin (N + 1), ∃ c ∈ Ioo (z i.castSucc) (z i.succ), F 1 c = 0 := by
      intro i
      have hlt : z i.castSucc < z i.succ := hz (Fin.castSucc_lt_succ (i := i))
      have h1 := hzab i.castSucc
      have h2 := hzab i.succ
      have hsub : Icc (z i.castSucc) (z i.succ) ⊆ Icc a b := Icc_subset_Icc h1.1 h2.2
      exact exists_hasDerivAt_eq_zero hlt ((hc 0 (Nat.succ_pos N)).mono hsub)
        ((hz0 _).trans (hz0 _).symm)
        (fun y hy => hd 0 (Nat.succ_pos N) y ⟨lt_of_le_of_lt h1.1 hy.1, lt_of_lt_of_le hy.2 h2.2⟩)
    choose w hw hw0 using hstep
    have hwmono : StrictMono w := by
      rw [Fin.strictMono_iff_lt_succ]
      intro i
      have e1 := (hw i.castSucc).2
      have e2 := (hw i.succ).1
      rw [Fin.succ_castSucc] at e1
      linarith
    have hwab : ∀ i, w i ∈ Icc a b := fun i =>
      ⟨le_of_lt (lt_of_le_of_lt (hzab _).1 (hw i).1), le_of_lt (lt_of_lt_of_le (hw i).2 (hzab _).2)⟩
    obtain ⟨ξ, h1, h2, -, h4⟩ := ih (fun k => F (k + 1))
      (fun k hk => hc (k + 1) (by omega)) (fun k hk => hd (k + 1) (by omega)) w hwmono hwab hw0
    have e0 := (hw 0).1
    have eL := (hw (Fin.last N)).2
    simp only [Fin.castSucc_zero, Fin.succ_last] at e0 eL
    refine ⟨ξ, by linarith, by linarith, fun _ => ⟨by linarith, by linarith⟩, h4⟩

#print axioms rolle_chain

/-- The `(n + 1)`-th derivative of the monic node polynomial is `(n + 1)!`. -/
theorem iterate_derivative_nodal_fin {n : ℕ} (x : Fin (n + 1) → ℝ) :
    derivative^[n + 1] (nodal univ x) = ((n + 1)! : ℝ[X]) := by
  have hdeg : (nodal univ x).natDegree = n + 1 := by
    rw [natDegree_nodal, card_univ, Fintype.card_fin]
  have hmon : (nodal univ x).Monic := nodal_monic
  have hlt : (nodal univ x - X ^ (n + 1)).degree < ((n + 1 : ℕ) : WithBot ℕ) := by
    have hne : nodal univ x ≠ 0 := hmon.ne_zero
    have h := degree_sub_lt_left (p := nodal univ x) (q := X ^ (n + 1))
      (by rw [degree_X_pow, degree_eq_natDegree hne, hdeg]) hne
      (by rw [hmon.leadingCoeff, leadingCoeff_X_pow])
    rwa [degree_eq_natDegree hne, hdeg] at h
  have hsplit : nodal univ x = X ^ (n + 1) + (nodal univ x - X ^ (n + 1)) := by ring
  rw [hsplit, iterate_map_add, iterate_derivative_eq_zero_of_degree_lt hlt, add_zero,
    iterate_derivative_X_pow_eq_natCast_mul, Nat.sub_self, pow_zero, mul_one,
    Nat.descFactorial_self]

#print axioms iterate_derivative_nodal_fin

/-- The interpolation error theorem: if `f` has `n + 1` derivatives across the smallest interval
`[a, b]` holding `t` and the `n + 1` distinct nodes, then there is a point `ξ` in that interval
(strictly inside it whenever it has length) with
`f t - p_n t = f^(n+1)(ξ) / (n + 1)! * ω(t)`. -/
theorem interpolation_error_theorem {n : ℕ} (f : ℝ → ℝ) (x : Fin (n + 1) → ℝ)
    (hx : Function.Injective x) (t a b : ℝ)
    (ha : IsLeast (insert t (range x)) a) (hb : IsGreatest (insert t (range x)) b)
    (hf : ContDiffOn ℝ n f (Icc a b))
    (hf' : DifferentiableOn ℝ (iteratedDerivWithin n f (Icc a b)) (Ioo a b)) :
    ∃ ξ ∈ Icc a b, (a < b → ξ ∈ Ioo a b) ∧
      f t - (interpolate univ x (fun i => f (x i))).eval t =
        iteratedDerivWithin (n + 1) f (Icc a b) ξ / (n + 1)! * (nodal univ x).eval t := by
  classical
  have hmemA : ∀ y ∈ insert t (range x), a ≤ y ∧ y ≤ b := fun y hy => ⟨ha.2 hy, hb.2 hy⟩
  have hxab : ∀ i, a ≤ x i ∧ x i ≤ b := fun i => hmemA _ (mem_insert_of_mem _ ⟨i, rfl⟩)
  have hinj : Set.InjOn x (univ : Finset (Fin (n + 1))) := hx.injOn
  by_cases hnode : ∃ i, x i = t
  · obtain ⟨i, rfl⟩ := hnode
    refine ⟨(a + b) / 2, ⟨by linarith [hxab i], by linarith [hxab i]⟩,
      fun h => ⟨by linarith, by linarith⟩, ?_⟩
    rw [eval_interpolate_at_node _ hinj (mem_univ i), eval_nodal_at_node (mem_univ i)]
    simp
  simp only [not_exists] at hnode
  set p := interpolate univ x (fun i => f (x i)) with hp
  set ω := nodal univ x with hω
  have hωt : ω.eval t ≠ 0 := by
    rw [hω, eval_nodal]
    exact prod_ne_zero_iff.mpr fun i _ => sub_ne_zero.mpr fun h => hnode i h.symm
  set K := (f t - p.eval t) / ω.eval t with hK
  set S : Finset ℝ := insert t (univ.image x) with hS
  have hcard : S.card = n + 2 := by
    rw [hS, card_insert_of_notMem, Finset.card_image_of_injective _ hx, card_univ, Fintype.card_fin]
    simp only [Finset.mem_image, Finset.mem_univ, true_and, not_exists]
    exact hnode
  set z := S.orderEmbOfFin hcard with hz
  have hzS : ∀ i, z i ∈ S := fun i => orderEmbOfFin_mem S hcard i
  have hzab : ∀ i, z i ∈ Icc a b := by
    intro i
    have := hzS i
    rw [hS, Finset.mem_insert, Finset.mem_image] at this
    rcases this with h | ⟨j, -, h⟩
    · rw [h]; exact hmemA t (mem_insert _ _)
    · rw [← h]; exact hxab j
  have hab : a < b := by
    have h01 : z 0 < z 1 := z.strictMono (by simp)
    linarith [(hzab 0).1, (hzab 1).2]
  have hU : UniqueDiffOn ℝ (Icc a b) := uniqueDiffOn_Icc hab
  set F : ℕ → ℝ → ℝ := fun k y => iteratedDerivWithin k f (Icc a b) y -
    (derivative^[k] p).eval y - K * (derivative^[k] ω).eval y with hF
  have hcont : ∀ k < n + 1, ContinuousOn (F k) (Icc a b) := by
    intro k hk
    have h1 := hf.continuousOn_iteratedDerivWithin (m := k) (by exact_mod_cast Nat.lt_succ_iff.mp hk) hU
    exact (h1.sub (Polynomial.continuousOn _)).sub (continuousOn_const.mul (Polynomial.continuousOn _))
  have hderiv : ∀ k < n + 1, ∀ y ∈ Ioo a b, HasDerivAt (F k) (F (k + 1) y) y := by
    intro k hk y hy
    have hnhds : Icc a b ∈ nhds y := Icc_mem_nhds hy.1 hy.2
    have hd : DifferentiableAt ℝ (iteratedDerivWithin k f (Icc a b)) y := by
      rcases Nat.lt_succ_iff_lt_or_eq.mp hk with hk | rfl
      · exact (hf.differentiableOn_iteratedDerivWithin (by exact_mod_cast hk) hU y
          (Ioo_subset_Icc_self hy)).differentiableAt hnhds
      · exact (hf' y hy).differentiableAt (Ioo_mem_nhds hy.1 hy.2)
    have h1 : HasDerivAt (iteratedDerivWithin k f (Icc a b))
        (iteratedDerivWithin (k + 1) f (Icc a b) y) y := by
      rw [iteratedDerivWithin_succ, derivWithin_of_mem_nhds hnhds]
      exact hd.hasDerivAt
    have h2 := (derivative^[k] p).hasDerivAt y
    have h3 := (derivative^[k] ω).hasDerivAt y
    simp only [hF, Function.iterate_succ_apply']
    exact (h1.sub h2).sub (h3.const_mul K)
  have hzero : ∀ i, F 0 (z i) = 0 := by
    intro i
    have := hzS i
    rw [hS, Finset.mem_insert, Finset.mem_image] at this
    simp only [hF, iteratedDerivWithin_zero, Function.iterate_zero, id]
    rcases this with h | ⟨j, -, h⟩
    · rw [h, hK]; field_simp; ring
    · rw [← h, hp, hω, eval_interpolate_at_node _ hinj (mem_univ j),
        eval_nodal_at_node (mem_univ j)]
      ring
  obtain ⟨ξ, -, -, hξ, hFξ⟩ := rolle_chain (n + 1) F hcont hderiv z z.strictMono hzab hzero
  obtain ⟨hξ1, hξ2⟩ := hξ (Nat.succ_pos n)
  have hξab : ξ ∈ Ioo a b :=
    ⟨lt_of_le_of_lt (hzab 0).1 hξ1, lt_of_lt_of_le hξ2 (hzab _).2⟩
  refine ⟨ξ, Ioo_subset_Icc_self hξab, fun _ => hξab, ?_⟩
  have hpdeg : (derivative^[n + 1] p) = 0 := by
    apply iterate_derivative_eq_zero_of_degree_lt
    have := degree_interpolate_lt (r := fun i => f (x i)) hinj
    rwa [card_univ, Fintype.card_fin] at this
  simp only [hF, hpdeg, hω, iterate_derivative_nodal_fin, eval_zero, sub_zero, eval_natCast] at hFξ
  have hfac : ((n + 1)! : ℝ) ≠ 0 := by positivity
  have hK' : K = iteratedDerivWithin (n + 1) f (Icc a b) ξ / (n + 1)! := by
    field_simp; linarith
  rw [← hK', hK]
  field_simp

/-- The bound: if the `(n + 1)`-th derivative never exceeds `M` in size across the span,
the error at `t` is at most `M / (n + 1)!` times the size of the node polynomial at `t`. -/
theorem interpolation_error_bound {n : ℕ} (f : ℝ → ℝ) (x : Fin (n + 1) → ℝ)
    (hx : Function.Injective x) (t a b M : ℝ)
    (ha : IsLeast (insert t (range x)) a) (hb : IsGreatest (insert t (range x)) b)
    (hf : ContDiffOn ℝ n f (Icc a b))
    (hf' : DifferentiableOn ℝ (iteratedDerivWithin n f (Icc a b)) (Ioo a b))
    (hM : ∀ y ∈ Ioo a b, |iteratedDerivWithin (n + 1) f (Icc a b) y| ≤ M) :
    |f t - (interpolate univ x (fun i => f (x i))).eval t| ≤
      M / (n + 1)! * |(nodal univ x).eval t| := by
  obtain ⟨ξ, -, hξI, heq⟩ := interpolation_error_theorem f x hx t a b ha hb hf hf'
  have hfac : (0 : ℝ) < (n + 1)! := by positivity
  rw [heq, abs_mul, abs_div, abs_of_pos hfac]
  by_cases hω : (nodal univ x).eval t = 0
  · simp [hω]
  · have hab : a < b := by
      have hne : x 0 ≠ t := fun h => hω (by rw [← h]; exact eval_nodal_at_node (Finset.mem_univ 0))
      have h1 : a ≤ x 0 := ha.2 (mem_insert_of_mem _ ⟨0, rfl⟩)
      have h2 : x 0 ≤ b := hb.2 (mem_insert_of_mem _ ⟨0, rfl⟩)
      have h3 : a ≤ t := ha.2 (mem_insert _ _)
      have h4 : t ≤ b := hb.2 (mem_insert _ _)
      rcases hne.lt_or_gt with h | h <;> linarith
    have := hM ξ (hξI hab)
    gcongr

/-- Four equal nodes `x₀, x₀ + h, x₀ + 2h, x₀ + 3h`: across their span the node polynomial never
exceeds `h ^ 4` in size, and it reaches `h ^ 4` at `x₀ + s h` with `s = (3 - √5) / 2`. -/
theorem equal_nodes_max_node_polynomial (x₀ h : ℝ) :
    (∀ t ∈ Icc x₀ (x₀ + 3 * h),
      |(nodal univ (fun k : Fin 4 => x₀ + ((k : ℕ) : ℝ) * h)).eval t| ≤ h ^ 4) ∧
    |(nodal univ (fun k : Fin 4 => x₀ + ((k : ℕ) : ℝ) * h)).eval (x₀ + (3 - √5) / 2 * h)| = h ^ 4 := by
  have key : ∀ t, (nodal univ (fun k : Fin 4 => x₀ + ((k : ℕ) : ℝ) * h)).eval t =
      ((t - x₀) ^ 2 - 3 * h * (t - x₀) + h ^ 2) ^ 2 - h ^ 4 := by
    intro t
    rw [eval_nodal, Fin.prod_univ_four]
    simp
    ring
  refine ⟨fun t ht => ?_, ?_⟩
  · rw [key, abs_le]
    obtain ⟨h1, h2⟩ := ht
    set u := t - x₀ with hu
    have hu0 : 0 ≤ u := by linarith
    have hu3 : u ≤ 3 * h := by linarith
    have hw1 : u ^ 2 - 3 * h * u + h ^ 2 ≤ h ^ 2 := by nlinarith
    have hw2 : -(5 / 4) * h ^ 2 ≤ u ^ 2 - 3 * h * u + h ^ 2 := by nlinarith [sq_nonneg (u - 3 / 2 * h)]
    constructor
    · nlinarith [sq_nonneg (u ^ 2 - 3 * h * u + h ^ 2)]
    · nlinarith [mul_nonneg (sub_nonneg.mpr hw1) (sub_nonneg.mpr hw2), sq_nonneg h, sq_nonneg (h ^ 2)]
  · rw [key]
    have h5 : √5 ^ 2 = 5 := Real.sq_sqrt (by norm_num)
    have hs : ((3 - √5) / 2) ^ 2 - 3 * ((3 - √5) / 2) + 1 = 0 := by linear_combination h5 / 4
    have hP : (x₀ + (3 - √5) / 2 * h - x₀) ^ 2 - 3 * h * (x₀ + (3 - √5) / 2 * h - x₀) + h ^ 2 = 0 := by
      linear_combination h ^ 2 * hs
    rw [hP]
    have : (0 : ℝ) ≤ h ^ 4 := by positivity
    rw [show (0 : ℝ) ^ 2 - h ^ 4 = -(h ^ 4) by ring, abs_neg, abs_of_nonneg this]

/-! The card's whole-number worked examples. -/

-- Four nodes, n = 3: the factorial is 4! = 1 × 2 × 3 × 4 = 24.
example : (4 : ℕ)! = 24 := by decide
-- Dividing by 3! instead of 4! makes the bound four times too loose.
example : (4 : ℕ)! / (3 : ℕ)! = 4 := by decide
-- The pairing trick: with u = s² - 3s, s(s - 3) · (s - 1)(s - 2) = u(u + 2) = (u + 1)² - 1;
-- at u = -1 the product is -1, its smallest value.
example : (-1 : ℚ) * (-1 + 2) = (-1 + 1) ^ 2 - 1 := by norm_num
-- In the middle gap, at s = 3/2, the product s(s - 1)(s - 2)(s - 3) is 9/16 in size.
example : (3 / 2 : ℚ) * (3 / 2 - 1) * (3 / 2 - 2) * (3 / 2 - 3) = 9 / 16 := by norm_num
-- Sizing the table: three cubic pieces of three gaps each store 3 · 3 + 1 = 10 values,
-- 20 degrees apart across 180 degrees.
example : 3 * 3 + 1 = 10 ∧ 180 / (3 * 3) = 20 := by decide

#print axioms interpolation_error_theorem
#print axioms interpolation_error_bound
#print axioms equal_nodes_max_node_polynomial
