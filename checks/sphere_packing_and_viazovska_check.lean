-- Sphere packing, solved in dimensions 8 and 24: a function that is never positive beyond the closest spacing r, has a transform never negative, and agrees with its transform at 0 caps the density of every packing of balls of radius r/2 at one such ball's volume, lattice or not, and in dimension 8 with r = √2 that cap is π^4/384.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Algebra.Module.ZLattice.Covolume
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.Order.LiminfLimsup
import Mathlib.Analysis.Fourier.Inversion

open MeasureTheory Metric Filter Real ArithmeticFunction
open scoped FourierTransform ComplexOrder

/-! Space is `EuclideanSpace ℝ (Fin d)`: lists of `d` real numbers with the usual distance.
The Fourier transform `𝓕` is Mathlib's, `𝓕 f (y) = ∫ f(x) e^(−2πi x·y) dx`, the convention of
Cohn and Elkies. A test function `f` is real-valued; its transform is taken of `x ↦ (f x : ℂ)`.
"Fades faster than |x|^(−d)" is read, as in Cohn and Elkies (2003), as: for some `C` and some
`δ > 0`, both `|f(x)|` and `|𝓕 f(x)|` are at most `C (1 + |x|)^(−d−δ)`. The card's functions are
continuous, so `f` is assumed continuous: without it, changing `f` at the single point 0 would
make the hypothesis `f(0) = 𝓕 f(0)` say nothing. A packing of balls of radius `r/2` is a set of
centres any two of which are at least `r` apart, and its density is the limit superior, as `R`
grows, of the share of the ball of radius `R` about 0 that the balls cover. -/

open scoped RealInnerProductSpace ComplexConjugate Topology Pointwise

/-- The plane wave `e^(2πi⟨ξ, x⟩)`. -/
noncomputable def ceWave {d : ℕ} (ξ x : EuclideanSpace ℝ (Fin d)) : ℂ :=
  Complex.exp (↑(2 * π * ⟪ξ, x⟫) * Complex.I)

lemma ceWave_norm {d : ℕ} (ξ x : EuclideanSpace ℝ (Fin d)) : ‖ceWave ξ x‖ = 1 :=
  Complex.norm_exp_ofReal_mul_I _

lemma ceWave_continuous (d : ℕ) :
    Continuous (fun p : EuclideanSpace ℝ (Fin d) × EuclideanSpace ℝ (Fin d) => ceWave p.1 p.2) := by
  unfold ceWave; fun_prop

lemma ceWave_continuous_right {d : ℕ} (ξ : EuclideanSpace ℝ (Fin d)) : Continuous (ceWave ξ) := by
  unfold ceWave; fun_prop

lemma ceWave_continuous_left {d : ℕ} (x : EuclideanSpace ℝ (Fin d)) :
    Continuous (fun ξ => ceWave ξ x) := by
  unfold ceWave; fun_prop

lemma ceWave_mul_conj {d : ℕ} (ξ x y : EuclideanSpace ℝ (Fin d)) :
    ceWave ξ x * conj (ceWave ξ y) = ceWave ξ (x - y) := by
  unfold ceWave
  rw [← Complex.exp_conj, ← Complex.exp_add]
  congr 1
  simp only [map_mul, Complex.conj_ofReal, Complex.conj_I, inner_sub_right]
  push_cast; ring

lemma ce_fourier_continuous {d : ℕ} (F : EuclideanSpace ℝ (Fin d) → ℂ) (hF : Integrable F) :
    Continuous (𝓕 F) :=
  VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar
    (by exact continuous_inner) hF

