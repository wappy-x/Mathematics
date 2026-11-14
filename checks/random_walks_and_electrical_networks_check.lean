-- Random walks as circuits: on every finite connected network of two-way links, the round-trip time of the random walk between two stations is twice the number of links times the effective resistance between them, the hitting times are the voltages of the circuit fed d(x) amps at every station, the round trip is at most 2m times the shortest route, and the card's six-station numbers check out exactly.
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.LinearAlgebra.FiniteDimensional.Basic

namespace RandomWalksAndElectricalNetworks

open SimpleGraph Finset

/-! ### The model

The stations are the vertices of a finite simple graph `G` (every lane two-way, no lane from a
station to itself); `m = #G.edgeFinset` is the number of lanes and `G.degree x` is `d(x)`.

* Hitting times. A rider at `x` takes one of the `d(x)` lanes with equal chances, and the choice
  depends only on where the bike is now. First-step analysis (the Absorption card) says the
  average trips to the target `b` are the function `h` with `h b = 0` and, at every other station,
  `h x = 1 + (average of h over the neighbours of x)`. `IsHittingTime G b h` says exactly this;
  `hitting_times_are_voltages` below shows it has exactly one solution on a connected network,
  so `h x` is `E_x[τ_b]`.
* Effective resistance. Every lane is a 1-ohm resistor, so the current from `x` to a neighbour
  `y` is `v x - v y`. `IsUnitCurrentPotential G a b v` is Kirchhoff's current law with 1 amp fed
  in at `a` and taken out at `b`; the voltage drop `v a - v b` is then `R_eff(a, b)`, the one
  resistor that passes the same current for the same drop. -/

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- First-step equations for the hitting times to `b`: zero at `b`, and one trip plus the
average over the `d(x)` equally likely next stations everywhere else. -/
def IsHittingTime (K : Type*) [Field K] (G : SimpleGraph V) [DecidableRel G.Adj] (b : V)
    (h : V → K) : Prop :=
  h b = 0 ∧ ∀ x, x ≠ b → h x = 1 + (∑ y ∈ G.neighborFinset x, h y) / (G.degree x : K)

/-- Kirchhoff's current law with every lane a 1-ohm resistor, 1 amp fed in at `a` and
1 amp taken out at `b`: at each station the current flowing out along the lanes equals the
current fed in there. -/
def IsUnitCurrentPotential (K : Type*) [Field K] (G : SimpleGraph V) [DecidableRel G.Adj]
    (a b : V) (v : V → K) : Prop :=
  ∀ x, ∑ y ∈ G.neighborFinset x, (v x - v y) = (if x = a then 1 else 0) - (if x = b then 1 else 0)

/-! ### Helper lemmas -/

