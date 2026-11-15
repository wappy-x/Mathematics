-- Projection: in a complete real inner-product space, every closed subspace splits each vector uniquely into its nearest point plus a perpendicular leftover, the nearest-point map is idempotent, the idempotent self-adjoint operators are exactly these projections, a closed convex set has one nearest point fixed by the obtuse-angle test, and the card's seven-day numbers are checked.
import Mathlib.Analysis.InnerProductSpace.Projection.Basic
import Mathlib.Analysis.InnerProductSpace.Projection.Minimal
import Mathlib.Analysis.Convex.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open RealInnerProductSpace

namespace ProjectionTheoremAndOrthogonalComplements

/-- Pythagoras for the projection: the distance from `y` to a point `m` of `M`, squared, is the
distance to the projection squared plus the distance from the projection to `m` squared. -/
theorem norm_sub_sq_eq_proj_add
    {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]
    (M : ClosedSubmodule ℝ H) (y m : H) (hm : m ∈ M) :
    ‖y - m‖ ^ 2 = ‖y - (M : Submodule ℝ H).starProjection y‖ ^ 2 +
      ‖(M : Submodule ℝ H).starProjection y - m‖ ^ 2 := by
  have hmem : (M : Submodule ℝ H).starProjection y - m ∈ (M : Submodule ℝ H) :=
    Submodule.sub_mem _ (Submodule.starProjection_apply_mem _ _) hm
  have h0 : ⟪y - (M : Submodule ℝ H).starProjection y,
      (M : Submodule ℝ H).starProjection y - m⟫ = 0 :=
    Submodule.starProjection_inner_eq_zero _ _ hmem
  have := norm_add_sq_eq_norm_sq_add_norm_sq_real h0
  rw [sub_add_sub_cancel] at this
  rw [sq, sq, sq]
  exact this

#print axioms norm_sub_sq_eq_proj_add

/-- The projection theorem. In a Hilbert space `H` (real scalars, complete), let `M` be a closed
subspace and `P` the projection onto it. Every vector `y` is `P y` plus a leftover `y - P y`,
with `P y` in `M` and the leftover in the orthogonal complement `Mᗮ`. This split is the only one:
any `y = m + r` with `m` in `M` and `r` in `Mᗮ` has `m = P y` and `r = y - P y`. `P y` is a
nearest point of `M` to `y`, and the only one. Projecting twice is projecting once:
`P ∘ P = P`. -/
theorem closed_subspace_unique_split_nearest_point_idempotent
    {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]
    (M : ClosedSubmodule ℝ H) :
    let P := (M : Submodule ℝ H).starProjection
    (∀ y : H,
      P y ∈ M ∧ y - P y ∈ (M : Submodule ℝ H)ᗮ ∧
      (∀ m ∈ M, ∀ r ∈ (M : Submodule ℝ H)ᗮ, y = m + r → m = P y ∧ r = y - P y) ∧
      (∀ m ∈ M, ‖y - P y‖ ≤ ‖y - m‖) ∧
      (∀ q ∈ M, (∀ m ∈ M, ‖y - q‖ ≤ ‖y - m‖) → q = P y)) ∧
    P ∘L P = P := by
  intro P
  refine ⟨fun y => ⟨?_, ?_, ?_, ?_, ?_⟩, ?_⟩
  · exact Submodule.starProjection_apply_mem _ _
  · exact Submodule.sub_starProjection_mem_orthogonal _
  · intro m hm r hr hy
    have h1 : P y = m := Submodule.eq_starProjection_of_mem_orthogonal' hm hr hy
    refine ⟨h1.symm, ?_⟩
    rw [h1, hy]; abel
  · intro m hm
    have h := norm_sub_sq_eq_proj_add M y m hm
    have h2 : ‖y - P y‖ ^ 2 ≤ ‖y - m‖ ^ 2 := by
      rw [h]; nlinarith [sq_nonneg ‖(M : Submodule ℝ H).starProjection y - m‖]
    exact (pow_le_pow_iff_left₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).mp h2
  · intro q hq hmin
    have h := norm_sub_sq_eq_proj_add M y q hq
    have hle := hmin (P y) (Submodule.starProjection_apply_mem _ _)
    have h2 : ‖y - q‖ ^ 2 ≤ ‖y - P y‖ ^ 2 :=
      pow_le_pow_left₀ (norm_nonneg _) hle 2
    have h3 : ‖P y - q‖ ^ 2 = 0 := by
      have := sq_nonneg ‖P y - q‖
      change ‖y - q‖ ^ 2 = ‖y - P y‖ ^ 2 + ‖P y - q‖ ^ 2 at h
      linarith
    have h4 : P y - q = 0 := by
      rwa [sq_eq_zero_iff, norm_eq_zero] at h3
    exact (sub_eq_zero.mp h4).symm
  · exact (Submodule.isIdempotentElem_starProjection (K := (M : Submodule ℝ H))).eq