lemma ce_inversion {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hcont : Continuous f)
    (hf : Integrable f) (hφ : Integrable (𝓕 (fun z => (f z : ℂ)))) (z : EuclideanSpace ℝ (Fin d)) :
    ∫ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ceWave ξ z = (f z : ℂ) := by
  have hc : Continuous (fun z => (f z : ℂ)) := by fun_prop
  have h := congrFun (hc.fourierInv_fourier_eq hf.ofReal hφ) z
  rw [Real.fourierInv_eq'] at h
  simpa [ceWave, mul_comm] using h

lemma ce_swap {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hcont : Continuous f)
    (hf : Integrable f) (hφ : Integrable (𝓕 (fun z => (f z : ℂ))))
    (ν : Measure (EuclideanSpace ℝ (Fin d))) [IsFiniteMeasure ν] :
    ∫ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ∫ y, ceWave ξ y ∂ν = ∫ y, (f y : ℂ) ∂ν := by
  set φ := 𝓕 (fun z => (f z : ℂ))
  have hφc : Continuous φ := ce_fourier_continuous _ hf.ofReal
  have hint : Integrable (Function.uncurry fun ξ y => φ ξ * ceWave ξ y) (volume.prod ν) := by
    refine Integrable.mono' (hφ.norm.mul_prod (integrable_const (1 : ℝ))) ?_ ?_
    · exact ((hφc.comp continuous_fst).mul (ceWave_continuous d)).aestronglyMeasurable
    · exact ae_of_all _ fun p => by
        obtain ⟨a, b⟩ := p
        simp [ceWave_norm]
  calc ∫ ξ, φ ξ * ∫ y, ceWave ξ y ∂ν = ∫ ξ, ∫ y, φ ξ * ceWave ξ y ∂ν := by
        congr 1; ext ξ; rw [integral_const_mul]
    _ = ∫ y, (∫ ξ, φ ξ * ceWave ξ y) ∂ν := integral_integral_swap hint
    _ = ∫ y, (f y : ℂ) ∂ν := by
        congr 1; ext y; exact ce_inversion f hcont hf hφ y

lemma ce_swap_int {d : ℕ} (φ : EuclideanSpace ℝ (Fin d) → ℂ) (hφc : Continuous φ)
    (hφ : Integrable φ) (ν : Measure (EuclideanSpace ℝ (Fin d))) [IsFiniteMeasure ν] :
    Integrable (fun ξ => φ ξ * ∫ y, ceWave ξ y ∂ν) := by
  have hint : Integrable (Function.uncurry fun ξ y => φ ξ * ceWave ξ y) (volume.prod ν) := by
    refine Integrable.mono' (hφ.norm.mul_prod (integrable_const (1 : ℝ))) ?_ ?_
    · exact ((hφc.comp continuous_fst).mul (ceWave_continuous d)).aestronglyMeasurable
    · exact ae_of_all _ fun p => by
        obtain ⟨a, b⟩ := p
        simp [ceWave_norm]
  refine hint.integral_prod_left.congr (ae_of_all _ fun ξ => ?_)
  simp only [Function.uncurry_apply_pair]
  rw [integral_const_mul]

lemma ce_I1 {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hcont : Continuous f)
    (hf : Integrable f) (hφ : Integrable (𝓕 (fun z => (f z : ℂ))))
    (S : Finset (EuclideanSpace ℝ (Fin d))) :
    ∫ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ((∑ x ∈ S, ceWave ξ x) * conj (∑ x ∈ S, ceWave ξ x)) =
      ((∑ x ∈ S, ∑ y ∈ S, f (x - y) : ℝ) : ℂ) := by
  have hwave : ∀ z, Integrable (fun ξ => 𝓕 (fun z => (f z : ℂ)) ξ * ceWave ξ z) := fun z =>
    hφ.mul_bdd (ceWave_continuous_left z).aestronglyMeasurable
      (ae_of_all _ fun ξ => (ceWave_norm ξ z).le)
  have h : ∀ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ((∑ x ∈ S, ceWave ξ x) * conj (∑ x ∈ S, ceWave ξ x))
      = ∑ x ∈ S, ∑ y ∈ S, 𝓕 (fun z => (f z : ℂ)) ξ * ceWave ξ (x - y) := by
    intro ξ
    rw [map_sum, Finset.sum_mul_sum, Finset.mul_sum]
    refine Finset.sum_congr rfl fun x _ => ?_
    rw [Finset.mul_sum]
    exact Finset.sum_congr rfl fun y _ => by rw [ceWave_mul_conj]
  rw [integral_congr_ae (ae_of_all _ h),
    integral_finsetSum _ fun x _ => integrable_finsetSum _ fun y _ => hwave _]
  push_cast
  refine Finset.sum_congr rfl fun x _ => ?_
  rw [integral_finsetSum _ fun y _ => hwave _]
  exact Finset.sum_congr rfl fun y _ => ce_inversion f hcont hf hφ _

lemma ce_I2 {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hcont : Continuous f)
    (hf : Integrable f) (hφ : Integrable (𝓕 (fun z => (f z : ℂ))))
    (S : Finset (EuclideanSpace ℝ (Fin d))) (μ : Measure (EuclideanSpace ℝ (Fin d)))
    [IsFiniteMeasure μ] :
    ∫ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ((∑ x ∈ S, ceWave ξ x) * conj (∫ y, ceWave ξ y ∂μ)) =
      ((∑ x ∈ S, ∫ y, f (x - y) ∂μ : ℝ) : ℂ) := by
  have hφc : Continuous (𝓕 (fun z => (f z : ℂ))) := ce_fourier_continuous _ hf.ofReal
  have h : ∀ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ((∑ x ∈ S, ceWave ξ x) * conj (∫ y, ceWave ξ y ∂μ))
      = ∑ x ∈ S, 𝓕 (fun z => (f z : ℂ)) ξ * ∫ z, ceWave ξ z ∂(μ.map (fun y => x - y)) := by
    intro ξ
    rw [Finset.sum_mul, Finset.mul_sum]
    refine Finset.sum_congr rfl fun x _ => ?_
    have hm : ∫ z, ceWave ξ z ∂(μ.map (fun y => x - y)) = ∫ y, ceWave ξ (x - y) ∂μ :=
      integral_map (measurable_const.sub measurable_id).aemeasurable
        (ceWave_continuous_right ξ).aestronglyMeasurable
    rw [hm, ← integral_conj, ← integral_const_mul]
    simp only [ceWave_mul_conj]
  rw [integral_congr_ae (ae_of_all _ h),
    integral_finsetSum _ fun x _ => ce_swap_int _ hφc hφ _]
  push_cast
  refine Finset.sum_congr rfl fun x _ => ?_
  have hm : ∫ z, (f z : ℂ) ∂(μ.map (fun y => x - y)) = ∫ y, (f (x - y) : ℂ) ∂μ :=
    integral_map (measurable_const.sub measurable_id).aemeasurable
      (by fun_prop : Continuous fun z => (f z : ℂ)).aestronglyMeasurable
  rw [ce_swap f hcont hf hφ, hm, integral_complex_ofReal]

lemma ce_I4 {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hcont : Continuous f)
    (hf : Integrable f) (hφ : Integrable (𝓕 (fun z => (f z : ℂ))))
    (μ : Measure (EuclideanSpace ℝ (Fin d))) [IsFiniteMeasure μ] :
    ∫ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ((∫ y, ceWave ξ y ∂μ) * conj (∫ y, ceWave ξ y ∂μ)) =
      ((∫ p, f (p.1 - p.2) ∂(μ.prod μ) : ℝ) : ℂ) := by
  have h : ∀ ξ, 𝓕 (fun z => (f z : ℂ)) ξ * ((∫ y, ceWave ξ y ∂μ) * conj (∫ y, ceWave ξ y ∂μ))
      = 𝓕 (fun z => (f z : ℂ)) ξ * ∫ z, ceWave ξ z ∂((μ.prod μ).map (fun p => p.1 - p.2)) := by
    intro ξ
    have hm : ∫ z, ceWave ξ z ∂((μ.prod μ).map (fun p => p.1 - p.2)) =
        ∫ p, ceWave ξ (p.1 - p.2) ∂(μ.prod μ) :=
      integral_map (measurable_fst.sub measurable_snd).aemeasurable
        (ceWave_continuous_right ξ).aestronglyMeasurable
    rw [hm, ← integral_conj, ← integral_prod_mul]
    simp only [ceWave_mul_conj]
  have hm : ∫ z, (f z : ℂ) ∂((μ.prod μ).map (fun p => p.1 - p.2)) =
      ∫ p, (f (p.1 - p.2) : ℂ) ∂(μ.prod μ) :=
    integral_map (measurable_fst.sub measurable_snd).aemeasurable
      (by fun_prop : Continuous fun z => (f z : ℂ)).aestronglyMeasurable
  rw [integral_congr_ae (ae_of_all _ h), ce_swap f hcont hf hφ, hm, integral_complex_ofReal]

lemma ce_posdef_core {d : ℕ} (φ : EuclideanSpace ℝ (Fin d) → ℂ) (hφ : Integrable φ)
    (hpos : ∀ ξ, 0 ≤ φ ξ) (P G : EuclideanSpace ℝ (Fin d) → ℂ) (hP : Continuous P)
    (hG : Continuous G) (KP KG : ℝ) (hKP : ∀ ξ, ‖P ξ‖ ≤ KP) (hKG : ∀ ξ, ‖G ξ‖ ≤ KG)
    (A B D c : ℝ) (I1 : ∫ ξ, φ ξ * (P ξ * conj (P ξ)) = (A : ℂ))
    (I2 : ∫ ξ, φ ξ * (P ξ * conj (G ξ)) = (B : ℂ))
    (I4 : ∫ ξ, φ ξ * (G ξ * conj (G ξ)) = (D : ℂ)) :
    0 ≤ A - 2 * c * B + c ^ 2 * D := by
  have hreal : ∀ ξ, φ ξ = ((φ ξ).re : ℂ) := fun ξ => by
    apply Complex.ext <;> simp [(Complex.nonneg_iff.1 (hpos ξ)).2.symm]
  have hprod : ∀ X Y : EuclideanSpace ℝ (Fin d) → ℂ, Continuous X → Continuous Y →
      ∀ KX KY : ℝ, (∀ ξ, ‖X ξ‖ ≤ KX) → (∀ ξ, ‖Y ξ‖ ≤ KY) →
      Integrable (fun ξ => φ ξ * (X ξ * conj (Y ξ))) := by
    intro X Y hX hY KX KY hKX hKY
    refine hφ.mul_bdd (hX.mul (Complex.continuous_conj.comp hY)).aestronglyMeasurable
      (ae_of_all _ fun ξ => ?_) (c := KX * KY)
    rw [norm_mul, Complex.norm_conj]
    exact mul_le_mul (hKX ξ) (hKY ξ) (norm_nonneg _) ((norm_nonneg _).trans (hKX ξ))
  have I3 : ∫ ξ, φ ξ * (G ξ * conj (P ξ)) = (B : ℂ) := by
    have h : ∀ ξ, φ ξ * (G ξ * conj (P ξ)) = conj (φ ξ * (P ξ * conj (G ξ))) := by
      intro ξ
      rw [hreal ξ]
      simp only [map_mul, Complex.conj_ofReal, Complex.conj_conj]
      ring
    rw [integral_congr_ae (ae_of_all _ h), integral_conj, I2, Complex.conj_ofReal]
  have i1 := hprod P P hP hP _ _ hKP hKP
  have i2 := hprod P G hP hG _ _ hKP hKG
  have i3 := hprod G P hG hP _ _ hKG hKP
  have i4 := hprod G G hG hG _ _ hKG hKG
  have hsplit : ∀ ξ, φ ξ * ((P ξ - (c : ℂ) * G ξ) * conj (P ξ - (c : ℂ) * G ξ)) =
      φ ξ * (P ξ * conj (P ξ)) - (c : ℂ) * (φ ξ * (P ξ * conj (G ξ)))
      - (c : ℂ) * (φ ξ * (G ξ * conj (P ξ))) + (c : ℂ) ^ 2 * (φ ξ * (G ξ * conj (G ξ))) := by
    intro ξ
    simp only [map_sub, map_mul, Complex.conj_ofReal]
    ring
  have key : ∫ ξ, φ ξ * ((P ξ - (c : ℂ) * G ξ) * conj (P ξ - (c : ℂ) * G ξ)) =
      ((A - 2 * c * B + c ^ 2 * D : ℝ) : ℂ) := by
    rw [integral_congr_ae (ae_of_all _ hsplit),
      integral_add (by exact (i1.sub (i2.const_mul _)).sub (i3.const_mul _))
        (by exact i4.const_mul _),
      integral_sub (by exact i1.sub (i2.const_mul _)) (by exact i3.const_mul _),
      integral_sub i1 (by exact i2.const_mul _), integral_const_mul, integral_const_mul,
      integral_const_mul, I1, I2, I3, I4]
    push_cast
    ring
  have hnn : ∫ ξ, φ ξ * ((P ξ - (c : ℂ) * G ξ) * conj (P ξ - (c : ℂ) * G ξ)) =
      ((∫ ξ, (φ ξ).re * Complex.normSq (P ξ - (c : ℂ) * G ξ) : ℝ) : ℂ) := by
    rw [← integral_complex_ofReal]
    refine integral_congr_ae (ae_of_all _ fun ξ => ?_)
    simp only
    rw [Complex.mul_conj, hreal ξ]
    push_cast
    simp
  rw [key] at hnn
  rw [Complex.ofReal_inj.1 hnn]
  exact integral_nonneg fun ξ =>
    mul_nonneg (Complex.nonneg_iff.1 (hpos ξ)).1 (Complex.normSq_nonneg _)

lemma ce_posdef {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hcont : Continuous f)
    (hf : Integrable f) (hφ : Integrable (𝓕 (fun z => (f z : ℂ))))
    (hfour : ∀ y, 0 ≤ 𝓕 (fun z => (f z : ℂ)) y)
    (S : Finset (EuclideanSpace ℝ (Fin d))) (μ : Measure (EuclideanSpace ℝ (Fin d)))
    [IsFiniteMeasure μ] (c : ℝ) :
    0 ≤ (∑ x ∈ S, ∑ y ∈ S, f (x - y)) - 2 * c * (∑ x ∈ S, ∫ y, f (x - y) ∂μ)
      + c ^ 2 * ∫ p, f (p.1 - p.2) ∂(μ.prod μ) := by
  refine ce_posdef_core _ hφ hfour (fun ξ => ∑ x ∈ S, ceWave ξ x) (fun ξ => ∫ y, ceWave ξ y ∂μ)
    (continuous_finsetSum _ fun x _ => ceWave_continuous_left x) ?_ S.card (1 * μ.real Set.univ)
    (fun ξ => ?_) (fun ξ => norm_integral_le_of_norm_le_const
      (ae_of_all _ fun y => (ceWave_norm ξ y).le)) _ _ _ c
    (ce_I1 f hcont hf hφ S) (ce_I2 f hcont hf hφ S μ) (ce_I4 f hcont hf hφ μ)
  · exact continuous_of_dominated (bound := fun _ => (1 : ℝ))
      (fun ξ => (ceWave_continuous_right ξ).aestronglyMeasurable)
      (fun ξ => ae_of_all _ fun y => (ceWave_norm ξ y).le) (integrable_const 1)
      (ae_of_all _ fun y => ceWave_continuous_left y)
  · calc ‖∑ x ∈ S, ceWave ξ x‖ ≤ ∑ x ∈ S, ‖ceWave ξ x‖ := norm_sum_le _ _
      _ = S.card := by simp [ceWave_norm]

lemma ce_tail_bound {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hf : Integrable f) (T R' : ℝ)
    (x : EuclideanSpace ℝ (Fin d)) (hx : ‖x‖ + T ≤ R') :
    |(∫ z, f z) - ∫ y in ball 0 R', f (x - y)| ≤
      ∫ z, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z := by
  have hg : Integrable (fun y => f (x - y)) := hf.comp_sub_left x
  have hmeas : MeasurableSet {z : EuclideanSpace ℝ (Fin d) | T ≤ ‖z‖} :=
    measurableSet_le measurable_const measurable_norm
  have hsplit : (∫ y in ball 0 R', f (x - y)) + ∫ y in (ball 0 R')ᶜ, f (x - y) =
      ∫ y, f (x - y) := integral_add_compl measurableSet_ball hg
  have e : ∫ y, f (x - y) = ∫ z, f z := integral_sub_left_eq_self _ _ _
  rw [show (∫ z, f z) - ∫ y in ball 0 R', f (x - y) = ∫ y in (ball 0 R')ᶜ, f (x - y) by
    linarith]
  calc |∫ y in (ball 0 R')ᶜ, f (x - y)| ≤ ∫ y in (ball 0 R')ᶜ, |f (x - y)| :=
        abs_integral_le_integral_abs
    _ = ∫ y, Set.indicator (ball 0 R')ᶜ (fun y => |f (x - y)|) y :=
        (integral_indicator measurableSet_ball.compl).symm
    _ ≤ ∫ y, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) (x - y) := by
        refine integral_mono (hg.abs.indicator measurableSet_ball.compl)
          ((hf.abs.indicator hmeas).comp_sub_left x) fun y => ?_
        by_cases hy : y ∈ (ball (0 : EuclideanSpace ℝ (Fin d)) R')ᶜ
        · have h1 : R' ≤ ‖y‖ := by simpa using hy
          have h2 : T ≤ ‖x - y‖ := by
            have := norm_sub_norm_le y x
            rw [norm_sub_rev] at this
            linarith
          rw [Set.indicator_of_mem hy, Set.indicator_of_mem (show x - y ∈ {z | T ≤ ‖z‖} from h2)]
        · rw [Set.indicator_of_notMem hy]
          exact Set.indicator_nonneg (fun _ _ => abs_nonneg _) _
    _ = _ := integral_sub_left_eq_self _ _ _

lemma ce_count {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (r K : ℝ) (hcont : Continuous f)
    (hf : Integrable f) (hK : ∀ x, |f x| ≤ K) (hφ : Integrable (𝓕 (fun z => (f z : ℂ))))
    (hfour : ∀ y, 0 ≤ 𝓕 (fun z => (f z : ℂ)) y)
    (hneg : ∀ x : EuclideanSpace ℝ (Fin d), r ≤ ‖x‖ → f x ≤ 0)
    (hF0 : ∫ x, f x = f 0) (hpos : 0 < f 0) (T R : ℝ) (hT : 0 ≤ T)
    (S : Finset (EuclideanSpace ℝ (Fin d))) (hSR : ∀ x ∈ S, ‖x‖ < R)
    (hsep : ∀ x ∈ S, ∀ y ∈ S, x ≠ y → r ≤ ‖x - y‖)
    (hτ : ∫ z, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z ≤ f 0) :
    (S.card : ℝ) * (f 0 - ∫ z, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z) ^ 2 ≤
      f 0 * (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) *
        (f 0 + ∫ z, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z) +
        (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) -
          volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) R)) * ∫ x, |f x|) := by
  set τ := ∫ z, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z with hτdef
  set F0 := f 0 with hF0def
  set L1 := ∫ x, |f x| with hL1
  set μ := volume.restrict (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) with hμ
  have : IsFiniteMeasure μ := isFiniteMeasure_restrict.mpr measure_ball_lt_top.ne
  have hτ0 : 0 ≤ τ := integral_nonneg fun z => Set.indicator_nonneg (fun _ _ => abs_nonneg _) _
  have hL0 : 0 ≤ L1 := integral_nonneg fun z => abs_nonneg _
  set h : EuclideanSpace ℝ (Fin d) → ℝ := fun x => ∫ y, f (x - y) ∂μ with hh
  -- the inner integral near the centre and everywhere
  have hnear : ∀ x : EuclideanSpace ℝ (Fin d), ‖x‖ < R → |F0 - h x| ≤ τ := by
    intro x hx
    have := ce_tail_bound f hf T (R + T) x (by linarith)
    rwa [hF0] at this
  have hfar : ∀ x, h x ≤ L1 := by
    intro x
    calc h x ≤ |h x| := le_abs_self _
      _ ≤ ∫ y, |f (x - y)| ∂μ := abs_integral_le_integral_abs
      _ ≤ ∫ y, |f (x - y)| := setIntegral_le_integral (hf.comp_sub_left x).abs
          (ae_of_all _ fun _ => abs_nonneg _)
      _ = L1 := integral_sub_left_eq_self (fun z => |f z|) _ x
  -- the three terms
  have hA : (∑ x ∈ S, ∑ y ∈ S, f (x - y)) ≤ S.card * F0 := by
    rw [← nsmul_eq_mul, ← Finset.sum_const]
    refine Finset.sum_le_sum fun x hx => ?_
    rw [← Finset.add_sum_erase _ _ hx, sub_self]
    have : ∑ y ∈ S.erase x, f (x - y) ≤ 0 := Finset.sum_nonpos fun y hy =>
      hneg _ (hsep x hx y (Finset.mem_of_mem_erase hy) (Finset.ne_of_mem_erase hy).symm)
    linarith
  have hB : S.card * (F0 - τ) ≤ ∑ x ∈ S, h x := by
    rw [← nsmul_eq_mul, ← Finset.sum_const]
    refine Finset.sum_le_sum fun x hx => ?_
    have := hnear x (hSR x hx)
    rw [abs_le] at this
    linarith
  have hprod_int : Integrable (fun p : EuclideanSpace ℝ (Fin d) × EuclideanSpace ℝ (Fin d) =>
      f (p.1 - p.2)) (μ.prod μ) :=
    Integrable.of_bound (by fun_prop : Continuous fun p : EuclideanSpace ℝ (Fin d) ×
      EuclideanSpace ℝ (Fin d) => f (p.1 - p.2)).aestronglyMeasurable K
      (ae_of_all _ fun p => by simpa using hK (p.1 - p.2))
  have hD : ∫ p, f (p.1 - p.2) ∂(μ.prod μ) ≤
      volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) * (F0 + τ) +
        (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) -
          volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) R)) * L1 := by
    rw [integral_prod _ hprod_int]
    have hhint : Integrable h μ := hprod_int.integral_prod_left
    have hmeasR : MeasurableSet (ball (0 : EuclideanSpace ℝ (Fin d)) R)ᶜ := measurableSet_ball.compl
    calc ∫ x, h x ∂μ ≤ ∫ x, ((F0 + τ) + Set.indicator (ball 0 R)ᶜ (fun _ => L1) x) ∂μ := by
          refine integral_mono hhint ((integrable_const _).add
            ((integrable_const L1).indicator hmeasR)) fun x => ?_
          by_cases hx : x ∈ (ball (0 : EuclideanSpace ℝ (Fin d)) R)ᶜ
          · rw [Set.indicator_of_mem hx]
            have := hfar x
            linarith
          · rw [Set.indicator_of_notMem hx]
            have hx' : ‖x‖ < R := by simpa using hx
            have := hnear x hx'
            rw [abs_le] at this
            linarith
      _ = _ := by
          rw [integral_add (integrable_const _) ((integrable_const L1).indicator hmeasR),
            integral_const, integral_indicator_const _ hmeasR, measureReal_restrict_apply_univ,
            measureReal_restrict_apply hmeasR, smul_eq_mul, smul_eq_mul]
          congr 2
          rw [Set.inter_comm, ← Set.sdiff_eq, measureReal_sdiff (ball_subset_ball (by linarith))
            measurableSet_ball]
  -- positivity of the quadratic form
  have hQ : ∀ c : ℝ, 0 ≤ (∫ p, f (p.1 - p.2) ∂(μ.prod μ)) * (c * c) +
      (-2 * ∑ x ∈ S, h x) * c + ∑ x ∈ S, ∑ y ∈ S, f (x - y) := by
    intro c
    have := ce_posdef f hcont hf hφ hfour S μ c
    simp only [h]
    linarith
  have hdisc := discrim_le_zero hQ
  rw [discrim] at hdisc
  have hD0 : 0 ≤ ∫ p, f (p.1 - p.2) ∂(μ.prod μ) := by
    have := ce_posdef f hcont hf hφ hfour ∅ μ 1
    simpa using this
  set A := ∑ x ∈ S, ∑ y ∈ S, f (x - y)
  set Bc := ∑ x ∈ S, h x
  set D := ∫ p, f (p.1 - p.2) ∂(μ.prod μ)
  set N : ℝ := (S.card : ℝ)
  have hN : 0 ≤ N := Nat.cast_nonneg _
  have h1 : 0 ≤ N * (F0 - τ) := mul_nonneg hN (by linarith)
  have h2 : (N * (F0 - τ)) ^ 2 ≤ Bc ^ 2 := pow_le_pow_left₀ h1 hB 2
  have h3 : Bc ^ 2 ≤ D * A := by nlinarith
  have h4 : D * A ≤ D * (N * F0) := mul_le_mul_of_nonneg_left hA hD0
  have h5 : D * (N * F0) ≤ (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) * (F0 + τ) +
        (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) -
          volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) R)) * L1) * (N * F0) :=
    mul_le_mul_of_nonneg_right hD (mul_nonneg hN hpos.le)
  rcases hN.eq_or_lt with hN0 | hNpos
  · rw [← hN0, zero_mul]
    have hV : volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) R) ≤
        volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) :=
      measureReal_mono (ball_subset_ball (by linarith))
    exact mul_nonneg hpos.le (add_nonneg (mul_nonneg measureReal_nonneg (by linarith))
      (mul_nonneg (by linarith) hL0))
  · have : N * (N * (F0 - τ) ^ 2) ≤ N * (F0 * (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) * (F0 + τ) +
        (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) (R + T)) -
          volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) R)) * L1)) := by nlinarith
    exact le_of_mul_le_mul_left this hNpos

