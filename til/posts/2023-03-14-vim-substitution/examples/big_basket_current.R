# Replace each instance of carrot with kale on lines 8 and two lines ahead 
# :.,+2s/carrot/kale/g
# . - start at the current line
# +2 - look ahead to additional lines
library(tribble)

basket <- tribble(
   ~fruit,       ~veggie,
   "apple",      "carrot",
   "apple",      "pepper",
   "banana",     "carrot",
   "pears",      "carrot",
   "strawberry", "asparagus"
)
