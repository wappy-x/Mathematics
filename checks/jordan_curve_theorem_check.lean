-- Jordan curve theorem: a simple closed curve in the plane leaves exactly two open connected pieces, one bounded and one unbounded, each with the whole curve as its boundary, and an arc leaves one piece.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.UnitInterval
import Mathlib.Topology.Connected.Basic
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Analysis.Complex.Convex
import Mathlib.Analysis.Complex.CoveringMap
import Mathlib.AlgebraicTopology.FundamentalGroupoid.SimplyConnected
import Mathlib.Analysis.Convex.Contractible
import Mathlib.Topology.TietzeExtension
import Mathlib.Topology.Homotopy.Lifting
import Mathlib.Topology.Algebra.Order.Floor

namespace JordanAux

open Set Complex

theorem exists_log_of_ne_zero (h : ℂ → ℂ) (hc : Continuous h) (hne : ∀ z, h z ≠ 0) :
    ∃ M : ℂ → ℂ, Continuous M ∧ ∀ z, Complex.exp (M z) = h z := by
  obtain ⟨F, ⟨-, hF⟩, -⟩ := IsCoveringMapOn.existsUnique_continuousMap_lifts
    Complex.isCoveringMapOn_exp ⟨h, hc⟩ (a₀ := 0) (e₀ := Complex.log (h 0))
    (Complex.exp_log (hne 0)) (fun a => hne a)
  exact ⟨F, F.continuous, fun z => congr_fun hF z⟩

theorem cos_nonpos_band (y : ℝ) (hy : Real.cos y ≤ 0) :
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

theorem arg_band (θ : ℝ → ℝ) {u v : ℝ} (huv : u ≤ v) (hθ : ContinuousOn θ (Icc u v)) (φ : ℝ)
    (hcos : ∀ t ∈ Icc u v, Real.cos (θ t - φ) ≤ 0) :
    ∃ k : ℤ, ∀ t ∈ Icc u v, Real.pi / 2 + 2 * Real.pi * k ≤ θ t - φ ∧
      θ t - φ ≤ 3 * Real.pi / 2 + 2 * Real.pi * k := by
  have hpi := Real.pi_pos
  obtain ⟨k, hk1, hk2⟩ := cos_nonpos_band _ (hcos u ⟨le_rfl, huv⟩)
  refine ⟨k, fun t ht => ?_⟩
  obtain ⟨j, hj1, hj2⟩ := cos_nonpos_band _ (hcos t ht)
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

theorem int_nonpos_of {a : ℤ} {c : ℝ} (hc : c < 1) (h : 2 * Real.pi * (a : ℝ) ≤ 2 * Real.pi * c) :
    a ≤ 0 := by
  have h1 : (a : ℝ) ≤ c := le_of_mul_le_mul_left h (by positivity)
  have h2 : (a : ℝ) < 1 := by linarith
  have : a < 1 := by exact_mod_cast h2
  omega

/-- Poincaré–Miranda in two dimensions. -/
theorem box_zero (F : ℝ → ℝ → ℂ) (hF : Continuous fun p : ℝ × ℝ => F p.1 p.2)
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
  obtain ⟨M, hM, hMG⟩ := exists_log_of_ne_zero G hG (fun z => hne _ (hcs _) _ (hct _))
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
  obtain ⟨k1, hk1⟩ := arg_band (fun t => Θ s0 t) ht (by simp only [Θ]; fun_prop) 0
    (fun t htt => by
      have h := hL t htt; rw [hre s0 hs0 t htt] at h
      rw [sub_zero]; by_contra hc; push Not at hc; nlinarith [pos s0 t])
  obtain ⟨k2, hk2⟩ := arg_band (fun s => Θ s t0) hs (by simp only [Θ]; fun_prop) (Real.pi / 2)
    (fun s hss => by
      have h := hB s hss; rw [him s hss t0 ht0] at h
      rw [Real.cos_sub_pi_div_two]; by_contra hc; push Not at hc; nlinarith [pos s t0])
  obtain ⟨k3, hk3⟩ := arg_band (fun t => Θ s1 t) ht (by simp only [Θ]; fun_prop) Real.pi
    (fun t htt => by
      have h := hR t htt; rw [hre s1 hs1 t htt] at h
      rw [Real.cos_sub_pi]; by_contra hc; push Not at hc; nlinarith [pos s1 t])
  obtain ⟨k4, hk4⟩ := arg_band (fun s => Θ s t1) hs (by simp only [Θ]; fun_prop) (-(Real.pi / 2))
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
  have q1 : k2 - k1 ≤ 0 := int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q2 : k1 - k2 ≤ 0 := int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  have q3 : k3 - k2 ≤ 0 := int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q4 : k2 - k3 ≤ 0 := int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  have q5 : k4 - k3 - 1 ≤ 0 := int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q6 : k3 + 1 - k4 ≤ 0 := int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  have q7 : k1 - k4 ≤ 0 := int_nonpos_of (c := 1/4) (by norm_num) (by push_cast; linarith)
  have q8 : k4 - k1 ≤ 0 := int_nonpos_of (c := 3/4) (by norm_num) (by push_cast; linarith)
  omega

theorem ray_left_closed (a : ℂ) : IsClosed {z : ℂ | ∃ t : ℝ, 0 ≤ t ∧ z = a - t} := by
  have : {z : ℂ | ∃ t : ℝ, 0 ≤ t ∧ z = a - t} = {z | z.im = a.im} ∩ {z | z.re ≤ a.re} := by
    ext z; simp only [mem_ofPred_eq, mem_inter_iff]; constructor
    · rintro ⟨t, ht, rfl⟩; simp; linarith
    · rintro ⟨h1, h2⟩; exact ⟨a.re - z.re, by linarith, Complex.ext (by simp) (by simp [h1])⟩
  rw [this]
  exact (isClosed_eq Complex.continuous_im continuous_const).inter
    (isClosed_le Complex.continuous_re continuous_const)

theorem ray_right_closed (a : ℂ) : IsClosed {z : ℂ | ∃ t : ℝ, 0 ≤ t ∧ z = a + t} := by
  have : {z : ℂ | ∃ t : ℝ, 0 ≤ t ∧ z = a + t} = {z | z.im = a.im} ∩ {z | a.re ≤ z.re} := by
    ext z; simp only [mem_ofPred_eq, mem_inter_iff]; constructor
    · rintro ⟨t, ht, rfl⟩; simp; linarith
    · rintro ⟨h1, h2⟩; exact ⟨z.re - a.re, by linarith, Complex.ext (by simp) (by simp [h1])⟩
  rw [this]
  exact (isClosed_eq Complex.continuous_im continuous_const).inter
    (isClosed_le continuous_const Complex.continuous_re)

/-- A barrier made of a path in a horizontal band, with horizontal rays out of its two ends,
cannot be crossed by a connected set from above the band to below it. -/
theorem sep_barrier (α : ℝ → ℂ) (hα : Continuous α) (K : ℝ)
    (hK : ∀ s ∈ Icc (0:ℝ) 1, |(α s).im| ≤ K) (C : Set ℂ) (hC : IsPreconnected C)
    (hCB : ∀ z ∈ C, z ∉ α '' Icc 0 1 ∧ (∀ t : ℝ, 0 ≤ t → z ≠ α 0 - t) ∧
      (∀ t : ℝ, 0 ≤ t → z ≠ α 1 + t))
    {x y : ℂ} (hx : x ∈ C) (hy : y ∈ C) (hxK : K < x.im) (hyK : y.im < -K) : False := by
  set B : Set ℂ := α '' Icc 0 1 ∪ {z | ∃ t : ℝ, 0 ≤ t ∧ z = α 0 - t} ∪
    {z | ∃ t : ℝ, 0 ≤ t ∧ z = α 1 + t} with hB_def
  have hBc : IsClosed B :=
    ((isCompact_Icc.image hα).isClosed.union (ray_left_closed _)).union (ray_right_closed _)
  have hCO : C ⊆ Bᶜ := by
    intro z hz hzB
    obtain ⟨h1, h2, h3⟩ := hCB z hz
    rcases hzB with (h | ⟨t, ht, rfl⟩) | ⟨t, ht, rfl⟩
    · exact h1 h
    · exact h2 t ht rfl
    · exact h3 t ht rfl
  set O := connectedComponentIn Bᶜ x
  have hOo : IsOpen O := hBc.isOpen_compl.connectedComponentIn
  have hxO : x ∈ Bᶜ := hCO hx
  have hCsub : C ⊆ O := hC.subset_connectedComponentIn hx hCO
  have hOpc : IsPathConnected O :=
    (hOo.isConnected_iff_isPathConnected).1 (isConnected_connectedComponentIn_iff.2 hxO)
  have hj := hOpc.joinedIn x (hCsub hx) y (hCsub hy)
  set γ := hj.somePath
  set β : ℝ → ℂ := ⇑γ.extend
  have hβc : Continuous β := γ.extend.continuous
  have hβO : ∀ t ∈ Icc (0:ℝ) 1, β t ∈ O := fun t ht => by
    simp only [β]; rw [Path.extend_apply γ ht]; exact hj.somePath_mem _
  obtain ⟨R, hR⟩ := isCompact_Icc.exists_bound_of_continuousOn hβc.continuousOn
  have hR0 : 0 ≤ R := le_trans (norm_nonneg _) (hR 0 ⟨le_rfl, zero_le_one⟩)
  set N : ℝ := R + ‖α 0‖ + ‖α 1‖ + 1
  set cl : ℝ → ℝ := fun s => max 0 (min s 1)
  set αh : ℝ → ℂ := fun s => α (cl s) + (((s - cl s) * N : ℝ) : ℂ)
  have hcl : ∀ s, cl s ∈ Icc (0:ℝ) 1 :=
    fun s => ⟨le_max_left _ _, max_le zero_le_one (min_le_right _ _)⟩
  have hβ0 : β 0 = x := γ.extend_zero
  have hβ1 : β 1 = y := γ.extend_one
  have cm1 : cl (-1) = 0 := by norm_num [cl]
  have c2 : cl 2 = 1 := by norm_num [cl]
  have eL : ∀ t ∈ Icc (0:ℝ) 1, (αh (-1) - β t).re ≤ 0 := by
    intro t ht
    have h1 := hR t ht
    have h2 := Complex.abs_re_le_norm (β t)
    have h3 := Complex.abs_re_le_norm (α 0)
    have h4 := norm_nonneg (α 1)
    simp only [αh, cm1, sub_re, add_re, ofReal_re]
    rw [abs_le] at h2 h3
    nlinarith
  have eR : ∀ t ∈ Icc (0:ℝ) 1, 0 ≤ (αh 2 - β t).re := by
    intro t ht
    have h1 := hR t ht
    have h2 := Complex.abs_re_le_norm (β t)
    have h3 := Complex.abs_re_le_norm (α 1)
    have h4 := norm_nonneg (α 0)
    simp only [αh, c2, sub_re, add_re, ofReal_re]
    rw [abs_le] at h2 h3
    nlinarith
  have eB : ∀ s ∈ Icc (-1:ℝ) 2, (αh s - β 0).im ≤ 0 := by
    intro s hs
    have := hK _ (hcl s)
    rw [abs_le] at this
    simp only [αh, hβ0, sub_im, add_im, ofReal_im]
    linarith
  have eT : ∀ s ∈ Icc (-1:ℝ) 2, 0 ≤ (αh s - β 1).im := by
    intro s hs
    have := hK _ (hcl s)
    rw [abs_le] at this
    simp only [αh, hβ1, sub_im, add_im, ofReal_im]
    linarith
  obtain ⟨s, hs, t, ht, hst⟩ := box_zero (fun s t => αh s - β t)
    (by simp only [αh, cl]; fun_prop)
    (show (-1:ℝ) ≤ 2 by norm_num) (show (0:ℝ) ≤ 1 by norm_num) eL eR eB eT
  have hβB : β t ∈ Bᶜ := connectedComponentIn_subset _ _ (hβO t ht)
  apply hβB
  rw [← sub_eq_zero.1 hst]
  rcases lt_or_ge s 0 with h0 | h0
  · have : cl s = 0 := by simp only [cl]; rw [min_eq_left (by linarith), max_eq_left h0.le]
    refine Or.inl (Or.inr ⟨-(s * N), ?_, ?_⟩)
    · have : 0 ≤ N := by positivity
      nlinarith
    · simp only [αh, this]; push_cast; ring
  rcases le_or_gt s 1 with h1 | h1
  · have : cl s = s := by simp only [cl]; rw [min_eq_left h1, max_eq_right h0]
    refine Or.inl (Or.inl ⟨s, ⟨h0, h1⟩, ?_⟩)
    simp only [αh, this]; simp
  · have : cl s = 1 := by simp only [cl]; rw [min_eq_right h1.le, max_eq_right zero_le_one]
    refine Or.inr ⟨(s - 1) * N, ?_, ?_⟩
    · have : 0 ≤ N := by positivity
      nlinarith
    · simp only [αh, this]

