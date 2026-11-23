-- Two algebra questions: every residually finite group is sofic (in fact with an exact finite picture), and in a commutative ring the sum of two nil ideals is nil.
import Mathlib.GroupTheory.ResiduallyFinite
import Mathlib.GroupTheory.Perm.Basic
import Mathlib.InformationTheory.Hamming
import Mathlib.RingTheory.Nilpotent.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.Ideal.Defs

namespace SoficKothe

/-- The card's Hamming distance between two shuffles `α`, `β` of `n` points: the number of
points where they disagree, divided by `n` (a share from 0 to 1). -/
noncomputable def permDist {n : ℕ} (α β : Equiv.Perm (Fin n)) : ℝ :=
  (hammingDist (α : Fin n → Fin n) (β : Fin n → Fin n) : ℝ) / n

/-- The card's definition of a sofic group: for every finite set `F` of members and every error
`ε > 0`, some `n` and some map `σ` from `G` to the shuffles of `n` points satisfy, for all
`g, h` in `F`, `d(σ(gh), σ(g)σ(h)) ≤ ε`, and `d(σ(g), id) ≥ 1 − ε` when `g ≠ e`. -/
def IsSofic (G : Type*) [Group G] : Prop :=
  ∀ (F : Finset G) (ε : ℝ), 0 < ε →
    ∃ (n : ℕ) (σ : G → Equiv.Perm (Fin n)),
      (∀ g ∈ F, ∀ h ∈ F, permDist (σ (g * h)) (σ g * σ h) ≤ ε) ∧
      (∀ g ∈ F, g ≠ 1 → 1 - ε ≤ permDist (σ g) 1)

/-- The first open question (Gromov, 1999), stated exactly: is every group sofic?
Only stated here, never proved: as of 2026-11-23 a "no" is claimed, not refereed. -/
def EveryGroupIsSofic : Prop :=
  ∀ (G : Type) [Group G], IsSofic G

/-- Köthe's question (1930), stated exactly: in any ring `R`, if two left ideals `L₀`, `L₁`
are nil (every member has some power equal to 0), is every sum `a + b` with `a ∈ L₀`,
`b ∈ L₁` nil too? (`Submodule R R` is a left ideal.) Only stated here, never proved: as of
2026-11-23 a "no" is claimed, not refereed. -/
def KotheStatement : Prop :=
  ∀ (R : Type) [Ring R] (L₀ L₁ : Submodule R R),
    (∀ x ∈ L₀, IsNilpotent x) → (∀ x ∈ L₁, IsNilpotent x) →
      ∀ a ∈ L₀, ∀ b ∈ L₁, IsNilpotent (a + b)

theorem exists_fins_normal_avoiding (G : Type*) [Group G] [Group.ResiduallyFinite G]
    (F : Finset G) : ∃ K : FiniteIndexNormalSubgroup G, ∀ g ∈ F, g ≠ 1 → g ∉ K := by
  classical
  induction F using Finset.induction_on with
  | empty => exact ⟨FiniteIndexNormalSubgroup.ofSubgroup ⊤, by simp⟩
  | insert a s _ ih =>
    obtain ⟨K, hK⟩ := ih
    by_cases ha : a = 1
    · refine ⟨K, fun g hg hg1 => ?_⟩
      rcases Finset.mem_insert.mp hg with rfl | hg
      · exact (hg1 ha).elim
      · exact hK g hg hg1
    · obtain ⟨H, hH⟩ := Group.exists_finiteIndexNormalSubgroup_notMem a ha
      refine ⟨K ⊓ H, fun g hg hg1 hmem => ?_⟩
      rcases Finset.mem_insert.mp hg with rfl | hg
      · exact hH ((inf_le_right : K ⊓ H ≤ H) hmem)
      · exact hK g hg hg1 ((inf_le_left : K ⊓ H ≤ K) hmem)

#print axioms exists_fins_normal_avoiding

theorem exact_picture_pos (G : Type*) [Group G] [Group.ResiduallyFinite G] (F : Finset G) :
    ∃ (n : ℕ) (σ : G →* Equiv.Perm (Fin n)), 0 < n ∧
      ∀ g ∈ F, g ≠ 1 → ∀ x : Fin n, σ g x ≠ x := by
  classical
  obtain ⟨K, hK⟩ := exists_fins_normal_avoiding G F
  let N : Subgroup G := K.toSubgroup
  let e : (G ⧸ N) ≃ Fin (Nat.card (G ⧸ N)) := Finite.equivFin _
  refine ⟨Nat.card (G ⧸ N), (Equiv.permCongrHom e).toMonoidHom.comp (MulAction.toPermHom G (G ⧸ N)),
    Nat.card_pos, fun g hg hg1 x hx => ?_⟩
  apply hK g hg hg1
  obtain ⟨y, rfl⟩ := e.surjective x
  obtain ⟨z, rfl⟩ := QuotientGroup.mk_surjective y
  simp only [MonoidHom.coe_comp, Function.comp_apply, MulEquiv.coe_toMonoidHom,
    Equiv.permCongrHom_coe, Equiv.permCongr_apply, Equiv.symm_apply_apply,
    MulAction.toPermHom_apply, MulAction.toPerm_apply] at hx
  have h2 := e.injective hx
  change ((g * z : G) : G ⧸ N) = z at h2
  rw [QuotientGroup.eq] at h2
  have h3 : z⁻¹ * g⁻¹ * z ∈ N := by simpa [mul_assoc] using h2
  have h4 := (inferInstance : N.Normal).conj_mem _ h3 z
  have h5 : g⁻¹ ∈ N := by simpa [mul_assoc] using h4
  exact (FiniteIndexNormalSubgroup.mem_toSubgroup_iff).mp (N.inv_mem_iff.mp h5)

