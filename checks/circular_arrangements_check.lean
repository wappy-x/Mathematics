-- Round tables and bracelets: n different things placed round a ring make (n - 1)! arrangements when turning the ring counts as the same, each such family holding exactly n row-orders, and (n - 1)! / 2 when turning it over counts as the same too, for n at least 3.
import Mathlib.Data.Fintype.Perm
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib

/-! An arrangement of n different things round a ring is a one-to-one matching
`f : Fin n ≃ α` of the n positions with the n things: position `i` holds thing `f i`.
Turning the ring by `k` places gives the arrangement `i ↦ f (i + k)`; turning it over as
well gives `i ↦ f (k - i)` (positions are counted round the ring, so `+` and `-` wrap). -/

theorem card_eq_mul_card_quot_of_classes {X : Type*} [Finite X] (r : X → X → Prop)
    (hr : Equivalence r) (m : ℕ) (hm : ∀ x, Nat.card {y // r x y} = m) :
    Nat.card X = m * Nat.card (Quot r) := by
  classical
  have hfib : ∀ q : Quot r, Nat.card {y // Quot.mk r y = q} = m := by
    intro q
    induction q using Quot.ind with
    | mk x =>
      rw [← hm x]
      apply Nat.card_congr
      apply Equiv.subtypeEquivRight
      intro y
      constructor
      · intro hy
        exact hr.symm ((hr.eqvGen_iff).mp (Quot.eqvGen_exact hy))
      · intro hy
        exact Quot.sound (hr.symm hy)
  have := Fintype.ofFinite X
  have : Fintype (Quot r) := Fintype.ofFinite _
  rw [← Nat.card_congr (Equiv.sigmaFiberEquiv (Quot.mk r)), Nat.card_sigma]
  simp only [hfib, Finset.sum_const, Finset.card_univ, smul_eq_mul, Nat.card_eq_fintype_card]
  ring

theorem card_equiv_fin_eq_factorial {α : Type*} [Fintype α] (n : ℕ)
    (h : Fintype.card α = n) : Nat.card (Fin n ≃ α) = n.factorial := by
  classical
  rw [Nat.card_eq_fintype_card, Fintype.card_equiv (Fintype.equivFinOfCardEq h).symm,
    Fintype.card_fin]

theorem card_quot_fin_zero_equiv {α : Type*} [Fintype α] (h : Fintype.card α = 0)
    (r : (Fin 0 ≃ α) → (Fin 0 ≃ α) → Prop) : Nat.card (Quot r) = 1 := by
  rw [Nat.card_eq_one_iff_unique]
  refine ⟨⟨fun a b => ?_⟩, ⟨Quot.mk _ (Fintype.equivFinOfCardEq h).symm⟩⟩
  induction a using Quot.ind with
  | mk a =>
    induction b using Quot.ind with
    | mk b =>
      congr 1
      exact Equiv.ext fun i => Fin.elim0 i

#print axioms card_eq_mul_card_quot_of_classes
#print axioms card_equiv_fin_eq_factorial
#print axioms card_quot_fin_zero_equiv

theorem rotation_family_card {α : Type*} [Fintype α] (n : ℕ)
    (f : Fin n ≃ α) :
    Nat.card {g : Fin n ≃ α // ∃ k : Fin n, ∀ i, g i = f (i + k)} = n := by
  rcases n with _ | m
  · simp
  · let φ : Fin (m+1) → (Fin (m+1) ≃ α) := fun k => (Equiv.addRight k).trans f
    have hφ : Function.Injective φ := by
      intro k l hkl
      have := congrArg (fun g : Fin (m+1) ≃ α => g 0) hkl
      simpa [φ] using this
    refine (Nat.card_fin (m+1)).symm.trans ?_ |>.symm
    refine Nat.card_congr ((Equiv.ofInjective φ hφ).trans (Equiv.subtypeEquivRight ?_))
    intro g
    simp only [Set.mem_range]
    constructor
    · rintro ⟨k, rfl⟩
      exact ⟨k, fun i => rfl⟩
    · rintro ⟨k, hk⟩
      exact ⟨k, Equiv.ext fun i => (hk i).symm⟩

#print axioms rotation_family_card

/-- Round a table, where moving everyone the same number of chairs round counts as the same
dinner, n different guests make (n - 1)! different dinners: the n! orders in a row, divided
by the n rotations of each one. -/
theorem round_table_count {α : Type*} [Fintype α] (n : ℕ)
    (h : Fintype.card α = n) :
    Nat.card (Quot fun f g : Fin n ≃ α => ∃ k : Fin n, ∀ i, g i = f (i + k)) =
      (n - 1).factorial := by
  rcases n with _ | m
  · simpa using card_quot_fin_zero_equiv h _
  · have hr : Equivalence fun f g : Fin (m+1) ≃ α => ∃ k : Fin (m+1), ∀ i, g i = f (i + k) := by
      refine ⟨fun f => ⟨0, fun i => by simp⟩, ?_, ?_⟩
      · rintro f g ⟨k, hk⟩
        exact ⟨-k, fun i => by simp [hk]⟩
      · rintro f g e ⟨k, hk⟩ ⟨l, hl⟩
        exact ⟨l + k, fun i => by simp [hl, hk, add_assoc]⟩
    have key := card_eq_mul_card_quot_of_classes _ hr (m+1)
      (fun f => rotation_family_card (m+1) f)
    rw [card_equiv_fin_eq_factorial (m+1) h, Nat.factorial_succ] at key
    simp only [Nat.add_sub_cancel]
    exact (Nat.eq_of_mul_eq_mul_left (Nat.succ_pos m) key).symm

/-- Every family of row-orders that turning the ring makes the same holds exactly n of them,
one per starting position, because the n things all differ. -/
theorem round_table_family_size {α : Type*} [Fintype α] (n : ℕ)
    (f : Fin n ≃ α) :
    Nat.card {g : Fin n ≃ α // ∃ k : Fin n, ∀ i, g i = f (i + k)} = n := by
  exact rotation_family_card n f

/-- On a bracelet, which can be turned round and also turned over (reversing the order),
n different beads, with n at least 3, make (n - 1)! / 2 different bracelets: the n! orders
in a row, divided by the 2n turns and flips. -/
theorem bracelet_count {α : Type*} [Fintype α] (n : ℕ)
    (h : Fintype.card α = n) (hn : 3 ≤ n) :
    Nat.card (Quot fun f g : Fin n ≃ α =>
        ∃ k : Fin n, (∀ i, g i = f (i + k)) ∨ (∀ i, g i = f (k - i))) =
      (n - 1).factorial / 2 := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 3 := ⟨n - 3, by omega⟩
  have two_ne : (2 : Fin (m+3)) ≠ 0 := by
    intro h2
    have := congrArg Fin.val h2
    simp at this
    rw [Nat.mod_eq_of_lt (by omega)] at this
    exact absurd this (by norm_num)
  have hr : Equivalence fun f g : Fin (m+3) ≃ α =>
      ∃ k : Fin (m+3), (∀ i, g i = f (i + k)) ∨ (∀ i, g i = f (k - i)) := by
    refine ⟨fun f => ⟨0, Or.inl fun i => by simp⟩, ?_, ?_⟩
    · rintro f g ⟨k, hk | hk⟩
      · exact ⟨-k, Or.inl fun i => by simp [hk]⟩
      · exact ⟨k, Or.inr fun i => by simp [hk]⟩
    · rintro f g e ⟨k, hk | hk⟩ ⟨l, hl | hl⟩
      · exact ⟨l + k, Or.inl fun i => by simp [hl, hk, add_assoc]⟩
      · exact ⟨l + k, Or.inr fun i => by rw [hl, hk]; congr 1; abel⟩
      · exact ⟨k - l, Or.inr fun i => by rw [hl, hk]; congr 1; abel⟩
      · exact ⟨k - l, Or.inl fun i => by rw [hl, hk]; congr 1; abel⟩
  have hcls : ∀ f : Fin (m+3) ≃ α, Nat.card {g : Fin (m+3) ≃ α // ∃ k : Fin (m+3),
      (∀ i, g i = f (i + k)) ∨ (∀ i, g i = f (k - i))} = 2 * (m+3) := by
    intro f
    let φ : Fin (m+3) ⊕ Fin (m+3) → (Fin (m+3) ≃ α) :=
      Sum.elim (fun k => (Equiv.addRight k).trans f) (fun k => (Equiv.subLeft k).trans f)
    have hφ : Function.Injective φ := by
      rintro (k | k) (l | l) hkl
      · have := congrArg (fun g : Fin (m+3) ≃ α => g 0) hkl
        simpa [φ] using this
      · have h0 := congrArg (fun g : Fin (m+3) ≃ α => g 0) hkl
        have h1 := congrArg (fun g : Fin (m+3) ≃ α => g 1) hkl
        simp [φ] at h0 h1
        subst h0
        let := Fin.instCommRing (m+3)
        exact absurd (by linear_combination h1) two_ne
      · have h0 := congrArg (fun g : Fin (m+3) ≃ α => g 0) hkl
        have h1 := congrArg (fun g : Fin (m+3) ≃ α => g 1) hkl
        simp [φ] at h0 h1
        subst h0
        let := Fin.instCommRing (m+3)
        exact absurd (by linear_combination -h1) two_ne
      · have := congrArg (fun g : Fin (m+3) ≃ α => g 0) hkl
        simpa [φ] using this
    have e := (Equiv.ofInjective φ hφ).trans (Equiv.subtypeEquivRight (p := (· ∈ Set.range φ))
      (q := fun g => ∃ k : Fin (m+3), (∀ i, g i = f (i + k)) ∨ (∀ i, g i = f (k - i))) ?_)
    · rw [← Nat.card_congr e, Nat.card_sum, Nat.card_fin]
      ring
    · intro g
      simp only [Set.mem_range]
      constructor
      · rintro ⟨k | k, rfl⟩
        · exact ⟨k, Or.inl fun i => rfl⟩
        · exact ⟨k, Or.inr fun i => rfl⟩
      · rintro ⟨k, hk | hk⟩
        · exact ⟨Sum.inl k, Equiv.ext fun i => (hk i).symm⟩
        · exact ⟨Sum.inr k, Equiv.ext fun i => (hk i).symm⟩
  have key := card_eq_mul_card_quot_of_classes _ hr _ hcls
  rw [card_equiv_fin_eq_factorial (m+3) h] at key
  have hf : (m+3).factorial = (m+3) * (m+2).factorial := Nat.factorial_succ _
  simp only [show m + 3 - 1 = m + 2 by omega]
  rw [hf] at key
  have : (m+2).factorial = 2 * Nat.card _ :=
    Nat.eq_of_mul_eq_mul_left (by omega : 0 < m + 3) (by rw [key]; ring)
  rw [this]
  simp

-- Eight friends: 8! = 40,320 orders in a row, 8 rotations each, 40,320 / 8 = 5,040 = 7! dinners.
example : Nat.factorial 8 = 40320 := by decide
example : 40320 / 8 = 5040 ∧ Nat.factorial 7 = 5040 := by decide
-- Halving the dinner table, the wrong answer: 2,520.
example : Nat.factorial 7 / 2 = 2520 := by decide
-- The picture: four guests, 24 orders, 4 to a row, 6 dinners = 3!.
example : Nat.factorial 4 = 24 ∧ 24 / 4 = 6 ∧ Nat.factorial 3 = 6 := by decide
-- Six different beads: 720 orders, 120 necklaces, 60 bracelets, both ways round.
example : Nat.factorial 6 = 720 ∧ 720 / 6 = 120 ∧ Nat.factorial 5 = 120 := by decide
example : 720 / 12 = 60 ∧ 120 / 2 = 60 ∧ Nat.factorial 5 / 2 = 60 := by decide
-- Three different beads: 2 necklaces, 1 bracelet.
example : Nat.factorial 2 = 2 ∧ Nat.factorial 2 / 2 = 1 := by decide
-- R R B B G Y: 180 orders, 30 necklaces; halving says 15, the 2 mirror-image necklaces make it 16.
example : Nat.factorial 6 / (2 * 2) = 180 ∧ 180 / 6 = 30 ∧ 30 / 2 = 15 ∧ (30 + 2) / 2 = 16 := by decide

#print axioms round_table_count
#print axioms round_table_family_size
#print axioms bracelet_count
