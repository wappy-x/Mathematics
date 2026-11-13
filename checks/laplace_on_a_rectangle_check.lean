-- Laplace on a rectangle: every sum of sine-across, sinh-up waves solves u_xx + u_yy = 0 on a W by H plate, is 0 on three edges and matches its sine sum on the top edge; a 100 C edge has sine coefficients 400/(nπ) for odd n and 0 for even n; and a settled temperature is fixed by its edge values.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Real Finset

open Filter Topology in
lemma lap_aux_second_deriv_nonpos {f : ℝ → ℝ} {x₀ : ℝ} (hmax : IsLocalMax f x₀)
    (hc : ContinuousAt f x₀) : deriv (deriv f) x₀ ≤ 0 := by
  by_contra h
  push Not at h
  have hd := hmax.deriv_eq_zero
  have hmin := isLocalMin_of_deriv_deriv_pos h hd hc
  have heq : f =ᶠ[𝓝 x₀] fun _ => f x₀ :=
    (hmin.and hmax).mono fun x hx => le_antisymm hx.2 hx.1
  have h2 : deriv (deriv f) x₀ = deriv (deriv fun _ : ℝ => f x₀) x₀ := heq.deriv.deriv_eq
  simp at h2
  linarith

open Filter Topology in
lemma lap_aux_combo {φ ψ : ℝ → ℝ} {U : Set ℝ} (hU : IsOpen U) (hφ : ContDiffOn ℝ 2 φ U)
    (hψ : ContDiffOn ℝ 2 ψ U) (c d : ℝ) {x : ℝ} (hx : x ∈ U) :
    deriv (deriv (fun s => φ s - ψ s + c * s ^ 2 + d)) x
        = deriv (deriv φ) x - deriv (deriv ψ) x + 2 * c ∧
      ContinuousAt (fun s => φ s - ψ s + c * s ^ 2 + d) x := by
  have hφd : DifferentiableOn ℝ φ U := hφ.differentiableOn (by norm_num)
  have hψd : DifferentiableOn ℝ ψ U := hψ.differentiableOn (by norm_num)
  have hφ' : ContDiffOn ℝ 1 (deriv φ) U := hφ.deriv_of_isOpen hU (by norm_num)
  have hψ' : ContDiffOn ℝ 1 (deriv ψ) U := hψ.deriv_of_isOpen hU (by norm_num)
  have hφ'd := (hφ'.differentiableOn (by norm_num)).differentiableAt (hU.mem_nhds hx)
  have hψ'd := (hψ'.differentiableOn (by norm_num)).differentiableAt (hU.mem_nhds hx)
  have hU' : U ∈ 𝓝 x := hU.mem_nhds hx
  have heq : deriv (fun s => φ s - ψ s + c * s ^ 2 + d) =ᶠ[𝓝 x]
      fun s => deriv φ s - deriv ψ s + c * (2 * s) := by
    filter_upwards [hU'] with s hs
    have a := (hφd.differentiableAt (hU.mem_nhds hs)).hasDerivAt
    have b := (hψd.differentiableAt (hU.mem_nhds hs)).hasDerivAt
    have := ((a.sub b).add ((hasDerivAt_pow 2 s).const_mul c)).add_const d
    refine this.deriv.trans ?_
    norm_num
  refine ⟨?_, ?_⟩
  · rw [heq.deriv_eq]
    have := (hφ'd.hasDerivAt.sub hψ'd.hasDerivAt).add ((hasDerivAt_id x).const_mul (c * 2))
    have h2 := this.deriv
    convert h2 using 1
    · congr 1
      funext s
      simp
      ring
    · simp
      ring
  · have a := (hφd.differentiableAt hU').continuousAt
    have b := (hψd.differentiableAt hU').continuousAt
    fun_prop

open Filter Topology in
lemma lap_aux_le (W H : ℝ) (hW : 0 < W) (hH : 0 < H)
    (u v : ℝ → ℝ → ℝ)
    (hu_cont : ContinuousOn (Function.uncurry u) (Set.Icc 0 W ×ˢ Set.Icc 0 H))
    (hv_cont : ContinuousOn (Function.uncurry v) (Set.Icc 0 W ×ˢ Set.Icc 0 H))
    (hu_C2 : ContDiffOn ℝ 2 (Function.uncurry u) (Set.Ioo 0 W ×ˢ Set.Ioo 0 H))
    (hv_C2 : ContDiffOn ℝ 2 (Function.uncurry v) (Set.Ioo 0 W ×ˢ Set.Ioo 0 H))
    (hu_lap : ∀ x ∈ Set.Ioo 0 W, ∀ y ∈ Set.Ioo 0 H,
      deriv (fun s => deriv (fun r => u r y) s) x + deriv (fun s => deriv (fun r => u x r) s) y = 0)
    (hv_lap : ∀ x ∈ Set.Ioo 0 W, ∀ y ∈ Set.Ioo 0 H,
      deriv (fun s => deriv (fun r => v r y) s) x + deriv (fun s => deriv (fun r => v x r) s) y = 0)
    (h_bottom_top : ∀ x ∈ Set.Icc 0 W, u x 0 = v x 0 ∧ u x H = v x H)
    (h_sides : ∀ y ∈ Set.Icc 0 H, u 0 y = v 0 y ∧ u W y = v W y) :
    ∀ x ∈ Set.Icc 0 W, ∀ y ∈ Set.Icc 0 H, u x y ≤ v x y := by
  set K : Set (ℝ × ℝ) := Set.Icc 0 W ×ˢ Set.Icc 0 H with hK
  have hKc : IsCompact K := isCompact_Icc.prod isCompact_Icc
  have hKne : K.Nonempty := ⟨(0, 0), ⟨⟨le_refl _, hW.le⟩, ⟨le_refl _, hH.le⟩⟩⟩
  -- the perturbed bound
  have key : ∀ ε > 0, ∀ x ∈ Set.Icc 0 W, ∀ y ∈ Set.Icc 0 H, u x y - v x y ≤ ε * W ^ 2 := by
    intro ε hε
    let G : ℝ × ℝ → ℝ := fun p => u p.1 p.2 - v p.1 p.2 + ε * p.1 ^ 2
    have hGc : ContinuousOn G K := by
      have h1 : ContinuousOn (fun p : ℝ × ℝ => ε * p.1 ^ 2) K := by fun_prop
      exact (hu_cont.sub hv_cont).add h1
    obtain ⟨p, hpK, hpmax⟩ := hKc.exists_isMaxOn hKne hGc
    have hGp : G p ≤ ε * W ^ 2 := by
      obtain ⟨⟨hx0, hxW⟩, ⟨hy0, hyH⟩⟩ := hpK
      have hsq : ε * p.1 ^ 2 ≤ ε * W ^ 2 := by
        apply mul_le_mul_of_nonneg_left _ hε.le
        exact pow_le_pow_left₀ hx0 hxW 2
      by_cases hint : p.1 ∈ Set.Ioo 0 W ∧ p.2 ∈ Set.Ioo 0 H
      · exfalso
        obtain ⟨hx, hy⟩ := hint
        have hxU : p.1 ∈ Set.Ioo (0 : ℝ) W := hx
        -- x direction
        have hφu : ContDiffOn ℝ 2 (fun r => u r p.2) (Set.Ioo 0 W) :=
          hu_C2.comp (by fun_prop : ContDiff ℝ 2 fun s : ℝ => (s, p.2)).contDiffOn
            (fun s hs => ⟨hs, hy⟩)
        have hφv : ContDiffOn ℝ 2 (fun r => v r p.2) (Set.Ioo 0 W) :=
          hv_C2.comp (by fun_prop : ContDiff ℝ 2 fun s : ℝ => (s, p.2)).contDiffOn
            (fun s hs => ⟨hs, hy⟩)
        have hψu : ContDiffOn ℝ 2 (fun r => u p.1 r) (Set.Ioo 0 H) :=
          hu_C2.comp (by fun_prop : ContDiff ℝ 2 fun s : ℝ => (p.1, s)).contDiffOn
            (fun s hs => ⟨hx, hs⟩)
        have hψv : ContDiffOn ℝ 2 (fun r => v p.1 r) (Set.Ioo 0 H) :=
          hv_C2.comp (by fun_prop : ContDiff ℝ 2 fun s : ℝ => (p.1, s)).contDiffOn
            (fun s hs => ⟨hx, hs⟩)
        obtain ⟨hdx, hcx⟩ := lap_aux_combo isOpen_Ioo hφu hφv ε 0 hx
        obtain ⟨hdy, hcy⟩ := lap_aux_combo isOpen_Ioo hψu hψv 0 (ε * p.1 ^ 2) hy
        have hmx : IsLocalMax (fun s => u s p.2 - v s p.2 + ε * s ^ 2 + 0) p.1 := by
          filter_upwards [isOpen_Ioo.mem_nhds hx] with s hs
          have := hpmax (show (s, p.2) ∈ K from ⟨Set.Ioo_subset_Icc_self hs,
            Set.Ioo_subset_Icc_self hy⟩)
          simpa [G] using this
        have hmy : IsLocalMax (fun s => u p.1 s - v p.1 s + 0 * s ^ 2 + ε * p.1 ^ 2) p.2 := by
          filter_upwards [isOpen_Ioo.mem_nhds hy] with s hs
          have := hpmax (show (p.1, s) ∈ K from ⟨Set.Ioo_subset_Icc_self hx,
            Set.Ioo_subset_Icc_self hs⟩)
          simpa [G] using this
        have ax := lap_aux_second_deriv_nonpos hmx hcx
        have ay := lap_aux_second_deriv_nonpos hmy hcy
        have lu := hu_lap p.1 hx p.2 hy
        have lv := hv_lap p.1 hx p.2 hy
        rw [hdx] at ax
        rw [hdy] at ay
        linarith
      · have hb : u p.1 p.2 = v p.1 p.2 := by
          rw [not_and_or] at hint
          rcases hint with h | h
          · have : p.1 = 0 ∨ p.1 = W := by
              by_contra hc
              push Not at hc
              exact h ⟨lt_of_le_of_ne hx0 (Ne.symm hc.1), lt_of_le_of_ne hxW hc.2⟩
            rcases this with e | e
            · rw [e]; exact (h_sides p.2 ⟨hy0, hyH⟩).1
            · rw [e]; exact (h_sides p.2 ⟨hy0, hyH⟩).2
          · have : p.2 = 0 ∨ p.2 = H := by
              by_contra hc
              push Not at hc
              exact h ⟨lt_of_le_of_ne hy0 (Ne.symm hc.1), lt_of_le_of_ne hyH hc.2⟩
            rcases this with e | e
            · rw [e]; exact (h_bottom_top p.1 ⟨hx0, hxW⟩).1
            · rw [e]; exact (h_bottom_top p.1 ⟨hx0, hxW⟩).2
        simp only [G, hb]
        linarith
    intro x hx y hy
    have := hpmax (show (x, y) ∈ K from ⟨hx, hy⟩)
    simp only [Set.mem_ofPred_eq, G] at this
    have : 0 ≤ ε * x ^ 2 := by positivity
    linarith
  intro x hx y hy
  by_contra hlt
  push Not at hlt
  have hW2 : 0 < W ^ 2 := by positivity
  have := key ((u x y - v x y) / (2 * W ^ 2)) (by apply div_pos <;> linarith) x hx y hy
  rw [div_mul_eq_mul_div, mul_div_assoc, show W ^ 2 / (2 * W ^ 2) = 1 / 2 by field_simp] at this
  linarith

#print axioms lap_aux_second_deriv_nonpos
#print axioms lap_aux_combo
#print axioms lap_aux_le

/-- **Separation on a rectangle, the card's main claim (Steps 1 to 4).** Take a plate W wide and
H high, with W > 0 and H > 0. For any sizes b_1, …, b_N, the sum of waves
`u(x, y) = ∑_{n=1}^{N} b_n sin(nπx/W) · sinh(nπy/W) / sinh(nπH/W)`
is smooth, solves Laplace's equation `u_xx + u_yy = 0` at every point, is 0 on the left edge
(x = 0), the right edge (x = W) and the bottom edge (y = 0), and on the top edge (y = H) reads
the sine sum `∑ b_n sin(nπx/W)`: the sines come from the two cold facing sides, the sinh from
the cold bottom, and dividing by sinh(nπH/W) makes each wave read its full size at the top. -/
theorem sine_sinh_sum_solves_laplace_on_rectangle (W H : ℝ) (hW : 0 < W) (hH : 0 < H)
    (N : ℕ) (b : ℕ → ℝ) :
    let u : ℝ → ℝ → ℝ := fun x y =>
      ∑ n ∈ Icc 1 N, b n * sin (n * π * x / W) * (sinh (n * π * y / W) / sinh (n * π * H / W))
    ContDiff ℝ 2 (Function.uncurry u) ∧
    (∀ x y : ℝ, deriv (fun s => deriv (fun r => u r y) s) x
        + deriv (fun s => deriv (fun r => u x r) s) y = 0) ∧
    (∀ y : ℝ, u 0 y = 0 ∧ u W y = 0) ∧
    (∀ x : ℝ, u x 0 = 0) ∧
    (∀ x : ℝ, u x H = ∑ n ∈ Icc 1 N, b n * sin (n * π * x / W)) := by
  intro u
  -- shorthand: k n = nπ/W and S n = sinh(nπH/W)
  have hlin : ∀ (n : ℕ) (t : ℝ), HasDerivAt (fun r : ℝ => n * π * r / W) (n * π / W) t := by
    intro n t
    simpa using ((hasDerivAt_id t).const_mul ((n : ℝ) * π)).div_const W
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · show ContDiff ℝ 2 (fun p : ℝ × ℝ => ∑ n ∈ Icc 1 N, b n * sin (n * π * p.1 / W) *
      (sinh (n * π * p.2 / W) / sinh (n * π * H / W)))
    apply ContDiff.sum
    intro n _
    fun_prop
  · intro x y
    have hx1 : ∀ s, HasDerivAt (fun r => u r y) (∑ n ∈ Icc 1 N, b n * (cos (n * π * s / W) *
        (n * π / W)) * (sinh (n * π * y / W) / sinh (n * π * H / W))) s := by
      intro s
      apply HasDerivAt.fun_sum
      intro n _
      exact (((hlin n s).sin).const_mul (b n)).mul_const _
    have hx2 : HasDerivAt (fun s => deriv (fun r => u r y) s) (∑ n ∈ Icc 1 N, b n *
        ((-sin (n * π * x / W) * (n * π / W)) * (n * π / W)) *
        (sinh (n * π * y / W) / sinh (n * π * H / W))) x := by
      have : (fun s => deriv (fun r => u r y) s) = fun s => ∑ n ∈ Icc 1 N, b n *
          (cos (n * π * s / W) * (n * π / W)) * (sinh (n * π * y / W) / sinh (n * π * H / W)) := by
        funext s; exact (hx1 s).deriv
      rw [this]
      apply HasDerivAt.fun_sum
      intro n _
      exact ((((hlin n x).cos).mul_const _).const_mul (b n)).mul_const _
    have hy1 : ∀ s, HasDerivAt (fun r => u x r) (∑ n ∈ Icc 1 N, b n * sin (n * π * x / W) *
        ((cosh (n * π * s / W) * (n * π / W)) / sinh (n * π * H / W))) s := by
      intro s
      apply HasDerivAt.fun_sum
      intro n _
      exact (((hlin n s).sinh).div_const _).const_mul _
    have hy2 : HasDerivAt (fun s => deriv (fun r => u x r) s) (∑ n ∈ Icc 1 N, b n *
        sin (n * π * x / W) * ((sinh (n * π * y / W) * (n * π / W) * (n * π / W)) /
        sinh (n * π * H / W))) y := by
      have : (fun s => deriv (fun r => u x r) s) = fun s => ∑ n ∈ Icc 1 N, b n *
          sin (n * π * x / W) * ((cosh (n * π * s / W) * (n * π / W)) / sinh (n * π * H / W)) := by
        funext s; exact (hy1 s).deriv
      rw [this]
      apply HasDerivAt.fun_sum
      intro n _
      exact ((((hlin n y).cosh).mul_const _).div_const _).const_mul _
    rw [hx2.deriv, hy2.deriv, ← Finset.sum_add_distrib]
    apply Finset.sum_eq_zero
    intro n _
    ring
  · intro y
    constructor
    · simp [u]
    · apply Finset.sum_eq_zero
      intro n _
      rw [mul_div_assoc, div_self hW.ne', mul_one, sin_nat_mul_pi]
      ring
  · intro x
    simp [u]
  · intro x
    apply Finset.sum_congr rfl
    intro n hn
    have hn1 : 1 ≤ n := (Finset.mem_Icc.mp hn).1
    have hpos : 0 < sinh (n * π * H / W) := by
      rw [sinh_pos_iff]
      have : (0 : ℝ) < n := by exact_mod_cast hn1
      positivity
    rw [div_self hpos.ne', mul_one]

/-- **The hot edge's sine coefficients (the formula, f = 100).** For the bar at 100 C on the
top edge of the 1 m plate, the Fourier sine coefficient `b_n = 2 ∫₀¹ f(x) sin(nπx) dx` is
400/(nπ) when n is odd and 0 when n is even, for every wave number n ≥ 1. -/
theorem sine_coefficient_of_hot_edge (n : ℕ) (hn : 1 ≤ n) :
    2 * ∫ x in (0 : ℝ)..1, (100 : ℝ) * sin (n * π * x)
      = if Odd n then 400 / (n * π) else 0 := by
  have hc : (n : ℝ) * π ≠ 0 := by
    have : (0 : ℝ) < n := by exact_mod_cast hn
    positivity
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_comp_mul_left
    (fun x => sin x) hc, integral_sin]
  simp only [mul_zero, mul_one, cos_zero, cos_nat_mul_pi, smul_eq_mul]
  split_ifs with h
  · rw [h.neg_one_pow]
    field_simp
    ring
  · rw [Nat.not_odd_iff_even] at h
    rw [h.neg_one_pow]
    ring

/-- **The settled temperature is the only one (Detailed proof, uniqueness).** On a plate W wide
and H high, let u and v be temperatures that are continuous on the closed plate, twice
continuously differentiable inside it, and solve Laplace's equation `u_xx + u_yy = 0` inside. If
they agree on all four edges, they agree at every point of the plate. -/
theorem settled_temperature_fixed_by_edges (W H : ℝ) (hW : 0 < W) (hH : 0 < H)
    (u v : ℝ → ℝ → ℝ)
    (hu_cont : ContinuousOn (Function.uncurry u) (Set.Icc 0 W ×ˢ Set.Icc 0 H))
    (hv_cont : ContinuousOn (Function.uncurry v) (Set.Icc 0 W ×ˢ Set.Icc 0 H))
    (hu_C2 : ContDiffOn ℝ 2 (Function.uncurry u) (Set.Ioo 0 W ×ˢ Set.Ioo 0 H))
    (hv_C2 : ContDiffOn ℝ 2 (Function.uncurry v) (Set.Ioo 0 W ×ˢ Set.Ioo 0 H))
    (hu_lap : ∀ x ∈ Set.Ioo 0 W, ∀ y ∈ Set.Ioo 0 H,
      deriv (fun s => deriv (fun r => u r y) s) x + deriv (fun s => deriv (fun r => u x r) s) y = 0)
    (hv_lap : ∀ x ∈ Set.Ioo 0 W, ∀ y ∈ Set.Ioo 0 H,
      deriv (fun s => deriv (fun r => v r y) s) x + deriv (fun s => deriv (fun r => v x r) s) y = 0)
    (h_bottom_top : ∀ x ∈ Set.Icc 0 W, u x 0 = v x 0 ∧ u x H = v x H)
    (h_sides : ∀ y ∈ Set.Icc 0 H, u 0 y = v 0 y ∧ u W y = v W y) :
    ∀ x ∈ Set.Icc 0 W, ∀ y ∈ Set.Icc 0 H, u x y = v x y := by
  intro x hx y hy
  apply le_antisymm
  · exact lap_aux_le W H hW hH u v hu_cont hv_cont hu_C2 hv_C2 hu_lap hv_lap
      h_bottom_top h_sides x hx y hy
  · exact lap_aux_le W H hW hH v u hv_cont hu_cont hv_C2 hu_C2 hv_lap hu_lap
      (fun x hx => ⟨(h_bottom_top x hx).1.symm, (h_bottom_top x hx).2.symm⟩)
      (fun y hy => ⟨(h_sides y hy).1.symm, (h_sides y hy).2.symm⟩) x hx y hy

/-! The card's whole-number worked examples. -/

-- Four quarter turns of the plate make every edge 100 C, so the centre gets a quarter: 25 C.
example : (100 : ℚ) / 4 = 25 := by norm_num

-- Edges at 100, 60, 20 and 0 C: the centre reads a quarter of each, 45 C.
example : (100 : ℚ) / 4 + 60 / 4 + 20 / 4 + 0 / 4 = 45 := by norm_num

-- The coefficients 400/(nπ) are nonzero only for odd wave numbers: 1, 3, 5, 7 are odd, 2 is not.
example : Odd 1 ∧ Odd 3 ∧ Odd 5 ∧ Odd 7 ∧ ¬ Odd 2 := by decide

#print axioms sine_sinh_sum_solves_laplace_on_rectangle
#print axioms sine_coefficient_of_hot_edge
#print axioms settled_temperature_fixed_by_edges