/-- The currents out of all stations add up to zero. -/
theorem lap_sum_zero (G : SimpleGraph V) [DecidableRel G.Adj] (f : V → ℝ) :
    ∑ x, ∑ y ∈ G.neighborFinset x, (f x - f y) = 0 := by
  have h1 : ∑ x, ∑ y ∈ G.neighborFinset x, (f x - f y) =
      ∑ x, ∑ y, if G.Adj x y then f x - f y else 0 := by
    refine Finset.sum_congr rfl fun x _ => ?_
    rw [neighborFinset_eq_filter, Finset.sum_filter]
  have h2 : ∑ x, ∑ y, (if G.Adj x y then f x - f y else 0) =
      -∑ x, ∑ y, (if G.Adj x y then f x - f y else 0) := by
    conv_lhs => rw [Finset.sum_comm]
    rw [← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun x _ => ?_
    rw [← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun y _ => ?_
    by_cases hxy : G.Adj x y
    · simp [hxy, G.adj_symm hxy]
    · have hyx : ¬ G.Adj y x := fun h => hxy h.symm
      simp [hxy, hyx]
  rw [h1]; linarith

/-- If the equations hold away from `b` and the right-hand sides add up to zero, they hold at `b`. -/
theorem lap_at_of_sum (G : SimpleGraph V) [DecidableRel G.Adj] (f g : V → ℝ) (b : V)
    (hg : ∑ x, g x = 0) (hf : ∀ x, x ≠ b → ∑ y ∈ G.neighborFinset x, (f x - f y) = g x) :
    ∑ y ∈ G.neighborFinset b, (f b - f y) = g b := by
  have h0 := lap_sum_zero G f
  rw [← Finset.add_sum_erase _ _ (Finset.mem_univ b)] at h0 hg
  have : ∑ x ∈ Finset.univ.erase b, ∑ y ∈ G.neighborFinset x, (f x - f y) =
      ∑ x ∈ Finset.univ.erase b, g x :=
    Finset.sum_congr rfl fun x hx => hf x (Finset.ne_of_mem_erase hx)
  linarith

/-- Maximum principle: a function whose outflow is at most zero away from `b` is largest at `b`. -/
theorem max_principle (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) (b : V)
    (f : V → ℝ) (hf : ∀ x, x ≠ b → ∑ y ∈ G.neighborFinset x, (f x - f y) ≤ 0) :
    ∀ x, f x ≤ f b := by
  obtain ⟨x0, -, hx0⟩ := Finset.exists_max_image Finset.univ f ⟨b, Finset.mem_univ b⟩
  have hM : ∀ x, f x ≤ f x0 := fun x => hx0 x (Finset.mem_univ x)
  have step : ∀ u w, G.Adj u w → u ≠ b → f u = f x0 → f w = f x0 := by
    intro u w huw hub hu
    have hnn : ∀ y ∈ G.neighborFinset u, 0 ≤ f u - f y := fun y _ => by
      have := hM y; linarith
    have hle : f u - f w ≤ ∑ y ∈ G.neighborFinset u, (f u - f y) :=
      Finset.single_le_sum hnn ((G.mem_neighborFinset u w).2 huw)
    have := hf u hub
    have := hM w
    linarith
  have key : ∀ u v (p : G.Walk u v), v = b → f u = f x0 → f b = f x0 := by
    intro u v p
    induction p with
    | nil => intro hv hu; rw [← hv]; exact hu
    | @cons u w _ huw p ih =>
      intro hv hu
      by_cases hub : u = b
      · rw [← hub]; exact hu
      · exact ih hv (step u w huw hub hu)
  intro x
  obtain ⟨p⟩ := hG.preconnected x0 b
  rw [key x0 b p rfl rfl]
  exact hM x

/-- A function with zero outflow everywhere is constant. -/
theorem const_of_lap_zero (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) (b : V)
    (f : V → ℝ) (hf : ∀ x, ∑ y ∈ G.neighborFinset x, (f x - f y) = 0) : ∀ x, f x = f b := by
  intro x
  have h1 := max_principle G hG b f (fun x _ => (hf x).le) x
  have h2 : -f x ≤ -f b := max_principle G hG b (fun z => -f z) (fun x _ => by
    have : ∑ y ∈ G.neighborFinset x, (-f x - -f y) = -∑ y ∈ G.neighborFinset x, (f x - f y) := by
      rw [← Finset.sum_neg_distrib]
      exact Finset.sum_congr rfl fun y _ => by ring
    simp only [this, hf x, neg_zero, le_refl]) x
  linarith

/-- In a connected network every station other than `b` has a lane. -/
theorem degree_pos_of_ne (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) {x b : V}
    (hx : x ≠ b) : 0 < G.degree x := by
  obtain ⟨p⟩ := hG.preconnected x b
  cases p with
  | nil => exact absurd rfl hx
  | cons h _ => exact (G.degree_pos_iff_exists_adj x).2 ⟨_, h⟩

/-- The outflow written as `d(x) f(x)` minus the sum over the neighbours. -/
theorem lap_eq (G : SimpleGraph V) [DecidableRel G.Adj] (f : V → ℝ) (x : V) :
    ∑ y ∈ G.neighborFinset x, (f x - f y) =
      (G.degree x : ℝ) * f x - ∑ y ∈ G.neighborFinset x, f y := by
  rw [Finset.sum_sub_distrib, Finset.sum_const, card_neighborFinset_eq_degree, nsmul_eq_mul]

/-- The first-step equations rewritten as a circuit: `d(x)` amps in everywhere, `2m` out at `b`. -/
theorem lap_of_hitting (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) (b : V)
    (h : V → ℝ) (hh : IsHittingTime ℝ G b h) :
    ∀ x, ∑ y ∈ G.neighborFinset x, (h x - h y) =
      (G.degree x : ℝ) - if x = b then 2 * (#G.edgeFinset : ℝ) else 0 := by
  have off : ∀ x, x ≠ b → ∑ y ∈ G.neighborFinset x, (h x - h y) =
      (G.degree x : ℝ) - if x = b then 2 * (#G.edgeFinset : ℝ) else 0 := by
    intro x hx
    have hd : (G.degree x : ℝ) ≠ 0 := by
      have := degree_pos_of_ne G hG hx; positivity
    rw [lap_eq, if_neg hx, hh.2 x hx]
    field_simp
    ring
  intro x
  by_cases hx : x = b
  · subst hx
    refine lap_at_of_sum G h _ x ?_ off
    rw [Finset.sum_sub_distrib, Finset.sum_ite_eq' Finset.univ x, if_pos (Finset.mem_univ x)]
    have := G.sum_degrees_eq_twice_card_edges
    have h2 : (∑ v, (G.degree v : ℝ)) = 2 * (#G.edgeFinset : ℝ) := by exact_mod_cast this
    linarith
  · exact off x hx

/-- The first-step equations have at most one solution. -/
theorem hitting_unique (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) (b : V)
    (h₁ h₂ : V → ℝ) (hh₁ : IsHittingTime ℝ G b h₁) (hh₂ : IsHittingTime ℝ G b h₂) : h₁ = h₂ := by
  have l1 := lap_of_hitting G hG b h₁ hh₁
  have l2 := lap_of_hitting G hG b h₂ hh₂
  have hc := const_of_lap_zero G hG b (fun z => h₁ z - h₂ z) (fun x => by
    have : ∑ y ∈ G.neighborFinset x, ((h₁ x - h₂ x) - (h₁ y - h₂ y)) =
        ∑ y ∈ G.neighborFinset x, (h₁ x - h₁ y) - ∑ y ∈ G.neighborFinset x, (h₂ x - h₂ y) := by
      rw [← Finset.sum_sub_distrib]
      exact Finset.sum_congr rfl fun y _ => by ring
    simp only [this, l1 x, l2 x, sub_self])
  funext x
  have := hc x
  simp only [hh₁.1, hh₂.1, sub_self] at this
  linarith

/-- The circuit equations can be solved for any currents away from `b` and any voltage at `b`. -/
theorem exists_solution (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) (b : V)
    (g : V → ℝ) : ∃ f : V → ℝ, f b = g b ∧
      ∀ x, x ≠ b → ∑ y ∈ G.neighborFinset x, (f x - f y) = g x := by
  let L : (V → ℝ) →ₗ[ℝ] (V → ℝ) :=
    { toFun := fun f x => if x = b then f b else ∑ y ∈ G.neighborFinset x, (f x - f y)
      map_add' := by
        intro f₁ f₂; funext x
        simp only [Pi.add_apply]
        split_ifs
        · rfl
        · rw [← Finset.sum_add_distrib]
          exact Finset.sum_congr rfl fun y _ => by ring
      map_smul' := by
        intro c f; funext x
        simp only [Pi.smul_apply, smul_eq_mul, RingHom.id_apply]
        split_ifs
        · rfl
        · rw [Finset.mul_sum]
          exact Finset.sum_congr rfl fun y _ => by ring }
  have hinj : Function.Injective L := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro f hf
    have hfx : ∀ x, (if x = b then f b else ∑ y ∈ G.neighborFinset x, (f x - f y)) = 0 :=
      fun x => congrFun hf x
    have hb : f b = 0 := by simpa using hfx b
    have hlap : ∀ x, x ≠ b → ∑ y ∈ G.neighborFinset x, (f x - f y) = 0 := fun x hx => by
      simpa [hx] using hfx x
    have hall : ∀ x, ∑ y ∈ G.neighborFinset x, (f x - f y) = 0 := by
      intro x
      by_cases hx : x = b
      · subst hx
        exact lap_at_of_sum G f (fun _ => 0) x (by simp) hlap
      · exact hlap x hx
    funext x
    have := const_of_lap_zero G hG b f hall x
    simp [this, hb]
  obtain ⟨f, hf⟩ := (LinearMap.injective_iff_surjective.mp hinj) g
  refine ⟨f, ?_, ?_⟩
  · have := congrFun hf b
    simpa [L] using this
  · intro x hx
    have := congrFun hf x
    simpa [L, hx] using this

/-- Comparing hitting times: going to `c` from `x` takes at most the trip to `b` plus `b` to `c`. -/
theorem hitting_triangle (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) (b c : V)
    (hb hc : V → ℝ) (hhb : IsHittingTime ℝ G b hb) (hhc : IsHittingTime ℝ G c hc) :
    ∀ x, hc x - hb x ≤ hc b := by
  have lb := lap_of_hitting G hG b hb hhb
  have lc := lap_of_hitting G hG c hc hhc
  have hm := max_principle G hG b (fun z => hc z - hb z) (fun x hx => by
    have e : ∑ y ∈ G.neighborFinset x, ((hc x - hb x) - (hc y - hb y)) =
        ∑ y ∈ G.neighborFinset x, (hc x - hc y) - ∑ y ∈ G.neighborFinset x, (hb x - hb y) := by
      rw [← Finset.sum_sub_distrib]
      exact Finset.sum_congr rfl fun y _ => by ring
    simp only [e, lc x, lb x, if_neg hx]
    have : (0 : ℝ) ≤ 2 * (#G.edgeFinset : ℝ) := by positivity
    split_ifs <;> linarith)
  intro x
  have h := hm x
  simp only [hhb.1, sub_zero] at h
  exact h

/-- The card's main result, the commute-time identity. On a connected network of two-way
lanes, each a 1-ohm resistor, a circuit carrying 1 amp from `a` to `b` exists, and for the
walk that picks among the lanes at each station with equal chances, the hitting time from `a`
to `b` plus the hitting time from `b` to `a` equals `2 m R_eff(a, b)`, where `m` is the number
of lanes and `R_eff(a, b)` is the voltage drop `v a - v b` of that circuit. -/
theorem commute_time_eq_two_mul_card_edges_mul_effective_resistance
    (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected) (a b : V) :
    (∃ v : V → ℝ, IsUnitCurrentPotential ℝ G a b v) ∧
      ∀ (hb ha v : V → ℝ), IsHittingTime ℝ G b hb → IsHittingTime ℝ G a ha →
        IsUnitCurrentPotential ℝ G a b v →
          hb a + ha b = 2 * (#G.edgeFinset : ℝ) * (v a - v b) := by
  have hv : ∃ v : V → ℝ, IsUnitCurrentPotential ℝ G a b v := by
    obtain ⟨v, -, hv⟩ := exists_solution G hG b
      (fun x => (if x = a then 1 else 0) - (if x = b then 1 else 0))
    refine ⟨v, fun x => ?_⟩
    have hsum : ∑ x, ((if x = a then (1 : ℝ) else 0) - (if x = b then 1 else 0)) = 0 := by
      simp [Finset.sum_sub_distrib]
    by_cases hx : x = b
    · subst hx; exact lap_at_of_sum G v _ x hsum hv
    · exact hv x hx
  refine ⟨hv, fun hb ha v hhb hha hvv => ?_⟩
  have lb := lap_of_hitting G hG b hb hhb
  have la := lap_of_hitting G hG a ha hha
  have hc := const_of_lap_zero G hG b
    (fun z => hb z - ha z - 2 * (#G.edgeFinset : ℝ) * v z) (fun x => by
      have e : ∑ y ∈ G.neighborFinset x, ((hb x - ha x - 2 * (#G.edgeFinset : ℝ) * v x) -
          (hb y - ha y - 2 * (#G.edgeFinset : ℝ) * v y)) =
          ∑ y ∈ G.neighborFinset x, (hb x - hb y) - ∑ y ∈ G.neighborFinset x, (ha x - ha y) -
            2 * (#G.edgeFinset : ℝ) * ∑ y ∈ G.neighborFinset x, (v x - v y) := by
        rw [Finset.mul_sum, ← Finset.sum_sub_distrib, ← Finset.sum_sub_distrib]
        exact Finset.sum_congr rfl fun y _ => by ring
      rw [e, lb x, la x, hvv x]
      split_ifs <;> ring) a
  simp only [hhb.1, hha.1] at hc
  linarith

/-- Hitting times are voltages. On a connected network the first-step equations for the target
`b` have exactly one solution, and it is the voltage of the circuit that feeds `d(x)` amps into
every station `x`, grounds `b` at 0 volts and lets all `2m` amps leave at `b`. -/
theorem hitting_times_are_voltages (G : SimpleGraph V) [DecidableRel G.Adj] (hG : G.Connected)
    (b : V) :
    ∃! h : V → ℝ, IsHittingTime ℝ G b h ∧
      ∀ x, ∑ y ∈ G.neighborFinset x, (h x - h y) =
        (G.degree x : ℝ) - if x = b then 2 * (#G.edgeFinset : ℝ) else 0 := by
  obtain ⟨f, hfb, hf⟩ := exists_solution G hG b (fun x => if x = b then 0 else (G.degree x : ℝ))
  have hfh : IsHittingTime ℝ G b f := by
    refine ⟨by simpa using hfb, fun x hx => ?_⟩
    have e := hf x hx
    simp only [hx, if_false] at e
    rw [lap_eq] at e
    have hd : (G.degree x : ℝ) ≠ 0 := by
      have := degree_pos_of_ne G hG hx; positivity
    field_simp
    linarith
  exact ⟨f, ⟨hfh, lap_of_hitting G hG b f hfh⟩, fun h hh => hitting_unique G hG b h f hh.1 hfh⟩

/-- The shortest-route bound. Since the resistance is at most the length of the shortest route,
the round trip between `a` and `b` is at most `2m` times the number of lanes on a shortest
route from `a` to `b`. -/
theorem commute_time_le_two_mul_card_edges_mul_dist (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : G.Connected) (a b : V) (hb ha : V → ℝ) (hhb : IsHittingTime ℝ G b hb)
    (hha : IsHittingTime ℝ G a ha) :
    hb a + ha b ≤ 2 * (#G.edgeFinset : ℝ) * (G.dist a b : ℝ) := by
  choose H hH using fun c => (hitting_times_are_voltages G hG c).exists
  have hHt : ∀ c, IsHittingTime ℝ G c (H c) := fun c => (hH c).1
  have hm : (0 : ℝ) ≤ 2 * (#G.edgeFinset : ℝ) := by positivity
  have edge : ∀ u w, G.Adj u w → H w u + H u w ≤ 2 * (#G.edgeFinset : ℝ) := by
    intro u w huw
    obtain ⟨⟨v, hv⟩, hid⟩ :=
      commute_time_eq_two_mul_card_edges_mul_effective_resistance G hG u w
    rw [hid (H w) (H u) v (hHt w) (hHt u) hv]
    have hne : u ≠ w := G.ne_of_adj huw
    have hmax := max_principle G hG u v (fun x hx => by
      rw [hv x]; simp only [hx, if_false]; split_ifs <;> norm_num)
    have hu : ∑ y ∈ G.neighborFinset u, (v u - v y) = 1 := by rw [hv u]; simp [hne]
    have hle : v u - v w ≤ ∑ y ∈ G.neighborFinset u, (v u - v y) :=
      Finset.single_le_sum (f := fun y => v u - v y) (fun y _ => by have := hmax y; linarith)
        ((G.mem_neighborFinset u w).2 huw)
    calc 2 * (#G.edgeFinset : ℝ) * (v u - v w) ≤ 2 * (#G.edgeFinset : ℝ) * 1 :=
          mul_le_mul_of_nonneg_left (by linarith) hm
      _ = 2 * (#G.edgeFinset : ℝ) := mul_one _
  have walk : ∀ u w (p : G.Walk u w),
      H w u + H u w ≤ 2 * (#G.edgeFinset : ℝ) * (p.length : ℝ) := by
    intro u w p
    induction p with
    | nil => simp [(hHt _).1]
    | @cons u x w hux p ih =>
      have t1 := hitting_triangle G hG x w (H x) (H w) (hHt x) (hHt w) u
      have t2 := hitting_triangle G hG x u (H x) (H u) (hHt x) (hHt u) w
      have e := edge u x hux
      rw [Walk.length_cons, Nat.cast_succ]
      linarith
  obtain ⟨p, hp⟩ := hG.exists_walk_length_eq_dist a b
  rw [hitting_unique G hG b hb (H b) hhb (hHt b), hitting_unique G hG a ha (H a) hha (hHt a), ← hp]
  exact walk a b p

/-! ### The card's bike-share network

Market 0, Park 1, Library 2, Hospital 3, University 4, Docks 5; seven two-way lanes. -/

/-- The seven lanes. -/
def bikeLinks : List (Fin 6 × Fin 6) := [(0, 1), (1, 5), (0, 2), (2, 3), (3, 5), (1, 4), (4, 5)]

/-- The six stations as a simple graph. -/
def bikeNet : SimpleGraph (Fin 6) where
  Adj x y := (x, y) ∈ bikeLinks ∨ (y, x) ∈ bikeLinks
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel bikeNet.Adj := fun _ _ => inferInstanceAs (Decidable (_ ∨ _))

-- Seven links; degrees Market 2, Park 3, Library 2, Hospital 2, University 2, Docks 3.
example : #bikeNet.edgeFinset = 7 := by decide
example : (List.finRange 6).map (fun x => bikeNet.degree x) = [2, 3, 2, 2, 2, 3] := by decide

-- Hitting times to Docks: Market 6, Park 4, Library 6, Hospital 4, University 3, Docks 0.
example : IsHittingTime ℚ bikeNet 5 (![6, 4, 6, 4, 3, 0] : Fin 6 → ℚ) := by
  have hd : ∀ x, bikeNet.degree x = ![2, 3, 2, 2, 2, 3] x := by decide
  refine ⟨rfl, fun x hx => ?_⟩
  rw [hd, neighborFinset_eq_filter, Finset.sum_filter, Fin.sum_univ_six]
  fin_cases x <;> simp [bikeNet, bikeLinks] at hx ⊢ <;> norm_num
-- Hitting times to Market: Market 0, Park 7, Library 5, Hospital 8, University 9, Docks 9.
example : IsHittingTime ℚ bikeNet 0 (![0, 7, 5, 8, 9, 9] : Fin 6 → ℚ) := by
  have hd : ∀ x, bikeNet.degree x = ![2, 3, 2, 2, 2, 3] x := by decide
  refine ⟨rfl, fun x hx => ?_⟩
  rw [hd, neighborFinset_eq_filter, Finset.sum_filter, Fin.sum_univ_six]
  fin_cases x <;> simp [bikeNet, bikeLinks] at hx ⊢ <;> norm_num
-- 1 amp from Market to Docks: voltages 15/14, 6/14, 10/14, 5/14, 3/14, 0, so R_eff = 15/14 ohm.
example : IsUnitCurrentPotential ℚ bikeNet 0 5
    (![15/14, 6/14, 10/14, 5/14, 3/14, 0] : Fin 6 → ℚ) := by
  intro x
  rw [neighborFinset_eq_filter, Finset.sum_filter, Fin.sum_univ_six]
  fin_cases x <;> simp [bikeNet, bikeLinks] <;> norm_num

-- Series and parallel by hand: Park to Docks 2/3, plus Market-Park 5/3, lower side 3, total 15/14.
example : (1 * 2 : ℚ) / (1 + 2) = 2 / 3 := by norm_num
example : ((5 / 3) * 3 : ℚ) / (5 / 3 + 3) = 15 / 14 := by norm_num
-- Commute time 2 × 7 × 15/14 = 15 trips; the legs 1 + (4 + 6)/2 = 6 and 1 + (7 + 8 + 9)/3 = 9.
example : 2 * 7 * (15 / 14 : ℚ) = 15 := by norm_num
example : 1 + (4 + 6) / 2 = (6 : ℚ) ∧ 1 + (7 + 8 + 9) / 3 = (9 : ℚ) ∧ (6 + 9 : ℚ) = 15 := by norm_num
-- The wrong answers: 2 n R = 90/7, m R = 15/2, the shortest route 2 × 7 × 2 = 28.
example : 2 * 6 * (15 / 14 : ℚ) = 90 / 7 ∧ 7 * (15 / 14 : ℚ) = 15 / 2 ∧ 2 * 7 * 2 = 28 := by
  norm_num
-- A dead-end station off Park: R_eff stays 15/14, m becomes 8, round trip 120/7 (about 17.14).
example : 2 * 8 * (15 / 14 : ℚ) = 120 / 7 := by norm_num

#print axioms lap_sum_zero
#print axioms lap_at_of_sum
#print axioms max_principle
#print axioms const_of_lap_zero
#print axioms degree_pos_of_ne
#print axioms lap_eq
#print axioms lap_of_hitting
#print axioms hitting_unique
#print axioms exists_solution
#print axioms hitting_triangle
#print axioms commute_time_eq_two_mul_card_edges_mul_effective_resistance
#print axioms hitting_times_are_voltages
#print axioms commute_time_le_two_mul_card_edges_mul_dist

end RandomWalksAndElectricalNetworks
