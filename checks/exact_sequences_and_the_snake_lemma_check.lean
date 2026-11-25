-- Exact sequences of modules: for exact rows of modules joined by commuting downward maps, the kernels and cokernels form an exact six-term row through the connecting map built by the chase, a short exact sequence splits exactly when it has a section or a retraction, and the five lemma holds.
import Mathlib.Algebra.Exact.Basic
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.LinearAlgebra.Prod
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.FiveLemma
import Mathlib.Tactic.NormNum

namespace SnakeLemmaCard

open LinearMap Function

variable {R : Type*} [Ring R]
  {A B C A' B' C' : Type*}
  [AddCommGroup A] [Module R A] [AddCommGroup B] [Module R B] [AddCommGroup C] [Module R C]
  [AddCommGroup A'] [Module R A'] [AddCommGroup B'] [Module R B'] [AddCommGroup C'] [Module R C']

/-- The snake lemma. Take a top exact row `A → B → C → 0` (exact at `B`, with `g` onto), a
bottom exact row `0 → A' → B' → C'` (exact at `B'`, with `f'` one-to-one), and downward maps
`a, b, c` making both squares commute. Then `f` and `g` restrict to maps
`ker a → ker b → ker c`, `f'` and `g'` pass to maps `coker a → coker b → coker c`, and there is
a connecting map `δ : ker c → coker a`, given by the chase (lift `z` to `y` with `g y = z`,
pull `b y` back to the `x` with `f' x = b y`, take the class `[x]`), that makes the six-term row
`ker a → ker b → ker c → coker a → coker b → coker c` exact at every inner spot. If `f` is
one-to-one the row starts with `0 →`, and if `g'` is onto it ends with `→ 0`. -/
theorem snake_lemma_exact_six_term_row
    (f : A →ₗ[R] B) (g : B →ₗ[R] C) (f' : A' →ₗ[R] B') (g' : B' →ₗ[R] C')
    (a : A →ₗ[R] A') (b : B →ₗ[R] B') (c : C →ₗ[R] C')
    (hfg : Exact f g) (hg : Surjective g)
    (hf'g' : Exact f' g') (hf' : Injective f')
    (hsq₁ : b ∘ₗ f = f' ∘ₗ a) (hsq₂ : c ∘ₗ g = g' ∘ₗ b) :
    ∃ (κ₁ : ker a →ₗ[R] ker b) (κ₂ : ker b →ₗ[R] ker c)
      (δ : ker c →ₗ[R] A' ⧸ range a)
      (γ₁ : A' ⧸ range a →ₗ[R] B' ⧸ range b) (γ₂ : B' ⧸ range b →ₗ[R] C' ⧸ range c),
      (∀ u, (κ₁ u : B) = f u) ∧ (∀ v, (κ₂ v : C) = g v) ∧
      (∀ x, γ₁ ((range a).mkQ x) = (range b).mkQ (f' x)) ∧
      (∀ w, γ₂ ((range b).mkQ w) = (range c).mkQ (g' w)) ∧
      (∀ (z : ker c) (y : B) (x : A'), g y = z → f' x = b y → δ z = (range a).mkQ x) ∧
      Exact κ₁ κ₂ ∧ Exact κ₂ δ ∧ Exact δ γ₁ ∧ Exact γ₁ γ₂ ∧
      (Injective f → Injective κ₁) ∧ (Surjective g' → Surjective γ₂) := by
  classical
  have hgf : ∀ u, g (f u) = 0 := fun u => hfg.apply_apply_eq_zero u
  have hg'f' : ∀ u, g' (f' u) = 0 := fun u => hf'g'.apply_apply_eq_zero u
  have sq₁ : ∀ u, b (f u) = f' (a u) := fun u => LinearMap.congr_fun hsq₁ u
  have sq₂ : ∀ u, c (g u) = g' (b u) := fun u => LinearMap.congr_fun hsq₂ u
  -- the two restricted maps
  let κ₁ : ker a →ₗ[R] ker b :=
    LinearMap.restrict f (fun u (hu : u ∈ ker a) => by
      simp only [mem_ker] at hu ⊢; rw [sq₁, hu, map_zero])
  let κ₂ : ker b →ₗ[R] ker c :=
    LinearMap.restrict g (fun v (hv : v ∈ ker b) => by
      simp only [mem_ker] at hv ⊢; rw [sq₂, hv, map_zero])
  let γ₁ : A' ⧸ range a →ₗ[R] B' ⧸ range b :=
    (range a).mapQ (range b) f' (by
      rintro _ ⟨u, rfl⟩; exact ⟨f u, by rw [sq₁]⟩)
  let γ₂ : B' ⧸ range b →ₗ[R] C' ⧸ range c :=
    (range b).mapQ (range c) g' (by
      rintro _ ⟨u, rfl⟩; exact ⟨g u, by rw [sq₂]⟩)
  -- the chase
  have hx : ∀ y : B, c (g y) = 0 → ∃ x, f' x = b y := by
    intro y hy
    rw [sq₂] at hy
    exact (hf'g' (b y)).mp hy
  have wd : ∀ (y₁ y₂ : B) (x₁ x₂ : A'), g y₁ = g y₂ → f' x₁ = b y₁ → f' x₂ = b y₂ →
      (range a).mkQ x₁ = (range a).mkQ x₂ := by
    intro y₁ y₂ x₁ x₂ hy h₁ h₂
    have : g (y₁ - y₂) = 0 := by rw [map_sub, hy, sub_self]
    obtain ⟨w, hw⟩ := (hfg _).mp this
    rw [Submodule.mkQ_apply, Submodule.mkQ_apply, Submodule.Quotient.eq]
    refine ⟨w, hf' ?_⟩
    rw [← sq₁, hw, map_sub, map_sub, h₁, h₂]
  have yspec : ∀ z : ker c, g (hg z).choose = z := fun z => (hg z).choose_spec
  have ykc : ∀ z : ker c, c (g (hg z).choose) = 0 := fun z => by rw [yspec]; exact z.2
  let δf : ker c → A' ⧸ range a := fun z => (range a).mkQ (hx _ (ykc z)).choose
  have hδf : ∀ (z : ker c) (y : B) (x : A'), g y = z → f' x = b y → δf z = (range a).mkQ x := by
    intro z y x hy hxy
    exact wd _ y _ x (by rw [yspec, hy]) (hx _ (ykc z)).choose_spec hxy
  have lift : ∀ z : ker c, ∃ y x, g y = z ∧ f' x = b y := fun z =>
    ⟨_, _, yspec z, (hx _ (ykc z)).choose_spec⟩
  let δ : ker c →ₗ[R] A' ⧸ range a :=
    { toFun := δf
      map_add' := by
        intro z₁ z₂
        obtain ⟨y₁, x₁, hy₁, hx₁⟩ := lift z₁
        obtain ⟨y₂, x₂, hy₂, hx₂⟩ := lift z₂
        rw [hδf z₁ y₁ x₁ hy₁ hx₁, hδf z₂ y₂ x₂ hy₂ hx₂,
          hδf (z₁ + z₂) (y₁ + y₂) (x₁ + x₂) (by simp [hy₁, hy₂]) (by simp [hx₁, hx₂]),
          map_add]
      map_smul' := by
        intro r z
        obtain ⟨y, x, hy, hxy⟩ := lift z
        rw [hδf z y x hy hxy, hδf (r • z) (r • y) (r • x) (by simp [hy]) (by simp [hxy]),
          map_smul, RingHom.id_apply] }
  have hδ : ∀ (z : ker c) (y : B) (x : A'), g y = z → f' x = b y → δ z = (range a).mkQ x := hδf
  have hκ₁ : ∀ u, (κ₁ u : B) = f u := fun u => rfl
  have hκ₂ : ∀ v, (κ₂ v : C) = g v := fun v => rfl
  have hγ₁ : ∀ x, γ₁ ((range a).mkQ x) = (range b).mkQ (f' x) := fun x => rfl
  have hγ₂ : ∀ w, γ₂ ((range b).mkQ w) = (range c).mkQ (g' w) := fun w => rfl
  refine ⟨κ₁, κ₂, δ, γ₁, γ₂, hκ₁, hκ₂, hγ₁, hγ₂, hδ, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · -- exact at ker b
    intro v
    constructor
    · intro hv
      have hv' : g (v : B) = 0 := by rw [← hκ₂, hv]; rfl
      obtain ⟨u, hu⟩ := (hfg _).mp hv'
      have hau : a u = 0 := by
        apply hf'
        rw [← sq₁, hu, map_zero]
        exact v.2
      exact ⟨⟨u, hau⟩, Subtype.ext (by rw [hκ₁]; exact hu)⟩
    · rintro ⟨u, rfl⟩
      exact Subtype.ext (by rw [hκ₂, hκ₁, hgf]; rfl)
  · -- exact at ker c
    intro z
    constructor
    · intro hz
      obtain ⟨y, x, hy, hxy⟩ := lift z
      rw [hδ z y x hy hxy, Submodule.mkQ_apply, Submodule.Quotient.mk_eq_zero] at hz
      obtain ⟨w, hw⟩ := hz
      refine ⟨⟨y - f w, ?_⟩, Subtype.ext ?_⟩
      · rw [mem_ker, map_sub, sq₁, hw, hxy, sub_self]
      · rw [hκ₂]; simp [hgf, hy]
    · rintro ⟨v, rfl⟩
      rw [hδ (κ₂ v) v 0 (hκ₂ v) (by rw [map_zero]; exact v.2.symm), map_zero]
  · -- exact at coker a
    intro q
    obtain ⟨x, rfl⟩ := Submodule.mkQ_surjective _ q
    constructor
    · intro hq
      rw [hγ₁, Submodule.mkQ_apply, Submodule.Quotient.mk_eq_zero] at hq
      obtain ⟨y, hy⟩ := hq
      have hz : g y ∈ ker c := by rw [mem_ker, sq₂, hy, hg'f']
      exact ⟨⟨g y, hz⟩, hδ _ y x rfl hy.symm⟩
    · rintro ⟨z, hz⟩
      obtain ⟨y, x', hy, hxy⟩ := lift z
      rw [hδ z y x' hy hxy] at hz
      rw [← hz, hγ₁, hxy, Submodule.mkQ_apply, Submodule.Quotient.mk_eq_zero]
      exact ⟨y, rfl⟩
  · -- exact at coker b
    intro q
    obtain ⟨w, rfl⟩ := Submodule.mkQ_surjective _ q
    constructor
    · intro hq
      rw [hγ₂, Submodule.mkQ_apply, Submodule.Quotient.mk_eq_zero] at hq
      obtain ⟨z, hz⟩ := hq
      obtain ⟨y, rfl⟩ := hg z
      have : g' (w - b y) = 0 := by rw [map_sub, ← sq₂, hz, sub_self]
      obtain ⟨x, hx'⟩ := (hf'g' _).mp this
      refine ⟨(range a).mkQ x, ?_⟩
      rw [hγ₁, hx', Submodule.mkQ_apply, Submodule.mkQ_apply, Submodule.Quotient.eq]
      exact ⟨-y, by simp⟩
    · rintro ⟨q', hq'⟩
      obtain ⟨x, rfl⟩ := Submodule.mkQ_surjective _ q'
      rw [← hq', hγ₁, hγ₂, hg'f', map_zero]
  · -- left end
    intro hf u₁ u₂ h
    apply Subtype.ext
    apply hf
    rw [← hκ₁, ← hκ₁, h]
  · -- right end
    intro hg' q
    obtain ⟨w, rfl⟩ := Submodule.mkQ_surjective _ q
    obtain ⟨v, rfl⟩ := hg' w
    exact ⟨(range b).mkQ v, hγ₂ v⟩

/-- Split, section, retraction. For a short exact sequence `0 → A → B → C → 0`, the row is
split (an isomorphism `B ≅ A ⊕ C` turning `f` into `x ↦ (x, 0)` and `g` into `(x, z) ↦ z`)
exactly when `g` has a section `s` with `g ∘ s = 1`, and exactly when `f` has a retraction
`r` with `r ∘ f = 1`. -/
theorem short_exact_split_iff_section_iff_retraction
    (f : A →ₗ[R] B) (g : B →ₗ[R] C)
    (hf : Injective f) (hfg : Exact f g) (hg : Surjective g) :
    ((∃ s : C →ₗ[R] B, g ∘ₗ s = LinearMap.id) ↔
      ∃ e : B ≃ₗ[R] A × C, (∀ x, e (f x) = (x, 0)) ∧ ∀ y, (e y).2 = g y) ∧
    ((∃ r : B →ₗ[R] A, r ∘ₗ f = LinearMap.id) ↔
      ∃ e : B ≃ₗ[R] A × C, (∀ x, e (f x) = (x, 0)) ∧ ∀ y, (e y).2 = g y) := by
  have key : ∀ e : B ≃ₗ[R] A × C,
      ((∀ x, e (f x) = (x, 0)) ∧ ∀ y, (e y).2 = g y) ↔
        (f = e.symm.toLinearMap ∘ₗ LinearMap.inl R A C ∧ g = LinearMap.snd R A C ∘ₗ e.toLinearMap) := by
    intro e
    constructor
    · rintro ⟨h₁, h₂⟩
      refine ⟨LinearMap.ext fun x => ?_, LinearMap.ext fun y => ?_⟩
      · simp only [LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply,
          LinearMap.inl_apply]
        rw [← h₁, LinearEquiv.symm_apply_apply]
      · simp [h₂]
    · rintro ⟨h₁, h₂⟩
      refine ⟨fun x => ?_, fun y => ?_⟩
      · rw [h₁]; simp
      · rw [h₂]; simp
  constructor
  · constructor
    · rintro ⟨s, hs⟩
      obtain ⟨e, he⟩ := (hfg.splitSurjectiveEquiv hf ⟨s, hs⟩)
      exact ⟨e, (key e).mpr he⟩
    · rintro ⟨e, he⟩
      exact ⟨_, ((hfg.splitSurjectiveEquiv hf).symm ⟨e, (key e).mp he⟩).2⟩
  · constructor
    · rintro ⟨r, hr⟩
      obtain ⟨e, he⟩ := (hfg.splitInjectiveEquiv hg ⟨r, hr⟩)
      exact ⟨e, (key e).mpr he⟩
    · rintro ⟨e, he⟩
      exact ⟨_, ((hfg.splitInjectiveEquiv hg).symm ⟨e, (key e).mp he⟩).2⟩

/-- The five lemma. In a commuting ladder of two exact rows of five modules
`A₁ → A₂ → A₃ → A₄ → A₅` and `B₁ → B₂ → B₃ → B₄ → B₅`, joined by downward maps
`t₁, …, t₅`, if the four outer downward maps are isomorphisms, so is the middle one. -/
theorem five_lemma
    {A₁ A₂ A₃ A₄ A₅ B₁ B₂ B₃ B₄ B₅ : Type*}
    [AddCommGroup A₁] [Module R A₁] [AddCommGroup A₂] [Module R A₂]
    [AddCommGroup A₃] [Module R A₃] [AddCommGroup A₄] [Module R A₄]
    [AddCommGroup A₅] [Module R A₅]
    [AddCommGroup B₁] [Module R B₁] [AddCommGroup B₂] [Module R B₂]
    [AddCommGroup B₃] [Module R B₃] [AddCommGroup B₄] [Module R B₄]
    [AddCommGroup B₅] [Module R B₅]
    (α₁ : A₁ →ₗ[R] A₂) (α₂ : A₂ →ₗ[R] A₃) (α₃ : A₃ →ₗ[R] A₄) (α₄ : A₄ →ₗ[R] A₅)
    (β₁ : B₁ →ₗ[R] B₂) (β₂ : B₂ →ₗ[R] B₃) (β₃ : B₃ →ₗ[R] B₄) (β₄ : B₄ →ₗ[R] B₅)
    (t₁ : A₁ →ₗ[R] B₁) (t₂ : A₂ →ₗ[R] B₂) (t₃ : A₃ →ₗ[R] B₃)
    (t₄ : A₄ →ₗ[R] B₄) (t₅ : A₅ →ₗ[R] B₅)
    (hα₁ : Exact α₁ α₂) (hα₂ : Exact α₂ α₃) (hα₃ : Exact α₃ α₄)
    (hβ₁ : Exact β₁ β₂) (hβ₂ : Exact β₂ β₃) (hβ₃ : Exact β₃ β₄)
    (h₁ : t₂ ∘ₗ α₁ = β₁ ∘ₗ t₁) (h₂ : t₃ ∘ₗ α₂ = β₂ ∘ₗ t₂)
    (h₃ : t₄ ∘ₗ α₃ = β₃ ∘ₗ t₃) (h₄ : t₅ ∘ₗ α₄ = β₄ ∘ₗ t₄)
    (ht₁ : Bijective t₁) (ht₂ : Bijective t₂) (ht₄ : Bijective t₄) (ht₅ : Bijective t₅) :
    Bijective t₃ := by
  have c₁ : β₁.toAddMonoidHom.comp t₁.toAddMonoidHom = t₂.toAddMonoidHom.comp α₁.toAddMonoidHom :=
    AddMonoidHom.ext fun x => (LinearMap.congr_fun h₁ x).symm
  have c₂ : β₂.toAddMonoidHom.comp t₂.toAddMonoidHom = t₃.toAddMonoidHom.comp α₂.toAddMonoidHom :=
    AddMonoidHom.ext fun x => (LinearMap.congr_fun h₂ x).symm
  have c₃ : β₃.toAddMonoidHom.comp t₃.toAddMonoidHom = t₄.toAddMonoidHom.comp α₃.toAddMonoidHom :=
    AddMonoidHom.ext fun x => (LinearMap.congr_fun h₃ x).symm
  have c₄ : β₄.toAddMonoidHom.comp t₄.toAddMonoidHom = t₅.toAddMonoidHom.comp α₄.toAddMonoidHom :=
    AddMonoidHom.ext fun x => (LinearMap.congr_fun h₄ x).symm
  exact AddMonoidHom.bijective_of_surjective_of_bijective_of_bijective_of_injective
    α₁.toAddMonoidHom α₂.toAddMonoidHom α₃.toAddMonoidHom α₄.toAddMonoidHom
    β₁.toAddMonoidHom β₂.toAddMonoidHom β₃.toAddMonoidHom β₄.toAddMonoidHom
    t₁.toAddMonoidHom t₂.toAddMonoidHom t₃.toAddMonoidHom t₄.toAddMonoidHom t₅.toAddMonoidHom
    c₁ c₂ c₃ c₄ hα₁ hα₂ hα₃ hβ₁ hβ₂ hβ₃ ht₁.2 ht₂ ht₄ ht₅.1

-- The ruler: 7 half-metres = 3 metres + leftover 1; half + half = 2 half-metres = 1 metre,
-- leftover 0.
example : (7 : ℤ) = 2 * 3 + 1 ∧ (1 : ℤ) + 1 = 2 * 1 + 0 := by norm_num
-- Not split: in ℤ/2 both members are killed by 2, but in ℤ only 0 is, so no homomorphism
-- ℤ/2 → ℤ sends the half to an odd count.
example : (Finset.univ.filter fun z : ZMod 2 => 2 * z = 0).card = 2 := by decide
example : ¬ ∃ s : ZMod 2 →+ ℤ, s 1 % 2 = 1 := by
  rintro ⟨s, hs⟩
  have h2 : s 1 + s 1 = 0 := by rw [← map_add]; exact (congrArg s (by decide)).trans s.map_zero
  omega
-- Snake on the ruler times 2: ker c = ℤ/2; the chase lifts the half to 1, doubles it to 2,
-- pulls back to 1 metre (2 · 1 = 2 · 1), whose class mod 2 is odd.
example : (2 : ℤ) * 1 = 2 * 1 ∧ (1 : ℤ) % 2 = 1 := by norm_num
-- Order count: 1 · 2 · 2 = 1 · 2 · 2.
example : 1 * 2 * 2 = 1 * 2 * 2 := by norm_num
-- The house pair n = 4, m = 6: ker c = {0, 2}, the image of times 6 in ℤ/4 is {0, 2}
-- (so coker c has 4 / 2 = 2 members), d = gcd(4, 6) = 2, and the chase sends 2 to the class
-- of 3, since 6 · 2 = 4 · 3.
example : (Finset.univ.filter fun z : ZMod 4 => 6 * z = 0) = {0, 2} := by decide
example : (Finset.univ.image fun z : ZMod 4 => 6 * z) = {0, 2} := by decide
example : Nat.gcd 4 6 = 2 ∧ (6 : ℤ) * 2 = 4 * 3 := by norm_num
-- What breaks: times 4 then mod 2 composes to zero, yet 2 has leftover 0 and is not
-- 4 times a whole number.
example : (∀ x : ZMod 2, (4 : ZMod 2) * x = 0) ∧ (2 : ℤ) % 4 = 2 := by decide

#print axioms snake_lemma_exact_six_term_row
#print axioms short_exact_split_iff_section_iff_retraction
#print axioms five_lemma

end SnakeLemmaCard
