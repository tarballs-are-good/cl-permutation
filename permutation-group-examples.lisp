(in-package #:cl-permutation)

(defparameter s_5 (list #[2 1 3 4 5]
                        #[1 3 2 4 5]
                        #[1 2 4 3 5]
                        #[1 2 3 5 4]))

(defparameter mathieu (list #[16 7 4 17 1 6 11 23 22 10 19 2 14 5 3 8 9 18 20 24 15 21 13 12]
                            #[24 21 10 22 9 23 8 7 5 3 18 20 14 13 19 17 16 11 15 12 2 4 6 1]))

(defparameter rubik
  (list #[3 5 8 2 7 1 4 6 33 34 35 12 13 14 15 16 9 10 11 20 21 22 23 24 17 
          18 19 28 29 30 31 32 25 26 27 36 37 38 39 40 41 42 43 44 45 46 47 48]
        #[17 2 3 20 5 22 7 8 11 13 16 10 15 9 12 14 41 18 19 44 21 46 23 24 
          25 26 27 28 29 30 31 32 33 34 6 36 4 38 39 1 40 42 43 37 45 35 47 48] 
        #[1 2 3 4 5 25 28 30 9 10 8 12 7 14 15 6 19 21 24 18 23 17 20 22 43 
          26 27 42 29 41 31 32 33 34 35 36 37 38 39 40 11 13 16 44 45 46 47 48] 
        #[1 2 38 4 36 6 7 33 9 10 11 12 13 14 15 16 17 18 3 20 5 22 23 8 27 
          29 32 26 31 25 28 30 48 34 35 45 37 43 39 40 41 42 19 44 21 46 47 24] 
        #[14 12 9 4 5 6 7 8 46 10 11 47 13 48 15 16 17 18 19 20 21 22 23 24
          25 26 1 28 2 30 31 3 35 37 40 34 39 33 36 38 41 42 43 44 45 32 29 27] 
        #[1 2 3 4 5 6 7 8 9 10 11 12 13 22 23 24 17 18 19 20 21 30 31 32 25
          26 27 28 29 38 39 40 33 34 35 36 37 14 15 16 43 45 48 42 47 41 44 46]))

