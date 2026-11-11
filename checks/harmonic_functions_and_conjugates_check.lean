-- Harmonic functions: the real and imaginary parts of a holomorphic function are harmonic, a harmonic function on a simply connected open region is the real part of a holomorphic function, and where the derivative is not zero the gradients of the two parts are nonzero and perpendicular, so their level curves cross at right angles.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Constructions
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.AlgebraicTopology.FundamentalGroupoid.SimplyConnected
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.Harmonic.Analytic
import Mathlib.Analysis.Complex.HasPrimitives
import Mathlib.Topology.Homotopy.Lifting

open Set InnerProductSpace

namespace HarmonicConjugateAux

/-- A copy of `ℂ` with the discrete topology. -/
structure Disc where
  val : ℂ

instance : TopologicalSpace Disc := ⊥
instance : DiscreteTopology Disc := ⟨rfl⟩
instance : Nonempty Disc := ⟨⟨0⟩⟩

/-- Points of the étale space of local primitives of `g` over `U`. -/
@[ext]
structure Etale (g : ℂ → ℂ) (U : Set ℂ) where
  base : ℂ
  val : ℂ

instance (g : ℂ → ℂ) (U : Set ℂ) : Inhabited (Etale g U) := ⟨⟨0, 0⟩⟩

variable {g : ℂ → ℂ} {U : Set ℂ}

def hc_IsLocPrim (g : ℂ → ℂ) (U : Set ℂ) (V : Set ℂ) (H : ℂ → ℂ) : Prop :=
  IsOpen V ∧ V ⊆ U ∧ ∀ w ∈ V, HasDerivAt H (g w) w

def hc_sheet (g : ℂ → ℂ) (U : Set ℂ) (V : Set ℂ) (H : ℂ → ℂ) : Set (Etale g U) :=
  {e | e.base ∈ V ∧ e.val = H e.base}

instance (g : ℂ → ℂ) (U : Set ℂ) : TopologicalSpace (Etale g U) :=
  TopologicalSpace.generateFrom
    ({S | ∃ V H, hc_IsLocPrim g U V H ∧ S = hc_sheet g U V H} ∪
      {S | ∃ O : Set ℂ, IsOpen O ∧ S = Etale.base ⁻¹' O})

theorem hc_continuous_base : Continuous (Etale.base : Etale g U → ℂ) := by
  refine continuous_def.2 fun O hO => ?_
  apply TopologicalSpace.isOpen_generateFrom_of_mem
  exact Or.inr ⟨O, hO, rfl⟩

theorem hc_isOpen_sheet {V : Set ℂ} {H : ℂ → ℂ} (h : hc_IsLocPrim g U V H) :
    IsOpen (hc_sheet g U V H) := by
  apply TopologicalSpace.isOpen_generateFrom_of_mem
  exact Or.inl ⟨V, H, h, rfl⟩

/-- The section of the étale space over `B` given by `G + c`. -/
def hc_sec (g : ℂ → ℂ) (U : Set ℂ) (B : Set ℂ) (G : ℂ → ℂ) (c : ℂ) : B → Etale g U :=
  fun w => ⟨w.1, G w.1 + c⟩

theorem hc_continuous_sec {B : Set ℂ} {G : ℂ → ℂ} (hB : hc_IsLocPrim g U B G) (c : ℂ) :
    Continuous (hc_sec g U B G c) := by
  rw [continuous_generateFrom_iff]
  rintro S (⟨V, H, hVH, rfl⟩ | ⟨O, hO, rfl⟩)
  · -- the set where `H - G = c` is open in `B ∩ V`
    have hs : IsOpen (B ∩ V) := hB.1.inter hVH.1
    have hd : DifferentiableOn ℂ (H - G) (B ∩ V) := fun w hw =>
      ((hVH.2.2 w hw.2).sub (hB.2.2 w hw.1)).differentiableAt.differentiableWithinAt
    have hd' : (B ∩ V).EqOn (deriv (H - G)) 0 := by
      intro w hw
      rw [((hVH.2.2 w hw.2).sub (hB.2.2 w hw.1)).deriv, sub_self]
      rfl
    have ho := hs.isOpen_inter_preimage_of_deriv_eq_zero hd hd' {c}
    have : hc_sec g U B G c ⁻¹' hc_sheet g U V H =
        Subtype.val ⁻¹' ((B ∩ V) ∩ (H - G) ⁻¹' {c}) := by
      ext ⟨w, hw⟩
      simp only [hc_sec, hc_sheet, mem_preimage, mem_ofPred_eq, mem_inter_iff, mem_singleton_iff]
      constructor
      · rintro ⟨h1, h2⟩
        exact ⟨⟨hw, h1⟩, by simp only [Pi.sub_apply]; rw [← h2]; ring⟩
      · rintro ⟨⟨_, h1⟩, h2⟩
        exact ⟨h1, by rw [← h2]; simp only [Pi.sub_apply]; ring⟩
    rw [this]
    exact continuous_subtype_val.isOpen_preimage _ ho
  · exact continuous_subtype_val.isOpen_preimage _ hO

/-- Local trivialization over a set `B` carrying a primitive `G`. -/
noncomputable def hc_triv {B : Set ℂ} {G : ℂ → ℂ} (hB : hc_IsLocPrim g U B G) :
    Bundle.Trivialization Disc (Etale.base : Etale g U → ℂ) :=
  IsOpen.trivializationDiscrete (f := (Etale.base : Etale g U → ℂ)) (ι := Disc)
    (fun i => hc_sheet g U B (fun w => G w + i.val)) B hB.1
    (by
      intro i W hWB
      constructor
      · intro hW
        exact (hc_continuous_base.isOpen_preimage W hW).inter
          (hc_isOpen_sheet ⟨hB.1, hB.2.1, fun w hw => (hB.2.2 w hw).add_const _⟩)
      · intro hW
        have h1 := (hc_continuous_sec hB i.val).isOpen_preimage _ hW
        have h2 : hc_sec g U B G i.val ⁻¹' (Etale.base ⁻¹' W ∩ hc_sheet g U B (fun w => G w + i.val)) =
            Subtype.val ⁻¹' W := by
          ext ⟨w, hw⟩
          simp [hc_sec, hc_sheet]
        rw [h2] at h1
        have h3 := hB.1.isOpenMap_subtype_val _ h1
        rwa [Subtype.image_preimage_coe, inter_eq_right.2 hWB] at h3)
    (by
      intro i e1 he1 e2 he2 h
      exact Etale.ext h (by rw [he1.2, he2.2, h]))
    (by
      intro i w hw
      exact ⟨⟨w, G w + i.val⟩, ⟨hw, rfl⟩, rfl⟩)
    (by
      intro i j hij
      rw [Function.onFun, Set.disjoint_left]
      intro e he1 he2
      apply hij
      have : G e.base + i.val = G e.base + j.val := he1.2.symm.trans he2.2
      cases i; cases j
      simpa using this)
    (by
      intro e he
      refine mem_iUnion.2 ⟨⟨e.val - G e.base⟩, he, ?_⟩
      simp)

