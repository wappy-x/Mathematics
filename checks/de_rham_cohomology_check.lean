-- de Rham cohomology: on the torus every closed smooth 1-form is, in exactly one way, c₁ dθ + c₂ dψ plus the derivative of a smooth function on the torus, so the first de Rham group has dimension 2, and c₁, c₂ are read both by loop integrals over 2π and by area integrals over 4π².
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Algebra.Ring.Periodic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
import Mathlib.MeasureTheory.Integral.Prod

open Real
open scoped ContDiff

/-! The torus is the square of states (θ, ψ), platform angle and crank phase, with opposite edges
glued. A smooth 1-form α = P dθ + Q dψ on the torus is a pair of smooth functions P, Q on the plane
ℝ × ℝ that repeat after 2π in θ and after 2π in ψ (`Function.Periodic`). It is closed when its
curl is zero, ∂Q/∂θ = ∂P/∂ψ. It is exact when α = df for a smooth function f on the torus, that is
a smooth f on the plane repeating after 2π in both directions, with P = ∂f/∂θ and Q = ∂f/∂ψ.
The partial derivative ∂f/∂θ at p is `fderiv ℝ f p (1, 0)`, and ∂f/∂ψ is `fderiv ℝ f p (0, 1)`. -/

open scoped Interval in
theorem dr_hasFDerivAt_param {E F : Type} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F]
    {g : E × ℝ → F} (hg : ContDiff ℝ 1 g) (x₀ : E) :
    HasFDerivAt (fun x => ∫ t in (0:ℝ)..1, g (x, t))
      (∫ t in (0:ℝ)..1, (fderiv ℝ g (x₀, t)).comp (ContinuousLinearMap.inl ℝ E ℝ)) x₀ := by
  have hgc : Continuous g := hg.continuous
  have hDc : Continuous (fderiv ℝ g) := hg.continuous_fderiv one_ne_zero
  have hF'c : Continuous (fun p : E × ℝ => (fderiv ℝ g p).comp (ContinuousLinearMap.inl ℝ E ℝ)) :=
    hDc.clm_comp continuous_const
  have hSc : IsCompact (Metric.closedBall x₀ 1 ×ˢ Set.Icc (0:ℝ) 1) :=
    (isCompact_closedBall x₀ 1).prod isCompact_Icc
  obtain ⟨B, hB⟩ := hSc.exists_bound_of_continuousOn hF'c.continuousOn
  have hIoc : Ι (0:ℝ) 1 ⊆ Set.Icc 0 1 := by
    intro t ht; rw [Set.uIoc_of_le zero_le_one] at ht; exact ⟨ht.1.le, ht.2⟩
  refine intervalIntegral.hasFDerivAt_integral_of_dominated_of_fderiv_le (𝕜 := ℝ)
    (bound := fun _ => B) (F := fun x t => g (x, t))
    (F' := fun x t => (fderiv ℝ g (x, t)).comp (ContinuousLinearMap.inl ℝ E ℝ))
    (Metric.ball_mem_nhds x₀ one_pos) ?_ ?_ ?_ ?_ ?_ ?_
  · exact Filter.Eventually.of_forall (fun x =>
      (hgc.comp (by fun_prop : Continuous fun t : ℝ => (x, t))).aestronglyMeasurable)
  · exact (hgc.comp (by fun_prop : Continuous fun t : ℝ => (x₀, t))).intervalIntegrable _ _
  · exact (hF'c.comp (by fun_prop : Continuous fun t : ℝ => (x₀, t))).aestronglyMeasurable
  · exact Filter.Eventually.of_forall (fun t ht x hx =>
      hB (x, t) ⟨Metric.ball_subset_closedBall hx, hIoc ht⟩)
  · exact intervalIntegrable_const
  · refine Filter.Eventually.of_forall (fun t _ x _ => ?_)
    exact ((hg.differentiable one_ne_zero (x, t)).hasFDerivAt).comp x (hasFDerivAt_prodMk_left x t)

theorem dr_contDiff_param_nat {E : Type} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] (n : ℕ) :
    ∀ {F : Type} [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F] {g : E × ℝ → F},
      ContDiff ℝ n g → ContDiff ℝ n (fun x => ∫ t in (0:ℝ)..1, g (x, t)) := by
  induction n with
  | zero =>
    intro F _ _ _ g hg
    rw [Nat.cast_zero, contDiff_zero] at hg ⊢
    exact intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
      (f := fun x t => g (x, t)) hg 0 1
  | succ n ih =>
    intro F _ _ _ g hg
    have hg1 : ContDiff ℝ 1 g := hg.of_le (by exact_mod_cast Nat.le_add_left 1 n)
    rw [Nat.cast_succ, contDiff_succ_iff_fderiv] at hg ⊢
    refine ⟨fun x => (dr_hasFDerivAt_param hg1 x).differentiableAt, by simp, ?_⟩
    have heq : fderiv ℝ (fun x => ∫ t in (0:ℝ)..1, g (x, t)) =
        fun x => ∫ t in (0:ℝ)..1, (fderiv ℝ g (x, t)).comp (ContinuousLinearMap.inl ℝ E ℝ) := by
      funext x; exact (dr_hasFDerivAt_param hg1 x).fderiv
    rw [heq]
    exact ih (g := fun p => (fderiv ℝ g p).comp (ContinuousLinearMap.inl ℝ E ℝ))
      (hg.2.2.clm_comp contDiff_const)

theorem dr_contDiff_param {E F : Type} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F]
    {g : E × ℝ → F} (hg : ContDiff ℝ ∞ g) :
    ContDiff ℝ ∞ (fun x => ∫ t in (0:ℝ)..1, g (x, t)) :=
  contDiff_infty.2 fun n => dr_contDiff_param_nat n (contDiff_infty.1 hg n)

