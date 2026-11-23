-- Commutative diagrams: exactly one function completes the product diagram and exactly one completes its reversed sum diagram, reversing arrows swaps monos and epis, and the arrow counts multiply.
import Mathlib.CategoryTheory.EpiMono
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Sum
import Mathlib.Data.Fintype.Card
import Mathlib.Algebra.BigOperators.Fin

open CategoryTheory

/-- The product diagram and its reverse, the sum diagram, each commute for exactly one
completing function. For sets `X`, `A`, `B`, `Y` and functions `f : X → A`, `g : X → B`,
`p : A → Y`, `q : B → Y`: a function `h : X → A × B` satisfies `fst ∘ h = f` and
`snd ∘ h = g` exactly when `h` is the pairing `⟨f, g⟩ = fun x ↦ (f x, g x)`; and, with every
arrow reversed, a function `k : A + B → Y` from the tagged sum satisfies `k ∘ inl = p` and
`k ∘ inr = q` exactly when `k` is the case split `[p, q]`. -/
theorem product_and_sum_diagrams_complete_uniquely {X A B Y : Type*}
    (f : X → A) (g : X → B) (p : A → Y) (q : B → Y) :
    (∀ h : X → A × B, (Prod.fst ∘ h = f ∧ Prod.snd ∘ h = g) ↔ h = fun x => (f x, g x)) ∧
    (∀ k : A ⊕ B → Y, (k ∘ Sum.inl = p ∧ k ∘ Sum.inr = q) ↔ k = Sum.elim p q) := by
  constructor
  · intro h
    constructor
    · rintro ⟨h1, h2⟩
      funext x
      exact Prod.ext (congrFun h1 x) (congrFun h2 x)
    · rintro rfl
      exact ⟨rfl, rfl⟩
  · intro k
    constructor
    · rintro ⟨h1, h2⟩
      funext x
      cases x with
      | inl a => exact congrFun h1 a
      | inr b => exact congrFun h2 b
    · rintro rfl
      exact ⟨rfl, rfl⟩

/-- Duality for monos and epis: in any category, an arrow `f` can be cancelled on the left
(a mono) exactly when the same arrow reversed in the opposite category `𝒞ᵒᵖ` can be
cancelled on the right (an epi), and `f` is an epi exactly when its reverse is a mono. -/
theorem mono_epi_swap_in_opposite_category {C : Type*} [Category C] {S T : C} (f : S ⟶ T) :
    (Mono f ↔ Epi f.op) ∧ (Epi f ↔ Mono f.op) := by
  exact ⟨(op_epi_iff f).symm, (op_mono_iff f).symm⟩

/-- The counts multiply: for finite sets, the arrows `X → A × B` number
`|Hom(X, A)| · |Hom(X, B)|`, and the arrows `A + B → Y` number `|Hom(A, Y)| · |Hom(B, Y)|`. -/
theorem hom_counts_product_and_sum {X A B Y : Type*} [Fintype X] [DecidableEq X]
    [Fintype A] [DecidableEq A] [Fintype B] [DecidableEq B] [Fintype Y] [DecidableEq Y] :
    Fintype.card (X → A × B) = Fintype.card (X → A) * Fintype.card (X → B) ∧
    Fintype.card (A ⊕ B → Y) = Fintype.card (A → Y) * Fintype.card (B → Y) := by
  constructor
  · rw [Fintype.card_fun, Fintype.card_fun, Fintype.card_fun, Fintype.card_prod, mul_pow]
  · rw [Fintype.card_fun, Fintype.card_fun, Fintype.card_fun, Fintype.card_sum, pow_add]

-- The café: 2 drinks and 3 pastries give 6 meal deals and 5 voucher items.
example : Fintype.card (Fin 2 × Fin 3) = 6 ∧ Fintype.card (Fin 2 ⊕ Fin 3) = 5 := by decide

-- 216 = 8 × 27 functions from 3 tables into the meal deals; 3,125 = 25 × 125 into 5 prices.
example : Fintype.card (Fin 3 → Fin 2 × Fin 3) = 216 ∧ 216 = 2 ^ 3 * 3 ^ 3 := by
  simp
example : Fintype.card (Fin 2 ⊕ Fin 3 → Fin 5) = 3125 ∧ 3125 = 5 ^ 2 * 5 ^ 3 := by
  simp

-- Of the 216 functions from tables into meal deals, exactly 1 passes both equations
-- for f = (tea, coffee, tea) and g = (scone, toast, muffin).
example : (Finset.univ.filter (fun h : Fin 3 → Fin 2 × Fin 3 =>
    Prod.fst ∘ h = ![0, 1, 0] ∧ Prod.snd ∘ h = ![0, 2, 1])).card = 1 := by decide +kernel

-- The clock square: x mod 3 commutes on 144 of 144 pairs of hours, x mod 5 on 78.
example : (Finset.univ.filter (fun ab : Fin 12 × Fin 12 =>
    (ab.1.val + ab.2.val) % 12 % 3 = (ab.1.val % 3 + ab.2.val % 3) % 3)).card = 144 := by decide +kernel
example : (Finset.univ.filter (fun ab : Fin 12 × Fin 12 =>
    (ab.1.val + ab.2.val) % 12 % 5 = (ab.1.val % 5 + ab.2.val % 5) % 5)).card = 78 := by decide +kernel

-- The sets of size 0, 1, 2 and all functions between them: 11 arrows, 8 one-to-one, 5 onto.
example : (∑ n : Fin 3, ∑ m : Fin 3, Fintype.card (Fin n → Fin m)) = 11 := by decide
example : (∑ n : Fin 3, ∑ m : Fin 3,
    (Finset.univ.filter (fun h : Fin n → Fin m => Function.Injective h)).card) = 8 := by decide
example : (∑ n : Fin 3, ∑ m : Fin 3,
    (Finset.univ.filter (fun h : Fin n → Fin m => Function.Surjective h)).card) = 5 := by decide

-- Here and takeaway prices: the plain union has 2 items and 16 price lists into 4 prices;
-- the tagged sum has 4 items and 256.
example : Fintype.card (Fin 2 → Fin 4) = 16 ∧ Fintype.card (Fin 2 ⊕ Fin 2 → Fin 4) = 256 := by
  simp

#print axioms product_and_sum_diagrams_complete_uniquely
#print axioms mono_epi_swap_in_opposite_category
#print axioms hom_counts_product_and_sum
