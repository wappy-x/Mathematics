-- Covering dimension: the unit square has covering dimension exactly 2, every fine closed cover of it has a point in 3 pieces, and K5 drawn on the moment curve in space has no crossing edges.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Segment
import Mathlib.Data.Set.Card
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.Complex.CoveringMap
import Mathlib.Topology.Homotopy.Lifting
import Mathlib.Topology.Algebra.Order.Floor
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.Data.Int.Interval
import Mathlib.AlgebraicTopology.FundamentalGroupoid.SimplyConnected
import Mathlib.Analysis.Convex.Contractible
import Mathlib.Analysis.Complex.Convex

open Metric Set

/-- The card's fine-cover test, `dim X ≤ n`: for every `ε > 0` some finite closed cover of `X`
has mesh (largest diameter of a piece) below `ε` and order at most `n + 1`, that is, no point of
`X` lies in more than `n + 1` pieces. Mathlib has no covering dimension, so it is spelled out. -/
def CoveringDimLE {α : Type*} [PseudoMetricSpace α] (X : Set α) (n : ℕ) : Prop :=
  ∀ ε > 0, ∃ (m : ℕ) (F : Fin m → Set α), (∀ i, IsClosed (F i)) ∧ (⋃ i, F i) = X ∧
    (∀ i, diam (F i) < ε) ∧ ∀ x ∈ X, {i | x ∈ F i}.ncard ≤ n + 1

/-- The unit square `I² = [0, 1]²` in the Euclidean plane: the panel, scaled. -/
def unitSquare : Set (EuclideanSpace ℝ (Fin 2)) := {x | ∀ j, x j ∈ Icc (0 : ℝ) 1}

section LcdAux

open Complex


theorem lcd_exists_log_of_ne_zero (h : ℂ → ℂ) (hc : Continuous h) (hne : ∀ z, h z ≠ 0) :
    ∃ M : ℂ → ℂ, Continuous M ∧ ∀ z, Complex.exp (M z) = h z := by
  obtain ⟨F, ⟨-, hF⟩, -⟩ := IsCoveringMapOn.existsUnique_continuousMap_lifts
    Complex.isCoveringMapOn_exp ⟨h, hc⟩ (a₀ := 0) (e₀ := Complex.log (h 0))
    (Complex.exp_log (hne 0)) (fun a => hne a)
  exact ⟨F, F.continuous, fun z => congr_fun hF z⟩
#print axioms lcd_exists_log_of_ne_zero

theorem lcd_cos_nonpos_band (y : ℝ) (hy : Real.cos y ≤ 0) :
    ∃ j : ℤ, Real.pi / 2 + 2 * Real.pi * j ≤ y ∧ y ≤ 3 * Real.pi / 2 + 2 * Real.pi * j := by
  have hpi := Real.pi_pos
  set j0 : ℤ := ⌊(y + Real.pi / 2) / (2 * Real.pi)⌋
  have h1 : (j0 : ℝ) ≤ (y + Real.pi / 2) / (2 * Real.pi) := Int.floor_le _
  have h2 : (y + Real.pi / 2) / (2 * Real.pi) < j0 + 1 := Int.lt_floor_add_one _
  rw [le_div_iff₀ (by positivity)] at h1
  rw [div_lt_iff₀ (by positivity)] at h2
  have hc : Real.cos (y - j0 * (2 * Real.pi)) = Real.cos y := Real.cos_sub_int_mul_two_pi y j0
  by_cases hr : y - j0 * (2 * Real.pi) < Real.pi / 2
  · by_cases hr2 : -(Real.pi / 2) < y - j0 * (2 * Real.pi)
    · have := Real.cos_pos_of_mem_Ioo ⟨hr2, hr⟩
      linarith
    · refine ⟨j0 - 1, ?_, ?_⟩ <;> push_cast <;> nlinarith
  · exact ⟨j0, by nlinarith, by nlinarith⟩
#print axioms lcd_cos_nonpos_band

theorem lcd_arg_band (θ : ℝ → ℝ) {u v : ℝ} (huv : u ≤ v) (hθ : ContinuousOn θ (Icc u v)) (φ : ℝ)
    (hcos : ∀ t ∈ Icc u v, Real.cos (θ t - φ) ≤ 0) :
    ∃ k : ℤ, ∀ t ∈ Icc u v, Real.pi / 2 + 2 * Real.pi * k ≤ θ t - φ ∧
      θ t - φ ≤ 3 * Real.pi / 2 + 2 * Real.pi * k := by
  have hpi := Real.pi_pos
  obtain ⟨k, hk1, hk2⟩ := lcd_cos_nonpos_band _ (hcos u ⟨le_rfl, huv⟩)
  refine ⟨k, fun t ht => ?_⟩
  obtain ⟨j, hj1, hj2⟩ := lcd_cos_nonpos_band _ (hcos t ht)
  have hsub : Icc u t ⊆ Icc u v := Icc_subset_Icc le_rfl ht.2
  have hc' : ContinuousOn θ (Icc u t) := hθ.mono hsub
  have hjk : j = k := by
    by_contra hne
    rcases lt_or_gt_of_ne hne with hlt | hgt
    · -- j ≤ k - 1: value 2πk in between
      have hjk' : (j : ℝ) ≤ k - 1 := by exact_mod_cast (show j ≤ k - 1 by omega)
      obtain ⟨t', ht', heq⟩ := intermediate_value_Icc' ht.1 hc'
        (show 2 * Real.pi * k + φ ∈ Icc (θ t) (θ u) by constructor <;> nlinarith)
      have := hcos t' (hsub ht')
      rw [heq, show 2 * Real.pi * k + φ - φ = (k : ℝ) * (2 * Real.pi) by ring,
        Real.cos_int_mul_two_pi] at this
      linarith
    · have hjk' : (k : ℝ) + 1 ≤ j := by exact_mod_cast (show k + 1 ≤ j by omega)
      obtain ⟨t', ht', heq⟩ := intermediate_value_Icc ht.1 hc'
        (show 2 * Real.pi * (k + 1) + φ ∈ Icc (θ u) (θ t) by constructor <;> nlinarith)
      have := hcos t' (hsub ht')
      rw [heq, show 2 * Real.pi * (k + 1) + φ - φ = ((k + 1 : ℤ) : ℝ) * (2 * Real.pi) by
        push_cast; ring, Real.cos_int_mul_two_pi] at this
      linarith
  subst hjk
  exact ⟨hj1, hj2⟩