theorem dr_contDiff_primitive {h : ℝ × ℝ → ℝ} (hh : ContDiff ℝ ∞ h) :
    ContDiff ℝ ∞ (fun p : ℝ × ℝ => ∫ s in (0:ℝ)..p.2, h (p.1, s)) := by
  have heq : (fun p : ℝ × ℝ => ∫ s in (0:ℝ)..p.2, h (p.1, s)) =
      fun p => p.2 * ∫ u in (0:ℝ)..1, h (p.1, u * p.2) := by
    funext p
    have := intervalIntegral.smul_integral_comp_mul_right (a := 0) (b := 1)
      (fun s => h (p.1, s)) p.2
    simpa using this.symm
  rw [heq]
  exact contDiff_snd.mul (dr_contDiff_param (g := fun q : (ℝ × ℝ) × ℝ => h (q.1.1, q.2 * q.1.2))
    (hh.comp (by fun_prop)))

theorem dr_hasDerivAt_fst {f : ℝ × ℝ → ℝ} {t y : ℝ} (hf : DifferentiableAt ℝ f (t, y)) :
    HasDerivAt (fun t => f (t, y)) (fderiv ℝ f (t, y) (1, 0)) t :=
  hf.hasFDerivAt.comp_hasDerivAt t ((hasDerivAt_id t).prodMk (hasDerivAt_const t y))

theorem dr_hasDerivAt_snd {f : ℝ × ℝ → ℝ} {x s : ℝ} (hf : DifferentiableAt ℝ f (x, s)) :
    HasDerivAt (fun s => f (x, s)) (fderiv ℝ f (x, s) (0, 1)) s :=
  hf.hasFDerivAt.comp_hasDerivAt s ((hasDerivAt_const s x).prodMk (hasDerivAt_id s))

theorem dr_continuous_fst {f : ℝ × ℝ → ℝ} (hf : ContDiff ℝ 1 f) :
    Continuous (fun p : ℝ × ℝ => fderiv ℝ f p (1, 0)) :=
  (hf.continuous_fderiv one_ne_zero).clm_apply continuous_const

theorem dr_continuous_snd {f : ℝ × ℝ → ℝ} (hf : ContDiff ℝ 1 f) :
    Continuous (fun p : ℝ × ℝ => fderiv ℝ f p (0, 1)) :=
  (hf.continuous_fderiv one_ne_zero).clm_apply continuous_const

theorem dr_integral_fst {f : ℝ × ℝ → ℝ} (hf : ContDiff ℝ 1 f) (a b y : ℝ) :
    ∫ t in a..b, fderiv ℝ f (t, y) (1, 0) = f (b, y) - f (a, y) :=
  intervalIntegral.integral_eq_sub_of_hasDerivAt
    (fun t _ => dr_hasDerivAt_fst (hf.differentiable one_ne_zero _))
    (((dr_continuous_fst hf).comp (by fun_prop : Continuous fun t : ℝ => (t, y))).intervalIntegrable _ _)

