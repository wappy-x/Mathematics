-- Recurrences: the tilings of a 2 x n hallway by 1 x 2 tiles obey T(n) = T(n-1) + T(n-2) with seeds T(1) = 1 and T(2) = 2, so they are the Fibonacci numbers F(n+1), and the Tower of Hanoi rule h(n) = 2h(n-1) + 1 with h(0) = 0 gives h(n) = 2^n - 1.
import Mathlib.Combinatorics.SimpleGraph.Hasse
import Mathlib.Combinatorics.SimpleGraph.Prod
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Order.Partition.Finpartition
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Tactic.NormNum

open SimpleGraph

/-- The squares of a hallway 2 tiles wide and `n` tiles long are the pairs (row, column) in
`Fin 2 × Fin n`; two squares are neighbours when they are joined in the grid graph
`pathGraph 2 □ pathGraph n` (same column and the other row, or same row and the next column).
A 1 x 2 tile covers two neighbouring squares, and a floor (a tiling) splits all the squares into
such tiles: a partition of the board whose every part is a pair of neighbours.
`hallwayTilings n` is T(n), the number of floors. -/
noncomputable def hallwayTilings (n : ℕ) : ℕ :=
  Nat.card {P : Finpartition (Finset.univ : Finset (Fin 2 × Fin n)) //
    ∀ p ∈ P.parts, ∃ a b, (pathGraph 2 □ pathGraph n).Adj a b ∧ p = {a, b}}

section TilingHelpers

variable {α : Type*} [Fintype α] [DecidableEq α]

theorem tiling_finpartition_eq_of_part_eq (P Q : Finpartition (Finset.univ : Finset α))
    (h : ∀ a, P.part a = Q.part a) : P = Q := by
  ext t
  constructor
  · intro ht
    obtain ⟨x, hx⟩ := P.nonempty_of_mem_parts ht
    rw [← P.part_eq_of_mem ht hx, h]
    exact Q.part_mem.2 (Finset.mem_univ _)
  · intro ht
    obtain ⟨x, hx⟩ := Q.nonempty_of_mem_parts ht
    rw [← Q.part_eq_of_mem ht hx, ← h]
    exact P.part_mem.2 (Finset.mem_univ _)

theorem tiling_part_pair (G : SimpleGraph α) (P : Finpartition (Finset.univ : Finset α))
    (hP : ∀ p ∈ P.parts, ∃ a b, G.Adj a b ∧ p = {a, b}) (a b : α) (hb : b ∈ P.part a)
    (hne : b ≠ a) : P.part a = {a, b} ∧ G.Adj a b := by
  obtain ⟨x, y, hxy, hp⟩ := hP _ (P.part_mem.2 (Finset.mem_univ a))
  have ha : a ∈ P.part a := P.mem_part (Finset.mem_univ a)
  rw [hp] at ha hb ⊢
  simp only [Finset.mem_insert, Finset.mem_singleton] at ha hb
  rcases ha with rfl | rfl <;> rcases hb with rfl | rfl
  · exact absurd rfl hne
  · exact ⟨rfl, hxy⟩
  · exact ⟨Finset.pair_comm _ _, hxy.symm⟩
  · exact absurd rfl hne

theorem tiling_exists_partner (G : SimpleGraph α) (P : Finpartition (Finset.univ : Finset α))
    (hP : ∀ p ∈ P.parts, ∃ a b, G.Adj a b ∧ p = {a, b}) (a : α) :
    ∃ b, b ∈ P.part a ∧ b ≠ a := by
  obtain ⟨x, y, hxy, hp⟩ := hP _ (P.part_mem.2 (Finset.mem_univ a))
  have ha : a ∈ P.part a := P.mem_part (Finset.mem_univ a)
  rw [hp] at ha ⊢
  simp only [Finset.mem_insert, Finset.mem_singleton] at ha
  rcases ha with rfl | rfl
  · exact ⟨y, by simp, hxy.ne.symm⟩
  · exact ⟨x, by simp, hxy.ne⟩