#print axioms lcd_arg_band

theorem lcd_int_nonpos_of {a : ℤ} {c : ℝ} (hc : c < 1) (h : 2 * Real.pi * (a : ℝ) ≤ 2 * Real.pi * c) :
    a ≤ 0 := by
  have h1 : (a : ℝ) ≤ c := le_of_mul_le_mul_left h (by positivity)
  have h2 : (a : ℝ) < 1 := by linarith
  have : a < 1 := by exact_mod_cast h2
  omega
#print axioms lcd_int_nonpos_of

/-- Poincaré–Miranda in two dimensions. -/
theorem lcd_box_zero (F : ℝ → ℝ → ℂ) (hF : Continuous fun p : ℝ × ℝ => F p.1 p.2)
    {s0 s1 t0 t1 : ℝ} (hs : s0 ≤ s1) (ht : t0 ≤ t1)
    (hL : ∀ t ∈ Icc t0 t1, (F s0 t).re ≤ 0) (hR : ∀ t ∈ Icc t0 t1, 0 ≤ (F s1 t).re)
    (hB : ∀ s ∈ Icc s0 s1, (F s t0).im ≤ 0) (hT : ∀ s ∈ Icc s0 s1, 0 ≤ (F s t1).im) :
    ∃ s ∈ Icc s0 s1, ∃ t ∈ Icc t0 t1, F s t = 0 := by
  by_contra hne
  push Not at hne
  have hpi := Real.pi_pos
  set cs : ℝ → ℝ := fun s => max s0 (min s s1)
  set ct : ℝ → ℝ := fun t => max t0 (min t t1)
  have hcs : ∀ s, cs s ∈ Icc s0 s1 := fun s => ⟨le_max_left _ _, max_le hs (min_le_right _ _)⟩
  have hct : ∀ t, ct t ∈ Icc t0 t1 := fun t => ⟨le_max_left _ _, max_le ht (min_le_right _ _)⟩
  have hcs' : ∀ s ∈ Icc s0 s1, cs s = s := fun s h => by
    simp only [cs]; rw [min_eq_left h.2, max_eq_right h.1]
  have hct' : ∀ t ∈ Icc t0 t1, ct t = t := fun t h => by
    simp only [ct]; rw [min_eq_left h.2, max_eq_right h.1]
  set G : ℂ → ℂ := fun z => F (cs z.re) (ct z.im)
  have hG : Continuous G := by
    have : Continuous fun z : ℂ => (cs z.re, ct z.im) := by
      simp only [cs, ct]; fun_prop
    exact hF.comp this
  obtain ⟨M, hM, hMG⟩ := lcd_exists_log_of_ne_zero G hG (fun z => hne _ (hcs _) _ (hct _))
  set Θ : ℝ → ℝ → ℝ := fun s t => (M (s + t * I)).im
  set P : ℝ → ℝ → ℝ := fun s t => (M (s + t * I)).re
  have key : ∀ s ∈ Icc s0 s1, ∀ t ∈ Icc t0 t1, exp (M (s + t * I)) = F s t := by
    intro s hs t ht
    rw [hMG]; simp only [G]; simp [hcs' s hs, hct' t ht]
  have hre : ∀ s ∈ Icc s0 s1, ∀ t ∈ Icc t0 t1, (F s t).re = Real.exp (P s t) * Real.cos (Θ s t) :=
    fun s hs t ht => by rw [← key s hs t ht, exp_re]
  have him : ∀ s ∈ Icc s0 s1, ∀ t ∈ Icc t0 t1, (F s t).im = Real.exp (P s t) * Real.sin (Θ s t) :=
    fun s hs t ht => by rw [← key s hs t ht, exp_im]
  have hs0 : s0 ∈ Icc s0 s1 := ⟨le_rfl, hs⟩
  have hs1 : s1 ∈ Icc s0 s1 := ⟨hs, le_rfl⟩
  have ht0 : t0 ∈ Icc t0 t1 := ⟨le_rfl, ht⟩
  have ht1 : t1 ∈ Icc t0 t1 := ⟨ht, le_rfl⟩
  have pos : ∀ s t, 0 < Real.exp (P s t) := fun s t => Real.exp_pos _
  -- left edge
  obtain ⟨k1, hk1⟩ := lcd_arg_band (fun t => Θ s0 t) ht (by simp only [Θ]; fun_prop) 0
    (fun t htt => by
      have h := hL t htt; rw [hre s0 hs0 t htt] at h
      rw [sub_zero]; by_contra hc; push Not at hc; nlinarith [pos s0 t])
  obtain ⟨k2, hk2⟩ := lcd_arg_band (fun s => Θ s t0) hs (by simp only [Θ]; fun_prop) (Real.pi / 2)
    (fun s hss => by
      have h := hB s hss; rw [him s hss t0 ht0] at h
      rw [Real.cos_sub_pi_div_two]; by_contra hc; push Not at hc; nlinarith [pos s t0])
  obtain ⟨k3, hk3⟩ := lcd_arg_band (fun t => Θ s1 t) ht (by simp only [Θ]; fun_prop) Real.pi
    (fun t htt => by
      have h := hR t htt; rw [hre s1 hs1 t htt] at h
      rw [Real.cos_sub_pi]; by_contra hc; push Not at hc; nlinarith [pos s1 t])
  obtain ⟨k4, hk4⟩ := lcd_arg_band (fun s => Θ s t1) hs (by simp only [Θ]; fun_prop) (-(Real.pi / 2))
    (fun s hss => by
      have h := hT s hss; rw [him s hss t1 ht1] at h
      rw [sub_neg_eq_add, Real.cos_add_pi_div_two]; by_contra hc; push Not at hc
      nlinarith [pos s t1])
  obtain ⟨a1, a2⟩ := hk1 t0 ht0
  obtain ⟨b1, b2⟩ := hk2 s0 hs0
  obtain ⟨c1, c2⟩ := hk2 s1 hs1
  obtain ⟨d1, d2⟩ := hk3 t0 ht0
  obtain ⟨e1, e2⟩ := hk3 t1 ht1
  obtain ⟨f1, f2⟩ := hk4 s1 hs1
  obtain ⟨g1, g2⟩ := hk4 s0 hs0
  obtain ⟨h1, h2⟩ := hk1 t1 ht1
  -- corner (s0,t0): k1 = k2
  have q1 : k2 - k1 ≤ 0 := lcd_int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q2 : k1 - k2 ≤ 0 := lcd_int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  have q3 : k3 - k2 ≤ 0 := lcd_int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q4 : k2 - k3 ≤ 0 := lcd_int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  have q5 : k4 - k3 - 1 ≤ 0 := lcd_int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q6 : k3 + 1 - k4 ≤ 0 := lcd_int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  have q7 : k1 - k4 ≤ 0 := lcd_int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q8 : k4 - k1 ≤ 0 := lcd_int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  omega
