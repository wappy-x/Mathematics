-- Reflection: on the half-line x ≥ 0, d'Alembert's formula run on the data extended oddly is the one classical solution with the end held at zero, extended evenly it solves the free-end problem, and near the end it reads as the incoming wave plus a flipped echo.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic.NormNum
import Mathlib

open Set

/-- The odd extension: the data copied past the end `x = 0`, upside down. -/
noncomputable def oddExt (f : ℝ → ℝ) (x : ℝ) : ℝ := if 0 ≤ x then f x else -f (-x)

/-- The even extension: the data copied past the end `x = 0`, upright. -/
noncomputable def evenExt (f : ℝ → ℝ) (x : ℝ) : ℝ := f |x|

/-- D'Alembert's whole-line formula with wave speed `c`, starting shape `F` and starting
velocity `G`. -/
noncomputable def dAlembert (c : ℝ) (F G : ℝ → ℝ) (x t : ℝ) : ℝ :=
  (F (x - c * t) + F (x + c * t)) / 2 + 1 / (2 * c) * ∫ s in (x - c * t)..(x + c * t), G s

/-- A classical solution of the half-line wave problem with a clamped end: `u` has continuous
second rates on the closed quarter-plane `x ≥ 0, t ≥ 0`, solves `u_tt = c^2 u_xx` for `x > 0`,
`t > 0`, starts with shape `f` and velocity `g` on `x ≥ 0`, and `u(0, t) = 0` for `t ≥ 0`. -/
def IsClampedHalfLineSolution (c : ℝ) (f g : ℝ → ℝ) (u : ℝ → ℝ → ℝ) : Prop :=
  ContDiffOn ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2) (Ici 0 ×ˢ Ici 0) ∧
  (∀ x t, 0 < x → 0 < t → deriv (fun t => deriv (fun t => u x t) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) ∧
  (∀ x, 0 ≤ x → u x 0 = f x) ∧
  (∀ x, 0 ≤ x → derivWithin (fun t => u x t) (Ici 0) 0 = g x) ∧
  (∀ t, 0 ≤ t → u 0 t = 0)

/-- A classical solution of the half-line wave problem with a free end: as above, but the end
condition is zero slope, `u_x(0, t) = 0` for `t ≥ 0`. -/
def IsFreeHalfLineSolution (c : ℝ) (f g : ℝ → ℝ) (u : ℝ → ℝ → ℝ) : Prop :=
  ContDiffOn ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2) (Ici 0 ×ˢ Ici 0) ∧
  (∀ x t, 0 < x → 0 < t → deriv (fun t => deriv (fun t => u x t) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) ∧
  (∀ x, 0 ≤ x → u x 0 = f x) ∧
  (∀ x, 0 ≤ x → derivWithin (fun t => u x t) (Ici 0) 0 = g x) ∧
  (∀ t, 0 ≤ t → derivWithin (fun x => u x t) (Ici 0) 0 = 0)

lemma glue_hasDerivAt {F D : ℝ → ℝ}
    (h1 : ∀ x, 0 ≤ x → HasDerivWithinAt F (D x) (Ici 0) x)
    (h2 : ∀ x, x ≤ 0 → HasDerivWithinAt F (D x) (Iic 0) x) (x : ℝ) : HasDerivAt F (D x) x := by
  rcases lt_trichotomy x 0 with hx | rfl | hx
  · exact (h2 x hx.le).hasDerivAt (Iic_mem_nhds hx)
  · have := (h2 0 le_rfl).union (h1 0 le_rfl)
    rwa [Iic_union_Ici, hasDerivWithinAt_univ] at this
  · exact (h1 x hx.le).hasDerivAt (Ici_mem_nhds hx)

#print axioms glue_hasDerivAt

lemma oddExt_hasDerivAt {h h' : ℝ → ℝ} (hd : ∀ x, 0 ≤ x → HasDerivWithinAt h (h' x) (Ici 0) x)
    (h0 : h 0 = 0) (x : ℝ) : HasDerivAt (oddExt h) (evenExt h' x) x := by
  apply glue_hasDerivAt (D := evenExt h') _ _ x
  · intro y hy
    rw [evenExt, abs_of_nonneg hy]
    exact (hd y hy).congr (fun z hz => by simp [oddExt, (show (0:ℝ) ≤ z from hz)])
      (by simp [oddExt, hy])
  · intro y hy
    have hn : HasDerivWithinAt (fun z : ℝ => -z) (-1) (Iic 0) y :=
      (hasDerivAt_neg' y).hasDerivWithinAt
    have hc := (hd (-y) (by linarith)).comp y hn (fun z hz => by
      simp only [mem_Iic, mem_Ici] at hz ⊢; linarith)
    rw [evenExt, abs_of_nonpos hy]
    refine (hc.neg.congr (fun z hz => ?_) ?_).congr_deriv (by ring)
    · simp only [mem_Iic] at hz
      simp only [oddExt]
      split_ifs with hz'
      · have : z = 0 := le_antisymm hz hz'
        subst this; simp [h0]
      · rfl
    · simp only [oddExt]
      split_ifs with hy'
      · have : y = 0 := le_antisymm hy hy'
        subst this; simp [h0]
      · rfl

#print axioms oddExt_hasDerivAt

lemma evenExt_hasDerivAt {h h' : ℝ → ℝ} (hd : ∀ x, 0 ≤ x → HasDerivWithinAt h (h' x) (Ici 0) x)
    (h0 : h' 0 = 0) (x : ℝ) : HasDerivAt (evenExt h) (oddExt h' x) x := by
  apply glue_hasDerivAt (D := oddExt h') _ _ x
  · intro y hy
    simp only [oddExt, hy, ↓reduceIte]
    exact (hd y hy).congr (fun z hz => by simp [evenExt, abs_of_nonneg (show (0:ℝ) ≤ z from hz)])
      (by simp [evenExt, abs_of_nonneg hy])
  · intro y hy
    have hn : HasDerivWithinAt (fun z : ℝ => -z) (-1) (Iic 0) y :=
      (hasDerivAt_neg' y).hasDerivWithinAt
    have hc := (hd (-y) (by linarith)).comp y hn (fun z hz => by
      simp only [mem_Iic, mem_Ici] at hz ⊢; linarith)
    refine (hc.congr (fun z hz => ?_) ?_).congr_deriv ?_
    · simp only [mem_Iic] at hz
      simp [evenExt, Function.comp, abs_of_nonpos hz]
    · simp [evenExt, Function.comp, abs_of_nonpos hy]
    · simp only [oddExt]
      split_ifs with hy'
      · have : y = 0 := le_antisymm hy hy'
        subst this; simp [h0]
      · ring

#print axioms evenExt_hasDerivAt

lemma evenExt_continuous {h : ℝ → ℝ} (hc : ContinuousOn h (Ici 0)) : Continuous (evenExt h) :=
  hc.comp_continuous continuous_abs (fun x => abs_nonneg x)

#print axioms evenExt_continuous

lemma oddExt_eq_max {h : ℝ → ℝ} (h0 : h 0 = 0) :
    oddExt h = fun x => h (max x 0) - h (max (-x) 0) := by
  funext x
  simp only [oddExt]
  split_ifs with hx
  · simp [max_eq_left hx, max_eq_right (by linarith : -x ≤ 0), h0]
  · simp [max_eq_right (by linarith : x ≤ 0), max_eq_left (by linarith : 0 ≤ -x), h0]

#print axioms oddExt_eq_max

lemma oddExt_continuous {h : ℝ → ℝ} (hc : ContinuousOn h (Ici 0)) (h0 : h 0 = 0) :
    Continuous (oddExt h) := by
  rw [oddExt_eq_max h0]
  exact (hc.comp_continuous (continuous_id.max continuous_const) (fun x => (le_max_right x 0 : (0:ℝ) ≤ _))).sub
    (hc.comp_continuous (continuous_neg.max continuous_const) (fun x => (le_max_right (-x) 0 : (0:ℝ) ≤ _)))

#print axioms oddExt_continuous

lemma oddExt_neg {h : ℝ → ℝ} (h0 : h 0 = 0) (x : ℝ) : oddExt h (-x) = -oddExt h x := by
  rw [oddExt_eq_max h0]
  simp only [neg_neg]
  ring

#print axioms oddExt_neg

lemma contDiff_two_of_hasDerivAt {F F' F'' : ℝ → ℝ} (h1 : ∀ x, HasDerivAt F (F' x) x)
    (h2 : ∀ x, HasDerivAt F' (F'' x) x) (h3 : Continuous F'') : ContDiff ℝ 2 F := by
  have e1 : deriv F = F' := funext fun x => (h1 x).deriv
  have e2 : deriv F' = F'' := funext fun x => (h2 x).deriv
  rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
  refine ⟨fun x => (h1 x).differentiableAt, by simp, ?_⟩
  rw [e1, contDiff_one_iff_deriv, e2]
  exact ⟨fun x => (h2 x).differentiableAt, h3⟩

#print axioms contDiff_two_of_hasDerivAt

lemma contDiff_one_of_hasDerivAt {F F' : ℝ → ℝ} (h1 : ∀ x, HasDerivAt F (F' x) x)
    (h3 : Continuous F') : ContDiff ℝ 1 F := by
  have e1 : deriv F = F' := funext fun x => (h1 x).deriv
  rw [contDiff_one_iff_deriv, e1]
  exact ⟨fun x => (h1 x).differentiableAt, h3⟩

#print axioms contDiff_one_of_hasDerivAt

lemma halfline_data {f : ℝ → ℝ} (hf : ContDiffOn ℝ 1 f (Ici 0)) :
    (∀ x, 0 ≤ x → HasDerivWithinAt f (derivWithin f (Ici 0) x) (Ici 0) x) ∧
    ContinuousOn (derivWithin f (Ici 0)) (Ici 0) :=
  ⟨fun x hx => ((hf.differentiableOn one_ne_zero) x hx).hasDerivWithinAt,
    hf.continuousOn_derivWithin (uniqueDiffOn_Ici 0) le_rfl⟩

#print axioms halfline_data

lemma hd_sub_t {φ φ' : ℝ → ℝ} (h : ∀ y, HasDerivAt φ (φ' y) y) (x c t : ℝ) :
    HasDerivAt (fun t => φ (x - c * t)) (-c * φ' (x - c * t)) t := by
  have := (h (x - c * t)).comp t (((hasDerivAt_id' t).const_mul c).const_sub x)
  exact this.congr_deriv (by ring)

#print axioms hd_sub_t

lemma hd_add_t {φ φ' : ℝ → ℝ} (h : ∀ y, HasDerivAt φ (φ' y) y) (x c t : ℝ) :
    HasDerivAt (fun t => φ (x + c * t)) (c * φ' (x + c * t)) t := by
  have := (h (x + c * t)).comp t (((hasDerivAt_id' t).const_mul c).const_add x)
  exact this.congr_deriv (by ring)

#print axioms hd_add_t

lemma hd_sub_x {φ φ' : ℝ → ℝ} (h : ∀ y, HasDerivAt φ (φ' y) y) (x c t : ℝ) :
    HasDerivAt (fun x => φ (x - c * t)) (φ' (x - c * t)) x := by
  have := (h (x - c * t)).comp x ((hasDerivAt_id' x).sub_const (c * t))
  exact this.congr_deriv (by ring)

#print axioms hd_sub_x

lemma hd_add_x {φ φ' : ℝ → ℝ} (h : ∀ y, HasDerivAt φ (φ' y) y) (x c t : ℝ) :
    HasDerivAt (fun x => φ (x + c * t)) (φ' (x + c * t)) x := by
  have := (h (x + c * t)).comp x ((hasDerivAt_id' x).add_const (c * t))
  exact this.congr_deriv (by ring)

#print axioms hd_add_x

lemma wave_core (c : ℝ) (hc : c ≠ 0) (F G P : ℝ → ℝ) (u : ℝ → ℝ → ℝ)
    (hF : ContDiff ℝ 2 F) (hG : ContDiff ℝ 1 G) (hP : ∀ y, HasDerivAt P (G y) y)
    (hu : ∀ x t, u x t =
      (F (x - c * t) + F (x + c * t)) / 2 + 1 / (2 * c) * (P (x + c * t) - P (x - c * t))) :
    ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2) ∧
    (∀ x t, deriv (fun t => deriv (fun t => u x t) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) ∧
    (∀ x t, HasDerivAt (fun t => u x t) ((-c * deriv F (x - c * t) + c * deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (c * G (x + c * t) + c * G (x - c * t))) t) ∧
    (∀ x t, HasDerivAt (fun x => u x t) ((deriv F (x - c * t) + deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t))) x) := by
  have hu' : u = fun x t =>
      (F (x - c * t) + F (x + c * t)) / 2 + 1 / (2 * c) * (P (x + c * t) - P (x - c * t)) :=
    funext fun x => funext fun t => hu x t
  subst hu'
  have hFd : ∀ y, HasDerivAt F (deriv F y) y := fun y =>
    ((hF.differentiable (by norm_num)) y).hasDerivAt
  have hF1 : ContDiff ℝ 1 (deriv F) := by
    rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv] at hF
    exact hF.2.2
  have hF2d : ∀ y, HasDerivAt (deriv F) (deriv (deriv F) y) y := fun y =>
    ((hF1.differentiable one_ne_zero) y).hasDerivAt
  have hGd : ∀ y, HasDerivAt G (deriv G y) y := fun y =>
    ((hG.differentiable one_ne_zero) y).hasDerivAt
  have hP2 : ContDiff ℝ 2 P := by
    rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
    refine ⟨fun y => (hP y).differentiableAt, by simp, ?_⟩
    rw [show deriv P = G from funext fun y => (hP y).deriv]
    exact hG
  have ht : ∀ x t, HasDerivAt (fun t => (F (x - c * t) + F (x + c * t)) / 2 +
      1 / (2 * c) * (P (x + c * t) - P (x - c * t)))
      ((-c * deriv F (x - c * t) + c * deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (c * G (x + c * t) + c * G (x - c * t))) t := by
    intro x t
    have := (((hd_sub_t hFd x c t).add (hd_add_t hFd x c t)).div_const 2).add
      (((hd_add_t hP x c t).sub (hd_sub_t hP x c t)).const_mul (1 / (2 * c)))
    exact this.congr_deriv (by ring)
  have hx : ∀ x t, HasDerivAt (fun x => (F (x - c * t) + F (x + c * t)) / 2 +
      1 / (2 * c) * (P (x + c * t) - P (x - c * t)))
      ((deriv F (x - c * t) + deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t))) x := by
    intro x t
    exact (((hd_sub_x hFd x c t).add (hd_add_x hFd x c t)).div_const 2).add
      (((hd_add_x hP x c t).sub (hd_sub_x hP x c t)).const_mul (1 / (2 * c)))
  refine ⟨?_, ?_, ht, hx⟩
  · fun_prop
  · intro x t
    rw [show (fun t => deriv (fun t => (F (x - c * t) + F (x + c * t)) / 2 +
      1 / (2 * c) * (P (x + c * t) - P (x - c * t))) t) = fun t =>
      (-c * deriv F (x - c * t) + c * deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (c * G (x + c * t) + c * G (x - c * t)) from funext fun t => (ht x t).deriv]
    rw [show (fun x => deriv (fun x => (F (x - c * t) + F (x + c * t)) / 2 +
      1 / (2 * c) * (P (x + c * t) - P (x - c * t))) x) = fun x =>
      (deriv F (x - c * t) + deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t)) from funext fun x => (hx x t).deriv]
    have h1 := ((((hd_sub_t hF2d x c t).const_mul (-c)).add
      ((hd_add_t hF2d x c t).const_mul c)).div_const 2).add
      ((((hd_add_t hGd x c t).const_mul c).add ((hd_sub_t hGd x c t).const_mul c)).const_mul
        (1 / (2 * c)))
    have h2 := (((hd_sub_x hF2d x c t).add (hd_add_x hF2d x c t)).div_const 2).add
      (((hd_add_x hGd x c t).sub (hd_sub_x hGd x c t)).const_mul (1 / (2 * c)))
    rw [show deriv (fun t => (-c * deriv F (x - c * t) + c * deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (c * G (x + c * t) + c * G (x - c * t))) t = _ from h1.deriv,
      show deriv (fun x => (deriv F (x - c * t) + deriv F (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t))) x = _ from h2.deriv]
    field_simp
    ring

#print axioms wave_core

lemma const_of_hasDerivAt_zero {φ : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hc : ContinuousOn φ (Icc a b)) (hd : ∀ s ∈ Ioo a b, HasDerivAt φ 0 s) : φ b = φ a := by
  rcases hab.eq_or_lt with rfl | hlt
  · rfl
  · obtain ⟨s, _, h⟩ := exists_hasDerivAt_eq_slope φ (fun _ => 0) hlt hc hd
    have hne : b - a ≠ 0 := sub_ne_zero.mpr hlt.ne'
    have := (eq_div_iff hne).mp h
    linarith

#print axioms const_of_hasDerivAt_zero

lemma lin2 {M : Type*} [AddCommGroup M] [TopologicalSpace M] [Module ℝ M]
    (L : ℝ × ℝ →L[ℝ] M) (a b : ℝ) : L (a, b) = a • L (1, 0) + b • L (0, 1) := by
  have : ((a, b) : ℝ × ℝ) = a • ((1 : ℝ), (0 : ℝ)) + b • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  rw [this, map_add, map_smul, map_smul]

#print axioms lin2

lemma quad_mem_nhds {x t : ℝ} (hx : 0 < x) (ht : 0 < t) :
    Ici (0 : ℝ) ×ˢ Ici (0 : ℝ) ∈ nhds (x, t) :=
  prod_mem_nhds (Ici_mem_nhds hx) (Ici_mem_nhds ht)

#print axioms quad_mem_nhds

lemma slice_fst {V : ℝ × ℝ → ℝ} (hV : DifferentiableOn ℝ V (Ici 0 ×ˢ Ici 0)) {x t : ℝ}
    (hx : 0 ≤ x) (ht : 0 ≤ t) :
    HasDerivWithinAt (fun y => V (y, t)) (fderivWithin ℝ V (Ici 0 ×ˢ Ici 0) (x, t) (1, 0))
      (Ici 0) x := by
  have h1 := (hV (x, t) ⟨hx, ht⟩).hasFDerivWithinAt
  have h2 : HasDerivWithinAt (fun y : ℝ => (y, t)) ((1 : ℝ), (0 : ℝ)) (Ici 0) x :=
    ((hasDerivAt_id' x).prodMk (hasDerivAt_const x t)).hasDerivWithinAt
  exact h1.comp_hasDerivWithinAt x h2 (fun y hy => mk_mem_prod hy (show t ∈ Ici (0 : ℝ) from ht))

#print axioms slice_fst

lemma slice_snd {V : ℝ × ℝ → ℝ} (hV : DifferentiableOn ℝ V (Ici 0 ×ˢ Ici 0)) {x t : ℝ}
    (hx : 0 ≤ x) (ht : 0 ≤ t) :
    HasDerivWithinAt (fun s => V (x, s)) (fderivWithin ℝ V (Ici 0 ×ˢ Ici 0) (x, t) (0, 1))
      (Ici 0) t := by
  have h1 := (hV (x, t) ⟨hx, ht⟩).hasFDerivWithinAt
  have h2 : HasDerivWithinAt (fun s : ℝ => (x, s)) ((0 : ℝ), (1 : ℝ)) (Ici 0) t :=
    ((hasDerivAt_const t x).prodMk (hasDerivAt_id' t)).hasDerivWithinAt
  exact h1.comp_hasDerivWithinAt t h2 (fun s hs => ⟨hx, hs⟩)

#print axioms slice_snd

lemma slice_snd_interior {V : ℝ × ℝ → ℝ} (hV : ContDiffOn ℝ 2 V (Ici 0 ×ˢ Ici 0)) {x t : ℝ}
    (hx : 0 < x) (ht : 0 < t) :
    HasDerivAt (fun s => V (x, s)) (fderivWithin ℝ V (Ici 0 ×ˢ Ici 0) (x, t) (0, 1)) t := by
  have hd : DifferentiableAt ℝ V (x, t) :=
    (hV.contDiffAt (quad_mem_nhds hx ht)).differentiableAt (by norm_num)
  rw [fderivWithin_of_mem_nhds (quad_mem_nhds hx ht)]
  exact hd.hasFDerivAt.comp_hasDerivAt t ((hasDerivAt_const t x).prodMk (hasDerivAt_id' t))

#print axioms slice_snd_interior

lemma pde_fderiv {c : ℝ} {v : ℝ → ℝ → ℝ}
    (hV : ContDiffOn ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2) (Ici 0 ×ˢ Ici 0))
    {x t : ℝ} (hx : 0 < x) (ht : 0 < t)
    (hpde : deriv (fun t => deriv (fun t => v x t) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x) :
    fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t) (0, 1) (0, 1) =
      c ^ 2 * fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t) (1, 0) (1, 0) := by
  have hdiff : ∀ y s, 0 < y → 0 < s → DifferentiableAt ℝ (fun p : ℝ × ℝ => v p.1 p.2) (y, s) :=
    fun y s hy hs => (hV.contDiffAt (quad_mem_nhds hy hs)).differentiableAt (by norm_num)
  have hD2 : DifferentiableAt ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t) :=
    ((hV.contDiffAt (quad_mem_nhds hx ht)).fderiv_right (m := 1) (by norm_num)).differentiableAt
      (by norm_num)
  have et : deriv (fun t => deriv (fun t => v x t) t) t =
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t) (0, 1) (0, 1) := by
    have hev : (fun s => deriv (fun t => v x t) s) =ᶠ[nhds t]
        (fun s => fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (x, s) (0, 1)) := by
      filter_upwards [Ioi_mem_nhds ht] with s hs
      exact ((hdiff x s hx hs).hasFDerivAt.comp_hasDerivAt s
        ((hasDerivAt_const s x).prodMk (hasDerivAt_id' s))).deriv
    rw [hev.deriv_eq]
    have hc : HasDerivAt (fun s => fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (x, s))
        (fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t) (0, 1)) t :=
      hD2.hasFDerivAt.comp_hasDerivAt t ((hasDerivAt_const t x).prodMk (hasDerivAt_id' t))
    have := hc.clm_apply (hasDerivAt_const t ((0 : ℝ), (1 : ℝ)))
    rw [this.deriv]
    simp
  have ex : deriv (fun x => deriv (fun x => v x t) x) x =
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t) (1, 0) (1, 0) := by
    have hev : (fun y => deriv (fun x => v x t) y) =ᶠ[nhds x]
        (fun y => fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (y, t) (1, 0)) := by
      filter_upwards [Ioi_mem_nhds hx] with y hy
      exact ((hdiff y t hy ht).hasFDerivAt.comp_hasDerivAt y
        ((hasDerivAt_id' y).prodMk (hasDerivAt_const y t))).deriv
    rw [hev.deriv_eq]
    have hc : HasDerivAt (fun y => fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (y, t))
        (fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t) (1, 0)) x :=
      hD2.hasFDerivAt.comp_hasDerivAt x ((hasDerivAt_id' x).prodMk (hasDerivAt_const x t))
    have := hc.clm_apply (hasDerivAt_const x ((1 : ℝ), (0 : ℝ)))
    rw [this.deriv]
    simp
  rw [← et, ← ex]
  exact hpde

#print axioms pde_fderiv

lemma char_deriv {c : ℝ} {v : ℝ → ℝ → ℝ}
    (hV : ContDiffOn ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2) (Ici 0 ×ˢ Ici 0))
    {x t : ℝ} (hx : 0 < x) (ht : 0 < t)
    (hpde : deriv (fun t => deriv (fun t => v x t) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x) (a : ℝ) (ha : a ^ 2 = c ^ 2) :
    ∃ L : ℝ × ℝ →L[ℝ] ℝ, HasFDerivAt (fun p => fderivWithin ℝ (fun p : ℝ × ℝ => v p.1 p.2)
      (Ici 0 ×ˢ Ici 0) p (a, 1)) L (x, t) ∧ L (-a, 1) = 0 := by
  have hVq := hV.contDiffAt (quad_mem_nhds hx ht)
  have hD2 : HasFDerivAt (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2))
      (fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t)) (x, t) :=
    ((hVq.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)).hasFDerivAt
  have hev : (fun p => fderivWithin ℝ (fun p : ℝ × ℝ => v p.1 p.2) (Ici 0 ×ˢ Ici 0) p (a, 1))
      =ᶠ[nhds (x, t)] (fun p => fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) p (a, 1)) := by
    filter_upwards [prod_mem_nhds (Ioi_mem_nhds hx) (Ioi_mem_nhds ht)] with p hp
    rw [fderivWithin_of_mem_nhds (prod_mem_nhds (Ici_mem_nhds hp.1) (Ici_mem_nhds hp.2))]
  refine ⟨_, (hD2.clm_apply (hasFDerivAt_const ((a : ℝ), (1 : ℝ)) (x, t))).congr_of_eventuallyEq
    hev, ?_⟩
  have hsym := hVq.isSymmSndFDerivAt (by simp)
  have hp := pde_fderiv hV hx ht hpde
  set D2 := fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2)) (x, t)
  have hs := hsym (1, 0) (0, 1)
  simp only [ContinuousLinearMap.comp_zero, ContinuousLinearMap.flip_apply, zero_add]
  rw [lin2 D2 (-a) 1]
  simp only [add_apply, smul_apply, smul_eq_mul]
  rw [lin2 (D2 (1, 0)) a 1, lin2 (D2 (0, 1)) a 1]
  simp only [smul_eq_mul]
  linear_combination (-a) * hs + hp - D2 (1, 0) (1, 0) * ha

#print axioms char_deriv

lemma transport {Φ : ℝ × ℝ → ℝ} {Q : Set (ℝ × ℝ)} (hcont : ContinuousOn Φ Q)
    (x0 t0 d T : ℝ) (hT : 0 ≤ T) (hmaps : ∀ s ∈ Icc 0 T, (x0 + d * s, t0 - s) ∈ Q)
    (hderiv : ∀ s ∈ Ioo 0 T, ∃ L : ℝ × ℝ →L[ℝ] ℝ,
      HasFDerivAt Φ L (x0 + d * s, t0 - s) ∧ L (-d, 1) = 0) :
    Φ (x0 + d * T, t0 - T) = Φ (x0, t0) := by
  have key := const_of_hasDerivAt_zero (φ := fun s => Φ (x0 + d * s, t0 - s)) hT
    (hcont.comp (by fun_prop : Continuous fun s : ℝ => (x0 + d * s, t0 - s)).continuousOn hmaps)
    (fun s hs => by
      obtain ⟨L, hL, hL0⟩ := hderiv s hs
      have hγ : HasDerivAt (fun s : ℝ => (x0 + d * s, t0 - s)) (d * 1, -1) s :=
        (((hasDerivAt_id' s).const_mul d).const_add x0).prodMk ((hasDerivAt_id' s).const_sub t0)
      have := hL.comp_hasDerivAt s hγ
      refine this.congr_deriv ?_
      rw [lin2 L (d * 1) (-1)]
      rw [lin2 L (-d) 1] at hL0
      simp only [smul_eq_mul] at hL0 ⊢
      linarith)
  simpa using key

#print axioms transport

lemma clamped_unique {c : ℝ} (hc : 0 < c) {f g : ℝ → ℝ} {v w : ℝ → ℝ → ℝ}
    (hv : IsClampedHalfLineSolution c f g v) (hw : IsClampedHalfLineSolution c f g w)
    (x t : ℝ) (hx : 0 ≤ x) (ht : 0 ≤ t) : v x t = w x t := by
  obtain ⟨hV2, hVp, hV0, hV1, hVb⟩ := hv
  obtain ⟨hW2, hWp, hW0, hW1, hWb⟩ := hw
  have hQu : UniqueDiffOn ℝ (Ici (0 : ℝ) ×ˢ Ici (0 : ℝ)) :=
    (uniqueDiffOn_Ici 0).prod (uniqueDiffOn_Ici 0)
  have hVd := hV2.differentiableOn (by norm_num)
  have hWd := hW2.differentiableOn (by norm_num)
  -- the difference of the two derivatives
  let D : ℝ × ℝ → ℝ × ℝ →L[ℝ] ℝ := fun p =>
    fderivWithin ℝ (fun p : ℝ × ℝ => v p.1 p.2) (Ici 0 ×ˢ Ici 0) p -
    fderivWithin ℝ (fun p : ℝ × ℝ => w p.1 p.2) (Ici 0 ×ˢ Ici 0) p
  have hDc : ∀ a : ℝ, ContinuousOn (fun p => D p (a, 1)) (Ici 0 ×ˢ Ici 0) := by
    intro a
    have h1 := hV2.continuousOn_fderivWithin hQu (by norm_num)
    have h2 := hW2.continuousOn_fderivWithin hQu (by norm_num)
    exact (h1.sub h2).clm_apply continuousOn_const
  have hDd : ∀ a : ℝ, a ^ 2 = c ^ 2 → ∀ y s : ℝ, 0 < y → 0 < s →
      ∃ L : ℝ × ℝ →L[ℝ] ℝ, HasFDerivAt (fun p => D p (a, 1)) L (y, s) ∧ L (-a, 1) = 0 := by
    intro a ha y s hy hs
    obtain ⟨L1, h1, e1⟩ := char_deriv hV2 hy hs (hVp y s hy hs) a ha
    obtain ⟨L2, h2, e2⟩ := char_deriv hW2 hy hs (hWp y s hy hs) a ha
    refine ⟨L1 - L2, ?_, by simp [e1, e2]⟩
    exact h1.sub h2
  have hD0x : ∀ y, 0 ≤ y → D (y, 0) (1, 0) = 0 := by
    intro y hy
    have e1 := (slice_fst hVd hy le_rfl).derivWithin (uniqueDiffOn_Ici 0 y hy)
    have e2 := (slice_fst hWd hy le_rfl).derivWithin (uniqueDiffOn_Ici 0 y hy)
    have c1 : derivWithin (fun z => v z 0) (Ici 0) y = derivWithin f (Ici 0) y :=
      derivWithin_congr (fun z hz => hV0 z hz) (hV0 y hy)
    have c2 : derivWithin (fun z => w z 0) (Ici 0) y = derivWithin f (Ici 0) y :=
      derivWithin_congr (fun z hz => hW0 z hz) (hW0 y hy)
    simp only [D, sub_apply]
    rw [← e1, ← e2]
    exact sub_eq_zero.mpr (c1.trans c2.symm)
  have hD0t : ∀ y, 0 ≤ y → D (y, 0) (0, 1) = 0 := by
    intro y hy
    have e1 := (slice_snd hVd hy le_rfl).derivWithin (uniqueDiffOn_Ici 0 0 (show (0 : ℝ) ∈ Ici (0 : ℝ) from mem_Ici.mpr le_rfl))
    have e2 := (slice_snd hWd hy le_rfl).derivWithin (uniqueDiffOn_Ici 0 0 (show (0 : ℝ) ∈ Ici (0 : ℝ) from mem_Ici.mpr le_rfl))
    simp only [D, sub_apply]
    rw [← e1, ← e2]
    exact sub_eq_zero.mpr ((hV1 y hy).trans (hW1 y hy).symm)
  have hDb : ∀ s, 0 ≤ s → D (0, s) (0, 1) = 0 := by
    intro s hs
    have e1 := (slice_snd hVd le_rfl hs).derivWithin (uniqueDiffOn_Ici 0 s hs)
    have e2 := (slice_snd hWd le_rfl hs).derivWithin (uniqueDiffOn_Ici 0 s hs)
    have c1 : derivWithin (fun z => v 0 z) (Ici 0) s = 0 := by
      rw [derivWithin_congr (f := fun _ => (0 : ℝ)) (fun z hz => hVb z hz) (hVb s hs)]
      simp
    have c2 : derivWithin (fun z => w 0 z) (Ici 0) s = 0 := by
      rw [derivWithin_congr (f := fun _ => (0 : ℝ)) (fun z hz => hWb z hz) (hWb s hs)]
      simp
    simp only [D, sub_apply]
    rw [← e1, ← e2]
    rw [c1, c2, sub_zero]
  -- the incoming combination vanishes
  have hA : ∀ y s, 0 ≤ y → 0 ≤ s → D (y, s) (c, 1) = 0 := by
    intro y s hy hs
    have := transport (hDc c) y s c s hs
      (fun r hr => ⟨by simp only [mem_Ici]; nlinarith [hr.1], by simp only [mem_Ici]; linarith [hr.2]⟩)
      (fun r hr => hDd c rfl _ _ (by nlinarith [hr.1]) (by linarith [hr.2]))
    rw [← this, sub_self, lin2]
    simp only [smul_eq_mul]
    rw [hD0x _ (by nlinarith), hD0t _ (by nlinarith)]
    ring
  have hB : ∀ y s, 0 ≤ y → 0 ≤ s → D (y, s) (-c, 1) = 0 := by
    intro y s hy hs
    by_cases hys : c * s ≤ y
    · have := transport (hDc (-c)) y s (-c) s hs
        (fun r hr => ⟨by simp only [mem_Ici]; nlinarith [hr.2], by simp only [mem_Ici]; linarith [hr.2]⟩)
        (fun r hr => by
          have := hDd (-c) (by ring) (y + -c * r) (s - r) (by nlinarith [hr.2]) (by linarith [hr.2])
          simpa using this)
      rw [← this, sub_self, lin2]
      simp only [smul_eq_mul]
      rw [hD0x _ (by linarith), hD0t _ (by linarith)]
      ring
    · push Not at hys
      have hyc : y / c ≤ s := by rw [div_le_iff₀ hc]; linarith
      have hyc0 : 0 ≤ y / c := div_nonneg hy hc.le
      have := transport (hDc (-c)) y s (-c) (y / c) hyc0
        (fun r hr => ⟨by
            simp only [mem_Ici]
            have : c * r ≤ y := by have := hr.2; rw [le_div_iff₀ hc] at this; linarith
            linarith,
          by simp only [mem_Ici]; linarith [hr.2]⟩)
        (fun r hr => by
          have h1 : c * r < y := by have := hr.2; rw [lt_div_iff₀ hc] at this; linarith
          have := hDd (-c) (by ring) (y + -c * r) (s - r) (by linarith) (by linarith [hr.2])
          simpa using this)
      have e0 : y + -c * (y / c) = 0 := by field_simp; ring
      rw [← this, e0, lin2]
      have hA0 := hA 0 (s - y / c) le_rfl (by linarith)
      rw [lin2] at hA0
      simp only [smul_eq_mul] at hA0 ⊢
      rw [hDb _ (by linarith)] at hA0 ⊢
      linarith
  -- so the time rates agree everywhere on the quarter-plane
  have hT : ∀ y s, 0 ≤ y → 0 ≤ s → D (y, s) (0, 1) = 0 := by
    intro y s hy hs
    have h1 := hA y s hy hs
    have h2 := hB y s hy hs
    rw [lin2] at h1 h2
    simp only [smul_eq_mul] at h1 h2
    linarith
  rcases hx.eq_or_lt with rfl | hx'
  · rw [hVb t ht, hWb t ht]
  · have key := const_of_hasDerivAt_zero (φ := fun s => v x s - w x s) ht
      ((hV2.continuousOn.comp (by fun_prop : Continuous fun s : ℝ => (x, s)).continuousOn
          (fun s (hs : s ∈ Icc 0 t) => mk_mem_prod (show x ∈ Ici (0 : ℝ) from hx) (show s ∈ Ici (0 : ℝ) from hs.1))).sub
        (hW2.continuousOn.comp (by fun_prop : Continuous fun s : ℝ => (x, s)).continuousOn
          (fun s (hs : s ∈ Icc 0 t) => mk_mem_prod (show x ∈ Ici (0 : ℝ) from hx) (show s ∈ Ici (0 : ℝ) from hs.1))))
      (fun s hs => by
        have := (slice_snd_interior hV2 hx' hs.1).sub (slice_snd_interior hW2 hx' hs.1)
        refine this.congr_deriv ?_
        have := hT x s hx hs.1.le
        simpa [D] using this)
    simp only [hV0 x hx, hW0 x hx, sub_self] at key
    linarith

#print axioms clamped_unique

lemma dAlembert_split (c : ℝ) {F G : ℝ → ℝ} (hG : Continuous G) (x t : ℝ) :
    dAlembert c F G x t = (F (x - c * t) + F (x + c * t)) / 2 + 1 / (2 * c) *
      ((fun y => ∫ s in (0 : ℝ)..y, G s) (x + c * t) -
        (fun y => ∫ s in (0 : ℝ)..y, G s) (x - c * t)) := by
  simp only [dAlembert]
  rw [intervalIntegral.integral_interval_sub_left (hG.intervalIntegrable _ _)
    (hG.intervalIntegrable _ _)]

#print axioms dAlembert_split

lemma primitive_hasDerivAt {G : ℝ → ℝ} (hG : Continuous G) (y : ℝ) :
    HasDerivAt (fun y => ∫ s in (0 : ℝ)..y, G s) (G y) y :=
  (hG.integral_hasStrictDerivAt 0 y).hasDerivAt

#print axioms primitive_hasDerivAt

/-- A clamped end is a mirror placed in the data. On a uniform string with wave speed `c > 0`
and one end held still at `x = 0`, take a starting shape `f` with continuous second rates on
`x ≥ 0` and a starting velocity `g` with continuous first rates there, with the corners
matched at the end: `f(0) = 0`, `g(0) = 0`, `f''(0) = 0`. Then d'Alembert's whole-line formula
run on the odd extensions of `f` and `g` is a classical solution of the half-line problem
`u_tt = c^2 u_xx`, `u(x, 0) = f(x)`, `u_t(x, 0) = g(x)`, `u(0, t) = 0`, and it is the only one:
every classical solution equals it at every `x ≥ 0` and `t ≥ 0`. -/
theorem clamped_half_line_wave_eq_dAlembert_oddExt (c : ℝ) (hc : 0 < c) (f g : ℝ → ℝ)
    (hf : ContDiffOn ℝ 2 f (Ici 0)) (hg : ContDiffOn ℝ 1 g (Ici 0))
    (hf0 : f 0 = 0) (hg0 : g 0 = 0) (hf2 : iteratedDerivWithin 2 f (Ici 0) 0 = 0) :
    IsClampedHalfLineSolution c f g (dAlembert c (oddExt f) (oddExt g)) ∧
    ∀ v : ℝ → ℝ → ℝ, IsClampedHalfLineSolution c f g v →
      ∀ x t, 0 ≤ x → 0 ≤ t → v x t = dAlembert c (oddExt f) (oddExt g) x t := by
  have hc0 : c ≠ 0 := hc.ne'
  obtain ⟨hfd, -⟩ := halfline_data (hf.of_le (by norm_num))
  have hf1 : ContDiffOn ℝ 1 (derivWithin f (Ici 0)) (Ici 0) :=
    hf.derivWithin (uniqueDiffOn_Ici 0) (by norm_num)
  obtain ⟨hf1d, hf2c⟩ := halfline_data hf1
  obtain ⟨hgd, hg1c⟩ := halfline_data hg
  have hf2' : derivWithin (derivWithin f (Ici 0)) (Ici 0) 0 = 0 := by
    rw [iteratedDerivWithin_eq_iterate] at hf2
    simpa using hf2
  have hF : ContDiff ℝ 2 (oddExt f) := contDiff_two_of_hasDerivAt (oddExt_hasDerivAt hfd hf0)
    (evenExt_hasDerivAt hf1d hf2') (oddExt_continuous hf2c hf2')
  have hG : ContDiff ℝ 1 (oddExt g) :=
    contDiff_one_of_hasDerivAt (oddExt_hasDerivAt hgd hg0) (evenExt_continuous hg1c)
  have hGc := hG.continuous
  obtain ⟨h2, hpde, ht, -⟩ := wave_core c hc0 (oddExt f) (oddExt g) _
    (dAlembert c (oddExt f) (oddExt g)) hF hG (primitive_hasDerivAt hGc)
    (dAlembert_split c hGc)
  have hsol : IsClampedHalfLineSolution c f g (dAlembert c (oddExt f) (oddExt g)) := by
    refine ⟨h2.contDiffOn, fun x t _ _ => hpde x t, fun x hx => ?_, fun x hx => ?_,
      fun t ht => ?_⟩
    · simp [dAlembert, oddExt, hx]
    · rw [(ht x 0).hasDerivWithinAt.derivWithin
        (uniqueDiffOn_Ici 0 0 (show (0 : ℝ) ∈ Ici (0 : ℝ) from mem_Ici.mpr le_rfl))]
      have e : oddExt g x = g x := by simp [oddExt, hx]
      simp only [mul_zero, sub_zero, add_zero]
      rw [← e]
      field_simp
      ring
    · simp only [dAlembert, zero_sub, zero_add]
      rw [oddExt_neg hf0]
      have hI : ∫ s in (-(c * t))..(c * t), oddExt g s = 0 := by
        have h1 := intervalIntegral.integral_comp_neg (a := -(c * t)) (b := c * t)
          (f := fun s => oddExt g s)
        simp only [neg_neg, oddExt_neg hg0, intervalIntegral.integral_neg] at h1
        linarith
      rw [hI]
      ring
  exact ⟨hsol, fun v hv x t hx ht => clamped_unique hc hv hsol x t hx ht⟩

/-- A free end takes the upright mirror. On a uniform string with wave speed `c > 0` and a
free end (zero slope) at `x = 0`, take a starting shape `f` with continuous second rates on
`x ≥ 0` and a starting velocity `g` with continuous first rates there, with the corners matched
at the end for the even extension: `f'(0) = 0`, `g'(0) = 0`. Then d'Alembert's formula run on
the even extensions of `f` and `g` is a classical solution of the half-line problem with
`u_x(0, t) = 0`. -/
theorem free_half_line_wave_dAlembert_evenExt (c : ℝ) (hc : 0 < c) (f g : ℝ → ℝ)
    (hf : ContDiffOn ℝ 2 f (Ici 0)) (hg : ContDiffOn ℝ 1 g (Ici 0))
    (hf1 : derivWithin f (Ici 0) 0 = 0) (hg1 : derivWithin g (Ici 0) 0 = 0) :
    IsFreeHalfLineSolution c f g (dAlembert c (evenExt f) (evenExt g)) := by
  have hc0 : c ≠ 0 := hc.ne'
  obtain ⟨hfd, -⟩ := halfline_data (hf.of_le (by norm_num))
  have hf1' : ContDiffOn ℝ 1 (derivWithin f (Ici 0)) (Ici 0) :=
    hf.derivWithin (uniqueDiffOn_Ici 0) (by norm_num)
  obtain ⟨hf1d, hf2c⟩ := halfline_data hf1'
  obtain ⟨hgd, hg1c⟩ := halfline_data hg
  have hF' : ∀ x, HasDerivAt (evenExt f) (oddExt (derivWithin f (Ici 0)) x) x :=
    evenExt_hasDerivAt hfd hf1
  have hF : ContDiff ℝ 2 (evenExt f) := contDiff_two_of_hasDerivAt hF'
    (oddExt_hasDerivAt hf1d hf1) (evenExt_continuous hf2c)
  have hG : ContDiff ℝ 1 (evenExt g) :=
    contDiff_one_of_hasDerivAt (evenExt_hasDerivAt hgd hg1) (oddExt_continuous hg1c hg1)
  have hGc := hG.continuous
  obtain ⟨h2, hpde, ht, hx⟩ := wave_core c hc0 (evenExt f) (evenExt g) _
    (dAlembert c (evenExt f) (evenExt g)) hF hG (primitive_hasDerivAt hGc)
    (dAlembert_split c hGc)
  refine ⟨h2.contDiffOn, fun x t _ _ => hpde x t, fun x hx => ?_, fun x hx => ?_,
    fun t ht => ?_⟩
  · simp [dAlembert, evenExt, abs_of_nonneg hx]
  · rw [(ht x 0).hasDerivWithinAt.derivWithin
      (uniqueDiffOn_Ici 0 0 (show (0 : ℝ) ∈ Ici (0 : ℝ) from mem_Ici.mpr le_rfl))]
    have e : evenExt g x = g x := by simp [evenExt, abs_of_nonneg hx]
    simp only [mul_zero, sub_zero, add_zero]
    rw [← e]
    field_simp
    ring
  · rw [(hx 0 t).hasDerivWithinAt.derivWithin
      (uniqueDiffOn_Ici 0 0 (show (0 : ℝ) ∈ Ici (0 : ℝ) from mem_Ici.mpr le_rfl))]
    have hd : deriv (evenExt f) = oddExt (derivWithin f (Ici 0)) := funext fun x => (hF' x).deriv
    rw [hd]
    simp only [zero_sub, zero_add]
    rw [oddExt_neg hf1]
    simp only [evenExt, abs_neg]
    ring

/-- The echo comes back flipped. Near the clamped end, where `0 ≤ x < ct`, the odd-extension
formula reads in the real data only: the incoming half `f(x + ct) / 2`, the echo
`-f(ct - x) / 2` (half the pulse, upside down, moving away from the end), and the starting
velocity spread over `ct - x` to `x + ct`. -/
theorem dAlembert_oddExt_near_end (c : ℝ) (hc : 0 < c) (f g : ℝ → ℝ)
    (hg : ContinuousOn g (Ici 0)) (x t : ℝ) (hx : 0 ≤ x) (hxt : x < c * t) :
    dAlembert c (oddExt f) (oddExt g) x t =
      (f (x + c * t) - f (c * t - x)) / 2 + 1 / (2 * c) * ∫ s in (c * t - x)..(x + c * t), g s := by
  have hct : 0 < c * t := by linarith
  have h1 : x - c * t < 0 := by linarith
  have h2 : 0 ≤ x + c * t := by linarith
  simp only [dAlembert]
  have eF1 : oddExt f (x - c * t) = -f (c * t - x) := by
    simp [oddExt, not_le.mpr h1, neg_sub]
  have eF2 : oddExt f (x + c * t) = f (x + c * t) := by simp [oddExt, h2]
  rw [eF1, eF2]
  have hgi : ∀ b, 0 ≤ b → IntervalIntegrable g MeasureTheory.volume 0 b := fun b hb =>
    (hg.mono (fun s hs => by rw [uIcc_of_le hb] at hs; exact hs.1)).intervalIntegrable
  have hneg : IntervalIntegrable (oddExt g) MeasureTheory.volume (x - c * t) 0 := by
    have hc' : ContinuousOn (fun s => -g (-s)) (uIcc (x - c * t) 0) :=
      (hg.comp continuous_neg.continuousOn (fun s hs => by
        rw [uIcc_of_le h1.le] at hs
        simp only [mem_Icc] at hs
        simp only [mem_Ici]
        linarith [hs.2])).neg
    exact hc'.intervalIntegrable.congr_uIoo (fun s hs => by
      rw [uIoo_of_le h1.le] at hs
      simp [oddExt, not_le.mpr hs.2])
  have hpos : IntervalIntegrable (oddExt g) MeasureTheory.volume 0 (x + c * t) :=
    (hgi _ h2).congr (fun s hs => by
      rw [uIoc_of_le h2] at hs
      simp [oddExt, hs.1.le])
  rw [← intervalIntegral.integral_add_adjacent_intervals hneg hpos]
  have e1 : ∫ s in (x - c * t)..0, oddExt g s = -∫ s in (0 : ℝ)..(c * t - x), g s := by
    rw [intervalIntegral.integral_congr_uIoo (g := fun s => -g (-s)) (fun s hs => by
      rw [uIoo_of_le h1.le] at hs
      simp [oddExt, not_le.mpr hs.2])]
    rw [intervalIntegral.integral_neg, intervalIntegral.integral_comp_neg]
    simp [neg_sub]
  have e2 : ∫ s in (0 : ℝ)..(x + c * t), oddExt g s = ∫ s in (0 : ℝ)..(x + c * t), g s :=
    intervalIntegral.integral_congr (fun s hs => by
      rw [uIcc_of_le h2] at hs
      simp [oddExt, hs.1])
  have e3 : ∫ s in (c * t - x)..(x + c * t), g s =
      (∫ s in (0 : ℝ)..(x + c * t), g s) - ∫ s in (0 : ℝ)..(c * t - x), g s :=
    (intervalIntegral.integral_interval_sub_left (hgi _ h2) (hgi _ (by linarith))).symm
  rw [e1, e2, e3]
  ring

/-- The card's tent, place in cm and height in mm: centre 10 cm, half-width 2 cm, height 2 mm. -/
noncomputable def tent (x : ℝ) : ℝ := if |x - 10| < 2 then 2 * (1 - |x - 10| / 2) else 0

-- Wave speed: c = 2 × 65 cm × 110 Hz = 14300 cm/s = 143 m/s.
example : (2 : ℝ) * 65 * 110 = 14300 := by norm_num

-- The echo is back at 10 cm after 2 × 10 cm ÷ c, when each half has run ct = 20 cm.
example : (14300 : ℝ) * (2 * 10 / 14300) = 20 := by norm_num

-- Worked numbers, by hand: clamped bridge, released from rest (g = 0). At 1.3986 ms = 20/14300 s
-- the string at 10 cm is (F_o(-10) + F_o(30)) / 2 = (-2 + 0) / 2 = -1 mm, flipped.
example : dAlembert 14300 (oddExt tent) (oddExt fun _ => 0) 10 (2 * 10 / 14300) = -1 := by
  norm_num [dAlembert, oddExt, tent, abs_of_nonneg, abs_of_nonpos]

-- Its upright twin, 20 cm farther on, at 30 cm: 1 mm.
example : dAlembert 14300 (oddExt tent) (oddExt fun _ => 0) 30 (2 * 10 / 14300) = 1 := by
  norm_num [dAlembert, oddExt, tent, abs_of_nonneg, abs_of_nonpos]

-- The bridge stays at 0 when the halves meet it, 10/14300 s = 0.6993 ms.
example : dAlembert 14300 (oddExt tent) (oddExt fun _ => 0) 0 (10 / 14300) = 0 := by
  norm_num [dAlembert, oddExt, tent, abs_of_nonneg, abs_of_nonpos]

-- Free end: the echo at 10 cm returns upright, +1 mm, and the end rises 2 mm at 0.6993 ms.
example : dAlembert 14300 (evenExt tent) (evenExt fun _ => 0) 10 (2 * 10 / 14300) = 1 := by
  norm_num [dAlembert, evenExt, tent, abs_of_nonneg, abs_of_nonpos]

example : dAlembert 14300 (evenExt tent) (evenExt fun _ => 0) 0 (10 / 14300) = 2 := by
  norm_num [dAlembert, evenExt, tent, abs_of_nonneg, abs_of_nonpos]

-- Mistake 3: at x0/c = 0.6993 ms the reading at 10 cm is 0 mm; the echo is not back yet.
example : dAlembert 14300 (oddExt tent) (oddExt fun _ => 0) 10 (10 / 14300) = 0 := by
  norm_num [dAlembert, oddExt, tent, abs_of_nonneg, abs_of_nonpos]

-- The bounce at 1 cm from the bridge: ct = 8.5 cm gives 0.75 mm, ct = 9.5 cm gives 0.5 mm,
-- ct = 11 cm gives -1 mm.
example : dAlembert 14300 (oddExt tent) (oddExt fun _ => 0) 1 (17 / 2 / 14300) = 3 / 4 := by
  norm_num [dAlembert, oddExt, tent, abs_of_nonneg, abs_of_nonpos]

example : dAlembert 14300 (oddExt tent) (oddExt fun _ => 0) 1 (19 / 2 / 14300) = 1 / 2 := by
  norm_num [dAlembert, oddExt, tent, abs_of_nonneg, abs_of_nonpos]

example : dAlembert 14300 (oddExt tent) (oddExt fun _ => 0) 1 (11 / 14300) = -1 := by
  norm_num [dAlembert, oddExt, tent, abs_of_nonneg, abs_of_nonpos]

#print axioms clamped_half_line_wave_eq_dAlembert_oddExt
#print axioms free_half_line_wave_dAlembert_evenExt
#print axioms dAlembert_oddExt_near_end
