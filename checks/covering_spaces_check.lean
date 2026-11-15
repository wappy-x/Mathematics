-- Covering spaces: every path in the base of a covering map has exactly one lift from a chosen start, a map from a path-connected, locally path-connected space lifts exactly when its loops land inside the cover's loop subgroup, and for the line over the circle a lifted loop climbs a whole number of turns.
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Topology.Homotopy.Lifting

open unitInterval Real

/-! A covering map `p : E → X` is Mathlib's `IsCoveringMap p`: every point of the base `X` has an
open patch `U` that is evenly covered, `p⁻¹(U)` being a disjoint union of sheets, each mapped onto
`U` by a homeomorphism. A path is a continuous map from the time interval `I = [0, 1]`.
A lift of `γ : C(I, X)` is a continuous `Γ : C(I, E)` with `p ∘ Γ = γ`.
For a map `f : C(A, X)`, `FundamentalGroup.map f a₀` is `f_*` on `π₁(A, a₀)`, and
`FundamentalGroup.mapOfEq ⟨p, _⟩ he` is `p_*` from `π₁(E, e₀)` into `π₁(X, f a₀)`.
The circle `S¹` is Mathlib's unit circle `Circle` in the complex plane, and the line covers it by
`p(s) = (cos 2πs, sin 2πs)`, which is `Circle.exp (2 * π * s)`, with `s` measured in turns. -/

/-- **Path lifting.** For a covering map `p : E → X` (every patch evenly covered), every path `γ`
in the base and every chosen start `e` above `γ(0)`, there is exactly one lift of `γ` that starts
at `e`: one continuous path `Γ` in the cover with `p ∘ Γ = γ` and `Γ(0) = e`. -/
theorem path_lifts_uniquely {E X : Type*} [TopologicalSpace E] [TopologicalSpace X]
    {p : E → X} (cov : IsCoveringMap p) (γ : C(I, X)) (e : E) (he : p e = γ 0) :
    ∃! Γ : C(I, E), p ∘ Γ = γ ∧ Γ 0 = e := by
  refine ⟨cov.liftPath γ e he.symm, ⟨cov.liftPath_lifts γ e he.symm, cov.liftPath_zero γ e he.symm⟩,
    fun Γ hΓ => (cov.eq_liftPath_iff' he.symm).mpr hΓ⟩

/-- **The lifting criterion.** Let `p : E → X` be a covering map, `Y` a path-connected and
locally path-connected space, `f : Y → X` continuous, and `e₀` a point of the cover above
`f(y₀)`. A lift `F` with `p ∘ F = f` and `F(y₀) = e₀` exists exactly when
`f_*(π₁(Y, y₀)) ⊆ p_*(π₁(E, e₀))`: every loop `f` draws below is, up to sliding, the shadow of
a loop up in the cover. -/
theorem lift_exists_iff_loops_inside_cover_subgroup {E X Y : Type*} [TopologicalSpace E]
    [TopologicalSpace X] [TopologicalSpace Y] [PathConnectedSpace Y]
    [LocallyPathConnectedSpace Y] {p : E → X} (cov : IsCoveringMap p) (f : C(Y, X)) (y₀ : Y)
    (e₀ : E) (he₀ : p e₀ = f y₀) :
    (∃ F : C(Y, E), F y₀ = e₀ ∧ p ∘ F = f) ↔
      (FundamentalGroup.map f y₀).range ≤
        (FundamentalGroup.mapOfEq ⟨p, cov.continuous⟩ he₀).range := by
  constructor
  · rintro ⟨F, hF0, hFp⟩
    subst hF0
    obtain rfl : f = (⟨p, cov.continuous⟩ : C(E, X)).comp F := by
      ext y; exact (congr_fun hFp y).symm
    rintro _ ⟨g, rfl⟩
    refine ⟨FundamentalGroup.map F y₀ g, ?_⟩
    rw [FundamentalGroup.mapOfEq_apply]
    obtain ⟨g⟩ := g
    induction g using Quotient.inductionOn with
    | h a => rfl
  · intro h
    exact (cov.existsUnique_continuousMap_lifts_of_range_le he₀ h).exists

/-- **The line over the circle reads off integers.** For `p(s) = (cos 2πs, sin 2πs)`, the points
of the line above `p(s)` are exactly `s + m` for whole numbers `m`; and if `γ` is a loop on the
circle (`γ(0) = γ(1)`) and `Γ` is any continuous lift of it to the line, then `Γ(1) − Γ(0)` is a
whole number: the floors the lifted loop climbs. -/
theorem line_over_circle_lifted_loop_climbs_whole_turns :
    (∀ s t : ℝ, Circle.exp (2 * π * t) = Circle.exp (2 * π * s) ↔ ∃ m : ℤ, t = s + m) ∧
      ∀ (γ : C(I, Circle)) (Γ : C(I, ℝ)), γ 0 = γ 1 →
        (∀ u, Circle.exp (2 * π * Γ u) = γ u) → ∃ m : ℤ, Γ 1 - Γ 0 = m := by
  have key : ∀ s t : ℝ, Circle.exp (2 * π * t) = Circle.exp (2 * π * s) ↔ ∃ m : ℤ, t = s + m := by
    intro s t
    rw [Circle.exp_eq_exp]
    have hπ : (2 * π) ≠ 0 := by positivity
    constructor
    · rintro ⟨m, hm⟩
      refine ⟨m, ?_⟩
      apply mul_left_cancel₀ hπ
      linear_combination hm
    · rintro ⟨m, rfl⟩
      exact ⟨m, by ring⟩
  refine ⟨key, fun γ Γ h0 hΓ => ?_⟩
  obtain ⟨m, hm⟩ := (key (Γ 0) (Γ 1)).mp (by rw [hΓ, hΓ, h0])
  exact ⟨m, by rw [hm]; ring⟩

/-! Worked numbers. Positions are whole degrees: a plan angle is taken mod 360, a ramp position is
not; one circuit is 360 degrees, one floor, 3 m up, with 24 bays of 15 degrees. -/

/-- The short way from plan angle `a` to plan angle `b`, in `(-180, 180]` degrees. -/
def rampStep (a b : ℤ) : ℤ := (b - a + 179) % 360 - 179

/-- Follow a log of plan angles up the ramp from ramp position 0, one short step at a time. -/
def rampLift (angles : List ℤ) : List ℤ :=
  List.scanl (· + ·) 0 (List.zipWith rampStep angles angles.tail)

/-- The car's tracker log: its plan angle every 30 seconds. -/
def tracker : List ℤ := [0, 100, 200, 300, 40, 140, 240, 340, 80, 180]

/-- The loop `z ↦ z^k` on the plan, sampled every 30 degrees of `z`: 13 readings. -/
def loopAngles (k : ℤ) : List ℤ := (List.range 13).map fun j => (30 * k * j) % 360

-- The tracker log lifts, step by step, to 0, 100, ..., 900 degrees up the ramp.
example : rampLift tracker = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900] := by
  decide