#print axioms lcd_box_zero

end LcdAux

theorem lcd_dist_le (x y : EuclideanSpace ℝ (Fin 2)) : dist x y ≤ |x 0 - y 0| + |x 1 - y 1| := by
  rw [EuclideanSpace.dist_eq, Fin.sum_univ_two, Real.dist_eq, Real.dist_eq]
  calc Real.sqrt (|x 0 - y 0| ^ 2 + |x 1 - y 1| ^ 2)
      ≤ Real.sqrt ((|x 0 - y 0| + |x 1 - y 1|) ^ 2) :=
        Real.sqrt_le_sqrt (by nlinarith [abs_nonneg (x 0 - y 0), abs_nonneg (x 1 - y 1)])
    _ = |x 0 - y 0| + |x 1 - y 1| := Real.sqrt_sq (by positivity)
#print axioms lcd_dist_le

theorem lcd_coord_le_dist (x y : EuclideanSpace ℝ (Fin 2)) (j : Fin 2) :
    |x j - y j| ≤ dist x y := by
  rw [EuclideanSpace.dist_eq]
  apply Real.abs_le_sqrt
  simp only [Real.dist_eq, sq_abs]
  exact Finset.single_le_sum (f := fun i => (x i - y i) ^ 2) (fun i _ => by positivity)
    (Finset.mem_univ j)
#print axioms lcd_coord_le_dist

theorem lcd_square_mem (s t : ℝ) (hs : s ∈ Icc (0 : ℝ) 1) (ht : t ∈ Icc (0 : ℝ) 1) :
    (!₂[s, t] : EuclideanSpace ℝ (Fin 2)) ∈ unitSquare := by
  intro j
  fin_cases j <;> simp [hs, ht]
#print axioms lcd_square_mem

theorem lcd_square_bounded : Bornology.IsBounded unitSquare := by
  refine Metric.isBounded_iff.2 ⟨2, fun x hx y hy => ?_⟩
  have h0 : |x 0 - y 0| ≤ 1 := abs_sub_le_iff.2 ⟨by linarith [(hx 0).1, (hx 0).2, (hy 0).1,
    (hy 0).2], by linarith [(hx 0).1, (hx 0).2, (hy 0).1, (hy 0).2]⟩
  have h1 : |x 1 - y 1| ≤ 1 := abs_sub_le_iff.2 ⟨by linarith [(hx 1).1, (hx 1).2, (hy 1).1,
    (hy 1).2], by linarith [(hx 1).1, (hx 1).2, (hy 1).1, (hy 1).2]⟩
  linarith [lcd_dist_le x y]
#print axioms lcd_square_bounded

