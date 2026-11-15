-- The fundamental group: loop classes at a point form a group under joining, and a continuous map induces a homomorphism of these groups.
import Mathlib.Topology.Homotopy.Path
import Mathlib.Topology.ContinuousMap.Basic
import Mathlib.AlgebraicTopology.FundamentalGroupoid.Basic

variable {X Y Z : Type*} [TopologicalSpace X] [TopologicalSpace Y] [TopologicalSpace Z]

/-- The loops at a fixed point `x₀`, counted as the same when one slides into the other with
both ends held at `x₀`, form a group. Its operation is joining: the class of `α` times the
class of `β` is the class of "run `α`, then `β`". Standing still is the identity, and running a
loop backwards gives the inverse. -/
theorem loop_classes_form_a_group (x₀ : X) :
    ∃ G : Group (Path.Homotopic.Quotient x₀ x₀),
      (∀ α β : Path x₀ x₀,
        G.mul (Path.Homotopic.Quotient.mk α) (Path.Homotopic.Quotient.mk β) =
          Path.Homotopic.Quotient.mk (α.trans β)) ∧
      G.one = Path.Homotopic.Quotient.mk (Path.refl x₀) ∧
      (∀ α : Path x₀ x₀,
        G.inv (Path.Homotopic.Quotient.mk α) = Path.Homotopic.Quotient.mk α.symm) := by
  refine ⟨{ mul := Path.Homotopic.Quotient.trans,
            one := Path.Homotopic.Quotient.refl x₀,
            inv := Path.Homotopic.Quotient.symm,
            mul_assoc := Path.Homotopic.Quotient.trans_assoc,
            one_mul := Path.Homotopic.Quotient.refl_trans,
            mul_one := Path.Homotopic.Quotient.trans_refl,
            inv_mul_cancel := Path.Homotopic.Quotient.symm_trans }, ?_, ?_, ?_⟩
  · intro α β
    exact (Path.Homotopic.Quotient.mk_trans α β).symm
  · exact (Path.Homotopic.Quotient.mk_refl x₀).symm
  · intro α
    exact (Path.Homotopic.Quotient.mk_symm α).symm

/-- A continuous map `f` gives a well-defined map `f_*` on loop classes, `f_*[α] = [f ∘ α]`,
landing in the loop classes at `f x₀`, and `f_*` respects joining:
`f_*([α][β]) = f_*[α] f_*[β]`. So `f_*` is a homomorphism. -/
theorem continuous_map_induces_homomorphism (f : C(X, Y)) (x₀ : X) :
    ∃ fstar : Path.Homotopic.Quotient x₀ x₀ → Path.Homotopic.Quotient (f x₀) (f x₀),
      (∀ α : Path x₀ x₀,
        fstar (Path.Homotopic.Quotient.mk α) =
          Path.Homotopic.Quotient.mk (α.map f.continuous)) ∧
      (∀ P Q : Path.Homotopic.Quotient x₀ x₀,
        fstar (Path.Homotopic.Quotient.trans P Q) =
          Path.Homotopic.Quotient.trans (fstar P) (fstar Q)) := by
  refine ⟨fun P => P.map f, fun α => rfl, ?_⟩
  intro P Q
  induction P using Path.Homotopic.Quotient.ind with | mk α =>
  induction Q using Path.Homotopic.Quotient.ind with | mk β =>
  exact congrArg Path.Homotopic.Quotient.mk (Path.map_trans α β f.continuous)

/-- Carrying by `f` and then by `g` is carrying by `g ∘ f`, and the map that moves nothing
carries every loop class to itself: `(g ∘ f)_* = g_* ∘ f_*` and `(id)_* = id`. -/
theorem induced_map_comp_and_id (f : C(X, Y)) (g : C(Y, Z)) (x₀ : X)
    (P : Path.Homotopic.Quotient x₀ x₀) :
    P.map (g.comp f) = (P.map f).map g ∧ P.map (ContinuousMap.id X) = P := by
  refine ⟨Path.Homotopic.Quotient.map_comp, ?_⟩
  induction P using Path.Homotopic.Quotient.ind with | mk α =>
  rw [← Path.Homotopic.Quotient.mk_map]
  exact congrArg Path.Homotopic.Quotient.mk (Path.map_id α)

namespace Pavement

