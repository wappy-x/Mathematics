-- Line integrals of a field: for a route with a continuous velocity and a field continuous along it, reversing the route flips the sign of the work, a forward change of clock leaves it unchanged, force-times-chord sums close in on it, and the card's wind gives 30, 10, −30 and 90 J on its four routes and 120 J round the loop.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Topology.Order.ProjIcc
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Tactic

open Set RealInnerProductSpace

/-- Telescoping over `Fin`: the steps of a list of numbers add up to last minus first. -/
theorem fin_sum_succ_sub_castSucc : ∀ (m : ℕ) (u : Fin (m + 1) → ℝ),
    ∑ i : Fin m, (u i.succ - u i.castSucc) = u (Fin.last m) - u 0 := by
  intro m
  induction m with
  | zero => intro u; simp
  | succ m ih =>
    intro u
    rw [Fin.sum_univ_castSucc]
    have h := ih (fun i => u i.castSucc)
    simp only [Fin.succ_castSucc] at h ⊢
    rw [h, Fin.succ_last, Fin.castSucc_zero]
    ring

/-- **Reversing the route flips the sign.** A route r(t), for clock t from a to b, has a
continuous velocity r'(t) (r is continuously differentiable: a smooth piece), and the field F is
continuous along the route. The work is ∫ from a to b of F(r(t)) · r'(t) dt. Run the same route
backwards, from B to A, by the clock s ↦ r(a + b − s). Its work is the negative of the forward work. -/
theorem line_integral_reverse_eq_neg {n : ℕ} (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (r : ℝ → EuclideanSpace ℝ (Fin n)) {a b : ℝ} (hab : a ≤ b)
    (hr : ContDiff ℝ 1 r) (hF : ContinuousOn F (r '' Icc a b)) :
    (∫ s in a..b, ⟪F (r (a + b - s)), deriv (fun s => r (a + b - s)) s⟫) =
      -∫ t in a..b, ⟪F (r t), deriv r t⟫ := by
  have hdiff : Differentiable ℝ r := hr.differentiable one_ne_zero
  have hd : ∀ s, deriv (fun s => r (a + b - s)) s = -deriv r (a + b - s) := by
    intro s
    have h1 : HasDerivAt r (deriv r (a + b - s)) (a + b - s) := (hdiff _).hasDerivAt
    have h2 : HasDerivAt (fun s : ℝ => a + b - s) (-1) s := by
      simpa using (hasDerivAt_id s).const_sub (a + b)
    have h3 := h1.scomp s h2
    have h4 : (r ∘ fun s : ℝ => a + b - s) = fun s => r (a + b - s) := rfl
    rw [h4] at h3
    rw [h3.deriv]
    simp
  simp_rw [hd, inner_neg_right]
  rw [intervalIntegral.integral_neg,
    intervalIntegral.integral_comp_sub_left (fun x => ⟪F (r x), deriv r x⟫) (a + b)]
  congr 2 <;> ring

/-- **The pace does not matter.** A route r(t), clock t from a to b, has a continuous velocity,
and the field F is continuous along it. A new clock s runs from c to d, and t = φ(s) turns it into
the old one: φ has a continuous rate of change, runs forward (never goes back), and starts at a
and ends at b. Then the work along the new-clock route r(φ(s)), ∫ from c to d of
F(r(φ(s))) · (r ∘ φ)'(s) ds, equals the work ∫ from a to b of F(r(t)) · r'(t) dt. -/
theorem line_integral_reparam_eq {n : ℕ} (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (r : ℝ → EuclideanSpace ℝ (Fin n)) (φ : ℝ → ℝ) {a b c d : ℝ} (hcd : c ≤ d)
    (hr : ContDiff ℝ 1 r) (hF : ContinuousOn F (r '' Icc a b))
    (hφ : ContDiff ℝ 1 φ) (hmono : MonotoneOn φ (Icc c d)) (hφc : φ c = a) (hφd : φ d = b) :
    (∫ s in c..d, ⟪F (r (φ s)), deriv (r ∘ φ) s⟫) = ∫ t in a..b, ⟪F (r t), deriv r t⟫ := by
  have hdiff : Differentiable ℝ r := hr.differentiable one_ne_zero
  have hφdiff : Differentiable ℝ φ := hφ.differentiable one_ne_zero
  set g : ℝ → ℝ := fun t => ⟪F (r t), deriv r t⟫ with hg
  have hd : ∀ s, deriv (r ∘ φ) s = deriv φ s • deriv r (φ s) := by
    intro s
    exact ((hdiff (φ s)).hasDerivAt.scomp s (hφdiff s).hasDerivAt).deriv
  have hint : ∀ s, ⟪F (r (φ s)), deriv (r ∘ φ) s⟫ = (g ∘ φ) s * deriv φ s := by
    intro s
    rw [hd, inner_smul_right]
    simp only [hg, Function.comp]
    ring
  simp_rw [hint]
  have hgc : ContinuousOn g (Icc a b) :=
    (hF.comp hr.continuous.continuousOn (mapsTo_image r _)).inner
      (hr.continuous_deriv le_rfl).continuousOn
  rw [intervalIntegral.integral_comp_mul_deriv' (f := φ) (f' := deriv φ) (g := g)
    (fun x _ => (hφdiff x).hasDerivAt) (hφ.continuous_deriv le_rfl).continuousOn, hφc, hφd]
  apply hgc.mono
  rintro _ ⟨x, hx, rfl⟩
  rw [uIcc_of_le hcd] at hx
  refine ⟨?_, ?_⟩
  · rw [← hφc]; exact hmono ⟨le_rfl, hcd⟩ hx hx.1
  · rw [← hφd]; exact hmono hx ⟨hcd, le_rfl⟩ hx.2

/-- **Force-times-chord sums close in on the work.** A route r(t), clock t from a to b, has a
continuous velocity, and the field F is continuous along it. Cut the clock at
a = t₀ ≤ t₁ ≤ … ≤ tₙ = b with every step shorter than δ, pick any reading τᵢ in each step, and
add F(r(τᵢ)) · (r(tᵢ) − r(tᵢ₋₁)): the wind at that reading dotted with the step's chord.
For every ε > 0 there is a δ > 0 that keeps every such sum within ε of the work
∫ from a to b of F(r(t)) · r'(t) dt, whatever readings are picked. -/
theorem chord_sums_tend_to_line_integral {n : ℕ}
    (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (r : ℝ → EuclideanSpace ℝ (Fin n)) {a b : ℝ} (hab : a ≤ b)
    (hr : ContDiff ℝ 1 r) (hF : ContinuousOn F (r '' Icc a b)) :
    ∀ ε > 0, ∃ δ > 0, ∀ (m : ℕ) (t : Fin (m + 1) → ℝ) (τ : Fin m → ℝ),
      t 0 = a → t (Fin.last m) = b →
      (∀ i : Fin m, t i.castSucc ≤ τ i ∧ τ i ≤ t i.succ) →
      (∀ i : Fin m, t i.succ - t i.castSucc < δ) →
      |(∑ i : Fin m, ⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫) -
          ∫ s in a..b, ⟪F (r s), deriv r s⟫| < ε := by
  intro ε hε
  have hdiff : Differentiable ℝ r := hr.differentiable one_ne_zero
  set p : ℝ → ℝ := fun x => (projIcc a b hab x : ℝ) with hp
  have hpc : Continuous p := continuous_subtype_val.comp continuous_projIcc
  have hpI : ∀ x ∈ Icc a b, p x = x := fun x hx => by simp [hp, projIcc_of_mem hab hx]
  have hpm : ∀ x, p x ∈ Icc a b := fun x => (projIcc a b hab x).2
  have hr' : Continuous (deriv r) := hr.continuous_deriv le_rfl
  have hrc : Continuous r := hr.continuous
  set G : ℝ → EuclideanSpace ℝ (Fin n) := fun x => F (r (p x)) with hG
  have hGc : Continuous G :=
    hF.comp_continuous (hrc.comp hpc) (fun x => mem_image_of_mem r (hpm x))
  set g : ℝ → ℝ := fun x => ⟪G x, deriv r x⟫ with hg
  have hgc : Continuous g := hGc.inner hr'
  set H : ℝ → ℝ := fun x => ∫ s in a..x, g s with hH
  have hHd : ∀ x, HasDerivAt H (g x) x := fun x =>
    (hgc.integral_hasStrictDerivAt a x).hasDerivAt
  obtain ⟨M, hM⟩ : ∃ M, ∀ x ∈ Icc a b, ‖deriv r x‖ ≤ M :=
    isCompact_Icc.exists_bound_of_continuousOn hr'.continuousOn
  have hM0 : 0 ≤ M := le_trans (norm_nonneg _) (hM a ⟨le_rfl, hab⟩)
  have hba : 0 ≤ b - a := sub_nonneg.2 hab
  set η : ℝ := ε / (2 * (M + 1) * (b - a + 1)) with hη
  have hden : 0 < 2 * (M + 1) * (b - a + 1) := by positivity
  have hη0 : 0 < η := div_pos hε hden
  have hηeq : η * (2 * (M + 1) * (b - a + 1)) = ε := by
    rw [hη]; field_simp
  have huc := (isCompact_Icc (a := a) (b := b)).uniformContinuousOn_of_continuous hGc.continuousOn
  rw [Metric.uniformContinuousOn_iff] at huc
  obtain ⟨δ, hδ, hδG⟩ := huc η hη0
  refine ⟨δ, hδ, ?_⟩
  intro m t τ h0 hlast hτ hstep
  have hmono : Monotone t := Fin.monotone_iff_le_succ.2 (fun i => (hτ i).1.trans (hτ i).2)
  have htI : ∀ j, t j ∈ Icc a b := fun j =>
    ⟨h0 ▸ hmono (Fin.zero_le j), hlast ▸ hmono (Fin.le_last j)⟩
  have hint : ∫ s in a..b, ⟪F (r s), deriv r s⟫ = H b - H a := by
    have h1 : ∫ s in a..b, ⟪F (r s), deriv r s⟫ = ∫ s in a..b, g s := by
      apply intervalIntegral.integral_congr
      intro x hx
      rw [uIcc_of_le hab] at hx
      simp [hg, hG, hpI x hx]
    rw [h1, hH]
    simp
  have htel : H b - H a = ∑ i : Fin m, (H (t i.succ) - H (t i.castSucc)) := by
    rw [← h0, ← hlast]
    exact (fin_sum_succ_sub_castSucc m (fun j => H (t j))).symm
  rw [hint, htel, ← Finset.sum_sub_distrib]
  have hterm : ∀ i : Fin m,
      |⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫ - (H (t i.succ) - H (t i.castSucc))| ≤
        η * M * (t i.succ - t i.castSucc) := by
    intro i
    have hxy : t i.castSucc ≤ t i.succ := (hτ i).1.trans (hτ i).2
    have hτI : τ i ∈ Icc a b :=
      ⟨(htI _).1.trans (hτ i).1, (hτ i).2.trans (htI _).2⟩
    have hGτ : G (τ i) = F (r (τ i)) := by simp [hG, hpI _ hτI]
    let K : ℝ → ℝ := fun s => ⟪F (r (τ i)), r s⟫ - H s
    have hK : ∀ s, HasDerivAt K (⟪F (r (τ i)), deriv r s⟫ - g s) s := by
      intro s
      have h1 := (hasDerivAt_const s (F (r (τ i)))).inner ℝ (hdiff s).hasDerivAt
      have h2 : HasDerivAt K (⟪F (r (τ i)), deriv r s⟫ + ⟪(0 : EuclideanSpace ℝ (Fin n)), r s⟫ - g s) s :=
        h1.sub (hHd s)
      convert h2 using 1
      simp
    have hb : ∀ s ∈ Ico (t i.castSucc) (t i.succ),
        ‖⟪F (r (τ i)), deriv r s⟫ - g s‖ ≤ η * M := by
      intro s hs
      have hsI : s ∈ Icc a b :=
        ⟨(htI _).1.trans hs.1, hs.2.le.trans (htI _).2⟩
      have hGs : G s = F (r s) := by simp [hG, hpI s hsI]
      have hdist : dist (G (τ i)) (G s) < η := by
        apply hδG _ hτI _ hsI
        rw [Real.dist_eq, abs_lt]
        have := hstep i
        constructor <;> linarith [(hτ i).1, (hτ i).2, hs.1, hs.2]
      rw [Real.norm_eq_abs, hg]
      simp only
      rw [← inner_sub_left]
      calc |⟪F (r (τ i)) - G s, deriv r s⟫| ≤ ‖F (r (τ i)) - G s‖ * ‖deriv r s‖ :=
            abs_real_inner_le_norm _ _
        _ ≤ η * M := by
            apply mul_le_mul _ (hM s hsI) (norm_nonneg _) hη0.le
            rw [← dist_eq_norm, ← hGτ]
            exact hdist.le
    have hmv := norm_image_sub_le_of_norm_deriv_le_segment' (f := K)
      (fun s _ => (hK s).hasDerivWithinAt) hb (t i.succ) ⟨hxy, le_rfl⟩
    rw [Real.norm_eq_abs] at hmv
    convert hmv using 2
    simp only [K, inner_sub_right]
    ring
  calc |∑ i : Fin m, (⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫ -
          (H (t i.succ) - H (t i.castSucc)))|
      ≤ ∑ i : Fin m, |⟪F (r (τ i)), r (t i.succ) - r (t i.castSucc)⟫ -
          (H (t i.succ) - H (t i.castSucc))| := Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ i : Fin m, η * M * (t i.succ - t i.castSucc) := Finset.sum_le_sum (fun i _ => hterm i)
    _ = η * M * (b - a) := by
        rw [← Finset.mul_sum, fin_sum_succ_sub_castSucc m t, h0, hlast]
    _ < ε := by
        have h1 : η * M * (b - a) ≤ η * ((M + 1) * (b - a + 1)) := by
          apply le_trans (le_of_eq (mul_assoc _ _ _))
          apply mul_le_mul_of_nonneg_left _ hη0.le
          nlinarith
        nlinarith

-- The card's wind is (y/10, −1) N at (x, y) m; the cart goes from A (0, 0) to B (40, 30).
-- Straight route (40t, 30t): wind (3t, −1), velocity (40, 30); the work is 120/2 − 30 = 30 J.
example : (∫ t in (0 : ℝ)..1, ((30 * t / 10) * 40 + (-1) * 30)) = 30 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 60 * t ^ 2 - 30 * t ^ 1)
      ((30 * x / 10) * 40 + (-1) * 30) x := by
    intro x _
    have := ((hasDerivAt_pow 2 x).const_mul 60).sub ((hasDerivAt_pow 1 x).const_mul 30)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- The curve (40t, 30t^2): wind (3t^2, −1), velocity (40, 60t); the work is 40 − 30 = 10 J.
example : (∫ t in (0 : ℝ)..1, ((30 * t ^ 2 / 10) * 40 + (-1) * (60 * t))) = 10 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 40 * t ^ 3 - 30 * t ^ 2)
      ((30 * x ^ 2 / 10) * 40 + (-1) * (60 * x)) x := by
    intro x _
    have := ((hasDerivAt_pow 3 x).const_mul 40).sub ((hasDerivAt_pow 2 x).const_mul 30)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- Its dot product is 120t^2 − 60t, with antiderivative 40t^3 − 30t^2.
