-- Killing field: in the globe's chart, the fields that solve the Killing equation are exactly the spins about axes through the centre, one for each turn rate (three independent ones), on the flattened Earth only the polar spin survives, and two spins bracket to minus the third.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Prod

open Real Set
open scoped ContDiff

/-! The chart is `(φ, θ)`: a point `p : ℝ × ℝ` has `p.1 = φ`, the angle down from the North
Pole, and `p.2 = θ`, the longitude east, both in radians. Index `0` is `φ` and index `1` is `θ`.
A vector field `X` has components `X 0 = X^φ` and `X 1 = X^θ`. A metric is its table
`g i j`, a function of the point. All are functions on the chart. -/

/-- The chart's unit steps: `0` is a step in `φ`, `1` a step in `θ`. -/
def chartStep : Fin 2 → ℝ × ℝ := ![(1, 0), (0, 1)]

/-- `∂_i f`: the rate of change of `f` along chart direction `i`. -/
noncomputable def pd (i : Fin 2) (f : ℝ × ℝ → ℝ) (p : ℝ × ℝ) : ℝ :=
  fderiv ℝ f p (chartStep i)

/-- The card's chart formula for the Lie derivative of a metric along a field:
`(ℒ_X g)_ij = X^k ∂_k g_ij + g_kj ∂_i X^k + g_ik ∂_j X^k`, summed over `k`. -/
noncomputable def lieDerivMetric (g : Fin 2 → Fin 2 → ℝ × ℝ → ℝ) (X : Fin 2 → ℝ × ℝ → ℝ)
    (i j : Fin 2) (p : ℝ × ℝ) : ℝ :=
  ∑ k : Fin 2, (X k p * pd k (g i j) p + g k j p * pd i (X k) p + g i k p * pd j (X k) p)

/-- The Lie bracket of two fields in the chart: `[X, Y]^k = X^i ∂_i Y^k - Y^i ∂_i X^k`. -/
noncomputable def lieBracketChart (X Y : Fin 2 → ℝ × ℝ → ℝ) (k : Fin 2) (p : ℝ × ℝ) : ℝ :=
  ∑ i : Fin 2, (X i p * pd i (Y k) p - Y i p * pd i (X k) p)

/-- The round globe of radius `R`: `g_φφ = R²`, `g_θθ = R² sin² φ`, `g_φθ = 0`. -/
noncomputable def roundMetric (R : ℝ) : Fin 2 → Fin 2 → ℝ × ℝ → ℝ :=
  fun i j p => !![R ^ 2, 0; 0, R ^ 2 * sin p.1 ^ 2] i j

/-- The flattened Earth with equatorial radius `a` and polar radius `b`, in the chart
`r = (a sin φ cos θ, a sin φ sin θ, b cos φ)`: `g_φφ = a² cos² φ + b² sin² φ`,
`g_θθ = a² sin² φ`, `g_φθ = 0`. -/
noncomputable def flattenedMetric (a b : ℝ) : Fin 2 → Fin 2 → ℝ × ℝ → ℝ :=
  fun i j p => !![a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2, 0; 0, a ^ 2 * sin p.1 ^ 2] i j

/-- The spin with turn rate `ω = (ωx, ωy, ωz)` about the three axes through the centre:
`X^φ = ωy cos θ - ωx sin θ`, `X^θ = ωz - cot φ (ωx cos θ + ωy sin θ)`. -/
noncomputable def spinField (wx wy wz : ℝ) : Fin 2 → ℝ × ℝ → ℝ :=
  fun k p => ![wy * cos p.2 - wx * sin p.2,
               wz - cos p.1 / sin p.1 * (wx * cos p.2 + wy * sin p.2)] k

/-- The chart's domain: every point of the globe except the two poles, `0 < φ < π`. -/
noncomputable def chartDomain : Set (ℝ × ℝ) := Ioo 0 π ×ˢ univ

/-! Helper lemmas for the proofs below. -/

lemma kf_isOpen_chartDomain : IsOpen chartDomain := isOpen_Ioo.prod isOpen_univ

lemma kf_mem_chartDomain {p : ℝ × ℝ} : p ∈ chartDomain ↔ 0 < p.1 ∧ p.1 < π := by
  simp [chartDomain]

