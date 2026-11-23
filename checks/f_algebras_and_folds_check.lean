-- F-algebras: every algebra of the expression functor F X = ℕ + X × X + X × X has exactly one fold from the finite expression trees, the arrow in of any initial algebra is invertible (Lambek's lemma), and the power-set functor has no initial algebra.
import Mathlib.CategoryTheory.Endofunctor.Algebra
import Mathlib.CategoryTheory.Types.Basic
import Mathlib.Data.Fintype.Powerset
import Mathlib.Tactic.NormNum.Basic

open CategoryTheory

namespace FAlgebrasAndFolds

/-- One layer of an expression, with holes of type X: the card's F X = ℕ + (X × X) + (X × X).
`Sum.inl n` is `lit n`, `Sum.inr (Sum.inl (x, y))` is `add(x, y)`,
`Sum.inr (Sum.inr (x, y))` is `mul(x, y)`. -/
abbrev Layer (X : Type) : Type := ℕ ⊕ (X × X) ⊕ (X × X)

/-- F on a function f: keep the shape, apply f in each hole; `lit n` stays as it is. -/
def layerMap {X Y : Type} (f : X → Y) : Layer X → Layer Y :=
  Sum.map id (Sum.map (Prod.map f f) (Prod.map f f))

/-- The expression functor F on the category of sets (Lean's `Type`). -/
def exprF : Type ⥤ Type where
  obj X := Layer X
  map f := TypeCat.ofHom (layerMap f)
  map_id X := by
    ext l
    rcases l with n | ⟨a, b⟩ | ⟨a, b⟩ <;> rfl
  map_comp f g := by
    ext l
    rcases l with n | ⟨a, b⟩ | ⟨a, b⟩ <;> rfl

/-- The finite expression trees T: a literal, or an add or a mul over two smaller trees. -/
inductive Expr : Type
  | lit : ℕ → Expr
  | add : Expr → Expr → Expr
  | mul : Expr → Expr → Expr
  deriving DecidableEq

/-- in : F T → T, building a tree from one layer of subtrees. -/
def inFun : Layer Expr → Expr
  | Sum.inl n => Expr.lit n
  | Sum.inr (Sum.inl (a, b)) => Expr.add a b
  | Sum.inr (Sum.inr (a, b)) => Expr.mul a b

/-- in, as an arrow of the category of sets. -/
def inn : exprF.obj Expr ⟶ Expr := TypeCat.ofHom inFun

/-- The power-set functor 𝒫: a set X goes to its set of subsets, a function f to taking images. -/
def powersetF : Type ⥤ Type where
  obj X := Set X
  map f := TypeCat.ofHom (Set.image f)
  map_id X := by
    ext s x
    simp
  map_comp f g := by
    ext s x
    simp

/-- Helper: the fold of an algebra map `α`, written by recursion on trees. -/
def foldFun {A : Type} (α : Layer A → A) : Expr → A
  | Expr.lit n => α (Sum.inl n)
  | Expr.add a b => α (Sum.inr (Sum.inl (foldFun α a, foldFun α b)))
  | Expr.mul a b => α (Sum.inr (Sum.inr (foldFun α a, foldFun α b)))

#print axioms foldFun

/-- **Each algebra has exactly one fold.** For every F-algebra, a carrier set A with one arrow
α : F A → A, there is exactly one arrow fold : T → A from the finite expression trees with
fold ∘ in = α ∘ F(fold): fold the subtrees in the holes, then apply one step of α. Lean writes
`g ≫ f` for "g first, then f". -/
theorem fold_exists_unique (A : Type) (α : exprF.obj A ⟶ A) :
    ∃! fold : Expr ⟶ A, inn ≫ fold = exprF.map fold ≫ α := by
  refine ⟨TypeCat.ofHom (foldFun (fun l => α l)), ?_, ?_⟩
  · ext l
    rcases l with n | ⟨a, b⟩ | ⟨a, b⟩ <;> rfl
  · intro g hg
    have key : ∀ l : Layer Expr, g (inFun l) = α (layerMap (fun x => g x) l) := fun l =>
      congrArg (fun h : exprF.obj Expr ⟶ A => h l) hg
    have H : ∀ e : Expr, g e = foldFun (fun l => α l) e := by
      intro e
      induction e with
      | lit n => exact key (Sum.inl n)
      | add a b iha ihb =>
        have := key (Sum.inr (Sum.inl (a, b)))
        simp only [inFun, layerMap, Sum.map_inr, Sum.map_inl, Prod.map] at this
        rw [this, iha, ihb]; rfl
      | mul a b iha ihb =>
        have := key (Sum.inr (Sum.inr (a, b)))
        simp only [inFun, layerMap, Sum.map_inr, Prod.map] at this
        rw [this, iha, ihb]; rfl
    ext e
    exact H e

/-- **Lambek's lemma.** For any endofunctor F of any category, if an F-algebra (T, in) is
initial (exactly one algebra map to every other algebra), then in : F T → T is invertible. -/
theorem lambek_lemma {C : Type*} [Category C] {F : C ⥤ C} (T : Endofunctor.Algebra F)
    (h : Limits.IsInitial T) : IsIso T.str := by
  exact Endofunctor.Algebra.Initial.str_isIso h

/-- **The power-set functor has no initial algebra.** There is no algebra of the power-set
functor 𝒫 that is initial. -/
theorem powerset_no_initial_algebra :
    ¬ ∃ T : Endofunctor.Algebra powersetF, Nonempty (Limits.IsInitial T) := by
  rintro ⟨T, ⟨h⟩⟩
  have hiso : IsIso T.str := Endofunctor.Algebra.Initial.str_isIso h
  have hbij := (isIso_iff_bijective T.str).1 hiso
  exact Function.cantor_injective (fun s : Set T.a => T.str s) hbij.1

/-! ### The card's worked numbers -/

/-- The fold of α, written out by recursion, for computing the card's examples. -/
def Expr.fold {A : Type} (α : Layer A → A) : Expr → A
  | Expr.lit n => α (Sum.inl n)
  | Expr.add a b => α (Sum.inr (Sum.inl (Expr.fold α a, Expr.fold α b)))
  | Expr.mul a b => α (Sum.inr (Sum.inr (Expr.fold α a, Expr.fold α b)))

/-- The bill: 3 coffees at p pence plus 2 sandwiches at 240 pence. -/
def receipt (p : ℕ) : Expr :=
  Expr.add (Expr.mul (Expr.lit 3) (Expr.lit p)) (Expr.mul (Expr.lit 2) (Expr.lit 240))

/-- The evaluate algebra: return n, add, multiply. -/
def evalAlg : Layer ℕ → ℕ := Sum.elim id (Sum.elim (fun p => p.1 + p.2) (fun p => p.1 * p.2))
/-- The same rules on an m-hour clock. -/
def clockAlg (m : ℕ) : Layer ℕ → ℕ :=
  Sum.elim (fun n => n % m) (Sum.elim (fun p => (p.1 + p.2) % m) (fun p => p.1 * p.2 % m))
/-- Count nodes. -/
def sizeAlg : Layer ℕ → ℕ := Sum.elim (fun _ => 1) (Sum.elim (fun p => 1 + p.1 + p.2) (fun p => 1 + p.1 + p.2))
/-- Height. -/
def heightAlg : Layer ℕ → ℕ :=
  Sum.elim (fun _ => 0) (Sum.elim (fun p => 1 + max p.1 p.2) (fun p => 1 + max p.1 p.2))
/-- Leaves lose their last digit, operators kept: not an algebra map from evaluate. -/
def dropDigitAlg : Layer ℕ → ℕ := Sum.elim (fun n => n / 10) (Sum.elim (fun p => p.1 + p.2) (fun p => p.1 * p.2))

/-- The trees built in k layers (F applied k times to the empty set), literals 2 and 3. -/
def levels : ℕ → List Expr
  | 0 => []
  | k + 1 =>
    [Expr.lit 2, Expr.lit 3] ++
      ((levels k).flatMap fun a => (levels k).map fun b => Expr.add a b) ++
      ((levels k).flatMap fun a => (levels k).map fun b => Expr.mul a b)

/-- The count a(k+1) = 2 + 2 a(k)^2 from a(0) = 0. -/
def a : ℕ → ℕ
  | 0 => 0
  | k + 1 => 2 + 2 * a k ^ 2

-- The bill evaluates to 855 pence; 7 nodes; height 2; the 10-hour clock gives 5; the 7-hour
-- clock gives 1; a coffee at 140 pence gives 900.
example : (receipt 125).fold evalAlg = 855 := by decide
example : (receipt 125).fold sizeAlg = 7 := by decide
example : (receipt 125).fold heightAlg = 2 := by decide
example : (receipt 125).fold (clockAlg 10) = 5 := by decide
example : (receipt 125).fold (clockAlg 7) = 1 := by decide
example : (receipt 140).fold evalAlg = 900 := by decide
-- Fusion on the bill: the clock fold equals the last digit of the evaluate fold.
example : (receipt 125).fold (clockAlg 10) = (receipt 125).fold evalAlg % 10 := by decide
-- Fusing "drop the last digit" gives 0, but 855 drops to 85.
example : (receipt 125).fold dropDigitAlg = 0 ∧ 855 / 10 = 85 := by decide
-- Read left to right, the bill gives 90,480.
example : ((3 * 125) + 2) * 240 = 90480 := by norm_num
-- Trees built in k layers: 0, 2, 10, 202 by listing; the count gives 0, 2, 10, 202, 81,610.
example : (List.range 4).map (fun k => (levels k).length) = [0, 2, 10, 202] := by
  decide +kernel
example : (List.range 5).map a = [0, 2, 10, 202, 81610] := by decide
-- The brute-force uniqueness test runs over 3^10 = 59,049 maps; the 2-hour clock over 2^10 = 1,024.
example : 3 ^ 10 = 59049 ∧ 2 ^ 10 = 1024 := by norm_num
-- A set of 5 members has 32 subsets, never 5.
example : Fintype.card (Set (Fin 5)) = 32 := by rw [Fintype.card_set]; norm_num

#print axioms fold_exists_unique
#print axioms lambek_lemma
#print axioms powerset_no_initial_algebra

end FAlgebrasAndFolds