-- From ramp 700, of the candidates 80, 440, 800, 1160 above 80 degrees, only 800 is in reach.
example : ([80, 440, 800, 1160] : List ℤ).filter (fun c => |c - 700| < 180) = [800] := by
  decide

-- End of lift: 900 degrees is 5/2 turns; floor 2, bay 12, height 15/2 m.
example : (900 : ℚ) / 360 = 5 / 2 ∧ (900 : ℤ) / 360 = 2 ∧ (180 : ℤ) / 15 = 12 ∧
    (5 / 2 : ℚ) * 3 = 15 / 2 := by
  norm_num

-- Drive up and back down: the lift ends at 0 degrees, floor 0.
example : (rampLift (tracker ++ tracker.reverse.tail)).getLast? = some 0 := by
  decide

-- Mistake: readings every 60 s lift to -640 degrees, floor -2.
example : rampLift [0, 200, 40, 240, 80] = [0, -160, -320, -480, -640] ∧
    (-640 : ℤ) / 360 = -2 := by
  decide

-- Mistake: [0, 1) as the cover sends 340 degrees to 17/18 turn and 80 to 2/9, a jump of -13/18.
example : (340 : ℚ) / 360 = 17 / 18 ∧ (80 : ℚ) / 360 = 2 / 9 ∧
    ((80 : ℚ) - 340) / 360 = -13 / 18 := by
  norm_num

-- Lifting criterion on all 28 cases: z^k lifts to a closed loop in the n-fold cover iff n ∣ k.
example : ∀ n ∈ ([1, 2, 3, 4] : List ℤ), ∀ k ∈ ([-3, -2, -1, 0, 1, 2, 3] : List ℤ),
    ((rampLift (loopAngles k)).getLast?.map (· % (360 * n)) = some 0 ↔ n ∣ k) := by
  decide

-- A loop of k turns lifted into the 3-fold cover ends on sheet k mod 3, for k = 0..5.
example : ((List.range 6).map fun k : ℕ =>
    (rampLift (loopAngles k)).getLast?.map (fun e => e % 1080 / 360)) =
    [some 0, some 1, some 2, some 0, some 1, some 2] := by
  decide

-- Mistake: z^3 through the double cover ends at 360 degrees, sheet 1, since 2 does not divide 3.
example : (rampLift (loopAngles 3)).getLast?.map (· % 720) = some 360 ∧ ¬ (2 : ℤ) ∣ 3 := by
  decide

#print axioms path_lifts_uniquely
#print axioms lift_exists_iff_loops_inside_cover_subgroup
#print axioms line_over_circle_lifted_loop_climbs_whole_turns