lemma ce_integrable_of_decay {d : ℕ} {G : Type*} [NormedAddCommGroup G]
    (g : EuclideanSpace ℝ (Fin d) → G) (hg : Continuous g) (C δ : ℝ) (hδ : 0 < δ)
    (hb : ∀ x, ‖g x‖ ≤ C * (1 + ‖x‖) ^ (-((d : ℝ) + δ))) : Integrable g :=
  ((integrable_one_add_norm (by simp; linarith)).const_mul C).mono' hg.aestronglyMeasurable
    (ae_of_all _ hb)

lemma ce_vol_ball {d : ℕ} (R : ℝ) (hR : 0 < R) :
    volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) R) =
      volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) 1) * R ^ d := by
  rw [measureReal_def, Measure.addHaar_ball_of_pos volume 0 hR, ENNReal.toReal_mul,
    ENNReal.toReal_ofReal (by positivity), finrank_euclideanSpace_fin, measureReal_def, mul_comm]

lemma ce_tail_tendsto {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (hf : Integrable f) :
    Tendsto (fun T : ℝ => ∫ z, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z) atTop (𝓝 0) := by
  have h := tendsto_integral_filter_of_dominated_convergence (l := atTop)
    (F := fun T : ℝ => fun z => Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z)
    (f := fun _ => (0 : ℝ)) (fun z => |f z|)
    (Eventually.of_forall fun T => (hf.abs.indicator
      (measurableSet_le measurable_const measurable_norm)).aestronglyMeasurable)
    (Eventually.of_forall fun T => ae_of_all _ fun z => by
      rw [Real.norm_eq_abs, abs_of_nonneg (Set.indicator_nonneg (fun _ _ => abs_nonneg _) _)]
      exact Set.indicator_le_self' (fun _ _ => abs_nonneg _) z)
    hf.abs (ae_of_all _ fun z => by
      refine tendsto_const_nhds.congr' ?_
      filter_upwards [eventually_gt_atTop ‖z‖] with T hT
      rw [Set.indicator_of_notMem (by simpa using hT)])
  simpa using h

lemma ce_set_of_finset {d : ℕ} (S : Set (EuclideanSpace ℝ (Fin d))) (B : ℝ)
    (h : ∀ t : Finset (EuclideanSpace ℝ (Fin d)), ↑t ⊆ S → (t.card : ℝ) ≤ B) :
    S.Finite ∧ (Nat.card S : ℝ) ≤ B := by
  have hfin : S.Finite := by
    by_contra hinf
    obtain ⟨t, ht, hcard⟩ := Set.Infinite.exists_subset_card_eq hinf (⌊B⌋₊ + 1)
    have h1 := h t ht
    rw [hcard] at h1
    have h2 : 0 ≤ B := le_trans (by positivity) h1
    have h3 := Nat.lt_floor_add_one B
    push_cast at h1
    linarith
  refine ⟨hfin, ?_⟩
  rw [Nat.card_coe_set_eq, Set.ncard_eq_toFinset_card S hfin]
  exact h _ (by simp)

lemma ce_core {d : ℕ} (f : EuclideanSpace ℝ (Fin d) → ℝ) (r : ℝ)
    (hcont : Continuous f)
    (hdecay : ∃ C δ : ℝ, 0 < δ ∧ ∀ x : EuclideanSpace ℝ (Fin d),
      |f x| ≤ C * (1 + ‖x‖) ^ (-((d : ℝ) + δ)) ∧
      ‖𝓕 (fun z => (f z : ℂ)) x‖ ≤ C * (1 + ‖x‖) ^ (-((d : ℝ) + δ)))
    (hneg : ∀ x : EuclideanSpace ℝ (Fin d), r ≤ ‖x‖ → f x ≤ 0)
    (hfour : ∀ y : EuclideanSpace ℝ (Fin d), 0 ≤ 𝓕 (fun z => (f z : ℂ)) y)
    (hzero : 𝓕 (fun z => (f z : ℂ)) 0 = (f 0 : ℂ)) (hpos : 0 < f 0) :
    0 < r ∧ ∀ ε > 0, ∃ R0 : ℝ, ∀ R ≥ R0, 0 < R ∧ ∀ S : Set (EuclideanSpace ℝ (Fin d)),
      S ⊆ ball 0 R → (∀ x ∈ S, ∀ y ∈ S, x ≠ y → r ≤ dist x y) →
      S.Finite ∧ (Nat.card S : ℝ) ≤
        (1 + ε) * (volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) 1) * R ^ d) := by
  have hr : 0 < r := by
    by_contra h
    have := hneg 0 (by simp; linarith)
    linarith
  refine ⟨hr, fun ε hε => ?_⟩
  obtain ⟨C, δ, hδ, hb⟩ := hdecay
  have hf : Integrable f := ce_integrable_of_decay f hcont C δ hδ fun x => (hb x).1
  have hφ : Integrable (𝓕 (fun z => (f z : ℂ))) :=
    ce_integrable_of_decay _ (ce_fourier_continuous _ hf.ofReal) C δ hδ fun x => (hb x).2
  have hK : ∀ x, |f x| ≤ C := by
    have hC : 0 ≤ C := by
      have := (hb 0).1
      simp at this
      linarith [abs_nonneg (f 0)]
    intro x
    refine (hb x).1.trans ?_
    calc C * (1 + ‖x‖) ^ (-((d : ℝ) + δ)) ≤ C * 1 := by
          gcongr
          exact Real.rpow_le_one_of_one_le_of_nonpos (by linarith [norm_nonneg x])
            (by linarith [(Nat.cast_nonneg d : (0 : ℝ) ≤ d)])
      _ = C := mul_one C
  have hF0 : ∫ x, f x = f 0 := by
    have h := hzero
    simp only [Real.fourier_eq, inner_zero_right, neg_zero, AddChar.map_zero_eq_one,
      one_smul] at h
    rw [integral_complex_ofReal] at h
    exact_mod_cast h
  set τ : ℝ → ℝ := fun T => ∫ z, Set.indicator {z | T ≤ ‖z‖} (fun z => |f z|) z with hτ
  set F0 := f 0 with hF0def
  set L1 := ∫ x, |f x| with hL1
  set ω := volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) 1) with hω
  have ha : Tendsto (fun R : ℝ => √R / R) atTop (𝓝 0) := by
    have : (fun R : ℝ => √R / R) = fun R => (√R)⁻¹ := by
      ext R; rw [Real.sqrt_div_self', one_div]
    rw [this]
    exact tendsto_inv_atTop_zero.comp Real.tendsto_sqrt_atTop
  have hb' : Tendsto (fun R : ℝ => τ (√R)) atTop (𝓝 0) :=
    (ce_tail_tendsto f hf).comp Real.tendsto_sqrt_atTop
  have hg : Tendsto (fun R : ℝ => F0 * ((1 + √R / R) ^ d * (F0 + τ (√R)) +
      ((1 + √R / R) ^ d - 1) * L1) / (F0 - τ (√R)) ^ 2) atTop (𝓝 1) := by
    have h1 : Tendsto (fun R : ℝ => (1 + √R / R) ^ d) atTop (𝓝 ((1 + 0) ^ d)) :=
      (tendsto_const_nhds.add ha).pow d
    have h2 : Tendsto (fun R : ℝ => F0 + τ (√R)) atTop (𝓝 (F0 + 0)) :=
      tendsto_const_nhds.add hb'
    have h3 : Tendsto (fun R : ℝ => F0 - τ (√R)) atTop (𝓝 (F0 - 0)) :=
      tendsto_const_nhds.sub hb'
    have h4 := (tendsto_const_nhds (x := F0)).mul ((h1.mul h2).add
      ((h1.sub (tendsto_const_nhds (x := (1 : ℝ)))).mul (tendsto_const_nhds (x := L1))))
    have h5 := h4.div (h3.pow 2) (by simp; exact hpos.ne')
    convert h5 using 2
    simp only [add_zero, one_pow, sub_zero, sub_self, zero_mul, one_mul]
    field_simp
  obtain ⟨R0, hR0⟩ := eventually_atTop.1 ((hg.eventually (gt_mem_nhds (by linarith : (1 : ℝ) < 1 + ε))).and
    ((hb'.eventually (gt_mem_nhds hpos)).and (eventually_ge_atTop (1 : ℝ))))
  refine ⟨R0, fun R hR => ?_⟩
  obtain ⟨hgR, hτR, hR1⟩ := hR0 R hR
  have hRpos : 0 < R := by linarith
  refine ⟨hRpos, fun S hS hsep => ce_set_of_finset S _ fun t ht => ?_⟩
  have hcount := ce_count f r C hcont hf hK hφ hfour hneg hF0 hpos (√R) R (Real.sqrt_nonneg R) t
    (fun x hx => by simpa using hS (ht hx))
    (fun x hx y hy hxy => by rw [← dist_eq_norm]; exact hsep x (ht hx) y (ht hy) hxy) hτR.le
  rw [ce_vol_ball _ (by positivity), ce_vol_ball _ hRpos] at hcount
  have hsplit : (R + √R) ^ d = R ^ d * (1 + √R / R) ^ d := by
    rw [← mul_pow]; congr 1; field_simp
  rw [hsplit] at hcount
  have hpos2 : 0 < (F0 - τ (√R)) ^ 2 := by
    have : 0 < F0 - τ (√R) := by linarith
    positivity
  have hωR : 0 ≤ ω * R ^ d := mul_nonneg measureReal_nonneg (by positivity)
  have key : (t.card : ℝ) ≤ ω * R ^ d * (F0 * ((1 + √R / R) ^ d * (F0 + τ (√R)) +
      ((1 + √R / R) ^ d - 1) * L1) / (F0 - τ (√R)) ^ 2) := by
    rw [mul_div_assoc', le_div_iff₀ hpos2]
    calc (t.card : ℝ) * (F0 - τ (√R)) ^ 2 ≤ _ := hcount
      _ = _ := by ring
  calc (t.card : ℝ) ≤ _ := key
    _ ≤ ω * R ^ d * (1 + ε) := mul_le_mul_of_nonneg_left hgR.le hωR
    _ = _ := by ring

#print axioms ceWave_norm
#print axioms ceWave_continuous
#print axioms ceWave_continuous_right
#print axioms ceWave_continuous_left
#print axioms ceWave_mul_conj
#print axioms ce_fourier_continuous
#print axioms ce_inversion
#print axioms ce_swap
#print axioms ce_swap_int
#print axioms ce_I1
#print axioms ce_I2
#print axioms ce_I4
#print axioms ce_posdef_core
#print axioms ce_posdef
#print axioms ce_tail_bound
#print axioms ce_count
#print axioms ce_integrable_of_decay
#print axioms ce_vol_ball
#print axioms ce_tail_tendsto
#print axioms ce_set_of_finset
#print axioms ce_core

/-- The Cohn–Elkies bound. Let `f` be a continuous real function on `d`-dimensional space that,
with its Fourier transform, fades faster than `|x|^(−d)`. Suppose `f(x) ≤ 0` whenever
`|x| ≥ r`, the transform `𝓕 f(y)` is real and at least 0 for every `y`, and
`f(0) = 𝓕 f(0) > 0`. Then every packing of balls of radius `r/2` in `d`-dimensional space,
lattice or not, has density at most the volume of one ball of radius `r/2`. -/
theorem cohn_elkies_density_le_ball_volume (d : ℕ) (f : EuclideanSpace ℝ (Fin d) → ℝ) (r : ℝ)
    (hcont : Continuous f)
    (hdecay : ∃ C δ : ℝ, 0 < δ ∧ ∀ x : EuclideanSpace ℝ (Fin d),
      |f x| ≤ C * (1 + ‖x‖) ^ (-((d : ℝ) + δ)) ∧
      ‖𝓕 (fun z => (f z : ℂ)) x‖ ≤ C * (1 + ‖x‖) ^ (-((d : ℝ) + δ)))
    (hneg : ∀ x : EuclideanSpace ℝ (Fin d), r ≤ ‖x‖ → f x ≤ 0)
    (hfour : ∀ y : EuclideanSpace ℝ (Fin d), 0 ≤ 𝓕 (fun z => (f z : ℂ)) y)
    (hzero : 𝓕 (fun z => (f z : ℂ)) 0 = (f 0 : ℂ)) (hpos : 0 < f 0)
    (X : Set (EuclideanSpace ℝ (Fin d)))
    (hpack : ∀ x ∈ X, ∀ y ∈ X, x ≠ y → r ≤ dist x y) :
    limsup (fun R : ℝ => volume ((⋃ x ∈ X, ball x (r / 2)) ∩ ball 0 R) /
        volume (ball (0 : EuclideanSpace ℝ (Fin d)) R)) atTop ≤
      volume (ball (0 : EuclideanSpace ℝ (Fin d)) (r / 2)) := by
  obtain ⟨hr, hcore⟩ := ce_core f r hcont hdecay hneg hfour hzero hpos
  set ω := volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) 1) with hω
  set Vr := volume (ball (0 : EuclideanSpace ℝ (Fin d)) (r / 2)) with hVrdef
  have hVr : Vr ≠ ⊤ := measure_ball_lt_top.ne
  have hωpos : 0 < ω := ENNReal.toReal_pos (measure_ball_pos volume _ one_pos).ne'
    measure_ball_lt_top.ne
  have hε : ∀ ε > 0, limsup (fun R : ℝ => volume ((⋃ x ∈ X, ball x (r / 2)) ∩ ball 0 R) /
      volume (ball (0 : EuclideanSpace ℝ (Fin d)) R)) atTop ≤ ENNReal.ofReal (1 + ε) * Vr := by
    intro ε hε
    obtain ⟨R0, hR0⟩ := hcore ε hε
    have hev : ∀ᶠ R : ℝ in atTop, volume ((⋃ x ∈ X, ball x (r / 2)) ∩ ball 0 R) /
        volume (ball (0 : EuclideanSpace ℝ (Fin d)) R) ≤
        ENNReal.ofReal ((1 + ε) * ((R + r / 2) / R) ^ d) * Vr := by
      filter_upwards [eventually_ge_atTop (max R0 1)] with R hR
      have hRpos : 0 < R := by linarith [le_max_right R0 1]
      obtain ⟨-, hS⟩ := hR0 (R + r / 2) (by linarith [le_max_left R0 1])
      obtain ⟨hfin, hcard⟩ := hS (X ∩ ball 0 (R + r / 2)) Set.inter_subset_right
        (fun x hx y hy hxy => hpack x hx.1 y hy.1 hxy)
      have hsub : (⋃ x ∈ X, ball x (r / 2)) ∩ ball 0 R ⊆ ⋃ x ∈ hfin.toFinset, ball x (r / 2) := by
        rintro z ⟨hz, hzR⟩
        simp only [Set.mem_iUnion] at hz
        obtain ⟨x, hxX, hzx⟩ := hz
        simp only [Set.mem_iUnion, Set.Finite.mem_toFinset]
        refine ⟨x, ⟨hxX, ?_⟩, hzx⟩
        rw [mem_ball] at hzx hzR ⊢
        calc dist x 0 ≤ dist x z + dist z 0 := dist_triangle _ _ _
          _ < R + r / 2 := by rw [dist_comm]; linarith
      have hmeas : volume ((⋃ x ∈ X, ball x (r / 2)) ∩ ball 0 R) ≤
          ENNReal.ofReal ((1 + ε) * (ω * (R + r / 2) ^ d)) * Vr := by
        calc _ ≤ volume (⋃ x ∈ hfin.toFinset, ball x (r / 2)) := measure_mono hsub
          _ ≤ ∑ x ∈ hfin.toFinset, volume (ball x (r / 2)) := measure_biUnion_finset_le _ _
          _ = ∑ x ∈ hfin.toFinset, Vr := Finset.sum_congr rfl fun x _ =>
              Measure.addHaar_ball_center _ _ _
          _ = (hfin.toFinset.card : ENNReal) * Vr := by rw [Finset.sum_const, nsmul_eq_mul]
          _ ≤ _ := by
              gcongr
              rw [← ENNReal.ofReal_natCast]
              apply ENNReal.ofReal_le_ofReal
              rw [← Set.ncard_eq_toFinset_card _ hfin, ← Nat.card_coe_set_eq]
              exact hcard
      have hball : volume (ball (0 : EuclideanSpace ℝ (Fin d)) R) = ENNReal.ofReal (ω * R ^ d) := by
        rw [← ce_vol_ball R hRpos, ofReal_measureReal]
      rw [hball]
      calc _ ≤ ENNReal.ofReal ((1 + ε) * (ω * (R + r / 2) ^ d)) * Vr /
            ENNReal.ofReal (ω * R ^ d) := by gcongr
        _ = ENNReal.ofReal ((1 + ε) * (ω * (R + r / 2) ^ d) / (ω * R ^ d)) * Vr := by
            rw [ENNReal.mul_div_right_comm, ENNReal.ofReal_div_of_pos (by positivity)]
        _ = _ := by
            congr 2
            rw [div_pow]
            field_simp
    have hβ : Tendsto (fun R : ℝ => (1 + ε) * ((R + r / 2) / R) ^ d) atTop
        (𝓝 ((1 + ε) * (1 + 0) ^ d)) := by
      refine tendsto_const_nhds.mul (Tendsto.pow ?_ d)
      have h0 : Tendsto (fun R : ℝ => 1 + r / 2 / R) atTop (𝓝 (1 + 0)) :=
        tendsto_const_nhds.add (tendsto_const_nhds.div_atTop tendsto_id)
      refine h0.congr' ?_
      filter_upwards [eventually_gt_atTop 0] with R hR
      field_simp
    have hlim : Tendsto (fun R : ℝ => ENNReal.ofReal ((1 + ε) * ((R + r / 2) / R) ^ d) * Vr)
        atTop (𝓝 (ENNReal.ofReal (1 + ε) * Vr)) := by
      have := ENNReal.Tendsto.mul_const (ENNReal.tendsto_ofReal hβ) (Or.inr hVr)
      simpa using this
    calc _ ≤ limsup (fun R : ℝ => ENNReal.ofReal ((1 + ε) * ((R + r / 2) / R) ^ d) * Vr) atTop :=
          limsup_le_limsup hev
      _ = _ := hlim.limsup_eq
  have hlim0 : Tendsto (fun ε : ℝ => ENNReal.ofReal (1 + ε) * Vr) (𝓝[>] 0)
      (𝓝 (ENNReal.ofReal (1 + 0) * Vr)) :=
    (ENNReal.Tendsto.mul_const (ENNReal.tendsto_ofReal (tendsto_const_nhds.add tendsto_id))
      (Or.inr hVr)).mono_left nhdsWithin_le_nhds
  have := ge_of_tendsto hlim0 (eventually_nhdsWithin_of_forall fun ε (hε' : 0 < ε) => hε ε hε')
  simpa using this

/-- The Cohn–Elkies bound for a lattice packing (the card's detailed proof). If a lattice `Λ`
in `d`-dimensional space has closest spacing at least `r`, and `f` meets the same conditions,
then the lattice packing's density, one ball's volume `vol B(r/2)` divided by the volume
`V_Λ` each lattice point owns, is at most `vol B(r/2)`. -/
theorem cohn_elkies_lattice_density_le (d : ℕ) (f : EuclideanSpace ℝ (Fin d) → ℝ) (r : ℝ)
    (hcont : Continuous f)
    (hdecay : ∃ C δ : ℝ, 0 < δ ∧ ∀ x : EuclideanSpace ℝ (Fin d),
      |f x| ≤ C * (1 + ‖x‖) ^ (-((d : ℝ) + δ)) ∧
      ‖𝓕 (fun z => (f z : ℂ)) x‖ ≤ C * (1 + ‖x‖) ^ (-((d : ℝ) + δ)))
    (hneg : ∀ x : EuclideanSpace ℝ (Fin d), r ≤ ‖x‖ → f x ≤ 0)
    (hfour : ∀ y : EuclideanSpace ℝ (Fin d), 0 ≤ 𝓕 (fun z => (f z : ℂ)) y)
    (hzero : 𝓕 (fun z => (f z : ℂ)) 0 = (f 0 : ℂ)) (hpos : 0 < f 0)
    (Λ : Submodule ℤ (EuclideanSpace ℝ (Fin d))) [DiscreteTopology Λ] [IsZLattice ℝ Λ]
    (hmin : ∀ x ∈ Λ, x ≠ 0 → r ≤ ‖x‖) :
    (volume (ball (0 : EuclideanSpace ℝ (Fin d)) (r / 2))).toReal / ZLattice.covolume Λ ≤
      (volume (ball (0 : EuclideanSpace ℝ (Fin d)) (r / 2))).toReal := by
  obtain ⟨hr, hcore⟩ := ce_core f r hcont hdecay hneg hfour hzero hpos
  set ω := volume.real (ball (0 : EuclideanSpace ℝ (Fin d)) 1) with hω
  have hωpos : 0 < ω := ENNReal.toReal_pos (measure_ball_pos volume _ one_pos).ne'
    measure_ball_lt_top.ne
  have hcov : 0 < ZLattice.covolume Λ := ZLattice.covolume_pos Λ
  have hfront : volume (frontier (ball (0 : EuclideanSpace ℝ (Fin d)) 1)) = 0 := by
    rw [frontier_ball _ one_ne_zero]
    rcases subsingleton_or_nontrivial (EuclideanSpace ℝ (Fin d)) with h | h
    · have : sphere (0 : EuclideanSpace ℝ (Fin d)) 1 = ∅ := by
        ext x; simp [Subsingleton.elim x 0]
      simp [this]
    · exact Measure.addHaar_sphere volume 0 1
  have hlim := ZLattice.covolume.tendsto_card_div_pow' Λ isBounded_ball measurableSet_ball hfront
  rw [finrank_euclideanSpace_fin] at hlim
  have key : ∀ ε > 0, ω / ZLattice.covolume Λ ≤ (1 + ε) * ω := by
    intro ε hε
    obtain ⟨R0, hR0⟩ := hcore ε hε
    refine le_of_tendsto hlim ?_
    filter_upwards [tendsto_natCast_atTop_atTop.eventually_ge_atTop (max R0 1)] with n hn
    have hnpos : (0 : ℝ) < n := by linarith [le_max_right R0 1]
    obtain ⟨-, hS⟩ := hR0 n (le_trans (le_max_left R0 1) hn)
    set A := ball (0 : EuclideanSpace ℝ (Fin d)) 1 ∩ (n : ℝ)⁻¹ • (Λ : Set (EuclideanSpace ℝ (Fin d))) with hA
    have hinj : Function.Injective (fun x : EuclideanSpace ℝ (Fin d) => (n : ℝ) • x) :=
      smul_right_injective _ hnpos.ne'
    have himg : Nat.card ((fun x => (n : ℝ) • x) '' A) = Nat.card A :=
      Nat.card_image_of_injective hinj _
    have hinΛ : ∀ z ∈ (fun x => (n : ℝ) • x) '' A, z ∈ Λ := by
      rintro z ⟨x, ⟨-, hx⟩, rfl⟩
      obtain ⟨l, hl, rfl⟩ := Set.mem_smul_set.1 hx
      simp only
      rw [smul_smul, mul_inv_cancel₀ hnpos.ne', one_smul]
      exact hl
    obtain ⟨-, hcard⟩ := hS ((fun x => (n : ℝ) • x) '' A)
      (by
        rintro z ⟨x, ⟨hx, -⟩, rfl⟩
        rw [mem_ball_zero_iff] at hx ⊢
        rw [norm_smul, Real.norm_eq_abs, abs_of_pos hnpos]
        calc (n : ℝ) * ‖x‖ < n * 1 := by gcongr
          _ = n := mul_one _)
      (fun x hx y hy hxy => by
        rw [dist_eq_norm]
        exact hmin _ (Submodule.sub_mem _ (hinΛ x hx) (hinΛ y hy)) (sub_ne_zero.2 hxy))
    rw [himg] at hcard
    rw [div_le_iff₀ (by positivity)]
    linarith
  have h1 : 1 ≤ ZLattice.covolume Λ := by
    refine le_of_forall_pos_le_add fun ε hε => ?_
    have := key (ε / ZLattice.covolume Λ) (div_pos hε hcov)
    rw [div_le_iff₀ hcov] at this
    have hc : ε / ZLattice.covolume Λ * ZLattice.covolume Λ = ε := div_mul_cancel₀ ε hcov.ne'
    have h3 : (1 + ε / ZLattice.covolume Λ) * ω * ZLattice.covolume Λ =
        ω * (ZLattice.covolume Λ + ε) := by linear_combination ω * hc
    rw [h3] at this
    exact le_of_mul_le_mul_left (by linarith : ω * 1 ≤ ω * (ZLattice.covolume Λ + ε)) hωpos
  exact div_le_self ENNReal.toReal_nonneg h1

/-- The cap in dimension 8. A ball of radius `R` in 8 dimensions has volume `(π^4/24) R^8`, so
with E8's closest spacing `r = √2` one ball of radius `√2/2` has volume `π^4/384`, the density
of E8 (volume 1 per point) and the Cohn–Elkies cap that Viazovska's magic function reaches. -/
theorem volume_ball_dim_eight (x : EuclideanSpace ℝ (Fin 8)) (R : ℝ) (hR : 0 ≤ R) :
    volume (ball x R) = ENNReal.ofReal (π ^ 4 / 24 * R ^ 8) ∧
      volume (ball x (√2 / 2)) = ENNReal.ofReal (π ^ 4 / 384) := by
  have key : ∀ s : ℝ, 0 ≤ s → volume (ball x s) = ENNReal.ofReal (π ^ 4 / 24 * s ^ 8) := by
    intro s hs
    rw [InnerProductSpace.volume_ball_of_dim_even (k := 4) (by simp) x s]
    rw [finrank_euclideanSpace_fin, ← ENNReal.ofReal_pow hs, ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    norm_num [Nat.factorial]
    ring
  refine ⟨key R hR, ?_⟩
  rw [key _ (by positivity)]
  congr 1
  have h2 : (√2 : ℝ) ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have : (√2 / 2 : ℝ) ^ 8 = 1 / 16 := by
    rw [div_pow, show (8:ℕ) = 2 * 4 from rfl, pow_mul, h2]; norm_num
  rw [this]; ring

-- E8's shells from E4 = 1 + 240 Σ σ3(n) q^n: 240, 2,160 and 6,720 vectors of squared length 2, 4, 6.
example : 240 * sigma 3 1 = 240 ∧ 240 * sigma 3 2 = 2160 ∧ 240 * sigma 3 3 = 6720 := by decide
-- E8 points with squared length at most 200, read from E4's coefficients: 6,634,372,561.
example : 1 + ∑ m ∈ Finset.Icc 1 100, 240 * sigma 3 m = 6634372561 := by decide +kernel
-- D8's deep hole (1/2, ..., 1/2): squared distance 8 × (1/2)^2 = 2 in dimension 8, only 3/4 in dimension 3.
example : (8 : ℚ) * (1 / 2) ^ 2 = 2 ∧ (3 : ℚ) * (1 / 2) ^ 2 = 3 / 4 := by norm_num
-- Leech lattice from modular forms: (65520/691)(σ11(m) − τ(m)) with τ(1), τ(2), τ(3) = 1, −24, 252
-- gives 0, 196,560 and 16,773,120 vectors of squared length 2, 4, 6.
example : sigma 11 1 - 1 = 0 ∧ 65520 * (sigma 11 2 + 24) = 691 * 196560 ∧
    65520 * (sigma 11 3 - 252) = 691 * 16773120 := by decide
-- Leech shortest vectors from the Golay code: 759 × 2^7 + 24 × 2^12 + C(24, 2) × 4 = 196,560.
example : Nat.choose 24 2 = 276 ∧ 759 * 2 ^ 7 + 24 * 2 ^ 12 + 276 * 4 = 196560 := by decide
-- The Golay code has 2^12 = 4,096 words; the Leech density's denominator is 12! = 479,001,600.
example : 2 ^ 12 = 4096 ∧ Nat.factorial 12 = 479001600 := by decide
-- Oranges in a crate: 40 cm, cube stack 5^3 = 125, pyramid 3 × 25 + 3 × 16 = 123 in 6 layers;
-- 80 cm, cube stack 1,000, pyramid 7 × 100 + 6 × 81 = 1,186 in 13 layers.
example : 5 ^ 3 = 125 ∧ 3 * 5 ^ 2 + 3 * 4 ^ 2 = 123 ∧ 10 ^ 3 = 1000 ∧
    7 * 10 ^ 2 + 6 * 9 ^ 2 = 1186 := by decide
-- 48 cm crate: pyramid 4 × 36 + 4 × 25 = 244 in 8 layers, cube stack 6^3 = 216.
example : 4 * 6 ^ 2 + 4 * 5 ^ 2 = 244 ∧ 6 ^ 3 = 216 := by decide

#print axioms cohn_elkies_density_le_ball_volume
#print axioms cohn_elkies_lattice_density_le
#print axioms volume_ball_dim_eight
