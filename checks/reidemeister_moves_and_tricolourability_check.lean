-- Reidemeister moves and the three-colour test: each Reidemeister move leaves the number of three-colourings of a knot diagram unchanged, and the trefoil has 9 colourings against the unknot's 3.
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.FieldTheory.Finiteness
import Mathlib.Algebra.Field.ZMod

/-!
A diagram is stored as on the card's code: a number of arcs `n` and a list of crossings
`(over arc, under arc, under arc)`. Colours are `ZMod p`: red 0, yellow 1, blue 2 when `p = 3`.
Mathlib has no knot diagrams, so this combinatorial model is set up here.
-/

namespace Tricolour

/-- The crossing rule: at every crossing, twice the over colour minus the two under colours is 0. -/
def Legal {p : ℕ} {ι : Type*} (cr : List (ι × ι × ι)) (c : ι → ZMod p) : Prop :=
  ∀ x ∈ cr, 2 * c x.1 - c x.2.1 - c x.2.2 = 0

instance {p : ℕ} {ι : Type*} (cr : List (ι × ι × ι)) (c : ι → ZMod p) :
    Decidable (Legal cr c) := by
  unfold Legal; infer_instance

/-- `T p n cr`: the number of colourings, with `p` colours, of the diagram with `n` arcs and
crossing list `cr`. The card's `T(D)` is `T 3 n cr`. -/
def T (p : ℕ) [NeZero p] (n : ℕ) (cr : List (Fin n × Fin n × Fin n)) : ℕ :=
  (Finset.univ.filter (fun c : Fin n → ZMod p => Legal cr c)).card

/-- A tangle: the part of a diagram inside a small disc where a move happens. It has its own
arcs and crossings, and `j` ends on the edge of the disc; `ends i` is the inside arc at end `i`. -/
structure Tangle (j : ℕ) where
  arcs : ℕ
  crossings : List (Fin arcs × Fin arcs × Fin arcs)
  ends : Fin j → Fin arcs

/-- The number of three-colourings of the whole diagram made by gluing an outside part
(arcs `α`, crossings `out`, end `i` lying on outside arc `g i`) to the tangle `t`: a colouring
of the outside and one of the inside that agree at every end. -/
def glued {α : Type*} [Fintype α] [DecidableEq α] {j : ℕ}
    (out : List (α × α × α)) (g : Fin j → α) (t : Tangle j) : ℕ :=
  (Finset.univ.filter (fun q : (α → ZMod 3) × (Fin t.arcs → ZMod 3) =>
    Legal out q.1 ∧ Legal t.crossings q.2 ∧ ∀ i, q.1 (g i) = q.2 (t.ends i))).card

/-- R1 before: one plain strand, both ends on the same arc. -/
def r1Before : Tangle 2 := ⟨1, [], ![0, 0]⟩
/-- R1 after, kink passing over first: arc `p` lies over itself and over `q`. -/
def r1OverFirst : Tangle 2 := ⟨2, [(0, 0, 1)], ![0, 1]⟩
/-- R1 after, kink passing under first: arc `q` lies over `p` and over itself. -/
def r1UnderFirst : Tangle 2 := ⟨2, [(1, 0, 1)], ![0, 1]⟩
/-- R2 before: two separate strands `a` and `b`. -/
def r2Before : Tangle 4 := ⟨2, [], ![0, 0, 1, 1]⟩
/-- R2 after: `a` lies over `b` twice, cutting it into `b₁`, `m`, `b₂`. -/
def r2After : Tangle 4 := ⟨4, [(0, 1, 2), (0, 2, 3)], ![0, 0, 1, 3]⟩
/-- R3 before: arcs top `t`; middle in, middle out; under in, under middle, under out.
The under strand passes under the middle strand first, then under the top. -/
def r3Before : Tangle 6 := ⟨6, [(1, 3, 4), (0, 4, 5), (0, 1, 2)], ![0, 0, 1, 2, 3, 5]⟩
/-- R3 after: the under strand passes under the top first, then under the middle strand. -/
def r3After : Tangle 6 := ⟨6, [(0, 1, 2), (0, 3, 4), (2, 4, 5)], ![0, 0, 1, 2, 3, 5]⟩

theorem legal_nil {p : ℕ} {ι : Type*} (c : ι → ZMod p) : Legal [] c := by
  simp [Legal]

#print axioms legal_nil