example : ∀ t : ℚ, (30 * t ^ 2 / 10) * 40 + (-1) * (60 * t) = 120 * t ^ 2 - 60 * t := by
  intro t; ring
example : (40 : ℚ) * 1 ^ 3 - 30 * 1 ^ 2 - (40 * 0 ^ 3 - 30 * 0 ^ 2) = 10 := by norm_num
-- The straight route at a slow start, (40s^2, 30s^2): velocity (80s, 60s), work 30 J again.
example : (∫ s in (0 : ℝ)..1, ((30 * s ^ 2 / 10) * (80 * s) + (-1) * (60 * s))) = 30 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 60 * t ^ 4 - 30 * t ^ 2)
      ((30 * x ^ 2 / 10) * (80 * x) + (-1) * (60 * x)) x := by
    intro x _
    have := ((hasDerivAt_pow 4 x).const_mul 60).sub ((hasDerivAt_pow 2 x).const_mul 30)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- The straight route from B to A, (40 − 40s, 30 − 30s): velocity (−40, −30), work −30 J.
example : (∫ s in (0 : ℝ)..1, ((30 * (1 - s) / 10) * (-40) + (-1) * (-30))) = -30 := by
  have h : ∀ x ∈ uIcc (0:ℝ) 1, HasDerivAt (fun t : ℝ => 60 * t ^ 2 - 90 * t ^ 1)
      ((30 * (1 - x) / 10) * (-40) + (-1) * (-30)) x := by
    intro x _
    have := ((hasDerivAt_pow 2 x).const_mul 60).sub ((hasDerivAt_pow 1 x).const_mul 90)
    convert this using 1
    simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    (by apply Continuous.intervalIntegrable; fun_prop)]
  norm_num
