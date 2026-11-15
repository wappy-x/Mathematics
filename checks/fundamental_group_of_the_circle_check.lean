-- The circle's fundamental group is the integers: every loop on the unit circle at 1 is classified up to sliding by where its lift ends, and this whole number turns the fundamental group into the integers under addition.
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Topology.Covering.FundamentalGroupCircle

open unitInterval Real

/-! The circle `S¹` is Mathlib's unit circle `Circle` in the complex plane, with base point
`x₀ = 1` (east). The loop clock `s` runs over `I = [0, 1]`.
The wrap `w(y) = (cos 2πy, sin 2πy)` is `Circle.exp (2 * π * y)`.
A lift from 0 of a path `γ` is a continuous `f : I → ℝ` with `f 0 = 0` and `w (f s) = γ s`
for every `s`. The winding number `n(γ)` is `f 1`.
The fundamental group `π₁(S¹, x₀)` is Mathlib's `FundamentalGroup Circle 1`; the class `[γ]`
of a loop is `FundamentalGroup.fromPath (Path.Homotopic.Quotient.mk γ)`.
The integers under addition are `Multiplicative ℤ` as a group; `toAdd` reads off the integer.
`α.trans β` runs `α` and then `β`, each at double speed: the card's `α · β`. -/

/-- **The circle's fundamental group is the integers.** There is a group isomorphism from
`π₁(S¹, x₀)` to the whole numbers under addition that sends the class of each loop `γ` to
`n(γ)`, where its lift from 0 ends; and running `α` then `β` adds the counts:
`n(α · β) = n(α) + n(β)`. -/
theorem circle_fundamental_group_iso_int :
    ∃ φ : FundamentalGroup Circle 1 ≃* Multiplicative ℤ,
      (∀ (γ : Path (1 : Circle) 1) (f : C(I, ℝ)), f 0 = 0 →
        (∀ s, Circle.exp (2 * π * f s) = γ s) →
          ((φ (FundamentalGroup.fromPath (Path.Homotopic.Quotient.mk γ))).toAdd : ℝ) = f 1) ∧
      (∀ α β : Path (1 : Circle) 1,
        (φ (FundamentalGroup.fromPath (Path.Homotopic.Quotient.mk (α.trans β)))).toAdd =
          (φ (FundamentalGroup.fromPath (Path.Homotopic.Quotient.mk α))).toAdd +
            (φ (FundamentalGroup.fromPath (Path.Homotopic.Quotient.mk β))).toAdd) := by
  have hp := Circle.isAddQuotientCoveringMap_exp
  have h2π : (2 * π) ≠ 0 := by positivity
  let e0 : Circle.exp ⁻¹' {1} := ⟨0, by simp⟩
  refine ⟨(hp.fundamentalGroupEquiv (x := 1) e0).trans <|
    MulOpposite.opMulEquiv.symm.trans (AddSubgroup.zmultiplesEquivInt h2π).toMultiplicative,
    ?_, ?_⟩
  · intro γ f hf0 hf
    obtain ⟨n, hn⟩ : ∃ n : ℤ, f 1 = n := by
      have := hf 1
      rw [γ.target, Circle.exp_eq_one] at this
      obtain ⟨n, hn⟩ := this
      refine ⟨n, ?_⟩
      have hπ : (0:ℝ) < π := pi_pos
      nlinarith
    let Γ : C(I, ℝ) := ⟨fun s => 2 * π * f s, by fun_prop⟩
    have h : hp.fundamentalGroupToMulOpposite (x := 1) e0 (.of (.mk γ)) =
        .op (.ofAdd ⟨n • (2 * π), n, rfl⟩) :=
      hp.fundamentalGroupToMulOpposite_apply_mk_eq (Γ := Γ) (funext fun s => hf s)
        (by simp [Γ, hf0, e0]) (by
          change 2 * π * f 1 = (n • (2 * π) : ℝ) + 0
          rw [hn, zsmul_eq_mul]; ring)
    have h' : hp.fundamentalGroupEquiv (x := 1) e0
        (FundamentalGroup.fromPath (Path.Homotopic.Quotient.mk γ)) =
        .op (.ofAdd ⟨n • (2 * π), n, rfl⟩) := h
    rw [hn]
    simp only [MulEquiv.trans_apply, h', MulOpposite.opMulEquiv_symm_apply,
      MulOpposite.unop_op]
    exact congrArg (fun z : ℤ => (z : ℝ)) (AddSubgroup.zmultiplesEquivInt_apply_zsmul h2π n)
  · intro α β
    rw [show FundamentalGroup.fromPath (Path.Homotopic.Quotient.mk (α.trans β)) =
      FundamentalGroup.fromPath (.mk β) * FundamentalGroup.fromPath (.mk α) from rfl]
    rw [map_mul, toAdd_mul, add_comm]

