# Replace each instance of carrot with kale on lines 7 to 9 (inclusive)
# :7,9s/carrot/kale/g
library(tribble)

basket <- tribble(
   ~fruit      , ~veggie,
   "apple"     , "carrot",
   "apple"     , "pepper",
   "banana"    , "carrot",
   "pears"     , "carrot",
   "strawberry", "asparagus"
)
