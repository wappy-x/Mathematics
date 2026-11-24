-- Finite planes and orthogonal Latin squares: n - 1 mutually orthogonal Latin squares of order n exist exactly when a projective plane of order n does, no order allows more, and a finite field builds a full set.
import Mathlib.Combinatorics.Configuration
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.LinearCombination

open Function

/-- A Latin square on the symbol set `α`: rows, columns and symbols are all `α`, and each
symbol appears exactly once in every row and exactly once in every column. -/
def IsLatinSquare {α : Type*} (L : α → α → α) : Prop :=
  (∀ i, Bijective (L i)) ∧ ∀ j, Bijective (fun i => L i j)

/-- Two squares are orthogonal when, laid on top of each other, every ordered pair of symbols
appears in exactly one cell. -/
def AreOrthogonal {α : Type*} (A B : α → α → α) : Prop :=
  Bijective (fun c : α × α => (A c.1 c.2, B c.1 c.2))

/-- A family of mutually orthogonal Latin squares (MOLS): every square is Latin and every two
different squares are orthogonal. -/
def IsMOLS {ι α : Type*} (F : ι → α → α → α) : Prop :=
  (∀ k, IsLatinSquare (F k)) ∧ Pairwise fun a b => AreOrthogonal (F a) (F b)

instance {α : Type*} [Fintype α] [DecidableEq α] (L : α → α → α) :
    Decidable (IsLatinSquare L) :=
  inferInstanceAs (Decidable ((∀ i, Bijective (L i)) ∧ ∀ j, Bijective (fun i => L i j)))

instance {α : Type*} [Fintype α] [DecidableEq α] (A B : α → α → α) :
    Decidable (AreOrthogonal A B) :=
  inferInstanceAs (Decidable (Bijective (fun c : α × α => (A c.1 c.2, B c.1 c.2))))

namespace PPMOLS
open Configuration

section PlaneToMOLS
open Configuration

variable {P L : Type} [Membership P L] [Configuration.ProjectivePlane P L]

theorem line_eq_of_two {p₁ p₂ : P} {l₁ l₂ : L} (h : p₁ ≠ p₂) (h1 : p₁ ∈ l₁) (h2 : p₂ ∈ l₁)
    (h3 : p₁ ∈ l₂) (h4 : p₂ ∈ l₂) : l₁ = l₂ :=
  (Configuration.Nondegenerate.eq_or_eq h1 h2 h3 h4).resolve_left h

