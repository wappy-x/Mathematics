-- Steiner triple systems: a set of v points carries triples covering every pair exactly once exactly when v leaves remainder 1 or 3 on division by 6.
import Mathlib.Data.Finset.Card
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Fintype.Prod
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.Ring
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.LinearCombination
import Mathlib.Data.ZMod.Basic

open Finset

/-- `B` is a Steiner triple system on the point set `V`: every block is a 3-point subset of `V`,
and every pair of different points of `V` lies in exactly one block. -/
def IsSteinerTripleSystem {α : Type*} [DecidableEq α] (V : Finset α) (B : Finset (Finset α)) : Prop :=
  (∀ t ∈ B, t ⊆ V ∧ t.card = 3) ∧
    ∀ x ∈ V, ∀ y ∈ V, x ≠ y → (B.filter fun t => x ∈ t ∧ y ∈ t).card = 1

instance {α : Type*} [DecidableEq α] (V : Finset α) (B : Finset (Finset α)) :
    Decidable (IsSteinerTripleSystem V B) := by
  unfold IsSteinerTripleSystem; infer_instance

theorem sts_point_count {α : Type*} [DecidableEq α] (V : Finset α)
    (B : Finset (Finset α)) (h : IsSteinerTripleSystem V B) (x : α) (hx : x ∈ V) :
    (B.filter fun t => x ∈ t).card * 2 = V.card - 1 := by
  have key := Finset.sum_card_inter (s := V.erase x) (B := B.filter fun t => x ∈ t) (n := 1)
    (by
      intro a ha
      rw [Finset.filter_filter]
      have := h.2 x hx a (Finset.mem_of_mem_erase ha) (Finset.ne_of_mem_erase ha).symm
      simpa using this)
  rw [Finset.card_erase_of_mem hx, mul_one] at key
  rw [← key, Finset.card_eq_sum_ones, Finset.sum_mul]
  apply Finset.sum_congr rfl
  intro t ht
  rw [Finset.mem_filter] at ht
  obtain ⟨htB, hxt⟩ := ht
  have hsub := (h.1 t htB).1
  have : V.erase x ∩ t = t.erase x := by
    ext y; simp only [Finset.mem_inter, Finset.mem_erase]
    constructor
    · rintro ⟨⟨h1, _⟩, h3⟩; exact ⟨h1, h3⟩
    · rintro ⟨h1, h3⟩; exact ⟨⟨h1, hsub h3⟩, h3⟩
  rw [this, Finset.card_erase_of_mem hxt, (h.1 t htB).2]
  rfl
#print axioms sts_point_count

