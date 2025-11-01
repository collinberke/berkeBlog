# Replace each instance of carrot with kale starting at line 8
# to the end of the file
# :.,$s/carrot/kale/g
# . - start at the current line
# $ - look ahead to additional lines
library(tribble)

basket <- tribble(
   ~fruit,       ~veggie,
   "apple",      "carrot",
   "apple",      "pepper",
   "banana",     "carrot",
   "pears",      "carrot",
   "strawberry", "asparagus",
   "apple",      "carrot",
   "apple",      "pepper",
   "banana",     "carrot",
   "pears",      "carrot",
   "strawberry", "asparagus"
)