theorem affine_eq {l0 m1 m2 : L} {a b x x' : P} (hab : a ≠ b) (ha : a ∈ l0) (hb : b ∈ l0)
    (hx : x ∉ l0) (ha1 : a ∈ m1) (hx1 : x ∈ m1) (hx1' : x' ∈ m1) (hb2 : b ∈ m2) (hx2 : x ∈ m2)
    (hx2' : x' ∈ m2) : x = x' := by
  by_contra hne
  have h12 : m1 = m2 := line_eq_of_two hne hx1 hx1' hx2 hx2'
  subst h12
  have : m1 = l0 := line_eq_of_two hab ha1 hb2 ha hb
  subst this
  exact hx hx1

theorem line_eq_through {l0 m1 m2 : L} {a x : P} (ha : a ∈ l0) (hx : x ∉ l0) (ha1 : a ∈ m1)
    (hx1 : x ∈ m1) (ha2 : a ∈ m2) (hx2 : x ∈ m2) : m1 = m2 :=
  line_eq_of_two (fun (h : a = x) => hx (h ▸ ha)) ha1 hx1 ha2 hx2

theorem card_lines_through_ne [Finite P] [Finite L] {l0 : L} {p : P} (hp : p ∈ l0) :
    Nat.card {l : L // p ∈ l ∧ l ≠ l0} = ProjectivePlane.order P L := by
  classical
  have := Fintype.ofFinite L
  have h1 := ProjectivePlane.lineCount_eq L p
  rw [lineCount, Nat.card_eq_fintype_card, Fintype.card_subtype] at h1
  rw [Nat.card_eq_fintype_card, Fintype.card_subtype]
  have : (Finset.univ.filter fun l : L => p ∈ l ∧ l ≠ l0) =
      (Finset.univ.filter fun l : L => p ∈ l).erase l0 := by
    ext l; simp [and_comm]
  rw [this, Finset.card_erase_of_mem (by simpa using hp), h1]
  simp

theorem mols_of_plane [Finite P] [Finite L] (n : ℕ) (hn : 2 ≤ n)
    (hord : ProjectivePlane.order P L = n) :
    ∃ F : Fin (n - 1) → Fin n → Fin n → Fin n, IsMOLS F := by
  classical
  obtain ⟨-, -, -, l0, -, -, -⟩ := @ProjectivePlane.exists_config P L _ _
  have hpts : Nat.card {p : P // p ∈ l0} = n + 1 := by
    rw [← hord]; exact ProjectivePlane.pointCount_eq P l0
  obtain ⟨a, ha_inj, ha⟩ : ∃ a : Fin (n + 1) → P, Function.Injective a ∧ ∀ k, a k ∈ l0 := by
    let e := (Finite.equivFinOfCardEq hpts).symm
    exact ⟨fun k => (e k).1, fun x y h => e.injective (Subtype.ext h), fun k => (e k).2⟩
  have hT : ∀ p, p ∈ l0 → Nat.card {l : L // p ∈ l ∧ l ≠ l0} = n :=
    fun p hp => hord ▸ card_lines_through_ne hp
  -- n lines through a point of l0, other than l0
  have hfam : ∀ p, p ∈ l0 → ∃ R : Fin n → L, Function.Injective R ∧ ∀ i, p ∈ R i ∧ R i ≠ l0 := by
    intro p hp
    let e := (Finite.equivFinOfCardEq (hT p hp)).symm
    exact ⟨fun i => (e i).1, fun x y h => e.injective (Subtype.ext h), fun i => (e i).2⟩
  -- labels for lines through a point of l0
  have hlab : ∀ p, p ∈ l0 → ∃ g : L → Fin n, ∀ m m', p ∈ m → m ≠ l0 → p ∈ m' → m' ≠ l0 →
      g m = g m' → m = m' := by
    intro p hp
    let e := Finite.equivFinOfCardEq (hT p hp)
    refine ⟨fun m => if h : p ∈ m ∧ m ≠ l0 then e ⟨m, h⟩ else ⟨0, by omega⟩, ?_⟩
    intro m m' h1 h2 h3 h4 h
    simp only [h1, h2, h3, h4, ne_eq, not_false_eq_true, and_self, dite_true] at h
    exact congrArg Subtype.val (e.injective h)
  have hline : ∀ p x : P, p ≠ x → ∃ m : L, p ∈ m ∧ x ∈ m :=
    fun p x h => ⟨HasLines.mkLine h, HasLines.mkLine_ax h⟩
  let idx : Fin (n - 1) → Fin (n + 1) := fun k => ⟨k.1 + 2, by omega⟩
  obtain ⟨z0, z1, hz0, hz1⟩ : ∃ z0 z1 : Fin (n + 1), z0.val = 0 ∧ z1.val = 1 :=
    ⟨⟨0, by omega⟩, ⟨1, by omega⟩, rfl, rfl⟩
  have h01 : a z0 ≠ a z1 := fun h => by
    have := congrArg Fin.val (ha_inj h); omega
  have h0k : ∀ k, a z0 ≠ a (idx k) := fun k h => by
    have := congrArg Fin.val (ha_inj h); simp only [idx] at this; omega
  have h1k : ∀ k, a z1 ≠ a (idx k) := fun k h => by
    have := congrArg Fin.val (ha_inj h); simp only [idx] at this; omega
  have hkk : ∀ k k', k ≠ k' → a (idx k) ≠ a (idx k') := fun k k' hk h => by
    have := congrArg Fin.val (ha_inj h); simp only [idx] at this; exact hk (Fin.ext (by omega))
  obtain ⟨R, hR_inj, hR⟩ := hfam (a z0) (ha z0)
  obtain ⟨C, hC_inj, hC⟩ := hfam (a z1) (ha z1)
  choose g hg using fun k : Fin (n - 1) => hlab (a (idx k)) (ha _)
  -- the affine point in row i and column j
  obtain ⟨pt, hpt⟩ : ∃ pt : Fin n → Fin n → P,
      ∀ i j, pt i j ∈ R i ∧ pt i j ∈ C j ∧ pt i j ∉ l0 := by
    have hRC : ∀ i j, R i ≠ C j := by
      intro i j h
      apply (hR i).2
      exact line_eq_of_two h01 (hR i).1 (h ▸ (hC j).1) (ha z0) (ha z1)
    refine ⟨fun i j => HasPoints.mkPoint (P := P) (hRC i j), fun i j => ?_⟩
    obtain ⟨h1, h2⟩ := HasPoints.mkPoint_ax (P := P) (hRC i j)
    refine ⟨h1, h2, fun h => ?_⟩
    have e1 := (Configuration.Nondegenerate.eq_or_eq h1 (hR i).1 h (ha z0)).resolve_right (hR i).2
    have e2 := (Configuration.Nondegenerate.eq_or_eq h2 (hC j).1 h (ha z1)).resolve_right (hC j).2
    exact h01 (e1.symm.trans e2)
  choose M hM using fun (k : Fin (n - 1)) (i j : Fin n) =>
    hline (a (idx k)) (pt i j) (fun h => (hpt i j).2.2 (h ▸ ha _))
  have hMne : ∀ k i j, M k i j ≠ l0 := fun k i j h => (hpt i j).2.2 (h ▸ (hM k i j).2)
  have hMeq : ∀ k i j i' j', g k (M k i j) = g k (M k i' j') → M k i j = M k i' j' :=
    fun k i j i' j' h => hg k _ _ (hM k i j).1 (hMne k i j) (hM k i' j').1 (hMne k i' j') h
  refine ⟨fun k i j => g k (M k i j), fun k => ⟨fun i => ?_, fun j => ?_⟩, fun k k' hk => ?_⟩
  · apply Finite.injective_iff_bijective.mp
    intro j j' h
    have hm := hMeq k i j i j' h
    have hp : pt i j = pt i j' := affine_eq (h0k k) (ha z0) (ha _) (hpt i j).2.2 (hR i).1
      (hpt i j).1 (hpt i j').1 (hM k i j).1 (hM k i j).2 (hm ▸ (hM k i j').2)
    apply hC_inj
    exact line_eq_through (ha z1) (hpt i j).2.2 (hC j).1 (hpt i j).2.1 (hC j').1
      (hp ▸ (hpt i j').2.1)
  · apply Finite.injective_iff_bijective.mp
    intro i i' h
    have hm := hMeq k i j i' j h
    have hp : pt i j = pt i' j := affine_eq (h1k k) (ha z1) (ha _) (hpt i j).2.2 (hC j).1
      (hpt i j).2.1 (hpt i' j).2.1 (hM k i j).1 (hM k i j).2 (hm ▸ (hM k i' j).2)
    apply hR_inj
    exact line_eq_through (ha z0) (hpt i j).2.2 (hR i).1 (hpt i j).1 (hR i').1
      (hp ▸ (hpt i' j).1)
  · apply Finite.injective_iff_bijective.mp
    rintro ⟨i, j⟩ ⟨i', j'⟩ h
    simp only [Prod.mk.injEq] at h
    have hm := hMeq k i j i' j' h.1
    have hm' := hMeq k' i j i' j' h.2
    have hp : pt i j = pt i' j' := affine_eq (hkk k k' hk) (ha _) (ha _) (hpt i j).2.2
      (hM k i j).1 (hM k i j).2 (hm ▸ (hM k i' j').2) (hM k' i j).1 (hM k' i j).2
      (hm' ▸ (hM k' i' j').2)
    have e1 : i = i' := hR_inj (line_eq_through (ha z0) (hpt i j).2.2 (hR i).1 (hpt i j).1
      (hR i').1 (hp ▸ (hpt i' j').1))
    have e2 : j = j' := hC_inj (line_eq_through (ha z1) (hpt i j).2.2 (hC j).1 (hpt i j).2.1
      (hC j').1 (hp ▸ (hpt i' j').2.1))
    rw [e1, e2]


end PlaneToMOLS

section Net
variable {D α : Type}

/-- Points of the plane built from a net: affine cells and one point at infinity per direction. -/
inductive NPt (_G : D → α × α → α) : Type
  | aff (c : α × α)
  | inf (d : D)

/-- Lines of the plane built from a net: one per direction and value, plus the line at infinity. -/
inductive NLn (_G : D → α × α → α) : Type
  | ln (d : D) (v : α)
  | inf

def netMem (G : D → α × α → α) : NLn G → NPt G → Prop
  | .inf, .aff _ => False
  | .inf, .inf _ => True
  | .ln d v, .aff c => G d c = v
  | .ln d _, .inf e => e = d

instance (G : D → α × α → α) : Membership (NPt G) (NLn G) := ⟨netMem G⟩

variable {G : D → α × α → α}

@[simp] theorem mem_inf_aff (c : α × α) : ¬ ((NPt.aff c : NPt G) ∈ (NLn.inf : NLn G)) :=
  fun h => h
@[simp] theorem mem_inf_inf (e : D) : (NPt.inf e : NPt G) ∈ (NLn.inf : NLn G) := trivial
@[simp] theorem mem_ln_aff (c : α × α) (d : D) (v : α) :
    (NPt.aff c : NPt G) ∈ (NLn.ln d v : NLn G) ↔ G d c = v := Iff.rfl
@[simp] theorem mem_ln_inf (e d : D) (v : α) :
    (NPt.inf e : NPt G) ∈ (NLn.ln d v : NLn G) ↔ e = d := Iff.rfl

def NPt.equiv : NPt G ≃ (α × α) ⊕ D where
  toFun | .aff c => Sum.inl c | .inf d => Sum.inr d
  invFun | Sum.inl c => .aff c | Sum.inr d => .inf d
  left_inv p := by cases p <;> rfl
  right_inv p := by cases p <;> rfl

def NLn.equiv : NLn G ≃ Option (D × α) where
  toFun | .ln d v => some (d, v) | .inf => none
  invFun | some (d, v) => .ln d v | none => .inf
  left_inv p := by cases p <;> rfl
  right_inv p := by rcases p with _ | ⟨d, v⟩ <;> rfl

instance [Fintype D] [Fintype α] : Fintype (NPt G) := Fintype.ofEquiv _ NPt.equiv.symm
instance [Fintype D] [Fintype α] : Fintype (NLn G) := Fintype.ofEquiv _ NLn.equiv.symm

theorem net_nondeg (hG : ∀ d d', d ≠ d' → Function.Injective fun c => (G d c, G d' c))
    (hD : ∀ d : D, ∃ d', d' ≠ d) (hα : Nonempty α) : Nondegenerate (NPt G) (NLn G) where
  exists_point := by
    intro l
    rcases l with ⟨d, v⟩ | _
    · obtain ⟨d', hd'⟩ := hD d
      exact ⟨.inf d', by simpa using hd'⟩
    · exact ⟨.aff (hα.some, hα.some), mem_inf_aff _⟩
  exists_line := by
    intro p
    rcases p with c | e
    · exact ⟨.inf, mem_inf_aff c⟩
    · obtain ⟨d', hd'⟩ := hD e
      exact ⟨.ln d' hα.some, by simpa using hd'.symm⟩
  eq_or_eq := by
    intro p₁ p₂ l₁ l₂ h1 h2 h3 h4
    rcases p₁ with c₁ | e₁ <;> rcases p₂ with c₂ | e₂ <;>
      rcases l₁ with ⟨d₁, v₁⟩ | _ <;> rcases l₂ with ⟨d₂, v₂⟩ | _ <;>
      simp only [mem_ln_aff, mem_ln_inf, mem_inf_aff, mem_inf_inf] at h1 h2 h3 h4 <;>
      try exact Or.inr rfl
    · by_cases hd : d₁ = d₂
      · subst hd; right; rw [← h1, ← h3]
      · left; congr 1
        exact hG d₁ d₂ hd (by simp only [Prod.mk.injEq]; exact ⟨h1.trans h2.symm, h3.trans h4.symm⟩)
    · subst h2; subst h4; right; rw [← h1, ← h3]
    · subst h1; subst h3; right; rw [← h2, ← h4]
    all_goals (left; subst_vars; rfl)


theorem net_meet (hG : ∀ d d', d ≠ d' → Function.Bijective fun c => (G d c, G d' c))
    (l₁ l₂ : NLn G) (h : l₁ ≠ l₂) : ∃ p : NPt G, p ∈ l₁ ∧ p ∈ l₂ := by
  rcases l₁ with ⟨d₁, v₁⟩ | _ <;> rcases l₂ with ⟨d₂, v₂⟩ | _
  · by_cases hd : d₁ = d₂
    · exact ⟨.inf d₁, by simp [hd]⟩
    · obtain ⟨c, hc⟩ := (hG d₁ d₂ hd).2 (v₁, v₂)
      simp only [Prod.mk.injEq] at hc
      exact ⟨.aff c, by simpa using hc⟩
  · exact ⟨.inf d₁, by simp⟩
  · exact ⟨.inf d₂, by simp⟩
  · exact absurd rfl h

theorem card_NPt [Fintype D] [Fintype α] :
    Fintype.card (NPt G) = Fintype.card α * Fintype.card α + Fintype.card D := by
  rw [Fintype.card_congr NPt.equiv, Fintype.card_sum, Fintype.card_prod]

theorem card_NLn [Fintype D] [Fintype α] :
    Fintype.card (NLn G) = Fintype.card D * Fintype.card α + 1 := by
  rw [Fintype.card_congr NLn.equiv, Fintype.card_option, Fintype.card_prod]

theorem pointCount_inf [Fintype D] :
    Nat.card {p : NPt G // p ∈ (NLn.inf : NLn G)} = Fintype.card D := by
  rw [← Nat.card_eq_fintype_card]
  refine (Nat.card_congr (Equiv.ofBijective (fun d : D => (⟨.inf d, trivial⟩ :
    {p : NPt G // p ∈ (NLn.inf : NLn G)})) ⟨fun a b h => ?_, ?_⟩)).symm
  · exact NPt.inf.inj (congrArg Subtype.val h)
  · rintro ⟨p, hp⟩
    rcases p with c | d
    · exact absurd hp (mem_inf_aff c)
    · exact ⟨d, rfl⟩

theorem net_plane [Fintype D] [DecidableEq D] [Fintype α] [DecidableEq α]
    (hG : ∀ d d', d ≠ d' → Function.Injective fun c => (G d c, G d' c)) (n : ℕ) (hn : 2 ≤ n)
    (hα : Fintype.card α = n) (hD : Fintype.card D = n + 1) :
    ∃ (P L : Type) (_ : Membership P L) (_ : Configuration.ProjectivePlane P L)
      (_ : Finite P) (_ : Finite L), Configuration.ProjectivePlane.order P L = n := by
  have hGb : ∀ d d', d ≠ d' → Function.Bijective fun c => (G d c, G d' c) :=
    fun d d' h => Finite.injective_iff_bijective.mp (hG d d' h)
  obtain ⟨d₀, d₁, d₂, h01, h02, h12⟩ : ∃ d₀ d₁ d₂ : D, d₀ ≠ d₁ ∧ d₀ ≠ d₂ ∧ d₁ ≠ d₂ := by
    have : 2 < Fintype.card D := by omega
    obtain ⟨s, hs⟩ := Finset.exists_subset_card_eq (s := (Finset.univ : Finset D)) (n := 3)
      (by simp; omega)
    obtain ⟨x, y, z, hxy, hxz, hyz, -⟩ := Finset.card_eq_three.mp hs.2
    exact ⟨x, y, z, hxy, hxz, hyz⟩
  have hD' : ∀ d : D, ∃ d', d' ≠ d := fun d => by
    by_cases h : d₀ = d
    · exact ⟨d₁, fun h' => h01 (h.trans h'.symm)⟩
    · exact ⟨d₀, h⟩
  have : Nontrivial α := Fintype.one_lt_card_iff_nontrivial.mp (by omega)
  have hne : Nonempty α := inferInstance
  have hcard : Fintype.card (NPt G) = Fintype.card (NLn G) := by
    rw [card_NPt, card_NLn, hα, hD]; ring
  let hP : HasPoints (NPt G) (NLn G) :=
    { net_nondeg hG hD' hne with
      mkPoint := fun h => Classical.choose (net_meet hGb _ _ h)
      mkPoint_ax := fun h => Classical.choose_spec (net_meet hGb _ _ h) }
  let hL : HasLines (NPt G) (NLn G) := HasPoints.hasLines hcard
  let c₀ : α × α := (hne.some, hne.some)
  obtain ⟨w, hw⟩ := exists_ne (G d₁ c₀)
  let plane : ProjectivePlane (NPt G) (NLn G) :=
    { hP, hL with
      exists_config := ⟨.inf d₂, .aff c₀, .inf d₀, .ln d₁ w, .ln d₀ (G d₀ c₀), .ln d₁ (G d₁ c₀),
        by simpa using h02.symm, by simpa using h12.symm, by simpa using hw.symm, by simp, by simp,
        by simpa using h01, by simp, by simpa using h01⟩ }
  refine ⟨NPt G, NLn G, inferInstance, plane, inferInstance, inferInstance, ?_⟩
  have := ProjectivePlane.pointCount_eq (NPt G) (NLn.inf : NLn G)
  rw [pointCount, pointCount_inf, hD] at this
  omega

end Net

theorem plane_of_mols (n : ℕ) (hn : 2 ≤ n) (F : Fin (n - 1) → Fin n → Fin n → Fin n)
    (hF : IsMOLS F) :
    ∃ (P L : Type) (_ : Membership P L) (_ : Configuration.ProjectivePlane P L)
      (_ : Finite P) (_ : Finite L), Configuration.ProjectivePlane.order P L = n := by
  let G : Option (Option (Fin (n - 1))) → Fin n × Fin n → Fin n := fun d c =>
    match d with
    | none => c.1
    | some none => c.2
    | some (some k) => F k c.1 c.2
  refine net_plane (G := G) ?_ n hn (by simp) (by simp; omega)
  intro d d' hdd'
  rintro ⟨i, j⟩ ⟨i', j'⟩ h
  simp only [Prod.mk.injEq] at h
  obtain ⟨h1, h2⟩ := h
  rcases d with _ | _ | k <;> rcases d' with _ | _ | k' <;> simp only [G] at h1 h2
  · exact absurd rfl hdd'
  · rw [h1, h2]
  · subst h1; rw [((hF.1 k').1 i).1 h2]
  · rw [h1, h2]
  · exact absurd rfl hdd'
  · subst h1; rw [((hF.1 k').2 j).1 h2]
  · subst h2; rw [((hF.1 k).1 i).1 h1]
  · subst h2; rw [((hF.1 k).2 j).1 h1]
  · have hk : k ≠ k' := fun h => hdd' (by rw [h])
    have := (hF.2 hk).1 (a₁ := (i, j)) (a₂ := (i', j')) (by simp only [Prod.mk.injEq]; exact ⟨h1, h2⟩)
    exact this

#print axioms line_eq_of_two
#print axioms affine_eq
#print axioms line_eq_through
#print axioms card_lines_through_ne
#print axioms mols_of_plane
#print axioms mem_inf_aff
#print axioms mem_inf_inf
#print axioms mem_ln_aff
#print axioms mem_ln_inf
#print axioms net_nondeg
#print axioms net_meet
#print axioms card_NPt
#print axioms card_NLn
#print axioms pointCount_inf
#print axioms net_plane
#print axioms plane_of_mols

end PPMOLS


/-- The card's main claim: for every order `n ≥ 2`, a full set of `n - 1` mutually orthogonal
Latin squares of order `n` exists exactly when a projective plane of order `n` exists
(`n ≥ 2` is needed: at orders 0 and 1 the empty set of squares exists but no plane does). -/
theorem full_mols_iff_projective_plane (n : ℕ) (hn : 2 ≤ n) :
    (∃ F : Fin (n - 1) → Fin n → Fin n → Fin n, IsMOLS F) ↔
      ∃ (P L : Type) (_ : Membership P L) (_ : Configuration.ProjectivePlane P L)
        (_ : Finite P) (_ : Finite L), Configuration.ProjectivePlane.order P L = n := by
  constructor
  · rintro ⟨F, hF⟩
    exact PPMOLS.plane_of_mols n hn F hF
  · rintro ⟨P, L, _, _, _, _, hord⟩
    exact PPMOLS.mols_of_plane n hn hord

/-- No order allows more than `n - 1` mutually orthogonal Latin squares: a family of MOLS on
`n ≥ 2` symbols has at most `n - 1` squares. -/
theorem mols_card_le {ι α : Type*} [Fintype ι] [Fintype α] (hα : 2 ≤ Fintype.card α)
    (F : ι → α → α → α) (hF : IsMOLS F) : Fintype.card ι ≤ Fintype.card α - 1 := by
  classical
  obtain ⟨i0, i1, hi⟩ := Fintype.exists_pair_of_one_lt_card hα
  have hne : Nonempty α := ⟨i0⟩
  let j0 : α := i0
  have ht : ∀ k, ∃ t : α, F k i1 t = F k i0 j0 := fun k => ((hF.1 k).1 i1).2 _
  choose t ht using ht
  have htne : ∀ k, t k ≠ j0 := by
    intro k h
    have h' := ht k
    rw [h] at h'
    exact hi (((hF.1 k).2 j0).1 h').symm
  have hinj : Function.Injective fun k => (⟨t k, htne k⟩ : {x : α // x ≠ j0}) := by
    intro a b hab
    by_contra hab'
    have h1 : t a = t b := congrArg Subtype.val hab
    have := (hF.2 hab').1 (a₁ := (i0, j0)) (a₂ := (i1, t a)) (by
      simp only [Prod.mk.injEq]
      exact ⟨(ht a).symm, by rw [h1, ht b]⟩)
    simp only [Prod.mk.injEq] at this
    exact hi this.1
  have := Fintype.card_le_of_injective _ hinj
  simpa [Fintype.card_subtype_compl] using this


/-- The field construction: over a finite field `K` with `q` elements, the squares
`L_m(i, j) = i + m j`, one for each nonzero `m`, are `q - 1` mutually orthogonal Latin squares. -/
theorem field_squares_are_mols (K : Type*) [Field K] [Fintype K] [DecidableEq K] :
    IsMOLS (fun (m : {m : K // m ≠ 0}) (i j : K) => i + m.1 * j) ∧
      Fintype.card {m : K // m ≠ 0} = Fintype.card K - 1 := by
  refine ⟨⟨fun m => ⟨fun i => ?_, fun j => ?_⟩, fun a b hab => ?_⟩, ?_⟩
  · apply Finite.injective_iff_bijective.mp
    intro x y h
    simpa [m.2] using h
  · apply Finite.injective_iff_bijective.mp
    intro x y h
    simpa using h
  · apply Finite.injective_iff_bijective.mp
    rintro ⟨x1, x2⟩ ⟨y1, y2⟩ h
    simp only [Prod.mk.injEq] at h
    obtain ⟨h1, h2⟩ := h
    have hab' : a.1 - b.1 ≠ 0 := sub_ne_zero.mpr (fun h => hab (Subtype.ext h))
    have e2 : x2 = y2 := by
      have : (a.1 - b.1) * x2 = (a.1 - b.1) * y2 := by linear_combination h1 - h2
      exact mul_left_cancel₀ hab' this
    subst e2
    have : x1 = y1 := by simpa using h1
    rw [this]
  · rw [Fintype.card_subtype_compl, Fintype.card_subtype_eq]

/-- The card's two squares of order 3, `i + j` and `i + 2j` mod 3. -/
def L1 : ZMod 3 → ZMod 3 → ZMod 3 := fun i j => i + j
def L2 : ZMod 3 → ZMod 3 → ZMod 3 := fun i j => i + 2 * j

/-- The number of different ordered pairs seen when two squares are laid on top of each other. -/
def pairCount {α : Type*} [Fintype α] [DecidableEq α] (A B : α → α → α) : ℕ :=
  (Finset.univ.image fun c : α × α => (A c.1 c.2, B c.1 c.2)).card

-- Order 3: both squares are Latin, they are orthogonal, and all 9 ordered pairs appear.
example : IsLatinSquare L1 ∧ IsLatinSquare L2 := by decide
example : AreOrthogonal L1 L2 := by decide
example : pairCount L1 L2 = 9 := by decide
-- Row 1, column 2 shows the pair 0, 2.
example : L1 1 2 = 0 ∧ L2 1 2 = 2 := by decide
-- The plane of order 3: 3^2 + 3 + 1 = 13 points, and (3^3 - 1)/(3 - 1) = 13 triples up to scaling.
example : 3 ^ 2 + 3 + 1 = 13 ∧ (3 ^ 3 - 1) / (3 - 1) = 13 := by norm_num

/-- The Fano plane's seven lines on the points 1 to 7. -/
def fano : Finset (Finset ℕ) :=
  {{1, 2, 4}, {2, 3, 5}, {3, 4, 6}, {4, 5, 7}, {5, 6, 1}, {6, 7, 2}, {7, 1, 3}}

-- The Fano plane: 7 lines of 3, every two points on exactly one line, every two lines share one point.
example : fano.card = 7 ∧ ∀ l ∈ fano, l.card = 3 := by decide
example : ∀ a ∈ Finset.Icc 1 7, ∀ b ∈ Finset.Icc 1 7, a ≠ b →
    (fano.filter fun l => a ∈ l ∧ b ∈ l).card = 1 := by decide
example : ∀ l ∈ fano, ∀ m ∈ fano, l ≠ m → (l ∩ m).card = 1 := by decide

-- Mistake 1: on the 4-hour clock, i + 2j is not Latin (row 0 reads 0, 2, 0, 2).
example : ¬ IsLatinSquare (fun i j : ZMod 4 => i + 2 * j) := by decide
-- Mistake 2: 2(i + j) mod 3 against i + j shows only 3 of 9 pairs.
example : pairCount L1 (fun i j => 2 * (i + j)) = 3 := by decide
-- Mistake 3: i + j and i + 5j mod 6 are Latin but show only 18 of 36 pairs.
example : IsLatinSquare (fun i j : ZMod 6 => i + j) ∧ IsLatinSquare (fun i j : ZMod 6 => i + 5 * j) := by decide
example : pairCount (fun i j : ZMod 6 => i + j) (fun i j => i + 5 * j) = 18 := by decide

#print axioms full_mols_iff_projective_plane
#print axioms mols_card_le
#print axioms field_squares_are_mols