/-- Idempotent and self-adjoint is exactly an orthogonal projection. A bounded operator `P` on a
Hilbert space satisfies `P ∘ P = P` and `⟪P x, y⟫ = ⟪x, P y⟫` for all `x`, `y` exactly when it
is the projection onto some closed subspace `M`. -/
theorem idempotent_self_adjoint_iff_orthogonal_projection
    {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]
    (P : H →L[ℝ] H) :
    (P ∘L P = P ∧ ∀ x y : H, ⟪P x, y⟫ = ⟪x, P y⟫) ↔
      ∃ M : ClosedSubmodule ℝ H, P = (M : Submodule ℝ H).starProjection := by
  constructor
  · rintro ⟨hidem, hsym⟩
    have hclosed : IsClosed (LinearMap.range (P : H →ₗ[ℝ] H) : Set H) := by
      have : (LinearMap.range (P : H →ₗ[ℝ] H) : Set H) = {x | P x = x} := by
        ext x
        constructor
        · rintro ⟨z, rfl⟩
          change P (P z) = P z
          rw [← ContinuousLinearMap.comp_apply, hidem]
        · intro hx
          exact ⟨x, hx⟩
      rw [this]
      exact isClosed_eq P.continuous continuous_id
    refine ⟨⟨LinearMap.range (P : H →ₗ[ℝ] H), hclosed⟩, ?_⟩
    ext x
    symm
    apply Submodule.eq_starProjection_of_mem_orthogonal
    · exact ⟨x, rfl⟩
    · rintro w ⟨z, rfl⟩
      change ⟪P z, x - P x⟫ = 0
      have : P (P x) = P x := by rw [← ContinuousLinearMap.comp_apply, hidem]
      rw [hsym, map_sub, this, sub_self, inner_zero_right]
  · rintro ⟨M, rfl⟩
    exact ⟨(Submodule.isIdempotentElem_starProjection (K := (M : Submodule ℝ H))).eq,
      Submodule.inner_starProjection_left_eq_right _⟩

/-- Closed convex sets. In a Hilbert space, a non-empty closed convex set `C` has exactly one
nearest point `p` to each vector `y`. A point `p` of `C` is that nearest point exactly when every
other member `c` of `C` sits at an angle of 90° or more: `⟪y - p, c - p⟫ ≤ 0`. -/
theorem closed_convex_unique_nearest_point_obtuse_angle
    {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]
    (C : Set H) (hne : C.Nonempty) (hclosed : IsClosed C) (hconv : Convex ℝ C) (y : H) :
    (∃! p, p ∈ C ∧ ∀ c ∈ C, ‖y - p‖ ≤ ‖y - c‖) ∧
    ∀ p ∈ C, ((∀ c ∈ C, ‖y - p‖ ≤ ‖y - c‖) ↔ ∀ c ∈ C, ⟪y - p, c - p⟫ ≤ 0) := by
  have hiff : ∀ p ∈ C, ((∀ c ∈ C, ‖y - p‖ ≤ ‖y - c‖) ↔ ∀ c ∈ C, ⟪y - p, c - p⟫ ≤ 0) := by
    intro p hp
    have : Nonempty C := ⟨⟨p, hp⟩⟩
    have hbdd : BddBelow (Set.range fun w : C => ‖y - w‖) :=
      ⟨0, Set.forall_mem_range.2 fun _ => norm_nonneg _⟩
    rw [← norm_eq_iInf_iff_real_inner_le_zero hconv hp]
    constructor
    · intro h
      apply le_antisymm
      · exact le_ciInf fun w => h w w.2
      · exact ciInf_le hbdd ⟨p, hp⟩
    · intro h c hc
      rw [h]
      exact ciInf_le hbdd ⟨c, hc⟩
  refine ⟨?_, hiff⟩
  obtain ⟨p, hp, hpeq⟩ := exists_norm_eq_iInf_of_complete_convex hne hclosed.isComplete hconv y
  have : Nonempty C := ⟨⟨p, hp⟩⟩
  have hbdd : BddBelow (Set.range fun w : C => ‖y - w‖) :=
    ⟨0, Set.forall_mem_range.2 fun _ => norm_nonneg _⟩
  have hpmin : ∀ c ∈ C, ‖y - p‖ ≤ ‖y - c‖ := fun c hc => hpeq ▸ ciInf_le hbdd ⟨c, hc⟩
  refine ⟨p, ⟨hp, hpmin⟩, ?_⟩
  rintro q ⟨hq, hqmin⟩
  have h1 := (hiff p hp).mp hpmin q hq
  have h2 := (hiff q hq).mp hqmin p hp
  have h3 : ⟪q - p, q - p⟫ ≤ 0 := by
    have e : ⟪q - p, q - p⟫ = ⟪y - p, q - p⟫ + ⟪y - q, p - q⟫ :=
      calc ⟪q - p, q - p⟫ = ⟪(y - p) - (y - q), q - p⟫ := by congr 1; abel
        _ = ⟪y - p, q - p⟫ - ⟪y - q, q - p⟫ := inner_sub_left _ _ _
        _ = ⟪y - p, q - p⟫ + ⟪y - q, p - q⟫ := by
          have hn : ⟪y - q, q - p⟫ = -⟪y - q, p - q⟫ := by
            rw [← inner_neg_right, neg_sub]
          rw [hn, sub_neg_eq_add]
    linarith
  exact sub_eq_zero.mp (real_inner_self_nonpos.mp h3)