/-- Three closed sets covering the square, placed like the corners of a triangle, share a
point (from Poincaré–Miranda). -/
theorem lcd_three (C1 C2 C3 : Set (EuclideanSpace ℝ (Fin 2))) (h1 : IsClosed C1)
    (h2 : IsClosed C2) (h3 : IsClosed C3)
    (hcov : ∀ x ∈ unitSquare, x ∈ C1 ∨ x ∈ C2 ∨ x ∈ C3)
    (hA1 : ∀ x ∈ unitSquare, x 0 = 0 → x ∈ C1) (hB1 : ∀ x ∈ C1, x 0 ≠ 1)
    (hA2 : ∀ x ∈ C3, x 1 ≠ 0) (hB2 : ∀ x ∈ C2, x 1 ≠ 1) :
    ∃ x, x ∈ C1 ∧ x ∈ C2 ∧ x ∈ C3 := by
  by_contra hno
  push Not at hno
  set P : Set (EuclideanSpace ℝ (Fin 2)) := {x | x 1 = 0} ∪ (C1 ∩ C2) with hPdef
  set Q : Set (EuclideanSpace ℝ (Fin 2)) := {x | x 1 = 1} ∪ (C1 ∩ C3) with hQdef
  have hP : IsClosed P := (isClosed_eq (by fun_prop) continuous_const).union (h1.inter h2)
  have hQ : IsClosed Q := (isClosed_eq (by fun_prop) continuous_const).union (h1.inter h3)
  have hPQ : ∀ x, x ∈ P → x ∈ Q → False := by
    intro x hxP hxQ
    rcases hxP with h | ⟨hc1, hc2⟩ <;> rcases hxQ with h' | ⟨hc1', hc3⟩
    · have e1 : x 1 = 0 := h
      have e2 : x 1 = 1 := h'
      rw [e1] at e2; norm_num at e2
    · exact hA2 x hc3 h
    · exact hB2 x hc2 h'
    · exact hno x hc1 hc2 hc3
  have i01 : (0 : ℝ) ∈ Icc (0 : ℝ) 1 := ⟨le_rfl, zero_le_one⟩
  have i11 : (1 : ℝ) ∈ Icc (0 : ℝ) 1 := ⟨zero_le_one, le_rfl⟩
  have hP0 : P.Nonempty := ⟨!₂[0, 0], Or.inl (by simp)⟩
  have hQ0 : Q.Nonempty := ⟨!₂[0, 1], Or.inl (by simp)⟩
  have hC1 : C1.Nonempty := ⟨!₂[0, 0], hA1 _ (lcd_square_mem _ _ i01 i01) (by simp)⟩
  have hR : ∀ t ∈ Icc (0 : ℝ) 1, (!₂[1, t] : EuclideanSpace ℝ (Fin 2)) ∈ C2 ∪ C3 := by
    intro t ht
    rcases hcov _ (lcd_square_mem _ _ i11 ht) with h | h | h
    · exact absurd (by simp) (hB1 _ h)
    · exact Or.inl h
    · exact Or.inr h
  have hC23 : (C2 ∪ C3).Nonempty := ⟨_, hR 0 i01⟩
  set u : EuclideanSpace ℝ (Fin 2) → ℝ := fun z => infDist z C1 - infDist z (C2 ∪ C3) with hu
  set v : EuclideanSpace ℝ (Fin 2) → ℝ := fun z => infDist z P - infDist z Q with hv
  have huc : Continuous u := (continuous_infDist_pt _).sub (continuous_infDist_pt _)
  have hvc : Continuous v := (continuous_infDist_pt _).sub (continuous_infDist_pt _)
  have hpt : Continuous fun p : ℝ × ℝ => (!₂[p.1, p.2] : EuclideanSpace ℝ (Fin 2)) := by
    fun_prop
  set F : ℝ → ℝ → ℂ := fun s t => ((u !₂[s, t] : ℝ) : ℂ) + ((v !₂[s, t] : ℝ) : ℂ) * Complex.I
    with hF
  have hFre : ∀ s t, (F s t).re = u !₂[s, t] := fun s t => by simp [hF]
  have hFim : ∀ s t, (F s t).im = v !₂[s, t] := fun s t => by simp [hF]
  have hFc : Continuous fun p : ℝ × ℝ => F p.1 p.2 :=
    (Complex.continuous_ofReal.comp (huc.comp hpt)).add
      ((Complex.continuous_ofReal.comp (hvc.comp hpt)).mul continuous_const)
  obtain ⟨s, hs, t, ht, hz⟩ := lcd_box_zero F hFc zero_le_one zero_le_one
    (fun t ht => by
      rw [hFre]
      have : (!₂[0, t] : EuclideanSpace ℝ (Fin 2)) ∈ C1 :=
        hA1 _ (lcd_square_mem _ _ i01 ht) (by simp)
      simp only [hu, infDist_zero_of_mem this]
      linarith [infDist_nonneg (x := (!₂[0, t] : EuclideanSpace ℝ (Fin 2))) (s := C2 ∪ C3)])
    (fun t ht => by
      rw [hFre]
      simp only [hu, infDist_zero_of_mem (hR t ht)]
      linarith [infDist_nonneg (x := (!₂[1, t] : EuclideanSpace ℝ (Fin 2))) (s := C1)])
    (fun s hs => by
      rw [hFim]
      have : (!₂[s, 0] : EuclideanSpace ℝ (Fin 2)) ∈ P := Or.inl (by simp)
      simp only [hv, infDist_zero_of_mem this]
      linarith [infDist_nonneg (x := (!₂[s, 0] : EuclideanSpace ℝ (Fin 2))) (s := Q)])
    (fun s hs => by
      rw [hFim]
      have : (!₂[s, 1] : EuclideanSpace ℝ (Fin 2)) ∈ Q := Or.inl (by simp)
      simp only [hv, infDist_zero_of_mem this]
      linarith [infDist_nonneg (x := (!₂[s, 1] : EuclideanSpace ℝ (Fin 2))) (s := P)])
  set z : EuclideanSpace ℝ (Fin 2) := !₂[s, t] with hzdef
  have hu0 : u z = 0 := by rw [← hFre, hz]; simp
  have hv0 : v z = 0 := by rw [← hFim, hz]; simp
  simp only [hu, sub_eq_zero] at hu0
  simp only [hv, sub_eq_zero] at hv0
  have hzC1 : z ∈ C1 ∧ z ∈ C2 ∪ C3 := by
    rcases hcov z (lcd_square_mem _ _ hs ht) with h | h | h
    · refine ⟨h, ?_⟩
      rw [(h2.union h3).mem_iff_infDist_zero hC23, ← hu0, infDist_zero_of_mem h]
    · have h' : z ∈ C2 ∪ C3 := Or.inl h
      refine ⟨?_, h'⟩
      rw [h1.mem_iff_infDist_zero hC1, hu0, infDist_zero_of_mem h']
    · have h' : z ∈ C2 ∪ C3 := Or.inr h
      refine ⟨?_, h'⟩
      rw [h1.mem_iff_infDist_zero hC1, hu0, infDist_zero_of_mem h']
  rcases hzC1 with ⟨hz1, hz2 | hz3⟩
  · have hzP : z ∈ P := Or.inr ⟨hz1, hz2⟩
    have hzQ : z ∈ Q := by
      rw [hQ.mem_iff_infDist_zero hQ0, ← hv0, infDist_zero_of_mem hzP]
    exact hPQ z hzP hzQ
  · have hzQ : z ∈ Q := Or.inr ⟨hz1, hz3⟩
    have hzP : z ∈ P := by
      rw [hP.mem_iff_infDist_zero hP0, hv0, infDist_zero_of_mem hzQ]
    exact hPQ z hzP hzQ
#print axioms lcd_three

/-- The covering theorem itself, proved here so the dimension theorem above it can use it. -/
theorem lcd_lebesgue (m : ℕ) (F : Fin m → Set (EuclideanSpace ℝ (Fin 2)))
    (hclosed : ∀ i, IsClosed (F i)) (hcover : (⋃ i, F i) = unitSquare)
    (hsides : ∀ i, ∀ j : Fin 2, ¬ ((∃ x ∈ F i, x j = 0) ∧ (∃ y ∈ F i, y j = 1))) :
    ∃ x ∈ unitSquare, 3 ≤ {i | x ∈ F i}.ncard := by
  set P1 : Fin m → Prop := fun i => ∃ x ∈ F i, x 0 = 0 with hP1
  set P2 : Fin m → Prop := fun i => ∃ x ∈ F i, x 1 = 0 with hP2
  have hFsub : ∀ i, F i ⊆ unitSquare := fun i => hcover ▸ subset_iUnion F i
  have hin : ∀ x ∈ unitSquare, ∃ i, x ∈ F i := fun x hx => by
    rw [← hcover] at hx; exact mem_iUnion.1 hx
  obtain ⟨x, ⟨hx1, hx2, hx3⟩⟩ := lcd_three (⋃ i ∈ {i | P1 i}, F i)
    (⋃ i ∈ {i | ¬ P1 i ∧ P2 i}, F i) (⋃ i ∈ {i | ¬ P1 i ∧ ¬ P2 i}, F i)
    ((Set.toFinite _).isClosed_biUnion fun i _ => hclosed i)
    ((Set.toFinite _).isClosed_biUnion fun i _ => hclosed i)
    ((Set.toFinite _).isClosed_biUnion fun i _ => hclosed i)
    (fun x hx => by
      obtain ⟨i, hi⟩ := hin x hx
      by_cases a : P1 i
      · exact Or.inl (mem_biUnion a hi)
      · by_cases b : P2 i
        · exact Or.inr (Or.inl (mem_biUnion (show i ∈ {i | ¬ P1 i ∧ P2 i} from ⟨a, b⟩) hi))
        · exact Or.inr (Or.inr (mem_biUnion (show i ∈ {i | ¬ P1 i ∧ ¬ P2 i} from ⟨a, b⟩) hi)))
    (fun x hx h0 => by
      obtain ⟨i, hi⟩ := hin x hx
      exact mem_biUnion (show i ∈ {i | P1 i} from ⟨x, hi, h0⟩) hi)
    (fun x hx h0 => by
      obtain ⟨i, hi, hxi⟩ := mem_iUnion₂.1 hx
      exact hsides i 0 ⟨hi, ⟨x, hxi, h0⟩⟩)
    (fun x hx h0 => by
      obtain ⟨i, hi, hxi⟩ := mem_iUnion₂.1 hx
      exact hi.2 ⟨x, hxi, h0⟩)
    (fun x hx h0 => by
      obtain ⟨i, hi, hxi⟩ := mem_iUnion₂.1 hx
      exact hsides i 1 ⟨hi.2, ⟨x, hxi, h0⟩⟩)
  obtain ⟨i1, hi1, hxi1⟩ := mem_iUnion₂.1 hx1
  obtain ⟨i2, hi2, hxi2⟩ := mem_iUnion₂.1 hx2
  obtain ⟨i3, hi3, hxi3⟩ := mem_iUnion₂.1 hx3
  have h12 : i1 ≠ i2 := fun h => hi2.1 (h ▸ hi1)
  have h13 : i1 ≠ i3 := fun h => hi3.1 (h ▸ hi1)
  have h23 : i2 ≠ i3 := fun h => hi3.2 (h ▸ hi2.2)
  refine ⟨x, hFsub i1 hxi1, ?_⟩
  have h3 : ({i1, i2, i3} : Set (Fin m)).ncard = 3 :=
    Set.ncard_eq_three.2 ⟨i1, i2, i3, h12, h13, h23, rfl⟩
  rw [← h3]
  apply Set.ncard_le_ncard _ (Set.toFinite _)
  intro i hi
  rcases hi with rfl | rfl | rfl
  · exact hxi1
  · exact hxi2
  · exact hxi3
#print axioms lcd_lebesgue

theorem lcd_transfer {α : Type*} [PseudoMetricSpace α] (X : Set α) (n : ℕ) (ε : ℝ) {ι : Type*}
    [Fintype ι] (F : ι → Set α) (hc : ∀ i, IsClosed (F i)) (hu : (⋃ i, F i) = X)
    (hd : ∀ i, diam (F i) < ε) (ho : ∀ x ∈ X, {i | x ∈ F i}.ncard ≤ n + 1) :
    ∃ (m : ℕ) (G : Fin m → Set α), (∀ i, IsClosed (G i)) ∧ (⋃ i, G i) = X ∧
      (∀ i, diam (G i) < ε) ∧ ∀ x ∈ X, {i | x ∈ G i}.ncard ≤ n + 1 := by
  set e := Fintype.equivFin ι
  refine ⟨_, fun i => F (e.symm i), fun i => hc _, ?_, fun i => hd _, ?_⟩
  · rw [← hu]; exact e.symm.surjective.iUnion_comp F
  · intro x hx
    have : {i | x ∈ F (e.symm i)} = e.symm ⁻¹' {i | x ∈ F i} := rfl
    rw [this, Set.ncard_preimage_of_injective_subset_range e.symm.injective (by simp)]
    exact ho x hx
#print axioms lcd_transfer

/-- Offset bricks: for every `ε > 0` a fine closed cover of the square with order at most 3. -/
theorem lcd_upper : CoveringDimLE unitSquare 2 := by
  intro ε hε
  set N : ℕ := ⌈2 / ε⌉₊ + 1 with hNdef
  have hNpos : (0 : ℝ) < N := by positivity
  have hN0 : 0 < N := by omega
  have hNε : 2 / (N : ℝ) < ε := by
    have h1 : 2 / ε < N := by
      have := Nat.le_ceil (2 / ε); rw [hNdef]; push_cast; linarith
    rw [div_lt_iff₀ hNpos]; rw [div_lt_iff₀ hε] at h1; linarith
  refine lcd_transfer unitSquare 2 ε (ι := Fin N × Fin (N + 1))
    (fun p => {x | x ∈ unitSquare ∧ ((p.1 : ℕ) : ℝ) ≤ N * x 1 ∧ N * x 1 ≤ (p.1 : ℕ) + 1 ∧
      2 * ((p.2 : ℕ) : ℝ) - (((p.1 : ℕ) % 2 : ℕ) : ℝ) ≤ 2 * N * x 0 ∧
      2 * N * x 0 ≤ 2 * ((p.2 : ℕ) : ℝ) + 2 - (((p.1 : ℕ) % 2 : ℕ) : ℝ)}) ?_ ?_ ?_ ?_
  · intro p
    have hsq : IsClosed unitSquare := by
      have : unitSquare = ⋂ j : Fin 2, (fun x : EuclideanSpace ℝ (Fin 2) => x j) ⁻¹' Icc 0 1 := by
        ext x; simp [unitSquare]
      rw [this]
      exact isClosed_iInter fun j => isClosed_Icc.preimage (by fun_prop)
    have c0 : Continuous fun x : EuclideanSpace ℝ (Fin 2) => x 0 := by fun_prop
    have c1 : Continuous fun x : EuclideanSpace ℝ (Fin 2) => x 1 := by fun_prop
    exact hsq.inter ((isClosed_le continuous_const (continuous_const.mul c1)).inter
      ((isClosed_le (continuous_const.mul c1) continuous_const).inter
      ((isClosed_le continuous_const (continuous_const.mul c0)).inter
      (isClosed_le (continuous_const.mul c0) continuous_const))))
  · apply Subset.antisymm
    · exact iUnion_subset fun p x hx => hx.1
    · intro x hx
      have hx0 := hx 0
      have hx1 := hx 1
      set k : ℕ := min ⌊(N : ℝ) * x 1⌋₊ (N - 1) with hk
      have hkN : k < N := by omega
      set q : ℝ := ((k % 2 : ℕ) : ℝ) with hq
      have hq0 : 0 ≤ q := by positivity
      have hq1 : q ≤ 1 := by
        have : k % 2 ≤ 1 := by omega
        rw [hq]; exact_mod_cast this
      set j : ℕ := min ⌊(N : ℝ) * x 0 + q / 2⌋₊ N with hj
      have hjN : j < N + 1 := by omega
      refine mem_iUnion.2 ⟨(⟨k, hkN⟩, ⟨j, hjN⟩), hx, ?_, ?_, ?_, ?_⟩
      · have : (k : ℝ) ≤ ⌊(N : ℝ) * x 1⌋₊ := by exact_mod_cast min_le_left _ _
        exact this.trans (Nat.floor_le (by nlinarith [hx1.1]))
      · show (N : ℝ) * x 1 ≤ k + 1
        by_cases h : ⌊(N : ℝ) * x 1⌋₊ ≤ N - 1
        · have : k = ⌊(N : ℝ) * x 1⌋₊ := min_eq_left h
          rw [this]; exact (Nat.lt_floor_add_one _).le
        · have : k + 1 = N := by omega
          have : (k : ℝ) + 1 = N := by exact_mod_cast this
          rw [this]; nlinarith [hx1.2]
      · show 2 * (j : ℝ) - q ≤ 2 * N * x 0
        have : (j : ℝ) ≤ ⌊(N : ℝ) * x 0 + q / 2⌋₊ := by exact_mod_cast min_le_left _ _
        have h2 := Nat.floor_le (show 0 ≤ (N : ℝ) * x 0 + q / 2 by nlinarith [hx0.1])
        linarith
      · show 2 * N * x 0 ≤ 2 * (j : ℝ) + 2 - q
        by_cases h : ⌊(N : ℝ) * x 0 + q / 2⌋₊ ≤ N
        · have : j = ⌊(N : ℝ) * x 0 + q / 2⌋₊ := min_eq_left h
          rw [this]
          have := Nat.lt_floor_add_one ((N : ℝ) * x 0 + q / 2)
          linarith
        · have : j = N := by omega
          rw [this]; nlinarith [hx0.2]
  · intro p
    refine lt_of_le_of_lt ?_ hNε
    refine Metric.diam_le_of_forall_dist_le (by positivity) fun x hx y hy => ?_
    obtain ⟨-, a1, a2, a3, a4⟩ := hx
    obtain ⟨-, b1, b2, b3, b4⟩ := hy
    have e1 : |x 1 - y 1| ≤ 1 / N := by
      rw [le_div_iff₀ hNpos, ← abs_of_pos hNpos, ← abs_mul]
      exact abs_le.2 ⟨by nlinarith, by nlinarith⟩
    have e0 : |x 0 - y 0| ≤ 1 / N := by
      rw [le_div_iff₀ hNpos, ← abs_of_pos hNpos, ← abs_mul]
      exact abs_le.2 ⟨by nlinarith, by nlinarith⟩
    calc dist x y ≤ |x 0 - y 0| + |x 1 - y 1| := lcd_dist_le x y
      _ ≤ 1 / N + 1 / N := add_le_add e0 e1
      _ = 2 / N := by ring
  · intro x hx
    set S := {p : Fin N × Fin (N + 1) | x ∈ {x | x ∈ unitSquare ∧ ((p.1 : ℕ) : ℝ) ≤ N * x 1 ∧
      N * x 1 ≤ (p.1 : ℕ) + 1 ∧ 2 * ((p.2 : ℕ) : ℝ) - (((p.1 : ℕ) % 2 : ℕ) : ℝ) ≤ 2 * N * x 0 ∧
      2 * N * x 0 ≤ 2 * ((p.2 : ℕ) : ℝ) + 2 - (((p.1 : ℕ) % 2 : ℕ) : ℝ)}} with hS
    classical
    rw [Set.ncard_eq_toFinset_card']
    set f : Fin N × Fin (N + 1) → ℤ := fun p => 2 * ((p.2 : ℕ) : ℤ) - (((p.1 : ℕ) % 2 : ℕ) : ℤ)
      with hf
    set w : ℤ := ⌈2 * (N : ℝ) * x 0⌉ - 2 with hw
    have hcard : (Finset.Icc w (w + 2)).card = 3 := by
      rw [Int.card_Icc]; omega
    show S.toFinset.card ≤ 3
    rw [← hcard]
    refine Finset.card_le_card_of_injOn f ?_ ?_
    · intro p hp
      have hp' : p ∈ S := by simpa using hp
      obtain ⟨-, -, -, c3, c4⟩ := hp'
      have hfr : ((f p : ℤ) : ℝ) = 2 * ((p.2 : ℕ) : ℝ) - (((p.1 : ℕ) % 2 : ℕ) : ℝ) := by
        simp only [hf, Int.cast_sub, Int.cast_mul, Int.cast_ofNat, Int.cast_natCast]
      rw [Finset.mem_coe, Finset.mem_Icc]
      constructor
      · have : ⌈2 * (N : ℝ) * x 0⌉ ≤ f p + 2 := by
          rw [Int.ceil_le]; push_cast; rw [hfr]; linarith
        omega
      · have h1 : ((f p : ℤ) : ℝ) ≤ ⌈2 * (N : ℝ) * x 0⌉ := by
          rw [hfr]; exact c3.trans (Int.le_ceil _)
        have : f p ≤ ⌈2 * (N : ℝ) * x 0⌉ := by exact_mod_cast h1
        omega
    · intro p hp p' hp' hpp
      have hp1 : p ∈ S := by simpa using hp
      have hp1' : p' ∈ S := by simpa using hp'
      obtain ⟨-, c1, c2, -, -⟩ := hp1
      obtain ⟨-, d1, d2, -, -⟩ := hp1'
      have k1 : ((p.1 : ℕ) : ℝ) ≤ ((p'.1 : ℕ) + 1 : ℕ) := by push_cast; linarith
      have k2 : ((p'.1 : ℕ) : ℝ) ≤ ((p.1 : ℕ) + 1 : ℕ) := by push_cast; linarith
      have k1' : (p.1 : ℕ) ≤ (p'.1 : ℕ) + 1 := by exact_mod_cast k1
      have k2' : (p'.1 : ℕ) ≤ (p.1 : ℕ) + 1 := by exact_mod_cast k2
      simp only [hf] at hpp
      have e1 : (p.1 : ℕ) = p'.1 := by omega
      have e2 : (p.2 : ℕ) = p'.2 := by omega
      exact Prod.ext (Fin.ext e1) (Fin.ext e2)
#print axioms lcd_upper

/-- The square has covering dimension exactly 2: it can be cut into closed pieces as finely as
wished with no point in more than 3 of them (offset bricks), but not with no point in more than 2
(Lebesgue's covering theorem, from Brouwer). -/
theorem square_covering_dimension_eq_two :
    CoveringDimLE unitSquare 2 ∧ ¬ CoveringDimLE unitSquare 1 := by
  exact ⟨lcd_upper, fun h => by
    obtain ⟨m, F, hc, hu, hd, ho⟩ := h 1 one_pos
    have hFsub : ∀ i, F i ⊆ unitSquare := fun i => hu ▸ subset_iUnion F i
    obtain ⟨x, hx, h3⟩ := lcd_lebesgue m F hc hu (by
      rintro i j ⟨⟨x, hx, hx0⟩, ⟨y, hy, hy1⟩⟩
      have hb := lcd_square_bounded.subset (hFsub i)
      have := lt_of_le_of_lt (lcd_coord_le_dist x y j)
        ((Metric.dist_le_diam_of_mem hb hx hy).trans_lt (hd i))
      rw [hx0, hy1] at this; norm_num at this)
    have := ho x hx
    omega⟩

/-- Lebesgue's covering theorem for the square: in every finite closed cover of the square in
which no piece meets two opposite sides, some point of the square lies in at least 3 pieces. -/
theorem lebesgue_covering_theorem_square (m : ℕ) (F : Fin m → Set (EuclideanSpace ℝ (Fin 2)))
    (hclosed : ∀ i, IsClosed (F i)) (hcover : (⋃ i, F i) = unitSquare)
    (hsides : ∀ i, ∀ j : Fin 2, ¬ ((∃ x ∈ F i, x j = 0) ∧ (∃ y ∈ F i, y j = 1))) :
    ∃ x ∈ unitSquare, 3 ≤ {i | x ∈ F i}.ncard := by
  exact lcd_lebesgue m F hclosed hcover hsides

/-- The point at `t` on the moment curve `(t, t², t³)` in space. -/
def momentCurve (t : ℝ) : Fin 3 → ℝ := ![t, t ^ 2, t ^ 3]

/-- A graph embeds in space with straight edges: put vertex `t` at `(t, t², t³)`. Two edges with
four different ends never meet, since no four points of the moment curve lie in one plane. -/
theorem moment_curve_disjoint_edges_never_meet (a b c d : ℝ) (hab : a ≠ b) (hac : a ≠ c)
    (had : a ≠ d) (hbc : b ≠ c) (hbd : b ≠ d) (hcd : c ≠ d) :
    segment ℝ (momentCurve a) (momentCurve b) ∩ segment ℝ (momentCurve c) (momentCurve d) = ∅ := by
  ext z
  simp only [mem_inter_iff, mem_empty_iff_false, iff_false, not_and]
  rintro ⟨α, β, hα, hβ, hαβ, rfl⟩ ⟨γ, δ, hγ, hδ, hγδ, h⟩
  have e1 := congrFun h 0
  have e2 := congrFun h 1
  have e3 := congrFun h 2
  simp [momentCurve] at e1 e2 e3
  have hA : α * ((a - b) * (a - c) * (a - d)) = 0 := by
    linear_combination (-1 : ℝ) * e3 + (b + c + d) * e2 - (b * c + b * d + c * d) * e1
      + b * c * d * (hγδ - hαβ)
  have hB : β * ((b - a) * (b - c) * (b - d)) = 0 := by
    linear_combination (-1 : ℝ) * e3 + (a + c + d) * e2 - (a * c + a * d + c * d) * e1
      + a * c * d * (hγδ - hαβ)
  have ha : α = 0 := by
    rcases mul_eq_zero.1 hA with h | h
    · exact h
    · exfalso; simp [sub_eq_zero, hab, hac, had] at h
  have hb : β = 0 := by
    rcases mul_eq_zero.1 hB with h | h
    · exact h
    · exfalso; simp [sub_eq_zero, hab.symm, hbc, hbd] at h
  rw [ha, hb] at hαβ; norm_num at hαβ

/-! The card's whole-number worked examples. -/

/-- A closed box `[x₀, x₁] × [y₀, y₁]`, in eighths of the panel's side. -/
def boxCount (boxes : List (ℕ × ℕ × ℕ × ℕ)) (x y : ℕ) : ℕ :=
  (boxes.filter fun r => decide (r.1 ≤ x ∧ x ≤ r.2.1 ∧ r.2.2.1 ≤ y ∧ y ≤ r.2.2.2)).length

/-- Stretcher bond: 4 courses of blocks half the panel wide and a quarter high; odd courses start
half a block in, so they hold a half, a whole and a half block. -/
def stretcherBond : List (ℕ × ℕ × ℕ × ℕ) :=
  [(0, 4, 0, 2), (4, 8, 0, 2), (0, 2, 2, 4), (2, 6, 2, 4), (6, 8, 2, 4),
   (0, 4, 4, 6), (4, 8, 4, 6), (0, 2, 6, 8), (2, 6, 6, 8), (6, 8, 6, 8)]

/-- Square tiles a quarter of the panel on a side, joints running straight through. -/
def stackBond : List (ℕ × ℕ × ℕ × ℕ) :=
  (List.range 4).flatMap fun i => (List.range 4).map fun j => (2 * i, 2 * i + 2, 2 * j, 2 * j + 2)

/-- Every point of the scan: each cut line and the middle of each cell, in eighths of the side. -/
def scan (boxes : List (ℕ × ℕ × ℕ × ℕ)) : List ℕ :=
  (List.range 9).flatMap fun x => (List.range 9).map fun y => boxCount boxes x y

-- blocks per course [2, 3, 2, 3]: 10 blocks
example : stretcherBond.length = 2 + 3 + 2 + 3 := by decide
-- stretcher bond has order 3, at exactly 9 points; the tiles have order 4, at 9 corners
example : (scan stretcherBond).all (· ≤ 3) = true := by decide
example : (scan stretcherBond).count 3 = 9 := by decide
example : stackBond.length = 16 := by decide
example : (scan stackBond).all (· ≤ 4) = true := by decide
example : (scan stackBond).count 4 = 3 * 3 := by decide
-- the cube: 3 in a layer + 1 in the next, against 3 + 3 when layers stack straight
example : (3 + 1 : ℕ) = 4 ∧ (3 + 3 : ℕ) = 6 := by norm_num
-- Cantor set, round 5: 2^5 = 32 pieces, each 1/3^5 = 1/243 long
example : (2 : ℕ) ^ 5 = 32 ∧ (3 : ℕ) ^ 5 = 243 := by norm_num
-- K5 on the moment curve, vertices 1, 2, 3, 4: the determinant of differences is 12,
-- the Vandermonde product of the six differences
example : Matrix.det !![(2 : ℤ) - 1, 2 ^ 2 - 1 ^ 2, 2 ^ 3 - 1 ^ 3;
    3 - 1, 3 ^ 2 - 1 ^ 2, 3 ^ 3 - 1 ^ 3; 4 - 1, 4 ^ 2 - 1 ^ 2, 4 ^ 3 - 1 ^ 3] = 12 := by
  norm_num [Matrix.det_fin_three]
example : ((2 - 1) * (3 - 1) * (4 - 1) * (3 - 2) * (4 - 2) * (4 - 3) : ℤ) = 12 := by norm_num
-- a graph embeds in R^(2 x 1 + 1) = R^3; K5 has 10 edges, a flat drawing allows 3 x 5 - 6 = 9
example : 2 * 1 + 1 = 3 := by norm_num
example : Nat.choose 5 2 = 10 ∧ 3 * 5 - 6 = 9 ∧ 3 * 5 - 6 < Nat.choose 5 2 := by decide

#print axioms square_covering_dimension_eq_two
#print axioms lebesgue_covering_theorem_square
#print axioms moment_curve_disjoint_edges_never_meet
