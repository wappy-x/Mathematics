-- Ext: Ext¹ built from a projective resolution matches the extensions 0 → N → E → M → 0 one for one up to equivalence, with 0 matching the split one, and over ℤ the resolution of ℤ/m gives Hom(ℤ/m, N) = N[m] and Ext¹(ℤ/m, N) = N/mN.
import Mathlib.Algebra.Exact.Basic
import Mathlib.Algebra.Module.Projective
import Mathlib.Algebra.Group.Subgroup.Pointwise
import Mathlib.GroupTheory.QuotientGroup.Defs
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.GroupTheory.QuotientGroup.Basic
import Mathlib.LinearAlgebra.Span.Basic

universe u

open Function

namespace ExtCard

variable {R : Type u} [Ring R]

/-- Running a map `d : A → B` backwards: a map `B → N` becomes the map `A → N` that first does `d`. -/
def precomp (N : Type u) [AddCommGroup N] [Module R N] {A B : Type u} [AddCommGroup A] [Module R A]
    [AddCommGroup B] [Module R B] (d : A →ₗ[R] B) : (B →ₗ[R] N) →+ (A →ₗ[R] N) where
  toFun φ := φ ∘ₗ d
  map_zero' := LinearMap.zero_comp d
  map_add' φ ψ := LinearMap.add_comp d ψ φ

/-- Ext¹ read off the resolution pieces `P₂ → P₁ → P₀`: maps `P₁ → N` that die on `P₂`
(the kernel of `d₂*`), with those that come from `P₀` (the image of `d₁*`) counted as zero. -/
abbrev Ext1 (N : Type u) [AddCommGroup N] [Module R N] {P₀ P₁ P₂ : Type u}
    [AddCommGroup P₀] [Module R P₀] [AddCommGroup P₁] [Module R P₁] [AddCommGroup P₂] [Module R P₂]
    (d₁ : P₁ →ₗ[R] P₀) (d₂ : P₂ →ₗ[R] P₁) : Type u :=
  (precomp N d₂).ker ⧸ (precomp N d₁).range.addSubgroupOf (precomp N d₂).ker

/-- An extension of M by N: an exact sequence `0 → N → E → M → 0`. -/
structure Extension (R : Type u) [Ring R] (M N : Type u) [AddCommGroup M] [Module R M]
    [AddCommGroup N] [Module R N] where
  E : Type u
  [addCommGroup : AddCommGroup E]
  [module : Module R E]
  i : N →ₗ[R] E
  p : E →ₗ[R] M
  injective_i : Injective i
  surjective_p : Surjective p
  exact : Exact i p

attribute [instance] Extension.addCommGroup Extension.module

variable {M N : Type u} [AddCommGroup M] [Module R M] [AddCommGroup N] [Module R N]

/-- Two extensions are equivalent when an isomorphism of the middle modules fixes the copy of N
and the map onto M. -/
def Extension.Equiv (X Y : Extension R M N) : Prop :=
  ∃ e : X.E ≃ₗ[R] Y.E, e.toLinearMap ∘ₗ X.i = Y.i ∧ Y.p ∘ₗ e.toLinearMap = X.p

/-- The split extension `0 → N → N ⊕ M → M → 0`, with no carry. -/
def Extension.split (R : Type u) [Ring R] (M N : Type u) [AddCommGroup M] [Module R M]
    [AddCommGroup N] [Module R N] : Extension R M N where
  E := N × M
  i := LinearMap.inl R N M
  p := LinearMap.snd R N M
  injective_i := LinearMap.inl_injective
  surjective_p := LinearMap.snd_surjective
  exact := Exact.inl_snd

/-- Equivalence of extensions runs both ways. -/
theorem Extension.equiv_symm {X Y : Extension R M N} (h : Extension.Equiv X Y) :
    Extension.Equiv Y X := by
  obtain ⟨e, h1, h2⟩ := h
  refine ⟨e.symm, ?_, ?_⟩
  · rw [← h1]; ext x; simp
  · rw [← h2]; ext x; simp