/-! The card's seven-day record: readings `y`, days `t` counted from the middle day, the all-ones
record `one`, the trend `p = 11 + t`, the leftover `r`, and the integer matrix `28 P_M = 4J + t tᵀ`. -/

/-- The week's readings, in °C. -/
def y : Fin 7 → ℤ := ![8, 10, 9, 11, 12, 12, 15]
/-- The day, counted from the middle day. -/
def t : Fin 7 → ℤ := ![-3, -2, -1, 0, 1, 2, 3]
/-- The all-ones record. -/
def one : Fin 7 → ℤ := fun _ => 1
/-- The trend, 11 + t. -/
def p : Fin 7 → ℤ := ![8, 9, 10, 11, 12, 13, 14]
/-- The leftover, record minus trend. -/
def r : Fin 7 → ℤ := ![0, 1, -1, 0, 0, -1, 1]
/-- The matrix `28 P_M = 4J + t tᵀ`. -/
def P28 : Matrix (Fin 7) (Fin 7) ℤ := fun i j => 4 + t i * t j

-- ⟨y, 1⟩ = 77, ⟨y, t⟩ = 28, ⟨t, t⟩ = 28: intercept 77/7 = 11, slope 28/28 = 1.
example : ∑ i, y i * one i = 77 := by decide
example : ∑ i, y i * t i = 28 := by decide
example : ∑ i, t i * t i = 28 := by decide
-- The trend is 11 + t, and the record is trend plus leftover.
example : p = fun i => 11 + t i := by decide
example : y = p + r := by decide
-- The leftover is perpendicular to every line: ⟨r, 1⟩ = 0 and ⟨r, t⟩ = 0.
example : ∑ i, r i * one i = 0 := by decide
example : ∑ i, r i * t i = 0 := by decide
-- Pythagoras: 879 = 875 + 4.
example : ∑ i, y i * y i = 879 ∧ ∑ i, p i * p i = 875 ∧ ∑ i, r i * r i = 4 := by decide
-- The matrix sends the record to 28 times the trend.
example : P28.mulVec y = fun i => 28 * p i := by decide
-- (28 P_M)² = 28 · (28 P_M), so P_M P_M = P_M; and P_M equals its transpose.
example : P28 * P28 = (28 : ℤ) • P28 := by decide
example : P28.transpose = P28 := by decide
-- trace (28 P_M) = 56 and trace (28 I - 28 P_M) = 140: dimensions 2 and 5.
example : P28.trace = 56 ∧ (28 * 7 : ℤ) - P28.trace = 140 := by decide
-- The line fit of the leftover is zero: P_M r = 0.
example : P28.mulVec r = 0 := by decide

#print axioms closed_subspace_unique_split_nearest_point_idempotent
#print axioms idempotent_self_adjoint_iff_orthogonal_projection
#print axioms closed_convex_unique_nearest_point_obtuse_angle

end ProjectionTheoremAndOrthogonalComplements
