-- Semidirect products: a group with a normal subgroup N and a subgroup H that meet only in the identity and fill the group is N twisted by H acting by conjugation, the clock rule (a, s)(b, t) = (a + u^s b, s + t) is a group when u has an undo and u^m = 1, and for primes q < p a group of order pq is cyclic when q does not divide p - 1 and one of at most two groups when it does.
import Mathlib.GroupTheory.SemidirectProduct
import Mathlib.GroupTheory.GroupAction.ConjAct
import Mathlib.GroupTheory.SpecificGroups.Cyclic
import Mathlib.Data.ZMod.Basic
import Mathlib.GroupTheory.SpecificGroups.ZGroup
import Mathlib.RingTheory.IntegralDomain
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Data.Nat.Squarefree

open scoped Pointwise

universe u

/-- The clock rule of the card: a pair (a, s) is a turn count a on an n-clock and a flip count s
on an m-clock, and (a, s)(b, t) = (a + u^s b, s + t), with u a multiplier on the n-clock. -/
def twist (n m : ℕ) (u : ZMod n) (x y : ZMod n × ZMod m) : ZMod n × ZMod m :=
  (x.1 + u ^ x.2.val * y.1, x.2 + y.2)

lemma pow_val_add {n m : ℕ} [NeZero m] (u : ZMod n) (hum : u ^ m = 1) (s t : ZMod m) :
    u ^ (s + t).val = u ^ s.val * u ^ t.val := by
  rw [← pow_add, ZMod.val_add, ← pow_eq_pow_mod _ hum]

lemma hom_eq_one_of_coprime {H K : Type*} [Group H] [Group K] (f : H →* K)
    (h : (Nat.card H).Coprime (Nat.card K)) : f = 1 := by
  ext x
  have h1 : orderOf (f x) ∣ Nat.card H := (orderOf_map_dvd f x).trans (orderOf_dvd_natCard x)
  have h2 : orderOf (f x) ∣ Nat.card K := orderOf_dvd_natCard _
  have h3 := Nat.Coprime.coprime_dvd_left h1 (Nat.Coprime.coprime_dvd_right h2 h)
  exact orderOf_eq_one_iff.mp (by simpa using h3)

lemma isCyclic_semidirect_of_eq_one {N H : Type*} [Group N] [Group H] [IsCyclic N] [IsCyclic H]
    (φ : H →* MulAut N) (hφ : φ = 1) (hc : (Nat.card N).Coprime (Nat.card H)) :
    IsCyclic (N ⋊[φ] H) := by
  subst hφ
  exact (SemidirectProduct.mulEquivProd).isCyclic.mpr (Group.isCyclic_prod_iff.mpr ⟨‹_›, ‹_›, hc⟩)