theorem legal_cons {p : ℕ} {ι : Type*} (x : ι × ι × ι) (l : List (ι × ι × ι)) (c : ι → ZMod p) :
    Legal (x :: l) c ↔ 2 * c x.1 - c x.2.1 - c x.2.2 = 0 ∧ Legal l c := by
  simp [Legal]

#print axioms legal_cons

theorem glued_eq_of_maps {α : Type*} [Fintype α] [DecidableEq α] {j : ℕ}
    (out : List (α × α × α)) (g : Fin j → α) (t t' : Tangle j)
    (F : (Fin t.arcs → ZMod 3) → (Fin t'.arcs → ZMod 3))
    (G : (Fin t'.arcs → ZMod 3) → (Fin t.arcs → ZMod 3))
    (hF : ∀ (e : Fin j → ZMod 3) c, Legal t.crossings c → (∀ i, e i = c (t.ends i)) →
      Legal t'.crossings (F c) ∧ ∀ i, e i = F c (t'.ends i))
    (hG : ∀ (e : Fin j → ZMod 3) c, Legal t'.crossings c → (∀ i, e i = c (t'.ends i)) →
      Legal t.crossings (G c) ∧ ∀ i, e i = G c (t.ends i))
    (hGF : ∀ c, Legal t.crossings c → G (F c) = c)
    (hFG : ∀ c, Legal t'.crossings c → F (G c) = c) :
    glued out g t = glued out g t' := by
  unfold glued
  refine Finset.card_bij' (fun q _ => (q.1, F q.2)) (fun q _ => (q.1, G q.2)) ?_ ?_ ?_ ?_
  · intro q hq
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hq ⊢
    exact ⟨hq.1, hF (fun i => q.1 (g i)) q.2 hq.2.1 hq.2.2⟩
  · intro q hq
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hq ⊢
    exact ⟨hq.1, hG (fun i => q.1 (g i)) q.2 hq.2.1 hq.2.2⟩
  · intro q hq
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hq
    exact Prod.ext rfl (hGF q.2 hq.2.1)
  · intro q hq
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hq
    exact Prod.ext rfl (hFG q.2 hq.2.1)

#print axioms glued_eq_of_maps

theorem r1_over {α : Type*} [Fintype α] [DecidableEq α] (out : List (α × α × α))
    (g : Fin 2 → α) : glued out g r1Before = glued out g r1OverFirst := by
  refine glued_eq_of_maps out g r1Before r1OverFirst
    (fun (c : Fin 1 → ZMod 3) => ![c 0, c 0]) (fun (c : Fin 2 → ZMod 3) => ![c 0]) ?_ ?_ ?_ ?_
  all_goals dsimp only [r1Before, r1OverFirst] at *
  all_goals simp only [legal_cons, legal_nil, and_true, Fin.forall_fin_two,
    Matrix.cons_val_zero, Matrix.cons_val_one] at *
  · intro e c _ he
    refine ⟨by ring, he⟩
  · intro e c hc he
    refine ⟨trivial, he.1, ?_⟩
    rw [he.2]; grind
  · intro c _
    funext i; fin_cases i; rfl
  · intro c hc
    funext i; fin_cases i
    · rfl
    · simp; grind

#print axioms r1_over

theorem r1_under {α : Type*} [Fintype α] [DecidableEq α] (out : List (α × α × α))
    (g : Fin 2 → α) : glued out g r1Before = glued out g r1UnderFirst := by
  refine glued_eq_of_maps out g r1Before r1UnderFirst
    (fun (c : Fin 1 → ZMod 3) => ![c 0, c 0]) (fun (c : Fin 2 → ZMod 3) => ![c 0]) ?_ ?_ ?_ ?_
  all_goals dsimp only [r1Before, r1UnderFirst] at *
  all_goals simp only [legal_cons, legal_nil, and_true] at *
  · intro e c hc he
    refine ⟨by simp; grind, fun i => ?_⟩
    have h := he i
    fin_cases i <;> simp at h ⊢ <;> grind
  · intro e c hc he
    refine ⟨by simp, fun i => ?_⟩
    have h := he i
    fin_cases i <;> simp at h ⊢ <;> grind
  · intro c hc
    funext i
    fin_cases i; simp
  · intro c hc
    funext i
    fin_cases i <;> simp
    grind

#print axioms r1_under

theorem r2 {α : Type*} [Fintype α] [DecidableEq α] (out : List (α × α × α))
    (g : Fin 4 → α) : glued out g r2Before = glued out g r2After := by
  refine glued_eq_of_maps out g r2Before r2After
    (fun (c : Fin 2 → ZMod 3) => ![c 0, c 1, 2 * c 0 - c 1, c 1])
    (fun (c : Fin 4 → ZMod 3) => ![c 0, c 1]) ?_ ?_ ?_ ?_
  all_goals dsimp only [r2Before, r2After] at *
  all_goals simp only [legal_cons, legal_nil, and_true] at *
  · intro e c hc he
    refine ⟨by simp, fun i => ?_⟩
    have h := he i
    fin_cases i <;> simp at h ⊢ <;> grind
  · intro e c hc he
    refine ⟨by simp, fun i => ?_⟩
    have h := he i
    fin_cases i <;> simp at h ⊢ <;> grind
  · intro c hc
    funext i
    fin_cases i <;> simp
  · intro c hc
    funext i
    fin_cases i <;> simp <;> grind

#print axioms r2

theorem r3 {α : Type*} [Fintype α] [DecidableEq α] (out : List (α × α × α))
    (g : Fin 6 → α) : glued out g r3Before = glued out g r3After := by
  refine glued_eq_of_maps out g r3Before r3After
    (fun (c : Fin 6 → ZMod 3) => ![c 0, c 1, c 2, c 3, 2 * c 0 - c 3, c 5])
    (fun (c : Fin 6 → ZMod 3) => ![c 0, c 1, c 2, c 3, 2 * c 1 - c 3, c 5]) ?_ ?_ ?_ ?_
  all_goals dsimp only [r3Before, r3After] at *
  all_goals simp only [legal_cons, legal_nil, and_true] at *
  · intro e c hc he
    refine ⟨by simp; grind, fun i => ?_⟩
    have h := he i
    fin_cases i <;> simp at h ⊢ <;> grind
  · intro e c hc he
    refine ⟨by simp; grind, fun i => ?_⟩
    have h := he i
    fin_cases i <;> simp at h ⊢ <;> grind
  · intro c hc
    funext i
    fin_cases i <;> simp
    grind
  · intro c hc
    funext i
    fin_cases i <;> simp
    grind

#print axioms r3

/-- The card's theorem: each of the three Reidemeister moves (the kink R1 in both forms, the
poke R2, the slide R3), made inside a small disc of any diagram, leaves the number of
three-colourings of the whole diagram unchanged. -/
theorem reidemeister_moves_preserve_colouring_count
    {α : Type*} [Fintype α] [DecidableEq α] :
    (∀ (out : List (α × α × α)) (g : Fin 2 → α),
        glued out g r1Before = glued out g r1OverFirst) ∧
    (∀ (out : List (α × α × α)) (g : Fin 2 → α),
        glued out g r1Before = glued out g r1UnderFirst) ∧
    (∀ (out : List (α × α × α)) (g : Fin 4 → α),
        glued out g r2Before = glued out g r2After) ∧
    (∀ (out : List (α × α × α)) (g : Fin 6 → α),
        glued out g r3Before = glued out g r3After) := by
  exact ⟨r1_over, r1_under, r2, r3⟩

/-- The rule "twice the over colour minus the two under colours is 0 mod 3" says the same as
"the three colours at the crossing are all the same or all different". -/
theorem crossing_rule_iff_all_same_or_all_different (o a b : ZMod 3) :
    2 * o - a - b = 0 ↔ (o = a ∧ a = b) ∨ (o ≠ a ∧ a ≠ b ∧ o ≠ b) := by
  revert o a b; decide

/-- The crossing matrix: one row per crossing, with 2 at the over arc and −1 at each under arc. -/
def crossingMatrix {n : ℕ} (cr : List (Fin n × Fin n × Fin n)) :
    Matrix (Fin cr.length) (Fin n) (ZMod 3) :=
  Matrix.of fun i => 2 • (Pi.single cr[i].1 1 : Fin n → ZMod 3)
    - Pi.single cr[i].2.1 1 - Pi.single cr[i].2.2 1

theorem legal_iff_mulVec {n : ℕ} (cr : List (Fin n × Fin n × Fin n)) (c : Fin n → ZMod 3) :
    Legal cr c ↔ (crossingMatrix cr).mulVec c = 0 := by
  have key : ∀ i : Fin cr.length, (crossingMatrix cr).mulVec c i
      = 2 * c cr[i].1 - c cr[i].2.1 - c cr[i].2.2 := by
    intro i
    simp only [Matrix.mulVec, crossingMatrix, Matrix.of_apply, sub_dotProduct,
      two_nsmul, add_dotProduct, single_dotProduct]
    ring
  constructor
  · intro h
    funext i
    rw [key, Pi.zero_apply]
    exact h _ (List.getElem_mem _)
  · intro h x hx
    obtain ⟨i, hi, rfl⟩ := List.getElem_of_mem hx
    have := congrFun h ⟨i, hi⟩
    rw [key] at this
    exact this

#print axioms legal_iff_mulVec

/-- The number of colourings is 3 to the power (arcs minus the number of independent
crossing rules): `T(D) = 3^(n - r)`. -/
theorem colouring_count_eq_three_pow_arcs_sub_rank (n : ℕ) (cr : List (Fin n × Fin n × Fin n)) :
    T 3 n cr = 3 ^ (n - (crossingMatrix cr).rank) := by
  have h1 : T 3 n cr = Nat.card (LinearMap.ker (crossingMatrix cr).mulVecLin) := by
    rw [T, ← Fintype.card_coe, ← Nat.card_eq_fintype_card]
    refine Nat.card_congr (Equiv.subtypeEquivRight ?_)
    intro c
    simp [legal_iff_mulVec]
  have h2 := LinearMap.finrank_range_add_finrank_ker (crossingMatrix cr).mulVecLin
  rw [h1, Module.natCard_eq_pow_finrank (K := ZMod 3), Nat.card_zmod, Matrix.rank]
  congr 1
  simp only [Module.finrank_fin_fun] at h2
  omega

/-! The card's worked numbers. -/

-- The trefoil (3 arcs, 3 crossings) has 9 colourings; the ring (1 arc) has 3; 9 ≠ 3.
example : T 3 3 [(0, 1, 2), (1, 2, 0), (2, 0, 1)] = 9 := by decide
example : T 3 1 [] = 3 := by decide
example : T 3 3 [(0, 1, 2), (1, 2, 0), (2, 0, 1)] ≠ T 3 1 [] := by decide
-- The trefoil's 9 = 3 one-colour colourings + 6 all-different ones.
example : (Finset.univ.filter (fun c : Fin 3 → ZMod 3 => c 0 = c 1 ∧ c 1 = c 2)).card = 3 := by
  decide
example : (Finset.univ.filter
    (fun c : Fin 3 → ZMod 3 => c 0 ≠ c 1 ∧ c 1 ≠ c 2 ∧ c 0 ≠ c 2)).card = 6 := by decide
-- The other diagrams in the code: ring with a kink, ring with a poke, trefoil with a kink,
-- figure-eight, two separate rings, Hopf link.
example : T 3 1 [(0, 0, 0)] = 3 := by decide
example : T 3 2 [(0, 0, 1), (0, 1, 0)] = 3 := by decide
example : T 3 4 [(0, 1, 2), (1, 2, 0), (2, 3, 1), (3, 0, 3)] = 9 := by decide
example : T 3 4 [(0, 1, 2), (2, 3, 0), (1, 2, 3), (3, 0, 1)] = 3 := by decide
example : T 3 2 [] = 9 := by decide
example : T 3 2 [(0, 1, 1), (1, 0, 0)] = 3 := by decide
-- Three different colours pass the rule: 2·0 − 1 − 2 = −3 ≡ 0.
example : (2 * 0 - 1 - 2 : ZMod 3) = 0 := by decide
-- The slide worked with u = 1, m = 2, t = 0: the under strand leaves red both ways.
example : (2 * 0 - (2 * 2 - 1) : ZMod 3) = 0 := by decide
example : (2 * (2 * 0 - 2) - (2 * 0 - 1) : ZMod 3) = 0 := by decide
-- What breaks: no rule gives 27 for the trefoil and 81 after a kink.
example : Fintype.card (Fin 3 → ZMod 3) = 27 := by decide
example : Fintype.card (Fin 4 → ZMod 3) = 81 := by decide
-- "All different" only: the ring with a kink has no colouring.
example : (Finset.univ.filter (fun c : Fin 1 → ZMod 3 =>
    c 0 ≠ c 0 ∧ c 0 ≠ c 0 ∧ c 0 ≠ c 0)).card = 0 := by decide
-- Two colours: trefoil 2, ring 2.
example : T 2 3 [(0, 1, 2), (1, 2, 0), (2, 0, 1)] = 2 := by decide
example : T 2 1 [] = 2 := by decide

#print axioms reidemeister_moves_preserve_colouring_count
#print axioms crossing_rule_iff_all_same_or_all_different
#print axioms colouring_count_eq_three_pow_arcs_sub_rank

end Tricolour