/-- Equivalence of extensions chains. -/
theorem Extension.equiv_trans {X Y Z : Extension R M N} (h : Extension.Equiv X Y)
    (h' : Extension.Equiv Y Z) : Extension.Equiv X Z := by
  obtain ⟨e, h1, h2⟩ := h
  obtain ⟨e', h1', h2'⟩ := h'
  refine ⟨e.trans e', ?_, ?_⟩
  · rw [← h1', ← h1]; ext x; simp
  · rw [← h2, ← h2']; ext x; simp

/-- A map from a projective module whose values lie in the image of `i` factors through `i`. -/
theorem lift_into_range {P E N' : Type u} [AddCommGroup P] [Module R P] [Module.Projective R P]
    [AddCommGroup E] [Module R E] [AddCommGroup N'] [Module R N']
    (i : N' →ₗ[R] E) (g : P →ₗ[R] E) (hg : ∀ x, g x ∈ Set.range i) :
    ∃ h : P →ₗ[R] N', i ∘ₗ h = g := by
  obtain ⟨h, hh⟩ := Module.projective_lifting_property i.rangeRestrict
    (g.codRestrict _ fun x => LinearMap.mem_range.mpr (hg x)) i.surjective_rangeRestrict
  refine ⟨h, ?_⟩
  ext x
  have := congrArg Subtype.val (LinearMap.congr_fun hh x)
  simpa using this

section Std

variable {P₀ P₁ P₂ : Type u} [AddCommGroup P₀] [Module R P₀] [AddCommGroup P₁] [Module R P₁]
    [AddCommGroup P₂] [Module R P₂]
    (ε : P₀ →ₗ[R] M) (d₁ : P₁ →ₗ[R] P₀) (d₂ : P₂ →ₗ[R] P₁)
    (hε : Surjective ε) (h₀ : Exact d₁ ε) (h₁ : Exact d₂ d₁)

/-- The relations of the standard extension: the pairs `(-φ x, d₁ x)`. -/
abbrev stdRel (φ : P₁ →ₗ[R] N) : Submodule R (N × P₀) :=
  LinearMap.range ((-φ).prod d₁)

/-- The standard extension built from `φ`: `(N × P₀)` with `(-φ x, d₁ x)` counted as zero. -/
@[reducible] def stdExt (φ : P₁ →ₗ[R] N) (hφ₂ : φ ∘ₗ d₂ = 0) : Extension R M N where
  E := (N × P₀) ⧸ stdRel d₁ φ
  i := (stdRel d₁ φ).mkQ ∘ₗ LinearMap.inl R N P₀
  p := (stdRel d₁ φ).liftQ (ε ∘ₗ LinearMap.snd R N P₀) (by
    rintro _ ⟨x, rfl⟩
    simp [h₀.apply_apply_eq_zero])
  injective_i := by
    rw [injective_iff_map_eq_zero]
    intro n hn
    simp only [LinearMap.coe_comp, comp_apply, Submodule.mkQ_apply, LinearMap.inl_apply,
      Submodule.Quotient.mk_eq_zero] at hn
    obtain ⟨x, hx⟩ := hn
    have hx1 : -φ x = n := congrArg Prod.fst hx
    have hx2 : d₁ x = 0 := congrArg Prod.snd hx
    obtain ⟨y, rfl⟩ := (h₁ x).mp hx2
    have : φ (d₂ y) = 0 := LinearMap.congr_fun hφ₂ y
    rw [← hx1, this, neg_zero]
  surjective_p := by
    intro m
    obtain ⟨a, rfl⟩ := hε m
    exact ⟨Submodule.Quotient.mk (0, a), by simp⟩
  exact := by
    intro z
    refine ⟨fun hz => ?_, ?_⟩
    · obtain ⟨⟨n, a⟩, rfl⟩ := Submodule.Quotient.mk_surjective _ z
      simp at hz
      obtain ⟨y, rfl⟩ := (h₀ a).mp hz
      refine ⟨n + φ y, ?_⟩
      simp only [LinearMap.coe_comp, comp_apply, Submodule.mkQ_apply, LinearMap.inl_apply]
      rw [Submodule.Quotient.eq]
      exact ⟨-y, by ext <;> simp⟩
    · rintro ⟨n, rfl⟩
      simp

/-- The lift of `ε` into the standard extension. -/
def stdLam (φ : P₁ →ₗ[R] N) : P₀ →ₗ[R] (N × P₀) ⧸ stdRel d₁ φ :=
  (stdRel d₁ φ).mkQ ∘ₗ LinearMap.inr R N P₀

theorem stdLam_p (φ : P₁ →ₗ[R] N) (hφ₂ : φ ∘ₗ d₂ = 0) :
    (stdExt ε d₁ d₂ hε h₀ h₁ φ hφ₂).p ∘ₗ stdLam d₁ φ = ε := by
  ext a; simp [stdLam]

theorem stdLam_i (φ : P₁ →ₗ[R] N) (hφ₂ : φ ∘ₗ d₂ = 0) :
    (stdExt ε d₁ d₂ hε h₀ h₁ φ hφ₂).i ∘ₗ φ = stdLam d₁ φ ∘ₗ d₁ := by
  ext x
  simp only [stdExt, stdLam, LinearMap.coe_comp, comp_apply, Submodule.mkQ_apply,
    LinearMap.inl_apply, LinearMap.inr_apply]
  rw [Submodule.Quotient.eq]
  exact ⟨-x, by ext <;> simp⟩

/-- Any extension with a lift `lam` and its `φ` is equivalent to the standard one built from `φ`. -/
theorem std_equiv (X : Extension R M N) (lam : P₀ →ₗ[R] X.E) (φ : P₁ →ₗ[R] N)
    (hlam : X.p ∘ₗ lam = ε) (hφ : X.i ∘ₗ φ = lam ∘ₗ d₁) (hφ₂ : φ ∘ₗ d₂ = 0) :
    Extension.Equiv (stdExt ε d₁ d₂ hε h₀ h₁ φ hφ₂) X := by
  have hφx : ∀ x, X.i (φ x) = lam (d₁ x) := LinearMap.congr_fun hφ
  have hlam' : ∀ a, X.p (lam a) = ε a := LinearMap.congr_fun hlam
  have hrel : stdRel d₁ φ ≤ LinearMap.ker (X.i.coprod lam) := by
    rintro _ ⟨x, rfl⟩
    simp [hφx]
  let g : (N × P₀) ⧸ stdRel d₁ φ →ₗ[R] X.E := (stdRel d₁ φ).liftQ (X.i.coprod lam) hrel
  have hbij : Bijective g := by
    constructor
    · rw [injective_iff_map_eq_zero]
      intro z hz
      obtain ⟨⟨n, a⟩, rfl⟩ := Submodule.Quotient.mk_surjective _ z
      simp only [g, Submodule.liftQ_apply, LinearMap.coprod_apply] at hz
      have h2 : ε a = 0 := by
        have := congrArg X.p hz
        simpa [hlam', X.exact.apply_apply_eq_zero] using this
      obtain ⟨y, rfl⟩ := (h₀ a).mp h2
      have h3 : X.i (n + φ y) = 0 := by
        rw [map_add, hφx]; exact hz
      have h4 : n + φ y = 0 := X.injective_i (h3.trans (map_zero X.i).symm)
      rw [Submodule.Quotient.mk_eq_zero]
      exact ⟨y, by ext <;> simp [eq_neg_of_add_eq_zero_left h4]⟩
    · intro e
      obtain ⟨a, ha⟩ := hε (X.p e)
      have : X.p (e - lam a) = 0 := by simp [hlam', ha]
      obtain ⟨n, hn⟩ := (X.exact _).mp this
      refine ⟨Submodule.Quotient.mk (n, a), ?_⟩
      simp [g, hn]
  refine ⟨LinearEquiv.ofBijective g hbij, ?_, ?_⟩
  · ext n; simp [g]
  · apply LinearMap.ext; intro z
    obtain ⟨⟨n, a⟩, rfl⟩ := Submodule.Quotient.mk_surjective _ z
    simp [g, hlam', X.exact.apply_apply_eq_zero]

include hε h₀ h₁ in
theorem equiv_of_class_eq (X Y : Extension R M N) (lam : P₀ →ₗ[R] X.E) (φ : P₁ →ₗ[R] N)
    (hlam : X.p ∘ₗ lam = ε) (hφ : X.i ∘ₗ φ = lam ∘ₗ d₁) (hφ₂ : φ ∘ₗ d₂ = 0)
    (lam' : P₀ →ₗ[R] Y.E) (φ' : P₁ →ₗ[R] N)
    (hlam' : Y.p ∘ₗ lam' = ε) (hφ' : Y.i ∘ₗ φ' = lam' ∘ₗ d₁) (hφ₂' : φ' ∘ₗ d₂ = 0)
    (h : (QuotientAddGroup.mk ⟨φ, hφ₂⟩ : Ext1 N d₁ d₂) = QuotientAddGroup.mk ⟨φ', hφ₂'⟩) :
    Extension.Equiv X Y := by
  rw [QuotientAddGroup.eq, AddSubgroup.mem_addSubgroupOf] at h
  obtain ⟨ψ, hψ⟩ := h
  have hψx : ∀ x, ψ (d₁ x) = -φ x + φ' x := fun x => LinearMap.congr_fun hψ x
  refine Extension.equiv_trans
    (Extension.equiv_symm (std_equiv ε d₁ d₂ hε h₀ h₁ X lam φ hlam hφ hφ₂))
    (std_equiv ε d₁ d₂ hε h₀ h₁ Y (lam' - Y.i ∘ₗ ψ) φ ?_ ?_ hφ₂)
  · ext a
    have := LinearMap.congr_fun hlam' a
    simp only [LinearMap.coe_comp, comp_apply] at this
    simp [this, Y.exact.apply_apply_eq_zero]
  · ext x
    have := LinearMap.congr_fun hφ' x
    simp only [LinearMap.coe_comp, comp_apply] at this
    simp [← this, hψx]

variable [Module.Projective R P₀] [Module.Projective R P₁]

include h₀ h₁ in
/-- Every extension has a lift `lam` and a `φ`. -/
theorem exists_data (X : Extension R M N) : ∃ φ : (precomp N d₂).ker, ∃ lam : P₀ →ₗ[R] X.E,
    X.p ∘ₗ lam = ε ∧ X.i ∘ₗ φ.1 = lam ∘ₗ d₁ := by
  obtain ⟨lam, hlam⟩ := Module.projective_lifting_property X.p ε X.surjective_p
  have hlam' : ∀ a, X.p (lam a) = ε a := LinearMap.congr_fun hlam
  obtain ⟨φ, hφ⟩ := lift_into_range X.i (lam ∘ₗ d₁) (fun x => (X.exact _).mp (by
    simp [hlam', h₀.apply_apply_eq_zero]))
  have hφ₂ : φ ∘ₗ d₂ = 0 := by
    ext y; apply X.injective_i
    have := LinearMap.congr_fun hφ (d₂ y)
    simp only [LinearMap.coe_comp, comp_apply] at this
    simp [this, h₁.apply_apply_eq_zero]
  exact ⟨⟨φ, hφ₂⟩, lam, hlam, hφ⟩

omit [Module.Projective R P₁] in
/-- Two choices of lift give the same class. -/
theorem class_eq_of_data (X : Extension R M N) (lam lam' : P₀ →ₗ[R] X.E) (φ φ' : P₁ →ₗ[R] N)
    (hlam : X.p ∘ₗ lam = ε) (hφ : X.i ∘ₗ φ = lam ∘ₗ d₁) (hφ₂ : φ ∘ₗ d₂ = 0)
    (hlam' : X.p ∘ₗ lam' = ε) (hφ' : X.i ∘ₗ φ' = lam' ∘ₗ d₁) (hφ₂' : φ' ∘ₗ d₂ = 0) :
    (QuotientAddGroup.mk ⟨φ, hφ₂⟩ : Ext1 N d₁ d₂) = QuotientAddGroup.mk ⟨φ', hφ₂'⟩ := by
  have e1 : ∀ a, X.p (lam a) = ε a := LinearMap.congr_fun hlam
  have e2 : ∀ a, X.p (lam' a) = ε a := LinearMap.congr_fun hlam'
  obtain ⟨ψ, hψ⟩ := lift_into_range X.i (lam' - lam) (fun a => (X.exact _).mp (by simp [e1, e2]))
  rw [QuotientAddGroup.eq, AddSubgroup.mem_addSubgroupOf]
  refine ⟨ψ, ?_⟩
  show ψ ∘ₗ d₁ = -φ + φ'
  apply LinearMap.ext; intro x
  apply X.injective_i
  have k1 := LinearMap.congr_fun hφ x
  have k2 := LinearMap.congr_fun hφ' x
  have k3 := LinearMap.congr_fun hψ (d₁ x)
  simp only [LinearMap.coe_comp, comp_apply, LinearMap.sub_apply] at k1 k2 k3
  simp only [LinearMap.coe_comp, comp_apply, LinearMap.add_apply, LinearMap.neg_apply, map_add,
    map_neg, k1, k2, k3]
  abel

/-- The class of an extension, from a chosen lift. -/
noncomputable def classOf (X : Extension R M N) : Ext1 N d₁ d₂ :=
  QuotientAddGroup.mk (exists_data ε d₁ d₂ h₀ h₁ X).choose

theorem classOf_spec (X : Extension R M N) (lam : P₀ →ₗ[R] X.E) (φ : P₁ →ₗ[R] N)
    (hlam : X.p ∘ₗ lam = ε) (hφ : X.i ∘ₗ φ = lam ∘ₗ d₁) (hφ₂ : φ ∘ₗ d₂ = 0) :
    classOf ε d₁ d₂ h₀ h₁ X = QuotientAddGroup.mk (⟨φ, hφ₂⟩ : (precomp N d₂).ker) := by
  obtain ⟨lam', h1, h2⟩ := (exists_data ε d₁ d₂ h₀ h₁ X).choose_spec
  exact class_eq_of_data ε d₁ d₂ X lam' lam _ φ h1 h2 _ hlam hφ hφ₂

theorem classOf_respects (X Y : Extension R M N) (h : Extension.Equiv X Y) :
    classOf ε d₁ d₂ h₀ h₁ X = classOf ε d₁ d₂ h₀ h₁ Y := by
  obtain ⟨e, he1, he2⟩ := h
  obtain ⟨φ, lam, h1, h2⟩ := exists_data ε d₁ d₂ h₀ h₁ X
  rw [classOf_spec ε d₁ d₂ h₀ h₁ X lam φ.1 h1 h2 φ.2]
  refine (classOf_spec ε d₁ d₂ h₀ h₁ Y (e.toLinearMap ∘ₗ lam) φ.1 ?_ ?_ φ.2).symm
  · rw [← h1, ← he2]; rfl
  · rw [← he1, LinearMap.comp_assoc, h2]; rfl

end Std

/-- Ext¹ classifies extensions. Take a projective resolution `P₂ → P₁ → P₀ → M → 0` of M
(only its first three pieces matter for Ext¹). Then the members of Ext¹(M, N) match the
extensions `0 → N → E → M → 0`, counted up to equivalence, one for one. The match is the
recipe of the card: lift `P₀ → M` to `λ : P₀ → E`; on `P₁` it lands in N as `φ`, and the
extension goes to the class of `φ`. Zero matches the split extension `N ⊕ M`. -/
theorem ext_one_classifies_extensions
    {P₀ P₁ P₂ : Type u} [AddCommGroup P₀] [Module R P₀] [AddCommGroup P₁] [Module R P₁]
    [AddCommGroup P₂] [Module R P₂]
    [Module.Projective R P₀] [Module.Projective R P₁] [Module.Projective R P₂]
    (ε : P₀ →ₗ[R] M) (d₁ : P₁ →ₗ[R] P₀) (d₂ : P₂ →ₗ[R] P₁)
    (hε : Surjective ε) (h₀ : Exact d₁ ε) (h₁ : Exact d₂ d₁) :
    ∃ f : Quot (@Extension.Equiv R _ M N _ _ _ _) ≃ Ext1 N d₁ d₂,
      (∀ (X : Extension R M N) (lam : P₀ →ₗ[R] X.E) (φ : P₁ →ₗ[R] N)
          (_hlam : X.p ∘ₗ lam = ε) (_hφ : X.i ∘ₗ φ = lam ∘ₗ d₁) (hφ₂ : φ ∘ₗ d₂ = 0),
          f (Quot.mk _ X) = QuotientAddGroup.mk (⟨φ, hφ₂⟩ : (precomp N d₂).ker)) ∧
      f (Quot.mk _ (Extension.split R M N)) = 0 := by
  classical
  let F : Quot (@Extension.Equiv R _ M N _ _ _ _) → Ext1 N d₁ d₂ :=
    Quot.lift (classOf ε d₁ d₂ h₀ h₁) (fun X Y h => classOf_respects ε d₁ d₂ h₀ h₁ X Y h)
  have hspec : ∀ (X : Extension R M N) (lam : P₀ →ₗ[R] X.E) (φ : P₁ →ₗ[R] N)
      (_hlam : X.p ∘ₗ lam = ε) (_hφ : X.i ∘ₗ φ = lam ∘ₗ d₁) (hφ₂ : φ ∘ₗ d₂ = 0),
      F (Quot.mk _ X) = QuotientAddGroup.mk (⟨φ, hφ₂⟩ : (precomp N d₂).ker) :=
    fun X lam φ hlam hφ hφ₂ => classOf_spec ε d₁ d₂ h₀ h₁ X lam φ hlam hφ hφ₂
  have hinj : Injective F := by
    intro a b hab
    induction a using Quot.ind with
    | mk X =>
    induction b using Quot.ind with
    | mk Y =>
    apply Quot.sound
    obtain ⟨φX, lamX, h1, h2⟩ := exists_data ε d₁ d₂ h₀ h₁ X
    obtain ⟨φY, lamY, h3, h4⟩ := exists_data ε d₁ d₂ h₀ h₁ Y
    rw [hspec X lamX φX.1 h1 h2 φX.2, hspec Y lamY φY.1 h3 h4 φY.2] at hab
    exact equiv_of_class_eq ε d₁ d₂ hε h₀ h₁ X Y lamX φX.1 h1 h2 φX.2 lamY φY.1 h3 h4 φY.2 hab
  have hsurj : Surjective F := by
    intro c
    obtain ⟨⟨φ, hφ₂⟩, rfl⟩ := QuotientAddGroup.mk_surjective c
    exact ⟨Quot.mk _ (stdExt ε d₁ d₂ hε h₀ h₁ φ hφ₂),
      hspec _ (stdLam d₁ φ) φ (stdLam_p ε d₁ d₂ hε h₀ h₁ φ hφ₂)
        (stdLam_i ε d₁ d₂ hε h₀ h₁ φ hφ₂) hφ₂⟩
  refine ⟨Equiv.ofBijective F ⟨hinj, hsurj⟩, fun X lam φ hlam hφ hφ₂ => hspec X lam φ hlam hφ hφ₂, ?_⟩
  have hs := hspec (Extension.split R M N) (LinearMap.inr R N M ∘ₗ ε) 0
    (LinearMap.ext fun a => rfl)
    (LinearMap.ext fun x => Prod.ext rfl (h₀.apply_apply_eq_zero x).symm) (by simp)
  exact hs.trans rfl

/-- Ext over ℤ for a clock. Resolve ℤ/m by `0 → ℤ --(× m)--> ℤ → ℤ/m → 0`. Then the maps from
ℤ/m into N are the members m times kills, `Hom(ℤ/m, N) = N[m]`, and Ext¹ read off this
resolution is N with the multiples of m counted as zero, `Ext¹(ℤ/m, N) = N / mN`. -/
theorem hom_and_ext_one_of_cyclic (m : ℕ) (N : Type) [AddCommGroup N] :
    Nonempty ((ZMod m →+ N) ≃+ (zsmulAddGroupHom (α := N) (m : ℤ)).ker) ∧
    Nonempty (Ext1 (R := ℤ) N ((m : ℤ) • LinearMap.id : ℤ →ₗ[ℤ] ℤ) (0 : PUnit →ₗ[ℤ] ℤ) ≃+
      N ⧸ (zsmulAddGroupHom (α := N) (m : ℤ)).range) := by
  refine ⟨⟨?_⟩, ⟨?_⟩⟩
  · exact
    { toFun := fun f => ⟨f 1, by
        show (m : ℤ) • f 1 = 0
        rw [← map_zsmul, zsmul_one]
        simp⟩
      invFun := fun n => ZMod.lift m ⟨zmultiplesHom N n.1, by
        have : (m : ℤ) • n.1 = 0 := n.2
        simpa using this⟩
      left_inv := by
        intro f
        ext x
        obtain ⟨k, rfl⟩ := ZMod.intCast_surjective x
        rw [ZMod.lift_coe]
        simp [← map_zsmul]
      right_inv := by
        intro n
        apply Subtype.ext
        have : (1 : ZMod m) = ((1 : ℤ) : ZMod m) := by simp
        simp only
        rw [this, ZMod.lift_coe]
        simp
      map_add' := by
        intro f g
        rfl }
  · let H : (precomp (R := ℤ) N (0 : PUnit →ₗ[ℤ] ℤ)).ker →+
        N ⧸ (zsmulAddGroupHom (α := N) (m : ℤ)).range :=
      AddMonoidHom.mk' (fun φ => QuotientAddGroup.mk (φ.1 1)) (by intro a b; simp)
    have hsurj : Surjective H := by
      intro c
      obtain ⟨n, rfl⟩ := QuotientAddGroup.mk_surjective c
      refine ⟨⟨LinearMap.toSpanSingleton ℤ N n, ?_⟩, ?_⟩
      · show precomp N _ _ = 0
        ext u
        simp [precomp]
      · show (QuotientAddGroup.mk (LinearMap.toSpanSingleton ℤ N n 1) : N ⧸ _) = _
        simp
    have hker : (precomp N ((m : ℤ) • LinearMap.id : ℤ →ₗ[ℤ] ℤ)).range.addSubgroupOf
        (precomp (R := ℤ) N (0 : PUnit →ₗ[ℤ] ℤ)).ker = H.ker := by
      ext φ
      rw [AddSubgroup.mem_addSubgroupOf, AddMonoidHom.mem_ker, AddMonoidHom.mem_range]
      change (∃ ψ, precomp N _ ψ = φ.1) ↔ (QuotientAddGroup.mk (φ.1 1) : N ⧸ _) = 0
      rw [QuotientAddGroup.eq_zero_iff, AddMonoidHom.mem_range]
      constructor
      · rintro ⟨ψ, hψ⟩
        refine ⟨ψ 1, ?_⟩
        rw [← hψ]
        simp [precomp]
        rw [← map_nsmul, nsmul_one]
      · rintro ⟨n, hn⟩
        refine ⟨LinearMap.toSpanSingleton ℤ N n, ?_⟩
        apply LinearMap.ext_ring
        simp [precomp, ← hn]
    exact (QuotientAddGroup.quotientAddEquivOfEq hker).trans
      (QuotientAddGroup.quotientKerEquivOfSurjective H hsurj)

/-- Order matters: every extension `0 → N → E → R → 0` of a free module R splits, so
Ext¹(ℤ, ℤ/2) = 0 while Ext¹(ℤ/2, ℤ) = ℤ/2. Stated here as: every extension of R by N is
equivalent to the split one. -/
theorem extension_of_free_splits (X : Extension R R N) :
    Extension.Equiv X (Extension.split R R N) := by
  obtain ⟨e0, he0⟩ := X.surjective_p 1
  let l : R →ₗ[R] X.E := LinearMap.toSpanSingleton R X.E e0
  have hl : X.p ∘ₗ l = LinearMap.id := by
    apply LinearMap.ext_ring
    simp [l, he0]
  obtain ⟨e, he1, he2⟩ := X.exact.splitSurjectiveEquiv X.injective_i ⟨l, hl⟩
  refine ⟨e, ?_, ?_⟩
  · rw [he1]; ext n; exact e.apply_symm_apply _
  · rw [he2]; rfl

end ExtCard

open ExtCard

-- Z/4 against Z/6: times 4 on Z/6 sends 0..5 to 0, 4, 2, 0, 4, 2.
example : (List.range 6).map (fun x => 4 * x % 6) = [0, 4, 2, 0, 4, 2] := by decide
-- Its kernel {0, 3} is Hom(Z/4, Z/6) = Z/2; its image {0, 2, 4} leaves Ext¹ = Z/6 ÷ 3 members = Z/2.
example : (Finset.univ.filter (fun x : ZMod 6 => 4 * x = 0)) = {0, 3} := by decide
example : (Finset.univ.image (fun x : ZMod 6 => 4 * x)) = {0, 2, 4} := by decide
-- Z/4 against Z/9: 4 · Z/9 is all of Z/9, so Ext¹(Z/4, Z/9) = 0 (4 and 9 share no factor).
example : (Finset.univ.image (fun x : ZMod 9 => 4 * x)) = Finset.univ := by decide
example : Nat.gcd 4 6 = 2 ∧ Nat.gcd 4 9 = 1 := by norm_num
-- c = 1 gives Z/24: there the multiples of 4 are a 6-clock and leave a 4-clock on top.
example : (Finset.univ.image (fun x : ZMod 24 => 4 * x)).card = 6 ∧ 24 / 6 = 4 := by decide
-- Over the ring Z/4: the kernel of doubling is the image of doubling, {0, 2}, so the resolution never ends.
example : (Finset.univ.filter (fun x : ZMod 4 => 2 * x = 0)) = Finset.univ.image (fun x : ZMod 4 => 2 * x) := by decide

#print axioms ext_one_classifies_extensions
#print axioms hom_and_ext_one_of_cyclic
#print axioms extension_of_free_splits
#print axioms Extension.equiv_symm
#print axioms Extension.equiv_trans
#print axioms lift_into_range
#print axioms stdLam_p
#print axioms stdLam_i
#print axioms std_equiv
#print axioms equiv_of_class_eq
#print axioms exists_data
#print axioms class_eq_of_data
#print axioms classOf_spec
#print axioms classOf_respects