/-- The setoid whose classes are the pairs `{a, σ a}` of an involution `σ`. -/
def tilingSetoid (σ : α → α) (hσ : ∀ a, σ (σ a) = a) : Setoid α where
  r a b := b = a ∨ b = σ a
  iseqv := by
    refine ⟨fun a => Or.inl rfl, ?_, ?_⟩
    · rintro a b (rfl | rfl)
      · exact Or.inl rfl
      · exact Or.inr (hσ a).symm
    · rintro a b c (rfl | rfl) (rfl | rfl)
      · exact Or.inl rfl
      · exact Or.inr rfl
      · exact Or.inr rfl
      · exact Or.inl (hσ a)

instance tilingSetoid_decRel (σ : α → α) (hσ : ∀ a, σ (σ a) = a) :
    DecidableRel (tilingSetoid σ hσ).r :=
  fun a b => inferInstanceAs (Decidable (b = a ∨ b = σ a))

theorem tiling_part_ofSetoid (σ : α → α) (hσ : ∀ a, σ (σ a) = a)
    (a : α) : (Finpartition.ofSetoid (tilingSetoid σ hσ)).part a = {a, σ a} := by
  ext b
  rw [Finpartition.mem_part_ofSetoid_iff_rel]
  simp only [Finset.mem_insert, Finset.mem_singleton]
  rfl

