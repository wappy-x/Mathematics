-- Self-adjoint extensions: a densely defined symmetric operator on a complex Hilbert space has a self-adjoint closure exactly when both deficiency indices are zero, by the ±i test.
import Mathlib.Analysis.InnerProductSpace.LinearPMap
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open scoped LinearPMap
open scoped ComplexConjugate

namespace SelfAdjointExtensions

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

theorem symm_inner_aux (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†)
    (u v : A.domain) : inner ℂ (A u) (v : H) = inner ℂ (u : H) (A v) := by
  have h := LinearPMap.adjoint_isFormalAdjoint hdense ⟨u, hsymm.1 u.2⟩ v
  rw [← hsymm.2 (x := u) (y := ⟨u, hsymm.1 u.2⟩) rfl] at h
  exact h

theorem inner_self_im_aux (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†)
    (u : A.domain) : (inner ℂ (A u) (u : H)).im = 0 := by
  have h := symm_inner_aux A hdense hsymm u u
  have h2 : conj (inner ℂ (A u) (u : H)) = inner ℂ (A u) (u : H) := by
    rw [inner_conj_symm]; exact h.symm
  exact Complex.conj_eq_iff_im.mp h2

/-- The norm identity `‖(A ± i)u‖² = ‖Au‖² + ‖u‖²` for a symmetric operator. -/
theorem norm_sq_add_I_smul_aux
    (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†) (u : A.domain) :
    ‖A u + Complex.I • (u : H)‖ ^ 2 = ‖A u‖ ^ 2 + ‖(u : H)‖ ^ 2 ∧
      ‖A u - Complex.I • (u : H)‖ ^ 2 = ‖A u‖ ^ 2 + ‖(u : H)‖ ^ 2 := by
  have h := inner_self_im_aux A hdense hsymm u
  constructor
  · rw [@norm_add_sq ℂ, inner_smul_right, norm_smul, Complex.norm_I, one_mul]
    simp [h]
  · rw [@norm_sub_sq ℂ, inner_smul_right, norm_smul, Complex.norm_I, one_mul]
    simp [h]