-- Straight route: length √(40^2 + 30^2) = 50 m, direction (40/50, 30/50) = (0.8, 0.6).
example : (40 : ℚ) ^ 2 + 30 ^ 2 = 50 ^ 2 ∧ (40 : ℚ) / 50 = 4 / 5 ∧ (30 : ℚ) / 50 = 3 / 5 := by
  norm_num
-- North leg on either edge: −1 N × 30 m = −30 J. East leg along the top: 3 N × 40 m = 120 J.
example : (-1 : ℚ) * 30 = -30 ∧ (30 : ℚ) / 10 * 40 = 120 := by norm_num
-- North, then east: −30 + 120 = 90 J. East, then north: 0 + (−30) = −30 J.
example : (-30 : ℚ) + 120 = 90 ∧ (0 : ℚ) + (-30) = -30 := by norm_num
-- The loop, out north-then-east and back along the hedge route reversed: 90 + 30 = 120 J,
-- which is 0.1 N per metre times the area 40 m × 30 m.
example : (90 : ℚ) + 30 = 120 ∧ (1 : ℚ) / 10 * (40 * 30) = 120 := by norm_num
-- On the curve, 4 force-times-chord pieces give 9.375 J = 75/8 J, short by 0.625 J = 5/8 J.
-- Piece i runs over clock [i/4, (i+1)/4]: wind at its middle (3((2i+1)/8)^2, −1), chord
-- (10, 30((i+1)^2 − i^2)/16).
example : (∑ i ∈ Finset.range 4,
    (3 * ((2 * (i : ℚ) + 1) / 8) ^ 2 * 10 + (-1) * (30 * ((i + 1) ^ 2 - i ^ 2) / 16))) = 75 / 8 := by
  norm_num [Finset.sum_range_succ]
example : (10 : ℚ) - 75 / 8 = 5 / 8 := by norm_num

#print axioms fin_sum_succ_sub_castSucc
#print axioms line_integral_reverse_eq_neg
#print axioms line_integral_reparam_eq
#print axioms chord_sums_tend_to_line_integral