/-- Tilings of a graph by pairs of neighbours are the same as fixed-point-free involutions along
edges. -/
noncomputable def tilingEquiv (G : SimpleGraph α) :
    {P : Finpartition (Finset.univ : Finset α) // ∀ p ∈ P.parts, ∃ a b, G.Adj a b ∧ p = {a, b}} ≃
    {σ : α → α // ∀ a, G.Adj a (σ a) ∧ σ (σ a) = a} where
  toFun P := ⟨fun a => Classical.choose (tiling_exists_partner G P.1 P.2 a), fun a => by
    have h1 := Classical.choose_spec (tiling_exists_partner G P.1 P.2 a)
    set b := Classical.choose (tiling_exists_partner G P.1 P.2 a)
    have h2 := Classical.choose_spec (tiling_exists_partner G P.1 P.2 b)
    set c := Classical.choose (tiling_exists_partner G P.1 P.2 b)
    obtain ⟨hpa, hab⟩ := tiling_part_pair G P.1 P.2 a b h1.1 h1.2
    refine ⟨hab, ?_⟩
    have hpb : P.1.part b = P.1.part a :=
      P.1.part_eq_of_mem (P.1.part_mem.2 (Finset.mem_univ a)) h1.1
    have hc := h2.1
    rw [hpb, hpa] at hc
    simp only [Finset.mem_insert, Finset.mem_singleton] at hc
    rcases hc with hc | hc
    · exact hc
    · exact absurd hc h2.2⟩
  invFun σ := ⟨Finpartition.ofSetoid (tilingSetoid σ.1 (fun a => (σ.2 a).2)), by
    intro p hp
    obtain ⟨x, hx⟩ := Finpartition.nonempty_of_mem_parts _ hp
    refine ⟨x, σ.1 x, (σ.2 x).1, ?_⟩
    rw [← Finpartition.part_eq_of_mem _ hp hx]
    exact tiling_part_ofSetoid _ _ x⟩
  left_inv P := by
    apply Subtype.ext
    apply tiling_finpartition_eq_of_part_eq
    intro a
    rw [tiling_part_ofSetoid]
    have h1 := Classical.choose_spec (tiling_exists_partner G P.1 P.2 a)
    exact (tiling_part_pair G P.1 P.2 a _ h1.1 h1.2).1.symm
  right_inv σ := by
    apply Subtype.ext
    funext a
    have key : ∀ b, b ∈ (Finpartition.ofSetoid (tilingSetoid σ.1 (fun a => (σ.2 a).2))).part a →
        b ≠ a → b = σ.1 a := by
      intro b hb hne
      rw [tiling_part_ofSetoid] at hb
      simp only [Finset.mem_insert, Finset.mem_singleton] at hb
      rcases hb with hb | hb
      · exact absurd hb hne
      · exact hb
    have h1 := Classical.choose_spec (tiling_exists_partner G
      (Finpartition.ofSetoid (tilingSetoid σ.1 (fun a => (σ.2 a).2)))
      (by
        intro p hp
        obtain ⟨x, hx⟩ := Finpartition.nonempty_of_mem_parts _ hp
        refine ⟨x, σ.1 x, (σ.2 x).1, ?_⟩
        rw [← Finpartition.part_eq_of_mem _ hp hx]
        exact tiling_part_ofSetoid _ _ x) a)
    exact key _ h1.1 h1.2

end TilingHelpers

/-- Neighbouring squares, with squares written as pairs of whole numbers (row, column). -/
def hallAdj (a b : ℕ × ℕ) : Prop :=
  ((a.1 + 1 = b.1 ∨ b.1 + 1 = a.1) ∧ a.2 = b.2) ∨ ((a.2 + 1 = b.2 ∨ b.2 + 1 = a.2) ∧ a.1 = b.1)

/-- A floor of the 2 x n hallway as a partner map on all pairs of whole numbers: on the board each
square goes to a neighbouring square on the board and back; off the board nothing moves. -/
def hallGood (n : ℕ) (f : ℕ × ℕ → ℕ × ℕ) : Prop :=
  ∀ a : ℕ × ℕ, (a.1 < 2 ∧ a.2 < n → (f a).1 < 2 ∧ (f a).2 < n ∧ hallAdj a (f a) ∧ f (f a) = a) ∧
    (¬ (a.1 < 2 ∧ a.2 < n) → f a = a)

theorem hallGood_last_vert {n : ℕ} {f : ℕ × ℕ → ℕ × ℕ} (hf : hallGood (n + 2) f)
    (hA : f (0, n + 1) = (1, n + 1)) : f (1, n + 1) = (0, n + 1) := by
  have := ((hf (0, n + 1)).1 ⟨by norm_num, by omega⟩).2.2.2
  rwa [hA] at this

theorem hallGood_last_flat {n : ℕ} {f : ℕ × ℕ → ℕ × ℕ} (hf : hallGood (n + 2) f)
    (hA : f (0, n + 1) ≠ (1, n + 1)) : f (0, n + 1) = (0, n) ∧ f (1, n + 1) = (1, n) := by
  obtain ⟨h1, h2, h3, h4⟩ := (hf (0, n + 1)).1 ⟨by norm_num, by omega⟩
  obtain ⟨k1, k2, k3, k4⟩ := (hf (1, n + 1)).1 ⟨by norm_num, by omega⟩
  have hA' : f (0, n + 1) = (0, n) := by
    simp only [ne_eq, Prod.ext_iff] at hA ⊢
    simp only [hallAdj] at h3
    omega
  refine ⟨hA', ?_⟩
  by_cases hB : f (1, n + 1) = (0, n + 1)
  · rw [hB] at k4
    exact absurd k4 hA
  · simp only [Prod.ext_iff] at hB ⊢
    simp only [hallAdj] at k3
    omega

/-- Floors of the 2 x (n+2) hallway ending in an upright tile are floors of the 2 x (n+1)
hallway. -/
def hallE1 (n : ℕ) :
    {x : {f // hallGood (n + 2) f} // x.1 (0, n + 1) = (1, n + 1)} ≃ {f // hallGood (n + 1) f} where
  toFun x := ⟨fun a => if a.1 < 2 ∧ a.2 < n + 1 then x.1.1 a else a, by
    obtain ⟨⟨f, hf⟩, hA⟩ := x
    change f (0, n + 1) = (1, n + 1) at hA
    have hB := hallGood_last_vert hf hA
    intro a
    constructor
    · intro ha
      obtain ⟨h1, h2, h3, h4⟩ := (hf a).1 ⟨ha.1, by omega⟩
      have h2' : (f a).2 < n + 1 := by
        by_contra hc
        have : f a = (0, n + 1) ∨ f a = (1, n + 1) := by
          rw [Prod.ext_iff, Prod.ext_iff]; omega
        rcases this with he | he
        · rw [he, hA] at h4; rw [← h4] at ha; simp at ha
        · rw [he, hB] at h4; rw [← h4] at ha; simp at ha
      dsimp only
      rw [ite_eq_left ha, ite_eq_left (And.intro h1 h2')]
      exact ⟨h1, h2', h3, h4⟩
    · intro ha
      dsimp only
      rw [ite_eq_right ha]⟩
  invFun g := ⟨⟨fun a => if a = (0, n + 1) then (1, n + 1) else
      if a = (1, n + 1) then (0, n + 1) else g.1 a, by
    obtain ⟨g, hg⟩ := g
    intro a
    constructor
    · intro ha
      by_cases hA : a = (0, n + 1)
      · subst hA
        simp [hallAdj]
      by_cases hB : a = (1, n + 1)
      · subst hB
        simp [hallAdj]
      have ha' : a.1 < 2 ∧ a.2 < n + 1 := by
        simp only [Prod.ext_iff] at hA hB; omega
      obtain ⟨h1, h2, h3, h4⟩ := (hg a).1 ha'
      have gA : g a ≠ (0, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      have gB : g a ≠ (1, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      dsimp only
      rw [ite_eq_right hA, ite_eq_right hB, ite_eq_right gA, ite_eq_right gB]
      exact ⟨h1, by omega, h3, h4⟩
    · intro ha
      have hA : a ≠ (0, n + 1) := by rintro rfl; simp at ha
      have hB : a ≠ (1, n + 1) := by rintro rfl; simp at ha
      dsimp only
      rw [ite_eq_right hA, ite_eq_right hB]
      exact (hg a).2 (by omega)⟩, by simp⟩
  left_inv x := by
    obtain ⟨⟨f, hf⟩, hA⟩ := x
    change f (0, n + 1) = (1, n + 1) at hA
    have hB := hallGood_last_vert hf hA
    apply Subtype.ext; apply Subtype.ext
    funext a
    dsimp only
    by_cases h1 : a = (0, n + 1)
    · rw [ite_eq_left h1, h1, hA]
    rw [ite_eq_right h1]
    by_cases h2 : a = (1, n + 1)
    · rw [ite_eq_left h2, h2, hB]
    rw [ite_eq_right h2]
    by_cases h3 : a.1 < 2 ∧ a.2 < n + 1
    · rw [ite_eq_left h3]
    · rw [ite_eq_right h3]
      refine ((hf a).2 ?_).symm
      simp only [Prod.ext_iff] at h1 h2
      omega
  right_inv g := by
    obtain ⟨g, hg⟩ := g
    apply Subtype.ext
    funext a
    dsimp only
    by_cases h3 : a.1 < 2 ∧ a.2 < n + 1
    · rw [ite_eq_left h3]
      have hA : a ≠ (0, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      have hB : a ≠ (1, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      rw [ite_eq_right hA, ite_eq_right hB]
    · rw [ite_eq_right h3]
      exact ((hg a).2 h3).symm

/-- Floors of the 2 x (n+2) hallway ending in two flat tiles are floors of the 2 x n hallway. -/
def hallE2 (n : ℕ) :
    {x : {f // hallGood (n + 2) f} // ¬ x.1 (0, n + 1) = (1, n + 1)} ≃ {f // hallGood n f} where
  toFun x := ⟨fun a => if a.1 < 2 ∧ a.2 < n then x.1.1 a else a, by
    obtain ⟨⟨f, hf⟩, hA⟩ := x
    change ¬ f (0, n + 1) = (1, n + 1) at hA
    obtain ⟨hA', hB'⟩ := hallGood_last_flat hf hA
    have hC : f (0, n) = (0, n + 1) := by
      have := ((hf (0, n + 1)).1 ⟨by norm_num, by omega⟩).2.2.2
      rwa [hA'] at this
    have hD : f (1, n) = (1, n + 1) := by
      have := ((hf (1, n + 1)).1 ⟨by norm_num, by omega⟩).2.2.2
      rwa [hB'] at this
    intro a
    constructor
    · intro ha
      obtain ⟨h1, h2, h3, h4⟩ := (hf a).1 ⟨ha.1, by omega⟩
      have h2' : (f a).2 < n := by
        by_contra hc
        have : f a = (0, n + 1) ∨ f a = (1, n + 1) ∨ f a = (0, n) ∨ f a = (1, n) := by
          simp only [Prod.ext_iff]; omega
        rcases this with he | he | he | he
        · rw [he, hA'] at h4; rw [← h4] at ha; simp at ha
        · rw [he, hB'] at h4; rw [← h4] at ha; simp at ha
        · rw [he, hC] at h4; rw [← h4] at ha; simp at ha
        · rw [he, hD] at h4; rw [← h4] at ha; simp at ha
      dsimp only
      rw [ite_eq_left ha, ite_eq_left (And.intro h1 h2')]
      exact ⟨h1, h2', h3, h4⟩
    · intro ha
      dsimp only
      rw [ite_eq_right ha]⟩
  invFun g := ⟨⟨fun a => if a = (0, n + 1) then (0, n) else if a = (0, n) then (0, n + 1) else
      if a = (1, n + 1) then (1, n) else if a = (1, n) then (1, n + 1) else g.1 a, by
    obtain ⟨g, hg⟩ := g
    intro a
    constructor
    · intro ha
      by_cases hA : a = (0, n + 1)
      · subst hA; simp [hallAdj]
      by_cases hC : a = (0, n)
      · subst hC; simp [hallAdj]
      by_cases hB : a = (1, n + 1)
      · subst hB; simp [hallAdj]
      by_cases hD : a = (1, n)
      · subst hD; simp [hallAdj]
      have ha' : a.1 < 2 ∧ a.2 < n := by
        simp only [Prod.ext_iff] at hA hB hC hD; omega
      obtain ⟨h1, h2, h3, h4⟩ := (hg a).1 ha'
      have gA : g a ≠ (0, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      have gB : g a ≠ (1, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      have gC : g a ≠ (0, n) := by rw [Ne, Prod.ext_iff]; omega
      have gD : g a ≠ (1, n) := by rw [Ne, Prod.ext_iff]; omega
      dsimp only
      rw [ite_eq_right hA, ite_eq_right hC, ite_eq_right hB, ite_eq_right hD,
        ite_eq_right gA, ite_eq_right gC, ite_eq_right gB, ite_eq_right gD]
      exact ⟨h1, by omega, h3, h4⟩
    · intro ha
      have hA : a ≠ (0, n + 1) := by rintro rfl; simp at ha
      have hB : a ≠ (1, n + 1) := by rintro rfl; simp at ha
      have hC : a ≠ (0, n) := by rintro rfl; simp at ha
      have hD : a ≠ (1, n) := by rintro rfl; simp at ha
      dsimp only
      rw [ite_eq_right hA, ite_eq_right hC, ite_eq_right hB, ite_eq_right hD]
      exact (hg a).2 (by omega)⟩, by simp⟩
  left_inv x := by
    obtain ⟨⟨f, hf⟩, hA⟩ := x
    change ¬ f (0, n + 1) = (1, n + 1) at hA
    obtain ⟨hA', hB'⟩ := hallGood_last_flat hf hA
    have hC : f (0, n) = (0, n + 1) := by
      have := ((hf (0, n + 1)).1 ⟨by norm_num, by omega⟩).2.2.2
      rwa [hA'] at this
    have hD : f (1, n) = (1, n + 1) := by
      have := ((hf (1, n + 1)).1 ⟨by norm_num, by omega⟩).2.2.2
      rwa [hB'] at this
    apply Subtype.ext; apply Subtype.ext
    funext a
    dsimp only
    by_cases h1 : a = (0, n + 1)
    · rw [ite_eq_left h1, h1, hA']
    rw [ite_eq_right h1]
    by_cases h2 : a = (0, n)
    · rw [ite_eq_left h2, h2, hC]
    rw [ite_eq_right h2]
    by_cases h3 : a = (1, n + 1)
    · rw [ite_eq_left h3, h3, hB']
    rw [ite_eq_right h3]
    by_cases h4 : a = (1, n)
    · rw [ite_eq_left h4, h4, hD]
    rw [ite_eq_right h4]
    by_cases h5 : a.1 < 2 ∧ a.2 < n
    · rw [ite_eq_left h5]
    · rw [ite_eq_right h5]
      refine ((hf a).2 ?_).symm
      simp only [Prod.ext_iff] at h1 h2 h3 h4
      omega
  right_inv g := by
    obtain ⟨g, hg⟩ := g
    apply Subtype.ext
    funext a
    dsimp only
    by_cases h3 : a.1 < 2 ∧ a.2 < n
    · rw [ite_eq_left h3]
      have hA : a ≠ (0, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      have hB : a ≠ (1, n + 1) := by rw [Ne, Prod.ext_iff]; omega
      have hC : a ≠ (0, n) := by rw [Ne, Prod.ext_iff]; omega
      have hD : a ≠ (1, n) := by rw [Ne, Prod.ext_iff]; omega
      rw [ite_eq_right hA, ite_eq_right hC, ite_eq_right hB, ite_eq_right hD]
    · rw [ite_eq_right h3]
      exact ((hg a).2 h3).symm

theorem hallGood_card_zero : Nat.card {f // hallGood 0 f} = 1 := by
  rw [Nat.card_eq_one_iff_unique]
  refine ⟨⟨fun f g => ?_⟩, ⟨⟨id, fun a => ⟨fun h => absurd h.2 (Nat.not_lt_zero _),
    fun _ => rfl⟩⟩⟩⟩
  apply Subtype.ext
  funext a
  rw [(f.2 a).2 (fun h => absurd h.2 (Nat.not_lt_zero _)),
    (g.2 a).2 (fun h => absurd h.2 (Nat.not_lt_zero _))]

/-- The one floor of the 2 x 1 hallway: a single upright tile. -/
def hallOne (a : ℕ × ℕ) : ℕ × ℕ :=
  if a = (0, 0) then (1, 0) else if a = (1, 0) then (0, 0) else a

theorem hallGood_one_eq {f : ℕ × ℕ → ℕ × ℕ} (hf : hallGood 1 f) : f = hallOne := by
  funext a
  unfold hallOne
  by_cases h1 : a = (0, 0)
  · subst h1
    rw [ite_eq_left rfl]
    obtain ⟨k1, k2, k3, -⟩ := (hf (0, 0)).1 (by norm_num)
    simp only [hallAdj] at k3
    rw [Prod.ext_iff]
    omega
  by_cases h2 : a = (1, 0)
  · subst h2
    rw [ite_eq_right (by decide), ite_eq_left rfl]
    obtain ⟨k1, k2, k3, -⟩ := (hf (1, 0)).1 (by norm_num)
    simp only [hallAdj] at k3
    rw [Prod.ext_iff]
    omega
  rw [ite_eq_right h1, ite_eq_right h2]
  apply (hf a).2
  simp only [Prod.ext_iff] at h1 h2
  omega

theorem hallGood_hallOne : hallGood 1 hallOne := by
  intro a
  constructor
  · intro ha
    have : a = (0, 0) ∨ a = (1, 0) := by simp only [Prod.ext_iff]; omega
    rcases this with rfl | rfl <;> simp [hallOne, hallAdj]
  · intro ha
    have h1 : a ≠ (0, 0) := by rintro rfl; simp at ha
    have h2 : a ≠ (1, 0) := by rintro rfl; simp at ha
    simp [hallOne, h1, h2]

theorem hallGood_card_one : Nat.card {f // hallGood 1 f} = 1 := by
  rw [Nat.card_eq_one_iff_unique]
  refine ⟨⟨fun f g => ?_⟩, ⟨⟨hallOne, hallGood_hallOne⟩⟩⟩
  apply Subtype.ext
  rw [hallGood_one_eq f.2, hallGood_one_eq g.2]

theorem hallGood_card : ∀ n, Nat.card {f // hallGood n f} = Nat.fib (n + 1)
  | 0 => by rw [hallGood_card_zero]; simp
  | 1 => by rw [hallGood_card_one]; simp
  | n + 2 => by
    have h1 := hallGood_card (n + 1)
    have h0 := hallGood_card n
    have : Finite {f // hallGood (n + 1) f} :=
      Nat.finite_of_card_ne_zero (by rw [h1]; exact (Nat.fib_pos.2 (by omega)).ne')
    have : Finite {f // hallGood n f} :=
      Nat.finite_of_card_ne_zero (by rw [h0]; exact (Nat.fib_pos.2 (by omega)).ne')
    rw [Nat.card_congr ((Equiv.sumCompl (fun x : {f // hallGood (n + 2) f} =>
        x.1 (0, n + 1) = (1, n + 1))).symm.trans (Equiv.sumCongr (hallE1 n) (hallE2 n))),
      Nat.card_sum, h1, h0, show n + 2 + 1 = (n + 1) + 2 by ring, Nat.fib_add_two (n := n + 1)]
    ring

/-- A square of the hallway written as a pair of whole numbers (row, column). -/
def hallToN {n : ℕ} (x : Fin 2 × Fin n) : ℕ × ℕ := (x.1.val, x.2.val)

theorem hall_adj_iff {n : ℕ} (x y : Fin 2 × Fin n) :
    (pathGraph 2 □ pathGraph n).Adj x y ↔ hallAdj (hallToN x) (hallToN y) := by
  simp only [boxProd_adj, pathGraph_adj, hallAdj, hallToN, Fin.ext_iff]

/-- Partner maps on the hallway squares are the same as partner maps on pairs of whole numbers
that fix everything off the board. -/
def hallEquivN (n : ℕ) :
    {σ : Fin 2 × Fin n → Fin 2 × Fin n //
      ∀ a, (pathGraph 2 □ pathGraph n).Adj a (σ a) ∧ σ (σ a) = a} ≃ {f // hallGood n f} where
  toFun σ := ⟨fun a => if h : a.1 < 2 ∧ a.2 < n then
      hallToN (σ.1 (⟨a.1, h.1⟩, ⟨a.2, h.2⟩)) else a, by
    obtain ⟨σ, hσ⟩ := σ
    intro a
    constructor
    · intro h
      dsimp only
      rw [dite_eq_left h]
      set y := σ (⟨a.1, h.1⟩, ⟨a.2, h.2⟩) with hy
      have hb : (hallToN y).1 < 2 ∧ (hallToN y).2 < n := ⟨y.1.isLt, y.2.isLt⟩
      refine ⟨hb.1, hb.2, ?_, ?_⟩
      · exact (hall_adj_iff (⟨a.1, h.1⟩, ⟨a.2, h.2⟩) y).1 (hσ _).1
      · rw [dite_eq_left hb]
        have : ((⟨(hallToN y).1, hb.1⟩, ⟨(hallToN y).2, hb.2⟩) : Fin 2 × Fin n) = y := rfl
        rw [this, hy, (hσ _).2]
        rfl
    · intro h
      dsimp only
      rw [dite_eq_right h]⟩
  invFun g := ⟨fun x => (⟨(g.1 (hallToN x)).1, ((g.2 (hallToN x)).1 ⟨x.1.isLt, x.2.isLt⟩).1⟩,
      ⟨(g.1 (hallToN x)).2, ((g.2 (hallToN x)).1 ⟨x.1.isLt, x.2.isLt⟩).2.1⟩), by
    obtain ⟨g, hg⟩ := g
    intro x
    obtain ⟨h1, h2, h3, h4⟩ := (hg (hallToN x)).1 ⟨x.1.isLt, x.2.isLt⟩
    constructor
    · rw [hall_adj_iff]; exact h3
    · apply Prod.ext <;> apply Fin.ext
      · show (g (g (hallToN x))).1 = x.1.val
        rw [h4]; rfl
      · show (g (g (hallToN x))).2 = x.2.val
        rw [h4]; rfl⟩
  left_inv σ := by
    apply Subtype.ext
    funext x
    have hx : (x.1 : ℕ) ≤ 1 := Nat.le_of_lt_succ x.1.isLt
    apply Prod.ext <;> apply Fin.ext <;> simp [hallToN, hx]
  right_inv g := by
    apply Subtype.ext
    funext a
    dsimp only
    by_cases h : a.1 < 2 ∧ a.2 < n
    · rw [dite_eq_left h]; rfl
    · rw [dite_eq_right h]; exact ((g.2 a).2 h).symm

theorem hallwayTilings_eq_card (n : ℕ) : hallwayTilings n = Nat.card {f // hallGood n f} :=
  Nat.card_congr ((tilingEquiv _).trans (hallEquivN n))

#print axioms tiling_finpartition_eq_of_part_eq
#print axioms tiling_part_pair
#print axioms tiling_exists_partner
#print axioms tiling_part_ofSetoid
#print axioms hallGood_last_vert
#print axioms hallGood_last_flat
#print axioms hallGood_card_zero
#print axioms hallGood_one_eq
#print axioms hallGood_hallOne
#print axioms hallGood_card_one
#print axioms hallGood_card
#print axioms hall_adj_iff
#print axioms hallwayTilings_eq_card

/-- The card's recurrence: a 2 x n hallway has as many floors as the hallway one tile shorter
plus the hallway two tiles shorter, for every length n ≥ 3, and the two seeds counted by hand are
T(1) = 1 and T(2) = 2. -/
theorem hallway_tilings_recurrence :
    hallwayTilings 1 = 1 ∧ hallwayTilings 2 = 2 ∧
      ∀ n, 3 ≤ n → hallwayTilings n = hallwayTilings (n - 1) + hallwayTilings (n - 2) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [hallwayTilings_eq_card, hallGood_card_one]
  · rw [hallwayTilings_eq_card, hallGood_card]
    rfl
  · intro n hn
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
    simp only [hallwayTilings_eq_card, hallGood_card, show m + 2 - 1 = m + 1 by omega,
      show m + 2 - 2 = m by omega]
    rw [show m + 2 + 1 = (m + 1) + 2 by ring, Nat.fib_add_two (n := m + 1)]
    ring

/-- The tiling counts are the Fibonacci numbers one place along: T(n) = F(n + 1), where `Nat.fib`
has seeds F(1) = F(2) = 1. -/
theorem hallway_tilings_eq_fib_succ (n : ℕ) : hallwayTilings n = Nat.fib (n + 1) := by
  rw [hallwayTilings_eq_card, hallGood_card]

/-- The Tower of Hanoi closed form: for every whole number n ≥ 0, a sequence with h(0) = 0 and
h(n) = 2h(n − 1) + 1 for n ≥ 1 has h(n) = 2^n − 1. -/
theorem hanoi_moves_closed_form (h : ℕ → ℕ) (h0 : h 0 = 0)
    (hstep : ∀ n, 1 ≤ n → h n = 2 * h (n - 1) + 1) (n : ℕ) : h n = 2 ^ n - 1 := by
  induction n with
  | zero => simp [h0]
  | succ k ih =>
    rw [hstep (k + 1) (by omega), Nat.add_sub_cancel, ih, pow_succ]
    have : 0 < 2 ^ k := by positivity
    omega

-- The worked numbers: T(1) to T(10) are F(2) to F(11): 1 2 3 5 8 13 21 34 55 89.
example : (List.range 10).map (fun n => Nat.fib (n + 2)) = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89] := by
  decide

-- The far end of a 2 x 10 hallway: 55 end in one upright tile, 34 in two flat tiles.
example : Nat.fib 10 + Nat.fib 9 = 89 ∧ 55 + 34 = 89 := by decide

-- Fibonacci's seeds 1 and 1: F(11) = 89, and F(10) = 55, the count one tile shorter (mistake 1).
example : Nat.fib 1 = 1 ∧ Nat.fib 2 = 1 ∧ Nat.fib 11 = 89 ∧ Nat.fib 10 = 55 := by decide

-- Mistake 2: the flat pair counted once per row, a(n) = a(n-1) + 2 a(n-2) from 1 and 2, ends at 512.
example : (List.range 8).foldl (fun (p : ℕ × ℕ) _ => (p.2, p.2 + 2 * p.1)) (1, 2) = (256, 512) := by
  decide

-- Hanoi: h(1) to h(10) by the rule are 1 3 7 15 31 63 127 255 511 1023.
example : (List.range 10).map (fun k => Nat.iterate (fun h => 2 * h + 1) (k + 1) 0) =
    [1, 3, 7, 15, 31, 63, 127, 255, 511, 1023] := by decide

-- Hanoi, ten discs: 2 x 511 + 1 = 511 + 1 + 511 = 2^10 - 1 = 1023.
example : 2 * 511 + 1 = 1023 ∧ 511 + 1 + 511 = 1023 ∧ 2 ^ 10 - 1 = 1023 := by norm_num

-- Mistake 3: the guess h(n) = 2^n fails at the start (2^0 = 1, not 0) and claims 1024.
example : 2 ^ 0 ≠ 0 ∧ 2 ^ 10 = 1024 := by norm_num

#print axioms hallway_tilings_recurrence
#print axioms hallway_tilings_eq_fib_succ
#print axioms hanoi_moves_closed_form