lemma order_pq_decomp {p q : ℕ} (hp : p.Prime) (hq : q.Prime) (hqp : q < p)
    (G : Type u) [Group G] (hG : Nat.card G = p * q) :
    ∃ (N H : Subgroup G) (φ : H →* MulAut N) (_ : G ≃* N ⋊[φ] H),
      IsCyclic H ∧ IsCyclic N ∧ (Nat.card N).Coprime (Nat.card H) ∧
        ((Nat.card N = p ∧ Nat.card H = q) ∨ φ = 1) := by
  have hpq0 : p * q ≠ 0 := Nat.mul_ne_zero hp.ne_zero hq.ne_zero
  have : Finite G := Nat.finite_of_card_ne_zero (hG ▸ hpq0)
  have hsq : Squarefree (Nat.card G) := by
    rw [hG, Nat.squarefree_mul_iff]
    exact ⟨(Nat.coprime_primes hp hq).mpr hqp.ne', hp.squarefree, hq.squarefree⟩
  have := IsZGroup.of_squarefree hsq
  obtain ⟨N, H, φ, e, hH, hN, hc⟩ := (isZGroup_iff_exists_mulEquiv (G := G)).mp this
  refine ⟨N, H, φ, e, hH, hN, hc, ?_⟩
  have hcard : Nat.card N * Nat.card H = p * q := by
    rw [← hG, Nat.card_congr e.toEquiv, SemidirectProduct.card]
  have hdvd : Nat.card N ∣ p * q := ⟨_, hcard.symm⟩
  obtain ⟨y, z, hy, hz, hyz⟩ := Nat.dvd_mul.mp hdvd
  have hq1 : 1 < q := hq.one_lt
  rcases hp.eq_one_or_self_of_dvd y hy with hy' | hy' <;>
    rcases hq.eq_one_or_self_of_dvd z hz with hz' | hz' <;> rw [hy', hz'] at hyz
  · -- N trivial
    right
    apply hom_eq_one_of_coprime
    rw [IsCyclic.card_mulAut, ← hyz]
    simp
  · -- |N| = q, |H| = p
    right
    apply hom_eq_one_of_coprime
    have hH' : Nat.card H = p := by
      rw [← hyz, one_mul, mul_comm p q] at hcard
      exact Nat.eq_of_mul_eq_mul_left hq.pos hcard
    rw [IsCyclic.card_mulAut, ← hyz, one_mul, Nat.totient_prime hq, hH']
    exact (Nat.Prime.coprime_iff_not_dvd hp).mpr (Nat.not_dvd_of_pos_of_lt (by omega) (by omega))
  · left
    refine ⟨by rw [← hyz, mul_one], ?_⟩
    rw [← hyz, mul_one] at hcard
    exact Nat.eq_of_mul_eq_mul_left hp.pos hcard
  · right
    apply hom_eq_one_of_coprime
    have hH' : Nat.card H = 1 := by
      rw [← hyz] at hcard
      exact Nat.eq_of_mul_eq_mul_left (Nat.mul_pos hp.pos hq.pos) (by rw [hcard, mul_one])
    rw [hH']
    exact Nat.coprime_one_left _

lemma injective_of_ne_one {H K : Type*} [Group H] [Group K] {q : ℕ} (hq : q.Prime)
    (hH : Nat.card H = q) (f : H →* K) (hf : f ≠ 1) : Function.Injective f := by
  have : Fact (Nat.card H).Prime := ⟨hH ▸ hq⟩
  rcases Subgroup.eq_bot_or_eq_top_of_prime_card f.ker with h | h
  · exact (MonoidHom.ker_eq_bot_iff f).mp h
  · exact absurd (MonoidHom.ker_eq_top_iff.mp h) hf

lemma semidirect_unique {N₁ H₁ N₂ H₂ : Type*} [Group N₁] [Group H₁] [Group N₂] [Group H₂]
    {p q : ℕ} (hp : p.Prime) (hq : q.Prime) (hN₁ : Nat.card N₁ = p) (hN₂ : Nat.card N₂ = p)
    (hH₁ : Nat.card H₁ = q) (hH₂ : Nat.card H₂ = q)
    (φ₁ : H₁ →* MulAut N₁) (φ₂ : H₂ →* MulAut N₂) (h₁ : φ₁ ≠ 1) (h₂ : φ₂ ≠ 1) :
    Nonempty (N₁ ⋊[φ₁] H₁ ≃* N₂ ⋊[φ₂] H₂) := by
  have : Fact p.Prime := ⟨hp⟩
  have : IsCyclic N₁ := isCyclic_of_prime_card hN₁
  have : IsCyclic N₂ := isCyclic_of_prime_card hN₂
  have : Finite N₂ := Nat.finite_of_card_ne_zero (hN₂ ▸ hp.ne_zero)
  let fn : N₁ ≃* N₂ := mulEquivOfCyclicCardEq (hN₁.trans hN₂.symm)
  let ψ : H₁ →* MulAut N₂ := (MulAut.congr fn).toMonoidHom.comp φ₁
  have hψ1 : ψ ≠ 1 := by
    intro h
    apply h₁
    ext g x
    have := DFunLike.congr_fun h g
    simp only [ψ, MonoidHom.comp_apply, MulEquiv.coe_toMonoidHom, MonoidHom.one_apply] at this
    rw [(MulAut.congr fn).map_eq_one_iff] at this
    simp [this]
  have hψ := injective_of_ne_one hq hH₁ ψ hψ1
  have hφ₂ := injective_of_ne_one hq hH₂ φ₂ h₂
  let eA := IsCyclic.mulAutMulEquiv N₂
  have : IsCyclic (MulAut N₂) := eA.isCyclic.mpr (by rw [hN₂]; infer_instance)
  have : Finite (MulAut N₂) := Finite.of_equiv _ eA.symm.toEquiv
  have hr : ψ.range = φ₂.range := by
    rw [IsCyclic.subgroup_eq_iff_card_eq, ← Nat.card_congr (MonoidHom.ofInjective hψ).toEquiv,
      ← Nat.card_congr (MonoidHom.ofInjective hφ₂).toEquiv, hH₁, hH₂]
  let fg : H₁ ≃* H₂ := (MonoidHom.ofInjective hψ).trans
    ((MulEquiv.subgroupCongr hr).trans (MonoidHom.ofInjective hφ₂).symm)
  have hfg : ∀ g, φ₂ (fg g) = ψ g := by
    intro g
    have : MonoidHom.ofInjective hφ₂ (fg g) =
        MulEquiv.subgroupCongr hr (MonoidHom.ofInjective hψ g) := by
      simp only [fg, MulEquiv.trans_apply, MulEquiv.apply_symm_apply]
    have := congrArg Subtype.val this
    simpa [MonoidHom.ofInjective_apply] using this
  refine ⟨SemidirectProduct.congr fn fg fun g => ?_⟩
  rw [hfg g]
  ext x
  simp [ψ, MulAut.congr_apply]

/-- Recognising a semidirect product: if N is a normal subgroup of G and H a subgroup, N and H
share only the identity, and every member of G is a product x h with x in N and h in H, then G is
the semidirect product of N by H, with H acting on N by conjugation (h sends y to h y h⁻¹); the
match sends the pair (x, h) to the product x h. -/
theorem semidirect_product_of_normal_complement {G : Type*} [Group G] (N H : Subgroup G)
    [N.Normal] (hmeet : N ⊓ H = ⊥) (hfill : (N : Set G) * (H : Set G) = Set.univ) :
    ∃ e : N ⋊[MulAut.conjNormal.comp H.subtype] H ≃* G,
      ∀ (x : N) (h : H), e ⟨x, h⟩ = (x : G) * h := by
  have hc : N.IsComplement' H :=
    Subgroup.isComplement'_of_disjoint_and_mul_eq_univ (disjoint_iff.mpr hmeet) hfill
  refine ⟨MulEquiv.ofBijective (SemidirectProduct.lift N.subtype H.subtype ?_) ?_,
    fun x h => rfl⟩
  · intro g
    ext x
    simp [MulAut.conjNormal_apply]
  · exact (SemidirectProduct.equivProd.bijective_comp _).mpr hc

/-- The pairs are a group: when the multiplier u can be undone on the n-clock and u^m = 1, the
twisted rule on an n-clock by an m-clock brackets either way, has (0, 0) as its identity, and
gives every pair an undo. -/
theorem twist_is_group {n m : ℕ} [NeZero m] (u : ZMod n) (hu : IsUnit u) (hum : u ^ m = 1) :
    (∀ x y z : ZMod n × ZMod m, twist n m u (twist n m u x y) z = twist n m u x (twist n m u y z)) ∧
      (∀ x : ZMod n × ZMod m, twist n m u (0, 0) x = x ∧ twist n m u x (0, 0) = x) ∧
      (∀ x : ZMod n × ZMod m, ∃ y, twist n m u x y = (0, 0) ∧ twist n m u y x = (0, 0)) := by
  have _ := hu
  refine ⟨fun x y z => ?_, fun x => ?_, fun x => ?_⟩
  · simp only [twist, pow_val_add u hum]
    ext <;> simp only <;> ring
  · simp [twist]
  · refine ⟨(-(u ^ (-x.2).val * x.1), -x.2), ?_, ?_⟩
    · have h0 := pow_val_add u hum x.2 (-x.2)
      rw [add_neg_cancel, ZMod.val_zero, pow_zero] at h0
      simp only [twist, Prod.mk.injEq, add_neg_cancel, and_true]
      rw [mul_neg, ← mul_assoc, ← h0, one_mul, add_neg_cancel]
    · simp only [twist, neg_add_cancel]

/-- The groups of order pq, for primes q < p: a twist u ≠ 1 with u^q = 1 on the p-clock exists
exactly when q divides p - 1; when q does not divide p - 1 every group of order pq is the
pq-clock (cyclic); and any two groups of order pq that are not cyclic are the same group
relabelled, so there are at most two groups of order pq. -/
theorem groups_of_order_pq {p q : ℕ} (hp : p.Prime) (hq : q.Prime) (hqp : q < p) :
    ((∃ v : ZMod p, v ≠ 1 ∧ v ^ q = 1) ↔ q ∣ p - 1) ∧
      (∀ (G : Type u) [Group G], Nat.card G = p * q → ¬ q ∣ p - 1 → IsCyclic G) ∧
      (∀ (G₁ G₂ : Type u) [Group G₁] [Group G₂], Nat.card G₁ = p * q → Nat.card G₂ = p * q →
        ¬ IsCyclic G₁ → ¬ IsCyclic G₂ → Nonempty (G₁ ≃* G₂)) := by
  have hq1 := hq.one_lt
  have : Fact p.Prime := ⟨hp⟩
  refine ⟨⟨?_, ?_⟩, ?_, ?_⟩
  · rintro ⟨v, hv1, hvq⟩
    have hv0 : v ≠ 0 := by
      rintro rfl
      rw [zero_pow hq.ne_zero] at hvq
      exact zero_ne_one hvq
    have ho : orderOf v = q := by
      rcases hq.eq_one_or_self_of_dvd _ (orderOf_dvd_of_pow_eq_one hvq) with h | h
      · exact absurd (orderOf_eq_one_iff.mp h) hv1
      · exact h
    rw [← ho]
    exact orderOf_dvd_of_pow_eq_one (ZMod.pow_card_sub_one_eq_one hv0)
  · intro hdvd
    have : Fact q.Prime := ⟨hq⟩
    obtain ⟨u, hu⟩ := exists_prime_orderOf_dvd_card q (G := (ZMod p)ˣ) (by rwa [ZMod.card_units p])
    refine ⟨(u : ZMod p), fun h => ?_, ?_⟩
    · have := (orderOf_units (y := u)).trans hu
      rw [h, orderOf_one] at this
      omega
    · rw [← hu, ← orderOf_units]
      exact pow_orderOf_eq_one _
  · intro G _ hG hnd
    have : Finite G := Nat.finite_of_card_ne_zero (hG ▸ Nat.mul_ne_zero hp.ne_zero hq.ne_zero)
    obtain ⟨N, H, φ, e, hH, hN, hc, hcase⟩ := order_pq_decomp hp hq hqp G hG
    have hφ : φ = 1 := by
      rcases hcase with ⟨hNp, hHq⟩ | h
      · apply hom_eq_one_of_coprime
        rw [IsCyclic.card_mulAut, hNp, Nat.totient_prime hp, hHq]
        exact (Nat.Prime.coprime_iff_not_dvd hq).mpr hnd
      · exact h
    exact e.isCyclic.mpr (isCyclic_semidirect_of_eq_one φ hφ hc)
  · intro G₁ G₂ _ _ h₁ h₂ hn₁ hn₂
    obtain ⟨N₁, H₁, φ₁, e₁, hH₁, hN₁, hc₁, hcase₁⟩ := order_pq_decomp hp hq hqp G₁ h₁
    obtain ⟨N₂, H₂, φ₂, e₂, hH₂, hN₂, hc₂, hcase₂⟩ := order_pq_decomp hp hq hqp G₂ h₂
    have hφ₁ : φ₁ ≠ 1 := fun h => hn₁ (e₁.isCyclic.mpr (isCyclic_semidirect_of_eq_one φ₁ h hc₁))
    have hφ₂ : φ₂ ≠ 1 := fun h => hn₂ (e₂.isCyclic.mpr (isCyclic_semidirect_of_eq_one φ₂ h hc₂))
    rcases hcase₁ with ⟨a₁, b₁⟩ | h
    · rcases hcase₂ with ⟨a₂, b₂⟩ | h
      · obtain ⟨f⟩ := semidirect_unique hp hq a₁ a₂ b₁ b₂ φ₁ φ₂ hφ₁ hφ₂
        exact ⟨e₁.trans (f.trans e₂.symm)⟩
      · exact absurd h hφ₂
    · exact absurd h hφ₁

-- The tile: Z mod 4 twisted by Z mod 2 with u = 3, which is -1 on a 4-clock.
-- Turn then flip is (3, 1); flip then turn is (1, 1).
example : twist 4 2 3 (0, 1) (1, 0) = (3, 1) ∧ twist 4 2 3 (1, 0) (0, 1) = (1, 1) := by decide
-- Flip, quarter turn, flip gives (3, 0), the undo of the quarter turn (1, 0).
example : twist 4 2 3 (0, 1) (1, 1) = (3, 0) ∧ twist 4 2 3 (twist 4 2 3 (0, 1) (1, 0)) (0, 1) = (3, 0) ∧
    twist 4 2 3 (1, 0) (3, 0) = (0, 0) := by decide
-- 40 of the 64 pairs of tile moves commute; with no twist (u = 1) all 64 do.
example : (Finset.univ.filter (fun xy : (ZMod 4 × ZMod 2) × (ZMod 4 × ZMod 2) =>
    twist 4 2 3 xy.1 xy.2 = twist 4 2 3 xy.2 xy.1)).card = 40 := by decide
example : (Finset.univ.filter (fun xy : (ZMod 4 × ZMod 2) × (ZMod 4 × ZMod 2) =>
    twist 4 2 1 xy.1 xy.2 = twist 4 2 1 xy.2 xy.1)).card = 64 := by decide
-- Order 21: 2^3 = 8 = 1 on the 7-clock, so u = 2 twists; u = 3 fails, 3^3 = 6 on the 7-clock.
example : (2 : ZMod 7) ^ 3 = 1 ∧ (3 : ZMod 7) ^ 3 = 6 := by decide
-- In the twisted 21, (1, 1) twice is (3, 2) and three times is (0, 0).
example : twist 7 3 2 (1, 1) (1, 1) = (3, 2) ∧ twist 7 3 2 (twist 7 3 2 (1, 1) (1, 1)) (1, 1) = (0, 0) := by
  decide
-- The twisted 21: 105 of 441 pairs commute; 14 members of order 3 and 6 of order 7 besides the
-- identity, so none of order 21.
example : (Finset.univ.filter (fun xy : (ZMod 7 × ZMod 3) × (ZMod 7 × ZMod 3) =>
    twist 7 3 2 xy.1 xy.2 = twist 7 3 2 xy.2 xy.1)).card = 105 := by decide
example : (Finset.univ.filter (fun x : ZMod 7 × ZMod 3 =>
    x ≠ (0, 0) ∧ twist 7 3 2 (twist 7 3 2 x x) x = (0, 0))).card = 14 := by decide
example : (Finset.univ.filter (fun x : ZMod 7 × ZMod 3 =>
    x ≠ (0, 0) ∧ (fun y => twist 7 3 2 y x)^[6] x = (0, 0))).card = 6 := by decide
-- u = 4 is u = 2 relabelled: renaming s as 2s on the 3-clock carries one rule to the other.
example : ∀ x y : ZMod 7 × ZMod 3,
    ((twist 7 3 2 x y).1, 2 * (twist 7 3 2 x y).2) = twist 7 3 4 (x.1, 2 * x.2) (y.1, 2 * y.2) := by
  decide
-- The mistake of twisting by the right-hand move's flip breaks 192 of the tile's 512 triples.
set_option maxRecDepth 20000 in
example : (Finset.univ.filter (fun xyz : (ZMod 4 × ZMod 2) × (ZMod 4 × ZMod 2) × (ZMod 4 × ZMod 2) =>
    let f := fun x y : ZMod 4 × ZMod 2 => (x.1 + (3 : ZMod 4) ^ y.2.val * y.1, x.2 + y.2)
    f (f xyz.1 xyz.2.1) xyz.2.2 ≠ f xyz.1 (f xyz.2.1 xyz.2.2))).card = 192 := by decide
-- The multipliers u with u^q = 1 on the p-clock: [1, 2, 4] for 21, [1] for 15, [1, 2] for 6.
example : Finset.univ.filter (fun v : ZMod 7 => v ^ 3 = 1) = {1, 2, 4} := by decide
example : Finset.univ.filter (fun v : ZMod 5 => v ^ 3 = 1) = {1} := by decide
example : Finset.univ.filter (fun v : ZMod 3 => v ^ 2 = 1) = {1, 2} := by decide
-- 3 divides 6 (order 21), 3 does not divide 4 (order 15), 2 divides 2 (order 6).
example : 3 ∣ 7 - 1 ∧ ¬ 3 ∣ 5 - 1 ∧ 2 ∣ 3 - 1 := by decide

#print axioms pow_val_add
#print axioms hom_eq_one_of_coprime
#print axioms isCyclic_semidirect_of_eq_one
#print axioms order_pq_decomp
#print axioms injective_of_ne_one
#print axioms semidirect_unique
#print axioms semidirect_product_of_normal_complement
#print axioms twist_is_group
#print axioms groups_of_order_pq
