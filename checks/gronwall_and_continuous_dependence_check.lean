-- Gronwall's inequality: two solutions of a law with Lipschitz constant L stay within their starting gap times e^(Lt), a quantity bounded by δ plus L times its running total stays below δe^(Lt), and a gap with w' ≤ kw stays below w(0)e^(kt).
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Set Real

/-- Helper: a continuous function whose rate in the interior is at most `k` times itself
stays below its start grown by `e^(kt)`. -/
theorem gronwall_helper_interior (g g' : ℝ → ℝ) (k T : ℝ)
    (hc : ContinuousOn g (Icc 0 T))
    (hd : ∀ t ∈ Ioo 0 T, HasDerivAt g (g' t) t)
    (hk : ∀ t ∈ Ioo 0 T, g' t ≤ k * g t) :
    ∀ t ∈ Icc 0 T, g t ≤ g 0 * exp (k * t) := by
  intro t ht
  set h : ℝ → ℝ := fun s => g s * exp (-k * s) with hh
  have hanti : AntitoneOn h (Icc 0 T) := by
    apply antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc 0 T)
      (f' := fun s => (g' s - k * g s) * exp (-k * s))
    · exact hc.mul (by fun_prop)
    · intro x hx
      rw [interior_Icc] at hx
      have h1 : HasDerivAt (fun s => exp (-k * s)) (exp (-k * x) * (-k)) x := by
        have := ((hasDerivAt_id x).const_mul (-k)).exp
        simpa using this
      have h2 := (hd x hx).mul h1
      have : (g' x - k * g x) * exp (-k * x) = g' x * exp (-k * x) + g x * (exp (-k * x) * -k) := by
        ring
      rw [this]
      exact h2.hasDerivWithinAt
    · intro x hx
      rw [interior_Icc] at hx
      exact mul_nonpos_of_nonpos_of_nonneg (by linarith [hk x hx]) (exp_pos _).le
  have h0 : (0:ℝ) ∈ Icc 0 T := ⟨le_rfl, ht.1.trans ht.2⟩
  have := hanti h0 ht ht.1
  simp only [hh, mul_zero, exp_zero, mul_one] at this
  have he : exp (-k * t) * exp (k * t) = 1 := by rw [← exp_add]; simp
  calc g t = g t * exp (-k * t) * exp (k * t) := by rw [mul_assoc, he, mul_one]
    _ ≤ g 0 * exp (k * t) := mul_le_mul_of_nonneg_right this (exp_pos _).le

#print axioms gronwall_helper_interior

/-- Continuous dependence on the start. Suppose the rate law `f` satisfies
`|f(t, y) - f(t, z)| ≤ L |y - z|` for all points `(t, y)` and `(t, z)` of a region `R`.
If `y` and `z` both solve `y' = f(t, y)` on the times from `0` to `T` and stay in `R` there,
then at every such time the gap is at most the starting gap grown by `e^(Lt)`:
`|y(t) - z(t)| ≤ |y(0) - z(0)| e^(Lt)`. -/
theorem solutions_gap_le_start_gap_mul_exp (f : ℝ → ℝ → ℝ) (R : Set (ℝ × ℝ)) (L T : ℝ)
    (hlip : ∀ t y z : ℝ, (t, y) ∈ R → (t, z) ∈ R → |f t y - f t z| ≤ L * |y - z|)
    (y z : ℝ → ℝ)
    (hy : ∀ t ∈ Icc 0 T, HasDerivWithinAt y (f t (y t)) (Icc 0 T) t)
    (hz : ∀ t ∈ Icc 0 T, HasDerivWithinAt z (f t (z t)) (Icc 0 T) t)
    (hyR : ∀ t ∈ Icc 0 T, (t, y t) ∈ R) (hzR : ∀ t ∈ Icc 0 T, (t, z t) ∈ R) :
    ∀ t ∈ Icc 0 T, |y t - z t| ≤ |y 0 - z 0| * exp (L * t) := by
  intro t ht
  rcases lt_or_ge L 0 with hL | hL
  · have heq : ∀ s ∈ Icc 0 T, y s = z s := by
      intro s hs
      by_contra hne
      have := hlip s (y s) (z s) (hyR s hs) (hzR s hs)
      have hpos : 0 < |y s - z s| := abs_pos.mpr (sub_ne_zero.mpr hne)
      nlinarith [abs_nonneg (f s (y s) - f s (z s))]
    rw [heq t ht, sub_self, abs_zero]
    positivity
  · have hmem : ∀ s ∈ Ico 0 T, Icc 0 T ∈ nhdsWithin s (Ici s) := by
      intro s hs
      exact Filter.mem_of_superset (Icc_mem_nhdsGE hs.2) (Icc_subset_Icc_left hs.1)
    have key := dist_le_of_trajectories_ODE_of_mem (K := ⟨L, hL⟩) (v := f)
      (s := fun t => {x | (t, x) ∈ R}) (a := 0) (b := T) (δ := |y 0 - z 0|)
      (f := y) (g := z)
      (fun t _ => LipschitzOnWith.of_dist_le_mul fun a ha b hb => by
        rw [Real.dist_eq, Real.dist_eq]; exact hlip t a b ha hb)
      (fun s hs => (hy s hs).continuousWithinAt)
      (fun s hs => (hy s (Ico_subset_Icc_self hs)).mono_of_mem_nhdsWithin (hmem s hs))
      (fun s hs => hyR s (Ico_subset_Icc_self hs))
      (fun s hs => (hz s hs).continuousWithinAt)
      (fun s hs => (hz s (Ico_subset_Icc_self hs)).mono_of_mem_nhdsWithin (hmem s hs))
      (fun s hs => hzR s (Ico_subset_Icc_self hs))
      (by rw [Real.dist_eq]) t ht
    rw [Real.dist_eq, sub_zero] at key
    exact key

/-- Gronwall's inequality, integral form. Let `w` be continuous and never negative for times
from `0` to `T`, and let `L ≥ 0` and `δ ≥ 0` be constants. If at every such time
`w(t) ≤ δ + ∫₀ᵗ L w(s) ds`, then at every such time `w(t) ≤ δ e^(Lt)`. -/
theorem gronwall_integral_form (w : ℝ → ℝ) (L δ T : ℝ)
    (hw : ContinuousOn w (Icc 0 T)) (hw0 : ∀ t ∈ Icc 0 T, 0 ≤ w t)
    (hL : 0 ≤ L) (hδ : 0 ≤ δ)
    (h : ∀ t ∈ Icc 0 T, w t ≤ δ + ∫ s in (0)..t, L * w s) :
    ∀ t ∈ Icc 0 T, w t ≤ δ * exp (L * t) := by
  intro t ht
  have hT : ∀ s ∈ Icc 0 T, Icc 0 s ⊆ Icc 0 T := fun s hs => Icc_subset_Icc_right hs.2
  have hcont : ContinuousOn (fun s => L * w s) (Icc 0 T) := continuousOn_const.mul hw
  set W : ℝ → ℝ := fun u => ∫ s in (0)..u, L * w s with hW
  have hT0 : 0 ≤ T := ht.1.trans ht.2
  have key := gronwall_helper_interior (fun u => δ + W u) (fun u => L * w u) L T
    (by
      have hi : MeasureTheory.IntegrableOn (fun s => L * w s) (uIcc 0 T) := by
        rw [uIcc_of_le hT0]; exact hcont.integrableOn_Icc
      have := intervalIntegral.continuousOn_primitive_interval hi
      rw [uIcc_of_le hT0] at this
      exact continuousOn_const.add this)
    (by
      intro u hu
      have hsub : uIcc 0 u ⊆ Icc 0 T := by
        rw [uIcc_of_le hu.1.le]; exact Icc_subset_Icc_right hu.2.le
      have hd := intervalIntegral.integral_hasDerivAt_right
        ((hcont.mono hsub).intervalIntegrable)
        ((hcont.mono Ioo_subset_Icc_self).stronglyMeasurableAtFilter isOpen_Ioo u hu)
        (hcont.continuousAt (Icc_mem_nhds hu.1 hu.2))
      exact hd.const_add δ)
    (by
      intro u hu
      have := h u (Ioo_subset_Icc_self hu)
      exact mul_le_mul_of_nonneg_left this hL)
    t ht
  simp only [hW, intervalIntegral.integral_same, add_zero] at key
  exact (h t ht).trans key

/-- The one-sided form, for a law that may pull solutions together. If `w` has rate `w'` on the
times from `0` to `T` and `w'(t) ≤ k w(t)` there, for a constant `k` of either sign, then
`w(t) ≤ w(0) e^(kt)` at every such time. -/
theorem one_sided_gronwall (w w' : ℝ → ℝ) (k T : ℝ)
    (hw : ∀ t ∈ Icc 0 T, HasDerivWithinAt w (w' t) (Icc 0 T) t)
    (hk : ∀ t ∈ Icc 0 T, w' t ≤ k * w t) :
    ∀ t ∈ Icc 0 T, w t ≤ w 0 * exp (k * t) := by
  apply gronwall_helper_interior w w' k T
  · intro t ht; exact (hw t ht).continuousWithinAt
  · intro t ht
    exact (hw t (Ioo_subset_Icc_self ht)).hasDerivAt (Icc_mem_nhds ht.1 ht.2)
  · intro t ht; exact hk t (Ioo_subset_Icc_self ht)

-- The rumours' starting gap: 11 - 10 = 1 pupil.
example : (11 : ℕ) - 10 = 1 := by norm_num
-- The reversed bucket's second solution at s = 50: (s / 10)^2 = 25.
example : ((50 : ℚ) / 10) ^ 2 = 25 := by norm_num

#print axioms solutions_gap_le_start_gap_mul_exp
#print axioms gronwall_integral_form
#print axioms one_sided_gronwall
