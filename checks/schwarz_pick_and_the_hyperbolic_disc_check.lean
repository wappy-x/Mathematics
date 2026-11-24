-- Schwarz-Pick: a holomorphic map of the unit disc into itself never increases the disc's hyperbolic distance, never stretches its ruler at a point, and keeps one distance only when it is a Mobius map of the disc.
import Mathlib.Analysis.Complex.Schwarz
import Mathlib.Analysis.SpecialFunctions.Artanh
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum

open Complex Metric ComplexConjugate

noncomputable section

/-- The card's pseudo-distance δ(z, w) = |(z − w)/(1 − w̄ z)|: how far z lands from 0 once the
disc map φ_w(z) = (z − w)/(1 − w̄ z) has moved w to 0. -/
def pseudoDist (z w : ℂ) : ℝ := ‖(z - w) / (1 - conj w * z)‖

/-- The card's hyperbolic (Poincare) distance on the unit disc, d(z, w) = 2 artanh δ(z, w). -/
def hypDist (z w : ℂ) : ℝ := 2 * Real.artanh (pseudoDist z w)

-- Helper lemmas for the proofs below.

lemma sp_norm_identity (w z : ℂ) :
    ‖1 - conj w * z‖ ^ 2 - ‖z - w‖ ^ 2 = (1 - ‖w‖ ^ 2) * (1 - ‖z‖ ^ 2) := by
  simp only [Complex.sq_norm, normSq_apply, sub_re, sub_im, mul_re, mul_im, conj_re, conj_im,
    one_re, one_im]
  ring

lemma sp_den_ne_zero {w z : ℂ} (hw : ‖w‖ < 1) (hz : ‖z‖ < 1) : 1 - conj w * z ≠ 0 := by
  intro h
  have h1 : conj w * z = 1 := by linear_combination -h
  have h2 : ‖conj w * z‖ < 1 := by
    rw [norm_mul, Complex.norm_conj]
    nlinarith [norm_nonneg w, norm_nonneg z]
  rw [h1] at h2
  simp at h2

lemma sp_mob_norm_lt {w z : ℂ} (hw : ‖w‖ < 1) (hz : ‖z‖ < 1) :
    ‖(z - w) / (1 - conj w * z)‖ < 1 := by
  have hd := sp_den_ne_zero hw hz
  have hpos : 0 < ‖1 - conj w * z‖ := norm_pos_iff.mpr hd
  rw [norm_div, div_lt_one hpos]
  have h := sp_norm_identity w z
  have : 0 < (1 - ‖w‖ ^ 2) * (1 - ‖z‖ ^ 2) := by
    apply mul_pos <;> nlinarith [norm_nonneg w, norm_nonneg z]
  nlinarith [norm_nonneg (z - w), norm_nonneg (1 - conj w * z)]

lemma sp_mob_mapsTo {a : ℂ} (ha : ‖a‖ < 1) :
    Set.MapsTo (fun ζ : ℂ => (ζ - a) / (1 - conj a * ζ)) (ball 0 1) (ball 0 1) := by
  intro ζ hζ
  rw [mem_ball_zero_iff] at hζ ⊢
  exact sp_mob_norm_lt ha hζ

lemma sp_mob_hasDerivAt {a ζ : ℂ} (hd : 1 - conj a * ζ ≠ 0) :
    HasDerivAt (fun ζ : ℂ => (ζ - a) / (1 - conj a * ζ))
      ((1 - conj a * a) / (1 - conj a * ζ) ^ 2) ζ := by
  have h1 : HasDerivAt (fun ζ : ℂ => ζ - a) 1 ζ := (hasDerivAt_id ζ).sub_const a
  have h2 : HasDerivAt (fun ζ : ℂ => 1 - conj a * ζ) (-conj a) ζ := by
    simpa using ((hasDerivAt_id ζ).const_mul (conj a)).const_sub 1
  convert h1.div h2 hd using 1
  field_simp
  ring

lemma sp_mob_diffOn {a : ℂ} (ha : ‖a‖ < 1) :
    DifferentiableOn ℂ (fun ζ : ℂ => (ζ - a) / (1 - conj a * ζ)) (ball 0 1) := by
  intro ζ hζ
  rw [mem_ball_zero_iff] at hζ
  exact (sp_mob_hasDerivAt (sp_den_ne_zero ha hζ)).differentiableAt.differentiableWithinAt

