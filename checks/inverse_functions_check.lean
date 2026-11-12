-- Inverse functions: a function has a two-sided inverse exactly when it is a bijection, that inverse is unique, and a composite is undone in reverse order.
import Mathlib.Logic.Function.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Int.Interval
import Mathlib.Algebra.Field.Rat
import Mathlib.Tactic.NormNum

open Function

/-- A function can be undone, meaning some rule sends every output back to its input and
both round trips are the identity, exactly when the function is a bijection: no two inputs
share an output and every output is reached. -/
theorem has_inverse_iff_bijective {α β : Type*} (f : α → β) :
    (∃ g : β → α, LeftInverse g f ∧ RightInverse g f) ↔ Bijective f := by
  constructor
  · rintro ⟨g, hl, hr⟩
    exact ⟨hl.injective, hr.surjective⟩
  · intro hf
    refine ⟨Function.surjInv hf.2, ?_, ?_⟩
    · exact Function.leftInverse_surjInv hf
    · exact Function.rightInverse_surjInv hf.2

/-- Only one rule undoes a function: two rules that each undo f both ways round are the same rule. -/
theorem inverse_unique {α β : Type*} (f : α → β) (g₁ g₂ : β → α)
    (h₁ : LeftInverse g₁ f ∧ RightInverse g₁ f) (h₂ : LeftInverse g₂ f ∧ RightInverse g₂ f) :
    g₁ = g₂ := by
  funext b
  have := h₁.2 b
  calc g₁ b = g₁ (f (g₂ b)) := by rw [h₂.2 b]
    _ = g₂ b := h₁.1 (g₂ b)

/-- Undo the jobs in reverse order: if g undoes f and k undoes h, then doing f then h is
undone by undoing h first, then f. -/
theorem inverse_of_comp_reverse_order {α β γ : Type*} (f : α → β) (g : β → α) (h : β → γ)
    (k : γ → β) (hf : LeftInverse g f ∧ RightInverse g f) (hh : LeftInverse k h ∧ RightInverse k h) :
    LeftInverse (g ∘ k) (h ∘ f) ∧ RightInverse (g ∘ k) (h ∘ f) := by
  refine ⟨?_, ?_⟩
  · intro a
    simp only [Function.comp]
    rw [hh.1 (f a)]
    exact hf.1 a
  · intro c
    simp only [Function.comp]
    rw [hf.2 (k c)]
    exact hh.2 c

/-- The 24-hour clock read on a 12-hour dial. -/
def dial (h : ℕ) : ℕ := if h % 12 = 0 then 12 else h % 12

-- Temperatures, with 1.8 written exactly as 9/5: 20 °C goes out to 68 °F.
example : (9 / 5 : ℚ) * 20 + 32 = 68 := by norm_num
-- The way back: 68 − 32 = 36, and 36 ÷ 9/5 = 20.
example : (68 : ℚ) - 32 = 36 := by norm_num
example : ((68 : ℚ) - 32) / (9 / 5) = 20 := by norm_num
-- Four temperatures out and back: −40, 0, 20, 100 °C go to −40, 32, 68, 212 °F and all come home.
example : ([-40, 0, 20, 100] : List ℚ).map (fun c => (9 / 5) * c + 32) = [-40, 32, 68, 212] := by
  norm_num
example : ([-40, 32, 68, 212] : List ℚ).map (fun f => (f - 32) / (9 / 5)) = [-40, 0, 20, 100] := by
  norm_num
-- At −40 the scales agree.
example : (9 / 5 : ℚ) * (-40) + 32 = -40 := by norm_num
-- Undone in the wrong order, 68 ÷ 9/5 − 32 is not 20.
example : (68 : ℚ) / (9 / 5) - 32 ≠ 20 := by norm_num
-- Whole degrees −50 to 100: only 20 °C gives 68 °F (9/5 × C + 32 = 68, times 5 to stay in whole numbers).
example : ((Finset.Icc (-50 : ℤ) 100).filter (fun c => 9 * c + 160 = 5 * 68)) = {20} := by decide
-- The clock: hours 01:00 and 13:00 both read 1.
example : (Finset.range 24).filter (fun h => dial h = 1) = {1, 13} := by decide
-- All 12 readings are reached, so the clock is onto, and each has 2 hours behind it.
example : (Finset.range 24).image dial = Finset.Icc 1 12 := by decide
example : ∀ d ∈ Finset.Icc 1 12, ((Finset.range 24).filter (fun h => dial h = d)).card = 2 := by decide
-- Cut to the morning, 00:00 to 11:00: one hour lands on each reading.
example : (Finset.range 12).filter (fun h => dial h = 1) = {1} := by decide
example : ∀ d ∈ Finset.Icc 1 12, ((Finset.range 12).filter (fun h => dial h = d)).card = 1 := by decide

#print axioms has_inverse_iff_bijective
#print axioms inverse_unique
#print axioms inverse_of_comp_reverse_order