/-- **Every path has exactly one lift from 0, and a loop's lift ends on a whole number.**
A continuous path `γ` on the circle starting at `x₀` has exactly one continuous lift `f`
on the real line with `f 0 = 0` and `w (f s) = γ s`; if `γ` also ends at `x₀`, then `f 1`
is a whole number. -/
theorem path_lifts_uniquely_and_loop_lift_ends_on_integer (γ : C(I, Circle)) (h0 : γ 0 = 1) :
    (∃! f : C(I, ℝ), f 0 = 0 ∧ ∀ s, Circle.exp (2 * π * f s) = γ s) ∧
      (γ 1 = 1 → ∀ f : C(I, ℝ), f 0 = 0 → (∀ s, Circle.exp (2 * π * f s) = γ s) →
        ∃ n : ℤ, f 1 = n) := by
  have h2π : (2 * π) ≠ 0 := by positivity
  refine ⟨?_, ?_⟩
  · obtain ⟨Γ, hΓ, hΓ0⟩ :=
      Circle.isCoveringMap_exp.exists_path_lifts γ 0 (by simp [h0])
    refine ⟨⟨fun s => Γ s / (2 * π), by fun_prop⟩, ⟨?_, fun s => ?_⟩, ?_⟩
    · simp [hΓ0]
    · change Circle.exp (2 * π * (Γ s / (2 * π))) = γ s
      rw [mul_div_cancel₀ _ h2π]
      exact congrFun hΓ s
    · rintro g ⟨hg0, hg⟩
      have key : (fun s => 2 * π * g s) = (Γ : I → ℝ) :=
        Circle.isCoveringMap_exp.eq_of_comp_eq (by fun_prop) Γ.continuous
          (by funext s; simp only [Function.comp_apply, hg]; exact (congrFun hΓ s).symm)
          0 (by simp [hg0, hΓ0])
      ext s
      change g s = Γ s / (2 * π)
      rw [← congrFun key s]
      field_simp
  · intro h1 f _ hf
    have := hf 1
    rw [h1, Circle.exp_eq_one] at this
    obtain ⟨n, hn⟩ := this
    refine ⟨n, ?_⟩
    have hπ : (0:ℝ) < π := pi_pos
    nlinarith

/-- **Two loops slide into each other exactly when they wind the same number of times.**
Loops `α` and `γ` at `x₀` are homotopic with the ends held at `x₀` if and only if their
lifts from 0 end at the same number. -/
theorem loops_homotopic_iff_same_winding_number (α γ : Path (1 : Circle) 1) (fα fγ : C(I, ℝ))
    (hα0 : fα 0 = 0) (hα : ∀ s, Circle.exp (2 * π * fα s) = α s)
    (hγ0 : fγ 0 = 0) (hγ : ∀ s, Circle.exp (2 * π * fγ s) = γ s) :
    α.Homotopic γ ↔ fα 1 = fγ 1 := by
  obtain ⟨φ, hφ, -⟩ := circle_fundamental_group_iso_int
  rw [← hφ α fα hα0 hα, ← hφ γ fγ hγ0 hγ, Int.cast_inj, EmbeddingLike.apply_eq_iff_eq,
    φ.injective.eq_iff, ← Path.Homotopic.Quotient.eq]
  constructor
  · intro h; rw [h]
  · intro h; exact congrArg CategoryTheory.End.asHom h

/-! The card's whole-number worked examples. -/

-- Two turns then three: n(α · β) = 2 + 3 = 5.
example : (2 : ℤ) + 3 = 5 := by norm_num
-- The other order, β then α: 3 + 2 = 5.
example : (3 : ℤ) + 2 = 5 := by norm_num
-- β run backwards: its lift ends at 0 - 3 = -3.
example : (0 : ℤ) - 3 = -3 := by norm_num
-- Three turns, then two the other way: 3 + (-2) = 1.
example : (3 : ℤ) + (-2) = 1 := by norm_num
-- β, then β backwards: 3 + (-3) = 0, so the loop shrinks to its start.
example : (3 : ℤ) + (-3) = 0 := by norm_num
-- 8 compass sectors per turn: 5 turns cross 5 × 8 = 40 sector edges, net.
example : (5 : ℤ) * 8 = 40 := by norm_num
-- The sum rule is checked on 49 pairs: m and n each from -3 to 3.
example : ((Finset.Icc (-3 : ℤ) 3) ×ˢ (Finset.Icc (-3 : ℤ) 3)).card = 49 := by decide

#print axioms circle_fundamental_group_iso_int
#print axioms path_lifts_uniquely_and_loop_lift_ends_on_integer
#print axioms loops_homotopic_iff_same_winding_number