/-- Norm identity for the shifted operator `c • id +ᵥ T` with `c = ±i`. -/
theorem norm_vadd_sq_aux (T : H →ₗ.[ℂ] H) (hdense : Dense (T.domain : Set H)) (hsymm : T ≤ T†)
    {c : ℂ} (hc : c = Complex.I ∨ c = -Complex.I) (u : T.domain) :
    ‖((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T) u‖ ^ 2 = ‖T u‖ ^ 2 + ‖(u : H)‖ ^ 2 := by
  rw [LinearPMap.vadd_apply]
  have h := norm_sq_add_I_smul_aux T hdense hsymm u
  rcases hc with rfl | rfl
  · simpa [add_comm] using h.1
  · simpa [neg_smul, ← sub_eq_add_neg, add_comm, sub_eq_neg_add] using h.2

/-- A kernel vector of `T† + conj c` is orthogonal to the range of `T + c`. -/
theorem inner_vadd_eq_zero_aux (T : H →ₗ.[ℂ] H) (hdense : Dense (T.domain : Set H)) (c : ℂ)
    (y : T†.domain) (hy : T† y = -conj c • (y : H)) (x : T.domain) :
    inner ℂ (((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T) x) (y : H) = 0 := by
  rw [LinearPMap.vadd_apply, inner_add_left,
    (LinearPMap.adjoint_isFormalAdjoint hdense).symm x y, hy]
  simp [inner_smul_left, inner_smul_right]

/-- A vector orthogonal to the range of `T + c` lies in the kernel of `T† + conj c`. -/
theorem mem_adjoint_of_inner_vadd_aux (T : H →ₗ.[ℂ] H) (hdense : Dense (T.domain : Set H))
    (c : ℂ) (y : H) (h : ∀ x : T.domain,
      inner ℂ (((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T) x) y = 0) :
    ∃ hy : y ∈ T†.domain, T† ⟨y, hy⟩ = -conj c • y := by
  have key : ∀ x : T.domain, inner ℂ (-conj c • y) (x : H) = inner ℂ y (T x) := by
    intro x
    have hx := h x
    rw [LinearPMap.vadd_apply, inner_add_left] at hx
    have hx' : inner ℂ (T x) y = - inner ℂ (c • (x : H)) y := eq_neg_of_add_eq_zero_right hx
    rw [← inner_conj_symm y, hx', inner_smul_left, inner_smul_left]
    simp [inner_conj_symm]
  have hy : y ∈ T†.domain := LinearPMap.mem_adjoint_domain_of_exists y ⟨_, key⟩
  exact ⟨hy, LinearPMap.adjoint_apply_eq hdense ⟨y, hy⟩ key⟩


/-- For a closed symmetric operator, the range of `T ± i` is closed. -/
theorem isClosed_range_vadd_aux (T : H →ₗ.[ℂ] H) (hdense : Dense (T.domain : Set H))
    (hsymm : T ≤ T†) (hclosed : T.IsClosed) {c : ℂ} (hc : c = Complex.I ∨ c = -Complex.I) :
    IsClosed (LinearMap.range ((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun : Set H) := by
  have : IsClosed (T.graph : Set (H × H)) := hclosed
  have : CompleteSpace T.graph := IsClosed.completeSpace_coe (s := (T.graph : Set (H × H)))
  let Φ : (H × H) →L[ℂ] H :=
    ContinuousLinearMap.snd ℂ H H + c • ContinuousLinearMap.fst ℂ H H
  let g : T.graph →L[ℂ] H := Φ.comp T.graph.subtypeL
  have hg : AntilipschitzWith 1 g := by
    refine g.antilipschitz_of_bound fun p => ?_
    obtain ⟨⟨a, b⟩, hp⟩ := p
    obtain ⟨u, hu1, hu2⟩ := (T.mem_graph_iff).mp hp
    simp only at hu1 hu2
    subst hu1 hu2
    have hn := norm_vadd_sq_aux T hdense hsymm hc u
    rw [LinearPMap.vadd_apply, LinearMap.smul_apply, LinearMap.id_apply] at hn
    have hgp : g ⟨((u : H), T u), hp⟩ = c • (u : H) + T u := by
      simp [g, Φ, add_comm]
    rw [hgp, NNReal.coe_one, one_mul]
    show ‖((u : H), T u)‖ ≤ _
    rw [Prod.norm_def]
    apply max_le <;> dsimp only
    · nlinarith [norm_nonneg (u : H), norm_nonneg (c • (u : H) + T u), sq_nonneg ‖T u‖]
    · nlinarith [norm_nonneg (T u), norm_nonneg (c • (u : H) + T u), sq_nonneg ‖(u : H)‖]
  convert hg.isClosed_range g.uniformContinuous using 1
  ext z
  simp only [SetLike.mem_coe, LinearMap.mem_range, Set.mem_range]
  constructor
  · rintro ⟨u, rfl⟩
    refine ⟨⟨((u : H), T u), T.mem_graph u⟩, ?_⟩
    simp [g, Φ, add_comm]
  · rintro ⟨⟨⟨a, b⟩, hp⟩, rfl⟩
    obtain ⟨u, hu1, hu2⟩ := (T.mem_graph_iff).mp hp
    simp only at hu1 hu2
    subst hu1 hu2
    refine ⟨u, ?_⟩
    simp [g, Φ, add_comm]


/-- If `T + c` reaches every vector, then `T† + conj c` has trivial kernel. -/
theorem eq_zero_of_range_eq_top_aux (T : H →ₗ.[ℂ] H) (hdense : Dense (T.domain : Set H)) (c : ℂ)
    (htop : LinearMap.range ((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun = ⊤)
    (y : T†.domain) (hy : T† y = -conj c • (y : H)) : (y : H) = 0 := by
  have hyK : (y : H) ∈ LinearMap.range ((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun :=
    htop ▸ Submodule.mem_top
  obtain ⟨x, hx⟩ := LinearMap.mem_range.mp hyK
  have h0 := inner_vadd_eq_zero_aux T hdense c y hy x
  have hx' : ((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T) x = (y : H) := hx
  rw [hx'] at h0
  exact inner_self_eq_zero.mp h0

/-- For a closed symmetric operator, `T + c` (`c = ±i`) reaches every vector exactly when
`T† + conj c` has trivial kernel. -/
theorem range_vadd_eq_top_iff_aux (T : H →ₗ.[ℂ] H) (hdense : Dense (T.domain : Set H))
    (hsymm : T ≤ T†) (hclosed : T.IsClosed) {c : ℂ} (hc : c = Complex.I ∨ c = -Complex.I) :
    LinearMap.range ((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun = ⊤ ↔
      ∀ y : T†.domain, T† y = -conj c • (y : H) → (y : H) = 0 := by
  set K := LinearMap.range ((c • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun with hK
  constructor
  · exact eq_zero_of_range_eq_top_aux T hdense c
  · intro hker
    have hcl : IsClosed (K : Set H) := isClosed_range_vadd_aux T hdense hsymm hclosed hc
    have hperp : Kᗮ = ⊥ := by
      rw [Submodule.eq_bot_iff]
      intro y hy
      rw [Submodule.mem_orthogonal] at hy
      obtain ⟨hyd, hyeq⟩ := mem_adjoint_of_inner_vadd_aux T hdense c y
        (fun x => hy _ (LinearMap.mem_range_self _ x))
      exact hker ⟨y, hyd⟩ hyeq
    rw [← Submodule.topologicalClosure_eq_top_iff] at hperp
    rwa [hcl.submodule_topologicalClosure_eq] at hperp

/-- The extension step of the ±i test: if `T ± i` both reach every vector, then `T† ≤ T`. -/
theorem adjoint_le_of_range_aux (T : H →ₗ.[ℂ] H) (hdense : Dense (T.domain : Set H))
    (hsymm : T ≤ T†)
    (hp : LinearMap.range ((Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun = ⊤)
    (hm : LinearMap.range ((-Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun = ⊤) :
    T† ≤ T := by
  have hdom : T†.domain ≤ T.domain := by
    intro y hy
    set z : H := T† ⟨y, hy⟩ - Complex.I • y with hz
    have hzK : z ∈ LinearMap.range ((-Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).toFun :=
      hm ▸ Submodule.mem_top
    obtain ⟨x, hx⟩ := LinearMap.mem_range.mp hzK
    have hx' : -Complex.I • (x : H) + T x = z := by
      rw [← hx]; rfl
    let x' : T†.domain := ⟨x, hsymm.1 x.2⟩
    have hTx : T x = T† x' := hsymm.2 rfl
    let w : T†.domain := ⟨y, hy⟩ - x'
    have hsub : T† w = T† ⟨y, hy⟩ - T† x' := T†.toFun.map_sub _ _
    have hw : T† w = -conj Complex.I • (w : H) := by
      rw [hsub, ← hTx]
      have : T x = z + Complex.I • (x : H) := by
        rw [← hx']; simp
      rw [this, hz]
      simp only [w, Submodule.coe_sub, Complex.conj_I, neg_neg, smul_sub]
      abel
    have hw0 : (w : H) = 0 := eq_zero_of_range_eq_top_aux T hdense _ hp w hw
    have hyx : y = (x : H) := by
      have : (w : H) = y - x := rfl
      rw [hw0] at this
      exact (sub_eq_zero.mp this.symm)
    rw [hyx]; exact x.2
  refine ⟨hdom, fun a b hab => ?_⟩
  have := hsymm.2 (x := b) (y := a) hab.symm
  exact this.symm


/-- Facts about the closure of a densely defined symmetric operator: it is closed, densely
defined, has the same adjoint, and is again symmetric. -/
theorem closure_facts_aux (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†) :
    A.closure.IsClosed ∧ Dense (A.closure.domain : Set H) ∧ A.closure† = A† ∧
      A.closure ≤ A.closure† := by
  have hcl : A.IsClosable := LinearPMap.isClosable_iff_exists_closed_extension.mpr
    ⟨A†, LinearPMap.adjoint_isClosed hdense, hsymm⟩
  have hBd : Dense (A.closure.domain : Set H) := hdense.mono A.le_closure.1
  have hBle : A.closure ≤ A† := by
    apply LinearPMap.le_of_le_graph
    rw [← hcl.graph_closure_eq_closure_graph]
    exact Submodule.topologicalClosure_minimal _ (LinearPMap.le_graph_of_le hsymm)
      (LinearPMap.adjoint_isClosed hdense)
  have h1 : A.closure† ≤ A† := by
    apply LinearPMap.IsFormalAdjoint.le_adjoint hdense
    intro x y
    have := (LinearPMap.adjoint_isFormalAdjoint hBd).symm ⟨x, A.le_closure.1 x.2⟩ y
    rw [← A.le_closure.2 (x := x) rfl] at this
    exact this
  have h2 : A† ≤ A.closure† := by
    apply LinearPMap.IsFormalAdjoint.le_adjoint hBd
    intro x y
    have hS : IsClosed {p : H × H | inner ℂ p.2 (y : H) = inner ℂ p.1 (A† y)} :=
      isClosed_eq (by fun_prop) (by fun_prop)
    have hsub : (A.graph : Set (H × H)) ⊆ {p : H × H | inner ℂ p.2 (y : H) = inner ℂ p.1 (A† y)} := by
      intro p hp
      obtain ⟨u, hu1, hu2⟩ := (A.mem_graph_iff).mp hp
      simp only [Set.mem_ofPred_eq, ← hu1, ← hu2]
      exact (LinearPMap.adjoint_isFormalAdjoint hdense).symm u y
    have hmem : ((x : H), A.closure x) ∈ (A.graph.topologicalClosure : Set (H × H)) := by
      rw [hcl.graph_closure_eq_closure_graph]
      exact A.closure.mem_graph x
    rw [Submodule.topologicalClosure_coe] at hmem
    exact closure_minimal hsub hS hmem
  have hBadj : A.closure† = A† := le_antisymm h1 h2
  exact ⟨hcl.closure_isClosed, hBd, hBadj, hBadj ▸ hBle⟩

omit [CompleteSpace H] in
/-- Rank zero of the kernel of `T + d` means: `T y = e • y` forces `y = 0`, where `d = -e`. -/
theorem rank_ker_vadd_eq_zero_iff_aux (T : H →ₗ.[ℂ] H) {d e : ℂ} (he : d = -e) :
    Module.rank ℂ ((d • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).ker = 0 ↔
      ∀ y : T.domain, T y = e • (y : H) → (y : H) = 0 := by
  rw [rank_zero_iff_forall_zero]
  constructor
  · intro h y hy
    have hmem : (y : H) ∈ ((d • LinearMap.id : H →ₗ[ℂ] H) +ᵥ T).ker :=
      LinearPMap.mem_ker_iff.mpr ⟨y, rfl, by
        rw [LinearPMap.vadd_apply, LinearMap.smul_apply, LinearMap.id_apply]
        show d • (y : H) + T y = 0
        rw [hy, he, neg_smul, neg_add_cancel]⟩
    exact congrArg Subtype.val (h ⟨y, hmem⟩)
  · rintro h ⟨x, hx⟩
    obtain ⟨y, rfl, hy⟩ := LinearPMap.mem_ker_iff.mp hx
    rw [LinearPMap.vadd_apply, LinearMap.smul_apply, LinearMap.id_apply] at hy
    have hy' : d • (y : H) + T y = 0 := hy
    ext
    apply h y
    rw [he, neg_smul] at hy'
    exact (neg_add_eq_zero.mp hy').symm

/-- The ±i test for a closed, densely defined symmetric operator. -/
theorem isSelfAdjoint_iff_range_aux
    (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†)
    (hclosed : A.IsClosed) :
    IsSelfAdjoint A ↔
      LinearMap.range ((Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ A).toFun = ⊤ ∧
      LinearMap.range ((-Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ A).toFun = ⊤ := by
  constructor
  · intro hsa
    have hadj : A† = A := hsa
    have hdense' : Dense (A†.domain : Set H) := by rw [hadj]; exact hdense
    have hsymm' : A† ≤ A†† := by rw [hadj, hadj]
    have hker : ∀ c : ℂ, (c = Complex.I ∨ c = -Complex.I) →
        ∀ y : A†.domain, A† y = -conj c • (y : H) → (y : H) = 0 := by
      intro c hc y hy
      have hc' : conj c = Complex.I ∨ conj c = -Complex.I := by
        rcases hc with rfl | rfl <;> simp
      have hn := norm_vadd_sq_aux A† hdense' hsymm' hc' y
      rw [LinearPMap.vadd_apply, LinearMap.smul_apply, LinearMap.id_apply, hy, neg_smul,
        add_neg_cancel, norm_zero] at hn
      have : ‖(y : H)‖ ^ 2 = 0 := by nlinarith [sq_nonneg ‖A† y‖, sq_nonneg ‖(y : H)‖]
      exact norm_eq_zero.mp (pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this)
    exact ⟨(range_vadd_eq_top_iff_aux A hdense hsymm hclosed (Or.inl rfl)).mpr
        (hker _ (Or.inl rfl)),
      (range_vadd_eq_top_iff_aux A hdense hsymm hclosed (Or.inr rfl)).mpr
        (hker _ (Or.inr rfl))⟩
  · rintro ⟨hp, hm⟩
    exact le_antisymm (adjoint_le_of_range_aux A hdense hsymm hp hm) hsymm

/-- Essential self-adjointness by counting (von Neumann's first criterion, proved on the card by
the ±i test). Let `A` be a densely defined symmetric operator on a complex Hilbert space `H`:
its adjoint `A†` agrees with `A` on the domain of `A` (`A ≤ A†`). Then the closure of `A` is
self-adjoint exactly when both deficiency indices are zero:
`n₊ = dim ker (A† - i) = 0` and `n₋ = dim ker (A† + i) = 0`.
Here `A† - i` is `A†` shifted by `-i` times the identity, on the same domain as `A†`. -/
theorem closure_isSelfAdjoint_iff_deficiency_indices_zero
    (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†) :
    IsSelfAdjoint A.closure ↔
      Module.rank ℂ ((-Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ A†).ker = 0 ∧
      Module.rank ℂ ((Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ A†).ker = 0 := by
  obtain ⟨hBcl, hBd, hBadj, hBsymm⟩ := closure_facts_aux A hdense hsymm
  rw [isSelfAdjoint_iff_range_aux A.closure hBd hBsymm hBcl,
    range_vadd_eq_top_iff_aux A.closure hBd hBsymm hBcl (Or.inl rfl),
    range_vadd_eq_top_iff_aux A.closure hBd hBsymm hBcl (Or.inr rfl), hBadj,
    rank_ker_vadd_eq_zero_iff_aux A† (e := -conj Complex.I) (by simp),
    rank_ker_vadd_eq_zero_iff_aux A† (e := -conj (-Complex.I)) (by simp)]

/-- The ±i test for a closed operator. A closed, densely defined, symmetric operator `A` on a
complex Hilbert space is self-adjoint exactly when `A + i` and `A - i` both reach every vector
of `H`. -/
theorem isSelfAdjoint_iff_range_add_I_and_sub_I_eq_top
    (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†)
    (hclosed : A.IsClosed) :
    IsSelfAdjoint A ↔
      LinearMap.range ((Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ A).toFun = ⊤ ∧
      LinearMap.range ((-Complex.I • LinearMap.id : H →ₗ[ℂ] H) +ᵥ A).toFun = ⊤ := by
  exact isSelfAdjoint_iff_range_aux A hdense hsymm hclosed

/-- Shifting by ±i never shrinks a vector: for a densely defined symmetric operator `A` and every
`u` in its domain, `‖(A ± i)u‖² = ‖Au‖² + ‖u‖²`, because the cross terms cancel. -/
theorem norm_sq_add_I_smul_eq_of_symmetric
    (A : H →ₗ.[ℂ] H) (hdense : Dense (A.domain : Set H)) (hsymm : A ≤ A†) (u : A.domain) :
    ‖A u + Complex.I • (u : H)‖ ^ 2 = ‖A u‖ ^ 2 + ‖(u : H)‖ ^ 2 ∧
      ‖A u - Complex.I • (u : H)‖ ^ 2 = ‖A u‖ ^ 2 + ‖(u : H)‖ ^ 2 := by
  exact norm_sq_add_I_smul_aux A hdense hsymm u


/- The card's Step 1 end terms `[-u'·v + u·v']` from 0 to 1, with `Au = -u''`. -/

-- held with insulated: u = x(1 - x), v = 1; the mirror test is off by 2.
example :
    (-(1 - 2 * (1 : ℚ)) * 1 + 1 * (1 - 1) * 0) - (-(1 - 2 * (0 : ℚ)) * 1 + 0 * (1 - 0) * 0) = 2 := by
  norm_num

-- held with held: u = x(1 - x), v = sin(πx); the end terms are 0.
example :
    (-(1 - 2 * (1 : ℝ)) * Real.sin (Real.pi * 1) + 1 * (1 - 1) * (Real.pi * Real.cos (Real.pi * 1)))
      - (-(1 - 2 * (0 : ℝ)) * Real.sin (Real.pi * 0) + 0 * (1 - 0) * (Real.pi * Real.cos (Real.pi * 0)))
      = 0 := by
  norm_num [Real.sin_pi]

-- insulated with insulated: u = x² - 2x³/3, v = cos(πx); the end terms are 0.
example :
    (-(2 * (1 : ℝ) - 2 * 1 ^ 2) * Real.cos (Real.pi * 1)
        + (1 ^ 2 - 2 * 1 ^ 3 / 3) * (-Real.pi * Real.sin (Real.pi * 1)))
      - (-(2 * (0 : ℝ) - 2 * 0 ^ 2) * Real.cos (Real.pi * 0)
        + (0 ^ 2 - 2 * 0 ^ 3 / 3) * (-Real.pi * Real.sin (Real.pi * 0)))
      = 0 := by
  norm_num [Real.sin_pi]

end SelfAdjointExtensions

open SelfAdjointExtensions

#print axioms symm_inner_aux
#print axioms inner_self_im_aux
#print axioms norm_sq_add_I_smul_aux
#print axioms norm_vadd_sq_aux
#print axioms inner_vadd_eq_zero_aux
#print axioms mem_adjoint_of_inner_vadd_aux
#print axioms isClosed_range_vadd_aux
#print axioms eq_zero_of_range_eq_top_aux
#print axioms range_vadd_eq_top_iff_aux
#print axioms adjoint_le_of_range_aux
#print axioms closure_facts_aux
#print axioms rank_ker_vadd_eq_zero_iff_aux
#print axioms isSelfAdjoint_iff_range_aux
#print axioms closure_isSelfAdjoint_iff_deficiency_indices_zero
#print axioms isSelfAdjoint_iff_range_add_I_and_sub_I_eq_top
#print axioms norm_sq_add_I_smul_eq_of_symmetric