lemma sp_mob_inv {a z : ℂ} (ha : ‖a‖ < 1) (hz : ‖z‖ < 1) :
    ((z - a) / (1 - conj a * z) - -a) / (1 - conj (-a) * ((z - a) / (1 - conj a * z))) = z := by
  have h1 := sp_den_ne_zero ha hz
  have h2 := sp_den_ne_zero ha ha
  rw [map_neg]
  have h3 : 1 - -conj a * ((z - a) / (1 - conj a * z)) = (1 - conj a * a) / (1 - conj a * z) := by
    rw [eq_div_iff h1, sub_mul, neg_mul, neg_mul, mul_assoc, div_mul_cancel₀ _ h1]
    ring
  have h4 : (z - a) / (1 - conj a * z) - -a = z * (1 - conj a * a) / (1 - conj a * z) := by
    rw [eq_div_iff h1, sub_mul, div_mul_cancel₀ _ h1]
    ring
  rw [h3, h4, div_div_div_cancel_right₀ h1]
  field_simp

lemma sp_one_sub_conj_mul_self_ne_zero {w : ℂ} (hw : ‖w‖ < 1) : 1 - conj w * w ≠ 0 :=
  sp_den_ne_zero hw hw

lemma sp_aux {f : ℂ → ℂ} (hf : DifferentiableOn ℂ f (ball 0 1))
    (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1)) {w : ℂ} (hw : w ∈ ball (0 : ℂ) 1) :
    ∃ g : ℂ → ℂ, DifferentiableOn ℂ g (ball 0 1) ∧ Set.MapsTo g (ball 0 1) (ball 0 1) ∧
      g 0 = 0 ∧
      (∀ z ∈ ball (0 : ℂ) 1,
        g ((z - w) / (1 - conj w * z)) = (f z - f w) / (1 - conj (f w) * f z)) ∧
      HasDerivAt g (deriv f w * (1 - conj w * w) / (1 - conj (f w) * f w)) 0 := by
  have hw1 : ‖w‖ < 1 := mem_ball_zero_iff.mp hw
  have hnw : ‖-w‖ < 1 := by rwa [norm_neg]
  have hbw : f w ∈ ball (0 : ℂ) 1 := hmaps hw
  have hb1 : ‖f w‖ < 1 := mem_ball_zero_iff.mp hbw
  set b := f w with hb
  refine ⟨fun ζ => (f ((ζ - -w) / (1 - conj (-w) * ζ)) - b) /
      (1 - conj b * f ((ζ - -w) / (1 - conj (-w) * ζ))), ?_, ?_, ?_, ?_, ?_⟩
  · exact (sp_mob_diffOn hb1).comp (hf.comp (sp_mob_diffOn hnw) (sp_mob_mapsTo hnw))
      (hmaps.comp (sp_mob_mapsTo hnw))
  · exact (sp_mob_mapsTo hb1).comp (hmaps.comp (sp_mob_mapsTo hnw))
  · simp [hb]
  · intro z hz
    have hz1 : ‖z‖ < 1 := mem_ball_zero_iff.mp hz
    simp only
    rw [sp_mob_inv hw1 hz1]
  · have e0 : (0 - -w) / (1 - conj (-w) * 0) = w := by simp
    have hM := sp_mob_hasDerivAt (a := -w) (ζ := 0) (by simp)
    have hF : HasDerivAt f (deriv f w) ((0 - -w) / (1 - conj (-w) * 0)) := by
      rw [e0]
      exact (hf.differentiableAt (isOpen_ball.mem_nhds hw)).hasDerivAt
    have hFM := hF.comp 0 hM
    have hB : HasDerivAt (fun ζ : ℂ => (ζ - b) / (1 - conj b * ζ))
        ((1 - conj b * b) / (1 - conj b * b) ^ 2)
        ((f ∘ fun ζ : ℂ => (ζ - -w) / (1 - conj (-w) * ζ)) 0) := by
      simp only [Function.comp_apply, e0]
      exact sp_mob_hasDerivAt (sp_den_ne_zero hb1 hb1)
    refine (hB.comp 0 hFM).congr_deriv ?_
    have h1 := sp_den_ne_zero hb1 hb1
    simp only [map_neg, mul_zero, sub_zero, one_pow, div_one, neg_mul_neg]
    field_simp