#print axioms exact_picture_pos

/-- Every residually finite group is sofic. (Mathlib's `Group.ResiduallyFinite`: every member
other than `e` survives in some finite quotient.) -/
theorem residually_finite_group_is_sofic (G : Type*) [Group G] [Group.ResiduallyFinite G] :
    IsSofic G := by
  intro F ε hε
  obtain ⟨n, σ, hn, hσ⟩ := exact_picture_pos G F
  refine ⟨n, σ, fun g _ h _ => ?_, fun g hg hg1 => ?_⟩
  · simp [permDist, map_mul, hammingDist_self, hε.le]
  · have hd : hammingDist (σ g : Fin n → Fin n) ((1 : Equiv.Perm (Fin n)) : Fin n → Fin n) = n := by
      unfold hammingDist
      rw [Finset.filter_true_of_mem (fun x _ => by simpa using hσ g hg hg1 x)]
      simp
    have hn' : (n : ℝ) ≠ 0 := by positivity
    rw [permDist, hd, div_self hn']
    linarith

/-- Steps 0 to 2 of the card, with no error at all: for a residually finite group and any
finite set `F` of its members, there is a map `σ` from `G` to the shuffles of some `n` points
that copies every product exactly (it respects multiplication), with at least one point, and under which every member of
`F` other than `e` moves every point. -/
theorem residually_finite_exact_picture (G : Type*) [Group G] [Group.ResiduallyFinite G]
    (F : Finset G) :
    ∃ (n : ℕ) (σ : G →* Equiv.Perm (Fin n)), 0 < n ∧ ∀ g ∈ F, g ≠ 1 → ∀ x : Fin n, σ g x ≠ x := by
  obtain ⟨n, σ, hn, hσ⟩ := exact_picture_pos G F
  exact ⟨n, σ, hn, hσ⟩

/-- Köthe's statement holds in every commutative ring: if `L₀` and `L₁` are nil ideals
(every member has some power equal to 0), then every sum `a + b` with `a ∈ L₀` and `b ∈ L₁`
also has some power equal to 0. -/
theorem kothe_holds_in_commutative_rings {R : Type*} [CommRing R] (L₀ L₁ : Ideal R)
    (h₀ : ∀ x ∈ L₀, IsNilpotent x) (h₁ : ∀ x ∈ L₁, IsNilpotent x) :
    ∀ a ∈ L₀, ∀ b ∈ L₁, IsNilpotent (a + b) := by
  intro a ha b hb
  exact (Commute.all a b).isNilpotent_add (h₀ a ha) (h₁ b hb)

/-! The card's exact worked numbers. -/

-- S³ = [[1, 3], [0, 1]], the ball's largest entry 3; and T² = −I.
example : (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) ^ 3 = !![1, 3; 0, 1] := by
  decide

example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = -1 := by
  decide

-- Prime 2 is too small: T² = −I reads as I mod 2.
example : (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)) ^ 2 = 1 := by
  decide

-- Prime 3 is too small: S³ reads as I mod 3.
example : (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) (ZMod 3)) ^ 3 = 1 := by
  decide

-- SL(2, F_5) has 120 members, by brute force over all (a, b, c, d) with ad − bc = 1,
-- and by the formula p(p² − 1) at p = 5.
set_option maxRecDepth 100000 in
example : (Finset.univ.filter
    (fun x : ZMod 5 × ZMod 5 × ZMod 5 × ZMod 5 => x.1 * x.2.2.2 - x.2.1 * x.2.2.1 = 1)).card
      = 120 := by
  decide

example : 5 * (5 ^ 2 - 1) = 120 := by
  norm_num

-- Two square-zero matrices whose sum squares to I: E12² = 0, E21² = 0, (E12 + E21)² = I.
example : (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = 0 ∧
    (!![0, 0; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = 0 ∧
    (!![0, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = 1 := by
  decide

-- The left ideal of M2(F_2) made from E12 contains E21 · E12 = E22, and E22² = E22.
example : (!![0, 0; 1, 0] : Matrix (Fin 2) (Fin 2) (ZMod 2)) * !![0, 1; 0, 0] = !![0, 0; 0, 1] ∧
    (!![0, 0; 0, 1] : Matrix (Fin 2) (Fin 2) (ZMod 2)) ^ 2 = !![0, 0; 0, 1] := by
  decide

-- In Z/72 the nilpotent remainders (some power up to the 7th is 0, as in the code) are
-- exactly the 12 multiples of 6.
example : ∀ x : ZMod 72, (∃ k ∈ Finset.Icc 1 7, x ^ k = 0) ↔ 6 ∣ x.val := by
  decide

example : (Finset.univ.filter (fun x : ZMod 72 => ∃ k ∈ Finset.Icc 1 7, x ^ k = 0)).card = 12 := by
  decide

#print axioms residually_finite_group_is_sofic
#print axioms residually_finite_exact_picture
#print axioms kothe_holds_in_commutative_rings

end SoficKothe