theorem hc_isCoveringMapOn_base (hU : IsOpen U) (hg : DifferentiableOn ℂ g U) :
    IsCoveringMapOn (Etale.base : Etale g U → ℂ) U := by
  intro x hx
  obtain ⟨r, hr, hrU⟩ := Metric.isOpen_iff.1 hU x hx
  obtain ⟨G, hG⟩ := (hg.mono hrU).isExactOn_ball
  have hB : hc_IsLocPrim g U (Metric.ball x r) G := ⟨Metric.isOpen_ball, hrU, hG⟩
  exact (IsEvenlyCovered.of_trivialization (t := hc_triv hB)
    (by exact Metric.mem_ball_self hr)).to_isEvenlyCovered_preimage

theorem hc_exists_primitive (hU : IsOpen U) (hsc : IsSimplyConnected U)
    (hg : DifferentiableOn ℂ g U) : ∃ P : ℂ → ℂ, ∀ z ∈ U, HasDerivAt P (g z) z := by
  have := hsc.simplyConnectedSpace
  have := hU.locallyPathConnectedSpace
  obtain ⟨x₀, hx₀⟩ := hsc.nonempty
  let f : C(U, ℂ) := ⟨Subtype.val, continuous_subtype_val⟩
  obtain ⟨F, ⟨-, hF⟩, -⟩ := (hc_isCoveringMapOn_base (g := g) hU hg).existsUnique_continuousMap_lifts
    f (a₀ := ⟨x₀, hx₀⟩) (e₀ := (⟨x₀, 0⟩ : Etale g U)) rfl (fun a => a.2)
  have hb : ∀ w : U, (F w).base = w.1 := fun w => congrFun hF w
  classical
  refine ⟨fun z => if hz : z ∈ U then (F ⟨z, hz⟩).val else 0, fun x hx => ?_⟩
  obtain ⟨r, hr, hrU⟩ := Metric.isOpen_iff.1 hU x hx
  obtain ⟨G, hG⟩ := (hg.mono hrU).isExactOn_ball
  have hB : hc_IsLocPrim g U (Metric.ball x r) G := ⟨Metric.isOpen_ball, hrU, hG⟩
  set c := (F ⟨x, hx⟩).val - G x with hc
  have hS : hc_IsLocPrim g U (Metric.ball x r) (fun w => G w + c) :=
    ⟨hB.1, hB.2.1, fun w hw => (hB.2.2 w hw).add_const c⟩
  have hO : IsOpen (F ⁻¹' hc_sheet g U (Metric.ball x r) (fun w => G w + c)) :=
    F.continuous.isOpen_preimage _ (hc_isOpen_sheet hS)
  have hO' := hU.isOpenMap_subtype_val _ hO
  have hxO : x ∈ Subtype.val '' (F ⁻¹' hc_sheet g U (Metric.ball x r) (fun w => G w + c)) := by
    refine ⟨⟨x, hx⟩, ⟨?_, ?_⟩, rfl⟩
    · rw [hb]; exact Metric.mem_ball_self hr
    · rw [hb, hc]; ring
  have heq : (fun z => if hz : z ∈ U then (F ⟨z, hz⟩).val else 0) =ᶠ[nhds x]
      (fun w => G w + c) := by
    filter_upwards [hO'.mem_nhds hxO]
    rintro _ ⟨⟨w, hw⟩, hmem, rfl⟩
    simp only [hw, dite_true]
    rw [hmem.2, hb]
  exact ((hB.2.2 x (Metric.mem_ball_self hr)).add_const c).congr_of_eventuallyEq heq

#print axioms hc_IsLocPrim
#print axioms hc_sheet
#print axioms hc_continuous_base
#print axioms hc_isOpen_sheet
#print axioms hc_sec
#print axioms hc_continuous_sec
#print axioms hc_triv
#print axioms hc_isCoveringMapOn_base
#print axioms hc_exists_primitive

end HarmonicConjugateAux


theorem gradient_re_aux {f : ℂ → ℂ} {z a : ℂ} (h : HasDerivAt f a z) :
    gradient (fun w => (f w).re) z = (starRingEnd ℂ) a := by
  apply HasGradientAt.gradient
  rw [hasGradientAt_iff_hasFDerivAt]
  have h1 := Complex.reCLM.hasFDerivAt.comp z (h.hasFDerivAt.restrictScalars ℝ)
  have heq : (toDual ℝ ℂ) ((starRingEnd ℂ) a) =
      Complex.reCLM.comp ((ContinuousLinearMap.toSpanSingleton ℂ a).restrictScalars ℝ) := by
    refine ContinuousLinearMap.ext fun v => ?_
    rw [toDual_apply_apply, Complex.inner]
    simp [Complex.mul_re]
  rw [heq]
  exact h1

theorem gradient_im_aux {f : ℂ → ℂ} {z a : ℂ} (h : HasDerivAt f a z) :
    gradient (fun w => (f w).im) z = Complex.I * (starRingEnd ℂ) a := by
  apply HasGradientAt.gradient
  rw [hasGradientAt_iff_hasFDerivAt]
  have h1 := Complex.imCLM.hasFDerivAt.comp z (h.hasFDerivAt.restrictScalars ℝ)
  have heq : (toDual ℝ ℂ) (Complex.I * (starRingEnd ℂ) a) =
      Complex.imCLM.comp ((ContinuousLinearMap.toSpanSingleton ℂ a).restrictScalars ℝ) := by
    refine ContinuousLinearMap.ext fun v => ?_
    rw [toDual_apply_apply, Complex.inner]
    simp [Complex.mul_re, Complex.mul_im]
    try ring
  rw [heq]
  exact h1

#print axioms gradient_re_aux
#print axioms gradient_im_aux


/-- The card's main claim. Let f be holomorphic (complex differentiable at every point) on an
open region U, and write f = u + iv with u its real part and v its imaginary part. Then u and v
are both harmonic on U: each has continuous second partial derivatives near every point of U and
satisfies Laplace's equation u_xx + u_yy = 0 there. -/
theorem re_and_im_of_holomorphic_are_harmonic {f : ℂ → ℂ} {U : Set ℂ}
    (hU : IsOpen U) (hf : DifferentiableOn ℂ f U) :
    HarmonicOnNhd (fun z => (f z).re) U ∧ HarmonicOnNhd (fun z => (f z).im) U := by
  constructor
  · intro z hz
    exact (hf.analyticAt (hU.mem_nhds hz)).harmonicAt_re
  · intro z hz
    exact (hf.analyticAt (hU.mem_nhds hz)).harmonicAt_im


/-- Every harmonic function on a region without holes has a harmonic conjugate. If U is an open
simply connected region and u is harmonic on U, then there is a holomorphic F on U whose real
part is u; its imaginary part v is a partner making u + iv holomorphic on all of U. -/
theorem exists_harmonic_conjugate_of_simply_connected {u : ℂ → ℝ} {U : Set ℂ}
    (hU : IsOpen U) (hsc : IsSimplyConnected U) (hu : HarmonicOnNhd u U) :
    ∃ F : ℂ → ℂ, DifferentiableOn ℂ F U ∧ EqOn (fun z => (F z).re) u U := by
  let g := Complex.ofRealCLM ∘ (fderiv ℝ u · 1) - Complex.I • Complex.ofRealCLM ∘ (fderiv ℝ u · Complex.I)
  have hg : DifferentiableOn ℂ g U :=
    fun x hx ↦ (HarmonicAt.differentiableAt_complex_partial (hu x hx)).differentiableWithinAt
  obtain ⟨P, hP⟩ := HarmonicConjugateAux.hc_exists_primitive hU hsc hg
  have h₁P : DifferentiableOn ℂ P U := fun x hx => (hP x hx).differentiableAt.differentiableWithinAt
  have h₂P : DifferentiableOn ℝ (fun z => (P z).re) U :=
    Complex.reCLM.differentiable.comp_differentiableOn (h₁P.restrictScalars (𝕜 := ℝ) (𝕜' := ℂ))
  have hud : DifferentiableOn ℝ u U :=
    fun y hy ↦ (ContDiffAt.differentiableAt (hu y hy).1 two_ne_zero).differentiableWithinAt
  obtain ⟨a, ha⟩ := hU.exists_eq_add_of_fderiv_eq hsc.isPathConnected.isConnected.isPreconnected
    h₂P hud (by
      intro y hy
      have h₄F := (hP y hy).differentiableAt
      have h₅F := h₄F.restrictScalars (𝕜 := ℝ) (𝕜' := ℂ)
      rw [(by rfl : (fun z => (P z).re) = Complex.reCLM ∘ P), fderiv_comp y (by fun_prop) h₅F,
        ContinuousLinearMap.fderiv, h₄F.fderiv_restrictScalars (𝕜 := ℝ)]
      ext b
      nth_rw 2 [(by simp : b = b.re • (1 : ℂ) + b.im • (Complex.I : ℂ))]
      rw [map_add, map_smul, map_smul]
      simp [HasDerivAt.deriv (hP y hy), g])
  refine ⟨fun z => P z - (a : ℂ), ?_, ?_⟩
  · exact h₁P.sub_const _
  · intro z hz
    have := ha hz
    simp only at this
    simp [this]

/-- Right angles. Let f = u + iv be holomorphic on an open region U and let z be a point of U
where the derivative f'(z) is not zero. Then the gradients of u and of v at z are both nonzero
and their dot product u_x v_x + u_y v_y is 0. So the level curve of u through z and the level
curve of v through z cross at a right angle. -/
theorem level_curves_cross_at_right_angles {f : ℂ → ℂ} {U : Set ℂ} {z : ℂ}
    (hU : IsOpen U) (hf : DifferentiableOn ℂ f U) (hz : z ∈ U) (hf' : deriv f z ≠ 0) :
    gradient (fun w => (f w).re) z ≠ 0 ∧ gradient (fun w => (f w).im) z ≠ 0 ∧
      inner ℝ (gradient (fun w => (f w).re) z) (gradient (fun w => (f w).im) z) = 0 := by
  have hd : HasDerivAt f (deriv f z) z :=
    ((hf.differentiableAt (hU.mem_nhds hz))).hasDerivAt
  rw [gradient_re_aux hd, gradient_im_aux hd]
  refine ⟨?_, ?_, ?_⟩
  · simpa using hf'
  · simpa [Complex.I_ne_zero] using hf'
  · rw [Complex.inner]
    simp [Complex.mul_re, Complex.mul_im]
    ring

-- The plate: f = z^2 at P = 1 + 2i gives temperature u = 1^2 - 2^2 = -3 and partner v = 2xy = 4.
example : ((⟨1, 2⟩ : ℂ) ^ 2) = ⟨-3, 4⟩ := by
  apply Complex.ext <;> simp [pow_two] <;> norm_num

example : (1 : ℤ) ^ 2 - 2 ^ 2 = -3 := by norm_num

example : (2 : ℤ) * 1 * 2 = 4 := by norm_num

-- Second partials of u = x^2 - y^2 are 2 and -2: Laplacian 0. For x^2 + y^2 it is 2 + 2 = 4.
example : (2 : ℤ) + (-2) = 0 := by norm_num

example : (2 : ℤ) + 2 = 4 := by norm_num

-- Gradients at P: (2x, -2y) = (2, -4) and (2y, 2x) = (4, 2); dot product 2 * 4 + (-4) * 2 = 0.
example : (2 : ℤ) * 4 + (-4) * 2 = 0 := by norm_num

-- The partner built along the bottom then up the side: 0 + 2 * 2 = 4.
example : (0 : ℤ) + 2 * 2 = 4 := by norm_num

#print axioms re_and_im_of_holomorphic_are_harmonic
#print axioms exists_harmonic_conjugate_of_simply_connected
#print axioms level_curves_cross_at_right_angles