lemma sp_pd_rot {lam x y : ℂ} (hl : ‖lam‖ = 1) :
    pseudoDist (lam * x) (lam * y) = pseudoDist x y := by
  unfold pseudoDist
  have h : conj lam * lam = 1 := by rw [conj_mul', hl]; simp
  rw [show lam * x - lam * y = lam * (x - y) by ring, map_mul,
    show 1 - conj lam * conj y * (lam * x) = 1 - (conj lam * lam) * conj y * x by ring, h,
    one_mul, mul_div_assoc, norm_mul, hl, one_mul]

lemma sp_pd_mob {c u v : ℂ} (hc : ‖c‖ < 1) (hu : ‖u‖ < 1) (hv : ‖v‖ < 1) :
    pseudoDist ((u - c) / (1 - conj c * u)) ((v - c) / (1 - conj c * v)) = pseudoDist u v := by
  unfold pseudoDist
  have h1 := sp_den_ne_zero hc hu
  have h2 := sp_den_ne_zero hc hv
  have h3 : 1 - c * conj v ≠ 0 := by
    intro h
    apply h2
    have := congrArg conj h
    simpa [map_sub, map_mul, mul_comm] using this
  have h1' : 1 - u * conj c ≠ 0 := by rwa [mul_comm]
  have h2' : 1 - v * conj c ≠ 0 := by rwa [mul_comm]
  have h3' : 1 - conj v * c ≠ 0 := by rwa [mul_comm]
  have A : (u - c) / (1 - conj c * u) - (v - c) / (1 - conj c * v) =
      (1 - conj c * c) * (u - v) / ((1 - conj c * u) * (1 - conj c * v)) := by
    field_simp
    ring
  have B : 1 - conj ((v - c) / (1 - conj c * v)) * ((u - c) / (1 - conj c * u)) =
      (1 - conj c * c) * (1 - conj v * u) / ((1 - c * conj v) * (1 - conj c * u)) := by
    simp only [map_div₀, map_sub, map_mul, map_one, Complex.conj_conj]
    field_simp
    ring
  have hn : ‖1 - c * conj v‖ = ‖1 - conj c * v‖ := by
    rw [← Complex.norm_conj]
    simp [map_sub, map_mul, mul_comm]
  have hcc := sp_den_ne_zero hc hc
  rw [A, B, norm_div, norm_div, norm_div, norm_div, norm_mul, norm_mul, norm_mul, norm_mul, hn]
  have p1 : 0 < ‖1 - conj c * c‖ := norm_pos_iff.mpr hcc
  have p2 : 0 < ‖1 - conj c * u‖ := norm_pos_iff.mpr h1
  have p3 : 0 < ‖1 - conj c * v‖ := norm_pos_iff.mpr h2
  field_simp

lemma sp_alg {a a' b b' C κ c c' φ u : ℂ} (hκ : C * κ = 1) (hφ : φ * (1 - a' * u) = u - a)
    (hc : c * (C - a' * b) = a * C - b) (hc' : c' * (κ - a * b') = a' * κ - b')
    (h1 : 1 - a' * u ≠ 0) (h2 : 1 - -b' * (C * φ) ≠ 0) (h3 : C - a' * b ≠ 0)
    (h4 : 1 - b' * C * a ≠ 0) :
    (C * φ - -b) / (1 - -b' * (C * φ)) =
      (C - b * a') / (1 - b' * C * a) * ((u - c) / (1 - c' * u)) := by
  have eN : (C - b * a') * u + (b - C * a) = (C * φ - -b) * (1 - a' * u) := by
    linear_combination (-C) * hφ
  have eD : (1 - b' * C * a) + (b' * C - a') * u = (1 - -b' * (C * φ)) * (1 - a' * u) := by
    linear_combination (-b' * C) * hφ
  have hD : (1 - b' * C * a) + (b' * C - a') * u ≠ 0 := by
    rw [eD]; exact mul_ne_zero h2 h1
  have L : (C * φ - -b) / (1 - -b' * (C * φ)) =
      ((C - b * a') * u + (b - C * a)) / ((1 - b' * C * a) + (b' * C - a') * u) := by
    rw [eN, eD, mul_div_mul_right _ _ h1]
  have e1 : u - c = ((C - b * a') * u + (b - C * a)) / (C - a' * b) := by
    rw [eq_div_iff h3]; linear_combination (-1 : ℂ) * hc
  have e2 : 1 - c' * u = ((1 - b' * C * a) + (b' * C - a') * u) / (1 - b' * C * a) := by
    rw [eq_div_iff h4]; linear_combination (c' * u - u * a') * hκ - C * u * hc'
  rw [L, e1, e2, show C - b * a' = C - a' * b by ring]
  have h4' : 1 - C * a * b' ≠ 0 := by
    intro h; apply h4; linear_combination h
  field_simp

#print axioms sp_norm_identity
#print axioms sp_den_ne_zero
#print axioms sp_mob_norm_lt
#print axioms sp_mob_mapsTo
#print axioms sp_mob_hasDerivAt
#print axioms sp_mob_diffOn
#print axioms sp_mob_inv
#print axioms sp_one_sub_conj_mul_self_ne_zero
#print axioms sp_aux
#print axioms sp_pd_rot
#print axioms sp_pd_mob
#print axioms sp_alg

/-- **Schwarz-Pick, distance form.** Let f be holomorphic on the open unit disc and map the disc
into the disc. Then for any two points z and w of the disc, the hyperbolic distance between
f(z) and f(w) is at most the hyperbolic distance between z and w: f never stretches the disc's
distance. -/
theorem hypDist_map_le_of_holomorphic_self_map_of_disc {f : ℂ → ℂ}
    (hf : DifferentiableOn ℂ f (ball 0 1)) (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1))
    {z w : ℂ} (hz : z ∈ ball (0 : ℂ) 1) (hw : w ∈ ball (0 : ℂ) 1) :
    hypDist (f z) (f w) ≤ hypDist z w := by
  obtain ⟨g, hgd, hgm, hg0, hgeq, -⟩ := sp_aux hf hmaps hw
  have hz1 := mem_ball_zero_iff.mp hz
  have hw1 := mem_ball_zero_iff.mp hw
  have hle : pseudoDist (f z) (f w) ≤ pseudoDist z w := by
    unfold pseudoDist
    rw [← hgeq z hz]
    exact Complex.norm_le_norm_of_mapsTo_ball hgd (hgm.mono_right ball_subset_closedBall) hg0
      (sp_mob_norm_lt hw1 hz1)
  have := Real.artanh_le_artanh (neg_one_lt_zero.trans_le (norm_nonneg _))
    (sp_mob_norm_lt hw1 hz1) hle
  unfold hypDist pseudoDist
  linarith

/-- **Schwarz-Pick, stretch form.** With the same f, holomorphic on the open unit disc and mapping
it into itself, at every point z of the disc the stretch of the disc's ruler,
|f'(z)| (1 − |z|²)/(1 − |f(z)|²), is at most 1. -/
theorem hyperbolic_stretch_le_one_of_holomorphic_self_map_of_disc {f : ℂ → ℂ}
    (hf : DifferentiableOn ℂ f (ball 0 1)) (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1))
    {z : ℂ} (hz : z ∈ ball (0 : ℂ) 1) :
    ‖deriv f z‖ * (1 - ‖z‖ ^ 2) / (1 - ‖f z‖ ^ 2) ≤ 1 := by
  obtain ⟨g, hgd, hgm, hg0, -, hgder⟩ := sp_aux hf hmaps hz
  have h := Complex.norm_deriv_le_one_of_mapsTo_ball hgd
    (by rw [hg0]; exact hgm.mono_right ball_subset_closedBall) one_pos
  rw [hgder.deriv] at h
  have hz1 := mem_ball_zero_iff.mp hz
  have hfz1 := mem_ball_zero_iff.mp (hmaps hz)
  rw [conj_mul', conj_mul'] at h
  have e1 : (1 - (‖z‖ : ℂ) ^ 2) = ((1 - ‖z‖ ^ 2 : ℝ) : ℂ) := by push_cast; ring
  have e2 : (1 - (‖f z‖ : ℂ) ^ 2) = ((1 - ‖f z‖ ^ 2 : ℝ) : ℂ) := by push_cast; ring
  have p1 : 0 ≤ 1 - ‖z‖ ^ 2 := by nlinarith [norm_nonneg z]
  have p2 : 0 ≤ 1 - ‖f z‖ ^ 2 := by nlinarith [norm_nonneg (f z)]
  rw [e1, e2, norm_div, norm_mul, Complex.norm_real, Complex.norm_real, Real.norm_of_nonneg p1,
    Real.norm_of_nonneg p2] at h
  exact h

/-- **Keeping one distance forces a rigid motion.** With the same f, holomorphic on the open
unit disc and mapping it into itself, suppose f keeps the hyperbolic distance between one pair of
different points a and z of the disc. Then f keeps every hyperbolic distance in the disc, and f
is a Mobius map of the disc: a turn λ (|λ| = 1) after a Blaschke factor φ_c with c in the disc,
f(w) = λ (w − c)/(1 − c̄ w). -/
theorem isometry_and_mobius_of_hypDist_eq {f : ℂ → ℂ}
    (hf : DifferentiableOn ℂ f (ball 0 1)) (hmaps : Set.MapsTo f (ball 0 1) (ball 0 1))
    {a z : ℂ} (ha : a ∈ ball (0 : ℂ) 1) (hz : z ∈ ball (0 : ℂ) 1) (hne : z ≠ a)
    (heq : hypDist (f z) (f a) = hypDist z a) :
    (∀ u ∈ ball (0 : ℂ) 1, ∀ v ∈ ball (0 : ℂ) 1, hypDist (f u) (f v) = hypDist u v) ∧
      ∃ c ∈ ball (0 : ℂ) 1, ∃ lam : ℂ, ‖lam‖ = 1 ∧
        ∀ u ∈ ball (0 : ℂ) 1, f u = lam * ((u - c) / (1 - conj c * u)) := by
  obtain ⟨g, hgd, hgm, hg0, hgeq, -⟩ := sp_aux hf hmaps ha
  have ha1 := mem_ball_zero_iff.mp ha
  have hz1 := mem_ball_zero_iff.mp hz
  have hfz1 := mem_ball_zero_iff.mp (hmaps hz)
  have hb1 := mem_ball_zero_iff.mp (hmaps ha)
  set b := f a with hb
  -- equal distance gives equal pseudo-distance
  have hpd : pseudoDist (f z) b = pseudoDist z a := by
    unfold hypDist at heq
    have h' : Real.artanh (pseudoDist (f z) b) = Real.artanh (pseudoDist z a) := by linarith
    exact Real.artanh_injOn ⟨neg_one_lt_zero.trans_le (norm_nonneg _), sp_mob_norm_lt hb1 hfz1⟩
      ⟨neg_one_lt_zero.trans_le (norm_nonneg _), sp_mob_norm_lt ha1 hz1⟩ h'
  set ζ := (z - a) / (1 - conj a * z) with hζdef
  have hζ : ζ ∈ ball (0 : ℂ) 1 := sp_mob_mapsTo ha1 hz
  have hζne : ζ ≠ 0 := div_ne_zero (sub_ne_zero.mpr hne) (sp_den_ne_zero ha1 hz1)
  have hgζ : ‖g ζ‖ = ‖ζ‖ := by
    rw [hgeq z hz]
    exact hpd
  have hds : ‖dslope g 0 ζ‖ = 1 / 1 := by
    rw [dslope_of_ne _ hζne, slope_def_module, hg0, sub_zero, sub_zero, norm_smul, norm_inv, hgζ,
      inv_mul_cancel₀ (norm_ne_zero_iff.mpr hζne)]
    norm_num
  have haff := Complex.affine_of_mapsTo_ball_of_norm_dslope_eq_div hgd
    (by rw [hg0]; exact hgm.mono_right ball_subset_closedBall) hζ hds
  set C := dslope g 0 ζ with hCdef
  have hC : ‖C‖ = 1 := by simpa using hds
  have hgform : ∀ u ∈ ball (0 : ℂ) 1, g u = C * u := fun u hu => by
    rw [haff hu]; simp [hg0, smul_eq_mul, mul_comm]
  have hfu : ∀ u ∈ ball (0 : ℂ) 1, f u = (C * ((u - a) / (1 - conj a * u)) - -b) /
      (1 - conj (-b) * (C * ((u - a) / (1 - conj a * u)))) := by
    intro u hu
    have hfu1 := mem_ball_zero_iff.mp (hmaps hu)
    have := hgeq u hu
    rw [hgform _ (sp_mob_mapsTo ha1 hu)] at this
    rw [this, sp_mob_inv hb1 hfu1]
  -- the Mobius form
  have hCC : conj C * C = 1 := by rw [conj_mul', hC]; simp
  have hκ : C * conj C = 1 := by rw [mul_comm]; exact hCC
  have hC0 : C ≠ 0 := by intro h; rw [h] at hC; simp at hC
  have hCa : ‖C * a‖ < 1 := by rw [norm_mul, hC, one_mul]; exact ha1
  have h4 : 1 - conj b * C * a ≠ 0 := by
    rw [mul_assoc]; exact sp_den_ne_zero hb1 hCa
  have hconj : conj (C - conj a * b) = conj C * (1 - conj b * C * a) := by
    simp only [map_sub, map_mul, Complex.conj_conj]
    linear_combination (a * conj b) * hCC
  have hnorm : ‖C - conj a * b‖ = ‖1 - conj b * C * a‖ := by
    rw [← Complex.norm_conj, hconj, norm_mul, Complex.norm_conj, hC, one_mul]
  have h3 : C - conj a * b ≠ 0 := by
    rw [← norm_ne_zero_iff, hnorm, norm_ne_zero_iff]; exact h4
  set c := (a * C - b) / (C - conj a * b) with hcdef
  have hc : c * (C - conj a * b) = a * C - b := div_mul_cancel₀ _ h3
  have hc3 : conj (C - conj a * b) ≠ 0 := by
    rwa [map_ne_zero]
  have hc' : conj c * (conj C - a * conj b) = conj a * conj C - conj b := by
    have := div_mul_cancel₀ (conj (a * C - b)) hc3
    simp only [map_sub, map_mul, Complex.conj_conj] at this
    rw [hcdef, map_div₀]
    simpa only [map_sub, map_mul, Complex.conj_conj] using this
  have hc1 : ‖c‖ < 1 := by
    have hid := sp_norm_identity b (a * C)
    have hpos : 0 < (1 - ‖b‖ ^ 2) * (1 - ‖a * C‖ ^ 2) := by
      rw [norm_mul, hC, mul_one]
      apply mul_pos <;> nlinarith [norm_nonneg a, norm_nonneg b]
    have hp : 0 < ‖C - conj a * b‖ := norm_pos_iff.mpr h3
    rw [hcdef, norm_div, div_lt_one hp, hnorm]
    rw [show conj b * (a * C) = conj b * C * a by ring] at hid
    nlinarith [norm_nonneg (a * C - b), norm_nonneg (1 - conj b * C * a)]
  have hcball : c ∈ ball (0 : ℂ) 1 := mem_ball_zero_iff.mpr hc1
  set lam := (C - b * conj a) / (1 - conj b * C * a) with hlamdef
  have hlam : ‖lam‖ = 1 := by
    rw [hlamdef, norm_div, ← hnorm, show C - b * conj a = C - conj a * b by ring]
    exact div_self (norm_ne_zero_iff.mpr h3)
  have hform : ∀ u ∈ ball (0 : ℂ) 1, f u = lam * ((u - c) / (1 - conj c * u)) := by
    intro u hu
    have hu1 := mem_ball_zero_iff.mp hu
    have hφ1 : ‖C * ((u - a) / (1 - conj a * u))‖ < 1 := by
      rw [norm_mul, hC, one_mul]; exact sp_mob_norm_lt ha1 hu1
    have hnb : ‖-b‖ < 1 := by rwa [norm_neg]
    have h2 := sp_den_ne_zero hnb hφ1
    rw [hfu u hu]
    rw [map_neg] at h2 ⊢
    exact sp_alg hκ (div_mul_cancel₀ _ (sp_den_ne_zero ha1 hu1)) hc hc'
      (sp_den_ne_zero ha1 hu1) h2 h3 h4
  refine ⟨fun u hu v hv => ?_, c, hcball, lam, hlam, hform⟩
  have hu1 := mem_ball_zero_iff.mp hu
  have hv1 := mem_ball_zero_iff.mp hv
  unfold hypDist
  rw [hform u hu, hform v hv, sp_pd_rot hlam, sp_pd_mob hc1 hu1 hv1]

-- The card's worked numbers for f(z) = z^2 at z = 1/2, all exact fractions.
-- f(1/2) = 1/4.
example : ((1 / 2 : ℂ)) ^ 2 = 1 / 4 := by norm_num
-- The stretch of the ruler: |f'(1/2)| (1 − 1/4)/(1 − 1/16) = 1 × (3/4)/(15/16) = 4/5, at most 1.
example : ‖deriv (fun z : ℂ => z ^ 2) (1 / 2)‖ * (1 - ‖(1 / 2 : ℂ)‖ ^ 2)
    / (1 - ‖(1 / 2 : ℂ) ^ 2‖ ^ 2) = 4 / 5 := by
  have h : deriv (fun z : ℂ => z ^ 2) (1 / 2) = 1 := by
    rw [(hasDerivAt_pow 2 (1 / 2 : ℂ)).deriv]; norm_num
  rw [h]
  simp
  norm_num
-- Hyperbolic distance from 0 to 1/2 is ln 3, and from 0 to f(1/2) = 1/4 it is ln(5/3): shrunk.
example : hypDist 0 (1 / 2) = Real.log 3 := by
  have h : pseudoDist 0 (1 / 2) = 1 / 2 := by
    unfold pseudoDist; simp
  unfold hypDist
  rw [h, Real.artanh_eq_half_log (by constructor <;> norm_num)]
  norm_num
  ring
example : hypDist 0 (1 / 4) = Real.log (5 / 3) := by
  have h : pseudoDist 0 (1 / 4) = 1 / 4 := by
    unfold pseudoDist; simp
  unfold hypDist
  rw [h, Real.artanh_eq_half_log (by constructor <;> norm_num)]
  norm_num
  ring
-- From 1/2 to −1/2 the distance is ln 3 + ln 3; squaring sends both to 1/4, distance 0.
example : hypDist (1 / 2) (-1 / 2) = 2 * Real.log 3 := by
  have h : pseudoDist (1 / 2) (-1 / 2) = 4 / 5 := by
    unfold pseudoDist
    have e : ((1 / 2 : ℂ) - -1 / 2) / (1 - conj (-1 / 2 : ℂ) * (1 / 2)) = ((4 / 5 : ℝ) : ℂ) := by
      have c2 : conj (2 : ℂ) = 2 := map_ofNat _ 2
      simp [map_div₀, c2]
      norm_num
    rw [e, Complex.norm_real, Real.norm_of_nonneg (by norm_num)]
  unfold hypDist
  rw [h, Real.artanh_eq_half_log (by constructor <;> norm_num)]
  rw [show (1 + 4 / 5 : ℝ) / (1 - 4 / 5) = 3 ^ 2 by norm_num, Real.log_pow]
  ring
example : hypDist ((1 / 2 : ℂ) ^ 2) ((-1 / 2 : ℂ) ^ 2) = 0 := by
  unfold hypDist pseudoDist
  norm_num
-- The Mobius map m = φ_{1/2} sends 1/2 to 0 and 0 to −1/2.
example : (1 / 2 - 1 / 2 : ℂ) / (1 - conj (1 / 2 : ℂ) * (1 / 2)) = 0 := by simp
example : (0 - 1 / 2 : ℂ) / (1 - conj (1 / 2 : ℂ) * 0) = -1 / 2 := by
  simp
  ring
-- The mistake 2z^2: it sends 4/5 to 32/25, outside the disc.
example : (2 : ℝ) * (4 / 5) ^ 2 = 32 / 25 ∧ (1 : ℝ) < 32 / 25 := by
  constructor <;> norm_num

#print axioms hypDist_map_le_of_holomorphic_self_map_of_disc
#print axioms hyperbolic_stretch_le_one_of_holomorphic_self_map_of_disc
#print axioms isometry_and_mobius_of_hypDist_eq
