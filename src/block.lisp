;;;; block.lisp
;;;;
;;;; Copyright (c) 2015 Robert Smith

(in-package #:cl-permutation)

;;; Disjoint-Set (DJS) Data Structure
;;;
;;; Below we implement the well known union-find algorithms. We don't
;;; implement the common optimization of balancing-by-rank, because we
;;; have an additional constraint: We need to arbitrarily be able to
;;; change the canonical element of each DJS.
;;;
;;; We implement this by endowing DJS's with a "DJS-REP" data
;;; structure, which adds a level of indirection. This data structure
;;; just contains a single pointer to DJS node. There is an invariant
;;; that if one DJS-REP points to a node N, then no other DJS-REP node
;;; points to N as well.
;;;
;;; DJS nodes point to their representative DJS-REP, which changes
;;; when a DJS-UNION operation occurs. When DJS-UNION occurs, we may
;;; mess up the invariant above. This invariant is later repaired
;;; "on-demand" within DJS-FIND.

;;; We turn *PRINT-CIRCLE* on because each DJS/DJS-REP creates a new
;;; circular structure.
(setf *print-circle* t)

(defstruct (djs (:constructor %make-djs))
  "Representation of a disjoint-set data structure. Each node has a representative element denoted by REPRESENTATIVE, which points to a DJS-REP node representing the canonical element of that disjoint-set."
  (representative nil :type (or null djs-rep))
  value)

(defstruct (djs-rep (:constructor %make-djs-rep))
  "Pointer to the representative element of a DJS."
  (djs nil :type djs))

(defun djs (value)
  "Construct a fresh DJS node."
  (let* ((node (%make-djs :value value))
         (rep (%make-djs-rep :djs node)))
    (setf (djs-representative node) rep)
    ;; Return the DJS node.
    node))

(defun djs-change-representative (djs)
  "Change the representative of DJS to point to itself."
  (setf (djs-rep-djs (djs-representative djs)) djs))

(defun djs-find (d)
  "Find the canonical DJS node of which the DJS node D is a part."
  (loop :with rep := (djs-representative d)
        :with rep-node := (djs-rep-djs rep)
        :with rep-node-rep := (djs-representative rep-node)
        ;; Fix-up out-of-date rep nodes. Once updated, this loop will
        ;; not execute in future invocations.
        :until (eq rep rep-node-rep) :do
          (setf (djs-representative d) rep-node-rep
                rep                    rep-node-rep
                rep-node               (djs-rep-djs rep)
                rep-node-rep           (djs-representative rep-node))
        :finally (return (djs-rep-djs rep-node-rep))))

(defun djs-union (a b)
  "Link together the DJS nodes A and B.

The representative of the union will be that of B."
  (let ((a-rep (djs-representative a))
        (b-rep (djs-representative b)))
    (unless (eq a-rep b-rep)
      ;; Set representative of A to be B-REP. Now A won't point to
      ;; it's old representative.
      (setf (djs-representative a) b-rep)
      ;; Change the old A representative to point to B.
      (setf (djs-rep-djs a-rep)
            (djs-rep-djs b-rep))))
  nil)

(defun find-minimal-block-system-containing (perm-group alphas)
  "Find the minimal blocks of the permutation group PERM-GROUP which contain the list of points ALPHAS.

Returns a list of lists. Each sub-list represents a block.

If the group PERM-GROUP is not transitive, then the resulting list will contain all points as unit sub-lists which are not a part of the equivalence class of ALPHAS."
  ;; This is an implementation of Atkinson's algorithm.
  (check-type perm-group perm-group)
  (assert (not (null alphas)) (alphas) "ALPHAS must contain at least 1 point.")
  (assert (listp alphas) (alphas) "ALPHAS must be a list.")
  (let* ((degree (group-degree perm-group))
         ;; CLASSES is a map from point to DJS. We can reverse this
         ;; map by inspecting the value of DJS via DJS-VALUE. See the
         ;; functions CLASS and REP below.
         (classes (make-array (1+ degree) :initial-element nil)))
    (assert (every (lambda (alpha) (<= 1 alpha degree)) alphas)
            ()
            "ALPHAS contains invalid points. They must be between 1 and ~
             the degree of the group, which is ~D."
            degree)
    ;; Set up our equivalence classes as DJS's.
    ;;
    ;; First, initialize all classes..
    (loop :for i :from 1 :to degree :do
      (setf (aref classes i) (djs i)))
    ;; Next, put all ALPHA_I in the same equivalence class.
    (let ((alpha_1-class (aref classes (first alphas))))
      (loop :for i :in (rest alphas) :do
        (let ((alpha_i-class (aref classes i)))
          ;; Ensure that alpha_1-class is the representative of this
          ;; union. Currently, this is implicit in the DJS-UNION call.
          (djs-union alpha_i-class alpha_1-class))))
    (labels ((class (point)
               "Find the class of the point POINT."
               (aref classes point))
             (rep (point)
               "Find the class representative of the point POINT."
               (djs-value (djs-find (class point)))))
      (let ((q (queues:make-queue ':simple-queue)))
        ;; Initialize the queue with ALPHA_I for I > 1.
        (dolist (alpha (rest alphas))
          (queues:qpush q alpha))
        ;; Iterate until queue is empty.
        (loop :until (zerop (queues:qsize q)) :do
          (let ((gamma (queues:qpop q)))
            (dolist (g (generators perm-group))
              (let* ((delta (rep gamma))
                     (kappa (rep (perm-eval g gamma)))
                     (lam   (rep (perm-eval g delta))))
                (unless (= kappa lam)
                  (let ((kappa-class (class kappa))
                        (lam-class (class lam)))
                    ;; Merge the kappa and lambda classes.
                    (djs-union lam-class kappa-class)
                    ;; Make kappa the representative of merged class.
                    (djs-change-representative kappa-class)
                    ;; Add LAM for processing.
                    (queues:qpush q lam))))))))
      ;; Return equivalence classes.
      (let ((table (make-hash-table :test 'eql)))
        (loop :for j :from 1 :to degree
              :for rep := (rep j)
              :do (push j (gethash rep table nil))
              :finally (let ((equiv-classes nil))
                         (maphash (lambda (k v)
                                    (declare (ignore k))
                                    (push (nreverse v) equiv-classes))
                                  table)
                         (return (nreverse equiv-classes))))))))

(defun trivial-block-system-p (group bs)
  "Is the block system BS a trivial block system for the transitive permutation group GROUP?"
  (let ((l (length bs)))
    (or (= l 1)
        (= l (group-degree group)))))

(defun find-non-trivial-block-system (group)
  "Find a non-trivial block system of the permutation group GROUP.

GROUP must be transitive in order for this to produce truly non-trivial block systems."
  (loop :for i :from 2 :to (group-degree group)
        :for bs := (find-minimal-block-system-containing group (list 1 i))
        :unless (trivial-block-system-p group bs)
          :do (return bs)))


