(** Formal Reasoning About Programs <http://adam.chlipala.net/frap/>
  * Chapter 5: Model Checking
  * Author: Adam Chlipala
  * License: https://creativecommons.org/licenses/by-nc-nd/4.0/ *)

Require Import Frap TransitionSystems.

Set Implicit Arguments.


Definition oneStepClosure_current {state} (sys : trsys state)
           (invariant1 invariant2 : state -> Prop) :=
  forall st, invariant1 st
             -> invariant2 st.

Definition oneStepClosure_new {state} (sys : trsys state)
           (invariant1 invariant2 : state -> Prop) :=
  forall st st', invariant1 st
                 -> sys.(Step) st st'
                 -> invariant2 st'.

Definition oneStepClosure {state} (sys : trsys state)
           (invariant1 invariant2 : state -> Prop) :=
  oneStepClosure_current sys invariant1 invariant2
  /\ oneStepClosure_new sys invariant1 invariant2.

Theorem prove_oneStepClosure : forall state (sys : trsys state) (inv1 inv2 : state -> Prop),
  (forall st, inv1 st -> inv2 st)
  -> (forall st st', inv1 st -> sys.(Step) st st' -> inv2 st')
  -> oneStepClosure sys inv1 inv2.
Proof.
  unfold oneStepClosure.
  propositional.
Qed.

Theorem oneStepClosure_done : forall state (sys : trsys state) (invariant : state -> Prop),
  (forall st, sys.(Initial) st -> invariant st)
  -> oneStepClosure sys invariant invariant
  -> invariantFor sys invariant.
Proof.
  unfold oneStepClosure, oneStepClosure_current, oneStepClosure_new.
  propositional.
  apply invariant_induction.
  assumption.
  simplify.
  eapply H2.
  eassumption.
  assumption.
Qed.

Inductive multiStepClosure {state} (sys : trsys state)
  : (state -> Prop) -> (state -> Prop) -> Prop :=
| MscDone : forall inv,
    oneStepClosure sys inv inv
    -> multiStepClosure sys inv inv
| MscStep : forall inv inv' inv'',
    oneStepClosure sys inv inv'
    -> multiStepClosure sys inv' inv''
    -> multiStepClosure sys inv inv''.

Lemma multiStepClosure_ok' : forall state (sys : trsys state) (inv inv' : state -> Prop),
  multiStepClosure sys inv inv'
  -> (forall st, sys.(Initial) st -> inv st)
  -> invariantFor sys inv'.
Proof.
  induct 1; simplify.

  apply oneStepClosure_done.
  assumption.
  assumption.

  apply IHmultiStepClosure.
  simplify.
  unfold oneStepClosure, oneStepClosure_current in *. (* <-- *)
  propositional.
  apply H3.
  apply H1.
  assumption.
Qed.

Theorem multiStepClosure_ok : forall state (sys : trsys state) (inv : state -> Prop),
  multiStepClosure sys sys.(Initial) inv
  -> invariantFor sys inv.
Proof.
  simplify.
  eapply multiStepClosure_ok'.
  eassumption.
  propositional.
Qed.

Theorem oneStepClosure_empty : forall state (sys : trsys state),
  oneStepClosure sys (constant nil) (constant nil).
Proof.
  unfold oneStepClosure, oneStepClosure_current, oneStepClosure_new; propositional.
Qed.

Theorem oneStepClosure_split : forall state (sys : trsys state) st sts (inv1 inv2 : state -> Prop),
  (forall st', sys.(Step) st st' -> inv1 st')
  -> oneStepClosure sys (constant sts) inv2
  -> oneStepClosure sys (constant (st :: sts)) ({st} \cup inv1 \cup inv2).
Proof.
  unfold oneStepClosure, oneStepClosure_current, oneStepClosure_new; propositional.

  invert H0.

  left.
  left.
  simplify.
  propositional.

  right.
  apply H1.
  assumption.

  simplify.
  propositional.
  
  left.
  right.
  apply H.
  equality.

  right.
  eapply H2.
  eassumption.
  assumption.
Qed.

Definition fact_correct (original_input : nat) (st : fact_state) : Prop :=
  match st with
  | AnswerIs ans => fact original_input = ans
  | WithAccumulator _ _ => True
  end.

Theorem fact_init_is : forall original_input,
  fact_init original_input = {WithAccumulator original_input 1}.
Proof.
  simplify.
  apply sets_equal; simplify.
  propositional.

  invert H.
  equality.

  rewrite <- H0.
  constructor.
Qed.

Theorem singleton_in : forall {A} (x : A) rest,
  ({x} \cup rest) x.
Proof.
  simplify.
  left.
  simplify.
  equality.
Qed.

Theorem singleton_in_other : forall {A} (x : A) (s1 s2 : set A),
  s2 x
  -> (s1 \cup s2) x.
Proof.
  simplify.
  right.
  assumption.
Qed.

Theorem factorial_ok_2 :
  invariantFor (factorial_sys 2) (fact_correct 2).
Proof.
  simplify.
  eapply invariant_weaken.

  apply multiStepClosure_ok.
  simplify.
  rewrite fact_init_is.

  eapply MscStep.
  apply oneStepClosure_split; simplify.
  invert H; simplify.
  apply singleton_in.
  apply oneStepClosure_empty.
  simplify.

  eapply MscStep.
  apply oneStepClosure_split; simplify.
  invert H; simplify.
  apply singleton_in.
  apply oneStepClosure_split; simplify.
  invert H; simplify.
  apply singleton_in.
  apply oneStepClosure_empty.
  simplify.

  eapply MscStep.
  apply oneStepClosure_split; simplify.
  invert H; simplify.
  apply singleton_in.
  apply oneStepClosure_split; simplify.
  invert H; simplify.
  apply singleton_in.
  apply oneStepClosure_split; simplify.
  invert H; simplify.
  apply singleton_in.
  apply oneStepClosure_empty.
  simplify.

  apply MscDone.
  apply prove_oneStepClosure; simplify.
  propositional.
  propositional; invert H0; try equality.
  invert H; equality.
  invert H1; equality.

  simplify.
  propositional; subst; simplify; propositional.
              (* ^-- *)
Qed.

Hint Rewrite fact_init_is.

Ltac model_check_done :=
  apply MscDone; apply prove_oneStepClosure; simplify; propositional; subst;
  repeat match goal with
         | [ H : _ |- _ ] => invert H
         end; simplify; equality.

Ltac singletoner :=
  repeat match goal with
         | _ => apply singleton_in
         | [ |- (_ \cup _) _ ] => apply singleton_in_other
         end.

Ltac model_check_step :=
  eapply MscStep; [
    repeat ((apply oneStepClosure_empty; simplify)
            || (apply oneStepClosure_split; [ simplify;
                                              repeat match goal with
                                                     | [ H : _ |- _ ] => invert H; try congruence
                                                     end; solve [ singletoner ] | ]))
  | simplify ].

Ltac model_check_steps1 := model_check_done || model_check_step.
Ltac model_check_steps := repeat model_check_steps1.

Ltac model_check_finish := simplify; propositional; subst; simplify; equality.

Ltac model_check_infer :=
  apply multiStepClosure_ok; simplify; model_check_steps.

Ltac model_check_find_invariant :=
  simplify; eapply invariant_weaken; [ model_check_infer | ].

Ltac model_check := model_check_find_invariant; model_check_finish.

Theorem factorial_ok_2_snazzy :
  invariantFor (factorial_sys 2) (fact_correct 2).
Proof.
  model_check.
Qed.

Theorem factorial_ok_3 :
  invariantFor (factorial_sys 3) (fact_correct 3).
Proof.
  model_check.
Qed.

Theorem factorial_ok_5 :
  invariantFor (factorial_sys 5) (fact_correct 5).
Proof.
  model_check.
Qed.


(** * Abstraction *)

(*

int global = 0;

thread() {
  int local;

  while (true) {
    local = global;
    global = local + 2;
  }
}
*)

Inductive isEven : nat -> Prop :=
| EvenO : isEven 0
| EvenSS : forall n, isEven n -> isEven (S (S n)).

Inductive add2_thread :=
| Read
| Write (local : nat).

Inductive add2_init : threaded_state nat add2_thread -> Prop :=
| Add2Init : add2_init {| Shared := 0; Private := Read |}.

Inductive add2_step : threaded_state nat add2_thread -> threaded_state nat add2_thread -> Prop :=
| StepRead : forall global,
    add2_step {| Shared := global; Private := Read |}
              {| Shared := global; Private := Write global |}
| StepWrite : forall global local,
    add2_step {| Shared := global; Private := Write local |}
              {| Shared := S (S local); Private := Read |}.

Definition add2_sys1 := {|
  Initial := add2_init;
  Step := add2_step
|}.

Definition add2_sys := parallel add2_sys1 add2_sys1.

Inductive simulates state1 state2 (R : state1 -> state2 -> Prop)
  (sys1 : trsys state1) (sys2 : trsys state2) : Prop :=
| Simulates :
  (forall st1, sys1.(Initial) st1
               -> exists st2, R st1 st2
                              /\ sys2.(Initial) st2)
  -> (forall st1 st2, R st1 st2
                      -> forall st1', sys1.(Step) st1 st1'
                                      -> exists st2', R st1' st2'
                                                      /\ sys2.(Step) st2 st2')
  -> simulates R sys1 sys2.

Inductive invariantViaSimulation state1 state2 (R : state1 -> state2 -> Prop)
  (inv2 : state2 -> Prop)
  : state1 -> Prop :=
| InvariantViaSimulation : forall st1 st2, R st1 st2
  -> inv2 st2
  -> invariantViaSimulation R inv2 st1.

Lemma invariant_simulates' : forall state1 state2 (R : state1 -> state2 -> Prop)
  (sys1 : trsys state1) (sys2 : trsys state2),
  (forall st1 st2, R st1 st2
                   -> forall st1', sys1.(Step) st1 st1'
                                   ->  exists st2', R st1' st2'
                                                    /\ sys2.(Step) st2 st2')
  -> forall st1 st1', sys1.(Step)^* st1 st1'
                      -> forall st2, R st1 st2
                                     -> exists st2', R st1' st2'
                                                     /\ sys2.(Step)^* st2 st2'.
Proof.
  induct 2.

  simplify.
  exists st2.
  propositional.
  constructor.

  simplify.
  eapply H in H2.
  first_order.
  apply IHtrc in H2.
  first_order.
  exists x1.
  propositional.
  econstructor.
  eassumption.
  assumption.
  assumption.
Qed.

Theorem invariant_simulates : forall state1 state2 (R : state1 -> state2 -> Prop)
  (sys1 : trsys state1) (sys2 : trsys state2) (inv2 : state2 -> Prop),
  simulates R sys1 sys2
  -> invariantFor sys2 inv2
  -> invariantFor sys1 (invariantViaSimulation R inv2).
Proof.
  simplify.
  invert H.
  unfold invariantFor; simplify.
  apply H1 in H.
  first_order.
  apply invariant_simulates' with (sys2 := sys2) (R := R) (st2 := x) in H3; try assumption.
  first_order.
  unfold invariantFor in H0.
  apply H0 with (s' := x0) in H4; try assumption.
  econstructor.
  eassumption.
  assumption.
Qed.

(* Abstracted program:

bool global = true;

thread() {
  bool local;

  while (true) {
    local = global;
    global = local;
  }
}
*)

Inductive add2_bthread :=
| BRead
| BWrite (local : bool).

Inductive add2_binit : threaded_state bool add2_bthread -> Prop :=
| Add2BInit : add2_binit {| Shared := true; Private := BRead |}.

Inductive add2_bstep : threaded_state bool add2_bthread -> threaded_state bool add2_bthread -> Prop :=
| StepBRead : forall global,
    add2_bstep {| Shared := global; Private := BRead |}
               {| Shared := global; Private := BWrite global |}
| StepBWrite : forall global local,
    add2_bstep {| Shared := global; Private := BWrite local |}
               {| Shared := local; Private := BRead |}.

Definition add2_bsys1 := {|
  Initial := add2_binit;
  Step := add2_bstep
|}.

Definition add2_bsys := parallel add2_bsys1 add2_bsys1.

Definition add2_correct (st : threaded_state nat (add2_thread * add2_thread)) :=
  isEven st.(Shared).

Inductive R_private1 : add2_thread -> add2_bthread -> Prop :=
| RpRead : R_private1 Read BRead
| RpWrite : forall n b, (b = true <-> isEven n)
                        -> R_private1 (Write n) (BWrite b).

Inductive add2_R : threaded_state nat (add2_thread * add2_thread)
                   -> threaded_state bool (add2_bthread * add2_bthread)
                   -> Prop :=
| Add2_R : forall n b th1 th2 th1' th2',
  (b = true <-> isEven n)
  -> R_private1 th1 th1'
  -> R_private1 th2 th2'
  -> add2_R {| Shared := n; Private := (th1, th2) |}
            {| Shared := b; Private := (th1', th2') |}.

Theorem add2_init_is :
  parallel1 add2_binit add2_binit = { {| Shared := true; Private := (BRead, BRead) |} }.
Proof.
  simplify.
  apply sets_equal; simplify.
  propositional.

  invert H.
  invert H2.
  invert H4.
  equality.

  invert H0.
  constructor.
  constructor.
  constructor.
Qed.

Hint Rewrite add2_init_is.

Theorem add2_ok :
  invariantFor add2_sys add2_correct.
Proof.
  eapply invariant_weaken with (invariant1 := invariantViaSimulation add2_R _).
  apply invariant_simulates with (sys2 := add2_bsys).

  constructor; simplify.

  invert H.
  invert H0.
  invert H1.
  exists {| Shared := true; Private := (BRead, BRead) |}; simplify.
  propositional.
  constructor.
  propositional.
  constructor.
  constructor.
  constructor.

  invert H.
  invert H0; simplify.

  invert H7.

  invert H2.
  exists {| Shared := b; Private := (BWrite b, th2') |}.
  propositional.
  constructor.
  propositional.
  constructor.
  propositional.
  assumption.
  constructor.
  constructor.

  invert H2.
  exists {| Shared := b0; Private := (BRead, th2') |}.
  propositional.
  constructor.
  propositional.
  constructor.
  assumption.
  invert H0.
  propositional.
  constructor.
  assumption.
  constructor.
  constructor.

  invert H7.

  invert H3.
  exists {| Shared := b; Private := (th1', BWrite b) |}.
  propositional.
  constructor.
  propositional.
  assumption.
  constructor.
  propositional.
  constructor.
  constructor.

  invert H3.
  exists {| Shared := b0; Private := (th1', BRead) |}.
  propositional.
  constructor.
  propositional.
  constructor.
  assumption.
  invert H0.
  propositional.
  assumption.
  constructor.
  constructor.
  constructor.

  model_check_infer.

  invert 1.
  invert H0.
  simplify.
  unfold add2_correct.
  simplify.
  propositional; subst.

  invert H.
  propositional.

  invert H1.
  propositional.

  invert H.
  propositional.

  invert H1.
  propositional.
Qed.


(** * Another abstraction example *)

(*

f(int n) {
  int i, j;

  i = 0;
  j = 0;
  while (n > 0) {
    i = i + n;
    j = j + n;
    n = n - 1;
  }
}
*)

Inductive pc :=
| i_gets_0
| j_gets_0
| Loop
| i_add_n
| j_add_n
| n_sub_1
| Done.

Record vars := {
  N : nat;
  I : nat;
  J : nat
}.

Record state := {
  Pc : pc;
  Vars : vars
}.

Inductive initial : state -> Prop :=
| Init : forall vs, initial {| Pc := i_gets_0; Vars := vs |}.

Inductive step : state -> state -> Prop :=
| Step_i_gets_0 : forall n i j,
  step {| Pc := i_gets_0; Vars := {| N := n;
                                     I := i;
                                     J := j |} |}
       {| Pc := j_gets_0; Vars := {| N := n;
                                     I := 0;
                                     J := j |} |}
| Step_j_gets_0 : forall n i j,
  step {| Pc := j_gets_0; Vars := {| N := n;
                                     I := i;
                                     J := j |} |}
       {| Pc := Loop; Vars := {| N := n;
                                 I := i;
                                 J := 0 |} |}
| Step_Loop_done : forall i j,
  step {| Pc := Loop; Vars := {| N := 0;
                                 I := i;
                                 J := j |} |}
       {| Pc := Done; Vars := {| N := 0;
                                 I := i;
                                 J := j |} |}
| Step_Loop_enter : forall n i j,
  step {| Pc := Loop; Vars := {| N := S n;
                                 I := i;
                                 J := j |} |}
       {| Pc := i_add_n; Vars := {| N := S n;
                                    I := i;
                                    J := j |} |}
| Step_i_add_n : forall n i j,
  step {| Pc := i_add_n; Vars := {| N := n;
                                    I := i;
                                    J := j |} |}
       {| Pc := j_add_n; Vars := {| N := n;
                                    I := i + n;
                                    J := j |} |}
| Step_j_add_n : forall n i j,
  step {| Pc := j_add_n; Vars := {| N := n;
                                    I := i;
                                    J := j |} |}
       {| Pc := n_sub_1; Vars := {| N := n;
                                    I := i;
                                    J := j + n |} |}
| Step_n_sub_1 : forall n i j,
  step {| Pc := n_sub_1; Vars := {| N := n;
                                    I := i;
                                    J := j |} |}
       {| Pc := Loop; Vars := {| N := n - 1;
                                 I := i;
                                 J := j |} |}.

Definition loopy_sys := {|
  Initial := initial;
  Step := step
|}.

Inductive absvars := Unknown | i_is_0 | i_eq_j | i_eq_j_plus_n.

Record absstate := {
  APc : pc;
  AVars : absvars
}.

Inductive absstep : absstate -> absstate -> Prop :=
| AStep_i_gets_0 : forall vs,
  absstep {| APc := i_gets_0; AVars := vs |}
          {| APc := j_gets_0; AVars := i_is_0 |}
| AStep_j_gets_0_i_is_0 :
  absstep {| APc := j_gets_0; AVars := i_is_0 |}
          {| APc := Loop; AVars := i_eq_j |}
| AStep_j_gets_0_Other : forall vs,
  vs <> i_is_0
  -> absstep {| APc := j_gets_0; AVars := vs |}
             {| APc := Loop; AVars := Unknown |}
| AStep_Loop_done : forall vs,
  absstep {| APc := Loop; AVars := vs |}
          {| APc := Done; AVars := vs |}
| AStep_Loop_enter : forall vs,
  absstep {| APc := Loop; AVars := vs |}
          {| APc := i_add_n; AVars := vs |}
| AStep_i_add_n_i_eq_j :
  absstep {| APc := i_add_n; AVars := i_eq_j |}
          {| APc := j_add_n; AVars := i_eq_j_plus_n |}
| AStep_i_add_n_Other : forall vs,
  vs <> i_eq_j
  -> absstep {| APc := i_add_n; AVars := vs |}
             {| APc := j_add_n; AVars := Unknown |}
| AStep_j_add_n_i_eq_j_plus_n :
  absstep {| APc := j_add_n; AVars := i_eq_j_plus_n |}
          {| APc := n_sub_1; AVars := i_eq_j |}
| AStep_j_add_n_i_Other : forall vs,
  vs <> i_eq_j_plus_n
  -> absstep {| APc := j_add_n; AVars := vs |}
             {| APc := n_sub_1; AVars := Unknown |}
| AStep_n_sub_1_bad :
  absstep {| APc := n_sub_1; AVars := i_eq_j_plus_n |}
          {| APc := Loop; AVars := Unknown |}
| AStep_n_sub_1_good : forall vs,
  vs <> i_eq_j_plus_n
  -> absstep {| APc := n_sub_1; AVars := vs |}
             {| APc := Loop; AVars := vs |}.

Definition absloopy_sys := {|
  Initial := { {| APc := i_gets_0; AVars := Unknown |} };
  Step := absstep
|}.

Inductive Rvars : vars -> absvars -> Prop :=
| Rv_Unknown : forall vs, Rvars vs Unknown
| Rv_i_is_0 : forall vs, vs.(I) = 0 -> Rvars vs i_is_0
| Rv_i_eq_j : forall vs, vs.(I) = vs.(J) -> Rvars vs i_eq_j
| Rv_i_eq_j_plus_n : forall vs, vs.(I) = vs.(J) + vs.(N) -> Rvars vs i_eq_j_plus_n.

Inductive R : state -> absstate -> Prop :=
| Rcon : forall pc vs avs, Rvars vs avs -> R {| Pc := pc; Vars := vs |}
                                             {| APc := pc; AVars := avs |}.

Definition loopy_correct (st : state) :=
  st.(Pc) = Done -> st.(Vars).(I) = st.(Vars).(J).

Theorem loopy_ok :
  invariantFor loopy_sys loopy_correct.
Proof.
  eapply invariant_weaken with (invariant1 := invariantViaSimulation R _).
  apply invariant_simulates with (sys2 := absloopy_sys).

  constructor; simplify.

  invert H.
  exists {| APc := i_gets_0; AVars := Unknown |}.
  propositional.
  constructor.
  constructor.

  invert H0.

  invert H.
  exists {| APc := j_gets_0; AVars := i_is_0 |}.
  propositional; repeat constructor.

  invert H.
  invert H3.
  exists {| APc := Loop; AVars := Unknown |}; propositional; repeat constructor; equality.
  exists {| APc := Loop; AVars := i_eq_j |}; propositional; repeat constructor; equality.
  exists {| APc := Loop; AVars := Unknown |}; propositional; repeat constructor; equality.
  exists {| APc := Loop; AVars := Unknown |}; propositional; repeat constructor; equality.

  exists {| APc := Done; AVars := st2.(AVars) |}.
  invert H; simplify; propositional; repeat constructor; equality.

  exists {| APc := i_add_n; AVars := st2.(AVars) |}.
  invert H; simplify; propositional; repeat constructor; equality.

  invert H.
  invert H3.
  exists {| APc := j_add_n; AVars := Unknown |}; repeat constructor; equality.
  exists {| APc := j_add_n; AVars := Unknown |}; repeat constructor; equality.
  exists {| APc := j_add_n; AVars := i_eq_j_plus_n |}; repeat constructor; simplify; equality.
  exists {| APc := j_add_n; AVars := Unknown |}; repeat constructor; equality.

  invert H.
  invert H3.
  exists {| APc := n_sub_1; AVars := Unknown |}; repeat constructor; equality.
  exists {| APc := n_sub_1; AVars := Unknown |}; repeat constructor; equality.
  exists {| APc := n_sub_1; AVars := Unknown |}; repeat constructor; equality.
  exists {| APc := n_sub_1; AVars := i_eq_j |}; repeat constructor; simplify; equality.

  invert H.
  invert H3.
  exists {| APc := Loop; AVars := Unknown |}; propositional; repeat constructor; equality.
  exists {| APc := Loop; AVars := i_is_0 |}; propositional; repeat constructor; equality.
  exists {| APc := Loop; AVars := i_eq_j |}; propositional; repeat constructor; equality.
  exists {| APc := Loop; AVars := Unknown |}; propositional; repeat constructor; equality.

  model_check_infer.

  invert 1.
  invert H0.
  unfold loopy_correct.
  simplify.
  propositional; subst.

  invert H2.

  invert H1.

  invert H2.

  invert H1.
  invert H.
  assumption.

  invert H2.

  invert H1.

  invert H2.
Qed.