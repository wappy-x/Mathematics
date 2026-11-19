-- De Rham cohomology: on the punctured plane every closed 1-form is a multiple of the angle form plus an exact one, with the multiple read by its loop integral over 2π, the angle form itself is closed but not exact, and the same count holds for algebraic forms on the punctured line over any field of characteristic zero.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Algebra.Polynomial.Laurent
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.MeasureTheory.Integral.CurveIntegral.Poincare
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.FDeriv.Pow

open Real LaurentPolynomial

lemma deRham_normSq_ne_zero {p : ℝ × ℝ} (hp : p ≠ 0) : p.1 ^ 2 + p.2 ^ 2 ≠ 0 := by
  intro h
  apply hp
  have h1 : p.1 ^ 2 = 0 := by linarith [sq_nonneg p.1, sq_nonneg p.2]
  have h2 : p.2 ^ 2 = 0 := by linarith [sq_nonneg p.1, sq_nonneg p.2]
  exact Prod.ext (pow_eq_zero_iff two_ne_zero |>.mp h1) (pow_eq_zero_iff two_ne_zero |>.mp h2)

lemma deRham_hasFDerivAt_div {c d : ℝ × ℝ → ℝ} {c' d' : ℝ × ℝ →L[ℝ] ℝ} {x : ℝ × ℝ}
    (hc : HasFDerivAt c c' x) (hd : HasFDerivAt d d' x) (hx : d x ≠ 0) :
    HasFDerivAt (fun y => c y / d y) ((d x)⁻¹ • c' - (c x / d x ^ 2) • d') x := by
  have hi : HasFDerivAt (fun y => (d y)⁻¹)
      ((ContinuousLinearMap.toSpanSingleton ℝ (-(d x ^ 2)⁻¹)).comp d') x :=
    (hasFDerivAt_inv hx).comp x hd
  have := hc.fun_mul hi
  simp only [div_eq_mul_inv]
  convert this using 1
  refine ContinuousLinearMap.ext fun v => ?_
  simp
  field_simp
  ring

lemma deRham_normSq_hasFDerivAt (p : ℝ × ℝ) :
    HasFDerivAt (fun q : ℝ × ℝ => q.1 ^ 2 + q.2 ^ 2)
      ((2 * p.1) • ContinuousLinearMap.fst ℝ ℝ ℝ + (2 * p.2) • ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
  have := ((hasFDerivAt_fst (𝕜 := ℝ) (p := p)).pow 2).add ((hasFDerivAt_snd (𝕜 := ℝ) (p := p)).pow 2)
  convert this using 1
  refine ContinuousLinearMap.ext fun v => ?_
  simp

lemma deRham_angle_cross (p : ℝ × ℝ) (hp : p ≠ 0) :
    fderiv ℝ (fun q : ℝ × ℝ => q.1 / (q.1 ^ 2 + q.2 ^ 2)) p (1, 0)
      = fderiv ℝ (fun q : ℝ × ℝ => -q.2 / (q.1 ^ 2 + q.2 ^ 2)) p (0, 1) := by
  have hr := deRham_normSq_ne_zero hp
  have hn : HasFDerivAt (fun q : ℝ × ℝ => -q.2) (-ContinuousLinearMap.snd ℝ ℝ ℝ) p :=
    hasFDerivAt_snd.neg
  rw [(deRham_hasFDerivAt_div hasFDerivAt_fst (deRham_normSq_hasFDerivAt p) hr).fderiv,
    (deRham_hasFDerivAt_div hn (deRham_normSq_hasFDerivAt p) hr).fderiv]
  simp
  field_simp
  ring


lemma deRham_pt_ne (t : ℝ) : ((cos t, sin t) : ℝ × ℝ) ≠ 0 := by
  intro h
  have h1 : cos t = 0 := congrArg Prod.fst h
  have h2 : sin t = 0 := congrArg Prod.snd h
  have := sin_sq_add_cos_sq t
  rw [h1, h2] at this
  norm_num at this

lemma deRham_circle_hasDerivAt {f : ℝ × ℝ → ℝ} {L : ℝ × ℝ →L[ℝ] ℝ} {t : ℝ}
    (hf : HasFDerivAt f L (cos t, sin t)) :
    HasDerivAt (fun t => f (cos t, sin t)) (L (-sin t, cos t)) t :=
  hf.comp_hasDerivAt t ((hasDerivAt_cos t).prodMk (hasDerivAt_sin t))

lemma deRham_arc {ω : ℝ × ℝ → (ℝ × ℝ →L[ℝ] ℝ)} {f : ℝ × ℝ → ℝ} {s : Set (ℝ × ℝ)}
    (hf : ∀ a ∈ s, HasFDerivAt f (ω a) a)
    (hcont : Continuous fun t : ℝ => ω (cos t, sin t) (-sin t, cos t))
    {a b : ℝ} (hab : a ≤ b) (harc : ∀ t ∈ Set.Icc a b, (cos t, sin t) ∈ s) :
    ∫ t in a..b, ω (cos t, sin t) (-sin t, cos t) = f (cos b, sin b) - f (cos a, sin a) :=
  intervalIntegral.integral_eq_sub_of_hasDerivAt
    (fun t ht => deRham_circle_hasDerivAt (hf _ (harc t (by rwa [Set.uIcc_of_le hab] at ht))))
    (hcont.intervalIntegrable a b)

lemma deRham_sub_const {ω : ℝ × ℝ → (ℝ × ℝ →L[ℝ] ℝ)} {f g : ℝ × ℝ → ℝ} {s : Set (ℝ × ℝ)}
    (hs : Convex ℝ s) (hso : IsOpen s)
    (hf : ∀ a ∈ s, HasFDerivAt f (ω a) a) (hg : ∀ a ∈ s, HasFDerivAt g (ω a) a)
    {x y : ℝ × ℝ} (hx : x ∈ s) (hy : y ∈ s) : g x - f x = g y - f y :=
  hso.is_const_of_fderiv_eq_zero (f := fun p => g p - f p) hs.isPreconnected
    (fun a ha => ((hg a ha).fun_sub (hf a ha)).differentiableAt.differentiableWithinAt)
    (fun a ha => by rw [((hg a ha).fun_sub (hf a ha)).fderiv, sub_self]; rfl) hx hy

lemma deRham_glue {ω : ℝ × ℝ → (ℝ × ℝ →L[ℝ] ℝ)}
    (hω : DifferentiableOn ℝ ω {p | p ≠ 0})
    (hsym : ∀ a ∈ {p : ℝ × ℝ | p ≠ 0}, ∀ x y, fderiv ℝ ω a x y = fderiv ℝ ω a y x)
    (hloop : ∫ t in (0 : ℝ)..2 * π, ω (cos t, sin t) (-sin t, cos t) = 0) :
    ∃ F : ℝ × ℝ → ℝ, ∀ p : ℝ × ℝ, p ≠ 0 → HasFDerivAt F (ω p) p := by
  have prim : ∀ s : Set (ℝ × ℝ), Convex ℝ s → IsOpen s → (∀ p ∈ s, p ≠ 0) →
      ∃ f : ℝ × ℝ → ℝ, ∀ a ∈ s, HasFDerivAt f (ω a) a := fun s hs hso hsub =>
    hs.exists_forall_hasFDerivAt_of_fderiv_symmetric hso (hω.mono fun p hp => hsub p hp)
      (fun a ha => hsym a (hsub a ha))
  have hcont : Continuous fun t : ℝ => ω (cos t, sin t) (-sin t, cos t) :=
    (hω.continuousOn.comp_continuous (by fun_prop) (fun t => deRham_pt_ne t)).clm_apply
      (by fun_prop)
  -- the four open half-planes
  set R : Set (ℝ × ℝ) := Set.Ioi 0 ×ˢ Set.univ with hR
  set U : Set (ℝ × ℝ) := Set.univ ×ˢ Set.Ioi 0 with hU
  set L : Set (ℝ × ℝ) := Set.Iio 0 ×ˢ Set.univ with hL
  set D : Set (ℝ × ℝ) := Set.univ ×ˢ Set.Iio 0 with hD
  have mR : ∀ x : ℝ × ℝ, x ∈ R ↔ 0 < x.1 := fun x => by simp [hR]
  have mU : ∀ x : ℝ × ℝ, x ∈ U ↔ 0 < x.2 := fun x => by simp [hU]
  have mL : ∀ x : ℝ × ℝ, x ∈ L ↔ x.1 < 0 := fun x => by simp [hL]
  have mD : ∀ x : ℝ × ℝ, x ∈ D ↔ x.2 < 0 := fun x => by simp [hD]
  have oR : IsOpen R := isOpen_Ioi.prod isOpen_univ
  have oU : IsOpen U := isOpen_univ.prod isOpen_Ioi
  have oL : IsOpen L := isOpen_Iio.prod isOpen_univ
  have oD : IsOpen D := isOpen_univ.prod isOpen_Iio
  have ne : ∀ x : ℝ × ℝ, (0 < x.1 ∨ 0 < x.2 ∨ x.1 < 0 ∨ x.2 < 0) → x ≠ 0 := by
    rintro x hx rfl
    simp at hx
  obtain ⟨fR, hfR⟩ := prim R ((convex_Ioi 0).prod convex_univ) oR
    (fun x hx => ne x (Or.inl ((mR x).1 hx)))
  obtain ⟨fU, hfU⟩ := prim U (convex_univ.prod (convex_Ioi 0)) oU
    (fun x hx => ne x (Or.inr (Or.inl ((mU x).1 hx))))
  obtain ⟨fL, hfL⟩ := prim L ((convex_Iio 0).prod convex_univ) oL
    (fun x hx => ne x (Or.inr (Or.inr (Or.inl ((mL x).1 hx)))))
  obtain ⟨fD, hfD⟩ := prim D (convex_univ.prod (convex_Iio 0)) oD
    (fun x hx => ne x (Or.inr (Or.inr (Or.inr ((mD x).1 hx)))))
  -- the four open quadrants
  have cQ : ∀ (I J : Set ℝ), Convex ℝ I → Convex ℝ J → Convex ℝ (I ×ˢ J) :=
    fun I J hI hJ => hI.prod hJ
  set Q1 : Set (ℝ × ℝ) := Set.Ioi 0 ×ˢ Set.Ioi 0 with hQ1
  set Q2 : Set (ℝ × ℝ) := Set.Iio 0 ×ˢ Set.Ioi 0 with hQ2
  set Q3 : Set (ℝ × ℝ) := Set.Iio 0 ×ˢ Set.Iio 0 with hQ3
  set Q4 : Set (ℝ × ℝ) := Set.Ioi 0 ×ˢ Set.Iio 0 with hQ4
  have m1 : ∀ x : ℝ × ℝ, x ∈ Q1 ↔ 0 < x.1 ∧ 0 < x.2 := fun x => by simp [hQ1]
  have m2 : ∀ x : ℝ × ℝ, x ∈ Q2 ↔ x.1 < 0 ∧ 0 < x.2 := fun x => by simp [hQ2]
  have m3 : ∀ x : ℝ × ℝ, x ∈ Q3 ↔ x.1 < 0 ∧ x.2 < 0 := fun x => by simp [hQ3]
  have m4 : ∀ x : ℝ × ℝ, x ∈ Q4 ↔ 0 < x.1 ∧ x.2 < 0 := fun x => by simp [hQ4]
  have c1 : Convex ℝ Q1 := (convex_Ioi 0).prod (convex_Ioi 0)
  have c2 : Convex ℝ Q2 := (convex_Iio 0).prod (convex_Ioi 0)
  have c3 : Convex ℝ Q3 := (convex_Iio 0).prod (convex_Iio 0)
  have c4 : Convex ℝ Q4 := (convex_Ioi 0).prod (convex_Iio 0)
  have o1 : IsOpen Q1 := isOpen_Ioi.prod isOpen_Ioi
  have o2 : IsOpen Q2 := isOpen_Iio.prod isOpen_Ioi
  have o3 : IsOpen Q3 := isOpen_Iio.prod isOpen_Iio
  have o4 : IsOpen Q4 := isOpen_Ioi.prod isOpen_Iio
  -- signs of cos and sin on the five arcs
  have pi0 := pi_pos
  have s1 : ∀ t ∈ Set.Icc (0 : ℝ) (π / 4), 0 < cos t := fun t ht =>
    cos_pos_of_mem_Ioo ⟨by linarith [ht.1], by linarith [ht.2]⟩
  have s2 : ∀ t ∈ Set.Icc (π / 4) (3 * π / 4), 0 < sin t := fun t ht =>
    sin_pos_of_pos_of_lt_pi (by linarith [ht.1]) (by linarith [ht.2])
  have s3 : ∀ t ∈ Set.Icc (3 * π / 4) (5 * π / 4), cos t < 0 := fun t ht =>
    cos_neg_of_pi_div_two_lt_of_lt (by linarith [ht.1]) (by linarith [ht.2])
  have s4 : ∀ t ∈ Set.Icc (5 * π / 4) (7 * π / 4), sin t < 0 := fun t ht => by
    have := sin_pos_of_pos_of_lt_pi (x := t - π) (by linarith [ht.1]) (by linarith [ht.2])
    rw [sin_sub_pi] at this
    linarith
  have s5 : ∀ t ∈ Set.Icc (7 * π / 4) (2 * π), 0 < cos t := fun t ht => by
    rw [← cos_sub_two_pi]
    exact cos_pos_of_mem_Ioo ⟨by linarith [ht.1], by linarith [ht.2]⟩
  have l1 : (0 : ℝ) ≤ π / 4 := by linarith
  have l2 : π / 4 ≤ 3 * π / 4 := by linarith
  have l3 : 3 * π / 4 ≤ 5 * π / 4 := by linarith
  have l4 : 5 * π / 4 ≤ 7 * π / 4 := by linarith
  have l5 : 7 * π / 4 ≤ 2 * π := by linarith
  -- the corner points
  set a : ℝ × ℝ := (cos (π / 4), sin (π / 4)) with ha
  set b : ℝ × ℝ := (cos (3 * π / 4), sin (3 * π / 4)) with hb
  set c : ℝ × ℝ := (cos (5 * π / 4), sin (5 * π / 4)) with hc
  set d : ℝ × ℝ := (cos (7 * π / 4), sin (7 * π / 4)) with hd
  have ha1 : a ∈ Q1 := (m1 a).2 ⟨s1 _ ⟨l1, le_rfl⟩, s2 _ ⟨le_rfl, l2⟩⟩
  have hb2 : b ∈ Q2 := (m2 b).2 ⟨s3 _ ⟨le_rfl, l3⟩, s2 _ ⟨l2, le_rfl⟩⟩
  have hc3 : c ∈ Q3 := (m3 c).2 ⟨s3 _ ⟨l3, le_rfl⟩, s4 _ ⟨le_rfl, l4⟩⟩
  have hd4 : d ∈ Q4 := (m4 d).2 ⟨s5 _ ⟨le_rfl, l5⟩, s4 _ ⟨l4, le_rfl⟩⟩
  -- the loop integral, arc by arc
  have hi : ∀ x y : ℝ, IntervalIntegrable (fun t : ℝ => ω (cos t, sin t) (-sin t, cos t))
      MeasureTheory.volume x y := fun x y => hcont.intervalIntegrable x y
  have A1 := deRham_arc hfR hcont l1 (fun t ht => (mR _).2 (s1 t ht))
  have A2 := deRham_arc hfU hcont l2 (fun t ht => (mU _).2 (s2 t ht))
  have A3 := deRham_arc hfL hcont l3 (fun t ht => (mL _).2 (s3 t ht))
  have A4 := deRham_arc hfD hcont l4 (fun t ht => (mD _).2 (s4 t ht))
  have A5 := deRham_arc hfR hcont l5 (fun t ht => (mR _).2 (s5 t ht))
  rw [← intervalIntegral.integral_add_adjacent_intervals (hi 0 (π / 4)) (hi _ _),
    ← intervalIntegral.integral_add_adjacent_intervals (hi (π / 4) (3 * π / 4)) (hi _ _),
    ← intervalIntegral.integral_add_adjacent_intervals (hi (3 * π / 4) (5 * π / 4)) (hi _ _),
    ← intervalIntegral.integral_add_adjacent_intervals (hi (5 * π / 4) (7 * π / 4)) (hi _ _),
    A1, A2, A3, A4, A5] at hloop
  simp only [cos_two_pi, sin_two_pi, cos_zero, sin_zero] at hloop
  -- matching constants on the quadrants
  obtain ⟨k1, hk1⟩ : ∃ k : ℝ, k = fU a - fR a := ⟨_, rfl⟩
  obtain ⟨k2, hk2⟩ : ∃ k : ℝ, k = fL b - (fU b - k1) := ⟨_, rfl⟩
  obtain ⟨k3, hk3⟩ : ∃ k : ℝ, k = fD c - (fL c - k2) := ⟨_, rfl⟩
  have e1 : ∀ x ∈ Q1, fU x - k1 = fR x := fun x hx => by
    have := deRham_sub_const c1 o1 (fun y hy => hfR y ((mR y).2 ((m1 y).1 hy).1))
      (fun y hy => hfU y ((mU y).2 ((m1 y).1 hy).2)) hx ha1
    linarith
  have e2 : ∀ x ∈ Q2, fL x - k2 = fU x - k1 := fun x hx => by
    have := deRham_sub_const c2 o2 (fun y hy => hfU y ((mU y).2 ((m2 y).1 hy).2))
      (fun y hy => hfL y ((mL y).2 ((m2 y).1 hy).1)) hx hb2
    linarith
  have e3 : ∀ x ∈ Q3, fD x - k3 = fL x - k2 := fun x hx => by
    have := deRham_sub_const c3 o3 (fun y hy => hfL y ((mL y).2 ((m3 y).1 hy).1))
      (fun y hy => hfD y ((mD y).2 ((m3 y).1 hy).2)) hx hc3
    linarith
  have e4 : ∀ x ∈ Q4, fD x - k3 = fR x := fun x hx => by
    have := deRham_sub_const c4 o4 (fun y hy => hfR y ((mR y).2 ((m4 y).1 hy).1))
      (fun y hy => hfD y ((mD y).2 ((m4 y).1 hy).2)) hx hd4
    linarith
  -- the glued primitive
  refine ⟨fun x => if 0 < x.1 then fR x else if 0 < x.2 then fU x - k1
    else if x.1 < 0 then fL x - k2 else fD x - k3, ?_⟩
  have FR : ∀ x ∈ R, (if 0 < x.1 then fR x else if 0 < x.2 then fU x - k1
      else if x.1 < 0 then fL x - k2 else fD x - k3) = fR x := fun x hx => by
    simp only [(mR x).1 hx, ↓reduceIte]
  have FU : ∀ x ∈ U, (if 0 < x.1 then fR x else if 0 < x.2 then fU x - k1
      else if x.1 < 0 then fL x - k2 else fD x - k3) = fU x - k1 := fun x hx => by
    have h2 := (mU x).1 hx
    split_ifs with h1
    · exact (e1 x ((m1 x).2 ⟨h1, h2⟩)).symm
    · rfl
  have FL : ∀ x ∈ L, (if 0 < x.1 then fR x else if 0 < x.2 then fU x - k1
      else if x.1 < 0 then fL x - k2 else fD x - k3) = fL x - k2 := fun x hx => by
    have h1 := (mL x).1 hx
    split_ifs with h1' h2
    · linarith
    · exact (e2 x ((m2 x).2 ⟨h1, h2⟩)).symm
    · rfl
  have FD : ∀ x ∈ D, (if 0 < x.1 then fR x else if 0 < x.2 then fU x - k1
      else if x.1 < 0 then fL x - k2 else fD x - k3) = fD x - k3 := fun x hx => by
    have h2 := (mD x).1 hx
    split_ifs with h1 h2' h3
    · exact (e4 x ((m4 x).2 ⟨h1, h2⟩)).symm
    · linarith
    · exact (e3 x ((m3 x).2 ⟨h3, h2⟩)).symm
    · rfl
  intro p hp
  rcases lt_trichotomy p.1 0 with h1 | h1 | h1
  · have hpL : p ∈ L := (mL p).2 h1
    exact ((hfL p hpL).sub_const k2).congr_of_eventuallyEq
      (Filter.eventually_of_mem (oL.mem_nhds hpL) FL)
  · rcases lt_trichotomy p.2 0 with h2 | h2 | h2
    · have hpD : p ∈ D := (mD p).2 h2
      exact ((hfD p hpD).sub_const k3).congr_of_eventuallyEq
        (Filter.eventually_of_mem (oD.mem_nhds hpD) FD)
    · exact absurd (Prod.ext h1 h2) hp
    · have hpU : p ∈ U := (mU p).2 h2
      exact ((hfU p hpU).sub_const k1).congr_of_eventuallyEq
        (Filter.eventually_of_mem (oU.mem_nhds hpU) FU)
  · have hpR : p ∈ R := (mR p).2 h1
    exact (hfR p hpR).congr_of_eventuallyEq (Filter.eventually_of_mem (oR.mem_nhds hpR) FR)

lemma deRham_clm_decomp (L : ℝ × ℝ →L[ℝ] ℝ) (v : ℝ × ℝ) :
    L v = v.1 * L (1, 0) + v.2 * L (0, 1) := by
  conv_lhs => rw [show v = v.1 • ((1 : ℝ), (0 : ℝ)) + v.2 • ((0 : ℝ), (1 : ℝ)) by ext <;> simp]
  rw [map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul]

lemma deRham_form_hasFDerivAt {A B : ℝ × ℝ → ℝ} {a : ℝ × ℝ} (hA : DifferentiableAt ℝ A a)
    (hB : DifferentiableAt ℝ B a) :
    HasFDerivAt
      (fun p => A p • ContinuousLinearMap.fst ℝ ℝ ℝ + B p • ContinuousLinearMap.snd ℝ ℝ ℝ)
      ((fderiv ℝ A a).smulRight (ContinuousLinearMap.fst ℝ ℝ ℝ)
        + (fderiv ℝ B a).smulRight (ContinuousLinearMap.snd ℝ ℝ ℝ)) a :=
  (hA.hasFDerivAt.smul_const (ContinuousLinearMap.fst ℝ ℝ ℝ)).add
    (hB.hasFDerivAt.smul_const (ContinuousLinearMap.snd ℝ ℝ ℝ))

lemma deRham_sym {A B : ℝ × ℝ → ℝ} {a : ℝ × ℝ} (hA : DifferentiableAt ℝ A a)
    (hB : DifferentiableAt ℝ B a) (hcross : fderiv ℝ B a (1, 0) = fderiv ℝ A a (0, 1))
    (x y : ℝ × ℝ) :
    fderiv ℝ (fun p => A p • ContinuousLinearMap.fst ℝ ℝ ℝ + B p • ContinuousLinearMap.snd ℝ ℝ ℝ)
        a x y
      = fderiv ℝ
          (fun p => A p • ContinuousLinearMap.fst ℝ ℝ ℝ + B p • ContinuousLinearMap.snd ℝ ℝ ℝ)
          a y x := by
  rw [(deRham_form_hasFDerivAt hA hB).fderiv]
  simp only [add_apply, ContinuousLinearMap.smulRight_apply,
    smul_apply, ContinuousLinearMap.coe_fst', ContinuousLinearMap.coe_snd',
    smul_eq_mul]
  rw [deRham_clm_decomp (fderiv ℝ A a) x, deRham_clm_decomp (fderiv ℝ A a) y,
    deRham_clm_decomp (fderiv ℝ B a) x, deRham_clm_decomp (fderiv ℝ B a) y, hcross]
  ring


/-- **Every closed 1-form on the punctured plane is c ω plus an exact form.** Let
α = P dx + Q dy be a 1-form on the punctured plane ℝ² ∖ {0} whose parts P and Q have continuous
partial derivatives there, and suppose α is closed: its curl ∂Q/∂x − ∂P/∂y is zero at every point
other than the origin. Let c be the integral of α once round the unit circle
(x = cos t, y = sin t, t from 0 to 2π), divided by 2π. Then α − c ω is exact, where
ω = (−y dx + x dy)/(x² + y²) is the angle form: some function F on the punctured plane has
dF = α − c ω, that is ∂F/∂x = P − c(−y/r²) and ∂F/∂y = Q − c(x/r²) at every point other than
the origin. So H¹_dR of the punctured plane is spanned by [ω], and a class is read by its loop
integral divided by 2π. -/
theorem closed_one_form_eq_angle_multiple_add_exact
    {P Q : ℝ × ℝ → ℝ} (hP : ContDiffOn ℝ 1 P {p | p ≠ 0}) (hQ : ContDiffOn ℝ 1 Q {p | p ≠ 0})
    (hclosed : ∀ p : ℝ × ℝ, p ≠ 0 → fderiv ℝ Q p (1, 0) = fderiv ℝ P p (0, 1))
    (c : ℝ)
    (hc : c = (1 / (2 * π)) *
      ∫ t in (0 : ℝ)..2 * π, (P (cos t, sin t) * (-sin t) + Q (cos t, sin t) * cos t)) :
    ∃ F : ℝ × ℝ → ℝ, ∀ p : ℝ × ℝ, p ≠ 0 →
      HasFDerivAt F
        ((P p - c * (-p.2 / (p.1 ^ 2 + p.2 ^ 2))) • ContinuousLinearMap.fst ℝ ℝ ℝ
          + (Q p - c * (p.1 / (p.1 ^ 2 + p.2 ^ 2))) • ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
  have hS : IsOpen {p : ℝ × ℝ | p ≠ 0} := isOpen_ne
  have hPd : DifferentiableOn ℝ P {p | p ≠ 0} := hP.differentiableOn one_ne_zero
  have hQd : DifferentiableOn ℝ Q {p | p ≠ 0} := hQ.differentiableOn one_ne_zero
  have hPa : ∀ p : ℝ × ℝ, p ≠ 0 → DifferentiableAt ℝ P p := fun p hp =>
    (hPd p hp).differentiableAt (hS.mem_nhds hp)
  have hQa : ∀ p : ℝ × ℝ, p ≠ 0 → DifferentiableAt ℝ Q p := fun p hp =>
    (hQd p hp).differentiableAt (hS.mem_nhds hp)
  have hBd : ∀ p : ℝ × ℝ, p ≠ 0 →
      DifferentiableAt ℝ (fun q : ℝ × ℝ => q.1 / (q.1 ^ 2 + q.2 ^ 2)) p := fun p hp =>
    (deRham_hasFDerivAt_div hasFDerivAt_fst (deRham_normSq_hasFDerivAt p)
      (deRham_normSq_ne_zero hp)).differentiableAt
  have hAd : ∀ p : ℝ × ℝ, p ≠ 0 →
      DifferentiableAt ℝ (fun q : ℝ × ℝ => -q.2 / (q.1 ^ 2 + q.2 ^ 2)) p := fun p hp =>
    (deRham_hasFDerivAt_div
      (hasFDerivAt_snd.neg : HasFDerivAt (fun q : ℝ × ℝ => -q.2) _ p)
      (deRham_normSq_hasFDerivAt p) (deRham_normSq_ne_zero hp)).differentiableAt
  have hA : ∀ p : ℝ × ℝ, p ≠ 0 →
      DifferentiableAt ℝ (fun q : ℝ × ℝ => P q - c * (-q.2 / (q.1 ^ 2 + q.2 ^ 2))) p :=
    fun p hp => (hPa p hp).fun_sub ((hAd p hp).const_mul c)
  have hB : ∀ p : ℝ × ℝ, p ≠ 0 →
      DifferentiableAt ℝ (fun q : ℝ × ℝ => Q q - c * (q.1 / (q.1 ^ 2 + q.2 ^ 2))) p :=
    fun p hp => (hQa p hp).fun_sub ((hBd p hp).const_mul c)
  have hcross : ∀ p : ℝ × ℝ, p ≠ 0 →
      fderiv ℝ (fun q : ℝ × ℝ => Q q - c * (q.1 / (q.1 ^ 2 + q.2 ^ 2))) p (1, 0)
        = fderiv ℝ (fun q : ℝ × ℝ => P q - c * (-q.2 / (q.1 ^ 2 + q.2 ^ 2))) p (0, 1) :=
    fun p hp => by
      rw [((hQa p hp).hasFDerivAt.fun_sub ((hBd p hp).hasFDerivAt.const_mul c)).fderiv,
        ((hPa p hp).hasFDerivAt.fun_sub ((hAd p hp).hasFDerivAt.const_mul c)).fderiv]
      simp only [sub_apply, smul_apply, smul_eq_mul]
      rw [hclosed p hp, deRham_angle_cross p hp]
  refine deRham_glue (ω := fun p => (P p - c * (-p.2 / (p.1 ^ 2 + p.2 ^ 2)))
      • ContinuousLinearMap.fst ℝ ℝ ℝ
      + (Q p - c * (p.1 / (p.1 ^ 2 + p.2 ^ 2))) • ContinuousLinearMap.snd ℝ ℝ ℝ) ?_ ?_ ?_
  · intro p hp
    exact (deRham_form_hasFDerivAt (hA p hp) (hB p hp)).differentiableAt.differentiableWithinAt
  · intro p hp x y
    exact deRham_sym (hA p hp) (hB p hp) (hcross p hp) x y
  · have hg : Continuous fun t : ℝ => P (cos t, sin t) * (-sin t) + Q (cos t, sin t) * cos t := by
      have h1 : Continuous fun t : ℝ => P (cos t, sin t) :=
        hP.continuousOn.comp_continuous (by fun_prop) (fun t => deRham_pt_ne t)
      have h2 : Continuous fun t : ℝ => Q (cos t, sin t) :=
        hQ.continuousOn.comp_continuous (by fun_prop) (fun t => deRham_pt_ne t)
      exact (h1.mul continuous_sin.neg).add (h2.mul continuous_cos)
    rw [intervalIntegral.integral_congr (g := fun t : ℝ =>
        (P (cos t, sin t) * (-sin t) + Q (cos t, sin t) * cos t) - c) (fun t _ => by
      simp only [add_apply, smul_apply,
        ContinuousLinearMap.coe_fst', ContinuousLinearMap.coe_snd', smul_eq_mul,
        cos_sq_add_sin_sq, div_one]
      linear_combination (-c) * sin_sq_add_cos_sq t)]
    rw [intervalIntegral.integral_sub (hg.intervalIntegrable _ _) intervalIntegrable_const,
      intervalIntegral.integral_const, smul_eq_mul]
    have hpi : (2 * π) ≠ 0 := by positivity
    rw [hc]
    field_simp
    ring

/-- **The angle form is closed but not exact.** The angle form ω = (−y dx + x dy)/(x² + y²) on
the punctured plane has zero curl at every point other than the origin (its two cross rates
∂Q/∂x and ∂P/∂y agree); its integral once round the unit circle is 2π; and no function F on the
punctured plane has dF = ω. So [ω] ≠ 0, and H¹_dR of the punctured plane is exactly
one-dimensional. -/
theorem angle_form_closed_not_exact :
    (∀ p : ℝ × ℝ, p ≠ 0 →
      fderiv ℝ (fun q : ℝ × ℝ => q.1 / (q.1 ^ 2 + q.2 ^ 2)) p (1, 0)
        = fderiv ℝ (fun q : ℝ × ℝ => -q.2 / (q.1 ^ 2 + q.2 ^ 2)) p (0, 1)) ∧
    (∫ t in (0 : ℝ)..2 * π,
        ((-sin t) / (cos t ^ 2 + sin t ^ 2) * (-sin t)
          + cos t / (cos t ^ 2 + sin t ^ 2) * cos t)) = 2 * π ∧
    ¬ ∃ F : ℝ × ℝ → ℝ, ∀ p : ℝ × ℝ, p ≠ 0 →
      HasFDerivAt F
        ((-p.2 / (p.1 ^ 2 + p.2 ^ 2)) • ContinuousLinearMap.fst ℝ ℝ ℝ
          + (p.1 / (p.1 ^ 2 + p.2 ^ 2)) • ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
  have h1 : ∀ t : ℝ, (-sin t) / (cos t ^ 2 + sin t ^ 2) * (-sin t)
      + cos t / (cos t ^ 2 + sin t ^ 2) * cos t = 1 := fun t => by
    rw [cos_sq_add_sin_sq]
    linear_combination sin_sq_add_cos_sq t
  refine ⟨deRham_angle_cross, ?_, ?_⟩
  · simp only [h1, intervalIntegral.integral_const, smul_eq_mul, mul_one, sub_zero]
  · rintro ⟨F, hF⟩
    have hd : ∀ t ∈ Set.uIcc 0 (2 * π), HasDerivAt (fun t => F (cos t, sin t)) 1 t := by
      intro t _
      have := deRham_circle_hasDerivAt (hF _ (deRham_pt_ne t))
      convert this using 1
      simp only [add_apply, smul_apply,
        ContinuousLinearMap.coe_fst', ContinuousLinearMap.coe_snd', smul_eq_mul]
      rw [h1]
    have := intervalIntegral.integral_eq_sub_of_hasDerivAt hd intervalIntegrable_const
    simp only [intervalIntegral.integral_const, smul_eq_mul, mul_one, sub_zero, cos_two_pi,
      sin_two_pi, cos_zero, sin_zero, sub_self] at this
    linarith [pi_pos]

/-- **The same count by algebra, on the variety ℂ^× (any field of characteristic zero).** The
algebraic forms on the punctured line over a field K of characteristic zero are built from
Laurent polynomials K[z, z⁻¹]: a 0-form is a Laurent polynomial F, a 1-form is h(z) dz, and
d(z^n) = n z^(n−1) dz, so the coefficient of z^m in dF is (m + 1) times the coefficient of
z^(m+1) in F. Then: (H⁰) a Laurent polynomial with dF = 0 is a constant; (H¹) every 1-form
h(z) dz equals dF + c dz/z for some F, where c is the coefficient of z⁻¹ in h, the residue; and
dz/z itself is not dF for any F. So H⁰ is K and H¹ is K · [dz/z]. -/
theorem laurent_de_rham_H0_H1 {K : Type*} [Field K] [CharZero K] :
    (∀ F : K[T;T⁻¹], (∀ m : ℤ, ((m + 1 : ℤ) : K) * F.coeff (m + 1) = 0) →
      F = C (F.coeff 0)) ∧
    (∀ h : K[T;T⁻¹], ∃ F : K[T;T⁻¹], ∀ m : ℤ,
      h.coeff m = ((m + 1 : ℤ) : K) * F.coeff (m + 1) + (if m = -1 then h.coeff (-1) else 0)) ∧
    ¬ ∃ F : K[T;T⁻¹], ∀ m : ℤ,
      (T (-1) : K[T;T⁻¹]).coeff m = ((m + 1 : ℤ) : K) * F.coeff (m + 1) := by
  refine ⟨?_, ?_, ?_⟩
  · intro F hF
    ext n
    rw [C_apply]
    split_ifs with hn
    · rw [hn]
    · have := hF (n - 1)
      simp only [sub_add_cancel] at this
      rcases mul_eq_zero.mp this with h | h
      · exact absurd (by exact_mod_cast h) hn
      · exact h
  · intro h
    refine ⟨AddMonoidAlgebra.ofCoeff (Finsupp.onFinset (h.coeff.support.image (· + 1))
        (fun n => if n = 0 then 0 else h.coeff (n - 1) / (n : K)) ?_), ?_⟩
    · intro n hn
      simp only [Finset.mem_image, Finsupp.mem_support_iff]
      refine ⟨n - 1, ?_, by ring⟩
      intro h0
      apply hn
      simp [h0]
    · intro m
      rw [AddMonoidAlgebra.coeff_ofCoeff, Finsupp.onFinset_apply]
      by_cases hm : m = -1
      · subst hm
        simp
      · have hm' : m + 1 ≠ 0 := by omega
        have hK : ((m + 1 : ℤ) : K) ≠ 0 := by exact_mod_cast hm'
        simp only [hm, hm', ↓reduceIte, add_sub_cancel_right, add_zero]
        field_simp
  · rintro ⟨F, hF⟩
    have := hF (-1)
    simp at this

-- The angle form's cross rate at (1, 2): (2^2 − 1^2)/(1^2 + 2^2)^2 = 3/25 = 0.12.
example : ((2 : ℚ) ^ 2 - 1 ^ 2) / (1 ^ 2 + 2 ^ 2) ^ 2 = 3 / 25 := by norm_num
-- d(z^3 − 2z − 2z^−2) = (3z^2 − 2 + 4z^−3) dz: the coefficients n · a_n are 3 · 1, 1 · (−2), (−2) · (−2).
example : (3 : ℤ) * 1 = 3 ∧ (1 : ℤ) * (-2) = -2 ∧ (-2 : ℤ) * (-2) = 4 := by norm_num
-- The wire: μ0 I/2π = 4π × 10^−7 × 10/(2π) = 2 × 10^−6 tesla metres, 2 microtesla metres.
example : 4 * π * (1 / 10 ^ 7) * 10 / (2 * π) = 2 / 10 ^ 6 := by
  field_simp [Real.pi_ne_zero]
  norm_num
-- Over F_5, d(z^5) = 5 z^4 dz = 0, since 5 = 0 in F_5.
example : (5 : ZMod 5) = 0 := by decide
-- Over F_5, degrees −6 to 6: the closed 0-forms are z^n with 5 dividing n, here n = −5, 0, 5 (dim H^0 = 3).
example : (Finset.Icc (-6 : ℤ) 6).filter (fun n => n % 5 = 0) = {-5, 0, 5} := by decide
-- Over F_5, the forms z^m dz (m from −7 to 5) not hit are those with 5 dividing m + 1: m = −6, −1, 4.
example : (Finset.Icc (-7 : ℤ) 5).filter (fun m => (m + 1) % 5 = 0) = {-6, -1, 4} := by decide
-- Euler counts: the 3 × 3 torus grid 9 − 27 + 18 = 0, so dim H^1 = 2 − 0 = 2.
example : (9 : ℤ) - 27 + 18 = 0 ∧ (2 : ℤ) - (9 - 27 + 18) = 2 := by norm_num
-- The smooth quartic surface: 4^3 − 4 · 4^2 + 6 · 4 = 24, so dim H^2 = 24 − 2 = 22.
example : (4 : ℤ) ^ 3 - 4 * 4 ^ 2 + 6 * 4 = 24 ∧ (24 : ℤ) - 2 = 22 := by norm_num

#print axioms deRham_normSq_ne_zero
#print axioms deRham_hasFDerivAt_div
#print axioms deRham_normSq_hasFDerivAt
#print axioms deRham_angle_cross
#print axioms deRham_pt_ne
#print axioms deRham_circle_hasDerivAt
#print axioms deRham_arc
#print axioms deRham_sub_const
#print axioms deRham_glue
#print axioms deRham_clm_decomp
#print axioms deRham_form_hasFDerivAt
#print axioms deRham_sym
#print axioms closed_one_form_eq_angle_multiple_add_exact
#print axioms angle_form_closed_not_exact
#print axioms laurent_de_rham_H0_H1