lemma kf_hasDerivAt_pd0 {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (hf : DifferentiableAt ℝ f p) :
    HasDerivAt (fun x => f (x, p.2)) (pd 0 f p) p.1 := by
  have h1 : HasDerivAt (fun x : ℝ => (x, p.2)) ((1 : ℝ), (0 : ℝ)) p.1 :=
    HasDerivAt.prodMk (hasDerivAt_id _) (hasDerivAt_const _ _)
  have := hf.hasFDerivAt.comp_hasDerivAt (x := p.1) h1
  have e : pd 0 f p = fderiv ℝ f p ((1 : ℝ), (0 : ℝ)) := by simp [pd, chartStep]
  rw [e]; exact this

lemma kf_hasDerivAt_pd1 {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (hf : DifferentiableAt ℝ f p) :
    HasDerivAt (fun y => f (p.1, y)) (pd 1 f p) p.2 := by
  have h1 : HasDerivAt (fun y : ℝ => (p.1, y)) ((0 : ℝ), (1 : ℝ)) p.2 :=
    HasDerivAt.prodMk (hasDerivAt_const _ _) (hasDerivAt_id _)
  have := hf.hasFDerivAt.comp_hasDerivAt (x := p.2) h1
  have e : pd 1 f p = fderiv ℝ f p ((0 : ℝ), (1 : ℝ)) := by simp [pd, chartStep]
  rw [e]; exact this

lemma kf_pd0_eq {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} {d : ℝ} (hf : DifferentiableAt ℝ f p)
    (h : HasDerivAt (fun x => f (x, p.2)) d p.1) : pd 0 f p = d :=
  (kf_hasDerivAt_pd0 hf).unique h

lemma kf_pd1_eq {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} {d : ℝ} (hf : DifferentiableAt ℝ f p)
    (h : HasDerivAt (fun y => f (p.1, y)) d p.2) : pd 1 f p = d :=
  (kf_hasDerivAt_pd1 hf).unique h

lemma kf_pd_congr {f g : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (i : Fin 2) (h : f =ᶠ[nhds p] g) :
    pd i f p = pd i g p := by
  simp only [pd, h.fderiv_eq]

lemma kf_pd_congr_dom {f g : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (i : Fin 2) (hp : p ∈ chartDomain)
    (h : ∀ q ∈ chartDomain, f q = g q) : pd i f p = pd i g p :=
  kf_pd_congr i (Filter.eventually_of_mem (kf_isOpen_chartDomain.mem_nhds hp) h)

lemma kf_pd_symm {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (hf : ContDiffAt ℝ ∞ f p) :
    pd 0 (pd 1 f) p = pd 1 (pd 0 f) p := by
  have hs := hf.isSymmSndFDerivAt (by simp)
  have hd : DifferentiableAt ℝ (fderiv ℝ f) p :=
    (hf.fderiv_right (m := 1) (by simp)).differentiableAt (by simp)
  have key : ∀ (v w : ℝ × ℝ), fderiv ℝ (fun q => fderiv ℝ f q w) p v = fderiv ℝ (fderiv ℝ f) p v w := by
    intro v w
    have := hd.hasFDerivAt.clm_apply (hasFDerivAt_const w p)
    rw [this.fderiv]
    simp
  show fderiv ℝ (fun q => fderiv ℝ f q (chartStep 1)) p (chartStep 0) =
    fderiv ℝ (fun q => fderiv ℝ f q (chartStep 0)) p (chartStep 1)
  rw [key, key]
  exact hs _ _

lemma kf_pd_differentiableAt {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (i : Fin 2) (hf : ContDiffAt ℝ ∞ f p) :
    DifferentiableAt ℝ (pd i f) p := by
  have hd : DifferentiableAt ℝ (fderiv ℝ f) p :=
    (hf.fderiv_right (m := 1) (by simp)).differentiableAt (by simp)
  exact (hd.hasFDerivAt.clm_apply (hasFDerivAt_const (chartStep i) p)).differentiableAt

lemma kf_pd_fst {P : ℝ → ℝ} {P' : ℝ} {p : ℝ × ℝ} (hP : HasDerivAt P P' p.1) :
    pd 0 (fun q => P q.1) p = P' ∧ pd 1 (fun q => P q.1) p = 0 := by
  have hd : DifferentiableAt ℝ (fun q : ℝ × ℝ => P q.1) p :=
    hP.differentiableAt.comp p differentiableAt_fst
  exact ⟨kf_pd0_eq hd hP, kf_pd1_eq hd (hasDerivAt_const p.2 (P p.1))⟩

lemma kf_lie_diag (P Q : ℝ → ℝ) (P' Q' : ℝ) (g : Fin 2 → Fin 2 → ℝ × ℝ → ℝ)
    (hg : g = fun i j q => !![P q.1, 0; 0, Q q.1] i j)
    (X : Fin 2 → ℝ × ℝ → ℝ) (p : ℝ × ℝ)
    (hP : HasDerivAt P P' p.1) (hQ : HasDerivAt Q Q' p.1) :
    lieDerivMetric g X 0 0 p = X 0 p * P' + 2 * P p.1 * pd 0 (X 0) p ∧
    lieDerivMetric g X 1 1 p = X 0 p * Q' + 2 * Q p.1 * pd 1 (X 1) p ∧
    lieDerivMetric g X 0 1 p = P p.1 * pd 1 (X 0) p + Q p.1 * pd 0 (X 1) p ∧
    lieDerivMetric g X 1 0 p = P p.1 * pd 1 (X 0) p + Q p.1 * pd 0 (X 1) p := by
  subst hg
  obtain ⟨h0P, h1P⟩ := kf_pd_fst hP
  obtain ⟨h0Q, h1Q⟩ := kf_pd_fst hQ
  have hz : ∀ k, pd k (fun _ : ℝ × ℝ => (0:ℝ)) p = 0 := by intro k; simp [pd]
  refine ⟨?_, ?_, ?_, ?_⟩ <;>
    simp [lieDerivMetric, Fin.sum_univ_two, h0P, h1P, h0Q, h1Q, hz] <;> ring

lemma kf_spin0 (wx wy wz : ℝ) :
    spinField wx wy wz 0 = fun q => wy * cos q.2 - wx * sin q.2 := by
  funext q; simp [spinField]

lemma kf_spin1 (wx wy wz : ℝ) :
    spinField wx wy wz 1 = fun q => wz - cos q.1 / sin q.1 * (wx * cos q.2 + wy * sin q.2) := by
  funext q; simp [spinField]

lemma kf_spin_pd (wx wy wz : ℝ) {p : ℝ × ℝ} (hs : sin p.1 ≠ 0) :
    pd 0 (spinField wx wy wz 0) p = 0 ∧
    pd 1 (spinField wx wy wz 0) p = -wy * sin p.2 - wx * cos p.2 ∧
    pd 0 (spinField wx wy wz 1) p = (wx * cos p.2 + wy * sin p.2) / sin p.1 ^ 2 ∧
    pd 1 (spinField wx wy wz 1) p = -(cos p.1 / sin p.1) * (-wx * sin p.2 + wy * cos p.2) := by
  rw [kf_spin0, kf_spin1]
  have d0 : DifferentiableAt ℝ (fun q : ℝ × ℝ => wy * cos q.2 - wx * sin q.2) p := by fun_prop
  have d1 : DifferentiableAt ℝ
      (fun q : ℝ × ℝ => wz - cos q.1 / sin q.1 * (wx * cos q.2 + wy * sin q.2)) p := by
    fun_prop (disch := exact hs)
  refine ⟨?_, ?_, ?_, ?_⟩
  · exact kf_pd0_eq d0 (hasDerivAt_const p.1 (wy * cos p.2 - wx * sin p.2))
  · apply kf_pd1_eq d0
    have := ((hasDerivAt_cos p.2).const_mul wy).sub ((hasDerivAt_sin p.2).const_mul wx)
    convert this using 1; ring
  · apply kf_pd0_eq d1
    have := (((hasDerivAt_cos p.1).div (hasDerivAt_sin p.1) hs).mul_const
      (wx * cos p.2 + wy * sin p.2)).const_sub wz
    convert this using 1
    field_simp
    have := sin_sq_add_cos_sq p.1
    linear_combination (-(wx * cos p.2 + wy * sin p.2)) * this
  · apply kf_pd1_eq d1
    have := ((((hasDerivAt_cos p.2).const_mul wx).add ((hasDerivAt_sin p.2).const_mul wy)).const_mul
      (cos p.1 / sin p.1)).const_sub wz
    convert this using 1; ring

lemma kf_const_Ioo {F : ℝ → ℝ} (hF : ∀ x ∈ Ioo 0 π, HasDerivAt F 0 x) {x y : ℝ}
    (hx : x ∈ Ioo 0 π) (hy : y ∈ Ioo 0 π) : F x = F y :=
  isOpen_Ioo.is_const_of_deriv_eq_zero isPreconnected_Ioo
    (fun z hz => (hF z hz).differentiableAt.differentiableWithinAt)
    (fun z hz => (hF z hz).deriv) hx hy

lemma kf_pi2_mem : π / 2 ∈ Ioo 0 π := ⟨by positivity, by linarith [pi_pos]⟩

lemma kf_pi4_mem : π / 4 ∈ Ioo 0 π := ⟨by positivity, by linarith [pi_pos]⟩

lemma kf_line_smooth {u : ℝ × ℝ → ℝ} (hu : ContDiffOn ℝ ∞ u chartDomain) {x : ℝ}
    (hx : x ∈ Ioo 0 π) : ContDiff ℝ ∞ (fun y => u (x, y)) := by
  have : ContDiff ℝ ∞ (u ∘ fun y : ℝ => (x, y)) :=
    hu.comp_contDiff (by fun_prop) (fun y => by simpa [chartDomain] using hx)
  exact this

lemma kf_smooth_derivs {f : ℝ → ℝ} (hf : ContDiff ℝ ∞ f) :
    (∀ x, HasDerivAt f (deriv f x) x) ∧ (∀ x, HasDerivAt (deriv f) (deriv (deriv f) x) x) := by
  obtain ⟨h1, h2⟩ := contDiff_infty_iff_deriv.1 hf
  obtain ⟨h3, -⟩ := contDiff_infty_iff_deriv.1 h2
  exact ⟨fun x => (h1 x).hasDerivAt, fun x => (h3 x).hasDerivAt⟩

lemma kf_cdAt {u : ℝ × ℝ → ℝ} (hu : ContDiffOn ℝ ∞ u chartDomain) {p : ℝ × ℝ}
    (hp : p ∈ chartDomain) : ContDiffAt ℝ ∞ u p :=
  hu.contDiffAt (kf_isOpen_chartDomain.mem_nhds hp)

lemma kf_dAt {u : ℝ × ℝ → ℝ} (hu : ContDiffOn ℝ ∞ u chartDomain) {p : ℝ × ℝ}
    (hp : p ∈ chartDomain) : DifferentiableAt ℝ u p :=
  (kf_cdAt hu hp).differentiableAt (by simp)

lemma kf_cot_deriv {x : ℝ} (hs : sin x ≠ 0) :
    HasDerivAt (fun t => cos t / sin t) (-1 / sin x ^ 2) x := by
  have := (hasDerivAt_cos x).div (hasDerivAt_sin x) hs
  convert this using 1
  congr 1
  linear_combination sin_sq_add_cos_sq x

lemma kf_sin_ne {p : ℝ × ℝ} (hp : p ∈ chartDomain) : sin p.1 ≠ 0 := by
  rw [kf_mem_chartDomain] at hp
  exact (sin_pos_of_pos_of_lt_pi hp.1 hp.2).ne'

lemma kf_spin_unique {w w' : ℝ × ℝ × ℝ}
    (h : ∀ p ∈ chartDomain, ∀ k,
      spinField w.1 w.2.1 w.2.2 k p = spinField w'.1 w'.2.1 w'.2.2 k p) : w = w' := by
  have m1 : ((π / 2, 0) : ℝ × ℝ) ∈ chartDomain := by simpa [chartDomain] using kf_pi2_mem
  have m2 : ((π / 2, π / 2) : ℝ × ℝ) ∈ chartDomain := by simpa [chartDomain] using kf_pi2_mem
  have h1 := h _ m1 0
  have h2 := h _ m2 0
  have h3 := h _ m1 1
  obtain ⟨a, b, c⟩ := w
  obtain ⟨a', b', c'⟩ := w'
  simp [spinField] at h1 h2 h3
  simp [h1, h2, h3]

lemma kf_round_lie (R : ℝ) (X : Fin 2 → ℝ × ℝ → ℝ) (p : ℝ × ℝ) :
    lieDerivMetric (roundMetric R) X 0 0 p = X 0 p * 0 + 2 * R ^ 2 * pd 0 (X 0) p ∧
    lieDerivMetric (roundMetric R) X 1 1 p =
      X 0 p * (2 * R ^ 2 * sin p.1 * cos p.1) + 2 * (R ^ 2 * sin p.1 ^ 2) * pd 1 (X 1) p ∧
    lieDerivMetric (roundMetric R) X 0 1 p =
      R ^ 2 * pd 1 (X 0) p + R ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p ∧
    lieDerivMetric (roundMetric R) X 1 0 p =
      R ^ 2 * pd 1 (X 0) p + R ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p := by
  have hQ : HasDerivAt (fun x => R ^ 2 * sin x ^ 2) (2 * R ^ 2 * sin p.1 * cos p.1) p.1 := by
    have := ((hasDerivAt_sin p.1).pow 2).const_mul (R ^ 2)
    convert this using 1; simp; ring
  exact kf_lie_diag (fun _ => R ^ 2) (fun x => R ^ 2 * sin x ^ 2) 0 _ (roundMetric R) rfl X p
    (hasDerivAt_const _ _) hQ

lemma kf_flat_P_deriv (a b x : ℝ) :
    HasDerivAt (fun x => a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)
      (2 * (b ^ 2 - a ^ 2) * sin x * cos x) x := by
  have := (((hasDerivAt_cos x).pow 2).const_mul (a ^ 2)).add
    (((hasDerivAt_sin x).pow 2).const_mul (b ^ 2))
  convert this using 1; simp; ring

lemma kf_flat_lie (a b : ℝ) (X : Fin 2 → ℝ × ℝ → ℝ) (p : ℝ × ℝ) :
    lieDerivMetric (flattenedMetric a b) X 0 0 p =
      X 0 p * (2 * (b ^ 2 - a ^ 2) * sin p.1 * cos p.1) +
        2 * (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 0 (X 0) p ∧
    lieDerivMetric (flattenedMetric a b) X 1 1 p =
      X 0 p * (2 * a ^ 2 * sin p.1 * cos p.1) + 2 * (a ^ 2 * sin p.1 ^ 2) * pd 1 (X 1) p ∧
    lieDerivMetric (flattenedMetric a b) X 0 1 p =
      (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (X 0) p +
        a ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p ∧
    lieDerivMetric (flattenedMetric a b) X 1 0 p =
      (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (X 0) p +
        a ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p := by
  have hP : HasDerivAt (fun x => a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)
      (2 * (b ^ 2 - a ^ 2) * sin p.1 * cos p.1) p.1 := by
    have := (((hasDerivAt_cos p.1).pow 2).const_mul (a ^ 2)).add
      (((hasDerivAt_sin p.1).pow 2).const_mul (b ^ 2))
    convert this using 1; simp; ring
  have hQ : HasDerivAt (fun x => a ^ 2 * sin x ^ 2) (2 * a ^ 2 * sin p.1 * cos p.1) p.1 := by
    have := ((hasDerivAt_sin p.1).pow 2).const_mul (a ^ 2)
    convert this using 1; simp; ring
  exact kf_lie_diag (fun x => a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) (fun x => a ^ 2 * sin x ^ 2)
    _ _ (flattenedMetric a b) rfl X p hP hQ

lemma kf_flat_pos {a b : ℝ} (hb : 0 < b) (hab : b < a) (x : ℝ) :
    b ^ 2 ≤ a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2 := by
  have h1 : b ^ 2 ≤ a ^ 2 := by nlinarith
  nlinarith [mul_nonneg (sub_nonneg.2 h1) (sq_nonneg (cos x)), sin_sq_add_cos_sq x]

/-- Killing fields of the round globe are exactly the spins: on a globe of radius `R > 0`,
a smooth field `X` in the chart satisfies `ℒ_X g = 0` at every point off the poles if and
only if it is the spin about some axis through the centre, and the turn rate
`ω = (ωx, ωy, ωz)` is then unique, so there are exactly three independent Killing fields. -/
theorem killing_fields_of_round_globe_are_spins (R : ℝ) (hR : 0 < R)
    (X : Fin 2 → ℝ × ℝ → ℝ) (hX : ∀ k, ContDiffOn ℝ ∞ (X k) chartDomain) :
    (∀ p ∈ chartDomain, ∀ i j, lieDerivMetric (roundMetric R) X i j p = 0) ↔
      ∃! w : ℝ × ℝ × ℝ, ∀ p ∈ chartDomain, ∀ k, X k p = spinField w.1 w.2.1 w.2.2 k p := by
  have hR2 : R ^ 2 ≠ 0 := by positivity
  have memD : ∀ x y, x ∈ Ioo 0 π → ((x, y) : ℝ × ℝ) ∈ chartDomain := by
    intro x y hx; simpa [chartDomain] using hx
  constructor
  · intro H
    have E00 : ∀ p ∈ chartDomain, pd 0 (X 0) p = 0 := by
      intro p hp
      have h := H p hp 0 0
      rw [(kf_round_lie R X p).1] at h
      have : R ^ 2 * pd 0 (X 0) p = 0 := by linarith
      exact (mul_eq_zero.1 this).resolve_left hR2
    have E11 : ∀ p ∈ chartDomain, pd 1 (X 1) p = -(cos p.1 / sin p.1) * X 0 p := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 1 1
      rw [(kf_round_lie R X p).2.1] at h
      field_simp
      have : R ^ 2 * sin p.1 * (sin p.1 * pd 1 (X 1) p + cos p.1 * X 0 p) = 0 := by
        linear_combination h / 2
      have := (mul_eq_zero.1 this).resolve_left (mul_ne_zero hR2 hs)
      linear_combination this
    have E01 : ∀ p ∈ chartDomain, pd 0 (X 1) p = -pd 1 (X 0) p / sin p.1 ^ 2 := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 0 1
      rw [(kf_round_lie R X p).2.2.1] at h
      field_simp
      have : R ^ 2 * (pd 1 (X 0) p + sin p.1 ^ 2 * pd 0 (X 1) p) = 0 := by
        linear_combination h
      have := (mul_eq_zero.1 this).resolve_left hR2
      linear_combination this
    -- Step 1: X 0 does not depend on φ
    have hu : ∀ x ∈ Ioo 0 π, ∀ y, X 0 (x, y) = X 0 (π / 2, y) := by
      intro x hx y
      refine kf_const_Ioo (F := fun x => X 0 (x, y)) (fun z hz => ?_) hx kf_pi2_mem
      have := kf_hasDerivAt_pd0 (kf_dAt (hX 0) (memD z y hz))
      rwa [E00 _ (memD z y hz)] at this
    set f : ℝ → ℝ := fun y => X 0 (π / 2, y) with hf_def
    have hf : ContDiff ℝ ∞ f := kf_line_smooth (hX 0) kf_pi2_mem
    obtain ⟨hf1, hf2⟩ := kf_smooth_derivs hf
    have hu' : ∀ x ∈ Ioo 0 π, (fun y => X 0 (x, y)) = f := by
      intro x hx; funext y; exact hu x hx y
    -- Step 2: the θ-rate of X 0 is f'
    have huθ : ∀ x ∈ Ioo 0 π, ∀ y, pd 1 (X 0) (x, y) = deriv f y := by
      intro x hx y
      apply kf_pd1_eq (kf_dAt (hX 0) (memD x y hx))
      show HasDerivAt (fun y => X 0 (x, y)) (deriv f y) y
      rw [hu' x hx]; exact hf1 y
    -- Step 3: the form of X 1
    have hv : ∀ x ∈ Ioo 0 π, ∀ y, X 1 (x, y) = deriv f y * (cos x / sin x) + X 1 (π / 2, y) := by
      intro x hx y
      have key := kf_const_Ioo (F := fun x => X 1 (x, y) - deriv f y * (cos x / sin x))
        (fun z hz => ?_) hx kf_pi2_mem
      · simp only [cos_pi_div_two, zero_div, mul_zero, sub_zero] at key
        linarith
      · have hs : sin z ≠ 0 := (sin_pos_of_pos_of_lt_pi hz.1 hz.2).ne'
        have h1 := kf_hasDerivAt_pd0 (kf_dAt (hX 1) (memD z y hz))
        rw [E01 _ (memD z y hz), huθ z hz y] at h1
        have h2 := h1.sub ((kf_cot_deriv hs).const_mul (deriv f y))
        convert h2 using 1
        simp only
        field_simp
        ring
    set h : ℝ → ℝ := fun y => X 1 (π / 2, y) with hh_def
    have hh : ContDiff ℝ ∞ h := kf_line_smooth (hX 1) kf_pi2_mem
    obtain ⟨hh1, -⟩ := kf_smooth_derivs hh
    -- Step 4: the θ-equation
    have hθ : ∀ x ∈ Ioo 0 π, ∀ y,
        deriv (deriv f) y * (cos x / sin x) + deriv h y = -(cos x / sin x) * f y := by
      intro x hx y
      have e1 := E11 _ (memD x y hx)
      have e2 : pd 1 (X 1) (x, y) = deriv (deriv f) y * (cos x / sin x) + deriv h y := by
        apply kf_pd1_eq (kf_dAt (hX 1) (memD x y hx))
        show HasDerivAt (fun y => X 1 (x, y)) _ y
        have : (fun y => X 1 (x, y)) = fun y => deriv f y * (cos x / sin x) + h y := by
          funext y; exact hv x hx y
        rw [this]
        exact ((hf2 y).mul_const _).add (hh1 y)
      rw [e2, hu x hx y] at e1
      exact e1
    have hh' : ∀ y, deriv h y = 0 := by
      intro y
      have := hθ _ kf_pi2_mem y
      simpa using this
    have hff : ∀ y, deriv (deriv f) y = -f y := by
      intro y
      have := hθ _ kf_pi4_mem y
      rw [hh' y, cos_pi_div_four, sin_pi_div_four, div_self (by positivity)] at this
      linarith
    have hconst : ∀ y, h y = h 0 := fun y =>
      is_const_of_deriv_eq_zero (hh.differentiable (by simp)) hh' y 0
    -- Step 5: f solves f'' = -f
    set A := f 0
    set B := deriv f 0
    have hsol : ∀ y, f y = A * cos y + B * sin y ∧ deriv f y = -A * sin y + B * cos y := by
      let E : ℝ → ℝ := fun y => (f y - (A * cos y + B * sin y)) ^ 2 +
        (deriv f y - (-A * sin y + B * cos y)) ^ 2
      have hE : ∀ y, HasDerivAt E 0 y := by
        intro y
        have d1 := (hf1 y).sub (((hasDerivAt_cos y).const_mul A).add ((hasDerivAt_sin y).const_mul B))
        have d2 := (hf2 y).sub (((hasDerivAt_sin y).const_mul (-A)).add
          ((hasDerivAt_cos y).const_mul B))
        have := (d1.pow 2).add (d2.pow 2)
        convert this using 1
        rw [hff y]; simp; ring
      intro y
      have : E y = E 0 := is_const_of_deriv_eq_zero (fun z => (hE z).differentiableAt)
        (fun z => (hE z).deriv) y 0
      have h0 : E 0 = 0 := by simp [E, A, B]
      rw [h0] at this
      simp only [E] at this
      constructor
      · nlinarith [sq_nonneg (f y - (A * cos y + B * sin y)),
          sq_nonneg (deriv f y - (-A * sin y + B * cos y))]
      · nlinarith [sq_nonneg (f y - (A * cos y + B * sin y)),
          sq_nonneg (deriv f y - (-A * sin y + B * cos y))]
    -- Step 6: the turn rate
    have hspin : ∀ p ∈ chartDomain, ∀ k, X k p = spinField (-B) A (h 0) k p := by
      rintro ⟨x, y⟩ hp k
      have hx : x ∈ Ioo 0 π := by simpa [chartDomain] using hp
      fin_cases k
      · simp only [Fin.zero_eta, kf_spin0]
        rw [hu x hx y]
        show f y = _
        rw [(hsol y).1]; ring
      · simp only [Fin.mk_one, kf_spin1]
        rw [hv x hx y]
        show deriv f y * (cos x / sin x) + h y = _
        rw [(hsol y).2, hconst y]; ring
    refine ⟨(-B, A, h 0), hspin, fun w' hw' => ?_⟩
    exact kf_spin_unique (fun p hp k => by rw [← hw' p hp k, hspin p hp k])
  · rintro ⟨w, hw, -⟩ p hp i j
    have hs := kf_sin_ne hp
    have hval : ∀ k, X k p = spinField w.1 w.2.1 w.2.2 k p := hw p hp
    have hpd : ∀ i k, pd i (X k) p = pd i (spinField w.1 w.2.1 w.2.2 k) p :=
      fun i k => kf_pd_congr_dom i hp (fun q hq => hw q hq k)
    obtain ⟨l00, l11, l01, l10⟩ := kf_round_lie R X p
    obtain ⟨a1, a2, a3, a4⟩ := kf_spin_pd w.1 w.2.1 w.2.2 hs
    fin_cases i <;> fin_cases j
    · simp only [Fin.zero_eta, l00, hpd, a1]; ring
    · simp only [Fin.zero_eta, Fin.mk_one, l01, hpd, a2, a3]
      field_simp; ring
    · simp only [Fin.zero_eta, Fin.mk_one, l10, hpd, a2, a3]
      field_simp; ring
    · simp only [Fin.mk_one, l11, hpd, hval, a4]
      simp only [kf_spin0]
      field_simp; ring

/-- The flattened Earth keeps only the polar spin: when the equatorial radius `a` exceeds
the polar radius `b > 0`, a smooth field `X` in the chart satisfies `ℒ_X g = 0` at every
point off the poles if and only if it is a constant spin about the polar axis,
`X = (0, c)`, for exactly one rate `c`. -/
theorem killing_fields_of_flattened_earth_are_polar_spins (a b : ℝ) (hb : 0 < b) (hab : b < a)
    (X : Fin 2 → ℝ × ℝ → ℝ) (hX : ∀ k, ContDiffOn ℝ ∞ (X k) chartDomain) :
    (∀ p ∈ chartDomain, ∀ i j, lieDerivMetric (flattenedMetric a b) X i j p = 0) ↔
      ∃! c : ℝ, ∀ p ∈ chartDomain, X 0 p = 0 ∧ X 1 p = c := by
  have ha : 0 < a := hb.trans hab
  have ha2 : a ^ 2 ≠ 0 := by positivity
  have memD : ∀ x y, x ∈ Ioo 0 π → ((x, y) : ℝ × ℝ) ∈ chartDomain := by
    intro x y hx; simpa [chartDomain] using hx
  have Ppos : ∀ x, 0 < a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2 := fun x =>
    lt_of_lt_of_le (by positivity) (kf_flat_pos hb hab x)
  constructor
  · intro H
    have E00 : ∀ p ∈ chartDomain, pd 0 (X 0) p =
        -(2 * (b ^ 2 - a ^ 2) * sin p.1 * cos p.1) * X 0 p /
          (2 * (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2)) := by
      intro p hp
      have h := H p hp 0 0
      rw [(kf_flat_lie a b X p).1] at h
      have := Ppos p.1
      field_simp
      linear_combination h / 2
    have E11 : ∀ p ∈ chartDomain, pd 1 (X 1) p = -(cos p.1 / sin p.1) * X 0 p := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 1 1
      rw [(kf_flat_lie a b X p).2.1] at h
      field_simp
      have : a ^ 2 * sin p.1 * (sin p.1 * pd 1 (X 1) p + cos p.1 * X 0 p) = 0 := by
        linear_combination h / 2
      have := (mul_eq_zero.1 this).resolve_left (mul_ne_zero ha2 hs)
      linear_combination this
    have E01 : ∀ p ∈ chartDomain, pd 0 (X 1) p =
        -(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (X 0) p / (a ^ 2 * sin p.1 ^ 2) := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 0 1
      rw [(kf_flat_lie a b X p).2.2.1] at h
      field_simp
      linear_combination h
    -- the mixed second partials of X 1 agree
    have hstar : ∀ p ∈ chartDomain,
        X 0 p / sin p.1 ^ 2 - (cos p.1 / sin p.1) * pd 0 (X 0) p =
          -(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (pd 1 (X 0)) p /
            (a ^ 2 * sin p.1 ^ 2) := by
      intro p hp
      have hs := kf_sin_ne hp
      have hsym := kf_pd_symm (kf_cdAt (hX 1) hp)
      have L : pd 0 (pd 1 (X 1)) p =
          X 0 p / sin p.1 ^ 2 - (cos p.1 / sin p.1) * pd 0 (X 0) p := by
        rw [kf_pd_congr_dom 0 hp (g := fun q => -(cos q.1 / sin q.1) * X 0 q) E11]
        have du := kf_dAt (hX 0) hp
        have dd : DifferentiableAt ℝ (fun q : ℝ × ℝ => -(cos q.1 / sin q.1) * X 0 q) p := by
          fun_prop (disch := exact hs)
        apply kf_pd0_eq dd
        have : HasDerivAt (fun x => -(cos x / sin x) * X 0 (x, p.2))
            (-(-1 / sin p.1 ^ 2) * X 0 p + -(cos p.1 / sin p.1) * pd 0 (X 0) p) p.1 :=
          ((kf_cot_deriv hs).neg).mul (kf_hasDerivAt_pd0 du)
        convert this using 1
        field_simp
        ring
      have Rr : pd 1 (pd 0 (X 1)) p =
          -(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (pd 1 (X 0)) p /
            (a ^ 2 * sin p.1 ^ 2) := by
        rw [kf_pd_congr_dom 1 hp (g := fun q => -(a ^ 2 * cos q.1 ^ 2 + b ^ 2 * sin q.1 ^ 2) *
          pd 1 (X 0) q / (a ^ 2 * sin q.1 ^ 2)) E01]
        have d2 := kf_pd_differentiableAt 1 (kf_cdAt (hX 0) hp)
        have dd : DifferentiableAt ℝ (fun q : ℝ × ℝ => -(a ^ 2 * cos q.1 ^ 2 + b ^ 2 * sin q.1 ^ 2) *
            pd 1 (X 0) q / (a ^ 2 * sin q.1 ^ 2)) p := by
          fun_prop (disch := exact mul_ne_zero ha2 (pow_ne_zero 2 hs))
        apply kf_pd1_eq dd
        exact ((kf_hasDerivAt_pd1 d2).const_mul (-(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2))).div_const
          (a ^ 2 * sin p.1 ^ 2)
      rw [← L, ← Rr]; exact hsym
    -- √P · X 0 does not change along φ
    have hroot : ∀ x ∈ Ioo 0 π, ∀ y,
        √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * X 0 (x, y) = b * X 0 (π / 2, y) := by
      intro x hx y
      have key := kf_const_Ioo
        (F := fun x => √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * X 0 (x, y))
        (fun z hz => ?_) hx kf_pi2_mem
      · rw [key]
        simp [cos_pi_div_two, sin_pi_div_two, Real.sqrt_sq hb.le]
      · have hsq := (kf_flat_P_deriv a b z).sqrt (Ppos z).ne'
        have h1 := kf_hasDerivAt_pd0 (kf_dAt (hX 0) (memD z y hz))
        rw [E00 _ (memD z y hz)] at h1
        have := hsq.mul h1
        convert this using 1
        simp only
        have hr2 := Real.sq_sqrt (Ppos z).le
        have hrpos := Real.sqrt_pos.2 (Ppos z)
        set r := √(a ^ 2 * cos z ^ 2 + b ^ 2 * sin z ^ 2) with hr
        rw [← hr2]
        field_simp
        ring
    set g : ℝ → ℝ := fun y => X 0 (π / 2, y) with hg_def
    have hg : ContDiff ℝ ∞ g := kf_line_smooth (hX 0) kf_pi2_mem
    obtain ⟨hg1, hg2⟩ := kf_smooth_derivs hg
    have hform : ∀ x ∈ Ioo 0 π, (fun y => X 0 (x, y)) =
        fun y => b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * g y := by
      intro x hx; funext y
      have h := hroot x hx y
      have hpos := Real.sqrt_pos.2 (Ppos x)
      field_simp
      linear_combination h
    have hval : ∀ x ∈ Ioo 0 π, ∀ y,
        X 0 (x, y) = b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * g y :=
      fun x hx y => congrFun (hform x hx) y
    have hθθ : ∀ x ∈ Ioo 0 π, ∀ y, pd 1 (pd 1 (X 0)) (x, y) =
        b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv (deriv g) y := by
      intro x hx y
      have hθ : (fun y => pd 1 (X 0) (x, y)) =
          fun y => b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv g y := by
        funext y
        apply kf_pd1_eq (kf_dAt (hX 0) (memD x y hx))
        show HasDerivAt (fun y => X 0 (x, y)) _ y
        rw [hform x hx]
        exact (hg1 y).const_mul _
      apply kf_pd1_eq (kf_pd_differentiableAt 1 (kf_cdAt (hX 0) (memD x y hx)))
      show HasDerivAt (fun y => pd 1 (X 0) (x, y)) _ y
      rw [hθ]
      exact (hg2 y).const_mul _
    have heq : ∀ x ∈ Ioo 0 π, ∀ y,
        g y / sin x ^ 2 + (cos x / sin x) * (2 * (b ^ 2 - a ^ 2) * sin x * cos x) * g y /
          (2 * (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)) +
          (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv (deriv g) y / (a ^ 2 * sin x ^ 2) = 0 := by
      intro x hx y
      have h := hstar (x, y) (memD x y hx)
      have e0 := E00 (x, y) (memD x y hx)
      simp only at h e0
      rw [e0, hθθ x hx y, hval x hx y] at h
      have hc : b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) ≠ 0 := by
        have := Real.sqrt_pos.2 (Ppos x); positivity
      have : b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) *
          (g y / sin x ^ 2 + (cos x / sin x) * (2 * (b ^ 2 - a ^ 2) * sin x * cos x) * g y /
          (2 * (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)) +
          (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv (deriv g) y / (a ^ 2 * sin x ^ 2)) = 0 := by
        linear_combination h
      exact (mul_eq_zero.1 this).resolve_left hc
    have hg0 : ∀ y, g y = 0 := by
      intro y
      have e1 := heq _ kf_pi2_mem y
      have e2 := heq _ kf_pi4_mem y
      simp [sin_pi_div_two, cos_pi_div_two] at e1
      rw [cos_pi_div_four, sin_pi_div_four] at e2
      have h2 : √2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
      have hgg : deriv (deriv g) y = -(a ^ 2 * g y) / b ^ 2 := by
        field_simp
        field_simp at e1
        linear_combination e1
      rw [hgg] at e2
      field_simp at e2
      rw [h2] at e2
      have hab2 : 0 < a ^ 2 - b ^ 2 := by nlinarith
      have hk : (a ^ 2 - b ^ 2) * (a ^ 2 + 2 * b ^ 2) ≠ 0 := by positivity
      have : g y * ((a ^ 2 - b ^ 2) * (a ^ 2 + 2 * b ^ 2)) = 0 := by
        linear_combination (-1 / 2 : ℝ) * e2
      exact (mul_eq_zero.1 this).resolve_right hk
    have hu0 : ∀ p ∈ chartDomain, X 0 p = 0 := by
      rintro ⟨x, y⟩ hp
      have hx : x ∈ Ioo 0 π := by simpa [chartDomain] using hp
      rw [hval x hx y, hg0 y, mul_zero]
    have hv1 : ∀ p ∈ chartDomain, pd 1 (X 1) p = 0 := by
      intro p hp; rw [E11 p hp, hu0 p hp, mul_zero]
    have hv0 : ∀ p ∈ chartDomain, pd 0 (X 1) p = 0 := by
      intro p hp
      have : pd 1 (X 0) p = 0 := by
        rw [kf_pd_congr_dom 1 hp (g := fun _ => 0) hu0]; simp [pd]
      rw [E01 p hp, this]; simp
    have hvc : ∀ p ∈ chartDomain, X 1 p = X 1 (π / 2, 0) := by
      rintro ⟨x, y⟩ hp
      have hx : x ∈ Ioo 0 π := by simpa [chartDomain] using hp
      have s1 : X 1 (x, y) = X 1 (x, 0) :=
        is_const_of_deriv_eq_zero ((kf_line_smooth (hX 1) hx).differentiable (by simp))
          (fun z => by
            rw [(kf_hasDerivAt_pd1 (kf_dAt (hX 1) (memD x z hx))).deriv]
            exact hv1 _ (memD x z hx)) y 0
      have s2 : X 1 (x, 0) = X 1 (π / 2, 0) :=
        kf_const_Ioo (F := fun x => X 1 (x, 0)) (fun z hz => by
          have := kf_hasDerivAt_pd0 (kf_dAt (hX 1) (memD z 0 hz))
          rwa [hv0 _ (memD z 0 hz)] at this) hx kf_pi2_mem
      rw [s1, s2]
    refine ⟨X 1 (π / 2, 0), fun p hp => ⟨hu0 p hp, hvc p hp⟩, fun c' hc' => ?_⟩
    exact ((hc' _ (memD _ 0 kf_pi2_mem)).2).symm
  · rintro ⟨c, hc, -⟩ p hp i j
    have h0 : ∀ i, pd i (X 0) p = 0 := fun i => by
      rw [kf_pd_congr_dom i hp (g := fun _ => 0) (fun q hq => (hc q hq).1)]; simp [pd]
    have h1 : ∀ i, pd i (X 1) p = 0 := fun i => by
      rw [kf_pd_congr_dom i hp (g := fun _ => c) (fun q hq => (hc q hq).2)]; simp [pd]
    obtain ⟨l00, l11, l01, l10⟩ := kf_flat_lie a b X p
    fin_cases i <;> fin_cases j <;> simp [l00, l11, l01, l10, h0, h1, (hc p hp).1]

/-- The three spins form the rotation group's Lie algebra with the sign flipped:
the bracket of the spin about `x` and the spin about `y` is minus the spin about `z`,
at every point off the poles. -/
theorem bracket_spin_x_spin_y_eq_neg_spin_z :
    ∀ p ∈ chartDomain, ∀ k,
      lieBracketChart (spinField 1 0 0) (spinField 0 1 0) k p = - spinField 0 0 1 k p := by
  intro p hp k
  rw [kf_mem_chartDomain] at hp
  have hs : sin p.1 ≠ 0 := (sin_pos_of_pos_of_lt_pi hp.1 hp.2).ne'
  obtain ⟨a1, a2, a3, a4⟩ := kf_spin_pd 1 0 0 hs
  obtain ⟨b1, b2, b3, b4⟩ := kf_spin_pd 0 1 0 hs
  fin_cases k
  · simp only [lieBracketChart, Fin.sum_univ_two, Fin.zero_eta, a1, a2, b1, b2]
    simp [spinField]; ring
  · simp only [lieBracketChart, Fin.sum_univ_two, Fin.mk_one, a3, a4, b3, b4]
    simp [spinField]
    field_simp
    linear_combination (cos p.1 ^ 2 - 1) * sin_sq_add_cos_sq p.2 + sin_sq_add_cos_sq p.1

/-! Worked examples from the card, checked exactly. -/

-- The most Killing fields a connected surface can have: n(n+1)/2 with n = 2 is 3.
example : 2 * (2 + 1) / 2 = 3 := by decide

-- The polar spin is the spin with ω = (0, 0, 1): its components are (0, 1) everywhere.
example (p : ℝ × ℝ) : spinField 0 0 1 0 p = 0 ∧ spinField 0 0 1 1 p = 1 := by
  simp [spinField]

#print axioms killing_fields_of_round_globe_are_spins
#print axioms killing_fields_of_flattened_earth_are_polar_spins
#print axioms bracket_spin_x_spin_y_eq_neg_spin_z
#print axioms kf_isOpen_chartDomain
#print axioms kf_mem_chartDomain
#print axioms kf_hasDerivAt_pd0
#print axioms kf_hasDerivAt_pd1
#print axioms kf_pd0_eq
#print axioms kf_pd1_eq
#print axioms kf_pd_congr
#print axioms kf_pd_congr_dom
#print axioms kf_pd_symm
#print axioms kf_pd_differentiableAt
#print axioms kf_pd_fst
#print axioms kf_lie_diag
#print axioms kf_spin0
#print axioms kf_spin1
#print axioms kf_spin_pd
#print axioms kf_const_Ioo
#print axioms kf_pi2_mem
#print axioms kf_pi4_mem
#print axioms kf_line_smooth
#print axioms kf_smooth_derivs
#print axioms kf_cdAt
#print axioms kf_dAt
#print axioms kf_cot_deriv
#print axioms kf_sin_ne
#print axioms kf_spin_unique
#print axioms kf_round_lie
#print axioms kf_flat_P_deriv
#print axioms kf_flat_lie
#print axioms kf_flat_pos