/-! The card's worked numbers. A walk is the list of 1 m slab corners the dog visits, starting
and ending at the owner `(2, 0)`; the post is at `(0, 0)`. Joining drops the repeated meeting
corner. The winding number counts crossings of the ray east of the post going north, minus
those going south, exactly as in the card's code. -/

/-- Corners visited by a list of moves `(dx, dy, metres)` from the owner at `(2, 0)`. -/
def walk (moves : List (ℤ × ℤ × ℕ)) : List (ℤ × ℤ) :=
  (moves.flatMap fun m => List.replicate m.2.2 (m.1, m.2.1)).scanl
    (fun p d => (p.1 + d.1, p.2 + d.2)) (2, 0)

def join (a b : List (ℤ × ℤ)) : List (ℤ × ℤ) := a ++ b.tail

def crossing (s : (ℤ × ℤ) × (ℤ × ℤ)) : ℤ :=
  let x0 := s.1.1; let y0 := s.1.2; let x1 := s.2.1; let y1 := s.2.2
  if y0 ≤ 0 ∧ 0 < y1 ∧ 0 < x0 * y1 - x1 * y0 then 1
  else if y1 ≤ 0 ∧ 0 < y0 ∧ x0 * y1 - x1 * y0 < 0 then -1 else 0

def wind (p : List (ℤ × ℤ)) : ℤ := ((p.zip p.tail).map crossing).sum

def metres (p : List (ℤ × ℤ)) : ℕ := p.length - 1

def mirror (v : ℤ × ℤ) : ℤ × ℤ := (v.1, -v.2)

def sq (v : ℤ × ℤ) : ℤ × ℤ := (v.1 ^ 2 - v.2 ^ 2, 2 * v.1 * v.2)

/-- Lap a: N 2, W 4, S 4, E 4, N 2. -/
def lapA : List (ℤ × ℤ) := walk [(0, 1, 2), (-1, 0, 4), (0, -1, 4), (1, 0, 4), (0, 1, 2)]
/-- The small loop round a bin: E 1, N 1, W 1, S 1. -/
def bin : List (ℤ × ℤ) := walk [(1, 0, 1), (0, 1, 1), (-1, 0, 1), (0, -1, 1)]
/-- The wider lap: E 1, N 3, W 6, S 6, E 6, N 3, W 1. -/
def wide : List (ℤ × ℤ) :=
  walk [(1, 0, 1), (0, 1, 3), (-1, 0, 6), (0, -1, 6), (1, 0, 6), (0, 1, 3), (-1, 0, 1)]

-- lap a: 16 m, winding 1; the wide lap: 26 m, winding 1; the bin loop: 4 m, winding 0
example : metres lapA = 16 ∧ wind lapA = 1 := by decide
example : metres wide = 26 ∧ wind wide = 1 := by decide
example : metres bin = 4 ∧ wind bin = 0 := by decide
-- a·a: 32 m, winding 2; a·a·a: 48 m, winding 3
-- a·bin: 20 m, winding 1; a·a-bar: 32 m, winding 0
example : metres (join lapA lapA) = 32 ∧ wind (join lapA lapA) = 2 := by decide
example : metres (join lapA (join lapA lapA)) = 48 ∧ wind (join lapA (join lapA lapA)) = 3 := by
  decide
example : metres (join lapA bin) = 20 ∧ wind (join lapA bin) = 1 := by decide
example : metres (join lapA lapA.reverse) = 32 ∧ wind (join lapA lapA.reverse) = 0 := by decide
-- mirror sends winding 1 to -1; squaring sends 1 to 2; squaring after mirror sends 1 to -2
example : wind (lapA.map mirror) = -1 := by decide
example : wind (lapA.map sq) = 2 := by decide
example : wind (lapA.map (sq ∘ mirror)) = -2 := by decide
-- squaring a·a gives winding 4, the same as 2 + 2; the owner moves to (4, 0)
example : wind ((join lapA lapA).map sq) = 4 ∧
    wind (lapA.map sq) + wind (lapA.map sq) = 4 := by decide
example : sq (2, 0) = (4, 0) ∧ mirror (2, 0) = (2, 0) := by decide

end Pavement

#print axioms loop_classes_form_a_group
#print axioms continuous_map_induces_homomorphism
#print axioms induced_map_comp_and_id