theorem dr_integral_snd {f : ℝ × ℝ → ℝ} (hf : ContDiff ℝ 1 f) (a b x : ℝ) :
    ∫ s in a..b, fderiv ℝ f (x, s) (0, 1) = f (x, b) - f (x, a) :=
  intervalIntegral.integral_eq_sub_of_hasDerivAt
    (fun s _ => dr_hasDerivAt_snd (hf.differentiable one_ne_zero _))
    (((dr_continuous_snd hf).comp (by fun_prop : Continuous fun s : ℝ => (x, s))).intervalIntegrable _ _)

theorem dr_swap {F : ℝ → ℝ → ℝ} (hF : Continuous (Function.uncurry F)) (a b c d : ℝ) :
    ∫ x in a..b, ∫ y in c..d, F x y = ∫ y in c..d, ∫ x in a..b, F x y :=
  MeasureTheory.intervalIntegral_intervalIntegral_swap
    ((hF.continuousOn.integrableOn_compact (isCompact_uIcc.prod isCompact_uIcc)).mono_set
      (Set.prod_mono Set.uIoc_subset_uIcc Set.uIoc_subset_uIcc))

theorem dr_loop_fst {P f : ℝ × ℝ → ℝ} {c₁ : ℝ} (hf : ContDiff ℝ ∞ f)
    (hfθ : Function.Periodic f ((2 * π, 0) : ℝ × ℝ))
    (hPf : ∀ p : ℝ × ℝ, P p = c₁ + fderiv ℝ f p (1, 0)) (ψ₀ : ℝ) :
    ∫ t in (0 : ℝ)..2 * π, P (t, ψ₀) = 2 * π * c₁ := by
  have hf1 : ContDiff ℝ 1 f := hf.of_le (by simp)
  have hd : ∀ t, HasDerivAt (fun t => c₁ * t + f (t, ψ₀)) (P (t, ψ₀)) t := by
    intro t
    rw [hPf]
    have h := ((hasDerivAt_id t).const_mul c₁).add
      (dr_hasDerivAt_fst (hf1.differentiable one_ne_zero (t, ψ₀)))
    simp only [id, mul_one] at h
    exact h
  have hPc : Continuous P := by
    rw [show P = fun p => c₁ + fderiv ℝ f p (1, 0) from funext hPf]
    exact continuous_const.add (dr_continuous_fst hf1)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hd t)
    ((hPc.comp (by fun_prop : Continuous fun t : ℝ => (t, ψ₀))).intervalIntegrable _ _)]
  have : f (2 * π, ψ₀) = f (0, ψ₀) := by simpa using hfθ (0, ψ₀)
  rw [this]; ring

theorem dr_loop_snd {Q f : ℝ × ℝ → ℝ} {c₂ : ℝ} (hf : ContDiff ℝ ∞ f)
    (hfψ : Function.Periodic f ((0, 2 * π) : ℝ × ℝ))
    (hQf : ∀ p : ℝ × ℝ, Q p = c₂ + fderiv ℝ f p (0, 1)) (θ₀ : ℝ) :
    ∫ t in (0 : ℝ)..2 * π, Q (θ₀, t) = 2 * π * c₂ := by
  have hf1 : ContDiff ℝ 1 f := hf.of_le (by simp)
  have hd : ∀ t, HasDerivAt (fun t => c₂ * t + f (θ₀, t)) (Q (θ₀, t)) t := by
    intro t
    rw [hQf]
    have h := ((hasDerivAt_id t).const_mul c₂).add
      (dr_hasDerivAt_snd (hf1.differentiable one_ne_zero (θ₀, t)))
    simp only [id, mul_one] at h
    exact h
  have hQc : Continuous Q := by
    rw [show Q = fun p => c₂ + fderiv ℝ f p (0, 1) from funext hQf]
    exact continuous_const.add (dr_continuous_snd hf1)
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hd t)
    ((hQc.comp (by fun_prop : Continuous fun t : ℝ => (θ₀, t))).intervalIntegrable _ _)]
  have : f (θ₀, 2 * π) = f (θ₀, 0) := by simpa using hfψ (θ₀, 0)
  rw [this]; ring

