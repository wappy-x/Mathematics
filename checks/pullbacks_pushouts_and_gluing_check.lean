-- Pullbacks and pushouts: the join of two maps is their pullback of sets, its size is the key-by-key sum of fibre products, and gluing along one-to-one matches has |A| + |B| - |S| members.
import Mathlib.CategoryTheory.Limits.Types.Pushouts
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Pi
import Mathlib.SetTheory.Cardinal.Finite

open CategoryTheory CategoryTheory.Limits

universe u

/-- The join is the pullback of sets: for maps `f : A → C` and `g : B → C`, the set of
matching pairs `{(a, b) : f a = g b}`, with its two projections, is a pullback square
over `f` and `g`. Any set `T` with maps into `A` and `B` that agree in `C` maps into the
join in exactly one way. -/
theorem join_is_pullback {A B C : Type u} (f : A → C) (g : B → C) :
    IsPullback (↾(fun x : {x : A × B // f x.1 = g x.2} => x.1.1))
      (↾(fun x : {x : A × B // f x.1 = g x.2} => x.1.2)) (↾f) (↾g) := by
  rw [Types.isPullback_iff]
  refine ⟨?_, ?_, ?_⟩
  · ext x
    exact x.2
  · rintro x y ⟨h1, h2⟩
    exact Subtype.ext (Prod.ext h1 h2)
  · intro a b h
    exact ⟨⟨⟨a, b⟩, h⟩, rfl, rfl⟩

/-- Counting the join key by key: for finite sets, the number of matching pairs is the
sum over keys `c` of (the number of `A`-members with key `c`) times (the number of
`B`-members with key `c`). -/
theorem join_card_eq_sum_fibres {A B C : Type*} [Fintype A] [Fintype B] [Fintype C]
    [DecidableEq C] (f : A → C) (g : B → C) :
    Fintype.card {x : A × B // f x.1 = g x.2} =
      ∑ c : C, (Finset.univ.filter (fun a => f a = c)).card *
        (Finset.univ.filter (fun b => g b = c)).card := by
  let e : {x : A × B // f x.1 = g x.2} ≃ Σ c : C, {a // f a = c} × {b // g b = c} :=
    { toFun := fun x => ⟨f x.1.1, ⟨x.1.1, rfl⟩, ⟨x.1.2, x.2.symm⟩⟩
      invFun := fun y => ⟨(y.2.1.1, y.2.2.1), y.2.1.2.trans y.2.2.2.symm⟩
      left_inv := fun x => rfl
      right_inv := by
        rintro ⟨c, ⟨a, rfl⟩, ⟨b, hb⟩⟩
        rfl }
  rw [Fintype.card_congr e, Fintype.card_sigma]
  refine Finset.sum_congr rfl fun c _ => ?_
  rw [Fintype.card_prod, Fintype.card_subtype, Fintype.card_subtype]

/-- Counting the pushout: gluing finite sets `A` and `B` along `S` (side by side, then
fusing `i s` with `j s` for every match `s`, closed up to an equivalence relation) gives
`|A| + |B| - |S|` members when both match maps `i` and `j` are one-to-one. -/
theorem glued_card_of_injective {S A B : Type u} [Fintype S] [Fintype A] [Fintype B]
    (i : S → A) (j : S → B) (hi : Function.Injective i) (hj : Function.Injective j) :
    Nat.card (Types.Pushout (↾i) (↾j)) = Fintype.card A + Fintype.card B - Fintype.card S := by
  classical
  have : Mono (↾i : S ⟶ A) := (mono_iff_injective _).2 hi
  let φ : A ⊕ {b : B // b ∉ Set.range j} → Types.Pushout (↾i) (↾j) := fun x =>
    match x with
    | Sum.inl a => Quot.mk _ (Sum.inl a)
    | Sum.inr b => Quot.mk _ (Sum.inr b.1)
  have hφ : Function.Bijective φ := by
    constructor
    · rintro (a | ⟨b, hb⟩) (a' | ⟨b', hb'⟩) h
      · have := (Types.Pushout.quot_mk_eq_iff (↾i) (↾j) _ _).1 h
        rw [Types.Pushout.inl_rel'_inl_iff] at this
        obtain rfl | ⟨x, y, hxy, rfl, rfl⟩ := this
        · rfl
        · obtain rfl := hj hxy
          rfl
      · have := (Types.Pushout.quot_mk_eq_iff (↾i) (↾j) _ _).1 h
        rw [Types.Pushout.inl_rel'_inr_iff] at this
        obtain ⟨s, -, rfl⟩ := this
        exact absurd ⟨s, rfl⟩ hb'
      · have := (Types.Pushout.quot_mk_eq_iff (↾i) (↾j) _ _).1 h.symm
        rw [Types.Pushout.inl_rel'_inr_iff] at this
        obtain ⟨s, -, rfl⟩ := this
        exact absurd ⟨s, rfl⟩ hb
      · have := (Types.Pushout.quot_mk_eq_iff (↾i) (↾j) _ _).1 h
        rw [Types.Pushout.inr_rel'_inr_iff] at this
        subst this
        rfl
    · rintro ⟨a | b⟩
      · exact ⟨Sum.inl a, rfl⟩
      · by_cases hb : b ∈ Set.range j
        · obtain ⟨s, rfl⟩ := hb
          exact ⟨Sum.inl (i s), Quot.sound (Types.Pushout.Rel.inl_inr s)⟩
        · exact ⟨Sum.inr ⟨b, hb⟩, rfl⟩
  rw [← Nat.card_eq_of_bijective φ hφ, Nat.card_eq_fintype_card, Fintype.card_sum,
    Fintype.card_subtype_compl, Set.card_range_of_injective hj]
  have := Fintype.card_le_of_injective j hj
  omega

/-! Worked examples from the card. Customers: Ana = 0, Ben = 1, Cai = 2, Dev = 3.
Orders 1001 to 1006 are `Fin 6`; addresses Leeds, York, Hull, Bath are `Fin 4`. -/

/-- The customer of each order 1001 to 1006: Ana, Ben, Ana, Dev, Ben, Ana. -/
def orderCustomer : Fin 6 → Fin 4 := ![0, 1, 0, 3, 1, 0]

/-- The customer at each address Leeds, York, Hull, Bath: Ana, Ana, Ben, Cai. -/
def addressCustomer : Fin 4 → Fin 4 := ![0, 0, 1, 2]

-- the join has 8 matching rows out of 6 × 4 = 24 pairs
example : Fintype.card {x : Fin 6 × Fin 4 // orderCustomer x.1 = addressCustomer x.2} = 8 := by
  decide

-- key by key: 3 × 2 + 2 × 1 + 0 × 1 + 1 × 0 = 8
example : (∑ c : Fin 4, (Finset.univ.filter (fun a => orderCustomer a = c)).card *
    (Finset.univ.filter (fun b => addressCustomer b = c)).card) = 8 := by
  decide

-- a 2-row test table: 64 of the 576 pairs of maps match, which is 8 × 8
example : Fintype.card {pq : (Fin 2 → Fin 6) × (Fin 2 → Fin 4) //
    ∀ t, orderCustomer (pq.1 t) = addressCustomer (pq.2 t)} = 64 := by
  decide

-- key set of one point: the pullback is the plain product, 24 rows
example : Fintype.card {x : Fin 6 × Fin 4 // (fun _ => ()) x.1 = (fun _ => ()) x.2} = 24 := by
  decide

-- loyalty-card holders Ana and Ben, a subset of the keys: the 5 orders by card holders
example : Fintype.card {x : Fin 6 × Fin 2 //
    orderCustomer x.1 = (fun k : Fin 2 => (k.castSucc.castSucc : Fin 4)) x.2} = 5 := by
  decide

-- groups: the 4-hour and 6-hour clocks over parity have 12 matching pairs
example : Fintype.card {x : ZMod 4 × ZMod 6 // x.1.val % 2 = x.2.val % 2} = 12 := by
  decide

-- groups: the matching pairs are closed under adding and under undo
example : ∀ x y : ZMod 4 × ZMod 6, x.1.val % 2 = x.2.val % 2 → y.1.val % 2 = y.2.val % 2 →
    (x + y).1.val % 2 = (x + y).2.val % 2 := by
  decide

example : ∀ x : ZMod 4 × ZMod 6, x.1.val % 2 = x.2.val % 2 → (-x).1.val % 2 = (-x).2.val % 2 := by
  decide

#print axioms join_is_pullback
#print axioms join_card_eq_sum_fibres
#print axioms glued_card_of_injective