theorem sts_counts_aux {α : Type*} [DecidableEq α] (V : Finset α)
    (B : Finset (Finset α)) (h : IsSteinerTripleSystem V B) :
    B.card * 6 = V.card * (V.card - 1) ∧
      ∀ x ∈ V, (B.filter fun t => x ∈ t).card * 2 = V.card - 1 := by
  refine ⟨?_, sts_point_count V B h⟩
  have h3 : ∑ t ∈ B, (V ∩ t).card = B.card * 3 := by
    rw [Finset.card_eq_sum_ones, Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro t ht
    rw [Finset.inter_eq_right.mpr (h.1 t ht).1, (h.1 t ht).2, one_mul]
  have hsum : ∑ t ∈ B, (V ∩ t).card = ∑ x ∈ V, (B.filter fun t => x ∈ t).card := by
    simp_rw [← Finset.filter_mem_eq_inter, Finset.card_eq_sum_ones, Finset.sum_filter]
    exact Finset.sum_comm
  have h2 : (∑ x ∈ V, (B.filter fun t => x ∈ t).card) * 2 = V.card * (V.card - 1) := by
    rw [Finset.sum_mul, Finset.sum_congr rfl (fun x hx => sts_point_count V B h x hx)]
    simp
  rw [← h2, ← hsum, h3]; ring
#print axioms sts_counts_aux

theorem sts_necessity (v : ℕ) (hv : 0 < v) (B : Finset (Finset ℕ))
    (h : IsSteinerTripleSystem (range v) B) : v % 6 = 1 ∨ v % 6 = 3 := by
  obtain ⟨h1, h2⟩ := sts_counts_aux _ B h
  have h2' := h2 0 (by simpa using hv)
  simp only [card_range] at h1 h2'
  have hmod : v * (v - 1) % 6 = 0 := by rw [← h1]; simp
  rw [Nat.mul_mod] at hmod
  have : v % 6 < 6 := Nat.mod_lt _ (by norm_num)
  have e : (v - 1) % 6 = (v % 6 + 5) % 6 := by omega
  rw [e] at hmod
  interval_cases hr : v % 6 <;> omega
#print axioms sts_necessity

theorem sts_of_third {α : Type*} [Fintype α] [DecidableEq α] (c : α → α → α)
    (h1 : ∀ x y, x ≠ y → c x y ≠ x) (hcomm : ∀ x y, c x y = c y x)
    (hinv : ∀ x y, x ≠ y → c x (c x y) = y) (B : Finset (Finset α))
    (hB : ∀ t ∈ B, ∃ x y, x ≠ y ∧ t = {x, y, c x y})
    (hB' : ∀ x y, x ≠ y → ({x, y, c x y} : Finset α) ∈ B) :
    IsSteinerTripleSystem univ B := by
  have h2 : ∀ x y, x ≠ y → c x y ≠ y := fun x y hxy => by
    rw [hcomm]; exact h1 y x (Ne.symm hxy)
  have hcard : ∀ x y, x ≠ y → ({x, y, c x y} : Finset α).card = 3 := by
    intro x y hxy
    rw [Finset.card_insert_of_notMem, Finset.card_pair (h2 x y hxy).symm]
    simp only [Finset.mem_insert, Finset.mem_singleton, not_or]
    exact ⟨hxy, (h1 x y hxy).symm⟩
  refine ⟨fun t ht => ?_, fun x _ y _ hxy => ?_⟩
  · obtain ⟨x, y, hxy, rfl⟩ := hB t ht
    exact ⟨Finset.subset_univ _, hcard x y hxy⟩
  · rw [Finset.card_eq_one]
    refine ⟨{x, y, c x y}, ?_⟩
    ext t
    simp only [Finset.mem_filter, Finset.mem_singleton]
    constructor
    · rintro ⟨ht, hx, hy⟩
      obtain ⟨a, b, hab, rfl⟩ := hB t ht
      have e1 : c b a = c a b := hcomm b a
      have e2 : c a (c a b) = b := hinv a b hab
      have e3 : c (c a b) a = b := by rw [hcomm]; exact e2
      have e4 : c b (c a b) = a := by rw [← e1]; exact hinv b a (Ne.symm hab)
      have e5 : c (c a b) b = a := by rw [hcomm]; exact e4
      simp only [Finset.mem_insert, Finset.mem_singleton] at hx hy
      rcases hx with rfl | rfl | rfl <;> rcases hy with rfl | rfl | rfl <;>
        first
        | exact absurd rfl hxy
        | (simp only [e1, e2, e3, e4, e5]; done)
        | (simp only [e1, e2, e3, e4, e5]; ext z; simp only [Finset.mem_insert, Finset.mem_singleton]; tauto)
    · rintro rfl
      refine ⟨hB' x y hxy, by simp, by simp⟩
#print axioms sts_of_third

theorem sts_map {α β : Type*} [DecidableEq α] [DecidableEq β] (f : α ↪ β) {V : Finset α}
    {B : Finset (Finset α)} (h : IsSteinerTripleSystem V B) :
    IsSteinerTripleSystem (V.map f) (B.image fun t => t.map f) := by
  refine ⟨fun t ht => ?_, fun x hx y hy hxy => ?_⟩
  · obtain ⟨s, hs, rfl⟩ := Finset.mem_image.mp ht
    exact ⟨Finset.map_subset_map.mpr (h.1 s hs).1, by rw [Finset.card_map, (h.1 s hs).2]⟩
  · obtain ⟨a, ha, rfl⟩ := Finset.mem_map.mp hx
    obtain ⟨b, hb, rfl⟩ := Finset.mem_map.mp hy
    have hab : a ≠ b := fun e => hxy (by rw [e])
    rw [Finset.filter_image, Finset.card_image_of_injective _ (Finset.map_injective f)]
    simp only [Finset.mem_map']
    exact h.2 a ha b hb hab
#print axioms sts_map

theorem sts_range_of_fintype {T : Type*} [Fintype T] [DecidableEq T] {B : Finset (Finset T)}
    (h : IsSteinerTripleSystem univ B) :
    ∃ B' : Finset (Finset ℕ), IsSteinerTripleSystem (range (Fintype.card T)) B' := by
  let f : T ↪ ℕ := (Fintype.equivFin T).toEmbedding.trans Fin.valEmbedding
  have e : (univ : Finset T).map f = range (Fintype.card T) := by
    rw [← Finset.map_map, Finset.map_univ_equiv, Fin.map_valEmbedding_univ]
    ext m; simp
  exact ⟨_, e ▸ sts_map f h⟩
#print axioms sts_range_of_fintype

theorem z3_a : ∀ i j : ZMod 3, i ≠ j → -i - j ≠ i := by decide
#print axioms z3_a

theorem z3_b : ∀ i : ZMod 3, i + 1 ≠ i := by decide
#print axioms z3_b

theorem z3_c : ∀ i j : ZMod 3, i ≠ j → j ≠ i + 1 → i = j + 1 := by decide
#print axioms z3_c

theorem z3_d : ∀ i : ZMod 3, i ≠ i + 1 + 1 := by decide
#print axioms z3_d

theorem z3_e : ∀ i j : ZMod 3, i ≠ j → ({i, j, -i - j} : Finset (ZMod 3)) = {0, 1, 2} := by decide
#print axioms z3_e

theorem z3_f : ∀ i : ZMod 3, i + 2 ≠ i := by decide
#print axioms z3_f

theorem z3_g : ∀ i : ZMod 3, i - 1 ≠ i := by decide
#print axioms z3_g

theorem z3_h : ∀ i : ZMod 3, i - 1 ≠ i + 1 := by decide
#print axioms z3_h

theorem z3_i : ∀ i : ZMod 3, i + 2 + 2 = i + 1 := by decide
#print axioms z3_i

theorem z3_j : ∀ i : ZMod 3, i + 1 + 2 = i := by decide
#print axioms z3_j

theorem z3_k : ∀ i : ZMod 3, i + 2 ≠ i + 1 := by decide
#print axioms z3_k

theorem bose_two_half (n : ℕ) : (2 : ZMod (2 * n + 1)) * ((n : ZMod (2 * n + 1)) + 1) = 1 := by
  have h : ((2 * n + 1 : ℕ) : ZMod (2 * n + 1)) = 0 := ZMod.natCast_self _
  push_cast at h
  linear_combination h
#print axioms bose_two_half

theorem bose_cancel_two (n : ℕ) {a b : ZMod (2 * n + 1)} (h : 2 * a = 2 * b) : a = b := by
  linear_combination ((n : ZMod (2 * n + 1)) + 1) * h - (a - b) * bose_two_half n
#print axioms bose_cancel_two

/-- The third point of the Bose triple through two points. -/
def boseThird (n : ℕ) (p q : ZMod (2 * n + 1) × ZMod 3) : ZMod (2 * n + 1) × ZMod 3 :=
  if p.1 = q.1 then (p.1, -p.2 - q.2)
  else if p.2 = q.2 then (((n : ZMod (2 * n + 1)) + 1) * (p.1 + q.1), p.2 + 1)
  else if q.2 = p.2 + 1 then (2 * q.1 - p.1, p.2)
  else (2 * p.1 - q.1, q.2)

theorem boseThird_ne (n : ℕ) : ∀ x y, x ≠ y → boseThird n x y ≠ x := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  rintro ⟨x, i⟩ ⟨y, j⟩ hne
  simp only [boseThird]
  split_ifs with e1 e2 e3
  · subst e1
    have : i ≠ j := fun e => hne (by rw [e])
    intro e; exact z3_a i j this (Prod.ext_iff.mp e).2
  · intro e; exact z3_b i (Prod.ext_iff.mp e).2
  · intro e
    simp only [Prod.mk.injEq] at e e1
    exact e1 (hc2 (by linear_combination e.1)).symm
  · intro e
    simp only [Prod.mk.injEq] at e e2
    exact e2 e.2.symm
#print axioms boseThird_ne

theorem boseThird_comm (n : ℕ) : ∀ x y, boseThird n x y = boseThird n y x := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  rintro ⟨x, i⟩ ⟨y, j⟩
  simp only [boseThird]
  by_cases e1 : x = y
  · subst e1; simp only [ite_true]; ext <;> simp only <;> ring
  · rw [if_neg e1, if_neg (Ne.symm e1)]
    by_cases e2 : i = j
    · subst e2; simp only [ite_true]; ext <;> simp only; ring
    · rw [if_neg e2, if_neg (Ne.symm e2)]
      by_cases e3 : j = i + 1
      · subst e3; rw [if_pos rfl, if_neg (z3_d i)]
      · rw [if_neg e3, if_pos (z3_c i j e2 e3)]
#print axioms boseThird_comm

theorem boseThird_inv (n : ℕ) : ∀ x y, x ≠ y → boseThird n x (boseThird n x y) = y := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  rintro ⟨x, i⟩ ⟨y, j⟩ hne
  by_cases e1 : x = y
  · subst e1
    simp only [boseThird, ite_true]
    ext <;> simp only; ring
  · by_cases e2 : i = j
    · subst e2
      have hr : x ≠ ((n : ZMod (2 * n + 1)) + 1) * (x + y) := by
        intro e; apply e1
        linear_combination (2 : ZMod (2 * n + 1)) * e + (x + y) * h2
      simp only [boseThird, if_neg e1, ite_true, if_neg hr, if_neg (z3_b i).symm]
      ext <;> simp only
      linear_combination (x + y) * h2
    · by_cases e3 : j = i + 1
      · subst e3
        have hr : x ≠ 2 * y - x := by
          intro e; apply e1; apply hc2; linear_combination e
        simp only [boseThird, if_neg e1, if_neg e2, ite_true, if_neg hr]
        ext <;> simp only
        linear_combination y * h2
      · have hr : x ≠ 2 * x - y := by
          intro e; apply e1; linear_combination -e
        have hi := z3_c i j e2 e3
        simp only [boseThird, if_neg e1, if_neg e2, if_neg e3, if_neg hr]
        congr 1; ring
#print axioms boseThird_inv

theorem bose_exists (n : ℕ) : ∃ B : Finset (Finset (ZMod (2 * n + 1) × ZMod 3)),
    IsSteinerTripleSystem univ B :=
  ⟨_, sts_of_third (boseThird n) (boseThird_ne n) (boseThird_comm n) (boseThird_inv n)
    (((univ ×ˢ univ).filter fun pq : (ZMod (2 * n + 1) × ZMod 3) × (ZMod (2 * n + 1) × ZMod 3) =>
      pq.1 ≠ pq.2).image fun pq => {pq.1, pq.2, boseThird n pq.1 pq.2})
    (fun t ht => by
      obtain ⟨⟨p, q⟩, hpq, rfl⟩ := Finset.mem_image.mp ht
      exact ⟨p, q, (Finset.mem_filter.mp hpq).2, rfl⟩)
    (fun p q hpq => Finset.mem_image.mpr ⟨(p, q), by simp [hpq], rfl⟩)⟩
#print axioms bose_exists

def sAddN (n a b : ℕ) : ℕ := if a + b < 2 * n then a + b else a + b - 2 * n

def sSig (n s : ℕ) : ℕ := if s % 2 = 0 then s / 2 else n + s / 2

def sRho (n b : ℕ) : ℕ := if b < n then 2 * b else 2 * (b - n) + 1

def sSub (n r a : ℕ) : ℕ := if a ≤ r then r - a else r + 2 * n - a

def sOp (n : ℕ) (x y : Fin (2 * n)) : Fin (2 * n) :=
  ⟨sSig n (sAddN n x y), by
    have := x.2; have := y.2; simp only [sSig, sAddN]; split_ifs <;> omega⟩

def sDv (n : ℕ) (a b : Fin (2 * n)) : Fin (2 * n) :=
  ⟨sSub n (sRho n b) a, by
    have := a.2; have := b.2; simp only [sSub, sRho]; split_ifs <;> omega⟩

theorem sOp_comm (n : ℕ) (x y : Fin (2 * n)) : sOp n x y = sOp n y x := by
  simp only [sOp, sAddN, Nat.add_comm (x : ℕ)]
#print axioms sOp_comm

theorem sOp_dv (n : ℕ) (a b : Fin (2 * n)) : sOp n a (sDv n a b) = b := by
  apply Fin.ext
  have := a.2; have := b.2
  simp only [sOp, sDv, sSig, sAddN, sSub, sRho]
  split_ifs <;> omega
#print axioms sOp_dv

theorem sDv_op (n : ℕ) (a y : Fin (2 * n)) : sDv n a (sOp n a y) = y := by
  apply Fin.ext
  have := a.2; have := y.2
  simp only [sOp, sDv, sSig, sAddN, sSub, sRho]
  split_ifs <;> omega
#print axioms sDv_op

theorem sOp_self (n : ℕ) (x : Fin (2 * n)) :
    (sOp n x x : ℕ) = if (x : ℕ) < n then (x : ℕ) else x - n := by
  have := x.2
  simp only [sOp, sSig, sAddN]
  split_ifs <;> omega
#print axioms sOp_self

theorem sOp_inj (n : ℕ) {x y z : Fin (2 * n)} (h : sOp n x y = sOp n x z) : y = z := by
  rw [← sDv_op n x y, h, sDv_op]
#print axioms sOp_inj

def sInfty (n : ℕ) (y : Fin (2 * n)) (j : ZMod 3) : Option (Fin (2 * n) × ZMod 3) :=
  if h : (y : ℕ) < n then some (⟨y + n, by omega⟩, j - 1) else some (⟨y - n, by omega⟩, j + 1)

def sUp (n : ℕ) (x : Fin (2 * n)) (i : ZMod 3) (y : Fin (2 * n)) : Option (Fin (2 * n) × ZMod 3) :=
  if sOp n x x = y then (if (x : ℕ) < n then some (x, i + 2) else none) else some (sDv n x y, i)

def sThird (n : ℕ) : Option (Fin (2 * n) × ZMod 3) → Option (Fin (2 * n) × ZMod 3) →
    Option (Fin (2 * n) × ZMod 3)
  | none, none => none
  | none, some (y, j) => sInfty n y j
  | some (x, i), none => sInfty n x i
  | some (x, i), some (y, j) =>
    if i = j then some (sOp n x y, i + 1) else if j = i + 1 then sUp n x i y else sUp n y j x

theorem sThird_comm (n : ℕ) (p q : Option (Fin (2 * n) × ZMod 3)) :
    sThird n p q = sThird n q p := by
  rcases p with _ | ⟨x, i⟩ <;> rcases q with _ | ⟨y, j⟩
  · rfl
  · rfl
  · rfl
  · simp only [sThird]
    by_cases e2 : i = j
    · subst e2; simp only [ite_true, sOp_comm]
    · rw [if_neg e2, if_neg (Ne.symm e2)]
      by_cases e3 : j = i + 1
      · subst e3; rw [if_pos rfl, if_neg (z3_d i)]
      · rw [if_neg e3, if_pos (z3_c i j e2 e3)]
#print axioms sThird_comm

theorem sThird_ne (n : ℕ) (p q : Option (Fin (2 * n) × ZMod 3)) (hne : p ≠ q) :
    sThird n p q ≠ p := by
  rcases p with _ | ⟨x, i⟩ <;> rcases q with _ | ⟨y, j⟩
  · exact absurd rfl hne
  · simp only [sThird, sInfty]; split_ifs <;> simp
  · simp only [sThird, sInfty]; split_ifs
    · simp
    · simp [(z3_b i)]
  · simp only [sThird]
    by_cases e2 : i = j
    · subst e2; simp
    · rw [if_neg e2]
      by_cases e3 : j = i + 1
      · rw [if_pos e3]; simp only [sUp]
        split_ifs with h1 h2
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro _; exact z3_f i
        · simp
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro h; apply absurd _ h1; conv_rhs => rw [← sOp_dv n x y]
          rw [h]
      · rw [if_neg e3]; simp only [sUp]
        have hi := z3_c i j e2 e3
        split_ifs with h1 h2
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro _; rw [hi]; exact z3_k j
        · simp
        · simp only [ne_eq, Option.some.injEq, Prod.mk.injEq, not_and]
          intro _; exact Ne.symm e2
#print axioms sThird_ne

theorem sInfty_inv (n : ℕ) (y : Fin (2 * n)) (j : ZMod 3) :
    sThird n none (sInfty n y j) = some (y, j) := by
  unfold sInfty
  by_cases hy : (y : ℕ) < n
  · rw [dif_pos hy]; simp only [sThird, sInfty]
    rw [dif_neg (by simp)]
    simp only [Option.some.injEq, Prod.mk.injEq]
    exact ⟨Fin.ext (by simp), by ring⟩
  · rw [dif_neg hy]; simp only [sThird, sInfty]
    rw [dif_pos (by show (y : ℕ) - n < n; omega)]
    simp only [Option.some.injEq, Prod.mk.injEq]
    exact ⟨Fin.ext (by show (y : ℕ) - n + n = y; omega), by ring⟩
#print axioms sInfty_inv

theorem sThird_ss (n : ℕ) (x : Fin (2 * n)) (i : ZMod 3) (y : Fin (2 * n)) (j : ZMod 3) :
    sThird n (some (x, i)) (some (y, j)) =
      if i = j then some (sOp n x y, i + 1) else if j = i + 1 then sUp n x i y else sUp n y j x :=
  rfl
#print axioms sThird_ss

theorem sThird_sn (n : ℕ) (x : Fin (2 * n)) (i : ZMod 3) :
    sThird n (some (x, i)) none = sInfty n x i := rfl
#print axioms sThird_sn

theorem sThird_inv (n : ℕ) (p q : Option (Fin (2 * n) × ZMod 3)) (hne : p ≠ q) :
    sThird n p (sThird n p q) = q := by
  rcases p with _ | ⟨x, i⟩ <;> rcases q with _ | ⟨y, j⟩
  · exact absurd rfl hne
  · exact sInfty_inv n y j
  · -- p = (x, i), q = ∞
    rw [sThird_sn]; unfold sInfty
    by_cases hx : (x : ℕ) < n
    · rw [dif_pos hx, sThird_ss, if_neg (z3_g i).symm, if_neg (z3_h i)]
      unfold sUp
      rw [if_pos (Fin.ext (by rw [sOp_self]; simp <;> omega)), if_neg (by simp)]
    · rw [dif_neg hx, sThird_ss, if_neg (z3_b i).symm, if_pos rfl]
      unfold sUp
      rw [if_pos (Fin.ext (by rw [sOp_self]; simp <;> omega)), if_neg hx]
  · rw [sThird_ss]
    by_cases e2 : i = j
    · subst e2
      have hxy : x ≠ y := fun e => hne (by rw [e])
      rw [if_pos rfl, sThird_ss, if_neg (z3_b i).symm, if_pos rfl]
      unfold sUp
      rw [if_neg (fun e => hxy (sOp_inj n e)), sDv_op]
    · rw [if_neg e2]
      by_cases e3 : j = i + 1
      · subst e3
        rw [if_pos rfl]
        unfold sUp
        by_cases h1 : sOp n x x = y
        · rw [if_pos h1]
          by_cases hx : (x : ℕ) < n
          · have hy : y = x := by
              rw [← h1]; exact Fin.ext (by rw [sOp_self, if_pos hx])
            subst hy
            rw [if_pos hx, sThird_ss, if_neg (z3_f i).symm, if_neg (z3_k i)]
            unfold sUp
            rw [if_pos h1, if_pos hx, z3_i]
          · rw [if_neg hx, sThird_sn]
            unfold sInfty
            rw [dif_neg hx]
            simp only [Option.some.injEq, Prod.mk.injEq, and_true]
            rw [← h1]; exact Fin.ext (by rw [sOp_self, if_neg hx])
        · rw [if_neg h1]
          rw [sThird_ss, if_pos rfl, sOp_dv]
      · have hi := z3_c i j e2 e3
        rw [if_neg e3]
        unfold sUp
        by_cases h1 : sOp n y y = x
        · rw [if_pos h1]
          by_cases hy : (y : ℕ) < n
          · have hx : x = y := by
              rw [← h1]; exact Fin.ext (by rw [sOp_self, if_pos hy])
            subst hx
            rw [if_pos hy, sThird_ss, if_neg (by rw [hi]; exact (z3_k j).symm),
              if_pos (by rw [hi]; ring)]
            unfold sUp
            rw [if_pos h1, if_pos hy, hi, z3_j]
          · rw [if_neg hy, sThird_sn]
            unfold sInfty
            have hx : (x : ℕ) < n := by rw [← h1, sOp_self, if_neg hy]; omega
            rw [dif_pos hx]
            simp only [Option.some.injEq, Prod.mk.injEq]
            refine ⟨Fin.ext ?_, by rw [hi]; ring⟩
            simp only [← h1, sOp_self, if_neg hy]; omega
        · rw [if_neg h1]
          have hw : sDv n y x ≠ y := fun e => h1 (by conv_rhs => rw [← sOp_dv n y x]; rw [e])
          rw [sThird_ss, if_neg e2, if_neg e3]
          unfold sUp
          have h2 : sOp n (sDv n y x) (sDv n y x) ≠ x := by
            intro e
            apply hw
            apply sOp_inj n (x := sDv n y x)
            rw [e, sOp_comm, sOp_dv]
          rw [if_neg h2]
          have : sDv n (sDv n y x) x = y := by
            apply sOp_inj n (x := sDv n y x)
            rw [sOp_dv, sOp_comm, sOp_dv]
          rw [this]
#print axioms sThird_inv

theorem skolem_exists (n : ℕ) : ∃ B : Finset (Finset (Option (Fin (2 * n) × ZMod 3))),
    IsSteinerTripleSystem univ B :=
  ⟨_, sts_of_third (sThird n) (sThird_ne n) (sThird_comm n) (sThird_inv n)
    (((univ ×ˢ univ).filter fun pq : Option (Fin (2 * n) × ZMod 3) × Option (Fin (2 * n) × ZMod 3) =>
      pq.1 ≠ pq.2).image fun pq => {pq.1, pq.2, sThird n pq.1 pq.2})
    (fun t ht => by
      obtain ⟨⟨p, q⟩, hpq, rfl⟩ := Finset.mem_image.mp ht
      exact ⟨p, q, (Finset.mem_filter.mp hpq).2, rfl⟩)
    (fun p q hpq => Finset.mem_image.mpr ⟨(p, q), by simp [hpq], rfl⟩)⟩
#print axioms skolem_exists

/-- Main claim: a Steiner triple system on v points (v at least 1) exists exactly when
v leaves remainder 1 or 3 on division by 6. -/
theorem steiner_triple_system_exists_iff (v : ℕ) (hv : 0 < v) :
    (∃ B : Finset (Finset ℕ), IsSteinerTripleSystem (range v) B) ↔ v % 6 = 1 ∨ v % 6 = 3 := by
  constructor
  · rintro ⟨B, h⟩
    exact sts_necessity v hv B h
  · rintro (h | h)
    · obtain ⟨n, rfl⟩ : ∃ n, v = 6 * n + 1 := ⟨v / 6, by omega⟩
      obtain ⟨B, hB⟩ := skolem_exists n
      have e : Fintype.card (Option (Fin (2 * n) × ZMod 3)) = 6 * n + 1 := by
        simp [ZMod.card]; ring
      have := sts_range_of_fintype hB
      rwa [e] at this
    · obtain ⟨n, rfl⟩ : ∃ n, v = 6 * n + 3 := ⟨v / 6, by omega⟩
      obtain ⟨B, hB⟩ := bose_exists n
      have e : Fintype.card (ZMod (2 * n + 1) × ZMod 3) = 6 * n + 3 := by
        simp [ZMod.card]; ring
      have := sts_range_of_fintype hB
      rwa [e] at this

/-- The counts: in a Steiner triple system on v points, each point lies on r = (v - 1)/2 triples
and there are b = v(v - 1)/6 triples in all. -/
theorem steiner_triple_system_counts {α : Type*} [DecidableEq α] (V : Finset α)
    (B : Finset (Finset α)) (h : IsSteinerTripleSystem V B) :
    B.card * 6 = V.card * (V.card - 1) ∧
      ∀ x ∈ V, (B.filter fun t => x ∈ t).card * 2 = V.card - 1 := by
  exact sts_counts_aux V B h

/-- Bose's triples for v = 6n + 3 on the points (x, i), x counted round a clock of 2n + 1 and
i round a clock of 3: the uprights {(x,0), (x,1), (x,2)} and, for x ≠ y on layer i,
{(x,i), (y,i), ((n+1)(x+y), i+1)}. -/
def boseBlocks (n : ℕ) : Finset (Finset (ZMod (2 * n + 1) × ZMod 3)) :=
  (univ.image fun x : ZMod (2 * n + 1) => ({(x, 0), (x, 1), (x, 2)} : Finset _)) ∪
    ((univ ×ˢ univ ×ˢ univ).filter
        (fun p : ZMod 3 × ZMod (2 * n + 1) × ZMod (2 * n + 1) => p.2.1 ≠ p.2.2)).image
      fun p => ({(p.2.1, p.1), (p.2.2, p.1), (((n : ZMod (2 * n + 1)) + 1) * (p.2.1 + p.2.2), p.1 + 1)} :
        Finset _)

/-- Bose's construction: for every n, the uprights and rule triples form a Steiner triple system
on the 6n + 3 points (x, i). -/
theorem bose_construction_is_steiner_triple_system (n : ℕ) :
    IsSteinerTripleSystem (univ : Finset (ZMod (2 * n + 1) × ZMod 3)) (boseBlocks n) := by
  have h2 := bose_two_half n
  have hc2 := @bose_cancel_two n
  apply sts_of_third (boseThird n) (boseThird_ne n) (boseThird_comm n) (boseThird_inv n)
  · rintro t ht
    rcases Finset.mem_union.mp ht with ht | ht
    · obtain ⟨x, -, rfl⟩ := Finset.mem_image.mp ht
      refine ⟨(x, 0), (x, 1), by simp, ?_⟩
      simp only [boseThird, ite_true]
      rfl
    · obtain ⟨⟨i, a, b⟩, hp, rfl⟩ := Finset.mem_image.mp ht
      simp only [Finset.mem_filter] at hp
      refine ⟨(a, i), (b, i), by simp [hp.2], ?_⟩
      simp only [boseThird, if_neg hp.2, ite_true]
  · rintro ⟨x, i⟩ ⟨y, j⟩ hne
    by_cases e1 : x = y
    · subst e1
      have hij : i ≠ j := fun e => hne (by rw [e])
      simp only [boseThird, ite_true]
      apply Finset.mem_union_left
      refine Finset.mem_image.mpr ⟨x, Finset.mem_univ _, ?_⟩
      have := z3_e i j hij
      have key : ∀ s : Finset (ZMod 3), s.image (Prod.mk x) = s.image (Prod.mk x) := fun _ => rfl
      calc ({(x, 0), (x, 1), (x, 2)} : Finset _) = ({0, 1, 2} : Finset (ZMod 3)).image (Prod.mk x) := by
            simp [Finset.image_insert]
        _ = ({i, j, -i - j} : Finset (ZMod 3)).image (Prod.mk x) := by rw [this]
        _ = _ := by simp [Finset.image_insert]
    · apply Finset.mem_union_right
      rw [Finset.mem_image]
      by_cases e2 : i = j
      · subst e2
        refine ⟨(i, x, y), by simp [e1], ?_⟩
        simp only [boseThird, if_neg e1, ite_true]
      · by_cases e3 : j = i + 1
        · subst e3
          refine ⟨(i, x, 2 * y - x), by simp; intro e; apply e1; apply hc2; linear_combination e, ?_⟩
          have : ((n : ZMod (2 * n + 1)) + 1) * (x + (2 * y - x)) = y := by linear_combination y * h2
          simp only [boseThird, if_neg e1, if_neg e2, ite_true, this]
          ext z; simp only [Finset.mem_insert, Finset.mem_singleton]; tauto
        · have hi := z3_c i j e2 e3
          refine ⟨(j, y, 2 * x - y), by simp; intro e; apply e1; apply hc2; linear_combination -e, ?_⟩
          have : ((n : ZMod (2 * n + 1)) + 1) * (y + (2 * x - y)) = x := by linear_combination x * h2
          simp only [boseThird, if_neg e1, if_neg e2, if_neg e3, this, ← hi]
          ext z; simp only [Finset.mem_insert, Finset.mem_singleton]; tauto

-- v = 9: the 12 wrapped lines of the 3 by 3 grid cover every pair once.
example : IsSteinerTripleSystem (Icc 1 9)
    {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {1, 4, 7}, {2, 5, 8}, {3, 6, 9},
     {1, 5, 9}, {2, 6, 7}, {3, 4, 8}, {1, 6, 8}, {2, 4, 9}, {3, 5, 7}} := by decide

-- The Fano plane: 7 points and 7 lines, every pair on exactly one line.
example : IsSteinerTripleSystem (Icc 1 7)
    {{1, 2, 4}, {2, 3, 5}, {3, 4, 6}, {4, 5, 7}, {5, 6, 1}, {6, 7, 2}, {7, 1, 3}} := by decide

-- Kirkman's schoolgirls (A0-A6 = 0-6, B0-B6 = 7-13, Z = 14): the 7 days of 5 rows give 35 rows
-- covering every pair once, and each day every girl walks in exactly one row.
example :
    let days : List (Finset (Finset ℕ)) := [
      {{14, 0, 7}, {1, 2, 4}, {3, 8, 12}, {5, 11, 13}, {6, 9, 10}},
      {{14, 1, 8}, {2, 3, 5}, {4, 9, 13}, {6, 12, 7}, {0, 10, 11}},
      {{14, 2, 9}, {3, 4, 6}, {5, 10, 7}, {0, 13, 8}, {1, 11, 12}},
      {{14, 3, 10}, {4, 5, 0}, {6, 11, 8}, {1, 7, 9}, {2, 12, 13}},
      {{14, 4, 11}, {5, 6, 1}, {0, 12, 9}, {2, 8, 10}, {3, 13, 7}},
      {{14, 5, 12}, {6, 0, 2}, {1, 13, 10}, {3, 9, 11}, {4, 7, 8}},
      {{14, 6, 13}, {0, 1, 3}, {2, 7, 11}, {4, 10, 12}, {5, 8, 9}}]
    IsSteinerTripleSystem (range 15) (days.foldr (· ∪ ·) ∅) ∧
      (days.foldr (· ∪ ·) ∅).card = 35 ∧
      ∀ d ∈ days, d.card = 5 ∧ ∀ g ∈ range 15, (d.filter fun t => g ∈ t).card = 1 := by
  decide

-- Worked numbers: v = 9 gives 36 pairs, b = 12, r = 4; v = 15 gives 105 pairs, b = 35, 7 days;
-- v = 11 is odd but 6 does not divide 110.
example : 9 * 8 / 2 = 36 ∧ 9 * 8 / 6 = 12 ∧ 8 / 2 = 4 := by norm_num
example : 15 * 14 / 2 = 105 ∧ 105 / 3 = 35 ∧ 35 / 5 = 7 ∧ 14 / 2 = 7 := by norm_num
example : 11 % 2 = 1 ∧ 110 % 6 ≠ 0 := by norm_num
-- Between 3 and 15, the sizes with r and b whole are exactly those with remainder 1 or 3.
example : (Icc 3 15).filter (fun v => (v - 1) % 2 = 0 ∧ v * (v - 1) % 6 = 0) = {3, 7, 9, 13, 15} ∧
    (Icc 3 15).filter (fun v => v % 6 = 1 ∨ v % 6 = 3) = {3, 7, 9, 13, 15} := by decide

#print axioms steiner_triple_system_exists_iff
#print axioms steiner_triple_system_counts
#print axioms bose_construction_is_steiner_triple_system