theorem dr_green {P Q : ℝ × ℝ → ℝ} (hP : ContDiff ℝ 1 P) (hQ : ContDiff ℝ 1 Q)
    (hclosed : ∀ p : ℝ × ℝ, fderiv ℝ Q p (1, 0) = fderiv ℝ P p (0, 1)) (c θ ψ : ℝ) :
    ∫ s in (0:ℝ)..ψ, (Q (θ, s) - c) =
      (∫ s in (0:ℝ)..ψ, (Q (0, s) - c)) + ∫ t in (0:ℝ)..θ, (P (t, ψ) - P (t, 0)) := by
  have hQc := hQ.continuous
  have hPc := hP.continuous
  have key : ∫ s in (0:ℝ)..ψ, (Q (θ, s) - Q (0, s)) = ∫ t in (0:ℝ)..θ, (P (t, ψ) - P (t, 0)) := by
    calc ∫ s in (0:ℝ)..ψ, (Q (θ, s) - Q (0, s))
        = ∫ s in (0:ℝ)..ψ, ∫ t in (0:ℝ)..θ, fderiv ℝ P (t, s) (0, 1) := by
          congr 1; funext s
          rw [← dr_integral_fst hQ]
          simp only [hclosed]
      _ = ∫ t in (0:ℝ)..θ, ∫ s in (0:ℝ)..ψ, fderiv ℝ P (t, s) (0, 1) :=
          dr_swap (F := fun s t => fderiv ℝ P (t, s) (0, 1))
            ((dr_continuous_snd hP).comp (by fun_prop)) _ _ _ _
      _ = ∫ t in (0:ℝ)..θ, (P (t, ψ) - P (t, 0)) := by
          congr 1; funext t
          rw [dr_integral_snd hP]
  rw [← key, ← intervalIntegral.integral_add]
  · congr 1; funext s; ring
  · exact (by fun_prop : Continuous fun s : ℝ => Q ((0:ℝ), s) - c).intervalIntegrable _ _
  · exact (by fun_prop : Continuous fun s : ℝ => Q (θ, s) - Q ((0:ℝ), s)).intervalIntegrable _ _

#print axioms dr_hasFDerivAt_param
#print axioms dr_contDiff_param_nat
#print axioms dr_contDiff_param
#print axioms dr_contDiff_primitive
#print axioms dr_hasDerivAt_fst
#print axioms dr_hasDerivAt_snd
#print axioms dr_continuous_fst
#print axioms dr_continuous_snd
#print axioms dr_integral_fst
#print axioms dr_integral_snd
#print axioms dr_swap
#print axioms dr_loop_fst
#print axioms dr_loop_snd
#print axioms dr_green