theorem no_log_on_circle (M : ℂ → ℂ) (hM : Continuous M) (x : ℂ) (R : ℝ) (hR : 0 < R)
    (h : ∀ z, ‖z - x‖ = R → Complex.exp (M z) = z - x) : False := by
  set c : ℝ → ℂ := fun θ => x + (R : ℂ) * exp (θ * I) with hc_def
  have hcx : ∀ θ : ℝ, c θ - x = (R : ℂ) * exp (θ * I) := fun θ => by simp [c]
  have hcn : ∀ θ : ℝ, ‖c θ - x‖ = R := fun θ => by
    rw [hcx, norm_mul, norm_exp_ofReal_mul_I, Complex.norm_real, Real.norm_of_nonneg hR.le, mul_one]
  set k : ℝ → ℂ := fun θ => M (c θ) - ((Real.log R : ℂ) + θ * I) with hk_def
  have hk1 : ∀ θ : ℝ, exp (k θ) = 1 := fun θ => by
    simp only [k]
    rw [exp_sub, h _ (hcn θ), hcx, exp_add, ← ofReal_exp, Real.exp_log hR]
    exact div_self (mul_ne_zero (by exact_mod_cast hR.ne') (exp_ne_zero _))
  have hkn : ∀ θ : ℝ, ∃ n : ℤ, k θ = n * (2 * Real.pi * I) := fun θ => exp_eq_one_iff.1 (hk1 θ)
  have hkc : Continuous k := by
    simp only [k, c]; fun_prop
  set u : ℝ → ℝ := fun θ => (k θ).im / (2 * Real.pi) with hu_def
  have hu : Continuous u := by fun_prop
  have hun : ∀ θ, ∃ n : ℤ, u θ = n := fun θ => by
    obtain ⟨n, hn⟩ := hkn θ
    refine ⟨n, ?_⟩
    simp only [u, hn]
    simp [Real.pi_ne_zero]
  have hc2 : c (2 * Real.pi) = c 0 := by
    simp only [c]
    push_cast
    rw [exp_two_pi_mul_I]; simp
  have hu2 : u (2 * Real.pi) = u 0 - 1 := by
    simp only [u, k, hc2]
    field_simp
    simp
  obtain ⟨θ, -, hθ⟩ := intermediate_value_Icc' (by positivity : (0:ℝ) ≤ 2 * Real.pi)
    hu.continuousOn (show u 0 - 1/2 ∈ Icc (u (2*Real.pi)) (u 0) by
      rw [hu2]; constructor <;> linarith)
  obtain ⟨n0, hn0⟩ := hun 0
  obtain ⟨n1, hn1⟩ := hun θ
  have h3 : ((2 * n1 : ℤ) : ℝ) = ((2 * n0 - 1 : ℤ) : ℝ) := by push_cast; linarith
  have : (2 * n1 : ℤ) = 2 * n0 - 1 := by exact_mod_cast h3
  omega

theorem mem_comp_of_mem_closure {O : Set ℂ} (hO : IsOpen O) {x y : ℂ}
    (hy : y ∈ closure (connectedComponentIn O x)) (hyO : y ∈ O) :
    y ∈ connectedComponentIn O x := by
  obtain ⟨z, hz1, hz2⟩ :=
    mem_closure_iff.1 hy _ hO.connectedComponentIn (mem_connectedComponentIn hyO)
  rw [connectedComponentIn_eq hz2, ← connectedComponentIn_eq hz1]
  exact mem_connectedComponentIn hyO

theorem frontier_comp_subset {O : Set ℂ} (hO : IsOpen O) (x : ℂ) :
    frontier (connectedComponentIn O x) ⊆ Oᶜ := by
  intro y hy hyO
  have h1 := mem_comp_of_mem_closure hO hy.1 hyO
  exact hy.2 (hO.connectedComponentIn.interior_eq.symm ▸ h1)

theorem isPreconnected_norm_gt (R : ℝ) : IsPreconnected {z : ℂ | R < ‖z‖} := by
  have : {z : ℂ | R < ‖z‖} =
      (fun p : ℝ × ℝ => (p.1 : ℂ) * exp (p.2 * I)) '' (Ioi R ×ˢ univ) := by
    ext z; constructor
    · intro hz; exact ⟨(‖z‖, arg z), ⟨hz, trivial⟩, by simpa using norm_mul_exp_arg_mul_I z⟩
    · rintro ⟨⟨r, θ⟩, ⟨hr, -⟩, rfl⟩
      show R < ‖(r : ℂ) * exp (θ * I)‖
      rw [norm_mul, norm_exp_ofReal_mul_I, mul_one, Complex.norm_real, Real.norm_eq_abs]
      exact lt_of_lt_of_le hr (le_abs_self r)
  rw [this]
  exact (isPreconnected_Ioi.prod isPreconnected_univ).image _ (by fun_prop)

theorem comp_eq_far {K : Set ℂ} {R0 : ℝ} (hK : ∀ z ∈ K, ‖z‖ ≤ R0) {y : ℂ}
    (hub : ¬ Bornology.IsBounded (connectedComponentIn Kᶜ y)) :
    connectedComponentIn Kᶜ y = connectedComponentIn Kᶜ ((R0 + 1 : ℝ) : ℂ) := by
  have hE : {z : ℂ | R0 < ‖z‖} ⊆ Kᶜ := fun z hz hzK => by
    have := hK z hzK; have : R0 < ‖z‖ := hz; linarith
  obtain ⟨w, hw, hwR⟩ : ∃ w ∈ connectedComponentIn Kᶜ y, R0 < ‖w‖ := by
    by_contra h; push Not at h
    exact hub ((Metric.isBounded_closedBall (x := (0:ℂ)) (r := R0)).subset
      (fun w hw => by simpa using h w hw))
  have hfar : ((R0 + 1 : ℝ) : ℂ) ∈ {z : ℂ | R0 < ‖z‖} := by
    show R0 < ‖((R0 + 1 : ℝ) : ℂ)‖
    rw [Complex.norm_real, Real.norm_eq_abs]
    exact lt_of_lt_of_le (by linarith) (le_abs_self _)
  have := (isPreconnected_norm_gt R0).subset_connectedComponentIn hwR hE
  rw [connectedComponentIn_eq hw]
  exact connectedComponentIn_eq (this hfar)

/-- Borsuk's argument for an arc: no component of its complement is bounded. -/
theorem arc_comp_unbounded (f : ℝ → ℂ) (hf : Continuous f) {c d : ℝ} (hcd : c ≤ d)
    (hinj : InjOn f (Icc c d)) {x : ℂ} (hx : x ∉ f '' Icc c d) :
    ¬ Bornology.IsBounded (connectedComponentIn (f '' Icc c d)ᶜ x) := by
  classical
  set K := f '' Icc c d with hK_def
  have hKc : IsCompact K := isCompact_Icc.image hf
  let e0 : Icc c d → K := fun t => ⟨f t, mem_image_of_mem f t.2⟩
  have he0c : Continuous e0 := by fun_prop
  have he0b : Function.Bijective e0 := by
    constructor
    · intro s t hst; exact Subtype.ext (hinj s.2 t.2 (congrArg Subtype.val hst))
    · rintro ⟨z, t, ht, rfl⟩; exact ⟨⟨t, ht⟩, rfl⟩
  let e := he0c.homeoOfEquivCompactToT2 (f := Equiv.ofBijective e0 he0b)
  let σ : C(K, ℝ) := ⟨fun z => (e.symm z : ℝ), continuous_subtype_val.comp e.symm.continuous⟩
  obtain ⟨g, hgI, hgK⟩ := ContinuousMap.exists_restrict_eq_forall_mem_of_closed σ (t := Icc c d)
    (fun z => (e.symm z).2) (nonempty_Icc.2 hcd) hKc.isClosed
  have hfg : ∀ z ∈ K, f (g z) = z := by
    intro z hz
    have h1 : g z = σ ⟨z, hz⟩ := by rw [← hgK]; rfl
    rw [h1]
    have h2 : e (e.symm ⟨z, hz⟩) = ⟨z, hz⟩ := e.apply_symm_apply _
    exact congrArg Subtype.val h2
  intro hU
  set U := connectedComponentIn Kᶜ x
  have hxU : x ∈ U := mem_connectedComponentIn hx
  have hfr : frontier U ⊆ K := fun z hz => by
    simpa using frontier_comp_subset hKc.isClosed.isOpen_compl x hz
  set h : ℂ → ℂ := fun z => if z ∈ U then f (g z) - x else z - x
  have hc : Continuous h := by
    apply Continuous.if
    · intro a ha; rw [Set.setOf_mem_eq] at ha; rw [hfg a (hfr ha)]
    · exact (hf.comp g.continuous).sub continuous_const
    · fun_prop
  have hne : ∀ z, h z ≠ 0 := by
    intro z; simp only [h]; split_ifs with hz
    · rw [sub_ne_zero]; intro heq; exact hx (heq ▸ mem_image_of_mem f (hgI z))
    · rw [sub_ne_zero]; rintro rfl; exact hz hxU
  obtain ⟨M, hM, hMh⟩ := exists_log_of_ne_zero h hc hne
  obtain ⟨r, hr⟩ := hU.subset_closedBall x
  apply no_log_on_circle M hM x (max r 0 + 1) (by positivity)
  intro z hz
  have hzU : z ∉ U := fun hzU => by
    have := hr hzU; rw [Metric.mem_closedBall, dist_eq_norm] at this
    linarith [le_max_left r 0]
  rw [hMh]; simp only [h, if_neg hzU]

/-- An arc does not separate the plane (complex-plane version). -/
theorem arc_compl_isConnected (f : ℝ → ℂ) (hf : Continuous f) {c d : ℝ} (hcd : c ≤ d)
    (hinj : InjOn f (Icc c d)) : IsConnected (f '' Icc c d)ᶜ := by
  set K := f '' Icc c d
  have hKc : IsCompact K := isCompact_Icc.image hf
  obtain ⟨R0, hR0⟩ := hKc.isBounded.subset_closedBall 0
  have hK : ∀ z ∈ K, ‖z‖ ≤ R0 := fun z hz => by simpa using hR0 hz
  set far : ℂ := ((R0 + 1 : ℝ) : ℂ)
  have hfar : far ∉ K := fun h => by
    have h1 := hK _ h
    rw [Complex.norm_real, Real.norm_eq_abs] at h1
    linarith [le_abs_self (R0 + 1)]
  have : connectedComponentIn Kᶜ far = Kᶜ := by
    apply Subset.antisymm (connectedComponentIn_subset _ _)
    intro y hy
    have := comp_eq_far hK (arc_comp_unbounded f hf hcd hinj hy)
    rw [← this]; exact mem_connectedComponentIn hy
  rw [← this]; exact isConnected_connectedComponentIn_iff.2 hfar

theorem maehara_core (αn αs : ℝ → ℂ) (hcn : Continuous αn) (hcs : Continuous αs)
    (h0n : αn 0 = -1) (h1n : αn 1 = 1) (h0s : αs 0 = -1) (h1s : αs 1 = 1)
    (hinjn : InjOn αn (Icc 0 1)) (hinjs : InjOn αs (Icc 0 1))
    (hcap : ∀ z, z ∈ αn '' Icc 0 1 → z ∈ αs '' Icc 0 1 → z = -1 ∨ z = 1)
    (hbox : ∀ z ∈ αn '' Icc 0 1 ∪ αs '' Icc 0 1, |z.re| ≤ 1 ∧ |z.im| < 2 ∧
      (z.re = -1 → z = -1) ∧ (z.re = 1 → z = 1))
    (hcl : ∀ x ∉ αn '' Icc 0 1 ∪ αs '' Icc 0 1,
      (-1 : ℂ) ∈ closure (connectedComponentIn (αn '' Icc 0 1 ∪ αs '' Icc 0 1)ᶜ x) ∧
      (1 : ℂ) ∈ closure (connectedComponentIn (αn '' Icc 0 1 ∪ αs '' Icc 0 1)ᶜ x))
    (hm : ∀ y : ℝ, (y : ℂ) * I ∈ αs '' Icc 0 1 → ∃ y', y ≤ y' ∧ (y' : ℂ) * I ∈ αn '' Icc 0 1) :
    ∃ z0, z0 ∉ αn '' Icc 0 1 ∪ αs '' Icc 0 1 ∧
      Bornology.IsBounded (connectedComponentIn (αn '' Icc 0 1 ∪ αs '' Icc 0 1)ᶜ z0) ∧
      ∀ w, w ∉ αn '' Icc 0 1 ∪ αs '' Icc 0 1 →
        Bornology.IsBounded (connectedComponentIn (αn '' Icc 0 1 ∪ αs '' Icc 0 1)ᶜ w) →
        connectedComponentIn (αn '' Icc 0 1 ∪ αs '' Icc 0 1)ᶜ w =
          connectedComponentIn (αn '' Icc 0 1 ∪ αs '' Icc 0 1)ᶜ z0 := by
  set Jn := αn '' Icc 0 1 with hJn
  set Js := αs '' Icc 0 1 with hJs
  set J := Jn ∪ Js with hJ
  set v : ℝ → ℂ := fun y => (y : ℂ) * I with hv
  have vre : ∀ y, (v y).re = 0 := fun y => by simp [v]
  have vim : ∀ y, (v y).im = y := fun y => by simp [v]
  have hvc : Continuous v := by fun_prop
  have hJnc : IsCompact Jn := isCompact_Icc.image hcn
  have hJsc : IsCompact Js := isCompact_Icc.image hcs
  have hJc : IsCompact J := hJnc.union hJsc
  have hJo : IsOpen Jᶜ := hJc.isClosed.isOpen_compl
  have m1n : (-1 : ℂ) ∈ Jn := ⟨0, ⟨le_rfl, zero_le_one⟩, h0n⟩
  have p1n : (1 : ℂ) ∈ Jn := ⟨1, ⟨zero_le_one, le_rfl⟩, h1n⟩
  have vne1 : ∀ y, v y ≠ -1 := fun y h => by
    have := congrArg Complex.re h; rw [vre] at this; norm_num at this
  have vne1' : ∀ y, v y ≠ 1 := fun y h => by
    have := congrArg Complex.re h; rw [vre] at this; norm_num at this
  have rayL : ∀ z ∈ J, z ≠ -1 → ∀ t : ℝ, 0 ≤ t → z ≠ -1 - t := by
    intro z hz hz1 t ht heq
    obtain ⟨h1, -, h3, -⟩ := hbox z hz
    have : z.re = -1 - t := by rw [heq]; simp
    rw [abs_le] at h1
    exact hz1 (h3 (by linarith))
  have rayR : ∀ z ∈ J, z ≠ 1 → ∀ t : ℝ, 0 ≤ t → z ≠ 1 + t := by
    intro z hz hz1 t ht heq
    obtain ⟨h1, -, -, h4⟩ := hbox z hz
    have : z.re = 1 + t := by rw [heq]; simp
    rw [abs_le] at h1
    exact hz1 (h4 (by linarith))
  have axL : ∀ y t : ℝ, 0 ≤ t → v y ≠ -1 - t := fun y t ht h => by
    have := congrArg Complex.re h; rw [vre] at this; simp at this; linarith
  have axR : ∀ y t : ℝ, 0 ≤ t → v y ≠ 1 + t := fun y t ht h => by
    have := congrArg Complex.re h; rw [vre] at this; simp at this; linarith
  have notJre : ∀ z : ℂ, 1 < |z.re| → z ∉ J := fun z hz hzJ => by
    have := (hbox z hzJ).1; linarith
  have notJim : ∀ z : ℂ, 2 ≤ |z.im| → z ∉ J := fun z hz hzJ => by
    have := (hbox z hzJ).2.1; linarith
  -- the separation property of the two extended arcs
  have sepN : ∀ C : Set ℂ, IsPreconnected C → (∀ z ∈ C, z ∉ Jn ∧
      (∀ t : ℝ, 0 ≤ t → z ≠ -1 - t) ∧ (∀ t : ℝ, 0 ≤ t → z ≠ 1 + t)) →
      v 3 ∈ C → v (-3) ∈ C → False := by
    intro C hC hCB h3 hm3
    refine sep_barrier αn hcn 2 (fun s hs => (hbox _ (Or.inl ⟨s, hs, rfl⟩)).2.1.le) C hC ?_ h3 hm3
      (by rw [vim]; norm_num) (by rw [vim]; norm_num)
    rw [h0n, h1n]; exact hCB
  have sepS : ∀ C : Set ℂ, IsPreconnected C → (∀ z ∈ C, z ∉ Js ∧
      (∀ t : ℝ, 0 ≤ t → z ≠ -1 - t) ∧ (∀ t : ℝ, 0 ≤ t → z ≠ 1 + t)) →
      v 3 ∈ C → v (-3) ∈ C → False := by
    intro C hC hCB h3 hm3
    refine sep_barrier αs hcs 2 (fun s hs => (hbox _ (Or.inr ⟨s, hs, rfl⟩)).2.1.le) C hC ?_ h3 hm3
      (by rw [vim]; norm_num) (by rw [vim]; norm_num)
    rw [h0s, h1s]; exact hCB
  -- sub-arcs
  have subarc : ∀ α : ℝ → ℂ, Continuous α → InjOn α (Icc 0 1) → α 0 = -1 → α 1 = 1 →
      ∀ t1 t2 : ℝ, t1 ∈ Ioo (0:ℝ) 1 → t2 ∈ Ioo (0:ℝ) 1 →
      IsCompact (α '' uIcc t1 t2) ∧ IsPreconnected (α '' uIcc t1 t2) ∧
      ∀ z ∈ α '' uIcc t1 t2, z ∈ α '' Icc 0 1 ∧ z ≠ -1 ∧ z ≠ 1 := by
    intro α hα hinj ha0 ha1 t1 t2 ht1 ht2
    refine ⟨isCompact_uIcc.image hα, isPreconnected_uIcc.image _ hα.continuousOn, ?_⟩
    rintro z ⟨t, ht, rfl⟩
    have ht' : t ∈ Ioo (0:ℝ) 1 := (ordConnected_Ioo.uIcc_subset ht1 ht2) ht
    have htI : t ∈ Icc (0:ℝ) 1 := Ioo_subset_Icc_self ht'
    refine ⟨⟨t, htI, rfl⟩, ?_, ?_⟩
    · intro h; rw [← ha0] at h
      have := hinj htI ⟨le_rfl, zero_le_one⟩ h; linarith [ht'.1]
    · intro h; rw [← ha1] at h
      have := hinj htI ⟨zero_le_one, le_rfl⟩ h; linarith [ht'.2]
  have param : ∀ α : ℝ → ℂ, α 0 = -1 → α 1 = 1 → ∀ z ∈ α '' Icc 0 1, z ≠ -1 → z ≠ 1 →
      ∃ t ∈ Ioo (0:ℝ) 1, α t = z := by
    rintro α ha0 ha1 z ⟨t, ht, rfl⟩ h1 h2
    refine ⟨t, ⟨lt_of_le_of_ne ht.1 ?_, lt_of_le_of_ne ht.2 ?_⟩, rfl⟩
    · rintro rfl; exact h1 ha0
    · rintro rfl; exact h2 ha1
  -- points of the arcs on the imaginary axis
  have Ycomp : ∀ S : Set ℂ, IsCompact S → S ⊆ J → IsCompact (v ⁻¹' S) := by
    intro S hS hSJ
    refine (isCompact_Icc (a := (-2:ℝ)) (b := 2)).of_isClosed_subset
      (hS.isClosed.preimage hvc) ?_
    intro y hy
    have := (hbox _ (hSJ hy)).2.1
    rw [vim, abs_lt] at this
    exact ⟨this.1.le, this.2.le⟩
  have hYn : IsCompact (v ⁻¹' Jn) := Ycomp Jn hJnc subset_union_left
  have hYs : IsCompact (v ⁻¹' Js) := Ycomp Js hJsc subset_union_right
  have Ybd : ∀ y, v y ∈ J → |y| < 2 := fun y hy => by
    have := (hbox _ hy).2.1; rwa [vim] at this
  -- step 1
  have hYne : (v ⁻¹' Jn).Nonempty := by
    by_contra hne
    rw [not_nonempty_iff_eq_empty] at hne
    refine sepN (v '' Icc (-3) 3) (isPreconnected_Icc.image _ hvc.continuousOn) ?_
      ⟨3, ⟨by norm_num, le_rfl⟩, rfl⟩ ⟨-3, ⟨le_rfl, by norm_num⟩, rfl⟩
    rintro z ⟨y, -, rfl⟩
    refine ⟨fun h => ?_, axL y, axR y⟩
    have : y ∈ v ⁻¹' Jn := h
    rw [hne] at this; exact this
  obtain ⟨ym, hymY, hymax⟩ := hYn.exists_isGreatest hYne
  obtain ⟨yl, hylY, hylmin⟩ := hYn.exists_isLeast hYne
  have hymJ : v ym ∈ J := Or.inl hymY
  have hylJ : v yl ∈ J := Or.inl hylY
  have hym2 := Ybd ym hymJ
  have hyl2 := Ybd yl hylJ
  rw [abs_lt] at hym2 hyl2
  have hd : ∀ y, ym < y → v y ∉ J := by
    rintro y hy (h | h)
    · linarith [hymax h]
    · obtain ⟨y', hy', h'⟩ := hm y h
      linarith [hymax h']
  have hmS : ∀ y, ym ≤ y → v y ∉ Js := by
    intro y hy h
    rcases eq_or_lt_of_le hy with rfl | hlt
    · rcases hcap _ hymY h with h1 | h1
      · exact vne1 _ h1
      · exact vne1' _ h1
    · exact hd y hlt (Or.inr h)
  have ha : ∀ y, y < yl → v y ∉ Jn := fun y hy h => by linarith [hylmin h]
  have hylS : v yl ∉ Js := fun h => by
    rcases hcap _ hylY h with h1 | h1
    · exact vne1 _ h1
    · exact vne1' _ h1
  obtain ⟨tm, htm, htmv⟩ := param αn h0n h1n (v ym) hymY (vne1 _) (vne1' _)
  obtain ⟨tl, htl, htlv⟩ := param αn h0n h1n (v yl) hylY (vne1 _) (vne1' _)
  obtain ⟨arcNc, arcNp, arcNs⟩ := subarc αn hcn hinjn h0n h1n tm tl htm htl
  set arcN := αn '' uIcc tm tl with harcN
  have hmA : v ym ∈ arcN := ⟨tm, left_mem_uIcc, htmv⟩
  have hlA : v yl ∈ arcN := ⟨tl, right_mem_uIcc, htlv⟩
  have arcN_ok : ∀ z ∈ arcN, z ∈ J ∧ z ∉ Js ∧ (∀ t : ℝ, 0 ≤ t → z ≠ -1 - t) ∧
      (∀ t : ℝ, 0 ≤ t → z ≠ 1 + t) := by
    intro z hz
    obtain ⟨hz1, hz2, hz3⟩ := arcNs z hz
    refine ⟨Or.inl hz1, fun h => ?_, rayL z (Or.inl hz1) hz2, rayR z (Or.inl hz1) hz3⟩
    rcases hcap z hz1 h with h | h
    · exact hz2 h
    · exact hz3 h
  -- step 3: the lower arc crosses the axis below `l`
  have hstep3 : ∃ y, v y ∈ Js ∧ y < yl := by
    by_contra h
    push Not at h
    have hpre : IsPreconnected (v '' Icc ym 3 ∪ arcN ∪ v '' Icc (-3) yl) := by
      refine IsPreconnected.union (v yl) (Or.inr hlA) ⟨yl, ⟨by linarith, le_rfl⟩, rfl⟩ ?_
        (isPreconnected_Icc.image _ hvc.continuousOn)
      exact IsPreconnected.union (v ym) ⟨ym, ⟨le_rfl, by linarith⟩, rfl⟩ hmA
        (isPreconnected_Icc.image _ hvc.continuousOn) arcNp
    refine sepS _ hpre ?_ (Or.inl (Or.inl ⟨3, ⟨by linarith, le_rfl⟩, rfl⟩))
      (Or.inr ⟨-3, ⟨le_rfl, by linarith⟩, rfl⟩)
    rintro z ((⟨y, hy, rfl⟩ | hz) | ⟨y, hy, rfl⟩)
    · exact ⟨hmS y hy.1, axL y, axR y⟩
    · exact (arcN_ok z hz).2
    · refine ⟨fun hs => ?_, axL y, axR y⟩
      have := h y hs
      have hy' : y = yl := le_antisymm hy.2 this
      rw [hy'] at hs; exact hylS hs
  obtain ⟨y0, hy0s, hy0l⟩ := hstep3
  have hYs' : IsCompact (v ⁻¹' Js ∩ Iic yl) := hYs.inter_right isClosed_Iic
  obtain ⟨yp, ⟨hypS, hypl⟩, hypmax⟩ := hYs'.exists_isGreatest ⟨y0, hy0s, hy0l.le⟩
  have hypl' : yp < yl := lt_of_le_of_ne hypl (fun h => by rw [h] at hypS; exact hylS hypS)
  obtain ⟨yq, hyqS, hyqmin⟩ := hYs.exists_isLeast ⟨yp, hypS⟩
  have hyqp : yq ≤ yp := hyqmin hypS
  have hb : ∀ y, yp < y → y ≤ yl → v y ∉ Js := fun y h1 h2 h => by
    linarith [hypmax ⟨h, h2⟩]
  have hc : ∀ y, y < yq → v y ∉ Js := fun y h1 h => by linarith [hyqmin h]
  have hypJ : v yp ∈ J := Or.inr hypS
  have hyqJ : v yq ∈ J := Or.inr hyqS
  have hyp2 := Ybd yp hypJ
  have hyq2 := Ybd yq hyqJ
  rw [abs_lt] at hyp2 hyq2
  have hypN : v yp ∉ Jn := ha yp hypl'
  have hyqN : v yq ∉ Jn := ha yq (by linarith)
  obtain ⟨tp, htp, htpv⟩ := param αs h0s h1s (v yp) hypS (vne1 _) (vne1' _)
  obtain ⟨tq, htq, htqv⟩ := param αs h0s h1s (v yq) hyqS (vne1 _) (vne1' _)
  obtain ⟨arcSc, arcSp, arcSs⟩ := subarc αs hcs hinjs h0s h1s tp tq htp htq
  set arcS := αs '' uIcc tp tq with harcS
  have hpA : v yp ∈ arcS := ⟨tp, left_mem_uIcc, htpv⟩
  have hqA : v yq ∈ arcS := ⟨tq, right_mem_uIcc, htqv⟩
  have arcS_ok : ∀ z ∈ arcS, z ∈ J ∧ z ∉ Jn ∧ (∀ t : ℝ, 0 ≤ t → z ≠ -1 - t) ∧
      (∀ t : ℝ, 0 ≤ t → z ≠ 1 + t) := by
    intro z hz
    obtain ⟨hz1, hz2, hz3⟩ := arcSs z hz
    refine ⟨Or.inr hz1, fun h => ?_, rayL z (Or.inr hz1) hz2, rayR z (Or.inr hz1) hz3⟩
    rcases hcap z h hz1 with h | h
    · exact hz2 h
    · exact hz3 h
  set mid := (yp + yl) / 2 with hmid
  have hmid1 : yp < mid := by rw [hmid]; linarith
  have hmid2 : mid < yl := by rw [hmid]; linarith
  have hbetween : ∀ y, yp < y → y < yl → v y ∉ J := by
    rintro y h1 h2 (h | h)
    · exact ha y h2 h
    · exact hb y h1 h2.le h
  have hz0 : v mid ∉ J := hbetween mid hmid1 hmid2
  -- the unbounded component
  have hK3 : ∀ z ∈ J, ‖z‖ ≤ 3 := fun z hz => by
    obtain ⟨h1, h2, -⟩ := hbox z hz
    linarith [Complex.norm_le_abs_re_add_abs_im z]
  set Vf := connectedComponentIn Jᶜ ((3 + 1 : ℝ) : ℂ) with hVf
  have hV_of : ∀ w, ¬ Bornology.IsBounded (connectedComponentIn Jᶜ w) →
      connectedComponentIn Jᶜ w = Vf := fun w hw => comp_eq_far hK3 hw
  have halfV : ∀ z : ℂ, 2 < |z.im| → z ∈ Vf := by
    intro z hz
    rcases lt_abs.1 hz with hz | hz
    · set UH := {c : ℂ | 2 < c.im}
      have hUH : UH ⊆ Jᶜ := fun c hc => notJim c (le_trans (le_of_lt hc) (le_abs_self _))
      have hsub := (convex_halfSpace_im_gt 2).isPreconnected.subset_connectedComponentIn
        (show z ∈ UH from hz) hUH
      have hub : ¬ Bornology.IsBounded (connectedComponentIn Jᶜ z) := by
        intro hbd
        obtain ⟨r, hr⟩ := (hbd.subset hsub).subset_closedBall 0
        have hmem : v (|r| + 3) ∈ UH := by
          show 2 < (v (|r| + 3)).im; rw [vim]; linarith [abs_nonneg r]
        have := hr hmem
        rw [Metric.mem_closedBall, dist_zero_right] at this
        have h2 : ‖v (|r| + 3)‖ = |r| + 3 := by
          simp only [v, norm_mul, Complex.norm_I, mul_one, Complex.norm_real, Real.norm_eq_abs]
          exact abs_of_nonneg (by positivity)
        rw [h2] at this; linarith [le_abs_self r]
      rw [← hV_of z hub]; exact mem_connectedComponentIn (notJim z (le_trans hz.le (le_abs_self _)))
    · set LH := {c : ℂ | c.im < -2}
      have hz' : 2 ≤ |z.im| := le_trans hz.le (neg_le_abs _)
      have hLH : LH ⊆ Jᶜ := fun c hc => notJim c (by
        have : c.im < -2 := hc; rw [abs_of_neg (by linarith)]; linarith)
      have hsub := (convex_halfSpace_im_lt (-2)).isPreconnected.subset_connectedComponentIn
        (show z ∈ LH from by show z.im < -2; linarith) hLH
      have hub : ¬ Bornology.IsBounded (connectedComponentIn Jᶜ z) := by
        intro hbd
        obtain ⟨r, hr⟩ := (hbd.subset hsub).subset_closedBall 0
        have hmem : v (-(|r| + 3)) ∈ LH := by
          show (v (-(|r| + 3))).im < -2; rw [vim]; linarith [abs_nonneg r]
        have := hr hmem
        rw [Metric.mem_closedBall, dist_zero_right] at this
        have h2 : ‖v (-(|r| + 3))‖ = |r| + 3 := by
          simp only [v, norm_mul, Complex.norm_I, mul_one, Complex.norm_real, Real.norm_eq_abs]
          rw [abs_neg]; exact abs_of_nonneg (by positivity)
        rw [h2] at this; linarith [le_abs_self r]
      rw [← hV_of z hub]; exact mem_connectedComponentIn (notJim z hz')
  have hVf_unb : ¬ Bornology.IsBounded Vf := by
    intro hbd
    obtain ⟨r, hr⟩ := hbd.subset_closedBall 0
    have hmem : v (|r| + 3) ∈ Vf := halfV _ (by rw [vim, abs_of_nonneg (by positivity)]; linarith [abs_nonneg r])
    have := hr hmem
    rw [Metric.mem_closedBall, dist_zero_right] at this
    have h2 : ‖v (|r| + 3)‖ = |r| + 3 := by
      simp only [v, norm_mul, Complex.norm_I, mul_one, Complex.norm_real, Real.norm_eq_abs]
      exact abs_of_nonneg (by positivity)
    rw [h2] at this; linarith [le_abs_self r]
  have toV : ∀ S : Set ℂ, IsPreconnected S → S ⊆ Jᶜ → ∀ z ∈ S, 2 < |z.im| → S ⊆ Vf := by
    intro S hS hSJ z hz hzi
    have hzV := halfV z hzi
    rw [hVf, connectedComponentIn_eq hzV]
    exact hS.subset_connectedComponentIn hz hSJ
  -- step 4: the component of `v mid` is bounded
  set Ray : Set ℂ := {z | ∃ t : ℝ, 0 ≤ t ∧ z = -1 - t} ∪ {z | ∃ t : ℝ, 0 ≤ t ∧ z = 1 + t}
    with hRay
  have hRayc : IsClosed Ray := (ray_left_closed (-1)).union (ray_right_closed 1)
  set O := (J ∪ Ray)ᶜ with hO
  have hOo : IsOpen O := (hJc.isClosed.union hRayc).isOpen_compl
  have memO : ∀ z, z ∉ J → (∀ t : ℝ, 0 ≤ t → z ≠ -1 - t) → (∀ t : ℝ, 0 ≤ t → z ≠ 1 + t) →
      z ∈ O := by
    intro z h1 h2 h3 h
    rcases h with h | (⟨t, ht, rfl⟩ | ⟨t, ht, rfl⟩)
    · exact h1 h
    · exact h2 t ht rfl
    · exact h3 t ht rfl
  have Oprops : ∀ z ∈ O, z ∉ J ∧ (∀ t : ℝ, 0 ≤ t → z ≠ -1 - t) ∧
      (∀ t : ℝ, 0 ≤ t → z ≠ 1 + t) := by
    intro z hz
    exact ⟨fun h => hz (Or.inl h), fun t ht h => hz (Or.inr (Or.inl ⟨t, ht, h⟩)),
      fun t ht h => hz (Or.inr (Or.inr ⟨t, ht, h⟩))⟩
  have imO : ∀ z : ℂ, z ∉ J → z.im ≠ 0 → z ∈ O := by
    intro z h1 h2
    refine memO z h1 (fun t ht h => h2 ?_) (fun t ht h => h2 ?_) <;> rw [h] <;> simp
  have hU0b : Bornology.IsBounded (connectedComponentIn Jᶜ (v mid)) := by
    by_contra hub
    have hz0V : connectedComponentIn Jᶜ (v mid) = Vf := hV_of _ hub
    have hz0O : v mid ∈ O := memO _ hz0 (axL mid) (axR mid)
    set C := connectedComponentIn O (v mid) with hC
    have hCo : IsOpen C := hOo.connectedComponentIn
    have hz0C : v mid ∈ C := mem_connectedComponentIn hz0O
    have hCO : C ⊆ O := connectedComponentIn_subset _ _
    have upC : ∀ c ∈ C, 1 < |c.re| → 0 < c.im → v 3 ∈ C := by
      intro c hc hre him
      set S := (fun s : ℝ => c + (s : ℂ) * I) '' Icc 0 3
      have hS : IsPreconnected S := isPreconnected_Icc.image _ (by fun_prop)
      have hUH : IsPreconnected {z : ℂ | 2 < z.im} := (convex_halfSpace_im_gt 2).isPreconnected
      have hpre : IsPreconnected (S ∪ {z : ℂ | 2 < z.im}) :=
        IsPreconnected.union (c + ((3:ℝ):ℂ) * I) ⟨3, ⟨by norm_num, le_rfl⟩, rfl⟩
          (by show 2 < (c + ((3:ℝ):ℂ) * I).im; simp; linarith) hS hUH
      have hsubO : S ∪ {z : ℂ | 2 < z.im} ⊆ O := by
        rintro z (⟨s, hs, rfl⟩ | hz)
        · apply imO
          · apply notJre; simpa using hre
          · simp; linarith [hs.1]
        · have hz' : 2 < z.im := hz
          exact imO z (notJim z (le_trans hz'.le (le_abs_self _))) (by linarith)
      have := hpre.subset_connectedComponentIn (x := c)
        (Or.inl ⟨0, ⟨le_rfl, by norm_num⟩, by simp⟩) hsubO
      rw [hC, connectedComponentIn_eq hc]
      exact this (Or.inr (by show 2 < (v 3).im; rw [vim]; norm_num))
    have downC : ∀ c ∈ C, 1 < |c.re| → c.im < 0 → v (-3) ∈ C := by
      intro c hc hre him
      set S := (fun s : ℝ => c - (s : ℂ) * I) '' Icc 0 3
      have hS : IsPreconnected S := isPreconnected_Icc.image _ (by fun_prop)
      have hLH : IsPreconnected {z : ℂ | z.im < -2} :=
        (convex_halfSpace_im_lt (-2)).isPreconnected
      have hpre : IsPreconnected (S ∪ {z : ℂ | z.im < -2}) :=
        IsPreconnected.union (c - ((3:ℝ):ℂ) * I) ⟨3, ⟨by norm_num, le_rfl⟩, rfl⟩
          (by show (c - ((3:ℝ):ℂ) * I).im < -2; simp; linarith) hS hLH
      have hsubO : S ∪ {z : ℂ | z.im < -2} ⊆ O := by
        rintro z (⟨s, hs, rfl⟩ | hz)
        · apply imO
          · apply notJre; simpa using hre
          · simp; linarith [hs.1]
        · have hz' : z.im < -2 := hz
          exact imO z (notJim z (le_trans (by linarith) (neg_le_abs _))) (by linarith)
      have := hpre.subset_connectedComponentIn (x := c)
        (Or.inl ⟨0, ⟨le_rfl, by norm_num⟩, by simp⟩) hsubO
      rw [hC, connectedComponentIn_eq hc]
      exact this (Or.inr (by show (v (-3)).im < -2; rw [vim]; norm_num))
    have hcases : v 3 ∈ C ∨ v (-3) ∈ C := by
      by_contra hcon
      push Not at hcon
      have nearRay : ∀ c ∈ C, 1 < |c.re| → False := by
        intro c hc hre
        rcases lt_trichotomy c.im 0 with h | h | h
        · exact hcon.2 (downC c hc hre h)
        · obtain ⟨-, h2, h3⟩ := Oprops c (hCO hc)
          rcases lt_abs.1 hre with h' | h'
          · exact h3 (c.re - 1) (by linarith) (Complex.ext (by simp) (by simp [h]))
          · exact h2 (-1 - c.re) (by linarith) (Complex.ext (by simp) (by simp [h]))
        · exact hcon.1 (upC c hc hre h)
      have key : Vf ⊆ C ∪ (closure C)ᶜ := by
        intro x hx
        by_cases hxc : x ∈ closure C
        swap
        · exact Or.inr hxc
        left
        by_cases hxO : x ∈ O
        · exact mem_comp_of_mem_closure hOo hxc hxO
        exfalso
        have hxJ : x ∉ J := connectedComponentIn_subset _ _ hx
        have hxR : x ∈ Ray := by
          by_contra hxR; exact hxO (fun h => h.elim hxJ hxR)
        rcases hxR with ⟨t, ht, rfl⟩ | ⟨t, ht, rfl⟩
        · have ht0 : 0 < t := lt_of_le_of_ne ht (fun h => hxJ (by
            rw [← h]; simp only [ofReal_zero, sub_zero]; exact Or.inl m1n))
          obtain ⟨c, hc, hdist⟩ := Metric.mem_closure_iff.1 hxc t ht0
          have h1 : |(-1 - (t:ℂ) - c).re| ≤ ‖-1 - (t:ℂ) - c‖ := Complex.abs_re_le_norm _
          rw [← dist_eq_norm] at h1
          have h2 : (-1 - (t:ℂ) - c).re = -1 - t - c.re := by simp
          rw [h2, abs_le] at h1
          exact nearRay c hc (by rw [abs_of_neg (by linarith)]; linarith)
        · have ht0 : 0 < t := lt_of_le_of_ne ht (fun h => hxJ (by
            rw [← h]; simp only [ofReal_zero, add_zero]; exact Or.inl p1n))
          obtain ⟨c, hc, hdist⟩ := Metric.mem_closure_iff.1 hxc t ht0
          have h1 : |(1 + (t:ℂ) - c).re| ≤ ‖1 + (t:ℂ) - c‖ := Complex.abs_re_le_norm _
          rw [← dist_eq_norm] at h1
          have h2 : (1 + (t:ℂ) - c).re = 1 + t - c.re := by simp
          rw [h2, abs_le] at h1
          exact nearRay c hc (by rw [abs_of_pos (by linarith)]; linarith)
      have hVpre : IsPreconnected Vf := isPreconnected_connectedComponentIn
      rcases hVpre.subset_or_subset hCo isClosed_closure.isOpen_compl
        (disjoint_compl_right_iff_subset.2 subset_closure) key with h | h
      · exact hcon.1 (h (halfV _ (by rw [vim]; norm_num)))
      · have : v mid ∈ Vf := hz0V ▸ mem_connectedComponentIn hz0
        exact h this (subset_closure hz0C)
    rcases hcases with h3 | h3
    · have hpre : IsPreconnected (C ∪ v '' Icc yp mid ∪ arcS ∪ v '' Icc (-3) yq) := by
        refine IsPreconnected.union (v yq) (Or.inr hqA) ⟨yq, ⟨by linarith, le_rfl⟩, rfl⟩ ?_
          (isPreconnected_Icc.image _ hvc.continuousOn)
        refine IsPreconnected.union (v yp) (Or.inr ⟨yp, ⟨le_rfl, hmid1.le⟩, rfl⟩) hpA ?_ arcSp
        exact IsPreconnected.union (v mid) hz0C ⟨mid, ⟨hmid1.le, le_rfl⟩, rfl⟩
          isPreconnected_connectedComponentIn (isPreconnected_Icc.image _ hvc.continuousOn)
      refine sepN _ hpre ?_ (Or.inl (Or.inl (Or.inl h3))) (Or.inr ⟨-3, ⟨le_rfl, by linarith⟩, rfl⟩)
      rintro z (((hz | ⟨y, hy, rfl⟩) | hz) | ⟨y, hy, rfl⟩)
      · obtain ⟨h1, h2, h3⟩ := Oprops z (hCO hz); exact ⟨fun h => h1 (Or.inl h), h2, h3⟩
      · exact ⟨ha y (by linarith [hy.2]), axL y, axR y⟩
      · exact (arcS_ok z hz).2
      · exact ⟨ha y (by linarith [hy.2]), axL y, axR y⟩
    · have hpre : IsPreconnected (v '' Icc ym 3 ∪ arcN ∪ v '' Icc mid yl ∪ C) := by
        refine IsPreconnected.union (v mid) (Or.inr ⟨mid, ⟨le_rfl, hmid2.le⟩, rfl⟩) hz0C ?_
          isPreconnected_connectedComponentIn
        refine IsPreconnected.union (v yl) (Or.inr hlA) ⟨yl, ⟨hmid2.le, le_rfl⟩, rfl⟩ ?_
          (isPreconnected_Icc.image _ hvc.continuousOn)
        exact IsPreconnected.union (v ym) ⟨ym, ⟨le_rfl, by linarith⟩, rfl⟩ hmA
          (isPreconnected_Icc.image _ hvc.continuousOn) arcNp
      refine sepS _ hpre ?_ (Or.inl (Or.inl (Or.inl ⟨3, ⟨by linarith, le_rfl⟩, rfl⟩))) (Or.inr h3)
      rintro z (((⟨y, hy, rfl⟩ | hz) | ⟨y, hy, rfl⟩) | hz)
      · exact ⟨hmS y hy.1, axL y, axR y⟩
      · exact (arcN_ok z hz).2
      · exact ⟨hb y (by linarith [hy.1]) hy.2, axL y, axR y⟩
      · obtain ⟨h1, h2, h3⟩ := Oprops z (hCO hz); exact ⟨fun h => h1 (Or.inr h), h2, h3⟩
  -- step 5: no other bounded component
  refine ⟨v mid, hz0, hU0b, ?_⟩
  intro w hw hwb
  by_contra hne
  set W := connectedComponentIn Jᶜ w with hW
  have hWU : ∀ z ∈ W, z ∉ connectedComponentIn Jᶜ (v mid) := fun z hzW hzU =>
    hne (by show connectedComponentIn Jᶜ w = _; rw [connectedComponentIn_eq hzW, ← connectedComponentIn_eq hzU])
  have hWV : ∀ z ∈ W, z ∉ Vf := fun z hzW hzV => by
    apply hVf_unb
    rw [hVf, connectedComponentIn_eq hzV, ← connectedComponentIn_eq hzW]; exact hwb
  have hWJ : W ⊆ Jᶜ := connectedComponentIn_subset _ _
  set Pk := v '' Icc ym 3 ∪ arcN ∪ v '' Icc yp yl ∪ arcS ∪ v '' Icc (-3) yq with hPk
  have hPpre : IsPreconnected Pk := by
    refine IsPreconnected.union (v yq) (Or.inr hqA) ⟨yq, ⟨by linarith, le_rfl⟩, rfl⟩ ?_
      (isPreconnected_Icc.image _ hvc.continuousOn)
    refine IsPreconnected.union (v yp) (Or.inr ⟨yp, ⟨le_rfl, hypl⟩, rfl⟩) hpA ?_ arcSp
    refine IsPreconnected.union (v yl) (Or.inr hlA) ⟨yl, ⟨hypl, le_rfl⟩, rfl⟩ ?_
      (isPreconnected_Icc.image _ hvc.continuousOn)
    exact IsPreconnected.union (v ym) ⟨ym, ⟨le_rfl, by linarith⟩, rfl⟩ hmA
      (isPreconnected_Icc.image _ hvc.continuousOn) arcNp
  have hPc : IsCompact Pk := ((((isCompact_Icc.image hvc).union arcNc).union
    (isCompact_Icc.image hvc)).union arcSc).union (isCompact_Icc.image hvc)
  have hPW : ∀ z ∈ Pk, z ∉ W := by
    rintro z ((((⟨y, hy, rfl⟩ | hz) | ⟨y, hy, rfl⟩) | hz) | ⟨y, hy, rfl⟩) hzW
    · rcases eq_or_lt_of_le hy.1 with h | h
      · rw [← h] at hzW; exact hWJ hzW hymJ
      · have hsub := toV (v '' Icc y 3) (isPreconnected_Icc.image _ hvc.continuousOn)
          (by rintro _ ⟨y', hy', rfl⟩; exact hd y' (by linarith [hy'.1]))
          (v 3) ⟨3, ⟨hy.2, le_rfl⟩, rfl⟩ (by rw [vim]; norm_num)
        exact hWV _ hzW (hsub ⟨y, ⟨le_rfl, hy.2⟩, rfl⟩)
    · exact hWJ hzW (arcN_ok z hz).1
    · rcases eq_or_lt_of_le hy.1 with h | h
      · rw [← h] at hzW; exact hWJ hzW hypJ
      rcases eq_or_lt_of_le hy.2 with h' | h'
      · rw [h'] at hzW; exact hWJ hzW hylJ
      have hsub : v '' uIcc y mid ⊆ connectedComponentIn Jᶜ (v mid) :=
        (isPreconnected_uIcc.image _ hvc.continuousOn).subset_connectedComponentIn
          ⟨mid, right_mem_uIcc, rfl⟩ (by
            rintro _ ⟨y', hy', rfl⟩
            have := (ordConnected_Ioo (a := yp) (b := yl)).uIcc_subset ⟨h, h'⟩
              ⟨hmid1, hmid2⟩ hy'
            exact hbetween y' this.1 this.2)
      exact hWU _ hzW (hsub ⟨y, left_mem_uIcc, rfl⟩)
    · exact hWJ hzW (arcS_ok z hz).1
    · rcases eq_or_lt_of_le hy.2 with h | h
      · rw [h] at hzW; exact hWJ hzW hyqJ
      · have hsub := toV (v '' Icc (-3) y) (isPreconnected_Icc.image _ hvc.continuousOn)
          (by
            rintro _ ⟨y', hy', rfl⟩ (h1 | h1)
            · exact ha y' (by linarith [hy'.2]) h1
            · exact hc y' (by linarith [hy'.2]) h1)
          (v (-3)) ⟨-3, ⟨le_rfl, hy.1⟩, rfl⟩ (by rw [vim]; norm_num)
        exact hWV _ hzW (hsub ⟨y, ⟨hy.1, le_rfl⟩, rfl⟩)
  have hPre : ∀ z ∈ Pk, |z.re| ≤ 1 := by
    rintro z ((((⟨y, -, rfl⟩ | hz) | ⟨y, -, rfl⟩) | hz) | ⟨y, -, rfl⟩)
    · rw [vre]; norm_num
    · exact (hbox z (arcN_ok z hz).1).1
    · rw [vre]; norm_num
    · exact (hbox z (arcS_ok z hz).1).1
    · rw [vre]; norm_num
  have hPm1 : (-1 : ℂ) ∉ Pk := by
    rintro ((((⟨y, -, h⟩ | hz) | ⟨y, -, h⟩) | hz) | ⟨y, -, h⟩)
    · exact vne1 y h
    · exact (arcNs _ hz).2.1 rfl
    · exact vne1 y h
    · exact (arcSs _ hz).2.1 rfl
    · exact vne1 y h
  have hP1 : (1 : ℂ) ∉ Pk := by
    rintro ((((⟨y, -, h⟩ | hz) | ⟨y, -, h⟩) | hz) | ⟨y, -, h⟩)
    · exact vne1' y h
    · exact (arcNs _ hz).2.2 rfl
    · exact vne1' y h
    · exact (arcSs _ hz).2.2 rfl
    · exact vne1' y h
  have hPo : IsOpen Pkᶜ := hPc.isClosed.isOpen_compl
  obtain ⟨ε1, hε1, hb1⟩ := Metric.isOpen_iff.1 hPo (-1) hPm1
  obtain ⟨ε2, hε2, hb2⟩ := Metric.isOpen_iff.1 hPo 1 hP1
  set ε := min ε1 ε2 / 2 with hε
  have hεpos : 0 < ε := by positivity
  have hε1' : 2 * ε ≤ ε1 := by rw [hε]; linarith [min_le_left ε1 ε2]
  have hε2' : 2 * ε ≤ ε2 := by rw [hε]; linarith [min_le_right ε1 ε2]
  obtain ⟨wa, hwaW, hwad⟩ := Metric.mem_closure_iff.1 (hcl w hw).1 ε hεpos
  obtain ⟨wb, hwbW, hwbd⟩ := Metric.mem_closure_iff.1 (hcl w hw).2 ε hεpos
  have hWo : IsOpen W := hJo.connectedComponentIn
  have hWpc : IsPathConnected W :=
    (hWo.isConnected_iff_isPathConnected).1 (isConnected_connectedComponentIn_iff.2 hw)
  have hj := hWpc.joinedIn wa hwaW wb hwbW
  set γ := hj.somePath
  set α : ℝ → ℂ := ⇑γ.extend
  have hαc : Continuous α := γ.extend.continuous
  have hαW : ∀ t ∈ Icc (0:ℝ) 1, α t ∈ W := fun t ht => by
    simp only [α]; rw [Path.extend_apply γ ht]; exact hj.somePath_mem _
  have hα0 : α 0 = wa := γ.extend_zero
  have hα1 : α 1 = wb := γ.extend_one
  refine sep_barrier α hαc 2 ?_ Pk hPpre ?_
    (Or.inl (Or.inl (Or.inl (Or.inl ⟨3, ⟨by linarith, le_rfl⟩, rfl⟩))))
    (Or.inr ⟨-3, ⟨le_rfl, by linarith⟩, rfl⟩) (by rw [vim]; norm_num) (by rw [vim]; norm_num)
  · intro s hs
    by_contra h; push Not at h
    exact hWV _ (hαW s hs) (halfV _ h)
  · intro z hz
    refine ⟨?_, ?_, ?_⟩
    · rintro ⟨t, ht, rfl⟩; exact hPW _ hz (hαW t ht)
    · intro t ht heq
      rw [hα0] at heq
      have hre := hPre z hz
      have h1 : |(-1 - wa).re| ≤ ‖-1 - wa‖ := Complex.abs_re_le_norm _
      rw [← dist_eq_norm] at h1
      have h2 : (-1 - wa).re = -1 - wa.re := by simp
      rw [h2, abs_le] at h1
      have hzre : z.re = wa.re - t := by rw [heq]; simp
      rw [abs_le] at hre
      have ht' : t < ε := by linarith
      apply hb1 (show z ∈ Metric.ball (-1) ε1 from ?_) hz
      rw [Metric.mem_ball, dist_eq_norm, heq]
      calc ‖wa - (t:ℂ) - -1‖ ≤ ‖wa - -1‖ + ‖(t:ℂ)‖ := by
            rw [show wa - (t:ℂ) - -1 = (wa - -1) - t by ring]; exact norm_sub_le _ _
        _ < ε + ε := by
            rw [← dist_eq_norm, dist_comm, Complex.norm_real, Real.norm_of_nonneg ht]; linarith
        _ ≤ ε1 := by linarith
    · intro t ht heq
      rw [hα1] at heq
      have hre := hPre z hz
      have h1 : |(1 - wb).re| ≤ ‖1 - wb‖ := Complex.abs_re_le_norm _
      rw [← dist_eq_norm] at h1
      have h2 : (1 - wb).re = 1 - wb.re := by simp
      rw [h2, abs_le] at h1
      have hzre : z.re = wb.re + t := by rw [heq]; simp
      rw [abs_le] at hre
      have ht' : t < ε := by linarith
      apply hb2 (show z ∈ Metric.ball 1 ε2 from ?_) hz
      rw [Metric.mem_ball, dist_eq_norm, heq]
      calc ‖wb + (t:ℂ) - 1‖ ≤ ‖wb - 1‖ + ‖(t:ℂ)‖ := by
            rw [show wb + (t:ℂ) - 1 = (wb - 1) + t by ring]; exact norm_add_le _ _
        _ < ε + ε := by
            rw [← dist_eq_norm, dist_comm, Complex.norm_real, Real.norm_of_nonneg ht]; linarith
        _ ≤ ε2 := by linarith

theorem inj_shift (Γ : ℝ → ℂ) (hper : Function.Periodic Γ 1) (hinj : InjOn Γ (Ico 0 1))
    (c : ℝ) : InjOn Γ (Ico c (c + 1)) := by
  intro s hs t ht hst
  have hf : ∀ x, Γ (Int.fract x) = Γ x := fun x => by
    have := hper.sub_int_mul_eq (x := x) ⌊x⌋; rwa [mul_one] at this
  have h1 : Int.fract s = Int.fract t := hinj ⟨Int.fract_nonneg _, Int.fract_lt_one _⟩
    ⟨Int.fract_nonneg _, Int.fract_lt_one _⟩ (by rw [hf, hf, hst])
  obtain ⟨z, hz⟩ := Int.fract_eq_fract.1 h1
  have h2 : (z : ℝ) < 1 := by rw [← hz]; linarith [hs.1, hs.2, ht.1, ht.2]
  have h3 : (-1 : ℝ) < z := by rw [← hz]; linarith [hs.1, hs.2, ht.1, ht.2]
  have h4 : z = 0 := by
    have : z < 1 := by exact_mod_cast h2
    have : -1 < z := by exact_mod_cast h3
    omega
  rw [h4] at hz; simp at hz; linarith

theorem periodic_image (Γ : ℝ → ℂ) (hper : Function.Periodic Γ 1) :
    Γ '' Icc 0 1 = range Γ := by
  apply Subset.antisymm (image_subset_range _ _)
  rintro _ ⟨t, rfl⟩
  refine ⟨Int.fract t, ⟨Int.fract_nonneg _, (Int.fract_lt_one _).le⟩, ?_⟩
  have := hper.sub_int_mul_eq (x := t) ⌊t⌋; rwa [mul_one] at this

/-- Every component of the complement of a Jordan curve has the whole curve as its boundary. -/
theorem jordan_frontier (Γ : ℝ → ℂ) (hΓ : Continuous Γ) (hper : Function.Periodic Γ 1)
    (hinj : InjOn Γ (Ico 0 1)) {x : ℂ} (hx : x ∉ range Γ) :
    frontier (connectedComponentIn (range Γ)ᶜ x) = range Γ := by
  set J := range Γ with hJ
  have hJc : IsCompact J := by rw [hJ, ← periodic_image Γ hper]; exact isCompact_Icc.image hΓ
  set W := connectedComponentIn Jᶜ x with hW
  have hWo : IsOpen W := hJc.isClosed.isOpen_compl.connectedComponentIn
  apply Subset.antisymm
  · intro z hz; simpa using frontier_comp_subset hJc.isClosed.isOpen_compl x hz
  rintro z ⟨t0, rfl⟩
  by_contra hz
  have hfo : IsOpen (frontier W)ᶜ := isClosed_frontier.isOpen_compl
  obtain ⟨δ, hδ, hball⟩ := Metric.isOpen_iff.1 (hfo.preimage hΓ) t0 hz
  set δ' := min (δ / 2) (1 / 4) with hδ'
  have hδ'pos : 0 < δ' := by positivity
  have hδ'δ : δ' < δ := lt_of_le_of_lt (min_le_left _ _) (by linarith)
  have hδ'q : δ' ≤ 1 / 4 := min_le_right _ _
  set A := Γ '' Icc (t0 + δ') (t0 + 1 - δ') with hA
  have hinjA : InjOn Γ (Icc (t0 + δ') (t0 + 1 - δ')) :=
    (inj_shift Γ hper hinj t0).mono (show Icc (t0 + δ') (t0 + 1 - δ') ⊆ Ico t0 (t0 + 1) from
      fun s hs => ⟨by linarith [hs.1], by linarith [hs.2]⟩)
  have hAconn := arc_compl_isConnected Γ hΓ (by linarith) hinjA
  have hfrA : frontier W ⊆ A := by
    intro y hy
    have hyJ : y ∈ J := by simpa using frontier_comp_subset hJc.isClosed.isOpen_compl x hy
    obtain ⟨t, rfl⟩ := hyJ
    set n := ⌊t - (t0 - δ')⌋
    have h1 : (n:ℝ) ≤ t - (t0 - δ') := Int.floor_le _
    have h2 : t - (t0 - δ') < n + 1 := Int.lt_floor_add_one _
    have hΓt : Γ (t - n) = Γ t := by
      have := hper.sub_int_mul_eq (x := t) n; rwa [mul_one] at this
    by_cases hlt : t - n < t0 + δ'
    · exfalso
      have hmem : t - n ∈ Metric.ball t0 δ := by
        rw [Metric.mem_ball, Real.dist_eq, abs_lt]; constructor <;> linarith
      exact hball hmem (by rw [hΓt]; exact hy)
    · exact ⟨t - n, ⟨by linarith, by linarith⟩, hΓt⟩
  have hzA : Γ t0 ∉ A := by
    rintro ⟨s, hs, hst⟩
    have := inj_shift Γ hper hinj t0 ⟨by linarith [hs.1], by linarith [hs.2]⟩
      ⟨le_rfl, by linarith⟩ hst
    linarith [hs.1]
  have hAJ : A ⊆ J := image_subset_range _ _
  have hWA : W ⊆ Aᶜ := fun w hw hwA => connectedComponentIn_subset _ _ hw (hAJ hwA)
  have key : Aᶜ ⊆ W ∪ (closure W)ᶜ := by
    intro y hy
    by_cases hyc : y ∈ closure W
    · left; by_contra hyW; exact hy (hfrA ⟨hyc, by rwa [hWo.interior_eq]⟩)
    · exact Or.inr hyc
  rcases hAconn.isPreconnected.subset_or_subset hWo isClosed_closure.isOpen_compl
    (disjoint_compl_right_iff_subset.2 subset_closure) key with h | h
  · exact connectedComponentIn_subset _ _ (h hzA) ⟨t0, rfl⟩
  · exact h (hWA (mem_connectedComponentIn hx)) (subset_closure (mem_connectedComponentIn hx))

theorem box_of_diam (z : ℂ) (h1 : ‖z + 1‖ ≤ 2) (h2 : ‖z - 1‖ ≤ 2) :
    |z.re| ≤ 1 ∧ |z.im| < 2 ∧ (z.re = -1 → z = -1) ∧ (z.re = 1 → z = 1) := by
  have e1 : ‖z + 1‖ ^ 2 = (z.re + 1) ^ 2 + z.im ^ 2 := by
    rw [Complex.sq_norm, Complex.normSq_apply]; simp; ring
  have e2 : ‖z - 1‖ ^ 2 = (z.re - 1) ^ 2 + z.im ^ 2 := by
    rw [Complex.sq_norm, Complex.normSq_apply]; simp; ring
  have f1 : (z.re + 1) ^ 2 + z.im ^ 2 ≤ 4 := by
    rw [← e1]; nlinarith [norm_nonneg (z + 1)]
  have f2 : (z.re - 1) ^ 2 + z.im ^ 2 ≤ 4 := by
    rw [← e2]; nlinarith [norm_nonneg (z - 1)]
  refine ⟨abs_le.2 ⟨by nlinarith [sq_nonneg z.im], by nlinarith [sq_nonneg z.im]⟩,
    abs_lt.2 ⟨by nlinarith [sq_nonneg (z.re)], by nlinarith [sq_nonneg z.re]⟩, ?_, ?_⟩
  · intro h
    have : z.im = 0 := by rw [h] at f2; nlinarith [sq_nonneg z.im]
    exact Complex.ext (by simp [h]) (by simp [this])
  · intro h
    have : z.im = 0 := by rw [h] at f1; nlinarith [sq_nonneg z.im]
    exact Complex.ext (by simp [h]) (by simp [this])

theorem not_bounded_far {J : Set ℂ} {R0 : ℝ} (hK : ∀ z ∈ J, ‖z‖ ≤ R0) :
    ¬ Bornology.IsBounded (connectedComponentIn Jᶜ ((R0 + 1 : ℝ) : ℂ)) := by
  intro hV
  have hfar : R0 < ‖((R0 + 1 : ℝ) : ℂ)‖ := by
    rw [Complex.norm_real, Real.norm_eq_abs]; exact lt_of_lt_of_le (by linarith) (le_abs_self _)
  have hsub := (isPreconnected_norm_gt R0).subset_connectedComponentIn (x := ((R0 + 1 : ℝ) : ℂ))
    hfar (show {z : ℂ | R0 < ‖z‖} ⊆ Jᶜ from fun z hz hzJ => by
      have := hK z hzJ; have : R0 < ‖z‖ := hz; linarith)
  obtain ⟨r, hr⟩ := (hV.subset hsub).subset_closedBall 0
  have hmem : R0 < ‖((max r R0 + 1 : ℝ) : ℂ)‖ := by
    rw [Complex.norm_real, Real.norm_eq_abs]
    exact lt_of_lt_of_le (by linarith [le_max_right r R0]) (le_abs_self _)
  have := hr hmem
  rw [Metric.mem_closedBall, dist_zero_right, Complex.norm_real, Real.norm_eq_abs] at this
  linarith [le_abs_self (max r R0 + 1), le_max_left r R0, abs_le.1 this]

theorem jordan_normalized (Γ : ℝ → ℂ) (hΓ : Continuous Γ) (hper : Function.Periodic Γ 1)
    (hinj : InjOn Γ (Ico 0 1)) {τ : ℝ} (hτ0 : 0 < τ) (hτ1 : τ < 1) (ha : Γ 0 = -1)
    (hb : Γ τ = 1) (hdiam : ∀ z ∈ range Γ, ‖z + 1‖ ≤ 2 ∧ ‖z - 1‖ ≤ 2) :
    ∃ U V : Set ℂ, U ∪ V = (range Γ)ᶜ ∧ Disjoint U V ∧ IsOpen U ∧ IsOpen V ∧
      IsConnected U ∧ IsConnected V ∧ Bornology.IsBounded U ∧ ¬ Bornology.IsBounded V ∧
      frontier U = range Γ ∧ frontier V = range Γ := by
  set J := range Γ with hJdef
  set αn : ℝ → ℂ := fun s => Γ (τ * s) with hαn
  set αs : ℝ → ℂ := fun s => Γ (1 - (1 - τ) * s) with hαs
  have h1τ : 0 < 1 - τ := by linarith
  have hJn : αn '' Icc 0 1 = Γ '' Icc 0 τ := by
    ext z; constructor
    · rintro ⟨s, hs, rfl⟩; exact ⟨τ * s, ⟨by nlinarith [hs.1], by nlinarith [hs.2]⟩, rfl⟩
    · rintro ⟨u, hu, rfl⟩
      refine ⟨u / τ, ⟨div_nonneg hu.1 hτ0.le, (div_le_one hτ0).2 hu.2⟩, ?_⟩
      show Γ (τ * (u / τ)) = Γ u
      rw [mul_div_cancel₀ _ hτ0.ne']
  have hJs : αs '' Icc 0 1 = Γ '' Icc τ 1 := by
    ext z; constructor
    · rintro ⟨s, hs, rfl⟩
      exact ⟨1 - (1 - τ) * s, ⟨by nlinarith [hs.2], by nlinarith [hs.1]⟩, rfl⟩
    · rintro ⟨u, hu, rfl⟩
      refine ⟨(1 - u) / (1 - τ), ⟨div_nonneg (by linarith [hu.2]) h1τ.le,
        (div_le_one h1τ).2 (by linarith [hu.1])⟩, ?_⟩
      show Γ (1 - (1 - τ) * ((1 - u) / (1 - τ))) = Γ u
      rw [mul_div_cancel₀ _ h1τ.ne']; congr 1; ring
  have hJ : J = αn '' Icc 0 1 ∪ αs '' Icc 0 1 := by
    rw [hJn, hJs, ← image_union, Icc_union_Icc_eq_Icc hτ0.le hτ1.le, periodic_image Γ hper]
  have hΓ1 : Γ 1 = -1 := by rw [← ha]; simpa using hper 0
  have hcn : Continuous αn := by fun_prop
  have hcs : Continuous αs := by fun_prop
  have h0n : αn 0 = -1 := by simp [αn, ha]
  have h1n : αn 1 = 1 := by simp [αn, hb]
  have h0s : αs 0 = -1 := by simp [αs, hΓ1]
  have h1s : αs 1 = 1 := by
    show Γ (1 - (1 - τ) * 1) = 1; rw [show (1:ℝ) - (1 - τ) * 1 = τ by ring, hb]
  have hinjn : InjOn αn (Icc 0 1) := by
    intro s hs t ht h
    have := hinj ⟨by nlinarith [hs.1], by nlinarith [hs.2]⟩
      ⟨by nlinarith [ht.1], by nlinarith [ht.2]⟩ h
    exact mul_left_cancel₀ hτ0.ne' this
  have hinjs : InjOn αs (Icc 0 1) := by
    intro s hs t ht h
    have := inj_shift Γ hper hinj τ ⟨by nlinarith [hs.2], by nlinarith [hs.1]⟩
      ⟨by nlinarith [ht.2], by nlinarith [ht.1]⟩ h
    have : (1 - τ) * s = (1 - τ) * t := by linarith
    exact mul_left_cancel₀ h1τ.ne' this
  have hcap : ∀ z, z ∈ αn '' Icc 0 1 → z ∈ αs '' Icc 0 1 → z = -1 ∨ z = 1 := by
    intro z h1 h2
    rw [hJn] at h1; rw [hJs] at h2
    obtain ⟨u, hu, rfl⟩ := h1
    obtain ⟨w, hw, hwu⟩ := h2
    rcases eq_or_lt_of_le hw.2 with h | h
    · left; rw [← hwu, h, hΓ1]
    · have := hinj ⟨hw.1.trans' hτ0.le, h⟩ ⟨hu.1, by linarith [hu.2]⟩ hwu
      right; rw [← hb]; congr 1; linarith [hu.2, hw.1]
  have hbox : ∀ z ∈ J, |z.re| ≤ 1 ∧ |z.im| < 2 ∧ (z.re = -1 → z = -1) ∧ (z.re = 1 → z = 1) :=
    fun z hz => box_of_diam z (hdiam z hz).1 (hdiam z hz).2
  have hm1J : (-1 : ℂ) ∈ J := ⟨0, ha⟩
  have hp1J : (1 : ℂ) ∈ J := ⟨τ, hb⟩
  have hcl : ∀ x ∉ J, (-1 : ℂ) ∈ closure (connectedComponentIn Jᶜ x) ∧
      (1 : ℂ) ∈ closure (connectedComponentIn Jᶜ x) := by
    intro x hx
    have hfr := jordan_frontier Γ hΓ hper hinj hx
    exact ⟨frontier_subset_closure (hfr ▸ hm1J), frontier_subset_closure (hfr ▸ hp1J)⟩
  have key : ∃ z0, z0 ∉ J ∧ Bornology.IsBounded (connectedComponentIn Jᶜ z0) ∧
      ∀ w, w ∉ J → Bornology.IsBounded (connectedComponentIn Jᶜ w) →
        connectedComponentIn Jᶜ w = connectedComponentIn Jᶜ z0 := by
    by_cases hm : ∀ y : ℝ, (y : ℂ) * I ∈ αs '' Icc 0 1 →
        ∃ y', y ≤ y' ∧ (y' : ℂ) * I ∈ αn '' Icc 0 1
    · have := maehara_core αn αs hcn hcs h0n h1n h0s h1s hinjn hinjs hcap
        (by rw [← hJ]; exact hbox) (by rw [← hJ]; exact hcl) hm
      rwa [← hJ] at this
    · push Not at hm
      obtain ⟨y0, hy0s, hy0⟩ := hm
      have hm' : ∀ y : ℝ, (y : ℂ) * I ∈ αn '' Icc 0 1 →
          ∃ y', y ≤ y' ∧ (y' : ℂ) * I ∈ αs '' Icc 0 1 := by
        intro y hy; refine ⟨y0, ?_, hy0s⟩
        by_contra hlt; push Not at hlt; exact hy0 y hlt.le hy
      have hJ' : J = αs '' Icc 0 1 ∪ αn '' Icc 0 1 := by rw [hJ, union_comm]
      have := maehara_core αs αn hcs hcn h0s h1s h0n h1n hinjs hinjn
        (fun z h1 h2 => hcap z h2 h1) (by rw [← hJ']; exact hbox) (by rw [← hJ']; exact hcl) hm'
      rwa [← hJ'] at this
  obtain ⟨z0, hz0, hbd, huniq⟩ := key
  have hJc : IsCompact J := by rw [hJdef, ← periodic_image Γ hper]; exact isCompact_Icc.image hΓ
  obtain ⟨R0, hR0⟩ := hJc.isBounded.subset_closedBall 0
  have hK : ∀ z ∈ J, ‖z‖ ≤ R0 := fun z hz => by simpa using hR0 hz
  have hfar : ((R0 + 1 : ℝ) : ℂ) ∉ J := fun h => by
    have h1 := hK _ h
    rw [Complex.norm_real, Real.norm_eq_abs] at h1
    linarith [le_abs_self (R0 + 1)]
  have hVunb := not_bounded_far hK
  refine ⟨connectedComponentIn Jᶜ z0, connectedComponentIn Jᶜ ((R0 + 1 : ℝ) : ℂ), ?_, ?_,
    hJc.isClosed.isOpen_compl.connectedComponentIn, hJc.isClosed.isOpen_compl.connectedComponentIn,
    isConnected_connectedComponentIn_iff.2 hz0, isConnected_connectedComponentIn_iff.2 hfar,
    hbd, hVunb, jordan_frontier Γ hΓ hper hinj hz0, jordan_frontier Γ hΓ hper hinj hfar⟩
  · apply Subset.antisymm
    · exact union_subset (connectedComponentIn_subset _ _) (connectedComponentIn_subset _ _)
    · intro y hy
      by_cases hyb : Bornology.IsBounded (connectedComponentIn Jᶜ y)
      · left; rw [← huniq y hy hyb]; exact mem_connectedComponentIn hy
      · right; rw [← comp_eq_far hK hyb]; exact mem_connectedComponentIn hy
  · rw [Set.disjoint_left]; intro z hzU hzV
    apply hVunb
    rw [connectedComponentIn_eq hzV, ← connectedComponentIn_eq hzU]; exact hbd

theorem isBounded_image_of_bound {X Y : Type*} [SeminormedAddCommGroup X]
    [SeminormedAddCommGroup Y] (f : X → Y) (C D : ℝ) (hC : 0 ≤ C)
    (hf : ∀ x, ‖f x‖ ≤ C * ‖x‖ + D) (s : Set X) (hs : Bornology.IsBounded s) :
    Bornology.IsBounded (f '' s) := by
  obtain ⟨r, hr⟩ := isBounded_iff_forall_norm_le.1 hs
  refine isBounded_iff_forall_norm_le.2 ⟨C * r + D, ?_⟩
  rintro _ ⟨x, hx, rfl⟩
  calc ‖f x‖ ≤ C * ‖x‖ + D := hf x
    _ ≤ C * r + D := by gcongr; exact hr x hx

theorem transfer_props {X Y : Type*} [PseudoMetricSpace X] [PseudoMetricSpace Y] (h : X ≃ₜ Y)
    (hb : ∀ s : Set X, Bornology.IsBounded s → Bornology.IsBounded (h '' s))
    (hb' : ∀ s : Set Y, Bornology.IsBounded s → Bornology.IsBounded (h.symm '' s))
    (J : Set X) (H : ∃ U V : Set X, U ∪ V = Jᶜ ∧ Disjoint U V ∧ IsOpen U ∧ IsOpen V ∧
      IsConnected U ∧ IsConnected V ∧ Bornology.IsBounded U ∧ ¬ Bornology.IsBounded V ∧
      frontier U = J ∧ frontier V = J) :
    ∃ U V : Set Y, U ∪ V = (h '' J)ᶜ ∧ Disjoint U V ∧ IsOpen U ∧ IsOpen V ∧
      IsConnected U ∧ IsConnected V ∧ Bornology.IsBounded U ∧ ¬ Bornology.IsBounded V ∧
      frontier U = h '' J ∧ frontier V = h '' J := by
  obtain ⟨U, V, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10⟩ := H
  refine ⟨h '' U, h '' V, ?_, ?_, h.isOpenMap U h3, h.isOpenMap V h4,
    h5.image h h.continuous.continuousOn, h6.image h h.continuous.continuousOn, hb U h7, ?_, ?_, ?_⟩
  · rw [← image_union, h1, image_compl_eq h.bijective]
  · exact (disjoint_image_iff h.injective).2 h2
  · intro hV; apply h8; have := hb' _ hV; rwa [image_image, show (fun x => h.symm (h x)) = id from funext h.symm_apply_apply, image_id] at this
  · rw [← h.image_frontier, h9]
  · rw [← h.image_frontier, h10]

theorem jordan_complex (Γ : ℝ → ℂ) (hΓ : Continuous Γ) (hper : Function.Periodic Γ 1)
    (hinj : InjOn Γ (Ico 0 1)) :
    ∃ U V : Set ℂ, U ∪ V = (range Γ)ᶜ ∧ Disjoint U V ∧ IsOpen U ∧ IsOpen V ∧
      IsConnected U ∧ IsConnected V ∧ Bornology.IsBounded U ∧ ¬ Bornology.IsBounded V ∧
      frontier U = range Γ ∧ frontier V = range Γ := by
  set J := range Γ with hJdef
  have hJc : IsCompact J := by rw [hJdef, ← periodic_image Γ hper]; exact isCompact_Icc.image hΓ
  obtain ⟨⟨a, b⟩, ⟨haJ, hbJ⟩, hmax⟩ := (hJc.prod hJc).exists_isMaxOn
    ⟨(Γ 0, Γ 0), ⟨⟨0, rfl⟩, ⟨0, rfl⟩⟩⟩
    (continuous_norm.comp (continuous_fst.sub continuous_snd)).continuousOn
  have hmax' : ∀ z ∈ J, ∀ w ∈ J, ‖z - w‖ ≤ ‖a - b‖ := fun z hz w hw =>
    isMaxOn_iff.1 hmax (z, w) ⟨hz, hw⟩
  have hab : a ≠ b := by
    intro h
    have h1 := hmax' (Γ 0) ⟨0, rfl⟩ (Γ (1/2)) ⟨1/2, rfl⟩
    rw [h, sub_self, norm_zero] at h1
    have h2 : Γ 0 = Γ (1/2) := by rw [← sub_eq_zero]; exact norm_le_zero_iff.1 h1
    have := hinj ⟨le_rfl, by norm_num⟩ ⟨by norm_num, by norm_num⟩ h2
    norm_num at this
  obtain ⟨ta, rfl⟩ := haJ
  obtain ⟨tb, rfl⟩ := hbJ
  -- shift the parameter so that the curve starts at `Γ ta`
  set Γ1 : ℝ → ℂ := fun t => Γ (t + ta) with hΓ1
  have hΓ1c : Continuous Γ1 := by fun_prop
  have hper1 : Function.Periodic Γ1 1 := fun t => by
    show Γ (t + 1 + ta) = Γ (t + ta); rw [add_right_comm]; exact hper _
  have hinj1 : InjOn Γ1 (Ico 0 1) := by
    intro s hs t ht h
    have := inj_shift Γ hper hinj ta ⟨by linarith [hs.1], by linarith [hs.2]⟩
      ⟨by linarith [ht.1], by linarith [ht.2]⟩ h
    linarith
  have hr1 : range Γ1 = J := by
    apply Subset.antisymm
    · rintro _ ⟨t, rfl⟩; exact ⟨t + ta, rfl⟩
    · rintro _ ⟨t, rfl⟩; exact ⟨t - ta, by simp [Γ1]⟩
  set τ := Int.fract (tb - ta) with hτ
  have hΓ1τ : Γ1 τ = Γ tb := by
    show Γ (Int.fract (tb - ta) + ta) = Γ tb
    have := hper.sub_int_mul_eq (x := tb) ⌊tb - ta⌋
    rw [mul_one] at this
    rw [← this, Int.fract]; congr 1; ring
  have hΓ10 : Γ1 0 = Γ ta := by simp [Γ1]
  have hτ0 : 0 < τ := by
    refine lt_of_le_of_ne (Int.fract_nonneg _) (fun h => hab ?_)
    rw [← hΓ10, ← hΓ1τ, ← h]
  have hτ1 : τ < 1 := Int.fract_lt_one _
  -- the affine change of coordinates sending `Γ ta` to `-1` and `Γ tb` to `1`
  set a := Γ ta with ha
  set b := Γ tb with hb
  have hba : b - a ≠ 0 := sub_ne_zero.2 (Ne.symm hab)
  have h2 : (2 : ℂ) ≠ 0 := two_ne_zero
  let h : ℂ ≃ₜ ℂ :=
    { toFun := fun z => (b - a) / 2 * z + (a + b) / 2
      invFun := fun z => 2 / (b - a) * z + -((a + b) / (b - a))
      left_inv := fun z => by field_simp; ring
      right_inv := fun z => by field_simp; ring
      continuous_toFun := by fun_prop
      continuous_invFun := by fun_prop }
  have hbd : ∀ s : Set ℂ, Bornology.IsBounded s → Bornology.IsBounded (h '' s) := by
    intro s hs
    refine isBounded_image_of_bound h ‖(b - a) / 2‖ ‖(a + b) / 2‖ (norm_nonneg _) (fun z => ?_) s hs
    show ‖(b - a) / 2 * z + (a + b) / 2‖ ≤ _
    exact (norm_add_le _ _).trans (by rw [norm_mul])
  have hbd' : ∀ s : Set ℂ, Bornology.IsBounded s → Bornology.IsBounded (h.symm '' s) := by
    intro s hs
    refine isBounded_image_of_bound h.symm ‖2 / (b - a)‖ ‖-((a + b) / (b - a))‖ (norm_nonneg _)
      (fun z => ?_) s hs
    show ‖2 / (b - a) * z + -((a + b) / (b - a))‖ ≤ _
    exact (norm_add_le _ _).trans (by rw [norm_mul])
  set Γ2 : ℝ → ℂ := fun t => h.symm (Γ1 t) with hΓ2
  have hΓ2c : Continuous Γ2 := h.symm.continuous.comp hΓ1c
  have hper2 : Function.Periodic Γ2 1 := fun t => by simp only [Γ2]; rw [hper1 t]
  have hinj2 : InjOn Γ2 (Ico 0 1) := fun s hs t ht hst => hinj1 hs ht (h.symm.injective hst)
  have hΓ20 : Γ2 0 = -1 := by
    show 2 / (b - a) * Γ1 0 + -((a + b) / (b - a)) = -1
    rw [hΓ10]; field_simp; ring
  have hΓ2τ : Γ2 τ = 1 := by
    show 2 / (b - a) * Γ1 τ + -((a + b) / (b - a)) = 1
    rw [hΓ1τ]; field_simp; ring
  have hdiam : ∀ z ∈ range Γ2, ‖z + 1‖ ≤ 2 ∧ ‖z - 1‖ ≤ 2 := by
    rintro _ ⟨t, rfl⟩
    have hw : Γ1 t ∈ J := hr1 ▸ ⟨t, rfl⟩
    set w := Γ1 t
    have hpos : 0 < ‖b - a‖ := norm_pos_iff.2 hba
    have e1 : Γ2 t + 1 = 2 * (w - a) / (b - a) := by
      show 2 / (b - a) * w + -((a + b) / (b - a)) + 1 = _; field_simp; ring
    have e2 : Γ2 t - 1 = 2 * (w - b) / (b - a) := by
      show 2 / (b - a) * w + -((a + b) / (b - a)) - 1 = _; field_simp; ring
    have n2 : ‖(2 : ℂ)‖ = 2 := by simp
    rw [e1, e2, norm_div, norm_div, norm_mul, norm_mul, n2]
    have k1 := hmax' w hw a ⟨ta, rfl⟩
    have k2 := hmax' w hw b ⟨tb, rfl⟩
    rw [norm_sub_rev a b] at k1 k2
    constructor <;> rw [div_le_iff₀ hpos] <;> linarith
  obtain H := jordan_normalized Γ2 hΓ2c hper2 hinj2 hτ0 hτ1 hΓ20 hΓ2τ hdiam
  have hJ2 : h '' range Γ2 = J := by
    rw [← range_comp, ← hr1]
    congr 1; funext t; simp [Γ2]
  have := transfer_props h hbd hbd' (range Γ2) H
  rwa [hJ2] at this

#print axioms exists_log_of_ne_zero
#print axioms cos_nonpos_band
#print axioms arg_band
#print axioms int_nonpos_of
#print axioms box_zero
#print axioms ray_left_closed
#print axioms ray_right_closed
#print axioms sep_barrier
#print axioms no_log_on_circle
#print axioms mem_comp_of_mem_closure
#print axioms frontier_comp_subset
#print axioms isPreconnected_norm_gt
#print axioms comp_eq_far
#print axioms arc_comp_unbounded
#print axioms arc_compl_isConnected
#print axioms maehara_core
#print axioms inj_shift
#print axioms periodic_image
#print axioms jordan_frontier
#print axioms box_of_diam
#print axioms not_bounded_far
#print axioms jordan_normalized
#print axioms isBounded_image_of_bound
#print axioms transfer_props
#print axioms jordan_complex

end JordanAux

open Set unitInterval

/-- Jordan curve theorem. Let `γ` trace a simple closed curve `J` in the plane: it is continuous
on the time interval `[0, 1]`, it closes (`γ 0 = γ 1`), and two different times give the same
point only when they are the two ends `0` and `1`. Then the plane minus `J` is exactly two
pieces that do not overlap: an inside `U` and an outside `V`. Each is open and connected, the
inside is bounded, the outside is not, and the boundary of each is the whole curve `J`. -/
theorem jordan_curve_theorem (γ : I → EuclideanSpace ℝ (Fin 2)) (hγ : Continuous γ)
    (hclosed : γ 0 = γ 1)
    (hsimple : ∀ s t : I, s < t → γ s = γ t → s = 0 ∧ t = 1) :
    ∃ U V : Set (EuclideanSpace ℝ (Fin 2)),
      U ∪ V = (range γ)ᶜ ∧ Disjoint U V ∧
      IsOpen U ∧ IsOpen V ∧ IsConnected U ∧ IsConnected V ∧
      Bornology.IsBounded U ∧ ¬ Bornology.IsBounded V ∧
      frontier U = range γ ∧ frontier V = range γ := by
  set e := Complex.orthonormalBasisOneI.repr with he
  set f : ℝ → EuclideanSpace ℝ (Fin 2) := fun t => γ (projIcc 0 1 zero_le_one t) with hfdef
  have hf : Continuous f := hγ.comp continuous_projIcc
  have hf01 : f 0 = f 1 := by
    simp only [f]
    rw [projIcc_left, projIcc_right]
    exact hclosed
  set Γ : ℝ → ℂ := fun t => e.symm (f (Int.fract t)) with hΓdef
  have hΓc : Continuous Γ :=
    e.symm.continuous.comp (ContinuousOn.comp_fract'' (f := f) hf.continuousOn hf01)
  have hper : Function.Periodic Γ 1 := fun t => by simp only [Γ, Int.fract_add_one]
  have hinj : InjOn Γ (Ico 0 1) := by
    intro s hs t ht hst
    have h1 : f s = f t := by
      have := e.symm.injective hst
      rwa [Int.fract_eq_self.2 hs, Int.fract_eq_self.2 ht] at this
    simp only [f] at h1
    rw [projIcc_of_mem _ (Ico_subset_Icc_self hs), projIcc_of_mem _ (Ico_subset_Icc_self ht)] at h1
    by_contra hne
    rcases lt_or_gt_of_ne hne with hlt | hlt
    · have := hsimple _ _ (show (⟨s, Ico_subset_Icc_self hs⟩ : I) <
        ⟨t, Ico_subset_Icc_self ht⟩ from hlt) h1
      have := congrArg Subtype.val this.2
      simp at this; linarith [ht.2]
    · have := hsimple _ _ (show (⟨t, Ico_subset_Icc_self ht⟩ : I) <
        ⟨s, Ico_subset_Icc_self hs⟩ from hlt) h1.symm
      have := congrArg Subtype.val this.2
      simp at this; linarith [hs.2]
  have hrange : e '' range Γ = range γ := by
    ext z; constructor
    · rintro ⟨_, ⟨t, rfl⟩, rfl⟩
      exact ⟨projIcc 0 1 zero_le_one (Int.fract t), by simp [Γ, f]⟩
    · rintro ⟨u, rfl⟩
      by_cases hu : (u : ℝ) < 1
      · refine ⟨Γ u, ⟨u, rfl⟩, ?_⟩
        simp only [Γ, f, LinearIsometryEquiv.apply_symm_apply]
        rw [Int.fract_eq_self.2 ⟨u.2.1, hu⟩, projIcc_val]
      · have hu1 : u = 1 := Subtype.ext (le_antisymm u.2.2 (not_lt.1 hu))
        refine ⟨Γ 0, ⟨0, rfl⟩, ?_⟩
        simp only [Γ, f, LinearIsometryEquiv.apply_symm_apply, Int.fract_zero]
        rw [hu1, projIcc_left]
        exact hclosed
  have H := JordanAux.transfer_props e.toHomeomorph
    (fun s hs => JordanAux.isBounded_image_of_bound _ 1 0 zero_le_one (fun x => by simp) s hs)
    (fun s hs => JordanAux.isBounded_image_of_bound _ 1 0 zero_le_one (fun x => by simp) s hs)
    (range Γ) (JordanAux.jordan_complex Γ hΓc hper hinj)
  rw [show (e.toHomeomorph : ℂ → EuclideanSpace ℝ (Fin 2)) '' range Γ = range γ from hrange] at H
  exact H

/-- An arc never separates the plane: if `γ` is continuous on `[0, 1]` and never meets itself
(the curve does not close), then the plane minus the arc is in one piece. -/
theorem arc_does_not_separate_plane (γ : I → EuclideanSpace ℝ (Fin 2)) (hγ : Continuous γ)
    (hinj : Function.Injective γ) :
    IsConnected (range γ)ᶜ := by
  set e := Complex.orthonormalBasisOneI.repr with he
  set f : ℝ → ℂ := fun t => e.symm (γ (projIcc 0 1 zero_le_one t)) with hfdef
  have hf : Continuous f := e.symm.continuous.comp (hγ.comp continuous_projIcc)
  have hinj' : InjOn f (Icc 0 1) := by
    intro s hs t ht hst
    have h1 := hinj (e.symm.injective hst)
    rw [projIcc_of_mem _ hs, projIcc_of_mem _ ht] at h1
    exact congrArg Subtype.val h1
  have himg : e '' (f '' Icc 0 1) = range γ := by
    ext z; constructor
    · rintro ⟨_, ⟨t, -, rfl⟩, rfl⟩; simp [f]
    · rintro ⟨u, rfl⟩; exact ⟨f u, ⟨u, u.2, rfl⟩, by simp [f]⟩
  have hc := (JordanAux.arc_compl_isConnected f hf zero_le_one hinj').image e
    e.continuous.continuousOn
  rwa [image_compl_eq e.bijective, himg] at hc

/-! Worked numbers from the card, checked exactly. -/

-- The field with a 4 m neck: twice the shoelace area over the 16 corners is 2 × 3564 m².
example :
    let F : List (ℤ × ℤ) := [(0, 0), (80, 0), (80, 50), (60, 50), (42, 50), (42, 44), (50, 40),
      (52, 30), (46, 22), (34, 22), (28, 30), (30, 40), (38, 44), (38, 50), (20, 50), (0, 50)]
    (List.zipWith (fun p q => p.1 * q.2 - q.1 * p.2) F (F.rotate 1)).sum = 2 * 3564 := by
  decide

-- The neck closed to 0 m: the cut-off lake has shoelace area 404 m² (its corners run clockwise).
example :
    let L : List (ℤ × ℤ) := [(40, 44), (50, 40), (52, 30), (46, 22), (34, 22), (28, 30), (30, 40)]
    (List.zipWith (fun p q => p.1 * q.2 - q.1 * p.2) L (L.rotate 1)).sum = -(2 * 404) := by
  decide

-- Corners entered south-west, south-east, north-west, north-east: shoelace area 0 m².
example :
    let R : List (ℤ × ℤ) := [(0, 0), (80, 0), (0, 50), (80, 50)]
    (List.zipWith (fun p q => p.1 * q.2 - q.1 * p.2) R (R.rotate 1)).sum = 0 := by
  decide

-- The 90 by 60 grid splits into 3564 inside points and 1836 outside points.
example : 3564 + 1836 = 90 * 60 := by norm_num

-- Euler's count for the field: F = 2 - V + E with 16 corners and 16 runs gives 2 faces.
example : (2 : ℤ) - 16 + 16 = 2 := by norm_num

-- K₃,₃ has 9 edges and no triangle.
instance : DecidableRel (completeBipartiteGraph (Fin 3) (Fin 3)).Adj := fun v w =>
  inferInstanceAs (Decidable (v.isLeft ∧ w.isRight ∨ v.isRight ∧ w.isLeft))
example : (completeBipartiteGraph (Fin 3) (Fin 3)).edgeFinset.card = 9 := by decide
example : ∀ a b c : Fin 3 ⊕ Fin 3, (completeBipartiteGraph (Fin 3) (Fin 3)).Adj a b →
    (completeBipartiteGraph (Fin 3) (Fin 3)).Adj b c →
    ¬ (completeBipartiteGraph (Fin 3) (Fin 3)).Adj a c := by decide

-- K₃,₃ drawn flat would need F = 2 - 6 + 9 = 5 faces, but 4F ≤ 2E = 18 allows at most 9/2.
example : (2 : ℤ) - 6 + 9 = 5 ∧ ¬ (4 * 5 ≤ 2 * 9) := by norm_num

-- Koch snowflake: perimeter 270 · (4/3)^n and area 8/5 - (3/5)(4/9)^n triangles.
example : (270 : ℚ) * (4 / 3) ^ 1 = 360 ∧ (270 : ℚ) * (4 / 3) ^ 2 = 480 ∧
    (270 : ℚ) * (4 / 3) ^ 5 = 10240 / 9 := by norm_num
example : (8 / 5 : ℚ) - 3 / 5 * (4 / 9) ^ 0 = 1 ∧ (8 / 5 : ℚ) - 3 / 5 * (4 / 9) ^ 1 = 4 / 3 ∧
    (8 / 5 : ℚ) - 3 / 5 * (4 / 9) ^ 2 = 40 / 27 ∧
    (8 / 5 : ℚ) - 3 / 5 * (4 / 9) ^ 5 = 31288 / 19683 := by norm_num

#print axioms jordan_curve_theorem
#print axioms arc_does_not_separate_plane