/-- **The torus has b₁ = 2: H¹_dR(T²) is spanned by the turn form dθ and the bob form dψ.**
Let α = P dθ + Q dψ be a smooth 1-form on the torus (P and Q smooth on the plane and 2π-periodic
in θ and in ψ) that is closed (∂Q/∂θ = ∂P/∂ψ everywhere). Then there is exactly one pair of real
numbers (c₁, c₂) such that α − c₁ dθ − c₂ dψ is exact, that is, equals df for a smooth function f
on the torus. Existence says the classes [dθ] and [dψ] span the closed 1-forms modulo the exact
ones; uniqueness says no combination c₁ dθ + c₂ dψ other than 0 is exact. So the first de Rham
group of the torus has dimension 2. -/
theorem torus_first_de_rham_group_has_dimension_two {P Q : ℝ × ℝ → ℝ}
    (hP : ContDiff ℝ ∞ P) (hQ : ContDiff ℝ ∞ Q)
    (hPθ : Function.Periodic P ((2 * π, 0) : ℝ × ℝ)) (hPψ : Function.Periodic P ((0, 2 * π) : ℝ × ℝ))
    (hQθ : Function.Periodic Q ((2 * π, 0) : ℝ × ℝ)) (hQψ : Function.Periodic Q ((0, 2 * π) : ℝ × ℝ))
    (hclosed : ∀ p : ℝ × ℝ, fderiv ℝ Q p (1, 0) = fderiv ℝ P p (0, 1)) :
    ∃! c : ℝ × ℝ, ∃ f : ℝ × ℝ → ℝ, ContDiff ℝ ∞ f ∧
      Function.Periodic f ((2 * π, 0) : ℝ × ℝ) ∧ Function.Periodic f ((0, 2 * π) : ℝ × ℝ) ∧
      ∀ p : ℝ × ℝ, P p = c.1 + fderiv ℝ f p (1, 0) ∧ Q p = c.2 + fderiv ℝ f p (0, 1) := by
  have hP1 : ContDiff ℝ 1 P := hP.of_le (by simp)
  have hQ1 : ContDiff ℝ 1 Q := hQ.of_le (by simp)
  have hPc := hP1.continuous
  have hQc := hQ1.continuous
  have hπ : (2 * π) ≠ 0 := by positivity
  set c₁ := (2 * π)⁻¹ * ∫ t in (0:ℝ)..2 * π, P (t, 0) with hc₁
  set c₂ := (2 * π)⁻¹ * ∫ s in (0:ℝ)..2 * π, Q (0, s) with hc₂
  refine ⟨(c₁, c₂), ?_, ?_⟩
  · let f : ℝ × ℝ → ℝ := fun p =>
      (∫ s in (0:ℝ)..p.2, (Q (p.1, s) - c₂)) + ∫ t in (0:ℝ)..p.1, (P (t, 0) - c₁)
    have hfs : ContDiff ℝ ∞ f := by
      apply ContDiff.add
      · exact dr_contDiff_primitive (h := fun q => Q q - c₂) (hQ.sub contDiff_const)
      · have := dr_contDiff_primitive (h := fun q : ℝ × ℝ => P (q.2, 0) - c₁)
          ((hP.comp (by fun_prop)).sub contDiff_const)
        exact this.comp (contDiff_snd.prodMk contDiff_fst)
    have hf1 : ContDiff ℝ 1 f := hfs.of_le (by simp)
    have hθ : ∀ θ ψ, HasDerivAt (fun θ => f (θ, ψ)) (P (θ, ψ) - c₁) θ := by
      intro θ ψ
      have heq : (fun θ => f (θ, ψ)) = fun θ => (∫ s in (0:ℝ)..ψ, (Q (0, s) - c₂)) +
          (∫ t in (0:ℝ)..θ, (P (t, ψ) - P (t, 0))) + ∫ t in (0:ℝ)..θ, (P (t, 0) - c₁) := by
        funext θ
        simp only [f]
        rw [dr_green hP1 hQ1 hclosed]
      rw [heq]
      have h1 := ((by fun_prop : Continuous fun t : ℝ => P (t, ψ) - P (t, (0:ℝ))
        ).integral_hasStrictDerivAt 0 θ).hasDerivAt
      have h2 := ((by fun_prop : Continuous fun t : ℝ => P (t, (0:ℝ)) - c₁
        ).integral_hasStrictDerivAt 0 θ).hasDerivAt
      convert (h1.const_add _).add h2 using 1
      ring
    have hψ : ∀ θ ψ, HasDerivAt (fun ψ => f (θ, ψ)) (Q (θ, ψ) - c₂) ψ := by
      intro θ ψ
      have h1 := ((by fun_prop : Continuous fun s : ℝ => Q (θ, s) - c₂
        ).integral_hasStrictDerivAt 0 ψ).hasDerivAt
      exact h1.add_const (∫ t in (0:ℝ)..θ, (P (t, 0) - c₁))
    have hPint : ∫ t in (0:ℝ)..2 * π, (P (t, 0) - c₁) = 0 := by
      rw [intervalIntegral.integral_sub
        ((by fun_prop : Continuous fun t : ℝ => P (t, (0:ℝ))).intervalIntegrable _ _)
        intervalIntegrable_const, intervalIntegral.integral_const, hc₁]
      simp only [smul_eq_mul, sub_zero]
      rw [mul_inv_cancel_left₀ hπ]
      ring
    have hQint : ∫ s in (0:ℝ)..2 * π, (Q (0, s) - c₂) = 0 := by
      rw [intervalIntegral.integral_sub
        ((by fun_prop : Continuous fun s : ℝ => Q ((0:ℝ), s)).intervalIntegrable _ _)
        intervalIntegrable_const, intervalIntegral.integral_const, hc₂]
      simp only [smul_eq_mul, sub_zero]
      rw [mul_inv_cancel_left₀ hπ]
      ring
    refine ⟨f, hfs, ?_, ?_, ?_⟩
    · rintro ⟨θ, ψ⟩
      have hQ' : ∀ s, Q (θ + 2 * π, s) = Q (θ, s) := fun s => by simpa using hQθ (θ, s)
      have hper : Function.Periodic (fun t => P (t, 0) - c₁) (2 * π) := fun t => by
        have := hPθ (t, 0); simp only [Prod.mk_add_mk, add_zero] at this; simp [this]
      simp only [f, Prod.mk_add_mk, add_zero, hQ']
      congr 1
      rw [← intervalIntegral.integral_add_adjacent_intervals (b := θ)
        ((by fun_prop : Continuous fun t : ℝ => P (t, (0:ℝ)) - c₁).intervalIntegrable _ _)
        ((by fun_prop : Continuous fun t : ℝ => P (t, (0:ℝ)) - c₁).intervalIntegrable _ _),
        hper.intervalIntegral_add_eq θ 0, zero_add, hPint, add_zero]
    · rintro ⟨θ, ψ⟩
      have hper : Function.Periodic (fun s => Q (θ, s) - c₂) (2 * π) := fun s => by
        have := hQψ (θ, s); simp only [Prod.mk_add_mk, add_zero] at this; simp [this]
      have hP' : ∀ t, P (t, 2 * π) = P (t, 0) := fun t => by simpa using hPψ (t, 0)
      simp only [f, Prod.mk_add_mk, add_zero]
      congr 1
      rw [← intervalIntegral.integral_add_adjacent_intervals (b := ψ)
        ((by fun_prop : Continuous fun s : ℝ => Q (θ, s) - c₂).intervalIntegrable _ _)
        ((by fun_prop : Continuous fun s : ℝ => Q (θ, s) - c₂).intervalIntegrable _ _),
        hper.intervalIntegral_add_eq ψ 0, zero_add, dr_green hP1 hQ1 hclosed c₂ θ (2 * π), hQint]
      simp [hP']
    · rintro ⟨θ, ψ⟩
      constructor
      · have := (dr_hasDerivAt_fst (hf1.differentiable one_ne_zero (θ, ψ))).unique (hθ θ ψ)
        simp only; linarith
      · have := (dr_hasDerivAt_snd (hf1.differentiable one_ne_zero (θ, ψ))).unique (hψ θ ψ)
        simp only; linarith
  · rintro ⟨d₁, d₂⟩ ⟨g, hg, hgθ, hgψ, hPg⟩
    have h1 := dr_loop_fst hg hgθ (fun p => (hPg p).1) 0
    have h2 := dr_loop_snd hg hgψ (fun p => (hPg p).2) 0
    simp only at h1 h2
    rw [h1] at hc₁
    rw [h2] at hc₂
    ext
    · simp only; rw [hc₁]; field_simp
    · simp only; rw [hc₂]; field_simp

/-- **Loop integrals read the class (Step 0).** If α = c₁ dθ + c₂ dψ + df with f a smooth function
on the torus, then the integral of α once round any turn loop γ₁ (θ from 0 to 2π at a fixed crank
phase ψ₀) is 2π c₁, and once round any bob loop γ₂ (ψ from 0 to 2π at a fixed platform angle θ₀)
is 2π c₂: the exact part df adds 0 round every loop. -/
theorem loop_integrals_read_the_class {P Q f : ℝ × ℝ → ℝ} {c₁ c₂ : ℝ}
    (hf : ContDiff ℝ ∞ f)
    (hfθ : Function.Periodic f ((2 * π, 0) : ℝ × ℝ)) (hfψ : Function.Periodic f ((0, 2 * π) : ℝ × ℝ))
    (hPf : ∀ p : ℝ × ℝ, P p = c₁ + fderiv ℝ f p (1, 0))
    (hQf : ∀ p : ℝ × ℝ, Q p = c₂ + fderiv ℝ f p (0, 1)) :
    (∀ ψ₀ : ℝ, ∫ t in (0 : ℝ)..2 * π, P (t, ψ₀) = 2 * π * c₁) ∧
    (∀ θ₀ : ℝ, ∫ t in (0 : ℝ)..2 * π, Q (θ₀, t) = 2 * π * c₂) := by
  exact ⟨dr_loop_fst hf hfθ hPf, dr_loop_snd hf hfψ hQf⟩

/-- **Areas read the class too (Poincaré duality on the torus, Step 3).** With the duality pairing
⟨α, β⟩ = ∫ over the torus of α ∧ β, a form α = P dθ + Q dψ has ⟨α, dψ⟩ = ∫∫ P dθ dψ and
⟨dθ, α⟩ = ∫∫ Q dθ dψ over the square [0, 2π] × [0, 2π], while ⟨dθ, dψ⟩ = 4π². If
α = c₁ dθ + c₂ dψ + df with f a smooth function on the torus, then ⟨α, dψ⟩ = 4π² c₁ and
⟨dθ, α⟩ = 4π² c₂, so c₁ = ⟨α, dψ⟩ / 4π² and c₂ = ⟨dθ, α⟩ / 4π², the same numbers the loops give. -/
theorem area_pairings_read_the_class {P Q f : ℝ × ℝ → ℝ} {c₁ c₂ : ℝ}
    (hf : ContDiff ℝ ∞ f)
    (hfθ : Function.Periodic f ((2 * π, 0) : ℝ × ℝ)) (hfψ : Function.Periodic f ((0, 2 * π) : ℝ × ℝ))
    (hPf : ∀ p : ℝ × ℝ, P p = c₁ + fderiv ℝ f p (1, 0))
    (hQf : ∀ p : ℝ × ℝ, Q p = c₂ + fderiv ℝ f p (0, 1)) :
    (∫ ψ in (0 : ℝ)..2 * π, ∫ θ in (0 : ℝ)..2 * π, (1 : ℝ)) = 4 * π ^ 2 ∧
    (∫ ψ in (0 : ℝ)..2 * π, ∫ θ in (0 : ℝ)..2 * π, P (θ, ψ)) = 4 * π ^ 2 * c₁ ∧
    (∫ ψ in (0 : ℝ)..2 * π, ∫ θ in (0 : ℝ)..2 * π, Q (θ, ψ)) = 4 * π ^ 2 * c₂ := by
  have hf1 : ContDiff ℝ 1 f := hf.of_le (by simp)
  have hQc : Continuous Q := by
    rw [show Q = fun p => c₂ + fderiv ℝ f p (0, 1) from funext hQf]
    exact continuous_const.add (dr_continuous_snd hf1)
  refine ⟨?_, ?_, ?_⟩
  · simp only [intervalIntegral.integral_const, smul_eq_mul, sub_zero, mul_one]; ring
  · simp only [dr_loop_fst hf hfθ hPf]
    simp; ring
  · rw [dr_swap (F := fun ψ θ => Q (θ, ψ)) (hQc.comp (by fun_prop))]
    simp only [dr_loop_snd hf hfψ hQf]
    simp; ring

-- The carousel: a ride of 180 s at 15 s per turn makes 12 turns; 3 bobs per turn make 36 bobs.
example : (180 : ℕ) / 15 = 12 ∧ 3 * 12 = 36 := by decide

-- Mayer–Vietoris on two cylinders: both restriction maps have matrix [[-1, 1], [-1, 1]],
-- whose determinant is 0 (rank below 2); with rank 1, b₀ = 2 − 1, b₁ = (2 − 1) + (2 − 1), b₂ = 2 − 1.
example : !![(-1 : ℤ), 1; -1, 1].det = 0 := by norm_num [Matrix.det_fin_two]
example : (2 - 1 : ℕ) = 1 ∧ (2 - 1) + (2 - 1) = 2 ∧ (2 - 1 : ℕ) = 1 := by decide

-- The 3 × 3 grid torus: 9 corners, 27 edges, 18 triangles; Euler count 9 − 27 + 18 = 0,
-- so with b₀ = b₂ = 1 (duality), b₁ = 1 + 1 − 0 = 2.
example : 3 * 3 = 9 ∧ 3 * 9 = 27 ∧ 2 * 9 = 18 := by decide
example : (9 : ℤ) - 27 + 18 = 0 ∧ (1 : ℤ) + 1 - (9 - 27 + 18) = 2 := by decide

-- Exact ranks on the grid torus: rank d₁ = 8, rank d₂ = 17, so Betti numbers 9 − 8, 27 − 8 − 17, 18 − 17.
example : (9 - 8 : ℕ) = 1 ∧ 27 - 8 - 17 = 2 ∧ 18 - 17 = 1 := by decide

-- Try it: a surface with g = 2 handles has χ = 2 − 2g = −2, so b₁ = 1 + 1 − (−2) = 4.
example : (2 : ℤ) - 2 * 2 = -2 ∧ (1 : ℤ) + 1 - (2 - 2 * 2) = 4 := by decide

#print axioms torus_first_de_rham_group_has_dimension_two
#print axioms loop_integrals_read_the_class
#print axioms area_pairings_read_the_class
